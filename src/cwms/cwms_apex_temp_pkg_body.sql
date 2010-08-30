CREATE OR REPLACE PACKAGE BODY CWMS_APEX_TEMP AS
/******************************************************************************
   NAME:       CWMS_APEX_TEMP
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        7/8/2010             1. Created this package.
******************************************************************************/

 g_bad_chars        VARCHAR2(256);

FUNCTION calc_seasonal_mn_offset(f_005 IN VARCHAR2) RETURN NUMBER IS
temp_out NUMBER;
temp_yr NUMBER DEFAULT 0;
temp_mn NUMBER DEFAULT 0;
BEGIN

    temp_mn := TO_NUMBER(TRIM(SUBSTR(f_005, INSTR(f_005, '-') + 1)));
    temp_yr := TO_NUMBER(TRIM(SUBSTR(f_005, 1, INSTR(f_005, '-') - 1)));
    temp_out := temp_yr * 12 + temp_mn;
    RETURN temp_out;
    
END;
 FUNCTION get_header_by_column_num(f_column_number IN apex_collections.c001%TYPE
                                  ,f_import_type   IN NUMBER
                                  ) RETURN VARCHAR2 IS
 temp_out VARCHAR2(1999);
 BEGIN
 
  CASE f_import_type
   WHEN 1 THEN --location
    NULL;
   WHEN 2 THEN --location levels
     CASE f_column_number
      WHEN 'C002' THEN temp_out := 'LOCATION LEVEL';
      WHEN 'C003' THEN temp_out := 'CONSTANT LEVEL';
      WHEN 'C004' THEN temp_out := 'UNIT';
      WHEN 'C005' THEN temp_out := 'CALENDAR OFFSET';
      WHEN 'C006' THEN temp_out := 'TIME OFFSET';
      WHEN 'C007' THEN temp_out := 'SEASONAL VALUE';
      WHEN 'C007' THEN temp_out := 'OFFICE';
     ELSE
      NULL;
     END CASE;   
   WHEN 3 THEN --Location level indicators
    NULL;
   ELSE 
    NULL;
   END CASE ;
 
 
 
  RETURN temp_out;
 
 END;
    FUNCTION Get_unit_code_from_code_id(f_unit_id IN cwms_unit.unit_id%TYPE
                                       ,p_file_id IN NUMBER) 
                                                --RETURN VARCHAR2 
                                                RETURN cwms_unit.unit_code%TYPE 
                                                                            IS
    temp_out cwms_unit.unit_code%TYPE; 
    BEGIN

    --RETURN ' COming in = ' || f_unit_id || ' with a length of ' || LENGTH(f_unit_id);

    IF f_unit_id IS NULL THEN
     RETURN NULL;
    END IF;

    SELECT unit_code
      INTO temp_out
      FROM cwms_unit
     WHERE unit_id = f_unit_id; --'n/a'; --f_unit_id;

  

        RETURN temp_out;
    EXCEPTION
    
     WHEN no_Data_found THEN
    
  Set_Log_Row (p_error_text   => ' Error in get_unit_code_from_code_id NO DATA FOUND for unit_id ' || f_unit_id  
                                ,p_file_id      => p_file_id
                                ,p_pl_sql_text  =>  'SELECT unit_code FROM cwms_unit WHERE unit_id = ' || f_unit_id
                );    


     cwms_err.raise(
         'no_data_found',
         f_unit_id,
         'unit code');
      
     

    END get_unit_code_from_code_id;
  FUNCTION get_headers_for_APEX_rpt(f_import_type IN NUMBER) RETURN VARCHAR2 IS
temp_out VARCHAR2(1999);
BEGIN

CASE f_import_type
 WHEN 2 THEN
  FOR x IN (SELECT 1 d FROM dual
                UNION ALL
                SELECT 2 d FROM dual
                UNION ALL
                SELECT 3 d FROM dual
                UNION ALL
                SELECT 4 d FROM dual
                UNION ALL
                SELECT 5 d FROM dual
                UNION ALL
                SELECT 6 d FROM dual
                UNION ALL
                SELECT 7 d FROM dual
             ) LOOP
                IF temp_out IS NULL THEN
                temp_out := get_header_by_column_num('C00' || TO_CHAR(x.d)
                                                          ,f_import_type
                                                      );
                 ELSE
                temp_out := temp_out
                           || ':' 
                           || get_header_by_column_num('C00' || TO_CHAR(x.d)
                                                          ,f_import_type
                                                      );
                END IF;
               END LOOP;
                

  NULL;
 ELSE
  NULL;
END CASE;
RETURN Temp_out;
END;   
 FUNCTION get_location_level_id_param(f_location_level_id IN VARCHAR2
                                    ,f_loc_num IN NUMBER
                                      ) RETURN VARCHAR2 IS
temp_out VARCHAR2(1999);
BEGIN

 FOR x IN (SELECT TO_NUMBER(rownum) row_num
                , REPLACE(column_value,'"','') col_val
             FROM TABLE(SELECT STR2TBL(f_location_level_id, '.') 
                          FROM dual
                       )
          )
           LOOP
            --RETURN x.row_num;
            CASE x.row_num
             WHEN f_loc_num THEN 
                temp_out := x.col_val; 
             ELSE
                NULL; 
            END CASE;          
           END LOOP ;

 RETURN temp_out;
END;

 FUNCTION strip_for_stragg( f_string IN VARCHAR2 ) RETURN VARCHAR2
                                                IS
begin
  return translate( f_string, g_bad_chars, 'a');

  g_bad_chars := 'a';
  for i in 0..255 loop
    if ( i not between ascii('a') and ascii('z') AND
         i not between ascii('A') and ascii('Z') AND
         i not between ascii('0') and ascii('9') AND 
         i NOT BETWEEN ascii(',') AND ascii(',') AND
         i NOT BETWEEN ascii('/') AND ascii('/')
         )
    then
      g_bad_chars := g_bad_chars || chr(i);
    end if;
  end loop;
end;



Function str2tbl( p_str in varchar2, p_delim in varchar2 default ',' ) return str2tblType
PIPELINED
as
    l_str      long default p_str || p_delim;
    l_n        number;
begin
    loop
        l_n := instr( l_str, p_delim );
        exit when (nvl(l_n,0) = 0);
        pipe row( ltrim(rtrim(substr(l_str,1,l_n-1))) );
        l_str := substr( l_str, l_n+1 );
    end loop;
    return;
end;
PROCEDURE Download_File(p_file_id in uploaded_xls_files_t.id%TYPE) IS
    v_mime      uploaded_xls_files_t.mime_type%TYPE;
    v_length    NUMBER;
    v_file_name uploaded_xls_files_t.file_name%TYPE;
    Lob_loc     uploaded_xls_files_t.blob_content%TYPE;
BEGIN

   UPDATE uploaded_xls_files_t
      SET num_downloaded = num_downloaded + 1
    WHERE id = p_file_id;

    SELECT mime_type, blob_content, file_name,dbms_lob.getlength(blob_content)
      INTO v_mime,lob_loc,v_file_name,v_length
      FROM uploaded_xls_files_t
     WHERE id = p_file_id;
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
                htp.p('Content-Disposition: attachment; filename="' || v_file_name || '"');
        -- close the headers        
                owa_util.http_header_close;
        -- download the BLOB
        wpg_docload.download_file( Lob_loc );
end download_file;

    
  PROCEDURE load_ll (p_collection_name IN VARCHAR2
                    ,p_fail_if_exists IN c_app_logic_no%TYPE DEFAULT c_app_logic_no
                    ) IS
