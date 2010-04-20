WHENEVER sqlerror exit sql.sqlcode
SET define on
@@../cwms/defines.sql

SET serveroutput on

------------------------------
-- drop types if they exist --
------------------------------

DECLARE
   not_defined        EXCEPTION;
   has_dependencies   EXCEPTION;
   PRAGMA EXCEPTION_INIT (not_defined, -4043);
   PRAGMA EXCEPTION_INIT (has_dependencies, -2303);

   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   dropped_count      PLS_INTEGER;
   defined_count      PLS_INTEGER;
   total_count        PLS_INTEGER := 0;
   pass_count         PLS_INTEGER := 0;
   type_names         id_array_t
      := id_array_t (
'project_obj_t',
'lookup_type_obj_t',
'embank_protection_type_obj_t',
'embank_structure_type_obj_t',
'embankment_obj_t',
'PHYSICAL_TRANSFER_TYPE_OBJ_T',
'water_user_obj_t',
'wat_user_contract_obj_t',
'wat_usr_contract_acct_obj_t'
                    );
BEGIN
   defined_count := type_names.COUNT;

   LOOP
      pass_count := pass_count + 1;
      DBMS_OUTPUT.put_line ('Pass ' || pass_count);
      dropped_count := 0;
      DBMS_OUTPUT.put_line ('');

      FOR i IN type_names.FIRST .. type_names.LAST
      LOOP
         IF LENGTH (type_names (i)) > 0
         THEN
            BEGIN
               EXECUTE IMMEDIATE 'drop type ' || type_names (i);

               DBMS_OUTPUT.put_line ('   Dropped type ' || type_names (i));
               dropped_count := dropped_count + 1;
               total_count := total_count + 1;
               type_names (i) := '';
            EXCEPTION
               WHEN not_defined
               THEN
                  IF pass_count = 1
                  THEN
                     defined_count := defined_count - 1;
                  END IF;
               WHEN has_dependencies
               THEN
                  NULL;
            END;
         END IF;
      END LOOP;

      EXIT WHEN dropped_count = 0;
   END LOOP;

   DBMS_OUTPUT.put_line ('');

   IF total_count != defined_count
   THEN
      DBMS_OUTPUT.put ('*** WARNING: Only ');
   END IF;

   DBMS_OUTPUT.put_line (   ''
                         || total_count
                         || ' out of '
                         || defined_count
                         || ' types dropped'
                        );
END;
/
show errors


--location objectss.



--project object.
CREATE OR REPLACE TYPE project_obj_t AS OBJECT (
    --locations
    --the office id for the base location
    db_office_id 			VARCHAR2(16),

    -- the location associated with this project,
    --an instance of the location type.
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

create or replace type lookup_type_obj_t as object
(
    display_value	varchar2(25 byte),  --The value to display for this lookup record
    tooltip	varchar2(255 byte),     --The tooltip or meaning of this lookup record
    active	varchar2(1 byte)	--Whether this lookup record entry is currently active
);
/
show errors

CREATE OR REPLACE TYPE embankment_obj_t AS OBJECT
( 
    project_location_ref	location_ref_t,          --The project this embankment is a child of
    embankment_location location_obj_t,          --The location for this embankment 
    structure_type	lookup_type_obj_t,           --The lookup code for the type of the embankment structure
    structure_length	number,           --The overall length of the embankment structure
    upstream_prot_type	lookup_type_obj_t,           --The upstream protection type code for the embankment structure
    upstream_sideslope	number,           --The upstream side slope of the embankment structure
    downstream_prot_type	lookup_type_obj_t,   --The downstream protection type codefor the embankment structure
    downstream_sideslope	number,           --The downstream side slope of the embankment structure
    height_max	number,                   --The maximum height of the embankment structure
    top_width	number                    --The width at the top of the embankment structure
);
/
show errors

create or replace type water_user_obj_t as object
( 
    project_location_ref    location_ref_t,      --The project that this user is pertaining to.
    ENTITY_NAME	VARCHAR2(64 BYTE),      --The entity name associated with this user
    WATER_RIGHT	VARCHAR2(255 BYTE)      --The water right of this user
);
/ 
show errors

create or replace type wat_user_contract_obj_t as object
( 
    
    CONTRACT_WATER_USER	water_user_obj_t,--The water user this record pertains to.  See table AT_WATER_USER.
    CONTRACT_NAME	VARCHAR2(64 BYTE),--The identification name for the contract for this water user contract
    SUPPLY_LOCATION	location_ref_t,--The location where the supply of water for this contract will come from.  See AT_PHYSICAL_LOCATION
    CONTRACTED_STORAGE	NUMBER,--The contracted storage amount for this water user contract
    CONTRACT_DOCUMENTS	VARCHAR2(64 BYTE),--The documents for the contract
    WS_CONTRACT_EFFECTIVE_DATE	DATE,--The start date of the contract for this water user contract
    WS_CONTRACT_EXPIRATION_DATE	DATE,--The expiration date for the contract of this water user contract
    INITIAL_USE_ALLOCATION	NUMBER,--The initial contracted allocation for this water user contract
    FUTURE_USE_ALLOCATION	NUMBER,--The future contracted allocation for this water user contract
    FUTURE_USE_PERCENT_ACTIVATED	NUMBER,--The percent allocated future use for this water user contract
    TOTAL_ALLOC_PERCENT_ACTIVATED	NUMBER,--The percentage of total allocation for this water user contract
    WITHDRAW_LOCATION	location_ref_t --The location where this user contract withdraws or pumps out their water
);
/ 
show errors

create or replace type wat_usr_contract_acct_obj_t as object
(
    WUSR_CONTRACT_ACCT_CONTR	wat_user_contract_obj_t,--The contract for this water movement. SEE AT_WATER_USER_CONTRACT.
    PHYSICAL_TRANSFER_TYPE	lookup_type_obj_t,--The type of transfer for this water movement.  See AT_LU_PHYSICAL_TRANSFER_TYPE_CODE.
    ACCOUNTING_CREDIT_DEBIT	VARCHAR2(6 BYTE),--Whether this water movement is a credit or a debit to the contract
    ACCOUNTING_VOLUME	NUMBER,--The volume associated with the water movement
    TRANSFER_START_DATETIME	DATE,--The date this water movement began
    TRANSFER_END_DATETIME	DATE,--the date this water movement stopped
    ACCOUNTING_REMARKS	VARCHAR2(255 BYTE) --Any comments regarding this water accounting movement
);
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
