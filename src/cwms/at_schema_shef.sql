SET serveroutput on
SET define on
@@defines.sql
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------

DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   table_names       id_array_t
      := id_array_t ('CWMS_SHEF_TIME_ZONE',
                     'CWMS_SHEF_PE_CODES',
                     'AT_DATA_STREAM_ID',
                     'AT_DATA_FEED_ID',
                     'AT_SHEF_DECODE',
                     'AT_SHEF_CRIT_FILE',
                     'AT_SHEF_PE_CODES'
                    );
BEGIN
   FOR i IN table_names.FIRST .. table_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop table '
                           || table_names (i)
                           || ' cascade constraints';

         DBMS_OUTPUT.put_line ('Dropped table ' || table_names (i));
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;

END;
/


---------------------------------------------


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

SET define on
--------------------------------------------------------------------------------
CREATE TABLE CWMS_SHEF_PE_CODES
(
  SHEF_PE_CODE         VARCHAR2(2 BYTE),
  SHEF_TSE_CODE        VARCHAR2(3 BYTE),
  SHEF_DURATION_CODE   VARCHAR2(1 BYTE),
  SHEF_REQ_SEND_CODE   VARCHAR2(7 BYTE),
  UNIT_CODE_EN         NUMBER,
  UNIT_CODE_SI         NUMBER,
  PARAMETER_CODE       NUMBER,
  PARAMETER_TYPE_CODE  NUMBER,
  DESCRIPTION          VARCHAR2(256 BYTE),
  NOTES                VARCHAR2(258 BYTE)
)
tablespace CWMS_20DATA
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


CREATE UNIQUE INDEX CWMS_SHEF_PE_CODES_PK ON CWMS_SHEF_PE_CODES
(SHEF_PE_CODE)
LOGGING
tablespace CWMS_20DATA
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


