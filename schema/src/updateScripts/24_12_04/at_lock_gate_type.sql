CREATE TABLE at_lock_gate_type
(
    chamber_type_code         NUMBER(14)            NOT NULL,
    db_office_code            NUMBER                NOT NULL,
    chamber_type_display_value VARCHAR2(50 BYTE)     NOT NULL,
    chamber_type_tooltip      VARCHAR2(255 BYTE)     NOT NULL,
    chamber_type_active       VARCHAR2(1 BYTE) DEFAULT 'T'  NOT NULL
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
COMMENT ON COLUMN at_lock_gate_type.chamber_type_code IS 'The unique id for this chamber_type code record';
COMMENT ON COLUMN at_lock_gate_type.db_office_code IS 'References the "owning" office.';
COMMENT ON COLUMN at_lock_gate_type.chamber_type_display_value IS 'The value to display for this chamber_type code record';
COMMENT ON COLUMN at_lock_gate_type.chamber_type_tooltip IS 'The tooltip or meaning of this chamber_type code record';
COMMENT ON COLUMN at_lock_gate_type.chamber_type_active IS 'Whether this chamber type entry is currently active';

-- unique index
CREATE UNIQUE INDEX lock_gate_type_idx1 ON at_lock_gate_type
    (db_office_code, UPPER("CHAMBER_TYPE_DISPLAY_VALUE"))
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

ALTER TABLE at_lock_gate_type ADD (
  CONSTRAINT at_lock_gate_type_pk
 PRIMARY KEY
 (chamber_type_code)
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
ALTER TABLE at_lock_gate_type ADD (
  CONSTRAINT at_lock_gate_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_lock_gate_type ADD (
CONSTRAINT at_lgt_active_ck
CHECK ( chamber_type_active = 'T' OR chamber_type_active = 'F'))
/

INSERT INTO at_lock_gate_type (chamber_type_code, db_office_code, chamber_type_display_value, chamber_type_tooltip, chamber_type_active)VALUES (1, 53, 'Single Chamber', 'A lock gate system with a single chamber', 'T');
INSERT INTO at_lock_gate_type (chamber_type_code, db_office_code, chamber_type_display_value, chamber_type_tooltip, chamber_type_active)VALUES (2, 53, 'Land Side Main', 'The main chamber on the land side of the lock', 'T');
INSERT INTO at_lock_gate_type (chamber_type_code, db_office_code, chamber_type_display_value, chamber_type_tooltip, chamber_type_active)VALUES (3, 53, 'Land Side Aux', 'An auxiliary chamber on the land side of the lock', 'T');
INSERT INTO at_lock_gate_type (chamber_type_code, db_office_code, chamber_type_display_value, chamber_type_tooltip, chamber_type_active)VALUES (4, 53, 'River Side Main', 'The main chamber on the river side of the lock', 'T');
INSERT INTO at_lock_gate_type (chamber_type_code, db_office_code, chamber_type_display_value, chamber_type_tooltip, chamber_type_active)VALUES (5, 53, 'River Side Aux', 'An auxiliary chamber on the river side of the lock', 'T');
