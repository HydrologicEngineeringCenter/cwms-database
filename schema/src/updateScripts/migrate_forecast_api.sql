--------------------------------------------
-- verify that both the new tables exist  --
--------------------------------------------
declare
   l_schema_support number;
begin
   -- verify that the new tables exist
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
   l_sort_order_support number;
   l_new_spec at_fcst_spec%rowtype;
   l_new_inst at_fcst_inst%rowtype;
   l_clob clob;
   l_blob blob;
   l_src_offset integer;
   l_dst_offset integer;
   l_lang_ctx integer;
   l_warning integer;
   l_ts_row at_forecast_ts%rowtype;
   l_ts_start date;
   l_ts_end date;
   l_count number;
begin
   -- determine which forecast location table schema is available
   select COUNT(*)
   into l_sort_order_support
    from user_tab_columns
    where table_name = 'AT_FCST_LOCATION'
      and column_name = 'SORT_ORDER';
   -- loop through all forecasts
   for old_spec in (select * from at_forecast_spec) loop
      -- create new forecast spec code
      l_new_spec.fcst_spec_code := cwms_seq.nextval;
      -----------------------
      -- populate new spec --
      -----------------------
      select bl.db_office_code
      into l_new_spec.office_code
      from at_base_location bl,
           at_physical_location pl
      where pl.location_code = old_spec.target_location_code
        and bl.base_location_code = pl.base_location_code;
      l_new_spec.fcst_spec_id := old_spec.forecast_id;
      l_new_spec.fcst_designator := old_spec.forecast_type;
      if l_new_spec.fcst_designator is not null then
         l_new_spec.fcst_designator := l_new_spec.fcst_designator||'-';
      end if;
      l_new_spec.fcst_designator := l_new_spec.fcst_designator||cwms_loc.get_location_id(old_spec.target_location_code);
      case old_spec.source_agency
         when 'USACE' then
            select entity_code
            into l_new_spec.source_entity
            from at_entity
            where entity_id = 'CE'||old_spec.source_office;
         end case;
      insert into at_fcst_spec values l_new_spec;
      commit;
      --------------------------
      -- populate new inst(s) --
      --------------------------
      for old_ts in (select distinct forecast_date,
                                     issue_date
                     from at_forecast_ts
                     where forecast_spec_code = old_spec.forecast_spec_code
         )
         loop
            if (old_ts.issue_date != old_ts.forecast_date) then
               select *
                  into l_ts_row
                  from at_forecast_ts
                  where forecast_spec_code = old_spec.forecast_spec_code
                    and forecast_date = old_ts.forecast_date
                    and issue_date = old_ts.issue_date
                  fetch next 1 row only;
               select min(start_date), max(END_DATE)
                  into l_ts_start, l_ts_end
                  from av_tsv
                  where ts_code = l_ts_row.ts_code;
               cwms_ts.CHANGE_VERSION_DATE(l_ts_row.ts_code, l_ts_row.version_date, old_ts.issue_date, l_ts_start, l_ts_end);
            end if;
            l_new_inst.fcst_inst_code := cwms_seq.nextval;
            l_new_inst.fcst_spec_code := l_new_spec.fcst_spec_code;
            l_new_inst.fcst_date_time := old_ts.forecast_date;
            l_new_inst.issue_date_time := old_ts.issue_date;
            l_new_inst.max_age := old_spec.max_age;
            begin
               select value
               into l_clob
               from at_clob
               where clob_code = (select clob_code
                                  from at_forecast_text
                                  where forecast_spec_code = old_spec.forecast_spec_code
                                    and forecast_date = old_ts.forecast_date
                                    and issue_date = old_ts.issue_date
               );
            exception
               when no_data_found then l_clob := null;
            end;
            if l_clob is not null then
               dbms_lob.createtemporary(l_blob, true);
               l_src_offset := 1;
               l_dst_offset := 1;
               l_lang_ctx   := dbms_lob.default_lang_ctx;

               dbms_lob.converttoblob(
                  dest_lob     => l_blob,
                  src_clob     => l_clob,
                  amount       => dbms_lob.lobmaxsize,
                  dest_offset  => l_dst_offset,
                  src_offset   => l_src_offset,
                  blob_csid    => dbms_lob.default_csid,
                  lang_context => l_lang_ctx,
                  warning      => l_warning);

               l_new_inst.blob_file := blob_file_t(
                  filename     => 'forecast.txt',
                  media_type   => 'text/plain',
                  quality_code => null,
                  the_blob     => l_blob);
            end if;
            insert into at_fcst_inst values l_new_inst;
            commit;
         end loop;
      ------------------------------
      -- insert into new ts table --
      ------------------------------
      for ts_row in (
         select distinct t.ts_code
            from at_forecast_ts t
            where t.forecast_spec_code = old_spec.forecast_spec_code
      ) loop
            select count(*)
            into l_count
            from at_fcst_time_series ts
            where ts.fcst_spec_code = l_new_spec.fcst_spec_code
              and ts.ts_code = ts_row.ts_code;
         if l_count = 0 then
            insert into at_fcst_time_series
            values (l_new_spec.fcst_spec_code,
                    ts_row.ts_code);
            commit;
         end if;
      end loop;
      ---------------------------
      -- populate new location --
      ---------------------------
      -- check if schema supports new sort order column
      if l_sort_order_support = 0 then
         insert into at_fcst_location values (l_new_spec.fcst_spec_code, old_spec.target_location_code);
      else
         -- insert with sort order of 0
         execute immediate
            'insert into at_fcst_location (fcst_spec_code, location_code, sort_order)' ||
            'values (:1, :2, :3)'
            using l_new_spec.fcst_spec_code, old_spec.target_location_code, 0;
      end if;
      commit;
   end loop;
   commit;
end;