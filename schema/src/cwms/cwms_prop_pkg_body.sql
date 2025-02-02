/* Formatted on 4/6/2009 2:48:02 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY cwms_properties
AS
	-------------------------------------------------------------------------------
	-- function str_tab_tab2property_info_tab(...)
	--
	--
	FUNCTION str_tab_tab2property_info_tab (
		p_text_tab	 IN str_tab_tab_t
	)
		RETURN property_info_tab_t
	IS
		l_property_tab 					property_info_tab_t
				:= property_info_tab_t () ;
		i										PLS_INTEGER := p_text_tab.FIRST;
	BEGIN
		WHILE i IS NOT NULL
		LOOP
			IF p_text_tab (i).COUNT != 3
			THEN
				cwms_err.raise (
					'INVALID_ITEM',
					'Record with ' || p_text_tab (i).COUNT || ' fields',
					'property record.'
				);
			END IF;

			l_property_tab.EXTEND;
			l_property_tab (i).office_id := p_text_tab (i) (1);
			l_property_tab (i).prop_category := p_text_tab (i) (2);
			l_property_tab (i).prop_id := p_text_tab (i) (3);
			i := p_text_tab.NEXT (i);
		END LOOP;

		RETURN l_property_tab;
	END str_tab_tab2property_info_tab;



	-------------------------------------------------------------------------------
	-- procedure get_properties(...)
	--
	--
	PROCEDURE get_properties (p_cwms_cat			  OUT sys_refcursor,
									  p_property_info   IN		property_info_tab_t
									 )
	IS
		l_office_code						NUMBER (14) := NULL;
		l_office_id 						VARCHAR2 (16);
		l_prop_category					VARCHAR2 (256);
		l_prop_id							VARCHAR2 (256);
		l_query								VARCHAR2 (32767);
		l_pos                         PLS_INTEGER;
	BEGIN
		p_cwms_cat := NULL;

		IF p_property_info IS NOT NULL
		THEN
			FOR i IN p_property_info.FIRST .. p_property_info.LAST
			LOOP
            l_office_id := upper(cwms_util.normalize_wildcards(
               nvl(p_property_info(i).office_id, cwms_util.user_office_id), 
               true));
				l_prop_category := upper(cwms_util.normalize_wildcards(
               p_property_info(i).prop_category,
               true));
				l_prop_id := upper(cwms_util.normalize_wildcards(
               p_property_info(i).prop_id,
               true));
				IF i = 1
				THEN
					l_query :=
						'select o.office_id, p.prop_category, p.prop_id, p.prop_value, p.prop_comment '
						|| 'from at_properties p, cwms_office o '
						|| 'where ';
				END IF;

				l_query :=
						l_query
					|| '(o.office_id like '''
					|| l_office_id
               || ''' escape ''\'' '
					|| ' and p.office_code = o.office_code'
					|| ' and upper(p.prop_category) like '''
					|| l_prop_category
					|| ''' escape ''\'' '
					|| ' and upper(p.prop_id) like '''
					|| l_prop_id
					|| ''' escape ''\'')';

				IF i < p_property_info.LAST
				THEN
					l_query := l_query || ' or ';
				ELSE
					l_query :=
						l_query
						|| ' order by o.office_id, upper(p.prop_category), upper(p.prop_id) asc';
				END IF;
			END LOOP;
         cwms_util.check_dynamic_sql(l_query);
			OPEN p_cwms_cat FOR l_query;
		END IF;
	END get_properties;

	-------------------------------------------------------------------------------
	-- function set_properties(...)
	--
	--
	FUNCTION set_properties (p_property_info IN property_info2_tab_t)
		RETURN BINARY_INTEGER
	IS
		l_office_code						NUMBER (14) := NULL;
		l_office_id 						VARCHAR2 (16);
		l_prop_category					VARCHAR2 (256);
		l_prop_id							VARCHAR2 (256);
		l_prop_value						VARCHAR2 (256);
		l_prop_comment 					VARCHAR2 (256);
		l_table_row 						at_properties%ROWTYPE;
		l_updated							BOOLEAN;
		l_success_count					BINARY_INTEGER := 0;
		l_duplicate_count 				BINARY_INTEGER := 0;

		CURSOR l_query
		IS
				 SELECT	 office_code, prop_category, prop_id, prop_value,
							 prop_comment
					FROM	 at_properties
				  WHERE		  office_code IN (SELECT	office_code
														  FROM	cwms_office
														 WHERE	office_id = l_office_id)
							 AND UPPER (prop_category) = UPPER (l_prop_category)
							 AND UPPER (prop_id) = UPPER (l_prop_id)
			FOR UPDATE	 OF prop_value, prop_comment;
	BEGIN
		IF p_property_info IS NULL
		THEN
			RETURN 0;
		END IF;

		FOR i IN p_property_info.FIRST .. p_property_info.LAST
		LOOP
			-- l_office_id := upper(nvl(p_property_info(i).office_id, cwms_util.user_office_id));
			l_office_id := UPPER (p_property_info (i).office_id);
			l_prop_category := p_property_info (i).prop_category;
			l_prop_id := p_property_info (i).prop_id;

			OPEN l_query;

			FETCH l_query INTO								  l_table_row;

			IF l_query%NOTFOUND
			THEN
				------------
				-- insert --
				------------
				BEGIN
					SELECT	office_code
					  INTO	l_table_row.office_code
					  FROM	cwms_office
					 WHERE	office_id = l_office_id;

					l_table_row.prop_category := p_property_info (i).prop_category;
					l_table_row.prop_id := p_property_info (i).prop_id;
					l_table_row.prop_value := p_property_info (i).prop_value;
					l_table_row.prop_comment := p_property_info (i).prop_comment;

					BEGIN
						INSERT INTO at_properties
						  VALUES   l_table_row;

						l_success_count := l_success_count + 1;
					EXCEPTION
						WHEN OTHERS
						THEN
							DBMS_OUTPUT.put_line ('Cannot insert: ');
							DBMS_OUTPUT.put_line ('   Office_id = ' || l_office_id);
							DBMS_OUTPUT.put_line (
								'   Category  = ' || l_table_row.prop_category
							);
							DBMS_OUTPUT.put_line (
								'   Name      = ' || l_table_row.prop_id
							);
							DBMS_OUTPUT.put_line (
								'   Value     = ' || l_table_row.prop_value
							);
							DBMS_OUTPUT.put_line (
								'   Comment   = ' || l_table_row.prop_comment
							);
							DBMS_OUTPUT.put_line ('   Error     : ' || SQLERRM);
					END;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						NULL;
				END;
			ELSE
				------------
				-- update --
				------------
				BEGIN
					l_updated := FALSE;

					IF NVL (l_table_row.prop_value, '~') !=
							NVL (p_property_info (i).prop_value, '~')
					THEN
						l_updated := TRUE;
					END IF;

					IF NVL (l_table_row.prop_comment, '~') !=
							NVL (p_property_info (i).prop_comment, '~')
					THEN
						l_updated := TRUE;
					END IF;

					IF l_updated
					THEN
						BEGIN
							UPDATE	at_properties
								SET	prop_value = p_property_info (i).prop_value,
										prop_comment = p_property_info (i).prop_comment
							 WHERE	CURRENT OF l_query;

							l_success_count := l_success_count + 1;
						EXCEPTION
							WHEN OTHERS
							THEN
								DBMS_OUTPUT.put_line ('Cannot update: ');
								DBMS_OUTPUT.put_line (
									'   Office_id = ' || l_office_id
								);
								DBMS_OUTPUT.put_line (
									'   Category  = ' || l_table_row.prop_category
								);
								DBMS_OUTPUT.put_line (
									'   Name      = ' || l_table_row.prop_id
								);
								DBMS_OUTPUT.put_line (
									'   Value     = ' || l_table_row.prop_value
								);
								DBMS_OUTPUT.put_line (
									'   Comment   = ' || l_table_row.prop_comment
								);
								DBMS_OUTPUT.put_line ('   Error     : ' || SQLERRM);
						END;
					ELSE
						l_duplicate_count := l_duplicate_count + 1;
					END IF;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						NULL;
				END;
			END IF;

			CLOSE l_query;
		END LOOP;

		COMMIT;
		DBMS_OUTPUT.put_line (
			'' || l_duplicate_count || ' duplicates not modified.'
		);
		RETURN l_success_count;
	END set_properties;

	-------------------------------------------------------------------------------
	-- procedure get_properties(...)
	--
	--
	PROCEDURE get_properties (p_cwms_cat			  OUT sys_refcursor,
									  p_property_info   IN		VARCHAR2
									 )
	IS
		l_property_tab 					property_info_tab_t
				:= property_info_tab_t () ;
		l_text_table						str_tab_tab_t;
		i										PLS_INTEGER;
	BEGIN
		p_cwms_cat := NULL;

		IF p_property_info IS NULL
		THEN
			RETURN;
		END IF;

		l_text_table := cwms_util.parse_string_recordset (p_property_info);
		i := l_text_table.FIRST;

		WHILE i IS NOT NULL
		LOOP
			IF l_text_table (i).COUNT != 3
			THEN
				cwms_err.raise (
					'INVALID_ITEM',
					'Record with ' || l_text_table (i).COUNT || ' fields',
					'property record.'
				);
			END IF;

			l_property_tab.EXTEND;
			l_property_tab (i).office_id := l_text_table (i) (1);
			l_property_tab (i).prop_category := l_text_table (i) (2);
			l_property_tab (i).prop_id := l_text_table (i) (3);
			i := l_text_table.NEXT (i);
		END LOOP;

		get_properties (p_cwms_cat, l_property_tab);
	END get_properties;


   -------------------------------------------------------------------------------
   -- procedure get_properties(...)
   --
   --
   PROCEDURE get_properties (p_cwms_cat      OUT sys_refcursor,
                             p_property_info IN   property_info_t
                            )
   IS
   BEGIN
      get_properties(
         p_cwms_cat,
         property_info_tab_t(p_property_info));
   END get_properties;                            

   -------------------------------------------------------------------------------
   -- procedure get_properties(...)
   --
   --
	PROCEDURE get_properties (p_cwms_cat			  OUT sys_refcursor,
									  p_property_info   IN		CLOB
									 )
	IS
		l_property_tab 					property_info_tab_t
				:= property_info_tab_t () ;
		l_text_table						str_tab_tab_t;
	BEGIN
		p_cwms_cat := NULL;

		IF p_property_info IS NULL
		THEN
			RETURN;
		END IF;

		l_text_table := cwms_util.parse_clob_recordset (p_property_info);

		FOR i IN l_text_table.FIRST .. l_text_table.LAST
		LOOP
			IF l_text_table (i).COUNT != 3
			THEN
				cwms_err.raise (
					'INVALID_ITEM',
					'Record with ' || l_text_table (i).COUNT || ' fields',
					'property record.'
				);
			END IF;

			l_property_tab.EXTEND;
			l_property_tab (i).office_id := l_text_table (i) (1);
			l_property_tab (i).prop_category := l_text_table (i) (2);
			l_property_tab (i).prop_id := l_text_table (i) (3);
		END LOOP;

		get_properties (p_cwms_cat, l_property_tab);
	END get_properties;

	-------------------------------------------------------------------------------
	-- function get_property(...)
	--
	--

	FUNCTION get_property (p_category	 IN VARCHAR2,
								  p_id			 IN VARCHAR2,
								  p_default 	 IN VARCHAR2 DEFAULT NULL ,
								  p_office_id	 IN VARCHAR2 DEFAULT NULL
								 )
		RETURN VARCHAR2
	IS
		l_value								VARCHAR2 (256);
		l_comment							VARCHAR2 (256);
	BEGIN
		get_property (l_value,
						  l_comment,
						  p_category,
						  p_id,
						  p_default,
						  p_office_id
						 );
		RETURN l_value;
	END;

	PROCEDURE get_property (p_value			  OUT VARCHAR2,
									p_comment		  OUT VARCHAR2,
									p_category	  IN		VARCHAR2,
									p_id			  IN		VARCHAR2,
									p_default	  IN		VARCHAR2 DEFAULT NULL ,
									p_office_id   IN		VARCHAR2 DEFAULT NULL
								  )
	IS
		l_office_id 						VARCHAR2 (16)
				:= NVL (p_office_id, cwms_util.user_office_id) ;
		l_prop_value						at_properties.prop_value%TYPE
				:= p_default ;
		l_prop_comment 					at_properties.prop_comment%TYPE;
	BEGIN
		BEGIN
			l_office_id := UPPER (p_office_id);

			SELECT	prop_value, prop_comment
			  INTO	l_prop_value, l_prop_comment
			  FROM	at_properties p, cwms_office o
			 WHERE		 o.office_id = l_office_id
						AND p.office_code = o.office_code
						AND UPPER (p.prop_category) = UPPER (p_category)
						AND UPPER (p.prop_id) = UPPER (p_id);
		EXCEPTION
			WHEN OTHERS
			THEN
				NULL;
		END;

		p_value := l_prop_value;
		p_comment := l_prop_comment;
	END get_property;

	-------------------------------------------------------------------------------
	-- function get_properties_xml(...)
	--
	--
	FUNCTION get_properties_xml (p_property_info IN property_info_tab_t)
		RETURN CLOB
	IS
		l_xml 								CLOB;
		l_properties						sys_refcursor := NULL;
		l_prop_row							property_info2_t;
		l_last_office						VARCHAR2 (16) := ' ';
		l_indent 							VARCHAR2 (256);
		l_categories						str_tab_t
				:= str_tab_t () ;
		l_ids 								str_tab_t
				:= str_tab_t () ;
		l_this_category					str_tab_t
				:= str_tab_t () ;
		l_this_id							str_tab_t
				:= str_tab_t () ;
		l_level								BINARY_INTEGER := 0;
		spc CONSTANT						VARCHAR2 (1) := ' ';
		nl CONSTANT 						VARCHAR (1) := CHR (10);

		PROCEDURE write_clob (p_clob IN OUT NOCOPY CLOB, p_data VARCHAR2)
		IS
		BEGIN
			DBMS_LOB.writeappend (p_clob, LENGTH (p_data), p_data);
		END;

		PROCEDURE set_category (p_category IN VARCHAR2)
		IS
			l_pos 								BINARY_INTEGER;
			l_part								VARCHAR2 (256);
			l_category							VARCHAR (256) := p_category;
		BEGIN
			l_this_category.delete;

			LOOP
				l_pos := NVL (INSTR (l_category, '.'), 0);

				CASE l_pos
					WHEN 0
					THEN
						l_part := l_category;
						l_category := NULL;
					WHEN 1
					THEN
						l_part := '';
						l_category := SUBSTR (l_category, 2);
					ELSE
						l_part := SUBSTR (l_category, 1, l_pos - 1);
						l_category := SUBSTR (l_category, l_pos + 1);
				END CASE;

				l_this_category.EXTEND;
				l_this_category (l_this_category.LAST) := l_part;
				EXIT WHEN l_pos = 0;
			END LOOP;
		END;

		PROCEDURE push_category (p_category IN VARCHAR2)
		IS
		BEGIN
			l_categories.EXTEND;
			l_categories (l_categories.COUNT) := p_category;
			l_level := l_level + 1;
			l_indent := l_indent || spc;
			write_clob (
				l_xml,
				l_indent || '<category name="' || p_category || '">' || nl
			);
		END;

		PROCEDURE pop_category
		IS
		BEGIN
			write_clob (l_xml, l_indent || '</category>' || nl);
			l_categories.TRIM;
			l_level := l_level - 1;
			l_indent := SUBSTR (l_indent, 1, LENGTH (spc) * l_level);
		END;

		PROCEDURE pop_categories
		IS
		BEGIN
			WHILE l_categories.COUNT > 0
			LOOP
				pop_category;
			END LOOP;
		END;

		PROCEDURE set_id (p_id IN VARCHAR2)
		IS
			l_pos 								BINARY_INTEGER;
			l_part								VARCHAR2 (256);
			l_id									VARCHAR (256) := p_id;
		BEGIN
			l_this_id.delete;

			LOOP
				l_pos := NVL (INSTR (l_id, '.'), 0);

				CASE l_pos
					WHEN 0
					THEN
						l_part := l_id;
						l_id := NULL;
					WHEN 1
					THEN
						l_part := '';
						l_id := SUBSTR (l_id, 2);
					ELSE
						l_part := SUBSTR (l_id, 1, l_pos - 1);
						l_id := SUBSTR (l_id, l_pos + 1);
				END CASE;

				l_this_id.EXTEND;
				l_this_id (l_this_id.COUNT) := l_part;
				EXIT WHEN l_pos = 0;
			END LOOP;
		END;

		PROCEDURE push_id (p_id IN VARCHAR2)
		IS
		BEGIN
			l_ids.EXTEND;
			l_ids (l_ids.COUNT) := p_id;
			l_level := l_level + 1;
			l_indent := l_indent || spc;
			write_clob (l_xml, l_indent || '<id name="' || p_id || '">' || nl);
		END;

		PROCEDURE pop_id
		IS
		BEGIN
			write_clob (l_xml, l_indent || '</id>' || nl);
			l_ids.TRIM;
			l_level := l_level - 1;
			l_indent := SUBSTR (l_indent, 1, LENGTH (spc) * l_level);
		END;

		PROCEDURE pop_ids
		IS
		BEGIN
			WHILE l_ids.COUNT > 0
			LOOP
				pop_id;
			END LOOP;
		END;
	BEGIN
		DBMS_LOB.createtemporary (l_xml, TRUE);
		DBMS_LOB.open (l_xml, DBMS_LOB.lob_readwrite);
		write_clob (l_xml, '<?xml version="1.0" encoding="UTF-8"?>' || nl);
		write_clob (l_xml, '<cwms_properties>' || nl);
		l_level := 1;
		l_indent := spc;
		get_properties (l_properties, p_property_info);

		LOOP
			FETCH l_properties INTO 								 l_prop_row;

			EXIT WHEN l_properties%NOTFOUND;

			IF l_prop_row.office_id != l_last_office
			THEN
				pop_ids;
				pop_categories;

				IF l_last_office != ''
				THEN
					write_clob (l_xml, l_indent || '</office>' || nl);
				END IF;

				write_clob (
					l_xml,
						l_indent
					|| '<office name="'
					|| l_prop_row.office_id
					|| '">'
					|| nl
				);
				l_last_office := l_prop_row.office_id;
			END IF;

			set_category (l_prop_row.prop_category);

			FOR i IN l_this_category.FIRST .. l_this_category.COUNT
			LOOP
				IF i <= l_categories.COUNT
				THEN
					IF l_categories (i) != l_this_category (i)
					THEN
						pop_ids;

						WHILE l_categories.COUNT >= i
						LOOP
							pop_category;
						END LOOP;
					END IF;
				END IF;

				IF i > l_categories.COUNT
				THEN
					pop_ids;
					push_category (l_this_category (i));
				END IF;
			END LOOP;

			set_id (l_prop_row.prop_id);

			FOR i IN l_this_id.FIRST .. l_this_id.LAST
			LOOP
				IF i <= l_ids.COUNT
				THEN
					IF l_ids (i) != l_this_id (i)
					THEN
						WHILE l_ids.COUNT >= i
						LOOP
							pop_id;
						END LOOP;
					END IF;
				END IF;

				IF i > l_ids.COUNT
				THEN
					push_id (l_this_id (i));
				END IF;
			END LOOP;

			IF l_prop_row.prop_value IS NULL
			THEN
				write_clob (l_xml, l_indent || spc || '<value/>' || nl);
			ELSE
				write_clob (
					l_xml,
						l_indent
					|| spc
					|| '<value text="'
					|| l_prop_row.prop_value
					|| '"/>'
					|| nl
				);
			END IF;

			IF l_prop_row.prop_comment IS NULL
			THEN
				write_clob (l_xml, l_indent || spc || '<comment/>' || nl);
			ELSE
				write_clob (
					l_xml,
						l_indent
					|| spc
					|| '<comment text="'
					|| l_prop_row.prop_comment
					|| '"/>'
					|| nl
				);
			END IF;
		END LOOP;

		CLOSE l_properties;

		pop_ids;
		pop_categories;
		write_clob (l_xml, spc || '</office>' || nl);
		write_clob (l_xml, '</cwms_properties>' || nl);
		DBMS_LOB.close (l_xml);
		RETURN l_xml;
	END get_properties_xml;

	-------------------------------------------------------------------------------
	-- function get_properties_xml(...)
	--
	--
	FUNCTION get_properties_xml (p_property_info IN VARCHAR2)
		RETURN CLOB
	IS
	BEGIN
		RETURN get_properties_xml(str_tab_tab2property_info_tab(cwms_util.parse_string_recordset(p_property_info)));
	END get_properties_xml;

	-------------------------------------------------------------------------------
	-- function get_properties_xml(...)
	--
	--
	FUNCTION get_properties_xml (p_property_info IN CLOB)
		RETURN CLOB
	IS
	BEGIN
		RETURN get_properties_xml(str_tab_tab2property_info_tab(cwms_util.parse_clob_recordset(p_property_info)));
	END get_properties_xml;

	-------------------------------------------------------------------------------
	-- function set_properties(...)
	--
	--
	FUNCTION set_properties (p_property_info IN VARCHAR2)
		RETURN BINARY_INTEGER
	IS
		l_property_tab 					property_info2_tab_t
				:= property_info2_tab_t () ;
		l_text_table						str_tab_tab_t;
	BEGIN
		IF p_property_info IS NULL
		THEN
			RETURN 0;
		END IF;

		l_text_table := cwms_util.parse_string_recordset (p_property_info);

		FOR i IN l_text_table.FIRST .. l_text_table.LAST
		LOOP
			IF l_text_table (i).COUNT != 5
			THEN
				cwms_err.raise (
					'INVALID_ITEM',
					'Record with ' || l_text_table (i).COUNT || ' fields',
					'property record.'
				);
			END IF;

			l_property_tab.EXTEND;
			l_property_tab (i).office_id := l_text_table (i) (1);
			l_property_tab (i).prop_category := l_text_table (i) (2);
			l_property_tab (i).prop_id := l_text_table (i) (3);
			l_property_tab (i).prop_value := l_text_table (i) (4);
			l_property_tab (i).prop_comment := l_text_table (i) (5);
		END LOOP;

		RETURN set_properties (l_property_tab);
	END set_properties;

	-------------------------------------------------------------------------------
	-- function set_properties(...)
	--
	--
	FUNCTION set_properties (p_property_info IN CLOB)
		RETURN BINARY_INTEGER
	IS
		l_property_tab 					property_info2_tab_t
				:= property_info2_tab_t () ;
		l_text_table						str_tab_tab_t;
	BEGIN
		IF p_property_info IS NULL
		THEN
			RETURN 0;
		END IF;

		l_text_table := cwms_util.parse_clob_recordset (p_property_info);

		FOR i IN l_text_table.FIRST .. l_text_table.LAST
		LOOP
			IF l_text_table (i).COUNT != 5
			THEN
				cwms_err.raise (
					'INVALID_ITEM',
					'Record with ' || l_text_table (i).COUNT || ' fields',
					'property record.'
				);
			END IF;

			l_property_tab.EXTEND;
			l_property_tab (i).office_id := l_text_table (i) (1);
			l_property_tab (i).prop_category := l_text_table (i) (2);
			l_property_tab (i).prop_id := l_text_table (i) (3);
			l_property_tab (i).prop_value := l_text_table (i) (4);
			l_property_tab (i).prop_comment := l_text_table (i) (5);
		END LOOP;

		RETURN set_properties (l_property_tab);
	END set_properties;

	-------------------------------------------------------------------------------
	-- procedure set_property(...)
	--
	--
	PROCEDURE set_property (p_category	  IN VARCHAR2,
									p_id			  IN VARCHAR2,
									p_value		  IN VARCHAR2,
									p_comment	  IN VARCHAR2,
									p_office_id   IN VARCHAR2 DEFAULT NULL
								  )
	IS
		l_office_id 						VARCHAR2 (16)
				:= NVL (p_office_id, cwms_util.user_office_id) ;
		l_table_row 						at_properties%ROWTYPE;

		CURSOR l_query
		IS
				 SELECT	 office_code, prop_category, prop_id, prop_value,
							 prop_comment
					FROM	 at_properties
				  WHERE		  office_code IN (SELECT	office_code
														  FROM	cwms_office
														 WHERE	office_id = l_office_id)
							 AND UPPER (prop_category) = UPPER (p_category)
							 AND UPPER (prop_id) = UPPER (p_id)
			FOR UPDATE	 OF prop_value, prop_comment;
	BEGIN
		-- l_office_id := upper(nvl(p_office_id, cwms_util.user_office_id));
		l_office_id := UPPER (p_office_id);

		OPEN l_query;

		FETCH l_query INTO								  l_table_row;

		IF l_query%NOTFOUND
		THEN
			------------
			-- insert --
			------------
			BEGIN
				SELECT	office_code
				  INTO	l_table_row.office_code
				  FROM	cwms_office
				 WHERE	office_id = l_office_id;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_OFFICE_ID', p_office_id);
			END;

			l_table_row.prop_category := p_category;
			l_table_row.prop_id := p_id;
			l_table_row.prop_value := p_value;
			l_table_row.prop_comment := p_comment;

			INSERT INTO at_properties
			  VALUES   l_table_row;
		ELSE
			------------
			-- update --
			------------
			UPDATE	at_properties
				SET	prop_value = p_value, prop_comment = p_comment
			 WHERE	CURRENT OF l_query;
		END IF;

		CLOSE l_query;
	END set_property;


   -------------------------------------------------------------------------------
   -- procedure delete_property(...)
   --
   --
   PROCEDURE delete_property (p_category     IN VARCHAR2,
                              p_id           IN VARCHAR2,
                              p_office_id    IN VARCHAR2 DEFAULT NULL
                             )
   IS
   BEGIN
      delete 
        from at_properties
       where office_code = cwms_util.get_office_code(p_office_id)
         and prop_category = p_category
         and prop_id = p_id;
   END delete_property;                             


   -------------------------------------------------------------------------------
   -- procedure delete_properties(...)
   --
   --
   PROCEDURE delete_properties (p_property_info IN property_info_tab_t)
   IS
   BEGIN
      for i in 1..p_property_info.count loop
         delete_property(
            p_property_info(i).prop_category,
            p_property_info(i).prop_id,
            nvl(upper(p_property_info(i).office_id), cwms_util.user_office_id));
      end loop;
   END delete_properties;
                                
END cwms_properties;
/

show errors;