set serveroutput on
declare
   do_execute boolean := false;
   cmd varchar2(128);
begin
   for c in (select owner,
                    object_name,
                    object_type,
                    status
               from dba_objects
             where owner = 'CWMS_20'
               and object_type in ('PACKAGE', 'TYPE'))
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile debug specification';
      if do_execute then
         execute immediate cmd;
      else
         dbms_output.put_line (cmd||';');
      end if;
   end loop;
   for c in (select owner,
                    object_name,
                    regexp_substr(object_type, '\S+') as object_type
               from dba_objects
              where owner = 'CWMS_20'
                and object_type in ('PACKAGE BODY', 'TYPE BODY'))
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile debug body';
      if do_execute then
         execute immediate cmd;
      else
         dbms_output.put_line (cmd||';');
      end if;
   end loop;
   for c in (select owner,
                    object_name,
                    object_type
               from dba_objects
              where owner = 'CWMS_20'
                and object_type in ('TRIGGER','PROCEDURE','FUNCTION'))
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile debug';
      if do_execute then
         execute immediate cmd;
      else
         dbms_output.put_line (cmd||';');
      end if;
   end loop;
end;
/
