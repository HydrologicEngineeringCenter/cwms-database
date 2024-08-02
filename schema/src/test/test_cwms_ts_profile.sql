create or replace package test_cwms_ts_profile as
    --%suite(Test schema for TS Profile API's)
    --%rollback(manual)
    --%afterall(teardown)
    --%beforeall
    procedure setup;

    --%test(Catalog TS Profile Parsers and ensure expected rows are returned)
    procedure cat_profile_parser;
    procedure teardown;
    c_office_id constant varchar2(3) := '&&office_id';
    c_location_ids constant str_tab_t := str_tab_t('TestLocTsProf', 'TestLocTsProf-WithSub');
    c_timezone_ids constant str_tab_t := str_tab_t('US/Central', 'America/Los_Angeles');
end test_cwms_ts_profile;
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
        cwms_env.SET_SESSION_OFFICE_ID(c_office_id);
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
-- procedure test_lrts_id_output_formatting
--------------------------------------------------------------------------------
    procedure cat_profile_parser
        is
        l_ts_code          NUMBER;
        l_irr_ts_id        cwms_v_ts_id.cwms_ts_id%type := c_location_ids(1) || '.Depth.Inst.0.0.Test';
        l_1_min_ts_id      cwms_v_ts_id.cwms_ts_id%type := c_location_ids(2) || '.Depth-Water.Inst.1Minute.0.Test';
        l_crsr             sys_refcursor;
        l_ts_id_out        cwms_v_ts_id.cwms_ts_id%type;
        l_code             integer;
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
        cwms_env.SET_SESSION_OFFICE_ID(c_office_id);
        l_code := cwms_util.create_parameter_code('Depth-Water', 'F', c_office_id);
        l_code := cwms_util.create_parameter_code('Temp-Water', 'F', c_office_id);

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

end test_cwms_ts_profile;
/
show errors
grant execute on test_cwms_ts_profile to cwms_user;
