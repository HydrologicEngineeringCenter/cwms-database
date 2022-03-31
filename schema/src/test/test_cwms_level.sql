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
--%test(Test guide curve (multiple seasonal location levels with attributes))
procedure test_guide_curve;

c_office_id             varchar2(16)  := '&&office_id';
c_location_id           varchar2(57)  := 'LocLevelTestLoc';
c_timezone_id           varchar2(28)  := 'US/Central';
c_elev_unit             varchar2(16)  := 'ft';
c_stor_unit             varchar2(16)  := 'ac-ft';
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
   l_date1           date;
   l_date2           date;
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
      l_date1 := add_months(l_effective_date, l_seasonal_values(i-1).offset_months + 24) +  l_seasonal_values(i-1).offset_minutes / 1440;
      l_date2 := add_months(l_effective_date, l_seasonal_values(i).offset_months + 24) +  l_seasonal_values(i).offset_minutes / 1440;
      l_date  := l_date1 + (l_date2 - l_date1) / 2;
      l_expected_value := (l_seasonal_values(i-1).value + l_seasonal_values(i).value) / 2;
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => l_date,
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);

      ut.expect(round(l_value / l_expected_value, 4)).to_equal(1);
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
   l_value                number;
   l_expected_value       number;
   l_elev_limit           number := 1005;
   l_stor_limit           number;
   l_date                 date;
   l_date1                date;
   l_date2                date;
   l_effective_date       date := date '2021-01-01';
   l_interval_origin      date := date '2000-01-01';
   l_interval_months      integer := 12;
   l_seasonal_elev_values cwms_t_seasonal_value_tab := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * 1440, 1000),  -- 01 Jan
      cwms_t_seasonal_value( 2, 14 * 1440, 1010),  -- 15 Mar
      cwms_t_seasonal_value( 4,  0 * 1440, 1020),  -- 01 May
      cwms_t_seasonal_value( 7,  0 * 1440, 1020),  -- 01 Aug
      cwms_t_seasonal_value( 8, 14 * 1440, 1010),  -- 15 Sep
      cwms_t_seasonal_value(11,  0 * 1440, 1000)); -- 01 Dec
   l_seasonal_stor_values cwms_t_seasonal_value_tab;
   l_rating_spec          varchar2(615) := c_location_id||'.Elev;Stor.Linear.Production';
   l_errors               clob;
   l_rating_xml           varchar2(32767) := '
<ratings>
  <rating-template office-id="'||c_office_id||'">
    <parameters-id>Elev;Stor</parameters-id>
    <version>Linear</version>
    <ind-parameter-specs>
      <ind-parameter-spec position="1">
        <parameter>Elev</parameter>
        <in-range-method>LINEAR</in-range-method>
        <out-range-low-method>NEAREST</out-range-low-method>
        <out-range-high-method>NEAREST</out-range-high-method>
      </ind-parameter-spec>
    </ind-parameter-specs>
    <dep-parameter>Stor</dep-parameter>
    <description/>
  </rating-template>
  <rating-spec office-id="'||c_office_id||'">
    <rating-spec-id>'||l_rating_spec||'</rating-spec-id>
    <template-id>Elev;Stor.Linear</template-id>
    <location-id>'||c_location_id||'</location-id>
    <version>Production</version>
    <source-agency/>
    <in-range-method>PREVIOUS</in-range-method>
    <out-range-low-method>NEAREST</out-range-low-method>
    <out-range-high-method>PREVIOUS</out-range-high-method>
    <active>true</active>
    <auto-update>false</auto-update>
    <auto-activate>false</auto-activate>
    <auto-migrate-extension>false</auto-migrate-extension>
    <ind-rounding-specs>
      <ind-rounding-spec position="1">3333456784</ind-rounding-spec>
    </ind-rounding-specs>
    <dep-rounding-spec>4444444444</dep-rounding-spec>
    <description/>
  </rating-spec>
  <simple-rating office-id="'||c_office_id||'">
    <rating-spec-id>'||l_rating_spec||'</rating-spec-id>
    <vertical-datum-info/>
    <units-id vertical-datum="">'||c_elev_unit||';'||c_stor_unit||'</units-id>
    <effective-date>2009-01-14T00:00:00-06:00</effective-date>
    <create-date>2012-07-11T09:37:13-05:00</create-date>
    <active>true</active>
    <description/>
    <rating-points>
      <point>
        <ind>0</ind>
        <dep>0</dep>
      </point>
      <point>
        <ind>10000</ind>
        <dep>100000</dep>
      </point>
    </rating-points>
  </simple-rating>
