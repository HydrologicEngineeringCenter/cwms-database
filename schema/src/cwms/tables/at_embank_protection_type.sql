CREATE TABLE at_embank_protection_type
(
  protection_type_code        NUMBER(14)        NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  protection_type_display_value   VARCHAR2(50 BYTE)   NOT NULL,
  protection_type_tooltip     VARCHAR2(255 BYTE)    NOT NULL,
  protection_type_active      VARCHAR2(1) DEFAULT 'T' NOT NULL
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
COMMENT ON COLUMN at_embank_protection_type.protection_type_code IS 'The unique id for this protection_type code record';
COMMENT ON COLUMN at_embank_protection_type.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_embank_protection_type.protection_type_display_value IS 'The value to display for this protection_type code record';
COMMENT ON COLUMN at_embank_protection_type.protection_type_tooltip IS 'The tooltip or meaning of this protection_type code record';
COMMENT ON COLUMN at_embank_protection_type.protection_type_active IS 'Whether this protection_type entry is currently active';

-- unique index
CREATE UNIQUE INDEX embank_protection_type_idx1 ON at_embank_protection_type
(db_office_code, UPPER("PROTECTION_TYPE_DISPLAY_VALUE"))
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

ALTER TABLE at_embank_protection_type ADD (
  CONSTRAINT at_emb_protection_type_pk
 PRIMARY KEY
 (protection_type_code)
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
ALTER TABLE at_embank_protection_type ADD (
  CONSTRAINT at_embank_protection_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_embank_protection_type ADD (
CONSTRAINT at_ept_active_ck
CHECK ( protection_type_active = 'T' OR protection_type_active = 'F'))
/

insert into at_embank_protection_type values(1, 53, 'Concrete Blanket',    'Protected by blanket of concrete',              'T');
insert into at_embank_protection_type values(2, 53, 'Concrete Arch Facing','Protected by the faces of the concrete arches', 'T');
insert into at_embank_protection_type values(3, 53, 'Masonry Facing',      'Protected by masonry facing',                   'T');
insert into at_embank_protection_type values(4, 53, 'Grass-Covered Soil',  'Protected by grass-covered soil',               'T');
insert into at_embank_protection_type values(5, 53, 'Soil Cement',         'Protected by soil cement',                      'T');
insert into at_embank_protection_type values(6, 53, 'Rock Riprap',         'Protected by rock riprap',                      'T');
insert into at_embank_protection_type values(7, 53, 'Natural Rock',        'Protected by natural rock',                     'T');
insert into at_embank_protection_type values(8, 53, 'Stone Toe',           'Protected by a stone toe',                      'T');
commit;

create or replace trigger at_embank_protection_type_t1
   before insert or update or delete
   on at_embank_protection_type
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
end at_embank_protection_type_t1;
/