tmpVar NUMBER;
temp_num  NUMBER DEFAULT 0;
p_seasonal_string VARCHAR2(4000);
BEGIN
   tmpVar := 0;
                --If the constant level (column 2 IS NOT NULL then it is a non-seasonal record
                --      INSERT
                -- ELSE
                --  it is a seasonal record, build the seasonal string
   

   
   FOR x IN (SELECT c001,c002,c003,c004,c008
               FROM apex_collections
              WHERE collection_name = p_collection_name
                AND c002 IS NOT NULL
                AND c001 > 1 -- column headers
                AND c007 IS NULL
              ORDER BY c001 ASC 
            ) LOOP

                 cwms_level.store_location_level2( p_location_level_id  => x.c002 --     in  varchar2,
                                                  ,p_level_value        => x.c003 --           in  number,
                                                  ,p_level_units        => x.c004 --         in  varchar2,
                                                  ,p_office_id          => x.c008
                                                  ,p_fail_if_exists     => p_fail_if_exists
                                                 );

                APEX_COLLECTION.DELETE_MEMBER (
                                               p_collection_name => p_collection_name
                                              ,p_seq => TO_CHAR(x.c001)
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
   p_location_level_id => ‘Elev.Inst.0.Base Flood Control’,
   p_level_value       =>  null,
   p_level_units       => ‘ft’,
   p_seasonal_values   => ‘0,0,723/6,0,723/6,14,723/7,0,723/8,0,723/11,30,723’,
   p_office_id         => ‘SWT’)

*/



   FOR x IN (SELECT b.*
                  , REPLACE(REPLACE(b.seasonal_Value_raw,',','/'),'-',',') seasonal_Value
               FROM (
                     SELECT c002
                          , c004
                          , C008              
                      , STRAGG(c005 || '-' || c006 || '-' || c007) seasonal_Value_raw
                      FROM (   

                            SELECT c002,c004,c006,c007,c008
                                 , c005  -- + c005_yr c005
                              FROM (
                                      SELECT c002 -- STRAGG(strip_for_stragg(c007)) seasonal_value
                                           , c004
                                           , calc_seasonal_mn_offset(c005) c005 -- cal offset
                                           , TO_NUMBER(TRIM(SUBSTR(c006, 0, INSTR(c006, ' ')))) * 24 * 60  c006 -- time offset
                                           , c007
                                           , c008
                                       FROM apex_collections
                                      WHERE collection_name = p_collection_name
                                        AND c003 IS NULL
                                        AND c007 IS NOT NULL
                                        AND c001 > 1 --column headers
                                        )
                           )
                     GROUP BY c002
                            , c004
                            , c008
                    ) b
   
             
   
             )
              LOOP


--                INSERT INTO TEMP_COLLECTION_API_FIRE_TBL
--                    (collection, user_id_fired, plsql_fired, seasonal_value)
--                    VALUES
--                    (p_collection_name
--                    , 'JEREMY1'
--                    , NULL
--                    , 'Seasonal Value = "' || x.seasonal_value || '"'
--                    || '<BR>' || ' Raw Value = "' || x.seasonal_value_raw || '"'
--                    );



                --Clean up the string          
                  p_seasonal_string := x.seasonal_value ; 
                  p_seasonal_string := REPLACE(p_seasonal_string, '/', CWMS_UTIL.RECORD_SEPARATOR );
                  p_seasonal_string := REPLACE(p_seasonal_string, ',', CWMS_UTIL.FIELD_SEPARATOR );
    

                  cwms_level.store_location_level2(
                                     p_location_level_id => x.c002 --     in  varchar2,
                                   , p_level_value       => NULL --           in  number,
                                   , p_level_units       => x.c004  --v_data_array(4) --         in  varchar2,
                                   , p_interval_months   => 12                                              
                                   , p_fail_if_exists    => p_fail_if_exists --p_fail_if_exists
                                   , p_seasonal_values   => p_seasonal_string --temp_seasonal_values --p_seasonal_string
                                   , p_office_id         => x.c008
                                    );



                    APEX_COLLECTION.DELETE_MEMBERS(
                                                    p_collection_name => p_collection_name
                                                  , p_attr_number     => 2 --c002 
                                                  , p_attr_value      => x.c002 
                                                  );

--  INSERT INTO TEMP_COLLECTION_API_FIRE_TBL
--                    (collection, user_id_fired, plsql_fired, seasonal_value)
--                    VALUES
--                    (p_collection_name, 'JEREMY after fire', NULL, p_seasonal_String);



              END LOOP;   
                   
              
    SELECT COUNT(c001)
      INTO temp_num
      FROM apex_collections
     WHERE collection_name = p_collection_name;                           

    IF temp_num = 1 THEN 
       APEX_COLLECTION.TRUNCATE_COLLECTION(p_collection_name);
    END IF;
   
   EXCEPTION

     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END LOAD_LL;


  PROCEDURE Load_LLI(p_file_name        IN apex_application_files.filename%TYPE 
                    ,p_user_id          IN uploaded_xls_files_t.user_id_uploaded%TYPE
                    ,p_old_file_id      IN uploaded_xls_files_t.id%TYPE DEFAULT NULL
                    ,p_reload_xls_file  IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
                    ,p_debug_yn         IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
                    )
                     IS
 t_error_debug      VARCHAR2(4000);
  p_file_id           uploaded_xls_files_t.id%TYPE DEFAULT NULL;

 temp_loc_lvl_ind_id NUMBER;
 temp_err_msg        VARCHAR2(1999);
 temp_err_html       VARCHAR2(1999);

 v_blob_data        BLOB;
 v_blob_len         NUMBER;
 v_position         NUMBER;
 v_raw_chunk        RAW(10000);
 v_char             CHAR(1);
 c_chunk_len        number       := 1;
 v_line             VARCHAR2 (32767)        := NULL;
 v_data_array       wwv_flow_global.vc_arr2;
 v_rows             number;
 v_sr_no            number := 1;
 temp_error         VARCHAR2(1999);
 temp_num_rows      NUMBER DEFAULT 0;
 
--Contions Variables per Mike P's example
 l_conditions                loc_lvl_indicator_cond_tab_t := loc_lvl_indicator_cond_tab_t();
 l_indicator                 loc_lvl_indicator_t;
 l_office_id                 VARCHAR2(16) := 'CPC';
 l_unit_code                 NUMBER(10);
 l_location_id               varchar2(49)    ;
 l_parameter_id             varchar2(49)    ;
 l_parameter_type_id    varchar2(16)    ;
 l_duration_id          varchar2(16)    ;
 l_specified_level_id   varchar2(256)   ;
 l_location_level_id    varchar2(390)   ;

 -- l_na           VARCHAR2(3) DEFAULT 'n/a';
 l_na           VARCHAR2(3) DEFAULT NULL;

-- insert variables (unsure) 
       t_attr_id                  VARCHAR2(1999);
       t_attr_unit                VARCHAR2(1999);
--Clear variables
       t_level_indicator_code     at_loc_lvl_indicator.level_indicator_code%TYPE;
       t_location_code            VARCHAR2(1999);
       t_parameter_code           at_loc_lvl_indicator.parameter_code%TYPE;
       t_parameter_type_code      at_loc_lvl_indicator.parameter_type_code%TYPE;
       t_duration_code            at_loc_lvl_indicator.duration_code%TYPE;
       t_specified_level_code     number;
       t_level_indicator_id       varchar2(1999);
       t_attr_value               at_loc_lvl_indicator.attr_value%TYPE DEFAULT NULL;
       t_attr_parameter_code      at_loc_lvl_indicator.attr_parameter_code%TYPE DEFAULT NULL;
       t_attr_parameter_type_code at_loc_lvl_indicator.attr_parameter_type_code%TYPE DEFAULT NULL;
       t_attr_duration_code       at_loc_lvl_indicator.attr_duration_code%TYPE DEFAULT NULL;
       t_ref_level                VARCHAR2(1999);--at_loc_lvl_indicator.ref_specified_level_code%TYPE DEFAULT NULL;
       t_ref_attr_value           VARCHAR2(1999);--at_loc_lvl_indicator.ref_attr_value%TYPE DEFAULT NULL;
       t_minimum_duration         at_loc_lvl_indicator.minimum_duration%TYPE default null;
       t_maximum_age              at_loc_lvl_indicator.maximum_age%TYPE default null;
       t_md_p1                    VARCHAR2(100);
       t_md_p2                    VARCHAR2(100);
       t_md_p3                    VARCHAR2(100);
       t_ma_p1                    VARCHAR2(100);
       t_ma_p2                    VARCHAR2(100);
       t_ma_p3                    VARCHAR2(100);

--Conditions variables


      t1_expression                 at_loc_lvl_indicator_cond.expression%TYPE;
      t1_comparison_operator_1      at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
      t1_comparison_value_1         at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
      t1_comparison_unit            at_loc_lvl_indicator_cond.comparison_unit%TYPE;
      t1_connector                  at_loc_lvl_indicator_cond.connector%TYPE;
      t1_comparison_operator_2      at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
      t1_comparison_value_2         at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
      t1_rate_expression            at_loc_lvl_indicator_cond.rate_expression%TYPE;
      t1_rate_comparison_operator_1 at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
      t1_rate_comparison_value_1    at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
      t1_rate_comparison_unit       at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
      t1_rate_connector             at_loc_lvl_indicator_cond.rate_connector%TYPE ;
      t1_rate_comparison_operator_2 at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
      t1_rate_comparison_value_2    at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
      t1_rate_interval              at_loc_lvl_indicator_cond.rate_interval%TYPE;
      t1_description                at_loc_lvl_indicator_cond.description%TYPE;

      t2_expression                 at_loc_lvl_indicator_cond.expression%TYPE;
      t2_comparison_operator_1      at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
      t2_comparison_value_1         at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
      t2_comparison_unit            at_loc_lvl_indicator_cond.comparison_unit%TYPE;
      t2_connector                  at_loc_lvl_indicator_cond.connector%TYPE;
      t2_comparison_operator_2      at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
      t2_comparison_value_2         at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
      t2_rate_expression            at_loc_lvl_indicator_cond.rate_expression%TYPE;
      t2_rate_comparison_operator_1 at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
      t2_rate_comparison_value_1    at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
      t2_rate_comparison_unit       at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
      t2_rate_connector             at_loc_lvl_indicator_cond.rate_connector%TYPE ;
      t2_rate_comparison_operator_2 at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
      t2_rate_comparison_value_2    at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
      t2_rate_interval              at_loc_lvl_indicator_cond.rate_interval%TYPE;
      t2_description                at_loc_lvl_indicator_cond.description%TYPE;

      t3_expression                 at_loc_lvl_indicator_cond.expression%TYPE;
      t3_comparison_operator_1      at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
      t3_comparison_value_1         at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
      t3_comparison_unit            at_loc_lvl_indicator_cond.comparison_unit%TYPE;
      t3_connector                  at_loc_lvl_indicator_cond.connector%TYPE;
      t3_comparison_operator_2      at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
      t3_comparison_value_2         at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
      t3_rate_expression            at_loc_lvl_indicator_cond.rate_expression%TYPE;
      t3_rate_comparison_operator_1 at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
      t3_rate_comparison_value_1    at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
      t3_rate_comparison_unit       at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
      t3_rate_connector             at_loc_lvl_indicator_cond.rate_connector%TYPE ;
      t3_rate_comparison_operator_2 at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
      t3_rate_comparison_value_2    at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
      t3_rate_interval              at_loc_lvl_indicator_cond.rate_interval%TYPE;
      t3_description                at_loc_lvl_indicator_cond.description%TYPE;

      t4_expression                 at_loc_lvl_indicator_cond.expression%TYPE;
      t4_comparison_operator_1      at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
      t4_comparison_value_1         at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
      t4_comparison_unit            at_loc_lvl_indicator_cond.comparison_unit%TYPE;
      t4_connector                  at_loc_lvl_indicator_cond.connector%TYPE;
      t4_comparison_operator_2      at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
      t4_comparison_value_2         at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
      t4_rate_expression            at_loc_lvl_indicator_cond.rate_expression%TYPE;
      t4_rate_comparison_operator_1 at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
      t4_rate_comparison_value_1    at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
      t4_rate_comparison_unit       at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
      t4_rate_connector             at_loc_lvl_indicator_cond.rate_connector%TYPE ;
      t4_rate_comparison_operator_2 at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
      t4_rate_comparison_value_2    at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
      t4_rate_interval              at_loc_lvl_indicator_cond.rate_interval%TYPE;
      t4_description                at_loc_lvl_indicator_cond.description%TYPE;

      t5_expression                 at_loc_lvl_indicator_cond.expression%TYPE;
      t5_comparison_operator_1      at_loc_lvl_indicator_cond.comparison_operator_1%TYPE;
      t5_comparison_value_1         at_loc_lvl_indicator_cond.comparison_value_1%TYPE;
      t5_comparison_unit            at_loc_lvl_indicator_cond.comparison_unit%TYPE;
      t5_connector                  at_loc_lvl_indicator_cond.connector%TYPE;
      t5_comparison_operator_2      at_loc_lvl_indicator_cond.comparison_operator_2%TYPE;
      t5_comparison_value_2         at_loc_lvl_indicator_cond.comparison_value_2%TYPE;
      t5_rate_expression            at_loc_lvl_indicator_cond.rate_expression%TYPE;
      t5_rate_comparison_operator_1 at_loc_lvl_indicator_cond.rate_comparison_operator_1%TYPE;
      t5_rate_comparison_value_1    at_loc_lvl_indicator_cond.rate_comparison_value_1%TYPE;
      t5_rate_comparison_unit       at_loc_lvl_indicator_cond.rate_comparison_unit%TYPE;
      t5_rate_connector             at_loc_lvl_indicator_cond.rate_connector%TYPE ;
      t5_rate_comparison_operator_2 at_loc_lvl_indicator_cond.rate_comparison_operator_2%TYPE;
      t5_rate_comparison_value_2    at_loc_lvl_indicator_cond.rate_comparison_value_2%TYPE;
      t5_rate_interval              at_loc_lvl_indicator_cond.rate_interval%TYPE;
      t5_description                at_loc_lvl_indicator_cond.description%TYPE;

BEGIN

IF p_old_file_id IS NOT NULL AND p_reload_xls_file = c_app_logic_yes THEN
    --Get the BLOB and info from DB 
     p_file_id := p_old_file_id;
ELSE
    -- Process from APEX document repository

--Insert the XLS spreadsheet into the file repository table
  INSERT INTO uploaded_xls_files_t(id
                                 ,file_name
                                 , BLOB_CONTENT
                                 , MIME_TYPE
                                 , date_uploaded
                                 , user_id_uploaded

                                  ) 
                                  SELECT ID
                                          , p_file_name --:P615_FILE_NAME
                                          , blob_content
                                          , mime_type
                                          , SYSDATE
                                          , p_user_id
                                    FROM APEX_APPLICATION_FILES
                                    WHERE name = p_file_name;

  --Get the ID for future use
   SELECT ID
     INTO p_file_id
     FROM APEX_APPLICATION_FILES
    WHERE name = p_file_name;

  --Clean up the APEX File Repository
   DELETE apex_application_files
    WHERE name = p_file_name;

END IF; -- if p_old_file id IS NOT NULL 

  -- Read data from uploaded document repository
     SELECT blob_content 
       INTO v_blob_data
       FROM uploaded_xls_files_t
      WHERE id = p_file_id;

IF p_debug_yn = c_app_logic_yes THEN
Set_Log_Row (p_error_text  =>'Entering BLOB Loop with file id  "' || p_file_id || '"'
                            || ' and BLOB Length of '  || LENGTH(v_blob_data)
            ,p_file_id     => p_file_id
            ,p_pl_sql_text => ' Entering Processing Loop'
            ); 
END IF;
--Begin Loop
 v_blob_len := dbms_lob.getlength(v_blob_data);
 v_position := 1;

-- Read and convert binary to char</span>
-- Read the BLOB and parse into table to be processed
 WHILE ( v_position <= v_blob_len ) 
        LOOP
            NULL;
           v_raw_chunk := dbms_lob.substr(v_blob_data,c_chunk_len,v_position);
           v_char :=  chr(cwms_apex.hex_to_decimal(rawtohex(v_raw_chunk)));
           v_line := v_line || v_char;
           v_position := v_position + c_chunk_len;
           -- When a whole line is retrieved </span>

            IF v_char = CHR(10) THEN
             v_line := REPLACE(v_line, ',',':');        
        
        

                IF temp_num_rows = 0 THEN
                 -- DO nothing, this is the column title 
                  NULL;
                ELSE
               
                -- Clean up the quotes             
                    --v_line := REPLACE(v_line, '"','');

                FOR y IN (
                            SELECT rownum row_num
                                 --, strip_for_stragg(column_value) col_val
                                 , REPLACE(column_value,'"','') col_val
                              FROM TABLE(SELECT STR2TBL(v_line, ':') 
                                           FROM dual
                                         )
                          ) LOOP
 BEGIN

                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row "' || temp_num_rows 
                                                       || '"Column  "' || y.row_num || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Variable CASE Statement with XLS Column value of "' || y.col_val 
                                                        || '" and a length of "' || LENGTH(y.col_val) || '"'
                                        ); 
                            END IF;


                             CASE y.row_num
                              WHEN 1 THEN t_level_indicator_id := y.col_val;
                                          l_location_level_id  := y.col_val;
                              WHEN 2 THEN t_attr_id            := TO_NUMBER(y.col_val); -- attr_id 
                              WHEN 3 THEN t_attr_value         := TO_NUMBER(y.col_val);
                              WHEN 4 THEN t_attr_unit          := Get_unit_code_from_code_id(y.col_val,p_file_id); -- attr_unit 
                              WHEN 5 THEN t_ref_level          := y.col_Val; --t_ref_specified_level_code 
                              WHEN 6 THEN t_ref_attr_value          := y.col_val; 
                              WHEN 7 THEN t_md_p1                   := y.col_val;  --md p1  
                              WHEN 8 THEN t_md_p2                   := y.col_val;  --md p2 
                              WHEN 9 THEN t_md_p3                   := y.col_val;  --md p3
