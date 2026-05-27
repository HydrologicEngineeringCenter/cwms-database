CREATE TABLE at_project_agreement
(
  project_agreement_loc_code          NUMBER(14)      NOT NULL,
  external_agency_or_stakeholder        VARCHAR2(64 BYTE)         NOT NULL,
  project_agreement_doc_code          NUMBER(14)
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
COMMENT ON COLUMN at_project_agreement.project_agreement_loc_code IS 'The project that this agreement pertains to';
COMMENT ON COLUMN at_project_agreement.external_agency_or_stakeholder IS 'The external government agency or external stakeholder that has a written agreement with the Corps of Engineers related to this project';
COMMENT ON COLUMN at_project_agreement.project_agreement_doc_code IS 'The surrogate code that forms a cross reference to the record in table at_document which contains the project agreement document';

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_pk
 PRIMARY KEY
 (project_agreement_loc_code,external_agency_or_stakeholder)
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
  CONSTRAINT at_project_agreement_fk1
 FOREIGN KEY (project_agreement_loc_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_fk2
 FOREIGN KEY (project_agreement_doc_code)
 REFERENCES at_document (document_code))
/
