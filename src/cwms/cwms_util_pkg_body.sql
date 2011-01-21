SET define on
@@defines.sql

/* Formatted on 6/30/2009 6:36:59 AM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY cwms_util
AS
	/******************************************************************************
				 *   Name:		  CWMS_UTL
				*	 Purpose:	 Miscellaneous CWMS Procedures
		*
				  *	Revisions:
				 *   Ver 		 Date 		 Author		 Descriptio
					  *	---------  ----------  ----------  ----------------------------------------
				  *	1.1		  9/07/2005   Portin 	  create_view: at_ts_table_properties start and end dates
			  *												  changed to DATE datatype
				 *   1.0 		 8/29/2005	 Portin		 Original
				******************************************************************************/
	--
    

    FUNCTION min_dms (p_decimal_degrees IN NUMBER)
		RETURN NUMBER
	IS
		l_sec_dms							NUMBER;
		l_min_dms							NUMBER;
	BEGIN
		l_sec_dms :=
			ROUND (
				( (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60.0)
				 - TRUNC (
						ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60
					))
				* 60.0,
				2
			);
		l_min_dms :=
			TRUNC (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);

		IF l_sec_dms = 60
		THEN
			RETURN l_min_dms + 1;
		ELSE
			RETURN l_min_dms;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			-- Consider logging the error and then re-raise
			RAISE;
	END min_dms;

	--
	FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
		RETURN NUMBER
	IS
		l_sec_dms							NUMBER;
		l_sec_60 							NUMBER;
	BEGIN
		l_sec_dms :=
			( (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60.0)
			 - min_dms (p_decimal_degrees))
			* 60.0;
		l_sec_60 := ROUND (l_sec_dms, 2);

		IF l_sec_60 = 60
		THEN
			RETURN 0;
		ELSE
			RETURN l_sec_dms;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			-- Consider logging the error and then re-raise
			RAISE;
	END sec_dms;

	--
	FUNCTION min_dm (p_decimal_degrees IN NUMBER)
		RETURN NUMBER
	IS
	BEGIN
		RETURN (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			NULL;
		WHEN OTHERS
		THEN
			-- Consider logging the error and then re-raise
			RAISE;
	END min_dm;

	--
	-- return the p_in_date which is in p_in_tz as a date in UTC
	FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
		RETURN DATE
	IS
	BEGIN
		RETURN change_timezone(p_in_date, p_in_tz);
	END;

   --
   -- return the input date in a different time zone
   FUNCTION change_timezone (
      p_in_date IN DATE, 
      p_from_tz IN VARCHAR2, 
      p_to_tz   IN VARCHAR2 default 'UTC')
      RETURN DATE  result_cache
   IS
   BEGIN
      return case p_to_tz = p_from_tz
                when true then p_in_date
                else cast(from_tz (cast (p_in_date as timestamp), p_from_tz) at time zone p_to_tz as date)
             end;
   END;      

	FUNCTION get_base_id (p_full_id IN VARCHAR2)
		RETURN VARCHAR2
	IS
		l_num 								NUMBER := INSTR (p_full_id, '-', 1, 1);
		l_length 							NUMBER := LENGTH (p_full_id);
		l_sub_length						NUMBER := l_length - l_num;
	BEGIN
		IF 	INSTR (p_full_id, '.', 1, 1) > 0
			OR l_num = l_length
			OR l_num = 1
			OR l_sub_length > max_sub_id_length
			OR l_num > max_base_id_length + 1
			OR l_length > max_full_id_length
		THEN
			cwms_err.raise ('INVALID_FULL_ID', p_full_id);
		END IF;

		IF l_num = 0
		THEN
			RETURN p_full_id;
		ELSE
			RETURN SUBSTR (p_full_id, 1, l_num - 1);
		END IF;
	END;

	FUNCTION get_base_param_code (p_base_param_id IN VARCHAR2)
		RETURN NUMBER
	IS
		l_base_param_code 				NUMBER;
	BEGIN
		SELECT	a.base_parameter_code
		  INTO	l_base_param_code
		  FROM	cwms_base_parameter a
		 WHERE	UPPER (a.base_parameter_id) = UPPER (TRIM (p_base_param_id));

		RETURN l_base_param_code;
	END;

	FUNCTION get_sub_id (p_full_id IN VARCHAR2)
		RETURN VARCHAR2
	IS
		l_num 								NUMBER := INSTR (p_full_id, '-', 1, 1);
		l_length 							NUMBER := LENGTH (p_full_id);
		l_sub_length						NUMBER := l_length - l_num;
	BEGIN
		IF 	INSTR (p_full_id, '.', 1, 1) > 0
			OR l_num = l_length
			OR l_num = 1
			OR l_sub_length > max_sub_id_length
			OR l_num > max_base_id_length + 1
			OR l_length > max_full_id_length
		THEN
			cwms_err.raise ('INVALID_FULL_ID', p_full_id);
		END IF;

		IF l_num = 0
		THEN
			RETURN NULL;
		ELSE
			RETURN SUBSTR (p_full_id, l_num + 1, l_sub_length);
		END IF;
	END;

	FUNCTION is_true (p_true_false IN VARCHAR2)
		RETURN BOOLEAN result_cache
	IS
	BEGIN
		IF UPPER (p_true_false) = 'T' OR UPPER (p_true_false) = 'TRUE'
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END;

	--
	FUNCTION is_false (p_true_false IN VARCHAR2)
		RETURN BOOLEAN result_cache
	IS
	BEGIN
		IF UPPER (p_true_false) = 'F' OR UPPER (p_true_false) = 'FALSE'
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END;

	-- Retruns TRUE if p_true_false is T or True
	-- Returns FALSE if p_true_false is F or False.
	FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
		RETURN BOOLEAN result_cache
	IS
	BEGIN
		IF cwms_util.is_true (p_true_false)
		THEN
			RETURN TRUE;
		ELSIF cwms_util.is_false (p_true_false)
		THEN
			RETURN FALSE;
		ELSE
			cwms_err.raise ('INVALID_T_F_FLAG', p_true_false);
		END IF;
	END;

	-- Retruns 'T' if p_true_false is T or True
	-- Returns 'F 'if p_true_false is F or False.
	FUNCTION return_t_or_f_flag (p_true_false IN VARCHAR2)
		RETURN VARCHAR2 result_cache
	IS
	BEGIN
		IF cwms_util.is_true (p_true_false)
		THEN
			RETURN 'T';
		ELSIF cwms_util.is_false (p_true_false)
		THEN
			RETURN 'F';
		ELSE
			cwms_err.raise ('INVALID_T_F_FLAG', p_true_false);
		END IF;
	END;

	--------------------------------------------------------------------------------
	-- function get_real_name
	--
	FUNCTION get_real_name (p_synonym IN VARCHAR2)
		RETURN VARCHAR2
	IS
		l_name								VARCHAR2 (32) := UPPER (p_synonym);
		invalid_sql_name exception;
		PRAGMA EXCEPTION_INIT (invalid_sql_name, -44003);
	BEGIN
		BEGIN
			SELECT	dbms_assert.simple_sql_name (l_name)
			  INTO	l_name
			  FROM	DUAL;

			SELECT	table_name
			  INTO	l_name
			  FROM	sys.all_synonyms
			 WHERE		 synonym_name = l_name
						AND owner = 'PUBLIC'
						AND table_owner = '&cwms_schema';
		EXCEPTION
			WHEN invalid_sql_name
			THEN
				cwms_err.raise ('INVALID_ITEM',
									 p_synonym,
									 'materialized view name'
									);
			WHEN NO_DATA_FOUND
			THEN
				NULL;
		END;

		RETURN l_name;
	END get_real_name;

    PROCEDURE start_mv_cwms_ts_id_job
    IS
        l_count                                BINARY_INTEGER;
        l_user_id                            VARCHAR2 (30);
        l_job_id                             VARCHAR2 (30) := 'REFRESH_MV_CWMS_TS_ID_JOB';

        FUNCTION job_count
            RETURN BINARY_INTEGER
        IS
        BEGIN
            SELECT    COUNT ( * )
              INTO    l_count
              FROM    sys.dba_scheduler_jobs
             WHERE    job_name = l_job_id AND owner = l_user_id;

            RETURN l_count;
        END;
    BEGIN
        --------------------------------------
        -- make sure we're the correct user --
        --------------------------------------
        l_user_id := get_user_id;

        IF l_user_id != '&cwms_schema'
        THEN
            raise_application_error (
                -20999,
                'Must be &cwms_schema user to start job ' || l_job_id,
                TRUE
            );
        END IF;

        -------------------------------------------
        -- drop the job if it is already running --
        -------------------------------------------
        IF job_count > 0
        THEN
            DBMS_OUTPUT.put ('Dropping existing job ' || l_job_id || '...');
            DBMS_SCHEDULER.drop_job (l_job_id);

            --------------------------------
            -- verify that it was dropped --
            --------------------------------
            IF job_count = 0
            THEN
                DBMS_OUTPUT.put_line ('done.');
            ELSE
                DBMS_OUTPUT.put_line ('failed.');
            END IF;
        END IF;

        IF job_count = 0
        THEN
            BEGIN
                ---------------------
                -- restart the job --
                ---------------------
                DBMS_SCHEDULER.create_job (
                    job_name             => l_job_id,
                    job_type             => 'stored_procedure',
                    job_action            => 'cwms_util.refresh_mv_cwms_ts_id',
                    start_date            => NULL,
                    repeat_interval    => 'freq=secondly; interval='
                                              || mv_cwms_ts_id_refresh_interval,
                    end_date             => NULL,
                    job_class            => 'default_job_class',
                    enabled                => TRUE,
                    auto_drop            => FALSE,
                    comments             => 'Refreshes the mv_cwms_ts_id materialized view.'
                );

                IF job_count = 1
                THEN
                    DBMS_OUTPUT.put_line('Job ' || l_job_id
                                                || ' successfully scheduled to execute every '
                                                || mv_cwms_ts_id_refresh_interval
                                                || ' minutes.');
                ELSE
                    cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    cwms_err.raise ('ITEM_NOT_CREATED',
                                         'job',
                                         l_job_id || ':' || SQLERRM
                                        );
            END;
        END IF;
    END start_mv_cwms_ts_id_job;
    
    PROCEDURE stop_mv_cwms_ts_id_job
    IS
        l_count                                BINARY_INTEGER;
        l_user_id                            VARCHAR2 (30);
        l_job_id                             VARCHAR2 (30) := 'REFRESH_MV_CWMS_TS_ID_JOB';

        FUNCTION job_count
            RETURN BINARY_INTEGER
        IS
        BEGIN
            SELECT    COUNT ( * )
              INTO    l_count
              FROM    sys.dba_scheduler_jobs
             WHERE    job_name = l_job_id AND owner = l_user_id;

            RETURN l_count;
        END;
    BEGIN
        --------------------------------------
        -- make sure we're the correct user --
        --------------------------------------
        l_user_id := get_user_id;

        IF l_user_id != '&cwms_schema'
        THEN
            raise_application_error (
                -20999,
                'Must be &cwms_schema user to start job ' || l_job_id,
                TRUE
            );
        END IF;

        -------------------------------------------
        -- drop the job if it is already running --
        -------------------------------------------
        IF job_count > 0
        THEN
            DBMS_OUTPUT.put ('Dropping existing job ' || l_job_id || '...');
            DBMS_SCHEDULER.drop_job (l_job_id);

            --------------------------------
            -- verify that it was dropped --
            --------------------------------
            IF job_count = 0
            THEN
                DBMS_OUTPUT.put_line ('done.');
            ELSE
                DBMS_OUTPUT.put_line ('failed.');
            END IF;
        END IF;

    END stop_mv_cwms_ts_id_job;
    
    PROCEDURE refresh_mv_cwms_ts_id
    IS
      l_staleness                 VARCHAR2(19);
    BEGIN
        SELECT staleness 
          INTO l_staleness
          FROM user_mviews
          WHERE mview_name = 'MV_CWMS_TS_ID';
       IF l_staleness <> 'FRESH'
       THEN
         BEGIN
            dbms_mview.refresh('mv_cwms_ts_id');
         EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
                -- Do a complete refresh if the fast refresh fails. Strictly not needed as the indexes
                -- on the materialized views are changed from unique to non unique (to fix broken
                -- materialized view after renaming the time series)
                DBMS_MVIEW.refresh('mv_cwms_ts_id',method => 'C');
             END;
       END IF;
    END refresh_mv_cwms_ts_id;
	--------------------------------------------------------
	-- Return the current session user's primary office id
	--
	FUNCTION user_office_id
		RETURN VARCHAR2
	IS
		l_office_id 						VARCHAR2 (16) := 'UNK';
		l_username							VARCHAR2 (32);
	BEGIN
		l_username := get_user_id;

		BEGIN
			SELECT	a.office_id
			  INTO	l_office_id
			  FROM	cwms_office a, at_sec_user_office b
			 WHERE	b.username = l_username
						AND a.office_code = b.user_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				BEGIN
					SELECT	office_id
					  INTO	l_office_id
					  FROM	cwms_office
					 WHERE	eroc = UPPER (SUBSTR (l_username, 1, 2));
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						IF l_username = '&cwms_schema'
						THEN
							l_office_id := 'CWMS';
						END IF;
				END;
		END;

		RETURN l_office_id;
	END user_office_id;

	PROCEDURE get_user_office_data (p_office_id			  OUT VARCHAR2,
											  p_office_long_name   OUT VARCHAR2
											 )
	IS
		l_username							VARCHAR2 (32);
	BEGIN
		l_username := get_user_id;

		BEGIN
			SELECT	a.office_id, a.long_name
			  INTO	p_office_id, p_office_long_name
			  FROM	cwms_office a, at_sec_user_office b
			 WHERE	b.username = l_username
						AND a.office_code = b.user_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				BEGIN
					SELECT	a.office_id, a.long_name
					  INTO	p_office_id, p_office_long_name
					  FROM	cwms_office a
					 WHERE	eroc = UPPER (SUBSTR (l_username, 1, 2));
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						NULL;
				END;
		END;
	END;

	--------------------------------------------------------
	-- Return the current session user's primary office code
	--
	FUNCTION user_office_code
		RETURN NUMBER
	IS
		l_office_code						NUMBER (10) := 0;
		l_username							VARCHAR2 (32);
	BEGIN
		l_username := get_user_id;

		BEGIN
			SELECT	user_db_office_code
			  INTO	l_office_code
			  FROM	at_sec_user_office
			 WHERE	username = l_username;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				BEGIN
					SELECT	office_code
					  INTO	l_office_code
					  FROM	cwms_office
					 WHERE	eroc = UPPER (SUBSTR (l_username, 1, 2));
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						IF l_username = '&cwms_schema'
						THEN
							SELECT	office_code
							  INTO	l_office_code
							  FROM	cwms_office
							 WHERE	office_id = 'CWMS';
						END IF;
				END;
		END;

		RETURN l_office_code;
	END user_office_code;

	--------------------------------------------------------
	-- Return the office code for the specified office id,
	-- or the user's primary office if the office id is null
	--
	FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN NUMBER
	IS
		l_office_code						NUMBER := NULL;
	BEGIN
		IF p_office_id IS NULL
		THEN
			l_office_code := user_office_code;
		ELSE
			SELECT	office_code
			  INTO	l_office_code
			  FROM	cwms_office
			 WHERE	UPPER (office_id) = UPPER (p_office_id);
		END IF;

		RETURN l_office_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			cwms_err.raise ('INVALID_OFFICE_ID', p_office_id);
	END get_office_code;

	--------------------------------------------------------
	-- Return the db host office code for the specified office id,
	-- or the user's primary office if the office id is null
	--
	FUNCTION get_db_office_code (p_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN NUMBER
	IS
		l_db_office_code					NUMBER := NULL;
	BEGIN
		RETURN get_office_code (p_office_id);
	END get_db_office_code;

	--------------------------------------------------------
	--------------------------------------------------------
	FUNCTION get_db_office_id (p_db_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN VARCHAR2
	IS
		l_db_office_code					NUMBER := NULL;
		l_db_office_id 					VARCHAR2 (16);
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := user_office_id;
		ELSE
			SELECT	office_id
			  INTO	l_db_office_id
			  FROM	cwms_office
			 WHERE	UPPER (office_id) = UPPER (p_db_office_id);
		END IF;

		RETURN l_db_office_id;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			cwms_err.raise ('INVALID_OFFICE_ID', p_db_office_id);
	END get_db_office_id;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_location_id (
      p_location_code  IN NUMBER,
      p_prepend_office IN VARCHAR2 DEFAULT 'F')
      RETURN VARCHAR2
   IS
      l_location_id varchar2(183);
      l_office_id   varchar2(16);
   BEGIN
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into l_office_id,
             l_location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where PL.LOCATION_CODE = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      if is_true(p_prepend_office) then
         return l_office_id|| '/' || l_location_id;
      end if;
      return l_location_id;
   END get_location_id;      
	--------------------------------------------------------
	--------------------------------------------------------
	FUNCTION get_parameter_id (p_parameter_code IN NUMBER)
		RETURN VARCHAR2
	IS
		l_parameter_id 					VARCHAR2 (49);
	BEGIN
		BEGIN
			SELECT		cbp.base_parameter_id
						|| SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
						|| atp.sub_parameter_id
			  INTO	l_parameter_id
			  FROM	at_parameter atp, cwms_base_parameter cbp
			 WHERE	atp.parameter_code = p_parameter_code
						AND atp.base_parameter_code = cbp.base_parameter_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					p_parameter_code || ' is not a valid parameter_code.'
				);
		END;

		RETURN l_parameter_id;
	END get_parameter_id;

	/*
		--------------------------------------------------------
	 -- Replace filename wildcard chars (?,*) with SQL ones
		-- (_,%), using '\' as an escape character.
	  --
	 --  A null input generates a result of '%'.
	  --
	+--------------+-------------------------------------------------------------------------+
	|										 Output String 										|
	|				+------------------------------------------------------------+------------+
	|					|									  Recognize SQL						 | 			  |
	|					|										Wildcards?							 | 			  |
	|					+------+---------------------------+-----+-------------------+ 			  |
	| Input String | No : comments			  | Yes : comments			 | Different? |
	+--------------+------+---------------------------+-----+-------------------+------------+
	| %				  | \% : literal '%'         | %   : multi-wildcard     | Yes        |
	| _				| \_ : literal '_'         | _   : single-wildcard    | Yes        |
	| *				| %	: multi-wildcard		 | %	 : multi-wildcard 	 | No 		  |
	| ?				| _  : single-wildcard		| _	: single-wildcard 	 | No 		  |
	| \%	|		 : not allowed 				  | \%  : literal '%'       | Yes        |
	| \_	|		 : not allowed 				  | \_  : literal '_'       | Yes        |
	| \*	| *	 : literal '*'               | *   : literal '*'       | No         |
	| \?	| ?	 : literal '?'               | ?   : literal '?'       | No         |
	| \\%   | \\\% : literal '\' + literal '%' | \\% : literal '\' + mwc | Yes        |
	| \\_   | \\\_ : literal '\' + literal '\' | \\_ : literal '\' + swc | Yes        |
	| \\*   | \\% : literal '\' + mwc         | \\% : literal '\' + mwc | No         |
	| \\?   | \\_ : literal '\' + swc         | \\_ : literal '\' + swc | No         |
	+--------------+------+---------------------------+-----+-------------------+------------+
		 */
	FUNCTION normalize_wildcards (p_string 			IN VARCHAR2,
											p_recognize_sql	IN BOOLEAN DEFAULT FALSE
										  )
		RETURN VARCHAR2
	IS
		l_result 							VARCHAR2 (32767);
		l_char								VARCHAR2 (1);
		l_skip								BOOLEAN := FALSE;
	BEGIN
		--------------------------------
		-- default null string to '%' --
		--------------------------------
		IF p_string IS NULL
		THEN
			RETURN '%';
		END IF;

		l_result := NULL;

		FOR i IN 1 .. LENGTH (p_string)
		LOOP
			IF l_skip
			THEN
				l_skip := FALSE;
			ELSE
				l_char := SUBSTR (p_string, i, 1);

				CASE l_char
					WHEN '\'
					THEN
						IF i = LENGTH (p_string)
						THEN
							cwms_err.raise (
								'ERROR',
								'Escape character ''\'' cannot end a match string.'
							);
						END IF;

						l_skip := TRUE;

						IF REGEXP_INSTR (NVL (SUBSTR (p_string, i + 1), ' '),
											  '\\[*?%_]'
											 ) = 1
						THEN
							l_result := l_result || '\\';
						ELSE
							l_char := SUBSTR (p_string, i + 1, 1);

							IF p_recognize_sql
							THEN
								CASE l_char
									WHEN '\'
									THEN
										l_result := l_result || '\';
									WHEN '*'
									THEN
										l_result := l_result || '*';
									WHEN '?'
									THEN
										l_result := l_result || '?';
									WHEN '%'
									THEN
										l_result := l_result || '\%';
									WHEN '_'
									THEN
										l_result := l_result || '\_';
									ELSE
										cwms_err.raise ('INVALID_ITEM',
															 p_string,
															 'match string'
															);
								END CASE;
							ELSE
								CASE l_char
									WHEN '\'
									THEN
										l_result := l_result || '\';
									WHEN '*'
									THEN
										l_result := l_result || '*';
									WHEN '?'
									THEN
										l_result := l_result || '?';
									WHEN '%'
									THEN
										cwms_err.raise (
											'ERROR',
											'Escape sequence ''\%'' is not valid when p_recognize_sql is FALSE.'
										);
									WHEN '_'
									THEN
										cwms_err.raise (
											'ERROR',
											'Escape sequence ''\_'' is not valid when p_recognize_sql is FALSE.'
										);
									ELSE
										cwms_err.raise ('INVALID_ITEM',
															 p_string,
															 'match string'
															);
								END CASE;
							END IF;
						END IF;
					WHEN '*'
					THEN
						l_result := l_result || '%';
					WHEN '?'
					THEN
						l_result := l_result || '_';
					WHEN '%'
					THEN
						IF NOT p_recognize_sql
						THEN
							l_result := l_result || '\';
						END IF;

						l_result := l_result || '%';
					WHEN '_'
					THEN
						IF NOT p_recognize_sql
						THEN
							l_result := l_result || '\';
						END IF;

						l_result := l_result || '_';
					ELSE
						l_result := l_result || l_char;
				END CASE;
			END IF;
		END LOOP;

		RETURN l_result;
	END normalize_wildcards;

	--------------------------------------------------------
	-- Replace SQL ones (_,%) with filename wildcard chars (?,*),
	-- using '\' as an escape character.
	--
	--  A null input generates a result of '*'.
	--
	-- +--------------+-------------------------------------------------------------------------+
	-- |			|													  Output String														|
	-- |			+------------------------------------------------------------+------------+
	-- |			|													Recognize SQL								  |					|
	-- |			|													  Wildcards?									  |					|
	-- |			+------+---------------------------+-----+-------------------+ 				  |
	-- | Input String | No : comments				  | Yes : comments				 | Different? |
	-- +--------------+------+---------------------------+-----+-------------------+------------+
	-- | %	 | \% 	 : literal '%'               | %   : multi-wildcard    | Yes        |
	-- | _	 | \_ 	 : literal '_'               | _   : single-wildcard   | Yes        |
	-- | *	 | %		: multi-wildcard					 | %	 : multi-wildcard 	 | No 			 |
	-- | ?	 | _		: single-wildcard 				 | _	 : single-wildcard	  | No			  |
	-- | \%	  |			: not allowed						  | \%  : literal '%'       | Yes        |
	-- | \_	  |			: not allowed						  | \_  : literal '_'       | Yes        |
	-- | \*	  | * 	 : literal '*'               | *   : literal '*'       | No         |
	-- | \?	  | ? 	 : literal '?'               | ?   : literal '?'       | No         |
	-- | \\%   | \\\% : literal '\' + literal '%' | \\% : literal '\' + mwc | Yes        |
	-- | \\_   | \\\_ : literal '\' + literal '\' | \\_ : literal '\' + swc | Yes        |
	-- | \\*   | \\% : literal '\' + mwc         | \\% : literal '\' + mwc | No         |
	-- | \\?   | \\_ : literal '\' + swc         | \\_ : literal '\' + swc | No         |
	-- +--------------+------+---------------------------+-----+-------------------+------------+

	FUNCTION denormalize_wildcards (p_string IN VARCHAR2)
		RETURN VARCHAR2
	IS
		l_result 							VARCHAR2 (32767);
		l_char								VARCHAR2 (1);
		l_skip								BOOLEAN := FALSE;
	BEGIN
		--------------------------------
		-- default null string to '*' --
		--------------------------------
		IF p_string IS NULL
		THEN
			RETURN '*';
		END IF;

		l_result := NULL;

		FOR i IN 1 .. LENGTH (p_string)
		LOOP
			IF l_skip
			THEN
				l_skip := FALSE;
			ELSE
				l_char := SUBSTR (p_string, i, 1);

				CASE l_char
					WHEN '\'
					THEN
						IF i = LENGTH (p_string)
						THEN
							cwms_err.raise (
								'ERROR',
								'Escape character ''\'' cannot end a match string.'
							);
						END IF;

						l_skip := TRUE;

						IF REGEXP_INSTR (NVL (SUBSTR (p_string, i + 1), ' '),
											  '\\[*?%_]'
											 ) = 1
						THEN
							l_result := l_result || '\\';
						ELSE
							l_char := SUBSTR (p_string, i + 1, 1);


							CASE l_char
								WHEN '\'
								THEN
									l_result := l_result || '\';
								WHEN '*'
								THEN
									l_result := l_result || '*';
								WHEN '?'
								THEN
									l_result := l_result || '?';
								WHEN '%'
								THEN
									l_result := l_result || '%';
								WHEN '_'
								THEN
									l_result := l_result || '_';
								ELSE
									cwms_err.raise ('INVALID_ITEM',
														 p_string,
														 'match string'
														);
							END CASE;
						END IF;
					WHEN '%'
					THEN
						l_result := l_result || '*';
					WHEN '_'
					THEN
						l_result := l_result || '?';

					ELSE
						l_result := l_result || l_char;
				END CASE;
			END IF;
		END LOOP;

		RETURN l_result;
	END denormalize_wildcards;

	PROCEDURE parse_ts_id (p_base_location_id 		OUT VARCHAR2,
								  p_sub_location_id			OUT VARCHAR2,
								  p_base_parameter_id		OUT VARCHAR2,
								  p_sub_parameter_id 		OUT VARCHAR2,
								  p_parameter_type_id		OUT VARCHAR2,
								  p_interval_id				OUT VARCHAR2,
								  p_duration_id				OUT VARCHAR2,
								  p_version_id 				OUT VARCHAR2,
								  p_cwms_ts_id 			IN 	 VARCHAR2
								 )
	IS
	BEGIN
		cwms_ts.parse_ts (p_cwms_ts_id			 => p_cwms_ts_id,
								p_base_location_id	 => p_base_location_id,
								p_sub_location_id 	 => p_sub_location_id,
								p_base_parameter_id	 => p_base_parameter_id,
								p_sub_parameter_id	 => p_sub_parameter_id,
								p_parameter_type_id	 => p_parameter_type_id,
								p_interval_id			 => p_interval_id,
								p_duration_id			 => p_duration_id,
								p_version_id			 => p_version_id
							  );
	END;

	--------------------------------------------------------------------------------
	-- Parses a search string into one or more AND/OR LIKE/NOT LIKE predicate lines.
	-- A search string contains one or more search patterns separated by a blank -
	-- space. When constructing search patterns on can use AND, OR, and NOT between-
	-- search patterns. a blank space between two patterns is assumed to be an AND.
	-- Quotes can be used to aggregate search patterns that contain one or more  -
	-- blank spaces.
	--
	FUNCTION parse_search_string (p_search_patterns   IN VARCHAR2,
											p_search_column	  IN VARCHAR2,
											p_use_upper 		  IN BOOLEAN DEFAULT TRUE
										  )
		RETURN VARCHAR2
	--------------------------------------------------------------------------------
	-- Usage:																				-
	--   *  - wild card character matches zero or more occurences. 		-
	--   ?  - wild card character matches zero or one occurence.			-
	--   and - AND or a blank space, e.g., abc* *123 is eqivalent to		-
	-- 										  abc* AND *123							-
	--   or - OR  e.g., abc* OR *123 												-
	--   not - NOT or a dash, e.g., 'NOT abc*' is equivalent to '-abc*'     -
	--   " " - quotes are used to aggregate patters that have blank spaces   -
	-- 	 e.g., "abc 123*"                                              -
	--
	--   One can use the backslash as an escape character for the following  -
	--   special characters:															-
	--   \* used to make an asterisks a literal instead of a wild character  - 																		 -
	--   \? used to make a question mark a literal instead of a wild		-
	--   character 																		-
	--   \- used to start a new parse pattern with a dash instead of a NOT -
	--   \" used to make a quote a literal part of the parse pattern.        -
	--
	-- Example:
	-- p_search_column: COLUMN_OF_INTEREST 										-
	-- p_search_patterns: cb* NOT cbt* OR NOT cbk*								-
	--   will return: 																	-
	-- 			AND UPPER(COLUMN_OF_INTEREST)  LIKE 'CB%'                -
	-- 			AND UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBT%'            -
	-- 			OR UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBK%'             -
	--
	--  if p_use_upper is set to false, the above will return:
	--
	-- 			 AND COLUMN_OF_INTEREST  LIKE 'cb%'                      -
	-- 			 AND COLUMN_OF_INTEREST NOT LIKE 'cbt%'                  -
	-- 			 OR COLUMN_OF_INTEREST NOT LIKE 'cbk%'                   -
	--
	--  A null p_search_patterns generates a result of '%'.
	--
	-- 			 AND COLUMN_OF_INTEREST  LIKE '%'                        -
	--------------------------------------------------------------------------------
	--
	IS
		l_string 							VARCHAR2 (256)
				:= TRIM (p_search_patterns) ;
		l_search_column					VARCHAR2 (30)
				:= UPPER (TRIM (p_search_column)) ;
		l_use_upper 						BOOLEAN := NVL (p_use_upper, TRUE);
		l_recognize_sql					BOOLEAN := FALSE;
		l_string_length					NUMBER := NVL (LENGTH (l_string), 0);
		l_skip								NUMBER := 0;
		l_looking_first_quote			BOOLEAN := TRUE;
		l_sub_string_done 				BOOLEAN := FALSE;
		l_first_char						BOOLEAN := TRUE;
		l_char								VARCHAR2 (1);
		l_sub_string						VARCHAR2 (64) := NULL;
		l_not 								VARCHAR2 (3) := NULL;
		l_and_or 							VARCHAR2 (3) := 'AND';
		l_result 							VARCHAR2 (1000) := NULL;
		l_open_upper						VARCHAR2 (7);
		l_close_upper						VARCHAR2 (2);
		l_open_paran						VARCHAR2 (10) := NULL;
		l_close_paran						VARCHAR2 (10) := NULL;
		l_space								VARCHAR2 (1) := ' ';
		l_num_open_paran					NUMBER := 0;
		l_char_position					NUMBER := 0;
		l_num_element						NUMBER := 0;
		l_t									VARCHAR2 (1);
		l_tmp_string						VARCHAR2 (100) := NULL;
		l_is_closing_quotes				BOOLEAN;
	BEGIN
		--
		-- set the UPPER( ) wrapper...
		IF l_use_upper
		THEN
			l_open_upper := ' UPPER(';
			l_close_upper := ') ';
		ELSE
			l_open_upper := ' ';
			l_close_upper := ' ';
		END IF;

		--
		-- Make sure something was passed in.
		IF l_string_length > 0
		THEN
			FOR i IN 1 .. LENGTH (l_string)
			LOOP
				--   IF l_looking_first_quote
				--   THEN
				--   l_t := 'T';
				--   ELSE
				--   l_t := 'F';
				--   END IF;

				--   DBMS_OUTPUT.put_line (  l_t
				-- 						  || l_char_position
				-- 						  || '>'
				-- 						  || l_sub_string
				-- 						  || '< skip: '
				-- 						  || l_skip
				-- 						 );
				IF l_skip > 0
				THEN
					l_skip := l_skip - 1;
				ELSE
					l_char := SUBSTR (l_string, i, 1);

					--dbms_output.put_line('>>' || l_char || '<<');
					CASE l_char
						WHEN '\'
						THEN
							IF REGEXP_INSTR (NVL (SUBSTR (l_string, i + 1, 1), ' '),
												  '["*?\(\)]'
												 ) = 1
							THEN
								l_sub_string :=
									l_sub_string || '\' || SUBSTR (l_string, i + 1, 1);
								l_char_position := l_char_position + 2;
							ELSE
								l_sub_string :=
									l_sub_string || SUBSTR (l_string, i + 1, 1);
								l_char_position := l_char_position + 1;
							END IF;

							l_skip := l_skip + 1;
						WHEN '('
						THEN
							IF l_char_position = 0
							THEN
								l_sub_string := l_sub_string || l_char;
							ELSE
								l_sub_string := l_sub_string || l_char;
								l_char_position := l_char_position + 1;
							END IF;
						WHEN ')'
						THEN
							l_tmp_string := NULL;

							FOR j IN i .. l_string_length
							LOOP
								l_tmp_string := l_tmp_string || ')';
								l_skip := l_skip + 1;

								--DBMS_OUTPUT.put_line (l_tmp_string);
								IF j = l_string_length
									OR INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '),
												 ' '
												) = 1
								THEN
									l_is_closing_quotes := TRUE;
									EXIT;
								ELSIF INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '), ')') = 1
								THEN
									NULL;
								ELSE
									l_is_closing_quotes := FALSE;
									EXIT;
								END IF;
							END LOOP;

							IF l_is_closing_quotes
							THEN
								l_close_paran := l_tmp_string;
							ELSE
								l_sub_string := l_sub_string || l_tmp_string;
							END IF;
						WHEN '"'
						THEN
							IF l_looking_first_quote
							THEN
								IF l_char_position = 0
								THEN
									l_looking_first_quote := FALSE;
								ELSE
									l_sub_string := l_sub_string || l_char;
									l_char_position := l_char_position + 1;
								END IF;
							ELSE								 -- looking for the end quote.
								--
								-- An end quote must be followed by a space or end the string.
								--
								l_tmp_string := NULL;

								FOR j IN i .. l_string_length
								LOOP
									-- l_tmp_string := l_tmp_string || ')';
									--l_skip := l_skip + 1;
									--DBMS_OUTPUT.put_line (l_tmp_string);
									IF j = l_string_length
										OR INSTR (
											  NVL (SUBSTR (l_string, j + 1, 1), ' '),
											  ' '
										  ) = 1
									THEN
										l_is_closing_quotes := TRUE;
										l_sub_string_done := TRUE;
										--dbms_output.put_line('string is done!');
										EXIT;
									ELSIF INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '), ')') = 1
									THEN
										l_tmp_string := l_tmp_string || ')';
										l_skip := l_skip + 1;
									ELSE
										l_is_closing_quotes := FALSE;
										EXIT;
									END IF;
								END LOOP;

								IF l_is_closing_quotes
								THEN
									l_close_paran := l_tmp_string;
								ELSE
									l_sub_string := '"' || l_sub_string || l_tmp_string;
								END IF;
							-----------------
							-- 			 IF	 INSTR (NVL (SUBSTR (l_string, i + 1), ' '), ' ') =
							-- 																						1
							-- 				 OR i = l_string_length
							-- 			 THEN
							-- 				 l_skip := l_skip + 1;
							-- 				 l_sub_string_done := TRUE;
							-- 			 ELSE
							-- 				 l_sub_string := l_sub_string || l_char;
							-- 				 l_char_position := l_char_position + 1;
							-- 			 END IF;
							END IF;
						WHEN ' '
						THEN
							IF l_looking_first_quote
							THEN
								l_sub_string_done := TRUE;
							ELSE
								l_sub_string := l_sub_string || l_char;
								l_char_position := l_char_position + 1;
							END IF;
						ELSE
							l_sub_string := l_sub_string || l_char;
							l_char_position := l_char_position + 1;
					END CASE;
				END IF;

				IF l_sub_string_done OR i = l_string_length
				THEN
					IF LENGTH (l_sub_string) > 0
					THEN
						IF i = l_string_length
						THEN
							l_sub_string_done := TRUE;
						END IF;

						IF l_looking_first_quote
						THEN
							CASE l_sub_string
								WHEN 'OR'
								THEN
									l_and_or := 'OR';
									l_sub_string_done := FALSE;
								WHEN 'AND'
								THEN
									l_and_or := 'AND';
									l_sub_string_done := FALSE;
								WHEN 'NOT'
								THEN
									l_not := 'NOT';
									l_sub_string_done := FALSE;
								ELSE
									NULL;
							END CASE;
						END IF;

						IF l_sub_string_done
						THEN
							l_sub_string :=
								cwms_util.normalize_wildcards (
									p_string 			=> l_sub_string,
									p_recognize_sql	=> l_recognize_sql
								);

							IF l_use_upper
							THEN
								l_sub_string := UPPER (l_sub_string);
							END IF;

							IF l_num_element = 0
							THEN
								l_and_or := ' ( ';
								l_num_element := 1;
							END IF;

							l_result :=
									l_result
								|| ' '
								|| l_and_or
								|| l_space
								|| l_open_paran
								|| l_open_upper
								|| l_search_column
								|| l_close_upper
								|| l_not
								|| ' LIKE '''
								|| l_sub_string
								|| ''' '
								|| l_close_paran
								|| l_space
								|| CHR (10);
							l_and_or := 'AND';
							l_not := NULL;
							l_open_paran := NULL;
							l_close_paran := NULL;
							l_looking_first_quote := TRUE;
						END IF;
					END IF;

					l_first_char := TRUE;
					l_sub_string := NULL;
					l_sub_string_done := FALSE;
					l_char_position := 0;
				END IF;
			END LOOP;

			l_result := l_result || ' ) ';
		ELSE
			l_result := ' 1 = 1 ';
		END IF;

		RETURN l_result;
	END parse_search_string;

	--------------------------------------------------------------------
	-- Return a string with all leading and trailing whitespace removed.
	--
	FUNCTION strip (p_text IN VARCHAR2)
		RETURN VARCHAR2
	IS
		l_text								VARCHAR2 (32767);
	BEGIN
		l_text :=
			REGEXP_REPLACE (p_text, '^[[:space:]]*(.*)[[:space:]]*$', '\1');
		RETURN l_text;
	END strip;

	--------------------------------------------------------------------------------
	PROCEDURE test
	IS
	BEGIN
		DBMS_OUTPUT.put_line ('successful test');
	END;

	FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN	 p_base_id
				 || SUBSTR ('-', 1, LENGTH (TRIM (p_sub_id)))
				 || TRIM (p_sub_id);
	END;

	FUNCTION concat_ts_id (p_base_location_id 	IN VARCHAR2,
								  p_sub_location_id		IN VARCHAR2,
								  p_base_parameter_id	IN VARCHAR2,
								  p_sub_parameter_id 	IN VARCHAR2,
								  p_parameter_type_id	IN VARCHAR2,
								  p_interval_id			IN VARCHAR2,
								  p_duration_id			IN VARCHAR2,
								  p_version_id 			IN VARCHAR2
								 )
		RETURN VARCHAR2
	IS
		l_base_location_id				VARCHAR2 (16)
				:= TRIM (p_base_location_id) ;
		l_sub_location_id 				VARCHAR2 (32) := TRIM (p_sub_location_id);
		l_base_parameter_id				VARCHAR2 (16)
				:= TRIM (p_base_parameter_id) ;
		l_sub_parameter_id				VARCHAR2 (32)
				:= TRIM (p_sub_parameter_id) ;
		l_parameter_type_id				VARCHAR2 (16)
				:= TRIM (p_parameter_type_id) ;
		l_interval_id						VARCHAR2 (16) := TRIM (p_interval_id);
		l_duration_id						VARCHAR2 (16) := TRIM (p_duration_id);
		l_version_id						VARCHAR2 (32) := TRIM (p_version_id);
	BEGIN
		SELECT	cbp.base_parameter_id
		  INTO	l_base_parameter_id
		  FROM	cwms_base_parameter cbp
		 WHERE	UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

		SELECT	cpt.parameter_type_id
		  INTO	l_parameter_type_id
		  FROM	cwms_parameter_type cpt
		 WHERE	UPPER (cpt.parameter_type_id) = UPPER (l_parameter_type_id);

		SELECT	interval_id
		  INTO	l_interval_id
		  FROM	cwms_interval ci
		 WHERE	UPPER (ci.interval_id) = UPPER (l_interval_id);

		SELECT	duration_id
		  INTO	l_duration_id
		  FROM	cwms_duration cd
		 WHERE	UPPER (cd.duration_id) = UPPER (l_duration_id);

		IF l_parameter_type_id = 'Inst' AND l_duration_id != '0'
		THEN
			cwms_err.raise (
				'GENERIC_ERROR',
					'The Duration Id for an "Inst" record cannot be "'
				|| l_duration_id
				|| '". The Duration Id must be "0".'
			);
		ELSIF l_parameter_type_id IN ('Ave', 'Max', 'Min', 'Total') AND l_duration_id = '0'
		THEN
			cwms_err.raise (
				'GENERIC_ERROR',
					'A Parameter Type of "'
				|| l_parameter_type_id
				|| '" cannot have a "0" Duration Id.'
			);
		END IF;

		RETURN	 l_base_location_id
				 || SUBSTR ('-', 1, LENGTH (l_sub_location_id))
				 || l_sub_location_id
				 || '.'
				 || l_base_parameter_id
				 || SUBSTR ('-', 1, LENGTH (l_sub_parameter_id))
				 || l_sub_parameter_id
				 || '.'
				 || l_parameter_type_id
				 || '.'
				 || l_interval_id
				 || '.'
				 || l_duration_id
				 || '.'
				 || l_version_id;
	END;

	--------------------------------------------------------------------------------
	-- function get_time_zone_code
	--
	FUNCTION get_time_zone_code (p_time_zone_name IN VARCHAR2)
		RETURN NUMBER
	IS
		l_time_zone_code					NUMBER (10);
	BEGIN
		SELECT	time_zone_code
		  INTO	l_time_zone_code
		  FROM	cwms_time_zone
		 WHERE	UPPER (time_zone_name) = UPPER (NVL (p_time_zone_name, 'UTC'));

		RETURN l_time_zone_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			cwms_err.raise ('INVALID_TIME_ZONE', p_time_zone_name);
	END get_time_zone_code;

	--------------------------------------------------------------------------------
	-- function get_tz_usage_code
	--
	FUNCTION get_tz_usage_code (p_tz_usage_id IN VARCHAR2)
		RETURN NUMBER
	IS
		l_tz_usage_code					NUMBER (10);
	BEGIN
		SELECT	tz_usage_code
		  INTO	l_tz_usage_code
		  FROM	cwms_tz_usage
		 WHERE	UPPER (tz_usage_id) = UPPER (NVL (p_tz_usage_id, 'Standard'));

		RETURN l_tz_usage_code;
	EXCEPTION
		WHEN NO_DATA_FOUND
		THEN
			cwms_err.raise ('INVALID_ITEM',
								 p_tz_usage_id,
								 'CWMS time zone usage'
								);
	END get_tz_usage_code;

	----------------------------------------------------------------------------
	PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80 )
	IS
		i										PLS_INTEGER;
	BEGIN
		-- Dump (put_line) a character string p_str in chunks of length p_len
		i := 1;

		WHILE i < LENGTH (p_str)
		LOOP
			DBMS_OUTPUT.put_line (SUBSTR (p_str, i, p_len));
			i := i + p_len;
		END LOOP;
	END DUMP;

	----------------------------------------------------------------------------
	PROCEDURE create_view
	IS
		l_sel 								VARCHAR2 (120);
		l_sql 								VARCHAR2 (4000);

		CURSOR c1
		IS
			SELECT	*
			  FROM	at_ts_table_properties;
	BEGIN
		-- Create the partitioned timeseries table view

		-- Note: start_date and end_date are coded as ANSI DATE literals

		-- CREATE OR REPLACE FORCE VIEW AV_TSV AS
		-- select ts_code, date_time, data_entry_date, value, quality,
		--   DATE '2000-01-01' start_date, DATE '2001-01-01' end_date from IOT_2000
		-- union all
		-- select ts_code, date_time, data_entry_date, value, quality,
		--   DATE '2001-01-01' start_date, DATE '2002-01-01' end_date from IOT_2001
		l_sql := 'create or replace force view av_tsv as ';
		l_sel :=
			'select ts_code, date_time, version_date, data_entry_date, value, quality_code, DATE ''';

		FOR rec IN c1
		LOOP
			IF c1%ROWCOUNT > 1
			THEN
				l_sql := l_sql || ' union all ';
			END IF;

			l_sql :=
					l_sql
				|| l_sel
				|| TO_CHAR (rec.start_date, 'yyyy-mm-dd')
				|| ''' start_date, DATE '''
				|| TO_CHAR (rec.end_date, 'yyyy-mm-dd')
				|| ''' end_date from '
				|| rec.table_name;
		END LOOP;

		cwms_util.DUMP (l_sql);

		EXECUTE IMMEDIATE l_sql;
	EXCEPTION
		-- ORA-24344: success with compilation error
		WHEN OTHERS
		THEN
			--dbms_output.put_line(SQLERRM);
			RAISE;
	END create_view;

	-------------------------------------------------------------------------------
	-- function split_text(...)
	--
	--
	FUNCTION split_text (p_text		  IN VARCHAR2,
								p_separator   IN VARCHAR2 DEFAULT NULL ,
								p_max_split   IN INTEGER DEFAULT NULL
							  )
		RETURN str_tab_t
	IS
		l_str_tab							str_tab_t := str_tab_t ();
		l_str 								VARCHAR2 (32767);
		l_field								VARCHAR2 (32767);
		l_pos 								PLS_INTEGER;
		l_sep 								VARCHAR2 (32767);
		l_sep_len							PLS_INTEGER;
		l_split_count						PLS_INTEGER := 0;
		l_count_splits 					BOOLEAN;
	BEGIN
		IF p_max_split IS NULL
		THEN
			l_count_splits := FALSE;
		ELSE
			l_count_splits := TRUE;
		END IF;

		IF p_separator IS NULL
		THEN
			l_str := REGEXP_REPLACE (p_text, '\s+', ' ');
			l_sep := ' ';
		ELSE
			l_str := p_text;
			l_sep := p_separator;
		END IF;

		l_sep_len := LENGTH (l_sep);

		LOOP
			l_pos := NVL (INSTR (l_str, l_sep), 0);

			IF l_count_splits
			THEN
				IF l_split_count = p_max_split
				THEN
					l_pos := 0;
				END IF;
			END IF;

			IF l_pos = 0
			THEN
				l_field := l_str;
				l_str := NULL;
			ELSE
				l_split_count := l_split_count + 1;
				l_field := SUBSTR (l_str, 1, l_pos - 1);
				l_str := SUBSTR (l_str, l_pos + l_sep_len);
			-- null if > length(l_str)
			END IF;

			l_str_tab.EXTEND;
			l_str_tab (l_str_tab.LAST) := l_field;
			EXIT WHEN l_pos = 0;
		END LOOP;

		RETURN l_str_tab;
	END split_text;

	-------------------------------------------------------------------------------
	-- function split_text(...)
	--
	--
	FUNCTION split_text (p_text		  IN CLOB,
								p_separator   IN VARCHAR2 DEFAULT NULL ,
								p_max_split   IN INTEGER DEFAULT NULL
							  )
		RETURN str_tab_t
	IS
		l_clob								CLOB := p_text;
		l_rows								str_tab_t := str_tab_t ();
		l_new_rows							str_tab_t;
		l_buf 								VARCHAR2 (32767) := '';
		l_chunk								VARCHAR2 (4000);
		l_clob_offset						BINARY_INTEGER := 1;
		l_buf_offset						BINARY_INTEGER := 1;
		l_amount 							BINARY_INTEGER;
		l_clob_len							BINARY_INTEGER;
		l_last								BINARY_INTEGER;
		l_done_reading 					BOOLEAN;
		chunk_size CONSTANT				BINARY_INTEGER := 4000;
	BEGIN
		IF p_text IS NULL
		THEN
			RETURN NULL;
		END IF;

		l_clob_len := DBMS_LOB.getlength (l_clob);
		l_amount := chunk_size;
		DBMS_LOB.open (l_clob, DBMS_LOB.lob_readonly);

		LOOP
			DBMS_LOB.read (l_clob, l_amount, l_clob_offset, l_chunk);
			l_clob_offset := l_clob_offset + l_amount;
			l_done_reading := l_clob_offset > l_clob_len;
			l_buf := l_buf || l_chunk;

			IF INSTR (l_buf, p_separator) > 0 OR l_done_reading
			THEN
				l_new_rows := split_text (l_buf, p_separator);

				FOR i IN 1 .. l_new_rows.COUNT - 1
				LOOP
					l_rows.EXTEND;
					l_rows (l_rows.LAST) := l_new_rows (i);
				END LOOP;

				l_buf := l_new_rows (l_new_rows.COUNT);

				IF l_done_reading
				THEN
					l_rows.EXTEND;
					l_rows (l_rows.LAST) := l_buf;
				END IF;
			END IF;

			EXIT WHEN l_done_reading;
		END LOOP;

		DBMS_LOB.close (l_clob);
		RETURN l_rows;
	END split_text;

	-------------------------------------------------------------------------------
	-- function join_text(...)
	--
	--
	FUNCTION join_text (p_text_tab	 IN str_tab_t,
							  p_separator	 IN VARCHAR2 DEFAULT NULL
							 )
		RETURN VARCHAR2
	IS
		l_text								VARCHAR2 (32767) := NULL;
	BEGIN
		FOR i IN 1 .. p_text_tab.COUNT
		LOOP
			IF i > 1
			THEN
				l_text := l_text || p_separator;
			END IF;

			l_text := l_text || p_text_tab (i);
		END LOOP;

		RETURN l_text;
	END join_text;

	--------------------------------------------------------------------------------
	-- procedure format_xml(...)
	--
	PROCEDURE format_xml (p_xml_clob IN OUT NOCOPY CLOB, p_indent IN VARCHAR2)
	IS
		l_lines								str_tab_t;
		l_level								BINARY_INTEGER := 0;
		l_len 								BINARY_INTEGER
				:= LENGTH (NVL (p_indent, '')) ;
		l_newline CONSTANT				VARCHAR2 (1) := CHR (10);

		PROCEDURE write_line (p_line IN VARCHAR2)
		IS
		BEGIN
			IF l_len > 0
			THEN
				FOR i IN 1 .. l_level
				LOOP
					DBMS_LOB.writeappend (p_xml_clob, l_len, p_indent);
				END LOOP;
			END IF;

			DBMS_LOB.writeappend (p_xml_clob,
										 LENGTH (p_line) + 1,
										 p_line || l_newline
										);
		END;
	BEGIN
		IF p_xml_clob IS NOT NULL
		THEN
			p_xml_clob := REPLACE (p_xml_clob, '<', l_newline || '<');
			p_xml_clob := REPLACE (p_xml_clob, '>', '>' || l_newline);
			p_xml_clob := REPLACE (p_xml_clob, l_newline || l_newline, l_newline);
			l_lines := split_text (p_xml_clob, l_newline);
			DBMS_LOB.open (p_xml_clob, DBMS_LOB.lob_readwrite);
			DBMS_LOB.TRIM (p_xml_clob, 0);

			FOR i IN l_lines.FIRST .. l_lines.LAST
			LOOP
				FOR once IN 1 .. 1
				LOOP
					EXIT WHEN l_lines (i) IS NULL;
					l_lines (i) := TRIM (l_lines (i));
					EXIT WHEN LENGTH (l_lines (i)) = 0;

					IF INSTR (l_lines (i), '<') = 1
					THEN
						IF INSTR (l_lines (i), '<!--') = 1
						THEN
							write_line (l_lines (i));
						ELSIF INSTR (l_lines (i), '</') = 1
						THEN
							l_level := l_level - 1;
							write_line (l_lines (i));
						ELSE
							write_line (l_lines (i));

							IF INSTR (l_lines (i), '<xml?') != 1
								AND INSTR (l_lines (i), '/>', -1) !=
										LENGTH (l_lines (i)) - 1
							THEN
								l_level := l_level + 1;
							END IF;
						END IF;
					ELSE
						write_line (l_lines (i));
					END IF;
				END LOOP;
			END LOOP;

			DBMS_LOB.close (p_xml_clob);
		END IF;
	END format_xml;

	-------------------------------------------------------------------------------
	-- function parse_clob_recordset(...)
	--
	--
	FUNCTION parse_clob_recordset (p_clob IN CLOB)
		RETURN str_tab_tab_t
	IS
		l_rows								str_tab_t;
		l_tab 								str_tab_tab_t := str_tab_tab_t ();
	BEGIN
		IF p_clob IS NULL
		THEN
			RETURN NULL;
		END IF;

		l_rows := split_text (p_clob, record_separator);

		FOR i IN l_rows.FIRST .. l_rows.LAST
		LOOP
			l_tab.EXTEND;
			l_tab (l_tab.LAST) := split_text (l_rows (i), field_separator);
		END LOOP;

		RETURN l_tab;
	END parse_clob_recordset;

	-------------------------------------------------------------------------------
	-- function parse_string_recordset(...)
	--
	--
	FUNCTION parse_string_recordset (p_string IN VARCHAR2)
		RETURN str_tab_tab_t
	IS
		l_rows								str_tab_t;
		l_tab 								str_tab_tab_t := str_tab_tab_t ();
	BEGIN
		IF p_string IS NULL
		THEN
			RETURN NULL;
		END IF;

		l_rows := split_text (p_string, record_separator);

		FOR i IN l_rows.FIRST .. l_rows.LAST
		LOOP
			l_tab.EXTEND;
			l_tab (i) := split_text (l_rows (i), field_separator);
		END LOOP;

		RETURN l_tab;
	END parse_string_recordset;

	--------------------------------------------------------------------
	-- Return UTC timestamp for specified ISO 8601 string
	--
	FUNCTION TO_TIMESTAMP (p_iso_str IN VARCHAR2)
		RETURN timestamp
	IS
		l_yr									VARCHAR2 (5);
		l_mon 								VARCHAR2 (2) := '01';
		l_day 								VARCHAR2 (2) := '01';
		l_hr									VARCHAR2 (2) := '00';
		l_min 								VARCHAR2 (2) := '00';
		l_sec 								VARCHAR2 (8) := '00.0';
		l_tz									VARCHAR2 (32) := '+00:00';
		l_time								VARCHAR2 (32);
		l_parts								str_tab_t;
		l_ts									timestamp;
		l_offset 							INTERVAL DAY (9) TO SECOND (9);
		l_iso_pattern CONSTANT			VARCHAR2 (71)
				:= '-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:(\d{2}([.]\d+)?))?([-+]\d{2}:\d{2}|Z)?' ;
		l_str 								VARCHAR2 (64) := strip (p_iso_str);
		l_pos 								BINARY_INTEGER;
		l_add_day							BOOLEAN := FALSE;
	BEGIN
		IF REGEXP_INSTR (l_str, l_iso_pattern) != 1
			OR REGEXP_INSTR (l_str, l_iso_pattern, 1, 1, 1) !=
				  LENGTH (l_str) + 1
		THEN
			cwms_err.raise ('INVALID_ITEM', l_str, 'dateTime-formatted string');
		END IF;

		l_pos := REGEXP_INSTR (l_str, '-?\d{4}', 1, 1, 1);
		l_yr := SUBSTR (l_str, 1, l_pos - 1);
		l_str := SUBSTR (l_str, l_pos + 1);
		l_mon := SUBSTR (l_str, 1, 2);
		l_str := SUBSTR (l_str, 4);
		l_day := SUBSTR (l_str, 1, 2);
		l_str := SUBSTR (l_str, 4);
		l_hr := SUBSTR (l_str, 1, 2);
		l_str := SUBSTR (l_str, 4);
		l_min := SUBSTR (l_str, 1, 2);
		l_str := SUBSTR (l_str, 3);

		IF SUBSTR (l_str, 1, 1) = ':'
		THEN
			l_pos := REGEXP_INSTR (l_str, ':\d{2}([.]\d+)?', 1, 1, 1);
			l_sec := SUBSTR (l_str, 2, l_pos - 2);
			l_str := SUBSTR (l_str, l_pos);
		END IF;

		IF LENGTH (l_str) > 0
		THEN
			l_tz := l_str;
		END IF;

		IF l_hr = '24'
		THEN
			l_add_day := TRUE;
			l_hr := '00';
		END IF;

		l_time :=
				l_yr
			|| '-'
			|| l_mon
			|| '-'
			|| l_day
			|| 'T'
			|| l_hr
			|| ':'
			|| l_min
			|| ':'
			|| l_sec;

		----------------------------------------------------------------------
		-- use select to avoid namespace collision with CWMS_UTIL functions --
		----------------------------------------------------------------------
		SELECT	TO_TIMESTAMP (l_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF')
		  INTO	l_ts
		  FROM	DUAL;

		IF l_add_day
		THEN
			l_ts := l_ts + INTERVAL '1 00:00:00' DAY TO SECOND;
		END IF;

		--------------------------------------------------------------
		-- for some reason the TZH:TZM format only works on TO_CHAR --
		--------------------------------------------------------------
		l_tz := REPLACE (l_tz, 'Z', '+00:00');
		l_parts := split_text (SUBSTR (l_tz, 2), ':');
		l_hr := l_parts (1);
		l_min := l_parts (2);
		l_offset := TO_DSINTERVAL ('0 ' || l_hr || ':' || l_min || ':00');

		IF SUBSTR (l_tz, 1, 1) = '-'
		THEN
			l_ts := l_ts + l_offset;
		ELSE
			l_ts := l_ts - l_offset;
		END IF;

		RETURN l_ts;
	END TO_TIMESTAMP;

	--------------------------------------------------------------------
	-- Return UTC timestamp for specified Java milliseconds
	--
	FUNCTION TO_TIMESTAMP (p_millis IN NUMBER)
		RETURN timestamp
	IS
		l_millis 							NUMBER := ABS (p_millis);
		l_day 								NUMBER;
		l_hour								NUMBER;
		l_min 								NUMBER;
		l_sec 								NUMBER;
		l_negative							BOOLEAN := p_millis < 0;
		l_interval							INTERVAL DAY (9) TO SECOND (9);
	BEGIN
		l_day := TRUNC (l_millis / 86400000);
		l_millis := l_millis - (l_day * 86400000);
		l_hour := TRUNC (l_millis / 3600000);
		l_millis := l_millis - (l_hour * 3600000);
		l_min := TRUNC (l_millis / 60000);
		l_millis := l_millis - (l_min * 60000);
		l_sec := TRUNC (l_millis / 1000);
		l_millis := l_millis - (l_sec * 1000);
		l_interval :=
			TO_DSINTERVAL(   ''
							  || l_day
							  || ' '
							  || TO_CHAR (l_hour, '00')
							  || ':'
							  || TO_CHAR (l_min, '00')
							  || ':'
							  || TO_CHAR (l_sec, '00')
							  || '.'
							  || TO_CHAR (l_millis, '000'));

		IF l_negative
		THEN
			RETURN epoch - l_interval;
		ELSE
			RETURN epoch + l_interval;
		END IF;
	END TO_TIMESTAMP;

	--------------------------------------------------------------------
	-- Return Java milliseconds for a specified UTC timestamp.
	--
	FUNCTION to_millis (p_timestamp IN timestamp)
		RETURN NUMBER
	IS
		l_intvl								INTERVAL DAY (9) TO SECOND (9);
		l_millis 							NUMBER;
	BEGIN
		l_intvl := p_timestamp - epoch;
		l_millis :=
			TRUNC(  EXTRACT (DAY FROM l_intvl) * 86400000
					+ EXTRACT (HOUR FROM l_intvl) * 3600000
					+ EXTRACT (MINUTE FROM l_intvl) * 60000
					+ EXTRACT (SECOND FROM l_intvl) * 1000);
		RETURN l_millis;
	END to_millis;

	--------------------------------------------------------------------
	-- Return Java milliseconds for current time.
	--
	FUNCTION current_millis
		RETURN NUMBER
	IS
	BEGIN
		RETURN to_millis (SYS_EXTRACT_UTC (SYSTIMESTAMP));
	END current_millis;


	FUNCTION get_ts_interval (p_cwms_ts_code IN NUMBER)
		RETURN NUMBER
	IS
		l_ts_interval						NUMBER;
	BEGIN
		SELECT	a.interval
		  INTO	l_ts_interval
		  FROM	cwms_interval a, at_cwms_ts_spec b
		 WHERE	b.interval_code = a.interval_code
					AND b.ts_code = p_cwms_ts_code;

		RETURN l_ts_interval;
	END get_ts_interval;

	PROCEDURE get_valid_units (p_valid_units		  OUT sys_refcursor,
										p_parameter_id   IN		VARCHAR2 DEFAULT NULL
									  )
	IS
	BEGIN
		IF p_parameter_id IS NULL
		THEN
			OPEN p_valid_units FOR
				SELECT	a.unit_id
				  FROM	cwms_unit a;
		ELSE
			OPEN p_valid_units FOR
				SELECT	a.unit_id
				  FROM	cwms_unit a
				 WHERE	abstract_param_code =
								(SELECT	 abstract_param_code
									FROM	 cwms_base_parameter
								  WHERE	 upper(base_parameter_id) =
												 upper(get_base_id (p_parameter_id)));
		END IF;
	END;

/* get_valid_unit_id return the properly cased unit_id for p_unit_id.
 */

    /* Formatted on 3/30/2010 2:41:05 PM (QP5 v5.139.911.3011) */
    FUNCTION get_valid_unit_id (p_unit_id			IN VARCHAR2,
                                         p_parameter_id	IN VARCHAR2 DEFAULT NULL
                                        )
        RETURN VARCHAR2
    IS
        l_unit_id	VARCHAR2 (16);
    BEGIN
        BEGIN
            SELECT	unit_id
              INTO	l_unit_id
              FROM	TABLE (get_valid_units_tab (p_parameter_id))
             WHERE	unit_id = p_unit_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                BEGIN
                    SELECT	unit_id
                      INTO	l_unit_id
                      FROM	TABLE (get_valid_units_tab (p_parameter_id))
                     WHERE	UPPER (unit_id) = UPPER (p_unit_id);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        IF p_parameter_id IS NULL
                        THEN
                            raise_application_error (
                                -20102,
                                    'The unit: '
                                || TRIM (p_unit_id)
                                || ' is not a recognized CWMS Database unit.',
                                TRUE
                            );
                        ELSE
                            raise_application_error (
                                -20102,
                                    'The unit: '
                                || TRIM (p_unit_id)
                                || ' is not a recognized CWMS Database unit for the '
                                || TRIM (p_parameter_id)
                                || ' Parameter_ID.',
                                TRUE
                            );
                        END IF;
                    WHEN TOO_MANY_ROWS
                    THEN
                        raise_application_error (
                            -20102,
                                'The unit: '
                            || TRIM (p_unit_id)
                            || ' has multiple matches in the CWMS Database.'
                            || ' Please specify the Parameter_ID and/or use the'
                            || ' exact letter casing for the desired unit.',
                            TRUE
                        );
                END;
        END;

        RETURN l_unit_id;
    END;

	FUNCTION get_valid_units_tab (p_parameter_id IN VARCHAR2 DEFAULT NULL )
		RETURN cat_unit_tab_t
		PIPELINED
	IS
		l_query_cursor 					sys_refcursor;
		l_output_row						cat_unit_rec_t;
	BEGIN
		get_valid_units (l_query_cursor, p_parameter_id);

		LOOP
			FETCH l_query_cursor INTO									l_output_row;

			EXIT WHEN l_query_cursor%NOTFOUND;
			PIPE ROW (l_output_row);
		END LOOP;

		CLOSE l_query_cursor;
	END;

	FUNCTION get_unit_code (p_unit_id				 IN VARCHAR2,
									p_abstract_param_id	 IN VARCHAR2 DEFAULT NULL ,
									p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
								  )
		RETURN NUMBER
	IS
		l_unit_code 						NUMBER;
		l_db_office_code					VARCHAR2 (16)
				:= get_db_office_code (p_db_office_id) ;
	BEGIN
		IF p_abstract_param_id IS NULL
		THEN
			BEGIN
				SELECT	unit_code
				  INTO	l_unit_code
				  FROM	av_unit
				 WHERE	unit_id = TRIM (p_unit_id)
							AND db_office_code IN (l_db_office_code, 53);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_ITEM',
										 TRIM (p_unit_id),
										 'unit id. Note units are case senstive.'
										);
				WHEN TOO_MANY_ROWS
				THEN
					cwms_err.raise (
						'ERROR',
							'More than one entry was found for the unit: "'
						|| TRIM (p_unit_id)
						|| '". Try specifying the p_abstract_param for this unit.'
					);
			END;
		ELSE
			BEGIN
				SELECT	unit_code
				  INTO	l_unit_code
				  FROM	av_unit
				 WHERE	unit_id = TRIM (p_unit_id)
							AND db_office_code IN (l_db_office_code, 53)
							AND abstract_param_code =
									(SELECT	 abstract_param_code
										FROM	 cwms_abstract_parameter
									  WHERE	 abstract_param_id =
													 UPPER (TRIM (p_abstract_param_id)));
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise ('INVALID_ITEM',
										 TRIM (p_unit_id),
										 'unit id. Note units are case senstive.'
										);
			END;
		END IF;

		RETURN l_unit_code;
	END;

	FUNCTION get_loc_group_code (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_db_office_code	 IN NUMBER
										 )
		RETURN NUMBER
	IS
		l_loc_group_code					NUMBER;
	BEGIN
		IF p_db_office_code IS NULL
		THEN
			cwms_err.raise ('ERROR', 'p_db_office_code cannot be null.');
		END IF;

		--
		IF p_loc_category_id IS NOT NULL AND p_loc_group_id IS NOT NULL
		THEN
			BEGIN
				SELECT	loc_group_code
				  INTO	l_loc_group_code
				  FROM	at_loc_group a, at_loc_category b
				 WHERE	a.loc_category_code = b.loc_category_code
							AND UPPER (b.loc_category_id) =
									UPPER (TRIM (p_loc_category_id))
							AND b.db_office_code IN
										(p_db_office_code, cwms_util.db_office_code_all)
							AND UPPER (a.loc_group_id) =
									UPPER (TRIM (p_loc_group_id))
							AND a.db_office_code IN
										(p_db_office_code, cwms_util.db_office_code_all);
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise (
						'ERROR',
							'Could not find '
						|| TRIM (p_loc_category_id)
						|| '-'
						|| TRIM (p_loc_group_id)
						|| ' category-group combination'
					);
			END;
		ELSIF (p_loc_category_id IS NOT NULL AND p_loc_group_id IS NULL) OR (p_loc_category_id IS NULL AND p_loc_group_id IS NOT NULL)
		THEN
			cwms_err.raise (
				'ERROR',
				'The loc_category_id and loc_group_id is not a valid combination'
			);
		END IF;

		RETURN l_loc_group_code;
	END get_loc_group_code;

	FUNCTION get_loc_group_code (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_db_office_id		 IN VARCHAR2
										 )
		RETURN NUMBER
	IS
	BEGIN
		RETURN get_loc_group_code (
					 p_loc_category_id	=> p_loc_category_id,
					 p_loc_group_id		=> p_loc_group_id,
					 p_db_office_code 	=> cwms_util.get_db_office_code (
													  p_db_office_id
												  )
				 );
	END get_loc_group_code;

	--------------------------------------------------------------------------------
	-- get_user_id uses either sys_context or the apex authenticated user id. -
	--
	-- The "v" function is installed with apex - so apex needs to be installed     -
	-- for this package to compile.
	--------------------------------------------------------------------------------
	FUNCTION get_user_id
		RETURN VARCHAR2
	IS
		l_user_id							VARCHAR2 (31);
	BEGIN
		IF v ('APP_USER') != 'APEX_PUBLIC_USER' AND v ('APP_USER') IS NOT NULL
		THEN
			l_user_id := v ('APP_USER');
		ELSE
			l_user_id := SYS_CONTEXT ('userenv', 'session_user');
		END IF;

		RETURN UPPER (l_user_id);
	END get_user_id;

   procedure user_display_unit(
      p_unit_id      out varchar2,
      p_value_out    out number,
      p_parameter_id in  varchar2,
      p_value_in     in  number   default null,
      p_user_id      in  varchar2 default null,
      p_office_id    in  varchar2 default null)
   is
      l_unit_system         varchar2(2)  := 'SI';
      l_user_id             varchar2(31) := upper(nvl(p_user_id, get_user_id));
      l_office_id           varchar2(16) := get_db_office_id(p_office_id);
      l_base_parameter_id   varchar2(16) := get_base_id(p_parameter_id);
      l_office_code         number       := get_db_office_code(p_office_id);
      l_unit_code           number;
      l_base_parameter_code number;
   begin
      p_unit_id := null;
      p_value_out := null;
      --
      -- get preferred unit system
      --
      begin
         select display_unit_system
           into l_unit_system
           from at_user_preferences
          where db_office_code = l_office_code
            and username = l_user_id;
      exception
         when no_data_found then null;
      end;
      --
      -- get display unit for parameter in preferred unit system
      --
      begin
         select base_parameter_code,
                case l_unit_system
                  when 'SI' then display_unit_code_si
                  when 'EN' then display_unit_code_en
                end
           into l_base_parameter_code,
                l_unit_code
           from cwms_base_parameter
          where upper(base_parameter_id) = upper(l_base_parameter_id);                
      exception
         when no_data_found then
            cwms_err.raise('INVALID_PARAM_ID', p_parameter_id);
      end;
      select unit_id 
        into p_unit_id 
        from cwms_unit 
       where unit_code = l_unit_code;
      --
      -- convert the specified value from storage unit
      --
      if p_value_in is not null then
         select p_value_in * cuc.factor + cuc.offset
           into p_value_out
           from cwms_unit_conversion cuc,
                cwms_base_parameter bp
          where bp.base_parameter_code = l_base_parameter_code
            and cuc.from_unit_code = bp.unit_code
            and cuc.to_unit_code = l_unit_code;
      end if;        
   end user_display_unit;      

	FUNCTION get_interval_string (p_interval IN NUMBER)
		RETURN VARCHAR2
	IS
	--   public static final String YEAR_TIME_INTERVAL  = "yr";
	--   public static final String MONTH_TIME_INTERVAL = "mo";
	--   public static final String WEEK_TIME_INTERVAL  = "wk";
	--   public static final String DAY_TIME_INTERVAL = "dy";
	--   public static final String HOUR_TIME_INTERVAL  = "hr";
	--   public static final String MINUTE_TIME_INTERVAL = "mi";
	BEGIN
		RETURN '13mi';
	END;

   function get_user_display_unit(
      p_parameter_id in varchar2,
      p_user_id      in varchar2 default null,
      p_office_id    in varchar2 default null)
   return varchar2
   is
      l_unit_id   varchar2(16);
      l_value_out number;
   begin
      user_display_unit(
         l_unit_id,
         l_value_out,
         p_parameter_id,
         1.0,
         p_user_id,
         p_office_id);
         
      return l_unit_id;         
   end get_user_display_unit;      
      
	----------------------------------------------------------------------------
	FUNCTION get_default_units (p_parameter_id	IN VARCHAR2,
										 p_unit_system 	IN VARCHAR2 DEFAULT 'SI'
										)
		RETURN VARCHAR2
	AS
		l_default_units					VARCHAR2 (16);
		l_base_param_code 				NUMBER;
	BEGIN
      if p_parameter_id is null then 
         return null; 
      end if;
		l_base_param_code := get_base_param_code(get_base_id(p_parameter_id));

		IF UPPER (p_unit_system) = 'SI'
		THEN
			SELECT	a.unit_id
			  INTO	l_default_units
			  FROM	cwms_unit a, cwms_base_parameter b
			 WHERE	a.unit_code = b.display_unit_code_si
						AND b.base_parameter_code = l_base_param_code;
		ELSIF UPPER (p_unit_system) = 'EN'
		THEN
			SELECT	a.unit_id
			  INTO	l_default_units
			  FROM	cwms_unit a, cwms_base_parameter b
			 WHERE	a.unit_code = b.display_unit_code_en
						AND b.base_parameter_code = l_base_param_code;
		ELSE
			cwms_err.raise ('INVALID_ITEM',
								 p_unit_system,
								 'Unit System. Use either SI or EN'
								);
		END IF;

		RETURN l_default_units;
	END;
      
   function convert_to_db_units(
      p_value        in binary_double,
      p_parameter_id in varchar2,
      p_unit_id      in varchar2)
   return binary_double
   is
      l_factor binary_double;
      l_offset binary_double;
   begin
      select uc.factor,
             uc.offset
        into l_factor,
             l_offset
        from cwms_unit_conversion uc,
             cwms_base_parameter bp
       where bp.base_parameter_id = get_base_id(p_parameter_id)
         and uc.to_unit_code = bp.unit_code
         and uc.from_unit_id = p_unit_id;
         
      return p_value * l_factor + l_offset;         
   end;      
                             
   function convert_units(
      p_value        in binary_double,
      p_from_unit_id in varchar2,
      p_to_unit_id   in varchar2)
   return binary_double result_cache
   is
      l_factor binary_double;
      l_offset binary_double;
   begin
      select factor,
             offset
        into l_factor,
             l_offset
        from cwms_unit_conversion
       where from_unit_id = p_from_unit_id
         and to_unit_id = p_to_unit_id;
         
      return p_value * l_factor + l_offset;         
   end;   

	--
	-- sign-extends 32-bit integers so they can be retrieved by
	-- java int type
	--
	FUNCTION sign_extend (p_int IN INTEGER)
		RETURN INTEGER
	IS
		i										INTEGER;
		bi 									BINARY_INTEGER;
		numeric_overflow exception;
		PRAGMA EXCEPTION_INIT (numeric_overflow, -1426);
	BEGIN
		BEGIN
			bi := p_int;
		EXCEPTION
			WHEN numeric_overflow
			THEN
				BEGIN
					bi := p_int - 4294967296;
				EXCEPTION
					WHEN OTHERS
					THEN
						cwms_err.raise ('INVALID_ITEM', p_int, '32-bit integer');
				END;
		END;

		i := bi;
		RETURN i;
	END;
   
   -----------------------------------
   -- function months_to_yminterval --
   -----------------------------------
   function months_to_yminterval(
      p_months in integer) 
      return interval year to month 
   is
   begin
      if p_months is null then return null; end if;
      return to_yminterval(
         to_char(trunc(p_months / 12)) 
         || '-' 
         || to_char(mod(p_months, 12)));
   end months_to_yminterval;
   
   ------------------------------------
   -- function minutes_to_dsinterval --
   ------------------------------------
   function minutes_to_dsinterval(
      p_minutes in integer) 
      return interval day to second 
   is
   begin
      if p_minutes is null then return null; end if;
      return to_dsinterval(
         to_char(trunc(p_minutes / 1440)) 
         || ' ' 
         || to_char(trunc(mod(p_minutes, 1440) / 60)) 
         || ':' 
         || to_char(mod(p_minutes, 60) || ': 00'));
   end minutes_to_dsinterval;
   
   -----------------------------------
   -- function yminterval_to_months --
   -----------------------------------
   function yminterval_to_months(
      p_intvl in interval year to month) 
      return integer 
   is
   begin
      if p_intvl is null then return null; end if;
      return 12 * extract(year from p_intvl) + extract(month from p_intvl);
   end yminterval_to_months;
   
   ------------------------------------
   -- function dsinterval_to_minutes --
   ------------------------------------
   function dsinterval_to_minutes(
      p_intvl in interval day to second) 
      return integer 
   is
   begin
      if p_intvl is null then return null; end if;
      return 1440 * extract(day    from p_intvl)
             + 60 * extract(hour   from p_intvl) 
             +      extract(minute from p_intvl);
   end dsinterval_to_minutes;
   
   -----------------------------------
   -- function parse_odbc_ts_string --
   -----------------------------------
   function parse_odbc_ts_string(
      p_odbc_str in varchar2)
      return date
   is
   begin
      if p_odbc_str is null then
         return null;
      end if;
      return to_date(p_odbc_str, odbc_ts_fmt);
   exception
      when others then
         cwms_err.raise(
            'INVALID_ITEM',
            p_odbc_str,
            'ODBC timestamp format (' || odbc_ts_fmt || ')');
   end parse_odbc_ts_string;

   ----------------------------------
   -- function parse_odbc_d_string --
   ----------------------------------
   function parse_odbc_d_string(
      p_odbc_str in varchar2)
      return date
   is
   begin
      if p_odbc_str is null then
         return null;
      end if;
      return to_date(p_odbc_str, odbc_d_fmt);
   exception
      when others then
         cwms_err.raise(
            'INVALID_ITEM',
            p_odbc_str,
            'ODBC date format (' || odbc_d_fmt || ')');
   end parse_odbc_d_string;

   ----------------------------------------
   -- function parse_odbc_ts_or_d_string --
   ----------------------------------------
   function parse_odbc_ts_or_d_string(
      p_odbc_str in varchar2)
      return date
   is
      l_date date;
   begin
      if p_odbc_str is null then
         return null;
      end if;
      l_date := parse_odbc_ts_string(p_odbc_str);
      return l_date;
   exception
      when others then
         begin
            l_date := parse_odbc_d_string(p_odbc_str);
            return l_date;
         exception
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_odbc_str,
                  'ODBC timestamp or date format ('
                  || odbc_ts_fmt
                  || ', '
                  || ')');
         end;
   end parse_odbc_ts_or_d_string;
   
   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_algebraic
   -- 
   -- Returns a table of RPN tokens for a specified algebraic expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   -----------------------------------------------------------------------------
   function tokenize_algebraic(
      p_algebraic_expr in varchar2)
      return str_tab_t result_cache
   is
      l_infix_tokens         str_tab_t;
      l_postfix_tokens       str_tab_t := new str_tab_t();
      l_stack                str_tab_t := new str_tab_t();
      l_func_stack           str_tab_t := new str_tab_t();
      l_left_paren_count     binary_integer := 0;
      l_right_paren_count    binary_integer := 0;
      l_func                 varchar2(8);
      l_dummy                varchar2(1);
                              
      procedure error
      is
      begin
         cwms_err.raise('ERROR', 'Invalid algebraic expression: ' || p_algebraic_expr);
      end;
      
      procedure token_error(token in varchar2)
      is
      begin
         cwms_err.raise('ERROR', 'Invalid token in equation: ' || token);
      end;
      
      function precedence(op in varchar2)
      return number
      is
      begin
         return 
            case op
               when '+'     then 1
               when '-'     then 1
               when '*'     then 2
               when '/'     then 2
               when '//'    then 2
               when '%'     then 2
               when '^'     then 3
            end;
      end;
      
      procedure push(p_op in varchar2)
      is
      begin
         l_stack.extend;
         l_stack(l_stack.count) := p_op;
      end;

      function pop
      return varchar2
      is
         l_op varchar2(8);
      begin
         begin
            l_op := l_stack(l_stack.count);
         exception
            when others then error;
         end;
         l_stack.trim;
         return l_op;
      end;
      
      procedure push_func(p_func in varchar2)
      is
      begin
         l_func_stack.extend;
         l_func_stack(l_func_stack.count) := p_func;
      end;

      function pop_func
      return varchar2
      is
         l_func varchar2(8);
      begin
         begin
            l_func := l_func_stack(l_func_stack.count);
         exception
            when others then error;
         end;
         l_func_stack.trim;
         return l_func;
      end;
   begin
      ---------------------------------
      -- parse the infix into tokens --
      ---------------------------------
      l_infix_tokens := cwms_util.split_text(trim(regexp_replace(upper(p_algebraic_expr), '([()])', ' \1 ')));
      -------------------------------------
      -- process the tokens into postfix --
      -------------------------------------
      for i in 1..l_infix_tokens.count loop
         case
            ---------------
            -- operators --
            ---------------
            when l_infix_tokens(i) in ('+','-','*','/','//','%','^') then
               if l_stack.count > 0 and precedence(l_stack(l_stack.count)) > precedence(l_infix_tokens(i)) then
                  l_postfix_tokens.extend;
                  l_postfix_tokens(l_postfix_tokens.count) := pop;
               end if;
               push(l_infix_tokens(i));
            ---------------
            -- functions --
            ---------------
            when l_infix_tokens(i) in ('ABS','ACOS','ASIN','ATAN','CEIL',
               'COS','EXP','FLOOR','LN','LOG', 'SIGN','SIN','TAN','TRUNC') then
               push_func(l_infix_tokens(i));
            ----------------------
            -- open parentheses --
            ----------------------
            when l_infix_tokens(i) = '(' then
               push(null);
               push_func(null);
               l_left_paren_count := l_left_paren_count + 1;
            ------------------------
            -- close parentheses --
            ------------------------
            when l_infix_tokens(i) = ')' then
               while l_stack(l_stack.count) is not null loop
                  l_postfix_tokens.extend;
                  l_postfix_tokens(l_postfix_tokens.count) := pop;
               end loop;
               l_dummy := pop;
               l_func := pop_func;
               if l_func_stack.count > 0 and l_func_stack(l_func_stack.count) is not null then
                  l_func := pop_func;
                  l_postfix_tokens.extend;
                  l_postfix_tokens(l_postfix_tokens.count) := l_func;
               end if;
               l_right_paren_count := l_right_paren_count + 1;
            ---------------------               
            -- everything else --
            ---------------------               
            else            
               l_postfix_tokens.extend;
               l_postfix_tokens(l_postfix_tokens.count) := l_infix_tokens(i);
         end case;
      end loop;
      if l_right_paren_count != l_left_paren_count then
         error;
      end if;
      while l_stack.count > 0 loop
         l_postfix_tokens.extend;
         l_postfix_tokens(l_postfix_tokens.count) := pop;
      end loop;
      return l_postfix_tokens;
   end tokenize_algebraic;      
   
   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_RPN
   -- 
   -- Returns a table of RPN tokens for a specified delimited RPN expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- All numbers, arguments and operators must be separated by whitespace
   -----------------------------------------------------------------------------
   function tokenize_RPN(
      p_RPN_expr  in varchar2)
      return str_tab_t result_cache
   is
      l_postfix_tokens str_tab_t;
   begin
      return split_text(trim(upper(p_RPN_expr)));
   end tokenize_RPN;      
      
   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_expression
   -- 
   -- Returns the result of evaluating RPN tokens against specified arguments
   --
   -- The tokens are not case sensitive
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------
   function eval_tokenized_expression(
      p_RPN_tokens  in str_tab_t,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return number
   is
      l_stack number_tab_t := new number_tab_t();
      l_val1  binary_double;
      l_val2  binary_double;
      l_idx   binary_integer;
      
      procedure token_error(token in varchar2)
      is
      begin
         cwms_err.raise('ERROR', 'Invalid token in equation: ' || token);
      end;
      
      procedure argument_error(l_idx in integer)
      is
      begin
         cwms_err.raise('ERROR', 'ARG'||l_idx||' does not exist');
      end;
      
      procedure push(val in number)
      is
      begin
         l_stack.extend;
         l_stack(l_stack.count) := val;
      end;

      function pop
      return number
      is
         val number;
      begin
         val := l_stack(l_stack.last);
         l_stack.trim;
         return val;
      end;

   begin
      for i in 1..p_RPN_tokens.count loop
         case
            ---------------
            -- operators --
            ---------------
            when p_RPN_tokens(i) = '+' then 
               push(pop + pop);
            when p_RPN_tokens(i) = '-' then 
               push(-pop + pop);
            when p_RPN_tokens(i) = '*'
                then push(pop * pop);
            when p_RPN_tokens(i) = '/' then
               l_val2 := pop; 
               l_val1 := pop; 
               push(l_val1 / l_val2);
            when p_RPN_tokens(i) = '//' then  -- same as Python
               l_val2 := pop; 
               l_val1 := pop; 
               push(floor(l_val1 / l_val2));
            when p_RPN_tokens(i) = '%' then  -- same as Python math.fmod, not %
               l_val2 := pop; 
               l_val1 := pop; 
               push(mod(l_val1, l_val2));
            when p_RPN_tokens(i) = '^' then 
               l_val2 := pop; 
               l_val1 := pop; 
               push(l_val1 ** l_val2);
            ---------------               
            -- constants --
            ---------------               
            when p_RPN_tokens(i) = 'E' then 
               push(2.7182818284590451);
            when p_RPN_tokens(i) = 'PI' then 
               push(3.1415926535897931);
            ---------------------
            -- unary functions --
            ---------------------
            when p_RPN_tokens(i) = 'ABS' then
               push(abs(pop));
            when p_RPN_tokens(i) = 'ACOS' then
               push(acos(pop));
            when p_RPN_tokens(i) = 'ASIN' then
               push(asin(pop));
            when p_RPN_tokens(i) = 'ATAN' then
               push(atan(pop));
            when p_RPN_tokens(i) = 'CEIL' then
               push(ceil(pop));
            when p_RPN_tokens(i) = 'COS' then
               push(cos(pop));
            when p_RPN_tokens(i) = 'EXP' then
               push(exp(pop));
            when p_RPN_tokens(i) = 'FLOOR' then
               push(floor(pop));
            when p_RPN_tokens(i) = 'INV' then
               push(1 / pop);
            when p_RPN_tokens(i) = 'LN' then
               push(ln(pop));
            when p_RPN_tokens(i) = 'LOG' then  -- log base 10
               push(log(10, pop));
            when p_RPN_tokens(i) = 'NEG' then
               push(pop * -1);
            when p_RPN_tokens(i) = 'SIGN' then -- not SQL sign, but +1, 0, or -1
               l_val1 := pop;
               case
                  when l_val1 < 0 then push(-1);
                  when l_val1 > 0 then push(1);
                  else push(0);
               end case;
            when p_RPN_tokens(i) = 'SIN' then
               push(sin(pop));
            when p_RPN_tokens(i) = 'TAN' then
               push(tan(pop));
            when p_RPN_tokens(i) = 'TRUNC' then
               push(trunc(pop));
            ---------------               
            -- arguments --
            ---------------               
            when substr(p_RPN_tokens(i), 1, 3) = 'ARG' then
               begin
                  l_idx := to_number(substr(p_RPN_tokens(i), 4)) + p_args_offset;
                  if l_idx < 1 or l_idx > p_args.count then
                     argument_error(l_idx - p_args_offset);
                  end if;
                  if p_args(l_idx) is null then
                     return null;
                  end if;
                  push(p_args(l_idx));
               exception
                  when others then token_error(p_RPN_tokens(i));
               end;
            when substr(p_RPN_tokens(i), 1, 4) = '-ARG' then
               begin
                  l_idx := to_number(substr(p_RPN_tokens(i), 5));
                  if l_idx < 1 or l_idx > p_args.count then
                     argument_error(l_idx - p_args_offset);
                  end if;
                  if p_args(l_idx) is null then
                     return null;
                  end if;
                  push(p_args(l_idx));
               exception
                  when others then token_error(p_RPN_tokens(i));
               end;
            -------------               
            -- numbers --
            -------------               
            else 
               begin
                 push(to_number(p_RPN_tokens(i)));
              exception
                  when others then token_error(p_RPN_tokens(i));
              end;
         end case;
      end loop;
      if l_stack.count != 1 then
         cwms_err.raise('ERROR', 'Remaining items on stack');
      end if;
      return pop;
   end eval_tokenized_expression;      
      
   -----------------------------------------------------------------------------
   -- FUNCTION eval_algebraic_expression
   -- 
   -- Returns the result of evaluating an algebraic expression against specified 
   -- arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------
   function eval_algebraic_expression(
      p_algebraic_expr in varchar2,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return number
   is
   begin
      return eval_tokenized_expression(
         tokenize_algebraic(p_algebraic_expr),
         p_args,
         p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid algebraic expression: ' || p_algebraic_expr);
   end eval_algebraic_expression;
      
   -----------------------------------------------------------------------------
   -- FUNCTION eval_RPN_expression
   -- 
   -- Returns the result of evaluating a delimited RPN expression against
   -- specified arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --                             ln, log, sign, sin, tan, trunc
   --
   -- All numbers, arguments and operators must be separated by whitespace
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------
   function eval_RPN_expression(
      p_RPN_expr    in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return number
   is
   begin
      return eval_tokenized_expression(
         tokenize_RPN(p_RPN_expr),
         p_args,
         p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid RPN expression: ' || p_RPN_expr);
   end eval_RPN_expression;      

   -----------------------------
   -- check for SQL injection --
   -----------------------------
   procedure check_inputs(
      p_input in str_tab_t
   )
   is
      procedure invalid is
      begin
         cwms_err.raise('ERROR', 'Invalid input');
      end;
   begin
      if p_input is not null then
         for i in 1..p_input.count loop
            case
               when substr(p_input(i), 1, 1)  = '' then invalid;
               when instr(p_input(i), '--' ) != 0  then invalid;
               when instr(p_input(i), '/*' ) != 0  then invalid;
               when instr(p_input(i), ';'  ) != 0  then invalid;
               else null;
            end case;
         end loop;
      end if;
   end check_inputs;
   
   procedure check_input(
      p_input in varchar2
   )
   is
   begin
      check_inputs(str_tab_t(p_input));
   end check_input;
   
   ---------------------
   -- Append routines --
   ---------------------
   procedure append(
      p_dst in out nocopy clob,
      p_src in            clob)
   is
   begin
      dbms_lob.append(p_dst, p_src);      
   end;      
      
   procedure append(
      p_dst in out nocopy clob,
      p_src in            varchar2)
   is
   begin
      dbms_lob.writeappend(p_dst, length(p_src), p_src);
   end;      
      
   procedure append(
      p_dst in out nocopy clob,
      p_src in            xmltype)
   is
      l_src clob := p_src.getclobval;
   begin
      append(p_dst, l_src);
   end;      

   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            clob)
   is
      l_dst clob := p_dst.getclobval;
   begin
      append(l_dst, p_src);
      p_dst := xmltype(l_dst);
   end;      
      
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            varchar2)
   is
      l_dst clob := p_dst.getclobval;
   begin
      append(l_dst, p_src);
      p_dst := xmltype(l_dst);
   end;
      
   procedure append(
      p_dst in out nocopy xmltype,
      p_src in            xmltype)
   is
      l_dst clob := p_dst.getclobval;
   begin
      append(l_dst, p_src);
      p_dst := xmltype(l_dst);
   end;

   --------------------------   
   -- XML Utility routines --
   --------------------------
   function get_xml_node(
      p_xml  in xmltype,
      p_path in varchar)
   return xmltype
   is
   begin
      return case p_xml is null or p_path is null
                when true  then null
                when false then p_xml.extract(p_path)
             end;
   end get_xml_node;
      
   function get_xml_text(
      p_xml  in xmltype,
      p_path in varchar)
   return varchar2
   is
      l_xml xmltype;
      l_text varchar2(32767);
   begin
      l_xml := get_xml_node(p_xml, p_path);
      if l_xml is null then
         return null;
      else
         l_text := l_xml.getstringval;
         if instr(p_path, '/@') = 0 then         
            l_xml := l_xml.extract('/node()/text()');
         end if;  
      end if;
      if l_xml is null then
         return null;
      else         
         l_text := regexp_replace(regexp_replace(l_xml.getstringval, '^\s+'), '\s+$');
         return l_text;  
      end if;
   end;
      
   function get_xml_number(
      p_xml  in xmltype,
      p_path in varchar)
   return number
   is
   begin
      return to_number(get_xml_text(p_xml, p_path));
   end;

               
/*
BEGIN
 -- anything put here will be executed on every mod_plsql call
  NULL;
*/

END cwms_util;
/

SHOW errors;
