CREATE TABLE AT_DATA_DISSEM
(
  OFFICE_CODE         NUMBER,
  FILTER_TO_CORPSNET  VARCHAR2(1 BYTE)          NOT NULL,
  FILTER_TO_DMZ       VARCHAR2(1 BYTE)          NOT NULL
)
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

CREATE UNIQUE INDEX AT_DATA_DISSEM_PK ON AT_DATA_DISSEM
(OFFICE_CODE)
LOGGING
NOPARALLEL;

ALTER TABLE AT_DATA_DISSEM ADD (
  CONSTRAINT AT_DATA_DISSEM_C01
  CHECK ("FILTER_TO_CORPSNET"='T' OR "FILTER_TO_CORPSNET"='F')
  ENABLE VALIDATE,
  CONSTRAINT AT_DATA_DISSEM_C02
  CHECK ("FILTER_TO_DMZ"='T' OR "FILTER_TO_DMZ"='F')
  ENABLE VALIDATE,
  CONSTRAINT AT_DATA_DISSEM_PK
  PRIMARY KEY
  (OFFICE_CODE)
  USING INDEX AT_DATA_DISSEM_PK
  ENABLE VALIDATE);

ALTER TABLE AT_DATA_DISSEM ADD (
  CONSTRAINT AT_DATA_DISSEM_R01 
  FOREIGN KEY (OFFICE_CODE) 
  REFERENCES CWMS_OFFICE (OFFICE_CODE)
  ENABLE VALIDATE);
INSERT INTO AT_TS_CATEGORY (TS_CATEGORY_CODE,
                            TS_CATEGORY_ID,
                            DB_OFFICE_CODE,
                            TS_CATEGORY_DESC)
     VALUES (
               3,
               'Data Dissemination',
               53,
               'These TS Groups are used to manage which TS Ids are streamed to various data dissemination databases.');

COMMIT;

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     VALUES (
               100,
               3,
               'CorpsNet Include List',
               'These TS Id''s will be streamed to the National CorpsNet CWMS DB',
               53,
               NULL,
               NULL);

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     VALUES (
               101,
               3,
               'CorpsNet Exclude List',
               'These TS Id''s will not be streamed to the National CorpsNet DB',
               53,
               NULL,
               NULL);

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     VALUES (102,
             3,
             'DMZ Include List',
             'These TS Id''s will be streamed to the National DMZ CWMS DB',
             53,
             NULL,
             NULL);

INSERT INTO AT_TS_GROUP (TS_GROUP_CODE,
                         TS_CATEGORY_CODE,
                         TS_GROUP_ID,
                         TS_GROUP_DESC,
                         DB_OFFICE_CODE,
                         SHARED_TS_ALIAS_ID,
                         SHARED_TS_REF_CODE)
     VALUES (
               103,
               3,
               'DMZ Exclude List',
               'These TS Id''s will not be streamed to the National DMZ CWMS DB',
               53,
               NULL,
               NULL);

COMMIT;
