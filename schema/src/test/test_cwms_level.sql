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
--%test(Test regularly varying (seasonal) location levels)
procedure test_regularly_varying_location_levels;
--%test(Test irregularly varying (time series) location levels)
procedure test_irregularly_varying_location_levels;
--%test(Test virtual location levels)
procedure test_virtual_location_levels;
--%test(Test guide curve (multiple seasonal location levels with attributes))
procedure test_guide_curve;
--%test(Test location level labels, sources, indicators and conditions, and xml store/retrieve) [only works if OS TZ is UTC]
procedure test_sources_labels_indicators_conditions_and_xml;

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
   l_count           pls_integer;
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
   begin
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => l_effective_date1 - 1/86400,
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);
      cwms_err.raise ('ERROR', 'Expected exception not raised');
   exception
      when others then ut.expect(sqlerrm).to_be_like('ORA-20034: ITEM_DOES_NOT_EXIST: Location level % does not exist.');
   end;
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
   ------------------------------------------------------------------
   -- test delete_location_level3 with p_all_effective_dates = 'T' --
   ------------------------------------------------------------------
   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_id = c_location_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(2);

   cwms_level.delete_location_level3(
      p_location_level_id   => c_top_of_normal_elev_id,
      p_office_id           => c_office_id,
      p_all_effective_dates => 'T');

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_id = c_location_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

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
   l_count           pls_integer;
   l_seasonal_values_existlevel cwms_t_seasonal_value_tab := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * CWMS_TS.min_in_dy, 1020),  -- 01 Jan
      cwms_t_seasonal_value( 3, 14 * CWMS_TS.min_in_dy, 1010),  -- 15 April
      cwms_t_seasonal_value(9,  1 * CWMS_TS.min_in_dy, 1000)); -- 02 Oct
   l_seasonal_values cwms_t_seasonal_value_tab := cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( 0,  0 * CWMS_TS.min_in_dy, 1000),  -- 01 Jan
      cwms_t_seasonal_value( 2, 14 * CWMS_TS.min_in_dy, 1010),  -- 15 Mar
      cwms_t_seasonal_value( 4,  0 * CWMS_TS.min_in_dy, 1020), -- 01 May
      cwms_t_seasonal_value( 7,  0 * CWMS_TS.min_in_dy, 1020),  -- 01 Aug
      cwms_t_seasonal_value( 8, 14 * CWMS_TS.min_in_dy, 1010),  -- 15 Sep
      cwms_t_seasonal_value(11,  0 * CWMS_TS.min_in_dy, 1000)); -- 01 Dec
