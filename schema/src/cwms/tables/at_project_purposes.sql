CREATE TABLE at_project_purposes
(
  purpose_code          NUMBER(14)         NOT NULL,
  db_office_code        NUMBER             NOT NULL,
  purpose_display_value VARCHAR2(25 BYTE)  NOT NULL,
  purpose_tooltip       VARCHAR2(255 BYTE) NOT NULL,
  purpose_active        VARCHAR2(1 BYTE)   DEFAULT 'T' NOT NULL,
  purpose_nid_code      VARCHAR2(1 BYTE)
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
COMMENT ON COLUMN at_project_purposes.purpose_code IS 'The unique id for this project_purpose record';
COMMENT ON COLUMN at_project_purposes.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_project_purposes.purpose_display_value IS 'The value to display for this project_purpose record';
COMMENT ON COLUMN at_project_purposes.purpose_tooltip IS 'The tooltip or meaning of this project_purpose record';
COMMENT ON COLUMN at_project_purposes.purpose_active IS 'Whether the project_purpose entry is currently active';
COMMENT ON COLUMN at_project_purposes.purpose_nid_code IS 'National Inventory of Dams code for this purpose';

-- unique index
CREATE UNIQUE INDEX project_purpose_idx1 ON at_project_purposes
(db_office_code, UPPER("PURPOSE_DISPLAY_VALUE"))
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

ALTER TABLE at_project_purposes ADD (
  CONSTRAINT at_project_purposes_pk
 PRIMARY KEY
 (purpose_code)
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
ALTER TABLE at_project_purposes ADD (
  CONSTRAINT at_project_purposes_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_project_purposes ADD (
CONSTRAINT at_proj_purpose_active_ck
CHECK ( purpose_active = 'T' OR purpose_active = 'F'))
/

insert into at_project_purposes values ( 1, 53, 'Debris Control', 'Debris Control', 'T', 'D');
insert into at_project_purposes values ( 2, 53, 'Fire Prot/Small Fish Pond', 'Fire Protection Stock or Small Fish Pond', 'T', 'P');
set escape on
insert into at_project_purposes values ( 3, 53, 'Fish \& Wildlife Pond', 'Fish \& Wildlife Pond', 'T', 'F');
set escape off
insert into at_project_purposes values ( 4, 53, 'Flood Control', 'Flood Control', 'T', 'C');
insert into at_project_purposes values ( 5, 53, 'Grade Stabilization', 'Grade Stabilization', 'T', 'G');
insert into at_project_purposes values ( 6, 53, 'HydroElectric', 'HydroElectric', 'T', 'H');
insert into at_project_purposes values ( 7, 53, 'Irrigation', 'Irrigation', 'T', 'I');
insert into at_project_purposes values ( 8, 53, 'Navigation', 'Navigation', 'T', 'N');
insert into at_project_purposes values ( 9, 53, 'Recreation', 'Recreation', 'T', 'R');
insert into at_project_purposes values (10, 53, 'Tailings', 'Tailings', 'T', 'T');
insert into at_project_purposes values (11, 53, 'Water Supply', 'Water Supply', 'T', 'S');
insert into at_project_purposes values (12, 53, 'Other', 'Other', 'T', 'O');
commit;

create or replace trigger at_project_purposes_t1
   before insert or update or delete
   on at_project_purposes
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
end at_project_purposes_t1;
/
