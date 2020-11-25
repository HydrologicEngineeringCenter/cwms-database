CREATE TABLE AT_TSV_2021
(
  TS_CODE          NUMBER(14)                   NOT NULL,
  DATE_TIME        DATE                         NOT NULL,
  VERSION_DATE     DATE                         NOT NULL,
  DATA_ENTRY_DATE  TIMESTAMP(6)                 NOT NULL,
  VALUE            BINARY_DOUBLE,
  QUALITY_CODE     NUMBER(14),
  DEST_FLAG        NUMBER(1), 
  CONSTRAINT AT_TSV_2021_PK
  PRIMARY KEY
  (TS_CODE, DATE_TIME, VERSION_DATE)
  ENABLE VALIDATE
)
ORGANIZATION INDEX
PCTTHRESHOLD 50
TABLESPACE CWMS_20_TSV
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
COMPRESS 2
NOPARALLEL
MONITORING;
CREATE OR REPLACE TRIGGER AT_TSV_2021_AIUDR
        AFTER INSERT OR UPDATE OR DELETE ON AT_TSV_2021 FOR EACH ROW
DECLARE
                l_dml number;
        BEGIN
        -- count inserts, updates and deletes using the cwms_tsv package

                l_dml := 0;

                if INSERTING then
                        l_dml := 1;
                elsif UPDATING then
                        l_dml := 2;
                elsif DELETING then
                        l_dml := 3;
                end if;

        cwms_tsv.count(l_dml, sys_extract_utc(systimestamp));

        EXCEPTION
        -- silently fail
        WHEN OTHERS THEN NULL;
    END;
/

CREATE OR REPLACE TRIGGER AT_TSV_2021_DDF
        BEFORE INSERT OR UPDATE ON AT_TSV_2021 FOR EACH ROW
BEGIN
                if INSERTING OR UPDATING then
                        :new.dest_flag := CWMS_DATA_DISSEM.GET_DEST(:new.ts_code);
                end if;

        EXCEPTION
        -- silently fail
        WHEN OTHERS THEN NULL;
    END;
/


CREATE OR REPLACE TRIGGER ST_TSV_2021 BEFORE DELETE OR INSERT OR UPDATE
              ON AT_TSV_2021 REFERENCING NEW AS NEW OLD AS OLD
DECLARE

             l_priv   VARCHAR2 (16);
             BEGIN
             SELECT SYS_CONTEXT ('CWMS_ENV', 'CWMS_PRIVILEGE') INTO l_priv FROM DUAL;
             IF ((l_priv is NULL OR l_priv <> 'CAN_WRITE') AND user NOT IN ('SYS', 'CWMS_20'))
             THEN

               CWMS_20.CWMS_ERR.RAISE('NO_WRITE_PRIVILEGE');

             END IF;
           END;
/
ALTER TABLE AT_TSV_2021 ADD (
  CONSTRAINT AT_TSV_2021_FK1 
  FOREIGN KEY (TS_CODE) 
  REFERENCES AT_CWMS_TS_SPEC (TS_CODE)
  ENABLE VALIDATE
,  CONSTRAINT AT_TSV_2021_FK2 
  FOREIGN KEY (QUALITY_CODE) 
  REFERENCES CWMS_DATA_QUALITY (QUALITY_CODE)
  ENABLE VALIDATE);
