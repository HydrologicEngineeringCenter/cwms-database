--
-- AT_SHEF_SPEC_MAPPING_UPDATE  (Table) 
--
--  Dependencies: 
--   AT_DATA_STREAM_ID (Table)
--
CREATE TABLE AT_SHEF_SPEC_MAPPING_UPDATE
(
  DATA_STREAM_CODE    NUMBER,
  IDLE_TIME           DATE,
  NEW_CRIT_FILE_HASH  NUMBER
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


--
-- AT_SHEF_SPEC_MAPPING_UPDATE_PK  (Index) 
--
--  Dependencies: 
--   AT_SHEF_SPEC_MAPPING_UPDATE (Table)
--
CREATE UNIQUE INDEX AT_SHEF_SPEC_MAPPING_UPDATE_PK ON AT_SHEF_SPEC_MAPPING_UPDATE
(DATA_STREAM_CODE)
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
-- Non Foreign Key Constraints for Table AT_SHEF_SPEC_MAPPING_UPDATE 
-- 
ALTER TABLE AT_SHEF_SPEC_MAPPING_UPDATE ADD (
  CONSTRAINT AT_SHEF_SPEC_MAPPING_UPDATE_PK
  PRIMARY KEY
  (DATA_STREAM_CODE)
  USING INDEX AT_SHEF_SPEC_MAPPING_UPDATE_PK)
/

-- 
-- Foreign Key Constraints for Table AT_SHEF_SPEC_MAPPING_UPDATE 
-- 
ALTER TABLE AT_SHEF_SPEC_MAPPING_UPDATE ADD (
  CONSTRAINT AT_SHEF_SPEC_MAPPING_UPDATER01 
  FOREIGN KEY (DATA_STREAM_CODE) 
  REFERENCES AT_DATA_STREAM_ID (DATA_STREAM_CODE))
/
