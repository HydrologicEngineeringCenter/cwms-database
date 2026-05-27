CREATE TABLE at_embank_structure_type
(
  structure_type_code         NUMBER(14)            NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  structure_type_display_value    VARCHAR2(50 BYTE)       NOT NULL,
  structure_type_tooltip      VARCHAR2(255 BYTE)        NOT NULL,
  structure_type_active       VARCHAR2(1 BYTE) DEFAULT 'T'  NOT NULL
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
COMMENT ON COLUMN at_embank_structure_type.structure_type_code IS 'The unique id for this structure_type code record';
COMMENT ON COLUMN at_embank_structure_type.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_embank_structure_type.structure_type_display_value IS 'The value to display for this structure_type code record';
COMMENT ON COLUMN at_embank_structure_type.structure_type_tooltip IS 'The tooltip or meaning of this structure_type code record';
COMMENT ON COLUMN at_embank_structure_type.structure_type_active IS 'Whether this structure type entry is currently active';

-- unique index
CREATE UNIQUE INDEX embank_structure_type_idx1 ON at_embank_structure_type
(db_office_code, UPPER("STRUCTURE_TYPE_DISPLAY_VALUE"))
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

ALTER TABLE at_embank_structure_type ADD (
  CONSTRAINT at_emb_structure_type_pk
 PRIMARY KEY
 (structure_type_code)
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
ALTER TABLE at_embank_structure_type ADD (
  CONSTRAINT at_embank_structure_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_embank_structure_type ADD (
CONSTRAINT at_est_active_ck
CHECK ( structure_type_active = 'T' OR structure_type_active = 'F'))
/
insert into at_embank_structure_type values(1, 53, 'Rolled Earth-Filled',      'An embankment formed by compacted earth',                                'T');
insert into at_embank_structure_type values(2, 53, 'Natural',                  'A natural embankment',                                                   'T');
insert into at_embank_structure_type values(3, 53, 'Concrete Arch',            'An embankment formed by concrete arches',                                'T');
insert into at_embank_structure_type values(4, 53, 'Dble-Curv Concrete Arch',  'An embankment formed by thin, double-curvature concrete arches',         'T');
insert into at_embank_structure_type values(5, 53, 'Concrete Apron',           'An embankment formed by a concrete apron',                               'T');
insert into at_embank_structure_type values(6, 53, 'Concrete Dam',             'An embankment formed by concrete',                                       'T');
insert into at_embank_structure_type values(7, 53, 'Concrete Gravity',         'An embankment formed by concrete gravity materials',                     'T');
insert into at_embank_structure_type values(8, 53, 'Rolld Imperv Earth-Fill',  'An embankment formed by rolled impervious and random earth-fill',        'T');
insert into at_embank_structure_type values(9, 53, 'Imprv/Semiperv EarthFill', 'An embankment formed by rolled impervious and semi-pervious earth-fill', 'T');
commit;

create or replace trigger at_embank_structure_type_t1
   before insert or update or delete
   on at_embank_structure_type
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
end at_embank_structure_type_t1;
/
