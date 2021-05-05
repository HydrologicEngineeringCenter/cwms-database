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
define logfile=update_&db_name._18.1.8_to_18.1.9.log
prompt log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
prompt ################################################################################
prompt VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./18_1_9/verify_db_version
prompt ################################################################################
prompt UPDATING OBJECTS
--------------
-- PACKAGES --
--------------
prompt update packages
@../cwms/cwms_ts_pkg_body

-- Missing grants
prompt Apply missing grants
grant select on av_ts_extents_utc to cwms_user;
grant execute on cwms_ts_profile to cwms_user;
grant execute on shef_spec_type to cwms_user;

-- Recreate VPD policy
@../cwms/create_service_user_policy.sql

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
exec sys.utl_recomp.recomp_serial('&cwms_schema');
prompt ################################################################################
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
prompt UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./18_1_9/update_db_change_log.sql
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

