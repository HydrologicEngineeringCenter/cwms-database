CREATE OR REPLACE PACKAGE CWMS_APEX_TEMP AS
/******************************************************************************
   NAME:       CWMS_APEX_TEMP
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        7/8/2010             1. Created this package.
******************************************************************************/
 c_app_logic_yes      VARCHAR2(1) DEFAULT 'T';
 c_app_logic_no      VARCHAR2(1) DEFAULT 'F';
  
  FUNCTION calc_seasonal_mn_offset(f_005 IN VARCHAR2) RETURN NUMBER;
  FUNCTION Get_unit_code_from_code_id(f_unit_id IN cwms_unit.unit_id%TYPE
                                     ,p_file_id IN NUMBER )
                             RETURN cwms_unit.unit_code%TYPE
                             --RETURN VARCHAR2
                             ;
  FUNCTION get_headers_for_APEX_rpt(f_import_type IN NUMBER) RETURN VARCHAR2;
  FUNCTION get_header_by_column_num(f_column_number IN apex_collections.c001%TYPE
                                   ,f_import_type   IN NUMBER
                                   ) RETURN VARCHAR2;
  FUNCTION get_location_level_id_param(f_location_level_id IN VARCHAR2
                                      ,f_loc_num IN NUMBER
                                      ) RETURN VARCHAR2;

  FUNCTION strip_for_stragg( f_string IN VARCHAR2 ) RETURN VARCHAR2;
FUNCTION         F_valid_header (f_file_type IN NUMBER
                                          ,f_header_loc IN NUMBER 
                                          ) RETURN NUMBER;  


  function str2tbl( p_str in varchar2, p_delim in varchar2 default ',' ) return str2tblType
PIPELINED
;
PROCEDURE Download_File(p_file_id in uploaded_xls_files_t.id%TYPE);
  PROCEDURE Load_LL(p_collection_name IN VARCHAR2
                   ,p_fail_if_exists IN c_app_logic_no%TYPE DEFAULT c_app_logic_no
                   );
  PROCEDURE Load_LLI(p_file_name        IN apex_application_files.filename%TYPE 
                    ,p_user_id          IN uploaded_xls_files_t.user_id_uploaded%TYPE
                    ,p_old_file_id      IN uploaded_xls_files_t.id%TYPE DEFAULT NULL
                    ,p_reload_xls_file  IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
                    ,p_debug_yn         IN c_app_logic_yes%TYPE DEFAULT c_app_logic_no
                    );

  PROCEDURE Load_LLI_2( p_attr_id                   IN VARCHAR2
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
                     );
  PROCEDURE Load_LLI_Hardcoded;
  PROCEDURE Load_LLI_Hardcoded_2(p_conditions               IN loc_lvl_indicator_cond_tab_t := loc_lvl_indicator_cond_tab_t()
                               ,p_location_level_id         IN VARCHAR2
                               ,p_maximum_age               IN at_loc_lvl_indicator.maximum_age%TYPE
                               ,p_minimum_duration          IN at_loc_lvl_indicator.minimum_duration%TYPE
                               ,p_office_id                 IN VARCHAR2
                               ,p_ref_specified_level_id    IN VARCHAR2
                               ,p_ref_attr_value            IN NUMBER 
                                
                                );

  PROCEDURE Set_Log_Row (p_error_text   IN uploaded_xls_file_rows_t.error_code_original%TYPE
                        ,p_file_id      IN uploaded_xls_file_rows_t.file_id%TYPE
                        ,p_pl_sql_text  IN uploaded_xls_file_rows_t.pl_sql_call%TYPE
                        );
  
  
  
END CWMS_APEX_TEMP;
/
