
SET serveroutput on
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------

DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   table_names       id_array_t
      := id_array_t ('AT_CONSTRUCTION_HISTORY',                                       
					 'AT_DOCUMENT',                                                   
					 'AT_EMBANKMENT',                                                 
					 'AT_LOCK',                                                 
					 'AT_LOCKAGE_CHANGE',                                                
					 'AT_GATE_CHANGE',                                                
					 'AT_PROJECT_GATE_CHANGE',                                                
					 'AT_PROJECT_TURBINE_CHANGE',                                                
					 'AT_OUTLET_CHARACTERISTIC',                                      
					 'AT_PROJECT',                                                    
					 'AT_PROJECT_AGREEMENT',                                          
					 'AT_PROJECT_CHARACTERISTIC',                                     
					 'AT_PROJECT_CONGRESS_DISTRICT',                                  
					 'AT_PROJECT_PURPOSE',                                            
					 'AT_TURBINE_CHARACTERISTIC',                                     
					 'AT_TURBINE_SETTING',                                     
					 'AT_WATER_USER_ACCOUNTING',                                      
					 'AT_WATER_USER', 
					 'AT_GATE_SETTING',
					 'AT_LU_COMPUTATION_CODE',
					 'AT_LU_RELEASE_CODE',
					 'AT_LU_PROJECT_PURPOSE',
					 'AT_LU_DOCUMENT_TYPE',
					 'AT_LU_PROTECTION_TYPE',
					 'AT_LU_STRUCTURE_TYPE',
					 'AT_LU_TURBINE_SETTING'
                    );
   mview_log_names   id_array_t
      := id_array_t (' '
                    );
