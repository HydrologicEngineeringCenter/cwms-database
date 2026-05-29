CREATE TABLE at_xref_wat_usr_contract_docs
(
  water_user_contract_doc_code  NUMBER(14)      NOT NULL,
  document_code                 NUMBER(14)      NOT NULL,
  water_user_contract_code  NUMBER(14)      NOT NULL
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

COMMENT ON COLUMN at_xref_wat_usr_contract_docs.water_user_contract_doc_code IS 'The surrogate unique key for this record.';
COMMENT ON COLUMN at_xref_wat_usr_contract_docs.document_code IS 'The document code for the water supply contract.  More than one document is allowed for each record in the table AT_WATER_USER_CONTRACT. Examples of a need for multiple documents are the original contract, a modification to exercise an option, a contract extension, etc. See AT_DOCUMENT.';
COMMENT ON COLUMN at_xref_wat_usr_contract_docs.water_user_contract_code IS 'The water user contract record for which one or more documents are cross-referenced.  See AT_WATER_USER_CONTRACT.';

ALTER TABLE at_xref_wat_usr_contract_docs ADD (
  CONSTRAINT AT_XREF_WU_CONTRACT_DOCS_pk
 PRIMARY KEY
 (water_user_contract_doc_code)
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

CREATE UNIQUE INDEX at_xref_wat_usr_cont_docs_idx1 ON at_xref_wat_usr_contract_docs
(document_code,water_user_contract_code)
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

ALTER TABLE at_xref_wat_usr_contract_docs ADD (
  CONSTRAINT at_xref_wat_usr_cont_docs_fk1
 FOREIGN KEY (document_code)
 REFERENCES at_document (document_code))
/

ALTER TABLE at_xref_wat_usr_contract_docs ADD (
  CONSTRAINT at_xref_wat_usr_cont_docs_fk2
 FOREIGN KEY (water_user_contract_code)
 REFERENCES at_water_user_contract(water_user_contract_code))
/