</ratings>
';
begin
   setup;
   ------------------------------------------
   -- store the static elev location level --
   ------------------------------------------
   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => null,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_interval_origin   => l_interval_origin,
      p_interval_months   => l_interval_months,
      p_seasonal_values   => l_seasonal_elev_values,
      p_office_id         => c_office_id);
   commit;
   ----------------------
   -- store the rating --
   ----------------------
   cwms_rating.store_ratings_xml(
      p_errors         => l_errors,
      p_xml            => l_rating_xml,
      p_fail_if_exists => 'F',
      p_replace_base   => 'F');
   commit;
   ut.expect(l_errors).to_be_null;
   --------------------------------------------------------------
   -- rate the elev limit and static elev levels into storages --
   --------------------------------------------------------------
   l_stor_limit := cwms_rating.rate_f(
      p_rating_spec => l_rating_spec,
      p_value       => l_elev_limit,
      p_units       => cwms_t_str_tab(c_elev_unit, c_stor_unit),
      p_office_id   => c_office_id);

   select cwms_t_seasonal_value(
            offset_months,
            offset_minutes,
            cwms_rating.rate_f(
               p_rating_spec => l_rating_spec,
               p_value       => value,
               p_units       => cwms_t_str_tab(c_elev_unit, c_stor_unit),
               p_office_id   => c_office_id))
     bulk collect
     into l_seasonal_stor_values -- used only for expected stor values
     from table(l_seasonal_elev_values);
   --------------------------------------------------------------------------------------
   -- store a permanent virtual stor location level that rates the elev location level --
   --------------------------------------------------------------------------------------
   cwms_level.store_virtual_location_level(
      p_location_level_id       => c_top_of_normal_stor_id,
      p_constituents            => 'L1'||chr(9)||'LOCATION_LEVEL'||chr(9)||c_top_of_normal_elev_id||chr(10)||
                                   'R1'||chr(9)||'RATING'        ||chr(9)||l_rating_spec, -- using text constituents overload
      p_constituent_connections => 'L1=R1I1',
      p_effective_date          => l_effective_date,
      p_expiration_date         => null,
      p_timezone_id             => c_timezone_id,
      p_office_id               => c_office_id);
   commit;
   ---------------------------------------------------------------------------
   -- store a temporary virtual elev location level that restricts the elev --
   ---------------------------------------------------------------------------
   --                                                                       --
   -- The retrieve_location_level_value(s) routines have an optional para-  --
   -- meter named p_level_precedence which defaults to the value 'VN'.      --
   --                                                                       --
   -- Valid values for this parameter are 'N', 'V', 'NV', and 'VN'.  This   --
   -- parameter controls whether the routines try to retieve the location   --
   -- level values from 'N'oramal and/or 'V'irtual location levels. If 'VN' --
   -- is specified, the routines first try to retrieve from a virtual level --
   -- matching the parameters. If no such virtual location level is found,  --
   -- The routines next try to retrieve from a normal location level that   --
   -- matches the parameters. Specifying 'NV' causes the routines to first  --
   -- try for a normal level and fall back to a virtual level if none can   --
   -- be found. Specifying 'N' or 'V' restricts the routines to retrieving  --
   -- only from normal and virtual location levels, respectively.           --
   --                                                                       --
   -- Using the default level precedence of 'VN' allows virtual location    --
   -- levels to override normal location levels with the same level ID.     --
   -- Assigning an expiration date to the virtual location level makes such --
   -- overrides apply for a limited time only, which is what is done here.  --
   --                                                                       --
   ---------------------------------------------------------------------------
   cwms_level.store_virtual_location_level(
      p_location_level_id       => c_top_of_normal_elev_id,
      p_constituents            => cwms_t_str_tab_tab( -- using table constituents overloadd
                                      cwms_t_str_tab('L1', 'LOCATION_LEVEL', c_top_of_normal_elev_id),
                                      cwms_t_str_tab('F1', 'FORMULA',        'MIN($I1, '||l_elev_limit||') {ft;ft}')),
      p_constituent_connections => 'L1=F1I1',
      p_effective_date          => add_months(l_effective_date, 12),           -- start of year 2
      p_expiration_date         => add_months(l_effective_date, 24) - 1/86400, -- end of year 2
      p_timezone_id             => c_timezone_id,
      p_office_id               => c_office_id);
   commit;
   for year in 1..3 loop
      ---------------------------------------------------------
      -- retrieve the elev value at each seasonal breakpoint --
      ---------------------------------------------------------
      for i in 1..l_seasonal_elev_values.count loop
         l_date := add_months(l_effective_date, l_seasonal_elev_values(i).offset_months + (year-1) * 12) +  l_seasonal_elev_values(i).offset_minutes / 1440;
         l_expected_value := case
                             when year = 2 then
                                least(l_seasonal_elev_values(i).value, l_elev_limit)
                             else
                                l_seasonal_elev_values(i).value
                             end;
         l_value := cwms_level.retrieve_location_level_value(
            p_location_level_id => c_top_of_normal_elev_id,
            p_level_units       => c_elev_unit,
            p_date              => l_date,
            p_timezone_id       => c_timezone_id,
            p_office_id         => c_office_id);

         ut.expect(round(l_value / l_expected_value, 4)).to_equal(1);
      end loop;
      ---------------------------------------------------------
      -- retrieve the stor value at each seasonal breakpoint --
      ---------------------------------------------------------
      for i in 1..l_seasonal_stor_values.count loop
         l_date := add_months(l_effective_date, l_seasonal_stor_values(i).offset_months + (year-1) * 12) +  l_seasonal_stor_values(i).offset_minutes / 1440;
         l_expected_value := case
                             when year = 2 then
                                least(l_seasonal_stor_values(i).value, l_stor_limit)
                             else
                                l_seasonal_stor_values(i).value
                             end;
         l_value := cwms_level.retrieve_location_level_value(
            p_location_level_id => c_top_of_normal_stor_id,
            p_level_units       => c_stor_unit,
            p_date              => l_date,
            p_timezone_id       => c_timezone_id,
            p_office_id         => c_office_id);

         ut.expect(round(l_value / l_expected_value, 4)).to_equal(1);
      end loop;
      --------------------------------------------------------------
      -- retrieve elev values midway between seasonal breakpoints --
      --------------------------------------------------------------
      for i in 2..l_seasonal_elev_values.count loop
         l_date1 := add_months(l_effective_date, l_seasonal_elev_values(i-1).offset_months + (year-1) * 12) +  l_seasonal_elev_values(i-1).offset_minutes / 1440;
         l_date2 := add_months(l_effective_date, l_seasonal_elev_values(i).offset_months + (year-1) * 12) +  l_seasonal_elev_values(i).offset_minutes / 1440;
         l_date  := l_date1 + (l_date2 - l_date1) / 2;
         l_expected_value := case
                             when year = 2 then
                                least((l_seasonal_elev_values(i-1).value + l_seasonal_elev_values(i).value) / 2, l_elev_limit)
                             else
                                (l_seasonal_elev_values(i-1).value + l_seasonal_elev_values(i).value) / 2
                             end;
         l_value := cwms_level.retrieve_location_level_value(
            p_location_level_id => c_top_of_normal_elev_id,
            p_level_units       => c_elev_unit,
            p_date              => l_date,
            p_timezone_id       => c_timezone_id,
            p_office_id         => c_office_id);

         ut.expect(round(l_value / l_expected_value, 4)).to_equal(1);
      end loop;
      --------------------------------------------------------------
      -- retrieve stor values midway between seasonal breakpoints --
      --------------------------------------------------------------
      for i in 2..l_seasonal_stor_values.count loop
         l_date1 := add_months(l_effective_date, l_seasonal_stor_values(i-1).offset_months + (year-1) * 12) +  l_seasonal_stor_values(i-1).offset_minutes / 1440;
         l_date2 := add_months(l_effective_date, l_seasonal_stor_values(i).offset_months + (year-1) * 12) +  l_seasonal_stor_values(i).offset_minutes / 1440;
         l_date  := l_date1 + (l_date2 - l_date1) / 2;
         l_expected_value := case
                             when year = 2 then
                                least((l_seasonal_stor_values(i-1).value + l_seasonal_stor_values(i).value) / 2, l_stor_limit)
                             else
                                (l_seasonal_stor_values(i-1).value + l_seasonal_stor_values(i).value) / 2
                             end;
         l_value := cwms_level.retrieve_location_level_value(
            p_location_level_id => c_top_of_normal_stor_id,
            p_level_units       => c_stor_unit,
            p_date              => l_date,
            p_timezone_id       => c_timezone_id,
            p_office_id         => c_office_id);

         ut.expect(round(l_value / l_expected_value, 4)).to_equal(1);
      end loop;
   end loop;
