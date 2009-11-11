create or replace PACKAGE CWMS_PROJECT AS

-------------------------------------------------------------------------------
-- CAT_PROJECT
--
-- These procedures and functions manipulate projects in the CWMS/ROWCPS
-- database.

--type definitions. utilize location object from cwms_types.sql

CREATE OR REPLACE TYPE project_obj_t AS OBJECT (

	--the office id for the base location
	db_office_id 			VARCHAR2(16),

	-- the location associated with this project,
	--an instance of the location type.
	project_location 		cat_location2_obj_t,

	project_effective_date	DATE,

	project_expiration_date	DATE,

	--an instance of the location type.
	parent_location			cat_location2_obj_t, 

	authorizing_law			VARCHAR2(32),

	federal_cost			NUMBER,

	nonfederal_cost			NUMBER,

	--emailed Mark about this data member's type vs comment discrepancy
	cost_year				DATE, 

	federal_om_cost			NUMBER,

	nonfederal_om_cost		NUMBER,

	-- CLOB?
	remarks					VARCHAR2(1000), 

	project_owner			VARCHAR2(255),

	-- should this be part of the lock table since there can be more than one lock per project?
	lock_lift				NUMBER, 

	-- should this be part of the lock table since there can be more than one lock per project?
	lock_flow				NUMBER, 

	river_mile				NUMBER,

	has_hydro_power			VARCHAR2(1),

	turbine_count			NUMBER,
	
	hydropower_description	VARCHAR2(255),

	operating_purposes		VARCHAR2(255),

	authorized_purposes		VARCHAR2(255),

	-- an instance of the location type.
	pumpback_location_id	cat_location2_obj_t,

	--an instance of the location type
	near_gage_location_id	cat_location2_obj_t
);


  
-- cat_project
-- returns a listing of project identifying and geopositional data. 
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
PROCEDURE cat_project (
	--described above.
	p_project_cat		OUT		sys_refcursor, 
	
	--defaults to the user's office if null.
	p_db_office_id		IN		VARCHAR2 DEFAULT NULL
);
   
   
-- returns project data 
-- errors preventing the return of data should be issued as a thrown exception
-- 
PROCEDURE retrieve_project(
	--returns a filled in project object
	p_project					OUT		project_object_t 
	
	-- base location id + "-" + sub-loc id (if it exists)
	p_project_id				IN 		VARCHAR2, 
	
	-- defaults to the user's office if null
	p_db_office_id				IN		VARCHAR2 DEFAULT NULL 
	
)

--stores the data contained within the project object into the database schema
--will this alter the referenced location types?
procedure store_project(
	p_project					IN		project_object_t
)


-- renames a project from one id to a new one.
-- this should probably just call cwms_loc.rename_location().
procedure rename_project(
	p_project_id_old	IN	VARCHAR2,
	p_project_id_new	IN	VARCHAR2,
	p_db_office_id		IN	VARCHAR2 DEFAULT NULL
)

-- deletes a project, this does not affect any of the location code data.
-- I'm open to coding the delete actions flagged by parameter or by using
-- separate calls. 
procedure delete_project(
      p_project_id		IN   VARCHAR2,
	  --similar options to location delete
	  --delete data, delete just the project data, when to fail?
	  --delete cascade, delete this project and all referring data.
      p_delete_action   IN   VARCHAR2 DEFAULT 'DELETE DATA',
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   );

END CWMS_PROJECT;
