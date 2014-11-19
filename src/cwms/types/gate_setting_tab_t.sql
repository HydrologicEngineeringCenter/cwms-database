CREATE TYPE gate_setting_tab_t
/**
 * Holds a collection of gate settings
 *
 * @see type gate_setting_obj_t
 * @see type gate_change_obj_t
 */
is
  TABLE OF gate_setting_obj_t;
/


create or replace public synonym cwms_t_gate_setting_tab for gate_setting_tab_t;