end test_virtual_location_levels;
--------------------------------------------------------------------------------
-- procedure test_guide_curve
--------------------------------------------------------------------------------
-- The location level data for this test is taken from the file
-- test_cwms_level.test_guide_curve.xlsx in the src/test directory (same
-- directory as this file). The file has an embedded plot that facilitates
-- visualizing the maximum flow limits at various times of the year for any
-- amount of system flood storage utilized. The data in the l_eval_info variable
-- were chosen from this plot to because the flow limits change throughout the
-- year for the selected storage utilization values.
--------------------------------------------------------------------------------
procedure test_guide_curve
is
   type seasonal_value_tab_tab_t is table of cwms_t_seasonal_value_tab;
   type eval_rec_t is record(date_time date, basin_pct_full number, flow_limit number);
   type eval_tab_t is table of eval_rec_t;
   l_location_level_id varchar2(404) := c_location_id||'.%-of Basin Full.Inst.0.Guide Curve';
   l_attribute_id      varchar2(92)  := 'Flow.Max.0';
   l_level_unit        varchar2(16)  := '%';
   l_attribute_unit    varchar2(16)  := 'cfs';
   l_effective_date    date := date '2005-05-16';
   l_interval_origin   date := date '2000-01-01';
   l_interval_months   integer := 12;
   l_attribute_value   number;
   l_attribute_values  cwms_t_number_tab := cwms_t_number_tab(20000, 40000, 60000, 150000);
   l_seasonal_values   seasonal_value_tab_tab_t := seasonal_value_tab_tab_t();
   l_eval_info         eval_tab_t := eval_tab_t(
                          eval_rec_t(date '2022-02-01',  5,  20000),
                          eval_rec_t(date '2022-02-01', 10,  40000),
                          eval_rec_t(date '2022-02-01', 20,  60000),
                          eval_rec_t(date '2022-02-01', 45, 150000),

                          eval_rec_t(date '2022-04-01',  5,  40000),
                          eval_rec_t(date '2022-04-01', 10,  60000),
                          eval_rec_t(date '2022-04-01', 20,  60000),
                          eval_rec_t(date '2022-04-01', 45, 150000),

                          eval_rec_t(date '2022-08-01',  5,  20000),
                          eval_rec_t(date '2022-08-01', 10,  20000),
                          eval_rec_t(date '2022-08-01', 20,  60000),
                          eval_rec_t(date '2022-08-01', 45, 150000),

                          eval_rec_t(date '2022-11-01',  5,  20000),
                          eval_rec_t(date '2022-11-01', 10,  40000),
                          eval_rec_t(date '2022-11-01', 20,  60000),
                          eval_rec_t(date '2022-11-01', 45,  60000));
