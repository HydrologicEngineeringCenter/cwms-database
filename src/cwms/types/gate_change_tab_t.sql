CREATE TYPE gate_change_tab_t
/**
 * Holds information on a collection of gate changes
 *
 * @see type gate_change_obj_t
 */
is
  TABLE OF gate_change_obj_t;
/


create or replace public synonym cwms_t_gate_change_tab for gate_change_tab_t;

