CREATE OR REPLACE PACKAGE BODY cwms_ts AS

 --******************************************************************************/   
   FUNCTION get_Time_On_After_Interval (
     p_unsnapped_datetime     IN   DATE,
	  p_ts_offset              IN   NUMBER,
	  p_ts_interval            IN   NUMBER
   )
      RETURN DATE
   IS
    l_datetime      DATE;
	 l_datetime_orig DATE := p_unsnapped_datetime;
   BEGIN   
   
     DBMS_APPLICATION_INFO.set_module ('create_ts',
                                       'Function get_Time_On_After_Interval');
	 
	 if p_ts_interval <= 60 then
	   l_datetime := trunc(p_unsnapped_datetime, 'HH24');
	 elsif p_ts_interval <= 1440 then
	   l_datetime := trunc(p_unsnapped_datetime);
	 end if;  
	 
	 l_datetime := l_datetime + ((trunc((l_datetime_orig - l_datetime) * 1440 / p_ts_interval) * p_ts_interval) + p_ts_offset) / 1440;

	 if l_datetime < p_unsnapped_datetime then
	   l_datetime := l_datetime + (p_ts_interval / 1440);
     end if;
	 
	 RETURN l_datetime;								   
									   
     DBMS_APPLICATION_INFO.set_module (NULL, NULL);

   END get_Time_On_After_Interval;

   
   FUNCTION get_Time_On_Before_Interval (
     p_unsnapped_datetime     IN   DATE,
	  p_ts_offset              IN   NUMBER,
	  p_ts_interval            IN   NUMBER
   )
      RETURN DATE
   IS
     l_datetime      DATE;
	 l_datetime_orig DATE := p_unsnapped_datetime;
   BEGIN   
   
     DBMS_APPLICATION_INFO.set_module ('create_ts',
                                       'Function get_Time_On_Before_Interval');
	 
 
	 
	 RETURN p_unsnapped_datetime;								   
									   
     DBMS_APPLICATION_INFO.set_module (NULL, NULL);

   END get_Time_On_Before_Interval;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (
      p_office_id         IN   VARCHAR2,
      p_timeseries_desc   IN   VARCHAR2,
      p_utc_offset        IN   NUMBER DEFAULT NULL
   )
	IS
	   l_ts_code number;
	BEGIN
   create_ts_code (l_ts_code,
                   p_timeseries_desc,
                   p_utc_offset,
                   p_office_id
                  );
	END create_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS -
--
	PROCEDURE create_ts (
	   p_timeseries_desc     IN   VARCHAR2,
	   p_utc_offset          IN   NUMBER DEFAULT NULL,
	   p_interval_forward    IN   NUMBER DEFAULT NULL,
	   p_interval_backward   IN   NUMBER DEFAULT NULL,
	   p_versioned           IN   VARCHAR2 DEFAULT 'F',
	   p_active_flag         IN   VARCHAR2 DEFAULT 'T',
	   p_office_id           IN   VARCHAR2 DEFAULT NULL
	)
	IS
	   l_ts_code   NUMBER;
	BEGIN
	   create_ts_code (l_ts_code,
	                   p_timeseries_desc,
	                   p_utc_offset,
	                   p_interval_forward,
	                   p_interval_backward,
	                   p_versioned,
	                   p_active_flag,
	                   p_office_id
	                  );
	END create_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS_CODE - v2.0 -
--
   PROCEDURE create_ts_code (
      p_ts_code             OUT      NUMBER,
      p_timeseries_desc     IN       VARCHAR2,
      p_utc_offset          IN       NUMBER DEFAULT NULL,
      p_interval_forward    IN       NUMBER DEFAULT NULL,
      p_interval_backward   IN       NUMBER DEFAULT NULL,
      p_versioned           IN       VARCHAR2 DEFAULT 'F',
      p_active_flag         IN       VARCHAR2 DEFAULT 'T',
      p_office_id           IN       VARCHAR2 DEFAULT NULL
   )
IS
   l_office_id             VARCHAR2 (16);
   l_base_location_id      VARCHAR2 (50);
   l_base_location_code    NUMBER;
   l_sub_location_id       VARCHAR2 (50);
   l_base_parameter_id     VARCHAR2 (50);
   l_base_parameter_code   NUMBER;
   l_sub_parameter_id      VARCHAR2 (50);
   l_parameter_code        NUMBER;
   l_parameter_type_id     VARCHAR2 (50);
   l_parameter_type_code   NUMBER;
   l_interval              NUMBER;
   l_interval_id           VARCHAR2 (50);
   l_interval_code         NUMBER;
   l_duration_id           VARCHAR2 (50);
   l_duration_code         NUMBER;
   l_version               VARCHAR2 (50);
   l_office_code           NUMBER;
   l_db_office_code        NUMBER;
   l_location_code         NUMBER;
   l_ts_code_nv            NUMBER;
   l_ret                   NUMBER;
   l_hashcode              NUMBER;
   l_str_error             VARCHAR2 (256);
   l_utc_offset            NUMBER;
   l_all_office_code       NUMBER;
   l_active_flag           VARCHAR2 (1)   := 'T';
