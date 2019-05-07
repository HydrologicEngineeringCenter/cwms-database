-------------------
-- general setup --
-------------------
whenever sqlerror exit;
set define on
set verify off
set pages 100
set serveroutput on
define cwms_schema = 'CWMS_20'
define cwms_dba_schema = 'CWMS_DBA'
alter session set current_schema = &cwms_schema;
------------------------------------------------------------
-- spool to file that identifies the database in the name --
------------------------------------------------------------
var db_name varchar2(61)
begin
   select nvl(primary_db_unique_name, db_unique_name) into :db_name from v$database;
end;
/
whenever sqlerror continue;
declare
   l_count pls_integer;
   l_name  varchar2(30);
begin
   select count(*) into l_count from all_objects where object_name = 'CDB_PDBS';
   if l_count > 0 then
      select nvl(primary_db_unique_name, db_unique_name)
        into l_name
        from v$database;
      :db_name := l_name;
      begin
         select pdb_name
           into l_name
           from cdb_pdbs;
      exception
         when no_data_found then
            l_name := null;
      end;
      if l_name is not null then
         :db_name := :db_name||'-'||l_name;
      end if;
   end if;
end;
/
whenever sqlerror exit;
column db_name new_value db_name
select :db_name as db_name from dual;
define logfile=update_&db_name._3.0.7_to_18.1.1.log
prompt Log file = &logfile
spool &logfile;
-------------------
-- do the update --
-------------------
prompt ################################################################################
prompt 'VERIFYING EXPECTED VERSION'
select systimestamp from dual;
@@./18_1_1/verify_db_version
prompt ################################################################################
prompt 'COLLECT CURRENT PRIVILEGES'
select systimestamp from dual;
create table prev_priv as (select privilege,
                                  owner,
                                  table_name
                             from dba_tab_privs
                            where grantee = 'CWMS_USER'
                              and owner in ('&cwms_schema', '&cwms_dba_schema')
                          );
prompt ################################################################################
prompt 'DROP PURGE_QUEUES_JOB IF SCHEDULED'
select systimestamp from dual;
begin
   dbms_scheduler.drop_job(
      job_name => 'PURGE_QUEUES_JOB',
      defer => false,
      force => false);
exception
   when others then null;
