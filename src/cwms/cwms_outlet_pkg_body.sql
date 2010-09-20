WHENEVER sqlerror EXIT sql.sqlcode
SET serveroutput ON
CREATE OR REPLACE
PACKAGE BODY CWMS_OUTLET
AS
  -------------------------------------------------------------------------------
  -- CWMS_OUTLET
  --
  -- These procedures and functions query and manipulate outlets and their supporting types
  -- in the CWMS/ROWCPS database.
  --
  -- An outlet will always have a parent project defined in AT_PROJECT.
  -- There can be zero to many outlets for a given project.
  --
  -- Outlets have an associative relationship with "Outlet" Category Location Groups.
  -- An outlet is not required to be in an "Outlet" Location Group.
  --
  -- Outlets are associated a row defined in the AT_OUTLET_CHARACTERISTICS table.
  -- There can be many outlets associated with one characteristic.
  --
  -- Note on DB_OFFICE_ID. DB_OFFICEID in addtion to location id is required to
  -- uniquely identify a location code, so it will be included in all of these calls.
  --
  -- The DB_OFFICE_ID defaults to the connected user's office if null.
  -- p_db_office_id  IN  VARCHAR2 DEFAULT NULL
  -- CWMS has a package proceudure that can be used to determine the office id for
  -- a given user.
  --
  --type definitions:
  -- from cwms_types.sql, location_obj_t and location_ref_t.
  -- from rowcps_types.sql, XXX.
  -- security:
  --
  -------------------------------------------------------------------------------
  --
  --
  --
  --
  -- cat_outlet
  -- returns a summary listing of outlets instended to be used for lists or display.
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
  --    project_office_id        varchar2(32)   the office id of the parent project.
  --    project_id               varchar2(32)   the location id of the parent project.
  --    db_office_id             varchar2(16)   owning office of the outlet location.
  --    base_location_id         varchar2(16)   the outlet base location id
  --    sub_location_id          varchar2(32)   the outlet sub-location id, if defined
  --    time_zone_name           varchar2(28)   local time zone name for outlet location
  --    latitude                 number         outlet location latitude
  --    longitude                number         outlet location longitude
  --    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
  --    elevation                number         outlet location elevation
  --    elev_unit_id             varchar2(16)   outlet location elevation units
  --    vertical_datum           varchar2(16)   veritcal datum of elevation
  --    public_name              varchar2(32)   outlet location public name
  --    long_name                varchar2(80)   outlet location long name
  --    description              varchar2(512)  outlet location description
  --    active_flag              varchar2(1)    'T' if active, else 'F'
  --
  -------------------------------------------------------------------------------
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE cat_outlet(
    --described above.
    p_outlet_cat OUT sys_refcursor,
    -- the project id. if null, return all outlets for the office.
    p_project_id IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    -- the office id can use sql masks for retrieval of additional offices.
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END cat_outlet;
  --
  --
  --
  -- Core outlet procedures and functions.
  --
  --
  --
  -- Returns outlet data for a given outlet location id. Returned data is encapsulated
  -- in an outlet oracle type.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_outlet(
    --returns a filled in object including location data
    p_outlet OUT outlet_obj_t,
    -- a location ref that identifies the object we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_outlet_location_ref IN location_ref_t )
AS
BEGIN
  NULL;
END retrieve_outlet;
--
--
--
-- Returns a set of outlets for a given project. Returned data is encapsulated
-- in a table of outlet oracle types.
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued as a thrown exception
--
PROCEDURE retrieve_outlets(
    --returns a filled set of objects including location data
    p_outlets OUT outlet_tab_t,
    -- a project location ref that identifies the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t )
AS
BEGIN
  NULL;
END retrieve_outlets;
--
--
--
-- Stores the data contained within the outlet object into the database schema.
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE store_outlet(
    -- a populated outlet object type.
    p_outlet IN outlet_obj_t,
    -- a flag that will cause the procedure to fail if the outlet already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
BEGIN
  NULL;
END store_outlet;
--
--
--
-- Stores the data contained within the set of outlet objects into the database schema.
--
-- security: can only be called by dba group.
--
-- This procedure performs both insert and update functionality.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE store_outlets(
    -- a table of populated outlet object types.
    p_outlets IN outlet_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
BEGIN
  NULL;
END store_outlets;
--
--
--
-- Renames an outlet from one id to a new id.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE rename_outlet(
    p_outlet_id_old IN VARCHAR2,
    p_outlet_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END rename_outlet;
--
--
--
-- Performs a delete on an outlet.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE delete_outlet(
    p_outlet_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    -- delete key will fail if there are references to the outlet.
    -- delete all will delete the referring children then the outlet.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  )
AS
BEGIN
  NULL;
END delete_outlet;
--
--
--
-- outlet location group support
--
--
--
-- procedure create_outlet_group
-- creates a "Outlet" category location group
-- security: can only be called by the dba group.
-- errors will be thrown as exceptions.
PROCEDURE create_outlet_group(
    -- the outlet name
    p_loc_group_id IN VARCHAR2,
    -- description of the group
    p_loc_group_desc IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END create_outlet_group;
--
--
--
-- procedure rename_outlet_group
-- renames an existing "Outlet" category location group.
-- security: can only be called by the dba group.
-- errors will be thrown as exceptions.
PROCEDURE rename_outlet_group(
    -- the old group name
    p_loc_group_id_old IN VARCHAR2,
    -- the new group name
    p_loc_group_id_new IN VARCHAR2,
    -- an updated description
    p_loc_group_desc IN VARCHAR2 DEFAULT NULL,
    -- if true, null args should not be processed.
    p_ignore_null IN VARCHAR2 DEFAULT 'T',
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END rename_outlet_group;
--
--
--
-- delete_outlet_group
-- deletes an "Outlet" category location group.
--
PROCEDURE delete_outlet_group(
    -- the location group to delete.
    p_loc_group_id IN VARCHAR2,
    -- delete_key will fail if there are assigned locations.
    -- delete_all will delete all location assignments, then delete the group.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END delete_outlet_group;
--
--
--
-- Assign a location to a "Outlet" category location group. The location id
-- that is being assigned to the group needs to be constrained to location_codes
-- in AT_OUTLET.OUTLET_LOCATION_CODE.
PROCEDURE assign_outlet_group2(
    -- the location group id.
    p_loc_group_id IN VARCHAR2,
    -- the outlet location id
    p_location_id IN VARCHAR2,
    -- the attribute for the outlet location.
    p_loc_attribute IN NUMBER DEFAULT NULL,
    -- the alias for this outlet, this will most likely always be null.
    p_loc_alias_id IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END assign_outlet_group2;
--
--
--
-- Assign a set of outlet locations to the "Outlet" category location group. The location id
-- that is being assigned to the outlet group needs to be constrained to location_codes
-- in AT_OUTLET.OUTLET_LOCATION_CODE.
PROCEDURE assign_outlet_groups2(
    -- the outlet location group id
    p_loc_group_id IN VARCHAR2,
    -- an array of the location ids and extra data to assign to the specified group.
    p_loc_alias_array IN loc_alias_array2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END assign_outlet_groups2;
--
--
--
-- Removes a location from an "Outlet" category location group.
PROCEDURE unassign_outlet_group(
    -- the outlet group id
    p_loc_group_id IN VARCHAR2,
    -- the location id to remove.
    p_location_id IN VARCHAR2,
    -- if unassign is T then all assigned locs are removed from group.
    -- p_location_id needs to be set to null when the arg is T.
    p_unassign_all IN VARCHAR2 DEFAULT 'F',
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END unassign_outlet_group;
--
--
--
-- Removes a set of location ids from an "Outlet" category location group.
PROCEDURE unassign_outlet_groups(
    -- the outet group id.
    p_loc_group_id IN VARCHAR2,
    -- the array of location ids to remove.
    p_location_array IN char_49_array_type,
    -- if T, then all assigned locs are removed from the group.
    -- p_location_array needs to be null when the arg is T.
    p_unassign_all IN VARCHAR2 DEFAULT 'F',
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END unassign_outlet_groups;
--
--
--
--
--
-- outlet characteristic suppport
--
-- returns a listing of outlet characteristics objects.
PROCEDURE retr_outlet_characteristics(
    p_outlet_characteristic_tab_t OUT outlet_characteristic_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END retr_outlet_characteristics;
--
--
--
-- inserts or updates a set of outlet characteristics.
-- if an outlet characteristic does not exist it will be inserted.
-- if an outlet characteristic already exists and p_fail_if_exists is false, the existing
-- record will be updated.
--
-- a failure will cause the whole set of records to not be stored.
PROCEDURE store_outlet_characteristics(
    p_outlet_characteristic_tab_t IN outlet_characteristic_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
BEGIN
  NULL;
END store_outlet_characteristics;
--
--
--
-- returns an individual outlet characteristics object.
PROCEDURE retr_outlet_characteristic(
    p_outlet_characteristic_ref OUT outlet_characteristic_ref_t )
AS
BEGIN
  NULL;
END retr_outlet_characteristic;
--
--
--
-- inserts or updates an outlet characteristic.
-- if a record does not exist it will be inserted.
-- if the record already exists and p_fail_if_exists is false, the existing
-- record will be updated.
PROCEDURE store_outlet_characteristic(
    p_outlet_characteristic IN outlet_characteristic_obj_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
AS
BEGIN
  NULL;
END store_outlet_characteristic;
--
--
--
-- removes an outlet characterisitic.
PROCEDURE remove_outlet_characteristic(
    p_outlet_characteristic_ref IN outlet_characteristic_ref_t )
AS
BEGIN
  NULL;
END remove_outlet_characteristic;
--
--
--
-- Renames an outlet characteristic from one id to a new id.
--
-- security: can only be called by dba group.
--
-- errors will be issued as thrown exceptions.
--
PROCEDURE rename_outlet_characteristic(
    p_outlet_characteristic_id_old IN VARCHAR2,
    p_outlet_characteristic_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL )
AS
BEGIN
  NULL;
END rename_outlet_characteristic;
--
--
--
END CWMS_OUTLET;
/
show errors;