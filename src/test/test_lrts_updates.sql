create or replace package test_lrts_updates as

--%suite(Test schema for full LRTS compatibility)

--%rollback(manual)
--%beforeall(setup)
--%afterall(teardown)

--%test(LRTS time zone in AT_CWMS_TS_SPEC table)
procedure tz_in_at_cwms_ts_spec;
--%test(LRTS time zone in AT_CWMS_TS_ID table)
procedure tz_in_at_cwms_ts_id;
--%test(LRTS time zone in cwms_cat.cat_ts_id)
procedure tz_in_catalog;
--%test(RETRIEVE_TS_OUT overload)
procedure retrieve_ts_out;
--%test(RETRIEVE_TS [1.4] overload)
procedure retrieve_ts_old;
--%test(RETRIEVE_TS_2 [1.4] overload)
procedure retrieve_ts_2_old;
--%test(RETRIEVE_TS [2.0] overload)
procedure retrieve_ts;
--%test(RETRIEVE_TS_MULTI2)
procedure retrieve_ts_multi2;
--%test(ZRETRIEVE_TS overload)
procedure zretrieve_ts;
--%test(ZRETRIEVE_TS_JAVA overload)
procedure zretrieve_ts_java;

procedure setup;
procedure teardown;
c_office_id     constant varchar2(3)       := '&office_id';
c_location_ids  constant cwms_t_str_tab    := cwms_t_str_tab('TestLoc1', 'TestLoc1-WithSub', 'TestLoc2');
c_timezone_ids  constant cwms_t_str_tab    := cwms_t_str_tab('US/Central', null, 'CST');
c_intvl_offsets constant cwms_t_number_tab := cwms_t_number_tab(0, -10, -20);
c_ts_id_part    constant varchar2(24)      := '.Code.Inst.~1Hour.0.Test';
c_ts_unit       constant varchar2(3)       := 'n/a';
c_start_time    constant date              := date '2020-01-01';
c_value_count   constant pls_integer       := 24;
end test_lrts_updates;
/
create or replace package body test_lrts_updates as
v_ts_ids         cwms_t_str_tab    := cwms_t_str_tab();
v_timezone_ids   cwms_t_str_tab    := cwms_t_str_tab();
v_timezone_codes cwms_t_number_tab := cwms_t_number_tab();
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   for i in 1..c_location_ids.count loop
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
procedure setup -- (sets up LRTS without using routines under test)
is
   l_ts_values_utc   cwms_t_ztsv_array := cwms_t_ztsv_array();
   l_empty_ts_values cwms_t_ztsv_array := cwms_t_ztsv_array();
begin
--   cwms_err.raise('ERROR', 'This setup() routine needs to assign user privileges to time series');
   ------------------------------
   -- start with a clean slate --
   ------------------------------
   teardown;
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
   l_ts_values_utc.extend(c_value_count);
   for i in 1..c_value_count loop
      l_ts_values_utc(i) := cwms_t_ztsv(
         date_time    => c_start_time + (i-1) / 24,
         value        => i,
         quality_code => 0);
   end loop;
   -----------------------
   -- for each location --
   -----------------------
   for i in 1..c_location_ids.count loop
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
      ------------------------------------------
      -- store the time series without values --
      ------------------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => v_ts_ids(i),
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
         p_cwms_ts_id             => v_ts_ids(i),
         p_interval_utc_offset    => c_intvl_offsets(i),
         p_snap_forward_minutes   => null,
         p_snap_backward_minutes  => null,
         p_local_reg_time_zone_id => null,
         p_ts_active_flag         => null,
         p_db_office_id           => c_office_id);
      ---------------------------------------
      -- store the time series with values --
      ---------------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => v_ts_ids(i),
         p_units           => c_ts_unit,
         p_timeseries_data => l_ts_values_utc,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);
   end loop;
   commit;
end setup;
--------------------------------------------------------------------------------
-- procedure tz_in_at_cwms_ts_spec
--------------------------------------------------------------------------------
procedure tz_in_at_cwms_ts_spec
is
   l_time_zone_code integer;
