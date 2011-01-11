WHENEVER sqlerror EXIT sql.sqlcode
CREATE OR REPLACE
PACKAGE CWMS_TURBINE
AS
  -------------------------------------------------------------------------------
  -- CWMS_TURBINE
  --
  -- These procedures and functions query and manipulate turbines and their supporting types
  -- in the CWMS/ROWCPS database.
  --
  -- An turbine will always have a parent project defined in AT_PROJECT.
  -- There can be zero to many turbines for a given project.
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
  -- Returns turbine data for a given turbine location id. Returned data is encapsulated
  -- in an turbine oracle type.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_turbine(
    --returns a filled in object including location data
    p_turbine OUT project_structure_obj_t,
    -- a location ref that identifies the object we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_turbine_location_ref IN location_ref_t );
  --
  --
  --
  --
  --
  -- Returns a set of turbines for a given project. Returned data is encapsulated
  -- in a table of turbine oracle types.
  --
  -- security: can be called by user and dba group.
  --
  -- errors preventing the return of data will be issued as a thrown exception
  --
PROCEDURE retrieve_turbines(
    --returns a filled set of objects including location data
    p_turbines OUT project_structure_tab_t,
    -- a project location ref that identifies the objects we want to retrieve.
    -- includes the location id (base location + '-' + sublocation)
    -- the office id if null will default to the connected user's office
    p_project_location_ref IN location_ref_t );
  --
  --
  --
  -- Stores the data contained within the set of turbine objects into the database schema.
  --
  -- security: can only be called by dba group.
  --
  -- This procedure performs both insert and update functionality.
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE store_turbines(
    -- a table of populated turbine object types.
    p_turbines IN project_structure_tab_t,
    -- a flag that will cause the procedure to fail if the object already exists
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
  --
  --
  --
  -- Renames an turbine from one id to a new id.
  --
  -- security: can only be called by dba group.
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE rename_turbine(
    p_turbine_id_old IN VARCHAR2,
    p_turbine_id_new IN VARCHAR2,
    -- defaults to the connected user's office if null
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
  --
  --
  --
  -- Performs a delete on an turbine.
  --
  -- security: can only be called by dba group.
  --
  -- errors will be issued as thrown exceptions.
  --
PROCEDURE delete_turbine(
    p_turbine_id IN VARCHAR, -- base location id + "-" + sub-loc id (if it exists)
    -- delete key will fail if there are references to the turbine.
    -- delete all will delete the referring children then the turbine.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key,
    p_db_office_id  IN VARCHAR2 DEFAULT NULL -- defaults to the connected user's office if null
  );

-- stores a table of turbine settings.
--
-- start and end determines time window for delete.
-- start and end has to encompass the incoming time window defined in p_turbine_settings.
-- throw an error if it isnt.
--
-- inclusive determines if records at the start and end times are included in the delete.
-- the type of inclusive is borrowed from cwms_ts, but it could be setup as a 'T' 'F' 
-- if that makes more sense.
--
-- if rule isnt delete_insert then throw an error, initially ONLY delete insert
-- will be supported.
--
-- override_protection will not be implemented at this time, but is included for
-- future use.

procedure store_turbine_changes(
    p_turbine_changes in turbine_change_tab_t,
		-- store rule, only delete insert initially supported.
    p_store_rule		in varchar2 default null,
    -- start time of data to delete.
    p_start_time	  in		date default null,
    --end time of data to delete.
    p_end_time		  in		date default null,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive in varchar2 default 'T',
    -- if protection is to be ignored, not initially supported.
		p_override_prot	in varchar2 default 'F'
);

PROCEDURE retrieve_turbine_changes(
    -- the retrieved set of water user contract accountings
    p_turbine_changes out turbine_change_tab_t,
    -- the retrieved changes should be for this project.
    p_project_location in location_ref_t,
    -- the start date time for changes
    p_start_time in date,
    -- the end date time for changes
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive in varchar2 default 'T',
    -- determines the unit system that returned data is in.
    -- opening can be a variety of units across a given project, 
    -- so the return units are not parameterized.
    p_unit_system in varchar2 default null
  );

  --
  --
END CWMS_TURBINE;
/
show errors;
GRANT EXECUTE ON CWMS_TURBINE TO CWMS_USER;