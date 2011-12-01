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
@@data/cwms_schema_object_version


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

--
-- Create public synonyms and cwms_user roles
@@cwms/at_schema_public_interface.sql

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
exec cwms_msg.start_trim_log_job;
/
exec cwms_msg.start_purge_queues_job;
/
exec cwms_schema.cleanup_schema_version_table;
/
exec cwms_schema.start_check_schema_job;
/
exec cwms_ts.start_trim_ts_deleted_job;
/
exec cwms_sec.start_refresh_mv_sec_privs_job;
/
--
-- all done
--
exit 0

