--
-- AT_SHEF_IGNORE  (Table) 
--
--  Dependencies: 
--   AT_DATA_STREAM_ID (Table)
--   AT_DATA_FEED_ID (Table)
--
--   Row count:3
CREATE TABLE AT_SHEF_IGNORE
(
  DATA_STREAM_CODE       NUMBER,
  DATA_FEED_CODE         NUMBER,
  SHEF_PE_CODE           VARCHAR2(2 BYTE)       NOT NULL,
  SHEF_TSE_CODE          VARCHAR2(3 BYTE)       NOT NULL,
  SHEF_DURATION_NUMERIC  VARCHAR2(4 BYTE)       NOT NULL,
  SHEF_LOC_ID            VARCHAR2(128 BYTE)     NOT NULL
)
TABLESPACE CWMS_20AT_DATA
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

COMMENT ON COLUMN AT_SHEF_IGNORE.DATA_STREAM_CODE IS 'Unique code indicating the affected Data Stream.'
/

COMMENT ON COLUMN AT_SHEF_IGNORE.DATA_FEED_CODE IS 'Unique code indicating the affected Data Feed, if the DATA FEED Managment style is being used.'
/

COMMENT ON COLUMN AT_SHEF_IGNORE.SHEF_PE_CODE IS 'The PE code portion of the SHEF Spec to be ignored.'
/

COMMENT ON COLUMN AT_SHEF_IGNORE.SHEF_TSE_CODE IS 'The TSE code portion of the SHEF Spec to be ignored.'
/

COMMENT ON COLUMN AT_SHEF_IGNORE.SHEF_DURATION_NUMERIC IS 'The SHEF Duration Numeric code portion of the SHEF Spec to be ignored.'
/

COMMENT ON COLUMN AT_SHEF_IGNORE.SHEF_LOC_ID IS 'The SHEF Location ID portion of the SHEF Spec to be ignored.'
/


--
-- AT_SHEF_IGNORE_U01  (Index) 
--
--  Dependencies: 
--   AT_SHEF_IGNORE (Table)
--
CREATE UNIQUE INDEX AT_SHEF_IGNORE_U01 ON AT_SHEF_IGNORE
(DATA_STREAM_CODE, DATA_FEED_CODE, SHEF_LOC_ID, SHEF_PE_CODE, SHEF_TSE_CODE, 
SHEF_DURATION_NUMERIC)
LOGGING
TABLESPACE CWMS_20AT_DATA
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
-- Non Foreign Key Constraints for Table AT_SHEF_IGNORE 
-- 
ALTER TABLE AT_SHEF_IGNORE ADD (
  CONSTRAINT AT_SHEF_IGNORE_C01
  CHECK (data_stream_code is not null or data_feed_code is not null))
/

-- 
-- Foreign Key Constraints for Table AT_SHEF_IGNORE 
-- 
ALTER TABLE AT_SHEF_IGNORE ADD (
  CONSTRAINT AT_SHEF_IGNORE_R01 
  FOREIGN KEY (DATA_STREAM_CODE) 
  REFERENCES AT_DATA_STREAM_ID (DATA_STREAM_CODE),
  CONSTRAINT AT_SHEF_IGNORE_R02 
  FOREIGN KEY (DATA_FEED_CODE) 
  REFERENCES AT_DATA_FEED_ID (DATA_FEED_CODE))
/