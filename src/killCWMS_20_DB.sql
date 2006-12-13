set time on
set echo off
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
prompt '***************************************************************'
prompt '***                                                         ***'
prompt '*** Warning: This will completely remove all CWMS_20 schema ***'
prompt '*** objects!                                                ***'
prompt '***                                                         ***'
prompt '*** Press Ctrl-C now if you do not wish to continue!        ***'
prompt '***                                                         ***'
prompt '***************************************************************'
accept dummy char noprompt
set echo &echo_state
spool killCWMS_20_DB.log
--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
select sysdate from dual;
--
-- kill the cwms_20 user and the cwms_dev role
--
set echo on
drop user cwms_20 cascade;
drop role cwms_dev;
exit

