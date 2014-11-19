CREATE TYPE embankment_tab_t
/**
 * Holds a collection of embankment_obj_t objects
 *
 * @see type embankment_obj_t
 */
IS
  TABLE OF embankment_obj_t;
/


create or replace public synonym cwms_t_embankment_tab for embankment_tab_t;

