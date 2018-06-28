set verify off
declare
   obj_count integer;
   loop_count pls_integer := to_number('&2');
begin
   for i in 1..loop_count loop
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