--                                          t_minimum_duration  := t_md_p1 || ':' || t_md_p2 || ':' || t_md_p3; 
                              WHEN 10 THEN t_ma_p1                  := y.col_val; --ma p1  
                              WHEN 11 THEN t_ma_p2                  := y.col_val; --ma p2 
                              WHEN 12 THEN t_ma_p3                  := y.col_val; --ma p3
--                                           t_maximum_age   := t_ma_p1 || ':' || t_ma_p2 || ':' || t_ma_p3;
                              WHEN 13 THEN t1_expression            := y.col_val;
                              WHEN 14 THEN t1_comparison_unit       := Get_unit_code_from_code_id(y.col_val,p_file_id);
                              WHEN 15 THEN t1_comparison_operator_1 := y.col_val;
                              WHEN 16 THEN t1_comparison_value_1    := y.col_val;
                              WHEN 17 THEN t1_connector             := y.col_val;
                              WHEN 18 THEN t1_comparison_operator_2 := y.col_val;
                              WHEN 19 THEN t1_comparison_value_2    := y.col_Val;
                              WHEN 20 THEN t1_rate_expression       := y.col_Val;
                              WHEN 21 THEN t1_rate_comparison_unit  := y.col_Val;
                              WHEN 22 THEN t1_rate_interval         := y.col_Val;
                              WHEN 23 THEN t1_rate_comparison_operator_1 := y.col_val;
                              WHEN 24 THEN t1_rate_comparison_value_1    := y.col_val;
                              WHEN 25 THEN t1_rate_connector        := y.col_Val;
                              WHEN 26 THEN t1_rate_comparison_operator_2 := y.col_val;
                              WHEN 27 THEN t1_rate_comparison_value_2 := y.col_Val;
                              WHEN 28 THEN t1_description           := y.col_Val;

                              WHEN 29 THEN t2_expression            := y.col_val;
                              WHEN 30 THEN t2_comparison_unit       := Get_unit_code_from_code_id(y.col_val,p_file_id);
                              WHEN 31 THEN t2_comparison_operator_1 := y.col_val;
                              WHEN 32 THEN t2_comparison_value_1    := y.col_val;
                              WHEN 33 THEN t2_connector             := y.col_val;
                              WHEN 34 THEN t2_comparison_operator_2 := y.col_val;
                              WHEN 35 THEN t2_comparison_value_2    := y.col_Val;
                              WHEN 36 THEN t2_rate_expression       := y.col_Val;
                              WHEN 37 THEN t2_rate_comparison_unit  := y.col_Val;
                              WHEN 38 THEN t2_rate_interval         := y.col_Val;
                              WHEN 39 THEN t2_rate_comparison_operator_1 := y.col_val;
                              WHEN 40 THEN t2_rate_comparison_value_1    := y.col_val;
                              WHEN 41 THEN t2_rate_connector        := y.col_Val;
                              WHEN 42 THEN t2_rate_comparison_operator_2 := y.col_val;
                              WHEN 43 THEN t2_rate_comparison_value_2 := y.col_Val;
                              WHEN 44 THEN t2_description           := y.col_Val;

                              WHEN 45 THEN t3_expression            := y.col_val;
                              WHEN 46 THEN t3_comparison_unit       := Get_unit_code_from_code_id(y.col_val,p_file_id);
                              WHEN 47 THEN t3_comparison_operator_1 := y.col_val;
                              WHEN 48 THEN t3_comparison_value_1    := y.col_val;
                              WHEN 49 THEN t3_connector             := y.col_val;
                              WHEN 50 THEN t3_comparison_operator_2 := y.col_val;
                              WHEN 51 THEN t3_comparison_value_2    := y.col_Val;
                              WHEN 52 THEN t3_rate_expression       := y.col_Val;
                              WHEN 53 THEN t3_rate_comparison_unit  := y.col_Val;
                              WHEN 54 THEN t3_rate_interval         := y.col_Val;
                              WHEN 55 THEN t3_rate_comparison_operator_1 := y.col_val;
                              WHEN 56 THEN t3_rate_comparison_value_1    := y.col_val;
                              WHEN 57 THEN t3_rate_connector        := y.col_Val;
                              WHEN 58 THEN t3_rate_comparison_operator_2 := y.col_val;
                              WHEN 59 THEN t3_rate_comparison_value_2 := y.col_Val;
                              WHEN 60 THEN t3_description           := y.col_Val;

                              WHEN 61 THEN t4_expression            := y.col_val;
                              WHEN 62 THEN t4_comparison_unit       := Get_unit_code_from_code_id(y.col_val,p_file_id);