BEGIN
   FOR i IN table_names.FIRST .. table_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop table '
                           || table_names (i)
                           || ' cascade constraints purge';

         DBMS_OUTPUT.put_line ('Dropped table ' || table_names (i));
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;

   FOR i IN mview_log_names.FIRST .. mview_log_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop materialized view log on '
                           || mview_log_names (i);

         DBMS_OUTPUT.put_line (   'Dropped materialized view log on '
                               || mview_log_names (i)
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/

-------------------
-- CREATE TABLES --
-------------------

CREATE TABLE at_lu_computation_code
(
  computation_code  				NUMBER(10)			NOT NULL,
  computation_code_display_value	VARCHAR2(25 BYTE)	NOT NULL,
  computation_code_description		VARCHAR2(255 BYTE)  NOT NULL,
  computation_code_active			VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_computation_code.computation_code IS 'The unique id for this lookup record';
COMMENT ON COLUMN at_lu_computation_code.computation_code_display_value IS 'The value to display for this LU record';
COMMENT ON COLUMN at_lu_computation_code.computation_code_description IS 'The description or meaning of this LU record';
COMMENT ON COLUMN at_lu_computation_code.computation_code_active IS 'Whether the lu entry is currently active';
/

ALTER TABLE at_lu_computation_code ADD (
  CONSTRAINT at_lu_computation_code_pk
 PRIMARY KEY
 (computation_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

--------
--------

CREATE TABLE at_lu_release_code
(
  release_code	  				NUMBER(10)			NOT NULL,
  release_code_display_value	VARCHAR2(25 BYTE)	NOT NULL,
  release_code_description		VARCHAR2(255 BYTE)  NOT NULL,
  release_code_active			VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_release_code.release_code IS 'The unique id for this release code record';
COMMENT ON COLUMN at_lu_release_code.release_code_display_value IS 'The value to display for this release code record';
COMMENT ON COLUMN at_lu_release_code.release_code_description IS 'The description or meaning of this release code record';
COMMENT ON COLUMN at_lu_release_code.release_code_active IS 'Whether the release code entry is currently active';
/

ALTER TABLE at_lu_release_code ADD (
  CONSTRAINT at_lu_release_code_pk
 PRIMARY KEY
 (release_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

--------
--------

CREATE TABLE at_lu_project_purpose
(
  purpose_code  				NUMBER(10)			NOT NULL,
  purpose_code_display_value	VARCHAR2(25 BYTE)	NOT NULL,
  purpose_code_description		VARCHAR2(255 BYTE)  NOT NULL,
  purpose_code_active			VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_project_purpose.purpose_code IS 'The unique id for this project_purpose code record';
COMMENT ON COLUMN at_lu_project_purpose.purpose_code_display_value IS 'The value to display for this project_purpose code record';
COMMENT ON COLUMN at_lu_project_purpose.purpose_code_description IS 'The description or meaning of this project_purpose code record';
COMMENT ON COLUMN at_lu_project_purpose.purpose_code_active IS 'Whether the project_purpose code entry is currently active';
/

ALTER TABLE at_lu_project_purpose ADD (
  CONSTRAINT at_lu_project_purpose_pk
 PRIMARY KEY
 (purpose_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

--------
--------

CREATE TABLE at_lu_document_type
(
  document_type_code  				NUMBER(10)			NOT NULL,
  document_type_display_value		VARCHAR2(25 BYTE)	NOT NULL,
  document_type_description			VARCHAR2(255 BYTE)  NOT NULL,
  document_type_active				VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_document_type.document_type_code IS 'The unique id for this document_type code record';
COMMENT ON COLUMN at_lu_document_type.document_type_display_value IS 'The value to display for this document_type code record';
COMMENT ON COLUMN at_lu_document_type.document_type_description IS 'The description or meaning of this document_type code record';
COMMENT ON COLUMN at_lu_document_type.document_type_active IS 'Whether this document type code entry is currently active';
/

ALTER TABLE at_lu_document_type ADD (
  CONSTRAINT at_lu_document_type_pk
 PRIMARY KEY
 (document_type_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
--------
--------

CREATE TABLE at_lu_structure_type
(
  structure_type_code  				NUMBER(10)			NOT NULL,
  structure_type_display_value		VARCHAR2(25 BYTE)	NOT NULL,
  structure_type_description		VARCHAR2(255 BYTE)  NOT NULL,
  structure_type_active				VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_structure_type.structure_type_code IS 'The unique id for this structure_type code record';
COMMENT ON COLUMN at_lu_structure_type.structure_type_display_value IS 'The value to display for this structure_type code record';
COMMENT ON COLUMN at_lu_structure_type.structure_type_description IS 'The description or meaning of this structure_type code record';
COMMENT ON COLUMN at_lu_structure_type.structure_type_active IS 'Whether this structure type entry is currently active';
/

ALTER TABLE at_lu_structure_type ADD (
  CONSTRAINT at_lu_structure_type_pk
 PRIMARY KEY
 (structure_type_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

--------
--------

CREATE TABLE at_lu_protection_type
(
  protection_type_code  			NUMBER(10)			NOT NULL,
  protection_type_display_value		VARCHAR2(25 BYTE)	NOT NULL,
  protection_type_description		VARCHAR2(255 BYTE)  NOT NULL,
  protection_type_active			VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_protection_type.protection_type_code IS 'The unique id for this protection_type code record';
COMMENT ON COLUMN at_lu_protection_type.protection_type_display_value IS 'The value to display for this protection_type code record';
COMMENT ON COLUMN at_lu_protection_type.protection_type_description IS 'The description or meaning of this protection_type code record';
COMMENT ON COLUMN at_lu_protection_type.protection_type_active IS 'Whether this protection_type entry is currently active';
/

ALTER TABLE at_lu_protection_type ADD (
  CONSTRAINT at_lu_protection_type_pk
 PRIMARY KEY
 (protection_type_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

--------
--------

CREATE TABLE at_lu_turbine_setting
(
  turbine_setting_code  			NUMBER(10)			NOT NULL,
  turbine_setting_display_value		VARCHAR2(25 BYTE)	NOT NULL,
  turbine_setting_description		VARCHAR2(255 BYTE)  NOT NULL,
  turbine_setting_active			VARCHAR2(1)			NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lu_turbine_setting.turbine_setting_code IS 'The unique id for this turbine_setting code record';
COMMENT ON COLUMN at_lu_turbine_setting.turbine_setting_display_value IS 'The value to display for this turbine_setting code record';
COMMENT ON COLUMN at_lu_turbine_setting.turbine_setting_description IS 'The description or meaning of this turbine_setting code record';
COMMENT ON COLUMN at_lu_turbine_setting.turbine_setting_active IS 'Whether this turbine_setting entry is currently active';
/

ALTER TABLE at_lu_turbine_setting ADD (
  CONSTRAINT at_lu_turbine_setting_pk
 PRIMARY KEY
 (turbine_setting_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

--------
--------

CREATE TABLE at_project
(
  location_code				NUMBER(10)	NOT NULL,
  project_effective_date	DATE		NOT NULL,
  project_expiration_date	DATE,
  parent_location_code      NUMBER(10),
  authorizing_law			VARCHAR2(32),
  federal_cost				NUMBER,
  nonfederal_cost			NUMBER,
  cost_year					DATE,
  federal_om_cost			NUMBER(10),
  nonfederal_om_cost		NUMBER(10),
  remarks					VARCHAR2(1000),
  project_owner				VARCHAR2(255),
  lock_lift					NUMBER(10),
  lock_flow					NUMBER(10),
  river_mile				NUMBER(10),
  has_hydropower			VARCHAR2(1),
  turbine_count				NUMBER(10),
  hydropower_description	VARCHAR2(255),
  operating_purposes		VARCHAR2(255),
  authorized_purposes		VARCHAR2(255),
  pump_back_location_code	NUMBER(10),
  near_gage_location_code	NUMBER(10)	
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project.project_effective_date IS 'The date the project effectively began';
COMMENT ON COLUMN at_project.project_expiration_date IS 'The data the project effectively ended';
COMMENT ON COLUMN at_project.parent_location_code IS 'The parent project of this project, heirarically speaking';
COMMENT ON COLUMN at_project.authorizing_law IS 'The law authorizing this project';
COMMENT ON COLUMN at_project.federal_cost IS 'The federal cost of this project';
COMMENT ON COLUMN at_project.nonfederal_cost IS 'The non-federal cost of this project';
COMMENT ON COLUMN at_project.cost_year IS 'The cost per year of this project';
COMMENT ON COLUMN at_project.federal_om_cost IS 'The om federal cost of this project';
COMMENT ON COLUMN at_project.nonfederal_om_cost IS 'the non-federal cost of this project';
COMMENT ON COLUMN at_project.remarks IS 'The general remarks regarding this project';
COMMENT ON COLUMN at_project.project_owner IS 'The assigned owner of this project';
COMMENT ON COLUMN at_project.lock_lift IS 'The lock lift of this poject if any';
COMMENT ON COLUMN at_project.lock_flow IS 'The lock flow of this project if any';
COMMENT ON COLUMN at_project.river_mile IS 'The river mile this project is located near if any';
COMMENT ON COLUMN at_project.has_hydropower IS 'Whether this particular project has hydro-power';
COMMENT ON COLUMN at_project.turbine_count IS 'The turbine count of this project if any';
COMMENT ON COLUMN at_project.hydropower_description IS 'The description of the hydro-power located at this project';
COMMENT ON COLUMN at_project.operating_purposes IS 'The operating purposes of this project';
COMMENT ON COLUMN at_project.authorized_purposes IS 'The authorized purposes of this project';
COMMENT ON COLUMN at_project.pump_back_location_code IS 'The location code where the water is pumped back to';
COMMENT ON COLUMN at_project.near_gage_location_code IS 'The location code known as the near gage for the project';

/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_pk
 PRIMARY KEY
 (location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk_2
 FOREIGN KEY (parent_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk_3
 FOREIGN KEY (pump_back_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk_4
 FOREIGN KEY (near_gage_location_code)
 REFERENCES at_physical_location (location_code))
/


--------
--------

CREATE TABLE at_embankment
(
  location_code				NUMBER(10)			NOT NULL,
  embankment_id				VARCHAR2(32 BYTE)	NOT NULL,
  structure_type_code		NUMBER(10)			NOT NULL,
  structure_length			NUMBER(10),
  upstream_prot_type_code	NUMBER(10),
  upstream_sideslope		NUMBER(10),
  downstream_prot_type_code	NUMBER(10),
  downstream_sideslope		NUMBER(10),
  height_max				NUMBER(10),
  top_width					NUMBER(10)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_embankment.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_embankment.embankment_id IS 'The identification (id) of the embankment structure';
COMMENT ON COLUMN at_embankment.structure_type_code IS 'The lookup code for the type of the embankment structure';
COMMENT ON COLUMN at_embankment.structure_length IS 'The overall length of the embankment structure';
COMMENT ON COLUMN at_embankment.upstream_prot_type_code IS 'The upstream protection type code for the embankment structure';
COMMENT ON COLUMN at_embankment.upstream_sideslope IS 'The upstream side slope of the embankment structure';
COMMENT ON COLUMN at_embankment.downstream_prot_type_code IS 'The downstream protection type codefor the embankment structure';
COMMENT ON COLUMN at_embankment.downstream_sideslope IS 'The downstream side slope of the embankment structure';
COMMENT ON COLUMN at_embankment.height_max IS 'THe maximum height of the embankment structure';
COMMENT ON COLUMN at_embankment.top_width IS 'The width at the top of the embankment structure';

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_pk
 PRIMARY KEY
 (location_code,embankment_id)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk_2
 FOREIGN KEY (structure_type_code)
 REFERENCES at_lu_structure_type (structure_type_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk_3
 FOREIGN KEY (upstream_prot_type_code)
 REFERENCES at_lu_protection_type (protection_type_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk_4
 FOREIGN KEY (downstream_prot_type_code)
 REFERENCES at_lu_protection_type (protection_type_code))
/

--------
--------

CREATE TABLE at_lock
(
  location_code				NUMBER(10)			NOT NULL,
  project_location_code		NUMBER(10)			NOT NULL,
  lock_width				NUMBER(10),
  lock_length				NUMBER(10),
  volume_per_lockage		NUMBER(10),
  draft						NUMBER(10),
  normal_lock_lift			NUMBER(10)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lock.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_lock.project_location_code IS 'The project that this lock is part of';
COMMENT ON COLUMN at_lock.lock_width IS 'The overall width of the lock structure';
COMMENT ON COLUMN at_lock.lock_length IS 'The overall length of the lock structure';
COMMENT ON COLUMN at_lock.volume_per_lockage IS 'The volume of water contained in the lock structure';
COMMENT ON COLUMN at_lock.draft IS 'The draft of this particular lock';

ALTER TABLE at_lock ADD (
  CONSTRAINT at_lock_pk
 PRIMARY KEY
 (location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_lock ADD (
  CONSTRAINT at_lock_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_lock ADD (
  CONSTRAINT at_lock_fk_2
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (location_code))
/

--------
--------

CREATE TABLE at_lockage_change
(
  lockage_change_code			NUMBER(10)			NOT NULL,
  location_code					NUMBER(10)			NOT NULL,
  change_date					DATE				NOT NULL,
  direction_of_travel			VARCHAR2(255 BYTE),
  number_boats					NUMBER(10),
  number_barges					NUMBER(10),
  tonnage						NUMBER(10),
  additional_notes				VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_lockage_change.lockage_change_code IS 'Unique record identifier for every lock change on a project.  IS automatically created';
COMMENT ON COLUMN at_lockage_change.location_code IS 'The lock that has been activated';
COMMENT ON COLUMN at_lockage_change.change_date IS 'THe date of the Lock change';
COMMENT ON COLUMN at_lockage_change.direction_of_travel IS 'The direction of the water vehicles for this lock change';
COMMENT ON COLUMN at_lockage_change.number_boats IS 'The number of boats accomodated for this lock change';
COMMENT ON COLUMN at_lockage_change.number_barges IS 'The number of barges accomodated for this lock change';
COMMENT ON COLUMN at_lockage_change.tonnage IS 'The tonnage of product accomodated for this lock change';
COMMENT ON COLUMN at_lockage_change.additional_notes IS 'Any notes pertinent to this lock change';
/

ALTER TABLE at_lockage_change ADD (
  CONSTRAINT at_lockage_change_pk
 PRIMARY KEY
 (lockage_change_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_lockage_change ADD (
  CONSTRAINT at_lockage_change_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_lock (location_code))
/

--------
--------

CREATE TABLE at_project_turbine_change
(
  turbine_change_code			NUMBER(10)			NOT NULL,
  location_code					NUMBER(10)			NOT NULL,
  change_date					DATE				NOT NULL,
  old_totalq_override			NUMBER(10),
  new_totalq_override			NUMBER(10),
  additional_notes				VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project_turbine_change.turbine_change_code IS 'Unique record identifier for every turbine change on a project.  IS automatically created';
COMMENT ON COLUMN at_project_turbine_change.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project_turbine_change.change_date IS 'THe date of the turbine change';
COMMENT ON COLUMN at_project_turbine_change.old_totalq_override IS 'The total Q rate before the turbine change';
COMMENT ON COLUMN at_project_turbine_change.new_totalq_override IS 'The total Q rate after the turbine change';
COMMENT ON COLUMN at_project_turbine_change.additional_notes IS 'Any notes pertinent to this turbine change';
/

ALTER TABLE at_project_turbine_change ADD (
  CONSTRAINT at_project_turbine_change_pk
 PRIMARY KEY
 (turbine_change_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project_turbine_change ADD (
  CONSTRAINT at_project_turbine_change_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

--------
--------

CREATE TABLE at_turbine_characteristic
(
  location_code				NUMBER(10)			NOT NULL,
  project_location_code		NUMBER(10),
  rated_capacity			NUMBER(10),
  min_generation_flow		NUMBER(10),
  max_generation_flow		NUMBER(10),
  description				VARCHAR2(255 BYTE),
  operation_rule_set		VARCHAR2(255 BYTE),
  rating_code				NUMBER(10)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_turbine_characteristic.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_turbine_characteristic.project_location_code IS 'The project this turbine is related to';
COMMENT ON COLUMN at_turbine_characteristic.rated_capacity IS 'The capacity rating for the turbine';
COMMENT ON COLUMN at_turbine_characteristic.min_generation_flow IS 'The minimum flow required to utilize the turbine';
COMMENT ON COLUMN at_turbine_characteristic.max_generation_flow IS 'The maximum flow capacity for the turbine';
COMMENT ON COLUMN at_turbine_characteristic.description IS 'The description of the turbine';
COMMENT ON COLUMN at_turbine_characteristic.operation_rule_set IS 'The operational rule set for this turbine';
/

ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_pk
 PRIMARY KEY
 (location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_fk_2
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_fk_3
 FOREIGN KEY (rating_code)
 REFERENCES at_rating (rating_code))
/

--------
--------

CREATE TABLE at_turbine_setting
(
  turbine_change_code			NUMBER(10)			NOT NULL,
  location_code					NUMBER(10)			NOT NULL,
  turbine_setting_code			NUMBER(10)			NOT NULL,
  load							NUMBER(10),
  power							NUMBER(10),
  energy_rate					NUMBER(10),
  additional_notes				VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_turbine_setting.turbine_change_code IS 'The turbine change event unique identifier';
COMMENT ON COLUMN at_turbine_setting.location_code IS 'The unique individual turbine that is being changed';
COMMENT ON COLUMN at_turbine_setting.turbine_setting_code IS 'The new turbine lookup  setting code';
COMMENT ON COLUMN at_turbine_setting.load IS 'The load factor for the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.power IS 'The power rate for the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.energy_rate IS 'The energy rate for the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.additional_notes IS 'The additional notes pertinent to this turbine change';
/

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_pk
 PRIMARY KEY
 (turbine_change_code,location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk_1
 FOREIGN KEY (turbine_change_code)
 REFERENCES at_project_turbine_change (turbine_change_code))
/

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk_2
 FOREIGN KEY (location_code)
 REFERENCES at_turbine_characteristic (location_code))
/

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk_3
 FOREIGN KEY (turbine_setting_code)
 REFERENCES at_lu_turbine_setting (turbine_setting_code))
/

--------
--------

CREATE TABLE at_project_congress_district
(
  location_code				NUMBER(10)			NOT NULL,
  state_id					VARCHAR2(2 BYTE)	NOT NULL,
  congressional_district	NUMBER(10)			NOT NULL,
  district_remarks			VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project_congress_district.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project_congress_district.state_id IS 'The state abbreviation this project is located in';
COMMENT ON COLUMN at_project_congress_district.congressional_district IS 'The congressional district of the project';
COMMENT ON COLUMN at_project_congress_district.district_remarks IS 'Any remarks associated with this states congressional district regarding this project';
/

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_proj_congress_district_pk
 PRIMARY KEY
 (location_code,state_id,congressional_district)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_project_congress_distr_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

--------
--------

CREATE TABLE at_project_characteristic
(
  location_code						NUMBER(10)			NOT NULL,
  seasonal_pool_ord_number			NUMBER(10),
  spillway_notch_length				NUMBER(10),
  sedimentation_description			VARCHAR2(255 BYTE),
  downstream_urban_descrition		VARCHAR2(255 BYTE),
  bank_full_capacity_description	VARCHAR2(255 BYTE),
  yield_time_frame_start			DATE,
  yield_time_frame_end				DATE
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project_characteristic.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project_characteristic.seasonal_pool_ord_number IS 'The ordinal number of the seasonal pool';
COMMENT ON COLUMN at_project_characteristic.spillway_notch_length IS 'The length of the spillways notch';
COMMENT ON COLUMN at_project_characteristic.sedimentation_description IS 'The description of the projects sedimentation';
COMMENT ON COLUMN at_project_characteristic.downstream_urban_descrition IS 'The description of the urban are downstream';
COMMENT ON COLUMN at_project_characteristic.bank_full_capacity_description IS 'The description of the full capacity';
COMMENT ON COLUMN at_project_characteristic.yield_time_frame_start IS 'The start date of the yield time frame';
COMMENT ON COLUMN at_project_characteristic.yield_time_frame_end IS 'The end date of the yield time frame';
/

ALTER TABLE at_project_characteristic ADD (
  CONSTRAINT at_project_characteristic_pk
 PRIMARY KEY
 (location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project_characteristic ADD (
  CONSTRAINT at_project_characteristic_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/


--------
--------

CREATE TABLE at_project_gate_change
(
  gate_change_code				NUMBER(10)			NOT NULL,
  location_code					NUMBER(10)			NOT NULL,
  change_date					DATE				NOT NULL,
  elevation_tail				NUMBER(10),
  pool_elev						NUMBER(10),
  old_discharge_total_override	NUMBER(10),
  new_discharge_total_override	NUMBER(10),
  computation_code  			NUMBER(10),
  release_code	  				NUMBER(10),
  additional_notes				VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project_gate_change.gate_change_code IS 'Unique record identifier for every gate change on a project.  IS automatically created';
COMMENT ON COLUMN at_project_gate_change.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project_gate_change.change_date IS 'THe date of the Gate change';
COMMENT ON COLUMN at_project_gate_change.elevation_tail IS 'The tail elevation at the time of the gate change';
COMMENT ON COLUMN at_project_gate_change.pool_elev IS 'the pool elevation at the time of the gate change';
COMMENT ON COLUMN at_project_gate_change.old_discharge_total_override IS 'The discharge rate before the gate change';
COMMENT ON COLUMN at_project_gate_change.new_discharge_total_override IS 'The discharge rate after the gate change';
COMMENT ON COLUMN at_project_gate_change.computation_code IS 'The code for the computation code given for the gate change';
COMMENT ON COLUMN at_project_gate_change.release_code IS 'The code for the release code issued for the gate change';
COMMENT ON COLUMN at_project_gate_change.additional_notes IS 'Any notes pertinent to this gate change';
/

ALTER TABLE at_project_gate_change ADD (
  CONSTRAINT at_project_gate_change_pk
 PRIMARY KEY
 (gate_change_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project_gate_change ADD (
  CONSTRAINT at_project_gate_change_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_project_gate_change ADD (
  CONSTRAINT at_project_gate_change_fk_2
 FOREIGN KEY (computation_code)
 REFERENCES at_lu_computation_code (computation_code))
/

ALTER TABLE at_project_gate_change ADD (
  CONSTRAINT at_project_gate_change_fk_3
 FOREIGN KEY (release_code)
 REFERENCES at_lu_release_code (release_code))
/

--------
--------

CREATE TABLE at_gate_setting
(
  gate_change_code				NUMBER(10)			NOT NULL,
  location_code					NUMBER(10)			NOT NULL,
  gate_setting_code				VARCHAR2(10 BYTE)	NOT NULL,
  gate_opening					NUMBER(10)			NOT NULL,
  old_discharge					NUMBER(10),
  new_discharge					NUMBER(10),
  additional_notes				VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_gate_setting.gate_change_code IS 'THe unique record for the overall gate change';
COMMENT ON COLUMN at_gate_setting.location_code IS 'THe unique gate that is being set';
COMMENT ON COLUMN at_gate_setting.gate_setting_code IS 'The new gate setting code';
COMMENT ON COLUMN at_gate_setting.gate_opening IS 'The new gate opening setting';
COMMENT ON COLUMN at_gate_setting.old_discharge IS 'The discharge rate prior to the gate setting';
COMMENT ON COLUMN at_gate_setting.new_discharge IS 'The discharge rate after the new gate setting';
COMMENT ON COLUMN at_gate_setting.additional_notes IS 'The additional notes pertinent to this gate setting';
/

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_pk
 PRIMARY KEY
 (gate_change_code,location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_fk_1
 FOREIGN KEY (gate_change_code)
 REFERENCES at_project_gate_change (gate_change_code))
/

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_fk_2
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/

--------
--------

CREATE TABLE at_outlet_characteristic
(
  location_code					NUMBER(10)			NOT NULL,
  gate_count					NUMBER(10),
  gate_size						NUMBER(10),
  opening_size					NUMBER(10),
  invert_elev					NUMBER(10),
  flow_capacity_max				NUMBER(10),
  height						NUMBER(10),
  width							NUMBER(10),
  net_length					NUMBER(10),
  loc_group_code				NUMBER(10)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_outlet_characteristic.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_outlet_characteristic.gate_count IS 'The count of the number of gates at this outlet';
COMMENT ON COLUMN at_outlet_characteristic.gate_size IS 'the size of the gate';
COMMENT ON COLUMN at_outlet_characteristic.opening_size IS 'The opening size for the gate';
COMMENT ON COLUMN at_outlet_characteristic.invert_elev IS 'The elevation of the invertion';
COMMENT ON COLUMN at_outlet_characteristic.flow_capacity_max IS 'the maximum flow capacity of the gate';
COMMENT ON COLUMN at_outlet_characteristic.height IS 'The height of the gate';
COMMENT ON COLUMN at_outlet_characteristic.width IS 'The width of the gate';
COMMENT ON COLUMN at_outlet_characteristic.net_length IS 'The net length of the gate';
COMMENT ON COLUMN at_outlet_characteristic.loc_group_code IS 'The logical fgrouping this gate belongs with';
/

ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_pk
 PRIMARY KEY
 (location_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

--------
--------

CREATE TABLE at_document
(
  document_id					VARCHAR2(64 BYTE)	NOT NULL,
  location_code					NUMBER(10),
  document_type_code			NUMBER(10)			NOT NULL,
  document_url					VARCHAR2(100 BYTE),
  document_date					DATE				NOT NULL,
  document_mod_date				DATE,
  document_obsolete_date		DATE,
  description_id				VARCHAR2(256 BYTE)	NOT NULL,
  stored_document				BLOB
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_document.document_id IS 'The unique identifier for the indifidual document, system generated';
COMMENT ON COLUMN at_document.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_document.document_type_code IS 'The lu code for the type of the document';
COMMENT ON COLUMN at_document.document_url IS 'The URL where the document could be found';
COMMENT ON COLUMN at_document.document_date IS 'The initail date of the document';
COMMENT ON COLUMN at_document.document_mod_date IS 'The last modified date of the document';
COMMENT ON COLUMN at_document.document_obsolete_date IS 'THe date the document became obsolete';
COMMENT ON COLUMN at_document.description_id IS 'The description id where the document is described';
COMMENT ON COLUMN at_document.stored_document IS 'The actual storage of the document';
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_pk
 PRIMARY KEY
 (document_id)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk_2
 FOREIGN KEY (description_id)
 REFERENCES at_clob (id))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk_3
 FOREIGN KEY (document_type_code)
 REFERENCES at_lu_document_type (document_type_code))
/

--------
--------

CREATE TABLE at_water_user
(
  location_code					NUMBER(10)			NOT NULL,
  contract_id					VARCHAR2(64 BYTE)	NOT NULL,
  contract_effective_date		DATE				NOT NULL,
  contract_expiration_date		DATE				NOT NULL,
  contracted_storage			NUMBER(10),
  water_right					VARCHAR2(255 BYTE),
  initial_use_allocation		NUMBER(10),
  future_use_allocation			NUMBER(10),
  future_use_percent_activated	NUMBER(10),
  total_alloc_percent_activated NUMBER(10),
  document_id					VARCHAR2(64 BYTE),
  entity_name					VARCHAR2(64 BYTE),
  withdraw_location_code		NUMBER(10)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_water_user.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_water_user.contract_id IS 'The identification number of the contract for this user';
COMMENT ON COLUMN at_water_user.contract_effective_date IS 'The start date of the contract for this user';
COMMENT ON COLUMN at_water_user.contract_expiration_date IS 'The expiration date for the contract of this user';
COMMENT ON COLUMN at_water_user.contracted_storage IS 'The contracted storage amount for this user';
COMMENT ON COLUMN at_water_user.water_right IS 'The water right of this user';
COMMENT ON COLUMN at_water_user.initial_use_allocation IS 'The initial contracted allocation for this user';
COMMENT ON COLUMN at_water_user.future_use_allocation IS 'The future contracted allocation for this user';
COMMENT ON COLUMN at_water_user.future_use_percent_activated IS 'The percent allocated future use for this user';
COMMENT ON COLUMN at_water_user.total_alloc_percent_activated IS 'The percentage of total allocation for this user';
COMMENT ON COLUMN at_water_user.document_id IS 'The document id for the contract';
COMMENT ON COLUMN at_water_user.entity_name IS 'The entity name associated with this user';
COMMENT ON COLUMN at_water_user.withdraw_location_code IS 'The location where this user withdraws or pumps out their water';
/

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_pk
 PRIMARY KEY
 (location_code, contract_id)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_fk_2
 FOREIGN KEY (document_id)
 REFERENCES at_document (document_id))
/

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_fk_3
 FOREIGN KEY (withdraw_location_code)
 REFERENCES at_physical_location (location_code))
/

--------
--------

CREATE TABLE at_water_user_accounting
(
  location_code					NUMBER(10)			NOT NULL,
  contract_id					VARCHAR2(64 BYTE)	NOT NULL,
  accounting_effective_date		DATE				NOT NULL,
  accounting_expiration_date	DATE,
  accounting_credit_debit		VARCHAR2(6 BYTE),
  accounting_volume				NUMBER(10),
  accounting_transfer_type		VARCHAR2(20 BYTE),
  accounting_remarks			VARCHAR2(255 BYTE)			
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_water_user_accounting.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_water_user_accounting.contract_id IS 'The contract identification number for this water movement';
COMMENT ON COLUMN at_water_user_accounting.accounting_effective_date IS 'The date this water movement began';
COMMENT ON COLUMN at_water_user_accounting.accounting_expiration_date IS 'the date this water movement stopped';
COMMENT ON COLUMN at_water_user_accounting.accounting_credit_debit IS 'Whether this water movement is a credit or a debit to the contract';
COMMENT ON COLUMN at_water_user_accounting.accounting_volume IS 'The volume associated with the water movement';
COMMENT ON COLUMN at_water_user_accounting.accounting_transfer_type IS 'The type of water transfer for this accounting movement';
COMMENT ON COLUMN at_water_user_accounting.accounting_remarks IS 'Any comments regarding this water accounting movement';
/

ALTER TABLE at_water_user_accounting ADD (
  CONSTRAINT at_water_user_accounting_pk
 PRIMARY KEY
 (location_code, contract_id, accounting_effective_date)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_water_user_accounting ADD (
  CONSTRAINT at_water_user_acct_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

--------
--------

CREATE TABLE at_project_purpose
(
  location_code					NUMBER(10)	NOT NULL,
  purpose_code					NUMBER(10)	NOT NULL,
  additional_notes				VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project_purpose.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project_purpose.purpose_code IS 'The purpose of the project from the at_lu_proj_purpose_code';
COMMENT ON COLUMN at_project_purpose.additional_notes IS 'Any additional notes pertinent to this projects purpose';
/

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_pk
 PRIMARY KEY
 (location_code,purpose_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_fk_2
 FOREIGN KEY (purpose_code)
 REFERENCES at_lu_project_purpose(purpose_code))
/

--------
--------

CREATE TABLE at_project_agreement
(
  location_code					NUMBER(10)			NOT NULL,
  local_agency					VARCHAR2(64 BYTE)	NOT NULL,
  description_id				VARCHAR2(256 BYTE)	NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_project_agreement.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_project_agreement.local_agency IS 'The local agency code related to this project';
COMMENT ON COLUMN at_project_agreement.description_id IS 'The description id that describes this agencies relationship to the project';
/

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_pk
 PRIMARY KEY
 (location_code,local_agency)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_fk_2
 FOREIGN KEY (description_id)
 REFERENCES at_clob (id))
/

--------
--------

CREATE TABLE at_construction_history
(
  location_code						NUMBER(10)			NOT NULL,
  construction_id					VARCHAR2(64 BYTE)	NOT NULL,
  construction_effective_date		DATE				NOT NULL,
  construction_expiration_date		DATE				NOT NULL,
  land_acq_effective_date			DATE,
  land_acq_expiration_date			DATE,
  acres_infee_total					NUMBER(10),
  acres_easement_total				NUMBER(10),
  impoundment_date					DATE,
  filling_date						DATE,
  impoundment_mod_date				DATE,
  pool_raise_date					DATE,
  operational_status				VARCHAR2(255 BYTE),
  acres_acquired					NUMBER(10),
  description_id					VARCHAR2(256 BYTE)	NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/
COMMENT ON COLUMN at_construction_history.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_construction_history.construction_id IS 'The construction identification number';
COMMENT ON COLUMN at_construction_history.construction_effective_date IS 'The effective start date for the construction project';
COMMENT ON COLUMN at_construction_history.construction_expiration_date IS 'The effective end date for the construction project';
COMMENT ON COLUMN at_construction_history.land_acq_effective_date IS 'The date the land acquisition started';
COMMENT ON COLUMN at_construction_history.land_acq_expiration_date IS 'The date the land acquisition ended';
COMMENT ON COLUMN at_construction_history.acres_infee_total IS 'The total in fees for the acreage acquired';
COMMENT ON COLUMN at_construction_history.acres_easement_total IS 'The toal acres under easment for this construction project';
COMMENT ON COLUMN at_construction_history.impoundment_date IS 'The impound date';
COMMENT ON COLUMN at_construction_history.filling_date IS 'The filling date of the reservoir';
COMMENT ON COLUMN at_construction_history.impoundment_mod_date IS 'The modified impoundment date';
COMMENT ON COLUMN at_construction_history.pool_raise_date IS 'The date the pool elevation was raised';
COMMENT ON COLUMN at_construction_history.operational_status IS 'The operational status of the construction project';
COMMENT ON COLUMN at_construction_history.acres_acquired IS 'The total acres acquired for the construction project';
COMMENT ON COLUMN at_construction_history.description_id IS 'The description id that describes the construction project';
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_pk
 PRIMARY KEY
 (location_code,construction_id)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk_1
 FOREIGN KEY (location_code)
 REFERENCES at_project (location_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk_2
 FOREIGN KEY (description_id)
 REFERENCES at_clob (id))
/

