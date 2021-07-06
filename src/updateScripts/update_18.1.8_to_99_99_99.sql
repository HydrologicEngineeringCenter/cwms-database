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
      select name
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
define logfile=update_&db_name._18_1_8_to_99_99_99.log
prompt log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
prompt ################################################################################
prompt VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./99_99_99/verify_db_version
prompt ################################################################################
prompt UPDATING AT_PHYSICAL_LOCATION Trigger
@./99_99_99/update_at_physical_location_triggers
prompt Insert Probability parameter
@./99_99_99/insertProbability
prompt Drop AT_SEC_DB_TABLE
@./99_99_99/dropAtSecDbiTable
prompt add yearly tables
@./99_99_99/add_yearly_tables

------------
-- TABLES --
------------

whenever sqlerror continue;
insert 
  into at_parameter
       (parameter_code,
        db_office_code,
	     base_parameter_code,
	     sub_parameter_id,
	     sub_parameter_desc)
values (48,
        53,
        48,
        null,
       'Probability');
whenever sqlerror exit;
--
comment on table  at_cwms_ts_spec                     is 'Defines time series based on CWMS requirements.  This table also serves as time series specification super type.';
comment on column at_cwms_ts_spec.ts_code             is 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
comment on column at_cwms_ts_spec.location_code       is 'Primary key of AT_PHYSICAL_LOCATION table.';
comment on column at_cwms_ts_spec.parameter_code      is 'Primary key of AT_PARAMETER table.  Must already exist in the AT_PARAMETER table.';
comment on column at_cwms_ts_spec.parameter_type_code is 'Primary key of CWMS_PARAMETER_TYPE table.  Must already exist in the CWMS_PARAMETER_TYPE table.';
comment on column at_cwms_ts_spec.interval_code       is 'Primary key of CWMS_INTERVAL table';
comment on column at_cwms_ts_spec.duration_code       is 'Primary key of CWMS_DURATION table';
comment on column at_cwms_ts_spec.version             is 'User-defined version string';
comment on column at_cwms_ts_spec.description         is 'Additional information.';
comment on column at_cwms_ts_spec.interval_utc_offset is 'Offset in minutes into regular interval for values. Interval is UTC for regular ts, but is local for LRTS';
comment on column at_cwms_ts_spec.interval_forward    is 'Number of minutes the value can be later than the expected interval+offset and still be considered on time';
comment on column at_cwms_ts_spec.interval_backward   is 'Number of minutes the value can be behind earlier than the expected interval+offset and still be considered on time';
COMMENT ON COLUMN CWMS_20.AT_CWMS_TS_SPEC.TIME_ZONE_CODE IS 'Local time zone for LRTS';
comment on column at_cwms_ts_spec.version_flag        is 'Default is NULL, indicating versioning is off. If set to "Y" then versioning is on';
comment on column at_cwms_ts_spec.migrate_ver_flag    is 'Default is NULL, indicating versioned data is not migrated to historic tables.  If set to "Y", versioned data is archived.';
comment on column at_cwms_ts_spec.active_flag         is 'T or F';
comment on column at_cwms_ts_spec.delete_date         is 'Is the date that this ts_id was marked for deletion.';
comment on column at_cwms_ts_spec.historic_flag       is 'T or F specifying whether this time series is part of the historic record';
--
alter table at_cwms_ts_id add time_zone_id varchar2(28);
comment on table  at_cwms_ts_id                       is 'Holds useful information about time series identfiers';
comment on column at_cwms_ts_id.db_office_code        is 'Primary key in CWMS_OFFICE for the office that owns the time series';
comment on column at_cwms_ts_id.base_location_code    is 'Primary key in AT_BASE_LOCATION for the base location of the time series';
comment on column at_cwms_ts_id.base_loc_active_flag  is 'A flag (''T''/''F'') that specifies whether the base location is marked as active';
comment on column at_cwms_ts_id.location_code         is 'Primary key in AT_PHYSICAL_LOCATION for the location of the time series';
comment on column at_cwms_ts_id.loc_active_flag       is 'A flag (''T''/''F'') that specifies whether the location is marked as active';
comment on column at_cwms_ts_id.parameter_code        is 'Primary key in AT_PARAMETER for the parameter of the time series';
comment on column at_cwms_ts_id.ts_code               is 'Primary key in AT_CWMS_TS_SPEC for the time series ID';
comment on column at_cwms_ts_id.ts_active_flag        is 'A flag (''T''/''F'') that specifies whether the time series is marked as active';
comment on column at_cwms_ts_id.net_ts_active_flag    is 'A flag (''T''/''F'') that specifies whether the time series is inactivated by any other of the active flags';
comment on column at_cwms_ts_id.db_office_id          is 'The identifier of the office that owns the time series';
comment on column at_cwms_ts_id.cwms_ts_id            is 'The identifier of the time series';
comment on column at_cwms_ts_id.unit_id               is 'The identifier of the database storage unit for the time series';
comment on column at_cwms_ts_id.abstract_param_id     is 'The identifier of the abstract parameter of the time series';
comment on column at_cwms_ts_id.base_location_id      is 'The identifier of the base location of the time series';
comment on column at_cwms_ts_id.sub_location_id       is 'The identifier of the sub-location of the time series';
comment on column at_cwms_ts_id.location_id           is 'The identifier of the complete location of the time series';
comment on column at_cwms_ts_id.base_parameter_id     is 'The identifier of the base parameter of the time series';
comment on column at_cwms_ts_id.sub_parameter_id      is 'The identifier of the sub-parameter of the time series';
comment on column at_cwms_ts_id.parameter_id          is 'The identifier of the complete parameter of the time series';
comment on column at_cwms_ts_id.parameter_type_id     is 'The identifier of the parameter type of the time series';
comment on column at_cwms_ts_id.interval_id           is 'The identifier of the recurrence interval of the time series';
comment on column at_cwms_ts_id.duration_id           is 'The identifier of the duration of the time series';
comment on column at_cwms_ts_id.version_id            is 'The identifier of the version of the time series';
comment on column at_cwms_ts_id.interval              is 'The interval of the time series in minutes';
comment on column at_cwms_ts_id.interval_utc_offset   is 'The offset in minutes into the interval for time series values';
comment on column at_cwms_ts_id.version_flag          is 'A flag (''T''/''F'') that specifies whether the time series is versioned';
comment on column at_cwms_ts_id.historic_flag         is 'A flag (''T''/''F'') that specifies whether the time series is part of the historical record';
comment on column at_cwms_ts_id.time_zone_id          is 'The time zone of the location of the time series';

