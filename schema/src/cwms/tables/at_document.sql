CREATE TABLE at_document
(
  document_code          NUMBER(14)        NOT NULL,
  db_office_code         NUMBER            NOT NULL,
  document_id            VARCHAR2(64 BYTE) NOT NULL,
  document_type_code     NUMBER(14)        NOT NULL,
  document_location_code NUMBER(14),
  document_url           VARCHAR2(100 BYTE),
  document_date          DATE              NOT NULL,
  document_mod_date      DATE,
  document_obsolete_date DATE,
  document_preview_code  NUMBER(14),
  stored_document        NUMBER(14)
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
COMMENT ON COLUMN at_document.document_code IS 'The unique identifier for the individual document, system generated';
COMMENT ON COLUMN at_document.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_document.document_id IS 'The unique identifier for the individual document, user provided';
COMMENT ON COLUMN at_document.document_location_code IS 'The surrogate key from at_physical location that this document applies to.';
COMMENT ON COLUMN at_document.document_type_code IS 'The lu code for the type of the document';
COMMENT ON COLUMN at_document.document_url IS 'The URL where the document could be found';
COMMENT ON COLUMN at_document.document_date IS 'The initial date of the document';
COMMENT ON COLUMN at_document.document_mod_date IS 'The last modified date of the document';
COMMENT ON COLUMN at_document.document_obsolete_date IS 'The date the document became obsolete';
COMMENT ON COLUMN at_document.document_preview_code IS 'The surrogate key from AT_CLOB where the document is described';
COMMENT ON COLUMN at_document.stored_document IS 'The actual storage of the document';

-- unique index
CREATE UNIQUE INDEX at_document_idx1 ON at_document
(db_office_code, UPPER("DOCUMENT_ID"))
LOGGING
tablespace CWMS_20AT_DATA
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

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_pk
 PRIMARY KEY
 (document_code)
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
  CONSTRAINT at_document_fk1
 FOREIGN KEY (document_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk2
 FOREIGN KEY (document_preview_code)
 REFERENCES at_clob (clob_code))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk3
 FOREIGN KEY (document_type_code)
 REFERENCES at_document_type (document_type_code))
/

-- FK
ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk4
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

alter table at_document add constraint at_document_fk5 foreign key(stored_document) references at_blob(blob_code)
/
