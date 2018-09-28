declare
   trigger_text varchar2(4000) := '
create or replace trigger :table_name_DDF
   before insert or update
   on :table_name
   for each row
begin
   if inserting or updating then 
      :new.dest_flag := cwms_data_dissem.get_dest(:new.ts_code);
   end if;
exception
   -- silently fail
   when others then null;
end;';
begin
   for rec in 
      (select table_name 
         from user_tables t
        where regexp_like (t.table_name, '^AT_TSV(_(\d{4}|ARCHIVAL|INF_AND_BEYOND))?$')
          and 6 = (select max(column_id) from user_tab_columns where table_name = t.table_name)
      )
   loop
      execute immediate 'alter table '||rec.table_name||' add dest_flag number(1)';
      begin
         execute immediate replace(trigger_text, ':table_name', rec.table_name);
      exception
         when others then null;
      end;   
   end loop;
   commit;
end;
/
