CREATE OR REPLACE PACKAGE test_cwms_lock AS
   --%suite(Test cwms_stream package code)
   --%beforeall (setup)
   PROCEDURE setup;
   --%afterall(teardown)
   PROCEDURE teardown;

   --%test(Test roundtrip store and retrieve with supplemental meas data)
   PROCEDURE test_store_and_retrieve;
END test_cwms_lock;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY test_cwms_lock AS
   PROCEDURE setup IS
      BEGIN
         INSERT INTO AT_PARAMETER (PARAMETER_CODE, DB_OFFICE_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, SUB_PARAMETER_DESC)
               VALUES (319, 53, 10, 'Closure', 'Elev-Closure');
         COMMIT;

         cwms_loc.store_location(
            p_location_id  => 'ReqLock1',
            p_time_zone_id => 'UTC',
            p_db_office_id => 'SPK');
         commit;
         cwms_loc.store_location(
            p_location_id  => 'TestLockLocation123',
            p_time_zone_id => 'UTC',
            p_db_office_id => 'SPK');
         commit;
   end setup;

   PROCEDURE teardown IS
      BEGIN
         DELETE FROM AT_PARAMETER WHERE PARAMETER_CODE = 319;
         COMMIT;

         cwms_project.DELETE_PROJECT(p_project_id => 'ReqLock1',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id => 'SPK');
         COMMIT;
         cwms_loc.delete_location(
            p_location_id   => 'ReqLock1',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => 'SPK');
         COMMIT;

         cwms_lock.delete_lock(
            p_lock_id => 'TestLockLocation123',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => 'SPK');
         COMMIT;

         cwms_loc.delete_location(
            p_location_id   => 'TestLockLocation123',
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => 'SPK');
         COMMIT;
   END teardown;

   PROCEDURE test_store_and_retrieve IS
      l_lock_obj           lock_obj_t;
      l_retrieved_lock_obj lock_obj_t;
      l_lock_location_ref  location_ref_t := location_ref_t('TestLockLocation123', 'SPK');
      l_warning_buffer   number;
      c_office_id          CONSTANT VARCHAR2(16) := 'SPK';
      proj_location_id     CONSTANT VARCHAR2(16) := 'ReqLock1';
      c_location_id        CONSTANT VARCHAR2(57) := 'TestLockLocation123';
      c_parameter          CONSTANT VARCHAR2(49) := 'Elev-Closure';
      c_param_type         CONSTANT VARCHAR2(16) := 'Inst';
      c_duration           CONSTANT VARCHAR2(16) := '0';
      c_implicit_names     CONSTANT cwms_t_str_tab := cwms_t_str_tab('High Water Upper Pool', 'High Water Lower Pool', 'Low Water Upper Pool', 'Low Water Lower Pool');
   BEGIN

      -- Create the location levels for implicit pools
      FOR i IN 1..c_implicit_names.COUNT LOOP
         cwms_level.store_location_level(
            p_location_level_id => c_location_id || '.' || c_parameter || '.' || c_param_type || '.' || c_duration || '.' || c_implicit_names(i),
            p_level_value       => 100 * i,
            p_level_units       => 'm',
            p_effective_date    => DATE '2000-01-01',
            p_office_id         => c_office_id);
      END LOOP;

      cwms_level.store_location_level(
         p_location_level_id => c_location_id||'.'||c_parameter||'.'||c_param_type||'.'||c_duration||'.'||'Warning Buffer',
         p_level_value       => 3,
         p_level_units       => 'm',
         p_effective_date    => date '2000-01-01',
         p_office_id         => c_office_id);
      commit;

      -- Populate lock_obj_t object with required values
      l_lock_obj := lock_obj_t(
         project_location_ref => location_ref_t(
            p_location_id => proj_location_id,
            p_office_id   => c_office_id
         ),
         lock_location => location_obj_t(
            p_location_code => cwms_loc.get_location_code(c_office_id, l_lock_location_ref.get_location_id())
         ),
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
      ut.expect(l_retrieved_lock_obj.chamber_location_description.display_value).to_equal(l_lock_obj.chamber_location_description.display_value);

      l_warning_buffer := cwms_lock.get_warning_buffer_value(l_lock_location_ref.get_location_code());
      ut.expect(l_warning_buffer).to_equal(3.0);

      cwms_level.delete_location_level(
         p_location_level_id => c_location_id||'.'||'Elev'||'.'||c_param_type||'.'||c_duration||'.'||'Closure Warning',
         p_office_id         => c_office_id);

      --now that location level doesnt exist, we should get back default 2 ft
      l_warning_buffer := cwms_lock.get_warning_buffer_value(l_lock_location_ref.get_location_code());
      ut.expect(l_warning_buffer).to_equal(0.6096);

      -- test coverage of handling of null and non-existant p_lock_location_code parameters
      ut.expect(
         BEGIN
            l_warning_buffer:= cwms_lock.get_warning_buffer_value(NULL);
         END;
      ).to_raise_exception('INVALID_ITEM');

      ut.expect(
         BEGIN
            l_warning_buffer:= cwms_lock.get_warning_buffer_value(0123456789);
         END;
      ).to_raise_exception('INVALID_ITEM');

      -- Test that the lock object throws error with invalid non-null pool values
      ut.expect(
         BEGIN
            l_lock_obj := lock_obj_t(
            project_location_ref => location_ref_t(
               p_location_id => proj_location_id,
               p_office_id   => c_office_id
            ),
            lock_location => location_obj_t(
               p_location_code => cwms_loc.get_location_code(c_office_id, l_lock_location_ref.get_location_id())
            ),
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
            chamber_location_description => lookup_type_obj_t(
               office_id => c_office_id,                      -- Assuming you want 'Single Chamber'
               display_value => 'Single Chamber',
               tooltip => 'A lock gate system with a single chamber',
               active => 'T')                                 -- Active status
            );
            cwms_lock.store_lock(p_lock => l_lock_obj);
         END;
      ).to_raise_exception('INVALID_ITEM');

      FOR i IN 1..c_implicit_names.COUNT LOOP
               cwms_level.delete_location_level(
                  p_location_level_id => c_location_id || '.' || c_parameter || '.' || c_param_type || '.' || c_duration || '.' || c_implicit_names(i),
                  p_office_id         => c_office_id);
      END LOOP;
   END test_store_and_retrieve;
END test_cwms_lock;
/
SHOW ERRORS;
