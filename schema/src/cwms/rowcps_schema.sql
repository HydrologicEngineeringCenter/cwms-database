WHENEVER sqlerror exit sql.sqlcode
SET define on
-- @@../cwms/defines.sql
@@defines.sql

SET serveroutput on

----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------

DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   table_names       id_array_t
      := id_array_t ('AT_CONSTRUCTION_HISTORY',
           'AT_DOCUMENT',
           'AT_EMBANKMENT',
           'AT_GATE_SETTING',
           'AT_LOCK',
           'AT_LOCKAGE',
           'AT_GATE_CHANGE',
           'AT_TURBINE_CHANGE',
           'AT_OUTLET',
           'AT_PROJECT',
           'AT_PROJECT_AGREEMENT',
           'AT_PROJECT_CONGRESS_DISTRICT',
           'AT_PROJECT_LOCK',
           'AT_PROJECT_PURPOSES',
           'AT_PRJ_LCK_REVOKER_RIGHTS',
           'AT_TURBINE',
           'AT_TURBINE_SETTING',
           'AT_WAT_USR_CONTRACT_ACCOUNTING',
           'AT_WATER_USER_CONTRACT',
           'AT_WATER_USER',
           'AT_XREF_WAT_USR_CONTRACT_DOCS',
           'AT_DOCUMENT_TYPE',
           'AT_EMBANK_PROTECTION_TYPE',
           'AT_EMBANK_STRUCTURE_TYPE',
           'AT_GATE_CH_COMPUTATION_CODE',
           'AT_GATE_RELEASE_REASON_CODE',
           'AT_PHYSICAL_TRANSFER_TYPE',
           'AT_PROJECT_PURPOSE',
           'AT_TURBINE_SETTING_REASON',
           'AT_TURBINE_COMPUTATION_CODE',
           'AT_WS_CONTRACT_TYPE',
           'AT_OPERATIONAL_STATUS_CODE',
           'AT_OUTLET_CHARACTERISTIC',
           'AT_TURBINE_CHARACTERISTIC'
                    );
   mview_log_names   id_array_t
      := id_array_t (' '
                    );
