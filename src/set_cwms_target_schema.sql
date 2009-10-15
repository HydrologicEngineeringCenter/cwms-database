set echo off
set define on
prompt
define target = &target_schema
prompt
set time on
set echo on
whenever sqlerror continue
drop user cwms cascade;
whenever sqlerror exit sql.sqlcode
create user cwms identified by f0e9d8c7b6a59687;
declare
   stmt varchar2(128);
begin   
   for rec in (select distinct * from dba_objects where owner=upper('&target') order by object_name) loop
      stmt :=
         'create or replace synonym CWMS.'
         || rec.object_name
         || ' for &target'
         || '.'
         || rec.object_name;
      dbms_output.put_line('-- ' || stmt);         
      execute immediate stmt;
   end loop;
end;
/


