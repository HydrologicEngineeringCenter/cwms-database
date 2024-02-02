create or replace package test_lrts_updates as

--%suite(Test schema for full LRTS compatibility)

--%rollback(manual)
--%afterall(teardown)

--%test(CREATE_TS_CODE with zero offset without time zone)
procedure create_ts_code_no_tz1;
--%test(CREATE_TS_CODE with non-zero offset without time zone)
procedure create_ts_code_no_tz2;
--%test(CREATE_TS_CODE with with negative offset)
procedure create_lrts_ts_code_neg_offset;
--%test(CREATE_TS_CODE with with positive offset)
procedure create_lrts_ts_code_pos_offset;
--%test(UPDATE_TS_CODE with with negative offset)
procedure update_lrts_ts_code_neg_offset;
--%test(UPDATE_TS_CODE with with positive offset)
procedure update_lrts_ts_code_pos_offset;
--%test(Time zone in AT_CWMS_TS_SPEC table)
procedure tz_in_at_cwms_ts_spec;
--%test(Time zone in AT_CWMS_TS_ID table)
procedure tz_in_at_cwms_ts_id;
--%test(Time zone in AV_CWMS_TS_ID view)
procedure tz_in_av_cwms_ts_id;
--%test(Time zone in AV_CWMS_TS_ID2 view)
procedure tz_in_av_cwms_ts_id2;
--%test(Time zone in ZAV_CWMS_TS_ID view)
procedure tz_in_zav_cwms_ts_id;
--%test(Time zone in cwms_cat.cat_ts_id)
procedure tz_in_catalog;
--%test(RETRIEVE_TS_OUT overload)
procedure retrieve_ts_out;
--%test(RETRIEVE_TS [1.4] overload)
procedure retrieve_ts_old;
--%test(RETRIEVE_TS_2 [1.4] overload)
procedure retrieve_ts_2_old;
--%test(RETRIEVE_TS [2.0] overload)
procedure retrieve_ts;
--%test(ZRETRIEVE_TS overload)
procedure zretrieve_ts;
--%test(ZRETRIEVE_TS_JAVA overload)
procedure zretrieve_ts_java;
--%test(RETRIEVE_TS_MULTI)
procedure retrieve_ts_multi;
--%test(STORE_TS [2.0])
procedure store_ts;
--%test(STORE_TS [1.4])
procedure store_ts_old;
--%test(STORE_TS targeted for cxOracle client)
procedure store_ts_oracle;
--%test(STORE_TS targeted for jython client)
procedure store_ts_jython;
--%test(ZSTORE_TS)
procedure zstore_ts;
--%test (STORE_TS_MULTI)
procedure store_ts_multi;
--%test (ZSTORE_TS_MULTI)
procedure zstore_ts_multi;
--%test(SET_TSID_TIME_ZONE removed)
--%throws(-00900)
procedure set_tsid_time_zone;
--%test(SET_TS_TIME_ZONE removed)
--%throws(-00900)
procedure set_ts_time_zone;
--%test(CREATE_TS_TZ removed)
--%throws(-00900)
procedure create_ts_tz;
--%test(CREATE_TS_CODE_TZ removed)
--%throws(-00900)
procedure create_ts_code_tz;
--%test(GET_TSID_TIME_ZONE)
procedure get_tsid_time_zone;
--%test(GET_TS_TIME_ZONE)
procedure get_ts_time_zone;
--%test(retrieve_ts_multi_single_value - testing bugfix when a single value is retrieved, but an empty cursor is returned)
procedure retrieve_ts_multi_single_value;
--%test(update_lrts_ts_code_neg_offset_from_undefined - testing bugfix when an undefined offset isn't correctly updated from a negative offset)
procedure update_lrts_ts_code_neg_offset_from_undefined;
--%test(Test retrieve LRTS with P_TRIM = 'F')
procedure retrieve_lrts_untrimmed;
--%test(Test Function to generate UTC times for an LRTS time window)
procedure test_get_lrts_times_utc;
--%test(Test Jira issue CWDB-150 - Last hour of DST is not storing new time series)
procedure test_cwdb_150;
--%test(Test Jira issue CWDB-153 - Daily LRTS data returned at incorrect timestamps)
procedure test_cwdb_153;
--%test(Test formatting LRTS IDs on output)
procedure test_lrts_id_output_formatting;
--%test(Test formatting LRTS IDs on input)
procedure test_lrts_id_input_formatting;
procedure setup(p_options in varchar2 default null);
procedure teardown;
c_office_id     constant varchar2(3)  := '&&office_id';
c_location_ids  constant str_tab_t    := str_tab_t('TestLoc1', 'TestLoc1-WithSub', 'TestLoc2');
c_timezone_ids  constant str_tab_t    := str_tab_t('US/Central', null, 'CST'); -- make sure tz(2) is null
c_intvl_offsets constant number_tab_t := number_tab_t(0, 10, 20);
c_ts_id_part    constant varchar2(25) := '.Code.Inst.<intvl>.0.Test';
c_intervals     constant str_tab_t    := str_tab_t('0', '~1Hour', '1Hour');
c_ts_unit       constant varchar2(3)  := 'n/a';
c_start_time    constant date         := date '2020-01-01';
c_value_count   constant pls_integer  := 6;
end test_lrts_updates;
/
create or replace package body test_lrts_updates as
v_ts_ids         str_tab_t      := str_tab_t();
v_timezone_ids   str_tab_t      := str_tab_t();
v_timezone_codes number_tab_t   := number_tab_t();
c_ts_values_utc  ztsv_array_tab := ztsv_array_tab();
--------------------------------------------------------------------------------
-- procedure clear_caches
--------------------------------------------------------------------------------
procedure clear_caches
is
begin
   cwms_cache.clear(cwms_loc.g_location_code_cache);
   cwms_cache.clear(cwms_loc.g_location_id_cache);
   cwms_cache.clear(cwms_ts.g_ts_code_cache);
   cwms_cache.clear(cwms_ts.g_ts_id_cache);
   cwms_cache.clear(cwms_ts.g_ts_id_alias_cache);
   cwms_cache.clear(cwms_ts.g_is_lrts_cache);
end clear_caches;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   l_ts_codes number_tab_t;
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   clear_caches;
   for i in 1..c_location_ids.count loop
      select ts_code
        bulk collect
        into l_ts_codes
        from at_cwms_ts_id
       where db_office_id = c_office_id
         and location_id = c_location_ids(i);
      for j in 1..l_ts_codes.count loop
         for rec in (select table_name from at_ts_table_properties) loop
            execute immediate 'delete from '||rec.table_name||' where ts_code = :ts_code' using l_ts_codes(j);
         end loop;
         delete from at_ts_extents where ts_code = l_ts_codes(j);
         delete from at_cwms_ts_spec where ts_code = l_ts_codes(j);
      end loop;
      begin
         cwms_loc.delete_location(
            p_location_id   => c_location_ids(i),
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => c_office_id);
      exception
         when exc_location_id_not_found then null;
      end;
   end loop;
   commit;
   clear_caches;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup( -- (sets up LRTS without using routines under test)
   p_options in varchar2 default null)
is
   l_ts_values_loc   ztsv_array_tab := ztsv_array_tab();
   l_empty_ts_values ztsv_array     := ztsv_array();
   l_cwms_ts_id      cwms_v_ts_id.cwms_ts_id%type;
   l_intvl_offset    integer;
begin
   ------------------------------
   -- start with a clean slate --
   ------------------------------
   teardown;
   if p_options is null or instr(p_options, 'INIT') > 0 then
      --------------------------------
      -- populate package_variables --
      --------------------------------
      v_ts_ids.extend(c_location_ids.count);
      v_timezone_ids.extend(c_location_ids.count);
      v_timezone_codes.extend(c_location_ids.count);
      for i in 1..c_location_ids.count loop
         v_ts_ids(i)         := c_location_ids(i)||c_ts_id_part;
         v_timezone_ids(i)   := cwms_util.get_time_zone_name(case when c_timezone_ids(i) is null then c_timezone_ids(i-1) else c_timezone_ids(i) end);
         v_timezone_codes(i) := cwms_util.get_time_zone_code(case when c_timezone_ids(i) is null then c_timezone_ids(i-1) else c_timezone_ids(i) end);
      end loop;
      ---------------------------------------
      -- create the UTC time series values --
      ---------------------------------------
      c_ts_values_utc.extend(c_location_ids.count);
      l_ts_values_loc.extend(c_location_ids.count);
      for i in 1..c_location_ids.count loop
         c_ts_values_utc(i) := ztsv_array();
         c_ts_values_utc(i).extend(c_value_count);
         for j in 1..c_value_count loop
            c_ts_values_utc(i)(j) := ztsv_type(
               date_time    => c_start_time + (j-1) / 24 + c_intvl_offsets(i) / 1440,
               value        => j,
               quality_code => 0);
         end loop;
      end loop;
   end if;
   -----------------------
   -- for each location --
   -----------------------
   for i in 1..c_location_ids.count loop
      if p_options is null or instr(p_options, 'STORE_LOCATIONS') > 0 then
         -------------------------
         -- create the location --
         -------------------------
         cwms_loc.store_location2(
            p_location_id				=> c_location_ids(i),
            p_location_type			=> null,
            p_elevation 				=> null,
            p_elev_unit_id 			=> null,
            p_vertical_datum			=> null,
            p_latitude					=> null,
            p_longitude 				=> null,
            p_horizontal_datum		=> null,
            p_public_name				=> null,
            p_long_name 				=> null,
            p_description				=> null,
            p_time_zone_id 			=> c_timezone_ids(i),
            p_county_name				=> null,
            p_state_initial			=> null,
            p_active 					=> null,
            p_location_kind_id		=> null,
            p_map_label 				=> null,
            p_published_latitude 	=> null,
            p_published_longitude	=> null,
            p_bounding_office_id 	=> null,
            p_nation_id 				=> null,
            p_nearest_city 			=> null,
            p_ignorenulls				=> 'T',
            p_db_office_id 			=> c_office_id);
      end if;
      if p_options is null or instr(p_options, 'STORE_TIMESERIES') > 0 then
         -----------------------------------------------
         -- create the local time series value in utc --
         -----------------------------------------------
         select ztsv_type(cwms_util.change_timezone(date_time, cwms_loc.get_local_timezone(c_location_ids(i), c_office_id), 'UTC'),
                         value,
                         quality_code
                        )
           bulk collect
           into l_ts_values_loc(i)
           from table(c_ts_values_utc(i));
         for j in 1..c_intervals.count loop
            l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            l_intvl_offset := case
                              when c_intervals(j) = '0' then null
                              when substr(c_intervals(j), 1, 1) = '~' then -c_intvl_offsets(i)
                              else c_intvl_offsets(i)
                              end;
            ------------------------------------------
            -- store the time series without values --
            ------------------------------------------
            cwms_ts.zstore_ts(
               p_cwms_ts_id      => l_cwms_ts_id,
               p_units           => c_ts_unit,
               p_timeseries_data => l_empty_ts_values,
               p_store_rule      => cwms_util.replace_all,
               p_override_prot   => 'F',
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => c_office_id);
            --------------------------------
            -- update the interval offset --
            --------------------------------
            cwms_ts.update_ts_id(
               p_cwms_ts_id             => l_cwms_ts_id,
               p_interval_utc_offset    => l_intvl_offset,
               p_snap_forward_minutes   => null,
               p_snap_backward_minutes  => null,
               p_local_reg_time_zone_id => null,
               p_ts_active_flag         => null,
               p_db_office_id           => c_office_id);
            ---------------------------------------
            -- store the time series with values --
            ---------------------------------------
            cwms_ts.zstore_ts(
               p_cwms_ts_id      => l_cwms_ts_id,
               p_units           => c_ts_unit,
               p_timeseries_data => l_ts_values_loc(i),
               p_store_rule      => cwms_util.replace_all,
               p_override_prot   => 'F',
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => c_office_id);
         end loop;
      end if;
   end loop;
   commit;
end setup;
--------------------------------------------------------------------------------
-- procedure create_ts_code_no_tz1
--------------------------------------------------------------------------------
procedure create_ts_code_no_tz1
is
   l_ts_code integer;
begin
   setup('INIT');

   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> null,
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);

   cwms_ts.create_ts_code (
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '0'),
      p_utc_offset        => -10, -- offset will be ignored
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);

end create_ts_code_no_tz1;
--------------------------------------------------------------------------------
-- procedure create_ts_code_no_tz2
--------------------------------------------------------------------------------
procedure create_ts_code_no_tz2
is
   l_ts_code integer;
begin
   setup('INIT');

   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> null,
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);

   cwms_ts.create_ts_code (
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
      p_utc_offset        => -10,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);
end create_ts_code_no_tz2;
--------------------------------------------------------------------------------
-- procedure create_lrts_ts_code_neg_offset
--------------------------------------------------------------------------------
procedure create_lrts_ts_code_neg_offset
is
   l_ts_code    integer;
   l_offset_in  integer := -10;
   l_offset_out integer;
begin
   setup('INIT');

   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);

   cwms_ts.create_ts_code (
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
      p_utc_offset        => l_offset_in,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);

   select interval_utc_offset
     into l_offset_out
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

   ut.expect(l_offset_out).to_equal(l_offset_in);
end create_lrts_ts_code_neg_offset;
--------------------------------------------------------------------------------
-- procedure create_lrts_ts_code_pos_offset
--------------------------------------------------------------------------------
procedure create_lrts_ts_code_pos_offset
is
   l_ts_code    integer;
   l_offset_in  integer := 10;
   l_offset_out integer;
begin
   setup('INIT');

   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);

   cwms_ts.create_ts_code (
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
      p_utc_offset        => l_offset_in,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);

   select interval_utc_offset
     into l_offset_out
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

   ut.expect(l_offset_out).to_equal(-l_offset_in);
end create_lrts_ts_code_pos_offset;
--------------------------------------------------------------------------------
-- procedure update_lrts_ts_code_neg_offset
--------------------------------------------------------------------------------
procedure update_lrts_ts_code_neg_offset
is
   l_ts_code    integer;
   l_offset_1   integer := -10;
   l_offset_2   integer := -20;
   l_offset_out integer;
begin
   setup('INIT');

   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);

   cwms_ts.create_ts_code (
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
      p_utc_offset        => l_offset_1,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);

   cwms_ts.update_ts_id (
      p_ts_code                => l_ts_code,
      p_interval_utc_offset    => l_offset_2,
      p_snap_forward_minutes   => null,
      p_snap_backward_minutes  => null,
      p_local_reg_time_zone_id => null,
      p_ts_active_flag         => null);

   select interval_utc_offset
     into l_offset_out
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

   ut.expect(l_offset_out).to_equal(l_offset_2);
end update_lrts_ts_code_neg_offset;

--------------------------------------------------------------------------------
-- procedure update_lrts_ts_code_neg_offset_from_undefined
--------------------------------------------------------------------------------
procedure update_lrts_ts_code_neg_offset_from_undefined
    is
    l_ts_code    integer;
    l_offset   integer := -10;
    l_offset_out integer;
begin
    setup('INIT');

    cwms_loc.store_location2(
            p_location_id				=> c_location_ids(1),
            p_location_type			=> null,
            p_elevation 				=> null,
            p_elev_unit_id 			=> null,
            p_vertical_datum			=> null,
            p_latitude					=> null,
            p_longitude 				=> null,
            p_horizontal_datum		=> null,
            p_public_name				=> null,
            p_long_name 				=> null,
            p_description				=> null,
            p_time_zone_id 			=> c_timezone_ids(1),
            p_county_name				=> null,
            p_state_initial			=> null,
            p_active 					=> null,
            p_location_kind_id		=> null,
            p_map_label 				=> null,
            p_published_latitude 	=> null,
            p_published_longitude	=> null,
            p_bounding_office_id 	=> null,
            p_nation_id 				=> null,
            p_nearest_city 			=> null,
            p_ignorenulls				=> 'T',
            p_db_office_id 			=> c_office_id);

    cwms_ts.create_ts_code (
            p_ts_code           => l_ts_code,
            p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
            p_utc_offset        => cwms_util.utc_offset_undefined,
            p_interval_forward  => null,
            p_interval_backward => null,
            p_versioned         => 'F',
            p_active_flag       => 'T',
            p_fail_if_exists    => 'T',
            p_office_id         => c_office_id);

    declare
        l_ts_values tsv_array := tsv_array();
    begin
        select tsv_type(
            from_tz(cast(date_time + abs(l_offset) / 1440 as timestamp), 'UTC'),
            value,
            quality_code)
        bulk collect
        into l_ts_values
        from table(c_ts_values_utc(1));

        cwms_ts.store_ts(
                p_office_id       => c_office_id,
                p_cwms_ts_id      => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
                p_units           => c_ts_unit,
                p_timeseries_data => l_ts_values,
                p_store_rule      => cwms_util.replace_all,
                p_override_prot   => 0,
                p_versiondate     => cwms_util.non_versioned,
                p_create_as_lrts  => 'F'
            );
    end;

    cwms_ts.update_ts_id (
            p_ts_code                => l_ts_code,
            p_interval_utc_offset    => l_offset,
            p_snap_forward_minutes   => null,
            p_snap_backward_minutes  => null,
            p_local_reg_time_zone_id => null,
            p_ts_active_flag         => null);

    select interval_utc_offset
    into l_offset_out
    from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_offset_out).to_equal(l_offset);
end update_lrts_ts_code_neg_offset_from_undefined;
--------------------------------------------------------------------------------
-- procedure update_lrts_ts_code_pos_offset
--------------------------------------------------------------------------------
procedure update_lrts_ts_code_pos_offset
is
   l_ts_code    integer;
   l_offset_1   integer := -10;
   l_offset_2   integer := 20;
   l_offset_out integer;
begin
   setup('INIT');

   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);

   cwms_ts.create_ts_code (
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'),
      p_utc_offset        => l_offset_1,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);

   cwms_ts.update_ts_id (
      p_ts_code                => l_ts_code,
      p_interval_utc_offset    => l_offset_2,
      p_snap_forward_minutes   => null,
      p_snap_backward_minutes  => null,
      p_local_reg_time_zone_id => null,
      p_ts_active_flag         => null);

   select interval_utc_offset
     into l_offset_out
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

   ut.expect(l_offset_out).to_equal(-l_offset_2);
end update_lrts_ts_code_pos_offset;
--------------------------------------------------------------------------------
-- procedure tz_in_at_cwms_ts_spec
--------------------------------------------------------------------------------
procedure tz_in_at_cwms_ts_spec
is
   l_time_zone_code  integer;
   l_cwms_ts_id      cwms_v_ts_id.cwms_ts_id%type;
   l_timezone_ids    str_tab_t;
   l_timezone_codes  number_tab_t;
