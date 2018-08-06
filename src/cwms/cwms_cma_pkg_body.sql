create or replace package BODY                                                                                                                                                                                                                         CWMS_CMA
IS
   /******************************************************************************
      NAME:       CWMS_CMA_ERDC
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        6/19/2013    u4rt9jdk        1. Created this package.
      1.2        OCT2013      JDK             1. Updated for CWMS 3.0
      1.3        Sep2015      JDK             1. Updated for CMA 2.03
      1.3.1      OCT 2015     JDK             1. Updated for CMA 2.03 with bug fixes
      1.3.2      JAN2015      JDK             1. Updated for CMA 2.03 with more bug fixes
      1.3.2.1    MAR2017      JDK             1. CWMS 3.06 bug fixes and cwms xxx a2w locatioN_id  to location_code fixes
      1.4        JUL2018      JDK	      1. Bug fixes and additional A2W options
   ******************************************************************************/

   FUNCTION MyFunction (Param1 IN NUMBER)
      RETURN NUMBER
   IS
   BEGIN
      RETURN 1;
   END;

   FUNCTION apex_log_error (p_error IN apex_error.t_error)
      RETURN at_cma_error_log.id%TYPE
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_error_id            at_cma_error_log.id%TYPE;
      l_is_internal_error   at_cma_error_log.is_internal_error%TYPE;
   BEGIN
      IF p_error.is_internal_error
      THEN
         l_is_internal_error := 'Y';
      ELSE
         l_is_internal_error := 'N';
      END IF;

      --
      INSERT INTO at_cma_error_log (MESSAGE,
                                    additional_info,
                                    display_location,
                                    association_type,
                                    page_item_name,
                                    region_id,
                                    column_alias,
                                    row_num,
                                    is_internal_error,
                                    apex_error_code,
                                    ora_sqlcode,
                                    ora_sqlerrm,
                                    error_backtrace,
                                    component_type,
                                    component_id,
                                    component_name     -- substitution strings
                                                  ,
                                    application_id,
                                    app_page_id,
                                    app_user,
                                    browser_language,
                                    date_time)
           VALUES (p_error.MESSAGE,
                   p_error.additional_info,
                   p_error.display_location,
                   p_error.association_type,
                   p_error.page_item_name,
                   p_error.region_id,
                   p_error.column_alias,
                   p_error.row_num,
                   l_is_internal_error,
                   p_error.apex_error_code,
                   p_error.ora_sqlcode,
                   p_error.ora_sqlerrm,
                   p_error.error_backtrace,
                   p_error.component.TYPE,
                   p_error.component.id,
                   p_error.component.name              -- substitution strings
                                         ,
                   v ('APP_ID'),
                   v ('APP_PAGE_ID'),
                   v ('APP_USER'),
                   v ('BROWSER_LANGUAGE'),
                   SYSDATE)
        RETURNING id
             INTO l_error_id;

      COMMIT;
      --
      RETURN l_error_id;
   END apex_log_error;



   FUNCTION f_calc_num_pts_p_day_interval (
      f_interval_id IN cwms_V_ts_id.interval_id%TYPE)
      RETURN NUMBER
   IS
      temp_num   NUMBER DEFAULT NULL;
   BEGIN
      CASE f_interval_id
         WHEN '1Day'
         THEN
            temp_num := 1;
         WHEN '1Hour'
         THEN
            temp_num := 24;
         WHEN '2Hours'
         THEN
            temp_num := 12;
         WHEN '3Hours'
         THEN
            temp_num := 8;                                  -- 24hours/day / 3
         WHEN '4Hours'
         THEN
            temp_num := 6;                                  -- 24hours/day / 4
         WHEN '6Hours'
         THEN
            temp_num := 4;
         WHEN '8Hours'
         THEN
            temp_num := 3;              -- 24/hours/day divided by 8 hours = 3
         WHEN '30Minutes'
         THEN
            temp_num := 2 * 24;            --2 records/hour times 24 hours/day
         WHEN '15Minutes'
         THEN
            temp_num := 4 * 24;                --4 records/hour times 24 hours
         WHEN '10Minutes'
         THEN
            temp_num := 6 * 24;                --6 records/hour times 24 hours
         WHEN '6Minutes'
         THEN
            temp_num := 10 * 24;                    --10 records/hour times 24
         WHEN '5Minutes'
         THEN
            temp_num := 12 * 24;              --12 records/hour times 24 hours
         WHEN '4Minutes'
         THEN
            temp_num := 15 * 24;              --15 records/hour times 24 hours
         WHEN '3Minutes'
         THEN
            temp_num := 20 * 24;
         WHEN '2Minutes'
         THEN
            temp_num := 30 * 24;              --30 records/hour times 24 hours
         --~ intervals?

         WHEN '~1Day'
         THEN
            temp_num := 1;
         WHEN '~1Hour'
         THEN
            temp_num := 24;
         WHEN '~2Hours'
         THEN
            temp_num := 12;
         WHEN '~3Hours'
         THEN
            temp_num := 8;                                  -- 24hours/day / 3
         WHEN '~4Hours'
         THEN
            temp_num := 6;                                  -- 24hours/day / 4
         WHEN '~6Hours'
         THEN
            temp_num := 4;
         WHEN '~8Hours'
         THEN
            temp_num := 3;              -- 24/hours/day divided by 8 hours = 3
         WHEN '~30Minutes'
         THEN
            temp_num := 2 * 24;            --2 records/hour times 24 hours/day
         WHEN '~15Minutes'
         THEN
            temp_num := 4 * 24;                --4 records/hour times 24 hours
         WHEN '~10Minutes'
         THEN
            temp_num := 6 * 24;                --6 records/hour times 24 hours
         WHEN '~6Minutes'
         THEN
            temp_num := 10 * 24;                    --10 records/hour times 24
         WHEN '~5Minutes'
         THEN
            temp_num := 12 * 24;              --12 records/hour times 24 hours
         WHEN '~4Minutes'
         THEN
            temp_num := 15 * 24;              --15 records/hour times 24 hours
         WHEN '~3Minutes'
         THEN
            temp_num := 20 * 24;
         WHEN '~2Minutes'
         THEN
            temp_num := 30 * 24;
         ELSE
            temp_num := NULL;
      END CASE;

      RETURN temp_num;
   END f_calc_num_pts_p_day_interval;



   FUNCTION f_calc_num_pts_p_day_ts_id (
      f_cwms_ts_id IN cwms_v_ts_id.cwms_ts_id%TYPE)
      RETURN NUMBER
   IS
      temp_num   NUMBER DEFAULT NULL;
   BEGIN
      FOR x IN (SELECT DISTINCT interval_id
                  FROM cwms_v_ts_id
                 WHERE ts_code = f_cwms_ts_id)
      LOOP
         temp_Num :=
            f_calc_num_pts_p_day_interval (f_interval_id => x.interval_id);
      END LOOP;

      RETURN temp_num;
   END f_calc_num_pts_p_day_ts_id;

   FUNCTION f_get_loc_attribs_by_xy (
      p_latitude    IN cwms_v_loc.latitude%TYPE,
      p_longitude   IN cwms_v_loc.longitude%TYPE)
      RETURN VARCHAR2
   IS
      temp_1   VARCHAR2 (1999);
      temp_2   VARCHAR2 (1999);
      temp_3   VARCHAR2 (1999);
      temp_4   VARCHAR2 (1999);
      temp_5   VARCHAR2 (1999);
      delim    VARCHAR2 (10) DEFAULT '<BR>';
   BEGIN
      p_preload_squery_by_xy (p_lat              => p_latitude,
                              p_lon              => p_longitude,
                              p_county           => temp_1,
                              p_nation_id        => temp_2,
                              p_nearest_city     => temp_3,
                              p_state_initial    => temp_4,
                              p_time_zone_name   => temp_5);


      temp_1 := ' County = ' || temp_1;
      temp_2 := ' Nation = ' || temp_2;
      temp_3 := ' Nearest City = ' || temp_3;
      temp_4 := ' State = ' || temp_4;
      temp_5 := ' TZ = ' || temp_5;


      RETURN    temp_1
             || delim
             || temp_2
             || delim
             || temp_3
             || delim
             || temp_4
             || delim
             || temp_5;
   END f_get_loc_attribs_by_xy;

   FUNCTION f_get_loc_home_tools_by_loc (f_location_code IN cwms_v_loc.location_code%TYPE
                                        ,f_app_id        IN NUMBER
                                        ,f_session_id    IN NUMBER
                                        ) RETURN VARCHAR2  IS
   
   
   
  num_LL      NUMBER DEFAULT 0;
  temp_out    VARCHAR2(1999);
  BEGIN
  
   FOR x  IN (SELECT locatioN_code
                   , location_id   
                FROM cwms_v_loc
               WHERE unit_system = 'EN'
                 AND locatioN_code = f_location_code
                 ) LOOP
                    temp_out :=
                    '<a href="f?p='
                           || TO_CHAR(f_APP_ID)
                           || ':'
                           || 14
                           || ':'
                           || TO_CHAR(f_SESSION_id)
                           || '::::P14_SEARCH_STRING:'
                           || x.location_id
                           || '"><img src="#WORKSPACE_IMAGES#Search-16.png" title="Search" alt="Search"></a>';
                   END LOOP;
  
      temp_out := REPLACE(temp_out
                      , '#WORKSPACE_IMAGES#Search-16.png'
                      , 'http://cpc-cwmsdb3.usace.army.mil:8082/apex/wwv_flow_file_mgr.get_file?p_security_group_id=1589520410177877&p_fname=Search-16.png'
                         );
  
    num_ll := f_get_loc_num_ll(f_locatioN_code, 'ALL');
    IF num_ll > 0 THEN
    
      temp_out := temp_Out || ' ' || '<img src="#WORKSPACE_IMAGES#Location_level-16.png" title="' || TO_CHAR(num_ll) || ' LL Exist" alt="LL Exist"></a>x' || TO_CHAR(num_ll) ;
      temp_out := REPLACE(temp_out
                      , '#WORKSPACE_IMAGES#Location_level-16.png'
                      , 'http://cpc-cwmsdb3.usace.army.mil:8082/apex/wwv_flow_file_mgr.get_file?p_security_group_id=1589520410177877&p_fname=Location_level-16.png'
                         );
      temp_out := '<a href="f?p='
                           || TO_CHAR(f_APP_ID)
                           || ':'
                           || 364
                           || ':'
                           || TO_CHAR(f_SESSION_id)
                           || '::::F99_LOCATION_CODE:'
                           || f_location_code
                           || '"> ' || temp_out;                  
                         
    ELSE
      temp_out := temp_Out || ' ' || '<img src="#WORKSPACE_IMAGES#Location_level-16.png" title="No LLs" alt="No LLs"></a>';
      temp_out := REPLACE(temp_out
                      , '#WORKSPACE_IMAGES#Location_level-16.png'
                      , 'http://cpc-cwmsdb3.usace.army.mil:8082/apex/wwv_flow_file_mgr.get_file?p_security_group_id=1589520410177877&p_fname=Location_level-16.png'
                         );
  
    END IF;
  
  
  RETURN Temp_out;                   
   END;
