
----------------------------------------------------
-- For debuging of apex applications, the aa1 table is used --
-- The cwms_apex aa1 procudure is normally reduced to a null; --
-- It is uncommented to write to the aa1 table only during debugging --
-- sessions. --
----------------------------------------------------

CREATE SEQUENCE "${CWMS_SCHEMA}"."GK"
  START WITH 2675692
  MAXVALUE 999999999999999999999999999
  MINVALUE 0
  NOCYCLE
  NOCACHE
  NOORDER
/

CREATE TABLE AA1
(
  LINE         NUMBER,
  STRINGSTUFF  VARCHAR2(4000 BYTE)
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
MONITORING;


CREATE UNIQUE INDEX AA1_PK ON "${CWMS_SCHEMA}"."AA1"
(LINE)
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
NOPARALLEL;


CREATE OR REPLACE TRIGGER aa1_PK
  BEFORE INSERT
  ON "${CWMS_SCHEMA}"."AA1"   for each row
declare
  NEWPK NUMBER;
begin
  SELECT gk.NEXTVAL INTO NEWPK FROM DUAL;
  :NEW.LINE := NEWPK;
end;
/


ALTER TABLE AA1 ADD (
  CONSTRAINT AA1_PK
 PRIMARY KEY
 (LINE)
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
               ));