BEGIN
   IF p_office_id IS NULL
   THEN
      l_office_id := cwms_util.user_office_id;
   ELSE
      l_office_id := UPPER (p_office_id);
   END IF;

   DBMS_APPLICATION_INFO.set_module ('create_ts_code',
                                     'parse timeseries_desc using regexp'
                                    );

   --parse values from timeseries_desc using regular expressions
   SELECT cwms_util.return_base_id (REGEXP_SUBSTR (p_timeseries_desc,
                                                   '[^.]+',
                                                   1,
                                                   1
                                                  )
                                   ) base_location_id,
          cwms_util.return_sub_id (REGEXP_SUBSTR (p_timeseries_desc,
                                                  '[^.]+',
                                                  1,
                                                  1
                                                 )
                                  ) sub_location_id,
          cwms_util.return_base_id (REGEXP_SUBSTR (p_timeseries_desc,
                                                   '[^.]+',
                                                   1,
                                                   2
                                                  )
                                   ) base_parameter_id,
          cwms_util.return_sub_id (REGEXP_SUBSTR (p_timeseries_desc,
                                                  '[^.]+',
                                                  1,
                                                  2
                                                 )
                                  ) sub_parameter_id,
          REGEXP_SUBSTR (p_timeseries_desc, '[^.]+', 1, 3) parameter_type_id,
          REGEXP_SUBSTR (p_timeseries_desc, '[^.]+', 1, 4) interval_id,
          REGEXP_SUBSTR (p_timeseries_desc, '[^.]+', 1, 5) duration_id,
          REGEXP_SUBSTR (p_timeseries_desc, '[^.]+', 1, 6) VERSION
     INTO l_base_location_id,
          l_sub_location_id,
          l_base_parameter_id,
          l_sub_parameter_id,
          l_parameter_type_id,
          l_interval_id,
          l_duration_id,
          l_version
     FROM DUAL;

   --office codes must exist, if not fail and return error  (prebuilt table, dynamic office addition not allowed)
   DBMS_APPLICATION_INFO.set_action ('check for office_code');

   BEGIN
      SELECT office_code
        INTO l_office_code
        FROM cwms_office o
       WHERE o.office_id = l_office_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', l_office_id);
   END;

   -- check for valid cwms_code based on id passed in, if not there then create, if create error then fail and return
   DBMS_APPLICATION_INFO.set_action
                                   ('check for cwms_code, create if necessary');

   --generate hash and lock table for that hash value to serialize ts_create as timeseries_desc is not pkeyed.
   SELECT ORA_HASH (UPPER (l_office_id) || UPPER (p_timeseries_desc),
                    1073741823
                   )
     INTO l_hashcode
     FROM DUAL;

   l_ret :=
      DBMS_LOCK.request (ID                     => l_hashcode,
                         TIMEOUT                => 0,
                         lockmode               => 5,
                         release_on_commit      => TRUE
                        );

   IF l_ret > 0
   THEN
      DBMS_LOCK.sleep (2);
   ELSE
      -- BEGIN
      DBMS_APPLICATION_INFO.set_action
                              ('check for location_code, create if necessary');
         -- check for valid base_location_code based on id passed in, if not there then create, -
      -- if create error then fail and return -
      cwms_loc.create_location_raw (l_base_location_code,
                                    l_location_code,
                                    l_base_location_id,
                                    l_sub_location_id,
                                    l_office_code
                                   );

      IF l_location_code IS NULL
      THEN
         raise_application_error (-20203,
                                  'Unable to generate location_code',
                                  TRUE
                                 );
      END IF;

      -- determine rest of lookup codes based on passed in values, use scalar subquery to minimize context switches, return error if lookups not found
      DBMS_APPLICATION_INFO.set_action ('check code lookups, scalar subquery');

      SELECT (SELECT base_parameter_code
                FROM cwms_base_parameter p
               WHERE UPPER (p.base_parameter_id) = UPPER (l_base_parameter_id))
                                                                            p,
             (SELECT duration_code
                FROM cwms_duration d
               WHERE UPPER (d.duration_id) = UPPER (l_duration_id)) d,
             (SELECT parameter_type_code
                FROM cwms_parameter_type p
               WHERE UPPER (p.parameter_type_id) = UPPER (l_parameter_type_id))
                                                                           pt,
             (SELECT interval_code
                FROM cwms_interval i
               WHERE UPPER (i.interval_id) = UPPER (l_interval_id)) i,
             (SELECT INTERVAL
                FROM cwms_interval ii
               WHERE UPPER (ii.interval_id) = UPPER (l_interval_id)) ii
        INTO l_base_parameter_code,
             l_duration_code,
             l_parameter_type_code,
             l_interval_code,
             l_interval
        FROM DUAL;

      IF    l_base_parameter_code IS NULL
         OR l_duration_code IS NULL
         OR l_parameter_type_code IS NULL
         OR l_interval_code IS NULL
      THEN
         l_str_error :=
              'ERROR: Invalid Time Series Description: ' || p_timeseries_desc;

         IF l_base_parameter_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_base_parameter_id
               || ' is not a valid base parameter';
         END IF;

         IF l_duration_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_duration_id
               || ' is not a valid duration';
         END IF;

         IF l_interval_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_interval_id
               || ' is not a valid interval';
         END IF;

         raise_application_error (-20205, l_str_error, TRUE);
      END IF;

      SELECT office_code
        INTO l_all_office_code
        FROM cwms_office
       WHERE office_id = 'ALL';

      BEGIN
         SELECT parameter_code
           INTO l_parameter_code
           FROM at_parameter ap
          WHERE base_parameter_code = l_base_parameter_code
            AND db_office_code IN (l_office_code, l_all_office_code)
            AND UPPER (sub_parameter_id) = UPPER (l_sub_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN                                   -- Insert new sub_parameter...
            INSERT INTO at_parameter
                        (parameter_code, db_office_code,
                         base_parameter_code, sub_parameter_id
                        )
                 VALUES (cwms_seq.NEXTVAL, l_office_code,
                         l_base_parameter_code, l_sub_parameter_id
                        )
              RETURNING parameter_code
                   INTO l_parameter_code;
      END;

      --after all lookups, check for existing ts_code, insert it if not found, and verify that it was inserted with the returning, error if no valid ts_code is returned
      DBMS_APPLICATION_INFO.set_action
                                     ('check for ts_code, create if necessary');

      BEGIN
         SELECT ts_code
           INTO p_ts_code
           FROM at_cwms_ts_spec acts
          WHERE office_code = l_office_code
            AND acts.location_code = l_location_code
            AND acts.parameter_code = l_parameter_code
            AND acts.parameter_type_code = l_parameter_type_code
            AND acts.interval_code = l_interval_code
            AND acts.duration_code = l_duration_code
            AND UPPER (NVL (acts.VERSION, 1)) = UPPER (NVL (l_version, 1))
            AND acts.delete_date IS NULL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_interval_id = '0'
            THEN
               l_utc_offset := cwms_util.utc_offset_irregular;
            ELSE
               l_utc_offset := cwms_util.utc_offset_undefined;

               IF p_utc_offset IS NOT NULL
               THEN
                  IF p_utc_offset < l_interval
                  THEN
                     l_utc_offset := p_utc_offset;
                  END IF;
               END IF;
            END IF;

            INSERT INTO at_cwms_ts_spec t
                        (ts_code, office_code, location_code,
                         parameter_code, parameter_type_code,
                         interval_code, duration_code, VERSION,
                         ts_ni_hash,
                         interval_utc_offset, active_flag
                        )
                 VALUES (cwms_seq.NEXTVAL, l_office_code, l_location_code,
                         l_parameter_code, l_parameter_type_code,
                         l_interval_code, l_duration_code, l_version,
                            l_parameter_code
                         || '-'
                         || l_parameter_type_code
                         || '-'
                         || l_duration_code,
                         l_utc_offset, l_active_flag
                        )
              RETURNING ts_code
                   INTO p_ts_code;

            COMMIT;
      END;
   END IF;

   IF p_ts_code IS NULL
   THEN
      raise_application_error (-20204,
                               'Unable to generate timeseries_code',
                               TRUE
                              );
   END IF;

   DBMS_APPLICATION_INFO.set_module (NULL, NULL);
END create_ts_code;

--

--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS_JAVA -
--   
	PROCEDURE retrieve_ts_java (
	   p_transaction_time   OUT      DATE,
	   p_at_tsv_rc          OUT      sys_refcursor,
	   p_units              IN       VARCHAR2,
	   p_timeseries_desc    IN       VARCHAR2,
	   p_start_time         IN       DATE,
	   p_end_time           IN       DATE,
	   p_time_zone          IN       VARCHAR2 DEFAULT 'UTC',
	   p_trim               IN       VARCHAR2 DEFAULT 'F',
	   p_inclusive          IN       NUMBER DEFAULT NULL,
	   p_version_date       IN       DATE DEFAULT NULL,
	   p_max_version        IN       VARCHAR2 DEFAULT 'T',
	   p_office_id          IN       VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
	   p_transaction_time := CAST ((SYSTIMESTAMP AT TIME ZONE 'GMT') AS DATE);
	   retrieve_ts (p_at_tsv_rc,
	                p_units,
	                p_timeseries_desc,
	                p_start_time,
	                p_end_time,
	                p_time_zone,
	                p_trim,
	                p_inclusive,
	                p_version_date,
	                p_max_version,
	                p_office_id
	               );
	END retrieve_ts_java;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
	PROCEDURE retrieve_ts (
	   p_at_tsv_rc         IN OUT   sys_refcursor,
	   p_units             IN       VARCHAR2,
	   p_officeid          IN       VARCHAR2,
	   p_timeseries_desc   IN       VARCHAR2,
	   p_start_time        IN       DATE,
	   p_end_time          IN       DATE,
	   p_timezone      	  IN       VARCHAR2 DEFAULT 'GMT',
	   p_trim              IN       NUMBER DEFAULT cwms_util.false_num,
	   p_inclusive         IN       NUMBER DEFAULT NULL,
	   p_versiondate       IN       DATE DEFAULT NULL,
	   p_max_version       IN       NUMBER DEFAULT cwms_util.true_num
	)
	IS
	   l_trim        VARCHAR2(1);
		l_max_version VARCHAR2(1);
	BEGIN
	   --
	   IF p_trim IS NULL OR p_trim = cwms_util.false_num
	   THEN
	      l_trim := 'F';
	   ELSIF p_trim = cwms_util.true_num
	   THEN
	      l_trim := 'T';
	   ELSE
	      cwms_err.RAISE ('INVALID_T_F_FLAG_OLD', p_trim);
	   END IF;
	
	   --
	   IF p_max_version IS NULL OR p_max_version = cwms_util.true_num
	   THEN
	      l_max_version := 'T';
	   ELSIF p_max_version = cwms_util.false_num
	   THEN
	      l_max_version := 'F';
	   ELSE
	      cwms_err.RAISE ('INVALID_T_F_FLAG_OLD', p_max_version);
	   END IF;
	   --
	   retrieve_ts (p_at_tsv_rc,
	                p_units,
	                p_timeseries_desc,
	                p_start_time,
	                p_end_time,
	                p_timezone,
	                l_trim,
	                p_inclusive,
	                p_versiondate,
	                l_max_version,
	                p_officeid
	               );
	END retrieve_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS - v2.0 -
--
   PROCEDURE retrieve_ts (
      p_at_tsv_rc         IN OUT   sys_refcursor,
      p_units             IN       VARCHAR2,
      p_timeseries_desc   IN       VARCHAR2,
      p_start_time        IN       DATE,
      p_end_time          IN       DATE,
      p_time_zone         IN       VARCHAR2 DEFAULT 'UTC',
      p_trim              IN       VARCHAR2 DEFAULT 'F',
      p_inclusive         IN       NUMBER DEFAULT NULL,
      p_version_date      IN       DATE DEFAULT NULL,
      p_max_version       IN       VARCHAR2 DEFAULT 'T',
      p_office_id         IN       VARCHAR2 DEFAULT NULL
		)
   IS
	
		l_whichRetrieve varchar2(10);
		l_numVals       integer;
		l_errNum        integer;
		l_ts_interval   number;
		l_ts_offset     number;
		l_versioned     number;
		l_ts_code       number;
		l_version_date  DATE;
		l_max_version   BOOLEAN;
		l_trim          BOOLEAN;
		l_start_time    DATE   := cwms_util.date_from_tz_to_utc(p_start_time, p_time_zone);
		l_end_time      DATE   := cwms_util.date_from_tz_to_utc(p_end_time,   p_time_zone);
		l_end_time_init DATE   := l_end_time;
		
		l_office_id     varchar2(16);
	
	BEGIN
		--
		dbms_application_info.set_module ( 'Cwms_ts_retrieve','Check Interval');
		--
	    -- set default values, don't be fooled by NULL as an actual argument 
		if p_office_id is null 
		then
		  l_office_id := cwms_util.user_office_id;
		else                           
		  l_office_id := p_office_id;
		end if;
	
		if p_trim is null
		then
		  l_trim := FALSE;
		else
		  l_trim := cwms_util.return_true_or_false(p_trim);
		end if;
	
		if NVL(p_max_version,  cwms_util.true_num) = cwms_util.false_num then
		  l_max_version := FALSE;
		else
		  l_max_version := TRUE;
		end if;
	
	    l_version_date := nvl(p_version_date, cwms_util.non_versioned);
	
	  	--Get Time series parameters for retrieval load into record structure
	
	
		SELECT interval,
		       CASE interval_utc_offset
		          WHEN cwms_util.utc_offset_undefined
		             THEN NULL
		          WHEN cwms_util.utc_offset_irregular
		             THEN NULL
		          ELSE (interval_utc_offset / 60)
		       END,
		       version_flag, ts_code
		  INTO l_ts_interval,
		       l_ts_offset,
		       l_versioned, l_ts_code
		  FROM mv_cwms_ts_id
		 WHERE office_id = UPPER (l_office_id)
		   AND UPPER (cwms_ts_id) = UPPER (p_timeseries_desc);
	
		IF l_ts_interval=0 
		THEN
	      IF p_inclusive IS NOT NULL
			THEN         
	         IF l_versioned IS NULL
				THEN -- l_versioned IS NULL -   
					-- 
					-- nonl_versioned, irregular, inclusive retrieval
					-- 
					dbms_output.put_line('RETRIEVE_TS #1');
					--         
					open p_at_tsv_rc for 
					SELECT   date_time, VALUE, quality_code
					    FROM (SELECT date_time, VALUE, quality_code,
					                 LAG (date_time, 1, l_start_time) OVER (ORDER BY date_time)
					                                                                      lagdate,
					                 LEAD (date_time, 1, l_end_time) OVER (ORDER BY date_time)
					                                                                     leaddate
					            FROM av_tsv_dqu v
					           WHERE v.ts_code = l_ts_code
					             AND v.unit_id = p_units
					             AND v.start_date <= l_end_time
					             AND v.end_date > l_start_time)
					   WHERE leaddate >= l_start_time AND lagdate <= l_end_time
					ORDER BY date_time ASC;
	
				ELSE  -- l_versioned IS NOT NULL - 
				   --
					-- l_versioned, irregular, inclusive retrieval - 
					
					IF p_version_date IS NULL
					THEN -- p_version_date IS NULL -
					
						IF l_max_version 
						THEN -- l_max_version is TRUE -
						
							--latest version_date query -
							-- 
							dbms_output.put_line('RETRIEVE_TS #2');
							--         
	
							open p_at_tsv_rc for
							SELECT   date_time, VALUE, quality_code
							    FROM (SELECT date_time,
							                 MAX (VALUE)KEEP (DENSE_RANK LAST ORDER BY version_date)
							                                                                        VALUE,
							                 MAX (quality_code)KEEP (DENSE_RANK LAST ORDER BY version_date)
							                                                                 quality_code
							            FROM (SELECT date_time, VALUE, quality_code, version_date,
							                         LAG (date_time, 1, l_start_time) OVER (ORDER BY date_time)
							                                                                      lagdate,
							                         LEAD (date_time, 1, l_end_time) OVER (ORDER BY date_time)
							                                                                     leaddate
							                    FROM av_tsv_dqu v
							                   WHERE v.ts_code = l_ts_code
							                     AND v.unit_id = p_units
							                     AND v.start_date <= l_end_time
							                     AND v.end_date > l_start_time)
							           WHERE leaddate >= l_start_time AND lagdate <= l_end_time)
							ORDER BY date_time ASC;
	
						ELSE --l_max_version is FALSE -
						
						   -- first version_date query -
							-- 
							dbms_output.put_line('RETRIEVE_TS #3');
							--         
							open p_at_tsv_rc for
							SELECT   date_time, VALUE, quality_code
							    FROM (SELECT date_time,
							                 MAX (VALUE)KEEP (DENSE_RANK FIRST ORDER BY version_date)
							                                                                        VALUE,
							                 MAX (quality_code)KEEP (DENSE_RANK FIRST ORDER BY version_date)
							                                                                 quality_code
							            FROM (SELECT date_time, VALUE, quality_code, version_date,
							                         LAG (date_time, 1, l_start_time) OVER (ORDER BY date_time)
							                                                                      lagdate,
							                         LEAD (date_time, 1, l_end_time) OVER (ORDER BY date_time)
							                                                                     leaddate
							                    FROM av_tsv_dqu v
							                   WHERE v.ts_code = l_ts_code
							                     AND v.unit_id = p_units
							                     AND v.start_date <= l_end_time
							                     AND v.end_date > l_start_time)
							           WHERE leaddate >= l_start_time AND lagdate <= l_end_time)
							ORDER BY date_time ASC;
							
						END IF;  --l_max_version -
						
					ELSE --p_version_date IS NOT NULL - 
					   --
						--selected version_date query -
						-- 
						dbms_output.put_line('RETRIEVE_TS #4');
						--         
						open p_at_tsv_rc for 
						SELECT   date_time, VALUE, quality_code
						    FROM (SELECT date_time, VALUE, quality_code,
						                 LAG (date_time, 1, l_start_time) OVER (ORDER BY date_time)
						                                                                      lagdate,
						                 LEAD (date_time, 1, l_end_time) OVER (ORDER BY date_time)
						                                                                     leaddate
						            FROM av_tsv_dqu v
						           WHERE v.ts_code = l_ts_code
						             AND v.unit_id = p_units
						             AND v.version_date = p_version_date
						             AND v.start_date <= l_end_time
						             AND v.end_date > l_start_time)
						   WHERE leaddate >= l_start_time AND lagdate <= l_end_time
						ORDER BY date_time ASC;
	         
					END IF;  --p_version_date -
	
				END IF;  -- l_versioned -
	
			ELSE -- p_inclusive IS NULL -
			
				dbms_application_info.set_action (   'return  irregular  ts '
				                                  || l_ts_code
															 || ' from '
															 || to_char(l_start_time,'mm/dd/yyyy hh24:mi')
															 || ' to '
															 || to_char(l_end_time,'mm/dd/yyyy hh24:mi')
															 || ' in units '
															 || p_units);     
				IF l_versioned IS NULL
				THEN    
					-- nonl_versioned, irregular, noninclusive retrieval -
					--
					dbms_output.put_line('RETRIEVE_TS #5');
					--                         
					open p_at_tsv_rc for
					SELECT   FROM_TZ (CAST (date_time AS TIMESTAMP), 'GMT') AT TIME ZONE (p_time_zone),
					         value, quality_code
					    FROM av_tsv_dqu v
					   WHERE v.ts_code = l_ts_code
					     AND v.date_time BETWEEN l_start_time AND l_end_time
					     AND v.unit_id = p_units
					     AND v.start_date <= l_end_time
					     AND v.end_date > l_start_time
					ORDER BY date_time ASC;
	
				ELSE  -- l_versioned IS NOT NULL -
	   		   --
					-- l_versioned, irregular, noninclusive retrieval -
					--
					IF p_version_date IS NULL
					THEN
	            
			         IF l_max_version
						THEN    
	
							--latest version_date query          
							--
							dbms_output.put_line('RETRIEVE_TS #6');
							--         
							open p_at_tsv_rc for
							SELECT   date_time, VALUE, quality_code
							    FROM (SELECT   date_time,
							                   MAX (VALUE)KEEP (DENSE_RANK LAST ORDER BY version_date)
							                                                                        VALUE,
							                   MAX (quality_code)KEEP (DENSE_RANK LAST ORDER BY version_date)
							                                                                 quality_code
							              FROM (SELECT date_time, VALUE, quality_code, version_date
							                      FROM av_tsv_dqu v
							                     WHERE v.ts_code = l_ts_code
							                       AND v.date_time BETWEEN l_start_time AND l_end_time
							                       AND v.unit_id = p_units
							                       AND v.start_date <= l_end_time
							                       AND v.end_date > l_start_time)
							          GROUP BY date_time)
							ORDER BY date_time ASC;
	
						ELSE  -- p_version_date IS NOT NULL -
							-- 
							dbms_output.put_line('RETRIEVE_TS #7');
							--         
							open p_at_tsv_rc for
							SELECT   date_time, VALUE, quality_code
							    FROM (SELECT   date_time,
							                   MAX (VALUE)KEEP (DENSE_RANK FIRST ORDER BY version_date)
							                                                                        VALUE,
							                   MAX (quality_code)KEEP (DENSE_RANK FIRST ORDER BY version_date)
							                                                                 quality_code
							              FROM (SELECT date_time, VALUE, quality_code, version_date
							                      FROM av_tsv_dqu v
							                     WHERE v.ts_code = l_ts_code
							                       AND v.date_time BETWEEN l_start_time AND l_end_time
							                       AND v.unit_id = p_units
							                       AND v.start_date <= l_end_time
							                       AND v.end_date > l_start_time)
							          GROUP BY date_time)
							ORDER BY date_time ASC;
	
						END IF; -- p_version_date IS NOT NULL -
	
					ELSE -- l_max_version is FALSE -
						-- 
						dbms_output.put_line('RETRIEVE_TS #8');
						--         
						open p_at_tsv_rc for
						/* Formatted on 2006/10/25 12:54 (Formatter Plus v4.8.7) */
						SELECT   date_time, VALUE, quality_code
						    FROM av_tsv_dqu v
						   WHERE v.ts_code = l_ts_code
						     AND v.date_time BETWEEN l_start_time AND l_end_time
						     AND v.unit_id = p_units
						     AND v.version_date = version_date
						     AND v.start_date <= l_end_time
						     AND v.end_date > l_start_time
						ORDER BY date_time ASC;
	
					END IF;  -- l_max_version -
	  
				END IF;  -- l_versioned -
	
			END IF;  -- p_inclusive -
	
		ELSE  -- l_ts_interval <> 0 -
	
			dbms_application_info.set_action (   'return  regular  ts '
														 || l_ts_code
														 || ' from '
														 || to_char(l_start_time,'mm/dd/yyyy hh24:mi')
														 || ' to '
														 || to_char(l_end_time,'mm/dd/yyyy hh24:mi')
														 || ' in units '
														 || p_units);
	
	     
			-- Make sure start_time and end_time fall on a valid date/time for the regular -
			--    time series given the interval and offset. -
				
		   l_start_time   := get_time_on_after_interval(l_start_time, l_ts_offset, l_ts_interval);
	      l_end_time     := get_time_on_after_interval(l_end_time, l_ts_offset, l_ts_interval);
			 
			IF l_end_time > l_end_time_init
			THEN
			   l_end_time := l_end_time - (l_ts_interval / 1440);
			END IF;
	
			IF l_versioned IS NULL 
			THEN 
				--
				-- nonl_versioned, regular ts query
	 		   -- 
			   dbms_output.put_line('RETRIEVE_TS #9 - nonl_versioned, regular ts query');
			   --         
	  		   l_start_time   := get_time_on_after_interval(l_start_time, l_ts_offset, l_ts_interval);
	         l_end_time     := get_time_on_after_interval(l_end_time, l_ts_offset, l_ts_interval);
			 
			 	IF l_end_time > l_end_time_init 
				THEN
			   	l_end_time := l_end_time - (l_ts_interval / 1440);
			 	END IF;
			 
			 	open p_at_tsv_rc for
				select FROM_TZ (CAST (jdate_time AS TIMESTAMP), 'GMT') AT TIME ZONE (p_time_zone)
						 																 	 			  	 "DATETIME", 
		             value, 
			          nvl(quality_code,0) quality_code
	           from (select * 
		                from (select * 
	                           from av_tsv_dqu v 
	                          where  v.ts_code = l_ts_code 
						             and v.date_time between l_start_time and l_end_time 
	                            and v.unit_id = p_units
	                            and v.start_date <= l_end_time 
						             and v.end_date > l_start_time 
						          ) v
	        right outer join (select l_start_time +((level-1)/(1440/l_ts_interval )) jdate_time 
	                            from  dual 
								 connect by 1=1 
								        and level<=(round((l_end_time - l_start_time )*1440)/l_ts_interval )+1
									  ) t 
					          on t.jdate_time = v.date_time 
			          ) 
		    order by jdate_time;
	
			ELSE --  l_versioned IS NOT NULL -
	
	    		IF p_version_date IS NULL
				THEN
	
					IF l_max_version
					THEN
						-- 
						dbms_output.put_line('RETRIEVE_TS #10');
						--         
						open p_at_tsv_rc for
						/* Formatted on 2006/10/25 13:12 (Formatter Plus v4.8.7) */
						SELECT   date_time, VALUE, quality_code
						    FROM (SELECT   jdate_time date_time,
						                   MAX (VALUE)KEEP (DENSE_RANK LAST ORDER BY version_date)
						                                                                        VALUE,
						                   MAX (quality_code)KEEP (DENSE_RANK LAST ORDER BY version_date)
						                                                                 quality_code
						              FROM (SELECT *
						                      FROM (SELECT *
						                              FROM av_tsv_dqu v
						                             WHERE v.ts_code = l_ts_code
						                               AND v.date_time BETWEEN l_start_time AND l_end_time
						                               AND v.unit_id = p_units
						                               AND v.start_date <= l_end_time
						                               AND v.end_date > l_start_time) v
						                           RIGHT OUTER JOIN
						                           (SELECT       l_start_time
						                                       + (  (LEVEL - 1)
						                                          / (1440 / l_ts_interval)
						                                         ) jdate_time
						                                  FROM DUAL
						                            CONNECT BY 1 = 1
						                                   AND LEVEL <=
						                                            (  ROUND (  (  l_end_time
						                                                         - l_start_time
						                                                        )
						                                                      * 1440
						                                                     )
						                                             / l_ts_interval
						                                            )
						                                          + 1) t ON t.jdate_time = v.date_time
						                           )
						          ORDER BY jdate_time)
						GROUP BY date_time;
	
					ELSE  -- l_max_version is FALSE -
						-- 
						dbms_output.put_line('RETRIEVE_TS #11');
						--         
						open p_at_tsv_rc for
						/* Formatted on 2006/10/25 13:14 (Formatter Plus v4.8.7) */
						SELECT   date_time, VALUE, quality_code
						    FROM (SELECT   jdate_time date_time,
						                   MAX (VALUE)KEEP (DENSE_RANK FIRST ORDER BY version_date)
						                                                                        VALUE,
						                   MAX (quality_code)KEEP (DENSE_RANK FIRST ORDER BY version_date)
						                                                                 quality_code
						              FROM (SELECT *
						                      FROM (SELECT *
						                              FROM av_tsv_dqu v
						                             WHERE v.ts_code = l_ts_code
						                               AND v.date_time BETWEEN l_start_time AND l_end_time
						                               AND v.unit_id = p_units
						                               AND v.start_date <= l_end_time
						                               AND v.end_date > l_start_time) v
						                           RIGHT OUTER JOIN
						                           (SELECT       l_start_time
						                                       + (  (LEVEL - 1)
						                                          / (1440 / l_ts_interval)
						                                         ) jdate_time
						                                  FROM DUAL
						                            CONNECT BY 1 = 1
						                                   AND LEVEL <=
						                                            (  ROUND (  (  l_end_time
						                                                         - l_start_time
						                                                        )
						                                                      * 1440
						                                                     )
						                                             / l_ts_interval
						                                            )
						                                          + 1) t ON t.jdate_time = v.date_time
						                           )
						          ORDER BY jdate_time)
						GROUP BY date_time;
	
					END IF;  -- l_max_version -
	
				ELSE  -- p_version_date IS NOT NULL -
					-- 
					dbms_output.put_line('RETRIEVE_TS #12');
					--         
					open p_at_tsv_rc for
					/* Formatted on 2006/10/25 13:32 (Formatter Plus v4.8.7) */
					SELECT   jdate_time date_time, VALUE, NVL (quality_code, 0) quality_code
					    FROM (SELECT *
					            FROM (SELECT *
					                    FROM av_tsv_dqu v
					                   WHERE v.ts_code = l_ts_code
					                     AND v.date_time BETWEEN l_start_time AND l_end_time
					                     AND v.unit_id = p_units
					                     AND v.version_date = p_version_date
					                     AND v.start_date <= l_end_time
					                     AND v.end_date > l_start_time) v
					                 RIGHT OUTER JOIN
					                 (SELECT       l_start_time
					                             + ((LEVEL - 1) / (1440 / l_ts_interval))
					                                                                   jdate_time
					                        FROM DUAL
					                  CONNECT BY 1 = 1
					                         AND LEVEL <=
					                                  (  ROUND ((l_end_time - l_start_time) * 1440)
					                                   / l_ts_interval
					                                  )
					                                + 1) t ON t.jdate_time = v.date_time
					                 )
					ORDER BY jdate_time;
	
				END IF;
	  
	  		END IF;
	 
	 	END IF;
	 
	 	dbms_application_info.set_module(null,null);
		
	END retrieve_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
	PROCEDURE store_ts (
	   p_office_id         IN   VARCHAR2,
	   p_timeseries_desc   IN   VARCHAR2,
	   p_units             IN   VARCHAR2,
	   p_timeseries_data   IN   tsv_array,
	   p_store_rule        IN   VARCHAR2 DEFAULT NULL,
	   p_override_prot     IN   NUMBER DEFAULT cwms_util.false_num,
	   p_versiondate       IN   DATE DEFAULT cwms_util.non_versioned
	)
	--^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
	IS
	   l_override_prot VARCHAR2(1);
	BEGIN
	   IF p_override_prot IS NULL OR p_override_prot = cwms_util.false_num
		THEN
			l_override_prot := 'F';
		ELSIF p_override_prot = cwms_util.true_num
		THEN
			l_override_prot := 'T';
		ELSE
		   cwms_err.raise('INVALID_T_F_FLAG_OLD', p_override_prot);
		END IF;
		
	   store_ts (p_timeseries_desc,
	             p_units,
	             p_timeseries_data,
	             p_store_rule,
	             l_override_prot,
	             p_versiondate,
					 p_office_id
	            );
	END store_ts; -- v1.4 --
--	
--
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS -
--	
	PROCEDURE store_ts (
	   p_timeseries_desc   IN   VARCHAR2,
	   p_units             IN   VARCHAR2,
	   p_timeseries_data   IN   tsv_array,
	   p_store_rule        IN   VARCHAR2 DEFAULT NULL,
	   p_override_prot     IN   NUMBER DEFAULT cwms_util.false_num,
	   p_version_date      IN   DATE DEFAULT cwms_util.non_versioned,
	   p_office_id         IN   VARCHAR2 DEFAULT NULL
	)
	IS
	   l_office_id           VARCHAR2 (16);
	   t1count               NUMBER;
	   t2count               NUMBER;
	   l_ucount                NUMBER;
	   l_store_date             TIMESTAMP ( 3 )  DEFAULT SYSTIMESTAMP;
	   l_ts_code             NUMBER;
	   l_interval_id         VARCHAR2 (100);
	   l_interval_value      NUMBER;
	   utc_offset            NUMBER;
	   existing_utc_offset   NUMBER;
	   table_cnt             NUMBER;
	   mindate               DATE;
	   maxdate               DATE;
	   l_sql_txt               VARCHAR2 (10000);
	   l_override_prot       BOOLEAN;
	   l_version_date         DATE;
	BEGIN
   	dbms_application_info.set_module('cwms_ts_store.store_ts','get tscode from ts_id');

      -- set default values, don't be fooled by NULL as an actual argument

      if p_office_id is null 
		then
      	l_office_id := cwms_util.user_office_id;
    	else                           
      	l_office_id := p_office_id;
    	end if;

    	l_version_date   := nvl(p_version_date, cwms_util.non_versioned);
	
	   if NVL(p_override_prot, cwms_util.false_num) = cwms_util.false_num 
		then
	   	l_override_prot := FALSE;
		else
	  		l_override_prot := TRUE;
		end if;
	
		dbms_application_info.set_action('Determine utc_offset of incoming data set');
	
    	select regexp_substr(p_timeseries_desc,'[^.]+',1,4) interval_id 
        into l_interval_id 
	     from dual;
	
	begin
      select i.interval 
        into l_interval_value 
	    from cwms_interval i 
       where upper(i.interval_id) = upper(l_interval_id);
	  exception
	  when NO_DATA_FOUND then
	    raise_application_error(-20110, 'ERROR: ' || l_interval_id || ' is not a valid time series interval', true);
    end;	 
    
    if l_interval_value > 0 then 
	  
      dbms_application_info.set_action('Incoming data set has a regular interval, confirm data set matches interval_id');
      
	           BEGIN
            SELECT DISTINCT ROUND (MOD (  (  CAST (date_time AS DATE)
                                           - TRUNC (CAST (date_time AS DATE))
                                          )
                                        * 1440
                                        * 60,
                                        l_interval_value * 60
                                       ),
                                   0
                                  )
                       INTO utc_offset
                       FROM TABLE (p_timeseries_data);   -- where rownum < 20;
         EXCEPTION

	  
-- 	  begin
-- 	  
--         select distinct round(mod((date_time-trunc(date_time))*1440*60,in_interval_value*60),0) 
--           into utc_offset  
--           from table(p_timeseries_data) ; -- where rownum < 20;
-- 	    
--       exception 
	  when too_many_rows then
        raise_application_error(-20110, 'ERROR: Incoming data set is contains irregular data. Unable to store data for '||p_timeseries_desc, true);
      end;
	
	else
	
	  dbms_application_info.set_action('Incoming data set is irregular');
	  
      utc_offset := cwms_util.UTC_OFFSET_IRREGULAR;
	
    end if;	
	
	dbms_application_info.set_action('Find or create a TS_CODE for your TS Desc');
  
    begin -- BEGIN - Find the TS_CODE 
      
      select ts_code, interval_utc_offset 
        into l_ts_code, existing_utc_offset
	    from mv_CWMS_TS_ID m 
       where upper(m.CWMS_TS_ID) = upper(p_timeseries_desc)
	     and m.OFFICE_ID = upper(l_office_id);
		 
      dbms_application_info.set_action('TS_CODE was found - check its utc_offset against the dataset''s and/or set an undefined utc_offset');
	  
	  if existing_utc_offset = cwms_util.UTC_OFFSET_UNDEFINED then
	    -- Existing TS_Code did not have a defined UTC_OFFSET, so set it equal to the offset of this data set.
		
	    update at_cwms_ts_spec acts
		   set acts.INTERVAL_UTC_OFFSET = utc_offset
		 where acts.TS_CODE = l_ts_code;
		 
      elsif existing_utc_offset != utc_offset then
	    -- Existing TS_Code's UTC_OFFSET does not match the offset of the data set - so storage of data set fails.
		
        raise_application_error(-20101, 'Incoming Data Set''s UTC_OFFSET does not match UTC_OFFSET of previously stored data - data set was NOT stored', true);
		
	  end if; 
    
    exception
    when no_data_found then
      /*
	   Exception is thrown when the Time Series Description passed 
	   does not exist in the database for the office_id. If this is
	   the case a new TS_CODE will be created for the Time Series 
	   Descriptor. 
	  */
      
      create_ts_code(p_ts_code=>l_ts_code, 
		               p_office_id=>l_office_id, 
							p_timeseries_desc=>p_timeseries_desc, 
							p_utc_offset=>utc_offset);
 
    end; -- END - Find TS_CODE

    if l_ts_code is null then
      raise_application_error(-20105, 'Unable to create or locate ts_code for '||p_timeseries_desc, true);
    end if;

    dbms_application_info.set_action('check for unit conversion factors');


		SELECT COUNT (*)
		  INTO l_ucount
		  FROM at_cwms_ts_spec s,
		       at_parameter ap,
		       cwms_unit_conversion c,
		       cwms_base_parameter p,
		       cwms_unit u
		 WHERE s.ts_code = l_ts_code
		   AND s.parameter_code = ap.parameter_code
			AND ap.base_parameter_code =p.base_parameter_code
		   AND p.unit_code = c.from_unit_code
		   AND c.to_unit_code = u.unit_code
		   AND u.unit_id = p_units;


		if l_ucount <> 1 
		then
			raise_application_error(-20103, 'Requested unit conversion is not available', true);
		end if;

    dbms_application_info.set_action('check for interval_utc_offset violation if regular ts');

--     if in_interval_value > 0 then
-- 
--       select count(*) 
--         into t1count 
--         from (select distinct round( mod((t.date_time - trunc(t.date_time))*1440,i.interval))  - (ts.INTERVAL_UTC_OFFSET/60) offset_diff
--             from TABLE(cast(p_timeseries_data as tsv_array)) t, at_cwms_ts_spec ts, cwms_interval i
--            where i.interval_code = ts.interval_code
--              and ts.ts_code = tcode
--              and i.interval>0
--              and ts.INTERVAL_UTC_OFFSET>0
--          );
-- 
--       if t1count > 1 then
--         raise_application_error(-20101, 'Date-Time value falls outside defined UTC_INTERVAL_OFFSET in regular time series', true);
--       end if;
-- 
--       dbms_application_info.set_action('check for interval violation if regular ts');
-- 
-- 
--       select count(*) 
--         into t2count 
-- 	    from (select distinct diff_interval 
-- 	            from (select  round(mod(1440*(lead(date_time, 1) over (order by date_time)-date_time), in_interval_value)) diff_interval, lead(date_time, 1) over (order by date_time) leaddate
--                         from TABLE(cast(p_timeseries_data as tsv_array)) 
--                        where in_interval_value>0
-- 		             )
--                where leaddate is not null
--              );
-- 
--       if t2count > 1 then
--         raise_application_error(-20102, 'Invalid interval in regular time series', true);
--       end if;
-- 
--     end if;

    select count(*) 
      into table_cnt
      from at_ts_table_properties;

	-- 
	-- Determine the min and max date in the dataset, convert 
	-- the min & max dates to GMT dates.
	-- The min & max dates are used to determine which 
	-- at_tsv tables need to be accessed during the store.
	--
	  	  
    if table_cnt>1 then 
      select min(CAST((t.date_time AT TIME ZONE 'GMT') AS DATE)), 
	         max(CAST((t.date_time AT TIME ZONE 'GMT') AS DATE))
        into mindate, maxdate 
	    from TABLE(cast(p_timeseries_data as tsv_array)) t;
    end if;

	
	dbms_output.put_line('*****************************'         || CHR(10) ||
	                     'IN STORE_TS'                           || CHR(10) ||
						 'TS Description: ' || p_timeseries_desc || CHR(10) ||
						 '       TS CODE: ' || l_ts_code           || CHR(10) ||
						 '    Store Rule: ' || p_store_rule      || CHR(10) ||
						 '      Override: ' || p_override_prot   || CHR(10) ||
						 '*****************************');

   CASE
   WHEN l_override_prot and upper(p_store_rule) = cwms_util.replace_all 
	THEN
      --
		--**********************************
	   -- CASE 1 - Store Rule: REPLACE ALL 
		--          Override:   TRUE  
	   --**********************************
		--
		dbms_application_info.set_action('merge into table, override, replace_all ');
		dbms_output.put_line('CASE 1: store_all override: TRUE');
		dbms_output.put_line('CASE 1: table_cnt = ' || table_cnt);
	  
      IF table_cnt=1
		THEN
	
			MERGE INTO at_tsv t1
			   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
			                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
			            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
			                 at_cwms_ts_spec s,
								  at_parameter ap,
			                 cwms_unit_conversion c,
			                 cwms_base_parameter p,
			                 cwms_unit u
			           WHERE s.ts_code = l_ts_code
			             AND s.parameter_code = ap.parameter_code
							 AND ap.base_parameter_code = p.base_parameter_code
			             AND p.unit_code = c.from_unit_code
			             AND c.to_unit_code = u.unit_code
			             AND u.unit_id = p_units) t2
			   ON (    t1.ts_code = l_ts_code
			       AND t1.date_time = t2.date_time
			       AND t1.version_date = l_version_date)
			   WHEN MATCHED THEN
			      UPDATE
			         SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
			             t1.quality_code = t2.quality_code
			   WHEN NOT MATCHED THEN
			      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
			              version_date)
			      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
			              l_version_date);

			ELSE
 
         	FOR x IN (select start_date, end_date, table_name 
            	         from at_ts_table_properties 
	  	          		  where start_date<=maxdate 
		                   and end_date>mindate)
        		LOOP

					dbms_output.put_line('CASE 1: multi-table storage: ' || x.table_name);

					l_sql_txt:=
						' merge into '||x.table_name||' t1
            		using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					               (t.value/c.factor) - c.offset value, 
								   t.quality_code 
		                      from TABLE(cast(:p_timeseries_data as tsv_array)) t,
							       at_cwms_ts_spec s, 
									 at_parameter ap,
								    cwms_unit_conversion c, 
								    cwms_base_parameter p, 
								    cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
										 AND ap.base_parameter_code = p.base_parameter_code
                               and p.unit_code      =  c.from_unit_code
                               and c.to_unit_code   =  u.unit_code
                               and u.UNIT_ID        =  :p_units
                               and date_time        >= :start_date 
							   and date_time        <  :end_date 
			               ) t2
                        on (    t1.ts_code      = :l_ts_code 
						    and t1.date_time    = t2.date_time 
							and t1.version_date = :l_version_date )
                      when matched then
		                update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                      when not matched then 
		                insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
						values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';

					dbms_output.put_line('CASE 1: exectuing dynamic merge statement');
		  
		  			execute immediate l_sql_txt using p_timeseries_data, 
		                           l_ts_code, p_units, x.start_date, x.end_date, 
										  	l_ts_code, l_version_date, 
										  	l_store_date, 
										  	l_ts_code, l_store_date, l_version_date;
          
			 		dbms_output.put_line('CASE 1: merge stament completed');
        
		  		END LOOP;
		
				dbms_output.put_line('CASE 1: multi table store completed');
		
			END IF;
 
	 	WHEN NOT l_override_prot and upper(p_store_rule) = cwms_util.replace_all
		THEN
			--
			--*************************************
			-- CASE 2 - Store Rule: REPLACE ALL -
			--         Override:   FALSE -
			--*************************************
			-- 
			dbms_application_info.set_action('CASE 2: merge into  table, no override, replace_all ');
			dbms_output.put_line('CASE 2: store_all override: FALSE');
			dbms_output.put_line('CASE 2: table_cnt = ' || table_cnt);
	  	  
		  	IF table_cnt=1
			THEN
	  
	  			dbms_output.put_line('CASE 2: single table');

				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN MATCHED THEN
				      UPDATE
				         SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
				             t1.quality_code = t2.quality_code
				         WHERE    (t1.quality_code IN (SELECT quality_code
				                                         FROM cwms_data_quality q
				                                        WHERE q.protection_id = 'UNPROTECTED')
				                  )
				               OR (t2.quality_code IN (SELECT quality_code
				                                         FROM cwms_data_quality q
				                                        WHERE q.protection_id = 'PROTECTED'))
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
				              version_date)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
				              l_version_date);
			ELSE
        
		  		dbms_output.put_line('CASE 2: number of at_tables in schema: ' || table_cnt);
		
				FOR x IN (select start_date, end_date, table_name 
	                		from at_ts_table_properties 
		           		  where start_date<=maxdate 
		             	    and end_date>mindate)
				LOOP
		
					dbms_output.put_line('CASE 2: begin storage loop, table_name: ' || x.table_name);

					l_sql_txt:=
						' merge into '||x.table_name||' t1 
                     using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					               (t.value/c.factor) - c.offset value, 
								   t.quality_code 
		                      from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							       at_cwms_ts_spec s, 
									 at_parameter ap,
								    cwms_unit_conversion c, 
								    cwms_base_parameter p, 
								    cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
										 AND ap.base_parameter_code = p.base_parameter_code
                                and p.unit_code      =  c.from_unit_code 
                                and c.to_unit_code   =  u.unit_code 
                                and u.UNIT_ID        =  :p_units 
                                and date_time        >= :start_date 
								and date_time        <  :end_date 
			               ) t2
                        on (    t1.ts_code      = :l_ts_code 
						    and t1.date_time    = t2.date_time 
							and t1.version_date = :l_version_date )
                      when matched then 
		                update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                         where (t1.quality_code in (select quality_code 
	                                                  from cwms_data_quality q 
		  		                                     where q.PROTECTION_ID=''UNPROTECTED''
				                                    )
							    )
							 or (t2.quality_code in (select quality_code 
	                                                   from cwms_data_quality q 
		  		                                      where q.PROTECTION_ID=''PROTECTED''
													)
								)
                      when not matched then 
		                insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
			            values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code,:l_version_date )
	                 ';
						
					--dbms_output.put_line(l-sql_txt);			

					dbms_output.put_line('CASE 2: Executing dynamic merge statment');
		  
		  			execute immediate l_sql_txt using p_timeseries_data, 
		                           l_ts_code, p_units, x.start_date, x.end_date, 
										   l_ts_code,l_version_date, 
										   l_store_date,
										   l_ts_code, l_store_date, l_version_date;
		  
		  			dbms_output.put_line('CASE 2: Merge statement completed');
		  
		  		END LOOP;
		
				dbms_output.put_line('CASE 2: done with loop');
		
			END IF;
			
		WHEN upper(p_store_rule) = cwms_util.do_not_replace
		THEN
			--
			--*************************************
			-- CASE 3 - Store Rule: DO NOT REPLACE
			--*************************************
			--  
			dbms_application_info.set_action('merge into table, do_not_replace ');

			IF table_cnt=1
			THEN
			
				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
				              version_date)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
				              l_version_date);

			ELSE
		
				FOR x IN (select start_date, end_date, table_name 
	                     from at_ts_table_properties 
		                 where start_date<=maxdate 
		                   and end_date>mindate)
				LOOP

            	l_sql_txt:='merge into '||x.table_name||' t1
                      using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					                (t.value/c.factor) - c.offset value, 
									t.quality_code 
		                       from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							       at_cwms_ts_spec s, 
									 at_parameter ap,
								    cwms_unit_conversion c, 
								    cwms_base_parameter p, 
								    cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
										 AND ap.base_parameter_code = p.base_parameter_code
                                and p.unit_code      =  c.from_unit_code
                                and c.to_unit_code   =  u.unit_code
                                and u.UNIT_ID        =  :p_units
                                and date_time        >= :start_date 
								and date_time        <  :end_date 
			                ) t2
                         on (    t1.ts_code      = :l_ts_code 
						     and t1.date_time    = t2.date_time 
							 and t1.version_date = :l_version_date)
                       when not matched then
		                 insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
			              values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';
         
					execute immediate l_sql_txt using p_timeseries_data, 
			                        l_ts_code, p_units, x.start_date, x.end_date, 
											l_ts_code, l_version_date,  
											l_ts_code, l_store_date, l_version_date;
				END LOOP;
				
			END IF;
		WHEN upper(p_store_rule) = cwms_util.replace_missing_values_only
		THEN
			--
			--***************************************************
			-- CASE 4 - Store Rule: REPLACE MISSING VALUES ONLY -
			--*************************************************
			--
			dbms_application_info.set_action('merge into table, replace_missing_values_only');
   
			IF table_cnt=1
			THEN

				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN MATCHED THEN
				      UPDATE
				         SET t1.VALUE = t2.VALUE, t1.quality_code = t2.quality_code,
				             t1.data_entry_date = l_store_date
				         WHERE t1.quality_code IN (SELECT quality_code
				                                     FROM cwms_data_quality q
				                                    WHERE q.validity_id = 'MISSING')
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code);

			ELSE
		
				FOR x IN (select start_date, end_date, table_name 
	                     from at_ts_table_properties 
		                 where start_date<=maxdate 
		                  and end_date>mindate)
				LOOP
        
            	l_sql_txt:='merge into '||x.table_name||' t1
                      using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					                (t.value/c.factor) - c.offset value, 
									t.quality_code 
		                       from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							       at_cwms_ts_spec s, 
									 at_parameter ap,
								    cwms_unit_conversion c, 
								    cwms_base_parameter p, 
								    cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
										 AND ap.base_parameter_code = p.base_parameter_code
                                and p.unit_code      =  c.from_unit_code
                                and c.to_unit_code   =  u.unit_code
                                and u.UNIT_ID        =  :p_units
                                and date_time        >= :start_date 
								and date_time        <  :end_date
			                ) t2
                         on (    t1.ts_code      = :l_ts_code 
						     and t1.date_time    = t2.date_time 
							 and t1.version_date = :l_version_date)
                       when matched then 
		                 update set t1.value = t2.value, t1.quality_code = t2.quality_code, t1.data_entry_date = :l_store_date 
                          where t1.quality_code in (select quality_code 
						                              from cwms_data_quality q 
													 where q.VALIDITY_ID=''MISSING'')
                       when not matched then 
		                 insert (ts_code,  date_time,    data_entry_date, value,    quality_code,    version_date ) 
		  	             values (:l_ts_code, t2.date_time, :l_store_date,      t2.value, t2.quality_code, :l_version_date )';
 
 					execute immediate l_sql_txt using p_timeseries_data, 
			                        l_ts_code, p_units, x.start_date, x.end_date, 
											l_ts_code, l_version_date, 
											l_store_date, 
											l_ts_code, l_store_date, l_version_date;
				END LOOP;
				
			END IF;
      WHEN l_override_prot AND upper(p_store_rule) = cwms_util.replace_with_non_missing
		THEN
			--
			--*******************************************
			-- CASE 5 - Store Rule: REPLACE W/NON-MISSING -
			--         Override:   TRUE -
			--*******************************************
			--  
			dbms_application_info.set_action('merge into table, override, replace_with_non_missing ');

			IF table_cnt=1
			THEN
			
				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u,
				                 cwms_data_quality q
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND q.quality_code = t.quality_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN MATCHED THEN
				      UPDATE
				         SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
				             t1.quality_code = t2.quality_code
				         WHERE t2.quality_code NOT IN (SELECT quality_code
				                                         FROM cwms_data_quality
				                                        WHERE validity_id = 'MISSING')
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code);

			ELSE
   
				FOR x IN (select start_date, end_date, table_name 
		                  from at_ts_table_properties 
					        where start_date <= maxdate 
					          and end_date   >  mindate)
				LOOP
        
            	l_sql_txt:='merge into '||x.table_name||' t1
                      using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					                (t.value/c.factor) - c.offset value, 
									t.quality_code 
					           from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							        at_cwms_ts_spec s, 
									  at_parameter ap,
									cwms_unit_conversion c, 
									cwms_base_parameter p, 
									cwms_unit u, 
									cwms_data_quality q
                              where s.ts_code        =  :l_ts_code
                                and s.parameter_code =  ap.parameter_code
										  AND ap.base_parameter_code = p.base_parameter_code
                                and q.quality_code   =  t.quality_code
                                and p.unit_code      =  c.from_unit_code
                                and c.to_unit_code   =  u.unit_code
                                and u.UNIT_ID        =  :p_units
                                and date_time        >= :start_date 
						        and date_time        <  :end_date   
						    ) t2
                         on (    t1.ts_code      = :l_ts_code 
						     and t1.date_time    = t2.date_time 
							 and t1.version_date = :l_version_date)
                       when matched then 
					     update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
						  where t2.quality_code not in (select quality_code
						                                  from cwms_data_quality
														 where validity_id = ''MISSING'')									 
                       when not matched then 
					     insert (ts_code,  date_time,    data_entry_date, value,    quality_code,    version_date ) 
						 values (:l_ts_code, t2.date_time, :l_store_date,      t2.value, t2.quality_code, :l_version_date )';  
   
            	execute immediate l_sql_txt using p_timeseries_data, 
			                     l_ts_code, p_units, x.start_date, x.end_date, 
										l_ts_code, l_version_date, 
										l_store_date, 
										l_ts_code, l_store_date, l_version_date;
				END LOOP;
			END IF;

		WHEN NOT l_override_prot AND upper(p_store_rule) = cwms_util.replace_with_non_missing
		THEN
			--
			--******************************************* 
			-- Case 6 - Store Rule: Replace w/Non-Missing -
			--         Override:   FALSE -
			--*******************************************
			--  
			dbms_application_info.set_action('merge into table, no override, replace_with_non_missing ');

			IF table_cnt=1
			THEN 
  
				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u,
				                 cwms_data_quality q
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND q.quality_code = t.quality_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN MATCHED THEN
				      UPDATE
				         SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
				             t1.quality_code = t2.quality_code
				         WHERE     (   (t1.quality_code IN (
				                                         SELECT quality_code
				                                           FROM cwms_data_quality q
				                                          WHERE q.protection_id =
				                                                                 'UNPROTECTED')
				                       )
				                    OR (t2.quality_code IN (
				                                           SELECT quality_code
				                                             FROM cwms_data_quality q
				                                            WHERE q.protection_id =
				                                                                   'PROTECTED')
				                       )
				                   )
				               AND (t2.quality_code NOT IN (SELECT quality_code
				                                              FROM cwms_data_quality q
				                                             WHERE q.validity_id = 'MISSING')
				                   )
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
				              version_date)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
				              l_version_date);

			ELSE

				FOR x IN (select start_date, end_date, table_name 
		                  from at_ts_table_properties 
				           where start_date<=maxdate 
				             and end_date>mindate)
				LOOP
        
		  			l_sql_txt:='merge into '||x.table_name||' t1
                    using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					              (t.value/c.factor) - c.offset value, 
								  t.quality_code 
					         from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							      at_cwms_ts_spec s, 
									at_parameter ap,
								  cwms_unit_conversion c, 
								  cwms_base_parameter p, 
								  cwms_unit u,  
								  cwms_data_quality q
                            where s.ts_code        =  :l_ts_code
                              and s.parameter_code =  p.parameter_code
										AND ap.base_parameter_code = p.base_parameter_code
                              and q.quality_code   =  t.quality_code
                              and p.unit_code      =  c.from_unit_code
                              and c.to_unit_code   =  u.unit_code
                              and u.UNIT_ID        =  :p_units
                              and date_time        >= :start_date 
							  and date_time        <  :end_date     
						  ) t2
                       on ( t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                     when matched then 
					   update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                        where (  (t1.quality_code in (select quality_code 
						                            from cwms_data_quality q 
												   where q.PROTECTION_ID=''UNPROTECTED''
												  )
							     )
			                  or (t2.quality_code in (select quality_code 
	                                                 from cwms_data_quality q 
		  		                                    where q.PROTECTION_ID=''PROTECTED''
									              )
				                 )
							  )
						  and (t2.quality_code not in (select quality_code 
	                                                     from cwms_data_quality q 
		  		                                        where q.VALIDITY_ID=''MISSING''
									                  )
				              )
                     when not matched then 
					   insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
					   values (:l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';
   
					execute immediate l_sql_txt using p_timeseries_data, 
		                           l_ts_code, p_units, x.start_date, x.end_date, 
										   l_ts_code, l_version_date, 
										   l_store_date, 
										   l_ts_code, l_store_date, l_version_date;
				END LOOP;
				
			END IF;
		WHEN NOT l_override_prot AND upper(p_store_rule)=cwms_util.delete_insert
		THEN
			--
			--*************************************
			-- CASE 7 - Store Rule: DELETE - INSERT -
			--         Override:   FALSE -
			--*************************************
			--  
			dbms_application_info.set_action('delete/merge from table, no override, delete_insert ');
			dbms_output.put_line('CASE 7: STORE_TS rule: delete-insert, FALSE');
			dbms_output.put_line('CASE 7: table_cnt: ' || table_cnt);

			IF table_cnt=1
			THEN
	  
	  			dbms_output.put_line('CASE 7: Single Table Section');
      
				DELETE FROM at_tsv t1
				      WHERE date_time
				               BETWEEN (SELECT MIN (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
				                          FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
				                   AND (SELECT MAX (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
				                          FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
				        AND t1.ts_code = l_ts_code
				        AND t1.version_date = l_version_date
				        AND t1.quality_code IN (SELECT quality_code
				                                  FROM cwms_data_quality q
				                                 WHERE q.protection_id = 'UNPROTECTED');

				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code)
				   WHEN MATCHED THEN
				      UPDATE
				         SET t1.VALUE = t2.VALUE, t1.quality_code = t2.quality_code,
				             t1.data_entry_date = l_store_date
				         WHERE t2.quality_code IN (SELECT quality_code
				                                     FROM cwms_data_quality q
				                                    WHERE q.protection_id = 'PROTECTED');
																
			ELSE
	  
	  			dbms_output.put_line('CASE 7: Multiple Table Section');

				FOR x IN (select start_date, end_date, table_name 
		                  from at_ts_table_properties 
				           where start_date <= maxdate 
				             and end_date   >  mindate)
				LOOP
        
		  			dbms_output.put_line('CASE 7: preparing DELETE FROM dynamic sql for table: ' || x.table_name);
		
					l_sql_txt:=' delete from '||x.table_name||' t1
                      where date_time between (select min(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
					                             from TABLE(cast(:p_timeseries_data as tsv_array)) t) 
										  and (select max(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
										         from TABLE(cast(:p_timeseries_data as tsv_array)) t)
                        and t1.ts_code = :l_ts_code
                        and t1.version_date = :l_version_date
                        and t1.quality_code in (select quality_code 
						                          from cwms_data_quality q 
												 where q.PROTECTION_ID=''UNPROTECTED'')';

					--dbms_output.put_line(l_sql_txt);		  
					dbms_output.put_line('CASE 7: Executing DELETE FROM dynamic sql for table: ' || x.table_name);

					execute immediate l_sql_txt using p_timeseries_data, p_timeseries_data, l_ts_code, l_version_date;

					dbms_output.put_line('CASE 7: preparing MERGE INTO dynamic sql for table: ' || x.table_name);

					l_sql_txt:='merge into '||x.table_name||' t1
                    using (select  CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time,
					               (t.value/c.factor) - c.offset value, 
								   t.quality_code 
					         from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							      at_cwms_ts_spec s,
									at_parameter ap,
								  cwms_unit_conversion c, 
								  cwms_base_parameter p, 
								  cwms_unit u
                            where s.ts_code        =  :l_ts_code
                              and s.parameter_code =  ap.parameter_code
  									   AND ap.base_parameter_code = p.base_parameter_code
                              and p.unit_code      =  c.from_unit_code
                              and c.to_unit_code   =  u.unit_code
                              and u.UNIT_ID        =  :p_units
                              and date_time        >= :start_date 
							  and date_time        <  :end_date   
						  ) t2
                       on (    t1.ts_code      = :l_ts_code 
					       and t1.date_time    =  t2.date_time 
						   and t1.version_date = :l_version_date)
                     when not matched then
					   insert (ts_code, date_time, data_entry_date, value, quality_code, version_date ) 
					   values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )
                   when matched then 
					   update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                        where t2.quality_code in (select quality_code from cwms_data_quality q where q.PROTECTION_ID=''PROTECTED'')
                 ';
				 
				 	dbms_output.put_line('CASE 7: Executing MERGE INTO dynamic sql for table: ' || x.table_name);
				   --dbms_output.put_line(l_sql_txt);
		  
		  		   execute immediate l_sql_txt using p_timeseries_data, 
		                           l_ts_code, p_units, x.start_date, x.end_date, 
										   l_ts_code, l_version_date, 
										   l_ts_code, l_store_date, l_version_date,
										   l_store_date;
		  
		  			dbms_output.put_line('CASE 7: Merge completed.');
		  
		  		END LOOP;
		
				dbms_output.put_line('CASE 7: delete-insert FALSE Completed.');
				
			END IF;
 
 		WHEN l_override_prot AND upper(p_store_rule) = cwms_util.delete_insert
		THEN
			--
			--************************************* 
			--CASE 8 - Store Rule: DELETE - INSERT -
			--         Override:   TRUE -
			--*************************************
			-- 
		   dbms_application_info.set_action('delete/merge from  table, override, delete_insert ');
			dbms_output.put_line('CASE 8: STORE_TS rule: delete-insert, TRUE');
			dbms_output.put_line('CASE 8: table_cnt: ' || table_cnt);
		
      	IF table_cnt=1
			THEN 

         	dbms_output.put_line('CASE 8: Single Table Section');
	  
				DELETE FROM at_tsv t1
				      WHERE date_time
				               BETWEEN (SELECT MIN (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
				                          FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
				                   AND (SELECT MAX (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
				                          FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
				        AND t1.ts_code = l_ts_code
				        AND t1.version_date = l_version_date;
				
				MERGE INTO at_tsv t1
				   USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
				                 (t.VALUE / c.factor) - c.offset VALUE, t.quality_code
				            FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
				                 at_cwms_ts_spec s,
									  at_parameter ap,
				                 cwms_unit_conversion c,
				                 cwms_base_parameter p,
				                 cwms_unit u
				           WHERE s.ts_code = l_ts_code
				             AND s.parameter_code = ap.parameter_code
								 AND ap.base_parameter_code = p.base_parameter_code
				             AND p.unit_code = c.from_unit_code
				             AND c.to_unit_code = u.unit_code
				             AND u.unit_id = p_units) t2
				   ON (    t1.ts_code = l_ts_code
				       AND t1.date_time = t2.date_time
				       AND t1.version_date = l_version_date)
				   WHEN NOT MATCHED THEN
				      INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
				      VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code);

		   ELSE
   
				FOR x IN (select start_date, end_date, table_name 
		                  from at_ts_table_properties 
				           where start_date<=maxdate 
				             and end_date>mindate)
				LOOP
        
		  			dbms_output.put_line('CASE 8: preparing DELETE FROM dynamic sql for av_tsv view');

					l_sql_txt:='delete from '||x.table_name||' t1
                     where date_time between (select min(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
					                            from TABLE(cast(:p_timeseries_data as tsv_array)) t) 
								         and (select max(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
										        from TABLE(cast(:p_timeseries_data as tsv_array)) t)
                       and t1.ts_code =: l_tcode
                       and t1.version_date = :l_version_date';

       	  		--dbms_output.put_line(l_sql_txt);
					dbms_output.put_line('CASE 8: executing DELETE FROM dynamic sql for av_tsv view');

          		execute immediate l_sql_txt using p_timeseries_data, p_timeseries_data, l_ts_code, l_version_date;

					dbms_output.put_line('CASE 8: preparing MERGE INTO dynamic sql for table: ' || x.table_name);
		  
		  			l_sql_txt:='merge into '||x.table_name||' t1
                    using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
					              (t.value/c.factor) - c.offset value, 
								  t.quality_code 
					         from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
							      at_cwms_ts_spec s, 
									at_parameter ap,
								  cwms_unit_conversion c, 
								  cwms_base_parameter p, 
								  cwms_unit u
                            where s.ts_code        =  :l_ts_code
                              and s.parameter_code =  ap.parameter_code
										AND ap.base_parameter_code = p.base_parameter_code
                              and p.unit_code      =  c.from_unit_code
                              and c.to_unit_code   =  u.unit_code
                              and u.UNIT_ID        =  :p_units
                              and date_time        >= :start_date 
							  and date_time        <  :end_date
						  ) t2
                       on (    t1.ts_code      = :l_ts_code 
					       and t1.date_time    = t2.date_time 
						   and t1.version_date = :l_version_date)
                     when not matched then
					   insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
					   values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';

					dbms_output.put_line('CASE 8: Executing MERGE INTO dynamic sql for table: ' || x.table_name);

					execute immediate l_sql_txt using p_timeseries_data, 
		                           l_ts_code, p_units, x.start_date, x.end_date,
										   l_ts_code, l_version_date, 
										   l_ts_code, l_store_date, l_version_date;
		  
		  			dbms_output.put_line('CASE 8: Merge completed.');
					
				END LOOP;
		
				dbms_output.put_line('CASE 8: delete-insert TRUE Completed.');
				
			END IF;
		
		ELSE
		
			cwms_err.raise('INVALID_STORE_RULE',p_store_rule);
		
		END CASE;

		COMMIT;

  		-----------------------------------------------                                                                    
  		-- notify the real-time Oracle->DSS exchange --
  		-----------------------------------------------  
		--   cwms_xchg.time_series_updated(
		--     l_ts_code, 
		--     l_office_id, 
		--     p_timeseries_desc,
		--     p_store_rule, 
		--     p_units,
		--     l_override_prot, 
		--     p_timeseries_data);
    
  	 	dbms_application_info.set_module(null, null);

	END store_ts;
--
--*******************************************************************   --
--** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE ****   --
--
-- DELETE_TS_CLEANUP -
--
	PROCEDURE delete_ts_cleanup (
	   p_ts_code_old     IN   NUMBER,
	   p_ts_code_new     IN   NUMBER,
	   p_delete_action   IN   VARCHAR2
	)
	IS
	BEGIN
	   CASE
	      WHEN p_delete_action = cwms_util.delete_all
	      THEN
	         NULL;             -- NOTE TO GERHARD Need to think about cleaning up
	                           -- all of the dependancies when deleting.
	      WHEN p_delete_action = cwms_util.delete_data
	      THEN
	         UPDATE at_transform_criteria
	            SET ts_code = p_ts_code_new
	          WHERE ts_code = p_ts_code_old;
	
	         --
	         UPDATE at_transform_criteria
	            SET resultant_ts_code = p_ts_code_new
	          WHERE resultant_ts_code = p_ts_code_old;
	
	         --
	         UPDATE at_alarm
	            SET ts_code = p_ts_code_new
	          WHERE ts_code = p_ts_code_old;
	
	         --
	         UPDATE at_validation
	            SET ts_code = p_ts_code_new
	          WHERE ts_code = p_ts_code_old;
	   END CASE;
	END delete_ts_cleanup;

--

--*******************************************************************   --
--*******************************************************************   --
--
-- DELETE_TS -
--
/* Formatted on 2006/10/30 14:38 (Formatter Plus v4.8.7) */
PROCEDURE delete_ts (
   p_timeseries_desc   IN   VARCHAR2,
   p_delete_action     IN   VARCHAR2 DEFAULT cwms_util.delete_all,
   p_office_id         IN   VARCHAR2 DEFAULT NULL
)
IS
   l_office_id       VARCHAR2 (16);
   l_ts_code         NUMBER;
   l_ts_code_new     NUMBER        := NULL;
   l_delete_action   VARCHAR2 (16) := UPPER (p_delete_action);
   l_delete_date     DATE          := SYSDATE;
   l_tmp_del_date    DATE          := l_delete_date + 1;
--
BEGIN
   --
   IF p_office_id IS NULL
   THEN
      l_office_id := cwms_util.user_office_id;
   ELSE
      l_office_id := p_office_id;
   END IF;

   --
   BEGIN
      SELECT ts_code
        INTO l_ts_code
        FROM mv_cwms_ts_id mcts
       WHERE UPPER (mcts.cwms_ts_id) = UPPER (p_timeseries_desc)
         AND UPPER (mcts.office_id) = UPPER (l_office_id);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('TS_ID_NOT_FOUND', p_timeseries_desc);
   END;

   --
   IF NVL (l_delete_action, cwms_util.delete_all) = cwms_util.delete_all
   THEN
      l_delete_action := cwms_util.delete_all;
   ELSIF l_delete_action = cwms_util.delete_data
   THEN
      l_delete_action := cwms_util.delete_data;
   ELSE
      cwms_err.RAISE ('INVALID_DELETE_ACTION', p_delete_action);
   END IF;

   -- If deleting the data only, then a new replacement ts_code must --
   -- be created --
   --
   IF l_delete_action = cwms_util.delete_data
   THEN     -- Create replacement ts_id - temporarily disabled by setting a --
            -- delete date - need to do this so as not to violate unique    --
            -- constraint --
      SELECT cwms_seq.NEXTVAL
        INTO l_ts_code_new
        FROM DUAL;

      INSERT INTO at_cwms_ts_spec
         SELECT l_ts_code_new, office_code, location_code, parameter_code,
                parameter_type_code, interval_code, duration_code, VERSION,
                ts_ni_hash, description, interval_utc_offset,
                interval_forward, interval_backward, interval_offset_id,
                time_zone_code, version_flag, migrate_ver_flag, active_flag,
                l_tmp_del_date, data_source
           FROM at_cwms_ts_spec acts
          WHERE acts.ts_code = l_ts_code;
   END IF;

   -- Delete the timeseries id --
   UPDATE at_cwms_ts_spec
      SET location_code = 0,
          delete_date = l_delete_date
    WHERE ts_code = l_ts_code;

   IF l_delete_action = cwms_util.delete_data
   THEN
      -- Activate the replacement ts_id by setting the delete_date to null --
      UPDATE at_cwms_ts_spec
         SET delete_date = NULL
       WHERE ts_code = l_ts_code_new;
   END IF;

   --
   COMMIT;
   --
   delete_ts_cleanup (l_ts_code, l_ts_code_new, l_delete_action);
--
END delete_ts;
--	
END cwms_ts; --end package body
/

