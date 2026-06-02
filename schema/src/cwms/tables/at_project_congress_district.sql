CREATE TABLE at_project_congress_district
(
  project_congress_location_code  NUMBER(14)      NOT NULL,
  project_congress_state_code   NUMBER(14)      NOT NULL,
  congressional_district    NUMBER(14)      NOT NULL,
  congress_district_remarks   VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_project_congress_district.project_congress_location_code IS 'The project this congressional district record is a child to';
COMMENT ON COLUMN at_project_congress_district.project_congress_state_code IS 'The surrogate key (code) for the state this project is located in';
COMMENT ON COLUMN at_project_congress_district.congressional_district IS 'The congressional district of the project';
COMMENT ON COLUMN at_project_congress_district.congress_district_remarks IS 'Any remarks associated with this states congressional district regarding this project';

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_proj_congress_district_pk
 PRIMARY KEY
 (project_congress_location_code,project_congress_state_code,congressional_district)
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
  CONSTRAINT at_proj_cong_district_fk1
 FOREIGN KEY (project_congress_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_proj_cong_district_fk2
 FOREIGN KEY (project_congress_state_code)
 REFERENCES cwms_state (state_code))
/
