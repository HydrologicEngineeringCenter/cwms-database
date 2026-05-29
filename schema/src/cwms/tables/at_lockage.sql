CREATE TABLE at_lockage
(
  lockage_code        NUMBER(14)      NOT NULL,
  lockage_location_code     NUMBER(14)      NOT NULL,
  lockage_datetime      DATE        NOT NULL,
  number_boats        BINARY_DOUBLE,
  number_barges       BINARY_DOUBLE,
  tonnage       BINARY_DOUBLE,
  is_tow_upbound      VARCHAR2(1 BYTE)                NOT NULL,
  is_lock_chamber_emptying              VARCHAR2(1 BYTE)                NOT NULL,
  lockage_notes       VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_lockage.lockage_code IS 'Unique record identifier for every lockage on a project.  IS automatically generated.';
COMMENT ON COLUMN at_lockage.lockage_location_code IS 'The lock at which this lockage occurred.  SEE AT_LOCK';
COMMENT ON COLUMN at_lockage.lockage_datetime IS 'The date and time of the lockage';
COMMENT ON COLUMN at_lockage.number_boats IS 'The number of boats accommodated in this lockage';
COMMENT ON COLUMN at_lockage.number_barges IS 'The number of barges accommodated in this lockage';
COMMENT ON COLUMN at_lockage.tonnage IS 'The tonnage of product accommodated in this lockage';
COMMENT ON COLUMN at_lockage.is_tow_upbound IS 'A boolean-equivalent value for the direction of boats and barges for this lockage.  Constrained to T or F by a check constraint.';
COMMENT ON COLUMN at_lockage.is_lock_chamber_emptying IS 'A boolean-equivalent value for whether the lockage operation of this record was emptying or filling the lock chamber.  Constrained to T or F by a check constraint.';
COMMENT ON COLUMN at_lockage.lockage_notes IS 'Any notes pertinent to this lockage';


ALTER TABLE at_lockage ADD (
  CONSTRAINT at_lockage_pk
 PRIMARY KEY
 (lockage_code)
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

CREATE UNIQUE INDEX at_lockage_idx_1 ON at_lockage
(lockage_location_code,lockage_datetime)
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

ALTER TABLE at_lockage ADD (
  CONSTRAINT at_lockage_fk1
 FOREIGN KEY (lockage_location_code)
 REFERENCES at_lock (lock_location_code))
/
ALTER TABLE at_lockage ADD (
CONSTRAINT at_lockage_is_tow_upbound_ck
CHECK ( is_tow_upbound = 'T' OR is_tow_upbound = 'F'))
/
ALTER TABLE at_lockage ADD (
CONSTRAINT at_lockage_is_lock_emptying_ck
CHECK ( is_lock_chamber_emptying = 'T' OR is_lock_chamber_emptying = 'F'))
/
