-- &1 : schema name
-- &2 : "abort" (case insensitive) -> aborts if invalid objects found
--    : other                      -> continues anyway      
select substr(object_name, 1, 31) "INVALID OBJECT", object_type
  from dba_objects
 where owner = '&1'
   and status = 'INVALID'
 order by object_name, object_type asc;

declare
   obj_count integer;
begin
   select count(*)
     into obj_count
     from dba_objects
    where owner = '&1'
      and status = 'INVALID';
   dbms_output.put_line('' || obj_count || ' objects are invalid.');
   if obj_count > 0 and upper('&2') = 'ABORT' then
      raise_application_error(-20999, 'Aborting on invalid objects');
   end if;
end;
/

