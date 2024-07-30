alter table at_cwms_ts_spec add prev_location_code NUMBER(14);
COMMENT ON COLUMN at_cwms_ts_spec.location_code IS 'Primary key of AT_PHYSICAL_LOCATION table. Location time series is associated with. Is set to 0 when time series is deleted';
COMMENT ON COLUMN at_cwms_ts_spec.prev_location_code IS 'Location of time series prior to deletion';

CREATE INDEX at_cwms_ts_spec_locations ON at_cwms_ts_spec
(location_code, prev_location_code)
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

ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_ck_1
 CHECK ((location_code > 0 AND prev_location_code IS NULL) OR (location_code = 0 AND prev_location_code > 0)))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_ck_2
 CHECK ((location_code > 0 AND delete_date IS NULL) OR (location_code = 0 AND delete_date IS NOT NULL)))
/

ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_7
 FOREIGN KEY (prev_location_code)
 REFERENCES at_physical_location (location_code))
/