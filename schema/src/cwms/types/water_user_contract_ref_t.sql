CREATE TYPE water_user_contract_ref_t
/**
 * Holds minimal information about a water user contract
 *
 * @see water_user_contract_obj_t
 *
 * @member water_user    The water user
 * @member contract_name The identifier for the water user contract
 */
AS
  OBJECT
  (
    water_user water_user_obj_t,   --The water user this record pertains to.  See table AT_WATER_USER.
    contract_name VARCHAR2(64 BYTE)--The identification name for the contract for this water user contract
  );
/


create or replace public synonym cwms_t_water_user_contract_ref for water_user_contract_ref_t;

