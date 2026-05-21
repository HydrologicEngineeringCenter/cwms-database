CREATE TABLE at_ws_contract_type
(
  ws_contract_type_code     NUMBER(14)        NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  ws_contract_type_display_value  VARCHAR2(25 BYTE)   NOT NULL,
  ws_contract_type_tooltip    VARCHAR2(255 BYTE)    NOT NULL,
  ws_contract_type_active   VARCHAR2(1) DEFAULT 'T' NOT NULL
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
COMMENT ON COLUMN at_ws_contract_type.ws_contract_type_code IS 'The unique id for this water supply contract type code record';
COMMENT ON COLUMN at_ws_contract_type.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_ws_contract_type.ws_contract_type_display_value IS 'The value to display for this ws_contract_type record';
COMMENT ON COLUMN at_ws_contract_type.ws_contract_type_tooltip IS 'The description or meaning of this ws_contract_type record';
COMMENT ON COLUMN at_ws_contract_type.ws_contract_type_active IS 'Whether this ws_contract_type entry is currently active';
/

-- unique index
CREATE UNIQUE INDEX ws_contract_type_code_idx1 ON at_ws_contract_type
(db_office_code, UPPER("WS_CONTRACT_TYPE_DISPLAY_VALUE"))
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

ALTER TABLE at_ws_contract_type ADD (
  CONSTRAINT at_ws_contract_type_pk
 PRIMARY KEY
 (ws_contract_type_code)
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
ALTER TABLE at_ws_contract_type ADD (
  CONSTRAINT at_ws_contract_type_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_ws_contract_type ADD (
CONSTRAINT at_ws_cntrct_typ_activ_ck
CHECK ( ws_contract_type_active = 'T' OR ws_contract_type_active = 'F'))
/

insert into at_ws_contract_type values (1,53,'Storage','Storage contract','T');
insert into at_ws_contract_type values (2,53,'Irrigation','Irrigation contract','T');
insert into at_ws_contract_type values (3,53,'Surplus','Surplus contract','T');
insert into at_ws_contract_type values (4,53,'Conduit','Conduit contract','T');
insert into at_ws_contract_type values (5,53,'Conveyance','Conveyance contract','T');
insert into at_ws_contract_type values (6,53,'Interim Irrigation','Interim use irrigation','T');
commit;

create or replace trigger at_ws_contract_type_t1
   before insert or update or delete
   on at_ws_contract_type
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
end at_ws_contract_type_t1;
/