end;
/
prompt ################################################################################
prompt 'MODIFYING CWMS_DB_CHANGE_LOG TABLE'
select systimestamp from dual;
@@./18_1_1/modify_db_change_log
prompt ################################################################################
prompt 'ADDING NEW STATES AND COUNTIES'
select systimestamp from dual;
whenever sqlerror continue;
@@./18_1_1/add_states+counties
whenever sqlerror exit;
prompt ################################################################################
prompt 'MODIFYING AT_SEC_CWMS_USERS TABLE'
select systimestamp from dual;
alter table at_sec_cwms_users modify phone varchar2(24);
prompt ################################################################################
prompt 'MODIFYING TIME SERIES TABLES'
select systimestamp from dual;
@@./18_1_1/modify_time_series_tables
whenever sqlerror continue
@@../cwms/mv_ts_code_filter
whenever sqlerror exit
prompt ################################################################################
prompt 'MODIFYING FOR UPDATED STREAMFLOW MEASUREMENTS'
whenever sqlerror continue
@@./18_1_1/modify_stream_meas_tables
whenever sqlerror exit
drop type streamflow_meas_t force;
@@../cwms/types/streamflow_meas_t
@@../cwms/types/streamflow_meas_t-body
prompt ################################################################################
prompt 'ADDING AT_RATING_VALUE_DEP_IDX INDEX'
select systimestamp from dual;
whenever sqlerror continue
drop index at_rating_value_fk_idx_2;
create index at_rating_value_dep_idx on at_rating_value (dep_rating_ind_param_code)
tablespace cwms_20at_data ;
whenever sqlerror exit
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
prompt 'UPDATING REGI LOOKUP TABLES'
select systimestamp from dual;
whenever sqlerror continue
@@./18_1_1/update_embankment_protection_types
@@./18_1_1/update_embankment_structure_types
@@./18_1_1/update_gate_change_computations
@@./18_1_1/update_gate_release_reasons
@@./18_1_1/update_physical_transfer_types
@@./18_1_1/update_turbine_computation_codes
@@./18_1_1/update_turbine_setting_reasons
@@./18_1_1/update_ws_contract_types
whenever sqlerror exit
@@./18_1_1/add_rowcps_triggers
prompt ################################################################################
prompt 'ADDING NEW SCHEDULER MONITORING OBJECTS'
select systimestamp from dual;
whenever sqlerror continue
@@../cwms/tables/cwms_auth_sched_entries
@@../cwms/tables/cwms_unauth_sched_entries
@@../cwms/views/av_auth_sched_entries
@@../cwms/views/av_unauth_sched_entries
@@../cwms/cwms_scheduler_auth_pkg
@@../cwms/cwms_scheduler_auth_pkg_body
create or replace public synonym cwms_scheduler_auth for cwms_scheduler_auth;
whenever sqlerror exit
prompt ################################################################################
prompt 'ADDING APPLICATION LOG OBJECTS'
select systimestamp from dual;
@@../cwms/tables/at_app_log_dir
@@../cwms/tables/at_app_log_file
@@../cwms/tables/at_app_log_entry
@@../cwms/tables/at_app_log_ingest_control
@@../cwms/cwms_log_ingest_pkg
@@../cwms/cwms_log_ingest_pkg_body
create or replace public synonym CWMS_LOG_INGEST for cwms_20.cwms_log_ingest;
prompt ################################################################################
prompt 'ADDING CWMS POOLS'
select systimestamp from dual;
whenever sqlerror continue
@@../cwms/types/number_tab_tab_t
@@../cwms/tables/at_pool_name
@@../cwms/tables/at_pool
@@../cwms/views/av_pool_name
@@../cwms/views/av_pool
@@../cwms/cwms_pool_pkg
@@../cwms/cwms_pool_pkg_body
create or replace public synonym cwms_pool for cwms_pool;
whenever sqlerror exit
prompt ################################################################################
prompt 'ADDING LOCATION LEVEL LABELS AND SOURCES'
select systimestamp from dual;
@@../cwms/tables/at_loc_lvl_label
@@../cwms/views/av_loc_lvl_label
@@../cwms/tables/at_loc_lvl_source
@@../cwms/views/av_loc_lvl_source
@@../cwms/cwms_level_pkg
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
whenever sqlerror continue
delete from at_clob where id in ('/VIEWDOCS/AV_CWMS_TS_ID', '/VIEWDOCS/AV_CWMS_TS_ID2', '/VIEWDOCS/ZAV_CWMS_TS_ID');
drop package cwms_ts_id;
drop package cwms_ts;
@@./18_1_1/add_historic_time_series
@@../cwms/views/av_cwms_ts_id
@@../cwms/views/av_cwms_ts_id2
@@../cwms/views/zav_cwms_ts_id
@@../cwms/cwms_ts_id_pkg
@@../cwms/cwms_ts_id_pkg_body
@@../cwms/cwms_ts_pkg
@@../cwms/cwms_ts_pkg_body
whenever sqlerror exit
prompt ################################################################################
prompt 'UPDATING CMA AND A2W'
select systimestamp from dual;
@@./18_1_1/update_cma_and_a2w
whenever sqlerror continue
delete from at_clob where id like '/VIEWDOCS/AV_A2W_TS_CODES_BY_LOC%';
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
@@../cwms/cwms_util_pkg
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
@@../cwms/cwms_cma_pkg
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
whenever sqlerror continue
@@../cwms/tables/at_ts_extents
@@../cwms/types/ts_extents_t
@@../cwms/types/ts_extents_t-body
@@../cwms/types/ts_extents_tab_t
@@../cwms/views/av_ts_extents_utc
@@../cwms/views/av_ts_extents_local
--@@../cwms/cwms_ts_pkg
--@@../cwms/cwms_ts_pkg_body
whenever sqlerror exit
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
prompt 'ADDING APPLICATION LOGIN/LOGOUT'
select systimestamp from dual;
@@../cwms/tables/at_application_login
@@../cwms/tables/at_application_session
@@../cwms/views/av_application_login
@@../cwms/views/av_application_session
-- @@../cwms/cwms_util_pkg
-- @@../cwms/cwms_util_pkg_body
prompt ################################################################################
prompt 'MODIFYING OTHER TABLES'
select systimestamp from dual;
@@./18_1_1/update_tables
@@./18_1_1/at_physical_location_t02
@@./18_1_1/modify_water_supply_tables
alter table at_seasonal_location_level modify (value null);
whenever sqlerror continue;
@@../cwms/mv_ts_code_filter
drop trigger at_rating_value_trig;
create index mv_time_zone_idx2 on mv_time_zone(time_zone_code) tablespace cwms_20at_data;
create index mv_time_zone_idx3 on mv_time_zone(upper("TIME_ZONE_NAME")) tablespace cwms_20at_data;
create index at_log_message_properties_idx1 on at_log_message_properties (prop_name, nvl(prop_text, prop_value), msg_id) tablespace cwms_20at_data;
-- New Error Messages
insert into cwms_error (err_code, err_name, err_msg) values (-20049, 'NO SUCH APPLICATION INSTANCE', 'No application instance is associated with the specified UUID');
insert into cwms_error (err_code, err_name, err_msg) values (-20050, 'APPLICATION INSTANCE LOGGED OUT', 'The application instance associated with the specified UUID has logged out');
-- New Unit
insert into cwms_unit values(99, 'bar', 22, null,  'Bars', 'Pressure of 1 standard atmosphere');
-- New Unit Aliases
delete from at_unit_alias where alias_id = 'Celcius';
insert into at_unit_alias values('1000 M2',         53,  3);
insert into at_unit_alias values('1000 M3',         53, 77);
insert into at_unit_alias values('ACRES',           53,  4);
insert into at_unit_alias values('ATM',             53, 99);
insert into at_unit_alias values('ATMOSPHERE',      53, 99);
insert into at_unit_alias values('ATMOSPHERES',     53, 99);
insert into at_unit_alias values('B-UNIT',          53, 96);
insert into at_unit_alias values('BAR',             53, 99);
insert into at_unit_alias values('BARS',            53, 99);
insert into at_unit_alias values('B_UNIT',          53, 96);
insert into at_unit_alias values('Celsius',         53, 67);
insert into at_unit_alias values('DSF',             53, 79);
insert into at_unit_alias values('FT3/S',           53, 72);
insert into at_unit_alias values('FT3/SEC',         53, 72);
insert into at_unit_alias values('Feet',            53, 35);
insert into at_unit_alias values('GWH',             53, 23);
insert into at_unit_alias values('HOUR',            53, 19);
insert into at_unit_alias values('HOURS',           53, 19);
insert into at_unit_alias values('HR',              53, 19);
insert into at_unit_alias values('HZ',              53, 93);
insert into at_unit_alias values('Inch',            53, 36);
insert into at_unit_alias values('KAF',             53, 82);
insert into at_unit_alias values('KELVIN',          53, 98);
insert into at_unit_alias values('KELVINS',         53, 98);
insert into at_unit_alias values('KHZ',             53, 94);
insert into at_unit_alias values('KHz',             53, 94);
insert into at_unit_alias values('KW',              53, 58);
insert into at_unit_alias values('KWH',             53, 24);
insert into at_unit_alias values('M2',              53,  8);
insert into at_unit_alias values('M3',              53, 85);
insert into at_unit_alias values('M3/SEC',          53, 73);
insert into at_unit_alias values('METERS',          53, 38);
insert into at_unit_alias values('MHZ',             53, 95);
insert into at_unit_alias values('MIN',             53, 20);
insert into at_unit_alias values('MINUTE',          53, 20);
insert into at_unit_alias values('MINUTES',         53, 20);
insert into at_unit_alias values('MM',              53, 40);
insert into at_unit_alias values('MWH',             53, 25);
insert into at_unit_alias values('Mile',            53, 39);
insert into at_unit_alias values('POUNDS',          53, 28);
insert into at_unit_alias values('SEC',             53, 21);
insert into at_unit_alias values('SECOND',          53, 21);
insert into at_unit_alias values('SECONDS',         53, 21);
insert into at_unit_alias values('SFD',             53, 79);
insert into at_unit_alias values('SURVEY FEET',     53, 91);
insert into at_unit_alias values('SURVEY FOOT',     53, 91);
insert into at_unit_alias values('TWH',             53, 26);
insert into at_unit_alias values('UMHO/CM',         53, 16);
insert into at_unit_alias values('UMHOS/CM',        53, 16);
insert into at_unit_alias values('WH',              53, 27);
insert into at_unit_alias values('atm',             53, 99);
insert into at_unit_alias values('atmosphere',      53, 99);
insert into at_unit_alias values('atmospheres',     53, 99);
insert into at_unit_alias values('b',               53, 96);
insert into at_unit_alias values('b-unit',          53, 96);
insert into at_unit_alias values('b_unit',          53, 96);
insert into at_unit_alias values('bars',            53, 99);
insert into at_unit_alias values('cfs-day',         53, 79);
insert into at_unit_alias values('cu ft',           53, 81);
insert into at_unit_alias values('cubic feet',      53, 81);
insert into at_unit_alias values('cycles/s',        53, 93);
insert into at_unit_alias values('cycles/sec',      53, 93);
insert into at_unit_alias values('deg c',           53, 67);
insert into at_unit_alias values('deg f',           53, 68);
insert into at_unit_alias values('ft3/s',           53, 72);
insert into at_unit_alias values('ft^3/s',          53, 72);
insert into at_unit_alias values('g/cm3',           53, 50);
insert into at_unit_alias values('hz',              53, 93);
insert into at_unit_alias values('in/deg-d',        53, 55);
insert into at_unit_alias values('k',               53, 98);
insert into at_unit_alias values('kelvin',          53, 98);
insert into at_unit_alias values('kelvins',         53, 98);
insert into at_unit_alias values('khz',             53, 94);
insert into at_unit_alias values('lbf',             53, 28);
insert into at_unit_alias values('mHz',             53, 95);
insert into at_unit_alias values('mg/L',            53, 51);
insert into at_unit_alias values('mhz',             53, 95);
insert into at_unit_alias values('mm/deg-d',        53, 56);
insert into at_unit_alias values('newton',          53, 90);
insert into at_unit_alias values('newtons',         53, 90);
insert into at_unit_alias values('pounds',          53, 28);
insert into at_unit_alias values('second-foot-day', 53, 79);
insert into at_unit_alias values('sfd',             53, 79);
insert into at_unit_alias values('survey feet',     53, 91);
insert into at_unit_alias values('survey foot',     53, 91);
-- New Unit Conversions
insert into cwms_unit_conversion values('bar',   'bar',   22, 99, 99, 1.0,           0.0, null);
insert into cwms_unit_conversion values('bar',   'in-hg', 22, 99, 62, 29.5299801647, 0.0, null);
insert into cwms_unit_conversion values('bar',   'kPa',   22, 99, 63, 100.0,         0.0, null);
insert into cwms_unit_conversion values('bar',   'mb',    22, 99, 64, 1000.0,        0.0, null);
insert into cwms_unit_conversion values('bar',   'mm-hg', 22, 99, 65, 750.061505043, 0.0, null);
insert into cwms_unit_conversion values('bar',   'psi',   22, 99, 66, 14.5037743897, 0.0, null);
insert into cwms_unit_conversion values('in-hg', 'bar',   22, 62, 99, 0.03386389,    0.0, null);
insert into cwms_unit_conversion values('kPa',   'bar',   22, 63, 99, 0.01,          0.0, null);
insert into cwms_unit_conversion values('mb',    'bar',   22, 64, 99, 0.001,         0.0, null);
insert into cwms_unit_conversion values('mm-hg', 'bar',   22, 65, 99, 0.001333224,   0.0, null);
insert into cwms_unit_conversion values('psi',   'bar',   22, 66, 99, 0.06894757,    0.0, null);
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
delete from at_clob where id = '/VIEWDOCS/AV_LOCK';
@@../cwms/views/av_lock
delete from at_clob where id = '/VIEWDOCS/AV_LOC_LVL_ATTRIBUTE';
@@../cwms/views/av_loc_lvl_attribute
delete from at_clob where id = '/VIEWDOCS/AV_BASE_PARAMETER_UNITS';
@@../cwms/views/av_base_parameter_units
delete from at_clob where id = '/VIEWDOCS/AV_RATING';
@@../cwms/views/av_rating
@@./18_1_1/dqu_views
create or replace public synonym CWMS_V_A2W_TS_CODES_BY_LOC for AV_A2W_TS_CODES_BY_LOC;
whenever sqlerror continue;
@@../cwms/views/av_location_level_curval
@@../cwms/views/av_entity_category
whenever sqlerror exit;
@@../cwms/views/mv_location_level_curval
prompt ################################################################################
prompt 'UPDATING OTHER TYPES'
select systimestamp from dual;
whenever sqlerror continue
drop public synonym cwms_t_group_type2;
drop public synonym cwms_t_group_type3;
drop public synonym cwms_t_loc_alias_type2;
drop public synonym cwms_t_loc_alias_type3;
drop type old_vdatum_stream_rating_t force;
drop type old_stream_rating_t force;
drop type old_vdatum_rating_t force;
drop type old_rating_t force;
drop type project_obj_t force;
@@../cwms/types/project_obj_t
@@../cwms/types/project_obj_t-body
whenever sqlerror exit
@@../cwms/types/rating_ind_parameter_t-body
@@../cwms/types/clob_tab_t
prompt ################################################################################
prompt 'UPDATING OTHER PACKAGE SPECIFICATIONS'
select systimestamp from dual;
whenever sqlerror continue
drop package old_cwms_rating;
whenever sqlerror exit
@@../cwms/cwms_configuration_pkg
@@../cwms/cwms_pump_pkg
@@../cwms/cwms_usgs_pkg
@@../cwms/cwms_xchg_pkg
create or replace public synonym cwms_tsv for cwms_tsv;
prompt ################################################################################
prompt 'UPDATING OTHER PACKAGE BODDIES'
select systimestamp from dual;
@@../cwms/cwms_data_dissem_pkg_body
@@../cwms/cwms_entity_pkg_body
@@../cwms/cwms_env_pkg_body
@@../cwms/cwms_lookup_pkg_body
@@../cwms/cwms_mail_pkg_body
@@../cwms/cwms_pump_pkg_body
@@../cwms/cwms_tsv_pkg_body
@@../cwms/cwms_upass_pkg_body
@@../cwms_dba/cwms_user_admin_pkg_body
prompt ################################################################################
prompt 'ADDING WRITE PRIVILEGE TRIGGERS ON NEW TABLES'
select systimestamp from dual;
set define on
@@../cwms/create_sec_triggers
--prompt ################################################################################
--prompt 'REBUILD MV_SEC_TS_PRIVILEGES'
--select systimestamp from dual;
-- -- I don't know why the following line is necessary - but it is
--@@./18_1_1/rebuild_mv_sec_ts_privileges
prompt ################################################################################
prompt 'CORRECT BAD WORDING IN TRIGGERS'
select systimestamp from dual;
begin
   for rec in (select description,
                      trigger_body
                 from user_triggers
                where regexp_like(description, 'REFERENCING\s+FOR', 'i')
              )
   loop
      execute immediate
         'create or replace TRIGGER '
         ||regexp_replace(rec.description, 'REFERENCING\s+FOR', 'FOR', 1, 1, 'i')
         ||rec.trigger_body;
   end loop;
