CREATE TYPE water_user_contract_tab_t
/**
 * Holds a collection of water_user_contract_obj_t objects
 *
 * @see type water_user_contract_obj_t
 */
IS
  TABLE OF water_user_contract_obj_t;
/


create or replace public synonym cwms_t_water_user_contract_tab for water_user_contract_tab_t;

