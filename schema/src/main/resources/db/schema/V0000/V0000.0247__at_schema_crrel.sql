


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- UPLOADED_XLS_FILE_ROWS_SEQ  (Sequence)
--
CREATE SEQUENCE UPLOADED_XLS_FILE_ROWS_SEQ
  START WITH 100
  MAXVALUE 999999999999999999999999999
  MINVALUE 100
  NOCYCLE
  NOCACHE
  NOORDER
/

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- STRING_AGG_TYPE  (Type)
--

CREATE OR REPLACE type string_agg_type as object
   (
      total varchar2(4000),

       static function
            ODCIAggregateInitialize(sctx IN OUT string_agg_type )
            return number,

       member function
          ODCIAggregateIterate(self IN OUT string_agg_type ,
                               value IN varchar2 )
          return number,

     member function
          ODCIAggregateTerminate(self IN string_agg_type,
                                 returnValue OUT  varchar2,
                                 flags IN number)
           return number,

      member function
           ODCIAggregateMerge(self IN OUT string_agg_type,
                              ctx2 IN string_agg_type)
           return number
   );
/



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- UPLOADED_XLS_FILES_T  (Table)
--
--   Row count:3
CREATE TABLE UPLOADED_XLS_FILES_T
(
  ID                NUMBER                      NOT NULL,
  FILE_NAME         VARCHAR2(1999 BYTE)         NOT NULL,
  MIME_TYPE         VARCHAR2(1999 BYTE)         NOT NULL,
  BLOB_CONTENT      BLOB                        NOT NULL,
  DATE_UPLOADED     DATE                        NOT NULL,
  USER_ID_UPLOADED  VARCHAR2(30 BYTE)           NOT NULL,
  CLOB_CONTENT      CLOB,
  ROW_COUNT_ALL     NUMBER,
  NUM_DOWNLOADED    NUMBER                      DEFAULT 0
)
LOB (BLOB_CONTENT) STORE AS (
  TABLESPACE CWMS_20AT_DATA
  ENABLE       STORAGE IN ROW
  CHUNK       8192
  RETENTION
  NOCACHE
  LOGGING
  INDEX       (
        TABLESPACE CWMS_20AT_DATA
        STORAGE    (
                    INITIAL          64K
                    NEXT             1M
                    MINEXTENTS       1
                    MAXEXTENTS       UNLIMITED
                    PCTINCREASE      0
                    BUFFER_POOL      DEFAULT
                   ))
      STORAGE    (
                  INITIAL          64K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                 ))
LOB (CLOB_CONTENT) STORE AS (
  TABLESPACE CWMS_20AT_DATA
  ENABLE       STORAGE IN ROW
  CHUNK       8192
  RETENTION
  NOCACHE
  LOGGING
  INDEX       (
        TABLESPACE CWMS_20AT_DATA
        STORAGE    (
                    INITIAL          64K
                    NEXT             1M
                    MINEXTENTS       1
                    MAXEXTENTS       UNLIMITED
                    PCTINCREASE      0
                    BUFFER_POOL      DEFAULT
                   ))
      STORAGE    (
                  INITIAL          64K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                 ))
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- UPLOADED_XLS_FILE_ROWS_T  (Table)
--
--  Dependencies:
--   UPLOADED_XLS_FILES_T (Table)
--
--   Row count:7
CREATE TABLE UPLOADED_XLS_FILE_ROWS_T
(
  ID                    NUMBER                  NOT NULL,
  FILE_ID               NUMBER                  NOT NULL,
  DATE_UPLOADED         DATE                    NOT NULL,
  USER_ID_UPLOADED      VARCHAR2(31 BYTE)       NOT NULL,
  DATE_LAST_UPDATED     DATE                    NOT NULL,
  USER_ID_LAST_UPDATED  VARCHAR2(31 BYTE)       NOT NULL,
  ERROR_CODE_ORIGINAL   VARCHAR2(1999 BYTE)     NOT NULL,
  PL_SQL_CALL           VARCHAR2(4000 BYTE),
  SINGLE_ROW_YN         VARCHAR2(1 BYTE)        NOT NULL,
  SEASONAL_COMPONENT    VARCHAR2(4000 BYTE)
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
-- UPLOADED_XLS_FILES_T_PK  (Index)
--
--  Dependencies:
--   UPLOADED_XLS_FILES_T (Table)
--
CREATE UNIQUE INDEX UPLOADED_XLS_FILES_T_PK ON UPLOADED_XLS_FILES_T
(ID)
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
-- UPLOADED_XLS_FILE_ROWS_T_PK  (Index)
--
--  Dependencies:
--   UPLOADED_XLS_FILE_ROWS_T (Table)
--
CREATE UNIQUE INDEX UPLOADED_XLS_FILE_ROWS_T_PK ON UPLOADED_XLS_FILE_ROWS_T
(ID)
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
-- Non Foreign Key Constraints for Table UPLOADED_XLS_FILES_T
--
ALTER TABLE UPLOADED_XLS_FILES_T ADD (
  CONSTRAINT UPLOADED_XLS_FILES_T_PK
  PRIMARY KEY
  (ID)
  USING INDEX UPLOADED_XLS_FILES_T_PK)
/

--
-- Non Foreign Key Constraints for Table UPLOADED_XLS_FILE_ROWS_T
--
ALTER TABLE UPLOADED_XLS_FILE_ROWS_T ADD (
  CONSTRAINT UPLOADED_XLS_FILE_ROWS_T_PK
  PRIMARY KEY
  (ID)
  USING INDEX UPLOADED_XLS_FILE_ROWS_T_PK)
/

--
-- Foreign Key Constraints for Table UPLOADED_XLS_FILE_ROWS_T
--
ALTER TABLE UPLOADED_XLS_FILE_ROWS_T ADD (
  CONSTRAINT UPLOADED_XLS_FILE_ROWS_T__FK1
  FOREIGN KEY (FILE_ID)
  REFERENCES UPLOADED_XLS_FILES_T (ID))
/

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- TEMP_COLLECTION_API_FIRE_TBL  (Table)
--
--   Row count:539
CREATE TABLE TEMP_COLLECTION_API_FIRE_TBL
(
  COLLECTION      VARCHAR2(1999 BYTE),
  USER_ID_FIRED   VARCHAR2(30 BYTE),
  PLSQL_FIRED     VARCHAR2(1999 BYTE),
  SEASONAL_VALUE  VARCHAR2(4000 BYTE)
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
