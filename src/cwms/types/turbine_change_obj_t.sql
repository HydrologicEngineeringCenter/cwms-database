CREATE type turbine_change_obj_t
/**
 * Holds information about a turbine change at a CWMS project
 *
 * @see type tubine_change_tab_t
 *
 * @member project_location_ref         Identifies the project
 * @member change_date                  The date/time of the turbine change
 * @member discharge_computation        The discharge computation used for the turbine change
 * @member setting_reason               The reason for the turbine change
 * @member settings                     The individual turbine settings
 * @member elev_pool                    The pool elevation at the time of the turbine change
 * @member elev_tailwater               The tailwater elevation at the time of the turbine change
 * @member elev_units                   The elevation unit
 * @member old_total_discharge_override The total discharge before the turbine change
 * @member new_total_discharge_override The total discharge after the turbine change
 * @member discharge_units              The discharge unit
 * @member change_notes                 Notes about the turbine change
 * @member protected                    A flag ('T' or 'F') specifying whether the turbine change is protected from future updates
 */
AS
  object
  (
      --required
      project_location_ref location_ref_t, --PROJECT_LOCATION_CODE
      change_date date, --xxx_CHANGE_DATE
      
      discharge_computation lookup_type_obj_t, --turbine_discharge_comp_code
      setting_reason lookup_type_obj_t, --turbine_setting_reason_code
      
      settings turbine_setting_tab_t,
      --not required 
      elev_pool binary_double,
      elev_tailwater binary_double,
      elev_units varchar2(16),
      old_total_discharge_override binary_double, --OLD_TOTAL_DISCHARGE_OVERRIDE
      new_total_discharge_override binary_double, --NEW_TOTAL_DISCHARGE_OVERRIDE
      discharge_units  varchar2(16), 
      change_notes VARCHAR2(255 BYTE), --GATE_CHANGE_NOTES
      protected varchar2(1) --PROTECTED_FLAG
);
/


create or replace public synonym cwms_t_turbine_change_obj for turbine_change_obj_t;

