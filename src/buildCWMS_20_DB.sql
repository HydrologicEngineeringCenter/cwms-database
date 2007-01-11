set echo off
set time on
set define &
set concat .
whenever sqlerror exit sql.sqlcode
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo        : '
accept inst        char prompt 'Enter the database instance     : '
accept eroc        char prompt 'Enter the EROC for this office  : '
accept sys_passwd  char prompt 'Enter the password for SYS      : '
accept cwms_passwd char prompt 'Enter the password for CWMS_20  : '
accept pd_passwd   char prompt 'Enter the password for &eroc.cwmspd : '
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
create or replace public synonym cwms_err for cwms_20.cwms_err;
grant execute on cwms_20.cwms_err to cwms_user;

@@cwms/at_schema
@@cwms/at_schema_tsv
@@cwms/at_sec_schema

@@cwms/CWMS_UTIL_PKG
@@cwms/CWMS_UTIL_PKG_BODY
create or replace public synonym cwms_util for cwms_20.cwms_util;
grant execute on cwms_20.cwms_util to cwms_user;

@@cwms/at_schema_tsv_dqu

@@cwms/CWMS_SEC_POLICY
@@cwms/CWMS_SEC_POLICY_BODY
create or replace public synonym cwms_sec_policy for cwms_20.cwms_sec_policy;
grant execute on cwms_20.cwms_sec_policy to cwms_user;

@@cwms/CWMS_TS_PKG
@@cwms/CWMS_TS_PKG_BODY
create or replace public synonym cwms_ts for cwms_20.cwms_ts;
grant execute on cwms_20.cwms_ts to cwms_user;

@@cwms/CWMS_DSS_PKG
@@cwms/CWMS_DSS_PKG_BODY
create or replace public synonym cwms_dss for cwms_20.cwms_dss;
grant execute on cwms_20.cwms_dss to cwms_user;

@@cwms/at_schema_2

@@cwms/CWMS_CAT_PKG
@@cwms/CWMS_CAT_PKG_BODY
create or replace public synonym cwms_cat for cwms_20.cwms_cat;
grant execute on cwms_20.cwms_cat to cwms_user;

@@cwms/CWMS_LOC_PKG
@@cwms/CWMS_LOC_PKG_BODY
create or replace public synonym cwms_loc for cwms_20.cwms_loc;
grant execute on cwms_20.cwms_loc to cwms_user;

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
set define on
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

