CREATE TYPE water_user_tab_t
/**
 * Hold a collection of water_user_obj_t objects
 *
 * @see type water_uer_obj_t
 */
IS
  TABLE OF water_user_obj_t;
/


create or replace public synonym cwms_t_water_user_tab for water_user_tab_t;

