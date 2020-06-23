insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCK', null,
'
/**
 * Displays AV_LOCK information
 *
 * @since CWMS 2.1
 *
 * @field lock_id                    The..
 * @field project_id                 The..
 * @field lock_location_code         The location_code of the lock
 * @field project_location_code      The location_code of the project
 * @field unit_system                The..
 * @field length_unit_id             The..
 * @field volume_unit_id             The..
 * @field lock_length                The..
 * @field lock_width                 The..
 * @field volume_per_lockage         The..
 * @field minimum_draft              The..
 * @field normal_lock_lift           The..
 * @field db_office_id               The database office ID of the lock
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
   db_office_id
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
         loc1.db_office_id
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

create or replace public synonym cwms_v_lock for av_lock;