--Set_Log_Row (p_error_text  =>'setting t4_comparison unit to "' || t4_comparison_unit || '"'
--                            || ' from '  || y.col_val
--            ,p_file_id     => p_file_id
--            ,p_pl_sql_text => ' WHEN 14 THEN t4_comparison_unit       := Get_unit_code_from_code_id(y.col_val);'
--            ); 

                              WHEN 63 THEN t4_comparison_operator_1 := y.col_val;
                              WHEN 64 THEN t4_comparison_value_1    := y.col_val;
                              WHEN 65 THEN t4_connector             := y.col_val;
                              WHEN 66 THEN t4_comparison_operator_2 := y.col_val;
                              WHEN 67 THEN t4_comparison_value_2    := y.col_Val;
                              WHEN 68 THEN t4_rate_expression       := y.col_Val;
                              WHEN 69 THEN t4_rate_comparison_unit  := y.col_Val;
                              WHEN 70 THEN t4_rate_interval         := y.col_Val;
                              WHEN 71 THEN t4_rate_comparison_operator_1 := y.col_val;
                              WHEN 72 THEN t4_rate_comparison_value_1    := y.col_val;
                              WHEN 73 THEN t4_rate_connector        := y.col_Val;
                              WHEN 74 THEN t4_rate_comparison_operator_2 := y.col_val;
                              WHEN 75 THEN t4_rate_comparison_value_2 := y.col_Val;
                              WHEN 76 THEN t4_description           := y.col_Val;

                              WHEN 77 THEN t5_expression            := y.col_val;
                              WHEN 78 THEN t5_comparison_unit       := Get_unit_code_from_code_id(y.col_val,p_file_id);
                              WHEN 79 THEN t5_comparison_operator_1 := y.col_val;
                              WHEN 80 THEN t5_comparison_value_1    := y.col_val;
                              WHEN 81 THEN t5_connector             := y.col_val;
                              WHEN 82 THEN t5_comparison_operator_2 := y.col_val;
                              WHEN 83 THEN t5_comparison_value_2    := y.col_Val;
                              WHEN 84 THEN t5_rate_expression       := y.col_Val;
                              WHEN 85 THEN t5_rate_comparison_unit  := y.col_Val;
                              WHEN 86 THEN t5_rate_interval         := y.col_Val;
                              WHEN 87 THEN t5_rate_comparison_operator_1 := y.col_val;
                              WHEN 88 THEN t5_rate_comparison_value_1   := y.col_val;
                              WHEN 89 THEN t5_rate_connector            := y.col_Val;
                              WHEN 90 THEN t5_rate_comparison_operator_2 := y.col_val;
                              WHEN 91 THEN t5_rate_comparison_value_2   := y.col_Val;
                              WHEN 92 THEN t5_description               := y.col_Val;

                              WHEN 93 THEN t_location_code              := y.col_Val;
                             
                             ELSE
                              NULL;
                             END CASE;






                             EXCEPTION

                              WHEN others THEN 
                                 NULL;
                                 temp_Err_msg := sqlerrm;
                                 t_error_debug := NULL;
                                 
                                 CASE y.row_num
                                  WHEN 1 THEN t_error_debug := '1. t_level_indicator_id set to: ' || y.col_val;
                                  WHEN 2 THEN t_error_debug := '2. t_attr_id set to: ' || y.col_val;
                                  WHEN 14 THEN t_error_debug := '14. t1_comparison_unit  set to: ' || y.col_val; 
                                 ELSE
                                  NULL;
                                 END CASE;
                                 
                                 
                                 INSERT INTO uploaded_xls_file_rows_t (
                                                      id, file_id,date_uploaded,user_id_uploaded,date_last_updated,user_id_last_updated
                                                     ,error_code_original, pl_Sql_call, single_row_yn, seasonal_component)
                                                   VALUES
                                                      (UPLOADED_XLS_FILE_ROWS_SEQ.nextval
                                                      , p_file_id
                                                      , SYSDATE
                                                      , p_user_id
                                                      , SYSDATE
                                                      , p_user_id
                                                      , y.row_num || '. adding record bad conversion in array column ' || y.row_num
                                                        || ' XLS colum ' || TO_NUMBER((y.row_num - 4))
                                                        || ' with value of: ' || y.col_val
                                                        || ' Length of the field is: ' || CASE 
                                                                                           WHEN y.col_val IS NULL THEN 'EMPTY'
                                                                                           ELSE TO_CHAR(LENGTH(y.col_val))
                                                                                          END
                                                        || ' Field Value is "' || y.col_val || '"'
                                                        || ' Error = ' || temp_Err_msg
                                                        || ' Error Debug = ' || t_error_debug
                                                        --14 = ' || t1_comparison_unit || ' vs. ' || y.col_val
                                                      , v_line
                                                      , c_app_logic_yes
                                                      , NULL 
                                                      );
                             END;
                            END LOOP;
