create or replace package test_cwms_ts_profile as
   --%suite(Test schema for TS Profile APIs)
   --%rollback(manual)
   --%afterall(teardown)
   --%beforeall(setup)

   procedure setup;

   --%test(Catalog TS Profile Parsers and ensure expected rows are returned)
   procedure cat_profile_parser;
   --%test(Delete single TS Profile instance and ensure only the instance is deleted)
   procedure delete_single_instance;
   procedure teardown;
--    c_office_id constant varchar2(3) := '&&office_id';
   c_office_id constant varchar2(3) := 'SWT';
   c_location_ids constant str_tab_t := str_tab_t('TestLocTsProf', 'TestLocTsProf-WithSub');
   c_timezone_ids constant str_tab_t := str_tab_t('US/Central', 'America/Los_Angeles');
end test_cwms_ts_profile;
show errors
/
create or replace package body test_cwms_ts_profile as
   --------------------------------------------------------------------------------
-- procedure clear_caches
--------------------------------------------------------------------------------
   procedure clear_caches
      is
   begin
      cwms_ts.clear_all_caches;
      cwms_loc.clear_all_caches;
   end clear_caches;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
   procedure teardown
      is
      exc_location_id_not_found exception;
      pragma exception_init (exc_location_id_not_found, -20025);
   begin
      clear_caches;
      for i in 1..c_location_ids.count
         loop
            begin
               cwms_loc.delete_location(
                  p_location_id => c_location_ids(i),
                  p_delete_action => cwms_util.delete_all,
                  p_db_office_id => c_office_id);
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
   procedure setup
      is
   begin
      ------------------------------
      -- start with a clean slate --
      ------------------------------
      cwms_env.set_session_office_id(c_office_id);
      teardown;
      cwms_util.set_output_debug_info(false);
      -----------------------
      -- for each location --
      -----------------------
      for i in 1..c_location_ids.count
         loop
         -------------------------
         -- create the location --
         -------------------------
            cwms_loc.store_location2(
               p_location_id => c_location_ids(i),
               p_location_type => null,
               p_elevation => null,
               p_elev_unit_id => null,
               p_vertical_datum => null,
               p_latitude => null,
               p_longitude => null,
               p_horizontal_datum => null,
               p_public_name => null,
               p_long_name => null,
               p_description => null,
               p_time_zone_id => c_timezone_ids(i),
               p_county_name => null,
               p_state_initial => null,
               p_active => null,
               p_location_kind_id => null,
               p_map_label => null,
               p_published_latitude => null,
               p_published_longitude => null,
               p_bounding_office_id => null,
               p_nation_id => null,
               p_nearest_city => null,
               p_ignorenulls => 'T',
               p_db_office_id => c_office_id);
         end loop;
      commit;
   end setup;
   --------------------------------------------------------------------------------
   -- procedure cat_profile_parser
   --------------------------------------------------------------------------------
   procedure cat_profile_parser
      is
      l_ts_code          NUMBER;
      l_irr_ts_id        cwms_v_ts_id.cwms_ts_id%type := c_location_ids(1) || '.Depth.Inst.0.0.Test';
      l_1_min_ts_id      cwms_v_ts_id.cwms_ts_id%type := c_location_ids(2) || '.Depth-Water.Inst.1Minute.0.Test';
      l_crsr             sys_refcursor;
      l_ts_id_out        cwms_v_ts_id.cwms_ts_id%type;
      l_location_id_out  cwms_v_loc.location_id%type;
      l_key_parameter_id cwms_v_ts_profile.key_parameter_id%type;
      l_data_crsr        sys_refcursor;
      l_office_id_out    cwms_v_ts_id.db_office_id%type;
      l_description      cwms_v_ts_profile.description%type;
      l_counter          NUMBER                       := 0;
   begin
      ------------------------
      -- create ts profiles --
      ------------------------
      cwms_env.set_session_office_id(c_office_id);
      cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_cwms_ts_id => l_irr_ts_id,
                             p_office_id => c_office_id);
      cwms_ts.create_ts_code(p_ts_code => l_ts_code,
                             p_cwms_ts_id => l_1_min_ts_id,
                             p_office_id => c_office_id);
      cwms_ts_profile.store_ts_profile(
         p_location_id => c_location_ids(1),
         p_key_parameter_id => 'Depth',
         p_profile_params => 'Depth,Temp',
         p_description => 'Depth-Temp Profile',
         p_ref_ts_id => l_irr_ts_id,
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);
      cwms_ts_profile.store_ts_profile_parser(
         p_location_id => c_location_ids(1),
         p_key_parameter_id => 'Depth',
         p_record_delimiter => chr(10),
         p_field_delimiter => chr(9),
         p_time_field => 1,
         p_time_start_col => null,
         p_time_end_col => null,
         p_time_format => 'yyyy-mm-dd hh24:mi:ss',
         p_time_zone => 'UTC',
         p_parameter_info => 'Depth,ft,2' || chr(10) || 'Temp,F,3',
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);

      cwms_ts_profile.store_ts_profile(
         p_location_id => c_location_ids(2),
         p_key_parameter_id => 'Depth-Water',
         p_profile_params => 'Depth-Water,Temp-Water',
         p_description => 'Depth-Water Temp Profile',
         p_ref_ts_id => l_1_min_ts_id,
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);
      cwms_ts_profile.store_ts_profile_parser(
         p_location_id => c_location_ids(2),
         p_key_parameter_id => 'Depth-Water',
         p_record_delimiter => chr(10),
         p_field_delimiter => chr(9),
         p_time_field => 1,
         p_time_start_col => null,
         p_time_end_col => null,
         p_time_format => 'yyyy-mm-dd hh24:mi:ss',
         p_time_zone => 'UTC',
         p_parameter_info => 'Depth-Water,ft,2' || chr(10) || 'Temp-Water,F,3',
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);
      l_crsr := cwms_ts_profile.cat_ts_profile_f('*', '*', '*');
      loop
         fetch l_crsr
            into l_office_id_out,
            l_location_id_out,
            l_key_parameter_id,
            l_data_crsr,
            l_ts_id_out,
            l_description;
         exit when l_crsr%notfound;
         l_counter := l_counter + 1;
         close l_data_crsr;
         if l_key_parameter_id = 'Depth-Water' then
            ut.expect(l_office_id_out).to_equal(c_office_id);
            ut.expect(l_location_id_out).to_equal(c_location_ids(2));
            ut.expect(l_ts_id_out).to_equal(l_1_min_ts_id);
            ut.expect(l_description).to_equal('Depth-Water Temp Profile');
         else
            ut.expect(l_key_parameter_id).to_equal('Depth');
            ut.expect(l_office_id_out).to_equal(c_office_id);
            ut.expect(l_location_id_out).to_equal(c_location_ids(1));
            ut.expect(l_ts_id_out).to_equal(l_irr_ts_id);
            ut.expect(l_description).to_equal('Depth-Temp Profile');
         end if;
      end loop;
      ut.expect(l_counter).to_equal(2);
      close l_crsr;

      l_counter := 0;
      l_crsr := cwms_ts_profile.cat_ts_profile_f('*', 'Depth-Water', c_office_id);
      loop
         fetch l_crsr
            into l_office_id_out,
            l_location_id_out,
            l_key_parameter_id,
            l_data_crsr,
            l_ts_id_out,
            l_description;
         exit when l_crsr%notfound;
         l_counter := l_counter + 1;
         close l_data_crsr;
         ut.expect(l_key_parameter_id).to_equal('Depth-Water');
         ut.expect(l_office_id_out).to_equal(c_office_id);
         ut.expect(l_location_id_out).to_equal(c_location_ids(2));
         ut.expect(l_ts_id_out).to_equal(l_1_min_ts_id);
         ut.expect(l_description).to_equal('Depth-Water Temp Profile');
      end loop;
      ut.expect(l_counter).to_equal(1);
      close l_crsr;

      l_counter := 0;
      l_crsr := cwms_ts_profile.cat_ts_profile_f(c_location_ids(1), '*', c_office_id);
      loop
         fetch l_crsr
            into l_office_id_out,
            l_location_id_out,
            l_key_parameter_id,
            l_data_crsr,
            l_ts_id_out,
            l_description;
         exit when l_crsr%notfound;
         l_counter := l_counter + 1;
         close l_data_crsr;
         ut.expect(l_key_parameter_id).to_equal('Depth');
         ut.expect(l_office_id_out).to_equal(c_office_id);
         ut.expect(l_location_id_out).to_equal(c_location_ids(1));
         ut.expect(l_ts_id_out).to_equal(l_irr_ts_id);
         ut.expect(l_description).to_equal('Depth-Temp Profile');
      end loop;
      ut.expect(l_counter).to_equal(1);
      close l_crsr;
   end cat_profile_parser;
   --------------------------------------------------------------------------------
   -- procedure delete_single_instance
   --------------------------------------------------------------------------------
   procedure delete_single_instance
      is
      l_ts_code          NUMBER;
      l_ts_id            cwms_v_ts_id.cwms_ts_id%type := c_location_ids(1) || '.Depth.Inst.1Hour.0.Test';
      l_crsr             sys_refcursor;
      l_instance_date_1  date                         := to_date('2024-08-16 05:00:00', 'YYYY-MM-DD HH24:MI:SS');
      l_instance_date_2  date                         := to_date('2024-08-17 05:00:00', 'YYYY-MM-DD HH24:MI:SS');
      l_location_id_out  cwms_v_loc.location_id%type;
      l_key_parameter_id cwms_v_ts_profile.key_parameter_id%type;
      l_office_id_out    cwms_v_ts_id.db_office_id%type;
      l_counter          number                       := 0;
      l_ts_profile_data  varchar2(4000);
      l_ts_data_utc      cwms_t_ztsv_array;
      l_count            number                       := 5;
      l_version_id       varchar2(32);
      l_version_date     date;
      l_first_date_time  date;
      l_last_date_time   date;
   begin
      ------------------------
      -- create ts profiles --
      ------------------------
      cwms_env.set_session_office_id(c_office_id);
      cwms_ts.create_ts_code(p_ts_code => l_ts_code, p_cwms_ts_id => l_ts_id,
                             p_office_id => c_office_id);

      cwms_ts_profile.store_ts_profile_parser(
         p_location_id => c_location_ids(1),
         p_key_parameter_id => 'Depth',
         p_record_delimiter => chr(10),
         p_field_delimiter => chr(9),
         p_time_field => 1,
         p_time_start_col => null,
         p_time_end_col => null,
         p_time_format => 'yyyy-mm-dd hh24:mi:ss',
         p_time_zone => 'UTC',
         p_parameter_info => 'Depth,ft,2' || chr(10) || 'Temp,F,3',
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);
      l_ts_data_utc := cwms_t_ztsv_array();
      l_ts_data_utc.extend(l_count + 1);
      for i in 1..l_count
         loop
            l_ts_data_utc(i) := cwms_t_ztsv(l_instance_date_1 + i - 1, i, 0);
            l_ts_profile_data := l_ts_profile_data
               || to_char(l_ts_data_utc(i).date_time, 'yyyy-mm-dd hh24:mi:ss') -- field 1 (Date_Time)
               || chr(9) || to_number(l_ts_data_utc(i).value) -- field 2 (Depth)
               || chr(9) || to_number(l_ts_data_utc(i).value) -- field 3 (Temp)
               || chr(10);
         end loop;
      cwms_ts_profile.store_ts_profile(
         p_location_id => c_location_ids(1),
         p_key_parameter_id => 'Depth',
         p_profile_params => 'Depth,Temp',
         p_description => 'Depth-Temp Profile',
         p_ref_ts_id => l_ts_id,
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);
      cwms_ts_profile.store_ts_profile_parser(
         p_location_id => c_location_ids(1),
         p_key_parameter_id => 'Depth',
         p_record_delimiter => chr(10),
         p_field_delimiter => chr(9),
         p_time_field => 1,
         p_time_start_col => null,
         p_time_end_col => null,
         p_time_format => 'yyyy-mm-dd hh24:mi:ss',
         p_time_zone => 'UTC',
         p_parameter_info => 'Depth,ft,2' || chr(10) || 'Temp,F,3',
         p_fail_if_exists => 'F',
         p_office_id => c_office_id);
      cwms_ts_profile.store_ts_profile_instance(p_location_id => c_location_ids(1), p_key_parameter_id => 'Depth',
                                                p_profile_data => l_ts_profile_data,
                                                p_version_id => 'UNIT_TEST', p_store_rule=>'DELETE INSERT',
                                                p_override_prot => 'T', p_version_date => l_instance_date_1,
                                                p_office_id => c_office_id);
      cwms_ts_profile.store_ts_profile_instance(p_location_id => c_location_ids(1), p_key_parameter_id => 'Depth',
                                                p_profile_data => l_ts_profile_data,
                                                p_version_id => 'UNIT_TEST', p_store_rule=>'DELETE INSERT',
                                                p_override_prot => 'T', p_version_date => l_instance_date_2,
                                                p_office_id => c_office_id);
      commit;
      --stored two instances with different versions, there should be two instances in the catalog
      l_crsr := cwms_ts_profile.cat_ts_profile_instance_f(c_location_ids(1), 'Depth', 'UNIT_TEST',
                                                          l_instance_date_1, l_instance_date_2, 'UTC', c_office_id);
      loop
         fetch l_crsr
            into l_office_id_out,
            l_location_id_out,
            l_key_parameter_id,
            l_version_id,
            l_version_date,
            l_first_date_time,
            l_last_date_time;
         exit when l_crsr%notfound;
         l_counter := l_counter + 1;
      end loop;
      close l_crsr;

      ut.expect(l_counter).to_equal(2);
      cwms_ts_profile.delete_ts_profile_instance(c_location_ids(1), 'Depth', 'UNIT_TEST', l_instance_date_1,
                                                 'UTC', 'T', l_instance_date_1, c_office_id);

--        there should now only be one instance
      l_crsr := cwms_ts_profile.cat_ts_profile_instance_f(c_location_ids(1), 'Depth', 'UNIT_TEST',
                                                          l_instance_date_1, l_instance_date_2, 'UTC', c_office_id);
      l_counter := 0;
      loop
         fetch l_crsr
            into l_office_id_out,
            l_location_id_out,
            l_key_parameter_id,
            l_version_id,
            l_version_date,
            l_first_date_time,
            l_last_date_time;
         exit when l_crsr%notfound;
         l_counter := l_counter + 1;
      end loop;
      ut.expect(l_counter).to_equal(1);
      close l_crsr;
   end delete_single_instance;

end test_cwms_ts_profile;
/
show errors
grant execute on test_cwms_ts_profile to cwms_user;
