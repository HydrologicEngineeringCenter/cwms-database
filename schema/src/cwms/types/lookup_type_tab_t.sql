CREATE TYPE lookup_type_tab_t
/**
 * Holds a collection of lookup_type_obj_t objects
 *
 * @see type lookup_type_obj_t
 */
IS
  TABLE OF lookup_type_obj_t;
/


create or replace public synonym cwms_t_lookup_type_tab for lookup_type_tab_t;

