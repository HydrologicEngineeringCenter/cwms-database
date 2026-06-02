CREATE TABLE at_project
(
  project_location_code       NUMBER(14)          NOT NULL,
  federal_cost          NUMBER,
  nonfederal_cost       NUMBER,
  cost_year         DATE,
  federal_om_cost       BINARY_DOUBLE,
  nonfederal_om_cost        BINARY_DOUBLE,
  authorizing_law       VARCHAR2(512),
  project_owner         VARCHAR2(255),
  hydropower_description      VARCHAR2(255),
  sedimentation_description     VARCHAR2(255 BYTE),
  downstream_urban_description            VARCHAR2(255 BYTE),
  bank_full_capacity_description          VARCHAR2(255 BYTE),
  pump_back_location_code     NUMBER(14),
  near_gage_location_code     NUMBER(14),
  yield_time_frame_start      DATE,
  yield_time_frame_end        DATE,
  project_remarks       VARCHAR2(1000 BYTE)
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
COMMENT ON COLUMN at_project.project_location_code IS 'Unique record identifier for this project. THis code is also in AT_PHYSICAL_LOCATION';
COMMENT ON COLUMN at_project.authorizing_law IS 'A semicolon separated list of laws authorizing this project';
COMMENT ON COLUMN at_project.federal_cost IS 'The federal cost of this project';
COMMENT ON COLUMN at_project.nonfederal_cost IS 'The non-federal cost of this project';
COMMENT ON COLUMN at_project.cost_year IS 'The year the project cost data is from';
COMMENT ON COLUMN at_project.federal_om_cost IS 'The om federal cost of this project';
COMMENT ON COLUMN at_project.nonfederal_om_cost IS 'the non-federal cost of this project';
COMMENT ON COLUMN at_project.project_remarks IS 'The general remarks regarding this project';
COMMENT ON COLUMN at_project.project_owner IS 'The assigned owner of this project';
COMMENT ON COLUMN at_project.hydropower_description IS 'The description of the hydro-power located at this project';
COMMENT ON COLUMN at_project.pump_back_location_code IS 'The location code where the water is pumped back to';
COMMENT ON COLUMN at_project.near_gage_location_code IS 'The location code known as the near gage for the project';
COMMENT ON COLUMN at_project.sedimentation_description IS 'The description of the projects sedimentation';
COMMENT ON COLUMN at_project.downstream_urban_description IS 'The description of the urban area downstream';
COMMENT ON COLUMN at_project.bank_full_capacity_description IS 'The description of the full capacity';
COMMENT ON COLUMN at_project.yield_time_frame_start IS 'The start date of the yield time frame.  The actual yield value is a flow value and therefore it is stored in the table SPECIFIED_LEVEL.';
COMMENT ON COLUMN at_project.yield_time_frame_end IS 'The end date of the yield time frame.  The actual yield value is a flow value and therefore it is stored in the table SPECIFIED_LEVEL.';

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_pk
 PRIMARY KEY
 (project_location_code)
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
  CONSTRAINT at_project_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk2
 FOREIGN KEY (pump_back_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk3
 FOREIGN KEY (near_gage_location_code)
 REFERENCES at_physical_location (location_code))
/