FUNCTION f_get_loc_num_ll(f_location_code IN cwms_v_loc.location_code%TYPE
                            ,f_location_level_kind IN VARCHAR2 DEFAULT 'ALL'
                            ) RETURN NUMBER IS
  temp_out NUMBER DEFAULT 0;
  BEGIN                            

    IF f_location_level_kind = 'ALL' THEN

      SELECT COUNT(location_code) 
        INTO temp_out
        FROM at_location_level
      WHERE locatioN_code = f_location_code;

    ELSE
    
     CASE f_location_level_kind 
      WHEN 'CONSTANT' THEN
       SELECT COUNT(location_code) 
         INTO temp_out
         FROM at_location_level
        WHERE locatioN_code = f_location_code
          AND interval_origin IS NULL
          AND ts_code IS NULL;
      WHEN 'SEASONAL' THEN
       SELECT COUNT(location_code) 
         INTO temp_out
         FROM at_location_level
        WHERE locatioN_code = f_location_code
          AND interval_origin IS NOT NULL
          AND ts_code IS NULL;
      WHEN 'TS_ID' THEN 
       SELECT COUNT(location_code) 
         INTO temp_out
         FROM at_location_level
        WHERE locatioN_code = f_location_code
          AND ts_code IS NOT NULL;
      ELSE NULL;
    END CASE;
    
    END IF;

   RETURN temp_out;

  END f_get_loc_num_ll;
   FUNCTION f_get_tz_by_xy (p_latitude    IN cwms_v_loc.latitude%TYPE,
                            p_longitude   IN cwms_v_loc.longitude%TYPE)
      RETURN cwms_v_loc.time_zone_name%TYPE
   IS
      temp_county           cwms_v_loc.county_name%TYPE;
      temp_nation_id        cwms_v_loc.nation_id%TYPE;
      temp_nearest_city     cwms_v_loc.nearest_city%TYPE;
      temp_state_initial    cwms_v_loc.state_initial%TYPE;
      temp_time_zone_name   cwms_v_loc.time_zone_name%TYPE;
   BEGIN
      p_preload_squery_by_xy (p_lat              => p_latitude,
                              p_lon              => p_longitude,
                              p_county           => temp_county,
                              p_nation_id        => temp_natioN_id,
                              p_nearest_city     => temp_nearest_city,
                              p_state_initial    => temp_state_initial,
                              p_time_zone_name   => temp_time_zone_name);

      RETURN temp_time_zone_name;
   END;

   FUNCTION f_validate_loc_for_nh (
      f_location_id IN cwms_v_loc.locatioN_id%TYPE)
      RETURN VARCHAR2
   IS
      temp_out     VARCHAR2 (1999);
      num_issues   NUMBER DEFAULT 0;
   BEGIN
      -- This function will return NULL if the location will be displayed in the NW Site
      --This function will return a string if it fails for any reason (lat/lon/etc.)

      FOR x IN (SELECT *
                  FROM cwms_v_Loc
                 WHERE unit_system = 'EN' AND location_id = f_locatioN_id)
      LOOP
         NULL;

         IF x.loc_active_flag = 'F'
         THEN
            temp_out := temp_out || ' Location is inactive';
            num_issues := num_issues + 1;
         END IF;

         IF    x.latitude = 0
            OR x.latitude IS NULL
            OR x.longitude = 0
            OR x.latitude IS NULL
         THEN
            temp_out := temp_out || ' lat/lons are invalid.';
            num_issues := num_issues + 1;
         END IF;
      END LOOP;

      IF num_issues > 0
      THEN
         RETURN f_location_id || ' has ' || num_issues || ' of' || temp_out;
      ELSE
         RETURN NULL;
      END IF;
   END;

   FUNCTION f_validate_string (f_string_1   IN VARCHAR2,
                               f_string_2   IN VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      IF UPPER (f_string_1) = UPPER (f_string_2)
      THEN
         RETURN '=';
      ELSE
         RETURN '-'; --'<img src="#WORKSPACE_IMAGES#bullet_ball_red16.png" title="Search" alt="Search"></a>';
      END IF;
   END;
FUNCTION f_get_ll_home_container (f_location_code IN CWMS_V_LOC.location_code%TYPE) RETURN VARCHAR2 IS
   temp_out VARCHAR2(1999);
   BEGIN
   FOR x IN (SELECT parameter_id, num_ll, rownum row_num
                FROM (
              SELECT parameter_id, COUNT(parameter_id) num_ll
                          FROM (SELECT DISTINCT location_level_id, parameter_id 
                                  FROM cwms_v_location_level
                                 WHERE location_code = f_location_code
                                )
                         GROUP BY parameter_id
                          ORDER BY 2 DESC
                          )
            

              ) LOOP
             IF x.row_Num = 1 THEN temp_out := '<li><a href="#tabs-1">' || x.parameter_id || '</a></li>'; END IF;
             IF x.row_num = 2 THEN temp_out := temp_out || '
             <li><a href="#tabs-2">' || x.parameter_id || '</a></li>';  END IF;
             IF x.row_num = 3 THEN temp_out := temp_out || '
             <li><a href="#tabs-3">' || x.parameter_id || '</a></li>';  END IF;
             IF x.row_num = 4 THEN temp_out := temp_out || '
             <li><a href="#tabs-4">' || x.parameter_id || '</a></li>';  END IF;
             IF x.row_num = 5 THEN temp_out := temp_out || '
             <li><a href="#tabs-5">' || x.parameter_id || '</a></li>';  END IF;
             IF x.row_num = 6 THEN temp_out := temp_out || '
             <li><a href="#tabs-6">' || x.parameter_id || '</a></li>';  END IF;
             IF x.row_num = 7 THEN temp_out := temp_out || '
             <li><a href="#tabs-7">' || x.parameter_id || '</a></li>';  END IF;
             IF x.row_num = 8 THEN temp_out := temp_out || '
             <li><a href="#tabs-8">' || x.parameter_id || '</a></li>';  END IF;
          
            END LOOP;
   
   
   IF temp_out IS NOT NULL THEN
    Temp_out :=    '<div id="tabs">
<ul> ' || temp_out ||' 
    </ul>
</div>';
   ELSE 
         Temp_out :=    '<div id="tabs">
<ul> '  ||' 
    </ul>
</div>';

   END IF;

  RETURN temp_out;

   END;
   FUNCTION f_validate_loc_by_loc_types (
      f_location_code IN cwms_v_loc.location_code%TYPE)
      RETURN VARCHAR2
   IS
      temp_type          VARCHAR2 (199);
      num_ll             NUMBER DEFAULT 0;
      temp_location_id   cwms_v_loc.location_id%TYPE;
      temp_out           VARCHAR2 (1999);
   BEGIN
      -- This function will validate a location against its location type (so if it's a project, have certain location levels
      SELECT location_id
        INTO temp_location_id
        FROM cwms_v_loc
       WHERE unit_system = 'EN' AND location_code = f_location_code;

      FOR x
         IN (SELECT *
               FROM cwms_v_location_type
              WHERE     location_type != 'NONE'
                    AND location_code = f_location_code)
      LOOP
         NULL;

         CASE x.location_type
            WHEN 'PROJECT'
            THEN
               FOR y
                  IN (SELECT *
                        FROM cwms_v_location_level
                       WHERE     location_id = temp_location_id
                             AND base_parameter_id IN ('Elev', 'Stage'))
               LOOP
                  CASE UPPER (y.specified_level_id)
                     WHEN 'STREAMBED'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'STREAM BED'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'TOP OF FLOOD'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'TOP OF CONSERVATION'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'BOTTOM OF CONSERVATION'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'TOP OF NORMAL'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'TOP OF INACTIVE'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'BOTTOM OF INACTIVE'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'TOP OF INLET'
                     THEN
                        num_ll := num_ll + 1;
                     WHEN 'BOTTOM OF INLET'
                     THEN
                        num_ll := num_ll + 1;
                     ELSE
                        NULL;
                  END CASE;
               END LOOP;

               temp_out :=
                     temp_out
                  || ' - '
                  || ' found '
                  || num_ll
                  || ' known location levels';
               NULL;
            ELSE
               NULL;
         END CASE;
      END LOOP;

      RETURN temp_out;
   END;

   FUNCTION f_get_nw_loc_link (
      f_locatioN_id          IN cwms_v_loc.locatioN_id%TYPE,
      f_map_or_rpt_or_both   IN VARCHAR2 DEFAULT 'Both',
      f_html_link_or_text    IN VARCHAR2 DEFAULT 'HTML')
      RETURN VARCHAR2
   IS
      temp_issues   VARCHAR2 (1999);
   BEGIN
      temp_issues := f_validate_loc_for_nh (f_locatioN_id);

      IF temp_issues IS NULL
      THEN
         NULL;
      ELSE
         --CASE f_html_link_or_text
         -- WHEN

         RETURN temp_issues;
      END IF;
   END;

   FUNCTION orcl_2_unix (f_oracle_date IN DATE)
      RETURN NUMBER
   IS
   BEGIN
      --http://www.orafaq.com/usenet/comp.databases.oracle.misc/2004/09/02/0035.htm

      RETURN ROUND (
                  (f_oracle_date - TO_DATE ('19700101', 'yyyymmdd')) * 86400
                -   TO_NUMBER (SUBSTR (TZ_OFFSET (SESSIONTIMEZONE), 1, 3))
                  * 3600,
                0);
   --    RETURN (f_oracle_date - TO_DATE('19700101','yyyymmdd'))*86400 ;
   END;

   PROCEDURE copy_ts_code_to_ts_code (
      p_ts_code_from      IN     cwms_v_ts_id.ts_code%TYPE,
      p_ts_code_to        IN     cwms_v_ts_id.Ts_code%TYPE,
      p_store_rule_code   IN     cwms_store_rule.store_rule_code%TYPE,
      p_out                  OUT VARCHAR2,
      p_date_start        IN     DATE DEFAULT NULL,
      p_date_end          IN     DATE DEFAULT NULL)
   IS
      --This procedure will copy a TSCODE values from one to another

      temp_value             CWMS_T_TSV;
      temp_value_array       cwms_t_tsv_array;
      temp_store_rule        cwms_store_rule.store_rule_id%TYPE;

      temp_cwms_ts_id_to     cwms_v_ts_id.cwms_ts_id%TYPE;
      temp_db_office_id_to   cwms_v_ts_id.db_Office_id%TYPE;

      temp_unit_id           cwms_v_ts_id.unit_id%TYPE;
   BEGIN
      --Get the selected store rule
      SELECT store_rule_id
        INTO temp_store_rule
        FROM cwms_store_rule
       WHERE store_rule_code = p_store_rule_code;

      --Get the destination units and db_office_id
      SELECT db_office_id, cwms_ts_id, unit_id
        INTO temp_db_office_id_to, temp_cwms_ts_id_to, temp_unit_id
        FROM cwms_v_ts_id
       WHERE ts_code = p_ts_code_to;

      --SELECT MIN(date_time), COUNT(value) FROM cwms_v_tsv WHERE ts_code = 6145017

      --SELECT MIN(date_time), COUNT(value) FROM cwms_v_tsv WHERE ts_code = 1054054

      --Initialize the arrays
      temp_value_array := cwms_t_tsv_array ();

      --from 6145017 to 1054054



      FOR x
         IN (SELECT tsv.*, tsi.unit_id, tsi.db_office_id
               FROM cwms_v_tsv tsv, cwms_v_ts_id tsi
              WHERE     tsv.ts_code = tsi.ts_code
                    AND tsv.ts_code = p_ts_code_from)
      LOOP
         --Initialize the arrays

         --Set the cwms_t_tsv type to the date/time
         temp_Value := cwms_t_tsv (x.date_time, x.VALUE, x.quality_code);
         --Add the record to the array
         temp_value_array.EXTEND ();
         temp_value_array (temp_value_array.LAST) := temp_value;
      END LOOP;


      --Store TS Code
      cwms_ts.store_ts (p_cwms_ts_id        => temp_cwms_ts_id_to,
                        p_units             => temp_unit_id,
                        p_timeseries_data   => temp_value_array,
                        p_store_rule        => temp_store_rule,
                        p_override_prot     => 'F',
                        p_version_date      => cwms_util.non_versioned,
                        p_office_id         => temp_db_office_id_to);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := SQLERRM;
   END;


   PROCEDURE copy_tsc_to_tsc_interp (
      p_ts_code_from      IN     cwms_v_ts_id.ts_code%TYPE,
      p_ts_code_to        IN     cwms_v_ts_id.Ts_code%TYPE,
      p_store_rule_code   IN     cwms_store_rule.store_Rule_code%TYPE,
      p_interpolate_tf    IN     VARCHAR2 DEFAULT 'T',
      p_out                  OUT VARCHAR2,
      p_date_start        IN     DATE,
      p_date_end          IN     DATE)
   IS
      --This procedure will copy a TSCODE values from one to another

      temp_value                CWMS_T_TSV;
      temp_value_array          cwms_t_tsv_array;

      temp_value_interp         CWMS_T_TSV;
      temp_value_array_interp   cwms_t_tsv_array;

      temp_store_rule           cwms_store_rule.store_rule_id%TYPE;

      temp_cwms_ts_id_from      cwms_v_ts_id.cwms_ts_id%TYPE;
      temp_db_office_id_from    cwms_v_ts_id.db_Office_id%TYPE;
      temp_interval_id_from     cwms_v_ts_id.interval_id%TYPE;


      temp_cwms_ts_id_to        cwms_v_ts_id.cwms_ts_id%TYPE;
      temp_db_office_id_to      cwms_v_ts_id.db_Office_id%TYPE;
      temp_interval_id_to       cwms_v_ts_id.interval_id%TYPE;

      temp_unit_id              cwms_v_ts_id.unit_id%TYPE;

      interpolate_method        VARCHAR2 (1999) DEFAULT 'AVERAGE';
      run_yn                    VARCHAR2 (1) DEFAULT 'Y';


      temp_value_last           cwms_v_tsv.VALUE%TYPE;
      temp_date_time_last       cwms_v_tsv.date_time%TYPE;

      temp_value_avg            NUMBER;
      Loop_i                    NUMBER DEFAULT 1;

      quality_code_interp       NUMBER DEFAULT 3;
      num_points_needed         NUMBER;
   BEGIN
      --Get the selected store rule
      SELECT store_rule_id
        INTO temp_store_rule
        FROM cwms_store_rule
       WHERE store_rule_code = p_store_rule_code;

      --Get the destination units and db_office_id
      SELECT db_office_id,
             cwms_ts_id,
             unit_id,
             interval_id
        INTO temp_db_office_id_to,
             temp_cwms_ts_id_to,
             temp_unit_id,
             temp_interval_id_to
        FROM cwms_v_ts_id
       WHERE ts_code = p_ts_code_to;

      -- Get the source intervals
      SELECT db_office_id,
             cwms_ts_id,
             unit_id,
             interval_id
        INTO temp_db_office_id_from,
             temp_cwms_ts_id_from,
             temp_unit_id,
             temp_interval_id_from
        FROM cwms_v_ts_id
       WHERE ts_code = p_ts_code_from;


      CASE
         WHEN temp_interval_id_from = temp_interval_id_to
         THEN
            --Process normally, same number of data points per hour
            NULL;
         WHEN     temp_interval_id_from = '1Hour'
              AND temp_interval_id_to = '30Minutes'
         THEN
            --Data is 1Hour data and it should go to 30Minutes
            run_yn := 'Y';
            num_points_needed := 1;
         ELSE
            NULL;
      END CASE;


      --SELECT MIN(date_time), COUNT(value) FROM cwms_v_tsv WHERE ts_code = 6145017

      --SELECT MIN(date_time), COUNT(value) FROM cwms_v_tsv WHERE ts_code = 1054054

      --Initialize the arrays
      temp_value_array := cwms_t_tsv_array ();

      --from 6145017 to 1054054



      FOR x
         IN (  SELECT tsv.*,
                      tsi.unit_id,
                      tsi.db_office_id,
                      TO_DATE (tsv.date_time, 'DD-MON-YYYY HH24:MI')
                         date_time_date
                 FROM cwms_v_tsv tsv, cwms_v_ts_id tsi
                WHERE     tsv.ts_code = tsi.ts_code
                      AND tsv.ts_code = p_ts_code_from
                      AND tsv.date_time >= p_date_start
                      AND tsv.date_time < p_date_end
             ORDER BY date_Time ASC)
      LOOP
         IF temp_value_last IS NOT NULL AND temp_date_time_LAST IS NOT NULL
         THEN
            -- this is NOT the first record, so calculate the running average value
            IF TO_DATE (x.date_time, 'DD-MON-YYYY') + 1 / 24 =
                  TO_DATE (temp_date_time_last, 'DD-MON-YYYY')
            THEN
               --The loop is running in the correct direction and the records are continuou
               --  calculate the missing record BEHIND the current location
               temp_value_avg := temp_value_last + x.VALUE;

               CASE num_points_needed
                  WHEN 1
                  THEN
                     temp_value_avg := temp_value_avg / 2;
                     --Set the cwms_t_tsv type to the date/time
                     temp_Value :=
                        cwms_t_tsv (
                           TO_TIMESTAMP (x.date_time_date + .5 / 24),
                           temp_value_avg,
                           quality_code_interp  --DOUBLE CHECK WHAT TO DO HERE
                                              );
                     --Add the record to the array
                     temp_value_array.EXTEND ();
                     temp_value_array (temp_value_array.LAST) := temp_value;
                  --Build out with more case statements later
                  ELSE
                     NULL;
               END CASE;

               --Reset the loop and averages
               loop_i := 1;
               temp_value_avg := NULL;
            ELSE
               --Not on a Hourly Record, keep on adding to the running average
               temp_value_avg := temp_value_last + x.VALUE;
               loop_i := loop_i + 1;
            END IF;
         END IF;

         IF temp_value_last IS NULL OR temp_date_time_last IS NULL
         THEN
            --This is the first record OR the value is missing, don't do anything
            NULL;
         ELSE
            temp_value_last := x.VALUE;
            temp_date_time_last := x.date_time;
         END IF;



         --Set the cwms_t_tsv type to the date/time
         temp_Value := cwms_t_tsv (x.date_time, x.VALUE, x.quality_code);
         --Add the record to the array
         temp_value_array.EXTEND ();
         temp_value_array (temp_value_array.LAST) := temp_value;
      END LOOP;

      --Store TS Code
      cwms_ts.store_ts (p_cwms_ts_id        => temp_cwms_ts_id_to,
                        p_units             => temp_unit_id,
                        p_timeseries_data   => temp_value_array,
                        p_store_rule        => temp_store_rule,
                        p_override_prot     => 'F',
                        p_version_date      => cwms_util.non_versioned,
                        p_office_id         => temp_db_office_id_to);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := SQLERRM;
   END;

   PROCEDURE Deconstruct_ts_id (
      p_ts_code_from      IN     cwms_v_ts_id.ts_code%TYPE,
      p_interval_to       IN     cwms_v_ts_id.interval%TYPE,
      p_store_rule_code   IN     cwms_store_rule.store_rule_code%TYPE,
      p_interpolate_tf    IN     VARCHAR2 DEFAULT 'T',
      p_out                  OUT VARCHAR2        --,p_date_start       IN DATE
                                                 --,p_date_end         IN DATE
      )
   IS
      --This procedure will take a 15 or 30 minute TS and make it a 1Hour one

      temp_value             CWMS_T_TSV;
      temp_value_array       cwms_t_tsv_array;
      temp_store_rule        cwms_store_rule.store_Rule_id%TYPE;

      temp_cwms_ts_id_to     cwms_v_ts_id.cwms_ts_id%TYPE;
      temp_db_office_id_to   cwms_v_ts_id.db_Office_id%TYPE;

      temp_unit_id           cwms_v_ts_id.unit_id%TYPE;
   BEGIN
      --Get the selected store rule
      SELECT store_rule_id
        INTO temp_store_rule
        FROM cwms_store_Rule
       WHERE store_rule_code = p_store_rule_code;

      --Initialize the arrays
      temp_value_array := cwms_t_tsv_array ();


      FOR x
         IN (SELECT tsv.*, tsi.unit_id, tsi.db_office_id
               FROM cwms_v_tsv tsv, cwms_v_ts_id tsi
              WHERE     tsv.ts_code = tsi.ts_code
                    AND TO_CHAR (date_Time, 'MI') = '00'
                    AND tsv.ts_code = p_ts_code_from)
      LOOP
         --Set the cwms_t_tsv type to the date/time
         temp_Value := cwms_t_tsv (x.date_time, x.VALUE, x.quality_code);
         --Add the record to the array
         temp_value_array.EXTEND ();
         temp_value_array (temp_value_array.LAST) := temp_value;
      END LOOP;


      --Store TS Code
      cwms_ts.store_ts (p_cwms_ts_id        => temp_cwms_ts_id_to,
                        p_units             => temp_unit_id,
                        p_timeseries_data   => temp_value_array,
                        p_store_rule        => temp_store_rule,
                        p_override_prot     => 'F',
                        p_version_date      => cwms_util.non_versioned,
                        p_office_id         => temp_db_office_id_to);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := SQLERRM;
   END;



   /*PROCEDURE download_file(p_file IN cwms_documents_t.id%TYPE) IS

    v_mime         VARCHAR2(48);
    v_length       NUMBER;
    v_file_name    VARCHAR2(2000);
    Lob_loc        BLOB;

   BEGIN
           SELECT mime_type, blob_content, file_name,DBMS_LOB.GETLENGTH(blob_content)
             INTO v_mime,lob_loc,v_file_name,v_length
             FROM cwms_documents_t
            WHERE id = p_file;
                 --
                 -- set up HTTP header
                 --
               -- use an NVL around the mime type and
               -- if it is a null set it to application/octect
               -- application/octect may launch a download window from windows
               owa_util.mime_header( nvl(v_mime,'application/octet'), FALSE );

           -- set the size so the browser knows how much to download
           htp.p('Content-length: ' || v_length);
           -- the filename will be used by the browser if the users does a save as
           htp.p('Content-Disposition:  attachment; filename="'||replace(replace(substr(v_file_name,instr(v_file_name,'/')+1),chr(10),null),chr(13),null)|| '"');
           -- close the headers
           owa_util.http_header_close;
           -- download the BLOB
           wpg_docload.download_file( Lob_loc );

           UPDATE cwms_documents_t
              SET num_downloaded = num_downloaded + 1
            WHERE id = p_file;

     END;
     */
   PROCEDURE Clean_Loc_Metadata_by_xy (
      p_db_office_id             IN cwms_v_ts_id.db_office_id%TYPE,
      p_location_code            IN cwms_v_loc.location_code%TYPE DEFAULT NULL,
      p_overwrite_county_yn      IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_nation_id_yn   IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_near_city_yn   IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_state_yn       IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_tz_name_yn     IN VARCHAR2 DEFAULT c_app_logic_n)
   IS
      temp_time_zone_name   cwms_v_loc.time_zone_name%TYPE;
      temp_nation_id        cwms_v_loc.nation_id%TYPE;
      temp_nearest_city     cwms_v_loc.nearest_city%TYPE;
      temp_county_name      cwms_v_loc.county_name%TYPE;
      temp_state_initial    cwms_v_loc.state_initial%TYPE;
   BEGIN
      -- This procedure will set all the updatable metadata if a lat/lon is known
      NULL;


      FOR x
         IN (SELECT l.*
               FROM cwms_v_loc l
              WHERE     l.db_office_id = p_db_office_id
                    AND l.active_flag = c_cwms_logic_t
                    AND (l.latitude IS NOT NULL AND l.longitude IS NOT NULL)
                    AND CASE
                           WHEN p_location_code IS NULL THEN 1
                           ELSE p_location_code
                        END =
                           CASE
                              WHEN p_location_code IS NULL THEN 1
                              ELSE l.location_code
                           END)
      LOOP
         p_preload_squery_by_xy (p_lat              => x.latitude,
                                 p_lon              => x.longitude,
                                 p_county           => temp_county_name,
                                 p_nation_id        => temp_nation_id,
                                 p_nearest_city     => temp_nearest_city,
                                 p_state_initial    => temp_state_initial,
                                 p_time_zone_name   => temp_time_zone_name);

         IF     p_overwrite_county_yn = c_app_logic_y
            AND p_overwrite_nation_id_yn = c_app_logic_y
            AND p_overwrite_near_city_yn = c_app_logic_y
            AND p_overwrite_state_yn = c_app_logic_y
            AND p_overwrite_tz_name_yn = c_app_logic_y
         THEN
            cwms_loc.update_location2 (
               p_location_id     => x.location_id,
               p_county_name     => temp_county_name,
               p_state_initial   => temp_state_initial -- The API requires State if you update county
                                                      ,
               p_nation_id       => temp_nation_id,
               p_nearest_city    => temp_nearest_city,
               p_time_zone_id    => temp_time_zone_name);
         ELSE
            IF p_overwrite_county_yn = c_app_logic_y
            THEN
               cwms_loc.update_location2 (
                  p_location_id     => x.location_id,
                  p_county_name     => temp_county_name,
                  p_state_initial   => temp_state_initial -- The API requires State if you update county
                                                         );
            END IF;

            IF p_overwrite_nation_id_yn = c_app_logic_y
            THEN
               cwms_loc.update_location2 (p_location_id   => x.location_id,
                                          p_nation_id     => temp_nation_id);
            END IF;

            IF p_overwrite_near_city_yn = c_app_logic_y
            THEN
               cwms_loc.update_location2 (
                  p_location_id    => x.location_id,
                  p_nearest_city   => temp_nearest_city);
            END IF;


            IF p_overwrite_state_yn = c_app_logic_y
            THEN
               cwms_loc.update_location2 (
                  p_location_id     => x.location_id,
                  p_state_initial   => temp_state_initial);
            END IF;

            IF p_overwrite_tz_name_yn = c_app_logic_y
            THEN
               cwms_loc.update_location2 (
                  p_location_id    => x.location_id,
                  p_time_zone_id   => temp_time_zone_name);
            END IF;
         END IF;
      /*

                       cwms_loc.update_location2(p_location_id => x.location_id
                                                ,p_county_name => CASE
                                                                   WHEN p_overwrite_county_yn = c_app_Logic_y THEN
                                                                       temp_county_name
                                                                   ELSE
                                                                    NULL
                                                                  END

                                                ,p_nation_id => CASE
                                                                   WHEN p_overwrite_nation_id_yn = c_app_Logic_y THEN
                                                                       temp_natioN_id
                                                                   ELSE
                                                                    NULL
                                                                  END
                                                ,p_nearest_city => CASE
                                                                   WHEN p_overwrite_near_city_yn = c_app_Logic_y THEN
                                                                       temp_nearest_city
                                                                   ELSE
                                                                    NULL
                                                                  END
                                                ,p_state_initial => CASE
                                                                   WHEN p_overwrite_state_yn = c_app_Logic_y THEN
                                                                       temp_state_initial
                                                                   ELSE
                                                                    NULL
                                                                  END
                                                ,p_time_zone_id => CASE
                                                                   WHEN p_overwrite_tz_name = c_app_Logic_y THEN
                                                                       temp_time_zone_name
                                                                   ELSE
                                                                    NULL
                                                                  END

                                                );
      */

      END LOOP;
   END;


   PROCEDURE Load_csv_collection_to_DB (
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_store_rule_code   IN cwms_store_rule.store_rule_code%TYPE)
   IS
      temp_value          CWMS_T_TSV;
      temp_value_array    cwms_t_tsv_array;
      i                   NUMBER DEFAULT 0;
      temp_cwms_ts_id     cwms_v_ts_id.cwms_ts_id%TYPE;
      temp_unit_id        cwms_v_ts_id.unit_id%TYPE;
      temp_db_office_id   cwms_v_ts_id.db_office_id%TYPE;
      temp_store_rule     cwms_store_rule.store_rule_id%TYPE;
   BEGIN
      --Get the selected store rule
      SELECT store_rule_id
        INTO temp_store_rule
        FROM cwms_store_rule
       WHERE store_Rule_code = p_store_rule_code;

      --Initialize the arrays
      temp_value_array := cwms_t_tsv_array ();

      FOR x IN (SELECT *
                  FROM apex_collections
                 WHERE collection_name = p_collection_name)
      LOOP
         --Set the cwms_t_tsv type to the date/time
         temp_Value :=
            cwms_t_tsv (TO_TIMESTAMP (x.d001), TO_BINARY_DOUBLE (x.n002), 3);
         --Add the record to the array
         temp_value_array.EXTEND ();
         temp_value_array (temp_value_array.LAST) := temp_value;

         BEGIN
            --Get the cwms Ts ID if it doesn't exist
            IF    temp_cwms_ts_id IS NULL
               OR temp_unit_id IS NULL
               OR temp_db_office_id IS NULL
            THEN
               SELECT cwms_ts_id, unit_id, db_office_id
                 INTO temp_cwms_ts_id, temp_unit_id, temp_db_office_id
                 FROM cwms_v_ts_id
                WHERE ts_code = x.n001;
            END IF;


            --Update the APEX Collection Member to tell the user is processed
            APEX_COLLECTION.UPDATE_MEMBER (
               p_collection_name   => p_collection_name,
               p_seq               => x.seq_id,
               p_C001              => x.C001,
               p_C002              => x.C002,
               p_C003              => x.C003,
               p_c004              => x.C004,
               p_c005              => x.c005,
               p_N001              => x.N001,
               p_N002              => x.N002,
               p_D001              => x.D001,
               p_c011              => 'Successfully added to array ',
               p_c010              => temp_cwms_ts_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               --Update the APEX Collection Member to tell the user if there were any issues
               APEX_COLLECTION.UPDATE_MEMBER (
                  p_collection_name   => p_collection_name,
                  p_seq               => x.seq_id,
                  p_C001              => x.C001,
                  p_C002              => x.C002,
                  p_C003              => x.C003,
                  p_c004              => x.C004,
                  p_c005              => x.c005,
                  p_N001              => x.N001,
                  p_N002              => x.N002,
                  p_D001              => x.D001,
                  p_c011              => SQLERRM,
                  p_C010              => temp_cwms_ts_id);
         END;
      END LOOP;

      --Store the TS Value
      cwms_ts.store_ts (p_cwms_ts_id        => temp_cwms_ts_id,
                        p_units             => temp_unit_id,
                        p_timeseries_data   => temp_value_array,
                        p_store_rule        => temp_store_rule,
                        p_override_prot     => 'F',
                        p_version_date      => cwms_util.non_versioned,
                        p_office_id         => temp_db_office_id);
   END;

   PROCEDURE load_application_constants (
      p_app_logic_yes                 OUT VARCHAR2,
      p_app_logic_no                  OUT VARCHAR2,
      p_app_Page_title_prefix         OUT VARCHAR2,
      p_app_save_text                 OUT VARCHAR2,
      p_app_cancel_text               OUT VARCHAR2,
      p_app_page_15_Instructions      OUT VARCHAR2,
      p_app_logic_html5_date_mask     OUT VARCHAR2,
      p_app_db_office_id_cwms         OUT VARCHAR2,
      p_app_usr_dflt_scope_choice     OUT VARCHAR2,
      p_app_search_goto_loc_icon      OUT VARCHAR2,
      p_app_ts_store_rule_id_dflt     OUT VARCHAR2 --cwms_ts_store_rule_l.id%TYPE
                                                  ,
      p_app_null_lookup_temp_text     OUT VARCHAR2 --=> :APP_NULL_LOOKUP_TEMP_TEXT
                                                  ,
      p_app_NW_UR_base_loc_ts_id_tf   OUT VARCHAR2)
   IS
   BEGIN
      p_app_LOGIC_YES := c_cwms_logic_t;
      p_app_LOGIC_NO := c_cwms_logic_f;
      p_app_PAGE_TITLE_PREFIX := 'CMA - NEW ';
      p_app_SAVE_TEXT := 'Save';
      p_app_CANCEL_TEXT := 'Cancel';
      p_app_PAGE_15_INSTRUCTIONS :=
         'Follow the Region Titles for Instructions to upload eGIS Metadata <BR>';
      p_app_LOGIC_HTML5_DATE_MASK := 'YYYY-MM-DD';
      p_app_DB_OFFICE_ID_CWMS := 'CWMS';
      p_app_usr_dflt_scope_choice := 'BY_CHECKS';
      p_app_search_goto_loc_icon :=
         '<img src="#WORKSPACE_IMAGES#Go-16.png" title="Goto Loc" alt="Today">';
      p_app_null_lookup_temp_text := c_temp_null_case;            -- 'Hi Art';
      p_app_NW_UR_base_loc_ts_id_tf := c_cwms_logic_t;


      p_app_ts_store_rule_id_dflt := 1;
   /*    SELECT TO_CHAR(MIN(store_rule_code))
         INTO p_app_ts_store_rule_id_dflt
         FROM cwms_store_rule
        WHERE use_as_default = c_cwms_logic_t;
   */


   END;


   PROCEDURE load_store_rule (
      p_id              IN cwms_store_rule.store_rule_code%TYPE,
      p_default_tf      IN cwms_store_rule.use_as_default%TYPE, --cwms_ts_store_rule_l.default_tf%TYPE ,
      p_description     IN cwms_store_rule.description%TYPE,
      p_display_value   IN cwms_store_rule.store_rule_id%TYPE,
      p_sort_order      IN AT_STORE_RULE_ORDER.sort_order%TYPE)
   IS
   BEGIN
      UPDATE cwms_store_rule
         SET store_rule_id = p_description, use_as_default = p_default_tf
       --        , sort_order     = p_sort_order
       WHERE store_rule_code = store_rule_code;

      NULL;
   END;

   PROCEDURE load_tsc_parallel (
      p_ts_code_left          IN cwms_v_ts_id.ts_code%TYPE,
      p_ts_code_right         IN cwms_v_ts_id.ts_code%TYPE,
      p_new_collection_name   IN VARCHAR2 DEFAULT 'TS_PARALLEL_COMPARE')
   IS
      temp_date_end              DATE; -- DEFAULT TO_DATE(SYSDATE, 'DD-MON-YYYY') - 1;
      temp_date_begin            DATE;          -- DEFAULT temp_date_end - 30;
      num_days                   NUMBER DEFAULT 15;

      temp_intervals_per_day     NUMBER;
      temp_intervals_per_day_r   NUMBER;
      temp_intervals_per_day_l   NUMBER;
      temp_intervals_for_range   NUMBER; --number of intervals times number of days

      temp_increment_minutes_r   NUMBER;
      temp_increment_minutes_l   NUMBER;

      temp_increment_minutes     NUMBER; --this is the number of minutes to increment (i.e. 15 minutes = 15, 1Hour = 60)


      temp_row_date_time         DATE; --DEFAULT temp_date_begin;       --this is the calculated datetime value that the two TS Codes will be compared against. It
      --starts ath temp_date_begin
      l_seq                      NUMBER; --sequence number when adding to a collection

      temp_seq_id                NUMBER;               --temp_seq_id IN a loop
   BEGIN
      temp_date_end := SYSDATE;
      temp_date_begin := SYSDATE - num_days;
      temp_date_begin :=
         TO_DATE (TO_CHAR (temp_date_begin, 'DD-MON-YYYY'), 'DD-MON-YYYY');
      temp_row_date_time := temp_date_begin;

      --Determine the intervals
      NULL;


      FOR x IN (SELECT tsi.*, 'LEFT' parallel_loc
                  FROM cwms_v_ts_id tsi
                 WHERE ts_code = p_ts_code_left
                UNION ALL
                SELECT tsi.*, 'RIGHT' parallel_loc
                  FROM cwms_v_ts_id tsi
                 WHERE ts_code = p_ts_code_right)
      LOOP
         IF x.parallel_loc = 'LEFT'
         THEN
            CASE x.interval_id
               WHEN '1Hour'
               THEN
                  temp_intervals_per_day_l := 24;
                  temp_increment_minutes_l := 60;
               WHEN '15Minutes'
               THEN
                  temp_intervals_per_day_l := 4 * 24;
                  temp_increment_minutes_l := 15;
               ELSE
                  NULL;
            END CASE;
         END IF;

         IF x.parallel_loc = 'RIGHT'
         THEN
            CASE x.interval_id
               WHEN '1Hour'
               THEN
                  temp_intervals_per_day_r := 24;
                  temp_increment_minutes_r := 60;
               WHEN '15Minutes'
               THEN
                  temp_intervals_per_day_r := 4 * 24;
                  temp_increment_minutes_r := 15;
               ELSE
                  NULL;
            END CASE;
         END IF;
      END LOOP;


      FOR x
         IN (SELECT MAX (intervals) max_intervals,
                    MIN (increments) min_increments
               FROM (SELECT temp_intervals_per_day_r intervals,
                            temp_increment_minutes_r increments
                       FROM DUAL
                     UNION ALL
                     SELECT temp_intervals_per_day_l intervals,
                            temp_increment_minutes_l increments
                       FROM DUAL))
      LOOP
         temp_intervals_Per_day := x.max_intervals;
         temp_increment_minutes := x.min_increments;
      END LOOP;

      -- Get the number of intervals to add to the collection by multiplying the number of days by the num/intervals/day
      temp_intervals_for_range := temp_intervals_per_day * num_days;



      --Create the collection
      apex_collection.create_or_truncate_collection (
         p_collection_name => p_new_collection_name);

      --Using the intervals, make a for loop populate all the records in a collection needed to
      FOR looP_counter IN 1 .. temp_intervals_for_range
      LOOP
         l_seq :=
            apex_collection.add_member (
               p_collection_name   => p_new_collection_name,
               p_c010              => 'Loading Collection',
               p_d001              => temp_row_date_time);

         temp_row_date_time :=
            temp_row_date_time + (temp_increment_minutes / (24 * 60));
      END LOOP;


      --Populate the collection with the data from the left ts code
      /*
      FOR x IN ( SELECT TO_NUMBER(tsv.value) value
                      , date_time
                   FROM cwms_v_tsv tsv
                  WHERE tsv.ts_code        = p_ts_code_left
                    AND (tsv.date_time    >= temp_date_begin AND tsv.date_time <= temp_date_end)
               ) LOOP

                    FOR y IN (SELECT *
                                FROM apex_collections
                               WHERE collection_name = p_new_collection_name
                               ORDER BY d001
                             ) LOOP
                                 IF x.date_time = y.d001 THEN
                                  temp_seq_id := y.seq_id;

                                    apex_collection.update_member_attribute(p_collection_name => p_new_collection_name
                                                                           ,p_seq             => temp_seq_id
                                                                           ,p_attr_number     => 1
                                                                           ,p_number_value      => x.value
                                                                           );





                                 END IF;

                               END LOOP;



                 END LOOP;
      */
      FOR x
         IN (SELECT ROUND (TO_NUMBER (tsv.VALUE), 6) VALUE,
                    tsv.date_time,
                    ac.seq_id
               FROM (SELECT *
                       FROM cwms_v_tsv
                      WHERE     ts_code = p_ts_code_left
                            AND (    date_time >= temp_date_begin
                                 AND date_time <= temp_date_end)) tsv,
                    (SELECT *
                       FROM apex_collections
                      WHERE collection_name = p_new_collection_name) ac
              WHERE tsv.date_time = ac.d001)
      LOOP
         apex_collection.update_member_attribute (
            p_collection_name   => p_new_collection_name,
            p_seq               => x.seq_id,
            p_attr_number       => 1,
            p_number_value      => x.VALUE);
      END LOOP;



      FOR x
         IN (SELECT ROUND (TO_NUMBER (tsv.VALUE), 8) VALUE,
                    tsv.date_time,
                    ac.seq_id
               FROM (SELECT *
                       FROM cwms_v_tsv
                      WHERE     ts_code = p_ts_code_right
                            AND (    date_time >= temp_date_begin
                                 AND date_time <= temp_date_end)) tsv,
                    (SELECT *
                       FROM apex_collections
                      WHERE collection_name = p_new_collection_name) ac
              WHERE tsv.date_time = ac.d001)
      LOOP
         apex_collection.update_member_attribute (
            p_collection_name   => p_new_collection_name,
            p_seq               => x.seq_id,
            p_attr_number       => 2,
            p_number_value      => x.VALUE);
      END LOOP;



      --Actually compare

      FOR x IN (SELECT *
                  FROM apex_collections
                 WHERE collection_name = p_new_collection_name)
      LOOP
         CASE
            WHEN x.n001 IS NULL AND x.n002 IS NULL
            THEN
               apex_collection.update_member_attribute (
                  p_collection_name   => p_new_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'No data');
            WHEN x.n001 = x.n002
            THEN
               apex_collection.update_member_attribute (
                  p_collection_name   => p_new_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'Match');
            WHEN x.n001 <> x.n002
            THEN
               apex_collection.update_member_attribute (
                  p_collection_name   => p_new_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'Values Do not match');
            WHEN x.n001 IS NULL AND x.n002 IS NOT NULL
            THEN
               apex_collection.update_member_attribute (
                  p_collection_name   => p_new_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'Left Side is NULL');
            WHEN x.n002 IS NULL AND x.n001 IS NOT NULL
            THEN
               apex_collection.update_member_attribute (
                  p_collection_name   => p_new_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'Right Side is NULL');
            ELSE
               apex_collection.update_member_attribute (
                  p_collection_name   => p_new_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'Other CASE');
         END CASE;
      END LOOP;



      --SELECT * FROM cwms_v_tsv WHERE ts_code = 374043 AND date_time = TO_DATE('10-SEP-2013 09:30', 'DD-MON-YYYY HH24:MI');

      NULL;
   END;

   PROCEDURE parse_tsv_csv (p_clob                   CLOB,
                            p_collection_name        VARCHAR2,
                            p_delim                  VARCHAR2 DEFAULT ',',
                            p_optionally_enclosed    VARCHAR2 DEFAULT '"',
                            p_all_one_ts_id_tf       VARCHAR2 DEFAULT 'T'
                            
                            )
   IS
      --
      CARRIAGE_RETURN   CONSTANT CHAR (1) := CHR (13);
      LINE_FEED         CONSTANT CHAR (1) := CHR (10);
      --
      l_char                     CHAR (1);
      l_lookahead                CHAR (1);
      l_pos                      NUMBER := 0;
      l_token                    VARCHAR2 (32767) := NULL;
      l_token_complete           BOOLEAN := FALSE;
      l_line_complete            BOOLEAN := FALSE;
      l_new_token                BOOLEAN := TRUE;
      l_enclosed                 BOOLEAN := FALSE;
      --
      l_lineno                   NUMBER := 1;
      l_columnno                 NUMBER := 1;


      --temp_collection_name  cwms_collections.Collection_name%TYPE;

      temp_value                 NUMBER;
      temp_unit_id               VARCHAR2 (1999);
      temp_date_time             DATE;
      temp_date_time_char        VARCHAR2 (1999);
      temp_cwms_ts_id            cwms_v_ts_id.cwms_ts_id%TYPE;
      temp_ts_code               cwms_v_ts_id.ts_code%TYPE;
      temp_db_office_id          cwms_v_ts_id.db_office_id%TYPE;


      temp_str_ts_code           VARCHAR2 (7) DEFAULT 'TS_CODE';
      temp_str_ts_id             VARCHAR2 (10) DEFAULT 'CWMS_TS_ID';
      Ts_code_or_ts_id           VARCHAR2 (10);
   BEGIN
      LOOP
         -- increment position index
         l_pos := l_pos + 1;

         -- get next character from clob
         l_char := DBMS_LOB.SUBSTR (p_clob, 1, l_pos);

         -- exit when no more characters to process
         EXIT WHEN l_char IS NULL OR l_pos > DBMS_LOB.getLength (p_clob);

         -- if first character of new token is optionally enclosed character
         -- note that and skip it and get next character
         IF l_new_token AND l_char = p_optionally_enclosed
         THEN
            l_enclosed := TRUE;
            l_pos := l_pos + 1;
            l_char := DBMS_LOB.SUBSTR (p_clob, 1, l_pos);
         END IF;

         l_new_token := FALSE;

         -- get look ahead character
         l_lookahead := DBMS_LOB.SUBSTR (p_clob, 1, l_pos + 1);

         -- inspect character (and lookahead) to determine what to do
         IF l_char = p_optionally_enclosed AND l_enclosed
         THEN
            IF l_lookahead = p_optionally_enclosed
            THEN
               l_pos := l_pos + 1;
               l_token := l_token || l_lookahead;
            ELSIF l_lookahead = p_delim
            THEN
               l_pos := l_pos + 1;
               l_token_complete := TRUE;
            END IF;
         ELSIF l_char IN (CARRIAGE_RETURN, LINE_FEED) AND NOT l_enclosed
         THEN
            l_token_complete := TRUE;
            l_line_complete := TRUE;

            IF l_lookahead IN (CARRIAGE_RETURN, LINE_FEED)
            THEN
               l_pos := l_pos + 1;
            END IF;
         ELSIF l_char = p_delim AND NOT l_enclosed
         THEN
            l_token_complete := TRUE;
         ELSIF l_pos = DBMS_LOB.getLength (p_clob)
         THEN
            l_token := l_token || l_char;
            l_token_complete := TRUE;
            l_line_complete := TRUE;
         ELSE
            l_token := l_token || l_char;
         END IF;

         -- process a new token
         IF l_token_complete
         THEN
            --Do something HERE if needing stuff by column AND row
            --Skip the first line
            IF l_lineno = 1
            THEN
               CASE l_columnno
                  WHEN 1
                  THEN
                     CASE NVL (l_token, '**null**')
                        WHEN temp_str_ts_id
                        THEN
                           ts_code_or_ts_id := temp_str_ts_id;
                        WHEN temp_str_ts_code
                        THEN
                           ts_code_or_ts_id := temp_str_ts_code;
                        ELSE
                           NULL;
                     END CASE;
                  ELSE
                     NULL;
               END CASE;
            ELSE
               CASE l_columnno
                  WHEN 1
                  THEN
                     CASE ts_code_or_ts_id
                        WHEN temp_str_ts_id
                        THEN
                           temp_cwms_ts_id := NVL (l_token, '**null**');
                        WHEN temp_str_ts_code
                        THEN
                           temp_ts_code :=
                              TO_NUMBER (NVL (l_token, '**null**'));
                        ELSE
                           NULL;
                     END CASE;
                  --WHEN 2 THEN temp_date_time    :=  nvl(l_token,'**null**') ;

                  WHEN 2
                  THEN
                     temp_date_time_char :=
                        NVL (UPPER (TRIM (l_token)), '**null**');


                     temp_date_time :=
                        TO_DATE (NVL (UPPER (l_token), '**null**'),
                                 'DD/MON/YYYY HH24:MI');

                     IF EXTRACT (YEAR FROM temp_date_time) <= 1925
                     THEN
                        -- something is prob. wrong
                        temp_date_time := NULL;
                     END IF;
                  WHEN 3
                  THEN
                     temp_value := TO_NUMBER (NVL (l_token, '**null**'));
                  WHEN 4
                  THEN
                     temp_unit_id := NVL (l_token, '**null**');
                  WHEN 5
                  THEN
                     temp_db_office_id := NVL (l_token, '**null**');
                  ELSE
                     NULL;
               END CASE;
            END IF;


            --dbms_output.put_line( 'R' || l_lineno || 'C' || l_columnno || ': ' ||
            --                            nvl(l_token,'**null**') );

            l_columnno := l_columnno + 1;
            l_token := NULL;
            l_enclosed := FALSE;
            l_new_token := TRUE;
            l_token_complete := FALSE;
         END IF;

         -- process end-of-line here
         IF l_line_complete
         THEN
            IF l_lineno = 1
            THEN
               --Do nothing as this is the first line
            
               NULL;
            ELSE
               IF ts_code_or_ts_id = temp_str_ts_code
               THEN
                  IF temp_cwms_ts_id IS NULL  OR p_all_one_ts_id_tf  ='F' THEN

                  SELECT cwms_ts_id
                    INTO temp_cwms_ts_id
                    FROM cwms_v_ts_id
                   WHERE ts_code      = temp_ts_code
                     AND db_office_id = temp_db_office_id;
                         
                  END IF;
                         
               END IF;

               IF ts_code_or_ts_id = temp_str_ts_id
               THEN
                 IF temp_ts_code IS NULL OR p_all_one_ts_id_tf  ='F' THEN
                  SELECT ts_code
                    INTO temp_ts_code
                    FROM cwms_v_ts_id
                   WHERE cwms_ts_id   = temp_cwms_ts_id
                     AND db_office_id = temp_db_office_id;
                 END IF;
               END IF;



               APEX_COLLECTION.ADD_MEMBER (
                  p_collection_name   => p_collection_name --   ,p_blob001         => temp_blob
                                                          ,
                  p_c001              => CASE ts_code_or_ts_id
                                           WHEN temp_str_ts_code
                                           THEN
                                              TO_CHAR (temp_ts_code)
                                           ELSE
                                              temp_cwms_ts_id
                                        END,
                  p_c002              => temp_date_time_char,
                  p_c003              => TO_CHAR (temp_value),
                  p_c004              => temp_unit_id,
                  p_c005              => temp_db_office_id,
                  p_c010              => temp_cwms_ts_id,
                  p_d001              => temp_date_time --TO_DATE('02-AUG-2013 10:00', 'DD-MON-YYYY HH24:MI')
                                                       ,
                  p_n001              => temp_ts_code        --123456 --tscode
                                                     ,
                  p_n002              => temp_value                --1 --value
                                                   );


               NULL;
            END IF;

            DBMS_OUTPUT.put_line ('-----');
            l_lineno := l_lineno + 1;
            l_columnno := 1;
            l_line_complete := FALSE;
         END IF;
      END LOOP;
   END;


   PROCEDURE preload_store_rule_editor (
      p_store_Rule_code   IN     cwms_store_rule.store_rule_code%TYPE,
      p_use_as_default       OUT cwms_store_rule.use_as_default%TYPE, --cwms_ts_store_rule_l.default_tf%TYPE ,
      p_description          OUT cwms_store_rule.description%TYPE,
      p_store_rule_id        OUT cwms_store_rule.store_rule_id%TYPE,
      p_sort_order           OUT AT_STORE_RULE_ORDER.sort_order%TYPE)
   IS
   BEGIN
      SELECT description, use_as_default, store_rule_id
        --        , sort_order
        INTO p_description, p_use_as_default, p_store_rule_id
        --        , p_sort_order
        FROM cwms_store_rule
       WHERE store_rule_code = p_store_Rule_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END;

   PROCEDURE preload_Upload_tsv (
      p_store_rule_code IN OUT cwms_store_rule.store_Rule_code%TYPE)
   IS
   BEGIN
      --Get the default store rule by CMA installation

      BEGIN
         IF p_store_Rule_code IS NULL
         THEN
            SELECT MIN (store_rule_code)
              INTO p_store_rule_code
              FROM cwms_store_rule
             WHERE use_as_default = 'T';
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT MIN (store_rule_code)
              INTO p_store_rule_code
              FROM cwms_store_rule;
      END;
   END;

   PROCEDURE p_clean_location_type (
      p_db_office_id        IN cwms_v_loc.db_Office_id%TYPE,
      p_location_type_old   IN cwms_v_loc.location_type%TYPE,
      p_location_type_new   IN cwms_v_loc.location_type%TYPE)
   IS
   BEGIN
      --this procedure will update a location's location type

      FOR x
         IN (  SELECT *
                 FROM cwms_v_loc
                WHERE     unit_system = 'EN'
                      AND db_Office_id = p_db_office_id
                      AND locatioN_type = p_locatioN_type_old
             ORDER BY locatioN_id ASC)
      LOOP
         cwms_Loc.store_location (p_location_id        => x.locatioN_id -- IN VARCHAR2,
                                , p_location_type      => p_locatioN_type_new -- IN VARCHAR2 DEFAULT NULL,
                                , p_elevation          => x.elevation --    IN NUMBER DEFAULT NULL,
                                , p_elev_unit_id       => x.unit_id --   IN VARCHAR2 DEFAULT NULL,
                                , p_vertical_datum     => x.vertical_datum -- IN VARCHAR2 DEFAULT NULL,
                                , p_latitude           => x.latitude --  IN NUMBER DEFAULT NULL,
                                , p_longitude          => x.longitude --    IN NUMBER DEFAULT NULL,
                                , p_horizontal_datum   => x.horizontal_datum --IN VARCHAR2 DEFAULT NULL,
                                , p_public_name        => x.public_Name -- IN VARCHAR2 DEFAULT NULL,
                                , p_long_name          => x.long_name --   IN VARCHAR2 DEFAULT NULL,
                                , p_description        => x.description -- IN VARCHAR2 DEFAULT NULL,
                                , p_time_zone_id       => x.time_zone_name --  IN VARCHAR2 DEFAULT NULL,
                                , p_county_name        => x.county_name -- IN VARCHAR2 DEFAULT NULL,
                                , p_state_initial      => x.state_initial --x.IN VARCHAR2 DEFAULT NULL,
                                , p_active             => x.loc_active_flag --   IN VARCHAR2 DEFAULT NULL,
                                , p_ignorenulls        => 'T' --x.IN VARCHAR2 DEFAULT 'T',
                                , p_db_office_id       => x.db_office_id -- IN VARCHAR2 DEFAULT NULL
                                  );
      END LOOP;
   END;

--   PROCEDURE p_delete_lockage (
--      p_lockage_code IN Cwms_v_lockage.lockage_code%TYPE)
--   IS
--   BEGIN
--      DELETE at_lockage
--       WHERE lockage_code = p_lockage_code;
--
--      NULL;
--   END;


   PROCEDURE p_clear_a2w_ts_code (p_ts_code IN cwms_v_ts_id.ts_code%TYPE) IS
   BEGIN
    NULL;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_elev = NULL
     WHERE ts_code_elev = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_stage = NULL
     WHERE ts_code_stage = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_precip = NULL
     WHERE ts_code_precip = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_inflow = NULL
     WHERE ts_code_inflow = p_ts_code;

   UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_outflow = NULL
     WHERE ts_code_outflow = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_sur_release = NULL
     WHERE ts_code_sur_release = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_stor_drought = NULL
     WHERE ts_code_stor_drought = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_stor_flood = NULL
     WHERE ts_code_stor_flood = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_elev_Tw = NULL
     WHERE ts_code_elev_Tw = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_stage_tw = NULL
     WHERE ts_code_stage_tw = p_ts_code;

    UPDATE at_a2w_ts_codes_by_loc
       SET ts_code_rule_curve_elev = NULL
     WHERE ts_code_rule_curve_elev = p_ts_code;

    UPDATE at_a2w_ts_codes_By_loc
       SET ts_code_power_Gen    = NULL
     WHERE ts_code_power_Gen    = p_ts_code;
    
    UPDATE at_a2w_ts_codes_By_loc
       SET ts_code_temp_air    = NULL
     WHERE ts_code_temp_air    = p_ts_code;

    UPDATE at_a2w_ts_codes_By_loc
       SET ts_code_temp_water    = NULL
     WHERE ts_code_temp_water    = p_ts_code;

    UPDATE at_a2w_ts_codes_By_loc
       SET ts_code_do    = NULL
     WHERE ts_code_do    = p_ts_code;
        
      FOR x IN (SELECT DISTINCT location_code, db_Office_id
                  FROM cwms_v_ts_id
                WHERE ts_code = p_ts_code
                ) LOOP

      p_set_a2w_num_tsids (
                            p_db_Office_id    => x.db_office_id,
                            p_locatioN_code   => x.locatioN_code ,
                            p_user_id         => 'SYSTEM'
                          );
                  END LOOP;

  END ; --p_clear_a2w_ts_code


   PROCEDURE p_refresh_a2w_ts_codes (
      p_db_office_id    IN at_a2w_ts_codes_by_loc.db_office_id%TYPE,
      p_location_code   IN at_a2w_ts_codes_by_loc.location_code%TYPE DEFAULT NULL)
   IS
      fire_update_yn            VARCHAR2 (1) DEFAULT 'Y';
      fire_i                    NUMBER DEFAULT 0;          --number of updates
      loop_i_no_data            NUMBER DEFAULT 0;           --Loop for no data
      loop_i_old_data           NUMBER DEFAULT 0;         -- Loop for old data

      tsc_elev                  cwms_v_ts_id.ts_code%TYPE;
      tsc_stage                 cwms_v_ts_id.ts_code%TYPE;
      tsc_precip                cwms_v_ts_id.ts_code%TYPE;
      tsc_inflow                cwms_v_ts_id.ts_code%TYPE;
      tsc_outflow               cwms_v_ts_id.ts_code%TYPE;
      tsc_stor_flood            cwms_v_ts_id.ts_code%TYPE;
      tsc_stor_drought          cwms_v_ts_id.ts_code%TYPE;

      temp_notes                CLOB;
      temp_delim                VARCHAR2 (25) DEFAULT CHR (13);
      temp_num_days_countback   NUMBER DEFAULT 15;
      temp_num_ts_codes         NUMBER DEFAULT 0;
   BEGIN
      --This procedure will refresh ts_codes used to display in A2W
      -- It will check for the most up to date TS Codes and give priority to revised TS IDs

      NULL;

      /*
      DELETE temp_a2w_ts_codes_by_loc
       WHERE db_Office_id IN (SELECT db_office_id
                                FROM cwms_v_ts_id
                               WHERE db_office_id = p_db_Office_id
                                 AND net_ts_active_Flag = 'F'
                             )
         AND locatioN_id IN (SELECT locatioN_id
                                FROM cwms_v_ts_id
                               WHERE db_office_id = p_db_Office_id
                                 AND net_ts_active_Flag = 'F'
                             )


      MERGE INTO temp_a2w_ts_codes_by_loc a2w
       USING (SELECT DISTINCT db_office_id, location_id, SYSDATE
                 FROM cwms_v_ts_id
                WHERE db_office_id = 'LRP'
                  AND net_ts_active_flag = 'T'
                ORDER BY db_office_id, location_id
             ) tsi
          ON (a2w.db_office_id = tsi.db_office_id
               AND
              a2w.location_id  = tsi.location_id
             )
       WHEN MATCHED THEN
      */

      -- SELECT * FROM a2w_ts_codes_by_loc WHERE db_Office_id = 'LRB'
/*
      DELETE at_a2w_ts_codes_by_loc
       WHERE     CASE
                    WHEN p_db_office_id IS NULL THEN c_temp_null_case
                    ELSE p_db_Office_id
                 END =
                    CASE
                       WHEN p_db_office_id IS NULL THEN c_temp_null_case
                       ELSE db_Office_id
                    END
             AND CASE
                    WHEN p_locatioN_code IS NULL THEN 1
                    ELSE p_location_code
                 END =
                    CASE
                       WHEN p_locatioN_code IS NULL THEN 1
                       ELSE location_code
                    END;



      INSERT INTO at_a2w_ts_codes_by_loc (db_office_id,
                                          location_code,
                                          date_refreshed)
           SELECT DISTINCT db_office_id, location_id, SYSDATE
             FROM cwms_v_ts_id
            WHERE     CASE
                         WHEN p_db_office_id IS NULL THEN c_temp_null_case
                         ELSE p_db_Office_id
                      END =
                         CASE
                            WHEN p_db_office_id IS NULL THEN c_temp_null_case
                            ELSE db_Office_id
                         END
                  AND CASE
                         WHEN p_locatioN_code IS NULL THEN 1
                         ELSE p_locatioN_code
                      END =
                         CASE
                            WHEN p_locatioN_code IS NULL THEN 1
                            ELSE location_code
                         END
                  AND net_ts_active_flag = c_cwms_logic_t
                  AND base_parameter_id IN
                         ('Elev', 'Stage', 'Flow', 'Precip', 'Stor')
                  AND LENGTH (base_locatioN_id) > 1
                  AND INSTR (locatioN_id, '-RAWS') = 0 --LRP stores their raw data in a seperate container of sublocations?
         --         AND SUBSTR(base_LocatioN_id,1,1) IN ('A','B','C')
         --         AND SUBSTR(base_locatioN_id,1,1) IN ('U')
         ORDER BY db_office_id, location_id;



      FOR x
         IN (  SELECT *
                 FROM at_a2w_ts_codes_by_loc
                WHERE     db_office_id = p_db_office_id
                      AND CASE
                             WHEN p_locatioN_code IS NULL THEN 1
                             ELSE p_locatioN_code
                          END =
                             CASE
                                WHEN p_locatioN_code IS NULL THEN 1
                                ELSE location_code
                             END
             ORDER BY db_Office_id, locatioN_code)
      LOOP
         --Find the elevation TS COde

         FOR y IN (  SELECT tsi.*, ROWNUM row_num
                       FROM (  SELECT tsi.db_office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id) version_id,
                                      MAX (tsv.date_time) max_date_time,
                                      1 SQL_LEVEL
                                 FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                                WHERE     tsi.ts_code = tsv.ts_code
                                      AND tsi.db_office_id = x.db_Office_id
                                      AND tsi.location_code = x.locatioN_code
                                      AND tsi.net_ts_active_flag = c_cwms_logic_t
                                      AND TSI.base_parameter_id = c_str_elev
                                      AND (   UPPER (tsi.versioN_id) IN
                                                 ('OBS', 'REV', 'DCP-REV')
                                           OR INSTR (UPPER (tsi.version_id),
                                                     '-REV') > 0
                                           OR INSTR (UPPER (tsi.version_id),
                                                     'DECODES') > 0)
                                      AND INSTR (UPPER (cwms_ts_id), 'FORECAST') =
                                             0
                                      AND INSTR (parameter_id, '-PZ') = 0 --NAE has a lot of PZ elevations
                             GROUP BY tsi.db_Office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id)
                             UNION ALL
                               SELECT tsi.db_office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id) version_id,
                                      MAX (tsv.date_time) max_date_time,
                                      2 SQL_LEVEL
                                 FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                                WHERE     tsi.ts_code = tsv.ts_code
                                      AND tsi.db_office_id = x.db_Office_id
                                      AND tsi.location_code = x.locatioN_code
                                      AND tsi.net_ts_active_flag = c_cwms_logic_t
                                      AND TSI.base_parameter_id = c_str_elev
                                      AND (    UPPER (tsi.versioN_id) NOT IN
                                                  ('OBS', 'REV', 'DCP-REV')
                                           AND INSTR (UPPER (tsi.version_id),
                                                      '-REV') = 0
                                           AND INSTR (UPPER (tsi.version_id),
                                                      'DECODES') = 0)
                                      AND INSTR (UPPER (cwms_ts_id), 'FORECAST') =
                                             0
                             GROUP BY tsi.db_Office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id)) tsi
                   ORDER BY sql_level ASC, max_date_time DESC)
         LOOP
            CASE
               WHEN     y.SQL_level = 1
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - 5
               THEN
                  tsc_elev := y.ts_code;
                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               ELSE
                  NULL;
            END CASE;
         END LOOP;

         --Get the Precip TS Codes

         fire_update_yn := 'Y';

         FOR y IN (  SELECT tsi.*, ROWNUM row_num
                       FROM (  SELECT tsi.db_office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id) version_id,
                                      MAX (tsv.date_time) max_date_time,
                                      1 SQL_level
                                 FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                                WHERE     tsi.ts_code = tsv.ts_code
                                      AND tsi.db_office_id = x.db_Office_id
                                      AND tsi.location_code = x.locatioN_code
                                      AND TSI.base_parameter_id = c_str_precip
                                      AND tsi.net_ts_active_flag = c_cwms_logic_t
                                      AND INSTR (UPPER (cwms_ts_id), 'FORECAST') =
                                             0
                                      AND (   INSTR (UPPER (versioN_id), '-REV') >
                                                 0
                                           OR UPPER (version_id) IN
                                                 ('REV', 'OBS'))
                             GROUP BY tsi.db_Office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id)
                             UNION ALL
                               SELECT tsi.db_office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id) version_id,
                                      MAX (tsv.date_time) max_date_time,
                                      2 SQL_Level
                                 FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                                WHERE     tsi.ts_code = tsv.ts_code
                                      AND tsi.db_office_id = x.db_Office_id
                                      AND tsi.location_code = x.locatioN_code
                                      AND TSI.base_parameter_id = c_str_precip
                                      AND tsi.net_ts_active_flag = c_cwms_logic_t
                                      AND INSTR (UPPER (cwms_ts_id), 'FORECAST') =
                                             0
                                      AND (UPPER (version_id) NOT IN
                                              ('REV', 'OBS'))
                             GROUP BY tsi.db_Office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id)) tsi
                   ORDER BY tsi.sql_level, row_num)
         LOOP
            CASE
               WHEN     y.sql_level = 1
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
               THEN
                  tsc_precip := y.ts_code;


                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               WHEN     y.sql_level = 1
                    AND y.row_num = 1
                    AND y.max_date_time <= SYSDATE - temp_num_days_countback
                    AND fire_update_yn = 'Y'
               THEN
                  --Don't add the TS code because the date is too old, but this should be an active TS ID?
                  tsc_precip := y.ts_code;

                  temp_notes :=
                        temp_notes
                     || temp_delim
                     || ' -  precip CASE has a Active '
                     || y.version_id
                     || ' TS with too-old data ('
                     || y.max_date_time
                     || ' = '
                     || ROUND ( (SYSDATE - y.max_date_time), 0)
                     || ' days old, the count back is '
                     || temp_num_days_countback
                     || ') '
                     || y.cwms_ts_id
                     || ' SQL Level = '
                     || y.sql_level
                     || ' row number = '
                     || y.row_Num
                     || ' version = '
                     || y.version_id;

                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               WHEN     y.sql_level = 2
                    AND y.row_Num = 1
                    AND y.version_id IN
                           ('RAW',
                            'DCP-RAW',
                            'NERFC QPF',
                            'DECODES',
                            'NWS-RAW',
                            'PRECIP-RAW'                                 --LRE
                                        ,
                            'GOES-COMP'                                  --LRD
                                       ,
                            'MVMLRGS-RAW'                     --MVM's raw data
                                         ,
                            'RED-DCP'                          --MVP raw data?
                                     ,
                            'SFWMD-RAW'                    --SAJ's raw data???
                                       ,
                            'ACF'                              --SAS raw data?
                                 )
                    AND fire_update_yn = 'Y'
               THEN
                  tsc_precip := y.ts_code;

                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               ELSE
                  IF fire_update_yn = 'Y'
                  THEN
                     temp_notes :=
                           temp_notes
                        || temp_delim
                        || ' - INVALID precip CASE for '
                        || y.cwms_ts_id
                        || ' SQL Level = '
                        || y.sql_level
                        || ' row number = '
                        || y.row_Num
                        || ' version = '
                        || y.version_id;
                  END IF;
            END CASE;
         END LOOP;

         fire_update_yn := 'Y';

         -- Find the Stage TS COde


         FOR y IN (  SELECT tsi.*, ROWNUM row_num
                       FROM (  SELECT tsi.db_office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id) version_id,
                                      MAX (tsv.date_time) max_date_time,
                                      1 SQL_LEVEL
                                 FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                                WHERE     tsi.ts_code = tsv.ts_code
                                      AND tsi.db_office_id = x.db_Office_id
                                      AND tsi.location_code = x.locatioN_code
                                      AND tsi.net_ts_active_flag = c_cwms_logic_t
                                      AND TSI.base_parameter_id = c_str_stage
                                      AND UPPER (tsi.versioN_id) IN
                                             ('OBS', 'DCP-REV', 'REV')
                                      AND INSTR (UPPER (tsi.cwms_ts_id),
                                                 'FORECAST') = 0
                             GROUP BY tsi.db_Office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id)
                             UNION ALL
                               SELECT tsi.db_office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id) version_id,
                                      MAX (tsv.date_time) max_date_time,
                                      2 SQL_LEVEL
                                 FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                                WHERE     tsi.ts_code = tsv.ts_code
                                      AND tsi.db_office_id = x.db_Office_id
                                      AND tsi.location_code = x.locatioN_code
                                      AND tsi.net_ts_active_flag = c_cwms_logic_t
                                      AND TSI.base_parameter_id = c_str_stage
                                      AND UPPER (tsi.versioN_id) NOT IN
                                             ('OBS', 'DCP-REV', 'REV')
                                      AND INSTR (UPPER (tsi.cwms_ts_id),
                                                 'FORECAST') = 0
                             GROUP BY tsi.db_Office_id,
                                      tsi.ts_code,
                                      tsi.cwms_ts_id,
                                      UPPER (tsi.version_id)) tsi
                   ORDER BY sql_level, cwms_ts_id)
         LOOP
            CASE
               WHEN     UPPER (y.version_id) IN ('OBS', 'DCP-REV', 'REV')
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
               THEN
                  tsc_stage := y.ts_code;

                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               WHEN     y.sql_level = 2
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
                    AND fire_update_yn = 'Y'
               THEN
                  tsc_stage := y.ts_code;

                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               ELSE
                  IF fire_update_yn = 'Y'
                  THEN
                     temp_notes :=
                           temp_notes
                        || temp_delim
                        || ' - INVALID stage  CASE for '
                        || y.cwms_ts_id
                        || ' SQL Level = '
                        || y.sql_level
                        || ' row number = '
                        || y.row_Num
                        || ' version = '
                        || y.version_id;
                  END IF;
            END CASE;
         END LOOP;

         -- Find the Inflow TS COde

         fire_update_yn := 'Y';

         FOR y IN (SELECT tsi.*, ROWNUM row_num
                     FROM (  SELECT tsi.db_office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id) version_id,
                                    MAX (tsv.date_time) max_date_time
                               FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                              WHERE     tsi.ts_code = tsv.ts_code
                                    AND tsi.db_office_id = x.db_Office_id
                                    AND tsi.location_code = x.locatioN_code
                                    AND TSI.base_parameter_id = 'Flow'
                                    AND tsi.sub_parameter_id LIKE ('Inflow%')
                                    AND INSTR (UPPER (tsi.cwms_ts_id),
                                               'FORECAST') = 0
                                    AND UPPER (tsi.versioN_id) IN
                                           ('OBS', 'DCP-REV', 'REV')
                           GROUP BY tsi.db_Office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id)
                           UNION ALL
                             SELECT tsi.db_office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id) version_id,
                                    MAX (tsv.date_time) max_date_time
                               FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                              WHERE     tsi.ts_code = tsv.ts_code
                                    AND tsi.db_office_id = x.db_Office_id
                                    AND tsi.location_code = x.locatioN_code
                                    AND TSI.base_parameter_id = 'Flow'
                                    AND tsi.sub_parameter_id NOT LIKE
                                           ('Inflow%')
                                    AND INSTR (UPPER (tsi.cwms_ts_id),
                                               'FORECAST') = 0
                                    AND UPPER (tsi.versioN_id) NOT IN
                                           ('OBS', 'DCP-REV', 'REV')
                           GROUP BY tsi.db_Office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id)) tsi)
         LOOP
            CASE
               WHEN     UPPER (y.version_id) IN ('OBS', 'DCP-REV', 'REV')
                    AND y.sub_parameter_id LIKE ('Inflow%')
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
               THEN
                  tsc_inflow := y.ts_code;

                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               ELSE
                  NULL;
            END CASE;
         END LOOP;

         -- Find the outflow TS COde

         fire_update_yn := 'Y';

         FOR y IN (SELECT tsi.*, ROWNUM row_num
                     FROM (  SELECT tsi.db_office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id) version_id,
                                    MAX (tsv.date_time) max_date_time
                               FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                              WHERE     tsi.ts_code = tsv.ts_code
                                    AND tsi.db_office_id = x.db_Office_id
                                    AND tsi.location_code = x.locatioN_code
                                    AND TSI.base_parameter_id = 'Flow'
                                    AND tsi.sub_parameter_id LIKE ('Outflow%')
                                    AND UPPER (tsi.version_id) IN
                                           ('OBS', 'DCP-REV', 'REV')
                           GROUP BY tsi.db_Office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id)
                           UNION ALL
                             SELECT tsi.db_office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id) version_id,
                                    MAX (tsv.date_time) max_date_time
                               FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                              WHERE     tsi.ts_code = tsv.ts_code
                                    AND tsi.db_office_id = x.db_Office_id
                                    AND tsi.location_code = x.locatioN_code
                                    AND TSI.base_parameter_id = 'Flow'
                                    AND tsi.sub_parameter_id NOT LIKE
                                           ('Outflow%')
                                    AND INSTR (tsi.parameter_id, 'Inflow') = 0
                                    AND UPPER (tsi.version_id) NOT IN
                                           ('OBS', 'DCP-REV', 'REV')
                           GROUP BY tsi.db_Office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id)) tsi)
         LOOP
            CASE
               WHEN     UPPER (y.version_id) IN ('OBS', 'DCP-REV', 'REV')
                    AND y.sub_parameter_id LIKE ('Outflow%')
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
               THEN
                  tsc_outflow := y.ts_code;

                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               ELSE
                  NULL;
            END CASE;
         END LOOP;

         -- Find the storage TS COde

         fire_update_yn := 'Y';

         FOR y IN (SELECT tsi.*, ROWNUM row_num
                     FROM (  SELECT tsi.db_office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id) version_id,
                                    MAX (tsv.date_time) max_date_time
                               FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                              WHERE     tsi.ts_code = tsv.ts_code
                                    AND tsi.db_office_id = x.db_Office_id
                                    AND tsi.location_code = x.locatioN_code
                                    AND TSI.base_parameter_id = c_str_stor
                                    AND tsi.sub_parameter_id IS NULL
                                    AND tsi.versioN_id IN
                                           ('OBS', 'DCP-REV', 'REV')
                           GROUP BY tsi.db_Office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id)
                           UNION ALL
                             SELECT tsi.db_office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id) version_id,
                                    MAX (tsv.date_time) max_date_time
                               FROM cwms_v_ts_id tsi, cwms_v_tsv tsv
                              WHERE     tsi.ts_code = tsv.ts_code
                                    AND tsi.db_office_id = x.db_Office_id
                                    AND tsi.location_code = x.locatioN_code
                                    AND TSI.base_parameter_id = c_str_stor
                                    AND tsi.sub_parameter_id IS NOT NULL
                                    AND tsi.versioN_id NOT IN
                                           ('OBS', 'DCP-REV', 'REV')
                           GROUP BY tsi.db_Office_id,
                                    tsi.ts_code,
                                    tsi.cwms_ts_id,
                                    tsi.sub_parameter_id,
                                    UPPER (tsi.version_id)) tsi)
         LOOP
            CASE
               WHEN     UPPER (y.version_id) IN ('OBS', 'DCP-REV', 'REV')
                    AND y.sub_parameter_id IS NULL
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
                    AND (   INSTR (UPPER (y.cwms_ts_id), 'FLOOD') > 0
                         OR INSTR (UPPER (y.cwms_ts_id), 'FLD') > 0)
               THEN
                  tsc_stor_Flood := y.ts_code;
               WHEN     y.version_id IN ('OBS', 'DCP-REV', 'REV')
                    AND y.sub_parameter_id IS NULL
                    AND y.row_num = 1
                    AND y.max_date_time > SYSDATE - temp_num_days_countback
                    AND (   INSTR (UPPER (y.cwms_ts_id), 'DROUGHT') > 0
                         OR INSTR (UPPER (y.cwms_ts_id), 'CONSERVATION') > 0
                         OR INSTR (UPPER (y.cwms_ts_id), 'CONSERVE') > 0)
               THEN
                  tsc_stor_drought := y.ts_code;


                  fire_update_yn := 'N';
                  fire_i := fire_i + 1;
               WHEN y.row_Num = 2 AND fire_update_yn = 'Y'
               THEN
                  tsc_stor_drought := y.ts_code;
                  tsc_stor_Flood := y.ts_code;
                  fire_update_yn := 'N';
                  fire_i := fire_i + 2;
               ELSE
                  NULL;
            END CASE;
         END LOOP;



         IF fire_i > 0
         THEN
            UPDATE at_a2w_ts_codes_by_loc
               SET date_refreshed = SYSDATE,
                   notes =
                         'Found '
                      || fire_i
                      || ' TS IDs for '
                      || x.locatioN_code
                      || temp_delim
                      || temp_notes,
                   display_flag = 'T',
                   ts_code_elev = tsc_elev,
                   ts_code_stage = tsc_stage,
                   ts_code_precip = tsc_precip,
                   ts_code_outflow = tsc_outflow,
                   ts_code_inflow = tsc_inflow,
                   ts_code_stor_flood = tsc_stor_flood,
                   ts_code_stor_drought = tsc_stor_drought,
                   num_ts_codes = fire_i
             WHERE     db_Office_id = x.db_Office_id
                   AND location_code = x.locatioN_code;
         ELSE
            --No TS Codes were found for this office and location
            -- email or what?
            NULL;


            FOR y
               IN (  SELECT tsi.cwms_ts_id, MAX (tsv.date_time) max_date_time
                       FROM cwms_v_ts_id tsi,
                            cwms_v_tsv tsv,
                            (SELECT db_office_id, locatioN_code
                               FROM at_a2w_ts_codes_by_loc
                              WHERE (    ts_code_elev IS NULL
                                     AND ts_code_precip IS NULL
                                     AND ts_code_stage IS NULL
                                     AND ts_code_inflow IS NULL
                                     AND ts_code_outflow IS NULL
                                     AND locatioN_code = x.location_code
                                     AND db_office_id = x.db_office_id)) tsl
                      WHERE     tsi.ts_code = tsv.ts_code(+)
                            AND tsi.location_code = tsl.locatioN_code
                            AND tsi.db_office_id = tsl.db_office_id
                   GROUP BY tsi.cwms_ts_id
                   ORDER BY 2 DESC)
            LOOP
               IF y.max_date_time IS NULL
               THEN
                  loop_i_no_data := Loop_i_no_data + 1;
               END IF;

               IF y.max_date_time <= SYSDATE - 6
               THEN
                  loop_i_old_data := looP_i_old_data + 1;
               END IF;
            END LOOP;

            IF loop_i_no_data > 0 OR loop_i_old_data > 0
            THEN
               UPDATE at_a2w_ts_codes_by_loc
                  SET date_refreshed = SYSDATE,
                      notes =
                            loop_i_no_data
                         || '/'
                         || loop_i_old_data
                         || ' empty/old TS IDs for '
                         || x.locatioN_code
                         || temp_delim
                         || temp_notes,
                      display_flag = 'F'
                WHERE     db_Office_id = x.db_Office_id
                      AND location_code = x.locatioN_code;
            ELSE
               UPDATE at_a2w_ts_codes_by_loc
                  SET date_refreshed = SYSDATE,
                      notes = temp_notes,
                      display_flag = 'F'
                WHERE     db_Office_id = x.db_Office_id
                      AND location_code = x.locatioN_code;
            END IF;
         END IF;


         loop_i_no_data := 0;
         loop_i_old_data := 0;
         fire_i := 0;


         tsc_elev := NULL;
         tsc_stage := NULL;
         tsc_precip := NULL;
         tsc_inflow := NULL;
         tsc_outflow := NULL;
         tsc_stor_flood := NULL;
         tsc_stor_drought := NULL;
         temp_notes := NULL;
      END LOOP;
*/
NULL;


   END p_refresh_a2w_ts_codes;

   PROCEDURE p_sync_cwms_office_from_CM2 (
      p_sync_office_buildings_yn    IN     VARCHAR2 DEFAULT c_app_logic_y,
      p_sync_office_boundaries_yn   IN     VARCHAR2 DEFAULT c_app_logic_y,
      p_status                         OUT VARCHAR2)
   IS
      temp_num_updated   NUMBER DEFAULT 0;
   BEGIN
      /*
          IF p_sync_office_buildings_yn = c_app_logic_y THEN
            UPDATE CWMS_OFFICES_GEOLOC o
                 SET o.shape_office_building = (SELECT shape
                                                  FROM coe.offices_geoloc@gold1db
                                                  WHERE symbol = o.office_id
                                )
               WHERE office_id IN (select symbol
                                     FROM coe.offices_geoloc@gold1db
                                   );

                 temp_num_updated := SQL%ROWCOUNT;
            p_status := p_status || temp_num_updated || ' - updated buildings. ' ;
            temp_num_updated := 0;

          END IF;
      */
      /*
          IF p_sync_office_boundaries_yn = c_app_logic_y THEN

           -- Update the district offices by office ID
             UPDATE cwms_offices_geoloc o
                SET o.shape = (SELECT sdo_aggr_union(sdoaggrtype(d.shape, 0.5)) shape
                                FROM coe.district@gold1db d
                               WHERE name IS NOT NULL
                                 AND name != 'Water'
                                 AND symbol IS NOT NULL
                                 AND symbol = SUBSTR(o.org_symbol,3, LENGTH(o.org_symbol))
                               GROUP BY symbol, name
                              );
            temp_num_updated := SQL%ROWCOUNT;
            p_status := p_status || temp_num_updated || ' - updated by district. ' ;
            temp_num_updated := 0;

           -- Update the division boundaries by office ID

              --SELECT * FROM coe.usace_military_divisions@gold1db

             UPDATE cwms_offices_geoloc o
                SET o.shape = (SELECT d.shape
                                FROM coe.usace_military_divisions@gold1db  d
                               WHERE div = SUBSTR(o.org_symbol,3, LENGTH(o.org_symbol))
                              )
               WHERE SUBSTR(o.org_symbol,3, LENGTH(o.org_symbol)) IN (SELECT div
                                     FROM coe.usace_military_divisions@gold1db
                                  );
              temp_num_updated := SQL%ROWCOUNT;
              p_status := p_status || temp_num_updated || ' - updated by division. ' ;
              temp_num_updated := 0;


          END IF;
      */

      --IF p_status IS NULL THEN p_status :=  'nothing happened ' || p_sync_office_boundaries_yn || p_sync_office_buildings_yn; END IF;
      NULL;
   END;

   PROCEDURE p_sync_cwms_geo_tbls_w_CM2 (
      p_compare_or_sync   IN     VARCHAR2 DEFAULT 'COMPARE',
      p_status               OUT VARCHAR2)
   IS
      temp_num_cwms   NUMBER DEFAULT 0;
      temp_Num_cm2    NUMBER DEFAULT 0;
      temp_delim      VARCHAR2 (10) DEFAULT '||';

      temp_num        NUMBER DEFAULT 0;
   BEGIN
      --This procedure will syncronize the geometry tables in CWMS with CM2 tables

      -- SQL used to create the tables
      --CREATE TABLE cities AS SELECT * FROM coe.cities@gold1db;
      --UPDATE mdsys.user_sdo_geom_metadata SET srid = 8265 WHERE table_name = UPPER('cities');
      --CREATE INDEX cities_sidx on cities (SHAPE) indextype is mdsys.spatial_index
      --        INSERT INTO mdsys.user_sdo_geom_metadata (table_name,column_name,diminfo,srid)
      --             VALUES ('cities','SHAPE', SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',-180,180,0.005)
      --                                                    , SDO_DIM_ELEMENT('Y',-90,90,0.005))
      --                                                   , 8265);

      --Country
      -- CREATE TABLE country AS SELECT * FROM esri_world.country@gold1db
      -- UPDATE mdsys.user_sdo_geom_metadata SET srid = 8265 WHERE table_name = UPPER('country');
      -- INSERT INTO mdsys.user_sdo_geom_metadata (table_name,column_name,diminfo,srid)
      --      VALUES ('country','SHAPE', SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',-180,180,0.005)
      --                                            , SDO_DIM_ELEMENT('Y',-90,90,0.005))
      --                                           , 8265);
      -- CREATE INDEX country_sidx on country (SHAPE) indextype is mdsys.spatial_index;

      --States
      --CREATE TABLE states AS SELECT * FROM coe.states@gold1db;
      --UPDATE mdsys.user_sdo_geom_metadata SET srid = 8265 WHERE table_name = UPPER('states');
      --INSERT INTO mdsys.user_sdo_geom_metadata (table_name,column_name,diminfo,srid)
      --     VALUES ('states','SHAPE', SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',-180,180,0.005)
      --                                           , SDO_DIM_ELEMENT('Y',-90,90,0.005))
      --                                          , 8265);
      --DROP INDEX states_sidx
      --CREATE INDEX states_sidx on states (SHAPE) indextype is mdsys.spatial_index

      --County
      --DROP TABLE counties
      --CREATE TABLE counties AS SELECT * FROM NAT_ATLAS.COUNTYP020_AGGR@gold1db;
      --UPDATE mdsys.user_sdo_geom_metadata SET srid = 8265 WHERE table_name = UPPER('counties');
      -- INSERT INTO mdsys.user_sdo_geom_metadata (table_name,column_name,diminfo,srid)
      --    VALUES ('counties','SHAPE', SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',-180,180,0.005)
      --                                           , SDO_DIM_ELEMENT('Y',-90,90,0.005))
      --                                         , 8265);
      --CREATE INDEX counties_sidx on counties (SHAPE) indextype is mdsys.spatial_index ;

      --Timezone
      --CREATE TABLE timezone AS SELECT * FROM esri_world.timezone@gold1db;
      --UPDATE mdsys.user_sdo_geom_metadata SET srid = 8265 WHERE table_name = UPPER('timezone');
      --INSERT INTO mdsys.user_sdo_geom_metadata (table_name,column_name,diminfo,srid)
      --    VALUES ('timezone','SHAPE', SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',-180,180,0.005)
      --                                           , SDO_DIM_ELEMENT('Y',-90,90,0.005))
      --                                          , 8265);
      -- CREATE INDEX timezone_sidx on timezone (SHAPE) indextype is mdsys.spatial_index ;



      --SELECT * FROM all_sdo_geom_metadata

      --SELECT * FROM cities

      /*
              IF p_compare_or_sync = 'COMPARE' THEN
               NULL;

               SELECT COUNT(objectid)
                 INTO temp_num_cwms
                 FROM cities;

               SELECT COUNT(objectid)
                 INTO temp_num_cm2
                 FROM coe.cities@gold1db;

                 IF temp_num_cwms = temp_num_cm2 THEN
                  p_status := p_status || temp_delim || ' Cities Rows equal eachother at ' || temp_num_cwms ;
                 END IF;

              END IF;
      */

      --State


      -- NIDID

      --SELECT * FROM cwms_nid
      /*

        DELETE cwms_nid;
        temp_num := SQL%ROWCOUNT;
        p_status := p_status || temp_delim || ' Deleted ' || TO_CHAR(temp_num) || ' records from NID.';

        INSERT INTO cwms_nid

        SELECT recordid, dam_name, other_dam_name, dam_former_name
             , stateid, nidid, longitude, latitude, section, county, river
             , city, distance, owner_name, NULL usace_critical, owner_type, dam_designer
             , private_dam, dam_type, core, foundation, purposes
             , year_completed, year_modified, dam_length, dam_height, structural_height
             , hydraulic_height, nid_height, max_discharge, max_storage, normal_storage
             , nid_storage, surfacE_area, drainage_area, NULL sort_category, shape
          FROM coe.nid2013@gold1db;

        p_status := p_status || temp_delim || ' Inserted ' || TO_CHAR(temp_num) || ' records from NID.';

        */
      --SELECT * FROM coe.nid2013@gold1db;

      --USGS Stations

      --NWS Station ID

      --USACE Inventory of Dams
      /*

          CREATE TABLE usace_DAM_T AS SELECT * FROM usace_dam@gold1db
          CREATE TABLE usace_DAM_purpose_A AS SELECT * FROM usace_dam_purpose@gold1db
          CREATE TABLE usace_DAM_purpose_L AS SELECT * FROM usace_purpose@gold1db
      */

      --SELECT * FROM user_db_links

      --DELETE usace_dam_t;
      --INSERT INTO usace_dam_t SELECT * FROM usace_dam@gold1db;

      --SELECT * FROM usace_dam_t

      NULL;
   END;

   PROCEDURE p_sync_cwms_rivergages_w_CM2
   IS
   BEGIN
      --This procedure will syncronize rivergages table with a copy of CorpsMap
      NULL;
   END;

   PROCEDURE p_sync_cwms_loc_by_NIDID (
      p_db_Office_id   IN     cwms_v_loc.db_Office_id%TYPE,
      p_location_id    IN     cwms_v_loc.locatioN_id%TYPE DEFAULT NULL,
      p_action         IN     VARCHAR2 DEFAULT 'PL/SQL',
      p_sync_tf        IN     VARCHAR2 DEFAULT c_cwms_logic_f,
      p_out               OUT CLOB)
   IS
      loop_i            NUMBER DEFAULT 1;
      num_i             NUMBER DEFAULT 0;
      temp_clob         CLOB;
      temp_clob_loop    CLOB;

      temp_num_issues   NUMBER;

      loop_num          NUMBER DEFAULT 1;
      temp_delim        VARCHAR2 (15) DEFAULT '<BR>';
   BEGIN
      NULL;

      --this procedure will synconize an office or location's NIDID aliases
      FOR x
         IN (  SELECT l.*, la.alias_id nidid
                 FROM cwms_v_loc l,
                      (SELECT *
                         FROM cwms_v_loc_alias
                        WHERE     db_Office_id = p_db_Office_id
                              AND category_id = 'Agency Aliases'
                              AND GROUP_ID = 'NIDID') la
                WHERE     l.unit_system = 'EN'
                      AND l.db_office_id = p_db_office_id
                      AND l.location_id = la.locatioN_id(+)
                      AND CASE
                             WHEN p_locatioN_id IS NULL THEN c_temp_null_case
                             ELSE p_locatioN_id
                          END =
                             CASE
                                WHEN p_locatioN_id IS NULL
                                THEN
                                   c_temp_null_case
                                ELSE
                                   l.locatioN_id
                             END
             ORDER BY l.location_id)
      LOOP
         IF x.nidid IS NULL
         THEN
            --Location doesn't have a NIDID in it
            temp_clob_loop :=
                  temp_clob_loop
               || temp_delim
               || loop_i
               || '. '
               || x.location_id
               || ' does not have a NIDID association';
            NULL;
         ELSE
            temp_clob_loop :=
                  temp_clob_loop
               || temp_delim
               || loop_i
               || '. '
               || x.location_id
               || ' has a NIDID association of '
               || x.nidid;

            num_i := num_i + 1;

            FOR y
               IN (SELECT d.*, c.county_name, s.state_abbr state_initial
                     FROM cwms_usace_dam d,
                          cwms_usace_dam_state s,
                          cwms_usace_dam_county c
                    WHERE     d.state_id = s.state_id
                          AND d.county_id = c.county_id
                          AND nid_id = x.nidid)
            LOOP
               temp_clob_loop :=
                     temp_clob_loop
                  || temp_delim
                  || ' - . '
                  || x.location_id
                  || ' has a USACE NID association of '
                  || x.nidid;

               IF y.longitude != x.longitude
               THEN
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' CWMS longitude '
                     || x.longitude
                     || ' differs from USACE Inventory of Dams '
                     || y.longitude
                     || ' by '
                     || (x.longitude - y.longitude)
                     || ' .';
               ELSE
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' longitude Matches';
               END IF;

               IF y.latitude != x.latitude
               THEN
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' CWMS latitude '
                     || x.latitude
                     || ' differs from USACE Inventory of Dams '
                     || y.latitude
                     || ' by '
                     || (x.latitude - y.latitude)
                     || ' .';
               ELSE
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' latitude Matches';
               END IF;

               IF UPPER (x.public_name) != UPPER (y.dam_name)
               THEN
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' CWMS public name '
                     || x.public_name
                     || ' differs from USACE Inventory of Dams '
                     || y.dam_name
                     || '.';
               ELSE
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' Public Names Match';
               END IF;

               IF UPPER (x.state_initial) != UPPER (y.state_initial)
               THEN
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' CWMS state abbreviation '
                     || x.state_initial
                     || ' differs from USACE Inventory of Dams '
                     || y.state_initial
                     || '.';
               ELSE
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' States Match';
               END IF;

               IF UPPER (x.county_name) != UPPER (y.county_name)
               THEN
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' CWMS county name '
                     || x.county_name
                     || ' differs from USACE Inventory of Dams '
                     || y.county_name
                     || '.';
               ELSE
                  temp_clob_loop :=
                        temP_clob_loop
                     || temp_delim
                     || ' - .. '
                     || ' Counties Match';
               END IF;



               IF p_sync_tf = 'T'
               THEN
                  cwms_loc.update_location2 (
                     p_location_id        => x.location_id,
                     p_county_name        => y.county_name,
                     p_horizontal_datum   => 'WSG84',
                     p_latitude           => y.latitude,
                     p_longitude          => y.longitude,
                     p_public_name        => y.dam_name,
                     p_state_initial      => y.state_initial,
                     p_db_office_id       => x.db_office_id);
               END IF;
            END LOOP;
         END IF;

         NULL;



         IF temp_clob_loop IS NOT NULL
         THEN
            temp_clob := Temp_clob || temp_delim || temp_clob_loop;
         END IF;

         temp_clob_loop := NULL;
         loop_i := loop_i + 1;
      END LOOP;


      temp_clob :=
            ' Found '
         || num_i
         || ' NIDID associations from '
         || loop_i
         || ' locations.'
         || temp_delim
         || temp_clob;


      /*
      WHILE loop_num < (length(temp_clob))

      loop
          htp.prn (SUBSTR(temp_clob
                         , loop_num
                         , 1000
                         )
                  );
          loop_num := loop_num + 1000;

      end loop;
      */


      CASE p_action
         WHEN 'PL/SQL'
         THEN
            p_out := temp_clob;
         ELSE
            NULL;
      END CASE;
   END;

   PROCEDURE p_sync_cwms_nid_w_CM2 (
      p_compare_or_sync   IN     VARCHAR2 DEFAULT 'COMPARE',
      p_status               OUT VARCHAR2)
   IS
   BEGIN
      /* This procecdure will syncronize the usace NID lookup tables with values at CRREL/CM2

      */
      NULL;
   /*
   IF UPPER(p_compare_or_sync) = 'SYNC' THEN

       DELETE cwms_usace_dam;
       DELETE cwms_usace_dam_state;
       DELETE cwms_usace_dam_county;

       INSERT INTO cwms_usace_dam_state   SELECT * FROM usace_dam_state@gold1db;
       INSERT INTO cwms_usace_dam_county  SELECT * FROM usace_dam_county@gold1db;
       INSERT INTO cwms_usace_dam         SELECT d.*, null shape FROM usace_dam@gold1db d;

       DELETE cwms_nid;



       INSERT INTO cwms_nid               SELECT n.recordid, dam_name,other_dam_name,dam_former_Name
                                               , stateid, nidid, longitude,latitude
                                               , section, county, river, city
                                               , distance, owner_name
                                               , NULL usace_critical
                                               , owner_type, dam_designer, private_dam
                                               , dam_type, core, foundation, purposes, year_completed
                                               , year_modified, dam_length, dam_height
                                               , structural_height
                                               , hydraulic_height, nid_height, max_discharge, max_storage
                                               , normal_storage, nid_storage, surface_area, drainage_area
                                               , null sort_category
                                               , shape
                                            FROM nid_for_cwms@gold1db n;

   --SELECT * FROm cwms_nid


      UPDATE cwms_usace_dam
         SET shape = SDO_GEOMETRY(2001,
                                  8265,
                                  SDO_POINT_TYPE (longitude,latitude,NULL), NULL, NULL
                                 )
       WHERE longitude IS NOT NULL AND latitude IS NOT NULL;



   ELSE
       p_status := 'CM2 Sync for NID set to "Compare". Expand...';


   END IF;

   */

   END;

   PROCEDURE p_sync_cwms_loc_by_RG (
      p_db_Office_id   IN     cwms_v_loc.db_Office_id%TYPE,
      p_location_id    IN     cwms_v_loc.locatioN_id%TYPE DEFAULT NULL,
      p_action         IN     VARCHAR2 DEFAULT 'PL/SQL',
      p_sync_tf        IN     VARCHAR2 DEFAULT c_cwms_logic_f,
      p_parse_for      IN     VARCHAR2 DEFAULT NULL,
      p_out               OUT CLOB)
   IS
      temp_clob          CLOB;

      temp_latitude      cwms_v_loc.latitude%TYPE;
      temp_Longitude     cwms_v_loc.longitude%TYPE;
      temp_public_Name   cwms_v_loc.public_name%TYPE;


      loop_x_i           NUMBER DEFAULT 0;
      loop_y_i           NUMBER DEFAULT 0;
      loop_in_rg         NUMBER DEFAULT 0;


      temp_delim         VARCHAR2 (15) DEFAULT '<BR>';
   BEGIN
      FOR x
         IN (  SELECT *
                 FROM cwms_v_loc
                WHERE     unit_System = 'EN'
                      AND db_office_id = p_db_Office_id
                      AND CASE
                             WHEN p_locatioN_id IS NULL THEN c_temp_null_case
                             ELSE p_locatioN_id
                          END =
                             CASE
                                WHEN p_locatioN_id IS NULL
                                THEN
                                   c_temp_null_case
                                ELSE
                                   locatioN_id
                             END
             ORDER BY locatioN_id)
      LOOP
         NULL;

         temp_clob :=
               temp_clob
            || temp_delim
            || ' - '
            || TO_CHAR (loop_x_i)
            || ' found '
            || x.location_id;

         /*
         --Scan through and check the rivergages extract for a match

             FOR y IN (SELECT *
                         FROM cwms_v_rivergages_station
                        WHERE district = p_db_Office_id
                          AND (station_id = x.locatioN_id
                                         OR
                               statioN_id = x.sub_location_id
                              )
                      ) LOOP
                         temp_clob := temp_clob || temp_delim || ' -- found RG loc';

                         --Check all the metadata
                             --Latitude
                             CASE
                              WHEN (x.latitude IS NULL OR x.latitude = 0)
                                             AND
                                   (y.latitude != 0 AND y.latitude IS NOT NULL) THEN
                                   --Set latitude = RG
                                     temp_latitude := y.latitude;
                                     temp_clob := temp_clob || temp_delim || ' --- ' || ' New Latitude = ' || TO_CHAR(y.latitude);
                              ELSE
                               temp_clob := temp_clob || temp_delim || ' --- ' || ' CWMS location has a latitude. ';
                             END CASE;
                              --Longitude
                             CASE
                              WHEN (x.Longitude IS NULL OR x.longitude = 0)
                                             AND
                                   (y.Longitude != 0 AND y.Longitude IS NOT NULL) THEN
                                   --Set Longitude = RG
                                     temp_longitude := y.longitude;
                                     temp_clob := temp_clob || temp_delim    || ' --- ' || ' New longitude = ' || TO_CHAR(y.longitude);

                              ELSE
                                temp_clob := temp_clob || temp_delim || ' --- ' || ' CWMS location has a longitude. ';
                             END CASE;
                              --Public Name
                             CASE

                              WHEN x.public_name IS NULL OR x.public_name = x.locatioN_id
                               THEN
                                   --Get the public name from river gages

                                   CASE
                                     WHEN y.map_label IS NOT NULL AND y.map_label != y.station_id AND LENGTH(y.map_label) > 5 THEN
                                         temp_public_Name := SUBSTR(y.map_Label,1,32);
                                         temp_clob := temp_clob || temp_delim    || ' --- ' || ' New Public Name from RG Map Label = ' || temp_public_Name;

                                     ELSE
                                         temp_public_Name := SUBSTR(y.statioN_desc, 1,57);

                                       IF LENGTH(y.statioN_desc) <= 32 THEN
                                         temp_clob := temp_clob || temp_delim    || ' --- ' || ' New Public Name from RG station desc = ' || temp_public_Name;
                                       ELSE
                                         temp_clob := temp_clob || temp_delim    || ' --- ' || ' Public Name from RG station desc was too big, so it has been shortened to: ' || temp_public_Name
                                                                || temp_delim    || ' from ' || y.statioN_desc;
                                       END IF;
                                  END CASE;
                             ELSE
                                temp_clob := temp_clob || temp_delim || ' --- ' || ' CWMS location already has a Public Name. ';
                             END CASE;

                             loop_y_i := loop_y_i + 1;
                             loop_in_rg := loop_in_rg + 1;

                             --Gage zero = elevation location level of streambed?

                             --flood stage = elevation location_level of flood



                        END LOOP;


                 IF loop_Y_i = 0 THEN
                     --Found zero records in RG
                     temp_clob := temp_clob || temp_delim || '  --x ' || x.location_id || ' not in RiverGages';
                 END IF;
         */

         loop_Y_i := 0;

         loop_x_i := loop_x_i + 1;
      END LOOP;

      temp_clob :=
            'Found '
         || loop_in_rg
         || ' locations in rivergages.'
         || ' Parsed '
         || loop_x_i
         || ' CWMS Locations'
         || temp_delim
         || temp_clob;

      p_out := temp_clob;
      NULL;
   END;



   PROCEDURE p_load_tsv (
      p_collection_name   IN     apex_collections.collection_name%TYPE,
      p_display_out          OUT VARCHAR2)
   IS
      temp_value   CWMS_T_TSV;
      --temp_value_array   cwms_t_tsv_array;
      i            NUMBER DEFAULT 0;
   BEGIN
      FOR x IN (SELECT *
                  FROM apex_collections
                 WHERE collection_name = p_collection_name)
      LOOP
         NULL;

         /*
         temp_Value := cwms_t_tsv(TIMESTAMP '1997-01-31 09:26:56.66 +02:00'
                                      , TO_BINARY_DOUBLE(1)
                                      , 3
                                       );
         --temp_value_array(i) := temp_value;
         */
         BEGIN
            NULL;
         /*
             cwms_ts.store_ts (
                 p_cwms_ts_id          => 'Test123.123'
                 ,p_units              => 'M'
                 ,p_timeseries_data   => temp_value_array
                 ,p_store_rule         =>  NULL
                 ,p_override_prot      => 'F'
                 ,p_version_date       => cwms_util.non_versioned
                 ,p_office_id           => 'NAE'
             );
         */

         /*
            SELECT cwms_ts_id
              INTO temp_cwms_id
              FROM cwms_v_ts_id
             WHERE ts_code = x.n001;
         */


         EXCEPTION
            WHEN OTHERS
            THEN
               APEX_COLLECTION.UPDATE_MEMBER (
                  p_collection_name   => p_collection_name,
                  p_seq               => x.seq_id,
                  p_c010              => SQLERRM);
         END;

         APEX_COLLECTION.UPDATE_MEMBER (
            p_collection_name   => p_collection_name,
            p_seq               => x.seq_id,
            p_c010              => 'Success');
      END LOOP;

      NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_display_out := SQLERRM;
   END;


   PROCEDURE p_load_Project_Purpose (
      p_db_Office_id       IN cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id        IN cwms_v_loc.locatioN_id%TYPE,
      p_project_purposes   IN VARCHAR2,
      p_delim              IN VARCHAR2 DEFAULT ',',
      p_purpose_type       IN VARCHAR2 DEFAULT 'AUTHORIZED')
   IS
      --temp_db_office_code        cwms_v_cwms_office.db_office_code%TYPE;
      temp_additional_notes   VARCHAR2 (50);
   BEGIN
      /*
        SELECT db_office_code
          INTO temp_db_office_code
          FROM cwms_v_cwms_office
         WHERE db_office_id = p_db_Office_id;
      */

      FOR x
         IN (SELECT *
               FROM cwms_v_loc
              WHERE     db_office_id = p_db_Office_id
                    AND location_id = p_locatioN_id
                    AND unit_system = 'EN')
      LOOP
         --SELECT * FROM cwms_v_project_purpose

         --Delete values in the DB but not in the string
         DELETE at_project_purpose
          WHERE     project_location_code = x.location_code
                AND purpose_type = p_purpose_type
                AND project_purpose_code IN
                       (SELECT TO_NUMBER (purpose_code) purpose_code
                          FROM cwms_v_project_purposes
                         WHERE office_id IN ('CWMS')
                        MINUS
                        SELECT TO_NUMBER (COLUMN_VALUE) purpose_code
                          FROM TABLE (
                                  STR2TBL (
                                     REPLACE (p_project_purposes,
                                              p_delim,
                                              ','))));

         IF p_project_purposes IS NOT NULL
         THEN
            --insert new values
            FOR y
               IN (SELECT TO_NUMBER (COLUMN_VALUE) purpose_code
                     FROM TABLE (
                             STR2TBL (
                                REPLACE (p_project_purposes, p_delim, ',')))
                   MINUS
                   SELECT TO_NUMBER (project_purpose_code) purpose_code
                     FROM cwms_v_project_purpose
                    WHERE     project_location_code = x.location_code
                          AND purpose_type = p_purpose_type)
            LOOP
               temp_additional_notes :=
                     'Added via CMA on '
                  || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI');


               INSERT INTO at_project_purpose (project_locatioN_code,
                                               project_purpose_code,
                                               purpose_type,
                                               additional_notes)
                    VALUES (x.locatioN_code,
                            y.purpose_code,
                            p_purpose_Type,
                            temp_additional_notes);

               temp_additional_notes := NULL;
            END LOOP;
         END IF;
      END LOOP;



      NULL;
   END;

   PROCEDURE p_load_missing_tsv (
      p_ts_code           IN cwms_v_ts_id.ts_code%TYPE,
      p_date_start        IN DATE,
      p_date_end          IN DATE,
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_load_to_db_tf     IN VARCHAR2 DEFAULT 'F',
      p_load_as_zero      IN VARCHAR2 DEFAULT 'F')
   IS
      loop_in_i                  NUMBER DEFAULT 0;
      temp_date                  DATE;
      temp_date_char             VARCHAR2 (55);
      temp_decimal_days_to_add   NUMBER;
      num_days                   NUMBER DEFAULT 30;
      Num_loop                   NUMBER DEFAULT 0;
      temp_average_value         NUMBER DEFAULT 0;
      temp_avg_val_in_loop       NUMBER;
      temp_loop_i_found          NUMBER DEFAULT 0;


      --Variables to handle zero values
      temp_zero_last             NUMBER;
      temp_value_num_last        NUMBER;
      temp_value_num             NUMBER;         --used to convert char to num

      --Pct Calculations
      temp_num_mean              NUMBER;                    --This is the mean
      temp_num_010_pct_mean      NUMBER; --This is the number to determine if the individual number is 5% off the man
      temp_num_090_pct_mean      NUMBER;
      temp_num_110_pct_mean      NUMBER;

      temp_running_mean          NUMBER;            --This is the running mean

      --Variables to be called out to calc procedure
      temp_value_previous        NUMBER;
      temp_value_next            NUMBER;
      temp_value                 NUMBER;
      temp_value_average         NUMBER;
      temp_seq_Id_previous       NUMBER;
      temp_seq_id_next           NUMBER;
   BEGIN
      temp_decimal_days_to_add := 1 / 24;

      num_loop := num_days * 24;
      temp_date := p_date_start;

      FOR i IN 1 .. num_loop
      LOOP
         IF temp_date IS NULL
         THEN
            temp_date := TO_DATE ('01-APR-2014', 'DD-MON-YYYY');
         ELSE
            temp_date := temp_date + temp_decimal_days_to_add;
         END IF;


         temp_date_char := TO_CHAR (temp_date, 'DD-MON-YYYY HH24:MI');

         FOR x
            IN (  SELECT c002,
                         TO_DATE (c002, 'DD-MON-YYYY HH24:MI') compare_date
                    FROM apex_collections
                   WHERE     collection_name = p_collection_name
                         AND c002 = temp_date_char
                ORDER BY seq_id)
         LOOP
            NULL;
            loop_in_i := 1;
         END LOOP;

         IF loop_in_i = 1
         THEN
            --The record exists in the collection, do not add
            NULL;
         ELSE
            IF p_load_as_zero = 'T'
            THEN
               APEX_COLLECTION.ADD_MEMBER (
                  p_collection_name   => p_collection_name,
                  p_c001              => p_ts_code,
                  p_c002              => temp_date_char,
                  p_c005              => '0',
                  p_c010              => 'MISSING',
                  p_c011              => temp_date_char);
            ELSE
               APEX_COLLECTION.ADD_MEMBER (
                  p_collection_name   => p_collection_name,
                  p_c001              => p_ts_code,
                  p_c002              => temp_date_char,
                  p_c010              => 'MISSING',
                  p_c011              => temp_date_char);
            END IF;
         END IF;

         loop_in_i := 0;
      END LOOP;



      --Sort the collection to get them in chronological order

      FOR x
         IN (SELECT c.*, TO_DATE (c002, 'DD-MON-YYYY HH24:MI:SS') temp_date
               FROM apex_collections c
              WHERE c.collection_name = p_collection_name)
      LOOP
         apex_collection.update_member (
            p_collection_name   => p_collection_name,
            p_seq               => x.seq_id,
            p_c001              => x.c001,
            p_c002              => x.c002,
            p_c003              => x.c003,
            p_c004              => x.c004,
            p_c005              => x.c005,
            p_c006              => x.c006,
            p_c007              => x.c007,
            p_c008              => x.c008,
            p_c009              => x.c009,
            p_c010              => x.c010,
            p_c011              => x.c011,
            p_c012              => x.c012,
            p_c013              => x.c013,
            p_d001              => x.temp_date);
      END LOOP;

      APEX_COLLECTION.SORT_MEMBERS (p_collection_name         => p_collection_name,
                                    p_sort_on_column_number   => 2);
   END;

   PROCEDURE p_get_values_by_seq_id (
      p_collection_name   IN     apex_collections.collection_name%TYPE,
      p_seq_id            IN     apex_collections.seq_id%TYPE,
      p_value                OUT NUMBER,
      p_value_previous       OUT NUMBER,
      p_value_next           OUT NUMBER,
      p_value_average        OUT NUMBER,
      p_seq_Id_previous      OUT apex_collections.seq_id%TYPE,
      p_seq_id_next          OUT apex_collections.seq_id%TYPE)
   IS
      temp_last          NUMBER;
      temp_last_seq_id   NUMBER;
   BEGIN
      NULL;

      FOR x
         IN (  SELECT seq_id, c005
                 FROM apex_collections
                WHERE collection_name = p_collection_name AND c005 IS NOT NULL
             ORDER BY seq_id)
      LOOP
         NULL;

         BEGIN
            --If the loop has found the current value, then conditionally process for the next acceptable value
            IF p_value IS NOT NULL AND p_value_next IS NULL
            THEN
               IF p_value_next IS NOT NULL OR p_value_next != '0'
               THEN
                  p_value_next := TO_NUMBER (x.c005);
                  p_seq_id_next := x.seq_id;
               END IF;
            END IF;


            --
            IF x.seq_Id = p_seq_id
            THEN
               p_value := TO_NUMBER (x.c005);

               p_value_previous := temp_last;
               p_seq_Id_previous := temp_last_seq_id;
            END IF;


            IF temp_last IS NOT NULL OR temp_last != '0'
            THEN
               temp_last := TO_NUMBER (x.c005);
               temp_last_seq_id := x.seq_id;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;

      p_value_average := (p_value_next + p_value_previous) / 2;


      p_value := ROUND (p_value, 4);
      p_value_previous := ROUND (p_value_previous, 4);
      p_value_next := ROUND (p_value_next, 4);
      p_value_average := ROUND (p_value_average, 4);
   END;

   PROCEDURE p_get_values_between_seq_id (
      p_collection_name   IN     apex_collections.collection_name%TYPE,
      p_seq_id_start      IN     apex_collections.seq_id%TYPE,
      p_seq_Id_end        IN     apex_collections.seq_id%TYPE,
      p_num_values        IN     NUMBER,
      p_calc_method       IN     VARCHAR2 DEFAULT 'LINEAR',
      p_value_start          OUT NUMBER,
      p_value_end            OUT NUMBER,
      p_value_increment      OUT NUMBER)
   IS
   BEGIN
      --This procedure will return the starting value, end value, and increment values inbetween
      --It will parse a collection for seq id's start and end values.
      NULL;


      p_value_increment := 99999;


      BEGIN
         SELECT TO_NUMBER (c005)
           INTO p_value_start
           FROM apex_collections
          WHERE     collection_name = p_collection_name
                AND seq_id = p_seq_id_start;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_value_start := NULL;
      END;

      BEGIN
         SELECT TO_NUMBER (c005)
           INTO p_value_end
           FROM apex_collections
          WHERE collection_name = p_collection_name AND seq_id = p_seq_id_end;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_value_start := NULL;
      END;

      IF p_value_end IS NOT NULL AND p_value_start IS NOT NULL
      THEN
         IF p_calc_method = 'LINEAR'
         THEN
            p_value_increment := (p_value_end - p_value_start) / p_num_values;
         ELSE
            NULL;
         END IF;
      END IF;
   END;

   PROCEDURE p_clean_tsv_zeros (
      p_collection_name IN apex_collections.collection_name%TYPE)
   IS
      --This procedure will clean up zero values in a collection of TSV data
      temp_value             NUMBER;
      temp_value_previous    NUMBER;
      temp_value_next        NUMBER;
      temp_value_average     NUMBER;
      temp_seq_Id_previous   apex_collections.seq_id%TYPE;
      temp_seq_id_next       apex_collections.seq_id%TYPE;
      temp_last_seq_id       apex_collections.seq_id%TYPE;

      temp_last_value        NUMBER;
      temp_next_value        NUMBER;

      suggested_value        NUMBER;
      suggested_i            NUMBER;
      seq_id_breadth         NUMBER;
      val_breadth            NUMBER;
      Seq_id_in_order        NUMBER;
      temp_direction         VARCHAR2 (4) DEFAULT 'ASC';         --ASC or DESC
   BEGIN
      FOR x IN (  SELECT *
                    FROM apex_collections
                   WHERE collection_name = p_collection_name AND c005 = '0'
                ORDER BY seq_id)
      LOOP
         suggested_value := NULL;
         suggested_i := NULL;
         temp_value_previous := NULL;
         temp_value_next := NULL;
         temp_seq_id_next := NULL;
         temp_seq_id_previous := NULL;
         val_breadth := NULL;
         temp_last_seq_id := NULL;
         Seq_id_in_order := NULL;
         temp_direction := 'ASC';


         FOR y
            IN (  SELECT *
                    FROM apex_collections
                   WHERE     collection_name = p_collection_name
                         AND c005 IS NOT NULL
                --                             AND c005 != '0'
                ORDER BY seq_id)
         LOOP
            IF y.seq_id = x.seq_id
            THEN
               --We are at the current value, use the last value
               temp_value_previous := temp_last_value;
               temp_seq_Id_previous := temp_last_seq_id;
            END IF;

            IF     y.seq_id >= x.seq_id
               AND temp_value_next IS NULL
               AND y.c005 IS NOT NULL
               AND y.c005 != '0'
            THEN
               temp_value_next := y.c005;
               temp_seq_Id_next := y.seq_id;
            END IF;



            temp_last_value := y.c005;
            temp_last_seq_id := y.seq_Id;
         END LOOP;



         CASE
            WHEN temp_value_next != 0 AND temp_value_previous != 0
            THEN
               --Determine the breadth of Seq IDs
               seq_id_breadth := ABS (temp_seq_Id_next - temp_seq_id_previous);
               val_breadth := ABS (temp_value_previous - temp_value_next);
               Seq_id_in_order := ABS (temp_seq_id_next - x.seq_id);


               --Determine the suggested value's increment in the order
               IF val_breadth = 0
               THEN
                  suggested_i := 1;
               ELSE
                  suggested_i := ROUND (seq_id_breadth / val_breadth, 4);
               END IF;

               --Determmine the suggested value
               IF temp_value_next >= temp_value_previous
               THEN
                  --Slope is goin up, add the decimal amount
                  temp_direction := 'ASC';
                  suggested_value := temp_value_previous + suggested_i;
               ELSE
                  --Subtract the decimal amount
                  temp_direction := 'DESC';
                  suggested_value := temp_value_next + suggested_i;
               END IF;

               --Round the suggested value
               suggested_value := ROUND (suggested_value, 4);

               APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                  p_collection_name   => p_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 5,
                  p_attr_value        => suggested_value);

               APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                  p_collection_name   => p_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 10,
                  p_attr_value        => 'QUESTIONABLE');

               APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                  p_collection_name   => p_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 12,
                  p_attr_value        =>    'Zero Condition 1-previous/next found good values:'
                                         || 'Temp Previous = '
                                         || temp_value_previous
                                         || '<BR>'
                                         || 'Current Value = '
                                         || x.c005
                                         || '<BR>'
                                         || 'Next Good = '
                                         || temp_value_next
                                         || '<BR>'
                                         || 'Seq ID = '
                                         || temp_seq_Id_previous
                                         || '-->'
                                         || temp_seq_Id_next
                                         || '<BR>'
                                         || 'Suggested i = '
                                         || suggested_i
                                         || '<BR>'
                                         || 'Seq ID Breadth = '
                                         || seq_id_breadth
                                         || '<BR>'
                                         || 'Seq ID in Order = '
                                         || Seq_id_in_order
                                         || '<BR>'
                                         || 'Value Breadth = '
                                         || val_breadth
                                         || '<BR>'
                                         || 'Direction = '
                                         || temp_direction
                                         || '<BR>'
                                         || 'Suggested Val = '
                                         || suggested_value);
            ELSE
               APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                  p_collection_name   => p_collection_name,
                  p_seq               => x.seq_id,
                  p_attr_number       => 12,
                  p_attr_value        =>    'Zero Condition ELSE-previous/next is failed:'
                                         || 'Temp Previous = '
                                         || temp_value_previous
                                         || '<BR>'
                                         || 'Current Value = '
                                         || x.c005
                                         || '<BR>'
                                         || 'Next Good = '
                                         || temp_value_next
                                         || '<BR>'
                                         || 'Seq ID = '
                                         || temp_seq_Id_previous
                                         || '-->'
                                         || temp_seq_Id_next
                                         || '<BR>'
                                         || 'Suggested i = '
                                         || suggested_i
                                         || '<BR>'
                                         || 'Seq ID Breadth = '
                                         || seq_id_breadth
                                         || '<BR>'
                                         || 'Seq ID in Order = '
                                         || Seq_id_in_order
                                         || '<BR>'
                                         || 'Value Breadth = '
                                         || val_breadth
                                         || '<BR>'
                                         || 'Direction = '
                                         || temp_direction
                                         || '<BR>'
                                         || 'Suggested Val = '
                                         || suggested_value);
         END CASE;
      END LOOP;
   END;


   PROCEDURE p_clean_tsv_stdev (
      p_collectioN_name   IN apex_collections.collection_name%TYPE,
      p_stdev_threshold   IN NUMBER DEFAULT 100)
   IS
      temp_max   NUMBER;
      temp_min   NUMBER;
   BEGIN
      --THis procedure will delete records from the APEX collection that cross a stdev threshold

      SELECT MIN (TO_NUMBER (c005)), MAX (TO_NUMBER (c005))
        INTO temp_min, temp_max
        FROM apex_collections
       WHERE     collection_name = p_collection_name
             AND c005 != '0'
             AND c005 IS NOT NULL;



      FOR x IN (  SELECT *
                    FROM apex_collections
                   WHERE collection_name = p_collection_name AND c005 != '0'
                ORDER BY seq_id)
      LOOP
         NULL;
      END LOOP;
   END p_clean_tsv_stdev;

   PROCEDURE p_clear_loc_type_classif (
      p_db_Office_id    IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_code   IN cwms_v_loc.location_code%TYPE,
      p_location_type   IN cwms_v_location_type.location_type%TYPE)
   IS
      temp_locatioN_id   cwms_v_loc.location_id%TYPE;
   BEGIN
      SELECT DISTINCT locatioN_id
        INTO temp_locatioN_id
        FROM cwms_v_Loc
       WHERE     db_Office_id = p_db_office_id
             AND location_code = p_location_code;

      FOR x
         IN (SELECT *
               FROM cwms_v_locatioN_type
              WHERE     locatioN_id = temp_location_id
                    AND Office_id = p_db_office_id
                    AND locatioN_type = p_location_type)
      LOOP
         CASE x.locatioN_type
            WHEN 'NONE'
            THEN
               --Do nothing
               NULL;
            WHEN 'STREAM'
            THEN
               --Delete the stream record in AT_STREAM
               DELETE at_stream
                WHERE stream_locatioN_code = p_location_code;
            WHEN 'PROJECT'
            THEN
               --Delete the project record in AT_PROJECT
               DELETE at_project
                WHERE project_location_code = p_location_code;
            WHEN 'BASIN'
            THEN
               --Delete the basin record in AT_BASIN
               DELETE at_basin
                WHERE basin_location_code = p_locatioN_code;
            WHEN 'OUTLET'
            THEN
               --Delete the outlet record in AT_OUTLET
               DELETE at_outlet
                WHERE outlet_location_code = p_locatioN_code;
            WHEN 'LOCK'
            THEN
               --Delete the lock record in AT_LOCK
               DELETE at_lock
                WHERE lock_location_code = p_location_code;
            WHEN 'EMBANKMENT'
            THEN
               --DELETE the embankment record in at_embankment
               DELETE at_embankment
                WHERE embankment_locatioN_code = p_locatioN_code;
            WHEN 'TURBINE'
            THEN
               DELETE at_turbine
                WHERE turbine_locatioN_code = p_location_code;
            ELSE
               NULL;
         END CASE;
      END LOOP;
   END p_clear_loc_type_classif;


   PROCEDURE p_store_tsc_by_collection (
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_store_rule_code   IN cwms_store_rule.store_rule_code%TYPE)
   IS
      temp_c001            apex_collections.c001%TYPE;

      temp_value           CWMS_T_TSV;
      temp_value_array     CWMS_T_TSV_ARRAY;
      temp_store_rule_id   CWMS_STORE_RULE.STORE_RULE_ID%TYPE;
   BEGIN
      --Initialize the arrays
      temp_value_array := cwms_t_tsv_array ();


      SELECT store_rule_Id
        INTO temp_store_Rule_id
        FROM cwms_store_Rule
       WHERE store_rule_code = p_store_rule_code;



      FOR x
         IN (  SELECT *
                 FROM apex_collections
                WHERE collection_name = p_collection_name AND c010 IS NOT NULL --null values means the API didn't find issues with row
             ORDER BY seq_id)
      LOOP
         --SELECT * FROM cwms_v_quality_code

         --Set the cwms_t_tsv type to the date/time

         CASE
            WHEN x.c005 IS NULL AND x.c010 = 'MISSING'
            THEN
               --Add an empty row
               temp_Value :=
                  cwms_t_tsv (TO_DATE (x.c002, 'DD-MON-YYYY HH24:MI:SS'),
                              TO_NUMBER (x.c005),
                              5                         --5 = screened/missing
                               );
            WHEN x.c005 IS NOT NULL AND x.c010 = 'QUESTIONABLE'
            THEN
               temp_Value :=
                  cwms_t_tsv (TO_DATE (x.c002, 'DD-MON-YYYY HH24:MI:SS'),
                              TO_NUMBER (x.c005),
                              9                  -- 9  = screened/questionable
                               );
            ELSE
               temp_Value :=
                  cwms_t_tsv (TO_DATE (x.c002, 'DD-MON-YYYY HH24:MI:SS'),
                              TO_NUMBER (x.c005),
                              9                         --5 = screened/missing
                               );
         END CASE;

         --Add the record to the array
         temp_value_array.EXTEND ();
         temp_value_array (temp_value_array.LAST) := temp_value;

         temp_c001 := x.c001;
      END LOOP;



      FOR x IN (SELECT cwms_ts_id, db_Office_id, unit_id
                  FROM cwms_v_ts_id
                 WHERE TO_CHAR (ts_code) = temp_c001)
      LOOP
         cwms_ts.store_ts (p_office_id         => x.db_office_id,
                           p_cwms_ts_id        => x.cwms_ts_id,
                           p_units             => x.unit_id,
                           p_timeseries_data   => temp_value_array,
                           p_store_rule        => temp_store_Rule_id,
                           p_override_prot     => cwms_util.false_num,
                           p_versiondate       => cwms_util.non_versioned);
      END LOOP;
   END p_store_tsc_by_collection;



   PROCEDURE p_preload_ll (
      p_db_office_id         IN     cwms_v_locatioN_level.office_id%TYPE,
      p_location_level_id    IN     cwms_v_location_level.location_level_id%TYPE,
      p_level_date           IN     VARCHAR2,
      p_unit_system          IN     cwms_v_loc.unit_system%TYPE DEFAULT 'EN',
      p_delim                IN     VARCHAR2 DEFAULT ':',
      p_base_parameter_id       OUT cwms_v_locatioN_level.base_parameter_id%TYPE,
      p_sub_parameter_id        OUT cwms_v_location_level.sub_Parameter_id%TYPE --                        ,p_parameter_id             OUT cwms_v_location_level.parameter_id%TYPE
                                                                               ,
      p_parameter_type_id       OUT VARCHAR2,
      p_duration_id             OUT cwms_v_locatioN_level.duratioN_id%TYPE,
      p_specified_level_id      OUT cwms_v_location_level.specified_level_id%TYPE,
      p_level_unit_id           OUT cwms_v_location_level.level_unit%TYPE,
      p_Num_points              OUT NUMBER,
      p_single_value            OUT NUMBER,
      p_multiple_values         OUT VARCHAR2)
   IS
      temp_Num                  NUMBER DEFAULT 0;
      temp_specified_level_id   cwms_v_specified_level.specified_level_id%TYPE;
      temp_parameteR_id         cwms_v_ts_id.parameteR_id%TYPE;
      temp_locatioN_id          cwms_v_loc.location_id%TYPE;
      temp_char                 VARCHAR2 (1999);
   BEGIN
      --Determine seasonal vs. constant
      SELECT COUNT (location_level_id)
        INTO temp_num
        FROM cwms_v_Location_level
       WHERE     location_level_id = p_location_level_id
             AND unit_system = p_unit_system
             AND level_date = TO_DATE (p_level_date, 'YYYY/MM/DD HH24MI');


      CASE
         WHEN temp_num = 0
         THEN
            --do nothing
            NULL;

            p_level_unit_id :=
               cwms_util.get_default_units (p_base_parameter_id,
                                            p_unit_system);
         WHEN temp_num = 1
         THEN
            --single record, constant value, non seasonal
            cwms_level.parse_location_level_id (
               p_location_id          => temp_locatioN_id     -- out varchar2,
                                                         ,
               p_parameter_id         => temp_parameteR_id     --out varchar2,
                                                          ,
               p_parameter_type_id    => p_parameter_type_id   --out varchar2,
                                                            ,
               p_duration_id          => p_duration_id         --out varchar2,
                                                      ,
               p_specified_level_id   => temp_specified_level_id --  out varchar2
                                                                ,
               p_location_level_id    => p_locatioN_level_id);

            --SELECT * FROM cwms_v_LocatioN_level WHERE Office_id = 'MVR' and location_level_id LIKE ('AGNI%')

            SELECT DISTINCT
                   base_parameter_id,
                   sub_parameter_id,
                   SUBSTR (
                      location_level_id,
                      (  LENGTH (location_id)
                       + 1
                       + LENGTH (base_parameter_id)
                       + 3
                       + LENGTH (sub_parameter_id)),
                        INSTR (
                           SUBSTR (
                              location_level_id,
                              (  LENGTH (locatioN_id)
                               + 1
                               + LENGTH (base_parameter_id)
                               + 3
                               + LENGTH (sub_parameter_id))),
                           '.')
                      - 1)
                      parameter_type_id,
                   duration_id,
                   specified_level_id,
                   ROUND (constant_level, 6) constant_value,
                   level_unit
              INTO p_base_parameter_id,
                   p_sub_parameter_id,
                   temp_char                            -- p_parameter_type_id
                            ,
                   p_duration_id,
                   p_specified_level_id,
                   p_single_value,
                   p_level_unit_id
              FROM cwms_v_location_level
             WHERE     location_level_id = p_location_level_id
                   AND unit_system = p_unit_system
                   AND level_date =
                          TO_DATE (p_level_date, 'YYYY/MM/DD HH24MI');
         WHEN temp_num > 1
         THEN
            -- Seasonal values

            p_num_points := 0;

            cwms_level.parse_location_level_id (
               p_location_id          => temp_locatioN_id     -- out varchar2,
                                                         ,
               p_parameter_id         => temp_parameteR_id     --out varchar2,
                                                          ,
               p_parameter_type_id    => p_parameter_type_id   --out varchar2,
                                                            ,
               p_duration_id          => p_duration_id         --out varchar2,
                                                      ,
               p_specified_level_id   => temp_specified_level_id --  out varchar2
                                                                ,
               p_location_level_id    => p_locatioN_level_id);


            FOR x
               IN (SELECT base_parameter_id,
                          sub_parameter_id,
                          SUBSTR (
                             location_level_id,
                             (  LENGTH (location_id)
                              + 1
                              + LENGTH (base_parameter_id)
                              + 3
                              + LENGTH (sub_parameter_id)),
                               INSTR (
                                  SUBSTR (
                                     location_level_id,
                                     (  LENGTH (locatioN_id)
                                      + 1
                                      + LENGTH (base_parameter_id)
                                      + 3
                                      + LENGTH (sub_parameter_id))),
                                  '.')
                             - 1)
                             parameter_type_id,
                          duration_id,
                          specified_level_id,
                          level_unit
                     FROM cwms_v_location_level
                    WHERE     location_level_id = p_location_level_id
                          AND unit_system = p_unit_system
                          AND level_date =
                                 TO_DATE (p_level_date, 'YYYY/MM/DD HH24MI'))
            LOOP
               p_base_parameter_id := x.base_parameter_id;
               p_sub_parameter_id := x.sub_parameter_id;
               --p_parameter_type_id  := x.parameter_type_id;
               p_duration_id := x.duration_id;
               p_specified_level_id := x.specified_level_id;
               p_level_unit_id := x.level_unit;


               p_num_points := p_num_points + 1;
            END LOOP;
      END CASE;
   /*
     SELECT * FROM cwms_v_Location_level
WHERE location_level_id = 'AGNI4.Elev-Pool.Inst.0.Flood' and office_id = 'MVR'
   AND level_date = TO_DATE('1900/01/01 0600', 'YYYY/MM/DD HH24MI')
   */

   END;



   PROCEDURE p_preload_Project_Purpose (
      p_db_Office_id       IN     cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id        IN     cwms_v_loc.locatioN_id%TYPE,
      p_delim              IN     VARCHAR2 DEFAULT ',',
      p_purpose_type       IN     VARCHAR2 DEFAULT 'AUTHORIZED',
      p_project_purposes      OUT VARCHAR2)
   IS
   BEGIN
      FOR x
         IN (SELECT *
               FROM cwms_v_loc
              WHERE     db_office_id = p_db_Office_id
                    AND location_id = p_locatioN_id
                    AND unit_system = 'EN')
      LOOP
         --SELECT * FROM cwms_v_project_purpose

         SELECT REPLACE (STRAGG (project_purpose_code), ',', p_delim)
           INTO p_project_purposes
           FROM cwms_v_project_Purpose
          WHERE     project_locatioN_code = x.locatioN_code
                AND purpose_type = p_purpose_type;
      END LOOP;
   END;


   PROCEDURE p_preload_location (
      p_db_office_id          IN     cwms_v_loc.db_office_id%TYPE,
      p_location_id           IN     cwms_v_loc.location_id%TYPE,
      p_location_type_api     IN OUT cwms_v_location_Type.location_type%TYPE,
      p_api_read_only            OUT VARCHAR2,
      p_lock_project_id          OUT VARCHAR2,
      p_num_locs_project_of      OUT NUMBER,
      p_outlet_project_id        OUT cwms_v_project.project_id%TYPE,
      p_turbine_project_id       OUT cwms_v_project.project_id%TYPE)
   IS
      temp_base_location_id   cwms_v_loc.base_location_id%TYPE;
      temp_sub_locatioN_id    cwms_v_loc.sub_Location_id%TYPE;

      temp_num                NUMBER DEFAULT 0;
      temp_location_code      cwms_v_loc.locatioN_code%TYPE;
   BEGIN
      --Set the read only flag to 'T' and then set to false in loop
      p_api_read_only := 'F';

      SELECT base_locatioN_id, sub_locatioN_id, location_code
        INTO temp_base_locatioN_id, temp_sub_location_id, temp_location_code
        FROM cwms_v_loc
       WHERE     locatioN_id = p_location_id
             AND db_office_id = p_db_office_id
             AND unit_system = 'EN';


      -- Set the defaults that might be overwritten later in loops
      IF temp_sub_Location_id IS NOT NULL
      THEN
         p_lock_project_id := temp_base_locatioN_id;
         p_outlet_project_id := temp_base_locatioN_id;
         p_turbine_project_id := temp_base_locatioN_id;
      END IF;



      FOR x
         IN (SELECT *
               FROM cwms_v_locatioN_type
              WHERE     locatioN_id = p_location_id
                    AND office_id = p_db_office_id)
      LOOP
         p_location_type_api := x.location_type;

         --Global Items to preload
         IF temp_sub_locatioN_id IS NOT NULL
         THEN
            --this is a sub location, set the project to the base location and let it be overwritten later
            p_outlet_project_id := temp_base_locatioN_id;
         END IF;


         CASE x.location_type
            WHEN c_str_outlet
            THEN
               NULL;

               BEGIN
                  SELECT project_id
                    INTO p_outlet_project_id
                    FROM cwms_v_outlet
                   WHERE     outlet_id = p_locatioN_id
                         AND office_id = p_db_office_id;


                  p_api_read_only := 'F';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     IF temp_sub_locatioN_id IS NOT NULL
                     THEN
                        --this is a sub location, set the project to the base location and let it be overwritten later
                        p_outlet_project_id := temp_base_locatioN_id;
                     ELSE
                        NULL;
                     END IF;
               END;
            WHEN c_str_turbine
            THEN
               NULL;

               BEGIN
                  SELECT project_id
                    INTO p_turbine_project_id
                    FROM cwms_v_turbine
                   WHERE     turbine_id = p_locatioN_id
                         AND office_id = p_db_office_id;


                  p_api_read_only := 'F';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     IF temp_sub_locatioN_id IS NOT NULL
                     THEN
                        --this is a sub location, set the project to the base location and let it be overwritten later
                        p_turbine_project_id := temp_base_locatioN_id;
                     ELSE
                        NULL;
                     END IF;
               END;
            ELSE
               NULL;
         END CASE;
      END LOOP;

      SELECT t.num_1 + l.num_2
        INTO p_num_locs_project_of
        FROM (SELECT COUNT (project_Id) Num_1
                FROM cwms_v_turbine
               WHERE project_id = p_location_id) t,
             (SELECT COUNT (project_id) num_2
                FROM cwms_v_lock
               WHERE project_id = p_location_id) l;


      --Check for subordinate records



      IF p_location_type_api IN
            ('NONE',
             'BASIN',
             'STREAM',
             'LOCK',
             'PROJECT',
             'EMBANKMENT',
             'OUTLET',
             'SITE',
             'STREAM_LOCATION',
             'STREAM_GAGE',
             'WEATHER_GAGE')
      THEN
         p_api_read_only := 'F';
      ELSE
         p_api_read_only := 'T';
      END IF;



