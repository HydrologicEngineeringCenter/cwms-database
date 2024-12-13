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
define logfile=update_&db_name._24_5_24_to_24_12_4.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./24_12_04/verify_db_version



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
PROMPT CREATING AND ALTERING COLUMN-TYPE SPECIFICATIONS
select systimestamp from dual;
@../cwms/column-types/supplemental_streamflow_meas_t
@../cwms/column_types/blob_file_t
@../cwms/column_types/file_t
@../cwms/column_types/text_file_t
@../cwms/column_types/uuid_t

PROMPT ################################################################################
PROMPT ALTERING TABLES

@./24_12_04/at_lock_gate_type
alter table at_lock add units_id VARCHAR2(16);
alter table at_lock add maximum_lock_lift BINARY_DOUBLE;
alter table at_lock add chamber_location_description_code NUMBER(14);

COMMENT ON COLUMN at_lock.maximum_lock_lift IS 'The maximum lift the lock can support';
COMMENT ON COLUMN at_lock.chamber_location_description_code IS 'A single chamber, land side main, land side aux, river side main, river side aux.';

COMMENT ON COLUMN at_lockage.number_boats IS 'The number of boats accommodated in this lockage';
COMMENT ON COLUMN at_lockage.number_barges IS 'The number of barges accommodated in this lockage';
COMMENT ON COLUMN at_lockage.tonnage IS 'The tonnage of product accommodated in this lockage';

INSERT INTO at_specified_level VALUES(27, 53, 'High Water Upper Pool',             'High Water Upper Pool Level');
INSERT INTO at_specified_level VALUES(28, 53, 'High Water Lower Pool',             'High Water Lower Pool Level');
INSERT INTO at_specified_level VALUES(29, 53, 'Low Water Upper Pool',              'Low Water Upper Pool Level');
INSERT INTO at_specified_level VALUES(30, 53, 'Low Water Lower Pool',              'Low Water Lower Pool Level');
INSERT INTO at_specified_level VALUES(31, 53, 'Warning Buffer',                    'Warning Buffer level');

@./24_12_04/data_acquisition

update CWMS_COUNTY set COUNTY_NAME =  'LaMoure' where COUNTY_CODE = 38045;

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE SPECIFICATIONS
select systimestamp from dual;

drop type lock_obj_t force;

@../cwms/types/lock_obj_t

@../cwms/types/supp_streamflow_meas_t
@../cwms/types/supp_streamflow_meas_t-body
@../cwms/types/streamflow_meas2_t
@../cwms/types/streamflow_meas2_t-body
@../cwms/types/streamflow_meas2_tab_t
@../cwms/types/blob_file_t-body
@../cwms/types/fcst_file_t
@../cwms/types/fcst_file_tab_t
@../cwms/types/file_t-body
@../cwms/types/text_file_t-body
@../cwms/types/uuid_t-body


alter table at_streamflow_meas add supplemental_streamflow_meas supp_streamflow_meas_t;

PROMPT ################################################################################
PROMPT CREATING NEW TABLES

@../cwms/tables/at_fcst_spec
@../cwms/tables/at_fcst_location
@../cwms/tables/at_fcst_time_series
@../cwms/tables/at_fcst_inst
@../cwms/tables/at_fcst_info



PROMPT ################################################################################
PROMPT CREATING AND ALTERING VIEWS
select systimestamp from dual;
delete from at_clob where id = '/VIEWDOCS/AV_GAGE';
delete from at_clob where id = '/VIEWDOCS/AV_LOC_GRP_ASSGN';
delete from at_clob where id = '/VIEWDOCS/AV_LOCK';
delete from at_clob where id = '/VIEWDOCS/AV_TS_GRP_ASSGN';
delete from at_clob where id = '/VIEWDOCS/AV_TS_PROFILE_PARSER';
delete from at_clob where id = '/VIEWDOCS/AV_USGS_RATING';

@../cwms/views/av_gage
@../cwms/views/av_loc_grp_assgn
@../cwms/views/av_lock
@../cwms/views/av_ts_grp_assgn
@../cwms/views/av_ts_profile_parser
@../cwms/views/av_usgs_rating

@../cwms/views/av_stream_reach
@../cwms/views/av_fcst_info
@../cwms/views/av_fcst_inst
@../cwms/views/av_fcst_location
@../cwms/views/av_fcst_spec
@../cwms/views/av_fcst_time_series

PROMPT ################################################################################
PROMPT UPDATING PACKAGE

@../cwms/cwms_cache_pkg
@../cwms/cwms_lock_pkg
@../cwms/cwms_project_pkg
@../cwms/cwms_sec_pkg
@../cwms/cwms_stream_pkg
@../cwms/cwms_ts_pkg
@../cwms/cwms_fcst_pkg
@../cwms/cwms_util_pkg

PROMPT ################################################################################
PROMPT UPDATING PACKAGE BODIES
select systimestamp from dual;

@../cwms/cwms_cache_pkg_body
@../cwms/cwms_cat_pkg_body
@../cwms/cwms_cma_pkg_body
@../cwms/cwms_level_pkg_body
@../cwms/cwms_loc_pkg_body
@../cwms/cwms_lock_pkg_body
@../cwms/cwms_outlet_pkg_body
@../cwms/cwms_project_pkg_body
@../cwms/cwms_sec_pkg_body
@../cwms/cwms_shef_pkg_body
@../cwms/cwms_stream_pkg_body
@../cwms/cwms_ts_pkg_body
@../cwms/cwms_ts_profile_pkg_body
@../cwms/cwms_util_pkg_body
@../cwms/cwms_vt_pkg_body
@../cwms/cwms_water_supply_pkg_body
@../cwms/cwms_fcst_pkg_body


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

create unique index at_fcst_spec_idx2 on at_fcst_spec (
   cwms_util.get_db_office_id_from_code(office_code),
   fcst_spec_id,
   fcst_designator);

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
PROMPT ################################################################################
PROMPT RESTORING PRE-UPDATE PRIVILEGES
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
@@./24_12_04/update_db_change_log
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
