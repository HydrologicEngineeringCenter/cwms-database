SET serveroutput on
   
CREATE OR REPLACE TYPE project_obj_t AS OBJECT (

	--the office id for the base location
	db_office_id 			VARCHAR2(16),

	-- the location associated with this project,
	--an instance of the location type.
	project_location 		cat_location2_obj_t,

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
	
	hydropower_description	VARCHAR2(255),

	-- an instance of the location type.
	pumpback_location_id	cat_location2_obj_t,

	--an instance of the location type
	near_gage_location_id	cat_location2_obj_t
	
	sedimentation_description VARCHAR(255),
	
	downstream_urban_description VARCHAR(255),
	
	bank_full_capacity_description VARCHAR(255),
	
	yield_time_frame_start DATE,
	
	yield_time_frame_end DATE
);   
   
/
show errors;
