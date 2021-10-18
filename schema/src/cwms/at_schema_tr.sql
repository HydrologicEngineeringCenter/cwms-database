SET define on
@@defines.sql

/* Formatted on 2008/06/24 04:39 (Formatter Plus v4.8.8) */
--******************************
--******************************
--------------------------------

CREATE TABLE "&cwms_schema"."CWMS_TR_TRANSFORMATIONS"
(
  transform_id  VARCHAR2(32 BYTE)               NOT NULL,
  description   VARCHAR2(256 BYTE)              NOT NULL
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
CREATE UNIQUE INDEX "&cwms_schema"."CWMS_TR_TRANSFORMATIONS_PK" ON "&cwms_schema"."CWMS_TR_TRANSFORMATIONS"
(transform_id)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
CREATE UNIQUE INDEX "&cwms_schema"."CWMS_TR_TRANSFORMATIONS_UI01" ON "&cwms_schema"."CWMS_TR_TRANSFORMATIONS"
(UPPER("TRANSFORM_ID"))
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
ALTER TABLE "&cwms_schema"."CWMS_TR_TRANSFORMATIONS" ADD (
  CONSTRAINT cwms_tr_transformations_pk
 PRIMARY KEY
 (transform_id)
    USING INDEX
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/

INSERT INTO "&cwms_schema"."CWMS_TR_TRANSFORMATIONS"
            (transform_id, description
            )
     VALUES ('Validation', 'Triggers a Validation, if validation criteria.'
            );
INSERT INTO "&cwms_schema"."CWMS_TR_TRANSFORMATIONS"
            (transform_id,
             description
            )
     VALUES ('Scaling',
             'Applies scaling factors as reflected in y = (x + a) b + c'
            );
INSERT INTO "&cwms_schema"."CWMS_TR_TRANSFORMATIONS"
            (transform_id,
             description
            )
     VALUES ('Lookup Table',
             'Applies a 1 or 2 parameter lookup table against a dependant variable. Lookup table can either be a single table or a set of tables over time, e.g., a set of stage/flow tables that change over time.'
            );
COMMIT ;



--************************
--************************
------------------

SET define on
CREATE TABLE "&cwms_schema"."AT_TR_TEMPLATE_ID"
(
  template_code             NUMBER,
  template_id               VARCHAR2(32 BYTE)   NOT NULL,
  db_office_code            NUMBER              NOT NULL,
  primary_indep_param_code  NUMBER,
  dep_param_code            NUMBER,
  description               VARCHAR2(132 BYTE),
  seed_version_suffix       VARCHAR2(32 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
CREATE UNIQUE INDEX "&cwms_schema"."AT_TR_TEMPLATE_ID_PK" ON "&cwms_schema"."AT_TR_TEMPLATE_ID"
(template_code)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
CREATE UNIQUE INDEX "&cwms_schema"."AT_TR_TEMPLATE_ID_UQ01" ON "&cwms_schema"."AT_TR_TEMPLATE_ID"
(UPPER("TEMPLATE_ID"), db_office_code)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
ALTER TABLE "&cwms_schema"."AT_TR_TEMPLATE_ID" ADD (
  CONSTRAINT at_tr_template_id_pk
 PRIMARY KEY
 (template_code)
    USING INDEX
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/
ALTER TABLE "&cwms_schema"."AT_TR_TEMPLATE_ID" ADD (
  CONSTRAINT at_tr_template_id_r01
 FOREIGN KEY (db_office_code)
 REFERENCES "&cwms_schema"."CWMS_OFFICE" (office_code),
  CONSTRAINT at_tr_template_id_r02
 FOREIGN KEY (primary_indep_param_code)
 REFERENCES "&cwms_schema"."AT_PARAMETER" (parameter_code),
  CONSTRAINT at_tr_template_id_r03
 FOREIGN KEY (dep_param_code)
 REFERENCES "&cwms_schema"."AT_PARAMETER" (parameter_code))
/
--************************
--------------------------
--************************



CREATE TABLE "&cwms_schema"."AT_TR_TEMPLATE_SET"
(
  template_code          NUMBER,
  sequence_no            NUMBER,
  description            VARCHAR2(132 BYTE),
  store_dep_flag         VARCHAR2(1 BYTE),
  unit_system            VARCHAR2(2 BYTE),
  transform_id           VARCHAR2(32 BYTE),
  lookup_agency          VARCHAR2(32 BYTE),
  lookup_rating_version  VARCHAR2(32 BYTE),
  scaling_arg_a          NUMBER,
  scaling_arg_b          NUMBER,
  scaling_arg_c          NUMBER
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
COMMENT ON COLUMN "&cwms_schema"."AT_TR_TEMPLATE_SET"."DESCRIPTION" IS 'description is of AT_TR_TEMPLATE_SET'
/
COMMENT ON COLUMN "&cwms_schema"."AT_TR_TEMPLATE_SET"."STORE_DEP_FLAG" IS 'If T, then dependent variable is store to database, else it''s simply available for the next transform.'
/
COMMENT ON COLUMN "&cwms_schema"."AT_TR_TEMPLATE_SET"."UNIT_SYSTEM" IS 'Either SI or EN or null - null indicates that the computation is not system dependant (which means it will really be done in the SI system).'
/
CREATE UNIQUE INDEX "&cwms_schema"."AT_TR_TEMPLATE_SET_PK" ON "&cwms_schema"."AT_TR_TEMPLATE_SET"
(template_code, sequence_no)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
ALTER TABLE "&cwms_schema"."AT_TR_TEMPLATE_SET" ADD (
  CONSTRAINT at_tr_template_set_pk
 PRIMARY KEY
 (template_code, sequence_no)
    USING INDEX
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/
ALTER TABLE "&cwms_schema"."AT_TR_TEMPLATE_SET" ADD (
  CONSTRAINT at_tr_template_set_r01
 FOREIGN KEY (template_code)
 REFERENCES "&cwms_schema"."AT_TR_TEMPLATE_ID" (template_code),
  CONSTRAINT at_tr_template_set_r02
 FOREIGN KEY (transform_id)
 REFERENCES "&cwms_schema"."CWMS_TR_TRANSFORMATIONS" (transform_id))
/


--************************
--------------------------
--************************


CREATE TABLE "&cwms_schema"."AT_TR_TS_MASK"
(
  template_code        NUMBER,
  sequence_no          NUMBER,
  variable_no          NUMBER,
  location_code        NUMBER,
  parameter_code       NUMBER,
  parameter_type_code  NUMBER,
  interval_code        NUMBER,
  duration_code        NUMBER,
  version_mask         VARCHAR2(42 BYTE)
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
CREATE UNIQUE INDEX "&cwms_schema"."AT_TR_TS_MASK_PK" ON "&cwms_schema"."AT_TR_TS_MASK"
(template_code, sequence_no, variable_no)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
ALTER TABLE "&cwms_schema"."AT_TR_TS_MASK" ADD (
  CONSTRAINT at_tr_ts_mask_pk
 PRIMARY KEY
 (template_code, sequence_no, variable_no)
    USING INDEX
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/
ALTER TABLE "&cwms_schema"."AT_TR_TS_MASK" ADD (
  CONSTRAINT at_tr_ts_mask_r01
 FOREIGN KEY (template_code, sequence_no)
 REFERENCES "&cwms_schema"."AT_TR_TEMPLATE_SET" (template_code,sequence_no),
  CONSTRAINT at_tr_ts_mask1_r02
 FOREIGN KEY (location_code)
 REFERENCES "&cwms_schema"."AT_PHYSICAL_LOCATION" (location_code),
  CONSTRAINT at_tr_ts_mask1_r03
 FOREIGN KEY (parameter_code)
 REFERENCES "&cwms_schema"."AT_PARAMETER" (parameter_code),
  CONSTRAINT at_tr_ts_mask1_r04
 FOREIGN KEY (parameter_type_code)
 REFERENCES "&cwms_schema"."CWMS_PARAMETER_TYPE" (parameter_type_code),
  CONSTRAINT at_tr_ts_mask1_r05
 FOREIGN KEY (interval_code)
 REFERENCES "&cwms_schema"."CWMS_INTERVAL" (interval_code),
  CONSTRAINT at_tr_ts_mask1_r06
 FOREIGN KEY (duration_code)
 REFERENCES "&cwms_schema"."CWMS_DURATION" (duration_code))
/
--************************
--------------------------
--************************


CREATE TABLE "&cwms_schema"."AT_TR_TEMPLATE"
(
  ts_code_indep_1  NUMBER,
  template_code    NUMBER,
  active_flag      VARCHAR2(1 BYTE)             NOT NULL,
  event_trigger    VARCHAR2(32 BYTE)            NOT NULL
)
tablespace CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
CREATE UNIQUE INDEX "&cwms_schema"."AT_TR_TEMPLATE_PK" ON "&cwms_schema"."AT_TR_TEMPLATE"
(ts_code_indep_1, template_code)
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
ALTER TABLE "&cwms_schema"."AT_TR_TEMPLATE" ADD (
  CONSTRAINT at_tr_template_pk
 PRIMARY KEY
 (ts_code_indep_1, template_code)
    USING INDEX
    tablespace CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
               ))
/
ALTER TABLE "&cwms_schema"."AT_TR_TEMPLATE" ADD (
  CONSTRAINT at_tr_template_r01
 FOREIGN KEY (template_code)
 REFERENCES "&cwms_schema"."AT_TR_TEMPLATE_ID" (template_code),
  CONSTRAINT at_tr_template_r02
 FOREIGN KEY (ts_code_indep_1)
 REFERENCES "&cwms_schema"."AT_CWMS_TS_SPEC" (ts_code))
/