create or replace package test_cwms_forecast as

--%suite(Test cwms_forecast package code)
--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test CWDB-132 - make sure forecast views show time-series for locations other than forecast location)
procedure cwdb_132_forecast_views_too_restrictive;

procedure setup;
procedure teardown;

c_fcst_id     constant cwms_v_forecast.forecast_id%type := 'CWDB132_TEST FORECAST';
c_fcst_loc_id constant cwms_v_loc.location_id%type  := 'CWDB132_Fcst_Loc';
c_us_loc_id   constant cwms_v_loc.location_id%type  := 'CWDB132_US_Loc';
c_ds_loc_id   constant cwms_v_loc.location_id%type  := 'CWDB132_DS_Loc';
c_office_id   constant cwms_v_loc.db_office_id%type := '&&office_id';
g_location_ids cwms_t_str_tab := cwms_t_str_tab(
                                    c_fcst_loc_id,
                                    c_us_loc_id,
                                    c_ds_loc_id);

end test_cwms_forecast;
/
show errors
create or replace package body test_cwms_forecast as
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   x_item_does_not_exist   exception;
   x_location_id_not_found exception;
   pragma exception_init(x_item_does_not_exist,   -20034);
   pragma exception_init(x_location_id_not_found, -20025);
begin
   begin
      cwms_forecast.delete_spec(
         p_location_id   => c_fcst_loc_id,
         p_forecast_id   => c_fcst_id,
         p_delete_action => cwms_util.delete_all,
         p_office_id     => c_office_id);
   exception
      when x_item_does_not_exist then null;
   end;

   for i in 1..g_location_ids.count loop
      begin
         cwms_loc.delete_location(
            p_location_id   => g_location_ids(i),
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => c_office_id);
      exception
         when x_location_id_not_found then null;
      end;
   end loop;
end teardown;
--------------------------------------------------------------------------------
-- procedure cwdb_132_forecast_views_too_restrictive
--------------------------------------------------------------------------------
procedure cwdb_132_forecast_views_too_restrictive
is
   l_count        pls_integer;
   l_output_debug boolean;
   l_fcst_time    date := timestamp '2023-05-09 16:00:00';
   l_fcst_ts_data cwms_t_ztimeseries_array := cwms_t_ztimeseries_array(
   cwms_t_ztimeseries(
      c_fcst_loc_id||'.Stor.Inst.1Hour.0.Fcst',
      'ac-ft',
      cwms_t_ztsv_array(
         cwms_t_ztsv(l_fcst_time + 0/24, 1000, 3),
         cwms_t_ztsv(l_fcst_time + 1/24, 2000, 3),
         cwms_t_ztsv(l_fcst_time + 2/24, 3000, 3),
         cwms_t_ztsv(l_fcst_time + 3/24, 4000, 3),
         cwms_t_ztsv(l_fcst_time + 4/24, 5000, 3),
         cwms_t_ztsv(l_fcst_time + 5/24, 6000, 3))),
   cwms_t_ztimeseries(
      c_us_loc_id||'.Flow.Inst.1Hour.0.Fcst',
      'cfs',
      cwms_t_ztsv_array(
         cwms_t_ztsv(l_fcst_time + 0/24, 100, 3),
         cwms_t_ztsv(l_fcst_time + 1/24, 200, 3),
         cwms_t_ztsv(l_fcst_time + 2/24, 300, 3),
         cwms_t_ztsv(l_fcst_time + 3/24, 400, 3),
         cwms_t_ztsv(l_fcst_time + 4/24, 500, 3),
         cwms_t_ztsv(l_fcst_time + 5/24, 600, 3))),
   cwms_t_ztimeseries(
      c_ds_loc_id||'.Flow.Inst.1Hour.0.Fcst',
      'cfs',
      cwms_t_ztsv_array(
         cwms_t_ztsv(l_fcst_time + 0/24, 100, 3),
         cwms_t_ztsv(l_fcst_time + 1/24, 200, 3),
         cwms_t_ztsv(l_fcst_time + 2/24, 300, 3),
         cwms_t_ztsv(l_fcst_time + 3/24, 400, 3),
         cwms_t_ztsv(l_fcst_time + 4/24, 500, 3),
         cwms_t_ztsv(l_fcst_time + 5/24, 600, 3))));