BEGIN
                                NULL;
                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row  "' || temp_num_rows || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Conditions Variable 1 Processing'
                                        ); 
                            END IF;
                               l_conditions.delete;
                               l_conditions.extend(5);
                               l_conditions(1) := loc_lvl_indicator_cond_t(
                                  p_indicator_value            => 1,
                                  p_expression                 => t1_expression,
                                  p_comparison_operator_1      => t1_comparison_operator_1,
                                  p_comparison_value_1         => t1_comparison_Value_1,
                                  p_comparison_unit            => t1_comparison_unit,
                                  p_connector                  => t1_connector,
                                  p_comparison_operator_2      => t1_comparison_operator_2,
                                  p_comparison_value_2         => t1_comparison_value_2,
                                  p_rate_expression            => t1_rate_expression,
                                  p_rate_comparison_operator_1 => t1_rate_comparison_operator_1,
                                  p_rate_comparison_value_1    => t1_rate_comparison_value_1,
                                  p_rate_comparison_unit       => t1_rate_comparison_unit,
                                  p_rate_connector             => t1_rate_connector,
                                  p_rate_comparison_operator_2 => t1_rate_comparison_operator_2,
                                  p_rate_comparison_value_2    => t1_rate_comparison_value_2 ,
                                  p_rate_interval              => t1_rate_interval,
                                  p_description                => t1_description);


                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row  "' || temp_num_rows || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Conditions Variable 2 Processing'
                                        );
                            END IF;           

                               l_conditions(2) := loc_lvl_indicator_cond_t(
                                  p_indicator_value            => 2,
                                  p_expression                 => t2_expression,
                                  p_comparison_operator_1      => t2_comparison_operator_1,
                                  p_comparison_value_1         => t2_comparison_Value_1,
                                  p_comparison_unit            => t2_comparison_unit,
                                  p_connector                  => t2_connector,
                                  p_comparison_operator_2      => t2_comparison_operator_2,
                                  p_comparison_value_2         => t2_comparison_value_2,
                                  p_rate_expression            => t2_rate_expression,
                                  p_rate_comparison_operator_1 => t2_rate_comparison_operator_1,
                                  p_rate_comparison_value_1    => t2_rate_comparison_value_1,
                                  p_rate_comparison_unit       => t2_rate_comparison_unit,
                                  p_rate_connector             => t2_rate_connector,
                                  p_rate_comparison_operator_2 => t2_rate_comparison_operator_2,
                                  p_rate_comparison_value_2    => t2_rate_comparison_value_2 ,
                                  p_rate_interval              => t2_rate_interval,
                                  p_description                => t2_description);

                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row  "' || temp_num_rows || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Conditions Variable 3 Processing'
                                        );
                            END IF;                                      

                               l_conditions(3) := loc_lvl_indicator_cond_t(
                                  p_indicator_value            => 3,
                                  p_expression                 => t3_expression,
                                  p_comparison_operator_1      => t3_comparison_operator_1,
                                  p_comparison_value_1         => t3_comparison_Value_1,
                                  p_comparison_unit            => t3_comparison_unit,
                                  p_connector                  => t3_connector,
                                  p_comparison_operator_2      => t3_comparison_operator_2,
                                  p_comparison_value_2         => t3_comparison_value_2,
                                  p_rate_expression            => t3_rate_expression,
                                  p_rate_comparison_operator_1 => t3_rate_comparison_operator_1,
                                  p_rate_comparison_value_1    => t3_rate_comparison_value_1,
                                  p_rate_comparison_unit       => t3_rate_comparison_unit,
                                  p_rate_connector             => t3_rate_connector,
                                  p_rate_comparison_operator_2 => t3_rate_comparison_operator_2,
                                  p_rate_comparison_value_2    => t3_rate_comparison_value_2 ,
                                  p_rate_interval              => t3_rate_interval,
                                  p_description                => t3_description);

                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row  "' || temp_num_rows || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Conditions Variable 4 Processing'
                                        );
                            END IF;          

                               l_conditions(4) := loc_lvl_indicator_cond_t(
                                  p_indicator_value            => 4,
                                  p_expression                 => t4_expression,
                                  p_comparison_operator_1      => t4_comparison_operator_1,
                                  p_comparison_value_1         => t4_comparison_Value_1,
                                  p_comparison_unit            => t4_comparison_unit,
                                  p_connector                  => t4_connector,
                                  p_comparison_operator_2      => t4_comparison_operator_2,
                                  p_comparison_value_2         => t4_comparison_value_2,
                                  p_rate_expression            => t4_rate_expression,
                                  p_rate_comparison_operator_1 => t4_rate_comparison_operator_1,
                                  p_rate_comparison_value_1    => t4_rate_comparison_value_1,
                                  p_rate_comparison_unit       => t4_rate_comparison_unit,
                                  p_rate_connector             => t4_rate_connector,
                                  p_rate_comparison_operator_2 => t4_rate_comparison_operator_2,
                                  p_rate_comparison_value_2    => t4_rate_comparison_value_2 ,
                                  p_rate_interval              => t4_rate_interval,
                                  p_description                => t4_description);
                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row  "' || temp_num_rows || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Conditions Variable 5 Processing'
                                        );
                            END IF;
                                      

                               l_conditions(5) := loc_lvl_indicator_cond_t(
                                  p_indicator_value            => 5,
                                  p_expression                 => t5_expression,
                                  p_comparison_operator_1      => t5_comparison_operator_1,
                                  p_comparison_value_1         => t5_comparison_Value_1,
                                  p_comparison_unit            => t5_comparison_unit,
                                  p_connector                  => t5_connector,
                                  p_comparison_operator_2      => t5_comparison_operator_2,
                                  p_comparison_value_2         => t5_comparison_value_2,
                                  p_rate_expression            => t5_rate_expression,
                                  p_rate_comparison_operator_1 => t5_rate_comparison_operator_1,
                                  p_rate_comparison_value_1    => t5_rate_comparison_value_1,
                                  p_rate_comparison_unit       => t5_rate_comparison_unit,
                                  p_rate_connector             => t5_rate_connector,
                                  p_rate_comparison_operator_2 => t5_rate_comparison_operator_2,
                                  p_rate_comparison_value_2    => t5_rate_comparison_value_2 ,
                                  p_rate_interval              => t5_rate_interval,
                                  p_description                => t5_description);

                            --Interval Calculations
                                t_minimum_duration  := TO_DSINTERVAL(t_md_p1 || ':' || t_md_p2 || ':' || t_md_p3);
                                t_maximum_age       := TO_DSINTERVAL(t_ma_p1 || ':' || t_ma_p2 || ':' || t_ma_p3);

                               IF p_debug_yn = c_app_logic_yes THEN
                                Set_Log_Row (p_error_text  =>'Finished Processing Row  "' || temp_num_rows || '" Intervals'
                                            ,p_file_id     => p_file_id
                                            ,p_pl_sql_text => ' t_minimum_duration = "' || t_minimum_duration || '"'
                                                            || '<BR> P1 = "' || t_md_p1 || '" P2 = "' || t_md_p2 || '" P3 = "' || t_md_p3 || '"'
                                                            || '<BR>t_maximum_age = "' || t_maximum_age || '"'
                                                            || '<BR> P1 = "' || t_ma_p1 || '" P2 = "' || t_ma_p2 || '" P3 = "' || t_ma_p3 || '"'
                                            );
                                END IF;


                             temp_err_html := ' 1 A = ' || t_level_indicator_id    || '<BR>' ||
                                              ' 2 B = ' || t_attr_id               || '<BR>' ||
                                              ' 3 C = ' || t_attr_value            || '<BR>' ||
                                              ' 4 D = ' || t_attr_unit             || '<BR>' ||
                                              ' 5 E = ' || t_ref_level             || '<BR>' ||
                                              ' 6 F = ' || t_ref_attr_value        || '<BR>' ||
                                              ' 7 G = ' || t_md_p1                 || '<BR>' ||
                                              ' 8 G = ' || t_md_p2                 || '<BR>' ||
                                              ' 9 G = ' || t_md_p3                 || '<BR>' ||
                                              '10 H = ' || t_ma_p1                 || '<BR>' ||
                                              '11 H = ' || t_ma_p2                 || '<BR>' ||
                                              '12 H = ' || t_ma_p3                 || '<BR>' ||
                                              '13 I = ' || t1_expression           || '<BR>' ||
                                              '14 J = ' || t1_comparison_unit      || '<BR>' ||   
                                              '15 K = ' || t1_comparison_operator_1  || '<BR>' ||
                                              '16 L = ' || t1_comparison_value_1   || '<BR>' ||
                                              '17 M = ' || t1_connector            || '<BR>' ||
                                              '18 N = ' || t1_comparison_operator_2 || '<BR>' ||
                                              '19 O = ' || t1_comparison_value_2  || '<BR>' ||
                                              '20 P = ' || t1_rate_expression || '<BR>' ||
                                              '21 Q = ' || t1_rate_comparison_unit  || '<BR>' ||
                                              '22 R = ' || t1_rate_interval          || '<BR>' ||
                                              '23 S = ' || t1_rate_comparison_operator_1  || '<BR>' ||
                                              '24 T = ' || t1_rate_comparison_value_1  || '<BR>' ||
                                              '25 U = ' || t1_rate_connector         || '<BR>' ||
                                              '26 V = ' || t1_rate_comparison_operator_2 || '<BR>' ||
                                              '27 W = ' || t1_rate_comparison_value_2 || '<BR>' ||
                                              '28 X = ' || t1_description     || '<BR>' ||
                                              '29 Y = ' || t2_expression            || '<BR>' ||
                                              '30 Z = ' || t2_comparison_unit       || '<BR>' ||
                                              '31 AA = ' || t2_comparison_operator_1 || '<BR>' ||
                                              '32 AB = ' || t2_comparison_value_1    || '<BR>' ||
                                              '33 AC = ' || t2_connector             || '<BR>' ||
                                              '34 AD = ' || t2_comparison_operator_2 || '<BR>' ||
                                              '35 AE = ' || t2_comparison_value_2    || '<BR>' ||
                                              '36 AF = ' || t2_rate_expression       || '<BR>' ||
                                              '37 AG = ' || t2_rate_comparison_unit  || '<BR>' ||
                                              '38 AH = ' || t2_rate_interval         || '<BR>' ||
                                              '39 AI = ' || t2_rate_comparison_operator_1 || '<BR>' ||
                                              '40 AJ = ' || t2_rate_comparison_value_1    || '<BR>' ||
                                              '41 AK = ' || t2_rate_connector        || '<BR>' ||
                                              '42 AL = ' || t2_rate_comparison_operator_2 || '<BR>' ||
                                              '43 AM = ' || t2_rate_comparison_value_2 || '<BR>' ||
                                              '44 AN = ' || t2_description           || '<BR>' ||
                                              '45 AO = ' || t3_expression            || '<BR>' ||
                                              '46 AP = ' || t3_comparison_unit       || '<BR>' ||
                                              '47 AQ = ' || t3_comparison_operator_1 || '<BR>' ||
                                              '48 AR = ' || t3_comparison_value_1    || '<BR>' ||
                                              '49 AS = ' || t3_connector             || '<BR>' ||
                                              '50 AT = ' || t3_comparison_operator_2 || '<BR>' ||
                                              '51 AU = ' || t3_comparison_value_2    || '<BR>' ||
                                              '52 AV = ' || t3_rate_expression       || '<BR>' ||
                                              '53 AW = ' || t3_rate_comparison_unit  || '<BR>' ||
                                              '54 AX = ' || t3_rate_interval         || '<BR>' ||
                                              '55 AY = ' || t3_rate_comparison_operator_1 || '<BR>' ||
                                              '56 AZ = ' || t3_rate_comparison_value_1    || '<BR>' ||
                                              '57 BA = ' || t3_rate_connector        || '<BR>' ||
                                              '58 BB = ' || t3_rate_comparison_operator_2 || '<BR>' ||
                                              '59 BC = ' || t3_rate_comparison_value_2 || '<BR>' ||
                                              '60 BD = ' || t3_description           || '<BR>' ||

                                              '61 BE = ' || t4_expression            || '<BR>' ||
                                              '62 BF = ' || t4_comparison_unit       || '<BR>' ||
                                              '63 BG = ' || t4_comparison_operator_1 || '<BR>' ||
                                              '64 BH = ' || t4_comparison_value_1    || '<BR>' ||
                                              '65 BI = ' || t4_connector             || '<BR>' ||
                                              '66 BJ = ' || t4_comparison_operator_2 || '<BR>' ||
                                              '67 BK = ' || t4_comparison_value_2    || '<BR>' ||
                                              '68 BL = ' || t4_rate_expression       || '<BR>' ||
                                              '69 BM = ' || t4_rate_comparison_unit  || '<BR>' ||
                                              '70 BN = ' || t4_rate_interval         || '<BR>' ||
                                              '71 BO = ' || t4_rate_comparison_operator_1 || '<BR>' ||
                                              '72 BP = ' || t4_rate_comparison_value_1    || '<BR>' ||
                                              '73 BQ = ' || t4_rate_connector        || '<BR>' ||
                                              '74 BR = ' || t4_rate_comparison_operator_2 || '<BR>' ||
                                              '75 BS = ' || t4_rate_comparison_value_2 || '<BR>' ||
                                              '76 BT = ' || t4_description           || '<BR>' ||
                                              '77 BU = ' || t5_expression            || '<BR>' ||
                                              '78 BV = ' || t5_comparison_unit       || '<BR>' ||
                                              '79 BW = ' || t5_comparison_operator_1 || '<BR>' ||
                                              '80 BX = ' || t5_comparison_value_1    || '<BR>' ||
                                              '81 BY = ' || t5_connector             || '<BR>' ||
                                              '82 BZ = ' || t5_comparison_operator_2 || '<BR>' ||
                                              '83 CA = ' || t5_comparison_value_2    || '<BR>' ||
                                              '84 CB = ' || t5_rate_expression       || '<BR>' ||
                                              '85 CC = ' || t5_rate_comparison_unit  || '<BR>' ||
                                              '86 CD = ' || t5_rate_interval         || '<BR>' ||
                                              '87 CE = ' || t5_rate_comparison_operator_1 || '<BR>' ||
                                              '88 CF = ' || t5_rate_comparison_value_1    || '<BR>' ||
                                              '89 CG = ' || t5_rate_connector        || '<BR>' ||
                                              '90 CH = ' || t5_rate_comparison_operator_2 || '<BR>' ||
                                              '91 CI = ' || t5_rate_comparison_value_2 || '<BR>' ||
                                              '92 CJ = ' || t5_description           || '<BR>' ||
                                              '93 CK = ' || t_location_code          || '<BR>' ||
                                              'Interval 1, Minimum Duration = ' || t_minimum_duration || '<BR>' ||
                                              'Interval 2, Maximum Age = '      || t_maximum_age
                                              ;

                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  => 'Logging Setting Page API Variables from XLS! --' || temp_err_msg
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => 'LINE #' || temp_num_rows || '<BR>'
                                                       || ' = "' || v_line || '"<BR>'
                                                       || 'p_office_id = ' || t_location_code || '<BR>'
                                                       || 'p_location_level_id = ' || l_location_level_id || '<BR>'
                                                       || 'Internal Variables and Excel Cell Columns<BR>' || temp_err_html
                                         );
                            END IF;


                            IF p_debug_yn = c_app_logic_yes THEN
                            Set_Log_Row (p_error_text  =>'Processing Row  "' || temp_num_rows || '"'
                                        ,p_file_id     => p_file_id
                                        ,p_pl_sql_text => ' Entering Load_LLI_2'
                                        );
                            END IF;

                               load_lli_2( p_attr_id                   => t_attr_id
                                          , p_attr_value                => t_Attr_value
                                          , p_attr_unit                 => t_attr_unit
                                          , p_conditions                => l_conditions
                                          , p_file_id                   => p_file_id
                                          , p_indicator                 => l_indicator
                                          , p_location_level_id         => l_location_level_id
                                          , p_maximum_age               => t_maximum_age
                                          , p_minimum_duration          => t_minimum_duration
                                          , p_office_id                 => t_location_code
                                          , p_ref_specified_level_id    => t_ref_level 
                                          , p_ref_attr_value            => t_ref_attr_value 
                                          , p_debug_yn                  => p_debug_yn 
                                         );
                               
                            EXCEPTION
                             WHEN others THEN
                             
                             temp_Err_msg := sqlerrm;
                             
                             temp_err_html := ' 1 A = ' || t_level_indicator_id    || '<BR>' ||
                                              ' 2 B = ' || t_attr_id               || '<BR>' ||
                                              ' 3 C = ' || t_attr_value            || '<BR>' ||
                                              ' 4 D = ' || t_attr_unit             || '<BR>' ||
                                              ' 5 E = ' || t_ref_level             || '<BR>' ||
                                              ' 6 F = ' || t_ref_attr_value        || '<BR>' ||
                                              ' 7 G = ' || t_md_p1                 || '<BR>' ||
                                              ' 8 G = ' || t_md_p2                 || '<BR>' ||
                                              ' 9 G = ' || t_md_p3                 || '<BR>' ||
                                              '10 H = ' || t_ma_p1                 || '<BR>' ||
                                              '11 H = ' || t_ma_p2                 || '<BR>' ||
                                              '12 H = ' || t_ma_p3                 || '<BR>' ||
                                              '13 I = ' || t1_expression           || '<BR>' ||
                                              '14 J = ' || t1_comparison_unit      || '<BR>' ||   
                                              '15 K = ' || t1_comparison_operator_1  || '<BR>' ||
                                              '16 L = ' || t1_comparison_value_1   || '<BR>' ||
                                              '17 M = ' || t1_connector            || '<BR>' ||
                                              '18 N = ' || t1_comparison_operator_2 || '<BR>' ||
                                              '19 O = ' || t1_comparison_value_2  || '<BR>' ||
                                              '20 P = ' || t1_rate_expression || '<BR>' ||
                                              '21 Q = ' || t1_rate_comparison_unit  || '<BR>' ||
                                              '22 R = ' || t1_rate_interval          || '<BR>' ||
                                              '23 S = ' || t1_rate_comparison_operator_1  || '<BR>' ||
                                              '24 T = ' || t1_rate_comparison_value_1  || '<BR>' ||
                                              '25 U = ' || t1_rate_connector         || '<BR>' ||
                                              '26 V = ' || t1_rate_comparison_operator_2 || '<BR>' ||
                                              '27 W = ' || t1_rate_comparison_value_2 || '<BR>' ||
                                              '28 X = ' || t1_description     || '<BR>' ||
                                              '29 Y = ' || t2_expression            || '<BR>' ||
                                              '30 Z = ' || t2_comparison_unit       || '<BR>' ||
                                              '31 AA = ' || t2_comparison_operator_1 || '<BR>' ||
                                              '32 AB = ' || t2_comparison_value_1    || '<BR>' ||
                                              '33 AC = ' || t2_connector             || '<BR>' ||
                                              '34 AD = ' || t2_comparison_operator_2 || '<BR>' ||
                                              '35 AE = ' || t2_comparison_value_2    || '<BR>' ||
                                              '36 AF = ' || t2_rate_expression       || '<BR>' ||
                                              '37 AG = ' || t2_rate_comparison_unit  || '<BR>' ||
                                              '38 AH = ' || t2_rate_interval         || '<BR>' ||
                                              '39 AI = ' || t2_rate_comparison_operator_1 || '<BR>' ||
                                              '40 AJ = ' || t2_rate_comparison_value_1    || '<BR>' ||
                                              '41 AK = ' || t2_rate_connector        || '<BR>' ||
                                              '42 AL = ' || t2_rate_comparison_operator_2 || '<BR>' ||
                                              '43 AM = ' || t2_rate_comparison_value_2 || '<BR>' ||
                                              '44 AN = ' || t2_description           || '<BR>' ||
                                              '45 AO = ' || t3_expression            || '<BR>' ||
                                              '46 AP = ' || t3_comparison_unit       || '<BR>' ||
                                              '47 AQ = ' || t3_comparison_operator_1 || '<BR>' ||
                                              '48 AR = ' || t3_comparison_value_1    || '<BR>' ||
                                              '49 AS = ' || t3_connector             || '<BR>' ||
                                              '50 AT = ' || t3_comparison_operator_2 || '<BR>' ||
                                              '51 AU = ' || t3_comparison_value_2    || '<BR>' ||
                                              '52 AV = ' || t3_rate_expression       || '<BR>' ||
                                              '53 AW = ' || t3_rate_comparison_unit  || '<BR>' ||
                                              '54 AX = ' || t3_rate_interval         || '<BR>' ||
                                              '55 AY = ' || t3_rate_comparison_operator_1 || '<BR>' ||
                                              '56 AZ = ' || t3_rate_comparison_value_1    || '<BR>' ||
                                              '57 BA = ' || t3_rate_connector        || '<BR>' ||
                                              '58 BB = ' || t3_rate_comparison_operator_2 || '<BR>' ||
                                              '59 BC = ' || t3_rate_comparison_value_2 || '<BR>' ||
                                              '60 BD = ' || t3_description           || '<BR>' ||

                                              '61 BE = ' || t4_expression            || '<BR>' ||
                                              '62 BF = ' || t4_comparison_unit       || '<BR>' ||
                                              '63 BG = ' || t4_comparison_operator_1 || '<BR>' ||
                                              '64 BH = ' || t4_comparison_value_1    || '<BR>' ||
                                              '65 BI = ' || t4_connector             || '<BR>' ||
                                              '66 BJ = ' || t4_comparison_operator_2 || '<BR>' ||
                                              '67 BK = ' || t4_comparison_value_2    || '<BR>' ||
                                              '68 BL = ' || t4_rate_expression       || '<BR>' ||
                                              '69 BM = ' || t4_rate_comparison_unit  || '<BR>' ||
                                              '70 BN = ' || t4_rate_interval         || '<BR>' ||
                                              '71 BO = ' || t4_rate_comparison_operator_1 || '<BR>' ||
                                              '72 BP = ' || t4_rate_comparison_value_1    || '<BR>' ||
                                              '73 BQ = ' || t4_rate_connector        || '<BR>' ||
                                              '74 BR = ' || t4_rate_comparison_operator_2 || '<BR>' ||
                                              '75 BS = ' || t4_rate_comparison_value_2 || '<BR>' ||
                                              '76 BT = ' || t4_description           || '<BR>' ||
                                              '77 BU = ' || t5_expression            || '<BR>' ||
                                              '78 BV = ' || t5_comparison_unit       || '<BR>' ||
                                              '79 BW = ' || t5_comparison_operator_1 || '<BR>' ||
                                              '80 BX = ' || t5_comparison_value_1    || '<BR>' ||
                                              '81 BY = ' || t5_connector             || '<BR>' ||
                                              '82 BZ = ' || t5_comparison_operator_2 || '<BR>' ||
                                              '83 CA = ' || t5_comparison_value_2    || '<BR>' ||
                                              '84 CB = ' || t5_rate_expression       || '<BR>' ||
                                              '85 CC = ' || t5_rate_comparison_unit  || '<BR>' ||
                                              '86 CD = ' || t5_rate_interval         || '<BR>' ||
                                              '87 CE = ' || t5_rate_comparison_operator_1 || '<BR>' ||
                                              '88 CF = ' || t5_rate_comparison_value_1    || '<BR>' ||
                                              '89 CG = ' || t5_rate_connector        || '<BR>' ||
                                              '90 CH = ' || t5_rate_comparison_operator_2 || '<BR>' ||
                                              '91 CI = ' || t5_rate_comparison_value_2 || '<BR>' ||
                                              '92 CJ = ' || t5_description           || '<BR>' ||
                                              '93 CK = ' || t_location_code          || '<BR>' ||
                                              'Interval 1, Minimum Duration = ' || t_minimum_duration || '<BR>' ||
                                              'Interval 2, Maximum Age = '      || t_maximum_age  
                                              ;

                                INSERT INTO uploaded_xls_file_rows_t (
                                                      id, file_id,date_uploaded,user_id_uploaded,date_last_updated,user_id_last_updated
                                                     ,error_code_original, pl_Sql_call, single_row_yn, seasonal_component)
                                                   VALUES
                                                      (UPLOADED_XLS_FILE_ROWS_SEQ.nextval
                                                      , p_file_id
                                                      , SYSDATE
                                                      , p_user_id
                                                      , SYSDATE
                                                      , p_user_id
                                                      --, 'Logging Setting Page API Variables from XLS! --' || temp_err_msg
                                                      , 'Error in setting Page API Variables from XLS! --' || temp_err_msg
                                                      , 'LINE #' || temp_num_rows || '<BR>'
                                                       || ' = "' || v_line || '"<BR>'
                                                       || 'p_office_id = ' || t_location_code || '<BR>'
                                                       || 'p_location_level_id = ' || l_location_level_id || '<BR>'
                                                       || 'Internal Variables and Excel Cell Columns<BR>' || temp_err_html 
                                                      , c_app_logic_yes
                                                      , NULL 
                                                      );

                             END;

                    END IF; -- temp_num_rows = 0
              --Reset line if at the end
              v_line := NULL;
              --Increment counter
              temp_num_rows := temp_num_rows + 1;

            END IF;      
        
       
        END LOOP;


