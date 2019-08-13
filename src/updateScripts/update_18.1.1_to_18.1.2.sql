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
prompt VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./18_1_2/verify_db_version
prompt ################################################################################
prompt UPDATING OBJECTS
------------
-- TABLES --
------------
-- Extend expression length on virtual rating expressions
alter table at_virtual_rating_element modify (rating_expression varchar2(80));
-- Extend database id length in db change log
alter table cwms_db_change_log modify (database_id varchar2(61));
--------------
-- PACKAGES --
--------------
-- Switch to new method of retrieving database name
-- Modify GET_LOOKUP_TABLE to retrieve CWMS-owned records in addition to specified office
@../cwms/cwms_cat_pkg_body
-- Switch to new method of retrieving database name
@../cwms/cwms_level_pkg_body
@../cwms/cwms_mail_pkg_body
@../cwms/cwms_rating_pkg_body
@../cwms/cwms_scheduler_auth_pkg_body
-- Switch to new method of retrieving database name
-- Modify CREATE_LOCATION_RAW2 to allow nation to be passed in as id or code
@../cwms/cwms_loc_pkg_body
-- Switch to new method of retrieving database name
-- Fix bug in retrieve_time_series for JSON and XML formats when no data
@../cwms/ts_pkg_body
-- Switch from http to https on URLs
@../cwms/usgs_pkg
@../cwms/usgs_pkg_body
-- Fix bug in reporting last logout time when there have been multiple logins, but no logouts
-- Add function to retrieve appropriate database name for standard or containerized dbs
-- Add and use function to normalize Java rating expressions into PL/SQL rating expressions
-- Fix bugs on parsing infix (algebraic) expressions that have negated arguments or functions
@../cwms/util_pkg
@../cwms/util_pkg_body
-- Switch to new method of retrieving database name
-- Restore maximum length of 16 for DB data store ID to prevent XML validation errors
@../cwms/cwms_xchg_pkg_body
-----------
-- TYPES --
-----------
-- Handle anomalies in USGS measurements records better
@../cwms/types/streamflow_meas_t-body
-- Fix bug in generating <extsion-points> XML data
@../cwms/types/rating_ind_parameter_t-body
-- Modify constructor from database to return shift effective dates and shift active flags when not returning rating points
@../cwms/types/stream_rating_t-body
-----------
-- VIEWS --
-----------
-- Fix bug in units conversion
@../cwms/views/av_location_level
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
prompt UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./18_1_2/update_db_change_log
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

