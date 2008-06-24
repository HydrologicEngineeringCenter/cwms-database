/* Formatted on 2008/06/24 04:39 (Formatter Plus v4.8.8) */
--******************************
--******************************
--------------------------------

CREATE TABLE cwms_20.cwms_tr_transformations
(
  transform_id  VARCHAR2(32 BYTE)               NOT NULL,
  description   VARCHAR2(256 BYTE)              NOT NULL
)
TABLESPACE cwms_20data
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
CREATE UNIQUE INDEX cwms_20.cwms_tr_transformations_pk ON cwms_20.cwms_tr_transformations
(transform_id)
LOGGING
TABLESPACE cwms_20data
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
CREATE UNIQUE INDEX cwms_20.cwms_tr_transformations_ui01 ON cwms_20.cwms_tr_transformations
(UPPER("TRANSFORM_ID"))
LOGGING
TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.cwms_tr_transformations ADD (
  CONSTRAINT cwms_tr_transformations_pk
 PRIMARY KEY
 (transform_id)
    USING INDEX
    TABLESPACE cwms_20data
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
SET DEFINE OFF;
INSERT INTO cwms_20.cwms_tr_transformations
            (transform_id, description
            )
     VALUES ('Validation', 'Triggers a Validation, if validation criteria.'
            );
INSERT INTO cwms_20.cwms_tr_transformations
            (transform_id,
             description
            )
     VALUES ('Scaling',
             'Applies scaling factors as reflected in y = (x + a) b + c'
            );
INSERT INTO cwms_20.cwms_tr_transformations
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


CREATE TABLE cwms_20.at_tr_template_id
(
  template_code             NUMBER,
  template_id               VARCHAR2(32 BYTE)   NOT NULL,
  db_office_code            NUMBER              NOT NULL,
  primary_indep_param_code  NUMBER,
  dep_param_code            NUMBER,
  description               VARCHAR2(132 BYTE),
  seed_version_suffix       VARCHAR2(32 BYTE)
)
TABLESPACE cwms_20data
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
CREATE UNIQUE INDEX cwms_20.at_tr_template_id_pk ON cwms_20.at_tr_template_id
(template_code)
LOGGING
TABLESPACE cwms_20data
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
CREATE UNIQUE INDEX cwms_20.at_tr_template_id_uq01 ON cwms_20.at_tr_template_id
(UPPER("TEMPLATE_ID"), db_office_code)
LOGGING
TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_template_id ADD (
  CONSTRAINT at_tr_template_id_pk
 PRIMARY KEY
 (template_code)
    USING INDEX
    TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_template_id ADD (
  CONSTRAINT at_tr_template_id_r01
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_20.cwms_office (office_code),
  CONSTRAINT at_tr_template_id_r02
 FOREIGN KEY (primary_indep_param_code)
 REFERENCES cwms_20.at_parameter (parameter_code),
  CONSTRAINT at_tr_template_id_r03
 FOREIGN KEY (dep_param_code)
 REFERENCES cwms_20.at_parameter (parameter_code))
/
--************************
--------------------------
--************************



CREATE TABLE cwms_20.at_tr_template_set
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
TABLESPACE cwms_20data
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
COMMENT ON COLUMN cwms_20.at_tr_template_set.description IS 'description is of AT_TR_TEMPLATE_SET'
/
COMMENT ON COLUMN cwms_20.at_tr_template_set.store_dep_flag IS 'If T, then dependent variable is store to database, else it''s simply available for the next transform.'
/
COMMENT ON COLUMN cwms_20.at_tr_template_set.unit_system IS 'Either SI or EN or null - null indicates that the computation is not system dependant (which means it will really be done in the SI system).'
/
CREATE UNIQUE INDEX cwms_20.at_tr_template_set_pk ON cwms_20.at_tr_template_set
(template_code, sequence_no)
LOGGING
TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_template_set ADD (
  CONSTRAINT at_tr_template_set_pk
 PRIMARY KEY
 (template_code, sequence_no)
    USING INDEX
    TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_template_set ADD (
  CONSTRAINT at_tr_template_set_r01
 FOREIGN KEY (template_code)
 REFERENCES cwms_20.at_tr_template_id (template_code),
  CONSTRAINT at_tr_template_set_r02
 FOREIGN KEY (transform_id)
 REFERENCES cwms_20.cwms_tr_transformations (transform_id))
/


--************************
--------------------------
--************************


CREATE TABLE cwms_20.at_tr_ts_mask
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
TABLESPACE cwms_20data
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
CREATE UNIQUE INDEX cwms_20.at_tr_ts_mask_pk ON cwms_20.at_tr_ts_mask
(template_code, sequence_no, variable_no)
LOGGING
TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_ts_mask ADD (
  CONSTRAINT at_tr_ts_mask_pk
 PRIMARY KEY
 (template_code, sequence_no, variable_no)
    USING INDEX
    TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_ts_mask ADD (
  CONSTRAINT at_tr_ts_mask_r01
 FOREIGN KEY (template_code, sequence_no)
 REFERENCES cwms_20.at_tr_template_set (template_code,sequence_no),
  CONSTRAINT at_tr_ts_mask1_r02
 FOREIGN KEY (location_code)
 REFERENCES cwms_20.at_physical_location (location_code),
  CONSTRAINT at_tr_ts_mask1_r03
 FOREIGN KEY (parameter_code)
 REFERENCES cwms_20.at_parameter (parameter_code),
  CONSTRAINT at_tr_ts_mask1_r04
 FOREIGN KEY (parameter_type_code)
 REFERENCES cwms_20.cwms_parameter_type (parameter_type_code),
  CONSTRAINT at_tr_ts_mask1_r05
 FOREIGN KEY (interval_code)
 REFERENCES cwms_20.cwms_interval (interval_code),
  CONSTRAINT at_tr_ts_mask1_r06
 FOREIGN KEY (duration_code)
 REFERENCES cwms_20.cwms_duration (duration_code))
/
--************************
--------------------------
--************************


CREATE TABLE cwms_20.at_tr_template
(
  ts_code_indep_1  NUMBER,
  template_code    NUMBER,
  active_flag      VARCHAR2(1 BYTE)             NOT NULL,
  event_trigger    VARCHAR2(32 BYTE)            NOT NULL
)
TABLESPACE cwms_20data
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
CREATE UNIQUE INDEX cwms_20.at_tr_template_pk ON cwms_20.at_tr_template
(ts_code_indep_1, template_code)
LOGGING
TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_template ADD (
  CONSTRAINT at_tr_template_pk
 PRIMARY KEY
 (ts_code_indep_1, template_code)
    USING INDEX
    TABLESPACE cwms_20data
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
ALTER TABLE cwms_20.at_tr_template ADD (
  CONSTRAINT at_tr_template_r01
 FOREIGN KEY (template_code)
 REFERENCES cwms_20.at_tr_template_id (template_code),
  CONSTRAINT at_tr_template_r02
 FOREIGN KEY (ts_code_indep_1)
 REFERENCES cwms_20.at_cwms_ts_spec (ts_code))
/