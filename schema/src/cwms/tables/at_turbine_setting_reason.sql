CREATE TABLE at_turbine_setting_reason
(
  turb_set_reason_code       NUMBER(14)      NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  turb_set_reason_display_value     VARCHAR2(25 BYTE)   NOT NULL,
  turb_set_reason_tooltip    VARCHAR2(255 BYTE)    NOT NULL,
  turb_set_reason_active     VARCHAR2(1) DEFAULT 'T' NOT NULL
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
COMMENT ON COLUMN at_turbine_setting_reason.turb_set_reason_code IS 'The unique id for this turbine_setting_type code record';
COMMENT ON COLUMN at_turbine_setting_reason.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_turbine_setting_reason.turb_set_reason_display_value IS 'The value to display for this turbine_setting_type record';
COMMENT ON COLUMN at_turbine_setting_reason.turb_set_reason_tooltip IS 'The description or meaning of this turbine_setting_type record';
COMMENT ON COLUMN at_turbine_setting_reason.turb_set_reason_active IS 'Whether this turbine_setting_type entry is currently active';

-- unique index
CREATE UNIQUE INDEX turbine_setting_reason_idx1 ON at_turbine_setting_reason
(db_office_code, UPPER(TURB_SET_REASON_DISPLAY_VALUE))
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

ALTER TABLE at_turbine_setting_reason ADD (
  CONSTRAINT at_turb_setting_reason_pk
 PRIMARY KEY
 (turb_set_reason_code)
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
ALTER TABLE at_turbine_setting_reason ADD (
  CONSTRAINT at_turbine_setting_reason_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_turbine_setting_reason ADD (
CONSTRAINT at_tst_active_ck
CHECK ( turb_set_reason_active = 'T' OR turb_set_reason_active = 'F'))
/

insert into at_turbine_setting_reason values(1, 53, 'S', 'Scheduled release to meet loads', 'T');
insert into at_turbine_setting_reason values(2, 53, 'F', 'Flood control release',           'T');
insert into at_turbine_setting_reason values(3, 53, 'W', 'Water supply release',            'T');
insert into at_turbine_setting_reason values(4, 53, 'Q', 'Water quality release',           'T');
insert into at_turbine_setting_reason values(5, 53, 'H', 'Hydropower release',              'T');
insert into at_turbine_setting_reason values(6, 53, 'O', 'Other release',                   'T');
commit;

create or replace trigger at_turbine_setting_reason_t1
   before insert or update or delete
   on at_turbine_setting_reason
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
end at_turbine_setting_reason_t1;
/
