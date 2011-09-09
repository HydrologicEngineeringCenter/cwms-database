CREATE OR REPLACE PACKAGE cwms_water_supply
/**
 * Facilities for working with water supply users, contracts, and accounting
 *
 * @author Peter Morris
 *
 * @since CWMS 2.1
 */
IS
/**
 * Retrieves a catalog of all water users matching specified parameters.  Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_cursor  A cursor containing all matching water users.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">project_office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">project_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">entity_name</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The water user</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">water_right</td>
 *     <td class="descr">varchar2(255)</td>
 *     <td class="descr">The water right for the water user</td>
 *   </tr>
 * </table>
 *
 * @param p_project_id_mask  The project location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_db_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 */
PROCEDURE cat_water_user(
    -- described above
    p_cursor OUT sys_refcursor,
    -- a mask to limit the query to certain projects.
    p_project_id_mask IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    -- the office id can use sql masks for retrieval of additional offices.
    p_db_office_id_mask IN VARCHAR2 DEFAULT NULL );
/**
 * Retrieves a catalog of all water user contracts matching specified parameters.  Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_cursor  A cursor containing all matching water user contracts.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">project_office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">project_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the project</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">entity_name</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The water user</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">contract name</td>
 *     <td class="descr">varchar2(255)</td>
 *     <td class="descr">The water right for the water user</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">contracted storage</td>
 *     <td class="descr">binary double</td>
 *     <td class="descr">The amount of storage under contract</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">contract type</td>
 *     <td class="descr">varchar2(25)</td>
 *     <td class="descr">The water supply contract type</td>
 *   </tr>
 * </table>
 *
 * @param p_project_id_mask  The project location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_entity_name_mask  The water user pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_db_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 */
PROCEDURE cat_water_user_contract(
    -- described above
    p_cursor OUT sys_refcursor,
    -- a mask to limit the query to certain projects.
    p_project_id_mask IN VARCHAR2 DEFAULT NULL,
    -- a mask to limit the query to certain entities.
    p_entity_name_mask IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    -- the office id can use sql masks for retrieval of additional offices.
    p_db_office_id_mask IN VARCHAR2 DEFAULT NULL );
/**
 * Retrieve water users for a specified project
 *
 * @param p_water_users The collection of water users for the specified project
 *
 * @param p_project_location_ref The project to retieve the water users for
 */
PROCEDURE retrieve_water_users(
    --returns a filled set of objects including location ref data
    p_water_users OUT water_user_tab_t,
    -- a project location refs that identify the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t );
/**
 * Stores (inserts or updates) a water user
 *
 * @param p_water_user     The water user to store
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the specified water user already exists
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified water user already exists
 */
