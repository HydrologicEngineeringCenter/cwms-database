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
-- log on as builduser
--
connect &builduser/&builduser_passwd@&inst 
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
@@cwms/User-Roles/cwms_users
@@cwms/User-Roles/cwms_dba_user

-- Make &cwms_schema user owner of CWMS_USER role so that it can be granted to other users
connect &cwms_schema/&cwms_passwd@&inst
@@cwms/User-Roles/cwms_user_role_create
-- Add system grants to CWMS_USER as build user 
connect &builduser/&builduser_passwd@&inst 
@@cwms/User-Roles/cwms_user_role_grant_system

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
exec dbms_output.put_line('Creating initial types.');
@@cwms/column_types/file_t
@@cwms/column_types/text_file_t
@@cwms/column_types/blob_file_t
exec dbms_output.put_line('Creating tables.');
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
@@cwms/at_schema_cma
@@cwms/tables/at_api_keys

--
--  Load data into cwms tables...
--
@@data/unit_alias_data
@@data/cwms_shef_pe_codes


--
-- CWMS API
--
exec dbms_output.put_line('Creating Java stored routines.');
create or replace and compile java source named "random_uuid" as
public class RandomUUID {
    public static String create() {
        return java.util.UUID.randomUUID().toString();
    }
}
/
create or replace function random_uuid
return varchar2
as language java
name 'RandomUUID.create() return java.lang.String';
/
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
@@cwms/views/av_active_api_keys

--
-- Create pd/test user accounts...
---
set define on
@@py_admin_ErocUsers


--
-- Create public synonyms and cwms_user roles
@@cwms/at_schema_public_interface.sql
show errors;
-- Filter for streaming data
@@cwms/mv_ts_code_filter

ALTER SESSION SET current_schema = &builduser;

--
-- compile all invalid objects
--
SET define on

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
   execute immediate 'alter session set plscope_settings=''IDENTIFIERS:ALL''';
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
@@cwms/User-Roles/web_user_role_grants.sql
alter session set current_schema = &builduser

-- create CWMS service user
begin execute immediate 'create user ' || cwms_sec.cac_service_user || ' PROFILE CWMS_PROF IDENTIFIED BY "FEDCBA9876543210" '; end; 
/
-- Replace connect to role with create session/set container for RDS compatibility
begin execute immediate 'grant create session to ' || cwms_sec.cac_service_user; end; 
/
begin execute immediate 'grant set container to ' || cwms_sec.cac_service_user; end; 
/

set echo off
--
-- log on as the CWMS schema user and start queues and jobs
--
--ALTER SYSTEM DISABLE RESTRICTED SESSION;
--EXEC DBMS_LOCK.SLEEP(1);

set define on
prompt Connecting as &cwms_schema
connect &cwms_schema/&cwms_passwd@&inst
begin execute immediate 'grant cwms_user to ' || cwms_sec.cac_service_user; end; 
/
set serveroutput on
prompt Connected as &cwms_schema
grant execute on cwms_util to cwms_dba;
alter session set ddl_lock_timeout = 100;
--
-- Create pd/test user accounts...
---
set define on
@@py_ErocUsers
-- call this again to create logoff triggers for newly-added users
@@cwms/tables/at_tsv_count

@@cwms/views/mv_location_level_curval
-- replace previous dummy view
@@cwms/views/av_cwms_ts_id
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
   cwms_sec.start_clean_session_job;
   cwms_shef.start_update_shef_spec_map_job;
   cwms_ts.start_update_ts_extents_job;
   cwms_ts.start_immediate_upd_tsx_job;
   cwms_ts.start_truncate_ts_msg_arch_job;
end;
/
@@cwms/create_sec_triggers
@@cwms/create_user_policies
@@cwms/at_dd_flag_trig
prompt Recompiling all invalid objects...
begin
   execute immediate 'alter session set plscope_settings=''IDENTIFIERS:ALL''';
   dbms_utility.compile_schema('&cwms_schema');
end;
/
prompt Rebuilding all disabled function-based indexes...
begin
   for rec in (select index_name from all_indexes where owner = '&cwms_schema' and funcidx_status = 'DISABLED') loop
      execute immediate 'alter index &cwms_schema..'||rec.index_name||' rebuild';
   end loop;
end;
/

----------------------------------------------------------------------------------------------------------------------------
-- I hate having this here, but for some reason this SAYS it works when in AT_SCHEMA, but the constraint is missing after --
-- the build finishes, so do it here (ugh!!!) Also, I had to wrap in a PL/SQL block to keep it from forcing an exit 255!  --
----------------------------------------------------------------------------------------------------------------------------
prompt ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK6 FOREIGN KEY (NATION_CODE) REFERENCES CWMS_NATION_SP (FIPS_CNTRY);
begin
   execute immediate ('ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK6 FOREIGN KEY (NATION_CODE) REFERENCES CWMS_NATION_SP (FIPS_CNTRY)');
exception
   when others then raise;
end;
/

--
-- all done
--
exit 0
