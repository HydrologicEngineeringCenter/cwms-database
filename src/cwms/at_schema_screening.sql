SET define on
@@defines.sql
--------------------------------
-- AT_SCREENING_ID table.
-- 
CREATE TABLE AT_SCREENING_ID
(
  SCREENING_CODE       NUMBER                   NOT NULL,
  DB_OFFICE_CODE       NUMBER                   NOT NULL,
  SCREENING_ID         VARCHAR2(16 BYTE)        NOT NULL,
  SCREENING_ID_DESC    VARCHAR2(128 BYTE),
  BASE_PARAMETER_CODE  NUMBER                   NOT NULL,
  PARAMETER_CODE       NUMBER                   NOT NULL,
  PARAMETER_TYPE_CODE  NUMBER,
  DURATION_CODE        NUMBER
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_SCREENING_ID_UC01 ON AT_SCREENING_ID
(DB_OFFICE_CODE, UPPER("SCREENING_ID"), BASE_PARAMETER_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX AT_SCREENING_ID_PK ON AT_SCREENING_ID
(SCREENING_CODE)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SCREENING_ID ADD (
  CONSTRAINT AT_SCREENING_ID_PK
 PRIMARY KEY
 (SCREENING_CODE)
    USING INDEX 
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
---------------------------------
-- AT_SCREENING_CRITERIA table.
-- 
CREATE TABLE AT_SCREENING_CRITERIA
(
  SCREENING_CODE              NUMBER,
  SEASON_START_DATE           NUMBER,
  RANGE_REJECT_LO             NUMBER,
  RANGE_REJECT_HI             NUMBER,
  RANGE_QUESTION_LO           NUMBER,
  RANGE_QUESTION_HI           NUMBER,
  RATE_CHANGE_REJECT_RISE     NUMBER,
  RATE_CHANGE_REJECT_FALL     NUMBER,
  RATE_CHANGE_QUEST_RISE      NUMBER,
  RATE_CHANGE_QUEST_FALL      NUMBER,
  CONST_REJECT_DURATION_CODE  NUMBER,
  CONST_REJECT_MIN            NUMBER,
  CONST_REJECT_TOLERANCE      NUMBER,
  CONST_REJECT_N_MISS         NUMBER,
  CONST_QUEST_DURATION_CODE   NUMBER,
  CONST_QUEST_MIN             NUMBER,
  CONST_QUEST_TOLERANCE       NUMBER,
  CONST_QUEST_N_MISS          NUMBER,
  ESTIMATE_EXPRESSION         VARCHAR2(32 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_SCREENING_CRITERIA_PK ON "&cwms_schema"."AT_SCREENING_CRITERIA"
(SCREENING_CODE, SEASON_START_DATE)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SCREENING_CRITERIA ADD (
  CONSTRAINT AT_SCREENING_CRITERIA_PK
 PRIMARY KEY
 (SCREENING_CODE, SEASON_START_DATE)
    USING INDEX 
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/

ALTER TABLE AT_SCREENING_CRITERIA ADD (
  CONSTRAINT AT_SCREENING_CRITERIA_R01 
 FOREIGN KEY (SCREENING_CODE) 
 REFERENCES AT_SCREENING_ID (SCREENING_CODE),
  CONSTRAINT AT_SCREENING_CRITERIA_FK03 
 FOREIGN KEY (CONST_QUEST_DURATION_CODE) 
 REFERENCES CWMS_DURATION (DURATION_CODE),
  CONSTRAINT AT_SCREENING_CRITERIA_FK02 
 FOREIGN KEY (CONST_REJECT_DURATION_CODE) 
 REFERENCES CWMS_DURATION (DURATION_CODE))
/
---------------------------------
-- AT_SCREENING_DUR_MAG table.
-- 
CREATE TABLE AT_SCREENING_DUR_MAG
(
  SCREENING_CODE     NUMBER,
  SEASON_START_DATE  NUMBER,
  DURATION_CODE      NUMBER,
  REJECT_LO          NUMBER,
  REJECT_HI          NUMBER,
  QUESTION_LO        NUMBER,
  QUESTION_HI        NUMBER
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_SCREENING_DUR_MAG_PK ON AT_SCREENING_DUR_MAG
(SCREENING_CODE, SEASON_START_DATE, DURATION_CODE)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SCREENING_DUR_MAG ADD (
  CONSTRAINT AT_SCREENING_DUR_MAG_PK
 PRIMARY KEY
 (SCREENING_CODE, SEASON_START_DATE, DURATION_CODE)
    USING INDEX 
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_SCREENING_DUR_MAG ADD (
  CONSTRAINT AT_SCREENING_DUR_MAG_FK02 
 FOREIGN KEY (DURATION_CODE) 
 REFERENCES CWMS_DURATION (DURATION_CODE))
/

ALTER TABLE AT_SCREENING_DUR_MAG ADD (
  CONSTRAINT AT_SCREENING_DUR_MAG_FK01 
 FOREIGN KEY (SCREENING_CODE, SEASON_START_DATE) 
 REFERENCES AT_SCREENING_CRITERIA (SCREENING_CODE,SEASON_START_DATE))
/


---------------------------------
-- AT_SCREENING_CONTROL table.
-- 
CREATE TABLE at_screening_control
(
  screening_code                  NUMBER,
  rate_change_disp_interval_code  NUMBER,
  range_active_flag               VARCHAR2(1 BYTE),
  rate_change_active_flag         VARCHAR2(1 BYTE),
  const_active_flag               VARCHAR2(1 BYTE),
  dur_mag_active_flag             VARCHAR2(1 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
COMMENT ON COLUMN at_screening_control.range_active_flag IS '"T" means the check is active, "F" means the check is inactive, NULL means the check is undefined and consequently not used.'
/
COMMENT ON COLUMN at_screening_control.rate_change_active_flag IS '"T" means the check is active, "F" means the check is inactive, NULL means the check is undefined and consequently not used.'
/
COMMENT ON COLUMN at_screening_control.const_active_flag IS '"T" means the check is active, "F" means the check is inactive, NULL means the check is undefined and consequently not used.'
/
COMMENT ON COLUMN at_screening_control.dur_mag_active_flag IS '"T" means the check is active, "F" means the check is inactive, NULL means the check is undefined and consequently not used.'
/

CREATE UNIQUE INDEX at_screening_control_pk ON "&cwms_schema"."AT_SCREENING_CONTROL"
(screening_code)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

ALTER TABLE at_screening_control ADD (
  CONSTRAINT at_screening_control_pk
 PRIMARY KEY
 (screening_code)
    USING INDEX
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/
ALTER TABLE at_screening_control ADD (
  FOREIGN KEY (screening_code)
 REFERENCES at_screening_id (screening_code))
/

SHOW ERRORS;