
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
           NAME          VARCHAR2(40)
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
           COUNTY_NAME VARCHAR2(40)
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
           ABSTRACT_PARAM_CODE NUMBER(14)         NOT NULL,
           ABSTRACT_PARAM_ID   VARCHAR2(32 BYTE)  NOT NULL
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
    -- CWMS_ABSTRACT_PARAMETER indicies
    --
    CREATE UNIQUE INDEX CWMS_ABSTRACT_PARAMETER_UI ON CWMS_ABSTRACT_PARAMETER
       (
           UPPER(ABSTRACT_PARAM_ID)
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
    -- CWMS_ABSTRACT_PARAMETER constraints
    --
    ALTER TABLE CWMS_ABSTRACT_PARAMETER ADD CONSTRAINT CWMS_ABSTRACT_PARAMETER_PK PRIMARY KEY (ABSTRACT_PARAM_CODE);

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
           UNIT_CODE           NUMBER(14)         NOT NULL,
           UNIT_ID             VARCHAR2(16 BYTE)  NOT NULL,
           ABSTRACT_PARAM_CODE NUMBER(14)         NOT NULL,
           UNIT_SYSTEM         VARCHAR2(2 BYTE),
           LONG_NAME           VARCHAR2(80 BYTE),
           DESCRIPTION         VARCHAR2(80 BYTE)
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
    -- CWMS_UNIT constraints
    --
    ALTER TABLE CWMS_UNIT ADD CONSTRAINT CWMS_UNIT_PK PRIMARY KEY (UNIT_CODE);
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


INSERT INTO CWMS_STATE VALUES (00, '00', 'Unknown State or State N/A');
INSERT INTO CWMS_STATE VALUES (01, 'AL', 'Alabama');
INSERT INTO CWMS_STATE VALUES (02, 'AK', 'Alaska');
INSERT INTO CWMS_STATE VALUES (04, 'AZ', 'Arizona');
INSERT INTO CWMS_STATE VALUES (05, 'AR', 'Arkansas');
INSERT INTO CWMS_STATE VALUES (06, 'CA', 'California');
INSERT INTO CWMS_STATE VALUES (08, 'CO', 'Colorado');
INSERT INTO CWMS_STATE VALUES (09, 'CT', 'Connecticut');
INSERT INTO CWMS_STATE VALUES (10, 'DE', 'Delaware');
INSERT INTO CWMS_STATE VALUES (11, 'DC', 'District of Columbia');
INSERT INTO CWMS_STATE VALUES (12, 'FL', 'Florida');
INSERT INTO CWMS_STATE VALUES (13, 'GA', 'Georgia');
INSERT INTO CWMS_STATE VALUES (15, 'HI', 'Hawaii');
INSERT INTO CWMS_STATE VALUES (16, 'ID', 'Idaho');
INSERT INTO CWMS_STATE VALUES (17, 'IL', 'Illinois');
INSERT INTO CWMS_STATE VALUES (18, 'IN', 'Indiana');
INSERT INTO CWMS_STATE VALUES (19, 'IA', 'Iowa');
INSERT INTO CWMS_STATE VALUES (20, 'KS', 'Kansas');
INSERT INTO CWMS_STATE VALUES (21, 'KY', 'Kentucky');
INSERT INTO CWMS_STATE VALUES (22, 'LA', 'Louisiana');
INSERT INTO CWMS_STATE VALUES (23, 'ME', 'Maine');
INSERT INTO CWMS_STATE VALUES (24, 'MD', 'Maryland');
INSERT INTO CWMS_STATE VALUES (25, 'MA', 'Massachusetts');
INSERT INTO CWMS_STATE VALUES (26, 'MI', 'Michigan');
INSERT INTO CWMS_STATE VALUES (27, 'MN', 'Minnesota');
INSERT INTO CWMS_STATE VALUES (28, 'MS', 'Mississippi');
INSERT INTO CWMS_STATE VALUES (29, 'MO', 'Missouri');
INSERT INTO CWMS_STATE VALUES (30, 'MT', 'Montana');
INSERT INTO CWMS_STATE VALUES (31, 'NE', 'Nebraska');
INSERT INTO CWMS_STATE VALUES (32, 'NV', 'Nevada');
INSERT INTO CWMS_STATE VALUES (33, 'NH', 'New Hampshire');
INSERT INTO CWMS_STATE VALUES (34, 'NJ', 'New Jersey');
INSERT INTO CWMS_STATE VALUES (35, 'NM', 'New Mexico');
INSERT INTO CWMS_STATE VALUES (36, 'NY', 'New York');
INSERT INTO CWMS_STATE VALUES (37, 'NC', 'North Carolina');
INSERT INTO CWMS_STATE VALUES (38, 'ND', 'North Dakota');
INSERT INTO CWMS_STATE VALUES (39, 'OH', 'Ohio');
INSERT INTO CWMS_STATE VALUES (40, 'OK', 'Oklahoma');
INSERT INTO CWMS_STATE VALUES (41, 'OR', 'Oregon');
INSERT INTO CWMS_STATE VALUES (42, 'PA', 'Pennsylvania');
INSERT INTO CWMS_STATE VALUES (44, 'RI', 'Rhode Island');
INSERT INTO CWMS_STATE VALUES (45, 'SC', 'South Carolina');
INSERT INTO CWMS_STATE VALUES (46, 'SD', 'South Dakota');
INSERT INTO CWMS_STATE VALUES (47, 'TN', 'Tennessee');
INSERT INTO CWMS_STATE VALUES (48, 'TX', 'Texas');
INSERT INTO CWMS_STATE VALUES (49, 'UT', 'Utah');
INSERT INTO CWMS_STATE VALUES (50, 'VT', 'Vermont');
INSERT INTO CWMS_STATE VALUES (51, 'VA', 'Virginia');
INSERT INTO CWMS_STATE VALUES (53, 'WA', 'Washington');
INSERT INTO CWMS_STATE VALUES (54, 'WV', 'West Virginia');
INSERT INTO CWMS_STATE VALUES (55, 'WI', 'Wisconsin');
INSERT INTO CWMS_STATE VALUES (56, 'WY', 'Wyoming');
INSERT INTO CWMS_STATE VALUES (60, 'AS', 'American Samoa');
INSERT INTO CWMS_STATE VALUES (66, 'GU', 'Guam');
INSERT INTO CWMS_STATE VALUES (68, 'MH', 'Marshall Islands');
INSERT INTO CWMS_STATE VALUES (69, 'MP', 'Northern Mariana Islands');
INSERT INTO CWMS_STATE VALUES (72, 'PR', 'Puerto Rico');
INSERT INTO CWMS_STATE VALUES (78, 'VI', 'Virgin Islands of the U.S.');
INSERT INTO CWMS_STATE VALUES (80, 'AB', 'Alberta');
INSERT INTO CWMS_STATE VALUES (81, 'BC', 'British Columbia');
INSERT INTO CWMS_STATE VALUES (82, 'MB', 'Manitoba');
INSERT INTO CWMS_STATE VALUES (83, 'NB', 'New Brunswick');
INSERT INTO CWMS_STATE VALUES (84, 'NF', 'Newfoundland');
INSERT INTO CWMS_STATE VALUES (85, 'NS', 'Nova Scotia');
INSERT INTO CWMS_STATE VALUES (86, 'NT', 'Northwest Territories');
INSERT INTO CWMS_STATE VALUES (87, 'NU', 'Nunavut');
INSERT INTO CWMS_STATE VALUES (88, 'ON', 'Ontario');
INSERT INTO CWMS_STATE VALUES (89, 'PE', 'Prince Edward Island');
INSERT INTO CWMS_STATE VALUES (90, 'QC', 'Quebec');
INSERT INTO CWMS_STATE VALUES (91, 'SK', 'Saskatchewan');
INSERT INTO CWMS_STATE VALUES (92, 'YT', 'Yukon');


INSERT INTO CWMS_COUNTY VALUES (
	0,
	'000',
	0,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	1000,
	'000',
	1,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	1001,
	'001',
	1,
	'Autauga'
);
INSERT INTO CWMS_COUNTY VALUES (
	1003,
	'003',
	1,
	'Baldwin'
);
INSERT INTO CWMS_COUNTY VALUES (
	1005,
	'005',
	1,
	'Barbour'
);
INSERT INTO CWMS_COUNTY VALUES (
	1007,
	'007',
	1,
	'Bibb'
);
INSERT INTO CWMS_COUNTY VALUES (
	1009,
	'009',
	1,
	'Blount'
);
INSERT INTO CWMS_COUNTY VALUES (
	1011,
	'011',
	1,
	'Bullock'
);
INSERT INTO CWMS_COUNTY VALUES (
	1013,
	'013',
	1,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	1015,
	'015',
	1,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	1017,
	'017',
	1,
	'Chambers'
);
INSERT INTO CWMS_COUNTY VALUES (
	1019,
	'019',
	1,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	1021,
	'021',
	1,
	'Chilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	1023,
	'023',
	1,
	'Choctaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	1025,
	'025',
	1,
	'Clarke'
);
INSERT INTO CWMS_COUNTY VALUES (
	1027,
	'027',
	1,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	1029,
	'029',
	1,
	'Cleburne'
);
INSERT INTO CWMS_COUNTY VALUES (
	1031,
	'031',
	1,
	'Coffee'
);
INSERT INTO CWMS_COUNTY VALUES (
	1033,
	'033',
	1,
	'Colbert'
);
INSERT INTO CWMS_COUNTY VALUES (
	1035,
	'035',
	1,
	'Conecuh'
);
INSERT INTO CWMS_COUNTY VALUES (
	1037,
	'037',
	1,
	'Coosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	1039,
	'039',
	1,
	'Covington'
);
INSERT INTO CWMS_COUNTY VALUES (
	1041,
	'041',
	1,
	'Crenshaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	1043,
	'043',
	1,
	'Cullman'
);
INSERT INTO CWMS_COUNTY VALUES (
	1045,
	'045',
	1,
	'Dale'
);
INSERT INTO CWMS_COUNTY VALUES (
	1047,
	'047',
	1,
	'Dallas'
);
INSERT INTO CWMS_COUNTY VALUES (
	1049,
	'049',
	1,
	'De Kalb'
);
INSERT INTO CWMS_COUNTY VALUES (
	1051,
	'051',
	1,
	'Elmore'
);
INSERT INTO CWMS_COUNTY VALUES (
	1053,
	'053',
	1,
	'Escambia'
);
INSERT INTO CWMS_COUNTY VALUES (
	1055,
	'055',
	1,
	'Etowah'
);
INSERT INTO CWMS_COUNTY VALUES (
	1057,
	'057',
	1,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	1059,
	'059',
	1,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	1061,
	'061',
	1,
	'Geneva'
);
INSERT INTO CWMS_COUNTY VALUES (
	1063,
	'063',
	1,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	1065,
	'065',
	1,
	'Hale'
);
INSERT INTO CWMS_COUNTY VALUES (
	1067,
	'067',
	1,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	1069,
	'069',
	1,
	'Houston'
);
INSERT INTO CWMS_COUNTY VALUES (
	1071,
	'071',
	1,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	1073,
	'073',
	1,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	1075,
	'075',
	1,
	'Lamar'
);
INSERT INTO CWMS_COUNTY VALUES (
	1077,
	'077',
	1,
	'Lauderdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	1079,
	'079',
	1,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	1081,
	'081',
	1,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	1083,
	'083',
	1,
	'Limestone'
);
INSERT INTO CWMS_COUNTY VALUES (
	1085,
	'085',
	1,
	'Lowndes'
);
INSERT INTO CWMS_COUNTY VALUES (
	1087,
	'087',
	1,
	'Macon'
);
INSERT INTO CWMS_COUNTY VALUES (
	1089,
	'089',
	1,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	1091,
	'091',
	1,
	'Marengo'
);
INSERT INTO CWMS_COUNTY VALUES (
	1093,
	'093',
	1,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	1095,
	'095',
	1,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	1097,
	'097',
	1,
	'Mobile'
);
INSERT INTO CWMS_COUNTY VALUES (
	1099,
	'099',
	1,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	1101,
	'101',
	1,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	1103,
	'103',
	1,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	1105,
	'105',
	1,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	1107,
	'107',
	1,
	'Pickens'
);
INSERT INTO CWMS_COUNTY VALUES (
	1109,
	'109',
	1,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	1111,
	'111',
	1,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	1113,
	'113',
	1,
	'Russell'
);
INSERT INTO CWMS_COUNTY VALUES (
	1115,
	'115',
	1,
	'St. Clair'
);
INSERT INTO CWMS_COUNTY VALUES (
	1117,
	'117',
	1,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	1119,
	'119',
	1,
	'Sumter'
);
INSERT INTO CWMS_COUNTY VALUES (
	1121,
	'121',
	1,
	'Talladega'
);
INSERT INTO CWMS_COUNTY VALUES (
	1123,
	'123',
	1,
	'Tallapoosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	1125,
	'125',
	1,
	'Tuscaloosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	1127,
	'127',
	1,
	'Walker'
);
INSERT INTO CWMS_COUNTY VALUES (
	1129,
	'129',
	1,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	1131,
	'131',
	1,
	'Wilcox'
);
INSERT INTO CWMS_COUNTY VALUES (
	1133,
	'133',
	1,
	'Winston'
);
INSERT INTO CWMS_COUNTY VALUES (
	2000,
	'000',
	2,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	2013,
	'013',
	2,
	'Aleutians East'
);
INSERT INTO CWMS_COUNTY VALUES (
	2016,
	'016',
	2,
	'Aleutians West'
);
INSERT INTO CWMS_COUNTY VALUES (
	2020,
	'020',
	2,
	'Anchorage'
);
INSERT INTO CWMS_COUNTY VALUES (
	2050,
	'050',
	2,
	'Bethel'
);
INSERT INTO CWMS_COUNTY VALUES (
	2060,
	'060',
	2,
	'Bristol Bay'
);
INSERT INTO CWMS_COUNTY VALUES (
	2070,
	'070',
	2,
	'Dillingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	2090,
	'090',
	2,
	'Fairbanks North Star'
);
INSERT INTO CWMS_COUNTY VALUES (
	2100,
	'100',
	2,
	'Haines'
);
INSERT INTO CWMS_COUNTY VALUES (
	2110,
	'110',
	2,
	'Juneau'
);
INSERT INTO CWMS_COUNTY VALUES (
	2122,
	'122',
	2,
	'Kenai Peninsula'
);
INSERT INTO CWMS_COUNTY VALUES (
	2130,
	'130',
	2,
	'Ketchikan Gateway'
);
INSERT INTO CWMS_COUNTY VALUES (
	2150,
	'150',
	2,
	'Kodiak Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	2164,
	'164',
	2,
	'Lake and Peninsula'
);
INSERT INTO CWMS_COUNTY VALUES (
	2170,
	'170',
	2,
	'Matanuska-Susitna'
);
INSERT INTO CWMS_COUNTY VALUES (
	2180,
	'180',
	2,
	'Nome'
);
INSERT INTO CWMS_COUNTY VALUES (
	2185,
	'185',
	2,
	'North Slope'
);
INSERT INTO CWMS_COUNTY VALUES (
	2188,
	'188',
	2,
	'Northwest Arctic'
);
INSERT INTO CWMS_COUNTY VALUES (
	2220,
	'220',
	2,
	'Sitka'
);
INSERT INTO CWMS_COUNTY VALUES (
	2231,
	'231',
	2,
	'Skagway-Yakutat-Angoon'
);
INSERT INTO CWMS_COUNTY VALUES (
	2240,
	'240',
	2,
	'Southeast Fairbanks'
);
INSERT INTO CWMS_COUNTY VALUES (
	2261,
	'261',
	2,
	'Valdez-Cordova'
);
INSERT INTO CWMS_COUNTY VALUES (
	2270,
	'270',
	2,
	'Wade Hampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	2280,
	'280',
	2,
	'Wrangell-Petersburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	2290,
	'290',
	2,
	'Yukon-Koyukuk'
);
INSERT INTO CWMS_COUNTY VALUES (
	4000,
	'000',
	4,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	4001,
	'001',
	4,
	'Apache'
);
INSERT INTO CWMS_COUNTY VALUES (
	4003,
	'003',
	4,
	'Cochise'
);
INSERT INTO CWMS_COUNTY VALUES (
	4005,
	'005',
	4,
	'Coconino'
);
INSERT INTO CWMS_COUNTY VALUES (
	4007,
	'007',
	4,
	'Gila'
);
INSERT INTO CWMS_COUNTY VALUES (
	4009,
	'009',
	4,
	'Graham'
);
INSERT INTO CWMS_COUNTY VALUES (
	4011,
	'011',
	4,
	'Greenlee'
);
INSERT INTO CWMS_COUNTY VALUES (
	4012,
	'012',
	4,
	'La Paz'
);
INSERT INTO CWMS_COUNTY VALUES (
	4013,
	'013',
	4,
	'Maricopa'
);
INSERT INTO CWMS_COUNTY VALUES (
	4015,
	'015',
	4,
	'Mohave'
);
INSERT INTO CWMS_COUNTY VALUES (
	4017,
	'017',
	4,
	'Navajo'
);
INSERT INTO CWMS_COUNTY VALUES (
	4019,
	'019',
	4,
	'Pima'
);
INSERT INTO CWMS_COUNTY VALUES (
	4021,
	'021',
	4,
	'Pinal'
);
INSERT INTO CWMS_COUNTY VALUES (
	4023,
	'023',
	4,
	'Santa Cruz'
);
INSERT INTO CWMS_COUNTY VALUES (
	4025,
	'025',
	4,
	'Yavapai'
);
INSERT INTO CWMS_COUNTY VALUES (
	4027,
	'027',
	4,
	'Yuma'
);
INSERT INTO CWMS_COUNTY VALUES (
	5000,
	'000',
	5,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	5001,
	'001',
	5,
	'Arkansas'
);
INSERT INTO CWMS_COUNTY VALUES (
	5003,
	'003',
	5,
	'Ashley'
);
INSERT INTO CWMS_COUNTY VALUES (
	5005,
	'005',
	5,
	'Baxter'
);
INSERT INTO CWMS_COUNTY VALUES (
	5007,
	'007',
	5,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	5009,
	'009',
	5,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	5011,
	'011',
	5,
	'Bradley'
);
INSERT INTO CWMS_COUNTY VALUES (
	5013,
	'013',
	5,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	5015,
	'015',
	5,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	5017,
	'017',
	5,
	'Chicot'
);
INSERT INTO CWMS_COUNTY VALUES (
	5019,
	'019',
	5,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	5021,
	'021',
	5,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	5023,
	'023',
	5,
	'Cleburne'
);
INSERT INTO CWMS_COUNTY VALUES (
	5025,
	'025',
	5,
	'Cleveland'
);
INSERT INTO CWMS_COUNTY VALUES (
	5027,
	'027',
	5,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	5029,
	'029',
	5,
	'Conway'
);
INSERT INTO CWMS_COUNTY VALUES (
	5031,
	'031',
	5,
	'Craighead'
);
INSERT INTO CWMS_COUNTY VALUES (
	5033,
	'033',
	5,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	5035,
	'035',
	5,
	'Crittenden'
);
INSERT INTO CWMS_COUNTY VALUES (
	5037,
	'037',
	5,
	'Cross'
);
INSERT INTO CWMS_COUNTY VALUES (
	5039,
	'039',
	5,
	'Dallas'
);
INSERT INTO CWMS_COUNTY VALUES (
	5041,
	'041',
	5,
	'Desha'
);
INSERT INTO CWMS_COUNTY VALUES (
	5043,
	'043',
	5,
	'Drew'
);
INSERT INTO CWMS_COUNTY VALUES (
	5045,
	'045',
	5,
	'Faulkner'
);
INSERT INTO CWMS_COUNTY VALUES (
	5047,
	'047',
	5,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	5049,
	'049',
	5,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	5051,
	'051',
	5,
	'Garland'
);
INSERT INTO CWMS_COUNTY VALUES (
	5053,
	'053',
	5,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	5055,
	'055',
	5,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	5057,
	'057',
	5,
	'Hempstead'
);
INSERT INTO CWMS_COUNTY VALUES (
	5059,
	'059',
	5,
	'Hot Spring'
);
INSERT INTO CWMS_COUNTY VALUES (
	5061,
	'061',
	5,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	5063,
	'063',
	5,
	'Independence'
);
INSERT INTO CWMS_COUNTY VALUES (
	5065,
	'065',
	5,
	'Izard'
);
INSERT INTO CWMS_COUNTY VALUES (
	5067,
	'067',
	5,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	5069,
	'069',
	5,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	5071,
	'071',
	5,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	5073,
	'073',
	5,
	'Lafayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	5075,
	'075',
	5,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	5077,
	'077',
	5,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	5079,
	'079',
	5,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	5081,
	'081',
	5,
	'Little River'
);
INSERT INTO CWMS_COUNTY VALUES (
	5083,
	'083',
	5,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	5085,
	'085',
	5,
	'Lonoke'
);
INSERT INTO CWMS_COUNTY VALUES (
	5087,
	'087',
	5,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	5089,
	'089',
	5,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	5091,
	'091',
	5,
	'Miller'
);
INSERT INTO CWMS_COUNTY VALUES (
	5093,
	'093',
	5,
	'Mississippi'
);
INSERT INTO CWMS_COUNTY VALUES (
	5095,
	'095',
	5,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	5097,
	'097',
	5,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	5099,
	'099',
	5,
	'Nevada'
);
INSERT INTO CWMS_COUNTY VALUES (
	5101,
	'101',
	5,
	'Newton'
);
INSERT INTO CWMS_COUNTY VALUES (
	5103,
	'103',
	5,
	'Ouachita'
);
INSERT INTO CWMS_COUNTY VALUES (
	5105,
	'105',
	5,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	5107,
	'107',
	5,
	'Phillips'
);
INSERT INTO CWMS_COUNTY VALUES (
	5109,
	'109',
	5,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	5111,
	'111',
	5,
	'Poinsett'
);
INSERT INTO CWMS_COUNTY VALUES (
	5113,
	'113',
	5,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	5115,
	'115',
	5,
	'Pope'
);
INSERT INTO CWMS_COUNTY VALUES (
	5117,
	'117',
	5,
	'Prairie'
);
INSERT INTO CWMS_COUNTY VALUES (
	5119,
	'119',
	5,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	5121,
	'121',
	5,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	5123,
	'123',
	5,
	'St. Francis'
);
INSERT INTO CWMS_COUNTY VALUES (
	5125,
	'125',
	5,
	'Saline'
);
INSERT INTO CWMS_COUNTY VALUES (
	5127,
	'127',
	5,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	5129,
	'129',
	5,
	'Searcy'
);
INSERT INTO CWMS_COUNTY VALUES (
	5131,
	'131',
	5,
	'Sebastian'
);
INSERT INTO CWMS_COUNTY VALUES (
	5133,
	'133',
	5,
	'Sevier'
);
INSERT INTO CWMS_COUNTY VALUES (
	5135,
	'135',
	5,
	'Sharp'
);
INSERT INTO CWMS_COUNTY VALUES (
	5137,
	'137',
	5,
	'Stone'
);
INSERT INTO CWMS_COUNTY VALUES (
	5139,
	'139',
	5,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	5141,
	'141',
	5,
	'Van Buren'
);
INSERT INTO CWMS_COUNTY VALUES (
	5143,
	'143',
	5,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	5145,
	'145',
	5,
	'White'
);
INSERT INTO CWMS_COUNTY VALUES (
	5147,
	'147',
	5,
	'Woodruff'
);
INSERT INTO CWMS_COUNTY VALUES (
	5149,
	'149',
	5,
	'Yell'
);
INSERT INTO CWMS_COUNTY VALUES (
	6000,
	'000',
	6,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	6001,
	'001',
	6,
	'Alameda'
);
INSERT INTO CWMS_COUNTY VALUES (
	6003,
	'003',
	6,
	'Alpine'
);
INSERT INTO CWMS_COUNTY VALUES (
	6005,
	'005',
	6,
	'Amador'
);
INSERT INTO CWMS_COUNTY VALUES (
	6007,
	'007',
	6,
	'Butte'
);
INSERT INTO CWMS_COUNTY VALUES (
	6009,
	'009',
	6,
	'Calaveras'
);
INSERT INTO CWMS_COUNTY VALUES (
	6011,
	'011',
	6,
	'Colusa'
);
INSERT INTO CWMS_COUNTY VALUES (
	6013,
	'013',
	6,
	'Contra Costa'
);
INSERT INTO CWMS_COUNTY VALUES (
	6015,
	'015',
	6,
	'Del Norte'
);
INSERT INTO CWMS_COUNTY VALUES (
	6017,
	'017',
	6,
	'El Dorado'
);
INSERT INTO CWMS_COUNTY VALUES (
	6019,
	'019',
	6,
	'Fresno'
);
INSERT INTO CWMS_COUNTY VALUES (
	6021,
	'021',
	6,
	'Glenn'
);
INSERT INTO CWMS_COUNTY VALUES (
	6023,
	'023',
	6,
	'Humboldt'
);
INSERT INTO CWMS_COUNTY VALUES (
	6025,
	'025',
	6,
	'Imperial'
);
INSERT INTO CWMS_COUNTY VALUES (
	6027,
	'027',
	6,
	'Inyo'
);
INSERT INTO CWMS_COUNTY VALUES (
	6029,
	'029',
	6,
	'Kern'
);
INSERT INTO CWMS_COUNTY VALUES (
	6031,
	'031',
	6,
	'Kings'
);
INSERT INTO CWMS_COUNTY VALUES (
	6033,
	'033',
	6,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	6035,
	'035',
	6,
	'Lassen'
);
INSERT INTO CWMS_COUNTY VALUES (
	6037,
	'037',
	6,
	'Los Angeles'
);
INSERT INTO CWMS_COUNTY VALUES (
	6039,
	'039',
	6,
	'Madera'
);
INSERT INTO CWMS_COUNTY VALUES (
	6041,
	'041',
	6,
	'Marin'
);
INSERT INTO CWMS_COUNTY VALUES (
	6043,
	'043',
	6,
	'Mariposa'
);
INSERT INTO CWMS_COUNTY VALUES (
	6045,
	'045',
	6,
	'Mendocino'
);
INSERT INTO CWMS_COUNTY VALUES (
	6047,
	'047',
	6,
	'Merced'
);
INSERT INTO CWMS_COUNTY VALUES (
	6049,
	'049',
	6,
	'Modoc'
);
INSERT INTO CWMS_COUNTY VALUES (
	6051,
	'051',
	6,
	'Mono'
);
INSERT INTO CWMS_COUNTY VALUES (
	6053,
	'053',
	6,
	'Monterey'
);
INSERT INTO CWMS_COUNTY VALUES (
	6055,
	'055',
	6,
	'Napa'
);
INSERT INTO CWMS_COUNTY VALUES (
	6057,
	'057',
	6,
	'Nevada'
);
INSERT INTO CWMS_COUNTY VALUES (
	6059,
	'059',
	6,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	6061,
	'061',
	6,
	'Placer'
);
INSERT INTO CWMS_COUNTY VALUES (
	6063,
	'063',
	6,
	'Plumas'
);
INSERT INTO CWMS_COUNTY VALUES (
	6065,
	'065',
	6,
	'Riverside'
);
INSERT INTO CWMS_COUNTY VALUES (
	6067,
	'067',
	6,
	'Sacramento'
);
INSERT INTO CWMS_COUNTY VALUES (
	6069,
	'069',
	6,
	'San Benito'
);
INSERT INTO CWMS_COUNTY VALUES (
	6071,
	'071',
	6,
	'San Bernardino'
);
INSERT INTO CWMS_COUNTY VALUES (
	6073,
	'073',
	6,
	'San Diego'
);
INSERT INTO CWMS_COUNTY VALUES (
	6075,
	'075',
	6,
	'San Francisco'
);
INSERT INTO CWMS_COUNTY VALUES (
	6077,
	'077',
	6,
	'San Joaquin'
);
INSERT INTO CWMS_COUNTY VALUES (
	6079,
	'079',
	6,
	'San Luis Obispo'
);
INSERT INTO CWMS_COUNTY VALUES (
	6081,
	'081',
	6,
	'San Mateo'
);
INSERT INTO CWMS_COUNTY VALUES (
	6083,
	'083',
	6,
	'Santa Barbara'
);
INSERT INTO CWMS_COUNTY VALUES (
	6085,
	'085',
	6,
	'Santa Clara'
);
INSERT INTO CWMS_COUNTY VALUES (
	6087,
	'087',
	6,
	'Santa Cruz'
);
INSERT INTO CWMS_COUNTY VALUES (
	6089,
	'089',
	6,
	'Shasta'
);
INSERT INTO CWMS_COUNTY VALUES (
	6091,
	'091',
	6,
	'Sierra'
);
INSERT INTO CWMS_COUNTY VALUES (
	6093,
	'093',
	6,
	'Siskiyou'
);
INSERT INTO CWMS_COUNTY VALUES (
	6095,
	'095',
	6,
	'Solano'
);
INSERT INTO CWMS_COUNTY VALUES (
	6097,
	'097',
	6,
	'Sonoma'
);
INSERT INTO CWMS_COUNTY VALUES (
	6099,
	'099',
	6,
	'Stanislaus'
);
INSERT INTO CWMS_COUNTY VALUES (
	6101,
	'101',
	6,
	'Sutter'
);
INSERT INTO CWMS_COUNTY VALUES (
	6103,
	'103',
	6,
	'Tehama'
);
INSERT INTO CWMS_COUNTY VALUES (
	6105,
	'105',
	6,
	'Trinity'
);
INSERT INTO CWMS_COUNTY VALUES (
	6107,
	'107',
	6,
	'Tulare'
);
INSERT INTO CWMS_COUNTY VALUES (
	6109,
	'109',
	6,
	'Tuolumne'
);
INSERT INTO CWMS_COUNTY VALUES (
	6111,
	'111',
	6,
	'Ventura'
);
INSERT INTO CWMS_COUNTY VALUES (
	6113,
	'113',
	6,
	'Yolo'
);
INSERT INTO CWMS_COUNTY VALUES (
	6115,
	'115',
	6,
	'Yuba'
);
INSERT INTO CWMS_COUNTY VALUES (
	8000,
	'000',
	8,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	8001,
	'001',
	8,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	8003,
	'003',
	8,
	'Alamosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	8005,
	'005',
	8,
	'Arapahoe'
);
INSERT INTO CWMS_COUNTY VALUES (
	8007,
	'007',
	8,
	'Archuleta'
);
INSERT INTO CWMS_COUNTY VALUES (
	8009,
	'009',
	8,
	'Baca'
);
INSERT INTO CWMS_COUNTY VALUES (
	8011,
	'011',
	8,
	'Bent'
);
INSERT INTO CWMS_COUNTY VALUES (
	8013,
	'013',
	8,
	'Boulder'
);
INSERT INTO CWMS_COUNTY VALUES (
	8015,
	'015',
	8,
	'Chaffee'
);
INSERT INTO CWMS_COUNTY VALUES (
	8017,
	'017',
	8,
	'Cheyenne'
);
INSERT INTO CWMS_COUNTY VALUES (
	8019,
	'019',
	8,
	'Clear Creek'
);
INSERT INTO CWMS_COUNTY VALUES (
	8021,
	'021',
	8,
	'Conejos'
);
INSERT INTO CWMS_COUNTY VALUES (
	8023,
	'023',
	8,
	'Costilla'
);
INSERT INTO CWMS_COUNTY VALUES (
	8025,
	'025',
	8,
	'Crowley'
);
INSERT INTO CWMS_COUNTY VALUES (
	8027,
	'027',
	8,
	'Custer'
);
INSERT INTO CWMS_COUNTY VALUES (
	8029,
	'029',
	8,
	'Delta'
);
INSERT INTO CWMS_COUNTY VALUES (
	8031,
	'031',
	8,
	'Denver'
);
INSERT INTO CWMS_COUNTY VALUES (
	8033,
	'033',
	8,
	'Dolores'
);
INSERT INTO CWMS_COUNTY VALUES (
	8035,
	'035',
	8,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	8037,
	'037',
	8,
	'Eagle'
);
INSERT INTO CWMS_COUNTY VALUES (
	8039,
	'039',
	8,
	'Elbert'
);
INSERT INTO CWMS_COUNTY VALUES (
	8041,
	'041',
	8,
	'El Paso'
);
INSERT INTO CWMS_COUNTY VALUES (
	8043,
	'043',
	8,
	'Fremont'
);
INSERT INTO CWMS_COUNTY VALUES (
	8045,
	'045',
	8,
	'Garfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	8047,
	'047',
	8,
	'Gilpin'
);
INSERT INTO CWMS_COUNTY VALUES (
	8049,
	'049',
	8,
	'Grand'
);
INSERT INTO CWMS_COUNTY VALUES (
	8051,
	'051',
	8,
	'Gunnison'
);
INSERT INTO CWMS_COUNTY VALUES (
	8053,
	'053',
	8,
	'Hinsdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	8055,
	'055',
	8,
	'Huerfano'
);
INSERT INTO CWMS_COUNTY VALUES (
	8057,
	'057',
	8,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	8059,
	'059',
	8,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	8061,
	'061',
	8,
	'Kiowa'
);
INSERT INTO CWMS_COUNTY VALUES (
	8063,
	'063',
	8,
	'Kit Carson'
);
INSERT INTO CWMS_COUNTY VALUES (
	8065,
	'065',
	8,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	8067,
	'067',
	8,
	'La Plata'
);
INSERT INTO CWMS_COUNTY VALUES (
	8069,
	'069',
	8,
	'Larimer'
);
INSERT INTO CWMS_COUNTY VALUES (
	8071,
	'071',
	8,
	'Las Animas'
);
INSERT INTO CWMS_COUNTY VALUES (
	8073,
	'073',
	8,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	8075,
	'075',
	8,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	8077,
	'077',
	8,
	'Mesa'
);
INSERT INTO CWMS_COUNTY VALUES (
	8079,
	'079',
	8,
	'Mineral'
);
INSERT INTO CWMS_COUNTY VALUES (
	8081,
	'081',
	8,
	'Moffat'
);
INSERT INTO CWMS_COUNTY VALUES (
	8083,
	'083',
	8,
	'Montezuma'
);
INSERT INTO CWMS_COUNTY VALUES (
	8085,
	'085',
	8,
	'Montrose'
);
INSERT INTO CWMS_COUNTY VALUES (
	8087,
	'087',
	8,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	8089,
	'089',
	8,
	'Otero'
);
INSERT INTO CWMS_COUNTY VALUES (
	8091,
	'091',
	8,
	'Ouray'
);
INSERT INTO CWMS_COUNTY VALUES (
	8093,
	'093',
	8,
	'Park'
);
INSERT INTO CWMS_COUNTY VALUES (
	8095,
	'095',
	8,
	'Phillips'
);
INSERT INTO CWMS_COUNTY VALUES (
	8097,
	'097',
	8,
	'Pitkin'
);
INSERT INTO CWMS_COUNTY VALUES (
	8099,
	'099',
	8,
	'Prowers'
);
INSERT INTO CWMS_COUNTY VALUES (
	8101,
	'101',
	8,
	'Pueblo'
);
INSERT INTO CWMS_COUNTY VALUES (
	8103,
	'103',
	8,
	'Rio Blanco'
);
INSERT INTO CWMS_COUNTY VALUES (
	8105,
	'105',
	8,
	'Rio Grande'
);
INSERT INTO CWMS_COUNTY VALUES (
	8107,
	'107',
	8,
	'Routt'
);
INSERT INTO CWMS_COUNTY VALUES (
	8109,
	'109',
	8,
	'Saguache'
);
INSERT INTO CWMS_COUNTY VALUES (
	8111,
	'111',
	8,
	'San Juan'
);
INSERT INTO CWMS_COUNTY VALUES (
	8113,
	'113',
	8,
	'San Miguel'
);
INSERT INTO CWMS_COUNTY VALUES (
	8115,
	'115',
	8,
	'Sedgwick'
);
INSERT INTO CWMS_COUNTY VALUES (
	8117,
	'117',
	8,
	'Summit'
);
INSERT INTO CWMS_COUNTY VALUES (
	8119,
	'119',
	8,
	'Teller'
);
INSERT INTO CWMS_COUNTY VALUES (
	8121,
	'121',
	8,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	8123,
	'123',
	8,
	'Weld'
);
INSERT INTO CWMS_COUNTY VALUES (
	8125,
	'125',
	8,
	'Yuma'
);
INSERT INTO CWMS_COUNTY VALUES (
	9000,
	'000',
	9,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	9001,
	'001',
	9,
	'Fairfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	9003,
	'003',
	9,
	'Hartford'
);
INSERT INTO CWMS_COUNTY VALUES (
	9005,
	'005',
	9,
	'Litchfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	9007,
	'007',
	9,
	'Middlesex'
);
INSERT INTO CWMS_COUNTY VALUES (
	9009,
	'009',
	9,
	'New Haven'
);
INSERT INTO CWMS_COUNTY VALUES (
	9011,
	'011',
	9,
	'New London'
);
INSERT INTO CWMS_COUNTY VALUES (
	9013,
	'013',
	9,
	'Tolland'
);
INSERT INTO CWMS_COUNTY VALUES (
	9015,
	'015',
	9,
	'Windham'
);
INSERT INTO CWMS_COUNTY VALUES (
	10000,
	'000',
	10,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	10001,
	'001',
	10,
	'Kent'
);
INSERT INTO CWMS_COUNTY VALUES (
	10003,
	'003',
	10,
	'New Castle'
);
INSERT INTO CWMS_COUNTY VALUES (
	10005,
	'005',
	10,
	'Sussex'
);
INSERT INTO CWMS_COUNTY VALUES (
	11000,
	'000',
	11,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	11001,
	'001',
	11,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	12000,
	'000',
	12,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	12001,
	'001',
	12,
	'Alachua'
);
INSERT INTO CWMS_COUNTY VALUES (
	12003,
	'003',
	12,
	'Baker'
);
INSERT INTO CWMS_COUNTY VALUES (
	12005,
	'005',
	12,
	'Bay'
);
INSERT INTO CWMS_COUNTY VALUES (
	12007,
	'007',
	12,
	'Bradford'
);
INSERT INTO CWMS_COUNTY VALUES (
	12009,
	'009',
	12,
	'Brevard'
);
INSERT INTO CWMS_COUNTY VALUES (
	12011,
	'011',
	12,
	'Broward'
);
INSERT INTO CWMS_COUNTY VALUES (
	12013,
	'013',
	12,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	12015,
	'015',
	12,
	'Charlotte'
);
INSERT INTO CWMS_COUNTY VALUES (
	12017,
	'017',
	12,
	'Citrus'
);
INSERT INTO CWMS_COUNTY VALUES (
	12019,
	'019',
	12,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	12021,
	'021',
	12,
	'Collier'
);
INSERT INTO CWMS_COUNTY VALUES (
	12023,
	'023',
	12,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	12025,
	'025',
	12,
	'Dade'
);
INSERT INTO CWMS_COUNTY VALUES (
	12027,
	'027',
	12,
	'De Soto'
);
INSERT INTO CWMS_COUNTY VALUES (
	12029,
	'029',
	12,
	'Dixie'
);
INSERT INTO CWMS_COUNTY VALUES (
	12031,
	'031',
	12,
	'Duval'
);
INSERT INTO CWMS_COUNTY VALUES (
	12033,
	'033',
	12,
	'Escambia'
);
INSERT INTO CWMS_COUNTY VALUES (
	12035,
	'035',
	12,
	'Flagler'
);
INSERT INTO CWMS_COUNTY VALUES (
	12037,
	'037',
	12,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	12039,
	'039',
	12,
	'Gadsden'
);
INSERT INTO CWMS_COUNTY VALUES (
	12041,
	'041',
	12,
	'Gilchrist'
);
INSERT INTO CWMS_COUNTY VALUES (
	12043,
	'043',
	12,
	'Glades'
);
INSERT INTO CWMS_COUNTY VALUES (
	12045,
	'045',
	12,
	'Gulf'
);
INSERT INTO CWMS_COUNTY VALUES (
	12047,
	'047',
	12,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	12049,
	'049',
	12,
	'Hardee'
);
INSERT INTO CWMS_COUNTY VALUES (
	12051,
	'051',
	12,
	'Hendry'
);
INSERT INTO CWMS_COUNTY VALUES (
	12053,
	'053',
	12,
	'Hernando'
);
INSERT INTO CWMS_COUNTY VALUES (
	12055,
	'055',
	12,
	'Highlands'
);
INSERT INTO CWMS_COUNTY VALUES (
	12057,
	'057',
	12,
	'Hillsborough'
);
INSERT INTO CWMS_COUNTY VALUES (
	12059,
	'059',
	12,
	'Holmes'
);
INSERT INTO CWMS_COUNTY VALUES (
	12061,
	'061',
	12,
	'Indian River'
);
INSERT INTO CWMS_COUNTY VALUES (
	12063,
	'063',
	12,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	12065,
	'065',
	12,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	12067,
	'067',
	12,
	'Lafayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	12069,
	'069',
	12,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	12071,
	'071',
	12,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	12073,
	'073',
	12,
	'Leon'
);
INSERT INTO CWMS_COUNTY VALUES (
	12075,
	'075',
	12,
	'Levy'
);
INSERT INTO CWMS_COUNTY VALUES (
	12077,
	'077',
	12,
	'Liberty'
);
INSERT INTO CWMS_COUNTY VALUES (
	12079,
	'079',
	12,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	12081,
	'081',
	12,
	'Manatee'
);
INSERT INTO CWMS_COUNTY VALUES (
	12083,
	'083',
	12,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	12085,
	'085',
	12,
	'Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	12087,
	'087',
	12,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	12089,
	'089',
	12,
	'Nassau'
);
INSERT INTO CWMS_COUNTY VALUES (
	12091,
	'091',
	12,
	'Okaloosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	12093,
	'093',
	12,
	'Okeechobee'
);
INSERT INTO CWMS_COUNTY VALUES (
	12095,
	'095',
	12,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	12097,
	'097',
	12,
	'Osceola'
);
INSERT INTO CWMS_COUNTY VALUES (
	12099,
	'099',
	12,
	'Palm Beach'
);
INSERT INTO CWMS_COUNTY VALUES (
	12101,
	'101',
	12,
	'Pasco'
);
INSERT INTO CWMS_COUNTY VALUES (
	12103,
	'103',
	12,
	'Pinellas'
);
INSERT INTO CWMS_COUNTY VALUES (
	12105,
	'105',
	12,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	12107,
	'107',
	12,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	12109,
	'109',
	12,
	'St. Johns'
);
INSERT INTO CWMS_COUNTY VALUES (
	12111,
	'111',
	12,
	'St. Lucie'
);
INSERT INTO CWMS_COUNTY VALUES (
	12113,
	'113',
	12,
	'Santa Rosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	12115,
	'115',
	12,
	'Sarasota'
);
INSERT INTO CWMS_COUNTY VALUES (
	12117,
	'117',
	12,
	'Seminole'
);
INSERT INTO CWMS_COUNTY VALUES (
	12119,
	'119',
	12,
	'Sumter'
);
INSERT INTO CWMS_COUNTY VALUES (
	12121,
	'121',
	12,
	'Suwannee'
);
INSERT INTO CWMS_COUNTY VALUES (
	12123,
	'123',
	12,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	12125,
	'125',
	12,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	12127,
	'127',
	12,
	'Volusia'
);
INSERT INTO CWMS_COUNTY VALUES (
	12129,
	'129',
	12,
	'Wakulla'
);
INSERT INTO CWMS_COUNTY VALUES (
	12131,
	'131',
	12,
	'Walton'
);
INSERT INTO CWMS_COUNTY VALUES (
	12133,
	'133',
	12,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	13000,
	'000',
	13,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	13001,
	'001',
	13,
	'Appling'
);
INSERT INTO CWMS_COUNTY VALUES (
	13003,
	'003',
	13,
	'Atkinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13005,
	'005',
	13,
	'Bacon'
);
INSERT INTO CWMS_COUNTY VALUES (
	13007,
	'007',
	13,
	'Baker'
);
INSERT INTO CWMS_COUNTY VALUES (
	13009,
	'009',
	13,
	'Baldwin'
);
INSERT INTO CWMS_COUNTY VALUES (
	13011,
	'011',
	13,
	'Banks'
);
INSERT INTO CWMS_COUNTY VALUES (
	13013,
	'013',
	13,
	'Barrow'
);
INSERT INTO CWMS_COUNTY VALUES (
	13015,
	'015',
	13,
	'Bartow'
);
INSERT INTO CWMS_COUNTY VALUES (
	13017,
	'017',
	13,
	'Ben Hill'
);
INSERT INTO CWMS_COUNTY VALUES (
	13019,
	'019',
	13,
	'Berrien'
);
INSERT INTO CWMS_COUNTY VALUES (
	13021,
	'021',
	13,
	'Bibb'
);
INSERT INTO CWMS_COUNTY VALUES (
	13023,
	'023',
	13,
	'Bleckley'
);
INSERT INTO CWMS_COUNTY VALUES (
	13025,
	'025',
	13,
	'Brantley'
);
INSERT INTO CWMS_COUNTY VALUES (
	13027,
	'027',
	13,
	'Brooks'
);
INSERT INTO CWMS_COUNTY VALUES (
	13029,
	'029',
	13,
	'Bryan'
);
INSERT INTO CWMS_COUNTY VALUES (
	13031,
	'031',
	13,
	'Bulloch'
);
INSERT INTO CWMS_COUNTY VALUES (
	13033,
	'033',
	13,
	'Burke'
);
INSERT INTO CWMS_COUNTY VALUES (
	13035,
	'035',
	13,
	'Butts'
);
INSERT INTO CWMS_COUNTY VALUES (
	13037,
	'037',
	13,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	13039,
	'039',
	13,
	'Camden'
);
INSERT INTO CWMS_COUNTY VALUES (
	13043,
	'043',
	13,
	'Candler'
);
INSERT INTO CWMS_COUNTY VALUES (
	13045,
	'045',
	13,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	13047,
	'047',
	13,
	'Catoosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	13049,
	'049',
	13,
	'Charlton'
);
INSERT INTO CWMS_COUNTY VALUES (
	13051,
	'051',
	13,
	'Chatham'
);
INSERT INTO CWMS_COUNTY VALUES (
	13053,
	'053',
	13,
	'Chattahoochee'
);
INSERT INTO CWMS_COUNTY VALUES (
	13055,
	'055',
	13,
	'Chattooga'
);
INSERT INTO CWMS_COUNTY VALUES (
	13057,
	'057',
	13,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	13059,
	'059',
	13,
	'Clarke'
);
INSERT INTO CWMS_COUNTY VALUES (
	13061,
	'061',
	13,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	13063,
	'063',
	13,
	'Clayton'
);
INSERT INTO CWMS_COUNTY VALUES (
	13065,
	'065',
	13,
	'Clinch'
);
INSERT INTO CWMS_COUNTY VALUES (
	13067,
	'067',
	13,
	'Cobb'
);
INSERT INTO CWMS_COUNTY VALUES (
	13069,
	'069',
	13,
	'Coffee'
);
INSERT INTO CWMS_COUNTY VALUES (
	13071,
	'071',
	13,
	'Colquitt'
);
INSERT INTO CWMS_COUNTY VALUES (
	13073,
	'073',
	13,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	13075,
	'075',
	13,
	'Cook'
);
INSERT INTO CWMS_COUNTY VALUES (
	13077,
	'077',
	13,
	'Coweta'
);
INSERT INTO CWMS_COUNTY VALUES (
	13079,
	'079',
	13,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	13081,
	'081',
	13,
	'Crisp'
);
INSERT INTO CWMS_COUNTY VALUES (
	13083,
	'083',
	13,
	'Dade'
);
INSERT INTO CWMS_COUNTY VALUES (
	13085,
	'085',
	13,
	'Dawson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13087,
	'087',
	13,
	'Decatur'
);
INSERT INTO CWMS_COUNTY VALUES (
	13089,
	'089',
	13,
	'De Kalb'
);
INSERT INTO CWMS_COUNTY VALUES (
	13091,
	'091',
	13,
	'Dodge'
);
INSERT INTO CWMS_COUNTY VALUES (
	13093,
	'093',
	13,
	'Dooly'
);
INSERT INTO CWMS_COUNTY VALUES (
	13095,
	'095',
	13,
	'Dougherty'
);
INSERT INTO CWMS_COUNTY VALUES (
	13097,
	'097',
	13,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	13099,
	'099',
	13,
	'Early'
);
INSERT INTO CWMS_COUNTY VALUES (
	13101,
	'101',
	13,
	'Echols'
);
INSERT INTO CWMS_COUNTY VALUES (
	13103,
	'103',
	13,
	'Effingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	13105,
	'105',
	13,
	'Elbert'
);
INSERT INTO CWMS_COUNTY VALUES (
	13107,
	'107',
	13,
	'Emanuel'
);
INSERT INTO CWMS_COUNTY VALUES (
	13109,
	'109',
	13,
	'Evans'
);
INSERT INTO CWMS_COUNTY VALUES (
	13111,
	'111',
	13,
	'Fannin'
);
INSERT INTO CWMS_COUNTY VALUES (
	13113,
	'113',
	13,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	13115,
	'115',
	13,
	'Floyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	13117,
	'117',
	13,
	'Forsyth'
);
INSERT INTO CWMS_COUNTY VALUES (
	13119,
	'119',
	13,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	13121,
	'121',
	13,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	13123,
	'123',
	13,
	'Gilmer'
);
INSERT INTO CWMS_COUNTY VALUES (
	13125,
	'125',
	13,
	'Glascock'
);
INSERT INTO CWMS_COUNTY VALUES (
	13127,
	'127',
	13,
	'Glynn'
);
INSERT INTO CWMS_COUNTY VALUES (
	13129,
	'129',
	13,
	'Gordon'
);
INSERT INTO CWMS_COUNTY VALUES (
	13131,
	'131',
	13,
	'Grady'
);
INSERT INTO CWMS_COUNTY VALUES (
	13133,
	'133',
	13,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	13135,
	'135',
	13,
	'Gwinnett'
);
INSERT INTO CWMS_COUNTY VALUES (
	13137,
	'137',
	13,
	'Habersham'
);
INSERT INTO CWMS_COUNTY VALUES (
	13139,
	'139',
	13,
	'Hall'
);
INSERT INTO CWMS_COUNTY VALUES (
	13141,
	'141',
	13,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	13143,
	'143',
	13,
	'Haralson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13145,
	'145',
	13,
	'Harris'
);
INSERT INTO CWMS_COUNTY VALUES (
	13147,
	'147',
	13,
	'Hart'
);
INSERT INTO CWMS_COUNTY VALUES (
	13149,
	'149',
	13,
	'Heard'
);
INSERT INTO CWMS_COUNTY VALUES (
	13151,
	'151',
	13,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	13153,
	'153',
	13,
	'Houston'
);
INSERT INTO CWMS_COUNTY VALUES (
	13155,
	'155',
	13,
	'Irwin'
);
INSERT INTO CWMS_COUNTY VALUES (
	13157,
	'157',
	13,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13159,
	'159',
	13,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	13161,
	'161',
	13,
	'Jeff Davis'
);
INSERT INTO CWMS_COUNTY VALUES (
	13163,
	'163',
	13,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13165,
	'165',
	13,
	'Jenkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	13167,
	'167',
	13,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13169,
	'169',
	13,
	'Jones'
);
INSERT INTO CWMS_COUNTY VALUES (
	13171,
	'171',
	13,
	'Lamar'
);
INSERT INTO CWMS_COUNTY VALUES (
	13173,
	'173',
	13,
	'Lanier'
);
INSERT INTO CWMS_COUNTY VALUES (
	13175,
	'175',
	13,
	'Laurens'
);
INSERT INTO CWMS_COUNTY VALUES (
	13177,
	'177',
	13,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	13179,
	'179',
	13,
	'Liberty'
);
INSERT INTO CWMS_COUNTY VALUES (
	13181,
	'181',
	13,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	13183,
	'183',
	13,
	'Long'
);
INSERT INTO CWMS_COUNTY VALUES (
	13185,
	'185',
	13,
	'Lowndes'
);
INSERT INTO CWMS_COUNTY VALUES (
	13187,
	'187',
	13,
	'Lumpkin'
);
INSERT INTO CWMS_COUNTY VALUES (
	13189,
	'189',
	13,
	'McDuffie'
);
INSERT INTO CWMS_COUNTY VALUES (
	13191,
	'191',
	13,
	'McIntosh'
);
INSERT INTO CWMS_COUNTY VALUES (
	13193,
	'193',
	13,
	'Macon'
);
INSERT INTO CWMS_COUNTY VALUES (
	13195,
	'195',
	13,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	13197,
	'197',
	13,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	13199,
	'199',
	13,
	'Meriwether'
);
INSERT INTO CWMS_COUNTY VALUES (
	13201,
	'201',
	13,
	'Miller'
);
INSERT INTO CWMS_COUNTY VALUES (
	13205,
	'205',
	13,
	'Mitchell'
);
INSERT INTO CWMS_COUNTY VALUES (
	13207,
	'207',
	13,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	13209,
	'209',
	13,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	13211,
	'211',
	13,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	13213,
	'213',
	13,
	'Murray'
);
INSERT INTO CWMS_COUNTY VALUES (
	13215,
	'215',
	13,
	'Muscogee'
);
INSERT INTO CWMS_COUNTY VALUES (
	13217,
	'217',
	13,
	'Newton'
);
INSERT INTO CWMS_COUNTY VALUES (
	13219,
	'219',
	13,
	'Oconee'
);
INSERT INTO CWMS_COUNTY VALUES (
	13221,
	'221',
	13,
	'Oglethorpe'
);
INSERT INTO CWMS_COUNTY VALUES (
	13223,
	'223',
	13,
	'Paulding'
);
INSERT INTO CWMS_COUNTY VALUES (
	13225,
	'225',
	13,
	'Peach'
);
INSERT INTO CWMS_COUNTY VALUES (
	13227,
	'227',
	13,
	'Pickens'
);
INSERT INTO CWMS_COUNTY VALUES (
	13229,
	'229',
	13,
	'Pierce'
);
INSERT INTO CWMS_COUNTY VALUES (
	13231,
	'231',
	13,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	13233,
	'233',
	13,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	13235,
	'235',
	13,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	13237,
	'237',
	13,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	13239,
	'239',
	13,
	'Quitman'
);
INSERT INTO CWMS_COUNTY VALUES (
	13241,
	'241',
	13,
	'Rabun'
);
INSERT INTO CWMS_COUNTY VALUES (
	13243,
	'243',
	13,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	13245,
	'245',
	13,
	'Richmond'
);
INSERT INTO CWMS_COUNTY VALUES (
	13247,
	'247',
	13,
	'Rockdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	13249,
	'249',
	13,
	'Schley'
);
INSERT INTO CWMS_COUNTY VALUES (
	13251,
	'251',
	13,
	'Screven'
);
INSERT INTO CWMS_COUNTY VALUES (
	13253,
	'253',
	13,
	'Seminole'
);
INSERT INTO CWMS_COUNTY VALUES (
	13255,
	'255',
	13,
	'Spalding'
);
INSERT INTO CWMS_COUNTY VALUES (
	13257,
	'257',
	13,
	'Stephens'
);
INSERT INTO CWMS_COUNTY VALUES (
	13259,
	'259',
	13,
	'Stewart'
);
INSERT INTO CWMS_COUNTY VALUES (
	13261,
	'261',
	13,
	'Sumter'
);
INSERT INTO CWMS_COUNTY VALUES (
	13263,
	'263',
	13,
	'Talbot'
);
INSERT INTO CWMS_COUNTY VALUES (
	13265,
	'265',
	13,
	'Taliaferro'
);
INSERT INTO CWMS_COUNTY VALUES (
	13267,
	'267',
	13,
	'Tattnall'
);
INSERT INTO CWMS_COUNTY VALUES (
	13269,
	'269',
	13,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	13271,
	'271',
	13,
	'Telfair'
);
INSERT INTO CWMS_COUNTY VALUES (
	13273,
	'273',
	13,
	'Terrell'
);
INSERT INTO CWMS_COUNTY VALUES (
	13275,
	'275',
	13,
	'Thomas'
);
INSERT INTO CWMS_COUNTY VALUES (
	13277,
	'277',
	13,
	'Tift'
);
INSERT INTO CWMS_COUNTY VALUES (
	13279,
	'279',
	13,
	'Toombs'
);
INSERT INTO CWMS_COUNTY VALUES (
	13281,
	'281',
	13,
	'Towns'
);
INSERT INTO CWMS_COUNTY VALUES (
	13283,
	'283',
	13,
	'Treutlen'
);
INSERT INTO CWMS_COUNTY VALUES (
	13285,
	'285',
	13,
	'Troup'
);
INSERT INTO CWMS_COUNTY VALUES (
	13287,
	'287',
	13,
	'Turner'
);
INSERT INTO CWMS_COUNTY VALUES (
	13289,
	'289',
	13,
	'Twiggs'
);
INSERT INTO CWMS_COUNTY VALUES (
	13291,
	'291',
	13,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	13293,
	'293',
	13,
	'Upson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13295,
	'295',
	13,
	'Walker'
);
INSERT INTO CWMS_COUNTY VALUES (
	13297,
	'297',
	13,
	'Walton'
);
INSERT INTO CWMS_COUNTY VALUES (
	13299,
	'299',
	13,
	'Ware'
);
INSERT INTO CWMS_COUNTY VALUES (
	13301,
	'301',
	13,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	13303,
	'303',
	13,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	13305,
	'305',
	13,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	13307,
	'307',
	13,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	13309,
	'309',
	13,
	'Wheeler'
);
INSERT INTO CWMS_COUNTY VALUES (
	13311,
	'311',
	13,
	'White'
);
INSERT INTO CWMS_COUNTY VALUES (
	13313,
	'313',
	13,
	'Whitfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	13315,
	'315',
	13,
	'Wilcox'
);
INSERT INTO CWMS_COUNTY VALUES (
	13317,
	'317',
	13,
	'Wilkes'
);
INSERT INTO CWMS_COUNTY VALUES (
	13319,
	'319',
	13,
	'Wilkinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	13321,
	'321',
	13,
	'Worth'
);
INSERT INTO CWMS_COUNTY VALUES (
	15000,
	'000',
	15,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	15001,
	'001',
	15,
	'Hawaii'
);
INSERT INTO CWMS_COUNTY VALUES (
	15003,
	'003',
	15,
	'Honolulu'
);
INSERT INTO CWMS_COUNTY VALUES (
	15007,
	'007',
	15,
	'Kauai'
);
INSERT INTO CWMS_COUNTY VALUES (
	15009,
	'009',
	15,
	'Maui'
);
INSERT INTO CWMS_COUNTY VALUES (
	16000,
	'000',
	16,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	16001,
	'001',
	16,
	'Ada'
);
INSERT INTO CWMS_COUNTY VALUES (
	16003,
	'003',
	16,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	16005,
	'005',
	16,
	'Bannock'
);
INSERT INTO CWMS_COUNTY VALUES (
	16007,
	'007',
	16,
	'Bear Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	16009,
	'009',
	16,
	'Benewah'
);
INSERT INTO CWMS_COUNTY VALUES (
	16011,
	'011',
	16,
	'Bingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	16013,
	'013',
	16,
	'Blaine'
);
INSERT INTO CWMS_COUNTY VALUES (
	16015,
	'015',
	16,
	'Boise'
);
INSERT INTO CWMS_COUNTY VALUES (
	16017,
	'017',
	16,
	'Bonner'
);
INSERT INTO CWMS_COUNTY VALUES (
	16019,
	'019',
	16,
	'Bonneville'
);
INSERT INTO CWMS_COUNTY VALUES (
	16021,
	'021',
	16,
	'Boundary'
);
INSERT INTO CWMS_COUNTY VALUES (
	16023,
	'023',
	16,
	'Butte'
);
INSERT INTO CWMS_COUNTY VALUES (
	16025,
	'025',
	16,
	'Camas'
);
INSERT INTO CWMS_COUNTY VALUES (
	16027,
	'027',
	16,
	'Canyon'
);
INSERT INTO CWMS_COUNTY VALUES (
	16029,
	'029',
	16,
	'Caribou'
);
INSERT INTO CWMS_COUNTY VALUES (
	16031,
	'031',
	16,
	'Cassia'
);
INSERT INTO CWMS_COUNTY VALUES (
	16033,
	'033',
	16,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	16035,
	'035',
	16,
	'Clearwater'
);
INSERT INTO CWMS_COUNTY VALUES (
	16037,
	'037',
	16,
	'Custer'
);
INSERT INTO CWMS_COUNTY VALUES (
	16039,
	'039',
	16,
	'Elmore'
);
INSERT INTO CWMS_COUNTY VALUES (
	16041,
	'041',
	16,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	16043,
	'043',
	16,
	'Fremont'
);
INSERT INTO CWMS_COUNTY VALUES (
	16045,
	'045',
	16,
	'Gem'
);
INSERT INTO CWMS_COUNTY VALUES (
	16047,
	'047',
	16,
	'Gooding'
);
INSERT INTO CWMS_COUNTY VALUES (
	16049,
	'049',
	16,
	'Idaho'
);
INSERT INTO CWMS_COUNTY VALUES (
	16051,
	'051',
	16,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	16053,
	'053',
	16,
	'Jerome'
);
INSERT INTO CWMS_COUNTY VALUES (
	16055,
	'055',
	16,
	'Kootenai'
);
INSERT INTO CWMS_COUNTY VALUES (
	16057,
	'057',
	16,
	'Latah'
);
INSERT INTO CWMS_COUNTY VALUES (
	16059,
	'059',
	16,
	'Lemhi'
);
INSERT INTO CWMS_COUNTY VALUES (
	16061,
	'061',
	16,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	16063,
	'063',
	16,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	16065,
	'065',
	16,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	16067,
	'067',
	16,
	'Minidoka'
);
INSERT INTO CWMS_COUNTY VALUES (
	16069,
	'069',
	16,
	'Nez Perce'
);
INSERT INTO CWMS_COUNTY VALUES (
	16071,
	'071',
	16,
	'Oneida'
);
INSERT INTO CWMS_COUNTY VALUES (
	16073,
	'073',
	16,
	'Owyhee'
);
INSERT INTO CWMS_COUNTY VALUES (
	16075,
	'075',
	16,
	'Payette'
);
INSERT INTO CWMS_COUNTY VALUES (
	16077,
	'077',
	16,
	'Power'
);
INSERT INTO CWMS_COUNTY VALUES (
	16079,
	'079',
	16,
	'Shoshone'
);
INSERT INTO CWMS_COUNTY VALUES (
	16081,
	'081',
	16,
	'Teton'
);
INSERT INTO CWMS_COUNTY VALUES (
	16083,
	'083',
	16,
	'Twin Falls'
);
INSERT INTO CWMS_COUNTY VALUES (
	16085,
	'085',
	16,
	'Valley'
);
INSERT INTO CWMS_COUNTY VALUES (
	16087,
	'087',
	16,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	17000,
	'000',
	17,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	17001,
	'001',
	17,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	17003,
	'003',
	17,
	'Alexander'
);
INSERT INTO CWMS_COUNTY VALUES (
	17005,
	'005',
	17,
	'Bond'
);
INSERT INTO CWMS_COUNTY VALUES (
	17007,
	'007',
	17,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	17009,
	'009',
	17,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	17011,
	'011',
	17,
	'Bureau'
);
INSERT INTO CWMS_COUNTY VALUES (
	17013,
	'013',
	17,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	17015,
	'015',
	17,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	17017,
	'017',
	17,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	17019,
	'019',
	17,
	'Champaign'
);
INSERT INTO CWMS_COUNTY VALUES (
	17021,
	'021',
	17,
	'Christian'
);
INSERT INTO CWMS_COUNTY VALUES (
	17023,
	'023',
	17,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	17025,
	'025',
	17,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	17027,
	'027',
	17,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	17029,
	'029',
	17,
	'Coles'
);
INSERT INTO CWMS_COUNTY VALUES (
	17031,
	'031',
	17,
	'Cook'
);
INSERT INTO CWMS_COUNTY VALUES (
	17033,
	'033',
	17,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	17035,
	'035',
	17,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	17037,
	'037',
	17,
	'De Kalb'
);
INSERT INTO CWMS_COUNTY VALUES (
	17039,
	'039',
	17,
	'De Witt'
);
INSERT INTO CWMS_COUNTY VALUES (
	17041,
	'041',
	17,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	17043,
	'043',
	17,
	'Du Page'
);
INSERT INTO CWMS_COUNTY VALUES (
	17045,
	'045',
	17,
	'Edgar'
);
INSERT INTO CWMS_COUNTY VALUES (
	17047,
	'047',
	17,
	'Edwards'
);
INSERT INTO CWMS_COUNTY VALUES (
	17049,
	'049',
	17,
	'Effingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	17051,
	'051',
	17,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	17053,
	'053',
	17,
	'Ford'
);
INSERT INTO CWMS_COUNTY VALUES (
	17055,
	'055',
	17,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	17057,
	'057',
	17,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	17059,
	'059',
	17,
	'Gallatin'
);
INSERT INTO CWMS_COUNTY VALUES (
	17061,
	'061',
	17,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	17063,
	'063',
	17,
	'Grundy'
);
INSERT INTO CWMS_COUNTY VALUES (
	17065,
	'065',
	17,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	17067,
	'067',
	17,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	17069,
	'069',
	17,
	'Hardin'
);
INSERT INTO CWMS_COUNTY VALUES (
	17071,
	'071',
	17,
	'Henderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	17073,
	'073',
	17,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	17075,
	'075',
	17,
	'Iroquois'
);
INSERT INTO CWMS_COUNTY VALUES (
	17077,
	'077',
	17,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	17079,
	'079',
	17,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	17081,
	'081',
	17,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	17083,
	'083',
	17,
	'Jersey'
);
INSERT INTO CWMS_COUNTY VALUES (
	17085,
	'085',
	17,
	'Jo Daviess'
);
INSERT INTO CWMS_COUNTY VALUES (
	17087,
	'087',
	17,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	17089,
	'089',
	17,
	'Kane'
);
INSERT INTO CWMS_COUNTY VALUES (
	17091,
	'091',
	17,
	'Kankakee'
);
INSERT INTO CWMS_COUNTY VALUES (
	17093,
	'093',
	17,
	'Kendall'
);
INSERT INTO CWMS_COUNTY VALUES (
	17095,
	'095',
	17,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	17097,
	'097',
	17,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	17099,
	'099',
	17,
	'La Salle'
);
INSERT INTO CWMS_COUNTY VALUES (
	17101,
	'101',
	17,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	17103,
	'103',
	17,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	17105,
	'105',
	17,
	'Livingston'
);
INSERT INTO CWMS_COUNTY VALUES (
	17107,
	'107',
	17,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	17109,
	'109',
	17,
	'McDonough'
);
INSERT INTO CWMS_COUNTY VALUES (
	17111,
	'111',
	17,
	'McHenry'
);
INSERT INTO CWMS_COUNTY VALUES (
	17113,
	'113',
	17,
	'McLean'
);
INSERT INTO CWMS_COUNTY VALUES (
	17115,
	'115',
	17,
	'Macon'
);
INSERT INTO CWMS_COUNTY VALUES (
	17117,
	'117',
	17,
	'Macoupin'
);
INSERT INTO CWMS_COUNTY VALUES (
	17119,
	'119',
	17,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	17121,
	'121',
	17,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	17123,
	'123',
	17,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	17125,
	'125',
	17,
	'Mason'
);
INSERT INTO CWMS_COUNTY VALUES (
	17127,
	'127',
	17,
	'Massac'
);
INSERT INTO CWMS_COUNTY VALUES (
	17129,
	'129',
	17,
	'Menard'
);
INSERT INTO CWMS_COUNTY VALUES (
	17131,
	'131',
	17,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	17133,
	'133',
	17,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	17135,
	'135',
	17,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	17137,
	'137',
	17,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	17139,
	'139',
	17,
	'Moultrie'
);
INSERT INTO CWMS_COUNTY VALUES (
	17141,
	'141',
	17,
	'Ogle'
);
INSERT INTO CWMS_COUNTY VALUES (
	17143,
	'143',
	17,
	'Peoria'
);
INSERT INTO CWMS_COUNTY VALUES (
	17145,
	'145',
	17,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	17147,
	'147',
	17,
	'Piatt'
);
INSERT INTO CWMS_COUNTY VALUES (
	17149,
	'149',
	17,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	17151,
	'151',
	17,
	'Pope'
);
INSERT INTO CWMS_COUNTY VALUES (
	17153,
	'153',
	17,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	17155,
	'155',
	17,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	17157,
	'157',
	17,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	17159,
	'159',
	17,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	17161,
	'161',
	17,
	'Rock Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	17163,
	'163',
	17,
	'St. Clair'
);
INSERT INTO CWMS_COUNTY VALUES (
	17165,
	'165',
	17,
	'Saline'
);
INSERT INTO CWMS_COUNTY VALUES (
	17167,
	'167',
	17,
	'Sangamon'
);
INSERT INTO CWMS_COUNTY VALUES (
	17169,
	'169',
	17,
	'Schuyler'
);
INSERT INTO CWMS_COUNTY VALUES (
	17171,
	'171',
	17,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	17173,
	'173',
	17,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	17175,
	'175',
	17,
	'Stark'
);
INSERT INTO CWMS_COUNTY VALUES (
	17177,
	'177',
	17,
	'Stephenson'
);
INSERT INTO CWMS_COUNTY VALUES (
	17179,
	'179',
	17,
	'Tazewell'
);
INSERT INTO CWMS_COUNTY VALUES (
	17181,
	'181',
	17,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	17183,
	'183',
	17,
	'Vermilion'
);
INSERT INTO CWMS_COUNTY VALUES (
	17185,
	'185',
	17,
	'Wabash'
);
INSERT INTO CWMS_COUNTY VALUES (
	17187,
	'187',
	17,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	17189,
	'189',
	17,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	17191,
	'191',
	17,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	17193,
	'193',
	17,
	'White'
);
INSERT INTO CWMS_COUNTY VALUES (
	17195,
	'195',
	17,
	'Whiteside'
);
INSERT INTO CWMS_COUNTY VALUES (
	17197,
	'197',
	17,
	'Will'
);
INSERT INTO CWMS_COUNTY VALUES (
	17199,
	'199',
	17,
	'Williamson'
);
INSERT INTO CWMS_COUNTY VALUES (
	17201,
	'201',
	17,
	'Winnebago'
);
INSERT INTO CWMS_COUNTY VALUES (
	17203,
	'203',
	17,
	'Woodford'
);
INSERT INTO CWMS_COUNTY VALUES (
	18000,
	'000',
	18,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	18001,
	'001',
	18,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	18003,
	'003',
	18,
	'Allen'
);
INSERT INTO CWMS_COUNTY VALUES (
	18005,
	'005',
	18,
	'Bartholomew'
);
INSERT INTO CWMS_COUNTY VALUES (
	18007,
	'007',
	18,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	18009,
	'009',
	18,
	'Blackford'
);
INSERT INTO CWMS_COUNTY VALUES (
	18011,
	'011',
	18,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	18013,
	'013',
	18,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	18015,
	'015',
	18,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	18017,
	'017',
	18,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	18019,
	'019',
	18,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	18021,
	'021',
	18,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	18023,
	'023',
	18,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	18025,
	'025',
	18,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	18027,
	'027',
	18,
	'Daviess'
);
INSERT INTO CWMS_COUNTY VALUES (
	18029,
	'029',
	18,
	'Dearborn'
);
INSERT INTO CWMS_COUNTY VALUES (
	18031,
	'031',
	18,
	'Decatur'
);
INSERT INTO CWMS_COUNTY VALUES (
	18033,
	'033',
	18,
	'De Kalb'
);
INSERT INTO CWMS_COUNTY VALUES (
	18035,
	'035',
	18,
	'Delaware'
);
INSERT INTO CWMS_COUNTY VALUES (
	18037,
	'037',
	18,
	'Dubois'
);
INSERT INTO CWMS_COUNTY VALUES (
	18039,
	'039',
	18,
	'Elkhart'
);
INSERT INTO CWMS_COUNTY VALUES (
	18041,
	'041',
	18,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	18043,
	'043',
	18,
	'Floyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	18045,
	'045',
	18,
	'Fountain'
);
INSERT INTO CWMS_COUNTY VALUES (
	18047,
	'047',
	18,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	18049,
	'049',
	18,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	18051,
	'051',
	18,
	'Gibson'
);
INSERT INTO CWMS_COUNTY VALUES (
	18053,
	'053',
	18,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	18055,
	'055',
	18,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	18057,
	'057',
	18,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	18059,
	'059',
	18,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	18061,
	'061',
	18,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	18063,
	'063',
	18,
	'Hendricks'
);
INSERT INTO CWMS_COUNTY VALUES (
	18065,
	'065',
	18,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	18067,
	'067',
	18,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	18069,
	'069',
	18,
	'Huntington'
);
INSERT INTO CWMS_COUNTY VALUES (
	18071,
	'071',
	18,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	18073,
	'073',
	18,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	18075,
	'075',
	18,
	'Jay'
);
INSERT INTO CWMS_COUNTY VALUES (
	18077,
	'077',
	18,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	18079,
	'079',
	18,
	'Jennings'
);
INSERT INTO CWMS_COUNTY VALUES (
	18081,
	'081',
	18,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	18083,
	'083',
	18,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	18085,
	'085',
	18,
	'Kosciusko'
);
INSERT INTO CWMS_COUNTY VALUES (
	18087,
	'087',
	18,
	'Lagrange'
);
INSERT INTO CWMS_COUNTY VALUES (
	18089,
	'089',
	18,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	18091,
	'091',
	18,
	'La Porte'
);
INSERT INTO CWMS_COUNTY VALUES (
	18093,
	'093',
	18,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	18095,
	'095',
	18,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	18097,
	'097',
	18,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	18099,
	'099',
	18,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	18101,
	'101',
	18,
	'Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	18103,
	'103',
	18,
	'Miami'
);
INSERT INTO CWMS_COUNTY VALUES (
	18105,
	'105',
	18,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	18107,
	'107',
	18,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	18109,
	'109',
	18,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	18111,
	'111',
	18,
	'Newton'
);
INSERT INTO CWMS_COUNTY VALUES (
	18113,
	'113',
	18,
	'Noble'
);
INSERT INTO CWMS_COUNTY VALUES (
	18115,
	'115',
	18,
	'Ohio'
);
INSERT INTO CWMS_COUNTY VALUES (
	18117,
	'117',
	18,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	18119,
	'119',
	18,
	'Owen'
);
INSERT INTO CWMS_COUNTY VALUES (
	18121,
	'121',
	18,
	'Parke'
);
INSERT INTO CWMS_COUNTY VALUES (
	18123,
	'123',
	18,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	18125,
	'125',
	18,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	18127,
	'127',
	18,
	'Porter'
);
INSERT INTO CWMS_COUNTY VALUES (
	18129,
	'129',
	18,
	'Posey'
);
INSERT INTO CWMS_COUNTY VALUES (
	18131,
	'131',
	18,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	18133,
	'133',
	18,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	18135,
	'135',
	18,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	18137,
	'137',
	18,
	'Ripley'
);
INSERT INTO CWMS_COUNTY VALUES (
	18139,
	'139',
	18,
	'Rush'
);
INSERT INTO CWMS_COUNTY VALUES (
	18141,
	'141',
	18,
	'St. Joseph'
);
INSERT INTO CWMS_COUNTY VALUES (
	18143,
	'143',
	18,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	18145,
	'145',
	18,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	18147,
	'147',
	18,
	'Spencer'
);
INSERT INTO CWMS_COUNTY VALUES (
	18149,
	'149',
	18,
	'Starke'
);
INSERT INTO CWMS_COUNTY VALUES (
	18151,
	'151',
	18,
	'Steuben'
);
INSERT INTO CWMS_COUNTY VALUES (
	18153,
	'153',
	18,
	'Sullivan'
);
INSERT INTO CWMS_COUNTY VALUES (
	18155,
	'155',
	18,
	'Switzerland'
);
INSERT INTO CWMS_COUNTY VALUES (
	18157,
	'157',
	18,
	'Tippecanoe'
);
INSERT INTO CWMS_COUNTY VALUES (
	18159,
	'159',
	18,
	'Tipton'
);
INSERT INTO CWMS_COUNTY VALUES (
	18161,
	'161',
	18,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	18163,
	'163',
	18,
	'Vanderburgh'
);
INSERT INTO CWMS_COUNTY VALUES (
	18165,
	'165',
	18,
	'Vermillion'
);
INSERT INTO CWMS_COUNTY VALUES (
	18167,
	'167',
	18,
	'Vigo'
);
INSERT INTO CWMS_COUNTY VALUES (
	18169,
	'169',
	18,
	'Wabash'
);
INSERT INTO CWMS_COUNTY VALUES (
	18171,
	'171',
	18,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	18173,
	'173',
	18,
	'Warrick'
);
INSERT INTO CWMS_COUNTY VALUES (
	18175,
	'175',
	18,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	18177,
	'177',
	18,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	18179,
	'179',
	18,
	'Wells'
);
INSERT INTO CWMS_COUNTY VALUES (
	18181,
	'181',
	18,
	'White'
);
INSERT INTO CWMS_COUNTY VALUES (
	18183,
	'183',
	18,
	'Whitley'
);
INSERT INTO CWMS_COUNTY VALUES (
	19000,
	'000',
	19,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	19001,
	'001',
	19,
	'Adair'
);
INSERT INTO CWMS_COUNTY VALUES (
	19003,
	'003',
	19,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	19005,
	'005',
	19,
	'Allamakee'
);
INSERT INTO CWMS_COUNTY VALUES (
	19007,
	'007',
	19,
	'Appanoose'
);
INSERT INTO CWMS_COUNTY VALUES (
	19009,
	'009',
	19,
	'Audubon'
);
INSERT INTO CWMS_COUNTY VALUES (
	19011,
	'011',
	19,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	19013,
	'013',
	19,
	'Black Hawk'
);
INSERT INTO CWMS_COUNTY VALUES (
	19015,
	'015',
	19,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	19017,
	'017',
	19,
	'Bremer'
);
INSERT INTO CWMS_COUNTY VALUES (
	19019,
	'019',
	19,
	'Buchanan'
);
INSERT INTO CWMS_COUNTY VALUES (
	19021,
	'021',
	19,
	'Buena Vista'
);
INSERT INTO CWMS_COUNTY VALUES (
	19023,
	'023',
	19,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	19025,
	'025',
	19,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	19027,
	'027',
	19,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	19029,
	'029',
	19,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	19031,
	'031',
	19,
	'Cedar'
);
INSERT INTO CWMS_COUNTY VALUES (
	19033,
	'033',
	19,
	'Cerro Gordo'
);
INSERT INTO CWMS_COUNTY VALUES (
	19035,
	'035',
	19,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	19037,
	'037',
	19,
	'Chickasaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	19039,
	'039',
	19,
	'Clarke'
);
INSERT INTO CWMS_COUNTY VALUES (
	19041,
	'041',
	19,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	19043,
	'043',
	19,
	'Clayton'
);
INSERT INTO CWMS_COUNTY VALUES (
	19045,
	'045',
	19,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	19047,
	'047',
	19,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	19049,
	'049',
	19,
	'Dallas'
);
INSERT INTO CWMS_COUNTY VALUES (
	19051,
	'051',
	19,
	'Davis'
);
INSERT INTO CWMS_COUNTY VALUES (
	19053,
	'053',
	19,
	'Decatur'
);
INSERT INTO CWMS_COUNTY VALUES (
	19055,
	'055',
	19,
	'Delaware'
);
INSERT INTO CWMS_COUNTY VALUES (
	19057,
	'057',
	19,
	'Des Moines'
);
INSERT INTO CWMS_COUNTY VALUES (
	19059,
	'059',
	19,
	'Dickinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	19061,
	'061',
	19,
	'Dubuque'
);
INSERT INTO CWMS_COUNTY VALUES (
	19063,
	'063',
	19,
	'Emmet'
);
INSERT INTO CWMS_COUNTY VALUES (
	19065,
	'065',
	19,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	19067,
	'067',
	19,
	'Floyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	19069,
	'069',
	19,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	19071,
	'071',
	19,
	'Fremont'
);
INSERT INTO CWMS_COUNTY VALUES (
	19073,
	'073',
	19,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	19075,
	'075',
	19,
	'Grundy'
);
INSERT INTO CWMS_COUNTY VALUES (
	19077,
	'077',
	19,
	'Guthrie'
);
INSERT INTO CWMS_COUNTY VALUES (
	19079,
	'079',
	19,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	19081,
	'081',
	19,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	19083,
	'083',
	19,
	'Hardin'
);
INSERT INTO CWMS_COUNTY VALUES (
	19085,
	'085',
	19,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	19087,
	'087',
	19,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	19089,
	'089',
	19,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	19091,
	'091',
	19,
	'Humboldt'
);
INSERT INTO CWMS_COUNTY VALUES (
	19093,
	'093',
	19,
	'Ida'
);
INSERT INTO CWMS_COUNTY VALUES (
	19095,
	'095',
	19,
	'Iowa'
);
INSERT INTO CWMS_COUNTY VALUES (
	19097,
	'097',
	19,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	19099,
	'099',
	19,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	19101,
	'101',
	19,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	19103,
	'103',
	19,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	19105,
	'105',
	19,
	'Jones'
);
INSERT INTO CWMS_COUNTY VALUES (
	19107,
	'107',
	19,
	'Keokuk'
);
INSERT INTO CWMS_COUNTY VALUES (
	19109,
	'109',
	19,
	'Kossuth'
);
INSERT INTO CWMS_COUNTY VALUES (
	19111,
	'111',
	19,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	19113,
	'113',
	19,
	'Linn'
);
INSERT INTO CWMS_COUNTY VALUES (
	19115,
	'115',
	19,
	'Louisa'
);
INSERT INTO CWMS_COUNTY VALUES (
	19117,
	'117',
	19,
	'Lucas'
);
INSERT INTO CWMS_COUNTY VALUES (
	19119,
	'119',
	19,
	'Lyon'
);
INSERT INTO CWMS_COUNTY VALUES (
	19121,
	'121',
	19,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	19123,
	'123',
	19,
	'Mahaska'
);
INSERT INTO CWMS_COUNTY VALUES (
	19125,
	'125',
	19,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	19127,
	'127',
	19,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	19129,
	'129',
	19,
	'Mills'
);
INSERT INTO CWMS_COUNTY VALUES (
	19131,
	'131',
	19,
	'Mitchell'
);
INSERT INTO CWMS_COUNTY VALUES (
	19133,
	'133',
	19,
	'Monona'
);
INSERT INTO CWMS_COUNTY VALUES (
	19135,
	'135',
	19,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	19137,
	'137',
	19,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	19139,
	'139',
	19,
	'Muscatine'
);
INSERT INTO CWMS_COUNTY VALUES (
	19141,
	'141',
	19,
	'OBrien'
);
INSERT INTO CWMS_COUNTY VALUES (
	19143,
	'143',
	19,
	'Osceola'
);
INSERT INTO CWMS_COUNTY VALUES (
	19145,
	'145',
	19,
	'Page'
);
INSERT INTO CWMS_COUNTY VALUES (
	19147,
	'147',
	19,
	'Palo Alto'
);
INSERT INTO CWMS_COUNTY VALUES (
	19149,
	'149',
	19,
	'Plymouth'
);
INSERT INTO CWMS_COUNTY VALUES (
	19151,
	'151',
	19,
	'Pocahontas'
);
INSERT INTO CWMS_COUNTY VALUES (
	19153,
	'153',
	19,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	19155,
	'155',
	19,
	'Pottawattamie'
);
INSERT INTO CWMS_COUNTY VALUES (
	19157,
	'157',
	19,
	'Poweshiek'
);
INSERT INTO CWMS_COUNTY VALUES (
	19159,
	'159',
	19,
	'Ringgold'
);
INSERT INTO CWMS_COUNTY VALUES (
	19161,
	'161',
	19,
	'Sac'
);
INSERT INTO CWMS_COUNTY VALUES (
	19163,
	'163',
	19,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	19165,
	'165',
	19,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	19167,
	'167',
	19,
	'Sioux'
);
INSERT INTO CWMS_COUNTY VALUES (
	19169,
	'169',
	19,
	'Story'
);
INSERT INTO CWMS_COUNTY VALUES (
	19171,
	'171',
	19,
	'Tama'
);
INSERT INTO CWMS_COUNTY VALUES (
	19173,
	'173',
	19,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	19175,
	'175',
	19,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	19177,
	'177',
	19,
	'Van Buren'
);
INSERT INTO CWMS_COUNTY VALUES (
	19179,
	'179',
	19,
	'Wapello'
);
INSERT INTO CWMS_COUNTY VALUES (
	19181,
	'181',
	19,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	19183,
	'183',
	19,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	19185,
	'185',
	19,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	19187,
	'187',
	19,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	19189,
	'189',
	19,
	'Winnebago'
);
INSERT INTO CWMS_COUNTY VALUES (
	19191,
	'191',
	19,
	'Winneshiek'
);
INSERT INTO CWMS_COUNTY VALUES (
	19193,
	'193',
	19,
	'Woodbury'
);
INSERT INTO CWMS_COUNTY VALUES (
	19195,
	'195',
	19,
	'Worth'
);
INSERT INTO CWMS_COUNTY VALUES (
	19197,
	'197',
	19,
	'Wright'
);
INSERT INTO CWMS_COUNTY VALUES (
	20000,
	'000',
	20,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	20001,
	'001',
	20,
	'Allen'
);
INSERT INTO CWMS_COUNTY VALUES (
	20003,
	'003',
	20,
	'Anderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20005,
	'005',
	20,
	'Atchison'
);
INSERT INTO CWMS_COUNTY VALUES (
	20007,
	'007',
	20,
	'Barber'
);
INSERT INTO CWMS_COUNTY VALUES (
	20009,
	'009',
	20,
	'Barton'
);
INSERT INTO CWMS_COUNTY VALUES (
	20011,
	'011',
	20,
	'Bourbon'
);
INSERT INTO CWMS_COUNTY VALUES (
	20013,
	'013',
	20,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	20015,
	'015',
	20,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	20017,
	'017',
	20,
	'Chase'
);
INSERT INTO CWMS_COUNTY VALUES (
	20019,
	'019',
	20,
	'Chautauqua'
);
INSERT INTO CWMS_COUNTY VALUES (
	20021,
	'021',
	20,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	20023,
	'023',
	20,
	'Cheyenne'
);
INSERT INTO CWMS_COUNTY VALUES (
	20025,
	'025',
	20,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	20027,
	'027',
	20,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	20029,
	'029',
	20,
	'Cloud'
);
INSERT INTO CWMS_COUNTY VALUES (
	20031,
	'031',
	20,
	'Coffey'
);
INSERT INTO CWMS_COUNTY VALUES (
	20033,
	'033',
	20,
	'Comanche'
);
INSERT INTO CWMS_COUNTY VALUES (
	20035,
	'035',
	20,
	'Cowley'
);
INSERT INTO CWMS_COUNTY VALUES (
	20037,
	'037',
	20,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	20039,
	'039',
	20,
	'Decatur'
);
INSERT INTO CWMS_COUNTY VALUES (
	20041,
	'041',
	20,
	'Dickinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20043,
	'043',
	20,
	'Doniphan'
);
INSERT INTO CWMS_COUNTY VALUES (
	20045,
	'045',
	20,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	20047,
	'047',
	20,
	'Edwards'
);
INSERT INTO CWMS_COUNTY VALUES (
	20049,
	'049',
	20,
	'Elk'
);
INSERT INTO CWMS_COUNTY VALUES (
	20051,
	'051',
	20,
	'Ellis'
);
INSERT INTO CWMS_COUNTY VALUES (
	20053,
	'053',
	20,
	'Ellsworth'
);
INSERT INTO CWMS_COUNTY VALUES (
	20055,
	'055',
	20,
	'Finney'
);
INSERT INTO CWMS_COUNTY VALUES (
	20057,
	'057',
	20,
	'Ford'
);
INSERT INTO CWMS_COUNTY VALUES (
	20059,
	'059',
	20,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	20061,
	'061',
	20,
	'Geary'
);
INSERT INTO CWMS_COUNTY VALUES (
	20063,
	'063',
	20,
	'Gove'
);
INSERT INTO CWMS_COUNTY VALUES (
	20065,
	'065',
	20,
	'Graham'
);
INSERT INTO CWMS_COUNTY VALUES (
	20067,
	'067',
	20,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	20069,
	'069',
	20,
	'Gray'
);
INSERT INTO CWMS_COUNTY VALUES (
	20071,
	'071',
	20,
	'Greeley'
);
INSERT INTO CWMS_COUNTY VALUES (
	20073,
	'073',
	20,
	'Greenwood'
);
INSERT INTO CWMS_COUNTY VALUES (
	20075,
	'075',
	20,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	20077,
	'077',
	20,
	'Harper'
);
INSERT INTO CWMS_COUNTY VALUES (
	20079,
	'079',
	20,
	'Harvey'
);
INSERT INTO CWMS_COUNTY VALUES (
	20081,
	'081',
	20,
	'Haskell'
);
INSERT INTO CWMS_COUNTY VALUES (
	20083,
	'083',
	20,
	'Hodgeman'
);
INSERT INTO CWMS_COUNTY VALUES (
	20085,
	'085',
	20,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20087,
	'087',
	20,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20089,
	'089',
	20,
	'Jewell'
);
INSERT INTO CWMS_COUNTY VALUES (
	20091,
	'091',
	20,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20093,
	'093',
	20,
	'Kearny'
);
INSERT INTO CWMS_COUNTY VALUES (
	20095,
	'095',
	20,
	'Kingman'
);
INSERT INTO CWMS_COUNTY VALUES (
	20097,
	'097',
	20,
	'Kiowa'
);
INSERT INTO CWMS_COUNTY VALUES (
	20099,
	'099',
	20,
	'Labette'
);
INSERT INTO CWMS_COUNTY VALUES (
	20101,
	'101',
	20,
	'Lane'
);
INSERT INTO CWMS_COUNTY VALUES (
	20103,
	'103',
	20,
	'Leavenworth'
);
INSERT INTO CWMS_COUNTY VALUES (
	20105,
	'105',
	20,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	20107,
	'107',
	20,
	'Linn'
);
INSERT INTO CWMS_COUNTY VALUES (
	20109,
	'109',
	20,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	20111,
	'111',
	20,
	'Lyon'
);
INSERT INTO CWMS_COUNTY VALUES (
	20113,
	'113',
	20,
	'McPherson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20115,
	'115',
	20,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	20117,
	'117',
	20,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	20119,
	'119',
	20,
	'Meade'
);
INSERT INTO CWMS_COUNTY VALUES (
	20121,
	'121',
	20,
	'Miami'
);
INSERT INTO CWMS_COUNTY VALUES (
	20123,
	'123',
	20,
	'Mitchell'
);
INSERT INTO CWMS_COUNTY VALUES (
	20125,
	'125',
	20,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	20127,
	'127',
	20,
	'Morris'
);
INSERT INTO CWMS_COUNTY VALUES (
	20129,
	'129',
	20,
	'Morton'
);
INSERT INTO CWMS_COUNTY VALUES (
	20131,
	'131',
	20,
	'Nemaha'
);
INSERT INTO CWMS_COUNTY VALUES (
	20133,
	'133',
	20,
	'Neosho'
);
INSERT INTO CWMS_COUNTY VALUES (
	20135,
	'135',
	20,
	'Ness'
);
INSERT INTO CWMS_COUNTY VALUES (
	20137,
	'137',
	20,
	'Norton'
);
INSERT INTO CWMS_COUNTY VALUES (
	20139,
	'139',
	20,
	'Osage'
);
INSERT INTO CWMS_COUNTY VALUES (
	20141,
	'141',
	20,
	'Osborne'
);
INSERT INTO CWMS_COUNTY VALUES (
	20143,
	'143',
	20,
	'Ottawa'
);
INSERT INTO CWMS_COUNTY VALUES (
	20145,
	'145',
	20,
	'Pawnee'
);
INSERT INTO CWMS_COUNTY VALUES (
	20147,
	'147',
	20,
	'Phillips'
);
INSERT INTO CWMS_COUNTY VALUES (
	20149,
	'149',
	20,
	'Pottawatomie'
);
INSERT INTO CWMS_COUNTY VALUES (
	20151,
	'151',
	20,
	'Pratt'
);
INSERT INTO CWMS_COUNTY VALUES (
	20153,
	'153',
	20,
	'Rawlins'
);
INSERT INTO CWMS_COUNTY VALUES (
	20155,
	'155',
	20,
	'Reno'
);
INSERT INTO CWMS_COUNTY VALUES (
	20157,
	'157',
	20,
	'Republic'
);
INSERT INTO CWMS_COUNTY VALUES (
	20159,
	'159',
	20,
	'Rice'
);
INSERT INTO CWMS_COUNTY VALUES (
	20161,
	'161',
	20,
	'Riley'
);
INSERT INTO CWMS_COUNTY VALUES (
	20163,
	'163',
	20,
	'Rooks'
);
INSERT INTO CWMS_COUNTY VALUES (
	20165,
	'165',
	20,
	'Rush'
);
INSERT INTO CWMS_COUNTY VALUES (
	20167,
	'167',
	20,
	'Russell'
);
INSERT INTO CWMS_COUNTY VALUES (
	20169,
	'169',
	20,
	'Saline'
);
INSERT INTO CWMS_COUNTY VALUES (
	20171,
	'171',
	20,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	20173,
	'173',
	20,
	'Sedgwick'
);
INSERT INTO CWMS_COUNTY VALUES (
	20175,
	'175',
	20,
	'Seward'
);
INSERT INTO CWMS_COUNTY VALUES (
	20177,
	'177',
	20,
	'Shawnee'
);
INSERT INTO CWMS_COUNTY VALUES (
	20179,
	'179',
	20,
	'Sheridan'
);
INSERT INTO CWMS_COUNTY VALUES (
	20181,
	'181',
	20,
	'Sherman'
);
INSERT INTO CWMS_COUNTY VALUES (
	20183,
	'183',
	20,
	'Smith'
);
INSERT INTO CWMS_COUNTY VALUES (
	20185,
	'185',
	20,
	'Stafford'
);
INSERT INTO CWMS_COUNTY VALUES (
	20187,
	'187',
	20,
	'Stanton'
);
INSERT INTO CWMS_COUNTY VALUES (
	20189,
	'189',
	20,
	'Stevens'
);
INSERT INTO CWMS_COUNTY VALUES (
	20191,
	'191',
	20,
	'Sumner'
);
INSERT INTO CWMS_COUNTY VALUES (
	20193,
	'193',
	20,
	'Thomas'
);
INSERT INTO CWMS_COUNTY VALUES (
	20195,
	'195',
	20,
	'Trego'
);
INSERT INTO CWMS_COUNTY VALUES (
	20197,
	'197',
	20,
	'Wabaunsee'
);
INSERT INTO CWMS_COUNTY VALUES (
	20199,
	'199',
	20,
	'Wallace'
);
INSERT INTO CWMS_COUNTY VALUES (
	20201,
	'201',
	20,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	20203,
	'203',
	20,
	'Wichita'
);
INSERT INTO CWMS_COUNTY VALUES (
	20205,
	'205',
	20,
	'Wilson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20207,
	'207',
	20,
	'Woodson'
);
INSERT INTO CWMS_COUNTY VALUES (
	20209,
	'209',
	20,
	'Wyandotte'
);
INSERT INTO CWMS_COUNTY VALUES (
	21000,
	'000',
	21,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	21001,
	'001',
	21,
	'Adair'
);
INSERT INTO CWMS_COUNTY VALUES (
	21003,
	'003',
	21,
	'Allen'
);
INSERT INTO CWMS_COUNTY VALUES (
	21005,
	'005',
	21,
	'Anderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21007,
	'007',
	21,
	'Ballard'
);
INSERT INTO CWMS_COUNTY VALUES (
	21009,
	'009',
	21,
	'Barren'
);
INSERT INTO CWMS_COUNTY VALUES (
	21011,
	'011',
	21,
	'Bath'
);
INSERT INTO CWMS_COUNTY VALUES (
	21013,
	'013',
	21,
	'Bell'
);
INSERT INTO CWMS_COUNTY VALUES (
	21015,
	'015',
	21,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	21017,
	'017',
	21,
	'Bourbon'
);
INSERT INTO CWMS_COUNTY VALUES (
	21019,
	'019',
	21,
	'Boyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	21021,
	'021',
	21,
	'Boyle'
);
INSERT INTO CWMS_COUNTY VALUES (
	21023,
	'023',
	21,
	'Bracken'
);
INSERT INTO CWMS_COUNTY VALUES (
	21025,
	'025',
	21,
	'Breathitt'
);
INSERT INTO CWMS_COUNTY VALUES (
	21027,
	'027',
	21,
	'Breckinridge'
);
INSERT INTO CWMS_COUNTY VALUES (
	21029,
	'029',
	21,
	'Bullitt'
);
INSERT INTO CWMS_COUNTY VALUES (
	21031,
	'031',
	21,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	21033,
	'033',
	21,
	'Caldwell'
);
INSERT INTO CWMS_COUNTY VALUES (
	21035,
	'035',
	21,
	'Calloway'
);
INSERT INTO CWMS_COUNTY VALUES (
	21037,
	'037',
	21,
	'Campbell'
);
INSERT INTO CWMS_COUNTY VALUES (
	21039,
	'039',
	21,
	'Carlisle'
);
INSERT INTO CWMS_COUNTY VALUES (
	21041,
	'041',
	21,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	21043,
	'043',
	21,
	'Carter'
);
INSERT INTO CWMS_COUNTY VALUES (
	21045,
	'045',
	21,
	'Casey'
);
INSERT INTO CWMS_COUNTY VALUES (
	21047,
	'047',
	21,
	'Christian'
);
INSERT INTO CWMS_COUNTY VALUES (
	21049,
	'049',
	21,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	21051,
	'051',
	21,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	21053,
	'053',
	21,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	21055,
	'055',
	21,
	'Crittenden'
);
INSERT INTO CWMS_COUNTY VALUES (
	21057,
	'057',
	21,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	21059,
	'059',
	21,
	'Daviess'
);
INSERT INTO CWMS_COUNTY VALUES (
	21061,
	'061',
	21,
	'Edmonson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21063,
	'063',
	21,
	'Elliott'
);
INSERT INTO CWMS_COUNTY VALUES (
	21065,
	'065',
	21,
	'Estill'
);
INSERT INTO CWMS_COUNTY VALUES (
	21067,
	'067',
	21,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	21069,
	'069',
	21,
	'Fleming'
);
INSERT INTO CWMS_COUNTY VALUES (
	21071,
	'071',
	21,
	'Floyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	21073,
	'073',
	21,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	21075,
	'075',
	21,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	21077,
	'077',
	21,
	'Gallatin'
);
INSERT INTO CWMS_COUNTY VALUES (
	21079,
	'079',
	21,
	'Garrard'
);
INSERT INTO CWMS_COUNTY VALUES (
	21081,
	'081',
	21,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	21083,
	'083',
	21,
	'Graves'
);
INSERT INTO CWMS_COUNTY VALUES (
	21085,
	'085',
	21,
	'Grayson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21087,
	'087',
	21,
	'Green'
);
INSERT INTO CWMS_COUNTY VALUES (
	21089,
	'089',
	21,
	'Greenup'
);
INSERT INTO CWMS_COUNTY VALUES (
	21091,
	'091',
	21,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	21093,
	'093',
	21,
	'Hardin'
);
INSERT INTO CWMS_COUNTY VALUES (
	21095,
	'095',
	21,
	'Harlan'
);
INSERT INTO CWMS_COUNTY VALUES (
	21097,
	'097',
	21,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	21099,
	'099',
	21,
	'Hart'
);
INSERT INTO CWMS_COUNTY VALUES (
	21101,
	'101',
	21,
	'Henderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21103,
	'103',
	21,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	21105,
	'105',
	21,
	'Hickman'
);
INSERT INTO CWMS_COUNTY VALUES (
	21107,
	'107',
	21,
	'Hopkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	21109,
	'109',
	21,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21111,
	'111',
	21,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21113,
	'113',
	21,
	'Jessamine'
);
INSERT INTO CWMS_COUNTY VALUES (
	21115,
	'115',
	21,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21117,
	'117',
	21,
	'Kenton'
);
INSERT INTO CWMS_COUNTY VALUES (
	21119,
	'119',
	21,
	'Knott'
);
INSERT INTO CWMS_COUNTY VALUES (
	21121,
	'121',
	21,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	21123,
	'123',
	21,
	'Larue'
);
INSERT INTO CWMS_COUNTY VALUES (
	21125,
	'125',
	21,
	'Laurel'
);
INSERT INTO CWMS_COUNTY VALUES (
	21127,
	'127',
	21,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	21129,
	'129',
	21,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	21131,
	'131',
	21,
	'Leslie'
);
INSERT INTO CWMS_COUNTY VALUES (
	21133,
	'133',
	21,
	'Letcher'
);
INSERT INTO CWMS_COUNTY VALUES (
	21135,
	'135',
	21,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	21137,
	'137',
	21,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	21139,
	'139',
	21,
	'Livingston'
);
INSERT INTO CWMS_COUNTY VALUES (
	21141,
	'141',
	21,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	21143,
	'143',
	21,
	'Lyon'
);
INSERT INTO CWMS_COUNTY VALUES (
	21145,
	'145',
	21,
	'McCracken'
);
INSERT INTO CWMS_COUNTY VALUES (
	21147,
	'147',
	21,
	'McCreary'
);
INSERT INTO CWMS_COUNTY VALUES (
	21149,
	'149',
	21,
	'McLean'
);
INSERT INTO CWMS_COUNTY VALUES (
	21151,
	'151',
	21,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	21153,
	'153',
	21,
	'Magoffin'
);
INSERT INTO CWMS_COUNTY VALUES (
	21155,
	'155',
	21,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	21157,
	'157',
	21,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	21159,
	'159',
	21,
	'Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	21161,
	'161',
	21,
	'Mason'
);
INSERT INTO CWMS_COUNTY VALUES (
	21163,
	'163',
	21,
	'Meade'
);
INSERT INTO CWMS_COUNTY VALUES (
	21165,
	'165',
	21,
	'Menifee'
);
INSERT INTO CWMS_COUNTY VALUES (
	21167,
	'167',
	21,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	21169,
	'169',
	21,
	'Metcalfe'
);
INSERT INTO CWMS_COUNTY VALUES (
	21171,
	'171',
	21,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	21173,
	'173',
	21,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	21175,
	'175',
	21,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	21177,
	'177',
	21,
	'Muhlenberg'
);
INSERT INTO CWMS_COUNTY VALUES (
	21179,
	'179',
	21,
	'Nelson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21181,
	'181',
	21,
	'Nicholas'
);
INSERT INTO CWMS_COUNTY VALUES (
	21183,
	'183',
	21,
	'Ohio'
);
INSERT INTO CWMS_COUNTY VALUES (
	21185,
	'185',
	21,
	'Oldham'
);
INSERT INTO CWMS_COUNTY VALUES (
	21187,
	'187',
	21,
	'Owen'
);
INSERT INTO CWMS_COUNTY VALUES (
	21189,
	'189',
	21,
	'Owsley'
);
INSERT INTO CWMS_COUNTY VALUES (
	21191,
	'191',
	21,
	'Pendleton'
);
INSERT INTO CWMS_COUNTY VALUES (
	21193,
	'193',
	21,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	21195,
	'195',
	21,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	21197,
	'197',
	21,
	'Powell'
);
INSERT INTO CWMS_COUNTY VALUES (
	21199,
	'199',
	21,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	21201,
	'201',
	21,
	'Robertson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21203,
	'203',
	21,
	'Rockcastle'
);
INSERT INTO CWMS_COUNTY VALUES (
	21205,
	'205',
	21,
	'Rowan'
);
INSERT INTO CWMS_COUNTY VALUES (
	21207,
	'207',
	21,
	'Russell'
);
INSERT INTO CWMS_COUNTY VALUES (
	21209,
	'209',
	21,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	21211,
	'211',
	21,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	21213,
	'213',
	21,
	'Simpson'
);
INSERT INTO CWMS_COUNTY VALUES (
	21215,
	'215',
	21,
	'Spencer'
);
INSERT INTO CWMS_COUNTY VALUES (
	21217,
	'217',
	21,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	21219,
	'219',
	21,
	'Todd'
);
INSERT INTO CWMS_COUNTY VALUES (
	21221,
	'221',
	21,
	'Trigg'
);
INSERT INTO CWMS_COUNTY VALUES (
	21223,
	'223',
	21,
	'Trimble'
);
INSERT INTO CWMS_COUNTY VALUES (
	21225,
	'225',
	21,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	21227,
	'227',
	21,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	21229,
	'229',
	21,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	21231,
	'231',
	21,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	21233,
	'233',
	21,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	21235,
	'235',
	21,
	'Whitley'
);
INSERT INTO CWMS_COUNTY VALUES (
	21237,
	'237',
	21,
	'Wolfe'
);
INSERT INTO CWMS_COUNTY VALUES (
	21239,
	'239',
	21,
	'Woodford'
);
INSERT INTO CWMS_COUNTY VALUES (
	22000,
	'000',
	22,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	22001,
	'001',
	22,
	'Acadia'
);
INSERT INTO CWMS_COUNTY VALUES (
	22003,
	'003',
	22,
	'Allen'
);
INSERT INTO CWMS_COUNTY VALUES (
	22005,
	'005',
	22,
	'Ascension'
);
INSERT INTO CWMS_COUNTY VALUES (
	22007,
	'007',
	22,
	'Assumption'
);
INSERT INTO CWMS_COUNTY VALUES (
	22009,
	'009',
	22,
	'Avoyelles'
);
INSERT INTO CWMS_COUNTY VALUES (
	22011,
	'011',
	22,
	'Beauregard'
);
INSERT INTO CWMS_COUNTY VALUES (
	22013,
	'013',
	22,
	'Bienville'
);
INSERT INTO CWMS_COUNTY VALUES (
	22015,
	'015',
	22,
	'Bossier'
);
INSERT INTO CWMS_COUNTY VALUES (
	22017,
	'017',
	22,
	'Caddo'
);
INSERT INTO CWMS_COUNTY VALUES (
	22019,
	'019',
	22,
	'Calcasieu'
);
INSERT INTO CWMS_COUNTY VALUES (
	22021,
	'021',
	22,
	'Caldwell'
);
INSERT INTO CWMS_COUNTY VALUES (
	22023,
	'023',
	22,
	'Cameron'
);
INSERT INTO CWMS_COUNTY VALUES (
	22025,
	'025',
	22,
	'Catahoula'
);
INSERT INTO CWMS_COUNTY VALUES (
	22027,
	'027',
	22,
	'Claiborne'
);
INSERT INTO CWMS_COUNTY VALUES (
	22029,
	'029',
	22,
	'Concordia'
);
INSERT INTO CWMS_COUNTY VALUES (
	22031,
	'031',
	22,
	'De Soto'
);
INSERT INTO CWMS_COUNTY VALUES (
	22033,
	'033',
	22,
	'East Baton Rouge'
);
INSERT INTO CWMS_COUNTY VALUES (
	22035,
	'035',
	22,
	'East Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	22037,
	'037',
	22,
	'East Feliciana'
);
INSERT INTO CWMS_COUNTY VALUES (
	22039,
	'039',
	22,
	'Evangeline'
);
INSERT INTO CWMS_COUNTY VALUES (
	22041,
	'041',
	22,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	22043,
	'043',
	22,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	22045,
	'045',
	22,
	'Iberia'
);
INSERT INTO CWMS_COUNTY VALUES (
	22047,
	'047',
	22,
	'Iberville'
);
INSERT INTO CWMS_COUNTY VALUES (
	22049,
	'049',
	22,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	22051,
	'051',
	22,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	22053,
	'053',
	22,
	'Jefferson Davis'
);
INSERT INTO CWMS_COUNTY VALUES (
	22055,
	'055',
	22,
	'Lafayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	22057,
	'057',
	22,
	'LaFourche'
);
INSERT INTO CWMS_COUNTY VALUES (
	22059,
	'059',
	22,
	'La Salle'
);
INSERT INTO CWMS_COUNTY VALUES (
	22061,
	'061',
	22,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	22063,
	'063',
	22,
	'Livingston'
);
INSERT INTO CWMS_COUNTY VALUES (
	22065,
	'065',
	22,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	22067,
	'067',
	22,
	'Morehouse'
);
INSERT INTO CWMS_COUNTY VALUES (
	22069,
	'069',
	22,
	'Natchitoches'
);
INSERT INTO CWMS_COUNTY VALUES (
	22071,
	'071',
	22,
	'Orleans'
);
INSERT INTO CWMS_COUNTY VALUES (
	22073,
	'073',
	22,
	'Ouachita'
);
INSERT INTO CWMS_COUNTY VALUES (
	22075,
	'075',
	22,
	'Plaquemines'
);
INSERT INTO CWMS_COUNTY VALUES (
	22077,
	'077',
	22,
	'Pointe Coupee'
);
INSERT INTO CWMS_COUNTY VALUES (
	22079,
	'079',
	22,
	'Rapides'
);
INSERT INTO CWMS_COUNTY VALUES (
	22081,
	'081',
	22,
	'Red River'
);
INSERT INTO CWMS_COUNTY VALUES (
	22083,
	'083',
	22,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	22085,
	'085',
	22,
	'Sabine'
);
INSERT INTO CWMS_COUNTY VALUES (
	22087,
	'087',
	22,
	'St. Bernard'
);
INSERT INTO CWMS_COUNTY VALUES (
	22089,
	'089',
	22,
	'St. Charles'
);
INSERT INTO CWMS_COUNTY VALUES (
	22091,
	'091',
	22,
	'St. Helena'
);
INSERT INTO CWMS_COUNTY VALUES (
	22093,
	'093',
	22,
	'St. James'
);
INSERT INTO CWMS_COUNTY VALUES (
	22095,
	'095',
	22,
	'St. John the Baptist'
);
INSERT INTO CWMS_COUNTY VALUES (
	22097,
	'097',
	22,
	'St. Landry'
);
INSERT INTO CWMS_COUNTY VALUES (
	22099,
	'099',
	22,
	'St. Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	22101,
	'101',
	22,
	'St. Mary'
);
INSERT INTO CWMS_COUNTY VALUES (
	22103,
	'103',
	22,
	'St. Tammany'
);
INSERT INTO CWMS_COUNTY VALUES (
	22105,
	'105',
	22,
	'Tangipahoa'
);
INSERT INTO CWMS_COUNTY VALUES (
	22107,
	'107',
	22,
	'Tensas'
);
INSERT INTO CWMS_COUNTY VALUES (
	22109,
	'109',
	22,
	'Terrebonne'
);
INSERT INTO CWMS_COUNTY VALUES (
	22111,
	'111',
	22,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	22113,
	'113',
	22,
	'Vermilion'
);
INSERT INTO CWMS_COUNTY VALUES (
	22115,
	'115',
	22,
	'Vernon'
);
INSERT INTO CWMS_COUNTY VALUES (
	22117,
	'117',
	22,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	22119,
	'119',
	22,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	22121,
	'121',
	22,
	'West Baton Rouge'
);
INSERT INTO CWMS_COUNTY VALUES (
	22123,
	'123',
	22,
	'West Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	22125,
	'125',
	22,
	'West Feliciana'
);
INSERT INTO CWMS_COUNTY VALUES (
	22127,
	'127',
	22,
	'Winn'
);
INSERT INTO CWMS_COUNTY VALUES (
	23000,
	'000',
	23,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	23001,
	'001',
	23,
	'Androscoggin'
);
INSERT INTO CWMS_COUNTY VALUES (
	23003,
	'003',
	23,
	'Aroostook'
);
INSERT INTO CWMS_COUNTY VALUES (
	23005,
	'005',
	23,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	23007,
	'007',
	23,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	23009,
	'009',
	23,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	23011,
	'011',
	23,
	'Kennebec'
);
INSERT INTO CWMS_COUNTY VALUES (
	23013,
	'013',
	23,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	23015,
	'015',
	23,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	23017,
	'017',
	23,
	'Oxford'
);
INSERT INTO CWMS_COUNTY VALUES (
	23019,
	'019',
	23,
	'Penobscot'
);
INSERT INTO CWMS_COUNTY VALUES (
	23021,
	'021',
	23,
	'Piscataquis'
);
INSERT INTO CWMS_COUNTY VALUES (
	23023,
	'023',
	23,
	'Sagadahoc'
);
INSERT INTO CWMS_COUNTY VALUES (
	23025,
	'025',
	23,
	'Somerset'
);
INSERT INTO CWMS_COUNTY VALUES (
	23027,
	'027',
	23,
	'Waldo'
);
INSERT INTO CWMS_COUNTY VALUES (
	23029,
	'029',
	23,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	23031,
	'031',
	23,
	'York'
);
INSERT INTO CWMS_COUNTY VALUES (
	24000,
	'000',
	24,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	24001,
	'001',
	24,
	'Allegany'
);
INSERT INTO CWMS_COUNTY VALUES (
	24003,
	'003',
	24,
	'Anne Arundel'
);
INSERT INTO CWMS_COUNTY VALUES (
	24005,
	'005',
	24,
	'Baltimore'
);
INSERT INTO CWMS_COUNTY VALUES (
	24009,
	'009',
	24,
	'Calvert'
);
INSERT INTO CWMS_COUNTY VALUES (
	24011,
	'011',
	24,
	'Caroline'
);
INSERT INTO CWMS_COUNTY VALUES (
	24013,
	'013',
	24,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	24015,
	'015',
	24,
	'Cecil'
);
INSERT INTO CWMS_COUNTY VALUES (
	24017,
	'017',
	24,
	'Charles'
);
INSERT INTO CWMS_COUNTY VALUES (
	24019,
	'019',
	24,
	'Dorchester'
);
INSERT INTO CWMS_COUNTY VALUES (
	24021,
	'021',
	24,
	'Frederick'
);
INSERT INTO CWMS_COUNTY VALUES (
	24023,
	'023',
	24,
	'Garrett'
);
INSERT INTO CWMS_COUNTY VALUES (
	24025,
	'025',
	24,
	'Harford'
);
INSERT INTO CWMS_COUNTY VALUES (
	24027,
	'027',
	24,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	24029,
	'029',
	24,
	'Kent'
);
INSERT INTO CWMS_COUNTY VALUES (
	24031,
	'031',
	24,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	24033,
	'033',
	24,
	'Prince Georges'
);
INSERT INTO CWMS_COUNTY VALUES (
	24035,
	'035',
	24,
	'Queen Annes'
);
INSERT INTO CWMS_COUNTY VALUES (
	24037,
	'037',
	24,
	'St. Marys'
);
INSERT INTO CWMS_COUNTY VALUES (
	24039,
	'039',
	24,
	'Somerset'
);
INSERT INTO CWMS_COUNTY VALUES (
	24041,
	'041',
	24,
	'Talbot'
);
INSERT INTO CWMS_COUNTY VALUES (
	24043,
	'043',
	24,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	24045,
	'045',
	24,
	'Wicomico'
);
INSERT INTO CWMS_COUNTY VALUES (
	24047,
	'047',
	24,
	'Worcester'
);
INSERT INTO CWMS_COUNTY VALUES (
	24510,
	'510',
	24,
	'Baltimore City'
);
INSERT INTO CWMS_COUNTY VALUES (
	25000,
	'000',
	25,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	25001,
	'001',
	25,
	'Barnstable'
);
INSERT INTO CWMS_COUNTY VALUES (
	25003,
	'003',
	25,
	'Berkshire'
);
INSERT INTO CWMS_COUNTY VALUES (
	25005,
	'005',
	25,
	'Bristol'
);
INSERT INTO CWMS_COUNTY VALUES (
	25007,
	'007',
	25,
	'Dukes'
);
INSERT INTO CWMS_COUNTY VALUES (
	25009,
	'009',
	25,
	'Essex'
);
INSERT INTO CWMS_COUNTY VALUES (
	25011,
	'011',
	25,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	25013,
	'013',
	25,
	'Hampden'
);
INSERT INTO CWMS_COUNTY VALUES (
	25015,
	'015',
	25,
	'Hampshire'
);
INSERT INTO CWMS_COUNTY VALUES (
	25017,
	'017',
	25,
	'Middlesex'
);
INSERT INTO CWMS_COUNTY VALUES (
	25019,
	'019',
	25,
	'Nantucket'
);
INSERT INTO CWMS_COUNTY VALUES (
	25021,
	'021',
	25,
	'Norfolk'
);
INSERT INTO CWMS_COUNTY VALUES (
	25023,
	'023',
	25,
	'Plymouth'
);
INSERT INTO CWMS_COUNTY VALUES (
	25025,
	'025',
	25,
	'Suffolk'
);
INSERT INTO CWMS_COUNTY VALUES (
	25027,
	'027',
	25,
	'Worcester'
);
INSERT INTO CWMS_COUNTY VALUES (
	26000,
	'000',
	26,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	26001,
	'001',
	26,
	'Alcona'
);
INSERT INTO CWMS_COUNTY VALUES (
	26003,
	'003',
	26,
	'Alger'
);
INSERT INTO CWMS_COUNTY VALUES (
	26005,
	'005',
	26,
	'Allegan'
);
INSERT INTO CWMS_COUNTY VALUES (
	26007,
	'007',
	26,
	'Alpena'
);
INSERT INTO CWMS_COUNTY VALUES (
	26009,
	'009',
	26,
	'Antrim'
);
INSERT INTO CWMS_COUNTY VALUES (
	26011,
	'011',
	26,
	'Arenac'
);
INSERT INTO CWMS_COUNTY VALUES (
	26013,
	'013',
	26,
	'Baraga'
);
INSERT INTO CWMS_COUNTY VALUES (
	26015,
	'015',
	26,
	'Barry'
);
INSERT INTO CWMS_COUNTY VALUES (
	26017,
	'017',
	26,
	'Bay'
);
INSERT INTO CWMS_COUNTY VALUES (
	26019,
	'019',
	26,
	'Benzie'
);
INSERT INTO CWMS_COUNTY VALUES (
	26021,
	'021',
	26,
	'Berrien'
);
INSERT INTO CWMS_COUNTY VALUES (
	26023,
	'023',
	26,
	'Branch'
);
INSERT INTO CWMS_COUNTY VALUES (
	26025,
	'025',
	26,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	26027,
	'027',
	26,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	26029,
	'029',
	26,
	'Charlevoix'
);
INSERT INTO CWMS_COUNTY VALUES (
	26031,
	'031',
	26,
	'Cheboygan'
);
INSERT INTO CWMS_COUNTY VALUES (
	26033,
	'033',
	26,
	'Chippewa'
);
INSERT INTO CWMS_COUNTY VALUES (
	26035,
	'035',
	26,
	'Clare'
);
INSERT INTO CWMS_COUNTY VALUES (
	26037,
	'037',
	26,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	26039,
	'039',
	26,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	26041,
	'041',
	26,
	'Delta'
);
INSERT INTO CWMS_COUNTY VALUES (
	26043,
	'043',
	26,
	'Dickinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	26045,
	'045',
	26,
	'Eaton'
);
INSERT INTO CWMS_COUNTY VALUES (
	26047,
	'047',
	26,
	'Emmet'
);
INSERT INTO CWMS_COUNTY VALUES (
	26049,
	'049',
	26,
	'Genesee'
);
INSERT INTO CWMS_COUNTY VALUES (
	26051,
	'051',
	26,
	'Gladwin'
);
INSERT INTO CWMS_COUNTY VALUES (
	26053,
	'053',
	26,
	'Gogebic'
);
INSERT INTO CWMS_COUNTY VALUES (
	26055,
	'055',
	26,
	'Grand Traverse'
);
INSERT INTO CWMS_COUNTY VALUES (
	26057,
	'057',
	26,
	'Gratiot'
);
INSERT INTO CWMS_COUNTY VALUES (
	26059,
	'059',
	26,
	'Hillsdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	26061,
	'061',
	26,
	'Houghton'
);
INSERT INTO CWMS_COUNTY VALUES (
	26063,
	'063',
	26,
	'Huron'
);
INSERT INTO CWMS_COUNTY VALUES (
	26065,
	'065',
	26,
	'Ingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	26067,
	'067',
	26,
	'Ionia'
);
INSERT INTO CWMS_COUNTY VALUES (
	26069,
	'069',
	26,
	'Iosco'
);
INSERT INTO CWMS_COUNTY VALUES (
	26071,
	'071',
	26,
	'Iron'
);
INSERT INTO CWMS_COUNTY VALUES (
	26073,
	'073',
	26,
	'Isabella'
);
INSERT INTO CWMS_COUNTY VALUES (
	26075,
	'075',
	26,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	26077,
	'077',
	26,
	'Kalamazoo'
);
INSERT INTO CWMS_COUNTY VALUES (
	26079,
	'079',
	26,
	'Kalkaska'
);
INSERT INTO CWMS_COUNTY VALUES (
	26081,
	'081',
	26,
	'Kent'
);
INSERT INTO CWMS_COUNTY VALUES (
	26083,
	'083',
	26,
	'Keweenaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	26085,
	'085',
	26,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	26087,
	'087',
	26,
	'Lapeer'
);
INSERT INTO CWMS_COUNTY VALUES (
	26089,
	'089',
	26,
	'Leelanau'
);
INSERT INTO CWMS_COUNTY VALUES (
	26091,
	'091',
	26,
	'Lenawee'
);
INSERT INTO CWMS_COUNTY VALUES (
	26093,
	'093',
	26,
	'Livingston'
);
INSERT INTO CWMS_COUNTY VALUES (
	26095,
	'095',
	26,
	'Luce'
);
INSERT INTO CWMS_COUNTY VALUES (
	26097,
	'097',
	26,
	'Mackinac'
);
INSERT INTO CWMS_COUNTY VALUES (
	26099,
	'099',
	26,
	'Macomb'
);
INSERT INTO CWMS_COUNTY VALUES (
	26101,
	'101',
	26,
	'Manistee'
);
INSERT INTO CWMS_COUNTY VALUES (
	26103,
	'103',
	26,
	'Marquette'
);
INSERT INTO CWMS_COUNTY VALUES (
	26105,
	'105',
	26,
	'Mason'
);
INSERT INTO CWMS_COUNTY VALUES (
	26107,
	'107',
	26,
	'Mecosta'
);
INSERT INTO CWMS_COUNTY VALUES (
	26109,
	'109',
	26,
	'Menominee'
);
INSERT INTO CWMS_COUNTY VALUES (
	26111,
	'111',
	26,
	'Midland'
);
INSERT INTO CWMS_COUNTY VALUES (
	26113,
	'113',
	26,
	'Missaukee'
);
INSERT INTO CWMS_COUNTY VALUES (
	26115,
	'115',
	26,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	26117,
	'117',
	26,
	'Montcalm'
);
INSERT INTO CWMS_COUNTY VALUES (
	26119,
	'119',
	26,
	'Montmorency'
);
INSERT INTO CWMS_COUNTY VALUES (
	26121,
	'121',
	26,
	'Muskegon'
);
INSERT INTO CWMS_COUNTY VALUES (
	26123,
	'123',
	26,
	'Newaygo'
);
INSERT INTO CWMS_COUNTY VALUES (
	26125,
	'125',
	26,
	'Oakland'
);
INSERT INTO CWMS_COUNTY VALUES (
	26127,
	'127',
	26,
	'Oceana'
);
INSERT INTO CWMS_COUNTY VALUES (
	26129,
	'129',
	26,
	'Ogemaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	26131,
	'131',
	26,
	'Ontonagon'
);
INSERT INTO CWMS_COUNTY VALUES (
	26133,
	'133',
	26,
	'Osceola'
);
INSERT INTO CWMS_COUNTY VALUES (
	26135,
	'135',
	26,
	'Oscoda'
);
INSERT INTO CWMS_COUNTY VALUES (
	26137,
	'137',
	26,
	'Otsego'
);
INSERT INTO CWMS_COUNTY VALUES (
	26139,
	'139',
	26,
	'Ottawa'
);
INSERT INTO CWMS_COUNTY VALUES (
	26141,
	'141',
	26,
	'Presque Isle'
);
INSERT INTO CWMS_COUNTY VALUES (
	26143,
	'143',
	26,
	'Roscommon'
);
INSERT INTO CWMS_COUNTY VALUES (
	26145,
	'145',
	26,
	'Saginaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	26147,
	'147',
	26,
	'St. Clair'
);
INSERT INTO CWMS_COUNTY VALUES (
	26149,
	'149',
	26,
	'St. Joseph'
);
INSERT INTO CWMS_COUNTY VALUES (
	26151,
	'151',
	26,
	'Sanilac'
);
INSERT INTO CWMS_COUNTY VALUES (
	26153,
	'153',
	26,
	'Schoolcraft'
);
INSERT INTO CWMS_COUNTY VALUES (
	26155,
	'155',
	26,
	'Shiawassee'
);
INSERT INTO CWMS_COUNTY VALUES (
	26157,
	'157',
	26,
	'Tuscola'
);
INSERT INTO CWMS_COUNTY VALUES (
	26159,
	'159',
	26,
	'Van Buren'
);
INSERT INTO CWMS_COUNTY VALUES (
	26161,
	'161',
	26,
	'Washtenaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	26163,
	'163',
	26,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	26165,
	'165',
	26,
	'Wexford'
);
INSERT INTO CWMS_COUNTY VALUES (
	27000,
	'000',
	27,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	27001,
	'001',
	27,
	'Aitkin'
);
INSERT INTO CWMS_COUNTY VALUES (
	27003,
	'003',
	27,
	'Anoka'
);
INSERT INTO CWMS_COUNTY VALUES (
	27005,
	'005',
	27,
	'Becker'
);
INSERT INTO CWMS_COUNTY VALUES (
	27007,
	'007',
	27,
	'Beltrami'
);
INSERT INTO CWMS_COUNTY VALUES (
	27009,
	'009',
	27,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	27011,
	'011',
	27,
	'Big Stone'
);
INSERT INTO CWMS_COUNTY VALUES (
	27013,
	'013',
	27,
	'Blue Earth'
);
INSERT INTO CWMS_COUNTY VALUES (
	27015,
	'015',
	27,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	27017,
	'017',
	27,
	'Carlton'
);
INSERT INTO CWMS_COUNTY VALUES (
	27019,
	'019',
	27,
	'Carver'
);
INSERT INTO CWMS_COUNTY VALUES (
	27021,
	'021',
	27,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	27023,
	'023',
	27,
	'Chippewa'
);
INSERT INTO CWMS_COUNTY VALUES (
	27025,
	'025',
	27,
	'Chisago'
);
INSERT INTO CWMS_COUNTY VALUES (
	27027,
	'027',
	27,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	27029,
	'029',
	27,
	'Clearwater'
);
INSERT INTO CWMS_COUNTY VALUES (
	27031,
	'031',
	27,
	'Cook'
);
INSERT INTO CWMS_COUNTY VALUES (
	27033,
	'033',
	27,
	'Cottonwood'
);
INSERT INTO CWMS_COUNTY VALUES (
	27035,
	'035',
	27,
	'Crow Wing'
);
INSERT INTO CWMS_COUNTY VALUES (
	27037,
	'037',
	27,
	'Dakota'
);
INSERT INTO CWMS_COUNTY VALUES (
	27039,
	'039',
	27,
	'Dodge'
);
INSERT INTO CWMS_COUNTY VALUES (
	27041,
	'041',
	27,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	27043,
	'043',
	27,
	'Faribault'
);
INSERT INTO CWMS_COUNTY VALUES (
	27045,
	'045',
	27,
	'Fillmore'
);
INSERT INTO CWMS_COUNTY VALUES (
	27047,
	'047',
	27,
	'Freeborn'
);
INSERT INTO CWMS_COUNTY VALUES (
	27049,
	'049',
	27,
	'Goodhue'
);
INSERT INTO CWMS_COUNTY VALUES (
	27051,
	'051',
	27,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	27053,
	'053',
	27,
	'Hennepin'
);
INSERT INTO CWMS_COUNTY VALUES (
	27055,
	'055',
	27,
	'Houston'
);
INSERT INTO CWMS_COUNTY VALUES (
	27057,
	'057',
	27,
	'Hubbard'
);
INSERT INTO CWMS_COUNTY VALUES (
	27059,
	'059',
	27,
	'Isanti'
);
INSERT INTO CWMS_COUNTY VALUES (
	27061,
	'061',
	27,
	'Itasca'
);
INSERT INTO CWMS_COUNTY VALUES (
	27063,
	'063',
	27,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	27065,
	'065',
	27,
	'Kanabec'
);
INSERT INTO CWMS_COUNTY VALUES (
	27067,
	'067',
	27,
	'Kandiyohi'
);
INSERT INTO CWMS_COUNTY VALUES (
	27069,
	'069',
	27,
	'Kittson'
);
INSERT INTO CWMS_COUNTY VALUES (
	27071,
	'071',
	27,
	'Koochiching'
);
INSERT INTO CWMS_COUNTY VALUES (
	27073,
	'073',
	27,
	'Lac Qui Parle'
);
INSERT INTO CWMS_COUNTY VALUES (
	27075,
	'075',
	27,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	27077,
	'077',
	27,
	'Lake of the Woods'
);
INSERT INTO CWMS_COUNTY VALUES (
	27079,
	'079',
	27,
	'Le Sueur'
);
INSERT INTO CWMS_COUNTY VALUES (
	27081,
	'081',
	27,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	27083,
	'083',
	27,
	'Lyon'
);
INSERT INTO CWMS_COUNTY VALUES (
	27085,
	'085',
	27,
	'McLeod'
);
INSERT INTO CWMS_COUNTY VALUES (
	27087,
	'087',
	27,
	'Mahnomen'
);
INSERT INTO CWMS_COUNTY VALUES (
	27089,
	'089',
	27,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	27091,
	'091',
	27,
	'Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	27093,
	'093',
	27,
	'Meeker'
);
INSERT INTO CWMS_COUNTY VALUES (
	27095,
	'095',
	27,
	'Mille Lacs'
);
INSERT INTO CWMS_COUNTY VALUES (
	27097,
	'097',
	27,
	'Morrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	27099,
	'099',
	27,
	'Mower'
);
INSERT INTO CWMS_COUNTY VALUES (
	27101,
	'101',
	27,
	'Murray'
);
INSERT INTO CWMS_COUNTY VALUES (
	27103,
	'103',
	27,
	'Nicollet'
);
INSERT INTO CWMS_COUNTY VALUES (
	27105,
	'105',
	27,
	'Nobles'
);
INSERT INTO CWMS_COUNTY VALUES (
	27107,
	'107',
	27,
	'Norman'
);
INSERT INTO CWMS_COUNTY VALUES (
	27109,
	'109',
	27,
	'Olmsted'
);
INSERT INTO CWMS_COUNTY VALUES (
	27111,
	'111',
	27,
	'Otter Tail'
);
INSERT INTO CWMS_COUNTY VALUES (
	27113,
	'113',
	27,
	'Pennington'
);
INSERT INTO CWMS_COUNTY VALUES (
	27115,
	'115',
	27,
	'Pine'
);
INSERT INTO CWMS_COUNTY VALUES (
	27117,
	'117',
	27,
	'Pipestone'
);
INSERT INTO CWMS_COUNTY VALUES (
	27119,
	'119',
	27,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	27121,
	'121',
	27,
	'Pope'
);
INSERT INTO CWMS_COUNTY VALUES (
	27123,
	'123',
	27,
	'Ramsey'
);
INSERT INTO CWMS_COUNTY VALUES (
	27125,
	'125',
	27,
	'Red Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	27127,
	'127',
	27,
	'Redwood'
);
INSERT INTO CWMS_COUNTY VALUES (
	27129,
	'129',
	27,
	'Renville'
);
INSERT INTO CWMS_COUNTY VALUES (
	27131,
	'131',
	27,
	'Rice'
);
INSERT INTO CWMS_COUNTY VALUES (
	27133,
	'133',
	27,
	'Rock'
);
INSERT INTO CWMS_COUNTY VALUES (
	27135,
	'135',
	27,
	'Roseau'
);
INSERT INTO CWMS_COUNTY VALUES (
	27137,
	'137',
	27,
	'St. Louis'
);
INSERT INTO CWMS_COUNTY VALUES (
	27139,
	'139',
	27,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	27141,
	'141',
	27,
	'Sherburne'
);
INSERT INTO CWMS_COUNTY VALUES (
	27143,
	'143',
	27,
	'Sibley'
);
INSERT INTO CWMS_COUNTY VALUES (
	27145,
	'145',
	27,
	'Stearns'
);
INSERT INTO CWMS_COUNTY VALUES (
	27147,
	'147',
	27,
	'Steele'
);
INSERT INTO CWMS_COUNTY VALUES (
	27149,
	'149',
	27,
	'Stevens'
);
INSERT INTO CWMS_COUNTY VALUES (
	27151,
	'151',
	27,
	'Swift'
);
INSERT INTO CWMS_COUNTY VALUES (
	27153,
	'153',
	27,
	'Todd'
);
INSERT INTO CWMS_COUNTY VALUES (
	27155,
	'155',
	27,
	'Traverse'
);
INSERT INTO CWMS_COUNTY VALUES (
	27157,
	'157',
	27,
	'Wabasha'
);
INSERT INTO CWMS_COUNTY VALUES (
	27159,
	'159',
	27,
	'Wadena'
);
INSERT INTO CWMS_COUNTY VALUES (
	27161,
	'161',
	27,
	'Waseca'
);
INSERT INTO CWMS_COUNTY VALUES (
	27163,
	'163',
	27,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	27165,
	'165',
	27,
	'Watonwan'
);
INSERT INTO CWMS_COUNTY VALUES (
	27167,
	'167',
	27,
	'Wilkin'
);
INSERT INTO CWMS_COUNTY VALUES (
	27169,
	'169',
	27,
	'Winona'
);
INSERT INTO CWMS_COUNTY VALUES (
	27171,
	'171',
	27,
	'Wright'
);
INSERT INTO CWMS_COUNTY VALUES (
	27173,
	'173',
	27,
	'Yellow Medicine'
);
INSERT INTO CWMS_COUNTY VALUES (
	28000,
	'000',
	28,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	28001,
	'001',
	28,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	28003,
	'003',
	28,
	'Alcorn'
);
INSERT INTO CWMS_COUNTY VALUES (
	28005,
	'005',
	28,
	'Amite'
);
INSERT INTO CWMS_COUNTY VALUES (
	28007,
	'007',
	28,
	'Attala'
);
INSERT INTO CWMS_COUNTY VALUES (
	28009,
	'009',
	28,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	28011,
	'011',
	28,
	'Bolivar'
);
INSERT INTO CWMS_COUNTY VALUES (
	28013,
	'013',
	28,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	28015,
	'015',
	28,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	28017,
	'017',
	28,
	'Chickasaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	28019,
	'019',
	28,
	'Choctaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	28021,
	'021',
	28,
	'Claiborne'
);
INSERT INTO CWMS_COUNTY VALUES (
	28023,
	'023',
	28,
	'Clarke'
);
INSERT INTO CWMS_COUNTY VALUES (
	28025,
	'025',
	28,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	28027,
	'027',
	28,
	'Coahoma'
);
INSERT INTO CWMS_COUNTY VALUES (
	28029,
	'029',
	28,
	'Copiah'
);
INSERT INTO CWMS_COUNTY VALUES (
	28031,
	'031',
	28,
	'Covington'
);
INSERT INTO CWMS_COUNTY VALUES (
	28033,
	'033',
	28,
	'De Soto'
);
INSERT INTO CWMS_COUNTY VALUES (
	28035,
	'035',
	28,
	'Forrest'
);
INSERT INTO CWMS_COUNTY VALUES (
	28037,
	'037',
	28,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	28039,
	'039',
	28,
	'George'
);
INSERT INTO CWMS_COUNTY VALUES (
	28041,
	'041',
	28,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	28043,
	'043',
	28,
	'Grenada'
);
INSERT INTO CWMS_COUNTY VALUES (
	28045,
	'045',
	28,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	28047,
	'047',
	28,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	28049,
	'049',
	28,
	'Hinds'
);
INSERT INTO CWMS_COUNTY VALUES (
	28051,
	'051',
	28,
	'Holmes'
);
INSERT INTO CWMS_COUNTY VALUES (
	28053,
	'053',
	28,
	'Humphreys'
);
INSERT INTO CWMS_COUNTY VALUES (
	28055,
	'055',
	28,
	'Issaquena'
);
INSERT INTO CWMS_COUNTY VALUES (
	28057,
	'057',
	28,
	'Itawamba'
);
INSERT INTO CWMS_COUNTY VALUES (
	28059,
	'059',
	28,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	28061,
	'061',
	28,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	28063,
	'063',
	28,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	28065,
	'065',
	28,
	'Jefferson Davis'
);
INSERT INTO CWMS_COUNTY VALUES (
	28067,
	'067',
	28,
	'Jones'
);
INSERT INTO CWMS_COUNTY VALUES (
	28069,
	'069',
	28,
	'Kemper'
);
INSERT INTO CWMS_COUNTY VALUES (
	28071,
	'071',
	28,
	'Lafayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	28073,
	'073',
	28,
	'Lamar'
);
INSERT INTO CWMS_COUNTY VALUES (
	28075,
	'075',
	28,
	'Lauderdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	28077,
	'077',
	28,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	28079,
	'079',
	28,
	'Leake'
);
INSERT INTO CWMS_COUNTY VALUES (
	28081,
	'081',
	28,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	28083,
	'083',
	28,
	'Leflore'
);
INSERT INTO CWMS_COUNTY VALUES (
	28085,
	'085',
	28,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	28087,
	'087',
	28,
	'Lowndes'
);
INSERT INTO CWMS_COUNTY VALUES (
	28089,
	'089',
	28,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	28091,
	'091',
	28,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	28093,
	'093',
	28,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	28095,
	'095',
	28,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	28097,
	'097',
	28,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	28099,
	'099',
	28,
	'Neshoba'
);
INSERT INTO CWMS_COUNTY VALUES (
	28101,
	'101',
	28,
	'Newton'
);
INSERT INTO CWMS_COUNTY VALUES (
	28103,
	'103',
	28,
	'Noxubee'
);
INSERT INTO CWMS_COUNTY VALUES (
	28105,
	'105',
	28,
	'Oktibbeha'
);
INSERT INTO CWMS_COUNTY VALUES (
	28107,
	'107',
	28,
	'Panola'
);
INSERT INTO CWMS_COUNTY VALUES (
	28109,
	'109',
	28,
	'Pearl River'
);
INSERT INTO CWMS_COUNTY VALUES (
	28111,
	'111',
	28,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	28113,
	'113',
	28,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	28115,
	'115',
	28,
	'Pontotoc'
);
INSERT INTO CWMS_COUNTY VALUES (
	28117,
	'117',
	28,
	'Prentiss'
);
INSERT INTO CWMS_COUNTY VALUES (
	28119,
	'119',
	28,
	'Quitman'
);
INSERT INTO CWMS_COUNTY VALUES (
	28121,
	'121',
	28,
	'Rankin'
);
INSERT INTO CWMS_COUNTY VALUES (
	28123,
	'123',
	28,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	28125,
	'125',
	28,
	'Sharkey'
);
INSERT INTO CWMS_COUNTY VALUES (
	28127,
	'127',
	28,
	'Simpson'
);
INSERT INTO CWMS_COUNTY VALUES (
	28129,
	'129',
	28,
	'Smith'
);
INSERT INTO CWMS_COUNTY VALUES (
	28131,
	'131',
	28,
	'Stone'
);
INSERT INTO CWMS_COUNTY VALUES (
	28133,
	'133',
	28,
	'Sunflower'
);
INSERT INTO CWMS_COUNTY VALUES (
	28135,
	'135',
	28,
	'Tallahatchie'
);
INSERT INTO CWMS_COUNTY VALUES (
	28137,
	'137',
	28,
	'Tate'
);
INSERT INTO CWMS_COUNTY VALUES (
	28139,
	'139',
	28,
	'Tippah'
);
INSERT INTO CWMS_COUNTY VALUES (
	28141,
	'141',
	28,
	'Tishomingo'
);
INSERT INTO CWMS_COUNTY VALUES (
	28143,
	'143',
	28,
	'Tunica'
);
INSERT INTO CWMS_COUNTY VALUES (
	28145,
	'145',
	28,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	28147,
	'147',
	28,
	'Walthall'
);
INSERT INTO CWMS_COUNTY VALUES (
	28149,
	'149',
	28,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	28151,
	'151',
	28,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	28153,
	'153',
	28,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	28155,
	'155',
	28,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	28157,
	'157',
	28,
	'Wilkinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	28159,
	'159',
	28,
	'Winston'
);
INSERT INTO CWMS_COUNTY VALUES (
	28161,
	'161',
	28,
	'Yalobusha'
);
INSERT INTO CWMS_COUNTY VALUES (
	28163,
	'163',
	28,
	'Yazoo'
);
INSERT INTO CWMS_COUNTY VALUES (
	29000,
	'000',
	29,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	29001,
	'001',
	29,
	'Adair'
);
INSERT INTO CWMS_COUNTY VALUES (
	29003,
	'003',
	29,
	'Andrew'
);
INSERT INTO CWMS_COUNTY VALUES (
	29005,
	'005',
	29,
	'Atchison'
);
INSERT INTO CWMS_COUNTY VALUES (
	29007,
	'007',
	29,
	'Audrain'
);
INSERT INTO CWMS_COUNTY VALUES (
	29009,
	'009',
	29,
	'Barry'
);
INSERT INTO CWMS_COUNTY VALUES (
	29011,
	'011',
	29,
	'Barton'
);
INSERT INTO CWMS_COUNTY VALUES (
	29013,
	'013',
	29,
	'Bates'
);
INSERT INTO CWMS_COUNTY VALUES (
	29015,
	'015',
	29,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	29017,
	'017',
	29,
	'Bollinger'
);
INSERT INTO CWMS_COUNTY VALUES (
	29019,
	'019',
	29,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	29021,
	'021',
	29,
	'Buchanan'
);
INSERT INTO CWMS_COUNTY VALUES (
	29023,
	'023',
	29,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	29025,
	'025',
	29,
	'Caldwell'
);
INSERT INTO CWMS_COUNTY VALUES (
	29027,
	'027',
	29,
	'Callaway'
);
INSERT INTO CWMS_COUNTY VALUES (
	29029,
	'029',
	29,
	'Camden'
);
INSERT INTO CWMS_COUNTY VALUES (
	29031,
	'031',
	29,
	'Cape Girardeau'
);
INSERT INTO CWMS_COUNTY VALUES (
	29033,
	'033',
	29,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	29035,
	'035',
	29,
	'Carter'
);
INSERT INTO CWMS_COUNTY VALUES (
	29037,
	'037',
	29,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	29039,
	'039',
	29,
	'Cedar'
);
INSERT INTO CWMS_COUNTY VALUES (
	29041,
	'041',
	29,
	'Chariton'
);
INSERT INTO CWMS_COUNTY VALUES (
	29043,
	'043',
	29,
	'Christian'
);
INSERT INTO CWMS_COUNTY VALUES (
	29045,
	'045',
	29,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	29047,
	'047',
	29,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	29049,
	'049',
	29,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	29051,
	'051',
	29,
	'Cole'
);
INSERT INTO CWMS_COUNTY VALUES (
	29053,
	'053',
	29,
	'Cooper'
);
INSERT INTO CWMS_COUNTY VALUES (
	29055,
	'055',
	29,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	29057,
	'057',
	29,
	'Dade'
);
INSERT INTO CWMS_COUNTY VALUES (
	29059,
	'059',
	29,
	'Dallas'
);
INSERT INTO CWMS_COUNTY VALUES (
	29061,
	'061',
	29,
	'Daviess'
);
INSERT INTO CWMS_COUNTY VALUES (
	29063,
	'063',
	29,
	'De Kalb'
);
INSERT INTO CWMS_COUNTY VALUES (
	29065,
	'065',
	29,
	'Dent'
);
INSERT INTO CWMS_COUNTY VALUES (
	29067,
	'067',
	29,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	29069,
	'069',
	29,
	'Dunklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	29071,
	'071',
	29,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	29073,
	'073',
	29,
	'Gasconade'
);
INSERT INTO CWMS_COUNTY VALUES (
	29075,
	'075',
	29,
	'Gentry'
);
INSERT INTO CWMS_COUNTY VALUES (
	29077,
	'077',
	29,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	29079,
	'079',
	29,
	'Grundy'
);
INSERT INTO CWMS_COUNTY VALUES (
	29081,
	'081',
	29,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	29083,
	'083',
	29,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	29085,
	'085',
	29,
	'Hickory'
);
INSERT INTO CWMS_COUNTY VALUES (
	29087,
	'087',
	29,
	'Holt'
);
INSERT INTO CWMS_COUNTY VALUES (
	29089,
	'089',
	29,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	29091,
	'091',
	29,
	'Howell'
);
INSERT INTO CWMS_COUNTY VALUES (
	29093,
	'093',
	29,
	'Iron'
);
INSERT INTO CWMS_COUNTY VALUES (
	29095,
	'095',
	29,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	29097,
	'097',
	29,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	29099,
	'099',
	29,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	29101,
	'101',
	29,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	29103,
	'103',
	29,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	29105,
	'105',
	29,
	'Laclede'
);
INSERT INTO CWMS_COUNTY VALUES (
	29107,
	'107',
	29,
	'Lafayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	29109,
	'109',
	29,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	29111,
	'111',
	29,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	29113,
	'113',
	29,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	29115,
	'115',
	29,
	'Linn'
);
INSERT INTO CWMS_COUNTY VALUES (
	29117,
	'117',
	29,
	'Livingston'
);
INSERT INTO CWMS_COUNTY VALUES (
	29119,
	'119',
	29,
	'McDonald'
);
INSERT INTO CWMS_COUNTY VALUES (
	29121,
	'121',
	29,
	'Macon'
);
INSERT INTO CWMS_COUNTY VALUES (
	29123,
	'123',
	29,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	29125,
	'125',
	29,
	'Maries'
);
INSERT INTO CWMS_COUNTY VALUES (
	29127,
	'127',
	29,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	29129,
	'129',
	29,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	29131,
	'131',
	29,
	'Miller'
);
INSERT INTO CWMS_COUNTY VALUES (
	29133,
	'133',
	29,
	'Mississippi'
);
INSERT INTO CWMS_COUNTY VALUES (
	29135,
	'135',
	29,
	'Moniteau'
);
INSERT INTO CWMS_COUNTY VALUES (
	29137,
	'137',
	29,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	29139,
	'139',
	29,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	29141,
	'141',
	29,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	29143,
	'143',
	29,
	'New Madrid'
);
INSERT INTO CWMS_COUNTY VALUES (
	29145,
	'145',
	29,
	'Newton'
);
INSERT INTO CWMS_COUNTY VALUES (
	29147,
	'147',
	29,
	'Nodaway'
);
INSERT INTO CWMS_COUNTY VALUES (
	29149,
	'149',
	29,
	'Oregon'
);
INSERT INTO CWMS_COUNTY VALUES (
	29151,
	'151',
	29,
	'Osage'
);
INSERT INTO CWMS_COUNTY VALUES (
	29153,
	'153',
	29,
	'Ozark'
);
INSERT INTO CWMS_COUNTY VALUES (
	29155,
	'155',
	29,
	'Pemiscot'
);
INSERT INTO CWMS_COUNTY VALUES (
	29157,
	'157',
	29,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	29159,
	'159',
	29,
	'Pettis'
);
INSERT INTO CWMS_COUNTY VALUES (
	29161,
	'161',
	29,
	'Phelps'
);
INSERT INTO CWMS_COUNTY VALUES (
	29163,
	'163',
	29,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	29165,
	'165',
	29,
	'Platte'
);
INSERT INTO CWMS_COUNTY VALUES (
	29167,
	'167',
	29,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	29169,
	'169',
	29,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	29171,
	'171',
	29,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	29173,
	'173',
	29,
	'Ralls'
);
INSERT INTO CWMS_COUNTY VALUES (
	29175,
	'175',
	29,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	29177,
	'177',
	29,
	'Ray'
);
INSERT INTO CWMS_COUNTY VALUES (
	29179,
	'179',
	29,
	'Reynolds'
);
INSERT INTO CWMS_COUNTY VALUES (
	29181,
	'181',
	29,
	'Ripley'
);
INSERT INTO CWMS_COUNTY VALUES (
	29183,
	'183',
	29,
	'St. Charles'
);
INSERT INTO CWMS_COUNTY VALUES (
	29185,
	'185',
	29,
	'St. Clair'
);
INSERT INTO CWMS_COUNTY VALUES (
	29186,
	'186',
	29,
	'Ste. Genevieve'
);
INSERT INTO CWMS_COUNTY VALUES (
	29187,
	'187',
	29,
	'St. Francois'
);
INSERT INTO CWMS_COUNTY VALUES (
	29189,
	'189',
	29,
	'St. Louis'
);
INSERT INTO CWMS_COUNTY VALUES (
	29195,
	'195',
	29,
	'Saline'
);
INSERT INTO CWMS_COUNTY VALUES (
	29197,
	'197',
	29,
	'Schuyler'
);
INSERT INTO CWMS_COUNTY VALUES (
	29199,
	'199',
	29,
	'Scotland'
);
INSERT INTO CWMS_COUNTY VALUES (
	29201,
	'201',
	29,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	29203,
	'203',
	29,
	'Shannon'
);
INSERT INTO CWMS_COUNTY VALUES (
	29205,
	'205',
	29,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	29207,
	'207',
	29,
	'Stoddard'
);
INSERT INTO CWMS_COUNTY VALUES (
	29209,
	'209',
	29,
	'Stone'
);
INSERT INTO CWMS_COUNTY VALUES (
	29211,
	'211',
	29,
	'Sullivan'
);
INSERT INTO CWMS_COUNTY VALUES (
	29213,
	'213',
	29,
	'Taney'
);
INSERT INTO CWMS_COUNTY VALUES (
	29215,
	'215',
	29,
	'Texas'
);
INSERT INTO CWMS_COUNTY VALUES (
	29217,
	'217',
	29,
	'Vernon'
);
INSERT INTO CWMS_COUNTY VALUES (
	29219,
	'219',
	29,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	29221,
	'221',
	29,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	29223,
	'223',
	29,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	29225,
	'225',
	29,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	29227,
	'227',
	29,
	'Worth'
);
INSERT INTO CWMS_COUNTY VALUES (
	29229,
	'229',
	29,
	'Wright'
);
INSERT INTO CWMS_COUNTY VALUES (
	29510,
	'510',
	29,
	'St. Louis City'
);
INSERT INTO CWMS_COUNTY VALUES (
	30000,
	'000',
	30,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	30001,
	'001',
	30,
	'Beaverhead'
);
INSERT INTO CWMS_COUNTY VALUES (
	30003,
	'003',
	30,
	'Big Horn'
);
INSERT INTO CWMS_COUNTY VALUES (
	30005,
	'005',
	30,
	'Blaine'
);
INSERT INTO CWMS_COUNTY VALUES (
	30007,
	'007',
	30,
	'Broadwater'
);
INSERT INTO CWMS_COUNTY VALUES (
	30009,
	'009',
	30,
	'Carbon'
);
INSERT INTO CWMS_COUNTY VALUES (
	30011,
	'011',
	30,
	'Carter'
);
INSERT INTO CWMS_COUNTY VALUES (
	30013,
	'013',
	30,
	'Cascade'
);
INSERT INTO CWMS_COUNTY VALUES (
	30015,
	'015',
	30,
	'Chouteau'
);
INSERT INTO CWMS_COUNTY VALUES (
	30017,
	'017',
	30,
	'Custer'
);
INSERT INTO CWMS_COUNTY VALUES (
	30019,
	'019',
	30,
	'Daniels'
);
INSERT INTO CWMS_COUNTY VALUES (
	30021,
	'021',
	30,
	'Dawson'
);
INSERT INTO CWMS_COUNTY VALUES (
	30023,
	'023',
	30,
	'Deer Lodge'
);
INSERT INTO CWMS_COUNTY VALUES (
	30025,
	'025',
	30,
	'Fallon'
);
INSERT INTO CWMS_COUNTY VALUES (
	30027,
	'027',
	30,
	'Fergus'
);
INSERT INTO CWMS_COUNTY VALUES (
	30029,
	'029',
	30,
	'Flathead'
);
INSERT INTO CWMS_COUNTY VALUES (
	30031,
	'031',
	30,
	'Gallatin'
);
INSERT INTO CWMS_COUNTY VALUES (
	30033,
	'033',
	30,
	'Garfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	30035,
	'035',
	30,
	'Glacier'
);
INSERT INTO CWMS_COUNTY VALUES (
	30037,
	'037',
	30,
	'Golden Valley'
);
INSERT INTO CWMS_COUNTY VALUES (
	30039,
	'039',
	30,
	'Granite'
);
INSERT INTO CWMS_COUNTY VALUES (
	30041,
	'041',
	30,
	'Hill'
);
INSERT INTO CWMS_COUNTY VALUES (
	30043,
	'043',
	30,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	30045,
	'045',
	30,
	'Judith Basin'
);
INSERT INTO CWMS_COUNTY VALUES (
	30047,
	'047',
	30,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	30049,
	'049',
	30,
	'Lewis and Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	30051,
	'051',
	30,
	'Liberty'
);
INSERT INTO CWMS_COUNTY VALUES (
	30053,
	'053',
	30,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	30055,
	'055',
	30,
	'McCone'
);
INSERT INTO CWMS_COUNTY VALUES (
	30057,
	'057',
	30,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	30059,
	'059',
	30,
	'Meagher'
);
INSERT INTO CWMS_COUNTY VALUES (
	30061,
	'061',
	30,
	'Mineral'
);
INSERT INTO CWMS_COUNTY VALUES (
	30063,
	'063',
	30,
	'Missoula'
);
INSERT INTO CWMS_COUNTY VALUES (
	30065,
	'065',
	30,
	'Musselshell'
);
INSERT INTO CWMS_COUNTY VALUES (
	30067,
	'067',
	30,
	'Park'
);
INSERT INTO CWMS_COUNTY VALUES (
	30069,
	'069',
	30,
	'Petroleum'
);
INSERT INTO CWMS_COUNTY VALUES (
	30071,
	'071',
	30,
	'Phillips'
);
INSERT INTO CWMS_COUNTY VALUES (
	30073,
	'073',
	30,
	'Pondera'
);
INSERT INTO CWMS_COUNTY VALUES (
	30075,
	'075',
	30,
	'Powder River'
);
INSERT INTO CWMS_COUNTY VALUES (
	30077,
	'077',
	30,
	'Powell'
);
INSERT INTO CWMS_COUNTY VALUES (
	30079,
	'079',
	30,
	'Prairie'
);
INSERT INTO CWMS_COUNTY VALUES (
	30081,
	'081',
	30,
	'Ravalli'
);
INSERT INTO CWMS_COUNTY VALUES (
	30083,
	'083',
	30,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	30085,
	'085',
	30,
	'Roosevelt'
);
INSERT INTO CWMS_COUNTY VALUES (
	30087,
	'087',
	30,
	'Rosebud'
);
INSERT INTO CWMS_COUNTY VALUES (
	30089,
	'089',
	30,
	'Sanders'
);
INSERT INTO CWMS_COUNTY VALUES (
	30091,
	'091',
	30,
	'Sheridan'
);
INSERT INTO CWMS_COUNTY VALUES (
	30093,
	'093',
	30,
	'Silver Bow'
);
INSERT INTO CWMS_COUNTY VALUES (
	30095,
	'095',
	30,
	'Stillwater'
);
INSERT INTO CWMS_COUNTY VALUES (
	30097,
	'097',
	30,
	'Sweet Grass'
);
INSERT INTO CWMS_COUNTY VALUES (
	30099,
	'099',
	30,
	'Teton'
);
INSERT INTO CWMS_COUNTY VALUES (
	30101,
	'101',
	30,
	'Toole'
);
INSERT INTO CWMS_COUNTY VALUES (
	30103,
	'103',
	30,
	'Treasure'
);
INSERT INTO CWMS_COUNTY VALUES (
	30105,
	'105',
	30,
	'Valley'
);
INSERT INTO CWMS_COUNTY VALUES (
	30107,
	'107',
	30,
	'Wheatland'
);
INSERT INTO CWMS_COUNTY VALUES (
	30109,
	'109',
	30,
	'Wibaux'
);
INSERT INTO CWMS_COUNTY VALUES (
	30111,
	'111',
	30,
	'Yellowstone'
);
INSERT INTO CWMS_COUNTY VALUES (
	31000,
	'000',
	31,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	31001,
	'001',
	31,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	31003,
	'003',
	31,
	'Antelope'
);
INSERT INTO CWMS_COUNTY VALUES (
	31005,
	'005',
	31,
	'Arthur'
);
INSERT INTO CWMS_COUNTY VALUES (
	31007,
	'007',
	31,
	'Banner'
);
INSERT INTO CWMS_COUNTY VALUES (
	31009,
	'009',
	31,
	'Blaine'
);
INSERT INTO CWMS_COUNTY VALUES (
	31011,
	'011',
	31,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	31013,
	'013',
	31,
	'Box Butte'
);
INSERT INTO CWMS_COUNTY VALUES (
	31015,
	'015',
	31,
	'Boyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	31017,
	'017',
	31,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	31019,
	'019',
	31,
	'Buffalo'
);
INSERT INTO CWMS_COUNTY VALUES (
	31021,
	'021',
	31,
	'Burt'
);
INSERT INTO CWMS_COUNTY VALUES (
	31023,
	'023',
	31,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	31025,
	'025',
	31,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	31027,
	'027',
	31,
	'Cedar'
);
INSERT INTO CWMS_COUNTY VALUES (
	31029,
	'029',
	31,
	'Chase'
);
INSERT INTO CWMS_COUNTY VALUES (
	31031,
	'031',
	31,
	'Cherry'
);
INSERT INTO CWMS_COUNTY VALUES (
	31033,
	'033',
	31,
	'Cheyenne'
);
INSERT INTO CWMS_COUNTY VALUES (
	31035,
	'035',
	31,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	31037,
	'037',
	31,
	'Colfax'
);
INSERT INTO CWMS_COUNTY VALUES (
	31039,
	'039',
	31,
	'Cuming'
);
INSERT INTO CWMS_COUNTY VALUES (
	31041,
	'041',
	31,
	'Custer'
);
INSERT INTO CWMS_COUNTY VALUES (
	31043,
	'043',
	31,
	'Dakota'
);
INSERT INTO CWMS_COUNTY VALUES (
	31045,
	'045',
	31,
	'Dawes'
);
INSERT INTO CWMS_COUNTY VALUES (
	31047,
	'047',
	31,
	'Dawson'
);
INSERT INTO CWMS_COUNTY VALUES (
	31049,
	'049',
	31,
	'Deuel'
);
INSERT INTO CWMS_COUNTY VALUES (
	31051,
	'051',
	31,
	'Dixon'
);
INSERT INTO CWMS_COUNTY VALUES (
	31053,
	'053',
	31,
	'Dodge'
);
INSERT INTO CWMS_COUNTY VALUES (
	31055,
	'055',
	31,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	31057,
	'057',
	31,
	'Dundy'
);
INSERT INTO CWMS_COUNTY VALUES (
	31059,
	'059',
	31,
	'Fillmore'
);
INSERT INTO CWMS_COUNTY VALUES (
	31061,
	'061',
	31,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	31063,
	'063',
	31,
	'Frontier'
);
INSERT INTO CWMS_COUNTY VALUES (
	31065,
	'065',
	31,
	'Furnas'
);
INSERT INTO CWMS_COUNTY VALUES (
	31067,
	'067',
	31,
	'Gage'
);
INSERT INTO CWMS_COUNTY VALUES (
	31069,
	'069',
	31,
	'Garden'
);
INSERT INTO CWMS_COUNTY VALUES (
	31071,
	'071',
	31,
	'Garfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	31073,
	'073',
	31,
	'Gosper'
);
INSERT INTO CWMS_COUNTY VALUES (
	31075,
	'075',
	31,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	31077,
	'077',
	31,
	'Greeley'
);
INSERT INTO CWMS_COUNTY VALUES (
	31079,
	'079',
	31,
	'Hall'
);
INSERT INTO CWMS_COUNTY VALUES (
	31081,
	'081',
	31,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	31083,
	'083',
	31,
	'Harlan'
);
INSERT INTO CWMS_COUNTY VALUES (
	31085,
	'085',
	31,
	'Hayes'
);
INSERT INTO CWMS_COUNTY VALUES (
	31087,
	'087',
	31,
	'Hitchcock'
);
INSERT INTO CWMS_COUNTY VALUES (
	31089,
	'089',
	31,
	'Holt'
);
INSERT INTO CWMS_COUNTY VALUES (
	31091,
	'091',
	31,
	'Hooker'
);
INSERT INTO CWMS_COUNTY VALUES (
	31093,
	'093',
	31,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	31095,
	'095',
	31,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	31097,
	'097',
	31,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	31099,
	'099',
	31,
	'Kearney'
);
INSERT INTO CWMS_COUNTY VALUES (
	31101,
	'101',
	31,
	'Keith'
);
INSERT INTO CWMS_COUNTY VALUES (
	31103,
	'103',
	31,
	'Keya Paha'
);
INSERT INTO CWMS_COUNTY VALUES (
	31105,
	'105',
	31,
	'Kimball'
);
INSERT INTO CWMS_COUNTY VALUES (
	31107,
	'107',
	31,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	31109,
	'109',
	31,
	'Lancaster'
);
INSERT INTO CWMS_COUNTY VALUES (
	31111,
	'111',
	31,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	31113,
	'113',
	31,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	31115,
	'115',
	31,
	'Loup'
);
INSERT INTO CWMS_COUNTY VALUES (
	31117,
	'117',
	31,
	'McPherson'
);
INSERT INTO CWMS_COUNTY VALUES (
	31119,
	'119',
	31,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	31121,
	'121',
	31,
	'Merrick'
);
INSERT INTO CWMS_COUNTY VALUES (
	31123,
	'123',
	31,
	'Morrill'
);
INSERT INTO CWMS_COUNTY VALUES (
	31125,
	'125',
	31,
	'Nance'
);
INSERT INTO CWMS_COUNTY VALUES (
	31127,
	'127',
	31,
	'Nemaha'
);
INSERT INTO CWMS_COUNTY VALUES (
	31129,
	'129',
	31,
	'Nuckolls'
);
INSERT INTO CWMS_COUNTY VALUES (
	31131,
	'131',
	31,
	'Otoe'
);
INSERT INTO CWMS_COUNTY VALUES (
	31133,
	'133',
	31,
	'Pawnee'
);
INSERT INTO CWMS_COUNTY VALUES (
	31135,
	'135',
	31,
	'Perkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	31137,
	'137',
	31,
	'Phelps'
);
INSERT INTO CWMS_COUNTY VALUES (
	31139,
	'139',
	31,
	'Pierce'
);
INSERT INTO CWMS_COUNTY VALUES (
	31141,
	'141',
	31,
	'Platte'
);
INSERT INTO CWMS_COUNTY VALUES (
	31143,
	'143',
	31,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	31145,
	'145',
	31,
	'Red Willow'
);
INSERT INTO CWMS_COUNTY VALUES (
	31147,
	'147',
	31,
	'Richardson'
);
INSERT INTO CWMS_COUNTY VALUES (
	31149,
	'149',
	31,
	'Rock'
);
INSERT INTO CWMS_COUNTY VALUES (
	31151,
	'151',
	31,
	'Saline'
);
INSERT INTO CWMS_COUNTY VALUES (
	31153,
	'153',
	31,
	'Sarpy'
);
INSERT INTO CWMS_COUNTY VALUES (
	31155,
	'155',
	31,
	'Saunders'
);
INSERT INTO CWMS_COUNTY VALUES (
	31157,
	'157',
	31,
	'Scotts Bluff'
);
INSERT INTO CWMS_COUNTY VALUES (
	31159,
	'159',
	31,
	'Seward'
);
INSERT INTO CWMS_COUNTY VALUES (
	31161,
	'161',
	31,
	'Sheridan'
);
INSERT INTO CWMS_COUNTY VALUES (
	31163,
	'163',
	31,
	'Sherman'
);
INSERT INTO CWMS_COUNTY VALUES (
	31165,
	'165',
	31,
	'Sioux'
);
INSERT INTO CWMS_COUNTY VALUES (
	31167,
	'167',
	31,
	'Stanton'
);
INSERT INTO CWMS_COUNTY VALUES (
	31169,
	'169',
	31,
	'Thayer'
);
INSERT INTO CWMS_COUNTY VALUES (
	31171,
	'171',
	31,
	'Thomas'
);
INSERT INTO CWMS_COUNTY VALUES (
	31173,
	'173',
	31,
	'Thurston'
);
INSERT INTO CWMS_COUNTY VALUES (
	31175,
	'175',
	31,
	'Valley'
);
INSERT INTO CWMS_COUNTY VALUES (
	31177,
	'177',
	31,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	31179,
	'179',
	31,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	31181,
	'181',
	31,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	31183,
	'183',
	31,
	'Wheeler'
);
INSERT INTO CWMS_COUNTY VALUES (
	31185,
	'185',
	31,
	'York'
);
INSERT INTO CWMS_COUNTY VALUES (
	32000,
	'000',
	32,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	32001,
	'001',
	32,
	'Churchill'
);
INSERT INTO CWMS_COUNTY VALUES (
	32003,
	'003',
	32,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	32005,
	'005',
	32,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	32007,
	'007',
	32,
	'Elko'
);
INSERT INTO CWMS_COUNTY VALUES (
	32009,
	'009',
	32,
	'Esmeralda'
);
INSERT INTO CWMS_COUNTY VALUES (
	32011,
	'011',
	32,
	'Eureka'
);
INSERT INTO CWMS_COUNTY VALUES (
	32013,
	'013',
	32,
	'Humboldt'
);
INSERT INTO CWMS_COUNTY VALUES (
	32015,
	'015',
	32,
	'Lander'
);
INSERT INTO CWMS_COUNTY VALUES (
	32017,
	'017',
	32,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	32019,
	'019',
	32,
	'Lyon'
);
INSERT INTO CWMS_COUNTY VALUES (
	32021,
	'021',
	32,
	'Mineral'
);
INSERT INTO CWMS_COUNTY VALUES (
	32023,
	'023',
	32,
	'Nye'
);
INSERT INTO CWMS_COUNTY VALUES (
	32027,
	'027',
	32,
	'Pershing'
);
INSERT INTO CWMS_COUNTY VALUES (
	32029,
	'029',
	32,
	'Storey'
);
INSERT INTO CWMS_COUNTY VALUES (
	32031,
	'031',
	32,
	'Washoe'
);
INSERT INTO CWMS_COUNTY VALUES (
	32033,
	'033',
	32,
	'White Pine'
);
INSERT INTO CWMS_COUNTY VALUES (
	32510,
	'510',
	32,
	'Carson City'
);
INSERT INTO CWMS_COUNTY VALUES (
	33000,
	'000',
	33,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	33001,
	'001',
	33,
	'Belknap'
);
INSERT INTO CWMS_COUNTY VALUES (
	33003,
	'003',
	33,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	33005,
	'005',
	33,
	'Cheshire'
);
INSERT INTO CWMS_COUNTY VALUES (
	33007,
	'007',
	33,
	'Coos'
);
INSERT INTO CWMS_COUNTY VALUES (
	33009,
	'009',
	33,
	'Grafton'
);
INSERT INTO CWMS_COUNTY VALUES (
	33011,
	'011',
	33,
	'Hillsborough'
);
INSERT INTO CWMS_COUNTY VALUES (
	33013,
	'013',
	33,
	'Merrimack'
);
INSERT INTO CWMS_COUNTY VALUES (
	33015,
	'015',
	33,
	'Rockingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	33017,
	'017',
	33,
	'Strafford'
);
INSERT INTO CWMS_COUNTY VALUES (
	33019,
	'019',
	33,
	'Sullivan'
);
INSERT INTO CWMS_COUNTY VALUES (
	34000,
	'000',
	34,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	34001,
	'001',
	34,
	'Atlantic'
);
INSERT INTO CWMS_COUNTY VALUES (
	34003,
	'003',
	34,
	'Bergen'
);
INSERT INTO CWMS_COUNTY VALUES (
	34005,
	'005',
	34,
	'Burlington'
);
INSERT INTO CWMS_COUNTY VALUES (
	34007,
	'007',
	34,
	'Camden'
);
INSERT INTO CWMS_COUNTY VALUES (
	34009,
	'009',
	34,
	'Cape May'
);
INSERT INTO CWMS_COUNTY VALUES (
	34011,
	'011',
	34,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	34013,
	'013',
	34,
	'Essex'
);
INSERT INTO CWMS_COUNTY VALUES (
	34015,
	'015',
	34,
	'Gloucester'
);
INSERT INTO CWMS_COUNTY VALUES (
	34017,
	'017',
	34,
	'Hudson'
);
INSERT INTO CWMS_COUNTY VALUES (
	34019,
	'019',
	34,
	'Hunterdon'
);
INSERT INTO CWMS_COUNTY VALUES (
	34021,
	'021',
	34,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	34023,
	'023',
	34,
	'Middlesex'
);
INSERT INTO CWMS_COUNTY VALUES (
	34025,
	'025',
	34,
	'Monmouth'
);
INSERT INTO CWMS_COUNTY VALUES (
	34027,
	'027',
	34,
	'Morris'
);
INSERT INTO CWMS_COUNTY VALUES (
	34029,
	'029',
	34,
	'Ocean'
);
INSERT INTO CWMS_COUNTY VALUES (
	34031,
	'031',
	34,
	'Passaic'
);
INSERT INTO CWMS_COUNTY VALUES (
	34033,
	'033',
	34,
	'Salem'
);
INSERT INTO CWMS_COUNTY VALUES (
	34035,
	'035',
	34,
	'Somerset'
);
INSERT INTO CWMS_COUNTY VALUES (
	34037,
	'037',
	34,
	'Sussex'
);
INSERT INTO CWMS_COUNTY VALUES (
	34039,
	'039',
	34,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	34041,
	'041',
	34,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	35000,
	'000',
	35,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	35001,
	'001',
	35,
	'Bernalillo'
);
INSERT INTO CWMS_COUNTY VALUES (
	35003,
	'003',
	35,
	'Catron'
);
INSERT INTO CWMS_COUNTY VALUES (
	35005,
	'005',
	35,
	'Chaves'
);
INSERT INTO CWMS_COUNTY VALUES (
	35006,
	'006',
	35,
	'Cibola'
);
INSERT INTO CWMS_COUNTY VALUES (
	35007,
	'007',
	35,
	'Colfax'
);
INSERT INTO CWMS_COUNTY VALUES (
	35009,
	'009',
	35,
	'Curry'
);
INSERT INTO CWMS_COUNTY VALUES (
	35011,
	'011',
	35,
	'De Baca'
);
INSERT INTO CWMS_COUNTY VALUES (
	35013,
	'013',
	35,
	'Dona Ana'
);
INSERT INTO CWMS_COUNTY VALUES (
	35015,
	'015',
	35,
	'Eddy'
);
INSERT INTO CWMS_COUNTY VALUES (
	35017,
	'017',
	35,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	35019,
	'019',
	35,
	'Guadalupe'
);
INSERT INTO CWMS_COUNTY VALUES (
	35021,
	'021',
	35,
	'Harding'
);
INSERT INTO CWMS_COUNTY VALUES (
	35023,
	'023',
	35,
	'Hidalgo'
);
INSERT INTO CWMS_COUNTY VALUES (
	35025,
	'025',
	35,
	'Lea'
);
INSERT INTO CWMS_COUNTY VALUES (
	35027,
	'027',
	35,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	35028,
	'028',
	35,
	'Los Alamos'
);
INSERT INTO CWMS_COUNTY VALUES (
	35029,
	'029',
	35,
	'Luna'
);
INSERT INTO CWMS_COUNTY VALUES (
	35031,
	'031',
	35,
	'McKinley'
);
INSERT INTO CWMS_COUNTY VALUES (
	35033,
	'033',
	35,
	'Mora'
);
INSERT INTO CWMS_COUNTY VALUES (
	35035,
	'035',
	35,
	'Otero'
);
INSERT INTO CWMS_COUNTY VALUES (
	35037,
	'037',
	35,
	'Quay'
);
INSERT INTO CWMS_COUNTY VALUES (
	35039,
	'039',
	35,
	'Rio Arriba'
);
INSERT INTO CWMS_COUNTY VALUES (
	35041,
	'041',
	35,
	'Roosevelt'
);
INSERT INTO CWMS_COUNTY VALUES (
	35043,
	'043',
	35,
	'Sandoval'
);
INSERT INTO CWMS_COUNTY VALUES (
	35045,
	'045',
	35,
	'San Juan'
);
INSERT INTO CWMS_COUNTY VALUES (
	35047,
	'047',
	35,
	'San Miguel'
);
INSERT INTO CWMS_COUNTY VALUES (
	35049,
	'049',
	35,
	'Santa Fe'
);
INSERT INTO CWMS_COUNTY VALUES (
	35051,
	'051',
	35,
	'Sierra'
);
INSERT INTO CWMS_COUNTY VALUES (
	35053,
	'053',
	35,
	'Socorro'
);
INSERT INTO CWMS_COUNTY VALUES (
	35055,
	'055',
	35,
	'Taos'
);
INSERT INTO CWMS_COUNTY VALUES (
	35057,
	'057',
	35,
	'Torrance'
);
INSERT INTO CWMS_COUNTY VALUES (
	35059,
	'059',
	35,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	35061,
	'061',
	35,
	'Valencia'
);
INSERT INTO CWMS_COUNTY VALUES (
	36000,
	'000',
	36,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	36001,
	'001',
	36,
	'Albany'
);
INSERT INTO CWMS_COUNTY VALUES (
	36003,
	'003',
	36,
	'Allegany'
);
INSERT INTO CWMS_COUNTY VALUES (
	36005,
	'005',
	36,
	'Bronx'
);
INSERT INTO CWMS_COUNTY VALUES (
	36007,
	'007',
	36,
	'Broome'
);
INSERT INTO CWMS_COUNTY VALUES (
	36009,
	'009',
	36,
	'Cattaraugus'
);
INSERT INTO CWMS_COUNTY VALUES (
	36011,
	'011',
	36,
	'Cayuga'
);
INSERT INTO CWMS_COUNTY VALUES (
	36013,
	'013',
	36,
	'Chautauqua'
);
INSERT INTO CWMS_COUNTY VALUES (
	36015,
	'015',
	36,
	'Chemung'
);
INSERT INTO CWMS_COUNTY VALUES (
	36017,
	'017',
	36,
	'Chenango'
);
INSERT INTO CWMS_COUNTY VALUES (
	36019,
	'019',
	36,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	36021,
	'021',
	36,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	36023,
	'023',
	36,
	'Cortland'
);
INSERT INTO CWMS_COUNTY VALUES (
	36025,
	'025',
	36,
	'Delaware'
);
INSERT INTO CWMS_COUNTY VALUES (
	36027,
	'027',
	36,
	'Dutchess'
);
INSERT INTO CWMS_COUNTY VALUES (
	36029,
	'029',
	36,
	'Erie'
);
INSERT INTO CWMS_COUNTY VALUES (
	36031,
	'031',
	36,
	'Essex'
);
INSERT INTO CWMS_COUNTY VALUES (
	36033,
	'033',
	36,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	36035,
	'035',
	36,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	36037,
	'037',
	36,
	'Genesee'
);
INSERT INTO CWMS_COUNTY VALUES (
	36039,
	'039',
	36,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	36041,
	'041',
	36,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	36043,
	'043',
	36,
	'Herkimer'
);
INSERT INTO CWMS_COUNTY VALUES (
	36045,
	'045',
	36,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	36047,
	'047',
	36,
	'Kings'
);
INSERT INTO CWMS_COUNTY VALUES (
	36049,
	'049',
	36,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	36051,
	'051',
	36,
	'Livingston'
);
INSERT INTO CWMS_COUNTY VALUES (
	36053,
	'053',
	36,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	36055,
	'055',
	36,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	36057,
	'057',
	36,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	36059,
	'059',
	36,
	'Nassau'
);
INSERT INTO CWMS_COUNTY VALUES (
	36061,
	'061',
	36,
	'New York'
);
INSERT INTO CWMS_COUNTY VALUES (
	36063,
	'063',
	36,
	'Niagara'
);
INSERT INTO CWMS_COUNTY VALUES (
	36065,
	'065',
	36,
	'Oneida'
);
INSERT INTO CWMS_COUNTY VALUES (
	36067,
	'067',
	36,
	'Onondaga'
);
INSERT INTO CWMS_COUNTY VALUES (
	36069,
	'069',
	36,
	'Ontario'
);
INSERT INTO CWMS_COUNTY VALUES (
	36071,
	'071',
	36,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	36073,
	'073',
	36,
	'Orleans'
);
INSERT INTO CWMS_COUNTY VALUES (
	36075,
	'075',
	36,
	'Oswego'
);
INSERT INTO CWMS_COUNTY VALUES (
	36077,
	'077',
	36,
	'Otsego'
);
INSERT INTO CWMS_COUNTY VALUES (
	36079,
	'079',
	36,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	36081,
	'081',
	36,
	'Queens'
);
INSERT INTO CWMS_COUNTY VALUES (
	36083,
	'083',
	36,
	'Rensselaer'
);
INSERT INTO CWMS_COUNTY VALUES (
	36085,
	'085',
	36,
	'Richmond'
);
INSERT INTO CWMS_COUNTY VALUES (
	36087,
	'087',
	36,
	'Rockland'
);
INSERT INTO CWMS_COUNTY VALUES (
	36089,
	'089',
	36,
	'St. Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	36091,
	'091',
	36,
	'Saratoga'
);
INSERT INTO CWMS_COUNTY VALUES (
	36093,
	'093',
	36,
	'Schenectady'
);
INSERT INTO CWMS_COUNTY VALUES (
	36095,
	'095',
	36,
	'Schoharie'
);
INSERT INTO CWMS_COUNTY VALUES (
	36097,
	'097',
	36,
	'Schuyler'
);
INSERT INTO CWMS_COUNTY VALUES (
	36099,
	'099',
	36,
	'Seneca'
);
INSERT INTO CWMS_COUNTY VALUES (
	36101,
	'101',
	36,
	'Steuben'
);
INSERT INTO CWMS_COUNTY VALUES (
	36103,
	'103',
	36,
	'Suffolk'
);
INSERT INTO CWMS_COUNTY VALUES (
	36105,
	'105',
	36,
	'Sullivan'
);
INSERT INTO CWMS_COUNTY VALUES (
	36107,
	'107',
	36,
	'Tioga'
);
INSERT INTO CWMS_COUNTY VALUES (
	36109,
	'109',
	36,
	'Tompkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	36111,
	'111',
	36,
	'Ulster'
);
INSERT INTO CWMS_COUNTY VALUES (
	36113,
	'113',
	36,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	36115,
	'115',
	36,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	36117,
	'117',
	36,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	36119,
	'119',
	36,
	'Westchester'
);
INSERT INTO CWMS_COUNTY VALUES (
	36121,
	'121',
	36,
	'Wyoming'
);
INSERT INTO CWMS_COUNTY VALUES (
	36123,
	'123',
	36,
	'Yates'
);
INSERT INTO CWMS_COUNTY VALUES (
	37000,
	'000',
	37,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	37001,
	'001',
	37,
	'Alamance'
);
INSERT INTO CWMS_COUNTY VALUES (
	37003,
	'003',
	37,
	'Alexander'
);
INSERT INTO CWMS_COUNTY VALUES (
	37005,
	'005',
	37,
	'Alleghany'
);
INSERT INTO CWMS_COUNTY VALUES (
	37007,
	'007',
	37,
	'Anson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37009,
	'009',
	37,
	'Ashe'
);
INSERT INTO CWMS_COUNTY VALUES (
	37011,
	'011',
	37,
	'Avery'
);
INSERT INTO CWMS_COUNTY VALUES (
	37013,
	'013',
	37,
	'Beaufort'
);
INSERT INTO CWMS_COUNTY VALUES (
	37015,
	'015',
	37,
	'Bertie'
);
INSERT INTO CWMS_COUNTY VALUES (
	37017,
	'017',
	37,
	'Bladen'
);
INSERT INTO CWMS_COUNTY VALUES (
	37019,
	'019',
	37,
	'Brunswick'
);
INSERT INTO CWMS_COUNTY VALUES (
	37021,
	'021',
	37,
	'Buncombe'
);
INSERT INTO CWMS_COUNTY VALUES (
	37023,
	'023',
	37,
	'Burke'
);
INSERT INTO CWMS_COUNTY VALUES (
	37025,
	'025',
	37,
	'Cabarrus'
);
INSERT INTO CWMS_COUNTY VALUES (
	37027,
	'027',
	37,
	'Caldwell'
);
INSERT INTO CWMS_COUNTY VALUES (
	37029,
	'029',
	37,
	'Camden'
);
INSERT INTO CWMS_COUNTY VALUES (
	37031,
	'031',
	37,
	'Carteret'
);
INSERT INTO CWMS_COUNTY VALUES (
	37033,
	'033',
	37,
	'Caswell'
);
INSERT INTO CWMS_COUNTY VALUES (
	37035,
	'035',
	37,
	'Catawba'
);
INSERT INTO CWMS_COUNTY VALUES (
	37037,
	'037',
	37,
	'Chatham'
);
INSERT INTO CWMS_COUNTY VALUES (
	37039,
	'039',
	37,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	37041,
	'041',
	37,
	'Chowan'
);
INSERT INTO CWMS_COUNTY VALUES (
	37043,
	'043',
	37,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	37045,
	'045',
	37,
	'Cleveland'
);
INSERT INTO CWMS_COUNTY VALUES (
	37047,
	'047',
	37,
	'Columbus'
);
INSERT INTO CWMS_COUNTY VALUES (
	37049,
	'049',
	37,
	'Craven'
);
INSERT INTO CWMS_COUNTY VALUES (
	37051,
	'051',
	37,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	37053,
	'053',
	37,
	'Currituck'
);
INSERT INTO CWMS_COUNTY VALUES (
	37055,
	'055',
	37,
	'Dare'
);
INSERT INTO CWMS_COUNTY VALUES (
	37057,
	'057',
	37,
	'Davidson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37059,
	'059',
	37,
	'Davie'
);
INSERT INTO CWMS_COUNTY VALUES (
	37061,
	'061',
	37,
	'Duplin'
);
INSERT INTO CWMS_COUNTY VALUES (
	37063,
	'063',
	37,
	'Durham'
);
INSERT INTO CWMS_COUNTY VALUES (
	37065,
	'065',
	37,
	'Edgecombe'
);
INSERT INTO CWMS_COUNTY VALUES (
	37067,
	'067',
	37,
	'Forsyth'
);
INSERT INTO CWMS_COUNTY VALUES (
	37069,
	'069',
	37,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	37071,
	'071',
	37,
	'Gaston'
);
INSERT INTO CWMS_COUNTY VALUES (
	37073,
	'073',
	37,
	'Gates'
);
INSERT INTO CWMS_COUNTY VALUES (
	37075,
	'075',
	37,
	'Graham'
);
INSERT INTO CWMS_COUNTY VALUES (
	37077,
	'077',
	37,
	'Granville'
);
INSERT INTO CWMS_COUNTY VALUES (
	37079,
	'079',
	37,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	37081,
	'081',
	37,
	'Guilford'
);
INSERT INTO CWMS_COUNTY VALUES (
	37083,
	'083',
	37,
	'Halifax'
);
INSERT INTO CWMS_COUNTY VALUES (
	37085,
	'085',
	37,
	'Harnett'
);
INSERT INTO CWMS_COUNTY VALUES (
	37087,
	'087',
	37,
	'Haywood'
);
INSERT INTO CWMS_COUNTY VALUES (
	37089,
	'089',
	37,
	'Henderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37091,
	'091',
	37,
	'Hertford'
);
INSERT INTO CWMS_COUNTY VALUES (
	37093,
	'093',
	37,
	'Hoke'
);
INSERT INTO CWMS_COUNTY VALUES (
	37095,
	'095',
	37,
	'Hyde'
);
INSERT INTO CWMS_COUNTY VALUES (
	37097,
	'097',
	37,
	'Iredell'
);
INSERT INTO CWMS_COUNTY VALUES (
	37099,
	'099',
	37,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37101,
	'101',
	37,
	'Johnston'
);
INSERT INTO CWMS_COUNTY VALUES (
	37103,
	'103',
	37,
	'Jones'
);
INSERT INTO CWMS_COUNTY VALUES (
	37105,
	'105',
	37,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	37107,
	'107',
	37,
	'Lenoir'
);
INSERT INTO CWMS_COUNTY VALUES (
	37109,
	'109',
	37,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	37111,
	'111',
	37,
	'McDowell'
);
INSERT INTO CWMS_COUNTY VALUES (
	37113,
	'113',
	37,
	'Macon'
);
INSERT INTO CWMS_COUNTY VALUES (
	37115,
	'115',
	37,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	37117,
	'117',
	37,
	'Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	37119,
	'119',
	37,
	'Mecklenburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	37121,
	'121',
	37,
	'Mitchell'
);
INSERT INTO CWMS_COUNTY VALUES (
	37123,
	'123',
	37,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	37125,
	'125',
	37,
	'Moore'
);
INSERT INTO CWMS_COUNTY VALUES (
	37127,
	'127',
	37,
	'Nash'
);
INSERT INTO CWMS_COUNTY VALUES (
	37129,
	'129',
	37,
	'New Hanover'
);
INSERT INTO CWMS_COUNTY VALUES (
	37131,
	'131',
	37,
	'Northampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	37133,
	'133',
	37,
	'Onslow'
);
INSERT INTO CWMS_COUNTY VALUES (
	37135,
	'135',
	37,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	37137,
	'137',
	37,
	'Pamlico'
);
INSERT INTO CWMS_COUNTY VALUES (
	37139,
	'139',
	37,
	'Pasquotank'
);
INSERT INTO CWMS_COUNTY VALUES (
	37141,
	'141',
	37,
	'Pender'
);
INSERT INTO CWMS_COUNTY VALUES (
	37143,
	'143',
	37,
	'Perquimans'
);
INSERT INTO CWMS_COUNTY VALUES (
	37145,
	'145',
	37,
	'Person'
);
INSERT INTO CWMS_COUNTY VALUES (
	37147,
	'147',
	37,
	'Pitt'
);
INSERT INTO CWMS_COUNTY VALUES (
	37149,
	'149',
	37,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	37151,
	'151',
	37,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	37153,
	'153',
	37,
	'Richmond'
);
INSERT INTO CWMS_COUNTY VALUES (
	37155,
	'155',
	37,
	'Robeson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37157,
	'157',
	37,
	'Rockingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	37159,
	'159',
	37,
	'Rowan'
);
INSERT INTO CWMS_COUNTY VALUES (
	37161,
	'161',
	37,
	'Rutherford'
);
INSERT INTO CWMS_COUNTY VALUES (
	37163,
	'163',
	37,
	'Sampson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37165,
	'165',
	37,
	'Scotland'
);
INSERT INTO CWMS_COUNTY VALUES (
	37167,
	'167',
	37,
	'Stanly'
);
INSERT INTO CWMS_COUNTY VALUES (
	37169,
	'169',
	37,
	'Stokes'
);
INSERT INTO CWMS_COUNTY VALUES (
	37171,
	'171',
	37,
	'Surry'
);
INSERT INTO CWMS_COUNTY VALUES (
	37173,
	'173',
	37,
	'Swain'
);
INSERT INTO CWMS_COUNTY VALUES (
	37175,
	'175',
	37,
	'Transylvania'
);
INSERT INTO CWMS_COUNTY VALUES (
	37177,
	'177',
	37,
	'Tyrrell'
);
INSERT INTO CWMS_COUNTY VALUES (
	37179,
	'179',
	37,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	37181,
	'181',
	37,
	'Vance'
);
INSERT INTO CWMS_COUNTY VALUES (
	37183,
	'183',
	37,
	'Wake'
);
INSERT INTO CWMS_COUNTY VALUES (
	37185,
	'185',
	37,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	37187,
	'187',
	37,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	37189,
	'189',
	37,
	'Watauga'
);
INSERT INTO CWMS_COUNTY VALUES (
	37191,
	'191',
	37,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	37193,
	'193',
	37,
	'Wilkes'
);
INSERT INTO CWMS_COUNTY VALUES (
	37195,
	'195',
	37,
	'Wilson'
);
INSERT INTO CWMS_COUNTY VALUES (
	37197,
	'197',
	37,
	'Yadkin'
);
INSERT INTO CWMS_COUNTY VALUES (
	37199,
	'199',
	37,
	'Yancey'
);
INSERT INTO CWMS_COUNTY VALUES (
	38000,
	'000',
	38,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	38001,
	'001',
	38,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	38003,
	'003',
	38,
	'Barnes'
);
INSERT INTO CWMS_COUNTY VALUES (
	38005,
	'005',
	38,
	'Benson'
);
INSERT INTO CWMS_COUNTY VALUES (
	38007,
	'007',
	38,
	'Billings'
);
INSERT INTO CWMS_COUNTY VALUES (
	38009,
	'009',
	38,
	'Bottineau'
);
INSERT INTO CWMS_COUNTY VALUES (
	38011,
	'011',
	38,
	'Bowman'
);
INSERT INTO CWMS_COUNTY VALUES (
	38013,
	'013',
	38,
	'Burke'
);
INSERT INTO CWMS_COUNTY VALUES (
	38015,
	'015',
	38,
	'Burleigh'
);
INSERT INTO CWMS_COUNTY VALUES (
	38017,
	'017',
	38,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	38019,
	'019',
	38,
	'Cavalier'
);
INSERT INTO CWMS_COUNTY VALUES (
	38021,
	'021',
	38,
	'Dickey'
);
INSERT INTO CWMS_COUNTY VALUES (
	38023,
	'023',
	38,
	'Divide'
);
INSERT INTO CWMS_COUNTY VALUES (
	38025,
	'025',
	38,
	'Dunn'
);
INSERT INTO CWMS_COUNTY VALUES (
	38027,
	'027',
	38,
	'Eddy'
);
INSERT INTO CWMS_COUNTY VALUES (
	38029,
	'029',
	38,
	'Emmons'
);
INSERT INTO CWMS_COUNTY VALUES (
	38031,
	'031',
	38,
	'Foster'
);
INSERT INTO CWMS_COUNTY VALUES (
	38033,
	'033',
	38,
	'Golden Valley'
);
INSERT INTO CWMS_COUNTY VALUES (
	38035,
	'035',
	38,
	'Grand Forks'
);
INSERT INTO CWMS_COUNTY VALUES (
	38037,
	'037',
	38,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	38039,
	'039',
	38,
	'Griggs'
);
INSERT INTO CWMS_COUNTY VALUES (
	38041,
	'041',
	38,
	'Hettinger'
);
INSERT INTO CWMS_COUNTY VALUES (
	38043,
	'043',
	38,
	'Kidder'
);
INSERT INTO CWMS_COUNTY VALUES (
	38045,
	'045',
	38,
	'La Moure'
);
INSERT INTO CWMS_COUNTY VALUES (
	38047,
	'047',
	38,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	38049,
	'049',
	38,
	'McHenry'
);
INSERT INTO CWMS_COUNTY VALUES (
	38051,
	'051',
	38,
	'McIntosh'
);
INSERT INTO CWMS_COUNTY VALUES (
	38053,
	'053',
	38,
	'McKenzie'
);
INSERT INTO CWMS_COUNTY VALUES (
	38055,
	'055',
	38,
	'McLean'
);
INSERT INTO CWMS_COUNTY VALUES (
	38057,
	'057',
	38,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	38059,
	'059',
	38,
	'Morton'
);
INSERT INTO CWMS_COUNTY VALUES (
	38061,
	'061',
	38,
	'Mountrial'
);
INSERT INTO CWMS_COUNTY VALUES (
	38063,
	'063',
	38,
	'Nelson'
);
INSERT INTO CWMS_COUNTY VALUES (
	38065,
	'065',
	38,
	'Oliver'
);
INSERT INTO CWMS_COUNTY VALUES (
	38067,
	'067',
	38,
	'Pembina'
);
INSERT INTO CWMS_COUNTY VALUES (
	38069,
	'069',
	38,
	'Pierce'
);
INSERT INTO CWMS_COUNTY VALUES (
	38071,
	'071',
	38,
	'Ramsey'
);
INSERT INTO CWMS_COUNTY VALUES (
	38073,
	'073',
	38,
	'Ransom'
);
INSERT INTO CWMS_COUNTY VALUES (
	38075,
	'075',
	38,
	'Renville'
);
INSERT INTO CWMS_COUNTY VALUES (
	38077,
	'077',
	38,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	38079,
	'079',
	38,
	'Rolette'
);
INSERT INTO CWMS_COUNTY VALUES (
	38081,
	'081',
	38,
	'Sargent'
);
INSERT INTO CWMS_COUNTY VALUES (
	38083,
	'083',
	38,
	'Sheridan'
);
INSERT INTO CWMS_COUNTY VALUES (
	38085,
	'085',
	38,
	'Sioux'
);
INSERT INTO CWMS_COUNTY VALUES (
	38087,
	'087',
	38,
	'Slope'
);
INSERT INTO CWMS_COUNTY VALUES (
	38089,
	'089',
	38,
	'Stark'
);
INSERT INTO CWMS_COUNTY VALUES (
	38091,
	'091',
	38,
	'Steele'
);
INSERT INTO CWMS_COUNTY VALUES (
	38093,
	'093',
	38,
	'Stutsman'
);
INSERT INTO CWMS_COUNTY VALUES (
	38095,
	'095',
	38,
	'Towner'
);
INSERT INTO CWMS_COUNTY VALUES (
	38097,
	'097',
	38,
	'Traill'
);
INSERT INTO CWMS_COUNTY VALUES (
	38099,
	'099',
	38,
	'Walsh'
);
INSERT INTO CWMS_COUNTY VALUES (
	38101,
	'101',
	38,
	'Ward'
);
INSERT INTO CWMS_COUNTY VALUES (
	38103,
	'103',
	38,
	'Wells'
);
INSERT INTO CWMS_COUNTY VALUES (
	38105,
	'105',
	38,
	'Williams'
);
INSERT INTO CWMS_COUNTY VALUES (
	39000,
	'000',
	39,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	39001,
	'001',
	39,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	39003,
	'003',
	39,
	'Allen'
);
INSERT INTO CWMS_COUNTY VALUES (
	39005,
	'005',
	39,
	'Ashland'
);
INSERT INTO CWMS_COUNTY VALUES (
	39007,
	'007',
	39,
	'Ashtabula'
);
INSERT INTO CWMS_COUNTY VALUES (
	39009,
	'009',
	39,
	'Athens'
);
INSERT INTO CWMS_COUNTY VALUES (
	39011,
	'011',
	39,
	'Auglaize'
);
INSERT INTO CWMS_COUNTY VALUES (
	39013,
	'013',
	39,
	'Belmont'
);
INSERT INTO CWMS_COUNTY VALUES (
	39015,
	'015',
	39,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	39017,
	'017',
	39,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	39019,
	'019',
	39,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	39021,
	'021',
	39,
	'Champaign'
);
INSERT INTO CWMS_COUNTY VALUES (
	39023,
	'023',
	39,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	39025,
	'025',
	39,
	'Clermont'
);
INSERT INTO CWMS_COUNTY VALUES (
	39027,
	'027',
	39,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	39029,
	'029',
	39,
	'Columbiana'
);
INSERT INTO CWMS_COUNTY VALUES (
	39031,
	'031',
	39,
	'Coshocton'
);
INSERT INTO CWMS_COUNTY VALUES (
	39033,
	'033',
	39,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	39035,
	'035',
	39,
	'Cuyahoga'
);
INSERT INTO CWMS_COUNTY VALUES (
	39037,
	'037',
	39,
	'Darke'
);
INSERT INTO CWMS_COUNTY VALUES (
	39039,
	'039',
	39,
	'Defiance'
);
INSERT INTO CWMS_COUNTY VALUES (
	39041,
	'041',
	39,
	'Delaware'
);
INSERT INTO CWMS_COUNTY VALUES (
	39043,
	'043',
	39,
	'Erie'
);
INSERT INTO CWMS_COUNTY VALUES (
	39045,
	'045',
	39,
	'Fairfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	39047,
	'047',
	39,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	39049,
	'049',
	39,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	39051,
	'051',
	39,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	39053,
	'053',
	39,
	'Gallia'
);
INSERT INTO CWMS_COUNTY VALUES (
	39055,
	'055',
	39,
	'Geauga'
);
INSERT INTO CWMS_COUNTY VALUES (
	39057,
	'057',
	39,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	39059,
	'059',
	39,
	'Guernsey'
);
INSERT INTO CWMS_COUNTY VALUES (
	39061,
	'061',
	39,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	39063,
	'063',
	39,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	39065,
	'065',
	39,
	'Hardin'
);
INSERT INTO CWMS_COUNTY VALUES (
	39067,
	'067',
	39,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	39069,
	'069',
	39,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	39071,
	'071',
	39,
	'Highland'
);
INSERT INTO CWMS_COUNTY VALUES (
	39073,
	'073',
	39,
	'Hocking'
);
INSERT INTO CWMS_COUNTY VALUES (
	39075,
	'075',
	39,
	'Holmes'
);
INSERT INTO CWMS_COUNTY VALUES (
	39077,
	'077',
	39,
	'Huron'
);
INSERT INTO CWMS_COUNTY VALUES (
	39079,
	'079',
	39,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	39081,
	'081',
	39,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	39083,
	'083',
	39,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	39085,
	'085',
	39,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	39087,
	'087',
	39,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	39089,
	'089',
	39,
	'Licking'
);
INSERT INTO CWMS_COUNTY VALUES (
	39091,
	'091',
	39,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	39093,
	'093',
	39,
	'Lorain'
);
INSERT INTO CWMS_COUNTY VALUES (
	39095,
	'095',
	39,
	'Lucas'
);
INSERT INTO CWMS_COUNTY VALUES (
	39097,
	'097',
	39,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	39099,
	'099',
	39,
	'Mahoning'
);
INSERT INTO CWMS_COUNTY VALUES (
	39101,
	'101',
	39,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	39103,
	'103',
	39,
	'Medina'
);
INSERT INTO CWMS_COUNTY VALUES (
	39105,
	'105',
	39,
	'Meigs'
);
INSERT INTO CWMS_COUNTY VALUES (
	39107,
	'107',
	39,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	39109,
	'109',
	39,
	'Miami'
);
INSERT INTO CWMS_COUNTY VALUES (
	39111,
	'111',
	39,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	39113,
	'113',
	39,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	39115,
	'115',
	39,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	39117,
	'117',
	39,
	'Morrow'
);
INSERT INTO CWMS_COUNTY VALUES (
	39119,
	'119',
	39,
	'Muskingum'
);
INSERT INTO CWMS_COUNTY VALUES (
	39121,
	'121',
	39,
	'Noble'
);
INSERT INTO CWMS_COUNTY VALUES (
	39123,
	'123',
	39,
	'Ottawa'
);
INSERT INTO CWMS_COUNTY VALUES (
	39125,
	'125',
	39,
	'Paulding'
);
INSERT INTO CWMS_COUNTY VALUES (
	39127,
	'127',
	39,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	39129,
	'129',
	39,
	'Pickaway'
);
INSERT INTO CWMS_COUNTY VALUES (
	39131,
	'131',
	39,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	39133,
	'133',
	39,
	'Portage'
);
INSERT INTO CWMS_COUNTY VALUES (
	39135,
	'135',
	39,
	'Preble'
);
INSERT INTO CWMS_COUNTY VALUES (
	39137,
	'137',
	39,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	39139,
	'139',
	39,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	39141,
	'141',
	39,
	'Ross'
);
INSERT INTO CWMS_COUNTY VALUES (
	39143,
	'143',
	39,
	'Sandusky'
);
INSERT INTO CWMS_COUNTY VALUES (
	39145,
	'145',
	39,
	'Scioto'
);
INSERT INTO CWMS_COUNTY VALUES (
	39147,
	'147',
	39,
	'Seneca'
);
INSERT INTO CWMS_COUNTY VALUES (
	39149,
	'149',
	39,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	39151,
	'151',
	39,
	'Stark'
);
INSERT INTO CWMS_COUNTY VALUES (
	39153,
	'153',
	39,
	'Summit'
);
INSERT INTO CWMS_COUNTY VALUES (
	39155,
	'155',
	39,
	'Trumbull'
);
INSERT INTO CWMS_COUNTY VALUES (
	39157,
	'157',
	39,
	'Tuscarawas'
);
INSERT INTO CWMS_COUNTY VALUES (
	39159,
	'159',
	39,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	39161,
	'161',
	39,
	'Van Wert'
);
INSERT INTO CWMS_COUNTY VALUES (
	39163,
	'163',
	39,
	'Vinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	39165,
	'165',
	39,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	39167,
	'167',
	39,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	39169,
	'169',
	39,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	39171,
	'171',
	39,
	'Williams'
);
INSERT INTO CWMS_COUNTY VALUES (
	39173,
	'173',
	39,
	'Wood'
);
INSERT INTO CWMS_COUNTY VALUES (
	39175,
	'175',
	39,
	'Wyandot'
);
INSERT INTO CWMS_COUNTY VALUES (
	40000,
	'000',
	40,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	40001,
	'001',
	40,
	'Adair'
);
INSERT INTO CWMS_COUNTY VALUES (
	40003,
	'003',
	40,
	'Alfalfa'
);
INSERT INTO CWMS_COUNTY VALUES (
	40005,
	'005',
	40,
	'Atoka'
);
INSERT INTO CWMS_COUNTY VALUES (
	40007,
	'007',
	40,
	'Beaver'
);
INSERT INTO CWMS_COUNTY VALUES (
	40009,
	'009',
	40,
	'Beckham'
);
INSERT INTO CWMS_COUNTY VALUES (
	40011,
	'011',
	40,
	'Blaine'
);
INSERT INTO CWMS_COUNTY VALUES (
	40013,
	'013',
	40,
	'Bryan'
);
INSERT INTO CWMS_COUNTY VALUES (
	40015,
	'015',
	40,
	'Caddo'
);
INSERT INTO CWMS_COUNTY VALUES (
	40017,
	'017',
	40,
	'Canadian'
);
INSERT INTO CWMS_COUNTY VALUES (
	40019,
	'019',
	40,
	'Carter'
);
INSERT INTO CWMS_COUNTY VALUES (
	40021,
	'021',
	40,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	40023,
	'023',
	40,
	'Choctaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	40025,
	'025',
	40,
	'Cimarron'
);
INSERT INTO CWMS_COUNTY VALUES (
	40027,
	'027',
	40,
	'Cleveland'
);
INSERT INTO CWMS_COUNTY VALUES (
	40029,
	'029',
	40,
	'Coal'
);
INSERT INTO CWMS_COUNTY VALUES (
	40031,
	'031',
	40,
	'Comanche'
);
INSERT INTO CWMS_COUNTY VALUES (
	40033,
	'033',
	40,
	'Cotton'
);
INSERT INTO CWMS_COUNTY VALUES (
	40035,
	'035',
	40,
	'Craig'
);
INSERT INTO CWMS_COUNTY VALUES (
	40037,
	'037',
	40,
	'Creek'
);
INSERT INTO CWMS_COUNTY VALUES (
	40039,
	'039',
	40,
	'Custer'
);
INSERT INTO CWMS_COUNTY VALUES (
	40041,
	'041',
	40,
	'Delaware'
);
INSERT INTO CWMS_COUNTY VALUES (
	40043,
	'043',
	40,
	'Dewey'
);
INSERT INTO CWMS_COUNTY VALUES (
	40045,
	'045',
	40,
	'Ellis'
);
INSERT INTO CWMS_COUNTY VALUES (
	40047,
	'047',
	40,
	'Garfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	40049,
	'049',
	40,
	'Garvin'
);
INSERT INTO CWMS_COUNTY VALUES (
	40051,
	'051',
	40,
	'Grady'
);
INSERT INTO CWMS_COUNTY VALUES (
	40053,
	'053',
	40,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	40055,
	'055',
	40,
	'Greer'
);
INSERT INTO CWMS_COUNTY VALUES (
	40057,
	'057',
	40,
	'Harmon'
);
INSERT INTO CWMS_COUNTY VALUES (
	40059,
	'059',
	40,
	'Harper'
);
INSERT INTO CWMS_COUNTY VALUES (
	40061,
	'061',
	40,
	'Haskell'
);
INSERT INTO CWMS_COUNTY VALUES (
	40063,
	'063',
	40,
	'Hughes'
);
INSERT INTO CWMS_COUNTY VALUES (
	40065,
	'065',
	40,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	40067,
	'067',
	40,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	40069,
	'069',
	40,
	'Johnston'
);
INSERT INTO CWMS_COUNTY VALUES (
	40071,
	'071',
	40,
	'Kay'
);
INSERT INTO CWMS_COUNTY VALUES (
	40073,
	'073',
	40,
	'Kingfisher'
);
INSERT INTO CWMS_COUNTY VALUES (
	40075,
	'075',
	40,
	'Kiowa'
);
INSERT INTO CWMS_COUNTY VALUES (
	40077,
	'077',
	40,
	'Latimer'
);
INSERT INTO CWMS_COUNTY VALUES (
	40079,
	'079',
	40,
	'Le Flore'
);
INSERT INTO CWMS_COUNTY VALUES (
	40081,
	'081',
	40,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	40083,
	'083',
	40,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	40085,
	'085',
	40,
	'Love'
);
INSERT INTO CWMS_COUNTY VALUES (
	40087,
	'087',
	40,
	'McClain'
);
INSERT INTO CWMS_COUNTY VALUES (
	40089,
	'089',
	40,
	'McCurtain'
);
INSERT INTO CWMS_COUNTY VALUES (
	40091,
	'091',
	40,
	'McIntosh'
);
INSERT INTO CWMS_COUNTY VALUES (
	40093,
	'093',
	40,
	'Major'
);
INSERT INTO CWMS_COUNTY VALUES (
	40095,
	'095',
	40,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	40097,
	'097',
	40,
	'Mayes'
);
INSERT INTO CWMS_COUNTY VALUES (
	40099,
	'099',
	40,
	'Murray'
);
INSERT INTO CWMS_COUNTY VALUES (
	40101,
	'101',
	40,
	'Muskogee'
);
INSERT INTO CWMS_COUNTY VALUES (
	40103,
	'103',
	40,
	'Noble'
);
INSERT INTO CWMS_COUNTY VALUES (
	40105,
	'105',
	40,
	'Nowata'
);
INSERT INTO CWMS_COUNTY VALUES (
	40107,
	'107',
	40,
	'Okfuskee'
);
INSERT INTO CWMS_COUNTY VALUES (
	40109,
	'109',
	40,
	'Oklahoma'
);
INSERT INTO CWMS_COUNTY VALUES (
	40111,
	'111',
	40,
	'Okmulgee'
);
INSERT INTO CWMS_COUNTY VALUES (
	40113,
	'113',
	40,
	'Osage'
);
INSERT INTO CWMS_COUNTY VALUES (
	40115,
	'115',
	40,
	'Ottawa'
);
INSERT INTO CWMS_COUNTY VALUES (
	40117,
	'117',
	40,
	'Pawnee'
);
INSERT INTO CWMS_COUNTY VALUES (
	40119,
	'119',
	40,
	'Payne'
);
INSERT INTO CWMS_COUNTY VALUES (
	40121,
	'121',
	40,
	'Pittsburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	40123,
	'123',
	40,
	'Pontotoc'
);
INSERT INTO CWMS_COUNTY VALUES (
	40125,
	'125',
	40,
	'Pottawatomie'
);
INSERT INTO CWMS_COUNTY VALUES (
	40127,
	'127',
	40,
	'Pushmataha'
);
INSERT INTO CWMS_COUNTY VALUES (
	40129,
	'129',
	40,
	'Roger Mills'
);
INSERT INTO CWMS_COUNTY VALUES (
	40131,
	'131',
	40,
	'Rogers'
);
INSERT INTO CWMS_COUNTY VALUES (
	40133,
	'133',
	40,
	'Seminole'
);
INSERT INTO CWMS_COUNTY VALUES (
	40135,
	'135',
	40,
	'Sequoyah'
);
INSERT INTO CWMS_COUNTY VALUES (
	40137,
	'137',
	40,
	'Stephens'
);
INSERT INTO CWMS_COUNTY VALUES (
	40139,
	'139',
	40,
	'Texas'
);
INSERT INTO CWMS_COUNTY VALUES (
	40141,
	'141',
	40,
	'Tillman'
);
INSERT INTO CWMS_COUNTY VALUES (
	40143,
	'143',
	40,
	'Tulsa'
);
INSERT INTO CWMS_COUNTY VALUES (
	40145,
	'145',
	40,
	'Wagoner'
);
INSERT INTO CWMS_COUNTY VALUES (
	40147,
	'147',
	40,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	40149,
	'149',
	40,
	'Washita'
);
INSERT INTO CWMS_COUNTY VALUES (
	40151,
	'151',
	40,
	'Woods'
);
INSERT INTO CWMS_COUNTY VALUES (
	40153,
	'153',
	40,
	'Woodward'
);
INSERT INTO CWMS_COUNTY VALUES (
	41000,
	'000',
	41,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	41001,
	'001',
	41,
	'Baker'
);
INSERT INTO CWMS_COUNTY VALUES (
	41003,
	'003',
	41,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	41005,
	'005',
	41,
	'Clackamas'
);
INSERT INTO CWMS_COUNTY VALUES (
	41007,
	'007',
	41,
	'Clatsop'
);
INSERT INTO CWMS_COUNTY VALUES (
	41009,
	'009',
	41,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	41011,
	'011',
	41,
	'Coos'
);
INSERT INTO CWMS_COUNTY VALUES (
	41013,
	'013',
	41,
	'Crook'
);
INSERT INTO CWMS_COUNTY VALUES (
	41015,
	'015',
	41,
	'Curry'
);
INSERT INTO CWMS_COUNTY VALUES (
	41017,
	'017',
	41,
	'Deschutes'
);
INSERT INTO CWMS_COUNTY VALUES (
	41019,
	'019',
	41,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	41021,
	'021',
	41,
	'Gilliam'
);
INSERT INTO CWMS_COUNTY VALUES (
	41023,
	'023',
	41,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	41025,
	'025',
	41,
	'Harney'
);
INSERT INTO CWMS_COUNTY VALUES (
	41027,
	'027',
	41,
	'Hood River'
);
INSERT INTO CWMS_COUNTY VALUES (
	41029,
	'029',
	41,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	41031,
	'031',
	41,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	41033,
	'033',
	41,
	'Josephine'
);
INSERT INTO CWMS_COUNTY VALUES (
	41035,
	'035',
	41,
	'Klamath'
);
INSERT INTO CWMS_COUNTY VALUES (
	41037,
	'037',
	41,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	41039,
	'039',
	41,
	'Lane'
);
INSERT INTO CWMS_COUNTY VALUES (
	41041,
	'041',
	41,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	41043,
	'043',
	41,
	'Linn'
);
INSERT INTO CWMS_COUNTY VALUES (
	41045,
	'045',
	41,
	'Malheur'
);
INSERT INTO CWMS_COUNTY VALUES (
	41047,
	'047',
	41,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	41049,
	'049',
	41,
	'Morrow'
);
INSERT INTO CWMS_COUNTY VALUES (
	41051,
	'051',
	41,
	'Multnomah'
);
INSERT INTO CWMS_COUNTY VALUES (
	41053,
	'053',
	41,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	41055,
	'055',
	41,
	'Sherman'
);
INSERT INTO CWMS_COUNTY VALUES (
	41057,
	'057',
	41,
	'Tillamook'
);
INSERT INTO CWMS_COUNTY VALUES (
	41059,
	'059',
	41,
	'Umatilla'
);
INSERT INTO CWMS_COUNTY VALUES (
	41061,
	'061',
	41,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	41063,
	'063',
	41,
	'Wallowa'
);
INSERT INTO CWMS_COUNTY VALUES (
	41065,
	'065',
	41,
	'Wasco'
);
INSERT INTO CWMS_COUNTY VALUES (
	41067,
	'067',
	41,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	41069,
	'069',
	41,
	'Wheeler'
);
INSERT INTO CWMS_COUNTY VALUES (
	41071,
	'071',
	41,
	'Yamhill'
);
INSERT INTO CWMS_COUNTY VALUES (
	42000,
	'000',
	42,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	42001,
	'001',
	42,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	42003,
	'003',
	42,
	'Allegheny'
);
INSERT INTO CWMS_COUNTY VALUES (
	42005,
	'005',
	42,
	'Armstrong'
);
INSERT INTO CWMS_COUNTY VALUES (
	42007,
	'007',
	42,
	'Beaver'
);
INSERT INTO CWMS_COUNTY VALUES (
	42009,
	'009',
	42,
	'Bedford'
);
INSERT INTO CWMS_COUNTY VALUES (
	42011,
	'011',
	42,
	'Berks'
);
INSERT INTO CWMS_COUNTY VALUES (
	42013,
	'013',
	42,
	'Blair'
);
INSERT INTO CWMS_COUNTY VALUES (
	42015,
	'015',
	42,
	'Bradford'
);
INSERT INTO CWMS_COUNTY VALUES (
	42017,
	'017',
	42,
	'Bucks'
);
INSERT INTO CWMS_COUNTY VALUES (
	42019,
	'019',
	42,
	'Butler'
);
INSERT INTO CWMS_COUNTY VALUES (
	42021,
	'021',
	42,
	'Cambria'
);
INSERT INTO CWMS_COUNTY VALUES (
	42023,
	'023',
	42,
	'Cameron'
);
INSERT INTO CWMS_COUNTY VALUES (
	42025,
	'025',
	42,
	'Carbon'
);
INSERT INTO CWMS_COUNTY VALUES (
	42027,
	'027',
	42,
	'Centre'
);
INSERT INTO CWMS_COUNTY VALUES (
	42029,
	'029',
	42,
	'Chester'
);
INSERT INTO CWMS_COUNTY VALUES (
	42031,
	'031',
	42,
	'Clarion'
);
INSERT INTO CWMS_COUNTY VALUES (
	42033,
	'033',
	42,
	'Clearfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	42035,
	'035',
	42,
	'Clinton'
);
INSERT INTO CWMS_COUNTY VALUES (
	42037,
	'037',
	42,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	42039,
	'039',
	42,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	42041,
	'041',
	42,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	42043,
	'043',
	42,
	'Dauphin'
);
INSERT INTO CWMS_COUNTY VALUES (
	42045,
	'045',
	42,
	'Delaware'
);
INSERT INTO CWMS_COUNTY VALUES (
	42047,
	'047',
	42,
	'Elk'
);
INSERT INTO CWMS_COUNTY VALUES (
	42049,
	'049',
	42,
	'Erie'
);
INSERT INTO CWMS_COUNTY VALUES (
	42051,
	'051',
	42,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	42053,
	'053',
	42,
	'Forest'
);
INSERT INTO CWMS_COUNTY VALUES (
	42055,
	'055',
	42,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	42057,
	'057',
	42,
	'Fulton'
);
INSERT INTO CWMS_COUNTY VALUES (
	42059,
	'059',
	42,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	42061,
	'061',
	42,
	'Huntingdon'
);
INSERT INTO CWMS_COUNTY VALUES (
	42063,
	'063',
	42,
	'Indiana'
);
INSERT INTO CWMS_COUNTY VALUES (
	42065,
	'065',
	42,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	42067,
	'067',
	42,
	'Juniata'
);
INSERT INTO CWMS_COUNTY VALUES (
	42069,
	'069',
	42,
	'Lackawanna'
);
INSERT INTO CWMS_COUNTY VALUES (
	42071,
	'071',
	42,
	'Lancaster'
);
INSERT INTO CWMS_COUNTY VALUES (
	42073,
	'073',
	42,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	42075,
	'075',
	42,
	'Lebanon'
);
INSERT INTO CWMS_COUNTY VALUES (
	42077,
	'077',
	42,
	'Lehigh'
);
INSERT INTO CWMS_COUNTY VALUES (
	42079,
	'079',
	42,
	'Luzerne'
);
INSERT INTO CWMS_COUNTY VALUES (
	42081,
	'081',
	42,
	'Lycoming'
);
INSERT INTO CWMS_COUNTY VALUES (
	42083,
	'083',
	42,
	'McKean'
);
INSERT INTO CWMS_COUNTY VALUES (
	42085,
	'085',
	42,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	42087,
	'087',
	42,
	'Mifflin'
);
INSERT INTO CWMS_COUNTY VALUES (
	42089,
	'089',
	42,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	42091,
	'091',
	42,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	42093,
	'093',
	42,
	'Montour'
);
INSERT INTO CWMS_COUNTY VALUES (
	42095,
	'095',
	42,
	'Northampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	42097,
	'097',
	42,
	'Northumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	42099,
	'099',
	42,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	42101,
	'101',
	42,
	'Philadelphia'
);
INSERT INTO CWMS_COUNTY VALUES (
	42103,
	'103',
	42,
	'Pike'
);
INSERT INTO CWMS_COUNTY VALUES (
	42105,
	'105',
	42,
	'Potter'
);
INSERT INTO CWMS_COUNTY VALUES (
	42107,
	'107',
	42,
	'Schuylkill'
);
INSERT INTO CWMS_COUNTY VALUES (
	42109,
	'109',
	42,
	'Snyder'
);
INSERT INTO CWMS_COUNTY VALUES (
	42111,
	'111',
	42,
	'Somerset'
);
INSERT INTO CWMS_COUNTY VALUES (
	42113,
	'113',
	42,
	'Sullivan'
);
INSERT INTO CWMS_COUNTY VALUES (
	42115,
	'115',
	42,
	'Susquehanna'
);
INSERT INTO CWMS_COUNTY VALUES (
	42117,
	'117',
	42,
	'Tioga'
);
INSERT INTO CWMS_COUNTY VALUES (
	42119,
	'119',
	42,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	42121,
	'121',
	42,
	'Venango'
);
INSERT INTO CWMS_COUNTY VALUES (
	42123,
	'123',
	42,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	42125,
	'125',
	42,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	42127,
	'127',
	42,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	42129,
	'129',
	42,
	'Westmoreland'
);
INSERT INTO CWMS_COUNTY VALUES (
	42131,
	'131',
	42,
	'Wyoming'
);
INSERT INTO CWMS_COUNTY VALUES (
	42133,
	'133',
	42,
	'York'
);
INSERT INTO CWMS_COUNTY VALUES (
	44000,
	'000',
	44,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	44001,
	'001',
	44,
	'Bristol'
);
INSERT INTO CWMS_COUNTY VALUES (
	44003,
	'003',
	44,
	'Kent'
);
INSERT INTO CWMS_COUNTY VALUES (
	44005,
	'005',
	44,
	'Newport'
);
INSERT INTO CWMS_COUNTY VALUES (
	44007,
	'007',
	44,
	'Providence'
);
INSERT INTO CWMS_COUNTY VALUES (
	44009,
	'009',
	44,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	45000,
	'000',
	45,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	45001,
	'001',
	45,
	'Abbeville'
);
INSERT INTO CWMS_COUNTY VALUES (
	45003,
	'003',
	45,
	'Aiken'
);
INSERT INTO CWMS_COUNTY VALUES (
	45005,
	'005',
	45,
	'Allendale'
);
INSERT INTO CWMS_COUNTY VALUES (
	45007,
	'007',
	45,
	'Anderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	45009,
	'009',
	45,
	'Bamberg'
);
INSERT INTO CWMS_COUNTY VALUES (
	45011,
	'011',
	45,
	'Barnwell'
);
INSERT INTO CWMS_COUNTY VALUES (
	45013,
	'013',
	45,
	'Beaufort'
);
INSERT INTO CWMS_COUNTY VALUES (
	45015,
	'015',
	45,
	'Berkeley'
);
INSERT INTO CWMS_COUNTY VALUES (
	45017,
	'017',
	45,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	45019,
	'019',
	45,
	'Charleston'
);
INSERT INTO CWMS_COUNTY VALUES (
	45021,
	'021',
	45,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	45023,
	'023',
	45,
	'Chester'
);
INSERT INTO CWMS_COUNTY VALUES (
	45025,
	'025',
	45,
	'Chesterfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	45027,
	'027',
	45,
	'Clarendon'
);
INSERT INTO CWMS_COUNTY VALUES (
	45029,
	'029',
	45,
	'Colleton'
);
INSERT INTO CWMS_COUNTY VALUES (
	45031,
	'031',
	45,
	'Darlington'
);
INSERT INTO CWMS_COUNTY VALUES (
	45033,
	'033',
	45,
	'Dillon'
);
INSERT INTO CWMS_COUNTY VALUES (
	45035,
	'035',
	45,
	'Dorchester'
);
INSERT INTO CWMS_COUNTY VALUES (
	45037,
	'037',
	45,
	'Edgefield'
);
INSERT INTO CWMS_COUNTY VALUES (
	45039,
	'039',
	45,
	'Fairfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	45041,
	'041',
	45,
	'Florence'
);
INSERT INTO CWMS_COUNTY VALUES (
	45043,
	'043',
	45,
	'Georgetown'
);
INSERT INTO CWMS_COUNTY VALUES (
	45045,
	'045',
	45,
	'Greenville'
);
INSERT INTO CWMS_COUNTY VALUES (
	45047,
	'047',
	45,
	'Greenwood'
);
INSERT INTO CWMS_COUNTY VALUES (
	45049,
	'049',
	45,
	'Hampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	45051,
	'051',
	45,
	'Horry'
);
INSERT INTO CWMS_COUNTY VALUES (
	45053,
	'053',
	45,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	45055,
	'055',
	45,
	'Kershaw'
);
INSERT INTO CWMS_COUNTY VALUES (
	45057,
	'057',
	45,
	'Lancaster'
);
INSERT INTO CWMS_COUNTY VALUES (
	45059,
	'059',
	45,
	'Laurens'
);
INSERT INTO CWMS_COUNTY VALUES (
	45061,
	'061',
	45,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	45063,
	'063',
	45,
	'Lexington'
);
INSERT INTO CWMS_COUNTY VALUES (
	45065,
	'065',
	45,
	'McCormick'
);
INSERT INTO CWMS_COUNTY VALUES (
	45067,
	'067',
	45,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	45069,
	'069',
	45,
	'Marlboro'
);
INSERT INTO CWMS_COUNTY VALUES (
	45071,
	'071',
	45,
	'Newberry'
);
INSERT INTO CWMS_COUNTY VALUES (
	45073,
	'073',
	45,
	'Oconee'
);
INSERT INTO CWMS_COUNTY VALUES (
	45075,
	'075',
	45,
	'Orangeburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	45077,
	'077',
	45,
	'Pickens'
);
INSERT INTO CWMS_COUNTY VALUES (
	45079,
	'079',
	45,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	45081,
	'081',
	45,
	'Saluda'
);
INSERT INTO CWMS_COUNTY VALUES (
	45083,
	'083',
	45,
	'Spartanburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	45085,
	'085',
	45,
	'Sumter'
);
INSERT INTO CWMS_COUNTY VALUES (
	45087,
	'087',
	45,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	45089,
	'089',
	45,
	'Williamsburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	45091,
	'091',
	45,
	'York'
);
INSERT INTO CWMS_COUNTY VALUES (
	46000,
	'000',
	46,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	46003,
	'003',
	46,
	'Aurora'
);
INSERT INTO CWMS_COUNTY VALUES (
	46005,
	'005',
	46,
	'Beadle'
);
INSERT INTO CWMS_COUNTY VALUES (
	46007,
	'007',
	46,
	'Bennett'
);
INSERT INTO CWMS_COUNTY VALUES (
	46009,
	'009',
	46,
	'Bon Homme'
);
INSERT INTO CWMS_COUNTY VALUES (
	46011,
	'011',
	46,
	'Brookings'
);
INSERT INTO CWMS_COUNTY VALUES (
	46013,
	'013',
	46,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	46015,
	'015',
	46,
	'Brule'
);
INSERT INTO CWMS_COUNTY VALUES (
	46017,
	'017',
	46,
	'Buffalo'
);
INSERT INTO CWMS_COUNTY VALUES (
	46019,
	'019',
	46,
	'Butte'
);
INSERT INTO CWMS_COUNTY VALUES (
	46021,
	'021',
	46,
	'Campbell'
);
INSERT INTO CWMS_COUNTY VALUES (
	46023,
	'023',
	46,
	'Charles Mix'
);
INSERT INTO CWMS_COUNTY VALUES (
	46025,
	'025',
	46,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	46027,
	'027',
	46,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	46029,
	'029',
	46,
	'Codington'
);
INSERT INTO CWMS_COUNTY VALUES (
	46031,
	'031',
	46,
	'Corson'
);
INSERT INTO CWMS_COUNTY VALUES (
	46033,
	'033',
	46,
	'Custer'
);
INSERT INTO CWMS_COUNTY VALUES (
	46035,
	'035',
	46,
	'Davison'
);
INSERT INTO CWMS_COUNTY VALUES (
	46037,
	'037',
	46,
	'Day'
);
INSERT INTO CWMS_COUNTY VALUES (
	46039,
	'039',
	46,
	'Deuel'
);
INSERT INTO CWMS_COUNTY VALUES (
	46041,
	'041',
	46,
	'Dewey'
);
INSERT INTO CWMS_COUNTY VALUES (
	46043,
	'043',
	46,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	46045,
	'045',
	46,
	'Edmunds'
);
INSERT INTO CWMS_COUNTY VALUES (
	46047,
	'047',
	46,
	'Fall River'
);
INSERT INTO CWMS_COUNTY VALUES (
	46049,
	'049',
	46,
	'Faulk'
);
INSERT INTO CWMS_COUNTY VALUES (
	46051,
	'051',
	46,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	46053,
	'053',
	46,
	'Gregory'
);
INSERT INTO CWMS_COUNTY VALUES (
	46055,
	'055',
	46,
	'Haakon'
);
INSERT INTO CWMS_COUNTY VALUES (
	46057,
	'057',
	46,
	'Hamlin'
);
INSERT INTO CWMS_COUNTY VALUES (
	46059,
	'059',
	46,
	'Hand'
);
INSERT INTO CWMS_COUNTY VALUES (
	46061,
	'061',
	46,
	'Hanson'
);
INSERT INTO CWMS_COUNTY VALUES (
	46063,
	'063',
	46,
	'Harding'
);
INSERT INTO CWMS_COUNTY VALUES (
	46065,
	'065',
	46,
	'Hughes'
);
INSERT INTO CWMS_COUNTY VALUES (
	46067,
	'067',
	46,
	'Hutchinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	46069,
	'069',
	46,
	'Hyde'
);
INSERT INTO CWMS_COUNTY VALUES (
	46071,
	'071',
	46,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	46073,
	'073',
	46,
	'Jerauld'
);
INSERT INTO CWMS_COUNTY VALUES (
	46075,
	'075',
	46,
	'Jones'
);
INSERT INTO CWMS_COUNTY VALUES (
	46077,
	'077',
	46,
	'Kingsbury'
);
INSERT INTO CWMS_COUNTY VALUES (
	46079,
	'079',
	46,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	46081,
	'081',
	46,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	46083,
	'083',
	46,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	46085,
	'085',
	46,
	'Lyman'
);
INSERT INTO CWMS_COUNTY VALUES (
	46087,
	'087',
	46,
	'McCook'
);
INSERT INTO CWMS_COUNTY VALUES (
	46089,
	'089',
	46,
	'McPherson'
);
INSERT INTO CWMS_COUNTY VALUES (
	46091,
	'091',
	46,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	46093,
	'093',
	46,
	'Meade'
);
INSERT INTO CWMS_COUNTY VALUES (
	46095,
	'095',
	46,
	'Mellette'
);
INSERT INTO CWMS_COUNTY VALUES (
	46097,
	'097',
	46,
	'Miner'
);
INSERT INTO CWMS_COUNTY VALUES (
	46099,
	'099',
	46,
	'Minnehaha'
);
INSERT INTO CWMS_COUNTY VALUES (
	46101,
	'101',
	46,
	'Moody'
);
INSERT INTO CWMS_COUNTY VALUES (
	46103,
	'103',
	46,
	'Pennington'
);
INSERT INTO CWMS_COUNTY VALUES (
	46105,
	'105',
	46,
	'Perkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	46107,
	'107',
	46,
	'Potter'
);
INSERT INTO CWMS_COUNTY VALUES (
	46109,
	'109',
	46,
	'Roberts'
);
INSERT INTO CWMS_COUNTY VALUES (
	46111,
	'111',
	46,
	'Sanborn'
);
INSERT INTO CWMS_COUNTY VALUES (
	46113,
	'113',
	46,
	'Shannon'
);
INSERT INTO CWMS_COUNTY VALUES (
	46115,
	'115',
	46,
	'Spink'
);
INSERT INTO CWMS_COUNTY VALUES (
	46117,
	'117',
	46,
	'Stanley'
);
INSERT INTO CWMS_COUNTY VALUES (
	46119,
	'119',
	46,
	'Sully'
);
INSERT INTO CWMS_COUNTY VALUES (
	46121,
	'121',
	46,
	'Todd'
);
INSERT INTO CWMS_COUNTY VALUES (
	46123,
	'123',
	46,
	'Tripp'
);
INSERT INTO CWMS_COUNTY VALUES (
	46125,
	'125',
	46,
	'Turner'
);
INSERT INTO CWMS_COUNTY VALUES (
	46127,
	'127',
	46,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	46129,
	'129',
	46,
	'Walworth'
);
INSERT INTO CWMS_COUNTY VALUES (
	46135,
	'135',
	46,
	'Yankton'
);
INSERT INTO CWMS_COUNTY VALUES (
	46137,
	'137',
	46,
	'Ziebach'
);
INSERT INTO CWMS_COUNTY VALUES (
	47000,
	'000',
	47,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	47001,
	'001',
	47,
	'Anderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47003,
	'003',
	47,
	'Bedford'
);
INSERT INTO CWMS_COUNTY VALUES (
	47005,
	'005',
	47,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	47007,
	'007',
	47,
	'Bledsoe'
);
INSERT INTO CWMS_COUNTY VALUES (
	47009,
	'009',
	47,
	'Blount'
);
INSERT INTO CWMS_COUNTY VALUES (
	47011,
	'011',
	47,
	'Bradley'
);
INSERT INTO CWMS_COUNTY VALUES (
	47013,
	'013',
	47,
	'Campbell'
);
INSERT INTO CWMS_COUNTY VALUES (
	47015,
	'015',
	47,
	'Cannon'
);
INSERT INTO CWMS_COUNTY VALUES (
	47017,
	'017',
	47,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	47019,
	'019',
	47,
	'Carter'
);
INSERT INTO CWMS_COUNTY VALUES (
	47021,
	'021',
	47,
	'Cheatham'
);
INSERT INTO CWMS_COUNTY VALUES (
	47023,
	'023',
	47,
	'Chester'
);
INSERT INTO CWMS_COUNTY VALUES (
	47025,
	'025',
	47,
	'Claiborne'
);
INSERT INTO CWMS_COUNTY VALUES (
	47027,
	'027',
	47,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	47029,
	'029',
	47,
	'Cocke'
);
INSERT INTO CWMS_COUNTY VALUES (
	47031,
	'031',
	47,
	'Coffee'
);
INSERT INTO CWMS_COUNTY VALUES (
	47033,
	'033',
	47,
	'Crockett'
);
INSERT INTO CWMS_COUNTY VALUES (
	47035,
	'035',
	47,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	47037,
	'037',
	47,
	'Davidson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47039,
	'039',
	47,
	'Decatur'
);
INSERT INTO CWMS_COUNTY VALUES (
	47041,
	'041',
	47,
	'De Kalb'
);
INSERT INTO CWMS_COUNTY VALUES (
	47043,
	'043',
	47,
	'Dickson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47045,
	'045',
	47,
	'Dyer'
);
INSERT INTO CWMS_COUNTY VALUES (
	47047,
	'047',
	47,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	47049,
	'049',
	47,
	'Fentress'
);
INSERT INTO CWMS_COUNTY VALUES (
	47051,
	'051',
	47,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	47053,
	'053',
	47,
	'Gibson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47055,
	'055',
	47,
	'Giles'
);
INSERT INTO CWMS_COUNTY VALUES (
	47057,
	'057',
	47,
	'Grainger'
);
INSERT INTO CWMS_COUNTY VALUES (
	47059,
	'059',
	47,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	47061,
	'061',
	47,
	'Grundy'
);
INSERT INTO CWMS_COUNTY VALUES (
	47063,
	'063',
	47,
	'Hamblen'
);
INSERT INTO CWMS_COUNTY VALUES (
	47065,
	'065',
	47,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	47067,
	'067',
	47,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	47069,
	'069',
	47,
	'Hardeman'
);
INSERT INTO CWMS_COUNTY VALUES (
	47071,
	'071',
	47,
	'Hardin'
);
INSERT INTO CWMS_COUNTY VALUES (
	47073,
	'073',
	47,
	'Hawkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	47075,
	'075',
	47,
	'Haywood'
);
INSERT INTO CWMS_COUNTY VALUES (
	47077,
	'077',
	47,
	'Henderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47079,
	'079',
	47,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	47081,
	'081',
	47,
	'Hickman'
);
INSERT INTO CWMS_COUNTY VALUES (
	47083,
	'083',
	47,
	'Houston'
);
INSERT INTO CWMS_COUNTY VALUES (
	47085,
	'085',
	47,
	'Humphreys'
);
INSERT INTO CWMS_COUNTY VALUES (
	47087,
	'087',
	47,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47089,
	'089',
	47,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47091,
	'091',
	47,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47093,
	'093',
	47,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	47095,
	'095',
	47,
	'Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	47097,
	'097',
	47,
	'Lauderdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	47099,
	'099',
	47,
	'Lawrence'
);
INSERT INTO CWMS_COUNTY VALUES (
	47101,
	'101',
	47,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	47103,
	'103',
	47,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	47105,
	'105',
	47,
	'Loudon'
);
INSERT INTO CWMS_COUNTY VALUES (
	47107,
	'107',
	47,
	'McMinn'
);
INSERT INTO CWMS_COUNTY VALUES (
	47109,
	'109',
	47,
	'McNairy'
);
INSERT INTO CWMS_COUNTY VALUES (
	47111,
	'111',
	47,
	'Macon'
);
INSERT INTO CWMS_COUNTY VALUES (
	47113,
	'113',
	47,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	47115,
	'115',
	47,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	47117,
	'117',
	47,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	47119,
	'119',
	47,
	'Maury'
);
INSERT INTO CWMS_COUNTY VALUES (
	47121,
	'121',
	47,
	'Meigs'
);
INSERT INTO CWMS_COUNTY VALUES (
	47123,
	'123',
	47,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	47125,
	'125',
	47,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	47127,
	'127',
	47,
	'Moore'
);
INSERT INTO CWMS_COUNTY VALUES (
	47129,
	'129',
	47,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	47131,
	'131',
	47,
	'Obion'
);
INSERT INTO CWMS_COUNTY VALUES (
	47133,
	'133',
	47,
	'Overton'
);
INSERT INTO CWMS_COUNTY VALUES (
	47135,
	'135',
	47,
	'Perry'
);
INSERT INTO CWMS_COUNTY VALUES (
	47137,
	'137',
	47,
	'Pickett'
);
INSERT INTO CWMS_COUNTY VALUES (
	47139,
	'139',
	47,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	47141,
	'141',
	47,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	47143,
	'143',
	47,
	'Rhea'
);
INSERT INTO CWMS_COUNTY VALUES (
	47145,
	'145',
	47,
	'Roane'
);
INSERT INTO CWMS_COUNTY VALUES (
	47147,
	'147',
	47,
	'Robertson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47149,
	'149',
	47,
	'Rutherford'
);
INSERT INTO CWMS_COUNTY VALUES (
	47151,
	'151',
	47,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	47153,
	'153',
	47,
	'Sequatchie'
);
INSERT INTO CWMS_COUNTY VALUES (
	47155,
	'155',
	47,
	'Sevier'
);
INSERT INTO CWMS_COUNTY VALUES (
	47157,
	'157',
	47,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	47159,
	'159',
	47,
	'Smith'
);
INSERT INTO CWMS_COUNTY VALUES (
	47161,
	'161',
	47,
	'Stewart'
);
INSERT INTO CWMS_COUNTY VALUES (
	47163,
	'163',
	47,
	'Sullivan'
);
INSERT INTO CWMS_COUNTY VALUES (
	47165,
	'165',
	47,
	'Sumner'
);
INSERT INTO CWMS_COUNTY VALUES (
	47167,
	'167',
	47,
	'Tipton'
);
INSERT INTO CWMS_COUNTY VALUES (
	47169,
	'169',
	47,
	'Trousdale'
);
INSERT INTO CWMS_COUNTY VALUES (
	47171,
	'171',
	47,
	'Unicoi'
);
INSERT INTO CWMS_COUNTY VALUES (
	47173,
	'173',
	47,
	'Union'
);
INSERT INTO CWMS_COUNTY VALUES (
	47175,
	'175',
	47,
	'Van Buren'
);
INSERT INTO CWMS_COUNTY VALUES (
	47177,
	'177',
	47,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	47179,
	'179',
	47,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	47181,
	'181',
	47,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	47183,
	'183',
	47,
	'Weakley'
);
INSERT INTO CWMS_COUNTY VALUES (
	47185,
	'185',
	47,
	'White'
);
INSERT INTO CWMS_COUNTY VALUES (
	47187,
	'187',
	47,
	'Williamson'
);
INSERT INTO CWMS_COUNTY VALUES (
	47189,
	'189',
	47,
	'Wilson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48000,
	'000',
	48,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	48001,
	'001',
	48,
	'Anderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48003,
	'003',
	48,
	'Andrews'
);
INSERT INTO CWMS_COUNTY VALUES (
	48005,
	'005',
	48,
	'Angelina'
);
INSERT INTO CWMS_COUNTY VALUES (
	48007,
	'007',
	48,
	'Aransas'
);
INSERT INTO CWMS_COUNTY VALUES (
	48009,
	'009',
	48,
	'Archer'
);
INSERT INTO CWMS_COUNTY VALUES (
	48011,
	'011',
	48,
	'Armstrong'
);
INSERT INTO CWMS_COUNTY VALUES (
	48013,
	'013',
	48,
	'Atascosa'
);
INSERT INTO CWMS_COUNTY VALUES (
	48015,
	'015',
	48,
	'Austin'
);
INSERT INTO CWMS_COUNTY VALUES (
	48017,
	'017',
	48,
	'Bailey'
);
INSERT INTO CWMS_COUNTY VALUES (
	48019,
	'019',
	48,
	'Bandera'
);
INSERT INTO CWMS_COUNTY VALUES (
	48021,
	'021',
	48,
	'Bastrop'
);
INSERT INTO CWMS_COUNTY VALUES (
	48023,
	'023',
	48,
	'Baylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	48025,
	'025',
	48,
	'Bee'
);
INSERT INTO CWMS_COUNTY VALUES (
	48027,
	'027',
	48,
	'Bell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48029,
	'029',
	48,
	'Bexar'
);
INSERT INTO CWMS_COUNTY VALUES (
	48031,
	'031',
	48,
	'Blanco'
);
INSERT INTO CWMS_COUNTY VALUES (
	48033,
	'033',
	48,
	'Borden'
);
INSERT INTO CWMS_COUNTY VALUES (
	48035,
	'035',
	48,
	'Bosque'
);
INSERT INTO CWMS_COUNTY VALUES (
	48037,
	'037',
	48,
	'Bowie'
);
INSERT INTO CWMS_COUNTY VALUES (
	48039,
	'039',
	48,
	'Brazoria'
);
INSERT INTO CWMS_COUNTY VALUES (
	48041,
	'041',
	48,
	'Brazos'
);
INSERT INTO CWMS_COUNTY VALUES (
	48043,
	'043',
	48,
	'Brewster'
);
INSERT INTO CWMS_COUNTY VALUES (
	48045,
	'045',
	48,
	'Briscoe'
);
INSERT INTO CWMS_COUNTY VALUES (
	48047,
	'047',
	48,
	'Brooks'
);
INSERT INTO CWMS_COUNTY VALUES (
	48049,
	'049',
	48,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	48051,
	'051',
	48,
	'Burleson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48053,
	'053',
	48,
	'Burnet'
);
INSERT INTO CWMS_COUNTY VALUES (
	48055,
	'055',
	48,
	'Caldwell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48057,
	'057',
	48,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	48059,
	'059',
	48,
	'Callahan'
);
INSERT INTO CWMS_COUNTY VALUES (
	48061,
	'061',
	48,
	'Cameron'
);
INSERT INTO CWMS_COUNTY VALUES (
	48063,
	'063',
	48,
	'Camp'
);
INSERT INTO CWMS_COUNTY VALUES (
	48065,
	'065',
	48,
	'Carson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48067,
	'067',
	48,
	'Cass'
);
INSERT INTO CWMS_COUNTY VALUES (
	48069,
	'069',
	48,
	'Castro'
);
INSERT INTO CWMS_COUNTY VALUES (
	48071,
	'071',
	48,
	'Chambers'
);
INSERT INTO CWMS_COUNTY VALUES (
	48073,
	'073',
	48,
	'Cherokee'
);
INSERT INTO CWMS_COUNTY VALUES (
	48075,
	'075',
	48,
	'Childress'
);
INSERT INTO CWMS_COUNTY VALUES (
	48077,
	'077',
	48,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	48079,
	'079',
	48,
	'Cochran'
);
INSERT INTO CWMS_COUNTY VALUES (
	48081,
	'081',
	48,
	'Coke'
);
INSERT INTO CWMS_COUNTY VALUES (
	48083,
	'083',
	48,
	'Coleman'
);
INSERT INTO CWMS_COUNTY VALUES (
	48085,
	'085',
	48,
	'Collin'
);
INSERT INTO CWMS_COUNTY VALUES (
	48087,
	'087',
	48,
	'Collingsworth'
);
INSERT INTO CWMS_COUNTY VALUES (
	48089,
	'089',
	48,
	'Colorado'
);
INSERT INTO CWMS_COUNTY VALUES (
	48091,
	'091',
	48,
	'Comal'
);
INSERT INTO CWMS_COUNTY VALUES (
	48093,
	'093',
	48,
	'Comanche'
);
INSERT INTO CWMS_COUNTY VALUES (
	48095,
	'095',
	48,
	'Concho'
);
INSERT INTO CWMS_COUNTY VALUES (
	48097,
	'097',
	48,
	'Cooke'
);
INSERT INTO CWMS_COUNTY VALUES (
	48099,
	'099',
	48,
	'Coryell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48101,
	'101',
	48,
	'Cottle'
);
INSERT INTO CWMS_COUNTY VALUES (
	48103,
	'103',
	48,
	'Crane'
);
INSERT INTO CWMS_COUNTY VALUES (
	48105,
	'105',
	48,
	'Crockett'
);
INSERT INTO CWMS_COUNTY VALUES (
	48107,
	'107',
	48,
	'Crosby'
);
INSERT INTO CWMS_COUNTY VALUES (
	48109,
	'109',
	48,
	'Culberson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48111,
	'111',
	48,
	'Dallam'
);
INSERT INTO CWMS_COUNTY VALUES (
	48113,
	'113',
	48,
	'Dallas'
);
INSERT INTO CWMS_COUNTY VALUES (
	48115,
	'115',
	48,
	'Dawson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48117,
	'117',
	48,
	'Deaf Smith'
);
INSERT INTO CWMS_COUNTY VALUES (
	48119,
	'119',
	48,
	'Delta'
);
INSERT INTO CWMS_COUNTY VALUES (
	48121,
	'121',
	48,
	'Denton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48123,
	'123',
	48,
	'De Witt'
);
INSERT INTO CWMS_COUNTY VALUES (
	48125,
	'125',
	48,
	'Dickens'
);
INSERT INTO CWMS_COUNTY VALUES (
	48127,
	'127',
	48,
	'Dimmit'
);
INSERT INTO CWMS_COUNTY VALUES (
	48129,
	'129',
	48,
	'Donley'
);
INSERT INTO CWMS_COUNTY VALUES (
	48131,
	'131',
	48,
	'Duval'
);
INSERT INTO CWMS_COUNTY VALUES (
	48133,
	'133',
	48,
	'Eastland'
);
INSERT INTO CWMS_COUNTY VALUES (
	48135,
	'135',
	48,
	'Ector'
);
INSERT INTO CWMS_COUNTY VALUES (
	48137,
	'137',
	48,
	'Edwards'
);
INSERT INTO CWMS_COUNTY VALUES (
	48139,
	'139',
	48,
	'Ellis'
);
INSERT INTO CWMS_COUNTY VALUES (
	48141,
	'141',
	48,
	'El Paso'
);
INSERT INTO CWMS_COUNTY VALUES (
	48143,
	'143',
	48,
	'Erath'
);
INSERT INTO CWMS_COUNTY VALUES (
	48145,
	'145',
	48,
	'Falls'
);
INSERT INTO CWMS_COUNTY VALUES (
	48147,
	'147',
	48,
	'Fannin'
);
INSERT INTO CWMS_COUNTY VALUES (
	48149,
	'149',
	48,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	48151,
	'151',
	48,
	'Fisher'
);
INSERT INTO CWMS_COUNTY VALUES (
	48153,
	'153',
	48,
	'Floyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	48155,
	'155',
	48,
	'Foard'
);
INSERT INTO CWMS_COUNTY VALUES (
	48157,
	'157',
	48,
	'Fort Bend'
);
INSERT INTO CWMS_COUNTY VALUES (
	48159,
	'159',
	48,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	48161,
	'161',
	48,
	'Freestone'
);
INSERT INTO CWMS_COUNTY VALUES (
	48163,
	'163',
	48,
	'Frio'
);
INSERT INTO CWMS_COUNTY VALUES (
	48165,
	'165',
	48,
	'Gaines'
);
INSERT INTO CWMS_COUNTY VALUES (
	48167,
	'167',
	48,
	'Galveston'
);
INSERT INTO CWMS_COUNTY VALUES (
	48169,
	'169',
	48,
	'Garza'
);
INSERT INTO CWMS_COUNTY VALUES (
	48171,
	'171',
	48,
	'Gillespie'
);
INSERT INTO CWMS_COUNTY VALUES (
	48173,
	'173',
	48,
	'Glasscock'
);
INSERT INTO CWMS_COUNTY VALUES (
	48175,
	'175',
	48,
	'Goliad'
);
INSERT INTO CWMS_COUNTY VALUES (
	48177,
	'177',
	48,
	'Gonzales'
);
INSERT INTO CWMS_COUNTY VALUES (
	48179,
	'179',
	48,
	'Gray'
);
INSERT INTO CWMS_COUNTY VALUES (
	48181,
	'181',
	48,
	'Grayson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48183,
	'183',
	48,
	'Gregg'
);
INSERT INTO CWMS_COUNTY VALUES (
	48185,
	'185',
	48,
	'Grimes'
);
INSERT INTO CWMS_COUNTY VALUES (
	48187,
	'187',
	48,
	'Guadalupe'
);
INSERT INTO CWMS_COUNTY VALUES (
	48189,
	'189',
	48,
	'Hale'
);
INSERT INTO CWMS_COUNTY VALUES (
	48191,
	'191',
	48,
	'Hall'
);
INSERT INTO CWMS_COUNTY VALUES (
	48193,
	'193',
	48,
	'Hamilton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48195,
	'195',
	48,
	'Hansford'
);
INSERT INTO CWMS_COUNTY VALUES (
	48197,
	'197',
	48,
	'Hardeman'
);
INSERT INTO CWMS_COUNTY VALUES (
	48199,
	'199',
	48,
	'Hardin'
);
INSERT INTO CWMS_COUNTY VALUES (
	48201,
	'201',
	48,
	'Harris'
);
INSERT INTO CWMS_COUNTY VALUES (
	48203,
	'203',
	48,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	48205,
	'205',
	48,
	'Hartley'
);
INSERT INTO CWMS_COUNTY VALUES (
	48207,
	'207',
	48,
	'Haskell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48209,
	'209',
	48,
	'Hays'
);
INSERT INTO CWMS_COUNTY VALUES (
	48211,
	'211',
	48,
	'Hemphill'
);
INSERT INTO CWMS_COUNTY VALUES (
	48213,
	'213',
	48,
	'Henderson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48215,
	'215',
	48,
	'Hidalgo'
);
INSERT INTO CWMS_COUNTY VALUES (
	48217,
	'217',
	48,
	'Hill'
);
INSERT INTO CWMS_COUNTY VALUES (
	48219,
	'219',
	48,
	'Hockley'
);
INSERT INTO CWMS_COUNTY VALUES (
	48221,
	'221',
	48,
	'Hood'
);
INSERT INTO CWMS_COUNTY VALUES (
	48223,
	'223',
	48,
	'Hopkins'
);
INSERT INTO CWMS_COUNTY VALUES (
	48225,
	'225',
	48,
	'Houston'
);
INSERT INTO CWMS_COUNTY VALUES (
	48227,
	'227',
	48,
	'Howard'
);
INSERT INTO CWMS_COUNTY VALUES (
	48229,
	'229',
	48,
	'Hudspeth'
);
INSERT INTO CWMS_COUNTY VALUES (
	48231,
	'231',
	48,
	'Hunt'
);
INSERT INTO CWMS_COUNTY VALUES (
	48233,
	'233',
	48,
	'Hutchinson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48235,
	'235',
	48,
	'Irion'
);
INSERT INTO CWMS_COUNTY VALUES (
	48237,
	'237',
	48,
	'Jack'
);
INSERT INTO CWMS_COUNTY VALUES (
	48239,
	'239',
	48,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48241,
	'241',
	48,
	'Jasper'
);
INSERT INTO CWMS_COUNTY VALUES (
	48243,
	'243',
	48,
	'Jeff Davis'
);
INSERT INTO CWMS_COUNTY VALUES (
	48245,
	'245',
	48,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48247,
	'247',
	48,
	'Jim Hogg'
);
INSERT INTO CWMS_COUNTY VALUES (
	48249,
	'249',
	48,
	'Jim Wells'
);
INSERT INTO CWMS_COUNTY VALUES (
	48251,
	'251',
	48,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48253,
	'253',
	48,
	'Jones'
);
INSERT INTO CWMS_COUNTY VALUES (
	48255,
	'255',
	48,
	'Karnes'
);
INSERT INTO CWMS_COUNTY VALUES (
	48257,
	'257',
	48,
	'Kaufman'
);
INSERT INTO CWMS_COUNTY VALUES (
	48259,
	'259',
	48,
	'Kendall'
);
INSERT INTO CWMS_COUNTY VALUES (
	48261,
	'261',
	48,
	'Kenedy'
);
INSERT INTO CWMS_COUNTY VALUES (
	48263,
	'263',
	48,
	'Kent'
);
INSERT INTO CWMS_COUNTY VALUES (
	48265,
	'265',
	48,
	'Kerr'
);
INSERT INTO CWMS_COUNTY VALUES (
	48267,
	'267',
	48,
	'Kimble'
);
INSERT INTO CWMS_COUNTY VALUES (
	48269,
	'269',
	48,
	'King'
);
INSERT INTO CWMS_COUNTY VALUES (
	48271,
	'271',
	48,
	'Kinney'
);
INSERT INTO CWMS_COUNTY VALUES (
	48273,
	'273',
	48,
	'Kleberg'
);
INSERT INTO CWMS_COUNTY VALUES (
	48275,
	'275',
	48,
	'Knox'
);
INSERT INTO CWMS_COUNTY VALUES (
	48277,
	'277',
	48,
	'Lamar'
);
INSERT INTO CWMS_COUNTY VALUES (
	48279,
	'279',
	48,
	'Lamb'
);
INSERT INTO CWMS_COUNTY VALUES (
	48281,
	'281',
	48,
	'Lampasas'
);
INSERT INTO CWMS_COUNTY VALUES (
	48283,
	'283',
	48,
	'La Salle'
);
INSERT INTO CWMS_COUNTY VALUES (
	48285,
	'285',
	48,
	'Lavaca'
);
INSERT INTO CWMS_COUNTY VALUES (
	48287,
	'287',
	48,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	48289,
	'289',
	48,
	'Leon'
);
INSERT INTO CWMS_COUNTY VALUES (
	48291,
	'291',
	48,
	'Liberty'
);
INSERT INTO CWMS_COUNTY VALUES (
	48293,
	'293',
	48,
	'Limestone'
);
INSERT INTO CWMS_COUNTY VALUES (
	48295,
	'295',
	48,
	'Lipscomb'
);
INSERT INTO CWMS_COUNTY VALUES (
	48297,
	'297',
	48,
	'Live Oak'
);
INSERT INTO CWMS_COUNTY VALUES (
	48299,
	'299',
	48,
	'Llano'
);
INSERT INTO CWMS_COUNTY VALUES (
	48301,
	'301',
	48,
	'Loving'
);
INSERT INTO CWMS_COUNTY VALUES (
	48303,
	'303',
	48,
	'Lubbock'
);
INSERT INTO CWMS_COUNTY VALUES (
	48305,
	'305',
	48,
	'Lynn'
);
INSERT INTO CWMS_COUNTY VALUES (
	48307,
	'307',
	48,
	'McCulloch'
);
INSERT INTO CWMS_COUNTY VALUES (
	48309,
	'309',
	48,
	'McLennan'
);
INSERT INTO CWMS_COUNTY VALUES (
	48311,
	'311',
	48,
	'McMullen'
);
INSERT INTO CWMS_COUNTY VALUES (
	48313,
	'313',
	48,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	48315,
	'315',
	48,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	48317,
	'317',
	48,
	'Martin'
);
INSERT INTO CWMS_COUNTY VALUES (
	48319,
	'319',
	48,
	'Mason'
);
INSERT INTO CWMS_COUNTY VALUES (
	48321,
	'321',
	48,
	'Matagorda'
);
INSERT INTO CWMS_COUNTY VALUES (
	48323,
	'323',
	48,
	'Maverick'
);
INSERT INTO CWMS_COUNTY VALUES (
	48325,
	'325',
	48,
	'Medina'
);
INSERT INTO CWMS_COUNTY VALUES (
	48327,
	'327',
	48,
	'Menard'
);
INSERT INTO CWMS_COUNTY VALUES (
	48329,
	'329',
	48,
	'Midland'
);
INSERT INTO CWMS_COUNTY VALUES (
	48331,
	'331',
	48,
	'Milam'
);
INSERT INTO CWMS_COUNTY VALUES (
	48333,
	'333',
	48,
	'Mills'
);
INSERT INTO CWMS_COUNTY VALUES (
	48335,
	'335',
	48,
	'Mitchell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48337,
	'337',
	48,
	'Montague'
);
INSERT INTO CWMS_COUNTY VALUES (
	48339,
	'339',
	48,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	48341,
	'341',
	48,
	'Moore'
);
INSERT INTO CWMS_COUNTY VALUES (
	48343,
	'343',
	48,
	'Morris'
);
INSERT INTO CWMS_COUNTY VALUES (
	48345,
	'345',
	48,
	'Motley'
);
INSERT INTO CWMS_COUNTY VALUES (
	48347,
	'347',
	48,
	'Nacogdoches'
);
INSERT INTO CWMS_COUNTY VALUES (
	48349,
	'349',
	48,
	'Navarro'
);
INSERT INTO CWMS_COUNTY VALUES (
	48351,
	'351',
	48,
	'Newton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48353,
	'353',
	48,
	'Nolan'
);
INSERT INTO CWMS_COUNTY VALUES (
	48355,
	'355',
	48,
	'Nueces'
);
INSERT INTO CWMS_COUNTY VALUES (
	48357,
	'357',
	48,
	'Ochiltree'
);
INSERT INTO CWMS_COUNTY VALUES (
	48359,
	'359',
	48,
	'Oldham'
);
INSERT INTO CWMS_COUNTY VALUES (
	48361,
	'361',
	48,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	48363,
	'363',
	48,
	'Palo Pinto'
);
INSERT INTO CWMS_COUNTY VALUES (
	48365,
	'365',
	48,
	'Panola'
);
INSERT INTO CWMS_COUNTY VALUES (
	48367,
	'367',
	48,
	'Parker'
);
INSERT INTO CWMS_COUNTY VALUES (
	48369,
	'369',
	48,
	'Parmer'
);
INSERT INTO CWMS_COUNTY VALUES (
	48371,
	'371',
	48,
	'Pecos'
);
INSERT INTO CWMS_COUNTY VALUES (
	48373,
	'373',
	48,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	48375,
	'375',
	48,
	'Potter'
);
INSERT INTO CWMS_COUNTY VALUES (
	48377,
	'377',
	48,
	'Presidio'
);
INSERT INTO CWMS_COUNTY VALUES (
	48379,
	'379',
	48,
	'Rains'
);
INSERT INTO CWMS_COUNTY VALUES (
	48381,
	'381',
	48,
	'Randall'
);
INSERT INTO CWMS_COUNTY VALUES (
	48383,
	'383',
	48,
	'Reagan'
);
INSERT INTO CWMS_COUNTY VALUES (
	48385,
	'385',
	48,
	'Real'
);
INSERT INTO CWMS_COUNTY VALUES (
	48387,
	'387',
	48,
	'Red River'
);
INSERT INTO CWMS_COUNTY VALUES (
	48389,
	'389',
	48,
	'Reeves'
);
INSERT INTO CWMS_COUNTY VALUES (
	48391,
	'391',
	48,
	'Refugio'
);
INSERT INTO CWMS_COUNTY VALUES (
	48393,
	'393',
	48,
	'Roberts'
);
INSERT INTO CWMS_COUNTY VALUES (
	48395,
	'395',
	48,
	'Robertson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48397,
	'397',
	48,
	'Rockwall'
);
INSERT INTO CWMS_COUNTY VALUES (
	48399,
	'399',
	48,
	'Runnels'
);
INSERT INTO CWMS_COUNTY VALUES (
	48401,
	'401',
	48,
	'Rusk'
);
INSERT INTO CWMS_COUNTY VALUES (
	48403,
	'403',
	48,
	'Sabine'
);
INSERT INTO CWMS_COUNTY VALUES (
	48405,
	'405',
	48,
	'San Augustine'
);
INSERT INTO CWMS_COUNTY VALUES (
	48407,
	'407',
	48,
	'San Jacinto'
);
INSERT INTO CWMS_COUNTY VALUES (
	48409,
	'409',
	48,
	'San Patricio'
);
INSERT INTO CWMS_COUNTY VALUES (
	48411,
	'411',
	48,
	'San Saba'
);
INSERT INTO CWMS_COUNTY VALUES (
	48413,
	'413',
	48,
	'Schleicher'
);
INSERT INTO CWMS_COUNTY VALUES (
	48415,
	'415',
	48,
	'Scurry'
);
INSERT INTO CWMS_COUNTY VALUES (
	48417,
	'417',
	48,
	'Shackelford'
);
INSERT INTO CWMS_COUNTY VALUES (
	48419,
	'419',
	48,
	'Shelby'
);
INSERT INTO CWMS_COUNTY VALUES (
	48421,
	'421',
	48,
	'Sherman'
);
INSERT INTO CWMS_COUNTY VALUES (
	48423,
	'423',
	48,
	'Smith'
);
INSERT INTO CWMS_COUNTY VALUES (
	48425,
	'425',
	48,
	'Somervell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48427,
	'427',
	48,
	'Starr'
);
INSERT INTO CWMS_COUNTY VALUES (
	48429,
	'429',
	48,
	'Stephens'
);
INSERT INTO CWMS_COUNTY VALUES (
	48431,
	'431',
	48,
	'Sterling'
);
INSERT INTO CWMS_COUNTY VALUES (
	48433,
	'433',
	48,
	'Stonewall'
);
INSERT INTO CWMS_COUNTY VALUES (
	48435,
	'435',
	48,
	'Sutton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48437,
	'437',
	48,
	'Swisher'
);
INSERT INTO CWMS_COUNTY VALUES (
	48439,
	'439',
	48,
	'Tarrant'
);
INSERT INTO CWMS_COUNTY VALUES (
	48441,
	'441',
	48,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	48443,
	'443',
	48,
	'Terrell'
);
INSERT INTO CWMS_COUNTY VALUES (
	48445,
	'445',
	48,
	'Terry'
);
INSERT INTO CWMS_COUNTY VALUES (
	48447,
	'447',
	48,
	'Throckmorton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48449,
	'449',
	48,
	'Titus'
);
INSERT INTO CWMS_COUNTY VALUES (
	48451,
	'451',
	48,
	'Tom Green'
);
INSERT INTO CWMS_COUNTY VALUES (
	48453,
	'453',
	48,
	'Travis'
);
INSERT INTO CWMS_COUNTY VALUES (
	48455,
	'455',
	48,
	'Trinity'
);
INSERT INTO CWMS_COUNTY VALUES (
	48457,
	'457',
	48,
	'Tyler'
);
INSERT INTO CWMS_COUNTY VALUES (
	48459,
	'459',
	48,
	'Upshur'
);
INSERT INTO CWMS_COUNTY VALUES (
	48461,
	'461',
	48,
	'Upton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48463,
	'463',
	48,
	'Uvalde'
);
INSERT INTO CWMS_COUNTY VALUES (
	48465,
	'465',
	48,
	'Val Verde'
);
INSERT INTO CWMS_COUNTY VALUES (
	48467,
	'467',
	48,
	'Van Zandt'
);
INSERT INTO CWMS_COUNTY VALUES (
	48469,
	'469',
	48,
	'Victoria'
);
INSERT INTO CWMS_COUNTY VALUES (
	48471,
	'471',
	48,
	'Walker'
);
INSERT INTO CWMS_COUNTY VALUES (
	48473,
	'473',
	48,
	'Waller'
);
INSERT INTO CWMS_COUNTY VALUES (
	48475,
	'475',
	48,
	'Ward'
);
INSERT INTO CWMS_COUNTY VALUES (
	48477,
	'477',
	48,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	48479,
	'479',
	48,
	'Webb'
);
INSERT INTO CWMS_COUNTY VALUES (
	48481,
	'481',
	48,
	'Wharton'
);
INSERT INTO CWMS_COUNTY VALUES (
	48483,
	'483',
	48,
	'Wheeler'
);
INSERT INTO CWMS_COUNTY VALUES (
	48485,
	'485',
	48,
	'Wichita'
);
INSERT INTO CWMS_COUNTY VALUES (
	48487,
	'487',
	48,
	'Wilbarger'
);
INSERT INTO CWMS_COUNTY VALUES (
	48489,
	'489',
	48,
	'Willacy'
);
INSERT INTO CWMS_COUNTY VALUES (
	48491,
	'491',
	48,
	'Williamson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48493,
	'493',
	48,
	'Wilson'
);
INSERT INTO CWMS_COUNTY VALUES (
	48495,
	'495',
	48,
	'Winkler'
);
INSERT INTO CWMS_COUNTY VALUES (
	48497,
	'497',
	48,
	'Wise'
);
INSERT INTO CWMS_COUNTY VALUES (
	48499,
	'499',
	48,
	'Wood'
);
INSERT INTO CWMS_COUNTY VALUES (
	48501,
	'501',
	48,
	'Yoakum'
);
INSERT INTO CWMS_COUNTY VALUES (
	48503,
	'503',
	48,
	'Young'
);
INSERT INTO CWMS_COUNTY VALUES (
	48505,
	'505',
	48,
	'Zapata'
);
INSERT INTO CWMS_COUNTY VALUES (
	48507,
	'507',
	48,
	'Zavala'
);
INSERT INTO CWMS_COUNTY VALUES (
	49000,
	'000',
	49,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	49001,
	'001',
	49,
	'Beaver'
);
INSERT INTO CWMS_COUNTY VALUES (
	49003,
	'003',
	49,
	'Box Elder'
);
INSERT INTO CWMS_COUNTY VALUES (
	49005,
	'005',
	49,
	'Cache'
);
INSERT INTO CWMS_COUNTY VALUES (
	49007,
	'007',
	49,
	'Carbon'
);
INSERT INTO CWMS_COUNTY VALUES (
	49009,
	'009',
	49,
	'Daggett'
);
INSERT INTO CWMS_COUNTY VALUES (
	49011,
	'011',
	49,
	'Davis'
);
INSERT INTO CWMS_COUNTY VALUES (
	49013,
	'013',
	49,
	'Duchesne'
);
INSERT INTO CWMS_COUNTY VALUES (
	49015,
	'015',
	49,
	'Emery'
);
INSERT INTO CWMS_COUNTY VALUES (
	49017,
	'017',
	49,
	'Garfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	49019,
	'019',
	49,
	'Grand'
);
INSERT INTO CWMS_COUNTY VALUES (
	49021,
	'021',
	49,
	'Iron'
);
INSERT INTO CWMS_COUNTY VALUES (
	49023,
	'023',
	49,
	'Juab'
);
INSERT INTO CWMS_COUNTY VALUES (
	49025,
	'025',
	49,
	'Kane'
);
INSERT INTO CWMS_COUNTY VALUES (
	49027,
	'027',
	49,
	'Millard'
);
INSERT INTO CWMS_COUNTY VALUES (
	49029,
	'029',
	49,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	49031,
	'031',
	49,
	'Piute'
);
INSERT INTO CWMS_COUNTY VALUES (
	49033,
	'033',
	49,
	'Rich'
);
INSERT INTO CWMS_COUNTY VALUES (
	49035,
	'035',
	49,
	'Salt Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	49037,
	'037',
	49,
	'San Juan'
);
INSERT INTO CWMS_COUNTY VALUES (
	49039,
	'039',
	49,
	'Sanpete'
);
INSERT INTO CWMS_COUNTY VALUES (
	49041,
	'041',
	49,
	'Sevier'
);
INSERT INTO CWMS_COUNTY VALUES (
	49043,
	'043',
	49,
	'Summit'
);
INSERT INTO CWMS_COUNTY VALUES (
	49045,
	'045',
	49,
	'Tooele'
);
INSERT INTO CWMS_COUNTY VALUES (
	49047,
	'047',
	49,
	'Uintah'
);
INSERT INTO CWMS_COUNTY VALUES (
	49049,
	'049',
	49,
	'Utah'
);
INSERT INTO CWMS_COUNTY VALUES (
	49051,
	'051',
	49,
	'Wasatch'
);
INSERT INTO CWMS_COUNTY VALUES (
	49053,
	'053',
	49,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	49055,
	'055',
	49,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	49057,
	'057',
	49,
	'Weber'
);
INSERT INTO CWMS_COUNTY VALUES (
	50000,
	'000',
	50,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	50001,
	'001',
	50,
	'Addison'
);
INSERT INTO CWMS_COUNTY VALUES (
	50003,
	'003',
	50,
	'Bennington'
);
INSERT INTO CWMS_COUNTY VALUES (
	50005,
	'005',
	50,
	'Caledonia'
);
INSERT INTO CWMS_COUNTY VALUES (
	50007,
	'007',
	50,
	'Chittenden'
);
INSERT INTO CWMS_COUNTY VALUES (
	50009,
	'009',
	50,
	'Essex'
);
INSERT INTO CWMS_COUNTY VALUES (
	50011,
	'011',
	50,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	50013,
	'013',
	50,
	'Grand Isle'
);
INSERT INTO CWMS_COUNTY VALUES (
	50015,
	'015',
	50,
	'Lamoille'
);
INSERT INTO CWMS_COUNTY VALUES (
	50017,
	'017',
	50,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	50019,
	'019',
	50,
	'Orleans'
);
INSERT INTO CWMS_COUNTY VALUES (
	50021,
	'021',
	50,
	'Rutland'
);
INSERT INTO CWMS_COUNTY VALUES (
	50023,
	'023',
	50,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	50025,
	'025',
	50,
	'Windham'
);
INSERT INTO CWMS_COUNTY VALUES (
	50027,
	'027',
	50,
	'Windsor'
);
INSERT INTO CWMS_COUNTY VALUES (
	51000,
	'000',
	51,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	51001,
	'001',
	51,
	'Accomack'
);
INSERT INTO CWMS_COUNTY VALUES (
	51003,
	'003',
	51,
	'Albemarle'
);
INSERT INTO CWMS_COUNTY VALUES (
	51005,
	'005',
	51,
	'Alleghany'
);
INSERT INTO CWMS_COUNTY VALUES (
	51007,
	'007',
	51,
	'Amelia'
);
INSERT INTO CWMS_COUNTY VALUES (
	51009,
	'009',
	51,
	'Amherst'
);
INSERT INTO CWMS_COUNTY VALUES (
	51011,
	'011',
	51,
	'Appomattox'
);
INSERT INTO CWMS_COUNTY VALUES (
	51013,
	'013',
	51,
	'Arlington'
);
INSERT INTO CWMS_COUNTY VALUES (
	51015,
	'015',
	51,
	'Augusta'
);
INSERT INTO CWMS_COUNTY VALUES (
	51017,
	'017',
	51,
	'Bath'
);
INSERT INTO CWMS_COUNTY VALUES (
	51019,
	'019',
	51,
	'Bedford'
);
INSERT INTO CWMS_COUNTY VALUES (
	51021,
	'021',
	51,
	'Bland'
);
INSERT INTO CWMS_COUNTY VALUES (
	51023,
	'023',
	51,
	'Botetourt'
);
INSERT INTO CWMS_COUNTY VALUES (
	51025,
	'025',
	51,
	'Brunswick'
);
INSERT INTO CWMS_COUNTY VALUES (
	51027,
	'027',
	51,
	'Buchanan'
);
INSERT INTO CWMS_COUNTY VALUES (
	51029,
	'029',
	51,
	'Buckingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	51031,
	'031',
	51,
	'Campbell'
);
INSERT INTO CWMS_COUNTY VALUES (
	51033,
	'033',
	51,
	'Caroline'
);
INSERT INTO CWMS_COUNTY VALUES (
	51035,
	'035',
	51,
	'Carroll'
);
INSERT INTO CWMS_COUNTY VALUES (
	51036,
	'036',
	51,
	'Charles City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51037,
	'037',
	51,
	'Charlotte'
);
INSERT INTO CWMS_COUNTY VALUES (
	51041,
	'041',
	51,
	'Chesterfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	51043,
	'043',
	51,
	'Clarke'
);
INSERT INTO CWMS_COUNTY VALUES (
	51045,
	'045',
	51,
	'Craig'
);
INSERT INTO CWMS_COUNTY VALUES (
	51047,
	'047',
	51,
	'Culpeper'
);
INSERT INTO CWMS_COUNTY VALUES (
	51049,
	'049',
	51,
	'Cumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	51051,
	'051',
	51,
	'Dickenson'
);
INSERT INTO CWMS_COUNTY VALUES (
	51053,
	'053',
	51,
	'Dinwiddie'
);
INSERT INTO CWMS_COUNTY VALUES (
	51057,
	'057',
	51,
	'Essex'
);
INSERT INTO CWMS_COUNTY VALUES (
	51059,
	'059',
	51,
	'Fairfax'
);
INSERT INTO CWMS_COUNTY VALUES (
	51061,
	'061',
	51,
	'Fauquier'
);
INSERT INTO CWMS_COUNTY VALUES (
	51063,
	'063',
	51,
	'Floyd'
);
INSERT INTO CWMS_COUNTY VALUES (
	51065,
	'065',
	51,
	'Fluvanna'
);
INSERT INTO CWMS_COUNTY VALUES (
	51067,
	'067',
	51,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	51069,
	'069',
	51,
	'Frederick'
);
INSERT INTO CWMS_COUNTY VALUES (
	51071,
	'071',
	51,
	'Giles'
);
INSERT INTO CWMS_COUNTY VALUES (
	51073,
	'073',
	51,
	'Gloucester'
);
INSERT INTO CWMS_COUNTY VALUES (
	51075,
	'075',
	51,
	'Goochland'
);
INSERT INTO CWMS_COUNTY VALUES (
	51077,
	'077',
	51,
	'Grayson'
);
INSERT INTO CWMS_COUNTY VALUES (
	51079,
	'079',
	51,
	'Greene'
);
INSERT INTO CWMS_COUNTY VALUES (
	51081,
	'081',
	51,
	'Greensville'
);
INSERT INTO CWMS_COUNTY VALUES (
	51083,
	'083',
	51,
	'Halifax'
);
INSERT INTO CWMS_COUNTY VALUES (
	51085,
	'085',
	51,
	'Hanover'
);
INSERT INTO CWMS_COUNTY VALUES (
	51087,
	'087',
	51,
	'Henrico'
);
INSERT INTO CWMS_COUNTY VALUES (
	51089,
	'089',
	51,
	'Henry'
);
INSERT INTO CWMS_COUNTY VALUES (
	51091,
	'091',
	51,
	'Highland'
);
INSERT INTO CWMS_COUNTY VALUES (
	51093,
	'093',
	51,
	'Isle of Wight'
);
INSERT INTO CWMS_COUNTY VALUES (
	51095,
	'095',
	51,
	'James City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51097,
	'097',
	51,
	'King and Queen'
);
INSERT INTO CWMS_COUNTY VALUES (
	51099,
	'099',
	51,
	'King George'
);
INSERT INTO CWMS_COUNTY VALUES (
	51101,
	'101',
	51,
	'King William'
);
INSERT INTO CWMS_COUNTY VALUES (
	51103,
	'103',
	51,
	'Lancaster'
);
INSERT INTO CWMS_COUNTY VALUES (
	51105,
	'105',
	51,
	'Lee'
);
INSERT INTO CWMS_COUNTY VALUES (
	51107,
	'107',
	51,
	'Loudoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	51109,
	'109',
	51,
	'Louisa'
);
INSERT INTO CWMS_COUNTY VALUES (
	51111,
	'111',
	51,
	'Lunenburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51113,
	'113',
	51,
	'Madison'
);
INSERT INTO CWMS_COUNTY VALUES (
	51115,
	'115',
	51,
	'Mathews'
);
INSERT INTO CWMS_COUNTY VALUES (
	51117,
	'117',
	51,
	'Mecklenburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51119,
	'119',
	51,
	'Middlesex'
);
INSERT INTO CWMS_COUNTY VALUES (
	51121,
	'121',
	51,
	'Montgomery'
);
INSERT INTO CWMS_COUNTY VALUES (
	51125,
	'125',
	51,
	'Nelson'
);
INSERT INTO CWMS_COUNTY VALUES (
	51127,
	'127',
	51,
	'New Kent'
);
INSERT INTO CWMS_COUNTY VALUES (
	51131,
	'131',
	51,
	'Northampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	51133,
	'133',
	51,
	'Northumberland'
);
INSERT INTO CWMS_COUNTY VALUES (
	51135,
	'135',
	51,
	'Nottoway'
);
INSERT INTO CWMS_COUNTY VALUES (
	51137,
	'137',
	51,
	'Orange'
);
INSERT INTO CWMS_COUNTY VALUES (
	51139,
	'139',
	51,
	'Page'
);
INSERT INTO CWMS_COUNTY VALUES (
	51141,
	'141',
	51,
	'Patrick'
);
INSERT INTO CWMS_COUNTY VALUES (
	51143,
	'143',
	51,
	'Pittsylvania'
);
INSERT INTO CWMS_COUNTY VALUES (
	51145,
	'145',
	51,
	'Powhatan'
);
INSERT INTO CWMS_COUNTY VALUES (
	51147,
	'147',
	51,
	'Prince Edward'
);
INSERT INTO CWMS_COUNTY VALUES (
	51149,
	'149',
	51,
	'Prince George'
);
INSERT INTO CWMS_COUNTY VALUES (
	51153,
	'153',
	51,
	'Prince William'
);
INSERT INTO CWMS_COUNTY VALUES (
	51155,
	'155',
	51,
	'Pulaski'
);
INSERT INTO CWMS_COUNTY VALUES (
	51157,
	'157',
	51,
	'Rappahannock'
);
INSERT INTO CWMS_COUNTY VALUES (
	51159,
	'159',
	51,
	'Richmond'
);
INSERT INTO CWMS_COUNTY VALUES (
	51161,
	'161',
	51,
	'Roanoke'
);
INSERT INTO CWMS_COUNTY VALUES (
	51163,
	'163',
	51,
	'Rockbridge'
);
INSERT INTO CWMS_COUNTY VALUES (
	51165,
	'165',
	51,
	'Rockingham'
);
INSERT INTO CWMS_COUNTY VALUES (
	51167,
	'167',
	51,
	'Russell'
);
INSERT INTO CWMS_COUNTY VALUES (
	51169,
	'169',
	51,
	'Scott'
);
INSERT INTO CWMS_COUNTY VALUES (
	51171,
	'171',
	51,
	'Shenandoah'
);
INSERT INTO CWMS_COUNTY VALUES (
	51173,
	'173',
	51,
	'Smyth'
);
INSERT INTO CWMS_COUNTY VALUES (
	51175,
	'175',
	51,
	'Southampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	51177,
	'177',
	51,
	'Spotsylvania'
);
INSERT INTO CWMS_COUNTY VALUES (
	51179,
	'179',
	51,
	'Stafford'
);
INSERT INTO CWMS_COUNTY VALUES (
	51181,
	'181',
	51,
	'Surry'
);
INSERT INTO CWMS_COUNTY VALUES (
	51183,
	'183',
	51,
	'Sussex'
);
INSERT INTO CWMS_COUNTY VALUES (
	51185,
	'185',
	51,
	'Tazewell'
);
INSERT INTO CWMS_COUNTY VALUES (
	51187,
	'187',
	51,
	'Warren'
);
INSERT INTO CWMS_COUNTY VALUES (
	51191,
	'191',
	51,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	51193,
	'193',
	51,
	'Westmoreland'
);
INSERT INTO CWMS_COUNTY VALUES (
	51195,
	'195',
	51,
	'Wise'
);
INSERT INTO CWMS_COUNTY VALUES (
	51197,
	'197',
	51,
	'Wythe'
);
INSERT INTO CWMS_COUNTY VALUES (
	51199,
	'199',
	51,
	'York'
);
INSERT INTO CWMS_COUNTY VALUES (
	51510,
	'510',
	51,
	'Alexandria'
);
INSERT INTO CWMS_COUNTY VALUES (
	51515,
	'515',
	51,
	'Bedford City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51520,
	'520',
	51,
	'Bristol'
);
INSERT INTO CWMS_COUNTY VALUES (
	51530,
	'530',
	51,
	'Buena Vista'
);
INSERT INTO CWMS_COUNTY VALUES (
	51540,
	'540',
	51,
	'Charlottesville'
);
INSERT INTO CWMS_COUNTY VALUES (
	51550,
	'550',
	51,
	'Chesapeake'
);
INSERT INTO CWMS_COUNTY VALUES (
	51560,
	'560',
	51,
	'Clifton Forge'
);
INSERT INTO CWMS_COUNTY VALUES (
	51570,
	'570',
	51,
	'Colonial Heights'
);
INSERT INTO CWMS_COUNTY VALUES (
	51580,
	'580',
	51,
	'Covington'
);
INSERT INTO CWMS_COUNTY VALUES (
	51590,
	'590',
	51,
	'Danville'
);
INSERT INTO CWMS_COUNTY VALUES (
	51595,
	'595',
	51,
	'Emporia'
);
INSERT INTO CWMS_COUNTY VALUES (
	51600,
	'600',
	51,
	'Fairfax City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51610,
	'610',
	51,
	'Falls Chruch'
);
INSERT INTO CWMS_COUNTY VALUES (
	51620,
	'620',
	51,
	'Franklin City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51630,
	'630',
	51,
	'Fredericksburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51640,
	'640',
	51,
	'Galax'
);
INSERT INTO CWMS_COUNTY VALUES (
	51650,
	'650',
	51,
	'Hampton'
);
INSERT INTO CWMS_COUNTY VALUES (
	51660,
	'660',
	51,
	'Harrisonburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51670,
	'670',
	51,
	'Hopewell'
);
INSERT INTO CWMS_COUNTY VALUES (
	51678,
	'678',
	51,
	'Lexington'
);
INSERT INTO CWMS_COUNTY VALUES (
	51680,
	'680',
	51,
	'Lynchburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51683,
	'683',
	51,
	'Manassas City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51685,
	'685',
	51,
	'Manassas Park City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51690,
	'690',
	51,
	'Martinsville'
);
INSERT INTO CWMS_COUNTY VALUES (
	51700,
	'700',
	51,
	'Newport News'
);
INSERT INTO CWMS_COUNTY VALUES (
	51710,
	'710',
	51,
	'Norfolk'
);
INSERT INTO CWMS_COUNTY VALUES (
	51720,
	'720',
	51,
	'Norton'
);
INSERT INTO CWMS_COUNTY VALUES (
	51730,
	'730',
	51,
	'Petersburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51735,
	'735',
	51,
	'Poquoson City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51740,
	'740',
	51,
	'Portsmouth'
);
INSERT INTO CWMS_COUNTY VALUES (
	51750,
	'750',
	51,
	'Radford'
);
INSERT INTO CWMS_COUNTY VALUES (
	51760,
	'760',
	51,
	'Richmond City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51770,
	'770',
	51,
	'Roanoke City'
);
INSERT INTO CWMS_COUNTY VALUES (
	51775,
	'775',
	51,
	'Salem'
);
INSERT INTO CWMS_COUNTY VALUES (
	51780,
	'780',
	51,
	'South Boston'
);
INSERT INTO CWMS_COUNTY VALUES (
	51790,
	'790',
	51,
	'Staunton'
);
INSERT INTO CWMS_COUNTY VALUES (
	51800,
	'800',
	51,
	'Suffolk'
);
INSERT INTO CWMS_COUNTY VALUES (
	51810,
	'810',
	51,
	'Virginia Beach'
);
INSERT INTO CWMS_COUNTY VALUES (
	51820,
	'820',
	51,
	'Waynesboro'
);
INSERT INTO CWMS_COUNTY VALUES (
	51830,
	'830',
	51,
	'Williamsburg'
);
INSERT INTO CWMS_COUNTY VALUES (
	51840,
	'840',
	51,
	'Winchester'
);
INSERT INTO CWMS_COUNTY VALUES (
	53000,
	'000',
	53,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	53001,
	'001',
	53,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	53003,
	'003',
	53,
	'Asotin'
);
INSERT INTO CWMS_COUNTY VALUES (
	53005,
	'005',
	53,
	'Benton'
);
INSERT INTO CWMS_COUNTY VALUES (
	53007,
	'007',
	53,
	'Chelan'
);
INSERT INTO CWMS_COUNTY VALUES (
	53009,
	'009',
	53,
	'Clallam'
);
INSERT INTO CWMS_COUNTY VALUES (
	53011,
	'011',
	53,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	53013,
	'013',
	53,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	53015,
	'015',
	53,
	'Cowlitz'
);
INSERT INTO CWMS_COUNTY VALUES (
	53017,
	'017',
	53,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	53019,
	'019',
	53,
	'Ferry'
);
INSERT INTO CWMS_COUNTY VALUES (
	53021,
	'021',
	53,
	'Franklin'
);
INSERT INTO CWMS_COUNTY VALUES (
	53023,
	'023',
	53,
	'Garfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	53025,
	'025',
	53,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	53027,
	'027',
	53,
	'Grays Harbor'
);
INSERT INTO CWMS_COUNTY VALUES (
	53029,
	'029',
	53,
	'Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	53031,
	'031',
	53,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	53033,
	'033',
	53,
	'King'
);
INSERT INTO CWMS_COUNTY VALUES (
	53035,
	'035',
	53,
	'Kitsap'
);
INSERT INTO CWMS_COUNTY VALUES (
	53037,
	'037',
	53,
	'Kittitas'
);
INSERT INTO CWMS_COUNTY VALUES (
	53039,
	'039',
	53,
	'Klickitat'
);
INSERT INTO CWMS_COUNTY VALUES (
	53041,
	'041',
	53,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	53043,
	'043',
	53,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	53045,
	'045',
	53,
	'Mason'
);
INSERT INTO CWMS_COUNTY VALUES (
	53047,
	'047',
	53,
	'Okanogan'
);
INSERT INTO CWMS_COUNTY VALUES (
	53049,
	'049',
	53,
	'Pacific'
);
INSERT INTO CWMS_COUNTY VALUES (
	53051,
	'051',
	53,
	'Pend Oreille'
);
INSERT INTO CWMS_COUNTY VALUES (
	53053,
	'053',
	53,
	'Pierce'
);
INSERT INTO CWMS_COUNTY VALUES (
	53055,
	'055',
	53,
	'San Juan'
);
INSERT INTO CWMS_COUNTY VALUES (
	53057,
	'057',
	53,
	'Skagit'
);
INSERT INTO CWMS_COUNTY VALUES (
	53059,
	'059',
	53,
	'Skamania'
);
INSERT INTO CWMS_COUNTY VALUES (
	53061,
	'061',
	53,
	'Snohomish'
);
INSERT INTO CWMS_COUNTY VALUES (
	53063,
	'063',
	53,
	'Spokane'
);
INSERT INTO CWMS_COUNTY VALUES (
	53065,
	'065',
	53,
	'Stevens'
);
INSERT INTO CWMS_COUNTY VALUES (
	53067,
	'067',
	53,
	'Thurston'
);
INSERT INTO CWMS_COUNTY VALUES (
	53069,
	'069',
	53,
	'Wahkiakum'
);
INSERT INTO CWMS_COUNTY VALUES (
	53071,
	'071',
	53,
	'Walla Walla'
);
INSERT INTO CWMS_COUNTY VALUES (
	53073,
	'073',
	53,
	'Whatcom'
);
INSERT INTO CWMS_COUNTY VALUES (
	53075,
	'075',
	53,
	'Whitman'
);
INSERT INTO CWMS_COUNTY VALUES (
	53077,
	'077',
	53,
	'Yakima'
);
INSERT INTO CWMS_COUNTY VALUES (
	54000,
	'000',
	54,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	54001,
	'001',
	54,
	'Barbour'
);
INSERT INTO CWMS_COUNTY VALUES (
	54003,
	'003',
	54,
	'Berkeley'
);
INSERT INTO CWMS_COUNTY VALUES (
	54005,
	'005',
	54,
	'Boone'
);
INSERT INTO CWMS_COUNTY VALUES (
	54007,
	'007',
	54,
	'Braxton'
);
INSERT INTO CWMS_COUNTY VALUES (
	54009,
	'009',
	54,
	'Brooke'
);
INSERT INTO CWMS_COUNTY VALUES (
	54011,
	'011',
	54,
	'Cabell'
);
INSERT INTO CWMS_COUNTY VALUES (
	54013,
	'013',
	54,
	'Calhoun'
);
INSERT INTO CWMS_COUNTY VALUES (
	54015,
	'015',
	54,
	'Clay'
);
INSERT INTO CWMS_COUNTY VALUES (
	54017,
	'017',
	54,
	'Doddridge'
);
INSERT INTO CWMS_COUNTY VALUES (
	54019,
	'019',
	54,
	'Fayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	54021,
	'021',
	54,
	'Gilmer'
);
INSERT INTO CWMS_COUNTY VALUES (
	54023,
	'023',
	54,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	54025,
	'025',
	54,
	'Greenbrier'
);
INSERT INTO CWMS_COUNTY VALUES (
	54027,
	'027',
	54,
	'Hampshire'
);
INSERT INTO CWMS_COUNTY VALUES (
	54029,
	'029',
	54,
	'Hancock'
);
INSERT INTO CWMS_COUNTY VALUES (
	54031,
	'031',
	54,
	'Hardy'
);
INSERT INTO CWMS_COUNTY VALUES (
	54033,
	'033',
	54,
	'Harrison'
);
INSERT INTO CWMS_COUNTY VALUES (
	54035,
	'035',
	54,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	54037,
	'037',
	54,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	54039,
	'039',
	54,
	'Kanawha'
);
INSERT INTO CWMS_COUNTY VALUES (
	54041,
	'041',
	54,
	'Lewis'
);
INSERT INTO CWMS_COUNTY VALUES (
	54043,
	'043',
	54,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	54045,
	'045',
	54,
	'Logan'
);
INSERT INTO CWMS_COUNTY VALUES (
	54047,
	'047',
	54,
	'McDowell'
);
INSERT INTO CWMS_COUNTY VALUES (
	54049,
	'049',
	54,
	'Marion'
);
INSERT INTO CWMS_COUNTY VALUES (
	54051,
	'051',
	54,
	'Marshall'
);
INSERT INTO CWMS_COUNTY VALUES (
	54053,
	'053',
	54,
	'Mason'
);
INSERT INTO CWMS_COUNTY VALUES (
	54055,
	'055',
	54,
	'Mercer'
);
INSERT INTO CWMS_COUNTY VALUES (
	54057,
	'057',
	54,
	'Mineral'
);
INSERT INTO CWMS_COUNTY VALUES (
	54059,
	'059',
	54,
	'Mingo'
);
INSERT INTO CWMS_COUNTY VALUES (
	54061,
	'061',
	54,
	'Monongalia'
);
INSERT INTO CWMS_COUNTY VALUES (
	54063,
	'063',
	54,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	54065,
	'065',
	54,
	'Morgan'
);
INSERT INTO CWMS_COUNTY VALUES (
	54067,
	'067',
	54,
	'Nicholas'
);
INSERT INTO CWMS_COUNTY VALUES (
	54069,
	'069',
	54,
	'Ohio'
);
INSERT INTO CWMS_COUNTY VALUES (
	54071,
	'071',
	54,
	'Pendleton'
);
INSERT INTO CWMS_COUNTY VALUES (
	54073,
	'073',
	54,
	'Pleasants'
);
INSERT INTO CWMS_COUNTY VALUES (
	54075,
	'075',
	54,
	'Pocahontas'
);
INSERT INTO CWMS_COUNTY VALUES (
	54077,
	'077',
	54,
	'Preston'
);
INSERT INTO CWMS_COUNTY VALUES (
	54079,
	'079',
	54,
	'Putnam'
);
INSERT INTO CWMS_COUNTY VALUES (
	54081,
	'081',
	54,
	'Raleigh'
);
INSERT INTO CWMS_COUNTY VALUES (
	54083,
	'083',
	54,
	'Randolph'
);
INSERT INTO CWMS_COUNTY VALUES (
	54085,
	'085',
	54,
	'Ritchie'
);
INSERT INTO CWMS_COUNTY VALUES (
	54087,
	'087',
	54,
	'Roane'
);
INSERT INTO CWMS_COUNTY VALUES (
	54089,
	'089',
	54,
	'Summers'
);
INSERT INTO CWMS_COUNTY VALUES (
	54091,
	'091',
	54,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	54093,
	'093',
	54,
	'Tucker'
);
INSERT INTO CWMS_COUNTY VALUES (
	54095,
	'095',
	54,
	'Tyler'
);
INSERT INTO CWMS_COUNTY VALUES (
	54097,
	'097',
	54,
	'Upshur'
);
INSERT INTO CWMS_COUNTY VALUES (
	54099,
	'099',
	54,
	'Wayne'
);
INSERT INTO CWMS_COUNTY VALUES (
	54101,
	'101',
	54,
	'Webster'
);
INSERT INTO CWMS_COUNTY VALUES (
	54103,
	'103',
	54,
	'Wetzel'
);
INSERT INTO CWMS_COUNTY VALUES (
	54105,
	'105',
	54,
	'Wirt'
);
INSERT INTO CWMS_COUNTY VALUES (
	54107,
	'107',
	54,
	'Wood'
);
INSERT INTO CWMS_COUNTY VALUES (
	54109,
	'109',
	54,
	'Wyoming'
);
INSERT INTO CWMS_COUNTY VALUES (
	55000,
	'000',
	55,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	55001,
	'001',
	55,
	'Adams'
);
INSERT INTO CWMS_COUNTY VALUES (
	55003,
	'003',
	55,
	'Ashland'
);
INSERT INTO CWMS_COUNTY VALUES (
	55005,
	'005',
	55,
	'Barron'
);
INSERT INTO CWMS_COUNTY VALUES (
	55007,
	'007',
	55,
	'Bayfield'
);
INSERT INTO CWMS_COUNTY VALUES (
	55009,
	'009',
	55,
	'Brown'
);
INSERT INTO CWMS_COUNTY VALUES (
	55011,
	'011',
	55,
	'Buffalo'
);
INSERT INTO CWMS_COUNTY VALUES (
	55013,
	'013',
	55,
	'Burnett'
);
INSERT INTO CWMS_COUNTY VALUES (
	55015,
	'015',
	55,
	'Calumet'
);
INSERT INTO CWMS_COUNTY VALUES (
	55017,
	'017',
	55,
	'Chippewa'
);
INSERT INTO CWMS_COUNTY VALUES (
	55019,
	'019',
	55,
	'Clark'
);
INSERT INTO CWMS_COUNTY VALUES (
	55021,
	'021',
	55,
	'Columbia'
);
INSERT INTO CWMS_COUNTY VALUES (
	55023,
	'023',
	55,
	'Crawford'
);
INSERT INTO CWMS_COUNTY VALUES (
	55025,
	'025',
	55,
	'Dane'
);
INSERT INTO CWMS_COUNTY VALUES (
	55027,
	'027',
	55,
	'Dodge'
);
INSERT INTO CWMS_COUNTY VALUES (
	55029,
	'029',
	55,
	'Door'
);
INSERT INTO CWMS_COUNTY VALUES (
	55031,
	'031',
	55,
	'Douglas'
);
INSERT INTO CWMS_COUNTY VALUES (
	55033,
	'033',
	55,
	'Dunn'
);
INSERT INTO CWMS_COUNTY VALUES (
	55035,
	'035',
	55,
	'Eau Claire'
);
INSERT INTO CWMS_COUNTY VALUES (
	55037,
	'037',
	55,
	'Florence'
);
INSERT INTO CWMS_COUNTY VALUES (
	55039,
	'039',
	55,
	'Fond Du Lac'
);
INSERT INTO CWMS_COUNTY VALUES (
	55041,
	'041',
	55,
	'Forest'
);
INSERT INTO CWMS_COUNTY VALUES (
	55043,
	'043',
	55,
	'Grant'
);
INSERT INTO CWMS_COUNTY VALUES (
	55045,
	'045',
	55,
	'Green'
);
INSERT INTO CWMS_COUNTY VALUES (
	55047,
	'047',
	55,
	'Green Lake'
);
INSERT INTO CWMS_COUNTY VALUES (
	55049,
	'049',
	55,
	'Iowa'
);
INSERT INTO CWMS_COUNTY VALUES (
	55051,
	'051',
	55,
	'Iron'
);
INSERT INTO CWMS_COUNTY VALUES (
	55053,
	'053',
	55,
	'Jackson'
);
INSERT INTO CWMS_COUNTY VALUES (
	55055,
	'055',
	55,
	'Jefferson'
);
INSERT INTO CWMS_COUNTY VALUES (
	55057,
	'057',
	55,
	'Juneau'
);
INSERT INTO CWMS_COUNTY VALUES (
	55059,
	'059',
	55,
	'Kenosha'
);
INSERT INTO CWMS_COUNTY VALUES (
	55061,
	'061',
	55,
	'Kewaunee'
);
INSERT INTO CWMS_COUNTY VALUES (
	55063,
	'063',
	55,
	'La Crosse'
);
INSERT INTO CWMS_COUNTY VALUES (
	55065,
	'065',
	55,
	'Lafayette'
);
INSERT INTO CWMS_COUNTY VALUES (
	55067,
	'067',
	55,
	'Langlade'
);
INSERT INTO CWMS_COUNTY VALUES (
	55069,
	'069',
	55,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	55071,
	'071',
	55,
	'Manitowoc'
);
INSERT INTO CWMS_COUNTY VALUES (
	55073,
	'073',
	55,
	'Marathon'
);
INSERT INTO CWMS_COUNTY VALUES (
	55075,
	'075',
	55,
	'Marinette'
);
INSERT INTO CWMS_COUNTY VALUES (
	55077,
	'077',
	55,
	'Marquette'
);
INSERT INTO CWMS_COUNTY VALUES (
	55078,
	'078',
	55,
	'Menominee'
);
INSERT INTO CWMS_COUNTY VALUES (
	55079,
	'079',
	55,
	'Milwaukee'
);
INSERT INTO CWMS_COUNTY VALUES (
	55081,
	'081',
	55,
	'Monroe'
);
INSERT INTO CWMS_COUNTY VALUES (
	55083,
	'083',
	55,
	'Oconto'
);
INSERT INTO CWMS_COUNTY VALUES (
	55085,
	'085',
	55,
	'Oneida'
);
INSERT INTO CWMS_COUNTY VALUES (
	55087,
	'087',
	55,
	'Outagamie'
);
INSERT INTO CWMS_COUNTY VALUES (
	55089,
	'089',
	55,
	'Ozaukee'
);
INSERT INTO CWMS_COUNTY VALUES (
	55091,
	'091',
	55,
	'Pepin'
);
INSERT INTO CWMS_COUNTY VALUES (
	55093,
	'093',
	55,
	'Pierce'
);
INSERT INTO CWMS_COUNTY VALUES (
	55095,
	'095',
	55,
	'Polk'
);
INSERT INTO CWMS_COUNTY VALUES (
	55097,
	'097',
	55,
	'Portage'
);
INSERT INTO CWMS_COUNTY VALUES (
	55099,
	'099',
	55,
	'Price'
);
INSERT INTO CWMS_COUNTY VALUES (
	55101,
	'101',
	55,
	'Racine'
);
INSERT INTO CWMS_COUNTY VALUES (
	55103,
	'103',
	55,
	'Richland'
);
INSERT INTO CWMS_COUNTY VALUES (
	55105,
	'105',
	55,
	'Rock'
);
INSERT INTO CWMS_COUNTY VALUES (
	55107,
	'107',
	55,
	'Rusk'
);
INSERT INTO CWMS_COUNTY VALUES (
	55109,
	'109',
	55,
	'St. Croix'
);
INSERT INTO CWMS_COUNTY VALUES (
	55111,
	'111',
	55,
	'Sauk'
);
INSERT INTO CWMS_COUNTY VALUES (
	55113,
	'113',
	55,
	'Sawyer'
);
INSERT INTO CWMS_COUNTY VALUES (
	55115,
	'115',
	55,
	'Shawano'
);
INSERT INTO CWMS_COUNTY VALUES (
	55117,
	'117',
	55,
	'Sheboygan'
);
INSERT INTO CWMS_COUNTY VALUES (
	55119,
	'119',
	55,
	'Taylor'
);
INSERT INTO CWMS_COUNTY VALUES (
	55121,
	'121',
	55,
	'Trempealeau'
);
INSERT INTO CWMS_COUNTY VALUES (
	55123,
	'123',
	55,
	'Vernon'
);
INSERT INTO CWMS_COUNTY VALUES (
	55125,
	'125',
	55,
	'Vilas'
);
INSERT INTO CWMS_COUNTY VALUES (
	55127,
	'127',
	55,
	'Walworth'
);
INSERT INTO CWMS_COUNTY VALUES (
	55129,
	'129',
	55,
	'Washburn'
);
INSERT INTO CWMS_COUNTY VALUES (
	55131,
	'131',
	55,
	'Washington'
);
INSERT INTO CWMS_COUNTY VALUES (
	55133,
	'133',
	55,
	'Waukesha'
);
INSERT INTO CWMS_COUNTY VALUES (
	55135,
	'135',
	55,
	'Waupaca'
);
INSERT INTO CWMS_COUNTY VALUES (
	55137,
	'137',
	55,
	'Waushara'
);
INSERT INTO CWMS_COUNTY VALUES (
	55139,
	'139',
	55,
	'Winnebago'
);
INSERT INTO CWMS_COUNTY VALUES (
	55141,
	'141',
	55,
	'Wood'
);
INSERT INTO CWMS_COUNTY VALUES (
	56000,
	'000',
	56,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	56001,
	'001',
	56,
	'Albany'
);
INSERT INTO CWMS_COUNTY VALUES (
	56003,
	'003',
	56,
	'Big Horn'
);
INSERT INTO CWMS_COUNTY VALUES (
	56005,
	'005',
	56,
	'Campbell'
);
INSERT INTO CWMS_COUNTY VALUES (
	56007,
	'007',
	56,
	'Carbon'
);
INSERT INTO CWMS_COUNTY VALUES (
	56009,
	'009',
	56,
	'Converse'
);
INSERT INTO CWMS_COUNTY VALUES (
	56011,
	'011',
	56,
	'Crook'
);
INSERT INTO CWMS_COUNTY VALUES (
	56013,
	'013',
	56,
	'Fremont'
);
INSERT INTO CWMS_COUNTY VALUES (
	56015,
	'015',
	56,
	'Goshen'
);
INSERT INTO CWMS_COUNTY VALUES (
	56017,
	'017',
	56,
	'Hot Springs'
);
INSERT INTO CWMS_COUNTY VALUES (
	56019,
	'019',
	56,
	'Johnson'
);
INSERT INTO CWMS_COUNTY VALUES (
	56021,
	'021',
	56,
	'Laramie'
);
INSERT INTO CWMS_COUNTY VALUES (
	56023,
	'023',
	56,
	'Lincoln'
);
INSERT INTO CWMS_COUNTY VALUES (
	56025,
	'025',
	56,
	'Natrona'
);
INSERT INTO CWMS_COUNTY VALUES (
	56027,
	'027',
	56,
	'Niobrara'
);
INSERT INTO CWMS_COUNTY VALUES (
	56029,
	'029',
	56,
	'Park'
);
INSERT INTO CWMS_COUNTY VALUES (
	56031,
	'031',
	56,
	'Platte'
);
INSERT INTO CWMS_COUNTY VALUES (
	56033,
	'033',
	56,
	'Sheridan'
);
INSERT INTO CWMS_COUNTY VALUES (
	56035,
	'035',
	56,
	'Sublette'
);
INSERT INTO CWMS_COUNTY VALUES (
	56037,
	'037',
	56,
	'Sweetwater'
);
INSERT INTO CWMS_COUNTY VALUES (
	56039,
	'039',
	56,
	'Teton'
);
INSERT INTO CWMS_COUNTY VALUES (
	56041,
	'041',
	56,
	'Uinta'
);
INSERT INTO CWMS_COUNTY VALUES (
	56043,
	'043',
	56,
	'Washakie'
);
INSERT INTO CWMS_COUNTY VALUES (
	56045,
	'045',
	56,
	'Weston'
);
INSERT INTO CWMS_COUNTY VALUES (
	60000,
	'000',
	60,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	60010,
	'010',
	60,
	'Eastern District'
);
INSERT INTO CWMS_COUNTY VALUES (
	60020,
	'020',
	60,
	'Manu''a District'
);
INSERT INTO CWMS_COUNTY VALUES (
	60030,
	'030',
	60,
	'Rose Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	60040,
	'040',
	60,
	'Swains Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	60050,
	'050',
	60,
	'Western District'
);
INSERT INTO CWMS_COUNTY VALUES (
	66000,
	'000',
	66,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	66010,
	'010',
	66,
	'Guam'
);
INSERT INTO CWMS_COUNTY VALUES (
	68000,
	'000',
	68,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	68007,
	'007',
	68,
	'Ailinginae Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68010,
	'010',
	68,
	'Ailinglaplap Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68030,
	'030',
	68,
	'Ailuk Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68040,
	'040',
	68,
	'Arno Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68050,
	'050',
	68,
	'Aur Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68060,
	'060',
	68,
	'Bikar Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68070,
	'070',
	68,
	'Bikini Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68073,
	'073',
	68,
	'Bokak Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68080,
	'080',
	68,
	'Ebon Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68090,
	'090',
	68,
	'Enewetak Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68100,
	'100',
	68,
	'Erikub Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68110,
	'110',
	68,
	'Jabat Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	68120,
	'120',
	68,
	'Jaluit Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68130,
	'130',
	68,
	'Jemo Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	68140,
	'140',
	68,
	'Kili Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	68150,
	'150',
	68,
	'Kwajalein Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68160,
	'160',
	68,
	'Lae Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68170,
	'170',
	68,
	'Lib Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	68180,
	'180',
	68,
	'Likiep Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68190,
	'190',
	68,
	'Majuro Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68300,
	'300',
	68,
	'Maloelap Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68310,
	'310',
	68,
	'Mejit Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	68320,
	'320',
	68,
	'Mili Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68330,
	'330',
	68,
	'Namdrik Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68340,
	'340',
	68,
	'Namu Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68350,
	'350',
	68,
	'Rongelap Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68360,
	'360',
	68,
	'Rongrik Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68385,
	'385',
	68,
	'Taka Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68390,
	'390',
	68,
	'Ujae Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68400,
	'400',
	68,
	'Ujelang Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68410,
	'410',
	68,
	'Utrik Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68420,
	'420',
	68,
	'Wotho Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	68430,
	'430',
	68,
	'Wotje Atoll'
);
INSERT INTO CWMS_COUNTY VALUES (
	69000,
	'000',
	69,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	69085,
	'085',
	69,
	'Northern Islands Municipality'
);
INSERT INTO CWMS_COUNTY VALUES (
	69100,
	'100',
	69,
	'Rota Municipality'
);
INSERT INTO CWMS_COUNTY VALUES (
	69110,
	'110',
	69,
	'Saipan Municipality'
);
INSERT INTO CWMS_COUNTY VALUES (
	69120,
	'120',
	69,
	'Tinian Municipality'
);
INSERT INTO CWMS_COUNTY VALUES (
	72000,
	'000',
	72,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	72001,
	'001',
	72,
	'Adjuntas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72003,
	'003',
	72,
	'Aguada Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72005,
	'005',
	72,
	'Aguadilla Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72007,
	'007',
	72,
	'Aguas Buenas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72009,
	'009',
	72,
	'Aibonito Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72011,
	'011',
	72,
	'Anasco Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72013,
	'013',
	72,
	'Arecibo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72015,
	'015',
	72,
	'Arroyo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72017,
	'017',
	72,
	'Barceloneta Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72019,
	'019',
	72,
	'Barranquitas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72021,
	'021',
	72,
	'Bayamon Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72023,
	'023',
	72,
	'Cabo Rojo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72025,
	'025',
	72,
	'Caguas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72027,
	'027',
	72,
	'Camuy Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72029,
	'029',
	72,
	'Canovanas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72031,
	'031',
	72,
	'Carolina Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72033,
	'033',
	72,
	'Catano Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72035,
	'035',
	72,
	'Cayey Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72037,
	'037',
	72,
	'Ceiba Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72039,
	'039',
	72,
	'Ciales Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72041,
	'041',
	72,
	'Cidra Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72043,
	'043',
	72,
	'Coamo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72045,
	'045',
	72,
	'Comerio Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72047,
	'047',
	72,
	'Corozal Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72049,
	'049',
	72,
	'Culebra Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72051,
	'051',
	72,
	'Dorado Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72053,
	'053',
	72,
	'Fajardo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72054,
	'054',
	72,
	'Florida Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72055,
	'055',
	72,
	'Guanica Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72057,
	'057',
	72,
	'Guayama Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72059,
	'059',
	72,
	'Guayanilla Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72061,
	'061',
	72,
	'Guaynabo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72063,
	'063',
	72,
	'Gurabo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72065,
	'065',
	72,
	'Hatillo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72067,
	'067',
	72,
	'Hormigueros Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72069,
	'069',
	72,
	'Humacao Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72071,
	'071',
	72,
	'Isabela Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72073,
	'073',
	72,
	'Jayuya Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72075,
	'075',
	72,
	'Juana Diaz Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72077,
	'077',
	72,
	'Juncos Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72079,
	'079',
	72,
	'Lajas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72081,
	'081',
	72,
	'Lares Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72083,
	'083',
	72,
	'Las Marias Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72085,
	'085',
	72,
	'Las Piedras Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72087,
	'087',
	72,
	'Loiza Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72089,
	'089',
	72,
	'Luquillo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72091,
	'091',
	72,
	'Manati Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72093,
	'093',
	72,
	'Maricao Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72095,
	'095',
	72,
	'Maunabo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72097,
	'097',
	72,
	'Mayaguez Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72099,
	'099',
	72,
	'Moca Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72101,
	'101',
	72,
	'Morovis Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72103,
	'103',
	72,
	'Naguabo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72105,
	'105',
	72,
	'Naranjito Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72107,
	'107',
	72,
	'Orocovis Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72109,
	'109',
	72,
	'Patillas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72111,
	'111',
	72,
	'Penuelas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72113,
	'113',
	72,
	'Ponce Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72115,
	'115',
	72,
	'Quebradillas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72117,
	'117',
	72,
	'Rincon Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72119,
	'119',
	72,
	'Rio Grande Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72121,
	'121',
	72,
	'Sabana Grande Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72123,
	'123',
	72,
	'Salinas Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72125,
	'125',
	72,
	'San German Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72127,
	'127',
	72,
	'San Juan Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72129,
	'129',
	72,
	'San Lorenzo Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72131,
	'131',
	72,
	'San Sebastian Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72133,
	'133',
	72,
	'Santa Isabel Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72135,
	'135',
	72,
	'Toa Alta Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72137,
	'137',
	72,
	'Toa Baja Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72139,
	'139',
	72,
	'Trujillo Alto Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72141,
	'141',
	72,
	'Utuado Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72143,
	'143',
	72,
	'Vega Alta Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72145,
	'145',
	72,
	'Vega Baja Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72147,
	'147',
	72,
	'Vieques Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72149,
	'149',
	72,
	'Villalba Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72151,
	'151',
	72,
	'Yabucoa Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	72153,
	'153',
	72,
	'Yauco Municipio'
);
INSERT INTO CWMS_COUNTY VALUES (
	78000,
	'000',
	78,
	'Unknown County or County N/A'
);
INSERT INTO CWMS_COUNTY VALUES (
	78010,
	'010',
	78,
	'St. Croix Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	78020,
	'020',
	78,
	'St. John Island'
);
INSERT INTO CWMS_COUNTY VALUES (
	78030,
	'030',
	78,
	'St. Thomas Island'
);


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


INSERT INTO CWMS_INTERVAL VALUES (29, '0', 0, 'Irregular recurrence interval');
INSERT INTO CWMS_INTERVAL VALUES (31, '~1Minute', 0, 'Local time irregular: expected recurrence interval of 1 minute');
INSERT INTO CWMS_INTERVAL VALUES (32, '~2Minutes', 0, 'Local time irregular: expected recurrence interval of 2 minutes');
INSERT INTO CWMS_INTERVAL VALUES (33, '~3Minutes', 0, 'Local time irregular: expected recurrence interval of 3 minutes');
INSERT INTO CWMS_INTERVAL VALUES (34, '~4Minutes', 0, 'Local time irregular: expected recurrence interval of 4 minutes');
INSERT INTO CWMS_INTERVAL VALUES (35, '~5Minutes', 0, 'Local time irregular: expected recurrence interval of 5 minutes');
INSERT INTO CWMS_INTERVAL VALUES (36, '~6Minutes', 0, 'Local time irregular: expected recurrence interval of 6 minutes');
INSERT INTO CWMS_INTERVAL VALUES (37, '~8Minutes', 0, 'Local time irregular: expected recurrence interval of 8 minutes');
INSERT INTO CWMS_INTERVAL VALUES (38, '~10Minutes', 0, 'Local time irregular: expected recurrence interval of 10 minutes');
INSERT INTO CWMS_INTERVAL VALUES (39, '~12Minutes', 0, 'Local time irregular: expected recurrence interval of 12 minutes');
INSERT INTO CWMS_INTERVAL VALUES (40, '~15Minutes', 0, 'Local time irregular: expected recurrence interval of 15 minutes');
INSERT INTO CWMS_INTERVAL VALUES (41, '~20Minutes', 0, 'Local time irregular: expected recurrence interval of 20 minutes');
INSERT INTO CWMS_INTERVAL VALUES (42, '~30Minutes', 0, 'Local time irregular: expected recurrence interval of 30 minutes');
INSERT INTO CWMS_INTERVAL VALUES (43, '~1Hour', 0, 'Local time irregular: expected recurrence interval of 1 hour');
INSERT INTO CWMS_INTERVAL VALUES (44, '~2Hours', 0, 'Local time irregular: expected recurrence interval of 2 hours');
INSERT INTO CWMS_INTERVAL VALUES (45, '~3Hours', 0, 'Local time irregular: expected recurrence interval of 3 hours');
INSERT INTO CWMS_INTERVAL VALUES (46, '~4Hours', 0, 'Local time irregular: expected recurrence interval of 4 hours');
INSERT INTO CWMS_INTERVAL VALUES (47, '~6Hours', 0, 'Local time irregular: expected recurrence interval of 6 hours');
INSERT INTO CWMS_INTERVAL VALUES (48, '~8Hours', 0, 'Local time irregular: expected recurrence interval of 8 hours');
INSERT INTO CWMS_INTERVAL VALUES (49, '~12Hours', 0, 'Local time irregular: expected recurrence interval of 12 hours');
INSERT INTO CWMS_INTERVAL VALUES (50, '~1Day', 0, 'Local time irregular: expected recurrence interval of 1 day');
INSERT INTO CWMS_INTERVAL VALUES (51, '~2Days', 0, 'Local time irregular: expected recurrence interval of 2 days');
INSERT INTO CWMS_INTERVAL VALUES (52, '~3Days', 0, 'Local time irregular: expected recurrence interval of 3 days');
INSERT INTO CWMS_INTERVAL VALUES (53, '~4Days', 0, 'Local time irregular: expected recurrence interval of 4 days');
INSERT INTO CWMS_INTERVAL VALUES (54, '~5Days', 0, 'Local time irregular: expected recurrence interval of 5 days');
INSERT INTO CWMS_INTERVAL VALUES (55, '~6Days', 0, 'Local time irregular: expected recurrence interval of 6 days');
INSERT INTO CWMS_INTERVAL VALUES (56, '~1Week', 0, 'Local time irregular: expected recurrence interval of 1 week');
INSERT INTO CWMS_INTERVAL VALUES (57, '~1Month', 0, 'Local time irregular: expected recurrence interval of 1 month');
INSERT INTO CWMS_INTERVAL VALUES (58, '~1Year', 0, 'Local time irregular: expected recurrence interval of 1 year');
INSERT INTO CWMS_INTERVAL VALUES (59, '~1Decade', 0, 'Local time irregular: expected recurrence interval of 1 decade');
INSERT INTO CWMS_INTERVAL VALUES (1, '1Minute', 1, 'Regular recurrence interval of 1 minute');
INSERT INTO CWMS_INTERVAL VALUES (2, '2Minutes', 2, 'Regular recurrence interval of 2 minutes');
INSERT INTO CWMS_INTERVAL VALUES (3, '3Minutes', 3, 'Regular recurrence interval of 3 minutes');
INSERT INTO CWMS_INTERVAL VALUES (4, '4Minutes', 4, 'Regular recurrence interval of 4 minutes');
INSERT INTO CWMS_INTERVAL VALUES (5, '5Minutes', 5, 'Regular recurrence interval of 5 minutes');
INSERT INTO CWMS_INTERVAL VALUES (6, '6Minutes', 6, 'Regular recurrence interval of 6 minutes');
INSERT INTO CWMS_INTERVAL VALUES (7, '8Minutes', 8, 'Regular recurrence interval of 8 minutes');
INSERT INTO CWMS_INTERVAL VALUES (30, '10Minutes', 10, 'Regular recurrence interval of 10 minutes');
INSERT INTO CWMS_INTERVAL VALUES (8, '12Minutes', 12, 'Regular recurrence interval of 12 minutes');
INSERT INTO CWMS_INTERVAL VALUES (9, '15Minutes', 15, 'Regular recurrence interval of 15 minutes');
INSERT INTO CWMS_INTERVAL VALUES (10, '20Minutes', 20, 'Regular recurrence interval of 20 minutes');
INSERT INTO CWMS_INTERVAL VALUES (11, '30Minutes', 30, 'Regular recurrence interval of 30 minutes');
INSERT INTO CWMS_INTERVAL VALUES (12, '1Hour', 60, 'Regular recurrence interval of 1 hour');
INSERT INTO CWMS_INTERVAL VALUES (13, '2Hours', 120, 'Regular recurrence interval of 2 hours');
INSERT INTO CWMS_INTERVAL VALUES (14, '3Hours', 180, 'Regular recurrence interval of 3 hours');
INSERT INTO CWMS_INTERVAL VALUES (15, '4Hours', 240, 'Regular recurrence interval of 4 hours');
INSERT INTO CWMS_INTERVAL VALUES (16, '6Hours', 360, 'Regular recurrence interval of 6 hours');
INSERT INTO CWMS_INTERVAL VALUES (17, '8Hours', 480, 'Regular recurrence interval of 8 hours');
INSERT INTO CWMS_INTERVAL VALUES (18, '12Hours', 720, 'Regular recurrence interval of 12 hours');
INSERT INTO CWMS_INTERVAL VALUES (19, '1Day', 1440, 'Regular recurrence interval of 1 day');
INSERT INTO CWMS_INTERVAL VALUES (20, '2Days', 2880, 'Regular recurrence interval of 2 days');
INSERT INTO CWMS_INTERVAL VALUES (21, '3Days', 4320, 'Regular recurrence interval of 3 days');
INSERT INTO CWMS_INTERVAL VALUES (22, '4Days', 5760, 'Regular recurrence interval of 4 days');
INSERT INTO CWMS_INTERVAL VALUES (23, '5Days', 7200, 'Regular recurrence interval of 5 days');
INSERT INTO CWMS_INTERVAL VALUES (24, '6Days', 8640, 'Regular recurrence interval of 6 days');
INSERT INTO CWMS_INTERVAL VALUES (25, '1Week', 10080, 'Regular recurrence interval of 1 week');
INSERT INTO CWMS_INTERVAL VALUES (26, '1Month', 43200, 'Regular recurrence interval of 1 month');
INSERT INTO CWMS_INTERVAL VALUES (27, '1Year', 525600, 'Regular recurrence interval of 1 year');
INSERT INTO CWMS_INTERVAL VALUES (28, '1Decade', 5256000, 'Regular recurrence interval of 1 decade');


INSERT INTO CWMS_DURATION VALUES (1, '1Minute', 1, 'Measurement applies over 1 minute, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (2, '2Minutes', 2, 'Measurement applies over 2 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (3, '3Minutes', 3, 'Measurement applies over 3 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (4, '4Minutes', 4, 'Measurement applies over 4 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (5, '5Minutes', 5, 'Measurement applies over 5 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (6, '6Minutes', 6, 'Measurement applies over 6 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (7, '8Minutes', 8, 'Measurement applies over 8 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (8, '12Minutes', 12, 'Measurement applies over 12 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (9, '15Minutes', 15, 'Measurement applies over 15 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (10, '20Minutes', 20, 'Measurement applies over 20 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (11, '30Minutes', 30, 'Measurement applies over 30 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (12, '1Hour', 60, 'Measurement applies over 1 hour, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (13, '2Hours', 120, 'Measurement applies over 2 hours, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (14, '3Hours', 180, 'Measurement applies over 3 hours, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (15, '4Hours', 240, 'Measurement applies over 4 hours, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (16, '6Hours', 360, 'Measurement applies over 6 hours, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (17, '8Hours', 480, 'Measurement applies over 8 hours, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (18, '12Hours', 720, 'Measurement applies over 12 hours, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (19, '1Day', 1440, 'Measurement applies over 1 day, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (20, '2Days', 2880, 'Measurement applies over 2 days, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (21, '3Days', 4320, 'Measurement applies over 3 days, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (22, '4Days', 5760, 'Measurement applies over 4 days, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (23, '5Days', 7200, 'Measurement applies over 5 days, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (24, '6Days', 8640, 'Measurement applies over 6 days, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (25, '1Week', 10080, 'Measurement applies over 1 week, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (26, '1Month', 43200, 'Measurement applies over 1 month, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (27, '1Year', 525600, 'Measurement applies over 1 year, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (28, '1Decade', 5256000, 'Measurement applies over 1 decade, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (29, '0', 0, 'Measurement applies intantaneously at time stamp or from previous time stamp');
INSERT INTO CWMS_DURATION VALUES (30, '1MinuteBOP', 1, 'Measurement applies over 1 minute, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (31, '2MinutesBOP', 2, 'Measurement applies over 2 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (32, '3MinutesBOP', 3, 'Measurement applies over 3 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (33, '4MinutesBOP', 4, 'Measurement applies over 4 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (34, '5MinutesBOP', 5, 'Measurement applies over 5 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (35, '6MinutesBOP', 6, 'Measurement applies over 1 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (36, '8MinutesBOP', 8, 'Measurement applies over 8 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (37, '12MinutesBOP', 12, 'Measurement applies over 12 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (38, '15MinutesBOP', 15, 'Measurement applies over 15 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (39, '20MinutesBOP', 20, 'Measurement applies over 20 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (40, '30MinutesBOP', 30, 'Measurement applies over 30 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (41, '1HourBOP', 60, 'Measurement applies over 1 hour, time stamped at period beginnng');
INSERT INTO CWMS_DURATION VALUES (42, '2HoursBOP', 120, 'Measurement applies over 2 hours, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (43, '3HoursBOP', 180, 'Measurement applies over 3 hours, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (44, '4HoursBOP', 240, 'Measurement applies over 4 hours, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (45, '6HoursBOP', 360, 'Measurement applies over 6 hours, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (46, '8HoursBOP', 480, 'Measurement applies over 8 hours, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (47, '12HoursBOP', 720, 'Measurement applies over 12 hours, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (48, '1DayBOP', 1440, 'Measurement applies over 1 day, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (49, '2DaysBOP', 2880, 'Measurement applies over 2 days, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (50, '3DaysBOP', 4320, 'Measurement applies over 3 days, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (51, '4DaysBOP', 5760, 'Measurement applies over 4 days, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (52, '5DaysBOP', 7200, 'Measurement applies over 5 days, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (53, '6DaysBOP', 8640, 'Measurement applies over 6 days, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (54, '1WeekBOP', 10080, 'Measurement applies over 1 week, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (55, '1MonthBOP', 43200, 'Measurement applies over 1 month, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (56, '1YearBOP', 525600, 'Measurement applies over 1 year, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (57, '1DecadeBOP', 5256000, 'Measurement applies over 1 decade, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (58, '10Minutes', 10, 'Measurement applies over 10 minutes, time stamped at period end');
INSERT INTO CWMS_DURATION VALUES (59, '10MinutesBOP', 10, 'Measurement applies over 10 minutes, time stamped at period beginning');
INSERT INTO CWMS_DURATION VALUES (60, '0BOP', 0, 'Measurement applies intantaneously at time stamp or until next time stamp');


INSERT INTO CWMS_SHEF_DURATION VALUES ('I', 'Instantaneous', '0', 29);
INSERT INTO CWMS_SHEF_DURATION VALUES ('U', '1 Minute', '1', 1);
INSERT INTO CWMS_SHEF_DURATION VALUES ('C', '15 Minutes', '15', 9);
INSERT INTO CWMS_SHEF_DURATION VALUES ('J', '30 Minutes', '30', 11);
INSERT INTO CWMS_SHEF_DURATION VALUES ('H', '1 Hour', '1001', 12);
INSERT INTO CWMS_SHEF_DURATION VALUES ('B', '2 Hour', '1002', 13);
INSERT INTO CWMS_SHEF_DURATION VALUES ('T', '3 Hour', '1003', 14);
INSERT INTO CWMS_SHEF_DURATION VALUES ('F', '4 Hour', '1004', 15);
INSERT INTO CWMS_SHEF_DURATION VALUES ('Q', '6 Hour', '1006', 16);
INSERT INTO CWMS_SHEF_DURATION VALUES ('A', '8 Hour', '1008', 17);
INSERT INTO CWMS_SHEF_DURATION VALUES ('K', '12 Hour', '1012', 18);
INSERT INTO CWMS_SHEF_DURATION VALUES ('L', '18 Hour', '1018', NULL);
INSERT INTO CWMS_SHEF_DURATION VALUES ('D', '1 Day', '2001', 19);
INSERT INTO CWMS_SHEF_DURATION VALUES ('W', '1 Week', '2007', 25);
INSERT INTO CWMS_SHEF_DURATION VALUES ('N', 'Mid month, duration for the period from the 1st day of the month to and ending on the 15th day of the same month', NULL, NULL);
INSERT INTO CWMS_SHEF_DURATION VALUES ('M', '1 Month', '3001', 26);
INSERT INTO CWMS_SHEF_DURATION VALUES ('Y', '1 Year', '4001', 27);
INSERT INTO CWMS_SHEF_DURATION VALUES ('P', 'Duration for a period beginning at previous 7 a.m. local and ending at time of observation', '5004', 19);
INSERT INTO CWMS_SHEF_DURATION VALUES ('V', 'Variable period, duration defined separately (see Tables 11a and 11b) 1/', NULL, NULL);
INSERT INTO CWMS_SHEF_DURATION VALUES ('S', 'Period of seasonal duration (normally used to designate a partial period, for example, 1 January to current date)', '5001', NULL);
INSERT INTO CWMS_SHEF_DURATION VALUES ('R', 'Entire period of record', '5002', NULL);
INSERT INTO CWMS_SHEF_DURATION VALUES ('X', 'Unknown duration', '5005', NULL);
INSERT INTO CWMS_SHEF_DURATION VALUES ('Z', 'Filler character, pointer to default duration for that physical element as shown in Table 7.', NULL, NULL);


INSERT INTO CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (
	1,
	'Total',
	'TOTAL'
);
INSERT INTO CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (
	2,
	'Max',
	'MAXIMUM'
);
INSERT INTO CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (
	3,
	'Min',
	'MINIMUM'
);
INSERT INTO CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (
	4,
	'Const',
	'CONSTANT'
);
INSERT INTO CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (
	5,
	'Ave',
	'AVERAGE'
);
INSERT INTO CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE, PARAMETER_TYPE_ID, DESCRIPTION) VALUES (
	6,
	'Inst',
	'INSTANTANEOUS'
);


INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	1,
	'%',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='%'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='%'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='%'
	),
	'Percent',
	'Ratio expressed as hundredths'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	2,
	'Area',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Area'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m2'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m2'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft2'
	),
	'Surface Area',
	'Area of a surface'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	3,
	'Dir',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Angle'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='deg'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='deg'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='deg'
	),
	'Direction',
	'Map direction specified clockwise from North'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	4,
	'Code',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	'Coded Information',
	'Numeric code symbolically representing a phenomenon'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	5,
	'Conc',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Mass Concentration'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mg/l'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mg/l'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ppm'
	),
	'Concentration',
	'Relative content of a component dissolved or dispersed in a volume of water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	6,
	'Cond',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Conductivity'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='umho/cm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='umho/cm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='umho/cm'
	),
	'Conductivity',
	'Ability of an aqueous solution to conduct electricity'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	7,
	'Count',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Count'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='unit'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='unit'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='unit'
	),
	'Count',
	'Progressive sum of items enumerated one by one or group by group.'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	8,
	'Currency',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Currency'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='$'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='$'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='$'
	),
	'Currency',
	'Economic value expressed as currency/money'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	9,
	'Depth',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in'
	),
	'Depth',
	'Depth of any form of water above the ground surface'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	10,
	'Elev',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Elevation',
	'The height of a surface above a datum which approximates sea level'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	11,
	'Energy',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Energy'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='MWh'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='MWh'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='MWh'
	),
	'Energy',
	'Energy, work, or quantity of heat'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	12,
	'Evap',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in'
	),
	'Evaporation',
	'Liquid water lost to vapor measured as an equivalent depth of liquid water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	13,
	'EvapRate',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Linear Speed'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm/day'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm/day'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in/day'
	),
	'Evaporation Rate',
	'Rate of liquid water evaporation'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	14,
	'Flow',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Volume Rate'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cms'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cms'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cfs'
	),
	'Flow Rate',
	'Volume rate of moving water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	15,
	'Frost',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in'
	),
	'Ground Frost',
	'Depth of frost penetration into the ground (non-permafrost)'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	16,
	'Opening',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Opening Height',
	'Height of opening controlling passage of water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	17,
	'pH',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Hydrogen Ion Concentration Index'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='su'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='su'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='su'
	),
	'pH',
	'Negative logarithm of hydrogen-ion concentration in a solution'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	18,
	'Power',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Power'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='MW'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='MW'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='MW'
	),
	'Power',
	'Energy rate, Radiant Flux'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	19,
	'Precip',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in'
	),
	'Precipitation',
	'Deposit on the earth of hail, mist, rain, sleet, or snow'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	20,
	'Pres',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Pressure'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='kPa'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='kPa'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in-hg'
	),
	'Pressure',
	'Pressure (force per unit area)'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	21,
	'Rad',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Irradiation'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='J/m2'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='J/m2'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='langley'
	),
	'Irradiation',
	'Radiant energy on a unit area of irradiated surface.'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	22,
	'Speed',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Linear Speed'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='kph'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='kph'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mph'
	),
	'Speed',
	'Rate of moving substance or object irrespective of direction'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	23,
	'Stage',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Stage',
	'The height of a water surface above a designated datum other than sea level'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	24,
	'Stor',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Volume'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m3'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m3'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ac-ft'
	),
	'Storage',
	'Volume of impounded water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	25,
	'Temp',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Temperature'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='C'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='C'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='F'
	),
	'Temperature',
	'Hotness or coldness of a substance based on measuring expansion of mercury'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	26,
	'Thick',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='cm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='in'
	),
	'Thickness',
	'Thickness of sheet of substance'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	27,
	'Timing',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Elapsed Time'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='sec'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='sec'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='sec'
	),
	'Timing',
	'A duration of a phenomenon'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	28,
	'Turb',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Turbidity'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='JTU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='JTU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='JTU'
	),
	'Turbidity',
	'Measurement of interference to the passage of light by matter in suspension'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	29,
	'Volt',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Electromotive Potential'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='volt'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='volt'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='volt'
	),
	'Voltage',
	'Electric Potential'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	30,
	'Travel',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='km'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='km'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mi'
	),
	'Accumulated Travel',
	'Accumulated movement of a fluid past a point'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	31,
	'SpinRate',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Angular Speed'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='rpm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='rpm'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='rpm'
	),
	'Spin Rate',
	'Number of revolutions made about an axis per unit of time'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	32,
	'Irrad',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Irradiance'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='W/m2'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='W/m2'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='langley/min'
	),
	'Irradiance',
	'Radiant Power on a unit area of irradiated surface.'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	33,
	'TurbJ',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Turbidity'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='JTU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='JTU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='JTU'
	),
	'Turbidity',
	'Measurement of interference to the passage of light by matter in suspension'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	34,
	'TurbN',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Turbidity'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='NTU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='NTU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='NTU'
	),
	'Turbidity',
	'Measurement of scattered light at an angle of 90+/-30 degrees to the incident light beam from a white light source (540+/-140 nm) (EPA method 180.1)'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	35,
	'Fish',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Count'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='unit'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='unit'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='unit'
	),
	'Fish Count',
	'Fish Count.'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	36,
	'Dist',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='km'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='km'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='mi'
	),
	'Distance',
	'Distance between two points.'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	37,
	'Ratio',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	'Ratio',
	'Quotient of two numbers having the same units'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	38,
	'TurbF',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Turbidity'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='FNU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='FNU'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='FNU'
	),
	'Turbidity',
	'Measurement of scattered light at an angle of 90+/-2.5 degrees to the incident light beam from a monochromatic light source (860+/-60 nm) (ISO 7027)'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	39,
	'Volume',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Volume'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m3'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m3'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft3'
	),
	'Volume',
	'Volume of anything other than impounded water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	40,
	'Height',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Height',
	'The height of a surface above an arbitrary datum'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	41,
	'Rotation',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Angle'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='deg'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='deg'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='deg'
	),
	'Rotation',
	'Angular displacement'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	42,
	'Length',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Length',
	'Linear displacement associated with the larger horizontal planar measurment'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	43,
	'Width',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Width',
	'Linear displacement associated with the smaller horizontal planar measurment'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	44,
	'Coeff',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	'Coefficient',
	'Unitless coefficient for formulas'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	45,
	'Head',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Length'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='m'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ft'
	),
	'Head',
	'Difference between two elevations in a column of water'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	46,
	'Current',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Electric Charge Rate'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ampere'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ampere'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='ampere'
	),
	'Current',
	'Electric current flowing past a point in a circuit'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	47,
	'Freq',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='Frequency'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='Hz'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='Hz'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='Hz'
	),
	'Frequency',
	'The number of cycles or occurrences per time unit'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	48,
	'Probability',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	'Probability',
	'Expected fraction of all events for a specific event'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	-1,
	'Text',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	'Text Data',
	'Text data only, no numeric values'
);
INSERT INTO CWMS_BASE_PARAMETER (BASE_PARAMETER_CODE, BASE_PARAMETER_ID, ABSTRACT_PARAM_CODE, UNIT_CODE, DISPLAY_UNIT_CODE_SI, DISPLAY_UNIT_CODE_EN, LONG_NAME, DESCRIPTION) VALUES (
	-2,
	'Binary',
	(	SELECT ABSTRACT_PARAM_CODE
		FROM   CWMS_ABSTRACT_PARAMETER
		WHERE  ABSTRACT_PARAM_ID='None'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	(	SELECT U.UNIT_CODE
		FROM CWMS_UNIT U
		WHERE U.UNIT_ID='n/a'
	),
	'Binary Data',
	'Binary data such as images, documents, etc...'
);



    INSERT INTO at_parameter
       SELECT base_parameter_code, (SELECT office_code
                                      FROM cwms_office
                                     WHERE office_id = 'CWMS'),
              base_parameter_code, NULL, cbp.long_name
         FROM cwms_base_parameter cbp
    /

    INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	301,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='%'
	),
	'ofArea-Snow',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Percent of Area Covered by Snow'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	302,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='%'
	),
	'Opening',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Percent Open'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	303,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Conc'
	),
	'Acidity',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Acidity Concentration'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	304,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Conc'
	),
	'Alkalinity',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Alkalinity Concentration'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	305,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Conc'
	),
	'DO',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Disolved Oxygen Concentration'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	306,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Conc'
	),
	'Iron',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Iron Concentration'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	307,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Conc'
	),
	'Sulfate',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Sulfate Concentration'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	308,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Conc'
	),
	'Salinity',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Salinity Concentration'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	309,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Depth'
	),
	'Snow',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Snow Depth'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	310,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Depth'
	),
	'SnowWE',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Snow Water Equivalance'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	311,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Flow'
	),
	'In',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Inflow'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	312,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Flow'
	),
	'Out',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Outflow'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	313,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Flow'
	),
	'Reg',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Regulated Flow'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	314,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Flow'
	),
	'Spill',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Spillway Flow'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	315,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Flow'
	),
	'Unreg',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Unregulated Flow'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	316,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Temp'
	),
	'Air',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Air Temperature'
);
INSERT INTO AT_PARAMETER (PARAMETER_CODE, BASE_PARAMETER_CODE, SUB_PARAMETER_ID, DB_OFFICE_CODE, SUB_PARAMETER_DESC) VALUES (
	317,
	(	SELECT BASE_PARAMETER_CODE
		FROM   CWMS_BASE_PARAMETER
		WHERE  BASE_PARAMETER_ID='Temp'
	),
	'Water',
	(	SELECT OFFICE_CODE
		FROM CWMS_OFFICE U
		WHERE OFFICE_ID='CWMS'
	),
	'Water Temperature'
);


DECLARE
BEGIN
   INSERT INTO at_display_units
      SELECT 44, a.parameter_code, 'EN', b.display_unit_code_en
        FROM at_parameter a, cwms_base_parameter b
       WHERE a.base_parameter_code = b.base_parameter_code
         AND a.sub_parameter_id IS NULL;

   INSERT INTO at_display_units
      SELECT 44, a.parameter_code, 'SI', b.display_unit_code_si
        FROM at_parameter a, cwms_base_parameter b
       WHERE a.base_parameter_code = b.base_parameter_code
         AND a.sub_parameter_id IS NULL;
END;
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 301, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 301)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 301, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 301)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 302, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 302)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 302, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 302)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 303, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 303)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 303, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 303)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 304, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 304)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 304, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 304)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 305, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 305)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 305, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 305)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 306, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 306)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 306, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 306)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 307, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 307)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 307, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 307)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 308, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'g/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 308)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 308, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'g/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 308)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 309, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 309)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 309, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'in'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 309)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 310, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 310)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 310, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'in'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 310)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 311, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 311)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 311, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 311)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 312, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 312)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 312, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 312)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 313, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 313)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 313, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 313)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 314, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 314)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 314, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 314)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 315, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 315)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 315, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 315)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 316, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'C'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 316)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 316, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'F'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 316)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 317, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'C'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 317)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 317, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'F'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 317)
            )
/


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


INSERT INTO CWMS_DSS_PARAMETER_TYPE (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (
	1,
	'PER-AVER',
	(	SELECT PARAMETER_TYPE_CODE
		FROM   CWMS_PARAMETER_TYPE
		WHERE  PARAMETER_TYPE_ID='Ave'
	),
	'Average over a period'
);
INSERT INTO CWMS_DSS_PARAMETER_TYPE (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (
	2,
	'PER-CUM',
	(	SELECT PARAMETER_TYPE_CODE
		FROM   CWMS_PARAMETER_TYPE
		WHERE  PARAMETER_TYPE_ID='Total'
	),
	'Accumulation over a period'
);
INSERT INTO CWMS_DSS_PARAMETER_TYPE (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (
	3,
	'INST-VAL',
	(	SELECT PARAMETER_TYPE_CODE
		FROM   CWMS_PARAMETER_TYPE
		WHERE  PARAMETER_TYPE_ID='Inst'
	),
	'Value observed at an instant'
);
INSERT INTO CWMS_DSS_PARAMETER_TYPE (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (
	4,
	'INST-CUM',
	(	SELECT PARAMETER_TYPE_CODE
		FROM   CWMS_PARAMETER_TYPE
		WHERE  PARAMETER_TYPE_ID='Inst'
	),
	'Accumulation observed at an instant'
);
INSERT INTO CWMS_DSS_PARAMETER_TYPE (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (
	5,
	'PER-MIN',
	(	SELECT PARAMETER_TYPE_CODE
		FROM   CWMS_PARAMETER_TYPE
		WHERE  PARAMETER_TYPE_ID='Min'
	),
	'Minumum over a period'
);
INSERT INTO CWMS_DSS_PARAMETER_TYPE (DSS_PARAMETER_TYPE_CODE, DSS_PARAMETER_TYPE_ID, PARAMETER_TYPE_CODE, DESCRIPTION) VALUES (
	6,
	'PER-MAX',
	(	SELECT PARAMETER_TYPE_CODE
		FROM   CWMS_PARAMETER_TYPE
		WHERE  PARAMETER_TYPE_ID='Max'
	),
	'Maximum over a period'
);



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
