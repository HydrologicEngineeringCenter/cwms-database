--------------------------------------------
-- verify that both the new tables exist  --
--------------------------------------------
declare
   l_schema_support number;
begin
   select count(*)
    into l_schema_support
    from ALL_TABLES
    where table_name = 'AT_FCST_SPEC'
      and OWNER = 'CWMS_20';
   if l_schema_support = 0 then
      cwms_err.raise('ERROR', 'Expected new forecast tables to exist.');
   end if;
end;
/
declare
   cursor c_forecasts is
      (select distinct forecast_id, source_office
      from at_forecast_spec);
   l_forecast_spec_code at_forecast_spec.forecast_spec_code%type;
   l_pattern varchar2(10) := '(.+)-(.+)';
   l_sort_order_support number;
   l_clob_value clob := empty_clob();
   l_blob_value blob := empty_blob();
   l_warning number;
   l_dest_offset number := 1;
   l_src_offset number := 1;
   l_lang_context number := dbms_lob.default_lang_ctx;
begin
   select COUNT(*)
   into l_sort_order_support
    from user_tab_columns
    where table_name = 'AT_FCST_LOCATION'
      and column_name = 'SORT_ORDER';
   for rec in c_forecasts loop
      select FORECAST_SPEC_CODE
      into l_forecast_spec_code
      from at_forecast_spec
      where forecast_id = rec.forecast_id
        and source_office = rec.source_office
         fetch first 1 rows only;
      -- insert into new spec table
      insert into at_fcst_spec
         select
            s.FORECAST_SPEC_CODE,
            cwms_util.GET_OFFICE_CODE(s.source_office),
            nvl(REGEXP_SUBSTR(s.forecast_id, l_pattern, 1, 1, 'i', 1), s.forecast_id),
            REGEXP_SUBSTR(s.forecast_id, l_pattern, 1, 1, 'i', 2),
            (select entity_code -- need to handle case where entity is not in at_entity
             from at_entity
             where entity_id = s.source_agency
               and office_code = cwms_util.GET_OFFICE_CODE('CWMS')),
            forecast_type
         from at_forecast_spec s
         where s.forecast_id = rec.forecast_id
         and s.source_office = rec.source_office
         and s.FORECAST_SPEC_CODE = l_forecast_spec_code;
      commit;
      -- insert into new location table using chosen spec code
      for row in (
         select distinct target_location_code
         from at_forecast_spec s
         where s.forecast_id = rec.forecast_id
           and s.source_office = rec.source_office
      ) loop
         -- check if schema supports new sort order column
         if l_sort_order_support = 0 then
            insert into at_fcst_location (fcst_spec_code, primary_location_code)
               values(l_forecast_spec_code,
                   row.target_location_code);
         else
            -- insert with sort order of 0
            execute immediate
               'insert into at_fcst_location (fcst_spec_code, location_code, sort_order)' ||
               'values (:1, :2, :3)'
               using l_forecast_spec_code, row.target_location_code, 0;
         end if;
      end loop;
      commit;
      -- insert into new ts table using chosen spec code
      for row in (
         select distinct t.ts_code
         from at_forecast_spec s
         join at_forecast_ts t
              on t.forecast_spec_code = s.forecast_spec_code
         where s.forecast_id = rec.forecast_id
           and s.source_office = rec.source_office
      ) loop
         insert into at_fcst_time_series
         values (l_forecast_spec_code,
                 row.ts_code);
         commit;
      end loop;
      commit;
      --insert into new fcst_inst table using chosen spec code
      for row in (
         select t.forecast_spec_code
         from at_forecast_spec s
              join at_forecast_ts t
                   on t.forecast_spec_code = s.forecast_spec_code
         where s.forecast_id = rec.forecast_id
           and s.source_office = rec.source_office
      ) loop
         for txt_row in (
            select txt.clob_code, txt.forecast_spec_code
                     from at_forecast_text txt
                          where txt.forecast_spec_code = row.forecast_spec_code
         ) loop
            select value
               into l_clob_value
               from at_clob
               where clob_code = txt_row.clob_code;
            dbms_lob.createtemporary(l_blob_value, true);
            dbms_lob.converttoblob(dest_lob => l_blob_value,
               src_clob => l_clob_value,
               amount => 1,
               dest_offset => l_dest_offset,
               src_offset => l_src_offset,
               blob_csid => dbms_lob.default_csid,
               lang_context => l_lang_context,
               warning => l_warning
            );

            insert into at_fcst_inst
            select
               cwms_seq.nextval,
               l_forecast_spec_code,
               t.forecast_date,
               nvl(t.version_date, t.issue_date),
               s.max_age,
               null,
               cwms_t_blob_file(
                  (select id
                      from at_clob
                      where clob_code = txt.clob_code) || '.txt',
                  'text/plain', 0,
                  (select description
                   from at_clob
                   where clob_code = txt.clob_code),
                  l_blob_value)
            from at_forecast_spec s
                    join at_forecast_ts t
                         on t.forecast_spec_code = s.forecast_spec_code
                    join CWMS_20.at_forecast_text txt
                         on txt.forecast_spec_code = s.forecast_spec_code
            where s.forecast_id = rec.forecast_id
            and s.source_office = rec.source_office
            and txt.clob_code = txt_row.clob_code;
            commit;
         end loop;
      end loop;
      commit;
   end loop;
   commit;
end;