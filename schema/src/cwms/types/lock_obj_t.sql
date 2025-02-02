CREATE TYPE lock_obj_t
/**
 * Holds information about a lock at a CWMS project
 *
 * @member project_location_ref Identifies the CWMS project
 * @member lock_location        The location information about the locak
 * @member volume_per_lockage   The volume of water released for each lockage
 * @member volume_units_id      The unit for lockage volume
 * @member lock_width           The width of the lock
 * @member lock_length          The length of the lock
 * @member minimum_draft        The minimum draft for the lock
 * @member normal_lock_lift     The elevation difference between upstream and downstream pools
 * @member units_id             The unit of length, width, draft, and lift
 * @member maximum_lock_lift    The maximum lift the lock can support
 * @member elev_units_id        The unit of the elevation pool values
 * @member elev_closure_high_water_upper_pool The elevation that a lock closes due to high water in the upper pool
 * @member elev_closure_high_water_lower_pool The elevation that a lock closes due to high water in the lower pool
 * @member elev_closure_low_water_upper_pool The elevation that a lock closes due to lower water in the upper pool
 * @member elev_closure_low_water_lower_pool The elevation that a lock closes due to low water in the lower pool
 * @member elev_closure_high_water_upper_pool_warning
 * @member elev_closure_high_water_lower_pool_warning
 * @member chamber_location_description A single chamber, le main, land side aux, river side main, river side aux.
 */
AS
   OBJECT
   (
      project_location_ref location_ref_t, --The project this lock is a child of
      lock_location location_obj_t,        --The location for this lock
      -- the volume of water discharged for one lockage at
      --normal headwater and tailwater elevations.  this volume includes any flushing water.
      volume_per_lockage binary_double, -- Param: Stor.
      volume_units_id VARCHAR2(16),     -- the units of the volume value.
      lock_width binary_double,         -- Param: Width. The width of the lock chamber
      lock_length binary_double,        -- Param: Length. the length of the lock chamber
      minimum_draft binary_double,      -- Param: Depth. the minimum depth of water that is maintained for vessels for this particular lock
      normal_lock_lift binary_double,   -- Param: Height. The difference between upstream pool and downstream pool at normal elevation.
      units_id VARCHAR2(16),            -- the units id used for width, length, draft, and lift.
      maximum_lock_lift binary_double,  -- Param: Height. The maximum lift the lock can support
      elev_units_id VARCHAR2(16),       -- the units of the elevation pool values
      elev_closure_high_water_upper_pool binary_double, -- Param: Elev-Pool. The elevation that a lock closes due to high water in the upper pool
      elev_closure_high_water_lower_pool binary_double, -- Param: Elev-Pool. The elevation that a lock closes due to high water in the lower pool
      elev_closure_low_water_upper_pool binary_double,  -- Param: Elev-Pool. The elevation that a lock closes due to lower water in the upper pool
      elev_closure_low_water_lower_pool binary_double,  -- Param: Elev-Pool. The elevation that a lock closes due to low water in the lower pool
      elev_closure_high_water_upper_pool_warning binary_double,
      elev_closure_high_water_lower_pool_warning binary_double,
      chamber_location_description lookup_type_obj_t -- A single chamber, le main, land side aux, river side main, river side aux.
   );
/


create or replace public synonym cwms_t_lock_obj for lock_obj_t;