ALTER TABLE CWMS_SHEF_PE_CODES ADD (
  CONSTRAINT CWMS_SHEF_PE_CODES_PK
 PRIMARY KEY
 (SHEF_PE_CODE)
    USING INDEX 
    tablespace CWMS_20DATA
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




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- AT_DATA_STREAM_ID  (Table) 
--
--  Dependencies: 
--   CWMS_OFFICE (Table)
--
CREATE TABLE AT_DATA_STREAM_ID
(
  DATA_STREAM_CODE       NUMBER,
  DB_OFFICE_CODE         NUMBER                 NOT NULL,
  DATA_STREAM_ID         VARCHAR2(16 BYTE)      NOT NULL,
  DATA_STREAM_DESC       VARCHAR2(128 BYTE),
  ACTIVE_FLAG            VARCHAR2(1 BYTE),
  DELETE_DATE            DATE,
  DATA_STREAM_MGT_STYLE  VARCHAR2(32 BYTE),
  UPDATE_CRIT_FILE       VARCHAR2(1 BYTE)
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


--
-- AT_DATA_STREAM_ID_PK  (Index) 
--
--  Dependencies: 
--   AT_DATA_STREAM_ID (Table)
--
CREATE UNIQUE INDEX AT_DATA_STREAM_ID_PK ON AT_DATA_STREAM_ID
(DATA_STREAM_CODE)
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
-- AT_DATA_STREAM_ID_U01  (Index) 
--
--  Dependencies: 
--   AT_DATA_STREAM_ID (Table)
--
CREATE UNIQUE INDEX AT_DATA_STREAM_ID_U01 ON AT_DATA_STREAM_ID
(DATA_STREAM_ID, DB_OFFICE_CODE)
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
-- Non Foreign Key Constraints for Table AT_DATA_STREAM_ID 
-- 
ALTER TABLE AT_DATA_STREAM_ID ADD (
  CONSTRAINT AT_DATA_STREAM_ID_PK
  PRIMARY KEY
  (DATA_STREAM_CODE)
  USING INDEX AT_DATA_STREAM_ID_PK,
  CONSTRAINT AT_DATA_STREAM_ID_U01
  UNIQUE (DATA_STREAM_ID, DB_OFFICE_CODE)
  USING INDEX AT_DATA_STREAM_ID_U01)
/

-- 
-- Foreign Key Constraints for Table AT_DATA_STREAM_ID 
-- 
ALTER TABLE AT_DATA_STREAM_ID ADD (
  CONSTRAINT AT_DATA_STREAM_ID_R01 
  FOREIGN KEY (DB_OFFICE_CODE) 
  REFERENCES CWMS_OFFICE (OFFICE_CODE))
/


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- AT_SHEF_DECODE  (Table) 
--
--  Dependencies: 
--   CWMS_SHEF_TIME_ZONE (Table)
--   CWMS_UNIT (Table)
--   CWMS_SHEF_DURATION (Table)
--   AT_DATA_STREAM_ID (Table)
--   AT_CWMS_TS_SPEC (Table)
--   AT_DATA_FEED_ID (Table)
--
--   Row count:4501
CREATE TABLE AT_SHEF_DECODE
(
  TS_CODE                NUMBER,
  DATA_STREAM_CODE       NUMBER,
  SHEF_PE_CODE           VARCHAR2(2 BYTE)       NOT NULL,
  SHEF_TSE_CODE          VARCHAR2(3 BYTE)       NOT NULL,
  SHEF_DURATION_NUMERIC  VARCHAR2(4 BYTE)       NOT NULL,
  SHEF_UNIT_CODE         NUMBER                 NOT NULL,
  SHEF_TIME_ZONE_CODE    NUMBER,
  DL_TIME                VARCHAR2(1 BYTE),
  LOCATION_CODE          NUMBER                 NOT NULL,
  LOC_GROUP_CODE         NUMBER                 NOT NULL,
  SHEF_DURATION_CODE     VARCHAR2(1 BYTE)       NOT NULL,
  SHEF_LOC_ID            VARCHAR2(128 BYTE)     NOT NULL,
  DATA_FEED_CODE         NUMBER,
  IGNORE_SHEF_SPEC       VARCHAR2(1 BYTE)       NOT NULL
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


--
-- AT_SHEF_DECODE_PK  (Index) 
--
--  Dependencies: 
--   AT_SHEF_DECODE (Table)
--
CREATE UNIQUE INDEX AT_SHEF_DECODE_PK ON AT_SHEF_DECODE
(TS_CODE)
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
-- AT_SHEF_DECODE_U03  (Index) 
--
--  Dependencies: 
--   AT_SHEF_DECODE (Table)
--
CREATE UNIQUE INDEX AT_SHEF_DECODE_U03 ON AT_SHEF_DECODE
(DATA_STREAM_CODE, SHEF_LOC_ID, SHEF_PE_CODE, SHEF_TSE_CODE, SHEF_DURATION_NUMERIC, 
DATA_FEED_CODE)
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
-- Non Foreign Key Constraints for Table AT_SHEF_DECODE 
-- 
ALTER TABLE AT_SHEF_DECODE ADD (
  CONSTRAINT AT_SHEF_DECODE_C01
  CHECK (data_stream_code is not null or data_feed_code is not null),
  CONSTRAINT AT_SHEF_DECODE_PK
  PRIMARY KEY
  (TS_CODE)
  USING INDEX AT_SHEF_DECODE_PK)
/

-- 
-- Foreign Key Constraints for Table AT_SHEF_DECODE 
-- 
ALTER TABLE AT_SHEF_DECODE ADD (
  CONSTRAINT AT_SHEF_DECODE_R01 
  FOREIGN KEY (TS_CODE) 
  REFERENCES AT_CWMS_TS_SPEC (TS_CODE),
  CONSTRAINT AT_SHEF_DECODE_R02 
  FOREIGN KEY (DATA_STREAM_CODE) 
  REFERENCES AT_DATA_STREAM_ID (DATA_STREAM_CODE)  DISABLE,
  CONSTRAINT AT_SHEF_DECODE_R03 
  FOREIGN KEY (SHEF_UNIT_CODE) 
  REFERENCES CWMS_UNIT (UNIT_CODE),
  CONSTRAINT AT_SHEF_DECODE_R04 
  FOREIGN KEY (SHEF_DURATION_CODE) 
  REFERENCES CWMS_SHEF_DURATION (SHEF_DURATION_CODE),
  CONSTRAINT AT_SHEF_DECODE_R05 
  FOREIGN KEY (SHEF_TIME_ZONE_CODE) 
  REFERENCES CWMS_SHEF_TIME_ZONE (SHEF_TIME_ZONE_CODE),
  CONSTRAINT AT_SHEF_DECODE_R06 
  FOREIGN KEY (DATA_FEED_CODE) 
  REFERENCES AT_DATA_FEED_ID (DATA_FEED_CODE))
/


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
CREATE TABLE AT_SHEF_CRIT_FILE
(
  DATA_STREAM_CODE  NUMBER,
  CREATION_DATE     DATE,
  SHEF_CRIT_FILE    CLOB
)
tablespace CWMS_20DATA
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
LOB (SHEF_CRIT_FILE) STORE AS 
      ( TABLESPACE  CWMS_20DATA 
        ENABLE      STORAGE IN ROW
        CHUNK       8192
        PCTVERSION  0
        NOCACHE
        STORAGE    (
                    INITIAL          64K
                    MINEXTENTS       1
                    MAXEXTENTS       2147483645
                    PCTINCREASE      0
                    BUFFER_POOL      DEFAULT
                   )
      )
NOCACHE
NOPARALLEL
MONITORING
/


CREATE UNIQUE INDEX AT_SHEF_CRIT_FILE_PK ON AT_SHEF_CRIT_FILE
(DATA_STREAM_CODE, CREATION_DATE)
LOGGING
tablespace CWMS_20DATA
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


ALTER TABLE AT_SHEF_CRIT_FILE ADD (
  CONSTRAINT AT_SHEF_CRIT_FILE_PK
 PRIMARY KEY
 (DATA_STREAM_CODE, CREATION_DATE)
    USING INDEX 
    tablespace CWMS_20DATA
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


ALTER TABLE AT_SHEF_CRIT_FILE ADD (
  CONSTRAINT AT_SHEF_CRIT_FILE_R01 
 FOREIGN KEY (DATA_STREAM_CODE) 
 REFERENCES AT_DATA_STREAM_ID (DATA_STREAM_CODE))
/

--------------------------------------------------------------------------------
CREATE TABLE AT_SHEF_PE_CODES
(
  DB_OFFICE_CODE       NUMBER                   NOT NULL,
  SHEF_PE_CODE         VARCHAR2(2 BYTE)         NOT NULL,
  ID_CODE              NUMBER                   NOT NULL,
  SHEF_TSE_CODE        VARCHAR2(3 BYTE),
  SHEF_DURATION_CODE   VARCHAR2(1 BYTE),
  SHEF_REQ_SEND_CODE   VARCHAR2(7 BYTE),
  UNIT_CODE_EN         NUMBER,
  UNIT_CODE_SI         NUMBER,
  PARAMETER_CODE       NUMBER,
  PARAMETER_TYPE_CODE  NUMBER,
  DESCRIPTION          VARCHAR2(256 BYTE),
  NOTES                VARCHAR2(258 BYTE)
)
tablespace CWMS_20DATA
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


CREATE UNIQUE INDEX AT_SHEF_PE_CODES_IDX02 ON AT_SHEF_PE_CODES
(ID_CODE)
LOGGING
tablespace CWMS_20DATA
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


CREATE UNIQUE INDEX AT_SHEF_PE_CODES_IDX03 ON AT_SHEF_PE_CODES
(DB_OFFICE_CODE, SHEF_PE_CODE, SHEF_TSE_CODE, SHEF_DURATION_CODE, SHEF_REQ_SEND_CODE, 
UNIT_CODE_EN, UNIT_CODE_SI, PARAMETER_CODE, PARAMETER_TYPE_CODE)
LOGGING
tablespace CWMS_20DATA
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


CREATE UNIQUE INDEX AT_SHEF_PE_CODES_IDX1 ON AT_SHEF_PE_CODES
(DB_OFFICE_CODE, SHEF_PE_CODE, SHEF_TSE_CODE, SHEF_DURATION_CODE, SHEF_REQ_SEND_CODE, 
UNIT_CODE_EN, UNIT_CODE_SI, PARAMETER_CODE, PARAMETER_TYPE_CODE, UPPER("DESCRIPTION"), 
UPPER("NOTES"))
LOGGING
tablespace CWMS_20DATA
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


CREATE UNIQUE INDEX AT_SHEF_PE_CODES_PK ON AT_SHEF_PE_CODES
(SHEF_PE_CODE, DB_OFFICE_CODE, ID_CODE)
LOGGING
tablespace CWMS_20DATA
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


CREATE OR REPLACE TRIGGER at_shef_pe_codes_trg01
   BEFORE INSERT OR UPDATE OF shef_pe_code
   ON AT_SHEF_PE_CODES    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
BEGIN
   :NEW.shef_pe_code := UPPER (:NEW.shef_pe_code);
END;
/


CREATE OR REPLACE TRIGGER at_shef_pe_codes_trg03
   BEFORE INSERT OR UPDATE OF shef_duration_code
   ON AT_SHEF_PE_CODES    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
BEGIN
   :NEW.shef_duration_code := UPPER (:NEW.shef_duration_code);
END;
/


CREATE OR REPLACE TRIGGER at_shef_pe_codes_trg04
   BEFORE INSERT OR UPDATE OF shef_req_send_code
   ON AT_SHEF_PE_CODES    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
BEGIN
   :NEW.shef_req_send_code := UPPER (:NEW.shef_req_send_code);
END;
/


CREATE OR REPLACE TRIGGER at_shef_pe_codes_trg02
   BEFORE INSERT OR UPDATE OF shef_tse_code
   ON AT_SHEF_PE_CODES    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
BEGIN
   :NEW.shef_tse_code := UPPER (:NEW.shef_tse_code);
END;
/


ALTER TABLE AT_SHEF_PE_CODES ADD (
  CONSTRAINT AT_SHEF_PE_CODES_PK
 PRIMARY KEY
 (DB_OFFICE_CODE, SHEF_PE_CODE, ID_CODE)
    USING INDEX 
    tablespace CWMS_20DATA
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
--------------------------------------------------------------------------------
CREATE TABLE CWMS_SHEF_EXTREMUM_CODES
(
  SHEF_E_CODE    VARCHAR2(1 BYTE),
  DESCRIPTION    VARCHAR2(32 BYTE),
  DURATION_CODE  NUMBER,
  SEQUENCE_NO    NUMBER
)
tablespace CWMS_20DATA
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
tablespace CWMS_20DATA
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
    tablespace CWMS_20DATA
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

