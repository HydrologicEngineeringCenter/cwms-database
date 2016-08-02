/* Formatted on 6/16/2011 12:32:09 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY cwms_apex
AS
	TYPE varchar2_t IS TABLE OF VARCHAR2 (32767)
								 INDEX BY BINARY_INTEGER;

	g_bad_chars   VARCHAR2 (256);


	FUNCTION get_steps_per_status_update (p_count IN NUMBER)
		RETURN NUMBER
	IS
	BEGIN
		IF (p_count < 100)
		THEN
			RETURN 0;
		ELSIF (p_count < 200)
		THEN
			RETURN 10;
		ELSIF (p_count < 500)
		THEN
			RETURN 25;
		ELSIF (p_count < 1000)
		THEN
			RETURN 50;
		ELSIF (p_count < 2000)
		THEN
			RETURN 100;
		ELSIF (p_count < 5000)
		THEN
			RETURN 250;
		ELSE
			RETURN 500;
		END IF;
	END get_steps_per_status_update;

	--this function is based on one by Connor McDonald
	--http://www.jlcomp.demon.co.uk/faq/base_convert.html
	FUNCTION hex_to_decimal (p_hex_str IN VARCHAR2)
		RETURN NUMBER
	IS
		v_dec   NUMBER;
		v_hex   VARCHAR2 (16) := '0123456789ABCDEF';
	BEGIN
		v_dec := 0;

		FOR indx IN 1 .. LENGTH (p_hex_str)
		LOOP
			v_dec :=
				  v_dec * 16
				+ INSTR (v_hex, UPPER (SUBSTR (p_hex_str, indx, 1)))
				- 1;
		END LOOP;

		RETURN v_dec;
	END hex_to_decimal;



	PROCEDURE aa1 (p_string IN VARCHAR2)
	IS
	BEGIN
--		  INSERT INTO aa1 (stringstuff)
--		  VALUES (p_string
--		 	);
--		
--		  COMMIT;
		NULL;
	END aa1;

	-- Private functions --{{{
	PROCEDURE delete_collection ( 													 --{{{
										  -- Delete the collection if it exists
										  p_collection_name IN VARCHAR2)
	IS
	BEGIN
		IF (apex_collection.collection_exists (p_collection_name))
		THEN
			apex_collection.delete_collection (p_collection_name);
		END IF;
	END delete_collection;																 --}}}

	--
	--
	PROCEDURE csv_to_array (															 --{{{
									-- Utility to take a CSV string, parse it into a PL/SQL table
									-- Note that it takes care of some elements optionally enclosed
									-- by double-quotes.
									p_csv_string	 IN	  VARCHAR2,
									p_array				 OUT wwv_flow_global.vc_arr2,
									p_separator 	 IN	  VARCHAR2 := ','
								  )
	IS
		l_start_separator   PLS_INTEGER := 0;
		l_stop_separator	  PLS_INTEGER := 0;
		l_length 			  PLS_INTEGER := 0;
		l_idx 				  BINARY_INTEGER := 0;
		l_quote_enclosed	  BOOLEAN := FALSE;
		l_offset 			  PLS_INTEGER := 1;
		l_cwms_id			  VARCHAR2 (183);
	--   csv   p_array
	--   shef_id ........... 1   2
	--   shef_pe_code ...... 2   3
	--   shef_tse_code ..... 3   4
	--   shef_duration_code   4  5
	--   cwms_ts_id ........ 5-10   1
	--   unit_sys .......... 11  7
	--   units ............. 12  6
	--   tz ................ 13  8
	--   dltime ............ 14  9
	--   offset ............ 15  10
	--   snap forw ......... 16  12
	--   snap back ......... 17  11


	BEGIN
		cwms_apex.aa1 (
			'>>cwms_apex.csv_to_array<< p_csv_string: ' || p_csv_string
		);
		l_length := NVL (LENGTH (p_csv_string), 0);

		IF (l_length <= 0)
		THEN
			RETURN;
		END IF;

		LOOP
			l_idx := l_idx + 1;

			cwms_apex.aa1 ('>>cwms_apex.csv_to_array<< l_idx: ' || l_idx);

			l_quote_enclosed := FALSE;

			IF SUBSTR (p_csv_string, l_start_separator + 1, 1) = '"'
			THEN
				l_quote_enclosed := TRUE;
				l_offset := 2;
				l_stop_separator :=
					INSTR (p_csv_string, '"', l_start_separator + l_offset, 1);
			ELSE
				l_offset := 1;
				l_stop_separator :=
					INSTR (p_csv_string,
							 p_separator,
							 l_start_separator + l_offset,
							 1
							);
			END IF;

			IF l_stop_separator = 0
			THEN
				l_stop_separator := l_length + 1;
			END IF;

			------
			-------
			--------



			p_array (l_idx) :=
				(SUBSTR (p_csv_string,
							l_start_separator + l_offset,
							(l_stop_separator - l_start_separator - l_offset)
						  ));


			---------
			--------
			------
			--   p_array (l_idx)   :=
			--   (SUBSTR (p_csv_string,
			--   l_start_separator + l_offset,
			--   (l_stop_separator - l_start_separator - l_offset)
			--   ));
			EXIT WHEN l_stop_separator >= l_length;

			IF l_quote_enclosed
			THEN
				l_stop_separator := l_stop_separator + 1;
			END IF;

			l_start_separator := l_stop_separator;
		END LOOP;
	END csv_to_array; 																	 --}}}


	---
	-- Utility to take a criteria file string, parse it into a PL/SQL table
	--
	PROCEDURE crit_to_array (
		p_criteria_record   IN		VARCHAR2,
		p_comment				  OUT VARCHAR2,
		p_array					  OUT wwv_flow_global.vc_arr2
	)
	IS
	BEGIN
		BEGIN
			cwms_shef.parse_criteria_record (
				p_shef_id				  => p_array (2),
				p_shef_pe_code 		  => p_array (3),
				p_shef_tse_code		  => p_array (4),
				p_shef_duration_code   => p_array (5),
				p_units					  => p_array (6),
				p_unit_sys				  => p_array (7),
				p_tz						  => p_array (8),
				p_dltime 				  => p_array (9),
				p_int_offset			  => p_array (10),
				p_int_backward 		  => p_array (11),
				p_int_forward			  => p_array (12),
				p_cwms_ts_id			  => p_array (1),
				p_comment				  => p_comment,
				p_criteria_record 	  => p_criteria_record
			);
		EXCEPTION
			WHEN OTHERS
			THEN
				p_comment :=
					'ERROR: Format not recognized, cannot parse this line';
		END;
	END crit_to_array;

	--
	PROCEDURE get_records (p_blob IN BLOB, p_records OUT varchar2_t)		 --{{{
	IS
		l_record_separator	VARCHAR2 (2) := CHR (13) || CHR (10);
		l_last					INTEGER;
		l_current				INTEGER;
	BEGIN
		-- Sigh, stupid DOS/Unix newline stuff. If HTMLDB has generated the file,
		-- it will be a Unix text file. If user has manually created the file, it
		-- will have DOS newlines.
		-- If the file has a DOS newline (cr+lf), use that
		-- If the file does not have a DOS newline, use a Unix newline (lf)
		IF (NVL (
				 DBMS_LOB.INSTR (p_blob,
									  UTL_RAW.cast_to_raw (l_record_separator),
									  1,
									  1
									 ),
				 0
			 ) = 0)
		THEN
			l_record_separator := CHR (10);
		END IF;

		l_last := 1;

		LOOP
			l_current :=
				DBMS_LOB.INSTR (p_blob,
									 UTL_RAW.cast_to_raw (l_record_separator),
									 l_last,
									 1
									);
			EXIT WHEN (NVL (l_current, 0) = 0);
			p_records (p_records.COUNT + 1) :=
				UTL_RAW.cast_to_varchar2 (
					DBMS_LOB.SUBSTR (p_blob, l_current - l_last, l_last)
				);
			l_last := l_current + LENGTH (l_record_separator);
		END LOOP;
	END get_records;																		 --}}}

	--}}}
	-- Utility functions --{{{
	PROCEDURE parse_textarea ( 														 --{{{
									  p_textarea			 IN VARCHAR2,
									  p_collection_name	 IN VARCHAR2
									 )
	IS
		l_index		INTEGER;
		l_string 	VARCHAR2 (32767)
			:= TRANSLATE (p_textarea, CHR (10) || CHR (13) || ' ,', '@@@@');
		l_element	VARCHAR2 (100);
	BEGIN
		l_string := l_string || '@';
		htmldb_collection.create_or_truncate_collection (p_collection_name);

		LOOP
			l_index := INSTR (l_string, '@');
			EXIT WHEN NVL (l_index, 0) = 0;
			l_element := SUBSTR (l_string, 1, l_index - 1);

			IF (TRIM (l_element) IS NOT NULL)
			THEN
				apex_collection.add_member (p_collection_name, l_element);
			END IF;

			l_string := SUBSTR (l_string, l_index + 1);
		END LOOP;
	END parse_textarea;																	 --}}}

	--------------------------------------------------------------------------------
	PROCEDURE check_parsed_crit_file (p_collection_name IN VARCHAR2)
	IS
		l_count	 NUMBER;
	BEGIN
		cwms_apex.aa1 ('>>check_parsed_crit_file<< starting');

		--   INSERT INTO at_shef_decodes_gtemp
		--   SELECT   UPPER (c003 || '.' || c004 || '.' || c005 || '.' || c006) shef_spec, UPPER (c002) cwms_ts_id, c001 line_no,
		--   c003 shef_loc_id, c004 shef_pe_code, c005 shef_tse_code,
		--   c006 shef_dur_numeric, c007 shef_units, c009 shef_tz,
		--   c010 shef_dlt, c011 interval_utc_offset, c012 snap_backward,
		--   c013 snap_forward
		--   FROM apex_collections
		--   WHERE collection_name = p_collection_name;

		--   SELECT   COUNT ( * )
		--   INTO l_count
		--   FROM at_shef_decodes_gtemp;

		--   cwms_apex.aa1('>>check_parsed_crit_file<< at_shef_decodes_gtemp has '
		--   || l_count
		--   || ' rows.');
		cwms_apex.aa1 ('>>check_parsed_crit_file<< ending');
	END check_parsed_crit_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================
	--------------------------------------------------------------------------------
	PROCEDURE parse_file (																 --{{{
		p_file_name 				  IN		VARCHAR2,
		p_collection_name 		  IN		VARCHAR2,
		p_error_collection_name   IN		VARCHAR2,
		p_headings_item			  IN		VARCHAR2,
		p_columns_item 			  IN		VARCHAR2,
		p_ddl_item					  IN		VARCHAR2,
		p_number_of_records			  OUT NUMBER,
		p_number_of_columns			  OUT NUMBER,
		p_is_csv 					  IN		VARCHAR2 DEFAULT 'T',
		p_db_office_id 			  IN		VARCHAR2,
		p_process_id				  IN		VARCHAR2
	)
	IS
		l_blob					BLOB;
		l_records				varchar2_t;
		l_record 				wwv_flow_global.vc_arr2;
		l_datatypes 			wwv_flow_global.vc_arr2;
		l_headings				VARCHAR2 (4000);
		l_columns				VARCHAR2 (4000);
		l_seq_id 				NUMBER;
		l_num_columns			INTEGER;
		l_ddl 					VARCHAR2 (4000);
		l_is_csv 				BOOLEAN;
		l_is_crit_file 		BOOLEAN;
		l_tmp 					NUMBER;
		l_comment				VARCHAR2 (128) := NULL;
		l_datastream			VARCHAR2 (16);
		l_cwms_seq				NUMBER;
		l_len 					NUMBER;
		--
		l_rc						SYS_REFCURSOR;
		l_cwms_id_dup			VARCHAR2 (183);
		l_shef_id_dup			VARCHAR2 (183);
		--
		l_rc_rows				SYS_REFCURSOR;
		l_row_num				NUMBER;
		l_rows_msg				VARCHAR2 (1000);
		l_cmt 					VARCHAR2 (256);
		l_steps_per_commit	NUMBER;
		l_process_id			VARCHAR2 (128);
	BEGIN
		IF cwms_util.is_true (NVL (p_is_csv, 'T'))
		THEN
			l_is_csv := TRUE;
			l_is_crit_file := FALSE;
		ELSE
			l_is_csv := FALSE;
			l_is_crit_file := TRUE;
		END IF;

		aa1 ('parse collection name: ' || p_collection_name);
		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_process_id, (INSTR (p_process_id, '.', 1, 5) + 1))
			);
		l_cmt :=
				'ST='
			|| LOCALTIMESTAMP
			|| ';FILE='
			|| p_file_name
			|| ';STEPS='
			|| l_steps_per_commit
			|| ';CT=';
		l_process_id := p_process_id;

		IF (l_process_id IS NULL)
		THEN
			l_process_id := 'ProcessID';
		END IF;

		cwms_properties.set_property ('PROCESS_STATUS',
												l_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		--   IF (p_table_name IS NOT NULL)
		--   THEN
		--   BEGIN
		--   EXECUTE IMMEDIATE 'drop table ' || p_table_name;
		--   EXCEPTION
		--   WHEN OTHERS
		--   THEN
		--   NULL;
		--   END;

		--   l_ddl := 'create table ' || p_table_name || ' ' || v (p_ddl_item);
		--   apex_util.set_session_state ('P149_DEBUG', l_ddl);

		--   EXECUTE IMMEDIATE l_ddl;

		--   l_ddl :=
		--   'insert into '
		--   || p_table_name
		--   || ' '
		--   || 'select '
		--   || v (p_columns_item)
		--   || ' '
		--   || 'from htmldb_collections '
		--   || 'where seq_id > 1 and collection_name='''
		--   || p_collection_name
		--   || '''';
		--   apex_util.set_session_state ('P149_DEBUG',
		--   v ('P149_DEBUG') || '/' || l_ddl
		--   );

		--   EXECUTE IMMEDIATE l_ddl;

		--   RETURN;
		--   END IF;
		BEGIN
			SELECT	blob_content
			  INTO	l_blob
			  FROM	wwv_flow_files
			 WHERE	name = p_file_name;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				raise_application_error (-20000,
												 'File not found, id=' || p_file_name
												);
		END;

		get_records (l_blob, l_records);

		IF (l_records.COUNT < 2)
		THEN
			raise_application_error (
				-20000,
				'File must have at least 2 ROWS, id=' || p_file_name
			);
		END IF;

		-- Initialize collection
		apex_collection.create_or_truncate_collection (p_collection_name);
		apex_collection.create_or_truncate_collection (p_error_collection_name);

		-- Get column headings and datatypes
		IF l_is_crit_file
		THEN
			cwms_apex.aa1 ('Get column headings and datatypes');
			l_record (1) := 'Line No.';
			l_datatypes (1) := 'number';
			l_record (2) := 'cwms_ts_id';
			l_datatypes (2) := 'varchar2(183)';
			l_record (3) := 'shef_id';
			l_datatypes (3) := 'varchar2(32)';
			l_record (4) := 'pe_code';
			l_datatypes (4) := 'varchar2(32)';
			l_record (5) := 'tse_code';
			l_datatypes (5) := 'varchar2(32)';
			l_record (6) := 'dur_code';
			l_datatypes (6) := 'varchar2(32)';
			l_record (7) := 'units';
			l_datatypes (7) := 'varchar2(32)';
			l_record (8) := 'unit_system';
			l_datatypes (8) := 'varchar2(32)';
			l_record (9) := 'tz';
			l_datatypes (9) := 'varchar2(32)';
			l_record (10) := 'dltime';
			l_datatypes (10) := 'varchar2(32)';
			l_record (11) := 'int_offset';
			l_datatypes (11) := 'varchar2(32)';
			l_record (12) := 'int_backward';
			l_datatypes (12) := 'varchar2(32)';
			l_record (13) := 'int_forward';
			l_datatypes (13) := 'varchar2(32)';
		ELSE
			csv_to_array (l_records (1), l_record);
			csv_to_array (l_records (2), l_datatypes);
		END IF;

		l_num_columns := l_record.COUNT;

		IF (l_num_columns > 50)
		THEN
			raise_application_error (
				-20000,
				'Max. of 50 columns allowed, id=' || p_file_name
			);
		END IF;

		p_number_of_columns := l_num_columns;

		-- Get column headings and names
		FOR i IN 1 .. l_record.COUNT
		LOOP
			l_headings := l_headings || ':' || l_record (i);
			l_columns := l_columns || ',c' || LPAD (i, 3, '0');
		END LOOP;

		l_headings := LTRIM (l_headings, ':');
		l_columns := LTRIM (l_columns, ',');
		APEX_UTIL.set_session_state (p_headings_item, l_headings);
		APEX_UTIL.set_session_state (p_columns_item, l_columns);

		-- Get datatypes
		FOR i IN 1 .. l_record.COUNT
		LOOP
			l_ddl := l_ddl || ',' || l_record (i) || ' ' || l_datatypes (i);
		END LOOP;

		l_ddl := '(' || LTRIM (l_ddl, ',') || ')';
		APEX_UTIL.set_session_state (p_ddl_item, l_ddl);
		-- Save data into specified collection
		p_number_of_records := l_records.COUNT;

		FOR i IN 1 .. p_number_of_records
		LOOP
			aa1 (l_records (i));

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						l_process_id,
						'Processing: ' || i || ' of ' || p_number_of_records,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;

			IF l_is_crit_file
			THEN
				crit_to_array (l_records (i), l_comment, l_record);
			ELSE
				csv_to_array (l_records (i), l_record);
			END IF;

			IF INSTR (l_comment, 'ERROR') = 1
			THEN
				l_seq_id :=
					apex_collection.add_member (p_error_collection_name, 'dummy');
				apex_collection.update_member_attribute (
					p_collection_name   => p_error_collection_name,
					p_seq 				  => l_seq_id,
					p_attr_number		  => 1,
					p_attr_value		  => i
				);
				apex_collection.update_member_attribute (
					p_collection_name   => p_error_collection_name,
					p_seq 				  => l_seq_id,
					p_attr_number		  => 2,
					p_attr_value		  => l_comment
				);
				apex_collection.update_member_attribute (
					p_collection_name   => p_error_collection_name,
					p_seq 				  => l_seq_id,
					p_attr_number		  => 3,
					p_attr_value		  => l_records (i)
				);
			ELSIF INSTR (l_comment, 'COMMENT') = 1
			THEN
				NULL; 											 -- comment, so throw away.
			ELSE
				l_seq_id :=
					apex_collection.add_member (p_collection_name, 'dummy');
				apex_collection.update_member_attribute (
					p_collection_name   => p_collection_name,
					p_seq 				  => l_seq_id,
					p_attr_number		  => 1,
					p_attr_value		  => i
				);

				FOR j IN 1 .. l_record.COUNT
				LOOP
					apex_collection.update_member_attribute (
						p_collection_name   => p_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => j + 1,
						p_attr_value		  => l_record (j)
					);
				END LOOP;
			END IF;
		END LOOP;

		IF l_is_crit_file
		THEN
			BEGIN
				OPEN l_rc FOR
					SELECT	cwms_id
					  FROM	(SELECT		UPPER (c002) cwms_id,
												COUNT (UPPER (c002)) count_id
									  FROM	apex_collections
									 WHERE	collection_name = UPPER (p_collection_name)
								 GROUP BY	UPPER (c002))
					 WHERE	count_id > 1;
			EXCEPTION
				WHEN OTHERS
				THEN
					l_tmp := 3;
			END;

			IF l_tmp != 3
			THEN
				LOOP
					FETCH l_rc
					INTO l_cwms_id_dup;

					EXIT WHEN l_rc%NOTFOUND;

					OPEN l_rc_rows FOR
						SELECT	c001
						  FROM	apex_collections
						 WHERE	collection_name = UPPER (p_collection_name)
									AND UPPER (c002) = l_cwms_id_dup;

					l_rows_msg := NULL;
					l_tmp := 0;

					LOOP
						FETCH l_rc_rows
						INTO l_row_num;

						EXIT WHEN l_rc_rows%NOTFOUND;

						IF l_tmp = 1
						THEN
							l_rows_msg := l_rows_msg || ', ';
						END IF;

						l_rows_msg := l_rows_msg || TO_CHAR (l_row_num);
						l_tmp := 1;
					END LOOP;

					l_seq_id :=
						apex_collection.add_member (p_error_collection_name,
															 'dummy'
															);
					apex_collection.update_member_attribute (
						p_collection_name   => p_error_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => 1,
						p_attr_value		  => l_rows_msg
					);
					apex_collection.update_member_attribute (
						p_collection_name   => p_error_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => 2,
						p_attr_value		  => 'ERROR: cwms ts id is defined on multiple lines.'
					);
					apex_collection.update_member_attribute (
						p_collection_name   => p_error_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => 3,
						p_attr_value		  => l_cwms_id_dup
					);
				END LOOP;

				--
				--
				CLOSE l_rc;

				CLOSE l_rc_rows;

				OPEN l_rc FOR
					SELECT	shef_id
					  FROM	(SELECT		UPPER (c003 || '.' || c004 || '.' || c005 || '.' || c006) shef_id,
												COUNT (UPPER (c003 || '.' || c004 || '.' || c005 || '.' || c006)) count_id
									  FROM	apex_collections
									 WHERE	collection_name = UPPER (p_collection_name)
								 GROUP BY	UPPER (
														c003
													|| '.'
													|| c004
													|| '.'
													|| c005
													|| '.'
													|| c006
												))
					 WHERE	count_id > 1;

				LOOP
					FETCH l_rc
					INTO l_shef_id_dup;

					EXIT WHEN l_rc%NOTFOUND;

					OPEN l_rc_rows FOR
						SELECT	c001
						  FROM	apex_collections
						 WHERE	collection_name = UPPER (p_collection_name)
									AND UPPER (
												 c003
											 || '.'
											 || c004
											 || '.'
											 || c005
											 || '.'
											 || c006
										 ) = l_shef_id_dup;

					l_rows_msg := NULL;
					l_tmp := 0;

					LOOP
						FETCH l_rc_rows
						INTO l_row_num;

						EXIT WHEN l_rc_rows%NOTFOUND;

						IF l_tmp = 1
						THEN
							l_rows_msg := l_rows_msg || ', ';
						END IF;

						l_rows_msg := l_rows_msg || l_row_num;
						l_tmp := 1;
					END LOOP;

					l_seq_id :=
						apex_collection.add_member (p_error_collection_name,
															 'dummy'
															);
					apex_collection.update_member_attribute (
						p_collection_name   => p_error_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => 1,
						p_attr_value		  => l_rows_msg
					);
					apex_collection.update_member_attribute (
						p_collection_name   => p_error_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => 2,
						p_attr_value		  => 'ERROR: SHEF id is defined on multiple lines.'
					);
					apex_collection.update_member_attribute (
						p_collection_name   => p_error_collection_name,
						p_seq 				  => l_seq_id,
						p_attr_number		  => 3,
						p_attr_value		  => l_shef_id_dup
					);
				END LOOP;
			END IF;
		END IF;

		--   IF l_is_crit_file
		--   THEN
		--   cwms_shef.delete_data_stream (l_datastream, 'T', 'CWMS');
		--   END IF;

		--   DELETE FROM wwv_flow_files
		--   WHERE NAME = p_file_name;
		SELECT	COUNT (*)
		  INTO	l_seq_id
		  FROM	apex_collections
		 WHERE	collection_name = p_collection_name;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			l_process_id,
			'Completed ' || p_number_of_records || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);

		aa1 (
				'parse collection name: '
			|| p_collection_name
			|| ' Row count: '
			|| l_seq_id
		);
	END parse_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================

	--
	--  example:..
	--   desired result is either:
	--   if p_expr_value is equal to the p_expr_value_test  -
	--   then the string:  -
	--   ' 1 = 1 '   is returned                                       -
	--   else the string returned is...
	--   ' p_column_id = p_expr_string '                            -
	--
	--   For exmple:
	--   get_equal_predicate('sub_parameter_id', ':P535_SUB_PARM', :P535_SUB_PARM, '%');   -
	--   if :P535_SUB_PARM is '%' then....
	--   " 1=1 "  is returned.
	--
	--   if :P535_SUB_PARM is not '%' then...
	--   " sub_parameter_id = :P535_SUB_PARM " is returned.
	--   NOTE: quotes are not part of the string - there is a leading and trailing space character.
	--
	FUNCTION get_equal_predicate (p_column_id 		  IN VARCHAR2,
											p_expr_string		  IN VARCHAR2,
											p_expr_value		  IN VARCHAR2,
											p_expr_value_test   IN VARCHAR2
										  )
		RETURN VARCHAR2
	IS
		l_return_predicate	VARCHAR2 (100) := ' 1=1 ';
		l_column_id 			VARCHAR2 (31) := TRIM (p_column_id);
	BEGIN
		IF p_expr_value != p_expr_value_test
		THEN
			l_return_predicate :=
				' ' || l_column_id || ' = ''' || TRIM (p_expr_value) || ''' ';
		ELSIF p_expr_value IS NULL
		THEN
			l_return_predicate := ' ' || l_column_id || ' IS NULL ';
		END IF;

		RETURN l_return_predicate;
	END get_equal_predicate;

	FUNCTION get_primary_db_office_id
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN cwms_util.user_office_id;
	END get_primary_db_office_id;

	FUNCTION calc_seasonal_mn_offset (f_005 IN VARCHAR2)
		RETURN NUMBER
	IS
		temp_out   NUMBER;
		temp_yr	  NUMBER DEFAULT 0;
		temp_mn	  NUMBER DEFAULT 0;
	BEGIN
		temp_mn := TO_NUMBER (TRIM (SUBSTR (f_005, INSTR (f_005, '-') + 1)));
		temp_yr := TO_NUMBER (TRIM (SUBSTR (f_005, 1, INSTR (f_005, '-') - 1)));
		temp_out := temp_yr * 12 + temp_mn;
		RETURN temp_out;
	END calc_seasonal_mn_offset;

	FUNCTION get_header_by_column_num (
		f_column_number	IN apex_collections.c001%TYPE,
		f_import_type		IN NUMBER
	)
		RETURN VARCHAR2
	IS
		temp_out   VARCHAR2 (1999);
	BEGIN
		CASE UPPER (f_import_type)
			WHEN 1
			THEN																		  --location
				NULL;
			WHEN 2
			THEN																 --location levels
				CASE f_column_number
					WHEN 'C002'
					THEN
						temp_out := 'LOCATION LEVEL';
					WHEN 'C003'
					THEN
						temp_out := 'CONSTANT LEVEL';
					WHEN 'C004'
					THEN
						temp_out := 'UNIT';
					WHEN 'C005'
					THEN
						temp_out := 'CALENDAR OFFSET';
					WHEN 'C006'
					THEN
						temp_out := 'TIME OFFSET';
					WHEN 'C007'
					THEN
						temp_out := 'SEASONAL VALUE';
					WHEN 'C007'
					THEN
						temp_out := 'OFFICE';
					ELSE
						NULL;
				END CASE;
			WHEN 3
			THEN													--Location level indicators
				NULL;
			ELSE
				NULL;
		END CASE;

		RETURN temp_out;
	END get_header_by_column_num;

	FUNCTION get_unit_code_from_code_id (
		f_unit_id	IN cwms_unit.unit_id%TYPE,
		p_file_id	IN NUMBER
	)
		--RETURN VARCHAR2
		RETURN cwms_unit.unit_code%TYPE
	IS
		temp_out   cwms_unit.unit_code%TYPE;
	BEGIN
		--RETURN ' COming in = ' || f_unit_id || ' with a length of ' || LENGTH(f_unit_id);

		IF f_unit_id IS NULL
		THEN
			RETURN NULL;
		END IF;

		SELECT	unit_code
		  INTO	temp_out
		  FROM	cwms_unit
		 WHERE	unit_id = f_unit_id; 							--'n/a'; --f_unit_id;



		RETURN temp_out;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			set_log_row (
				p_error_text	 => ' Error in get_unit_code_from_code_id NO DATA FOUND for unit_id '
										|| f_unit_id,
				p_file_id		 => p_file_id,
				p_pl_sql_text	 => 'SELECT unit_code FROM cwms_unit WHERE unit_id = '
										|| f_unit_id
			);


			cwms_err.raise ('no_data_found', f_unit_id, 'unit code');
	END get_unit_code_from_code_id;

	FUNCTION get_headers_for_apex_rpt (f_import_type IN NUMBER)
		RETURN VARCHAR2
	IS
		temp_out   VARCHAR2 (1999);
	BEGIN
		CASE f_import_type
			WHEN 2
			THEN
				FOR x IN (SELECT	 1 d
								FROM	 DUAL
							 UNION ALL
							 SELECT	 2 d
								FROM	 DUAL
							 UNION ALL
							 SELECT	 3 d
								FROM	 DUAL
							 UNION ALL
							 SELECT	 4 d
								FROM	 DUAL
							 UNION ALL
							 SELECT	 5 d
								FROM	 DUAL
							 UNION ALL
							 SELECT	 6 d
								FROM	 DUAL
							 UNION ALL
							 SELECT	 7 d
								FROM	 DUAL)
				LOOP
					IF temp_out IS NULL
					THEN
						temp_out :=
							get_header_by_column_num ('C00' || TO_CHAR (x.d),
															  f_import_type
															 );
					ELSE
						temp_out :=
							temp_out || ':'
							|| get_header_by_column_num ('C00' || TO_CHAR (x.d),
																  f_import_type
																 );
					END IF;
				END LOOP;


				NULL;
			ELSE
				NULL;
		END CASE;

		RETURN temp_out;
	END get_headers_for_apex_rpt;

	FUNCTION get_location_level_id_param (f_location_level_id	IN VARCHAR2,
													  f_loc_num 				IN NUMBER
													 )
		RETURN VARCHAR2
	IS
		temp_out   VARCHAR2 (1999);
	BEGIN
		FOR x IN (SELECT	 TO_NUMBER (ROWNUM) row_num,
								 REPLACE (COLUMN_VALUE, '"', '') col_val
						FROM	 TABLE (SELECT   str2tbl (f_location_level_id, '.')
											 FROM   DUAL))
		LOOP
			--RETURN x.row_num;
			CASE x.row_num
				WHEN f_loc_num
				THEN
					temp_out := x.col_val;
				ELSE
					NULL;
			END CASE;
		END LOOP;

		RETURN temp_out;
	END get_location_level_id_param;

	FUNCTION strip_for_stragg (f_string IN VARCHAR2)
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN TRANSLATE (f_string, g_bad_chars, 'a');

		g_bad_chars := 'a';

		FOR i IN 0 .. 255
		LOOP
			IF (	  i NOT BETWEEN ASCII ('a') AND ASCII ('z')
				 AND i NOT BETWEEN ASCII ('A') AND ASCII ('Z')
				 AND i NOT BETWEEN ASCII ('0') AND ASCII ('9')
				 AND i NOT BETWEEN ASCII (',') AND ASCII (',')
				 AND i NOT BETWEEN ASCII ('/') AND ASCII ('/'))
			THEN
				g_bad_chars := g_bad_chars || CHR (i);
			END IF;
		END LOOP;
	END strip_for_stragg;



	FUNCTION str2tbl (p_str IN VARCHAR2, p_delim IN VARCHAR2 DEFAULT ',')
		RETURN str_tab_t
		PIPELINED
	AS
		l_str   LONG DEFAULT p_str || p_delim;
		l_n	  NUMBER;
	BEGIN
		LOOP
			l_n := INSTR (l_str, p_delim);
			EXIT WHEN (NVL (l_n, 0) = 0);
			PIPE ROW (LTRIM (RTRIM (SUBSTR (l_str, 1, l_n - 1))));
			l_str := SUBSTR (l_str, l_n + 1);
		END LOOP;

		RETURN;
	END str2tbl;

	FUNCTION valid_csv_header (f_file_type 	IN NUMBER,
										f_header_loc	IN NUMBER,
										f_header_val	IN VARCHAR2
									  )
		RETURN VARCHAR2
	IS
		temp_var 			c_app_logic_no%TYPE DEFAULT c_app_logic_no;
		temp_header_val	VARCHAR2 (1999);
	/******************************************************************************
	 NAME: f_valid_csv_header
	 PURPOSE:

	 REVISIONS:
	 Ver	 Date  Author	Description
	 --------- ---------- ---------------	------------------------------------
	 1.0	 7/6/2010 JDK	1. Created this function.
	 1.1	 10NOV2010	JDK	1. Operationalized function into package
			2. Made case insensitive per APABST request

	 NOTES:

	 Automatically available Auto Replace Keywords:
	  Object Name:   f_valid_csv_header
	  Sysdate:	7/6/2010
	  Date and Time:	7/6/2010, 10:50:48 AM, and 7/6/2010 10:50:48 AM
	  Username:   (set in TOAD Options, Procedure Editor)
	  Table Name:	(set in the "New PL/SQL Object" dialog)

	******************************************************************************/
	BEGIN
		temp_header_val := UPPER (f_header_val);


		CASE f_file_type
			WHEN 1
			THEN
				temp_var := c_app_logic_no;
			WHEN 2
			THEN
				-- this is a location_level
				CASE
					WHEN f_header_loc = 2 AND temp_header_val = 'LOCATION LEVEL'
					THEN
						temp_var := c_app_logic_yes;
					WHEN f_header_loc = 3 AND temp_header_val = 'CONSTANT LEVEL'
					THEN
						temp_var := c_app_logic_yes;
					WHEN f_header_loc = 4 AND temp_header_val = 'UNIT'
					THEN
						temp_var := c_app_logic_yes;
					WHEN f_header_loc = 5 AND temp_header_val = 'CALENDAR OFFSET'
					THEN
						temp_var := c_app_logic_yes;
					WHEN f_header_loc = 6 AND temp_header_val = 'TIME OFFSET'
					THEN
						temp_var := c_app_logic_yes;
					WHEN f_header_loc = 7 AND temp_header_val = 'SEASONAL VALUE'
					THEN
						temp_var := c_app_logic_yes;
					WHEN f_header_loc = 8 AND temp_header_val = 'OFFICE'
					THEN
						temp_var := c_app_logic_yes;
					ELSE
						temp_var := c_app_logic_no;
				END CASE;														  --loc and val
			WHEN 3
			THEN
				-- this is a location_level indicator
				temp_var := c_app_logic_no;
			ELSE
				temp_var := c_app_logic_no;
		END CASE;

		RETURN temp_var;
	END valid_csv_header;

	--=============================================================================
	--=============================================================================
	--=============================================================================

	PROCEDURE store_parsed_crit_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_loc_group_id 					IN VARCHAR2,
		p_data_stream_id					IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_parsed_rows			  NUMBER;
		l_shef_duration_code   VARCHAR2 (5);
		l_line_no				  VARCHAR2 (32);
		l_cwms_ts_id			  VARCHAR2 (200);
		l_shef_id				  VARCHAR2 (32);
		l_pe_code				  VARCHAR2 (32);
		l_tse_code				  VARCHAR2 (32);
		l_dur_code				  VARCHAR2 (32);
		l_units					  VARCHAR2 (32);
		l_unit_system			  VARCHAR2 (32);
		l_tz						  VARCHAR2 (32);
		l_dltime 				  VARCHAR2 (32);
		l_int_offset			  VARCHAR2 (32);
		l_int_backward 		  VARCHAR2 (32);
		l_int_forward			  VARCHAR2 (32);
		l_min 					  NUMBER;
		l_max 					  NUMBER;
		l_cmt 					  VARCHAR2 (256);
		l_steps_per_commit	  NUMBER;
	BEGIN
		aa1 (
			'store_parsed_crit_file - collection name: '
			|| p_parsed_collection_name
		);

		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		FOR i IN 1 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;


			SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
						c011, c012, c013
			  INTO	l_line_no, l_cwms_ts_id, l_shef_id, l_pe_code, l_tse_code,
						l_dur_code, l_units, l_unit_system, l_tz, l_dltime,
						l_int_offset, l_int_backward, l_int_forward
			  FROM	apex_collections
			 WHERE	collection_name = p_parsed_collection_name AND seq_id = i;

			-- convert duration numeric to duration code
			BEGIN
				SELECT	shef_duration_code || shef_duration_numeric
				  INTO	l_shef_duration_code
				  FROM	cwms_shef_duration
				 WHERE	shef_duration_numeric = l_dur_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					l_shef_duration_code := 'V' || TRIM (l_dur_code);
			END;

			-- confert dltime to t or f
			IF l_dltime IS NOT NULL
			THEN
				IF l_dltime = 'false'
				THEN
					l_dltime := 'F';
				ELSIF l_dltime = 'true'
				THEN
					l_dltime := 'T';
				END IF;
			END IF;

			aa1 (
					'storing spec: '
				|| l_cwms_ts_id
				|| ' --datastream->'
				|| p_data_stream_id
				|| ' --shef id->'
				|| l_shef_id
			);
			--
			aa1 (
					'l_int_offset = '
				|| l_int_offset
				|| ' l_int_forward '
				|| l_int_forward
				|| ' l_int_backward '
				|| l_int_backward
			);
			--
			aa1 ('Calling cwms_shef.store_shef_spec');
			cwms_shef.store_shef_spec (
				p_cwms_ts_id				  => l_cwms_ts_id,
				p_data_stream_id			  => p_data_stream_id,
				p_loc_group_id 			  => p_loc_group_id,
				p_shef_loc_id				  => l_shef_id,
				-- normally use loc_group_id
				p_shef_pe_code 			  => l_pe_code,
				p_shef_tse_code			  => l_tse_code,
				p_shef_duration_code 	  => l_shef_duration_code,
				p_shef_unit_id 			  => l_units,
				p_time_zone_id 			  => l_tz,
				p_daylight_savings		  => l_dltime,
				-- psuedo boolean.
				p_interval_utc_offset	  => TO_NUMBER (l_int_offset),
				-- in minutes.
				p_snap_forward_minutes	  => TO_NUMBER (l_int_forward),
				p_snap_backward_minutes   => TO_NUMBER (l_int_backward),
				p_ignore_shef_spec		  => NULL,
				p_db_office_id 			  => p_db_office_id
			);
		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_crit_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================


	PROCEDURE store_parsed_crit_csv_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_loc_group_id 					IN VARCHAR2,
		p_data_stream_id					IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_parsed_rows			  NUMBER;
		l_shef_duration_code   VARCHAR2 (5);
		l_line_no				  VARCHAR2 (32);
		l_cwms_ts_id			  VARCHAR2 (200);
		l_shef_id				  VARCHAR2 (32);
		l_pe_code				  VARCHAR2 (32);
		l_tse_code				  VARCHAR2 (32);
		l_dur_code				  VARCHAR2 (32);
		l_location_id			  VARCHAR2 (32);
		l_parameter_id 		  VARCHAR2 (32);
		l_type_id				  VARCHAR2 (32);
		l_interval_id			  VARCHAR2 (32);
		l_duration_id			  VARCHAR2 (32);
		l_version_id			  VARCHAR2 (32);
		l_units					  VARCHAR2 (32);
		l_unit_system			  VARCHAR2 (32);
		l_tz						  VARCHAR2 (32);
		l_dltime 				  VARCHAR2 (32);
		l_int_offset			  VARCHAR2 (32);
		l_int_backward 		  VARCHAR2 (32);
		l_int_forward			  VARCHAR2 (32);
		l_active 				  VARCHAR2 (32);
		l_office 				  VARCHAR2 (32);
		l_min 					  NUMBER;
		l_max 					  NUMBER;
		l_cmt 					  VARCHAR2 (256);
		l_steps_per_commit	  NUMBER;
	BEGIN
		aa1 (
			'store_parsed_crit_csv_file - collection name: '
			|| p_parsed_collection_name
		);

		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		--=======  Start at 2 to skip Heading
		FOR i IN 2 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;


			SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
						c011, c012, c013, c014, c015, c016, c017, c018, c019
			  INTO	l_line_no, l_shef_id, l_pe_code, l_tse_code, l_dur_code,
						l_location_id, l_parameter_id, l_type_id, l_interval_id,
						l_duration_id, l_version_id, l_tz, l_dltime, l_units,
						l_int_offset, l_int_forward, l_int_backward, l_active,
						l_office
			  FROM	apex_collections
			 WHERE	collection_name = p_parsed_collection_name AND seq_id = i;

			-- convert duration numeric to duration code
			BEGIN
				SELECT	shef_duration_code || shef_duration_numeric
				  INTO	l_shef_duration_code
				  FROM	cwms_shef_duration
				 WHERE	shef_duration_numeric = l_dur_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					l_shef_duration_code := 'V' || TRIM (l_dur_code);
			END;

			-- confert dltime to t or f
			IF l_dltime IS NOT NULL
			THEN
				IF l_dltime = 'false'
				THEN
					l_dltime := 'F';
				ELSIF l_dltime = 'true'
				THEN
					l_dltime := 'T';
				END IF;
			END IF;

			-- pack up cwms ts id  =======================================================
			l_cwms_ts_id :=
					l_location_id
				|| '.'
				|| l_parameter_id
				|| '.'
				|| l_type_id
				|| '.'
				|| l_interval_id
				|| '.'
				|| l_duration_id
				|| '.'
				|| l_version_id;

			aa1 (
					'storing spec: '
				|| l_cwms_ts_id
				|| ' --datastream->'
				|| p_data_stream_id
				|| ' --shef id->'
				|| l_shef_id
			);
			--
			aa1 (
					'l_int_offset = '
				|| l_int_offset
				|| ' l_int_forward '
				|| l_int_forward
				|| ' l_int_backward '
				|| l_int_backward
			);

			--
			IF (l_int_offset = 'N/A')
			THEN
				l_int_offset := NULL;
			END IF;

			IF (l_int_offset = 'Undefined')
			THEN
				l_int_offset := NULL;
			END IF;

			aa1 ('Calling cwms_shef.store_shef_spec');
			cwms_shef.store_shef_spec (
				p_cwms_ts_id				  => l_cwms_ts_id,
				p_data_stream_id			  => p_data_stream_id,
				p_loc_group_id 			  => p_loc_group_id,
				p_shef_loc_id				  => l_shef_id,
				-- normally use loc_group_id
				p_shef_pe_code 			  => l_pe_code,
				p_shef_tse_code			  => l_tse_code,
				p_shef_duration_code 	  => l_shef_duration_code,
				p_shef_unit_id 			  => l_units,
				p_time_zone_id 			  => l_tz,
				p_daylight_savings		  => l_dltime,
				-- psuedo boolean.
				p_interval_utc_offset	  => TO_NUMBER (TRIM (l_int_offset)),
				-- in minutes.
				p_snap_forward_minutes	  => TO_NUMBER (TRIM (l_int_forward)),
				p_snap_backward_minutes   => TO_NUMBER (TRIM (l_int_backward)),
				p_ignore_shef_spec		  => l_active,
				p_db_office_id 			  => p_db_office_id
			);
		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_crit_csv_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================

	PROCEDURE store_parsed_loc_short_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_location_id			VARCHAR2 (200);
		l_public_name			VARCHAR2 (200);
		l_county_name			VARCHAR2 (200);
		l_state_initial		VARCHAR2 (20);
		l_active 				VARCHAR2 (10);
		l_ignorenulls			VARCHAR2 (1);
		l_parsed_rows			NUMBER;
		l_line_no				VARCHAR2 (32);
		l_min 					NUMBER;
		l_max 					NUMBER;
		l_cmt 					VARCHAR2 (256);
		l_steps_per_commit	NUMBER;
	BEGIN
		aa1 (
			'store_parsed_loc_short_file - collection name: '
			|| p_parsed_collection_name
		);

		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		-- Start at 2 to skip first line of column titles
		FOR i IN 2 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;


			SELECT	c001, c002, c003, c004, c005, c006
			  INTO	l_line_no, l_location_id, l_public_name, l_county_name,
						l_state_initial, l_active
			  FROM	apex_collections
			 WHERE	collection_name = p_parsed_collection_name AND seq_id = i;

			aa1 ('storing locs: ' || l_location_id);
			--
			cwms_loc.store_location (p_location_id 	 => l_location_id,
											 p_public_name 	 => l_public_name,
											 p_county_name 	 => l_county_name,
											 p_state_initial	 => l_state_initial,
											 p_active			 => l_active,
											 p_ignorenulls 	 => 'T',
											 p_db_office_id	 => p_db_office_id
											);
		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_loc_short_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================
	PROCEDURE store_parsed_loc_full_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_location_id				VARCHAR2 (200);
		l_location_type			VARCHAR2 (200);
		l_elevation 				NUMBER;
		l_elev_unit_id 			VARCHAR2 (200);
		l_vertical_datum			VARCHAR2 (200);
		l_latitude					NUMBER;
		l_lat_mins					NUMBER;
		l_lat_secs					NUMBER;
		l_longitude 				NUMBER;
		l_long_mins 				NUMBER;
		l_long_secs 				NUMBER;
		l_horizontal_datum		VARCHAR2 (200);
		l_public_name				VARCHAR2 (200);
		l_long_name 				VARCHAR2 (200);
		l_description				VARCHAR2 (200);
		l_time_zone_id 			VARCHAR2 (200);
		l_county_name				VARCHAR2 (200);
		l_state_initial			VARCHAR2 (200);
		l_active 					VARCHAR2 (200);
		l_ignorenulls				VARCHAR2 (1);
		l_parsed_rows				NUMBER;
		l_line_no					VARCHAR2 (32);
		l_min 						NUMBER;
		l_max 						NUMBER;
		l_loc_id 					VARCHAR2 (32);
		l_location_kind_id		VARCHAR2 (32);
		l_map_label 				VARCHAR2 (50);
		l_published_latitude 	NUMBER;
		l_published_longitude	NUMBER;
		l_bounding_office_id 	VARCHAR2 (16);
		l_nation_id 				VARCHAR (48);
		l_nearest_city 			VARCHAR2 (50);
		l_office_id_24 			VARCHAR2 (32);
		l_office_id_26 			VARCHAR2 (32);
		l_office_id_28 			VARCHAR2 (32);
		l_cmt 						VARCHAR2 (256);
		l_steps_per_commit		NUMBER;
	BEGIN
		aa1 (
			'store_parsed_loc_full_file - collection name: '
			|| p_parsed_collection_name
		);
		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		SELECT	c002, c024, c026, c028
		  INTO	l_loc_id, l_office_id_24, l_office_id_26, l_office_id_28
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name AND seq_id = 1;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		--   Start at 2, Skip first line in file to bypass column headings
		FOR i IN 2 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;

			l_latitude := 0;
			l_longitude := 0;
			l_lat_mins := 0;
			l_long_mins := 0;
			l_lat_secs := 0;
			l_long_secs := 0;

			IF (TRIM (NVL (l_loc_id, 'XXX')) = 'Location ID'
				 AND TRIM (NVL (l_office_id_24, 'XXX')) = 'Office')
			THEN
				SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009,
							c010, c011, c012, c013, c014, c015, c016, c017, c018,
							c019, c020, c021, c022, c023
				  INTO	l_line_no, l_location_id, l_public_name, l_county_name,
							l_state_initial, l_active, l_location_type,
							l_vertical_datum, l_elevation, l_elev_unit_id,
							l_horizontal_datum, l_latitude, l_longitude,
							l_time_zone_id, l_long_name, l_description,
							l_location_kind_id, l_map_label, l_published_latitude,
							l_published_longitude, l_bounding_office_id, l_nation_id,
							l_nearest_city
				  FROM	apex_collections
				 WHERE	collection_name = p_parsed_collection_name
							AND seq_id = i;
			ELSIF (TRIM (NVL (l_loc_id, 'XXX')) = 'Location ID'
					 AND TRIM (NVL (l_office_id_26, 'XXX')) = 'Office')
			THEN
				SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009,
							c010, c011, c012, c013, c014, c015, c016, c017, c018,
							c019, c020, c021, c022, c023, c024, c025
				  INTO	l_line_no, l_location_id, l_public_name, l_county_name,
							l_state_initial, l_active, l_location_type,
							l_vertical_datum, l_elevation, l_elev_unit_id,
							l_horizontal_datum, l_latitude, l_lat_mins, l_longitude,
							l_long_mins, l_time_zone_id, l_long_name, l_description,
							l_location_kind_id, l_map_label, l_published_latitude,
							l_published_longitude, l_bounding_office_id, l_nation_id,
							l_nearest_city
				  FROM	apex_collections
				 WHERE	collection_name = p_parsed_collection_name
							AND seq_id = i;
			ELSIF (TRIM (NVL (l_loc_id, 'XXX')) = 'Location ID'
					 AND TRIM (NVL (l_office_id_28, 'XXX')) = 'Office')
			THEN
				SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009,
							c010, c011, c012, c013, c014, c015, c016, c017, c018,
							c019, c020, c021, c022, c023, c024, c025, c026, c027
				  INTO	l_line_no, l_location_id, l_public_name, l_county_name,
							l_state_initial, l_active, l_location_type,
							l_vertical_datum, l_elevation, l_elev_unit_id,
							l_horizontal_datum, l_latitude, l_lat_mins, l_lat_secs,
							l_longitude, l_long_mins, l_long_secs, l_time_zone_id,
							l_long_name, l_description, l_location_kind_id,
							l_map_label, l_published_latitude, l_published_longitude,
							l_bounding_office_id, l_nation_id, l_nearest_city
				  FROM	apex_collections
				 WHERE	collection_name = p_parsed_collection_name
							AND seq_id = i;
			ELSE
				cwms_err.raise ('ERROR', 'Unable to parse data!');
			END IF;

			l_latitude :=
				(ABS (l_latitude) + l_lat_mins / 60 + l_lat_secs / 3600)
				* SIGN (l_latitude);
			l_longitude :=
				(ABS (l_longitude) + l_long_mins / 60 + l_long_secs / 3600)
				* SIGN (l_longitude);
			aa1 ('storing locs: ' || l_location_id);
			--
			cwms_loc.store_location2 (l_location_id,
											  l_location_type,
											  l_elevation,
											  l_elev_unit_id,
											  l_vertical_datum,
											  l_latitude,
											  l_longitude,
											  l_horizontal_datum,
											  l_public_name,
											  l_long_name,
											  l_description,
											  l_time_zone_id,
											  l_county_name,
											  l_state_initial,
											  l_active,
											  l_location_kind_id,
											  l_map_label,
											  l_published_latitude,
											  l_published_longitude,
											  l_bounding_office_id,
											  l_nation_id,
											  l_nearest_city,
											  'F',
											  p_db_office_id
											 );
		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_loc_full_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================

	PROCEDURE store_parsed_loc_alias_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_location_id			VARCHAR2 (200);
		l_alias					VARCHAR2 (200);
		l_group					VARCHAR2 (200);
		l_ignorenulls			VARCHAR2 (1);
		l_parsed_rows			NUMBER;
		l_line_no				VARCHAR2 (32);
		l_min 					NUMBER;
		l_max 					NUMBER;
		l_cmt 					VARCHAR2 (256);
		l_steps_per_commit	NUMBER;
	BEGIN
		aa1 (
			'store_parsed_loc_alias_file - collection name: '
			|| p_parsed_collection_name
		);

		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;


		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		-- Start at 2 to skip first line of column titles
		FOR i IN 2 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;


			SELECT	c001, c002, c003, c004
			  INTO	l_line_no, l_location_id, l_alias, l_group
			  FROM	apex_collections
			 WHERE	collection_name = p_parsed_collection_name AND seq_id = i;

			aa1 ('storing locaa: ' || l_location_id);
			--
			cwms_loc.assign_loc_group (p_loc_category_id   => 'Agency Aliases',
												p_loc_group_id 	  => l_group,
												p_location_id		  => l_location_id,
												p_loc_alias_id 	  => l_alias,
												p_db_office_id 	  => p_db_office_id
											  );
		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_loc_alias_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================

	PROCEDURE store_parsed_screen_base_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_line_no						VARCHAR2 (32);
		l_screening_id 				VARCHAR2 (32);
		l_screening_id_desc			VARCHAR2 (256);
		l_parameter_id 				VARCHAR2 (32);
		l_parameter_type_id			VARCHAR2 (32);
		l_duration_id					VARCHAR2 (32);
		l_unit_id						VARCHAR2 (32);
		l_range_active_flag			VARCHAR2 (10);
		l_range_active_flag_char	VARCHAR2 (1);
		l_range_reject_lo 			VARCHAR2 (32);
		l_range_question_lo			VARCHAR2 (32);
		l_range_question_hi			VARCHAR2 (32);
		l_range_reject_hi 			VARCHAR2 (32);
		l_db_office_id 				VARCHAR2 (32);

		l_ignorenulls					VARCHAR2 (1);
		l_parsed_rows					NUMBER;
		--l_line_no   VARCHAR2 (32);
		l_min 							NUMBER;
		l_max 							NUMBER;

		l_cmt 							VARCHAR2 (256);
		l_steps_per_commit			NUMBER;
		--  l_scrn_data	  SCREEN_CRIT_ARRAY

		l_scrn_data 					screen_crit_array := screen_crit_array ();
		l_d_m_data						screen_dur_mag_array
												:= screen_dur_mag_array ();
		l_scn_cntl						screening_control_t;
		i_num 							NUMBER;
		j_num 							NUMBER;
	BEGIN
		aa1 (
			'store_parsed_loc_short_file - collection name: '
			|| p_parsed_collection_name
		);

		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		-- Start at 2 to skip first line of column titles
		FOR i IN 2 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;


			SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009, c010,
						c011, c012, c013
			  INTO	l_line_no, l_screening_id, l_screening_id_desc,
						l_parameter_id, l_parameter_type_id, l_duration_id,
						l_unit_id, l_range_active_flag, l_range_reject_lo,
						l_range_question_lo, l_range_question_hi, l_range_reject_hi,
						l_db_office_id
			  FROM	apex_collections
			 WHERE	collection_name = p_parsed_collection_name AND seq_id = i;

			aa1 ('storing locs: ' || l_screening_id);

			--===================================================================================================
			BEGIN
				i_num := 1;
				j_num := 5;

				FOR i IN 1 .. i_num
				LOOP
					FOR j IN 1 .. j_num
					LOOP
						l_d_m_data.EXTEND;
					END LOOP;

					--   l_d_m_data(1) := screen_dur_mag_type ('1Hour', 0,
					--   :P1535_R_DUR_MAG_1H, 0, :P1535_Q_DUR_MAG_1H);
					--   l_d_m_data(2) := screen_dur_mag_type ('3Hours', 0,
					--   :P1535_R_DUR_MAG_3H, 0, :P1535_Q_DUR_MAG_3H);
					--   l_d_m_data(3) := screen_dur_mag_type ('6Hours', 0,
					--   :P1535_R_DUR_MAG_6H, 0, :P1535_Q_DUR_MAG_6H);
					--   l_d_m_data(4) := screen_dur_mag_type ('12Hours', 0,
					--   :P1535_R_DUR_MAG_12H, 0, :P1535_Q_DUR_MAG_12H);
					--   l_d_m_data(5) := screen_dur_mag_type ('1Day', 0,
					--   :P1535_R_DUR_MAG_24H, 0, :P1535_Q_DUR_MAG_24H);

					l_d_m_data (1) :=
						screen_dur_mag_type ('1Hour', 0, NULL, 0, NULL);
					l_d_m_data (2) :=
						screen_dur_mag_type ('3Hours', 0, NULL, 0, NULL);
					l_d_m_data (3) :=
						screen_dur_mag_type ('6Hours', 0, NULL, 0, NULL);
					l_d_m_data (4) :=
						screen_dur_mag_type ('12Hours', 0, NULL, 0, NULL);
					l_d_m_data (5) :=
						screen_dur_mag_type ('1Day', 0, NULL, 0, NULL);


					l_scrn_data.EXTEND;
					l_scrn_data (i) :=
						screen_crit_type (1,
												1,
												l_range_reject_lo,
												l_range_reject_hi,
												l_range_question_lo,
												l_range_question_hi,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												NULL,
												l_d_m_data
											  );
				--   :P1535_RATE_CHANGE_REJECT_RISE,
				--   :P1535_RATE_CHANGE_REJECT_FALL,
				--   :P1535_RATE_CHANGE_QUEST_RISE,
				--   :P1535_RATE_CHANGE_QUEST_FALL,
				--   :P1535_CONST_REJECT_DURATION,
				--   :P1535_CONST_REJECT_MIN,
				--   :P1535_CONST_REJECT_TOLERANCE,
				--   :P1535_CONST_REJECT_N_MISS,
				--   :P1535_CONST_QUEST_DURATION,
				--   :P1535_CONST_QUEST_MIN,
				--   :P1535_CONST_QUEST_TOLERANCE,
				--   :P1535_CONST_QUEST_N_MISS,

				END LOOP;

				-- decode(RANGE_ACTIVE_FLAG, ''T'', ''Active'', ''F'', ''In-active'', ''N'', ''Not Used'', '''', ''Not Used'')
				IF (l_range_active_flag = 'Active')
				THEN
					l_range_active_flag_char := 'T';
				ELSIF (l_range_active_flag = 'In-active')
				THEN
					l_range_active_flag_char := 'F';
				ELSIF (l_range_active_flag = 'Not Used')
				THEN
					l_range_active_flag_char := 'N';
				ELSE
					l_range_active_flag_char := NULL;
				END IF;

				l_scn_cntl :=
					screening_control_t (l_range_active_flag_char, 'N', 'N', 'N');
				--   :P1535_STATUS_RATE_OF_CHANGE,
				--   :P1535_STATUS_CONSTANT_VALUE,
				--   :P1535_STATUS_DUR_MAG);

				cwms_vt.store_screening_criteria (
					p_screening_id 						=> l_screening_id,
					p_unit_id								=> l_unit_id,
					p_screen_crit_array					=> l_scrn_data,
					p_rate_change_disp_interval_id	=> NULL,
					p_screening_control					=> l_scn_cntl,
					p_store_rule							=> 'DELETE INSERT',
					p_ignore_nulls 						=> 'T',
					p_db_office_id 						=> l_db_office_id
				);
			END;
		--====================================================================================================

		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_screen_base_file;

	--=============================================================================
	--=============================================================================
	--=============================================================================
	/*  PROCEDURE parse_crit_file (			--{{{
	  p_file_name	  IN	VARCHAR2,
	  p_collection_name	IN  VARCHAR2,
	  p_error_collection_name	IN   VARCHAR2,
	  p_headings_item   IN	VARCHAR2,
	  p_columns_item	IN  VARCHAR2,
	  p_ddl_item	 IN  VARCHAR2,
	  p_number_of_records	 OUT NUMBER,
	  p_number_of_columns	 OUT NUMBER,
	  p_is_csv	  IN	 VARCHAR2 DEFAULT 'T' ,
	  p_db_office_id	IN  VARCHAR2,
	  p_process_id   IN	 VARCHAR2
	  )
	  IS
	  l_blob 	 BLOB;
	  l_records 	 varchar2_t;
	  l_record	  wwv_flow_global.vc_arr2;
	  l_idx	  NUMBER := 1;
	  l_datatypes	  wwv_flow_global.vc_arr2;
	  l_headings	 VARCHAR2 (4000);
	  l_columns 	 VARCHAR2 (4000);
	  l_seq_id	  NUMBER;
	  l_num_columns	 INTEGER;
	  l_ddl	  VARCHAR2 (4000);
	  l_is_csv	  BOOLEAN;
	  l_error_message   VARCHAR2 (512);

	  l_tmp	  NUMBER;
	  l_comment 	 VARCHAR2 (128) := NULL;
	  l_datastream 	 VARCHAR2 (16);
	  l_cwms_seq	 NUMBER;
	  l_len	  NUMBER;
	  l_first_record	  NUMBER := 2;
	  --
	  l_rc		sys_refcursor;
	  l_cwms_id_dup	 VARCHAR2 (183);
	  l_shef_id_dup	 VARCHAR2 (183);
	  --
	  l_rc_rows 	 sys_refcursor;
	  l_row_num 	 NUMBER;
	  l_rows_msg	 VARCHAR2 (1000);
	  l_cmt	  VARCHAR2 (256);
	  l_steps_per_commit   NUMBER;
	  l_cwms_ts_id 	 VARCHAR2 (183);
	  l_cwms_ts_code	  NUMBER;

	  l_unit_code	  NUMBER;
	  l_base_parameter_code   NUMBER;
	  l_base_parameter_id	 VARCHAR2 (50);
	  l_parameter_type_code   NUMBER;
	  l_interval_code   NUMBER;
	  l_duration_code   NUMBER;
	  l_db_office_id	  VARCHAR2 (16)
	  := cwms_util.get_db_office_id (p_db_office_id) ;
	  l_abstract_param_id	 VARCHAR2 (16);
	  l_abstract_param_code   NUMBER;
	  l_abstract_param_code_user	NUMBER;
	  l_unit_code_en	  NUMBER;
	  l_unit_code_si	  NUMBER;
	  l_unit_id_en 	 VARCHAR2 (16);
	  l_unit_id_si 	 VARCHAR2 (16);
	  BEGIN
	  DELETE FROM	gt_shef_decodes1;

	  IF cwms_util.is_true (NVL (p_is_csv, 'T'))
	  THEN
	  l_is_csv := TRUE;
	  ELSE
	  l_is_csv := FALSE;
	  l_first_record := 1;
	  END IF;

	  aa1 ('>>parse_crit_file<< parse collection name: ' || p_collection_name
		);

	  BEGIN
	  SELECT blob_content
	  INTO l_blob
	  FROM wwv_flow_files
		WHERE name = p_file_name;
	  EXCEPTION
	  WHEN NO_DATA_FOUND
	  THEN
	  raise_application_error (-20000,
			 'File not found, id=' || p_file_name
			);
	  END;

	  aa1 ('>>parse_crit_file<< blob w/filename read: ' || p_file_name);
	  get_records (l_blob, l_records);

	  p_number_of_records := l_records.COUNT;
	  aa1('>>parse_crit_file<< number of records read in: '
		|| p_number_of_records);

	  IF (l_is_csv AND p_number_of_records < 2)
	  THEN
	  raise_application_error (
	  -20000,
	  'Your csv crit file contains less than two rows.
		 A valid csv file must consist of a header row and
		 at least one crit line. File read: '
	  || p_file_name
	  );
	  ELSIF (p_number_of_records < 1)
	  THEN
	  raise_application_error (
	  -20000,
	  'Your crit file appears to be empty. File read: ' || p_file_name
	  );
	  END IF;


	  -- Get column headings and datatypes
	  IF NOT l_is_csv
	  THEN
	  cwms_apex.aa1 ('Get column headings and datatypes');
	  l_record (1) := 'Line No.';
	  l_record (2) := 'cwms_ts_id';
	  l_record (3) := 'shef_id';
	  l_record (4) := 'pe_code';
	  l_record (5) := 'tse_code';
	  l_record (6) := 'dur_code';
	  l_record (7) := 'units';
	  l_record (8) := 'unit_system';
	  l_record (9) := 'tz';
	  l_record (10) := 'dltime';
	  l_record (11) := 'int_offset';
	  l_record (12) := 'int_backward';
	  l_record (13) := 'int_forward';
	  ELSE
	  csv_to_array (l_records (1), l_record);
	  END IF;

	  l_num_columns := l_record.COUNT;
	  aa1 ('>>parse_crit_file<< number of columns read in: ' || l_num_columns
		);

	  IF (l_num_columns > 50)
	  THEN
	  raise_application_error (
	  -20000,
	  'Max. of 50 columns allowed, id=' || p_file_name
	  );
	  END IF;

	  p_number_of_columns := l_num_columns;

	  -- Get column headings and names
	  FOR i IN 1 .. l_record.COUNT
	  LOOP
	  l_headings := l_headings || ':' || l_record (i);
	  l_columns := l_columns || ',c' || LPAD (i, 3, '0');
	  END LOOP;

	  l_headings := LTRIM (l_headings, ':');
	  l_columns := LTRIM (l_columns, ',');
	  apex_util.set_session_state (p_headings_item, l_headings);
	  apex_util.set_session_state (p_columns_item, l_columns);


	  aa1 ('>>parse_crit_file<< entering grand loop');

	  FOR i IN 2 .. p_number_of_records
	  LOOP
	  aa1 ('>>parse_crit_file<< l_records: ' || l_records (i));
	  l_error_message := NULL;
	  l_idx := l_idx + 1;

	  IF (l_steps_per_commit > 0)
	  THEN
	  IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
	  THEN
		 cwms_properties.set_property (
		 'PROCESS_STATUS',
		 p_process_id,
		 'Processing: ' || i || ' of ' || p_number_of_records,
		 l_cmt || LOCALTIMESTAMP,
		 p_db_office_id
		 );
		 COMMIT;
	  END IF;
	  END IF;

	  IF l_is_csv
	  THEN
	  csv_to_array (l_records (l_idx), l_record);
	  ELSE
	  crit_to_array (l_records (l_idx), l_comment, l_record);
	  END IF;

	  IF INSTR (l_comment, 'ERROR') = 1
	  THEN
	  l_seq_id :=
		 apex_collection.add_member (p_error_collection_name, 'dummy');
	  apex_collection.update_member_attribute (
		 p_collection_name => p_error_collection_name,
		 p_seq	=> l_seq_id,
		 p_attr_number  => 1,
		 p_attr_value	=> i
	  );
	  apex_collection.update_member_attribute (
		 p_collection_name => p_error_collection_name,
		 p_seq	=> l_seq_id,
		 p_attr_number  => 2,
		 p_attr_value	=> l_comment
	  );
	  apex_collection.update_member_attribute (
		 p_collection_name => p_error_collection_name,
		 p_seq	=> l_seq_id,
		 p_attr_number  => 3,
		 p_attr_value	=> l_records (l_idx)
	  );
	  ELSIF INSTR (l_comment, 'COMMENT') = 1
	  THEN
	  NULL;		 -- comment, so throw away.
	  ELSE
	  -- l_seq_id :=
	  -- apex_collection.add_member (p_collection_name, 'dummy');
	  -- apex_collection.update_member_attribute (
	  -- p_collection_name => p_collection_name,
	  -- p_seq => l_seq_id,
	  -- p_attr_number => 1,
	  -- p_attr_value => i
	  -- );

	  -- FOR j IN 1 .. l_record.COUNT
	  -- LOOP
	  -- apex_collection.update_member_attribute (
	  -- p_collection_name => p_collection_name,
	  -- p_seq => l_seq_id,
	  -- p_attr_number => j + 1,
	  -- p_attr_value => l_record (j)
	  -- );
	  -- END LOOP;
	  l_cwms_ts_id :=
		 l_record (5)
		 || '.'
		 || l_record (6)
		 || '.'
		 || l_record (7)
		 || '.'
		 || l_record (8)
		 || '.'
		 || l_record (9)
		 || '.'
		 || l_record (10);

	  BEGIN
		 l_cwms_ts_code :=
		 cwms_ts.get_ts_code (
		 p_cwms_ts_id => l_cwms_ts_id,
		 p_db_office_code => cwms_util.get_db_office_code (p_db_office_id)
		 );
	  EXCEPTION
		 WHEN OTHERS
		 THEN
		 l_cwms_ts_code := NULL;
	  END;

	  --
	  ---
	  ---- Is the unit_id valid?...
	  --
	  BEGIN
		 l_unit_code := cwms_util.get_unit_code (l_record (12), NULL);

		 SELECT	a.abstract_param_code
		 INTO  l_abstract_param_code_user
		 FROM  cwms_unit a
		WHERE  a.unit_code = l_unit_code;
	  EXCEPTION
		 WHEN OTHERS
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **ERROR: Unrecognized Unit Id: '
		 || l_record (12);
	  END;

	  --
	  ---
	  ---- Is the base parameter valid?...
	  --
	  BEGIN
		 l_base_parameter_id := cwms_util.get_base_id (l_record (6));
		 l_base_parameter_code :=
		 cwms_ts.get_parameter_code (l_base_parameter_id,
			 NULL,
			 p_db_office_id,
			 'F'
			  );
	  EXCEPTION
		 WHEN OTHERS
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **ERROR: The Parameter Id''s Base Parameter is not Recognized: '
		 || l_base_parameter_id;
	  END;

	  --
	  ---
	  ---- Is the parameter type valid?...
	  BEGIN
		 l_parameter_type_code :=
		 cwms_ts.get_parameter_type_code (l_record (7));
	  EXCEPTION
		 WHEN OTHERS
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **ERROR: The Parameter Type Id is not Recognized: '
		 || l_record (7);
	  END;

	  --
	  ---
	  ---- Is the interval_id valid?"...
	  BEGIN
		 SELECT	interval_code
		 INTO  l_interval_code
		 FROM  cwms_interval a
		WHERE  UPPER (a.interval_id) = UPPER (TRIM (l_record (8)));
	  EXCEPTION
		 WHEN NO_DATA_FOUND
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **ERROR: The Interval Id is not Recognized: '
		 || l_record (8);
	  END;


	  --
	  ---
	  ---- Is the PE Code valid?...
	  BEGIN
		 SELECT	abstract_param_code, abstract_param_id, unit_code_en,
		 unit_code_si, unit_id_en, unit_id_si
		 INTO  l_abstract_param_code, l_abstract_param_id,
		 l_unit_code_en, l_unit_code_si, l_unit_id_en,
		 l_unit_id_si
		 FROM  av_shef_pe_codes a
		WHERE  shef_pe_code = UPPER (TRIM (l_record (4)))
		 AND db_office_id IN (l_db_office_id, 'CWMS');

		 IF l_abstract_param_code != l_abstract_param_code_user
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **ERROR: The unit you specified: '
		 || l_record (12)
		 || ' needs to be a unit of type '
		 || l_abstract_param_id
		 || '. Default units for this SHEF PE Code are either: '
		 || l_unit_id_en
		 || ' or '
		 || l_unit_id_si
		 || '.';
		 ELSIF l_unit_code NOT IN (l_unit_code_en, l_unit_code_si)
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **WARNING: The unit you specified: '
		 || l_record (12)
		 || ' is not a default unit for this SHEF PE Code, namely: '
		 || l_unit_id_en
		 || ' or '
		 || l_unit_id_si
		 || '. Please be sure your data is being recieved with this non-standard unit.';
		 END IF;
	  EXCEPTION
		 WHEN NO_DATA_FOUND
		 THEN
		 l_error_message :=
		 l_error_message
		 || ' **ERROR: The SHEF PE Code:
	  '
		 || l_record (4)
		 || ' is not Recognized';
	  END;

	  --
	  ---
	  ---- Is the duration_id valid?...
	  BEGIN
		 SELECT	duration_code
		 INTO  l_duration_code
		 FROM  cwms_duration a
		WHERE  UPPER (a.duration_id) = UPPER (TRIM (l_record (9)));
	  EXCEPTION
		 WHEN NO_DATA_FOUND
		 THEN
		 l_error_message :=
		 l_error_message
		 || '                       **ERROR: The Duration Id is not Recognized:
	  '
		 || l_record (9);
	  END;

	  --
	  ---
	  ---- Is the shef_loc_id of proper length?"...
	  l_len := LENGTH (l_record (1));

	  IF l_len < 3 OR l_len > 8
	  THEN
		 l_error_message :=
		 l_error_message
		 || '                     **ERROR: The SHEF Location Id is
	  '
		 || l_len
		 || '                    characters long. It must be between 3 and 8 characters in
	  length.
	  ';
	  END IF;

	  BEGIN
		 INSERT INTO gt_shef_decodes1 (
			  line_number,
			  shef_loc_id,
			  shef_pe_code,
			  shef_tse_code,
			  shef_dur_numeric,
			  shef_spec,
			  location_id,
			  parameter_id,
			  base_parameter_code,
			  parameter_type_id,
			  parameter_type_code,
			  interval_id,
			  interval_code,
			  duration_id,
			  duration_code,
			  version,
			  cwms_ts_id,
			  cwms_ts_code,
			  --unit_system,
			  units,
			  unit_code,
			  shef_tz,
			  shef_dl_time,
			  interva_utc_offset,
			  interval_forward,
			  interval_backward,
			  active_flag,
			  unparsed_line
		 )
		 VALUES	(
			l_idx,
			l_record (1),	  -- shef_location_id
			l_record (2),	  -- shef_pe_code
			l_record (3),	  -- shef_tse_code
			l_record (4),	  -- shef_dur_numeric
			UPPER(	l_record (1)
			|| '.'
			|| l_record (2)
			|| '.'
			|| l_record (3)
			|| '.'
			|| l_record (4)),   -- shef_spec
			l_record (5),		-- location_id
			l_record (6),	  -- parameter_id
			l_base_parameter_code,	-- base_parameter_code
			l_record (7),	 -- parameter_type_id
			l_parameter_type_code,	-- parameter_type_code
			l_record (8),		-- interval_id
			l_interval_code,	  -- interval_code
			l_record (9),		-- duration_id
			l_duration_code,	  -- duration_code
			l_record (10), 	-- version
			l_cwms_ts_id,	  -- cwms_ts_id
			l_cwms_ts_code,	  -- cwms_ts_code
			l_record (11), 	 -- unit_system
			l_unit_code,	  -- unit_code
			l_record (12), 	-- unit_id
			l_record (13), 	-- shef_tz
			l_record (14), 	-- shef_dl_time T/F
			l_record (15),  -- interval_utc_offset
			l_record (16), 	-- interval_forward
			l_record (17),   -- interval_backward
	-- 	  l_record (18),	  -- active_flag
			l_records (l_idx) 	-- unparsed line
		 );
	  EXCEPTION
		 WHEN OTHERS
		 THEN
		 aa1('                      >>parse_crit_file<< failed to store:
	  '
		  || l_records (l_idx));
		 aa1('                        >>parse_crit_file<<
	  '
		  || SQLERRM);
		 l_error_message := SQLERRM;

		 INSERT INTO gt_shef_decodes1 (
			  line_number,
			  unparsed_line,
			  error_msg
			)
		 VALUES	(l_idx, l_records (l_idx),   -- unparsed line
				l_error_message
			);
	  -- INSERT INTO gt_parse_errors (
	  --		 line_number,
	  --		 error_msg,
	  --		 unparsed_line
	  --	 )
	  -- VALUES (l_idx, l_error_message, l_records (l_idx)
	  --	 );
	  END;
	  END IF;
	  END LOOP;

	  SELECT COUNT ( * )
	  INTO  l_idx
	  FROM  gt_shef_decodes1;

	  aa1(	'                >>parse_crit_file<< gt_shef_decodes1 has: '
		|| l_idx
		|| ' rows.
	  ');

	  IF NOT l_is_csv
	  THEN
	  BEGIN
	  OPEN l_rc FOR
		 SELECT	cwms_id
		 FROM  ( SELECT  UPPER (c002) cwms_id,
			COUNT (UPPER (c002)) count_id
			FROM	apex_collections
		  WHERE	collection_name = UPPER (p_collection_name)
		  GROUP BY UPPER (c002))
		WHERE  count_id > 1;
	  EXCEPTION
	  WHEN OTHERS
	  THEN
		 l_tmp := 3;
	  END;

	  IF l_tmp != 3
	  THEN
	  LOOP
		 FETCH l_rc INTO		 l_cwms_id_dup;

		 EXIT WHEN l_rc%NOTFOUND;

		 OPEN l_rc_rows FOR
		 SELECT	c001
		 FROM  apex_collections
		WHERE  collection_name = UPPER (p_collection_name)
		 AND UPPER (c002) = l_cwms_id_dup;

		 l_rows_msg := NULL;
		 l_tmp := 0;

		 LOOP
		 FETCH l_rc_rows INTO	  l_row_num;

		 EXIT WHEN l_rc_rows%NOTFOUND;

		 IF l_tmp = 1
		 THEN
		 l_rows_msg :=
		 l_rows_msg
		 || '                                                                        ,
	  ';
		 END IF;

		 l_rows_msg := l_rows_msg || TO_CHAR (l_row_num);
		 l_tmp := 1;
		 END LOOP;

		 l_seq_id :=
		 apex_collection.add_member (
		 p_error_collection_name,
		 '                                  dummy
	  '
		 );
		 apex_collection.update_member_attribute (
		 p_collection_name  => p_error_collection_name,
		 p_seq	 => l_seq_id,
		 p_attr_number   => 1,
		 p_attr_value	=> l_rows_msg
		 );
		 apex_collection.update_member_attribute (
		 p_collection_name  => p_error_collection_name,
		 p_seq	 => l_seq_id,
		 p_attr_number   => 2,
		 p_attr_value	=> '                                                    ERROR: cwms ts id is
	  defined on multiple lines.
	  '
		 );
		 apex_collection.update_member_attribute (
		 p_collection_name  => p_error_collection_name,
		 p_seq	 => l_seq_id,
		 p_attr_number   => 3,
		 p_attr_value	=> l_cwms_id_dup
		 );
	  END LOOP;

	  --
	  --
	  CLOSE l_rc;

	  CLOSE l_rc_rows;

	  OPEN l_rc FOR
		 SELECT	shef_id
		 FROM  ( SELECT  UPPER(c003
			  || '                                    .
	  '
			  || c004
			  || '                                    .
	  '
			  || c005
			  || '                                    .
	  '
			  || c006)
			shef_id,
			COUNT(UPPER(c003
			  || '                                        .
	  '
			  || c004
			  || '                                        .
	  '
			  || c005
			  || '                                        .
	  '
			  || c006))
			count_id
			FROM	apex_collections
		  WHERE	collection_name = UPPER (p_collection_name)
		  GROUP BY UPPER(c003
			  || '                                    .
	  '
			  || c004
			  || '                                    .
	  '
			  || c005
			  || '                                    .
	  '
			  || c006))
		WHERE  count_id > 1;

	  LOOP
		 FETCH l_rc INTO		 l_shef_id_dup;

		 EXIT WHEN l_rc%NOTFOUND;

		 OPEN l_rc_rows FOR
		 SELECT	c001
		 FROM  apex_collections
		WHERE  collection_name = UPPER (p_collection_name)
		 AND UPPER( c003
			 || '                                  .'
			 || c004
			 || '                                  .'
			 || c005
			 || '                                  .
	  '
			 || c006) = l_shef_id_dup;

		 l_rows_msg := NULL;
		 l_tmp := 0;

		 LOOP
		 FETCH l_rc_rows INTO	  l_row_num;

		 EXIT WHEN l_rc_rows%NOTFOUND;

		 IF l_tmp = 1
		 THEN
		 l_rows_msg :=
		 l_rows_msg
		 || '                                                                        ,
	  ';
		 END IF;

		 l_rows_msg := l_rows_msg || l_row_num;
		 l_tmp := 1;
		 END LOOP;

		 l_seq_id :=
		 apex_collection.add_member (
		 p_error_collection_name,
		 '                                  dummy
	  '
		 );
		 apex_collection.update_member_attribute (
		 p_collection_name  => p_error_collection_name,
		 p_seq	 => l_seq_id,
		 p_attr_number   => 1,
		 p_attr_value	=> l_rows_msg
		 );
		 apex_collection.update_member_attribute (
		 p_collection_name  => p_error_collection_name,
		 p_seq	 => l_seq_id,
		 p_attr_number   => 2,
		 p_attr_value	=> '                                                    ERROR: SHEF id is defined
	  on multiple lines.
	  '
		 );
		 apex_collection.update_member_attribute (
		 p_collection_name  => p_error_collection_name,
		 p_seq	 => l_seq_id,
		 p_attr_number   => 3,
		 p_attr_value	=> l_shef_id_dup
		 );
	  END LOOP;
	  END IF;
	  END IF;

	  --	IF l_is_crit_file
	  --	THEN
	  --	cwms_shef.delete_data_stream (l_datastream, '                                                                                                       T
	  -- ', 'CWMS  ');
	  --	END IF;

	  --	DELETE FROM wwv_flow_files
	  --	WHERE NAME = p_file_name;
	  SELECT COUNT ( * )
	  INTO  l_seq_id
	  FROM  apex_collections
	 WHERE  collection_name = p_collection_name;

	  cwms_properties.set_property (
	  '        PROCESS_STATUS',
	  p_process_id,
	  '        Completed ' || p_number_of_records || ' records
	  ',
	  l_cmt || LOCALTIMESTAMP,
	  p_db_office_id
	  );

	  aa1(	'                  parse collection name: '
		|| p_collection_name
		|| '                 Row count:
	  '
		|| l_seq_id);
	  END;

	  PROCEDURE error_check_crit_data (
	  p_db_store_rule  IN VARCHAR2,
	  p_data_stream_id	IN VARCHAR2,
	  p_db_office_id IN VARCHAR2 DEFAULT NULL
	  )
	  AS
	  BEGIN
	  IF (p_db_store_rule =
		'                                                  ADD
	  ')
	  THEN
	  INSERT INTO gt_shef_decodes1 (shef_loc_id, shef_pe_code, shef_tse_code, shef_dur_numeric, shef_spec, location_id, parameter_id, base_parameter_code, parameter_type_id, parameter_type_code, interval_id, interval_code, duration_id, duration_code, version, cwms_ts_id, cwms_ts_code, unit_system, units, unit_code, shef_tz, shef_dl_time, interva_utc_offset, interval_forward, interval_backward, active_flag, unparsed_line
			 )
	  SELECT shef_loc_id, shef_pe_code, shef_tse_code,
		 shef_duration_numeric, shef_spec, location_id,
		 parameter_id, 11, parameter_type_id, 11, interval_id, 11,
		 duration_id, 11, version_id, cwms_ts_id, ts_code,
		 unit_system, unit_id, 11, shef_time_zone_id, dl_time,
		 interval_utc_offset, interval_forward, interval_backward,
		 active_flag,
		 '                                          This SHEF Spec is currently defined
	  in DB
	  '
	  FROM  av_shef_decode_spec
		WHERE data_stream_id = p_data_stream_id
		 AND db_office_id = p_db_office_id;
	  END IF;
	  END;
	*/
	PROCEDURE download_file (p_file_id IN uploaded_xls_files_t.id%TYPE)
	IS
		v_mime		  uploaded_xls_files_t.mime_type%TYPE;
		v_length 	  NUMBER;
		v_file_name   uploaded_xls_files_t.file_name%TYPE;
		lob_loc		  uploaded_xls_files_t.blob_content%TYPE;
	BEGIN
		UPDATE	uploaded_xls_files_t
			SET	num_downloaded = num_downloaded + 1
		 WHERE	id = p_file_id;

		SELECT	mime_type, blob_content, file_name,
					DBMS_LOB.getlength (blob_content)
		  INTO	v_mime, lob_loc, v_file_name, v_length
		  FROM	uploaded_xls_files_t
		 WHERE	id = p_file_id;

		--
		-- set up HTTP header
		--
		-- use an NVL around the mime type and
		-- if it is a null set it to application/octect
		-- application/octect may launch a download window from windows
		OWA_UTIL.mime_header (NVL (v_mime, 'application/octet'), FALSE);

		-- set the size so the browser knows how much to download
		HTP.p ('Content-length: ' || v_length);
		-- the filename will be used by the browser if the users does a save as
		HTP.p (
			'Content-Disposition: attachment; filename="' || v_file_name || '"'
		);
		-- close the headers
		OWA_UTIL.http_header_close;
		-- download the BLOB
		WPG_DOCLOAD.download_file (lob_loc);
	END download_file;


	PROCEDURE load_ll (
		p_collection_name   IN VARCHAR2,
		p_fail_if_exists	  IN c_app_logic_no%TYPE DEFAULT c_app_logic_no
	)
	IS
		tmpvar				  NUMBER;
		temp_num 			  NUMBER DEFAULT 0;
		p_seasonal_string   VARCHAR2 (4000);
	BEGIN
		tmpvar := 0;

		--If the constant level (column 2 IS NOT NULL then it is a non-seasonal record
		--  INSERT
		-- ELSE
		--  it is a seasonal record, build the seasonal string



		FOR x
			IN (SELECT		c001, c002, c003, c004, c008
					  FROM	apex_collections
					 WHERE		 collection_name = p_collection_name
								AND c002 IS NOT NULL
								AND c001 > 1								 -- column headers
								AND c007 IS NULL
				 ORDER BY	c001 ASC)
		LOOP
			cwms_level.store_location_level2 (
				p_location_level_id	 => x.c002							-- in varchar2,
														 ,
				p_level_value			 => x.c003						  --	 in  number,
														 ,
				p_level_units			 => x.c004						  --	in varchar2,
														 ,
				p_office_id 			 => x.c008,
				p_fail_if_exists		 => p_fail_if_exists
			);

			apex_collection.delete_member (
				p_collection_name   => p_collection_name,
				p_seq 				  => TO_CHAR (x.c001)
			);
		END LOOP;


		/* Mike P's Example
		SWT,Elev.Inst.0.Base Flood Control,,ft,00-00,000 00:00:00,723
		SWT,Elev.Inst.0.Base Flood Control,,ft,00-06,000 00:00:00,723
		SWT,Elev.Inst.0.Base Flood Control,,ft,00-06,014 00:00:00,723
		SWT,Elev.Inst.0.Base Flood Control,,ft,00-07,000 00:00:00,723
		SWT,Elev.Inst.0.Base Flood Control,,ft,00-08,000 00:00:00,723
		SWT,Elev.Inst.0.Base Flood Control,,ft,00-11,030 00:00:00,723

		procedure store_location_level2(
		 p_location_level_id => 'Elev.Inst.0.Base Flood Control',
		 p_level_value  => null,
		 p_level_units  => 'ft',
		 p_seasonal_values => '0,0,723/6,0,723/6,14,723/7,0,723/8,0,723/11,30,723',
		 p_office_id	=> 'SWT')

		*/



		FOR x IN (SELECT	 b.*,
								 REPLACE (REPLACE (b.seasonal_value_raw, ',', '/'), '-', ',') seasonal_value
						FROM	 (SELECT 	 c002, c004, c008,
												 stragg (c005 || '-' || c006 || '-' || c007) seasonal_value_raw
										FROM	 (SELECT   c002, c004, c006, c007, c008,
															  c005			 -- + c005_yr c005
													 FROM   (SELECT	c002 -- STRAGG(strip_for_stragg(c007)) seasonal_value
																				 , c004,
																			calc_seasonal_mn_offset (c005) c005 -- cal offset
																														  ,
																			TO_NUMBER (TRIM (SUBSTR (c006, 1, INSTR (c006, ' ')))) * 24 * 60 c006 -- time offset
																																										,
																			c007, c008
																  FROM	apex_collections
																 WHERE	collection_name =
																				p_collection_name
																			AND c003 IS NULL
																			AND c007 IS NOT NULL
																			AND c001 > 1 --column headers
																							))
								  GROUP BY	 c002, c004, c008) b)
		LOOP
			INSERT
			  INTO	temp_collection_api_fire_tbl (collection,
																user_id_fired,
																plsql_fired,
																seasonal_value
															  )
			VALUES	(
							p_collection_name,
							'JEREMY1',
							NULL,
								'Seasonal Value = "'
							|| x.seasonal_value
							|| '"'
							|| '<BR>'
							|| ' Raw Value = "'
							|| x.seasonal_value_raw
							|| '"'
						);



			--Clean up the string
			p_seasonal_string := x.seasonal_value;
			p_seasonal_string :=
				REPLACE (p_seasonal_string, '/', cwms_util.record_separator);
			p_seasonal_string :=
				REPLACE (p_seasonal_string, ',', cwms_util.field_separator);


			cwms_level.store_location_level2 (
				p_location_level_id	 => x.c002							-- in varchar2,
														 ,
				p_level_value			 => NULL 						  --	 in  number,
													  ,
				p_level_units			 => x.c004 --v_data_array(4) --	 in varchar2,
														 ,
				p_interval_months 	 => 12,
				p_fail_if_exists		 => p_fail_if_exists 		--p_fail_if_exists
																	  ,
				p_seasonal_values 	 => p_seasonal_string --temp_seasonal_values --p_seasonal_string
																		,
				p_office_id 			 => x.c008
			);



			apex_collection.delete_members (
				p_collection_name   => p_collection_name,
				p_attr_number		  => 2												--c002
												,
				p_attr_value		  => x.c002
			);
		--  INSERT INTO TEMP_COLLECTION_API_FIRE_TBL
		-- 	(collection, user_id_fired, plsql_fired, seasonal_value)
		-- 	VALUES
		-- 	(p_collection_name, 'JEREMY after fire', NULL, p_seasonal_String);



		END LOOP;


		SELECT	COUNT (c001)
		  INTO	temp_num
		  FROM	apex_collections
		 WHERE	collection_name = p_collection_name;

		IF temp_num = 1
		THEN
			apex_collection.truncate_collection (p_collection_name);
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			-- Consider logging the error and then re-raise
			RAISE;
	END load_ll;


	PROCEDURE load_lli (
		p_file_name 		  IN apex_application_files.filename%TYPE,
		p_user_id			  IN uploaded_xls_files_t.user_id_uploaded%TYPE,
		p_old_file_id		  IN uploaded_xls_files_t.id%TYPE DEFAULT NULL,
		p_reload_xls_file   IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no,
		p_debug_yn			  IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
	)
	IS
		t_error_debug						  VARCHAR2 (4000);
		p_file_id							  uploaded_xls_files_t.id%TYPE DEFAULT NULL;

		temp_loc_lvl_ind_id				  NUMBER;
		temp_err_msg						  VARCHAR2 (1999);
		temp_err_html						  VARCHAR2 (1999);

		v_blob_data 						  BLOB;
		v_blob_len							  NUMBER;
		v_position							  NUMBER;
		v_raw_chunk 						  RAW (10000);
		v_char								  CHAR (1);
		c_chunk_len 						  NUMBER := 1;
		v_line								  VARCHAR2 (32767) := NULL;
		v_data_array						  wwv_flow_global.vc_arr2;
		v_rows								  NUMBER;
		v_sr_no								  NUMBER := 1;
		temp_error							  VARCHAR2 (1999);
		temp_num_rows						  NUMBER DEFAULT 0;

		--Contions Variables per Mike P's example
		l_conditions						  loc_lvl_ind_cond_tab_t
													  := loc_lvl_ind_cond_tab_t ();
		l_indicator 						  loc_lvl_indicator_t;
		l_office_id 						  VARCHAR2 (16) := 'CPC';
		l_unit_code 						  NUMBER (10);
		l_location_id						  VARCHAR2 (49);
		l_parameter_id 					  VARCHAR2 (49);
		l_parameter_type_id				  VARCHAR2 (16);
		l_duration_id						  VARCHAR2 (16);
		l_specified_level_id 			  VARCHAR2 (256);
		l_location_level_id				  VARCHAR2 (390);

		-- l_na	 VARCHAR2(3) DEFAULT 'n/a';
		l_na									  VARCHAR2 (3) DEFAULT NULL;

		-- insert variables (unsure)
		t_attr_id							  VARCHAR2 (1999);
		t_attr_unit 						  VARCHAR2 (1999);
		--Clear variables
		t_level_indicator_code			  at_loc_lvl_indicator.level_indicator_code%TYPE;
		t_location_code					  VARCHAR2 (1999);
		t_parameter_code					  at_loc_lvl_indicator.parameter_code%TYPE;
		t_parameter_type_code			  at_loc_lvl_indicator.parameter_type_code%TYPE;
		t_duration_code					  at_loc_lvl_indicator.duration_code%TYPE;
		t_specified_level_code			  NUMBER;
		t_level_indicator_id 			  VARCHAR2 (1999);
		t_attr_value						  at_loc_lvl_indicator.attr_value%TYPE
													  DEFAULT NULL;
		t_attr_parameter_code			  at_loc_lvl_indicator.attr_parameter_code%TYPE
													  DEFAULT NULL;
		t_attr_parameter_type_code 	  at_loc_lvl_indicator.attr_parameter_type_code%TYPE
			DEFAULT NULL;
		t_attr_duration_code 			  at_loc_lvl_indicator.attr_duration_code%TYPE
			DEFAULT NULL;
		t_ref_level 						  VARCHAR2 (1999); --at_loc_lvl_indicator.ref_specified_level_code%TYPE DEFAULT NULL;
		t_ref_attr_value					  VARCHAR2 (1999); --at_loc_lvl_indicator.ref_attr_value%TYPE DEFAULT NULL;
		t_minimum_duration				  at_loc_lvl_indicator.minimum_duration%TYPE
													  DEFAULT NULL;
		t_maximum_age						  at_loc_lvl_indicator.maximum_age%TYPE
													  DEFAULT NULL;
		t_md_p1								  VARCHAR2 (100);
		t_md_p2								  VARCHAR2 (100);
		t_md_p3								  VARCHAR2 (100);
		t_ma_p1								  VARCHAR2 (100);
		t_ma_p2								  VARCHAR2 (100);
		t_ma_p3								  VARCHAR2 (100);

		--Conditions variables


		t1_expression						  at_loc_lvl_indicator_cond.expression%TYPE;
		t1_comparison_operator_1		  at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
		t1_comparison_value_1			  at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
		t1_comparison_unit				  at_loc_lvl_indicator_cond.comparison_unit%TYPE;
		t1_connector						  at_loc_lvl_indicator_cond.connector%TYPE;
		t1_comparison_operator_2		  at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
		t1_comparison_value_2			  at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
		t1_rate_expression				  at_loc_lvl_indicator_cond.rate_expression%TYPE;
		t1_rate_comparison_operator_1   at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
		t1_rate_comparison_value_1 	  at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
		t1_rate_comparison_unit 		  at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
		t1_rate_connector 				  at_loc_lvl_indicator_cond.rate_connector%TYPE;
		t1_rate_comparison_operator_2   at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
		t1_rate_comparison_value_2 	  at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
		t1_rate_interval					  at_loc_lvl_indicator_cond.rate_interval%TYPE;
		t1_description 					  at_loc_lvl_indicator_cond.description%TYPE;

		t2_expression						  at_loc_lvl_indicator_cond.expression%TYPE;
		t2_comparison_operator_1		  at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
		t2_comparison_value_1			  at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
		t2_comparison_unit				  at_loc_lvl_indicator_cond.comparison_unit%TYPE;
		t2_connector						  at_loc_lvl_indicator_cond.connector%TYPE;
		t2_comparison_operator_2		  at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
		t2_comparison_value_2			  at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
		t2_rate_expression				  at_loc_lvl_indicator_cond.rate_expression%TYPE;
		t2_rate_comparison_operator_1   at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
		t2_rate_comparison_value_1 	  at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
		t2_rate_comparison_unit 		  at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
		t2_rate_connector 				  at_loc_lvl_indicator_cond.rate_connector%TYPE;
		t2_rate_comparison_operator_2   at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
		t2_rate_comparison_value_2 	  at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
		t2_rate_interval					  at_loc_lvl_indicator_cond.rate_interval%TYPE;
		t2_description 					  at_loc_lvl_indicator_cond.description%TYPE;

		t3_expression						  at_loc_lvl_indicator_cond.expression%TYPE;
		t3_comparison_operator_1		  at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
		t3_comparison_value_1			  at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
		t3_comparison_unit				  at_loc_lvl_indicator_cond.comparison_unit%TYPE;
		t3_connector						  at_loc_lvl_indicator_cond.connector%TYPE;
		t3_comparison_operator_2		  at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
		t3_comparison_value_2			  at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
		t3_rate_expression				  at_loc_lvl_indicator_cond.rate_expression%TYPE;
		t3_rate_comparison_operator_1   at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
		t3_rate_comparison_value_1 	  at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
		t3_rate_comparison_unit 		  at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
		t3_rate_connector 				  at_loc_lvl_indicator_cond.rate_connector%TYPE;
		t3_rate_comparison_operator_2   at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
		t3_rate_comparison_value_2 	  at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
		t3_rate_interval					  at_loc_lvl_indicator_cond.rate_interval%TYPE;
		t3_description 					  at_loc_lvl_indicator_cond.description%TYPE;

		t4_expression						  at_loc_lvl_indicator_cond.expression%TYPE;
		t4_comparison_operator_1		  at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
		t4_comparison_value_1			  at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
		t4_comparison_unit				  at_loc_lvl_indicator_cond.comparison_unit%TYPE;
		t4_connector						  at_loc_lvl_indicator_cond.connector%TYPE;
		t4_comparison_operator_2		  at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
		t4_comparison_value_2			  at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
		t4_rate_expression				  at_loc_lvl_indicator_cond.rate_expression%TYPE;
		t4_rate_comparison_operator_1   at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
		t4_rate_comparison_value_1 	  at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
		t4_rate_comparison_unit 		  at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
		t4_rate_connector 				  at_loc_lvl_indicator_cond.rate_connector%TYPE;
		t4_rate_comparison_operator_2   at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
		t4_rate_comparison_value_2 	  at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
		t4_rate_interval					  at_loc_lvl_indicator_cond.rate_interval%TYPE;
		t4_description 					  at_loc_lvl_indicator_cond.description%TYPE;

		t5_expression						  at_loc_lvl_indicator_cond.expression%TYPE;
		t5_comparison_operator_1		  at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
		t5_comparison_value_1			  at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
		t5_comparison_unit				  at_loc_lvl_indicator_cond.comparison_unit%TYPE;
		t5_connector						  at_loc_lvl_indicator_cond.connector%TYPE;
		t5_comparison_operator_2		  at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
		t5_comparison_value_2			  at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
		t5_rate_expression				  at_loc_lvl_indicator_cond.rate_expression%TYPE;
		t5_rate_comparison_operator_1   at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
		t5_rate_comparison_value_1 	  at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
		t5_rate_comparison_unit 		  at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
		t5_rate_connector 				  at_loc_lvl_indicator_cond.rate_connector%TYPE;
		t5_rate_comparison_operator_2   at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
		t5_rate_comparison_value_2 	  at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
		t5_rate_interval					  at_loc_lvl_indicator_cond.rate_interval%TYPE;
		t5_description 					  at_loc_lvl_indicator_cond.description%TYPE;
	BEGIN
		IF p_old_file_id IS NOT NULL AND p_reload_xls_file = c_app_logic_yes
		THEN
			--Get the BLOB and info from DB
			p_file_id := p_old_file_id;
		ELSE
			-- Process from APEX document repository

			--Insert the XLS spreadsheet into the file repository table
			INSERT INTO   uploaded_xls_files_t (id,
															file_name,
															blob_content,
															mime_type,
															date_uploaded,
															user_id_uploaded
														  )
				SELECT	id, p_file_name								 --:P615_FILE_NAME
												, blob_content, mime_type, SYSDATE,
							p_user_id
				  FROM	apex_application_files
				 WHERE	name = p_file_name;

			--Get the ID for future use
			SELECT	id
			  INTO	p_file_id
			  FROM	apex_application_files
			 WHERE	name = p_file_name;

			--Clean up the APEX File Repository
			DELETE	apex_application_files
			 WHERE	name = p_file_name;
		END IF;											  -- if p_old_file id IS NOT NULL

		-- Read data from uploaded document repository
		SELECT	blob_content
		  INTO	v_blob_data
		  FROM	uploaded_xls_files_t
		 WHERE	id = p_file_id;

		IF p_debug_yn = c_app_logic_yes
		THEN
			set_log_row (
				p_error_text	 =>	'Entering BLOB Loop with file id  "'
										|| p_file_id
										|| '"'
										|| ' and BLOB Length of '
										|| LENGTH (v_blob_data),
				p_file_id		 => p_file_id,
				p_pl_sql_text	 => ' Entering Processing Loop'
			);
		END IF;

		--Begin Loop
		v_blob_len := DBMS_LOB.getlength (v_blob_data);
		v_position := 1;

		-- Read and convert binary to char</span>
		-- Read the BLOB and parse into table to be processed
		WHILE (v_position <= v_blob_len)
		LOOP
			NULL;
			v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
			v_char := CHR (cwms_apex.hex_to_decimal (RAWTOHEX (v_raw_chunk)));
			v_line := v_line || v_char;
			v_position := v_position + c_chunk_len;

			-- When a whole line is retrieved </span>

			IF v_char = CHR (10)
			THEN
				v_line := REPLACE (v_line, ',', ':');



				IF temp_num_rows = 0
				THEN
					-- DO nothing, this is the column title
					NULL;
				ELSE
					-- Clean up the quotes
					--v_line := REPLACE(v_line, '"','');

					FOR y IN (SELECT	 ROWNUM row_num --, strip_for_stragg(column_value) col_val
																,
											 REPLACE (COLUMN_VALUE, '"', '') col_val
									FROM	 TABLE (SELECT   str2tbl (v_line, ':')
														 FROM   DUAL))
					LOOP
						BEGIN
							IF p_debug_yn = c_app_logic_yes
							THEN
								set_log_row (
									p_error_text	 =>	'Processing Row "'
															|| temp_num_rows
															|| '"Column  "'
															|| y.row_num
															|| '"',
									p_file_id		 => p_file_id,
									p_pl_sql_text	 => ' Entering Variable CASE Statement with XLS Column value of "'
															|| y.col_val
															|| '" and a length of "'
															|| LENGTH (y.col_val)
															|| '"'
								);
							END IF;


							CASE y.row_num
								WHEN 1
								THEN
									t_level_indicator_id := y.col_val;
									l_location_level_id := y.col_val;
								WHEN 2
								THEN
									t_attr_id := TO_NUMBER (y.col_val); 	  -- attr_id
								WHEN 3
								THEN
									t_attr_value := TO_NUMBER (y.col_val);
								WHEN 4
								THEN
									t_attr_unit :=
										get_unit_code_from_code_id (y.col_val,
																			 p_file_id
																			); 		-- attr_unit
								WHEN 5
								THEN
									t_ref_level := y.col_val; --t_ref_specified_level_code
								WHEN 6
								THEN
									t_ref_attr_value := y.col_val;
								WHEN 7
								THEN
									t_md_p1 := y.col_val;							  --md p1
								WHEN 8
								THEN
									t_md_p2 := y.col_val;							  --md p2
								WHEN 9
								THEN
									t_md_p3 := y.col_val;							  --md p3
								-- 	  t_minimum_duration  := t_md_p1 || ':' || t_md_p2 || ':' || t_md_p3;
								WHEN 10
								THEN
									t_ma_p1 := y.col_val;							  --ma p1
								WHEN 11
								THEN
									t_ma_p2 := y.col_val;							  --ma p2
								WHEN 12
								THEN
									t_ma_p3 := y.col_val;							  --ma p3
								-- 		t_maximum_age	:= t_ma_p1 || ':' || t_ma_p2 || ':' || t_ma_p3;
								WHEN 13
								THEN
									t1_expression := y.col_val;
								WHEN 14
								THEN
									t1_comparison_unit :=
										get_unit_code_from_code_id (y.col_val,
																			 p_file_id
																			);
								WHEN 15
								THEN
									t1_comparison_operator_1 := y.col_val;
								WHEN 16
								THEN
									t1_comparison_value_1 := y.col_val;
								WHEN 17
								THEN
									t1_connector := y.col_val;
								WHEN 18
								THEN
									t1_comparison_operator_2 := y.col_val;
								WHEN 19
								THEN
									t1_comparison_value_2 := y.col_val;
								WHEN 20
								THEN
									t1_rate_expression := y.col_val;
								WHEN 21
								THEN
									t1_rate_comparison_unit := y.col_val;
								WHEN 22
								THEN
									t1_rate_interval := y.col_val;
								WHEN 23
								THEN
									t1_rate_comparison_operator_1 := y.col_val;
								WHEN 24
								THEN
									t1_rate_comparison_value_1 := y.col_val;
								WHEN 25
								THEN
									t1_rate_connector := y.col_val;
								WHEN 26
								THEN
									t1_rate_comparison_operator_2 := y.col_val;
								WHEN 27
								THEN
									t1_rate_comparison_value_2 := y.col_val;
								WHEN 28
								THEN
									t1_description := y.col_val;
								WHEN 29
								THEN
									t2_expression := y.col_val;
								WHEN 30
								THEN
									t2_comparison_unit :=
										get_unit_code_from_code_id (y.col_val,
																			 p_file_id
																			);
								WHEN 31
								THEN
									t2_comparison_operator_1 := y.col_val;
								WHEN 32
								THEN
									t2_comparison_value_1 := y.col_val;
								WHEN 33
								THEN
									t2_connector := y.col_val;
								WHEN 34
								THEN
									t2_comparison_operator_2 := y.col_val;
								WHEN 35
								THEN
									t2_comparison_value_2 := y.col_val;
								WHEN 36
								THEN
									t2_rate_expression := y.col_val;
								WHEN 37
								THEN
									t2_rate_comparison_unit := y.col_val;
								WHEN 38
								THEN
									t2_rate_interval := y.col_val;
								WHEN 39
								THEN
									t2_rate_comparison_operator_1 := y.col_val;
								WHEN 40
								THEN
									t2_rate_comparison_value_1 := y.col_val;
								WHEN 41
								THEN
									t2_rate_connector := y.col_val;
								WHEN 42
								THEN
									t2_rate_comparison_operator_2 := y.col_val;
								WHEN 43
								THEN
									t2_rate_comparison_value_2 := y.col_val;
								WHEN 44
								THEN
									t2_description := y.col_val;
								WHEN 45
								THEN
									t3_expression := y.col_val;
								WHEN 46
								THEN
									t3_comparison_unit :=
										get_unit_code_from_code_id (y.col_val,
																			 p_file_id
																			);
								WHEN 47
								THEN
									t3_comparison_operator_1 := y.col_val;
								WHEN 48
								THEN
									t3_comparison_value_1 := y.col_val;
								WHEN 49
								THEN
									t3_connector := y.col_val;
								WHEN 50
								THEN
									t3_comparison_operator_2 := y.col_val;
								WHEN 51
								THEN
									t3_comparison_value_2 := y.col_val;
								WHEN 52
								THEN
									t3_rate_expression := y.col_val;
								WHEN 53
								THEN
									t3_rate_comparison_unit := y.col_val;
								WHEN 54
								THEN
									t3_rate_interval := y.col_val;
								WHEN 55
								THEN
									t3_rate_comparison_operator_1 := y.col_val;
								WHEN 56
								THEN
									t3_rate_comparison_value_1 := y.col_val;
								WHEN 57
								THEN
									t3_rate_connector := y.col_val;
								WHEN 58
								THEN
									t3_rate_comparison_operator_2 := y.col_val;
								WHEN 59
								THEN
									t3_rate_comparison_value_2 := y.col_val;
								WHEN 60
								THEN
									t3_description := y.col_val;
								WHEN 61
								THEN
									t4_expression := y.col_val;
								WHEN 62
								THEN
									t4_comparison_unit :=
										get_unit_code_from_code_id (y.col_val,
																			 p_file_id
																			);
								--Set_Log_Row (p_error_text  =>'setting t4_comparison unit to "' || t4_comparison_unit || '"'
								-- 	|| ' from '  || y.col_val
								-- 	,p_file_id => p_file_id
								-- 	,p_pl_sql_text => ' WHEN 14 THEN t4_comparison_unit       := Get_unit_code_from_code_id(y.col_val);'
								-- 	);

								WHEN 63
								THEN
									t4_comparison_operator_1 := y.col_val;
								WHEN 64
								THEN
									t4_comparison_value_1 := y.col_val;
								WHEN 65
								THEN
									t4_connector := y.col_val;
								WHEN 66
								THEN
									t4_comparison_operator_2 := y.col_val;
								WHEN 67
								THEN
									t4_comparison_value_2 := y.col_val;
								WHEN 68
								THEN
									t4_rate_expression := y.col_val;
								WHEN 69
								THEN
									t4_rate_comparison_unit := y.col_val;
								WHEN 70
								THEN
									t4_rate_interval := y.col_val;
								WHEN 71
								THEN
									t4_rate_comparison_operator_1 := y.col_val;
								WHEN 72
								THEN
									t4_rate_comparison_value_1 := y.col_val;
								WHEN 73
								THEN
									t4_rate_connector := y.col_val;
								WHEN 74
								THEN
									t4_rate_comparison_operator_2 := y.col_val;
								WHEN 75
								THEN
									t4_rate_comparison_value_2 := y.col_val;
								WHEN 76
								THEN
									t4_description := y.col_val;
								WHEN 77
								THEN
									t5_expression := y.col_val;
								WHEN 78
								THEN
									t5_comparison_unit :=
										get_unit_code_from_code_id (y.col_val,
																			 p_file_id
																			);
								WHEN 79
								THEN
									t5_comparison_operator_1 := y.col_val;
								WHEN 80
								THEN
									t5_comparison_value_1 := y.col_val;
								WHEN 81
								THEN
									t5_connector := y.col_val;
								WHEN 82
								THEN
									t5_comparison_operator_2 := y.col_val;
								WHEN 83
								THEN
									t5_comparison_value_2 := y.col_val;
								WHEN 84
								THEN
									t5_rate_expression := y.col_val;
								WHEN 85
								THEN
									t5_rate_comparison_unit := y.col_val;
								WHEN 86
								THEN
									t5_rate_interval := y.col_val;
								WHEN 87
								THEN
									t5_rate_comparison_operator_1 := y.col_val;
								WHEN 88
								THEN
									t5_rate_comparison_value_1 := y.col_val;
								WHEN 89
								THEN
									t5_rate_connector := y.col_val;
								WHEN 90
								THEN
									t5_rate_comparison_operator_2 := y.col_val;
								WHEN 91
								THEN
									t5_rate_comparison_value_2 := y.col_val;
								WHEN 92
								THEN
									t5_description := y.col_val;
								WHEN 93
								THEN
									t_location_code := y.col_val;
								ELSE
									NULL;
							END CASE;
						EXCEPTION
							WHEN OTHERS
							THEN
								NULL;
								temp_err_msg := SQLERRM;
								t_error_debug := NULL;

								CASE y.row_num
									WHEN 1
									THEN
										t_error_debug :=
											'1. t_level_indicator_id set to: '
											|| y.col_val;
									WHEN 2
									THEN
										t_error_debug :=
											'2. t_attr_id set to: ' || y.col_val;
									WHEN 14
									THEN
										t_error_debug :=
											'14. t1_comparison_unit  set to: '
											|| y.col_val;
									ELSE
										NULL;
								END CASE;


								INSERT
								  INTO	uploaded_xls_file_rows_t (
												id,
												file_id,
												date_uploaded,
												user_id_uploaded,
												date_last_updated,
												user_id_last_updated,
												error_code_original,
												pl_sql_call,
												single_row_yn,
												seasonal_component
											)
								VALUES	(
												uploaded_xls_file_rows_seq.NEXTVAL,
												p_file_id,
												SYSDATE,
												p_user_id,
												SYSDATE,
												p_user_id,
												y.row_num
												|| '. adding record bad conversion in array column '
												|| y.row_num
												|| ' XLS colum '
												|| TO_NUMBER ( (y.row_num - 4))
												|| ' with value of: '
												|| y.col_val
												|| ' Length of the field is: '
												|| CASE
														WHEN y.col_val IS NULL THEN 'EMPTY'
														ELSE TO_CHAR (LENGTH (y.col_val))
													END
												|| ' Field Value is "'
												|| y.col_val
												|| '"'
												|| ' Error = '
												|| temp_err_msg
												|| ' Error Debug = '
												|| t_error_debug --14 = ' || t1_comparison_unit || ' vs. ' || y.col_val
																	 ,
												v_line,
												c_app_logic_yes,
												NULL
											);
						END;
					END LOOP;

					BEGIN
						NULL;

						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Processing Row  "'
														|| temp_num_rows
														|| '"',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 => ' Entering Conditions Variable 1 Processing'
							);
						END IF;

						l_conditions.delete;
						l_conditions.EXTEND (5);
						l_conditions (1) :=
							loc_lvl_indicator_cond_t (
								p_indicator_value 				 => 1,
								p_expression						 => t1_expression,
								p_comparison_operator_1 		 => t1_comparison_operator_1,
								p_comparison_value_1 			 => t1_comparison_value_1,
								p_comparison_unit 				 => t1_comparison_unit,
								p_connector 						 => t1_connector,
								p_comparison_operator_2 		 => t1_comparison_operator_2,
								p_comparison_value_2 			 => t1_comparison_value_2,
								p_rate_expression 				 => t1_rate_expression,
								p_rate_comparison_operator_1	 => t1_rate_comparison_operator_1,
								p_rate_comparison_value_1		 => t1_rate_comparison_value_1,
								p_rate_comparison_unit			 => t1_rate_comparison_unit,
								p_rate_connector					 => t1_rate_connector,
								p_rate_comparison_operator_2	 => t1_rate_comparison_operator_2,
								p_rate_comparison_value_2		 => t1_rate_comparison_value_2,
								p_rate_interval					 => t1_rate_interval,
								p_description						 => t1_description
							);


						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Processing Row  "'
														|| temp_num_rows
														|| '"',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 => ' Entering Conditions Variable 2 Processing'
							);
						END IF;

						l_conditions (2) :=
							loc_lvl_indicator_cond_t (
								p_indicator_value 				 => 2,
								p_expression						 => t2_expression,
								p_comparison_operator_1 		 => t2_comparison_operator_1,
								p_comparison_value_1 			 => t2_comparison_value_1,
								p_comparison_unit 				 => t2_comparison_unit,
								p_connector 						 => t2_connector,
								p_comparison_operator_2 		 => t2_comparison_operator_2,
								p_comparison_value_2 			 => t2_comparison_value_2,
								p_rate_expression 				 => t2_rate_expression,
								p_rate_comparison_operator_1	 => t2_rate_comparison_operator_1,
								p_rate_comparison_value_1		 => t2_rate_comparison_value_1,
								p_rate_comparison_unit			 => t2_rate_comparison_unit,
								p_rate_connector					 => t2_rate_connector,
								p_rate_comparison_operator_2	 => t2_rate_comparison_operator_2,
								p_rate_comparison_value_2		 => t2_rate_comparison_value_2,
								p_rate_interval					 => t2_rate_interval,
								p_description						 => t2_description
							);

						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Processing Row  "'
														|| temp_num_rows
														|| '"',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 => ' Entering Conditions Variable 3 Processing'
							);
						END IF;

						l_conditions (3) :=
							loc_lvl_indicator_cond_t (
								p_indicator_value 				 => 3,
								p_expression						 => t3_expression,
								p_comparison_operator_1 		 => t3_comparison_operator_1,
								p_comparison_value_1 			 => t3_comparison_value_1,
								p_comparison_unit 				 => t3_comparison_unit,
								p_connector 						 => t3_connector,
								p_comparison_operator_2 		 => t3_comparison_operator_2,
								p_comparison_value_2 			 => t3_comparison_value_2,
								p_rate_expression 				 => t3_rate_expression,
								p_rate_comparison_operator_1	 => t3_rate_comparison_operator_1,
								p_rate_comparison_value_1		 => t3_rate_comparison_value_1,
								p_rate_comparison_unit			 => t3_rate_comparison_unit,
								p_rate_connector					 => t3_rate_connector,
								p_rate_comparison_operator_2	 => t3_rate_comparison_operator_2,
								p_rate_comparison_value_2		 => t3_rate_comparison_value_2,
								p_rate_interval					 => t3_rate_interval,
								p_description						 => t3_description
							);

						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Processing Row  "'
														|| temp_num_rows
														|| '"',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 => ' Entering Conditions Variable 4 Processing'
							);
						END IF;

						l_conditions (4) :=
							loc_lvl_indicator_cond_t (
								p_indicator_value 				 => 4,
								p_expression						 => t4_expression,
								p_comparison_operator_1 		 => t4_comparison_operator_1,
								p_comparison_value_1 			 => t4_comparison_value_1,
								p_comparison_unit 				 => t4_comparison_unit,
								p_connector 						 => t4_connector,
								p_comparison_operator_2 		 => t4_comparison_operator_2,
								p_comparison_value_2 			 => t4_comparison_value_2,
								p_rate_expression 				 => t4_rate_expression,
								p_rate_comparison_operator_1	 => t4_rate_comparison_operator_1,
								p_rate_comparison_value_1		 => t4_rate_comparison_value_1,
								p_rate_comparison_unit			 => t4_rate_comparison_unit,
								p_rate_connector					 => t4_rate_connector,
								p_rate_comparison_operator_2	 => t4_rate_comparison_operator_2,
								p_rate_comparison_value_2		 => t4_rate_comparison_value_2,
								p_rate_interval					 => t4_rate_interval,
								p_description						 => t4_description
							);

						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Processing Row  "'
														|| temp_num_rows
														|| '"',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 => ' Entering Conditions Variable 5 Processing'
							);
						END IF;


						l_conditions (5) :=
							loc_lvl_indicator_cond_t (
								p_indicator_value 				 => 5,
								p_expression						 => t5_expression,
								p_comparison_operator_1 		 => t5_comparison_operator_1,
								p_comparison_value_1 			 => t5_comparison_value_1,
								p_comparison_unit 				 => t5_comparison_unit,
								p_connector 						 => t5_connector,
								p_comparison_operator_2 		 => t5_comparison_operator_2,
								p_comparison_value_2 			 => t5_comparison_value_2,
								p_rate_expression 				 => t5_rate_expression,
								p_rate_comparison_operator_1	 => t5_rate_comparison_operator_1,
								p_rate_comparison_value_1		 => t5_rate_comparison_value_1,
								p_rate_comparison_unit			 => t5_rate_comparison_unit,
								p_rate_connector					 => t5_rate_connector,
								p_rate_comparison_operator_2	 => t5_rate_comparison_operator_2,
								p_rate_comparison_value_2		 => t5_rate_comparison_value_2,
								p_rate_interval					 => t5_rate_interval,
								p_description						 => t5_description
							);

						--Interval Calculations
						t_minimum_duration :=
							TO_DSINTERVAL (
								t_md_p1 || ':' || t_md_p2 || ':' || t_md_p3
							);
						t_maximum_age :=
							TO_DSINTERVAL (
								t_ma_p1 || ':' || t_ma_p2 || ':' || t_ma_p3
							);

						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Finished Processing Row  "'
														|| temp_num_rows
														|| '" Intervals',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 =>	' t_minimum_duration = "'
														|| t_minimum_duration
														|| '"'
														|| '<BR> P1 = "'
														|| t_md_p1
														|| '" P2 = "'
														|| t_md_p2
														|| '" P3 = "'
														|| t_md_p3
														|| '"'
														|| '<BR>t_maximum_age = "'
														|| t_maximum_age
														|| '"'
														|| '<BR> P1 = "'
														|| t_ma_p1
														|| '" P2 = "'
														|| t_ma_p2
														|| '" P3 = "'
														|| t_ma_p3
														|| '"'
							);
						END IF;


						temp_err_html :=
								' 1 A = '
							|| t_level_indicator_id
							|| '<BR>'
							|| ' 2 B = '
							|| t_attr_id
							|| '<BR>'
							|| ' 3 C = '
							|| t_attr_value
							|| '<BR>'
							|| ' 4 D = '
							|| t_attr_unit
							|| '<BR>'
							|| ' 5 E = '
							|| t_ref_level
							|| '<BR>'
							|| ' 6 F = '
							|| t_ref_attr_value
							|| '<BR>'
							|| ' 7 G = '
							|| t_md_p1
							|| '<BR>'
							|| ' 8 G = '
							|| t_md_p2
							|| '<BR>'
							|| ' 9 G = '
							|| t_md_p3
							|| '<BR>'
							|| '10 H = '
							|| t_ma_p1
							|| '<BR>'
							|| '11 H = '
							|| t_ma_p2
							|| '<BR>'
							|| '12 H = '
							|| t_ma_p3
							|| '<BR>'
							|| '13 I = '
							|| t1_expression
							|| '<BR>'
							|| '14 J = '
							|| t1_comparison_unit
							|| '<BR>'
							|| '15 K = '
							|| t1_comparison_operator_1
							|| '<BR>'
							|| '16 L = '
							|| t1_comparison_value_1
							|| '<BR>'
							|| '17 M = '
							|| t1_connector
							|| '<BR>'
							|| '18 N = '
							|| t1_comparison_operator_2
							|| '<BR>'
							|| '19 O = '
							|| t1_comparison_value_2
							|| '<BR>'
							|| '20 P = '
							|| t1_rate_expression
							|| '<BR>'
							|| '21 Q = '
							|| t1_rate_comparison_unit
							|| '<BR>'
							|| '22 R = '
							|| t1_rate_interval
							|| '<BR>'
							|| '23 S = '
							|| t1_rate_comparison_operator_1
							|| '<BR>'
							|| '24 T = '
							|| t1_rate_comparison_value_1
							|| '<BR>'
							|| '25 U = '
							|| t1_rate_connector
							|| '<BR>'
							|| '26 V = '
							|| t1_rate_comparison_operator_2
							|| '<BR>'
							|| '27 W = '
							|| t1_rate_comparison_value_2
							|| '<BR>'
							|| '28 X = '
							|| t1_description
							|| '<BR>'
							|| '29 Y = '
							|| t2_expression
							|| '<BR>'
							|| '30 Z = '
							|| t2_comparison_unit
							|| '<BR>'
							|| '31 AA = '
							|| t2_comparison_operator_1
							|| '<BR>'
							|| '32 AB = '
							|| t2_comparison_value_1
							|| '<BR>'
							|| '33 AC = '
							|| t2_connector
							|| '<BR>'
							|| '34 AD = '
							|| t2_comparison_operator_2
							|| '<BR>'
							|| '35 AE = '
							|| t2_comparison_value_2
							|| '<BR>'
							|| '36 AF = '
							|| t2_rate_expression
							|| '<BR>'
							|| '37 AG = '
							|| t2_rate_comparison_unit
							|| '<BR>'
							|| '38 AH = '
							|| t2_rate_interval
							|| '<BR>'
							|| '39 AI = '
							|| t2_rate_comparison_operator_1
							|| '<BR>'
							|| '40 AJ = '
							|| t2_rate_comparison_value_1
							|| '<BR>'
							|| '41 AK = '
							|| t2_rate_connector
							|| '<BR>'
							|| '42 AL = '
							|| t2_rate_comparison_operator_2
							|| '<BR>'
							|| '43 AM = '
							|| t2_rate_comparison_value_2
							|| '<BR>'
							|| '44 AN = '
							|| t2_description
							|| '<BR>'
							|| '45 AO = '
							|| t3_expression
							|| '<BR>'
							|| '46 AP = '
							|| t3_comparison_unit
							|| '<BR>'
							|| '47 AQ = '
							|| t3_comparison_operator_1
							|| '<BR>'
							|| '48 AR = '
							|| t3_comparison_value_1
							|| '<BR>'
							|| '49 AS = '
							|| t3_connector
							|| '<BR>'
							|| '50 AT = '
							|| t3_comparison_operator_2
							|| '<BR>'
							|| '51 AU = '
							|| t3_comparison_value_2
							|| '<BR>'
							|| '52 AV = '
							|| t3_rate_expression
							|| '<BR>'
							|| '53 AW = '
							|| t3_rate_comparison_unit
							|| '<BR>'
							|| '54 AX = '
							|| t3_rate_interval
							|| '<BR>'
							|| '55 AY = '
							|| t3_rate_comparison_operator_1
							|| '<BR>'
							|| '56 AZ = '
							|| t3_rate_comparison_value_1
							|| '<BR>'
							|| '57 BA = '
							|| t3_rate_connector
							|| '<BR>'
							|| '58 BB = '
							|| t3_rate_comparison_operator_2
							|| '<BR>'
							|| '59 BC = '
							|| t3_rate_comparison_value_2
							|| '<BR>'
							|| '60 BD = '
							|| t3_description
							|| '<BR>'
							|| '61 BE = '
							|| t4_expression
							|| '<BR>'
							|| '62 BF = '
							|| t4_comparison_unit
							|| '<BR>'
							|| '63 BG = '
							|| t4_comparison_operator_1
							|| '<BR>'
							|| '64 BH = '
							|| t4_comparison_value_1
							|| '<BR>'
							|| '65 BI = '
							|| t4_connector
							|| '<BR>'
							|| '66 BJ = '
							|| t4_comparison_operator_2
							|| '<BR>'
							|| '67 BK = '
							|| t4_comparison_value_2
							|| '<BR>'
							|| '68 BL = '
							|| t4_rate_expression
							|| '<BR>'
							|| '69 BM = '
							|| t4_rate_comparison_unit
							|| '<BR>'
							|| '70 BN = '
							|| t4_rate_interval
							|| '<BR>'
							|| '71 BO = '
							|| t4_rate_comparison_operator_1
							|| '<BR>'
							|| '72 BP = '
							|| t4_rate_comparison_value_1
							|| '<BR>'
							|| '73 BQ = '
							|| t4_rate_connector
							|| '<BR>'
							|| '74 BR = '
							|| t4_rate_comparison_operator_2
							|| '<BR>'
							|| '75 BS = '
							|| t4_rate_comparison_value_2
							|| '<BR>'
							|| '76 BT = '
							|| t4_description
							|| '<BR>'
							|| '77 BU = '
							|| t5_expression
							|| '<BR>'
							|| '78 BV = '
							|| t5_comparison_unit
							|| '<BR>'
							|| '79 BW = '
							|| t5_comparison_operator_1
							|| '<BR>'
							|| '80 BX = '
							|| t5_comparison_value_1
							|| '<BR>'
							|| '81 BY = '
							|| t5_connector
							|| '<BR>'
							|| '82 BZ = '
							|| t5_comparison_operator_2
							|| '<BR>'
							|| '83 CA = '
							|| t5_comparison_value_2
							|| '<BR>'
							|| '84 CB = '
							|| t5_rate_expression
							|| '<BR>'
							|| '85 CC = '
							|| t5_rate_comparison_unit
							|| '<BR>'
							|| '86 CD = '
							|| t5_rate_interval
							|| '<BR>'
							|| '87 CE = '
							|| t5_rate_comparison_operator_1
							|| '<BR>'
							|| '88 CF = '
							|| t5_rate_comparison_value_1
							|| '<BR>'
							|| '89 CG = '
							|| t5_rate_connector
							|| '<BR>'
							|| '90 CH = '
							|| t5_rate_comparison_operator_2
							|| '<BR>'
							|| '91 CI = '
							|| t5_rate_comparison_value_2
							|| '<BR>'
							|| '92 CJ = '
							|| t5_description
							|| '<BR>'
							|| '93 CK = '
							|| t_location_code
							|| '<BR>'
							|| 'Interval 1, Minimum Duration = '
							|| t_minimum_duration
							|| '<BR>'
							|| 'Interval 2, Maximum Age = '
							|| t_maximum_age;

						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 => 'Logging Setting Page API Variables from XLS! --'
														|| temp_err_msg,
								p_file_id		 => p_file_id,
								p_pl_sql_text	 =>	'LINE #'
														|| temp_num_rows
														|| '<BR>'
														|| ' = "'
														|| v_line
														|| '"<BR>'
														|| 'p_office_id = '
														|| t_location_code
														|| '<BR>'
														|| 'p_location_level_id = '
														|| l_location_level_id
														|| '<BR>'
														|| 'Internal Variables and Excel Cell Columns<BR>'
														|| temp_err_html
							);
						END IF;


						IF p_debug_yn = c_app_logic_yes
						THEN
							set_log_row (
								p_error_text	 =>	'Processing Row  "'
														|| temp_num_rows
														|| '"',
								p_file_id		 => p_file_id,
								p_pl_sql_text	 => ' Entering Load_LLI_2'
							);
						END IF;

						load_lli_2 (p_attr_id						=> t_attr_id,
										p_attr_value					=> t_attr_value,
										p_attr_unit 					=> t_attr_unit,
										p_conditions					=> l_conditions,
										p_file_id						=> p_file_id,
										p_indicator 					=> l_indicator,
										p_location_level_id			=> l_location_level_id,
										p_maximum_age					=> t_maximum_age,
										p_minimum_duration			=> t_minimum_duration,
										p_office_id 					=> t_location_code,
										p_ref_specified_level_id	=> t_ref_level,
										p_ref_attr_value				=> t_ref_attr_value,
										p_debug_yn						=> p_debug_yn
									  );
					EXCEPTION
						WHEN OTHERS
						THEN
							temp_err_msg := SQLERRM;

							temp_err_html :=
									' 1 A = '
								|| t_level_indicator_id
								|| '<BR>'
								|| ' 2 B = '
								|| t_attr_id
								|| '<BR>'
								|| ' 3 C = '
								|| t_attr_value
								|| '<BR>'
								|| ' 4 D = '
								|| t_attr_unit
								|| '<BR>'
								|| ' 5 E = '
								|| t_ref_level
								|| '<BR>'
								|| ' 6 F = '
								|| t_ref_attr_value
								|| '<BR>'
								|| ' 7 G = '
								|| t_md_p1
								|| '<BR>'
								|| ' 8 G = '
								|| t_md_p2
								|| '<BR>'
								|| ' 9 G = '
								|| t_md_p3
								|| '<BR>'
								|| '10 H = '
								|| t_ma_p1
								|| '<BR>'
								|| '11 H = '
								|| t_ma_p2
								|| '<BR>'
								|| '12 H = '
								|| t_ma_p3
								|| '<BR>'
								|| '13 I = '
								|| t1_expression
								|| '<BR>'
								|| '14 J = '
								|| t1_comparison_unit
								|| '<BR>'
								|| '15 K = '
								|| t1_comparison_operator_1
								|| '<BR>'
								|| '16 L = '
								|| t1_comparison_value_1
								|| '<BR>'
								|| '17 M = '
								|| t1_connector
								|| '<BR>'
								|| '18 N = '
								|| t1_comparison_operator_2
								|| '<BR>'
								|| '19 O = '
								|| t1_comparison_value_2
								|| '<BR>'
								|| '20 P = '
								|| t1_rate_expression
								|| '<BR>'
								|| '21 Q = '
								|| t1_rate_comparison_unit
								|| '<BR>'
								|| '22 R = '
								|| t1_rate_interval
								|| '<BR>'
								|| '23 S = '
								|| t1_rate_comparison_operator_1
								|| '<BR>'
								|| '24 T = '
								|| t1_rate_comparison_value_1
								|| '<BR>'
								|| '25 U = '
								|| t1_rate_connector
								|| '<BR>'
								|| '26 V = '
								|| t1_rate_comparison_operator_2
								|| '<BR>'
								|| '27 W = '
								|| t1_rate_comparison_value_2
								|| '<BR>'
								|| '28 X = '
								|| t1_description
								|| '<BR>'
								|| '29 Y = '
								|| t2_expression
								|| '<BR>'
								|| '30 Z = '
								|| t2_comparison_unit
								|| '<BR>'
								|| '31 AA = '
								|| t2_comparison_operator_1
								|| '<BR>'
								|| '32 AB = '
								|| t2_comparison_value_1
								|| '<BR>'
								|| '33 AC = '
								|| t2_connector
								|| '<BR>'
								|| '34 AD = '
								|| t2_comparison_operator_2
								|| '<BR>'
								|| '35 AE = '
								|| t2_comparison_value_2
								|| '<BR>'
								|| '36 AF = '
								|| t2_rate_expression
								|| '<BR>'
								|| '37 AG = '
								|| t2_rate_comparison_unit
								|| '<BR>'
								|| '38 AH = '
								|| t2_rate_interval
								|| '<BR>'
								|| '39 AI = '
								|| t2_rate_comparison_operator_1
								|| '<BR>'
								|| '40 AJ = '
								|| t2_rate_comparison_value_1
								|| '<BR>'
								|| '41 AK = '
								|| t2_rate_connector
								|| '<BR>'
								|| '42 AL = '
								|| t2_rate_comparison_operator_2
								|| '<BR>'
								|| '43 AM = '
								|| t2_rate_comparison_value_2
								|| '<BR>'
								|| '44 AN = '
								|| t2_description
								|| '<BR>'
								|| '45 AO = '
								|| t3_expression
								|| '<BR>'
								|| '46 AP = '
								|| t3_comparison_unit
								|| '<BR>'
								|| '47 AQ = '
								|| t3_comparison_operator_1
								|| '<BR>'
								|| '48 AR = '
								|| t3_comparison_value_1
								|| '<BR>'
								|| '49 AS = '
								|| t3_connector
								|| '<BR>'
								|| '50 AT = '
								|| t3_comparison_operator_2
								|| '<BR>'
								|| '51 AU = '
								|| t3_comparison_value_2
								|| '<BR>'
								|| '52 AV = '
								|| t3_rate_expression
								|| '<BR>'
								|| '53 AW = '
								|| t3_rate_comparison_unit
								|| '<BR>'
								|| '54 AX = '
								|| t3_rate_interval
								|| '<BR>'
								|| '55 AY = '
								|| t3_rate_comparison_operator_1
								|| '<BR>'
								|| '56 AZ = '
								|| t3_rate_comparison_value_1
								|| '<BR>'
								|| '57 BA = '
								|| t3_rate_connector
								|| '<BR>'
								|| '58 BB = '
								|| t3_rate_comparison_operator_2
								|| '<BR>'
								|| '59 BC = '
								|| t3_rate_comparison_value_2
								|| '<BR>'
								|| '60 BD = '
								|| t3_description
								|| '<BR>'
								|| '61 BE = '
								|| t4_expression
								|| '<BR>'
								|| '62 BF = '
								|| t4_comparison_unit
								|| '<BR>'
								|| '63 BG = '
								|| t4_comparison_operator_1
								|| '<BR>'
								|| '64 BH = '
								|| t4_comparison_value_1
								|| '<BR>'
								|| '65 BI = '
								|| t4_connector
								|| '<BR>'
								|| '66 BJ = '
								|| t4_comparison_operator_2
								|| '<BR>'
								|| '67 BK = '
								|| t4_comparison_value_2
								|| '<BR>'
								|| '68 BL = '
								|| t4_rate_expression
								|| '<BR>'
								|| '69 BM = '
								|| t4_rate_comparison_unit
								|| '<BR>'
								|| '70 BN = '
								|| t4_rate_interval
								|| '<BR>'
								|| '71 BO = '
								|| t4_rate_comparison_operator_1
								|| '<BR>'
								|| '72 BP = '
								|| t4_rate_comparison_value_1
								|| '<BR>'
								|| '73 BQ = '
								|| t4_rate_connector
								|| '<BR>'
								|| '74 BR = '
								|| t4_rate_comparison_operator_2
								|| '<BR>'
								|| '75 BS = '
								|| t4_rate_comparison_value_2
								|| '<BR>'
								|| '76 BT = '
								|| t4_description
								|| '<BR>'
								|| '77 BU = '
								|| t5_expression
								|| '<BR>'
								|| '78 BV = '
								|| t5_comparison_unit
								|| '<BR>'
								|| '79 BW = '
								|| t5_comparison_operator_1
								|| '<BR>'
								|| '80 BX = '
								|| t5_comparison_value_1
								|| '<BR>'
								|| '81 BY = '
								|| t5_connector
								|| '<BR>'
								|| '82 BZ = '
								|| t5_comparison_operator_2
								|| '<BR>'
								|| '83 CA = '
								|| t5_comparison_value_2
								|| '<BR>'
								|| '84 CB = '
								|| t5_rate_expression
								|| '<BR>'
								|| '85 CC = '
								|| t5_rate_comparison_unit
								|| '<BR>'
								|| '86 CD = '
								|| t5_rate_interval
								|| '<BR>'
								|| '87 CE = '
								|| t5_rate_comparison_operator_1
								|| '<BR>'
								|| '88 CF = '
								|| t5_rate_comparison_value_1
								|| '<BR>'
								|| '89 CG = '
								|| t5_rate_connector
								|| '<BR>'
								|| '90 CH = '
								|| t5_rate_comparison_operator_2
								|| '<BR>'
								|| '91 CI = '
								|| t5_rate_comparison_value_2
								|| '<BR>'
								|| '92 CJ = '
								|| t5_description
								|| '<BR>'
								|| '93 CK = '
								|| t_location_code
								|| '<BR>'
								|| 'Interval 1, Minimum Duration = '
								|| t_minimum_duration
								|| '<BR>'
								|| 'Interval 2, Maximum Age = '
								|| t_maximum_age;

							INSERT
							  INTO	uploaded_xls_file_rows_t (id,
																		  file_id,
																		  date_uploaded,
																		  user_id_uploaded,
																		  date_last_updated,
																		  user_id_last_updated,
																		  error_code_original,
																		  pl_sql_call,
																		  single_row_yn,
																		  seasonal_component
																		 )
							VALUES	(
											uploaded_xls_file_rows_seq.NEXTVAL,
											p_file_id,
											SYSDATE,
											p_user_id,
											SYSDATE,
											p_user_id --, 'Logging Setting Page API Variables from XLS! --' || temp_err_msg
														,
											'Error in setting Page API Variables from XLS! --'
											|| temp_err_msg,
												'LINE #'
											|| temp_num_rows
											|| '<BR>'
											|| ' = "'
											|| v_line
											|| '"<BR>'
											|| 'p_office_id = '
											|| t_location_code
											|| '<BR>'
											|| 'p_location_level_id = '
											|| l_location_level_id
											|| '<BR>'
											|| 'Internal Variables and Excel Cell Columns<BR>'
											|| temp_err_html,
											c_app_logic_yes,
											NULL
										);
					END;
				END IF;													 -- temp_num_rows = 0

				--Reset line if at the end
				v_line := NULL;
				--Increment counter
				temp_num_rows := temp_num_rows + 1;
			END IF;
		END LOOP;


		UPDATE	uploaded_xls_files_t
			SET	row_count_all = temp_num_rows
		 WHERE	id = p_file_id;
	END load_lli;

	PROCEDURE load_lli_2 (
		p_attr_id						IN VARCHAR2,
		p_attr_value					IN NUMBER,
		p_attr_unit 					IN VARCHAR2,
		p_conditions					IN loc_lvl_ind_cond_tab_t := loc_lvl_ind_cond_tab_t (),
		p_file_id						IN uploaded_xls_files_t.id%TYPE,
		p_indicator 					IN loc_lvl_indicator_t,
		p_location_level_id			IN VARCHAR2,
		p_maximum_age					IN at_loc_lvl_indicator.maximum_age%TYPE,
		p_minimum_duration			IN at_loc_lvl_indicator.minimum_duration%TYPE,
		p_office_id 					IN VARCHAR2,
		p_ref_specified_level_id	IN VARCHAR2,
		p_ref_attr_value				IN NUMBER,
		p_debug_yn						IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
	)
	IS
		temp_err_msg			  VARCHAR2 (1999);
		t_level_indicator_id   VARCHAR2 (1999);
	BEGIN
		IF p_debug_yn = c_app_logic_yes
		THEN
			set_log_row (
				p_error_text	 => ' Logging for location level id and p_location_level = "'
										|| p_location_level_id
										|| '"',
				p_file_id		 => p_file_id,
				p_pl_sql_text	 => 'passing in variables'
			);
			set_log_row (
				p_error_text	 =>	' Logging for reference level "'
										|| p_ref_specified_level_id
										|| '" and reference level id  = "'
										|| p_ref_attr_value
										|| '"' --                                      || ' and unit codes = "' || p_unit_code || '"'
												,
				p_file_id		 => p_file_id,
				p_pl_sql_text	 => 'passing in variables'
			);
		END IF;

		temp_err_msg := NULL;

		BEGIN
			load_lli_hardcoded_2 (p_conditions,
										 p_location_level_id,
										 p_maximum_age,
										 p_minimum_duration,
										 p_office_id,
										 p_ref_specified_level_id,
										 p_ref_attr_value
										);

			IF p_debug_yn = c_app_logic_yes
			THEN
				set_log_row (
					p_error_text	 => ' Logging for location level id and p_location_level = "'
											|| p_location_level_id
											|| '"',
					p_file_id		 => p_file_id,
					p_pl_sql_text	 => 'Variable comparison after calling load_lli_hardcoded_2 '
				);
			END IF;
		--NOTES: Comment out below to make it fail on a no_data_found
		-- l_indicator.store;

		EXCEPTION
			WHEN OTHERS
			THEN
				temp_err_msg := SQLERRM;


				set_log_row (
					p_error_text	 => ' Error in calling load LLI Hardcoded 2  = '
											|| temp_err_msg,
					p_file_id		 => p_file_id,
					p_pl_sql_text	 =>	'p_conditions => p_conditions '
											|| '<BR>'
											|| 'p_location_level_id  => '
											|| p_location_level_id
											|| '<BR>'
											|| 'p_ref_specified_level_id => '
											|| p_ref_specified_level_id
											|| '<BR>'
											|| 'p_ref_Attr_value  => '
											|| p_ref_attr_value
											|| '<BR>'
											|| 'p_office_id => '
											|| p_office_id
				);
		END;
	END load_lli_2;

	PROCEDURE load_lli_hardcoded
	IS
		l_conditions			  loc_lvl_ind_cond_tab_t := loc_lvl_ind_cond_tab_t ();
		l_indicator 			  loc_lvl_indicator_t;
		l_office_id 			  VARCHAR2 (16) := 'CPC';
		l_unit_code 			  NUMBER (10);
		l_location_id			  VARCHAR2 (49);
		l_parameter_id 		  VARCHAR2 (49);
		l_parameter_type_id	  VARCHAR2 (16);
		l_duration_id			  VARCHAR2 (16);
		l_specified_level_id   VARCHAR2 (256);
		l_location_level_id	  VARCHAR2 (390)
			:= 'BROKJDK.Stor.Inst.0.Top of Flood.PERCENT FULL';
	BEGIN
		SELECT	unit_code
		  INTO	l_unit_code
		  FROM	cwms_unit
		 WHERE	unit_id = 'm3';

		l_conditions.EXTEND (5);

		l_conditions (1) :=
			loc_lvl_indicator_cond_t (
				p_indicator_value 				 => 1,
				p_expression						 => '(V - L2) / (L - L2)',
				p_comparison_operator_1 		 => 'LT',
				p_comparison_value_1 			 => 0.1,
				p_comparison_unit 				 => l_unit_code,
				p_connector 						 => NULL,
				p_comparison_operator_2 		 => NULL,
				p_comparison_value_2 			 => NULL,
				p_rate_expression 				 => NULL,
				p_rate_comparison_operator_1	 => NULL,
				p_rate_comparison_value_1		 => NULL,
				p_rate_comparison_unit			 => NULL,
				p_rate_connector					 => NULL,
				p_rate_comparison_operator_2	 => NULL,
				p_rate_comparison_value_2		 => NULL,
				p_rate_interval					 => NULL,
				p_description						 => 'Under 10%'
			);

		l_conditions (2) :=
			loc_lvl_indicator_cond_t (
				p_indicator_value 				 => 2,
				p_expression						 => '(V - L2) / (L - L2)',
				p_comparison_operator_1 		 => 'GE',
				p_comparison_value_1 			 => 0.1,
				p_comparison_unit 				 => l_unit_code,
				p_connector 						 => 'AND',
				p_comparison_operator_2 		 => 'LT',
				p_comparison_value_2 			 => 0.25,
				p_rate_expression 				 => NULL,
				p_rate_comparison_operator_1	 => NULL,
				p_rate_comparison_value_1		 => NULL,
				p_rate_comparison_unit			 => NULL,
				p_rate_connector					 => NULL,
				p_rate_comparison_operator_2	 => NULL,
				p_rate_comparison_value_2		 => NULL,
				p_rate_interval					 => NULL,
				p_description						 => '10% to under 25%'
			);



		l_conditions (3) :=
			loc_lvl_indicator_cond_t (
				p_indicator_value 				 => 3,
				p_expression						 => '(V - L2) / (L - L2)',
				p_comparison_operator_1 		 => 'GE',
				p_comparison_value_1 			 => 0.25,
				p_comparison_unit 				 => l_unit_code,
				p_connector 						 => 'AND',
				p_comparison_operator_2 		 => 'LT',
				p_comparison_value_2 			 => 0.75,
				p_rate_expression 				 => NULL,
				p_rate_comparison_operator_1	 => NULL,
				p_rate_comparison_value_1		 => NULL,
				p_rate_comparison_unit			 => NULL,
				p_rate_connector					 => NULL,
				p_rate_comparison_operator_2	 => NULL,
				p_rate_comparison_value_2		 => NULL,
				p_rate_interval					 => NULL,
				p_description						 => '25% to under 75%'
			);



		l_conditions (4) :=
			loc_lvl_indicator_cond_t (
				p_indicator_value 				 => 4,
				p_expression						 => '(V - L2) / (L - L2)',
				p_comparison_operator_1 		 => 'GE',
				p_comparison_value_1 			 => 0.75,
				p_comparison_unit 				 => l_unit_code,
				p_connector 						 => 'AND',
				p_comparison_operator_2 		 => 'LT',
				p_comparison_value_2 			 => 1,
				p_rate_expression 				 => NULL,
				p_rate_comparison_operator_1	 => NULL,
				p_rate_comparison_value_1		 => NULL,
				p_rate_comparison_unit			 => NULL,
				p_rate_connector					 => NULL,
				p_rate_comparison_operator_2	 => NULL,
				p_rate_comparison_value_2		 => NULL,
				p_rate_interval					 => NULL,
				p_description						 => '75% to under 100%'
			);

		l_conditions (5) :=
			loc_lvl_indicator_cond_t (
				p_indicator_value 				 => 5,
				p_expression						 => '(V - L2) / (L - L2)',
				p_comparison_operator_1 		 => 'GE',
				p_comparison_value_1 			 => 1,
				p_comparison_unit 				 => l_unit_code,
				p_connector 						 => NULL,
				p_comparison_operator_2 		 => NULL,
				p_comparison_value_2 			 => NULL,
				p_rate_expression 				 => NULL,
				p_rate_comparison_operator_1	 => NULL,
				p_rate_comparison_value_1		 => NULL,
				p_rate_comparison_unit			 => NULL,
				p_rate_connector					 => NULL,
				p_rate_comparison_operator_2	 => NULL,
				p_rate_comparison_value_2		 => NULL,
				p_rate_interval					 => NULL,
				p_description						 => '100% and over'
			);

		cwms_level.parse_location_level_id (l_location_id,
														l_parameter_id,
														l_parameter_type_id,
														l_duration_id,
														l_specified_level_id,
														l_location_level_id
													  );

		l_indicator :=
			loc_lvl_indicator_t (
				office_id					 => l_office_id,
				location_id 				 => l_location_id,
				parameter_id				 => l_parameter_id,
				parameter_type_id 		 => l_parameter_type_id,
				duration_id 				 => l_duration_id,
				specified_level_id		 => l_specified_level_id,
				level_indicator_id		 => 'PERCENT FULL',
				attr_value					 => NULL,
				attr_units_id				 => NULL,
				attr_parameter_id 		 => NULL,
				attr_parameter_type_id	 => NULL,
				attr_duration_id			 => NULL,
				ref_specified_level_id	 => NULL,
				ref_attr_value 			 => NULL,
				minimum_duration			 => TO_DSINTERVAL ('00 04:00:00'),
				maximum_age 				 => TO_DSINTERVAL ('00 12:00:00'),
				conditions					 => l_conditions
			);

		l_indicator.store;
	END load_lli_hardcoded;

	PROCEDURE load_lli_hardcoded_2 (
		p_conditions					IN loc_lvl_ind_cond_tab_t := loc_lvl_ind_cond_tab_t (),
		p_location_level_id			IN VARCHAR2,
		p_maximum_age					IN at_loc_lvl_indicator.maximum_age%TYPE,
		p_minimum_duration			IN at_loc_lvl_indicator.minimum_duration%TYPE,
		p_office_id 					IN VARCHAR2,
		p_ref_specified_level_id	IN VARCHAR2,
		p_ref_attr_value				IN NUMBER
	)
	IS
		l_indicator 			  loc_lvl_indicator_t;
		l_location_id			  VARCHAR2 (49);
		l_parameter_id 		  VARCHAR2 (49);
		l_parameter_type_id	  VARCHAR2 (16);
		l_duration_id			  VARCHAR2 (16);
		l_specified_level_id   VARCHAR2 (256);
		t_level_indicator_id   VARCHAR2 (1999);
		l_code					  NUMBER;
	BEGIN
		IF p_conditions IS NOT NULL AND p_conditions.COUNT > 5
		THEN
			cwms_text.store_text (l_code,
										 DBMS_UTILITY.format_call_stack,
										 '/error_text',
										 'error_text',
										 'F',
										 cwms_util.user_office_id
										);
			cwms_err.raise (
				'ERROR',
				'Expected only 5 conditions, found ' || p_conditions.COUNT
			);
		END IF;


		t_level_indicator_id :=
			get_location_level_id_param (p_location_level_id, 6);
		cwms_level.parse_location_level_id (l_location_id,
														l_parameter_id,
														l_parameter_type_id,
														l_duration_id,
														l_specified_level_id,
														p_location_level_id
													  );

		l_indicator :=
			loc_lvl_indicator_t (
				office_id					 => SUBSTR (p_office_id, 1, 3),
				location_id 				 => l_location_id,
				parameter_id				 => l_parameter_id,
				parameter_type_id 		 => l_parameter_type_id,
				duration_id 				 => l_duration_id,
				specified_level_id		 => l_specified_level_id,
				level_indicator_id		 => t_level_indicator_id,
				attr_value					 => NULL,
				attr_units_id				 => NULL,
				attr_parameter_id 		 => NULL,
				attr_parameter_type_id	 => NULL,
				attr_duration_id			 => NULL,
				ref_specified_level_id	 => p_ref_specified_level_id,
				ref_attr_value 			 => p_ref_attr_value,
				minimum_duration			 => p_minimum_duration,
				maximum_age 				 => p_maximum_age,
				conditions					 => p_conditions
			);

		l_indicator.store;
	END load_lli_hardcoded_2;



	--=============================================================================
	--====Begin==store_parsed_loc_egis_file========================================
	--=============================================================================
	PROCEDURE store_parsed_loc_egis_file (
		p_parsed_collection_name		IN VARCHAR2,
		p_store_err_collection_name	IN VARCHAR2,
		p_db_office_id 					IN VARCHAR2 DEFAULT NULL,
		p_unique_process_id				IN VARCHAR2
	)
	IS
		l_location_id			 VARCHAR2 (48);
		l_base_location_id2	 VARCHAR2 (48);
		l_base_location_id	 VARCHAR2 (16);
		l_sub_location_id 	 VARCHAR2 (32);
		l_county_name			 VARCHAR2 (40);
		l_state_initial		 VARCHAR2 (2);
		--===================
		l_latitude				 NUMBER;
		l_longitude 			 NUMBER;
		l_horizontal_datum	 VARCHAR2 (16);
		l_elevation 			 NUMBER;
		l_unit_id				 VARCHAR2 (16);
		l_vertical_datum		 VARCHAR2 (16);

		l_time_zone_name		 VARCHAR2 (28);
		l_long_name 			 VARCHAR2 (80);
		l_description			 VARCHAR2 (1024);
		l_db_office_id 		 VARCHAR2 (16);

		--====================
		l_ignorenulls			 VARCHAR2 (1);
		l_parsed_rows			 NUMBER;
		l_line_no				 VARCHAR2 (32);
		l_line_no2				 VARCHAR2 (32);
		l_min 					 NUMBER;
		l_max 					 NUMBER;
		l_cmt 					 VARCHAR2 (256);
		l_steps_per_commit	 NUMBER;
	BEGIN
		aa1 (
			'store_parsed_loc_egis_file - collection name: '
			|| p_parsed_collection_name
		);
		--============  Create Error Collection  ====  'P613_STORE_ERROR_COLLECTION' ======
		apex_collection.create_or_truncate_collection (
			p_store_err_collection_name
		);


		l_steps_per_commit :=
			TO_NUMBER (
				SUBSTR (p_unique_process_id,
						  (INSTR (p_unique_process_id, '.', 1, 5) + 1)
						 )
			);
		l_cmt :=
			'ST=' || LOCALTIMESTAMP || ';STEPS=' || l_steps_per_commit || ';CT=';
		cwms_properties.set_property ('PROCESS_STATUS',
												p_unique_process_id,
												'Initiated',
												l_cmt || LOCALTIMESTAMP,
												p_db_office_id
											  );

		IF (l_steps_per_commit > 0)
		THEN
			COMMIT;
		END IF;

		SELECT	COUNT (*), MIN (seq_id), MAX (seq_id)
		  INTO	l_parsed_rows, l_min, l_max
		  FROM	apex_collections
		 WHERE	collection_name = p_parsed_collection_name;

		aa1 (
				'l_parsed_rows = '
			|| l_parsed_rows
			|| ' min '
			|| l_min
			|| ' max '
			|| l_max
		);

		-- Start at 2 to skip first line of column titles
		FOR i IN 2 .. l_parsed_rows
		LOOP
			aa1 ('looping: ' || i);

			IF (l_steps_per_commit > 0)
			THEN
				IF (i - TRUNC (i / l_steps_per_commit) * l_steps_per_commit = 0)
				THEN
					cwms_properties.set_property (
						'PROCESS_STATUS',
						p_unique_process_id,
						'Processing: ' || i || ' of ' || l_parsed_rows,
						l_cmt || LOCALTIMESTAMP,
						p_db_office_id
					);
					COMMIT;
				END IF;
			END IF;

			BEGIN --===============   Trap errors in select and store  =================================
				SELECT	c001, c002
				  INTO	l_line_no2, l_base_location_id2
				  FROM	apex_collections
				 WHERE	collection_name = p_parsed_collection_name
							AND seq_id = i;

				SELECT	c001, c002, c003, c004, c005, c006, c007, c008, c009,
							c010, c011, c012, c013, c014, c015
				  INTO	l_line_no, l_base_location_id, l_sub_location_id,
							l_latitude, l_longitude, l_horizontal_datum, l_elevation,
							l_unit_id, l_vertical_datum, l_county_name,
							l_state_initial, l_time_zone_name, l_long_name,
							l_description, l_db_office_id
				  FROM	apex_collections
				 WHERE	collection_name = p_parsed_collection_name
							AND seq_id = i;

				l_location_id :=
					cwms_util.concat_base_sub_id (l_base_location_id,
															l_sub_location_id
														  );

				aa1 ('storing locs-egis: ' || l_base_location_id);
				--
				cwms_loc.store_location (
					p_location_id			=> l_location_id,
					p_county_name			=> l_county_name,
					p_state_initial		=> l_state_initial,
					p_latitude				=> l_latitude,
					p_longitude 			=> l_longitude,
					p_horizontal_datum	=> l_horizontal_datum,
					p_elevation 			=> l_elevation,
					p_elev_unit_id 		=> l_unit_id,
					p_vertical_datum		=> l_vertical_datum,
					p_time_zone_id 		=> l_time_zone_name,
					p_long_name 			=> l_long_name,
					p_description			=> l_description,
					p_ignorenulls			=> 'T',
					p_db_office_id 		=> p_db_office_id
				);
			EXCEPTION
				WHEN OTHERS
				THEN
					DECLARE
						l_i			NUMBER := INSTR (SQLERRM, ':', 1, 1);
						l_err_num	VARCHAR2 (256) := SUBSTR (SQLERRM, 1, l_i);
						l_err_msg	VARCHAR2 (512)
							:= SUBSTR (SQLERRM,
										  l_i + 1,
										  (INSTR (SQLERRM, 'ORA-', 1, 2) - l_i - 1)
										 );
					BEGIN
						IF (LENGTH (l_err_msg) <= 5 OR l_err_msg IS NULL)
						THEN
							l_err_msg := SQLERRM;
						END IF;

						apex_collection.add_member (
							p_store_err_collection_name,
							'Line # ' || i,
							l_err_num,
							l_err_msg,
							l_line_no2 || ':' || l_base_location_id2
						);
					END;
			END; --==================	Trap Errors ==========================================
		END LOOP;

		cwms_properties.set_property (
			'PROCESS_STATUS',
			p_unique_process_id,
			'Completed ' || l_parsed_rows || ' records',
			l_cmt || LOCALTIMESTAMP,
			p_db_office_id
		);
	END store_parsed_loc_egis_file;

	--=============================================================================
	--====End==store_parsed_loc_egis_file==========================================
	--=============================================================================

	PROCEDURE set_log_row (
		p_error_text	 IN uploaded_xls_file_rows_t.error_code_original%TYPE,
		p_file_id		 IN uploaded_xls_file_rows_t.file_id%TYPE,
		p_pl_sql_text	 IN uploaded_xls_file_rows_t.pl_sql_call%TYPE
	)
	IS
	BEGIN
		INSERT
		  INTO	uploaded_xls_file_rows_t (id,
													  file_id,
													  date_uploaded,
													  user_id_uploaded,
													  date_last_updated,
													  user_id_last_updated,
													  error_code_original,
													  pl_sql_call,
													  single_row_yn,
													  seasonal_component
													 )
		VALUES	(
						uploaded_xls_file_rows_seq.NEXTVAL,
						p_file_id,
						SYSDATE,
						'API',
						SYSDATE,
						'API',
						p_error_text,
						p_pl_sql_text,
						c_app_logic_yes,
						NULL
					);
	END set_log_row;
END cwms_apex;
/