UPDATE uploaded_xls_files_t
   SET row_count_all = temp_num_rows
 WHERE id = p_file_id;

END load_lli;
 PROCEDURE Load_LLI_2 ( p_attr_id                   IN VARCHAR2
                      , p_attr_value                IN NUMBER
                      , p_attr_unit                 IN VARCHAR2
                      , p_conditions                IN loc_lvl_indicator_cond_tab_t := loc_lvl_indicator_cond_tab_t()
                      , p_file_id                   IN uploaded_xls_files_t.id%TYPE
                      , p_indicator                 IN loc_lvl_indicator_t
                      , p_location_level_id         IN VARCHAR2
                      , p_maximum_age               IN at_loc_lvl_indicator.maximum_age%TYPE
                      , p_minimum_duration          IN at_loc_lvl_indicator.minimum_duration%TYPE
                      , p_office_id                 IN VARCHAR2
                      , p_ref_specified_level_id    IN VARCHAR2
                      , p_ref_attr_value            IN NUMBER
                      , p_debug_yn                  IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
                     ) IS
 
   temp_Err_msg            VARCHAR2(1999);
   t_level_indicator_id     VARCHAR2(1999);  
BEGIN

    IF p_debug_yn = c_app_logic_yes THEN
      Set_Log_Row (p_error_text   => ' Logging for location level id and p_location_level = "' || p_location_level_id || '"' 
                                    ,p_file_id      => p_file_id
                                    ,p_pl_sql_text  =>  'passing in variables'
                    );
      Set_Log_Row (p_error_text   => ' Logging for reference level "' || p_ref_specified_level_id 
                                      || '" and reference level id  = "' || p_ref_attr_value  || '"'
--                                      || ' and unit codes = "' || p_unit_code || '"'   
                                    ,p_file_id      => p_file_id
                                    ,p_pl_sql_text  =>  'passing in variables'
                    );
    END IF;

    temp_Err_msg := NULL;

    BEGIN
    

      load_lli_hardcoded_2(p_conditions
                           ,p_location_level_id
                           ,p_maximum_age
                           ,p_minimum_duration          
                           ,p_office_id
                           ,p_ref_specified_level_id 
                           ,p_ref_attr_value
                           );

     IF p_debug_yn = c_app_logic_yes THEN
      Set_Log_Row (p_error_text   => ' Logging for location level id and p_location_level = "' || p_location_level_id || '"' 
                                    ,p_file_id      => p_file_id
                                    ,p_pl_sql_text  =>  'Variable comparison after calling load_lli_hardcoded_2 '
                    );
     END IF;
     --NOTES: Comment out below to make it fail on a no_data_found
       -- l_indicator.store;
        
    EXCEPTION
        WHEN OTHERS THEN

      temp_Err_msg := sqlerrm;
       
     
     Set_Log_Row (p_error_text   => ' Error in calling load LLI Hardcoded 2  = ' || temp_Err_msg 
                 ,p_file_id      => p_file_id
                 ,p_pl_sql_text  =>  'p_conditions => p_conditions '  
                           || '<BR>' || 'p_location_level_id  => ' || p_location_level_id
                           || '<BR>' || 'p_ref_specified_level_id => ' || p_ref_specified_level_id
                           || '<BR>' || 'p_ref_Attr_value  => '     || p_ref_attr_value
                           || '<BR>' || 'p_office_id => '               || p_office_id 

                  ); 
    END;

