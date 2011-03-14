declare
  l_project_id VARCHAR2(200);
  l_db_office_id varchar2(200);
  l_project_in cwms_dev.project_obj_t;
  l_PROJECT_OUT CWMS_DEV.PROJECT_OBJ_T;
  l_fail_if_exists varchar2(200);
  l_PROJECT_LOC_IN  cwms_dev.location_obj_t;
  l_project_loc_ref_in  cwms_dev.location_ref_t;
  
  l_entity_name VARCHAR2(64 BYTE);
  l_water_user water_user_obj_t;
  l_contract_name varchar2(64 byte);
  l_contract water_user_contract_obj_t;
  l_contracts water_user_contract_tab_t := water_user_contract_tab_t();
  l_contracts_out water_user_contract_tab_t := water_user_contract_tab_t();
  l_type_lookup lookup_type_obj_t;
  l_contract_types lookup_type_tab_t := lookup_type_tab_t();
  
begin
  
  l_project_id := 'AAA5';
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
  
  l_entity_name := 'Spatula City Water Dept';
  l_water_user := new WATER_USER_OBJ_T(new LOCATION_REF_T(l_project_id,null,l_db_office_id),l_entity_name,'blast people with fire hose');
  cwms_water_supply.store_water_user(l_water_user,l_fail_if_exists);
  
  l_contract_name := 'Test Contract';
  
  l_type_lookup := new lookup_type_obj_t(l_db_office_id,'Some contract type','Contract Tooltip','T'); --lookup
  
   
  l_contract := new water_user_contract_obj_t(
    new water_user_contract_ref_t(l_water_user,l_contract_name), --ref
    l_type_lookup, 
    to_date('2010/01/11-00:00:00', 'yyyy/mm/dd-hh24:mi:ss'), --eff date
    to_date('2010/01/03-00:00:00', 'yyyy/mm/dd-hh24:mi:ss'), --exp date
    15.0, --stor
    16.0, --ini alloc
    17.0, --fut alloc
    null, --stor units
    18.0, --fut perc
    19.0, -- total perc
    new location_obj_t(new location_ref_t(l_project_id,'withdraw 1',l_db_office_id),'OK','Tulsa','CST','reservoir project',-79.3067,40.7276,'NAD 83',1076,'m','NAVD 88','Keystone Lake','','','T','point','',-79.3067,40.7276,'SWT','Tulsa District','United States',''),
    new location_obj_t(new location_ref_t(l_project_id,'supply 1',l_db_office_id),'OK','Tulsa','CST','supply',              -79.3067,40.7276,'NAD 83',1076,'m','NAVD 88','Keystone Lake','','','T','point','',-79.3067,40.7276,'SWT','Tulsa District','United States',''),
    new location_obj_t(new location_ref_t(l_project_id,'pump in 1',l_db_office_id),'OK','Tulsa','CST','supply',              -79.3067,40.7276,'NAD 83',1076,'m','NAVD 88','Keystone Lake','','','T','point','',-79.3067,40.7276,'SWT','Tulsa District','United States','')
  );
  l_contracts.extend;
  l_contracts(1) := l_contract;
  
  l_contract_types.extend;
  l_contract_types(1) := l_type_lookup;
  cwms_water_supply.set_contract_types(l_contract_types, 'F');
  
  -- comment out if the contract already exists?
  cwms_water_supply.store_contracts(l_contracts,l_fail_if_exists);
  
  
  l_contracts_out.extend;
  cwms_water_supply.retrieve_contracts(l_contracts_out, l_project_loc_ref_in, l_entity_name);
  
  commit;
  
end;