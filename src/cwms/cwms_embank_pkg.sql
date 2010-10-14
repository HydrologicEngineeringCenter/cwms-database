WHENEVER sqlerror EXIT sql.sqlcode
CREATE OR REPLACE
PACKAGE CWMS_EMBANK
AS
  -------------------------------------------------------------------------------
  -- CWMS_EMBANK
  --
  -- These procedures and functions query and manipulate embankments in the CWMS/ROWCPS
  -- database. An embankment will always have a parent project defined in AT_PROJECT.
  -- There can be zero to many embankments for a given project.
  ---Note
  ---Note on DB_OFFICE_ID. DB_OFFICEID in addtion to location id is required to
  -- uniquely identify a location code, so it will be included in all of these calls.
  --
  -- defaults to the connected user's office if null.
  -- p_db_office_id  IN  VARCHAR2 DEFAULT NULL
  -- CWMS has a package proceudure that can be used to determine the office id for
  -- a given user.
  --
  --type definitions:
  -- from cwms_types.sql, location_obj_t and location_ref_t.
  -- from rowcps_types.sql, embankment_obj_t.
  -- security:
  --
  -------------------------------------------------------------------------------
  --
  -- cat_embankment
  -- returns a listing of embankments.
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
  --    project_id               varchar2(32) the identification (id) of the parent project.
  --    db_office_id             varchar2(16)   owning office of location
  --    base_location_id         varchar2(16)   base location id
  --    sub_location_id          varchar2(32)   sub-location id, if any
  --    time_zone_name           varchar2(28)   local time zone name for location
  --    latitude                 number         location latitude
  --    longitude                number         location longitude
  --    horizontal_datum         varchar2(16)   horizontal datrum of lat/lon
  --    elevation                number         location elevation
  --    elev_unit_id             varchar2(16)   location elevation units
  --    vertical_datum           varchar2(16)   veritcal datum of elevation
  --    public_name              varchar2(32)   location public name
  --    long_name                varchar2(80)   location long name
  --    description              varchar2(512)  location description
  --    active_flag              varchar2(1)    'T' if active, else 'F'
  --
  -------------------------------------------------------------------------------
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE cat_embankment(
    --described above.
    p_embankment_cat OUT sys_refcursor,
    -- the project id. if null, return all embankments for the office.
    p_project_id IN VARCHAR2 DEFAULT NULL,
    -- defaults to the connected user's office if null
    -- the office id can use sql masks for retrieval of additional offices.
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
  -- Returns embankment data for a given embankment id. Returned data is encapsulated
  -- in a embankment oracle type.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_embankment(
    --returns a filled in object including location data
    p_embankment OUT embankment_obj_t,
    -- a location ref that identifies the object we want to retrieve.
    -- includes the lock's location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_embankment_location_ref IN location_ref_t );
  -- Returns a set of embankments for a given project. Returned data is encapsulated
  -- in a table of embankment oracle types.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_embankments(
    --returns a filled set of objects including location data
    p_embankments OUT embankment_tab_t,
    -- a project location refs that identify the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t );
  -- Stores the data contained within the embankment object into the database schema.
  --
  --
  -- security: can only be called by dba group.
  --
  -- This procedure performs both insert and update functionality.
  --
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE store_embankment(
    -- a populated embankment object type.
    p_embankment IN embankment_obj_t,
    -- a flag that will cause the procedure to fail if the lock already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  -- Stores the data contained within the embankment object into the database schema.
  --
  --
  -- security: can only be called by dba group.
  --
  -- This procedure performs both insert and update functionality.
  --
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE store_embankments(
    -- a populated embankment object type.
    p_embankments IN embankment_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  -- Renames a embankment from one id to a new id.
  --
  -- security: can only be called by dba group.
  --
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE rename_embankment(
    p_embankment_id_old IN VARCHAR2,
    p_embankment_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
  -- Performs a  delete on the embankment.
  --
  -- security: can only be called by dba group.
  --
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE delete_embankment(
    p_embankment_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    -- delete key will fail if there are references to the embankment.
    -- delete all will delete the referring children then the embankment.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  );
  --
  -- manipulation of structure_type lookups
  --
  -- returns a listing of lookup objects.
PROCEDURE get_structure_types(
    p_lookup_type_tab OUT lookup_type_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
  -- inserts or updates a set of lookups.
  -- if a lookup does not exist it will be inserted.
  -- if a lookup already exists and p_fail_if_exists is false, the existing
  -- lookup will be updated.
  --
  -- a failure will cause the whole set of lookups to not be stored.
PROCEDURE set_structure_types(
    p_lookup_type_tab IN lookup_type_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  -- inserts or updates a lookup.
  -- if the lookup does not exist it will be inserted.
  -- if the lookup already exists and p_fail_if_exists is false, the existing
  -- lookup will be updated.
PROCEDURE set_structure_type(
    p_lookup_type IN lookup_type_obj_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  -- removes a lookup.
PROCEDURE remove_structure_type(
    p_lookup_type IN lookup_type_obj_t );
  --
  -- manipulation of protection_type lookups.
  -- used for both upstream and downstream.
  --
  -- returns a listing of lookup objects.
PROCEDURE get_protection_types(
    p_lookup_type_tab OUT lookup_type_tab_t,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
  -- inserts or updates a set of lookups.
  -- if a lookup does not exist it will be inserted.
  -- if a lookup already exists and p_fail_if_exists is false, the existing
  -- lookup will be updated.
  --
  -- a failure will cause the whole set of lookups to not be stored.
PROCEDURE set_protection_types(
    p_lookup_type_tab IN lookup_type_tab_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  -- inserts or updates a lookup.
  -- if the lookup does not exist it will be inserted.
  -- if the lookup already exists and p_fail_if_exists is false, the existing
  -- lookup will be updated.
PROCEDURE set_protection_type(
    p_lookup_type IN lookup_type_obj_t,
    -- a flag that will cause the procedure to fail if the objects already exist
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  -- removes a lookup.
PROCEDURE remove_protection_type(
    p_lookup_type IN lookup_type_obj_t );
END CWMS_EMBANK;
/
show errors;
GRANT EXECUTE ON CWMS_EMBANK TO CWMS_USER;