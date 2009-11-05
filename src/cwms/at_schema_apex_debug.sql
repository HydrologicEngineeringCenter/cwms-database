SET serveroutput on
SET define on
@@defines.sql
----------------------------------------------------
-- For debuging of apex applications, the aa1 table is used --
-- The cwms_apex aa1 procudure is normally reduced to a null; --
-- It is uncommented to write to the aa1 table only during debugging --
-- sessions. --
----------------------------------------------------

DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   table_names       id_array_t
      := id_array_t ('aa1'
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
   
   begin
   
   execute immediate 'DROP SEQUENCE GK';
   
   exception when others then null;
   end;

END;
/

CREATE SEQUENCE "&cwms_schema"."GK"
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
MONITORING;


CREATE UNIQUE INDEX AA1_PK ON "&cwms_schema"."AA1"
(LINE)
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
NOPARALLEL;


CREATE OR REPLACE TRIGGER aa1_PK
  BEFORE INSERT
  ON "&cwms_schema"."AA1"   for each row
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
    tablespace CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ));

