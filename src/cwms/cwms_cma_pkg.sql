create or replace package                                 CWMS_CMA
AS
   /******************************************************************************
   NAME:       CWMS_CMA_ERDC
   PURPOSE:
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        6/19/2013      u4rt9jdk       1. Created this package.
   ******************************************************************************/
   c_cwms_logic_t     CONSTANT VARCHAR2 (1)  DEFAULT 'T';
   c_cwms_logic_f     CONSTANT VARCHAR2 (1)  DEFAULT 'F';
   c_app_logic_y      CONSTANT VARCHAR2 (1)  DEFAULT 'T';
   c_app_logic_n      CONSTANT VARCHAR2 (1)  DEFAULT 'F';
   c_temp_null_case   CONSTANT VARCHAR2 (9)  DEFAULT 'Hi Art';
   c_str_inflow       CONSTANT VARCHAR2 (6)  DEFAULT 'Inflow';
   c_str_outflow      CONSTANT VARCHAR2 (7)  DEFAULT 'Outflow';
   c_str_elev         CONSTANT VARCHAR2 (4)  DEFAULT 'Elev';
   c_str_precip       CONSTANT VARCHAR2 (6)  DEFAULT 'Precip';
   c_str_stage        CONSTANT VARCHAR2 (5)  DEFAULT 'Stage';
   c_str_stor         CONSTANT VARCHAR2 (4)  DEFAULT 'Stor';
   c_str_site         CONSTANT VARCHAR2 (4)  DEFAULT 'SITE';
   c_str_streamgage   CONSTANT VARCHAR2 (10) DEFAULT 'STREAMGAGE';
   c_str_embankment   CONSTANT VARCHAR2 (10) DEFAULT 'EMBANKMENT';
   c_str_basin        CONSTANT VARCHAR2 (5)  DEFAULT 'BASIN';
   c_str_stream       CONSTANT VARCHAR2 (6)  DEFAULT 'STREAM';
   c_str_lock         CONSTANT VARCHAR2 (4)  DEFAULT 'LOCK';
   c_str_project      CONSTANT VARCHAR2 (7)  DEFAULT 'PROJECT';
   c_str_outlet       CONSTANT VARCHAR2 (6)  DEFAULT 'OUTLET';
   c_str_turbine      CONSTANT VARCHAR2 (7)  DEFAULT 'TURBINE';
   c_chart_min_days   CONSTANT NUMBER        DEFAULT 5;

--   PROCEDURE p_delete_lockage (
--      p_lockage_code IN Cwms_v_lockage.lockage_code%TYPE);

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
--      p_db_Office_id               IN cwms_v_loc.db_Office_id%TYPE);

--   PROCEDURE p_delete_pool (p_Location_code     IN cwms_v_pool.location_code%TYPE
--                           ,p_pool_code         IN cwms_v_pool.pool_code%TYPE
--                           );

