set echo off
set time on
whenever sqlerror exit sql.sqlcode
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
accept cwms_passwd char prompt 'Enter the password for CWMS_20 : '
set echo &echo_state
spool buildCWMS_20_DB.log
--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
begin dbms_output.enable(20000); end;
/
select sysdate from dual;
set serveroutput on
--
-- create the cwms_dev role and the cwms_20 user
--
@@cwms/User-Roles/cwms_dev_role
@@cwms/User-Roles/cwms_20_user
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

@@cwms/CWMS_LOC_PKG
@@cwms/CWMS_LOC_PKG_BODY

@@cwms/CWMS_CAT_PKG
@@cwms/CWMS_CAT_PKG_BODY

@@cwms/CWMS_TS_PKG
@@cwms/CWMS_TS_PKG_BODY

@@cwms/CWMS_DSS_PKG
@@cwms/CWMS_DSS_PKG_BODY

@@cwms/at_schema_2
--
-- all done
--
exit

