-------------------
-- general setup --
-------------------
whenever sqlerror exit;
set define on
set verify off
set pages 100
set serveroutput on
define cwms_schema='CWMS_20'
alter session set current_schema = &cwms_schema;
------------------------------------------------------------
-- spool to file that identifies the database in the name --
------------------------------------------------------------
column db_name new_value dbname
select nvl(primary_db_unique_name, db_unique_name) as db_name from v$database;
spool update_&dbname._3.0.7_to_3.1.1.log; 
-------------------
-- do the update --
-------------------
prompt ################################################################################
prompt 'VERIFYING EXPECTED VERSION'
select systimestamp from dual;
@@./18_1_1/verify_db_version
prompt ################################################################################
prompt 'MODIFYING CWMS_DB_CHANGE_LOG TABLE'
select systimestamp from dual;                                                                                   
@@./18_1_1/modify_db_change_log
prompt ################################################################################
prompt 'MODIFYING AT_SEC_CWMS_USERS TABLE'
select systimestamp from dual;      
alter table at_sec_cwms_users modify phone varchar2(24);
prompt ################################################################################
prompt 'MODIFYING TIME SERIES TABLES'
select systimestamp from dual;      
@@./18_1_1/modify_time_series_tables
prompt ################################################################################
prompt 'ADDING AT_RATING_VALUE_DEP_IDX INDEX'
select systimestamp from dual;   
create index at_rating_value_dep_idx on at_rating_value (dep_rating_ind_param_code) 
tablespace cwms_20at_data ;
prompt ################################################################################
prompt 'ADDING CONFIGURATION CATEGORY'
select systimestamp from dual;
@@./18_1_1/add_configuration_category
prompt ################################################################################
prompt 'REMOVING TRIGGER AT_STREAM_REACH_T01'
select systimestamp from dual;
@@./18_1_1/remove_at_stream_reach_t01                 
prompt ################################################################################
prompt 'DELETING CST, PST FROM CWMS_TIME_ZONE AND REBUILDING MV_TIME_ZONE'
select systimestamp from dual;
@@./18_1_1/delete_time_zones
prompt ################################################################################
prompt 'UPDATING TRANSITIONAL AND VIRTUAL RATING TABLE CONSTRAINTS'
select systimestamp from dual;
@@./18_1_1/modify_transitional_virtual_rating_tables
prompt ################################################################################
prompt 'ADDING INDEX ON DEP_RATING_PARAM_CODE FOR AT_RATING_VALUE'
select systimestamp from dual;
@@./18_1_1/add_at_rating_value_dep_index
prompt ################################################################################
prompt 'UPDATING REGI LOOKUP TABLES'
select systimestamp from dual;
@@./18_1_1/update_embankment_protection_types
@@./18_1_1/update_embankment_structure_types
@@./18_1_1/update_gate_change_computations
@@./18_1_1/update_gate_release_reasons
@@./18_1_1/update_physical_transfer_types
@@./18_1_1/update_turbine_computation_codes
@@./18_1_1/update_turbine_setting_reasons
@@./18_1_1/update_ws_contract_types
prompt ################################################################################
prompt 'ADDING NEW SCHEDULER MONITORING OBJECTS'
select systimestamp from dual;
@@../cwms/tables/cwms_auth_sched_entries
@@../cwms/tables/cwms_unauth_sched_entries
@@../cwms/views/av_auth_sched_entries
@@../cwms/views/av_unauth_sched_entries
@@../cwms/cwms_scheduler_auth_pkg
@@../cwms/cwms_scheduler_auth_pkg_body
prompt ################################################################################
prompt 'ADDING CWMS POOLS'
select systimestamp from dual;
@@../cwms/types/number_tab_tab_t
@@../cwms/tables/at_pool_name
@@../cwms/tables/at_pool
@@../cwms/views/av_pool_name
@@../cwms/views/av_pool
@@../cwms/cwms_pool_pkg
@@../cwms/cwms_pool_pkg_body                         
prompt ################################################################################
prompt 'ADDING LOCATION LEVEL LABELS AND SOURCES'
select systimestamp from dual;
@@../cwms/tables/at_loc_lvl_label
@@../cwms/views/av_loc_lvl_label
@@../cwms/tables/at_loc_lvl_source
@@../cwms/views/av_loc_lvl_source
@@../cwms//cwms_level_pkg
@@../cwms/cwms_level_pkg_body
prompt ################################################################################
prompt 'UPDATING CWMS FORECAST'
select systimestamp from dual;
@@../cwms/cwms_forecast_pkg
@@../cwms/cwms_forecast_pkg_body
@@../cwms/views/av_forecast
@@../cwms/views/av_forecast_ex
@@../cwms/views/av_forecast_spec
prompt ################################################################################
prompt 'ADDING TIME SERIES TEXT VIEWS'
select systimestamp from dual;
@@../cwms/views/av_std_text
@@../cwms/views/av_ts_text
prompt ################################################################################
prompt 'ADDING HISTORIC TIME SERIES FLAG'
select systimestamp from dual;
@@./18_1_1/add_historic_time_series
delete from at_clob where id in ('/VIEWDOCS/AV_CWMS_TS_ID', '/VIEWDOCS/AV_CWMS_TS_ID2', '/VIEWDOCS/ZAV_CWMS_TS_ID');
@@../cwms/views/av_cwms_ts_id
@@../cwms/views/av_cwms_ts_id2
@@../cwms/views/zav_cwms_ts_id
@@../cwms/cwms_ts_id_pkg_body
@@../cwms/cwms_ts_pkg_body
@@../cwms/cwms_ts_pkg        
prompt ################################################################################
prompt 'UPDATING CMA AND A2W'
select systimestamp from dual;   
@@./18_1_1/update_cma_and_a2w
whenever sqlerror continue
@@../cwms/views/av_a2w_ts_codes_by_loc
@@../cwms/views/av_a2w_ts_codes_by_loc2
whenever sqlerror exit
prompt ################################################################################
prompt 'LENGTHENING AT_BASE_LOCATION.BASE_LOCATION_ID'
select systimestamp from dual;   
-- alter tables
drop index at_base_location_idx1;
alter table at_base_location modify (
   base_location_id varchar2(24)
);
create unique index at_base_location_idx1 on at_base_location(
   db_office_code, upper(base_location_id)
) tablespace cwms_20at_data;
alter table at_loc_lvl_indicator_tab modify (
   location_id varchar2(57)
);
alter table at_cwms_ts_id modify (
   base_location_id varchar2(24),
   location_id      varchar2(57)
);
alter table at_shef_decode_spec modify (
   location_id varchar2(57)
);
-- drop types
drop type cat_dss_xchg_ts_map_obj_t force;
drop type cat_loc_obj_t force;
drop type cat_location2_obj_t force;
drop type cat_location_obj_t force;
drop type cat_ts_cwms_20_obj_t force;
drop type cat_ts_obj_t force;
drop type char_49_array_type force;
drop type cwms_ts_id_t force;
drop type loc_alias_type force;
drop type loc_alias_type2 force;
drop type loc_alias_type3 force;
drop type loc_lvl_cur_max_ind_t force;
drop type loc_lvl_indicator_t force;
drop type loc_type_ds force;                                                       
drop type location_level_t force;
drop type location_ref_t force;
drop type nested_ts_type force;
drop type rating_spec_t force;
drop type rating_t force;
drop type screen_assign_t force;
drop type stream_rating_t force;
drop type time_series_range_t force;
drop type timeseries_req_type force;
drop type timeseries_type force;
drop type tr_template_set_type force;
drop type ts_alias_t force;
drop type vdatum_rating_t force;
drop type vdatum_stream_rating_t force;
drop type ztimeseries_type force;
-- recreate types
@@../cwms/types/cat_dss_xchg_ts_map_obj_t
@@../cwms/types/cat_loc_obj_t
@@../cwms/types/cat_location2_obj_t
@@../cwms/types/cat_location_obj_t
@@../cwms/types/cat_ts_cwms_20_obj_t
@@../cwms/types/cat_ts_obj_t
@@../cwms/types/char_49_array_type
@@../cwms/types/cwms_ts_id_t
@@../cwms/types/loc_alias_type
@@../cwms/types/loc_alias_type2
@@../cwms/types/loc_alias_type3
@@../cwms/types/loc_lvl_cur_max_ind_t
@@../cwms/types/loc_lvl_indicator_t
@@../cwms/types/loc_lvl_indicator_t-body
@@../cwms/types/loc_type_ds
@@../cwms/types/location_level_t
@@../cwms/types/location_level_t-body
@@../cwms/types/location_ref_t
@@../cwms/types/location_ref_t-body
@@../cwms/types/nested_ts_type
@@../cwms/types/rating_spec_t
@@../cwms/types/rating_spec_t-body
@@../cwms/types/rating_t
@@../cwms/types/rating_t-body
@@../cwms/types/screen_assign_t
@@../cwms/types/stream_rating_t
@@../cwms/types/stream_rating_t-body
@@../cwms/types/time_series_range_t
@@../cwms/types/timeseries_req_type
@@../cwms/types/timeseries_type
@@../cwms/types/tr_template_set_type
@@../cwms/types/ts_alias_t
@@../cwms/types/vdatum_rating_t
@@../cwms/types/vdatum_rating_t-body
@@../cwms/types/vdatum_stream_rating_t
@@../cwms/types/vdatum_stream_rating_t-body
@@../cwms/types/ztimeseries_type
-- retbuild packages
@@../cwms/cwms_alarm_pkg_body
@@../cwms/cwms_apex_pkg_body
@@../cwms/cwms_basin_pkg
@@../cwms/cwms_basin_pkg_body
@@../cwms/cwms_cat_pkg
@@../cwms/cwms_cat_pkg_body
@@../cwms/cwms_data_dissem_pkg
@@../cwms/cwms_display_pkg
@@../cwms/cwms_display_pkg_body
@@../cwms/cwms_embank_pkg
@@../cwms/cwms_embank_pkg_body
--@@../cwms/cwms_forecast_pkg
--@@../cwms/cwms_forecast_pkg_body
@@../cwms/cwms_gage_pkg
@@../cwms/cwms_gage_pkg_body
@@../cwms/cwms_gate_pkg_body
--@@../cwms/cwms_level_pkg
--@@../cwms/cwms_level_pkg_body
@@../cwms/cwms_loc_pkg
@@../cwms/cwms_loc_pkg_body
@@../cwms/cwms_lock_pkg
@@../cwms/cwms_lock_pkg_body
@@../cwms/cwms_outlet_pkg_body
--@@../cwms/cwms_pool_pkg
--@@../cwms/cwms_pool_pkg_body
@@../cwms/cwms_project_pkg
@@../cwms/cwms_project_pkg_body
@@../cwms/cwms_rating_pkg
@@../cwms/cwms_rating_pkg_body
@@../cwms/cwms_sec_pkg 
@@../cwms/cwms_sec_pkg_body 
@@../cwms/cwms_shef_pkg
@@../cwms/cwms_shef_pkg_body
@@../cwms/cwms_stream_pkg
@@../cwms/cwms_stream_pkg_body
@@../cwms/cwms_text_pkg_body
--@@../cwms/cwms_ts_pkg
--@@../cwms/cwms_ts_pkg_body
@@../cwms/cwms_turbine_pkg_body
@@../cwms/cwms_usgs_pkg_body
@@../cwms/cwms_util_pkg_body                                                          
@@../cwms/cwms_vt_pkg_body
@@../cwms/cwms_water_supply_pkg
@@../cwms/cwms_water_supply_pkg_body
@@../cwms/cwms_xchg_pkg_body
prompt ################################################################################
prompt 'LENGTHENING AT_PHYSICAL_LOCATION.PUBLIC_NAME'
select systimestamp from dual;
alter table at_physical_location modify public_name varchar2(57);
--drop type cat_loc_obj_t force;
--drop type cat_location_obj_t force;
--drop type cat_location2_obj_t force;
--drop type loc_type_ds force;
drop type location_obj_t force;
--@@../cwms/types/cat_loc_obj_t
--@@../cwms/types/cat_location_obj_t
--@@../cwms/types/cat_location2_obj_t
--@@../cwms/types/loc_type_ds
@@../cwms/types/location_obj_t
@@../cwms/types/location_obj_t-body
--@@../cwms/cwms_cat_pkg
--@@../cwms/cwms_cat_pkg_body
@@../cwms/cwms_cma_pkg_body
--@@../cwms/cwms_data_dissem_pkg
--@@../cwms/cwms_embank_pkg
--@@../cwms/cwms_embank_pkg_body
--@@../cwms/cwms_loc_pkg_body
--@@../cwms/cwms_lock_pkg
--@@../cwms/cwms_lock_pkg_body
--@@../cwms/cwms_project_pkg
--@@../cwms/cwms_project_pkg_body
prompt ################################################################################
prompt 'UPDATING TIME SERIES EXTENTS'
select systimestamp from dual;
@@../cwms/tables/at_ts_extents
@@../cwms/types/ts_extents_t
@@../cwms/types/ts_extents_t-body
@@../cwms/types/ts_extents_tab_t
@@../cwms/views/av_ts_extents_utc
@@../cwms/views/av_ts_extents_local
--@@../cwms/cwms_ts_pkg
--@@../cwms/cwms_ts_pkg_body
prompt ################################################################################
prompt 'ADDING QUEUE SUBSCRIBER NAMES'
select systimestamp from dual;
whenever sqlerror continue;
@@./18_1_1/add_at_queue_subscriber_name
@@../cwms/views/av_queue_subscriber_name
whenever sqlerror exit;
prompt ################################################################################
prompt 'ADDING KEYED LOG MESSAGES'
select systimestamp from dual;
@@../cwms/cwms_msg_pkg
@@../cwms/cwms_msg_pkg_body
prompt ################################################################################
prompt 'MODIFYING OTHER TABLES'
select systimestamp from dual;
@@./18_1_1/update_tables
@@./18_1_1/at_physical_location_t02
whenever sqlerror continue;
@@../cwms/mv_ts_code_filter
drop trigger at_rating_value_trig;
create index mv_time_zone_idx2 on mv_time_zone(time_zone_code) tablespace cwms_20at_data;
create index mv_time_zone_idx3 on mv_time_zone(upper("TIME_ZONE_NAME")) tablespace cwms_20at_data;
create index at_log_message_properties_idx1 on at_log_message_properties (prop_name, nvl(prop_text, prop_value), msg_id) tablespace cwms_20at_data;
whenever sqlerror exit;
prompt ################################################################################
prompt 'UPDATING OTHER VIEWS'
select systimestamp from dual;
delete from at_clob where id = '/VIEWDOCS/AV_GATE_SETTING';
@@../cwms/views/av_gate_setting
delete from at_clob where id = '/VIEWDOCS/AV_LOC';
@@../cwms/views/av_loc
delete from at_clob where id = '/VIEWDOCS/AV_LOC2';
@@../cwms/views/av_loc2
delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL';
@@../cwms/views/av_location_level
prompt ################################################################################
prompt 'UPDATING OTHER TYPES'
select systimestamp from dual;
@@../cwms/types/rating_ind_parameter_t-body
@@../cwms/types/streamflow_meas_t-body
prompt ################################################################################
prompt 'UPDATING OTHER PACKAGE SPECIFICATIONS'
select systimestamp from dual;
@@../cwms/cwms_cma_pkg
@@../cwms/cwms_configuration_pkg
@@../cwms/cwms_util_pkg
prompt ################################################################################
prompt 'UPDATING OTHER PACKAGE BODDIES'
select systimestamp from dual;
@@../cwms/cwms_data_dissem_pkg_body
@@../cwms/cwms_entity_pkg_body
@@../cwms/cwms_env_pkg_body
@@../cwms/cwms_lookup_pkg_body
@@../cwms/cwms_mail_pkg_body
@@../cwms/cwms_turbine_pkg_body
@@../cwms/cwms_upass_pkg_body
@@../cwms/cwms_util_pkg_body
prompt ################################################################################
prompt 'ADDING WRITE PRIVILEGE TRIGGERS ON NEW TABLES'
select systimestamp from dual;
@@../cwms/create_sec_triggers
prompt ################################################################################
prompt 'REBUILD MV_SEC_TS_PRIVILEGES'
select systimestamp from dual;
@@./18_1_1/rebuild_mv_sec_ts_privileges -- I don't know why this is necessary - but it is
prompt ################################################################################
prompt 'INVALID OBJECTS...'
select systimestamp from dual;
select substr(object_name, 1, 30) as invalid_object, object_type from user_objects where status = 'INVALID' order by 1, 2;
prompt ################################################################################
prompt 'RECOMPILING SCHEMA'
select systimestamp from dual;
exec sys.utl_recomp.recomp_serial('CWMS_20');
prompt ################################################################################
prompt 'REMAINING INVALID OBJECTS...'
select systimestamp from dual;
select substr(object_name, 1, 30) as invalid_object, object_type from user_objects where status = 'INVALID' order by 1, 2;
prompt ################################################################################
prompt 'UPDATING DB_CHANGE_LOG'
select systimestamp from dual;
@@./18_1_1/update_db_change_log
select substr(version, 1, 10) as version, 
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date, 
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;
prompt ################################################################################
prompt 'STARTING JOBS'
select systimestamp from dual;
begin
   cwms_ts.start_immediate_upd_tsx_job; -- one time job starting now
   cwms_ts.start_update_ts_extents_job; -- weekly job at Fridays, 10:00 pm local time
end;
/
prompt ################################################################################
prompt 'UPDATE COMPLETE'
select systimestamp from dual;
exit

