/* Formatted on 2007/11/14 12:53 (Formatter Plus v4.8.8) */
/* CWMS Version 2.0 --
This script should be run by the cwms schema owner.
*/
SET serveroutput on
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------

DECLARE
   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   table_names       id_array_t
      := id_array_t ('at_ts_table_properties',
                     'at_base_location',
                     'at_physical_location',
                     'at_loc_category',
                     'at_loc_group',
                     'at_loc_group_assignment',
                     'at_data_stream_id',
                     'at_alarm_id',
                     'at_alarm_criteria',
                     'at_screening_id',
                     'at_screening_control',
                     'at_screening_criteria',
                     'at_screening_dur_mag',
                     'at_cwms_ts_spec',
                     'at_shef_decode',
                     'at_screening',
                     'at_alarm',
                     'at_comp_vt',
                     'at_transform_criteria',
                     'at_unit_alias',
                     'at_user_preferences',
                     'at_office_settings',
                     'at_properties',
                     'at_dss_file',
                     'at_dss_ts_spec',
                     'at_dss_ts_xchg_spec',
                     'at_dss_xchg_set',
                     'at_dss_ts_xchg_map',
                     'at_ts_msg_archive_1',
                     'at_ts_msg_archive_2',
                     'at_mview_refresh_paused',
                     'at_report_templates',
                     'at_clob'
                    );
   mview_log_names   id_array_t
      := id_array_t ('at_base_location',
                     'at_physical_location',
                     'at_cwms_ts_spec',
                     'cwms_office',
                     'cwms_abstract_parameter',
                     'cwms_parameter_type',
                     'cwms_base_parameter',
                     'at_parameter',
                     'cwms_interval',
                     'cwms_duration',
                     'cwms_unit'
                    );
BEGIN
   FOR i IN table_names.FIRST .. table_names.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE    'drop table '
                           || table_names (i)
                           || ' cascade constraints';

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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-------------------------
-- AT_TS_TABLE_PROPERTIES table
-- 

CREATE TABLE at_ts_table_properties
(
  start_date  DATE                              NOT NULL,
  end_date    DATE                              NOT NULL,
  table_name  VARCHAR2(30 BYTE)                 NOT NULL,
  CONSTRAINT at_ts_table_properties_pk
 PRIMARY KEY
 (start_date)
)
ORGANIZATION INDEX
LOGGING
TABLESPACE cwms_20at_data
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
MONITORING;

INSERT INTO at_ts_table_properties
     VALUES (DATE '1800-01-01', DATE '2002-01-01', 'AT_TSV_ARCHIVAL');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2002-01-01', DATE '2003-01-01', 'AT_TSV_2002');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2003-01-01', DATE '2004-01-01', 'AT_TSV_2003');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2004-01-01', DATE '2005-01-01', 'AT_TSV_2004');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2005-01-01', DATE '2006-01-01', 'AT_TSV_2005');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2006-01-01', DATE '2007-01-01', 'AT_TSV_2006');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2007-01-01', DATE '2008-01-01', 'AT_TSV_2007');
INSERT INTO at_ts_table_properties
     VALUES (DATE '2008-01-01', DATE '2100-01-01', 'AT_TSV_2008');
COMMIT ;

