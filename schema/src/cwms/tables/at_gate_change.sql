CREATE TABLE at_gate_change
(
  gate_change_code             NUMBER(14)    NOT NULL,
  project_location_code        NUMBER(14)    NOT NULL,
  gate_change_date             DATE          NOT NULL,
  elev_pool                    BINARY_DOUBLE NOT NULL,
  elev_tailwater               BINARY_DOUBLE,
  old_total_discharge_override BINARY_DOUBLE,
  new_total_discharge_override BINARY_DOUBLE,
  discharge_computation_code   NUMBER(14)    NOT NULL,
  release_reason_code          NUMBER(14)    NOT NULL,
  gate_change_notes            VARCHAR2(255 BYTE),
  protected                    VARCHAR2(1)   NOT NULL,
  reference_elev               BINARY_DOUBLE
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
COMMENT ON COLUMN at_gate_change.gate_change_code IS 'Unique record identifier for every gate change on a project.  IS automatically created';
COMMENT ON COLUMN at_gate_change.project_location_code IS 'The project this gate change pertains to';
COMMENT ON COLUMN at_gate_change.gate_change_date IS 'The date and time of the gate change';
COMMENT ON COLUMN at_gate_change.elev_pool IS 'The headwater pool elevation at the time of the gate change';
COMMENT ON COLUMN at_gate_change.elev_tailwater IS 'The tailwater elevation at the time of the gate change';
COMMENT ON COLUMN at_gate_change.old_total_discharge_override IS 'The total discharge rate just before the gate change.  This value is from a manual entry or other external data source and overrides the calculated Q for the projects outlet works.';
COMMENT ON COLUMN at_gate_change.new_total_discharge_override IS 'The total discharge rate just after the gate change. This value is from a manual entry or other external data source and overrides the calculated Q for the projects outlet works.';
COMMENT ON COLUMN at_gate_change.discharge_computation_code IS 'The code for the discharge computation method for the gate change. Values are restricted by a foreign key to a lookup table.';
COMMENT ON COLUMN at_gate_change.release_reason_code IS 'The code for the release reason (or purpose) issued for the gate change.  Values are restricted by a foreign key to a lookup table.';
COMMENT ON COLUMN at_gate_change.gate_change_notes IS 'Any notes pertinent to this gate change';
COMMENT ON COLUMN at_gate_change.protected IS 'Specifies whether this gate change is protected from inadvertent overwrites';
COMMENT ON COLUMN at_gate_change.reference_elev IS 'An additional reference elevation if required to describe this gate change';

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_pk
 PRIMARY KEY
 (gate_change_code)
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

CREATE UNIQUE INDEX at_gate_change_idx_1 ON at_gate_change
(project_location_code,gate_change_date)
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

alter table at_gate_change add constraint at_gate_change_ck1 check (protected in ('T', 'F'));

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_fk2
 FOREIGN KEY (discharge_computation_code)
 REFERENCES at_gate_ch_computation_code (discharge_comp_code))
/

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_fk3
 FOREIGN KEY (release_reason_code)
 REFERENCES at_gate_release_reason_code (release_reason_code))
/
