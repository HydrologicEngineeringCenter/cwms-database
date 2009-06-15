-------------------------
-- AT_CWMS_TSV_**** table
-- 

DECLARE
   TYPE name_tab_t IS TABLE OF VARCHAR2(16);
   l_names name_tab_t := NEW name_tab_t();
   l_template_1 VARCHAR2(1024) := '
      CREATE TABLE AT_TSV$name
      (
        TS_CODE          NUMBER(10)                   NOT NULL,
        DATE_TIME        DATE                         NOT NULL,
        VERSION_DATE     DATE                         NOT NULL,
        DATA_ENTRY_DATE  TIMESTAMP(6)                 NOT NULL,
        VALUE            BINARY_DOUBLE,
        QUALITY_CODE     NUMBER(10), 
        CONSTRAINT AT_TSV$name_PK
       PRIMARY KEY
       (TS_CODE, DATE_TIME, VERSION_DATE)
      )
      ORGANIZATION INDEX
      LOGGING
      TABLESPACE CWMS_20_TSV
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
      COMPRESS 2
      NOPARALLEL
      MONITORING';
      
   l_template_2 VARCHAR2(256) := '
    ALTER TABLE AT_TSV$name ADD (
     CONSTRAINT AT_TSV$name_FK1 
    FOREIGN KEY (TS_CODE) 
    REFERENCES AT_CWMS_TS_SPEC (TS_CODE))';
      
   l_template_3 VARCHAR2(256) := '
    ALTER TABLE AT_TSV$name ADD (
     CONSTRAINT AT_TSV$name_FK2 
    FOREIGN KEY (QUALITY_CODE) 
    REFERENCES CWMS_DATA_QUALITY (QUALITY_CODE))';
   
BEGIN
   l_names.extend(2);
   l_names(1) := '';
   l_names(2) := '_ARCHIVAL';
   FOR i IN  2002..2010 LOOP
      l_names.extend;
      l_names(l_names.count) := '_' || i;
   END LOOP;
   FOR i IN 1..l_names.last LOOP
      execute IMMEDIATE REPLACE(l_template_1, '$name', l_names(i));
      execute IMMEDIATE REPLACE(l_template_2, '$name', l_names(i));
      execute IMMEDIATE REPLACE(l_template_3, '$name', l_names(i));
      COMMIT;
   END LOOP;
END;
/
