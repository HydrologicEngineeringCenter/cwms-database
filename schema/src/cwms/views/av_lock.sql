insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCK', null,
'
/**
 * Displays AV_LOCK information
 *
 * @since CWMS 2.1
 *
 * @field lock_id                                         The name of the lock location physical identifier.
 * @field project_id                                      The name of the project location that this lock is part of.
 * @field lock_location_code                              The location_code of the lock
 * @field project_location_code                           The location_code of the project
 * @field unit_system                                     The unit system for the values and units
 * @field length_unit_id                                  The units of length values
 * @field volume_unit_id                                  The units of volume values
 * @field lock_length                                     The length of the lock chamber
 * @field lock_width                                      The width of the lock chamber
 * @field volume_per_lockage                              The volume of water discharged for one lockage at normal headwater and tailwater elevations.  This volume includes any flushing water.
 * @field minimum_draft                                   The minimum depth of water that is maintained for vessels for this particular lock
 * @field normal_lock_lift                                The normal lift the lock can support
 * @field db_office_id                                    The database office ID of the lock
 * @field maximum_lock_lift                               The maximum lift the lock can support
 * @field elev_unit_id                                    The units of elevation pool values
 * @field elev_closure_high_water_upper_pool              The elevation that a lock closes due to high water in the upper pool
 * @field elev_closure_high_water_lower_pool              The elevation that a lock closes due to high water in the lower pool
 * @field elev_closer_low_water_upper_pool                The elevation that a lock closes due to lower water in the upper pool
 * @field elev_closure_low_water_lower_pool               The elevation that a lock closes due to low water in the lower pool
 * @field elev_closure_high_water_upper_pool_warning      The warning level elevation that a lock closes due to high water in the upper pool
 * @field elev_closure_high_water_lower_pool_warning      The warning level elevation that a lock closes due to high water in the upper pool
 * @field chamber_location_description_code                    A single chamber, land side main, land side aux, river side main, river side aux.
 */
');
create or replace force view av_lock(
   lock_id,
   project_id,
   lock_location_code,
   project_location_code,
   unit_system,
   length_unit_id,
   volume_unit_id,
   lock_length,
   lock_width,
   volume_per_lockage,
   minimum_draft,
   normal_lock_lift,
   db_office_id,
   maximum_lock_lift,
   elev_unit_id,
   elev_closure_high_water_upper_pool,
   elev_closure_high_water_lower_pool,
   elev_closure_low_water_upper_pool,
   elev_closure_low_water_lower_pool,
   elev_closure_high_water_upper_pool_warning,
   elev_closure_high_water_lower_pool_warning,
   chamber_location_description_code
   )
as
    select loc1.location_id as lock_id,
        loc2.location_id as project_id,
        loc1.location_code as lock_location_code,
        loc2.location_code as project_location_code,
        loc1.unit_system,
        cwms_display.retrieve_user_unit_f('Length', loc1.unit_system) as length_unit_id,
        cwms_display.retrieve_user_unit_f('Volume', loc1.unit_system) as volume_unit_id,
        cwms_util.convert_units(
            lck.lock_length,
            cwms_util.get_default_units('Length', 'SI'),
            cwms_display.retrieve_user_unit_f('Length-Lock', loc1.unit_system))
            as lock_length,
        cwms_util.convert_units(
            lck.lock_width,
            cwms_util.get_default_units('Length', 'SI'),
            cwms_display.retrieve_user_unit_f('Width-Lock', loc1.unit_system))
            as lock_width,
        cwms_util.convert_units(
            lck.volume_per_lockage,
            cwms_util.get_default_units('Volume', 'SI'),
            cwms_display.retrieve_user_unit_f('Volume-Lock', loc1.unit_system))
            as volume_per_lockage,
        cwms_util.convert_units(
             lck.minimum_draft,
             cwms_util.get_default_units('Length', 'SI'),
             cwms_display.retrieve_user_unit_f('Depth-Draft', loc1.unit_system))
             as minimum_draft,
        cwms_util.convert_units(
            lck.normal_lock_lift,
            cwms_util.get_default_units('Length', 'SI'),
            cwms_display.retrieve_user_unit_f('Height-Lift', loc1.unit_system))
            as normal_lock_lift,
          loc1.db_office_id,
        cwms_util.convert_units(
            lck.maximum_lock_lift,
            cwms_util.get_default_units('Length', 'SI'),
            cwms_display.retrieve_user_unit_f('Height-Lift', loc1.unit_system))
            as maximum_lock_lift,
        cwms_display.retrieve_user_unit_f('Elev', loc1.unit_system) as elev_unit_id,
        cwms_util.convert_units(
            cwms_lock.get_pool_level_value(lck.lock_location_code, 'High Water Upper Pool'),
            cwms_util.get_default_units('Elev', 'SI'),
            cwms_display.retrieve_user_unit_f('Elev-Pool', loc1.unit_system))
        as elev_closure_high_water_upper_pool,
        cwms_util.convert_units(
            cwms_lock.get_pool_level_value(lck.lock_location_code, 'High Water Lower Pool'),
            cwms_util.get_default_units('Elev', 'SI'),
            cwms_display.retrieve_user_unit_f('Elev-Pool', loc1.unit_system))
        as elev_closure_high_water_lower_pool,
        cwms_util.convert_units(
            cwms_lock.get_pool_level_value(lck.lock_location_code, 'Low Water Upper Pool'),
            cwms_util.get_default_units('Elev', 'SI'),
            cwms_display.retrieve_user_unit_f('Elev-Pool', loc1.unit_system))
        as elev_closure_low_water_upper_pool,
        cwms_util.convert_units(
            cwms_lock.get_pool_level_value(lck.lock_location_code, 'Low Water Lower Pool'),
            cwms_util.get_default_units('Elev', 'SI'),
            cwms_display.retrieve_user_unit_f('Elev-Pool', loc1.unit_system))
        as elev_closure_low_water_lower_pool,
        cwms_util.convert_units(
            cwms_lock.get_pool_level_value(lck.lock_location_code, 'High Water Upper Pool') - 0.6096, --2ft buffer is 0.6096 meters
            cwms_util.get_default_units('Elev', 'SI'),
            cwms_display.retrieve_user_unit_f('Elev-Pool', loc1.unit_system))
                as elev_closure_high_water_upper_pool_warning,
        cwms_util.convert_units(
            cwms_lock.get_pool_level_value(lck.lock_location_code, 'High Water Lower Pool') - 0.6096, --2ft buffer is 0.6096 meters
            cwms_util.get_default_units('Elev', 'SI'),
            cwms_display.retrieve_user_unit_f('Elev-Pool', loc1.unit_system))
                as elev_closure_high_water_lower_pool_warning,
        lck.chamber_location_description_code
     from cwms_v_loc2 loc1, cwms_v_loc2 loc2, at_lock lck
    where loc1.location_code = lck.lock_location_code
      and loc2.location_code = lck.project_location_code
      and loc2.unit_system = 'EN'
/

begin
	execute immediate 'grant select on av_lock to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_lock for av_lock;