end;
/
prompt ################################################################################
prompt 'INVALID OBJECTS...'
select systimestamp from dual;
set pagesize 100
select owner||'.'||substr(object_name, 1, 30) as invalid_object,
       object_type
  from all_objects
 where status = 'INVALID'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by 1, 2;
prompt ################################################################################
prompt 'RECOMPILING SCHEMA'
select systimestamp from dual;
exec sys.utl_recomp.recomp_serial('&cwms_schema');
prompt ################################################################################
prompt 'REMAINING INVALID OBJECTS...'
select owner||'.'||substr(object_name, 1, 30) as invalid_object,
       object_type
  from all_objects
 where status = 'INVALID'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by 1, 2;
select owner||'.'||substr(name, 1, 30) as name,
       type,
       substr(line||':'||position, 1, 12) as location,
       substr(text, 1, 132) as error
  from all_errors
 where attribute = 'ERROR'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by owner, type, name, sequence;
prompt ################################################################################
prompt 'UPDATING SERVICE_USER_POLICY'
select systimestamp from dual;
set define on
@@../cwms/create_service_user_policy
prompt ################################################################################
prompt 'RESTORE PREVIOUS PRIVILEGES'
select systimestamp from dual;
begin
   for rec in (select privilege, owner, table_name from prev_priv) loop
      begin
         execute immediate 'grant '||rec.privilege||' on '||rec.owner||'.'||rec.table_name||' to cwms_user';
      exception
         when others then null;
      end;
   end loop;
