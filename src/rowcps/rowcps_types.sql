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

create or replace type embankment_obj_t as object
( 
    embankment_code	number,                   --The unique surrogate key (code) for this embankment structure
    embankment_project_loc	project_obj_t,          --The project this embankment is a child of
    embankment_id	varchar2(32 byte),              --The identification (id) of the embankment structure
    structure_type	embank_structure_type_obj_t,           --The lookup code for the type of the embankment structure
    structure_length	number,           --The overall length of the embankment structure
    upstream_prot_type	embank_protection_type_obj_t,           --The upstream protection type code for the embankment structure
    upstream_sideslope	number,           --The upstream side slope of the embankment structure
    downstream_prot_type	embank_protection_type_obj_t,   --The downstream protection type codefor the embankment structure
    downstream_sideslope	number,           --The downstream side slope of the embankment structure
    height_max	number,                   --The maximum height of the embankment structure
    top_width	number                    --The width at the top of the embankment structure
);

create or replace
type embank_protection_type_obj_t as object
(
protection_type_display_value	varchar2(25 byte),  --The value to display for this protection_type code record
protection_type_tooltip	varchar2(255 byte),     --The tooltip or meaning of this protection_type code record
protection_type_active	varchar2(1 byte)	--Whether this protection_type entry is currently active
);

create or replace
type embank_structure_type_obj_t as object
( 
structure_type_display_value	varchar2(25 byte),	--The value to display for this structure_type code record
structure_type_tooltip	varchar2(255 byte),	--The tooltip or meaning of this structure_type code record
structure_type_active	varchar2(1 byte)	--Whether this structure type entry is currently active
);

create or replace
TYPE PHYSICAL_TRANSFER_TYPE_OBJ_T as object
( 
phys_trans_type_display_value	varchar2(25 byte),--The value to display for this physical_transfer_type record
physical_transfer_type_tooltip	varchar2(255 byte),--The description or meaning of this physical_transfer_type record
physical_transfer_type_active	varchar2(1 byte)--Whether this physical_transfer_type entry is currently active
);

create or replace
type water_user_obj_t as object
( 
WATER_USER_PROJECT_LOC_CODE	cat_location2_obj_t,      --The project that this user is pertaining to.
ENTITY_NAME	VARCHAR2(64 BYTE),      --The entity name associated with this user
WATER_RIGHT	VARCHAR2(255 BYTE)      --The water right of this user
);
   
create or replace
type wat_user_contract_obj_t as object
( 

CONTRACT_WATER_USER	water_user_obj_t,--The water user this record pertains to.  See table AT_WATER_USER.
CONTRACT_NAME	VARCHAR2(64 BYTE),--The identification name for the contract for this water user contract
SUPPLY_LOCATION	cat_location2_obj_t,--The location where the supply of water for this contract will come from.  See AT_PHYSICAL_LOCATION
CONTRACTED_STORAGE	NUMBER,--The contracted storage amount for this water user contract
CONTRACT_DOCUMENTS	VARCHAR2(64 BYTE),--The documents for the contract
WS_CONTRACT_EFFECTIVE_DATE	DATE,--The start date of the contract for this water user contract
WS_CONTRACT_EXPIRATION_DATE	DATE,--The expiration date for the contract of this water user contract
INITIAL_USE_ALLOCATION	NUMBER,--The initial contracted allocation for this water user contract
FUTURE_USE_ALLOCATION	NUMBER,--The future contracted allocation for this water user contract
FUTURE_USE_PERCENT_ACTIVATED	NUMBER,--The percent allocated future use for this water user contract
TOTAL_ALLOC_PERCENT_ACTIVATED	NUMBER,--The percentage of total allocation for this water user contract
WITHDRAW_LOCATION	cat_location2_obj_t --The location where this user contract withdraws or pumps out their water
);

create or replace
type wat_usr_contract_acct_obj_t as object
(
WUSR_CONTRACT_ACCT_CONTR	wat_user_contract_obj_t,--The contract for this water movement. SEE AT_WATER_USER_CONTRACT.
PHYSICAL_TRANSFER_TYPE	physical_transfer_type_obj_t,--The type of transfer for this water movement.  See AT_LU_PHYSICAL_TRANSFER_TYPE_CODE.
ACCOUNTING_CREDIT_DEBIT	VARCHAR2(6 BYTE),--Whether this water movement is a credit or a debit to the contract
ACCOUNTING_VOLUME	NUMBER,--The volume associated with the water movement
TRANSFER_START_DATETIME	DATE,--The date this water movement began
TRANSFER_END_DATETIME	DATE,--the date this water movement stopped
ACCOUNTING_REMARKS	VARCHAR2(255 BYTE) --Any comments regarding this water accounting movement

);
   
   
   
/
show errors;

GRANT EXECUTE ON PROJECT_OBJ_T TO CWMS_USER;

