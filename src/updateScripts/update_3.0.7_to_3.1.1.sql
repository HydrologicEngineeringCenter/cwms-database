-------------------
-- general setup --
-------------------
whenever sqlerror exit;
set define on
set verify off
set serveroutput on
define cwms_schema = CWMS_20
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
@@./311_verify_db_version
prompt ################################################################################
prompt 'MODIFY CWMS_DB_CHANGE_LOG TABLE'
select systimestamp from dual;
@@./311_modify_db_change_log
prompt ################################################################################
prompt 'REMOVING TRIGGER AT_STREAM_REACH_T01'
select systimestamp from dual;
@@./311_remove_at_stream_reach_t01
prompt ################################################################################
prompt DELETING CST, PST FROM CWMS_TIME_ZONE AND REBUILDING MV_TIME_ZONE
select systimestamp from dual;
@@./311_delete_time_zones
prompt ################################################################################
prompt 'UPDATING REGI LOOKUP TABLES'
select systimestamp from dual;
@@./311_update_embankment_protection_types
@@./311_update_embankment_structure_types
@@./311_update_gate_change_computations
@@./311_update_gate_release_reasons
@@./311_update_physical_transfer_types
@@./311_update_turbine_computation_codes
@@./311_update_turbine_setting_reasons
@@./311_update_ws_contract_types
prompt ################################################################################
prompt 'ADDING NEW SCHEDULER MONITORING OBJECTS'
@@../cwms/tables/cwms_auth_sched_entrires
@@../cwms/tables/cwms_unauth_sched_entrires
@@../cwms/views/av_auth_sched_entrires
@@../cwms/views/av_unauth_sched_entrires
@@../cwms/cwms_scheduler_auth_pkg
@@../cwms/cwms_scheduler_auth_pkg_body
prompt ################################################################################
prompt 'UPDATING PACKAGE SPECIFICATIONS'
select systimestamp from dual;
@@../cwms/cwms_util_pkg
prompt ################################################################################
prompt 'UPDATING PACKAGE BODDIES'
select systimestamp from dual;
@@../cwms/cwms_embank_pkg_body
@@../cwms/cwms_outlet_pkg_body
@@../cwms/cwms_turbine_pkg_body
@@../cwms/cwms_util_pkg_body
@@../cwms/cwms_water_supply_pkg_body
@@../cwms/cwms_xchg_pkg_body
prompt ################################################################################
prompt 'RECOMPILING ALL INVALID OBJECTS...'
select systimestamp from dual;
@@./list_invalid_objects &cwms_schema 'continue' -- just list invalid objects
@@./recompile_schema     &cwms_schema 2          -- compiles at most 2 times
@@./list_invalid_objects &cwms_schema 'abort'    -- list invalid objects and abort if any
prompt ################################################################################
prompt 'UPDATING DB_CHANGE_LOG'
select systimestamp from dual;
@@./311_update_db_change_log
select substr(version, 1, 10) as version, 
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date, 
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;
prompt ################################################################################
prompt 'UPDATE COMPLETE'
select systimestamp from dual;
exit

