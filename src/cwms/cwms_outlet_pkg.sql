WHENEVER sqlerror EXIT sql.sqlcode
CREATE OR REPLACE
PACKAGE CWMS_OUTLET
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
    p_project_location_ref IN location_ref_t );
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
    p_fail_if_exists IN VARCHAR2 DEFAULT 'T' );
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
    p_db_office_id IN VARCHAR2 DEFAULT NULL );
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
  );

-- stores a table of gate settings.
--
-- start and end determines time window for delete.
-- start and end has to encompass the incoming time window defined in p_gate_settings.
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

procedure store_gate_changes(
    p_gate_changes in gate_change_tab_t,
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

PROCEDURE retrieve_gate_changes(
    -- the retrieved set of water user contract accountings
    p_gate_changes out gate_change_tab_t,
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
END CWMS_OUTLET;
/
show errors;
GRANT EXECUTE ON CWMS_OUTLET TO CWMS_USER;