END Load_lli_2;

PROCEDURE Load_lli_hardcoded IS 

   l_conditions           loc_lvl_indicator_cond_tab_t := loc_lvl_indicator_cond_tab_t();
   l_indicator            loc_lvl_indicator_t;
   l_office_id            varchar2(16) := 'CPC';
   l_unit_code            number(10);
   l_location_id          varchar2(49);
   l_parameter_id         varchar2(49);
   l_parameter_type_id    varchar2(16);
   l_duration_id          varchar2(16);
   l_specified_level_id   varchar2(256);
   l_location_level_id    varchar2(390) := 'BROKJDK.Stor.Inst.0.Top of Flood.PERCENT FULL';

begin

   select unit_code
     into l_unit_code
     from cwms_unit
    where unit_id = 'm3';

   l_conditions.extend(5);   

   l_conditions(1) := loc_lvl_indicator_cond_t(
      p_indicator_value            => 1,
      p_expression                 => '(V - L2) / (L - L2)',
      p_comparison_operator_1      => 'LT',
      p_comparison_value_1         => 0.1,
      p_comparison_unit            => l_unit_code,
      p_connector                  => null,
      p_comparison_operator_2      => null,
      p_comparison_value_2         => null,
      p_rate_expression            => null,
      p_rate_comparison_operator_1 => null,
      p_rate_comparison_value_1    => null,
      p_rate_comparison_unit       => null,
      p_rate_connector             => null,
      p_rate_comparison_operator_2 => null,
      p_rate_comparison_value_2    => null,
      p_rate_interval              => null,
      p_description                => 'Under 10%');

   l_conditions(2) := loc_lvl_indicator_cond_t(
      p_indicator_value            => 2,
      p_expression                 => '(V - L2) / (L - L2)',
      p_comparison_operator_1      => 'GE',
      p_comparison_value_1         => 0.1,
      p_comparison_unit            => l_unit_code,
      p_connector                  => 'AND',
      p_comparison_operator_2      => 'LT',
      p_comparison_value_2         => 0.25,
      p_rate_expression            => null,
      p_rate_comparison_operator_1 => null,
      p_rate_comparison_value_1    => null,
      p_rate_comparison_unit       => null,
      p_rate_connector             => null,
      p_rate_comparison_operator_2 => null,
      p_rate_comparison_value_2    => null,
      p_rate_interval              => null,
      p_description                => '10% to under 25%');

 

   l_conditions(3) := loc_lvl_indicator_cond_t(
      p_indicator_value            => 3,
      p_expression                 => '(V - L2) / (L - L2)',
      p_comparison_operator_1      => 'GE',
      p_comparison_value_1         => 0.25,
      p_comparison_unit            => l_unit_code,
      p_connector                  => 'AND',
      p_comparison_operator_2      => 'LT',
      p_comparison_value_2         => 0.75,
      p_rate_expression            => null,
      p_rate_comparison_operator_1 => null,
      p_rate_comparison_value_1    => null,
      p_rate_comparison_unit       => null,
      p_rate_connector             => null,
      p_rate_comparison_operator_2 => null,
      p_rate_comparison_value_2    => null,
      p_rate_interval              => null,
      p_description                => '25% to under 75%');

 

   l_conditions(4) := loc_lvl_indicator_cond_t(
      p_indicator_value            => 4,
      p_expression                 => '(V - L2) / (L - L2)',
      p_comparison_operator_1      => 'GE',
      p_comparison_value_1         => 0.75,
      p_comparison_unit            => l_unit_code,
      p_connector                  => 'AND',
      p_comparison_operator_2      => 'LT',
      p_comparison_value_2         => 1,
      p_rate_expression            => null,
      p_rate_comparison_operator_1 => null,
      p_rate_comparison_value_1    => null,
      p_rate_comparison_unit       => null,
      p_rate_connector             => null,
      p_rate_comparison_operator_2 => null,
      p_rate_comparison_value_2    => null,
      p_rate_interval              => null,
      p_description                => '75% to under 100%');

   l_conditions(5) := loc_lvl_indicator_cond_t(
      p_indicator_value            => 5,
      p_expression                 => '(V - L2) / (L - L2)',
      p_comparison_operator_1      => 'GE',
      p_comparison_value_1         => 1,
      p_comparison_unit            => l_unit_code,
      p_connector                  => null,
      p_comparison_operator_2      => null,
      p_comparison_value_2         => null,
      p_rate_expression            => null,
      p_rate_comparison_operator_1 => null,
      p_rate_comparison_value_1    => null,
      p_rate_comparison_unit       => null,
      p_rate_connector             => null,
      p_rate_comparison_operator_2 => null,
      p_rate_comparison_value_2    => null,
      p_rate_interval              => null,
      p_description                => '100% and over');

   cwms_level.parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      l_location_level_id);
    
   l_indicator := loc_lvl_indicator_t(
      office_id              => l_office_id,
      location_id            => l_location_id,
      parameter_id           => l_parameter_id,
      parameter_type_id      => l_parameter_type_id,
      duration_id            => l_duration_id,
      specified_level_id     => l_specified_level_id,
      level_indicator_id     => 'PERCENT FULL',
      attr_value             => null,
      attr_units_id          => null,
      attr_parameter_id      => null,
      attr_parameter_type_id => null,
      attr_duration_id       => null,
      ref_specified_level_id => null,
      ref_attr_value         => null,
      minimum_duration       => to_dsinterval('00 04:00:00'),
      maximum_age            => to_dsinterval('00 12:00:00'),
      conditions             => l_conditions);

      l_indicator.store;

