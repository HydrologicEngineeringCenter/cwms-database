CREATE TYPE project_structure_tab_t
/**
 * Holds a collection of project_structure_obj_t objects
 *
 * @see type project_structure_obj_t
 */
IS
  TABLE OF project_structure_obj_t;
/


create or replace public synonym cwms_t_project_structure_tab for project_structure_tab_t;

