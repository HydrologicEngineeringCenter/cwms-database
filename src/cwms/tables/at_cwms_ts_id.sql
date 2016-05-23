--
-- AT_CWMS_TS_ID  (Table) 
--
CREATE TABLE AT_CWMS_TS_ID
(
  DB_OFFICE_CODE        NUMBER                  NOT NULL,
  BASE_LOCATION_CODE    NUMBER,
  BASE_LOC_ACTIVE_FLAG  VARCHAR2(1 BYTE),
  LOCATION_CODE         NUMBER                  NOT NULL,
  LOC_ACTIVE_FLAG       VARCHAR2(1 BYTE),
  PARAMETER_CODE        NUMBER,
  TS_CODE               NUMBER                  NOT NULL,
  TS_ACTIVE_FLAG        VARCHAR2(1 BYTE),
  NET_TS_ACTIVE_FLAG    CHAR(1 BYTE),
  DB_OFFICE_ID          VARCHAR2(16 BYTE)       NOT NULL,
  CWMS_TS_ID            VARCHAR2(183 BYTE),
  UNIT_ID               VARCHAR2(16 BYTE)       NOT NULL,
  ABSTRACT_PARAM_ID     VARCHAR2(32 BYTE)       NOT NULL,
  BASE_LOCATION_ID      VARCHAR2(16 BYTE)       NOT NULL,
  SUB_LOCATION_ID       VARCHAR2(32 BYTE),
  LOCATION_ID           VARCHAR2(49 BYTE),
  BASE_PARAMETER_ID     VARCHAR2(16 BYTE)       NOT NULL,
  SUB_PARAMETER_ID      VARCHAR2(32 BYTE),
  PARAMETER_ID          VARCHAR2(49 BYTE),
  PARAMETER_TYPE_ID     VARCHAR2(16 BYTE)       NOT NULL,
  INTERVAL_ID           VARCHAR2(16 BYTE)       NOT NULL,
  DURATION_ID           VARCHAR2(16 BYTE)       NOT NULL,
  VERSION_ID            VARCHAR2(32 BYTE)       NOT NULL,
  INTERVAL              NUMBER(10)              NOT NULL,
  INTERVAL_UTC_OFFSET   NUMBER                  NOT NULL,
  VERSION_FLAG          VARCHAR2(1 BYTE)
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
-- AT_CWMS_TS_ID_PK  (Index) 
--
--  Dependencies: 
--   AT_CWMS_TS_ID (Table)
--
CREATE UNIQUE INDEX AT_CWMS_TS_ID_PK ON AT_CWMS_TS_ID
(TS_CODE)
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

CREATE OR REPLACE SYNONYM MV_CWMS_TS_ID
FOR AT_CWMS_TS_ID
/
--
-- AT_CWMS_TS_ID_U01  (Index) 
--
--  Dependencies: 
--   AT_CWMS_TS_ID (Table)
--
CREATE UNIQUE INDEX AT_CWMS_TS_ID_U01 ON AT_CWMS_TS_ID
(DB_OFFICE_ID, CWMS_TS_ID)
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
-- AT_CWMS_TS_ID_U02  (Index) 
--
--  Dependencies: 
--   AT_CWMS_TS_ID (Table)
--
CREATE UNIQUE INDEX AT_CWMS_TS_ID_U02 ON AT_CWMS_TS_ID
(UPPER("DB_OFFICE_ID"), UPPER("CWMS_TS_ID"))
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
-- AT_CWMS_TS_ID_U03  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE INDEX AT_CWMS_TS_ID_U03 ON AT_CWMS_TS_ID
(CWMS_TS_ID)
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
-- AT_CWMS_TS_ID_U04  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
CREATE INDEX AT_CWMS_TS_ID_U04 ON AT_CWMS_TS_ID
(UPPER("CWMS_TS_ID"))
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
-- AT_CWMS_TS_ID_ACTIVE  (Index)
--
--  Dependencies:
--   AT_CWMS_TS_ID (Table)
--
create index at_cwms_ts_id_active on at_cwms_ts_id(location_code, ts_active_flag)
tablespace cwms_20at_data;    

-- 
-- Non Foreign Key Constraints for Table AT_CWMS_TS_ID 
-- 
ALTER TABLE AT_CWMS_TS_ID ADD (
  CONSTRAINT AT_CWMS_TS_ID_PK
  PRIMARY KEY
  (TS_CODE)
  USING INDEX AT_CWMS_TS_ID_PK)
/
--
-- AT_BASE_LOCATION_T01  (Trigger) 
--
--  Dependencies: 
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_BASE_LOCATION (Table)
--
CREATE OR REPLACE TRIGGER at_base_location_t01
    AFTER UPDATE OF active_flag, base_location_id
    ON at_base_location
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_abl (:new.db_office_code,
                                    :new.base_location_code,
                                    :new.active_flag,
                                    :new.base_location_id
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_base_location_t01;
/


--
-- AT_CWMS_TS_SPEC_T01  (Trigger) 
--
--  Dependencies: 
--   STANDARD (Package)
--   DBMS_STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_CWMS_TS_SPEC (Table)
--
CREATE OR REPLACE TRIGGER at_cwms_ts_spec_t01
    AFTER INSERT OR UPDATE OR DELETE
    ON AT_CWMS_TS_SPEC     REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
    l_cwms_ts_spec   at_cwms_ts_spec%ROWTYPE;
BEGIN
    IF INSERTING OR UPDATING
    THEN
        l_cwms_ts_spec.ts_code := :new.ts_code;
        l_cwms_ts_spec.location_code := :new.location_code;
        l_cwms_ts_spec.parameter_code := :new.parameter_code;
        l_cwms_ts_spec.parameter_type_code := :new.parameter_type_code;
        l_cwms_ts_spec.interval_code := :new.interval_code;
        l_cwms_ts_spec.duration_code := :new.duration_code;
        l_cwms_ts_spec.version := :new.version;
        l_cwms_ts_spec.description := :new.description;
        l_cwms_ts_spec.interval_utc_offset := :new.interval_utc_offset;
        l_cwms_ts_spec.interval_forward := :new.interval_forward;
        l_cwms_ts_spec.interval_backward := :new.interval_backward;
        l_cwms_ts_spec.interval_offset_id := :new.interval_offset_id;
        l_cwms_ts_spec.time_zone_code := :new.time_zone_code;
        l_cwms_ts_spec.version_flag := :new.version_flag;
        l_cwms_ts_spec.migrate_ver_flag := :new.migrate_ver_flag;
        l_cwms_ts_spec.active_flag := :new.active_flag;
        l_cwms_ts_spec.delete_date := :new.delete_date;
        l_cwms_ts_spec.data_source := :new.data_source;
        --
        cwms_ts_id.touched_acts (l_cwms_ts_spec);
    END IF;

    IF DELETING
    THEN
        cwms_ts_id.delete_from_at_cwms_ts_id (:old.ts_code);
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_cwms_ts_spec_t01;
/


--
-- AT_PARAMETER_T01  (Trigger) 
--
--  Dependencies: 
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_PARAMETER (Table)
--
CREATE OR REPLACE TRIGGER at_parameter_t01
    AFTER UPDATE OF sub_parameter_id
    ON at_parameter
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_api (:new.parameter_code,
                                    :new.base_parameter_code,
                                    :new.sub_parameter_id
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_parameter_t01;
/


--
-- AT_PHYSICAL_LOCATION_T01  (Trigger) 
--
--  Dependencies: 
--   STANDARD (Package)
--   CWMS_TS_ID (Package)
--   AT_PHYSICAL_LOCATION (Table)
--
CREATE OR REPLACE TRIGGER at_physical_location_t01
    AFTER UPDATE OF active_flag, sub_location_id, base_location_code
    ON at_physical_location
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
DECLARE
BEGIN
    cwms_ts_id.touched_apl (:new.location_code,
                                    :new.active_flag,
                                    :new.sub_location_id,
                                    :new.base_location_code
                                  );
EXCEPTION
    WHEN OTHERS
    THEN
        -- Consider logging the error and then re-raise
        RAISE;
END at_physical_location_t01;
/
