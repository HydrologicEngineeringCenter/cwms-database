declare
   l_sel   varchar2 (120);
   l_sql   varchar2 (8000);

   cursor c1 is select * from at_ts_table_properties;
begin
   l_sql := 'create or replace force view av_tsv as ';
   l_sel := 'select ts_code, date_time, version_date, data_entry_date, value, quality_code, date ''';

   for rec in c1 loop
      if c1%rowcount > 1 then
         l_sql := l_sql || ' union all ';
      end if;
      l_sql :=
            l_sql
         || l_sel
         || to_char (rec.start_date, 'yyyy-mm-dd')
         || ''' as start_date, date '''
         || to_char (rec.end_date, 'yyyy-mm-dd')
         || ''' as end_date from '
         || rec.table_name;
   end loop;

   execute immediate l_sql;
end;
/