set verify off
create or replace package &&cwms_schema..test_cwms_level as
--%suite(Test schema for location level functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

procedure teardown;
procedure setup;

--%test(Test constant location levels)
procedure test_constant_location_levels;
--%test(Test regularly varying [seasonal] location levels)
procedure test_regularly_varying_location_levels;
--%test(Test irregularly varying [time series] location levels)
procedure test_irregularly_varying_location_levels;
--%test(Test virtual location levels)
procedure test_virtual_location_levels;

c_office_id             varchar2(16)  := '&&office_id';
c_location_id           varchar2(57)  := 'LocLevelTestLoc';
c_timezone_id           varchar2(28)  := 'US/Central';
c_elev_unit             varchar2(16)  := 'ft';
c_top_of_normal_elev_id varchar2(404) := c_location_id||'.Elev.Inst.0.Top of Normal';
c_top_of_normal_stor_id varchar2(404) := c_location_id||'.Stor.Inst.0.Top of Normal';
end test_cwms_level;
/
show errors;
create or replace package body &&cwms_schema..test_cwms_level as
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id);
exception
   when exc_location_id_not_found then null;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  =>c_location_id,
      p_time_zone_id => c_timezone_id,
      p_db_office_id => c_office_id);
   commit;
end;
--------------------------------------------------------------------------------
-- procedure test_constant_location_levels
--------------------------------------------------------------------------------
procedure test_constant_location_levels
is
   l_effective_date1 date   := date '2021-01-01';
   l_effective_date2 date   := date '2022-01-01';
   l_expiration_date date   := date '2023-01-01';
   l_value1          number := 1000;
   l_value2          number := 1010;
   l_value           number;
begin
   setup;
   ----------------------------------------
   -- store the constant location levels --
   ----------------------------------------
   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => l_value1,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date1,
      p_timezone_id       => c_timezone_id,
      p_expiration_date   => null,
      p_office_id         => c_office_id);

   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => l_value2,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date2,
      p_timezone_id       => c_timezone_id,
      p_expiration_date   => l_expiration_date,
      p_office_id         => c_office_id);

   commit;
   -------------------------------------------------------------
   -- retrieve the value just before the first effective date --
   -------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date1 - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(l_value).to_be_null;
   ----------------------------------------------------
   -- retrieve the value on the first effective date --
   ----------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date1,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value1, 5));
   ------------------------------------------------------------------------
   -- retrieve the value midway between first and second effective dates --
   ------------------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date1  + (l_effective_date2 - l_effective_date1) / 2,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value1, 5));
   --------------------------------------------------------------
   -- retrieve the value just before the second effective date --
   --------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date2 - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value1, 5));
   -----------------------------------------------------
   -- retrieve the value on the second effective date --
   -----------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date2,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value2, 5));
   --------------------------------------------------------
   -- retrieve the value just before the expiration date --
   --------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_expiration_date - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value2, 5));
   -----------------------------------------------
   -- retrieve the value on the expiration date --
   -----------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_expiration_date,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(l_value).to_be_null;

end test_constant_location_levels;
--------------------------------------------------------------------------------
-- procedure test_regularly_varying_location_levels
--------------------------------------------------------------------------------
procedure test_regularly_varying_location_levels
is
   l_value           number;
   l_expected_value  number;
   l_date            date;
   l_effective_date  date := date '2021-01-01';
   l_interval_origin date := date '2000-01-01';
   l_interval_months integer := 12;
   l_seasonal_values cwms_t_seasonal_value_tab := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * 1440, 1000),  -- 01 Jan
      cwms_t_seasonal_value( 2, 14 * 1440, 1010),  -- 15 Mar
      cwms_t_seasonal_value( 4,  0 * 1440, 1020),  -- 01 May
      cwms_t_seasonal_value( 7,  0 * 1440, 1020),  -- 01 Aug
      cwms_t_seasonal_value( 8, 14 * 1440, 1010),  -- 15 Sep
      cwms_t_seasonal_value(11,  0 * 1440, 1000)); -- 01 Dec
