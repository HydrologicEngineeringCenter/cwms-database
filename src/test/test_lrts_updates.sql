create or replace package test_lrts_updates as

--%suite(Test schema for full LRTS compatibility)

--%rollback(manual)
--# %beforeall(setup)
--# %afterall(teardown)

--%test(CREATE_TS_CODE with zero offset without time zone)
--%disabled
procedure create_ts_code_no_tz1;
--%test(CREATE_TS_CODE with non-zero offset without time zone)
--%disabled
procedure create_ts_code_no_tz2;
--%test(CREATE_TS_CODE with with negative offset)
--%disabled
procedure create_lrts_ts_code_neg_offset;
--%test(CREATE_TS_CODE with with positive offset)
--%disabled
procedure create_lrts_ts_code_pos_offset;
--%test(UPDATE_TS_CODE with with negative offset)
--%disabled
procedure update_lrts_ts_code_neg_offset;
--%test(UPDATE_TS_CODE with with positive offset)
--%disabled
procedure update_lrts_ts_code_pos_offset;
--%test(Time zone in AT_CWMS_TS_SPEC table)
--%disabled
procedure tz_in_at_cwms_ts_spec;
--%test(Time zone in AT_CWMS_TS_ID table)
--%disabled
procedure tz_in_at_cwms_ts_id;
--%test(Time zone in AV_CWMS_TS_ID view)
--%disabled
procedure tz_in_av_cwms_ts_id;
--%test(Time zone in AV_CWMS_TS_ID2 view)
--%disabled
procedure tz_in_av_cwms_ts_id2;
--%test(Time zone in ZAV_CWMS_TS_ID view)
--%disabled
procedure tz_in_zav_cwms_ts_id;
--%test(Time zone in cwms_cat.cat_ts_id)
--%disabled
procedure tz_in_catalog;
--%test(RETRIEVE_TS_OUT overload)
--%disabled
procedure retrieve_ts_out;
--%test(RETRIEVE_TS [1.4] overload)
--%disabled
procedure retrieve_ts_old;
--%test(RETRIEVE_TS_2 [1.4] overload)
--%disabled
procedure retrieve_ts_2_old;
--%test(RETRIEVE_TS [2.0] overload)
--%disabled
procedure retrieve_ts;
--%test(ZRETRIEVE_TS overload)
--%disabled
procedure zretrieve_ts;
--%test(ZRETRIEVE_TS_JAVA overload)
--%disabled
procedure zretrieve_ts_java;
--%test(RETRIEVE_TS_MULTI)
--%disabled
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

procedure setup(p_options in varchar2 default null);
procedure teardown;
c_office_id     constant varchar2(3)  := '&office_id';
c_location_ids  constant str_tab_t    := str_tab_t('TestLoc1', 'TestLoc1-WithSub', 'TestLoc2');
c_timezone_ids  constant str_tab_t    := str_tab_t('US/Central', null, 'CST');
c_intvl_offsets constant number_tab_t := number_tab_t(0, 10, 20);
c_ts_id_part    constant varchar2(25) := '.Code.Inst.<intvl>.0.Test';
c_intervals     constant str_tab_t    := str_tab_t('0', '~1Hour', '1Hour');
c_ts_unit       constant varchar2(3)  := 'n/a';
c_start_time    constant date          := date '2020-01-01';
c_value_count   constant pls_integer   := 24;
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
      p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '0'), -- zero interval should be okay
      p_utc_offset        => -10,                                  -- offset will be ignored
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

   begin
      cwms_ts.create_ts_code (
         p_ts_code           => l_ts_code,
         p_cwms_ts_id        => replace(v_ts_ids(1), '<intvl>', '~1Hour'), -- ~1Hour interval should raise exception
         p_utc_offset        => -10,
         p_interval_forward  => null,
         p_interval_backward => null,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_fail_if_exists    => 'T',
         p_office_id         => c_office_id);
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         if instr(sqlerrm, 'Cannot create Local-Regular Time Series for a location with a NULL time zone') > 0 then
            null;
         else
            setup;
            raise;
         end if;
   end;
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
   l_time_zone_code integer;
   l_cwms_ts_id     av_cwms_ts_id.cwms_ts_id%type;
