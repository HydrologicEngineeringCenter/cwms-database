ALTER SESSION SET current_schema = &CWMS_SCHEMA;
CREATE MATERIALIZED VIEW &CWMS_SCHEMA..MV_TS_CODE_FILTER 
    (TS_CODE,DEST)
TABLESPACE CWMS_20AT_DATA 
PCTUSED    0
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
NOCACHE
NOLOGGING
NOCOMPRESS
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
WITH PRIMARY KEY
 USING TRUSTED CONSTRAINTS
AS 
/* Formatted on 8/3/2017 8:46:45 AM (QP5 v5.300) */
SELECT UNIQUE ts_code, 2 as DEST
  FROM (SELECT TS_CODE
          FROM &cwms_schema..AV_CWMS_TS_ID2
         WHERE LOC_ALIAS_CATEGORY LIKE 'CWMS Mobile Lo%'
        UNION
        SELECT ts_code FROM &cwms_schema..AV_A2W_TS_CODES_BY_LOC2);



CREATE UNIQUE INDEX &CWMS_SCHEMA..MV_TS_CODE_IDX ON &CWMS_SCHEMA..MV_TS_CODE_FILTER
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
           );

CREATE OR REPLACE PROCEDURE &CWMS_SCHEMA..START_MV_TS_REFRESH_JOB
AS
BEGIN
   BEGIN
      DBMS_SCHEDULER.STOP_JOB ('MV_TS_REFRESH_JOB');
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   BEGIN
      DBMS_SCHEDULER.DROP_JOB ('MV_TS_REFRESH_JOB');
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   DBMS_SCHEDULER.CREATE_JOB (
      job_name          => 'MV_TS_REFRESH_JOB',
      job_type          => 'PLSQL_BLOCK',
      job_action        => 'BEGIN DBMS_MVIEW.REFRESH(''MV_TS_CODE_FILTER''); END;',
      start_date        => NULL,
      repeat_interval   => 'freq=secondly; interval=3600',
      job_class         => 'default_job_class',
      enabled           => TRUE,
      auto_drop         => FALSE,
      comments          => 'REFRESH TS CODE FILTER TABLE');
END START_MV_TS_REFRESH_JOB;
/

EXEC &CWMS_SCHEMA..START_MV_TS_REFRESH_JOB;

