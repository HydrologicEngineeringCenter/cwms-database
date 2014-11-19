CREATE TYPE characteristic_ref_t
/**
 * Identifies a characteristic
 *
 * @member office_id         The office that owns the characteristic
 * @member characteristic_id The characteristic identifier
 */
AS
  OBJECT
  (
    office_id         VARCHAR2 (16), -- the office id for this ref
    characteristic_id VARCHAR2 (64)  -- the id of this characteristic.
  );
/


create or replace public synonym cwms_t_characteristic_ref for characteristic_ref_t;

