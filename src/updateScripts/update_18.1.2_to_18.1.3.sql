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
define logfile=update_&db_name._18.1.2_to_18.1.3.log
prompt log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
prompt ################################################################################
prompt VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./18_1_3/verify_db_version
prompt ################################################################################
prompt UPDATING OBJECTS
------------
-- TABLES --
------------
-- Drop service user table
@@./18_1_3/recreate_at_sec_service_user.sql 
-- Add index to at_sec_user_groups table
@@./18_1_3/update_at_sec_user_groups.sql
-- Add trigger to location updates and deletions on AT_PHYSICAL_LOCATION
@@./18_1_3/at_physical_location_t03
--------------
-- PACKAGES --
--------------
-- Fix documentation for CAT_FORECAST routine
@../cwms/cwms_forecast_pkg
-- Fix bugs in testing for invalid results of LOG function
@../cwms/cwms_lookup_pkg_body
-- Fix bug in RETRIEVE_RATINGS_XML_DATA that ignored specified time zone
-- Fix bugs in testing for invalid results of LOG function
@../cwms/cwms_rating_pkg_body
-- Fix bugs in testing for invalid results of LOG function
@../cwms/cwms_rounding_pkg_body
-- Make service account password DoD compliant
-- Add procedures to get locked users and invalid login attempt
-- API call to add 'read_only' users to National CWMS DB
@../cwms/cwms_crypt_pkg
@../cwms/cwms_crypt_pkg_body
@../cwms/cwms_sec_pkg
@../cwms/cwms_sec_pkg_body
@../cwms_dba/cwms_user_admin_pkg.sql
@../cwms_dba/cwms_user_admin_pkg_body.sql
create or replace public synonym cwms_crypt for cwms_crypt;
-- Modify RETRIEVE_TS_MULTI to handle LOCATION_ID_NOT_FOUND in addition to TS_ID_NOT_FOUND
-- Fix bug in storing version flag
@../cwms/cwms_ts_pkg_body
-- Fix bug in GET_DB_NAME that returns incorrect name for dbs with DataGuard
-- Fix bug in reporting last logout time when there have been multiple logins, but no logouts
-- Fix bug in storing ratings with algebraic formulas without spaces
@../cwms/cwms_util_pkg_body
-- Fix bug in STORE_ACCOUNTING_SET to handle the change from locally-owned to CWMS-owned common physical transfer types
@../cwms/cwms_water_supply_pkg_body
-----------
-- TYPES --
-----------
-- Fix bugs in testing for invalid results of LOG function
@../cwms/types/rating_ind_parameter_t-body
-- Fix bug in storing ratings with algebraic formulas without spaces
-- Modified to allow contstrutor from XML to allow simple-rating with no formula or points
@../cwms/types/rating_t-body
-- Modified to allow contstrutor from XML to allow usgs-stream-rating with no points
@../cwms/types/stream_rating_t-body
-----------
-- VIEWS --
-----------
-- Additional views added for debugging purposes
@../cwms/views/av_ts_msg_archive
@../cwms/views/av_tsv_count_minute
@../cwms/views/av_tsv_count_day
-- Recreate mv_ts_code_filter
drop materialized view mv_ts_code_filter;
@../cwms/mv_ts_code_filter
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
@@./18_1_3/update_db_change_log
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