begin
   setup;
   for pass in 1..3 loop
      case
      when pass = 1 then
         -----------------------------------
         -- test with original time zones --
         -----------------------------------
         l_timezone_ids := v_timezone_ids;
      when pass = 2 then
         -----------------------------------------------------------
         -- test with updated time zones (sub-location tz = null) --
         -----------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'PST8PDT';
         l_timezone_ids(2) := null;
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      else
         ----------------------------------------------------------------------------------
         -- test with updated time zones (sub-location tz differs from base-location tz) --
         ----------------------------------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'MST7MDT';
         l_timezone_ids(2) := 'EST5EDT';
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      end case;
      l_timezone_codes  := number_tab_t();
      for i in 1..c_location_ids.count loop
         l_timezone_codes.extend;
         l_timezone_codes(i) := cwms_util.get_time_zone_code(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         l_timezone_ids(i)   := cwms_util.get_time_zone_name(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         for j in 1..c_intervals.count loop
            l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            select time_zone_code
              into l_time_zone_code
              from at_cwms_ts_spec
             where ts_code = (select ts_code
                                from at_cwms_ts_id
                               where db_office_id = c_office_id
                                 and cwms_ts_id = l_cwms_ts_id
                             );
            ut.expect(l_time_zone_code).to_equal(l_timezone_codes(i));
         end loop;
      end loop;
   end loop;
end tz_in_at_cwms_ts_spec;
--------------------------------------------------------------------------------
-- procedure tz_in_at_cwms_ts_id
--------------------------------------------------------------------------------
procedure tz_in_at_cwms_ts_id
is
   l_time_zone_id cwms_v_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   cwms_v_ts_id.cwms_ts_id%type;
   l_timezone_ids str_tab_t;
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;

   for pass in 1..3 loop
      case
      when pass = 1 then
         -----------------------------------
         -- test with original time zones --
         -----------------------------------
         l_timezone_ids := v_timezone_ids;
      when pass = 2 then
         -----------------------------------------------------------
         -- test with updated time zones (sub-location tz = null) --
         -----------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'PST8PDT';
         l_timezone_ids(2) := null;
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      else
         ----------------------------------------------------------------------------------
         -- test with updated time zones (sub-location tz differs from base-location tz) --
         ----------------------------------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'MST7MDT';
         l_timezone_ids(2) := 'EST5EDT';
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      end case;
      for i in 1..c_location_ids.count loop
         l_timezone_ids(i)   := cwms_util.get_time_zone_name(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         for j in 1..c_intervals.count loop
            l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            begin
               execute immediate '
               select time_zone_id
                 from at_cwms_ts_id
                where db_office_id = :c_office_id
                  and cwms_ts_id = :v_ts_id'
                 into l_time_zone_id
                using c_office_id,
                      l_cwms_ts_id;
            exception
               when exc_invalid_identifier then null;
            end;
            ut.expect(l_time_zone_id).to_equal(l_timezone_ids(i));
         end loop;
      end loop;
   end loop;
end tz_in_at_cwms_ts_id;
--------------------------------------------------------------------------------
-- procedure tz_in_av_cwms_ts_id
--------------------------------------------------------------------------------
procedure tz_in_av_cwms_ts_id
is
   l_time_zone_id cwms_v_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   cwms_v_ts_id.cwms_ts_id%type;
   l_timezone_ids str_tab_t;
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;

   for pass in 1..3 loop
      case
      when pass = 1 then
         -----------------------------------
         -- test with original time zones --
         -----------------------------------
         l_timezone_ids := v_timezone_ids;
      when pass = 2 then
         -----------------------------------------------------------
         -- test with updated time zones (sub-location tz = null) --
         -----------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'PST8PDT';
         l_timezone_ids(2) := null;
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      else
         ----------------------------------------------------------------------------------
         -- test with updated time zones (sub-location tz differs from base-location tz) --
         ----------------------------------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'MST7MDT';
         l_timezone_ids(2) := 'EST5EDT';
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      end case;
      for i in 1..c_location_ids.count loop
         l_timezone_ids(i)   := cwms_util.get_time_zone_name(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         for j in 1..c_intervals.count loop
            l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            begin
               execute immediate '
               select time_zone_id
                 from cwms_v_ts_id
                where db_office_id = :c_office_id
                  and cwms_ts_id = :v_ts_id'
                 into l_time_zone_id
                using c_office_id,
                      l_cwms_ts_id;
            exception
               when exc_invalid_identifier then null;
            end;
            ut.expect(l_time_zone_id).to_equal(l_timezone_ids(i));
         end loop;
      end loop;
   end loop;
end tz_in_av_cwms_ts_id;
--------------------------------------------------------------------------------
-- procedure tz_in_av_cwms_ts_id2
--------------------------------------------------------------------------------
procedure tz_in_av_cwms_ts_id2
is
   l_time_zone_id cwms_v_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   cwms_v_ts_id.cwms_ts_id%type;
   l_timezone_ids str_tab_t;
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;

   for pass in 1..3 loop
      case
      when pass = 1 then
         -----------------------------------
         -- test with original time zones --
         -----------------------------------
         l_timezone_ids := v_timezone_ids;
      when pass = 2 then
         -----------------------------------------------------------
         -- test with updated time zones (sub-location tz = null) --
         -----------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'PST8PDT';
         l_timezone_ids(2) := null;
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      else
         ----------------------------------------------------------------------------------
         -- test with updated time zones (sub-location tz differs from base-location tz) --
         ----------------------------------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'MST7MDT';
         l_timezone_ids(2) := 'EST5EDT';
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      end case;
      for i in 1..c_location_ids.count loop
         l_timezone_ids(i) := cwms_util.get_time_zone_name(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         for j in 1..c_intervals.count loop
            l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            begin
               execute immediate '
               select time_zone_id
                 from cwms_v_ts_id2
                where db_office_id = :c_office_id
                  and cwms_ts_id = :v_ts_id'
                 into l_time_zone_id
                using c_office_id,
                      l_cwms_ts_id;
            exception
               when exc_invalid_identifier then null;
            end;
            ut.expect(l_time_zone_id).to_equal(l_timezone_ids(i));
         end loop;
      end loop;
   end loop;
end tz_in_av_cwms_ts_id2;
--------------------------------------------------------------------------------
-- procedure tz_in_av_cwms_ts_id
--------------------------------------------------------------------------------
procedure tz_in_zav_cwms_ts_id
is
   l_time_zone_id cwms_v_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   cwms_v_ts_id.cwms_ts_id%type;
   l_timezone_ids str_tab_t;
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;

   for pass in 1..3 loop
      case
      when pass = 1 then
         -----------------------------------
         -- test with original time zones --
         -----------------------------------
         l_timezone_ids := v_timezone_ids;
      when pass = 2 then
         -----------------------------------------------------------
         -- test with updated time zones (sub-location tz = null) --
         -----------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'PST8PDT';
         l_timezone_ids(2) := null;
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      else
         ----------------------------------------------------------------------------------
         -- test with updated time zones (sub-location tz differs from base-location tz) --
         ----------------------------------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'MST7MDT';
         l_timezone_ids(2) := 'EST5EDT';
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      end case;
      for i in 1..c_location_ids.count loop
         l_timezone_ids(i) := cwms_util.get_time_zone_name(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         for j in 1..c_intervals.count loop
            l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            begin
               execute immediate '
               select time_zone_id
                 from zav_cwms_ts_id
                where db_office_id = :c_office_id
                  and cwms_ts_id = :v_ts_id'
                 into l_time_zone_id
                using c_office_id,
                      l_cwms_ts_id;
            exception
               when exc_invalid_identifier then null;
            end;
            ut.expect(l_time_zone_id).to_equal(l_timezone_ids(i));
         end loop;
      end loop;
   end loop;
end tz_in_zav_cwms_ts_id;
--------------------------------------------------------------------------------
-- procedure tz_in_catalog
--------------------------------------------------------------------------------
procedure tz_in_catalog
is
   l_crsr                sys_refcursor;
   l_db_office_id        varchar2(16);
   l_base_location_id    varchar2(24);
   l_cwms_ts_id_in       cwms_v_ts_id.cwms_ts_id%type;
   l_interval_utc_offset number;
   l_timezone_id         cwms_v_ts_id.cwms_ts_id%type;
   l_ts_active_flag      varchar2(1);
   l_user_privileges     number;
   l_cwms_ts_id_out      cwms_v_ts_id.cwms_ts_id%type;
   l_timezone_ids        str_tab_t;
begin
   setup;
   for pass in 1..3 loop
      case
      when pass = 1 then
         -----------------------------------
         -- test with original time zones --
         -----------------------------------
         l_timezone_ids := v_timezone_ids;
      when pass = 2 then
         -----------------------------------------------------------
         -- test with updated time zones (sub-location tz = null) --
         -----------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'PST8PDT';
         l_timezone_ids(2) := null;
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      else
         ----------------------------------------------------------------------------------
         -- test with updated time zones (sub-location tz differs from base-location tz) --
         ----------------------------------------------------------------------------------
         l_timezone_ids    := c_timezone_ids;
         l_timezone_ids(1) := 'MST7MDT';
         l_timezone_ids(2) := 'EST5EDT';
         for i in 1..2 loop
            cwms_loc.store_location(
               p_location_id  => c_location_ids(i),
               p_time_zone_id => l_timezone_ids(i),
               p_db_office_id => c_office_id);
            commit;
         end loop;
      end case;
      for i in 1..c_location_ids.count loop
         l_timezone_ids(i) := cwms_util.get_time_zone_name(case when l_timezone_ids(i) is null then l_timezone_ids(i-1) else l_timezone_ids(i) end);
         for j in 1..c_intervals.count loop
            l_cwms_ts_id_in := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
            cwms_cat.cat_ts_id(
               p_cwms_cat            => l_crsr,
               p_ts_subselect_string => l_cwms_ts_id_in,
               p_loc_category_id     => null,
               p_loc_group_id        => null,
               p_ts_category_id      => null,
               p_ts_group_id         => null,
               p_db_office_id        => c_office_id);
            fetch l_crsr
             into l_db_office_id,
                  l_base_location_id,
                  l_cwms_ts_id_out,
                  l_interval_utc_offset,
                  l_timezone_id,
                  l_ts_active_flag,
                  l_user_privileges;
            close l_crsr;
            ut.expect(l_db_office_id).to_equal(c_office_id);
            ut.expect(l_cwms_ts_id_out).to_equal(l_cwms_ts_id_in);
            ut.expect(l_interval_utc_offset).to_equal(case
                                                      when c_intervals(j) = '0' then cwms_util.utc_offset_irregular
                                                      when substr(c_intervals(j), 1, 1) = '~' then -c_intvl_offsets(i)
                                                      else c_intvl_offsets(i)
                                                      end);
            ut.expect(l_timezone_id).to_equal(l_timezone_ids(i));
         end loop;
      end loop;
   end loop;
end tz_in_catalog;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_out
--------------------------------------------------------------------------------
procedure retrieve_ts_out
is
   l_crsr             sys_refcursor;
   l_cwms_ts_id_in    cwms_v_ts_id.cwms_ts_id%type;
   l_cwms_ts_id_out   cwms_v_ts_id.cwms_ts_id%type;
   l_units_out        cwms_v_ts_id.unit_id%type;
   l_time_zone_id_in  cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_out cwms_v_ts_id.cwms_ts_id%type;
   l_date_times       date_table_type;
   l_values           double_tab_t;
   l_quality_codes    number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id_in := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_time_zone_id_in := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         -------------------------------------------------------
         -- first the version without the time zone parameter --
         -------------------------------------------------------
         cwms_ts.retrieve_ts_out (
            p_at_tsv_rc       => l_crsr,
            p_cwms_ts_id_out  => l_cwms_ts_id_out,
            p_units_out       => l_units_out,
            p_cwms_ts_id      => l_cwms_ts_id_in,
            p_units           => c_ts_unit,
            p_start_time      => c_start_time - 1,
            p_end_time        => c_start_time + 2,
            p_time_zone       => l_time_zone_id_in,
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => cwms_util.non_versioned,
            p_max_version     => 'T',
            p_office_id       => c_office_id);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;

         ut.expect(l_cwms_ts_id_out).to_equal(l_cwms_ts_id_in);
         ut.expect(l_units_out).to_equal(c_ts_unit);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
         ---------------------------------------------------
         -- next the version with the time zone parameter --
         ---------------------------------------------------
         cwms_ts.retrieve_ts_out (
            p_at_tsv_rc       => l_crsr,
            p_cwms_ts_id_out  => l_cwms_ts_id_out,
            p_units_out       => l_units_out,
            p_time_zone_id    => l_time_zone_id_out,
            p_cwms_ts_id      => l_cwms_ts_id_in,
            p_units           => c_ts_unit,
            p_start_time      => c_start_time - 1,
            p_end_time        => c_start_time + 2,
            p_time_zone       => l_time_zone_id_in,
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => cwms_util.non_versioned,
            p_max_version     => 'T',
            p_office_id       => c_office_id);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_cwms_ts_id_out).to_equal(l_cwms_ts_id_in);
         ut.expect(l_units_out).to_equal(c_ts_unit);
         ut.expect(l_time_zone_id_out).to_equal(l_time_zone_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
      end loop;
   end loop;
end retrieve_ts_out;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_old
--------------------------------------------------------------------------------
procedure retrieve_ts_old
is
   l_crsr             sys_refcursor;
   l_cwms_ts_id       cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_out cwms_v_ts_id.cwms_ts_id%type;
   l_date_times       date_table_type;
   l_values           double_tab_t;
   l_quality_codes    number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id      := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_time_zone_id_in := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         -------------------------------------------------------
         -- first the version without the time zone parameter --
         -------------------------------------------------------
         cwms_ts.retrieve_ts (
            p_at_tsv_rc   => l_crsr,
            p_units       => c_ts_unit,
            p_officeid    => c_office_id,
            p_cwms_ts_id  => l_cwms_ts_id,
            p_start_time  => c_start_time - 1,
            p_end_time    => c_start_time + 2,
            p_timezone    => l_time_zone_id_in,
            p_trim        => 1,
            p_inclusive   => 1,
            p_versiondate => cwms_util.non_versioned,
            p_max_version => 1);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
         ---------------------------------------------------
         -- next the version with the time zone parameter --
         ---------------------------------------------------
         cwms_ts.retrieve_ts (
            p_at_tsv_rc    => l_crsr,
            p_time_zone_id => l_time_zone_id_out,
            p_units        => c_ts_unit,
            p_officeid     => c_office_id,
            p_cwms_ts_id   => l_cwms_ts_id,
            p_start_time   => c_start_time - 1,
            p_end_time     => c_start_time + 2,
            p_timezone     => l_time_zone_id_in,
            p_trim         => 1,
            p_inclusive    => 1,
            p_versiondate  => cwms_util.non_versioned,
            p_max_version  => 1);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_time_zone_id_out).to_equal(l_time_zone_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
      end loop;
   end loop;
end retrieve_ts_old;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_2_old
--------------------------------------------------------------------------------
procedure retrieve_ts_2_old
is
   l_crsr             sys_refcursor;
   l_cwms_ts_id       cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_out cwms_v_ts_id.cwms_ts_id%type;
   l_date_times       date_table_type;
   l_values           double_tab_t;
   l_quality_codes    number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id      := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_time_zone_id_in := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         -------------------------------------------------------
         -- first the version without the time zone parameter --
         -------------------------------------------------------
         cwms_ts.retrieve_ts_2 (
            p_at_tsv_rc   => l_crsr,
            p_units       => c_ts_unit,
            p_officeid    => c_office_id,
            p_cwms_ts_id  => l_cwms_ts_id,
            p_start_time  => c_start_time - 1,
            p_end_time    => c_start_time + 2,
            p_timezone    => l_time_zone_id_in,
            p_trim        => 1,
            p_inclusive   => 1,
            p_versiondate => cwms_util.non_versioned,
            p_max_version => 1);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
         ---------------------------------------------------
         -- next the version with the time zone parameter --
         ---------------------------------------------------
         cwms_ts.retrieve_ts_2 (
            p_at_tsv_rc    => l_crsr,
            p_time_zone_id => l_time_zone_id_out,
            p_units        => c_ts_unit,
            p_officeid     => c_office_id,
            p_cwms_ts_id   => l_cwms_ts_id,
            p_start_time   => c_start_time - 1,
            p_end_time     => c_start_time + 2,
            p_timezone     => l_time_zone_id_in,
            p_trim         => 1,
            p_inclusive    => 1,
            p_versiondate  => cwms_util.non_versioned,
            p_max_version  => 1);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_time_zone_id_out).to_equal(l_time_zone_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
      end loop;
   end loop;
end retrieve_ts_2_old;
--------------------------------------------------------------------------------
-- procedure retrieve_ts
--------------------------------------------------------------------------------
procedure retrieve_ts
is
l_crsr             sys_refcursor;
   l_cwms_ts_id       cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_out cwms_v_ts_id.cwms_ts_id%type;
   l_date_times       date_table_type;
   l_values           double_tab_t;
   l_quality_codes    number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id      := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_time_zone_id_in := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         -------------------------------------------------------
         -- first the version without the time zone parameter --
         -------------------------------------------------------
         cwms_ts.retrieve_ts (
            p_at_tsv_rc       => l_crsr,
            p_cwms_ts_id      => l_cwms_ts_id,
            p_units           => c_ts_unit,
            p_start_time      => c_start_time - 1,
            p_end_time        => c_start_time + 2,
            p_time_zone       => l_time_zone_id_in,
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_version_date    => cwms_util.non_versioned,
            p_max_version     => 'T',
            p_office_id       => c_office_id);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
         ---------------------------------------------------
         -- next the version with the time zone parameter --
         ---------------------------------------------------
         cwms_ts.retrieve_ts (
            p_at_tsv_rc       => l_crsr,
            p_time_zone_id    => l_time_zone_id_out,
            p_cwms_ts_id      => l_cwms_ts_id,
            p_units           => c_ts_unit,
            p_start_time      => c_start_time - 1,
            p_end_time        => c_start_time + 2,
            p_time_zone       => l_time_zone_id_in,
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_version_date    => cwms_util.non_versioned,
            p_max_version     => 'T',
            p_office_id       => c_office_id);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_time_zone_id_out).to_equal(l_time_zone_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440);
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
      end loop;
   end loop;
end retrieve_ts;
--------------------------------------------------------------------------------
-- procedure zretrieve_ts
--------------------------------------------------------------------------------
procedure zretrieve_ts
is
   l_crsr             sys_refcursor;
   l_cwms_ts_id       cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_out cwms_v_ts_id.cwms_ts_id%type;
   l_date_times       date_table_type;
   l_values           double_tab_t;
   l_quality_codes    number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id      := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_time_zone_id_in := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         -------------------------------------------------------
         -- first the version without the time zone parameter --
         -------------------------------------------------------
         cwms_ts.zretrieve_ts (
            p_at_tsv_rc    => l_crsr,
            p_units        => c_ts_unit,
            p_cwms_ts_id   => l_cwms_ts_id,
            p_start_time   => c_start_time - 1,
            p_end_time     => c_start_time + 2,
            p_trim         => 'T',
            p_inclusive    => null,
            p_version_date => cwms_util.non_versioned,
            p_max_version  => 'T',
            p_db_office_id => c_office_id);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(cwms_util.change_timezone(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440, l_time_zone_id_in, 'UTC'));
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
         ---------------------------------------------------
         -- next the version with the time zone parameter --
         ---------------------------------------------------
         cwms_ts.zretrieve_ts (
            p_at_tsv_rc    => l_crsr,
            p_time_zone_id => l_time_zone_id_out,
            p_units        => c_ts_unit,
            p_cwms_ts_id   => l_cwms_ts_id,
            p_start_time   => c_start_time - 1,
            p_end_time     => c_start_time + 2,
            p_trim         => 'T',
            p_inclusive    => null,
            p_version_date => cwms_util.non_versioned,
            p_max_version  => 'T',
            p_db_office_id => c_office_id);

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;
         ut.expect(l_time_zone_id_out).to_equal(l_time_zone_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(cwms_util.change_timezone(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440, l_time_zone_id_in, 'UTC'));
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
      end loop;
   end loop;
end zretrieve_ts;
--------------------------------------------------------------------------------
-- procedure zretrieve_ts_java
--------------------------------------------------------------------------------
procedure zretrieve_ts_java
is
   l_crsr             sys_refcursor;
   l_start_time       date;
   l_end_time         date;
   l_transaction_time date;
   l_units_out        cwms_v_ts_id.unit_id%type;
   l_cwms_ts_id_in    cwms_v_ts_id.cwms_ts_id%type;
   l_cwms_ts_id_out   cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  cwms_v_ts_id.cwms_ts_id%type;
   l_time_zone_id_out cwms_v_ts_id.cwms_ts_id%type;
   l_date_times       date_table_type;
   l_values           double_tab_t;
   l_quality_codes    number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id_in   := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_time_zone_id_in := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         -------------------------------------------------------
         -- first the version without the time zone parameter --
         -------------------------------------------------------
         l_start_time := sysdate;
         cwms_ts.zretrieve_ts_java (
            p_transaction_time => l_transaction_time,
            p_at_tsv_rc        => l_crsr,
            p_units_out        => l_units_out,
            p_cwms_ts_id_out   => l_cwms_ts_id_out,
            p_units_in         => c_ts_unit,
            p_cwms_ts_id_in    => l_cwms_ts_id_in,
            p_start_time       => c_start_time - 1,
            p_end_time         => c_start_time + 2,
            p_trim             => 'T',
            p_inclusive        => null,
            p_version_date     => cwms_util.non_versioned,
            p_max_version      => 'T',
            p_db_office_id     => c_office_id);
         l_end_time := sysdate;

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;

         ut.expect(l_transaction_time).to_be_greater_or_equal(l_start_time);
         ut.expect(l_transaction_time).to_be_less_or_equal(l_end_time);
         ut.expect(l_units_out).to_equal(c_ts_unit);
         ut.expect(l_cwms_ts_id_out).to_equal(l_cwms_ts_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(cwms_util.change_timezone(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440, l_time_zone_id_in, 'UTC'));
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
         ---------------------------------------------------
         -- next the version with the time zone parameter --
         ---------------------------------------------------
         l_start_time := sysdate;
         cwms_ts.zretrieve_ts_java (
            p_transaction_time => l_transaction_time,
            p_at_tsv_rc        => l_crsr,
            p_units_out        => l_units_out,
            p_cwms_ts_id_out   => l_cwms_ts_id_out,
            p_time_zone_id     => l_time_zone_id_out,
            p_units_in         => c_ts_unit,
            p_cwms_ts_id_in    => l_cwms_ts_id_in,
            p_start_time       => c_start_time - 1,
            p_end_time         => c_start_time + 2,
            p_trim             => 'T',
            p_inclusive        => null,
            p_version_date     => cwms_util.non_versioned,
            p_max_version      => 'T',
            p_db_office_id     => c_office_id);
         l_end_time := sysdate;

         fetch l_crsr
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes
         limit 1000;

         close l_crsr;

         ut.expect(l_transaction_time).to_be_greater_or_equal(l_start_time);
         ut.expect(l_transaction_time).to_be_less_or_equal(l_end_time);
         ut.expect(l_units_out).to_equal(c_ts_unit);
         ut.expect(l_cwms_ts_id_out).to_equal(l_cwms_ts_id_in);
         ut.expect(l_time_zone_id_out).to_equal(l_time_zone_id_in);
         ut.expect(l_date_times.count).to_equal(c_value_count);
         ut.expect(l_values.count).to_equal(c_value_count);
         ut.expect(l_quality_codes.count).to_equal(c_value_count);
         for k in 1..c_value_count loop
            ut.expect(l_date_times(k)).to_equal(cwms_util.change_timezone(c_start_time + (k-1) / 24 + c_intvl_offsets(i) / 1440, l_time_zone_id_in, 'UTC'));
            ut.expect(l_values(k)).to_equal(k);
            ut.expect(l_quality_codes(k)).to_equal(0);
         end loop;
      end loop;
   end loop;
end zretrieve_ts_java;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_multi
--------------------------------------------------------------------------------
procedure retrieve_ts_multi
is
   l_crsr1                  sys_refcursor;
   l_crsr2                  sys_refcursor;
   l_time_zone              cwms_v_ts_id.cwms_ts_id%type := 'UTC';
   l_ts_request             timeseries_req_array := timeseries_req_array();
   l_cwms_ts_ids            str_tab_t := str_tab_t();
   l_timezone_ids           str_tab_t := str_tab_t();
   l_start_times            date_table_type := date_table_type();
   l_sequence_out           integer;
   l_cwms_ts_id_out         cwms_v_ts_id.cwms_ts_id%type;
   l_unit_out               cwms_v_ts_id.unit_id%type;
   l_location_time_zone_out cwms_v_ts_id.time_zone_id%type;
   l_start_time_out         date;
   l_end_time_out           date;
   l_time_zone_out          cwms_v_ts_id.time_zone_id%type;
   l_date_times             date_table_type;
   l_values                 double_tab_t;
   l_quality_codes          number_tab_t;
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_ids.extend;
         l_cwms_ts_ids(l_cwms_ts_ids.count) := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         l_timezone_ids.extend;
         l_timezone_ids(l_timezone_ids.count) := cwms_loc.get_local_timezone(c_location_ids(i), c_office_id);
         l_start_times.extend;
         l_start_times(l_start_times.count) := cwms_util.change_timezone(c_start_time + c_intvl_offsets(i) / 1440, cwms_loc.get_local_timezone(c_location_ids(i), c_office_id), l_time_zone);
         l_ts_request.extend;
         l_ts_request(l_ts_request.count) := timeseries_req_type(
            l_cwms_ts_ids(l_cwms_ts_ids.count),
            c_ts_unit,
            c_start_time - 1,
            c_start_Time + 2);
      end loop;
   end loop;
   cwms_ts.retrieve_ts_multi (
         p_at_tsv_rc       => l_crsr1,
         p_timeseries_info => l_ts_request,
         p_time_zone       => l_time_zone,
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       =>  c_office_id);

   loop
      fetch l_crsr1
       into l_sequence_out,
            l_cwms_ts_id_out,
            l_unit_out,
            l_start_time_out,
            l_end_time_out,
            l_time_zone_out,
            l_crsr2,
            l_location_time_zone_out;
      exit when l_crsr1%notfound;
      fetch l_crsr2
       bulk collect
       into l_date_times,
            l_values,
            l_quality_codes;
      close l_crsr2;
      ut.expect(l_cwms_ts_id_out).to_equal(l_cwms_ts_ids(l_sequence_out));
      ut.expect(l_unit_out).to_equal(c_ts_unit);
      ut.expect(l_location_time_zone_out).to_equal(l_timezone_ids(l_sequence_out));
      ut.expect(l_start_time_out).to_equal(l_start_times(l_sequence_out));
      ut.expect(l_date_times.count).to_equal(c_value_count);
      for i in 1..l_date_times.count loop
         ut.expect(l_date_times(i)).to_equal(l_start_time_out + (i - 1) / 24);
         ut.expect(l_values(i)).to_equal(i);
         ut.expect(l_quality_codes(i)).to_equal(0);
      end loop;
   end loop;
   close l_crsr1;
end retrieve_ts_multi;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_multi_single_value
--------------------------------------------------------------------------------
procedure retrieve_ts_multi_single_value
    is
    l_crsr1                  sys_refcursor;
    l_crsr2                  sys_refcursor;
    l_time_zone              cwms_v_ts_id.cwms_ts_id%type := 'UTC';
    l_ts_values  tsv_array := tsv_array();
    l_ts_request             timeseries_req_array := timeseries_req_array();
    l_cwms_ts_ids            str_tab_t := str_tab_t();
    l_timezone_ids           str_tab_t := str_tab_t();
    l_sequence_out           integer;
    l_cwms_ts_id_out         cwms_v_ts_id.cwms_ts_id%type;
    l_unit_out               cwms_v_ts_id.unit_id%type;
    l_location_time_zone_out cwms_v_ts_id.time_zone_id%type;
    l_start_time_out         date;
    l_end_time_out           date;
    l_time_zone_out          cwms_v_ts_id.time_zone_id%type;
    l_date_times             date_table_type;
    l_values                 double_tab_t;
    l_quality_codes          number_tab_t;
begin
    setup('INIT,STORE_LOCATIONS');
    l_ts_values.extend;
    l_ts_values(1) := tsv_type(
                date_time    => cast(c_ts_values_utc(2)(1).date_time as timestamp) at time zone 'US/Central',
                value        => c_ts_values_utc(2)(1).value,
                quality_code => c_ts_values_utc(2)(1).quality_code);
    l_cwms_ts_ids.extend;
    l_cwms_ts_ids(l_cwms_ts_ids.count) := replace(v_ts_ids(1), '<intvl>', '~1Hour');
    l_timezone_ids.extend;
    l_timezone_ids(l_timezone_ids.count) := cwms_loc.get_local_timezone(c_location_ids(1), c_office_id);

    cwms_ts.store_ts(
            p_office_id       => c_office_id,
            p_cwms_ts_id      => l_cwms_ts_ids(1),
            p_units           => c_ts_unit,
            p_timeseries_data => l_ts_values,
            p_store_rule      => cwms_util.replace_all,
            p_override_prot   => 0,
            p_versiondate     => cwms_util.non_versioned,
            p_create_as_lrts  => 'F'
        );

    l_ts_request.extend;
    l_ts_request(l_ts_request.count) := timeseries_req_type(
            l_cwms_ts_ids(l_cwms_ts_ids.count),
            c_ts_unit,
            c_start_time - 1,
            c_start_Time + 2);
    cwms_ts.retrieve_ts_multi (
            p_at_tsv_rc       => l_crsr1,
            p_timeseries_info => l_ts_request,
            p_time_zone       => l_time_zone,
            p_trim            => 'T',
            p_start_inclusive => 'T',
            p_end_inclusive   => 'T',
            p_previous        => 'F',
            p_next            => 'F',
            p_version_date    => cwms_util.non_versioned,
            p_max_version     => 'T',
            p_office_id       =>  c_office_id);

    loop
        fetch l_crsr1
            into l_sequence_out,
                 l_cwms_ts_id_out,
                 l_unit_out,
                 l_start_time_out,
                 l_end_time_out,
                 l_time_zone_out,
                 l_crsr2,
                 l_location_time_zone_out;
        exit when l_crsr1%notfound;
        fetch l_crsr2
            bulk collect
            into l_date_times,
            l_values,
            l_quality_codes;
        close l_crsr2;
        ut.expect(l_date_times.count).to_equal(1);
    end loop;
    close l_crsr1;
end retrieve_ts_multi_single_value;
--------------------------------------------------------------------------------
-- procedure store_ts
--------------------------------------------------------------------------------
procedure store_ts
is
   l_cwms_ts_id  cwms_v_ts_id.cwms_ts_id%type;
   l_ts_values   tsv_array := tsv_array();
   l_ts_values_2 tsv_array := tsv_array();
   l_ts_code     integer;
   l_count       integer;
   l_offset      integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_cwms_ts_id := replace(v_ts_ids(1), '<intvl>', '~1Hour');
   l_ts_values.extend(c_value_count);
   for i in 1..c_value_count loop
      l_ts_values(i) := tsv_type(
         date_time    => cast(trunc(c_ts_values_utc(2)(i).date_time, 'HH') as timestamp) at time zone 'US/Central',
         value        => c_ts_values_utc(2)(i).value,
         quality_code => c_ts_values_utc(2)(i).quality_code);
      if mod(i, 2) = 1 then
         l_ts_values(i).date_time := l_ts_values(i).date_time + to_dsinterval('0 0:10:0');
      end if;
   end loop;
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.delete_location(c_location_ids(1), cwms_util.delete_all, c_office_id);
   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);
   --------------------------------------------------------------------
   -- first store data as pseudo-regular by using previous signature --
   --------------------------------------------------------------------
   cwms_ts.store_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_ts_values.count);
    ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   --------------------------------------
   -- next store data as local-regular --
   --------------------------------------
   cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, c_office_id);
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.store_ts(
         p_cwms_ts_id      => l_cwms_ts_id,
         p_units           => c_ts_unit,
         p_timeseries_data => l_ts_values,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id,
         p_create_as_lrts  => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*Incoming data set contains multiple interval offsets.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   for i in 1..l_ts_values.count loop
      if mod(i, 2) = 1 then
         l_ts_values_2.extend;
         l_ts_values_2(l_ts_values_2.count) := l_ts_values(i);
      end if;
   end loop;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.store_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values_2,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_ts_values_2.count);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts;
--------------------------------------------------------------------------------
-- procedure store_ts_old
--------------------------------------------------------------------------------
procedure store_ts_old
is
   l_cwms_ts_id cwms_v_ts_id.cwms_ts_id%type;
   l_ts_values   tsv_array := tsv_array();
   l_ts_values_2 tsv_array := tsv_array();
   l_ts_code     integer;
   l_count       integer;
   l_offset      integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_cwms_ts_id := replace(v_ts_ids(1), '<intvl>', '~1Hour');
   l_ts_values.extend(c_value_count);
   for i in 1..c_value_count loop
      l_ts_values(i) := tsv_type(
         date_time    => cast(c_ts_values_utc(2)(i).date_time as timestamp) at time zone 'US/Central',
         value        => c_ts_values_utc(2)(i).value,
         quality_code => c_ts_values_utc(2)(i).quality_code);
      if mod(i, 2) = 0 then
         l_ts_values(i).date_time := l_ts_values(i).date_time + to_dsinterval('0 0:10:0');
      end if;
   end loop;
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.delete_location(c_location_ids(1), cwms_util.delete_all, c_office_id);
   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);
   --------------------------------------------------------------------
   -- first store data as pseudo-regular by using previous signature --
   --------------------------------------------------------------------
   cwms_ts.store_ts(
      p_office_id       => c_office_id,
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 0,
      p_versiondate     => cwms_util.non_versioned);

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_ts_values.count);
    ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   --------------------------------------
   -- next store data as local-regular --
   --------------------------------------
   cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, c_office_id);
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.store_ts(
         p_office_id       => c_office_id,
         p_cwms_ts_id      => l_cwms_ts_id,
         p_units           => c_ts_unit,
         p_timeseries_data => l_ts_values,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 0,
         p_versiondate     => cwms_util.non_versioned,
         p_create_as_lrts  => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*Incoming data set contains multiple interval offsets.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   for i in 1..l_ts_values.count loop
      if mod(i, 2) = 1 then
         l_ts_values_2.extend;
         l_ts_values_2(l_ts_values_2.count) := l_ts_values(i);
      end if;
   end loop;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.store_ts(
      p_office_id       => c_office_id,
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values_2,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 0,
      p_versiondate     => cwms_util.non_versioned,
      p_create_as_lrts  => 'T');

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_ts_values_2.count);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts_old;
--------------------------------------------------------------------------------
-- procedure store_ts_oracle
--------------------------------------------------------------------------------
procedure store_ts_oracle
is
   l_cwms_ts_id cwms_v_ts_id.cwms_ts_id%type;
   l_times       cwms_ts.number_array;
   l_values      cwms_ts.double_array;
   l_qualities   cwms_ts.number_array;
   l_times_2     cwms_ts.number_array;
   l_values_2    cwms_ts.double_array;
   l_qualities_2 cwms_ts.number_array;
   l_ts_code     integer;
   l_count       integer;
   l_offset      integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_cwms_ts_id := replace(v_ts_ids(1), '<intvl>', '~1Hour');
   for i in 1..c_value_count loop
      l_times(i) := cwms_util.to_millis(cast(c_ts_values_utc(2)(i).date_time as timestamp) at time zone 'US/Central');
      l_values(i) := c_ts_values_utc(2)(i).value;
      l_qualities(i) := c_ts_values_utc(2)(i).quality_code;
      if mod(i, 2) = 0 then
         l_times(i) := l_times(i) + 10 * 60 * 1000;
      end if;
   end loop;
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.delete_location(c_location_ids(1), cwms_util.delete_all, c_office_id);
   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);
   --------------------------------------------------------------------
   -- first store data as pseudo-regular by using previous signature --
   --------------------------------------------------------------------
   cwms_ts.store_ts (
      p_cwms_ts_id     => l_cwms_ts_id,
      p_units          => c_ts_unit,
      p_times          => l_times,
      p_values         => l_values,
      p_qualities      => l_qualities,
      p_store_rule     => cwms_util.replace_all,
      p_override_prot  => 'F',
      p_version_date   => cwms_util.non_versioned,
      p_office_id      => c_office_id);
   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_values.count);
    ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   --------------------------------------
   -- next store data as local-regular --
   --------------------------------------
   cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, c_office_id);
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.store_ts (
         p_cwms_ts_id     => l_cwms_ts_id,
         p_units          => c_ts_unit,
         p_times          => l_times,
         p_values         => l_values,
         p_qualities      => l_qualities,
         p_store_rule     => cwms_util.replace_all,
         p_override_prot  => 'F',
         p_version_date   => cwms_util.non_versioned,
         p_office_id      => c_office_id,
         p_create_as_lrts => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*Incoming data set contains multiple interval offsets.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   for i in 1..l_times.count loop
      if mod(i, 2) = 1 then
         l_times_2((i-1)/2+1)     := l_times(i);
         l_values_2((i-1)/2+1)    := l_values(i);
         l_qualities_2((i-1)/2+1) := l_qualities(i);
      end if;
   end loop;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.store_ts (
      p_cwms_ts_id     => l_cwms_ts_id,
      p_units          => c_ts_unit,
      p_times          => l_times_2,
      p_values         => l_values_2,
      p_qualities      => l_qualities_2,
      p_store_rule     => cwms_util.replace_all,
      p_override_prot  => 'F',
      p_version_date   => cwms_util.non_versioned,
      p_office_id      => c_office_id,
      p_create_as_lrts => 'T');

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_values_2.count);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts_oracle;
--------------------------------------------------------------------------------
-- procedure store_ts_jython
--------------------------------------------------------------------------------
procedure store_ts_jython
is
   l_cwms_ts_id cwms_v_ts_id.cwms_ts_id%type;
   l_times       number_tab_t := number_tab_t();
   l_values      number_tab_t := number_tab_t();
   l_qualities   number_tab_t := number_tab_t();
   l_times_2     number_tab_t := number_tab_t();
   l_values_2    number_tab_t := number_tab_t();
   l_qualities_2 number_tab_t := number_tab_t();
   l_ts_code     integer;
   l_count       integer;
   l_offset      integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_cwms_ts_id := replace(v_ts_ids(1), '<intvl>', '~1Hour');
   l_times.extend(c_value_count);
   l_values.extend(c_value_count);
   l_qualities.extend(c_value_count);
   for i in 1..c_value_count loop
      l_times(i) := cwms_util.to_millis(cast(c_ts_values_utc(2)(i).date_time as timestamp) at time zone 'US/Central');
      l_values(i) := c_ts_values_utc(2)(i).value;
      l_qualities(i) := c_ts_values_utc(2)(i).quality_code;
      if mod(i, 2) = 0 then
         l_times(i) := l_times(i) + 10 * 60 * 1000;
      end if;
   end loop;
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.delete_location(c_location_ids(1), cwms_util.delete_all, c_office_id);
   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);
   --------------------------------------------------------------------
   -- first store data as pseudo-regular by using previous signature --
   --------------------------------------------------------------------
   cwms_ts.store_ts (
      p_cwms_ts_id     => l_cwms_ts_id,
      p_units          => c_ts_unit,
      p_times          => l_times,
      p_values         => l_values,
      p_qualities      => l_qualities,
      p_store_rule     => cwms_util.replace_all,
      p_override_prot  => 'F',
      p_version_date   => cwms_util.non_versioned,
      p_office_id      => c_office_id);
   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_values.count);
    ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   --------------------------------------
   -- next store data as local-regular --
   --------------------------------------
   cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, c_office_id);
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.store_ts (
         p_cwms_ts_id     => l_cwms_ts_id,
         p_units          => c_ts_unit,
         p_times          => l_times,
         p_values         => l_values,
         p_qualities      => l_qualities,
         p_store_rule     => cwms_util.replace_all,
         p_override_prot  => 'F',
         p_version_date   => cwms_util.non_versioned,
         p_office_id      => c_office_id,
         p_create_as_lrts => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*Incoming data set contains multiple interval offsets.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   declare
      j pls_integer;
   begin
      for i in 1..l_times.count loop
         if mod(i, 2) = 1 then
            l_times_2.extend;
            l_values_2.extend;
            l_qualities_2.extend;
            j := l_times_2.count;
            l_times_2(j)     := l_times(i);
            l_values_2(j)    := l_values(i);
            l_qualities_2(j) := l_qualities(i);
         end if;
      end loop;
   end;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.store_ts (
      p_cwms_ts_id     => l_cwms_ts_id,
      p_units          => c_ts_unit,
      p_times          => l_times_2,
      p_values         => l_values_2,
      p_qualities      => l_qualities_2,
      p_store_rule     => cwms_util.replace_all,
      p_override_prot  => 'F',
      p_version_date   => cwms_util.non_versioned,
      p_office_id      => c_office_id,
      p_create_as_lrts => 'T');

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_values_2.count);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts_jython;
--------------------------------------------------------------------------------
-- procedure zstore_ts
--------------------------------------------------------------------------------
procedure zstore_ts
is
   l_cwms_ts_id cwms_v_ts_id.cwms_ts_id%type;
   l_ts_values   ztsv_array := ztsv_array();
   l_ts_values_2 ztsv_array := ztsv_array();
   l_ts_code     integer;
   l_count       integer;
   l_offset      integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_cwms_ts_id := replace(v_ts_ids(1), '<intvl>', '~1Hour');
   l_ts_values.extend(c_value_count);
   for i in 1..c_value_count loop
      l_ts_values(i) := ztsv_type(
         date_time    => cwms_util.change_timezone(c_ts_values_utc(2)(i).date_time, 'US/Central', 'UTC'),
         value        => c_ts_values_utc(2)(i).value,
         quality_code => c_ts_values_utc(2)(i).quality_code);
      if mod(i, 2) = 0 then
         l_ts_values(i).date_time := l_ts_values(i).date_time + to_dsinterval('0 0:10:0');
      end if;
   end loop;
   ------------------------
   -- store the location --
   ------------------------
   cwms_loc.delete_location(c_location_ids(1), cwms_util.delete_all, c_office_id);
   cwms_loc.store_location2(
      p_location_id				=> c_location_ids(1),
      p_location_type			=> null,
      p_elevation 				=> null,
      p_elev_unit_id 			=> null,
      p_vertical_datum			=> null,
      p_latitude					=> null,
      p_longitude 				=> null,
      p_horizontal_datum		=> null,
      p_public_name				=> null,
      p_long_name 				=> null,
      p_description				=> null,
      p_time_zone_id 			=> c_timezone_ids(1),
      p_county_name				=> null,
      p_state_initial			=> null,
      p_active 					=> null,
      p_location_kind_id		=> null,
      p_map_label 				=> null,
      p_published_latitude 	=> null,
      p_published_longitude	=> null,
      p_bounding_office_id 	=> null,
      p_nation_id 				=> null,
      p_nearest_city 			=> null,
      p_ignorenulls				=> 'T',
      p_db_office_id 			=> c_office_id);
   --------------------------------------------------------------------
   -- first store data as pseudo-regular by using previous signature --
   --------------------------------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_ts_values.count);
    ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   --------------------------------------
   -- next store data as local-regular --
   --------------------------------------
   cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, c_office_id);
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_cwms_ts_id,
         p_units           => c_ts_unit,
         p_timeseries_data => l_ts_values,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id,
         p_create_as_lrts  => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*Incoming data set contains multiple interval offsets.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   for i in 1..l_ts_values.count loop
      if mod(i, 2) = 1 then
         l_ts_values_2.extend;
         l_ts_values_2(l_ts_values_2.count) := l_ts_values(i);
      end if;
   end loop;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values_2,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');

   l_ts_code := cwms_ts.get_ts_code(l_cwms_ts_id, c_office_id);

   select count(*)
     into l_count
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_ts_unit;

   select interval_utc_offset
     into l_offset
     from at_cwms_ts_spec
    where ts_code = l_ts_code;

    ut.expect(l_count).to_equal(l_ts_values_2.count);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end zstore_ts;
