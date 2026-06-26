CREATE TABLE at_turbine_setting
(
  turbine_setting_code  NUMBER(14)      NOT NULL,
  turbine_change_code   NUMBER(14)      NOT NULL,
  turbine_location_code NUMBER(14)      NOT NULL,
  old_discharge         BINARY_DOUBLE   NOT NULL,
  new_discharge         BINARY_DOUBLE   NOT NULL,
  scheduled_load        BINARY_DOUBLE,
  real_power            BINARY_DOUBLE
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

COMMENT ON COLUMN at_turbine_setting.turbine_setting_code IS 'The surrogate key for this individual turbine change event.  Automatically generated surrogate key.';
COMMENT ON COLUMN at_turbine_setting.turbine_change_code IS 'The turbine change record to which this setting is associated.  See AT_TURBINE_CHANGE';
COMMENT ON COLUMN at_turbine_setting.turbine_location_code IS 'The unique individual turbine that is being changed';
COMMENT ON COLUMN at_turbine_setting.scheduled_load IS 'The scheduled load for the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.old_discharge IS 'The discharge prior to the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.new_discharge IS 'The discharge after the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.real_power IS 'The real power generation for the new turbine setting';

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_pk
 PRIMARY KEY
 (turbine_setting_code)
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

CREATE UNIQUE INDEX at_turbine_setting_idx_1 ON at_turbine_setting
(turbine_change_code,turbine_location_code)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk1
 FOREIGN KEY (turbine_change_code)
 REFERENCES at_turbine_change (turbine_change_code))
/

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk2
 FOREIGN KEY (turbine_location_code)
 REFERENCES at_turbine (turbine_location_code))
/