--      SELECT COUNT (lockage_code)
--        INTO temp_num
--        FROM cwms_v_lockage
--       WHERE lock_location_code = temp_locatioN_code;
--
--      IF temp_num > 0
--      THEN
--         p_api_read_only := 'T';
--      END IF;
   /*
   FOR x IN (SELECT *
               FROM cwms_v_location_type
              WHERE office_id   = p_DB_OFFICE_ID
                AND location_id = p_locatioN_id
              ) LOOP
                  IF x.location_type IN ('NONE','BASIN','STREAM','LOCK','PROJECT','EMBANKMENT') THEN
                   P_API_READ_ONLY       := 'F';
                  ELSE
                   P_API_READ_ONLY       := 'T';
                  END IF;
                END LOOP;
   */


   END p_preload_location;

   PROCEDURE p_preload_loc_by_station_5 (
      p_db_office_id     IN     cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_id      IN     cwms_v_loc.locatioN_id%TYPE DEFAULT NULL,
      p_debug_or_plsql   IN     VARCHAR2 DEFAULT 'DEBUG',
      p_fire_sql         IN     VARCHAR2 DEFAULT 'F',
      p_out                 OUT CLOB)
   IS
      temp_clob                 CLOB;
      temp_clob_loop            CLOB;
      temp_clob_debug           CLOB;
      temp_clob_debug_loop      CLOB;
      temp_delim                VARCHAR2 (12) DEFAULT '<BR>';
      temp_num                  NUMBER DEFAULT 0;
      loop_i                    NUMBER DEFAULT 1;
      temp_num_found            NUMBER DEFAULT 0;
      temp_num_not_found        NUMBER DEFAULT 0;
      temp_clob_nws_not_found   CLOB;


      temp_county               CWMS_V_LOC.COUNTY_NAME%TYPE;
      temp_natioN_id            cwms_v_loc.natioN_id%TYPE;
      temp_nearest_city         cwms_v_loc.nearest_city%TYPE;
      temp_state_initial        Cwms_v_loc.state_initial%TYPE;
      temp_time_zone_name       CWMS_V_LOC.time_zone_name%TYPE;
      temp_public_name          cwms_v_Loc.public_name%TYPE;
      temp_start_date           DATE;

      temp_nws_5_id             cwms_v_loc.locatioN_id%TYPE;
   BEGIN
      temp_start_date :=
         TO_DATE (TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI'),
                  'DD/MON/YYYY HH24:MI');


      FOR x
         IN (  SELECT *
                 FROM cwms_v_loc
                WHERE     db_Office_id = p_db_office_id
                      AND CASE
                             WHEN p_location_id IS NULL THEN 'Hello World'
                             ELSE p_locatioN_id
                          END =
                             CASE
                                WHEN p_location_id IS NULL THEN 'Hello World'
                                ELSE locatioN_id
                             END
                      AND (    INSTR (UPPER (locatioN_id), 'ART') = 0
                           AND INSTR (UPPER (locatioN_id), 'TEST') = 0)
                      AND (   LENGTH (locatioN_id) = 5
                           OR LENGTH (sub_LocatioN_id) = 5
                           OR location_id IN
                                 (SELECT location_id
                                    FROM cwms_v_loc_alias
                                   WHERE     db_Office_id = p_db_Office_id
                                         AND category_id = 'Agency Aliases'
                                         AND GROUP_ID = 'NWS Handbook 5 ID'))
                      AND unit_system = 'EN'
                      AND loc_active_Flag = 'T'
             ORDER BY db_Office_id, locatioN_id)
      LOOP
         IF LENGTH (x.location_id) != 5
         THEN
            --Process on NWS Handbook5 Alias

            SELECT alias_id
              INTO temp_nws_5_id
              FROM cwms_v_loc_alias
             WHERE     db_Office_id = p_db_Office_id
                   AND category_id = 'Agency Aliases'
                   AND GROUP_ID = 'NWS Handbook 5 ID'
                   AND location_id = x.location_id;
         ELSE
            temp_nws_5_id := x.location_id;
         END IF;


         NULL;
         temp_clob_loop :=
               '-- '
            || loop_i
            || '. Processing NWS Handbook 5 ID '
            || temp_nws_5_id
            || ' for Location "'
            || x.locatioN_id
            || '"'
            || temp_delim;


         SELECT COUNT (nws_id)
           INTO temp_num
           FROM cwms_station_nws
          WHERE nws_id = temp_nws_5_id;


         temp_clob_loop :=
               temp_clob_loop
            || '-- - Found '
            || temp_num
            || ' NWS Station IDs '
            || temp_delim;

         CASE
            WHEN temp_num = 1
            THEN
               FOR y IN (SELECT nws_id,
                                ROUND (lat, 8) lat,
                                ROUND (lon, 8) lon,
                                nws_name,
                                SUBSTR (nws_name, 1, 57) public_name
                           FROM cwms_station_nws
                          WHERE nws_id = temp_nws_5_id)
               LOOP
                  temp_public_name := y.public_name;

                  p_preload_squery_by_xy (
                     p_lat              => y.lat,
                     p_lon              => y.lon,
                     p_county           => temp_county,
                     p_nation_id        => temp_natioN_id,
                     p_nearest_city     => temp_nearest_city,
                     p_state_initial    => temp_state_initial,
                     p_time_zone_name   => temp_time_zone_name);


                  IF INSTR (temp_nearest_city, '''') > 0
                  THEN
                     temp_nearest_city :=
                        REPLACE (temp_nearest_city, '''', '''''');
                  END IF;

                  temp_clob_loop :=
                        temp_clob_loop
                     || '-- - Setting CWMS Alias "CWMS Agency Aliases" for "NWS Handbook 5 ID" =  "'
                     || y.nws_id
                     || '" NWS Station IDs '
                     || temp_delim
                     || 'cwms_loc.assign_loc_group (
                                                              p_loc_category_id    => '''
                     || 'Agency Aliases'
                     || '''
                                                              ,p_loc_group_id      => '''
                     || 'NWS Handbook 5 ID'
                     || '''
                                                              ,p_location_id       => '''
                     || x.locatioN_id
                     || '''
                                                              ,p_loc_alias_id      => '''
                     || y.nws_id
                     || '''
                                                              ,p_db_office_id      => '''
                     || p_db_office_id
                     || '''
                                                                );'
                     || temp_delim;

                  temp_clob_debug_loop :=
                        temp_clob_debug_loop
                     || 'CWMS NWS Handbook 5 Alias Link Found for "'
                     || y.nws_id
                     || '"'
                     || temp_delim;

                  IF p_fire_sql = 'T'
                  THEN
                     cwms_loc.assign_loc_group (
                        p_loc_category_id   => 'Agency Aliases',
                        p_loc_group_id      => 'NWS Handbook 5 ID',
                        p_location_id       => x.locatioN_id,
                        p_loc_alias_id      => y.nws_id,
                        p_db_office_id      => p_db_office_id);
                  END IF;

                  temp_clob_loop :=
                        temp_clob_loop
                     || temp_delim
                     || '-- - Setting CWMS Location Attributes for '
                     || x.location_id
                     || temp_delim
                     || 'cwms_loc.update_location2 (
                                         p_location_id        => '''
                     || x.location_id
                     || '''
                                        , p_horizontal_datum  => '''
                     || 'NAD83'
                     || '''
                                        , p_latitude          =>  '
                     || y.lat
                     || '
                                        , p_longitude         =>  '
                     || y.lon
                     || '
                                        , p_time_zone_id      => '''
                     || temp_time_zone_name
                     || '''
                                        , p_db_office_id      => '''
                     || x.db_office_id
                     || '''
                                        , p_state_initial     => '''
                     || temp_state_initial
                     || '''
                                        , p_natioN_id         => '''
                     || temp_nation_id
                     || '''
                                        , p_county_name       => '''
                     || temp_county
                     || '''
                                        , p_nearest_city      => '''
                     || temp_nearest_city
                     || '''
                                        , p_public_name       => '''
                     || temp_public_Name
                     || '''
                                        , p_long_Name         => '''
                     || y.nws_name
                     || '''
                                                );';

                  temp_clob_debug_loop :=
                        temp_clob_debug_loop
                     || temp_delim
                     || 'Location attributes in NWS vs. CWMS are:  <BR>
                                      '
                     || f_validate_string ('NAD83', x.long_Name)
                     || '    horizontal_datum  => '
                     || 'NAD83'
                     || ' vs. '
                     || x.horizontal_datum
                     || '<BR>
                                      '
                     || f_validate_string (x.latitude, y.lat)
                     || '   latitude          => '
                     || y.lat
                     || ' vs. '
                     || x.latitude
                     || '<BR>
                                      '
                     || f_validate_string (x.longitude, y.lon)
                     || '   longitude         => '
                     || y.lon
                     || ' vs. '
                     || x.longitude
                     || '<BR>
                                      '
                     || f_validate_string (x.time_zone_name,
                                           temp_time_zone_name)
                     || '   time_zone_id      => '
                     || temp_time_zone_name
                     || ' vs. '
                     || x.time_zone_name
                     || '<BR>
                                      '
                     || f_validate_string (x.db_office_id, x.db_office_id)
                     || '   db_office_id      => '
                     || x.db_office_id
                     || ' vs. '
                     || x.db_office_id
                     || '<BR>
                                      '
                     || f_validate_string (x.state_initial,
                                           temp_state_initial)
                     || '   state_initial     => '
                     || temp_state_initial
                     || ' vs. '
                     || x.state_initial
                     || '<BR>
                                      '
                     || f_validate_string (x.nation_id, temp_nation_id)
                     || '   nation_id         => '
                     || temp_nation_id
                     || ' vs. '
                     || x.nation_id
                     || '<BR>
                                      '
                     || f_validate_string (x.county_name, temp_county)
                     || '   county_name       => '
                     || temp_county
                     || ' vs. '
                     || x.county_name
                     || '<BR>
                                      '
                     || f_validate_string (x.nearest_city, temp_nearest_city)
                     || '   nearest_city      => '
                     || temp_nearest_city
                     || ' vs. '
                     || x.nearest_city
                     || '<BR>
                                      '
                     || f_validate_string (x.public_Name, temp_public_Name)
                     || '   public_name       => '
                     || temp_public_Name
                     || ' vs. '
                     || x.public_name
                     || '<BR>
                                      '
                     || f_validate_string (x.long_Name, y.nws_name)
                     || '   long_Name         => '
                     || y.nws_name
                     || ' vs. '
                     || x.long_name
                     || '<BR>
                                                )"';



                  IF p_fire_sql = 'T'
                  THEN
                     cwms_loc.update_location2 (
                        p_location_id        => x.location_id,
                        p_horizontal_datum   => 'NAD83',
                        p_latitude           => y.lat,
                        p_longitude          => y.lon,
                        p_time_zone_id       => temp_time_zone_name,
                        p_db_office_id       => x.db_office_id,
                        p_state_initial      => temp_state_initial,
                        p_natioN_id          => temp_nation_id,
                        p_county_name        => temp_county,
                        p_nearest_city       => temp_nearest_city,
                        p_public_name        => temp_public_Name,
                        p_long_Name          => y.nws_name);
                  END IF;



                  temp_county := NULL;
                  temp_natioN_id := NULL;
                  temp_nearest_city := NULL;
                  temp_state_initial := NULL;
                  temp_time_zone_name := NULL;
                  temp_public_name := NULL;
               END LOOP;

               temp_num_found := temp_num_found + 1;
            ELSE
               temp_num_not_found := temp_num_not_found + 1;

               IF temp_clob_nws_not_found IS NULL
               THEN
                  temp_clob_nws_not_found :=
                     temp_clob_nws_not_found || '''' || x.locatioN_id || '''';
               ELSE
                  temp_clob_nws_not_found :=
                        temp_clob_nws_not_found
                     || ', '''
                     || x.locatioN_id
                     || '''';
               END IF;
         END CASE;



         IF temp_clob_loop IS NOT NULL
         THEN
            temp_clob :=
               temp_clob || temp_delim || temp_clob_loop || temp_delim;
         END IF;


         IF temp_clob_debug_loop IS NOT NULL
         THEN
            temp_clob_debug :=
                  temp_clob_debug
               || temp_delim
               || temp_clob_debug_loop
               || temp_delim;
         END IF;



         temp_clob_loop := NULL;
         temp_clob_debug_loop := NULL;
         loop_i := loop_i + 1;
      END LOOP;

      CASE p_debug_or_plsql
         WHEN 'DEBUG'
         THEN
            p_out :=
                  '/* Processed for '
               || p_db_office_id
               || ' on '
               || TO_CHAR (temp_start_date, 'DD/MON/YYYY HH24:MI')
               || ' and found '
               || temp_num_found
               || ' of '
               || (loop_i - 1)
               || '. '
               || temp_num_not_Found
               || ' did not have Handbook 5 entries in the NWS Station ID Table USACE_STATION_NWS.'
               || temp_delim
               || ' CWMS Location ID without Handbook 5 Location IDs include: '
               || temp_delim
               || temp_clob_nws_not_found
               || temp_delim
               || '*/'
               || temp_delim
               || 'BEGIN'
               || temp_delim
               || temp_clob_debug
               || temp_delim
               || 'END;'
               || temp_delim
               || ' -- Finished procedure on '
               || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI')
               || '. Duration = '
               || TO_CHAR (ROUND ( ( (SYSDATE - temp_start_date) * 24), 2))
               || ' minutes.';
         WHEN 'PLSQL'
         THEN
            p_out :=
                  '/* Processed for '
               || p_db_office_id
               || ' on '
               || TO_CHAR (temp_start_date, 'DD/MON/YYYY HH24:MI')
               || ' and found '
               || temp_num_found
               || ' of '
               || (loop_i - 1)
               || '. '
               || temp_num_not_Found
               || ' did not have Handbook 5 entries in the NWS Station ID Table USACE_STATION_NWS.'
               || temp_delim
               || ' CWMS Location ID without Handbook 5 Location IDs include: '
               || temp_delim
               || temp_clob_nws_not_found
               || temp_delim
               || '*/'
               || temp_delim
               || 'BEGIN'
               || temp_delim
               || temp_clob
               || temp_delim
               || 'END;'
               || temp_delim
               || ' -- Finished procedure on '
               || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI')
               || '. Duration = '
               || TO_CHAR (ROUND ( ( (SYSDATE - temp_start_date) * 24), 2))
               || ' minutes.';
         ELSE
            p_out := 'Invalid Debug or PLSQL selection';
      END CASE;
   END;

   PROCEDURE p_preload_tsv_page (
      p_ts_code                 IN     cwms_v_ts_id.ts_code%TYPE,
      p_collection_name         IN     apex_collections.collection_name%TYPE,
      p_unit_system             IN     cwms_v_loc.unit_system%TYPE,
      p_reset_tf                IN OUT VARCHAR2,
      p_begin_date              IN     DATE,
      p_end_Date                IN     DATE,
      p_base_Parameter_id          OUT cwms_v_ts_id.base_parameter_id%TYPE,
      p_num_records_in_col         OUT NUMBER,
      p_simple_or_fancy_chart      OUT VARCHAR2)
   IS
      temp_query   VARCHAR2 (1999);
   BEGIN
      SELECT base_parameter_id
        INTO p_base_Parameter_id
        FROM cwms_v_ts_id
       WHERE ts_code = p_ts_code;

      IF p_end_date - p_begin_date > 30
      THEN
         p_simple_or_fancy_chart := 'SIMPLE';
      ELSE
         p_simple_or_fancy_chart := 'FANCY';
      END IF;



      --:P403_TEMP_SQL := temp_query;



      IF p_RESET_TF = 'T'
      THEN
         NULL;
      END IF;



      p_reset_tf := 'F';

      p_num_records_in_col :=
         APEX_COLLECTION.COLLECTION_MEMBER_COUNT (
            p_collection_name => p_collection_name);
   END;

   PROCEDURE p_preload_squery_by_xy (
      p_lat              IN     cwms_v_loc.latitude%TYPE,
      p_lon              IN     cwms_v_loc.longitude%TYPE,
      p_county              OUT cwms_v_loc.county_name%TYPE,
      p_nation_id           OUT cwms_v_loc.nation_id%TYPE,
      p_nearest_city        OUT cwms_v_loc.nearest_city%TYPE,
      p_state_initial       OUT cwms_v_loc.state_initial%TYPE,
      p_time_zone_name      OUT cwms_v_loc.time_zone_name%TYPE)
   IS
      temp_geometry           MDSYS.sdo_geometry;
      temp_time_zone_offset   NUMBER;
   BEGIN
      --This procedure will do a spatial query to CM2 datalayers to get the state/county/nation/nearest city/timezone by XY

      SELECT mdsys.SDO_GEOMETRY (2001,
                                 8265                                   --8307
                                     ,
                                 mdsys.sdo_point_type (p_lon, p_lat, NULL),
                                 NULL,
                                 NULL)
        INTO temp_geometry
        FROM DUAL;



      --Find out what Country the geometry is in
      FOR x IN (SELECT UPPER (c.long_Name) country_name
                  FROM cwms_nation_sp c
                 WHERE SDO_RELATE (c.shape,
                                   temp_geometry,
                                   'mask=anyinteract') = 'TRUE')
      LOOP
         p_natioN_id := x.country_name;
      END LOOP;


      IF p_nation_id = 'UNITED STATES'
      THEN
         --Nearest neighbor for the nearest City
         FOR x IN (SELECT c.city_name,
                          c.state_name,
                          SDO_NN_DISTANCE (1),
                          ROWNUM row_num
                     FROM cwms_v_cities_sp c
                    WHERE     SDO_NN (c.shape,
                                      temp_geometry,
                                      'sdo_num_res=2 unit=MILE',
                                      1) = 'TRUE'
                          AND ROWNUM <= 5)
         LOOP
            IF x.row_Num = 1
            THEN
               p_nearest_city := x.city_name;
            END IF;
         END LOOP;


         --states
         FOR x IN (SELECT c.state_name, state_fips, state_abbr
                     FROM cwms_state_sp c
                    WHERE SDO_RELATE (c.shape,
                                      temp_geometry,
                                      'mask=anyinteract') = 'TRUE')
         LOOP
            p_state_initial := x.state_abbr;
         END LOOP;

         IF p_state_initial IS NULL
         THEN
            NULL;
         --p_state_initial := 'State Not Found with y=' ||p_lat ||' and x= ' || p_lon;
         ELSE
            p_nation_id := 'United States';
            p_natioN_id := UPPER (p_natioN_id);
         END IF;

         --Counties
         FOR x IN (SELECT c.county county_name
                     FROM cwms_v_county_sp c
                    WHERE SDO_RELATE (c.shape,
                                      temp_geometry,
                                      'mask=anyinteract') = 'TRUE')
         LOOP
            p_county := TRIM (REPLACE (x.county_name, 'County', ''));
         END LOOP;

         IF p_county IS NULL
         THEN
            NULL;
         --p_county  := 'County Not Found with y(lat)=' ||p_lat ||' and x(lon)= ' || p_lon;
         END IF;
      ELSE
         p_state_initial := NULL;
         p_county := NULL;
         p_nearest_city := NULL;
      END IF;

      --Timezone
      FOR x IN (SELECT c.zone zone_offset
                  FROM cwms_v_time_zone_sp c
                 WHERE SDO_RELATE (c.shape,
                                   temp_geometry,
                                   'mask=anyinteract') = 'TRUE')
      LOOP
         temp_time_zone_offset := x.zone_offset;

         BEGIN
            SELECT time_zone_name
              INTO p_time_zone_name
              FROM mv_time_zone
             WHERE     time_Zone_name IN
                          ('US/Eastern',
                           'US/Central',
                           'US/Mountain',
                           'US/Pacific') --,'Eastern Standard Time','Central Standard Time','Mountain Standard Time','Pacific Standard Time','Coordinated Universal Time')
                   AND EXTRACT (HOUR FROM UTC_OFFSET) = temp_time_zone_offset;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               -- A Timezone has been found but it's not a US one, so lookup any of them
                  FOR z IN (

               SELECT DISTINCT time_zone_name
                 FROM mv_time_zone
                WHERE EXTRACT (HOUR FROM UTC_OFFSET) = temp_time_zone_offset
                ORDER BY 1 ASC
                 ) LOOP

                    p_time_zone_name := z.time_zone_name;
                   END LOOP;

         END;
      END LOOP;

      IF p_time_zone_name IS NULL
      THEN
         NULL;
      --p_time_zone_name  := 'Timnezone Not Found with y(lat)=' ||p_lat ||' and x(lon)= ' || p_lon;
      END IF;



      NULL;
   END;

   PROCEDURE p_load_tsv_col (
      p_ts_code           IN cwms_v_tsv.ts_code%TYPE,
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_begin_date        IN DATE,
      p_end_date          IN DATE,
      p_unit_system       IN cwms_v_loc.unit_system%TYPE)
   IS
      temp_query   VARCHAR2 (1999);
   BEGIN
      IF APEX_COLLECTION.COLLECTION_EXISTS (
            p_collection_name => p_collection_name) = TRUE
      THEN
         APEX_COLLECTION.DELETE_COLLECTION (
            p_collection_name => p_collection_name);
      END IF;


      IF p_unit_system = 'EN'
      THEN
         temp_query :=
               'SELECT tsv.ts_code, TO_CHAR(tsv.date_Time, '''
            || 'DD-MON-YYYY HH24:MI'
            || ''') date_Time, tsv.versioN_date, tsv.data_entry_date,                 TO_NUMBER(cwms_util.convert_units(
                                                tsv.value
                                              , tsi.unit_id
                                              , cwms_util.get_default_units (tsi.parameter_id,
                                                                              '''
            || 'EN'
            || '''
                                                                        )
                                                )
                                  ) value, tsv.quality_code, tsv.start_date, tsv.end_date
        FROM cwms_v_tsv tsv
           , cwms_v_ts_id tsi
         WHERE tsi.ts_code = tsv.ts_code '
            || '   AND tsi.ts_code    = '
            || TO_CHAR (p_ts_CODE)
            || '   AND tsv.date_time >= '''
            || TO_CHAR (p_begin_date, 'DD/MON/YYYY')
            || ''''
            || '   AND tsv.date_time <= '''
            || TO_CHAR (p_end_date, 'DD/MON/YYYY')
            || ''''
            --           || '   AND rownum = 1'
            || ' ORDER BY tsv.date_Time ASC';
      ELSE
         temp_query :=
               'SELECT tsv.ts_code, TO_CHAR(tsv.date_Time, '''
            || 'DD-MON-YYYY HH24:MI'
            || ''') date_Time, tsv.versioN_date, tsv.data_entry_date, ROUND(TO_NUMBER(tsv.value),6) value, tsv.quality_code, tsv.start_date, tsv.end_date
        FROM cwms_v_tsv tsv
           , cwms_v_ts_id tsi
         WHERE tsi.ts_code = tsv.ts_code '
            || '   AND tsi.ts_code    = '
            || TO_CHAR (p_ts_CODE)
            || '   AND tsv.date_time >= '''
            || TO_CHAR (p_begin_date, 'DD/MON/YYYY')
            || ''''
            || '   AND tsv.date_time <= '''
            || TO_CHAR (p_end_date, 'DD/MON/YYYY')
            || ''''
            --   || '   AND rownum = 1'
            || ' ORDER BY tsv.date_Time ASC';
      END IF;

      --Create a collection and populate it
      APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY (
         p_collection_name   => p_collection_name,
         p_query             => temp_query,
         p_generate_md5      => 'NO');


      NULL;
   END;


   PROCEDURE p_load_loc_by_station_5 (
      p_db_office_id   IN cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id    IN cwms_v_loc.locatioN_id%TYPE DEFAULT NULL)
   IS
      temp_num   NUMBER DEFAULT 0;
   BEGIN
      --This procedure will obtain information about a location when the locatioN_id = a station5 id



      FOR x
         IN (SELECT *
               FROM cwms_v_loc
              WHERE     db_Office_id = p_db_office_id
                    AND db_office_id = 'MVR'
                    AND CASE
                           WHEN p_location_id IS NULL THEN 'Hello World'
                           ELSE p_locatioN_id
                        END =
                           CASE
                              WHEN p_location_id IS NULL THEN 'Hello World'
                              ELSE locatioN_id
                           END
                    AND (LENGTH (locatioN_id) = 5)
                    AND INSTR (locatioN_id, 'Art') = 0
                    AND unit_system = 'EN')
      LOOP
         SELECT COUNT (nws_id)
           INTO temp_num
           FROM cwms_station_nws
          WHERE nws_id = x.locatioN_id;

         IF temp_num > 0
         THEN
            FOR y IN (SELECT nws_id,
                             lat,
                             lon,
                             CWMS_CMA.f_get_tz_by_xy (lat, lon) tz
                        FROM cwms_station_nws
                       WHERE nws_id = x.locatioN_id)
            LOOP
               cwms_loc.assign_loc_group (
                  p_loc_category_id   => 'Agency Aliases',
                  p_loc_group_id      => 'NWS Handbook 5 ID',
                  p_location_id       => x.locatioN_id,
                  p_loc_alias_id      => y.nws_id,
                  p_db_office_id      => p_db_office_id);
               cwms_loc.update_location2 (
                  p_location_id        => x.location_id,
                  p_horizontal_datum   => 'WSG84',
                  p_latitude           => y.lat,
                  p_longitude          => y.lon,
                  p_time_zone_id       => y.tz,
                  p_db_office_id       => x.db_office_id);
            END LOOP;
         END IF;



         temp_num := 0;
      END LOOP;



      NULL;
   END;


   PROCEDURE p_load_a2w_by_location (
      p_db_office_id           IN     at_a2w_ts_codes_by_loc.db_office_id%TYPE,
      p_location_id            IN     at_a2w_ts_codes_by_loc.db_office_id%TYPE,
      p_display_flag           IN     at_a2w_ts_codes_by_loc.display_flag%TYPE,
      p_notes                  IN     at_a2w_ts_codes_by_loc.notes%TYPE,
      p_num_ts_codes           IN     at_a2w_ts_codes_by_loc.num_ts_codes%TYPE,
      p_ts_code_elev           IN     at_a2w_ts_codes_by_loc.ts_code_elev%TYPE,
      p_ts_code_inflow         IN     at_a2w_ts_codes_by_loc.ts_code_inflow%TYPE,
      p_ts_code_outflow        IN     at_a2w_ts_codes_by_loc.ts_code_outflow%TYPE,
      p_ts_code_sur_release    IN     at_a2w_ts_codes_by_loc.ts_code_sur_release%TYPE,
      p_ts_code_precip         IN     at_a2w_ts_codes_by_loc.ts_code_precip%TYPE,
      p_ts_code_stage          IN     at_a2w_ts_codes_by_loc.ts_code_stage%TYPE,
      p_ts_code_stor_drought   IN     at_a2w_ts_codes_by_loc.ts_code_stor_drought%TYPE,
      p_ts_code_stor_Flood     IN     at_a2w_ts_codes_by_loc.ts_code_stor_Flood%TYPE,
      p_ts_code_elev_tw        IN     at_a2w_ts_codes_by_loc.ts_code_elev_tw%TYPE,
      p_ts_code_stage_tw       IN     at_a2w_ts_codes_by_loc.ts_code_stage_tw%TYPE,
      p_ts_code_rule_Curve_elev IN     at_a2w_ts_codes_by_loc.ts_code_rule_curve_elev%TYPE,
      p_ts_code_power_Gen       IN    at_a2w_ts_codes_By_loc.ts_code_power_Gen%TYPE,
      p_ts_code_temp_air        IN    at_a2w_ts_codes_by_loc.ts_code_temp_air%TYPE,
      p_ts_code_temp_water      IN    at_a2w_ts_codes_by_loc.ts_code_temp_water%TYPE,
      p_ts_code_do              IN    at_a2w_Ts_codes_by_loc.ts_code_do%TYPE,
      p_ts_code_ph              IN    at_a2w_ts_codes_by_loc.ts_code_ph%TYPE,
      p_ts_code_cond            IN    at_a2w_Ts_codes_By_loc.ts_code_cond%TYPE,
      p_ts_code_wind_dir        IN    at_a2w_ts_codes_By_loc.ts_code_wind_dir%TYPE,
      p_ts_code_wind_speed      IN    at_a2w_ts_codes_By_loc.ts_code_wind_speed%TYPE,
      p_ts_code_volt            in   at_a2w_ts_codes_By_loc.ts_code_volt%TYPE,
      p_ts_code_pct_flood       in   at_a2w_ts_codes_By_loc.ts_code_pct_flood%TYPE,
      p_ts_code_pct_con         in   at_a2w_ts_codes_By_loc.ts_code_pct_con%TYPE,
      p_ts_code_irrad           in   at_a2w_ts_codes_By_loc.ts_code_irrad%TYPE,
      p_ts_code_evap            in   at_a2w_ts_codes_By_loc.ts_code_evap%TYPE,
      p_rating_code_elev_stor   IN    NUMBER,
      p_rating_code_elev_area   IN    NUMBER,
      p_rating_code_outlet_Flow IN    NUMBER,
      p_ts_code_opening         IN    at_a2w_ts_codes_By_loc.ts_code_opening%TYPE,
      p_opening_source_obj      IN    VARCHAR2,
      p_lake_summary_tf         IN     at_a2w_ts_codes_by_loc.lake_summary_Tf%TYPE,
      p_error_msg                 OUT VARCHAR2)
   IS
      temp_location_code   cwms_v_loc.location_code%TYPE;
   BEGIN
      p_error_msg := NULL;

      SELECT location_code
        INTO temp_location_code
        FROM cwms_v_loc
       WHERE     Unit_system = 'EN'
             AND location_id = p_location_id
             AND db_Office_id = p_db_Office_id;


      UPDATE at_a2w_ts_codes_by_loc
         SET date_refreshed          = SYSDATE,
             display_flag            = p_display_flag,
             notes                   = p_notes,
             num_ts_codes            = p_num_ts_codes,
             ts_code_elev            = p_ts_code_elev,
             ts_code_inflow          = p_ts_code_inflow,
             ts_code_outflow         = p_ts_code_outflow,
             ts_code_sur_release     = p_ts_code_sur_release,
             ts_code_precip          = p_ts_code_precip,
             ts_code_stage           = p_ts_code_stage,
             ts_code_stor_drought    = p_ts_code_stor_drought,
             ts_code_stor_flood      = p_ts_code_stor_flood,
             ts_code_elev_tw         = p_ts_code_elev_tw,
             ts_code_stage_tw        = p_ts_code_stage_tw,
             ts_code_rule_curve_Elev = p_ts_code_rule_curve_elev,
             ts_code_power_gen       = p_ts_code_power_Gen,
             ts_code_temp_air        = p_ts_code_temp_air,
             ts_code_temp_water      = p_ts_code_temp_water,
             ts_code_do              = p_ts_code_do, 
             ts_code_wind_dir        = p_ts_code_wind_dir,
             ts_code_wind_speed      = p_ts_code_wind_Speed,
             ts_code_volt            = p_ts_code_volt,
             ts_code_pct_flood       = p_ts_code_pct_flood,
             ts_code_pct_con         = p_ts_code_pct_con,
             ts_code_irrad           = p_ts_code_irrad,
             ts_code_evap            = p_ts_code_evap,
             rating_code_elev_stor   = p_rating_code_elev_stor ,
	     rating_code_elev_area   = p_rating_code_elev_area,
             rating_code_outlet_flow = p_rating_code_outlet_Flow,
             opening_source_obj      = p_opening_source_obj,
             lake_summary_tf         = p_lake_summary_tf
       WHERE  db_office_id = p_db_office_id
         AND locatioN_code = temp_location_code;

  EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT
           INTO at_a2w_ts_codes_by_loc (db_Office_id,
                                        location_code,
                                        date_refreshed)
         VALUES (p_db_office_id, temp_location_code, SYSDATE);


         UPDATE at_a2w_ts_codes_by_loc
            SET date_refreshed       = SYSDATE,
                display_flag         = p_display_flag,
                notes                = p_notes,
                num_ts_codes         = p_num_ts_codes,
                ts_code_elev         = p_ts_code_elev,
                ts_code_inflow       = p_ts_code_inflow,
                ts_code_outflow      = p_ts_code_outflow,
                ts_code_sur_release  = p_ts_code_sur_release,
                ts_code_precip       = p_ts_code_precip,
                ts_code_stage        = p_ts_code_stage,
                ts_code_stor_drought = p_ts_code_stor_drought,
                ts_code_stor_flood   = p_ts_code_stor_flood,
                ts_code_elev_tw      = p_ts_code_elev_tw,
                ts_code_stage_tw     = p_ts_code_stage_tw,
                ts_code_rule_curve_Elev = p_ts_code_rule_curve_elev,
                ts_code_power_Gen       = p_ts_code_power_Gen       ,
                ts_code_temp_air        = p_ts_code_temp_air        ,
                ts_code_temp_water      = p_ts_code_temp_water      ,
                ts_code_do              = p_ts_code_do              ,
                ts_code_wind_dir        = p_ts_code_wind_dir,
                ts_code_wind_speed      = p_ts_code_wind_Speed,
             ts_code_volt            = p_ts_code_volt,
             ts_code_pct_flood       = p_ts_code_pct_flood,
             ts_code_pct_con         = p_ts_code_pct_con,
             ts_code_irrad           = p_ts_code_irrad,
             ts_code_evap            = p_ts_code_evap,
                rating_code_elev_stor   = p_rating_code_elev_stor  ,
	        rating_code_elev_area   = p_rating_code_elev_area  ,
                rating_code_outlet_flow = p_rating_code_outlet_Flow,
                opening_source_obj      = p_opening_source_obj     ,
                lake_summary_tf         = p_lake_summary_tf
          WHERE db_office_id  = p_db_office_id
            AND locatioN_code = temp_location_code;
      WHEN OTHERS
      THEN
         p_error_msg := SQLERRM;
   END;

   PROCEDURE p_load_location (
      p_db_office_id                  IN     cwms_v_loc.db_Office_id%TYPE,
      p_location_code                 IN     cwms_v_loc.locatioN_type%TYPE,
      p_location_type_new             IN     cwms_v_locatioN_type.locatioN_type%TYPE,
      p_basin_id                      IN     cwms_v_basin.basin_id%TYPE,
      p_basin_fail_if_exists          IN     VARCHAR2,
      p_basin_ignore_nulls            IN     VARCHAR2,
      p_basin_parent_basin_id         IN     cwms_v_basin.parent_basin_id%TYPE,
      p_basin_sort_order              IN     cwms_v_basin.sort_order%TYPE,
      p_basin_primary_stream_id       IN     cwms_v_basin.primary_stream_id%TYPE,
      p_basin_total_drainage_area     IN     cwms_v_basin.total_drainage_area%TYPE,
      p_basin_contrib_drainage_area   IN     cwms_v_basin.CONTRIBUTING_DRAINAGE_AREA%TYPE,
      p_basin_area_unit               IN     cwms_v_basin.area_unit%TYPE,
      p_embank_project_id             IN     cwms_v_embankment.project_id%TYPE,
      p_embank_struct_type_code       IN     cwms_v_embankment.structure_type_code%TYPE,
      p_embank_us_prot_type_code      IN     cwms_v_embankment.upstream_prot_type_code%TYPE,
      p_embank_us_sideslope           IN     cwms_v_embankment.upstream_sideslope%TYPE,
      p_embank_ds_prot_type_code      IN     cwms_v_embankment.downstream_prot_Type_code%TYPE,
      p_embank_ds_sideslope           IN     cwms_v_embankment.downstream_sideslope%TYPE,
      p_embank_length                 IN     cwms_v_embankment.structure_length%TYPE,
      p_embank_height                 IN     cwms_v_embankment.height_max%TYPE,
      p_embank_width                  IN     cwms_v_embankment.top_width%TYPE,
      p_embank_unit_id                IN     cwms_v_embankment.unit_id%TYPE,
      p_lock_project_id               IN     cwms_v_lock.project_id%TYPE, --:P36_PROJECT_LOCATION_ID --project_location_ref,
      p_lock_vol_per_lockage          IN     cwms_v_lock.volume_per_lockage%TYPE, --volume_per_lockage,
      p_lock_vol_units_id             IN     cwms_v_lock.volume_unit_id%TYPE, --volume_units_id
      p_lock_lock_width               IN     cwms_v_lock.lock_width%TYPE --lock_width
                                                                        ,
      p_lock_lock_length              IN     cwms_v_lock.lock_length%TYPE --lock_length
                                                                         ,
      p_lock_min_draft                IN     cwms_v_lock.minimum_draft%TYPE --minimum_draft
                                                                           ,
      p_lock_norm_lock_lift           IN     cwms_v_lock.normal_lock_lift%TYPE --normal_lock_lift
                                                                              ,
      p_lock_units_id                 IN     cwms_v_lock.length_unit_id%TYPE,
      p_prj_authorizing_law           IN     cwms_v_project.authorizing_law%TYPE --authorizing_law     VARCHAR2(32)
                                                                                ,
      p_prj_fed_cost                  IN     cwms_v_project.federal_cost%TYPE --federal_cost       NUMBER
                                                                             ,
      p_prj_nonfed_cost               IN     cwms_v_project.nonfederal_cost%TYPE --nonfederal_cost    NUMBER
                                                                                ,
      p_prj_owner                     IN     cwms_v_project.project_owner%TYPE --project_owner
                                                                              ,
      p_prj_near_gage_Loc_id          IN     cwms_v_project.near_gage_locatioN_id%TYPE,
      p_prj_pump_back_loc_id          IN     CWMS_V_PROJECT.PUMP_BACK_LOCATION_ID%TYPE,
      p_prj_purposes                  IN     VARCHAR2,
      p_prj_hydro_desc                IN     cwms_v_project.HYDROPOWER_DESCRIPTION%TYPE --hydropower_description
                                                                                       ,
      p_prj_sedimet_desc              IN     cwms_v_project.SEDIMENTATION_DESCRIPTION%TYPE --sedimentation_description
                                                                                          ,
      p_prj_dwnstr_urban              IN     cwms_v_project.downstream_urban_description%TYPE --downstream_urban_description VARCHAR(255)
                                                                                             ,
      p_prj_bank_full_cap_desc        IN     cwms_v_project.bank_full_capacity_description%TYPE --bank_full_capacity_description VARCHAR(255)
                                                                                               ,
      p_prj_yield_time_frame_start    IN     cwms_v_project.yield_time_frame_start%TYPE --yield_time_frame_start DATE,
                                                                                       ,
      p_prj_yield_time_frame_end      IN     cwms_v_project.yield_time_frame_end%TYPE,
      p_outlet_project_id             IN     cwms_v_loc.location_id%TYPE,
      p_strm_fail_if_exists           IN     VARCHAR2 DEFAULT 'F'    --=> 'F',
                                                                 ,
      p_strm_ignore_nulls             IN     VARCHAR2 DEFAULT 'T'    --=> 'T',
                                                                 ,
      p_strm_station_units            IN     cwms_v_stream.unit_id%TYPE --=> :P36_STREAM_UNITS_LENGTH,
                                                                       ,
      p_strm_stationing_starts_ds     IN     VARCHAR2  --=> :P36_ZERO_STATION,
                                                     ,
      p_strm_flows_into_stream        IN     cwms_v_loc.locatioN_code%TYPE --=> confluence_stream_id,  --:P36_RECEIVING_STREAM_CODE,
                                                                          ,
      p_strm_flows_into_station       IN     cwms_v_stream.confluence_station%TYPE --=> :P36_CONFLUENCE_STATION,
                                                                                  ,
      p_strm_flows_into_bank          IN     cwms_v_stream.confluence_bank%TYPE --=> :P36_CONFLUENCE_BANK,
                                                                               ,
      p_strm_diverts_from_stream      IN     cwms_v_loc.locatioN_code%TYPE --=> diverting_stream_id, --:P36_DIVERTING_STREAM_CODE,
                                                                          ,
      p_strm_diverts_from_station     IN     cwms_v_stream.diversion_station%TYPE --=> :P36_DIVERSION_STATION,
                                                                                 ,
      p_strm_diverts_from_bank        IN     cwms_v_stream.diversioN_bank%TYPE -- => :P36_DIVERSION_BANK,
                                                                              ,
      p_strm_length                   IN     CWMS_V_STREAM.STREAM_LENGTH%TYPE -- => :P36_STREAM_LENGTH,
                                                                             ,
      p_strm_average_slope            IN     cwms_v_stream.average_slope%TYPE -- => :P36_AVERAGE_SLOPE,
                                                                             ,
      p_strm_comments                 IN     cwms_v_stream.comments%TYPE -- => :P36_COMMENTS ,
                                                                        ,
      p_turbine_project_id            IN     cwms_v_turbine.project_id%TYPE,
      p_unit_system                   IN     cwms_v_loc.unit_system%TYPE,
      p_debug                            OUT VARCHAR2)
   IS
      /*
       THis procedure will load all the page elements in location home to the database
      */

      --Global API Stuff
      temp_fail_on_exists       VARCHAR2 (1) DEFAULT 'F';

      --DESC cwms_v_project
      --Global Objects
      temp_location_id          cwms_v_loc.location_id%TYPE;
      temp_base_location_id     cwms_v_loc.base_location_id%TYPE;
      temp_sub_locatioN_id      cwms_v_loc.sub_location_id%TYPE;
      temp_locatioN_type_api    cwms_v_location_type.location_type%TYPE;

      --Lock objects
      lock_project_id           location_ref_t;
      lock_loc_obj              locatioN_obj_t;
      lock_obj                  lock_obj_t;

      --Project objects
      pump_back_location_obj    location_obj_t;
      near_gage_location_obj    location_obj_t;
      project_obj               project_obj_t;
      project_loc_obj           location_obj_t;

      pump_back_location_code   cwms_v_loc.Location_code%TYPE;
      near_gage_locatioN_code   cwms_v_loc.location_code%TYPE;


      --Outlet objects
      l_outlet                  project_structure_obj_t;
      Outlet_project_loc        location_ref_t;
      outlet_structure_loc      location_obj_t;
      outlet_char_ref           characteristic_ref_t;


      --Embankment objects
      embank_prj_loc_obj        cwms_t_location_ref;
      embank_loc_ref            cwms_t_location_ref;
      embank_loc_obj            cwms_t_location_obj;
      embank_obj                cwms_t_embankment_obj;
      embank_structure_type     cwms_t_lookup_type_obj;
      embank_US_prot_type       cwms_t_lookup_type_obj;
      embank_DS_prot_type       cwms_t_lookup_type_obj;
   BEGIN
      --Get the Location ID For API calls
      SELECT DISTINCT location_id
        INTO temp_locatioN_id
        FROM cwms_v_loc
       WHERE     db_office_id = p_db_office_id
             AND locatioN_code = p_locatioN_code;

      --Check to see what the current API classification is and clear it if needed

      SELECT locatioN_type
        INTO temp_locatioN_type_api
        FROM cwms_v_location_type
       WHERE locatioN_id = temp_location_id;

      IF     temp_location_type_api != p_location_type_new
         AND temp_location_type_api NOT IN ('SITE')
      THEN
         p_clear_loc_type_classif (
            p_db_Office_id    => p_db_office_id,
            p_locatioN_code   => p_location_code,
            p_location_type   => temp_location_type_api);
      END IF;


      --Add the records if needed

      IF p_location_type_new IN
            (c_str_turbine, c_str_outlet, c_str_embankment)
      THEN
         p_load_Location_kind (
            p_locatioN_id            => temp_locatioN_id,
            p_location_kind_id_new   => p_location_type_new,
            p_project_id             => CASE p_location_type_new
                                          WHEN c_str_embankment
                                          THEN
                                             p_embank_project_id
                                          WHEN c_str_outlet
                                          THEN
                                             p_outlet_project_id
                                          WHEN c_str_turbine
                                          THEN
                                             p_turbine_project_id
                                          ELSE
                                             NULL
                                       END,
            p_structure_Type_code    => p_embank_struct_type_code,
            p_db_Office_id           => p_db_office_id);
      END IF;



      CASE p_locatioN_type_new
         WHEN c_str_outlet
         THEN
            cwms_outlet.store_outlet (p_outlet           => l_outlet,
                                      p_rating_group     => NULL,
                                      p_fail_if_exists   => 'F');
         WHEN c_str_basin
         THEN
            cwms_apex.aa1 ('entering cwms_basin.store_basin');
            cwms_basin.store_basin (
               p_basin_id                     => temp_location_id,
               p_fail_if_exists               => p_basin_fail_if_exists,
               p_ignore_nulls                 => p_basin_ignore_nulls,
               p_parent_basin_id              => p_basin_parent_basin_id,
               p_sort_order                   => p_basin_sort_order,
               p_primary_stream_id            => p_basin_primary_stream_id,
               p_total_drainage_area          => p_basin_total_drainage_area,
               p_contributing_drainage_area   => p_basin_contrib_drainage_area,
               p_area_unit                    => p_basin_area_unit,
               p_office_id                    => p_db_office_id);
            cwms_apex.aa1 ('exiting cwms_basin.store_basin');
         WHEN c_str_embankment
         THEN
            NULL;

            UPDATE at_embankment
               SET height_max =
                      cwms_util.convert_units (p_embank_height,
                                               p_embank_unit_id,
                                               'm'),
                   top_width =
                      cwms_util.convert_units (p_embank_width,
                                               p_embank_unit_id,
                                               'm'),
                   structure_length =
                      cwms_util.convert_units (p_embank_length,
                                               p_embank_unit_id,
                                               'm'),
                   structure_type_code = p_embank_struct_type_code,
                   downstream_prot_type_code = p_embank_ds_prot_Type_code,
                   downstream_sideslope = p_embank_ds_sideslope,
                   upstream_prot_type_code = p_embank_us_prot_type_code,
                   upstream_sideslope = p_embank_us_sideslope
             WHERE embankment_location_code = p_location_code;
         WHEN c_str_lock
         THEN
            IF INSTR (p_lock_project_id, '-') = 0
            THEN
               lock_project_id :=
                  location_ref_t (p_lock_project_id, NULL, p_db_office_id);
            ELSE
               lock_project_id :=
                  location_ref_t (
                     SUBSTR (p_lock_project_id,
                             1,
                             INSTR (p_lock_project_id, '-') - 1),
                     SUBSTR (p_lock_project_id,
                             INSTR (p_lock_project_id, '-') + 1),
                     p_db_office_id);
            END IF;

            SELECT base_locatioN_id, sub_locatioN_id
              INTO temp_base_location_id, temp_sub_location_id
              FROM Cwms_v_loc
             WHERE     Unit_system = p_unit_system
                   AND locatioN_code = p_location_code;

            lock_loc_obj :=
               location_obj_t (
                  locatioN_ref_t (temp_base_location_id,
                                  temp_sub_location_id,
                                  p_db_office_id));

            lock_obj :=
               lock_obj_t (lock_project_id --:P36_PROJECT_LOCATION_ID --project_location_ref
                                          ,
                           lock_loc_obj --:P36_LOCATION_ID_EDIT    --lock_location
                                       ,
                           p_lock_vol_per_lockage         --volume_per_lockage
                                                 ,
                           p_lock_vol_units_id               --volume_units_id
                                              ,
                           p_lock_lock_width                      --lock_width
                                            ,
                           p_lock_lock_length                    --lock_length
                                             ,
                           p_lock_min_draft                    --minimum_draft
                                           ,
                           p_lock_norm_lock_lift            --normal_lock_lift
                                                ,
                           p_lock_units_id                          --units_id
                                          );

            cwms_lock.store_lock (p_lock             => lock_obj,
                                  p_fail_if_exists   => temp_fail_on_exists);
         WHEN c_str_project
         THEN
            FOR x
               IN (SELECT location_id,
                          base_Location_id,
                          db_Office_id,
                          sub_Location_id
                     FROM cwms_v_Loc
                    WHERE     db_Office_id = p_db_Office_id
                          AND locatioN_code = p_location_code
                          AND unit_system = p_unit_system)
            LOOP
               project_loc_obj :=
                  location_obj_t (
                     locatioN_ref_t (x.base_locatioN_id,
                                     x.sub_location_id,
                                     x.db_office_id));
            END LOOP;

            FOR x
               IN (SELECT location_code,
                          base_Location_id,
                          sub_locatioN_id,
                          db_office_id
                     FROM cwms_v_loc
                    WHERE     location_id = p_prj_pump_back_loc_id
                          AND unit_system = p_unit_system
                          AND db_office_id = p_db_office_id)
            LOOP
               pump_back_location_obj :=
                  location_obj_t (locatioN_ref_t (x.location_code));
            --near_gage_location_obj := pump_back_locatioN_obj;

            END LOOP;

            FOR x
               IN (SELECT location_code,
                          base_Location_id,
                          sub_locatioN_id,
                          db_office_id
                     FROM cwms_v_loc
                    WHERE     location_id = p_prj_near_gage_Loc_id
                          AND unit_system = p_unit_system
                          AND db_office_id = p_db_office_id)
            LOOP
               near_gage_location_obj :=
                  location_obj_t (locatioN_ref_t (x.location_code));
            END LOOP;

            project_obj :=
               cwms_20.project_obj_t (project_loc_obj         --location_obj_t
                                                     ,
                                      pump_back_location_obj  --location_obj_t
                                                            ,
                                      near_gage_location_obj --near_gage_location_obj          --location_obj_t
                                                            ,
                                      P_PRJ_AUTHORIZING_LAW --authorizing_law     VARCHAR2(32)
                                                           ,
                                      NULL                    --cost_year DATE
                                          ,
                                      p_PRJ_FED_COST --federal_cost       NUMBER
                                                    ,
                                      P_PRJ_NONFED_COST --nonfederal_cost    NUMBER
                                                       ,
                                      NULL         --federal_om_cost    NUMBER
                                          ,
                                      NULL         --nonfederal_om_cost NUMBER
                                          ,
                                      'Dollars'                --cost_units_id
                                               ,
                                      'Created via CMA on: ' || SYSDATE --  || p_prj_comments     --remarks
                                                                       ,
                                      P_PRJ_OWNER              --project_owner
                                                 ,
                                      P_PRJ_HYDRO_DESC --hydropower_description
                                                      ,
                                      P_PRJ_SEDIMET_DESC --sedimentation_description
                                                        ,
                                      P_PRJ_DWNSTR_URBAN --downstream_urban_description VARCHAR(255)
                                                        ,
                                      P_PRJ_BANK_FULL_CAP_DESC --bank_full_capacity_description VARCHAR(255)
                                                              ,
                                      P_PRJ_YIELD_TIME_FRAME_START --yield_time_frame_start DATE,
                                                                  ,
                                      P_PRJ_YIELD_TIME_FRAME_END --yield_time_frame_end DATE
                                                                );


            cwms_project.store_project (
               p_project          => project_obj,
               p_fail_if_exists   => temp_fail_on_exists);

            p_load_project_purpose (p_db_office_id       => p_db_office_id,
                                    p_locatioN_id        => temp_locatioN_id,
                                    p_project_purposes   => p_prj_purposes,
                                    p_delim              => ':');
         WHEN c_str_stream
         THEN
            cwms_stream.store_stream (
               p_stream_id              => temp_locatioN_id,
               p_fail_if_exists         => p_strm_fail_if_exists,
               p_ignore_nulls           => p_strm_ignore_nulls,
               p_station_unit           => p_strm_station_units,
               p_stationing_starts_ds   => p_strm_stationing_starts_ds,
               p_flows_into_stream      => p_strm_flows_into_stream,
               p_flows_into_station     => p_strm_flows_into_station,
               p_flows_into_bank        => p_strm_flows_into_bank,
               p_diverts_from_stream    => p_strm_diverts_from_stream,
               p_diverts_from_station   => p_strm_diverts_from_station,
               p_diverts_from_bank      => p_strm_diverts_from_bank,
               p_length                 => p_strm_length,
               p_average_slope          => p_strm_average_slope,
               p_comments               => p_strm_comments,
               p_office_id              => p_db_office_id);
         ELSE
            NULL;
      END CASE;                                          --p_location_Type_new
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_debug := SQLERRM;
      WHEN OTHERS
      THEN
         p_debug := SQLERRM;
   END;

   PROCEDURE p_load_Location_kind (
      p_locatioN_id            IN cwms_v_loc.location_id%TYPE,
      p_location_kind_id_new   IN cwms_v_loc.location_kind_id%TYPE,
      p_project_id             IN cwms_v_project.project_id%TYPE,
      p_structure_Type_code    IN cwms_v_embankment.structure_Type_code%TYPE,
      p_db_Office_id           IN cwms_v_loc.db_office_id%TYPE)
   IS
      temp_locatioN_code          cwms_v_loc.location_code%TYPE;
      temp_project_code           cwms_v_loc.locatioN_code%TYPE;
      temp_location_kind_id_old   cwms_v_loc.location_type%TYPE;
   BEGIN
      --This procedure will load the minimum data necessary to create a record in the at_SUBoRDINATE
      --tables

      SELECT locatioN_code
        INTO temp_locatioN_code
        FROM cwms_v_loc
       WHERE     locatioN_id = p_location_id
             AND db_office_id = p_db_office_id
             AND unit_System = 'EN';

      SELECT location_type
        INTO temp_locatioN_kind_id_old
        FROM cwms_v_location_type
       WHERE locatioN_id = p_location_id AND office_id = p_db_Office_id;



      IF p_project_id IS NOT NULL
      THEN
         SELECT locatioN_code
           INTO temp_project_code
           FROM cwms_v_loc
          WHERE     locatioN_id = p_project_id
                AND db_office_id = p_db_office_id
                AND unit_system = 'EN';
      END IF;

      /*
      FOR x IN (SELECT *
                  FROM cwms_v_locatioN_Type
                 WHERE location_code = temp_locatioN_code
                   AND location_type != p_location_kind_id_new
              ) LOOP
                  --Run the delete procedure?
                      p_clear_loc_type_classif(p_db_Office_id     => p_db_office_id
                                              ,p_locatioN_code    => temp_locatioN_code
                                              ,p_location_type    => x.locatioN_type
                                              );

                 NULL;


                END LOOP;
     */

      IF temp_locatioN_kind_id_old = p_location_kind_id_new
      THEN
         --Do nothing, record already exists
         NULL;
      ELSE
         CASE p_location_kind_id_new
            WHEN c_str_embankment
            THEN
               INSERT
                 INTO at_embankment (embankment_location_code,
                                     embankment_project_loc_code,
                                     structure_Type_code)
               VALUES (
                         temp_location_code,
                         temp_project_code,
                         p_structure_Type_code);
            WHEN c_str_outlet
            THEN
               INSERT
                 INTO at_outlet (outlet_locatioN_code, project_location_code)
               VALUES (temp_location_code, temp_project_code);
            WHEN c_str_turbine
            THEN
               INSERT
                 INTO at_turbine (turbine_locatioN_code, project_locatioN_code)
               VALUES (temp_locatioN_code, temp_project_code);
            ELSE
               NULL;
         END CASE;
      END IF;
   END;

--   PROCEDURE p_load_lockage (
--      p_lockage_code               IN NUMBER,
--      p_lock_location_code         IN NUMBER,
--      p_lockage_datetime           IN cwms_v_lockage.lockage_datetime%TYPE,
--      p_number_boats               IN cwms_v_lockage.number_boats%TYPE,
--      p_number_barges              IN cwms_v_lockage.number_barges%TYPE,
--      p_tonnage                    IN cwms_v_lockage.tonnage%TYPE,
--      p_is_tow_upbound             IN cwms_v_lockage.is_tow_upbound%TYPE,
--      p_is_lock_chamber_emptying   IN cwms_v_lockage.is_lock_chamber_emptying%TYPE,
--      p_lockage_notes              IN cwms_v_lockage.lockage_notes%TYPE,
--      p_db_Office_id               IN cwms_v_loc.db_Office_id%TYPE)
--   IS
--      temp_num   cwms_v_lockage.lockage_code%TYPE;
--   BEGIN
--      NULL;
--
--      IF p_lockage_code IS NULL
--      THEN
--         --Add a new record
--         NULL;
--
--         SELECT cwms_seq.NEXTVAL INTO temp_num FROM DUAL;
--
--         INSERT INTO at_lockage (lockage_code,
--                                 lockage_location_code,
--                                 lockage_datetime,
--                                 number_boats,
--                                 number_barges,
--                                 tonnage,
--                                 is_tow_upbound,
--                                 is_lock_chamber_emptying,
--                                 lockage_Notes)
--              VALUES (temp_num,
--                      p_lock_location_code,
--                      p_lockage_datetime,
--                      p_number_boats,
--                      p_number_barges,
--                      p_tonnage,
--                      p_is_tow_upbound,
--                      p_is_lock_chamber_emptying,
--                      p_lockage_notes);
--      ELSE
--         -- updaten an existing record
--         UPDATE at_lockage
--            SET lockage_location_code = p_lock_location_code    --Keep this???
--                                                            ,
--                lockage_datetime = p_lockage_datetime,
--                number_boats = p_number_boats,
--                number_barges = p_number_barges,
--                tonnage = p_tonnage,
--                is_tow_upbound = p_is_tow_Upbound,
--                is_lock_chamber_emptying = p_is_lock_chamber_emptying,
--                lockage_Notes = p_lockage_Notes
--          WHERE lockage_code = p_lockage_code;
--
--         NULL;
--      END IF;                                                 -- lock location
--   END;

--   PROCEDURE p_load_pool (p_location_code  IN Cwms_v_loc.location_code%TYPE
--                        , p_pool_code      IN NUMBER
--                        , p_location_level_code_upper IN NUMBER
--                        , p_location_level_code_lower IN NUMBER
--                        , p_purpose_codes  IN VARCHAR2
--                        , p_delim          IN VARCHAR2 DEFAULT ':'  ) IS
--   temp_num NUMBER DEFAULT 0;
--   BEGIN
--
--
--   SELECT COUNT(location_code)
--     INTO temp_num
--     FROM cwms_v_pool
--    WHERE location_code = p_location_code
--      AND pool_code     = p_pool_code;
--   CASE
--   WHEN temp_num >0 THEN
--
--   UPDATE at_pool
--      SET location_level_code_Upper = p_location_level_code_upper
--        , location_level_code_lower = p_location_level_code_lower
----        , purpose_code              = p_purpose_code
--    WHERE location_code             = p_location_code
--      AND pool_code                 = p_pool_code;
--
--
--        DELETE at_pool_purposes
--         WHERE locatioN_code = p_locatioN_code;
--
--        FOR x IN (SELECT TO_NUMBER(column_value) column_value
--                    FROM TABLE(STR2TBL(p_purpose_codes, p_delim))
--                  ) LOOP
--
--                    INSERT INTO at_pool_purposes (location_code,pool_code,purpose_code, date_created)
--                                                VALUES
--                                                 ( p_location_code, p_pool_code, x.column_value, SYSDATE);
--
--                    END LOOP;
--
--
--
--    ELSE
--      INSERT INTO at_pool (location_code
--                        ,pool_code
--                        ,location_level_code_upper
--                        ,location_level_code_lower
--                        ,date_created
----                        ,purpose_code
--                        ) VALUES
--                        (p_location_code
--                        ,p_pool_code
--                        ,p_location_level_code_upper
--                        ,p_locatioN_level_code_lower
--                        ,SYSDATE
----                        ,p_purpose_code
--                        );
--
--        DELETE at_pool_purposes
--         WHERE locatioN_code = p_locatioN_code;
--
--        FOR x IN (SELECT TO_NUMBER(column_value) column_value
--                    FROM TABLE(STR2TBL(p_purpose_codes, p_delim))
--                  ) LOOP
--
--                    INSERT INTO at_pool_purposes (location_code,pool_code,purpose_code, date_created)
--                                                VALUES
--                                                 ( p_location_code, p_pool_code, x.column_value, SYSDATE);
--
--                    END LOOP;
--
--
--    END CASE;
--
--   EXCEPTION
--    WHEN no_data_found THEN
--
--    INSERT INTO at_pool (location_code
--                        ,pool_code
--                        ,location_level_code_upper
--                        ,location_level_code_lower
--                        ,date_created
--                        ) VALUES
--                        (p_location_code
--                        ,p_pool_code
--                        ,p_location_level_code_upper
--                        ,p_locatioN_level_code_lower
--                        ,SYSDATE
--                        );
--
--
--        DELETE at_pool_purposes
--         WHERE locatioN_code = p_locatioN_code;
--
--        FOR x IN (SELECT TO_NUMBER(column_value) column_value
--                    FROM TABLE(STR2TBL(p_purpose_codes, p_delim))
--                  ) LOOP
--
--                    INSERT INTO at_pool_purposes (location_code,pool_code,purpose_code, date_created)
--                                                VALUES
--                                                 ( p_location_code, p_pool_code, x.column_value, SYSDATE);
--
--                    END LOOP;
--
--
--   END;

   PROCEDURE p_load_rating_value (
      p_rating_code   IN cwms_v_rating_values.rating_code%TYPE,
      p_ind_value_1   IN cwms_v_rating_values.ind_value_1%TYPE,
      p_ind_value_2   IN cwms_v_rating_values.ind_value_2%TYPE,
      p_ind_value_3   IN cwms_v_rating_values.ind_value_3%TYPE,
      p_ind_value_4   IN cwms_v_rating_values.ind_value_4%TYPE,
      p_dep_value     IN cwms_v_rating_values.dep_value%TYPE)
   IS
      temp_rating_ind_param_code   at_rating_value.rating_ind_param_code%TYPE;
      temp_other_ind_hash          at_rating_value.other_ind_hash%TYPE;

      temp_num                     NUMBER DEFAULT 0;
   BEGIN
      IF p_ind_value_1 IS NOT NULL
      THEN
         FOR x IN (SELECT *
                     FROM at_rating_ind_parameter
                    WHERE rating_code = p_rating_code)
         LOOP
            SELECT DISTINCT other_ind_hash
              INTO temp_other_ind_hash
              FROM at_rating_value
             WHERE rating_ind_param_code = x.rating_ind_param_code;



            SELECT COUNT (rating_code)
              INTO temp_num
              FROM cwms_v_rating_values
             WHERE     rating_code = p_rating_code
                   AND dep_value = p_dep_value
                   AND ind_value_1 = p_ind_value_1;


            IF temp_num = 0
            THEN
               --INSERT
               INSERT INTO at_rating_value (rating_ind_param_code,
                                            other_ind_hash,
                                            ind_value,
                                            dep_value,
                                            dep_rating_ind_param_code,
                                            note_code)
                    VALUES (temp_rating_ind_param_code,
                            temp_other_ind_hash,
                            p_ind_value_1,
                            p_dep_value,
                            NULL,
                            NULL);
            ELSE
               -- Update

               /*

               FOR y IN (SELECT *
                           FROM at_rating_value
                          WHERE rating_ind_param_code  = temp_rating_ind_param_code
                            AND ind_value              = p_ind_value_1
                            AND dep_value              = p_dep_value
                        ) LOOP
                           UPDATE at_rating_value
                              SET


                          END LOOP;

               */
               NULL;
            END IF;
         END LOOP;
      END IF;



      --  SELECT * FROM at_rating_value
      -- SELECT * FROM at_rating_ind_parameter
      -- SELECT * FROM at_rating_ind_param_specs



      NULL;
   END;

   PROCEDURE p_chart_by_ts_code (
      p_ts_code      IN cwms_v_ts_id.TS_CODE%TYPE,
      p_days         IN NUMBER DEFAULT c_chart_min_days,
      p_date_start   IN DATE DEFAULT SYSDATE - 45,
      p_date_end     IN DATE DEFAULT SYSDATE,
      xmlcalldate    IN NUMBER DEFAULT NULL)
   IS
      loop_num                     NUMBER DEFAULT 1;

      temp_num_points              NUMBER DEFAULT 0;

      temp_date_start              DATE DEFAULT p_date_start;
      temp_date_end                DATE DEFAULT p_date_end;


      temp_base_parameter_id       VARCHAR2 (256);
      temp_clob                    CLOB;
      temp_cwms_ts_id              VARCHAR2 (256);
      temp_location_code           NUMBER;
      temp_location_id             VARCHAR2 (256);
      temp_ts_code                 NUMBER;
      temp_unit_id                 VARCHAR2 (3);
      temp_data_clob               CLOB;
      temp_data_clob_no_point      CLOB;
      temp_db_office_id            VARCHAR2 (5);

      temp_BoN_level_val           NUMBER;                              -- BoN
      temp_ToF_level_val           NUMBER;                              -- ToF
      temp_ToN_level_val           NUMBER;                              -- ToN


      temp_cons_red_pct            NUMBER DEFAULT 0.75;
      temp_cons_yellow_pct         NUMBER DEFAULT 0.90;

      temp_cons_red_val            NUMBER;
      temp_cons_yellow_val         NUMBER;

      temp_line_tof_Clob           CLOB;
      temp_line_ton_clob           CLOB;
      temp_line_bon_clob           CLOB;
      temp_line_drought_orange     CLOB;
      temp_line_drought_red        CLOB;



      temp_seasonal_loop_in_past   VARCHAR2 (1) DEFAULT 'T'; --c_cwms_logic_t%TYPE DEFAULT c_cwms_logic_t;
      temp_seasonal_loop_val       NUMBER;
   BEGIN
      --this procedure will return a CWMS Chart by NIDID
      -- It will look for an elevation or stage



      --    SELECT * FROM cwms_v_ts_id

      SELECT location_code, location_id, db_office_id
        INTO temp_location_Code, temp_location_id, temp_db_office_id
        FROM cwms_v_ts_id
       WHERE ts_code = p_ts_code;

      --select * from av_loc_alias@cpc_cwms20
      --SELECT * FROM cwms_v_Ts_id@cpc_cwms20

      FOR x
         IN (  SELECT ll.unit_system,
                      ROUND (ll.constant_level, 2) constant_level,
                      ll.location_level_id lli,
                      ROWNUM row_num
                 FROM cwms_v_location_level ll --av_location_level@cpc_cwms20 ll
                WHERE     office_id = temp_db_office_id
                      AND unit_system = 'EN'
                      AND constant_level IS NOT NULL
                      AND locatioN_id = temp_locatioN_id -- INSTR(location_level_id, temp_location_id) > 0
             ORDER BY ll.constant_level ASC)
      LOOP
         CASE
            WHEN INSTR (x.lli, 'Bottom of Normal') > 0
            THEN
               temp_BoN_level_val := x.constant_level;
            WHEN INSTR (x.lli, 'Top of Normal') > 0
            THEN
               temp_ToN_level_val := x.constant_level;
            WHEN INSTR (x.lli, 'Top of Flood') > 0
            THEN
               temp_ToF_level_val := x.constant_level;
            ELSE
               NULL;
         END CASE;
      END LOOP;

      FOR x
         IN (  SELECT lli.*,
                      CASE
                         WHEN SYSDATE > da THEN c_app_logic_y
                         ELSE c_app_logic_n
                      END
                         in_past,
                      TO_CHAR (SYSDATE, 'MM/DD/YYYY') sysdate1
                 FROM (SELECT location_level_id lli,
                              constant_level,
                              calendar_offset,
                              time_offset,
                              ROUND (seasonal_level, 2) seasonal_level,
                              CASE
                                 WHEN seasonal_level IS NOT NULL
                                 THEN
                                    TO_DATE (
                                          (  TO_NUMBER (
                                                SUBSTR (calendar_offset, 4, 2))
                                           + 1)
                                       || '/'
                                       || LPAD (
                                             TO_CHAR (
                                                (  TO_NUMBER (
                                                      SUBSTR (time_offset,
                                                              0,
                                                              4))
                                                 + 1)),
                                             2,
                                             0)
                                       || '/'
                                       || TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY')),
                                       'MM-DD-YYYY')
                              END
                                 da
                         --, TO_TIMESTAMP(calendar_offset || '-' || time_offset) t2
                         FROM cwms_v_location_level
                        WHERE     locatioN_id = temp_locatioN_id -- INSTR(location_level_id, temp_location_id) > 0
                              AND unit_System = 'EN'
                              AND seasonal_level IS NOT NULL) lli
             ORDER BY lli.calendar_offset, lli.time_offset)
      LOOP
         NULL;

         IF    (    x.in_past = c_app_logic_n
                AND temp_seasonal_loop_in_past = c_app_logic_y)
            OR (    x.in_past = c_app_logic_y
                AND temp_seasonal_loop_in_past = c_app_logic_y)
         THEN
            -- We're at the right location

            IF temp_seasonal_loop_Val IS NULL
            THEN
               temp_seasonal_loop_Val := x.seasonal_level;
            END IF;

            CASE
               WHEN INSTR (x.lli, 'Bottom of Normal') > 0
               THEN
                  temp_BoN_level_val := temp_seasonal_loop_val;
               WHEN INSTR (x.lli, 'Top of Normal') > 0
               THEN
                  temp_ToN_level_val := temp_seasonal_loop_val;
               WHEN INSTR (x.lli, 'Top of Flood') > 0
               THEN
                  temp_ToF_level_val := temp_seasonal_loop_val;
                  NULL;
               ELSE
                  NULL;
            END CASE;
         END IF;

         temp_seasonal_loop_val := x.seasonal_level;
         temp_seasonal_loop_in_past := x.in_past;
      END LOOP;


      IF     (temp_BoN_level_val > 0 AND temp_bon_level_val IS NOT NULL)
         AND (temp_ToN_level_val > 0 AND temp_ToN_level_val IS NOT NULL)
      THEN
         --Calculate the Conservation Pool Red and Yellow Lines
         --Red
         temp_cons_red_val :=
              temp_bon_level_val
            + ( (temp_ton_level_val - temp_bon_level_val) * temp_cons_red_pct);
         --Yellow
         temp_cons_yellow_val :=
              temp_bon_level_val
            + (  (temp_ton_level_val - temp_bon_level_val)
               * temp_cons_yellow_pct);


         temp_line_drought_orange :=
               '<line value = "'
            || TO_CHAR (temp_cons_yellow_val)
            || '" color ="Orange" >
              <label enabled="true">
               <font color = "Orange" size ="8" />
               <format>Drought</format>
              </label>
             </line>';

         temp_line_drought_red :=
               '<line value = "'
            || TO_CHAR (temp_cons_red_val)
            || '" color ="Red" >
              <label enabled="true">
               <font color = "Orange" size ="8" />
               <format>Drought</format>
              </label>
             </line>';
      END IF;


      --SELECT * FROM av_location_level@cpc_cwms20 WHERE office_id = 'NAP'
      --SELECT * FROM cwms_v_ts_id@cpc_cwms20 WHERE location_code = 20790066



      FOR x
         IN (SELECT tsi.cwms_Ts_id,
                    tsi.ts_code,
                    tsi.unit_id,
                    tsi.base_parameteR_id
               FROM cwms_v_ts_id tsi
              WHERE     tsi.ts_Code = p_ts_code
                    AND tsi.base_parameter_id IN ('Elev', 'Stage')
                    AND tsi.version_id NOT IN ('RUL'))
      LOOP
         IF temp_Ts_code IS NULL
         THEN
            temp_cwms_ts_id := x.cwms_Ts_id;
            temp_base_parameter_id := x.base_parameter_id;
            temp_unit_id := x.unit_id;
            temp_ts_code := x.ts_code;
         END IF;
      END LOOP;


      FOR y
         IN (  SELECT tsv.date_time,
                      ROUND (tsv.VALUE * 3.28084, 4) VALUE,
                      ORCL_2_UNIX (tsv.date_time) date_time_unix,
                      TO_CHAR (tsv.date_time, 'DD-MON-YYYY HH24:MI')
                         date_time_char
                 FROM cwms_v_Tsv tsv
                WHERE     tsv.ts_code = p_ts_code
                      AND (    tsv.date_Time >= p_date_start    --SYSDATE - 60
                           AND tsv.date_time <= p_date_end)
             --                             AND tsv.date_Time >= TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')) - p_days

             ORDER BY Date_time DESC)
      LOOP
         temp_data_clob :=
               temp_Data_clob
            || '
          <point x="'
            || TO_CHAR (y.date_time_unix)
            || ' " y="'
            || TO_CHAR (y.VALUE)
            || '" >
           <attributes>
             <attribute name="Date"><![CDATA['
            || y.date_time_char
            || ']]></attribute>
           </attributes>
          </point> ';

         temp_data_clob_no_point :=
               temp_data_clob_no_point
            || '
          <point x="'
            || TO_CHAR (y.date_time_unix)
            || ' " y="'
            || TO_CHAR (y.VALUE)
            || '" >
           <marker enabled="False" style="SmallMarker" />
           <attributes>
             <attribute name="Date"><![CDATA['
            || y.date_time_char
            || ']]></attribute>
           </attributes>
          </point> ';
         --Get the total number of points
         temp_num_points := temp_num_points + 1;
      END LOOP;

      -- IF temp_data_clob IS NULL THEN
      --   temp_data_clob := 'Hello JDK ' || temp_ts_code || '/' || p_ts_code;
      -- END If;


      IF temp_num_points > 150
      THEN
         temp_data_clob := temp_data_clob_no_point;
      END IF;



      IF temp_tof_level_Val IS NULL OR temp_tof_level_Val = 0
      THEN
         -- DO nothing
         NULL;
      ELSE
         temp_line_tof_clob :=
               '             <line value = "'
            || TO_CHAR (temp_ToF_level_val)
            || '" color="Red" dashed="true" hinting="true" caps="None" dash_length="3" >
              <label enabled="true">
               <font color = "red" size = "8"/>
               <format>ToF</format>
              </label>
             </line>';
      END IF;

      IF temp_ton_level_Val IS NULL OR temp_ton_level_Val = 0
      THEN
         -- DO nothing
         NULL;
      ELSE
         temp_line_ton_clob :=
               '             <line value = "'
            || TO_CHAR (temp_ToN_level_val)
            || '" color="Blue" >
              <label enabled="true">
               <font color = "Blue" size = "8"/>
               <format>ToN '
            || TO_CHAR (temp_ToN_level_val)
            || '</format>
              </label>
             </line>';
      END IF;



      temp_Data_clob :=
            '     <data>
        <series name="CWMS Output" type="Line">
        '
         || temp_data_clob
         || '         </series>
      </data>';

      temp_clob :=
            '<?xml version="1.0" encoding="UTF-8"?>
<anychart>
   <settings>
     <animation enabled="True" />
      <locale>
       <date_time_format>
         <format><![CDATA[%u]]></format>
       </date_time_format>
     </locale>
   </settings>
  <charts>
    <chart plot_type="Scatter">
     <data_plot_settings default_series_type="Spline">
        <line_series>
          <tooltip_settings enabled="true">
            <format><![CDATA[{%YValue} ft
on: {%Date}]]></format>
          </tooltip_settings>
        </line_series>
      </data_plot_settings>
      <styles>
        <marker_style name="SmallMarker" color="Blue">
          <marker type="Star5" size="2" />
          <states>
            <hover>
              <marker size="22" />
            </hover>
          </states>
        </marker_style>
      </styles>
      '
         || temp_data_clob
         || '
      <chart_settings>
        <title enabled = "true" >
          <text>'
         || temp_cwms_Ts_id
         || '</text>
        </title>
        <axes>
          <y_axis>
            <title enabled = "false">
              <text>'
         || temp_base_parameter_id
         || ' ('
         || temp_unit_id
         || ') </text>
            </title>
            <labels>
              <format>{%Value}{numDecimals:1,decimalSeparator:.,thousandsSeparator: } '
         || 'ft'
         || '</format>
             </labels>
             <labels>
              <format>{%Value}{numDecimals:1,decimalSeparator:.,thousandsSeparator: }</format>
             </labels>
           <axis_markers>
            <lines>'
         || temp_line_tof_clob
         || '
                   '
         || temp_line_ton_clob
         || '
             <line value = "'
         || TO_CHAR (temp_BoN_level_val)
         || '" color ="Blue" >
              <label enabled="true">
               <font color = "Blue" size ="8" />
               <format>BoN '
         || TO_CHAR (temp_BoN_level_val)
         || '</format>
              </label>
             </line>

             '
         || temp_line_drought_red
         || '
             '
         || temp_line_drought_orange
         || '

            </lines>


           </axis_markers>
          </y_axis>
           <x_axis>
            <scale type="DateTime" major_interval="1" minor_interval="12" major_interval_unit="Day" minor_interval_unit="Hour" minimum_offset="0" maximum_offset="0" />
            <labels>
              <format><![CDATA[{%Value}{dateTimeFormat:%dd-%MMM}]]></format>
            </labels>
            <title enabled="true">
                <text>Date </text>
            </title>
          </x_axis>
        </axes>
      </chart_settings>
    </chart>
  </charts>
</anychart>
';

      --temp_clob   := 'Hello World';

      WHILE loop_num < (LENGTH (temp_clob))
      LOOP
         HTP.prn (SUBSTR (temp_clob, loop_num, 1000));
         loop_num := loop_num + 1000;
      END LOOP;
   END p_chart_by_ts_code;


   PROCEDURE p_chart_Rating_Curve (
      xmlcalldate       IN     NUMBER DEFAULT NULL,
      p_location_code   IN     cwms_20.av_loc.location_code%TYPE,
      p_rating_code     IN     cwms_v_rating_values.rating_code%TYPE,
      p_db_Office_id    IN     cwms_v_loc.db_Office_id%TYPE,
      p_clob_out_tf     IN     VARCHAR2 DEFAULT 'F',
      p_clob_out           OUT CLOB)
   IS
      loop_num                  NUMBER;
      temp_end_date             DATE;
      temp_clob                 CLOB;
      temp_data_clob            CLOB;

      temp_x_axis_clob          CLOB;
      temp_Y_axis_clob          CLOB;

      temp_LL_clob              CLOB;

      temp_location_id          cwms_v_loc.location_id%TYPE;

      temp_ind_base_parameter   VARCHAR2 (10);
      temp_dep_base_parameter   VARCHAR2 (10);
      temp_native_units         VARCHAR2 (10);
      temp_x_axis_decimal_pt    NUMBER DEFAULT 0;
      temp_y_axis_decimal_pt    NUMBER DEFAULT 0;
      temp_x_axis_units         VARCHAR2 (10) DEFAULT 'ac-ft';
      temp_y_axis_units         VARCHAR2 (10) DEFAULT 'ft';
      temp_ts_code              cwms_v_ts_id.ts_code%TYPE;
      temp_ts_code_unit_id      cwms_v_ts_id.unit_id%TYPE;
      temp_x_axis_title         cwms_v_ts_id.parameter_id%TYPE;
      temp_y_axis_title         cwms_v_ts_id.parameter_id%TYPE;


      temp_ind_1_parameter_id   VARCHAR2 (255);
      temp_dep_parameter_id     VARCHAR2 (255);

      temp_stage_or_elev        VARCHAR2 (5) DEFAULT 'ELEV';


      temp_current_val_clob     CLOB;

      temp_title_clob           CLOB;
   BEGIN
      NULL;


      SELECT location_id
        INTO temp_location_id
        FROM cwms_v_loc
       WHERE location_code = p_locatioN_code AND unit_system = 'EN';


      FOR x
         IN (SELECT r.*,
                    UPPER (
                       SUBSTR (template_id, 1, INSTR (template_id, ';') - 1))
                       ind_1_parameter_id,
                    UPPER (
                       SUBSTR (template_id, INSTR (template_id, ';') + 1))
                       dep_parameter_id
               FROM cwms_v_rating r
              WHERE rating_code = p_rating_code AND aliased_item IS NULL)
      LOOP
         temp_native_units := x.native_Units;
         temp_title_clob := x.locatioN_id || ' Rating Curve ' || x.template_id;
         temp_ind_1_parameter_id := x.ind_1_parameter_id;
         temp_dep_parameter_id := x.dep_parameter_id;
      END LOOP;



      --Get the lookup units and base parameters

      CASE temp_native_units
         WHEN 'ft;ac-ft'
         THEN
            temp_ind_base_parameter := 'Elev';
            temp_dep_base_parameter := 'Stor';
            temp_x_axis_decimal_pt := 0;
            temp_y_axis_decimal_pt := 0;
            temp_x_axis_units := 'ac-ft';
            temp_y_axis_units := 'ft';
         WHEN 'ft;cfs'
         THEN
            temp_ind_base_parameter := 'Elev';
            temp_dep_base_parameter := 'Flow';
            temp_x_axis_decimal_pt := 0;
            temp_y_axis_decimal_pt := 0;
            temp_x_axis_units := 'cfs';
            temp_y_axis_units := 'ft';
         WHEN 'ft;acre'
         THEN
            temp_ind_base_parameter := 'Elev';
            temp_dep_base_parameter := 'Area';
            temp_x_axis_decimal_pt := 0;
            temp_y_axis_decimal_pt := 0;
            temp_x_axis_units := 'acre';
            temp_y_axis_units := 'ft';
         WHEN 'm;ac-ft'
         THEN
            temp_ind_base_parameter := 'Elev';
            temp_dep_base_parameter := 'Stor';
            temp_x_axis_decimal_pt := 0;
            temp_y_axis_decimal_pt := 0;
            temp_x_axis_units := 'ac-ft';
            temp_y_axis_units := 'm';
         WHEN 'm;m2'
         THEN
            temp_ind_base_parameter := 'Elev';
            temp_dep_base_parameter := 'Area';
            temp_x_axis_decimal_pt := 0;
            temp_y_axis_decimal_pt := 0;
            temp_x_axis_units := 'm2';
            temp_y_axis_units := 'm';
         WHEN 'ft;ft'
         THEN
            temp_ind_base_parameter := 'Elev';
            temp_dep_base_parameter := 'Elev';
            temp_x_axis_decimal_pt := 4;
            temp_y_axis_decimal_pt := 0;
            temp_x_axis_units := 'ft';
            temp_y_axis_units := 'ft';
         ELSE
            NULL;
      END CASE;



      FOR x IN (SELECT *
                  FROM cwms_v_a2w_ts_codes_by_loc
                 WHERE locatioN_id = temp_locatioN_id AND display_flag = 'T')
      LOOP
         CASE
            WHEN     x.ts_code_elev IS NOT NULL
                 AND temp_ind_1_parameter_id LIKE ('%ELEV')
            THEN
               temp_ts_code := x.ts_code_elev;
               temp_stage_or_elev := 'ELEV';
            WHEN     x.ts_code_stage IS NOT NULL
                 AND temp_ind_1_parameter_id LIKE ('%STAGE')
            THEN
               temp_ts_code := x.ts_code_stage;
               temp_stage_or_elev := 'STAGE';
            WHEN x.ts_code_Elev IS NOT NULL
            THEN
               temp_ts_code := x.ts_code_Elev;
               temp_stage_or_elev := 'Elev';
            WHEN x.ts_code_stage IS NOT NULL
            THEN
               temp_ts_code := x.ts_code_stage;
               temp_stage_or_elev := 'STAGE';
            ELSE
               NULL;
         END CASE;
      END LOOP;



      IF temp_ts_code IS NOT NULL
      THEN
         FOR x IN (SELECT *
                     FROM cwms_v_ts_id
                    WHERE ts_code = temp_ts_code)
         LOOP
            temp_y_axis_title := x.parameter_id;
            temp_ts_code_unit_id := x.unit_id;
         END LOOP;


         FOR x IN (SELECT tsv.*, ROWNUM row_num
                     FROM (  SELECT ROUND (
                                       TO_NUMBER (
                                          cwms_util.convert_units (
                                             VALUE,
                                             temp_ts_code_unit_id,
                                             'ft')),
                                       2)
                                       VALUE,
                                    TO_CHAR ( (date_time - 4 / 24),
                                             'DDMONYYYY HH24:MI')
                                       date_time
                               FROM cwms_v_tsv tsv
                              WHERE     ts_code = temp_ts_code
                                    AND date_time >= SYSDATE - 5
                           ORDER BY date_time DESC) tsv)
         LOOP
            IF x.row_num = 1
            THEN
               temp_current_val_clob :=
                     '<line value="'
                  || x.VALUE
                  || '" color="Blue"  dashed="True" dash_length="5" space_length="5" thickness="1" caps="none">
                      <label enabled="true" position="Far">
                        <font color="Blue" />
                        <format><![CDATA['
                  || x.date_time
                  || '-'
                  || x.VALUE
                  || ' '
                  || 'ft'
                  || ']]></format>
                      </label>
                    </line>'
                  || CHR (10);
            END IF;
         END LOOP;
      END IF;

      FOR x
         IN (  SELECT *
                 FROM cwms_v_location_level
                WHERE     office_id = p_db_office_id
                      AND location_id = temp_locatioN_id
                      AND unit_system = 'EN'
                      AND UPPER (base_parameter_id) = temp_stage_or_elev
             ORDER BY constant_level DESC /*          SELECT *
                                                      FROM cwms_web.local_load_data_table
                                                     WHERE gagename = temp_locatioN_id --temp_location_id
                                        */
                                         )
      LOOP
         IF x.specified_level_id = 'Top of Dam'
         THEN
            temp_ll_clob :=
                  '<line value="'
               || x.constant_level
               || '" color="Red" thickness="1" caps="none">
                          <label enabled="true" position="Near">
                            <font color="red" />
                            <format><![CDATA['
               || x.specified_level_id
               || ']]></format>
                          </label>
                        </line>'
               || CHR (10)
               || temp_ll_clob;
         ELSE
            temp_ll_clob :=
                  '<line value="'
               || x.constant_level
               || '" color="Red"  dashed="True" dash_length="5" space_length="5" thickness="1" caps="none">
                  <label enabled="true" position="Near">
                    <font color="red" />
                    <format><![CDATA['
               || x.specified_level_id
               || ']]></format>
                  </label>
                </line>'
               || CHR (10)
               || temp_ll_clob;
         END IF;
      END LOOP;


      temp_ll_clob :=
            '
  <axis_markers>
    <lines>
      '
         || temp_ll_clob
         || temp_current_val_clob
         || '
    </lines>
  </axis_markers>
';



      temp_x_axis_clob :=
            '                                   <x_axis enabled="true" >
                                                                        <title>
      <text><![CDATA['
         || temp_dep_parameter_id
         || ' ('
         || temp_x_axis_units
         || ')]]></text>
      <font bold="Yes" />
    </title>
<labels>
    <format><![CDATA[{%Value}{numDecimals:'
         || temp_x_axis_decimal_pt
         || '} ]]></format>
  </labels>

                                    <major_tickmark color="Red" />
                                    <zero_line thickness="2" type="Gradient" caps="None" opacity="1">
                                      <gradient>
                                        <key color="Black" position="0.2" />
                                        <key color="Red" position="0.5" />
                                        <key color="Black" position="0.8" />
                                      </gradient>
                                    </zero_line>
                                  </x_axis>';

      temp_Y_axis_clob :=
            ' <y_axis>
                                    <title>
      <text><![CDATA['
         || temp_y_axis_title
         || ' ('
         || temp_y_axis_units
         || ')]]></text>
      <font bold="Yes" />
    </title>
    <labels>
     <format><![CDATA[{%Value}{numDecimals:'
         || temp_y_axis_decimal_pt
         || '} ]]></format>
    </labels>
      <major_tickmark color="Red" />
                                    <zero_line thickness="2" type="Gradient" caps="None" opacity="1">
                                      <gradient>
                                        <key color="Black" position="0.2" />
                                        <key color="Red" position="0.5" />
                                        <key color="Black" position="0.8" />
                                      </gradient>
                                    </zero_line>
                                    '
         || temp_ll_clob
         || '
                                  </y_axis>
  ';

      FOR x
         IN (  SELECT cwms_util.convert_units (
                         ind_value_1,
                         cwms_util.get_default_units (temp_ind_base_parameter),
                         temp_y_axis_units)
                         ind_value_1,
                      cwms_util.convert_units (
                         ind_value_2,
                         cwms_util.get_default_units (temp_ind_base_parameter),
                         temp_y_axis_units)
                         ind_value_2,
                      cwms_util.convert_units (
                         ind_value_3,
                         cwms_util.get_default_units (temp_ind_base_parameter),
                         temp_y_axis_units)
                         ind_value_3,
                      cwms_util.convert_units (
                         ind_value_4,
                         cwms_util.get_default_units (temp_ind_base_parameter),
                         temp_y_axis_units)
                         ind_value_4,
                      cwms_util.convert_units (
                         dep_value,
                         cwms_util.get_default_units (temp_dep_base_parameter),
                         temp_x_axis_units)
                         dep_value,
                      rating_code
                 FROM cwms_v_rating_values
                WHERE rating_code = p_rating_code              --p_rating_code
             ORDER BY ind_value_1)
      LOOP
         temp_data_clob :=
               '<point x="'
            || TO_CHAR (ROUND (TO_NUMBER (x.dep_value), 4))
            || '" y="'
            || TO_CHAR (ROUND (TO_NUMBER (x.ind_value_1), 4))
            || '">
                                      </point>'
            || CHR (10)
            || temp_data_clob;
      END LOOP;


      temp_data_clob :=
            '<data>
                                <series style="line1">'
         || temp_data_clob
         || '
                                 </series>
                              </data>';



      temp_clob :=
            '<?xml version="1.0" encoding="UTF-8"?>
                        <anychart>
                          <charts>
                            <chart plot_type="Scatter">
                              <data_plot_settings default_series_type="Line">
                                <line_series>
                                  <marker_settings enabled="true" />
<tooltip_settings enabled="true">
    <format><![CDATA[{%YValue} '
         || temp_y_axis_units
         || '/{%XValue} '
         || temp_x_axis_units
         || ']]></format>
 </tooltip_settings>

                                </line_series>
                              </data_plot_settings>

                              <chart_settings>
                                <axes>
                                  '
         || temp_Y_axis_clob
         || '
                                  '
         || temp_x_axis_clob
         || '
                                </axes>
                                <title>
                                  <text>'
         || temp_title_clob
         || '</text>
                                </title>
                                <legend enabled="false" />
                              </chart_settings>
    '
         || temp_data_clob
         || '
                            </chart>
                          </charts>
                        </anychart>';

      IF p_clob_out_tf = 'T'
      THEN
         p_clob_out := temp_clob;
      ELSE
         loop_num := 1;

         WHILE loop_num < (LENGTH (temp_clob))
         LOOP
            HTP.prn (SUBSTR (temp_clob, loop_num, 1000));
            loop_num := loop_num + 1000;
         END LOOP;
      END IF;
   END;

   PROCEDURE p_set_a2w_num_tsids (
      p_db_Office_id    IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_code   IN Cwms_v_loc.location_code%TYPE,
      p_user_id         IN VARCHAR2)
   IS
      temp_i   NUMBER DEFAULT 0;
   BEGIN
      FOR x
         IN (SELECT *
               FROM cwms_v_a2w_ts_codes_By_loc2
              WHERE db_Office_id = p_db_Office_id
                AND location_code = p_locatioN_code
             )
      LOOP

        temp_i := temp_i  + 1;
         NULL;
/*
         IF x.ts_code_elev IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_stage IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_precip IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_inflow IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_outflow IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_stor_flood IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_stor_drought IS NOT NULL
         THEN
            temp_i := temp_i + 1;
         END IF;

         IF x.ts_code_power_Gen IS NOT NULL
         THEN 
            temp_i := temp_i + 1;
        END IF;
        
         IF x.ts_code_temp_air IS NOT NULL
         THEN 
            temp_i := temp_i + 1;
        END IF;
       
       IF x.ts_code_temp_water IS NOT NULL
         THEN 
            temp_i := temp_i + 1;
        END IF;
        
       IF x.ts_code_do IS NOT NULL
         THEN 
            temp_i := temp_i + 1;
        END IF;
*/
  END LOOP;

FOR x IN (SELECT * FROM at_a2w_ts_codes_By_loc WHERE db_Office_id = p_db_office_id 
             AND location_code = p_location_code)
             
      LOOP

         UPDATE at_a2w_ts_codes_by_loc
            SET date_refreshed = SYSDATE,
                notes =
                      x.notes
                   || CHR (10)
                   || ' updated via CMA on '
                   || SYSDATE
                   || ' by '
                   || p_user_id,
                num_ts_codes = temp_i
          WHERE     db_office_id = p_db_office_id
                AND location_code = p_location_code;

         IF temp_i = 0
         THEN
            UPDATE at_a2w_ts_codes_by_loc
               SET date_refreshed = SYSDATE,
                   notes =
                         x.notes
                      || CHR (10)
                      || ' updated via CMA on '
                      || SYSDATE
                      || ' by '
                      || p_user_Id
                      || '. Set display flag to False because there are no TS IDs selected.',
                   display_flag = 'F'
             WHERE     db_office_id = p_db_office_id
                   AND location_code = p_location_code;
         END IF;

      END LOOP;

         temp_i := 0;
 
   END;

   PROCEDURE p_add_Missing_a2w_rows (
      p_db_Office_id   IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_code    IN Cwms_v_loc.location_code%TYPE DEFAULT NULL,
      p_user_id        IN VARCHAR2)
   IS
    BEGIN
   UPDATE at_a2w_ts_codes_by_loc
           SET location_id = cwms_loc.get_location_id(location_code)
         WHERE locatioN_id IS NULL;

      IF p_locatioN_code IS NOT NULL
      THEN
         FOR x
            IN (SELECT db_office_id, location_code
                  FROM cwms_v_loc
                 WHERE db_Office_id    = p_db_Office_id
                   AND unit_system     = 'EN'
                   AND loc_active_flag = 'T'
                   AND location_kind_id NOT IN ( 'STREAM' , 'BASIN')  -- AND substr(location_id, 1,1) = 'B'
                   AND location_code   = p_locatioN_code
                MINUS
                SELECT db_office_id, locatioN_code
                  FROM cwms_v_a2w_ts_codes_by_loc
                 WHERE db_office_id  = p_db_office_id
                   AND locatioN_code = p_locatioN_code
               )
         LOOP
            INSERT
              INTO at_a2w_ts_codes_by_loc (db_Office_id,
                                           location_code,
                                           date_refreshed,
                                           location_id)
            VALUES (x.db_office_id, x.location_code, SYSDATE,cwms_loc.get_location_id(x.location_code) );
         END LOOP;
      ELSE
         FOR x
            IN (SELECT db_office_id, location_code
                  FROM cwms_v_loc
                 WHERE db_Office_id    = p_db_Office_id
                   AND unit_system     = 'EN'
                   AND loc_active_flag = 'T'
                   AND location_kind_id NOT IN ( 'STREAM' , 'BASIN')  -- AND substr(location_id, 1,1) = 'B'
                MINUS
                SELECT db_office_id, locatioN_code
                  FROM cwms_v_a2w_ts_codes_by_loc
                 WHERE db_office_id = p_db_office_id
                )
         LOOP

                        INSERT
                         INTO at_a2w_ts_codes_by_loc (db_Office_id,
                                                      location_code,
                                                      date_refreshed,
                                                      location_id)
                       VALUES (x.db_office_id, x.location_code, SYSDATE, cwms_loc.get_location_id(x.location_code)) ;
			
         END LOOP;
      END IF;
   END p_add_Missing_a2w_rows;

--   PROCEDURE p_delete_pool (p_Location_code     IN cwms_v_pool.location_code%TYPE
--                           ,p_pool_code         IN cwms_v_pool.pool_code%TYPE
--                           ) IS
--   BEGIN
--
--    DELETE at_pool_purposes WHERE location_code = p_location_code AND pool_code = p_pool_code;
--
--    DELETE at_pool WHERE location_code = p_location_code;
--
--
--
--   END;



   FUNCTION f_validate_location_kind_id (
      f_location_code IN cwms_v_loc.location_code%TYPE)
      RETURN VARCHAR2
   IS
   BEGIN
      NULL;

      RETURN 'failed';
   END;


   PROCEDURE p_test
   IS
   BEGIN
      HTP.p ('Hello Jeremy');
   END;

END CWMS_CMA;
/