--------------------------------------------------------------------------------
-- procedure store_ts_multi
--------------------------------------------------------------------------------
procedure store_ts_multi
is
   l_ts_array   timeseries_array := timeseries_array();
   l_ts_array_2 timeseries_array;
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_ts_array.extend(2);
   for i in 1..2 loop
      l_ts_array(i) := timeseries_type(
         tsid => replace(v_ts_ids(i), '<intvl>', '~1Hour'),
         unit => c_ts_unit,
         data => tsv_array());
      l_ts_array(i).data.extend(c_value_count);
      for j in 1..c_value_count loop
         l_ts_array(i).data(j) := tsv_type(
            date_time    => cast(c_ts_values_utc(2)(j).date_time as timestamp) at time zone 'US/Central',
            value        => c_ts_values_utc(2)(j).value,
            quality_code => c_ts_values_utc(2)(j).quality_code);
         if mod(j, 2) = 0 then
            l_ts_array(i).data(j).date_time := l_ts_array(i).data(j).date_time + to_dsinterval('0 0:10:0');
         end if;
      end loop;
   end loop;
   ------------------------------------------------------------------------------------
   -- first store each as as pseudo-regular by using previous common-value signature --
   ------------------------------------------------------------------------------------
   cwms_ts.store_ts_multi(
      p_timeseries_array => l_ts_array,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id);

   for i in 1..2 loop
      l_ts_code := cwms_ts.get_ts_code(l_ts_array(i).tsid, c_office_id);

      select count(*)
        into l_count
        from cwms_v_tsv_dqu
       where ts_code = l_ts_code
         and unit_id = c_ts_unit;

      select interval_utc_offset
        into l_offset
        from at_cwms_ts_spec
       where ts_code = l_ts_code;

       ut.expect(l_count).to_equal(l_ts_array(i).data.count);
       ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   end loop;
   ---------------------------------------------------------------------------
   -- next store each as data as local-regular using common-value signature --
   ---------------------------------------------------------------------------
   for i in 1..2 loop
      cwms_ts.delete_ts(l_ts_array(i).tsid, cwms_util.delete_all, c_office_id);
   end loop;
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.store_ts_multi(
         p_timeseries_array => l_ts_array,
         p_store_rule       => cwms_util.replace_all,
         p_override_prot    => 'F',
         p_version_date     => cwms_util.non_versioned,
         p_office_id        => c_office_id,
         p_create_as_lrts   => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*store_ts_multi processed \d+ ts_ids of which \d+ had STORE ERRORS.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   l_ts_array_2 := l_ts_array;
   for i in 1..2 loop
      l_ts_array_2(i).data := tsv_array();
      for j in 1..l_ts_array(i).data.count loop
         if mod(j, 2) = 1 then
            l_ts_array_2(i).data.extend;
            l_ts_array_2(i).data(l_ts_array_2(i).data.count) := l_ts_array(i).data(j);
         end if;
      end loop;
   end loop;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.store_ts_multi(
      p_timeseries_array => l_ts_array_2,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id,
      p_create_as_lrts   => 'T');

   for i in 1..2 loop
      l_ts_code := cwms_ts.get_ts_code(l_ts_array(i).tsid, c_office_id);

      select count(*)
        into l_count
        from cwms_v_tsv_dqu
       where ts_code = l_ts_code
         and unit_id = c_ts_unit;

      select interval_utc_offset
        into l_offset
        from at_cwms_ts_spec
       where ts_code = l_ts_code;

       ut.expect(l_count).to_equal(l_ts_array(i).data.count / 2);
       ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
   end loop;
   -------------------------------------------------------------------------------
   -- finally store one as PRTS and one as LRTS using separate-values signature --
   -------------------------------------------------------------------------------
   for i in 1..2 loop
      cwms_ts.delete_ts(l_ts_array(i).tsid, cwms_util.delete_all, c_office_id);
   end loop;
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.store_ts_multi(
         p_timeseries_array => l_ts_array,
         p_store_rule       => cwms_util.replace_all,
         p_override_prot    => 'F',
         p_version_dates    => date_table_type(cwms_util.non_versioned, cwms_util.non_versioned),
         p_office_id        => c_office_id,
         p_create_as_lrts   => str_tab_t('T', 'F'));
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*store_ts_multi processed \d+ ts_ids of which \d+ had STORE ERRORS.*',
            'm')
         then
            raise;
         end if;
   end;
   -- l_ts_array_2 is already filtered
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   for i in 1..2 loop
      cwms_ts.delete_ts(l_ts_array(i).tsid, cwms_util.delete_all, c_office_id);
   end loop;
   cwms_ts.store_ts_multi(
      p_timeseries_array => l_ts_array_2,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_dates    => date_table_type(cwms_util.non_versioned, cwms_util.non_versioned),
      p_office_id        => c_office_id,
      p_create_as_lrts   => str_tab_t('T', 'F'));

   for i in 1..2 loop
      l_ts_code := cwms_ts.get_ts_code(l_ts_array(i).tsid, c_office_id);

      select count(*)
        into l_count
        from cwms_v_tsv_dqu
       where ts_code = l_ts_code
         and unit_id = c_ts_unit;

      select interval_utc_offset
        into l_offset
        from at_cwms_ts_spec
       where ts_code = l_ts_code;

      ut.expect(l_count).to_equal(l_ts_array_2(i).data.count);
      if i = 1 then
         ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
      else
         ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
      end if;
   end loop;
end store_ts_multi;
--------------------------------------------------------------------------------
-- procedure zstore_ts_multi
--------------------------------------------------------------------------------
procedure zstore_ts_multi
is
   l_ts_array   ztimeseries_array := ztimeseries_array();
   l_ts_array_2 ztimeseries_array := ztimeseries_array();
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
begin
   setup('INIT,STORE_LOCATIONS');
   l_ts_array.extend(2);
   for i in 1..2 loop
      l_ts_array(i) := ztimeseries_type(
         tsid => replace(v_ts_ids(i), '<intvl>', '~1Hour'),
         unit => c_ts_unit,
         data => ztsv_array());
      l_ts_array(i).data.extend(c_value_count);
      for j in 1..c_value_count loop
         l_ts_array(i).data(j) := ztsv_type(
            date_time    => cwms_util.change_timezone(c_ts_values_utc(2)(j).date_time, 'UTC', 'US/Central'),
            value        => c_ts_values_utc(2)(j).value,
            quality_code => c_ts_values_utc(2)(j).quality_code);
         if mod(j, 2) = 0 then
            l_ts_array(i).data(j).date_time := l_ts_array(i).data(j).date_time + 10 / 1440;
         end if;
      end loop;
   end loop;
   ------------------------------------------------------------------------------------
   -- first store each as as pseudo-regular by using previous common-value signature --
   ------------------------------------------------------------------------------------
   cwms_ts.zstore_ts_multi(
      p_timeseries_array => l_ts_array,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id);

   for i in 1..2 loop
      l_ts_code := cwms_ts.get_ts_code(l_ts_array(i).tsid, c_office_id);

      select count(*)
        into l_count
        from cwms_v_tsv_dqu
       where ts_code = l_ts_code
         and unit_id = c_ts_unit;

      select interval_utc_offset
        into l_offset
        from at_cwms_ts_spec
       where ts_code = l_ts_code;

       ut.expect(l_count).to_equal(l_ts_array(i).data.count);
       ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
   end loop;
   ---------------------------------------------------------------------------
   -- next store each as data as local-regular using common-value signature --
   ---------------------------------------------------------------------------
   for i in 1..2 loop
      cwms_ts.delete_ts(l_ts_array(i).tsid, cwms_util.delete_all, c_office_id);
   end loop;
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.zstore_ts_multi(
         p_timeseries_array => l_ts_array,
         p_store_rule       => cwms_util.replace_all,
         p_override_prot    => 'F',
         p_version_date     => cwms_util.non_versioned,
         p_office_id        => c_office_id,
         p_create_as_lrts   => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*zstore_ts_multi processed \d+ ts_ids of which \d+ had STORE ERRORS.*',
            'm')
         then
            raise;
         end if;
   end;
   ----------------------------------
   -- filter down to single offset --
   ----------------------------------
   l_ts_array_2 := l_ts_array;
   for i in 1..2 loop
      l_ts_array_2(i).data := ztsv_array();
      for j in 1..l_ts_array(i).data.count loop
         if mod(j, 2) = 1 then
            l_ts_array_2(i).data.extend;
            l_ts_array_2(i).data(l_ts_array_2(i).data.count) := l_ts_array(i).data(j);
         end if;
      end loop;
   end loop;
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   cwms_ts.zstore_ts_multi(
      p_timeseries_array => l_ts_array_2,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id,
      p_create_as_lrts   => 'T');

   for i in 1..2 loop
      l_ts_code := cwms_ts.get_ts_code(l_ts_array(i).tsid, c_office_id);

      select count(*)
        into l_count
        from cwms_v_tsv_dqu
       where ts_code = l_ts_code
         and unit_id = c_ts_unit;

      select interval_utc_offset
        into l_offset
        from at_cwms_ts_spec
       where ts_code = l_ts_code;

       ut.expect(l_count).to_equal(l_ts_array(i).data.count / 2);
       ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
   end loop;
   -------------------------------------------------------------------------------
   -- finally store one as PRTS and one as LRTS using separate-values signature --
   -------------------------------------------------------------------------------
   for i in 1..2 loop
      cwms_ts.delete_ts(l_ts_array(i).tsid, cwms_util.delete_all, c_office_id);
   end loop;
   begin
      ----------------------------------------------
      -- should fail on multiple interval offsets --
      ----------------------------------------------
      cwms_ts.zstore_ts_multi(
         p_timeseries_array => l_ts_array,
         p_store_rule       => cwms_util.replace_all,
         p_override_prot    => 'F',
         p_version_dates    => date_table_type(cwms_util.non_versioned, cwms_util.non_versioned),
         p_office_id        => c_office_id,
         p_create_as_lrts   => str_tab_t('T', 'F'));
      cwms_err.raise('ERROR', 'Expected exception not raised.');
   exception
      when others then
         if not regexp_like(
            dbms_utility.format_error_stack,
            '.*zstore_ts_multi processed \d+ ts_ids of which \d+ had STORE ERRORS.*',
            'm')
         then
            raise;
         end if;
   end;
   -- l_ts_array_2 is already filtered
   -----------------------------------------
   -- storing these values should succeed --
   -----------------------------------------
   for i in 1..2 loop
      cwms_ts.delete_ts(l_ts_array(i).tsid, cwms_util.delete_all, c_office_id);
   end loop;
   cwms_ts.zstore_ts_multi(
      p_timeseries_array => l_ts_array_2,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_dates    => date_table_type(cwms_util.non_versioned, cwms_util.non_versioned),
      p_office_id        => c_office_id,
      p_create_as_lrts   => str_tab_t('T', 'F'));

   for i in 1..2 loop
      l_ts_code := cwms_ts.get_ts_code(l_ts_array(i).tsid, c_office_id);

      select count(*)
        into l_count
        from cwms_v_tsv_dqu
       where ts_code = l_ts_code
         and unit_id = c_ts_unit;

      select interval_utc_offset
        into l_offset
        from at_cwms_ts_spec
       where ts_code = l_ts_code;

      ut.expect(l_count).to_equal(l_ts_array_2(i).data.count);
      if i = 1 then
         ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
      else
         ut.expect(l_offset).to_equal(cwms_util.utc_offset_irregular);
      end if;
   end loop;
end zstore_ts_multi;
--------------------------------------------------------------------------------
-- procedure set_tsid_time_zone
--------------------------------------------------------------------------------
procedure set_tsid_time_zone
is
begin
   setup('INIT');
   execute immediate 'cwms_ts.set_tsid_time_zone('':1'', ''UTC'', ''&&office_id'')'
     using v_ts_ids(1);
end set_tsid_time_zone;
--------------------------------------------------------------------------------
-- procedure set_ts_time_zone
--------------------------------------------------------------------------------
procedure set_ts_time_zone
is
begin
   execute immediate 'cwms_ts.set_ts_time_zone(0, ''UTC'')';
end set_ts_time_zone;
--------------------------------------------------------------------------------
-- procedure create_ts_tz
--------------------------------------------------------------------------------
procedure create_ts_tz
is
begin
   setup('INIT');
   execute immediate 'cwms_ts.create_ts_tz('':1'', p_time_zone_name=>''UTC'', p_office_id=>''&&office_id'')'
     using v_ts_ids(1);
end create_ts_tz;
--------------------------------------------------------------------------------
-- procedure create_ts_code_tz
--------------------------------------------------------------------------------
procedure create_ts_code_tz
is
   l_ts_code at_cwms_ts_spec.ts_code%type;
begin
   setup('INIT');
   execute immediate 'cwms_ts.create_ts_tz(:1, '':2'', p_time_zone_name=>''UTC'', p_office_id=>''&&office_id'')'
     using l_ts_code, v_ts_ids(1);
end create_ts_code_tz;
--------------------------------------------------------------------------------
-- procedure get_tsid_time_zone
--------------------------------------------------------------------------------
procedure get_tsid_time_zone
is
   l_timezone cwms_time_zone.time_zone_name%type;
begin
   setup();
   l_timezone := cwms_ts.get_tsid_time_zone(replace(v_ts_ids(1), '<intvl>', c_intervals(1)), '&&office_id');
   ut.expect(l_timezone).to_equal(v_timezone_ids(1));
end get_tsid_time_zone;
--------------------------------------------------------------------------------
-- procedure get_ts_time_zone
--------------------------------------------------------------------------------
procedure get_ts_time_zone
is
   l_timezone cwms_time_zone.time_zone_name%type;
begin
   setup();
   l_timezone := cwms_ts.get_ts_time_zone(cwms_ts.get_ts_code(replace(v_ts_ids(1), '<intvl>', c_intervals(1)), '&&office_id'));
   ut.expect(l_timezone).to_equal(v_timezone_ids(1));
end get_ts_time_zone;
--------------------------------------------------------------------------------
-- procedure retrieve_lrts_untrimmed
--------------------------------------------------------------------------------
procedure retrieve_lrts_untrimmed
is
   type test_info_rec_t is record(
      interval_id     varchar2(16),
      start_times     cwms_t_date_table,
      interval_offset integer,
      value_count     integer);
   type test_info_tab_t is table of test_info_rec_t;
   l_test_info test_info_tab_t := test_info_tab_t(
      test_info_rec_t('~1Hour', cwms_t_date_table(timestamp '2021-03-14 00:00:00', timestamp '2021-11-14 00:00:00'),  15, 24),
      test_info_rec_t('~1Day',  cwms_t_date_table(timestamp '2021-03-01 00:00:00', timestamp '2021-11-01 00:00:00'), 420, 30));
   l_interval       number;
   l_cwms_ts_id     varchar2(183);
   l_local_time     date;
   l_utc_time       date;
   l_start_time     date;
   l_end_time       date;
   l_ts_values      cwms_t_ztsv_array;
   l_extra_count    integer := 5;
   l_crsr           sys_refcursor;
   l_times          cwms_t_date_table;
   l_values         cwms_t_double_tab;
   l_qualities      cwms_t_number_tab;
   l_expected_count integer;
   l_seasons        cwms_t_str_tab    := cwms_t_str_tab('Spring', 'Fall');
   l_start_times    cwms_t_date_table := cwms_t_date_table(
                                         timestamp '2021-03-14 00:00:00',  -- DST starts at 02:00 local
                                         timestamp '2021-11-14 00:00:00'); -- DST ends at 02:00 local
begin
   setup('INIT, STORE_LOCATIONS');
   for i in 1..l_test_info.count loop
      l_cwms_ts_id := replace(c_location_ids(1)||c_ts_id_part, '<intvl>', l_test_info(i).interval_id);
      select interval
        into l_interval
        from cwms_interval
       where interval_id = substr(l_test_info(i).interval_id, 2);
      for j in 1..l_test_info(i).start_times.count loop
         l_ts_values := cwms_t_ztsv_array();
         for k in 1..l_test_info(i).value_count loop
             l_ts_values.extend;
             l_local_time := l_test_info(i).start_times(j) + (k - 1) * l_interval / 1440 + l_test_info(i).interval_offset / 1440;
             l_utc_time := cwms_util.change_timezone(l_local_time, 'US/Central', 'UTC');
             l_ts_values(l_ts_values.count) := cwms_t_ztsv(l_utc_time, k, 0);
         end loop;
         select cast(multiset(select cwms_t_ztsv(date_time, value, quality_code)
                                from table(l_ts_values)
                               where date_time is not null
                             ) as cwms_t_ztsv_array
                    )
           into l_ts_values
           from dual;
         cwms_ts.create_ts(
            p_cwms_ts_id        => l_cwms_ts_id,
            p_utc_offset        => l_test_info(i).interval_offset,
            p_interval_forward  => null,
            p_interval_backward => null,
            p_versioned         => 'F',
            p_active_flag       => 'T',
            p_office_id         => c_office_id);

         cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_cwms_ts_id,
            p_units           => c_ts_unit,
            p_timeseries_data => l_ts_values,
            p_store_rule      => cwms_util.replace_all,
            p_office_id       => c_office_id);

         l_start_time := l_test_info(i).start_times(j) - l_extra_count * l_interval / 1440;
         l_end_time   := l_test_info(i).start_times(j) + (l_test_info(i).value_count + l_extra_count) * l_interval / 1440;

         cwms_ts.retrieve_ts(
            p_at_tsv_rc  => l_crsr,
            p_cwms_ts_id => l_cwms_ts_id,
            p_units      => c_ts_unit,
            p_start_time => l_start_time,
            p_end_time   => l_end_time,
            p_time_zone  => 'US/Central',
            p_trim       => 'F',
            p_office_id  => c_office_id);

         fetch l_crsr
          bulk collect
          into l_times,
               l_values,
               l_qualities;

         close l_crsr;

         if i = 1 and j = 1 then
            --------------------------------
            -- ~1Hour crossing Srping DST --
            --------------------------------
            l_expected_count := l_test_info(i).value_count + 2 * l_extra_count - 1;
            ut.expect(l_times.count).to_equal(l_expected_count);
            if l_times.count = l_expected_count then
               for k in 1..l_times.count loop
                  if k between l_extra_count + 1 and l_extra_count + l_test_info(i).value_count - 1 then
                     ut.expect(l_values(k)).to_equal(l_ts_values(k-l_extra_count).value);
                  else
                     ut.expect(l_values(k)).to_be_null;
                  end if;
               end loop;
            end if;
         else
            ----------------
            -- all others --
            ----------------
            l_expected_count := l_test_info(i).value_count + 2 * l_extra_count;
            ut.expect(l_times.count).to_equal(l_expected_count);
            if l_times.count = l_expected_count then
               for k in 1..l_times.count loop
                  if k between l_extra_count + 1 and l_extra_count + l_test_info(i).value_count then
                     ut.expect(l_values(k)).to_equal(l_ts_values(k-l_extra_count).value);
                  else
                     ut.expect(l_values(k)).to_be_null;
                  end if;
               end loop;
            end if;
         end if;

         cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, c_office_id);
      end loop;
   end loop;
end retrieve_lrts_untrimmed;
--------------------------------------------------------------------------------
-- test_get_lrts_time_utc
--------------------------------------------------------------------------------
procedure test_get_lrts_times_utc
is
   function d (p_str in varchar2) return date is begin return to_date(p_str, 'yyyy-mm-dd hh24:mi'); end;
   procedure test_returned_times(
      p_expected_times  in cwms_t_date_table,
      p_interval        in number,
      p_local_time_zone in varchar)
   is
      type utc_index_type is table of number_tab_t index by varchar2(19);
      c_date_fmt       constant varchar2(21) := 'yyyy-mm-dd hh24:mi:ss';
      l_expected_times cwms_t_date_table;
      l_returned_times cwms_t_date_table;
      l_expected_times_orig cwms_t_date_table;
      l_utc_indexes    utc_index_type;
      l_date_str       varchar2(19);
      l_utc_time       date;
      l_local_time     date;
      l_indexes        number_tab_t;
      l_dst_offset     number;
      l_fail           boolean := false;
   begin
      ------------------------
      -- get the dst offset --
      ------------------------
      select cwms_util.dsinterval_to_minutes(dst_offset) / 1440
        into l_dst_offset
        from cwms_time_zone
       where time_zone_name = cwms_util.get_time_zone_name(p_local_time_zone);
      ------------------------------------
      -- convert the local times to utc --
      ------------------------------------
      select cwms_util.change_timezone(column_value, p_local_time_zone, 'UTC')
        bulk collect
        into l_expected_times
        from table(p_expected_times);
      l_expected_times_orig := l_expected_times;
      ---------------------------------
      -- adjust duplicate utc values --
      ---------------------------------
      for i in 1..l_expected_times.count loop
         l_date_str := to_char(l_expected_times(i), c_date_fmt);
         if l_utc_indexes.exists(l_date_str) then
            l_utc_indexes(l_date_str).extend;
            l_utc_indexes(l_date_str)(l_utc_indexes(l_date_str).count) := i;
         else
            l_utc_indexes(l_date_str) := number_tab_t(i);
         end if;
      end loop;
      l_date_str := l_utc_indexes.first;
      loop
         exit when l_date_str is null;
         l_indexes := l_utc_indexes(l_date_str);
         if l_indexes.count = 2 then
            l_expected_times(l_indexes(1)) := l_expected_times(l_indexes(1)) - l_dst_offset;
         end if;
         l_date_str := l_utc_indexes.next(l_date_str);
      end loop;
      -----------------------------
      -- call get_lrts_times_utc --
      -----------------------------
      l_returned_times := cwms_ts.get_lrts_times_utc(
         p_start_time_utc  => l_expected_times(1),
         p_end_time_utc    => l_expected_times(l_expected_times.count),
         p_interval        => p_interval,
         p_local_time_zone => p_local_time_zone);
      ---------------------------------------------------------
      -- compare returned values against the expected values --
      ---------------------------------------------------------
      ut.expect(l_returned_times.count).to_equal(l_expected_times.count);
      if l_returned_times.count = l_expected_times.count then
         -- allow for either UTC time when converting from local to UTC is undetermined
         for i in 1..l_returned_times.count loop
            ut.expect(
               cwms_util.change_timezone(l_returned_times(i), 'UTC', p_local_time_zone)
            ).to_equal(
               cwms_util.change_timezone(l_expected_times(i), 'UTC', p_local_time_zone)
            );
         end loop;
      end if;
   end test_returned_times;
begin
   --------------------------------------------------------
   -- test crossing spring boundary with 0100 local time --
   --------------------------------------------------------
--   dbms_output.put_line(chr(10)||'test crossing spring boundary with 0100 local time'||chr(10));
   test_returned_times(cwms_t_date_table(d('2020-03-07 23:00'),d('2020-03-08 01:00'),d('2020-03-08 03:00')),  2/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 22:00'),d('2020-03-08 01:00'),d('2020-03-08 04:00')),  3/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 21:00'),d('2020-03-08 01:00'),d('2020-03-08 05:00')),  4/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 19:00'),d('2020-03-08 01:00'),d('2020-03-08 07:00')),  6/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 17:00'),d('2020-03-08 01:00'),d('2020-03-08 09:00')),  8/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 13:00'),d('2020-03-08 01:00'),d('2020-03-08 13:00')), 12/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 01:00'),d('2020-03-08 01:00'),d('2020-03-09 01:00')),     1, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-06 01:00'),d('2020-03-08 01:00'),d('2020-03-10 01:00')),     2, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-05 01:00'),d('2020-03-08 01:00'),d('2020-03-11 01:00')),     3, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-04 01:00'),d('2020-03-08 01:00'),d('2020-03-12 01:00')),     4, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-03 01:00'),d('2020-03-08 01:00'),d('2020-03-13 01:00')),     5, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-02 01:00'),d('2020-03-08 01:00'),d('2020-03-14 01:00')),     6, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-01 01:00'),d('2020-03-08 01:00'),d('2020-03-15 01:00')),     7, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-02-08 01:00'),d('2020-03-08 01:00'),d('2020-04-08 01:00')),    30, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2019-03-08 01:00'),d('2020-03-08 01:00'),d('2021-03-08 01:00')),   365, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2010-03-08 01:00'),d('2020-03-08 01:00'),d('2030-03-08 01:00')),  3650, 'US/Central');
   --------------------------------------------------------------------------------------------
   -- test crossing spring boundary with 0200 local time (invalid time yields NULL UTC time) --
   --------------------------------------------------------------------------------------------
--   dbms_output.put_line(chr(10)||'test crossing spring boundary with 0200 local time (invalid time yields NULL UTC time)'||chr(10));
   test_returned_times(
      cwms_t_date_table(
         d('2020-03-08 00:30'),
         d('2020-03-08 01:00'),
         d('2020-03-08 01:30'),
         d('2020-03-08 03:00'),
         d('2020-03-08 03:30'),
         d('2020-03-08 04:00')),
      30/1440,
      'US/Central');
   test_returned_times(
      cwms_t_date_table(
         d('2020-03-08 00:00'),
         d('2020-03-08 01:00'),
         d('2020-03-08 03:00'),
         d('2020-03-08 04:00')),
      1/24,
      'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-08 00:00'),d('2020-03-08 04:00')),  2/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 23:00'),d('2020-03-08 05:00')),  3/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 22:00'),d('2020-03-08 06:00')),  4/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 20:00'),d('2020-03-08 08:00')),  6/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 18:00'),d('2020-03-08 10:00')),  8/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 14:00'),d('2020-03-08 14:00')), 12/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 02:00'),d('2020-03-09 02:00')),     1, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-06 02:00'),d('2020-03-10 02:00')),     2, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-05 02:00'),d('2020-03-11 02:00')),     3, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-04 02:00'),d('2020-03-12 02:00')),     4, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-03 02:00'),d('2020-03-13 02:00')),     5, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-02 02:00'),d('2020-03-14 02:00')),     6, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-01 02:00'),d('2020-03-15 02:00')),     7, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-02-08 02:00'),d('2020-04-08 02:00')),    30, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2019-03-08 02:00'),d('2021-03-08 02:00')),   365, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2010-03-08 02:00'),d('2030-03-08 02:00')),  3650, 'US/Central');
   --------------------------------------------------------
   -- test crossing spring boundary with 0300 local time --
   --------------------------------------------------------
--   dbms_output.put_line(chr(10)||'test crossing spring boundary with 0300 local time'||chr(10));
   test_returned_times(cwms_t_date_table(d('2020-03-08 01:00'),d('2020-03-08 03:00'),d('2020-03-08 05:00')),  2/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-08 00:00'),d('2020-03-08 03:00'),d('2020-03-08 06:00')),  3/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 23:00'),d('2020-03-08 03:00'),d('2020-03-08 07:00')),  4/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 21:00'),d('2020-03-08 03:00'),d('2020-03-08 09:00')),  6/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 19:00'),d('2020-03-08 03:00'),d('2020-03-08 11:00')),  8/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 15:00'),d('2020-03-08 03:00'),d('2020-03-08 15:00')), 12/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-07 03:00'),d('2020-03-08 03:00'),d('2020-03-09 03:00')),     1, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-06 03:00'),d('2020-03-08 03:00'),d('2020-03-10 03:00')),     2, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-05 03:00'),d('2020-03-08 03:00'),d('2020-03-11 03:00')),     3, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-04 03:00'),d('2020-03-08 03:00'),d('2020-03-12 03:00')),     4, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-03 03:00'),d('2020-03-08 03:00'),d('2020-03-13 03:00')),     5, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-02 03:00'),d('2020-03-08 03:00'),d('2020-03-14 03:00')),     6, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-03-01 03:00'),d('2020-03-08 03:00'),d('2020-03-15 03:00')),     7, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-02-08 03:00'),d('2020-03-08 03:00'),d('2020-04-08 03:00')),    30, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2019-03-08 03:00'),d('2020-03-08 03:00'),d('2021-03-08 03:00')),   365, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2010-03-08 03:00'),d('2020-03-08 03:00'),d('2030-03-08 03:00')),  3650, 'US/Central');
   ------------------------------------------------------
   -- test crossing fall boundary with 0100 local time --
   ------------------------------------------------------
--   dbms_output.put_line(chr(10)||'test crossing fall boundary with 0100 local time'||chr(10));
   test_returned_times(
      cwms_t_date_table(
         d('2020-11-01 00:30'),
         d('2020-11-01 01:00'),
         d('2020-11-01 01:30'),
         d('2020-11-01 01:00'),
         d('2020-11-01 01:30'),
         d('2020-11-01 02:00')),
      30/1440,
      'US/Central');
   test_returned_times(
      cwms_t_date_table(
         d('2020-11-01 00:00'),
         d('2020-11-01 01:00'),
         d('2020-11-01 01:00'),
         d('2020-11-01 02:00')),
      1/24,
      'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 23:00'),d('2020-11-01 01:00'),d('2020-11-01 03:00')),  2/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 22:00'),d('2020-11-01 01:00'),d('2020-11-01 04:00')),  3/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 21:00'),d('2020-11-01 01:00'),d('2020-11-01 05:00')),  4/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 19:00'),d('2020-11-01 01:00'),d('2020-11-01 07:00')),  6/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 17:00'),d('2020-11-01 01:00'),d('2020-11-01 09:00')),  8/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 13:00'),d('2020-11-01 01:00'),d('2020-11-01 13:00')), 12/24, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-31 01:00'),d('2020-11-01 01:00'),d('2020-11-02 01:00')),     1, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-30 01:00'),d('2020-11-01 01:00'),d('2020-11-03 01:00')),     2, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-29 01:00'),d('2020-11-01 01:00'),d('2020-11-04 01:00')),     3, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-28 01:00'),d('2020-11-01 01:00'),d('2020-11-05 01:00')),     4, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-27 01:00'),d('2020-11-01 01:00'),d('2020-11-06 01:00')),     5, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-26 01:00'),d('2020-11-01 01:00'),d('2020-11-07 01:00')),     6, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-25 01:00'),d('2020-11-01 01:00'),d('2020-11-08 01:00')),     7, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2020-10-01 01:00'),d('2020-11-01 01:00'),d('2020-12-01 01:00')),    30, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2019-11-01 01:00'),d('2020-11-01 01:00'),d('2021-11-01 01:00')),   365, 'US/Central');
   test_returned_times(cwms_t_date_table(d('2010-11-01 01:00'),d('2020-11-01 01:00'),d('2030-11-01 01:00')),  3650, 'US/Central');
