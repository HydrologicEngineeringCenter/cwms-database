CREATE TYPE turbine_setting_tab_t
/**
 * Holds information about a collection of turbine settings
 *
 * @see type turbine_setting_obj_t
 * @see type turbine_change_obj_t
 */
is
  TABLE OF turbine_setting_obj_t;
/


create or replace public synonym cwms_t_turbine_setting_tab for turbine_setting_tab_t;

