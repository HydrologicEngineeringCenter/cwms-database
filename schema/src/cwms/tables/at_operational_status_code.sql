CREATE TABLE at_operational_status_code
(
  operational_status_code       NUMBER(14)      NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  oper_status_display_value   VARCHAR2(25 BYTE)   NOT NULL,
  operational_status_tooltip            VARCHAR2(255 BYTE)    NOT NULL,
  operational_status_active     VARCHAR2(1) DEFAULT 'T' NOT NULL
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
COMMENT ON COLUMN at_operational_status_code.operational_status_code IS 'The unique id for this operational_status_code code record';
COMMENT ON COLUMN at_operational_status_code.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_operational_status_code.oper_status_display_value IS 'The value to display for this operational_status_code record';
COMMENT ON COLUMN at_operational_status_code.operational_status_tooltip IS 'The description or meaning of this operational_status_code record';
COMMENT ON COLUMN at_operational_status_code.operational_status_active IS 'Whether this operational_status_code entry is currently active';

-- unique index
CREATE UNIQUE INDEX operational_status_code_idx1 ON at_operational_status_code
(db_office_code, UPPER("OPER_STATUS_DISPLAY_VALUE"))
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

ALTER TABLE at_operational_status_code ADD (
  CONSTRAINT at_op_status_code_pk
 PRIMARY KEY
 (operational_status_code)
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
ALTER TABLE at_operational_status_code ADD (
  CONSTRAINT at_operational_status_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_operational_status_code ADD (
CONSTRAINT at_oper_status_active_ck
CHECK (operational_status_active = 'T' OR operational_status_active = 'F'))
/
commit;

create or replace trigger at_operational_status_code_t1
   before insert or update or delete
   on at_operational_status_code
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
end at_operational_status_code_t1;
/
