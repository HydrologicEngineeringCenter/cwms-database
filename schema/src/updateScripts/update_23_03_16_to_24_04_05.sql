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
define logfile=update_&db_name._23_03_16_to_24_04_05.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./24_04_05/verify_db_version


PROMPT ################################################################################
PROMPT REMOVING REMOVE_DEAD_SUBSCRIBERS JOB
select systimestamp from dual;
begin
    dbms_scheduler.drop_job(job_name => '&cwms_schema..remove_dead_subscribers_job',
                            defer => false,
                            force => true);
exception
   when others then
      dbms_output.put_line(sqlerrm);
end;
/

PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql;



PROMPT ################################################################################
PROMPT ALTERING TABLES
@./24_04_05/at_cwms_ts_id_table_Triggers

-- remove RESULT_CACHE (MODE DEFAULT) from at_data_stream_properties
-- create table at_data_stream_properties_tmp as select * from at_data_stream_properties;
-- drop table at_data_stream_properties;
-- @../tables/at_data_stream_properties
-- insert into at_data_stream_properties select * from at_data_stream_properties_tmp;
-- drop table at_data_stream_properties_tmp;

-- remove RESULT_CACHE (MODE DEFAULT) from at_shef_decode_specs
-- create table at_shef_decode_specs_tmp as select * from at_shef_decode_specs;
-- drop table at_shef_decode_specs;
-- @../tables/at_shef_decode_specs
-- insert into at_shef_decode_specs select * from at_shef_decode_specs_tmp;
-- drop table at_shef_decode_specs_tmp;

-- update at_ts_extents table
alter table at_ts_extents add has_non_zero_quality char(1);
alter table at_ts_extents add constraint at_ts_extents_ck1 check (nvl(has_non_zero_quality, 'F') in ('T', 'F'));
comment on column at_ts_extents.has_non_zero_quality  is 'Specifies whether the ENTIRE time series has ANY quality_code other than zero)';

-- create at_tsv_count table
@./24_04_05/at_tsv_count

--update CWMS_STATE to add nation_code
@./24_04_05/cwms_state

@./24_04_05/CWMS_COUNTY

insert into CWMS_USGS_FLOW_ADJ(ADJ_ID, ADJ_NAME, DESCRIPTION) values('NONE','Unknown','Transfer from null code');

drop table CWMS_NATION
-- update cwms_nation_sp table
alter table cwms_nation_sp alter column FIPS_CNTRY  not null;
ALTER TABLE CWMS_NATION_SP ADD CONSTRAINT CWMS_NATION_SP_U2 UNIQUE (FIPS_CNTRY) ENABLE VALIDATE;

alter table AT_PHYSICAL_LOCATION drop constraint AT_PHYSICAL_LOCATION_FK6;
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK6 FOREIGN KEY (NATION_CODE) REFERENCES CWMS_NATION_SP (FIPS_CNTRY);

@./24_04_05/at_cwms_ts_spec_updates

-- create run_stats table
create global temporary table run_stats(
   runid varchar2(15), 
   name  varchar2(80), 
   value number(*,0)
) on commit preserve rows;
commit;

PROMPT ################################################################################
PROMPT ADDING USGS TS GROUP CATEGORY
@./24_04_05/USGSDataAquisition


PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE SPECIFICATIONS
select systimestamp from dual;

drop type location_level_t force;
drop type location_obj_t force;
drop type location_ref_t force;
drop type rating_spec_t force;
drop type rating_t force;
drop type rating_template_t force;
drop type streamflow_meas_t force;
drop type vdatum_rating_t force;
drop type vdatum_stream_rating_t force;
drop type zlocation_level_t force;
@../cwms/types/location_level_t
@../cwms/types/location_obj_t
@../cwms/types/location_ref_t
@../cwms/types/rating_spec_t
@../cwms/types/rating_t
@../cwms/types/rating_template_t
@../cwms/types/streamflow_meas_t
@../cwms/types/vdatum_rating_t
@../cwms/types/vdatum_stream_rating_t
@../cwms/types/zlocation_level_t
@../cwms/types/date_range_t
@../cwms/types/dsinterval_tab_t
@../cwms/types/timestamp_tab_t
@../cwms/types/tstz_tab_t

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE BODIES
@../cwms/types/date_range_t-body
@../cwms/types/location_level_t-body
@../cwms/types/location_obj_t-body
@../cwms/types/location_ref_t-body
@../cwms/types/rating_spec_t-body
@../cwms/types/rating_t-body
@../cwms/types/rating_template_t-body
@../cwms/types/streamflow_meas_t-body
@../cwms/types/vdatum_rating_t-body
@../cwms/types/vdatum_stream_rating_t-body
@../cwms/types/zlocation_level_t-body

drop trigger at_tsv_count_trig

