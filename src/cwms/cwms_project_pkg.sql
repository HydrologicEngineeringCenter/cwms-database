WHENEVER sqlerror exit sql.sqlcode
SET serveroutput on


create or replace PACKAGE CWMS_PROJECT IS

-------------------------------------------------------------------------------
-- CWMS_PROJECT
--
-- These procedures and functions query and manipulate projects in the CWMS/ROWCPS
-- database. 

---Note on DB_OFFICE_ID. DB_OFFICEID in addtion to location id is required to 
-- uniquely identify a location code, so it will be included in all of these calls.
--
-- defaults to the connected user's office if null.
-- p_db_office_id		IN		VARCHAR2 DEFAULT NULL
-- CWMS has a package proceudure that can be used to determine the office id for
-- a given user.

--type definitions. 
-- utilize location object from cwms_types.sql. 
-- utilize project object from rowcps_types.sql

-- security
-- cwms (cwms_sec?) allows definitions of user groups and assigned privileges to 
-- control access package procedures. 
-- Need to determine how these are going to be implemented into the ROWCPS API.
-- Talk to Perryman on this.
-- Initial thought is to use two cwms groups. a user level group and a dba level
-- group. I dont recall the names of these at the moment.
-------------------------------------------------------------------------------





-------------------------------------------------------------------------------
-- procedure: cat_project
-- returns a listing of project identifying and geopositional data. 
-- if a better design is returning a table of project_obj_t, that is fine.
-- at a minimum the columns below need to be returned.
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
--
-- p_basin_cat
-- returns a listing of assigned project locations for all "Basin" category location 
-- groups described by the p_db_office_id parameter. 
--
-- security: can be called by user and dba group.
--
-- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
-- Changing them will end up breaking external code (so make any changes prior
-- to development).
-- The returned records contain the following columns:
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    group_office_id          varchar2(16)   owning office of location group
--    loc_group_id             VARCHAR2(32)   the location group id
--    loc_group_desc           VARCHAR2(128)  the location group description
--    location_office_id       varchar2(16)   owning office of location
--    base_location_id         varchar2(16)   base location id
--    sub_location_id          varchar2(32)   sub-location id, if any
--
-- errors will be issued as thrown exceptions. 
--
PROCEDURE cat_project (
	--described above.
	p_project_cat		OUT		sys_refcursor,
  
	--described above.
	p_basin_cat		  OUT		sys_refcursor,
	
  -- defaults to the connected user's office if null
  -- the office id can use sql masks for retrieval of additional offices.
  p_db_office_id IN    VARCHAR2 DEFAULT NULL
                                                
);

   
-- Returns project data for a given project id. Returned data is encapsulated
-- in a project oracle type. This includes the location data for the project (
-- see the referenced location object types in the project type).
-- 
-- security: can be called by user and dba group.
-- 
-- errors preventing the return of data will be issued as a thrown exception
--
PROCEDURE retrieve_project(
	--returns a filled in project object including location data
	p_project					OUT		project_obj_t,
	
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id				IN 		VARCHAR2, 
	
	-- defaults to the connected user's office if null
	p_db_office_id				IN		VARCHAR2 DEFAULT NULL 
	
);

-- Stores the data contained within the project object into the database schema.
-- Also stores location data for the project's referenced locations.
-- 
-- security: can only be called by dba group.
-- 
-- This procedure performs both insert and update functionality. Use the 
-- connected user's office id if any of the office id args are null. 
-- 
-- If any of the location codes are undef for the corresponding location id and 
-- office id pairs, then create the location codes codes using cwms_loc.
--
-- if the project location code was created, insert the project data, otherwise
-- update the project data.
--
-- if any referenced location codes were created, insert their data, otherwise 
-- update the location data. cwms_loc might already take care of this via
-- cwms_loc.store_location.
--
-- errors will be issued as thrown exceptions.
-- 
procedure store_project(
	-- a populated project object type.
	p_project					IN		project_obj_t,
  -- fail the store if the project already exists.
  p_fail_if_exists      IN       VARCHAR2 DEFAULT 'T'
);


-- Renames a project from one id to a new id.
-- 
-- security: can only be called by dba group.
-- 
-- This should probably just call cwms_loc.rename_location().
-- Discussion has occurred on whether or not to just call cwms_loc.rename directly.
-- This depends on whether loc package is actively used, so unknown for right now
-- and rename_project will be developed. 
-- 
-- Note that a project's office id is not allowed to change.
--
-- errors will be issued as thrown exceptions.
-- 
procedure rename_project(
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id_old	IN	VARCHAR2,
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id_new	IN	VARCHAR2,
	-- defaults to the connected user's office if null
	p_db_office_id		IN	VARCHAR2 DEFAULT NULL
);

