CREATE TYPE characteristic_tab_t
/**
 * Holds a table of characteristics
 *
 * @see type characteristic_obj_t
 */
IS
  TABLE OF characteristic_obj_t;
/


create or replace public synonym cwms_t_characteristic_tab for characteristic_tab_t;

