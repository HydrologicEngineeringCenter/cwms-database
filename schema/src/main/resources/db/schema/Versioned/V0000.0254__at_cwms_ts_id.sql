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
  CWMS_TS_ID            VARCHAR2(191 BYTE),
  UNIT_ID               VARCHAR2(16 BYTE)       NOT NULL,
  ABSTRACT_PARAM_ID     VARCHAR2(32 BYTE)       NOT NULL,
  BASE_LOCATION_ID      VARCHAR2(24 BYTE)       NOT NULL,
  SUB_LOCATION_ID       VARCHAR2(32 BYTE),
  LOCATION_ID           VARCHAR2(57 BYTE),
  BASE_PARAMETER_ID     VARCHAR2(16 BYTE)       NOT NULL,
  SUB_PARAMETER_ID      VARCHAR2(32 BYTE),
  PARAMETER_ID          VARCHAR2(49 BYTE),
  PARAMETER_TYPE_ID     VARCHAR2(16 BYTE)       NOT NULL,
  INTERVAL_ID           VARCHAR2(16 BYTE)       NOT NULL,
  DURATION_ID           VARCHAR2(16 BYTE)       NOT NULL,
  VERSION_ID            VARCHAR2(32 BYTE)       NOT NULL,
  INTERVAL              NUMBER(14)              NOT NULL,
  INTERVAL_UTC_OFFSET   NUMBER                  NOT NULL,
  VERSION_FLAG          VARCHAR2(1 BYTE),
  HISTORIC_FLAG         VARCHAR2(1 BYTE)        DEFAULT 'F',
  TIME_ZONE_ID          VARCHAR2(28 BYTE)
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

comment on table  at_cwms_ts_id                       is 'Holds useful information about time series identfiers';
comment on column at_cwms_ts_id.db_office_code        is 'Primary key in CWMS_OFFICE for the office that owns the time series';
comment on column at_cwms_ts_id.base_location_code    is 'Primary key in AT_BASE_LOCATION for the base location of the time series';
comment on column at_cwms_ts_id.base_loc_active_flag  is 'A flag (''T''/''F'') that specifies whether the base location is marked as active';
comment on column at_cwms_ts_id.location_code         is 'Primary key in AT_PHYSICAL_LOCATION for the location of the time series';
comment on column at_cwms_ts_id.loc_active_flag       is 'A flag (''T''/''F'') that specifies whether the location is marked as active';
comment on column at_cwms_ts_id.parameter_code        is 'Primary key in AT_PARAMETER for the parameter of the time series';
comment on column at_cwms_ts_id.ts_code               is 'Primary key in AT_CWMS_TS_SPEC for the time series ID';
comment on column at_cwms_ts_id.ts_active_flag        is 'A flag (''T''/''F'') that specifies whether the time series is marked as active';
comment on column at_cwms_ts_id.net_ts_active_flag    is 'A flag (''T''/''F'') that specifies whether the time series is inactivated by any other of the active flags';
comment on column at_cwms_ts_id.db_office_id          is 'The identifier of the office that owns the time series';
comment on column at_cwms_ts_id.cwms_ts_id            is 'The identifier of the time series';
comment on column at_cwms_ts_id.unit_id               is 'The identifier of the database storage unit for the time series';
comment on column at_cwms_ts_id.abstract_param_id     is 'The identifier of the abstract parameter of the time series';
comment on column at_cwms_ts_id.base_location_id      is 'The identifier of the base location of the time series';
comment on column at_cwms_ts_id.sub_location_id       is 'The identifier of the sub-location of the time series';
comment on column at_cwms_ts_id.location_id           is 'The identifier of the complete location of the time series';
comment on column at_cwms_ts_id.base_parameter_id     is 'The identifier of the base parameter of the time series';
comment on column at_cwms_ts_id.sub_parameter_id      is 'The identifier of the sub-parameter of the time series';
comment on column at_cwms_ts_id.parameter_id          is 'The identifier of the complete parameter of the time series';
comment on column at_cwms_ts_id.parameter_type_id     is 'The identifier of the parameter type of the time series';
comment on column at_cwms_ts_id.interval_id           is 'The identifier of the recurrence interval of the time series';
comment on column at_cwms_ts_id.duration_id           is 'The identifier of the duration of the time series';
comment on column at_cwms_ts_id.version_id            is 'The identifier of the version of the time series';
comment on column at_cwms_ts_id.interval              is 'The interval of the time series in minutes';
comment on column at_cwms_ts_id.interval_utc_offset   is 'The offset in minutes into the interval for time series values';
comment on column at_cwms_ts_id.version_flag          is 'A flag (''T''/''F'') that specifies whether the time series is versioned';
comment on column at_cwms_ts_id.historic_flag         is 'A flag (''T''/''F'') that specifies whether the time series is part of the historical record';
comment on column at_cwms_ts_id.time_zone_id          is 'The time zone of the location of the time series';


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
tablespace cwms_20data;

--
-- Non Foreign Key Constraints for Table AT_CWMS_TS_ID
--
ALTER TABLE AT_CWMS_TS_ID ADD (
  CONSTRAINT AT_CWMS_TS_ID_PK
  PRIMARY KEY
  (TS_CODE)
  USING INDEX AT_CWMS_TS_ID_PK)
/
