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
define logfile=update_&db_name._22_1_2_to_22_2_1.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT VERIFYING EXPECTED VERSION
select systimestamp from dual;
@@./22_2_1/verify_db_version

PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql

PROMPT ################################################################################
PROMPT UPDATING TABLES
select systimestamp from dual;
insert into at_unit_alias values ('DEGC-D', 53, 123);
insert into at_unit_alias values ('DEGF-D', 53, 124);
insert into at_unit_alias values ('FT/S',   53,  41);
insert into at_unit_alias values ('MG/L',   53,  51);

@@./22_2_1/migrate_ts_dissemination

create or replace trigger at_vloc_level_constituent_t01
   before insert or update of constituent_abbr, constituent_name, constituent_type
   on at_vloc_lvl_constituent
   for each row
declare
   l_parts str_tab_t;
   l_pos   pls_integer;
begin
   if substr(:new.constituent_abbr, 1, 1) != substr(:new.constituent_type,1 , 1) then
      cwms_err.raise('ERROR', 'Constituent abbreviation must start with the same letter as constituent type');
   end if;
   case :new.constituent_type
   when 'LOCATION_LEVEL' then
      l_parts := cwms_util.split_text(:new.constituent_name, '.');
      if l_parts.count != 5 then
         cwms_err.raise('ERROR', 'Constituent name is not a valid location level identifier');
      end if;
   when 'RATING' then
      l_parts := cwms_util.split_text(:new.constituent_name, '.');
      if l_parts.count != 4 or instr(l_parts(2), ';') = 0 then
         cwms_err.raise('ERROR', 'Constituent name is not a valid rating specification');
      end if;
   when 'TIME_SERIES' then
      l_parts := cwms_util.split_text(:new.constituent_name, '.');
      if l_parts.count != 6 then
         cwms_err.raise('ERROR', 'Constituent name is not a valid time series identifier');
      end if;
   when 'FORMULA' then
      begin
         l_pos := regexp_instr(:new.constituent_name, '{.+?(,.+?)*;.+}');
         l_parts := cwms_util.tokenize_expression(substr(:new.constituent_name, 1, l_pos-1));
      exception
         when others then
            cwms_err.raise('ERROR', 'Constituent name is not a valid formula');
      end;
   else cwms_err.raise('ERROR', 'Constituent type must be one of ''LOCATION_LEVEL'', ''RATING'', ''TIME_SERIES'', or ''FORMULA''');
   end case;
end at_vloc_level_constituent_t01;
/

PROMPT ################################################################################
PROMPT UPDATING VIEWS
select systimestamp from dual;
delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL_CURVAL';
@../cwms/views/av_location_level_curval

PROMPT ################################################################################
PROMPT UPDATING PACKAGE SPECIFICATIONS
select systimestamp from dual;
@../cwms/cwms_sec_policy
@../cwms/cwms_level_pkg
@../cwms/cwms_util_pkg
@../cwms/cwms_data_dissem_pkg

PROMPT ################################################################################
PROMPT UPDATING TYPE SPECIFICATIONS
select systimestamp from dual;
drop type rating_t force;
@../cwms/types/rating_t

PROMPT ################################################################################
PROMPT UPDATING PACKAGE BODIES
select systimestamp from dual;
@../cwms/cwms_level_pkg_body
@../cwms/cwms_sec_pkg_body
@../cwms/cwms_sec_policy_body
@../cwms/cwms_ts_pkg_body
@../cwms/cwms_util_pkg_body
@../cwms/cwms_data_dissem_pkg_body

PROMPT ################################################################################
PROMPT UPDATING TYPE BODIES
select systimestamp from dual;
@../cwms/types/rating_t-body

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

whenever sqlerror exit;

PROMPT ################################################################################
PROMPT UPDATING DB_CHANGE_LOG
select systimestamp from dual;
@@./22_2_1/update_db_change_log
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
