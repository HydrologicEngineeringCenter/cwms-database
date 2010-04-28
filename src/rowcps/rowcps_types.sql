WHENEVER sqlerror exit sql.sqlcode
SET define on
@@../cwms/defines.sql
SET serveroutput on

--location objects are defined in cwms_types.
--location_ref_t and location_obj_t.


CREATE OR REPLACE TYPE lookup_type_obj_t AS OBJECT
(
    display_value	varchar2(25 byte),  --The value to display for this lookup record
    tooltip	varchar2(255 byte),     --The tooltip or meaning of this lookup record
    active	varchar2(1 byte)	--Whether this lookup record entry is currently active
);
/
show errors

CREATE OR REPLACE TYPE document_obj_t AS OBJECT(
    document_id	VARCHAR2(64 BYTE)	-- The unique identifier for the individual document, user provided
);
/
show errors

CREATE OR REPLACE TYPE document_tab_t IS TABLE OF document_obj_t;
/
show errors

--project object.
CREATE OR REPLACE TYPE project_obj_t AS OBJECT (
    --locations

    --the location associated with this project,
    --an instance of the location type.
    --has the db office id for this project.
    project_location 		location_obj_t,

    --The location code where the water is pumped back to
    pump_back_location 		location_obj_t,

    --The location code known as the near gage for the project
    near_gage_location 		location_obj_t,
    
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
show errors



CREATE OR REPLACE TYPE embankment_obj_t AS OBJECT
( 
    project_location_ref	location_ref_t,          --The project this embankment is a child of
    embankment_location location_obj_t,          --The location for this embankment 
    structure_type	lookup_type_obj_t,           --The lookup code for the type of the embankment structure
    structure_length	BINARY_DOUBLE,           --The overall length of the embankment structure
    upstream_prot_type	lookup_type_obj_t,           --The upstream protection type code for the embankment structure
    upstream_sideslope	BINARY_DOUBLE,           --The upstream side slope of the embankment structure
    downstream_prot_type	lookup_type_obj_t,   --The downstream protection type codefor the embankment structure
    downstream_sideslope	BINARY_DOUBLE,           --The downstream side slope of the embankment structure
    height_max	BINARY_DOUBLE,                   --The maximum height of the embankment structure
    top_width	BINARY_DOUBLE                    --The width at the top of the embankment structure
);
/
show errors


CREATE OR REPLACE TYPE water_user_obj_t AS OBJECT
( 
    project_location_ref    location_ref_t,      --The project that this user is pertaining to.
    entity_name	VARCHAR2(64 BYTE),      --The entity name associated with this user
    water_right	VARCHAR2(255 BYTE)      --The water right of this user
);
/ 
show errors

CREATE OR REPLACE TYPE water_user_contract_ref_t AS OBJECT
(
    water_user	water_user_obj_t,--The water user this record pertains to.  See table AT_WATER_USER.
    contract_name	VARCHAR2(64 BYTE)--The identification name for the contract for this water user contract
);
/
show errors

create or replace type wat_user_contract_obj_t as object
(
    water_user_contract_ref water_user_contract_ref_t,
   
    contracted_storage	BINARY_DOUBLE,--The contracted storage amount for this water user contract

    contract_documents	VARCHAR2(64 BYTE),--The documents for the contract
    water_supply_contract_type lookup_type_obj_t, -- The type of water supply contract. FK'ed to a LU table.

    ws_contract_effective_date	DATE,--The start date of the contract for this water user contract
    ws_contract_expiration_date	DATE,--The expiration date for the contract of this water user contract

    initial_use_allocation	BINARY_DOUBLE,--The initial contracted allocation for this water user contract
    future_use_allocation	BINARY_DOUBLE,--The future contracted allocation for this water user contract

    future_use_percent_activated	BINARY_DOUBLE,--The percent allocated future use for this water user contract
    total_alloc_percent_activated	BINARY_DOUBLE,--The percentage of total allocation for this water user contract
    
    withdraw_location	location_obj_t, --The code for the AT_PHYSICAL_LOCATION record which is the location where this water with be withdrawn from the permanent pool
    supply_location	    location_obj_t --The AT_PHYSICAL_LOCATION record which is the location where this water will be obtained below the dam or within the outlet works
);
/ 
show errors


create or replace type wat_usr_contract_acct_obj_t as object
(
    water_user_contract_ref water_user_contract_ref_t,--The contract for this water movement. SEE AT_WATER_USER_CONTRACT.
    physical_transfer_type	lookup_type_obj_t,--The type of transfer for this water movement.  See AT_LU_PHYSICAL_TRANSFER_TYPE_CODE.
    accounting_credit_debit	VARCHAR2(6 BYTE),--Whether this water movement is a credit or a debit to the contract
    accounting_volume	BINARY_DOUBLE,--The volume associated with the water movement
    transfer_start_datetime	DATE,--The date this water movement began
    transfer_end_datetime	DATE,--the date this water movement stopped
    accounting_remarks	VARCHAR2(255 BYTE) --Any comments regarding this water accounting movement
);
/ 
show errors

CREATE OR REPLACE TYPE wat_usr_contract_acct_tab_t is table of wat_usr_contract_acct_obj_t;
/
show errors






set echo on
--
--
-- create public synonyms for CWMS schema packages and views
-- grant execute on packages to CWMS_USER role
-- grant select on view to CWMS_USER role
--
-- exclude any package or view named like %_SEC_%
--
declare 
   type str_tab_t is table of varchar2(32);
   type_names str_tab_t := str_tab_t();
   sql_statement varchar2(128);
begin
   --
   -- collect CWMS schema object types
   --
   for rec in (
      select object_name 
        from dba_objects 
       where owner = '&cwms_schema'
         and object_type = 'TYPE'
         and object_name not like 'SYS_%')
   loop
      type_names.extend;
      type_names(type_names.last) := rec.object_name;
   end loop;
   
   --
   -- grant execute on COLLECTED types to CWMS_USER role
   --
   dbms_output.put_line('--');
   for i in 1..type_names.count loop
      sql_statement := 'GRANT EXECUTE ON &cwms_schema'||'.'||type_names(i)||' TO CWMS_USER';
      dbms_output.put_line('-- ' || sql_statement);
      execute immediate sql_statement;
   end loop;
end;
/