begin
   setup;
   ---------------------------------------
   -- store the seasonal location level and create new level --
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
   begin
      l_value := cwms_level.retrieve_location_level_value(
         p_location_level_id => c_top_of_normal_elev_id,
         p_level_units       => c_elev_unit,
         p_date              => l_effective_date - 1/86400,
         p_timezone_id       => c_timezone_id,
         p_office_id         => c_office_id);
         cwms_err.raise ('ERROR', 'Expected exception not raised');
   exception
      when others then ut.expect(sqlerrm).to_be_like('ORA-20034: ITEM_DOES_NOT_EXIST: Location level % does not exist.');
   end;
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
      l_date := add_months(l_effective_date, l_seasonal_values(i).offset_months + 24) +  l_seasonal_values(i).offset_minutes / CWMS_TS.min_in_dy;
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
      l_date1 := add_months(l_effective_date, l_seasonal_values(i-1).offset_months + 24) +  l_seasonal_values(i-1).offset_minutes / CWMS_TS.min_in_dy;
      l_date2 := add_months(l_effective_date, l_seasonal_values(i).offset_months + 24) +  l_seasonal_values(i).offset_minutes / CWMS_TS.min_in_dy;
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

   ---------------------------------------
   -- store the seasonal location level to level already created--
   ---------------------------------------

   cwms_level.store_location_level3(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => null,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_interval_origin   => l_interval_origin,
      p_interval_months   => l_interval_months,
      p_seasonal_values   => l_seasonal_values_existlevel,
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);

   -------------------------------------------------------------------------
   -- test number of seasonal values --
   -------------------------------------------------------------------------
   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_id = c_location_id
      and level_date = cwms_util.change_timezone(l_effective_date, c_timezone_id, 'UTC')
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(l_seasonal_values_existlevel.count);

  --------------------------------------------------------------------------
  --  test individual seasonal dates are present
  -----------------------------------

   for i in 1..l_seasonal_values_existlevel.count loop
        l_date := cwms_util.change_timezone(
                  add_months(l_interval_origin, l_seasonal_values_existlevel(i).offset_months) +
		  l_seasonal_values_existlevel(i).offset_minutes / CWMS_TS.min_in_dy, 
                  c_timezone_id, 'UTC');
    	select count(*)
         into  l_count
     	 from  cwms_v_location_level
    	 where office_id = c_office_id
      	   and location_level_id = c_top_of_normal_elev_id
      	   and level_date = cwms_util.change_timezone(l_effective_date, c_timezone_id, 'UTC')
      	   and unit_system = 'EN'
       	   and ADD_MONTHS(interval_origin,cwms_util.yminterval_to_months(calendar_offset)) +
               cwms_util.dsinterval_to_minutes(time_offset)/CWMS_TS.min_in_dy= l_date;
           ut.expect(l_count).to_equal(1);

   end loop;

   -------------------------------------------------------------------------
   -- test delete_location_level3 with p_most_recent_effective_date = 'T' --
   -------------------------------------------------------------------------

   cwms_level.delete_location_level3(
     p_location_level_id          => c_top_of_normal_elev_id,
      p_cascade                    => 'T',
      p_office_id                  => c_office_id,
      p_most_recent_effective_date => 'T');

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_id = c_location_id
      and level_date = cwms_util.change_timezone(l_effective_date, c_timezone_id, 'UTC')
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

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
   l_count           pls_integer;
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
      begin
         l_value := cwms_level.retrieve_location_level_value(
            p_location_level_id => c_top_of_normal_elev_id,
            p_level_units       => c_elev_unit,
            p_date              => cast(l_ts_data(i).date_time as date),
            p_timezone_id       => c_timezone_id,
            p_office_id         => c_office_id);
         if cast(l_ts_data(i).date_time as date) < l_effective_date then
            cwms_err.raise ('ERROR', 'Expected exception not raised');
         else
            ut.expect(round(l_value, 5)).to_equal(round(l_ts_data(i).value, 5));
         end if;
      exception
         when others then
            if cast(l_ts_data(i).date_time as date) < l_effective_date then
               ut.expect(sqlerrm).to_be_like('ORA-20034: ITEM_DOES_NOT_EXIST: Location level % does not exist.');
            else
               raise;
            end if;
      end;
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
      begin
         l_value := cwms_level.retrieve_location_level_value(
            p_location_level_id => c_top_of_normal_elev_id,
            p_level_units       => c_elev_unit,
            p_date              => l_date,
            p_timezone_id       => c_timezone_id,
            p_office_id         => c_office_id);
         if l_date < l_effective_date then
            cwms_err.raise ('ERROR', 'Expected exception not raised');
         else
            ut.expect(round(l_value / l_expected_value, 2)).to_equal(1);
         end if;
      exception
         when others then
            if l_date < l_effective_date then
               ut.expect(sqlerrm).to_be_like('ORA-20034: ITEM_DOES_NOT_EXIST: Location level % does not exist.');
            else
               raise;
            end if;
      end;
   end loop;
   ---------------------------------------------------------------
   -- test delete_location_level3 with specified effective date --
   ---------------------------------------------------------------
   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_id = c_location_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(1);

   cwms_level.delete_location_level3(
      p_location_level_id => c_top_of_normal_elev_id,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_cascade           => 'T',
      p_office_id         => c_office_id);

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_id = c_location_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

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
   l_count                pls_integer;
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
   -----------------------------------------------------------
   -- test delete_location_level3 with level type specified --
   -----------------------------------------------------------
   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_elev_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(l_seasonal_elev_values.count);

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_elev_id;

   ut.expect(l_count).to_equal(1);

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_stor_id;

   ut.expect(l_count).to_equal(1);

   select count(*)
     into l_count
     from cwms_v_vloc_lvl_constituent;

   ut.expect(l_count).to_equal(4);

   cwms_level.delete_location_level3(
      p_location_level_id   => c_top_of_normal_stor_id,
      p_office_id           => c_office_id,
      p_level_type          => 'V',
      p_all_effective_dates => 'T');

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_elev_id;

   ut.expect(l_count).to_equal(1);

   select count(*)into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_stor_id;

   ut.expect(l_count).to_equal(0);

   cwms_level.delete_location_level3(
      p_location_level_id   => c_top_of_normal_elev_id,
      p_timezone_id         => c_timezone_id,
      p_cascade             => 'T',
      p_office_id           => c_office_id,
      p_level_type          => 'N',
      p_all_effective_dates => 'T');

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_elev_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

   cwms_level.delete_location_level3(
      p_location_level_id   => c_top_of_normal_elev_id,
      p_timezone_id         => c_timezone_id,
      p_office_id           => c_office_id,
      p_level_type          => 'V',
      p_all_effective_dates => 'T');

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = c_top_of_normal_elev_id;

   ut.expect(l_count).to_equal(0);

   select count(*)
     into l_count
     from cwms_v_vloc_lvl_constituent;

   ut.expect(l_count).to_equal(0);

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
   l_count             pls_integer;
   l_expected_count    pls_integer;
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
   ----------------------------------------------------------------------------
   -- retrieve the max discharge for specified dates and system utilizations --
   ----------------------------------------------------------------------------
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
   -------------------------------------------------------------------
   -- test delete_location_level3 with p_all_attribute_values = 'T' --
   -------------------------------------------------------------------
   l_expected_count := 0;
   for i in 1..l_seasonal_values.count loop
      l_expected_count := l_expected_count + l_seasonal_values(i).count;
   end loop;

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = l_location_level_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(l_expected_count);

   cwms_level.delete_location_level3(
      p_location_level_id    => l_location_level_id,
      p_attribute_id         => l_attribute_id,
      p_cascade              => 'T',
      p_office_id            => c_office_id,
      p_all_effective_dates  => 'T',
      p_all_attribute_values => 'T');

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = l_location_level_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

