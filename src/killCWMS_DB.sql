set time on
set echo off
set define on
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept sys_passwd  char prompt 'Enter the password for SYS     : '
prompt '***************************************************************'
prompt '***                                                         ***'
prompt '*** Warning: This will completely remove all CWMS schema ***'
prompt '*** objects!                                                ***'
prompt '***                                                         ***'
prompt '*** Press Ctrl-C now if you do not wish to continue!        ***'
prompt '***                                                         ***'
prompt '*** Otherwise, press Enter.                                 ***'
prompt '***                                                         ***'
prompt '***************************************************************'
accept dummy char noprompt
set echo &echo_state
spool killCWMS_DB.log
--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
select sysdate from dual;
whenever sqlerror exit sql.sqlcode

--
-- kill the cwms public synonyms
--
set echo off
set serveroutput on
set echo off
--  Kill current CWMS sessions
declare
    cursor c is select sid,serial# from v$session where username = '&cwms_schema';
    kill_command varchar2(128);
begin

    dbms_output.put_line('Kill current schema sessions');
    for rec in c
    loop
        kill_command := 'alter system kill session '''||rec.sid||','||rec.serial#||'''';
        dbms_output.put_line(kill_command);
        execute immediate kill_command;
    end loop;
end;
/

begin
   for rec in (
      select synonym_name
        from sys.all_synonyms
       where owner = 'PUBLIC'
         and table_owner = '&CWMS_SCHEMA')               
   loop
      dbms_output.put_line('drop public synonym ' || rec.synonym_name);
      begin
         execute immediate 'drop public synonym ' || rec.synonym_name;
      exception
         when others then 
            dbms_output.put_line('==> Cannot drop public synonym ' || rec.synonym_name || ': ' || sqlerrm);
            raise;  
      end;
   end loop;
end;
/
--
-- kill the cwms users and the roles
--
begin
   dbms_output.put_line('drop role &CWMS_SCHEMA');
   execute immediate 'drop role &CWMS_SCHEMA';
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role &CWMS_SCHEMA : ' || sqlerrm);
      raise;  
end;
/
begin
   dbms_output.put_line('drop role cwms_user');
   execute immediate 'drop role cwms_user';
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role cwms_user : ' || sqlerrm);
      raise;  
end;
/
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
            raise;  
      end;
   end loop;
end;
/
begin
   dbms_output.put_line('drop user &cwms_schema cascade');
   execute immediate 'drop user &cwms_schema cascade';
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role &cwms_schema : ' || sqlerrm);
      raise;  
end;
/
begin
   dbms_output.put_line('drop user cwms_dba cascade');
   execute immediate 'drop user cwms_dba cascade';
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role cwms_dba : ' || sqlerrm);
      raise;  
end;
/
set echo &echo_state
exit 0