-- Performs a cascading delete on the project that will remove the project from 
-- the project table and all referenced tables.
-- 
-- security: can only be called by dba group.
-- 
-- This delete does not affect any of the location tables, only project tables.
-- AT_PHYSICAL_LOCATION will not be touched.
-- delete will only delete from the project down. 
-- 
-- errors will be issued as thrown exceptions. 
--
procedure delete_project(
	-- base location id + "-" + sub-loc id (if it exists)
  p_project_id		IN   VARCHAR2,
  -- the cwms_util delete action for this delete, options are delete_key and delete_all.
  -- delete_key will fail if there are project children referencing this project, i.e. embankments, etc.
  -- delete_all will cascade delete this project and all children. 
  p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, 
	-- defaults to the connected user's office if null
  p_db_office_id    IN   VARCHAR2 DEFAULT NULL
);


-- procedure create_basin_group
-- creates a "Basin" category location group
-- security: can only be called by the dba group.
-- errors will be thrown as exceptions.
PROCEDURE create_basin_group (
      -- the basin name
      p_loc_group_id      IN   VARCHAR2,
      -- description of the basin
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

-- procedure rename_basin_group
-- renames an existing "Basin" category location group.
-- security: can only be called by the dba group.
-- errors will be thrown as exceptions.
PROCEDURE rename_basin_group (
      -- the old basin name
      p_loc_group_id_old   IN   VARCHAR2,
      -- the new basin name
      p_loc_group_id_new   IN   VARCHAR2,
      -- an updated description
      p_loc_group_desc     IN   VARCHAR2 DEFAULT NULL,
      -- if true, null args should not be processed.
      p_ignore_null        IN   VARCHAR2 DEFAULT 'T',
      -- defaults to the connected user's office if null
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   --delete_basin_group
   -- deletes a "Basin" category location group.
   -- 
  PROCEDURE delete_basin_group (
    -- the location group to delete.
		p_loc_group_id		IN VARCHAR2,
    -- delete_key will fail if there are assigned locations.
    -- delete_all will delete all location assignments, then delete the group.
    p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key, 
    -- defaults to the connected user's office if null
		p_db_office_id		IN VARCHAR2 DEFAULT NULL
  );
   
   -- Assign a location to a "Basin" category location group. The location id
   -- that is being assigned to the basin needs to be constrained to location_codes
   -- in the AT_PROJECT table.
   PROCEDURE assign_basin_group2 (
      -- the location group id.
      p_loc_group_id      IN   VARCHAR2,
      -- the project location id
      p_location_id       IN   VARCHAR2,
      -- the attribute for the project location.
      p_loc_attribute     IN   NUMBER   DEFAULT NULL,
      -- the alias for this project, this will most likely always be null.
      p_loc_alias_id      IN   VARCHAR2 DEFAULT NULL,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

  -- Assign a set of locations to the "Basin" category location group. The location id
   -- that is being assigned to the basin needs to be constrained to location_codes
   -- in the AT_PROJECT table.
   PROCEDURE assign_basin_groups2 (
     -- the basin location group id
      p_loc_group_id      IN   VARCHAR2,
      -- an array of the location ids and extra data to assign to the specified group.
      p_loc_alias_array   IN   loc_alias_array2,
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );
   
   -- Removes a location from a "Basin" category location group.
   PROCEDURE unassign_basin_group (
      -- the basin location group id
      p_loc_group_id      IN   VARCHAR2,
      -- the location id to remove. 
      p_location_id       IN   VARCHAR2,
      -- if unassign is T then all assigned locs are removed from group. 
      -- p_location_id needs to be set to null when the arg is T.
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );
   
   -- Removes a set of location ids from a "Basin" category location group.
   PROCEDURE unassign_basin_groups (
      -- the basin location group id.
      p_loc_group_id      IN   VARCHAR2,
      -- the array of location ids to remove.
      p_location_array    IN   char_49_array_type,
      -- if T, then all assigned locs are removed from the group.
      -- p_location_array needs to be null when the arg is T.
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      -- defaults to the connected user's office if null
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );   
   
END CWMS_PROJECT;

/
show errors;

GRANT EXECUTE ON CWMS_PROJECT to CWMS_USER;