begin
   setup;
   l_seasonal_values.extend(4);
   l_seasonal_values(1) := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * 1440,  0),  -- 01 Jan
      cwms_t_seasonal_value( 1, 14 * 1440,  0),  -- 15 Feb
      cwms_t_seasonal_value( 2,  0 * 1440,  0),  -- 01 Mar
      cwms_t_seasonal_value( 4, 14 * 1440,  0),  -- 15 May
      cwms_t_seasonal_value( 5, 14 * 1440,  0),  -- 15 Jun
      cwms_t_seasonal_value( 8, 14 * 1440,  0),  -- 15 Sep
      cwms_t_seasonal_value( 9,  0 * 1440,  0),  -- 01 Oct
      cwms_t_seasonal_value(10,  0 * 1440,  0),  -- 01 Nov
      cwms_t_seasonal_value(11, 14 * 1440,  0),  -- 15 Dec
      cwms_t_seasonal_value(11, 30 * 1440,  0)); -- 31 Dec
   l_seasonal_values(2) := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * 1440,  7),  -- 01 Jan
      cwms_t_seasonal_value( 1, 14 * 1440,  7),  -- 15 Feb
      cwms_t_seasonal_value( 2,  0 * 1440,  3),  -- 01 Mar
      cwms_t_seasonal_value( 4, 14 * 1440,  3),  -- 15 May
      cwms_t_seasonal_value( 5, 14 * 1440, 11),  -- 15 Jun
      cwms_t_seasonal_value( 8, 14 * 1440, 11),  -- 15 Sep
      cwms_t_seasonal_value( 9,  0 * 1440,  7),  -- 01 Oct
      cwms_t_seasonal_value(10,  0 * 1440,  7),  -- 01 Nov
      cwms_t_seasonal_value(11, 14 * 1440,  7),  -- 15 Dec
      cwms_t_seasonal_value(11, 30 * 1440,  7)); -- 31 Dec
   l_seasonal_values(3) := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * 1440, 15),  -- 01 Jan
      cwms_t_seasonal_value( 1, 14 * 1440, 15),  -- 15 Feb
      cwms_t_seasonal_value( 2,  0 * 1440,  8),  -- 01 Mar
      cwms_t_seasonal_value( 4, 14 * 1440,  8),  -- 15 May
      cwms_t_seasonal_value( 5, 14 * 1440, 18),  -- 15 Jun
      cwms_t_seasonal_value( 8, 14 * 1440, 18),  -- 15 Sep
      cwms_t_seasonal_value( 9,  0 * 1440, 15),  -- 01 Oct
      cwms_t_seasonal_value(10,  0 * 1440, 15),  -- 01 Nov
      cwms_t_seasonal_value(11, 14 * 1440, 15),  -- 15 Dec
      cwms_t_seasonal_value(11, 30 * 1440, 15)); -- 31 Dec
   l_seasonal_values(4) := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * 1440, 40),  -- 01 Jan
      cwms_t_seasonal_value( 1, 14 * 1440, 40),  -- 15 Feb
      cwms_t_seasonal_value( 2,  0 * 1440, 40),  -- 01 Mar
      cwms_t_seasonal_value( 4, 14 * 1440, 40),  -- 15 May
      cwms_t_seasonal_value( 5, 14 * 1440, 40),  -- 15 Jun
      cwms_t_seasonal_value( 8, 14 * 1440, 40),  -- 15 Sep
      cwms_t_seasonal_value( 9,  0 * 1440, 50),  -- 01 Oct
      cwms_t_seasonal_value(10,  0 * 1440, 50),  -- 01 Nov
      cwms_t_seasonal_value(11, 14 * 1440, 50),  -- 15 Dec
      cwms_t_seasonal_value(11, 30 * 1440, 40)); -- 31 Dec
   ---------------------------
   -- store the guide curve --
   ---------------------------
   for i in 1..4 loop
      cwms_level.store_location_level4(
         p_location_level_id =>  l_location_level_id,
         p_level_value       =>  null,
         p_level_units       =>  l_level_unit,
         p_effective_date    =>  l_effective_date,
         p_timezone_id       =>  c_timezone_id,
         p_attribute_value   =>  l_attribute_values(i),
         p_attribute_units   =>  l_attribute_unit,
         p_attribute_id      =>  l_attribute_id,
         p_interval_origin   =>  l_interval_origin,
         p_interval_months   =>  l_interval_months,
         p_seasonal_values   =>  l_seasonal_values(i),
         p_office_id         =>  c_office_id);
      commit;
   end loop;
   for i in 1..l_eval_info.count loop
      l_attribute_value := cwms_level.lookup_attribute_by_level(
         p_location_level_id  => l_location_level_id,
         p_attribute_id       => l_attribute_id,
         p_level_value        => l_eval_info(i).basin_pct_full,
         p_level_units        => l_level_unit,
         p_attribute_units    => l_attribute_unit,
         p_in_range_behavior  => cwms_lookup.method_lower,
         p_out_range_behavior => cwms_lookup.method_closest,
         p_timezone_id        => c_timezone_id,
         p_date               => l_eval_info(i).date_time,
         p_office_id          => c_office_id);

     ut.expect(round(l_attribute_value, 9)).to_equal(l_eval_info(i).flow_limit);
   end loop;
end test_guide_curve;

end test_cwms_level;
/
show errors;
