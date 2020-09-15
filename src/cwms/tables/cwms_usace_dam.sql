CREATE TABLE CWMS_USACE_DAM
(
  DAM_ID                   INTEGER              NOT NULL,
  NID_ID                   VARCHAR2(21 BYTE)    NOT NULL,
  STATE_ID_CODE            VARCHAR2(60 BYTE),
  DAM_NAME                 VARCHAR2(600 BYTE)   NOT NULL,
  DISTRICT_ID              INTEGER              NOT NULL,
  STATE_ID                 INTEGER              NOT NULL,
  COUNTY_ID                INTEGER              NOT NULL,
  CITY_ID                  INTEGER              NOT NULL,
  CITY_DISTANCE            NUMBER(4,1),
  SECTION                  VARCHAR2(300 BYTE),
  LONGITUDE                NUMBER(19,9),
  LATITUDE                 NUMBER(19,9),
  NON_FED_ON_FED_PROPERTY  INTEGER              NOT NULL,
  RIVER_NAME               VARCHAR2(300 BYTE),
  OWNER_ID                 INTEGER              NOT NULL,
  HAZARD_CLASS_ID          INTEGER              NOT NULL,
  EAP_STATUS_ID            INTEGER              NOT NULL,
  INSPECTION_FREQUENCY     INTEGER              NOT NULL,
  YEAR_COMPLTED            INTEGER,
  CONDITION_ID             INTEGER,
  CONDITION_DETAIL         INTEGER,
  CONDITION_DATE           TIMESTAMP(9),
  LAST_INSPECTION_DATE     TIMESTAMP(9),
  DAM_LENGTH               INTEGER,
  DAM_HEIGHT               INTEGER,
  STRUCTURAL_HEIGHT        INTEGER,
  HYDRAULIC_HEIGHT         INTEGER,
  MAX_DISCHARGE            NUMBER(14,3),
  MAX_STORAGE              NUMBER,
  NORMAL_STORAGE           NUMBER,
  SURFACE_AREA             NUMBER(13,3),
  DRAINAGE_AREA            NUMBER(14,3),
  SPILLWAY_TYPE            INTEGER,
  SPILLWAY_WIDTH           INTEGER,
  DAM_VOLUME               INTEGER,
  NUM_LOCKS                INTEGER,
  LENGTH_LOCK              INTEGER,
  WIDTH_LOCK               INTEGER,
  FED_FUNDED_ID            INTEGER,
  FED_DESIGNED_ID          INTEGER,
  FED_OWNED_ID             INTEGER,
  FED_OPERATED_ID          INTEGER,
  FED_CONSTRUCTED_ID       INTEGER,
  FED_REGULATED_ID         INTEGER,
  FED_INSPECTED_ID         INTEGER,
  FED_OTHER_ID             INTEGER,
  DATE_UPDATED             TIMESTAMP(9)         NOT NULL,
  UPDATED_BY               VARCHAR2(150 BYTE)   NOT NULL,
  DAM_PHOTO                BLOB,
  OTHER_STRUCTURE_ID       VARCHAR2(30 BYTE),
  NUM_SEPERATE_STRUCT      INTEGER,
  EXEC_SUMMARY_PATH        VARCHAR2(3000 BYTE),
  DELETED                  INTEGER              NOT NULL,
  DELETED_DESCRIPTION      VARCHAR2(3000 BYTE),
  PROJECT_DSAC_EXEMPT      INTEGER              NOT NULL,
  BUSINESS_LINE_ID         INTEGER,
  SHAPE                    MDSYS.SDO_GEOMETRY
)
COLUMN SHAPE NOT SUBSTITUTABLE AT ALL LEVELS
LOB (DAM_PHOTO) STORE AS (
  TABLESPACE  CWMS_20DATA
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  RETENTION
  NOCACHE
  LOGGING
      STORAGE    (
                  INITIAL          64K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                  FLASH_CACHE      DEFAULT
                  CELL_FLASH_CACHE DEFAULT
                 ))
VARRAY "SHAPE"."SDO_ELEM_INFO" STORE AS LOB (
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  RETENTION
  CACHE
  LOGGING
      STORAGE    (
                  INITIAL          64K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                  FLASH_CACHE      DEFAULT
                  CELL_FLASH_CACHE DEFAULT
                 ))
VARRAY "SHAPE"."SDO_ORDINATES" STORE AS LOB (
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  RETENTION
  CACHE
  LOGGING
      STORAGE    (
                  INITIAL          64K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                  FLASH_CACHE      DEFAULT
                  CELL_FLASH_CACHE DEFAULT
                 ))
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;
--
CREATE UNIQUE INDEX CWMS_USACE_DAM_PK ON CWMS_USACE_DAM
(DAM_ID)
LOGGING
NOPARALLEL;
--
ALTER TABLE CWMS_USACE_DAM ADD (
  CONSTRAINT CWMS_USACE_DAM_PK
  PRIMARY KEY
  (DAM_ID)
  USING INDEX CWMS_USACE_DAM_PK
  ENABLE VALIDATE);


