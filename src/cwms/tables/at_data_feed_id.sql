--
-- AT_DATA_FEED_ID  (Table) 
--
--  Dependencies: 
--   CWMS_OFFICE (Table)
--   AT_DATA_STREAM_ID (Table)
--
--   Row count:3
CREATE TABLE AT_DATA_FEED_ID
(
  DATA_FEED_CODE    NUMBER,
  DATA_FEED_ID      VARCHAR2(32 BYTE),
  DB_OFFICE_CODE    NUMBER,
  DATA_FEED_PREFIX  VARCHAR2(3 BYTE),
  DATA_STREAM_CODE  NUMBER,
  DATA_FEED_DESC    VARCHAR2(128 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON COLUMN AT_DATA_FEED_ID.DATA_FEED_CODE IS 'Unique code for each data Feed.'
/

COMMENT ON COLUMN AT_DATA_FEED_ID.DATA_FEED_ID IS 'Office unique name for the data Feed. This name is often used in the Version portion of a TS ID.'
/

COMMENT ON COLUMN AT_DATA_FEED_ID.DB_OFFICE_CODE IS 'Identifies the office that owns this data Feed. One must have the CWMS DA Privilege for this office in order to create or modify data Feeds for this office.'
/

COMMENT ON COLUMN AT_DATA_FEED_ID.DATA_FEED_PREFIX IS 'This is a unique prefix that is prepended to all of the SHEF ID''s associated with this data Feed.'
/

--
-- AT_DATA_FEED_ID_I01  (Index) 
--
--  Dependencies: 
--   AT_DATA_FEED_ID (Table)
--
CREATE UNIQUE INDEX AT_DATA_FEED_ID_I01 ON AT_DATA_FEED_ID
(UPPER("DATA_FEED_ID"), DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


--
-- AT_DATA_FEED_ID_PK  (Index) 
--
--  Dependencies: 
--   AT_DATA_FEED_ID (Table)
--
CREATE UNIQUE INDEX AT_DATA_FEED_ID_PK ON AT_DATA_FEED_ID
(DATA_FEED_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


-- 
-- Non Foreign Key Constraints for Table AT_DATA_FEED_ID 
-- 
ALTER TABLE AT_DATA_FEED_ID ADD (
  CONSTRAINT AT_DATA_FEED_CODE_PK
  PRIMARY KEY
  (DATA_FEED_CODE)
  USING INDEX AT_DATA_FEED_ID_PK)
/

-- 
-- Foreign Key Constraints for Table AT_DATA_FEED_ID 
-- 
ALTER TABLE AT_DATA_FEED_ID ADD (
  CONSTRAINT AT_DATA_FEED_ID_R01 
  FOREIGN KEY (DB_OFFICE_CODE) 
  REFERENCES CWMS_OFFICE (OFFICE_CODE),
  CONSTRAINT AT_DATA_FEED_ID_R02 
  FOREIGN KEY (DATA_STREAM_CODE) 
  REFERENCES AT_DATA_STREAM_ID (DATA_STREAM_CODE))
/