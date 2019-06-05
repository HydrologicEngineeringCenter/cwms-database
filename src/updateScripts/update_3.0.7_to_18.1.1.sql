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
@@../cwms/cwms_text_pkg
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
@@./18_1_1/modify_at_text_filter
alter table at_seasonal_location_level modify (value null);
whenever sqlerror continue;
@@../cwms/mv_ts_code_filter
drop trigger at_rating_value_trig;
create index mv_time_zone_idx2 on mv_time_zone(time_zone_code) tablespace cwms_20at_data;
create index mv_time_zone_idx3 on mv_time_zone(upper("TIME_ZONE_NAME")) tablespace cwms_20at_data;
create index at_log_message_properties_idx1 on at_log_message_properties (prop_name, nvl(prop_text, prop_value), msg_id) tablespace cwms_20at_data;
update cwms_county set county_name = trim(chr(160) from county_name);
-- New Configurations
insert into cwms_config_category values ('DATA RETRIEVAL', 'Data Retrieval configurations');
insert into at_configuration values (9, null, 53, 'DATA RETRIEVAL', 'Other Data Retrieval', 'Generalized Data Retreival');
insert into at_configuration values (10, 9, 53, 'DATA RETRIEVAL', 'USGS Data Retrieval', 'USGS Data Retreival');
-- New Error Messages
insert into cwms_error (err_code, err_name, err_msg) values (-20049, 'NO SUCH APPLICATION INSTANCE', 'No application instance is associated with the specified UUID');
insert into cwms_error (err_code, err_name, err_msg) values (-20050, 'APPLICATION INSTANCE LOGGED OUT', 'The application instance associated with the specified UUID has logged out');
-- New Abstract Parameters
insert into cwms_abstract_parameter values(29, 'Currency Per Volume');
insert into cwms_abstract_parameter values(30, 'Quantity Per Length');
insert into cwms_abstract_parameter values(31, 'Temerature Index');
insert into cwms_abstract_parameter values(32, 'Mass');
insert into cwms_abstract_parameter values(33, 'Mass Per Volume');
insert into cwms_abstract_parameter values(34, 'Mass Rate');
-- New Units
insert into cwms_unit values( 99, 'bar',       22, null,    'Bars',                             'Pressure of 1 standard atmosphere');
insert into cwms_unit values(100, 'cm2',        3, 'SI',   'Square centimeters',                'Area of 1 square centimeter');
insert into cwms_unit values(101, '$/kaf',     29, 'EN',   'Dollars per 1000 acre-feet',        'Monetary Value of 1 United States dollar Per 1E+03 acre feet');
insert into cwms_unit values(102, '$/mcm',     29, 'SI',   'Dollars per milliion cubic meters', 'Monetary Value of 1 United States dollar Per 1E+06 cubic meters');
insert into cwms_unit values(103, 'k$',         8, null,   '1000 Dollars',                      'Monetary value of 1E+03 United States dollar');
insert into cwms_unit values(104, 'day',        9, null,   'Days',                              'Time span of 1 day');
insert into cwms_unit values(105, 'J',         11, 'SI',   'Joules',                            'Energy of one Joule');
insert into cwms_unit values(106, 'MJ',        11, 'SI',   'Megajoules',                        'Energy of one 1E+06 Joules');
insert into cwms_unit values(107, 'cal',       11, 'EN',   'Calories',                          'Energy of 1 thermochemical calorie (vs International Table calorie)');
insert into cwms_unit values(108, 'cm/day',    17, 'SI',   'Centimeters per day',               'Velocity of 1 centimeter per day');
insert into cwms_unit values(109, 'ft/hr',     17, 'EN',   'Feet per hour',                     'Velocity of 1 foot per hour');
insert into cwms_unit values(110, 'm/hr',      17, 'SI',   'Meters per hour',                   'Velocity of 1 mmeter per hour');
insert into cwms_unit values(111, 'g/m3',      33, 'SI',   'Grams per cubic meter',             'Mass of 1 gram per volume of 1 cubic meter');
insert into cwms_unit values(112, 'lbm/ft3',   33, 'EN',   'Pounds per cubic feet',             'Mass of 1 pound per volume of 1 cubic food');
insert into cwms_unit values(113, 'ton/day',   34, 'EN',   'Tons per day',                      'Mass rate of 1 ton per day');
insert into cwms_unit values(114, 'tonne/day', 34, 'SI',   'Tonnes per day',                    'Mass rate of 1 tonne per day');
insert into cwms_unit values(115, 'g',         32, 'SI',   'Grams',                             'Mass of 1 gram');
insert into cwms_unit values(116, 'kg',        32, 'SI',   'Kilograms',                         'Mass of 1E+03');
insert into cwms_unit values(117, 'lbm',       32, 'EN',   'Pounds',                            'Mass of 1 pound');
insert into cwms_unit values(118, 'mg',        32, 'SI',   'Milligrams',                        'Mass of 1E-03 gram');
insert into cwms_unit values(119, 'ton',       32, 'EN',   'Tons',                              'Mass of 1 ton');
insert into cwms_unit values(120, 'tonne',     32, 'SI',   'Tonnes',                            'Mass of 1 tonne');
insert into cwms_unit values(121, '1/ft',      30, 'EN',   'Per foot',                          'Quanitity per 1 foot');
insert into cwms_unit values(122, '1/m',       30, 'SI',   'Per meter',                         'Quanitity per 1 meter');
insert into cwms_unit values(123, 'C-day',     31, 'SI',   'Celsius degree day',                'Temperature index of 1 C degree-day');
insert into cwms_unit values(124, 'F-day',     31, 'EN',   'Fahrenheit degree day',             'Temperature index of 1 F degree-day');
insert into cwms_unit values(125, 'KAF/mon',   26, 'EN',   '1000 acre-feet per month',          'Volume rate of 1E+03 acre-feet per month');
insert into cwms_unit values(126, 'kcms',      26, 'SI',   'Kilo-cubic meters per second',      'Volume rate of 1E+03 cms');
insert into cwms_unit values(127, 'mcm/mon',   26, 'EN',   'Million cubic meters per month',    'Volume rate of 1E+06 cubic meters per month');
insert into cwms_unit values(128, 'kdsf',      25, 'EN',   'Kilo-day-second-foot',              'Volume of 1E+03 dsf');
insert into cwms_unit values(129, 'mcm',       25, 'SI',   'Millions of cubic meters',          'Volume of 1E+06 cubic meters');
-- New Unit Aliases
delete from at_unit_alias where alias_id = 'Celcius';
insert into at_unit_alias values('1000 M2',         53,   3);
insert into at_unit_alias values('1000 M3',         53,  77);
insert into at_unit_alias values('ACRES',           53,   4);
insert into at_unit_alias values('ATM',             53,  99);
insert into at_unit_alias values('ATMOSPHERE',      53,  99);
insert into at_unit_alias values('ATMOSPHERES',     53,  99);
insert into at_unit_alias values('B-UNIT',          53,  96);
insert into at_unit_alias values('BAR',             53,  99);
insert into at_unit_alias values('BARS',            53,  99);
insert into at_unit_alias values('B_UNIT',          53,  96);
insert into at_unit_alias values('Celsius',         53,  67);
insert into at_unit_alias values('DSF',             53,  79);
insert into at_unit_alias values('FT3/S',           53,  72);
insert into at_unit_alias values('FT3/SEC',         53,  72);
insert into at_unit_alias values('Feet',            53,  35);
insert into at_unit_alias values('GWH',             53,  23);
insert into at_unit_alias values('HOUR',            53,  19);
insert into at_unit_alias values('HOURS',           53,  19);
insert into at_unit_alias values('HR',              53,  19);
insert into at_unit_alias values('HZ',              53,  93);
insert into at_unit_alias values('Inch',            53,  36);
insert into at_unit_alias values('KAF',             53,  82);
insert into at_unit_alias values('KELVIN',          53,  98);
insert into at_unit_alias values('KELVINS',         53,  98);
insert into at_unit_alias values('KHZ',             53,  94);
insert into at_unit_alias values('KHz',             53,  94);
insert into at_unit_alias values('KW',              53,  58);
insert into at_unit_alias values('KWH',             53,  24);
insert into at_unit_alias values('M2',              53,   8);
insert into at_unit_alias values('M3',              53,  85);
insert into at_unit_alias values('M3/SEC',          53,  73);
insert into at_unit_alias values('METERS',          53,  38);
insert into at_unit_alias values('MHZ',             53,  95);
insert into at_unit_alias values('MIN',             53,  20);
insert into at_unit_alias values('MINUTE',          53,  20);
insert into at_unit_alias values('MINUTES',         53,  20);
insert into at_unit_alias values('MM',              53,  40);
insert into at_unit_alias values('MWH',             53,  25);
insert into at_unit_alias values('Mile',            53,  39);
insert into at_unit_alias values('POUNDS',          53,  28);
insert into at_unit_alias values('SEC',             53,  21);
insert into at_unit_alias values('SECOND',          53,  21);
insert into at_unit_alias values('SECONDS',         53,  21);
insert into at_unit_alias values('SFD',             53,  79);
insert into at_unit_alias values('SURVEY FEET',     53,  91);
insert into at_unit_alias values('SURVEY FOOT',     53,  91);
insert into at_unit_alias values('TWH',             53,  26);
insert into at_unit_alias values('UMHO/CM',         53,  16);
insert into at_unit_alias values('UMHOS/CM',        53,  16);
insert into at_unit_alias values('WH',              53,  27);
insert into at_unit_alias values('atm',             53,  99);
insert into at_unit_alias values('atmosphere',      53,  99);
insert into at_unit_alias values('atmospheres',     53,  99);
insert into at_unit_alias values('b',               53,  96);
insert into at_unit_alias values('b-unit',          53,  96);
insert into at_unit_alias values('b_unit',          53,  96);
insert into at_unit_alias values('bars',            53,  99);
insert into at_unit_alias values('cfs-day',         53,  79);
insert into at_unit_alias values('cu ft',           53,  81);
insert into at_unit_alias values('cubic feet',      53,  81);
insert into at_unit_alias values('cycles/s',        53,  93);
insert into at_unit_alias values('cycles/sec',      53,  93);
insert into at_unit_alias values('deg c',           53,  67);
insert into at_unit_alias values('deg f',           53,  68);
insert into at_unit_alias values('ft3/s',           53,  72);
insert into at_unit_alias values('ft^3/s',          53,  72);
insert into at_unit_alias values('g/cm3',           53,  50);
insert into at_unit_alias values('hz',              53,  93);
insert into at_unit_alias values('in/deg-d',        53,  55);
insert into at_unit_alias values('k',               53,  98);
insert into at_unit_alias values('kelvin',          53,  98);
insert into at_unit_alias values('kelvins',         53,  98);
insert into at_unit_alias values('khz',             53,  94);
insert into at_unit_alias values('lbf',             53,  28);
insert into at_unit_alias values('mHz',             53,  95);
insert into at_unit_alias values('mg/L',            53,  51);
insert into at_unit_alias values('mhz',             53,  95);
insert into at_unit_alias values('mm/deg-d',        53,  56);
insert into at_unit_alias values('newton',          53,  90);
insert into at_unit_alias values('newtons',         53,  90);
insert into at_unit_alias values('pounds',          53,  28);
insert into at_unit_alias values('second-foot-day', 53,  79);
insert into at_unit_alias values('sfd',             53,  79);
insert into at_unit_alias values('survey feet',     53,  91);
insert into at_unit_alias values('survey foot',     53,  91);
insert into at_unit_alias values('$/KAF',           53, 101);
insert into at_unit_alias values('1000 ac-ft/mon',  53, 125);
insert into at_unit_alias values('1000 cms',        53, 126);
insert into at_unit_alias values('1000000 m3',      53, 129);
insert into at_unit_alias values('DAY',             53, 104);
insert into at_unit_alias values('DAYS',            53, 104);
insert into at_unit_alias values('JOULE',           53, 105);
insert into at_unit_alias values('JOULES',          53, 105);
insert into at_unit_alias values('K$',              53, 103);
insert into at_unit_alias values('KCMS',            53, 126);
insert into at_unit_alias values('MEGAJOULE',       53, 106);
insert into at_unit_alias values('MEGAJOULES',      53, 106);
insert into at_unit_alias values('calorie',         53, 107);
insert into at_unit_alias values('calories',        53, 107);
insert into at_unit_alias values('day',             53, 104);
insert into at_unit_alias values('days',            53, 104);
insert into at_unit_alias values('degC-day',        53, 123);
insert into at_unit_alias values('degF-day',        53, 124);
insert into at_unit_alias values('gm',              53, 115);
insert into at_unit_alias values('gm/m3',           53, 111);
insert into at_unit_alias values('joule',           53, 105);
insert into at_unit_alias values('joules',          53, 105);
insert into at_unit_alias values('lb/ft3',          53, 112);
insert into at_unit_alias values('lbs/ft3',         53, 112);
insert into at_unit_alias values('megajoule',       53, 106);
insert into at_unit_alias values('megajoules',      53, 106);
-- New Unit Conversions
insert into cwms_unit_conversion values('bar',       'bar',       22,    99,  99,  1.0,               0.0,           null);
insert into cwms_unit_conversion values('bar',       'in-hg',     22,    99,  62,  29.5299801647,     0.0,           null);
insert into cwms_unit_conversion values('bar',       'kPa',       22,    99,  63,  100.0,             0.0,           null);
insert into cwms_unit_conversion values('bar',       'mb',        22,    99,  64,  1000.0,            0.0,           null);
insert into cwms_unit_conversion values('bar',       'mm-hg',     22,    99,  65,  750.061505043,     0.0,           null);
insert into cwms_unit_conversion values('bar',       'psi',       22,    99,  66,  14.5037743897,     0.0,           null);
insert into cwms_unit_conversion values('in-hg',     'bar',       22,    62,  99,  0.03386389,        0.0,           null);
insert into cwms_unit_conversion values('kPa',       'bar',       22,    63,  99,  0.01,              0.0,           null);
insert into cwms_unit_conversion values('mb',        'bar',       22,    64,  99,  0.001,             0.0,           null);
insert into cwms_unit_conversion values('mm-hg',     'bar',       22,    65,  99,  0.001333224,       0.0,           null);
insert into cwms_unit_conversion values('psi',       'bar',       22,    66,  99,  0.06894757,        0.0,           null);
insert into cwms_unit_conversion values('$',         'k$',        8,     18,  103, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('$/kaf',     '$/kaf',     29,    101, 101, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('$/kaf',     '$/mcm',     29,    101, 102, 0.81071319379,     0.0,           null);
insert into cwms_unit_conversion values('$/mcm',     '$/kaf',     29,    102, 101, 1.23348183755,     0.0,           null);
insert into cwms_unit_conversion values('$/mcm',     '$/mcm',     29,    102, 102, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('1/ft',      '1/ft',      30,    121, 121, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('1/ft',      '1/m',       30,    121, 122, 3.28083989501,     0.0,           null);
insert into cwms_unit_conversion values('1/m',       '1/ft',      30,    122, 121, 0.3048,            0.0,           null);
insert into cwms_unit_conversion values('1/m',       '1/m',       30,    122, 122, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('1000 m2',   'cm2',       3,     3,   100, 10000000.0,        0.0,           null);
insert into cwms_unit_conversion values('1000 m3',   'kdsf',      25,    77,  128, 0.000408734568536, 0.0,           null);
insert into cwms_unit_conversion values('1000 m3',   'mcm',       25,    77,  129, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('C-day',     'C-day',     31,    123, 123, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('C-day',     'F-day',     31,    123, 124, 1.8,               0.0,           null);
insert into cwms_unit_conversion values('F-day',     'C-day',     31,    124, 123, 0.555555555556,    0.0,           null);
insert into cwms_unit_conversion values('F-day',     'F-day',     31,    124, 124, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('GWh',       'J',         11,    23,  105, 3.6e+12,           0.0,           null);
insert into cwms_unit_conversion values('GWh',       'MJ',        11,    23,  106, 3600000.0,         0.0,           null);
insert into cwms_unit_conversion values('GWh',       'cal',       11,    23,  107, 8.60420650096e+11, 0.0,           null);
insert into cwms_unit_conversion values('J',         'GWh',       11,    105, 23,  2.77777777778e-13, 0.0,           null);
insert into cwms_unit_conversion values('J',         'J',         11,    105, 105, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('J',         'MJ',        11,    105, 106, 1e-06,             0.0,           null);
insert into cwms_unit_conversion values('J',         'MWh',       11,    105, 25,  2.77777777778e-10, 0.0,           null);
insert into cwms_unit_conversion values('J',         'TWh',       11,    105, 26,  2.77777777778e-16, 0.0,           null);
insert into cwms_unit_conversion values('J',         'Wh',        11,    105, 27,  0.000277777777778, 0.0,           null);
insert into cwms_unit_conversion values('J',         'cal',       11,    105, 107, 0.239005736138,    0.0,           null);
insert into cwms_unit_conversion values('J',         'kWh',       11,    105, 24,  2.77777777778e-07, 0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'KAF/mon',   26,    125, 125, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'cfs',       26,    125, 72,  16.5639972621,     0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'cms',       26,    125, 73,  0.469040169423,    0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'gpm',       26,    125, 74,  7434.43782747,     0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'kcfs',      26,    125, 75,  0.0165639972621,   0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'kcms',      26,    125, 126, 0.000469040169423, 0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'mcm/mon',   26,    125, 127, 1.23348183755,     0.0,           null);
insert into cwms_unit_conversion values('KAF/mon',   'mgd',       26,    125, 76,  10.7055904716,     0.0,           null);
insert into cwms_unit_conversion values('MJ',        'GWh',       11,    106, 23,  2.77777777778e-07, 0.0,           null);
insert into cwms_unit_conversion values('MJ',        'J',         11,    106, 105, 1000000.0,         0.0,           null);
insert into cwms_unit_conversion values('MJ',        'MJ',        11,    106, 106, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('MJ',        'MWh',       11,    106, 25,  0.000277777777778, 0.0,           null);
insert into cwms_unit_conversion values('MJ',        'TWh',       11,    106, 26,  2.77777777778e-10, 0.0,           null);
insert into cwms_unit_conversion values('MJ',        'Wh',        11,    106, 27,  277.777777778,     0.0,           null);
insert into cwms_unit_conversion values('MJ',        'cal',       11,    106, 107, 239005.736138,     0.0,           null);
insert into cwms_unit_conversion values('MJ',        'kWh',       11,    106, 24,  0.277777777778,    0.0,           null);
insert into cwms_unit_conversion values('MWh',       'J',         11,    25,  105, 3600000000.0,      0.0,           null);
insert into cwms_unit_conversion values('MWh',       'MJ',        11,    25,  106, 3600.0,            0.0,           null);
insert into cwms_unit_conversion values('MWh',       'cal',       11,    25,  107, 860420650.096,     0.0,           null);
insert into cwms_unit_conversion values('TWh',       'J',         11,    26,  105, 3.6e+15,           0.0,           null);
insert into cwms_unit_conversion values('TWh',       'MJ',        11,    26,  106, 3600000000.0,      0.0,           null);
insert into cwms_unit_conversion values('TWh',       'cal',       11,    26,  107, 8.60420650096e+14, 0.0,           null);
insert into cwms_unit_conversion values('Wh',        'J',         11,    27,  105, 3600.0,            0.0,           null);
insert into cwms_unit_conversion values('Wh',        'MJ',        11,    27,  106, 0.0036,            0.0,           null);
insert into cwms_unit_conversion values('Wh',        'cal',       11,    27,  107, 860.420650096,     0.0,           null);
insert into cwms_unit_conversion values('ac-ft',     'kdsf',      25,    78,  128, 0.000504166666667, 0.0,           null);
insert into cwms_unit_conversion values('ac-ft',     'mcm',       25,    78,  129, 0.00123348183755,  0.0,           null);
insert into cwms_unit_conversion values('acre',      'cm2',       3,     4,   100, 40468564.224,      0.0,           null);
insert into cwms_unit_conversion values('cal',       'GWh',       11,    107, 23,  1.16222222222e-12, 0.0,           null);
insert into cwms_unit_conversion values('cal',       'J',         11,    107, 105, 4.184,             0.0,           null);
insert into cwms_unit_conversion values('cal',       'MJ',        11,    107, 106, 4.184e-06,         0.0,           null);
insert into cwms_unit_conversion values('cal',       'MWh',       11,    107, 25,  1.16222222222e-09, 0.0,           null);
insert into cwms_unit_conversion values('cal',       'TWh',       11,    107, 26,  1.16222222222e-15, 0.0,           null);
insert into cwms_unit_conversion values('cal',       'Wh',        11,    107, 27,  0.00116222222222,  0.0,           null);
insert into cwms_unit_conversion values('cal',       'cal',       11,    107, 107, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('cal',       'kWh',       11,    107, 24,  1.16222222222e-06, 0.0,           null);
insert into cwms_unit_conversion values('cfs',       'KAF/mon',   26,    72,  125, 0.0603719008264,   0.0,           null);
insert into cwms_unit_conversion values('cfs',       'kcms',      26,    72,  126, 2.8316846592e-05,  0.0,           null);
insert into cwms_unit_conversion values('cfs',       'mcm/mon',   26,    72,  127, 0.0744676431676,   0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'cm/day',    17,    108, 108, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'ft/hr',     17,    108, 109, 0.00136701662292,  0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'ft/s',      17,    108, 41,  3.79726839701e-07, 0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'in/day',    17,    108, 42,  0.393700787402,    0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'in/hr',     17,    108, 43,  0.0164041994751,   0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'knot',      17,    108, 97,  2.2498200144e-07,  0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'kph',       17,    108, 44,  4.16666666667e-07, 0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'm/hr',      17,    108, 110, 0.000416666666667, 0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'm/s',       17,    108, 45,  1.15740740741e-07, 0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'mm/day',    17,    108, 46,  10.0,              0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'mm/hr',     17,    108, 47,  0.416666666667,    0.0,           null);
insert into cwms_unit_conversion values('cm/day',    'mph',       17,    108, 48,  2.58904663432e-07, 0.0,           null);
insert into cwms_unit_conversion values('cm2',       '1000 m2',   3,     100, 3,   1e-07,             0.0,           null);
insert into cwms_unit_conversion values('cm2',       'acre',      3,     100, 4,   2.47105381467e-08, 0.0,           null);
insert into cwms_unit_conversion values('cm2',       'cm2',       3,     100, 100, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('cm2',       'ft2',       3,     100, 5,   0.00107639104167,  0.0,           null);
insert into cwms_unit_conversion values('cm2',       'ha',        3,     100, 6,   1e-08,             0.0,           null);
insert into cwms_unit_conversion values('cm2',       'km2',       3,     100, 7,   1e-10,             0.0,           null);
insert into cwms_unit_conversion values('cm2',       'm2',        3,     100, 8,   0.0001,            0.0,           null);
insert into cwms_unit_conversion values('cm2',       'mile2',     3,     100, 9,   3.86102158542e-11, 0.0,           null);
insert into cwms_unit_conversion values('cms',       'KAF/mon',   26,    73,  125, 2.13201355703,     0.0,           null);
insert into cwms_unit_conversion values('cms',       'kcms',      26,    73,  126, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('cms',       'mcm/mon',   26,    73,  127, 2.6298,            0.0,           null);
insert into cwms_unit_conversion values('day',       'day',       9,     104, 104, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('day',       'hr',        9,     104, 19,  24.0,              0.0,           null);
insert into cwms_unit_conversion values('day',       'min',       9,     104, 20,  1440.0,            0.0,           null);
insert into cwms_unit_conversion values('day',       'sec',       9,     104, 21,  86400.0,           0.0,           null);
insert into cwms_unit_conversion values('dsf',       'kdsf',      25,    79,  128, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('dsf',       'mcm',       25,    79,  129, 0.00244657554555,  0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'cm/day',    17,    109, 108, 731.52,            0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'ft/hr',     17,    109, 109, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'ft/s',      17,    109, 41,  0.000277777777778, 0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'in/day',    17,    109, 42,  288.0,             0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'in/hr',     17,    109, 43,  12.0,              0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'knot',      17,    109, 97,  0.000164578833693, 0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'kph',       17,    109, 44,  0.0003048,         0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'm/hr',      17,    109, 110, 0.3048,            0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'm/s',       17,    109, 45,  8.46666666667e-05, 0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'mm/day',    17,    109, 46,  7315.2,            0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'mm/hr',     17,    109, 47,  304.8,             0.0,           null);
insert into cwms_unit_conversion values('ft/hr',     'mph',       17,    109, 48,  0.000189393939394, 0.0,           null);
insert into cwms_unit_conversion values('ft/s',      'cm/day',    17,    41,  108, 2633472.0,         0.0,           null);
insert into cwms_unit_conversion values('ft/s',      'ft/hr',     17,    41,  109, 3600.0,            0.0,           null);
insert into cwms_unit_conversion values('ft/s',      'm/hr',      17,    41,  110, 1097.28,           0.0,           null);
insert into cwms_unit_conversion values('ft2',       'cm2',       3,     5,   100, 929.0304,          0.0,           null);
insert into cwms_unit_conversion values('ft3',       'kdsf',      25,    81,  128, 1.15740740741e-08, 0.0,           null);
insert into cwms_unit_conversion values('ft3',       'mcm',       25,    81,  129, 2.8316846592e-08,  0.0,           null);
insert into cwms_unit_conversion values('g',         'g',         32,    115, 115, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('g',         'kg',        32,    115, 116, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('g',         'lbm',       32,    115, 117, 0.00220462262185,  0.0,           null);
insert into cwms_unit_conversion values('g',         'mg',        32,    115, 118, 1000.0,            0.0,           null);
insert into cwms_unit_conversion values('g',         'ton',       32,    115, 119, 1.10231131092e-06, 0.0,           null);
insert into cwms_unit_conversion values('g',         'tonne',     32,    115, 120, 1e-06,             0.0,           null);
insert into cwms_unit_conversion values('g/m3',      'g/m3',      33,    111, 111, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('g/m3',      'lbm/ft3',   33,    111, 112, 6.24279605761e-05, 0.0,           null);
insert into cwms_unit_conversion values('gal',       'kdsf',      25,    80,  128, 1.54722874055e-09, 0.0,           null);
insert into cwms_unit_conversion values('gal',       'mcm',       25,    80,  129, 3.785412e-09,      0.0,           null);
insert into cwms_unit_conversion values('gpm',       'KAF/mon',   26,    74,  125, 0.000134509161716, 0.0,           null);
insert into cwms_unit_conversion values('gpm',       'kcms',      26,    74,  126, 6.30902e-08,       0.0,           null);
insert into cwms_unit_conversion values('gpm',       'mcm/mon',   26,    74,  127, 0.00016591460796,  0.0,           null);
insert into cwms_unit_conversion values('ha',        'cm2',       3,     6,   100, 100000000.0,       0.0,           null);
insert into cwms_unit_conversion values('hr',        'day',       9,     19,  104, 0.0416666666667,   0.0,           null);
insert into cwms_unit_conversion values('in/day',    'cm/day',    17,    42,  108, 2.54,              0.0,           null);
insert into cwms_unit_conversion values('in/day',    'ft/hr',     17,    42,  109, 0.00347222222222,  0.0,           null);
insert into cwms_unit_conversion values('in/day',    'm/hr',      17,    42,  110, 0.00105833333333,  0.0,           null);
insert into cwms_unit_conversion values('in/hr',     'cm/day',    17,    43,  108, 60.96,             0.0,           null);
insert into cwms_unit_conversion values('in/hr',     'ft/hr',     17,    43,  109, 0.0833333333333,   0.0,           null);
insert into cwms_unit_conversion values('in/hr',     'm/hr',      17,    43,  110, 0.0254,            0.0,           null);
insert into cwms_unit_conversion values('k$',        '$',         8,     103, 18,  1000.0,            0.0,           null);
insert into cwms_unit_conversion values('k$',        'k$',        8,     103, 103, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('kWh',       'J',         11,    24,  105, 3600000.0,         0.0,           null);
insert into cwms_unit_conversion values('kWh',       'MJ',        11,    24,  106, 3.6,               0.0,           null);
insert into cwms_unit_conversion values('kWh',       'cal',       11,    24,  107, 860420.650096,     0.0,           null);
insert into cwms_unit_conversion values('kaf',       'kdsf',      25,    82,  128, 0.504166666667,    0.0,           null);
insert into cwms_unit_conversion values('kaf',       'mcm',       25,    82,  129, 1.23348183755,     0.0,           null);
insert into cwms_unit_conversion values('kcfs',      'KAF/mon',   26,    75,  125, 60.3719008264,     0.0,           null);
insert into cwms_unit_conversion values('kcfs',      'kcms',      26,    75,  126, 0.028316846592,    0.0,           null);
insert into cwms_unit_conversion values('kcfs',      'mcm/mon',   26,    75,  127, 74.4676431676,     0.0,           null);
insert into cwms_unit_conversion values('kcms',      'KAF/mon',   26,    126, 125, 2132.01355703,     0.0,           null);
insert into cwms_unit_conversion values('kcms',      'cfs',       26,    126, 72,  35314.6667215,     0.0,           null);
insert into cwms_unit_conversion values('kcms',      'cms',       26,    126, 73,  1000.0,            0.0,           null);
insert into cwms_unit_conversion values('kcms',      'gpm',       26,    126, 74,  15850322.2371,     0.0,           null);
insert into cwms_unit_conversion values('kcms',      'kcfs',      26,    126, 75,  35.3146667215,     0.0,           null);
insert into cwms_unit_conversion values('kcms',      'kcms',      26,    126, 126, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('kcms',      'mcm/mon',   26,    126, 127, 2629.8,            0.0,           null);
insert into cwms_unit_conversion values('kcms',      'mgd',       26,    126, 76,  22824.4640214,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      '1000 m3',   25,    128, 77,  2446.57554555,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'ac-ft',     25,    128, 78,  1983.47107438,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'dsf',       25,    128, 79,  1000.0,            0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'ft3',       25,    128, 81,  86400000.0,        0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'gal',       25,    128, 80,  646316846.237,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'kaf',       25,    128, 82,  1.98347107438,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'kdsf',      25,    128, 128, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'kgal',      25,    128, 83,  646316.846237,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'km3',       25,    128, 84,  0.00244657554555,  0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'm3',        25,    128, 85,  2446575.54555,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'mcm',       25,    128, 129, 2.44657554555,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'mgal',      25,    128, 86,  646.316846237,     0.0,           null);
insert into cwms_unit_conversion values('kdsf',      'mile3',     25,    128, 87,  0.000586964688204, 0.0,           null);
insert into cwms_unit_conversion values('kg',        'g',         32,    116, 115, 1000.0,            0.0,           null);
insert into cwms_unit_conversion values('kg',        'kg',        32,    116, 116, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('kg',        'lbm',       32,    116, 117, 2.20462262185,     0.0,           null);
insert into cwms_unit_conversion values('kg',        'mg',        32,    116, 118, 1000000.0,         0.0,           null);
insert into cwms_unit_conversion values('kg',        'ton',       32,    116, 119, 0.00110231131092,  0.0,           null);
insert into cwms_unit_conversion values('kg',        'tonne',     32,    116, 120, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('kgal',      'kdsf',      25,    83,  128, 1.54722874055e-06, 0.0,           null);
insert into cwms_unit_conversion values('kgal',      'mcm',       25,    83,  129, 3.785412e-06,      0.0,           null);
insert into cwms_unit_conversion values('km2',       'cm2',       3,     7,   100, 10000000000.0,     0.0,           null);
insert into cwms_unit_conversion values('km3',       'kdsf',      25,    84,  128, 408.734568536,     0.0,           null);
insert into cwms_unit_conversion values('km3',       'mcm',       25,    84,  129, 1000.0,            0.0,           null);
insert into cwms_unit_conversion values('knot',      'cm/day',    17,    97,  108, 4444800.0,         0.0,           null);
insert into cwms_unit_conversion values('knot',      'ft/hr',     17,    97,  109, 6076.11548556,     0.0,           null);
insert into cwms_unit_conversion values('knot',      'm/hr',      17,    97,  110, 1852.0,            0.0,           null);
insert into cwms_unit_conversion values('kph',       'cm/day',    17,    44,  108, 2400000.0,         0.0,           null);
insert into cwms_unit_conversion values('kph',       'ft/hr',     17,    44,  109, 3280.83989501,     0.0,           null);
insert into cwms_unit_conversion values('kph',       'm/hr',      17,    44,  110, 1000.0,            0.0,           null);
insert into cwms_unit_conversion values('lbm',       'g',         32,    117, 115, 453.59237,         0.0,           null);
insert into cwms_unit_conversion values('lbm',       'kg',        32,    117, 116, 0.45359237,        0.0,           null);
insert into cwms_unit_conversion values('lbm',       'lbm',       32,    117, 117, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('lbm',       'mg',        32,    117, 118, 453592.37,         0.0,           null);
insert into cwms_unit_conversion values('lbm',       'ton',       32,    117, 119, 0.0005,            0.0,           null);
insert into cwms_unit_conversion values('lbm',       'tonne',     32,    117, 120, 0.00045359237,     0.0,           null);
insert into cwms_unit_conversion values('lbm/ft3',   'g/m3',      33,    112, 111, 16018.463374,      0.0,           null);
insert into cwms_unit_conversion values('lbm/ft3',   'lbm/ft3',   33,    112, 112, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'cm/day',    17,    110, 108, 2400.0,            0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'ft/hr',     17,    110, 109, 3.28083989501,     0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'ft/s',      17,    110, 41,  0.000911344415281, 0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'in/day',    17,    110, 42,  944.881889764,     0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'in/hr',     17,    110, 43,  39.3700787402,     0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'knot',      17,    110, 97,  0.000539956803456, 0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'kph',       17,    110, 44,  0.001,             0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'm/hr',      17,    110, 110, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'm/s',       17,    110, 45,  0.000277777777778, 0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'mm/day',    17,    110, 46,  24000.0,           0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'mm/hr',     17,    110, 47,  1000.0,            0.0,           null);
insert into cwms_unit_conversion values('m/hr',      'mph',       17,    110, 48,  0.000621371192237, 0.0,           null);
insert into cwms_unit_conversion values('m/s',       'cm/day',    17,    45,  108, 8640000.0,         0.0,           null);
insert into cwms_unit_conversion values('m/s',       'ft/hr',     17,    45,  109, 11811.023622,      0.0,           null);
insert into cwms_unit_conversion values('m/s',       'm/hr',      17,    45,  110, 3600.0,            0.0,           null);
insert into cwms_unit_conversion values('m2',        'cm2',       3,     8,   100, 10000.0,           0.0,           null);
insert into cwms_unit_conversion values('m3',        'kdsf',      25,    85,  128, 4.08734568536e-07, 0.0,           null);
insert into cwms_unit_conversion values('m3',        'mcm',       25,    85,  129, 1e-06,             0.0,           null);
insert into cwms_unit_conversion values('mcm',       '1000 m3',   25,    129, 77,  1000.0,            0.0,           null);
insert into cwms_unit_conversion values('mcm',       'ac-ft',     25,    129, 78,  810.71319379,      0.0,           null);
insert into cwms_unit_conversion values('mcm',       'dsf',       25,    129, 79,  408.734568536,     0.0,           null);
insert into cwms_unit_conversion values('mcm',       'ft3',       25,    129, 81,  35314666.7215,     0.0,           null);
insert into cwms_unit_conversion values('mcm',       'gal',       25,    129, 80,  264172037.284,     0.0,           null);
insert into cwms_unit_conversion values('mcm',       'kaf',       25,    129, 82,  0.81071319379,     0.0,           null);
insert into cwms_unit_conversion values('mcm',       'kdsf',      25,    129, 128, 0.408734568536,    0.0,           null);
insert into cwms_unit_conversion values('mcm',       'kgal',      25,    129, 83,  264172.037284,     0.0,           null);
insert into cwms_unit_conversion values('mcm',       'km3',       25,    129, 84,  0.001,             0.0,           null);
insert into cwms_unit_conversion values('mcm',       'm3',        25,    129, 85,  1000000.0,         0.0,           null);
insert into cwms_unit_conversion values('mcm',       'mcm',       25,    129, 129, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('mcm',       'mgal',      25,    129, 86,  264.172037284,     0.0,           null);
insert into cwms_unit_conversion values('mcm',       'mile3',     25,    129, 87,  0.000239912758579, 0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'KAF/mon',   26,    127, 125, 0.81071319379,     0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'cfs',       26,    127, 72,  13.4286511223,     0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'cms',       26,    127, 73,  0.380257053768,    0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'gpm',       26,    127, 74,  6027.19683514,     0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'kcfs',      26,    127, 75,  0.0134286511223,   0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'kcms',      26,    127, 126, 0.000380257053768, 0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'mcm/mon',   26,    127, 127, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('mcm/mon',   'mgd',       26,    127, 76,  8.6791634426,      0.0,           null);
insert into cwms_unit_conversion values('mg',        'g',         32,    118, 115, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('mg',        'kg',        32,    118, 116, 1e-06,             0.0,           null);
insert into cwms_unit_conversion values('mg',        'lbm',       32,    118, 117, 2.20462262185e-06, 0.0,           null);
insert into cwms_unit_conversion values('mg',        'mg',        32,    118, 118, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('mg',        'ton',       32,    118, 119, 1.10231131092e-09, 0.0,           null);
insert into cwms_unit_conversion values('mg',        'tonne',     32,    118, 120, 1e-09,             0.0,           null);
insert into cwms_unit_conversion values('mgal',      'kdsf',      25,    86,  128, 0.00154722874055,  0.0,           null);
insert into cwms_unit_conversion values('mgal',      'mcm',       25,    86,  129, 0.003785412,       0.0,           null);
insert into cwms_unit_conversion values('mgd',       'KAF/mon',   26,    76,  125, 0.0934091400803,   0.0,           null);
insert into cwms_unit_conversion values('mgd',       'kcms',      26,    76,  126, 4.38126388889e-05, 0.0,           null);
insert into cwms_unit_conversion values('mgd',       'mcm/mon',   26,    76,  127, 0.11521847775,     0.0,           null);
insert into cwms_unit_conversion values('mile2',     'cm2',       3,     9,   100, 25899881103.4,     0.0,           null);
insert into cwms_unit_conversion values('mile3',     'kdsf',      25,    87,  128, 1703.68,           0.0,           null);
insert into cwms_unit_conversion values('mile3',     'mcm',       25,    87,  129, 4168.18182544,     0.0,           null);
insert into cwms_unit_conversion values('min',       'day',       9,     20,  104, 0.000694444444444, 0.0,           null);
insert into cwms_unit_conversion values('mm/day',    'cm/day',    17,    46,  108, 0.1,               0.0,           null);
insert into cwms_unit_conversion values('mm/day',    'ft/hr',     17,    46,  109, 0.000136701662292, 0.0,           null);
insert into cwms_unit_conversion values('mm/day',    'm/hr',      17,    46,  110, 4.16666666667e-05, 0.0,           null);
insert into cwms_unit_conversion values('mm/hr',     'cm/day',    17,    47,  108, 2.4,               0.0,           null);
insert into cwms_unit_conversion values('mm/hr',     'ft/hr',     17,    47,  109, 0.00328083989501,  0.0,           null);
insert into cwms_unit_conversion values('mm/hr',     'm/hr',      17,    47,  110, 0.001,             0.0,           null);
insert into cwms_unit_conversion values('mph',       'cm/day',    17,    48,  108, 3862425.6,         0.0,           null);
insert into cwms_unit_conversion values('mph',       'ft/hr',     17,    48,  109, 5280.0,            0.0,           null);
insert into cwms_unit_conversion values('mph',       'm/hr',      17,    48,  110, 1609.344,          0.0,           null);
insert into cwms_unit_conversion values('sec',       'day',       9,     21,  104, 1.15740740741e-05, 0.0,           null);
insert into cwms_unit_conversion values('ton',       'g',         32,    119, 115, 907184.74,         0.0,           null);
insert into cwms_unit_conversion values('ton',       'kg',        32,    119, 116, 907.18474,         0.0,           null);
insert into cwms_unit_conversion values('ton',       'lbm',       32,    119, 117, 2000.0,            0.0,           null);
insert into cwms_unit_conversion values('ton',       'mg',        32,    119, 118, 907184740.0,       0.0,           null);
insert into cwms_unit_conversion values('ton',       'ton',       32,    119, 119, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('ton',       'tonne',     32,    119, 120, 0.90718474,        0.0,           null);
insert into cwms_unit_conversion values('ton/day',   'ton/day',   34,    113, 113, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('ton/day',   'tonne/day', 34,    113, 114, 0.90718474,        0.0,           null);
insert into cwms_unit_conversion values('tonne',     'g',         32,    120, 115, 1000000.0,         0.0,           null);
insert into cwms_unit_conversion values('tonne',     'kg',        32,    120, 116, 1000.0,            0.0,           null);
insert into cwms_unit_conversion values('tonne',     'lbm',       32,    120, 117, 2204.62262185,     0.0,           null);
insert into cwms_unit_conversion values('tonne',     'mg',        32,    120, 118, 1000000000.0,      0.0,           null);
insert into cwms_unit_conversion values('tonne',     'ton',       32,    120, 119, 1.10231131092,     0.0,           null);
insert into cwms_unit_conversion values('tonne',     'tonne',     32,    120, 120, 1.0,               0.0,           null);
insert into cwms_unit_conversion values('tonne/day', 'ton/day',   34,    114, 113, 1.10231131092,     0.0,           null);
insert into cwms_unit_conversion values('tonne/day', 'tonne/day', 34,    114, 114, 1.0,               0.0,           null);
-- new USGS Parameter Conversions
insert into at_usgs_parameter values (53,    10, 317, 6, 67,    1.0, 0.0);
insert into at_usgs_parameter values (53,    21, 316, 6, 68,    1.0, 0.0);
insert into at_usgs_parameter values (53,    45,  19, 1, 36,    1.0, 0.0);
insert into at_usgs_parameter values (53,    60,  14, 6, 72,    1.0, 0.0);
insert into at_usgs_parameter values (53,    61,  14, 6, 72,    1.0, 0.0);
insert into at_usgs_parameter values (53,    62,  10, 6, 35,    1.0, 0.0);
insert into at_usgs_parameter values (53,    65,  23, 6, 35,    1.0, 0.0);
insert into at_usgs_parameter values (53,    95,   6, 6, 16,    1.0, 0.0);
insert into at_usgs_parameter values (53,    96, 308, 6, 51,  0.001, 0.0);
insert into at_usgs_parameter values (53, 72036,  24, 6, 78, 1000.0, 0.0);
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
@@../cwms/views/av_loc_vert_datum
@@../cwms/views/av_text_filter
@@../cwms/views/av_tsv_elev
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
   cwms_ts.start_truncate_ts_msg_arch_job;
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

