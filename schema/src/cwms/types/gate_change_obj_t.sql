CREATE type gate_change_obj_t
/**
 * Holds information about a gate change at a CWMS project
 *
 * @see type gate_change_tab_t
 *
 * @member project_location_ref         Identifies the project
 * @member change_date                  The date/time of the gate change
 * @member elev_pool                    The pool elevation at the time of the gate change
 * @member discharge_computation        The type of discharge computation used
 * @member release_reason               The reason for the gate change
 * @member settings                     Settings of individual gates
 * @member elev_tailwater               The tailwater elevation at the time of the gate change
 * @member elev_units                   The elevation unit
 * @member old_total_discharge_override The discharge before the gate change
 * @member new_total_discharge_override The discharge after the gate change
 * @member discharge_units              The discharge unit
 * @member change_notes                 Notes about the gate change
 * @member protected                    A flag ('T' or 'F') specifying whether this gate change is protected from future updates
 * @member reference_elev               An additional reference elevation if required to describe this gate change
 */
AS
  object
  (
      --required
      project_location_ref location_ref_t, --PROJECT_LOCATION_CODE
      change_date date, --GATE_CHANGE_DATE
      elev_pool binary_double, --ELEV_POOL
      discharge_computation lookup_type_obj_t, --DISCHARGE_COMPUTATION_CODE
      release_reason lookup_type_obj_t, --release_reason_code
      settings gate_setting_tab_t,
      --not required
      elev_tailwater binary_double, --ELEV_TAILWATER
      elev_units varchar2(16), 
      old_total_discharge_override binary_double, --OLD_TOTAL_DISCHARGE_OVERRIDE
      new_total_discharge_override binary_double, --NEW_TOTAL_DISCHARGE_OVERRIDE
      discharge_units  varchar2(16), 
      change_notes VARCHAR2(255 BYTE), --GATE_CHANGE_NOTES
      protected varchar2(1), --PROTECTED_FLAG
      reference_elev binary_double
);
/


create or replace public synonym cwms_t_gate_change_obj_t for gate_change_obj_t;