begin
   for i in 1..c_location_ids.count loop
      select time_zone_code
        into l_time_zone_code
        from at_cwms_ts_spec
       where ts_code = (select ts_code
                          from at_cwms_ts_id
                         where db_office_id = c_office_id
                           and cwms_ts_id = v_ts_ids(i)
                       );
      ut.expect(l_time_zone_code).to_equal(v_timezone_codes(i));
   end loop;
end tz_in_at_cwms_ts_spec;
--------------------------------------------------------------------------------
-- procedure tz_in_at_cwms_ts_id
--------------------------------------------------------------------------------
procedure tz_in_at_cwms_ts_id
is
   l_time_zone_id varchar2(28);
   exc_invalid_identifier exception;
   pragma exception_init (exc_invalid_identifier, -904);
begin
   for i in 1..c_location_ids.count loop
      begin
         execute immediate '
         select lrts_time_zone
           from at_cwms_ts_id
          where db_office_id = :c_office_id
            and cwms_ts_id = :v_ts_ids'
           into l_time_zone_id
          using c_office_id,
                v_ts_ids(i);
      exception
         when exc_invalid_identifier then null;
      end;   
      ut.expect(l_time_zone_id).to_equal(v_timezone_ids(i));
   end loop;
end tz_in_at_cwms_ts_id;
--------------------------------------------------------------------------------
-- procedure tz_in_catalog
--------------------------------------------------------------------------------
procedure tz_in_catalog
is
   l_crsr                sys_refcursor;
   l_db_office_id        varchar2(16);
   l_base_location_id    varchar2(24);
   l_cwms_ts_id          varchar2(191);
   l_interval_utc_offset number;
   l_lrts_timezone       varchar2(28);
   l_ts_active_flag      varchar2(1);
   l_user_privileges     number;
begin
   for i in 1..c_location_ids.count loop
      cwms_cat.cat_ts_id(
         p_cwms_cat            => l_crsr,
         p_ts_subselect_string => v_ts_ids(i),
         p_loc_category_id     => null,
         p_loc_group_id        => null,
         p_ts_category_id      => null,
         p_ts_group_id         => null,
         p_db_office_id        => c_office_id);
      fetch l_crsr
       into l_db_office_id,
            l_base_location_id,
            l_cwms_ts_id,
            l_interval_utc_offset,
            l_lrts_timezone,
            l_ts_active_flag,
            l_user_privileges;
      close l_crsr;
      ut.expect(l_db_office_id).to_equal(c_office_id);
      ut.expect(l_cwms_ts_id).to_equal(v_ts_ids(i));
      ut.expect(l_lrts_timezone).to_equal(v_timezone_ids(i));
   end loop;
end tz_in_catalog;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_out
--------------------------------------------------------------------------------
procedure retrieve_ts_out
is
begin
   null;
end retrieve_ts_out;
--------------------------------------------------------------------------------
-- procedure retrieve_ts_old
--------------------------------------------------------------------------------
procedure retrieve_ts_old
is
begin
   null;
end retrieve_ts_old;   
--------------------------------------------------------------------------------
-- procedure retrieve_ts_2_old
--------------------------------------------------------------------------------
procedure retrieve_ts_2_old
is
begin
   null;
end retrieve_ts_2_old;   
--------------------------------------------------------------------------------
-- procedure retrieve_ts
--------------------------------------------------------------------------------
procedure retrieve_ts
is
begin
   null;
end retrieve_ts;   
--------------------------------------------------------------------------------
-- procedure retrieve_ts_multi2
--------------------------------------------------------------------------------
procedure retrieve_ts_multi2
is
begin
   null;
end retrieve_ts_multi2;   
--------------------------------------------------------------------------------
-- procedure zretrieve_ts
--------------------------------------------------------------------------------
procedure zretrieve_ts
is
begin
   null;
end zretrieve_ts;   
--------------------------------------------------------------------------------
-- procedure zretrieve_ts_java
--------------------------------------------------------------------------------
procedure zretrieve_ts_java
is
begin
   null;
end zretrieve_ts_java;   

end test_lrts_updates;
/

grant execute on test_lrts_updates to cwms_user;