begin
   setup;
   for i in 1..c_location_ids.count loop
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
         ut.expect(l_time_zone_code).to_equal(v_timezone_codes(i));
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
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         begin
            execute immediate '
            select time_zone_id
              from at_cwms_ts_id
             where db_office_id = :c_office_id
               and cwms_ts_id = :v_ts_ids'
              into l_time_zone_id
             using c_office_id,
                   l_cwms_ts_id;
         exception
            when exc_invalid_identifier then null;
         end;
         ut.expect(l_time_zone_id).to_equal(v_timezone_ids(i));
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
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         begin
            execute immediate '
            select time_zone_id
              from av_cwms_ts_id
             where db_office_id = :c_office_id
               and cwms_ts_id = :v_ts_ids'
              into l_time_zone_id
             using c_office_id,
                   l_cwms_ts_id;
         exception
            when exc_invalid_identifier then null;
         end;
         ut.expect(l_time_zone_id).to_equal(v_timezone_ids(i));
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
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         begin
            execute immediate '
            select time_zone_id
              from av_cwms_ts_id2
             where db_office_id = :c_office_id
               and cwms_ts_id = :v_ts_ids'
              into l_time_zone_id
             using c_office_id,
                   l_cwms_ts_id;
         exception
            when exc_invalid_identifier then null;
         end;
         ut.expect(l_time_zone_id).to_equal(v_timezone_ids(i));
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
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   setup;
   for i in 1..c_location_ids.count loop
      for j in 1..c_intervals.count loop
         l_cwms_ts_id := replace(v_ts_ids(i), '<intvl>', c_intervals(j));
         begin
            execute immediate '
            select time_zone_id
              from zav_cwms_ts_id
             where db_office_id = :c_office_id
               and cwms_ts_id = :v_ts_ids'
              into l_time_zone_id
             using c_office_id,
                   l_cwms_ts_id;
         exception
            when exc_invalid_identifier then null;
         end;
         ut.expect(l_time_zone_id).to_equal(v_timezone_ids(i));
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
begin
   setup;
   for i in 1..c_location_ids.count loop
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
         ut.expect(l_timezone_id).to_equal(v_timezone_ids(i));
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
-- procedure store_ts
--------------------------------------------------------------------------------
procedure store_ts
is
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
   l_ts_values  tsv_array := tsv_array();
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
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
   cwms_ts.store_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values,
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

    ut.expect(l_count).to_equal(l_ts_values.count / 2);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts;
--------------------------------------------------------------------------------
-- procedure store_ts_old
--------------------------------------------------------------------------------
procedure store_ts_old
is
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
   l_ts_values  tsv_array := tsv_array();
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
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
   cwms_ts.store_ts(
      p_office_id       => c_office_id,
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values,
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

    ut.expect(l_count).to_equal(l_ts_values.count / 2);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts_old;
--------------------------------------------------------------------------------
-- procedure store_ts_oracle
--------------------------------------------------------------------------------
procedure store_ts_oracle
is
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
   l_times      cwms_ts.number_array;
   l_values     cwms_ts.double_array;
   l_qualities  cwms_ts.number_array;
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
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

    ut.expect(l_count).to_equal(l_values.count / 2);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts_oracle;
--------------------------------------------------------------------------------
-- procedure store_ts_jython
--------------------------------------------------------------------------------
procedure store_ts_jython
is
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
   l_times      number_tab_t := number_tab_t();
   l_values     number_tab_t := number_tab_t();
   l_qualities  number_tab_t := number_tab_t();
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
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

    ut.expect(l_count).to_equal(l_values.count / 2);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end store_ts_jython;
--------------------------------------------------------------------------------
-- procedure zstore_ts
--------------------------------------------------------------------------------
procedure zstore_ts
is
   l_cwms_ts_id av_cwms_ts_id.cwms_ts_id%type;
   l_ts_values  ztsv_array := ztsv_array();
   l_ts_code    integer;
   l_count      integer;
   l_offset     integer;
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
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_cwms_ts_id,
      p_units           => c_ts_unit,
      p_timeseries_data => l_ts_values,
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

    ut.expect(l_count).to_equal(l_ts_values.count / 2);
    ut.expect(l_offset).to_equal(-c_intvl_offsets(2));
end zstore_ts;

end test_lrts_updates;
/

grant execute on test_lrts_updates to cwms_user;