BEGIN
   FOR i IN table_names.FIRST .. table_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop table '
                           || table_names (i)
                           || ' cascade constraints purge';

         DBMS_OUTPUT.put_line ('Dropped table ' || table_names (i));
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;

   FOR i IN mview_log_names.FIRST .. mview_log_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop materialized view log on '
                           || mview_log_names (i);

         DBMS_OUTPUT.put_line (   'Dropped materialized view log on '
                               || mview_log_names (i)
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/

-------------------
-- CREATE TABLES --
-------------------

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

--------
--------

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


--------
--------

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
--------
--------

CREATE TABLE at_document_type
(
  document_type_code          NUMBER(14)      NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  document_type_display_value           VARCHAR2(25 BYTE)         NOT NULL,
  document_type_tooltip       VARCHAR2(255 BYTE)    NOT NULL,
  document_type_active        VARCHAR2(1 BYTE) DEFAULT 'T'  NOT NULL
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
COMMENT ON COLUMN at_document_type.document_type_code IS 'The unique id for this document_type record';
COMMENT ON COLUMN at_document_type.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_document_type.document_type_display_value IS 'The value to display for this document_type record';
COMMENT ON COLUMN at_document_type.document_type_tooltip IS 'The tooltip or meaning of this document_type record';
COMMENT ON COLUMN at_document_type.document_type_active IS 'Whether this document type entry is currently active';

-- unique index
CREATE UNIQUE INDEX document_type_idx1 ON at_document_type
(db_office_code, UPPER("DOCUMENT_TYPE_DISPLAY_VALUE"))
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

ALTER TABLE at_document_type ADD (
  CONSTRAINT at_doc_document_type_pk
 PRIMARY KEY
 (document_type_code)
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
ALTER TABLE at_document_type ADD (
  CONSTRAINT at_document_type_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_document_type ADD (
CONSTRAINT at_dt_active_ck
CHECK ( document_type_active = 'T' OR document_type_active = 'F'))
/

INSERT INTO at_document_type VALUES (1, 53, 'TS Uploaded CSVs',     'TS Uploaded CSVs',    'T');
INSERT INTO at_document_type VALUES (2, 53, 'COE Office Page',      'COE Office Page',     'T');
INSERT INTO at_document_type VALUES (3, 53, 'Wikipedia URLs',       'Wikipedia URLs',      'T');
INSERT INTO at_document_type VALUES (4, 53, 'Water Control Manual', 'Water Control Manual','T');
INSERT INTO at_document_type VALUES (5, 53, 'Other Documents',      'Other Documents',     'T');
--------
--------

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
--------
--------

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

--------
--------

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

--------
--------

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


--------
--------

CREATE TABLE at_turbine_computation_code
(
  turbine_comp_code       NUMBER(14)        NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  turbine_comp_display_value      VARCHAR2(25 BYTE)   NOT NULL,
  turbine_comp_tooltip     VARCHAR2(255 BYTE)    NOT NULL,
  turbine_comp_active      VARCHAR2(1) DEFAULT 'T' NOT NULL
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

COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_code IS 'The unique id for this turbine_computation_code record';
COMMENT ON COLUMN at_turbine_computation_code.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_display_value IS 'The value to display for this at_turbine_computation_code record';
COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_tooltip IS 'The description or meaning of this at_turbine_computation_code record';
COMMENT ON COLUMN at_turbine_computation_code.turbine_comp_active IS 'Whether this at_turbine_computation_code entry is currently active';

-- unique index
CREATE UNIQUE INDEX turbine_computation_code_idx1 ON at_turbine_computation_code
(db_office_code, UPPER(TURBINE_COMP_DISPLAY_VALUE))
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

ALTER TABLE at_turbine_computation_code ADD (
  CONSTRAINT at_turb_computation_code_pk
 PRIMARY KEY
 (turbine_comp_code)
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
ALTER TABLE at_turbine_computation_code ADD (
  CONSTRAINT at_turbine_computation_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

ALTER TABLE at_turbine_computation_code ADD (
CONSTRAINT at_tcc_active_ck
CHECK ( turbine_comp_active = 'T' OR turbine_comp_active = 'F'))
/

insert into at_turbine_computation_code values(1, 53, 'C', 'Calculated from turbine load-nethead curves', 'T');
insert into at_turbine_computation_code values(2, 53, 'T', 'Calculated from tailwater curve',             'T');
insert into at_turbine_computation_code values(3, 53, 'R', 'Reported by powerhouse',                      'T');
insert into at_turbine_computation_code values(4, 53, 'A', 'Adjusted by an automated method',             'T');

--------
--------

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

--------
--------

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

-- INSERT INTO at_operational_status_code VALUES (0, 53, 'Default', 'Default', 'T');


--------
--------

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

--------
--------

create or replace trigger at_document_type_t1
   before insert or update or delete
   on at_document_type
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
end at_document_type_t1;
/
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
create or replace trigger at_turbine_computation_code_t1
   before insert or update or delete
   on at_turbine_computation_code
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
end at_turbine_computation_code_t1;
/
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

--------
--------

CREATE TABLE at_project
(
  project_location_code       NUMBER(14)          NOT NULL,
  federal_cost          NUMBER,
  nonfederal_cost       NUMBER,
  cost_year         DATE,
  federal_om_cost       BINARY_DOUBLE,
  nonfederal_om_cost        BINARY_DOUBLE,
  authorizing_law       VARCHAR2(512),
  project_owner         VARCHAR2(255),
  hydropower_description      VARCHAR2(255),
  sedimentation_description     VARCHAR2(255 BYTE),
  downstream_urban_description            VARCHAR2(255 BYTE),
  bank_full_capacity_description          VARCHAR2(255 BYTE),
  pump_back_location_code     NUMBER(14),
  near_gage_location_code     NUMBER(14),
  yield_time_frame_start      DATE,
  yield_time_frame_end        DATE,
  project_remarks       VARCHAR2(1000 BYTE)
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
COMMENT ON COLUMN at_project.project_location_code IS 'Unique record identifier for this project. THis code is also in AT_PHYSICAL_LOCATION';
COMMENT ON COLUMN at_project.authorizing_law IS 'A semicolon separated list of laws authorizing this project';
COMMENT ON COLUMN at_project.federal_cost IS 'The federal cost of this project';
COMMENT ON COLUMN at_project.nonfederal_cost IS 'The non-federal cost of this project';
COMMENT ON COLUMN at_project.cost_year IS 'The year the project cost data is from';
COMMENT ON COLUMN at_project.federal_om_cost IS 'The om federal cost of this project';
COMMENT ON COLUMN at_project.nonfederal_om_cost IS 'the non-federal cost of this project';
COMMENT ON COLUMN at_project.project_remarks IS 'The general remarks regarding this project';
COMMENT ON COLUMN at_project.project_owner IS 'The assigned owner of this project';
COMMENT ON COLUMN at_project.hydropower_description IS 'The description of the hydro-power located at this project';
COMMENT ON COLUMN at_project.pump_back_location_code IS 'The location code where the water is pumped back to';
COMMENT ON COLUMN at_project.near_gage_location_code IS 'The location code known as the near gage for the project';
COMMENT ON COLUMN at_project.sedimentation_description IS 'The description of the projects sedimentation';
COMMENT ON COLUMN at_project.downstream_urban_description IS 'The description of the urban area downstream';
COMMENT ON COLUMN at_project.bank_full_capacity_description IS 'The description of the full capacity';
COMMENT ON COLUMN at_project.yield_time_frame_start IS 'The start date of the yield time frame.  The actual yield value is a flow value and therefore it is stored in the table SPECIFIED_LEVEL.';
COMMENT ON COLUMN at_project.yield_time_frame_end IS 'The end date of the yield time frame.  The actual yield value is a flow value and therefore it is stored in the table SPECIFIED_LEVEL.';

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_pk
 PRIMARY KEY
 (project_location_code)
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

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk2
 FOREIGN KEY (pump_back_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_project ADD (
  CONSTRAINT at_project_fk3
 FOREIGN KEY (near_gage_location_code)
 REFERENCES at_physical_location (location_code))
/

--------
--------

CREATE TABLE at_embankment
(
  embankment_location_code    NUMBER(14)                NOT NULL,
  embankment_project_loc_code         NUMBER(14)      NOT NULL,
  structure_type_code     NUMBER(14)      NOT NULL,
  structure_length      BINARY_DOUBLE,
  upstream_prot_type_code   NUMBER(14),
  upstream_sideslope      BINARY_DOUBLE,
  downstream_prot_type_code   NUMBER(14),
  downstream_sideslope      BINARY_DOUBLE,
  height_max          BINARY_DOUBLE,
  top_width           BINARY_DOUBLE
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
COMMENT ON COLUMN at_embankment.embankment_location_code IS 'The physical location code for this embankment structure';
COMMENT ON COLUMN at_embankment.embankment_project_loc_code IS 'The project location_code this embankment is a child of';
COMMENT ON COLUMN at_embankment.structure_type_code IS 'The lookup code for the type of the embankment structure';
COMMENT ON COLUMN at_embankment.structure_length IS 'The overall length of the embankment structure';
COMMENT ON COLUMN at_embankment.upstream_prot_type_code IS 'The upstream protection type code for the embankment structure';
COMMENT ON COLUMN at_embankment.upstream_sideslope IS 'The upstream side slope of the embankment structure';
COMMENT ON COLUMN at_embankment.downstream_prot_type_code IS 'The downstream protection type code for the embankment structure';
COMMENT ON COLUMN at_embankment.downstream_sideslope IS 'The downstream side slope of the embankment structure';
COMMENT ON COLUMN at_embankment.height_max IS 'The maximum height of the embankment structure';
COMMENT ON COLUMN at_embankment.top_width IS 'The width at the top of the embankment structure';

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_pk
 PRIMARY KEY
 (embankment_location_code)
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



ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk1
 FOREIGN KEY (embankment_location_code)
 REFERENCES at_physical_location (location_code))
/
ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk2
 FOREIGN KEY (embankment_project_loc_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk3
 FOREIGN KEY (structure_type_code)
 REFERENCES at_embank_structure_type (structure_type_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk4
 FOREIGN KEY (upstream_prot_type_code)
 REFERENCES at_embank_protection_type (protection_type_code))
/

ALTER TABLE at_embankment ADD (
  CONSTRAINT at_embankment_fk5
 FOREIGN KEY (downstream_prot_type_code)
 REFERENCES at_embank_protection_type (protection_type_code))
/

--------
--------
CREATE TABLE at_lock
(
   lock_location_code                 NUMBER(14) NOT NULL,
   project_location_code              NUMBER(14) NOT NULL,
   lock_width                         BINARY_DOUBLE,
   lock_length                        BINARY_DOUBLE,
   volume_per_lockage                 BINARY_DOUBLE,
   minimum_draft                      BINARY_DOUBLE,
   normal_lock_lift                   BINARY_DOUBLE,
   units_id                           VARCHAR2(16),
   maximum_lock_lift                  BINARY_DOUBLE,
   chamber_location_description_code  NUMBER(14)
)
   TABLESPACE cwms_20at_data
   PCTUSED 0
   PCTFREE 10
   INITRANS 1
   MAXTRANS 255
   STORAGE
(
   INITIAL
   504 k
   MINEXTENTS
   1
   MAXEXTENTS
   2147483645
   PCTINCREASE
   0
   BUFFER_POOL
   DEFAULT
)
   LOGGING
   NOCOMPRESS
   NOCACHE
   NOPARALLEL
   MONITORING
/
COMMENT ON COLUMN at_lock.lock_location_code IS 'Unique record identifier for this lock, also in at_physical_location';
COMMENT ON COLUMN at_lock.project_location_code IS 'The project that this lock is part of';
COMMENT ON COLUMN at_lock.lock_width IS 'The width of the lock chamber';
COMMENT ON COLUMN at_lock.lock_length IS 'The length of the lock chamber';
COMMENT ON COLUMN at_lock.volume_per_lockage IS 'The volume of water discharged for one lockage at normal headwater and tailwater elevations.  This volume includes any flushing water.';
COMMENT ON COLUMN at_lock.minimum_draft IS 'The minimum depth of water that is maintained for vessels for this particular lock';
COMMENT ON COLUMN at_lock.maximum_lock_lift IS 'The maximum lift the lock can support';
COMMENT ON COLUMN at_lock.chamber_location_description_code IS 'A single chamber, land side main, land side aux, river side main, river side aux.';

CREATE UNIQUE INDEX at_lock_idx_1 ON at_lock
   (lock_location_code, project_location_code)
   /

ALTER TABLE at_lock
   ADD (
      CONSTRAINT at_lock_pk
         PRIMARY KEY
            (lock_location_code)
            USING INDEX
               TABLESPACE cwms_20at_data
               PCTFREE 10
               INITRANS 2
               MAXTRANS 255
               STORAGE (
               INITIAL 64 k
               MINEXTENTS 1
               MAXEXTENTS 2147483645
               PCTINCREASE 0
               ))
/

ALTER TABLE at_lock
   ADD (
      CONSTRAINT at_lock_fk1
         FOREIGN KEY (lock_location_code)
            REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_lock
   ADD (
      CONSTRAINT at_lock_fk2
         FOREIGN KEY (project_location_code)
            REFERENCES at_project (project_location_code))
/


CREATE TABLE at_lockage
(
  lockage_code        NUMBER(14)      NOT NULL,
  lockage_location_code     NUMBER(14)      NOT NULL,
  lockage_datetime      DATE        NOT NULL,
  number_boats        BINARY_DOUBLE,
  number_barges       BINARY_DOUBLE,
  tonnage       BINARY_DOUBLE,
  is_tow_upbound      VARCHAR2(1 BYTE)                NOT NULL,
  is_lock_chamber_emptying              VARCHAR2(1 BYTE)                NOT NULL,
  lockage_notes       VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_lockage.lockage_code IS 'Unique record identifier for every lockage on a project.  IS automatically generated.';
COMMENT ON COLUMN at_lockage.lockage_location_code IS 'The lock at which this lockage occurred.  SEE AT_LOCK';
COMMENT ON COLUMN at_lockage.lockage_datetime IS 'The date and time of the lockage';
COMMENT ON COLUMN at_lockage.number_boats IS 'The number of boats accommodated in this lockage';
COMMENT ON COLUMN at_lockage.number_barges IS 'The number of barges accommodated in this lockage';
COMMENT ON COLUMN at_lockage.tonnage IS 'The tonnage of product accommodated in this lockage';
COMMENT ON COLUMN at_lockage.is_tow_upbound IS 'A boolean-equivalent value for the direction of boats and barges for this lockage.  Constrained to T or F by a check constraint.';
COMMENT ON COLUMN at_lockage.is_lock_chamber_emptying IS 'A boolean-equivalent value for whether the lockage operation of this record was emptying or filling the lock chamber.  Constrained to T or F by a check constraint.';
COMMENT ON COLUMN at_lockage.lockage_notes IS 'Any notes pertinent to this lockage';


ALTER TABLE at_lockage ADD (
  CONSTRAINT at_lockage_pk
 PRIMARY KEY
 (lockage_code)
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

CREATE UNIQUE INDEX at_lockage_idx_1 ON at_lockage
(lockage_location_code,lockage_datetime)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_lockage ADD (
  CONSTRAINT at_lockage_fk1
 FOREIGN KEY (lockage_location_code)
 REFERENCES at_lock (lock_location_code))
/
ALTER TABLE at_lockage ADD (
CONSTRAINT at_lockage_is_tow_upbound_ck
CHECK ( is_tow_upbound = 'T' OR is_tow_upbound = 'F'))
/
ALTER TABLE at_lockage ADD (
CONSTRAINT at_lockage_is_lock_emptying_ck
CHECK ( is_lock_chamber_emptying = 'T' OR is_lock_chamber_emptying = 'F'))
/

--------
--------

CREATE TABLE at_turbine_characteristic
(
  turbine_characteristic_code           NUMBER(14)                      NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  turbine_characteristic_id VARCHAR2(64 BYTE)   NOT NULL,
  rated_power_capacity      BINARY_DOUBLE,
  max_power_overload                    BINARY_DOUBLE,
  min_generation_flow     BINARY_DOUBLE,
  max_generation_flow     BINARY_DOUBLE,
  turbine_operation_rule_set    VARCHAR2(255 BYTE),
  turbine_general_description   VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_turbine_characteristic.turbine_characteristic_code IS 'The automatically generated unique surrogate key';
COMMENT ON COLUMN at_turbine_characteristic.db_office_code IS 'The office code for this turbine characteristic';
COMMENT ON COLUMN at_turbine_characteristic.turbine_characteristic_id IS 'The name of this turbine characteristic';
COMMENT ON COLUMN at_turbine_characteristic.rated_power_capacity IS 'The nameplate power generating capacity for this turbine';
COMMENT ON COLUMN at_turbine_characteristic.max_power_overload IS 'The maximum percentage of nameplate power that this turbine type can run in overload mode';
COMMENT ON COLUMN at_turbine_characteristic.min_generation_flow IS 'The minimum flow required to utilize the turbine';
COMMENT ON COLUMN at_turbine_characteristic.max_generation_flow IS 'The maximum flow capacity for the turbine';
COMMENT ON COLUMN at_turbine_characteristic.turbine_general_description IS 'The genearl description of this class of turbines';
COMMENT ON COLUMN at_turbine_characteristic.turbine_operation_rule_set IS 'The operational rule set for this turbine';


ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_pk
 PRIMARY KEY
 (turbine_characteristic_code)
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
ALTER TABLE at_turbine_characteristic ADD (
  CONSTRAINT at_turbine_characteristic_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
-- unique index
CREATE UNIQUE INDEX at_turbine_characteristic_idx1 ON at_turbine_characteristic
(db_office_code, UPPER("TURBINE_CHARACTERISTIC_ID"))
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


--------
--------

CREATE TABLE at_turbine
(
  turbine_location_code     NUMBER(14)      NOT NULL,
  project_location_code                 NUMBER(14)      NOT NULL
--  turbine_characteristic_code           NUMBER(14)                      NOT NULL
--  turbine_description     VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_turbine.turbine_location_code IS 'The actual turbine this record refers to.  The location_code also in AT_PHYSICAL_LOCATION';
COMMENT ON COLUMN at_turbine.project_location_code IS 'The project this turbine is part of.  See AT_PROJECT.project_location_code';
--COMMENT ON COLUMN at_turbine.turbine_characteristic_code IS 'The code for the foreign key record in the AT_TURBINE_CHARACTERISTIC table which describes turbine geometry and features.';
-- COMMENT ON COLUMN at_turbine.turbine_description IS 'The description of the turbine';

ALTER TABLE at_turbine ADD (
  CONSTRAINT at_turbine_pk
 PRIMARY KEY
 (turbine_location_code)
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
CREATE UNIQUE INDEX at_turbine_idx_1 ON at_turbine
(turbine_location_code,project_location_code)--,turbine_characteristic_code)
tablespace cwms_20at_data
/
ALTER TABLE at_turbine ADD (
  CONSTRAINT at_turbine_fk1
 FOREIGN KEY (turbine_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_turbine ADD (
  CONSTRAINT at_turbine_fk2
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

--ALTER TABLE at_turbine ADD (
--  CONSTRAINT at_turbine_fk3
-- FOREIGN KEY (turbine_characteristic_code)
-- REFERENCES at_turbine_characteristic (turbine_characteristic_code))
--/

--------
--------

CREATE TABLE at_turbine_change
(
  turbine_change_code             NUMBER(14)     NOT NULL,
  project_location_code           NUMBER(14)     NOT NULL,
  turbine_change_datetime         DATE           NOT NULL,
  elev_pool                       BINARY_DOUBLE,
  elev_tailwater                  BINARY_DOUBLE,
  turbine_setting_reason_code     NUMBER(14)     NOT NULL,
  turbine_discharge_comp_code     NUMBER(14)     NOT NULL,
  old_total_discharge_override    BINARY_DOUBLE,
  new_total_discharge_override    BINARY_DOUBLE,
  turbine_change_notes            VARCHAR2(255 BYTE),
  protected                       VARCHAR2(1)    NOT NULL
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
COMMENT ON COLUMN at_turbine_change.turbine_change_code IS 'Unique record identifier for every turbine change on a project.  IS automatically created';
COMMENT ON COLUMN at_turbine_change.project_location_code IS 'The project this turbine change refers to';
COMMENT ON COLUMN at_turbine_change.turbine_change_datetime IS 'The date and time of the turbine change';
COMMENT ON COLUMN at_turbine_change.elev_pool IS 'The headwater pool elevation at the time of the turbine change';
COMMENT ON COLUMN at_turbine_change.elev_tailwater IS 'The tailwater elevation at the time of the turbine change';
COMMENT ON COLUMN at_turbine_change.turbine_setting_reason_code IS 'The new turbine setting reason lookup code.  Examples of reasons are spin-noload, overload, dump energy, peaking, testing, etc.';
COMMENT ON COLUMN at_turbine_change.turbine_discharge_comp_code IS 'The new turbine setting discharge computation lookup code';
COMMENT ON COLUMN at_turbine_change.old_total_discharge_override IS 'The total Q rate before the turbine change.  This value is from a manual entry or other external data source and overrides the calculated Q for the group of turbines.';
COMMENT ON COLUMN at_turbine_change.new_total_discharge_override IS 'The total Q rate after the turbine change.  This value is from a manual entry or other external data source and overrides the calculated Q for the group of turbines.';
COMMENT ON COLUMN at_turbine_change.turbine_change_notes IS 'Any notes pertinent to this turbine change';

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_pk
 PRIMARY KEY
 (turbine_change_code)
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

CREATE UNIQUE INDEX at_turbine_change_idx_1 ON at_turbine_change
(project_location_code,turbine_change_datetime)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_fk2
 FOREIGN KEY (turbine_setting_reason_code)
 REFERENCES at_turbine_setting_reason (turb_set_reason_code))
/

ALTER TABLE at_turbine_change ADD (
  CONSTRAINT at_turbine_change_fk3
 FOREIGN KEY (turbine_discharge_comp_code)
 REFERENCES at_turbine_computation_code (turbine_comp_code))
/


--------
--------

CREATE TABLE at_turbine_setting
(
  turbine_setting_code  NUMBER(14)      NOT NULL,
  turbine_change_code   NUMBER(14)      NOT NULL,
  turbine_location_code NUMBER(14)      NOT NULL,
  old_discharge         BINARY_DOUBLE   NOT NULL,
  new_discharge         BINARY_DOUBLE   NOT NULL,
  scheduled_load        BINARY_DOUBLE,
  real_power            BINARY_DOUBLE
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

COMMENT ON COLUMN at_turbine_setting.turbine_setting_code IS 'The surrogate key for this individual turbine change event.  Automatically generated surrogate key.';
COMMENT ON COLUMN at_turbine_setting.turbine_change_code IS 'The turbine change record to which this setting is associated.  See AT_TURBINE_CHANGE';
COMMENT ON COLUMN at_turbine_setting.turbine_location_code IS 'The unique individual turbine that is being changed';
COMMENT ON COLUMN at_turbine_setting.scheduled_load IS 'The scheduled load for the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.old_discharge IS 'The discharge prior to the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.new_discharge IS 'The discharge after the new turbine setting';
COMMENT ON COLUMN at_turbine_setting.real_power IS 'The real power generation for the new turbine setting';

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_pk
 PRIMARY KEY
 (turbine_setting_code)
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

CREATE UNIQUE INDEX at_turbine_setting_idx_1 ON at_turbine_setting
(turbine_change_code,turbine_location_code)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk1
 FOREIGN KEY (turbine_change_code)
 REFERENCES at_turbine_change (turbine_change_code))
/

ALTER TABLE at_turbine_setting ADD (
  CONSTRAINT at_turbine_setting_fk2
 FOREIGN KEY (turbine_location_code)
 REFERENCES at_turbine (turbine_location_code))
/

--------
--------

CREATE TABLE at_project_congress_district
(
  project_congress_location_code  NUMBER(14)      NOT NULL,
  project_congress_state_code   NUMBER(14)      NOT NULL,
  congressional_district    NUMBER(14)      NOT NULL,
  congress_district_remarks   VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_project_congress_district.project_congress_location_code IS 'The project this congressional district record is a child to';
COMMENT ON COLUMN at_project_congress_district.project_congress_state_code IS 'The surrogate key (code) for the state this project is located in';
COMMENT ON COLUMN at_project_congress_district.congressional_district IS 'The congressional district of the project';
COMMENT ON COLUMN at_project_congress_district.congress_district_remarks IS 'Any remarks associated with this states congressional district regarding this project';

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_proj_congress_district_pk
 PRIMARY KEY
 (project_congress_location_code,project_congress_state_code,congressional_district)
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

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_proj_cong_district_fk1
 FOREIGN KEY (project_congress_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_project_congress_district ADD (
  CONSTRAINT at_proj_cong_district_fk2
 FOREIGN KEY (project_congress_state_code)
 REFERENCES cwms_state (state_code))
/

--------
--------

CREATE TABLE at_gate_change
(
  gate_change_code             NUMBER(14)    NOT NULL,
  project_location_code        NUMBER(14)    NOT NULL,
  gate_change_date             DATE          NOT NULL,
  elev_pool                    BINARY_DOUBLE NOT NULL,
  elev_tailwater               BINARY_DOUBLE,
  old_total_discharge_override BINARY_DOUBLE,
  new_total_discharge_override BINARY_DOUBLE,
  discharge_computation_code   NUMBER(14)    NOT NULL,
  release_reason_code          NUMBER(14)    NOT NULL,
  gate_change_notes            VARCHAR2(255 BYTE),
  protected                    VARCHAR2(1)   NOT NULL,
  reference_elev               BINARY_DOUBLE
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
COMMENT ON COLUMN at_gate_change.gate_change_code IS 'Unique record identifier for every gate change on a project.  IS automatically created';
COMMENT ON COLUMN at_gate_change.project_location_code IS 'The project this gate change pertains to';
COMMENT ON COLUMN at_gate_change.gate_change_date IS 'The date and time of the gate change';
COMMENT ON COLUMN at_gate_change.elev_pool IS 'The headwater pool elevation at the time of the gate change';
COMMENT ON COLUMN at_gate_change.elev_tailwater IS 'The tailwater elevation at the time of the gate change';
COMMENT ON COLUMN at_gate_change.old_total_discharge_override IS 'The total discharge rate just before the gate change.  This value is from a manual entry or other external data source and overrides the calculated Q for the projects outlet works.';
COMMENT ON COLUMN at_gate_change.new_total_discharge_override IS 'The total discharge rate just after the gate change. This value is from a manual entry or other external data source and overrides the calculated Q for the projects outlet works.';
COMMENT ON COLUMN at_gate_change.discharge_computation_code IS 'The code for the discharge computation method for the gate change. Values are restricted by a foreign key to a lookup table.';
COMMENT ON COLUMN at_gate_change.release_reason_code IS 'The code for the release reason (or purpose) issued for the gate change.  Values are restricted by a foreign key to a lookup table.';
COMMENT ON COLUMN at_gate_change.gate_change_notes IS 'Any notes pertinent to this gate change';
COMMENT ON COLUMN at_gate_change.protected IS 'Specifies whether this gate change is protected from inadvertent overwrites';
COMMENT ON COLUMN at_gate_change.reference_elev IS 'An additional reference elevation if required to describe this gate change';

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_pk
 PRIMARY KEY
 (gate_change_code)
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

CREATE UNIQUE INDEX at_gate_change_idx_1 ON at_gate_change
(project_location_code,gate_change_date)
LOGGING
tablespace cwms_20at_data
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

alter table at_gate_change add constraint at_gate_change_ck1 check (protected in ('T', 'F'));

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_fk2
 FOREIGN KEY (discharge_computation_code)
 REFERENCES at_gate_ch_computation_code (discharge_comp_code))
/

ALTER TABLE at_gate_change ADD (
  CONSTRAINT at_gate_change_fk3
 FOREIGN KEY (release_reason_code)
 REFERENCES at_gate_release_reason_code (release_reason_code))
/

--------
--------

CREATE TABLE at_outlet_characteristic
(
  outlet_characteristic_code      NUMBER(14)         NOT NULL,
  db_office_code      NUMBER                    NOT NULL,
  outlet_characteristic_id VARCHAR2(64 BYTE)   NOT NULL,
  opening_parameter_code                        NUMBER(14)             NOT NULL,
  height          BINARY_DOUBLE,
  width           BINARY_DOUBLE,
  opening_radius        BINARY_DOUBLE,
  elev_invert         BINARY_DOUBLE,
  flow_capacity_max       BINARY_DOUBLE,
  net_length_spillway       BINARY_DOUBLE,
  spillway_notch_length             BINARY_DOUBLE,
  outlet_general_description                    VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_outlet_characteristic.outlet_characteristic_code IS 'The automatically generated surrogate unique key for this record';
COMMENT ON COLUMN at_outlet_characteristic.db_office_code IS 'The office code that this characteristic is assigned to';
COMMENT ON COLUMN at_outlet_characteristic.outlet_characteristic_id IS 'The name of this outlet characteristic';
COMMENT ON COLUMN at_outlet_characteristic.opening_parameter_code IS 'A foreign key to an AT_PARAMETER record that constrains the gate opening to a defined parameter and unit.';
COMMENT ON COLUMN at_outlet_characteristic.height IS 'The height of the gate';
COMMENT ON COLUMN at_outlet_characteristic.width IS 'The width of the gate';
COMMENT ON COLUMN at_outlet_characteristic.opening_radius IS 'The radius of the pipe or circular conduit that this outlet is a control for.  This is not applicable to rectangular outlets, tainter gates, or uncontrolled spillways';
COMMENT ON COLUMN at_outlet_characteristic.elev_invert IS 'The elevation of the invert for the outlet';
COMMENT ON COLUMN at_outlet_characteristic.flow_capacity_max IS 'The maximum flow capacity of the gate';
COMMENT ON COLUMN at_outlet_characteristic.net_length_spillway IS 'The net length of the spillway';
COMMENT ON COLUMN at_outlet_characteristic.spillway_notch_length IS 'The length of the spillway notch';

ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_pk
 PRIMARY KEY
 (outlet_characteristic_code)
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
ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_fk1
 FOREIGN KEY (opening_parameter_code)
 REFERENCES at_parameter (parameter_code))
/
ALTER TABLE at_outlet_characteristic ADD (
  CONSTRAINT at_outlet_characteristic_fk2
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
-- unique index
CREATE UNIQUE INDEX at_outlet_characteristic_idx1 ON at_outlet_characteristic
(db_office_code, UPPER("OUTLET_CHARACTERISTIC_ID"))
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
--------
--------

CREATE TABLE at_outlet
(
  outlet_location_code              NUMBER(14)      NOT NULL,
  project_location_code                         NUMBER(14)      NOT NULL
--  outlet_characteristic_code        NUMBER(14)                      NOT NULL
  --outlet_description                            VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_outlet.outlet_location_code IS 'The unique outlet this record is. Also in AT_OUTLET';
COMMENT ON COLUMN at_outlet.project_location_code IS 'The project where this outlet is located. ';
--COMMENT ON COLUMN at_outlet.outlet_characteristic_code IS 'The code for the foreign key record in the AT_OUTLET_CHARACTERISTIC table which describe outlet geometry, features, and hydraulic equation parameters.';
--COMMENT ON COLUMN at_outlet.outlet_description IS 'The specific description for this outlet structure.';

ALTER TABLE at_outlet ADD (
  CONSTRAINT at_outlet_pk
 PRIMARY KEY
 (outlet_location_code)
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
CREATE UNIQUE INDEX at_outlet_idx_1 ON at_outlet
(outlet_location_code,project_location_code)--,outlet_characteristic_code)
TABLESPACE CWMS_20AT_DATA
/

ALTER TABLE at_outlet ADD (
  CONSTRAINT at_outlet_fk1
 FOREIGN KEY (outlet_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_outlet ADD (
  CONSTRAINT at_outlet_fk2
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

--ALTER TABLE at_outlet ADD (
--  CONSTRAINT at_outlet_fk3
-- FOREIGN KEY (outlet_characteristic_code)
-- REFERENCES at_outlet_characteristic (outlet_characteristic_code))
--/

create table at_comp_outlet(
   compound_outlet_code  number(14)   primary key,
   project_location_code number(14)   not null,
   compound_outlet_id    varchar2(64) not null,
   constraint at_comp_outlet_fk1 foreign key (project_location_code) references at_project (project_location_code),
   constraint at_comp_outlet_ck1 check (trim(compound_outlet_id) = compound_outlet_id)
) organization index
  tablespace cwms_20at_data
;

comment on table  at_comp_outlet is 'Holds information about sequential outlet groups';
comment on column at_comp_outlet.compound_outlet_code  is 'Synthetic key';
comment on column at_comp_outlet.project_location_code is 'References project that has this compound outlet';
comment on column at_comp_outlet.compound_outlet_id    is 'Name of this compound outlet (unique per project)';

create unique index at_comp_outlet_idx1 on at_comp_outlet (project_location_code, upper(compound_outlet_id))
/

create table at_comp_outlet_conn (
   at_comp_outlet_conn_code number(14) primary key,
   compound_outlet_code     number(14) not null,
   outlet_location_code     number(14) not null,
   next_outlet_code         number(14),
   constraint at_comp_outlet_conn_fk1 foreign key (compound_outlet_code) references at_comp_outlet (compound_outlet_code),
   constraint at_comp_outlet_conn_fk2 foreign key (outlet_location_code) references at_outlet (outlet_location_code),
   constraint at_comp_outlet_conn_fk3 foreign key (next_outlet_code) references at_outlet (outlet_location_code),
   constraint at_comp_outlet_conn_ck1 check (outlet_location_code != nvl(next_outlet_code, 0))
) organization index
  tablespace cwms_20at_data
/

comment on table  at_comp_outlet_conn is 'Holds information about compound outlet connectivity';
comment on column at_comp_outlet_conn.at_comp_outlet_conn_code is 'Synthetic key';
comment on column at_comp_outlet_conn.compound_outlet_code     is 'References sequential outlet group';
comment on column at_comp_outlet_conn.outlet_location_code     is 'References outlet on the upstream side of the connection';
comment on column at_comp_outlet_conn.next_outlet_code         is 'References outlet on the downstream side of the connection (0 if outlet downstream-most in sequence)';

create unique index at_comp_outlet_conn_idx1 on at_comp_outlet_conn(compound_outlet_code, outlet_location_code, nvl(next_outlet_code, 0))
/
create index at_comp_outlet_conn_idx2 on at_comp_outlet_conn(outlet_location_code)
/

create or replace trigger at_comp_outlet_conn_tr1
   before insert
   on at_comp_outlet_conn
   referencing new as new old as old
   for each row
declare
   l_proj_code1 number(14);
   l_proj_code2 number(14);
begin
   select project_location_code
     into l_proj_code1
     from at_comp_outlet
    where compound_outlet_code = :new.compound_outlet_code;

   select project_location_code
     into l_proj_code2
     from at_outlet
    where outlet_location_code = :new.outlet_location_code;

   if l_proj_code1 != l_proj_code2 then
      cwms_err.raise('ERROR', 'Cannot assign outlet from one project to a compound outlet from another project');
   end if;

   if :new.next_outlet_code is not null then
      select project_location_code
        into l_proj_code2
        from at_outlet
       where outlet_location_code = :new.next_outlet_code;

      if l_proj_code1 != l_proj_code2 then
         cwms_err.raise('ERROR', 'Cannot assign outlet from one project to a compound outlet from another project');
      end if;
   end if;
end at_comp_outlet_conn_tr1;
/

--------
--------

CREATE TABLE at_gate_setting
(
  gate_setting_code     NUMBER(14)    NOT NULL,
  gate_change_code      NUMBER(14)    NOT NULL,
  outlet_location_code  NUMBER(14)    NOT NULL,
  gate_opening          BINARY_DOUBLE NOT NULL,
  invert_elev           BINARY_DOUBLE
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

COMMENT ON COLUMN at_gate_setting.gate_setting_code IS 'The unique record for the overall gate setting.  Automatically generated surrogate key.';
COMMENT ON COLUMN at_gate_setting.gate_change_code IS 'The gate change record to which this setting is associated.  See AT_GATE_CHANGE.';
COMMENT ON COLUMN at_gate_setting.outlet_location_code IS 'The unique gate that is being set. This location code also in AT_PHYSICAL_LOCATION';
COMMENT ON COLUMN at_gate_setting.gate_opening IS 'The new gate opening.  This may be a dial opening rather than an actual opening';
COMMENT ON COLUMN at_gate_setting.invert_elev IS 'The invert elevation if the gate supports variable inverts';

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_pk
 PRIMARY KEY
 (gate_setting_code)
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

CREATE UNIQUE INDEX at_gate_setting_idx_1 ON at_gate_setting
(gate_setting_code,outlet_location_code)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_fk1
 FOREIGN KEY (gate_change_code)
 REFERENCES at_gate_change (gate_change_code))
/

ALTER TABLE at_gate_setting ADD (
  CONSTRAINT at_gate_setting_fk2
 FOREIGN KEY (outlet_location_code)
 REFERENCES at_outlet (outlet_location_code))
/

--------
--------

CREATE TABLE at_document
(
  document_code          NUMBER(14)        NOT NULL,
  db_office_code         NUMBER            NOT NULL,
  document_id            VARCHAR2(64 BYTE) NOT NULL,
  document_type_code     NUMBER(14)        NOT NULL,
  document_location_code NUMBER(14),
  document_url           VARCHAR2(100 BYTE),
  document_date          DATE              NOT NULL,
  document_mod_date      DATE,
  document_obsolete_date DATE,
  document_preview_code  NUMBER(14),
  stored_document        NUMBER(14)
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
COMMENT ON COLUMN at_document.document_code IS 'The unique identifier for the individual document, system generated';
COMMENT ON COLUMN at_document.db_office_code IS 'Refererences the "owning" office.';
COMMENT ON COLUMN at_document.document_id IS 'The unique identifier for the individual document, user provided';
COMMENT ON COLUMN at_document.document_location_code IS 'The surrogate key from at_physical location that this document applies to.';
COMMENT ON COLUMN at_document.document_type_code IS 'The lu code for the type of the document';
COMMENT ON COLUMN at_document.document_url IS 'The URL where the document could be found';
COMMENT ON COLUMN at_document.document_date IS 'The initial date of the document';
COMMENT ON COLUMN at_document.document_mod_date IS 'The last modified date of the document';
COMMENT ON COLUMN at_document.document_obsolete_date IS 'The date the document became obsolete';
COMMENT ON COLUMN at_document.document_preview_code IS 'The surrogate key from AT_CLOB where the document is described';
COMMENT ON COLUMN at_document.stored_document IS 'The actual storage of the document';

-- unique index
CREATE UNIQUE INDEX at_document_idx1 ON at_document
(db_office_code, UPPER("DOCUMENT_ID"))
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

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_pk
 PRIMARY KEY
 (document_code)
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

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk1
 FOREIGN KEY (document_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk2
 FOREIGN KEY (document_preview_code)
 REFERENCES at_clob (clob_code))
/

ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk3
 FOREIGN KEY (document_type_code)
 REFERENCES at_document_type (document_type_code))
/

-- FK
ALTER TABLE at_document ADD (
  CONSTRAINT at_document_fk4
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/

alter table at_document add constraint at_document_fk5 foreign key(stored_document) references at_blob(blob_code)
/

--------
--------

CREATE TABLE at_water_user
(
   water_user_code       NUMBER(14)        NOT NULL,
   project_location_code NUMBER(14)        NOT NULL,
   entity_name           VARCHAR2(64 BYTE) NOT NULL,
   water_right           VARCHAR2(255 BYTE)
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

COMMENT ON COLUMN at_water_user.water_user_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_water_user.project_location_code IS 'The project that this user obtains water from. (This user may obtain water from more than one project.';
COMMENT ON COLUMN at_water_user.water_right IS 'A description of the water right of this user.  This may include a citation of the legal document that bestowed this right.';
COMMENT ON COLUMN at_water_user.entity_name IS 'The entity name associated with this user';

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_pk
 PRIMARY KEY
 (water_user_code)
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

CREATE UNIQUE INDEX at_water_user_idx1 ON at_water_user
(project_location_code,upper(entity_name))
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_water_user ADD (
  CONSTRAINT at_water_user_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

--------
--------


CREATE TABLE at_water_user_contract
(
   water_user_contract_code      NUMBER(14)        NOT NULL,
   water_user_code               NUMBER(14)        NOT NULL,
   contract_name                 VARCHAR2(64 BYTE) NOT NULL,
   contracted_storage            BINARY_DOUBLE     NOT NULL,
--   contract_documents            VARCHAR2(64 BYTE) NOT NULL,
   water_supply_contract_type    NUMBER(14)        NOT NULL,
   ws_contract_effective_date    DATE,
   ws_contract_expiration_date   DATE,
   initial_use_allocation        BINARY_DOUBLE,
   future_use_allocation         BINARY_DOUBLE,
   future_use_percent_activated  BINARY_DOUBLE,
   total_alloc_percent_activated BINARY_DOUBLE,
   pump_out_location_code      NUMBER(14), --pump-out
   pump_out_below_location_code          NUMBER(14), --pump-out below
   pump_in_location_code         NUMBER(14),
   storage_unit_code             NUMBER(14)
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
COMMENT ON COLUMN at_water_user_contract.water_user_contract_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_water_user_contract.water_user_code IS 'The water user that has a contract for water storage at a project.  See table AT_WATER_USER.';
COMMENT ON COLUMN at_water_user_contract.contract_name IS 'The identification name for the contract for this water user contract';
COMMENT ON COLUMN at_water_user_contract.contracted_storage IS 'The contracted storage amount for this water user contract';
--COMMENT ON COLUMN at_water_user_contract.contract_documents IS 'The documents for the contract';
COMMENT ON COLUMN at_water_user_contract.water_supply_contract_type IS 'The type of water supply contract.  Constrained by a foreign key to a lookup table';
COMMENT ON COLUMN at_water_user_contract.ws_contract_effective_date IS 'The start date of the contract for this water user contract';
COMMENT ON COLUMN at_water_user_contract.ws_contract_expiration_date IS 'The expiration date for the contract of this water user contract';
COMMENT ON COLUMN at_water_user_contract.initial_use_allocation IS 'The initial contracted allocation for this water user contract';
COMMENT ON COLUMN at_water_user_contract.future_use_allocation IS 'The future contracted allocation for this water user contract';
COMMENT ON COLUMN at_water_user_contract.future_use_percent_activated IS 'The percent allocated future use for this water user contract';
COMMENT ON COLUMN at_water_user_contract.total_alloc_percent_activated IS 'The percentage of total allocation for this water user contract';
COMMENT ON COLUMN at_water_user_contract.pump_out_location_code IS 'The code for the AT_PHYSICAL_LOCATION record which is the location where this water with be withdrawn from the permanent pool';
COMMENT ON COLUMN at_water_user_contract.pump_out_below_location_code IS 'The AT_PHYSICAL_LOCATION record which is the location where this water will be obtained below the dam or within the outlet works';
COMMENT ON COLUMN at_water_user_contract.pump_in_location_code IS 'The AT_PHYSICAL_LOCATION record that identifies the project sub location where water is released into the permanent pool by pumping or gravity flow';
COMMENT ON COLUMN at_water_user_contract.storage_unit_code IS 'The unit of storage for this water user contract';

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_pk
 PRIMARY KEY
 (water_user_contract_code)
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

CREATE UNIQUE INDEX at_water_user_contract_idx1 ON at_water_user_contract
(water_user_code,upper(contract_name))
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk2
 FOREIGN KEY (water_user_code)
 REFERENCES at_water_user (water_user_code))
/

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk3
 FOREIGN KEY (pump_out_location_code)
 REFERENCES at_pump (pump_location_code))
/
ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk1
 FOREIGN KEY (pump_out_below_location_code)
 REFERENCES at_pump (pump_location_code))
/
ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk6
 FOREIGN KEY (pump_in_location_code)
 REFERENCES at_pump (pump_location_code))
/

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk4
 FOREIGN KEY (water_supply_contract_type)
 REFERENCES at_ws_contract_type (ws_contract_type_code))
/

ALTER TABLE at_water_user_contract ADD (
  CONSTRAINT at_water_user_contract_fk5
 FOREIGN KEY (storage_unit_code)
 REFERENCES cwms_unit (unit_code))
/

create or replace trigger at_water_user_contract_t01
for insert or update of pump_out_location_code, pump_out_below_location_code, pump_in_location_code
on at_water_user_contract
compound trigger

   type l_pumps_t is table of boolean index by varchar2(16);
   l_pumps l_pumps_t;

   before statement is
   begin
      for rec in (select pump_out_location_code as pump_code
                    from at_water_user_contract
                   where pump_out_location_code is not null
                  union all
                  select pump_out_below_location_code as pump_code
                    from at_water_user_contract
                   where pump_out_below_location_code is not null
                  union all
                  select pump_in_location_code as pump_code
                    from at_water_user_contract
                   where pump_in_location_code is not null
                 )
      loop
         l_pumps(to_char(rec.pump_code)) := true;
      end loop;
   end before statement;

   before each row is
   begin
      if :new.pump_out_location_code       = :new.pump_out_below_location_code or
         :new.pump_out_location_code       = :new.pump_in_location_code        or
         :new.pump_out_below_location_code = :new.pump_in_location_code
      then
         cwms_err.raise('ERROR', 'Water supply contract cannot have same pump in mulitple locations');
      end if;
      -----------------------
      -- pump_out_location --
      -----------------------
      if :new.pump_out_location_code is not null then
         if l_pumps.exists(:new.pump_out_location_code) and :new.pump_out_location_code != nvl(:old.pump_out_location_code, 0) then
            cwms_err.raise('ERROR', 'Pump out location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_out_location_code)) := true;
         end if;
      end if;
      -----------------------------
      -- pump_out_below_location --
      -----------------------------
      if :new.pump_out_below_location_code is not null then
         if l_pumps.exists(:new.pump_out_below_location_code) and :new.pump_out_below_location_code != nvl(:old.pump_out_below_location_code, 0)  then
            cwms_err.raise('ERROR', 'Pump out below location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_out_below_location_code)) := true;
         end if;
      end if;
      ----------------------
      -- pump_in_location --
      ----------------------
      if :new.pump_in_location_code is not null then
         if l_pumps.exists(:new.pump_in_location_code) and :new.pump_in_location_code != nvl(:old.pump_in_location_code, 0) then
            cwms_err.raise('ERROR', 'Pump in location is already used in another water supply contract');
         else
            l_pumps(to_char(:new.pump_in_location_code)) := true;
         end if;
      end if;
   end before each row;

end at_water_user_contract_t01;
/

--------
--------

CREATE TABLE at_wat_usr_contract_accounting
(
  wat_usr_contract_acct_code  NUMBER(14)      NOT NULL,
  water_user_contract_code  NUMBER(14)      NOT NULL,
  pump_location_code NUMBER(14) NOT NULL,
  phys_trans_type_code  NUMBER(14)      NOT NULL,
  -- accounting_credit_debit    VARCHAR2(6 BYTE)  NOT NULL,
  pump_flow       BINARY_DOUBLE     NOT NULL,
  transfer_start_datetime   DATE        NOT NULL,
  -- transfer_end_datetime      DATE        NOT NULL,
  accounting_remarks      VARCHAR2(255 BYTE)
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
COMMENT ON COLUMN at_wat_usr_contract_accounting.wat_usr_contract_acct_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.water_user_contract_code IS 'The contract identification number for this water movement. SEE AT_WATER_USER_CONTRACT.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.pump_location_code IS 'The AT_PHYSICAL_LOCATION location_code of the pump as referred to in the contract (pump out, pump out below, pump in) used for this water movement.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.phys_trans_type_code IS 'The type of transfer for this water movement.  See AT_phys_trans_type_CODE.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.transfer_start_datetime IS 'The date this water movement began, the end date is defined as the start date of the next accounting.';
-- COMMENT ON COLUMN at_wat_usr_contract_accounting.transfer_end_datetime IS 'the date this water movement ended';
-- COMMENT ON COLUMN at_wat_usr_contract_accounting.accounting_credit_debit IS 'Whether this water movement is a credit or a debit to the contract';
COMMENT ON COLUMN at_wat_usr_contract_accounting.pump_flow IS 'The flow associated with the water accounting record, this value will always be positive.';
COMMENT ON COLUMN at_wat_usr_contract_accounting.accounting_remarks IS 'Any comments regarding this water accounting movement';

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accounting_pk
 PRIMARY KEY
 (wat_usr_contract_acct_code)
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

CREATE UNIQUE INDEX at_wat_usr_contr_account_idx1 ON at_wat_usr_contract_accounting
(water_user_contract_code,pump_location_code,transfer_start_datetime)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accting_fk1
 FOREIGN KEY (water_user_contract_code)
 REFERENCES at_water_user_contract (water_user_contract_code))
/

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accting_fk2
 FOREIGN KEY (phys_trans_type_code)
 REFERENCES at_physical_transfer_type (phys_trans_type_code))
/

--ALTER TABLE at_wat_usr_contract_accounting ADD (
--CONSTRAINT acct_credit_or_debit_check
--CHECK ( upper(ACCOUNTING_CREDIT_DEBIT) = 'CREDIT' OR upper(ACCOUNTING_CREDIT_DEBIT) = 'DEBIT'))
--/

ALTER TABLE at_wat_usr_contract_accounting ADD (
  CONSTRAINT at_wat_usr_contr_accting_fk3
 FOREIGN KEY (pump_location_code)
 REFERENCES at_pump (pump_location_code))
/

--------
--------

CREATE TABLE at_xref_wat_usr_contract_docs
(
  water_user_contract_doc_code  NUMBER(14)      NOT NULL,
  document_code                 NUMBER(14)      NOT NULL,
  water_user_contract_code  NUMBER(14)      NOT NULL
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

COMMENT ON COLUMN at_xref_wat_usr_contract_docs.water_user_contract_doc_code IS 'The surrogate unique key for this record.';
COMMENT ON COLUMN at_xref_wat_usr_contract_docs.document_code IS 'The document code for the water supply contract.  More than one document is allowed for each record in the table AT_WATER_USER_CONTRACT. Examples of a need for multiple documents are the original contract, a modification to exercise an option, a contract extension, etc. See AT_DOCUMENT.';
COMMENT ON COLUMN at_xref_wat_usr_contract_docs.water_user_contract_code IS 'The water user contract record for which one or more documents are cross-referenced.  See AT_WATER_USER_CONTRACT.';

ALTER TABLE at_xref_wat_usr_contract_docs ADD (
  CONSTRAINT AT_XREF_WU_CONTRACT_DOCS_pk
 PRIMARY KEY
 (water_user_contract_doc_code)
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

CREATE UNIQUE INDEX at_xref_wat_usr_cont_docs_idx1 ON at_xref_wat_usr_contract_docs
(document_code,water_user_contract_code)
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_xref_wat_usr_contract_docs ADD (
  CONSTRAINT at_xref_wat_usr_cont_docs_fk1
 FOREIGN KEY (document_code)
 REFERENCES at_document (document_code))
/

ALTER TABLE at_xref_wat_usr_contract_docs ADD (
  CONSTRAINT at_xref_wat_usr_cont_docs_fk2
 FOREIGN KEY (water_user_contract_code)
 REFERENCES at_water_user_contract(water_user_contract_code))
/

--------
--------

CREATE TABLE at_project_purpose
(
  project_location_code           NUMBER(14)    NOT NULL,
  project_purpose_code      NUMBER(14)    NOT NULL,
  purpose_type        VARCHAR2(20 BYTE) NOT NULL,
  additional_notes      VARCHAR2(255 BYTE)
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

COMMENT ON COLUMN at_project_purpose.project_location_code IS 'The unique project this purpose relates to.  This key found in AT_PROJECT';
COMMENT ON COLUMN at_project_purpose.project_purpose_code IS 'The purpose of the project from the at_proj_purpose_code';
COMMENT ON COLUMN at_project_purpose.purpose_type IS 'The type for this purpose of the project.  Either operating or authorized.';
COMMENT ON COLUMN at_project_purpose.additional_notes IS 'Any additional notes pertinent to this projects purpose';

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_pk
 PRIMARY KEY
 (project_location_code,project_purpose_code)
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

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_project_purpose ADD (
  CONSTRAINT at_project_purpose_fk2
 FOREIGN KEY (project_purpose_code)
 REFERENCES at_project_purposes(purpose_code))
/

ALTER TABLE at_project_purpose ADD (
CONSTRAINT at_purpose_auth_or_oper_ck
CHECK ( upper(PURPOSE_TYPE) = 'OPERATING' OR upper(PURPOSE_TYPE) = 'AUTHORIZED'))
/

--------
--------

CREATE TABLE at_project_agreement
(
  project_agreement_loc_code          NUMBER(14)      NOT NULL,
  external_agency_or_stakeholder        VARCHAR2(64 BYTE)         NOT NULL,
  project_agreement_doc_code          NUMBER(14)
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
COMMENT ON COLUMN at_project_agreement.project_agreement_loc_code IS 'The project that this agreement pertains to';
COMMENT ON COLUMN at_project_agreement.external_agency_or_stakeholder IS 'The external government agency or external stakeholder that has a written agreement with the Corps of Engineers related to this project';
COMMENT ON COLUMN at_project_agreement.project_agreement_doc_code IS 'The surrogate code that forms a cross reference to the record in table at_document which contains the project agreement document';

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_pk
 PRIMARY KEY
 (project_agreement_loc_code,external_agency_or_stakeholder)
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

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_fk1
 FOREIGN KEY (project_agreement_loc_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_project_agreement ADD (
  CONSTRAINT at_project_agreement_fk2
 FOREIGN KEY (project_agreement_doc_code)
 REFERENCES at_document (document_code))
/

--------
--------

CREATE TABLE at_construction_history
(
  construction_history_code     NUMBER(14)      NOT NULL,
  project_location_code                         NUMBER(14)                      NOT NULL,
  construction_location_code            NUMBER(14)      NOT NULL,
  construction_id                   VARCHAR2(64 BYTE)         NOT NULL,
  construction_start_date           DATE        NOT NULL,
  construction_end_date             DATE        NOT NULL,
  land_acq_start_date         DATE,
  land_acq_end_date             DATE,
  area_infee_total        BINARY_DOUBLE,
  area_easement_total       BINARY_DOUBLE,
  impoundment_date        DATE,
  filling_date          DATE,
  impoundment_mod_date        DATE,
  pool_raise_date       DATE,
  operational_status_code     NUMBER(14)                      NOT NULL,
  construction_history_doc_code           NUMBER(14)
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
COMMENT ON COLUMN at_construction_history.construction_history_code IS 'The unique surrogate record number (code) for this construction history record';
COMMENT ON COLUMN at_construction_history.project_location_code IS 'The location code for the project where this construction is located at or associated with';
COMMENT ON COLUMN at_construction_history.construction_location_code IS 'The project this construction history record pertains to';
COMMENT ON COLUMN at_construction_history.construction_id IS 'The construction identification number or short name or title';
COMMENT ON COLUMN at_construction_history.construction_start_date IS 'The start date for the construction project';
COMMENT ON COLUMN at_construction_history.construction_end_date IS 'The completion date for the construction project';
COMMENT ON COLUMN at_construction_history.land_acq_start_date IS 'The date the land acquisition started';
COMMENT ON COLUMN at_construction_history.land_acq_end_date IS 'The date the land acquisition was completed';
COMMENT ON COLUMN at_construction_history.area_infee_total IS 'The total area (usually presented in units of acres) in-fee for the land acquired';
COMMENT ON COLUMN at_construction_history.area_easement_total IS 'The land area (usually presented in units of acres) under easement for this construction project';
COMMENT ON COLUMN at_construction_history.impoundment_date IS 'The date in which impoundment began.  Sometimes called the date of closure.';
COMMENT ON COLUMN at_construction_history.filling_date IS 'The date that the reservoir first reached the normal pool elevation';
COMMENT ON COLUMN at_construction_history.impoundment_mod_date IS 'The date in which impoundment began for the modified normal elevation.';
COMMENT ON COLUMN at_construction_history.pool_raise_date IS 'The date the pool elevation was raised';
COMMENT ON COLUMN at_construction_history.operational_status_code IS 'The operational status of the construction project. Constrained to a value in the lookup table AT_OPERATIONAL_STATUS_CODE';
COMMENT ON COLUMN at_construction_history.construction_history_doc_code IS 'The surrogate code of a record in AT_DOCUMENT that describes this phase of the construction history';

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_pk
 PRIMARY KEY
 (construction_history_code)
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

CREATE UNIQUE INDEX at_construction_hist_idx_1 ON at_construction_history
(project_location_code,construction_location_code,upper(construction_id))
LOGGING
tablespace cwms_20at_data
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

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk1
 FOREIGN KEY (project_location_code)
 REFERENCES at_project (project_location_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk2
 FOREIGN KEY (construction_location_code)
 REFERENCES at_physical_location (location_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk3
 FOREIGN KEY (construction_history_doc_code)
 REFERENCES at_document (document_code))
/

ALTER TABLE at_construction_history ADD (
  CONSTRAINT at_construction_history_fk4
 FOREIGN KEY (operational_status_code)
 REFERENCES at_operational_status_code (operational_status_code))
/

create table at_project_lock (
   lock_id         varchar2(64) primary key,
   project_code    number(14),
   application_id  varchar2(64),
   acquire_time    timestamp,
   session_user    varchar2(30),
   os_user         varchar2(30),
   session_program varchar2(64),
   session_machine varchar2(64),
   constraint at_project_lock_ck1 check (application_id = lower(application_id)),
   constraint at_project_lock_u1  unique (project_code, application_id) using index,
   constraint at_project_lock_fk1 foreign key (project_code) references at_project (project_location_code)
)
tablespace cwms_20at_data
/

comment on table at_project_lock is 'Contains information on projects locked for various applications';
comment on column at_project_lock.lock_id         is 'Unique lock identifier';
comment on column at_project_lock.project_code    is 'References project that is locked for application';
comment on column at_project_lock.application_id  is 'Specifies the application the project is locked for';
comment on column at_project_lock.acquire_time    is 'The UTC time the project lock was acquired';
comment on column at_project_lock.session_user    is 'The session user that acquired the lock';
comment on column at_project_lock.os_user         is 'The session user''s operating system user name';
comment on column at_project_lock.session_program is 'The program that acquired the lock';
comment on column at_project_lock.session_machine is 'The computer that acquired the lock';

create table at_prj_lck_revoker_rights (
   user_id         varchar2(30),
   office_code     number(14),
   application_id  varchar2(64),
   allow_flag      varchar2(1),
   project_list    varchar2(256),
   constraint at_prj_lck_revoker_rights_pk  primary key (user_id, office_code, application_id, allow_flag),
   constraint at_prj_lck_revoker_rights_ck1 check (user_id = lower(user_id)),
   constraint at_prj_lck_revoker_rights_ck2 check (application_id = lower(application_id)),
   constraint at_prj_lck_revoker_rights_ck3 check (allow_flag in ('T','F'))
)
tablespace cwms_20at_data
/

comment on table at_prj_lck_revoker_rights is 'Contains information about who can revoke project locks';
comment on column at_prj_lck_revoker_rights.user_id        is 'The user whose rights are described';
comment on column at_prj_lck_revoker_rights.office_code    is 'The office the user rights are described for';
comment on column at_prj_lck_revoker_rights.application_id is 'The application the user rights are described for';
comment on column at_prj_lck_revoker_rights.allow_flag     is 'Specifies whether this list is the ALLOW or DISALLOW list';
comment on column at_prj_lck_revoker_rights.project_list   is 'Comma-separated list of project identiers and/or project identifer masks';