end test_get_lrts_times_utc;
--------------------------------------------------------------------------------
-- procedure test_cwdb_150
--------------------------------------------------------------------------------
procedure test_cwdb_150
is
-- QUALITY_CODE SCREENED_ID VALIDITY_ID  RANGE_ID CHANGED_ID REPL_CAUSE_ID REPL_METHOD_ID TEST_FAILED_ID PROTECTION_ID
-- ------------ ----------- ------------ -------- ---------- ------------- -------------- -------------- -------------
--            0 UNSCREENED  UNKNOWN      NO_RANGE ORIGINAL   NONE          NONE           NONE           UNPROTECTED
--            5 SCREENED    MISSING      NO_RANGE ORIGINAL   NONE          NONE           NONE           UNPROTECTED
--        65545 SCREENED    QUESTIONABLE NO_RANGE ORIGINAL   NONE          NONE           CONSTANT_VALUE UNPROTECTED
--  -2147483645 SCREENED    OKAY         NO_RANGE ORIGINAL   NONE          NONE           NONE           PROTECTED
--     33554435 SCREENED    OKAY         NO_RANGE ORIGINAL   NONE          NONE           DISTRIBUTION   UNPROTECTED
--     33554437 SCREENED    MISSING      NO_RANGE ORIGINAL   NONE          NONE           DISTRIBUTION   UNPROTECTED
l_cwms_ts_id     varchar2(191) := 'TestLoc1.Code.Inst.~1Hour.0.CWDB-150';
l_time_zone      varchar2(28)  := 'America/Los_Angeles';
l_time_zone_2    varchar2(28);
l_start_time     date := cwms_util.change_timezone(timestamp '2020-10-31 22:00:00', l_time_zone, 'UTC');
l_dump_values    boolean := false;
l_crsr           sys_refcursor;
l_date_times     cwms_t_date_table;
l_values         cwms_t_double_tab;
l_quality_codes  cwms_t_number_tab;
l_count          pls_integer;
l_initial_zts    cwms_t_ztsv_array := cwms_t_ztsv_array(
   cwms_t_ztsv(l_start_time + 0 / 24,   31,  33554435),
   cwms_t_ztsv(l_start_time + 1 / 24,   32,  65545),
   cwms_t_ztsv(l_start_time + 2 / 24,   33,  33554435),
   cwms_t_ztsv(l_start_time + 3 / 24,   34,  65545),
   cwms_t_ztsv(l_start_time + 4 / 24,   35,  33554435),
   cwms_t_ztsv(l_start_time + 5 / 24, null,  5),
   cwms_t_ztsv(l_start_time + 6 / 24,   37, -2147483645),
   cwms_t_ztsv(l_start_time + 7 / 24,   38,  65545),
   cwms_t_ztsv(l_start_time + 8 / 24, null,  5),
   cwms_t_ztsv(l_start_time + 9 / 24, null,  5));

l_subsequent_zts cwms_t_ztsv_array := cwms_t_ztsv_array(
   cwms_t_ztsv(l_start_time + 1 / 24,   20, -2147483645),
   cwms_t_ztsv(l_start_time + 2 / 24, null,  33554435),
   cwms_t_ztsv(l_start_time + 3 / 24,   22,  65545),
   cwms_t_ztsv(l_start_time + 4 / 24,   35,  65545),
   cwms_t_ztsv(l_start_time + 5 / 24, null,  33554437),
   cwms_t_ztsv(l_start_time + 6 / 24,   25,  65545),
   cwms_t_ztsv(l_start_time + 7 / 24, null,  5),
   cwms_t_ztsv(l_start_time + 8 / 24,   27,  65545),
   cwms_t_ztsv(l_start_time + 9 / 24,   28, -2147483645),
   cwms_t_ztsv(l_start_time +10 / 24, null,  33554435));

l_expected_zts   cwms_t_ztsv_array := cwms_t_ztsv_array(
   cwms_t_ztsv(l_start_time + 0 / 24,   31,  33554435),
   cwms_t_ztsv(l_start_time + 1 / 24,   32,  65545),
   cwms_t_ztsv(l_start_time + 2 / 24,   33,  33554435),
   cwms_t_ztsv(l_start_time + 3 / 24,   34,  65545),
   cwms_t_ztsv(l_start_time + 4 / 24,   35,  33554435),
   cwms_t_ztsv(l_start_time + 5 / 24, null,  33554437),
   cwms_t_ztsv(l_start_time + 6 / 24,   37, -2147483645),
   cwms_t_ztsv(l_start_time + 7 / 24,   38,  65545),
   cwms_t_ztsv(l_start_time + 8 / 24,   27,  65545),
   cwms_t_ztsv(l_start_time + 9 / 24,   28,  -2147483645),
   cwms_t_ztsv(l_start_time +10 / 24, null,  0));
begin
   teardown;
   commit;
   select count(*) into l_count from cwms_v_loc where location_id = cwms_util.split_text(l_cwms_ts_id, 1, '.') and unit_system = 'EN';
   ut.expect(l_count).to_equal(0);
   cwms_loc.store_location(
      p_location_id	=> cwms_util.split_text(l_cwms_ts_id, 1, '.'),
      p_time_zone_id => l_time_zone,
      p_db_office_id => c_office_id);

   ----------------------------
   -- store the initial data --
   ----------------------------
   if l_dump_values then
      dbms_output.put_line(chr(10)||'Storing values: ');
      for i in 1..l_initial_zts.count loop
         dbms_output.put_line(
            chr(9)||from_tz(cast(l_initial_zts(i).date_time as timestamp), 'UTC') at time zone l_time_zone
            ||chr(9)||to_number(l_initial_zts(i).value)
            ||chr(9)||l_initial_zts(i).quality_code);
      end loop;
   end if;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_initial_zts,
      p_store_rule      => cwms_util.delete_insert,
      p_override_prot   => 'T',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   ------------------------------------------
   -- retrieve the intial data time window --
   ------------------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_time_zone_id => l_time_zone_2,
      p_cwms_ts_id   => l_cwms_ts_id,
      p_units        => c_ts_unit,
      p_start_time   => l_initial_zts(1).date_time,
      p_end_time     => l_initial_zts(l_initial_zts.count).date_time,
      p_time_zone    => 'UTC',
      p_trim         => 'F',
      p_office_id    => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   if l_dump_values then
      dbms_output.put_line(chr(10)||'Retrieved values: ');
      for i in 1..l_date_times.count loop
         dbms_output.put_line(
            chr(9)||from_tz(cast(l_date_times(i) as timestamp), 'UTC') at time zone l_time_zone
            ||chr(9)||to_number(l_values(i))
            ||chr(9)||l_quality_codes(i));
      end loop;
   end if;
   -------------------------------------------------
   -- compare retrieved data against initial data --
   -------------------------------------------------
   ut.expect(l_time_zone_2).to_equal(l_time_zone);
   ut.expect(l_date_times.count).to_equal(l_initial_zts.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_initial_zts(i).date_time);
      if l_initial_zts(i).value is null then
         ut.expect(l_values(i)).to_be_null;
      else
         ut.expect(l_values(i)).to_equal(l_initial_zts(i).value);
      end if;
      ut.expect(l_quality_codes(i)).to_equal(l_initial_zts(i).quality_code);
   end loop;
   --------------------------------------
   -- store data over the initial data --
   --------------------------------------
   if l_dump_values then
      dbms_output.put_line(chr(10)||'Storing values: ');
      for i in 1..l_subsequent_zts.count loop
         dbms_output.put_line(
            chr(9)||cast(l_subsequent_zts(i).date_time as timestamp) at time zone l_time_zone
            ||chr(9)||to_number(l_subsequent_zts(i).value)
            ||chr(9)||l_subsequent_zts(i).quality_code);
      end loop;
   end if;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_subsequent_zts,
      p_store_rule      => cwms_util.replace_missing_values_only,
      p_override_prot   => 'T',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   ---------------------------------------------
   -- retrieve the resultant data time window --
   ---------------------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_cwms_ts_id   => l_cwms_ts_id,
      p_units        => c_ts_unit,
      p_start_time   => l_initial_zts(1).date_time,
      p_end_time     => l_subsequent_zts(l_subsequent_zts.count).date_time,
      p_time_zone    => 'UTC',
      p_trim         => 'F',
      p_office_id    => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   if l_dump_values then
      dbms_output.put_line(chr(10)||'Retrieved values: ');
      for i in 1..l_date_times.count loop
         dbms_output.put_line(
            chr(9)||from_tz(cast(l_date_times(i) as timestamp), 'UTC') at time zone l_time_zone
            ||chr(9)||to_number(l_values(i))
            ||chr(9)||l_quality_codes(i));
      end loop;
   end if;
   --------------------------------------------------
   -- compare resulting data with expected results --
   --------------------------------------------------
   ut.expect(l_date_times.count).to_equal(l_expected_zts.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_expected_zts(i).date_time);
      if l_expected_zts(i).value is null then
         ut.expect(l_values(i)).to_be_null;
      else
         ut.expect(l_values(i)).to_equal(l_expected_zts(i).value);
      end if;
      ut.expect(l_quality_codes(i)).to_equal(l_expected_zts(i).quality_code);
   end loop;
end test_cwdb_150;
--------------------------------------------------------------------------------
-- procedure test_cwdb_153
--------------------------------------------------------------------------------
procedure test_cwdb_153
is
   l_cwms_ts_id     varchar2(191) := 'TestLoc1.Code.Inst.~1Day.0.CWDB-153';
   l_local_tz       varchar2(28)  := 'US/Central';
   l_nonlocal_tz    varchar2(28)  := 'US/Pacific';
   l_start_time     date := date '2017-10-16';
   l_value_count    pls_integer := 25;
   l_crsr           sys_refcursor;
   l_dump_values    boolean := true;
   l_date_times     cwms_t_date_table;
   l_values         cwms_t_double_tab;
   l_quality_codes  cwms_t_number_tab;
   l_zts            cwms_t_ztsv_array := cwms_t_ztsv_array();
   l_utc_times      cwms_t_date_table := cwms_t_date_table();
   l_local_times    cwms_t_date_table := cwms_t_date_table();
   l_nonlocal_times cwms_t_date_table := cwms_t_date_table();
   l_ts             cwms_t_tsv_array;
   l_ts_req         cwms_t_timeseries_req_array;
