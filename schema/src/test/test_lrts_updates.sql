drop package test_lrts_updates;
set verify off
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
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   l_ts_codes number_tab_t;
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
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
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup( -- (sets up LRTS without using routines under test)
   p_options in varchar2 default null)
is
   l_ts_values_loc   ztsv_array_tab := ztsv_array_tab();
   l_empty_ts_values ztsv_array     := ztsv_array();
   l_cwms_ts_id      av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id      av_cwms_ts_id.cwms_ts_id%type;
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
   l_time_zone_id av_cwms_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   av_cwms_ts_id.cwms_ts_id%type;
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
   l_time_zone_id av_cwms_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   av_cwms_ts_id.cwms_ts_id%type;
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
                 from av_cwms_ts_id
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
   l_time_zone_id av_cwms_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   av_cwms_ts_id.cwms_ts_id%type;
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
                 from av_cwms_ts_id2
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
   l_time_zone_id av_cwms_ts_id.cwms_ts_id%type;
   l_cwms_ts_id   av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id_in       av_cwms_ts_id.cwms_ts_id%type;
   l_interval_utc_offset number;
   l_timezone_id         av_cwms_ts_id.cwms_ts_id%type;
   l_ts_active_flag      varchar2(1);
   l_user_privileges     number;
   l_cwms_ts_id_out      av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id_in    av_cwms_ts_id.cwms_ts_id%type;
   l_cwms_ts_id_out   av_cwms_ts_id.cwms_ts_id%type;
   l_units_out        av_cwms_ts_id.unit_id%type;
   l_time_zone_id_in  av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_out av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id       av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_out av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id       av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_out av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id       av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_out av_cwms_ts_id.cwms_ts_id%type;
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
   l_cwms_ts_id       av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_out av_cwms_ts_id.cwms_ts_id%type;
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
   l_units_out        av_cwms_ts_id.unit_id%type;
   l_cwms_ts_id_in    av_cwms_ts_id.cwms_ts_id%type;
   l_cwms_ts_id_out   av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_in  av_cwms_ts_id.cwms_ts_id%type;
   l_time_zone_id_out av_cwms_ts_id.cwms_ts_id%type;
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
   l_time_zone              av_cwms_ts_id.cwms_ts_id%type := 'UTC';
   l_ts_request             timeseries_req_array := timeseries_req_array();
   l_cwms_ts_ids            str_tab_t := str_tab_t();
   l_timezone_ids           str_tab_t := str_tab_t();
   l_start_times            date_table_type := date_table_type();
   l_sequence_out           integer;
   l_cwms_ts_id_out         av_cwms_ts_id.cwms_ts_id%type;
   l_unit_out               av_cwms_ts_id.unit_id%type;
   l_location_time_zone_out av_cwms_ts_id.time_zone_id%type;
   l_start_time_out         date;
   l_end_time_out           date;
   l_time_zone_out          av_cwms_ts_id.time_zone_id%type;
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
    l_time_zone              av_cwms_ts_id.cwms_ts_id%type := 'UTC';
    l_ts_values  tsv_array := tsv_array();
    l_ts_request             timeseries_req_array := timeseries_req_array();
    l_cwms_ts_ids            str_tab_t := str_tab_t();
    l_timezone_ids           str_tab_t := str_tab_t();
    l_sequence_out           integer;
    l_cwms_ts_id_out         av_cwms_ts_id.cwms_ts_id%type;
    l_unit_out               av_cwms_ts_id.unit_id%type;
    l_location_time_zone_out av_cwms_ts_id.time_zone_id%type;
    l_start_time_out         date;
    l_end_time_out           date;
    l_time_zone_out          av_cwms_ts_id.time_zone_id%type;
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
   l_cwms_ts_id  av_cwms_ts_id.cwms_ts_id%type;
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
     from av_tsv_dqu
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
     from av_tsv_dqu
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
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
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
     from av_tsv_dqu
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
     from av_tsv_dqu
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
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
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
     from av_tsv_dqu
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
     from av_tsv_dqu
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
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
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
     from av_tsv_dqu
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
     from av_tsv_dqu
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
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
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
     from av_tsv_dqu
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
     from av_tsv_dqu
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
        from av_tsv_dqu
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
        from av_tsv_dqu
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
        from av_tsv_dqu
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
        from av_tsv_dqu
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
        from av_tsv_dqu
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
        from av_tsv_dqu
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

end test_lrts_updates;
/
show errors
grant execute on test_lrts_updates to cwms_user;
