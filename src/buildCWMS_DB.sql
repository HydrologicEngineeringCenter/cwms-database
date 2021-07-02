set echo off
set time on
set define on
set concat on
set linesize 1024
whenever sqlerror exit -1
whenever oserror exit -1

--
-- prompt for info
--
@@py_prompt

spool buildCWMS_DB.log
--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
--ALTER SYSTEM ENABLE RESTRICTED SESSION;
--
--
select sysdate from dual;
set serveroutput on
begin dbms_output.enable; end;
/
set echo &echo_state
--
-- create user roles and users
--
@@cwms/User-Roles/cwms_user_profile
@@cwms/User-Roles/cwms_user_roles
@@cwms/User-Roles/cwms_users
@@cwms/User-Roles/cwms_dba_user

--
@@cwms_dba/cwms_user_admin_pkg
@@cwms_dba/cwms_user_admin_pkg_body
--
set define on
grant execute on  cwms_dba.cwms_user_admin to &cwms_schema;
grant execute on  dbms_crypto to cwms_user;

--
-- switch to cwms_schema
--
alter session set current_schema = &cwms_schema;

--
-- structure that can be built without the CWMS API,
-- even if it results in invalid objects
--
@@py_BuildCwms
@@cwms/cwms_types
@@cwms/at_schema
@@cwms/at_schema_crrel
@@cwms/at_schema_shef
@@cwms/at_schema_alarm
@@cwms/at_schema_screening
@@cwms/at_schema_dss_xchg
@@cwms/at_schema_msg
@@cwms/at_schema_mv
@@cwms/at_schema_av
@@cwms/at_schema_rating
@@cwms/at_schema_tsv
@@cwms/at_schema_tr
@@cwms/at_schema_sec_2
@@cwms/at_schema_sec
@@cwms/at_schema_apex_debug
@@cwms/at_schema_cma

--
--  Load data into cwms tables...
--
@@data/unit_alias_data
@@data/cwms_shef_pe_codes


--
-- CWMS API
--
@@cwms/api
-- Context needs to be created after the package is created
@@cwms/at_schema_env

--
-- structure that can't be built without the CWMS API,
--
@@cwms/at_schema_2
whenever sqlerror exit -1
@@cwms/at_schema_tsv_dqu
-- views that depend on av_tsv and av_tsv_dqu
@@cwms/views/av_ts_profile_inst_tsv
@@cwms/views/av_ts_profile_inst_tsv2
@@cwms/views/av_ts_profile_inst_elev
@@cwms/views/av_ts_profile_inst_sp

--
-- Create dbi and pd user accounts...
---
set define on
@@py_ErocUsers

--
-- Create public synonyms and cwms_user roles
@@cwms/at_schema_public_interface.sql
-- Filter for streaming data
@@cwms/mv_ts_code_filter

ALTER SESSION SET current_schema = sys;

--
-- compile all invalid objects
--
SET define on
alter materialized view "&cwms_schema"."MV_SEC_TS_PRIVILEGES" compile
/

set echo off
set linesize 132
set pagesize 1000
prompt Invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Recompiling all invalid objects...
begin
   $if dbms_db_version.version < 12 $then
      execute immediate 'alter session set plscope_settings=''IDENTIFIERS:ALL''';
   $end
   dbms_utility.compile_schema('&cwms_schema');
end;
/

prompt Remaining invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Database errors...
  select *
   from dba_errors
  where owner = '&cwms_schema'
  order by 1,2,3,4;

whenever sqlerror exit -1
declare
   obj_count integer;
begin
   select count(*)
     into obj_count
     from dba_objects
    where owner = '&cwms_schema'
      and status = 'INVALID';
   if obj_count > 0 then
      dbms_output.put_line('' || obj_count || ' objects are still invalid.');
      raise_application_error(-20999, 'Some objects are still invalid.');
   else
      dbms_output.put_line('All invalid objects successfully compiled.');
   end if;
end;
/
-- update CWMS_DB_CHANGE_LOG
alter session set current_schema = &cwms_schema;
whenever sqlerror continue
select cwms_util.get_db_name from dual;
whenever sqlerror exit -1
begin
   update cwms_db_change_log
      set database_id = cwms_util.get_db_name
    where database_id = 'LOCAL';
end;
/
alter session set current_schema = sys
-- Create CWMS_DBXC_ROLE

@@cwms/User-Roles/cwms_dbx_role_et_user

set echo off
--
-- log on as the CWMS schema user and start queues and jobs
--
--ALTER SYSTEM DISABLE RESTRICTED SESSION;
--EXEC DBMS_LOCK.SLEEP(1);

set define on
prompt Connecting as &cwms_schema
connect &cwms_schema/&cwms_passwd@&inst
set serveroutput on
prompt Connected as &cwms_schema

@@cwms/views/mv_location_level_curval
@@cwms/tables/at_clob_index.sql
@@cwms/tables/indexes_for_spatial_data.sql
--------------------------------------------------
-- populate CWMS_IDENTIFIERS table on Oracle 11 --
--------------------------------------------------
prompt Popluating CWMS_IDENTIFIERS table
begin
   $if dbms_db_version.version < 12 $then
      begin execute immediate 'drop view cwms_v_identifiers'; exception when others then null; end;
      begin execute immediate 'drop table cwms_identifiers'; exception when others then null; end;
      execute immediate 'create table cwms_identifiers as (select object_name,
                                                                  name,
                                                                  line
                                                             from dba_identifiers
                                                            where owner = ''&cwms_schema''
                                                              and type in (''PROCEDURE'', ''FUNCTION'')
                                                              and usage = ''DEFINITION''
                                                              and object_type = ''PACKAGE BODY''
                                                              and usage_context_id = 1
                                                          )';
      execute immediate 'alter table cwms_identifiers add constraint cwms_identifiers_pk primary key (object_name, name, line) using index';
      execute immediate 'create or replace force view av_cwms_identifiers as select * from cwms_identifiers';
      execute immediate 'grant select on av_cwms_identifiers to cwms_user';
      execute immediate 'create or replace public synonym cwms_v_identifiers for av_cwms_identifiers';
   $else
      null;
   $end
