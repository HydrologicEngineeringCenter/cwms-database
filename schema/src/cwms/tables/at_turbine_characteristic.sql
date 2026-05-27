CREATE TABLE at_turbine_characteristic
(
  turbine_characteristic_code           NUMBER(14)                      NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  turbine_characteristic_id VARCHAR2(64 BYTE)   NOT NULL,
  rated_power_capacity      BINARY_DOUBLE,
  max_power_overload                    BINARY_DOUBLE,
  min_generation_flow     BINARY_DOUBLE,
  max_generation_flow     BINARY_DOUBLE,
  turbine_operation_rule_set    VARCHAR2(255 BYTE),
  turbine_general_description   VARCHAR2(255 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504 k
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
COMMENT ON COLUMN at_turbine_characteristic.turbine_characteristic_code IS 'The automatically generated unique surrogate key';
COMMENT ON COLUMN at_turbine_characteristic.db_office_code IS 'The office code for this turbine characteristic';
COMMENT ON COLUMN at_turbine_characteristic.turbine_characteristic_id IS 'The name of this turbine characteristic';
COMMENT ON COLUMN at_turbine_characteristic.rated_power_capacity IS 'The nameplate power generating capacity for this turbine';
COMMENT ON COLUMN at_turbine_characteristic.max_power_overload IS 'The maximum percentage of nameplate power that this turbine type can run in overload mode';
COMMENT ON COLUMN at_turbine_characteristic.min_generation_flow IS 'The minimum flow required to utilize the turbine';
COMMENT ON COLUMN at_turbine_characteristic.max_generation_flow IS 'The maximum flow capacity for the turbine';
COMMENT ON COLUMN at_turbine_characteristic.turbine_general_description IS 'The genearl description of this class of turbines';
COMMENT ON COLUMN at_turbine_characteristic.turbine_operation_rule_set IS 'The operational rule set for this turbine';


ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_pk
 PRIMARY KEY
 (turbine_characteristic_code)
    USING INDEX
    TABLESPACE cwms_20at_data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
-- unique index
CREATE UNIQUE INDEX at_turbine_characteristic_idx1 ON at_turbine_characteristic
(db_office_code, UPPER("TURBINE_CHARACTERISTIC_ID"))
LOGGING
tablespace CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/
