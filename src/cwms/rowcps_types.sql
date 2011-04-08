WHENEVER sqlerror EXIT sql.sqlcode
SET define ON
@@../cwms/defines.sql
SET serveroutput ON
--
--
--
--location objects are defined in cwms_types.
--location_ref_t and location_obj_t.
CREATE OR REPLACE TYPE lookup_type_obj_t
AS
  OBJECT
  (
    office_id     VARCHAR2 (16),      -- the office id for this lookup type
    display_value VARCHAR2(25 byte),  --The value to display for this lookup record
    tooltip       VARCHAR2(255 byte), --The tooltip or meaning of this lookup record
    active        VARCHAR2(1 byte)    --Whether this lookup record entry is currently active
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE lookup_type_tab_t
IS
  TABLE OF lookup_type_obj_t;
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE document_obj_t
AS
  OBJECT
  (
    office_id   VARCHAR2 (16),    -- the office id for this lookup type
    document_id VARCHAR2(64 BYTE) -- The unique identifier for the individual document, user provided
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE document_tab_t
IS
  TABLE OF document_obj_t;
  /
  show errors
  --project object.
  --
  --
  --
CREATE OR REPLACE TYPE project_obj_t
AS
  OBJECT
  (
  
    --locations
    --the location associated with this project,
    --an instance of the location type.
    --has the db office id for this project.
    project_location location_obj_t,
    --The location code where the water is pumped back to
    pump_back_location location_obj_t,
    --The location code known as the near gage for the project
    near_gage_location location_obj_t,
    --The law authorizing this project
    authorizing_law VARCHAR2(32),
    --The year the project cost data is from
    cost_year DATE,
    federal_cost       NUMBER, --Param: Currency. The federal cost of this project
    nonfederal_cost    NUMBER, --Param: Currency. The non-federal cost of this project
    federal_om_cost    NUMBER, --Param: Currency. The om federal cost of this project
    nonfederal_om_cost NUMBER, --Param: Currency. the non-federal cost of this project
    -- the units id of the cost fields.
    cost_units_id VARCHAR2(16),
    --The general remarks regarding this project
    --Should this be a  CLOB?
    remarks VARCHAR2(1000),
    --The assigned owner of this project
    project_owner VARCHAR2(255),
    --The description of the hydro-power located at this project
    hydropower_description VARCHAR2(255),
    --The description of the projects sedimentation
    sedimentation_description VARCHAR(255),
    --The description of the urban area downstream
    downstream_urban_description VARCHAR(255),
    --The description of the full capacity
    bank_full_capacity_description VARCHAR(255),
    --The start date of the yield time frame
    yield_time_frame_start DATE,
    --The end date of the yield time frame
    yield_time_frame_end DATE );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE embankment_obj_t
AS
  OBJECT
  (
    project_location_ref location_ref_t,    --The project this embankment is a child of
    embankment_location location_obj_t,     --The location for this embankment
    structure_type lookup_type_obj_t,       --The lookup code for the type of the embankment structure
    upstream_prot_type lookup_type_obj_t,   --The upstream protection type code for the embankment structure
    downstream_prot_type lookup_type_obj_t, --The downstream protection type codefor the embankment structure
    upstream_sideslope BINARY_DOUBLE,       --Param: ??. The upstream side slope of the embankment structure
    downstream_sideslope BINARY_DOUBLE,     --Param: ??. The downstream side slope of the embankment structure
    structure_length BINARY_DOUBLE,         --Param: Length. The overall length of the embankment structure
    height_max BINARY_DOUBLE,               --Param: Height. The maximum height of the embankment structure
    top_width BINARY_DOUBLE,                --Param: Width. The width at the top of the embankment structure
    units_id VARCHAR2(16)                   --The units id of the lenght, width, and height values
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE embankment_tab_t
IS
  TABLE OF embankment_obj_t;
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE water_user_obj_t
AS
  OBJECT
  (
    project_location_ref location_ref_t, --The project that this user is pertaining to.
    entity_name VARCHAR2(64 BYTE),       --The entity name associated with this user
    water_right VARCHAR2(255 BYTE)       --The water right of this user (optional)
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE water_user_tab_t
IS
  TABLE OF water_user_obj_t;
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE water_user_contract_ref_t
AS
  OBJECT
  (
    water_user water_user_obj_t,   --The water user this record pertains to.  See table AT_WATER_USER.
    contract_name VARCHAR2(64 BYTE)--The identification name for the contract for this water user contract
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE type water_user_contract_obj_t
AS
  object
  (
    water_user_contract_ref water_user_contract_ref_t,
    -- contract_documents VARCHAR2(64 BYTE),--The documents for the contract
    water_supply_contract_type lookup_type_obj_t, -- The type of water supply contract. FK'ed to a LU table.
    ws_contract_effective_date DATE,              --The start date of the contract for this water user contract
    ws_contract_expiration_date DATE,             --The expiration date for the contract of this water user contract
    contracted_storage BINARY_DOUBLE,             --Param: Stor. The contracted storage amount for this water user contract
    initial_use_allocation BINARY_DOUBLE,         --Param: Stor. The initial contracted allocation for this water user contract
    future_use_allocation BINARY_DOUBLE,          --Param: Stor. The future contracted allocation for this water user contract
    storage_units_id VARCHAR2(15),                -- the units used for contracted storage and allocations.
    future_use_percent_activated BINARY_DOUBLE,   --Param: ??. The percent allocated future use for this water user contract
    total_alloc_percent_activated BINARY_DOUBLE,  --Param: ??. The percentage of total allocation for this water user contract
    withdraw_location location_obj_t,             --The code for the AT_PHYSICAL_LOCATION record which is the location where this water with be withdrawn from the permanent pool
    supply_location location_obj_t,                --The AT_PHYSICAL_LOCATION record which is the location where this water will be obtained below the dam or within the outlet works
    pump_in_location location_obj_t                --The AT_PHYSICAL_LOCATION record which is the location where this water will be obtained below the dam or within the outlet works
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE water_user_contract_tab_t
IS
  TABLE OF water_user_contract_obj_t;
  /
  show errors
  --
  --
  --
CREATE OR REPLACE type wat_usr_contract_acct_obj_t
AS
  object
  (
    water_user_contract_ref water_user_contract_ref_t,--The contract for this water movement. SEE AT_WATER_USER_CONTRACT.
    pump_location_ref location_ref_t, --the contract pump that was used for this accounting.
    physical_transfer_type lookup_type_obj_t,         --The type of transfer for this water movement.  See AT_PHYSICAL_TRANSFER_TYPE_CODE.
    accounting_volume binary_double,                  --Param: Stor. The volume associated with the water movement
    -- units_id VARCHAR2(16),                            --The units id for volume
    transfer_start_datetime date,                     --The date this water movement began, DATE includes the time zone.
    accounting_remarks varchar2(255 byte)             --Any comments regarding this water accounting movement
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE wat_usr_contract_acct_tab_t
IS
  TABLE OF wat_usr_contract_acct_obj_t;
  /
  show errors
  
CREATE OR REPLACE type loc_ref_time_window_obj_t
AS
  object
  (
    location_ref location_ref_t, 
    start_date DATE,
    end_date DATE
    );
/
show errors

CREATE OR REPLACE TYPE loc_ref_time_window_tab_t
IS
  TABLE OF loc_ref_time_window_obj_t;
  /
  show errors


  --
  --
  --
CREATE OR REPLACE TYPE lock_obj_t
AS
  OBJECT
  (
    project_location_ref location_ref_t, --The project this embankment is a child of
    lock_location location_obj_t,        --The location for this embankment
    -- the volume of water discharged for one lockage at
    --normal headwater and tailwater elevations.  this volume includes any flushing water.
    volume_per_lockage binary_double, -- Param: Stor.
    volume_units_id VARCHAR2(16),     -- the units of the volume value.
    lock_width binary_double,         -- Param: Width. The width of the lock chamber
    lock_length binary_double,        -- Param: Length. the length of the lock chamber
    minimum_draft binary_double,      -- Param: Depth. the minimum depth of water that is maintained for vessels for this particular lock
    normal_lock_lift binary_double,   -- Param: Height. The difference between upstream pool and downstream pool at normal elevation.
    units_id VARCHAR2(16)             -- the units id used for width, length, draft, and lift.
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE characteristic_ref_t
AS
  OBJECT
  (
    office_id         VARCHAR2 (16), -- the office id for this ref
    characteristic_id VARCHAR2 (64)  -- the id of this characteristic.
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE project_structure_obj_t
AS
  OBJECT
  (
    project_location_ref location_ref_t,           --The project this structure is a child of
    structure_location location_obj_t,                  --The location for this structure
    characteristic_ref characteristic_ref_t   -- the characteristic for this structure.
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE project_structure_tab_t
IS
  TABLE OF project_structure_obj_t;
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE characteristic_obj_t
AS
  OBJECT
  (
    characteristic_ref characteristic_ref_t, -- office id and characteristic id
--    opening_parameter_id VARCHAR2 (16),             -- A foreign key to an AT_PARAMETER record that constrains the gate opening to a defined parameter and unit.
--    height BINARY_DOUBLE,                           -- The height of the gate
--    width binary_double,                            -- The width of the gate
--    opening_radius binary_double,                   -- The radius of the pipe or circular conduit that this outlet is a control for.  This is not applicable to rectangular outlets, tainter gates, or uncontrolled spillways
--    opening_units_id VARCHAR2(16),                  -- the units of the opening radius value.
--    elev_invert binary_double,                      -- The elevation of the invert for the outlet
--    flow_capacity_max BINARY_DOUBLE,                --  The maximum flow capacity of the gate
--    flow_units_id VARCHAR2(16),                     -- the units of the flow value.
--    net_length_spillway binary_double,              -- The net length of the spillway
--    spillway_notch_length binary_double,            -- The length of the spillway notch
--    length_units_id            VARCHAR2(16),                   -- the units of the height, width, and length.
    general_description VARCHAR2(255)                   -- description of the outlet characteristic
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE characteristic_tab_t
IS
  TABLE OF characteristic_obj_t;
  /
  show errors
--
-- gate calc
-- 
CREATE OR REPLACE type gate_setting_obj_t
AS
  object
  (
  --required
  outlet_location_ref location_ref_t,
  opening binary_double,
  opening_units varchar2(16)
  );
  /
  show errors
  --
CREATE OR REPLACE TYPE gate_setting_tab_t
is
  TABLE OF gate_setting_obj_t;
  /
  show errors
--
--
CREATE OR REPLACE type gate_change_obj_t
AS
  object
  (
      --required
      project_location_ref location_ref_t, --PROJECT_LOCATION_CODE
      change_date date, --GATE_CHANGE_DATE
      elev_pool binary_double, --ELEV_POOL
      discharge_computation lookup_type_obj_t, --DISCHARGE_COMPUTATION_CODE
      release_reason lookup_type_obj_t, --release_reason_code
      settings gate_setting_tab_t,
      --not required
      elev_tailwater binary_double, --ELEV_TAILWATER
      elev_units varchar2(16), 
      old_total_discharge_override binary_double, --OLD_TOTAL_DISCHARGE_OVERRIDE
      new_total_discharge_override binary_double, --NEW_TOTAL_DISCHARGE_OVERRIDE
      discharge_units  varchar2(16), 
      change_notes VARCHAR2(255 BYTE), --GATE_CHANGE_NOTES
      protected varchar2(1) --PROTECTED_FLAG
);
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE gate_change_tab_t
is
  TABLE OF gate_change_obj_t;
  /
  show errors
  
--
-- turbines
--
CREATE OR REPLACE type turbine_setting_obj_t
AS
  object
  (
  --required
  turbine_location_ref location_ref_t,
  --setting lookup?
  --discharge lookup?
  
  --not required
  energy_rate binary_double,
  load binary_double,
  generation_units varchar2(16),
  power_factor binary_double -- unitless
);
  /
  show errors
  --
CREATE OR REPLACE TYPE turbine_setting_tab_t
is
  TABLE OF turbine_setting_obj_t;
  /
  show errors
--
--
CREATE OR REPLACE type turbine_change_obj_t
AS
  object
  (
      --required
      project_location_ref location_ref_t, --PROJECT_LOCATION_CODE
      change_date date, --xxx_CHANGE_DATE
      
      discharge_computation lookup_type_obj_t, --turbine_discharge_comp_code
      setting_reason lookup_type_obj_t, --turbine_setting_reason_code
      
      settings turbine_setting_tab_t,
      --not required
      old_total_discharge_override binary_double, --OLD_TOTAL_DISCHARGE_OVERRIDE
      new_total_discharge_override binary_double, --NEW_TOTAL_DISCHARGE_OVERRIDE
      discharge_units  varchar2(16), 
      change_notes VARCHAR2(255 BYTE) --GATE_CHANGE_NOTES
);
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE turbine_change_tab_t
is
  TABLE OF turbine_change_obj_t;
  /
  show errors
/*
--
--
SET echo ON
--
-- create public synonyms for CWMS schema types
-- grant execute on types to CWMS_USER role
--
declare
   type str_tab_t is table of varchar2(32);
   l_type_names str_tab_t;
   l_synonym    varchar2(32);
   l_existing   varchar2(32);
   l_sql        varchar2(256);
begin
   -----------------------
   -- collect the types --
   -----------------------
   select type_name
          bulk collect
     into l_type_names
     from dba_types
    where owner='CWMS_21'
      and type_name not like 'SYS\_%' escape '\'
 order by type_name;
   ----------------------------------------------
   -- grant execute on types to CWMS user role --
   ----------------------------------------------
   for i in 1..l_type_names.count loop
      l_sql := 'grant execute on &cwms_schema..'||l_type_names(i)||' to cwms_user';
      dbms_output.put_line('-- '||l_sql);
      execute immediate l_sql;
   end loop;
   --------------------------------------
   -- create public synonyms for types --
   --------------------------------------
   for i in 1..l_type_names.count loop
      l_synonym := lower(l_type_names(i));
      if substr(l_synonym, -2) = '_t' then
         l_synonym := substr(l_synonym, 1, length(l_synonym) - 2);
      elsif substr(l_synonym, -5) = '_type' then
         l_synonym := substr(l_synonym, 1, length(l_synonym) - 5);
      end if; 
      l_synonym := 'cwms_t_'||substr(l_synonym, 1, 25);
      for j in 1..9 loop
         begin
            select synonym_name 
              into l_existing
              from dba_synonyms
             where table_owner = '&cwms_schema'
               and synonym_name = l_synonym;
         exception
            when no_data_found then exit;
         end;
         l_synonym := substr(l_synonym, 1, length(l_synonym) - 2)||'_'||j; 
      end loop;
      begin
         execute immediate 'drop public synonym '||l_synonym;
      exception
         when others then null;
      end;
      l_sql := 'create public synonym '||l_synonym||' for &cwms_schema..'||l_type_names(i);
      dbms_output.put_line('-- '||l_sql);
      execute immediate l_sql;
   end loop;    
end;
/
*/