end test_guide_curve;
--------------------------------------------------------------------------------
-- procedure test_sources_labels_indicators_conditions_and_xml
--------------------------------------------------------------------------------
procedure test_sources_labels_indicators_conditions_and_xml
is
   l_effective_date    date := date '2021-01-01';
   l_start_time        date := trunc(sysdate-1, 'dd') + 1/24;
   l_elev_bottom       number := 1010;
   l_elev_top          number := 1050;
   l_stor_bottom       number;
   l_stor_top          number;
   l_elev_bottom_id    varchar2(404) := c_location_id||'.Elev.Inst.0.Bottom of Flood';
   l_elev_bottom_label varchar2(32)  := c_location_id||' BFP Elev';
   l_elev_top_id       varchar2(404) := c_location_id||'.Elev.Inst.0.Top of Flood';
   l_elev_top_label    varchar2(32)  := c_location_id||' TFP Elev';
   l_stor_bottom_id    varchar2(404) := c_location_id||'.Stor.Inst.0.Bottom of Flood';
   l_stor_bottom_label varchar2(32)  := c_location_id||' BFP Stor';
   l_stor_top_id       varchar2(404) := c_location_id||'.Stor.Inst.0.Top of Flood';
   l_stor_top_label    varchar2(32)  := c_location_id||' TFP Stor';
   l_pct_full_ind_id   varchar2(437) := l_stor_top_id||'.PERCENT FULL';
   l_inflow_ind_id     varchar2(437) := l_stor_top_id||'.INFLOW';
   l_source_entity     varchar2(32)  := 'CE'||c_office_id;
   l_elev_tsid         varchar2(191) := c_location_id||'.Elev.Inst.1Hour.0.Test';
   l_stor_tsid         varchar2(191) := c_location_id||'.Stor.Inst.1Hour.0.Test';
   l_rate_unit         varchar2(16)  := 'ft3';
   l_rate_interval     varchar2(12)  := '000 00:00:01';
   l_minimum_duration  varchar2(12)  := '000 01:00:00';
   l_maximum_age       varchar2(12)  := '000 06:00:00';
   l_pct_full_expr     varchar2(26)  := '(V - L2) / (L1 - L2) * 100';
   l_rate_expr         varchar2(1)   := 'R';
   l_value_count       integer := 48;
   l_count             pls_integer;
   l_elev_ts_data      cwms_t_tsv_array;
   l_stor_ts_data      cwms_t_tsv_array;
   l_pct_full_vals     cwms_t_number_tab := cwms_t_number_tab(10, 25, 50, 75, 90);
   l_pct_full_ind_ts   cwms_t_ztsv_array;
   l_inflow_ind_ts     cwms_t_ztsv_array;
   l_crsr              sys_refcursor;
   l_indicator_id      varchar2(437);
   l_attribute_id      varchar2(83);
   l_attribute_value   number;
   l_attribute_unit    varchar2(16);
   l_indicator_values  cwms_t_ztsv_array;
   l_rating_spec       varchar2(615) := c_location_id||'.Elev;Stor.Linear.Production';
   l_errors            clob;
   l_levels_xml1       clob;
   l_levels_xml2       clob;
   l_rating_xml        varchar2(32767) := '
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
/*
   The data above results in the following elevation, storage, and %full values.
   Since the minimum duration is 1 hour, the indicators will be set on the 2nd
   hour that the %full expression is true, as indictated by <-- below.

    #	Date/Time       	Elev	 Stor	%Full
   --	----------------	----	-----	-----
    1	2022-03-31-01:00	1001	10010
    2	2022-03-31-02:00	1002	10020
    3	2022-03-31-03:00	1003	10030
    4	2022-03-31-04:00	1004	10040
    5	2022-03-31-05:00	1005	10050
    6	2022-03-31-06:00	1006	10060
    7	2022-03-31-07:00	1007	10070
    8	2022-03-31-08:00	1008	10080
    9	2022-03-31-09:00	1009	10090
   10	2022-03-31-10:00	1010	10100	  0.0
   11	2022-03-31-11:00	1011	10110	  2.5
   12	2022-03-31-12:00	1012	10120	  5.0
   13	2022-03-31-13:00	1013	10130	  7.5
   14	2022-03-31-14:00	1014	10140	 10.0
   15	2022-03-31-15:00	1015	10150	 12.5 <--
   16	2022-03-31-16:00	1016	10160	 15.0
   17	2022-03-31-17:00	1017	10170	 17.5
   18	2022-03-31-18:00	1018	10180	 20.0
   19	2022-03-31-19:00	1019	10190	 22.5
   20	2022-03-31-20:00	1020	10200	 25.0
   21	2022-03-31-21:00	1021	10210	 27.5 <--
   22	2022-03-31-22:00	1022	10220	 30.0
   23	2022-03-31-23:00	1023	10230	 32.5
   24	2022-04-01-00:00	1024	10240	 35.0
   25	2022-04-01-01:00	1025	10250	 37.5
   26	2022-04-01-02:00	1026	10260	 40.0
   27	2022-04-01-03:00	1027	10270	 42.5
   28	2022-04-01-04:00	1028	10280	 45.0
   29	2022-04-01-05:00	1029	10290	 47.5
   30	2022-04-01-06:00	1030	10300	 50.0
   31	2022-04-01-07:00	1031	10310	 52.5 <--
   32	2022-04-01-08:00	1032	10320	 55.0
   33	2022-04-01-09:00	1033	10330	 57.5
   34	2022-04-01-10:00	1034	10340	 60.0
   35	2022-04-01-11:00	1035	10350	 62.5
   36	2022-04-01-12:00	1036	10360	 65.0
   37	2022-04-01-13:00	1037	10370	 67.5
   38	2022-04-01-14:00	1038	10380	 70.0
   39	2022-04-01-15:00	1039	10390	 72.5
   40	2022-04-01-16:00	1040	10400	 75.0
   41	2022-04-01-17:00	1041	10410	 77.5 <--
   42	2022-04-01-18:00	1042	10420	 80.0
   43	2022-04-01-19:00	1043	10430	 82.5
   44	2022-04-01-20:00	1044	10440	 85.0
   45	2022-04-01-21:00	1045	10450	 87.5
   46	2022-04-01-22:00	1046	10460	 90.0
   47	2022-04-01-23:00	1047	10470	 92.5 <--
   48	2022-04-02-00:00	1048	10480	 95.0
   49	2022-04-02-01:00	1049	10490	 95.5
*/
   dbms_output.enable(2000000);
   setup;
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
   ----------------------------------------------------
   -- rate the bottom and top elevations to storages --
   ----------------------------------------------------
   l_stor_bottom := cwms_rating.rate_f(
      p_rating_spec => l_rating_spec,
      p_value       => l_elev_bottom,
      p_units       => cwms_t_str_tab(c_elev_unit, c_stor_unit),
      p_office_id   => c_office_id);

   l_stor_top := cwms_rating.rate_f(
      p_rating_spec => l_rating_spec,
      p_value       => l_elev_top,
      p_units       => cwms_t_str_tab(c_elev_unit, c_stor_unit),
      p_office_id   => c_office_id);
   ------------------------------------
   -- store the elev location levels --
   ------------------------------------
   cwms_level.store_location_level4(
      p_location_level_id => l_elev_bottom_id,
      p_level_value       => l_elev_bottom,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_expiration_date   => null,
      p_office_id         => c_office_id);
   commit;

   cwms_level.store_location_level4(
      p_location_level_id => l_elev_top_id,
      p_level_value       => l_elev_top,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date,
      p_timezone_id       => c_timezone_id,
      p_expiration_date   => null,
      p_office_id         => c_office_id);
   commit;
   ------------------------------------
   -- store the stor location levels --
   ------------------------------------
   cwms_level.store_virtual_location_level(
      p_location_level_id       => l_stor_bottom_id,
      p_constituents            => 'L1'||chr(9)||'LOCATION_LEVEL'||chr(9)||l_elev_bottom_id||chr(10)||
                                   'R1'||chr(9)||'RATING'        ||chr(9)||l_rating_spec,
      p_constituent_connections => 'L1=R1I1',
      p_effective_date          => l_effective_date,
      p_expiration_date         => null,
      p_timezone_id             => c_timezone_id,
      p_office_id               => c_office_id);
   commit;

   cwms_level.store_virtual_location_level(
      p_location_level_id       => l_stor_top_id,
      p_constituents            => 'L1'||chr(9)||'LOCATION_LEVEL'||chr(9)||l_elev_top_id||chr(10)||
                                   'R1'||chr(9)||'RATING'        ||chr(9)||l_rating_spec,
      p_constituent_connections => 'L1=R1I1',
      p_effective_date          => l_effective_date,
      p_expiration_date         => null,
      p_timezone_id             => c_timezone_id,
      p_office_id               => c_office_id);
   commit;
   --------------------------------------------------------------
   -- set the sources and labels for the elev and stor levels  --
   --------------------------------------------------------------
   cwms_level.set_loc_lvl_source(
      p_loc_lvl_source    => l_source_entity,
      p_location_level_id => l_elev_bottom_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_source(
      p_loc_lvl_source    => l_source_entity,
      p_location_level_id => l_elev_top_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_source(
      p_loc_lvl_source    => l_source_entity,
      p_location_level_id => l_stor_bottom_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_source(
      p_loc_lvl_source    => l_source_entity,
      p_location_level_id => l_stor_top_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_label(
      p_loc_lvl_label     => l_elev_bottom_label,
      p_location_level_id => l_elev_bottom_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_label(
      p_loc_lvl_label     => l_elev_top_label,
      p_location_level_id => l_elev_top_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_label(
      p_loc_lvl_label     => l_stor_bottom_label,
      p_location_level_id => l_stor_bottom_id,
      p_office_id         => c_office_id);

   cwms_level.set_loc_lvl_label(
      p_loc_lvl_label     => l_stor_top_label,
      p_location_level_id => l_stor_top_id,
      p_office_id         => c_office_id);
   -----------------------------------
   -- verify the sources and labels --
   -----------------------------------
   ut.expect(cwms_level.get_loc_lvl_source_f(l_elev_bottom_id, null, null, null, c_office_id)).to_equal(l_source_entity);
   ut.expect(cwms_level.get_loc_lvl_source_f(l_elev_top_id,    null, null, null, c_office_id)).to_equal(l_source_entity);
   ut.expect(cwms_level.get_loc_lvl_source_f(l_stor_bottom_id, null, null, null, c_office_id)).to_equal(l_source_entity);
   ut.expect(cwms_level.get_loc_lvl_source_f(l_stor_top_id,    null, null, null, c_office_id)).to_equal(l_source_entity);

   ut.expect(cwms_level.get_loc_lvl_label_f(l_elev_bottom_id, null, null, null, null, c_office_id)).to_equal(l_elev_bottom_label);
   ut.expect(cwms_level.get_loc_lvl_label_f(l_elev_top_id,    null, null, null, null, c_office_id)).to_equal(l_elev_top_label);
   ut.expect(cwms_level.get_loc_lvl_label_f(l_stor_bottom_id, null, null, null, null, c_office_id)).to_equal(l_stor_bottom_label);
   ut.expect(cwms_level.get_loc_lvl_label_f(l_stor_top_id,    null, null, null, null, c_office_id)).to_equal(l_stor_top_label);

   -------------------------------------------------
   -- store the percent flood pool used indicator --
   -------------------------------------------------
   cwms_level.store_loc_lvl_indicator2(
      p_loc_lvl_indicator_id   => l_pct_full_ind_id,
      p_ref_specified_level_id => cwms_util.split_text(l_stor_bottom_id, 5, '.'),
      p_minimum_duration       => l_minimum_duration,
      p_maximum_age            => l_maximum_age,
      p_office_id              => c_office_id);
   commit;
   ------------------------------------------------------------
   -- store the percent flood pool used indicator conditions --
   ------------------------------------------------------------
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id   => l_pct_full_ind_id,
         p_level_indicator_value  => i,
         p_expression             => l_pct_full_expr,
         p_comparison_operator_1  => 'GE',
         p_comparison_value_1     => l_pct_full_vals(i),
         p_comparison_unit_id     => c_stor_unit,
         p_description            => 'Flood pool >= '||l_pct_full_vals(i)||'% full',
         p_ref_specified_level_id => cwms_util.split_text(l_stor_bottom_id, 5, '.'),
         p_office_id              => c_office_id);
   end loop;
   commit;
   -------------------------------------------
   -- store the flood pool inflow indicator --
   -------------------------------------------
   cwms_level.store_loc_lvl_indicator2(
      p_loc_lvl_indicator_id   => l_inflow_ind_id,
      p_ref_specified_level_id => cwms_util.split_text(l_stor_bottom_id, 5, '.'),
      p_minimum_duration       => l_minimum_duration,
      p_maximum_age            => l_maximum_age,
      p_office_id              => c_office_id);
   commit;
   ------------------------------------------------------
   -- store the flood pool inflow indicator conditions --
   ------------------------------------------------------
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id       => l_inflow_ind_id,
         p_level_indicator_value      => i,
         p_expression                 => l_pct_full_expr,
         p_comparison_operator_1      => 'GE',
         p_comparison_value_1         => 10,
         p_comparison_unit_id         => c_stor_unit,
         p_rate_expression            => l_rate_expr,
         p_rate_comparison_operator_1 => 'GE',
         p_rate_comparison_value_1    => 50 * i,
         p_rate_comparison_unit_id    => l_rate_unit,
         p_rate_interval              => l_rate_interval,
         p_description                => 'Flood pool filling >= '||50 * i||' cfs',
         p_ref_specified_level_id     => cwms_util.split_text(l_stor_bottom_id, 5, '.'),
         p_office_id                  => c_office_id);
   end loop;
   commit;
   --------------------------------
   -- store the elev time series --
   --------------------------------
   select cwms_t_tsv(
             date_time    => from_tz(cast(l_start_time + (level-1)/24 as timestamp), c_timezone_id),
             value        => 1000 + level,
             quality_code => 0)
     bulk collect
     into l_elev_ts_data
     from dual
  connect by level <= l_value_count;

   cwms_ts.store_ts(
      l_elev_tsid,
      c_elev_unit,
      l_elev_ts_data,
      cwms_util.replace_all,
      'F',
      cwms_util.non_versioned,
      c_office_id,
      'T');
   commit;
   --------------------------------
   -- store the stor time series --
   --------------------------------
   select cwms_t_tsv(
             date_time,
             cwms_rating.rate_f(
                p_rating_spec => l_rating_spec,
                p_value       => value,
                p_units       => cwms_t_str_tab(c_elev_unit, c_stor_unit),
                p_office_id   => c_office_id),
             quality_code)
     bulk collect
     into l_stor_ts_data
     from table(l_elev_ts_data);

   cwms_ts.store_ts(
      l_stor_tsid,
      c_stor_unit,
      l_stor_ts_data,
      cwms_util.replace_all,
      'F',
      cwms_util.non_versioned,
      c_office_id,
      'T');
   commit;
   ------------------------------------------------------------------------------------------
   -- evaluate the percent flood pool used indicator expression for each time series value --
   ------------------------------------------------------------------------------------------
   l_pct_full_ind_ts := cwms_level.eval_level_indicator_expr(
      p_tsid                   => l_stor_tsid,
      p_start_time             => l_start_time,
      p_end_time               => l_start_time + (l_value_count)/24,
      p_unit                   => c_stor_unit,
      p_specified_level_id     => cwms_util.split_text(l_stor_top_id, 5, '.'),
      p_indicator_id           => cwms_util.split_text(l_pct_full_ind_id, 6, '.'),
      p_ref_specified_level_id => cwms_util.split_text(l_stor_bottom_id, 5, '.'),
      p_time_zone              => c_timezone_id,
      p_office_id              => c_office_id);
   for i in 1..l_pct_full_ind_ts.count loop
      ut.expect(l_pct_full_ind_ts(i).date_time).to_equal(cast(l_stor_ts_data(i).date_time as date));
      ut.expect(round(l_pct_full_ind_ts(i).value, 9)).to_equal(round((l_stor_ts_data(i).value - l_stor_bottom) / (l_stor_top - l_stor_bottom) * 100, 9));
   end loop;
   -------------------------------------------------------------------------------------------------------
   -- get the max condition values for the percent flood pool used indicator for each time series value --
   -------------------------------------------------------------------------------------------------------
   cwms_level.get_level_indicator_max_values(
      p_cursor               => l_crsr,
      p_tsid                 => l_stor_tsid,
      p_start_time           => l_start_time,
      p_end_time             => l_start_time + (l_value_count)/24,
      p_time_zone            => c_timezone_id,
      p_specified_level_mask => cwms_util.split_text(l_stor_top_id, 5, '.'),
      p_indicator_id_mask    => cwms_util.split_text(l_pct_full_ind_id, 6, '.'),
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   fetch l_crsr into l_indicator_id, l_attribute_id, l_attribute_value, l_attribute_unit, l_indicator_values;
   close l_crsr;
   for i in 1..l_indicator_values.count loop
      if i <= l_stor_ts_data.count then
         ut.expect(l_indicator_values(i).date_time).to_equal(cast(l_stor_ts_data(i).date_time as date));
      end if;
      ------------------------------------------------------
      -- see note above about breakpoints in percent full --
      ------------------------------------------------------
      case
      when i < 15 then ut.expect(l_indicator_values(i).value).to_equal(0);
      when i < 21 then ut.expect(l_indicator_values(i).value).to_equal(1);
      when i < 31 then ut.expect(l_indicator_values(i).value).to_equal(2);
      when i < 41 then ut.expect(l_indicator_values(i).value).to_equal(3);
      when i < 47 then ut.expect(l_indicator_values(i).value).to_equal(4);
      else             ut.expect(l_indicator_values(i).value).to_equal(5);
      end case;
   end loop;
   -----------------------------------------------------------------------------------------
   -- evaluate the flood pool inflow rate indicator expression for each time series value --
   -----------------------------------------------------------------------------------------
   l_inflow_ind_ts := cwms_level.eval_level_indicator_expr(
      p_tsid                   => l_stor_tsid,
      p_start_time             => l_start_time,
      p_end_time               => l_start_time + (l_value_count)/24,
      p_unit                   => c_stor_unit,
      p_specified_level_id     => cwms_util.split_text(l_stor_top_id, 5, '.'),
      p_indicator_id           => cwms_util.split_text(l_inflow_ind_id, 6, '.'),
      p_ref_specified_level_id => cwms_util.split_text(l_stor_bottom_id, 5, '.'),
      p_time_zone              => c_timezone_id,
      p_office_id              => c_office_id);
   for i in 1..l_inflow_ind_ts.count loop
      ut.expect(l_inflow_ind_ts(i).date_time).to_equal(cast(l_stor_ts_data(i).date_time as date));
      if i = 1 then
         ----------------------------------------------------------------------------------------------------
         -- two consecutive stor values are requred to compute the inflow, so the first value will be null --
         ----------------------------------------------------------------------------------------------------
         ut.expect(l_inflow_ind_ts(i).value).to_be_null;
      else
         ut.expect(round(l_inflow_ind_ts(i).value, 9)).to_equal(round(10 * 43560 / 3600, 9));
      end if;
   end loop;
   -------------------------------------------------------------------------------------------
   -- get the max condition values for the inflow rate indicator for each time series value --
   -------------------------------------------------------------------------------------------
   cwms_level.get_level_indicator_max_values(
      p_cursor               => l_crsr,
      p_tsid                 => l_stor_tsid,
      p_start_time           => l_start_time,
      p_end_time             => l_start_time + (l_value_count)/24,
      p_time_zone            => c_timezone_id,
      p_specified_level_mask => cwms_util.split_text(l_stor_top_id, 5, '.'),
      p_indicator_id_mask    => cwms_util.split_text(l_inflow_ind_id, 6, '.'),
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   fetch l_crsr into l_indicator_id, l_attribute_id, l_attribute_value, l_attribute_unit, l_indicator_values;
   close l_crsr;
   for i in 1..l_indicator_values.count loop
      if i <= l_stor_ts_data.count then
         ut.expect(l_indicator_values(i).date_time).to_equal(cast(l_stor_ts_data(i).date_time as date));
      end if;
      ---------------------------------------------------------------------------------------------
      -- The inflow should always be 121 cfs (10 ac-ft per/hour * 43560 ft2/ac * 1 hour/3600 s). --
      -- The condition values are (1=>50, 2=>100, 3=>150, 4=>200, 5=>250) so the max condtion    --
      -- for the rate will always be 2. However, the percent full condtion must also be > 10 for --
      -- a minimum of 1 hour, so the value should be 0 below the first percent full breakpoint   --
      -- and 2 on and above it (see note above about percent full breakpoints).                  --
      ---------------------------------------------------------------------------------------------
      ut.expect(l_indicator_values(i).value).to_equal(case when i < 15 then 0 else 2 end);
   end loop;

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = l_elev_bottom_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(1);

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = l_elev_top_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(1);

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = l_stor_bottom_id;

   ut.expect(l_count).to_equal(1);

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = l_stor_top_id;

   ut.expect(l_count).to_equal(1);

   select count(*)
     into l_count
     from cwms_v_loc_lvl_indicator
    where office_id = c_office_id
      and level_indicator_id = l_pct_full_ind_id;

   ut.expect(l_count).to_equal(5);

   select count(*)
     into l_count
     from cwms_v_loc_lvl_indicator
    where office_id = c_office_id
      and level_indicator_id = l_inflow_ind_id;

   ut.expect(l_count).to_equal(5);

   -------------------------------------------------------------------------------
   -- retrieve the current location levels xml for later storage and comparison --
   -------------------------------------------------------------------------------
   l_levels_xml1 := cwms_level.retrieve_location_levels_xml_f(
      p_location_level_id_mask     => '*',
      p_attribute_id_mask          => '*',
      p_start_time                 => null,
      p_end_time                   => null,
      p_timezone_id                => 'UTC',
      p_unit_system                => 'EN',
      p_attribute_value            => null,
      p_attribute_unit             => null,
      p_level_type                 => 'VN',
      p_include_levels             => 'T',
      p_include_constituent_levels => 'F',
      p_include_level_sources      => 'T',
      p_include_level_labels       => 'T',
      p_include_level_indicators   => 'T',
      p_office_id                  => c_office_id);
   ------------------------------------------------------------------------
   -- delete the location levels + indicators and verify their deletions --
   ------------------------------------------------------------------------
   for rec in (select l_elev_bottom_id as level_id from dual
               union all
               select l_elev_top_id as level_id from dual
               union all
               select l_stor_bottom_id as level_id from dual
               union all
               select l_stor_top_id as level_id from dual
              )
   loop
      cwms_level.delete_location_level3(
         p_location_level_id          => rec.level_id,
         p_delete_indicators          => 'T',
         p_office_id                  => c_office_id,
         p_most_recent_effective_date => 'T');
   end loop;

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = l_elev_bottom_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

   select count(*)
     into l_count
     from cwms_v_location_level
    where office_id = c_office_id
      and location_level_id = l_elev_top_id
      and unit_system = 'EN';

   ut.expect(l_count).to_equal(0);

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = l_stor_bottom_id;

   ut.expect(l_count).to_equal(0);

   select count(*)
     into l_count
     from cwms_v_virtual_location_level
    where office_id = c_office_id
      and location_level_id = l_stor_top_id;

   ut.expect(l_count).to_equal(0);

   select count(*)
     into l_count
     from cwms_v_loc_lvl_indicator
    where office_id = c_office_id
      and level_indicator_id = l_pct_full_ind_id;

   ut.expect(l_count).to_equal(0);

   select count(*)
     into l_count
     from cwms_v_loc_lvl_indicator
    where office_id = c_office_id
      and level_indicator_id = l_inflow_ind_id;

   ut.expect(l_count).to_equal(0);
   -----------------------------------------------------
   -- re-store the location levels via xml and verify --
   -----------------------------------------------------
   cwms_level.store_location_levels_xml(
      p_errors         => l_errors,
      p_xml            => l_levels_xml1,
      p_fail_if_exists => 'F',
      p_fail_on_error  => 'T');

   ut.expect(l_errors).to_be_null;

   l_levels_xml2 := cwms_level.retrieve_location_levels_xml_f(
      p_location_level_id_mask     => '*',
      p_attribute_id_mask          => '*',
      p_start_time                 => null,
      p_end_time                   => null,
      p_timezone_id                => 'UTC',
      p_unit_system                => 'EN',
      p_attribute_value            => null,
      p_attribute_unit             => null,
      p_level_type                 => 'VN',
      p_include_levels             => 'T',
      p_include_constituent_levels => 'F',
      p_include_level_sources      => 'T',
      p_include_level_labels       => 'T',
      p_include_level_indicators   => 'T',
      p_office_id                  => c_office_id);

   ut.expect(l_levels_xml2).to_equal(l_levels_xml1);

end test_sources_labels_indicators_conditions_and_xml;

end test_cwms_level;
/
show errors;
