CREATE TABLE at_construction_history
(
  construction_history_code     NUMBER(14)      NOT NULL,
  project_location_code                         NUMBER(14)                      NOT NULL,
  construction_location_code            NUMBER(14)      NOT NULL,
  construction_id                   VARCHAR2(64 BYTE)         NOT NULL,
  construction_start_date           DATE        NOT NULL,
  construction_end_date             DATE        NOT NULL,
  land_acq_start_date         DATE,
  land_acq_end_date             DATE,
  area_infee_total        BINARY_DOUBLE,
  area_easement_total       BINARY_DOUBLE,
  impoundment_date        DATE,
  filling_date          DATE,
  impoundment_mod_date        DATE,
  pool_raise_date       DATE,
  operational_status_code     NUMBER(14)                      NOT NULL,
  construction_history_doc_code           NUMBER(14)
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
COMMENT ON COLUMN at_construction_history.construction_history_code IS 'The unique surrogate record number (code) for this construction history record';
COMMENT ON COLUMN at_construction_history.project_location_code IS 'The location code for the project where this construction is located at or associated with';
COMMENT ON COLUMN at_construction_history.construction_location_code IS 'The project this construction history record pertains to';
COMMENT ON COLUMN at_construction_history.construction_id IS 'The construction identification number or short name or title';
COMMENT ON COLUMN at_construction_history.construction_start_date IS 'The start date for the construction project';
COMMENT ON COLUMN at_construction_history.construction_end_date IS 'The completion date for the construction project';
COMMENT ON COLUMN at_construction_history.land_acq_start_date IS 'The date the land acquisition started';
COMMENT ON COLUMN at_construction_history.land_acq_end_date IS 'The date the land acquisition was completed';
COMMENT ON COLUMN at_construction_history.area_infee_total IS 'The total area (usually presented in units of acres) in-fee for the land acquired';
COMMENT ON COLUMN at_construction_history.area_easement_total IS 'The land area (usually presented in units of acres) under easement for this construction project';
COMMENT ON COLUMN at_construction_history.impoundment_date IS 'The date in which impoundment began.  Sometimes called the date of closure.';
COMMENT ON COLUMN at_construction_history.filling_date IS 'The date that the reservoir first reached the normal pool elevation';
COMMENT ON COLUMN at_construction_history.impoundment_mod_date IS 'The date in which impoundment began for the modified normal elevation.';
COMMENT ON COLUMN at_construction_history.pool_raise_date IS 'The date the pool elevation was raised';
COMMENT ON COLUMN at_construction_history.operational_status_code IS 'The operational status of the construction project. Constrained to a value in the lookup table AT_OPERATIONAL_STATUS_CODE';
COMMENT ON COLUMN at_construction_history.construction_history_doc_code IS 'The surrogate code of a record in AT_DOCUMENT that describes this phase of the construction history';

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_pk
 PRIMARY KEY
 (construction_history_code)
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

CREATE UNIQUE INDEX at_construction_hist_idx_1 ON at_construction_history
(project_location_code,construction_location_code,upper(construction_id))
LOGGING
tablespace cwms_20at_data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk2
 FOREIGN KEY (construction_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk3
 FOREIGN KEY (construction_history_doc_code)
 REFERENCES at_document (document_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk4
 FOREIGN KEY (operational_status_code)
 REFERENCES at_operational_status_code (operational_status_code))
/
