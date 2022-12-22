set serveroutput on
declare
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
      dbms_output.put_line (cmd);
      execute immediate cmd;
   end loop;
   for c in (select owner,
                    object_name,
                    regexp_substr(object_type, '\S+') as object_type
               from dba_objects
              where owner = 'CWMS_20'
                and object_type in ('PACKAGE BODY', 'TYPE BODY'))
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile debug body';
      dbms_output.put_line (cmd);
      execute immediate cmd;
   end loop;
   for c in (select owner,
                    object_name,
                    object_type
               from dba_objects
              where owner = 'CWMS_20'
                and object_type in ('TRIGGER','PROCEDURE','FUNCTION')
                and status <> 'VALID')
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile debug';
      dbms_output.put_line (cmd);
      execute immediate cmd;
   end loop;
end;
/
