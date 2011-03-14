DECLARE
  l_PROJECT_ID VARCHAR2(200);
  l_db_office_id varchar2(200);
  l_project_in cwms_dev.project_obj_t;
  l_PROJECT_OUT CWMS_DEV.PROJECT_OBJ_T;
  l_fail_if_exists varchar2(200);
  l_PROJECT_LOC_IN  cwms_dev.location_obj_t;
  l_PROJECT_LOC_REF_IN  cwms_dev.location_ref_t;
begin
  
  l_project_id := 'TestProject1';
  l_db_office_id := 'SWT';
  l_FAIL_IF_EXISTS:= 'F';

  l_project_loc_ref_in := new cwms_dev.location_ref_t(l_project_id,l_db_office_id);
  

      l_project_loc_in := new location_obj_t (
            l_project_loc_ref_in, --proj location
   null, --state_initial        VARCHAR2 (2),
   null, --county_name          VARCHAR2 (40),
   null, --time_zone_name       VARCHAR2 (28),
   null, --location_type        VARCHAR2 (32),
   null, --latitude             NUMBER,
   null, --longitude            NUMBER,
   null, --horizontal_datum     VARCHAR2 (16),
   null, --elevation            number,
   'm', --elev_unit_id 
   null, --vertical_datum       VARCHAR2 (16),
   'AAA5', --public_name          VARCHAR2 (32),
   'AAA5', --long_name            VARCHAR2 (80),
   '', --description          VARCHAR2 (512),
   'T', --active_flag          VARCHAR2 (1),
   null, --location_kind_id     varchar2(32),
   null, --map_label            varchar2(50),
   null, --published_latitude   number,
   null, --published_longitude  number,
   null, --bounding_office_id   varchar2(16),
   null, --bounding_office_name varchar2(32),
   null, --nation_id            varchar2(48),
   null --nearest_city         varchar2(50)            
            );

   l_project_in := new project_obj_t(               -- TYPE project_obj_t AS OBJECT (
      l_project_loc_in,                        --    project_location               cat_location2_obj_t,
      null,                       --    pump_back_location           cat_location2_obj_t,
      null,                      --    near_gage_location          cat_location2_obj_t,
      null,                 --    authorizing_law                VARCHAR2(32),
      null,                       --    cost_year                      DATE,
      0,                    --    federal_cost                   NUMBER,
      0,                 --    nonfederal_cost                NUMBER,
      0,                 --    federal_om_cost                NUMBER,
      0,              --    nonfederal_om_cost             NUMBER,
      null, -- cost units.
      null,                 --    remarks                        VARCHAR2(1000),
      null,                   --    project_owner                  VARCHAR2(255),
      null,          --    hydropower_description         VARCHAR2(255),
      null,       --    sedimentation_description      VARCHAR(255),
      null,    --    downstream_urban_description   VARCHAR(255),
      null,  --    bank_full_capacity_description VARCHAR(255),
      null,          --    yield_time_frame_start         DATE,
      null); 

  cwms_project.store_project(
    l_PROJECT_IN,l_FAIL_IF_EXISTS
  );



--cwms_project.retrieve_project(
--    l_project_out,l_project_id,l_db_office_id
--  );
  
  -- Modify the code to output the variable
  -- DBMS_OUTPUT.PUT_LINE('P_PROJECT = ' || P_PROJECT);
END;
