CREATE type wat_usr_contract_acct_obj_t
/**
 * Holds a water user contract accounting record
 *
 * @see type wat_usr_contract_acct_tab_t
 *
 * @member water_user_contract_ref Identifies the water user contract
 * @member pump_location_ref       The location of the pump for this accounting record
 * @member physical_transfer_type  Identifies the type of water transfer for this accounting record
 * @member pump_flow               The pump flow for this accounting record
 * @member transfer_start_datetime The beginning time for the water transfer for this accounting record
 * @member accounting_remarks      Remarks for this accounting record
 */
AS
  object
  (
    water_user_contract_ref water_user_contract_ref_t,--The contract for this water movement. SEE AT_WATER_USER_CONTRACT.
    pump_location_ref location_ref_t, --the contract pump that was used for this accounting.
    physical_transfer_type lookup_type_obj_t,         --The type of transfer for this water movement.  See AT_PHYSICAL_TRANSFER_TYPE_CODE.
    pump_flow binary_double,                  --Param: Flow. The flow associated with the water accounting record
    transfer_start_datetime date,                     --The date this water movement began, DATE includes the time zone.
    accounting_remarks varchar2(255 byte)             --Any comments regarding this water accounting movement
  );
/


create or replace public synonym cwms_t_wat_usr_cntrct_acct_obj for wat_usr_contract_acct_obj_t;