--   PROCEDURE p_load_pool (p_location_code  IN Cwms_v_loc.location_code%TYPE
--                        , p_pool_code      IN NUMBER
--                        , p_location_level_code_upper IN NUMBER
--                        , p_location_level_code_lower IN NUMBER
--                        , p_purpose_codes  IN VARCHAR2
--                        , p_delim           IN VARCHAR2 DEFAULT ':'
--                         );


   FUNCTION MyFunction (Param1 IN NUMBER)
      RETURN NUMBER;

   FUNCTION apex_log_error (p_error IN apex_error.t_error)
      RETURN at_cma_error_log.id%TYPE;

   FUNCTION f_validate_string (f_string_1   IN VARCHAR2,
                               f_string_2   IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION f_calc_num_pts_p_day_interval (
      f_interval_id IN cwms_V_ts_id.interval_id%TYPE)
      RETURN NUMBER;

   FUNCTION f_calc_num_pts_p_day_ts_id (
      f_cwms_ts_id IN cwms_v_ts_id.cwms_ts_id%TYPE)
      RETURN NUMBER;

   FUNCTION f_get_loc_attribs_by_xy (
      p_latitude    IN cwms_v_loc.latitude%TYPE,
      p_longitude   IN cwms_v_loc.longitude%TYPE)
      RETURN VARCHAR2;

FUNCTION f_get_ll_home_container (f_location_code IN CWMS_V_LOC.location_code%TYPE) RETURN VARCHAR2;
      
   FUNCTION f_get_loc_home_tools_by_loc (f_location_code IN cwms_v_loc.location_code%TYPE
                                        ,f_app_id        IN NUMBER
                                        ,f_session_id    IN NUMBER
                                        ) RETURN VARCHAR2 ;
  
   FUNCTION f_get_loc_num_ll(f_location_code IN cwms_v_loc.location_code%TYPE
                            ,f_location_level_kind IN VARCHAR2 DEFAULT 'ALL'
                            ) RETURN NUMBER ;
                            
   FUNCTION f_get_tz_by_xy (p_latitude    IN cwms_v_loc.latitude%TYPE,
                            p_longitude   IN cwms_v_loc.longitude%TYPE)
      RETURN cwms_v_loc.time_zone_name%TYPE;

   FUNCTION f_validate_loc_for_nh (
      f_location_id IN cwms_v_loc.locatioN_id%TYPE)
      RETURN VARCHAR2;

   FUNCTION f_validate_loc_by_loc_types (
      f_location_code IN cwms_v_loc.location_code%TYPE)
      RETURN VARCHAR2;

   FUNCTION f_get_nw_loc_link (
      f_locatioN_id          IN cwms_v_loc.locatioN_id%TYPE,
      f_map_or_rpt_or_both   IN VARCHAR2 DEFAULT 'Both',
      f_html_link_or_text    IN VARCHAR2 DEFAULT 'HTML')
      RETURN VARCHAR2;

   FUNCTION orcl_2_unix (f_oracle_date IN DATE)
      RETURN NUMBER;

   PROCEDURE copy_ts_code_to_ts_code (
      p_ts_code_from      IN     cwms_v_ts_id.ts_code%TYPE,
      p_ts_code_to        IN     cwms_v_ts_id.Ts_code%TYPE,
      p_store_rule_code   IN     cwms_store_rule.store_rule_code%TYPE,
      p_out                  OUT VARCHAR2,
      p_date_start        IN     DATE DEFAULT NULL,
      p_date_end          IN     DATE DEFAULT NULL);

   PROCEDURE copy_tsc_to_tsc_interp (
      p_ts_code_from      IN     cwms_v_ts_id.ts_code%TYPE,
      p_ts_code_to        IN     cwms_v_ts_id.Ts_code%TYPE,
      p_store_rule_code   IN     cwms_store_rule.store_Rule_code%TYPE,
      p_interpolate_tf    IN     VARCHAR2 DEFAULT 'T',
      p_out                  OUT VARCHAR2,
      p_date_start        IN     DATE,
      p_date_end          IN     DATE);

   PROCEDURE Deconstruct_ts_id (
      p_ts_code_from      IN     cwms_v_ts_id.ts_code%TYPE,
      p_interval_to       IN     cwms_v_ts_id.interval%TYPE,
      p_store_rule_code   IN     cwms_store_rule.store_rule_code%TYPE,
      p_interpolate_tf    IN     VARCHAR2 DEFAULT 'T',
      p_out                  OUT VARCHAR2        --,p_date_start       IN DATE
                                                 --,p_date_end         IN DATE
      );

   /*  PROCEDURE download_file(
         p_file IN cwms_documents_t.id%TYPE);
         */
   PROCEDURE Clean_Loc_Metadata_by_xy (
      p_db_office_id             IN cwms_v_ts_id.db_office_id%TYPE,
      p_location_code            IN cwms_v_loc.location_code%TYPE DEFAULT NULL,
      p_overwrite_county_yn      IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_nation_id_yn   IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_near_city_yn   IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_state_yn       IN VARCHAR2 DEFAULT c_app_logic_n,
      p_overwrite_tz_name_yn     IN VARCHAR2 DEFAULT c_app_logic_n);

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
      p_app_null_lookup_temp_text     OUT VARCHAR2,
      p_app_NW_UR_base_loc_ts_id_tf   OUT VARCHAR2);

   PROCEDURE load_store_rule (
      p_id              IN cwms_store_rule.store_rule_code%TYPE,
      p_default_tf      IN cwms_store_rule.use_as_default%TYPE, --cwms_ts_store_rule_l.default_tf%TYPE ,
      p_description     IN cwms_store_rule.description%TYPE,
      p_display_value   IN cwms_store_rule.store_rule_id%TYPE,
      p_sort_order      IN AT_STORE_RULE_ORDER.sort_order%TYPE);

   PROCEDURE Load_csv_collection_to_DB (
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_store_rule_code   IN cwms_store_rule.store_rule_code%TYPE);

   PROCEDURE parse_tsv_csv (p_clob                   CLOB,
                            p_collection_name        VARCHAR2,
                            p_delim                  VARCHAR2 DEFAULT ',',
                            p_optionally_enclosed    VARCHAR2 DEFAULT '"',
                            p_all_one_ts_id_tf       VARCHAR2 DEFAULT 'T');

   PROCEDURE preload_store_rule_editor (
      p_store_Rule_code   IN     cwms_store_rule.store_rule_code%TYPE,
      p_use_as_default       OUT cwms_store_rule.use_as_default%TYPE, --cwms_ts_store_rule_l.default_tf%TYPE ,
      p_description          OUT cwms_store_rule.description%TYPE,
      p_store_rule_id        OUT cwms_store_rule.store_rule_id%TYPE,
      p_sort_order           OUT AT_STORE_RULE_ORDER.sort_order%TYPE);

   PROCEDURE load_tsc_parallel (
      p_ts_code_left          IN cwms_v_ts_id.ts_code%TYPE,
      p_ts_code_right         IN cwms_v_ts_id.ts_code%TYPE,
      p_new_collection_name   IN VARCHAR2 DEFAULT 'TS_PARALLEL_COMPARE');

   PROCEDURE preload_Upload_tsv (
      p_store_rule_code IN OUT cwms_store_rule.store_Rule_code%TYPE);

   PROCEDURE p_refresh_a2w_ts_codes (
      p_db_office_id    IN at_a2w_ts_codes_by_loc.db_office_id%TYPE,
      p_location_code   IN at_a2w_ts_codes_by_loc.location_code%TYPE DEFAULT NULL);

   PROCEDURE p_sync_cwms_office_from_CM2 (
      p_sync_office_buildings_yn    IN     VARCHAR2 DEFAULT c_app_logic_y,
      p_sync_office_boundaries_yn   IN     VARCHAR2 DEFAULT c_app_logic_y,
      p_status                         OUT VARCHAR2);

   PROCEDURE p_sync_cwms_geo_tbls_w_CM2 (
      p_compare_or_sync   IN     VARCHAR2 DEFAULT 'COMPARE',
      p_status               OUT VARCHAR2);

   PROCEDURE p_sync_cwms_rivergages_w_CM2;

   PROCEDURE p_sync_cwms_nid_w_CM2 (
      p_compare_or_sync   IN     VARCHAR2 DEFAULT 'COMPARE',
      p_status               OUT VARCHAR2);

   PROCEDURE p_sync_cwms_loc_by_NIDID (
      p_db_Office_id   IN     cwms_v_loc.db_Office_id%TYPE,
      p_location_id    IN     cwms_v_loc.locatioN_id%TYPE DEFAULT NULL,
      p_action         IN     VARCHAR2 DEFAULT 'PL/SQL',
      p_sync_tf        IN     VARCHAR2 DEFAULT c_cwms_logic_f,
      p_out               OUT CLOB);

   PROCEDURE p_sync_cwms_loc_by_RG (
      p_db_Office_id   IN     cwms_v_loc.db_Office_id%TYPE,
      p_location_id    IN     cwms_v_loc.locatioN_id%TYPE DEFAULT NULL,
      p_action         IN     VARCHAR2 DEFAULT 'PL/SQL',
      p_sync_tf        IN     VARCHAR2 DEFAULT c_cwms_logic_f,
      p_parse_for      IN     VARCHAR2 DEFAULT NULL,
      p_out               OUT CLOB);

   PROCEDURE p_load_tsv (
      p_collection_name   IN     apex_collections.collection_name%TYPE,
      p_display_out          OUT VARCHAR2);

   PROCEDURE p_clean_location_type (
      p_db_office_id        IN cwms_v_loc.db_Office_id%TYPE,
      p_location_type_old   IN cwms_v_loc.location_type%TYPE,
      p_location_type_new   IN cwms_v_loc.location_type%TYPE);

   PROCEDURE p_clear_a2w_ts_code (p_ts_code IN cwms_v_ts_id.ts_code%TYPE);

   PROCEDURE p_load_Project_Purpose (
      p_db_Office_id       IN cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id        IN cwms_v_loc.locatioN_id%TYPE,
      p_project_purposes   IN VARCHAR2,
      p_delim              IN VARCHAR2 DEFAULT ',',
      p_purpose_type       IN VARCHAR2 DEFAULT 'AUTHORIZED');

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
      p_multiple_values         OUT VARCHAR2);

   PROCEDURE p_preload_Project_Purpose (
      p_db_Office_id       IN     cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id        IN     cwms_v_loc.locatioN_id%TYPE,
      p_delim              IN     VARCHAR2 DEFAULT ',',
      p_purpose_type       IN     VARCHAR2 DEFAULT 'AUTHORIZED',
      p_project_purposes      OUT VARCHAR2);

   PROCEDURE p_preload_squery_by_xy (
      p_lat              IN     cwms_v_loc.latitude%TYPE,
      p_lon              IN     cwms_v_loc.longitude%TYPE,
      p_county              OUT cwms_v_loc.county_name%TYPE,
      p_nation_id           OUT cwms_v_loc.nation_id%TYPE,
      p_nearest_city        OUT cwms_v_loc.nearest_city%TYPE,
      p_state_initial       OUT cwms_v_loc.state_initial%TYPE,
      p_time_zone_name      OUT cwms_v_loc.time_zone_name%TYPE);

   PROCEDURE p_preload_loc_by_station_5 (
      p_db_office_id     IN     cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_id      IN     cwms_v_loc.locatioN_id%TYPE DEFAULT NULL,
      p_debug_or_plsql   IN     VARCHAR2 DEFAULT 'DEBUG',
      p_fire_sql         IN     VARCHAR2 DEFAULT 'F',
      p_out                 OUT CLOB);

   PROCEDURE p_preload_location (
      p_db_office_id          IN     cwms_v_loc.db_office_id%TYPE,
      p_locatioN_id           IN     cwms_v_loc.location_id%TYPE,
      p_locatioN_type_api     IN OUT cwms_v_location_Type.location_type%TYPE,
      p_api_read_only            OUT VARCHAR2,
      p_lock_project_id          OUT VARCHAR2,
      p_num_locs_project_of      OUT NUMBER,
      p_outlet_project_id        OUT cwms_v_project.project_id%TYPE,
      p_turbine_project_id       OUT cwms_v_project.project_id%TYPE);

   PROCEDURE p_preload_tsv_page (
      p_ts_code                 IN     cwms_v_ts_id.ts_code%TYPE,
      p_collection_name         IN     apex_collections.collection_name%TYPE,
      p_unit_system             IN     cwms_v_loc.unit_system%TYPE,
      p_reset_tf                IN OUT VARCHAR2,
      p_begin_date              IN     DATE,
      p_end_date                IN     DATE,
      p_base_Parameter_id          OUT cwms_v_ts_id.base_parameter_id%TYPE,
      p_num_records_in_col         OUT NUMBER,
      p_simple_or_fancy_chart      OUT VARCHAR2);

   PROCEDURE p_load_tsv_col (
      p_ts_code           IN cwms_v_tsv.ts_code%TYPE,
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_begin_date        IN DATE,
      p_end_date          IN DATE,
      p_unit_system       IN cwms_v_loc.unit_system%TYPE);

   PROCEDURE p_load_loc_by_station_5 (
      p_db_office_id   IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_id    IN cwms_v_loc.locatioN_id%TYPE DEFAULT NULL);

   PROCEDURE p_load_missing_tsv (
      p_ts_code           IN cwms_v_ts_id.ts_code%TYPE,
      p_date_start        IN DATE,
      p_date_end          IN DATE,
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_load_to_db_tf     IN VARCHAR2 DEFAULT 'F',
      p_load_as_zero      IN VARCHAR2 DEFAULT 'F');

   PROCEDURE p_get_values_by_seq_id (
      p_collection_name   IN     apex_collections.collection_name%TYPE,
      p_seq_id            IN     apex_collections.seq_id%TYPE,
      p_value                OUT NUMBER,
      p_value_previous       OUT NUMBER,
      p_value_next           OUT NUMBER,
      p_value_average        OUT NUMBER,
      p_seq_Id_previous      OUT apex_collections.seq_id%TYPE,
      p_seq_id_next          OUT apex_collections.seq_id%TYPE);

   PROCEDURE p_get_values_between_seq_id (
      p_collection_name   IN     apex_collections.collection_name%TYPE,
      p_seq_id_start      IN     apex_collections.seq_id%TYPE,
      p_seq_Id_end        IN     apex_collections.seq_id%TYPE,
      p_num_values        IN     NUMBER,
      p_calc_method       IN     VARCHAR2 DEFAULT 'LINEAR',
      p_value_start          OUT NUMBER,
      p_value_end            OUT NUMBER,
      p_value_increment      OUT NUMBER);


   PROCEDURE p_clean_tsv_zeros (
      p_collection_name IN apex_collections.collection_name%TYPE);

   PROCEDURE p_clean_tsv_stdev (
      p_collectioN_name   IN apex_collections.collection_name%TYPE,
      p_stdev_threshold   IN NUMBER DEFAULT 100);

   PROCEDURE p_clear_loc_type_classif (
      p_db_Office_id    IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_code   IN cwms_v_loc.location_code%TYPE,
      p_location_type   IN Cwms_v_location_type.location_type%TYPE);

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

   PROCEDURE p_store_tsc_by_collection (
      p_collection_name   IN apex_collections.collection_name%TYPE,
      p_store_rule_code   IN cwms_store_rule.store_rule_code%TYPE);

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
      p_ts_code_rule_Curve_elev IN    at_a2w_ts_codes_by_loc.ts_code_rule_curve_elev%TYPE,
      p_ts_code_power_Gen       IN    at_a2w_ts_codes_By_loc.ts_code_power_Gen%TYPE,
      p_ts_code_temp_air        IN    at_a2w_ts_codes_by_loc.ts_code_temp_air%TYPE,
      p_ts_code_temp_water      IN    at_a2w_ts_codes_by_loc.ts_code_temp_water%TYPE,
      p_ts_code_do              IN    at_a2w_Ts_codes_by_loc.ts_code_do%TYPE,
      p_ts_code_ph              IN    at_a2w_ts_codes_by_loc.ts_code_ph%TYPE,
      p_ts_code_cond            IN    at_a2w_Ts_codes_By_loc.ts_code_cond%TYPE,
      p_rating_code_elev_stor   IN    at_rating.rating_code%TYPE,
      p_lake_summary_tf        IN     at_a2w_ts_codes_by_loc.lake_summary_Tf%TYPE,
      p_error_msg                 OUT VARCHAR2);

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
      p_lock_project_id               IN     cwms_v_lock.project_id%TYPE --:P36_PROJECT_LOCATION_ID --project_location_ref
                                                                        --                           ,p_lock_loc_obj                IN cwms_v_lock.--:P36_LOCATION_ID_EDIT    --lock_location
      ,
      p_lock_vol_per_lockage          IN     cwms_v_lock.volume_per_lockage%TYPE --volume_per_lockage
                                                                                ,
      p_lock_vol_units_id             IN     cwms_v_lock.volume_unit_id%TYPE --volume_units_id
                                                                            ,
      p_lock_lock_width               IN     cwms_v_lock.lock_width%TYPE --lock_width
                                                                        ,
      p_lock_lock_length              IN     cwms_v_lock.lock_length%TYPE --lock_length
                                                                         ,
      p_lock_min_draft                IN     cwms_v_lock.minimum_draft%TYPE --minimum_draft
                                                                           ,
      p_lock_norm_lock_lift           IN     cwms_v_lock.normal_lock_lift%TYPE --normal_lock_lift
                                                                              ,
      p_lock_units_id                 IN     cwms_v_lock.length_unit_id%TYPE --units_id
                                                                            ,
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
      p_outlet_project_id             IN     cwms_v_loc.location_id%TYPE --                           ,p_stream_id                      => :P36_LOCATION_ID_EDIT,
                                                                        ,
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
      p_debug                            OUT VARCHAR2);

   PROCEDURE p_load_Location_kind (
      p_locatioN_id            IN cwms_v_loc.location_id%TYPE,
      p_location_kind_id_new   IN cwms_v_loc.location_kind_id%TYPE,
      p_project_id             IN cwms_v_project.project_id%TYPE,
      p_structure_Type_code    IN cwms_v_embankment.structure_Type_code%TYPE,
      p_db_Office_id           IN cwms_v_loc.db_office_id%TYPE);




   PROCEDURE p_load_rating_value (
      p_rating_code   IN cwms_v_rating_values.rating_code%TYPE,
      p_ind_value_1   IN cwms_v_rating_values.ind_value_1%TYPE,
      p_ind_value_2   IN cwms_v_rating_values.ind_value_2%TYPE,
      p_ind_value_3   IN cwms_v_rating_values.ind_value_3%TYPE,
      p_ind_value_4   IN cwms_v_rating_values.ind_value_4%TYPE,
      p_dep_value     IN cwms_v_rating_values.dep_value%TYPE);

   PROCEDURE p_chart_by_ts_code (
      p_ts_code      IN cwms_v_ts_id.TS_CODE%TYPE,
      p_days         IN NUMBER DEFAULT c_chart_min_days,
      p_date_start   IN DATE DEFAULT SYSDATE - 45,
      p_date_end     IN DATE DEFAULT SYSDATE,
      xmlcalldate    IN NUMBER DEFAULT NULL);

   PROCEDURE p_chart_Rating_Curve (
      xmlcalldate       IN     NUMBER DEFAULT NULL,
      p_location_code   IN     cwms_20.av_loc.location_code%TYPE,
      p_rating_code     IN     cwms_v_rating_values.rating_code%TYPE,
      p_db_Office_id    IN     cwms_v_loc.db_Office_id%TYPE,
      p_clob_out_tf     IN     VARCHAR2 DEFAULT 'F',
      p_clob_out           OUT CLOB);

   PROCEDURE p_set_a2w_num_tsids (
      p_db_Office_id    IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_code   IN Cwms_v_loc.location_code%TYPE,
      p_user_id         IN VARCHAR2);


   PROCEDURE p_add_Missing_a2w_rows (
      p_db_Office_id   IN cwms_v_loc.db_Office_id%TYPE,
      p_locatioN_code  IN Cwms_v_loc.location_code%TYPE DEFAULT NULL,
      p_user_id        IN VARCHAR2);

   FUNCTION f_validate_location_kind_id (
      f_location_code IN cwms_v_loc.location_code%TYPE)
      RETURN VARCHAR2;

   PROCEDURE p_test;


END CWMS_CMA;