END load_lli_hardcoded;

PROCEDURE Load_lli_hardcoded_2 (p_conditions                IN loc_lvl_indicator_cond_tab_t := loc_lvl_indicator_cond_tab_t()
                               ,p_location_level_id         IN VARCHAR2
                               ,p_maximum_age               IN at_loc_lvl_indicator.maximum_age%TYPE
                               ,p_minimum_duration          IN at_loc_lvl_indicator.minimum_duration%TYPE
                               ,p_office_id                 IN VARCHAR2
                               ,p_ref_specified_level_id    IN VARCHAR2
                               ,p_ref_attr_value            IN NUMBER 

                               )  IS 

   l_indicator            loc_lvl_indicator_t;
   l_location_id          varchar2(49);
   l_parameter_id         varchar2(49);
   l_parameter_type_id    varchar2(16);
   l_duration_id          varchar2(16);
   l_specified_level_id   varchar2(256);
   t_level_indicator_id   VARCHAR2(1999);
   l_code                 number;

begin
   
   if p_conditions is not null and p_conditions.count > 5 then
      cwms_text.store_text(l_code, dbms_utility.format_call_stack, '/error_text', 'error_text', 'F', cwms_util.user_office_id);
      cwms_err.raise(
         'ERROR',
         'Expected only 5 conditions, found '|| p_conditions.count);
   end if;
   
   
t_level_indicator_id := get_location_level_id_param(p_location_level_id
                                                   ,6
                                                   );
   cwms_level.parse_location_level_id(
                                      l_location_id,
                                      l_parameter_id,
                                      l_parameter_type_id,
                                      l_duration_id,
                                      l_specified_level_id,
                                      p_location_level_id
                                     );

   l_indicator := loc_lvl_indicator_t(
                                  office_id              => SUBSTR(p_office_id,1,3),
                                  location_id            => l_location_id,
                                  parameter_id           => l_parameter_id,
                                  parameter_type_id      => l_parameter_type_id,
                                  duration_id            => l_duration_id,
                                  specified_level_id     => l_specified_level_id,
                                  level_indicator_id     => t_level_indicator_id, 
                                  attr_value             => null,
                                  attr_units_id          => null,
                                  attr_parameter_id      => null,
                                  attr_parameter_type_id => null,
                                  attr_duration_id       => null,
                                  ref_specified_level_id => p_ref_specified_level_id ,
                                  ref_attr_value         => p_ref_attr_value  ,
                                  minimum_duration       => p_minimum_duration ,
                                  maximum_age            => p_maximum_age,
                                  conditions             => p_conditions
                                    );
   
      l_indicator.store;

END load_lli_hardcoded_2;


PROCEDURE Set_Log_Row (p_error_text   IN uploaded_xls_file_rows_t.error_code_original%TYPE
                      ,p_file_id      IN uploaded_xls_file_rows_t.file_id%TYPE
                      ,p_pl_sql_text  IN uploaded_xls_file_rows_t.pl_sql_call%TYPE
                       ) IS
BEGIN

       INSERT INTO uploaded_xls_file_rows_t (
                          id
                         ,file_id
                         ,date_uploaded
                         ,user_id_uploaded
                         ,date_last_updated
                         ,user_id_last_updated
                         ,error_code_original
                         ,pl_Sql_call
                         ,single_row_yn
                         ,seasonal_component
                                            )
                       VALUES
                          (UPLOADED_XLS_FILE_ROWS_SEQ.nextval
                          , p_file_id
                          , SYSDATE
                          , 'API'
                          , SYSDATE
                          , 'API'
                          , p_error_text
                          , p_pl_sql_text
                          , c_app_logic_yes
                          , NULL 
                          );
END set_log_row;

END CWMS_APEX_TEMP;
/
