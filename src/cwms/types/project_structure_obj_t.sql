CREATE TYPE project_structure_obj_t
/**
 * Holds information about a structure at a CWMS project
 *
 * @see type project_structure_tab_t
 *
 * @member project_location_ref Identifies the project
 * @member structure_location   The location information about structure
 * @member characteristic_ref   Identifies the characteristic
 */
AS
  OBJECT
  (
    project_location_ref location_ref_t,           --The project this structure is a child of
    structure_location location_obj_t,                  --The location for this structure
    characteristic_ref characteristic_ref_t   -- the characteristic for this structure.
  );
/


create or replace public synonym cwms_t_project_structure_obj for project_structure_obj_t;

