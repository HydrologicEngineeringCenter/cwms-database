drop index at_cwms_ts_id_u01;
drop index at_cwms_ts_id_u02;
drop index at_cwms_ts_id_u03;
drop index at_cwms_ts_id_u04;
alter table at_cwms_ts_id modify cwms_ts_id varchar2(191);
--
-- AT_CWMS_TS_ID_U02  (Index)
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

