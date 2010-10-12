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
    supply_location location_obj_t                --The AT_PHYSICAL_LOCATION record which is the location where this water will be obtained below the dam or within the outlet works
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
    physical_transfer_type lookup_type_obj_t,         --The type of transfer for this water movement.  See AT_LU_PHYSICAL_TRANSFER_TYPE_CODE.
    accounting_credit_debit VARCHAR2(6 BYTE),         --Whether this water movement is a credit or a debit to the contract
    accounting_volume BINARY_DOUBLE,                  --Param: Stor. The volume associated with the water movement
    units_id VARCHAR2(16),                            --The units id for volume
    transfer_start_datetime DATE,                     --The date this water movement began, DATE includes the time zone.
    transfer_end_datetime DATE,                       --the date this water movement stopped, DATE includes the time zone.
    accounting_remarks VARCHAR2(255 BYTE)             --Any comments regarding this water accounting movement
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
CREATE OR REPLACE TYPE outlet_characteristic_ref_t
AS
  OBJECT
  (
    office_id         VARCHAR2 (16), -- the office id for this ref
    characteristic_id VARCHAR2 (32)  -- the id of this characteristic.
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE outlet_obj_t
AS
  OBJECT
  (
    project_location_ref location_ref_t,           --The project this outlet is a child of
    outlet_location location_obj_t,                  --The location for this outlet
    characteristic_ref outlet_characteristic_ref_t, -- the characteristic for this outlet.
    outlet_description VARCHAR(255)                 -- The description of this outlet.
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE outlet_tab_t
IS
  TABLE OF outlet_obj_t;
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE outlet_characteristic_obj_t
AS
  OBJECT
  (
    characteristic_ref outlet_characteristic_ref_t, -- office id and characteristic id
    opening_parameter_id VARCHAR2 (16),             -- A foreign key to an AT_PARAMETER record that constrains the gate opening to a defined parameter and unit.
    height BINARY_DOUBLE,                           -- The height of the gate
    width binary_double,                            -- The width of the gate
    opening_radius binary_double,                   -- The radius of the pipe or circular conduit that this outlet is a control for.  This is not applicable to rectangular outlets, tainter gates, or uncontrolled spillways
    opening_units_id VARCHAR2(16),                  -- the units of the opening radius value.
    elev_invert binary_double,                      -- The elevation of the invert for the outlet
    flow_capacity_max BINARY_DOUBLE,                --  The maximum flow capacity of the gate
    flow_units_id VARCHAR2(16),                     -- the units of the flow value.
    net_length_spillway binary_double,              -- The net length of the spillway
    spillway_notch_length binary_double,            -- The length of the spillway notch
    length_units_id            VARCHAR2(16),                   -- the units of the height, width, and length.
    outlet_general_description VARCHAR2(255)                   -- description of the outlet characteristic
  );
  /
  show errors
  --
  --
  --
CREATE OR REPLACE TYPE outlet_characteristic_tab_t
IS
  TABLE OF outlet_characteristic_obj_t;
  /
  show errors
  --
  --
  --
  SET echo ON
  --
  --
  --
  -- create public synonyms for CWMS schema packages and views
  -- grant execute on packages to CWMS_USER role
  -- grant select on view to CWMS_USER role
  --
  -- exclude any package or view named like %_SEC_%
  --
  DECLARE
  type str_tab_t
IS
  TABLE OF VARCHAR2(32);
  type_names str_tab_t := str_tab_t();
  sql_statement VARCHAR2(128);
BEGIN
  --
  -- collect CWMS schema object types
  --
  FOR rec IN
  (SELECT object_name
  FROM dba_objects
  WHERE owner     = '&cwms_schema'
  AND object_type = 'TYPE'
  AND object_name NOT LIKE 'SYS_%'
  )
  LOOP
    type_names.extend;
    type_names(type_names.last) := rec.object_name;
  END LOOP;
  --
  -- grant execute on COLLECTED types to CWMS_USER role
  --
  dbms_output.put_line('--');
  FOR i IN 1..type_names.count
  LOOP
    sql_statement := 'GRANT EXECUTE ON &cwms_schema'||'.'||type_names(i)||' TO CWMS_USER';
    dbms_output.put_line('-- ' || sql_statement);
    EXECUTE immediate sql_statement;
  END LOOP;
END;
/
