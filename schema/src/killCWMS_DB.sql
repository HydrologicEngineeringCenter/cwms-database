set time on
set echo off
set define on
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo       : '
accept inst        char prompt 'Enter the database instance    : '
accept builduser   char prompt 'Enter builduser    : '
accept builduser_passwd  char prompt 'Enter the password for builduser     : '
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
-- log on as builduser
--
whenever sqlerror exit sql.sqlcode
connect &builduser/&builduser_passwd@&inst 
begin dbms_output.enable; end;
/

--ALTER SYSTEM ENABLE RESTRICTED SESSION;

--
-- kill the cwms public synonyms
--
set echo off
set serveroutput on
set echo off
--  Kill current CWMS sessions
declare
    cursor c is select sid,serial# from v$session where username = '&cwms_schema' or
	username like '__CWMSPD' or username like '__HECTEST%' or username = 'CWMS9999';
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
   for rec in (select role from dba_roles
	where role = 'CWMS_USER' or role = 'CWMS_DBX_ROLE')
   loop
   	dbms_output.put_line('drop role ' || rec.role);
   	execute immediate 'drop role ' || rec.role;
   end loop;
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role  : ' || sqlerrm);
      raise;  
end;
/
begin
   for rec in (   
      select username 
        from all_users 
       where username like '__CWMSPD' 
          or username like '__HECTEST%' 
          or username like 'CWMS9999' 
    order by username) 
   loop
      begin
         dbms_output.put_line('drop user ' || rec.username || ' cascade');
         execute immediate 'drop user ' || rec.username || ' cascade';
      exception
         when others then 
            dbms_output.put_line('==> Cannot drop user ' || rec.username || ': ' || sqlerrm);
            raise;  
      end;
   end loop;
end;
/
begin
   for rec in (select username from dba_users
	where username = '&CWMS_SCHEMA' or username = 'CWMS_DBA')
   loop
   	dbms_output.put_line('drop user ' || rec.username || ' cascade');
   	execute immediate 'drop user  ' || rec.username || '  cascade';
   end loop;
exception
   when others then 
      dbms_output.put_line('==> Cannot drop role  : ' || sqlerrm);
      raise;  
end;
/

purge recyclebin;
--ALTER SYSTEM DISABLE RESTRICTED SESSION;
--EXEC DBMS_LOCK.SLEEP(1);
exit 0

