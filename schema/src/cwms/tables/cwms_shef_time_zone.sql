CREATE TABLE CWMS_SHEF_TIME_ZONE
(
  SHEF_TIME_ZONE_CODE  NUMBER,
  SHEF_TIME_ZONE_ID    VARCHAR2(16 BYTE)        NOT NULL,
  SHEF_TIME_ZONE_DESC  VARCHAR2(64 BYTE)
)
TABLESPACE CWMS_20AT_DATA
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


CREATE UNIQUE INDEX CWMS_SHEF_TIME_ZONE_PK ON CWMS_SHEF_TIME_ZONE
(SHEF_TIME_ZONE_CODE)
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


ALTER TABLE CWMS_SHEF_TIME_ZONE ADD (
  CONSTRAINT CWMS_SHEF_TIME_ZONE_PK
 PRIMARY KEY
 (SHEF_TIME_ZONE_CODE)
    USING INDEX 
    TABLESPACE CWMS_20AT_DATA
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
SET DEFINE OFF;
Insert into CWMS_SHEF_TIME_ZONE
   (SHEF_TIME_ZONE_CODE, SHEF_TIME_ZONE_ID, SHEF_TIME_ZONE_DESC)
 Values
   (2, 'PST', 'Pacific Time');
Insert into CWMS_SHEF_TIME_ZONE
   (SHEF_TIME_ZONE_CODE, SHEF_TIME_ZONE_ID, SHEF_TIME_ZONE_DESC)
 Values
   (3, 'MST', 'Mountain Time');
Insert into CWMS_SHEF_TIME_ZONE
   (SHEF_TIME_ZONE_CODE, SHEF_TIME_ZONE_ID, SHEF_TIME_ZONE_DESC)
 Values
   (4, 'CST', 'Central Time');
Insert into CWMS_SHEF_TIME_ZONE
   (SHEF_TIME_ZONE_CODE, SHEF_TIME_ZONE_ID, SHEF_TIME_ZONE_DESC)
 Values
   (5, 'EST', 'Eastern Time');
Insert into CWMS_SHEF_TIME_ZONE
   (SHEF_TIME_ZONE_CODE, SHEF_TIME_ZONE_ID, SHEF_TIME_ZONE_DESC)
 Values
   (1, 'UTC', 'Coordinated Universal Time');
COMMIT;