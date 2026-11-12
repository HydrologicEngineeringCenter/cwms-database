set verify off;
create or replace package &&cwms_schema..test_cwms_turbine as
    --%suite(Test schema for turbine functionality)

   --%beforeall(setup)
   --%afterall(teardown)
   --%rollback(manual)

   procedure teardown;
   procedure setup;

   --%test(Protected turbine changes cannot be overwritten unless flag is set)
   procedure test_override_protection;

   c_office_id           constant varchar2(16) := '&&office_id';
   c_project_location_id constant varchar2(57) := 'ProjWithTurbine';
   c_timezone_id         constant varchar2(28) := 'America/Los_Angeles';
end test_cwms_turbine;
/
show errors;
create or replace package body &&cwms_schema..test_cwms_turbine as
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
      begin
         -- deleting the project location also deletes its turbine changes
         cwms_loc.delete_location(
            p_location_id   => c_project_location_id,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => c_office_id);
      exception
         when exc_location_id_not_found then null;
      end;
      commit;
      clear_caches;
   end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
   procedure setup
   is
      l_location_ref location_ref_t;
      l_location     location_obj_t;
      l_project_obj  project_obj_t;
   begin
      ------------------------------------
      -- create the project location    --
      ------------------------------------
      cwms_loc.store_location2(
         p_location_id         => c_project_location_id,
         p_location_type       => null,
         p_elevation           => null,
         p_elev_unit_id        => null,
         p_vertical_datum      => null,
         p_latitude            => null,
         p_longitude           => null,
         p_horizontal_datum    => null,
         p_public_name         => null,
         p_long_name           => null,
         p_description         => null,
         p_time_zone_id        => c_timezone_id,
         p_county_name         => null,
         p_state_initial       => null,
         p_active              => null,
         p_location_kind_id    => null,
         p_map_label           => null,
         p_published_latitude  => null,
         p_published_longitude => null,
         p_bounding_office_id  => null,
         p_nation_id           => null,
         p_nearest_city        => null,
         p_ignorenulls         => 'T',
         p_db_office_id        => c_office_id);
      ----------------------------
      -- make it into a project --
      ----------------------------
      l_location_ref := location_ref_t(c_project_location_id, c_office_id);
      l_location     := location_obj_t(l_location_ref);
      l_project_obj  := project_obj_t(l_location, null, null, null,
                                      null, null, null, null, null, null,
                                      null, null, null, null, null, null, null);
      cwms_project.store_project(l_project_obj, 'F');
      commit;
   end setup;
--------------------------------------------------------------------------------
-- function make_turbine_changes
--    builds two turbine changes (no turbine settings) for the test project
--------------------------------------------------------------------------------
   function make_turbine_changes(
      p_protected  in varchar2,
      p_notes      in varchar2,
      p_elev_pool  in binary_double,
      p_start_time in date)
      return turbine_change_tab_t
   is
      l_project_ref location_ref_t := location_ref_t(c_project_location_id, c_office_id);
      l_changes     turbine_change_tab_t := turbine_change_tab_t();
   begin
      l_changes.extend(2);
      for i in 1..2 loop
         l_changes(i) := turbine_change_obj_t(
            l_project_ref,                                                          -- project_location_ref
            p_start_time + (i - 1) / 24,                                            -- change_date (hourly)
            lookup_type_obj_t('CWMS', 'R', 'Reported by powerhouse', 'T'),          -- discharge_computation
            lookup_type_obj_t('CWMS', 'O', 'Other release', 'T'),                   -- setting_reason
            null,                                                                   -- settings
            p_elev_pool + i,                                                        -- elev_pool
            p_elev_pool - 10 + i,                                                   -- elev_tailwater
            'm',                                                                    -- elev_units
            100 * i,                                                                -- old_total_discharge_override
            100 * i + 50,                                                           -- new_total_discharge_override
            'cms',                                                                  -- discharge_units
            p_notes || ' ' || i,                                                    -- change_notes
            p_protected);                                                           -- protected
      end loop;
      return l_changes;
   end make_turbine_changes;