PROMPT ################################################################################
PROMPT CREATING AND ALTERING VIEWS
select systimestamp from dual;
delete from at_clob where id = '/VIEWDOCS/AV_ACTIVE_FLAG';
delete from at_clob where id = '/VIEWDOCS/AV_CWMS_TS_ID';
delete from at_clob where id = '/VIEWDOCS/AV_CWMS_TS_ID2';
delete from at_clob where id = '/VIEWDOCS/AV_FORECAST_EX';
delete from at_clob where id = '/VIEWDOCS/AV_FORECAST';
delete from at_clob where id = '/VIEWDOCS/AV_LOC_LVL_TS_MAP';
delete from at_clob where id = '/VIEWDOCS/AV_LOC';
delete from at_clob where id = '/VIEWDOCS/AV_LOC2';
delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL';
delete from at_clob where id = '/VIEWDOCS/AV_NATION';
delete from at_clob where id = '/VIEWDOCS/AV_SCREENED_TS_IDS';
delete from at_clob where id = '/VIEWDOCS/AV_SCREENING_ASSIGNMENTS';
delete from at_clob where id = '/VIEWDOCS/AV_SHEF_DECODE_SPEC';
delete from at_clob where id = '/VIEWDOCS/AV_TS_EXTENTS_LOCAL';
delete from at_clob where id = '/VIEWDOCS/AV_TS_EXTENTS_UTC';
delete from at_clob where id = '/VIEWDOCS/AV_TS_MSG_ARCHIVE';
delete from at_clob where id = '/VIEWDOCS/AV_TS_TEXT';
@../cwms/views/av_active_flag
@../cwms/views/av_cwms_ts_id
@../cwms/views/av_cwms_ts_id2
@../cwms/views/av_deleted_ts_id     
@../cwms/views/av_forecast_ex
@../cwms/views/av_forecast
@../cwms/views/av_loc_lvl_ts_map
@../cwms/views/av_loc
@../cwms/views/av_loc2
@../cwms/views/av_location_level
@../cwms/views/av_nation
@../cwms/views/av_screened_ts_ids
@../cwms/views/av_screening_assignments
@../cwms/views/av_shef_decode_spec
@../cwms/views/av_ts_extents_local
@../cwms/views/av_ts_extents_utc
@../cwms/views/av_ts_msg_archive
@../cwms/views/av_ts_text
@../cwms/views/stats 

PROMPT ################################################################################
PROMPT CREATING AND ALTERING PACKAGE BODIES
select systimestamp from dual;
@../cwms/cwms_pool_pkg_body.sql
@../cwms/cwms_ts_pkg_body.sql
@../cwms/cwms_cache_pkg_body.sql
@../cwms/cwms_cat_pkg_body.sql
@../cwms/cwms_data_dissem_pkg_body.sql
@../cwms/cwms_env_pkg_body.sql
@../cwms/cwms_err_pkg_body.sql
@../cwms/cwms_forecast_pkg_body.sql
@../cwms/cwms_level_pkg_body.sql
@../cwms/cwms_loc_pkg_body.sql
@../cwms/cwms_lock_pkg_body.sql
@../cwms/cwms_project_pkg_body.sql
@../cwms/cwms_rating_pkg_body.sql
@../cwms/cwms_shef_pkg_body.sql
@../cwms/cwms_text_pkg_body.sql
@../cwms/cwms_ts_pkg_body.sql
@../cwms/cwms_ts_profile_pkg_body.sql
@../cwms/cwms_tsv_pkg_body.sql
@../cwms/cwms_util_pkg_body.sql
@../cwms/cwms_vt_pkg_body.sql
@../cwms/cwms_xchg_pkg_body.sql
@../cwms/cwms_msg_pkg_body.sql
@../cwms/runstats_pkg_body.sql

PROMPT ################################################################################
PROMPT CREATING AND ALTERING PACKAGE SPECIFICATIONS
select systimestamp from dual;
@../cwms/cwms_cache_pkg.sql
@../cwms/cwms_ts_pkg_body.sql
@../cwms/cwms_cat_pkg.sql
@../cwms/cwms_env_pkg.sql
@../cwms/cwms_forecast_pkg.sql
@../cwms/cwms_level_pkg.sql
@../cwms/cwms_loc_pkg.sql
@../cwms/cwms_rating_pkg.sql
@../cwms/cwms_schema_pkg.sql
@../cwms/cwms_shef_pkg.sql
@../cwms/cwms_text_pkg.sql
@../cwms/cwms_ts_pkg.sql
@../cwms/cwms_tsv_pkg.sql
@../cwms/cwms_vt_pkg.sql
@../cwms/cwms_util_pkg.sql
@../cwms/cwms_xchg_pkg.sql
@../cwms/cwms_msg_pkg.sql
@../cwms/runstats_pkg.sql

PROMPT ################################################################################
PROMPT FINAL HOUSEKEEPING
select systimestamp from dual;
declare
   type usernames_t is table of varchar2(30);
   usernames usernames_t;
   l_count integer;
   cmd varchar2(128);
begin
   select count(*) into l_count from dba_users where username='CCP';
   usernames := usernames_t('&cwms_schema', '&cwms_dba_schema');
   if (l_count > 0) then
      usernames.extend;
      usernames(usernames.count) := 'CCP';
   end if;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'PACKAGE BODY') loop
      cmd := 'grant execute on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'TYPE') loop
      cmd := 'grant execute on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'VIEW' and object_name not like '%AQ$%') loop
      cmd := 'grant select on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
end;
/
@@./util/restore_privs

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects

promp ################################################################################
PROMPT REMAINING INVALID OBJECTS...
select systimestamp from dual;
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
/

whenever sqlerror exit;

PROMPT ################################################################################
PROMPT UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./24_04_05/update_db_change_log
select substr(version, 1, 10) as version,
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date,
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;
declare
   l_count pls_integer;
begin
   select count(*)
     into l_count
     from all_objects
    where status = 'INVALID'
      and owner in ('&cwms_schema', '&cwms_dba_schema');

   if l_count > 0 then
      raise_application_error(-20999, chr(10)||'==>'||chr(10)||'==> SOME OBJECTS ARE STILL INVALID'||chr(10)||'==>');
   end if;
end;
/
PROMPT ################################################################################
PROMPT UPDATE COMPLETE
select systimestamp from dual;
exit