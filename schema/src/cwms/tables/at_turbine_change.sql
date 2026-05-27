CREATE TABLE at_turbine_change
(
  turbine_change_code             NUMBER(14)     NOT NULL,
  project_location_code           NUMBER(14)     NOT NULL,
  turbine_change_datetime         DATE           NOT NULL,
  elev_pool                       BINARY_DOUBLE,
  elev_tailwater                  BINARY_DOUBLE,
  turbine_setting_reason_code     NUMBER(14)     NOT NULL,
  turbine_discharge_comp_code     NUMBER(14)     NOT NULL,
  old_total_discharge_override    BINARY_DOUBLE,
  new_total_discharge_override    BINARY_DOUBLE,
  turbine_change_notes            VARCHAR2(255 BYTE),
  protected                       VARCHAR2(1)    NOT NULL
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
COMMENT ON COLUMN at_turbine_change.turbine_change_code IS 'Unique record identifier for every turbine change on a project.  IS automatically created';
COMMENT ON COLUMN at_turbine_change.project_location_code IS 'The project this turbine change refers to';
COMMENT ON COLUMN at_turbine_change.turbine_change_datetime IS 'The date and time of the turbine change';
COMMENT ON COLUMN at_turbine_change.elev_pool IS 'The headwater pool elevation at the time of the turbine change';
COMMENT ON COLUMN at_turbine_change.elev_tailwater IS 'The tailwater elevation at the time of the turbine change';
COMMENT ON COLUMN at_turbine_change.turbine_setting_reason_code IS 'The new turbine setting reason lookup code.  Examples of reasons are spin-noload, overload, dump energy, peaking, testing, etc.';
COMMENT ON COLUMN at_turbine_change.turbine_discharge_comp_code IS 'The new turbine setting discharge computation lookup code';
COMMENT ON COLUMN at_turbine_change.old_total_discharge_override IS 'The total Q rate before the turbine change.  This value is from a manual entry or other external data source and overrides the calculated Q for the group of turbines.';
COMMENT ON COLUMN at_turbine_change.new_total_discharge_override IS 'The total Q rate after the turbine change.  This value is from a manual entry or other external data source and overrides the calculated Q for the group of turbines.';
COMMENT ON COLUMN at_turbine_change.turbine_change_notes IS 'Any notes pertinent to this turbine change';

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_pk
 PRIMARY KEY
 (turbine_change_code)
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

CREATE UNIQUE INDEX at_turbine_change_idx_1 ON at_turbine_change
(project_location_code,turbine_change_datetime)
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

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_fk2
 FOREIGN KEY (turbine_setting_reason_code)
 REFERENCES at_turbine_setting_reason (turb_set_reason_code))
/

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_fk3
 FOREIGN KEY (turbine_discharge_comp_code)
 REFERENCES at_turbine_computation_code (turbine_comp_code))
/
