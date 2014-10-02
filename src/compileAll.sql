set echo off
set define on
whenever sqlerror exit sql.sqlcode
prompt Invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Recompiling all invalid objects...
exec sys.utl_recomp.recomp_serial('&cwms_schema');
--  Some of the packages/types don't compile first time
commit;
exec dbms_lock.sleep(10);
exec sys.utl_recomp.recomp_serial('&cwms_schema');
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