PROCEDURE store_water_user(
    p_water_user IN water_user_obj_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Stores (inserts or updates) a collection of water users
 *
 * @param p_water_user     The water users to store
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if one of the specified water user already exists
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the one of specified water user already exists
 */
PROCEDURE store_water_users(
    p_water_users IN water_user_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Deletes a water user from a specified project
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_project_location_ref The project to delete the water user from
 * @param p_entity_name          The water user to delete
 * @param p_delete_action        Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the water user, and then only if it has no other data refers to it</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only data that refers to the water user, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the water user and all data that refers to it, if any</td>
 *   </tr>
 * </table>
 */
PROCEDURE delete_water_user(
    -- project location ref.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t,
    p_entity_name          IN VARCHAR,
    -- the water user entity name.
    -- delete key will fail if there are references.
    -- delete all will also delete the referring children.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key );
/**
 * Renames a water user for a specified project
 *
 * @param p_project_location_ref The project to rename the water user for
 * @param p_entity_old_name      The existing water user name
 * @param p_entity_new_name      The new water user name
 */
PROCEDURE rename_water_user(
    -- project location ref.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t,
    p_entity_name_old      IN VARCHAR2,
    p_entity_name_new      IN VARCHAR2 );
/**
 * Retrieves all water supply contracts for a specified project and water user
 *
 * @param p_contracts            The retrieved water supply contracts
 * @param p_project_location_ref The project to retrieve contracts for
 * @param p_entity_name          The water user to retrieve contracts for
 */
PROCEDURE retrieve_contracts(
    p_contracts OUT water_user_contract_tab_t,
    -- a project location refs that identify the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t,
    p_entity_name          IN VARCHAR2 );
/**
 * Stores a set of water supply contracts to the database
 *
 * @param p_contracts      The contracts to store
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if one of the contracts already exists
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the contracts already exists
 */
PROCEDURE store_contracts(
    p_contracts IN water_user_contract_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Deletes a water supply contract from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_contract_ref  The contract to delete
 *
 * @param p_delete_action        Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the water user, and then only if it has no other data refers to it</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only data that refers to the water user, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the water user and all data that refers to it, if any</td>
 *   </tr>
 * </table>
 */
PROCEDURE delete_contract(
    -- contains the identifying parts of the contract to delete.
    p_contract_ref IN water_user_contract_ref_t,
    -- delete key will fail if there are references.
    -- delete all will also delete the referring children.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key );
/**
 * Renames a water supply contract in the database
 *
 * @param p_water_user_contract The water supply contract to rename
 * @param p_old_contract_name   The existing contract name
 * @param p_new_contract_name   The new contract name
 */
PROCEDURE rename_contract(
    p_water_user_contract IN water_user_contract_ref_t,
    p_old_contract_name   IN VARCHAR2,
    p_new_contract_name   IN VARCHAR2 );
/**
 * Retrieves the set of water supply contract types for the specified office
 *
 * @param p_contract_types The retrieved contract
 * @param p_db_office_id   The office to retrieve the contract types for. If not specified or NULL, the session user's default office will be used.
 */
PROCEDURE get_contract_types(
    p_contract_types OUT lookup_type_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
/**
 * Stores (inserts or updates) a set of contract types
 *
 * @param p_contract_types The contract types to store
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies that the routine should fail if one of the contract types already exists
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and one of the contract types already exists
 */
PROCEDURE set_contract_types(
    p_contract_types IN lookup_type_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
/**
 * Retrieves water supply accounting records for a specified contract and time winow
 *
 * @param p_accounting_set  The retrieved accounting records
 * @param p_contract_ref    The contract to retrieve the records for
 * @param p_units           The flow unit to use in the retreived accounting records
 * @param p_start_time      The beginning of the time window
 * @param p_end_time        The end of the time window
 * @param p_time_zone       The time zone to use for the parameters and account records
 * @param p_start_inclusive A flag ('T' or 'F') specifying whether the time window begins on ('T') or after ('F') p_start_time
 * @param p_end_inclusive   A flag ('T' or 'F') specifying whether the time window ends on ('T') or before ('F') p_end_time
 * @param p_ascending_flag  A flag ('T' or 'F') specifying whether the accounting records are sorted in ascending date order
 * @param p_row_limit       The maximum number of records to retrieve even if the time window is not filled
 * @param p_transfer type   Reserved for future use. Not implemented
 */
PROCEDURE retrieve_accounting_set(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,

    -- the water user contract ref, does this need to be the project instead?
    p_contract_ref IN water_user_contract_ref_t,
    
    -- the units to return the flow as.
    p_units IN VARCHAR2,
    --time window stuff
    -- the transfer start date time
    p_start_time IN DATE,
    -- the transfer end date time
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
    
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    
    -- limit on the number of rows returned
    p_row_limit IN INTEGER DEFAULT NULL,
    
    -- a mask for the transfer type.
    -- if null, return all transfers.
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  );
-- not documented
PROCEDURE retrieve_pump_accounting(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,

    -- the water user contract ref
    p_contract_code in number,
    -- the water user contract ref
    p_contract_ref IN water_user_contract_ref_t,
    
    p_pump_loc_code IN number,
    
    -- the units to return the flow as.
    p_units IN VARCHAR2,
    --time window stuff
    -- the transfer start date time
    p_start_time IN DATE,
    -- the transfer end date time
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
    
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    
    -- limit on the number of rows returned
    p_row_limit IN integer DEFAULT NULL,
    
    -- a mask for the transfer type.
    -- if null, return all transfers.
    -- do we need this?
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  );
/**
 * Stores a set of water supply account records to the database
 *
 * @param p_accounting_tab       The water accounting records to store
 * @param p_contract_ref         The contract to store the accounting records for
 * @param p_pump_time_window_tab The time window to clear of all accounting records before storing
 * @param p_time_zone            The time zone for the time window and accounting records
 * @param p_flow_unit_id         The flow unit for the accounting records
 * @param p_store_rule           Reserved for future use   Not implemented
 * @param p_override_prot        Reserved for future use.  Not implemented
 */
PROCEDURE store_accounting_set(
    -- the set of water user contract accountings to store to the database.
    p_accounting_tab IN wat_usr_contract_acct_tab_t,

    -- the contract ref for the incoming accountings.
    p_contract_ref IN water_user_contract_ref_t,
    
    --the following represents pump time windows where data needs to be cleared
    --out as part of the delete insert process.
    p_pump_time_window_tab loc_ref_time_window_tab_t,

    -- the time zone of all of the incoming data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,    
    
    -- the units of the incoming accounting flow data
    p_flow_unit_id IN VARCHAR2 DEFAULT NULL,    

		-- store rule, this variable is not supported. 
    -- only delete insert initially supported.
    p_store_rule		IN VARCHAR2 DEFAULT NULL,

    -- if protection is to be ignored.
    -- this variable is not supported.
		p_override_prot	in varchar2 default 'F'
    );





END CWMS_WATER_SUPPLY;
/
show errors;
GRANT EXECUTE ON CWMS_WATER_SUPPLY TO CWMS_USER;