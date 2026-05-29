CREATE TABLE at_physical_transfer_type
(
  phys_trans_type_code        NUMBER(14)        NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  phys_trans_type_display_value     VARCHAR2(25 BYTE)   NOT NULL,
  phys_trans_type_tooltip   VARCHAR2(255 BYTE)    NOT NULL,
  phys_trans_type_active      VARCHAR2(1) DEFAULT 'T' NOT NULL
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
COMMENT ON COLUMN at_physical_transfer_type.phys_trans_type_code IS 'The unique id for this physical_transfer_type code record';
COMMENT ON COLUMN at_physical_transfer_type.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_physical_transfer_type.phys_trans_type_display_value IS 'The value to display for this physical_transfer_type record';
COMMENT ON COLUMN at_physical_transfer_type.phys_trans_type_tooltip IS 'The description or meaning of this physical_transfer_type record';
COMMENT ON COLUMN at_physical_transfer_type.phys_trans_type_active IS 'Whether this physical_transfer_type entry is currently active';

-- unique index
CREATE UNIQUE INDEX physical_transfer_type_idx1 ON at_physical_transfer_type
(db_office_code, UPPER("PHYS_TRANS_TYPE_DISPLAY_VALUE"))
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

ALTER TABLE at_physical_transfer_type ADD (
  CONSTRAINT at_phys_transfer_type_pk
 PRIMARY KEY
 (phys_trans_type_code)
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
ALTER TABLE at_physical_transfer_type ADD (
  CONSTRAINT at_physical_transfer_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_physical_transfer_type ADD (
CONSTRAINT at_ptt_active_ck
CHECK ( phys_trans_type_active = 'T' OR phys_trans_type_active = 'F'))
/

insert into at_physical_transfer_type values(1, 53, 'Pipeline', 'Transfer through a pipeline',  'T');
insert into at_physical_transfer_type values(2, 53, 'Canal',    'Transfer by canal',            'T');
insert into at_physical_transfer_type values(3, 53, 'Stream',   'Transfer by flow in a stream', 'T');
insert into at_physical_transfer_type values(4, 53, 'River',    'Transfer by flow in a river',  'T');
insert into at_physical_transfer_type values(5, 53, 'Siphon',   'Transfer by siphon',           'T');
insert into at_physical_transfer_type values(6, 53, 'Aqueduct', 'Transfer by aqueduct',         'T');
insert into at_physical_transfer_type values(7, 53, 'Conduit',  'Transfer by conduit',          'T');
commit;

create or replace trigger at_physical_transfer_type_t1
   before insert or update or delete
   on at_physical_transfer_type
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
end at_physical_transfer_type_t1;
/
