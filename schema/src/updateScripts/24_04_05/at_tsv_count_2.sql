set serveroutput on
whenever sqlerror continue
declare
   l_trigger_name    varchar2(30);
   l_trigger_sql     varchar2(1024);
   l_sql             varchar2(1024) := '
      create or replace TRIGGER :trigger_name
      AFTER INSERT OR UPDATE OR DELETE ON :table_name
      FOR EACH ROW
      DECLARE
      BEGIN
         -- count inserts, updates and deletes using the cwms_tsv package

         if INSERTING then
            cwms_tsv.count(cwms_tsv.DML_INSERT);
         elsif UPDATING then
            cwms_tsv.count(cwms_tsv.DML_UPDATE);
         elsif DELETING then
            cwms_tsv.count(cwms_tsv.DML_DELETE);
         end if;

      EXCEPTION
         -- silently fail
         WHEN OTHERS THEN NULL;
      END;';
begin
   -----------------------------------
   -- create the DML count triggers --
   -----------------------------------
   for rec in (select * from at_ts_table_properties) loop
      l_trigger_name := rec.table_name||'_COUNT';
      l_trigger_sql := replace(l_sql, ':table_name', rec.table_name);
      l_trigger_sql := replace(l_trigger_sql,':trigger_name', l_trigger_name);
      execute immediate l_trigger_sql;
      -- FIRE_ONCE YES = only local DML fires the trigger
      --           NO  = local and GoldenGate Apply DML will fire the trigger
      --
      -- APPLY_SERVER_ONLY overrides FIRE_ONCE.
      --           YES = only GoldenGate Apply DML will fire the trigger
      --           NO  = FIRE_ONCE controls trigger firing
      dbms_ddl.set_trigger_firing_property(
         trig_owner => 'CWMS_20',
         trig_name  => l_trigger_name,
         property   => dbms_ddl.fire_once,
         setting    => false);
   end loop;
   --------------------------------------------------------------------------------
   -- create logoff triggers to flush counts to table when the session is closed --
   --------------------------------------------------------------------------------
   l_trigger_sql := '
      create or replace trigger :x_FLUSH_TSV_DML_COUNTS_ON_LOGOFF
      BEFORE LOGOFF on :x.SCHEMA
      BEGIN cwms_tsv.flush; END;';
   for rec in (select username,
                      null as rolename
                 from all_users
                where username like '__DCS___'
                   or username like '__CWPA__'
                   or username = 'CWMS_STR_ADM'
               union
               select grantee as username,
                      granted_role as rolename
                 from dba_role_privs
                where granted_role = 'CWMS_USER'
              )
   loop
      -- create the LOGOFF trigger
      execute immediate replace(l_trigger_sql,':x',rec.username);
      if rec.rolename is null then
         -- grant execute on the count package
         execute immediate 'grant execute on cwms_tsv to '||rec.username;
      end if;
   end loop;
end;
/