---------------------------------
-- AT_BASE_LOCATION table.
-- 
CREATE TABLE at_base_location
(
  base_location_code  NUMBER,
  db_office_code      NUMBER                    NOT NULL,
  base_location_id    VARCHAR2(16 BYTE)         NOT NULL,
  active_flag         VARCHAR2(1 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING;

COMMENT ON COLUMN at_base_location.db_office_code IS 'Refererences the office "owning" this location.  In the CWMS v2 schema, the office hosting the database "owns" all locations.';
COMMENT ON COLUMN at_base_location.base_location_id IS 'Text name of this Base Location';
COMMENT ON COLUMN at_base_location.active_flag IS 'T or F';


CREATE UNIQUE INDEX at_base_location_pk ON at_base_location
(base_location_code)
LOGGING
TABLESPACE cwms_20data
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
NOPARALLEL;


CREATE UNIQUE INDEX at_base_location_idx1 ON at_base_location
(db_office_code, UPPER("BASE_LOCATION_ID"))
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_base_location ADD (
   CONSTRAINT at_base_location_ck_1
   CHECK (TRIM("BASE_LOCATION_ID")="BASE_LOCATION_ID"))
/
--ALTER TABLE AT_BASE_LOCATION ADD (
--  CONSTRAINT AT_BASE_LOCATION_CK_2
-- CHECK (NVL("ACTIVE_FLAG",'T')='T'))
--/

ALTER TABLE at_base_location ADD (
  CONSTRAINT at_base_location_pk
 PRIMARY KEY
 (base_location_code)
    USING INDEX
    TABLESPACE cwms_20data
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

ALTER TABLE at_base_location ADD (
  CONSTRAINT at_base_location_fk1
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
INSERT INTO at_base_location
            (base_location_code, db_office_code, base_location_id, active_flag
            )
     VALUES (0, (SELECT office_code
                   FROM cwms_office
                  WHERE office_id = 'CWMS'), 'Deleted TS ID', 'F'
            )
/
COMMIT
/
--------------------
-- AT_PHYSICAL_LOCATION table
-- 


CREATE TABLE at_physical_location
(
  location_code       NUMBER(10)                NOT NULL,
  base_location_code  NUMBER(10)                NOT NULL,
  sub_location_id     VARCHAR2(32 BYTE),
  time_zone_code      NUMBER(10),
  county_code         NUMBER(10),
  location_type       VARCHAR2(32 BYTE),
  elevation           NUMBER,
  vertical_datum      VARCHAR2(16 BYTE),
  longitude           NUMBER,
  latitude            NUMBER,
  horizontal_datum    VARCHAR2(16 BYTE),
  public_name         VARCHAR2(32 BYTE),
  long_name           VARCHAR2(80 BYTE),
  description         VARCHAR2(512 BYTE),
  active_flag         VARCHAR2(1 BYTE)
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
COMMENT ON TABLE at_physical_location IS 'Defines unique locations'
/
COMMENT ON COLUMN at_physical_location.location_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.'
/
COMMENT ON COLUMN at_physical_location.time_zone_code IS 'References the time zone associated with the geographic location.  Not necessarily the time zone of any data collected.'
/
COMMENT ON COLUMN at_physical_location.county_code IS 'References the county'
/
COMMENT ON COLUMN at_physical_location.location_type IS 'User-defined type (e.g. "Stream Gage", "Reservoir", etc...), up to 16 characters.'
/
COMMENT ON COLUMN at_physical_location.elevation IS 'Ground elevation at location.'
/
COMMENT ON COLUMN at_physical_location.vertical_datum IS 'Datum of elevation.'
/
COMMENT ON COLUMN at_physical_location.longitude IS 'Longitude of location.'
/
COMMENT ON COLUMN at_physical_location.latitude IS 'Latitude of location.'
/
COMMENT ON COLUMN at_physical_location.public_name IS 'User-defined public name, up to 32 characters.'
/
COMMENT ON COLUMN at_physical_location.long_name IS 'User-defined long name, up to 80 characters.'
/
COMMENT ON COLUMN at_physical_location.description IS 'User-defined description, up to 512 characters.'
/
COMMENT ON COLUMN at_physical_location.active_flag IS 'T or F'
/

CREATE UNIQUE INDEX at_physical_location_pk ON at_physical_location
(location_code)
LOGGING
TABLESPACE cwms_20data
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

CREATE UNIQUE INDEX at_physical_location_ui1 ON at_physical_location
(base_location_code, UPPER("SUB_LOCATION_ID"))
LOGGING
TABLESPACE cwms_20at_data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          104 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

ALTER TABLE at_physical_location ADD (
  CONSTRAINT at_physical_location_ck_2
 CHECK (active_flag ='T' OR active_flag = 'F'))
/
ALTER TABLE at_physical_location ADD (
  CONSTRAINT at_physical_location_ck_3
 CHECK (TRIM("SUB_LOCATION_ID")="SUB_LOCATION_ID"))
/
ALTER TABLE at_physical_location ADD (
  CONSTRAINT at_physical_location_pk
 PRIMARY KEY
 (location_code)
    USING INDEX
    TABLESPACE cwms_20data
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

ALTER TABLE at_physical_location ADD (
  CONSTRAINT at_physical_location_fk_1
 FOREIGN KEY (base_location_code)
 REFERENCES at_base_location (base_location_code))
/
ALTER TABLE at_physical_location ADD (
  CONSTRAINT at_physical_location_fk_2
 FOREIGN KEY (county_code)
 REFERENCES cwms_county (county_code))
/
ALTER TABLE at_physical_location ADD (
  CONSTRAINT at_physical_location_fk_3
 FOREIGN KEY (time_zone_code)
 REFERENCES cwms_time_zone (time_zone_code))
/
INSERT INTO at_physical_location
            (location_code, base_location_code, active_flag
            )
     VALUES (0, 0, 'F'
            )
/
COMMIT
/
---------------
------------------

CREATE TABLE at_loc_category
(
  loc_category_code  NUMBER,
  loc_category_id    VARCHAR2(32 BYTE)          NOT NULL,
  db_office_code     NUMBER                     NOT NULL,
  loc_category_desc  VARCHAR2(128 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_loc_category_name_pk ON at_loc_category
(loc_category_code)
LOGGING
TABLESPACE cwms_20at_data
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

CREATE UNIQUE INDEX at_loc_category_name_u1 ON at_loc_category
(UPPER("LOC_CATEGORY_ID"), db_office_code)
LOGGING
TABLESPACE cwms_20at_data
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

ALTER TABLE at_loc_category ADD (
  CONSTRAINT at_loc_category_name_pk
 PRIMARY KEY
 (loc_category_code)
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
SET DEFINE OFF;

INSERT 
  INTO at_loc_category 
VALUES (/* loc_category_code */ 0,
        /* loc_category_id   */ 'Default',
        /* db_office_code    */ 53,
        /* loc_category_desc */ 'Default');

INSERT 
  INTO at_loc_category 
VALUES (/* loc_category_code */ 1,                                      
        /* loc_category_id   */ 'Agency Aliases',                       
        /* db_office_code    */ 53,                                     
        /* loc_category_desc */ 'Location aliases for other agencies'); 

--------
--------

CREATE TABLE at_loc_group
(
  loc_group_code     NUMBER,
  loc_category_code  NUMBER                     NOT NULL,
  loc_group_id       VARCHAR2(32 BYTE)          NOT NULL,
  loc_group_desc     VARCHAR2(128 BYTE),
  db_office_code     NUMBER                     NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_loc_groups_pk ON at_loc_group
(loc_group_code)
LOGGING
TABLESPACE cwms_20at_data
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

CREATE UNIQUE INDEX at_loc_groups_u1 ON at_loc_group
(loc_category_code, UPPER("LOC_GROUP_ID"))
LOGGING
TABLESPACE cwms_20at_data
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

ALTER TABLE at_loc_group ADD (
  CONSTRAINT at_loc_groups_pk
 PRIMARY KEY
 (loc_group_code)
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

ALTER TABLE at_loc_group ADD (
  CONSTRAINT at_loc_groups_fk2
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
ALTER TABLE at_loc_group ADD (
  CONSTRAINT at_loc_groups_fk1
 FOREIGN KEY (loc_category_code)
 REFERENCES at_loc_category (loc_category_code))
/
SET DEFINE OFF;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 0, 
        /* loc_category_code */ 0, 
        /* loc_group_id      */ 'Default', 
        /* loc_group_desc    */ 'All Locations',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 1, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'USGS Station Name', 
        /* loc_group_desc    */ 'US Geological Survey Station Name',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 2, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'USGS Station Number', 
        /* loc_group_desc    */ 'US Geological Survey Station Number',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 3, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'NWS Handbook 5 ID', 
        /* loc_group_desc    */ 'National Weather Service Handbook 5 ID',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 4, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'DCP Platform ID', 
        /* loc_group_desc    */ 'Data Collection Platform ID',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 5, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'SHEF Location ID', 
        /* loc_group_desc    */ 'Standard Hydrometeorological Exchange Format Location ID',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 6, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'CBT Station ID', 
        /* loc_group_desc    */ 'Columbia Basin Teletype Station ID',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 7, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'USBR Station ID', 
        /* loc_group_desc    */ 'US Bureau of Reclamation Station ID',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 8, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'TVA Station ID', 
        /* loc_group_desc    */ 'Tennessee Valley Authority Station ID',
        /* db_office_code    */ 53);
COMMIT ;

INSERT 
  INTO at_loc_group
VALUES (/* loc_group_code    */ 9, 
        /* loc_category_code */ 1, 
        /* loc_group_id      */ 'NRCS Station ID', 
        /* loc_group_desc    */ 'Natural Resources Conservation Service Station ID',
        /* db_office_code    */ 53);
COMMIT ;



-----
-----

CREATE TABLE at_loc_group_assignment
(
  location_code   NUMBER,
  loc_group_code  NUMBER,
  loc_alias_id    VARCHAR2(128 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_loc_group_assignment_pk ON at_loc_group_assignment
(location_code, loc_group_code)
LOGGING
TABLESPACE cwms_20at_data
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

ALTER TABLE at_loc_group_assignment ADD (
  CONSTRAINT at_loc_group_assignment_pk
 PRIMARY KEY
 (location_code, loc_group_code)
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

ALTER TABLE at_loc_group_assignment ADD (
  CONSTRAINT at_loc_group_assignment_fk1
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/
ALTER TABLE at_loc_group_assignment ADD (
  CONSTRAINT at_loc_group_assignment_fk2
 FOREIGN KEY (loc_group_code)
 REFERENCES at_loc_group (loc_group_code))
/
SET DEFINE OFF;

INSERT INTO at_loc_group_assignment
            (location_code, loc_group_code, loc_alias_id
            )
     VALUES (0, 0, NULL
            );
COMMIT ;
----------
----------
-----------
-----------------
----------------------
--------------------------



---------------------------------
-- AT_CWMS_TS_SPEC table.
-- 

CREATE TABLE at_cwms_ts_spec
(
  ts_code              NUMBER                   NOT NULL,
  location_code        NUMBER                   NOT NULL,
  parameter_code       NUMBER                   NOT NULL,
  parameter_type_code  NUMBER(10)               NOT NULL,
  interval_code        NUMBER(10)               NOT NULL,
  duration_code        NUMBER(10)               NOT NULL,
  VERSION              VARCHAR2(32 BYTE)        NOT NULL,
  description          VARCHAR2(80 BYTE),
  interval_utc_offset  NUMBER                   NOT NULL,
  interval_forward     NUMBER,
  interval_backward    NUMBER,
  interval_offset_id   VARCHAR2(16 BYTE),
  time_zone_code       NUMBER(10),
  version_flag         VARCHAR2(1 BYTE),
  migrate_ver_flag     VARCHAR2(1 BYTE),
  active_flag          VARCHAR2(1 BYTE),
  delete_date          DATE,
  data_source          VARCHAR2(16 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          5 m
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
COMMENT ON TABLE at_cwms_ts_spec IS 'Defines time series based on CWMS requirements.  This table also serves as time series specification super type.'
/
COMMENT ON COLUMN at_cwms_ts_spec.description IS 'Additional information.'
/
COMMENT ON COLUMN at_cwms_ts_spec.version_flag IS 'Default is NULL, indicating versioning is off. If set to "Y" then versioning is on'
/
COMMENT ON COLUMN at_cwms_ts_spec.migrate_ver_flag IS 'Default is NULL, indicating versioned data is not migrated to historic tables.  If set to "Y", versioned data is archived.'
/
COMMENT ON COLUMN at_cwms_ts_spec.active_flag IS 'T or F'
/
COMMENT ON COLUMN at_cwms_ts_spec.delete_date IS 'Is the date that this ts_id was marked for deletion.'
/
COMMENT ON COLUMN at_cwms_ts_spec.ts_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.'
/
COMMENT ON COLUMN at_cwms_ts_spec.location_code IS 'Primary key of AT_PHYSICAL_LOCATION table.'
/
COMMENT ON COLUMN at_cwms_ts_spec.parameter_code IS 'Primary key of AT_PARAMETER table.  Must already exist in the AT_PARAMETER table.'
/
COMMENT ON COLUMN at_cwms_ts_spec.parameter_type_code IS 'Primary key of CWMS_PARAMETER_TYPE table.  Must already exist in the CWMS_PARAMETER_TYPE table.'
/

CREATE UNIQUE INDEX at_cwms_ts_spec_ui ON at_cwms_ts_spec
(location_code, parameter_type_code, parameter_code, interval_code,
duration_code, UPPER("VERSION"), delete_date)
LOGGING
TABLESPACE cwms_20at_data
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          24 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX at_cwms_ts_spec_pk ON at_cwms_ts_spec
(ts_code)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_ck_3
 CHECK (TRIM(VERSION)=VERSION))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_ck_4
 CHECK (NVL(version_flag,'T')='T'))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_ck_5
 CHECK (active_flag ='T' OR active_flag = 'F'))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_pk
 PRIMARY KEY
 (ts_code)
    USING INDEX
    TABLESPACE cwms_20data
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

ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_1
 FOREIGN KEY (parameter_type_code)
 REFERENCES cwms_parameter_type (parameter_type_code))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_2
 FOREIGN KEY (parameter_code)
 REFERENCES at_parameter (parameter_code))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_3
 FOREIGN KEY (interval_code)
 REFERENCES cwms_interval (interval_code))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_4
 FOREIGN KEY (duration_code)
 REFERENCES cwms_duration (duration_code))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_5
 FOREIGN KEY (location_code)
 REFERENCES at_physical_location (location_code))
/
ALTER TABLE at_cwms_ts_spec ADD (
  CONSTRAINT at_cwms_ts_spec_fk_6
 FOREIGN KEY (time_zone_code)
 REFERENCES cwms_time_zone (time_zone_code))
/


---------------------------------
-- AT_SCREENING table.
-- 
CREATE TABLE at_screening
(
  ts_code            NUMBER,
  screening_code     NUMBER                     NOT NULL,
  active_flag        VARCHAR2(1 BYTE),
  resultant_ts_code  NUMBER
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
COMMENT ON COLUMN at_screening.active_flag IS 'T of F'
/

CREATE UNIQUE INDEX at_screening_pk ON at_screening
(ts_code)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_screening ADD (
  CONSTRAINT at_screening_pk
 PRIMARY KEY
 (ts_code)
    USING INDEX
    TABLESPACE cwms_20data
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

ALTER TABLE at_screening ADD (
  CONSTRAINT at_screening_fk02
 FOREIGN KEY (resultant_ts_code)
 REFERENCES at_cwms_ts_spec (ts_code))
/


---------------------------------
-- AT_ALARM table.
-- 
CREATE TABLE at_alarm
(
  ts_code      NUMBER,
  ts_ni_hash   VARCHAR2(80 BYTE)                NOT NULL,
  alarm_code   NUMBER                           NOT NULL,
  active_flag  VARCHAR2(1 BYTE)
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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
COMMENT ON COLUMN at_alarm.active_flag IS 'T or F'
/

CREATE UNIQUE INDEX at_alarm_pk ON at_alarm
(ts_code)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_alarm ADD (
  CONSTRAINT at_alarm_pk
 PRIMARY KEY
 (ts_code)
    USING INDEX
    TABLESPACE cwms_20data
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


---------------------------------
-- AT_COMP_VT table.
-- 

CREATE TABLE at_comp_vt
(
  comp_vt_code           NUMBER,
  comp_vt_id             VARCHAR2(16 BYTE),
  db_office_code         NUMBER,
  filename_datchk1       VARCHAR2(32 BYTE),
  filename_datchk2       VARCHAR2(32 BYTE),
  filename_trn_in        VARCHAR2(32 BYTE),
  default_time_window    VARCHAR2(32 BYTE),
  context_start_date     VARCHAR2(32 BYTE),
  exchange_set_extract   VARCHAR2(32 BYTE),
  exchange_set_post_raw  VARCHAR2(32 BYTE),
  exchange_set_post_rev  VARCHAR2(32 BYTE)
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_comp_vt_pk ON at_comp_vt
(comp_vt_code)
LOGGING
TABLESPACE cwms_20data
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

CREATE UNIQUE INDEX at_comp_vt_u01 ON at_comp_vt
(comp_vt_id, db_office_code)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_comp_vt ADD (
  CONSTRAINT at_comp_vt_pk
 PRIMARY KEY
 (comp_vt_code)
    USING INDEX
    TABLESPACE cwms_20data
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
ALTER TABLE at_comp_vt ADD (
  CONSTRAINT at_comp_vt_u01
 UNIQUE (comp_vt_id, db_office_code)
    USING INDEX
    TABLESPACE cwms_20data
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

ALTER TABLE at_comp_vt ADD (
  CONSTRAINT at_comp_vt_r01
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
---------------------------------
-- AT_TRANSFORM_CRITERIA table.
-- 

CREATE TABLE at_transform_criteria
(
  ts_code                       NUMBER,
  dssmath_macro_call            VARCHAR2(128 BYTE),
  dssmath_post_raw              VARCHAR2(1 BYTE),
  comp_vt_code                  NUMBER,
  call_seq_table_lookup         NUMBER,
  call_seq_scaling              NUMBER,
  scaling_factor                NUMBER,
  scaling_offset                NUMBER,
  call_seq_mass_curve_to_inc    NUMBER,
  call_seq_inc_to_mass_curve    NUMBER,
  call_seq_interval_conversion  NUMBER,
  resultant_ts_code             NUMBER
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_transform_criteria_pk ON at_transform_criteria
(ts_code)
LOGGING
TABLESPACE cwms_20data
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

CREATE UNIQUE INDEX at_transform_criteria_u02 ON at_transform_criteria
(resultant_ts_code)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_transform_criteria ADD (
  CONSTRAINT at_transform_criteria_pk
 PRIMARY KEY
 (ts_code)
    USING INDEX
    TABLESPACE cwms_20data
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
ALTER TABLE at_transform_criteria ADD (
  CONSTRAINT at_transform_criteria_u02
 UNIQUE (resultant_ts_code)
    USING INDEX
    TABLESPACE cwms_20data
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

ALTER TABLE at_transform_criteria ADD (
  CONSTRAINT at_transform_criteria_r02
 FOREIGN KEY (resultant_ts_code)
 REFERENCES at_cwms_ts_spec (ts_code))
/
ALTER TABLE at_transform_criteria ADD (
  CONSTRAINT at_transform_criteria_r01
 FOREIGN KEY (ts_code)
 REFERENCES at_cwms_ts_spec (ts_code))
/
ALTER TABLE at_transform_criteria ADD (
  CONSTRAINT at_transform_criteria_r03
 FOREIGN KEY (comp_vt_code)
 REFERENCES at_comp_vt (comp_vt_code))
/

-----------------------------
-- AT_UNIT_ALIAS TABLE.
--
CREATE TABLE at_unit_alias
(
  alias_id        VARCHAR2(32 BYTE)             NOT NULL,
  db_office_code  NUMBER                  NOT NULL,
  unit_code       NUMBER(10)                    NOT NULL
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          200 k
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING;
-----------------------------
-- AT_UNIT_ALIAS TABLE comments
--
COMMENT ON TABLE at_unit_alias IS 'Contains unitAlias names for all units';
COMMENT ON COLUMN at_unit_alias.alias_id IS 'Alias name and primary key';
COMMENT ON COLUMN at_unit_alias.unit_code IS 'Foreign key referencing CWMS_UNIT table by its primary key';

-----------------------------
-- AT_UNIT_ALIAS TABLE indices
--
CREATE UNIQUE INDEX at_unit_alias_pk ON at_unit_alias
(alias_id, db_office_code)
LOGGING
TABLESPACE cwms_20data
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
NOPARALLEL;
-----------------------------
-- AT_UNIT_ALIAS TABLE constraints
--
ALTER TABLE at_unit_alias ADD CONSTRAINT at_unit_alias_r02 FOREIGN KEY (db_office_code) REFERENCES cwms_office (office_code);
ALTER TABLE at_unit_alias ADD CONSTRAINT fk_at_unit_alias  FOREIGN KEY (unit_code) REFERENCES cwms_unit (unit_code);
ALTER TABLE at_unit_alias ADD CONSTRAINT at_unit_alias_pk  PRIMARY KEY (alias_id, db_office_code)
    USING INDEX
    TABLESPACE cwms_20data
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               );

-----------------------------
-- AT_USER_PREFERENCES TABLE.
--
CREATE TABLE at_user_preferences
(
  db_office_code           NUMBER,
  username                 VARCHAR2(31 BYTE),
  display_format_lat_long  VARCHAR2(3 BYTE),
  display_unit_system      VARCHAR2(2 BYTE)
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_user_preferences_pk ON at_user_preferences
(db_office_code, username)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_user_preferences ADD (
  CONSTRAINT at_user_preferences_pk
 PRIMARY KEY
 (db_office_code, username)
    USING INDEX
    TABLESPACE cwms_20data
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
-----------------------------
-- AT_OFFICE_SETTINGS TABLE.
--
CREATE TABLE at_office_settings
(
  db_office_code           NUMBER,
  screening_use_otf        VARCHAR2(1 BYTE),
  screening_use_datchk     VARCHAR2(1 BYTE),
  screening_use_cwms       VARCHAR2(1 BYTE),
  max_northern_lat         NUMBER,
  max_southern_lat         NUMBER,
  max_western_long         NUMBER,
  max_eastern_long         NUMBER,
  display_lat_long_format  VARCHAR2(3 BYTE),
  display_unit_system      VARCHAR2(2 BYTE)
)
TABLESPACE cwms_20data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64 k
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

CREATE UNIQUE INDEX at_office_settings_pk ON at_office_settings
(db_office_code)
LOGGING
TABLESPACE cwms_20data
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

ALTER TABLE at_office_settings ADD (
  CONSTRAINT at_office_settings_pk
 PRIMARY KEY
 (db_office_code)
    USING INDEX
    TABLESPACE cwms_20data
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

---------------------------------
-- AT_PROPERTIES table.
-- 
CREATE TABLE at_properties
    (
        office_code    NUMBER(10),
        prop_category  VARCHAR2(256) NOT NULL,
        prop_id        VARCHAR2(256) NOT NULL,
        prop_value     VARCHAR2(256),
        prop_comment   VARCHAR2(256)
    )
    LOGGING
    NOCOMPRESS
    NOCACHE
    NOPARALLEL
    NOMONITORING;

COMMENT ON TABLE at_properties IS 'Generic properties, such as for Java application.';
COMMENT ON COLUMN at_properties.office_code   IS 'References the office that "owns" this property.';
COMMENT ON COLUMN at_properties.prop_category IS 'Major category or component to which property applies.';
COMMENT ON COLUMN at_properties.prop_id       IS 'Property name.';
COMMENT ON COLUMN at_properties.prop_value    IS 'Property value.';
COMMENT ON COLUMN at_properties.prop_comment  IS 'Notes about property usage or value.';
---------------------------------
-- AT_PROPERTIES constraints.
-- 
ALTER TABLE at_properties ADD CONSTRAINT at_properties_fk FOREIGN KEY(office_code)REFERENCES cwms_office (office_code);
ALTER TABLE at_properties ADD CONSTRAINT at_properties_pk PRIMARY KEY(office_code, prop_category, prop_id);

---------------------------------
-- AT_PROPERTIES indices.
-- 
CREATE UNIQUE INDEX at_properties_uk1 ON at_properties(office_code, UPPER("PROP_CATEGORY"), UPPER("PROP_ID"));

---------------------------------
-- AT_PROPERTIES default data.
-- 
INSERT INTO at_properties values(
	(SELECT office_code FROM cwms_office WHERE office_id = 'CWMS'),
	'CWMSDB',
	'logging.table.max_entries',
	'100000',
	'Max number of rows to keep when trimming log.');
	
INSERT INTO at_properties values(
	(SELECT office_code FROM cwms_office WHERE office_id = 'CWMS'),
	'CWMSDB',
	'logging.entry.max_age',
	'120',
	'Max entry age in days to keep when trimming log.');
	
INSERT INTO at_properties values(
	(SELECT office_code FROM cwms_office WHERE office_id = 'CWMS'),
	'CWMSDB',
	'logging.auto_trim.interval',
	'240',
	'Interval in minutes for job TRIM_LOG_JOB to execute.');

-----------------------------
-- AT_REPORT_TEMPLATES table
--
CREATE TABLE at_report_templates
(
  ID               VARCHAR2(256 BYTE),
  description      VARCHAR2(256 BYTE),
  header_template  VARCHAR2(4000 BYTE),
  record_template  VARCHAR2(4000 BYTE),
  footer_template  VARCHAR2(4000 BYTE)
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE
(
  INITIAL          64 k
  MINEXTENTS       1
  MAXEXTENTS       2147483645
  PCTINCREASE      0
  BUFFER_POOL      DEFAULT
)
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING;

-----------------------------
-- AT_REPORT_TEMPLATES comments
--
COMMENT ON TABLE  at_report_templates                 IS 'Defines canned templates for use with CWMS_REPORT.TEXT_REPORT';
COMMENT ON COLUMN at_report_templates.ID              IS 'Unique record identifier, using hierarchical /dir/subdir/.../file syntax';
COMMENT ON COLUMN at_report_templates.description     IS 'Description of this set of templates';
COMMENT ON COLUMN at_report_templates.header_template IS 'A template string for the portion of the report before the records';
COMMENT ON COLUMN at_report_templates.record_template IS 'A template string applied to each record in the report';
COMMENT ON COLUMN at_report_templates.footer_template IS 'A template string for the portion of the report after the records';

-----------------------------
-- AT_REPORT_TEMPLATES indices
--
ALTER TABLE at_report_templates ADD
(
  PRIMARY KEY (ID)
  USING INDEX
  TABLESPACE cwms_20at_data
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  STORAGE
  (
    INITIAL          64 k
    MINEXTENTS       1
    MAXEXTENTS       2147483645
    PCTINCREASE      0
  )
);

-----------------------------
-- AT_REPORT_TEMPLATES default data
--
INSERT INTO at_report_templates
     VALUES ('/cat_ts_table/xml', 'Generates XML from cat_ts_table records',
             '<?xml version="1.0"?>\n<tsid_catalog>\n',
             '  <tsid office="$1" ts_code="$4" offset="$3">$2</tsid>\n',
             '</tsid_catalog>\n');

INSERT INTO at_report_templates
     VALUES ('/cat_ts_table/html', 'Generates HTML from cat_ts_table records',
             '<html>
<head>
  <title>Time Series IDs</title>
</head>
<body>
  <center>
    <h2>Time Series IDs</h2>
    <hr/>
    <table border="1">
      <tr>
        <th>Time Series Identifier</th>
        <th>TS Code</th>
        <th>UTC Interval Offset</th>
      </tr>
',
             '      <tr>
        <td>$2</td>
        <td>$4</td>
        <td>$3</td>
      </tr>
',
             '    </table>
  </center>
</body>
</html>
'           );

INSERT INTO at_report_templates
     VALUES ('/cat_ts_table/text', 'Generates text from cat_ts_table records',
             '\nTIME SERIES CATALOG\nREPORT GENERATED BY $host AT $time\n\n',
             '$1%-8.8s$4%-8d$3%12d$2\n', '\n$count TOTAL RECORDS PROCESSED\n');

COMMIT ;

-----------------------------
-- AT_CLOB table
--
CREATE TABLE at_clob
(
  ID           VARCHAR2(256 BYTE) NOT NULL,
  description  VARCHAR2(256 BYTE),
  VALUE        CLOB
)
TABLESPACE cwms_20at_data
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE
(
  INITIAL          64 k
  MINEXTENTS       1
  MAXEXTENTS       2147483645
  PCTINCREASE      0
  BUFFER_POOL      DEFAULT
)
LOGGING
NOCOMPRESS
LOB (VALUE) STORE AS
(
  TABLESPACE  cwms_20at_data
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  PCTVERSION  0
  NOCACHE
  STORAGE
  (
    INITIAL          64 k
    MINEXTENTS       1
    MAXEXTENTS       2147483645
    PCTINCREASE      0
    BUFFER_POOL      DEFAULT
  )
)
NOCACHE
NOPARALLEL
MONITORING;

-----------------------------
-- AT_CLOB comments
--
COMMENT ON TABLE  at_clob             IS 'Character Large OBject Storage for CWMS';
COMMENT ON COLUMN at_clob.ID          IS 'Unique record identifier, using hierarchical /dir/subdir/.../file syntax';
COMMENT ON COLUMN at_clob.description IS 'Description of this CLOB';
COMMENT ON COLUMN at_clob.VALUE       IS 'The CLOB data';

-----------------------------
-- AT_CLOB indices
--
ALTER TABLE at_clob ADD
(
  PRIMARY KEY (ID)
  USING INDEX
  TABLESPACE cwms_20at_data
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  STORAGE
  (
    INITIAL          64 k
    MINEXTENTS       1
    MAXEXTENTS       2147483645
    PCTINCREASE      0
  )
);

-----------------------------
-- AT_CLOB default data
--
INSERT INTO at_clob
     VALUES ('/xslt/identity',
             'Transforms the input to an identical copy of itself',
             '<!-- The Identity Transformation -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Whenevery you match any node or any attribute -->
  <xsl:template match="node()|@*">
    <!-- Copy the current node -->
    <xsl:copy>
      <!-- Including andy attributes it has and any child nodes -->
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
'           );

INSERT INTO at_clob
     VALUES ('/xslt/cat_ts_xml/tabbed_text',
             'Transforms cat_ts_xml output to tab-separated text',
             '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/tsid_catalog[1]">
    <xsl:text>Time Series IDs for Office "</xsl:text>
    <xsl:value-of select="/tsid_catalog[1]/@office"/>
    <xsl:text>" Matching "</xsl:text>
    <xsl:value-of select="/tsid_catalog[1]/@pattern"/>
    <xsl:text>"&#xA;&#xA;Time Series ID&#x9;TS CODE&#x9;UTC OFFSET"&#xA;</xsl:text>
    <xsl:for-each select="/tsid_catalog/tsid">
      <xsl:value-of select="."/>   
      <xsl:text>&#x9;</xsl:text>
      <xsl:value-of select="@ts_code"/>   
      <xsl:text>&#x9;</xsl:text>
      <xsl:value-of select="@offset"/>   
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
'           );

INSERT INTO at_clob
     VALUES ('/xslt/cat_ts_xml/html', 'Transforms cat_ts_xml output to html',
             '<html xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<head>
  <title>Time Series IDs for Office "<xsl:value-of select="/tsid_catalog[1]/@office"/>" 
         Matching "<xsl:value-of select="/tsid_catalog[1]/@pattern"/>"
  </title>
</head>
<body>
  <center>
    <h2>
      Time series IDs matching pattern 
	    "<xsl:value-of select="/tsid_catalog[1]/@pattern"/>" for Office 
	    "<xsl:value-of select="/tsid_catalog[1]/@office"/>".
    </h2>
    <hr/>
    <table border="1"> 
      <tr>
        <th>Time Series Identifier</th>
        <th>TS Code</th>
        <th>UTC Interval Offset</th>
      </tr>
      <xsl:for-each select="/tsid_catalog/tsid">
      <tr>
        <td><xsl:value-of select="."/></td>
        <td><xsl:value-of select="@ts_code"/></td>
        <td><xsl:value-of select="@offset"/></td>
      </tr>   
      </xsl:for-each>
    </table>
  </center>
</body>
</html>
'           );

COMMIT ;


SHOW ERRORS;
COMMIT ;
