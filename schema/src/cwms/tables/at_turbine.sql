CREATE TABLE at_turbine
(
  turbine_location_code     NUMBER(14)      NOT NULL,
  project_location_code                 NUMBER(14)      NOT NULL
--  turbine_characteristic_code           NUMBER(14)                      NOT NULL
--  turbine_description     VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_turbine.turbine_location_code IS 'The actual turbine this record refers to.  The location_code also in AT_PHYSICAL_LOCATION';
COMMENT ON COLUMN at_turbine.project_location_code IS 'The project this turbine is part of.  See AT_PROJECT.project_location_code';
--COMMENT ON COLUMN at_turbine.turbine_characteristic_code IS 'The code for the foreign key record in the AT_TURBINE_CHARACTERISTIC table which describes turbine geometry and features.';
-- COMMENT ON COLUMN at_turbine.turbine_description IS 'The description of the turbine';

ALTER TABLE at_turbine ADD (
  CONSTRAINT at_turbine_pk
 PRIMARY KEY
 (turbine_location_code)
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
CREATE UNIQUE INDEX at_turbine_idx_1 ON at_turbine
(turbine_location_code,project_location_code)--,turbine_characteristic_code)
tablespace cwms_20at_data
/
ALTER TABLE at_turbine ADD (
  CONSTRAINT at_turbine_fk1
 FOREIGN KEY (turbine_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_turbine ADD (
  CONSTRAINT at_turbine_fk2
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/
