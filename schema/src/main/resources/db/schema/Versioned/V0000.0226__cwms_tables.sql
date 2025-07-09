
CREATE SEQUENCE CWMS_SEQ
	START WITH 44
	INCREMENT BY 1000
	MINVALUE 44
	MAXVALUE 1.0e38
	NOCYCLE
	CACHE 20
	ORDER;


    -- ## TABLE ###############################################
    -- ## CWMS_STATE
    -- ##
    CREATE TABLE CWMS_STATE
       (
           STATE_CODE    NUMBER(14)  NOT NULL,
           STATE_INITIAL VARCHAR2(2) NOT NULL,
           NAME          VARCHAR2(40),
           NATION_CODE   VARCHAR2(2)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20K
              NEXT 20K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    ----------------------------
    -- CWMS_STATE constraints --
    --
    ALTER TABLE CWMS_STATE ADD CONSTRAINT CWMS_STATE_PK PRIMARY KEY (STATE_CODE);

    -------------------------
    -- CWMS STATE comments --
    --
    COMMENT ON TABLE CWMS_STATE IS 'STATE_CODE uses FIPS state number.';




    -- ## TABLE ###############################################
    -- ## CWMS_COUNTY
    -- ##
    CREATE TABLE CWMS_COUNTY
       (
           COUNTY_CODE NUMBER(14)   NOT NULL,
           COUNTY_ID   VARCHAR2(3)  NOT NULL,
           STATE_CODE  NUMBER(14)   NOT NULL,
           COUNTY_NAME VARCHAR2(60)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 100K
              NEXT 50K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_COUNTY constraints --
    --
    ALTER TABLE CWMS_COUNTY ADD CONSTRAINT CWMS_COUNTY_PK PRIMARY KEY(COUNTY_CODE);
    ALTER TABLE CWMS_COUNTY ADD CONSTRAINT CWMS_COUNTY_FK FOREIGN KEY(STATE_CODE) REFERENCES CWMS_STATE (STATE_CODE);
    --------------------------
    -- CWMS_COUNTY comments --
    --
    COMMENT ON TABLE CWMS_COUNTY IS 'County code uses state and county FIPS number   01 - State FIPS number   053 - FIPS number thus, county code is 01053.';




    -- ## TABLE ###############################################
    -- ## CWMS_OFFICE
    -- ##
    CREATE TABLE CWMS_OFFICE
       (
           OFFICE_CODE           NUMBER(14)   NOT NULL,
           OFFICE_ID             VARCHAR2(16) NOT NULL,
           PUBLIC_NAME           VARCHAR2(32) NULL,
           LONG_NAME             VARCHAR2(80) NULL,
           REPORT_TO_OFFICE_CODE NUMBER(14)   NOT NULL,
           DB_HOST_OFFICE_CODE   NUMBER(14)   NOT NULL,
           EROC                  VARCHAR2(2)  NOT NULL,
           OFFICE_TYPE           VARCHAR2(8)  NOT NULL
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200K
              NEXT 200K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );


    -----------------------------
    -- CWMS_OFFICE constraints --
    --
    ALTER TABLE CWMS_OFFICE ADD CONSTRAINT CWMS_OFFICE_PK  PRIMARY KEY (OFFICE_CODE);
    ALTER TABLE CWMS_OFFICE ADD CONSTRAINT CWMS_OFFICE_UK  UNIQUE      (OFFICE_ID);
    ALTER TABLE CWMS_OFFICE ADD CONSTRAINT CWMS_OFFICE_CK1 CHECK       (OFFICE_TYPE IN ('UNK','HQ','MSC','MSCR','DIS','FOA'));


    -----------------------------
    -- CWMS_OFFICE comments --
    --
    COMMENT ON TABLE CWMS_OFFICE IS 'Corps of Engineer''s district and division offices.';
    COMMENT ON COLUMN CWMS_OFFICE."OFFICE_CODE" IS 'Unique office identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
    COMMENT ON COLUMN CWMS_OFFICE.OFFICE_ID IS 'USACE code or symbol for a district or division office.  Record identifier that is meaningful to the user, e.g. NWS, MVS.  This is user defined.  If not defined during data entry, it defaults to OFFICE_CODE.';
    COMMENT ON COLUMN CWMS_OFFICE.LONG_NAME IS 'Long name used to refer to an office.';
    COMMENT ON COLUMN CWMS_OFFICE.REPORT_TO_OFFICE_CODE IS 'Organizationally, the office to report to.';
    COMMENT ON COLUMN CWMS_OFFICE.DB_HOST_OFFICE_CODE IS 'The office hosting the database for this office.';
    COMMENT ON COLUMN CWMS_OFFICE.EROC IS 'Corps of Engineers Reporting Organization Codes as per ER-37-1-27.';
    COMMENT ON COLUMN CWMS_OFFICE.OFFICE_TYPE IS 'UNK=unknown, HQ=corps headquarters, MSC=division headquarters, MSCR=division regional, DIS=district, FOA=field operating activity';



    -- ## TABLE ###############################################
    -- ## CWMS_INTERVAL_OFFSET
    -- ##
    CREATE TABLE CWMS_INTERVAL_OFFSET
       (
           INTERVAL_OFFSET_CODE    NUMBER(14)   NOT NULL,
           INTERVAL_OFFSET_ID      VARCHAR2(16) NOT NULL,
           INTERVAL_OFFSET_VALUE   NUMBER(14)   NOT NULL,
           DESCRIPTION             VARCHAR2(80)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20K
              NEXT 20K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_INTERVAL_OFFSET indicies
    --
    CREATE UNIQUE INDEX CWMS_INTERVAL_OFFSET_UI ON CWMS_INTERVAL_OFFSET
       (
           UPPER(INTERVAL_OFFSET_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20k
              NEXT 20k
              MINEXTENTS 1
              MAXEXTENTS 20
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );




    -- ## TABLE ###############################################
    -- ## CWMS_ERROR
    -- ##
    CREATE TABLE CWMS_ERROR
    (
      ERR_CODE  NUMBER(6)                           NOT NULL,
      ERR_NAME  VARCHAR2(32 BYTE)                   NOT NULL,
      ERR_MSG   VARCHAR2(240 BYTE)
    )
    TABLESPACE CWMS_20DATA
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
    MONITORING;


    CREATE UNIQUE INDEX CWMS_ERROR_PK ON CWMS_ERROR
    (ERR_CODE)
    LOGGING
    TABLESPACE CWMS_20DATA
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
    NOPARALLEL;


    CREATE UNIQUE INDEX CWMS_ERROR_AK1 ON CWMS_ERROR
    (ERR_NAME)
    LOGGING
    TABLESPACE CWMS_20DATA
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
    NOPARALLEL;


    CREATE OR REPLACE TRIGGER CWMS_ERROR_BIUR
    before insert or update
    on CWMS_ERROR
    for each row
    begin
       :new.err_name := upper(:new.err_name);
    end;
    /




    ALTER TABLE CWMS_ERROR ADD (
      CONSTRAINT ERR_CODE_VAL_CHECK
     CHECK (err_code <-20000 and err_code>=-20999));

    ALTER TABLE CWMS_ERROR ADD (
      CONSTRAINT CWMS_ERROR_PK
     PRIMARY KEY
     (ERR_CODE)
        USING INDEX
        TABLESPACE CWMS_20DATA
        PCTFREE    10
        INITRANS   2
        MAXTRANS   255
        STORAGE    (
                    INITIAL          64K
                    MINEXTENTS       1
                    MAXEXTENTS       2147483645
                    PCTINCREASE      0
                   ));



    -- ## TABLE ###############################################
    -- ## CWMS_TIME_ZONE
    -- ##
    CREATE TABLE CWMS_TIME_ZONE
       (
           TIME_ZONE_CODE NUMBER(14)             NOT NULL,
           TIME_ZONE_NAME VARCHAR2(28)           NOT NULL,
           UTC_OFFSET    INTERVAL DAY TO SECOND NOT NULL,
           DST_OFFSET    INTERVAL DAY TO SECOND NOT NULL
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200K
              NEXT 200K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_TIME_ZONE constraints
    --
    ALTER TABLE CWMS_TIME_ZONE ADD CONSTRAINT CWMS_TIME_ZONE_PK  PRIMARY KEY  (TIME_ZONE_CODE);
    ALTER TABLE CWMS_TIME_ZONE ADD CONSTRAINT CWMS_TIME_ZONE_UK  UNIQUE       (TIME_ZONE_NAME);
    ALTER TABLE CWMS_TIME_ZONE ADD CONSTRAINT CWMS_TIME_ZONE_CK1 CHECK       (UTC_OFFSET >= INTERVAL '-18:00' HOUR TO MINUTE);
    ALTER TABLE CWMS_TIME_ZONE ADD CONSTRAINT CWMS_TIME_ZONE_CK2 CHECK       (UTC_OFFSET <= INTERVAL ' 18:00' HOUR TO MINUTE);
    ALTER TABLE CWMS_TIME_ZONE ADD CONSTRAINT CWMS_TIME_ZONE_CK3 CHECK       (DST_OFFSET >= INTERVAL  ' 0:00' HOUR TO MINUTE);
    ALTER TABLE CWMS_TIME_ZONE ADD CONSTRAINT CWMS_TIME_ZONE_CK4 CHECK       (DST_OFFSET <= INTERVAL   '1:00' HOUR TO MINUTE);

    -----------------------------
    -- CWMS_TIME_ZONE comments
    --
    COMMENT ON TABLE CWMS_TIME_ZONE IS 'Contains timezone information.';
    COMMENT ON COLUMN CWMS_TIME_ZONE.TIME_ZONE_CODE IS 'Primary key used to relate parameters other entities';
    COMMENT ON COLUMN CWMS_TIME_ZONE.TIME_ZONE_NAME IS 'Region name or abbreviation of timezone';
    COMMENT ON COLUMN CWMS_TIME_ZONE.UTC_OFFSET    IS 'Amount of time the timezone is ahead of UTC';
    COMMENT ON COLUMN CWMS_TIME_ZONE.DST_OFFSET    IS 'Amount of time the UTC_OFFSET increases during DST';




    -- ## TABLE ###############################################
    -- ## CWMS_TIME_ZONE_ALIAS
    -- ##
    CREATE TABLE CWMS_TIME_ZONE_ALIAS
       (
           TIME_ZONE_ALIAS VARCHAR2(9)  NOT NULL,
           TIME_ZONE_NAME  VARCHAR2(28) NOT NULL
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20K
              NEXT 20K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_TIME_ZONE_ALIAS constraints
    --
    ALTER TABLE CWMS_TIME_ZONE_ALIAS ADD CONSTRAINT CWMS_TIME_ZONE_ALIAS_PK  PRIMARY KEY (TIME_ZONE_ALIAS);
    ALTER TABLE CWMS_TIME_ZONE_ALIAS ADD CONSTRAINT CWMS_TIME_ZONE_ALIAS_FK1 FOREIGN KEY (TIME_ZONE_NAME) REFERENCES CWMS_TIME_ZONE (TIME_ZONE_NAME);

    -----------------------------
    -- CWMS_TIME_ZONE_ALIAS comments
    --
    COMMENT ON TABLE CWMS_TIME_ZONE_ALIAS IS 'Contains timezone aliases for Java custom time zones.';
    COMMENT ON COLUMN CWMS_TIME_ZONE_ALIAS.TIME_ZONE_ALIAS IS 'Time zone alias.';
    COMMENT ON COLUMN CWMS_TIME_ZONE_ALIAS.TIME_ZONE_NAME IS 'References propert time zone name.';




    -- ## TABLE ###############################################
    -- ## CWMS_TZ_USAGE
    -- ##
    CREATE TABLE CWMS_TZ_USAGE
       (
           TZ_USAGE_CODE NUMBER(14)   NOT NULL,
           TZ_USAGE_ID   VARCHAR2(8)  NOT NULL,
           DESCRIPTION   VARCHAR2(80)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200K
              NEXT 200K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_TZ_USAGE indicies
    --
    CREATE UNIQUE INDEX CWMS_TZ_USAGE_UI ON CWMS_TZ_USAGE
       (
           UPPER(TZ_USAGE_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200k
              NEXT 200k
              MINEXTENTS 1
              MAXEXTENTS 20
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_TZ_USAGE constraints
    --
    ALTER TABLE CWMS_TZ_USAGE ADD CONSTRAINT CWMS_TZ_USAGE_PK  PRIMARY KEY (TZ_USAGE_CODE);

    -----------------------------
    -- CWMS_TZ_USAGE comments
    --
    COMMENT ON TABLE CWMS_TZ_USAGE IS 'Contains timezone usage information.';
    COMMENT ON COLUMN CWMS_TZ_USAGE.TZ_USAGE_CODE IS 'Primary key used to relate parameters other entities';
    COMMENT ON COLUMN CWMS_TZ_USAGE.TZ_USAGE_ID   IS 'Timezone usage text identifier';
    COMMENT ON COLUMN CWMS_TZ_USAGE.DESCRIPTION   IS 'Timezone usage text description';




    -- ## TABLE ###############################################
    -- ## CWMS_INTERVAL
    -- ##
    CREATE TABLE CWMS_INTERVAL
       (
           INTERVAL_CODE  NUMBER(14)   NOT NULL,
           INTERVAL_ID    VARCHAR2(16) NOT NULL,
           INTERVAL       NUMBER(14)   NOT NULL,
           DESCRIPTION    VARCHAR2(80)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20K
              NEXT 20K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );
    -------------------------------
    -- CWMS_INTERVAL constraints --
    --
    ALTER TABLE CWMS_INTERVAL ADD CONSTRAINT CWMS_INTERVAL_PK PRIMARY KEY(INTERVAL_CODE);




    -- ## TABLE ###############################################
    -- ## CWMS_DURATION
    -- ##
    CREATE TABLE CWMS_DURATION
       (
           DURATION_CODE NUMBER(14)   NOT NULL,
           DURATION_ID   VARCHAR2(16) NOT NULL,
           DURATION      NUMBER(14)   NOT NULL,
           DESCRIPTION   VARCHAR2(80)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20K
              NEXT 20K
              MINEXTENTS 1
              MAXEXTENTS 100
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    --------------------------------
    -- CWMS_DURATION constratints --
    --
    ALTER TABLE CWMS_DURATION ADD CONSTRAINT CWMS_DURATION_PK PRIMARY KEY(DURATION_CODE);

    CREATE UNIQUE INDEX CWMS_DURATION_UI ON CWMS_DURATION(UPPER(DURATION_ID));




    -- ## TABLE ###############################################
    -- ## CWMS_SHEF_DURATION
    -- ##
    CREATE TABLE CWMS_SHEF_DURATION(
      SHEF_DURATION_CODE     VARCHAR2(1 BYTE),
      SHEF_DURATION_DESC     VARCHAR2(128 BYTE),
      SHEF_DURATION_NUMERIC  VARCHAR2(4 BYTE),
      CWMS_DURATION_CODE     NUMBER
    )
    TABLESPACE CWMS_20DATA
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


    CREATE UNIQUE INDEX CWMS_SHEF_DURATION_PK ON CWMS_SHEF_DURATION
    (SHEF_DURATION_CODE)
    LOGGING
    TABLESPACE CWMS_20DATA
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


    ALTER TABLE CWMS_SHEF_DURATION ADD (
      CONSTRAINT CWMS_SHEF_DURATION_PK
     PRIMARY KEY
     (SHEF_DURATION_CODE)
        USING INDEX
        TABLESPACE CWMS_20DATA
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


    ALTER TABLE CWMS_SHEF_DURATION ADD (
      CONSTRAINT CWMS_SHEF_DURATION_R01
     FOREIGN KEY (CWMS_DURATION_CODE)
     REFERENCES CWMS_DURATION (DURATION_CODE))
    /


    -- ## TABLE ###############################################
    -- ## CWMS_ABSTRACT_PARAMETER
    -- ##
    CREATE TABLE CWMS_ABSTRACT_PARAMETER
       (
           ABSTRACT_PARAM_CODE NUMBER(14) generated always as identity NOT NULL  primary key,
           ABSTRACT_PARAM_ID   VARCHAR2(32 BYTE)  NOT NULL
       );

    -----------------------------
    -- CWMS_ABSTRACT_PARAMETER indicies
    --
    CREATE UNIQUE INDEX CWMS_ABSTRACT_PARAMETER_UI ON CWMS_ABSTRACT_PARAMETER
       (
           UPPER(ABSTRACT_PARAM_ID)
       );

    -----------------------------
    -- CWMS_ABSTRACT_PARAMETER comments
    --
    COMMENT ON TABLE CWMS_ABSTRACT_PARAMETER IS 'Contains abstract parameters used with CWMS';
    COMMENT ON COLUMN CWMS_ABSTRACT_PARAMETER.ABSTRACT_PARAM_CODE IS 'Primary key used for relating abstract parameters to other entities';
    COMMENT ON COLUMN CWMS_ABSTRACT_PARAMETER.ABSTRACT_PARAM_ID IS 'Text identifier of abstract parameter';



    -- ## TABLE ###############################################
    -- ## CWMS_UNIT
    -- ##
    CREATE TABLE CWMS_UNIT
       (
           UNIT_CODE           NUMBER(14) generated always as identity NOT NULL primary key,
           UNIT_ID             VARCHAR2(16 BYTE)  NOT NULL,
           ABSTRACT_PARAM_CODE NUMBER(14)         NOT NULL,
           UNIT_SYSTEM         VARCHAR2(2 BYTE),
           LONG_NAME           VARCHAR2(80 BYTE),
           DESCRIPTION         VARCHAR2(80 BYTE)
       );

    -----------------------------
    -- CWMS_UNIT constraints
    --    
    ALTER TABLE CWMS_UNIT ADD CONSTRAINT CWMS_UNIT_UK UNIQUE      (UNIT_ID, ABSTRACT_PARAM_CODE);
    ALTER TABLE CWMS_UNIT ADD CONSTRAINT CWMS_UNIT_FK FOREIGN KEY (ABSTRACT_PARAM_CODE) REFERENCES CWMS_ABSTRACT_PARAMETER (ABSTRACT_PARAM_CODE);

    -----------------------------
    -- CWMS_UNIT comments
    --
    COMMENT ON TABLE CWMS_UNIT IS 'Contains all internal and external units used with CWMS';
    COMMENT ON COLUMN CWMS_UNIT.UNIT_CODE IS 'Primary key used for relating units to other entities';
    COMMENT ON COLUMN CWMS_UNIT.ABSTRACT_PARAM_CODE IS 'Foreign key referencing CWMS_ABSTRACT_PARAMETER table';
    COMMENT ON COLUMN CWMS_UNIT.UNIT_ID IS 'Short text identifier of unit';
    COMMENT ON COLUMN CWMS_UNIT.UNIT_SYSTEM IS 'SI deonotes SI, EN denotes English, Null denotes both SI and EN';
    COMMENT ON COLUMN CWMS_UNIT.LONG_NAME IS 'Complete name of unit';
    COMMENT ON COLUMN CWMS_UNIT.DESCRIPTION IS 'Description of unit';




    -- ## TABLE ###############################################
    -- ## CWMS_UNIT_CONVERSION
    -- ##
    CREATE TABLE CWMS_UNIT_CONVERSION
    (
      FROM_UNIT_ID        VARCHAR2(16 BYTE)       NOT NULL,
      TO_UNIT_ID          VARCHAR2(16 BYTE)       NOT NULL,
      ABSTRACT_PARAM_CODE NUMBER(14)              NOT NULL,
      FROM_UNIT_CODE      NUMBER(14)              NOT NULL,
      TO_UNIT_CODE        NUMBER(14)              NOT NULL,
      FACTOR              BINARY_DOUBLE,
      OFFSET              BINARY_DOUBLE,
      FUNCTION            VARCHAR2(64),
      CONSTRAINT CWMS_UNIT_CONVERSION_PK  PRIMARY KEY (FROM_UNIT_ID, TO_UNIT_ID),
      CONSTRAINT CWMS_UNIT_CONVERSION_FK1 FOREIGN KEY (FROM_UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE),
      CONSTRAINT CWMS_UNIT_CONVERSION_FK2 FOREIGN KEY (TO_UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE),
      CONSTRAINT CWMS_UNIT_CONVERSION_FK3 FOREIGN KEY (FROM_UNIT_ID, ABSTRACT_PARAM_CODE) REFERENCES CWMS_UNIT (UNIT_ID, ABSTRACT_PARAM_CODE),
      CONSTRAINT CWMS_UNIT_CONVERSION_FK4 FOREIGN KEY (TO_UNIT_ID, ABSTRACT_PARAM_CODE) REFERENCES CWMS_UNIT (UNIT_ID, ABSTRACT_PARAM_CODE),
      CONSTRAINT CWMS_UNIT_CONVERSION_CK1 CHECK ((FACTOR IS NULL AND OFFSET IS NULL) OR (FACTOR IS NOT NULL AND OFFSET IS NOT NULL)),
      CONSTRAINT CWMS_UNIT_CONVERSION_CK2 CHECK ((FACTOR IS NULL AND FUNCTION IS NOT NULL) OR (FACTOR IS NOT NULL AND FUNCTION IS NULL))
    )
    ORGANIZATION INDEX
    LOGGING
    TABLESPACE CWMS_20DATA
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
    MONITORING
    /

    -----------------------------
    -- CWMS_UNIT_CONVERSION indexes
    --

    CREATE UNIQUE INDEX CWMS_UNIT_CONVERSION_U01 ON CWMS_UNIT_CONVERSION
    (FROM_UNIT_CODE, TO_UNIT_CODE)
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

    -----------------------------
    -- CWMS_UNIT_CONVERSION comments
    --
    COMMENT ON TABLE CWMS_UNIT_CONVERSION IS 'Contains linear conversion factors for units';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.FROM_UNIT_ID IS   'Source unit';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.TO_UNIT_ID IS     'Destination unit';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.FROM_UNIT_CODE IS 'Source unit';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.TO_UNIT_CODE IS   'Destination unit';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.FACTOR IS         'Ratio of units    (m in y=mx+b for linear conversions)';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.OFFSET IS         'Offset of units   (b in y=mx+b for non-linear conversions)';
    COMMENT ON COLUMN CWMS_UNIT_CONVERSION.FUNCTION IS       'Non-linear conversion function';

    -----------------------------
    -- CWMS_UNIT_CONVERSION_UNIT trigger
    --
    CREATE OR REPLACE TRIGGER CWMS_UNIT_CONVERSION_UNIT
    BEFORE INSERT OR UPDATE OF FROM_UNIT_CODE, TO_UNIT_CODE
    ON CWMS_UNIT_CONVERSION
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
    DECLARE
       --
       -- This trigger ensures that the abstract parameter associated with the source unit
       -- is the same as the abstract parameter associated with the destination unit.
       --
       FROM_ABSTRACT_CODE          CWMS_ABSTRACT_PARAMETER.ABSTRACT_PARAM_CODE%TYPE;
       FROM_ABSTRACT_ID            CWMS_ABSTRACT_PARAMETER.ABSTRACT_PARAM_ID%TYPE;
       FROM_ID                     CWMS_UNIT.UNIT_ID%TYPE;
       TO_ABSTRACT_CODE            CWMS_ABSTRACT_PARAMETER.ABSTRACT_PARAM_CODE%TYPE;
       TO_ABSTRACT_ID              CWMS_ABSTRACT_PARAMETER.ABSTRACT_PARAM_ID%TYPE;
       TO_ID                       CWMS_UNIT.UNIT_ID%TYPE;
       INCONSISTENT_ABSTRACT_CODES EXCEPTION;
       PRAGMA EXCEPTION_INIT(INCONSISTENT_ABSTRACT_CODES, -20000);
    BEGIN
       SELECT ABSTRACT_PARAM_CODE
          INTO   FROM_ABSTRACT_CODE
          FROM   CWMS_UNIT
          WHERE  UNIT_CODE = :NEW.FROM_UNIT_CODE;
       SELECT ABSTRACT_PARAM_CODE
          INTO   TO_ABSTRACT_CODE
          FROM   CWMS_UNIT
          WHERE  UNIT_CODE = :NEW.TO_UNIT_CODE;
       IF FROM_ABSTRACT_CODE != TO_ABSTRACT_CODE
       THEN
          RAISE INCONSISTENT_ABSTRACT_CODES;
       END IF;
    EXCEPTION
       WHEN INCONSISTENT_ABSTRACT_CODES THEN
          SELECT UNIT_ID
             INTO   FROM_ID
             FROM   CWMS_UNIT
             WHERE  UNIT_CODE = :NEW.FROM_UNIT_CODE;
          SELECT UNIT_ID
             INTO   TO_ID
             FROM   CWMS_UNIT
             WHERE  UNIT_CODE = :NEW.TO_UNIT_CODE;
          SELECT ABSTRACT_PARAM_ID
             INTO   FROM_ABSTRACT_ID
             FROM   CWMS_ABSTRACT_PARAMETER
             WHERE  ABSTRACT_PARAM_CODE=FROM_ABSTRACT_CODE;
          SELECT ABSTRACT_PARAM_ID
             INTO   TO_ABSTRACT_ID
             FROM   CWMS_ABSTRACT_PARAMETER
             WHERE  ABSTRACT_PARAM_CODE=TO_ABSTRACT_CODE;
          DBMS_OUTPUT.PUT_LINE(
             'ERROR: From-unit "'
             || FROM_ID
             || '" has abstract parameter "'
             || FROM_ABSTRACT_ID
             || '" but To-unit "'
             || TO_ID
             || '" has abstract parameter "'
             || TO_ABSTRACT_ID
             || '".');
          RAISE;
       WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(SQLERRM);
          RAISE;
    END R_PARAMETER_UNIT;
    /





    -- ## TABLE ###############################################
    -- ## CWMS_PARAMETER_TYPE
    -- ##
    CREATE TABLE CWMS_PARAMETER_TYPE
      (
           PARAMETER_TYPE_CODE  NUMBER(14)   NOT NULL,
           PARAMETER_TYPE_ID    VARCHAR2(16) NOT NULL,
           DESCRIPTION          VARCHAR2(80) NULL
      )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20k
              NEXT 20k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_PARAMETER_TYPE indicies
    --
    CREATE UNIQUE INDEX CWMS_PARAMETER_TYPE_UI ON CWMS_PARAMETER_TYPE
       (
           UPPER(PARAMETER_TYPE_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20k
              NEXT 20k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -------------------------------------
    -- CWMS_PARAMETER_TYPE constraints --
    --
    ALTER TABLE CWMS_PARAMETER_TYPE ADD CONSTRAINT CWMS_PARAMETER_TYPE_PK PRIMARY KEY (PARAMETER_TYPE_CODE);

    ----------------------------------
    -- CWMS_PARAMETER_TYPE comments --
    --
    COMMENT ON TABLE  CWMS_PARAMETER_TYPE IS 'Associated with a parameter to define the relationship of the data value to its duration.  The valid values include average, total, maximum, minimum, and constant.';
    COMMENT ON COLUMN CWMS_PARAMETER_TYPE.PARAMETER_TYPE_CODE IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
    COMMENT ON COLUMN CWMS_PARAMETER_TYPE.PARAMETER_TYPE_ID IS 'Record identifier that is meaningful to the user.  This is user defined.  If not defined during data entry, it defaults to PARAMETER_TYPE_CODE.';
    COMMENT ON COLUMN CWMS_PARAMETER_TYPE.DESCRIPTION IS 'Additional information.';




    -- ## TABLE ###############################################
    -- ## CWMS_BASE_PARAMETER
    -- ##
    CREATE TABLE CWMS_BASE_PARAMETER
       (
           BASE_PARAMETER_CODE      NUMBER(14)         NOT NULL,
           BASE_PARAMETER_ID        VARCHAR2(16 BYTE)  NOT NULL,
           ABSTRACT_PARAM_CODE      NUMBER(14)         NOT NULL,
           UNIT_CODE                NUMBER(14)         NOT NULL,
           DISPLAY_UNIT_CODE_SI     NUMBER(14)         NOT NULL,
           DISPLAY_UNIT_CODE_EN     NUMBER(14)         NOT NULL,
           LONG_NAME                VARCHAR2(80 BYTE),
           DESCRIPTION              VARCHAR2(160 BYTE)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200K
              NEXT 200K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_BASE_PARAMETER indicies
    --
    CREATE UNIQUE INDEX CWMS_BASE_PARAMETER_UI ON CWMS_BASE_PARAMETER
       (
           UPPER(BASE_PARAMETER_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200k
              NEXT 200k
              MINEXTENTS 1
              MAXEXTENTS 20
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_BASE_PARAMETER constraints
    --
    ALTER TABLE CWMS_BASE_PARAMETER ADD CONSTRAINT CWMS_BASE_PARAMETER_PK   PRIMARY KEY (BASE_PARAMETER_CODE);
    ALTER TABLE CWMS_BASE_PARAMETER ADD CONSTRAINT CWMS_BASE_PARAMETER_FK1 FOREIGN KEY (ABSTRACT_PARAM_CODE) REFERENCES CWMS_ABSTRACT_PARAMETER (ABSTRACT_PARAM_CODE);
    ALTER TABLE CWMS_BASE_PARAMETER ADD CONSTRAINT CWMS_BASE_PARAMETER_FK2 FOREIGN KEY (UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);
    ALTER TABLE CWMS_BASE_PARAMETER ADD CONSTRAINT CWMS_BASE_PARAMETER_FK3 FOREIGN KEY (DISPLAY_UNIT_CODE_SI) REFERENCES CWMS_UNIT (UNIT_CODE);
    ALTER TABLE CWMS_BASE_PARAMETER ADD CONSTRAINT CWMS_BASE_PARAMETER_FK4 FOREIGN KEY (DISPLAY_UNIT_CODE_EN) REFERENCES CWMS_UNIT (UNIT_CODE);

    -----------------------------
    -- CWMS_BASE_PARAMETER comments
    --
    COMMENT ON TABLE CWMS_BASE_PARAMETER IS 'List of parameters allowed in the CWMS database';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.BASE_PARAMETER_CODE IS 'Primary key used to relate parameters other entities';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.BASE_PARAMETER_ID IS 'Short identifier of parameter';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.ABSTRACT_PARAM_CODE IS 'Foreign key referencing CWMS_ABSTRACT_PARAMETER table';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.UNIT_CODE IS 'This is the db storage unit for this parameter. Foreign key referencing @cwmsUnitTableName table.';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.DISPLAY_UNIT_CODE_SI IS 'This is the default SI display unit for this parameter. Foreign key referencing @cwmsUnitTableName table.';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.DISPLAY_UNIT_CODE_EN IS 'This is the default Non-SI display unit for this parameter. Foreign key referencing @cwmsUnitTableName table.';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.LONG_NAME IS 'Full name of parameter';
    COMMENT ON COLUMN CWMS_BASE_PARAMETER.DESCRIPTION IS 'Description of parameter';

    -----------------------------
    -- CWMS_BASE_PARAMETER_UNIT trigger
    --
    CREATE OR REPLACE TRIGGER cwms_base_parameter_unit
       BEFORE INSERT OR UPDATE OF abstract_param_code, unit_code
       ON cwms_base_parameter
       REFERENCING NEW AS NEW OLD AS OLD
       FOR EACH ROW
    DECLARE
       --
       -- This trigger ensures that the abstract parameter associated with the specified
       -- unit is the same as the abstract parameter associated with this parameter.
       --
       unit_abstract_code            cwms_abstract_parameter.abstract_param_code%TYPE;
       unit_abstract_id              cwms_abstract_parameter.abstract_param_id%TYPE;
       unit_id                       cwms_unit.unit_id%TYPE;
       unit_type                     VARCHAR (20);
       parameter_abstract_id         cwms_abstract_parameter.abstract_param_id%TYPE;
       inconsistent_abstract_codes   EXCEPTION;
       PRAGMA EXCEPTION_INIT (inconsistent_abstract_codes, -20000);
    BEGIN
       SELECT u.abstract_param_code
         INTO unit_abstract_code
         FROM cwms_unit u
        WHERE u.unit_code = :NEW.unit_code;

       IF :NEW.abstract_param_code != unit_abstract_code
       THEN
          SELECT u.unit_id
            INTO unit_id
            FROM cwms_unit u
           WHERE u.unit_code = :NEW.unit_code;

          unit_type := 'DB Storage Unit';
          RAISE inconsistent_abstract_codes;
       END IF;

       --
       SELECT u.abstract_param_code
         INTO unit_abstract_code
         FROM cwms_unit u
        WHERE u.unit_code = :NEW.display_unit_code_si;

       IF :NEW.abstract_param_code != unit_abstract_code
       THEN
          SELECT u.unit_id
            INTO unit_id
            FROM cwms_unit u
           WHERE u.unit_code = :NEW.display_unit_code_si;

          unit_type := 'SI Display Unit';
          RAISE inconsistent_abstract_codes;
       END IF;

       --
       SELECT u.abstract_param_code
         INTO unit_abstract_code
         FROM cwms_unit u
        WHERE u.unit_code = :NEW.display_unit_code_en;

       IF :NEW.abstract_param_code != unit_abstract_code
       THEN
          SELECT u.unit_id
            INTO unit_id
            FROM cwms_unit u
           WHERE u.unit_code = :NEW.display_unit_code_en;

          unit_type := 'Non-SI Display Unit';
          RAISE inconsistent_abstract_codes;
       END IF;
    EXCEPTION
       WHEN inconsistent_abstract_codes
       THEN
          SELECT abstract_param_id
            INTO unit_abstract_id
            FROM cwms_abstract_parameter
           WHERE abstract_param_code = unit_abstract_code;

          SELECT abstract_param_id
            INTO parameter_abstract_id
            FROM cwms_abstract_parameter
           WHERE abstract_param_code = :NEW.abstract_param_code;

          DBMS_OUTPUT.put_line (   'ERROR: Parameter "'
                                || :NEW.base_parameter_id
                                || '" has abstract parameter "'
                                || parameter_abstract_id
                                || '" but '
                                || unit_type
                                ||  ' "'
                                || unit_id
                                || '" has abstract parameter "'
                                || unit_abstract_id
                                || '".'
                               );
          RAISE;
       WHEN OTHERS
       THEN
          DBMS_OUTPUT.put_line (SQLERRM);
          RAISE;
    END r_parameter_unit;
    /





    -- ## TABLE ###############################################
    -- ## AT_PARAMETER
    -- ##

    CREATE TABLE AT_PARAMETER
    (
      PARAMETER_CODE       NUMBER,
      DB_OFFICE_CODE       NUMBER                     NOT NULL,
      BASE_PARAMETER_CODE  NUMBER                     NOT NULL,
      SUB_PARAMETER_ID     VARCHAR2(32 BYTE),
      SUB_PARAMETER_DESC   VARCHAR2(80 BYTE)
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

    -----------------------------
    -- AT_PARAMETER indicies
    --
    CREATE UNIQUE INDEX AT_PARAMETER_PK ON AT_PARAMETER
    (PARAMETER_CODE)
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


    CREATE UNIQUE INDEX AT_PARAMETER_UK1 ON AT_PARAMETER
    (BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE)
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

    -----------------------------
    -- AT_PARAMETER constraints
    --
    ALTER TABLE AT_PARAMETER ADD (
      CONSTRAINT AT_PARAMETER_PK
     PRIMARY KEY
     (PARAMETER_CODE)
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

    ALTER TABLE AT_PARAMETER ADD (
      CONSTRAINT AT_PARAMETER_UK1
     UNIQUE (BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE)
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

    ALTER TABLE AT_PARAMETER ADD (
      CONSTRAINT AT_PARAMETER_FK1
     FOREIGN KEY (DB_OFFICE_CODE)
     REFERENCES CWMS_OFFICE (OFFICE_CODE))
    /

    ALTER TABLE AT_PARAMETER ADD (
      CONSTRAINT AT_PARAMETER_FK2
     FOREIGN KEY (BASE_PARAMETER_CODE)
     REFERENCES CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE))
    /

    ALTER TABLE AT_PARAMETER ADD (
      CONSTRAINT AT_PARAMETER_CK_1
           CHECK (TRIM(SUB_PARAMETER_ID)=SUB_PARAMETER_ID))
    /




    ---------------------------------
    -- AT_DISPLAY_UNITS table
    --
    CREATE TABLE AT_DISPLAY_UNITS
    (
      DB_OFFICE_CODE     NUMBER                     NOT NULL,
      PARAMETER_CODE     NUMBER                     NOT NULL,
      UNIT_SYSTEM        VARCHAR2(2 BYTE)           NOT NULL,
      DISPLAY_UNIT_CODE  NUMBER                     NOT NULL
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
    MONITORING;


    CREATE UNIQUE INDEX AT_DISPLAY_UNITS_PK1 ON AT_DISPLAY_UNITS
    (DB_OFFICE_CODE, PARAMETER_CODE, UNIT_SYSTEM)
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
    NOPARALLEL;


    ALTER TABLE AT_DISPLAY_UNITS ADD (
      CONSTRAINT AT_DISPLAY_UNITS_PK1
     PRIMARY KEY
     (DB_OFFICE_CODE, PARAMETER_CODE, UNIT_SYSTEM)
        USING INDEX
        tablespace CWMS_20AT_DATA
        PCTFREE    10
        INITRANS   2
        MAXTRANS   255
        STORAGE    (
                    INITIAL          64K
                    MINEXTENTS       1
                    MAXEXTENTS       2147483645
                    PCTINCREASE      0
                   ));


    ALTER TABLE AT_DISPLAY_UNITS ADD (
      CONSTRAINT AT_DISPLAY_UNITS_FK02
     FOREIGN KEY (DISPLAY_UNIT_CODE)
     REFERENCES CWMS_UNIT (UNIT_CODE));

    ALTER TABLE AT_DISPLAY_UNITS ADD (
      CONSTRAINT AT_DISPLAY_UNITS_FK01
     FOREIGN KEY (PARAMETER_CODE)
     REFERENCES AT_PARAMETER (PARAMETER_CODE));


    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_SCREENED
    -- ##
    CREATE TABLE CWMS_DATA_Q_SCREENED
       (
           SCREENED_ID   VARCHAR2(16)  NOT NULL,
           DESCRIPTION   VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_SCREENED_PK PRIMARY KEY (SCREENED_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_SCREENED comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_SCREENED               IS 'Contains valid values for the screened component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_SCREENED.SCREENED_ID   IS 'Text identifier of screened component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_SCREENED.DESCRIPTION   IS 'Text description of screened component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_VALIDITY
    -- ##
    CREATE TABLE CWMS_DATA_Q_VALIDITY
       (
           VALIDITY_ID   VARCHAR2(16)  NOT NULL,
           DESCRIPTION   VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_VALIDITY_PK PRIMARY KEY (VALIDITY_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_VALIDITY comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_VALIDITY               IS 'Contains valid values for the validity component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_VALIDITY.VALIDITY_ID   IS 'Text identifier of validity component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_VALIDITY.DESCRIPTION   IS 'Text description of validity component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_RANGE
    -- ##
    CREATE TABLE CWMS_DATA_Q_RANGE
       (
           RANGE_ID    VARCHAR2(16)  NOT NULL,
           DESCRIPTION VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_RANGE_PK PRIMARY KEY (RANGE_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_RANGE comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_RANGE             IS 'Contains valid values for the range component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_RANGE.RANGE_ID    IS 'Text identifier of range component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_RANGE.DESCRIPTION IS 'Text description of range component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_CHANGED
    -- ##
    CREATE TABLE CWMS_DATA_Q_CHANGED
       (
           CHANGED_ID   VARCHAR2(16)  NOT NULL,
           DESCRIPTION  VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_CHANGED_PK PRIMARY KEY (CHANGED_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_CHANGED comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_CHANGED              IS 'Contains valid values for the changed component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_CHANGED.CHANGED_ID   IS 'Text identifier of changed component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_CHANGED.DESCRIPTION  IS 'Text description of changed component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_REPL_CAUSE
    -- ##
    CREATE TABLE CWMS_DATA_Q_REPL_CAUSE
       (
           REPL_CAUSE_ID   VARCHAR2(16)  NOT NULL,
           DESCRIPTION     VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_REPL_CAUSE_PK PRIMARY KEY (REPL_CAUSE_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_REPL_CAUSE comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_REPL_CAUSE                 IS 'Contains valid values for the replacement cause component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_REPL_CAUSE.REPL_CAUSE_ID   IS 'Text identifier of replacement cause component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_REPL_CAUSE.DESCRIPTION     IS 'Text description of replacement cause component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_REPL_METHOD
    -- ##
    CREATE TABLE CWMS_DATA_Q_REPL_METHOD
       (
           REPL_METHOD_ID   VARCHAR2(16)  NOT NULL,
           DESCRIPTION      VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_REPL_METHOD_PK PRIMARY KEY (REPL_METHOD_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );

    ---------------------------
    -- CWMS_DATA_Q_REPL_METHOD comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_REPL_METHOD                  IS 'Contains valid values for the replacement method component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_REPL_METHOD.REPL_METHOD_ID   IS 'Text identifier of replacement method component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_REPL_METHOD.DESCRIPTION      IS 'Text description of replacement method component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_TEST_FAILED
    -- ##
    CREATE TABLE CWMS_DATA_Q_TEST_FAILED
       (
           TEST_FAILED_ID   VARCHAR2(125)  NOT NULL,
           DESCRIPTION      VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_TEST_FAILED_PK PRIMARY KEY (TEST_FAILED_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_TEST_FAILED comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_TEST_FAILED                  IS 'Contains valid values for the test failed component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_TEST_FAILED.TEST_FAILED_ID   IS 'Text identifier of test failed component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_TEST_FAILED.DESCRIPTION      IS 'Text description of test failed component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_Q_PROTECTION
    -- ##
    CREATE TABLE CWMS_DATA_Q_PROTECTION
       (
           PROTECTION_ID   VARCHAR2(16)  NOT NULL,
           DESCRIPTION     VARCHAR2(80),
           CONSTRAINT CWMS_DATA_Q_PROTECTION_PK PRIMARY KEY (PROTECTION_ID)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 10K
              NEXT 10K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );


    ---------------------------
    -- CWMS_DATA_Q_PROTECTION comments --
    --
    COMMENT ON TABLE  CWMS_DATA_Q_PROTECTION                 IS 'Contains valid values for the protection component of CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_Q_PROTECTION.PROTECTION_ID   IS 'Text identifier of protection component and primary key';
    COMMENT ON COLUMN CWMS_DATA_Q_PROTECTION.DESCRIPTION     IS 'Text description of protection component';




    -- ## TABLE ###############################################
    -- ## CWMS_DATA_QUALITY
    -- ##
    CREATE TABLE CWMS_DATA_QUALITY
       (
           QUALITY_CODE   NUMBER(14)    NOT NULL,
           SCREENED_ID    VARCHAR2(16)  NOT NULL,
           VALIDITY_ID    VARCHAR2(16)  NOT NULL,
           RANGE_ID       VARCHAR2(16)  NOT NULL,
           CHANGED_ID     VARCHAR2(16)  NOT NULL,
           REPL_CAUSE_ID  VARCHAR2(16)  NOT NULL,
           REPL_METHOD_ID VARCHAR2(16)  NOT NULL,
           TEST_FAILED_ID VARCHAR2(125) NOT NULL,
           PROTECTION_ID  VARCHAR2(16)  NOT NULL,
           CONSTRAINT CWMS_DATA_QUALITY_PK   PRIMARY KEY (QUALITY_CODE)
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 300K
              NEXT 300K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );

    -------------------------------
    -- CWMS_DATA_QUALITY constraints  --
    --
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK1 FOREIGN KEY (SCREENED_ID   ) REFERENCES CWMS_DATA_Q_SCREENED   (SCREENED_ID   );
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK2 FOREIGN KEY (PROTECTION_ID ) REFERENCES CWMS_DATA_Q_PROTECTION (PROTECTION_ID );
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK3 FOREIGN KEY (VALIDITY_ID   ) REFERENCES CWMS_DATA_Q_VALIDITY   (VALIDITY_ID   );
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK4 FOREIGN KEY (RANGE_ID      ) REFERENCES CWMS_DATA_Q_RANGE      (RANGE_ID      );
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK5 FOREIGN KEY (CHANGED_ID    ) REFERENCES CWMS_DATA_Q_CHANGED    (CHANGED_ID    );
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK6 FOREIGN KEY (REPL_CAUSE_ID ) REFERENCES CWMS_DATA_Q_REPL_CAUSE  (REPL_CAUSE_ID );
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK7 FOREIGN KEY (REPL_METHOD_ID) REFERENCES CWMS_DATA_Q_REPL_METHOD (REPL_METHOD_ID);
    ALTER TABLE CWMS_DATA_QUALITY ADD CONSTRAINT CWMS_DATA_QUALITY_FK8 FOREIGN KEY (TEST_FAILED_ID) REFERENCES CWMS_DATA_Q_TEST_FAILED (TEST_FAILED_ID);

    ---------------------------
    -- CWMS_DATA_QUALITY comments --
    --
    COMMENT ON TABLE  CWMS_DATA_QUALITY                IS 'Contains CWMS data quality flags';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.QUALITY_CODE   IS 'Quality value as an unsigned integer and primary key for relating quality to other entities';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.SCREENED_ID    IS 'Foreign key referencing CWMS_DATA_Q_SCREENED table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.VALIDITY_ID    IS 'Foreign key referencing CWMS_DATA_Q_VALIDITY table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.RANGE_ID       IS 'Foreign key referencing CWMS_DATA_Q_RANGE table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.CHANGED_ID     IS 'Foreign key referencing CWMS_DATA_Q_CHANGED table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.REPL_CAUSE_ID  IS 'Foreign key referencing CWMS_DATA_Q_REPL_CAUSE table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.REPL_METHOD_ID IS 'Foreign key referencing CWMS_DATA_Q_REPL_METHOD table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.TEST_FAILED_ID IS 'Foreign key referencing CWMS_DATA_Q_TEST_FAILED table by its primary key';
    COMMENT ON COLUMN CWMS_DATA_QUALITY.PROTECTION_ID  IS 'Foreign key referencing CWMS_DATA_Q_PROTECTION table by its primary key';



    -- ## TABLE ###############################################
    -- ## CWMS_RATING_METHOD
    -- ##
    CREATE TABLE CWMS_RATING_METHOD
       (
           RATING_METHOD_CODE NUMBER(14),
           RATING_METHOD_ID   VARCHAR2(32),
           DESCRIPTION        VARCHAR2(256),
           CONSTRAINT CWMS_RATING_METHOD_PK PRIMARY KEY(RATING_METHOD_CODE)
       )
           ORGANIZATION INDEX
           TABLESPACE CWMS_20DATA;

    -----------------------------
    -- CWMS_RATING_METHOD indicies
    --
    CREATE UNIQUE INDEX CWMS_RATING_METHOD_UI ON CWMS_RATING_METHOD
       (
           UPPER(RATING_METHOD_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 20k
              NEXT 20k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );




    -- ## TABLE ###############################################
    -- ## CWMS_DSS_PARAMETER_TYPE
    -- ##
    CREATE TABLE CWMS_DSS_PARAMETER_TYPE
      (
           DSS_PARAMETER_TYPE_CODE NUMBER(14)   NOT NULL,
           DSS_PARAMETER_TYPE_ID   VARCHAR2(8)  NOT NULL,
           PARAMETER_TYPE_CODE     NUMBER(14)   NOT NULL,
           DESCRIPTION             VARCHAR2(40) NULL
      )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200k
              NEXT 200k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_DSS_PARAMETER_TYPE indicies
    --
    CREATE UNIQUE INDEX CWMS_DSS_PARAMETER_TYPE_UI ON CWMS_DSS_PARAMETER_TYPE
       (
           UPPER(DSS_PARAMETER_TYPE_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200k
              NEXT 200k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -------------------------------------
    -- CWMS_DSS_PARAMETER_TYPE constraints --
    --
    ALTER TABLE CWMS_DSS_PARAMETER_TYPE ADD CONSTRAINT CWMS_DSS_PARAMETER_TYPE_PK PRIMARY KEY (DSS_PARAMETER_TYPE_CODE);
    ALTER TABLE CWMS_DSS_PARAMETER_TYPE ADD CONSTRAINT CWMS_DSS_PARAMETER_TYPE_FK FOREIGN KEY (PARAMETER_TYPE_CODE) REFERENCES CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE);

    ----------------------------------
    -- CWMS_DSS_PARAMETER_TYPE comments --
    --
    COMMENT ON TABLE  CWMS_DSS_PARAMETER_TYPE IS 'List of valid HEC-DSS time series data types';
    COMMENT ON COLUMN CWMS_DSS_PARAMETER_TYPE.DSS_PARAMETER_TYPE_CODE IS 'Primary key for relating HEC-DSS parameter types to other entities';
    COMMENT ON COLUMN CWMS_DSS_PARAMETER_TYPE.DSS_PARAMETER_TYPE_ID IS 'HEC-DSS time series parameter type';
    COMMENT ON COLUMN CWMS_DSS_PARAMETER_TYPE.PARAMETER_TYPE_CODE IS 'CWMS parameter type associated with the HEC-DSS parameter type';
    COMMENT ON COLUMN CWMS_DSS_PARAMETER_TYPE.DESCRIPTION IS 'Description';




    -- ## TABLE ###############################################
    -- ## CWMS_DSS_XCHG_DIRECTION
    -- ##
    CREATE TABLE CWMS_DSS_XCHG_DIRECTION
      (
           DSS_XCHG_DIRECTION_CODE NUMBER       NOT NULL,
           DSS_XCHG_DIRECTION_ID   VARCHAR2(16) NOT NULL,
           DESCRIPTION             VARCHAR2(80) NULL
      )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200k
              NEXT 200k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -----------------------------
    -- CWMS_DSS_XCHG_DIRECTION indicies
    --
    CREATE UNIQUE INDEX CWMS_DSS_XCHG_DIRECTION_UI ON CWMS_DSS_XCHG_DIRECTION
       (
           UPPER(DSS_XCHG_DIRECTION_ID)
       )
           PCTFREE 10
           INITRANS 2
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
           (
              INITIAL 200k
              NEXT 200k
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
           );

    -------------------------------------
    -- CWMS_DSS_XCHG_DIRECTION constraints --
    --
    ALTER TABLE CWMS_DSS_XCHG_DIRECTION ADD CONSTRAINT CWMS_DSS_XCHG_DIRECTION_PK PRIMARY KEY (DSS_XCHG_DIRECTION_CODE);

    ----------------------------------
    -- CWMS_DSS_XCHG_DIRECTION comments --
    --
    COMMENT ON TABLE  CWMS_DSS_XCHG_DIRECTION IS 'List of valid Oracle/HEC-DSS exchange directions';
    COMMENT ON COLUMN CWMS_DSS_XCHG_DIRECTION.DSS_XCHG_DIRECTION_CODE IS 'Primary key for relating exchange directions to other entities';
    COMMENT ON COLUMN CWMS_DSS_XCHG_DIRECTION.DSS_XCHG_DIRECTION_ID IS 'Oracle/HEC-DSS exchange direction';
    COMMENT ON COLUMN CWMS_DSS_XCHG_DIRECTION.DESCRIPTION IS 'Description';




    -- ## TABLE ###############################################
    -- ## CWMS_LOG_MESSAGE_TYPES
    -- ##
    CREATE TABLE CWMS_LOG_MESSAGE_TYPES
       (
           MESSAGE_TYPE_CODE NUMBER(2)    NOT NULL,
           MESSAGE_TYPE_ID   VARCHAR2(32) NOT NULL
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 1K
              NEXT 1K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );

    -------------------------------
    -- CWMS_LOG_MESSAGE_TYPES constraints  --
    --
    ALTER TABLE CWMS_LOG_MESSAGE_TYPES ADD CONSTRAINT CWMS_LOG_MESSAGE_TYPES_PK PRIMARY KEY (MESSAGE_TYPE_CODE);

    ---------------------------
    -- CWMS_LOG_MESSAGE_TYPES comments --
    --
    COMMENT ON TABLE  CWMS_LOG_MESSAGE_TYPES                   IS 'Contains valid values for the MSG_TYPE field of logged status messages';
    COMMENT ON COLUMN CWMS_LOG_MESSAGE_TYPES.MESSAGE_TYPE_CODE IS 'Numeric code corresponding to the message type name';
    COMMENT ON COLUMN CWMS_LOG_MESSAGE_TYPES.MESSAGE_TYPE_ID   IS 'The message type name';




    -- ## TABLE ###############################################
    -- ## CWMS_LOG_MESSAGE_PROP_TYPES
    -- ##
    CREATE TABLE CWMS_LOG_MESSAGE_PROP_TYPES
       (
           PROP_TYPE_CODE NUMBER(1)   NOT NULL,
           PROP_TYPE_ID   VARCHAR2(8) NOT NULL
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 1K
              NEXT 1K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );

    -------------------------------
    -- CWMS_LOG_MESSAGE_PROP_TYPES constraints  --
    --
    ALTER TABLE CWMS_LOG_MESSAGE_PROP_TYPES ADD CONSTRAINT CWMS_LOG_MESSAGE_PROP_TYPES_PK PRIMARY KEY (PROP_TYPE_CODE);

    ---------------------------
    -- CWMS_LOG_MESSAGE_PROP_TYPES comments --
    --
    COMMENT ON TABLE  CWMS_LOG_MESSAGE_PROP_TYPES                IS 'Contains valid values for the PROP_TYPE field of logged status message properties';
    COMMENT ON COLUMN CWMS_LOG_MESSAGE_PROP_TYPES.PROP_TYPE_CODE IS 'Numeric code corresponding to the property type name';
    COMMENT ON COLUMN CWMS_LOG_MESSAGE_PROP_TYPES.PROP_TYPE_ID   IS 'The property type name';




    -- ## TABLE ###############################################
    -- ## CWMS_INTERPOLATE_UNITS
    -- ##
    CREATE TABLE CWMS_INTERPOLATE_UNITS
       (
           INTERPOLATE_UNITS_CODE NUMBER(1)   NOT NULL,
           INTERPOLATE_UNITS_ID   VARCHAR2(16) NOT NULL
       )
           PCTFREE 10
           PCTUSED 40
           INITRANS 1
           MAXTRANS 255
           TABLESPACE CWMS_20DATA
           STORAGE
       (
              INITIAL 1K
              NEXT 1K
              MINEXTENTS 1
              MAXEXTENTS 200
              PCTINCREASE 25
              FREELISTS 1
              FREELIST GROUPS 1
              BUFFER_POOL DEFAULT
       );

    -------------------------------
    -- CWMS_INTERPOLATE_UNITS constraints  --
    --
    ALTER TABLE CWMS_INTERPOLATE_UNITS ADD CONSTRAINT CWMS_INTERPOLATE_UNITS_PK PRIMARY KEY (INTERPOLATE_UNITS_CODE);

    ---------------------------
    -- CWMS_INTERPOLATE_UNITS comments --
    --
    COMMENT ON TABLE  CWMS_INTERPOLATE_UNITS                       IS 'Contains valid values for time series interpolation units';
    COMMENT ON COLUMN CWMS_INTERPOLATE_UNITS.INTERPOLATE_UNITS_CODE IS 'Numeric code corresponding to the interpolation units';
    COMMENT ON COLUMN CWMS_INTERPOLATE_UNITS.INTERPOLATE_UNITS_ID   IS 'The interpolation units';




    -- ## TABLE ###############################################
    -- ## CWMS_GAGE_METHOD
    -- ##
    CREATE TABLE CWMS_GAGE_METHOD
    (
       METHOD_CODE NUMBER(14)    NOT NULL,
       METHOD_ID   VARCHAR2(32)  NOT NULL,
       DESCRIPTION VARCHAR2(256)
    )
    tablespace CWMS_20DATA
    PCTUSED    0
    PCTFREE    10
    INITRANS   1
    MAXTRANS   255
    STORAGE    (
                INITIAL          10K
                NEXT             10K
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

    -------------------------------
    -- CWMS_GAGE_METHOD constraints  --
    --
    ALTER TABLE CWMS_GAGE_METHOD ADD CONSTRAINT CWMS_GAGE_METHOD_PK  PRIMARY KEY(METHOD_CODE) USING INDEX;
    ALTER TABLE CWMS_GAGE_METHOD ADD CONSTRAINT CWMS_GAGE_METHOD_U1  UNIQUE (METHOD_ID) USING INDEX;
    ALTER TABLE CWMS_GAGE_METHOD ADD CONSTRAINT CWMS_GAGE_METHOD_CK1 CHECK (TRIM(METHOD_ID) = METHOD_ID);
    ALTER TABLE CWMS_GAGE_METHOD ADD CONSTRAINT CWMS_GAGE_METHOD_CK2 CHECK (UPPER(METHOD_ID) = METHOD_ID);

    ---------------------------
    -- CWMS_GAGE_METHOD comments --
    --
    COMMENT ON TABLE  CWMS_GAGE_METHOD             IS 'Contains inquiry and transmission methods gages.';
    COMMENT ON COLUMN CWMS_GAGE_METHOD.METHOD_CODE IS 'Primary key relating methods to other entities.';
    COMMENT ON COLUMN CWMS_GAGE_METHOD.METHOD_ID   IS 'Name of method (''MANUAL'', ''PHONE'', ''INTERNET'', ''GOES'', etc...).';
    COMMENT ON COLUMN CWMS_GAGE_METHOD.DESCRIPTION IS 'Optional description.';




    -- ## TABLE ###############################################
    -- ## CWMS_GAGE_TYPE
    -- ##
    CREATE TABLE CWMS_GAGE_TYPE
    (
       GAGE_TYPE_CODE      NUMBER(14)    NOT NULL,
       GAGE_TYPE_ID        VARCHAR2(32)  NOT NULL,
       MANUALLY_READ       VARCHAR2(1)   NOT NULL,
       INQUIRY_METHOD      NUMBER(14),
       TRANSMIT_METHOD     NUMBER(14),
       DESCRIPTION         VARCHAR2(256)
    )
    tablespace CWMS_20DATA
    PCTUSED    0
    PCTFREE    10
    INITRANS   1
    MAXTRANS   255
    STORAGE    (
                INITIAL          10K
                NEXT             10K
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


    -------------------------------
    -- CWMS_GAGE_TYPE constraints  --
    --
    ALTER TABLE CWMS_GAGE_TYPE ADD CONSTRAINT CWMS_GAGE_TYPE_PK  PRIMARY KEY (GAGE_TYPE_CODE) USING INDEX;
    ALTER TABLE CWMS_GAGE_TYPE ADD CONSTRAINT CWMS_GAGE_TYPE_CK1 CHECK (TRIM(GAGE_TYPE_ID) = GAGE_TYPE_ID);
    ALTER TABLE CWMS_GAGE_TYPE ADD CONSTRAINT CWMS_GAGE_TYPE_FK1 FOREIGN KEY (INQUIRY_METHOD) REFERENCES CWMS_GAGE_METHOD (METHOD_CODE);
    ALTER TABLE CWMS_GAGE_TYPE ADD CONSTRAINT CWMS_GAGE_TYPE_FK2 FOREIGN KEY (TRANSMIT_METHOD) REFERENCES CWMS_GAGE_METHOD (METHOD_CODE);

    -------------------------------
    -- CWMS_GAGE_TYPE indicies  --
    --
    CREATE UNIQUE INDEX CWMS_GAGE_TYPE_U1 ON CWMS_GAGE_TYPE (UPPER(GAGE_TYPE_ID))
    LOGGING
    tablespace CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          10K
                NEXT             1M
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
                BUFFER_POOL      DEFAULT
               )
    NOPARALLEL;

    ---------------------------
    -- CWMS_GAGE_TYPE comments --
    --
    COMMENT ON TABLE  CWMS_GAGE_TYPE                 IS 'Contains pre-defined gage types.';
    COMMENT ON COLUMN CWMS_GAGE_TYPE.GAGE_TYPE_CODE  IS 'Primary key used to relate gage types to other entities.';
    COMMENT ON COLUMN CWMS_GAGE_TYPE.GAGE_TYPE_ID    IS 'Name of gage type.';
    COMMENT ON COLUMN CWMS_GAGE_TYPE.MANUALLY_READ   IS 'Indicator of whether gage is manually read.';
    COMMENT ON COLUMN CWMS_GAGE_TYPE.INQUIRY_METHOD  IS 'Reference to method of inquiry.';
    COMMENT ON COLUMN CWMS_GAGE_TYPE.TRANSMIT_METHOD IS 'Reference to method of data transmission.';
    COMMENT ON COLUMN CWMS_GAGE_TYPE.DESCRIPTION     IS 'Optional description.';




    -- ## TABLE ###############################################
    -- ## CWMS_NATION
    -- ##
    CREATE TABLE CWMS_NATION
    (
       NATION_CODE VARCHAR2(2)  NOT NULL,
       NATION_ID   VARCHAR2(48) NOT NULL
    )
    tablespace CWMS_20DATA
    PCTUSED    0
    PCTFREE    10
    INITRANS   1
    MAXTRANS   255
    STORAGE    (
                INITIAL          10K
                NEXT             10K
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

    -------------------------------
    -- CWMS_NATION constraints  --
    --
    ALTER TABLE CWMS_NATION ADD CONSTRAINT CWMS_NATION_PK  PRIMARY KEY (NATION_CODE) USING INDEX;
    ALTER TABLE CWMS_NATION ADD CONSTRAINT CWMS_NATION_CK1 CHECK (TRIM(NATION_ID) = NATION_ID);

    -------------------------------
    -- CWMS_NATION indicies  --
    --
    CREATE UNIQUE INDEX CWMS_NATION_U1 ON CWMS_NATION (UPPER(NATION_ID))
    LOGGING
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          10K
                NEXT             1M
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
                BUFFER_POOL      DEFAULT
               )
    NOPARALLEL;

    ---------------------------
    -- CWMS_NATION comments --
    --
    COMMENT ON TABLE  CWMS_NATION             IS 'Contains names of nations';
    COMMENT ON COLUMN CWMS_NATION.NATION_CODE IS 'Primary key used to relate nation to other entities';
    COMMENT ON COLUMN CWMS_NATION.NATION_ID   IS 'Name of nation';




    -- ## TABLE ###############################################
    -- ## CWMS_VERTCON_HEADER
    -- ##
    CREATE TABLE CWMS_VERTCON_HEADER (
       DATASET_CODE NUMBER(14)    NOT NULL,
       OFFICE_CODE  NUMBER(14)    NOT NULL,
       DATASET_ID   VARCHAR2(32)  NOT NULL,
       MIN_LAT      BINARY_DOUBLE NOT NULL,
       MAX_LAT      BINARY_DOUBLE NOT NULL,
       MIN_LON      BINARY_DOUBLE NOT NULL,
       MAX_LON      BINARY_DOUBLE NOT NULL,
       MARGIN       BINARY_DOUBLE NOT NULL,
       DELTA_LAT    BINARY_DOUBLE NOT NULL,
       DELTA_LON    BINARY_DOUBLE NOT NULL
    )
    TABLESPACE CWMS_20DATA
    /
    -------------------------------
    -- CWMS_VERTCON_HEADER constraints  --
    --
    ALTER TABLE CWMS_VERTCON_HEADER ADD (
       CONSTRAINT CWMS_VERTCON_HEADER_PK  PRIMARY KEY (DATASET_CODE) USING INDEX TABLESPACE CWMS_20DATA,
       CONSTRAINT CWMS_VERTCON_HEADER_CK1 CHECK (MIN_LAT BETWEEN -90 AND 90),
       CONSTRAINT CWMS_VERTCON_HEADER_CK2 CHECK (MAX_LAT BETWEEN -90 AND 90),
       CONSTRAINT CWMS_VERTCON_HEADER_CK3 CHECK (MAX_LAT > MIN_LAT),
       CONSTRAINT CWMS_VERTCON_HEADER_CK4 CHECK (MIN_LON BETWEEN -180 AND 180),
       CONSTRAINT CWMS_VERTCON_HEADER_CK5 CHECK (MAX_LON BETWEEN -180 AND 180),
       CONSTRAINT CWMS_VERTCON_HEADER_CK6 CHECK (MAX_LON > MIN_LON),
       CONSTRAINT CWMS_VERTCON_HEADER_CK7 CHECK (MARGIN BETWEEN 0 AND MAX_LON - MIN_LON),
       CONSTRAINT CWMS_VERTCON_HEADER_CK8 CHECK (DELTA_LAT > 0 AND DELTA_LAT < (MAX_LAT - MIN_LAT) / 2),
       CONSTRAINT CWMS_VERTCON_HEADER_CK9 CHECK (DELTA_LON > 0 AND DELTA_LON < (MAX_LON - MIN_LON) / 2)
    )
    /
    CREATE UNIQUE INDEX CWMS_VERTCON_HEADER_U1 ON CWMS_VERTCON_HEADER(UPPER(DATASET_ID)) TABLESPACE CWMS_20DATA
    /
    CREATE INDEX CWMS_VERTCON_HEADER_IDX1 ON CWMS_VERTCON_HEADER(MIN_LAT, MAX_LAT, MIN_LON, MAX_LON) TABLESPACE CWMS_20DATA
    /
    ---------------------------
    -- CWMS_VERTCON_HEADER comments --
    --
    COMMENT ON TABLE  CWMS_VERTCON_HEADER              IS 'Contains header information for a vertcon data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.DATASET_CODE IS 'Unique numeric code of this data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.DATASET_ID   IS 'Unique text identifier of this data set (commonly identifies vertcon data file)';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.MIN_LAT      IS 'Minimum latitude for this data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.MAX_LAT      IS 'Maximum latitude for this data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.MIN_LON      IS 'Minimum longitude for this data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.MAX_LON      IS 'Maximum longitude for this data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.MARGIN       IS 'Longitude buffer for maximum longitude';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.DELTA_LAT    IS 'Difference between adjacent latitudes in data set';
    COMMENT ON COLUMN CWMS_VERTCON_HEADER.DELTA_LON    IS 'Difference between adjacent longitudes in data set';




    -- ## TABLE ###############################################
    -- ## CWMS_VERTCON_DATA
    -- ##
    CREATE TABLE CWMS_VERTCON_DATA (
       DATASET_CODE NUMBER(14),
       TABLE_ROW    INTEGER,
       TABLE_COL    INTEGER,
       TABLE_VAL    BINARY_DOUBLE
    )
    TABLESPACE CWMS_20DATA
    /
    -------------------------------
    -- CWMS_VERTCON_DATA constraints  --
    --
    ALTER TABLE CWMS_VERTCON_DATA ADD (
       CONSTRAINT CWMS_VERTCON_DATA_PK  PRIMARY KEY (DATASET_CODE, TABLE_ROW, TABLE_COL) USING INDEX TABLESPACE CWMS_20DATA,
       CONSTRAINT CWMS_VERTCON_DATA_FK1 FOREIGN KEY (DATASET_CODE) REFERENCES CWMS_VERTCON_HEADER (DATASET_CODE)
    )
    /
    ---------------------------
    -- CWMS_VERTCON_DATA comments --
    --
    COMMENT ON TABLE  CWMS_VERTCON_DATA              IS 'Contains datum offsets for all loaded vercon data sets';
    COMMENT ON COLUMN CWMS_VERTCON_DATA.DATASET_CODE IS 'Data set identifier - foreign key to cwms_vertcon_header table';
    COMMENT ON COLUMN CWMS_VERTCON_DATA.TABLE_ROW    IS 'Row index in vertcon data table';
    COMMENT ON COLUMN CWMS_VERTCON_DATA.TABLE_COL    IS 'Column index in vertcon data table';
    COMMENT ON COLUMN CWMS_VERTCON_DATA.TABLE_VAL    IS 'Datum offset in millimeters for row and column in vertcon data table';




    -- ## TABLE ###############################################
    -- ## CWMS_VERTICAL_DATUM
    -- ##
    CREATE TABLE CWMS_VERTICAL_DATUM (
       VERTICAL_DATUM_ID VARCHAR2(16) PRIMARY KEY
    )
    TABLESPACE CWMS_20DATA
    /
    ---------------------------
    -- CWMS_VERTICAL_DATUM comments --
    --
    COMMENT ON TABLE  CWMS_VERTICAL_DATUM                   IS 'Contains constrained list of vertical datums';
    COMMENT ON COLUMN CWMS_VERTICAL_DATUM.VERTICAL_DATUM_ID IS 'Text identifier of vertical datum';




    -- ## TABLE ###############################################
    -- ## CWMS_STORE_RULE
    -- ##
    create table CWMS_STORE_RULE (
       store_rule_code integer,
       store_rule_id   varchar2(32),
       description     varchar2(128),
       use_as_default  varchar2(1) not null,
       constraint CWMS_STORE_RULE_pk primary key(store_rule_code),
       constraint CWMS_STORE_RULE_u1 unique(store_rule_id),
       constraint CWMS_STORE_RULE_ck1 check (use_as_default in ('T', 'F'))
    ) tablespace CWMS_20DATA
    /
    ---------------------------
    -- CWMS_STORE_RULE comments --
    --
    comment on table CWMS_STORE_RULE is 'Holds CWMS data storage rules';
    comment on column CWMS_STORE_RULE.store_rule_code is 'Primary key';
    comment on column CWMS_STORE_RULE.store_rule_id is 'Text identifier, which is also the primary key';
    comment on column CWMS_STORE_RULE.description   is 'Describes store rule behavior';
    comment on column CWMS_STORE_RULE.use_as_default  is 'Use as default in UI choIce controls';




    -- ## TABLE ###############################################
    -- ## CWMS_LOCATION_KIND
    -- ##
    create table CWMS_LOCATION_KIND
    (
      location_kind_code    number(14)         not null,
      parent_location_kind  number(14),
      location_kind_id      varchar2(32 byte)  not null,
      representative_point  varchar2(32 byte)  not null,
      description           varchar2(256 byte)
    )
    /

    alter table CWMS_LOCATION_KIND add constraint CWMS_LOCATION_KIND_pk  primary key (location_kind_code) using index;
    alter table CWMS_LOCATION_KIND add constraint CWMS_LOCATION_KIND_u1  unique (location_kind_id) using index;
    alter table CWMS_LOCATION_KIND add constraint CWMS_LOCATION_KIND_fk1 foreign key (parent_location_kind) references CWMS_LOCATION_KIND (location_kind_code);
    ---------------------------
    -- CWMS_LOCATION_KIND comments --
    --
    comment on table  CWMS_LOCATION_KIND is 'Contains location kinds.';
    comment on column CWMS_LOCATION_KIND.location_kind_code   is 'Primary key relating location kinds locations.';
    comment on column CWMS_LOCATION_KIND.parent_location_kind is 'References the code of the location kind that this kind is a sub-kind of.';
    comment on column CWMS_LOCATION_KIND.location_kind_id     is 'Text name used as an input to the lookup.';
    comment on column CWMS_LOCATION_KIND.representative_point is 'The point represented by the single lat/lon in the physical location tabel.';
    comment on column CWMS_LOCATION_KIND.description          is 'Descriptive text about the location kind.';




    -- ## TABLE ###############################################
    -- ## CWMS_USGS_TIME_ZONE
    -- ##
    create table CWMS_USGS_TIME_ZONE
    (
       tz_id         varchar2(6),
       tz_name       varchar2(31),
       tz_utc_offset interval day (0) to second (3),
       constraint    cwms_usgs_time_zone_pk primary key(tz_id) using index
    )
    /
    ---------------------------
    -- CWMS_USGS_TIME_ZONE comments --
    --
    comment on table  CWMS_USGS_TIME_ZONE is 'Contains USGS Time Zone Codes';
    comment on column CWMS_USGS_TIME_ZONE.tz_id         is 'The time zone identifier (USGS tz_cd)';
    comment on column CWMS_USGS_TIME_ZONE.tz_name       is 'The time zone name';
    comment on column CWMS_USGS_TIME_ZONE.tz_utc_offset is 'The interval that the time zone is offset from UTC';




    -- ## TABLE ###############################################
    -- ## CWMS_USGS_FLOW_ADJ
    -- ##
    create table CWMS_USGS_FLOW_ADJ
    (
       adj_id      varchar2(4),
       adj_name    varchar2(26),
       description varchar2(112),
       constraint  cwms_usgs_flow_adj_pk primary key(adj_id)
    )
    /
    ---------------------------
    -- CWMS_USGS_FLOW_ADJ comments --
    --
    comment on table  CWMS_USGS_FLOW_ADJ is 'Contains USGS Flow Adjustment Codes for streamflow measurements';
    comment on column CWMS_USGS_FLOW_ADJ.adj_id      is 'The adjustment identifier (USGS discharge_cd)';
    comment on column CWMS_USGS_FLOW_ADJ.adj_name    is 'The short description of the adjustment';
    comment on column CWMS_USGS_FLOW_ADJ.description is 'The long description of the adjustment';




    -- ## TABLE ###############################################
    -- ## CWMS_USGS_RATING_CTRL_COND
    -- ##
    create table CWMS_USGS_RATING_CTRL_COND
    (
       ctrl_cond_id varchar2(20),
       description  varchar2(59),
       constraint   cwms_usgs_rating_ctrl_cond_pk primary key(ctrl_cond_id)
    )
    /
    ---------------------------
    -- CWMS_USGS_RATING_CTRL_COND comments --
    --
    comment on table  CWMS_USGS_RATING_CTRL_COND is 'Contains USGS Rating Control Condition Codes';
    comment on column CWMS_USGS_RATING_CTRL_COND.ctrl_cond_id is 'The rating control condition identifier (USGS control_type_cd)';
    comment on column CWMS_USGS_RATING_CTRL_COND.description  is 'The description of the rating control type';




    -- ## TABLE ###############################################
    -- ## CWMS_USGS_MEAS_QUAL
    -- ##
    create table CWMS_USGS_MEAS_QUAL
    (
       qual_id     varchar2(1),
       qual_name   varchar2(11),
       description varchar2(51),
       constraint  cwms_usgs_meas_qual_pk primary key(qual_id)
    )
    /
    ---------------------------
    -- CWMS_USGS_MEAS_QUAL comments --
    --
    comment on table  CWMS_USGS_MEAS_QUAL is 'Contains USGS Discharge Measurement Quality Codes';
    comment on column CWMS_USGS_MEAS_QUAL.qual_id     is 'The quality identifier (USGS measured_rating_diff)';
    comment on column CWMS_USGS_MEAS_QUAL.qual_name   is 'The quality name';
    comment on column CWMS_USGS_MEAS_QUAL.description is 'The quality description';




    -- ## TABLE ###############################################
    -- ## CWMS_USGS_PARAMETER
    -- ##
    create table CWMS_USGS_PARAMETER
    (
       usgs_parameter_code      integer,
       cwms_base_parameter_code integer not null,
       cwms_sub_parameter_id    varchar2(32),
       cwms_parameter_type_code integer not null,
       cwms_unit_code           integer not null,
       cwms_conversion_factor   binary_double not null,
       cwms_conversion_offset   binary_double not null,
       shef_physical_element    varchar2(2),
       shef_unit_is_english     varchar2(1),
       shef_conversion_factor   binary_double,
       shef_conversion_offset   binary_double,
       usgs_parameter_name      varchar2(170),
       constraint cwms_usgs_parameter_pk primary key (usgs_parameter_code)
    )
    /

    ---------------------------
    -- CWMS_USGS_PARAMETER indexes --
    --
    create index CWMS_USGS_PARAMETER_idx1 on CWMS_USGS_PARAMETER (cwms_base_parameter_code, cwms_sub_parameter_id)
    /

    ---------------------------
    -- CWMS_USGS_PARAMETER comments --
    --
    comment on table  CWMS_USGS_PARAMETER is 'Holds info on USGS parameters';
    comment on column CWMS_USGS_PARAMETER.usgs_parameter_code      is 'The USGS parameter code';
    comment on column CWMS_USGS_PARAMETER.cwms_base_parameter_code is 'The matching CWMS base parameter code';
    comment on column CWMS_USGS_PARAMETER.cwms_sub_parameter_id    is 'The matching CWMS sub-parameter id, if any';
    comment on column CWMS_USGS_PARAMETER.cwms_parameter_type_code is 'The matching CWMS parameter type code';
    comment on column CWMS_USGS_PARAMETER.cwms_unit_code           is 'The matching CWMS unit code';
    comment on column CWMS_USGS_PARAMETER.cwms_conversion_factor   is 'The factor in CWMS = USGS * factor + offset';
    comment on column CWMS_USGS_PARAMETER.cwms_conversion_offset   is 'The offset in CWMS = USGS * factor + offset';
    comment on column CWMS_USGS_PARAMETER.shef_physical_element    is 'The matching SHEF PE code, if any';
    comment on column CWMS_USGS_PARAMETER.shef_unit_is_english     is 'Flag specifying whether the SHEF units are in English: ''T'' = /DUE (optional), ''F'' = /DUS (required)';
    comment on column CWMS_USGS_PARAMETER.shef_conversion_factor   is 'The factor in SHEF = USGS * factor + offset';
    comment on column CWMS_USGS_PARAMETER.shef_conversion_offset   is 'The offset in SHEF = USGS * factor + offset';
    comment on column CWMS_USGS_PARAMETER.usgs_parameter_name      is 'The USGS parameter name';



    -- ## TABLE ###############################################
    -- ## CWMS_ENTITY_CATEGORY
    -- ##
    create table CWMS_ENTITY_CATEGORY (
       category_id varchar2(3),
       description varchar2(48),
       constraint CWMS_ENTITY_CATEGORY_pk primary key (category_id),
       constraint CWMS_ENTITY_CATEGORY_ck check (category_id = upper(trim(category_id)))
    ) organization index
    /

    ---------------------------
    -- CWMS_ENTITY_CATEGORY comments --
    --
    comment on table  CWMS_ENTITY_CATEGORY is 'Holds categories of entities';
    comment on column CWMS_ENTITY_CATEGORY.category_id is 'The category identifier';
    comment on column CWMS_ENTITY_CATEGORY.description is 'The category description';



    -- ## TABLE ###############################################
    -- ## AT_ENTITY
    -- ##
    create table AT_ENTITY (
       entity_code number(14),
       parent_code number(14),
       office_code number(14)    not null,
       category_id varchar2(3),
       entity_id   varchar2(32)  not null,
       entity_name varchar2(128) not null,
       constraint AT_ENTITY_pk  primary key (entity_code),
       constraint AT_ENTITY_fk1 foreign key (parent_code) references AT_ENTITY (entity_code),
       constraint AT_ENTITY_fk2 foreign key (category_id) references cwms_entity_category (category_id),
       constraint AT_ENTITY_ck1 check (trim(entity_id) = entity_id),
       constraint AT_ENTITY_ck2 check (trim(entity_name) = entity_name)
    ) organization index
    /

    ---------------------------
    -- AT_ENTITY indexes --
    --
    create unique index AT_ENTITY_idx_id on AT_ENTITY (office_code, upper(entity_id));

    ---------------------------
    -- AT_ENTITY comments --
    --
    comment on table  AT_ENTITY is 'Holds entities referenced by other objects';
    comment on column AT_ENTITY.entity_code is 'Unique numeric code that identifies the entity in the database';
    comment on column AT_ENTITY.parent_code is 'Entity code of parent entity, if applicable';
    comment on column AT_ENTITY.office_code is 'Numeric code that identifies the office that owns this entity in the database';
    comment on column AT_ENTITY.category_id is 'Category describing the type of entity';
    comment on column AT_ENTITY.entity_id   is 'The character identifier of the entity';
    comment on column AT_ENTITY.entity_name is 'The name of the entity';



    -- ## TABLE ###############################################
    -- ## CWMS_CONFIG_CATEGORY
    -- ##
    create table CWMS_CONFIG_CATEGORY (
       category_id varchar2(16),
       description varchar2(48),
       constraint CWMS_CONFIG_CATEGORY_pk primary key (category_id),
       constraint CWMS_CONFIG_CATEGORY_ck check (category_id = upper(trim(category_id)))
    ) organization index
    /

    ---------------------------
    -- CWMS_CONFIG_CATEGORY comments --
    --
    comment on table  CWMS_CONFIG_CATEGORY is 'Holds categories of configurations';
    comment on column CWMS_CONFIG_CATEGORY.category_id is 'The category identifier';
    comment on column CWMS_CONFIG_CATEGORY.description is 'The category description';



    -- ## TABLE ###############################################
    -- ## AT_CONFIGURATION
    -- ##
    create table AT_CONFIGURATION (
       configuration_code number(14),
       parent_code        number(14),
       office_code        number(14)    not null,
       category_id        varchar2(16),
       configuration_id   varchar2(32)  not null,
       configuration_name varchar2(128) not null,
       constraint AT_CONFIGURATION_pk  primary key (configuration_code),
       constraint AT_CONFIGURATION_fk1 foreign key (parent_code) references AT_CONFIGURATION (configuration_code),
       constraint AT_CONFIGURATION_fk2 foreign key (category_id) references cwms_config_category (category_id),
       constraint AT_CONFIGURATION_fk3 foreign key (office_code) references cwms_office (office_code),
       constraint AT_CONFIGURATION_ck1 check (trim(configuration_id) = configuration_id),
       constraint AT_CONFIGURATION_ck2 check (trim(configuration_name) = configuration_name)
    ) organization index
    /

    ---------------------------
    -- AT_CONFIGURATION indexes --
    --
    create unique index AT_CONFIGURATION_idx_id on AT_CONFIGURATION (office_code, upper(configuration_id));

    ---------------------------
    -- AT_CONFIGURATION comments --
    --
    comment on table  AT_CONFIGURATION is 'Holds configurations referenced by other objects';
    comment on column AT_CONFIGURATION.configuration_code is 'Unique numeric code that identifies the configuration in the database';
    comment on column AT_CONFIGURATION.parent_code        is 'Configuration code of parent configuration, if applicable';
    comment on column AT_CONFIGURATION.office_code        is 'Numeric code that identifies the office that owns this configuration in the database';
    comment on column AT_CONFIGURATION.category_id        is 'Category describing the type of configuration';
    comment on column AT_CONFIGURATION.configuration_id   is 'The character identifier of the configuration';
    comment on column AT_CONFIGURATION.configuration_name is 'The name of the configuration';



    create table CWMS_GATE_TYPE (
       gate_type_code number(14),
       gate_type_id   varchar2(32) not null,
       description    varchar2(128),
       constraint CWMS_GATE_TYPE_pk  primary key (gate_type_code) using index,
       constraint CWMS_GATE_TYPE_ck1 check (upper(trim(gate_type_id)) = gate_type_id),
       constraint CWMS_GATE_TYPE_u01 unique (gate_type_id) using index
    ) tablespace cwms_20data;

    comment on table  CWMS_GATE_TYPE  is 'Holds reference types for gates';
    comment on column CWMS_GATE_TYPE.gate_type_code is 'Unique numeric code identfying the gate type';
    comment on column CWMS_GATE_TYPE.gate_type_id   is 'The name of the gate type';
    comment on column CWMS_GATE_TYPE.description    is 'A description of the gate type';



    create table CWMS_VLOC_LVL_CONSTITUENT_TYPE (
       constituent_type varchar2(16) primary key,
       constraint cwms_vloc_lvl_const_type_ck check (constituent_type in ('LOCATION_LEVEL','RATING','TIME_SERIES','FORMULA'))
    );
    comment on table CWMS_VLOC_LVL_CONSTITUENT_TYPE is 'Holds valid constiuent types for virtual location levels';
    comment on column CWMS_VLOC_LVL_CONSTITUENT_TYPE.constituent_type is 'The valid constituent types';







INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	VALUES (0, 'UNK', 'Corps of Engineers Office Unknown', 0, 0, '00', 'UNK');
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	VALUES (1, 'HQ', 'Headquarters, U.S. Army Corps of Engineers', 1, 1, 'S0', 'HQ');
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 2, 'LRD', 'Great Lakes and Ohio River Division', OFFICE_CODE, 2, 'H0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 3, 'LRDG', 'Great Lakes Region', OFFICE_CODE, 3, 'H8', 'MSCR' FROM CWMS_OFFICE WHERE OFFICE_ID='LRD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 4, 'LRC', 'Chicago District', OFFICE_CODE, 4, 'H6', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDG';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 5, 'LRE', 'Detroit District', OFFICE_CODE, 5, 'H7', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDG';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 6, 'LRB', 'Buffalo District', OFFICE_CODE, 6, 'H5', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDG';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 7, 'LRDO', 'Ohio River Region', OFFICE_CODE, 7, 'H0', 'MSCR' FROM CWMS_OFFICE WHERE OFFICE_ID='LRD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 8, 'LRH', 'Huntington District', OFFICE_CODE, 8, 'H1', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDO';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 9, 'LRL', 'Louisville District', OFFICE_CODE, 9, 'H2', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDO';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 10, 'LRN', 'Nashville District', OFFICE_CODE, 10, 'H3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDO';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 11, 'LRP', 'Pittsburgh District', OFFICE_CODE, 11, 'H4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='LRDO';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 12, 'MVD', 'Mississippi Valley Division', OFFICE_CODE, 12, 'B0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 13, 'MVK', 'Vicksburg District', OFFICE_CODE, 13, 'B4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='MVD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 14, 'MVM', 'Memphis District', OFFICE_CODE, 14, 'B1', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='MVD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 15, 'MVN', 'New Orleans District', OFFICE_CODE, 15, 'B2', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='MVD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 16, 'MVP', 'St. Paul District', OFFICE_CODE, 16, 'B6', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='MVD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 17, 'MVR', 'Rock Island District', OFFICE_CODE, 17, 'B5', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='MVD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 18, 'MVS', 'St. Louis District', OFFICE_CODE, 18, 'B3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='MVD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 19, 'NAD', 'North Atlantic Division', OFFICE_CODE, 19, 'E0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 20, 'NAB', 'Baltimore District', OFFICE_CODE, 20, 'E1', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 21, 'NAE', 'New England District', OFFICE_CODE, 21, 'E6', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 22, 'NAN', 'New York District', OFFICE_CODE, 22, 'E3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 23, 'NAO', 'Norfolk District', OFFICE_CODE, 23, 'E4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 24, 'NAP', 'Philadelphia District', OFFICE_CODE, 24, 'E5', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 25, 'NWD', 'Northwestern Division', OFFICE_CODE, 25, 'G0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 26, 'NWDP', 'Pacific Northwest Region', OFFICE_CODE, 26, 'G0', 'MSCR' FROM CWMS_OFFICE WHERE OFFICE_ID='NWD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 27, 'NWP', 'Portland District', OFFICE_CODE, 27, 'G2', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NWDP';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 28, 'NWS', 'Seattle District', OFFICE_CODE, 28, 'G3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NWDP';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 29, 'NWW', 'Walla Walla District', OFFICE_CODE, 29, 'G4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NWDP';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 30, 'NWDM', 'Missouri River Region', OFFICE_CODE, 30, 'G7', 'MSCR' FROM CWMS_OFFICE WHERE OFFICE_ID='NWD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 31, 'NWK', 'Kansas City District', OFFICE_CODE, 31, 'G5', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NWDM';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 32, 'NWO', 'Omaha District', OFFICE_CODE, 32, 'G6', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='NWDM';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 33, 'POD', 'Pacific Ocean Division', OFFICE_CODE, 33, 'J0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 34, 'POA', 'Alaska District', OFFICE_CODE, 34, 'J4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='POD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 35, 'POH', 'Hawaii District', OFFICE_CODE, 35, 'J3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='POD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 36, 'SAD', 'South Atlantic Division', OFFICE_CODE, 36, 'K0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 37, 'SAC', 'Charleston District', OFFICE_CODE, 37, 'K2', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 38, 'SAJ', 'Jacksonville District', OFFICE_CODE, 38, 'K3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 39, 'SAM', 'Mobile District', OFFICE_CODE, 39, 'K5', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 40, 'SAS', 'Savannah District', OFFICE_CODE, 40, 'K6', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 41, 'SAW', 'Wilmington District', OFFICE_CODE, 41, 'K7', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SAD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 42, 'SPD', 'South Pacific Division', OFFICE_CODE, 42, 'L0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 43, 'SPA', 'Albuquerque District', OFFICE_CODE, 43, 'L4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SPD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 44, 'SPK', 'Sacramento District', OFFICE_CODE, 44, 'L2', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SPD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 45, 'SPL', 'Los Angeles District', OFFICE_CODE, 45, 'L1', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SPD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 46, 'SPN', 'San Francisco District', OFFICE_CODE, 46, 'L3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SPD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 47, 'SWD', 'Southwestern Division', OFFICE_CODE, 47, 'M0', 'MSC' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 48, 'SWF', 'Fort Worth District', OFFICE_CODE, 48, 'M2', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SWD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 49, 'SWG', 'Galveston District', OFFICE_CODE, 49, 'M3', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SWD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 50, 'SWL', 'Little Rock District', OFFICE_CODE, 50, 'M4', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SWD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 51, 'SWT', 'Tulsa District', OFFICE_CODE, 51, 'M5', 'DIS' FROM CWMS_OFFICE WHERE OFFICE_ID='SWD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	VALUES (52, 'LCRA', 'Lower Colorado River Authority', 52, 52, 'Z0', 'UNK');
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	VALUES (53, 'CWMS', 'All CWMS Offices', 53, 53, 'X0', 'UNK');
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 54, 'ERD', 'Engineer Research and Development Center', OFFICE_CODE, 54, 'U0', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 55, 'CRREL', 'Cold Regions Research and Engineering Lab', OFFICE_CODE, 55, 'U4', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 56, 'CHL', 'Coastal and Hydraulics Laboratory', OFFICE_CODE, 56, 'U1', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 57, 'CERL', 'Construction Engineering Research Laboratory', OFFICE_CODE, 57, 'U2', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 58, 'EL', 'Environmental Laboratory', OFFICE_CODE, 58, 'U3', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 59, 'GSL', 'Geotechnical and Structures Laboratory', OFFICE_CODE, 59, 'U5', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 60, 'ITL', 'Information Technology Laboratory', OFFICE_CODE, 60, 'U6', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 61, 'TEC', 'Topographic Engineering Center', OFFICE_CODE, 61, 'U7', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='ERD';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 62, 'IWR', 'Institute for Water Resources', OFFICE_CODE, 62, 'Q1', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='HQ';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 63, 'NDC', 'Navigation Data Center', OFFICE_CODE, 63, 'Q2', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='IWR';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 64, 'HEC', 'Hydrologic Engineering Cennter', OFFICE_CODE, 64, 'Q0', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='IWR';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	SELECT 65, 'WCSC', 'Waterborne Commerce Statistics Center', OFFICE_CODE, 65, 'Q3', 'FOA' FROM CWMS_OFFICE WHERE OFFICE_ID='IWR';
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	VALUES (66, 'CPC', 'Central Processing Center', 66, 66, 'X1', 'UNK');
INSERT INTO CWMS_OFFICE (OFFICE_CODE, OFFICE_ID, LONG_NAME, REPORT_TO_OFFICE_CODE, DB_HOST_OFFICE_CODE, EROC, OFFICE_TYPE)
	VALUES (67, 'WPC', 'Western Processing Center', 67, 67, 'X2', 'UNK');
UPDATE CWMS_OFFICE SET DB_HOST_OFFICE_CODE=
	(SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID='NWDP')
	WHERE OFFICE_ID IN ('NWD', 'NWD', 'NWP', 'NWS', 'NWW');

INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20001, 'TS_ID_NOT_FOUND', 'The timeseries identifier "%1" was not found for office "%2"');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20002, 'TS_IS_INVALID', 'The timeseries identifier "%1" is not valid %2');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20003, 'TS_ALREADY_EXISTS', 'The timeseries identifier "%1" is already in use');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20004, 'INVALID_INTERVAL_ID', '"%1" is not a valid CWMS timeseries interval');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20005, 'INVALID_DURATION_ID', '"%1" is not a valid CWMS timeseries Duration');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20006, 'INVALID_PARAM_ID', '"%1" is not a valid CWMS timeseries Parameter');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20007, 'INVALID_PARAM_TYPE', '"%1" is not a valid CWMS timeseries Parameter Type');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20010, 'INVALID_OFFICE_ID', '"%1" is not a valid CWMS office id');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20011, 'INVALID_STORE_RULE', '"%1" is not a recognized Store Rule');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20012, 'INVALID_DELETE_ACTION', '"%1" is not a recognized Delete Action');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20013, 'INVALID_UTC_OFFSET', 'The UTC Offset: "%1" is not valid for a "%2" Interval value');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20014, 'TS_ID_NOT_CREATED', 'Unable to create TS ID: "%1"');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20015, 'XCHG_TS_ERROR', 'Time series "%1" cannot be configured for realtime exchange in set "%2" in the opposite direction from its configuration in set "%3".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20016, 'XCHG_RATING_ERROR', 'Rating series "%1" cannot be configured for realtime exchange in set "%2" in the opposite direction from its configuration in set "%3".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20017, 'XCHG_TIME_VALUE', 'Error converting "%1" to timestamp. Required format is "%2".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20018, 'XCHG_NO_DATA', 'Table "%1" has no data for code "%2" at time "%3".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20019, 'INVALID_ITEM', '"%1" is not a valid %2.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20020, 'ITEM_ALREADY_EXISTS', '"%1" "%2" already exists.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20021, 'ITEM_NOT_CREATED', 'Unable to create %1 "%2".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20022, 'STATE_CANNOT_BE_NULL', '"%1"-The State/Provence must be specified when specifying a County/Region.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20023, 'INVALID_T_F_FLAG', '"%1" - Must be either T or F.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20024, 'INVALID_T_F_FLAG_OLD', '"%1" - Must be either 1 for True or 0 for False.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20025, 'LOCATION_ID_NOT_FOUND', 'The Location: "%1" does not exist.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20026, 'LOCATION_ID_ALREADY_EXISTS', '"%1"-The Location: "%2" already exists.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20027, 'INVLAID_FULL_ID', '"%1" is not a valid Location or Parameter id.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20028, 'RENAME_LOC_BASE_1', 'Unable to rename. An old Base Location: "%1" can not be renamed to a non-Base Location: "%2".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20029, 'RENAME_LOC_BASE_2', 'Unable to rename. The new Location: "%1" already exists.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20030, 'RENAME_LOC_BASE_3', 'Unable to rename. The new Location: "%1" matches the existing old location.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20031, 'CAN_NOT_DELETE_LOC_1', 'Can not delete location: "%1" because Timeseries Identifiers exist.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20032, 'CANNOT_DELETE_UNIT_1', 'Cannot delete or rename unit alias "%1"; it is in use by %2.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20033, 'DUPLICATE_XCHG_MAP', 'Mapping of "%1" to "%2 already exists in exchage set "%3", but with different parameters.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20034, 'ITEM_DOES_NOT_EXIST', '%1 "%2" does not exist.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20035, 'DATA_STREAM_NOT_FOUND', 'The "%1" data stream was not found');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20036, 'PARAM_CANNOT_BE_NULL ', 'The "%1" parameter cannot be "NULL".');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20037, 'CANNOT_RENAME_1', 'Unable to rename. An old id of: "%1" was not found.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20038, 'CANNOT_RENAME_2', 'Unable to rename. The new id: "%1" already exists.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20039, 'CANNOT_RENAME_3', 'Unable to rename. The new id: "%1" matches the old.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20040, 'CANNOT_DELETE_DATA_STREAM', 'Cannot delete data stream: "%". It still has SHEF specs assigned to it.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20041, 'INVALID_FULL_ID', '"%1" is an invalid id.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20042, 'CANNOT_CHANGE_OFFSET', 'Cannot change interval utc offset of time series with stored data: "%1"');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20043, 'INVALID_SNAP_WINDOW', 'Snap Window can not be greater than the cwms_ts_id Interval');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20044, 'SHEF_DUP_TS_ID', 'CWMS_TS_ID "%1" has already been used.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20045, 'ITEM_OWNED_BY_CWMS', 'The %1: "%2" is owned by the system and cannot be changed or deleted.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20046, 'NO_CRIT_FILE_FOUND', 'A crit file for the %1 datastream was not found.');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20047, 'SESSION_OFFICE_ID_NOT_SET', 'Session office id is not set by the application');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20048, 'NO_WRITE_PRIVILEGE', 'User doesnt have write privileges');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20049, 'NO SUCH APPLICATION INSTANCE', 'No application instance is associated with the specified UUID');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20050, 'APPLICATION INSTANCE LOGGED OUT', 'The application instance associated with the specified UUID has logged out');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20102, 'UNIT_CONV_NOT_FOUND', 'The units conversion for "%1" was not found');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20103, 'INVALID_TIME_ZONE', 'The time zone "%1" is not a valid Oracle time zone region');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20104, 'UNITS_NOT_SPECIFIED', 'You must specifiy the UNITS of your data');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20234, 'ITEMS_ARE_IDENTICAL', '%1');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20244, 'NULL_ARGUMENT', 'Argument %1 is not allowed to be null');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20254, 'ARRAY_LENGTHS_DIFFER', '%1 arrays must have identical lengths');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20255, 'DUPLICATE_EDIPI', 'Two different users have the same EDIPI %1');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20997, 'GENERIC_ERROR', '%1');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20998, 'ERROR', '%1');
INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20999, 'UNKNOWN_EXCEPTION', 'The requested exception is not in the CWMS_ERROR table: "%1"');


INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (0, 'Unknown or Not Applicable', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (1, 'Africa/Algiers', '+00 01:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (2, 'Africa/Cairo', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (3, 'Africa/Casablanca', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (4, 'Africa/Ceuta', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (5, 'Africa/Djibouti', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (6, 'Africa/Freetown', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (7, 'Africa/Johannesburg', '+00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (8, 'Africa/Khartoum', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (9, 'Africa/Mogadishu', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (10, 'Africa/Nairobi', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (11, 'Africa/Nouakchott', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (12, 'Africa/Tripoli', '+00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (13, 'Africa/Tunis', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (14, 'Africa/Windhoek', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (15, 'America/Adak', '-00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (16, 'America/Anchorage', '-00 09:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (17, 'America/Anguilla', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (18, 'America/Araguaina', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (20, 'America/Aruba', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (21, 'America/Asuncion', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (22, 'America/Atka', '-00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (23, 'America/Belem', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (24, 'America/Boa_Vista', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (25, 'America/Bogota', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (26, 'America/Boise', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (27, 'America/Buenos_Aires', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (28, 'America/Cambridge_Bay', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (29, 'America/Cancun', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (30, 'America/Caracas', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (31, 'America/Cayenne', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (32, 'America/Cayman', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (33, 'America/Chicago', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (34, 'America/Chihuahua', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (35, 'America/Costa_Rica', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (36, 'America/Cuiaba', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (37, 'America/Curacao', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (38, 'America/Dawson', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (39, 'America/Dawson_Creek', '-00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (40, 'America/Denver', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (41, 'America/Detroit', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (42, 'America/Edmonton', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (43, 'America/El_Salvador', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (44, 'America/Ensenada', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (45, 'America/Fort_Wayne', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (46, 'America/Fortaleza', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (47, 'America/Godthab', '-00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (48, 'America/Goose_Bay', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (49, 'America/Grand_Turk', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (50, 'America/Guadeloupe', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (51, 'America/Guatemala', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (52, 'America/Guayaquil', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (53, 'America/Halifax', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (54, 'America/Havana', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (55, 'America/Hermosillo', '-00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (56, 'America/Indiana/Indianapolis', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (57, 'America/Indiana/Knox', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (58, 'America/Indiana/Marengo', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (59, 'America/Indiana/Petersburg', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (60, 'America/Indiana/Vevay', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (61, 'America/Indiana/Vincennes', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (62, 'America/Indianapolis', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (63, 'America/Inuvik', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (64, 'America/Iqaluit', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (65, 'America/Jamaica', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (66, 'America/Juneau', '-00 09:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (67, 'America/Kentucky/Louisville', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (68, 'America/Knox_IN', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (69, 'America/La_Paz', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (70, 'America/Lima', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (71, 'America/Los_Angeles', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (72, 'America/Louisville', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (73, 'America/Maceio', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (74, 'America/Managua', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (75, 'America/Manaus', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (76, 'America/Martinique', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (77, 'America/Mazatlan', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (78, 'America/Mexico_City', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (79, 'America/Miquelon', '-00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (80, 'America/Montevideo', '-00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (81, 'America/Montreal', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (82, 'America/Montserrat', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (83, 'America/New_York', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (84, 'America/Nome', '-00 09:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (85, 'America/Noronha', '-00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (86, 'America/Panama', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (87, 'America/Phoenix', '-00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (88, 'America/Porto_Acre', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (89, 'America/Porto_Velho', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (90, 'America/Puerto_Rico', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (91, 'America/Rankin_Inlet', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (92, 'America/Regina', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (93, 'America/Rio_Branco', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (94, 'America/Santiago', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (95, 'America/Sao_Paulo', '-00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (96, 'America/Scoresbysund', '-00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (97, 'America/Shiprock', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (98, 'America/St_Johns', '-00 03:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (99, 'America/St_Thomas', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (100, 'America/Swift_Current', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (101, 'America/Tegucigalpa', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (102, 'America/Thule', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (103, 'America/Thunder_Bay', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (104, 'America/Tijuana', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (105, 'America/Tortola', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (106, 'America/Vancouver', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (107, 'America/Virgin', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (108, 'America/Whitehorse', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (109, 'America/Winnipeg', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (110, 'America/Yellowknife', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (111, 'Arctic/Longyearbyen', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (112, 'Asia/Aden', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (113, 'Asia/Almaty', '+00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (114, 'Asia/Amman', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (115, 'Asia/Anadyr', '+00 12:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (116, 'Asia/Aqtau', '+00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (117, 'Asia/Aqtobe', '+00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (118, 'Asia/Baghdad', '+00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (119, 'Asia/Bahrain', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (120, 'Asia/Baku', '+00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (121, 'Asia/Bangkok', '+00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (122, 'Asia/Beirut', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (123, 'Asia/Bishkek', '+00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (124, 'Asia/Calcutta', '+00 05:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (125, 'Asia/Chongqing', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (126, 'Asia/Chungking', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (127, 'Asia/Dacca', '+00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (128, 'Asia/Damascus', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (129, 'Asia/Dhaka', '+00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (130, 'Asia/Dubai', '+00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (131, 'Asia/Gaza', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (132, 'Asia/Harbin', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (133, 'Asia/Hong_Kong', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (134, 'Asia/Irkutsk', '+00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (135, 'Asia/Istanbul', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (136, 'Asia/Jakarta', '+00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (137, 'Asia/Jayapura', '+00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (138, 'Asia/Jerusalem', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (139, 'Asia/Kabul', '+00 04:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (140, 'Asia/Kamchatka', '+00 12:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (141, 'Asia/Karachi', '+00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (142, 'Asia/Kashgar', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (143, 'Asia/Krasnoyarsk', '+00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (144, 'Asia/Kuala_Lumpur', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (145, 'Asia/Kuching', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (146, 'Asia/Kuwait', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (147, 'Asia/Macao', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (148, 'Asia/Macau', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (149, 'Asia/Magadan', '+00 11:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (150, 'Asia/Makassar', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (151, 'Asia/Manila', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (152, 'Asia/Muscat', '+00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (153, 'Asia/Nicosia', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (154, 'Asia/Novosibirsk', '+00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (155, 'Asia/Omsk', '+00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (156, 'Asia/Qatar', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (157, 'Asia/Rangoon', '+00 06:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (158, 'Asia/Riyadh', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (159, 'Asia/Saigon', '+00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (160, 'Asia/Seoul', '+00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (161, 'Asia/Shanghai', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (162, 'Asia/Singapore', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (163, 'Asia/Taipei', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (164, 'Asia/Tashkent', '+00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (165, 'Asia/Tbilisi', '+00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (166, 'Asia/Tehran', '+00 03:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (167, 'Asia/Tel_Aviv', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (168, 'Asia/Tokyo', '+00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (169, 'Asia/Ujung_Pandang', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (170, 'Asia/Urumqi', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (171, 'Asia/Vladivostok', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (172, 'Asia/Yakutsk', '+00 09:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (173, 'Asia/Yekaterinburg', '+00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (174, 'Asia/Yerevan', '+00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (175, 'Atlantic/Azores', '-00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (176, 'Atlantic/Bermuda', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (177, 'Atlantic/Canary', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (178, 'Atlantic/Faeroe', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (179, 'Atlantic/Jan_Mayen', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (180, 'Atlantic/Madeira', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (181, 'Atlantic/Reykjavik', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (182, 'Atlantic/St_Helena', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (183, 'Atlantic/Stanley', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (184, 'Australia/ACT', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (185, 'Australia/Adelaide', '+00 09:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (186, 'Australia/Brisbane', '+00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (187, 'Australia/Broken_Hill', '+00 09:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (188, 'Australia/Canberra', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (189, 'Australia/Darwin', '+00 09:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (190, 'Australia/Hobart', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (191, 'Australia/LHI', '+00 10:30:00.000000', '+00 00:30:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (192, 'Australia/Lindeman', '+00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (193, 'Australia/Lord_Howe', '+00 10:30:00.000000', '+00 00:30:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (194, 'Australia/Melbourne', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (195, 'Australia/NSW', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (196, 'Australia/North', '+00 09:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (197, 'Australia/Perth', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (198, 'Australia/Queensland', '+00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (199, 'Australia/South', '+00 09:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (200, 'Australia/Sydney', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (201, 'Australia/Tasmania', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (202, 'Australia/Victoria', '+00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (203, 'Australia/West', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (204, 'Australia/Yancowinna', '+00 09:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (205, 'Brazil/Acre', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (206, 'Brazil/DeNoronha', '-00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (207, 'Brazil/East', '-00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (208, 'Brazil/West', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (209, 'CET', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (211, 'CST6CDT', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (212, 'Canada/Atlantic', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (213, 'Canada/Central', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (214, 'Canada/East-Saskatchewan', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (215, 'Canada/Eastern', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (216, 'Canada/Mountain', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (217, 'Canada/Newfoundland', '-00 03:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (218, 'Canada/Pacific', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (219, 'Canada/Saskatchewan', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (220, 'Canada/Yukon', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (221, 'Chile/Continental', '-00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (222, 'Chile/EasterIsland', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (223, 'Cuba', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (224, 'EET', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (225, 'EST', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (226, 'EST5EDT', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (227, 'Egypt', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (228, 'Eire', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (229, 'Etc/GMT', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (230, 'Etc/GMT+0', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (231, 'Etc/GMT+1', '-00 01:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (232, 'Etc/GMT+10', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (233, 'Etc/GMT+11', '-00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (234, 'Etc/GMT+12', '-00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (235, 'Etc/GMT+2', '-00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (236, 'Etc/GMT+3', '-00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (237, 'Etc/GMT+4', '-00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (238, 'Etc/GMT+5', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (239, 'Etc/GMT+6', '-00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (240, 'Etc/GMT+7', '-00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (241, 'Etc/GMT+8', '-00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (242, 'Etc/GMT+9', '-00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (243, 'Etc/GMT-0', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (244, 'Etc/GMT-1', '+00 01:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (245, 'Etc/GMT-10', '+00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (246, 'Etc/GMT-11', '+00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (247, 'Etc/GMT-12', '+00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (248, 'Etc/GMT-13', '+00 13:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (249, 'Etc/GMT-14', '+00 14:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (250, 'Etc/GMT-2', '+00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (251, 'Etc/GMT-3', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (252, 'Etc/GMT-4', '+00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (253, 'Etc/GMT-5', '+00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (254, 'Etc/GMT-6', '+00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (255, 'Etc/GMT-7', '+00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (256, 'Etc/GMT-8', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (257, 'Etc/GMT-9', '+00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (258, 'Etc/GMT0', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (259, 'Etc/Greenwich', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (260, 'Europe/Amsterdam', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (261, 'Europe/Athens', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (262, 'Europe/Belfast', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (263, 'Europe/Belgrade', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (264, 'Europe/Berlin', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (265, 'Europe/Bratislava', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (266, 'Europe/Brussels', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (267, 'Europe/Bucharest', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (268, 'Europe/Budapest', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (269, 'Europe/Copenhagen', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (270, 'Europe/Dublin', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (271, 'Europe/Gibraltar', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (272, 'Europe/Guernsey', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (273, 'Europe/Helsinki', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (274, 'Europe/Isle_of_Man', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (275, 'Europe/Istanbul', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (276, 'Europe/Jersey', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (277, 'Europe/Kaliningrad', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (278, 'Europe/Kiev', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (279, 'Europe/Lisbon', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (280, 'Europe/Ljubljana', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (281, 'Europe/London', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (282, 'Europe/Luxembourg', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (283, 'Europe/Madrid', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (284, 'Europe/Mariehamn', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (285, 'Europe/Minsk', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (286, 'Europe/Monaco', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (287, 'Europe/Moscow', '+00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (288, 'Europe/Nicosia', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (289, 'Europe/Oslo', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (290, 'Europe/Paris', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (291, 'Europe/Podgorica', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (292, 'Europe/Prague', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (293, 'Europe/Riga', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (294, 'Europe/Rome', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (295, 'Europe/Samara', '+00 04:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (296, 'Europe/San_Marino', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (297, 'Europe/Sarajevo', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (298, 'Europe/Simferopol', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (299, 'Europe/Skopje', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (300, 'Europe/Sofia', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (301, 'Europe/Stockholm', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (302, 'Europe/Tallinn', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (303, 'Europe/Tirane', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (304, 'Europe/Uzhgorod', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (305, 'Europe/Vatican', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (306, 'Europe/Vienna', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (307, 'Europe/Vilnius', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (308, 'Europe/Volgograd', '+00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (309, 'Europe/Warsaw', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (310, 'Europe/Zagreb', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (311, 'Europe/Zaporozhye', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (312, 'Europe/Zurich', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (313, 'GB', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (314, 'GB-Eire', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (315, 'GMT', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (316, 'GMT+0', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (317, 'GMT-0', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (318, 'GMT0', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (319, 'Greenwich', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (320, 'HST', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (321, 'Hongkong', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (322, 'Iceland', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (323, 'Indian/Chagos', '+00 06:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (324, 'Indian/Christmas', '+00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (325, 'Indian/Cocos', '+00 06:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (326, 'Indian/Mayotte', '+00 03:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (327, 'Indian/Reunion', '+00 04:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (328, 'Iran', '+00 03:30:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (329, 'Israel', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (330, 'Jamaica', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (331, 'Japan', '+00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (332, 'Kwajalein', '+00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (333, 'Libya', '+00 02:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (334, 'MET', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (335, 'MST', '-00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (336, 'MST7MDT', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (337, 'Mexico/BajaNorte', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (338, 'Mexico/BajaSur', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (339, 'Mexico/General', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (340, 'NZ', '+00 12:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (341, 'NZ-CHAT', '+00 12:45:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (342, 'Navajo', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (343, 'PRC', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (345, 'PST8PDT', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (346, 'Pacific/Auckland', '+00 12:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (347, 'Pacific/Chatham', '+00 12:45:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (348, 'Pacific/Easter', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (349, 'Pacific/Fakaofo', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (350, 'Pacific/Fiji', '+00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (351, 'Pacific/Gambier', '-00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (352, 'Pacific/Guam', '+00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (353, 'Pacific/Honolulu', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (354, 'Pacific/Johnston', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (355, 'Pacific/Kiritimati', '+00 14:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (356, 'Pacific/Kwajalein', '+00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (357, 'Pacific/Marquesas', '-00 09:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (358, 'Pacific/Midway', '-00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (359, 'Pacific/Niue', '-00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (360, 'Pacific/Norfolk', '+00 11:30:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (361, 'Pacific/Noumea', '+00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (362, 'Pacific/Pago_Pago', '-00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (363, 'Pacific/Pitcairn', '-00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (364, 'Pacific/Rarotonga', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (365, 'Pacific/Saipan', '+00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (366, 'Pacific/Samoa', '-00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (367, 'Pacific/Tahiti', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (368, 'Pacific/Tongatapu', '+00 13:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (369, 'Pacific/Wake', '+00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (370, 'Pacific/Wallis', '+00 12:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (371, 'Poland', '+00 01:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (372, 'Portugal', '+00 00:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (373, 'ROC', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (374, 'ROK', '+00 09:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (375, 'Singapore', '+00 08:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (376, 'Turkey', '+00 02:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (377, 'US/Alaska', '-00 09:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (378, 'US/Aleutian', '-00 10:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (379, 'US/Arizona', '-00 07:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (380, 'US/Central', '-00 06:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (381, 'US/East-Indiana', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (382, 'US/Eastern', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (383, 'US/Hawaii', '-00 10:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (384, 'US/Indiana-Starke', '-00 05:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (385, 'US/Michigan', '-00 05:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (386, 'US/Mountain', '-00 07:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (387, 'US/Pacific', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (388, 'US/Pacific-New', '-00 08:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (389, 'US/Samoa', '-00 11:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (390, 'UTC', '+00 00:00:00.000000', '+00 00:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (391, 'W-SU', '+00 03:00:00.000000', '+00 01:00:00.000000');
INSERT INTO CWMS_TIME_ZONE (TIME_ZONE_CODE,TIME_ZONE_NAME,UTC_OFFSET,DST_OFFSET) VALUES (392, 'WET', '+00 00:00:00.000000', '+00 01:00:00.000000');

INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('CST', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('PST', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('EDT', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('CDT', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('MDT', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('PDT', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-00:00', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0:00', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0000', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-000', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+00:00', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0:00', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0000', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+000', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-01:00', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-1:00', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0100', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-100', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+01:00', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+1:00', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0100', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+100', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-02:00', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-2:00', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0200', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-200', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+02:00', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+2:00', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0200', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+200', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-03:00', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-3:00', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0300', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-300', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+03:00', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+3:00', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0300', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+300', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-04:00', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-4:00', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0400', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-400', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+04:00', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+4:00', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0400', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+400', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-05:00', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-5:00', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0500', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-500', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+05:00', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+5:00', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0500', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+500', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-06:00', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-6:00', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0600', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-600', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+06:00', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+6:00', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0600', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+600', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-07:00', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-7:00', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0700', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-700', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+07:00', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+7:00', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0700', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+700', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-08:00', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-8:00', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0800', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-800', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+08:00', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+8:00', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0800', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+800', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-09:00', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-9:00', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-0900', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-900', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+09:00', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+9:00', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+0900', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+900', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-10:00', 'Etc/GMT+10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-1000', 'Etc/GMT+10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+10:00', 'Etc/GMT-10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+1000', 'Etc/GMT-10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-11:00', 'Etc/GMT+11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-1100', 'Etc/GMT+11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+11:00', 'Etc/GMT-11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+1100', 'Etc/GMT-11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-12:00', 'Etc/GMT+12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT-1200', 'Etc/GMT+12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+12:00', 'Etc/GMT-12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('GMT+1200', 'Etc/GMT-12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-00:00', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0:00', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0000', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-000', 'Etc/GMT+0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+00:00', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0:00', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0000', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+000', 'Etc/GMT-0');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-01:00', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-1:00', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0100', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-100', 'Etc/GMT+1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+01:00', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+1:00', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0100', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+100', 'Etc/GMT-1');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-02:00', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-2:00', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0200', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-200', 'Etc/GMT+2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+02:00', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+2:00', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0200', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+200', 'Etc/GMT-2');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-03:00', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-3:00', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0300', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-300', 'Etc/GMT+3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+03:00', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+3:00', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0300', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+300', 'Etc/GMT-3');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-04:00', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-4:00', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0400', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-400', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+04:00', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+4:00', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0400', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+400', 'Etc/GMT-4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-05:00', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-5:00', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0500', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-500', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+05:00', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+5:00', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0500', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+500', 'Etc/GMT-5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-06:00', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-6:00', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0600', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-600', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+06:00', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+6:00', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0600', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+600', 'Etc/GMT-6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-07:00', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-7:00', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0700', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-700', 'Etc/GMT+7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+07:00', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+7:00', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0700', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+700', 'Etc/GMT-7');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-08:00', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-8:00', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0800', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-800', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+08:00', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+8:00', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0800', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+800', 'Etc/GMT-8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-09:00', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-9:00', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-0900', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-900', 'Etc/GMT+9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+09:00', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+9:00', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+0900', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+900', 'Etc/GMT-9');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-10:00', 'Etc/GMT+10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-1000', 'Etc/GMT+10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+10:00', 'Etc/GMT-10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+1000', 'Etc/GMT-10');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-11:00', 'Etc/GMT+11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-1100', 'Etc/GMT+11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+11:00', 'Etc/GMT-11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+1100', 'Etc/GMT-11');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-12:00', 'Etc/GMT+12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC-1200', 'Etc/GMT+12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+12:00', 'Etc/GMT-12');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('UTC+1200', 'Etc/GMT-12');


INSERT INTO CWMS_TZ_USAGE (TZ_USAGE_CODE, TZ_USAGE_ID, DESCRIPTION) VALUES (
	1,
	'Standard',
	'Use constant offset for zone standard time'
);
INSERT INTO CWMS_TZ_USAGE (TZ_USAGE_CODE, TZ_USAGE_ID, DESCRIPTION) VALUES (
	2,
	'Daylight',
	'Use constant offset for zone daylight savings time'
);
INSERT INTO CWMS_TZ_USAGE (TZ_USAGE_CODE, TZ_USAGE_ID, DESCRIPTION) VALUES (
	3,
	'Local',
	'Use varying offset for zone local time'
);

INSERT INTO CWMS_DATA_Q_SCREENED VALUES('UNSCREENED', 'The value has not been screened');
INSERT INTO CWMS_DATA_Q_SCREENED VALUES('SCREENED', 'The value has been screened');


INSERT INTO CWMS_DATA_Q_VALIDITY VALUES('UNKNOWN', 'The validity of the value has not been assessed');
INSERT INTO CWMS_DATA_Q_VALIDITY VALUES('OKAY', 'The value is accepted as valid');
INSERT INTO CWMS_DATA_Q_VALIDITY VALUES('MISSING', 'The value has not been reported or computed');
INSERT INTO CWMS_DATA_Q_VALIDITY VALUES('QUESTIONABLE', 'The validity of the value doubtful');
INSERT INTO CWMS_DATA_Q_VALIDITY VALUES('REJECTED', 'The value is rejected as invalid');


INSERT INTO CWMS_DATA_Q_RANGE VALUES('NO_RANGE', 'The value is not greater than the 1st range limit or limits were not tested');
INSERT INTO CWMS_DATA_Q_RANGE VALUES('RANGE_1', 'The value is greater than the 1st, but not the 2nd range limit');
INSERT INTO CWMS_DATA_Q_RANGE VALUES('RANGE_2', 'The value is greater than the 2nd, but not the 3rd range limit');
INSERT INTO CWMS_DATA_Q_RANGE VALUES('RANGE_3', 'The value is greater than the 3rd range limit');


INSERT INTO CWMS_DATA_Q_CHANGED VALUES('ORIGINAL', 'The value has not been changed from the original report or computation');
INSERT INTO CWMS_DATA_Q_CHANGED VALUES('MODIFIED', 'The value has been changed from the original report or computation');


INSERT INTO CWMS_DATA_Q_REPL_CAUSE VALUES('NONE', 'The value was not replaced');
INSERT INTO CWMS_DATA_Q_REPL_CAUSE VALUES('AUTOMATIC', 'The value was automatically replaced by a pre-set software condition');
INSERT INTO CWMS_DATA_Q_REPL_CAUSE VALUES('INTERACTIVE', 'The value was interactively replaced using a software tool');
INSERT INTO CWMS_DATA_Q_REPL_CAUSE VALUES('MANUAL', 'The value was specified explicitly');
INSERT INTO CWMS_DATA_Q_REPL_CAUSE VALUES('RESTORED', 'The value was restored to the original report or computation');


INSERT INTO CWMS_DATA_Q_REPL_METHOD VALUES('NONE', 'The value was not replaced');
INSERT INTO CWMS_DATA_Q_REPL_METHOD VALUES('LIN_INTERP', 'The value was replaced by linear interpolation');
INSERT INTO CWMS_DATA_Q_REPL_METHOD VALUES('EXPLICIT', 'The value was replaced by manual change');
INSERT INTO CWMS_DATA_Q_REPL_METHOD VALUES('MISSING', 'The value was replaced with missing');
INSERT INTO CWMS_DATA_Q_REPL_METHOD VALUES('GRAPHICAL', 'The value was replaced graphically');


INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NONE', 'The value passed all specified tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE', 'The value failed an absolute magnitude test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE', 'The value failed a constant value test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE', 'The value failed a rate of change test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE', 'The value failed a relative magnitude test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE', 'The value failed a duration-magnitude test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT', 'The value failed a negative incremental value test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('SKIP_LIST', 'The value was specifically excluded from testing');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('USER_DEFINED', 'The value failed a user-defined test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DISTRIBUTION', 'The value failed a distribution test');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+SKIP_LIST', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+SKIP_LIST', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+SKIP_LIST', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+SKIP_LIST', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+SKIP_LIST', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+SKIP_LIST', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('SKIP_LIST+USER_DEFINED', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('SKIP_LIST+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('USER_DEFINED+DISTRIBUTION', 'The value failed 2 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+SKIP_LIST+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 3 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 4 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 5 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 6 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 7 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 8 tests');
INSERT INTO CWMS_DATA_Q_TEST_FAILED VALUES('ABSOLUTE_VALUE+CONSTANT_VALUE+RATE_OF_CHANGE+RELATIVE_VALUE+DURATION_VALUE+NEG_INCREMENT+SKIP_LIST+USER_DEFINED+DISTRIBUTION', 'The value failed 9 tests');


INSERT INTO CWMS_DATA_Q_PROTECTION VALUES('UNPROTECTED', 'The value is not protected');
INSERT INTO CWMS_DATA_Q_PROTECTION VALUES('PROTECTED', 'The value is protected');


INSERT INTO CWMS_RATING_METHOD VALUES (1, 'NULL', 'Return null if between values or outside range');
INSERT INTO CWMS_RATING_METHOD VALUES (2, 'ERROR', 'Raise an exception if between values or outside range');
INSERT INTO CWMS_RATING_METHOD VALUES (3, 'LINEAR', 'Linear interpolation or extrapolation of independent and dependent values');
INSERT INTO CWMS_RATING_METHOD VALUES (4, 'LOGARITHMIC', 'Logarithmic interpolation or extrapolation of independent and dependent values');
INSERT INTO CWMS_RATING_METHOD VALUES (5, 'LIN-LOG', 'Linear interpolation/extrapoloation of independent values, Logarithmic of dependent values');
INSERT INTO CWMS_RATING_METHOD VALUES (6, 'LOG-LIN', 'Logarithmic interpolation/extrapoloation of independent values, Linear of dependent values');
INSERT INTO CWMS_RATING_METHOD VALUES (7, 'PREVIOUS', 'Return the value that is lower in position');
INSERT INTO CWMS_RATING_METHOD VALUES (8, 'NEXT', 'Return the value that is higher in position');
INSERT INTO CWMS_RATING_METHOD VALUES (9, 'NEAREST', 'Return the value that is nearest in position');
INSERT INTO CWMS_RATING_METHOD VALUES (10, 'LOWER', 'Return the value that is lower in magnitude');
INSERT INTO CWMS_RATING_METHOD VALUES (11, 'HIGHER', 'Return the value that is higher in magnitude');
INSERT INTO CWMS_RATING_METHOD VALUES (12, 'CLOSEST', 'Return the value that is closest in magnitude');


INSERT INTO CWMS_DSS_XCHG_DIRECTION (DSS_XCHG_DIRECTION_CODE, DSS_XCHG_DIRECTION_ID, DESCRIPTION) VALUES (
	1,
	'DssToOracle',
	'Direction is incoming to database (post)'
);
INSERT INTO CWMS_DSS_XCHG_DIRECTION (DSS_XCHG_DIRECTION_CODE, DSS_XCHG_DIRECTION_ID, DESCRIPTION) VALUES (
	2,
	'OracleToDss',
	'Direction is outgoing from database (extract)'
);

INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (1, 'AcknowledgeAlarm');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (2, 'AcknowledgeRequest');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (3, 'Alarm');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (4, 'ControlMessage');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (5, 'DeactivateAlarm');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (6, 'Exception Thrown');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (7, 'Fatal Error');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (8, 'Initialization Error');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (9, 'Initiated');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (10, 'Load Library Error');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (11, 'MissedHeartBeat');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (12, 'PreventAlarm');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (13, 'RequestAction');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (14, 'ResetAlarm');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (15, 'Runtime Exec Error');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (16, 'Shutting Down');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (17, 'State');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (18, 'Status');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (19, 'StatusIntervalMinutes');
INSERT INTO CWMS_LOG_MESSAGE_TYPES VALUES (20, 'Terminated');


INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (1, 'boolean');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (2, 'byte');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (3, 'short');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (4, 'int');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (5, 'long');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (6, 'float');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (7, 'double');
INSERT INTO CWMS_LOG_MESSAGE_PROP_TYPES VALUES (8, 'String');


INSERT INTO CWMS_INTERPOLATE_UNITS VALUES (1, 'minutes');
INSERT INTO CWMS_INTERPOLATE_UNITS VALUES (2, 'intervals');


INSERT INTO CWMS_GAGE_METHOD VALUES (1, 'MANUAL', 'No communication method');
INSERT INTO CWMS_GAGE_METHOD VALUES (2, 'GOES', 'Gage communicates via GOES satellite');
INSERT INTO CWMS_GAGE_METHOD VALUES (3, 'LOS', 'Line-of-site radio');
INSERT INTO CWMS_GAGE_METHOD VALUES (4, 'METEORBURST', 'Gage communicates via meteorburst');
INSERT INTO CWMS_GAGE_METHOD VALUES (5, 'PHONE', 'Gage communicates via telephone');
INSERT INTO CWMS_GAGE_METHOD VALUES (6, 'INTERNET', 'Gage communicates via internet');
INSERT INTO CWMS_GAGE_METHOD VALUES (7, 'IRRIDIUM', 'Gage communicates via IRRIDIUM statellite');


INSERT INTO CWMS_GAGE_TYPE VALUES (1, 'GOES_T', 'F', NULL, (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='GOES'), 'GOES TX-only');
INSERT INTO CWMS_GAGE_TYPE VALUES (2, 'GOES_TI', 'F', (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='GOES'), (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='GOES'), 'GOES TX+INQ');
INSERT INTO CWMS_GAGE_TYPE VALUES (3, 'LOS_T', 'F', NULL, (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='LOS'), 'LOS TX-only');
INSERT INTO CWMS_GAGE_TYPE VALUES (4, 'LOS_TI', 'F', (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='LOS'), (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='LOS'), 'LOS TX+INQ');
INSERT INTO CWMS_GAGE_TYPE VALUES (5, 'INET_T', 'F', NULL, (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='INTERNET'), 'Internet TX-only');
INSERT INTO CWMS_GAGE_TYPE VALUES (6, 'INET_TI', 'F', (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='INTERNET'), (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='INTERNET'), 'Internet TX+INQ');
INSERT INTO CWMS_GAGE_TYPE VALUES (7, 'IRRID_T', 'F', NULL, (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='IRRIDIUM'), 'Irridium TX-only');
INSERT INTO CWMS_GAGE_TYPE VALUES (8, 'IRRID_TI', 'F', (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='INTERNET'), (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='IRRIDIUM'), 'Irridium TX+INQ');
INSERT INTO CWMS_GAGE_TYPE VALUES (9, 'MET_T', 'F', NULL, (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='METEORBURST'), 'Meteorburst TX-only');
INSERT INTO CWMS_GAGE_TYPE VALUES (10, 'PHONE', 'F', (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='PHONE'), (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='PHONE'), 'Telephone INQ-only');
INSERT INTO CWMS_GAGE_TYPE VALUES (11, 'MANUAL', 'T', (SELECT METHOD_CODE FROM CWMS_GAGE_METHOD WHERE METHOD_ID='MANUAL'), NULL, 'Manually read');


INSERT INTO CWMS_NATION VALUES ('AF', 'AFGHANISTAN');
INSERT INTO CWMS_NATION VALUES ('AX', '�LAND ISLANDS');
INSERT INTO CWMS_NATION VALUES ('AL', 'ALBANIA');
INSERT INTO CWMS_NATION VALUES ('DZ', 'ALGERIA');
INSERT INTO CWMS_NATION VALUES ('AS', 'AMERICAN SAMOA');
INSERT INTO CWMS_NATION VALUES ('AD', 'ANDORRA');
INSERT INTO CWMS_NATION VALUES ('AO', 'ANGOLA');
INSERT INTO CWMS_NATION VALUES ('AI', 'ANGUILLA');
INSERT INTO CWMS_NATION VALUES ('AQ', 'ANTARCTICA');
INSERT INTO CWMS_NATION VALUES ('AG', 'ANTIGUA AND BARBUDA');
INSERT INTO CWMS_NATION VALUES ('AR', 'ARGENTINA');
INSERT INTO CWMS_NATION VALUES ('AM', 'ARMENIA');
INSERT INTO CWMS_NATION VALUES ('AW', 'ARUBA');
INSERT INTO CWMS_NATION VALUES ('AU', 'AUSTRALIA');
INSERT INTO CWMS_NATION VALUES ('AT', 'AUSTRIA');
INSERT INTO CWMS_NATION VALUES ('AZ', 'AZERBAIJAN');
INSERT INTO CWMS_NATION VALUES ('BS', 'BAHAMAS');
INSERT INTO CWMS_NATION VALUES ('BH', 'BAHRAIN');
INSERT INTO CWMS_NATION VALUES ('BD', 'BANGLADESH');
INSERT INTO CWMS_NATION VALUES ('BB', 'BARBADOS');
INSERT INTO CWMS_NATION VALUES ('BY', 'BELARUS');
INSERT INTO CWMS_NATION VALUES ('BE', 'BELGIUM');
INSERT INTO CWMS_NATION VALUES ('BZ', 'BELIZE');
INSERT INTO CWMS_NATION VALUES ('BJ', 'BENIN');
INSERT INTO CWMS_NATION VALUES ('BM', 'BERMUDA');
INSERT INTO CWMS_NATION VALUES ('BT', 'BHUTAN');
INSERT INTO CWMS_NATION VALUES ('BO', 'BOLIVIA');
INSERT INTO CWMS_NATION VALUES ('BA', 'BOSNIA AND HERZEGOVINA');
INSERT INTO CWMS_NATION VALUES ('BW', 'BOTSWANA');
INSERT INTO CWMS_NATION VALUES ('BV', 'BOUVET ISLAND');
INSERT INTO CWMS_NATION VALUES ('BR', 'BRAZIL');
INSERT INTO CWMS_NATION VALUES ('IO', 'BRITISH INDIAN OCEAN TERRITORY');
INSERT INTO CWMS_NATION VALUES ('BN', 'BRUNEI DARUSSALAM');
INSERT INTO CWMS_NATION VALUES ('BG', 'BULGARIA');
INSERT INTO CWMS_NATION VALUES ('BF', 'BURKINA FASO');
INSERT INTO CWMS_NATION VALUES ('BI', 'BURUNDI');
INSERT INTO CWMS_NATION VALUES ('KH', 'CAMBODIA');
INSERT INTO CWMS_NATION VALUES ('CM', 'CAMEROON');
INSERT INTO CWMS_NATION VALUES ('CA', 'CANADA');
INSERT INTO CWMS_NATION VALUES ('CV', 'CAPE VERDE');
INSERT INTO CWMS_NATION VALUES ('KY', 'CAYMAN ISLANDS');
INSERT INTO CWMS_NATION VALUES ('CF', 'CENTRAL AFRICAN REPUBLIC');
INSERT INTO CWMS_NATION VALUES ('TD', 'CHAD');
INSERT INTO CWMS_NATION VALUES ('CL', 'CHILE');
INSERT INTO CWMS_NATION VALUES ('CN', 'CHINA');
INSERT INTO CWMS_NATION VALUES ('CX', 'CHRISTMAS ISLAND');
INSERT INTO CWMS_NATION VALUES ('CC', 'COCOS (KEELING) ISLANDS');
INSERT INTO CWMS_NATION VALUES ('CO', 'COLOMBIA');
INSERT INTO CWMS_NATION VALUES ('KM', 'COMOROS');
INSERT INTO CWMS_NATION VALUES ('CG', 'CONGO');
INSERT INTO CWMS_NATION VALUES ('CD', 'CONGO, THE DEMOCRATIC REPUBLIC OF THE');
INSERT INTO CWMS_NATION VALUES ('CK', 'COOK ISLANDS');
INSERT INTO CWMS_NATION VALUES ('CR', 'COSTA RICA');
INSERT INTO CWMS_NATION VALUES ('CI', 'C�TE D''IVOIRE');
INSERT INTO CWMS_NATION VALUES ('HR', 'CROATIA');
INSERT INTO CWMS_NATION VALUES ('CU', 'CUBA');
INSERT INTO CWMS_NATION VALUES ('CY', 'CYPRUS');
INSERT INTO CWMS_NATION VALUES ('CZ', 'CZECH REPUBLIC');
INSERT INTO CWMS_NATION VALUES ('DK', 'DENMARK');
INSERT INTO CWMS_NATION VALUES ('DJ', 'DJIBOUTI');
INSERT INTO CWMS_NATION VALUES ('DM', 'DOMINICA');
INSERT INTO CWMS_NATION VALUES ('DO', 'DOMINICAN REPUBLIC');
INSERT INTO CWMS_NATION VALUES ('EC', 'ECUADOR');
INSERT INTO CWMS_NATION VALUES ('EG', 'EGYPT');
INSERT INTO CWMS_NATION VALUES ('SV', 'EL SALVADOR');
INSERT INTO CWMS_NATION VALUES ('GQ', 'EQUATORIAL GUINEA');
INSERT INTO CWMS_NATION VALUES ('ER', 'ERITREA');
INSERT INTO CWMS_NATION VALUES ('EE', 'ESTONIA');
INSERT INTO CWMS_NATION VALUES ('ET', 'ETHIOPIA');
INSERT INTO CWMS_NATION VALUES ('FK', 'FALKLAND ISLANDS (MALVINAS)');
INSERT INTO CWMS_NATION VALUES ('FO', 'FAROE ISLANDS');
INSERT INTO CWMS_NATION VALUES ('FJ', 'FIJI');
INSERT INTO CWMS_NATION VALUES ('FI', 'FINLAND');
INSERT INTO CWMS_NATION VALUES ('FR', 'FRANCE');
INSERT INTO CWMS_NATION VALUES ('GF', 'FRENCH GUIANA');
INSERT INTO CWMS_NATION VALUES ('PF', 'FRENCH POLYNESIA');
INSERT INTO CWMS_NATION VALUES ('TF', 'FRENCH SOUTHERN TERRITORIES');
INSERT INTO CWMS_NATION VALUES ('GA', 'GABON');
INSERT INTO CWMS_NATION VALUES ('GM', 'GAMBIA');
INSERT INTO CWMS_NATION VALUES ('GE', 'GEORGIA');
INSERT INTO CWMS_NATION VALUES ('DE', 'GERMANY');
INSERT INTO CWMS_NATION VALUES ('GH', 'GHANA');
INSERT INTO CWMS_NATION VALUES ('GI', 'GIBRALTAR');
INSERT INTO CWMS_NATION VALUES ('GR', 'GREECE');
INSERT INTO CWMS_NATION VALUES ('GL', 'GREENLAND');
INSERT INTO CWMS_NATION VALUES ('GD', 'GRENADA');
INSERT INTO CWMS_NATION VALUES ('GP', 'GUADELOUPE');
INSERT INTO CWMS_NATION VALUES ('GU', 'GUAM');
INSERT INTO CWMS_NATION VALUES ('GT', 'GUATEMALA');
INSERT INTO CWMS_NATION VALUES ('GG', 'GUERNSEY');
INSERT INTO CWMS_NATION VALUES ('GN', 'GUINEA');
INSERT INTO CWMS_NATION VALUES ('GW', 'GUINEA-BISSAU');
INSERT INTO CWMS_NATION VALUES ('GY', 'GUYANA');
INSERT INTO CWMS_NATION VALUES ('HT', 'HAITI');
INSERT INTO CWMS_NATION VALUES ('HM', 'HEARD ISLAND AND MCDONALD ISLANDS');
INSERT INTO CWMS_NATION VALUES ('VA', 'HOLY SEE (VATICAN CITY STATE)');
INSERT INTO CWMS_NATION VALUES ('HN', 'HONDURAS');
INSERT INTO CWMS_NATION VALUES ('HK', 'HONG KONG');
INSERT INTO CWMS_NATION VALUES ('HU', 'HUNGARY');
INSERT INTO CWMS_NATION VALUES ('IS', 'ICELAND');
INSERT INTO CWMS_NATION VALUES ('IN', 'INDIA');
INSERT INTO CWMS_NATION VALUES ('ID', 'INDONESIA');
INSERT INTO CWMS_NATION VALUES ('IR', 'IRAN, ISLAMIC REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('IQ', 'IRAQ');
INSERT INTO CWMS_NATION VALUES ('IE', 'IRELAND');
INSERT INTO CWMS_NATION VALUES ('IM', 'ISLE OF MAN');
INSERT INTO CWMS_NATION VALUES ('IL', 'ISRAEL');
INSERT INTO CWMS_NATION VALUES ('IT', 'ITALY');
INSERT INTO CWMS_NATION VALUES ('JM', 'JAMAICA');
INSERT INTO CWMS_NATION VALUES ('JP', 'JAPAN');
INSERT INTO CWMS_NATION VALUES ('JE', 'JERSEY');
INSERT INTO CWMS_NATION VALUES ('JO', 'JORDAN');
INSERT INTO CWMS_NATION VALUES ('KZ', 'KAZAKHSTAN');
INSERT INTO CWMS_NATION VALUES ('KE', 'KENYA');
INSERT INTO CWMS_NATION VALUES ('KI', 'KIRIBATI');
INSERT INTO CWMS_NATION VALUES ('KP', 'KOREA, DEMOCRATIC PEOPLE''S REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('KR', 'KOREA, REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('KW', 'KUWAIT');
INSERT INTO CWMS_NATION VALUES ('KG', 'KYRGYZSTAN');
INSERT INTO CWMS_NATION VALUES ('LA', 'LAO PEOPLE''S DEMOCRATIC REPUBLIC');
INSERT INTO CWMS_NATION VALUES ('LV', 'LATVIA');
INSERT INTO CWMS_NATION VALUES ('LB', 'LEBANON');
INSERT INTO CWMS_NATION VALUES ('LS', 'LESOTHO');
INSERT INTO CWMS_NATION VALUES ('LR', 'LIBERIA');
INSERT INTO CWMS_NATION VALUES ('LY', 'LIBYAN ARAB JAMAHIRIYA');
INSERT INTO CWMS_NATION VALUES ('LI', 'LIECHTENSTEIN');
INSERT INTO CWMS_NATION VALUES ('LT', 'LITHUANIA');
INSERT INTO CWMS_NATION VALUES ('LU', 'LUXEMBOURG');
INSERT INTO CWMS_NATION VALUES ('MO', 'MACAO');
INSERT INTO CWMS_NATION VALUES ('MK', 'MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('MG', 'MADAGASCAR');
INSERT INTO CWMS_NATION VALUES ('MW', 'MALAWI');
INSERT INTO CWMS_NATION VALUES ('MY', 'MALAYSIA');
INSERT INTO CWMS_NATION VALUES ('MV', 'MALDIVES');
INSERT INTO CWMS_NATION VALUES ('ML', 'MALI');
INSERT INTO CWMS_NATION VALUES ('MT', 'MALTA');
INSERT INTO CWMS_NATION VALUES ('MH', 'MARSHALL ISLANDS');
INSERT INTO CWMS_NATION VALUES ('MQ', 'MARTINIQUE');
INSERT INTO CWMS_NATION VALUES ('MR', 'MAURITANIA');
INSERT INTO CWMS_NATION VALUES ('MU', 'MAURITIUS');
INSERT INTO CWMS_NATION VALUES ('YT', 'MAYOTTE');
INSERT INTO CWMS_NATION VALUES ('MX', 'MEXICO');
INSERT INTO CWMS_NATION VALUES ('FM', 'MICRONESIA, FEDERATED STATES OF');
INSERT INTO CWMS_NATION VALUES ('MD', 'MOLDOVA, REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('MC', 'MONACO');
INSERT INTO CWMS_NATION VALUES ('MN', 'MONGOLIA');
INSERT INTO CWMS_NATION VALUES ('ME', 'MONTENEGRO');
INSERT INTO CWMS_NATION VALUES ('MS', 'MONTSERRAT');
INSERT INTO CWMS_NATION VALUES ('MA', 'MOROCCO');
INSERT INTO CWMS_NATION VALUES ('MZ', 'MOZAMBIQUE');
INSERT INTO CWMS_NATION VALUES ('MM', 'MYANMAR');
INSERT INTO CWMS_NATION VALUES ('NA', 'NAMIBIA');
INSERT INTO CWMS_NATION VALUES ('NR', 'NAURU');
INSERT INTO CWMS_NATION VALUES ('NP', 'NEPAL');
INSERT INTO CWMS_NATION VALUES ('NL', 'NETHERLANDS');
INSERT INTO CWMS_NATION VALUES ('AN', 'NETHERLANDS ANTILLES');
INSERT INTO CWMS_NATION VALUES ('NC', 'NEW CALEDONIA');
INSERT INTO CWMS_NATION VALUES ('NZ', 'NEW ZEALAND');
INSERT INTO CWMS_NATION VALUES ('NI', 'NICARAGUA');
INSERT INTO CWMS_NATION VALUES ('NE', 'NIGER');
INSERT INTO CWMS_NATION VALUES ('NG', 'NIGERIA');
INSERT INTO CWMS_NATION VALUES ('NU', 'NIUE');
INSERT INTO CWMS_NATION VALUES ('NF', 'NORFOLK ISLAND');
INSERT INTO CWMS_NATION VALUES ('MP', 'NORTHERN MARIANA ISLANDS');
INSERT INTO CWMS_NATION VALUES ('NO', 'NORWAY');
INSERT INTO CWMS_NATION VALUES ('OM', 'OMAN');
INSERT INTO CWMS_NATION VALUES ('PK', 'PAKISTAN');
INSERT INTO CWMS_NATION VALUES ('PW', 'PALAU');
INSERT INTO CWMS_NATION VALUES ('PS', 'PALESTINIAN TERRITORY, OCCUPIED');
INSERT INTO CWMS_NATION VALUES ('PA', 'PANAMA');
INSERT INTO CWMS_NATION VALUES ('PG', 'PAPUA NEW GUINEA');
INSERT INTO CWMS_NATION VALUES ('PY', 'PARAGUAY');
INSERT INTO CWMS_NATION VALUES ('PE', 'PERU');
INSERT INTO CWMS_NATION VALUES ('PH', 'PHILIPPINES');
INSERT INTO CWMS_NATION VALUES ('PN', 'PITCAIRN');
INSERT INTO CWMS_NATION VALUES ('PL', 'POLAND');
INSERT INTO CWMS_NATION VALUES ('PT', 'PORTUGAL');
INSERT INTO CWMS_NATION VALUES ('PR', 'PUERTO RICO');
INSERT INTO CWMS_NATION VALUES ('QA', 'QATAR');
INSERT INTO CWMS_NATION VALUES ('RE', 'R�UNION');
INSERT INTO CWMS_NATION VALUES ('RO', 'ROMANIA');
INSERT INTO CWMS_NATION VALUES ('RU', 'RUSSIAN FEDERATION');
INSERT INTO CWMS_NATION VALUES ('RW', 'RWANDA');
INSERT INTO CWMS_NATION VALUES ('BL', 'SAINT BARTH�LEMY');
INSERT INTO CWMS_NATION VALUES ('SH', 'SAINT HELENA');
INSERT INTO CWMS_NATION VALUES ('KN', 'SAINT KITTS AND NEVIS');
INSERT INTO CWMS_NATION VALUES ('LC', 'SAINT LUCIA');
INSERT INTO CWMS_NATION VALUES ('MF', 'SAINT MARTIN');
INSERT INTO CWMS_NATION VALUES ('PM', 'SAINT PIERRE AND MIQUELON');
INSERT INTO CWMS_NATION VALUES ('VC', 'SAINT VINCENT AND THE GRENADINES');
INSERT INTO CWMS_NATION VALUES ('WS', 'SAMOA');
INSERT INTO CWMS_NATION VALUES ('SM', 'SAN MARINO');
INSERT INTO CWMS_NATION VALUES ('ST', 'SAO TOME AND PRINCIPE');
INSERT INTO CWMS_NATION VALUES ('SA', 'SAUDI ARABIA');
INSERT INTO CWMS_NATION VALUES ('SN', 'SENEGAL');
INSERT INTO CWMS_NATION VALUES ('RS', 'SERBIA');
INSERT INTO CWMS_NATION VALUES ('SC', 'SEYCHELLES');
INSERT INTO CWMS_NATION VALUES ('SL', 'SIERRA LEONE');
INSERT INTO CWMS_NATION VALUES ('SG', 'SINGAPORE');
INSERT INTO CWMS_NATION VALUES ('SK', 'SLOVAKIA');
INSERT INTO CWMS_NATION VALUES ('SI', 'SLOVENIA');
INSERT INTO CWMS_NATION VALUES ('SB', 'SOLOMON ISLANDS');
INSERT INTO CWMS_NATION VALUES ('SO', 'SOMALIA');
INSERT INTO CWMS_NATION VALUES ('ZA', 'SOUTH AFRICA');
INSERT INTO CWMS_NATION VALUES ('GS', 'SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS');
INSERT INTO CWMS_NATION VALUES ('ES', 'SPAIN');
INSERT INTO CWMS_NATION VALUES ('LK', 'SRI LANKA');
INSERT INTO CWMS_NATION VALUES ('SD', 'SUDAN');
INSERT INTO CWMS_NATION VALUES ('SR', 'SURINAME');
INSERT INTO CWMS_NATION VALUES ('SJ', 'SVALBARD AND JAN MAYEN');
INSERT INTO CWMS_NATION VALUES ('SZ', 'SWAZILAND');
INSERT INTO CWMS_NATION VALUES ('SE', 'SWEDEN');
INSERT INTO CWMS_NATION VALUES ('CH', 'SWITZERLAND');
INSERT INTO CWMS_NATION VALUES ('SY', 'SYRIAN ARAB REPUBLIC');
INSERT INTO CWMS_NATION VALUES ('TW', 'TAIWAN, PROVINCE OF CHINA');
INSERT INTO CWMS_NATION VALUES ('TJ', 'TAJIKISTAN');
INSERT INTO CWMS_NATION VALUES ('TZ', 'TANZANIA, UNITED REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('TH', 'THAILAND');
INSERT INTO CWMS_NATION VALUES ('TL', 'TIMOR-LESTE');
INSERT INTO CWMS_NATION VALUES ('TG', 'TOGO');
INSERT INTO CWMS_NATION VALUES ('TK', 'TOKELAU');
INSERT INTO CWMS_NATION VALUES ('TO', 'TONGA');
INSERT INTO CWMS_NATION VALUES ('TT', 'TRINIDAD AND TOBAGO');
INSERT INTO CWMS_NATION VALUES ('TN', 'TUNISIA');
INSERT INTO CWMS_NATION VALUES ('TR', 'TURKEY');
INSERT INTO CWMS_NATION VALUES ('TM', 'TURKMENISTAN');
INSERT INTO CWMS_NATION VALUES ('TC', 'TURKS AND CAICOS ISLANDS');
INSERT INTO CWMS_NATION VALUES ('TV', 'TUVALU');
INSERT INTO CWMS_NATION VALUES ('UG', 'UGANDA');
INSERT INTO CWMS_NATION VALUES ('UA', 'UKRAINE');
INSERT INTO CWMS_NATION VALUES ('AE', 'UNITED ARAB EMIRATES');
INSERT INTO CWMS_NATION VALUES ('GB', 'UNITED KINGDOM');
INSERT INTO CWMS_NATION VALUES ('US', 'UNITED STATES');
INSERT INTO CWMS_NATION VALUES ('UM', 'UNITED STATES MINOR OUTLYING ISLANDS');
INSERT INTO CWMS_NATION VALUES ('UY', 'URUGUAY');
INSERT INTO CWMS_NATION VALUES ('UZ', 'UZBEKISTAN');
INSERT INTO CWMS_NATION VALUES ('VU', 'VANUATU');
INSERT INTO CWMS_NATION VALUES ('VE', 'VENEZUELA, BOLIVARIAN REPUBLIC OF');
INSERT INTO CWMS_NATION VALUES ('VN', 'VIET NAM');
INSERT INTO CWMS_NATION VALUES ('VG', 'VIRGIN ISLANDS, BRITISH');
INSERT INTO CWMS_NATION VALUES ('VI', 'VIRGIN ISLANDS, U.S.');
INSERT INTO CWMS_NATION VALUES ('WF', 'WALLIS AND FUTUNA');
INSERT INTO CWMS_NATION VALUES ('EH', 'WESTERN SAHARA');
INSERT INTO CWMS_NATION VALUES ('YE', 'YEMEN');
INSERT INTO CWMS_NATION VALUES ('ZM', 'ZAMBIA');
INSERT INTO CWMS_NATION VALUES ('ZW', 'ZIMBABWE');



    INSERT INTO CWMS_VERTICAL_DATUM VALUES ('STAGE');
    INSERT INTO CWMS_VERTICAL_DATUM VALUES ('LOCAL');
    INSERT INTO CWMS_VERTICAL_DATUM VALUES ('NGVD29');
    INSERT INTO CWMS_VERTICAL_DATUM VALUES ('NAVD88');


    insert into CWMS_STORE_RULE values(1, 'REPLACE WITH NON MISSING',    'Insert values at new times and replace any values at existing times, unless the incoming values are specified as missing', 'T');
    insert into CWMS_STORE_RULE values(2, 'REPLACE ALL',                 'Insert values at new times and replace any values at existing times, even if incoming values are specified as missing', 'F');
    insert into CWMS_STORE_RULE values(3, 'REPLACE MISSING VALUES ONLY', 'Insert values at new times but do not replace any values at existing times unless the existing values are specified as missing', 'F');
    insert into CWMS_STORE_RULE values(4, 'DO NOT REPLACE',              'Insert values at new times but do not replace any values at existing times', 'F');
    insert into CWMS_STORE_RULE values(5, 'DELETE INSERT',               'Delete all existing values in time window of incoming data and then insert incoming data', 'F');

insert into CWMS_LOCATION_KIND values(1, NULL, 'SITE', 'The point identified with site', 'A location with no entry in one of the location kind tables');
insert into CWMS_LOCATION_KIND values(2, 1, 'STREAM', 'The downstream-most point', 'A stream or river');
insert into CWMS_LOCATION_KIND values(3, 1, 'BASIN', 'The outlet of the basin', 'A basin or water catchment');
insert into CWMS_LOCATION_KIND values(4, 1, 'PROJECT', 'The project office or other loc', 'One or more associated structures constructed to manage the flow of water in a river or stream');
insert into CWMS_LOCATION_KIND values(5, 1, 'EMBANKMENT', 'The midpoint of the centerline', 'A structure protruding above the ground constructed to impede or direct the flow of water in a river or stream');
insert into CWMS_LOCATION_KIND values(6, 1, 'OUTLET', 'The discharge point or midpoint', 'A structure constructed to allow the flow of water through, under, or over an embankment');
insert into CWMS_LOCATION_KIND values(7, 1, 'TURBINE', 'The discharge point', 'A structure constructed to generate electricity from the flow of water');
insert into CWMS_LOCATION_KIND values(8, 1, 'LOCK', 'The center of the chamber', 'A structure that raises and lowers waterborne vessels between upper and lower pools');
insert into CWMS_LOCATION_KIND values(9, 1, 'STREAM_LOCATION', 'The stream location', 'A location on or along a stream');
insert into CWMS_LOCATION_KIND values(10, 6, 'GATE', 'The discharge point', 'An outlet that can restrict or prevent the flow of water.');
insert into CWMS_LOCATION_KIND values(11, 6, 'OVERFLOW', 'The midpoint of the discharge', 'An outlet that passes the flow of water without restriction above a certain elevation');
insert into CWMS_LOCATION_KIND values(12, 9, 'STREAM_GAGE', 'The gage location', 'A stream location that has a gage used to measure stage and/or other hydrologic parameters');
insert into CWMS_LOCATION_KIND values(13, 1, 'STREAM_REACH', 'The downstream-most point', 'A length of a stream bounded by upstream and downstream extents');
insert into CWMS_LOCATION_KIND values(14, 9, 'PUMP', 'The intake or discharge point', 'A stream location where water is pumped from or into a stream or reservoir');
insert into CWMS_LOCATION_KIND values(15, 1, 'WEATHER_GAGE', 'The gage location', 'A location that has a gage used to measure precipitation and/or other meteorologic parameters');
insert into CWMS_LOCATION_KIND values(16, 1, 'ENTITY', 'A representitave point', 'A location associated with an entity in the AT_ENTITY table');


insert into CWMS_USGS_TIME_ZONE values('ACSST', 'Central Australia Summer Time', to_dsinterval('+00 10:30:00'));
insert into CWMS_USGS_TIME_ZONE values('ACST', 'Central Australia Standard Time', to_dsinterval('+00 09:30:00'));
insert into CWMS_USGS_TIME_ZONE values('ADT', 'Atlantic Daylight Time', to_dsinterval('-00 03:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AESST', 'Australia Eastern Summer Time', to_dsinterval('+00 11:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AEST', 'Australia Eastern Standard Time', to_dsinterval('+00 10:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AFT', 'Afghanistan Time', to_dsinterval('+00 04:30:00'));
insert into CWMS_USGS_TIME_ZONE values('AKDT', 'Alaska Daylight Time', to_dsinterval('-00 08:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AKST', 'Alaska Standard Time', to_dsinterval('-00 09:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AST', 'Atlantic Standard Time (Canada)', to_dsinterval('-00 04:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AWSST', 'Australia Western Summer Time', to_dsinterval('+00 09:00:00'));
insert into CWMS_USGS_TIME_ZONE values('AWST', 'Australia Western Standard Time', to_dsinterval('+00 08:00:00'));
insert into CWMS_USGS_TIME_ZONE values('BST', 'British Summer Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('BT', 'Baghdad Time', to_dsinterval('+00 03:00:00'));
insert into CWMS_USGS_TIME_ZONE values('CADT', 'Central Australia Daylight Time', to_dsinterval('+00 10:30:00'));
insert into CWMS_USGS_TIME_ZONE values('CAST', 'Central Australia Standard Time', to_dsinterval('+00 09:30:00'));
insert into CWMS_USGS_TIME_ZONE values('CCT', 'China Coastal Time', to_dsinterval('+00 08:00:00'));
insert into CWMS_USGS_TIME_ZONE values('CDT', 'Central Daylight Time', to_dsinterval('-00 05:00:00'));
insert into CWMS_USGS_TIME_ZONE values('CET', 'Central European Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('CETDST', 'Central European Daylight Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('CST', 'Central Standard Time', to_dsinterval('-00 06:00:00'));
insert into CWMS_USGS_TIME_ZONE values('DNT', 'Dansk Normal Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('DST', 'Dansk Summer Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('EASST', 'East Australian Summer Time', to_dsinterval('+00 11:00:00'));
insert into CWMS_USGS_TIME_ZONE values('EAST', 'East Australian Standard Time', to_dsinterval('+00 10:00:00'));
insert into CWMS_USGS_TIME_ZONE values('EDT', 'Eastern Daylight Time', to_dsinterval('-00 04:00:00'));
insert into CWMS_USGS_TIME_ZONE values('EET', 'Eastern Europe Standard Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('EETDST', 'Eastern Europe Daylight Time', to_dsinterval('+00 03:00:00'));
insert into CWMS_USGS_TIME_ZONE values('EST', 'Eastern Standard Time', to_dsinterval('-00 05:00:00'));
insert into CWMS_USGS_TIME_ZONE values('FST', 'French Summer Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('FWT', 'French Winter Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('GMT', 'Greenwich Mean Time', to_dsinterval(' 00 00:00:00'));
insert into CWMS_USGS_TIME_ZONE values('GST', 'Guam Standard Time', to_dsinterval('+00 10:00:00'));
insert into CWMS_USGS_TIME_ZONE values('HDT', 'Hawaii Daylight Time', to_dsinterval('-00 09:00:00'));
insert into CWMS_USGS_TIME_ZONE values('HST', 'Hawaii Standard Time', to_dsinterval('-00 10:00:00'));
insert into CWMS_USGS_TIME_ZONE values('IDLE', 'International Date Line, East', to_dsinterval('+00 12:00:00'));
insert into CWMS_USGS_TIME_ZONE values('IDLW', 'International Date Line, West', to_dsinterval('-00 12:00:00'));
insert into CWMS_USGS_TIME_ZONE values('IST', 'Israel Standard Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('IT', 'Iran Time', to_dsinterval('+00 03:30:00'));
insert into CWMS_USGS_TIME_ZONE values('JST', 'Japan Standard Time', to_dsinterval('+00 09:00:00'));
insert into CWMS_USGS_TIME_ZONE values('JT', 'Java Time', to_dsinterval('+00 07:30:00'));
insert into CWMS_USGS_TIME_ZONE values('KST', 'Korea Standard Time', to_dsinterval('+00 09:00:00'));
insert into CWMS_USGS_TIME_ZONE values('LIGT', 'Melbourne, Australia', to_dsinterval('+00 10:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MDT', 'Mountain Daylight Time', to_dsinterval('-00 06:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MEST', 'Middle Europe Summer Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MET', 'Middle Europe Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('METDST', 'Middle Europe Daylight Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MEWT', 'Middle Europe Winter Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MEZ', 'Middle Europe Zone', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MST', 'Mountain Standard Time', to_dsinterval('-00 07:00:00'));
insert into CWMS_USGS_TIME_ZONE values('MT', 'Moluccas Time', to_dsinterval('+00 08:30:00'));
insert into CWMS_USGS_TIME_ZONE values('NDT', 'Newfoundland Daylight Time', to_dsinterval('-00 02:30:00'));
insert into CWMS_USGS_TIME_ZONE values('NFT', 'Newfoundland Standard Time', to_dsinterval('-00 03:30:00'));
insert into CWMS_USGS_TIME_ZONE values('NOR', 'Norway Standard Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('NST', 'Newfoundland Standard Time', to_dsinterval('-00 03:30:00'));
insert into CWMS_USGS_TIME_ZONE values('NZDT', 'New Zealand Daylight Time', to_dsinterval('+00 13:00:00'));
insert into CWMS_USGS_TIME_ZONE values('NZST', 'New Zealand Standard Time', to_dsinterval('+00 12:00:00'));
insert into CWMS_USGS_TIME_ZONE values('NZT', 'New Zealand Time', to_dsinterval('+00 12:00:00'));
insert into CWMS_USGS_TIME_ZONE values('PDT', 'Pacific Daylight Time', to_dsinterval('-00 07:00:00'));
insert into CWMS_USGS_TIME_ZONE values('PST', 'Pacific Standard Time', to_dsinterval('-00 08:00:00'));
insert into CWMS_USGS_TIME_ZONE values('SADT', 'South Australian Daylight Time', to_dsinterval('+00 10:30:00'));
insert into CWMS_USGS_TIME_ZONE values('SAT', 'South Australian Standard Time', to_dsinterval('+00 09:30:00'));
insert into CWMS_USGS_TIME_ZONE values('SET', 'Seychelles Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('SST', 'Swedish Summer Time', to_dsinterval('+00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('SWT', 'Swedish Winter Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('UTC', 'Universal Coordinated Time', to_dsinterval(' 00 00:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WADT', 'West Australian Daylight Time', to_dsinterval('+00 08:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WAST', 'West Australian Standard Time', to_dsinterval('+00 07:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WAT', 'West Africa Time', to_dsinterval('-00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WDT', 'West Australian Daylight Time', to_dsinterval('+00 09:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WET', 'Western Europe', to_dsinterval(' 00 00:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WETDST', 'Western Europe Daylight Time', to_dsinterval('+00 01:00:00'));
insert into CWMS_USGS_TIME_ZONE values('WST', 'West Australian Standard Time', to_dsinterval('+00 08:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP-2', 'UTC -2 hours', to_dsinterval('-00 02:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP-3', 'UTC -3 hours', to_dsinterval('-00 03:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP-11', 'UTC -11 hours', to_dsinterval('-00 11:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP4', 'UTC +4 hours', to_dsinterval('+00 04:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP5', 'UTC +5 hours', to_dsinterval('+00 05:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP6', 'UTC +6 hours', to_dsinterval('+00 06:00:00'));
insert into CWMS_USGS_TIME_ZONE values('ZP11', 'UTC +11 hours', to_dsinterval('+00 11:00:00'));



insert into CWMS_USGS_FLOW_ADJ values('UNSP', 'Unspecified', 'Transfer from null code only');
insert into CWMS_USGS_FLOW_ADJ values('MEAS', 'Measured', 'The discharge value was measured.');
insert into CWMS_USGS_FLOW_ADJ values('STOR', 'Adjusted for storage', 'The discharge value was adjusted for channel storage (between the measurement and the gage).');
insert into CWMS_USGS_FLOW_ADJ values('BYPS', 'Adjusted for other flows', 'The discharge at the gaging site was adjusted to account for bypass lateral tributary or diverted flows.');
insert into CWMS_USGS_FLOW_ADJ values('MAIN', 'Main channel flow only', 'The discharge was from a measurement in the main channel only it does not include other channels in this stream.');
insert into CWMS_USGS_FLOW_ADJ values('TIDE', 'Adjusted for tidal effect', 'The discharge was adjusted for tidal effect.');
insert into CWMS_USGS_FLOW_ADJ values('OTHR', 'Adjusted for other factors', 'The discharge was adjusted by a method not listed.(see measurement remarks).');


insert into CWMS_USGS_RATING_CTRL_COND values('UNSP', 'The stream control conditions were not specified.');
insert into CWMS_USGS_RATING_CTRL_COND values('AICE', 'The stream control is covered with anchor ice.');
insert into CWMS_USGS_RATING_CTRL_COND values('CICE', 'The stream control was convered by ice.');
insert into CWMS_USGS_RATING_CTRL_COND values('CLER', 'The stream control was clear of any obstructions.');
insert into CWMS_USGS_RATING_CTRL_COND values('FILL', 'The stream control was filled.');
insert into CWMS_USGS_RATING_CTRL_COND values('HVDB', 'The stream control was heavily covered with debris.');
insert into CWMS_USGS_RATING_CTRL_COND values('LGDB', 'The stream control was lightly covered with debris.');
insert into CWMS_USGS_RATING_CTRL_COND values('ALGA', 'The stream control was covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('MAHV', 'The stream control was heavily covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('MALT', 'The stream control was lightly covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('MAMD', 'The stream control was moderately covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('MDDB', 'The stream control was moderately covered with debris.');
insert into CWMS_USGS_RATING_CTRL_COND values('NFLW', 'There was no flow over the stream control.');
insert into CWMS_USGS_RATING_CTRL_COND values('SCUR', 'The stream control has scour conditions.');
insert into CWMS_USGS_RATING_CTRL_COND values('SICE', 'The stream control has shore ice.');
insert into CWMS_USGS_RATING_CTRL_COND values('SUBM', 'The stream control was submerged.');
insert into CWMS_USGS_RATING_CTRL_COND values('Unknown', 'The stream control conditions are unknown.');
insert into CWMS_USGS_RATING_CTRL_COND values('Unspecified', 'The stream control conditions were not specified.');
insert into CWMS_USGS_RATING_CTRL_COND values('Clear', 'The stream control was clear of any obstructions.');
insert into CWMS_USGS_RATING_CTRL_COND values('FillControlChanged', 'The stream control was filled.');
insert into CWMS_USGS_RATING_CTRL_COND values('ScourControlChanged', 'The stream control has scour conditions.');
insert into CWMS_USGS_RATING_CTRL_COND values('DebrisLight', 'The stream control was lightly covered with debris.');
insert into CWMS_USGS_RATING_CTRL_COND values('DebrisModerate', 'The stream control was moderately covered with debris.');
insert into CWMS_USGS_RATING_CTRL_COND values('DebrisHeavy', 'The stream control was heavily covered with debris.');
insert into CWMS_USGS_RATING_CTRL_COND values('VegetationLight', 'The stream control was lightly covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('VegetationModerate', 'The stream control was moderately covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('VegetationHeavy', 'The stream control was heavily covered with moss/algae.');
insert into CWMS_USGS_RATING_CTRL_COND values('IceAnchor', 'The stream control is covered with anchor ice.');
insert into CWMS_USGS_RATING_CTRL_COND values('IceCover', 'The stream control was covered by ice.');
insert into CWMS_USGS_RATING_CTRL_COND values('IceShore', 'The stream control has shore ice.');
insert into CWMS_USGS_RATING_CTRL_COND values('Submerged', 'The stream control was submerged.');
insert into CWMS_USGS_RATING_CTRL_COND values('NoFlow', 'There was no flow over the stream control.');


insert into CWMS_USGS_MEAS_QUAL values('E', 'Excellent', 'The data is within 2% (percent) of the actual flow');
insert into CWMS_USGS_MEAS_QUAL values('G', 'Good', 'The data is within 5% (percent) of the actual flow');
insert into CWMS_USGS_MEAS_QUAL values('F', 'Fair', 'The data is within 8% (percent) of the actual flow');
insert into CWMS_USGS_MEAS_QUAL values('P', 'Poor', 'The data are >8% (percent) of the actual flow');
insert into CWMS_USGS_MEAS_QUAL values('U', 'Unspecified', 'The measurement quality is unknown');


insert into CWMS_USGS_PARAMETER values(60, 14,NULL, 6, 72, 1, 0, 'QR', 'T', 0.001, 0, 'Discharge, cubic feet per second');
insert into CWMS_USGS_PARAMETER values(65, 23,NULL, 6, 35, 1, 0, 'HG', 'T', 1, 0, 'Gage height, feet');
insert into CWMS_USGS_PARAMETER values(10, 25,'Water', 6, 67, 1, 0, 'TW', 'F', 1, 0, 'Temperature, water, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(72019, 9,'Groundwater', 6, 35, 1, 0, 'HB', 'T', 1, 0, 'Depth to water level, feet below land surface');
insert into CWMS_USGS_PARAMETER values(70969, 29,'Battery', 6, 22, 1, 0, 'VB', 'T', 1, 0, 'DCP battery voltage, volts');
insert into CWMS_USGS_PARAMETER values(95, 6,NULL, 6, 16, 1, 0, 'WC', 'T', 1, 0, 'Specific conductance, water, unfiltered, microsiemens per centimeter at 25 degrees Celsius');
insert into CWMS_USGS_PARAMETER values(45, 19,NULL, 1, 36, 1, 0, 'PP', 'T', 1, 0, 'Precipitation, total, inches');
insert into CWMS_USGS_PARAMETER values(300, 5,'DO', 6, 51, 1, 0, 'WO', 'F', 1, 0, 'Dissolved oxygen, water, unfiltered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(400, 17,NULL, 6, 29, 1, 0, 'WP', 'T', 1, 0, 'pH, water, unfiltered, field, standard units');
insert into CWMS_USGS_PARAMETER values(63680, 38,NULL, 6, 71, 1, 0, NULL, NULL, NULL, NULL, 'Turbidity, water, unfiltered, monochrome near infra-red LED light, 780-900 nm, detection angle 90 +-2.5 degrees, formazin nephelometric units (FNU)');
insert into CWMS_USGS_PARAMETER values(72020, 10,NULL, 6, 35, 1, 0, 'HP', 'T', 1, 0, 'Elevation above NGVD 1929, feet');
insert into CWMS_USGS_PARAMETER values(80154, 5,'Sediment', 6, 51, 1, 0, 'WL', 'F', 1, 0, 'Suspended sediment concentration, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(55, 22,'Water', 6, 41, 1, 0, 'QF', 'T', 0.681818, 0, 'Stream velocity, feet per second');
insert into CWMS_USGS_PARAMETER values(62, 10,NULL, 6, 35, 1, 0, 'HP', 'T', 1, 0, 'Elevation of reservoir water surface above datum, feet');
insert into CWMS_USGS_PARAMETER values(480, 5,'Salt', 6, 52, 1000, 0, 'WS', 'T', 1, 0, 'Salinity, water, unfiltered, parts per thousand');
insert into CWMS_USGS_PARAMETER values(54, 24,NULL, 6, 78, 1, 0, 'LS', 'T', 0.001, 0, 'Reservoir storage, acre feet');
insert into CWMS_USGS_PARAMETER values(301, 1,'Saturation-DO', 6, 53, 1, 0, 'WX', 'T', 1, 0, 'Dissolved oxygen, water, unfiltered, percent of saturation');
insert into CWMS_USGS_PARAMETER values(62611, 10,'Groundwater', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Groundwater level above NAVD 1988, feet');
insert into CWMS_USGS_PARAMETER values(11, 25,'Water', 6, 68, 1, 0, 'TW', 'T', 1, 0, 'Temperature, water, degrees Fahrenheit');
insert into CWMS_USGS_PARAMETER values(72112, 37,'SignalToNoise', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'DCP signal to noise ratio');
insert into CWMS_USGS_PARAMETER values(20, 25,'Air', 6, 67, 1, 0, 'TA', 'F', 1, 0, 'Temperature, air, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(61035, 29,NULL, 6, 22, 1, 0, NULL, NULL, NULL, NULL, 'Voltage, volts');
insert into CWMS_USGS_PARAMETER values(62614, 10,NULL, 6, 35, 1, 0, 'HP', 'T', 1, 0, 'Lake or reservoir water surface elevation above NGVD 1929, feet');
insert into CWMS_USGS_PARAMETER values(63160, 10,NULL, 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Stream water level elevation above NAVD 1988, in feet');
insert into CWMS_USGS_PARAMETER values(21, 25,'Air', 6, 35, 1, 0, 'TA', 'T', 1, 0, 'Temperature, air, degrees Fahrenheit');
insert into CWMS_USGS_PARAMETER values(36, 3,'Wind', 6, 1, 1, 0, 'UD', 'T', 1, 0, 'Wind direction, degrees clockwise from true north');
insert into CWMS_USGS_PARAMETER values(35, 22,'Wind', 6, 48, 1, 0, 'US', 'T', 1, 0, 'Wind speed, miles per hour');
insert into CWMS_USGS_PARAMETER values(52, 1,'Humidity', 6, 53, 1, 0, 'XR', 'T', 1, 0, 'Relative humidity, percent');
insert into CWMS_USGS_PARAMETER values(62610, 10,'Groundwater', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Groundwater level above NGVD 1929, feet');
insert into CWMS_USGS_PARAMETER values(99133, 5,'Nitrate+NitriteAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Nitrate plus nitrite, water, in situ, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(81027, 25,'Soil', 6, 67, 1, 0, 'TS', 'F', 1, 0, 'Temperature, soil, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(74207, 1,'Moisture-Soil', 6, 53, 1, 0, 'MW', 'T', 1, 0, 'Moisture content, soil, volumetric, percent of total volume');
insert into CWMS_USGS_PARAMETER values(72150, 10,'Groundwater', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Groundwater level relative to Mean Sea Level (MSL), feet');
insert into CWMS_USGS_PARAMETER values(72137, 14,NULL, 6, 72, 1, 0, 'QR', 'T', 0.001, 0, 'Discharge, tidally filtered, cubic feet per second');
insert into CWMS_USGS_PARAMETER values(45592, 16,NULL, 6, 35, 1, 0, 'NO', 'T', 1, 0, 'Gate opening, height, feet');
insert into CWMS_USGS_PARAMETER values(62846, 25,'Soil', 6, 35, 1, 0, 'TS', 'T', 1, 0, 'Soil temperature, degrees Fahrenheit');
insert into CWMS_USGS_PARAMETER values(99060, 14,NULL, 6, 73, 1, 0, 'QR', 'F', 1, 0, 'Discharge, cubic meters per second');
insert into CWMS_USGS_PARAMETER values(25, 20,NULL, 6, 65, 1, 0, 'PA', 'T', 0.0393700787402, 0, 'Barometric pressure, millimeters of mercury');
insert into CWMS_USGS_PARAMETER values(99238, 36,'ADVMEnd', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Location of Acoustic Doppler Velocity Meter cell end, feet');
insert into CWMS_USGS_PARAMETER values(99234, 7,'Samples', 6, 17, 1, 0, NULL, NULL, NULL, NULL, 'Count of samples collected by autosampler, number');
insert into CWMS_USGS_PARAMETER values(3, 9,'Sample', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Sampling depth, feet');
insert into CWMS_USGS_PARAMETER values(99237, 37,'SignalToNoise', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Acoustic Doppler Velocity Meter signal to noise ratio');
insert into CWMS_USGS_PARAMETER values(62619, 10,NULL, 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Estuary or ocean water surface elevation above NGVD 1929, feet');
insert into CWMS_USGS_PARAMETER values(62361, 5,'Chorophyll', 6, 51, 0.001, 0, 'WY', 'F', 1, 0, 'Chlorophyll, total, water, fluorometric, 650-700 nanometers, in situ sensor, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(72147, 9,'Sensor', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Depth of sensor below water surface, feet');
insert into CWMS_USGS_PARAMETER values(72181, 37,'Moisture-Soil', 6, 54, 1, 0, 'MW', 'T', 100, 0, 'Moisture content, soil, volumetric, fraction of total volume');
insert into CWMS_USGS_PARAMETER values(62625, 22,'Wind', 6, 45, 1, 0, 'US', 'F', 1, 0, 'Wind speed, meters per second');
insert into CWMS_USGS_PARAMETER values(76, 34,NULL, 6, 70, 1, 0, NULL, NULL, NULL, NULL, 'Turbidity, water, unfiltered, nephelometric turbidity units');
insert into CWMS_USGS_PARAMETER values(98, 9,'Sample', 6, 38, 1, 0, NULL, NULL, NULL, NULL, 'Sampling depth, meters');
insert into CWMS_USGS_PARAMETER values(32295, 5,'CDOM-QSE', 6, 52, 1000, 0, NULL, NULL, NULL, NULL, 'Colored dissolved organic matter (CDOM), water, in situ, single band excitation, fluorescence emission, parts per billion quinine sulfate equivalents (ppb QSE)');
insert into CWMS_USGS_PARAMETER values(47, 20,'TotalGasses', 6, 65, 1, 0, 'WG', 'F', 1, 0, 'Total partial pressure of dissolved gases, water, unfiltered, millimeters of mercury');
insert into CWMS_USGS_PARAMETER values(62620, 10,NULL, 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Estuary or ocean water surface elevation above NAVD 1988, feet');
insert into CWMS_USGS_PARAMETER values(48, 1,'Saturation-TotalGasses', 6, 53, 1, 0, NULL, NULL, NULL, NULL, 'Total partial pressure of dissolved gases, water, unfiltered, percent of saturation');
insert into CWMS_USGS_PARAMETER values(62608, 32,NULL, 6, 31, 1, 0, 'RW', 'T', 1, 0, 'Total solar radiation (direct + diffuse radiation on a horizontal surface), watts per square meter');
insert into CWMS_USGS_PARAMETER values(62615, 10,NULL, 6, 35, 1, 0, 'HP', 'T', 1, 0, 'Lake or reservoir water surface elevation above NAVD 1988, feet');
insert into CWMS_USGS_PARAMETER values(99065, 23,NULL, 6, 38, 1, 0, 'HG', 'F', 1, 0, 'Gage height, above datum, meters');
insert into CWMS_USGS_PARAMETER values(61055, 37,'VanadiumUnder2mm', 6, 54, 1e-06, 0, NULL, NULL, NULL, NULL, 'Vanadium, bed sediment smaller than 2 millimeters, total digestion, dry weight, milligrams per kilogram');
insert into CWMS_USGS_PARAMETER values(63158, 10,NULL, 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Stream water level elevation above NGVD 1929, in feet');
insert into CWMS_USGS_PARAMETER values(72243, 14,NULL, 6, 72, 0, 0, 'QR', 'T', 0, 0, 'Discharge, cubic feet per day');
insert into CWMS_USGS_PARAMETER values(62609, 32,'Net', 6, 31, 1, 0, 'RN', 'T', 1, 0, 'Net solar radiation, watts per square meter');
insert into CWMS_USGS_PARAMETER values(72192, 19,NULL, 1, 36, 1, 0, 'PP', 'T', 1, 0, 'Precipitation, cumulative, inches');
insert into CWMS_USGS_PARAMETER values(45587, 25,'DCP', 6, 67, 1, 0, NULL, NULL, NULL, NULL, 'Temperature, internal, within data collection platform, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(530, 5,'Solids', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Suspended solids, water, unfiltered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(99409, 5,'Sediment', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Suspended sediment concentration, water, unfiltered, estimated by regression equation, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(70, 33,NULL, 6, 69, 1, 0, 'WT', 'T', 1, 0, 'Turbidity, water, unfiltered, Jackson Turbidity Units');
insert into CWMS_USGS_PARAMETER values(90856, 37,'SodiumAdsorption', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Sodium adsorption ratio, water, estimated by regression equation, number');
insert into CWMS_USGS_PARAMETER values(61728, 22,'Wind-Gust', 6, 48, 1, 0, 'UG', 'T', 1, 0, 'Wind gust speed, air, miles per hour');
insert into CWMS_USGS_PARAMETER values(75969, 20,NULL, 6, 64, 1, 0, 'PA', 'F', 0.1, 0, 'Barometric pressure, not corrected to sea level, millibars');
insert into CWMS_USGS_PARAMETER values(50012, 40,'Compaction', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Compaction, aquifer system, feet');
insert into CWMS_USGS_PARAMETER values(63, 7,'Points', 6, 17, 1, 0, NULL, NULL, NULL, NULL, 'Number of sampling points, count');
insert into CWMS_USGS_PARAMETER values(99137, 5,'NitrateAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Nitrate, water, in situ, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(72205, 6,'Soil', 6, 16, 1000, 0, NULL, NULL, NULL, NULL, 'Bulk electrical conductance, soil, decisiemens per meter');
insert into CWMS_USGS_PARAMETER values(50294, 4,'AVMDiagnostic', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Diagnostic code, tattler, acoustic velocity meter, number');
insert into CWMS_USGS_PARAMETER values(61729, 3,'Wind-Gust', 6, 1, 1, 0, 'UH', 'T', 0.1, 0, 'Wind gust direction, air, degrees clockwise from true north');
insert into CWMS_USGS_PARAMETER values(32316, 5,'Chlorophyll-A-Est', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, estimated, water, in-situ, in-vivo fluorescence (IVF), concentration estimated from reference material, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(45585, 16,NULL, 6, 35, 1, 0, 'NO', 'T', 1, 0, 'Gate opening, width, feet');
insert into CWMS_USGS_PARAMETER values(72159, 13,NULL, 6, 46, 1, 0, 'ER', 'F', 1, 0, 'Evapotranspiration, millimeters per day');
insert into CWMS_USGS_PARAMETER values(90095, 6,NULL, 6, 16, 1, 0, 'WC', 'T', 1, 0, 'Specific conductance, water, unfiltered, laboratory, microsiemens per centimeter at 25 degrees Celsius');
insert into CWMS_USGS_PARAMETER values(62616, 10,NULL, 6, 35, 1, 0, 'HP', 'F', 1, 0, 'Lake or reservoir water surface elevation above NGVD 1929, meters');
insert into CWMS_USGS_PARAMETER values(72036, 24,NULL, 6, 82, 1, 0, 'LS', 'T', 1, 0, 'Reservoir storage, thousand acre feet');
insert into CWMS_USGS_PARAMETER values(99986, 32,NULL, 6, 31, 1, 0, 'RN', 'T', 1, 0, 'Solar radiation (average flux density on a horizontal surface during measurement interval), watts per square meter');
insert into CWMS_USGS_PARAMETER values(650, 5,'PhosphateAsPO4', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Phosphate, water, unfiltered, milligrams per liter as PO4');
insert into CWMS_USGS_PARAMETER values(62623, 23,NULL, 6, 35, 1, 0, 'HM', 'T', 1, 0, 'Tide stage, above datum, feet');
insert into CWMS_USGS_PARAMETER values(63675, 34,NULL, 6, 70, 1, 0, NULL, NULL, NULL, NULL, 'Turbidity, water, unfiltered, broad band light source (400-680 nm), detection angle 90 +-30 degrees to incident light, nephelometric turbidity units (NTU)');
insert into CWMS_USGS_PARAMETER values(72180, 12,'+Transpiration', 6, 36, 1, 0, 'EM', 'T', 1, 0, 'Evapotranspiration, inches');
insert into CWMS_USGS_PARAMETER values(72252, 32,NULL, 6, 31, 1000, 0, 'RN', 'T', 1000, 0, 'Solar radiation (average flux density on a horizontal surface during measurement interval), kilowatts per square meter');
insert into CWMS_USGS_PARAMETER values(99111, 4,'QA-Type', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Type of quality assurance data associated with sample, code');
insert into CWMS_USGS_PARAMETER values(50, 13,NULL, 6, 42, 1, 0, 'ER', 'T', 1, 0, 'Evaporation total, inches per day');
insert into CWMS_USGS_PARAMETER values(99235, 4,'AlarmStatus-Equip', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Status of equipment alarm, codes specified in data descriptor');
insert into CWMS_USGS_PARAMETER values(665, 5,'PhosphorusAsP', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Phosphorus, water, unfiltered, milligrams per liter as phosphorus');
insert into CWMS_USGS_PARAMETER values(72022, 24,NULL, 6, 86, 1, 0, 'LS', 'T', 0.003571097, 0, 'Reservoir storage, million gallons');
insert into CWMS_USGS_PARAMETER values(72124, 32,'Net', 6, 31, 1, 0, 'RN', 'T', 1000, 0, 'Net radiation (net solar + net long wave radiation), watts per square meter');
insert into CWMS_USGS_PARAMETER values(32285, 5,'Chlorophyll-A-GnAlgae', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, green algae, in situ, fluorescence excitation at 370, 470, 525, 570, 590, 610 nm, fluorescence emission at 700 nm with correction for CDOM, ug/L');
insert into CWMS_USGS_PARAMETER values(62602, 20,'CorrectedToSeaLevel', 6, 62, 1, 0, 'PL', 'T', 1, 0, 'Barometric pressure, corrected to sea level, inches of mercury');
insert into CWMS_USGS_PARAMETER values(99772, 19,NULL, 6, 40, 1, 0, 'PC', 'F', 1, 0, 'Precipitation, millimeters');
insert into CWMS_USGS_PARAMETER values(631, 5,'Nitrate+NitriteAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Nitrate plus nitrite, water, filtered, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(85583, 25,'Water-Intragravel', 6, 67, 1, 0, NULL, NULL, NULL, NULL, 'Temperature, intragravel water, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(940, 5,'Chloride', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Chloride, water, filtered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(32284, 5,'Chlorophyll-A', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, total, in situ, fluorescence excitation at 370, 470, 525, 570, 590, 610 nm, fluorescence emission at 700 nm with correction for CDOM, ug/L');
insert into CWMS_USGS_PARAMETER values(62603, 20,NULL, 6, 62, 1, 0, 'PA', 'T', 1, 0, 'Barometric pressure, uncorrected, inches of mercury');
insert into CWMS_USGS_PARAMETER values(72166, 29,'Sensor', 6, 22, 1, 0, NULL, NULL, NULL, NULL, 'Raw sensor value, millivolts');
insert into CWMS_USGS_PARAMETER values(81026, 9,'SWE', 6, 36, 1, 0, 'SW', 'T', 1, 0, 'Water content of snow, inches');
insert into CWMS_USGS_PARAMETER values(99134, 5,'Carbon', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Dissolved organic carbon, water, in situ, estimated, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(58, 14,NULL, 6, 74, 1, 0, 'QP', 'T', 2.228009237e-06, 0, 'Flow rate of well, gallons per minute');
insert into CWMS_USGS_PARAMETER values(90, 29,'Reduction-Potential', 6, 22, 0.001, 0, NULL, NULL, NULL, NULL, 'Oxidation reduction potential, reference electrode not specified, millivolts');
insert into CWMS_USGS_PARAMETER values(32318, 5,'Chlorophylls', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophylls, water, in situ, fluorometric method, excitation at 470 +-15 nm, emission at 685 +-20 nm, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(72125, 20,'WaterVapor', 6, 63, 1, 0, NULL, NULL, NULL, NULL, 'Atmospheric water vapor pressure, calculated, kilopascals');
insert into CWMS_USGS_PARAMETER values(96, 5,'Salt', 6, 51, 1000, 0, 'WC', 'T', 1, 0, 'Salinity, water, unfiltered, milligrams per milliliter at 25 degrees Celsius');
insert into CWMS_USGS_PARAMETER values(630, 5,'Nitrate+NitriteAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Nitrate plus nitrite, water, unfiltered, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(608, 5,'AmmoniaAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Ammonia, water, filtered, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(32286, 5,'Chlorophyll-A-Cyanobacteria', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, cyanobacteria, in situ, fluorescence excitation at 370, 470, 525, 570, 590, 610 nm, fluorescence emission at 700 nm with correction for CDOM, ug/L');
insert into CWMS_USGS_PARAMETER values(32287, 5,'Chlorophyll-A-Cryptophytes', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, cryptophytes, in situ, fluorescence excitation at 370, 470, 525, 570, 590, 610 nm, fluorescence emission at 700 nm with correction for CDOM, ug/L');
insert into CWMS_USGS_PARAMETER values(32288, 5,'Chlorophyll-A-Dia+Dino', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, diatoms and dinoflagellates, in situ, excitation at 370, 470, 525, 570, 590, 610 nm, fluorescence emission at 700 nm with correction for CDOM, ug/L');
insert into CWMS_USGS_PARAMETER values(32289, 5,'CDOM', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Colored dissolved organic matter (CDOM), in situ, fluorescence excitation at 370, 470, 525, 570, 590, 610 nm, fluorescence emission at 700 nm, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(50415, 36,'ObsToBottom', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Distance, observation point to stream bottom, feet');
insert into CWMS_USGS_PARAMETER values(72199, 9,'Water', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Water depth, water surface to bottom, feet');
insert into CWMS_USGS_PARAMETER values(72200, 12,NULL, 6, 40, 1, 0, 'EP', 'F', 1, 0, 'Evaporation per recording interval, millimeters');
insert into CWMS_USGS_PARAMETER values(625, 5,'AmmoniaAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Ammonia plus organic nitrogen, water, unfiltered, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(72151, 20,'WaterColumn', 6, 66, 1, 0, NULL, NULL, NULL, NULL, 'Water column pressure, pounds per square inch');
insert into CWMS_USGS_PARAMETER values(72152, 27,'Exposure-Wet', 6, 21, 1, 0, NULL, NULL, NULL, NULL, 'Collector wet exposure (time within recording interval that collector is open when it should be open), seconds');
insert into CWMS_USGS_PARAMETER values(72153, 27,'Exposure-Dry', 6, 21, 1, 0, NULL, NULL, NULL, NULL, 'Collector dry exposure (time within recording interval that collector is open but should be closed), seconds');
insert into CWMS_USGS_PARAMETER values(72158, 7,'LidCycles', 6, 17, 1, 0, NULL, NULL, NULL, NULL, 'Collector lid cycles in recording interval, number');
insert into CWMS_USGS_PARAMETER values(80180, 5,'Sediment', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Total sediment concentration, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(81904, 22,'Index', 6, 41, 1, 0, 'QF', 'T', 0.681818, 0, 'Velocity at point in stream, feet per second');
insert into CWMS_USGS_PARAMETER values(99220, 5,'Chloride', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Chloride, water, unfiltered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(99401, 5,'DissolvedSolids', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Dissolved solids, water, filtered, estimated by regression equation, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(99910, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(8, 7,'SampleAcctNum', 6, 17, 1, 0, NULL, NULL, NULL, NULL, 'Sample accounting number');
insert into CWMS_USGS_PARAMETER values(72175, 32,'Longwave-Down', 6, 31, 1, 0, NULL, NULL, NULL, NULL, 'Longwave radiation, downward intensity, watts per square meter');
insert into CWMS_USGS_PARAMETER values(950, 5,'Fluoride', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Fluoride, water, filtered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(32319, 5,'Phycocyanins', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Phycocyanins (cyanobacteria), water, in situ, fluorometric method, excitation at 590 +-15 nm, emission at 685 +-20 nm, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(72174, 32,'Longwave-Up', 6, 31, 1, 0, NULL, NULL, NULL, NULL, 'Longwave radiation, upward intensity, watts per square meter');
insert into CWMS_USGS_PARAMETER values(9, 36,'XSec', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Location in cross section, distance from left bank looking downstream, feet');
insert into CWMS_USGS_PARAMETER values(53, 2,NULL, 6, 4, 1, 0, 'LA', 'T', 0.001, 0, 'Surface area, acres');
insert into CWMS_USGS_PARAMETER values(193, 19,NULL, 1, 36, 1, 0, 'PP', 'T', 1, 0, 'Precipitation total for defined period, inches');
insert into CWMS_USGS_PARAMETER values(45700, 16,'TotalAllGages', 6, 35, 1, 0, 'NG', 'T', 1, 0, 'Gate openings, reservoir, all gates, feet');
insert into CWMS_USGS_PARAMETER values(72120, 1,'Full-Total', 6, 53, 1, 0, NULL, NULL, NULL, NULL, 'Reservoir storage, total pool, percent of capacity');
insert into CWMS_USGS_PARAMETER values(72148, 9,'Sensor', 6, 38, 1, 0, NULL, NULL, NULL, NULL, 'Depth of sensor below water surface, meters');
insert into CWMS_USGS_PARAMETER values(72198, 9,'Snow', 6, 35, 1, 0, 'SD', 'T', 12, 0, 'Snow depth, feet');
insert into CWMS_USGS_PARAMETER values(99064, 45,NULL, 6, 35, 1, 0, 'HD', 'T', 1, 0, 'Water surface elevation difference between two locations, feet');
insert into CWMS_USGS_PARAMETER values(99404, 5,'Chloride', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Chloride, water, filtered, estimated by regression equation, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(99902, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99909, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(72, 23,NULL, 6, 38, 1, 0, 'HG', 'F', 1, 0, 'Stream stage, meters');
insert into CWMS_USGS_PARAMETER values(671, 5,'OrthophosphateAsP', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Orthophosphate, water, filtered, milligrams per liter as phosphorus');
insert into CWMS_USGS_PARAMETER values(61727, 22,'Wind-Gust', 6, 48, 1.15078, 0, 'UG', 'T', 1.15078, 0, 'Wind gust speed, air, knots');
insert into CWMS_USGS_PARAMETER values(72121, 1,'Full-Active', 6, 53, 1, 0, NULL, NULL, NULL, NULL, 'Reservoir storage, live pool, percent of capacity');
insert into CWMS_USGS_PARAMETER values(72156, 27,'Scan', 6, 21, 1, 0, NULL, NULL, NULL, NULL, 'Datalogger scan time per recording interval, seconds');
insert into CWMS_USGS_PARAMETER values(72185, 32,'Shortwave-Up', 6, 31, 1, 0, NULL, NULL, NULL, NULL, 'Shortwave radiation, upward intensity, watts per square meter');
insert into CWMS_USGS_PARAMETER values(72186, 32,'Shortwave-Down', 6, 31, 1, 0, NULL, NULL, NULL, NULL, 'Shortwave radiation, downward intensity, watts per square meter');
insert into CWMS_USGS_PARAMETER values(82127, 22,'Wind', 6, 48, 1.15078, 0, 'US', 'T', 1.15078, 0, 'Wind speed, knots');
insert into CWMS_USGS_PARAMETER values(99020, 10,NULL, 6, 38, 1, 0, 'HP', 'F', 1, 0, 'Elevation above NGVD 1929, meters');
insert into CWMS_USGS_PARAMETER values(99901, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99987, 21,'Total', 6, 32, 1000000, 0, 'RI', 'T', 23.900574, 0, 'Solar radiation (total flux density on a horizontal surface during measurement interval), megajoules per square meter');
insert into CWMS_USGS_PARAMETER values(30, 32,NULL, 6, 30, 0, 0, NULL, NULL, NULL, NULL, 'Incident solar radiation intensity, calories per square centimeter per day');
insert into CWMS_USGS_PARAMETER values(61, 14,NULL, 6, 72, 1, 0, 'QR', 'T', 0.001, 0, 'Discharge, instantaneous, cubic feet per second');
insert into CWMS_USGS_PARAMETER values(931, 37,'SodiumAdsorption', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Sodium adsorption ratio, water, number');
insert into CWMS_USGS_PARAMETER values(30211, 10,NULL, 6, 38, 1, 0, 'HP', 'F', 1, 0, 'Elevation above NGVD 1929, meters');
insert into CWMS_USGS_PARAMETER values(32290, 1,'FlourescenceXmit', 6, 53, 1, 0, NULL, NULL, NULL, NULL, 'Fluorescence transmission (transparency to fluorescence) at 700 nm, percent');
insert into CWMS_USGS_PARAMETER values(32325, 7,'DarkMeas', 5, 17, 1, 0, NULL, NULL, NULL, NULL, 'Dark measurement spectral average, water, in situ, ultraviolet nitrate analyzer, raw counts');
insert into CWMS_USGS_PARAMETER values(32326, 7,'LightMeas', 5, 17, 1, 0, NULL, NULL, NULL, NULL, 'Light measurement spectral average, water, in situ, ultraviolet nitrate analyzer, raw counts');
insert into CWMS_USGS_PARAMETER values(50052, 39,NULL, 1, 83, 1, 0, 'QV', 'T', 3.0688833e-06, 0, 'Flow total during composite period, thousands of gallons');
insert into CWMS_USGS_PARAMETER values(65231, 5,'ChlorophyllA', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, water, in situ, in vivo fluorescence, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(70301, 5,'DissolvedSolids', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Dissolved solids, water, filtered, sum of constituents, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(70507, 5,'OrthophosphateAsP', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Orthophosphate, water, unfiltered, milligrams per liter as phosphorus');
insert into CWMS_USGS_PARAMETER values(70953, 5,'ChlorophyllAPhytoplankton', 6, 51, 0.001, 0, NULL, NULL, NULL, NULL, 'Chlorophyll a, phytoplankton, chromatographic-fluorometric method, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(72126, 3,'Wind-StdDev', 6, 1, 1, 0, 'UE', 'T', 1, 0, 'Standard deviation of wind direction, degrees');
insert into CWMS_USGS_PARAMETER values(72176, 25,'Sencosr', 6, 67, 1, 0, NULL, NULL, NULL, NULL, 'Temperature of sensor, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(72204, 20,NULL, 6, 66, 1, 0, 'PA', 'T', 2.041768, 0, 'Barometric pressure (BP), uncorrected, pounds per square inch');
insert into CWMS_USGS_PARAMETER values(99067, 10,'PredictionError', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Difference between observed and predicted water surface elevation, feet');
insert into CWMS_USGS_PARAMETER values(99232, 27,'SoilMoistureContentPeriod', 6, 21, 0.001, 0, NULL, NULL, NULL, NULL, 'Volumetric soil moisture content period, for internal control of sensor, milliseconds');
insert into CWMS_USGS_PARAMETER values(99241, 36,'ADCPCellEnd', 6, 38, 1, 0, NULL, NULL, NULL, NULL, 'Location of Acoustic Doppler Velocity Meter cell end, meters');
insert into CWMS_USGS_PARAMETER values(99900, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99903, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99904, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99905, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99906, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99907, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(59, 14,NULL, 6, 74, 1, 0, 'QP', 'T', 2.228009237e-06, 0, 'Flow rate, instantaneous, gallons per minute');
insert into CWMS_USGS_PARAMETER values(403, 17,NULL, 6, 29, 1, 0, 'WP', 'T', 1, 0, 'pH, water, unfiltered, laboratory, standard units');
insert into CWMS_USGS_PARAMETER values(600, 5,'Nitrogen-Total', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Total nitrogen [nitrate + nitrite + ammonia + organic-N], water, unfiltered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(618, 5,'NitrageAsN', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Nitrate, water, filtered, milligrams per liter as nitrogen');
insert into CWMS_USGS_PARAMETER values(1046, 5,'Iron', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Iron, water, filtered, micrograms per liter');
insert into CWMS_USGS_PARAMETER values(30215, 7,'Signal', 6, 17, 1, 0, NULL, NULL, NULL, NULL, 'Signal, sediment, Markland meter, count');
insert into CWMS_USGS_PARAMETER values(50011, 25,'VentGas', 6, 67, 1, 0, NULL, NULL, NULL, NULL, 'Temperature, vent gas, volcanic, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(72106, 10,'Sample', 6, 35, 1, 0, NULL, NULL, NULL, NULL, 'Elevation of sample, feet');
insert into CWMS_USGS_PARAMETER values(72154, 27,'ExposureMissed', 6, 21, 1, 0, NULL, NULL, NULL, NULL, 'Collector missed exposure (time within recording interval that collector is closed but should be open), seconds');
insert into CWMS_USGS_PARAMETER values(72189, 9,'Snow', 6, 38, 1, 0, 'SD', 'F', 100, 0, 'Snow depth, meters');
insert into CWMS_USGS_PARAMETER values(72202, 32,'Longwave-Net', 6, 31, 1, 0, NULL, NULL, NULL, NULL, 'Net emitted longwave radiation, watts per square meter');
insert into CWMS_USGS_PARAMETER values(72240, 5,'CO', 6, 52, 1, 0, NULL, NULL, NULL, NULL, 'Carbon dioxide, water, dissolved, at the water surface, parts per million by volume of dissolved gases');
insert into CWMS_USGS_PARAMETER values(99246, 5,'Limit-Upper90%', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Upper 90 percent prediction limit for SSC by regression (PCODE 99409), milligrams per liter');
insert into CWMS_USGS_PARAMETER values(99247, 5,'Lower-Upper90%', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Lower 90 percent prediction limit for SSC by regression (PCODE 99409), milligrams per liter');
insert into CWMS_USGS_PARAMETER values(67, 4,'Stage-Tide', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Tide stage, code');
insert into CWMS_USGS_PARAMETER values(535, 5,'SuspSolids-IgnitionLoss', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Loss on ignition of suspended solids, water, unfiltered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(540, 5,'SuspSolids-AfterIgnition', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Suspended solids remaining after ignition, water, unfiltered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(930, 5,'Sodium', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Sodium, water, filtered, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(45586, 7,'Lockage', 6, 17, 1, 0, NULL, NULL, NULL, NULL, 'Lockage, count of lock openings, units');
insert into CWMS_USGS_PARAMETER values(45589, 25,'Shelter', 6, 67, 1, 0, NULL, NULL, NULL, NULL, 'Temperature, internal, within equipment shelter, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(46529, 19,NULL, 6, 36, 1, 0, 'PC', 'T', 1, 0, 'Precipitation, inches');
insert into CWMS_USGS_PARAMETER values(50042, 14,NULL, 6, 74, 1, 0, 'QR', 'T', 2.228009237e-06, 0, 'Discharge, gallons per minute');
insert into CWMS_USGS_PARAMETER values(50050, 14,NULL, 6, 76, 1, 0, NULL, NULL, NULL, NULL, 'Flow, in conduit or through a treatment plant, million gallons per day');
insert into CWMS_USGS_PARAMETER values(72004, 27,'BeforeSample', 6, 20, 1, 0, NULL, NULL, NULL, NULL, 'Pump or flow period prior to sampling, minutes');
insert into CWMS_USGS_PARAMETER values(72130, 13,'Potential', 6, 47, 1, 0, NULL, NULL, NULL, NULL, 'Potential evapotranspiration (PET), calculated by Penman method, millimeters per hour');
insert into CWMS_USGS_PARAMETER values(72135, 13,NULL, 6, 42, 1, 0, NULL, NULL, NULL, NULL, 'Evapotranspiration total, inches per day');
insert into CWMS_USGS_PARAMETER values(72155, 27,'Blocked', 6, 21, 1, 0, NULL, NULL, NULL, NULL, 'Blocked optical sensor (time within recording interval that optical sensor is blocked), seconds');
insert into CWMS_USGS_PARAMETER values(72157, 7,'Particle', 1, 17, 1, 0, NULL, NULL, NULL, NULL, 'Optical sensor particle counts within recording interval, number');
insert into CWMS_USGS_PARAMETER values(72253, 25,'Soil', 6, 67, 1, 0, 'TS', 'F', 1, 0, 'Soil temperature, degrees Celsius');
insert into CWMS_USGS_PARAMETER values(75972, 29,'Signal', 6, 22, 0.001, 0, NULL, NULL, NULL, NULL, 'Transducer signal, depth sensing, millivolts');
insert into CWMS_USGS_PARAMETER values(99398, 5,'Sodium', 6, 51, 1, 0, NULL, NULL, NULL, NULL, 'Sodium, water, filtered, estimated by regression equation, milligrams per liter');
insert into CWMS_USGS_PARAMETER values(99908, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');
insert into CWMS_USGS_PARAMETER values(99917, 4,'LoggedDate-yyddd', 6, 54, 1, 0, NULL, NULL, NULL, NULL, 'Julian date sample logged into the Ocala Laboratory, yyddd');


    insert into CWMS_ENTITY_CATEGORY values('GOV', 'Government entities including military');
    insert into CWMS_ENTITY_CATEGORY values('ORG', 'Non-governmental organization entities');
    insert into CWMS_ENTITY_CATEGORY values('EDU', 'Educational entities');
    insert into CWMS_ENTITY_CATEGORY values('COM', 'Commercial entities');



    insert into AT_ENTITY values(1,NULL,53,NULL,'OTHER','Unknown or unspecified entity');
    insert into AT_ENTITY values(2,NULL,53,'GOV','USACE','U.S. Army Corps of Engineers');
    insert into AT_ENTITY values(3,NULL,53,'GOV','NOAA','National Oceanic and Atmospheric Administration');
    insert into AT_ENTITY values(4,3,53,'GOV','NWS','National Weather Service');
    insert into AT_ENTITY values(5,NULL,53,'GOV','USGS','United States Geological Survey');
    insert into AT_ENTITY values(6,NULL,53,'GOV','USBR','United States Bureau of Reclamation');
    insert into AT_ENTITY values(7,NULL,53,'GOV','NRCS','Natural Resources Conservation Service');
    insert into AT_ENTITY values(8,NULL,53,'GOV','FEMA','Federal Emergency Management Agency');
    insert into AT_ENTITY values(9,NULL,53,'GOV','EPA','United States Environmental Protection Agency');
    insert into AT_ENTITY values(10,2,53,'GOV','CELRD','USACE Great Lakes and Ohio River Division');
    insert into AT_ENTITY values(11,2,53,'GOV','CEMVD','USACE Mississippi Valley Division');
    insert into AT_ENTITY values(12,2,53,'GOV','CENAD','USACE North Atlantic Division');
    insert into AT_ENTITY values(13,2,53,'GOV','CENWD','USACE Northwestern Division');
    insert into AT_ENTITY values(14,2,53,'GOV','CEPOD','USACE Pacific Ocean Division');
    insert into AT_ENTITY values(15,2,53,'GOV','CESAD','USACE South Atlantic Division');
    insert into AT_ENTITY values(16,2,53,'GOV','CESPD','USACE South Pacific Division');
    insert into AT_ENTITY values(17,2,53,'GOV','CESWD','USACE Southwestern Division');
    insert into AT_ENTITY values(18,2,53,'GOV','CEERD','USACE Engineer Research and Development Center');
    insert into AT_ENTITY values(19,2,53,'GOV','CEIWR','USACE Institute for Water Resources');
    insert into AT_ENTITY values(20,10,53,'GOV','CELRDG','USACE Great Lakes Region');
    insert into AT_ENTITY values(21,10,53,'GOV','CELRDO','USACE Ohio River Region');
    insert into AT_ENTITY values(22,20,53,'GOV','CELRC','USACE Chicago District');
    insert into AT_ENTITY values(23,20,53,'GOV','CELRE','USACE Detroit District');
    insert into AT_ENTITY values(24,20,53,'GOV','CELRB','USACE Buffalo District');
    insert into AT_ENTITY values(25,21,53,'GOV','CELRH','USACE Huntington District');
    insert into AT_ENTITY values(26,21,53,'GOV','CELRL','USACE Louisville District');
    insert into AT_ENTITY values(27,21,53,'GOV','CELRN','USACE Nashville District');
    insert into AT_ENTITY values(28,21,53,'GOV','CELRP','USACE Pittsburgh District');
    insert into AT_ENTITY values(29,11,53,'GOV','CEMVK','USACE Vicksburg District');
    insert into AT_ENTITY values(30,11,53,'GOV','CEMVM','USACE Memphis District');
    insert into AT_ENTITY values(31,11,53,'GOV','CEMVN','USACE New Orleans District');
    insert into AT_ENTITY values(32,11,53,'GOV','CEMVP','USACE St. Paul District');
    insert into AT_ENTITY values(33,11,53,'GOV','CEMVR','USACE Rock Island District');
    insert into AT_ENTITY values(34,11,53,'GOV','CEMVS','USACE St. Louis District');
    insert into AT_ENTITY values(35,12,53,'GOV','CENAB','USACE Baltimore District');
    insert into AT_ENTITY values(36,12,53,'GOV','CENAE','USACE New England District');
    insert into AT_ENTITY values(37,12,53,'GOV','CENAN','USACE New York District');
    insert into AT_ENTITY values(38,12,53,'GOV','CENAO','USACE Norfolk District');
    insert into AT_ENTITY values(39,12,53,'GOV','CENAP','USACE Philadelphia District');
    insert into AT_ENTITY values(40,13,53,'GOV','CENWDP','USACE Pacific Northwest Region');
    insert into AT_ENTITY values(41,13,53,'GOV','CENWDM','USACE Missouri River Region');
    insert into AT_ENTITY values(42,40,53,'GOV','CENWP','USACE Portland District');
    insert into AT_ENTITY values(43,40,53,'GOV','CENWS','USACE Seattle District');
    insert into AT_ENTITY values(44,40,53,'GOV','CENWW','USACE Walla Walla District');
    insert into AT_ENTITY values(45,41,53,'GOV','CENWK','USACE Kansas City District');
    insert into AT_ENTITY values(46,41,53,'GOV','CENWO','USACE Omaha District');
    insert into AT_ENTITY values(47,14,53,'GOV','CEPOA','USACE Alaska District');
    insert into AT_ENTITY values(48,14,53,'GOV','CEPOH','USACE Hawaii District');
    insert into AT_ENTITY values(49,15,53,'GOV','CESAC','USACE Charleston District');
    insert into AT_ENTITY values(50,15,53,'GOV','CESAJ','USACE Jacksonville District');
    insert into AT_ENTITY values(51,15,53,'GOV','CESAM','USACE Mobile District');
    insert into AT_ENTITY values(52,15,53,'GOV','CESAS','USACE Savannah District');
    insert into AT_ENTITY values(53,15,53,'GOV','CESAW','USACE Wilmington District');
    insert into AT_ENTITY values(54,16,53,'GOV','CESPA','USACE Albuquerque District');
    insert into AT_ENTITY values(55,16,53,'GOV','CESPK','USACE Sacramento District');
    insert into AT_ENTITY values(56,16,53,'GOV','CESPL','USACE Los Angeles District');
    insert into AT_ENTITY values(57,16,53,'GOV','CESPN','USACE San Francisco District');
    insert into AT_ENTITY values(58,17,53,'GOV','CESWF','USACE Fort Worth District');
    insert into AT_ENTITY values(59,17,53,'GOV','CESWG','USACE Galveston District');
    insert into AT_ENTITY values(60,17,53,'GOV','CESWL','USACE Little Rock District');
    insert into AT_ENTITY values(61,17,53,'GOV','CESWT','USACE Tulsa District');
    insert into AT_ENTITY values(62,18,53,'GOV','CEERD-CRREL','USACE Cold Regions Research and Engineering Lab');
    insert into AT_ENTITY values(63,18,53,'GOV','CEERD-CHL','USACE Coastal and Hydraulics Laboratory');
    insert into AT_ENTITY values(64,18,53,'GOV','CEERD-CERL','USACE Construction Engineering Research Laboratory');
    insert into AT_ENTITY values(65,18,53,'GOV','CEERD-EL','USACE Environmental Laboratory');
    insert into AT_ENTITY values(66,18,53,'GOV','CEERD-GSL','USACE Geotechnical and Structures Laboratory');
    insert into AT_ENTITY values(67,18,53,'GOV','CEERD-ITL','USACE Information Technology Laboratory');
    insert into AT_ENTITY values(68,18,53,'GOV','CEERD-TEC','USACE Topographic Engineering Center');
    insert into AT_ENTITY values(69,19,53,'GOV','CEIWR-NDC','USACE Navigation Data Center');
    insert into AT_ENTITY values(70,19,53,'GOV','CEIWR-HEC','USACE Hydrologic Engineering Center');
    insert into AT_ENTITY values(71,19,53,'GOV','CEIWR-WCSC','USACE Waterborne Commerce Statistics Center');
    insert into AT_ENTITY values(72,4,53,'GOV','ABRFC','NWS Arkansas-Red Basin River Forecast Center');
    insert into AT_ENTITY values(73,4,53,'GOV','APRFC','NWS Alaska-Pacific River Forecast Center');
    insert into AT_ENTITY values(74,4,53,'GOV','CBRFC','NWS Colorado Basin River Forecast Center');
    insert into AT_ENTITY values(75,4,53,'GOV','CNRFC','NWS California-Nevada River Forecast Center');
    insert into AT_ENTITY values(76,4,53,'GOV','LMRFC','NWS Lower Mississippi River Forecast Center');
    insert into AT_ENTITY values(77,4,53,'GOV','MARFC','NWS Middle Atlantic River Forecast Center');
    insert into AT_ENTITY values(78,4,53,'GOV','MBRFC','NWS Missouri Basin River Forecast Center');
    insert into AT_ENTITY values(79,4,53,'GOV','NCRFC','NWS North Central River Forecast Center');
    insert into AT_ENTITY values(80,4,53,'GOV','NERFC','NWS Northeast River Forecast Center');
    insert into AT_ENTITY values(81,4,53,'GOV','NWRFC','NWS Northwest River Forecast Center');
    insert into AT_ENTITY values(82,4,53,'GOV','OHRFC','NWS Ohio River Forecast Center');
    insert into AT_ENTITY values(83,4,53,'GOV','SERFC','NWS Southeast River Forecast Center');
    insert into AT_ENTITY values(84,4,53,'GOV','WGRFC','NWS West Gulf River Forecast Center');
    insert into AT_ENTITY values(85,NULL,53,'GOV','AK','State of Alaska');
    insert into AT_ENTITY values(86,NULL,53,'GOV','AL','State of Alabama');
    insert into AT_ENTITY values(87,NULL,53,'GOV','AR','State of Arkansas');
    insert into AT_ENTITY values(88,NULL,53,'GOV','AZ','State of Arizona');
    insert into AT_ENTITY values(89,NULL,53,'GOV','CA','State of California');
    insert into AT_ENTITY values(90,NULL,53,'GOV','CO','State of Colorado');
    insert into AT_ENTITY values(91,NULL,53,'GOV','CT','State of Connecticut');
    insert into AT_ENTITY values(92,NULL,53,'GOV','DE','State of Delaware');
    insert into AT_ENTITY values(93,NULL,53,'GOV','FL','State of Florida');
    insert into AT_ENTITY values(94,NULL,53,'GOV','GA','State of Georgia');
    insert into AT_ENTITY values(95,NULL,53,'GOV','HI','State of Hawaii');
    insert into AT_ENTITY values(96,NULL,53,'GOV','IA','State of Iowa');
    insert into AT_ENTITY values(97,NULL,53,'GOV','ID','State of Idaho');
    insert into AT_ENTITY values(98,NULL,53,'GOV','IL','State of Illinois');
    insert into AT_ENTITY values(99,NULL,53,'GOV','IN','State of Indiana');
    insert into AT_ENTITY values(100,NULL,53,'GOV','KS','State of Kansas');
    insert into AT_ENTITY values(101,NULL,53,'GOV','KY','Commonwealth of Kentucky');
    insert into AT_ENTITY values(102,NULL,53,'GOV','LA','State of Louisiana');
    insert into AT_ENTITY values(103,NULL,53,'GOV','MA','Commonwealth of Massachusetts');
    insert into AT_ENTITY values(104,NULL,53,'GOV','MD','State of Maryland');
    insert into AT_ENTITY values(105,NULL,53,'GOV','ME','State of Maine');
    insert into AT_ENTITY values(106,NULL,53,'GOV','MI','State of Michigan');
    insert into AT_ENTITY values(107,NULL,53,'GOV','MN','State of Minnesota');
    insert into AT_ENTITY values(108,NULL,53,'GOV','MO','State of Missouri');
    insert into AT_ENTITY values(109,NULL,53,'GOV','MS','State of Mississippi');
    insert into AT_ENTITY values(110,NULL,53,'GOV','MT','State of Montana');
    insert into AT_ENTITY values(111,NULL,53,'GOV','NC','State of North Carolina');
    insert into AT_ENTITY values(112,NULL,53,'GOV','ND','State of North Dakota');
    insert into AT_ENTITY values(113,NULL,53,'GOV','NE','State of Nebraska');
    insert into AT_ENTITY values(114,NULL,53,'GOV','NH','State of New Hampshire');
    insert into AT_ENTITY values(115,NULL,53,'GOV','NJ','State of New Jersey');
    insert into AT_ENTITY values(116,NULL,53,'GOV','NM','State of New Mexico');
    insert into AT_ENTITY values(117,NULL,53,'GOV','NV','State of Nevada');
    insert into AT_ENTITY values(118,NULL,53,'GOV','NY','State of New York');
    insert into AT_ENTITY values(119,NULL,53,'GOV','OH','State of Ohio');
    insert into AT_ENTITY values(120,NULL,53,'GOV','OK','State of Oklahoma');
    insert into AT_ENTITY values(121,NULL,53,'GOV','OR','State of Oregon');
    insert into AT_ENTITY values(122,NULL,53,'GOV','PA','Commonwealth of Pennsylvania');
    insert into AT_ENTITY values(123,NULL,53,'GOV','PR','Commonwealth of Puerto Rico');
    insert into AT_ENTITY values(124,NULL,53,'GOV','RI','State of Rhode Island');
    insert into AT_ENTITY values(125,NULL,53,'GOV','SC','State of South Carolina');
    insert into AT_ENTITY values(126,NULL,53,'GOV','SD','State of South Dakota');
    insert into AT_ENTITY values(127,NULL,53,'GOV','TN','State of Tennessee');
    insert into AT_ENTITY values(128,NULL,53,'GOV','TX','State of Texas');
    insert into AT_ENTITY values(129,NULL,53,'GOV','UT','State of Utah');
    insert into AT_ENTITY values(130,NULL,53,'GOV','VA','Commonwealth of Virginia');
    insert into AT_ENTITY values(131,NULL,53,'GOV','VT','State of Vermont');
    insert into AT_ENTITY values(132,NULL,53,'GOV','WA','State of Washington');
    insert into AT_ENTITY values(133,NULL,53,'GOV','WI','State of Wisconsin');
    insert into AT_ENTITY values(134,NULL,53,'GOV','WV','State of West Virginia');
    insert into AT_ENTITY values(135,NULL,53,'GOV','WY','State of Wyoming');
    insert into AT_ENTITY values(136,NULL,53,'GOV','APA','Alaska Power Administration');
    insert into AT_ENTITY values(137,NULL,53,'GOV','BPA','Bonneville Power Administration');
    insert into AT_ENTITY values(138,NULL,53,'GOV','SEPA','Southeastern Power Administration');
    insert into AT_ENTITY values(139,NULL,53,'GOV','SWPA','Southwestern Power Administration');
    insert into AT_ENTITY values(140,NULL,53,'GOV','WAPA','Western Area Power Administration');
    insert into AT_ENTITY values(141,NULL,53,'GOV','TVA','Tennessee Valley Authority');



    insert into CWMS_CONFIG_CATEGORY values('GENERAL', 'General purpose configurations');
    insert into CWMS_CONFIG_CATEGORY values('MODELING', 'Modeling configurations');
    insert into CWMS_CONFIG_CATEGORY values('DATA RETRIEVAL', 'Data Retrieval configurations');



    insert into AT_CONFIGURATION values(1,NULL,53,'GENERAL','OTHER','Generic general purpose');
    insert into AT_CONFIGURATION values(2,NULL,53,'MODELING','CWMS','Generalized CWMS modeling');
    insert into AT_CONFIGURATION values(3,2,53,'MODELING','CWMS-METVue','CWMS METVue modeling');
    insert into AT_CONFIGURATION values(4,2,53,'MODELING','CWMS-HMS','CWMS HMS modeling');
    insert into AT_CONFIGURATION values(5,2,53,'MODELING','CWMS-ResSim','CWMS ResSim modeling');
    insert into AT_CONFIGURATION values(6,2,53,'MODELING','CWMS-RAS','CWMS RAS modeling');
    insert into AT_CONFIGURATION values(7,2,53,'MODELING','CWMS-FIA','CWMS FIA modeling');
    insert into AT_CONFIGURATION values(8,2,53,'MODELING','CWMS-RiverWare','CWMS RiverWare modeling');
    insert into AT_CONFIGURATION values(9,NULL,53,'DATA RETRIEVAL','Other Data Retrieval','Generalized Data Retreival');
    insert into AT_CONFIGURATION values(10,9,53,'DATA RETRIEVAL','USGS Data Retrieval','USGS Data Retreival');



    insert into CWMS_GATE_TYPE values( 1, 'OTHER',          'Unknown or unspecified gate type');
    insert into CWMS_GATE_TYPE values( 2, 'CLAMSHELL',      'Gate whose upper and lower halves separate to open');
    insert into CWMS_GATE_TYPE values( 3, 'CREST',          'Gate that increases the crest elevation when raised');
    insert into CWMS_GATE_TYPE values( 4, 'DRUM',           'Hollow cylindrical section shaped crest gate hinged at the axis that floats on an adjustable amount of water in a chamber');
    insert into CWMS_GATE_TYPE values( 5, 'FUSE',           'Non-adjustable gate that is designed to fail (open) at a specific head');
    insert into CWMS_GATE_TYPE values( 6, 'INFLATABLE',     'Crest gate that is inflated to form a weir');
    insert into CWMS_GATE_TYPE values( 7, 'MITER',          'Doors hinged on opposite sides of a walled channel that meet in the center at an angle and are held closed by water pressure');
    insert into CWMS_GATE_TYPE values( 8, 'NEEDLE',         'Flow-through gate that is controlled by placing various numbers of boards (needles) vertically in a support structure');
    insert into CWMS_GATE_TYPE values( 9, 'RADIAL',         'Cylindrical section shaped gate hinged at the axis that passes water underneath when open');
    insert into CWMS_GATE_TYPE values(10, 'ROLLER',         'Cylindrical crest gate that rolls in cogged slots in piers at each end to control its height');
    insert into CWMS_GATE_TYPE values(11, 'STOPLOG',        'Crest gate whose height is controlled by varying the number of horizontal boards (logs) stacked between piers');
    insert into CWMS_GATE_TYPE values(12, 'VALVE',          'Small gate for passing small and precisely controlled amounts of water');
    insert into CWMS_GATE_TYPE values(13, 'VERTICAL SLIDE', 'Flat gate that slides vertically in tracks (with or without rollers) for control');
    insert into CWMS_GATE_TYPE values(14, 'WICKET',         'A group of small connected hinged gates (wickets) that overlap when closed and rotate together to open');



    insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('LOCATION_LEVEL');
    insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('RATING');
    insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('TIME_SERIES');
    insert into CWMS_VLOC_LVL_CONSTITUENT_TYPE values ('FORMULA');



    CREATE OR REPLACE PROCEDURE CWMS_UNIT_CONVERSION_TEST
    IS
       L_PARAM CWMS_ABSTRACT_PARAMETER%ROWTYPE;
       L_FROM  CWMS_UNIT%ROWTYPE;
       L_TO    CWMS_UNIT%ROWTYPE;
       L_CONV  CWMS_UNIT_CONVERSION%ROWTYPE;
       L_COUNT PLS_INTEGER := 0;
       L_TOTAL PLS_INTEGER := 0;
    BEGIN
       DBMS_OUTPUT.PUT_LINE('*** CHECKING UNIT CONVERSIONS ***');
       FOR L_PARAM IN (SELECT * FROM CWMS_ABSTRACT_PARAMETER)
       LOOP
          L_COUNT := 0;
          DBMS_OUTPUT.PUT_LINE('.');
          DBMS_OUTPUT.PUT_LINE('.  Checking abstract parameter ' || L_PARAM.ABSTRACT_PARAM_ID);
          FOR L_FROM IN (SELECT * FROM CWMS_UNIT WHERE ABSTRACT_PARAM_CODE=L_PARAM.ABSTRACT_PARAM_CODE)
          LOOP
             FOR L_TO IN (SELECT * FROM CWMS_UNIT WHERE ABSTRACT_PARAM_CODE=L_PARAM.ABSTRACT_PARAM_CODE)
             LOOP
                BEGIN
                   SELECT *
                      INTO  L_CONV
                      FROM CWMS_UNIT_CONVERSION
                      WHERE FROM_UNIT_CODE = L_FROM.UNIT_CODE
                      AND   TO_UNIT_CODE = L_TO.UNIT_CODE;
                   DBMS_OUTPUT.PUT_LINE(
                       '.    "'
                       || L_FROM.UNIT_ID
                       || '","'
                       || L_TO.UNIT_ID
                       || '",'
                       || L_CONV.OFFSET
                       || ','
                       || L_CONV.FACTOR);
                   L_COUNT := L_COUNT + 1;
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      DBMS_OUTPUT.PUT_LINE(
                       '.    >>> No conversion from "'
                       || L_FROM.UNIT_ID
                       || '" to "'
                       || L_TO.UNIT_ID
                       || '".');
                   WHEN OTHERS THEN
                      RAISE;
                END;
             END LOOP;
          END LOOP;
          DBMS_OUTPUT.PUT_LINE('.  ' || L_COUNT || ' unit conversion entries.');
          L_TOTAL := L_TOTAL + L_COUNT;
       END LOOP;
       DBMS_OUTPUT.PUT_LINE('.');
       DBMS_OUTPUT.PUT_LINE('' || L_TOTAL || ' unit conversion entries.');
    END CWMS_UNIT_CONVERSION_TEST;
    /



    BEGIN CWMS_UNIT_CONVERSION_TEST; END;
    /

    DROP PROCEDURE CWMS_UNIT_CONVERSION_TEST;
