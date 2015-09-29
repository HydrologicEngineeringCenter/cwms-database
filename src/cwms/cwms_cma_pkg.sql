CREATE OR REPLACE PACKAGE CWMS_CMA
AS
  /******************************************************************************
  NAME:       CWMS_CMA_ERDC
  PURPOSE:
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        6/19/2013      u4rt9jdk       1. Created this package.
  ******************************************************************************/
  c_cwms_logic_t   CONSTANT VARCHAR2(1) DEFAULT 'T';
  c_cwms_logic_f   CONSTANT VARCHAR2(1) DEFAULT 'F';
  c_app_logic_y    CONSTANT VARCHAR2(1) DEFAULT 'T';
  c_app_logic_n    CONSTANT VARCHAR2(1) DEFAULT 'F';
  c_temp_null_case CONSTANT VARCHAR2(9) DEFAULT 'Hi Art';
  c_str_inflow     CONSTANT VARCHAR2(6) DEFAULT 'Inflow';
  c_str_outflow    CONSTANT VARCHAR2(7) DEFAULT 'Outflow';
  c_str_elev       CONSTANT VARCHAR2(4) DEFAULT 'Elev';
  c_str_precip     CONSTANT VARCHAR2(6) DEFAULT 'Precip';
  c_str_stage      CONSTANT VARCHAR2(5) DEFAULT 'Stage';
  c_str_stor       CONSTANT VARCHAR2(4) DEFAULT 'Stor';
  c_chart_min_days CONSTANT NUMBER DEFAULT 5;
  FUNCTION MyFunction(
      Param1 IN NUMBER)
    RETURN NUMBER;
  FUNCTION apex_log_error(
      p_error IN apex_error.t_error )
    RETURN at_cma_error_log.id%TYPE;
  FUNCTION f_validate_string(
      f_string_1 IN VARCHAR2 ,
      f_string_2 IN VARCHAR2 )
    RETURN VARCHAR2;
  FUNCTION f_get_loc_attribs_by_xy(
      p_latitude  IN cwms_v_loc.latitude%TYPE ,
      p_longitude IN cwms_v_loc.longitude%TYPE )
    RETURN VARCHAR2;
  FUNCTION f_get_tz_by_xy(
      p_latitude  IN cwms_v_loc.latitude%TYPE ,
      p_longitude IN cwms_v_loc.longitude%TYPE )
    RETURN cwms_v_loc.time_zone_name%TYPE;

   FUNCTION f_get_loc_num_ll(f_location_code IN cwms_v_loc.location_code%TYPE
                            ,f_location_level_kind IN VARCHAR2 DEFAULT 'ALL'
                            ) RETURN NUMBER;

   FUNCTION f_get_loc_home_tools_by_loc (f_location_code IN cwms_v_loc.location_code%TYPE
                                        ,f_app_id        IN NUMBER
                                        ,f_session_id    IN NUMBER
                                        ) RETURN VARCHAR2;
                                          
   FUNCTION f_get_ll_home_container (f_location_code IN CWMS_V_LOC.location_code%TYPE) RETURN VARCHAR2;

   FUNCTION f_validate_loc_for_ur (f_location_id IN cwms_v_loc.locatioN_id%TYPE )    RETURN VARCHAR2;
    
      FUNCTION f_validate_loc_by_loc_types (f_location_code   IN cwms_v_loc.location_code%TYPE
                                    
                                       ) RETURN VARCHAR2; 
  
  FUNCTION f_get_nw_loc_link(
      f_locatioN_id        IN cwms_v_loc.locatioN_id%TYPE ,
      f_map_or_rpt_or_both IN VARCHAR2 DEFAULT 'Both' ,
      f_html_link_or_text  IN VARCHAR2 DEFAULT 'HTML' )
    RETURN VARCHAR2;

   FUNCTION get_ts_max_date_utc_2 (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned,
      p_year               IN NUMBER DEFAULT NULL)
      RETURN DATE;   

  FUNCTION orcl_2_unix(
      f_oracle_date IN DATE )
    RETURN NUMBER;
  PROCEDURE copy_ts_code_to_ts_code(
      p_ts_code_from    IN cwms_v_ts_id.ts_code%TYPE ,
      p_ts_code_to      IN cwms_v_ts_id.Ts_code%TYPE ,
      p_store_rule_code IN cwms_store_rule.store_rule_code%TYPE ,
      p_out             OUT VARCHAR2 ,
      p_date_start      IN DATE DEFAULT NULL ,
      p_date_end        IN DATE DEFAULT NULL );
  PROCEDURE copy_tsc_to_tsc_interp(p_ts_code_from      IN cwms_v_ts_id.ts_code%TYPE
                                    ,p_ts_code_to       IN cwms_v_ts_id.Ts_code%TYPE
                                    ,p_store_rule_code  IN cwms_store_rule.store_Rule_code%TYPE
                                    ,p_interpolate_tf   IN VARCHAR2 DEFAULT 'T'
                                    ,p_out              OUT VARCHAR2 
                                    ,p_date_start       IN DATE 
                                    ,p_date_end         IN DATE 
                                    );
  PROCEDURE Deconstruct_ts_id(
      p_ts_code_from    IN cwms_v_ts_id.ts_code%TYPE ,
      p_interval_to     IN cwms_v_ts_id.interval%TYPE ,
      p_store_rule_code IN cwms_store_rule.store_rule_code%TYPE ,
      p_interpolate_tf  IN VARCHAR2 DEFAULT 'T' ,
      p_out             OUT VARCHAR2
      --,p_date_start       IN DATE
      --,p_date_end         IN DATE
    );
