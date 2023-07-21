-------------------------------------------------------------------------
-- the build-from-scratch process calls this script twice:             --
--   * once before the cwms_tsv package exists (to create the table)   --
--   * once after the cwms_tsv package exists (to create the triggers) --
--                                                                     --
-- an update script updating from schema 23.03.16 should call it once  --
-------------------------------------------------------------------------
set serveroutput on
whenever sqlerror continue
declare
   l_count           pls_integer;
   l_table_exists    boolean;
   l_current_table   boolean;
   l_current_package boolean;
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
   ---------------------------
   -- drop any old triggers --
   ---------------------------
   for rec in (select trigger_name from user_triggers where trigger_name like 'AT\_TSV\_%\_AIUDR' escape '\') loop
      execute immediate 'drop trigger '||rec.trigger_name;
   end loop;
   --------------------------------------------------------------------
   -- determine whether the at_tsv_count table exists and is current --
   --------------------------------------------------------------------
   select count(*)
     into l_count
     from all_tables
    where owner = '&cwms_schema'
      and table_name = 'AT_TSV_COUNT';

   l_table_exists := l_count = 1;

   if l_table_exists then
      select count(*)
        into l_count
        from all_tab_columns
       where owner = '&cwms_schema'
         and table_name = 'AT_TSV_COUNT';

      l_current_table := l_count = 7;
   end if;
   ------------------------------------------------------------------
   -- determine whether the cwms_tsv package exists and is current --
   ------------------------------------------------------------------
   select count(*)
     into l_count
     from all_source
    where owner = '&cwms_schema'
      and name = 'CWMS_TSV'
      and type = 'PACKAGE'
      and upper(text) like '%DML_INSERT%';
   l_current_package := l_count > 0;
   -----------------------------------------------
   -- drop and/or create the table as necessary --
   -----------------------------------------------
   if l_table_exists and not l_current_table then
      execute immediate 'drop table at_tsv_count purge';
      l_table_exists := false;
   end if;
   if not l_table_exists then
      execute immediate '
         create table at_tsv_count
          (data_entry_date timestamp   constraint at_tsvc_data_entry_date_nn NOT NULL,
           inserts         number(7,0) constraint at_tsvc_inserts_nn NOT NULL,
           updates         number(7,0) constraint at_tsvc_updates_nn NOT NULL,
           deletes         number(7,0) constraint at_tsvc_deletes_nn NOT NULL,
           s_inserts       number(7,0) DEFAULT 0,
           s_updates       number(7,0) DEFAULT 0,
           s_deletes       number(7,0) DEFAULT 0,
           constraint at_tsv_count_pk primary key (data_entry_date)
          )
         organization index
         nocompress
         tablespace CWMS_20DATA';
   end if;
   if l_current_package then
      -----------------------------------
      -- create the DML count triggers --
      -----------------------------------
      begin
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
               trig_owner => '&cwms_schema',
               trig_name  => l_trigger_name,
               property   => dbms_ddl.fire_once,
               setting    => false);
         end loop;
      end;
      --------------------------------------------------------------------------------
      -- create logoff triggers to flush counts to table when the session is closed --
      --------------------------------------------------------------------------------
      l_trigger_sql := '
         create or replace trigger :x_FLUSH_TSV_DML_COUNTS_ON_LOGOFF
         BEFORE LOGOFF on :x.SCHEMA
         BEGIN cwms_tsv.flush; END;';
      begin
         for rec in (select username,
                            null as rolename
                       from all_users
                      where username like '__DCS___'
                         or username like '__CWPA___'
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
   end if;
end;
/

