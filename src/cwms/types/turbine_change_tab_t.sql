CREATE TYPE turbine_change_tab_t
/**
 * Holds a collection of turbine changes
 *
 * @see type turbine_change_obj_t
 */
is
  TABLE OF turbine_change_obj_t;
/


create or replace public synonym cwms_t_turbine_change_tab for turbine_change_tab_t;

