set echo off
set time on
set define on
set concat on
set linesize 1024   
whenever sqlerror exit sql.sqlcode
--
-- prompt for info
--
prompt
accept echo_state  char prompt 'Enter ON or OFF for echo         : '
--accept inst        char prompt 'Enter the database instance      : '
accept sys_passwd  char prompt 'Enter the password for SYS       : '
--accept cwms_passwd char prompt 'Enter the password for CWMS_20   : '
--accept dbi_passwd  char prompt 'Enter the password for ??cwmsdbi : '
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
@@cwms/User-Roles/cwms_user_roles
@@cwms/User-Roles/cwms_users
@@py_ErocUsers

--
-- switch to CWMS_20 schema
--
alter session set current_schema = cwms_20;

--
-- structure that can be built without the CWMS API,
-- even if it results in invalid objects
--
@@py_BuildCwms
@@cwms/cwms_types
@@cwms/at_schema
@@cwms/at_schema_tsv
@@cwms/at_sec_schema

--
-- CWMS API
--
@@cwms/api

--
-- structure that can't be built without the CWMS API,
-- 
@@cwms/at_schema_2
@@cwms/at_schema_tsv_dqu


alter session set current_schema = sys;
set serveroutput on
set echo off

--
-- create public synonyms for CWMS_20 packages and views
-- grant execute on packages to CWMS_USER role
-- grant select on view to CWMS_DEV role
--
-- exclude any package or view named like %_SEC_%
--
declare 
   type str_tab_t is table of varchar2(32);
   package_names str_tab_t := str_tab_t();
   view_names str_tab_t := str_tab_t();
   sql_statement varchar2(128);
   view_synonym varchar2(32);
begin
   --
   -- collect CWMS_20 packages except for security
   --
   for rec in (
      select object_name 
        from dba_objects 
       where owner = 'CWMS_20' 
         and object_type = 'PACKAGE')
   loop
      if instr(rec.object_name, '_SEC_') = 0 then
         package_names.extend;
         package_names(package_names.last) := rec.object_name;
      end if;
   end loop;
   --
   -- collect CWMS_20 views except for security
   --
   for rec in (
      select object_name 
        from dba_objects 
       where owner = 'CWMS_20'
         and object_type like '%VIEW'
         and regexp_like(object_name, '^[AM]V_')) 
   loop
      if instr(rec.object_name, '_SEC_') = 0 then
         view_names.extend;
         view_names(view_names.last) := rec.object_name;
      end if;
   end loop;
   --
   -- create public synonyms for collected packages
   --
   for i in 1..package_names.count loop
      sql_statement := 'CREATE OR REPLACE PUBLIC SYNONYM '||package_names(i)||' FOR CWMS_20.'||package_names(i);
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- create public synonyms for collected views
   --
   for i in 1..view_names.count loop
      view_synonym := regexp_replace(view_names(i), '^[AM]V_(CWMS_)*', 'CWMS_V_');
      sql_statement := 'CREATE OR REPLACE PUBLIC SYNONYM '||view_synonym||' FOR CWMS_20.'||view_names(i);
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- grant execute on collected packages to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..package_names.count loop
      sql_statement := 'GRANT EXECUTE ON CWMS_20.'||package_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- grant select on collected packages to CWMS_DEV role
   --
   dbms_output.put_line('--');
   for i in 1..view_names.count loop
      sql_statement := 'GRANT SELECT ON CWMS_20.'||view_names(i)||' TO CWMS_DEV';
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
end;
/

--
-- compile all invalid objects
--
set echo off
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
-- log on as the CWMS_20 user and start queues and jobs
--
set define on
connect cwms_20/&cwms_passwd@&inst
set serveroutput on
--------------------------------------
-- create and start queues and jobs --
--------------------------------------
prompt Creating and starting queues...
@py_Queues
prompt Starting jobs...
exec cwms_util.start_timeout_mv_refresh_job;
/
--
-- all done
--
exit