end;
/

--------------------------------
-- populate base data via API --
--------------------------------
begin
   cwms_text.store_std_text('A', 'NO RECORD');
   cwms_text.store_std_text('B', 'CHANNEL DRY');
   cwms_text.store_std_text('C', 'POOL STAGE');
   cwms_text.store_std_text('D', 'AFFECTED BY WIND');
   cwms_text.store_std_text('E', 'ESTIMATED');
   cwms_text.store_std_text('F', 'NOT AT STATED TIME');
   cwms_text.store_std_text('G', 'GATES CLOSED');
   cwms_text.store_std_text('H', 'PEAK STAGE');
   cwms_text.store_std_text('I', 'ICE/SHORE ICE');
   cwms_text.store_std_text('J', 'INTAKES OUT OF WATER');
   cwms_text.store_std_text('K', 'FLOAT FROZEN/FLOATING ICE');
   cwms_text.store_std_text('L', 'GAGE FROZEN');
   cwms_text.store_std_text('M', 'MALFUNCTION');
   cwms_text.store_std_text('N', 'MEAN STAGE FOR THE DAY');
   cwms_text.store_std_text('O', 'OBSERVERS READING');
   cwms_text.store_std_text('P', 'INTERPOLATED');
   cwms_text.store_std_text('Q', 'DISCHARGE MISSING');
   cwms_text.store_std_text('R', 'HIGH WATER, NO ACCESS');
end;
/

begin
   cwms_text.store_text_filter(
      p_text_filter_id => 'LOCATION',
      p_description    => 'Matches valid CWMS locations',
      p_text_filter    => str_tab_t('in:^[^.-]{0,15}[^. -](-[^. -][^.]{0,31})?$', 'ex:^\W', 'ex:\W$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'BASE_PARAMETER',
      p_description    => 'Matches valid CWMS base parameters',
      p_text_filter    => str_tab_t('in:^(%|Area|Code|Con[cd]|Count|Currency|Depth|Dir|Dist|Elev|Energy|Evap(Rate)?|Fish|Flow|Frost|Irrad|Opening|pH|Power|Precip|Pres|Rad|Ratio|Speed|SpinRate|Stage|Stor|Temp|Thick|Timing|Travel|Turb[FJN]?|Volt)$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'PARAMETER',
      p_description    => 'Matches valid CWMS parameters',
      p_text_filter    => str_tab_t('in:^(%|Area|Code|Con[cd]|Count|Currency|Depth|Dir|Dist|Elev|Energy|Evap(Rate)?|Fish|Flow|Frost|Irrad|Opening|pH|Power|Precip|Pres|Rad|Ratio|Speed|SpinRate|Stage|Stor|Temp|Thick|Timing|Travel|Turb[FJN]?|Volt)(-[^.]{1,32})?$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'PARAMETER_TYPE',
      p_description    => 'Matches valid CWMS parameter types',
      p_text_filter    => str_tab_t('in:^(Total|Max|Min|Const|Ave|Inst)$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'INTERVAL',
      p_description    => 'Matches valid CWMS intervals',
      p_text_filter    => str_tab_t('in:^(0|~?(1(Minute|Hour|Day|Week|Month|Year|Decade)|([234568]|1[025]|[23]0)Minutes|([23468]|12)Hours|[23456]Days))$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'DURATION',
      p_description    => 'Matches valid CWMS durations',
      p_text_filter    => str_tab_t('in:^(0|(1(Minute|Hour|Day|Week|Month|Year|Decade)|([234568]|1[025]|[23]0)Minutes|([23468]|12)Hours|[23456]Days)(BOP)?)$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');
end;
/
commit;
--prompt insert CWMS version entry
--@cwms_version
--------------------------------------
-- create and start queues and jobs --
--------------------------------------
prompt Creating and starting queues...
@py_Queues
begin
   cwms_msg.create_av_queue_subscr_msgs; -- view must be created after creating queues
end;
/
prompt Starting jobs...
begin
   cwms_msg.start_trim_log_job;
   cwms_msg.start_remove_subscribers_job;
   cwms_ts.start_trim_ts_deleted_job;
   cwms_sec.start_refresh_mv_sec_privs_job;
   cwms_sec.start_clean_session_job;
   cwms_shef.start_update_shef_spec_map_job;
   cwms_ts.start_update_ts_extents_job;
   cwms_ts.start_immediate_upd_tsx_job;
   cwms_ts.start_truncate_ts_msg_arch_job;
end;
/
set define on
@@cwms/create_sec_triggers
@@cwms/create_service_user_policy
@@cwms/at_tsv_count_trig
@@cwms/at_dd_flag_trig
-------------------------------------------------
-- rebuild any disabled function-based indexes --
-------------------------------------------------
declare
   index_ddl clob;
begin
   for rec in (select index_name from all_indexes where owner = '&cwms_schema' and funcidx_status = 'DISABLED') loop
      index_ddl := dbms_metadata.get_ddl('INDEX', rec.index_name, '&cwms_schema');
      execute immediate 'drop index &cwms_schema..'||rec.index_name;
      execute immediate index_ddl;
   end loop;
end;
/
--
-- all done
--
exit 0

