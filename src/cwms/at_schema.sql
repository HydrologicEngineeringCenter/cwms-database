/* CWMS Version 2.0 --
This script should be run by the cwms schema owner.
*/
set serveroutput on 
----------------------------------------------------
-- drop tables, mviews & mview logs if they exist --
----------------------------------------------------
declare
   type id_array_t is table of varchar2(32);
   table_names id_array_t := id_array_t(
      'at_ts_table_properties',
      'at_base_location',
      'at_physical_location',
      'at_loc_category',
      'at_loc_group',
      'at_loc_group_assignment',
      'at_data_stream_id',
      'at_alarm_id',
      'at_alarm_criteria',
      'at_screening_id',
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
      'at_clob');
   mview_log_names id_array_t := id_array_t(
      'at_base_location',
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

begin                
   for i in table_names.first .. table_names.last loop
      begin 
         execute immediate 'drop table ' || table_names(i) || ' cascade constraints';
         dbms_output.put_line('Dropped table ' || table_names(i));
      exception 
         when others then null;
      end;
   end loop;
   for i in mview_log_names.first .. mview_log_names.last loop
      begin 
         execute immediate 'drop materialized view log on ' || mview_log_names(i);
         dbms_output.put_line('Dropped materialized view log on ' || mview_log_names(i));
      exception 
         when others then null;
      end;
   end loop;
end;
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

CREATE TABLE AT_TS_TABLE_PROPERTIES
(
  START_DATE  DATE                              NOT NULL,
  END_DATE    DATE                              NOT NULL,
  TABLE_NAME  VARCHAR2(30 BYTE)                 NOT NULL, 
  CONSTRAINT AT_TS_TABLE_PROPERTIES_PK
 PRIMARY KEY
 (START_DATE)
)
ORGANIZATION INDEX
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
MONITORING;

insert into at_ts_table_properties values (DATE '1800-01-01',DATE '2002-01-01','AT_TSV_ARCHIVAL');
insert into at_ts_table_properties values (DATE '2002-01-01',DATE '2003-01-01','AT_TSV_2002');
insert into at_ts_table_properties values (DATE '2003-01-01',DATE '2004-01-01','AT_TSV_2003');
insert into at_ts_table_properties values (DATE '2004-01-01',DATE '2005-01-01','AT_TSV_2004');
insert into at_ts_table_properties values (DATE '2005-01-01',DATE '2006-01-01','AT_TSV_2005');
insert into at_ts_table_properties values (DATE '2006-01-01',DATE '2007-01-01','AT_TSV_2006');
insert into at_ts_table_properties values (DATE '2007-01-01',DATE '2008-01-01','AT_TSV_2007');
commit;

---------------------------------
-- AT_BASE_LOCATION table.
-- 
CREATE TABLE AT_BASE_LOCATION
(
  BASE_LOCATION_CODE  NUMBER,
  DB_OFFICE_CODE      NUMBER                    NOT NULL,
  BASE_LOCATION_ID    VARCHAR2(16 BYTE)         NOT NULL,
  ACTIVE_FLAG         VARCHAR2(1 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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

COMMENT ON COLUMN AT_BASE_LOCATION.DB_OFFICE_CODE IS 'Refererences the office "owning" this location.  In the CWMS v2 schema, the office hosting the database "owns" all locations.';
COMMENT ON COLUMN AT_BASE_LOCATION.BASE_LOCATION_ID IS 'Text name of this Base Location';
COMMENT ON COLUMN AT_BASE_LOCATION.ACTIVE_FLAG IS 'T or F';


CREATE UNIQUE INDEX AT_BASE_LOCATION_PK ON AT_BASE_LOCATION
(BASE_LOCATION_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;


CREATE UNIQUE INDEX AT_BASE_LOCATION_IDX1 ON AT_BASE_LOCATION
(DB_OFFICE_CODE, UPPER("BASE_LOCATION_ID"))
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_BASE_LOCATION ADD (
   CONSTRAINT AT_BASE_LOCATION_CK_1 
   CHECK (TRIM("BASE_LOCATION_ID")="BASE_LOCATION_ID"))
/

--ALTER TABLE AT_BASE_LOCATION ADD (
--  CONSTRAINT AT_BASE_LOCATION_CK_2
-- CHECK (NVL("ACTIVE_FLAG",'T')='T'))
--/

ALTER TABLE AT_BASE_LOCATION ADD (
  CONSTRAINT AT_BASE_LOCATION_PK
 PRIMARY KEY
 (BASE_LOCATION_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_BASE_LOCATION ADD (
  CONSTRAINT AT_BASE_LOCATION_FK1 
 FOREIGN KEY (DB_OFFICE_CODE) 
 REFERENCES CWMS_OFFICE (OFFICE_CODE))
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


CREATE TABLE AT_PHYSICAL_LOCATION
(
  LOCATION_CODE       NUMBER(10)                NOT NULL,
  BASE_LOCATION_CODE  NUMBER(10)                NOT NULL,
  SUB_LOCATION_ID     VARCHAR2(32 BYTE),
  TIME_ZONE_CODE      NUMBER(10),
  COUNTY_CODE         NUMBER(10),
  LOCATION_TYPE       VARCHAR2(32 BYTE),
  ELEVATION           NUMBER,
  VERTICAL_DATUM      VARCHAR2(16 BYTE),
  LONGITUDE           NUMBER,
  LATITUDE            NUMBER,
  HORIZONTAL_DATUM    VARCHAR2(16 BYTE),
  PUBLIC_NAME         VARCHAR2(32 BYTE),
  LONG_NAME           VARCHAR2(80 BYTE),
  DESCRIPTION         VARCHAR2(512 BYTE),
  ACTIVE_FLAG         VARCHAR2(1 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504K
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

COMMENT ON TABLE AT_PHYSICAL_LOCATION IS 'Defines unique locations'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LOCATION_CODE IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.TIME_ZONE_CODE IS 'References the time zone associated with the geographic location.  Not necessarily the time zone of any data collected.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.COUNTY_CODE IS 'References the county'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LOCATION_TYPE IS 'User-defined type (e.g. "Stream Gage", "Reservoir", etc...), up to 16 characters.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.ELEVATION IS 'Ground elevation at location.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.VERTICAL_DATUM IS 'Datum of elevation.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LONGITUDE IS 'Longitude of location.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LATITUDE IS 'Latitude of location.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.PUBLIC_NAME IS 'User-defined public name, up to 32 characters.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LONG_NAME IS 'User-defined long name, up to 80 characters.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.DESCRIPTION IS 'User-defined description, up to 512 characters.'
/

COMMENT ON COLUMN AT_PHYSICAL_LOCATION.ACTIVE_FLAG IS 'T or F'
/


CREATE UNIQUE INDEX AT_PHYSICAL_LOCATION_PK ON AT_PHYSICAL_LOCATION
(LOCATION_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX AT_PHYSICAL_LOCATION_UI1 ON AT_PHYSICAL_LOCATION
(BASE_LOCATION_CODE, UPPER("SUB_LOCATION_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          104K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_PHYSICAL_LOCATION ADD (
  CONSTRAINT AT_PHYSICAL_LOCATION_CK_2
 CHECK (ACTIVE_FLAG ='T' or ACTIVE_FLAG = 'F'))
/

ALTER TABLE AT_PHYSICAL_LOCATION ADD (
  CONSTRAINT AT_PHYSICAL_LOCATION_CK_3
 CHECK (TRIM("SUB_LOCATION_ID")="SUB_LOCATION_ID"))
/

ALTER TABLE AT_PHYSICAL_LOCATION ADD (
  CONSTRAINT AT_PHYSICAL_LOCATION_PK
 PRIMARY KEY
 (LOCATION_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_PHYSICAL_LOCATION ADD (
  CONSTRAINT AT_PHYSICAL_LOCATION_FK_1 
 FOREIGN KEY (BASE_LOCATION_CODE) 
 REFERENCES AT_BASE_LOCATION (BASE_LOCATION_CODE))
/

ALTER TABLE AT_PHYSICAL_LOCATION ADD (
  CONSTRAINT AT_PHYSICAL_LOCATION_FK_2 
 FOREIGN KEY (COUNTY_CODE) 
 REFERENCES CWMS_COUNTY (COUNTY_CODE))
/

ALTER TABLE AT_PHYSICAL_LOCATION ADD (
  CONSTRAINT AT_PHYSICAL_LOCATION_FK_3 
 FOREIGN KEY (TIME_ZONE_CODE) 
 REFERENCES CWMS_TIME_ZONE (TIME_ZONE_CODE))
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

CREATE TABLE AT_LOC_CATEGORY
(
  LOC_CATEGORY_CODE  NUMBER,
  LOC_CATEGORY_ID    VARCHAR2(32 BYTE)          NOT NULL,
  DB_OFFICE_CODE     NUMBER                     NOT NULL,
  LOC_CATEGORY_DESC  VARCHAR2(128 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_LOC_CATEGORY_NAME_PK ON AT_LOC_CATEGORY
(LOC_CATEGORY_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX AT_LOC_CATEGORY_NAME_U1 ON AT_LOC_CATEGORY
(UPPER("LOC_CATEGORY_ID"), DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_LOC_CATEGORY ADD (
  CONSTRAINT AT_LOC_CATEGORY_NAME_PK
 PRIMARY KEY
 (LOC_CATEGORY_CODE)
    USING INDEX 
    TABLESPACE CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/
SET DEFINE OFF;
Insert into AT_LOC_CATEGORY
   (LOC_CATEGORY_CODE, LOC_CATEGORY_ID, DB_OFFICE_CODE, LOC_CATEGORY_DESC)
 Values
   (0, 'Default', 53, 'Default');

--------
--------

CREATE TABLE AT_LOC_GROUP
(
  LOC_GROUP_CODE     NUMBER,
  LOC_CATEGORY_CODE  NUMBER                     NOT NULL,
  LOC_GROUP_ID       VARCHAR2(32 BYTE)          NOT NULL,
  LOC_GROUP_DESC     VARCHAR2(128 BYTE),
  DB_OFFICE_CODE     NUMBER                     NOT NULL
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_LOC_GROUPS_PK ON AT_LOC_GROUP
(LOC_GROUP_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX AT_LOC_GROUPS_U1 ON AT_LOC_GROUP
(LOC_CATEGORY_CODE, UPPER("LOC_GROUP_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_LOC_GROUP ADD (
  CONSTRAINT AT_LOC_GROUPS_PK
 PRIMARY KEY
 (LOC_GROUP_CODE)
    USING INDEX 
    TABLESPACE CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_LOC_GROUP ADD (
  CONSTRAINT AT_LOC_GROUPS_FK2 
 FOREIGN KEY (DB_OFFICE_CODE) 
 REFERENCES CWMS_OFFICE (OFFICE_CODE))
/

ALTER TABLE AT_LOC_GROUP ADD (
  CONSTRAINT AT_LOC_GROUPS_FK1 
 FOREIGN KEY (LOC_CATEGORY_CODE) 
 REFERENCES AT_LOC_CATEGORY (LOC_CATEGORY_CODE))
/
SET DEFINE OFF;
Insert into AT_LOC_GROUP
   (LOC_GROUP_CODE, LOC_CATEGORY_CODE, LOC_GROUP_ID, LOC_GROUP_DESC, DB_OFFICE_CODE)
 Values
   (0, 0, 'Default', 'All Locations', 53);
COMMIT;
-----
-----

CREATE TABLE AT_LOC_GROUP_ASSIGNMENT
(
  LOCATION_CODE   NUMBER,
  LOC_GROUP_CODE  NUMBER,
  LOC_ALIAS_ID    VARCHAR2(128 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_LOC_GROUP_ASSIGNMENT_PK ON AT_LOC_GROUP_ASSIGNMENT
(LOCATION_CODE, LOC_GROUP_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_LOC_GROUP_ASSIGNMENT ADD (
  CONSTRAINT AT_LOC_GROUP_ASSIGNMENT_PK
 PRIMARY KEY
 (LOCATION_CODE, LOC_GROUP_CODE)
    USING INDEX 
    TABLESPACE CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_LOC_GROUP_ASSIGNMENT ADD (
  CONSTRAINT AT_LOC_GROUP_ASSIGNMENT_FK1 
 FOREIGN KEY (LOCATION_CODE) 
 REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE))
/

ALTER TABLE AT_LOC_GROUP_ASSIGNMENT ADD (
  CONSTRAINT AT_LOC_GROUP_ASSIGNMENT_FK2 
 FOREIGN KEY (LOC_GROUP_CODE) 
 REFERENCES AT_LOC_GROUP (LOC_GROUP_CODE))
/
SET DEFINE OFF;

Insert into AT_LOC_GROUP_ASSIGNMENT
   (LOCATION_CODE, LOC_GROUP_CODE, LOC_ALIAS_ID)
 Values
   (0, 0, NULL);
COMMIT;
----------
----------
-----------
-----------------
----------------------
--------------------------




---------------------------------
-- AT_CWMS_TS_SPEC table.
-- 

CREATE TABLE AT_CWMS_TS_SPEC
(
  TS_CODE              NUMBER                   NOT NULL,
  LOCATION_CODE        NUMBER                   NOT NULL,
  PARAMETER_CODE       NUMBER                   NOT NULL,
  PARAMETER_TYPE_CODE  NUMBER(10)               NOT NULL,
  INTERVAL_CODE        NUMBER(10)               NOT NULL,
  DURATION_CODE        NUMBER(10)               NOT NULL,
  VERSION              VARCHAR2(32 BYTE)        NOT NULL,
  DESCRIPTION          VARCHAR2(80 BYTE),
  INTERVAL_UTC_OFFSET  NUMBER                   NOT NULL,
  INTERVAL_FORWARD     NUMBER,
  INTERVAL_BACKWARD    NUMBER,
  INTERVAL_OFFSET_ID   VARCHAR2(16 BYTE),
  TIME_ZONE_CODE       NUMBER(10),
  VERSION_FLAG         VARCHAR2(1 BYTE),
  MIGRATE_VER_FLAG     VARCHAR2(1 BYTE),
  ACTIVE_FLAG          VARCHAR2(1 BYTE),
  DELETE_DATE          DATE,
  DATA_SOURCE          VARCHAR2(16 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          5M
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

COMMENT ON TABLE AT_CWMS_TS_SPEC IS 'Defines time series based on CWMS requirements.  This table also serves as time series specification super type.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.DESCRIPTION IS 'Additional information.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.VERSION_FLAG IS 'Default is NULL, indicating versioning is off. If set to "Y" then versioning is on'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.MIGRATE_VER_FLAG IS 'Default is NULL, indicating versioned data is not migrated to historic tables.  If set to "Y", versioned data is archived.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.ACTIVE_FLAG IS 'T or F'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.DELETE_DATE IS 'Is the date that this ts_id was marked for deletion.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.TS_CODE IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.LOCATION_CODE IS 'Primary key of AT_PHYSICAL_LOCATION table.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.PARAMETER_CODE IS 'Primary key of AT_PARAMETER table.  Must already exist in the AT_PARAMETER table.'
/

COMMENT ON COLUMN AT_CWMS_TS_SPEC.PARAMETER_TYPE_CODE IS 'Primary key of CWMS_PARAMETER_TYPE table.  Must already exist in the CWMS_PARAMETER_TYPE table.'
/


CREATE UNIQUE INDEX AT_CWMS_TS_SPEC_UI ON AT_CWMS_TS_SPEC
(LOCATION_CODE, PARAMETER_TYPE_CODE, PARAMETER_CODE, INTERVAL_CODE, 
DURATION_CODE, UPPER("VERSION"), DELETE_DATE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/



CREATE UNIQUE INDEX AT_CWMS_TS_SPEC_PK ON AT_CWMS_TS_SPEC
(TS_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_CK_3
 CHECK (TRIM(VERSION)=VERSION))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_CK_4
 CHECK (NVL(VERSION_FLAG,'T')='T'))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_CK_5
 CHECK (ACTIVE_FLAG ='T' or ACTIVE_FLAG = 'F'))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_PK
 PRIMARY KEY
 (TS_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_FK_1 
 FOREIGN KEY (PARAMETER_TYPE_CODE) 
 REFERENCES CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_FK_2 
 FOREIGN KEY (PARAMETER_CODE) 
 REFERENCES AT_PARAMETER (PARAMETER_CODE))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_FK_3 
 FOREIGN KEY (INTERVAL_CODE) 
 REFERENCES CWMS_INTERVAL (INTERVAL_CODE))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_FK_4 
 FOREIGN KEY (DURATION_CODE) 
 REFERENCES CWMS_DURATION (DURATION_CODE))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_FK_5 
 FOREIGN KEY (LOCATION_CODE) 
 REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE))
/

ALTER TABLE AT_CWMS_TS_SPEC ADD (
  CONSTRAINT AT_CWMS_TS_SPEC_FK_6 
 FOREIGN KEY (TIME_ZONE_CODE) 
 REFERENCES CWMS_TIME_ZONE (TIME_ZONE_CODE))
/



---------------------------------
-- AT_SCREENING table.
-- 
CREATE TABLE AT_SCREENING
(
  TS_CODE            NUMBER,
  SCREENING_CODE     NUMBER                     NOT NULL,
  ACTIVE_FLAG        VARCHAR2(1 BYTE),
  RESULTANT_TS_CODE  NUMBER
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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

COMMENT ON COLUMN AT_SCREENING.ACTIVE_FLAG IS 'T of F'
/


CREATE UNIQUE INDEX AT_SCREENING_PK ON AT_SCREENING
(TS_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_SCREENING ADD (
  CONSTRAINT AT_SCREENING_PK
 PRIMARY KEY
 (TS_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_SCREENING ADD (
  CONSTRAINT AT_SCREENING_FK02 
 FOREIGN KEY (RESULTANT_TS_CODE) 
 REFERENCES AT_CWMS_TS_SPEC (TS_CODE))
/
---------------------------------
-- AT_ALARM table.
-- 
CREATE TABLE AT_ALARM
(
  TS_CODE      NUMBER,
  TS_NI_HASH   VARCHAR2(80 BYTE)                NOT NULL,
  ALARM_CODE   NUMBER                           NOT NULL,
  ACTIVE_FLAG  VARCHAR2(1 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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

COMMENT ON COLUMN AT_ALARM.ACTIVE_FLAG IS 'T or F'
/


CREATE UNIQUE INDEX AT_ALARM_PK ON AT_ALARM
(TS_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_ALARM ADD (
  CONSTRAINT AT_ALARM_PK
 PRIMARY KEY
 (TS_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/



---------------------------------
-- AT_COMP_VT table.
-- 

CREATE TABLE AT_COMP_VT
(
  COMP_VT_CODE           NUMBER,
  COMP_VT_ID             VARCHAR2(16 BYTE),
  DB_OFFICE_CODE         NUMBER,
  FILENAME_DATCHK1       VARCHAR2(32 BYTE),
  FILENAME_DATCHK2       VARCHAR2(32 BYTE),
  FILENAME_TRN_IN        VARCHAR2(32 BYTE),
  DEFAULT_TIME_WINDOW    VARCHAR2(32 BYTE),
  CONTEXT_START_DATE     VARCHAR2(32 BYTE),
  EXCHANGE_SET_EXTRACT   VARCHAR2(32 BYTE),
  EXCHANGE_SET_POST_RAW  VARCHAR2(32 BYTE),
  EXCHANGE_SET_POST_REV  VARCHAR2(32 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_COMP_VT_PK ON AT_COMP_VT
(COMP_VT_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX AT_COMP_VT_U01 ON AT_COMP_VT
(COMP_VT_ID, DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_COMP_VT ADD (
  CONSTRAINT AT_COMP_VT_PK
 PRIMARY KEY
 (COMP_VT_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE AT_COMP_VT ADD (
  CONSTRAINT AT_COMP_VT_U01
 UNIQUE (COMP_VT_ID, DB_OFFICE_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_COMP_VT ADD (
  CONSTRAINT AT_COMP_VT_R01 
 FOREIGN KEY (DB_OFFICE_CODE) 
 REFERENCES CWMS_OFFICE (OFFICE_CODE))
/

---------------------------------
-- AT_TRANSFORM_CRITERIA table.
-- 

CREATE TABLE AT_TRANSFORM_CRITERIA
(
  TS_CODE                       NUMBER,
  DSSMATH_MACRO_CALL            VARCHAR2(128 BYTE),
  DSSMATH_POST_RAW              VARCHAR2(1 BYTE),
  COMP_VT_CODE                  NUMBER,
  CALL_SEQ_TABLE_LOOKUP         NUMBER,
  CALL_SEQ_SCALING              NUMBER,
  SCALING_FACTOR                NUMBER,
  SCALING_OFFSET                NUMBER,
  CALL_SEQ_MASS_CURVE_TO_INC    NUMBER,
  CALL_SEQ_INC_TO_MASS_CURVE    NUMBER,
  CALL_SEQ_INTERVAL_CONVERSION  NUMBER,
  RESULTANT_TS_CODE             NUMBER
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_TRANSFORM_CRITERIA_PK ON AT_TRANSFORM_CRITERIA
(TS_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


CREATE UNIQUE INDEX AT_TRANSFORM_CRITERIA_U02 ON AT_TRANSFORM_CRITERIA
(RESULTANT_TS_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_TRANSFORM_CRITERIA ADD (
  CONSTRAINT AT_TRANSFORM_CRITERIA_PK
 PRIMARY KEY
 (TS_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

ALTER TABLE AT_TRANSFORM_CRITERIA ADD (
  CONSTRAINT AT_TRANSFORM_CRITERIA_U02
 UNIQUE (RESULTANT_TS_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


ALTER TABLE AT_TRANSFORM_CRITERIA ADD (
  CONSTRAINT AT_TRANSFORM_CRITERIA_R02 
 FOREIGN KEY (RESULTANT_TS_CODE) 
 REFERENCES AT_CWMS_TS_SPEC (TS_CODE))
/

ALTER TABLE AT_TRANSFORM_CRITERIA ADD (
  CONSTRAINT AT_TRANSFORM_CRITERIA_R01 
 FOREIGN KEY (TS_CODE) 
 REFERENCES AT_CWMS_TS_SPEC (TS_CODE))
/

ALTER TABLE AT_TRANSFORM_CRITERIA ADD (
  CONSTRAINT AT_TRANSFORM_CRITERIA_R03 
 FOREIGN KEY (COMP_VT_CODE) 
 REFERENCES AT_COMP_VT (COMP_VT_CODE))
/


-----------------------------
-- AT_UNIT_ALIAS TABLE.
--
CREATE TABLE AT_UNIT_ALIAS
(
  ALIAS_ID        VARCHAR2(32 BYTE)             NOT NULL,
  DB_OFFICE_CODE  NUMBER	  					NOT NULL,
  UNIT_CODE       NUMBER(10)                    NOT NULL
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          200K
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
COMMENT ON TABLE AT_UNIT_ALIAS IS 'Contains unitAlias names for all units';
COMMENT ON COLUMN AT_UNIT_ALIAS.ALIAS_ID IS 'Alias name and primary key';
COMMENT ON COLUMN AT_UNIT_ALIAS.UNIT_CODE IS 'Foreign key referencing CWMS_UNIT table by its primary key';

-----------------------------
-- AT_UNIT_ALIAS TABLE indicies
--
CREATE UNIQUE INDEX AT_UNIT_ALIAS_PK ON AT_UNIT_ALIAS
(ALIAS_ID, DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;
-----------------------------
-- AT_UNIT_ALIAS TABLE constraints
--
ALTER TABLE AT_UNIT_ALIAS ADD CONSTRAINT AT_UNIT_ALIAS_R02 FOREIGN KEY (DB_OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);
ALTER TABLE AT_UNIT_ALIAS ADD CONSTRAINT FK_AT_UNIT_ALIAS  FOREIGN KEY (UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);
ALTER TABLE AT_UNIT_ALIAS ADD CONSTRAINT AT_UNIT_ALIAS_PK  PRIMARY KEY (ALIAS_ID, DB_OFFICE_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               );

-----------------------------
-- AT_USER_PREFERENCES TABLE.
--
CREATE TABLE AT_USER_PREFERENCES
(
  DB_OFFICE_CODE           NUMBER,
  USERNAME                 VARCHAR2(31 BYTE),
  DISPLAY_FORMAT_LAT_LONG  VARCHAR2(3 BYTE),
  DISPLAY_UNIT_SYSTEM      VARCHAR2(2 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_USER_PREFERENCES_PK ON AT_USER_PREFERENCES
(DB_OFFICE_CODE, USERNAME)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_USER_PREFERENCES ADD (
  CONSTRAINT AT_USER_PREFERENCES_PK
 PRIMARY KEY
 (DB_OFFICE_CODE, USERNAME)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/

-----------------------------
-- AT_OFFICE_SETTINGS TABLE.
--
CREATE TABLE AT_OFFICE_SETTINGS
(
  DB_OFFICE_CODE           NUMBER,
  SCREENING_USE_OTF        VARCHAR2(1 BYTE),
  SCREENING_USE_DATCHK     VARCHAR2(1 BYTE),
  SCREENING_USE_CWMS       VARCHAR2(1 BYTE),
  MAX_NORTHERN_LAT         NUMBER,
  MAX_SOUTHERN_LAT         NUMBER,
  MAX_WESTERN_LONG         NUMBER,
  MAX_EASTERN_LONG         NUMBER,
  DISPLAY_LAT_LONG_FORMAT  VARCHAR2(3 BYTE),
  DISPLAY_UNIT_SYSTEM      VARCHAR2(2 BYTE)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
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


CREATE UNIQUE INDEX AT_OFFICE_SETTINGS_PK ON AT_OFFICE_SETTINGS
(DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/


ALTER TABLE AT_OFFICE_SETTINGS ADD (
  CONSTRAINT AT_OFFICE_SETTINGS_PK
 PRIMARY KEY
 (DB_OFFICE_CODE)
    USING INDEX 
    TABLESPACE CWMS_20DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ))
/


---------------------------------
-- AT_PROPERTIES table.
-- 
CREATE TABLE AT_PROPERTIES
    (
        OFFICE_CODE    NUMBER(10),
        PROP_CATEGORY  VARCHAR2(256) NOT NULL,
        PROP_ID        VARCHAR2(256) NOT NULL,
        PROP_VALUE     VARCHAR2(256),
        PROP_COMMENT   VARCHAR2(256)
    )
    LOGGING 
    NOCOMPRESS 
    NOCACHE
    NOPARALLEL
    NOMONITORING;
                                  
COMMENT ON TABLE AT_PROPERTIES IS 'Generic properties, such as for Java application.';
COMMENT ON COLUMN AT_PROPERTIES.OFFICE_CODE   IS 'References the office that "owns" this property.';
COMMENT ON COLUMN AT_PROPERTIES.PROP_CATEGORY IS 'Major category or component to which property applies.';
COMMENT ON COLUMN AT_PROPERTIES.PROP_ID       IS 'Property name.';
COMMENT ON COLUMN AT_PROPERTIES.PROP_VALUE    IS 'Property value.';
COMMENT ON COLUMN AT_PROPERTIES.PROP_COMMENT  IS 'Notes about property usage or value.';
---------------------------------
-- AT_PROPERTIES constraints.
-- 
ALTER TABLE AT_PROPERTIES ADD CONSTRAINT AT_PROPERTIES_FK FOREIGN KEY(OFFICE_CODE)REFERENCES CWMS_OFFICE (OFFICE_CODE);
ALTER TABLE AT_PROPERTIES ADD CONSTRAINT AT_PROPERTIES_PK PRIMARY KEY(OFFICE_CODE, PROP_CATEGORY, PROP_ID);
    
---------------------------------
-- AT_PROPERTIES indicies.
-- 
CREATE UNIQUE INDEX at_properties_uk1 ON at_properties(OFFICE_CODE, UPPER("PROP_CATEGORY"), UPPER("PROP_ID"));



-----------------------------
-- AT_REPORT_TEMPLATES table
--
create table at_report_templates
(
  id               varchar2(256 byte),
  description      varchar2(256 byte),
  header_template  varchar2(4000 byte),
  record_template  varchar2(4000 byte),
  footer_template  varchar2(4000 byte)
)
tablespace cwms_20at_data
pctused    0
pctfree    10
initrans   1
maxtrans   255
storage    
(
  initial          64k
  minextents       1
  maxextents       2147483645
  pctincrease      0
  buffer_pool      default
)
logging 
nocompress 
nocache
noparallel
monitoring;
                                            
-----------------------------
-- AT_REPORT_TEMPLATES comments
--
comment on table  at_report_templates                 is 'Defines canned templates for use with CWMS_REPORT.TEXT_REPORT';
comment on column at_report_templates.id              is 'Unique record identifier, using hierarchical /dir/subdir/.../file syntax';
comment on column at_report_templates.description     is 'Description of this set of templates';
comment on column at_report_templates.header_template is 'A template string for the portion of the report before the records';
comment on column at_report_templates.record_template is 'A template string applied to each record in the report';
comment on column at_report_templates.footer_template is 'A template string for the portion of the report after the records';

-----------------------------
-- AT_REPORT_TEMPLATES indicies
--
ALTER TABLE AT_REPORT_TEMPLATES ADD 
(
  PRIMARY KEY (ID)
  USING INDEX 
  TABLESPACE cwms_20at_data
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  STORAGE    
  (
    INITIAL          64K
    MINEXTENTS       1
    MAXEXTENTS       2147483645
    PCTINCREASE      0
  )
);

-----------------------------
-- AT_REPORT_TEMPLATES default data
--
insert into at_report_templates values
(
'/cat_ts_table/xml',
'Generates XML from cat_ts_table records',
'<?xml version="1.0"?>\n<tsid_catalog>\n',
'  <tsid office="$1" ts_code="$4" offset="$3">$2</tsid>\n',
'</tsid_catalog>\n'
);

insert into at_report_templates values
(
'/cat_ts_table/html',
'Generates HTML from cat_ts_table records',
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
'
);

insert into at_report_templates values
(
   '/cat_ts_table/text',
   'Generates text from cat_ts_table records',
   '\nTIME SERIES CATALOG\nREPORT GENERATED BY $host AT $time\n\n',
   '$1%-8.8s$4%-8d$3%12d$2\n',
   '\n$count TOTAL RECORDS PROCESSED\n'
);

commit;

-----------------------------
-- AT_CLOB table
--
create table at_clob
(
  id           varchar2(256 byte) not null,
  description  varchar2(256 byte),
  value        clob
)
tablespace cwms_20at_data
pctused    0
pctfree    10
initrans   1
maxtrans   255
storage    
(
  initial          64k
  minextents       1
  maxextents       2147483645
  pctincrease      0
  buffer_pool      default
)
logging 
nocompress 
lob (value) store as 
( 
  tablespace  cwms_20at_data 
  enable      storage in row
  chunk       8192
  pctversion  0
  nocache
  storage   
  (
    initial          64k
    minextents       1
    maxextents       2147483645
    pctincrease      0
    buffer_pool      default
  )
)
nocache
noparallel
monitoring;

-----------------------------
-- AT_CLOB comments
--
comment on table  at_clob             is 'Character Large OBject Storage for CWMS';
comment on column at_clob.id          is 'Unique record identifier, using hierarchical /dir/subdir/.../file syntax';
comment on column at_clob.description is 'Description of this CLOB';
comment on column at_clob.value       is 'The CLOB data';

-----------------------------
-- AT_CLOB indicies
--
alter table at_clob add 
(
  primary key (id)
  using index 
  tablespace cwms_20at_data
  pctfree    10
  initrans   2
  maxtrans   255
  storage    
  (
    initial          64k
    minextents       1
    maxextents       2147483645
    pctincrease      0
  )
);

-----------------------------
-- AT_CLOB default data
--
insert into at_clob values
(      
'/xslt/identity',
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
'
);

insert into at_clob values
(      
'/xslt/cat_ts_xml/tabbed_text',
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
'
);

insert into at_clob values
(      
'/xslt/cat_ts_xml/html',
'Transforms cat_ts_xml output to html',
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
'
);

commit;


SHOW ERRORS;
COMMIT;

