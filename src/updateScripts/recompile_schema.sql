declare
   obj_count integer;
begin
   for i in 1..&2 loop
      select count(*)
        into obj_count
        from dba_objects
       where owner = '&1'
         and status = 'INVALID';
         
      exit when obj_count = 0;         
      sys.utl_recomp.recomp_serial('&1');
   end loop;
end;
/

