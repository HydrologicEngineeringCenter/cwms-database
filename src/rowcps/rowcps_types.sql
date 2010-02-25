SET serveroutput on
   
CREATE OR REPLACE TYPE project_obj_t AS OBJECT (

	--locations
	--the office id for the base location
	db_office_id 			VARCHAR2(16),

	-- the location associated with this project,
	--an instance of the location type.
	project_location 		cat_location2_obj_t,

	--The location code where the water is pumped back to
	pump_back_location 		cat_location2_obj_t,

	--The location code known as the near gage for the project
	near_gage_location 		cat_location2_obj_t,
	
	--The law authorizing this project
	authorizing_law			VARCHAR2(32),
	
	--The federal cost of this project
	federal_cost			NUMBER,

	--The non-federal cost of this project
	nonfederal_cost			NUMBER,

	--The year the project cost data is from
	cost_year				DATE, 

	--The om federal cost of this project
	federal_om_cost			NUMBER,

	--the non-federal cost of this project
	nonfederal_om_cost		NUMBER,

	--The general remarks regarding this project
	--Should this be a  CLOB?   
	remarks					VARCHAR2(1000), 

	--The assigned owner of this project
	project_owner			VARCHAR2(255),
	
	--The description of the hydro-power located at this project
	hydropower_description	VARCHAR2(255),

	--The description of the projects sedimentation
	sedimentation_description VARCHAR(255),
	
	--The description of the urban area downstream
	downstream_urban_description VARCHAR(255),
	
	--The description of the full capacity
	bank_full_capacity_description VARCHAR(255),
	
	--The start date of the yield time frame
	yield_time_frame_start DATE,
	
	--The end date of the yield time frame
	yield_time_frame_end DATE
);   
   
/
show errors;

GRANT EXECUTE ON PROJECT_OBJ_T TO CWMS_USER;

