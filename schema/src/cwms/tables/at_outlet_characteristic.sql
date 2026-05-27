CREATE TABLE at_outlet_characteristic
(
  outlet_characteristic_code      NUMBER(14)         NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  outlet_characteristic_id VARCHAR2(64 BYTE)   NOT NULL,
  opening_parameter_code                        NUMBER(14)             NOT NULL,
  height          BINARY_DOUBLE,
  width           BINARY_DOUBLE,
  opening_radius        BINARY_DOUBLE,
  elev_invert         BINARY_DOUBLE,
  flow_capacity_max       BINARY_DOUBLE,
  net_length_spillway       BINARY_DOUBLE,
  spillway_notch_length             BINARY_DOUBLE,
  outlet_general_description                    VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_outlet_characteristic.outlet_characteristic_code IS 'The automatically generated surrogate unique key for this record';
COMMENT ON COLUMN at_outlet_characteristic.db_office_code IS 'The office code that this characteristic is assigned to';
COMMENT ON COLUMN at_outlet_characteristic.outlet_characteristic_id IS 'The name of this outlet characteristic';
COMMENT ON COLUMN at_outlet_characteristic.opening_parameter_code IS 'A foreign key to an AT_PARAMETER record that constrains the gate opening to a defined parameter and unit.';
COMMENT ON COLUMN at_outlet_characteristic.height IS 'The height of the gate';
COMMENT ON COLUMN at_outlet_characteristic.width IS 'The width of the gate';
COMMENT ON COLUMN at_outlet_characteristic.opening_radius IS 'The radius of the pipe or circular conduit that this outlet is a control for.  This is not applicable to rectangular outlets, tainter gates, or uncontrolled spillways';
COMMENT ON COLUMN at_outlet_characteristic.elev_invert IS 'The elevation of the invert for the outlet';
COMMENT ON COLUMN at_outlet_characteristic.flow_capacity_max IS 'The maximum flow capacity of the gate';
COMMENT ON COLUMN at_outlet_characteristic.net_length_spillway IS 'The net length of the spillway';
COMMENT ON COLUMN at_outlet_characteristic.spillway_notch_length IS 'The length of the spillway notch';

ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_pk
 PRIMARY KEY
 (outlet_characteristic_code)
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
ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_fk1
 FOREIGN KEY (opening_parameter_code)
 REFERENCES at_parameter (parameter_code))
/
ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_fk2
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
-- unique index
CREATE UNIQUE INDEX at_outlet_characteristic_idx1 ON at_outlet_characteristic
(db_office_code, UPPER("OUTLET_CHARACTERISTIC_ID"))
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
