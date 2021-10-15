CREATE TYPE water_user_obj_t
/**
 * Holds information about a water user for a CWMS project
 *
 * @see type water_user_tab_t
 *
 * @member project_location_ref Identifies the CWMS project
 * @member entity_name          The name of the water user
 * @member water_right          The water right for the water user at this project
 */
AS
  OBJECT
  (
    project_location_ref location_ref_t, --The project that this user is pertaining to.
    entity_name VARCHAR2(64 BYTE),       --The entity name associated with this user
    water_right VARCHAR2(255 BYTE)       --The water right of this user (optional)
  );
/


create or replace public synonym cwms_t_water_user_obj for water_user_obj_t;