begin
   setup;
   ---------------------------------------
   -- store the seasonal location level --
   ---------------------------------------
   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => null,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_interval_origin   => l_interval_origin,
      p_interval_months   => l_interval_months,
      p_seasonal_values   => l_seasonal_values,
      p_office_id         => c_office_id);

   commit;
   -------------------------------------------------------------
   -- retrieve the value just before the first effective date --
   -------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(l_value).to_be_null;
   ----------------------------------------------------
   -- retrieve the value on the first effective date --
   ----------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_seasonal_values(1).value, 5));
   -------------------------------------------------------------------
   -- retrieve values on each seasonal breakpoint for a future year --
   -------------------------------------------------------------------
   for i in 1..l_seasonal_values.count loop
      l_date := add_months(l_effective_date, l_seasonal_values(i).offset_months + 24) +  l_seasonal_values(i).offset_minutes / 1440;
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => l_date,
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);

      ut.expect(round(l_value / l_seasonal_values(i).value, 4)).to_equal(1);
   end loop;
   ---------------------------------------------------------------------------
   -- retrieve values midway between seasonal breakpoints for a future year --
   ---------------------------------------------------------------------------
   for i in 2..l_seasonal_values.count loop
      l_date := add_months(add_months(l_effective_date, l_seasonal_values(i-1).offset_months + 24) +  l_seasonal_values(i-1).offset_minutes / 1440
                           + (add_months(l_effective_date, l_seasonal_values(i).offset_months + 24) +  l_seasonal_values(i).offset_minutes / 1440
                              - add_months(l_effective_date, l_seasonal_values(i-1).offset_months + 24) +  l_seasonal_values(i-1).offset_minutes / 1440
                             ) / 2,
                          24);
      l_expected_value := (l_seasonal_values(i-1).value + l_seasonal_values(i).value) / 2;
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => l_date,
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);

      ut.expect(round(l_value / l_expected_value, 2)).to_equal(1);
   end loop;
end test_regularly_varying_location_levels;
--------------------------------------------------------------------------------
--procedure test_irregularly_varying_location_levels
--------------------------------------------------------------------------------
procedure test_irregularly_varying_location_levels
is
   l_date            date;
   l_effective_date  date := date '2021-01-01';
   l_start_time      date := add_months(l_effective_date, -1);
   l_tsid            varchar2(191) := c_location_id||'.Elev-Normal_Level.Inst.~1Month.0.Test';
   l_value_count     integer := 12;
   l_ts_data         cwms_t_tsv_array;
   l_value           number;
   l_expected_value  number;
begin
   setup;
   ---------------------------
   -- store the time series --
   ---------------------------
   select cwms_t_tsv(
             date_time    => from_tz(cast(add_months(l_start_time, level-1) as timestamp), c_timezone_id),
             value        => 1000 + level,
             quality_code => 0)
     bulk collect
     into l_ts_data
     from dual
  connect by level <= l_value_count;

   cwms_ts.store_ts(
      l_tsid,
      c_elev_unit,
      l_ts_data,
      cwms_util.replace_all,
      'F',
      cwms_util.non_versioned,
      c_office_id,
      'T');
   ------------------------------------------------
   -- store the time series-based location level --
   ------------------------------------------------
   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => null,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_tsid              => l_tsid,
      p_office_id         => c_office_id);

   commit;
   ----------------------------------------------
   -- retrieve values at each time series time --
   ----------------------------------------------
   for i in 1..l_ts_data.count loop
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => cast(l_ts_data(i).date_time as date),
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);

      if l_ts_data(i).date_time < l_effective_date then
         ut.expect(l_value).to_be_null;
      else
         ut.expect(round(l_value, 5)).to_equal(round(l_ts_data(i).value, 5));
      end if;
   end loop;
   ----------------------------------------------------
   -- retrieve value after the last time series time --
   ----------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => add_months(cast(l_ts_data(l_ts_data.count).date_time as date), 1),
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_be_null;
   ----------------------------------------------------------
   -- retrieve values midway between each time series time --
   ----------------------------------------------------------
   for i in 2..l_ts_data.count loop
      l_date := cast(l_ts_data(i-1).date_time as date) + (cast(l_ts_data(i).date_time as date) - cast(l_ts_data(i-1).date_time as date)) / 2;
      if l_date = timestamp '2021-03-16 12:00:00' then
         l_date := l_date;
      end if;
      l_expected_value := (l_ts_data(i-1).value + l_ts_data(i).value) / 2;
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => l_date,
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);
      if l_date < l_effective_date then
         ut.expect(l_value).to_be_null;
      else
         ut.expect(round(l_value / l_expected_value, 2)).to_equal(1);
      end if;
   end loop;
end test_irregularly_varying_location_levels;
--------------------------------------------------------------------------------
-- procedure test_virtual_location_levels
--------------------------------------------------------------------------------
procedure test_virtual_location_levels
is
begin
   ut.expect(0).to_equal(0);
end test_virtual_location_levels;

end test_cwms_level;
/
show errors;
