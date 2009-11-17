SET serveroutput on
   
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

	--the date of the major cost of the project
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
   
/
show errors;