/*  PROCEDURE download_file(
      p_file IN cwms_documents_t.id%TYPE);
      */
  PROCEDURE Clean_Loc_Metadata_by_xy(
      p_db_office_id           IN cwms_v_ts_id.db_office_id%TYPE ,
      p_location_code          IN cwms_v_loc.location_code%TYPE DEFAULT NULL ,
      p_overwrite_county_yn    IN VARCHAR2 DEFAULT c_app_logic_n ,
      p_overwrite_nation_id_yn IN VARCHAR2 DEFAULT c_app_logic_n ,
      p_overwrite_near_city_yn IN VARCHAR2 DEFAULT c_app_logic_n ,
      p_overwrite_state_yn     IN VARCHAR2 DEFAULT c_app_logic_n ,
      p_overwrite_tz_name_yn   IN VARCHAR2 DEFAULT c_app_logic_n );
  PROCEDURE load_application_constants(
      p_app_logic_yes OUT VARCHAR2 ,
      p_app_logic_no OUT VARCHAR2 ,
      p_app_Page_title_prefix OUT VARCHAR2 ,
      p_app_save_text OUT VARCHAR2 ,
      p_app_cancel_text OUT VARCHAR2 ,
      p_app_page_15_Instructions OUT VARCHAR2 ,
      p_app_logic_html5_date_mask OUT VARCHAR2 ,
      p_app_db_office_id_cwms OUT VARCHAR2 ,
      p_app_usr_dflt_scope_choice OUT VARCHAR2 ,
      p_app_search_goto_loc_icon OUT VARCHAR2 ,
      p_app_ts_store_rule_id_dflt OUT VARCHAR2 --cwms_ts_store_rule_l.id%TYPE
      ,
      p_app_null_lookup_temp_text OUT VARCHAR2 ,
      p_app_NW_UR_base_loc_ts_id_tf OUT VARCHAR2 );
  PROCEDURE load_store_rule(
      p_id            IN cwms_store_rule.store_rule_code%TYPE ,
      p_default_tf    IN cwms_store_rule.use_as_default%TYPE, --cwms_ts_store_rule_l.default_tf%TYPE ,
      p_description   IN cwms_store_rule.description%TYPE ,
      p_display_value IN cwms_store_rule.store_rule_id%TYPE ,
      p_sort_order    IN AT_STORE_RULE_ORDER.sort_order%TYPE );
  PROCEDURE Load_csv_collection_to_DB(
      p_collection_name IN apex_collections.collection_name%TYPE ,
      p_store_rule_code IN cwms_store_rule.store_rule_code%TYPE );
  PROCEDURE parse_tsv_csv(
      p_clob CLOB,
      p_collection_name     VARCHAR2,
      p_delim               VARCHAR2 DEFAULT ',',
      p_optionally_enclosed VARCHAR2 DEFAULT '"' );
  PROCEDURE preload_store_rule_editor(
      p_store_Rule_code IN cwms_store_rule.store_rule_code%TYPE ,
      p_use_as_default  OUT cwms_store_rule.use_as_default%TYPE, --cwms_ts_store_rule_l.default_tf%TYPE ,
      p_description     OUT cwms_store_rule.description%TYPE ,
      p_store_rule_id   OUT cwms_store_rule.store_rule_id%TYPE,
      p_sort_order    OUT AT_STORE_RULE_ORDER.sort_order%TYPE );

   PROCEDURE preload_ll_to_tsv(p_location_code  IN cwms_v_loc.location_code%TYPE
                              ,p_ll_code        IN cwms_v_location_level.location_level_code%TYPE
                              ,p_cwms_ts_id     OUT cwms_v_ts_id.cwms_ts_id%TYPE
                              );

   PROCEDURE load_ll_to_tsv(p_collection_name       IN  VARCHAR2
                          , p_location_level_code   IN cwms_V_location_level.location_level_code%TYPE
                          , p_unit_system           IN cwms_V_location_level.unit_system%TYPE
                          , p_add_point_method      IN VARCHAR2 DEFAULT 'LI'
                          , p_preview_tf            IN VARCHAR2 DEFAULT 'T'
                          , p_cwms_ts_id_new        IN cwms_v_ts_id.cwms_ts_id%TYPE
                          , p_store_rule_code       IN cwms_store_rule.store_rule_code%TYPE
                           );



  PROCEDURE load_tsc_parallel(
      p_ts_code_left        IN cwms_v_ts_id.ts_code%TYPE ,
      p_ts_code_right       IN cwms_v_ts_id.ts_code%TYPE ,
      p_new_collection_name IN VARCHAR2 DEFAULT 'TS_PARALLEL_COMPARE' );
  PROCEDURE preload_Upload_tsv(
                    p_store_rule_code  IN OUT cwms_store_rule.store_Rule_code%TYPE);
  
   PROCEDURE p_delete_location_level(p_location_level_code IN cwms_v_Location_level.locatioN_level_code%TYPE
                                    );

   PROCEDURE p_clear_a2w_ts_code (p_ts_code IN cwms_v_ts_id.ts_code%TYPE);
   
  PROCEDURE p_refresh_a2w_ts_codes(
      p_db_office_id IN at_a2w_ts_codes_by_loc.db_office_id%TYPE ,
      p_location_id  IN at_a2w_ts_codes_by_loc.location_id%TYPE DEFAULT NULL );
  PROCEDURE p_sync_cwms_office_from_CM2(
      p_sync_office_buildings_yn  IN VARCHAR2 DEFAULT c_app_logic_y ,
      p_sync_office_boundaries_yn IN VARCHAR2 DEFAULT c_app_logic_y ,
      p_status OUT VARCHAR2 );
  PROCEDURE p_sync_cwms_geo_tbls_w_CM2(
      p_compare_or_sync IN VARCHAR2 DEFAULT 'COMPARE' ,
      p_status OUT VARCHAR2 );
  PROCEDURE p_sync_cwms_nid_w_CM2(
      p_compare_or_sync IN VARCHAR2 DEFAULT 'COMPARE' ,
      p_status OUT VARCHAR2 );
  PROCEDURE p_sync_cwms_loc_by_NIDID(
      p_db_Office_id IN cwms_v_loc.db_Office_id%TYPE ,
      p_location_id  IN cwms_v_loc.locatioN_id%TYPE DEFAULT NULL ,
      p_action       IN VARCHAR2 DEFAULT 'PL/SQL' ,
      p_sync_tf      IN VARCHAR2 DEFAULT c_cwms_logic_f ,
      p_out OUT CLOB );
  PROCEDURE p_load_tsv(
      p_collection_name IN apex_collections.collection_name%TYPE ,
      p_display_out OUT VARCHAR2 ) ;
  PROCEDURE p_clean_location_type(
      p_db_office_id      IN cwms_v_loc.db_Office_id%TYPE ,
      p_location_type_old IN cwms_v_loc.location_type%TYPE ,
      p_location_type_new IN cwms_v_loc.location_type%TYPE );
  PROCEDURE p_load_Project_Purpose(
      p_db_Office_id     IN cwms_v_loc.db_office_id%TYPE ,
      p_locatioN_id      IN cwms_v_loc.locatioN_id%TYPE ,
      p_project_purposes IN VARCHAR2 ,
      p_delim            IN VARCHAR2 DEFAULT ','
     ,p_purpose_type     IN VARCHAR2 DEFAULT 'AUTHORIZED' );
  PROCEDURE p_preload_ll(
      p_db_office_id      IN cwms_v_locatioN_level.office_id%TYPE ,
      p_location_level_id IN cwms_v_location_level.location_level_id%TYPE ,
      p_level_date        IN VARCHAR2 ,
      p_unit_system       IN cwms_v_loc.unit_system%TYPE DEFAULT 'EN' ,
      p_delim             IN VARCHAR2 DEFAULT ':' ,
      p_base_parameter_id OUT cwms_v_locatioN_level.base_parameter_id%TYPE ,
      p_sub_parameter_id OUT cwms_v_location_level.sub_Parameter_id%TYPE
      --                        ,p_parameter_id             OUT cwms_v_location_level.parameter_id%TYPE
      ,
      p_parameter_type_id OUT VARCHAR2 ,
      p_duration_id OUT cwms_v_locatioN_level.duratioN_id%TYPE ,
      p_specified_level_id OUT cwms_v_location_level.specified_level_id%TYPE ,
      p_level_unit_id OUT cwms_v_location_level.level_unit%TYPE ,
      p_Num_points OUT NUMBER ,
      p_single_value OUT NUMBER ,
      p_multiple_values OUT VARCHAR2 );
  PROCEDURE p_preload_Project_Purpose(
      p_db_Office_id IN cwms_v_loc.db_office_id%TYPE ,
      p_locatioN_id  IN cwms_v_loc.locatioN_id%TYPE ,
      p_delim        IN VARCHAR2 DEFAULT ',' ,
      p_purpose_type     IN VARCHAR2 DEFAULT 'AUTHORIZED', 
      p_project_purposes OUT VARCHAR2
       );
  PROCEDURE p_preload_squery_by_xy(
      p_lat IN cwms_v_loc.latitude%TYPE ,
      p_lon IN cwms_v_loc.longitude%TYPE ,
      p_county OUT cwms_v_loc.county_name%TYPE ,
      p_nation_id OUT cwms_v_loc.nation_id%TYPE ,
      p_nearest_city OUT cwms_v_loc.nearest_city%TYPE ,
      p_state_initial OUT cwms_v_loc.state_initial%TYPE ,
      p_time_zone_name OUT cwms_v_loc.time_zone_name%TYPE );
  PROCEDURE p_preload_loc_by_station_5(
      p_db_office_id   IN cwms_v_loc.db_Office_id%TYPE ,
      p_locatioN_id    IN cwms_v_loc.locatioN_id%TYPE DEFAULT NULL ,
      p_debug_or_plsql IN VARCHAR2 DEFAULT 'DEBUG' ,
      p_fire_sql       IN VARCHAR2 DEFAULT 'F' ,
      p_out OUT CLOB );
  PROCEDURE  p_preload_location (
      p_db_office_id          IN     cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id           IN     cwms_v_loc.location_id%TYPE,
      p_locatioN_type_api     IN OUT cwms_v_location_Type.location_type%TYPE,
      p_api_read_only            OUT VARCHAR2,
      p_lock_project_id          OUT VARCHAR2,
      p_num_locs_project_of      OUT NUMBER,
      p_outlet_project_id        OUT cwms_v_project.project_id%TYPE,
      p_turbine_project_id       OUT cwms_v_project.project_id%TYPE);
  
  PROCEDURE p_load_loc_by_station_5(
      p_db_office_id IN cwms_v_loc.db_Office_id%TYPE ,
      p_locatioN_id  IN cwms_v_loc.locatioN_id%TYPE DEFAULT NULL );
  /*
  PROCEDURE Load_Location(
  p_active               IN   .ACTIVE_FLAG%TYPE
  ,p_bounding_office_id   IN cwms_v_loc.bounding_office_id%TYPE --:P36_PHYSICAL_OFFICE,
  ,p_county_name          IN  cwms_v_loc.county_name%TYPE  --REPLACE(:P36_COUNTY_NAME, '-UNK-'),
  ,p_description          IN cwms_v_loc.description        --  P36_DESCRIPTION,
  ,p_db_office_id        IN cwms_v_loc.db_office_id%TYPE   -- :F99_DB_OFFICE_ID
  , p_elevation         IN cwms_v_loc.elevation%TYPE        -- :P36_ELEVATION,
  , p_elev_unit_id      IN VARCHAR2                         -- :P36_DISPLAY_ELEVATION_UNITS,
  , p_horizontal_datum  IN cwms_v_loc.horizontal_datum%TYPE -- REPLACE(:P36_HORIZONTAL_DATUM, '-UNK-'),
  , p_latitude          IN cwms_v_loc.latitude%TYPE         --  dec_lat,
  , p_longitude         IN cwms_v_loc.longitude%TYPE        --dec_long,
  , p_location_id       IN cwms_v_loc.location_id%TYPE      -- :P36_LOCATION_ID_EDIT,
  , p_location_type     IN cwms_v_loc.lcoation_type%TYPE        -- REPLACE(:P36_LOCATION_TYPE, '-UNK-'),
  , p_long_name         IN cwms_v_loc.long_name%TYPE            --:P36_LONG_NAME,
  , p_location_kind_id     IN cwms_v_loc.location_kind_id%TYPE  -- :P36_LOCATION_KIND_ID,
  , p_map_label            IN cwms_v_loc.map_label%TYPE          -- :P36_MAP_LABEL,
  , p_nation_id          IN cwms_v_loc.nation_id%TYPE           --:P36_NATION_ID,
  ,  p_nearest_city         IN cwms_v_loc.nearest_city%TYPE      -- :P36_NEAREST_CITY,
  , p_public_name       IN cwms_v_loc.public_name%TYPE -- :P36_PUBLIC_NAME,
  , p_state_initial     IN cwms_v_loc.state_intial%TYPE --  REPLACE(:P36_STATE_INITIAL, '-UNK-', '00'),
  ,p_published_latitude   IN CWMS_V_LOC.PUBLISHED_LATITUDE%TYPE -- :P36_PUB_LATITUDE,
  ,p_published_longitude  IN cwms_v_loc.published_longitude%TYPE --:P36_PUB_LONGITUDE,
  ,p_ignorenulls         IN VARCHAR2
  ,p_time_zone_id     IN cwms_v_loc.time_zone_id%TYPE -- REPLACE(:P36_TIME_ZONE_NAME, '-UNK-'),
  ,p_vertical_datum    IN cwms_v_loc.vertical_datum -- REPLACE(:P36_VERTICAL_DATUM, '-UNK-'),
  );
  */
  
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
      p_lake_summary_tf        IN     at_a2w_ts_codes_by_loc.lake_summary_Tf%TYPE,
      p_error_msg                 OUT VARCHAR2);

  
  PROCEDURE p_chart_by_ts_code(
      p_ts_code   IN cwms_v_ts_id.TS_CODE%TYPE ,
      p_days      IN NUMBER DEFAULT c_chart_min_days ,
      p_date_start IN DATE DEFAULT SYSDATE - 45,
      p_date_end   IN DATE DEFAULT SYSDATE ,
      xmlcalldate IN NUMBER DEFAULT NULL );

  PROCEDURE p_set_a2w_num_tsids(p_db_Office_id  IN cwms_v_loc.db_Office_id%TYPE
                               ,p_locatioN_id   IN Cwms_v_loc.location_id%TYPE
                               ,p_user_id       IN VARCHAR2);


  PROCEDURE p_add_Missing_a2w_rows(p_db_Office_id  IN cwms_v_loc.db_Office_id%TYPE
                               ,p_locatioN_id   IN Cwms_v_loc.location_id%TYPE DEFAULT NULL
                               ,p_user_id       IN VARCHAR2); 

 PROCEDURE p_test;

END CWMS_CMA;
/
