CREATE TABLE at_gate_setting
(
  gate_setting_code     NUMBER(14)    NOT NULL,
  gate_change_code      NUMBER(14)    NOT NULL,
  outlet_location_code  NUMBER(14)    NOT NULL,
  gate_opening          BINARY_DOUBLE NOT NULL,
  invert_elev           BINARY_DOUBLE
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

COMMENT ON COLUMN at_gate_setting.gate_setting_code IS 'The unique record for the overall gate setting.  Automatically generated surrogate key.';
COMMENT ON COLUMN at_gate_setting.gate_change_code IS 'The gate change record to which this setting is associated.  See AT_GATE_CHANGE.';
COMMENT ON COLUMN at_gate_setting.outlet_location_code IS 'The unique gate that is being set. This location code also in AT_PHYSICAL_LOCATION';
COMMENT ON COLUMN at_gate_setting.gate_opening IS 'The new gate opening.  This may be a dial opening rather than an actual opening';
COMMENT ON COLUMN at_gate_setting.invert_elev IS 'The invert elevation if the gate supports variable inverts';

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_pk
 PRIMARY KEY
 (gate_setting_code)
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

CREATE UNIQUE INDEX at_gate_setting_idx_1 ON at_gate_setting
(gate_setting_code,outlet_location_code)
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

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_fk1
 FOREIGN KEY (gate_change_code)
 REFERENCES at_gate_change (gate_change_code))
/

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_fk2
 FOREIGN KEY (outlet_location_code)
 REFERENCES at_outlet (outlet_location_code))
/
