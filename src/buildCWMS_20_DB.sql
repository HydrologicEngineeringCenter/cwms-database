set echo off
set time on
whenever sqlerror exit sql.sqlcode
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept eroc        char prompt 'Enter the EROC for this office : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
accept cwms_passwd char prompt 'Enter the password for CWMS_20 : '
spool buildCWMS_20_DB.log
--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
select sysdate from dual;
set serveroutput on
begin dbms_output.enable; end;
/
set echo &echo_state
--
-- create user roles and users
--
@@cwms/User-Roles/cwms_dev_role
@@cwms/User-Roles/cwms_user_role
@@cwms/User-Roles/cwms_20_user
@@cwms/User-Roles/cwmspd_user

--
-- log on as the CWMS_20 user
--
connect cwms_20/&cwms_passwd@&inst
@@buildCwms
@@cwms/cwms_types

@@cwms/CWMS_ERR_PKG
@@cwms/CWMS_ERR_PKG_BODY

@@cwms/at_schema
@@cwms/at_schema_tsv

@@cwms/CWMS_UTIL_PKG
@@cwms/CWMS_UTIL_PKG_BODY

@@cwms/at_schema_tsv_dqu

@@cwms/CWMS_TS_PKG
@@cwms/CWMS_TS_PKG_BODY

@@cwms/CWMS_DSS_PKG
@@cwms/CWMS_DSS_PKG_BODY

@@cwms/at_schema_2

@@cwms/CWMS_CAT_PKG
@@cwms/CWMS_CAT_PKG_BODY

@@cwms/CWMS_LOC_PKG
@@cwms/CWMS_LOC_PKG_BODY

--
-- re-log on as sysdba and compile all invalid objects
--
set echo off
connect sys/&sys_passwd@&inst as sysdba
prompt Invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type 
    from dba_objects 
   where owner = 'CWMS_20' 
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Recompiling all invalid objects...
exec utl_recomp.recomp_serial('CWMS_20');
/

prompt Remaining invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type 
    from dba_objects 
   where owner = 'CWMS_20' 
     and status = 'INVALID'
order by object_name, object_type asc;

--
-- re-log on as the CWMS_20 user and start jobs
--
connect cwms_20/&cwms_passwd@&inst
set serveroutput on
prompt Starting jobs...
begin
   cwms_util.start_timeout_mv_refresh_job;
end;
/
--
-- all done
--
exit

