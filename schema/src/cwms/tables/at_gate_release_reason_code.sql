CREATE TABLE at_gate_release_reason_code
(
  release_reason_code       NUMBER(14)            NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  release_reason_display_value  VARCHAR2(25 BYTE)       NOT NULL,
  release_reason_tooltip    VARCHAR2(255 BYTE)        NOT NULL,
  release_reason_active     VARCHAR2(1 BYTE) DEFAULT 'T'  NOT NULL
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
COMMENT ON COLUMN at_gate_release_reason_code.release_reason_code IS 'The unique id for this release code record';
COMMENT ON COLUMN at_gate_release_reason_code.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_gate_release_reason_code.release_reason_display_value IS 'The value to display for this release code record';
COMMENT ON COLUMN at_gate_release_reason_code.release_reason_tooltip IS 'The tooltip or meaning of this release code record';
COMMENT ON COLUMN at_gate_release_reason_code.release_reason_active IS 'Whether the release code entry is currently active';

-- unique index
CREATE UNIQUE INDEX gate_release_reason_code_idx1 ON at_gate_release_reason_code
(db_office_code, UPPER("RELEASE_REASON_DISPLAY_VALUE"))
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

ALTER TABLE at_gate_release_reason_code ADD (
  CONSTRAINT at_gate_release_reason_pk
 PRIMARY KEY
 (release_reason_code)
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
ALTER TABLE at_gate_release_reason_code ADD (
  CONSTRAINT at_gate_release_reason_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_gate_release_reason_code ADD (
CONSTRAINT at_grrc_active_ck
CHECK ( release_reason_active = 'T' OR release_reason_active = 'F'))
/

insert into at_gate_release_reason_code values(1, 53, 'F', 'Flood control release', 'T');
insert into at_gate_release_reason_code values(2, 53, 'W', 'Water supply release',  'T');
insert into at_gate_release_reason_code values(3, 53, 'Q', 'Water quality release', 'T');
insert into at_gate_release_reason_code values(4, 53, 'H', 'Hydropower release',    'T');
insert into at_gate_release_reason_code values(5, 53, 'O', 'Other release',         'T');
commit;

create or replace trigger at_gate_release_reason_code_t1
   before insert or update or delete
   on at_gate_release_reason_code
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
end at_gate_release_reason_code_t1;
/
