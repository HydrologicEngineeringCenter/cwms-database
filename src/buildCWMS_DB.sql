set echo off
set time on
set define on
set concat on
set linesize 1024   
whenever sqlerror exit sql.sqlcode

--
-- prompt for info
--
@@py_prompt
 
spool buildCWMS_DB.log
--
-- log on as sysdba
--
connect sys/&sys_passwd@&inst as sysdba
--
--
select sysdate from dual;
set serveroutput on
begin dbms_output.enable; end;
/
set echo &echo_state
whenever sqlerror exit sql.sqlcode
--
-- create user roles and users
--
@@cwms/User-Roles/cwms_user_profile
@@cwms/User-Roles/cwms_user_roles
@@cwms/User-Roles/cwms_users
@@cwms/User-Roles/cwms_dba_user

--
@@cwms_dba/cwms_user_admin_pkg
@@cwms_dba/cwms_user_admin_pkg_body
--
set define on
grant execute on  cwms_dba.cwms_user_admin to &cwms_schema;
grant execute on  dbms_crypto to cwms_user;

--
-- switch to cwms_schema 
--
alter session set current_schema = &cwms_schema;

--
-- structure that can be built without the CWMS API,
-- even if it results in invalid objects
--
@@py_BuildCwms
@@cwms/cwms_types
@@cwms/at_schema
@@cwms/at_schema_shef
@@cwms/at_schema_alarm
@@cwms/at_schema_screening
@@cwms/at_schema_dss_xchg
@@cwms/at_schema_msg
@@cwms/at_schema_at_data
@@cwms/at_schema_mv
@@cwms/at_schema_av
@@cwms/at_schema_rating
@@cwms/at_schema_tsv
@@cwms/at_schema_tr
@@cwms/at_schema_sec
@@cwms/at_schema_apex_debug

--
--  Load data into cwms tables...
--
@@data/cwms_shef_pe_codes


--
-- CWMS API
--
@@cwms/api

--
-- structure that can't be built without the CWMS API,
-- 
@@cwms/at_schema_2
@@cwms/at_schema_tsv_dqu
--
-- Create dbi and pd user accounts...
---
set define on
@@py_ErocUsers


alter session set current_schema = sys;
set serveroutput on
set echo on
--
--
-- create public synonyms for CWMS schema packages and views
-- grant execute on packages to CWMS_USER role
-- grant select on view to CWMS_USER role
--
-- exclude any package or view named like %_SEC_%
--
declare 
   type str_tab_t is table of varchar2(32);
   package_names str_tab_t := str_tab_t();
   view_names str_tab_t := str_tab_t();
   type_names str_tab_t := str_tab_t();
   sql_statement varchar2(128);
   view_synonym varchar2(32);
begin
   --
   -- collect CWMS schema packages except for security
   --
   for rec in (
      select object_name 
        from dba_objects 
       where owner = '&cwms_schema' 
         and object_type = 'PACKAGE')
   loop
      if instr(rec.object_name, '_SEC_') = 0 then
         package_names.extend;
         package_names(package_names.last) := rec.object_name;
      end if;
   end loop;
   --
   -- collect CWMS schema views except for security
   --
   for rec in (
      select object_name 
        from dba_objects 
       where owner = '&cwms_schema'
         and object_type like '%VIEW'
         and regexp_like(object_name, '^[AM]V_')) 
   loop
      if instr(rec.object_name, '_SEC_') = 0 then
         view_names.extend;
         view_names(view_names.last) := rec.object_name;
      end if;
   end loop;
   --
   -- collect CWMS schema object types
   --
   for rec in (
      select object_name 
        from dba_objects 
       where owner = '&cwms_schema'
         and object_type = 'TYPE'
         and object_name not like 'SYS_%')
   loop
      type_names.extend;
      type_names(type_names.last) := rec.object_name;
   end loop;
   

   --
   -- create public synonyms for collected packages
   --
   for i in 1..package_names.count loop
      sql_statement := 'CREATE OR REPLACE PUBLIC SYNONYM '||package_names(i)||' FOR &cwms_schema'||'.'||package_names(i);
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- create public synonyms for collected views
   --
   for i in 1..view_names.count loop
   	begin
	      view_synonym := regexp_replace(view_names(i), '^[AM]V_(CWMS_)*', 'CWMS_V_');
		exception
			when others then
				-- view name is too long to be expanded by replacement!
				dbms_output.put_line('-- ERROR CREATING SYN)NYM FOR VIEW ' || view_names(i));
				continue;
		end;
      sql_statement := 'CREATE OR REPLACE PUBLIC SYNONYM '||view_synonym||' FOR &cwms_schema'||'.'||view_names(i);
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- grant execute on collected packages to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..package_names.count loop
      sql_statement := 'GRANT EXECUTE ON &cwms_schema'||'.'||package_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- grant execute on COLLECTED types to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..type_names.count loop
      sql_statement := 'GRANT EXECUTE ON &cwms_schema'||'.'||type_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
   --
   -- grant select on collected packages to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..view_names.count loop
      sql_statement := 'GRANT SELECT ON &cwms_schema'||'.'||view_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
end;
/

--
-- compile all invalid objects
--
SET define on
alter materialized view "&cwms_schema"."MV_SEC_TS_PRIVILEGES" compile
/

set echo off
prompt Invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type 
    from dba_objects 
   where owner = '&cwms_schema' 
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Recompiling all invalid objects...
exec utl_recomp.recomp_serial('&cwms_schema');
/

prompt Remaining invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type 
    from dba_objects 
   where owner = '&cwms_schema' 
     and status = 'INVALID'
order by object_name, object_type asc;

declare
   obj_count integer;
begin
   select count(*)
     into obj_count
     from dba_objects
    where owner = '&cwms_schema' 
      and status = 'INVALID';
   if obj_count > 0 then
      dbms_output.put_line('' || obj_count || ' objects are still invalid.');
      raise_application_error(-20999, 'Some objects are still invalid.');
   else
      dbms_output.put_line('All invalid objects successfully compiled.');
   end if;
end;
/


set echo off
--
-- log on as the CWMS schema user and start queues and jobs
--
set define on
connect &cwms_schema/&cwms_passwd@&inst
set serveroutput on
--------------------------------------
-- create and start queues and jobs --
--------------------------------------
prompt Creating and starting queues...
@py_Queues
prompt Starting jobs...
exec cwms_util.start_mv_cwms_ts_id_job;
/
exec cwms_msg.start_trim_log_job;
/
exec cwms_msg.start_purge_queues_job;
/
exec cwms_sec.start_refresh_mv_sec_privs_job;
/
--
-- all done
--
exit 0

