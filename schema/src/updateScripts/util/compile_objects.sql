declare
   cmd varchar2(128);
begin
   for c in (select owner,
                    object_name,
                    object_type,
                    status
               from dba_objects
             where owner in ('&cwms_schema', '&cwms_dba_schema')
               and object_type in ('PACKAGE', 'TYPE'))
   loop
      if c.owner = '&cwms_schema' and c.object_type = 'PACKAGE' then
         continue when c.object_name in ('CWMS_SEC_POLICY', 'CWMS_UPASS');
         cmd := 'create or replace public synonym '||c.object_name||' for &cwms_schema..'||c.object_name;
         execute immediate cmd;
      end if;
      if c.status = 'INVALID' then
         cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile '||c.object_type;
         dbms_output.put_line (cmd);
         begin
            execute immediate cmd;
         exception
            when others then null;
         end;
      end if;
   end loop;
   for c in (select owner,
                    object_name,
                    regexp_substr(object_type, '\S+') as object_type
               from dba_objects
              where owner in ('&cwms_schema', '&cwms_dba_schema')
                and object_type in ('PACKAGE BODY', 'TYPE BODY')
                and status <> 'VALID')
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile body';
      dbms_output.put_line (cmd);
         begin
            execute immediate cmd;
         exception
            when others then null;
         end;
   end loop;
   for c in (select owner,
                    object_name,
                    object_type
               from dba_objects
              where owner in ('&cwms_schema', '&cwms_dba_schema')
                and object_type in ('VIEW','MATERIALIZED VIEW','TRIGGER','PROCEDURE','FUNCTION')
                and status <> 'VALID')
   loop
      cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile';
      dbms_output.put_line (cmd);
         begin
            execute immediate cmd;
         exception
            when others then null;
         end;
   end loop;
end;
/
