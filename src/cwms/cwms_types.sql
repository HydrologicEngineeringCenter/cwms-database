---------------------------------------------------------------------------
-- This script may create type bodies with errors due to interdependence --
-- on packages. Continue past the errors and let the schema re-compile   --
-- in the main script determine if there is actually a problem.          --
---------------------------------------------------------------------------
-- WHENEVER sqlerror exit sql.sqlcode
WHENEVER sqlerror continue
SET define on
@@cwms/defines.sql
SET serveroutput on

------------------------------
-- drop types if they exist --
------------------------------
begin
   for rec in (select object_name
                 from dba_objects
                where owner = '&cwms_schema'
                  and object_type = 'TYPE'
                  and object_name not like 'SYS\_%' escape '\'
             order by object_name)
   loop
      dbms_output.put_line('Dropping type '||rec.object_name);
      execute immediate 'drop type '||rec.object_name||' force';
   end loop;
end;
/
@@cwms/types/anydata_tab_t
@@cwms/types/shef_spec_type
@@cwms/types/shef_spec_array
@@cwms/types/tsv_type
@@cwms/types/tsv_array
@@cwms/types/tsv_array_tab
@@cwms/types/ztsv_type
@@cwms/types/ztsv_array
@@cwms/types/ztsv_array_tab
@@cwms/types/ztimeseries_type
@@cwms/types/ztimeseries_array
@@cwms/types/char_16_array_type
@@cwms/types/char_32_array_type
@@cwms/types/char_49_array_type
@@cwms/types/char_183_array_type
@@cwms/types/date_table_type
@@cwms/types/timeseries_type
@@cwms/types/timeseries_array
@@cwms/types/timeseries_req_type
@@cwms/types/timeseries_req_array
@@cwms/types/nested_ts_type
@@cwms/types/nested_ts_table
@@cwms/types/source_type
@@cwms/types/source_array
@@cwms/types/tr_template_set_type
@@cwms/types/tr_template_set_array
@@cwms/types/loc_type_ds
@@cwms/types/screen_dur_mag_type
@@cwms/types/screen_dur_mag_array
@@cwms/types/screen_crit_type
@@cwms/types/screen_crit_array
@@cwms/types/screening_control_t
@@cwms/types/cwms_ts_id_t
@@cwms/types/cwms_ts_id_array
@@cwms/types/cat_ts_obj_t
@@cwms/types/cat_ts_otab_t
@@cwms/types/cat_ts_cwms_20_obj_t
@@cwms/types/cat_ts_cwms_20_otab_t
@@cwms/types/cat_loc_obj_t
@@cwms/types/cat_loc_otab_t
@@cwms/types/cat_location_obj_t
@@cwms/types/cat_location_otab_t
@@cwms/types/cat_location2_obj_t
@@cwms/types/cat_location2_otab_t
@@cwms/types/cat_location_kind_obj_t
@@cwms/types/cat_location_kind_otab_t
@@cwms/types/cat_loc_alias_obj_t
@@cwms/types/cat_loc_alias_otab_t
@@cwms/types/cat_param_obj_t
@@cwms/types/cat_param_otab_t
@@cwms/types/cat_sub_param_obj_t
@@cwms/types/cat_sub_param_otab_t
@@cwms/types/cat_sub_loc_obj_t
@@cwms/types/cat_sub_loc_otab_t
@@cwms/types/cat_state_obj_t
@@cwms/types/cat_state_otab_t
@@cwms/types/cat_county_obj_t
@@cwms/types/cat_county_otab_t
@@cwms/types/cat_timezone_obj_t
@@cwms/types/cat_timezone_otab_t
@@cwms/types/cat_dss_file_obj_t
@@cwms/types/cat_dss_file_otab_t
@@cwms/types/cat_dss_xchg_set_obj_t
@@cwms/types/cat_dss_xchg_set_otab_t
@@cwms/types/cat_dss_xchg_ts_map_obj_t
@@cwms/types/cat_dss_xchg_tsmap_otab_t
@@cwms/types/screen_assign_t
@@cwms/types/screen_assign_array
@@cwms/types/loc_alias_type
@@cwms/types/loc_alias_array
@@cwms/types/loc_alias_type2
@@cwms/types/loc_alias_array2
@@cwms/types/loc_alias_type3
@@cwms/types/loc_alias_array3
@@cwms/types/group_type
@@cwms/types/group_array
@@cwms/types/group_type2
@@cwms/types/group_array2
@@cwms/types/group_type3
@@cwms/types/group_array3
@@cwms/types/group_cat_t
@@cwms/types/group_cat_tab_t
@@cwms/types/ts_alias_t
@@cwms/types/ts_alias_tab_t
@@cwms/types/str_tab_t
@@cwms/types/str_tab_tab_t
@@cwms/types/number_tab_t
@@cwms/types/double_tab_t
@@cwms/types/double_tab_tab_t
@@cwms/types/log_message_properties_t
@@cwms/types/log_message_props_tab_t
@@cwms/types/location_ref_t
@@cwms/types/location_ref_t-body
@@cwms/types/location_ref_tab_t
@@cwms/types/location_obj_t
@@cwms/types/location_obj_t-body
@@cwms/types/specified_level_t
@@cwms/types/specified_level_t-body
@@cwms/types/specified_level_tab_t
@@cwms/types/loc_lvl_indicator_cond_t
@@cwms/types/loc_lvl_indicator_cond_t-body
@@cwms/types/loc_lvl_ind_cond_tab_t
@@cwms/types/zloc_lvl_indicator_t
@@cwms/types/zloc_lvl_indicator_t-body
@@cwms/types/zloc_lvl_indicator_tab_t
@@cwms/types/loc_lvl_indicator_t
@@cwms/types/loc_lvl_indicator_t-body
@@cwms/types/loc_lvl_indicator_tab_t
@@cwms/types/seasonal_value_t
@@cwms/types/seasonal_value_t-body
@@cwms/types/seasonal_value_tab_t
@@cwms/types/seasonal_location_level_t
@@cwms/types/seasonal_loc_lvl_tab_t
@@cwms/types/zlocation_level_t
@@cwms/types/zlocation_level_t-body
@@cwms/types/location_level_t
@@cwms/types/location_level_t-body
@@cwms/types/location_level_tab_t
@@cwms/types/jms_map_msg_tab_t
@@cwms/types/property_info_t
@@cwms/types/property_info_tab_t
@@cwms/types/property_info2_t
@@cwms/types/property_info2_tab_t
@@cwms/types/time_series_range_t
@@cwms/types/time_series_range_tab_t
@@cwms/types/date2_t
@@cwms/types/date2_tab_t
@@cwms/types/loc_lvl_cur_max_ind_t
@@cwms/types/loc_lvl_cur_max_ind_tab_t
@@cwms/types/str2tbltype
@@cwms/types/vert_datum_offset_t
@@cwms/types/vert_datum_offset_tab_t
@@cwms/types/xml_tab_t
@@cwms/types/streamflow_meas_t
@@cwms/types/streamflow_meas_tab_t
@@cwms/types/streamflow_meas_t-body
@@cwms/types/abs_logic_expr_t
@@cwms/types/abs_logic_expr_t-body
@@cwms/types/logic_expr_t
@@cwms/types/logic_expr_tab_t
@@cwms/types/logic_expr_t-body
@@cwms/types/stream_t
@@cwms/types/stream_tab_t
@@cwms/types/stream_t-body
@@cwms/types/entity_t
@@cwms/types/entity_tab_t
@@cwms/types/configuration_t
@@cwms/types/configuration_tab_t
-- HOST pwd
@@rowcps_types
@@cwms_types_rating
COMMIT ;
