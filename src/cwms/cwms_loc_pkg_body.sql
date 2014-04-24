CREATE OR REPLACE PACKAGE BODY cwms_loc
AS
	--
	-- num_group_assigned_to_shef return the number of groups -
	-- currently assigned in the at_shef_decode table.
	FUNCTION znum_group_assigned_to_shef (
		p_group_cat_array   IN group_cat_tab_t,
		p_db_office_code	  IN NUMBER
	)
		RETURN NUMBER
	IS
		l_tmp   NUMBER;
	BEGIN
		SELECT	COUNT (*)
		  INTO	l_tmp
		  FROM	at_shef_decode
		 WHERE	loc_group_code IN
						(SELECT	 loc_group_code
							FROM	 (SELECT   a.loc_category_code,
												  b.loc_group_id
										 FROM   at_loc_category a,
												  TABLE (
													  CAST (
														  p_group_cat_array AS group_cat_tab_t
													  )
												  ) b
										WHERE   UPPER (a.loc_category_id) =
													  UPPER (TRIM (b.loc_category_id))
												  AND a.db_office_code IN
															(p_db_office_code,
															 cwms_util.db_office_code_all)) c,
									 at_loc_group d
						  WHERE	 UPPER (d.loc_group_id) =
										 UPPER (TRIM (c.loc_group_id))
									 AND d.loc_category_code = c.loc_category_code
									 AND d.db_office_code IN
											  (p_db_office_code,
												cwms_util.db_office_code_all));

		RETURN l_tmp;
	END znum_group_assigned_to_shef;

	FUNCTION num_group_assigned_to_shef (
		p_group_cat_array   IN group_cat_tab_t,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER
	IS
		l_db_office_code	 NUMBER
									 := cwms_util.get_db_office_code (p_db_office_id);
	BEGIN
		RETURN znum_group_assigned_to_shef (p_group_cat_array,
														l_db_office_code
													  );
	END num_group_assigned_to_shef;

	--loc_cat_grp_rec_tab_t IS TABLE OF loc_cat_grp_rec_t

	FUNCTION get_location_id (p_location_code IN NUMBER)
		RETURN VARCHAR2
	IS
		l_location_id	 VARCHAR2 (49);
	BEGIN
		IF p_location_code IS NOT NULL
		THEN
			SELECT		bl.base_location_id
						|| SUBSTR ('_', 1, LENGTH (pl.sub_location_id))
						|| pl.sub_location_id
			  INTO	l_location_id
			  FROM	at_physical_location pl, at_base_location bl
			 WHERE	pl.location_code = p_location_code
						AND bl.base_location_code = pl.base_location_code;
		END IF;

		RETURN l_location_id;
	END get_location_id;

	FUNCTION get_location_id (p_location_id_or_alias	 VARCHAR2,
									  p_office_id					 VARCHAR2 DEFAULT NULL
									 )
		RETURN VARCHAR2
	IS
		l_office_id   VARCHAR2 (16);
	BEGIN
		l_office_id :=
			NVL (UPPER (TRIM (p_office_id)), cwms_util.user_office_id);

		FOR rec
			IN (SELECT		 bl.base_location_id
							 || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
							 || pl.sub_location_id
								 AS location_id
					FROM	 at_physical_location pl,
							 at_base_location bl,
							 cwms_office o
				  WHERE		  o.office_id = l_office_id
							 AND bl.db_office_code = o.office_code
							 AND pl.base_location_code = bl.base_location_code
							 AND UPPER (bl.base_location_id) =
									  UPPER (
										  cwms_util.get_base_id (p_location_id_or_alias
																		)
									  )
							 AND NVL (UPPER (pl.sub_location_id), '.') =
									  NVL (
										  UPPER (
											  cwms_util.get_sub_id (
												  p_location_id_or_alias
											  )
										  ),
										  '.'
									  ))
		LOOP
			RETURN TRIM (rec.location_id);
		END LOOP;

		------------------------------------------------
		-- if we get here we didn't find the location --
		------------------------------------------------
		BEGIN
			RETURN get_location_id_from_alias (
						 p_alias_id 	=> p_location_id_or_alias,
						 p_office_id	=> l_office_id
					 );
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('LOCATION_ID_NOT_FOUND', p_location_id_or_alias);
		END;
	END get_location_id;

	FUNCTION get_location_id (p_location_id_or_alias	 VARCHAR2,
									  p_office_code				 NUMBER
									 )
		RETURN VARCHAR2
	IS
		l_office_id   VARCHAR2 (16);
	BEGIN
		SELECT	office_id
		  INTO	l_office_id
		  FROM	cwms_office
		 WHERE	office_code = p_office_code;

		RETURN get_location_id (p_location_id_or_alias, l_office_id);
	END get_location_id;


	--********************************************************************** -
	--********************************************************************** -
	--********************************************************************** -
	--
	-- get_location_code returns location_code
	--
	------------------------------------------------------------------------------*/
	FUNCTION get_location_code (p_db_office_id	IN VARCHAR2,
										 p_location_id 	IN VARCHAR2,
                               p_check_aliases  IN VARCHAR2
										)
		RETURN NUMBER
		RESULT_CACHE
	IS
		l_db_office_code	 NUMBER := cwms_util.get_office_code (p_db_office_id);
	BEGIN
		RETURN get_location_code (p_db_office_code	=> l_db_office_code,
										  p_location_id		=> p_location_id,
                                p_check_aliases    => p_check_aliases
										 );
	END;

	--
	FUNCTION get_location_code (p_db_office_code   IN NUMBER,
										 p_location_id 	  IN VARCHAR2,
                               p_check_aliases    IN VARCHAR2
										)
		RETURN NUMBER
		RESULT_CACHE
	IS
		l_location_code	NUMBER;
	BEGIN     
		IF p_location_id IS NULL
		THEN         
			cwms_err.raise ('ERROR',
								 'The P_LOCATION_ID parameter cannot be NULL'
								);
		END IF;

		--
		SELECT	apl.location_code
		  INTO	l_location_code
		  FROM	at_physical_location apl, at_base_location abl
		 WHERE	apl.base_location_code = abl.base_location_code
					AND UPPER (abl.base_location_id) =
							 UPPER (cwms_util.get_base_id (p_location_id))
					AND NVL (UPPER (apl.sub_location_id), '.') =
							 NVL (UPPER (cwms_util.get_sub_id (p_location_id)), '.')
					AND abl.db_office_code = p_db_office_code;

		--
   	RETURN l_location_code;
	--
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
         IF cwms_util.is_true(p_check_aliases) THEN
            DECLARE
               l_office_id   VARCHAR2 (16);
            BEGIN
               SELECT   office_id
                 INTO   l_office_id
                 FROM   cwms_office
                WHERE   office_code = p_db_office_code;

               l_location_code :=
                  get_location_code_from_alias (p_alias_id  => p_location_id,
                                                p_office_id => l_office_id
                                               );
               IF l_location_code IS NULL
               THEN
                  cwms_err.raise('LOCATION_ID_NOT_FOUND', p_location_id);
               END IF;

               RETURN l_location_code;
            END;
         ELSE
            RAISE;
         END IF;
		WHEN OTHERS
		THEN     
			RAISE;
	END get_location_code;
   
   FUNCTION get_location_code (p_db_office_code   IN NUMBER,
                               p_location_id      IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE
   IS
   BEGIN
      return get_location_code(p_db_office_code, p_location_id, 'T');
   END get_location_code;
      
   FUNCTION get_location_code (p_db_office_id   IN VARCHAR2,
                               p_location_id    IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE
   IS
   BEGIN
      return get_location_code(p_db_office_id, p_location_id, 'T');
   END get_location_code;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- get_state_code returns state_code
	--
	------------------------------------------------------------------------------*/
	FUNCTION get_state_code (p_state_initial IN VARCHAR2 DEFAULT NULL)
		RETURN NUMBER
	IS
		l_state_code	NUMBER;
	BEGIN
		--dbms_output.put_line('function: get_county_code');
		--
		-- initialize l_state_initial...
		IF p_state_initial IS NULL OR p_state_initial = '0'
		THEN
			RETURN 0;
		END IF;

		SELECT	state_code
		  INTO	l_state_code
		  FROM	cwms_state
		 WHERE	UPPER (state_initial) = UPPER (p_state_initial);

		RETURN l_state_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			raise_application_error (
				-20213,
				p_state_initial || ' is an invalid State Abreviation',
				TRUE
			);
		WHEN OTHERS
		THEN
			RAISE;
	END get_state_code;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- get_county_code returns county_code
	--
	------------------------------------------------------------------------------*/
	FUNCTION get_county_code (p_county_name	  IN VARCHAR2 DEFAULT NULL,
									  p_state_initial   IN VARCHAR2 DEFAULT NULL
									 )
		RETURN NUMBER
	IS
		l_county_code		NUMBER;
		l_county_name		VARCHAR2 (40);
		l_state_initial	VARCHAR2 (2);
	BEGIN
		-- initialize l_county_name...
		IF p_county_name IS NULL
		THEN
			l_county_name := 'Unknown County or County N/A';
		ELSE
			l_county_name := p_county_name;
		END IF;

		--
		-- initialize l_state_initial...
		IF p_state_initial IS NULL OR p_state_initial = '0'
		THEN
			l_state_initial := '00';
		ELSE
			l_state_initial := p_state_initial;
		END IF;

		--dbms_output.put_line('function: get_county_code_code');
		SELECT	county_code
		  INTO	l_county_code
		  FROM	cwms_county
		 WHERE	UPPER (county_name) = UPPER (l_county_name)
					AND state_code = get_state_code (l_state_initial);

		RETURN l_county_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			raise_application_error (
				-20214,
					'Could not find '
				|| p_county_name
				|| ' county/parish '
				|| ' in '
				|| p_state_initial,
				TRUE
			);
		WHEN OTHERS
		THEN
			RAISE;
	END get_county_code;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- get_county_code returns zone_code
	--
	------------------------------------------------------------------------------*/
	FUNCTION get_timezone_code (p_time_zone_id IN VARCHAR2)
		RETURN NUMBER
	IS
		l_zone_code   NUMBER;
	BEGIN
		--dbms_output.put_line('function: get_county_code');
		SELECT	time_zone_code
		  INTO	l_zone_code
		  FROM	mv_time_zone
		 WHERE	UPPER (time_zone_name) = UPPER (p_time_zone_id);

		RETURN l_zone_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			raise_application_error (
				-20215,
				'Could not find a ' || p_time_zone_id || ' time zone',
				TRUE
			);
		WHEN OTHERS
		THEN
			RAISE;
	END get_timezone_code;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- CONVERT_FROM_TO converts a pararameter from one unit to antoher
	--
	------------------------------------------------------------------------------*/
	FUNCTION convert_from_to (p_orig_value 			 IN NUMBER,
									  p_from_unit_name		 IN VARCHAR2,
									  p_to_unit_name			 IN VARCHAR2,
									  p_abstract_paramname	 IN VARCHAR2
									 )
		RETURN NUMBER
	IS
		l_return_value   NUMBER;
	BEGIN
		--
		-- retrieve correct unit conversion factor/offset...
		BEGIN
			SELECT	p_orig_value * factor + offset
			  INTO	l_return_value
			  FROM	cwms_unit_conversion
			 WHERE	from_unit_id = cwms_util.get_unit_id(p_from_unit_name)
						AND to_unit_id = cwms_util.get_unit_id(p_to_unit_name);

			RETURN l_return_value;
		--
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				raise_application_error (
					-20216,
						'Unable to find conversion factor from '
					|| p_from_unit_name
					|| ' to '
					|| p_to_unit_name
					|| ' in CWMS DB',
					TRUE
				);
			WHEN OTHERS
			THEN
				RAISE;
		END;
	END convert_from_to;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- get_unit_code
	--
	------------------------------------------------------------------------------*/
	FUNCTION get_unit_code (unitname 			  IN VARCHAR2,
									abstractparamname   IN VARCHAR2
								  )
		RETURN NUMBER
	IS
		l_unit_code   NUMBER;
	BEGIN
		SELECT	unit_code
		  INTO	l_unit_code
		  FROM	cwms_unit
		 WHERE	UPPER (unit_id) = UPPER (cwms_util.get_unit_id(unitname))
					AND abstract_param_code =
							 (SELECT   abstract_param_code
								 FROM   cwms_abstract_parameter
								WHERE   abstract_param_id = abstractparamname);

		RETURN l_unit_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			raise_application_error (
				-20217,
					'"'
				|| unitname
				|| '" is not a recognized '
				|| abstractparamname
				|| ' unit',
				TRUE
			);
		WHEN OTHERS
		THEN
			RAISE;
	END get_unit_code;

	FUNCTION is_cwms_id_valid (p_base_loc_id IN VARCHAR2)
		RETURN BOOLEAN
	IS
		l_count	 NUMBER := 0;
	BEGIN
		-- Check that cwmsIdNew starts with an alphnumeric and does
		-- not conatain a period.
		l_count := REGEXP_INSTR (p_base_loc_id, '[\.]');
		l_count := l_count + REGEXP_INSTR (p_base_loc_id, '[^[:alnum:]]');

		IF l_count > 0
		THEN
			RETURN FALSE;
		END IF;

		RETURN TRUE;
	END is_cwms_id_valid;

	--********************************************************************** -
	--.
	--  CREATE_LOCATION_RAW2 -
	--.
	--********************************************************************** -
	--
	PROCEDURE create_location_raw2 (
		p_base_location_code 		OUT NUMBER,
		p_location_code				OUT NUMBER,
		p_base_location_id		IN 	 VARCHAR2,
		p_sub_location_id 		IN 	 VARCHAR2,
		p_db_office_code			IN 	 NUMBER,
		p_location_type			IN 	 VARCHAR2 DEFAULT NULL,
		p_elevation 				IN 	 NUMBER DEFAULT NULL,
		p_vertical_datum			IN 	 VARCHAR2 DEFAULT NULL,
		p_latitude					IN 	 NUMBER DEFAULT NULL,
		p_longitude 				IN 	 NUMBER DEFAULT NULL,
		p_horizontal_datum		IN 	 VARCHAR2 DEFAULT NULL,
		p_public_name				IN 	 VARCHAR2 DEFAULT NULL,
		p_long_name 				IN 	 VARCHAR2 DEFAULT NULL,
		p_description				IN 	 VARCHAR2 DEFAULT NULL,
		p_time_zone_code			IN 	 NUMBER DEFAULT NULL,
		p_county_code				IN 	 NUMBER DEFAULT NULL,
		p_active_flag				IN 	 VARCHAR2 DEFAULT 'T',
		p_location_kind_id		IN 	 VARCHAR2 DEFAULT NULL,
		p_map_label 				IN 	 VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN 	 NUMBER DEFAULT NULL,
		p_published_longitude	IN 	 NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN 	 VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN 	 VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN 	 VARCHAR2 DEFAULT NULL,
		p_db_office_id 			IN 	 VARCHAR2 DEFAULT NULL
	)
	IS
		PRAGMA AUTONOMOUS_TRANSACTION;

		l_hashcode					 NUMBER;
		l_ret 						 NUMBER;
		l_base_loc_exists 		 BOOLEAN := TRUE;
		l_sub_loc_exists			 BOOLEAN := TRUE;
		l_nation_id 				 VARCHAR2 (48) := NVL (p_nation_id, 'UNITED STATES');
		l_bounding_office_id 	 VARCHAR2 (16);
		l_location_kind_code 	 NUMBER;
		l_bounding_office_code	 NUMBER := NULL;
		l_nation_code				 VARCHAR2 (2);
		l_cwms_office_code		 NUMBER (10)
											 := cwms_util.get_office_code ('CWMS');
	BEGIN
		BEGIN
			SELECT	location_kind_code
			  INTO	l_location_kind_code
			  FROM	at_location_kind
			 WHERE	location_kind_id =
							UPPER (NVL (p_location_kind_id, 'POINT'))
						AND office_code IN (p_db_office_code, l_cwms_office_code);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('INVALID_ITEM',
									 p_location_kind_id,
									 'location kind'
									);
		END;

		IF p_bounding_office_id IS NOT NULL
		THEN
			BEGIN
				SELECT	office_code
				  INTO	l_bounding_office_code
				  FROM	cwms_office
				 WHERE	office_id = UPPER (p_bounding_office_id);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_ITEM',
										 p_bounding_office_id,
										 'office id'
										);
			END;
		END IF;

		BEGIN
			SELECT	nation_code
			  INTO	l_nation_code
			  FROM	cwms_nation
			 WHERE	nation_id = UPPER (l_nation_id);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('INVALID_ITEM', l_nation_id, 'nation id');
		END;

		BEGIN
			-- Check if base_location exists -
			SELECT	base_location_code
			  INTO	p_base_location_code
			  FROM	at_base_location abl
			 WHERE	UPPER (abl.base_location_id) = UPPER (p_base_location_id)
						AND abl.db_office_code = p_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_base_loc_exists := FALSE;
		END;

		IF l_base_loc_exists
		THEN
			BEGIN
				-- Check if sub_location exists -
				IF p_sub_location_id IS NULL
				THEN
					SELECT	location_code
					  INTO	p_location_code
					  FROM	at_physical_location apl
					 WHERE	apl.base_location_code = p_base_location_code
								AND apl.sub_location_id IS NULL;
				ELSE
					SELECT	location_code
					  INTO	p_location_code
					  FROM	at_physical_location apl
					 WHERE	apl.base_location_code = p_base_location_code
								AND UPPER (apl.sub_location_id) =
										 UPPER (p_sub_location_id);
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					l_sub_loc_exists := FALSE;
			END;
		END IF;

		IF NOT l_base_loc_exists OR NOT l_sub_loc_exists
		THEN
			---------.
			---------.
			-- Create new base and sub locations in database...
			l_hashcode :=
				DBMS_UTILITY.get_hash_value (
						p_db_office_code
					|| UPPER (p_base_location_id)
					|| UPPER (p_sub_location_id),
					0,
					1073741823
				);
			l_ret :=
				DBMS_LOCK.request (id						=> l_hashcode,
										 timeout 				=> 0,
										 lockmode				=> 5,
										 release_on_commit	=> TRUE
										);

			IF l_ret > 0
			THEN
				DBMS_LOCK.sleep (2);
			ELSE
				---------.
				---------.
				-- Create new Base Location (if necessary)...
				--.
				IF NOT l_base_loc_exists
				THEN
					--.
					-- Insert new Base Location -
					INSERT
						  INTO	at_base_location (base_location_code,
															db_office_code,
															base_location_id,
															active_flag
														  )
						VALUES	(
										cwms_seq.NEXTVAL,
										p_db_office_code,
										p_base_location_id,
										p_active_flag
									)
					RETURNING	base_location_code
						  INTO	p_base_location_code;

					--
					--.Insert new Base Location into at_physical_location -
					INSERT
					  INTO	at_physical_location (location_code,
															 base_location_code,
															 time_zone_code,
															 county_code,
															 location_type,
															 elevation,
															 vertical_datum,
															 longitude,
															 latitude,
															 horizontal_datum,
															 public_name,
															 long_name,
															 description,
															 active_flag,
															 location_kind,
															 map_label,
															 published_latitude,
															 published_longitude,
															 office_code,
															 nation_code,
															 nearest_city
															)
					VALUES	(
									p_base_location_code,
									p_base_location_code,
									p_time_zone_code,
									p_county_code,
									p_location_type,
									p_elevation,
									p_vertical_datum,
									p_longitude,
									p_latitude,
									p_horizontal_datum,
									p_public_name,
									p_long_name,
									p_description,
									p_active_flag,
									l_location_kind_code,
									p_map_label,
									p_published_latitude,
									p_published_longitude,
									l_bounding_office_code,
									l_nation_code,
									p_nearest_city
								);

					p_location_code := p_base_location_code;
				END IF;

				---------.
				---------.
				-- Create new (Sub) Location (if necessary)...
				--.
				IF p_sub_location_id IS NOT NULL
				THEN
					INSERT
						  INTO	at_physical_location (location_code,
																 base_location_code,
																 sub_location_id,
																 time_zone_code,
																 county_code,
																 location_type,
																 elevation,
																 vertical_datum,
																 longitude,
																 latitude,
																 horizontal_datum,
																 public_name,
																 long_name,
																 description,
																 active_flag,
																 location_kind,
																 map_label,
																 published_latitude,
																 published_longitude,
																 office_code,
																 nation_code,
																 nearest_city
																)
						VALUES	(
										cwms_seq.NEXTVAL,
										p_base_location_code,
										p_sub_location_id,
										p_time_zone_code,
										p_county_code,
										p_location_type,
										p_elevation,
										p_vertical_datum,
										p_longitude,
										p_latitude,
										p_horizontal_datum,
										p_public_name,
										p_long_name,
										p_description,
										p_active_flag,
										l_location_kind_code,
										p_map_label,
										p_published_latitude,
										p_published_longitude,
										l_bounding_office_code,
										l_nation_code,
										p_nearest_city
									)
					RETURNING	location_code
						  INTO	p_location_code;
				END IF;
			END IF;
		END IF;

		--
		COMMIT;											  -- needed to release dbms_lock.
	--
	END create_location_raw2;

	--********************************************************************** -
	--********************************************************************** -
	--.
	--  CREATE_LOCATION_RAW -
	--.
	--********************************************************************** -
	--
	-- The create_location_raw call is called by create_location and -
	-- rename_location. It's intended to be only called internally because -
	-- the call accepts raw codeed values such as db_office_code. -
	--.
	--*---------------------------------------------------------------------*-
	--
	PROCEDURE create_location_raw (
		p_base_location_code 	  OUT NUMBER,
		p_location_code			  OUT NUMBER,
		p_base_location_id	  IN		VARCHAR2,
		p_sub_location_id 	  IN		VARCHAR2,
		p_db_office_code		  IN		NUMBER,
		p_location_type		  IN		VARCHAR2 DEFAULT NULL,
		p_elevation 			  IN		NUMBER DEFAULT NULL,
		p_vertical_datum		  IN		VARCHAR2 DEFAULT NULL,
		p_latitude				  IN		NUMBER DEFAULT NULL,
		p_longitude 			  IN		NUMBER DEFAULT NULL,
		p_horizontal_datum	  IN		VARCHAR2 DEFAULT NULL,
		p_public_name			  IN		VARCHAR2 DEFAULT NULL,
		p_long_name 			  IN		VARCHAR2 DEFAULT NULL,
		p_description			  IN		VARCHAR2 DEFAULT NULL,
		p_time_zone_code		  IN		NUMBER DEFAULT NULL,
		p_county_code			  IN		NUMBER DEFAULT NULL,
		p_active_flag			  IN		VARCHAR2 DEFAULT 'T'
	)
	IS
	BEGIN
		create_location_raw2 (p_base_location_code,
									 p_location_code,
									 p_base_location_id,
									 p_sub_location_id,
									 p_db_office_code,
									 p_location_type,
									 p_elevation,
									 p_vertical_datum,
									 p_latitude,
									 p_longitude,
									 p_horizontal_datum,
									 p_public_name,
									 p_long_name,
									 p_description,
									 p_time_zone_code,
									 p_county_code,
									 p_active_flag
									);
	END create_location_raw;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- UPDATE_LOC -
	--
	--*---------------------------------------------------------------------*-
	--
	-- This is the v1.4 api call - ported for backward compatibility.
	--
	--*---------------------------------------------------------------------*-
	----
	---
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	PROCEDURE update_loc (
		p_office_id 		 IN VARCHAR2,
		p_base_loc_id		 IN VARCHAR2,
		p_location_type	 IN VARCHAR2 DEFAULT NULL,
		p_elevation 		 IN NUMBER DEFAULT NULL,
		p_elev_unit_id 	 IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum	 IN VARCHAR2 DEFAULT NULL,
		p_latitude			 IN NUMBER DEFAULT NULL,
		p_longitude 		 IN NUMBER DEFAULT NULL,
		p_public_name		 IN VARCHAR2 DEFAULT NULL,
		p_description		 IN VARCHAR2 DEFAULT NULL,
		p_timezone_id		 IN VARCHAR2 DEFAULT NULL,
		p_county_name		 IN VARCHAR2 DEFAULT NULL,
		p_state_initial	 IN VARCHAR2 DEFAULT NULL,
		p_ignorenulls		 IN NUMBER DEFAULT cwms_util.true_num
	)
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	---
	--
	IS
		l_loc_new				loc_type_ds;
		l_horizontal_datum	VARCHAR2 (16) := NULL;
		l_long_name 			VARCHAR2 (80) := NULL;
		l_active 				VARCHAR2 (1) := NULL;
		l_ignorenulls			VARCHAR2 (1) := 'T';
	BEGIN
		IF p_ignorenulls <> cwms_util.true_num
		THEN
			l_ignorenulls := 'F';
		END IF;

		update_location (p_office_id,
							  p_base_loc_id,
							  p_location_type,
							  p_elevation,
							  p_elev_unit_id,
							  p_vertical_datum,
							  p_latitude,
							  p_longitude,
							  l_horizontal_datum,
							  p_public_name,
							  l_long_name,
							  p_description,
							  p_timezone_id,
							  p_county_name,
							  p_state_initial,
							  l_active,
							  p_ignorenulls
							 );
	END update_loc;


	PROCEDURE update_location2 (
		p_location_id				IN VARCHAR2,
		p_location_type			IN VARCHAR2 DEFAULT NULL,
		p_elevation 				IN NUMBER DEFAULT NULL,
		p_elev_unit_id 			IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum			IN VARCHAR2 DEFAULT NULL,
		p_latitude					IN NUMBER DEFAULT NULL,
		p_longitude 				IN NUMBER DEFAULT NULL,
		p_horizontal_datum		IN VARCHAR2 DEFAULT NULL,
		p_public_name				IN VARCHAR2 DEFAULT NULL,
		p_long_name 				IN VARCHAR2 DEFAULT NULL,
		p_description				IN VARCHAR2 DEFAULT NULL,
		p_time_zone_id 			IN VARCHAR2 DEFAULT NULL,
		p_county_name				IN VARCHAR2 DEFAULT NULL,
		p_state_initial			IN VARCHAR2 DEFAULT NULL,
		p_active 					IN VARCHAR2 DEFAULT NULL,
		p_location_kind_id		IN VARCHAR2 DEFAULT NULL,
		p_map_label 				IN VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN NUMBER DEFAULT NULL,
		p_published_longitude	IN NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN VARCHAR2 DEFAULT NULL,
		p_ignorenulls				IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_location_code			 at_physical_location.location_code%TYPE;
		l_time_zone_code			 at_physical_location.time_zone_code%TYPE;
		l_county_code				 cwms_county.county_code%TYPE;
		l_location_type			 at_physical_location.location_type%TYPE;
		l_elevation 				 at_physical_location.elevation%TYPE;
		l_vertical_datum			 at_physical_location.vertical_datum%TYPE;
		l_longitude 				 at_physical_location.longitude%TYPE;
		l_latitude					 at_physical_location.latitude%TYPE;
		l_horizontal_datum		 at_physical_location.horizontal_datum%TYPE;
		l_state_code				 cwms_state.state_code%TYPE;
		l_public_name				 at_physical_location.public_name%TYPE;
		l_long_name 				 at_physical_location.long_name%TYPE;
		l_description				 at_physical_location.description%TYPE;
		l_active_flag				 at_physical_location.active_flag%TYPE;
		l_location_kind_code 	 at_physical_location.location_kind%TYPE;
		l_map_label 				 at_physical_location.map_label%TYPE;
		l_published_latitude 	 at_physical_location.published_latitude%TYPE;
		l_published_longitude	 at_physical_location.published_longitude%TYPE;
		l_bounding_office_code	 at_physical_location.office_code%TYPE;
		l_nation_code				 at_physical_location.nation_code%TYPE;
		l_nearest_city 			 at_physical_location.nearest_city%TYPE;
		--
		l_state_initial			 cwms_state.state_initial%TYPE;
		l_county_name				 cwms_county.county_name%TYPE;
		l_ignorenulls				 BOOLEAN := cwms_util.is_true (p_ignorenulls);
		l_office_code				 NUMBER (10)
			:= cwms_util.get_office_code (p_db_office_id);
		l_cwms_office_code		 NUMBER (10)
											 := cwms_util.get_office_code ('CWMS');
	BEGIN
		--.
		-- dbms_output.put_line('Bienvenue a update_loc');

		-- Retrieve the location's Location Code.
		--
		l_location_code := get_location_code (p_db_office_id, p_location_id);
		DBMS_OUTPUT.put_line ('l_location_code: ' || l_location_code);

		--
		--  If get_location_code did not throw an exception, then a valid base_location_id &.
		--  office_id pair was passed in, therefore continue to update the.
		--  at_physical_location table by first retrieving data for the existing location...
		--
		SELECT	location_type, elevation, vertical_datum, latitude, longitude,
					horizontal_datum, public_name, long_name, description,
					time_zone_code, county_code, active_flag, location_kind,
					map_label, published_latitude, published_longitude,
					office_code, nation_code, nearest_city
		  INTO	l_location_type, l_elevation, l_vertical_datum, l_latitude,
					l_longitude, l_horizontal_datum, l_public_name, l_long_name,
					l_description, l_time_zone_code, l_county_code, l_active_flag,
					l_location_kind_code, l_map_label, l_published_latitude,
					l_published_longitude, l_bounding_office_code, l_nation_code,
					l_nearest_city
		  FROM	at_physical_location
		 WHERE	location_code = l_location_code;

		DBMS_OUTPUT.put_line ('l_elevation: ' || l_elevation);

		----------------------------------------------------------
		----------------------------------------------------------
		-- Perform validation checks on newly passed parameters...

		---------.
		---------.
		-- Update location_type...
		--.
		IF p_location_type IS NOT NULL
		THEN
			l_location_type := p_location_type;
		ELSIF NOT l_ignorenulls
		THEN
			l_location_type := NULL;
		END IF;

		---------.
		---------.
		-- Update any new elvation to the correct DB units...
		--.
		IF p_elevation IS NOT NULL
		THEN
			l_elevation :=
				convert_from_to (p_elevation,
									  p_elev_unit_id,
									  l_elev_db_unit,
									  l_abstract_elev_param
									 );
		ELSIF NOT l_ignorenulls
		THEN
			l_elevation := NULL;
		END IF;

		---------.
		---------.
		-- Update vertical datum...
		--
		IF p_vertical_datum IS NOT NULL
		THEN
			l_vertical_datum := p_vertical_datum;
		ELSIF NOT l_ignorenulls
		THEN
			l_vertical_datum := NULL;
		END IF;

		---------.
		---------.
		-- Update latitude...
		--
		IF p_latitude IS NOT NULL
		THEN
			IF ABS (p_latitude) > 90
			THEN
				raise_application_error (
					-20219,
						'INVALID Latitude value: '
					|| p_latitude
					|| ' - must be between -90 and +90',
					TRUE
				);
			END IF;

			l_latitude := p_latitude;
		ELSIF NOT l_ignorenulls
		THEN
			l_latitude := NULL;
		END IF;

		---------.
		---------.
		-- Update longitude...
		--
		IF p_longitude IS NOT NULL
		THEN
			IF ABS (p_longitude) > 180
			THEN
				raise_application_error (
					-20218,
						'INVALID Longitude value: '
					|| p_longitude
					|| ' - must be between -180 and +180',
					TRUE
				);
			END IF;

			l_longitude := p_longitude;
		ELSIF NOT l_ignorenulls
		THEN
			l_longitude := NULL;
		END IF;

		---------.
		---------.
		-- Update horizontal datum...
		--
		IF p_horizontal_datum IS NOT NULL
		THEN
			l_horizontal_datum := p_horizontal_datum;
		ELSIF NOT l_ignorenulls
		THEN
			l_horizontal_datum := NULL;
		END IF;

		---------.
		---------.
		-- Update public_name...
		--
		IF p_public_name IS NOT NULL
		THEN
			l_public_name := p_public_name;
		ELSIF NOT l_ignorenulls
		THEN
			l_public_name := NULL;
		END IF;

		---------.
		---------.
		-- Update long_name...
		--
		IF p_long_name IS NOT NULL
		THEN
			l_long_name := p_long_name;
		ELSIF NOT l_ignorenulls
		THEN
			l_long_name := NULL;
		END IF;

		---------.
		---------.
		-- Update description...
		--
		IF p_description IS NOT NULL
		THEN
			l_description := p_description;
		ELSIF NOT l_ignorenulls
		THEN
			l_description := NULL;
		END IF;

		---------.
		---------.
		-- Update time_zone...
		--
		IF p_time_zone_id IS NOT NULL
		THEN
			l_time_zone_code := get_timezone_code (p_time_zone_id);
		ELSIF NOT l_ignorenulls
		THEN
			l_time_zone_code := NULL;
		END IF;

		---------.
		---------.
		-- Check and Update he State/County pair...
		--
		IF p_state_initial IS NULL AND p_county_name IS NOT NULL
		THEN			-- Throw exception - if a county name is passed in one must.
			-- also pass-in the county's state initials.
			cwms_err.raise ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
		ELSIF p_state_initial IS NOT NULL
		THEN										 -- Find the corresponding county_code.
			l_county_code := get_county_code (p_county_name, p_state_initial);
		ELSIF NOT l_ignorenulls
		THEN
			l_county_code := NULL;
		END IF;

		---------.
		---------.
		-- Update active_flag.
		--.
		IF p_active IS NOT NULL
		THEN
			IF cwms_util.is_true (p_active)
			THEN
				l_active_flag := 'T';
			ELSIF cwms_util.is_false (p_active)
			THEN
				l_active_flag := 'F';
			ELSE
				cwms_err.raise ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
			END IF;
		END IF;

		-------------------
		-- location kind --
		-------------------
		IF p_location_kind_id IS NOT NULL
		THEN
			BEGIN
				SELECT	location_kind_code
				  INTO	l_location_kind_code
				  FROM	at_location_kind
				 WHERE	location_kind_id = UPPER (p_location_kind_id)
							AND office_code IN (l_office_code, l_cwms_office_code);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_ITEM',
										 p_location_kind_id,
										 'location kind id'
										);
			END;
		END IF;

		---------------
		-- map label --
		---------------
		IF p_map_label IS NOT NULL
		THEN
			l_map_label := p_map_label;
		ELSIF NOT l_ignorenulls
		THEN
			l_map_label := NULL;
		END IF;

		------------------------
		-- published latitude --
		------------------------
		IF p_published_latitude IS NOT NULL
		THEN
			l_published_latitude := p_published_latitude;
		ELSIF NOT l_ignorenulls
		THEN
			l_published_latitude := NULL;
		END IF;

		-------------------------
		-- published longitude --
		-------------------------
		IF p_published_longitude IS NOT NULL
		THEN
			l_published_longitude := p_published_longitude;
		ELSIF NOT l_ignorenulls
		THEN
			l_published_longitude := NULL;
		END IF;

		-----------------
		-- office code --
		-----------------
		IF p_bounding_office_id IS NOT NULL
		THEN
			BEGIN
				SELECT	office_code
				  INTO	l_bounding_office_code
				  FROM	cwms_office
				 WHERE	office_id = UPPER (p_bounding_office_id);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_ITEM',
										 p_bounding_office_id,
										 'office id'
										);
			END;
		ELSIF NOT l_ignorenulls
		THEN
			l_bounding_office_code := NULL;
		END IF;

		-----------------
		-- nation code --
		-----------------
		IF p_nation_id IS NOT NULL
		THEN
			BEGIN
				SELECT	nation_code
				  INTO	l_nation_code
				  FROM	cwms_nation
				 WHERE	nation_id = UPPER (p_nation_id);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_ITEM', p_nation_id, 'nation id');
			END;
		ELSIF NOT l_ignorenulls
		THEN
			l_nation_code := NULL;
		END IF;

		------------------
		-- nearest city --
		------------------
		IF p_nearest_city IS NOT NULL
		THEN
			l_nearest_city := p_nearest_city;
		ELSIF NOT l_ignorenulls
		THEN
			l_nearest_city := NULL;
		END IF;


		--.
		--*************************************.
		-- Update at_physical_location table...
		--.
		UPDATE	at_physical_location
			SET	location_type = l_location_type,
					elevation = l_elevation,
					vertical_datum = l_vertical_datum,
					latitude = l_latitude,
					longitude = l_longitude,
					horizontal_datum = l_horizontal_datum,
					public_name = l_public_name,
					long_name = l_long_name,
					description = l_description,
					time_zone_code = l_time_zone_code,
					county_code = l_county_code,
					active_flag = l_active_flag,
					location_kind = l_location_kind_code,
					map_label = l_map_label,
					published_latitude = l_published_latitude,
					published_longitude = l_published_longitude,
					office_code = l_bounding_office_code,
					nation_code = l_nation_code,
					nearest_city = l_nearest_city
		 WHERE	location_code = l_location_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			RAISE;
	END update_location2;


	--********************************************************************** -
	--********************************************************************** -
	--
	-- UPDATE_LOCATION -
	--
	--*---------------------------------------------------------------------*-
	--
	-- Version 2.0 api call -
	--
	--*---------------------------------------------------------------------*-
	--
	PROCEDURE update_location (p_location_id			IN VARCHAR2,
										p_location_type		IN VARCHAR2 DEFAULT NULL,
										p_elevation 			IN NUMBER DEFAULT NULL,
										p_elev_unit_id 		IN VARCHAR2 DEFAULT NULL,
										p_vertical_datum		IN VARCHAR2 DEFAULT NULL,
										p_latitude				IN NUMBER DEFAULT NULL,
										p_longitude 			IN NUMBER DEFAULT NULL,
										p_horizontal_datum	IN VARCHAR2 DEFAULT NULL,
										p_public_name			IN VARCHAR2 DEFAULT NULL,
										p_long_name 			IN VARCHAR2 DEFAULT NULL,
										p_description			IN VARCHAR2 DEFAULT NULL,
										p_time_zone_id 		IN VARCHAR2 DEFAULT NULL,
										p_county_name			IN VARCHAR2 DEFAULT NULL,
										p_state_initial		IN VARCHAR2 DEFAULT NULL,
										p_active 				IN VARCHAR2 DEFAULT NULL,
										p_ignorenulls			IN VARCHAR2 DEFAULT 'T',
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  )
	IS
		l_location_code		at_physical_location.location_code%TYPE;
		l_time_zone_code		at_physical_location.time_zone_code%TYPE;
		l_county_code			cwms_county.county_code%TYPE;
		l_location_type		at_physical_location.location_type%TYPE;
		l_elevation 			at_physical_location.elevation%TYPE;
		l_vertical_datum		at_physical_location.vertical_datum%TYPE;
		l_longitude 			at_physical_location.longitude%TYPE;
		l_latitude				at_physical_location.latitude%TYPE;
		l_horizontal_datum	at_physical_location.horizontal_datum%TYPE;
		l_state_code			cwms_state.state_code%TYPE;
		l_public_name			at_physical_location.public_name%TYPE;
		l_long_name 			at_physical_location.long_name%TYPE;
		l_description			at_physical_location.description%TYPE;
		l_active_flag			at_physical_location.active_flag%TYPE;
		--
		l_state_initial		cwms_state.state_initial%TYPE;
		l_county_name			cwms_county.county_name%TYPE;
		l_ignorenulls			BOOLEAN := cwms_util.is_true (p_ignorenulls);
	BEGIN
		--.
		-- dbms_output.put_line('Bienvenue a update_loc');

		-- Retrieve the location's Location Code.
		--
		l_location_code := get_location_code (p_db_office_id, p_location_id);
		DBMS_OUTPUT.put_line ('l_location_code: ' || l_location_code);

		--
		--  If get_location_code did not throw an exception, then a valid base_location_id &.
		--  office_id pair was passed in, therefore continue to update the.
		--  at_physical_location table by first retrieving data for the existing location...
		--
		SELECT	location_type, elevation, vertical_datum, latitude, longitude,
					horizontal_datum, public_name, long_name, description,
					time_zone_code, county_code, active_flag
		  INTO	l_location_type, l_elevation, l_vertical_datum, l_latitude,
					l_longitude, l_horizontal_datum, l_public_name, l_long_name,
					l_description, l_time_zone_code, l_county_code, l_active_flag
		  FROM	at_physical_location
		 WHERE	location_code = l_location_code;

		DBMS_OUTPUT.put_line ('l_elevation: ' || l_elevation);

		----------------------------------------------------------
		----------------------------------------------------------
		-- Perform validation checks on newly passed parameters...

		---------.
		---------.
		-- Update location_type...
		--.
		IF p_location_type IS NOT NULL
		THEN
			l_location_type := p_location_type;
		ELSIF NOT l_ignorenulls
		THEN
			l_location_type := NULL;
		END IF;

		---------.
		---------.
		-- Update any new elvation to the correct DB units...
		--.
		IF p_elevation IS NOT NULL
		THEN
			l_elevation :=
				convert_from_to (p_elevation,
									  p_elev_unit_id,
									  l_elev_db_unit,
									  l_abstract_elev_param
									 );
		ELSIF NOT l_ignorenulls
		THEN
			l_elevation := NULL;
		END IF;

		---------.
		---------.
		-- Update vertical datum...
		--
		IF p_vertical_datum IS NOT NULL
		THEN
			l_vertical_datum := p_vertical_datum;
		ELSIF NOT l_ignorenulls
		THEN
			l_vertical_datum := NULL;
		END IF;

		---------.
		---------.
		-- Update latitude...
		--
		IF p_latitude IS NOT NULL
		THEN
			IF ABS (p_latitude) > 90
			THEN
				raise_application_error (
					-20219,
						'INVALID Latitude value: '
					|| p_latitude
					|| ' - must be between -90 and +90',
					TRUE
				);
			END IF;

			l_latitude := p_latitude;
		ELSIF NOT l_ignorenulls
		THEN
			l_latitude := NULL;
		END IF;

		---------.
		---------.
		-- Update longitude...
		--
		IF p_longitude IS NOT NULL
		THEN
			IF ABS (p_longitude) > 180
			THEN
				raise_application_error (
					-20218,
						'INVALID Longitude value: '
					|| p_longitude
					|| ' - must be between -180 and +180',
					TRUE
				);
			END IF;

			l_longitude := p_longitude;
		ELSIF NOT l_ignorenulls
		THEN
			l_longitude := NULL;
		END IF;

		---------.
		---------.
		-- Update horizontal datum...
		--
		IF p_horizontal_datum IS NOT NULL
		THEN
			l_horizontal_datum := p_horizontal_datum;
		ELSIF NOT l_ignorenulls
		THEN
			l_horizontal_datum := NULL;
		END IF;

		---------.
		---------.
		-- Update public_name...
		--
		IF p_public_name IS NOT NULL
		THEN
			l_public_name := p_public_name;
		ELSIF NOT l_ignorenulls
		THEN
			l_public_name := NULL;
		END IF;

		---------.
		---------.
		-- Update long_name...
		--
		IF p_long_name IS NOT NULL
		THEN
			l_long_name := p_long_name;
		ELSIF NOT l_ignorenulls
		THEN
			l_long_name := NULL;
		END IF;

		---------.
		---------.
		-- Update description...
		--
		IF p_description IS NOT NULL
		THEN
			l_description := p_description;
		ELSIF NOT l_ignorenulls
		THEN
			l_description := NULL;
		END IF;

		---------.
		---------.
		-- Update time_zone...
		--
		IF p_time_zone_id IS NOT NULL
		THEN
			l_time_zone_code := get_timezone_code (p_time_zone_id);
		ELSIF NOT l_ignorenulls
		THEN
			l_time_zone_code := NULL;
		END IF;

		---------.
		---------.
		-- Check and Update he State/County pair...
		--
		IF p_state_initial IS NULL AND p_county_name IS NOT NULL
		THEN			-- Throw exception - if a county name is passed in one must.
			-- also pass-in the county's state initials.
			cwms_err.raise ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
		ELSIF p_state_initial IS NOT NULL
		THEN										 -- Find the corresponding county_code.
			l_county_code := get_county_code (p_county_name, p_state_initial);
		ELSIF NOT l_ignorenulls
		THEN
			l_county_code := NULL;
		END IF;

		---------.
		---------.
		-- Update active_flag.
		--.
		IF p_active IS NOT NULL
		THEN
			IF cwms_util.is_true (p_active)
			THEN
				l_active_flag := 'T';
			ELSIF cwms_util.is_false (p_active)
			THEN
				l_active_flag := 'F';
			ELSE
				cwms_err.raise ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
			END IF;
		END IF;

		--.
		--*************************************.
		-- Update at_physical_location table...
		--.
		UPDATE	at_physical_location
			SET	location_type = l_location_type,
					elevation = l_elevation,
					vertical_datum = l_vertical_datum,
					latitude = l_latitude,
					longitude = l_longitude,
					horizontal_datum = l_horizontal_datum,
					public_name = l_public_name,
					long_name = l_long_name,
					description = l_description,
					time_zone_code = l_time_zone_code,
					county_code = l_county_code,
					active_flag = l_active_flag
		 WHERE	location_code = l_location_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			RAISE;
	END update_location;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- INSERT_LOC -
	--
	--*---------------------------------------------------------------------*-
	--
	-- This is the v1.4 api call - ported for backward compatibility.
	--
	--*---------------------------------------------------------------------*-
	--
	---
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv...
	PROCEDURE insert_loc (p_office_id		  IN VARCHAR2,
								 p_base_loc_id 	  IN VARCHAR2,
								 p_state_initial	  IN VARCHAR2 DEFAULT NULL,
								 p_county_name 	  IN VARCHAR2 DEFAULT NULL,
								 p_timezone_name	  IN VARCHAR2 DEFAULT NULL,
								 p_location_type	  IN VARCHAR2 DEFAULT NULL,
								 p_latitude 		  IN NUMBER DEFAULT NULL,
								 p_longitude		  IN NUMBER DEFAULT NULL,
								 p_elevation		  IN NUMBER DEFAULT NULL,
								 p_elev_unit_id	  IN VARCHAR2 DEFAULT NULL,
								 p_vertical_datum   IN VARCHAR2 DEFAULT NULL,
								 p_public_name 	  IN VARCHAR2 DEFAULT NULL,
								 p_long_name		  IN VARCHAR2 DEFAULT NULL,
								 p_description 	  IN VARCHAR2 DEFAULT NULL
								)
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	---
	--
	IS
		l_horizontal_datum	VARCHAR2 (16) := NULL;
		l_active 				VARCHAR2 (1) := 'T';
	BEGIN
		create_location (p_base_loc_id,
							  p_office_id,
							  p_location_type,
							  p_elevation,
							  p_elev_unit_id,
							  p_vertical_datum,
							  p_latitude,
							  p_longitude,
							  l_horizontal_datum,
							  p_public_name,
							  p_long_name,
							  p_description,
							  p_timezone_name,
							  p_county_name,
							  p_state_initial,
							  l_active
							 );
	END insert_loc;


	--********************************************************************** -
	--.
	--  CREATE_LOCATION2 -
	--.
	--********************************************************************** -
	--
	PROCEDURE create_location2 (
		p_location_id				IN VARCHAR2,
		p_location_type			IN VARCHAR2 DEFAULT NULL,
		p_elevation 				IN NUMBER DEFAULT NULL,
		p_elev_unit_id 			IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum			IN VARCHAR2 DEFAULT NULL,
		p_latitude					IN NUMBER DEFAULT NULL,
		p_longitude 				IN NUMBER DEFAULT NULL,
		p_horizontal_datum		IN VARCHAR2 DEFAULT NULL,
		p_public_name				IN VARCHAR2 DEFAULT NULL,
		p_long_name 				IN VARCHAR2 DEFAULT NULL,
		p_description				IN VARCHAR2 DEFAULT NULL,
		p_time_zone_id 			IN VARCHAR2 DEFAULT NULL,
		p_county_name				IN VARCHAR2 DEFAULT NULL,
		p_state_initial			IN VARCHAR2 DEFAULT NULL,
		p_active 					IN VARCHAR2 DEFAULT NULL,
		p_location_kind_id		IN VARCHAR2 DEFAULT NULL,
		p_map_label 				IN VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN NUMBER DEFAULT NULL,
		p_published_longitude	IN NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_base_location_id	  at_base_location.base_location_id%TYPE
										  := cwms_util.get_base_id (p_location_id);
		--
		l_sub_location_id 	  at_physical_location.sub_location_id%TYPE
										  := cwms_util.get_sub_id (p_location_id);
		--
		l_db_office_id 		  cwms_office.office_id%TYPE;
		l_db_office_code		  cwms_office.office_code%TYPE;
		l_base_location_code   at_base_location.base_location_code%TYPE;
		l_location_code		  at_physical_location.location_code%TYPE;
		l_base_loc_exists 	  BOOLEAN;
		l_loc_exists			  BOOLEAN := FALSE;
		--
		l_location_type		  at_physical_location.location_type%TYPE;
		l_elevation 			  at_physical_location.elevation%TYPE := NULL;
		l_vertical_datum		  at_physical_location.vertical_datum%TYPE;
		l_latitude				  at_physical_location.latitude%TYPE := NULL;
		l_longitude 			  at_physical_location.longitude%TYPE := NULL;
		l_horizontal_datum	  at_physical_location.horizontal_datum%TYPE;
		l_public_name			  at_physical_location.public_name%TYPE;
		l_long_name 			  at_physical_location.long_name%TYPE;
		l_description			  at_physical_location.description%TYPE;
		l_time_zone_code		  at_physical_location.time_zone_code%TYPE := NULL;
		l_county_code			  cwms_county.county_code%TYPE := NULL;
		l_active_flag			  at_physical_location.active_flag%TYPE;
		--
		l_ret 					  NUMBER;
		l_hashcode				  NUMBER;
	--
	BEGIN
		--
		--------------------------------------------------------
		-- Set office_id...
		--------------------------------------------------------
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		DBMS_APPLICATION_INFO.set_module ('create_location2', 'get office code');
		--------------------------------------------------------
		-- Get the office_code...
		--------------------------------------------------------
		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		--.
		-- Check if a Base Location already exists for this p_location_id...
		BEGIN
			SELECT	base_location_code, base_location_id
			  INTO	l_base_location_code, l_base_location_id
			  FROM	at_base_location abl
			 WHERE	UPPER (abl.base_location_id) = l_base_location_id
						AND abl.db_office_code = l_db_office_code;

			l_base_loc_exists := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_base_loc_exists := FALSE;
			WHEN OTHERS
			THEN
				RAISE;
		END;

		--.
		-- If Base Location exists, check if Sub Location already exists...
		IF l_base_loc_exists
		THEN
			BEGIN
				l_location_code :=
					get_location_code (l_db_office_id, p_location_id);
				--.
				l_loc_exists := TRUE;
			EXCEPTION
				WHEN OTHERS 		  -- location_code does not exist so continue...
				THEN
					NULL;
			END;
		END IF;

		IF l_loc_exists
		THEN
			cwms_err.raise ('LOCATION_ID_ALREADY_EXISTS',
								 'cwms_loc',
								 l_db_office_id || ':' || p_location_id
								);
		END IF;  
      
      check_alias_id(p_location_id, p_location_id, null, null, l_db_office_id);

		----------------------------------------------------------
		----------------------------------------------------------
		-- Perform validation checks on newly passed parameters...
		---------.
		---------.
		-- location_type...
		--.
		l_location_type := p_location_type;

		---------.
		---------.
		-- Convert any new elvation to the correct DB units...
		--.
		IF p_elevation IS NOT NULL
		THEN
			l_elevation :=
				convert_from_to (p_elevation,
									  p_elev_unit_id,
									  l_elev_db_unit,
									  l_abstract_elev_param
									 );
		END IF;

		---------.
		---------.
		-- vertical datum...
		--
		l_vertical_datum := p_vertical_datum;

		---------.
		---------.
		-- latitude...
		--
		IF p_latitude IS NOT NULL
		THEN
			IF ABS (p_latitude) > 90
			THEN
				raise_application_error (
					-20219,
						'INVALID Latitude value: '
					|| p_latitude
					|| ' - must be between -90 and +90',
					TRUE
				);
			END IF;

			l_latitude := p_latitude;
		END IF;

		---------.
		---------.
		-- longitude...
		--
		IF p_longitude IS NOT NULL
		THEN
			IF ABS (p_longitude) > 180
			THEN
				raise_application_error (
					-20218,
						'INVALID Longitude value: '
					|| p_longitude
					|| ' - must be between -180 and +180',
					TRUE
				);
			END IF;

			l_longitude := p_longitude;
		END IF;

		---------.
		---------.
		--  horizontal datum...
		--
		l_horizontal_datum := p_horizontal_datum;
		---------.
		---------.
		-- public_name...
		--
		l_public_name := p_public_name;
		---------.
		---------.
		-- long_name...
		--
		l_long_name := p_long_name;
		---------.
		---------.
		-- description...
		--
		l_description := p_description;

		---------.
		---------.
		-- time_zone...
		--
		IF p_time_zone_id IS NOT NULL
		THEN
			l_time_zone_code := get_timezone_code (p_time_zone_id);
		END IF;

		---------.
		---------.
		-- Check and Update he State/County pair...
		--
		IF p_state_initial IS NULL AND p_county_name IS NOT NULL
		THEN			-- Throw exception - if a county name is passed in one must.
			-- also pass-in the county's state initials.
			cwms_err.raise ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
		ELSIF p_state_initial IS NOT NULL
		THEN										 -- Find the corresponding county_code.
			l_county_code := get_county_code (p_county_name, p_state_initial);
		END IF;

		---------.
		---------.
		-- Update active_flag.
		--.
		IF p_active IS NOT NULL
		THEN
			IF cwms_util.is_true (p_active)
			THEN
				l_active_flag := 'T';
			ELSIF cwms_util.is_false (p_active)
			THEN
				l_active_flag := 'F';
			ELSE
				cwms_err.raise ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
			END IF;
		ELSE
			l_active_flag := 'T';
		END IF;

		---------.
		---------.
		-- Create new base and sub locations in database...
		--.
		--.
		create_location_raw2 (l_base_location_code,
									 l_location_code,
									 l_base_location_id,
									 l_sub_location_id,
									 l_db_office_code,
									 l_location_type,
									 l_elevation,
									 l_vertical_datum,
									 l_latitude,
									 l_longitude,
									 l_horizontal_datum,
									 l_public_name,
									 l_long_name,
									 l_description,
									 l_time_zone_code,
									 l_county_code,
									 l_active_flag,
									 p_location_kind_id,
									 p_map_label,
									 p_published_latitude,
									 p_published_longitude,
									 p_bounding_office_id,
									 p_nation_id,
									 p_nearest_city,
									 p_db_office_id
									);
	--
	END create_location2;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- CREATE_LOCATION -
	--
	--*---------------------------------------------------------------------*-
	--
	-- Replaces insert_loc in the 2.0 api -
	--
	--*---------------------------------------------------------------------*-
	--

	PROCEDURE create_location (p_location_id			IN VARCHAR2,
										p_location_type		IN VARCHAR2 DEFAULT NULL,
										p_elevation 			IN NUMBER DEFAULT NULL,
										p_elev_unit_id 		IN VARCHAR2 DEFAULT NULL,
										p_vertical_datum		IN VARCHAR2 DEFAULT NULL,
										p_latitude				IN NUMBER DEFAULT NULL,
										p_longitude 			IN NUMBER DEFAULT NULL,
										p_horizontal_datum	IN VARCHAR2 DEFAULT NULL,
										p_public_name			IN VARCHAR2 DEFAULT NULL,
										p_long_name 			IN VARCHAR2 DEFAULT NULL,
										p_description			IN VARCHAR2 DEFAULT NULL,
										p_time_zone_id 		IN VARCHAR2 DEFAULT NULL,
										p_county_name			IN VARCHAR2 DEFAULT NULL,
										p_state_initial		IN VARCHAR2 DEFAULT NULL,
										p_active 				IN VARCHAR2 DEFAULT NULL,
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  )
	IS
	BEGIN
		create_location2 (p_location_id				=> p_location_id,
								p_location_type			=> p_location_type,
								p_elevation 				=> p_elevation,
								p_elev_unit_id 			=> p_elev_unit_id,
								p_vertical_datum			=> p_vertical_datum,
								p_latitude					=> p_latitude,
								p_longitude 				=> p_longitude,
								p_horizontal_datum		=> p_horizontal_datum,
								p_public_name				=> p_public_name,
								p_long_name 				=> p_long_name,
								p_description				=> p_description,
								p_time_zone_id 			=> p_time_zone_id,
								p_county_name				=> p_county_name,
								p_state_initial			=> p_state_initial,
								p_active 					=> p_active,
								p_location_kind_id		=> NULL,
								p_map_label 				=> NULL,
								p_published_latitude 	=> NULL,
								p_published_longitude	=> NULL,
								p_bounding_office_id 	=> NULL,
								p_nation_id 				=> NULL,
								p_nearest_city 			=> NULL,
								p_db_office_id 			=> p_db_office_id
							  );
	END create_location;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- RENAME_LOC -
	--
	--*---------------------------------------------------------------------*-
	--
	-- This is the v1.4 api call - ported for backward compatibility.
	--
	--*---------------------------------------------------------------------*-
	---
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv...
	PROCEDURE rename_loc (p_officeid 			IN VARCHAR2,
								 p_base_loc_id_old	IN VARCHAR2,
								 p_base_loc_id_new	IN VARCHAR2
								)
	IS
	BEGIN
		rename_location (p_base_loc_id_old, p_base_loc_id_new, p_officeid);
	END rename_loc;

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	---
	--
	--********************************************************************** -
	--********************************************************************** -
	--
	-- RENAME_LOCATION -
	--
	--*---------------------------------------------------------------------*-
	--
	-- Version 2.0 rename_location...
	--
	--*---------------------------------------------------------------------*-
	PROCEDURE rename_location (p_location_id_old   IN VARCHAR2,
										p_location_id_new   IN VARCHAR2,
										p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
									  )
	IS
		l_location_id_old 			VARCHAR2 (49) := TRIM (p_location_id_old);
		l_location_id_new 			VARCHAR2 (49) := TRIM (p_location_id_new);
		l_base_location_id_old		at_base_location.base_location_id%TYPE
			:= cwms_util.get_base_id (l_location_id_old);
		--
		l_sub_location_id_old		at_physical_location.sub_location_id%TYPE
												:= cwms_util.get_sub_id (l_location_id_old);
		--
		l_base_location_id_new		at_base_location.base_location_id%TYPE
			:= cwms_util.get_base_id (l_location_id_new);
		--
		l_sub_location_id_new		at_physical_location.sub_location_id%TYPE
												:= cwms_util.get_sub_id (l_location_id_new);
		--
		-- l_db_office_code cwms_office.office_code%TYPE;
		l_base_location_code_old	at_base_location.base_location_code%TYPE;
		l_base_location_code_new	at_base_location.base_location_code%TYPE;
		l_location_code_old			at_physical_location.location_code%TYPE;
		l_location_code_new			at_physical_location.location_code%TYPE;
		--
		l_base_location_id_exist	at_base_location.base_location_id%TYPE;
		l_sub_location_id_exist 	at_physical_location.sub_location_id%TYPE
												:= NULL;
		--
		l_old_loc_is_base_loc		BOOLEAN := FALSE;
		l_base_id_case_change		BOOLEAN := FALSE;
		l_sub_id_case_change 		BOOLEAN := FALSE;
		l_id_case_change				BOOLEAN := FALSE;
		--
		l_location_type				at_physical_location.location_type%TYPE;
		l_elevation 					at_physical_location.elevation%TYPE := NULL;
		l_vertical_datum				at_physical_location.vertical_datum%TYPE;
		l_latitude						at_physical_location.latitude%TYPE := NULL;
		l_longitude 					at_physical_location.longitude%TYPE := NULL;
		l_horizontal_datum			at_physical_location.horizontal_datum%TYPE;
		l_public_name					at_physical_location.public_name%TYPE;
		l_long_name 					at_physical_location.long_name%TYPE;
		l_description					at_physical_location.description%TYPE;
		l_time_zone_code				at_physical_location.time_zone_code%TYPE
												:= NULL;
		l_county_code					cwms_county.county_code%TYPE := NULL;
		l_active_flag					at_physical_location.active_flag%TYPE;
		l_location_kind				at_physical_location.location_kind%TYPE
												:= NULL;
		l_map_label 					at_physical_location.map_label%TYPE := NULL;
		l_published_latitude 		at_physical_location.published_latitude%TYPE
												:= NULL;
		l_published_longitude		at_physical_location.published_longitude%TYPE
			:= NULL;
		l_office_code					at_physical_location.office_code%TYPE
												:= NULL;
		l_nation_code					at_physical_location.nation_code%TYPE
												:= NULL;
		l_nearest_city 				at_physical_location.nearest_city%TYPE
												:= NULL;
		l_db_office_id 				VARCHAR2 (16)
			:= cwms_util.get_db_office_id (p_db_office_id);
		l_db_office_code				cwms_office.office_code%TYPE
			:= cwms_util.get_db_office_code (l_db_office_id);
	BEGIN
		---------.
		---------.
		--.
		--  New location can not already exist...
		BEGIN
			l_location_code_new :=
				get_location_code (l_db_office_id, l_location_id_new);
		EXCEPTION
			WHEN OTHERS
			THEN
				-- The get_location_code call should throw an exception becasue --
				-- the new location shouldn't exist.
				l_location_code_new := NULL;
		END;

		IF l_location_code_new IS NOT NULL
		THEN
			IF UPPER (l_location_id_old) != UPPER (l_location_id_new)
			THEN
				-- If l_location_code_new is found then the new location --
				-- already exists - so throw an exception...
				cwms_err.raise ('RENAME_LOC_BASE_2', p_location_id_new);
			END IF;
		END IF;

		---------.
		---------.
		--.
		-- retrieve existing base_location_code...
		--.
		BEGIN
			SELECT	base_location_code, base_location_id
			  INTO	l_base_location_code_old, l_base_location_id_exist
			  FROM	at_base_location abl
			 WHERE	UPPER (abl.base_location_id) =
							UPPER (l_base_location_id_old)
						AND abl.db_office_code = l_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('LOCATION_ID_NOT_FOUND',
									 'rename_location',
									 p_location_id_old
									);
		END;

		---------.
		---------.
		--.
		-- retrieve existing location data...
		--.
		IF l_sub_location_id_old IS NULL  -- A BASE Location is being renamed --
		THEN
			SELECT	location_code, time_zone_code, county_code, location_type,
						elevation, vertical_datum, longitude, latitude,
						horizontal_datum, public_name, long_name, description,
						active_flag, location_kind, map_label, published_latitude,
						published_longitude, office_code, nation_code, nearest_city
			  INTO	l_location_code_old, l_time_zone_code, l_county_code,
						l_location_type, l_elevation, l_vertical_datum, l_longitude,
						l_latitude, l_horizontal_datum, l_public_name, l_long_name,
						l_description, l_active_flag, l_location_kind, l_map_label,
						l_published_latitude, l_published_longitude, l_office_code,
						l_nation_code, l_nearest_city
			  FROM	at_physical_location apl
			 WHERE	apl.base_location_code = l_base_location_code_old
						AND apl.sub_location_id IS NULL;

			--
			l_old_loc_is_base_loc := TRUE;
		ELSE														-- For BASE-SUB Locations -
			BEGIN
				SELECT	location_code, sub_location_id, time_zone_code,
							county_code, location_type, elevation, vertical_datum,
							longitude, latitude, horizontal_datum, public_name,
							long_name, description, active_flag, location_kind,
							map_label, published_latitude, published_longitude,
							office_code, nation_code, nearest_city
				  INTO	l_location_code_old, l_sub_location_id_exist,
							l_time_zone_code, l_county_code, l_location_type,
							l_elevation, l_vertical_datum, l_longitude, l_latitude,
							l_horizontal_datum, l_public_name, l_long_name,
							l_description, l_active_flag, l_location_kind,
							l_map_label, l_published_latitude, l_published_longitude,
							l_office_code, l_nation_code, l_nearest_city
				  FROM	at_physical_location apl
				 WHERE	apl.base_location_code = l_base_location_code_old
							AND UPPER (apl.sub_location_id) =
									 UPPER (l_sub_location_id_old);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('LOCATION_ID_NOT_FOUND',
										 'rename_location',
										 p_location_id_old
										);
			END;
		END IF;

		---------.
		---------.
		--.
		-- Confirm that the new location id is valid...
		--.
		-- CHECK #1 - If old name is a base location, then new.
		-- name must also be a base location...
		--.
		IF l_old_loc_is_base_loc AND l_sub_location_id_new IS NOT NULL
		THEN
			cwms_err.raise ('RENAME_LOC_BASE_1',
								 p_location_id_old,
								 p_location_id_new
								);
		END IF;

		--.
		-- CHECK #2 - The new location can not already exist...
		--.
		-- first check if this is a simple upper/lower case change rename -
		--.
		IF UPPER (l_location_id_new) = UPPER (l_location_id_old)
		THEN
			-- if old = new then find if base or sub or both have case changes -
			--.
			IF l_base_location_id_exist <> l_base_location_id_new
			THEN
				l_base_id_case_change := TRUE;
			END IF;

			--.
			IF l_sub_location_id_old IS NOT NULL
			THEN
				IF l_sub_location_id_exist <> l_sub_location_id_new
				THEN
					l_sub_id_case_change := TRUE;
				END IF;
			END IF;

			--.
			IF l_base_id_case_change OR l_sub_id_case_change
			THEN
				l_id_case_change := TRUE;
			ELSE
				cwms_err.raise ('RENAME_LOC_BASE_3', l_location_id_new);
			END IF;
		END IF;

		---------.
		---------.
		--.
		-- RENAME the location...
		--.
		CASE
			WHEN l_old_loc_is_base_loc
			THEN												  -- Simple Base Loc Rename --
				UPDATE	at_base_location abl
					SET	base_location_id = l_base_location_id_new
				 WHERE	abl.base_location_code = l_base_location_code_old;
			--
			WHEN l_sub_location_id_new IS NULL
			THEN									  -- Old Loc renamed to new Base Loc --
				--.
				-- 1) create a new Base Location with the new Base_Location_ID -
				--.
				INSERT
					  INTO	at_base_location (base_location_code,
														db_office_code,
														base_location_id,
														active_flag
													  )
					VALUES	(
									cwms_seq.NEXTVAL,
									l_db_office_code,
									l_base_location_id_new,
									l_active_flag
								)
				RETURNING	base_location_code
					  INTO	l_base_location_code_new;

				--.
				-- 2) update the old location by:
				--   a) updating its Base Location Code with the newly generated --
				--   Base_Location_Code, --
				--   b) setting the sub_location_id to null --
				--.
				UPDATE	at_physical_location apl
					SET	base_location_code = l_base_location_code_new,
							sub_location_id = NULL
				 WHERE	apl.location_code = l_location_code_old;
			ELSE
				IF UPPER (l_base_location_id_old) =
						UPPER (l_base_location_id_new)
				THEN					  -- Simple rename of Base and/or Sub Loc IDs --
					IF l_base_id_case_change
					THEN
						UPDATE	at_base_location abl
							SET	base_location_id = l_base_location_id_new
						 WHERE	abl.base_location_code = l_base_location_code_old;
					END IF;

					--
					UPDATE	at_physical_location apl
						SET	sub_location_id = l_sub_location_id_new
					 WHERE	apl.location_code = l_location_code_old;
				ELSE			  -- rename to a new Base Loc requires new Base Loc --
					--.
					--
					-- 1) create a new Base Location with the new Base Location_name -
					--.
					create_location_raw2 (l_base_location_code_new,
												 l_location_code_new,
												 l_base_location_id_new,
												 NULL,
												 l_db_office_code,
												 l_location_type,
												 l_elevation,
												 l_vertical_datum,
												 l_latitude,
												 l_longitude,
												 l_horizontal_datum,
												 l_public_name,
												 l_long_name,
												 l_description,
												 l_time_zone_code,
												 l_county_code,
												 l_active_flag,
												 l_location_kind,
												 l_map_label,
												 l_published_latitude,
												 l_published_longitude,
												 l_office_code,
												 l_nation_code,
												 l_nearest_city
												);

					--.
					-- 2) update the old location by:
					--   a) updating its Base Location Code with the newly generated --
					--   Base_Location_Code, --
					--   b) setting the sub_location_id to the new sub_location_id --
					--.
					UPDATE	at_physical_location apl
						SET	base_location_code = l_base_location_code_new,
								sub_location_id = l_sub_location_id_new
					 WHERE	apl.location_code = l_location_code_old;
				END IF;
		END CASE;

		COMMIT;
	--
	END rename_location;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- DELETE_LOC -
	--
	--*---------------------------------------------------------------------*-
	--
	-- This is the v1.4 api call - ported for backward compatibility.
	--
	--*---------------------------------------------------------------------*-
	--
	--
	---
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	PROCEDURE delete_loc (p_officeid IN VARCHAR2, p_base_loc_id IN VARCHAR2)
	IS
	BEGIN
		delete_location (p_base_loc_id, p_officeid);
	END delete_loc;

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
	---
	--
	--********************************************************************** -
	--********************************************************************** -
	--
	-- DELETE_LOCATION -
	--
	--*---------------------------------------------------------------------*-
	--
	-- This delete is the new version 2.0 delete_location. It will only -
	-- delete locations if there are no timeseries identifiers associated -
	-- with the location to be deleted. -
	--
	-- NOTE: Deleting a Base Location will delete ALL associated Sub -
	-- Locations -
	-- valid p_delete_actions:
	--   --
	--  delete_loc:  This action will delete the location_id only if there
	--  are no cwms_ts_id's associated with this location_id.
	--  If there are cwms_ts_id's assciated with the location_id,
	--  then an exception is thrown.
	--  delete_ts_data: This action will delete all of the data associated
	--  with all of the cwms_ts_id's associated with this
	--  location_id. The location_id and the cwms_ts_id's
	--  themselves are not deleted.
	--  delete_ts_id:   This action will delete any cwms_ts_id that has
	--  no associated data. Only ts_id's that have data
	--  along with the location_id itself will remain.
	--  delete_ts_cascade: This action will delete all data and all cwms_ts_id's
	--  associazted with this location_id. It does not delete
	--  the location_id.
	--  delete_loc_cascade: This will delete all data, all cwms_ts_id's, as well
	--  as the location_id itself.

	--
	--*---------------------------------------------------------------------*-
	PROCEDURE delete_location (
		p_location_id		IN VARCHAR2,
		p_delete_action	IN VARCHAR2 DEFAULT cwms_util.delete_loc,
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_count					  NUMBER;
		l_base_location_id	  at_base_location.base_location_id%TYPE;
		--
		l_sub_location_id 	  at_physical_location.sub_location_id%TYPE;
		--
		l_base_location_code   NUMBER;
		l_location_code		  NUMBER;
		l_db_office_code		  NUMBER;
		--l_db_office_id VARCHAR2 (16);
		l_delete_action		  VARCHAR2 (22);
		l_cursor 				  SYS_REFCURSOR;
		l_this_is_a_base_loc   BOOLEAN := FALSE;
		--
		l_count_ts				  NUMBER := 0;
		l_cwms_ts_id			  VARCHAR2 (183);
		l_ts_code				  NUMBER;
		--
		l_location_codes		  number_tab_t;
		l_location_ids 		  str_tab_t;
	--
	BEGIN
		-------------------
		-- sanity checks --
		-------------------
		IF p_location_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'Location identifier must not be null.');
		END IF;

		IF p_delete_action IS NULL
		THEN
			cwms_err.raise ('ERROR', 'Delete action must not be null.');
		END IF;

		l_delete_action :=
			NVL (UPPER (TRIM (p_delete_action)), cwms_util.delete_loc);

		IF l_delete_action NOT IN
				(cwms_util.delete_key,									-- delete loc only
				 cwms_util.delete_data, 					-- delete all children only
				 cwms_util.delete_all,					-- delete loc and all children
				 cwms_util.delete_loc,									-- delete loc only
				 cwms_util.delete_loc_cascade,		-- delete loc and all children
				 cwms_util.delete_ts_id,					-- delete child ts ids only
				 cwms_util.delete_ts_data, 			  -- delete child ts data only
				 cwms_util.delete_ts_cascade	-- delete child ts data and ids only
													 )
		THEN
			cwms_err.raise ('INVALID_DELETE_ACTION', p_delete_action);
		END IF;

		l_base_location_id := cwms_util.get_base_id (p_location_id);
		l_sub_location_id := cwms_util.get_sub_id (p_location_id);
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);

		-- You can only delete a location if that location does not have
		-- any child records.
		BEGIN
			SELECT	base_location_code
			  INTO	l_base_location_code
			  FROM	at_base_location abl
			 WHERE	UPPER (abl.base_location_id) = UPPER (l_base_location_id)
						AND abl.db_office_code = l_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('LOCATION_ID_NOT_FOUND', p_location_id);
		END;

		l_location_code := get_location_code (p_db_office_id, p_location_id);

		--
		IF l_sub_location_id IS NULL
		THEN
			l_this_is_a_base_loc := TRUE;
		END IF;

		----------------------------------------------------------------
		-- Handle the times series separately since there are special --
		-- delete actions just for time series  --
		----------------------------------------------------------------
		IF l_this_is_a_base_loc
		THEN
			OPEN l_cursor FOR
				SELECT	cwms_ts_id
				  FROM	at_cwms_ts_id
				 WHERE	base_location_code = l_base_location_code;
		ELSE
			OPEN l_cursor FOR
				SELECT	cwms_ts_id
				  FROM	at_cwms_ts_id
				 WHERE	location_code = l_location_code;
		END IF;

		LOOP
			FETCH l_cursor
			INTO l_cwms_ts_id;

			EXIT WHEN l_cursor%NOTFOUND;

			IF l_delete_action IN (cwms_util.delete_key, cwms_util.delete_loc)
			THEN
				CLOSE l_cursor;

				cwms_err.raise ('CAN_NOT_DELETE_LOC_1', p_location_id);
			END IF;

			CASE
				WHEN l_delete_action IN
						  (cwms_util.delete_data,
							cwms_util.delete_all,
							cwms_util.delete_loc_cascade,
							cwms_util.delete_ts_cascade)
				THEN
					cwms_ts.delete_ts (l_cwms_ts_id,
											 cwms_util.delete_ts_cascade,
											 l_db_office_code
											);
				WHEN l_delete_action = cwms_util.delete_ts_id
				THEN
					BEGIN
						cwms_ts.delete_ts (l_cwms_ts_id,
												 cwms_util.delete_ts_id,
												 l_db_office_code
												);
					EXCEPTION
						WHEN OTHERS
						THEN
							NULL; 				 -- exception thrown if ts_id has data.
					END;
				WHEN l_delete_action = cwms_util.delete_ts_data
				THEN
					cwms_ts.delete_ts (l_cwms_ts_id,
											 cwms_util.delete_ts_data,
											 l_db_office_code
											);
				ELSE
					cwms_err.raise ('INVALID_DELETE_ACTION', p_delete_action);
			END CASE;

			--
			l_count_ts := l_count_ts + 1;
		END LOOP;

		--
		CLOSE l_cursor;

		---------------------------------------------
		-- delete other child records if specified --
		---------------------------------------------
		IF l_delete_action IN
				(cwms_util.delete_data,
				 cwms_util.delete_all,
				 cwms_util.delete_loc_cascade)
		THEN
			IF l_this_is_a_base_loc
			THEN -- Deleting Base Location ----------------------------------------
				----------------------------------------------------------------
				-- collect all location ids and codes with this base location --
				----------------------------------------------------------------
				SELECT	location_code,
							p_location_id || SUBSTR ('-', LENGTH (sub_location_id)) || sub_location_id
				  BULK	COLLECT INTO l_location_codes, l_location_ids
				  FROM	at_physical_location
				 WHERE	base_location_code = l_base_location_code;
                
            -----------------------
            -- group assignments --
            -----------------------
            delete 
              from at_loc_group_assignment 
             where location_code in (select * from table(l_location_codes))
                or loc_ref_code in (select * from table(l_location_codes));
             
				------------
				-- basins --
				------------
				UPDATE	at_basin
					SET	parent_basin_code = NULL
				 WHERE	parent_basin_code IN (SELECT	 *
															FROM	 TABLE (l_location_codes));

				UPDATE	at_basin
					SET	primary_stream_code = NULL
				 WHERE	primary_stream_code IN (SELECT	*
															  FROM	TABLE (l_location_codes
																				));

				DELETE FROM   at_basin
						WHERE   basin_location_code IN (SELECT   *
																	 FROM   TABLE (
																				  l_location_codes
																			  ));

				-------------
				-- streams --
				-------------
				UPDATE	at_stream
					SET	diverting_stream_code = NULL
				 WHERE	diverting_stream_code IN (SELECT   *
																 FROM   TABLE (
																			  l_location_codes
																		  ));

				UPDATE	at_stream
					SET	receiving_stream_code = NULL
				 WHERE	receiving_stream_code IN (SELECT   *
																 FROM   TABLE (
																			  l_location_codes
																		  ));

				DELETE FROM   at_stream_reach
						WHERE   stream_location_code IN (SELECT	*
																	  FROM	TABLE (
																					l_location_codes
																				));

				DELETE FROM   at_stream_location
						WHERE   stream_location_code IN (SELECT	*
																	  FROM	TABLE (
																					l_location_codes
																				))
								  OR location_code IN (SELECT   *
																 FROM   TABLE (
																			  l_location_codes
																		  ));

				DELETE FROM   at_stream
						WHERE   stream_location_code IN (SELECT	*
																	  FROM	TABLE (
																					l_location_codes
																				));

				-----------
				-- gages --
				-----------
				DELETE FROM   at_gage_sensor
						WHERE   gage_code IN
									  (SELECT	gage_code
										  FROM	at_gage
										 WHERE	gage_location_code IN (SELECT   *
																					 FROM   TABLE (
																								  l_location_codes
																							  )));

				DELETE FROM   at_goes
						WHERE   gage_code IN
									  (SELECT	gage_code
										  FROM	at_gage
										 WHERE	gage_location_code IN (SELECT   *
																					 FROM   TABLE (
																								  l_location_codes
																							  )));

				DELETE FROM   at_gage
						WHERE   gage_location_code IN (SELECT	 *
																	FROM	 TABLE (
																				 l_location_codes
																			 ));

				---------------
				-- documents --
				---------------
				DELETE FROM   at_document
						WHERE   document_location_code IN (SELECT   *
																		 FROM   TABLE (
																					  l_location_codes
																				  ));

				--------------------------
				-- geographic locations --
				--------------------------
				DELETE FROM   at_geographic_location
						WHERE   location_code IN
									  (SELECT	*
										  FROM	TABLE (l_location_codes));

				-----------
				-- urls --
				-----------
				DELETE FROM   at_location_url
						WHERE   location_code IN
									  (SELECT	*
										  FROM	TABLE (l_location_codes));

				-------------------
				-- display scale --
				-------------------
				DELETE FROM   at_display_scale
						WHERE   location_code IN
									  (SELECT	*
										  FROM	TABLE (l_location_codes));

				---------------
				-- forecasts --
				---------------
				DELETE FROM   at_forecast_spec
						WHERE   target_location_code IN (SELECT	*
																	  FROM	TABLE (
																					l_location_codes
																				))
								  OR source_location_code IN (SELECT	*
																		  FROM	TABLE (
																						l_location_codes
																					));

				--------------
				-- projects --
				--------------
				FOR i IN 1 .. l_location_codes.COUNT
				LOOP
					FOR rec
						IN 								 -- will match only 0 or 1 record
							(SELECT	 project_location_code
								FROM	 at_project
							  WHERE	 project_location_code = l_location_codes (i))
					LOOP
						cwms_project.delete_project (l_location_ids (i),
															  cwms_util.delete_all,
															  p_db_office_id
															 );
					END LOOP;
				END LOOP;

				-------------
				-- ratings --
				-------------
				FOR i IN 1 .. l_location_ids.COUNT
				LOOP
					cwms_rating.delete_specs (l_location_ids (i) || '.*',
													  cwms_util.delete_all,
													  p_db_office_id
													 );
				END LOOP;

				---------------------
				-- location levels --
				---------------------
				FOR i IN 1 .. l_location_ids.COUNT
				LOOP
					FOR rec
						IN (SELECT	 DISTINCT office_id, location_level_id,
													 level_date, attribute_id,
													 attribute_value, attribute_unit
                        FROM	 cwms_v_location_level
							  WHERE	 office_id =
											 NVL (UPPER (TRIM (p_db_office_id)),
													cwms_util.user_office_id
												  )
										 AND location_level_id LIKE
												  l_location_ids (i) || '.%'
										 AND unit_system = 'SI')
					LOOP
						cwms_level.delete_location_level_ex (rec.location_level_id,
																		 rec.level_date,
																		 'UTC',
																		 rec.attribute_id,
																		 rec.attribute_value,
																		 rec.attribute_unit,
																		 'T',
																		 'T',
																		 rec.office_id
																		);
					END LOOP;
				END LOOP;
			ELSE -- Deleting a single Sub Location --------------------------------
            -----------------------
            -- group assignments --
            -----------------------
            delete 
              from at_loc_group_assignment 
             where location_code = l_location_code
                or loc_ref_code = l_location_code;
            
   			------------
				-- basins --
				------------
				UPDATE	at_basin
					SET	parent_basin_code = NULL
				 WHERE	parent_basin_code = l_location_code;

				UPDATE	at_basin
					SET	primary_stream_code = NULL
				 WHERE	primary_stream_code = l_location_code;

				DELETE FROM   at_basin
						WHERE   basin_location_code = l_location_code;

				-------------
				-- streams --
				-------------
				UPDATE	at_stream
					SET	diverting_stream_code = NULL
				 WHERE	diverting_stream_code = l_location_code;

				UPDATE	at_stream
					SET	receiving_stream_code = NULL
				 WHERE	receiving_stream_code = l_location_code;

				DELETE FROM   at_stream_reach
						WHERE   stream_location_code = l_location_code;

				DELETE FROM   at_stream_location
						WHERE   stream_location_code = l_location_code
								  OR location_code = l_location_code;

				DELETE FROM   at_stream
						WHERE   stream_location_code = l_location_code;

				-----------
				-- gages --
				-----------
				DELETE FROM   at_gage_sensor
						WHERE   gage_code IN
									  (SELECT	gage_code
										  FROM	at_gage
										 WHERE	gage_location_code = l_location_code);

				DELETE FROM   at_goes
						WHERE   gage_code IN
									  (SELECT	gage_code
										  FROM	at_gage
										 WHERE	gage_location_code = l_location_code);

				DELETE FROM   at_gage
						WHERE   gage_location_code = l_location_code;

				---------------
				-- documents --
				---------------
				DELETE FROM   at_document
						WHERE   document_location_code = l_location_code;

				--------------------------
				-- geographic locations --
				--------------------------
				DELETE FROM   at_geographic_location
						WHERE   location_code = l_location_code;

				-----------
				-- urls --
				-----------
				DELETE FROM   at_location_url
						WHERE   location_code = l_location_code;

				-------------------
				-- display scale --
				-------------------
				DELETE FROM   at_display_scale
						WHERE   location_code = l_location_code;

				---------------
				-- forecasts --
				---------------
				DELETE FROM   at_forecast_spec
						WHERE   target_location_code = l_location_code
								  OR source_location_code = l_location_code;

				--------------
				-- projects --
				--------------
				FOR rec IN								 -- will match only 0 or 1 record
							  (SELECT	project_location_code
								  FROM	at_project
								 WHERE	project_location_code = l_location_code)
				LOOP
					cwms_project.delete_project (p_location_id,
														  cwms_util.delete_all,
														  p_db_office_id
														 );
				END LOOP;

				-------------
				-- ratings --
				-------------
				cwms_rating.delete_specs (p_location_id || '.*',
												  cwms_util.delete_all,
												  p_db_office_id
												 );

				---------------------
				-- location levels --
				---------------------
				FOR rec
					IN (SELECT	 DISTINCT office_id, location_level_id,
												 level_date, attribute_id,
												 attribute_value, attribute_unit
							FROM	 cwms_v_location_level
						  WHERE	 office_id =
										 NVL (UPPER (TRIM (p_db_office_id)),
												cwms_util.user_office_id
											  )
									 AND location_level_id LIKE p_location_id || '.%'
									 AND unit_system = 'SI')
				LOOP
					cwms_level.delete_location_level_ex (rec.location_level_id,
																	 rec.level_date,
																	 'UTC',
																	 rec.attribute_id,
																	 rec.attribute_value,
																	 rec.attribute_unit,
																	 'T',
																	 'T',
																	 rec.office_id
																	);
				END LOOP;
			END IF;
		END IF;

		--------------------------------------------------------------
		-- finally, delete the actual location records if specified --
		--------------------------------------------------------------
		IF l_delete_action IN
				(cwms_util.delete_key,
				 cwms_util.delete_all,
				 cwms_util.delete_loc,
				 cwms_util.delete_loc_cascade)
		THEN
			IF l_this_is_a_base_loc
			THEN -- Deleting Base Location ----------------------------------------
				-----------------------
				-- group assignments --
				-----------------------
				DELETE FROM   at_loc_group_assignment atlga
						WHERE   atlga.location_code IN
									  (SELECT	location_code
										  FROM	at_physical_location apl
										 WHERE	apl.base_location_code =
														l_base_location_code);

				----------------------
				-- actual locations --
				----------------------
				DELETE FROM   at_physical_location apl
						WHERE   apl.base_location_code = l_base_location_code;

				DELETE FROM   at_base_location abl
						WHERE   abl.base_location_code = l_base_location_code;
			ELSE -- Deleting a single Sub Location --------------------------------
				-----------------------
				-- group assignments --
				-----------------------
				DELETE FROM   at_loc_group_assignment atlga
						WHERE   atlga.location_code = l_location_code;

				---------------------
				-- actual location --
				---------------------
				DELETE FROM   at_physical_location apl
						WHERE   apl.location_code = l_location_code;
			END IF;
		END IF;

		--
		COMMIT;
	--
	END delete_location;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- DELETE_LOCATION_CASCADE -
	--
	--*---------------------------------------------------------------------*-
	--
	-- This delete WILL DELETE any data associated with the location, -
	-- NO QUESTIONS ASKED -
	-- SO USE WITH CARE -
	--
	-- NOTE: Deleting a Base Location will delete ALL associated Sub -
	-- Locations Including All DATA -
	--
	--*---------------------------------------------------------------------*-
	PROCEDURE delete_location_cascade (
		p_location_id	  IN VARCHAR2,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
		delete_location (p_location_id, cwms_util.delete_all, p_db_office_id);
	END delete_location_cascade;

	--********************************************************************** -
	--********************************************************************** -
	--
	-- COPY_LOCATION -
	--
	--*---------------------------------------------------------------------*-
	PROCEDURE copy_location (p_location_id_old	IN VARCHAR2,
									 p_location_id_new	IN VARCHAR2,
									 p_active				IN VARCHAR2 DEFAULT 'T',
									 p_db_office_id		IN VARCHAR2 DEFAULT NULL
									)
	IS
	BEGIN
		NULL;
	END copy_location;

	--
	--********************************************************************** -
	--********************************************************************** -
	--
	-- STORE_ALIASES -
	--
	-- p_store_rule - Valid store rules are: -
	--  Delete Insert - This will delete all existing aliases  -
	--  and insert the new set of aliases -
	--  in your p_alias_array. This is the -
	--  Default.  -
	--  Replace All - This will update any pre-existing  -
	--  aliases and insert new ones -
	--
	-- p_ignorenulls - is only valid when the "Replace All" store rull is    -
	--   envoked.
	--   if 'T' then do not update a pre-existing value        -
	--   with a newly passed-in null value.  -
	--   if 'F' then update a pre-existing value               -
	--   with a newly passed-in null value.  -
	--*--------------------------------------------------------------------- -
	--
	--   PROCEDURE store_aliases (
	--   p_location_id  IN VARCHAR2,
	--   p_alias_array  IN alias_array,
	--   p_store_rule   IN VARCHAR2 DEFAULT 'DELETE INSERT',
	--   p_ignorenulls  IN VARCHAR2 DEFAULT 'T',
	--   p_db_office_id IN VARCHAR2 DEFAULT NULL
	--   )
	--   IS
	--   l_agency_code  NUMBER;
	--   l_office_id VARCHAR2 (16);
	--   l_office_code  NUMBER;
	--   l_location_code   NUMBER;
	--   l_array_count  NUMBER   := p_alias_array.COUNT;
	--   l_count  NUMBER  := 1;
	--   l_distinct NUMBER;
	--   l_store_rule   VARCHAR2 (16);
	--   l_alias_id VARCHAR2 (16);
	--   l_alias_public_name  VARCHAR2 (32);
	--   l_alias_long_name VARCHAR2 (80);
	--   l_insert BOOLEAN;
	--   l_ignorenulls  BOOLEAN
	--  := cwms_util.return_true_or_false (p_ignorenulls);
	--   BEGIN
	--   --
	--   IF l_count = 0
	--   THEN
	--   cwms_err.RAISE
	--  ('GENERIC_ERROR',
	--   'No viable agency/alias data passed to store_aliases.'
	--  );
	--   END IF;

	--------------------------------------------------------------------
	---- Check that passed-in aliases are do not contain duplicates...
	--------------------------------------------------------------------
	--   SELECT COUNT (*)
	--   INTO l_distinct
	--   FROM (SELECT DISTINCT UPPER (t.agency_id)
	--   FROM TABLE (CAST (p_alias_array AS alias_array)) t);

	--   --
	--   IF l_distinct != l_array_count
	--   THEN
	--   cwms_err.RAISE
	--  ('GENERIC_ERROR',
	--   'Duplicate Agency/Alias pairs are not permited. Only one Alias is permited per Agency (store_aliases).'
	--  );
	--   END IF;

	--   --
	--   -- Make sure none of the alias_id's are null
	--   --
	--   SELECT COUNT (*)
	--   INTO l_distinct
	--   FROM (SELECT t.alias_id
	--  FROM TABLE (CAST (p_alias_array AS alias_array)) t
	--   WHERE alias_id IS NULL);

	--   --
	--   IF l_distinct != 0
	--   THEN
	--   cwms_err.RAISE
	--  ('GENERIC_ERROR',
	--   'A NULL alias_id was submitted. alias_id may not be NULL. (store_aliases).'
	--  );
	--   END IF;

	--   --
	--   IF p_db_office_id IS NULL
	--   THEN
	--   l_office_id := cwms_util.user_office_id;
	--   ELSE
	--   l_office_id := UPPER (p_db_office_id);
	--   END IF;

	--   --
	--   l_office_code := get_office_code (l_office_id);
	--   l_location_code := get_location_code (l_office_id, p_location_id);

	--   --
	--   IF p_store_rule IS NULL
	--   THEN
	--   l_store_rule := cwms_util.delete_all;
	--   ELSIF UPPER (p_store_rule) = cwms_util.delete_all
	--   THEN
	--   l_store_rule := cwms_util.delete_all;
	--   ELSIF UPPER (p_store_rule) = cwms_util.replace_all
	--   THEN
	--   l_store_rule := cwms_util.replace_all;
	--   ELSE
	--   cwms_err.RAISE ('GENERIC_ERROR',
	--  p_store_rule
	--   || ' is an invalid store rule. (store_aliases)'
	--  );
	--   END IF;

	--   --
	--   IF l_store_rule = cwms_util.delete_all
	--   THEN
	--   DELETE FROM at_loc_group_assignment atlga
	--  WHERE atlga.location_code = l_location_code;

	--   --
	--   LOOP
	--  EXIT WHEN l_count > l_array_count;

	--  --
	--  BEGIN
	--   SELECT agency_code
	--   INTO l_agency_code
	--   FROM at_agency_name
	--  WHERE UPPER (agency_id) =
	--   UPPER (p_alias_array (l_count).agency_id)
	--  AND db_office_code IN
	--  (l_office_code, cwms_util.db_office_code_all);
	--  EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN
	--  --.
	--  INSERT INTO at_agency_name
	--  (agency_code,
	--   agency_id,
	--   agency_name,
	--   db_office_code
	--  )
	--   VALUES (cwms_seq.NEXTVAL,
	--   p_alias_array (l_count).agency_id,
	--   p_alias_array (l_count).agency_name,
	--   l_office_code
	--  )
	--  RETURNING agency_code
	--   INTO l_agency_code;
	--  END;

	--  --
	--  INSERT INTO at_alias_name
	--  (location_code, agency_code,
	--   alias_id,
	--   alias_public_name,
	--   alias_long_name
	--  )
	--   VALUES (l_location_code, l_agency_code,
	--   p_alias_array (l_count).alias_id,
	--   p_alias_array (l_count).alias_public_name,
	--   p_alias_array (l_count).alias_long_name
	--  );

	--  --
	--  l_count := l_count + 1;
	--   END LOOP;
	--   ELSE  -- store_rule is REPLACE ALL -
	--   LOOP
	--  EXIT WHEN l_count > l_array_count;

	--  --
	--  -- retrieve agency_code...
	--  BEGIN
	--   SELECT agency_code
	--   INTO l_agency_code
	--   FROM at_agency_name
	--  WHERE UPPER (agency_id) =
	--   UPPER (p_alias_array (l_count).agency_id)
	--  AND db_office_code IN
	--  (l_office_code, cwms_util.db_office_code_all);
	--  EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN -- No agency_code found, so create one...
	--  --.
	--  INSERT INTO at_agency_name
	--  (agency_code,
	--   agency_id,
	--   agency_name,
	--   db_office_code
	--  )
	--   VALUES (cwms_seq.NEXTVAL,
	--   p_alias_array (l_count).agency_id,
	--   p_alias_array (l_count).agency_name,
	--   l_office_code
	--  )
	--  RETURNING agency_code
	--   INTO l_agency_code;
	--  END;

	--  --
	--  --
	--  -- retrieve existing alias information...
	--  l_insert := FALSE;

	--  BEGIN
	--   SELECT alias_id, alias_public_name, alias_long_name
	--   INTO l_alias_id, l_alias_public_name, l_alias_long_name
	--   FROM at_alias_name
	--  WHERE location_code = l_location_code
	--  AND agency_code = l_agency_code;

	--   --
	--   IF p_alias_array (l_count).alias_public_name IS NULL
	--  AND NOT l_ignorenulls
	--   THEN
	--  l_alias_public_name := NULL;
	--   END IF;

	--   IF p_alias_array (l_count).alias_long_name IS NULL
	--  AND NOT l_ignorenulls
	--   THEN
	--  l_alias_long_name := NULL;
	--   END IF;
	--  EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN
	--  l_insert := TRUE;
	--  END;

	--  --
	--  IF l_insert
	--  THEN
	--   --
	--   INSERT INTO at_alias_name
	--   (location_code, agency_code,
	--  alias_id,
	--  alias_public_name,
	--  alias_long_name
	--   )
	--  VALUES (l_location_code, l_agency_code,
	--  p_alias_array (l_count).alias_id,
	--  p_alias_array (l_count).alias_public_name,
	--  p_alias_array (l_count).alias_long_name
	--   );
	--  ELSE
	--   UPDATE at_alias_name
	--  SET alias_id = p_alias_array (l_count).alias_id,
	--  alias_public_name = l_alias_public_name,
	--  alias_long_name = l_alias_long_name
	--  WHERE location_code = l_location_code
	--  AND agency_code = l_agency_code;
	--  --
	--  END IF;

	--  --
	--  l_count := l_count + 1;
	--   END LOOP;
	--   END IF;

	--   --
	--   COMMIT;
	----
	--   NULL;
	--   END store_aliases;

	--   PROCEDURE store_alias (
	--   p_location_id  IN VARCHAR2,
	--   p_agency_id IN VARCHAR2,
	--   p_alias_id IN VARCHAR2,
	--   p_agency_name  IN VARCHAR2 DEFAULT NULL,
	--   p_alias_public_name  IN VARCHAR2 DEFAULT NULL,
	--   p_alias_long_name IN VARCHAR2 DEFAULT NULL,
	--   p_ignorenulls  IN VARCHAR2 DEFAULT 'T',
	--   p_db_office_id IN VARCHAR2 DEFAULT NULL
	--   )
	--   IS
	--   l_alias_array  alias_array := alias_array ();
	--   l_store_rule   VARCHAR2 (16) := 'REPLACE ALL';
	--   BEGIN
	--   --
	--   l_alias_array.EXTEND;
	--   --
	--   l_alias_array (1) :=
	--   alias_type (p_agency_id,
	--   p_alias_id,
	--   p_agency_name,
	--   p_alias_public_name,
	--   p_alias_long_name
	--  );
	--   --
	--   store_aliases (p_location_id,
	--   l_alias_array,
	--   l_store_rule,
	--   p_ignorenulls,
	--   p_db_office_id
	--  );
	--   END store_alias;

	--********************************************************************** -

	PROCEDURE store_location2 (
		p_location_id				IN VARCHAR2,
		p_location_type			IN VARCHAR2 DEFAULT NULL,
		p_elevation 				IN NUMBER DEFAULT NULL,
		p_elev_unit_id 			IN VARCHAR2 DEFAULT NULL,
		p_vertical_datum			IN VARCHAR2 DEFAULT NULL,
		p_latitude					IN NUMBER DEFAULT NULL,
		p_longitude 				IN NUMBER DEFAULT NULL,
		p_horizontal_datum		IN VARCHAR2 DEFAULT NULL,
		p_public_name				IN VARCHAR2 DEFAULT NULL,
		p_long_name 				IN VARCHAR2 DEFAULT NULL,
		p_description				IN VARCHAR2 DEFAULT NULL,
		p_time_zone_id 			IN VARCHAR2 DEFAULT NULL,
		p_county_name				IN VARCHAR2 DEFAULT NULL,
		p_state_initial			IN VARCHAR2 DEFAULT NULL,
		p_active 					IN VARCHAR2 DEFAULT NULL,
		p_location_kind_id		IN VARCHAR2 DEFAULT NULL,
		p_map_label 				IN VARCHAR2 DEFAULT NULL,
		p_published_latitude 	IN NUMBER DEFAULT NULL,
		p_published_longitude	IN NUMBER DEFAULT NULL,
		p_bounding_office_id 	IN VARCHAR2 DEFAULT NULL,
		p_nation_id 				IN VARCHAR2 DEFAULT NULL,
		p_nearest_city 			IN VARCHAR2 DEFAULT NULL,
		p_ignorenulls				IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_cwms_code 	 NUMBER;
		l_office_id 	 VARCHAR2 (16);
		l_office_code	 NUMBER;
	BEGIN
		--
		-- check if cwms_id for this office already exists...
		BEGIN
			update_location2 (p_location_id,
									p_location_type,
									p_elevation,
									p_elev_unit_id,
									p_vertical_datum,
									p_latitude,
									p_longitude,
									p_horizontal_datum,
									p_public_name,
									p_long_name,
									p_description,
									p_time_zone_id,
									p_county_name,
									p_state_initial,
									p_active,
									p_location_kind_id,
									p_map_label,
									p_published_latitude,
									p_published_longitude,
									p_bounding_office_id,
									p_nation_id,
									p_nearest_city,
									p_ignorenulls,
									p_db_office_id
								  );
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				RAISE;
			WHEN OTHERS
			THEN												--l_cwms_code was not found...
				DBMS_OUTPUT.put_line ('entering create_location');
				create_location2 (p_location_id,
										p_location_type,
										p_elevation,
										p_elev_unit_id,
										p_vertical_datum,
										p_latitude,
										p_longitude,
										p_horizontal_datum,
										p_public_name,
										p_long_name,
										p_description,
										p_time_zone_id,
										p_county_name,
										p_state_initial,
										p_active,
										p_location_kind_id,
										p_map_label,
										p_published_latitude,
										p_published_longitude,
										p_bounding_office_id,
										p_nation_id,
										p_nearest_city,
										p_db_office_id
									  );
		END;
	--

	--  store_aliases (p_location_id,
	--   p_alias_array,
	--   'DELETE INSERT',
	--   p_ignorenulls,
	--   p_db_office_id
	--  );
	--
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			-- Consider logging the error and then re-raise
			RAISE;
	END store_location2;

	--********************************************************************** -
	--
	-- STORE_LOC provides backward compatiblity for the dbi.  It will update a
	-- location if it already exists by calling update_loc or create a new location
	-- by calling create_loc.
	--
	--*---------------------------------------------------------------------*-
	--

	PROCEDURE store_location (p_location_id		  IN VARCHAR2,
									  p_location_type 	  IN VARCHAR2 DEFAULT NULL,
									  p_elevation			  IN NUMBER DEFAULT NULL,
									  p_elev_unit_id		  IN VARCHAR2 DEFAULT NULL,
									  p_vertical_datum	  IN VARCHAR2 DEFAULT NULL,
									  p_latitude			  IN NUMBER DEFAULT NULL,
									  p_longitude			  IN NUMBER DEFAULT NULL,
									  p_horizontal_datum   IN VARCHAR2 DEFAULT NULL,
									  p_public_name		  IN VARCHAR2 DEFAULT NULL,
									  p_long_name			  IN VARCHAR2 DEFAULT NULL,
									  p_description		  IN VARCHAR2 DEFAULT NULL,
									  p_time_zone_id		  IN VARCHAR2 DEFAULT NULL,
									  p_county_name		  IN VARCHAR2 DEFAULT NULL,
									  p_state_initial 	  IN VARCHAR2 DEFAULT NULL,
									  p_active				  IN VARCHAR2 DEFAULT NULL,
									  p_ignorenulls		  IN VARCHAR2 DEFAULT 'T',
									  p_db_office_id		  IN VARCHAR2 DEFAULT NULL
									 )
	IS
	BEGIN
		--
		DBMS_OUTPUT.put_line ('entering store_location2');

		store_location2 (p_location_id		  => p_location_id,
							  p_location_type 	  => p_location_type,
							  p_elevation			  => p_elevation,
							  p_elev_unit_id		  => p_elev_unit_id,
							  p_vertical_datum	  => p_vertical_datum,
							  p_latitude			  => p_latitude,
							  p_longitude			  => p_longitude,
							  p_horizontal_datum   => p_horizontal_datum,
							  p_public_name		  => p_public_name,
							  p_long_name			  => p_long_name,
							  p_description		  => p_description,
							  p_time_zone_id		  => p_time_zone_id,
							  p_county_name		  => p_county_name,
							  p_state_initial 	  => p_state_initial,
							  p_active				  => p_active,
							  p_ignorenulls		  => p_ignorenulls,
							  p_db_office_id		  => p_db_office_id
							 );
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			-- Consider logging the error and then re-raise
			RAISE;
	END store_location;

	--
	--
	PROCEDURE retrieve_location2 (
		p_location_id				IN OUT VARCHAR2,
		p_elev_unit_id 			IN 	 VARCHAR2 DEFAULT 'm',
		p_location_type				OUT VARCHAR2,
		p_elevation 					OUT NUMBER,
		p_vertical_datum				OUT VARCHAR2,
		p_latitude						OUT NUMBER,
		p_longitude 					OUT NUMBER,
		p_horizontal_datum			OUT VARCHAR2,
		p_public_name					OUT VARCHAR2,
		p_long_name 					OUT VARCHAR2,
		p_description					OUT VARCHAR2,
		p_time_zone_id 				OUT VARCHAR2,
		p_county_name					OUT VARCHAR2,
		p_state_initial				OUT VARCHAR2,
		p_active 						OUT VARCHAR2,
		p_location_kind_id			OUT VARCHAR2,
		p_map_label 					OUT VARCHAR2,
		p_published_latitude 		OUT NUMBER,
		p_published_longitude		OUT NUMBER,
		p_bounding_office_id 		OUT VARCHAR2,
		p_nation_id 					OUT VARCHAR2,
		p_nearest_city 				OUT VARCHAR2,
		p_alias_cursor 				OUT SYS_REFCURSOR,
		p_db_office_id 			IN 	 VARCHAR2 DEFAULT NULL
	)
	IS
		l_office_id 				 VARCHAR2 (16);
		l_office_code				 NUMBER;
		l_location_code			 NUMBER;
		l_bounding_office_code	 NUMBER := NULL;
		l_nation_code				 VARCHAR (2) := NULL;
		l_cwms_office_code		 NUMBER := cwms_util.get_office_code ('CWMS');
	--
	-- l_alias_cursor   sys_refcursor;
	--
	BEGIN
		l_office_id := cwms_util.get_db_office_id (p_db_office_id);
		--
		l_office_code := cwms_util.get_db_office_code (l_office_id);
		l_location_code := get_location_code (l_office_id, p_location_id);

		--
		SELECT	al.location_id
		  INTO	p_location_id
		  FROM	av_loc al
		 WHERE	al.location_code = l_location_code AND unit_system = 'SI';

		--
		BEGIN
			SELECT	apl.location_type,
						convert_from_to (apl.elevation, 'm', p_elev_unit_id, 'Length') elev,
						apl.vertical_datum,
						apl.latitude, apl.longitude, apl.horizontal_datum,
						apl.public_name, apl.long_name, apl.description,
						ctz.time_zone_name, cc.county_name, cs.state_initial,
						apl.active_flag, alk.location_kind_id, apl.map_label,
						apl.published_latitude, apl.published_longitude,
						apl.office_code, apl.nation_code, apl.nearest_city
			  INTO	p_location_type, p_elevation, p_vertical_datum, p_latitude, p_longitude,
						p_horizontal_datum, p_public_name, p_long_name,
						p_description, p_time_zone_id, p_county_name,
						p_state_initial, p_active, p_location_kind_id, p_map_label,
						p_published_latitude, p_published_longitude,
						l_bounding_office_code, l_nation_code, p_nearest_city
			  FROM	at_physical_location apl,
						cwms_county cc,
						cwms_state cs,
						cwms_time_zone ctz,
						at_location_kind alk
			 WHERE		 NVL (apl.county_code, 0) = cc.county_code
						AND NVL (cc.state_code, 0) = cs.state_code
						AND NVL (apl.time_zone_code, 0) = ctz.time_zone_code
						AND alk.location_kind_code = apl.location_kind
						AND alk.office_code IN (l_office_code, l_cwms_office_code)
						AND apl.location_code = l_location_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				NULL;
		END;

		IF l_bounding_office_code IS NULL
		THEN
			p_bounding_office_id := NULL;
		ELSE
			SELECT	office_id
			  INTO	p_bounding_office_id
			  FROM	cwms_office
			 WHERE	office_code = l_bounding_office_code;
		END IF;

		IF l_nation_code IS NULL
		THEN
			p_nation_id := NULL;
		ELSE
			SELECT	nation_id
			  INTO	p_nation_id
			  FROM	cwms_nation
			 WHERE	nation_code = l_nation_code;
		END IF;

		--
		--   cwms_cat.cat_loc_aliases (l_alias_cursor,
		--  p_location_id,
		--  NULL,
		--  'F',
		--  l_office_id
		--   );
		cwms_cat.cat_loc_aliases (p_cwms_cat			 => p_alias_cursor,
										  p_location_id		 => p_location_id,
										  p_loc_category_id	 => NULL,
										  p_loc_group_id		 => NULL,
										  p_abbreviated		 => 'T',
										  p_db_office_id		 => l_office_id
										 );
	--
	-- p_alias_cursor := l_alias_cursor;
	--
	--
	END retrieve_location2;

	--
	--********************************************************************** -
	--********************************************************************** -
	--
	-- RETRIEVE_LOCATION provides backward compatiblity for the dbi. It will update a
	-- location if it already exists by calling update_loc or create a new location
	-- by calling create_loc.
	--
	--*---------------------------------------------------------------------*-
	--
	PROCEDURE retrieve_location (
		p_location_id			IN OUT VARCHAR2,
		p_elev_unit_id 		IN 	 VARCHAR2 DEFAULT 'm',
		p_location_type			OUT VARCHAR2,
		p_elevation 				OUT NUMBER,
		p_vertical_datum			OUT VARCHAR2,
		p_latitude					OUT NUMBER,
		p_longitude 				OUT NUMBER,
		p_horizontal_datum		OUT VARCHAR2,
		p_public_name				OUT VARCHAR2,
		p_long_name 				OUT VARCHAR2,
		p_description				OUT VARCHAR2,
		p_time_zone_id 			OUT VARCHAR2,
		p_county_name				OUT VARCHAR2,
		p_state_initial			OUT VARCHAR2,
		p_active 					OUT VARCHAR2,
		p_alias_cursor 			OUT SYS_REFCURSOR,
		p_db_office_id 		IN 	 VARCHAR2 DEFAULT NULL
	)
	IS
		l_location_kind_id		at_location_kind.location_kind_id%TYPE;
		l_map_label 				at_physical_location.map_label%TYPE;
		l_published_latitude 	at_physical_location.published_latitude%TYPE;
		l_published_longitude	at_physical_location.published_longitude%TYPE;
		l_bounding_office_id 	cwms_office.office_id%TYPE;
		l_nation_id 				cwms_nation.nation_id%TYPE;
		l_nearest_city 			at_physical_location.nearest_city%TYPE;
	BEGIN
		retrieve_location2 (p_location_id,
								  p_elev_unit_id,
								  p_location_type,
								  p_elevation,
								  p_vertical_datum,
								  p_latitude,
								  p_longitude,
								  p_horizontal_datum,
								  p_public_name,
								  p_long_name,
								  p_description,
								  p_time_zone_id,
								  p_county_name,
								  p_state_initial,
								  p_active,
								  l_location_kind_id,
								  l_map_label,
								  l_published_latitude,
								  l_published_longitude,
								  l_bounding_office_id,
								  l_nation_id,
								  l_nearest_city,
								  p_alias_cursor,
								  p_db_office_id
								 );
	END retrieve_location;


	PROCEDURE create_location_kind (p_location_kind_id   IN VARCHAR2,
											  p_description		  IN VARCHAR2
											 )
	IS
		l_office_code			INTEGER := cwms_util.user_office_code;
		l_cwms_office_code	INTEGER := cwms_util.get_office_code ('CWMS');
		l_count					INTEGER;
		l_location_kind_id	VARCHAR2 (32) := UPPER (TRIM (p_location_kind_id));
		l_description			VARCHAR2 (256) := TRIM (p_description);
	BEGIN
		SELECT	COUNT (*)
		  INTO	l_count
		  FROM	at_location_kind
		 WHERE	location_kind_id = l_location_kind_id
					AND office_code IN (l_office_code, l_cwms_office_code);

		IF l_count != 0
		THEN
			cwms_err.raise ('ITEM_ALREADY_EXISTS',
								 'Location kind',
								 l_location_kind_id
								);
		END IF;

		INSERT INTO   at_location_kind
			  VALUES   (
							  cwms_seq.NEXTVAL,
							  l_office_code,
							  l_location_kind_id,
							  l_description
						  );
	END create_location_kind;

	PROCEDURE update_location_kind (p_location_kind_id   IN VARCHAR2,
											  p_description		  IN VARCHAR2
											 )
	IS
		l_office_code				 INTEGER := cwms_util.user_office_code;
		l_cwms_office_code		 INTEGER := cwms_util.get_office_code ('CWMS');
		l_existing_office_code	 INTEGER;
		l_location_kind_id		 VARCHAR2 (32)
											 := UPPER (TRIM (p_location_kind_id));
		l_description				 VARCHAR2 (256) := TRIM (p_description);
	BEGIN
		SELECT	office_code
		  INTO	l_existing_office_code
		  FROM	at_location_kind
		 WHERE	location_kind_id = l_location_kind_id
					AND office_code IN (l_office_code, l_cwms_office_code);

		IF l_existing_office_code = l_cwms_office_code
		THEN
			cwms_err.raise (
				'ERROR',
					'Cannot delete location kind '
				|| l_location_kind_id
				|| ' because it is owned by CWMS'
			);
		ELSE
			UPDATE	at_location_kind
				SET	description = l_description
			 WHERE	office_code = l_office_code
						AND location_kind_id = l_location_kind_id;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			cwms_err.raise ('INVALID_ITEM', l_location_kind_id, 'location kind');
	END update_location_kind;

	PROCEDURE delete_location_kind (p_location_kind_id IN VARCHAR2)
	IS
		l_office_code				 INTEGER := cwms_util.user_office_code;
		l_cwms_office_code		 INTEGER := cwms_util.get_office_code ('CWMS');
		l_existing_office_code	 INTEGER;
		l_location_kind_id		 VARCHAR2 (32)
											 := UPPER (TRIM (p_location_kind_id));
	BEGIN
		SELECT	office_code
		  INTO	l_existing_office_code
		  FROM	at_location_kind
		 WHERE	location_kind_id = l_location_kind_id
					AND office_code IN (l_office_code, l_cwms_office_code);

		IF l_existing_office_code = l_cwms_office_code
		THEN
			cwms_err.raise (
				'ERROR',
					'Cannot delete location kind '
				|| l_location_kind_id
				|| ' because it is owned by CWMS'
			);
		ELSE
			DELETE FROM   at_location_kind
					WHERE   office_code = l_office_code
							  AND location_kind_id = l_location_kind_id;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			cwms_err.raise ('INVALID_ITEM', l_location_kind_id, 'location kind');
	END delete_location_kind;

	--------------------------------------------------------------------------------
	-- FUNCTION get_local_timezone
	--------------------------------------------------------------------------------
	FUNCTION get_local_timezone (p_location_code IN NUMBER)
		RETURN VARCHAR2
	IS
		l_local_tz	 VARCHAR2 (28);
	BEGIN
		SELECT	time_zone_name
		  INTO	l_local_tz
		  FROM	cwms_time_zone ctz, at_physical_location atp
		 WHERE	atp.location_code = p_location_code
					AND ctz.time_zone_code = NVL (atp.time_zone_code, 0);

		IF l_local_tz = 'Unknown or Not Applicable'
		THEN
			l_local_tz := 'UTC';
		END IF;

		RETURN l_local_tz;
	END get_local_timezone;

	--------------------------------------------------------------------------------
	-- FUNCTION get_local_timezone
	--------------------------------------------------------------------------------
	function get_local_timezone (
      p_location_id	in varchar2,
		p_office_id		in varchar2)
		return varchar2
	is
		l_local_tz	varchar2(28);
      l_office_id varchar2(16) := cwms_util.get_db_office_id(p_office_id);  
   begin
      select distinct
             vl.time_zone_name
        into l_local_tz
        from av_loc2 vl
       where upper(vl.location_id) = upper(trim(p_location_id))
         and vl.db_office_id = l_office_id 
         and vl.unit_system = 'SI';

      if l_local_tz is null then
         l_local_tz := 'UTC';
      end if;

      return l_local_tz;
   exception
     when too_many_rows then
        cwms_err.raise(
           'ERROR', 
           l_office_id
           ||'/'
           ||p_location_id
           ||' references more than one location.');      
   end get_local_timezone;

	FUNCTION get_loc_category_code (p_loc_category_id	 IN VARCHAR2,
											  p_db_office_code	 IN NUMBER
											 )
		RETURN NUMBER
	IS
		l_loc_category_code	 NUMBER;
	BEGIN
		BEGIN
			SELECT	atlc.loc_category_code
			  INTO	l_loc_category_code
			  FROM	at_loc_category atlc
			 WHERE	atlc.db_office_code IN (53, p_db_office_code)
						AND UPPER (atlc.loc_category_id) =
								 UPPER (TRIM (p_loc_category_id));
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'Category id: ',
									 p_loc_category_id
									);
		END;

		RETURN l_loc_category_code;
	END get_loc_category_code;

	FUNCTION get_loc_group_code (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_db_office_code	 IN NUMBER
										 )
		RETURN NUMBER
	IS
		l_loc_category_code	 NUMBER;
		l_loc_group_code		 NUMBER;
	BEGIN
		l_loc_category_code :=
			get_loc_category_code (p_loc_category_id, p_db_office_code);

		BEGIN
			SELECT	loc_group_code
			  INTO	l_loc_group_code
			  FROM	at_loc_group atlg
			 WHERE		 atlg.loc_category_code = l_loc_category_code
						AND UPPER (atlg.loc_group_id) = UPPER (p_loc_group_id)
						AND db_office_code IN (53, p_db_office_code);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'group id: ',
									 p_loc_group_id
									);
		END;

		RETURN l_loc_group_code;
	END get_loc_group_code;

	PROCEDURE store_loc_category (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_fail_if_exists		 IN VARCHAR2 DEFAULT 'F',
		p_ignore_null			 IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_tmp   NUMBER;
	BEGIN
		l_tmp :=
			store_loc_category_f (p_loc_category_id,
										 p_loc_category_desc,
										 p_fail_if_exists,
										 p_ignore_null,
										 p_db_office_id
										);
	END store_loc_category;

	FUNCTION store_loc_category_f (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_fail_if_exists		 IN VARCHAR2 DEFAULT 'F',
		p_ignore_null			 IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER
	IS
		l_db_office_id 		 VARCHAR2 (16);
		l_db_office_code		 NUMBER;
		l_loc_category_id 	 VARCHAR2 (32) := TRIM (p_loc_category_id);
		l_loc_category_desc	 VARCHAR2 (128) := TRIM (p_loc_category_desc);
		l_fail_if_exists		 BOOLEAN := cwms_util.is_true (p_fail_if_exists);
		l_ignore_null			 BOOLEAN := cwms_util.is_true (p_ignore_null);
		l_rec 					 at_loc_category%ROWTYPE;
		l_exists 				 BOOLEAN;
	BEGIN
		l_db_office_id := NVL (UPPER (p_db_office_id), cwms_util.user_office_id);
		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		-------------------------------------------
		-- determine whether the category exists --
		-------------------------------------------
		BEGIN
			SELECT	*
			  INTO	l_rec
			  FROM	at_loc_category
			 WHERE	UPPER (loc_category_id) = UPPER (l_loc_category_id)
						AND db_office_code IN
								 (l_db_office_code, cwms_util.db_office_code_all);

			l_exists := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_exists := FALSE;
		END;

		--------------------------------
		-- fail if conditions warrant --
		--------------------------------
		IF l_exists
		THEN
			IF l_fail_if_exists
			THEN
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
						l_db_office_id
					|| '/'
					|| l_loc_category_id
					|| ' already exists.'
				);
			ELSIF l_rec.db_office_code = cwms_util.db_office_code_all
			THEN
				-------------------------------------------------------
				-- this is OK if we're not trying to update anything --
				-------------------------------------------------------
				IF (l_ignore_null AND p_loc_category_desc IS NULL)
					OR (p_loc_category_desc = l_rec.loc_category_desc)
				THEN
					RETURN l_rec.loc_category_code;
				END IF;

				----------------------------------
				-- can't change a CWMS category --
				----------------------------------
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
						'Cannot store the '
					|| l_loc_category_id
					|| ' category because it already exists as a system category.'
				);
			END IF;
		END IF;

		---------------------------------
		-- insert or update the record --
		---------------------------------
		IF l_exists
		THEN
			IF NOT (l_ignore_null AND p_loc_category_desc IS NULL)
			THEN
				l_rec.loc_category_desc := p_loc_category_desc;
			END IF;

			UPDATE	at_loc_category
				SET	row = l_rec
			 WHERE	loc_category_code = l_rec.loc_category_code;
		ELSE
			l_rec.loc_category_code := cwms_seq.NEXTVAL;
			l_rec.loc_category_id := p_loc_category_id;
			l_rec.loc_category_desc := p_loc_category_desc;
			l_rec.db_office_code := l_db_office_code;

			INSERT INTO   at_loc_category
				  VALUES   l_rec;
		END IF;

		RETURN l_rec.loc_category_code;
	END store_loc_category_f;

	PROCEDURE create_loc_category (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
		store_loc_category (p_loc_category_id,
								  p_loc_category_desc,
								  'T',
								  'F',
								  p_db_office_id
								 );
	END create_loc_category;

	FUNCTION create_loc_category_f (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_category_desc	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER
	IS
	BEGIN
		RETURN store_loc_category_f (p_loc_category_id,
											  p_loc_category_desc,
											  'T',
											  'F',
											  p_db_office_id
											 );
	END create_loc_category_f;

	PROCEDURE store_loc_group (p_loc_category_id 	 IN VARCHAR2,
										p_loc_group_id 		 IN VARCHAR2,
										p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
										p_fail_if_exists		 IN VARCHAR2 DEFAULT 'F',
										p_ignore_nulls 		 IN VARCHAR2 DEFAULT 'T',
										p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
										p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL,
										p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
									  )
	IS
		l_rec 				 at_loc_group%ROWTYPE;
		l_office_code		 NUMBER (10)
									 := cwms_util.get_db_office_code (p_db_office_id);
		l_fail_if_exists	 BOOLEAN := cwms_util.is_true (p_fail_if_exists);
		l_ignore_nulls 	 BOOLEAN := cwms_util.is_true (p_ignore_nulls);
		l_exists 			 BOOLEAN;
	BEGIN
		-----------------------------------------
		-- determine whether the record exists --
		-----------------------------------------
		BEGIN
			SELECT	g.loc_group_code, g.loc_category_code, g.loc_group_id,
						g.loc_group_desc, g.db_office_code, g.shared_loc_alias_id,
						g.shared_loc_ref_code
			  INTO	l_rec
			  FROM	at_loc_group g, at_loc_category c
			 WHERE		 UPPER (c.loc_category_id) = UPPER (p_loc_category_id)
						AND g.loc_category_code = c.loc_category_code
						AND UPPER (g.loc_group_id) = UPPER (p_loc_group_id)
						AND g.db_office_code IN
								 (l_office_code, cwms_util.db_office_code_all);

			l_exists := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_exists := FALSE;
		END;

		--------------------------------
		-- fail if conditions warrant --
		--------------------------------
		IF l_exists
		THEN
			IF l_fail_if_exists
			THEN
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
						'CWMS location group '
					|| NVL (UPPER (p_db_office_id), cwms_util.user_office_id)
					|| '/'
					|| p_loc_category_id
					|| '/'
					|| p_loc_group_id
				);
			END IF;

			IF l_rec.db_office_code = cwms_util.db_office_code_all
			THEN
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
					'Cannot store location group because it is a CWMS system item.'
				);
			END IF;
		END IF;

		---------------------------------
		-- insert or update the record --
		---------------------------------
		IF l_exists
		THEN
			IF NOT (l_ignore_nulls AND p_loc_group_desc IS NULL)
			THEN
				l_rec.loc_group_desc := p_loc_group_desc;
			END IF;

			IF NOT (l_ignore_nulls AND p_shared_alias_id IS NULL)
			THEN
				l_rec.shared_loc_alias_id := p_shared_alias_id;
			END IF;

			IF NOT (l_ignore_nulls AND p_shared_loc_ref_id IS NULL)
			THEN
				l_rec.shared_loc_ref_code :=
					cwms_loc.get_location_code (l_office_code,
														 p_shared_loc_ref_id
														);
			END IF;

			UPDATE	at_loc_group
				SET	row = l_rec
			 WHERE	loc_group_code = l_rec.loc_group_code;
		ELSE
			l_rec.loc_group_code := cwms_seq.NEXTVAL;
			l_rec.loc_category_code :=
				store_loc_category_f (p_loc_category_id,
											 NULL,
											 'F',
											 'T',
											 p_db_office_id
											);
			l_rec.loc_group_id := p_loc_group_id;
			l_rec.loc_group_desc := p_loc_group_desc;
			l_rec.db_office_code := l_office_code;
			l_rec.shared_loc_alias_id := p_shared_alias_id;

			IF p_shared_loc_ref_id IS NOT NULL
			THEN
				l_rec.shared_loc_ref_code :=
					cwms_loc.get_location_code (l_office_code,
														 p_shared_loc_ref_id
														);
			END IF;

			INSERT INTO   at_loc_group
				  VALUES   l_rec;
		END IF;
	END store_loc_group;

	PROCEDURE create_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_loc_group_desc 	IN VARCHAR2 DEFAULT NULL,
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										)
	IS
	BEGIN
		cwms_loc.store_loc_group (p_loc_category_id,
										  p_loc_group_id,
										  p_loc_group_desc,
										  'T',
										  'F',
										  NULL,
										  NULL,
										  p_db_office_id
										 );
	END create_loc_group;


	PROCEDURE create_loc_group2 (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_group_id 		 IN VARCHAR2,
		p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL,
		p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
		p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
		store_loc_group (p_loc_category_id,
							  p_loc_group_id,
							  p_loc_group_desc,
							  'T',
							  'F',
							  p_shared_alias_id,
							  p_shared_loc_ref_id,
							  p_db_office_id
							 );
	END create_loc_group2;

	PROCEDURE rename_loc_group (p_loc_category_id	 IN VARCHAR2,
										 p_loc_group_id_old	 IN VARCHAR2,
										 p_loc_group_id_new	 IN VARCHAR2,
										 p_loc_group_desc 	 IN VARCHAR2 DEFAULT NULL,
										 p_ignore_null 		 IN VARCHAR2 DEFAULT 'T',
										 p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_db_office_id 			 VARCHAR2 (16);
		l_db_office_code			 NUMBER;
		l_loc_category_code		 NUMBER;
		l_loc_group_code			 NUMBER;
		l_loc_group_id_old		 VARCHAR2 (32) := TRIM (p_loc_group_id_old);
		l_loc_group_id_new		 VARCHAR2 (32) := TRIM (p_loc_group_id_new);
		l_group_already_exists	 BOOLEAN := FALSE;
		l_ignore_null				 BOOLEAN;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		IF NVL (p_ignore_null, 'T') = 'T'
		THEN
			l_ignore_null := TRUE;
		ELSE
			l_ignore_null := FALSE;
		END IF;

		-- Does Category exist?.
		--
		BEGIN
			l_loc_category_code :=
				get_loc_category_code (p_loc_category_id, l_db_office_code);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'ITEM_DOES_NOT_EXIST',
					'Category id must exist to rename group id - Category id that does not exist: ',
					p_loc_category_id
				);
		END;

		--
		-- Does NEW Group id already exist?.
		BEGIN
			l_loc_group_code :=
				get_loc_group_code (p_loc_category_id,
										  p_loc_group_id_new,
										  l_db_office_code
										 );
			l_group_already_exists := TRUE;
		EXCEPTION
			WHEN OTHERS
			THEN
				l_group_already_exists := FALSE;
		END;

		IF l_group_already_exists
		THEN
			IF UPPER (l_loc_group_id_old) != UPPER (l_loc_group_id_new)
			THEN										  -- or there's not a case change...
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
					'p_loc_group_id_new already exists - can''t rename to: ',
					p_loc_group_id_new
				);
			END IF;
		END IF;

		--
		-- Does OLD Group id exist?.
		BEGIN
			l_loc_group_code :=
				get_loc_group_code (p_loc_category_id,
										  p_loc_group_id_old,
										  l_db_office_code
										 );
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'ITEM_DOES_NOT_EXIST',
					'p_loc_group_id_old does not exist - can''t perform rename of: ',
					p_loc_group_id_old
				);
		END;

		--
		-- all checks passed, perform the rename...
		IF p_loc_group_desc IS NULL AND l_ignore_null
		THEN
			UPDATE	at_loc_group
				SET	loc_group_id = l_loc_group_id_new
			 WHERE	loc_group_code = l_loc_group_code;
		ELSE
			UPDATE	at_loc_group
				SET	loc_group_id = l_loc_group_id_new,
						loc_group_desc = TRIM (p_loc_group_desc)
			 WHERE	loc_group_code = l_loc_group_code;
		END IF;
	--
	--
	END rename_loc_group;

	--
	--********************************************************************** -
	--********************************************************************** -
	--
	-- STORE_ALIAS   -
	--
	--*---------------------------------------------------------------------*-
	--
	--   PROCEDURE store_alias (
	--   p_location_id  IN VARCHAR2,
	--   p_category_id  IN VARCHAR2,
	--   p_group_id  IN VARCHAR2,
	--   p_alias_id  IN VARCHAR2,
	--   p_db_office_id IN VARCHAR2 DEFAULT NULL
	--   )
	--   IS
	--   l_loc_category_code  NUMBER;
	--   l_loc_group_code  NUMBER;
	--   l_location_code   NUMBER;
	--   l_db_office_id VARCHAR2 (16);
	--   l_db_office_code  NUMBER;
	--   l_tmp VARCHAR2 (128);
	--   BEGIN
	--   IF p_db_office_id IS NULL
	--   THEN
	--   l_db_office_id := cwms_util.user_office_id;
	--   ELSE
	--   l_db_office_id := UPPER (p_db_office_id);
	--   END IF;

	--   l_db_office_code := cwms_util.get_office_code (l_db_office_id);

	--   BEGIN
	--   l_loc_category_code :=
	--  get_loc_category_code (p_category_id, l_db_office_code);
	--   EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN
	--  cwms_err.RAISE ('GENERIC_ERROR',
	--   'The category id: '
	--  || p_category_id
	--  || ' does not exist.'
	--   );
	--   END;

	--   DBMS_OUTPUT.put_line ('gk 1');

	--   BEGIN
	--   l_loc_group_code :=
	--   get_loc_group_code (p_category_id, p_group_id, l_db_office_code);
	--   EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN
	--  cwms_err.RAISE ('GENERIC_ERROR',
	--   'There is no group: '
	--  || p_group_id
	--  || ' in the '
	--  || p_category_id
	--  || ' category.'
	--   );
	--   END;

	--   DBMS_OUTPUT.put_line ('gk 2');

	--   BEGIN
	--   l_location_code := get_location_code (p_db_office_id, p_location_id);
	--   EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN
	--  cwms_err.RAISE ('GENERIC_ERROR',
	--   'The '
	--  || p_location_id
	--  || ' location id does not exist.'
	--   );
	--   END;

	--   DBMS_OUTPUT.put_line ('gk 3');

	--   BEGIN
	--   SELECT loc_alias_id
	--   INTO l_tmp
	--   FROM at_loc_group_assignment
	--   WHERE location_code = l_location_code
	--  AND loc_group_code = l_loc_group_code;

	--   UPDATE at_loc_group_assignment
	--  SET loc_alias_id = trim(p_alias_id)
	--   WHERE location_code = l_location_code
	--  AND loc_group_code = l_loc_group_code;
	--   EXCEPTION
	--   WHEN NO_DATA_FOUND
	--   THEN
	--  INSERT INTO at_loc_group_assignment
	--  (loc_group_code, location_code, loc_alias_id
	--  )
	--   VALUES (l_loc_group_code, l_location_code, trim(p_alias_id)
	--  );
	--   END;

	---- MERGE INTO at_loc_group_assignment a
	---- USING (SELECT loc_group_code, location_code, loc_alias_id
	---- FROM at_loc_group_assignment
	---- WHERE loc_group_code = l_loc_group_code
	---- AND location_code = l_location_code) b
	---- ON (  a.loc_group_code = l_loc_group_code
	---- AND a.location_code = l_location_code)
	---- WHEN MATCHED THEN
	---- UPDATE
	---- SET a.loc_alias_id = p_alias_id
	---- WHEN NOT MATCHED THEN
	---- INSERT (loc_group_code, location_code, loc_alias_id)
	---- VALUES (cwms_seq.NEXTVAL, l_location_code, p_alias_id);
	--   END;

	--
	--
	-- assign_groups is used to assign one or more location_id's --
	-- to a location group.
	--
	--   loc_alias_type AS OBJECT (
	--   location_id VARCHAR2 (49),
	--   loc_alias_id  VARCHAR2 (16),
	--
	PROCEDURE assign_loc_groups (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_loc_alias_array	 IN loc_alias_array,
										  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										 )
	IS
		l_db_office_id 		 VARCHAR2 (16);
		l_db_office_code		 NUMBER;
		l_loc_category_code	 NUMBER;
		l_loc_group_code		 NUMBER;
		l_location_code		 NUMBER;
		l_cnt 					 NUMBER;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		BEGIN
			l_loc_category_code :=
				get_loc_category_code (p_loc_category_id, l_db_office_code);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'The category id: ' || p_loc_category_id || ' does not exist.'
				);
		END;

		BEGIN
			l_loc_group_code :=
				get_loc_group_code (p_loc_category_id,
										  p_loc_group_id,
										  l_db_office_code
										 );
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ERROR',
						'There is no group: '
					|| p_loc_group_id
					|| ' in the '
					|| p_loc_category_id
					|| ' category.'
				);
		END;


		FOR i IN 1 .. p_loc_alias_array.COUNT
		LOOP
			check_alias_id (p_loc_alias_array (i).loc_alias_id,
								 p_loc_alias_array (i).location_id,
								 p_loc_category_id,
								 p_loc_group_id,
								 l_db_office_id
								);
			l_location_code :=
				get_location_code (l_db_office_id,
										 p_loc_alias_array (i).location_id
										);

			IF l_location_code IS NULL
			THEN
				cwms_err.raise (
					'ERROR',
						'Unable to assign the Alias_ID: '
					|| p_loc_alias_array (i).loc_alias_id
					|| ' under the '
					|| p_loc_group_id
					|| ' Group in the '
					|| p_loc_category_id
					|| ' Location Category to the Location_ID: '
					|| p_loc_alias_array (i).location_id
					|| ' because that Location ID does not exist for your Office_ID: '
					|| l_db_office_id
				);
			ELSE
				SELECT	COUNT (*)
				  INTO	l_cnt
				  FROM	at_loc_group_assignment
				 WHERE	location_code = l_location_code
							AND loc_group_code = l_loc_group_code;

				IF l_cnt = 0
				THEN
					INSERT
					  INTO	at_loc_group_assignment (location_code,
																 loc_group_code,
																 loc_attribute,
																 loc_alias_id,
																 loc_ref_code,
                                                 office_code
																)
					VALUES	(
									l_location_code,
									l_loc_group_code,
									NULL,
									p_loc_alias_array (i).loc_alias_id,
									NULL,
                           l_db_office_code
								);
				ELSE
					UPDATE	at_loc_group_assignment
						SET	loc_attribute = NULL,
								loc_alias_id = p_loc_alias_array (i).loc_alias_id,
								loc_ref_code = NULL
					 WHERE	location_code = l_location_code
								AND loc_group_code = l_loc_group_code;
				END IF;
			END IF;
		END LOOP;
	--
	-- When we upgraded to 11.2.0.2.0 the update portion of this merge ran
	-- into table mutating errors because get_location_code() selects from
	-- table AT_LOC_GROUP_ASSIGNMENT
	--
	--  MERGE INTO  at_loc_group_assignment a
	--  USING  (SELECT get_location_code (l_db_office_id, plaa.location_id) location_code,
	--  plaa.loc_alias_id
	--   FROM TABLE (p_loc_alias_array) plaa) b
	--  ON  (a.loc_group_code = l_loc_group_code
	--  AND a.location_code = b.location_code)
	--  WHEN MATCHED
	--  THEN
	--  UPDATE SET
	--  a.loc_attribute = NULL,
	--  a.loc_alias_id = b.loc_alias_id,
	--  a.loc_ref_code = NULL
	--  WHEN NOT MATCHED
	--  THEN
	--  INSERT (location_code,
	--  loc_group_code,
	--  loc_attribute,
	--  loc_alias_id,
	--  loc_ref_code
	--   )
	--   VALUES  (
	--   b.location_code,
	--   l_loc_group_code,
	--   NULL,
	--   b.loc_alias_id,
	--   NULL
	--   );

	END assign_loc_groups;

	--
	-- assign_groups is used to assign one or more location_id's --
	-- to a location group.
	--
	--   loc_alias_type2 AS OBJECT (
	--   location_id VARCHAR2 (49),
	--   loc_attribute NUMBER,
	--   loc_alias_id  VARCHAR2 (128)
	--
	PROCEDURE assign_loc_groups2 (p_loc_category_id   IN VARCHAR2,
											p_loc_group_id 	  IN VARCHAR2,
											p_loc_alias_array   IN loc_alias_array2,
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  )
	IS
		l_db_office_id 		 VARCHAR2 (16);
		l_db_office_code		 NUMBER;
		l_loc_category_code	 NUMBER;
		l_loc_group_code		 NUMBER;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		BEGIN
			l_loc_category_code :=
				get_loc_category_code (p_loc_category_id, l_db_office_code);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'The category id: ' || p_loc_category_id || ' does not exist.'
				);
		END;

		BEGIN
			l_loc_group_code :=
				get_loc_group_code (p_loc_category_id,
										  p_loc_group_id,
										  l_db_office_code
										 );
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
						'There is no group: '
					|| p_loc_group_id
					|| ' in the '
					|| p_loc_category_id
					|| ' category.'
				);
		END;


		FOR i IN 1 .. p_loc_alias_array.COUNT
		LOOP
			check_alias_id (p_loc_alias_array (i).loc_alias_id,
								 p_loc_alias_array (i).location_id,
								 p_loc_category_id,
								 p_loc_group_id,
								 l_db_office_id
								);
		END LOOP;

		MERGE INTO	 at_loc_group_assignment a
			  USING	 (SELECT   get_location_code (l_db_office_id, plaa.location_id) location_code,
									  plaa.loc_attribute, plaa.loc_alias_id
							 FROM   TABLE (p_loc_alias_array) plaa) b
				  ON	 (a.loc_group_code = l_loc_group_code
						  AND a.location_code = b.location_code)
		WHEN MATCHED
		THEN
			UPDATE SET
				a.loc_attribute = b.loc_attribute,
				a.loc_alias_id = b.loc_alias_id
		WHEN NOT MATCHED
		THEN
			INSERT		 (location_code,
							  loc_group_code,
							  loc_attribute,
							  loc_alias_id,
                       office_code
							 )
				 VALUES	 (
								 b.location_code,
								 l_loc_group_code,
								 b.loc_attribute,
								 b.loc_alias_id,
                         l_db_office_code
							 );
	END assign_loc_groups2;

	--
	-- assign_groups is used to assign one or more location_id's --
	-- to a location group.
	--
	--   loc_alias_type3 AS OBJECT (
	--   location_id VARCHAR2 (49),
	--   loc_attribute NUMBER,
	--   loc_alias_id  VARCHAR2 (128),
	--   loc_ref_id  VARCHAR2 (49)
	--
	PROCEDURE assign_loc_groups3 (p_loc_category_id   IN VARCHAR2,
											p_loc_group_id 	  IN VARCHAR2,
											p_loc_alias_array   IN loc_alias_array3,
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  )
	IS
		l_db_office_id 		 VARCHAR2 (16);
		l_db_office_code		 NUMBER;
		l_loc_category_code	 NUMBER;
		l_loc_group_code		 NUMBER;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		BEGIN
			l_loc_category_code :=
				get_loc_category_code (p_loc_category_id, l_db_office_code);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'The category id: ' || p_loc_category_id || ' does not exist.'
				);
		END;

		BEGIN
			l_loc_group_code :=
				get_loc_group_code (p_loc_category_id,
										  p_loc_group_id,
										  l_db_office_code
										 );
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
						'There is no group: '
					|| p_loc_group_id
					|| ' in the '
					|| p_loc_category_id
					|| ' category.'
				);
		END;

		FOR i IN 1 .. p_loc_alias_array.COUNT
		LOOP
			check_alias_id (p_loc_alias_array (i).loc_alias_id,
								 p_loc_alias_array (i).location_id,
								 p_loc_category_id,
								 p_loc_group_id,
								 l_db_office_id
								);
		END LOOP;

		MERGE INTO	 at_loc_group_assignment a
			  USING	 (SELECT   get_location_code (p_db_office_id => l_db_office_id, p_location_id => plaa.location_id, p_check_aliases => 'F') location_code,
									  plaa.loc_attribute, plaa.loc_alias_id,
									  plaa.loc_ref_id
							 FROM   TABLE (p_loc_alias_array) plaa) b
				  ON	 (a.loc_group_code = l_loc_group_code
						  AND a.location_code = b.location_code)
		WHEN MATCHED
		THEN
			UPDATE SET
				a.loc_attribute = b.loc_attribute,
				a.loc_alias_id = b.loc_alias_id,
				a.loc_ref_code =
					DECODE (
						b.loc_ref_id,
						NULL, NULL,
						get_location_code (p_db_office_code   => l_db_office_code,
												 p_location_id 	  => b.loc_ref_id,
                                     p_check_aliases    => 'F'
												)
					)
		WHEN NOT MATCHED
		THEN
			INSERT		 (location_code,
							  loc_group_code,
							  loc_attribute,
							  loc_alias_id,
							  loc_ref_code,
                       office_code
							 )
				 VALUES	 (
								 b.location_code,
								 l_loc_group_code,
								 b.loc_attribute,
								 b.loc_alias_id,
								 DECODE (
									 b.loc_ref_id,
									 NULL, NULL,
									 get_location_code (
										 p_db_office_code   => l_db_office_code,
										 p_location_id 	  => b.loc_ref_id,
                               p_check_aliases    => 'F'
									 )
								 ),
                         l_db_office_code
							 );
	END assign_loc_groups3;

	-- creates it and will rename the aliases if they already exist.
	PROCEDURE assign_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_location_id 		IN VARCHAR2,
										 p_loc_alias_id		IN VARCHAR2 DEFAULT NULL,
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_loc_alias_array   loc_alias_array
			:= loc_alias_array (loc_alias_type (p_location_id, p_loc_alias_id));
	BEGIN
		assign_loc_groups (p_loc_category_id	=> p_loc_category_id,
								 p_loc_group_id		=> p_loc_group_id,
								 p_loc_alias_array	=> l_loc_alias_array,
								 p_db_office_id		=> p_db_office_id
								);
	END assign_loc_group;

	PROCEDURE assign_loc_group2 (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_location_id		 IN VARCHAR2,
										  p_loc_attribute 	 IN NUMBER DEFAULT NULL,
										  p_loc_alias_id		 IN VARCHAR2 DEFAULT NULL,
										  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										 )
	IS
		l_loc_alias_array2	loc_alias_array2
			:= loc_alias_array2 (
					loc_alias_type2 (p_location_id,
										  p_loc_attribute,
										  p_loc_alias_id
										 )
				);
	BEGIN
		assign_loc_groups2 (p_loc_category_id	 => p_loc_category_id,
								  p_loc_group_id		 => p_loc_group_id,
								  p_loc_alias_array	 => l_loc_alias_array2,
								  p_db_office_id		 => p_db_office_id
								 );
	END assign_loc_group2;

	PROCEDURE assign_loc_group3 (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_location_id		 IN VARCHAR2,
										  p_loc_attribute 	 IN NUMBER DEFAULT NULL,
										  p_loc_alias_id		 IN VARCHAR2 DEFAULT NULL,
										  p_ref_loc_id 		 IN VARCHAR2 DEFAULT NULL,
										  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										 )
	IS
		l_loc_alias_array   loc_alias_array3;
	BEGIN
		l_loc_alias_array :=
			loc_alias_array3 (
				loc_alias_type3 (
					p_location_id,
					p_loc_attribute,
					p_loc_alias_id,
               p_ref_loc_id
				)
			);
		assign_loc_groups3 (p_loc_category_id	 => p_loc_category_id,
								  p_loc_group_id		 => p_loc_group_id,
								  p_loc_alias_array	 => l_loc_alias_array,
								  p_db_office_id		 => p_db_office_id
								 );
	END assign_loc_group3;

	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-- unassign_loc_groups and
	-- unassign_loc_group
	--
	--These procedures unassign (delete) group/location pairs. The -
	--unassign_loc_groups procedure accepts an array of locations so that one or -
	--more group/location pairs can be unassigned. The unassign_loc_group procedure -
	--only accepts a single group location pair for unassignment.
	--
	--Both calls allow the possibility to unassign all group/location pairs by -
	--setting the p_unassign_all parameter to "T" for TURE. The default value for -
	--this parameter is "F" for FALSE.
	--
	--For the unassign_loc_groups call, the p_location_array uses the CWMS -
	--"char_49_array_type" table type, which is an array of table type varchar2(49).

	--Note that you cannot unassign group/location pairs if a group/location pair -
	--is being referenced by a SHEF decode entry.
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	PROCEDURE unassign_loc_groups (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_id 	  IN VARCHAR2,
		p_location_array	  IN char_49_array_type,
		p_unassign_all 	  IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code	 NUMBER := cwms_util.get_office_code (p_db_office_id);
		l_loc_group_code	 NUMBER
			:= get_loc_group_code (p_loc_category_id	 => p_loc_category_id,
										  p_loc_group_id		 => p_loc_group_id,
										  p_db_office_code	 => l_db_office_code
										 );
		l_tmp 				 NUMBER;
		l_unassign_all 	 BOOLEAN := FALSE;  
	BEGIN
		IF UPPER (TRIM (p_unassign_all)) = 'T'
		THEN
			l_unassign_all := TRUE;
		END IF;

		BEGIN
			IF l_unassign_all
			THEN							  -- delete all group/location assignments...
				DELETE FROM   at_loc_group_assignment lga
						WHERE   loc_group_code = l_loc_group_code
                    AND   l_db_office_code = (select bl.db_office_code
                                                from at_physical_location pl,
                                                     at_base_location bl
                                               where pl.location_code = location_code
                                                 and bl.base_location_code = bl.base_location_code      
                                             );
			ELSE						 -- delete only group/location assignments for -
				-- given locations...
				DELETE FROM   at_loc_group_assignment
						WHERE   loc_group_code = l_loc_group_code
								  AND location_code IN
											(SELECT	 location_code
												FROM	 av_loc b,
														 TABLE (
															 CAST (
																 p_location_array AS char_49_array_type
															 )
														 ) c
											  WHERE	 UPPER (b.location_id) =
															 UPPER (TRIM (c.COLUMN_VALUE)));
			END IF;
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'Cannot unassign Location/Group pair(s). One or more group assignments are still assigned.'
				);
		END;
	END unassign_loc_groups;

	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-- unassign_loc_group --
	-- See description for unassign_loc_groups above.--
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	PROCEDURE unassign_loc_group (p_loc_category_id   IN VARCHAR2,
											p_loc_group_id 	  IN VARCHAR2,
											p_location_id		  IN VARCHAR2,
											p_unassign_all 	  IN VARCHAR2 DEFAULT 'F',
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  )
	IS
		l_location_array	 char_49_array_type
									 := char_49_array_type (TRIM (p_location_id));
	BEGIN
		unassign_loc_groups (p_loc_category_id   => p_loc_category_id,
									p_loc_group_id 	  => p_loc_group_id,
									p_location_array	  => l_location_array,
									p_unassign_all 	  => p_unassign_all,
									p_db_office_id 	  => p_db_office_id
								  );
	END unassign_loc_group;

	PROCEDURE delete_loc_group (p_loc_group_code   IN NUMBER,
										 p_cascade			  IN VARCHAR2 DEFAULT 'F'
										)
	IS
	BEGIN
		IF cwms_util.is_true (p_cascade)
		THEN
			DELETE FROM   at_loc_group_assignment
					WHERE   loc_group_code = p_loc_group_code;

			UPDATE	at_rating_spec
				SET	source_agency_code = NULL
			 WHERE	source_agency_code = p_loc_group_code;
		END IF;

		--------------------------------------------------------------------
		-- delete the group (will fail if there are location assignments) --
		--------------------------------------------------------------------
		DELETE FROM   at_loc_group
				WHERE   loc_group_code = p_loc_group_code;
	END delete_loc_group;

	PROCEDURE delete_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_cascade				IN VARCHAR2 DEFAULT 'F',
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_loc_group_code	 NUMBER (10);
		l_db_office_code	 NUMBER := cwms_util.get_office_code (p_db_office_id);
	BEGIN
		IF l_db_office_code = cwms_util.db_office_code_all
		THEN
			cwms_err.raise (
				'ERROR',
				'Groups owned by the CWMS office id can not be deleted.'
			);
		END IF;

		------------------------------------------
		-- get the the category and group codes --
		------------------------------------------
		l_loc_group_code :=
			get_loc_group_code (p_loc_category_id	 => p_loc_category_id,
									  p_loc_group_id		 => p_loc_group_id,
									  p_db_office_code	 => l_db_office_code
									 );
		delete_loc_group (p_loc_group_code	 => l_loc_group_code,
								p_cascade			 => p_cascade
							  );
	END delete_loc_group;

	-- can only delete if there are no assignments to this group.
	PROCEDURE delete_loc_group (p_loc_category_id	IN VARCHAR2,
										 p_loc_group_id		IN VARCHAR2,
										 p_db_office_id		IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_loc_group_code	 NUMBER (10);
		l_db_office_code	 NUMBER := cwms_util.get_office_code (p_db_office_id);
	BEGIN
		delete_loc_group (p_loc_category_id   => p_loc_category_id,
								p_loc_group_id 	  => p_loc_group_id,
								p_cascade			  => 'F',
								p_db_office_id 	  => p_db_office_id
							  );
	END delete_loc_group;

	PROCEDURE delete_loc_cat (p_loc_category_id	 IN VARCHAR2,
									  p_cascade 			 IN VARCHAR2 DEFAULT 'F',
									  p_db_office_id		 IN VARCHAR2 DEFAULT NULL
									 )
	IS
		l_loc_category_code	 NUMBER (10);
		l_db_office_code		 NUMBER;
	BEGIN
		---------------------------
		-- get the category code --
		---------------------------

		l_loc_category_code :=
			get_loc_category_code (
				p_loc_category_id   => p_loc_category_id,
				p_db_office_code	  => cwms_util.get_office_code (p_db_office_id)
			);

		---------------------------------------------------
		-- delete groups in this caegory if specified  --
		-- (will fail if there are location assignments) --
		---------------------------------------------------
		IF cwms_util.is_true (p_cascade)
		THEN
			NULL;

			FOR loc_group_code_rec
				IN (SELECT	 loc_group_code
						FROM	 at_loc_group
					  WHERE	 loc_category_code = l_loc_category_code)
			LOOP
				delete_loc_group (
					p_loc_group_code	 => loc_group_code_rec.loc_group_code,
					p_cascade				 => 'T'
				);
			END LOOP;
		END IF;

		---------------------------------------------------------------
		-- delete the category (will fail if there are still groups) --
		---------------------------------------------------------------
		DELETE FROM   at_loc_category
				WHERE   loc_category_code = l_loc_category_code;
	END delete_loc_cat;

	PROCEDURE rename_loc_category (
		p_loc_category_id_old	IN VARCHAR2,
		p_loc_category_id_new	IN VARCHAR2,
		p_loc_category_desc		IN VARCHAR2 DEFAULT NULL,
		p_ignore_null				IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_id 				 VARCHAR2 (16);
		l_db_office_code				 NUMBER;
		l_loc_category_code_old 	 NUMBER;
		l_loc_category_code_new 	 NUMBER;
		l_loc_category_id_old		 VARCHAR2 (32) := TRIM (p_loc_category_id_old);
		l_loc_category_id_new		 VARCHAR2 (32) := TRIM (p_loc_category_id_new);
		l_category_already_exists	 BOOLEAN := FALSE;
		l_ignore_null					 BOOLEAN;
		l_cat_owned_by_cwms			 BOOLEAN;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		IF NVL (p_ignore_null, 'T') = 'T'
		THEN
			l_ignore_null := TRUE;
		ELSE
			l_ignore_null := FALSE;
		END IF;

		-- Is the p_loc_category_OLD owned by CWMS?...
		---
		BEGIN
			SELECT	loc_category_code
			  INTO	l_loc_category_code_old
			  FROM	at_loc_category
			 WHERE	UPPER (loc_category_id) = UPPER (l_loc_category_id_old)
						AND db_office_code = (SELECT	 office_code
														FROM	 cwms_office
													  WHERE	 office_id = 'CWMS');

			l_cat_owned_by_cwms := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_cat_owned_by_cwms := FALSE;
		END;

		IF l_cat_owned_by_cwms
		THEN
			cwms_err.raise (
				'ITEM_ALREADY_EXISTS',
				'The ' || l_loc_category_id_old
				|| ' category is owned by the system. You cannot rename this category.'
			);
		END IF;

		-- Is the p_loc_category_NEW owned by CWMS?...
		---
		BEGIN
			SELECT	loc_category_code
			  INTO	l_loc_category_code_new
			  FROM	at_loc_category
			 WHERE	UPPER (loc_category_id) = UPPER (l_loc_category_id_new)
						AND db_office_code = (SELECT	 office_code
														FROM	 cwms_office
													  WHERE	 office_id = 'CWMS');

			l_cat_owned_by_cwms := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_cat_owned_by_cwms := FALSE;
		END;

		IF l_cat_owned_by_cwms
		THEN
			cwms_err.raise (
				'ITEM_ALREADY_EXISTS',
				'The ' || l_loc_category_id_new
				|| ' category is owned by the system. You cannot rename to this category.'
			);
		END IF;

		-- Does Category exist?.
		--
		BEGIN
			l_loc_category_code_old :=
				get_loc_category_code (l_loc_category_id_old, l_db_office_code);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'ITEM_DOES_NOT_EXIST',
					'Category id must exist to rename it - Category id that does not exist: ',
					l_loc_category_id_old
				);
		END;

		--
		-- Does NEW Category id already exist?.
		BEGIN
			l_loc_category_code_new :=
				get_loc_category_code (l_loc_category_id_new, l_db_office_code);
			l_category_already_exists := TRUE;
		EXCEPTION
			WHEN OTHERS
			THEN
				l_category_already_exists := FALSE;
		END;

		IF l_category_already_exists
		THEN
			IF UPPER (l_loc_category_id_old) != UPPER (l_loc_category_id_new)
			THEN										  -- or there's not a case change...
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
					'p_loc_category_id_new already exists - can''t rename to: ',
					l_loc_category_id_old
				);
			END IF;
		END IF;

		--
		-- all checks passed, perform the rename...
		IF p_loc_category_desc IS NULL AND l_ignore_null
		THEN
			UPDATE	at_loc_category
				SET	loc_category_id = l_loc_category_id_new
			 WHERE	loc_category_code = l_loc_category_code_old;
		ELSE
			UPDATE	at_loc_category
				SET	loc_category_id = l_loc_category_id_new,
						loc_category_desc = TRIM (p_loc_category_desc)
			 WHERE	loc_category_code = l_loc_category_code_old;
		END IF;
	--
	--
	END rename_loc_category;

	--
	-- used to assign one or more groups to an existing category.
	--
	PROCEDURE assign_loc_grps_cat2 (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_array   IN group_array2,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_id 		 VARCHAR2 (16);
		l_db_office_code		 NUMBER;
		l_loc_category_code	 NUMBER;
		l_loc_group_code		 NUMBER;
		l_loc_category_id 	 VARCHAR2 (32) := TRIM (p_loc_category_id);
		l_loc_group_id 		 VARCHAR2 (32);
		l_loc_group_desc		 VARCHAR2 (128);
		l_tmp 					 NUMBER;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		IF l_db_office_code = cwms_util.db_office_code_all
		THEN
			cwms_err.raise ('GENERIC_ERROR',
								 'Cannot assign system office groups with this call.'
								);
		END IF;

		-- get the category_code...
		BEGIN
			l_loc_category_code :=
				get_loc_category_code (l_loc_category_id, l_db_office_code);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				NULL;
		END;

		l_tmp := p_loc_group_array.COUNT;

		IF l_tmp > 0
		THEN
			FOR i IN 1 .. l_tmp
			LOOP
				l_loc_group_id := TRIM (p_loc_group_array (i).GROUP_ID);
				l_loc_group_desc := TRIM (p_loc_group_array (i).group_desc);

				BEGIN
					--
					-- If the group_id already exists, then update -
					-- the group_id and group_desc...
					SELECT	loc_group_code
					  INTO	l_loc_group_code
					  FROM	at_loc_group
					 WHERE		 UPPER (loc_group_id) = UPPER (l_loc_group_id)
								AND loc_category_code = l_loc_category_code
								AND db_office_code = l_db_office_code;

					UPDATE	at_loc_group
						SET	loc_group_id = l_loc_group_id,
								loc_group_desc = l_loc_group_desc,
								shared_loc_alias_id =
									p_loc_group_array (i).shared_alias_id,
								shared_loc_ref_code =
									get_location_code (
										l_db_office_code,
										p_loc_group_array (i).shared_loc_ref_id
									)
					 WHERE	loc_group_code = l_loc_group_code;

					l_loc_group_code := NULL;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						BEGIN
							--
							-- Check if the group_id is a CWMS owned -
							-- group_id, if it is, do nothing...
							SELECT	loc_group_code
							  INTO	l_loc_group_code
							  FROM	at_loc_group
							 WHERE	UPPER (loc_group_id) = UPPER (l_loc_group_id)
										AND loc_category_code = l_loc_category_code
										AND db_office_code =
												 cwms_util.db_office_code_all;
						EXCEPTION
							WHEN NO_DATA_FOUND
							THEN
								--
								-- Insert a new group_id...
								INSERT
								  INTO	at_loc_group (loc_group_code,
															  loc_category_code,
															  loc_group_id,
															  loc_group_desc,
															  shared_loc_alias_id,
															  shared_loc_ref_code,
															  db_office_code
															 )
								VALUES	(
												cwms_seq.NEXTVAL,
												l_loc_category_code,
												l_loc_group_id,
												l_loc_group_desc,
												l_db_office_code,
												p_loc_group_array (i).shared_alias_id,
												get_location_code (
													l_db_office_code,
													p_loc_group_array (i).shared_loc_ref_id
												)
											);
						END;
				END;
			END LOOP;
		END IF;
	END assign_loc_grps_cat2;


	--
	-- used to assign a group to an existing category.
	--
	PROCEDURE assign_loc_grp_cat2 (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_group_id 		 IN VARCHAR2,
		p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
		p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
		p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_loc_group_array   group_array2
			:= group_array2 (
					group_type2 (TRIM (p_loc_group_id),
									 TRIM (p_loc_group_desc),
									 p_shared_alias_id,
									 p_shared_loc_ref_id
									)
				);
	BEGIN
		assign_loc_grps_cat2 (p_loc_category_id,
									 l_loc_group_array,
									 p_db_office_id
									);
	END assign_loc_grp_cat2;

	--
	-- used to assign one or more groups to an existing category.
	--
	PROCEDURE assign_loc_grps_cat (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_array   IN group_array,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_loc_group_array   group_array2 := group_array2 ();
	BEGIN
		l_loc_group_array.EXTEND (p_loc_group_array.COUNT);

		FOR i IN 1 .. p_loc_group_array.COUNT
		LOOP
			l_loc_group_array (i) :=
				group_type2 (p_loc_group_array (i).GROUP_ID,
								 p_loc_group_array (i).group_desc,
								 NULL,
								 NULL
								);
		END LOOP;

		assign_loc_grps_cat2 (p_loc_category_id,
									 l_loc_group_array,
									 p_db_office_id
									);
	END assign_loc_grps_cat;

	--
	-- used to assign a group to an existing category.
	--
	PROCEDURE assign_loc_grp_cat (
		p_loc_category_id   IN VARCHAR2,
		p_loc_group_id 	  IN VARCHAR2,
		p_loc_group_desc	  IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
		assign_loc_grp_cat2 (p_loc_category_id 	 => p_loc_category_id,
									p_loc_group_id 		 => p_loc_group_id,
									p_loc_group_desc		 => p_loc_group_desc,
									p_shared_alias_id 	 => NULL,
									p_shared_loc_ref_id	 => NULL,
									p_db_office_id 		 => p_db_office_id
								  );
	END assign_loc_grp_cat;

	FUNCTION retrieve_location (p_location_code IN NUMBER)
		RETURN location_obj_t
	IS
		l_location_obj   location_obj_t := NULL;
		l_location_ref   location_ref_t := NULL;

		FUNCTION elev_unit (p_office_id IN VARCHAR2)
			RETURN VARCHAR2
		IS
			l_unit	  VARCHAR2 (16);
			l_factor   NUMBER;
		BEGIN
			cwms_util.user_display_unit (l_unit,
												  l_factor,
												  'Elev',
												  1.0,
												  NULL,
												  p_office_id
												 );
			RETURN l_unit;
		END;

		FUNCTION elev_factor (p_office_id IN VARCHAR2)
			RETURN NUMBER
		IS
			l_unit	  VARCHAR2 (16);
			l_factor   NUMBER;
		BEGIN
			cwms_util.user_display_unit (l_unit,
												  l_factor,
												  'Elev',
												  1.0,
												  NULL,
												  p_office_id
												 );
			RETURN l_factor;
		END;
	BEGIN
		FOR rec IN (SELECT	o.office_id office_id, o.office_code office_code,
									pl.location_code location_code,
									bl.base_location_id base_location_id,
									pl.sub_location_id sub_location_id,
									s.state_initial state_initial,
									c.county_name county_name,
									tz.time_zone_name time_zone_name,
									pl.location_type location_type,
									pl.latitude latitude, pl.longitude longitude,
									pl.horizontal_datum horizontal_datum,
									pl.elevation elevation,
									pl.vertical_datum vertical_datum,
									pl.public_name public_name, pl.long_name long_name,
									pl.description description,
									pl.active_flag active_flag,
									lk.location_kind_id location_kind_id,
									pl.map_label map_label,
									pl.published_latitude published_latitude,
									pl.published_longitude published_longitude,
									o2.office_id bounding_office_id,
									o2.public_name bounding_office_name,
									n.nation_id nation_id,
									pl.nearest_city nearest_city
						  FROM	at_physical_location pl
									LEFT OUTER JOIN at_base_location bl
										ON (pl.base_location_code =
												 bl.base_location_code)
									LEFT OUTER JOIN at_location_kind lk
										ON (pl.location_kind = lk.location_kind_code)
									LEFT OUTER JOIN cwms_time_zone tz
										ON (pl.time_zone_code = tz.time_zone_code)
									LEFT OUTER JOIN cwms_county c
										ON (pl.county_code = c.county_code)
									LEFT OUTER JOIN cwms_state s
										ON (c.state_code = s.state_code)
									LEFT OUTER JOIN cwms_nation n
										ON (pl.nation_code = n.nation_code)
									LEFT OUTER JOIN cwms_office o
										ON (bl.db_office_code = o.office_code)
									LEFT OUTER JOIN cwms_office o2
										ON (pl.office_code = o2.office_code)
						 WHERE	pl.location_code = p_location_code)
		LOOP
			l_location_ref :=
				NEW location_ref_t (rec.base_location_id,
										  rec.sub_location_id,
										  rec.office_id
										 );
			l_location_obj :=
				NEW location_obj_t (l_location_ref,
										  rec.state_initial,
										  rec.county_name,
										  rec.time_zone_name,
										  rec.location_type,
										  rec.latitude,
										  rec.longitude,
										  rec.horizontal_datum,
										  rec.elevation * elev_factor (rec.office_id),
										  elev_unit (rec.office_id),
										  rec.vertical_datum,
										  rec.public_name,
										  rec.long_name,
										  rec.description,
										  rec.active_flag,
										  rec.location_kind_id,
										  rec.map_label,
										  rec.published_latitude,
										  rec.published_longitude,
										  rec.bounding_office_id,
										  rec.bounding_office_name,
										  rec.nation_id,
										  rec.nearest_city
										 );
		END LOOP;

		RETURN l_location_obj;
	END retrieve_location;

	FUNCTION retrieve_location (p_location_id 	IN VARCHAR2,
										 p_db_office_id	IN VARCHAR2 DEFAULT NULL
										)
		RETURN location_obj_t
	IS
	BEGIN
		RETURN retrieve_location (
					 get_location_code (p_db_office_id, p_location_id)
				 );
	END retrieve_location;

	PROCEDURE store_location (p_location			IN location_obj_t,
									  p_fail_if_exists	IN VARCHAR2 DEFAULT 'T'
									 )
	IS
		l_location_code	NUMBER;
	BEGIN
		l_location_code := store_location_f (p_location, p_fail_if_exists);
	END store_location;

	FUNCTION store_location_f (p_location			 IN location_obj_t,
										p_fail_if_exists	 IN VARCHAR2 DEFAULT 'T'
									  )
		RETURN NUMBER
	IS
		l_location_code			NUMBER;
		location_id_not_found	EXCEPTION;
		PRAGMA EXCEPTION_INIT (location_id_not_found, -20025);
	BEGIN
		BEGIN
			l_location_code :=
				cwms_loc.get_location_code (
					p_location.location_ref.get_office_id,
					p_location.location_ref.get_location_id
				);
		EXCEPTION
			WHEN location_id_not_found
			THEN
				NULL;
		END;

		IF l_location_code IS NOT NULL
		THEN
			IF cwms_util.is_true (p_fail_if_exists)
			THEN
				cwms_err.raise ('LOCATION_ID_ALREADY_EXISTS',
									 p_location.location_ref.get_office_id,
									 p_location.location_ref.get_location_id
									);
			END IF;
		END IF;

		cwms_loc.store_location2 (p_location.location_ref.get_location_id,
										  p_location.location_type,
										  p_location.elevation,
										  p_location.elev_unit_id,
										  p_location.vertical_datum,
										  p_location.latitude,
										  p_location.longitude,
										  p_location.horizontal_datum,
										  p_location.public_name,
										  p_location.long_name,
										  p_location.description,
										  p_location.time_zone_name,
										  p_location.county_name,
										  p_location.state_initial,
										  p_location.active_flag,
										  p_location.location_kind_id,
										  p_location.map_label,
										  p_location.published_latitude,
										  p_location.published_longitude,
										  p_location.bounding_office_id,
										  p_location.nation_id,
										  p_location.nearest_city,
										  'T',
										  p_location.location_ref.get_office_id
										 );

		l_location_code :=
			cwms_loc.get_location_code (p_location.location_ref.get_office_id,
												 p_location.location_ref.get_location_id
												);

		RETURN l_location_code;
	END store_location_f;


	function get_location_id_from_alias (
		p_alias_id		 in varchar2,
		p_group_id		 in varchar2 default null,
		p_category_id	 in varchar2 default null,
		p_office_id 	 in varchar2 default null)
		return varchar2
	is  
      l_office_code   number(10);  
      l_location_code number(10);
      l_office_id     varchar2(16);
		l_location_id   varchar2(49); 
      l_parts         str_tab_t;
	begin
		-------------------
		-- sanity checks --
		-------------------
      l_office_code := cwms_util.get_db_office_code(upper(trim(p_office_id)));
      select office_id into l_office_id from cwms_office where office_code = l_office_code;

   	-----------------------------------------
		-- retrieve and return the location id --
		-----------------------------------------
      begin
         select distinct
                a.location_code
           into l_location_code
           from at_loc_group_assignment a,
                at_loc_group g,
                at_loc_category c
          where a.office_code = l_office_code
            and g.loc_group_code = a.loc_group_code
            and c.loc_category_code = g.loc_category_code
            and upper(a.loc_alias_id) = upper(trim(p_alias_id))
            and upper(g.loc_group_id) = upper(trim(nvl(p_group_id, g.loc_group_id)))           
            and upper(c.loc_category_id) = upper(trim(nvl(p_category_id, c.loc_category_id)));           
      exception
         when no_data_found then
            -----------------------------------------------
            -- perhaps only the base location is aliased --
            -----------------------------------------------
            l_parts := cwms_util.split_text(trim(p_alias_id), '-', 1);
            if (l_parts.count = 2) then
               l_location_id := get_location_id_from_alias(l_parts(1), p_group_id, p_category_id, l_office_id);
               if l_location_id is not null then    
                  begin
                     select distinct
                            location_id
                       into l_location_id
                       from cwms_v_loc
                      where location_id = l_location_id || '-' || trim(l_parts(2))
                        and db_office_id = l_office_id; 
                  exception
                     when no_data_found then
                        l_location_id := null;
                  end;
               end if;
            end if;
         when too_many_rows then
            cwms_err.raise (
               'ERROR',
               'Alias (' || p_alias_id || ') matches more than one location.');
      end;

		if l_location_id is null and l_location_code is not null then
         l_location_id := cwms_loc.get_location_id(l_location_code);
      end if;
      return l_location_id;
	end get_location_id_from_alias;


	function get_location_code_from_alias (
		p_alias_id    in varchar2,
		p_group_id    in varchar2 default null,
		p_category_id in varchar2 default null,
		p_office_id   in varchar2 default null)
		return number
	is
		l_location_code number(10);
      l_location_id   varchar2(256);
      l_office_id     varchar2(16);
	begin
		-------------------
		-- sanity checks --
		-------------------
      l_office_id := cwms_util.get_db_office_id(p_office_id);
                       
      l_location_id := get_location_id_from_alias(p_alias_id, p_group_id, p_category_id, l_office_id);
      if l_location_id is not null then
         l_location_code := cwms_loc.get_location_code(
            p_db_office_id  => l_office_id,
            p_location_id   => l_location_id, 
            p_check_aliases => 'F');
      end if; 
         
      return l_location_code; 
         
	end get_location_code_from_alias;

   procedure check_alias_id (p_alias_id      in varchar2,
                             p_location_id   in varchar2,
                             p_category_id   in varchar2,
                             p_group_id      in varchar2,
                             p_office_id      in varchar2 default null
                            )
   is
      l_location_id     varchar2(49);
      l_location_code  number(10);
      l_office_id      varchar2(16);
      l_count           pls_integer;
      l_multiple_ids   boolean;
      l_property_id     varchar2(256);
   begin
      l_office_id := cwms_util.get_db_office_id(p_office_id);

      -----------------------------------------------------------
      -- first, check for multiple locations in the same group --
      -----------------------------------------------------------
      if p_alias_id is not null and p_category_id is not null and p_group_id is not null then
         l_location_code := nvl(get_location_code(l_office_id, p_location_id, 'F'), -1);
         begin
            select count(*)
              into l_count
              from at_loc_category c,
                   at_loc_group g,
                   at_loc_group_assignment a
             where upper(c.loc_category_id) = upper(p_category_id)
               and upper(g.loc_group_id) = upper(p_group_id)
               and upper(a.loc_alias_id) = upper(p_alias_id)
               and a.location_code != l_location_code 
               and g.loc_category_code = c.loc_category_code
               and a.loc_group_code = g.loc_group_code;
         exception
            when no_data_found then
               l_count := 0;
         end;

         if l_count > 0 then
            cwms_err.raise (
               'ERROR',
               'Alias '
               || p_alias_id
               || ' is already in use in location office/category/group ('
               || l_office_id
               || '/'
               || p_category_id
               || '/'
               || p_group_id
               || ').');
         end if;
      end if;

      -----------------------------------------------------------
      -- next, see if the alias is already a location id or is --
      -- used in another group to references anothter location --
      -----------------------------------------------------------
      begin
         l_location_id  := get_location_id(p_alias_id, p_office_id);
      exception
         when too_many_rows then
            l_multiple_ids := true;
      end;
      l_multiple_ids := l_multiple_ids or (l_location_id is not null and upper(l_location_id) != upper(p_location_id));

      if l_multiple_ids then
         l_property_id := 'Allow_multiple_locations_for_alias';

         if not cwms_util.is_true(cwms_properties.get_property('CWMSDB', l_property_id, 'F', l_office_id)) then
            cwms_err.raise(
               'ERROR',
               'Alias ('
               || p_alias_id
               || ') would reference multiple locations.  '
               || 'If you want to allow this, set the CWMSDB/'
               || l_property_id
               || ' '
               || 'property to ''T'' for office id '
               || l_office_id
               || '.  Note that this action will '
               || 'eliminate the ability to look up a location using the alias or any others that '
               || 'reference multiple locations.'
            );
         end if;
      end if;
   end check_alias_id;

	FUNCTION check_alias_id_f (p_alias_id		 IN VARCHAR2,
										p_location_id	 IN VARCHAR2,
										p_category_id	 IN VARCHAR2,
										p_group_id		 IN VARCHAR2,
										p_office_id 	 IN VARCHAR2 DEFAULT NULL
									  )
		RETURN VARCHAR2
	IS
	BEGIN
		check_alias_id (p_alias_id,
							 p_location_id,
							 p_category_id,
							 p_group_id,
							 p_office_id
							);
		RETURN p_alias_id;
	END check_alias_id_f;

	PROCEDURE store_url (p_location_id		 IN VARCHAR2,
								p_url_id 			 IN VARCHAR2,
								p_url_address		 IN VARCHAR2,
								p_fail_if_exists	 IN VARCHAR2,
								p_ignore_nulls 	 IN VARCHAR2,
								p_url_title 		 IN VARCHAR2 DEFAULT NULL,
								p_office_id 		 IN VARCHAR2 DEFAULT NULL
							  )
	IS
		l_fail_if_exists	 BOOLEAN;
		l_ignore_nulls 	 BOOLEAN;
		l_exists 			 BOOLEAN;
		l_rec 				 at_location_url%ROWTYPE;
	BEGIN
		-------------------
		-- sanity checks --
		-------------------
		IF p_location_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'Location identifier must not be null.');
		END IF;

		IF p_url_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'URL identifier must not be null.');
		END IF;

		------------------------------
		-- see if the record exists --
		------------------------------
		l_rec.location_code := get_location_code (p_office_id, p_location_id);
		l_rec.url_id := p_url_id;

		BEGIN
			SELECT	*
			  INTO	l_rec
			  FROM	at_location_url
			 WHERE	location_code = l_rec.location_code
						AND url_id = l_rec.url_id;

			l_exists := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_exists := FALSE;
		END;

		IF l_exists
		THEN
			IF l_fail_if_exists
			THEN
				cwms_err.raise (
					'ITEM_ALREADY_EXISTS',
					'CWMS Location URL',
						NVL (UPPER (p_office_id), cwms_util.user_office_id)
					|| '/'
					|| p_location_id
					|| '/'
					|| p_url_id
				);
			END IF;
		ELSE
			IF p_url_address IS NULL
			THEN
				cwms_err.raise ('ERROR',
									 'URL address must not be null on new record.'
									);
			END IF;
		END IF;

		-------------------------
		-- populate the record --
		-------------------------
		IF p_url_address IS NOT NULL
		THEN
			l_rec.url_address := p_url_address;
		END IF;

		IF p_url_title IS NOT NULL OR NOT l_ignore_nulls
		THEN
			l_rec.url_title := p_url_title;
		END IF;

		---------------------------------
		-- insert or update the record --
		---------------------------------
		IF l_exists
		THEN
			UPDATE	at_location_url
				SET	row = l_rec
			 WHERE	location_code = l_rec.location_code
						AND url_id = l_rec.url_id;
		ELSE
			INSERT INTO   at_location_url
				  VALUES   l_rec;
		END IF;
	END store_url;

	PROCEDURE retrieve_url (p_url_address		 OUT VARCHAR2,
									p_url_title 		 OUT VARCHAR2,
									p_location_id	 IN	  VARCHAR2,
									p_url_id 		 IN	  VARCHAR2,
									p_office_id 	 IN	  VARCHAR2 DEFAULT NULL
								  )
	IS
		l_rec   at_location_url%ROWTYPE;
	BEGIN
		-------------------
		-- sanity checks --
		-------------------
		IF p_location_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'Location identifier must not be null.');
		END IF;

		IF p_url_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'URL identifier must not be null.');
		END IF;

		-------------------------
		-- retrieve the record --
		-------------------------
		l_rec.location_code := get_location_code (p_office_id, p_location_id);
		l_rec.url_id := p_url_id;

		BEGIN
			SELECT	*
			  INTO	l_rec
			  FROM	at_location_url
			 WHERE	location_code = l_rec.location_code
						AND url_id = l_rec.url_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ITEM_DOES_NOT_EXIST',
					'CWMS Location URL',
						NVL (UPPER (p_office_id), cwms_util.user_office_id)
					|| '/'
					|| p_location_id
					|| '/'
					|| p_url_id
				);
		END;

		---------------------------
		-- set the out variables --
		---------------------------
		p_url_address := l_rec.url_address;
		p_url_title := l_rec.url_title;
	END retrieve_url;

	PROCEDURE delete_url (p_location_id   IN VARCHAR2,
								 p_url_id		  IN VARCHAR2, 		-- NULL = all urls
								 p_office_id	  IN VARCHAR2 DEFAULT NULL
								)
	IS
	BEGIN
		-------------------
		-- sanity checks --
		-------------------
		IF p_location_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'Location identifier must not be null.');
		END IF;

		---------------------
		-- delete the urls --
		---------------------
		BEGIN
			DELETE FROM   at_location_url
					WHERE   location_code =
								  get_location_code (p_office_id, p_location_id)
							  AND url_id = NVL (p_url_id, url_id);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ITEM_DOES_NOT_EXIST',
					'CWMS Location URL',
						NVL (UPPER (p_office_id), cwms_util.user_office_id)
					|| '/'
					|| p_location_id
					|| '/'
					|| NVL (p_url_id, '<any>')
				);
		END;
	END delete_url;

	PROCEDURE rename_url (p_location_id   IN VARCHAR2,
								 p_old_url_id	  IN VARCHAR2,
								 p_new_url_id	  IN VARCHAR2,
								 p_office_id	  IN VARCHAR2 DEFAULT NULL
								)
	IS
	BEGIN
		-------------------
		-- sanity checks --
		-------------------
		IF p_location_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'Location identifier must not be null.');
		END IF;

		IF p_old_url_id IS NULL
		THEN
			cwms_err.raise ('ERROR',
								 'Existing URL identifier must not be null.'
								);
		END IF;

		IF p_new_url_id IS NULL
		THEN
			cwms_err.raise ('ERROR', 'New URL identifier must not be null.');
		END IF;

		--------------------
		-- rename the url --
		--------------------
		BEGIN
			UPDATE	at_location_url
				SET	url_id = p_new_url_id
			 WHERE	location_code =
							get_location_code (p_office_id, p_location_id)
						AND url_id = p_old_url_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ITEM_DOES_NOT_EXIST',
					'CWMS Location URL',
						NVL (UPPER (p_office_id), cwms_util.user_office_id)
					|| '/'
					|| p_location_id
					|| '/'
					|| p_old_url_id
				);
		END;
	END rename_url;

	PROCEDURE cat_urls (p_url_catalog			  OUT SYS_REFCURSOR,
							  p_location_id_mask   IN		VARCHAR2 DEFAULT '*',
							  p_url_id_mask		  IN		VARCHAR2 DEFAULT '*',
							  p_url_address_mask   IN		VARCHAR2 DEFAULT '*',
							  p_url_title_mask	  IN		VARCHAR2 DEFAULT '*',
							  p_office_id_mask	  IN		VARCHAR2 DEFAULT NULL
							 )
	IS
		l_location_id_mask	VARCHAR2 (49);
		l_url_id_mask			VARCHAR2 (32);
		l_url_address_mask	VARCHAR2 (1024);
		l_url_title_mask		VARCHAR2 (256);
		l_office_id_mask		VARCHAR2 (16);
	BEGIN
		----------------------
		-- set up the masks --
		----------------------
		l_location_id_mask :=
			cwms_util.normalize_wildcards (UPPER (p_location_id_mask));
		l_url_id_mask := cwms_util.normalize_wildcards (UPPER (p_url_id_mask));
		l_url_address_mask :=
			cwms_util.normalize_wildcards (UPPER (p_url_address_mask));
		l_url_title_mask :=
			cwms_util.normalize_wildcards (UPPER (p_url_title_mask));
		l_office_id_mask :=
			cwms_util.normalize_wildcards (
				UPPER (NVL (p_url_address_mask, cwms_util.user_office_id))
			);

		-----------------------
		-- perform the query --
		-----------------------
		OPEN p_url_catalog FOR
			SELECT	  o.office_id,
						  bl.base_location_id || SUBSTR ('-', 1, LENGTH (pl.sub_location_id)) || pl.sub_location_id AS location_id,
						  lu.url_id, lu.url_address, lu.url_title
				 FROM   at_location_url lu,
						  at_physical_location pl,
						  at_base_location bl,
						  cwms_office o
				WHERE 		o.office_id LIKE l_office_id_mask ESCAPE '\'
						  AND bl.db_office_code = o.office_code
						  AND pl.base_location_code = bl.base_location_code
						  AND UPPER (
										bl.base_location_id
									|| SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
									|| pl.sub_location_id
								) LIKE
									l_location_id_mask ESCAPE '\'
						  AND lu.location_code = pl.location_code
						  AND UPPER (lu.url_id) LIKE l_url_id_mask ESCAPE '\'
						  AND UPPER (lu.url_address) LIKE
									l_url_address_mask ESCAPE '\'
						  AND UPPER (lu.url_title) LIKE l_url_title_mask ESCAPE '\'
			ORDER BY   o.office_id,
						  bl.base_location_id,
						  pl.sub_location_id NULLS FIRST,
						  lu.url_id;
	END cat_urls;

	FUNCTION cat_urls_f (p_location_id_mask	IN VARCHAR2 DEFAULT '*',
								p_url_id_mask			IN VARCHAR2 DEFAULT '*',
								p_url_address_mask	IN VARCHAR2 DEFAULT '*',
								p_url_title_mask		IN VARCHAR2 DEFAULT '*',
								p_office_id_mask		IN VARCHAR2 DEFAULT NULL
							  )
		RETURN SYS_REFCURSOR
	IS
		l_cursor   SYS_REFCURSOR;
	BEGIN
		cat_urls (l_cursor,
					 p_location_id_mask,
					 p_url_id_mask,
					 p_url_address_mask,
					 p_url_title_mask,
					 p_office_id_mask
					);

		RETURN l_cursor;
	END cat_urls_f;

   function get_location_type(
      p_location_code in number)
      return varchar2
   is
      l_table_types str_tab_tab_t := str_tab_tab_t(
         str_tab_t('AT_BASIN',      'BASIN_LOCATION_CODE',      'BASIN'),
         str_tab_t('AT_STREAM',     'STREAM_LOCATION_CODE',     'STREAM'),
         str_tab_t('AT_OUTLET',     'OUTLET_LOCATION_CODE',     'OUTLET'),
         str_tab_t('AT_TURBINE',    'TURBINE_LOCATION_CODE',    'TURBINE'),
         str_tab_t('AT_EMBANKMENT', 'EMBANKMENT_LOCATION_CODE', 'EMBANKMENT'),
         str_tab_t('AT_LOCK',       'LOCK_LOCATION_CODE',       'LOCK'),
         str_tab_t('AT_PROJECT',    'PROJECT_LOCATION_CODE',    'PROJECT'));
      l_type_names  str_tab_t := str_tab_t();
      l_count       pls_integer;
   begin
      for i in 1..l_table_types.count loop
         execute immediate 'select count(*) from '||l_table_types(i)(1)||' where '||l_table_types(i)(2)||' = :1'
            into l_count
           using p_location_code;
         if l_count = 1 then
            l_type_names.extend;
            l_type_names(l_type_names.count) := l_table_types(i)(3);
         end if;                                
      end loop;
      case l_type_names.count
         when 0 then return 'NONE';
         when 1 then return l_type_names(1);
         else cwms_err.raise('ERROR', 'Location has multiple types: '||cwms_util.join_text(l_type_names, ', '));
      end case;
   end get_location_type;

   function get_location_type(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return get_location_type(cwms_loc.get_location_code(p_office_id, p_location_id));
   end get_location_type;

   function get_vertcon_offset(
      p_lat in binary_double,
      p_lon in binary_double)
      return binary_double
      deterministic
   is           
      l_missing        constant binary_double := 9999;
      l_file_names     str_tab_t; 
      l_data_set_codes double_tab_t;
      l_min_lat        binary_double;
      l_min_lon        binary_double;
      l_delta_lat      binary_double;
      l_delta_lon      binary_double; 
      -------------------------------------
      -- variables below are named after --
      -- variables in vertcon.for source --
      -------------------------------------
      x                binary_double;
      y                binary_double;
      i                binary_integer;
      j                binary_integer;
      t1               binary_double;
      t2               binary_double;
      t3               binary_double;
      t4               binary_double;
      a                binary_double;
      b                binary_double;
      c                binary_double;
      d                binary_double;
      row              binary_double;
      col              binary_double;
      z1               binary_double;
      z2               binary_double;
      z3               binary_double;
      z4               binary_double;
      z                binary_double;
   begin
      begin
         select dataset_id,
                dataset_code
           bulk collect
           into l_file_names,
                l_data_set_codes
           from cwms_vertcon_header
          where p_lat >= min_lat
            and p_lat <= max_lat
            and p_lon >= min_lon
            and p_lon <= max_lon - margin; 
                              
         select min_lat,
                min_lon,
                delta_lat,
                delta_lon
           into l_min_lat,
                l_min_lon,
                l_delta_lat,
                l_delta_lon
           from cwms_vertcon_header
          where dataset_code = l_data_set_codes(1);       
      exception
         when no_data_found then
            cwms_err.raise('ERROR', 'No VERTCON data found for lat, lon : '||p_lat||', '||p_lon);
      end;
      ------------------------------------------------
      -- variables xgrid and ygrid from vertcon.for --
      ------------------------------------------------
      x := (p_lon - l_min_lon) / l_delta_lon + 1;
      y := (p_lat - l_min_lat) / l_delta_lat + 1;   
      ----------------------------------------------   
      -- variables irow and jcol from vertcon.for --
      ----------------------------------------------   
      i := trunc(y);
      j := trunc(x);
      -----------------------------------------------------------
      -- variables tee1, tee2, tee2, and tee4 from vertcon.for --
      -----------------------------------------------------------
      select table_val into t1 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i   and table_col = j;
      select table_val into t2 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i+1 and table_col = j;
      select table_val into t3 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i   and table_col = j+1;
      select table_val into t4 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i+1 and table_col = j+1;

      if t1 = l_missing or t2 = l_missing or t3 = l_missing or t4 = l_missing then
         cwms_err.raise('ERROR', 'Cannot compute datum shift due to missing value in grid');
      end if;
      ------------------------------------------------------
      -- variables ay, bee, cee, and dee from vertcon.for --
      ------------------------------------------------------
      a := t1;                          
      b := t3-t1;
      c := t2-t1;
      d := t4-t3-t2+t1;               
      ----------------------------------   
      -- same names as in vertcon.for --
      ----------------------------------   
      row := y - i;
      col := x - j;
      ----------------------------------------------------------------                                 
      -- variables zee1, zee2, zee3, zee4, and zee from vertcon.for --
      ----------------------------------------------------------------                                 
      z1 := a;
      z2 := b*col;
      z3 := c*row;
      z4 := d*col*row;
      z  := z1 + z2 + z3 + z4;
      
      return z / 1000.;
   end get_vertcon_offset;

   function get_vertical_datum_offset_row(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date       in date,
      p_time_zone            in varchar2,
      p_match_effective_date in varchar2 default 'F',
      p_office_id            in varchar2 default null)
      return urowid
   is
      l_rowid urowid;
      l_location_code number(10);
      l_vertical_datum_id_1 varchar2(16);
      l_vertical_datum_id_2 varchar2(16);
      l_effective_date_utc  date;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_1);
      end if;
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_2);
      end if;
      if p_effective_date is null then
         cwms_err.raise('NULL_ARGUMENT', p_effective_date);
      end if;
      -----------------
      -- do the work --
      -----------------
      l_vertical_datum_id_1 := upper(p_vertical_datum_id_1);
      l_vertical_datum_id_2 := upper(p_vertical_datum_id_2);
      l_location_code       := cwms_loc.get_location_code(p_office_id, p_location_id);
      l_effective_date_utc  := cwms_util.change_timezone(
         p_effective_date, 
         nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code)), 
         'UTC');
      begin
         if cwms_util.is_true(p_match_effective_date) then
            --------------------------
            -- exact effective date --
            --------------------------
            select rowid
              into l_rowid
              from at_vert_datum_offset
             where location_code = l_location_code
               and vertical_datum_id_1 = l_vertical_datum_id_1
               and vertical_datum_id_2 = l_vertical_datum_id_2
               and effective_date = l_effective_date_utc;
         else
            -----------------------------------------------
            -- latest effective date not after specified --
            -----------------------------------------------
            select rowid
              into l_rowid
              from at_vert_datum_offset
             where location_code = l_location_code
               and vertical_datum_id_1 = l_vertical_datum_id_1
               and vertical_datum_id_2 = l_vertical_datum_id_2
               and effective_date = (select max(effective_date)
                                       from at_vert_datum_offset
                                      where location_code = l_location_code
                                        and vertical_datum_id_1 = l_vertical_datum_id_1
                                        and vertical_datum_id_2 = l_vertical_datum_id_2
                                        and effective_date <= l_effective_date_utc
                                    );
         end if;
      exception
         when no_data_found then null;
      end;      
      return l_rowid;
   end get_vertical_datum_offset_row;
   
   procedure store_vertical_datum_offset(
      p_location_id         in varchar2,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_offset              in binary_double,
      p_unit                in varchar2,
      p_effective_date      in date     default date '1000-01-01',
      p_time_zone           in varchar2 default null,
      p_description         in varchar2 default null,
      p_fail_if_exists      in varchar2 default 'T',
      p_office_id           in varchar2 default null)
   is
      l_rowid          urowid;
      l_fail_if_exists boolean := cwms_util.is_true(p_fail_if_exists);
      l_effective_date date := p_effective_date; 
      l_time_zone      varchar2(28) := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
      l_reversed       boolean := false;
      l_delete         boolean := false;
      l_insert         boolean := false;
      l_update         boolean := false;
   begin               
      ---------------------------
      -- normalize cookie date --
      ---------------------------
      if abs(l_effective_date - date '1000-01-01') < 1 then
         l_effective_date := date '1000-01-01';
         l_time_zone := 'UTC';
      end if;               
      -------------------------------------------------
      -- get the existing record if it already exits --
      -------------------------------------------------
      l_rowid := get_vertical_datum_offset_row(
         p_location_id, 
         p_vertical_datum_id_1, 
         p_vertical_datum_id_2, 
         l_effective_date, 
         l_time_zone, 
         'T', 
         p_office_id);
      if l_rowid is null then
         ------------------------------------------ 
         -- get the reversed record if it exists --
         ------------------------------------------ 
         l_rowid := get_vertical_datum_offset_row(
            p_location_id, 
            p_vertical_datum_id_2, 
            p_vertical_datum_id_1, 
            l_effective_date, 
            l_time_zone, 
            'T', 
            p_office_id);
         l_reversed := l_rowid is not null;            
      end if;
      if l_rowid is null then
         --------------------------
         -- record doesn't exist --
         --------------------------
         l_insert := true;
      else
         -------------------
         -- record exists --
         -------------------
         if l_fail_if_exists then
            if l_reversed then
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'CWMS Vertical Datum Offset',
                  cwms_util.get_db_office_id(p_office_id)
                  ||'/'||p_location_id
                  ||'/'||upper(p_vertical_datum_id_2)
                  ||'/'||upper(p_vertical_datum_id_1)
                  ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
                  ||'('||l_time_zone
                  ||')');
            else
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'CWMS Vertical Datum Offset',
                  cwms_util.get_db_office_id(p_office_id)
                  ||'/'||p_location_id
                  ||'/'||upper(p_vertical_datum_id_1)
                  ||'/'||upper(p_vertical_datum_id_2)
                  ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
                  ||'('||l_time_zone
                  ||')');
            end if;
         end if;
         if l_reversed then
            l_delete := true;
            l_insert := true;
         else                
            l_update := true;
         end if;
      end if;
      if l_update then
            update at_vert_datum_offset
               set offset = cwms_util.convert_units(p_offset, p_unit, 'm'),
                   description = p_description 
             where rowid = l_rowid;
      elsif l_insert then
         if l_delete then
            delete 
              from at_vert_datum_offset
             where rowid = l_rowid; 
         end if;
         insert
           into at_vert_datum_offset
         values (cwms_loc.get_location_code(p_office_id, p_location_id),
                 upper(p_vertical_datum_id_1),
                 upper(p_vertical_datum_id_2),
                 cwms_util.change_timezone(
                    l_effective_date, 
                    l_time_zone, 
                    'UTC'),
                 cwms_util.convert_units(p_offset, p_unit, 'm'),
                 p_description
                );
      end if;
    end store_vertical_datum_offset;
      
   procedure store_vertical_datum_offset(
      p_vertical_datum_offset in vert_datum_offset_t,
      p_fail_if_exists        in varchar2 default 'T')
   is
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_vertical_datum_offset is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_vertical_datum_offset');
      end if;   
      -----------------
      -- do the work --
      -----------------
      store_vertical_datum_offset(
         p_location_id         => p_vertical_datum_offset.location.get_location_id,
         p_vertical_datum_id_1 => p_vertical_datum_offset.vertical_datum_id_1,
         p_vertical_datum_id_2 => p_vertical_datum_offset.vertical_datum_id_2,
         p_offset              => p_vertical_datum_offset.offset,
         p_unit                => p_vertical_datum_offset.unit,
         p_effective_date      => p_vertical_datum_offset.effective_date,
         p_time_zone           => p_vertical_datum_offset.time_zone,
         p_description         => p_vertical_datum_offset.description,
         p_fail_if_exists      => p_fail_if_exists,
         p_office_id           => p_vertical_datum_offset.location.office_id);
   end store_vertical_datum_offset;
      
   procedure retrieve_vertical_datum_offset(
      p_offset               out binary_double,
      p_unit_out             out varchar2,
      p_description          out varchar2,
      p_effective_date_out   out date,
      p_location_id          in  varchar2,
      p_vertical_datum_id_1  in  varchar2,
      p_vertical_datum_id_2  in  varchar2,
      p_effective_date_in    in  date     default null,
      p_time_zone            in  varchar2 default null,
      p_unit_in              in  varchar2 default null,
      p_match_effective_date in  varchar2 default 'F',
      p_office_id            in  varchar2 default null)
   is
      l_rowid          urowid;
      l_effective_date date;
      l_time_zone      varchar2(28);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;   
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_1);
      end if;   
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_2);
      end if;   
      -----------------
      -- do the work --
      -----------------
      l_effective_date := nvl(p_effective_date_in, sysdate);
      l_time_zone := case p_effective_date_in is null
                        when true then 'UTC'
                        else nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id))
                     end;      
      l_rowid := get_vertical_datum_offset_row(
         p_location_id          => p_location_id,
         p_vertical_datum_id_1  => p_vertical_datum_id_1,
         p_vertical_datum_id_2  => p_vertical_datum_id_2,
         p_effective_date       => l_effective_date,
         p_time_zone            => l_time_zone,
         p_match_effective_date => p_match_effective_date,
         p_office_id            => p_office_id); 
      if l_rowid is null then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS Vertical Datum Offset',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||upper(p_vertical_datum_id_1)
            ||'/'||upper(p_vertical_datum_id_2)
            ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
            ||'('||l_time_zone
            ||')');
      end if;             
      select case 
                when p_unit_in is null then offset
                else cwms_util.convert_units(offset, 'm', p_unit_in)
             end,
             nvl(p_unit_in, 'm'),
             description 
        into p_offset,
             p_unit_out,
             p_description 
        from at_vert_datum_offset
       where rowid = l_rowid;
   end retrieve_vertical_datum_offset;
      
   function retrieve_vertical_datum_offset(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date_in    in date     default null,
      p_time_zone            in varchar2 default null,
      p_unit                 in varchar2 default null,
      p_match_effective_date in varchar2 default 'F',
      p_office_id            in varchar2 default null)
      return vert_datum_offset_t
   is
      l_offset             binary_double;
      l_unit_out           varchar2(16);
      l_description        varchar2(64);
      l_effective_date_out date;
   begin     
      retrieve_vertical_datum_offset(
         p_offset               => l_offset,
         p_unit_out             => l_unit_out,
         p_description          => l_description,
         p_effective_date_out   => l_effective_date_out,
         p_location_id          => p_location_id,
         p_vertical_datum_id_1  => p_vertical_datum_id_1,
         p_vertical_datum_id_2  => p_vertical_datum_id_2,
         p_effective_date_in    => p_effective_date_in,
         p_time_zone            => p_time_zone,
         p_unit_in              => p_unit,
         p_match_effective_date => p_match_effective_date,
         p_office_id            => p_office_id);
         
      return vert_datum_offset_t(
         location_ref_t(p_location_id, p_office_id),
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         l_effective_date_out,
         case p_effective_date_in is null
            when true then 'UTC'
            else nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id))
         end,  
         l_offset,
         l_unit_out,
         l_description);
                     
   end retrieve_vertical_datum_offset;
      
   procedure delete_vertical_datum_offset(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date_in    in date     default null,
      p_time_zone            in varchar2 default null,
      p_match_effective_date in varchar2 default 'T',
      p_office_id            in varchar2 default null)
   is
      l_rowid          urowid;
      l_effective_date date;
      l_time_zone      varchar2(28);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;   
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_1);
      end if;   
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_2);
      end if;   
      -----------------
      -- do the work --
      -----------------
      l_effective_date := nvl(p_effective_date_in, sysdate);
      l_time_zone := case p_effective_date_in is null
                        when true then 'UTC'
                        else nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id))
                     end;      
      l_rowid := get_vertical_datum_offset_row(
         p_location_id          => p_location_id,
         p_vertical_datum_id_1  => p_vertical_datum_id_1,
         p_vertical_datum_id_2  => p_vertical_datum_id_2,
         p_effective_date       => l_effective_date,
         p_time_zone            => l_time_zone,
         p_match_effective_date => p_match_effective_date,
         p_office_id            => p_office_id); 
      if l_rowid is null then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS Vertical Datum Offset',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||upper(p_vertical_datum_id_1)
            ||'/'||upper(p_vertical_datum_id_2)
            ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
            ||'('||l_time_zone
            ||')');
      end if;
      
      delete from at_vert_datum_offset where rowid = l_rowid;
                   
   end delete_vertical_datum_offset;
      
   procedure get_vertical_datum_offset(   
      p_offset              out binary_double, 
      p_effective_date      out date,
      p_estimate            out varchar2,
      p_location_code       in  number,
      p_vertical_datum_id_1 in  varchar2,   
      p_vertical_datum_id_2 in  varchar2,
      p_datetime_utc        in  date default sysdate) 
   is       
      pragma autonomous_transaction; -- for inserting VERTCON offset estimate
      l_offset              binary_double;
      l_effective_date      date;
      l_vertical_datum_id_1 varchar2(16);
      l_vertical_datum_id_2 varchar2(16);
      l_description         varchar2(64);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_code is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_location_code');
      end if;
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_vertical_datum_id_1');
      end if;
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_vertical_datum_id_2');
      end if;
      if p_datetime_utc is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_datetime_utc'); 
      end if;
      -----------------
      -- do the work --
      -----------------    
      l_vertical_datum_id_1 := upper(p_vertical_datum_id_1);
      l_vertical_datum_id_2 := upper(p_vertical_datum_id_2);
      if l_vertical_datum_id_2 = l_vertical_datum_id_1 then
         ----------------------
         -- identity mapping --
         ----------------------
         l_offset := 0;
         l_effective_date := date '1000-01-01';
      end if;
      if l_offset is null then
         begin     
            -------------------------------------------------
            -- generate a 29->88 estimate if it might help --
            -------------------------------------------------
            if (l_vertical_datum_id_1 in ('NGVD29', 'NAVD88')  or 
                l_vertical_datum_id_2 in ('NGVD29', 'NAVD88')) and not
               (l_vertical_datum_id_1 in ('NGVD29', 'NAVD88')  and 
                l_vertical_datum_id_2 in ('NGVD29', 'NAVD88')) 
            then
               get_vertical_datum_offset(
                  l_offset,
                  l_effective_date,
                  l_description,
                  p_location_code,
                  'NGVD29',
                  'NAVD88');
               l_offset := null;
               l_effective_date := null;
               l_description := null;               
            end if;
            --------------------------------------
            -- search for the specified mapping --
            --------------------------------------
            select offset,
                   effective_date,
                   description
              into l_offset,
                   l_effective_date,
                   l_description
              from at_vert_datum_offset
             where location_code = p_location_code
               and vertical_datum_id_1 = l_vertical_datum_id_1  
               and vertical_datum_id_2 = l_vertical_datum_id_2
               and effective_date = (select max(effective_date)
                                       from at_vert_datum_offset  
                                      where location_code = p_location_code
                                        and vertical_datum_id_1 = l_vertical_datum_id_1  
                                        and vertical_datum_id_2 = l_vertical_datum_id_2
                                        and effective_date <= p_datetime_utc
                                    );
         exception
            when no_data_found then null;
         end;
         if l_offset is null then
            ------------------------------------
            -- search for the reverse mapping --
            ------------------------------------
            begin
               select offset,
                      effective_date,
                      description
                 into l_offset,
                      l_effective_date,
                      l_description
                 from at_vert_datum_offset
                where location_code = p_location_code
                  and vertical_datum_id_1 = l_vertical_datum_id_2  
                  and vertical_datum_id_2 = l_vertical_datum_id_1
                  and effective_date = (select max(effective_date)
                                          from at_vert_datum_offset  
                                         where location_code = p_location_code
                                           and vertical_datum_id_1 = l_vertical_datum_id_2  
                                           and vertical_datum_id_2 = l_vertical_datum_id_1
                                           and effective_date <= p_datetime_utc
                                       );
               l_offset := -l_offset;
            exception
               when no_data_found then null;
            end;
         end if;
      end if;
      if l_offset is null then
         -------------------------------------------------------------------------
         -- search for any indirect mappings separated by a single common datum --
         -------------------------------------------------------------------------
         for rec_1 in (
            select v1.vertical_datum_id_1,
                   v1.vertical_datum_id_2,
                   v1.offset,
                   v1.effective_date,
                   v1.description
              from at_vert_datum_offset v1
             where location_code = p_location_code
               and (v1.vertical_datum_id_1 = l_vertical_datum_id_1 or v1.vertical_datum_id_2 = l_vertical_datum_id_1)
               and effective_date = (select max(effective_date)
                                       from at_vert_datum_offset
                                      where location_code = p_location_code
                                        and vertical_datum_id_1 = v1.vertical_datum_id_1
                                        and vertical_datum_id_2 = v1.vertical_datum_id_2
                                        and effective_date <= p_datetime_utc
                                    )
                    )
         loop                                                                                             
            for rec_2 in (
               select v2.vertical_datum_id_1,
                      v2.vertical_datum_id_2,
                      v2.offset,
                      v2.effective_date,
                      v2.description
                 from at_vert_datum_offset v2
                where location_code = p_location_code
                  and (v2.vertical_datum_id_1 = l_vertical_datum_id_2 or v2.vertical_datum_id_2 = l_vertical_datum_id_2)
                  and effective_date = (select max(effective_date)
                                          from at_vert_datum_offset
                                         where location_code = p_location_code
                                           and vertical_datum_id_1 = v2.vertical_datum_id_1
                                           and vertical_datum_id_2 = v2.vertical_datum_id_2
                                           and effective_date <= p_datetime_utc
                                       )
                       )
            loop
               if rec_1.vertical_datum_id_1 = l_vertical_datum_id_1 then
                  if rec_2.vertical_datum_id_1 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_2 = rec_1.vertical_datum_id_2 then
                        --------------------------------------------
                        -- datum_1 ==> common; datum_2 ==> common --
                        --------------------------------------------
                        l_offset := rec_1.offset - rec_2.offset;
                     end if; 
                  elsif rec_2.vertical_datum_id_2 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_1 = rec_1.vertical_datum_id_2 then
                        --------------------------------------------
                        -- datum_1 ==> common; common ==> datum_2 --
                        --------------------------------------------
                        l_offset := rec_1.offset + rec_2.offset;
                     end if; 
                  end if;
               elsif rec_1.vertical_datum_id_2 = l_vertical_datum_id_1 then
                  if rec_2.vertical_datum_id_1 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_2 = rec_1.vertical_datum_id_1 then
                        --------------------------------------------
                        -- common ==> datum_1; datum_2 ==> common --
                        --------------------------------------------
                        l_offset := -rec_1.offset - rec_2.offset;
                     end if; 
                  elsif rec_2.vertical_datum_id_2 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_1 = rec_1.vertical_datum_id_1 then
                        --------------------------------------------
                        -- common ==> datum_1; common ==> datum_2 --
                        --------------------------------------------
                        l_offset := -rec_1.offset + rec_2.offset;
                     end if; 
                  end if;
               end if; 
               if l_offset is not null then
                  l_effective_date := greatest(rec_1.effective_date, rec_2.effective_date);
                  if rec_1.description is not null and instr(upper(rec_1.description), 'ESTIMATE') > 0 then
                     l_description := rec_1.description;
                  else
                     l_description := rec_2.description;
                  end if;
                  exit;
               end if;
            end loop;
            exit when l_offset is not null;                                      
         end loop;                                      
      end if;
      if l_offset is null then
         if l_vertical_datum_id_1 in ('NGVD29', 'NAVD88') and 
            l_vertical_datum_id_2 in ('NGVD29', 'NAVD88')
         then
            ---------------------------------------------
            -- estimate offset using VERTCON algorithm --
            ---------------------------------------------
            declare
               l_lat binary_double;
               l_lon binary_double;
            begin    
               select latitude,
                      longitude
                 into l_lat,
                      l_lon
                 from cwms_v_loc
                where location_code = p_location_code
                  and unit_system = 'SI';
                
               if l_lat is not null and l_lon is not null then
                  l_offset := get_vertcon_offset(l_lat, l_lon);
                  l_effective_date := date '1000-01-01';
                  l_description := 'VERTCON ESTIMATE';
                  insert
                    into at_vert_datum_offset
                  values (p_location_code,
                          'NGVD29',
                          'NAVD88',
                          l_effective_date,
                          l_offset,
                          l_description);
                  if l_vertical_datum_id_1 = 'NAVD88' then
                     l_offset := -l_offset;
                  end if;
                  commit;                               
               end if;                
            exception
               when no_data_found then null;
            end;
         end if;           
      end if;
      if l_offset is null then 
         ---------------------
         -- declare failure --
         ---------------------
         declare
            l_location location_ref_t := location_ref_t(p_location_code);
         begin
            cwms_err.raise(
               'ERROR',
               'No vertical offset exists for '
               ||l_location.get_office_id
               ||'/'
               ||l_location.get_location_id
               ||' from '
               ||l_vertical_datum_id_1
               ||' to '
               ||l_vertical_datum_id_2);              
         end;
      end if;
      p_offset := l_offset;
      p_effective_date := l_effective_date;
      if l_description is null or instr(upper(l_description), 'ESTIMATE') = 0 then
         p_estimate := 'F';
      else
         p_estimate := 'T';
      end if; 
   end get_vertical_datum_offset; 
      
   function get_vertical_datum_offsets(
      p_location_code       in number,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_start_time_utc      in date,
      p_end_time_utc        in date)
      return ztsv_array
   is 
      l_offsets ztsv_array;
   begin
      get_vertical_datum_offsets(  
         l_offsets,
         p_location_code,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         p_start_time_utc,
         p_end_time_utc);
         
      return l_offsets;
   end get_vertical_datum_offsets;        

   procedure get_vertical_datum_offsets(  
      p_offsets             out ztsv_array,
      p_location_code       in  number,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_start_time_utc      in  date,
      p_end_time_utc        in  date)
   is
      l_offsets        ztsv_array;
      l_offsets2       ztsv_array;
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_start_time_utc is null then
         cwms_err.raise('NULL_ARGUMENT', p_start_time_utc);
      end if;
      if p_end_time_utc is null then
         cwms_err.raise('NULL_ARGUMENT', p_end_time_utc);
      end if;
      if p_end_time_utc < p_start_time_utc then
         cwms_err.raise('ERROR', 'End time must be be earlier than start time.');
      end if;
      -----------------
      -- do the work --
      -----------------    
      l_effective_date := p_end_time_utc;
      loop           
         begin
            get_vertical_datum_offset(   
               l_offset, 
               l_effective_date,
               l_estimate,
               p_location_code,
               p_vertical_datum_id_1,   
               p_vertical_datum_id_2,
               l_effective_date); 
            if l_offsets is null then
               l_offsets := ztsv_array();
               l_offsets.extend;
            end if;               
            l_offsets(l_offsets.count) := ztsv_type(l_effective_date, l_offset, null);
            exit when l_effective_date < p_start_time_utc;
            l_effective_date := l_effective_date - 1 / 86400;
         exception
            when others then exit;
         end;
      end loop;
      if l_offsets is not null then
         l_offsets2 := ztsv_array();
         l_offsets2.extend(l_offsets.count);
         for i in 1..l_offsets.count loop
            l_offsets2(i) := l_offsets(l_offsets.count+1-i);
         end loop;
      end if;
      p_offsets := l_offsets2;
   end get_vertical_datum_offsets;        

   function get_vertical_datum_offset(
      p_location_code       in number,
      p_vertical_datum_id_1 in varchar2,   
      p_vertical_datum_id_2 in varchar2, 
      p_datetime_utc        in date     default sysdate,
      p_unit                in varchar2 default null)
      return binary_double
   is
      l_offset         binary_double;
      l_effective_date date;  
      l_estimate       varchar2(1);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_code is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_code);
      end if;
      -----------------
      -- do the work --
      -----------------    
      get_vertical_datum_offset(
          p_offset              => l_offset,
          p_effective_date      => l_effective_date,
          p_estimate            => l_estimate,
          p_location_code       => p_location_code,
          p_vertical_datum_id_1 => p_vertical_datum_id_1,   
          p_vertical_datum_id_2 => p_vertical_datum_id_2,
          p_datetime_utc        => p_datetime_utc);
      if p_unit is not null then
         l_offset := cwms_util.convert_units(l_offset, 'm', p_unit);
      end if;
      return l_offset;
   end get_vertical_datum_offset;   
      
   function get_vertical_datum_offset(
      p_location_id         in varchar,
      p_vertical_datum_id_1 in varchar2,   
      p_vertical_datum_id_2 in varchar2,
      p_datetime            in date     default null,
      p_time_zone           in varchar2 default null,
      p_unit                in varchar2 default null,
      p_office_id           in varchar2 default null)
      return binary_double
   is
      l_offset         binary_double;
      l_effective_date date;  
      l_estimate       varchar2(1);
   begin
      get_vertical_datum_offset(
         l_offset,
         l_effective_date,
         l_estimate,
         p_location_id,
         p_vertical_datum_id_1,   
         p_vertical_datum_id_2,
         p_datetime,
         p_time_zone,
         p_unit,
         p_office_id);
      return l_offset;         
   end get_vertical_datum_offset;   
      
   procedure get_vertical_datum_offset(
      p_offset              out binary_double,
      p_effective_date      out date,
      p_estimate            out varchar2,
      p_location_id         in  varchar,
      p_vertical_datum_id_1 in  varchar2,   
      p_vertical_datum_id_2 in  varchar2,
      p_datetime            in  date     default null,
      p_time_zone           in  varchar2 default null,
      p_unit                in  varchar2 default null,
      p_office_id           in  varchar2 default null)
   is
      l_location_code  number(10);
      l_timezone       varchar2(28);
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      -----------------
      -- do the work --
      -----------------    
      l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
      l_timezone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      get_vertical_datum_offset(
         l_offset,
         l_effective_date,
         l_estimate,
         l_location_code,
         p_vertical_datum_id_1,   
         p_vertical_datum_id_2,
         nvl(cwms_util.change_timezone(p_datetime, l_timezone, 'UTC'), sysdate));
      if p_unit is null then
         p_offset := l_offset;
      else
         p_offset := cwms_util.convert_units(l_offset, 'm', p_unit);
      end if; 
      p_effective_date := cwms_util.change_timezone(l_effective_date, 'UTC', l_timezone);
      p_estimate := l_estimate;
      
   end get_vertical_datum_offset;   
      
   function get_vertical_datum_offsets(
      p_location_id         in varchar,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_start_time          in date,
      p_end_time            in date,
      p_time_zone           in varchar2 default null,
      p_unit                in varchar2 default null,
      p_office_id           in varchar2 default null)
      return ztsv_array
   is
      l_offsets ztsv_array;
   begin
      get_vertical_datum_offsets(
         l_offsets,
         p_location_id,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         p_start_time,
         p_end_time,
         p_time_zone,
         p_unit,
         p_office_id);
      return l_offsets;         
   end get_vertical_datum_offsets;        
      
   procedure get_vertical_datum_offsets(
      p_offsets             out ztsv_array,
      p_location_id         in  varchar,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_start_time          in  date,
      p_end_time            in  date,
      p_time_zone           in  varchar2 default null,
      p_unit                in  varchar2 default null,
      p_office_id           in  varchar2 default null)
   is
      l_location_code  number(10);
      l_timezone       varchar2(28);
      l_offsets        ztsv_array;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      -----------------
      -- do the work --
      -----------------    
      l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
      l_timezone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      get_vertical_datum_offsets(  
         l_offsets,
         l_location_code,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         cwms_util.change_timezone(p_start_time, l_timezone, 'UTC'),
         cwms_util.change_timezone(p_end_time, l_timezone, 'UTC'));
      if l_offsets is not null then
         for i in 1..l_offsets.count loop
            l_offsets(i).date_time := cwms_util.change_timezone(l_offsets(i).date_time, 'UTC', l_timezone);
            if p_unit is not null then
               l_offsets(i).value := cwms_util.convert_units(l_offsets(i).value, 'm', p_unit);
            end if;
         end loop;
      end if;         
   end get_vertical_datum_offsets;
            
   
   procedure set_default_vertical_datum(
      p_vertical_datum in varchar2)
   is
      l_vertical_datum varchar(16);
   begin
      if p_vertical_datum is null then
         cwms_util.reset_session_info('VERTICAL DATUM');
      else
         select vertical_datum_id
           into l_vertical_datum
           from cwms_vertical_datum
          where vertical_datum_id = upper(p_vertical_datum)
            and vertical_datum_id <> 'STAGE';
         cwms_util.set_session_info('VERTICAL DATUM', l_vertical_datum);            
      end if;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_vertical_datum, 'CWMS vertical datum');
   end set_default_vertical_datum;
      
   procedure get_default_vertical_datum(
      p_vertical_datum out varchar2)
   is
   begin
      p_vertical_datum := get_default_vertical_datum;
   end get_default_vertical_datum;
      
   function get_default_vertical_datum
      return varchar2
   is
   begin
      return cwms_util.get_session_info_txt('VERTICAL DATUM');
   end get_default_vertical_datum;
      
   procedure get_location_vertical_datum(
      p_vertical_datum out varchar2,
      p_location_code  in  number)
   is
      l_vertical_datum     varchar2(16);
      l_base_location_code number(10);
   begin
      select base_location_code, 
             vertical_datum
        into l_base_location_code,
             l_vertical_datum
        from at_physical_location
       where location_code = p_location_code;
      if l_vertical_datum is null and l_base_location_code != p_location_code then
         select base_location_code, 
                vertical_datum
           into l_base_location_code,
                l_vertical_datum
           from at_physical_location
          where location_code = l_base_location_code;
      end if;
      p_vertical_datum := l_vertical_datum;
   end get_location_vertical_datum;
      
   procedure get_location_vertical_datum(
      p_vertical_datum out varchar2,
      p_location_id    in  varchar2,
      p_office_id      in  varchar2 default null)
   is
   begin
      get_location_vertical_datum(
         p_vertical_datum,
         get_location_code(p_office_id, p_location_id));
   end get_location_vertical_datum;
      
   function get_location_vertical_datum(
      p_location_code in number)
      return varchar2
   is
      l_vertical_datum varchar2(16);
   begin
      get_location_vertical_datum(l_vertical_datum, p_location_code);
      return l_vertical_datum;
   end get_location_vertical_datum;
      
   function get_location_vertical_datum(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
      l_vertical_datum varchar2(16);
   begin
      get_location_vertical_datum(l_vertical_datum, p_location_id, p_office_id);
      return l_vertical_datum;
   end get_location_vertical_datum;

   function get_vertical_datum_offset(
      p_location_code in number,
      p_unit          in varchar2)
      return binary_double
   is
      l_location_datum  varchar2(16);
      l_effective_datum varchar2(16);
      l_datum_offset    binary_double;
   begin
      l_location_datum  := get_location_vertical_datum(p_location_code);
      l_effective_datum := cwms_util.get_effective_vertical_datum(p_unit);
      case
         when l_effective_datum is null or l_location_datum = l_effective_datum then
            l_datum_offset := 0;
         when l_location_datum is null then
            cwms_err.raise('ERROR', 'Cannot convert between NULL and non-NULL vertical datums');
         else 
            l_datum_offset := get_vertical_datum_offset(
                 p_location_code, 
                 l_location_datum, 
                 l_effective_datum,
                 sysdate,
                 p_unit);
      end case;
      return l_datum_offset;
   end get_vertical_datum_offset;

   function get_vertical_datum_offset(
      p_location_id  in varchar2,
      p_unit         in varchar2,
      p_office_id    in varchar2 default null)
      return binary_double
   is
   begin
      return get_vertical_datum_offset(
         get_location_code(p_office_id, p_location_id),
         p_unit);
   end get_vertical_datum_offset;
            
   
   procedure get_vertical_datum_info(
      p_vert_datum_info out varchar2,
      p_location_code   in  number,
      p_unit            in  varchar2)
   is   
      l_location_id      varchar2(49);
      l_office_id        varchar2(16);
      l_elevation        number;
      l_unit             varchar2(16);
      l_vert_datum_info  varchar2(4000);
      l_native_datum     varchar2(16);
      l_local_datum_name varchar2(16);
      l_datum_offset     binary_double;
      l_effective_date   date;
      l_estimate         varchar2(1); 
      l_rounding_spec    varchar2(10) := '4444444449';
   begin
      l_unit := cwms_util.get_unit_id(p_unit);

      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id,
             o.office_id,
             cwms_util.convert_units(pl.elevation, 'm', l_unit),
             pl.vertical_datum
        into l_location_id,
             l_office_id,
             l_elevation,
             l_native_datum          
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      l_vert_datum_info := '<vertical-datum-info office="'
         ||l_office_id
         ||'" unit="'
         ||l_unit
         ||'">'
         ||chr(10);
      l_vert_datum_info := l_vert_datum_info
         ||'  <location>'
         ||l_location_id
         ||'</location>'
         ||chr(10);
      l_vert_datum_info := l_vert_datum_info
         ||'  <native-datum>'
         ||nvl(replace(l_native_datum, 'LOCAL', 'OTHER'), 'UNKNOWN')
         ||'</native-datum>'
         ||chr(10);
      if l_native_datum = 'LOCAL' then 
         l_local_datum_name := get_local_vert_datum_name_f(p_location_code);
         if l_local_datum_name is null then
            l_vert_datum_info := l_vert_datum_info
               ||'  <local-datum-name/>'
               ||chr(10);
         else
            l_vert_datum_info := l_vert_datum_info
               ||'  <local-datum-name>'
               ||l_local_datum_name
               ||'</local-datum-name>'
               ||chr(10);
         end if;
      end if;   
      if l_elevation is not null then
         l_vert_datum_info := l_vert_datum_info 
            ||'  <elevation>'
            ||cwms_rounding.round_nt_f(l_elevation, l_rounding_spec)
            ||'</elevation>'
            ||chr(10);
      end if;
      
      for rec in (select vertical_datum_id
                    from cwms_vertical_datum
                   where vertical_datum_id != l_native_datum
                   order by vertical_datum_id
                 )
      loop
         begin
            get_vertical_datum_offset(
               l_datum_offset,
               l_effective_date,
               l_estimate,
               p_location_code,
               l_native_datum,
               rec.vertical_datum_id);
            l_vert_datum_info := l_vert_datum_info
               ||'  <offset estimate="'
               || case l_estimate when 'T' then 'true' else 'false' end
               ||'">'
               ||chr(10)
               ||'    <to-datum>'
               ||rec.vertical_datum_id
               ||'</to-datum>'
               ||chr(10)
               ||'    <value>'
               ||cwms_rounding.round_dt_f(cwms_util.convert_units(l_datum_offset, 'm', l_unit), l_rounding_spec)
               ||'</value>'
               ||chr(10)
               ||'  </offset>'
               ||chr(10);
         exception
            when others then
               if instr(sqlerrm, 'No vertical offset exists') = 1 then null; end if;
         end;
      end loop;                      
      l_vert_datum_info := l_vert_datum_info
         ||'</vertical-datum-info>';
      l_vert_datum_info := regexp_replace(l_vert_datum_info, '(N[AG]VD)(29|88)', '\1-\2');         
      p_vert_datum_info := l_vert_datum_info;
   end get_vertical_datum_info;

   procedure get_vertical_datum_info(
      p_vert_datum_info out varchar2,
      p_location_id     in  varchar2,
      p_unit            in  varchar2,
      p_office_id       in  varchar2 default null)
   is                            
      l_location_records str_tab_tab_t;
      l_office_records   str_tab_tab_t;
      l_record_count     pls_integer := 0;
      l_field_count      pls_integer := 0;
      l_total            pls_integer := 0;
      l_vert_datum_info  varchar2(4000);
      l_office_id        varchar2(16);
      function indent(p_str in varchar2) return varchar2
      is
         l_lines str_tab_t;
         l_str   varchar2(32767);
      begin
         l_lines := cwms_util.split_text(p_str, chr(10));
         for i in 1..l_lines.count loop
            l_str := l_str
               ||'  '||replace(l_lines(i), chr(13), null)||chr(10);
         end loop;
         return substr(l_str, 1, length(l_str)-1);
      end;
   begin           
      l_location_records := cwms_util.parse_string_recordset(p_location_id);
      l_record_count := l_location_records.count;
      for i in 1..l_record_count loop
         l_total := l_total + l_location_records(i).count;
      end loop;
      if p_office_id is not null then
         l_office_records := cwms_util.parse_string_recordset(p_office_id);
      end if;
      if l_total > 1 then
         l_vert_datum_info := '<vertical-datum-info-set>'||chr(10);
         for i in 1..l_record_count loop
            l_field_count := l_location_records(i).count;
            for j in 1..l_field_count loop
               case
                  when l_office_records is null then
                     -- no office ids
                     l_office_id := null;
                  when l_office_records.count = l_record_count then
                     case 
                        when l_office_records(i).count = 1 then
                           -- single office for this record
                           l_office_id := l_office_records(i)(1);
                        when l_office_records(i).count = l_field_count then
                           -- one office per location
                           l_office_id := l_office_records(i)(j);
                        else
                           -- office count error for this record
                           cwms_err.raise('ERROR', 'Invalid office count on record '||i);
                     end case;
                  else
                     -- total office count error
                     cwms_err.raise('ERROR', 'Invalid total office count');
               end case;
               l_vert_datum_info := l_vert_datum_info
                  ||indent(get_vertical_datum_info_f(l_location_records(i)(j), p_unit, l_office_id))
                  ||chr(10);
            end loop;
         end loop;
         l_vert_datum_info := l_vert_datum_info||'</vertical-datum-info-set>';
      else
         get_vertical_datum_info(
            l_vert_datum_info,
            get_location_code(p_office_id, p_location_id),
            p_unit);
      end if;
      p_vert_datum_info := l_vert_datum_info;
   end get_vertical_datum_info;

   function get_vertical_datum_info_f(
      p_location_code in number,
      p_unit          in varchar2)
      return varchar2
   is
      l_vert_datum_info varchar2(4000);
   begin
      get_vertical_datum_info(
         l_vert_datum_info,
         p_location_code,
         p_unit);
      return l_vert_datum_info;      
   end get_vertical_datum_info_f;   
      
   procedure set_vertical_datum_info(
      p_location_code   in number,
      p_vert_datum_info in xmltype,
      p_fail_if_exists  in varchar2 default 'F')
   is
      l_node                xmltype;
      l_location_id         varchar2(49);
      l_location_id_2       varchar2(49);
      l_office_id           varchar2(16);
      l_office_id_2         varchar2(16);
      l_native_datum        varchar2(16);
      l_native_datum_db     varchar2(16);
      l_local_datum_name    varchar2(16);
      l_local_datum_name_db varchar2(16);
      l_to_datum            varchar2(16);
      l_unit                varchar2(16);
      l_estimate            boolean;
      l_offset              binary_double;
      l_elevation           binary_double;
      l_elevation_db        binary_double;
      l_fail_if_exists      boolean;
   begin
      l_location_id := get_location_id(p_location_code);
      select o.office_id
        into l_office_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;               
      l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
      l_node := cwms_util.get_xml_node(p_vert_datum_info, '/vertical-datum-info');
      if l_node is null then
         cwms_err.raise('ERROR', 'Vertical datum info does not have <vertical-datum-info> as root element');
      end if;
      l_office_id_2   := cwms_util.get_xml_text(l_node, '/vertical-datum-info/@office');
      l_location_id_2 := cwms_util.get_xml_text(l_node, '/vertical-datum-info/location');
      if (l_office_id_2 is null) != (l_location_id_2 is null) then
         cwms_err.raise('ERROR', 'Office and location must be specified together (both or neither)');
      end if;
      if l_office_id_2 is not null then
         if get_location_code(l_office_id_2, l_location_id_2) != p_location_code then
            cwms_err.raise('ERROR', 'Location specified in XML is not same as that specified in p_location_code parameter');
         end if;
      end if;         
      l_unit := cwms_util.get_xml_text(l_node, '/vertical-datum-info/@unit');
      if l_unit is null then
         cwms_err.raise('ERROR', 'Vertical datum info does not specify unit');
      end if;
      l_native_datum := upper(cwms_util.get_xml_text(l_node, '/vertical-datum-info/native-datum'));
      if l_native_datum is not null then 
         l_native_datum := replace(l_native_datum, 'OTHER', 'LOCAL');
         l_native_datum := regexp_replace(l_native_datum, '(N[AG]VD).+(29|88)', '\1\2');
         l_native_datum_db := get_location_vertical_datum(p_location_code);
         if l_native_datum_db is not null and l_native_datum_db != l_native_datum then
            cwms_err.raise(
               'ERROR', 
               'Specified native datum for '
               ||l_office_id||'/'||l_location_id
               ||' of '
               ||cwms_util.get_xml_text(l_node, '/vertical-datum-info/native-datum')
               ||' does not agree with native datum in database of '
               ||l_native_datum_db);
         end if;
         if l_native_datum = 'LOCAL' then
            l_local_datum_name := cwms_util.get_xml_text(l_node, '/vertical-datum-info/local-datum-name');
            if l_local_datum_name is not null then
               l_local_datum_name_db := get_local_vert_datum_name_f(p_location_code);
               if l_local_datum_name_db is not null and l_local_datum_name_db != l_local_datum_name then
                  cwms_err.raise(
                     'ERROR', 
                     'Specified local datum name for '
                     ||l_office_id||'/'||l_location_id
                     ||' of '
                     ||l_local_datum_name
                     ||' does not agree with local datum name in database of '
                     ||l_local_datum_name_db);
               end if;
            end if;
         end if;
      end if;
      l_elevation := cwms_util.get_xml_number(l_node, '/vertical-datum-info/elevation');
      if l_elevation is not null then
         select cwms_util.convert_units(elevation, 'm', l_unit)
           into l_elevation_db
           from at_physical_location
          where location_code = p_location_code;
         if l_elevation_db is not null and l_elevation_db != l_elevation then
            cwms_err.raise(
               'ERROR', 
               'Specified elevation for '
               ||l_office_id||'/'||l_location_id
               ||' of '
               ||l_elevation
               ||' '
               ||l_unit
               ||' does not agree with elevation in database of '
               ||l_elevation_db
               ||' '
               ||l_unit);
         end if;
      end if;
      for i in 1..999999 loop
         l_node := cwms_util.get_xml_node(p_vert_datum_info, '/vertical-datum-info/offset['||i||']');
         exit when l_node is null;
         l_to_datum := cwms_util.get_xml_text(l_node, '/offset/to-datum');
         if l_to_datum is null then
            cwms_err.raise('ERROR', '<offset> element does not specify datum in <to-datum> child element');
         end if;
         l_offset := cwms_util.get_xml_number(l_node, '/offset/value');
         if l_offset is null then
            cwms_err.raise('ERROR', '<offset> element does not specify datum in <value> child element');
         end if;
         case upper(nvl(cwms_util.get_xml_text(l_node, '/offset/@estimate'), 'NULL'))
            when 'TRUE'  then l_estimate := true;
            when 'FALSE' then l_estimate := false;
            when 'NULL'  then cwms_err.raise('ERROR', 'Estimate attribute is missing from <offset> element for datum '||l_to_datum);
            else cwms_err.raise('ERROR', 'Estimate attribute in <offset> element for datum '||l_to_datum||' must be "true" or "false"');
         end case;
         cwms_loc.store_vertical_datum_offset(
            p_location_id         => l_location_id,
            p_vertical_datum_id_1 => l_native_datum,
            p_vertical_datum_id_2 => l_to_datum,
            p_offset              => l_offset,
            p_unit                => l_unit,
            p_description         => case l_estimate when true then 'ESTIMATE' else null end,
            p_fail_if_exists      => p_fail_if_exists,
            p_office_id           => l_office_id);
      end loop;
      if l_native_datum_db is null then
         update at_physical_location
            set vertical_datum = l_native_datum_db
          where location_code = p_location_code;  
      end if;
      if l_local_datum_name is not null and l_local_datum_name_db is null then
         set_local_vert_datum_name(p_location_code, l_local_datum_name);
      end if;
      if l_elevation_db is null and l_elevation is not null then
         update at_physical_location
            set elevation = cwms_util.convert_units(l_elevation, l_unit, 'm')
          where location_code = p_location_code;  
      end if;
   end set_vertical_datum_info;           

   function get_vertical_datum_info_f(
      p_location_id in varchar2,
      p_unit        in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
      l_vert_datum_info varchar2(4000);
   begin                      
      get_vertical_datum_info(
         l_vert_datum_info,
         p_location_id,
         p_unit,
         p_office_id);
      return l_vert_datum_info;
   end get_vertical_datum_info_f;
            
   procedure set_vertical_datum_info(
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2)
   is
      l_xml  xmltype;
      l_node xmltype;
      function get_location_code(l_node in xmltype) return varchar2
      is
         l_location_id varchar2(49);
         l_office_id   varchar2(16);
      begin
         l_office_id := cwms_util.get_xml_text(l_node, '/vertical-datum-info/@office');
         if l_office_id is null then
               cwms_err.raise('ERROR', 'Office attribute is missing from <vertical-datum-info> element');
         end if;
         l_location_id := cwms_util.get_xml_text(l_node, '/vertical-datum-info/location');
         if l_location_id is null then
               cwms_err.raise('ERROR', '<vertical-datum-info> does not specify location in <location> element');
         end if;
         return cwms_loc.get_location_code(l_office_id, l_location_id);
      end;
   begin
      l_xml := xmltype(p_vert_datum_info);
      case l_xml.getrootelement
         when 'vertical-datum-info-set' then
            for i in 1..999999 loop
               l_node := cwms_util.get_xml_node(l_xml, '/vertical-datum-info-set/vertical-datum-info['||i||']');
               exit when l_node is null;
               set_vertical_datum_info(
                  get_location_code(l_node),
                  l_node,
                  p_fail_if_exists);
            end loop;
         when 'vertical-datum-info' then
            set_vertical_datum_info(
               get_location_code(l_xml),
               l_xml,
               p_fail_if_exists);
         else
            cwms_err.raise(
               'ERROR', 
               'Unexpected root element for vertical datum info: '
               ||l_xml.getrootelement);
      end case;
   end set_vertical_datum_info;
      
   procedure set_vertical_datum_info(
      p_location_code   in number,
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2)
   is
   begin
      set_vertical_datum_info(
         p_location_code,
         xmltype(p_vert_datum_info),
         p_fail_if_exists);
   end set_vertical_datum_info;
      
   procedure set_vertical_datum_info(
      p_location_id     in varchar2,
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2,     
      p_office_id       in varchar2 default null)
   is
   begin
      set_vertical_datum_info(
         get_location_code(p_office_id, p_location_id),
         p_vert_datum_info,
         p_fail_if_exists);
   end set_vertical_datum_info;     

   procedure get_local_vert_datum_name (
      p_local_vert_datum_name out varchar2,
      p_location_code         in  number)
   is
   begin
      p_local_vert_datum_name := get_local_vert_datum_name_f(p_location_code);
   end get_local_vert_datum_name;
   
   function get_local_vert_datum_name_f (
      p_location_code in number)
      return varchar2
   is
      l_local_vert_datum_name varchar2(16);
   begin
      begin                           
         select local_datum_name                
           into l_local_vert_datum_name
           from at_vert_datum_local
          where location_code = p_location_code; 
      exception
         when no_data_found then null;
      end;
      return l_local_vert_datum_name;
   end get_local_vert_datum_name_f;
   
   procedure get_local_vert_datum_name (
      p_local_vert_datum_name out varchar2,
      p_location_id           in  varchar2,
      p_office_id             in  varchar2 default null)
   is
   begin
      p_local_vert_datum_name := get_local_vert_datum_name_f(p_location_id, p_office_id);
   end get_local_vert_datum_name;

   function get_local_vert_datum_name_f (
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return get_local_vert_datum_name_f(cwms_loc.get_location_code(p_office_id, p_location_id));
   end get_local_vert_datum_name_f;
   
   procedure set_local_vert_datum_name(
      p_location_code   in number,
      p_vert_datum_name in varchar2,
      p_fail_if_exists  in varchar2 default 'T')
   is
      l_local_vert_datum_name varchar2(16);
   begin
      l_local_vert_datum_name := get_local_vert_datum_name_f(p_location_code);
      case 
         when l_local_vert_datum_name is null then
            insert into at_vert_datum_local values (p_location_code, p_vert_datum_name);
         when l_local_vert_datum_name = p_vert_datum_name then
            null;
         when cwms_util.is_true(p_fail_if_exists) then
            declare
               l_office_id   varchar2(16);
               l_location_id varchar2(49);
            begin
               select o.office_id,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id
                 into l_office_id,
                      l_location_id
                 from at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where pl.location_code = p_location_code
                  and bl.base_location_code = pl.base_location_code
                  and o.office_code = bl.db_office_code;      
               cwms_err.raise(
                  'ERROR',
                  'Location '
                  ||l_office_id
                  ||'/'                
                  ||l_location_id
                  ||' already has a local vertical datum name of '
                  ||l_local_vert_datum_name);
            end;
         else
            update at_vert_datum_local
               set local_datum_name = p_vert_datum_name
             where location_code = p_location_code;     
      end case;
   end set_local_vert_datum_name;   
   
   procedure set_local_vert_datum_name(
      p_location_id     in varchar2,
      p_vert_datum_name in varchar2,
      p_fail_if_exists  in varchar2 default 'T',
      p_office_id       in varchar2 default null)
   is
   begin
      set_local_vert_datum_name(
         p_location_code   => cwms_loc.get_location_code(p_office_id, p_location_id),
         p_vert_datum_name => p_vert_datum_name,
         p_fail_if_exists  => p_fail_if_exists);
   end set_local_vert_datum_name;   
 
   procedure delete_local_vert_datum_name (
      p_location_code in number)
   is
   begin
      delete from at_vert_datum_local where location_code = p_location_code;
   exception
      when no_data_found then null;
   end delete_local_vert_datum_name;
   
   procedure delete_local_vert_datum_name (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   is
   begin
      delete_local_vert_datum_name(get_location_code(p_office_id, p_location_id));
   end delete_local_vert_datum_name;
   
END cwms_loc;
/
show errors;