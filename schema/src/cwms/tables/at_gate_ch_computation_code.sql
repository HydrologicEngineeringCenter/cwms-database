CREATE TABLE at_gate_ch_computation_code
(
  discharge_comp_code       NUMBER(14)      NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  discharge_comp_display_value          VARCHAR2(25 BYTE)   NOT NULL,
  discharge_comp_tooltip      VARCHAR2(255 BYTE)    NOT NULL,
  discharge_comp_active     VARCHAR2(1 BYTE) DEFAULT 'T'  NOT NULL
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

COMMENT ON COLUMN at_gate_ch_computation_code.discharge_comp_code IS 'The unique id for this lookup record';
COMMENT ON COLUMN at_gate_ch_computation_code.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_gate_ch_computation_code.discharge_comp_display_value IS 'The value to display for this LU record';
COMMENT ON COLUMN at_gate_ch_computation_code.discharge_comp_tooltip IS 'The tooltip or meaning of this LU record';
COMMENT ON COLUMN at_gate_ch_computation_code.discharge_comp_active IS 'Whether the lu entry is currently active';

-- unique index
CREATE UNIQUE INDEX gate_ch_computation_code_idx1 ON at_gate_ch_computation_code
(db_office_code, UPPER(DISCHARGE_COMP_DISPLAY_VALUE))
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

ALTER TABLE at_gate_ch_computation_code ADD (
  CONSTRAINT at_gate_computation_code_pk
 PRIMARY KEY
 (discharge_comp_code)
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
ALTER TABLE at_gate_ch_computation_code ADD (
  CONSTRAINT at_gate_ch_computation_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_gate_ch_computation_code ADD (
CONSTRAINT at_gccc_active_ck
CHECK ( discharge_comp_active = 'T' OR discharge_comp_active = 'F'))
/

insert into at_gate_ch_computation_code values(1, 53, 'C', 'Calculated from gate opening-elev curves', 'T');
insert into at_gate_ch_computation_code values(2, 53, 'T', 'Calculated from tailwater curve',          'T');
insert into at_gate_ch_computation_code values(3, 53, 'E', 'Estimated by user',                        'T');
insert into at_gate_ch_computation_code values(4, 53, 'A', 'Adjusted by an automated method',          'T');
commit;

create or replace trigger at_gate_ch_computation_code_t1
   before insert or update or delete
   on at_gate_ch_computation_code
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
end at_gate_ch_computation_code_t1;
/
