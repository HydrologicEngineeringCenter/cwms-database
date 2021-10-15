DECLARE
    TYPE name_tab_t IS TABLE OF VARCHAR2 (21);

    TYPE year_tab_t IS TABLE OF NUMBER;

    l_start_date              VARCHAR2 (10);
    l_end_date                  VARCHAR2 (10);

    l_first_annual_year      NUMBER := 2022;
    l_last_annual_year      NUMBER := 2030;
    l_infinity_end_year      NUMBER := 2200;


   l_names name_tab_t := NEW name_tab_t();
    l_years                      year_tab_t := NEW year_tab_t ();

    l_template_1 VARCHAR2 (2048)
            := '
      CREATE TABLE AT_TSV$name
      (
        TS_CODE          NUMBER(14)                   NOT NULL,
        DATE_TIME        DATE                         NOT NULL,
        VERSION_DATE     DATE                         NOT NULL,
        DATA_ENTRY_DATE  TIMESTAMP(6)                 NOT NULL,
        VALUE            BINARY_DOUBLE,
        QUALITY_CODE     NUMBER(14), 
        DEST_FLAG          NUMBER(1),
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
      
    l_template_2 VARCHAR2 (256)
            := '
    ALTER TABLE AT_TSV$name ADD (
     CONSTRAINT AT_TSV$name_FK1 
    FOREIGN KEY (TS_CODE) 
    REFERENCES AT_CWMS_TS_SPEC (TS_CODE))';
      
    l_template_3 VARCHAR2 (256)
            := '
    ALTER TABLE AT_TSV$name ADD (
     CONSTRAINT AT_TSV$name_FK2 
    FOREIGN KEY (QUALITY_CODE) 
    REFERENCES CWMS_DATA_QUALITY (QUALITY_CODE))';
BEGIN

    FOR i IN l_first_annual_year .. l_last_annual_year
    LOOP
        l_names.EXTEND;
        l_names (l_names.COUNT) := '_' || i;
        l_years.EXTEND;
        l_years (l_names.COUNT) := i;
   END LOOP;
   

    FOR i IN 1 .. l_names.LAST
    LOOP
        DBMS_OUTPUT.PUT_LINE(REPLACE(l_template_1, '$name', l_names (i)));
        EXECUTE IMMEDIATE REPLACE (l_template_1, '$name', l_names (i));

        DBMS_OUTPUT.PUT_LINE(REPLACE(l_template_2, '$name', l_names (i)));
        EXECUTE IMMEDIATE REPLACE (l_template_2, '$name', l_names (i));

        DBMS_OUTPUT.PUT_LINE(REPLACE(l_template_3, '$name', l_names (i)));
        EXECUTE IMMEDIATE REPLACE (l_template_3, '$name', l_names (i));

       -- Annual Tables...
        l_start_date := l_years (i) || '-01-01';

        l_end_date := l_years (i) + 1 || '-01-01';
        delete from at_ts_table_properties where start_date=TO_DATE (l_start_date, 'YYYY-MM-DD');
        INSERT INTO at_ts_table_properties
        VALUES   (
                    TO_DATE (l_start_date, 'YYYY-MM-DD'),
                    TO_DATE (l_end_date, 'YYYY-MM-DD'),
                    'AT_TSV' || l_names (i)
                  );

      COMMIT;
   END LOOP;
   INSERT INTO at_ts_table_properties
        VALUES   (
                    TO_DATE (l_last_annual_year+1|| '-01-01', 'YYYY-MM-DD'),
                    TO_DATE (l_infinity_end_year|| '-01-01', 'YYYY-MM-DD'),
                    'AT_TSV_INF_AND_BEYOND'
                  );

   COMMIT;
END;
/