--------------------------------------------------------------------------------
-- procedure expect_turbine_changes
--    compares the significant fields of retrieved turbine changes to expected
--------------------------------------------------------------------------------
   procedure expect_turbine_changes(
      p_expected in turbine_change_tab_t,
      p_actual   in turbine_change_tab_t)
   is
   begin
      ut.expect(p_actual is not null).to_be_true;
      if p_actual is null then
         return;
      end if;
      ut.expect(p_actual.count).to_equal(p_expected.count);
      for i in 1..least(p_expected.count, p_actual.count) loop
         ut.expect(p_actual(i).change_date).to_equal(p_expected(i).change_date);
         ut.expect(p_actual(i).protected).to_equal(p_expected(i).protected);
         ut.expect(p_actual(i).change_notes).to_equal(p_expected(i).change_notes);
         ut.expect(round(p_actual(i).elev_pool, 6)).to_equal(round(p_expected(i).elev_pool, 6));
         ut.expect(round(p_actual(i).elev_tailwater, 6)).to_equal(round(p_expected(i).elev_tailwater, 6));
         ut.expect(round(p_actual(i).new_total_discharge_override, 6)).to_equal(round(p_expected(i).new_total_discharge_override, 6));
      end loop;
   end expect_turbine_changes;
--------------------------------------------------------------------------------
-- procedure test_override_protection
--------------------------------------------------------------------------------
   procedure test_override_protection
   is
      c_start_time   constant date := to_date('2024-01-15 06:00', 'yyyy-mm-dd hh24:mi');
      c_end_time     constant date := c_start_time + 1 / 24;
      l_project_ref  location_ref_t := location_ref_t(c_project_location_id, c_office_id);
      unprot_changes turbine_change_tab_t;
      prot_changes   turbine_change_tab_t;
      new_changes    turbine_change_tab_t;
      l_retrieved    turbine_change_tab_t;
      l_raised       boolean := false;
   begin
      unprot_changes := make_turbine_changes('F', 'unprotected', 100, c_start_time);
      prot_changes   := make_turbine_changes('T', 'protected',   200, c_start_time);
      new_changes    := make_turbine_changes('F', 'attempted',   300, c_start_time);

      -- store unprotected turbine changes
      cwms_turbine.store_turbine_changes(
         p_turbine_changes => unprot_changes,
         p_time_zone       => c_timezone_id);

      -- retrieve unprotected turbine changes
      l_retrieved := cwms_turbine.retrieve_turbine_changes_f(
         p_project_location => l_project_ref,
         p_start_time       => c_start_time,
         p_end_time         => c_end_time,
         p_time_zone        => c_timezone_id,
         p_unit_system      => 'SI');
      expect_turbine_changes(unprot_changes, l_retrieved);

      -- overwrite turbine changes with protected ones
      -- (existing records are unprotected, so no override is required)
      cwms_turbine.store_turbine_changes(
         p_turbine_changes => prot_changes,
         p_time_zone       => c_timezone_id);

      -- verify that the protected changes overwrote the unprotected changes
      l_retrieved := cwms_turbine.retrieve_turbine_changes_f(
         p_project_location => l_project_ref,
         p_start_time       => c_start_time,
         p_end_time         => c_end_time,
         p_time_zone        => c_timezone_id,
         p_unit_system      => 'SI');
      expect_turbine_changes(prot_changes, l_retrieved);

      -- try to overwrite protected changes without overriding protection - should fail
      begin
         cwms_turbine.store_turbine_changes(
            p_turbine_changes     => new_changes,
            p_time_zone           => c_timezone_id,
            p_override_protection => 'F');
      exception
         when others then
            l_raised := true;
            ut.expect(sqlerrm).to_be_like('%protected%');
      end;
      ut.expect(l_raised).to_be_true;

      -- retrieve protected changes, verify they have not changed
      l_retrieved := cwms_turbine.retrieve_turbine_changes_f(
         p_project_location => l_project_ref,
         p_start_time       => c_start_time,
         p_end_time         => c_end_time,
         p_time_zone        => c_timezone_id,
         p_unit_system      => 'SI');
      expect_turbine_changes(prot_changes, l_retrieved);

      -- overwrite protected changes with p_override_protection => 'T' - should succeed
      cwms_turbine.store_turbine_changes(
         p_turbine_changes     => new_changes,
         p_time_zone           => c_timezone_id,
         p_override_protection => 'T');
      l_retrieved := cwms_turbine.retrieve_turbine_changes_f(
         p_project_location => l_project_ref,
         p_start_time       => c_start_time,
         p_end_time         => c_end_time,
         p_time_zone        => c_timezone_id,
         p_unit_system      => 'SI');
      expect_turbine_changes(new_changes, l_retrieved);

      -- clean up
      cwms_turbine.delete_turbine_changes(
         p_project_location    => l_project_ref,
         p_start_time          => c_start_time,
         p_end_time            => c_end_time,
         p_time_zone           => c_timezone_id,
         p_override_protection => 'T');
      commit;
   end test_override_protection;

end test_cwms_turbine;
/
show errors;
grant execute on test_cwms_turbine to cwms_user;
