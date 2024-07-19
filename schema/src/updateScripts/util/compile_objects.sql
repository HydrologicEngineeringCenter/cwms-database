declare
   l_cmd   varchar2(128);
   l_count binary_integer;
begin
   for i in 1..5 loop
      l_count := 0;
      ----------------------------
      -- package and type specs --
      ----------------------------
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
            l_cmd := 'create or replace public synonym '||c.object_name||' for &cwms_schema..'||c.object_name;
            execute immediate l_cmd;
         end if;
         if c.status = 'INVALID' then
            l_count := l_count + 1;
            l_cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile '||c.object_type;
            dbms_output.put_line (l_cmd);
            begin
               execute immediate l_cmd;
            exception
               when others then null;
            end;
         end if;
      end loop;
      -----------------------------
      -- package and type bodies --
      -----------------------------
      for c in (select owner,
                       object_name,
                       regexp_substr(object_type, '\S+') as object_type,
                       status
                  from dba_objects
                 where owner in ('&cwms_schema', '&cwms_dba_schema')
                   and object_type in ('PACKAGE BODY', 'TYPE BODY')
                   and status <> 'VALID')
      loop
         if c.status = 'INVALID' then
            l_count := l_count + 1;
            l_cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile body';
            dbms_output.put_line (l_cmd);
            begin
               execute immediate l_cmd;
            exception
               when others then null;
            end;
         end if;
      end loop;
      --------------------------------------------------------
      -- views, materialized views, triggers, and functions --
      --------------------------------------------------------
      for c in (select owner,
                       object_name,
                       object_type,
                       status
                  from dba_objects
                 where owner in ('&cwms_schema', '&cwms_dba_schema')
                   and object_type in ('VIEW','MATERIALIZED VIEW','TRIGGER','PROCEDURE','FUNCTION')
                   and status <> 'VALID')
      loop
         if c.status = 'INVALID' then
            l_count := l_count + 1;
            l_cmd := 'alter '||c.object_type||' '||c.owner||'.'||c.object_name||' compile';
            dbms_output.put_line (l_cmd);
            begin
               execute immediate l_cmd;
            exception
               when others then null;
            end;
         end if;   
      end loop;
      exit when l_count = 0;
   end loop;   
end;
/
