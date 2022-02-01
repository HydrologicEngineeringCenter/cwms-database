DROP PROFILE cwms_prof cascade;
drop role cwms_user;

begin
   for rec in (select object_name
                 from dba_objects
                where owner = '${CWMS_SCHEMA}'
                  and object_type = 'TYPE'
                  and object_name not like 'SYS\_%' escape '\'
             order by object_name)
   loop
      dbms_output.put_line('Dropping type '||rec.object_name);
      execute immediate 'drop type '||rec.object_name||' force';
   end loop;
end;