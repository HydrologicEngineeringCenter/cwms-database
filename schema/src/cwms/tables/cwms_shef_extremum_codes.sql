CREATE TABLE CWMS_SHEF_EXTREMUM_CODES
(
  SHEF_E_CODE    VARCHAR2(1 BYTE),
  DESCRIPTION    VARCHAR2(32 BYTE),
  DURATION_CODE  NUMBER,
  SEQUENCE_NO    NUMBER
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


CREATE UNIQUE INDEX CWMS_EXTREMUM_CODES_PK ON CWMS_SHEF_EXTREMUM_CODES
(SHEF_E_CODE)
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


ALTER TABLE CWMS_SHEF_EXTREMUM_CODES ADD (
  CONSTRAINT CWMS_EXTREMUM_CODES_PK
 PRIMARY KEY
 (SHEF_E_CODE)
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