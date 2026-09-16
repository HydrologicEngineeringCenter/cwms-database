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
define logfile=update_&db_name._latlon_to_geometry.log
PROMPT log file = &logfile
spool &logfile append;
-------------------
-- do the update --
-------------------
PROMPT ################################################################################
PROMPT SAVING PRE-UPDATE PRIVILEGES
select systimestamp from dual;
@@./util/preupdate_privs.sql;

PROMPT ################################################################################
PROMPT CREATING NEW TABLES
select systimestamp from dual;

@@../cwms/tables/at_location_geometry
@@../cwms/tables/at_location_geometry_sidx

declare
   l_lines str_tab_t;
begin
   select text
     bulk collect
     into l_lines
     from user_source
    where name = 'ST_PHYSICAL_LOCATION'
    order by line;

   execute immediate
      'create or replace '
      ||replace(cwms_util.join_text(l_lines, null), 'PHYSICAL_LOCATION', 'LOCATION_GEOMETRY');
end;
/

PROMPT ################################################################################
PROMPT MOVE EXISTING LAT/LONGS TO GEOMETRY
select systimestamp from dual;

@@./latlon_to_geometry/move_lat_longs_to_geometry

PROMPT ################################################################################
PROMPT ALTERING TABLES
select systimestamp from dual;

PROMPT ################################################################################
PROMPT ALTERING TABLES
select systimestamp from dual;

alter table at_physical_location drop column longitude;
alter table at_physical_location drop column latitude;
drop trigger at_physical_location_t02;

@@./latlon_to_geometry/at_physical_location_t03

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE SPECIFICATIONS
select systimestamp from dual;

drop type location_obj_t force;
@@../cwms/types/location_obj_t

PROMPT ################################################################################
PROMPT CREATING AND ALTERING TYPE BODIES
select systimestamp from dual;

@@../cwms/types/location_obj_t-body

PROMPT ################################################################################
PROMPT CREATING AND ALTERING VIEWS
select systimestamp from dual;

delete from at_clob where id in ('/VIEWDOCS/AV_LOC','/VIEWDOCS/AV_LOC2');
@@../cwms/views/av_loc
@@../cwms/views/av_loc2

PROMPT ################################################################################
PROMPT UPDATING PACKAGE SPECIFICATIONS
select systimestamp from dual;
@@../cwms_loc_pkg

PROMPT ################################################################################
PROMPT UPDATING PACKAGE BODIES
select systimestamp from dual;

@@../cwms/cwms_cat_pkg_body
@@../cwms/cwms_embank_pkg_body
@@../cwms/cwms_loc_pkg_body
@@../cwms/cwms_lock_pkg_body
@@../cwms/cwms_project_pkg_body

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
select systimestamp from dual;
@@./util/restore_privs

PROMPT ################################################################################
PROMPT RECOMPILING SCHEMA
select systimestamp from dual;
@./util/compile_objects

PROMPT ################################################################################
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
PROMPT OUTPUT LATLON CONVERSION RESULTS
select systimestamp from dual;

declare
   l_notes  str_tab_t;
   l_counts number_tab_t;
begin
   dbms_output.put_line('Latitude/Longitude to Geometry Conversion Results');
   dbms_output.put_line('================================================================================');
   select conversion_note, count(location_code)
     bulk collect
     into l_notes, l_counts
     from at_latlon_conversion
    group by conversion_note
    order by 2 desc;
   for i in 1..l_notes.count loop
      dbms_output.put_line(to_char(l_counts(i), 99999)||' locations'||chr(9)||l_notes(i));
   end loop;
   dbms_output.put_line(chr(10)||'See table AT_LATLON_CONVERSION for details');
end;
/

PROMPT ################################################################################
PROMPT UPDATE COMPLETE
select systimestamp from dual;
exit
