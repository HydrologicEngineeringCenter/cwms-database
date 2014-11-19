CREATE type gate_setting_obj_t
/**
 * Holds information about a gate setting
 *
 * @see type gate_setting_tab_t
 * @see type gate_change_obj_t
 *
 * @member outlet_location_ref Identifies the gate
 * @member opening             The opening value
 * @member opening_parameter   The opening parameter
 * @member opening_units       The opening unit
 */
AS
  object
  (
  --required
  outlet_location_ref location_ref_t,
  opening binary_double,
  opening_parameter varchar2(49),
  opening_units varchar2(16)
  );
/


create or replace public synonym cwms_t_gate_setting_obj for gate_setting_obj_t;

