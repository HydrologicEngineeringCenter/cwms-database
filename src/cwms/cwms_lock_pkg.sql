CREATE OR REPLACE PACKAGE CWMS_LOCK AS

-------------------------------------------------------------------------------
-- CWMS_LOCK
--
-- These procedures and functions query and manipulate locks in the CWMS/ROWCPS
-- database.





--
-- cat_lock
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
--    project_office_id        varchar2(32)  the office id of the parent project.
--    project_location_id      varchar2(49)   the parent project's location id
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
--type definitions:
--
-- 
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
-- errors will be issued as thrown exceptions.
--
PROCEDURE cat_lock (
   p_lock_cat     OUT sys_refcursor,            --described above.
   p_project_id   IN    VARCHAR2 DEFAULT NULL,  -- the project id. if null, return all locks for the office.
   p_db_office_id IN    VARCHAR2 DEFAULT NULL); -- defaults to the connected user's office if null
                                                -- the office id can use sql masks for retrieval of additional offices.


PROCEDURE retrieve_lock(
   p_lock OUT lock_obj_t,                   --returns a filled in lock object including location data
   p_lock_location_ref IN location_ref_t);  -- a location ref that identifies the lock we want to retrieve.
                                            -- includes the lock's location id (base location + '-' + sublocation)
                                            -- the office id if null will default to the connected user's office

procedure store_lock(
   p_lock           IN lock_obj_t,            -- a populated lock object type.
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T'); -- a flag that will cause the procedure to fail if the lock already exists


procedure rename_lock(
   p_lock_id_old  IN VARCHAR2,               -- the old lock concatenated location id
   p_lock_id_new  IN VARCHAR2,               -- the new lock concatenated location id
   p_db_office_id IN VARCHAR2 DEFAULT NULL); -- defaults to the connected user's office if null   


procedure delete_lock(
    p_lock_id       IN VARCHAR,                               -- base location id + "-" + sub-loc id (if it exists)
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, --
    p_db_office_id  IN VARCHAR2 DEFAULT NULL);                -- defaults to the connected user's office if null   

END CWMS_LOCK;
/
show errors;

GRANT EXECUTE ON CWMS_PROJECT to CWMS_USER;