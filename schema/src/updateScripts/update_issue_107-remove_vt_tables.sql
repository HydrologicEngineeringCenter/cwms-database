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
define logfile=update_&db_name._issue_107.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql;

@@../cwms/cwms_ts_pkg_body

drop package cwms_vt;

drop view av_screened_ts_ids;
drop view av_screening_assignments;
drop view av_screening_control;
drop view av_screening_criteria;
drop view av_screening_dur_mag;
drop view av_screening_id;

drop table at_screening_control;
drop table at_screening_criteria;
drop table at_screening_dur_mag;
drop table at_screening_id;

drop type screening_control_t force;
drop type screen_assign_array force;
drop type screen_assign_t force;
drop type screen_crit_array force;
drop type screen_crit_type force;
drop type screen_dur_mag_array force;
drop type screen_dur_mag_type force;
drop type tr_template_set_array force;
drop type tr_template_set_type force;

drop public synonym cwms_t_screening_control;
drop public synonym cwms_t_screen_assign;
drop public synonym cwms_t_screen_assign_array;
drop public synonym cwms_t_screen_crit;
drop public synonym cwms_t_screen_crit_array;
drop public synonym cwms_t_screen_dur_mag;
drop public synonym cwms_t_screen_dur_mag_array;
drop public synonym cwms_t_tr_template_set;
drop public synonym cwms_t_tr_template_set_array;
drop public synonym cwms_vt;
drop public synonym cwms_v_screened_ts_ids;
drop public synonym cwms_v_screening_assignments;
drop public synonym cwms_v_screening_control;
drop public synonym cwms_v_screening_criteria;
drop public synonym cwms_v_screening_dur_mag;
drop public synonym cwms_v_screening_id;

delete
  from at_clob
 where id in ('/VIEWDOCS/AV_SCREENED_TS_IDS',
              '/VIEWDOCS/AV_SCREENING_ASSIGNMENTS',
              '/VIEWDOCS/AV_SCREENING_CONTROL',
              '/VIEWDOCS/AV_SCREENING_CRITERIA',
              '/VIEWDOCS/AV_SCREENING_DUR_MAG',
              '/VIEWDOCS/AV_SCREENING_ID'
             );


PROMPT ################################################################################
PROMPT FINAL HOUSEKEEPING
select systimestamp from dual;
declare
   type usernames_t is table of varchar2(30);
   usernames usernames_t;
   l_count integer;
   cmd varchar2(128);
begin
   select count(*) into l_count from dba_users where username='CCP';
   usernames := usernames_t('&cwms_schema', '&cwms_dba_schema');
   if (l_count > 0) then
      usernames.extend;
      usernames(usernames.count) := 'CCP';
   end if;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'PACKAGE BODY') loop
      cmd := 'grant execute on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'TYPE') loop
      cmd := 'grant execute on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
   for rec in (select object_name from dba_objects where owner = '&cwms_schema' and object_type = 'VIEW' and object_name not like '%AQ$%') loop
      cmd := 'grant select on &cwms_schema..'||rec.object_name||' to ';
      dbms_output.put(cmd||'[');
      for i in 1..usernames.count loop
         begin
            execute immediate(cmd||usernames(i));
            dbms_output.put(' '||usernames(i)||'(SUCCESS)');
         exception
            when others then
               dbms_output.put(' '||usernames(i)||'(FAILED)');
         end;
      end loop;
      dbms_output.put_line(' ]');
   end loop;
end;
/
PROMPT ################################################################################
PROMPT RESTORING PRE-UPDATE PRIVILEGES
@@./util/restore_privs

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects

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
PROMPT ################################################################################
PROMPT UPDATE COMPLETE
select systimestamp from dual;
exit
