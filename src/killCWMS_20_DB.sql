set time on
set echo off
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept eroc        char prompt 'Enter the EROC for this office : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
prompt '***************************************************************'
prompt '***                                                         ***'
prompt '*** Warning: This will completely remove all CWMS_20 schema ***'
prompt '*** objects!                                                ***'
prompt '***                                                         ***'
prompt '*** Press Ctrl-C now if you do not wish to continue!        ***'
prompt '***                                                         ***'
prompt '*** Otherwise, press Enter.                                 ***'
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
-- kill the cwms public synonyms
--
set echo off
set serveroutput on
begin
   for rec in (
      select synonym_name
        from sys.all_synonyms
       where owner = 'PUBLIC'
         and table_owner = 'CWMS_20')               
   loop
      dbms_output.put_line('drop public synonym ' || rec.synonym_name);
      execute immediate 'drop public synonym ' || rec.synonym_name;
   end loop;
end;
/
set echo &echo_state
--
-- kill the cwms users and the roles
--
drop role cwms_dev;
drop role cwms_user;
drop user &eroc.cwmsdbi;
drop user &eroc.cwmspd;
drop user cwms_20 cascade;
exit

