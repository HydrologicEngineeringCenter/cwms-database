CREATE TABLE at_turbine_computation_code
(
  turbine_comp_code       NUMBER(14)        NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  turbine_comp_display_value      VARCHAR2(25 BYTE)   NOT NULL,
  turbine_comp_tooltip     VARCHAR2(255 BYTE)    NOT NULL,
  turbine_comp_active      VARCHAR2(1) DEFAULT 'T' NOT NULL
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

COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_code IS 'The unique id for this turbine_computation_code record';
COMMENT ON COLUMN at_turbine_computation_code.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_display_value IS 'The value to display for this at_turbine_computation_code record';
COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_tooltip IS 'The description or meaning of this at_turbine_computation_code record';
COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_active IS 'Whether this at_turbine_computation_code entry is currently active';

-- unique index
CREATE UNIQUE INDEX turbine_computation_code_idx1 ON at_turbine_computation_code
(db_office_code, UPPER(TURBINE_COMP_DISPLAY_VALUE))
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

ALTER TABLE at_turbine_computation_code ADD (
  CONSTRAINT at_turb_computation_code_pk
 PRIMARY KEY
 (turbine_comp_code)
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

-- FK
ALTER TABLE at_turbine_computation_code ADD (
  CONSTRAINT at_turbine_computation_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_turbine_computation_code ADD (
CONSTRAINT at_tcc_active_ck
CHECK ( turbine_comp_active = 'T' OR turbine_comp_active = 'F'))
/

insert into at_turbine_computation_code values(1, 53, 'C', 'Calculated from turbine load-nethead curves', 'T');
insert into at_turbine_computation_code values(2, 53, 'T', 'Calculated from tailwater curve',             'T');
insert into at_turbine_computation_code values(3, 53, 'R', 'Reported by powerhouse',                      'T');
insert into at_turbine_computation_code values(4, 53, 'A', 'Adjusted by an automated method',             'T');
commit;

create or replace trigger at_turbine_computation_code_t1
   before insert or update or delete
   on at_turbine_computation_code
   referencing new as new old as old
   for each row
declare
   l_user_office_code integer;
begin
   l_user_office_code := cwms_util.user_office_code;
   if l_user_office_code != cwms_util.db_office_code_all and :new.db_office_code != l_user_office_code then
      cwms_err.raise(
         'ERROR',
         'Cannot modify value owned by '
         ||cwms_util.get_db_office_id_from_code(:new.db_office_code)
         ||' from office '
         ||cwms_util.get_db_office_id_from_code(l_user_office_code));
   end if;
end at_turbine_computation_code_t1;
/
