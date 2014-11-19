CREATE type water_user_contract_obj_t
/**
 * Holds information about a water user contract
 *
 * @see type water_user_contract_ref_t
 * @see type water_user_contract_tab_t
 *
 * @member water_user_contract_ref       Identifies the water user and contract
 * @member water_supply_contract_type    The type of water supply contract
 * @member ws_contract_effective_date    The effective date of the contract
 * @member ws_contract_expiration_date   The expiration date of the contract
 * @member contracted_storage            The storage under contract
 * @member initial_use_allocation        The initial storage allocation for this contract
 * @member future_use_allocation         The future storage allocation for this contract
 * @member storage_units_id              The unit for storage
 * @member future_use_percent_activated  The percentage of the future storage allocation that has been utilized
 * @member total_alloc_percent_activated The percentage of the total storage allocation that has been utilized
 * @member pump_out_location             The location where water is withrawn from the project, if any
 * @member pump_out_below_location       The location where water is withdrawn below the project, if any
 * @member pump_in_location              The location where water is pumped in to the project, if any
 */
AS
  object
  (
    water_user_contract_ref water_user_contract_ref_t,
    -- contract_documents VARCHAR2(64 BYTE),--The documents for the contract
    water_supply_contract_type lookup_type_obj_t, -- The type of water supply contract. FK'ed to a LU table.
    ws_contract_effective_date DATE,              --The start date of the contract for this water user contract
    ws_contract_expiration_date DATE,             --The expiration date for the contract of this water user contract
    contracted_storage BINARY_DOUBLE,             --Param: Stor. The contracted storage amount for this water user contract
    initial_use_allocation BINARY_DOUBLE,         --Param: Stor. The initial contracted allocation for this water user contract
    future_use_allocation BINARY_DOUBLE,          --Param: Stor. The future contracted allocation for this water user contract
    storage_units_id VARCHAR2(15),                -- the units used for contracted storage and allocations.
    future_use_percent_activated BINARY_DOUBLE,   --Param: ??. The percent allocated future use for this water user contract
    total_alloc_percent_activated BINARY_DOUBLE,  --Param: ??. The percentage of total allocation for this water user contract
    pump_out_location location_obj_t,             -- used to be withdrawal
    pump_out_below_location location_obj_t,       -- used to be supply
    pump_in_location location_obj_t               
  );
/


create or replace public synonym cwms_t_water_user_contract_obj for water_user_contract_obj_t;