-----------
-- VIEWS --
-----------
delete from at_clob where id = '/VIEWDOCS/ZAV_CWMS_TS_ID';
@../cwms/views/zav_cwms_ts_id
delete from at_clob where id = '/VIEWDOCS/AV_CWMS_TS_ID';
@../cwms/views/av_cwms_ts_id
delete from at_clob where id = '/VIEWDOCS/AV_CWMS_TS_ID2';
@../cwms/views/av_cwms_ts_id2
delete from at_clob where id = '/VIEWDOCS/AV_LOC';
@../cwms/views/av_loc
delete from at_clob where id = '/VIEWDOCS/AV_POOL';
@../cwms/views/av_pool

-------------------
-- PACKAGE SPECS --
-------------------
@../cwms/cwms_cat_pkg
@../cwms/cwms_loc_pkg
@../cwms/cwms_msg_pkg
@../cwms/cwms_pool_pkg
@../cwms/cwms_sec_pkg
@../cwms/cwms_ts_pkg
@../cwms/cwms_usgs_pkg
@../cwms/cwms_util_pkg
@../cwms_dba/cwms_user_admin_pkg

----------------
-- TYPE SPECS --
----------------
drop type nested_ts_type force;
@../cwms/types/nested_ts_type
----------------
-- TYPE BODY --
----------------
@../cwms/types/stream_rating_t-body
--------------------
-- PACKAGE BODIES --
--------------------
prompt update package bodies
@../cwms/cwms_cat_pkg_body
@../cwms/cwms_env_pkg_body
@../cwms/cwms_loc_pkg_body
@../cwms/cwms_msg_pkg_body
@../cwms/cwms_rating_pkg_body
@../cwms/cwms_sec_pkg_body
@../cwms/cwms_ts_pkg_body
@../cwms/cwms_ts_id_pkg_body
@../cwms/cwms_util_pkg_body
@../cwms_dba/cwms_user_admin_pkg_body

-- Missing grants
prompt Apply missing grants
grant select on av_ts_extents_utc to cwms_user;
grant execute on cwms_ts_profile to cwms_user;
grant execute on shef_spec_type to cwms_user;
grant execute on nested_ts_type to cwms_user;

-- Drop application triggers for read only users 
BEGIN
    FOR c
        IN (SELECT *
              FROM dba_objects
             WHERE     owner = 'CWMS_20'
                   AND object_type = 'TRIGGER'
                   AND object_name IN
                           ('ST_APPLICATION_LOGIN', 'ST_APPLICATION_SESSION'))
    LOOP
        DBMS_OUTPUT.PUT_LINE ('drop trigger ' || c.object_name);
        EXECUTE IMMEDIATE 'drop trigger ' || c.object_name;
    END LOOP;
END;
/

prompt ################################################################################
prompt INVALID OBJECTS...
select systimestamp from dual;
set pagesize 100
select owner||'.'||substr(object_name, 1, 30) as invalid_object,
       object_type
  from all_objects
 where status = 'INVALID'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by 1, 2;
prompt ################################################################################
prompt RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects
prompt UPDATING OBJECTS
@./99_99_99/update_at_cwms_ts_spec
prompt recreate db policies
@../cwms/create_service_user_policy.sql
prompt create av_view
exec cwms_util.create_view
prompt create read only triggers
@../cwms/create_sec_triggers
prompt create tsv count triggers
@../cwms/at_tsv_count_trig
prompt create tsv trigger for ddf flag 
@../cwms/at_dd_flag_trig.sql
prompt RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects
prompt create procedure to move data
@./util/move_data_from_inf_to_yearly
prompt Move INF data to yearly tables
begin move_data_from_inf_to_yearly; end; 
/
prompt drop move data procedure
drop procedure move_data_from_inf_to_yearly;

promp ################################################################################
prompt REMAINING INVALID OBJECTS...
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
prompt 'RESTORE CCP PRIVILEGES'
select systimestamp from dual;
whenever sqlerror continue;
declare
  l_count NUMBER;
begin
   select count(*) into l_count from dba_users where username='CCP';
   if(l_count>0)
   then
     for rec in (select object_name from user_objects where object_type in ('PACKAGE', 'TYPE')) loop
        execute immediate 'grant execute on '||rec.object_name||' to ccp';
     end loop;
   end if;
end;
/
whenever sqlerror exit;
prompt ################################################################################
prompt ################################################################################
prompt UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./99_99_99/update_db_change_log
select substr(version, 1, 10) as version,
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date,
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;
prompt ################################################################################
prompt UPDATE COMPLETE
select systimestamp from dual;
exit

