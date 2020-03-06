SET define on
@@defines.sql
-------------------------
-- AT_CWMS_TSV_**** table
-- 

DECLARE
    TYPE name_tab_t IS TABLE OF VARCHAR2 (21);

    TYPE year_tab_t IS TABLE OF NUMBER;

    l_start_date              VARCHAR2 (10);
    l_end_date                  VARCHAR2 (10);

    l_archive_start_year   NUMBER := 1700;
    l_first_annual_year      NUMBER := 2010;
    l_last_annual_year      NUMBER := 2025;
    l_infinity_end_year      NUMBER := 2200;


   l_names name_tab_t := NEW name_tab_t();
    l_years                      year_tab_t := NEW year_tab_t ();

    l_template_1 VARCHAR2 (2048)
            := '
      CREATE TABLE AT_TSV$name
      (
        TS_CODE          NUMBER(10)                   NOT NULL,
        DATE_TIME        DATE                         NOT NULL,
        VERSION_DATE     DATE                         NOT NULL,
        DATA_ENTRY_DATE  TIMESTAMP(6)                 NOT NULL,
        VALUE            BINARY_DOUBLE,
        QUALITY_CODE     NUMBER(10), 
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
    l_names.EXTEND (3);
   l_names(1) := '';
   l_names(2) := '_ARCHIVAL';
    l_names (3) := '_INF_AND_BEYOND';
    l_years.EXTEND (3);
    l_years (1) := 0;
    l_years (2) := l_archive_start_year;
    l_years (3) := l_infinity_end_year;

    FOR i IN l_first_annual_year .. l_last_annual_year
    LOOP
        l_names.EXTEND;
        l_names (l_names.COUNT) := '_' || i;
        l_years.EXTEND;
        l_years (l_names.COUNT) := i;
   END LOOP;

    FOR i IN 1 .. l_names.LAST
    LOOP
        EXECUTE IMMEDIATE REPLACE (l_template_1, '$name', l_names (i));

        EXECUTE IMMEDIATE REPLACE (l_template_2, '$name', l_names (i));

        EXECUTE IMMEDIATE REPLACE (l_template_3, '$name', l_names (i));

        --
        IF i > 1
        THEN
            IF i = 2
            THEN
                -- Archival Table...
                l_start_date := l_archive_start_year || '-01-01';

                l_end_date := l_first_annual_year || '-01-01';
            ELSIF i = 3
            THEN
                -- Infinity and Beyond Table...
                l_start_date := l_last_annual_year + 1 || '-01-01';

                l_end_date := l_infinity_end_year || '-01-01';
            ELSIF i > 3
            THEN
                -- Annual Tables...
                l_start_date := l_years (i) || '-01-01';

                l_end_date := l_years (i) + 1 || '-01-01';
            END IF;

            INSERT INTO at_ts_table_properties
              VALUES   (
                                TO_DATE (l_start_date, 'YYYY-MM-DD'),
                                TO_DATE (l_end_date, 'YYYY-MM-DD'),
                                'AT_TSV' || l_names (i)
                          );
        END IF;

        --
      COMMIT;
   END LOOP;
END;
/
CREATE TABLE AT_TSV_COUNT
(
  DATA_ENTRY_DATE  TIMESTAMP(6) CONSTRAINT AT_TSVC_DATA_ENTRY_DATE_NN NOT NULL,
  INSERTS          NUMBER(6) CONSTRAINT AT_TSVC_INSERTS_NN NOT NULL,
  UPDATES          NUMBER(6) CONSTRAINT AT_TSVC_UPDATES_NN NOT NULL,
  DELETES          NUMBER(6) CONSTRAINT AT_TSVC_DELETES_NN NOT NULL,
  SELECTS          NUMBER(6), 
  CONSTRAINT AT_TSV_COUNT_PK
  PRIMARY KEY
  (DATA_ENTRY_DATE)
  ENABLE VALIDATE
)
ORGANIZATION INDEX
PCTTHRESHOLD 50
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOLOGGING ;

