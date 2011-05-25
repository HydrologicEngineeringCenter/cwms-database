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
@@cwms/at_schema_crrel
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
--@@cwms/cwms_types_rating
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
   name_already_used exception;
   pragma exception_init(name_already_used, -955);
   type str_tab_t is table of varchar2(30);
   l_package_names   str_tab_t;
   l_view_names      str_tab_t;
   l_type_names      str_tab_t;
   l_public_synonyms str_tab_t;
   l_sql_statement varchar2(128);
   l_synonym varchar2(40);
begin
   --
   -- collect public synonyms for CWMS items 
   --
   select synonym_name bulk collect
     into l_public_synonyms
     from dba_synonyms
    where owner = 'PUBLIC'
      and substr(synonym_name, 1, 5) = 'CWMS_';
   --
   -- collect CWMS schema packages except for security
   --
   select object_name bulk collect
     into l_package_names      
     from dba_objects 
    where owner = '&cwms_schema' 
      and object_type = 'PACKAGE'
      and object_name not like '%_SEC_%';
   --
   -- collect CWMS schema views except for security
   --
   select object_name bulk collect
     into l_view_names 
     from dba_objects 
    where owner = '&cwms_schema'
      and object_type like '%VIEW'
      and object_name not like '%_SEC_%' 
      and regexp_like(object_name, '^[AM]V_');
   --
   -- collect CWMS schema object types
   --
   select object_name bulk collect
     into l_type_names 
     from dba_objects
    where owner = '&cwms_schema'
      and object_type = 'TYPE'
      and object_name not like 'SYS_%';
   --
   -- drop collected public synonyms
   --
   dbms_output.put_line('--');
   for i in 1..l_public_synonyms.count loop
      l_sql_statement := 'DROP PUBLIC SYNONYM '||l_public_synonyms(i);
      dbms_output.put_line('-- ' || l_sql_statement);
      execute immediate l_sql_statement;
   end loop;      
   --
   -- create public synonyms for collected packages
   --
   dbms_output.put_line('--');
   for i in 1..l_package_names.count loop
      l_sql_statement := 'CREATE PUBLIC SYNONYM '||l_package_names(i)||' FOR &cwms_schema'||'.'||l_package_names(i);
      dbms_output.put_line('-- ' || l_sql_statement);
      execute immediate l_sql_statement;
   end loop;
   --
   -- create public synonyms for collected views
   --
   dbms_output.put_line('--');
   for i in 1..l_view_names.count loop
      l_synonym := regexp_replace(l_view_names(i), '^(Z)?(A|(M))V_(CWMS_)*', 'CWMS_V_\3\1');
      if length(l_synonym) > 30 then
         raise_application_error(
            -20999, 
            'Synonym ('
            ||l_synonym
            ||') for type &cwms_schema..'
            ||l_view_names(i)
            ||' is too long');
      end if;
      l_sql_statement := 'CREATE PUBLIC SYNONYM '||l_synonym||' FOR &cwms_schema'||'.'||l_view_names(i);
      dbms_output.put_line('-- ' || l_sql_statement);
      execute immediate l_sql_statement;
   end loop;
   --
   -- create public synonyms for collected types
   --
   dbms_output.put_line('--');
   for i in 1..l_type_names.count loop
      l_synonym := regexp_replace(l_type_names(i), '^((AT|CWMS)_)?(\w+?)(_T(YPE)?)?$', 'CWMS_T_\3');
      if length(l_synonym) > 30 then
         dbms_output.put_line(
            '-- Synonym ('
            ||l_synonym
            ||') for type &cwms_schema..'
            ||l_type_names(i)
            ||' is too long');
         continue;            
      end if;
      for j in 2..999999 loop
         l_sql_statement := 'CREATE PUBLIC SYNONYM '||l_synonym||' FOR &cwms_schema'||'.'||l_type_names(i);
         dbms_output.put_line('-- ' || l_sql_statement);
         begin
            execute immediate l_sql_statement;
            exit;
         exception
            when name_already_used then
               dbms_output.put_line('--  name already used!');
               l_synonym := substr(l_synonym, 1, 29)||j;
         end;
      end loop;
   end loop;
   --
   -- grant execute on collected packages to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..l_package_names.count loop
      l_sql_statement := 'GRANT EXECUTE ON &cwms_schema'||'.'||l_package_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || l_sql_statement);
      execute immediate l_sql_statement;
   end loop;
   --
   -- grant execute on collected types to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..l_type_names.count loop
      l_sql_statement := 'GRANT EXECUTE ON &cwms_schema'||'.'||l_type_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || l_sql_statement);
      execute immediate l_sql_statement;
   end loop;
   --
   -- grant select on collected views to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..l_view_names.count loop
      l_sql_statement := 'GRANT SELECT ON &cwms_schema'||'.'||l_view_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || l_sql_statement);
      execute immediate l_sql_statement;
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
exec cwms_ts.start_trim_ts_deleted_job;
/
exec cwms_sec.start_refresh_mv_sec_privs_job;
/
--
-- all done
--
exit 0

