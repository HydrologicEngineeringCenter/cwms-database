define cwms_schema = CWMS_20
set define on
set verify off
--------------------------------------------
-- verify that both the new tables exist  --
--------------------------------------------
begin
   if (select count(*) from ALL_TABLES where table_name = 'AT_FCST_SPEC' and OWNER = cwms_schema) = 0 then
      cwms_err.raise('ERROR', 'Expected new forecast tables to exist.');
   end if;
end;
/
declare
begin
   insert into at_fcst_spec
      select
         s.FORECAST_SPEC_CODE,
         cwms_util.GET_OFFICE_CODE(s.source_office),
         s.forecast_id,
         null,
         (select entity_code -- need to handle case where entity is not in at_entity
            from at_entity
            where entity_id = s.source_agency
              and office_code = cwms_util.GET_OFFICE_CODE('CWMS')),
         forecast_type
      from at_forecast_spec s;
   commit;
   insert into at_fcst_location
      select
         s.forecast_spec_code,
         s.target_location_code
      from at_forecast_spec s;
   commit;
   insert into at_fcst_time_series
      select
         s.forecast_spec_code,
         s.ts_code
      from at_forecast_spec s;
   commit;
   insert into at_fcst_inst
      select
         DEFAULT,
         s.forecast_spec_code,
         t.forecast_date,
         (case when t.issue_date is not null then t.issue_date else t.version_date end),
         s.max_age,
         null,
         (select value from at_clob where clob_code = txt.clob_code)
      from at_forecast_spec s
         join at_forecast_ts t
            on t.forecast_spec_code = s.forecast_spec_code
                  and t.ts_code = s.ts_code
         join CWMS_20.at_forecast_text txt
            on txt.forecast_spec_code = s.forecast_spec_code
                  and txt.ts_code = s.ts_code;
   commit;
end;