end;
/
drop table prev_priv;
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
prompt 'CREATE THE AV_QUEUE_MESSAGES VIEW'
select systimestamp from dual;
exec cwms_msg.create_av_queue_subscr_msgs;
prompt ################################################################################
prompt 'STARTING JOBS'
select systimestamp from dual;
begin
   cwms_ts.start_immediate_upd_tsx_job; -- one time job starting now
   begin
      cwms_ts.start_update_ts_extents_job; -- weekly job at Fridays, 10:00 pm local time
   exception
      when others then
         if instr(sqlerrm, 'another instance is already running') > 0 then
            null;
         else
            raise;
         end if;
   end;
   cwms_msg.start_remove_subscribers_job;
end;
/
prompt ################################################################################
prompt 'NOTIFICATIONS'
select systimestamp from dual;
prompt ================================================================================
prompt 'The following locations (if any) have had their time zones changed from CST to US/Central or PST to US/Pacific.'
select office_id,
       substr(location_id, 1, 100) as location_id,
       time_zone_name
  from location_tz_changes;
drop table location_tz_changes;
prompt ================================================================================
prompt 'The following exchange sets (if any) have had their time zones changed from CST to US/Central or PST to US/Pacific.'
select office_id,
       xchg_set_id,
       substr(ts_id, 1, 100) as ts_id,
       substr(dss_pathname, 1, 100) as dss_pathname,
       time_zone_name
  from xchg_set_tz_changes;
drop table xchg_set_tz_changes;
prompt ================================================================================
prompt 'The locations (if any) have been changed to PUMP location kind'
select office_id,
       location_id,
       location_kind_id
  from pump_location_changes;
drop table pump_location_changes;
prompt ================================================================================
prompt 'The following ratings (if any) have had their source agencies set to NULL because they were not in the AT_ENTITIES table'
select * from rating_source_changes;
drop table rating_source_changes;
prompt ################################################################################
prompt 'UPDATE COMPLETE'
select systimestamp from dual;
exit

