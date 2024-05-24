set serveroutput on
whenever sqlerror continue
declare
   l_count           pls_integer;
   l_table_exists    boolean;
   l_current_table   boolean;
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
    where owner = 'CWMS_20'
      and table_name = 'AT_TSV_COUNT';

   l_table_exists := l_count = 1;

   if l_table_exists then
      select count(*)
        into l_count
        from all_tab_columns
       where owner = 'CWMS_20'
         and table_name = 'AT_TSV_COUNT';

      l_current_table := l_count = 7;
   end if;
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
end;
/
