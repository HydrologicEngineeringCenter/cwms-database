-------------------
-- general setup --
-------------------
whenever sqlerror exit;
set define on
set verify off
set pages 100
set serveroutput on
define cwms_schema = 'CWMS_20'
define cwms_dba_schema = 'CWMS_DBA'
alter session set current_schema = &cwms_schema;
------------------------------------------------------------
-- spool to file that identifies the database in the name --
------------------------------------------------------------
var db_name varchar2(61)
begin
   select nvl(primary_db_unique_name, db_unique_name) into :db_name from v$database;
end;
/
whenever sqlerror continue;
declare
   l_count pls_integer;
   l_name  varchar2(30);
begin
   select count(*) into l_count from all_objects where object_name = 'CDB_PDBS';
   if l_count > 0 then
      select name
        into l_name
        from v$database;
      :db_name := l_name;
      begin
         select pdb_name
           into l_name
           from cdb_pdbs;
      exception
         when no_data_found then
            l_name := null;
      end;
      if l_name is not null then
         :db_name := :db_name||'-'||l_name;
      end if;
   end if;
end;
/
whenever sqlerror exit;
column db_name new_value db_name
select :db_name as db_name from dual;
define logfile=update_&db_name._25_7_1_to_26_2_17.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./26_02_17/verify_db_version

PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql;

PROMPT ################################################################################
PROMPT ALTERING TABLES
select systimestamp from dual;

PROMPT ################################################################################
PROMPT ALTERING VIEWS
select systimestamp from dual;

PROMPT ################################################################################
PROMPT ALTERING TABLE DATA
select systimestamp from dual;
whenever sqlerror continue;
@@./26_02_17/update_cwms_nation_sp;
@@./26_02_17/update_cwms_state;
@@./26_02_17/update_cwms_county;
whenever sqlerror exit;

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE SPECIFICATIONS
select systimestamp from dual;

drop type wat_usr_contract_acct_obj_t force;
@@../cwms/types/wat_usr_contract_acct_obj_t


PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE BODIES
select systimestamp from dual;

@@../cwms/types/rating_ind_parameter_t-body
@@../cwms/types/rating_t-body

PROMPT ################################################################################
PROMPT UPDATING PACKAGE SPECIFICATIONS

@@../cwms/cwms_loc_pkg
@@../cwms/cwms_ts_pkg


PROMPT ################################################################################
PROMPT UPDATING PACKAGE BODIES
select systimestamp from dual;

define builduser = BUILDUSER
@@../cwms/cwms_level_pkg_body
@@../cwms/cwms_loc_pkg_body
@@../cwms/cwms_text_pkg_body
@@../cwms/cwms_ts_pkg_body
@@../cwms/cwms_ts_profile_pkg_body
@@../cwms/cwms_util_profile_pkg_body
@@../cwms/cwms_vt_pkg_body
@@../cwms/cwms_water_supply_pkg_body

PROMPT ################################################################################
PROMPT UPDATING TRIGGERS
select systimestamp from dual;


PROMPT ################################################################################
PROMPT FINAL HOUSEKEEPING
select systimestamp from dual;

declare
   cmd varchar2(128);
begin
   execute immediate 'grant CWMS_USER to CWMS_DBA';
   for rec in (select object_name,
                      object_type
                 from dba_objects
                where owner = '&cwms_schema'
                  and object_type in ('PACKAGE BODY', 'TYPE', 'VIEW')
                  and object_name not like '%AQ$%'
              )
   loop
      cmd := 'grant '
         ||case when rec.object_type = 'VIEW' then 'select' else 'execute' end
         ||' on &cwms_schema..'
         ||rec.object_name
         ||' to CWMS_USER';
      dbms_output.put(cmd||' [');
      begin
         execute immediate cmd;
         dbms_output.put_line('SUCCEEDED]');
      exception
         when others then dbms_output.put_line('FAILED]');
      end;   
   end loop;
end;
/
PROMPT ################################################################################
PROMPT RESTORING PRE-UPDATE PRIVILEGES
@@./util/restore_privs

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@@./util/compile_objects

promp ################################################################################
PROMPT REMAINING INVALID OBJECTS...
select systimestamp from dual;
select owner||'.'||substr(object_name, 1, 30) as invalid_object,
       object_type
  from all_objects
 where status = 'INVALID'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by 1, 2;
select owner||'.'||substr(name, 1, 30) as name,
       type,
       substr(line||':'||position, 1, 12) as location,
       substr(text, 1, 132) as error
  from all_errors
 where attribute = 'ERROR'
   and owner in ('&cwms_schema', '&cwms_dba_schema')
 order by owner, type, name, sequence;
/

whenever sqlerror exit;

PROMPT ################################################################################
PROMPT UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./26_02_17/update_db_change_log
select substr(version, 1, 10) as version,
       to_char(version_date, 'yyyy-mm-dd hh24:mi') as version_date,
       to_char(apply_date, 'yyyy-mm-dd hh24:mi') as apply_date
  from av_db_change_log
 where application = 'CWMS'
 order by version_date;
declare
   l_count pls_integer;
begin
   select count(*)
     into l_count
     from all_objects
    where status = 'INVALID'
      and owner in ('&cwms_schema', '&cwms_dba_schema');

   if l_count > 0 then
      raise_application_error(-20999, chr(10)||'==>'||chr(10)||'==> SOME OBJECTS ARE STILL INVALID'||chr(10)||'==>');
   end if;
end;
/
PROMPT ################################################################################
PROMPT UPDATE COMPLETE
select systimestamp from dual;
exit
