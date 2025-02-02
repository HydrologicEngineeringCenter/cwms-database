CREATE OR REPLACE PACKAGE test_cwms_lock AS
   --%suite(Test cwms_lock package code)
   --%rollback(manual)
   --%beforeall (setup)
   --%afterall(teardown)

   PROCEDURE setup;
   PROCEDURE teardown;

   --%test(Test roundtrip store and retrieve with lock data)
   PROCEDURE test_store_and_retrieve;

   --%test(Test roundtrip store and retrieve with lock data with no pool levels)
   PROCEDURE test_store_and_retrieve_no_pool_levels;

   --%throws(-20019)
   PROCEDURE test_invalid_pool_values;
   --%throws(-20019)
   PROCEDURE  test_null_param_warning_buffer;
   --%throws(-20020)
   PROCEDURE  test_non_existant_param_warning_buffer;
END test_cwms_lock;
/
SHOW ERRORS;
grant execute on test_cwms_lock to cwms_user;
CREATE OR REPLACE PACKAGE BODY test_cwms_lock AS
   PROCEDURE setup IS
      BEGIN
         cwms_loc.store_location2(
            p_location_id => 'CDSO2',
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
            p_time_zone_id => 'CST6CDT',
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
            p_db_office_id => 'SPK');
         commit;
         cwms_loc.store_location2(
            p_location_id => 'NEWT-Lock',
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
            p_time_zone_id => 'CST6CDT',
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
            p_db_office_id => 'SPK');
         commit;
         cwms_loc.store_location2(
               p_location_id => 'ROBE-Lock',
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
               p_time_zone_id => 'CST6CDT',
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
               p_db_office_id => 'SPK');
         commit;
         cwms_project.store_project(project_obj_t(
               cwms_t_location_obj(cwms_t_location_ref('CDSO2', 'SPK')),
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null,
               null));
         commit;
   end setup;

   PROCEDURE teardown IS
      BEGIN
         COMMIT;

         cwms_project.DELETE_PROJECT(p_project_id => 'CDSO2',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id => 'SPK');
         COMMIT;
         cwms_loc.delete_location(
            p_location_id   => 'CDSO2',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => 'SPK');
         COMMIT;

         cwms_loc.delete_location(
            p_location_id   => 'NEWT-Lock',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => 'SPK');
         COMMIT;
   END teardown;

   PROCEDURE test_store_and_retrieve IS
      l_lock_obj           lock_obj_t;
      l_retrieved_lock_obj lock_obj_t;
      l_lock_location_ref  location_ref_t := location_ref_t('NEWT-Lock', 'SPK');
      l_warning_buffer     number;
      c_office_id          CONSTANT VARCHAR2(16) := 'SPK';
      proj_location_id     CONSTANT VARCHAR2(16) := 'CDSO2';
      c_location_id        CONSTANT VARCHAR2(57) := 'NEWT-Lock';
      c_parameter          CONSTANT VARCHAR2(49) := 'Elev-Closure';
      c_param_type         CONSTANT VARCHAR2(16) := 'Inst';
      c_duration           CONSTANT VARCHAR2(16) := '0';
      c_implicit_names     CONSTANT cwms_t_str_tab := cwms_t_str_tab('High Water Upper Pool', 'High Water Lower Pool', 'Low Water Upper Pool', 'Low Water Lower Pool');
   BEGIN

      setup();
      -- Create the location levels for implicit pools
      FOR i IN 1..c_implicit_names.COUNT LOOP
         cwms_level.store_location_level(
            p_location_level_id => c_location_id || '.' || c_parameter || '.' || c_param_type || '.' || c_duration || '.' || c_implicit_names(i),
            p_level_value       => 100 * i,
            p_level_units       => 'm',
            p_effective_date    => DATE '2000-01-01',
            p_office_id         => c_office_id,
            p_fail_if_exists   => 'F');
      END LOOP;

      cwms_level.store_location_level(
         p_location_level_id => l_lock_location_ref.get_location_id()||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||'Warning Buffer',
         p_level_value       => 3,
         p_level_units       => 'm',
         p_effective_date    => date '2000-01-01',
         p_office_id         => c_office_id,
         p_fail_if_exists   => 'F');
      commit;

      -- Populate lock_obj_t object with required values
      l_lock_obj := lock_obj_t(
         project_location_ref => location_ref_t(proj_location_id, c_office_id),
         lock_location => location_obj_t(cwms_loc.get_location_code(c_office_id, l_lock_location_ref.get_location_id())),
         volume_per_lockage => 100.0,               -- Volume per lockage
         volume_units_id   => 'm3',                  -- Volume units
         lock_width        => 10.0,                  -- Lock width
         lock_length       => 20.0,                  -- Lock length
         minimum_draft     => 5.0,                   -- Minimum draft
         normal_lock_lift  => 15.0,                  -- Normal lock lift
         units_id          => 'm',                    -- Units for width, length, draft, and lift
         maximum_lock_lift => 25.0,                  -- Maximum lock lift
         elev_units_id     => 'm',                    -- Units for elevation
         elev_closure_high_water_upper_pool => NULL, -- Elevation for high water upper pool
         elev_closure_high_water_lower_pool => NULL, -- Elevation for high water lower pool
         elev_closure_low_water_upper_pool => NULL,    -- Elevation for low water upper pool
         elev_closure_low_water_lower_pool => NULL,   -- Elevation for low water lower pool
         elev_closure_high_water_upper_pool_warning => NULL,
         elev_closure_high_water_lower_pool_warning => NULL,
         chamber_location_description => lookup_type_obj_t(
            office_id => c_office_id,                      -- Assuming you want 'Single Chamber'
            display_value => 'Single Chamber',
            tooltip => 'A lock gate system with a single chamber',
            active => 'T'                                 -- Active status
         )
      );

      cwms_lock.store_lock(p_lock => l_lock_obj);

      -- Retrieve the lock object using the location reference
      cwms_lock.retrieve_lock(p_lock => l_retrieved_lock_obj, p_lock_location_ref => l_lock_location_ref);

      ut.expect(l_retrieved_lock_obj.volume_per_lockage).to_equal(l_lock_obj.volume_per_lockage);
      ut.expect(l_retrieved_lock_obj.units_id).to_equal(l_lock_obj.units_id);
      ut.expect(l_retrieved_lock_obj.lock_width).to_equal(l_lock_obj.lock_width);
      ut.expect(l_retrieved_lock_obj.lock_length).to_equal(l_lock_obj.lock_length);
      ut.expect(l_retrieved_lock_obj.minimum_draft).to_equal(l_lock_obj.minimum_draft);
      ut.expect(l_retrieved_lock_obj.normal_lock_lift).to_equal(l_lock_obj.normal_lock_lift);
      ut.expect(l_retrieved_lock_obj.maximum_lock_lift).to_equal(l_lock_obj.maximum_lock_lift);
      ut.expect(l_retrieved_lock_obj.elev_units_id).to_equal(l_lock_obj.elev_units_id);
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_upper_pool).to_equal(100.0);
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_lower_pool).to_equal(200.0);
      ut.expect(l_retrieved_lock_obj.elev_closure_low_water_upper_pool).to_equal(300.0);
      ut.expect(l_retrieved_lock_obj.elev_closure_low_water_lower_pool).to_equal(400.0);
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_upper_pool_warning).to_equal(97);
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_lower_pool_warning).to_equal(197);
      ut.expect(l_retrieved_lock_obj.chamber_location_description.display_value).to_equal(l_lock_obj.chamber_location_description.display_value);

      l_warning_buffer := cwms_lock.get_warning_buffer_value(l_lock_location_ref.get_location_code());
      ut.expect(l_warning_buffer).to_equal(3.0);

      --get warning buffer for a location that doesn't have a location level warning buffer
      l_warning_buffer := cwms_lock.get_warning_buffer_value(location_ref_t('CDSO2', 'SPK').get_location_code());
      ut.expect(l_warning_buffer).to_equal(0.6096);

   END test_store_and_retrieve;

   PROCEDURE test_store_and_retrieve_no_pool_levels IS
      l_lock_obj           lock_obj_t;
      l_retrieved_lock_obj lock_obj_t;
      l_lock_location_ref  location_ref_t := location_ref_t('ROBE-Lock', 'SPK');
      c_office_id          CONSTANT VARCHAR2(16) := 'SPK';
      proj_location_id     CONSTANT VARCHAR2(16) := 'CDSO2';
   BEGIN

      setup();

      -- Populate lock_obj_t object with required values
      l_lock_obj := lock_obj_t(
            project_location_ref => location_ref_t(proj_location_id, c_office_id),
            lock_location => location_obj_t(cwms_loc.get_location_code(c_office_id, l_lock_location_ref.get_location_id())),
            volume_per_lockage => 100.0,               -- Volume per lockage
            volume_units_id   => 'm3',                  -- Volume units
            lock_width        => 10.0,                  -- Lock width
            lock_length       => 20.0,                  -- Lock length
            minimum_draft     => 5.0,                   -- Minimum draft
            normal_lock_lift  => 15.0,                  -- Normal lock lift
            units_id          => 'm',                    -- Units for width, length, draft, and lift
            maximum_lock_lift => 25.0,                  -- Maximum lock lift
            elev_units_id     => 'm',                    -- Units for elevation
            elev_closure_high_water_upper_pool => NULL, -- Elevation for high water upper pool
            elev_closure_high_water_lower_pool => NULL, -- Elevation for high water lower pool
            elev_closure_low_water_upper_pool => NULL,    -- Elevation for low water upper pool
            elev_closure_low_water_lower_pool => NULL,   -- Elevation for low water lower pool
            elev_closure_high_water_upper_pool_warning => NULL,
            elev_closure_high_water_lower_pool_warning => NULL,
            chamber_location_description => NULL
         );

      cwms_lock.store_lock(p_lock => l_lock_obj);

      -- Retrieve the lock object using the location reference
      cwms_lock.retrieve_lock(p_lock => l_retrieved_lock_obj, p_lock_location_ref => l_lock_location_ref);

      ut.expect(l_retrieved_lock_obj.volume_per_lockage).to_equal(l_lock_obj.volume_per_lockage);
      ut.expect(l_retrieved_lock_obj.units_id).to_equal(l_lock_obj.units_id);
      ut.expect(l_retrieved_lock_obj.lock_width).to_equal(l_lock_obj.lock_width);
      ut.expect(l_retrieved_lock_obj.lock_length).to_equal(l_lock_obj.lock_length);
      ut.expect(l_retrieved_lock_obj.minimum_draft).to_equal(l_lock_obj.minimum_draft);
      ut.expect(l_retrieved_lock_obj.normal_lock_lift).to_equal(l_lock_obj.normal_lock_lift);
      ut.expect(l_retrieved_lock_obj.maximum_lock_lift).to_equal(l_lock_obj.maximum_lock_lift);
      ut.expect(l_retrieved_lock_obj.elev_units_id).to_equal(l_lock_obj.elev_units_id);
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_upper_pool).to_be_null();
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_lower_pool).to_be_null();
      ut.expect(l_retrieved_lock_obj.elev_closure_low_water_upper_pool).to_be_null();
      ut.expect(l_retrieved_lock_obj.elev_closure_low_water_lower_pool).to_be_null();
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_upper_pool_warning).to_be_null();
      ut.expect(l_retrieved_lock_obj.elev_closure_high_water_lower_pool_warning).to_be_null();
      ut.expect(l_retrieved_lock_obj.chamber_location_description.display_value).to_equal(l_lock_obj.chamber_location_description.display_value);

   END test_store_and_retrieve_no_pool_levels;

   PROCEDURE test_invalid_pool_values IS
      l_lock_obj           lock_obj_t;
      l_lock_location_ref  location_ref_t := location_ref_t('NEWT-Lock', 'SPK');
      c_office_id          CONSTANT VARCHAR2(16) := 'SPK';
      proj_location_id     CONSTANT VARCHAR2(16) := 'CDSO2';
   BEGIN
      l_lock_obj := lock_obj_t(
         project_location_ref => location_ref_t(proj_location_id,c_office_id),
         lock_location => location_obj_t(cwms_loc.get_location_code(c_office_id, l_lock_location_ref.get_location_id())),
         volume_per_lockage => 100.0,               -- Volume per lockage
         volume_units_id   => 'm3',                  -- Volume units
         lock_width        => 10.0,                  -- Lock width
         lock_length       => 20.0,                  -- Lock length
         minimum_draft     => 5.0,                   -- Minimum draft
         normal_lock_lift  => 15.0,                  -- Normal lock lift
         units_id          => 'm',                    -- Units for width, length, draft, and lift
         maximum_lock_lift => 25.0,                  -- Maximum lock lift
         elev_units_id     => 'm',                    -- Units for elevation
         elev_closure_high_water_upper_pool => 123, -- Elevation for high water upper pool
         elev_closure_high_water_lower_pool => NULL, -- Elevation for high water lower pool
         elev_closure_low_water_upper_pool => NULL,    -- Elevation for low water upper pool
         elev_closure_low_water_lower_pool => NULL,   -- Elevation for low water lower pool
         elev_closure_high_water_upper_pool_warning => NULL,
         elev_closure_high_water_lower_pool_warning => NULL,
         chamber_location_description => lookup_type_obj_t(
            office_id => c_office_id,                      -- Assuming you want 'Single Chamber'
            display_value => 'Single Chamber',
            tooltip => 'A lock gate system with a single chamber',
            active => 'T')                                 -- Active status
         );
      cwms_lock.store_lock(p_lock => l_lock_obj);
   END test_invalid_pool_values;

   PROCEDURE test_null_param_warning_buffer IS
      l_warning_buffer   number;
   BEGIN
      l_warning_buffer := cwms_lock.get_warning_buffer_value(NULL);
   END test_null_param_warning_buffer;

   PROCEDURE test_non_existant_param_warning_buffer IS
      l_warning_buffer   number;
   BEGIN
      l_warning_buffer := cwms_lock.get_warning_buffer_value(0123456789);
   END test_non_existant_param_warning_buffer;
END test_cwms_lock;
/
SHOW ERRORS;