begin
   -------------------------
   -- store the locations --
   -------------------------
   for i in 1..g_location_ids.count loop
      cwms_loc.store_location(
         p_location_id  => g_location_ids(i),
         p_db_office_id => c_office_id);
   end loop;
   -----------------------------
   -- store the forecast spec --
   -----------------------------
   cwms_forecast.store_spec(
      p_location_id    => c_fcst_loc_id,
      p_forecast_id    => c_fcst_id,
      p_fail_if_exists => 'F',
      p_ignore_nulls   => 'F',
      p_source_agency  => 'USACE',
      p_source_office  => c_office_id,
      p_valid_lifetime => 168,
      p_forecast_type  => null,
      p_source_loc_id  => null,
      p_office_id      => c_office_id);
   ------------------------
   -- store the forecast --
   ------------------------
   cwms_forecast.store_forecast(
      p_location_id    => c_fcst_loc_id,
      p_forecast_id    => c_fcst_id,
      p_forecast_time  => l_fcst_time,
      p_issue_time     => l_fcst_time + 1,
      p_time_zone      => 'UTC',
      p_fail_if_exists => 'F',
      p_text           => 'Here is some text',
      p_time_series    => l_fcst_ts_data,
      p_store_rule     => cwms_util.replace_all,
      p_office_id      => c_office_id);
   commit;
   --------------------------------------------------------------
   -- verify CWMS_V_FORECAST shows having time series and text --
   --------------------------------------------------------------
   l_count := 0;
   for rec in (select *
                 from cwms_v_forecast
                where office_id = c_office_id
                  and location_id = c_fcst_loc_id
                  and forecast_id = c_fcst_id
                  and utc_forecast_time = l_fcst_time
              )
   loop
      l_count := l_count + 1;
      ut.expect(rec.has_text).to_equal('T');
      ut.expect(rec.has_time_series).to_equal('T');
   end loop;
   ut.expect(l_count).to_equal(1);
   ------------------------------------------------------
   -- verify all time series are in CWMS_V_FORECAST_EX --
   ------------------------------------------------------
   for rec in (select tsid from table(l_fcst_ts_data)) loop
      select count(*)
        into l_count
        from cwms_v_forecast_ex
       where forecast_id = c_fcst_id
         and utc_forecast_time = l_fcst_time
         and cwms_ts_id = rec.tsid;

      ut.expect(l_count).to_equal(1);
   end loop;
   ---------------------------
   -- test catalog routines --
   ---------------------------
   declare
      l_crsr            sys_refcursor;
      l_office_ids      cwms_t_str_tab;
      l_location_ids    cwms_t_str_tab;
      l_fcst_ids        cwms_t_str_tab;
      l_fcst_dates      cwms_t_date_table;
      l_issue_dates     cwms_t_date_table;
      l_text_ids        cwms_t_str_tab;
      l_cwms_ts_ids     cwms_t_str_tab;
      l_version_dates   cwms_t_date_table;
      l_min_dates       cwms_t_date_table;
      l_max_dates       cwms_t_date_table;
      l_time_zone_names cwms_t_str_tab;
      l_valid_states    cwms_t_str_tab;
   begin
      ------------------------------------------------------------------
      -- verify abbreviated catalog shows having text and time series --
      ------------------------------------------------------------------
      l_crsr := cwms_forecast.cat_forecast_f(
         p_location_id_mask => c_fcst_loc_id,
         p_forecast_id_mask => c_fcst_id,
         p_max_fcst_age     => 'P10Y',
         p_max_issue_age    => 'P10Y',
         p_abbreviated      => 'T',
         p_time_zone        => 'UTC',
         p_office_id_mask   => c_office_id);

      fetch l_crsr
       bulk collect
       into l_office_ids,
            l_location_ids,
            l_fcst_ids,
            l_fcst_dates,
            l_issue_dates,
            l_text_ids,
            l_cwms_ts_ids,
            l_time_zone_names,
            l_valid_states;

      close l_crsr;
      ut.expect(l_cwms_ts_ids.count).to_equal(1);
      ut.expect(l_text_ids(1)).to_equal('T');
      ut.expect(l_cwms_ts_ids(1)).to_equal('T');
      -------------------------------------------------------------
      -- verify all time series are cataloged in regular catalog --
      -------------------------------------------------------------
      l_crsr := cwms_forecast.cat_forecast_f(
         p_location_id_mask => c_fcst_loc_id,
         p_forecast_id_mask => c_fcst_id,
         p_max_fcst_age     => 'P10Y',
         p_max_issue_age    => 'P10Y',
         p_abbreviated      => 'F',
         p_time_zone        => 'UTC',
         p_office_id_mask   => c_office_id);

      fetch l_crsr
       bulk collect
       into l_office_ids,
            l_location_ids,
            l_fcst_ids,
            l_fcst_dates,
            l_issue_dates,
            l_text_ids,
            l_cwms_ts_ids,
            l_version_dates,
            l_min_dates,
            l_max_dates,
            l_time_zone_names,
            l_valid_states;

      close l_crsr;
      ut.expect(l_cwms_ts_ids.count).to_equal(l_fcst_ts_data.count);

      for rec in (select tsid from table(l_fcst_ts_data)) loop
         select count(*)
           into l_count
           from table(l_cwms_ts_ids)
          where column_value = rec.tsid;

         ut.expect(l_count).to_equal(1);
      end loop;
   end;
end cwdb_132_forecast_views_too_restrictive;

end test_cwms_forecast;
/
show errors
