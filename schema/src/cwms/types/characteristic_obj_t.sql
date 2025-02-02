CREATE TYPE characteristic_obj_t
/**
 * Holds information about a characteristic
 *
 * @see type characteristic_ref_t
 * @see type characteristic_tab_t
 *
 * @member characteristic_ref  Identifies the characteristic
 * @member general_description Describes the characteristic
 */
AS
  OBJECT
  (
    characteristic_ref characteristic_ref_t, -- office id and characteristic id
--    opening_parameter_id VARCHAR2 (16),             -- A foreign key to an AT_PARAMETER record that constrains the gate opening to a defined parameter and unit.
--    height BINARY_DOUBLE,                           -- The height of the gate
--    width binary_double,                            -- The width of the gate
--    opening_radius binary_double,                   -- The radius of the pipe or circular conduit that this outlet is a control for.  This is not applicable to rectangular outlets, tainter gates, or uncontrolled spillways
--    opening_units_id VARCHAR2(16),                  -- the units of the opening radius value.
--    elev_invert binary_double,                      -- The elevation of the invert for the outlet
--    flow_capacity_max BINARY_DOUBLE,                --  The maximum flow capacity of the gate
--    flow_units_id VARCHAR2(16),                     -- the units of the flow value.
--    net_length_spillway binary_double,              -- The net length of the spillway
--    spillway_notch_length binary_double,            -- The length of the spillway notch
--    length_units_id            VARCHAR2(16),                   -- the units of the height, width, and length.
    general_description VARCHAR2(255)                   -- description of the outlet characteristic
  );
/


create or replace public synonym cwms_t_characteristic_obj for characteristic_obj_t;