begin
   begin
      cwms_loc.delete_location(
         p_location_id   => cwms_util.split_text(l_cwms_ts_id, 1, '.'),
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   exception
      when others then null;
   end;
   cwms_loc.store_location(
      p_location_id	=> cwms_util.split_text(l_cwms_ts_id, 1, '.'),
      p_time_zone_id => l_local_tz,
      p_db_office_id => c_office_id);
   ----------------------------
   -- create the time series --
   ----------------------------
   l_zts.extend(l_value_count);
   l_local_times.extend(l_value_count);
   l_utc_times.extend(l_value_count);
   l_nonlocal_times.extend(l_value_count);
   for i in 1..l_value_count loop
      l_local_times(i) := l_start_time + i - 1;
      l_utc_times(i) := cwms_util.change_timezone(l_local_times(i), l_local_tz, 'UTC');
      l_nonlocal_times(i) := cwms_util.change_timezone(l_local_times(i), l_local_tz, l_nonlocal_tz);
      l_zts(i) := cwms_t_ztsv(l_utc_times(i), i, 3);
      if l_dump_values then
         dbms_output.put_line(
            i
            ||chr(9)||l_zts(i).date_time
            ||chr(9)||l_zts(i).value
            ||chr(9)||l_zts(i).quality_code);
      end if;
   end loop;
   ---------------------------
   -- store the time series --
   ---------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_zts,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'T',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   ------------------------------
   -- retrieve the data in UTC --
   ------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc      => l_crsr,
      p_cwms_ts_id     => l_cwms_ts_id,
      p_units          => c_ts_unit,
      p_start_time     => l_zts(1).date_time - 1,
      p_end_time       => l_zts(l_zts.count).date_time + 1,
      p_time_zone      => 'UTC',
      p_trim           => 'T',
      p_office_id      => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   if l_dump_values then
      dbms_output.put_line(chr(10));
      for i in 1..l_date_times.count loop
         dbms_output.put_line(
            i
            ||chr(9)||l_date_times(i)
            ||chr(9)||to_number(l_values(i))
            ||chr(9)||l_quality_codes(i));
      end loop;
   end if;
   -----------------------------------
   -- compare with expected results --
   -----------------------------------
   ut.expect(l_date_times.count).to_equal(l_zts.count);
   if l_date_times.count = l_zts.count then
      for i in 1..l_date_times.count loop
         ut.expect(l_date_times(i)).to_equal(l_utc_times(i));
      end loop;
   end if;
   ----------------------------------------------
   -- retrieve the data in the local time zone --
   ----------------------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_cwms_ts_id   => l_cwms_ts_id,
      p_units        => c_ts_unit,
      p_start_time   => l_zts(1).date_time - 1,
      p_end_time     => l_zts(l_zts.count).date_time + 1,
      p_time_zone    => l_local_tz,
      p_trim         => 'T',
      p_office_id    => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   if l_dump_values then
      dbms_output.put_line(chr(10));
      for i in 1..l_date_times.count loop
         dbms_output.put_line(
            i
            ||chr(9)||l_date_times(i)
            ||chr(9)||to_number(l_values(i))
            ||chr(9)||l_quality_codes(i));
      end loop;
   end if;
   -----------------------------------
   -- compare with expected results --
   -----------------------------------
   ut.expect(l_date_times.count).to_equal(l_zts.count);
   if l_date_times.count = l_zts.count then
      for i in 1..l_date_times.count loop
         ut.expect(l_date_times(i)).to_equal(l_local_times(i));
      end loop;
   end if;
   ------------------------------------------------------
   -- retrieve the data in another non-local time zone --
   ------------------------------------------------------
   cwms_ts.retrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_cwms_ts_id   => l_cwms_ts_id,
      p_units        => c_ts_unit,
      p_start_time   => l_zts(1).date_time - 1,
      p_end_time     => l_zts(l_zts.count).date_time + 1,
      p_time_zone    => l_nonlocal_tz,
      p_trim         => 'T',
      p_office_id    => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   if l_dump_values then
      dbms_output.put_line(chr(10));
      for i in 1..l_date_times.count loop
         dbms_output.put_line(
            i
            ||chr(9)||l_date_times(i)
            ||chr(9)||to_number(l_values(i))
            ||chr(9)||l_quality_codes(i));
      end loop;
   end if;
   -----------------------------------
   -- compare with expected results --
   -----------------------------------
   ut.expect(l_date_times.count).to_equal(l_zts.count);
   if l_date_times.count = l_zts.count then
      for i in 1..l_date_times.count loop
         ut.expect(l_date_times(i)).to_equal(l_nonlocal_times(i));
      end loop;
   end if;
   ---------------------------------------------------------------------------
   -- specific test for RMA unit test failure
   ---------------------------------------------------------------------------
   l_local_tz    := 'America/Los_Angeles';
   l_start_time  := date '2005-01-01';
   l_value_count := 31;

   begin
      cwms_loc.delete_location(
         p_location_id   => cwms_util.split_text(l_cwms_ts_id, 1, '.'),
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   exception
      when others then null;
   end;
   cwms_loc.store_location(
      p_location_id	=> cwms_util.split_text(l_cwms_ts_id, 1, '.'),
      p_time_zone_id => l_local_tz,
      p_db_office_id => c_office_id);

   ----------------------------
   -- create the time series --
   ----------------------------
   l_ts := cwms_t_tsv_array();
   l_ts.extend(l_value_count);
   for i in 1..l_value_count loop
      l_ts(i) := cwms_t_tsv(
         from_tz(cast(l_start_time+i-1 as timestamp), l_local_tz),
         i,
         3);
   end loop;
   if l_dump_values then
      for i in 1..l_value_count loop
         dbms_output.put_line(i
         ||chr(9)||l_ts(i).date_time
         ||chr(9)||l_ts(i).value
         ||chr(9)||l_ts(i).quality_code);
      end loop;
   end if;
   --------------------
   -- store the data --
   --------------------
   cwms_ts.store_ts(
      p_cwms_ts_id       => l_cwms_ts_id,
      p_units            => c_ts_unit,
      p_timeseries_data  => l_ts,
      p_store_rule       => cwms_util.replace_all,
      p_override_prot    => 'F',
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id,
      p_create_as_lrts   => 'T');

   if l_dump_values then
      -----------------------------------
      -- select the data from the view --
      -----------------------------------
      dbms_output.put_line('Stored data');
      for rec in (select date_time,
                         value,
                         quality_code
                    from cwms_v_tsv_dqu
                   where cwms_ts_id = l_cwms_ts_id
                     and unit_id = c_ts_unit
                     and start_date = date '2005-01-01'
                   order by date_time
                 )
      loop
         dbms_output.put_line(rec.date_time||chr(9)||rec.value||chr(9)||rec.quality_code);
      end loop;
   end if;

   declare
      l_seq_out     integer;
      l_tsid_out    varchar2(191);
      l_unit_out    varchar2(16);
      l_start_out   date;
      l_end_out     date;
      l_data_tz_out varchar2(28);
      l_data_out    sys_refcursor;
      l_loc_tz_out  varchar2(28);
      ts1           timestamp;
      ts2           timestamp;
   begin
      ----------------------------------------------------
      -- retrieve the data with the correct time window --
      ----------------------------------------------------
      l_ts_req := cwms_t_timeseries_req_array();
      l_ts_req.extend;
      l_ts_req(1) := cwms_t_timeseries_req(
         l_cwms_ts_id,
         c_ts_unit,
         date '2005-01-01',
         date '2005-02-01');
      ts1 := systimestamp;
      cwms_ts.retrieve_ts_multi(
         p_at_tsv_rc       => l_crsr,
         p_timeseries_info => l_ts_req,
         p_time_zone       => null,
         p_trim            => 'F',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => null,
         p_max_version     => 'T',
         p_office_id       => null);
      ts2 := systimestamp;
      dbms_output.put_line((ts2-ts1));
      loop
         fetch l_crsr
          into l_seq_out,
               l_tsid_out,
               l_unit_out,
               l_start_out,
               l_end_out,
               l_data_tz_out,
               l_data_out,
               l_loc_tz_out;
         exit when l_crsr%notfound;
         fetch l_data_out
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes;
         close l_data_out;
         if l_dump_values then
            dbms_output.put_line(l_seq_out
               ||chr(9)||l_unit_out
               ||chr(9)||l_start_out
               ||chr(9)||l_end_out
               ||chr(9)||l_data_tz_out
               ||chr(9)||l_loc_tz_out);
            for i in 1..l_date_times.count loop
               dbms_output.put_line(null
                  ||chr(9)||i
                  ||chr(9)||l_date_times(i)
                  ||chr(9)||to_number(l_values(i))
                  ||chr(9)||l_quality_codes(i));
            end loop;
         end if;
         ut.expect(l_date_times.count).to_equal(l_ts.count);
         if l_date_times.count = l_ts.count then
            for i in 1..l_date_times.count loop
               ut.expect(l_date_times(i)).to_equal(cwms_util.change_timezone(cast(l_ts(i).date_time as date), l_local_tz, l_data_tz_out));
               ut.expect(l_values(i)).to_equal(l_ts(i).value);
               ut.expect(l_quality_codes(i)).to_equal(l_ts(i).quality_code);
            end loop;
         end if;
      end loop;
      close l_crsr;
      -----------------------------------------------
      -- retrieve the data with a too early window --
      -----------------------------------------------
      l_ts_req(1) := cwms_t_timeseries_req(
         l_cwms_ts_id,
         c_ts_unit,
         date '2004-10-01',
         date '2004-11-01');
      ts1 := systimestamp;
      cwms_ts.retrieve_ts_multi(
         p_at_tsv_rc       => l_crsr,
         p_timeseries_info => l_ts_req,
         p_time_zone       => null,
         p_trim            => 'F',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => null,
         p_max_version     => 'T',
         p_office_id       => null);
      ts2 := systimestamp;
      dbms_output.put_line((ts2-ts1));
      loop
         fetch l_crsr
          into l_seq_out,
               l_tsid_out,
               l_unit_out,
               l_start_out,
               l_end_out,
               l_data_tz_out,
               l_data_out,
               l_loc_tz_out;
         exit when l_crsr%notfound;
         fetch l_data_out
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes;
         close l_data_out;
         if l_dump_values then
            dbms_output.put_line(l_seq_out
               ||chr(9)||l_unit_out
               ||chr(9)||l_start_out
               ||chr(9)||l_end_out
               ||chr(9)||l_data_tz_out
               ||chr(9)||l_loc_tz_out);
         end if;
         ut.expect(l_date_times.count).to_equal(31);
         if l_date_times.count = 31 then
            for i in 1..31 loop
               ut.expect(l_values(i)).to_be_null;
            end loop;
         end if;
      end loop;
      close l_crsr;
      -----------------------------------------------
      -- retrieve the data with a too late window --
      -----------------------------------------------
      l_ts_req(1) := cwms_t_timeseries_req(
         l_cwms_ts_id,
         c_ts_unit,
         date '2005-03-01',
         date '2005-04-01');
      ts1 := systimestamp;
      cwms_ts.retrieve_ts_multi(
         p_at_tsv_rc       => l_crsr,
         p_timeseries_info => l_ts_req,
         p_time_zone       => null,
         p_trim            => 'F',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => null,
         p_max_version     => 'T',
         p_office_id       => null);
      ts2 := systimestamp;
      dbms_output.put_line((ts2-ts1));
      loop
         fetch l_crsr
          into l_seq_out,
               l_tsid_out,
               l_unit_out,
               l_start_out,
               l_end_out,
               l_data_tz_out,
               l_data_out,
               l_loc_tz_out;
         exit when l_crsr%notfound;
         fetch l_data_out
          bulk collect
          into l_date_times,
               l_values,
               l_quality_codes;
         close l_data_out;
         if l_dump_values then
            dbms_output.put_line(l_seq_out
               ||chr(9)||l_unit_out
               ||chr(9)||l_start_out
               ||chr(9)||l_end_out
               ||chr(9)||l_data_tz_out
               ||chr(9)||l_loc_tz_out);
         end if;
         ut.expect(l_date_times.count).to_equal(31);
         if l_date_times.count = 31 then
            for i in 1..31 loop
               ut.expect(l_values(i)).to_be_null;
            end loop;
         end if;
      end loop;
      close l_crsr;
   end;
end test_cwdb_153;
--------------------------------------------------------------------------------
-- procedure test_lrts_id_output_formatting
--------------------------------------------------------------------------------
procedure test_lrts_id_output_formatting
is
   location_id_not_found exception;
   pragma exception_init(location_id_not_found, -20025);
   l_now               date := trunc(sysdate, 'MI');
   l_location_id       cwms_v_loc.location_id%type := c_location_ids(1);
   l_lrts_ts_id_old    cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev-Lrts.Inst.~1Day.0.Test';
   l_lrts_ts_id_new    cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev-Lrts.Inst.1DayLocal.0.Test';
   l_prts_ts_id        cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev-Prts.Inst.~1Day.0.Test';
   l_ts_data           cwms_t_ztsv_array;
   l_count             binary_integer := 10;
   l_rec_count         binary_integer;
   l_crsr              sys_refcursor;
   l_ts_id_out         cwms_v_ts_id.cwms_ts_id%type;
   l_unit_out          cwms_v_ts_id.unit_id%type;
   l_time_zone_out     cwms_v_ts_id.time_zone_id%type;
   l_retrieve_time     date;
   l_ts_request        cwms_t_timeseries_req_array;
   l_seq               binary_integer;
   l_start_time        date;
   l_end_time          date;
   l_data_time_zone    cwms_v_ts_id.time_zone_id%type;
   l_data_crsr         sys_refcursor;
   l_office_id_out     cwms_v_ts_id.db_office_id%type;
   l_base_location     cwms_v_ts_id.base_location_id%type;
   l_intvl_offset      binary_integer;
   l_active_flag       varchar2(1);
   l_user_privs        number;
   l_cat_office_id     cwms_v_ts_id.db_office_id%type;
   l_category_id       cwms_v_ts_cat_grp.ts_category_id%type;
   l_ts_category_desc  cwms_v_ts_cat_grp.ts_category_desc%type;
   l_grp_office_id     cwms_v_ts_id.db_office_id%type;
   l_group_id          cwms_v_ts_cat_grp.ts_group_id%type;
   l_group_desc        cwms_v_ts_cat_grp.ts_group_desc%type;
   l_alias_id          cwms_v_ts_grp_assgn.alias_id%type;
   l_ref_ts_id         cwms_v_ts_grp_assgn.ref_ts_id%type;
   l_shared_alias_id   cwms_v_ts_cat_grp.shared_ts_alias_id%type;
   l_shared_ref_ts_id  cwms_v_ts_cat_grp.shared_ref_ts_id%type;
   l_attribute         cwms_v_ts_grp_assgn.attribute%type;
   l_code              integer;
   l_xchg_set_code     integer;
   l_dss_pathname      varchar2(391);
   l_dss_param_type    varchar2(8);
   l_dss_tz_usage      varchar2(8);
   l_ts_profile_data   varchar2(4000);
   l_forecast_date     date;
   l_issue_date        date;
   l_version_date      date;
   l_min_date          date;
   l_max_date          date;
   l_shef_decode_specs cwms_shef.cat_shef_decode_spec_tab_t;
   l_location_id_out   cwms_v_loc.location_id%type;
   l_key_parameter_id  cwms_v_ts_profile.key_parameter_id%type;
   l_description       cwms_v_ts_profile.description%type;
   l_data_dissem_recs  cwms_data_dissem.cat_ts_transfer_tab_t;
begin
   cwms_ts.set_use_new_lrts_format_on_output('F');
   cwms_ts.set_require_new_lrts_format_on_input('F');
   cwms_ts.set_allow_new_lrts_format_on_input('F');
   cwms_data_dissem.set_ts_filtering('F', 'F', c_office_id);
   ---------------------------------------
   -- create the ts and ts_profile data --
   --------------------------------------
   l_ts_data := cwms_t_ztsv_array();
   l_ts_data.extend(l_count);
   for i in 1..l_count loop
      l_ts_data(i) := cwms_t_ztsv(l_now-l_count+i, i, 0);
      l_ts_profile_data := l_ts_profile_data
         ||to_char(l_ts_data(i).date_time, 'yyyy-mm-dd hh24:mi:ss') -- field 1 (Date_Time)
         ||chr(9)||to_number(l_ts_data(i).value)                    -- field 2 (Depth)
         ||chr(9)||to_number(l_ts_data(i).value)                    -- field 3 (Temp)
         ||chr(10);
   end loop;
   l_start_time := l_ts_data(1).date_time;
   l_end_time   := l_ts_data(l_count).date_time;
   -------------------------------------------------
   -- delete the location and all ts if it exists --
   -------------------------------------------------
   begin
      cwms_loc.delete_location(l_location_id, cwms_util.delete_all, c_office_id);
      commit;
   exception
      when location_id_not_found then null;
   end;
   ----------------------
   -- store the location --
   ------------------------
   cwms_loc.store_location(
      p_location_id  => l_location_id,
      p_time_zone_id => c_timezone_ids(1),
      p_db_office_id => c_office_id);
   --------------------
   -- store the LRTS --
   --------------------
   -- Values
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_old,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   -- Standard Text
   cwms_text.store_ts_std_text(
      p_tsid        => l_lrts_ts_id_old,
      p_std_text_id => 'A',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_attribute   => 1,
      p_office_id   => c_office_id);
   -- Non-standard Text
   cwms_text.store_ts_text(
      p_tsid        => l_lrts_ts_id_old,
      p_text        => 'Some text',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_attribute   => 2,
      p_office_id   => c_office_id);
   --------------------
   -- store the PRTS --
   --------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_prts_ts_id,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'F');
   -- Standard Text
   cwms_text.store_ts_std_text(
      p_tsid        => l_prts_ts_id,
      p_std_text_id => 'A',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_attribute   => 3,
      p_office_id   => c_office_id);
   -- Non-standard Text
   cwms_text.store_ts_text(
      p_tsid        => l_prts_ts_id,
      p_text        => 'Some text',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_attribute   => 4,
      p_office_id   => c_office_id);
   commit;
   --------------------------------------------------------
   -- create location levels, indicators, and conditions --
   --------------------------------------------------------
   cwms_level.store_specified_level('Lrts', 'Dummy level', 'F', c_office_id);
   cwms_level.store_location_level3(
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_value       => null,
      p_level_units       => 'ft',
      p_tsid              => l_lrts_ts_id_old,
      p_office_id         => c_office_id);
   commit;
   cwms_level.store_loc_lvl_indicator(
      p_loc_lvl_indicator_id => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
      p_minimum_duration     => to_dsinterval('000 00:00:01'),
      p_maximum_age          => to_dsinterval('001 00:00:00'),
      p_office_id            => c_office_id);
   commit;
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id  => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
         p_level_indicator_value => i,
         p_expression            => 'V',
         p_comparison_operator_1 => 'LT',
         p_comparison_value_1    => 2*i,
         p_comparison_unit_id    => 'ft',
         p_office_id             => c_office_id);
   end loop;
   commit;
   cwms_level.store_specified_level('Prts', 'Dummy level', 'F', c_office_id);
   cwms_level.store_location_level3(
      p_location_level_id => l_location_id||'.Elev-Prts.Inst.0.Test',
      p_level_value       => null,
      p_level_units       => 'ft',
      p_tsid              => l_prts_ts_id,
      p_office_id         => c_office_id);
   commit;
   cwms_level.store_loc_lvl_indicator(
      p_loc_lvl_indicator_id => l_location_id||'.Elev-Prts.Inst.0.Test.VALUE',
      p_minimum_duration     => to_dsinterval('000 00:00:01'),
      p_maximum_age          => to_dsinterval('001 00:00:00'),
      p_office_id            => c_office_id);
   commit;
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id  => l_location_id||'.Elev-Prts.Inst.0.Test.VALUE',
         p_level_indicator_value => i,
         p_expression            => 'V',
         p_comparison_operator_1 => 'LT',
         p_comparison_value_1    => 2*i,
         p_comparison_unit_id    => 'ft',
         p_office_id             => c_office_id);
   end loop;
   commit;
   ---------------------------------------------
   -- create ts groups and assign time series --
   ---------------------------------------------
   cwms_ts.store_ts_category(
      p_ts_category_id => 'TestCategory1',
      p_db_office_id   => c_office_id);
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory1',
      p_ts_group_id      => 'TestGroup1',
      p_shared_ts_ref_id => l_lrts_ts_id_old,
      p_db_office_id     => c_office_id);
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory1',
      p_ts_group_id      => 'TestGroup2',
      p_shared_ts_ref_id => l_prts_ts_id,
      p_db_office_id     => c_office_id);
   cwms_ts.assign_ts_groups(
      p_ts_category_id => 'TestCategory1',
      p_ts_group_id    => 'TestGroup1',
      p_ts_alias_array => cwms_t_ts_alias_tab(
                             cwms_t_ts_alias(l_lrts_ts_id_old, 1, 'TestGroup1_TimeSeries1', l_lrts_ts_id_old),
                             cwms_t_ts_alias(l_prts_ts_id, 2, 'TestGroup1_TimeSeries2', l_prts_ts_id)),
      p_db_office_id   => c_office_id);
   cwms_ts.assign_ts_groups(
      p_ts_category_id => 'TestCategory1',
      p_ts_group_id    => 'TestGroup2',
      p_ts_alias_array => cwms_t_ts_alias_tab(
                             cwms_t_ts_alias(l_lrts_ts_id_old, 1, 'TestGroup2_TimeSeries1', l_lrts_ts_id_old),
                             cwms_t_ts_alias(l_prts_ts_id, 2, 'TestGroup2_TimeSeries2', l_prts_ts_id)),
      p_db_office_id   => c_office_id);
   ------------------------------
   -- create data exchange set --
   ------------------------------
   cwms_xchg.store_dss_datastore(
      p_datastore_code  => l_code,
      p_datastore_id    => 'Test',
      p_dss_filemgr_url => '//192.168.1.1:22101',
      p_dss_file_name   => '/var/tmp/test.dss',
      p_fail_if_exists  => 'F',
      p_office_id       => c_office_id);
   cwms_xchg.store_xchg_set(
      p_xchg_set_code  => l_xchg_set_code,
      p_xchg_set_id    => 'TestXchgSet',
      p_datastore_id   => 'Test',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   cwms_xchg.store_xchg_dss_ts_mapping(
      p_mapping_code      => l_code,
      p_xchg_set_code     => l_xchg_set_code,
      p_cwms_ts_code      => cwms_ts.get_ts_code(l_lrts_ts_id_old, c_office_id),
      p_a_pathname_part   => null,
      p_b_pathname_part   => 'TestLoc1',
      p_c_pathname_part   => 'Code',
      p_e_pathname_part   => '~1Day',
      p_f_pathname_part   => 'Lrts',
      p_parameter_type    => 'INST-VAL',
      p_units             => 'n/a',
      p_fail_if_exists    => 'F');
   cwms_xchg.store_xchg_dss_ts_mapping(
      p_mapping_code      => l_code,
      p_xchg_set_code     => l_xchg_set_code,
      p_cwms_ts_code      => cwms_ts.get_ts_code(l_prts_ts_id, c_office_id),
      p_a_pathname_part   => null,
      p_b_pathname_part   => 'TestLoc1',
      p_c_pathname_part   => 'Code',
      p_e_pathname_part   => '~1Day',
      p_f_pathname_part   => 'Prts',
      p_parameter_type    => 'INST-VAL',
      p_units             => 'n/a',
      p_fail_if_exists    => 'F');
   -----------------------
   -- create a forecast --
   -----------------------
   cwms_forecast.store_spec(
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_fail_if_exists => 'F',
      p_ignore_nulls   => 'F',
      p_source_agency  => 'USACE',
      p_source_office  => c_office_id,
      p_valid_lifetime => 24,
      p_office_id      => c_office_id);
   cwms_ts.create_ts(
      p_cwms_ts_id  => replace(l_lrts_ts_id_old, '.Test', '.Forecast'),
      p_utc_offset  => cwms_ts.get_utc_interval_offset(l_ts_data(1).date_time, 1440),
      p_active_flag => 'T',
      p_office_id   => c_office_id);
   cwms_forecast.store_forecast(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_forecast_time   => sysdate-1/2,
      p_issue_time      => sysdate-1/2,
      p_time_zone       => null,
      p_fail_if_exists  => 'F',
      p_text            => 'This is a test',
      p_time_series     => cwms_t_ztimeseries_array(
                              cwms_t_ztimeseries(replace(l_lrts_ts_id_old, '.Test', '.Forecast'), 'ft', l_ts_data),
                              cwms_t_ztimeseries(replace(l_prts_ts_id, '.Test', '.Forecast'), 'ft', l_ts_data)),
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id);
   commit;
   ------------------------
   -- create ts profiles --
   ------------------------
   l_code := cwms_util.create_parameter_code('Depth-Lrts', 'F', c_office_id);
   l_code := cwms_util.create_parameter_code('Temp-Lrts', 'F', c_office_id);
   l_code := cwms_util.create_parameter_code('Depth-Prts', 'F', c_office_id);
   l_code := cwms_util.create_parameter_code('Temp-Prts', 'F', c_office_id);
   dbms_output.put_line(l_ts_profile_data);
   cwms_ts_profile.store_ts_profile(
      p_location_id      => l_location_id,
      p_key_parameter_id => 'Depth-Lrts',
      p_profile_params   => 'Depth-Lrts,Temp-Lrts',
      p_description      => 'LRTS Profile',
      p_ref_ts_id        => l_lrts_ts_id_old,
      p_fail_if_exists   => 'F',
      p_office_id        => c_office_id);
   cwms_ts_profile.store_ts_profile_parser(
      p_location_id      => l_location_id,
      p_key_parameter_id => 'Depth-Lrts',
      p_record_delimiter => chr(10),
      p_field_delimiter  => chr(9),
      p_time_field       => 1,
      p_time_start_col   => null,
      p_time_end_col     => null,
      p_time_format      => 'yyyy-mm-dd hh24:mi:ss',
      p_time_zone        => 'UTC',
      p_parameter_info   => 'Depth-Lrts,ft,2'||chr(10)||'Temp-Lrts,F,3',
      p_fail_if_exists   => 'F',
      p_office_id        => c_office_id);
   cwms_ts_profile.store_ts_profile_instance(
      p_location_id      => l_location_id,
      p_key_parameter_id => 'Depth-Lrts',
      p_profile_data     => l_ts_profile_data,
      p_version_id       => 'Profile',
      p_store_rule       => cwms_util.replace_all,
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id);

   cwms_ts_profile.store_ts_profile(
      p_location_id      => l_location_id,
      p_key_parameter_id => 'Depth-Prts',
      p_profile_params   => 'Depth-Prts,Temp-Prts',
      p_description      => 'LRTS Profile',
      p_ref_ts_id        => l_prts_ts_id,
      p_fail_if_exists   => 'F',
      p_office_id        => c_office_id);
   cwms_ts_profile.store_ts_profile_parser(
      p_location_id      => l_location_id,
      p_key_parameter_id => 'Depth-Prts',
      p_record_delimiter => chr(10),
      p_field_delimiter  => chr(9),
      p_time_field       => 1,
      p_time_start_col   => null,
      p_time_end_col     => null,
      p_time_format      => 'yyyy-mm-dd hh24:mi:ss',
      p_time_zone        => 'UTC',
      p_parameter_info   => 'Depth-Prts,ft,2'||chr(10)||'Temp-Prts,F,3',
      p_fail_if_exists   => 'F',
      p_office_id        => c_office_id);
   cwms_ts_profile.store_ts_profile_instance(
      p_location_id      => l_location_id,
      p_key_parameter_id => 'Depth-Prts',
      p_profile_data     => l_ts_profile_data,
      p_version_id       => 'Profile',
      p_store_rule       => cwms_util.replace_all,
      p_version_date     => cwms_util.non_versioned,
      p_office_id        => c_office_id);
   --------------------------------
   -- create some screening info --
   --------------------------------
   cwms_vt.create_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_screening_id_desc   => 'Test Screening',
      p_parameter_id        => 'Elev',
      p_db_office_id        => c_office_id);
   cwms_vt.assign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_scr_assign_array    => cwms_t_screen_assign_array(
                                  cwms_t_screen_assign(l_lrts_ts_id_old, 'T', replace(l_lrts_ts_id_old, '.Test', '.Rev')),
                                  cwms_t_screen_assign(l_prts_ts_id, 'T', replace(l_prts_ts_id, '.Test', '.Rev'))),
      p_db_office_id        => c_office_id);
   commit;
   ----------------------------------
   -- create some data stream info --
   ----------------------------------
   cwms_shef.store_data_stream (
      p_data_stream_id  => 'Test_Data_Stream',
      p_db_office_id    => c_office_id);
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_lrts_ts_id_old,
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HP',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                  cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                  1440),
      p_db_office_id        => c_office_id);
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_prts_ts_id,
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HH',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_util.utc_offset_irregular,
      p_db_office_id        => c_office_id);
   commit;
   ------------------
   -- create a URL --
   ------------------
   cwms_loc.store_url(
      p_location_id    => l_location_id,
      p_url_id         => l_location_id||'_url',
      p_url_address    => 'https://dummy.com/this_is_a_url',
      p_fail_if_exists => 'F',
      p_ignore_nulls   => 'T',
      p_url_title      => 'URL for '||l_location_id,
      p_office_id      => c_office_id);
   for i in 1..2 loop
      ------------------------------------
      -- verify expected tsids in views --
      ------------------------------------
      dbms_output.put_line(chr(10)||'==> Setting session to use '||case when i = 1 then 'OLD' else 'NEW' end||' LRTS ID format');
      cwms_ts.set_use_new_lrts_format_on_output(substr('FT', i, 1));
      for rec in (select * from cwms_v_ts_id where cwms_ts_id like '%Elev-Prts.%.Test') loop
         dbms_output.put_line(rec.cwms_ts_id||chr(9)||rec.interval_utc_offset);
      end loop;
      if cwms_ts.format_lrts_output(l_prts_ts_id, c_office_id) != l_prts_ts_id then
         cwms_err.raise('ERROR', 'Formatting '||l_prts_ts_id||'. Expected '||l_prts_ts_id||' but got '||cwms_ts.format_lrts_output(l_prts_ts_id, c_office_id));
      end if;
      if i = 1 then
         if cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id) != l_lrts_ts_id_old then
            cwms_err.raise('ERROR', 'Formatting '||l_lrts_ts_id_old||'. Expected '||l_lrts_ts_id_old||' but got '||cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         end if;
      else
         if cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id) != l_lrts_ts_id_new then
            cwms_err.raise('ERROR', 'Formatting '||l_lrts_ts_id_old||'. Expected '||l_lrts_ts_id_new||' but got '||cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         end if;
      end if;

      dbms_output.put_line('==> Testing CWMS_V_TS_EXTENTS_UTC');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_extents_utc where location_id = l_location_id) loop
         l_rec_count := l_rec_count + 1;
         if rec.ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.ts_id like '%.Elev-Prts.%.Text' then
            ut.expect(rec.ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_EXTENTS_LOCAL');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_extents_local where location_id = l_location_id) loop
         l_rec_count := l_rec_count + 1;
         if rec.ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_ACTIVE_FLAG');
      l_rec_count := 0;
      for rec in (select * from cwms_v_active_flag where cwms_ts_id like l_location_id||'.%') loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_ID');
      l_rec_count := 0;
      for rec in (select cwms_ts_id, interval_id from cwms_v_ts_id where location_id = l_location_id) loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
            ut.expect(rec.interval_id).to_equal(cwms_ts.format_lrts_interval_output('~1Day'));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
            ut.expect(rec.interval_id).to_equal('~1Day');
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_ID2');
      l_rec_count := 0;
      for rec in (select cwms_ts_id, interval_id, version_id from cwms_v_ts_id2 where location_id = l_location_id and aliased_item is null) loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
            ut.expect(rec.interval_id).to_equal(cwms_ts.format_lrts_interval_output('~1Day'));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
            ut.expect(rec.interval_id).to_equal('~1Day');
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TSV_DQU');
      select distinct cwms_ts_id
        into l_ts_id_out
        from cwms_v_tsv_dqu
       where cwms_ts_id like l_location_id||'.Elev-Lrts.%.Test'
         and unit_id = 'ft'
         and aliased_item is null;
      if i = 1 then
         ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
      else
         ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
      end if;

      dbms_output.put_line('==> Testing CWMS_V_TSV_DQU_24H');
      select distinct cwms_ts_id
        into l_ts_id_out
        from cwms_v_tsv_dqu_24h
       where cwms_ts_id like l_location_id||'.Elev-Lrts.%.Test'
         and unit_id = 'ft'
         and aliased_item is null;
      if i = 1 then
         ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
      else
         ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
      end if;

      dbms_output.put_line('==> Testing CWMS_V_TSV_DQU_30D');
      select distinct cwms_ts_id
        into l_ts_id_out
        from cwms_v_tsv_dqu_30d
       where cwms_ts_id like l_location_id||'.Elev-Lrts.%.Test'
         and unit_id = 'ft'
         and aliased_item is null;
      if i = 1 then
         ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
      else
         ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
      end if;

      dbms_output.put_line('==> Testing CWMS_V_TS_TEXT');
      l_rec_count := 0;
      for rec in (select distinct
                         cwms_ts_id,
                         attribute,
                         to_char(text_value) as text
                    from cwms_v_ts_text
                   where location_id = l_location_id
                     and aliased_item is null
                   order by attribute
                 )
      loop
         l_rec_count := l_rec_count + 1;
         if rec.attribute < 3 then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         else
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_LOCATION_LEVEL');
      l_rec_count := 0;
      for rec in (select * from cwms_v_location_level where location_id = l_location_id) loop
         l_rec_count := l_rec_count + 1;
         if rec.specified_level_id = 'Lrts' then
            ut.expect(rec.tsid).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.specified_level_id = 'Prts' then
            ut.expect(rec.tsid).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_LOC_LVL_CUR_MAX_IND');
      l_rec_count := 0;
      for rec in (select * from cwms_v_loc_lvl_cur_max_ind) loop
         l_rec_count := l_rec_count + 1;
         if rec.level_indicator_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.level_indicator_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);


      dbms_output.put_line('==> Testing CWMS_V_LOC_LVL_TS_MAP');
      l_rec_count := 0;
      for rec in (select * from cwms_v_loc_lvl_ts_map) loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_ALIAS');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_alias where db_office_id = c_office_id and category_id = 'TestCategory1') loop
         l_rec_count := l_rec_count + 1;
         if substr(rec.alias_id, -11) = 'TimeSeries1' then
            ut.expect(rec.ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         else
            ut.expect(rec.ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_CAT_GRP');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_cat_grp where cat_db_office_id = c_office_id and ts_category_id = 'TestCategory1') loop
         l_rec_count := l_rec_count + 1;
         if rec.ts_group_id = 'TestGroup1' then
            ut.expect(rec.shared_ref_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         else
            ut.expect(rec.shared_ref_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_GRP_ASSGN');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_grp_assgn where db_office_id = c_office_id and category_id = 'TestCategory1') loop
         l_rec_count := l_rec_count + 1;
         if rec.attribute = 1 then
            ut.expect(rec.ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
            ut.expect(rec.ref_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         else
            ut.expect(rec.ts_id).to_equal(l_prts_ts_id);
            ut.expect(rec.ref_ts_id).to_equal(l_prts_ts_id);
         end if;
         if rec.group_id = 'TestGroup1' then
            ut.expect(rec.shared_ref_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         else
            ut.expect(rec.shared_ref_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_MSG_ARCHIVE');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_msg_archive  where cwms_ts_id like l_location_id||'.%') loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_FORECAST_EX');
      l_rec_count := 0;
      for rec in (select * from cwms_v_forecast_ex where location_id = l_location_id) loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Forecast' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(replace(l_lrts_ts_id_old, '.Test', '.Forecast'), c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Forecast' then
            ut.expect(rec.cwms_ts_id).to_equal(replace(l_prts_ts_id, '.Test', '.Forecast'));
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_TS_PROFILE');
      l_rec_count := 0;
      for rec in (select * from cwms_v_ts_profile where location_id = l_location_id) loop
         l_rec_count := l_rec_count + 1;
         if rec.key_parameter_id = 'Depth-Lrts' then
            ut.expect(rec.elev_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.key_parameter_id = 'Depth-Prts' then
            ut.expect(rec.elev_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_SCREENED_TS_IDS');
      l_rec_count := 0;
      for rec in (select * from cwms_v_screened_ts_ids where screening_id = 'Elev Range 1') loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_SCREENING_ASSIGNMENTS');
      l_rec_count := 0;
      for rec in (select * from cwms_v_screening_assignments where screening_id = 'Elev Range 1') loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_SHEF_DECODE_SPEC');
      l_rec_count := 0;
      for rec in (select * from cwms_v_shef_decode_spec where data_stream_id = 'Test_Data_Stream') loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);

      dbms_output.put_line('==> Testing CWMS_V_CURRENT_MAP_DATA');
      l_rec_count := 0;
      for rec in (select * from cwms_v_current_map_data where cwms_ts_id like l_location_id||'.%') loop
         l_rec_count := l_rec_count + 1;
         if rec.cwms_ts_id like '%.Elev-Lrts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
         elsif rec.cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(rec.cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;
      ut.expect(l_rec_count).to_be_greater_than(0);
      ---------------------------------------------------
      -- verify expected tsids in non-catalog routines --
      ---------------------------------------------------
      dbms_output.put_line('==> Testing RETRIEVE_TS_OUT');
      cwms_ts.retrieve_ts_out(
         p_at_tsv_rc      => l_crsr,
         p_cwms_ts_id_out => l_ts_id_out,
         p_units_out      => l_unit_out,
         p_time_zone_id   => l_time_zone_out,
         p_cwms_ts_id     => l_lrts_ts_id_old,
         p_units          => 'ft',
         p_start_time     => l_start_time,
         p_end_time       => l_end_time,
         p_office_id      => c_office_id);
      close l_crsr;
      ut.expect(l_ts_id_out).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
      ut.expect(l_unit_out).to_equal('ft');
      ut.expect(l_time_zone_out).to_equal(c_timezone_ids(1));

      cwms_ts.retrieve_ts_out(
         p_at_tsv_rc      => l_crsr,
         p_cwms_ts_id_out => l_ts_id_out,
         p_units_out      => l_unit_out,
         p_time_zone_id   => l_time_zone_out,
         p_cwms_ts_id     => l_prts_ts_id,
         p_units          => 'ft',
         p_start_time     => l_start_time,
         p_end_time       => l_end_time,
         p_office_id      => c_office_id);
      close l_crsr;
      ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
      ut.expect(l_unit_out).to_equal('ft');
      ut.expect(l_time_zone_out).to_equal(c_timezone_ids(1));

      dbms_output.put_line('==> Testing ZRETRIEVE_TS_JAVA');
      cwms_ts.zretrieve_ts_java(
         p_transaction_time => l_retrieve_time,
         p_at_tsv_rc        => l_crsr,
         p_units_out        => l_unit_out,
         p_cwms_ts_id_out   => l_ts_id_out,
         p_time_zone_id     => l_time_zone_out,
         p_units_in         => 'ft',
         p_cwms_ts_id_in    => l_lrts_ts_id_old,
         p_start_time       => l_start_time,
         p_end_time         => l_end_time,
         p_db_office_id     => c_office_id);
      close l_crsr;
      ut.expect(l_ts_id_out).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
      ut.expect(l_unit_out).to_equal('ft');
      ut.expect(l_time_zone_out).to_equal(c_timezone_ids(1));

      cwms_ts.zretrieve_ts_java(
         p_transaction_time => l_retrieve_time,
         p_at_tsv_rc        => l_crsr,
         p_units_out        => l_unit_out,
         p_cwms_ts_id_out   => l_ts_id_out,
         p_time_zone_id     => l_time_zone_out,
         p_units_in         => 'ft',
         p_cwms_ts_id_in    => l_prts_ts_id,
         p_start_time       => l_start_time,
         p_end_time         => l_end_time,
         p_db_office_id     => c_office_id);
      ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
      ut.expect(l_unit_out).to_equal('ft');
      ut.expect(l_time_zone_out).to_equal(c_timezone_ids(1));
      close l_crsr;

      dbms_output.put_line('==> Testing RETRIEVE_TS_MULTI');
      l_ts_request := cwms_t_timeseries_req_array(
         cwms_t_timeseries_req(l_lrts_ts_id_old, 'ft', l_start_time, l_end_time),
         cwms_t_timeseries_req(l_prts_ts_id, 'ft', l_start_time, l_end_time));
      cwms_ts.retrieve_ts_multi(
         p_at_tsv_rc       => l_crsr,
         p_timeseries_info => l_ts_request,
         p_office_id       => c_office_id);
      l_count := 1;
      loop
         fetch l_crsr
          into l_seq,
               l_ts_id_out,
               l_unit_out,
               l_start_time,
               l_end_time,
               l_data_time_zone,
               l_data_crsr,
               l_time_zone_out;
         exit when l_crsr%notfound;
         close l_data_crsr;
         if l_count = 1 then
            ut.expect(l_ts_id_out).to_equal(cwms_ts.format_lrts_output(l_lrts_ts_id_old, c_office_id));
            ut.expect(l_unit_out).to_equal('ft');
            ut.expect(l_time_zone_out).to_equal(c_timezone_ids(1));
         else
            ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            ut.expect(l_unit_out).to_equal('ft');
            ut.expect(l_time_zone_out).to_equal(c_timezone_ids(1));
         end if;
         l_count := l_count + 1;
      end loop;
      close l_crsr;

      declare
         l_level_value_out      number;
         l_level_comment_out    varchar2(256);
         l_effective_date_out   date;
         l_interval_origin_out  date;
         l_interval_months_out  integer;
         l_interval_minutes_out integer;
         l_interpolate_out      varchar2(1);
         l_tsid_out             varchar2(256);
         l_expiration_date_out  date;
         l_seasonal_values_out  seasonal_value_tab_t;
      begin
         dbms_output.put_line('==> Testing RETRIEVE_LOCATION_LEVEL3');
         cwms_level.retrieve_location_level3(
            p_level_value             => l_level_value_out,
            p_level_comment           => l_level_comment_out,
            p_effective_date          => l_effective_date_out,
            p_interval_origin         => l_interval_origin_out,
            p_interval_months         => l_interval_months_out,
            p_interval_minutes        => l_interval_minutes_out,
            p_interpolate             => l_interpolate_out,
            p_tsid                    => l_tsid_out,
            p_seasonal_values         => l_seasonal_values_out,
            p_location_level_id       => l_location_id||'.Elev-Lrts.Inst.0.Test',
            p_level_units             => 'ft',
            p_date                    => sysdate,
            p_timezone_id             => 'UTC',
            p_office_id               => c_office_id);
         if i = 1 then
            ut.expect(l_tsid_out).to_equal(l_lrts_ts_id_old);
         else
            ut.expect(l_tsid_out).to_equal(l_lrts_ts_id_new);
         end if;
         cwms_level.retrieve_location_level3(
            p_level_value             => l_level_value_out,
            p_level_comment           => l_level_comment_out,
            p_effective_date          => l_effective_date_out,
            p_interval_origin         => l_interval_origin_out,
            p_interval_months         => l_interval_months_out,
            p_interval_minutes        => l_interval_minutes_out,
            p_interpolate             => l_interpolate_out,
            p_tsid                    => l_tsid_out,
            p_seasonal_values         => l_seasonal_values_out,
            p_location_level_id       => l_location_id||'.Elev-Prts.Inst.0.Test',
            p_level_units             => 'ft',
            p_date                    => sysdate,
            p_timezone_id             => 'UTC',
            p_office_id               => c_office_id);
         dbms_output.put_line('==> Testing RETRIEVE_LOCATION_LEVEL4');
         ut.expect(l_tsid_out).to_equal(l_prts_ts_id);
         cwms_level.retrieve_location_level4(
            p_level_value             => l_level_value_out,
            p_level_comment           => l_level_comment_out,
            p_effective_date          => l_effective_date_out,
            p_interval_origin         => l_interval_origin_out,
            p_interval_months         => l_interval_months_out,
            p_interval_minutes        => l_interval_minutes_out,
            p_interpolate             => l_interpolate_out,
            p_tsid                    => l_tsid_out,
            p_expiration_date         => l_expiration_date_out,
            p_seasonal_values         => l_seasonal_values_out,
            p_location_level_id       => l_location_id||'.Elev-Lrts.Inst.0.Test',
            p_level_units             => 'ft',
            p_date                    => sysdate,
            p_timezone_id             => 'UTC',
            p_office_id               => c_office_id);
         if i = 1 then
            ut.expect(l_tsid_out).to_equal(l_lrts_ts_id_old);
         else
            ut.expect(l_tsid_out).to_equal(l_lrts_ts_id_new);
         end if;
         cwms_level.retrieve_location_level4(
            p_level_value             => l_level_value_out,
            p_level_comment           => l_level_comment_out,
            p_effective_date          => l_effective_date_out,
            p_interval_origin         => l_interval_origin_out,
            p_interval_months         => l_interval_months_out,
            p_interval_minutes        => l_interval_minutes_out,
            p_interpolate             => l_interpolate_out,
            p_tsid                    => l_tsid_out,
            p_expiration_date         => l_expiration_date_out,
            p_seasonal_values         => l_seasonal_values_out,
            p_location_level_id       => l_location_id||'.Elev-Prts.Inst.0.Test',
            p_level_units             => 'ft',
            p_date                    => sysdate,
            p_timezone_id             => 'UTC',
            p_office_id               => c_office_id);
         ut.expect(l_tsid_out).to_equal(l_prts_ts_id);
      end;
      -----------------------------------------------
      -- verify expected tsids in catalog routines --
      -----------------------------------------------
      dbms_output.put_line('==> Testing CAT_TS_ID');
      cwms_cat.cat_ts_id(
         p_cwms_cat            => l_crsr,
         p_ts_subselect_string => l_location_id||'.*.Test',
         p_db_office_id        => c_office_id);
      l_count := 1;
      loop
         fetch l_crsr
          into l_office_id_out,
               l_base_location,
               l_ts_id_out,
               l_intvl_offset,
               l_time_zone_out,
               l_active_flag,
               l_user_privs;
         exit when l_crsr%notfound;
         if i = 1 then
            case l_count
            when 1 then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
            when 2 then
               ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            else
               cwms_err.raise('ERROR', 'Too many rows!');
            end case;
         else
            case l_count
            when 1 then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
            when 2 then
               ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            else
               cwms_err.raise('ERROR', 'Too many rows!');
            end case;
         end if;
         l_count := l_count + 1;
      end loop;
      close l_crsr;

      dbms_output.put_line('==> Testing CAT_TS_ALIASES');
      cwms_cat.cat_ts_aliases(
         p_cwms_cat       => l_crsr,
         p_ts_category_id => 'Test*',
         p_db_office_id   => c_office_id);
      l_count := 1;
      loop
         fetch l_crsr
          into l_office_id_out,
               l_ts_id_out,
               l_cat_office_id,
               l_category_id,
               l_grp_office_id,
               l_group_id,
               l_group_desc,
               l_alias_id,
               l_ref_ts_id,
               l_shared_alias_id,
               l_shared_ref_ts_id,
               l_attribute;
         exit when l_crsr%notfound;
         if i = 1 then
            case l_group_id
            when 'TestGroup1' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_lrts_ts_id_old);
            when 'TestGroup2' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_prts_ts_id);
            end case;
            case l_attribute
            when 1 then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
            when 2 then
               ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            else
               cwms_err.raise('ERROR', 'Too many rows!');
            end case;
         else
            case l_group_id
            when 'TestGroup1' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_lrts_ts_id_new);
            when 'TestGroup2' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_prts_ts_id);
            else
               null;
            end case;
            case l_attribute
            when 1 then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
            when 2 then
               ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            else
               cwms_err.raise('ERROR', 'Too many rows!');
            end case;
         end if;
      end loop;
      close l_crsr;

      dbms_output.put_line('==> Testing CAT_TS_GROUP');
      cwms_cat.cat_ts_group(
         p_cwms_cat       => l_crsr,
         p_db_office_id   => c_office_id);
      l_count := 1;
      loop
         fetch l_crsr
          into l_cat_office_id,
               l_category_id,
               l_ts_category_desc,
               l_grp_office_id,
               l_group_id,
               l_group_desc,
               l_shared_alias_id,
               l_shared_ref_ts_id;
         exit when l_crsr%notfound;
         if i = 1 then
            case l_group_id
            when 'TestGroup1' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_lrts_ts_id_old);
            when 'TestGroup2' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_prts_ts_id);
            else
               null;
            end case;
         else
            case l_group_id
            when 'TestGroup1' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_lrts_ts_id_new);
            when 'TestGroup2' then
               ut.expect(l_shared_ref_ts_id).to_equal(l_prts_ts_id);
            else
               null;
            end case;
         end if;
      end loop;
      close l_crsr;

      dbms_output.put_line('==> Testing CAT_XCHG_TS_MAP');
      cwms_cat.cat_dss_xchg_ts_map(
         p_cwms_cat    => l_crsr,
         p_office_id   => c_office_id,
         p_xchg_set_id => '*');
      l_count := 1;
      loop
         fetch l_crsr
          into l_office_id_out,
               l_ts_id_out,
               l_dss_pathname,
               l_dss_param_type,
               l_unit_out,
               l_time_zone_out,
               l_dss_tz_usage;
         exit when l_crsr%notfound;
         if i = 1 then
            case l_dss_pathname
            when '//TestLoc1/Code//~1Day/Lrts/' then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
            when '//TestLoc1/Code//~1Day/Prts/' then
               ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            end case;
         else
            case l_dss_pathname
            when '//TestLoc1/Code//~1Day/Lrts/' then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
            when '//TestLoc1/Code//~1Day/Prts/' then
               ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
            end case;
         end if;
      end loop;
      close l_crsr;

      dbms_output.put_line('==> Testing CWMS_FORECAST.CAT_TS');
      l_crsr := cwms_forecast.cat_ts_f(
         p_location_id => l_location_id,
         p_forecast_id => 'TEST',
         p_office_id   => c_office_id);
      loop
         fetch l_crsr
          into l_office_id_out,
               l_forecast_date,
               l_issue_date,
               l_ts_id_out,
               l_version_date,
               l_min_date,
               l_max_date,
               l_time_zone_out;
         exit when l_crsr%notfound;
         if l_ts_id_out like '%.Elev-Lrts.%' then
            if i = 1 then
               ut.expect(l_ts_id_out).to_equal(replace(l_lrts_ts_id_old, '.Test', '.Forecast'));
            else
               ut.expect(l_ts_id_out).to_equal(replace(l_lrts_ts_id_new, '.Test', '.Forecast'));
            end if;
         else
            ut.expect(l_ts_id_out).to_equal(replace(l_prts_ts_id, '.Test', '.Forecast'));
         end if;
      end loop;
      close l_crsr;

      dbms_output.put_line('==> Testing CWMS_TS_PROFILE.CAT_TS_PROFILE');
      l_crsr := cwms_ts_profile.cat_ts_profile_f('*', '*', c_office_id);
      loop
         fetch l_crsr
          into l_office_id_out,
               l_location_id_out,
               l_key_parameter_id,
               l_data_crsr,
               l_ts_id_out,
               l_description;
         exit when l_crsr%notfound;
         close l_data_crsr;
         if l_key_parameter_id = 'Depth-Lrts' then
            if i = 1 then
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_old);
            else
               ut.expect(l_ts_id_out).to_equal(l_lrts_ts_id_new);
            end if;
         else
            ut.expect(l_ts_id_out).to_equal(l_prts_ts_id);
         end if;
      end loop;
      close l_crsr;

      dbms_output.put_line('==> Testing CWMS_SHEF.CAT_SHEF_DECODE_SPEC_TAB');
      cwms_shef.cat_shef_decode_spec (
         p_shef_decode_spec_rc => l_crsr,
         p_data_stream_id      => 'Test_Data_Stream',
         p_db_office_id        => c_office_id);
      fetch l_crsr bulk collect into l_shef_decode_specs;
      close l_crsr;
      for j in 1..l_shef_decode_specs.count loop
         if l_shef_decode_specs(j).cwms_ts_id like '%.Elev-Lrts.%' then
            if i = 1 then
               ut.expect(l_shef_decode_specs(j).cwms_ts_id).to_equal(l_lrts_ts_id_old);
               ut.expect(cwms_util.split_text(cwms_util.split_text(l_shef_decode_specs(j).shef_crit_line, 1, ';'), 2, '=')).to_equal(l_lrts_ts_id_old);
            else
               ut.expect(l_shef_decode_specs(j).cwms_ts_id).to_equal(l_lrts_ts_id_new);
               ut.expect(cwms_util.split_text(cwms_util.split_text(l_shef_decode_specs(j).shef_crit_line, 1, ';'), 2, '=')).to_equal(l_lrts_ts_id_new);
            end if;
         else
            ut.expect(l_shef_decode_specs(j).cwms_ts_id).to_equal(l_prts_ts_id);
            ut.expect(cwms_util.split_text(cwms_util.split_text(l_shef_decode_specs(j).shef_crit_line, 1, ';'), 2, '=')).to_equal(l_prts_ts_id);
         end if;
      end loop;

      dbms_output.put_line('==> Testing CWMS_DATA_DISSEM.CAT_TS_TRANSFER');
      cwms_data_dissem.cat_ts_transfer(l_crsr, c_office_id);
      fetch l_crsr bulk collect into l_data_dissem_recs;
      for j in 1..l_data_dissem_recs.count loop
         if l_data_dissem_recs(j).cwms_ts_id like '%.Elev-Lrts.%.Test' then
            if i = 1 then
               ut.expect(l_data_dissem_recs(j).cwms_ts_id).to_equal(l_lrts_ts_id_old);
            else
               ut.expect(l_data_dissem_recs(j).cwms_ts_id).to_equal(l_lrts_ts_id_new);
            end if;
         elsif l_data_dissem_recs(j).cwms_ts_id like '%.Elev-Prts.%.Test' then
            ut.expect(l_data_dissem_recs(j).cwms_ts_id).to_equal(l_prts_ts_id);
         end if;
      end loop;

   end loop;
   cwms_vt.delete_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_parameter_id        => 'Elev',
      p_parameter_type_id   => null,
      p_duration_id         => null,
      p_cascade             => 'T',
      p_db_office_id        => 'SWT');
   cwms_shef.delete_data_stream (
      p_data_stream_id  => 'Test_Data_Stream',
      p_cascade_all     => 'T',
      p_db_office_id    => c_office_id);
   cwms_level.delete_specified_level('Lrts', 'F', c_office_id);
   cwms_loc.delete_location(l_location_id, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts_category('TestCategory1', 'T', c_office_id);
   cwms_ts.set_use_new_lrts_format_on_output('F');
end test_lrts_id_output_formatting;
--------------------------------------------------------------------------------
-- procedure test_lrts_id_input_formatting
--------------------------------------------------------------------------------
procedure test_lrts_id_input_formatting
is
   l_location_id         cwms_v_loc.location_id%type := c_location_ids(1);
   l_location_id_copy    cwms_v_loc.location_id%type := c_location_ids(1)||'-Copy';
   l_lrts_ts_id_old      cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev-Lrts.Inst.~1Day.0.Test';
   l_lrts_ts_id_new      cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev-Lrts.Inst.1DayLocal.0.Test';
   l_lrts_ts_id_old_copy cwms_v_ts_id.cwms_ts_id%type := l_location_id||'-Copy.Elev-Lrts.Inst.~1Day.0.Test';
   l_lrts_ts_id_new_copy cwms_v_ts_id.cwms_ts_id%type := l_location_id||'-Copy.Elev-Lrts.Inst.1DayLocal.0.Test';
   l_prts_ts_id          cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev-Prts.Inst.~1Day.0.Test';
   l_rating_spec         cwms_v_rating_spec.rating_id%type := l_location_id||'.Elev;Stor.Linear.Production';
   l_count               binary_integer := 10;
   l_ts_data             cwms_t_ztsv_array;
   l_ts_data2            cwms_t_ztsv_array;
   l_start_time          date;
   l_end_time            date;
   l_crsr                sys_refcursor;
   l_date_times          cwms_t_date_table;
   l_values              cwms_t_double_tab;
   l_quality_codes       cwms_t_number_tab;
   l_min_value           binary_double;
   l_max_value           binary_double;
   l_ts_data_out         cwms_t_ztsv_array;
   l_ts_data_out2        cwms_t_ztsv_array;
   l_base_location_id    cwms_v_ts_id.base_location_id%type;
   l_sub_location_id     cwms_v_ts_id.sub_location_id%type;
   l_base_parameter_id   cwms_v_ts_id.base_parameter_id%type;
   l_sub_parameter_id    cwms_v_ts_id.sub_parameter_id%type;
   l_parameter_type_id   cwms_v_ts_id.parameter_type_id%type;
   l_interval_id         cwms_v_ts_id.interval_id%type;
   l_duration_id         cwms_v_ts_id.duration_id%type;
   l_version_id          cwms_v_ts_id.version_id%type;
   l_date_time           date;
   l_version_date        date;
   l_data_entry_date     date;
   l_text                varchar2(32767);
   l_clob                clob;
   l_number              number;
   l_blob                blob;
   l_media_type          varchar2(84);
   l_file_extension      varchar2(16);
   l_shef_id             varchar2(8);
   l_shef_pe_code        varchar2(2);
   l_shef_tse_code       varchar2(3);
   l_shef_duration_code  varchar2(4);
   l_units               varchar2(32);
   l_unit_sys            varchar2(32);
   l_tz                  varchar2(32);
   l_dltime              varchar2(32);
   l_int_offset          varchar2(32);
   l_int_backward        varchar2(32);
   l_int_forward         varchar2(32);
   l_cwms_ts_id          varchar2(191);
   l_location_obj        cwms_t_location_obj;
   l_project_obj         cwms_t_project_obj;
   l_rating              clob := '
<ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
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
    <location-id>'||l_location_id||'</location-id>
    <version>Production</version>
    <source-agency/>
    <in-range-method>PREVIOUS</in-range-method>
    <out-range-low-method>ERROR</out-range-low-method>
    <out-range-high-method>PREVIOUS</out-range-high-method>
    <active>true</active>
    <auto-update>false</auto-update>
    <auto-activate>false</auto-activate>
    <auto-migrate-extension>false</auto-migrate-extension>
    <ind-rounding-specs>
      <ind-rounding-spec position="1">2222233332</ind-rounding-spec>
    </ind-rounding-specs>
    <dep-rounding-spec>2222233332</dep-rounding-spec>
    <description/>
  </rating-spec>
  <simple-rating office-id="'||c_office_id||'">
    <rating-spec-id>'||l_rating_spec||'</rating-spec-id>
    <units-id vertical-datum="">ft;ac-ft</units-id>
    <effective-date>1900-01-01T00:00:00Z</effective-date>
    <active>true</active>
    <description/>
    <rating-points>
      <point><ind>0</ind><dep>0</dep></point>
      <point><ind>50</ind><dep>500</dep></point>
    </rating-points>
  </simple-rating>
</ratings>
';

begin
   cwms_loc.clear_all_caches;
   cwms_ts.clear_all_caches;
   cwms_ts.set_allow_new_lrts_format_on_input('F');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ------------------------
   -- create the ts data --
   ------------------------
   l_ts_data := cwms_t_ztsv_array();
   l_ts_data.extend(l_count);
   l_ts_data2 := cwms_t_ztsv_array();
   l_ts_data2.extend(l_count);
   for i in 1..l_count loop
      l_ts_data(i) := cwms_t_ztsv(date '2023-01-01' + (i-1), i, 0);
      l_ts_data2(i) := cwms_t_ztsv(date '2023-01-01' + (i-1), i * 10, 0);
   end loop;
   l_start_time := l_ts_data(1).date_time;
   l_end_time   := l_ts_data(l_count).date_time;
   --------------------------
   -- delete the locations --
   --------------------------
   begin
      cwms_loc.delete_location(l_location_id, cwms_util.delete_all, c_office_id);
   exception
      when others then null;
   end;
   begin
      cwms_loc.delete_location(l_location_id_copy, cwms_util.delete_all, c_office_id);
   exception
      when others then null;
   end;
   -------------------------
   -- store the locations --
   -------------------------
   cwms_loc.store_location(
      p_location_id  => l_location_id,
      p_time_zone_id => c_timezone_ids(1),
      p_db_office_id => c_office_id);
   cwms_loc.store_location(
      p_location_id  => l_location_id_copy,
      p_time_zone_id => c_timezone_ids(1),
      p_db_office_id => c_office_id);
   ----------------------------
   -- create specified level --
   ----------------------------
   cwms_level.store_specified_level('Lrts', 'Dummy level', 'F', c_office_id);
   ---------------------------------
   -- create the ts group catgory --
   ---------------------------------
   cwms_ts.store_ts_category(
      p_ts_category_id => 'TestCategory',
      p_db_office_id   => c_office_id);
   -----------------------
   -- create a forecast --
   -----------------------
   cwms_forecast.store_spec(
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_fail_if_exists => 'F',
      p_ignore_nulls   => 'F',
      p_source_agency  => 'USACE',
      p_source_office  => c_office_id,
      p_valid_lifetime => 24,
      p_office_id      => c_office_id);
   cwms_ts.create_ts(
      p_cwms_ts_id  => replace(l_lrts_ts_id_old, '.Test', '.Forecast'),
      p_utc_offset  => cwms_ts.get_utc_interval_offset(l_ts_data(1).date_time, 1440),
      p_active_flag => 'T',
      p_office_id   => c_office_id);
   cwms_forecast.store_forecast(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_forecast_time   => l_end_time,
      p_issue_time      => l_start_time,
      p_time_zone       => null,
      p_fail_if_exists  => 'F',
      p_text            => 'This is a test',
      p_time_series     => cwms_t_ztimeseries_array(
                              cwms_t_ztimeseries(replace(l_lrts_ts_id_old, '.Test', '.Forecast'), 'ft', l_ts_data)),
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id);
   ---------------------------
   -- create a screening id --
   ---------------------------
   cwms_vt.create_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_screening_id_desc   => 'Test Screening',
      p_parameter_id        => 'Elev',
      p_db_office_id        => c_office_id);
   ----------------------------------
   -- create some data stream info --
   ----------------------------------
   cwms_shef.store_data_stream (
      p_data_stream_id  => 'Test_Data_Stream',
      p_db_office_id    => c_office_id);
   -------------------------------------------------
   -- create a rating, location levels and a pool --
   -------------------------------------------------
   cwms_rating.store_ratings_xml(l_clob, l_rating, 'F', 'T');
   ut.expect(l_clob).to_be_null;
   cwms_level.store_location_level(
      p_location_level_id => l_location_id||'.Elev.Inst.0.Bottom of Normal',
      p_level_value       => 2,
      p_level_units       => 'ft',
      p_effective_date    => date '1900-01-01',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_level.store_location_level(
      p_location_level_id => l_location_id||'.Elev.Inst.0.Top of Normal',
      p_level_value       => 8,
      p_level_units       => 'ft',
      p_effective_date    => date '1900-01-01',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   l_location_obj := cwms_t_location_obj(cwms_loc.get_location_code(c_office_id, l_location_id));
   l_project_obj := cwms_t_project_obj(l_location_obj,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
   cwms_project.store_project(l_project_obj, 'F');
   cwms_pool.store_pool(
      p_project_id      => l_location_id,
      p_pool_name       => 'Normal',
      p_bottom_level_id => 'Elev.Inst.0.Bottom of Normal',
      p_top_level_id    =>'.Elev.Inst.0.Top of Normal',
      p_fail_if_exists  => 'F',
      p_office_id       => c_office_id);
   --------------------------------
   -- test all flag combinations --
   --------------------------------
   for i in 1..2 loop
      cwms_util.set_session_info('USE_NEW_LRTS_ID_FORMAT', 0);
      dbms_output.put_line(chr(10)||'==> i = '||i||': Setting session to use new LRTS format on output to '||substr('FT', i, 1));
      cwms_ts.set_use_new_lrts_format_on_output(substr('FT', i, 1));
      ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
      ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('F');
      ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('F');
      for j in 1..2 loop
         dbms_output.put_line('==> i,j = '||j||','||j||': Setting session to allow use of new LRTS format to '||substr('FT', j, 1));
         cwms_ts.set_allow_new_lrts_format_on_input(substr('FT', j, 1));
         if j = 1 then
            ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
            ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('F');
            ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('F');
         else
            ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
            ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('T');
            ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('F');
         end if;
         for k in 1..2 loop
            dbms_output.put_line('==> i,j,k = '||j||','||j||','||k||': Setting session to require use of new LRTS format to '||substr('FT', k, 1));
            cwms_ts.set_require_new_lrts_format_on_input(substr('FT', k, 1));
            -- should reset allow_new_lrts_format_on_intput to 'F'
            if k = 1 then
               ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
               ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('F');
               ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('F');
            else
               ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
               ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('F');
               ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('T');
            end if;
            for m in 1..2 loop
               dbms_output.put_line('==> i,j,k,m = '||j||','||j||','||k||','||m||': Setting session to allow use of new LRTS format to '||substr('FT', m, 1));
               cwms_ts.set_allow_new_lrts_format_on_input(substr('FT', m, 1));
               -- should reset require_new_lrts_format_on_intput to 'F'
               if m = 1 then
                  ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
                  ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('F');
                  ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('F');
               else
                  ut.expect(cwms_ts.use_new_lrts_format_on_output).to_equal(substr('FT', i, 1));
                  ut.expect(cwms_ts.allow_new_lrts_format_on_input).to_equal('T');
                  ut.expect(cwms_ts.require_new_lrts_format_on_input).to_equal('F');
               end if;
            end loop;
         end loop;
      end loop;
   end loop;
   -------------------------------
   -- test the input formatting --
   -------------------------------
   cwms_loc.clear_all_caches;
   cwms_ts.clear_all_caches;
   for i in 0..7 loop
      continue when i = 3; -- invalid value
      begin
         cwms_util.set_session_info('USE_NEW_LRTS_ID_FORMAT', i);
         if i in (3, 7) then
            cwms_err.raise('ERROR', 'Expected exception not raised');
         end if;
      exception
         when others then
            ut.expect(regexp_like(dbms_utility.format_error_stack, '.+not a valid value for session item USE_NEW_LRTS_ID_FORMAT.+', 'mn')).to_be_true;
      end;
      if i in (0, 4) then
         -- shouldn't revert
         ut.expect(cwms_ts.format_lrts_input(l_lrts_ts_id_new)).to_equal(l_lrts_ts_id_new);
         ut.expect(cwms_ts.format_lrts_input(l_lrts_ts_id_old)).to_equal(l_lrts_ts_id_old);
      else
         -- should revert
         ut.expect(cwms_ts.format_lrts_input(l_lrts_ts_id_new)).to_equal(l_lrts_ts_id_old);
         ut.expect(cwms_ts.format_lrts_input(l_lrts_ts_id_old)).to_equal(l_lrts_ts_id_old);
      end if;
   end loop;
   --------------------------
   -- test time series API --
   --------------------------
   ---------------------
   -- no new LRTS IDs --
   ---------------------
   cwms_loc.clear_all_caches;
   cwms_ts.clear_all_caches;
   cwms_ts.set_allow_new_lrts_format_on_input('F');
   cwms_ts.parse_ts(
      p_cwms_ts_id        => l_lrts_ts_id_old,
      p_base_location_id  => l_base_location_id,
      p_sub_location_id   => l_sub_location_id,
      p_base_parameter_id => l_base_parameter_id,
      p_sub_parameter_id  => l_sub_parameter_id,
      p_parameter_type_id => l_parameter_type_id,
      p_interval_id       => l_interval_id,
      p_duration_id       => l_duration_Id,
      p_version_id        => l_version_id);
   ut.expect(l_interval_id).to_equal(cwms_util.split_text(l_lrts_ts_id_old, 4, '.'));
   cwms_ts.parse_ts(
      p_cwms_ts_id        => l_lrts_ts_id_new,
      p_base_location_id  => l_base_location_id,
      p_sub_location_id   => l_sub_location_id,
      p_base_parameter_id => l_base_parameter_id,
      p_sub_parameter_id  => l_sub_parameter_id,
      p_parameter_type_id => l_parameter_type_id,
      p_interval_id       => l_interval_id,
      p_duration_id       => l_duration_Id,
      p_version_id        => l_version_id);
   ut.expect(l_interval_id).to_equal(cwms_util.split_text(l_lrts_ts_id_new, 4, '.'));
   cwms_shef.parse_criteria_record (
      p_shef_id            => l_shef_id,
      p_shef_pe_code       => l_shef_pe_code,
      p_shef_tse_code      => l_shef_tse_code,
      p_shef_duration_code => l_shef_duration_code,
      p_units              => l_units,
      p_unit_sys           => l_unit_sys,
      p_tz                 => l_tz,
      p_dltime             => l_dltime,
      p_int_offset         => l_int_offset,
      p_int_backward       => l_int_backward,
      p_int_forward        => l_int_forward,
      p_cwms_ts_id         => l_cwms_ts_id,
      p_comment            => l_text,
      p_criteria_record    => 'VIOK1.HP.RGZ.1440='||l_lrts_ts_id_old||';Units=ft;TZ=UTC;DLTime=false');
   ut.expect(l_cwms_ts_id).to_equal(l_lrts_ts_id_old);
   cwms_shef.parse_criteria_record (
      p_shef_id            => l_shef_id,
      p_shef_pe_code       => l_shef_pe_code,
      p_shef_tse_code      => l_shef_tse_code,
      p_shef_duration_code => l_shef_duration_code,
      p_units              => l_units,
      p_unit_sys           => l_unit_sys,
      p_tz                 => l_tz,
      p_dltime             => l_dltime,
      p_int_offset         => l_int_offset,
      p_int_backward       => l_int_backward,
      p_int_forward        => l_int_forward,
      p_cwms_ts_id         => l_cwms_ts_id,
      p_comment            => l_text,
      p_criteria_record    => 'VIOK1.HP.RGZ.1440='||l_lrts_ts_id_new||';Units=ft;TZ=UTC;DLTime=false');
   ut.expect(l_cwms_ts_id).to_equal(l_lrts_ts_id_new);
   -- should succeed
   --.... create, update, store ts
   cwms_ts.create_ts(
      p_cwms_ts_id => l_lrts_ts_id_old,
      p_utc_offset => 0,
      p_versioned  => 'F',
      p_office_id  => c_office_id);
   cwms_ts.update_ts_id(
      p_cwms_ts_id          => l_lrts_ts_id_old,
      p_interval_utc_offset => 420,
      p_db_office_id        => c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_all, c_office_id);
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_old,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_units           => 'ac-ft',
      p_timeseries_data => l_ts_data2,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_old_copy,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_units           => 'ac-ft',
      p_timeseries_data => l_ts_data2,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   --.... retrieve ts
   cwms_ts.retrieve_ts(
      p_at_tsv_rc  => l_crsr,
      p_cwms_ts_id => l_lrts_ts_id_old,
      p_units      => 'ft',
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_office_id  => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_count);
   --.... rename ts
   cwms_ts.rename_ts(l_lrts_ts_id_old, l_lrts_ts_id_old||'2', null, c_office_id);
   cwms_ts.rename_ts(l_lrts_ts_id_old||'2', l_lrts_ts_id_old, null, c_office_id);
   --.... get IDs and codes
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_lrts_ts_id_new);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_lrts_ts_id_old);
   ut.expect(cwms_ts.get_ts_code(l_lrts_ts_id_old, c_office_id)).to_be_not_null;
   ut.expect(cwms_ts.get_db_unit_id(l_lrts_ts_id_old)).to_equal('m');
   ut.expect(cwms_ts.get_location_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_location_id);
   --.... get/set info
   ut.expect(cwms_ts.get_tsid_time_zone(l_lrts_ts_id_old, c_office_id)).to_equal(c_timezone_ids(1));
   cwms_ts.set_tsid_versioned(l_lrts_ts_id_old, 'T', c_office_id);
   ut.expect(cwms_ts.is_tsid_versioned_f(l_lrts_ts_id_old, c_office_id)).to_equal('T');
   cwms_ts.get_tsid_version_dates(l_crsr, l_lrts_ts_id_old, date '1000-01-01', date '3000-01-01', 'UTC', c_office_id);
   fetch l_crsr bulk collect into l_date_times;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(1);
   ut.expect(cwms_ts.get_ts_interval(l_lrts_ts_id_old)).to_equal(0);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_old)).to_equal('1DayLocal');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_old)).to_equal('~1Day');
   ut.expect(cwms_ts.get_ts_min_date(l_lrts_ts_id_old, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_start_time);
   ut.expect(cwms_ts.get_ts_max_date(l_lrts_ts_id_old, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_end_time);
   cwms_ts.get_value_extents(l_min_value, l_max_value, l_lrts_ts_id_old, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(round(l_min_value, 9)).to_equal(1);
   ut.expect(round(l_max_value, 9)).to_equal(l_ts_data.count);
   l_ts_data_out := cwms_ts.get_values_in_range(l_lrts_ts_id_old, 1, l_count, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_count);
   cwms_ts.set_nulls_storage_policy_ts(cwms_Ts.filter_out_null_values, l_lrts_ts_id_old, c_office_id);
   ut.expect(cwms_ts.get_nulls_storage_policy_ts(l_lrts_ts_id_old, c_office_id)).to_equal(cwms_ts.filter_out_null_values);
   cwms_ts.set_nulls_storage_policy_ts(null, l_lrts_ts_id_old, c_office_id);
   cwms_ts.set_filter_duplicates_ts('T', l_lrts_ts_id_old, c_office_id);
   ut.expect(cwms_ts.get_filter_duplicates(l_lrts_ts_id_old, c_office_id)).to_equal('T');
   cwms_ts.set_historic(l_lrts_ts_id_old, 'T', c_office_id);
   ut.expect(cwms_ts.is_historic(l_lrts_ts_id_old, c_office_id)).to_equal('T');
   --.... group operations
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory',
      p_ts_group_id      => 'TestGroup_old',
      p_shared_ts_ref_id => l_lrts_ts_id_old,
      p_db_office_id     => c_office_id);
   cwms_ts.assign_ts_group('TestCategory', 'TestGroup_old', l_lrts_ts_id_old, 1, null, l_lrts_ts_id_old, c_office_id);
   cwms_ts.unassign_ts_group('TestCategory', 'TestGroup_old', l_lrts_ts_id_old, 'F', c_office_id);
   cwms_ts.assign_ts_groups('TestCategory', 'TestGroup_old', cwms_t_ts_alias_tab(cwms_t_ts_alias(l_lrts_ts_id_old, 1, null, l_lrts_ts_id_old)), c_office_id);
   cwms_ts.unassign_ts_groups('TestCategory', 'TestGroup_old', cwms_t_str_tab(l_lrts_ts_id_old), 'F', c_office_id);
   cwms_ts.delete_ts_group('TestCategory', 'TestGroup_old', c_office_id);
   --.... cwms_cat package
   cwms_cat.cat_ts_aliases(
      p_cwms_cat     => l_crsr,
      p_ts_id        => l_lrts_ts_id_old,
      p_db_office_id => c_office_id);
   close l_crsr;
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => l_lrts_ts_id_old,
      p_db_office_id        => c_office_id);
   close l_crsr;
   --.... cwms_level package
   cwms_level.store_location_level(cwms_t_location_level(
      c_office_id, l_location_id, 'Elev-Lrts', 'Inst', '0', 'Test',
      null, null, null, null, null, null, null, null, null, null, null, null, null, null,
      'T', l_lrts_ts_id_old,
      null, null, null, null, null, null));
   cwms_level.store_location_level3(
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_value       => null,
      p_level_units       => 'ft',
      p_tsid              => l_lrts_ts_id_old,
      p_office_id         => c_office_id);
   l_ts_data_out := cwms_level.retrieve_location_level_values(
      p_ts_id         => l_lrts_ts_id_old,
      p_spec_level_id => 'Test',
      p_level_units   => 'ft',
      p_start_time    => l_start_time,
      p_end_time      => l_end_time,
      p_office_id     => c_office_id);
   l_ts_data_out := cwms_level.retrieve_loc_lvl_values3(
      p_ts_id             => l_lrts_ts_id_old,
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_units       => 'ft',
      p_start_time        => l_start_time,
      p_end_time          => l_end_time,
      p_office_id         => c_office_id);
   cwms_level.store_loc_lvl_indicator(
      p_loc_lvl_indicator_id => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
      p_minimum_duration     => to_dsinterval('000 00:00:01'),
      p_maximum_age          => to_dsinterval('001 00:00:00'),
      p_office_id            => c_office_id);
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id  => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
         p_level_indicator_value => i,
         p_expression            => 'V',
         p_comparison_operator_1 => 'LT',
         p_comparison_value_1    => 2*i,
         p_comparison_unit_id    => 'ft',
         p_office_id             => c_office_id);
   end loop;
   cwms_level.get_level_indicator_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_old,
      p_eval_time            => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   cwms_level.get_level_indicator_max_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_old,
      p_start_time           => l_start_time,
      p_end_time             => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   l_ts_data_out := cwms_level.eval_level_indicator_expr (
      p_tsid               => l_lrts_ts_id_old,
      p_start_time         => l_start_time,
      p_end_time           => l_end_time,
      p_unit               => 'ft',
      p_specified_level_id => 'Test',
      p_indicator_id       => 'VALUE',
      p_condition_number   => 3,
      p_office_id          => c_office_id);
   --.... cwms_forecast package
   l_crsr := cwms_forecast.cat_ts_f(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_cwms_ts_id_mask => l_lrts_ts_id_old,
      p_office_id       => c_office_id);
   close l_crsr;
   cwms_forecast.retrieve_ts(
      p_ts_cursor      => l_crsr,
      p_version_date   => l_version_date,
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_cwms_ts_id     => replace(l_lrts_ts_id_old, '.Test', '.Forecast'),
      p_units          => 'ft',
      p_forecast_time  => l_end_time,
      p_issue_time     => l_start_time,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_time_zone      => c_timezone_ids(1),
      p_office_id      => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
      ut.expect(round(l_values(i), 9)).to_equal(l_ts_data(i).value);
      ut.expect(l_quality_codes(i)).to_equal(l_ts_data(i).quality_code);
   end loop;
   --.... cwms_text package
   select date_time bulk collect into l_date_times from table(l_ts_data);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_old,
      p_std_text_id  => 'A',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_old,
      p_std_text_id  => 'B',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => l_lrts_ts_id_old,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => l_lrts_ts_id_old,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id  => 'C',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id  => 'D',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_old,
      p_text        => 'Nonstandard text-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_old,
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'First text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-1',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'Second text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-2',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_old,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_old,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => l_lrts_ts_id_old,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => l_lrts_ts_id_old,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_text (
      p_tsid        => l_lrts_ts_id_old,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   begin
      cwms_text.store_ts_text (
         p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
         p_text        => 'Nonstandard text-1',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_TEXT to store text to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_text (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_old,
      p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_old,
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('First binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-1',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('Second binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-2',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_old,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_old,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => l_lrts_ts_id_old,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => l_lrts_ts_id_old,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      -- dbms_output.put_line(
      --    l_count
      --    ||chr(9)||l_date_time
      --    ||chr(9)||l_text
      --    ||chr(9)||l_number
      --    ||chr(9)||l_media_type
      --    ||chr(9)||l_file_extension
      --    ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_binary (
      p_tsid             => l_lrts_ts_id_old,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   begin
      cwms_text.store_ts_binary (
         p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
         p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
         p_binary_type => 'bin',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_BINARY to store binary to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_binary (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => 'bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      -- dbms_output.put_line(
      --    l_count
      --    ||chr(9)||l_date_time
      --    ||chr(9)||l_text
      --    ||chr(9)||l_number
      --    ||chr(9)||l_media_type
      --    ||chr(9)||l_file_extension
      --    ||chr(9)||utl_i18n.raw_to_char(l_blob));
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Binary'), cwms_util.delete_all, c_office_id);
   --.... cwms_pool package
   cwms_pool.get_elev_offsets(
      p_offsets    => l_ts_data_out,
      p_project_id => l_location_id,
      p_pool_name  => 'Normal',
      p_limit      => 'Top',
      p_unit       => 'ft',
      p_tsid       => l_lrts_ts_id_old,
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_timezone   => 'UTC',
      p_office_id  => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_elev_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ft',
      p_tsid           => l_lrts_ts_id_old,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_elevs(
      p_limit_elevs => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ft',
      p_tsid        => l_lrts_ts_id_old,
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_elevs(
      p_bottom_elevs => l_ts_data_out,
      p_top_elevs    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_stor_offsets(
      p_offsets     => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ac-ft',
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_stor_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ac-ft',
      p_tsid           => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_stors(
      p_limit_stors  => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_limit        => 'Top',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_stors(
      p_bottom_stors => l_ts_data_out,
      p_top_stors    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_percent_full(
      p_percent_full => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||round(to_number(l_ts_data_out(i).value), 4));
   -- end loop;
   --.... cwms_alarm package
   cwms_alarm.notify_loc_lvl_ind_state (
      p_ts_id              => l_lrts_ts_id_old,
      p_specified_level_id => 'Test',
      p_level_indicator_id => 'VALUE',
      p_min_state_notify   => 0,
      p_max_state_notify   => 5,
      p_office_id          => c_office_id);
   --.... other packages
   cwms_ts_profile.store_ts_profile(l_location_id, 'Depth-Lrts', 'Depth-Lrts,Temp-Lrts',null, l_lrts_ts_id_old, 'F', 'T', c_office_id);
   begin
      cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_new_copy, 'F', 'F', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_old_copy, 'F', 'F', c_office_id);
   cwms_vt.assign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_scr_assign_array    => cwms_t_screen_assign_array(cwms_t_screen_assign(l_lrts_ts_id_old, 'T', replace(l_lrts_ts_id_old, '.Test', '.Rev'))),
      p_db_office_id        => c_office_id);
   cwms_vt.unassign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_cwms_ts_id_array    => cwms_t_ts_id_array(cwms_t_ts_id(l_lrts_ts_id_old)),
      p_db_office_id        => c_office_id);
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_lrts_ts_id_old,
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HP',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                  cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                  1440),
      p_db_office_id        => c_office_id);
   cwms_shef.delete_shef_spec (
      p_cwms_ts_id     => l_lrts_ts_id_old,
      p_data_stream_id => 'Test_Data_Stream',
      p_db_office_id   => c_office_id);
   --.... delete, undelete
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_key, c_office_id);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      l_count := l_count + 1;
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_new);
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      l_count := l_count + 1;
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_old);
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.undelete_ts(l_lrts_ts_id_old, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_old_copy, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Stor'), cwms_util.delete_all, c_office_id);
   -- should fail
   --.... create, update, store ts
   begin
      cwms_ts.create_ts(
         p_cwms_ts_id => l_lrts_ts_id_new,
         p_utc_offset => 0,
         p_versioned  => 'F',
         p_office_id  => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+1DayLocal is not a valid interval.+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.update_ts_id(
         p_cwms_ts_id          => l_lrts_ts_id_new,
         p_interval_utc_offset => 420,
         p_db_office_id        => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_lrts_ts_id_new,
         p_units           => 'ft',
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_office_id       => c_office_id,
         p_create_as_lrts  => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+INVALID_INTERVAL_ID: "1DayLocal" is not a valid CWMS timeseries interval.+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.retrieve_ts(
         p_at_tsv_rc  => l_crsr,
         p_cwms_ts_id => l_lrts_ts_id_new,
         p_units      => 'ft',
         p_start_time => l_start_time,
         p_end_time   => l_end_time,
         p_office_id  => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... rename_ts
   begin
      cwms_ts.rename_ts(l_lrts_ts_id_new, l_lrts_ts_id_new||'2', null, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... get IDs and codes
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_new, c_office_id)).to_be_null;
   begin
      ut.expect(cwms_ts.get_ts_code(l_lrts_ts_id_new, c_office_id)).to_be_null;
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   ut.expect(cwms_ts.get_db_unit_id(l_lrts_ts_id_new)).to_equal('m');
   begin
      ut.expect(cwms_ts.get_location_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_location_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... get/set info
   begin
      ut.expect(cwms_ts.get_tsid_time_zone(l_lrts_ts_id_new, c_office_id)).to_equal(c_timezone_ids(1));
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_tsid_versioned(l_lrts_ts_id_new, 'T', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.is_tsid_versioned_f(l_lrts_ts_id_new, c_office_id)).to_equal('T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.get_tsid_version_dates(l_crsr, l_lrts_ts_id_new, date '1000-01-01', date '3000-01-01', 'UTC', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   ut.expect(cwms_ts.get_ts_interval(l_lrts_ts_id_new)).to_equal(0);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_new)).to_equal('1DayLocal');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_new)).to_equal('~1Day');
   begin
      ut.expect(cwms_ts.get_ts_min_date(l_lrts_ts_id_new, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_start_time);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.get_ts_max_date(l_lrts_ts_id_new, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_end_time);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.get_value_extents(l_min_value, l_max_value, l_lrts_ts_id_new, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      l_ts_data_out := cwms_ts.get_values_in_range(l_lrts_ts_id_new, 1, l_count, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_nulls_storage_policy_ts(cwms_Ts.filter_out_null_values, l_lrts_ts_id_new, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.get_nulls_storage_policy_ts(l_lrts_ts_id_new, c_office_id)).to_equal(cwms_ts.filter_out_null_values);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_filter_duplicates_ts('T', l_lrts_ts_id_new, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.get_filter_duplicates(l_lrts_ts_id_new, c_office_id)).to_equal('T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_historic(l_lrts_ts_id_new, 'T', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.is_historic(l_lrts_ts_id_new, c_office_id)).to_equal('T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... group operations
   begin
      cwms_ts.store_ts_group(
         p_ts_category_id   => 'TestCategory',
         p_ts_group_id      => 'TestGroup_new',
         p_shared_ts_ref_id => l_lrts_ts_id_new,
         p_db_office_id     => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory',
      p_ts_group_id      => 'TestGroup_new',
      p_db_office_id     => c_office_id);
   begin
      cwms_ts.assign_ts_group('TestCategory', 'TestGroup_new', l_lrts_ts_id_new, 1, null, l_lrts_ts_id_new, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.unassign_ts_group('TestCategory', 'TestGroup_new', l_lrts_ts_id_new, 'F', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.assign_ts_groups('TestCategory', 'TestGroup_new', cwms_t_ts_alias_tab(cwms_t_ts_alias(l_lrts_ts_id_new, 1, null, l_lrts_ts_id_new)), c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.unassign_ts_groups('TestCategory', 'TestGroup_new', cwms_t_str_tab(l_lrts_ts_id_new), 'F', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   cwms_ts.delete_ts_group('TestCategory', 'TestGroup_new', c_office_id);
   --.... cwms_cat package
   cwms_cat.cat_ts_aliases(
      p_cwms_cat     => l_crsr,
      p_ts_id        => l_lrts_ts_id_new,
      p_db_office_id => c_office_id);
   close l_crsr;
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => l_lrts_ts_id_old,
      p_db_office_id        => c_office_id);
   close l_crsr;
   --.... cwms_level package
   begin
      cwms_level.store_location_level(cwms_t_location_level(
         c_office_id, l_location_id, 'Elev-Lrts', 'Inst', '0', 'Test',
         null, null, null, null, null, null, null, null, null, null, null, null, null, null,
         'T', l_lrts_ts_id_new,
         null, null, null, null, null, null));
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_level.store_location_level3(
         p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
         p_level_value       => null,
         p_level_units       => 'ft',
         p_tsid              => l_lrts_ts_id_new,
         p_office_id         => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... cwms_forecast package
   l_crsr := cwms_forecast.cat_ts_f(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_cwms_ts_id_mask => l_lrts_ts_id_new,
      p_office_id       => c_office_id);
   close l_crsr;
   begin
      cwms_forecast.retrieve_ts(
         p_ts_cursor      => l_crsr,
         p_version_date   => l_version_date,
         p_location_id    => l_location_id,
         p_forecast_id    => 'TEST',
         p_cwms_ts_id     => replace(l_lrts_ts_id_new, '.Test', '.Forecast'),
         p_units          => 'ft',
         p_forecast_time  => l_end_time,
         p_issue_time     => l_start_time,
         p_start_time     => l_start_time,
         p_end_time       => l_end_time,
         p_time_zone      => c_timezone_ids(1),
         p_office_id      => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... cwms_pool package
   begin
      cwms_pool.get_elev_offsets(
         p_offsets    => l_ts_data_out,
         p_project_id => l_location_id,
         p_pool_name  => 'Normal',
         p_limit      => 'Top',
         p_unit       => 'ft',
         p_tsid       => l_lrts_ts_id_new,
         p_start_time => l_start_time,
         p_end_time   => l_end_time,
         p_timezone   => 'UTC',
         p_office_id  => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_pool.get_elev_offsets(
         p_bottom_offsets => l_ts_data_out,
         p_top_offsets    => l_ts_data_out2,
         p_project_id     => l_location_id,
         p_pool_name      => 'Normal',
         p_unit           => 'ft',
         p_tsid           => l_lrts_ts_id_new,
         p_start_time     => l_start_time,
         p_end_time       => l_end_time,
         p_timezone       => 'UTC',
         p_office_id      => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_pool.get_pool_limit_elevs(
         p_limit_elevs => l_ts_data_out,
         p_project_id  => l_location_id,
         p_pool_name   => 'Normal',
         p_limit       => 'Top',
         p_unit        => 'ft',
         p_tsid        => l_lrts_ts_id_new,
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_timezone    => 'UTC',
         p_office_id   => c_office_id);
      ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_pool.get_pool_limit_elevs(
         p_bottom_elevs => l_ts_data_out,
         p_top_elevs    => l_ts_data_out2,
         p_project_id   => l_location_id,
         p_pool_name    => 'Normal',
         p_unit         => 'ft',
         p_tsid         => l_lrts_ts_id_new,
         p_start_time   => l_start_time,
         p_end_time     => l_end_time,
         p_timezone     => 'UTC',
         p_office_id    => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... other packages
   begin
      cwms_ts_profile.store_ts_profile(l_location_id, 'Depth-Lrts', 'Depth-Lrts,Temp-Lrts',null, l_lrts_ts_id_new, 'F', 'T', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_vt.assign_screening_id (
         p_screening_id        => 'Elev Range 1',
         p_scr_assign_array    => cwms_t_screen_assign_array(cwms_t_screen_assign(l_lrts_ts_id_new, 'T', replace(l_lrts_ts_id_new, '.Test', '.Rev'))),
         p_db_office_id        => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when no_data_found then null;
   end;
   begin
      cwms_shef.store_shef_spec (
         p_cwms_ts_id          => l_lrts_ts_id_new,
         p_data_stream_id      => 'Test_Data_Stream',
         p_shef_loc_id         => 'SHEFO2',
         p_shef_pe_code        => 'HP',
         p_shef_tse_code       => 'RGZ',
         p_shef_duration_code  => 'I',
         p_shef_unit_id        => 'ft',
         p_time_zone_id        => 'UTC',
         p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                     cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                     1440),
         p_db_office_id        => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_shef.delete_shef_spec (
         p_cwms_ts_id     => l_lrts_ts_id_new,
         p_data_stream_id => 'Test_Data_Stream',
         p_db_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... delete, undelete
   begin
      cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_all, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.delete_ts(l_lrts_ts_id_new_copy, cwms_util.delete_all, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;

   -------------------------
   -- allow new LRTS IDs --
   ------------------------
   cwms_loc.clear_all_caches;
   cwms_ts.clear_all_caches;
   cwms_ts.set_allow_new_lrts_format_on_input('T');
   -- should succeed
   --.... create, update, store ts
   cwms_ts.create_ts(
      p_cwms_ts_id => l_lrts_ts_id_old,
      p_utc_offset => 0,
      p_versioned  => 'F',
      p_office_id  => c_office_id);
   cwms_ts.update_ts_id(
      p_cwms_ts_id          => l_lrts_ts_id_old,
      p_interval_utc_offset => 420,
      p_db_office_id        => c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_all, c_office_id);
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_old,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_old_copy,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_units           => 'ac-ft',
      p_timeseries_data => l_ts_data2,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   --.... retrieve ts
   cwms_ts.retrieve_ts(
      p_at_tsv_rc  => l_crsr,
      p_cwms_ts_id => l_lrts_ts_id_old,
      p_units      => 'ft',
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_office_id  => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   --.... rename_ts
   cwms_ts.rename_ts(l_lrts_ts_id_old, l_lrts_ts_id_old||'2', null, c_office_id);
   cwms_ts.rename_ts(l_lrts_ts_id_old||'2', l_lrts_ts_id_old, null, c_office_id);
   --.... get IDs and codes
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_lrts_ts_id_new);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_lrts_ts_id_old);
   ut.expect(cwms_ts.get_ts_code(l_lrts_ts_id_old, c_office_id)).to_be_not_null;
   ut.expect(cwms_ts.get_db_unit_id(l_lrts_ts_id_old)).to_equal('m');
   ut.expect(cwms_ts.get_location_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_location_id);
   --.... get/set info
   ut.expect(cwms_ts.get_tsid_time_zone(l_lrts_ts_id_old, c_office_id)).to_equal(c_timezone_ids(1));
   cwms_ts.set_tsid_versioned(l_lrts_ts_id_old, 'T', c_office_id);
   ut.expect(cwms_ts.is_tsid_versioned_f(l_lrts_ts_id_old, c_office_id)).to_equal('T');
   cwms_ts.get_tsid_version_dates(l_crsr, l_lrts_ts_id_old, date '1000-01-01', date '3000-01-01', 'UTC', c_office_id);
   fetch l_crsr bulk collect into l_date_times;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(1);
   ut.expect(cwms_ts.get_ts_interval(l_lrts_ts_id_old)).to_equal(0);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_old)).to_equal('1DayLocal');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_old)).to_equal('~1Day');
   ut.expect(cwms_ts.get_ts_min_date(l_lrts_ts_id_old, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_start_time);
   ut.expect(cwms_ts.get_ts_max_date(l_lrts_ts_id_old, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_end_time);
   cwms_ts.get_value_extents(l_min_value, l_max_value, l_lrts_ts_id_old, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(round(l_min_value, 9)).to_equal(1);
   ut.expect(round(l_max_value, 9)).to_equal(l_ts_data.count);
   l_ts_data_out := cwms_ts.get_values_in_range(l_lrts_ts_id_old, 1, l_count, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_count);
   cwms_ts.set_nulls_storage_policy_ts(cwms_Ts.filter_out_null_values, l_lrts_ts_id_old, c_office_id);
   ut.expect(cwms_ts.get_nulls_storage_policy_ts(l_lrts_ts_id_old, c_office_id)).to_equal(cwms_ts.filter_out_null_values);
   cwms_ts.set_nulls_storage_policy_ts(null, l_lrts_ts_id_old, c_office_id);
   cwms_ts.set_filter_duplicates_ts('T', l_lrts_ts_id_old, c_office_id);
   ut.expect(cwms_ts.get_filter_duplicates(l_lrts_ts_id_old, c_office_id)).to_equal('T');
   cwms_ts.set_historic(l_lrts_ts_id_old, 'T', c_office_id);
   ut.expect(cwms_ts.is_historic(l_lrts_ts_id_old, c_office_id)).to_equal('T');
   --.... group operations
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory',
      p_ts_group_id      => 'TestGroup_old',
      p_shared_ts_ref_id => l_lrts_ts_id_old,
      p_db_office_id     => c_office_id);
   cwms_ts.assign_ts_group('TestCategory', 'TestGroup_old', l_lrts_ts_id_old, 1, null, l_lrts_ts_id_old, c_office_id);
   cwms_ts.unassign_ts_group('TestCategory', 'TestGroup_old', l_lrts_ts_id_old, 'F', c_office_id);
   cwms_ts.assign_ts_groups('TestCategory', 'TestGroup_old', cwms_t_ts_alias_tab(cwms_t_ts_alias(l_lrts_ts_id_old, 1, null, l_lrts_ts_id_old)), c_office_id);
   cwms_ts.unassign_ts_groups('TestCategory', 'TestGroup_old', cwms_t_str_tab(l_lrts_ts_id_old), 'F', c_office_id);
   cwms_ts.delete_ts_group('TestCategory', 'TestGroup_old', c_office_id);
   --.... cwms_cat package
   cwms_cat.cat_ts_aliases(
      p_cwms_cat     => l_crsr,
      p_ts_id        => l_lrts_ts_id_old,
      p_db_office_id => c_office_id);
   close l_crsr;
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => l_lrts_ts_id_old,
      p_db_office_id        => c_office_id);
   close l_crsr;
   --.... cwms_level package
   cwms_level.store_location_level(cwms_t_location_level(
      c_office_id, l_location_id, 'Elev-Lrts', 'Inst', '0', 'Test',
      null, null, null, null, null, null, null, null, null, null, null, null, null, null,
      'T', l_lrts_ts_id_old,
      null, null, null, null, null, null));
   cwms_level.store_location_level3(
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_value       => null,
      p_level_units       => 'ft',
      p_tsid              => l_lrts_ts_id_old,
      p_office_id         => c_office_id);
   l_ts_data_out := cwms_level.retrieve_location_level_values(
      p_ts_id         => l_lrts_ts_id_old,
      p_spec_level_id => 'Test',
      p_level_units   => 'ft',
      p_start_time    => l_start_time,
      p_end_time      => l_end_time,
      p_office_id     => c_office_id);
   l_ts_data_out := cwms_level.retrieve_loc_lvl_values3(
      p_ts_id             => l_lrts_ts_id_old,
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_units       => 'ft',
      p_start_time        => l_start_time,
      p_end_time          => l_end_time,
      p_office_id         => c_office_id);
   cwms_level.store_loc_lvl_indicator(
      p_loc_lvl_indicator_id => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
      p_minimum_duration     => to_dsinterval('000 00:00:01'),
      p_maximum_age          => to_dsinterval('001 00:00:00'),
      p_office_id            => c_office_id);
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id  => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
         p_level_indicator_value => i,
         p_expression            => 'V',
         p_comparison_operator_1 => 'LT',
         p_comparison_value_1    => 2*i,
         p_comparison_unit_id    => 'ft',
         p_office_id             => c_office_id);
   end loop;
   cwms_level.get_level_indicator_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_old,
      p_eval_time            => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   cwms_level.get_level_indicator_max_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_old,
      p_start_time           => l_start_time,
      p_end_time             => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   l_ts_data_out := cwms_level.eval_level_indicator_expr (
      p_tsid               => l_lrts_ts_id_old,
      p_start_time         => l_start_time,
      p_end_time           => l_end_time,
      p_unit               => 'ft',
      p_specified_level_id => 'Test',
      p_indicator_id       => 'VALUE',
      p_condition_number   => 3,
      p_office_id          => c_office_id);
   --.... cwms_forecast package
   l_crsr := cwms_forecast.cat_ts_f(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_cwms_ts_id_mask => l_lrts_ts_id_old,
      p_office_id       => c_office_id);
   close l_crsr;
   cwms_forecast.retrieve_ts(
      p_ts_cursor      => l_crsr,
      p_version_date   => l_version_date,
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_cwms_ts_id     => replace(l_lrts_ts_id_old, '.Test', '.Forecast'),
      p_units          => 'ft',
      p_forecast_time  => l_end_time,
      p_issue_time     => l_start_time,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_time_zone      => c_timezone_ids(1),
      p_office_id      => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
      ut.expect(round(l_values(i), 9)).to_equal(l_ts_data(i).value);
      ut.expect(l_quality_codes(i)).to_equal(l_ts_data(i).quality_code);
   end loop;
   --.... cwms_text package
   select date_time bulk collect into l_date_times from table(l_ts_data);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_old,
      p_std_text_id  => 'A',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_old,
      p_std_text_id  => 'B',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => l_lrts_ts_id_old,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => l_lrts_ts_id_old,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id  => 'C',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id  => 'D',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.delete_ts_std_text(
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_old,
      p_text        => 'Nonstandard text-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_old,
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'First text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-1',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'Second text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-2',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_old,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_old,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => l_lrts_ts_id_old,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => l_lrts_ts_id_old,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_text (
      p_tsid        => l_lrts_ts_id_old,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   begin
      cwms_text.store_ts_text (
         p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
         p_text        => 'Nonstandard text-1',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_TEXT to store text to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_text (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_old,
      p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_old,
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('First binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-1',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('Second binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-2',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_old,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_old,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => l_lrts_ts_id_old,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => l_lrts_ts_id_old,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      --dbms_output.put_line(
      --   l_count
      --   ||chr(9)||l_date_time
      --   ||chr(9)||l_text
      --   ||chr(9)||l_number
      --   ||chr(9)||l_media_type
      --   ||chr(9)||l_file_extension
      --   ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_binary (
      p_tsid             => l_lrts_ts_id_old,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   begin
      cwms_text.store_ts_binary (
         p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
         p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
         p_binary_type => 'bin',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_BINARY to store binary to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_binary (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => 'bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => replace(l_lrts_ts_id_old, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      --dbms_output.put_line(
      --   l_count
      --   ||chr(9)||l_date_time
      --   ||chr(9)||l_text
      --   ||chr(9)||l_number
      --   ||chr(9)||l_media_type
      --   ||chr(9)||l_file_extension
      --   ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Binary'), cwms_util.delete_all, c_office_id);
   --.... cwms_pool package
   cwms_pool.get_elev_offsets(
      p_offsets    => l_ts_data_out,
      p_project_id => l_location_id,
      p_pool_name  => 'Normal',
      p_limit      => 'Top',
      p_unit       => 'ft',
      p_tsid       => l_lrts_ts_id_old,
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_timezone   => 'UTC',
      p_office_id  => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_elev_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ft',
      p_tsid           => l_lrts_ts_id_old,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_elevs(
      p_limit_elevs => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ft',
      p_tsid        => l_lrts_ts_id_old,
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_elevs(
      p_bottom_elevs => l_ts_data_out,
      p_top_elevs    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_stor_offsets(
      p_offsets     => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ac-ft',
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_stor_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ac-ft',
      p_tsid           => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_stors(
      p_limit_stors  => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_limit        => 'Top',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_stors(
      p_bottom_stors => l_ts_data_out,
      p_top_stors    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_stor_offsets(
      p_offsets     => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ac-ft',
      p_tsid        => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_stor_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ac-ft',
      p_tsid           => replace(l_lrts_ts_id_old, 'Elev', 'Stor'),
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_stors(
      p_limit_stors  => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_limit        => 'Top',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_stors(
      p_bottom_stors => l_ts_data_out,
      p_top_stors    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_percent_full(
      p_percent_full => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_tsid         => l_lrts_ts_id_old,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||round(to_number(l_ts_data_out(i).value), 4));
   -- end loop;
   --.... cwms_alarm package
   cwms_alarm.notify_loc_lvl_ind_state (
      p_ts_id              => l_lrts_ts_id_old,
      p_specified_level_id => 'Test',
      p_level_indicator_id => 'VALUE',
      p_min_state_notify   => 0,
      p_max_state_notify   => 5,
      p_office_id          => c_office_id);
   --.... other packages
   cwms_ts_profile.store_ts_profile(l_location_id, 'Depth-Lrts', 'Depth-Lrts,Temp-Lrts',null, l_lrts_ts_id_old, 'F', 'T', c_office_id);
   cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_old_copy, 'F', 'F', c_office_id);
   cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_new_copy, 'F', 'F', c_office_id);
   cwms_vt.assign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_scr_assign_array    => cwms_t_screen_assign_array(cwms_t_screen_assign(l_lrts_ts_id_old, 'T', replace(l_lrts_ts_id_old, '.Test', '.Rev'))),
      p_db_office_id        => c_office_id);
   cwms_vt.unassign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_cwms_ts_id_array    => cwms_t_ts_id_array(cwms_t_ts_id(l_lrts_ts_id_old)),
      p_db_office_id        => c_office_id);
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_lrts_ts_id_old,
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HP',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                  cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                  1440),
      p_db_office_id        => c_office_id);
   cwms_shef.delete_shef_spec (
      p_cwms_ts_id     => l_lrts_ts_id_old,
      p_data_stream_id => 'Test_Data_Stream',
      p_db_office_id   => c_office_id);
   --.... delete, undelete
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_key, c_office_id);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_new);
      l_count := l_count + 1;
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_old);
      l_count := l_count + 1;
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.undelete_ts(l_lrts_ts_id_old, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_old_copy, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_old, 'Elev', 'Stor'), cwms_util.delete_all, c_office_id);
   -- should succeed
   --.... create, update, store ts
   cwms_ts.create_ts(
      p_cwms_ts_id => l_lrts_ts_id_new,
      p_utc_offset => 0,
      p_versioned  => 'F',
      p_office_id  => c_office_id);
   cwms_ts.update_ts_id(
      p_cwms_ts_id          => l_lrts_ts_id_new,
      p_interval_utc_offset => 420,
      p_db_office_id        => c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_all, c_office_id);
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_new,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_new_copy,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => replace(l_lrts_ts_id_new, 'Elev', 'Stor'),
      p_units           => 'ac-ft',
      p_timeseries_data => l_ts_data2,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   --.... retrieve ts
   cwms_ts.retrieve_ts(
      p_at_tsv_rc  => l_crsr,
      p_cwms_ts_id => l_lrts_ts_id_new,
      p_units      => 'ft',
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_office_id  => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   --.... rename_ts
   cwms_ts.rename_ts(l_lrts_ts_id_new, l_lrts_ts_id_new||'2', null, c_office_id);
   cwms_ts.rename_ts(l_lrts_ts_id_new||'2', l_lrts_ts_id_new, null, c_office_id);
   --.... get IDs and codes
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_lrts_ts_id_new);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_lrts_ts_id_old);
   ut.expect(cwms_ts.get_ts_code(l_lrts_ts_id_new, c_office_id)).to_be_not_null;
   ut.expect(cwms_ts.get_db_unit_id(l_lrts_ts_id_new)).to_equal('m');
   ut.expect(cwms_ts.get_location_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_location_id);
   --.... get/set info
   ut.expect(cwms_ts.get_tsid_time_zone(l_lrts_ts_id_new, c_office_id)).to_equal(c_timezone_ids(1));
   cwms_ts.set_tsid_versioned(l_lrts_ts_id_new, 'T', c_office_id);
   ut.expect(cwms_ts.is_tsid_versioned_f(l_lrts_ts_id_new, c_office_id)).to_equal('T');
   cwms_ts.get_tsid_version_dates(l_crsr, l_lrts_ts_id_new, date '1000-01-01', date '3000-01-01', 'UTC', c_office_id);
   fetch l_crsr bulk collect into l_date_times;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(1);
   ut.expect(cwms_ts.get_ts_interval(l_lrts_ts_id_new)).to_equal(0);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_new)).to_equal('1DayLocal');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_new)).to_equal('~1Day');
   ut.expect(cwms_ts.get_ts_min_date(l_lrts_ts_id_new, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_start_time);
   ut.expect(cwms_ts.get_ts_max_date(l_lrts_ts_id_new, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_end_time);
   cwms_ts.get_value_extents(l_min_value, l_max_value, l_lrts_ts_id_new, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(round(l_min_value, 9)).to_equal(1);
   ut.expect(round(l_max_value, 9)).to_equal(l_ts_data.count);
   l_ts_data_out := cwms_ts.get_values_in_range(l_lrts_ts_id_new, 1, l_ts_data.count, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_ts.set_nulls_storage_policy_ts(cwms_Ts.filter_out_null_values, l_lrts_ts_id_new, c_office_id);
   ut.expect(cwms_ts.get_nulls_storage_policy_ts(l_lrts_ts_id_new, c_office_id)).to_equal(cwms_ts.filter_out_null_values);
   cwms_ts.set_nulls_storage_policy_ts(null, l_lrts_ts_id_new, c_office_id);
   cwms_ts.set_filter_duplicates_ts('T', l_lrts_ts_id_new, c_office_id);
   ut.expect(cwms_ts.get_filter_duplicates(l_lrts_ts_id_new, c_office_id)).to_equal('T');
   cwms_ts.set_historic(l_lrts_ts_id_new, 'T', c_office_id);
   ut.expect(cwms_ts.is_historic(l_lrts_ts_id_new, c_office_id)).to_equal('T');
   --.... group operations
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory',
      p_ts_group_id      => 'TestGroup_new',
      p_shared_ts_ref_id => l_lrts_ts_id_new,
      p_db_office_id     => c_office_id);
   cwms_ts.assign_ts_group('TestCategory', 'TestGroup_new', l_lrts_ts_id_new, 1, null, l_lrts_ts_id_new, c_office_id);
   cwms_ts.unassign_ts_group('TestCategory', 'TestGroup_new', l_lrts_ts_id_new, 'F', c_office_id);
   cwms_ts.assign_ts_groups('TestCategory', 'TestGroup_new', cwms_t_ts_alias_tab(cwms_t_ts_alias(l_lrts_ts_id_new, 1, null, l_lrts_ts_id_new)), c_office_id);
   cwms_ts.unassign_ts_groups('TestCategory', 'TestGroup_new', cwms_t_str_tab(l_lrts_ts_id_new), 'F', c_office_id);
   cwms_ts.delete_ts_group('TestCategory', 'TestGroup_new', c_office_id);
   --.... cwms_cat package
   cwms_cat.cat_ts_aliases(
      p_cwms_cat     => l_crsr,
      p_ts_id        => l_lrts_ts_id_new,
      p_db_office_id => c_office_id);
   close l_crsr;
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => l_lrts_ts_id_new,
      p_db_office_id        => c_office_id);
   close l_crsr;
   --.... cwms_level package
   cwms_level.store_location_level(cwms_t_location_level(
      c_office_id, l_location_id, 'Elev-Lrts', 'Inst', '0', 'Test',
      null, null, null, null, null, null, null, null, null, null, null, null, null, null,
      'T', l_lrts_ts_id_new,
      null, null, null, null, null, null));
   cwms_level.store_location_level3(
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_value       => null,
      p_level_units       => 'ft',
      p_tsid              => l_lrts_ts_id_new,
      p_office_id         => c_office_id);
   l_ts_data_out := cwms_level.retrieve_location_level_values(
      p_ts_id         => l_lrts_ts_id_new,
      p_spec_level_id => 'Test',
      p_level_units   => 'ft',
      p_start_time    => l_start_time,
      p_end_time      => l_end_time,
      p_office_id     => c_office_id);
   l_ts_data_out := cwms_level.retrieve_loc_lvl_values3(
      p_ts_id             => l_lrts_ts_id_new,
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_units       => 'ft',
      p_start_time        => l_start_time,
      p_end_time          => l_end_time,
      p_office_id         => c_office_id);
   cwms_level.store_loc_lvl_indicator(
      p_loc_lvl_indicator_id => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
      p_minimum_duration     => to_dsinterval('000 00:00:01'),
      p_maximum_age          => to_dsinterval('001 00:00:00'),
      p_office_id            => c_office_id);
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id  => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
         p_level_indicator_value => i,
         p_expression            => 'V',
         p_comparison_operator_1 => 'LT',
         p_comparison_value_1    => 2*i,
         p_comparison_unit_id    => 'ft',
         p_office_id             => c_office_id);
   end loop;
   cwms_level.get_level_indicator_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_new,
      p_eval_time            => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   cwms_level.get_level_indicator_max_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_new,
      p_start_time           => l_start_time,
      p_end_time             => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   l_ts_data_out := cwms_level.eval_level_indicator_expr (
      p_tsid               => l_lrts_ts_id_new,
      p_start_time         => l_start_time,
      p_end_time           => l_end_time,
      p_unit               => 'ft',
      p_specified_level_id => 'Test',
      p_indicator_id       => 'VALUE',
      p_condition_number   => 3,
      p_office_id          => c_office_id);
   --.... cwms_forecast package
   l_crsr := cwms_forecast.cat_ts_f(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_cwms_ts_id_mask => l_lrts_ts_id_new,
      p_office_id       => c_office_id);
   close l_crsr;
   cwms_forecast.retrieve_ts(
      p_ts_cursor      => l_crsr,
      p_version_date   => l_version_date,
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_cwms_ts_id     => replace(l_lrts_ts_id_new, '.Test', '.Forecast'),
      p_units          => 'ft',
      p_forecast_time  => l_end_time,
      p_issue_time     => l_start_time,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_time_zone      => c_timezone_ids(1),
      p_office_id      => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
      ut.expect(round(l_values(i), 9)).to_equal(l_ts_data(i).value);
      ut.expect(l_quality_codes(i)).to_equal(l_ts_data(i).quality_code);
   end loop;
   --.... cwms_text package
   select date_time bulk collect into l_date_times from table(l_ts_data);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_new,
      p_std_text_id  => 'A',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_new,
      p_std_text_id  => 'B',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => l_lrts_ts_id_new,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => l_lrts_ts_id_new,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id  => 'C',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id  => 'D',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   cwms_text.delete_ts_std_text(
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_new,
      p_text        => 'Nonstandard text-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_new,
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'First text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-1',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'Second text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-2',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_new,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_new,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => l_lrts_ts_id_new,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => l_lrts_ts_id_new,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_text (
      p_tsid        => l_lrts_ts_id_new,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   begin
      cwms_text.store_ts_text (
         p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
         p_text        => 'Nonstandard text-1',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_TEXT to store text to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_text (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_new,
      p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_new,
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('First binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-1',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('Second binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-2',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_new,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_new,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => l_lrts_ts_id_new,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => l_lrts_ts_id_new,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      --dbms_output.put_line(
      --   l_count
      --   ||chr(9)||l_date_time
      --   ||chr(9)||l_text
      --   ||chr(9)||l_number
      --   ||chr(9)||l_media_type
      --   ||chr(9)||l_file_extension
      --   ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_binary (
      p_tsid             => l_lrts_ts_id_new,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   begin
      cwms_text.store_ts_binary (
         p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
         p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
         p_binary_type => 'bin',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_BINARY to store binary to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_binary (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => 'bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      --dbms_output.put_line(
      --   l_count
      --   ||chr(9)||l_date_time
      --   ||chr(9)||l_text
      --   ||chr(9)||l_number
      --   ||chr(9)||l_media_type
      --   ||chr(9)||l_file_extension
      --   ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Binary'), cwms_util.delete_all, c_office_id);
   --.... cwms_pool package
   cwms_pool.get_elev_offsets(
      p_offsets    => l_ts_data_out,
      p_project_id => l_location_id,
      p_pool_name  => 'Normal',
      p_limit      => 'Top',
      p_unit       => 'ft',
      p_tsid       => l_lrts_ts_id_new,
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_timezone   => 'UTC',
      p_office_id  => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_elev_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ft',
      p_tsid           => l_lrts_ts_id_new,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_elevs(
      p_limit_elevs => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ft',
      p_tsid        => l_lrts_ts_id_new,
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_elevs(
      p_bottom_elevs => l_ts_data_out,
      p_top_elevs    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ft',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_stor_offsets(
      p_offsets     => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ac-ft',
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Stor'),
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_stor_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ac-ft',
      p_tsid           => replace(l_lrts_ts_id_new, 'Elev', 'Stor'),
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_stors(
      p_limit_stors  => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_limit        => 'Top',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_stors(
      p_bottom_stors => l_ts_data_out,
      p_top_stors    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_percent_full(
      p_percent_full => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||round(to_number(l_ts_data_out(i).value), 4));
   -- end loop;
   --.... cwms_alarm package
   cwms_alarm.notify_loc_lvl_ind_state (
      p_ts_id              => l_lrts_ts_id_new,
      p_specified_level_id => 'Test',
      p_level_indicator_id => 'VALUE',
      p_min_state_notify   => 0,
      p_max_state_notify   => 5,
      p_office_id          => c_office_id);
   --.... other packages
   cwms_ts_profile.store_ts_profile(l_location_id, 'Depth-Lrts', 'Depth-Lrts,Temp-Lrts',null, l_lrts_ts_id_new, 'F', 'T', c_office_id);
   cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_old_copy, 'F', 'F', c_office_id);
   cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_new_copy, 'F', 'F', c_office_id);
   cwms_vt.assign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_scr_assign_array    => cwms_t_screen_assign_array(cwms_t_screen_assign(l_lrts_ts_id_new, 'T', replace(l_lrts_ts_id_new, '.Test', '.Rev'))),
      p_db_office_id        => c_office_id);
   cwms_vt.unassign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_cwms_ts_id_array    => cwms_t_ts_id_array(cwms_t_ts_id(l_lrts_ts_id_new)),
      p_db_office_id        => c_office_id);
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_lrts_ts_id_new,
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HP',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                  cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                  1440),
      p_db_office_id        => c_office_id);
   cwms_shef.delete_shef_spec (
      p_cwms_ts_id     => l_lrts_ts_id_new,
      p_data_stream_id => 'Test_Data_Stream',
      p_db_office_id   => c_office_id);
   --.... delete, undelete
   cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_key, c_office_id);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_new);
      l_count := l_count + 1;
   end loop;
   cwms_ts.set_use_new_lrts_format_on_output('F');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      l_count := l_count + 1;
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_old);
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.undelete_ts(l_lrts_ts_id_new, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_new_copy, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Stor'), cwms_util.delete_all, c_office_id);

   ---------------------------
   -- reqiure new LRTS IDs --
   --------------------------
   cwms_loc.clear_all_caches;
   cwms_ts.clear_all_caches;
   cwms_ts.set_require_new_lrts_format_on_input('T');
   -- should fail
   --.... create, update, store ts
   begin
      cwms_ts.create_ts(
         p_cwms_ts_id => l_lrts_ts_id_old,
         p_utc_offset => 0,
         p_versioned  => 'F',
         p_office_id  => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+ERROR: Session requires new LRTS ID format.+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.update_ts_id(
         p_cwms_ts_id          => l_lrts_ts_id_old,
         p_interval_utc_offset => 420,
         p_db_office_id        => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_lrts_ts_id_old,
         p_units           => 'ft',
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_office_id       => c_office_id,
         p_create_as_lrts  => 'T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+ERROR: Session requires new LRTS ID format.+', 'mn')).to_be_true;
   end;
   --.... retrieve ts
   begin
      cwms_ts.retrieve_ts(
         p_at_tsv_rc  => l_crsr,
         p_cwms_ts_id => l_lrts_ts_id_old,
         p_units      => 'ft',
         p_start_time => l_start_time,
         p_end_time   => l_end_time,
         p_office_id  => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... rename_ts
   begin
      cwms_ts.rename_ts(l_lrts_ts_id_old, l_lrts_ts_id_old||'2', null, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... get IDs and codes
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_old, c_office_id)).to_be_null;
   begin
      ut.expect(cwms_ts.get_ts_code(l_lrts_ts_id_old, c_office_id)).to_be_null;
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   ut.expect(cwms_ts.get_db_unit_id(l_lrts_ts_id_old)).to_equal('m');
   begin
      ut.expect(cwms_ts.get_location_id(l_lrts_ts_id_old, c_office_id)).to_equal(l_location_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... get/set info
   begin
      ut.expect(cwms_ts.get_tsid_time_zone(l_lrts_ts_id_old, c_office_id)).to_equal(c_timezone_ids(1));
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_tsid_versioned(l_lrts_ts_id_old, 'T', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.is_tsid_versioned_f(l_lrts_ts_id_old, c_office_id)).to_equal('T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.get_tsid_version_dates(l_crsr, l_lrts_ts_id_old, date '1000-01-01', date '3000-01-01', 'UTC', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   ut.expect(cwms_ts.get_ts_interval(l_lrts_ts_id_old)).to_equal(0);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_old)).to_equal('1DayLocal');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_old)).to_equal('~1Day');
   begin
      ut.expect(cwms_ts.get_ts_min_date(l_lrts_ts_id_old, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_start_time);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.get_ts_max_date(l_lrts_ts_id_old, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_end_time);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.get_value_extents(l_min_value, l_max_value, l_lrts_ts_id_old, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      l_ts_data_out := cwms_ts.get_values_in_range(l_lrts_ts_id_old, 1, l_count, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_nulls_storage_policy_ts(cwms_Ts.filter_out_null_values, l_lrts_ts_id_old, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.get_nulls_storage_policy_ts(l_lrts_ts_id_old, c_office_id)).to_equal(cwms_ts.filter_out_null_values);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_filter_duplicates_ts('T', l_lrts_ts_id_old, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.get_filter_duplicates(l_lrts_ts_id_old, c_office_id)).to_equal('T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.set_historic(l_lrts_ts_id_old, 'T', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      ut.expect(cwms_ts.is_historic(l_lrts_ts_id_old, c_office_id)).to_equal('T');
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... group operations
   begin
      cwms_ts.store_ts_group(
         p_ts_category_id   => 'TestCategory',
         p_ts_group_id      => 'TestGroup_old',
         p_shared_ts_ref_id => l_lrts_ts_id_old,
         p_db_office_id     => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory',
      p_ts_group_id      => 'TestGroup_old',
      p_db_office_id     => c_office_id);
   begin
      cwms_ts.assign_ts_group('TestCategory', 'TestGroup_old', l_lrts_ts_id_old, 1, null, l_lrts_ts_id_old, c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.unassign_ts_group('TestCategory', 'TestGroup_old', l_lrts_ts_id_old, 'F', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.assign_ts_groups('TestCategory', 'TestGroup_old', cwms_t_ts_alias_tab(cwms_t_ts_alias(l_lrts_ts_id_old, 1, null, l_lrts_ts_id_old)), c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_ts.unassign_ts_groups('TestCategory', 'TestGroup_old', cwms_t_str_tab(l_lrts_ts_id_old), 'F', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   cwms_ts.delete_ts_group('TestCategory', 'TestGroup_old', c_office_id);
   --.... cwms_cat package
   cwms_cat.cat_ts_aliases(
      p_cwms_cat     => l_crsr,
      p_ts_id        => l_lrts_ts_id_old,
      p_db_office_id => c_office_id);
   close l_crsr;
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => l_lrts_ts_id_old,
      p_db_office_id        => c_office_id);
   close l_crsr;
   --.... cwms_level package
   begin
      cwms_level.store_location_level(cwms_t_location_level(
         c_office_id, l_location_id, 'Elev-Lrts', 'Inst', '0', 'Test',
         null, null, null, null, null, null, null, null, null, null, null, null, null, null,
         'T', l_lrts_ts_id_old,
         null, null, null, null, null, null));
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_level.store_location_level3(
         p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
         p_level_value       => null,
         p_level_units       => 'ft',
         p_tsid              => l_lrts_ts_id_old,
         p_office_id         => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... cwms_forecast package
   l_crsr := cwms_forecast.cat_ts_f(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_cwms_ts_id_mask => l_lrts_ts_id_old,
      p_office_id       => c_office_id);
   cwms_forecast.retrieve_ts(
      p_ts_cursor      => l_crsr,
      p_version_date   => l_version_date,
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_cwms_ts_id     => replace(l_lrts_ts_id_old, '.Test', '.Forecast'), -- doesn't fail; not required to be LRTS
      p_units          => 'ft',
      p_forecast_time  => l_end_time,
      p_issue_time     => l_start_time,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_time_zone      => c_timezone_ids(1),
      p_office_id      => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
      ut.expect(round(l_values(i), 9)).to_equal(l_ts_data(i).value);
      ut.expect(l_quality_codes(i)).to_equal(l_ts_data(i).quality_code);
   end loop;
   --.... cwms_pool package
   begin
      cwms_pool.get_elev_offsets(
         p_offsets    => l_ts_data_out,
         p_project_id => l_location_id,
         p_pool_name  => 'Normal',
         p_limit      => 'Top',
         p_unit       => 'ft',
         p_tsid       => l_lrts_ts_id_old,
         p_start_time => l_start_time,
         p_end_time   => l_end_time,
         p_timezone   => 'UTC',
         p_office_id  => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_pool.get_elev_offsets(
         p_bottom_offsets => l_ts_data_out,
         p_top_offsets    => l_ts_data_out2,
         p_project_id     => l_location_id,
         p_pool_name      => 'Normal',
         p_unit           => 'ft',
         p_tsid           => l_lrts_ts_id_old,
         p_start_time     => l_start_time,
         p_end_time       => l_end_time,
         p_timezone       => 'UTC',
         p_office_id      => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_pool.get_pool_limit_elevs(
         p_limit_elevs => l_ts_data_out,
         p_project_id  => l_location_id,
         p_pool_name   => 'Normal',
         p_limit       => 'Top',
         p_unit        => 'ft',
         p_tsid        => l_lrts_ts_id_old,
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_timezone    => 'UTC',
         p_office_id   => c_office_id);
      ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_pool.get_pool_limit_elevs(
         p_bottom_elevs => l_ts_data_out,
         p_top_elevs    => l_ts_data_out2,
         p_project_id   => l_location_id,
         p_pool_name    => 'Normal',
         p_unit         => 'ft',
         p_tsid         => l_lrts_ts_id_old,
         p_start_time   => l_start_time,
         p_end_time     => l_end_time,
         p_timezone     => 'UTC',
         p_office_id    => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   --.... other packages
   begin
      cwms_ts_profile.store_ts_profile(l_location_id, 'Depth-Lrts', 'Depth-Lrts,Temp-Lrts',null, l_lrts_ts_id_old, 'F', 'T', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+TS_ID_NOT_FOUND: .+', 'mn')).to_be_true;
   end;
   begin
      cwms_vt.assign_screening_id (
         p_screening_id        => 'Elev Range 1',
         p_scr_assign_array    => cwms_t_screen_assign_array(cwms_t_screen_assign(l_lrts_ts_id_old, 'T', replace(l_lrts_ts_id_old, '.Test', '.Rev'))),
         p_db_office_id        => c_office_id);
   exception
      when no_data_found then null;
   end;
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_lrts_ts_id_old, -- doesn't fail; created as PRTS
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HP',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                  cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                  1440),
      p_db_office_id        => c_office_id);
   cwms_shef.delete_shef_spec (
      p_cwms_ts_id     => l_lrts_ts_id_old,
      p_data_stream_id => 'Test_Data_Stream',
      p_db_office_id   => c_office_id);
   --.... delete, undelete
   cwms_ts.delete_ts(l_lrts_ts_id_old, cwms_util.delete_all, c_office_id); -- doesn't fail, created by store_shef_spec
   -- should succeed
   --.... create, update, store ts
   cwms_ts.create_ts(
      p_cwms_ts_id => l_lrts_ts_id_new,
      p_utc_offset => 0,
      p_versioned  => 'F',
      p_office_id  => c_office_id);
   cwms_ts.update_ts_id(
      p_cwms_ts_id          => l_lrts_ts_id_new,
      p_interval_utc_offset => 420,
      p_db_office_id        => c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_all, c_office_id);
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_new,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_lrts_ts_id_new_copy,
      p_units           => 'ft',
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => replace(l_lrts_ts_id_new, 'Elev', 'Stor'),
      p_units           => 'ac-ft',
      p_timeseries_data => l_ts_data2,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'T');
   --.... retrieve ts
   cwms_ts.retrieve_ts(
      p_at_tsv_rc  => l_crsr,
      p_cwms_ts_id => l_lrts_ts_id_new,
      p_units      => 'ft',
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_office_id  => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   --.... rename_ts
   cwms_ts.rename_ts(l_lrts_ts_id_new, l_lrts_ts_id_new||'2', null, c_office_id);
   cwms_ts.rename_ts(l_lrts_ts_id_new||'2', l_lrts_ts_id_new, null, c_office_id);
   --.... get IDs and codes
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_lrts_ts_id_new);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_lrts_ts_id_old);
   ut.expect(cwms_ts.get_ts_code(l_lrts_ts_id_new, c_office_id)).to_be_not_null;
   ut.expect(cwms_ts.get_db_unit_id(l_lrts_ts_id_new)).to_equal('m');
   ut.expect(cwms_ts.get_location_id(l_lrts_ts_id_new, c_office_id)).to_equal(l_location_id);
   --.... get/set info
   ut.expect(cwms_ts.get_tsid_time_zone(l_lrts_ts_id_new, c_office_id)).to_equal(c_timezone_ids(1));
   cwms_ts.set_tsid_versioned(l_lrts_ts_id_new, 'T', c_office_id);
   ut.expect(cwms_ts.is_tsid_versioned_f(l_lrts_ts_id_new, c_office_id)).to_equal('T');
   cwms_ts.get_tsid_version_dates(l_crsr, l_lrts_ts_id_new, date '1000-01-01', date '3000-01-01', 'UTC', c_office_id);
   fetch l_crsr bulk collect into l_date_times;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(1);
   ut.expect(cwms_ts.get_ts_interval(l_lrts_ts_id_new)).to_equal(0);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_new)).to_equal('1DayLocal');
   cwms_ts.set_use_new_lrts_format_on_output('F');
   ut.expect(cwms_ts.get_ts_interval_string(l_lrts_ts_id_new)).to_equal('~1Day');
   ut.expect(cwms_ts.get_ts_min_date(l_lrts_ts_id_new, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_start_time);
   ut.expect(cwms_ts.get_ts_max_date(l_lrts_ts_id_new, 'UTC', cwms_util.non_versioned, c_office_id)).to_equal(l_end_time);
   cwms_ts.get_value_extents(l_min_value, l_max_value, l_lrts_ts_id_new, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(round(l_min_value, 9)).to_equal(1);
   ut.expect(round(l_max_value, 9)).to_equal(l_ts_data.count);
   l_ts_data_out := cwms_ts.get_values_in_range(l_lrts_ts_id_new, 1, l_count, 'ft', l_start_time, l_end_time, 'UTC', c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_count);
   cwms_ts.set_nulls_storage_policy_ts(cwms_Ts.filter_out_null_values, l_lrts_ts_id_new, c_office_id);
   ut.expect(cwms_ts.get_nulls_storage_policy_ts(l_lrts_ts_id_new, c_office_id)).to_equal(cwms_ts.filter_out_null_values);
   cwms_ts.set_nulls_storage_policy_ts(null, l_lrts_ts_id_new, c_office_id);
   cwms_ts.set_filter_duplicates_ts('T', l_lrts_ts_id_new, c_office_id);
   ut.expect(cwms_ts.get_filter_duplicates(l_lrts_ts_id_new, c_office_id)).to_equal('T');
   cwms_ts.set_historic(l_lrts_ts_id_new, 'T', c_office_id);
   ut.expect(cwms_ts.is_historic(l_lrts_ts_id_new, c_office_id)).to_equal('T');
   --.... group operations
   cwms_ts.store_ts_group(
      p_ts_category_id   => 'TestCategory',
      p_ts_group_id      => 'TestGroup_new',
      p_shared_ts_ref_id => l_lrts_ts_id_new,
      p_db_office_id     => c_office_id);
   cwms_ts.assign_ts_group('TestCategory', 'TestGroup_new', l_lrts_ts_id_new, 1, null, l_lrts_ts_id_new, c_office_id);
   cwms_ts.unassign_ts_group('TestCategory', 'TestGroup_new', l_lrts_ts_id_new, 'F', c_office_id);
   cwms_ts.assign_ts_groups('TestCategory', 'TestGroup_new', cwms_t_ts_alias_tab(cwms_t_ts_alias(l_lrts_ts_id_new, 1, null, l_lrts_ts_id_new)), c_office_id);
   cwms_ts.unassign_ts_groups('TestCategory', 'TestGroup_new', cwms_t_str_tab(l_lrts_ts_id_new), 'F', c_office_id);
   cwms_ts.delete_ts_group('TestCategory', 'TestGroup_new', c_office_id);
   --.... cwms_cat package
   cwms_cat.cat_ts_aliases(
      p_cwms_cat     => l_crsr,
      p_ts_id        => l_lrts_ts_id_new,
      p_db_office_id => c_office_id);
   close l_crsr;
   cwms_cat.cat_ts_id(
      p_cwms_cat            => l_crsr,
      p_ts_subselect_string => l_lrts_ts_id_new,
      p_db_office_id        => c_office_id);
   close l_crsr;
   --.... cwms_level package
   cwms_level.store_location_level(cwms_t_location_level(
      c_office_id, l_location_id, 'Elev-Lrts', 'Inst', '0', 'Test',
      null, null, null, null, null, null, null, null, null, null, null, null, null, null,
      'T', l_lrts_ts_id_old,
      null, null, null, null, null, null));
   cwms_level.store_location_level3(
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_value       => null,
      p_level_units       => 'ft',
      p_tsid              => l_lrts_ts_id_new,
      p_office_id         => c_office_id);
   l_ts_data_out := cwms_level.retrieve_location_level_values(
      p_ts_id         => l_lrts_ts_id_new,
      p_spec_level_id => 'Test',
      p_level_units   => 'ft',
      p_start_time    => l_start_time,
      p_end_time      => l_end_time,
      p_office_id     => c_office_id);
   l_ts_data_out := cwms_level.retrieve_loc_lvl_values3(
      p_ts_id             => l_lrts_ts_id_new,
      p_location_level_id => l_location_id||'.Elev-Lrts.Inst.0.Test',
      p_level_units       => 'ft',
      p_start_time        => l_start_time,
      p_end_time          => l_end_time,
      p_office_id         => c_office_id);
   cwms_level.store_loc_lvl_indicator(
      p_loc_lvl_indicator_id => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
      p_minimum_duration     => to_dsinterval('000 00:00:01'),
      p_maximum_age          => to_dsinterval('001 00:00:00'),
      p_office_id            => c_office_id);
   for i in 1..5 loop
      cwms_level.store_loc_lvl_indicator_cond(
         p_loc_lvl_indicator_id  => l_location_id||'.Elev-Lrts.Inst.0.Test.VALUE',
         p_level_indicator_value => i,
         p_expression            => 'V',
         p_comparison_operator_1 => 'LT',
         p_comparison_value_1    => 2*i,
         p_comparison_unit_id    => 'ft',
         p_office_id             => c_office_id);
   end loop;
   cwms_level.get_level_indicator_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_new,
      p_eval_time            => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   cwms_level.get_level_indicator_max_values (
      p_cursor               => l_crsr,
      p_tsid                 => l_lrts_ts_id_new,
      p_start_time           => l_start_time,
      p_end_time             => l_end_time,
      p_time_zone            => 'UTC',
      p_specified_level_mask => 'Test',
      p_indicator_id_mask    => 'VALUE',
      p_unit_system          => 'EN',
      p_office_id            => c_office_id);
   close l_crsr;
   l_ts_data_out := cwms_level.eval_level_indicator_expr (
      p_tsid               => l_lrts_ts_id_new,
      p_start_time         => l_start_time,
      p_end_time           => l_end_time,
      p_unit               => 'ft',
      p_specified_level_id => 'Test',
      p_indicator_id       => 'VALUE',
      p_condition_number   => 3,
      p_office_id          => c_office_id);
   --.... cwms_forecast package
   l_crsr := cwms_forecast.cat_ts_f(
      p_location_id     => l_location_id,
      p_forecast_id     => 'TEST',
      p_cwms_ts_id_mask => l_lrts_ts_id_new,
      p_office_id       => c_office_id);
   close l_crsr;
   cwms_forecast.retrieve_ts(
      p_ts_cursor      => l_crsr,
      p_version_date   => l_version_date,
      p_location_id    => l_location_id,
      p_forecast_id    => 'TEST',
      p_cwms_ts_id     => replace(l_lrts_ts_id_new, '.Test', '.Forecast'),
      p_units          => 'ft',
      p_forecast_time  => l_end_time,
      p_issue_time     => l_start_time,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_time_zone      => c_timezone_ids(1),
      p_office_id      => c_office_id);
   fetch l_crsr
    bulk collect
    into l_date_times,
         l_values,
         l_quality_codes;
   close l_crsr;
   ut.expect(l_date_times.count).to_equal(l_ts_data.count);
   for i in 1..l_date_times.count loop
      ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
      ut.expect(round(l_values(i), 9)).to_equal(l_ts_data(i).value);
      ut.expect(l_quality_codes(i)).to_equal(l_ts_data(i).quality_code);
   end loop;
   --.... cwms_text package
   select date_time bulk collect into l_date_times from table(l_ts_data);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_new,
      p_std_text_id  => 'A',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => l_lrts_ts_id_new,
      p_std_text_id  => 'B',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => l_lrts_ts_id_new,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => l_lrts_ts_id_new,
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id  => 'C',
      p_times        => l_date_times,
      p_time_zone    => 'UTC',
      p_attribute    => 1,
      p_office_id    => c_office_id);
   cwms_text.store_ts_std_text(
      p_tsid         => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id  => 'D',
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_time_zone    => 'UTC',
      p_attribute    => 2,
      p_office_id    => c_office_id);
   l_number := cwms_text.get_ts_std_text_count(
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 2);
   l_crsr := cwms_text.retrieve_ts_std_text_f (
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 2);
   cwms_text.delete_ts_std_text(
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_std_text_id_mask => '*',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_new,
      p_text        => 'Nonstandard text-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text (
      p_tsid        => l_lrts_ts_id_new,
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'First text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-1',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   l_number := cwms_text.store_text(
      p_text           => 'Second text in AT_CLOB table',
      p_id             => '/TEST/STORE_TS_TEXT_ID-2',
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_new,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => l_lrts_ts_id_new,
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => l_lrts_ts_id_new,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => l_lrts_ts_id_new,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_text (
      p_tsid        => l_lrts_ts_id_new,
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   begin
      cwms_text.store_ts_text (
         p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
         p_text        => 'Nonstandard text-1',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_TEXT to store text to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_text (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text        => 'Nonstandard text-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_text_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_id     => '/TEST/STORE_TS_TEXT_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_text_count(
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_text_f (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Text'),
      p_text_mask   => '*',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_office_id   => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_clob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Text'), cwms_util.delete_all, c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_new,
      p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 1,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary (
      p_tsid        => l_lrts_ts_id_new,
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => '.bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('First binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-1',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_binary(
      p_binary_code       => l_number,
      p_binary            => utl_i18n.string_to_raw('Second binary in AT_BLOB table', 'AL32UTF8'),
      p_id                => '/TEST/STORE_TS_BINARY_ID-2',
      p_media_type_or_ext => '.bin',
      p_fail_if_exists    => 'F',
      p_office_id         => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_new,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => l_lrts_ts_id_new,
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => l_lrts_ts_id_new,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 4);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => l_lrts_ts_id_new,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      --dbms_output.put_line(
      --   l_count
      --   ||chr(9)||l_date_time
      --   ||chr(9)||l_text
      --   ||chr(9)||l_number
      --   ||chr(9)||l_media_type
      --   ||chr(9)||l_file_extension
      --   ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 4);
   cwms_text.delete_ts_binary (
      p_tsid             => l_lrts_ts_id_new,
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   begin
      cwms_text.store_ts_binary (
         p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
         p_binary      => utl_i18n.string_to_raw('Some binary-1', 'AL32UTF8'),
         p_binary_type => 'bin',
         p_start_time  => l_start_time,
         p_end_time    => l_end_time,
         p_time_zone   => 'UTC',
         p_attribute   => 1,
         p_office_id   => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(
            dbms_utility.format_error_stack,
            '.+Cannot use this version of STORE_TS_BINARY to store binary to a non-existent irregular time series.+',
            'mn')).to_be_true;
   end;
   cwms_text.store_ts_binary (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary      => utl_i18n.string_to_raw('Some binary-2', 'AL32UTF8'),
      p_binary_type => 'bin',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 2,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-1',
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_time_zone   => 'UTC',
      p_attribute   => 3,
      p_office_id   => c_office_id);
   cwms_text.store_ts_binary_id (
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_id   => '/TEST/STORE_TS_BINARY_ID-2',
      p_times       =>  l_date_times,
      p_time_zone   => 'UTC',
      p_attribute   => 4,
      p_office_id   => c_office_id);
   l_number := cwms_text.get_ts_binary_count(
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   ut.expect(l_number).to_equal(l_ts_data.count * 3);
   l_crsr := cwms_text.retrieve_ts_binary_f (
      p_tsid             => replace(l_lrts_ts_id_new, 'Elev', 'Binary'),
      p_binary_type_mask => 'bin',
      p_start_time       => l_start_time,
      p_end_time         => l_end_time,
      p_time_zone        => 'UTC',
      p_office_id        => c_office_id);
   l_count := 0;
   loop
      fetch l_crsr
       into l_date_time,
            l_version_date,
            l_data_entry_date,
            l_text,
            l_number,
            l_file_extension,
            l_media_type,
            l_blob;
      exit when l_crsr%notfound;
      l_count := l_count + 1;
      --dbms_output.put_line(
      --   l_count
      --   ||chr(9)||l_date_time
      --   ||chr(9)||l_text
      --   ||chr(9)||l_number
      --   ||chr(9)||l_media_type
      --   ||chr(9)||l_file_extension
      --   ||chr(9)||utl_i18n.raw_to_char(l_blob));
   end loop;
   close l_crsr;
   ut.expect(l_count).to_equal(l_ts_data.count * 3);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Binary'), cwms_util.delete_all, c_office_id);
   --.... cwms_pool package
   cwms_pool.get_elev_offsets(
      p_offsets    => l_ts_data_out,
      p_project_id => l_location_id,
      p_pool_name  => 'Normal',
      p_limit      => 'Top',
      p_unit       => 'ft',
      p_tsid       => l_lrts_ts_id_new,
      p_start_time => l_start_time,
      p_end_time   => l_end_time,
      p_timezone   => 'UTC',
      p_office_id  => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_elev_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ft',
      p_tsid           => l_lrts_ts_id_new,
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_elevs(
      p_limit_elevs => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ft',
      p_tsid        => l_lrts_ts_id_new,
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_elevs(
      p_bottom_elevs => l_ts_data_out,
      p_top_elevs    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ft',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_stor_offsets(
      p_offsets     => l_ts_data_out,
      p_project_id  => l_location_id,
      p_pool_name   => 'Normal',
      p_limit       => 'Top',
      p_unit        => 'ac-ft',
      p_tsid        => replace(l_lrts_ts_id_new, 'Elev', 'Stor'),
      p_start_time  => l_start_time,
      p_end_time    => l_end_time,
      p_timezone    => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id   => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_stor_offsets(
      p_bottom_offsets => l_ts_data_out,
      p_top_offsets    => l_ts_data_out2,
      p_project_id     => l_location_id,
      p_pool_name      => 'Normal',
      p_unit           => 'ac-ft',
      p_tsid           => replace(l_lrts_ts_id_new, 'Elev', 'Stor'),
      p_start_time     => l_start_time,
      p_end_time       => l_end_time,
      p_timezone       => 'UTC',
      p_rating_spec => l_rating_spec,
      p_office_id      => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_pool_limit_stors(
      p_limit_stors  => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_limit        => 'Top',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   cwms_pool.get_pool_limit_stors(
      p_bottom_stors => l_ts_data_out,
      p_top_stors    => l_ts_data_out2,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_unit         => 'ac-ft',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   ut.expect(l_ts_data_out2.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||to_number(l_ts_data_out(i).value)||chr(9)||to_number(l_ts_data_out2(i).value));
   -- end loop;
   cwms_pool.get_percent_full(
      p_percent_full => l_ts_data_out,
      p_project_id   => l_location_id,
      p_pool_name    => 'Normal',
      p_tsid         => l_lrts_ts_id_new,
      p_start_time   => l_start_time,
      p_end_time     => l_end_time,
      p_timezone     => 'UTC',
      p_rating_spec  => l_rating_spec,
      p_office_id    => c_office_id);
   ut.expect(l_ts_data_out.count).to_equal(l_ts_data.count);
   -- for i in 1..l_ts_data_out.count loop
   --    dbms_output.put_line(i||chr(9)||l_ts_data_out(i).date_time||chr(9)||round(to_number(l_ts_data_out(i).value), 4));
   -- end loop;
   --.... cwms_alarm package
   cwms_alarm.notify_loc_lvl_ind_state (
      p_ts_id              => l_lrts_ts_id_new,
      p_specified_level_id => 'Test',
      p_level_indicator_id => 'VALUE',
      p_min_state_notify   => 0,
      p_max_state_notify   => 5,
      p_office_id          => c_office_id);
   --.... other packages
   cwms_ts_profile.store_ts_profile(l_location_id, 'Depth-Lrts', 'Depth-Lrts,Temp-Lrts',null, l_lrts_ts_id_new, 'F', 'T', c_office_id);
   begin
      cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_old_copy, 'F', 'F', c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, '.+ERROR: Session requires new LRTS ID format.+', 'mn')).to_be_true;
   end;
   cwms_ts_profile.copy_ts_profile(l_location_id, 'Depth-Lrts', l_location_id_copy, l_lrts_ts_id_new_copy, 'F', 'F', c_office_id);
   cwms_vt.assign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_scr_assign_array    => cwms_t_screen_assign_array(cwms_t_screen_assign(l_lrts_ts_id_new, 'T', replace(l_lrts_ts_id_new, '.Test', '.Rev'))),
      p_db_office_id        => c_office_id);
   cwms_vt.unassign_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_cwms_ts_id_array    => cwms_t_ts_id_array(cwms_t_ts_id(l_lrts_ts_id_new)),
      p_db_office_id        => c_office_id);
   cwms_shef.store_shef_spec (
      p_cwms_ts_id          => l_lrts_ts_id_new,
      p_data_stream_id      => 'Test_Data_Stream',
      p_shef_loc_id         => 'SHEFO2',
      p_shef_pe_code        => 'HP',
      p_shef_tse_code       => 'RGZ',
      p_shef_duration_code  => 'I',
      p_shef_unit_id        => 'ft',
      p_time_zone_id        => 'UTC',
      p_interval_utc_offset => cwms_ts.get_utc_interval_offset(
                                  cwms_util.change_timezone(l_ts_data(1).date_time, 'UTC', c_timezone_ids(1)),
                                  1440),
      p_db_office_id        => c_office_id);
   cwms_shef.delete_shef_spec (
      p_cwms_ts_id     => l_lrts_ts_id_new,
      p_data_stream_id => 'Test_Data_Stream',
      p_db_office_id   => c_office_id);
   --.... delete, undelete
   cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_key, c_office_id);
   cwms_ts.set_use_new_lrts_format_on_output('T');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_new);
      l_count := l_count + 1;
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.set_use_new_lrts_format_on_output('F');
   l_count := 0;
   for rec in (select * from cwms_v_deleted_ts_id where location_id = l_location_id) loop
      ut.expect(rec.cwms_ts_id).to_equal(l_lrts_ts_id_old);
      l_count := l_count + 1;
   end loop;
   ut.expect(l_count).to_be_greater_than(0);
   cwms_ts.undelete_ts(l_lrts_ts_id_new, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_new, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(l_lrts_ts_id_new_copy, cwms_util.delete_all, c_office_id);
   cwms_ts.delete_ts(replace(l_lrts_ts_id_new, 'Elev', 'Stor'), cwms_util.delete_all, c_office_id);

   cwms_ts.set_allow_new_lrts_format_on_input('F');
   cwms_ts.set_use_new_lrts_format_on_output('F');

   cwms_vt.delete_screening_id (
      p_screening_id        => 'Elev Range 1',
      p_parameter_id        => 'Elev',
      p_parameter_type_id   => null,
      p_duration_id         => null,
      p_cascade             => 'T',
      p_db_office_id        => 'SWT');
   cwms_loc.delete_location(l_location_id, cwms_util.delete_all, c_office_id);

end test_lrts_id_input_formatting;

end test_lrts_updates;
/
show errors
grant execute on test_lrts_updates to cwms_user;
