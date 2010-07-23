WHENEVER sqlerror EXIT sql.sqlcode
  --------------------------------------------------------------------------------
  -- package cwms_water_supply.
  -- used to manipulate the tables at_water_user, at_water_user_contract,
  -- at_wat_usr_contract_accounting, at_xref_wat_usr_contract_docs.
  -- also manipulates at_document.
  --------------------------------------------------------------------------------
CREATE OR REPLACE
PACKAGE cwms_water_supply
IS
  --------------------------------------------------------------------------------
  -- procedure cat_water_user
  -- returns a catalog of water users.
  --
  -- security: can be called by user and dba group.
  --
  -- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
  -- Changing them will end up breaking external code (so make any changes prior
  -- to development).
  -- The returned records contain the following columns:
  --
  --    Name                      Datatype      Description
  --    ------------------------ ------------- ----------------------------
  --    project_office_id         varchar2(32)  the office id of the parent project.
  --    project_id                varchar2(32)   the identification (id) of the parent project.
  --    entity_name               varchar2
  --    water_right               varchar2
  --
  --------------------------------------------------------------------------------
  -- errors will be thrown as exceptions
  --
PROCEDURE cat_water_user(
    -- described above
    p_cursor OUT sys_refcursor,
    -- a mask to limit the query to certain projects.
    p_project_id_mask IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    -- the office id can use sql masks for retrieval of additional offices.
    p_db_office_id_mask IN VARCHAR2 DEFAULT NULL );
  --------------------------------------------------------------------------------
  -- procedure cat_water_user_contract
  -- returns a catalog of water user contracts.
  --
  -- security: can be called by user and dba group.
  --
  -- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
  -- Changing them will end up breaking external code (so make any changes prior
  -- to development).
  -- The returned records contain the following columns:
  --
  --    Name                      Datatype      Description
  --    ------------------------ ------------- ----------------------------
  --    project_office_id         varchar2(32)  the office id of the parent project.
  --    project_id                varchar2(32)  the identification (id) of the parent project.
  --    entity_name               varchar2
  --    contract_name             varchar2
  --    contracted_storage        varchar2
  --    contract_type             varchar2      the display value of the lookup.
  --
  --------------------------------------------------------------------------------
  -- errors will be thrown as exceptions
  --
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
  --------------------------------------------------------------------------------
  -- Returns a set of water users for a given project. Returned data is encapsulated
  -- in a table of water user oracle types.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_water_users(
    --returns a filled set of objects including location ref data
    p_water_users OUT water_user_tab_t,
    -- a project location refs that identify the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t );
  --------------------------------------------------------------------------------
  -- store a set of water users.
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
PROCEDURE store_water_users(
    water_user IN water_user_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  --------------------------------------------------------------------------------
  --deletes the water user identified by the project location ref and entity name.
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
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
  --------------------------------------------------------------------------------
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
PROCEDURE rename_water_user(
    -- project location ref.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t,
    p_entity_name_old      IN VARCHAR2,
    p_entity_name_new      IN VARCHAR2 );
  --------------------------------------------------------------------------------
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
  -- water user contract procedures.
PROCEDURE retrieve_contracts(
    p_contracts OUT water_user_contract_tab_t,
    -- a project location refs that identify the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t,
    p_entity_name          IN VARCHAR2 );
  --------------------------------------------------------------------------------
  -- stores a set of water user contracts.
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
PROCEDURE store_contracts(
    p_contracts IN water_user_contract_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
--------------------------------------------------------------------------------
-- deletes the water user contract associated with the argument ref.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
PROCEDURE delete_contract(
    -- contains the identifying parts of the contract to delete.
    p_contract_ref IN water_user_contract_ref_t,
    -- delete key will fail if there are references.
    -- delete all will also delete the referring children.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key );
  --------------------------------------------------------------------------------
  -- renames the water user contract associated with the water user arg from
  -- the old contract name to the new contract name.
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
PROCEDURE rename_contract(
    p_water_user        IN water_user_obj_t,
    p_old_contract_name IN VARCHAR2,
    p_new_contract_name IN VARCHAR2 );
  --------------------------------------------------------------------------------
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
  -- look up procedures.
  -- returns a listing of lookup objects.
PROCEDURE get_contract_types(
    p_lookup_type_tab_t OUT lookup_type_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
  --------------------------------------------------------------------------------
  -- errors preventing the return of data will be issued as a thrown exception
  --------------------------------------------------------------------------------
  -- inserts or updates a set of lookups.
  -- if a lookup does not exist it will be inserted.
  -- if a lookup already exists and p_fail_if_exists is false, the existing
  -- lookup will be updated.
  --
  -- a failure will cause the whole set of lookups to not be stored.
PROCEDURE set_contract_types(
    p_lookup_type_tab_t IN lookup_type_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  --------------------------------------------------------------------------------
  -- water supply accounting
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  -- store a water user contract accounting set.
  --------------------------------------------------------------------------------
PROCEDURE store_accounting_set(
    -- the set of water user contract accountings to store to the database.
    p_accounting_set IN wat_usr_contract_acct_tab_t,
    
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  --------------------------------------------------------------------------------
  -- retrieve a water user contract accounting set.
  --------------------------------------------------------------------------------
PROCEDURE retrieve_accounting_set(
    -- the retrieved set of water user contract accountings
    p_accounting_set OUT wat_usr_contract_acct_tab_t,
    -- a series of masks for the following attributes.
    -- p_db_office_id,
    -- p_project_id,
    -- p_entity_name,
    -- p_contract_name
    p_contract_ref IN water_user_contract_ref_t,
    -- a mask for the transfer type.
    -- if null, return all transfers.
    p_transfer_type IN VARCHAR2 DEFAULT NULL,
    -- the units to return the volume as.
    p_units IN VARCHAR2,
    -- the transfer start date time
    p_start_time IN DATE,
    -- the transfer end date time
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT 'UTC',
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive IN VARCHAR2 DEFAULT 'T'
  );
END CWMS_WATER_SUPPLY;
/
show errors;
GRANT EXECUTE ON CWMS_WATER_SUPPLY TO CWMS_USER;