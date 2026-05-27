CREATE TABLE at_outlet
(
  outlet_location_code              NUMBER(14)      NOT NULL,
  project_location_code                         NUMBER(14)      NOT NULL
--  outlet_characteristic_code        NUMBER(14)                      NOT NULL
  --outlet_description                            VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_outlet.outlet_location_code IS 'The unique outlet this record is. Also in AT_OUTLET';
COMMENT ON COLUMN at_outlet.project_location_code IS 'The project where this outlet is located. ';

ALTER TABLE at_outlet ADD (
  CONSTRAINT at_outlet_pk
 PRIMARY KEY
 (outlet_location_code)
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
CREATE UNIQUE INDEX at_outlet_idx_1 ON at_outlet
(outlet_location_code,project_location_code)--,outlet_characteristic_code)
TABLESPACE CWMS_20AT_DATA
/

ALTER TABLE at_outlet ADD (
  CONSTRAINT at_outlet_fk1
 FOREIGN KEY (outlet_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_outlet ADD (
  CONSTRAINT at_outlet_fk2
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/
