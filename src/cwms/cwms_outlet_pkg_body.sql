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
    p_outlet OUT project_structure_obj_t,
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
    p_outlets OUT project_structure_tab_t,
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
    p_outlet IN project_structure_obj_t,
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
    p_outlets IN project_structure_tab_t,
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

--
--
--
END CWMS_OUTLET;
/
show errors;