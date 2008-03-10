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
      begin
         execute immediate 'drop public synonym ' || rec.synonym_name;
      exception
         when others then 
            dbms_output.put_line('==> Cannot drop public synonym ' || rec.synonym_name || ': ' || sqlerrm);
      end;
   end loop;
end;
/
set echo &echo_state
--
-- kill the cwms users and the roles
--
begin
   drop role cwms_dev;
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role cwms_dev : ' || sqlerrm);
end;
begin
   drop role cwms_user;
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role cwms_user : ' || sqlerrm);
end;
set echo off
begin
   for rec in (   
      select username 
        from all_users 
       where username like '__CWMSDBI' 
          or username like '__CWMSPD' 
          or username like '__HECTEST' 
    order by username) 
   loop
      begin
         dbms_output.put_line('drop user ' || rec.username);
         execute immediate 'drop user ' || rec.username;
      exception
         when others then 
            dbms_output.put_line('==> Cannot drop user ' || rec.username || ': ' || sqlerrm);
      end;
   end loop;
end;
/
set echo &echo_state
drop user cwms_20 cascade;
exit

