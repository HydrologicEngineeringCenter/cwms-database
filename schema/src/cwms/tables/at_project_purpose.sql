CREATE TABLE at_project_purpose
(
  project_location_code           NUMBER(14)    NOT NULL,
  project_purpose_code      NUMBER(14)    NOT NULL,
  purpose_type        VARCHAR2(20 BYTE) NOT NULL,
  additional_notes      VARCHAR2(255 BYTE)
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

COMMENT ON COLUMN at_project_purpose.project_location_code IS 'The unique project this purpose relates to.  This key found in AT_PROJECT';
COMMENT ON COLUMN at_project_purpose.project_purpose_code IS 'The purpose of the project from the at_proj_purpose_code';
COMMENT ON COLUMN at_project_purpose.purpose_type IS 'The type for this purpose of the project.  Either operating or authorized.';
COMMENT ON COLUMN at_project_purpose.additional_notes IS 'Any additional notes pertinent to this projects purpose';

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_pk
 PRIMARY KEY
 (project_location_code,project_purpose_code)
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
  CONSTRAINT at_project_purpose_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_fk2
 FOREIGN KEY (project_purpose_code)
 REFERENCES at_project_purposes(purpose_code))
/

ALTER TABLE at_project_purpose ADD (
CONSTRAINT at_purpose_auth_or_oper_ck
CHECK ( upper(PURPOSE_TYPE) = 'OPERATING' OR upper(PURPOSE_TYPE) = 'AUTHORIZED'))
/
