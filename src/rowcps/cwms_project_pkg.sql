SET serveroutput on


create or replace PACKAGE CWMS_PROJECT IS

-------------------------------------------------------------------------------
-- CAT_PROJECT
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

--
-- cat_project
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
-- errors will be issued as thrown exceptions.
-- 
PROCEDURE cat_project (
	--described above.
	p_project_cat		OUT		sys_refcursor, 
	
	-- defaults to the connected user's office if null
	p_db_office_id		IN		VARCHAR2 DEFAULT NULL
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
	p_project					IN		project_obj_t
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
-- delete will only delete from the project down. 
-- 
-- errors will be issued as thrown exceptions. 
--
procedure delete_project(
	-- base location id + "-" + sub-loc id (if it exists)
    p_project_id		IN   VARCHAR2,
	-- defaults to the connected user's office if null
    p_db_office_id    IN   VARCHAR2 DEFAULT NULL
);

END CWMS_PROJECT;

/
show errors;

