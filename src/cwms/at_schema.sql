o/* Formatted on 2007/11/14 12:53 (Formatter Plus v4.8.8) */
/* CWMS Version 2.0 --
This script should be run by the cwms schema owner.
*/
SET serveroutput on
SET define on
@@defines.sql

------------------------------------------------------
-- drop tables, mviews and mview logs if they exist --
------------------------------------------------------

declare
   type id_array_t is table of varchar2 (32);

   table_names     id_array_t := new id_array_t();
   mview_log_names id_array_t := new id_array_t();
begin
   for rec in (select object_name 
                  from dba_objects 
                 where object_type = 'TABLE' 
                   and object_name not like 'AQ$%'
                   and object_name not like 'SYS\_%' escape '\')
   loop                       
      begin
            if substr(rec.object_name, 1, 6) = 'MLOG$_' then
                 execute immediate 'drop materialized view log on '
                                   || substr(rec.object_name, 7); 

                 dbms_output.put_line ('Dropped materialized view log on '
                                       || substr(rec.object_name, 7)
                    );
            else
               if substr(rec.object_name, 1, 3) = 'AT_'
                  and rec.object_name != 'AT_PARAMETER'
                  and rec.object_name != 'AT_DISPLAY_UNITS'
                  and rec.object_name != 'AT_LOCATION_KIND'
               then
                  execute immediate 'drop table '
                                     || rec.object_name
                              || ' cascade constraints';

                  dbms_output.put_line ('Dropped table ' || rec.object_name);
               end if;
            end if;
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
TABLESPACE CWMS_20AT_DATA
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
MONITORING
/

COMMIT ;

--
----
------
-- The at_ts_table_properties table is loaded with data
-- in the at_schema_tsv.sql ddl file.
------
----
--

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
TABLESPACE CWMS_20AT_DATA
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

COMMENT ON COLUMN at_base_location.db_office_code IS 'Refererences the office "owning" this location.  In the CWMS v2 schema, the office hosting the database "owns" all locations.';
COMMENT ON COLUMN at_base_location.base_location_id IS 'Text name of this Base Location';
COMMENT ON COLUMN at_base_location.active_flag IS 'Specifies whether data is being collected for this location';


CREATE UNIQUE INDEX at_base_location_pk ON at_base_location
(base_location_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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


CREATE UNIQUE INDEX at_base_location_idx1 ON at_base_location
(db_office_code, UPPER("BASE_LOCATION_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
 REFERENCES cwms_office (office_code));
INSERT INTO at_base_location
            (base_location_code, db_office_code, base_location_id, active_flag
            )
     VALUES (0, (SELECT office_code
                   FROM cwms_office
                  WHERE office_id = 'CWMS'), 'Deleted TS ID', 'F'
            )
/
COMMIT;
--------------------
-- AT_PHYSICAL_LOCATION table
-- 


CREATE TABLE AT_PHYSICAL_LOCATION
(
  LOCATION_CODE       NUMBER(10)                NOT NULL,
  BASE_LOCATION_CODE  NUMBER(10)                NOT NULL,
  SUB_LOCATION_ID     VARCHAR2(32),
  TIME_ZONE_CODE      NUMBER(10),
  COUNTY_CODE         NUMBER(10),
  LOCATION_TYPE       VARCHAR2(32),
  ELEVATION           NUMBER,
  VERTICAL_DATUM      VARCHAR2(16),
  LONGITUDE           NUMBER,
  LATITUDE            NUMBER,
  HORIZONTAL_DATUM    VARCHAR2(16),
  PUBLIC_NAME         VARCHAR2(32),
  LONG_NAME           VARCHAR2(80),
  DESCRIPTION         VARCHAR2(1024),
  ACTIVE_FLAG         VARCHAR2(1),
  LOCATION_KIND       NUMBER(10),
  MAP_LABEL           VARCHAR2(50),
  PUBLISHED_LATITUDE  NUMBER,
  PUBLISHED_LONGITUDE NUMBER,
  OFFICE_CODE         NUMBER(10),
  NATION_CODE         VARCHAR2(2),
  NEAREST_CITY        VARCHAR2(50),
  CONSTRAINT AT_PHYSICAL_LOCATION_PK  PRIMARY KEY (LOCATION_CODE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_PHYSICAL_LOCATION                     IS 'Defines unique locations';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LOCATION_CODE       IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.TIME_ZONE_CODE      IS 'References the time zone associated with the geographic location.  Not necessarily the time zone of any data collected.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.COUNTY_CODE         IS 'References the county containing this location';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LOCATION_TYPE       IS 'User-defined type (e.g. "Stream Gage", "Reservoir", etc...), up to 16 characters.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.ELEVATION           IS 'Elevation of location.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.VERTICAL_DATUM      IS 'Datum of elevation.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LONGITUDE           IS 'Longitude of location.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LATITUDE            IS 'Latitude of location.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.HORIZONTAL_DATUM    IS 'Datum of longitude and latitude.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.PUBLIC_NAME         IS 'User-defined public name, up to 32 characters.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LONG_NAME           IS 'User-defined long name, up to 80 characters.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.DESCRIPTION         IS 'User-defined description, up to 512 characters.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.ACTIVE_FLAG         IS 'T or F';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.LOCATION_KIND       IS 'Reference to location kind in AT_LOCATION_KIND';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.MAP_LABEL           IS 'User-defined label for map location (i.e., CorpsMap), max 50 characters.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.PUBLISHED_LATITUDE  IS 'Latitude of location as published by owning agency.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.PUBLISHED_LONGITUDE IS 'Longitude of location as published by owning agency.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.OFFICE_CODE         IS 'References the office who''s bounday contains this location.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.NATION_CODE         IS 'References the nation containing this location.';
COMMENT ON COLUMN AT_PHYSICAL_LOCATION.NEAREST_CITY        IS 'Name of city nearest this location.';


ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_CK1 CHECK (TRIM(SUB_LOCATION_ID) = SUB_LOCATION_ID);  
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_CK2 CHECK (ACTIVE_FLAG ='T' OR ACTIVE_FLAG = 'F');
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK1 FOREIGN KEY (BASE_LOCATION_CODE) REFERENCES AT_BASE_LOCATION (BASE_LOCATION_CODE); 
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK2 FOREIGN KEY (COUNTY_CODE) REFERENCES CWMS_COUNTY (COUNTY_CODE);  
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK3 FOREIGN KEY (TIME_ZONE_CODE) REFERENCES CWMS_TIME_ZONE (TIME_ZONE_CODE);
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK4 FOREIGN KEY (LOCATION_KIND) REFERENCES AT_LOCATION_KIND (LOCATION_KIND_CODE);
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK5 FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);  
ALTER TABLE AT_PHYSICAL_LOCATION ADD CONSTRAINT AT_PHYSICAL_LOCATION_FK6 FOREIGN KEY (NATION_CODE) REFERENCES CWMS_NATION (NATION_CODE);  

CREATE UNIQUE INDEX AT_PHYSICAL_LOCATION_U1 ON AT_PHYSICAL_LOCATION (BASE_LOCATION_CODE, UPPER(SUB_LOCATION_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          104K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

   
INSERT INTO at_physical_location
            (location_code, base_location_code, active_flag)
     VALUES (0, 0, 'F');

COMMIT;

---------------------------------------------------------------------------
-- This information is not included directly in the AT_PHYSICAL_LOCATION --
-- table because doing so prevents using the table's materialized view   --
-- log for the MV_CWMS_TS_ID view, which is central to lots of stuff.    --
---------------------------------------------------------------------------
CREATE TABLE AT_GEOGRAPHIC_LOCATION
(
  LOCATION_CODE NUMBER(10)          NOT NULL,
  GEOGRAPHIC_ID VARCHAR2(32)        DEFAULT 'LOCATION',
  POINT         MDSYS.SDO_GEOMETRY,
  MULTI_POINT   MDSYS.SDO_GEOMETRY,
  POLYGON       MDSYS.SDO_GEOMETRY,
  DESCRIPTION   VARCHAR2(256),
  CONSTRAINT AT_GEOGRAPHIC_LOCATION_PK  PRIMARY KEY (LOCATION_CODE, GEOGRAPHIC_ID) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504K
            NEXT             1M                                                     
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_GEOGRAPHIC_LOCATION               IS 'Geographic aspect of location';
COMMENT ON COLUMN AT_GEOGRAPHIC_LOCATION.GEOGRAPHIC_ID IS 'Text ID of point and/or multi-point and/or polygon';
COMMENT ON COLUMN AT_GEOGRAPHIC_LOCATION.LOCATION_CODE IS 'Reference to location';
COMMENT ON COLUMN AT_GEOGRAPHIC_LOCATION.POINT         IS 'Point location in WGS 84';
COMMENT ON COLUMN AT_GEOGRAPHIC_LOCATION.MULTI_POINT   IS 'Multi-point location in WGS 84';
COMMENT ON COLUMN AT_GEOGRAPHIC_LOCATION.POLYGON       IS 'Polygon location in WGS 84';
COMMENT ON COLUMN AT_GEOGRAPHIC_LOCATION.DESCRIPTION   IS 'Optional description';

ALTER TABLE AT_GEOGRAPHIC_LOCATION ADD CONSTRAINT AT_GEOGRAPHIC_LOCATION_CK1 CHECK (GEOGRAPHIC_ID = UPPER(GEOGRAPHIC_ID));
ALTER TABLE AT_GEOGRAPHIC_LOCATION ADD CONSTRAINT AT_GEOGRAPHIC_LOCATION_FK1 FOREIGN KEY (LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);

DELETE FROM USER_SDO_GEOM_METADATA WHERE TABLE_NAME='AT_GEOGRAPHIC_LOCATION';
DELETE FROM MDSYS.SDO_GEOM_METADATA_TABLE WHERE SDO_TABLE_NAME='AT_GEOGRAPHIC_LOCATION';

INSERT INTO MDSYS.SDO_GEOM_METADATA_TABLE VALUES (
   '&cwms_schema',
   'AT_GEOGRAPHIC_LOCATION',
   'POINT',
   SDO_DIM_ARRAY(
      SDO_DIM_ELEMENT('X', -180,  180, 0.01),
      SDO_DIM_ELEMENT('Y',  -90,   90, 0.01), 
      SDO_DIM_ELEMENT('Z', -420, 8850, 0.05)),
   (SELECT SRID 
      FROM MDSYS.CS_SRS 
     WHERE CS_NAME='WGS 84 (geographic 3D)'));

INSERT INTO MDSYS.SDO_GEOM_METADATA_TABLE VALUES (
   '&cwms_schema',
   'AT_GEOGRAPHIC_LOCATION',
   'MULTI_POINT',
   SDO_DIM_ARRAY(
      SDO_DIM_ELEMENT('X', -180,  180, 0.01),
      SDO_DIM_ELEMENT('Y',  -90,   90, 0.01), 
      SDO_DIM_ELEMENT('Z', -420, 8850, 0.05)),
   (SELECT SRID 
      FROM MDSYS.CS_SRS 
     WHERE CS_NAME='WGS 84 (geographic 3D)'));

INSERT INTO MDSYS.SDO_GEOM_METADATA_TABLE VALUES (
   '&cwms_schema',
   'AT_GEOGRAPHIC_LOCATION',
   'POLYGON',
   SDO_DIM_ARRAY(
      SDO_DIM_ELEMENT('X', -180,  180, 0.01),
      SDO_DIM_ELEMENT('Y',  -90,   90, 0.01), 
      SDO_DIM_ELEMENT('Z', -420, 8850, 0.05)),
   (SELECT SRID 
      FROM MDSYS.CS_SRS 
     WHERE CS_NAME='WGS 84 (geographic 3D)'));


CREATE INDEX AT_GEOGRAPHIC_LOCATION_PT_IDX
   ON AT_GEOGRAPHIC_LOCATION(POINT)
   INDEXTYPE IS MDSYS.SPATIAL_INDEX PARAMETERS ('layer_gtype=POINT')
/

CREATE INDEX AT_GEOGRAPHIC_LOCATION_MP_IDX
   ON AT_GEOGRAPHIC_LOCATION(MULTI_POINT)
   INDEXTYPE IS MDSYS.SPATIAL_INDEX PARAMETERS ('layer_gtype=MULTIPOINT')
/

CREATE INDEX AT_GEOGRAPHIC_LOCATION_PG_IDX
   ON AT_GEOGRAPHIC_LOCATION(POLYGON)
   INDEXTYPE IS MDSYS.SPATIAL_INDEX PARAMETERS ('layer_gtype=POLYGON')
/

CREATE TABLE AT_LOCATION_URL
(
   LOCATION_CODE NUMBER(10),
   URL_ID        VARCHAR2(32),
   URL_ADDRESS   VARCHAR2(1024),
   URL_TITLE     VARCHAR2(256),
   CONSTRAINT AT_LOCATION_URL_PK  PRIMARY KEY (LOCATION_CODE, URL_ID) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


COMMENT ON TABLE  AT_LOCATION_URL               IS 'Contains URLs pertaining to specific locations.';
COMMENT ON COLUMN AT_LOCATION_URL.LOCATION_CODE IS 'Reference to location.';
COMMENT ON COLUMN AT_LOCATION_URL.URL_ID        IS 'Short identifier for URL.';
COMMENT ON COLUMN AT_LOCATION_URL.URL_ADDRESS   IS 'The URL.';
COMMENT ON COLUMN AT_LOCATION_URL.URL_TITLE     IS 'Title for URL display.';

ALTER TABLE AT_LOCATION_URL ADD CONSTRAINT AT_LOCATION_URL_CK1 CHECK (TRIM(URL_ID) = URL_ID);
ALTER TABLE AT_LOCATION_URL ADD CONSTRAINT AT_LOCATION_URL_CK2 CHECK (TRIM(URL_ADDRESS) = URL_ADDRESS);
ALTER TABLE AT_LOCATION_URL ADD CONSTRAINT AT_LOCATION_URL_CK3 CHECK (TRIM(URL_TITLE) = URL_TITLE);
ALTER TABLE AT_LOCATION_URL ADD CONSTRAINT AT_LOCATION_URL_FK1 FOREIGN KEY (LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);

CREATE UNIQUE INDEX AT_LOCATION_URL_U1 ON AT_LOCATION_URL (LOCATION_CODE, UPPER(URL_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

CREATE TABLE AT_STREAM
(
  STREAM_LOCATION_CODE      NUMBER(10)    NOT NULL,
  ZERO_STATION              VARCHAR2(2),
  DIVERTING_STREAM_CODE     NUMBER(10),
  DIVERSION_STATION         BINARY_DOUBLE,
  DIVERSION_BANK            VARCHAR2(1),
  RECEIVING_STREAM_CODE     NUMBER(10),
  CONFLUENCE_STATION        BINARY_DOUBLE,
  CONFLUENCE_BANK           VARCHAR2(1),
  STREAM_LENGTH             BINARY_DOUBLE,
  AVERAGE_SLOPE             BINARY_DOUBLE,
  COMMENTS                  VARCHAR2(256),
  CONSTRAINT AT_STREAM_PK  PRIMARY KEY (STREAM_LOCATION_CODE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_STREAM                           IS 'Contains non-geographic information for streams';
COMMENT ON COLUMN AT_STREAM.STREAM_LOCATION_CODE      IS 'References stream location.';
COMMENT ON COLUMN AT_STREAM.ZERO_STATION              IS 'Specifies whether streams stationing begins upstream or downstream';
COMMENT ON COLUMN AT_STREAM.DIVERTING_STREAM_CODE     IS 'Reference to stream this stream diverted from';
COMMENT ON COLUMN AT_STREAM.DIVERSION_STATION         IS 'Station of diversion on reference stream';
COMMENT ON COLUMN AT_STREAM.DIVERSION_BANK            IS 'Bank of diversion on reference stream';
COMMENT ON COLUMN AT_STREAM.RECEIVING_STREAM_CODE     IS 'Reference to stream this stream flows into';
COMMENT ON COLUMN AT_STREAM.CONFLUENCE_STATION        IS 'Station of confluence on reference stream';
COMMENT ON COLUMN AT_STREAM.CONFLUENCE_BANK           IS 'Bank of confluence on reference stream';
COMMENT ON COLUMN AT_STREAM.STREAM_LENGTH             IS 'Length of this stream';
COMMENT ON COLUMN AT_STREAM.AVERAGE_SLOPE             IS 'Average slope in percent over the entire length of the stream';
COMMENT ON COLUMN AT_STREAM.COMMENTS                  IS 'Additional comments for stream';

ALTER TABLE AT_STREAM ADD CONSTRAINT AT_STREAM_FK1 FOREIGN KEY (STREAM_LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);
ALTER TABLE AT_STREAM ADD CONSTRAINT AT_STREAM_FK2 FOREIGN KEY (DIVERTING_STREAM_CODE) REFERENCES AT_STREAM (STREAM_LOCATION_CODE);
ALTER TABLE AT_STREAM ADD CONSTRAINT AT_STREAM_FK3 FOREIGN KEY (RECEIVING_STREAM_CODE) REFERENCES AT_STREAM (STREAM_LOCATION_CODE);
ALTER TABLE AT_STREAM ADD CONSTRAINT AT_STREAM_CK1 CHECK (ZERO_STATION = 'US' OR ZERO_STATION = 'DS');
ALTER TABLE AT_STREAM ADD CONSTRAINT AT_STREAM_CK2 CHECK (DIVERSION_BANK IS NULL OR DIVERSION_BANK = 'R' OR DIVERSION_BANK = 'L');
ALTER TABLE AT_STREAM ADD CONSTRAINT AT_STREAM_CK3 CHECK (CONFLUENCE_BANK IS NULL OR CONFLUENCE_BANK = 'R' OR CONFLUENCE_BANK = 'L');

CREATE TABLE AT_STREAM_REACH
(
  STREAM_LOCATION_CODE NUMBER(10)    NOT NULL,
  STREAM_REACH_ID      VARCHAR2(64)  NOT NULL,
  UPSTREAM_STATION     BINARY_DOUBLE NOT NULL,
  DOWNSTREAM_STATION   BINARY_DOUBLE NOT NULL,
  STREAM_TYPE_ID       VARCHAR2(4),
  COMMENTS             VARCHAR2(256),
  CONSTRAINT AT_STREAM_REACH_PK  PRIMARY KEY (STREAM_LOCATION_CODE, UPSTREAM_STATION, DOWNSTREAM_STATION) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_STREAM_REACH                      IS 'Contains stationing and type information for portions of streams.';
COMMENT ON COLUMN AT_STREAM_REACH.STREAM_LOCATION_CODE IS 'References stream.';
COMMENT ON COLUMN AT_STREAM_REACH.STREAM_REACH_ID      IS 'Name of stream reach.';
COMMENT ON COLUMN AT_STREAM_REACH.UPSTREAM_STATION     IS 'Upstream extent of reach.';
COMMENT ON COLUMN AT_STREAM_REACH.DOWNSTREAM_STATION   IS 'Downstream extent of reach.';
COMMENT ON COLUMN AT_STREAM_REACH.STREAM_TYPE_ID       IS 'References stream type (Rosgen Classification identifier).';
COMMENT ON COLUMN AT_STREAM_REACH.COMMENTS             IS 'Additional comments on reach.';

ALTER TABLE AT_STREAM_REACH ADD CONSTRAINT AT_STREAM_REACH_FK1 FOREIGN KEY (STREAM_LOCATION_CODE) REFERENCES AT_STREAM (STREAM_LOCATION_CODE);
ALTER TABLE AT_STREAM_REACH ADD CONSTRAINT AT_STREAM_REACH_FK2 FOREIGN KEY (STREAM_TYPE_ID) REFERENCES CWMS_STREAM_TYPE (STREAM_TYPE_ID);

CREATE UNIQUE INDEX IDX1 ON AT_STREAM_REACH (STREAM_LOCATION_CODE, UPPER(STREAM_REACH_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
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

CREATE TABLE AT_STREAM_LOCATION
(
  LOCATION_CODE           NUMBER(10)   NOT NULL,
  STREAM_LOCATION_CODE    NUMBER(10)   NOT NULL,
  STATION                 NUMBER       NOT NULL,
  PUBLISHED_STATION       NUMBER,
  NAVIGATION_STATION      NUMBER,
  BANK                    VARCHAR2(1),
  LOWEST_MEASURABLE_STAGE BINARY_DOUBLE,
  DRAINAGE_AREA           BINARY_DOUBLE,
  UNGAGED_AREA            BINARY_DOUBLE,
  CONSTRAINT AT_STREAM_LOCATION_PK  PRIMARY KEY (LOCATION_CODE, STREAM_LOCATION_CODE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_STREAM_LOCATION                         IS 'Contains metadata for stream locations';
COMMENT ON COLUMN AT_STREAM_LOCATION.LOCATION_CODE           IS 'Reference to physical location';
COMMENT ON COLUMN AT_STREAM_LOCATION.STREAM_LOCATION_CODE    IS 'Reference to stream';
COMMENT ON COLUMN AT_STREAM_LOCATION.STATION                 IS 'Station in km of stream at location';
COMMENT ON COLUMN AT_STREAM_LOCATION.PUBLISHED_STATION       IS 'Published station in km of stream at location';
COMMENT ON COLUMN AT_STREAM_LOCATION.NAVIGATION_STATION      IS 'Navigation station in km of stream at location';
COMMENT ON COLUMN AT_STREAM_LOCATION.BANK                    IS 'Bank of stream at location';
COMMENT ON COLUMN AT_STREAM_LOCATION.LOWEST_MEASURABLE_STAGE IS 'Lowest stage in m that is measurable at this stream location.';
COMMENT ON COLUMN AT_STREAM_LOCATION.DRAINAGE_AREA           IS 'Total drainage area in km2 above this stream location.';
COMMENT ON COLUMN AT_STREAM_LOCATION.UNGAGED_AREA            IS 'Drainage area in km2 above this stream location and below upstream gage(s).';

ALTER TABLE AT_STREAM_LOCATION ADD CONSTRAINT AT_STREAM_LOCATION_FK1 FOREIGN KEY (LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);
ALTER TABLE AT_STREAM_LOCATION ADD CONSTRAINT AT_STREAM_LOCATION_FK2 FOREIGN KEY (STREAM_LOCATION_CODE) REFERENCES AT_STREAM (STREAM_LOCATION_CODE);
ALTER TABLE AT_STREAM_LOCATION ADD CONSTRAINT AT_STREAM_LOCATION_CK1 CHECK (BANK IS NULL OR BANK = 'R' OR BANK = 'L');

CREATE TABLE AT_BASIN
(
  BASIN_LOCATION_CODE        NUMBER(10)    NOT NULL,
  TOTAL_DRAINAGE_AREA        BINARY_DOUBLE,
  CONTRIBUTING_DRAINAGE_AREA BINARY_DOUBLE,
  PRIMARY_STREAM_CODE        NUMBER(10),
  PARENT_BASIN_CODE          NUMBER(10),
  SORT_ORDER                 BINARY_DOUBLE,
  CONSTRAINT AT_BASIN_PK  PRIMARY KEY (BASIN_LOCATION_CODE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_BASIN                              IS 'Contains non-geographic information for basins';
COMMENT ON COLUMN AT_BASIN.BASIN_LOCATION_CODE          IS 'References basin location.';
COMMENT ON COLUMN AT_BASIN.TOTAL_DRAINAGE_AREA          IS 'Total area of basin';
COMMENT ON COLUMN AT_BASIN.CONTRIBUTING_DRAINAGE_AREA   IS 'Contributing drainage area of basin';
COMMENT ON COLUMN AT_BASIN.PRIMARY_STREAM_CODE          IS 'Reference to the stream record that the impoundment lies on';
COMMENT ON COLUMN AT_BASIN.PARENT_BASIN_CODE            IS 'Reference to containing basin';
COMMENT ON COLUMN AT_BASIN.SORT_ORDER                   IS 'Sorting order for application use';

ALTER TABLE AT_BASIN ADD CONSTRAINT AT_BASIN_FK1 FOREIGN KEY (BASIN_LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);
ALTER TABLE AT_BASIN ADD CONSTRAINT AT_BASIN_FK2 FOREIGN KEY (PRIMARY_STREAM_CODE) REFERENCES AT_STREAM (STREAM_LOCATION_CODE);
ALTER TABLE AT_BASIN ADD CONSTRAINT AT_BASIN_FK3 FOREIGN KEY (PARENT_BASIN_CODE) REFERENCES AT_BASIN (BASIN_LOCATION_CODE);

CREATE TABLE AT_GAGE
(
  GAGE_CODE                NUMBER(10)    NOT NULL,
  GAGE_TYPE_CODE           NUMBER(10)    NOT NULL,
  GAGE_LOCATION_CODE       NUMBER(10)    NOT NULL,
  GAGE_ID                  VARCHAR2(32)  NOT NULL,
  DISCONTINUED             VARCHAR2(1)   NOT NULL,
  OUT_OF_SERVICE           VARCHAR2(1)   NOT NULL,
  MANUFACTURER             VARCHAR2(32),
  MODEL_NUMBER             VARCHAR2(32),
  SERIAL_NUMBER            VARCHAR2(32),
  PHONE_NUMBER             VARCHAR2(16),
  INTERNET_ADDRESS         VARCHAR2(32),
  OTHER_ACCESS_ID          VARCHAR2(32),
  ASSOCIATED_LOCATION_CODE NUMBER(10),
  COMMENTS                 VARCHAR2(256),
  CONSTRAINT AT_GAGE_PK  PRIMARY KEY (GAGE_CODE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE AT_GAGE                           IS 'Contains gage type information for locations';
COMMENT ON COLUMN AT_GAGE.GAGE_CODE                IS 'Synthetic key.';
COMMENT ON COLUMN AT_GAGE.GAGE_TYPE_CODE           IS 'Refernce to gage type.';
COMMENT ON COLUMN AT_GAGE.GAGE_LOCATION_CODE       IS 'References location.';
COMMENT ON COLUMN AT_GAGE.GAGE_ID                  IS 'Gage identifier unique among gages at this location.';
COMMENT ON COLUMN AT_GAGE.DISCONTINUED             IS 'Gage has been discontinued (T) or not (F).';
COMMENT ON COLUMN AT_GAGE.OUT_OF_SERVICE           IS 'Gage is currently out of service (T) or not (F).';
COMMENT ON COLUMN AT_GAGE.MANUFACTURER             IS 'Gage manufacturer';
COMMENT ON COLUMN AT_GAGE.MODEL_NUMBER             IS 'Gage model number';
COMMENT ON COLUMN AT_GAGE.SERIAL_NUMBER            IS 'Gage serial number';
COMMENT ON COLUMN AT_GAGE.PHONE_NUMBER             IS 'Telephone number for remote access to gage.';
COMMENT ON COLUMN AT_GAGE.INTERNET_ADDRESS         IS 'IP address for remote access to gage.';
COMMENT ON COLUMN AT_GAGE.OTHER_ACCESS_ID          IS 'Other remote access id.';
COMMENT ON COLUMN AT_GAGE.ASSOCIATED_LOCATION_CODE IS 'Reference to location of an associated gage (i.e., headwater/tailwater).';
COMMENT ON COLUMN AT_GAGE.COMMENTS                 IS 'Comments';

ALTER TABLE AT_GAGE ADD CONSTRAINT AT_GAGE_CK1 CHECK (TRIM(GAGE_ID) = GAGE_ID);
ALTER TABLE AT_GAGE ADD CONSTRAINT AT_GAGE_CK2 CHECK (DISCONTINUED ='T' OR DISCONTINUED = 'F');
ALTER TABLE AT_GAGE ADD CONSTRAINT AT_GAGE_CK3 CHECK (OUT_OF_SERVICE ='T' OR OUT_OF_SERVICE = 'F');
ALTER TABLE AT_GAGE ADD CONSTRAINT AT_GAGE_FK2 FOREIGN KEY (GAGE_LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);  
ALTER TABLE AT_GAGE ADD CONSTRAINT AT_GAGE_FK1 FOREIGN KEY (GAGE_TYPE_CODE) REFERENCES CWMS_GAGE_TYPE (GAGE_TYPE_CODE);  
ALTER TABLE AT_GAGE ADD CONSTRAINT AT_GAGE_FK3 FOREIGN KEY (ASSOCIATED_LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);  

CREATE UNIQUE INDEX AT_GAGE_IDX1 ON AT_GAGE (GAGE_LOCATION_CODE, UPPER(GAGE_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
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

CREATE TABLE AT_GAGE_SENSOR
(
  GAGE_CODE          NUMBER(10)    NOT NULL,
  SENSOR_ID          VARCHAR2(32)  NOT NULL,
  PARAMETER_CODE     NUMBER(10)    NOT NULL,
  UNIT_CODE          NUMBER(10),
  VALID_RANGE_MIN    BINARY_DOUBLE,
  VALID_RANGE_MAX    BINARY_DOUBLE,
  ZERO_READING_VALUE BINARY_DOUBLE,
  OUT_OF_SERVICE     VARCHAR2(1)   NOT NULL,
  MANUFACTURER       VARCHAR2(32),
  MODEL_NUMBER       VARCHAR2(32),
  SERIAL_NUMBER      VARCHAR2(32),
  COMMENTS           VARCHAR2(256),
  CONSTRAINT AT_GAGE_SENSOR_PK  PRIMARY KEY (GAGE_CODE, SENSOR_ID)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          504K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_GAGE_SENSOR                    IS 'Contains information about sensors on gages.';
COMMENT ON COLUMN AT_GAGE_SENSOR.GAGE_CODE          IS 'Reference to gage.';
COMMENT ON COLUMN AT_GAGE_SENSOR.SENSOR_ID          IS 'Name of sensor.';
COMMENT ON COLUMN AT_GAGE_SENSOR.PARAMETER_CODE     IS 'Reference to sensed/measured parameter.';
COMMENT ON COLUMN AT_GAGE_SENSOR.UNIT_CODE          IS 'Reference to reporting unit for sensed/measured parameter.';
COMMENT ON COLUMN AT_GAGE_SENSOR.VALID_RANGE_MIN    IS 'Lowest valid world value for sensor.';
COMMENT ON COLUMN AT_GAGE_SENSOR.VALID_RANGE_MAX    IS 'Highest valid world value for sensor.';
COMMENT ON COLUMN AT_GAGE_SENSOR.ZERO_READING_VALUE IS 'World value for sensor reading/measurement of zero.';
COMMENT ON COLUMN AT_GAGE_SENSOR.OUT_OF_SERVICE     IS 'Sensor is currently out of service (T) or not (F).';
COMMENT ON COLUMN AT_GAGE_SENSOR.MANUFACTURER       IS 'Sensor manufacturer';
COMMENT ON COLUMN AT_GAGE_SENSOR.MODEL_NUMBER       IS 'Sensor model number';
COMMENT ON COLUMN AT_GAGE_SENSOR.SERIAL_NUMBER      IS 'Sensor serial number';
COMMENT ON COLUMN AT_GAGE_SENSOR.COMMENTS           IS 'Additional comments for sensor.';

ALTER TABLE AT_GAGE_SENSOR ADD CONSTRAINT AT_GAGE_SENSOR_CK1 CHECK (TRIM(SENSOR_ID) = SENSOR_ID);
ALTER TABLE AT_GAGE_SENSOR ADD CONSTRAINT AT_GAGE_SENSOR_CK2 CHECK (OUT_OF_SERVICE ='T' OR OUT_OF_SERVICE = 'F');
ALTER TABLE AT_GAGE_SENSOR ADD CONSTRAINT AT_GAGE_SENSOR_FK1 FOREIGN KEY (GAGE_CODE) REFERENCES AT_GAGE (GAGE_CODE);
ALTER TABLE AT_GAGE_SENSOR ADD CONSTRAINT AT_GAGE_SENSOR_FK2 FOREIGN KEY (PARAMETER_CODE) REFERENCES AT_PARAMETER (PARAMETER_CODE);
ALTER TABLE AT_GAGE_SENSOR ADD CONSTRAINT AT_GAGE_SENSOR_FK3 FOREIGN KEY (UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);

CREATE UNIQUE INDEX AT_GAGE_SENSOR_IDX1 ON AT_GAGE_SENSOR (UPPER(SENSOR_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
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

CREATE TABLE AT_GOES
(
   GAGE_CODE                NUMBER(10)  NOT NULL,
   GOES_SATELLITE           VARCHAR2(1) NOT NULL,
   SELFTIMED_CHANNEL        NUMBER(4),
   SELFTIMED_DATA_RATE      NUMBER(6),
   SELFTIMED_INTERVAL       INTERVAL DAY TO SECOND,
   SELFTIMED_OFFSET         INTERVAL DAY TO SECOND,
   SELFTIMED_LENGTH         INTERVAL DAY TO SECOND,   
   RANDOM_CHANNEL           NUMBER(4),
   RANDOM_DATA_RATE         NUMBER(6),
   RANDOM_INTERVAL          INTERVAL DAY TO SECOND,
   RANDOM_OFFSET            INTERVAL DAY TO SECOND,
   CONSTRAINT AT_GOES_PK  PRIMARY KEY (GAGE_CODE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_GOES                          IS 'Contains information about GOES transmissions from location.';
COMMENT ON COLUMN AT_GOES.GAGE_CODE                IS 'References gage.';
COMMENT ON COLUMN AT_GOES.GOES_SATELLITE           IS 'GOES-EAST (E) or GOES-WEST (W).';
COMMENT ON COLUMN AT_GOES.SELFTIMED_CHANNEL        IS 'GOES channel for self-timed transmissions.';
COMMENT ON COLUMN AT_GOES.SELFTIMED_DATA_RATE      IS 'Date rate in bits/second for self-timed transmissions.';
COMMENT ON COLUMN AT_GOES.SELFTIMED_INTERVAL       IS 'Recurrence interval for self-timed transmissions.';
COMMENT ON COLUMN AT_GOES.SELFTIMED_OFFSET         IS 'Offset into recurrence interval for self-timed transmissions.';
COMMENT ON COLUMN AT_GOES.SELFTIMED_LENGTH         IS 'Length of self-timed transmission window.';
COMMENT ON COLUMN AT_GOES.RANDOM_CHANNEL           IS 'GOES channel for random (triggered) transmissions.';
COMMENT ON COLUMN AT_GOES.RANDOM_DATA_RATE         IS 'Date rate in bits/second for random (triggered) transmissions.';
COMMENT ON COLUMN AT_GOES.RANDOM_INTERVAL          IS 'Recurrence interval of programmed random transmissions.';
COMMENT ON COLUMN AT_GOES.RANDOM_OFFSET            IS 'Offset into recurrence interval for programmed random transmissions.';

ALTER TABLE AT_GOES ADD CONSTRAINT AT_GOES_CK1 CHECK (GOES_SATELLITE = 'E' OR GOES_SATELLITE = 'W');
ALTER TABLE AT_GOES ADD CONSTRAINT AT_GOES_FK1 FOREIGN KEY (GAGE_CODE) REFERENCES AT_GAGE (GAGE_CODE); 

CREATE TABLE AT_DISPLAY_SCALE
(
   LOCATION_CODE  NUMBER(10) NOT NULL,
   PARAMETER_CODE NUMBER(10) NOT NULL,
   UNIT_CODE      NUMBER(10) NOT NULL,
   SCALE_MAX      NUMBER,
   SCALE_MIN      NUMBER,
   CONSTRAINT AT_DISPLAY_SCALE_PK  PRIMARY KEY (LOCATION_CODE, PARAMETER_CODE, UNIT_CODE) USING INDEX
)   
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_DISPLAY_SCALE                IS 'Contains display information for values at a location.';
COMMENT ON COLUMN AT_DISPLAY_SCALE.LOCATION_CODE  IS 'References a location.';
COMMENT ON COLUMN AT_DISPLAY_SCALE.PARAMETER_CODE IS 'References parameter.';
COMMENT ON COLUMN AT_DISPLAY_SCALE.UNIT_CODE      IS 'References unit for scale values.';

ALTER TABLE AT_DISPLAY_SCALE ADD CONSTRAINT AT_DISPLAY_SCALE_FK1 FOREIGN KEY (LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);
ALTER TABLE AT_DISPLAY_SCALE ADD CONSTRAINT AT_DISPLAY_SCALE_FK2 FOREIGN KEY (PARAMETER_CODE) REFERENCES AT_PARAMETER (PARAMETER_CODE);
ALTER TABLE AT_DISPLAY_SCALE ADD CONSTRAINT AT_DISPLAY_SCALE_FK3 FOREIGN KEY (UNIT_CODE) REFERENCES CWMS_UNIT (UNIT_CODE);

---------------
------------------

CREATE TABLE at_loc_category
(
  loc_category_code  NUMBER,
  loc_category_id    VARCHAR2(32 BYTE)          NOT NULL,
  db_office_code     NUMBER                     NOT NULL,
  loc_category_desc  VARCHAR2(256 BYTE)
)
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE AT_LOC_CATEGORY ADD CONSTRAINT AT_LOC_CATEGORY_FK1 FOREIGN KEY (DB_OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);

INSERT INTO at_loc_category VALUES (0, 'Default',        53, 'Default');
INSERT INTO at_loc_category VALUES (1, 'Agency Aliases', 53, 'Location aliases for other agencies'); 
-- INSERT INTO at_loc_category VALUES (2, 'Basin',          53, 'Category for basin location groups');
-- INSERT INTO at_loc_category VALUES (3, 'Outlet',         53, 'Category for outlet location groups');
-- INSERT INTO at_loc_category VALUES (4, 'Turbine',        53, 'Category for turbine location groups');


--------
--------

CREATE TABLE at_loc_group
(
  loc_group_code      NUMBER,
  loc_category_code   NUMBER                     NOT NULL,
  loc_group_id        VARCHAR2(65 BYTE)          NOT NULL,
  loc_group_desc      VARCHAR2(256 BYTE),
  db_office_code      NUMBER                     NOT NULL,
  shared_loc_alias_id VARCHAR2(256 BYTE),
  shared_loc_ref_code NUMBER
)
TABLESPACE CWMS_20AT_DATA
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
comment on table  at_loc_group                     is 'Specifies a location group within a location group category';
comment on column at_loc_group.loc_group_code      is 'Primary key uniquely identifying this group';
comment on column at_loc_group.loc_category_code   is 'Reference to location group category to which this group belongs';
comment on column at_loc_group.loc_group_id        is 'Name of this location group';
comment on column at_loc_group.loc_group_desc      is 'Description of the purpose of this location group';
comment on column at_loc_group.db_office_code      is 'Reference to office that owns this location group';
comment on column at_loc_group.shared_loc_alias_id is 'Shared location alias assigned to all members of this group by virtue of membership';
comment on column at_loc_group.shared_loc_ref_code is 'Shared reference to existing location assigned to all members of this group by virtue of memebership';

CREATE UNIQUE INDEX at_loc_groups_pk ON at_loc_group
(loc_group_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
  CONSTRAINT at_loc_groups_fk3
 FOREIGN KEY (shared_loc_ref_code)
 REFERENCES at_physical_location (location_code))
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
INSERT INTO at_loc_group VALUES (0, 0, 'Default',             'All Locations',                                            53, NULL, NULL);
INSERT INTO at_loc_group VALUES (1, 1, 'USGS Station Name',   'US Geological Survey Station Name',                        53, NULL, NULL);
INSERT INTO at_loc_group VALUES (2, 1, 'USGS Station Number', 'US Geological Survey Station Number',                      53, NULL, NULL);
INSERT INTO at_loc_group VALUES (3, 1, 'NWS Handbook 5 ID',   'National Weather Service Handbook 5 ID',                   53, NULL, NULL);
INSERT INTO at_loc_group VALUES (4, 1, 'DCP Platform ID',     'Data Collection Platform ID',                              53, NULL, NULL);
INSERT INTO at_loc_group VALUES (5, 1, 'SHEF Location ID',    'Standard Hydrometeorological Exchange Format Location ID', 53, NULL, NULL);
INSERT INTO at_loc_group VALUES (6, 1, 'CBT Station ID',      'Columbia Basin Teletype Station ID',                       53, NULL, NULL);
INSERT INTO at_loc_group VALUES (7, 1, 'USBR Station ID',     'US Bureau of Reclamation Station ID',                      53, NULL, NULL);
INSERT INTO at_loc_group VALUES (8, 1, 'TVA Station ID',      'Tennessee Valley Authority Station ID',                    53, NULL, NULL);
INSERT INTO at_loc_group VALUES (9, 1, 'NRCS Station ID',     'Natural Resources Conservation Service Station ID',        53, NULL, NULL);
COMMIT ;
-----

CREATE TABLE at_loc_group_assignment
(
  location_code   NUMBER,
  loc_group_code  NUMBER,
  loc_attribute   NUMBER,
  loc_alias_id    VARCHAR2(256 BYTE),
  loc_ref_code    NUMBER
)
TABLESPACE CWMS_20AT_DATA
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

comment on table  at_loc_group_assignment                is 'Assigns locations to location groups';
comment on column at_loc_group_assignment.location_code  is 'Reference to assigned location';
comment on column at_loc_group_assignment.loc_group_code is 'Reference to location group';
comment on column at_loc_group_assignment.loc_attribute  is 'General purpose value (can be used for sorting, etc...)';
comment on column at_loc_group_assignment.loc_alias_id   is 'Alias of location with respect to the assignment';
comment on column at_loc_group_assignment.loc_ref_code   is 'Reference to an existing location with respect to the assignment';

CREATE UNIQUE INDEX at_loc_group_assignment_pk ON at_loc_group_assignment
(location_code, loc_group_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
ALTER TABLE at_loc_group_assignment ADD (
  CONSTRAINT at_loc_group_assignment_fk3
 FOREIGN KEY (loc_ref_code)
 REFERENCES at_physical_location (location_code))
/

INSERT INTO at_loc_group_assignment
            (location_code, loc_group_code, loc_alias_id, loc_ref_code
            )
     VALUES (0, 0, NULL, NULL
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
  delete_date          TIMESTAMP(9),
  data_source          VARCHAR2(16 BYTE)
)
TABLESPACE CWMS_20_TSV
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


COMMENT ON TABLE at_cwms_ts_spec IS 'Defines time series based on CWMS requirements.  This table also serves as time series specification super type.';
COMMENT ON COLUMN at_cwms_ts_spec.description IS 'Additional information.';
COMMENT ON COLUMN at_cwms_ts_spec.version_flag IS 'Default is NULL, indicating versioning is off. If set to "Y" then versioning is on';
COMMENT ON COLUMN at_cwms_ts_spec.migrate_ver_flag IS 'Default is NULL, indicating versioned data is not migrated to historic tables.  If set to "Y", versioned data is archived.';
COMMENT ON COLUMN at_cwms_ts_spec.active_flag IS 'T or F';
COMMENT ON COLUMN at_cwms_ts_spec.delete_date IS 'Is the date that this ts_id was marked for deletion.';
COMMENT ON COLUMN at_cwms_ts_spec.ts_code IS 'Unique record identifier, primarily used for internal database processing. This code is automatically assigned by the system.';
COMMENT ON COLUMN at_cwms_ts_spec.location_code IS 'Primary key of AT_PHYSICAL_LOCATION table.';
COMMENT ON COLUMN at_cwms_ts_spec.parameter_code IS 'Primary key of AT_PARAMETER table.  Must already exist in the AT_PARAMETER table.';
COMMENT ON COLUMN at_cwms_ts_spec.parameter_type_code IS 'Primary key of CWMS_PARAMETER_TYPE table.  Must already exist in the CWMS_PARAMETER_TYPE table.';

CREATE UNIQUE INDEX at_cwms_ts_spec_ui ON at_cwms_ts_spec
(location_code, parameter_type_code, parameter_code, interval_code,
duration_code, UPPER("VERSION"), delete_date)
LOGGING
TABLESPACE CWMS_20_TSV
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
tablespace CWMS_20_TSV
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
    tablespace CWMS_20_TSV
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


CREATE TABLE AT_SPECIFIED_LEVEL
(
   SPECIFIED_LEVEL_CODE NUMBER(10)    NOT NULL,
   OFFICE_CODE          NUMBER(10)    NOT NULL,
   SPECIFIED_LEVEL_ID   VARCHAR2(256) NOT NULL,
   DESCRIPTION          VARCHAR2(256),
   CONSTRAINT AT_SPECIFIED_LEVEL_PK  PRIMARY KEY (SPECIFIED_LEVEL_CODE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             10K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_SPECIFIED_LEVEL                      IS 'Contains stream levels of interest.';
COMMENT ON COLUMN AT_SPECIFIED_LEVEL.SPECIFIED_LEVEL_CODE IS 'Primary key to relate stream levels to other entities.';
COMMENT ON COLUMN AT_SPECIFIED_LEVEL.OFFICE_CODE          IS 'Reference to office specifying this level.';
COMMENT ON COLUMN AT_SPECIFIED_LEVEL.SPECIFIED_LEVEL_ID   IS 'Name of level (i.e,. ''Flood'', ''Normal Pool'', ''Out of bank'', ''Max of record'').';
COMMENT ON COLUMN AT_SPECIFIED_LEVEL.DESCRIPTION          IS 'Optional description.';

ALTER TABLE AT_SPECIFIED_LEVEL ADD CONSTRAINT AT_SPECIFIED_LEVEL_CK1 CHECK (TRIM(SPECIFIED_LEVEL_ID) = SPECIFIED_LEVEL_ID);
ALTER TABLE AT_SPECIFIED_LEVEL ADD CONSTRAINT AT_SPECIFIED_LEVEL_FK1 FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);

CREATE UNIQUE INDEX AT_SPECIFIED_LEVEL_U1 ON AT_SPECIFIED_LEVEL (OFFICE_CODE, UPPER(SPECIFIED_LEVEL_ID))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

COMMIT;

INSERT INTO AT_SPECIFIED_LEVEL VALUES( 1, 53, 'Regulating',                        'Regulating Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 2, 53, 'Flood',                             'Flood Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 3, 53, 'Max Non-Damaging',                  'Maximum Without Causing Damage Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 4, 53, 'Top of Conservation',               'Top Conservation Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 5, 53, 'Top of Dam',                        'Top of Dam Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 6, 53, 'Top of Downstream',                 'Top of Downstream Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 7, 53, 'Top of Flood',                      'Top of Flood Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 8, 53, 'Top of Inactive',                   'Top of Inactive Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES( 9, 53, 'Top of Induced Surcharge',          'Top of Induced Surcharge Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(10, 53, 'Bottom of Normal',                  'Bottom of Normal Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(11, 53, 'Top of Normal',                     'Top of Normal Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(12, 53, 'Top of Overflow',                   'Top of Overflow Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(13, 53, 'Bottom of Operating',               'Bottom of Operating Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(14, 53, 'Bottom of Flood Control',           'Bottom of Flood Control Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(15, 53, 'Bottom of Exclusive Flood Control', 'Bottom of Exclusive Flood Control Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(16, 53, 'Top of Exclusive Flood Control',    'Top of Exclusive Flood Control Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(17, 53, 'Design Capacity',                   'Design Capacity Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(18, 53, 'Top of Operating',                  'Top of Operational Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(19, 53, 'Bottom of Power',                   'Bottom of Power Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(20, 53, 'Top of Power',                      'Top of Power Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(21, 53, 'Bottom of Multi-Purpose',           'Bottom of Multi-Purpose Level');
INSERT INTO AT_SPECIFIED_LEVEL VALUES(22, 53, 'Top of Multi-Purpose',              'Top of Multi-Purpose Level');

CREATE TABLE AT_LOCATION_LEVEL
(
   LOCATION_LEVEL_CODE           NUMBER(10) NOT NULL,
   LOCATION_CODE                 NUMBER(10) NOT NULL,
   SPECIFIED_LEVEL_CODE          NUMBER(10) NOT NULL,
   PARAMETER_CODE                NUMBER(10) NOT NULL,
   PARAMETER_TYPE_CODE           NUMBER(10) NOT NULL,
   DURATION_CODE                 NUMBER(10) NOT NULL,
   LOCATION_LEVEL_DATE           DATE NOT NULL,
   LOCATION_LEVEL_VALUE          NUMBER,
   LOCATION_LEVEL_COMMENT        VARCHAR2(256),
   ATTRIBUTE_VALUE               NUMBER,
   ATTRIBUTE_PARAMETER_CODE      NUMBER(10),
   ATTRIBUTE_PARAMETER_TYPE_CODE NUMBER(10),
   ATTRIBUTE_DURATION_CODE       NUMBER(10),
   ATTRIBUTE_COMMENT             VARCHAR2(256),
   INTERVAL_ORIGIN               DATE,
   CALENDAR_INTERVAL             INTERVAL YEAR(2) TO MONTH,
   TIME_INTERVAL                 INTERVAL DAY(3) TO SECOND(0),
   INTERPOLATE                   VARCHAR2(1) DEFAULT 'T',
   TS_CODE                       NUMBER(10),
   CONSTRAINT AT_LOCATION_LEVEL_PK  PRIMARY KEY (LOCATION_LEVEL_CODE) USING INDEX TABLESPACE CWMS_20AT_DATA
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_LOCATION_LEVEL                               IS 'Contains levels of interest at specific locations.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.LOCATION_LEVEL_CODE           IS 'Primary key that relates location levels to other entities.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.LOCATION_CODE                 IS 'References a location.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.SPECIFIED_LEVEL_CODE          IS 'References a specified level.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.PARAMETER_CODE                IS 'References the parameter for the level value.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.PARAMETER_TYPE_CODE           IS 'References parameter type.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.DURATION_CODE                 IS 'References duration.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.LOCATION_LEVEL_VALUE          IS 'Value of non-seasonal level.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.LOCATION_LEVEL_COMMENT        IS 'Optional comment/description of the level.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.LOCATION_LEVEL_DATE           IS 'Observed date or effective date depending on type of level';
COMMENT ON COLUMN AT_LOCATION_LEVEL.ATTRIBUTE_VALUE               IS 'Value of attribute that constrains applicability of this level.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.ATTRIBUTE_PARAMETER_CODE      IS 'References the parameter for the attribute value.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.ATTRIBUTE_PARAMETER_TYPE_CODE IS 'References parameter type for the attribute value.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.ATTRIBUTE_DURATION_CODE       IS 'References duration for the attribute value.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.ATTRIBUTE_COMMENT             IS 'Optional comment/description of the attribute.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.CALENDAR_INTERVAL             IS 'Interval period for seasonal levels if period is specified in years or months.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.TIME_INTERVAL                 IS 'Interval period for seasonal levels if period is specified in days.';
COMMENT ON COLUMN AT_LOCATION_LEVEL.INTERVAL_ORIGIN               IS 'Origin time in UTC for interval period - required if calendar interval is not null or time interval is not null';
COMMENT ON COLUMN AT_LOCATION_LEVEL.INTERPOLATE                   IS 'Values between offset are interpolated bewteen dates (T) or take the most recent value (F).';
COMMENT ON COLUMN AT_LOCATION_LEVEL.TS_CODE                       IS 'References a time series that serves as location level';


ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_CK1 CHECK (
   (LOCATION_LEVEL_VALUE IS NOT NULL AND CALENDAR_INTERVAL IS NULL AND TIME_INTERVAL IS NULL AND TS_CODE IS NULL) OR
   (LOCATION_LEVEL_VALUE IS NULL AND CALENDAR_INTERVAL IS NOT NULL AND TIME_INTERVAL IS NULL AND TS_CODE IS NULL) OR
   (LOCATION_LEVEL_VALUE IS NULL AND CALENDAR_INTERVAL IS NULL AND TIME_INTERVAL IS NOT NULL AND TS_CODE IS NULL) OR
   (LOCATION_LEVEL_VALUE IS NULL AND CALENDAR_INTERVAL IS NULL AND TIME_INTERVAL IS NULL AND TS_CODE IS NOT NULL)
);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_CK2 CHECK (NOT ((CALENDAR_INTERVAL IS NOT NULL OR TIME_INTERVAL IS NOT NULL) AND INTERVAL_ORIGIN IS NULL));
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_CK3 CHECK (INTERPOLATE IS NULL OR INTERPOLATE IN ('T', 'F'));
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_CK4 CHECK (NOT (LOCATION_LEVEL_VALUE IS NULL AND INTERPOLATE IS NULL));
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_CK5 CHECK (NOT (ATTRIBUTE_VALUE IS NOT NULL AND (ATTRIBUTE_PARAMETER_CODE IS NULL OR ATTRIBUTE_PARAMETER_TYPE_CODE IS NULL OR ATTRIBUTE_DURATION_CODE IS NULL)));
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK1 FOREIGN KEY (LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK2 FOREIGN KEY (SPECIFIED_LEVEL_CODE) REFERENCES AT_SPECIFIED_LEVEL (SPECIFIED_LEVEL_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK3 FOREIGN KEY (PARAMETER_CODE) REFERENCES AT_PARAMETER (PARAMETER_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK4 FOREIGN KEY (PARAMETER_TYPE_CODE) REFERENCES CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK5 FOREIGN KEY (DURATION_CODE) REFERENCES CWMS_DURATION (DURATION_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK6 FOREIGN KEY (ATTRIBUTE_PARAMETER_CODE) REFERENCES AT_PARAMETER (PARAMETER_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK7 FOREIGN KEY (ATTRIBUTE_PARAMETER_TYPE_CODE) REFERENCES CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK8 FOREIGN KEY (ATTRIBUTE_DURATION_CODE) REFERENCES CWMS_DURATION (DURATION_CODE);
ALTER TABLE AT_LOCATION_LEVEL ADD CONSTRAINT AT_LOCATION_LEVEL_FK9 FOREIGN KEY (TS_CODE) REFERENCES AT_CWMS_TS_SPEC (TS_CODE);

CREATE UNIQUE INDEX AT_LOCATION_LEVEL_U1 ON AT_LOCATION_LEVEL (
   LOCATION_CODE,
   SPECIFIED_LEVEL_CODE,
   PARAMETER_CODE,
   PARAMETER_TYPE_CODE,
   DURATION_CODE,
   LOCATION_LEVEL_DATE,
   NVL(ATTRIBUTE_PARAMETER_CODE, -1),
   NVL(ATTRIBUTE_PARAMETER_TYPE_CODE, -1),
   NVL(ATTRIBUTE_DURATION_CODE, -1),
   NVL(ATTRIBUTE_VALUE, -1))
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          10K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL
/

CREATE TABLE AT_SEASONAL_LOCATION_LEVEL
(
   LOCATION_LEVEL_CODE NUMBER(10) NOT NULL,
   CALENDAR_OFFSET     INTERVAL YEAR(2) TO MONTH,
   TIME_OFFSET         INTERVAL DAY(3) TO SECOND(0),
   VALUE               NUMBER     NOT NULL,
   CONSTRAINT AT_SEASONAL_LOCATION_LEVEL_PK  PRIMARY KEY (LOCATION_LEVEL_CODE, CALENDAR_OFFSET, TIME_OFFSET) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_SEASONAL_LOCATION_LEVEL                     IS 'Contains seasonal levels for specific locations.';
COMMENT ON COLUMN AT_SEASONAL_LOCATION_LEVEL.LOCATION_LEVEL_CODE IS 'References specified level at a specific location.';
COMMENT ON COLUMN AT_SEASONAL_LOCATION_LEVEL.CALENDAR_OFFSET     IS 'Months from beginning of period (added to minutes) to this offset.';
COMMENT ON COLUMN AT_SEASONAL_LOCATION_LEVEL.TIME_OFFSET         IS 'Mintues from beginning of period (added to months) to this offset.';
COMMENT ON COLUMN AT_SEASONAL_LOCATION_LEVEL.VALUE               IS 'Seasonal value at this offset in period.';

ALTER TABLE AT_SEASONAL_LOCATION_LEVEL ADD CONSTRAINT AT_SEASONAL_LOCATION_LEVEL_FK1 FOREIGN KEY (LOCATION_LEVEL_CODE) REFERENCES AT_LOCATION_LEVEL (LOCATION_LEVEL_CODE);
ALTER TABLE AT_SEASONAL_LOCATION_LEVEL ADD CONSTRAINT AT_SEASONAL_LOCATION_LEVEL_CK1 CHECK (NOT (CALENDAR_OFFSET IS NULL AND TIME_OFFSET IS NULL));

CREATE TABLE AT_LOC_LVL_INDICATOR
(
   LEVEL_INDICATOR_CODE          NUMBER(10) NOT NULL,
   LOCATION_CODE                 NUMBER(10) NOT NULL,
   SPECIFIED_LEVEL_CODE          NUMBER(10) NOT NULL,
   PARAMETER_CODE                NUMBER(10) NOT NULL,
   PARAMETER_TYPE_CODE           NUMBER(10) NOT NULL,
   DURATION_CODE                 NUMBER(10) NOT NULL,
   ATTR_VALUE                    NUMBER,
   ATTR_PARAMETER_CODE           NUMBER(10),
   ATTR_PARAMETER_TYPE_CODE      NUMBER(10),
   ATTR_DURATION_CODE            NUMBER(10),
   REF_SPECIFIED_LEVEL_CODE      NUMBER(10),
   REF_ATTR_VALUE                NUMBER,
   LEVEL_INDICATOR_ID            VARCHAR2(32) NOT NULL,
   MINIMUM_DURATION              INTERVAL DAY(3) TO SECOND(0),
   MAXIMUM_AGE                   INTERVAL DAY(3) TO SECOND(0),
   CONSTRAINT AT_LOC_LVL_INDICATOR_PK  PRIMARY KEY (LEVEL_INDICATOR_CODE) USING INDEX,
   CONSTRAINT AT_LOC_LVL_INDICATOR_U1  UNIQUE (
      LOCATION_CODE,
      SPECIFIED_LEVEL_CODE,
      PARAMETER_CODE,
      DURATION_CODE,
      LEVEL_INDICATOR_ID,
      ATTR_VALUE,
      ATTR_PARAMETER_CODE,
      REF_SPECIFIED_LEVEL_CODE,
      REF_ATTR_VALUE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_LOC_LVL_INDICATOR                          IS 'Specifies location level indicators.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.LEVEL_INDICATOR_CODE     IS 'Primary key that relates location level indicators to specific conditions.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.LOCATION_CODE            IS 'References location.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.SPECIFIED_LEVEL_CODE     IS 'References specified level.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.PARAMETER_CODE           IS 'References parameter.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.PARAMETER_TYPE_CODE      IS 'References parameter type.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.DURATION_CODE            IS 'References duration.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.ATTR_VALUE               IS 'Value of ATTR that constrains applicability of this level.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.ATTR_PARAMETER_CODE      IS 'References the parameter for the ATTR value.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.ATTR_PARAMETER_TYPE_CODE IS 'References parameter type for the ATTR value.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.ATTR_DURATION_CODE       IS 'References duration for the ATTR value.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.REF_SPECIFIED_LEVEL_CODE IS 'References specified level for ''reference'' level used for difference conditions.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.REF_ATTR_VALUE           IS 'ATTR value of ''reference'' level used for difference conditions.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.LEVEL_INDICATOR_ID       IS 'Text identifier of location level indicator.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.MINIMUM_DURATION         IS 'Optional minimum time a condition must be true for the indicator to be set.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR.MAXIMUM_AGE              IS 'Optional maximum age of most recent data for indicator to be set.';

ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK1 FOREIGN KEY (LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK2 FOREIGN KEY (SPECIFIED_LEVEL_CODE) REFERENCES AT_SPECIFIED_LEVEL (SPECIFIED_LEVEL_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK3 FOREIGN KEY (PARAMETER_CODE) REFERENCES AT_PARAMETER (PARAMETER_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK4 FOREIGN KEY (PARAMETER_TYPE_CODE) REFERENCES CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK5 FOREIGN KEY (DURATION_CODE) REFERENCES CWMS_DURATION (DURATION_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK6 FOREIGN KEY (ATTR_PARAMETER_CODE) REFERENCES AT_PARAMETER (PARAMETER_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK7 FOREIGN KEY (ATTR_PARAMETER_TYPE_CODE) REFERENCES CWMS_PARAMETER_TYPE (PARAMETER_TYPE_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK8 FOREIGN KEY (ATTR_DURATION_CODE) REFERENCES CWMS_DURATION (DURATION_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_FK9 FOREIGN KEY (REF_SPECIFIED_LEVEL_CODE) REFERENCES AT_SPECIFIED_LEVEL (SPECIFIED_LEVEL_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_CK1 CHECK (TRIM(UPPER(LEVEL_INDICATOR_ID)) = LEVEL_INDICATOR_ID);
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_CK2 CHECK (NVL(MINIMUM_DURATION, TO_DSINTERVAL('0 0:0:0')) >= TO_DSINTERVAL('0 0:0:0'));
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_CK3 CHECK (NVL(MAXIMUM_AGE, TO_DSINTERVAL('0 0:0:0')) >= TO_DSINTERVAL('0 0:0:0'));
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_CK5 CHECK (
   (ATTR_VALUE IS NULL AND ATTR_PARAMETER_CODE IS NULL AND ATTR_PARAMETER_TYPE_CODE IS NULL AND ATTR_DURATION_CODE IS NULL)
   OR
   (ATTR_VALUE IS NOT NULL AND ATTR_PARAMETER_CODE IS NOT NULL AND ATTR_PARAMETER_TYPE_CODE IS NOT NULL AND ATTR_DURATION_CODE IS NOT NULL));
ALTER TABLE AT_LOC_LVL_INDICATOR ADD CONSTRAINT AT_LOC_LVL_INDICATOR_CK6 CHECK (
   (REF_ATTR_VALUE IS NULL)
   OR
   (REF_ATTR_VALUE IS NOT NULL AND REF_SPECIFIED_LEVEL_CODE IS NOT NULL));

CREATE TABLE AT_LOC_LVL_INDICATOR_COND
(
   LEVEL_INDICATOR_CODE       NUMBER(10)                   NOT NULL,
   LEVEL_INDICATOR_VALUE      NUMBER(1)                    NOT NULL,
   EXPRESSION                 VARCHAR(64)                  NOT NULL,
   COMPARISON_OPERATOR_1      VARCHAR2(2)                  NOT NULL,
   COMPARISON_VALUE_1         BINARY_DOUBLE                NOT NULL,
   COMPARISON_UNIT            NUMBER(10)                   DEFAULT NULL,
   CONNECTOR                  VARCHAR2(3)                  DEFAULT NULL,
   COMPARISON_OPERATOR_2      VARCHAR2(2)                  DEFAULT NULL,
   COMPARISON_VALUE_2         BINARY_DOUBLE                DEFAULT NULL,
   RATE_EXPRESSION            VARCHAR(64)                  DEFAULT NULL,
   RATE_COMPARISON_OPERATOR_1 VARCHAR2(2)                  DEFAULT NULL,
   RATE_COMPARISON_VALUE_1    BINARY_DOUBLE                DEFAULT NULL,
   RATE_COMPARISON_UNIT       NUMBER(10)                   DEFAULT NULL,
   RATE_CONNECTOR             VARCHAR2(3)                  DEFAULT NULL,
   RATE_COMPARISON_OPERATOR_2 VARCHAR2(2)                  DEFAULT NULL,
   RATE_COMPARISON_VALUE_2    BINARY_DOUBLE                DEFAULT NULL,
   RATE_INTERVAL              INTERVAL DAY(3) TO SECOND(0) DEFAULT NULL,
   DESCRIPTION                VARCHAR2(256)                DEFAULT NULL,
   CONSTRAINT AT_LOC_LVL_INDICATOR_COND_PK  PRIMARY KEY (LEVEL_INDICATOR_CODE, LEVEL_INDICATOR_VALUE) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_LOC_LVL_INDICATOR_COND                            IS 'Specifies conditions for specific location level indicators.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.LEVEL_INDICATOR_CODE       IS 'References location level indicator for this condition.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.LEVEL_INDICATOR_VALUE      IS 'Indicator value (1-5) if this condition is met.';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.EXPRESSION                 IS 'Algebraic or RPN expression using variables V (value), L (level value), L2 (reference level value)';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.COMPARISON_OPERATOR_1      IS 'Operator (''LT'', ''LE'', ''EQ'', ''NE'', ''GE'', ''GT'') used to compare result of EXPRESSION with COMPARISON_VALUE_1';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.COMPARISON_VALUE_1         IS 'Value to compare with result of EXPRESSION with COMPARISON_OPERATOR_1';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.COMPARISON_UNIT            IS 'Unit used for comparisons';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.CONNECTOR                  IS 'Operator (''AND'', ''OR'') used to connect comparisons';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.COMPARISON_OPERATOR_2      IS 'Operator (''LT'', ''LE'', ''EQ'', ''NE'', ''GE'', ''GT'') used to compare result of EXPRESSION with COMPARISON_VALUE_2';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.COMPARISON_VALUE_2         IS 'Value to compare with result of EXPRESSION with COMPARISON_OPERATOR_2';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_EXPRESSION            IS 'Algebraic or RPN expression using variable R (rate of change)';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_COMPARISON_OPERATOR_1 IS 'Operator (''LT'', ''LE'', ''EQ'', ''NE'', ''GE'', ''GT'') used to compare result of RATE_EXPRESSION with RATE_COMPARISON_VALUE_1';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_COMPARISON_VALUE_1    IS 'Value to compare with result of RATE_EXPRESSION with RATE_COMPARISON_OPERATOR_1';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_COMPARISON_UNIT       IS 'Unit used for rate comparisons';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_CONNECTOR             IS 'Operator (''AND'', ''OR'') used to connect rate comparisons';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_COMPARISON_OPERATOR_2 IS 'Operator (''LT'', ''LE'', ''EQ'', ''NE'', ''GE'', ''GT'') used to compare result RATE_of EXPRESSION with RATE_COMPARISON_VALUE_2';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_COMPARISON_VALUE_2    IS 'Value to compare with result of RATE_EXPRESSION with RATE_COMPARISON_OPERATOR_2';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.RATE_INTERVAL              IS 'Interval used for rate comparisons';
COMMENT ON COLUMN AT_LOC_LVL_INDICATOR_COND.DESCRIPTION                IS 'Text description of indicator level condition';

ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_FK1 FOREIGN KEY (LEVEL_INDICATOR_CODE) REFERENCES AT_LOC_LVL_INDICATOR (LEVEL_INDICATOR_CODE);
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK1 CHECK (LEVEL_INDICATOR_VALUE IN (1, 2, 3, 4, 5));
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK2 CHECK (COMPARISON_OPERATOR_1 IN ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT'));
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK3 CHECK (NVL(CONNECTOR, 'AND') IN ('AND', 'OR'));
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK4 CHECK (NVL(COMPARISON_OPERATOR_2, 'EQ') IN ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT'));
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK5 CHECK (NVL(RATE_COMPARISON_OPERATOR_1, 'EQ') IN ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT'));
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK6 CHECK (NVL(RATE_CONNECTOR, 'AND') IN ('AND', 'OR'));
ALTER TABLE AT_LOC_LVL_INDICATOR_COND ADD CONSTRAINT AT_LOC_LVL_INDICATOR_COND_CK7 CHECK (NVL(RATE_COMPARISON_OPERATOR_2, 'EQ') IN ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT'));

CREATE GLOBAL TEMPORARY TABLE AT_LOC_LVL_INDICATOR_TAB
(
   SEQ                    INTEGER,
   OFFICE_ID              VARCHAR2(16),
   LOCATION_ID            VARCHAR2(49),
   PARAMETER_ID           VARCHAR2(49),
   PARAMETER_TYPE_ID      VARCHAR2(16),
   DURATION_ID            VARCHAR2(16),
   SPECIFIED_LEVEL_ID     VARCHAR2(265),
   LEVEL_INDICATOR_ID     VARCHAR2(32),
   LEVEL_UNITS_ID         VARCHAR2(16),
   ATTR_PARAMETER_ID      VARCHAR2(49),
   ATTR_PARAMETER_TYPE_ID VARCHAR2(16),
   ATTR_DURATION_ID       VARCHAR2(16),
   ATTR_UNITS_ID          VARCHAR2(16),
   ATTR_VALUE             NUMBER,
   MINIMUM_DURATION       INTERVAL DAY(3) TO SECOND(0),
   MAXIMUM_AGE            INTERVAL DAY(3) TO SECOND(0),
   RATE_OF_CHANGE         VARCHAR2(1),
   REF_SPECIFIED_LEVEL_ID VARCHAR2(256),
   REF_ATTRIBUTE_VALUE    NUMBER,
   CONDITIONS             VARCHAR2(4000)
)
ON COMMIT DELETE ROWS
/

COMMENT ON TABLE  AT_LOC_LVL_INDICATOR_TAB IS 'Used by CWMS_LEVEL.CAT_LOC_LVL_INDICATOR2';

ALTER TABLE AT_LOC_LVL_INDICATOR_TAB ADD CONSTRAINT AT_LOC_LVL_INDICATOR_TAB_PK PRIMARY KEY (SEQ) USING INDEX;

------------------------
-- TIME SERIES GROUPS --
------------------------
CREATE TABLE at_ts_category
(
  ts_category_code  NUMBER,
  ts_category_id    VARCHAR2(32 BYTE)          NOT NULL,
  db_office_code    NUMBER                     NOT NULL,
  ts_category_desc  VARCHAR2(256 BYTE)
)
TABLESPACE CWMS_20AT_DATA
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

CREATE UNIQUE INDEX at_ts_category_name_pk ON at_ts_category
(ts_category_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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

CREATE UNIQUE INDEX at_ts_category_name_u1 ON at_ts_category
(UPPER("TS_CATEGORY_ID"), db_office_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE at_ts_category ADD (
  CONSTRAINT at_ts_category_name_pk
 PRIMARY KEY
 (ts_category_code)
    USING INDEX
    TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE AT_TS_CATEGORY ADD CONSTRAINT AT_TS_CATEGORY_FK1 FOREIGN KEY (DB_OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);

INSERT INTO at_ts_category VALUES (0, 'Default',        53, 'Default');
INSERT INTO at_ts_category VALUES (1, 'Agency Aliases', 53, 'Time series aliases for various agencies'); 

--------
--------

CREATE TABLE at_ts_group
(
  ts_group_code      NUMBER,
  ts_category_code   NUMBER                     NOT NULL,
  ts_group_id        VARCHAR2(65 BYTE)          NOT NULL,
  ts_group_desc      VARCHAR2(256 BYTE),
  db_office_code     NUMBER                     NOT NULL,
  shared_ts_alias_id VARCHAR2(256 BYTE),
  shared_ts_ref_code NUMBER
)
TABLESPACE CWMS_20AT_DATA
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
comment on table  at_ts_group                    is 'Specifies a ts group within a ts group category';
comment on column at_ts_group.ts_group_code      is 'Primary key uniquely identifying this group';
comment on column at_ts_group.ts_category_code   is 'Reference to ts group category to which this group belongs';
comment on column at_ts_group.ts_group_id        is 'Name of this ts group';
comment on column at_ts_group.ts_group_desc      is 'Description of the purpose of this ts group';
comment on column at_ts_group.db_office_code     is 'Reference to office that owns this ts group';
comment on column at_ts_group.shared_ts_alias_id is 'Shared ts alias assigned to all members of this group by virtue of membership';
comment on column at_ts_group.shared_ts_ref_code is 'Shared reference to existing ts assigned to all members of this group by virtue of memebership';

CREATE UNIQUE INDEX at_ts_groups_pk ON at_ts_group
(ts_group_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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

CREATE UNIQUE INDEX at_ts_groups_u1 ON at_ts_group
(ts_category_code, UPPER("TS_GROUP_ID"))
LOGGING
TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE at_ts_group ADD (
  CONSTRAINT at_ts_groups_pk
 PRIMARY KEY
 (ts_group_code)
    USING INDEX
    TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE at_ts_group ADD (
  CONSTRAINT at_ts_groups_fk3
 FOREIGN KEY (shared_ts_ref_code)
 REFERENCES at_cwms_ts_spec (ts_code))
/
ALTER TABLE at_ts_group ADD (
  CONSTRAINT at_ts_groups_fk2
 FOREIGN KEY (db_office_code)
 REFERENCES cwms_office (office_code))
/
ALTER TABLE at_ts_group ADD (
  CONSTRAINT at_ts_groups_fk1
 FOREIGN KEY (ts_category_code)
 REFERENCES at_ts_category (ts_category_code))
/
INSERT INTO at_ts_group VALUES (0, 0, 'Default',        'All Time Series',                           53, NULL, NULL);
INSERT INTO at_ts_group VALUES (1, 1, 'USACE Standard', 'USACE National Standard Naming Convention', 53, NULL, NULL);
COMMIT ;
-----

CREATE TABLE at_ts_group_assignment
(
  ts_code        NUMBER,
  ts_group_code  NUMBER,
  ts_attribute   NUMBER,
  ts_alias_id    VARCHAR2(256 BYTE),
  ts_ref_code    NUMBER
)
TABLESPACE CWMS_20AT_DATA
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

comment on table  at_ts_group_assignment               is 'Assigns time series to ts groups';
comment on column at_ts_group_assignment.ts_code       is 'Reference to assigned ts';
comment on column at_ts_group_assignment.ts_group_code is 'Reference to ts group';
comment on column at_ts_group_assignment.ts_attribute  is 'General purpose value (can be used for sorting, etc...)';
comment on column at_ts_group_assignment.ts_alias_id   is 'Alias of ts with respect to the assignment';
comment on column at_ts_group_assignment.ts_ref_code   is 'Reference to an existing ts with respect to the assignment';

CREATE UNIQUE INDEX at_ts_group_assignment_pk ON at_ts_group_assignment
(ts_code, ts_group_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE at_ts_group_assignment ADD (
  CONSTRAINT at_ts_group_assignment_pk
 PRIMARY KEY
 (ts_code, ts_group_code)
    USING INDEX
    TABLESPACE CWMS_20AT_DATA
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

ALTER TABLE at_ts_group_assignment ADD (
  CONSTRAINT at_ts_group_assignment_fk1
 FOREIGN KEY (ts_code)
 REFERENCES at_cwms_ts_spec (ts_code))
/
ALTER TABLE at_ts_group_assignment ADD (
  CONSTRAINT at_ts_group_assignment_fk2
 FOREIGN KEY (ts_group_code)
 REFERENCES at_ts_group (ts_group_code))
/
ALTER TABLE at_ts_group_assignment ADD (
  CONSTRAINT at_ts_group_assignment_fk3
 FOREIGN KEY (ts_ref_code)
 REFERENCES at_cwms_ts_spec (ts_code))
/
COMMIT ;

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
TABLESPACE CWMS_20AT_DATA
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

COMMENT ON COLUMN at_screening.active_flag IS 'T of F';

CREATE UNIQUE INDEX at_screening_pk ON at_screening
(ts_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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

COMMENT ON COLUMN at_alarm.active_flag IS 'T or F';

CREATE UNIQUE INDEX at_alarm_pk ON at_alarm
(ts_code)
LOGGING
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
MONITORING
/

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
TABLESPACE CWMS_20AT_DATA
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

-----------------------------
-- AT_UNIT_ALIAS TABLE constraints
--
ALTER TABLE at_unit_alias ADD CONSTRAINT at_unit_alias_r02 FOREIGN KEY (db_office_code) REFERENCES cwms_office (office_code);
ALTER TABLE at_unit_alias ADD CONSTRAINT fk_at_unit_alias  FOREIGN KEY (unit_code) REFERENCES cwms_unit (unit_code);
ALTER TABLE at_unit_alias ADD CONSTRAINT at_unit_alias_pk  PRIMARY KEY (alias_id, db_office_code)
    USING INDEX
    TABLESPACE CWMS_20AT_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64 k
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               )
/

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
TABLESPACE CWMS_20AT_DATA
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
TABLESPACE CWMS_20AT_DATA
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
    TABLESPACE CWMS_20AT_DATA
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
tablespace CWMS_20AT_DATA
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

ALTER TABLE at_office_settings ADD (
  CONSTRAINT at_office_settings_pk
 PRIMARY KEY
 (db_office_code)
    USING INDEX
    tablespace CWMS_20AT_DATA
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
        prop_comment   VARCHAR2(256),
        CONSTRAINT at_properties_pk PRIMARY KEY(office_code, prop_category, prop_id)
    )
   TABLESPACE CWMS_20AT_DATA
    LOGGING
    NOCOMPRESS
    NOCACHE
    NOPARALLEL
    NOMONITORING
/

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

---------------------------------
-- AT_PROPERTIES indices.
-- 
CREATE UNIQUE INDEX at_properties_uk1 ON at_properties(office_code, UPPER("PROP_CATEGORY"), UPPER("PROP_ID")) TABLESPACE CWMS_20AT_DATA;

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

INSERT INTO at_properties values(
   (SELECT office_code FROM cwms_office WHERE office_id = 'CWMS'),
   'CWMSDB',
   'ts_deleted.table.max_entries',
   '1000000',
   'Max number of rows to keep when trimming AT_TS_DELETED_TIMES.');
   
INSERT INTO at_properties values(
   (SELECT office_code FROM cwms_office WHERE office_id = 'CWMS'),
   'CWMSDB',
   'ts_deleted.entry.max_age',
   '5',
   'Max entry age in days to keep when trimming AT_TS_DELETED_TIMES.');
   
INSERT INTO at_properties values(
   (SELECT office_code FROM cwms_office WHERE office_id = 'CWMS'),
   'CWMSDB',
   'ts_deleted.auto_trim.interval',
   '15',
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
TABLESPACE CWMS_20AT_DATA
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
MONITORING
/

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
  TABLESPACE CWMS_20AT_DATA
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
)
/

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
  CLOB_CODE    NUMBER(10) NOT NULL,
  OFFICE_CODE  NUMBER(10) NOT NULL,
  ID           VARCHAR2(256 BYTE) NOT NULL,
  description  VARCHAR2(256 BYTE),
  VALUE        CLOB,
  CONSTRAINT AT_CLOB_PK  PRIMARY KEY (clob_code) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
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
  TABLESPACE  CWMS_20AT_DATA
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
MONITORING
/

-----------------------------
-- AT_CLOB comments
--
COMMENT ON TABLE  at_clob             IS 'Character Large OBject Storage for CWMS';
COMMENT ON COLUMN at_clob.CLOB_CODE   IS 'Unique reference code for this CLOB';
COMMENT ON COLUMN at_clob.OFFICE_CODE IS 'Reference to CWMS office';
COMMENT ON COLUMN at_clob.ID          IS 'Unique record identifier, using hierarchical /dir/subdir/.../file syntax';
COMMENT ON COLUMN at_clob.description IS 'Description of this CLOB';
COMMENT ON COLUMN at_clob.VALUE       IS 'The CLOB data';

-----------------------------
-- AT_CLOB indices
--
create unique index at_clob_idx1 on at_clob (office_code, upper(id)) tablespace cwms_20at_data;

-----------------------------
-- AT_CLOB constraints
--
ALTER TABLE AT_CLOB ADD CONSTRAINT AT_CLOB_FK1 FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);

SET define off
-----------------------------
-- AT_CLOB default data
--
INSERT INTO at_clob
     VALUES (1,
             (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'),
             '/XSLT/IDENTITY',
             'Transforms the input to an identical copy of itself',
             '<!-- The Identity Transformation -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Whenevery you match any node or any attribute -->
  <xsl:template match="node()|@*">
    <!-- Copy the current node -->
    <xsl:copy>
      <!-- Including and attributes it has and any child nodes -->
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
'           );

INSERT INTO at_clob
     VALUES (2,
             (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'),
             '/XSLT/CAT_TS_XML/TABBED_TEXT',
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
     VALUES (3,
             (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'),
             '/XSLT/CAT_TS_XML/HTML',
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
'           );

COMMIT ;


CREATE TABLE AT_FORECAST_SPEC
(
   FORECAST_SPEC_CODE   NUMBER(10)   NOT NULL,
   TARGET_LOCATION_CODE NUMBER(10)   NOT NULL,
   FORECAST_ID          VARCHAR2(32) NOT NULL,   
   SOURCE_AGENCY        VARCHAR2(16) NOT NULL,
   SOURCE_OFFICE        VARCHAR2(16) NOT NULL,
   FORECAST_TYPE        VARCHAR2(5),
   SOURCE_LOCATION_CODE NUMBER(10),
   MAX_AGE              NUMBER(4),
   CONSTRAINT AT_FORECAST_SPEC_PK  PRIMARY KEY (FORECAST_SPEC_CODE) USING INDEX,
   CONSTRAINT AT_FORECAST_SPEC_U1  UNIQUE (TARGET_LOCATION_CODE, FORECAST_ID)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          24K
            NEXT             24K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

COMMENT ON TABLE  AT_FORECAST_SPEC                      IS 'Contains forecast specifications.';
COMMENT ON COLUMN AT_FORECAST_SPEC.FORECAST_SPEC_CODE   IS 'Synthetic key.';
COMMENT ON COLUMN AT_FORECAST_SPEC.TARGET_LOCATION_CODE IS 'References location that the forecast is for.';
COMMENT ON COLUMN AT_FORECAST_SPEC.FORECAST_ID          IS 'Forecast identifier, unique for a given location';
COMMENT ON COLUMN AT_FORECAST_SPEC.SOURCE_AGENCY        IS 'Agency that generates forecasts for this location (USACE or NWS).';
COMMENT ON COLUMN AT_FORECAST_SPEC.SOURCE_OFFICE        IS 'Office that generates forecasts for this location (i.e., NCRFC or MVR).';
COMMENT ON COLUMN AT_FORECAST_SPEC.FORECAST_TYPE        IS 'Type of forecast used at this location (i.e., RVS, RFD, etc...).';
COMMENT ON COLUMN AT_FORECAST_SPEC.SOURCE_LOCATION_CODE IS 'References location that is the source of forecats for this location.';
COMMENT ON COLUMN AT_FORECAST_SPEC.MAX_AGE              IS 'Age of existing forecast in hours before a new forecast is considered missing.';

ALTER TABLE AT_FORECAST_SPEC ADD CONSTRAINT AT_FORECAST_SPEC_CK1 CHECK (UPPER(TRIM(FORECAST_ID)) = FORECAST_ID);
ALTER TABLE AT_FORECAST_SPEC ADD CONSTRAINT AT_FORECAST_SPEC_CK2 CHECK (SOURCE_AGENCY = 'USACE' OR SOURCE_AGENCY = 'NWS');
ALTER TABLE AT_FORECAST_SPEC ADD CONSTRAINT AT_FORECAST_SPEC_CK3 CHECK (UPPER(TRIM(SOURCE_OFFICE)) = SOURCE_OFFICE);
ALTER TABLE AT_FORECAST_SPEC ADD CONSTRAINT AT_FORECAST_SPEC_CK4 CHECK (UPPER(TRIM(FORECAST_TYPE)) = FORECAST_TYPE);
ALTER TABLE AT_FORECAST_SPEC ADD CONSTRAINT AT_FORECAST_SPEC_FK1 FOREIGN KEY (TARGET_LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);  
ALTER TABLE AT_FORECAST_SPEC ADD CONSTRAINT AT_FORECAST_SPEC_FK2 FOREIGN KEY (SOURCE_LOCATION_CODE) REFERENCES AT_PHYSICAL_LOCATION (LOCATION_CODE);

CREATE TABLE AT_FORECAST_TS
(
   FORECAST_SPEC_CODE NUMBER(10) NOT NULL,
   TS_CODE            NUMBER(10) NOT NULL,
   FORECAST_DATE      DATE NOT NULL,
   ISSUE_DATE         DATE NOT NULL,
   VERSION_DATE       DATE NOT NULL,
   CONSTRAINT AT_FORECAST_TS_PK  PRIMARY KEY (FORECAST_SPEC_CODE, TS_CODE, FORECAST_DATE, ISSUE_DATE)
)
TABLESPACE CWMS_20AT_DATA
/

COMMENT ON TABLE  AT_FORECAST_TS                    IS 'Contains cross references between forecasts and time sereies';
COMMENT ON COLUMN AT_FORECAST_TS.FORECAST_SPEC_CODE IS 'References forecst specification';
COMMENT ON COLUMN AT_FORECAST_TS.TS_CODE            IS 'References time series';
COMMENT ON COLUMN AT_FORECAST_TS.FORECAST_DATE      IS 'Target date/time of the forecast';
COMMENT ON COLUMN AT_FORECAST_TS.ISSUE_DATE         IS 'Date/time the forecast was issued';
COMMENT ON COLUMN AT_FORECAST_TS.VERSION_DATE       IS 'Version date/time of the time series';

ALTER TABLE AT_FORECAST_TS ADD CONSTRAINT AT_FORECAST_TS_FK1 FOREIGN KEY (FORECAST_SPEC_CODE) REFERENCES AT_FORECAST_SPEC (FORECAST_SPEC_CODE);
ALTER TABLE AT_FORECAST_TS ADD CONSTRAINT AT_FORECAST_TS_FK2 FOREIGN KEY (TS_CODE) REFERENCES AT_CWMS_TS_SPEC (TS_CODE);

CREATE TABLE AT_FORECAST_TEXT
(
   FORECAST_SPEC_CODE NUMBER(10) NOT NULL,
   FORECAST_DATE      DATE NOT NULL,
   ISSUE_DATE         DATE NOT NULL,
   CLOB_CODE          NUMBER(10) NOT NULL,
   CONSTRAINT AT_FORECAST_TEXT_PK  PRIMARY KEY (FORECAST_SPEC_CODE, FORECAST_DATE, ISSUE_DATE)
)
TABLESPACE CWMS_20AT_DATA
/

COMMENT ON TABLE  AT_FORECAST_TEXT                    IS 'Contains cross references between forecasts and time sereies';
COMMENT ON COLUMN AT_FORECAST_TEXT.FORECAST_SPEC_CODE IS 'References forecst specification';
COMMENT ON COLUMN AT_FORECAST_TEXT.FORECAST_DATE      IS 'Target date/time of the forecast';
COMMENT ON COLUMN AT_FORECAST_TEXT.ISSUE_DATE         IS 'Date/time the forecast was issued';
COMMENT ON COLUMN AT_FORECAST_TEXT.CLOB_CODE          IS 'References text';

ALTER TABLE AT_FORECAST_TEXT ADD CONSTRAINT AT_FORECAST_TEXT_FK1 FOREIGN KEY (FORECAST_SPEC_CODE) REFERENCES AT_FORECAST_SPEC (FORECAST_SPEC_CODE);
ALTER TABLE AT_FORECAST_TEXT ADD CONSTRAINT AT_FORECAST_TEXT_FK2 FOREIGN KEY (CLOB_CODE) REFERENCES AT_CLOB (CLOB_CODE);

CREATE TABLE AT_TS_DELETED_TIMES (
   DELETED_TIME NUMBER(14) NOT NULL,
   TS_CODE      NUMBER(10) NOT NULL,
   VERSION_DATE DATE       NOT NULL,
   DATE_TIME    DATE       NOT NULL,
   CONSTRAINT AT_TS_DELETED_TIMES_PK PRIMARY KEY (DELETED_TIME, TS_CODE, VERSION_DATE, DATE_TIME)
) 
ORGANIZATION INDEX 
TABLESPACE CWMS_20_TSV
/

COMMENT ON TABLE  AT_TS_DELETED_TIMES              IS 'Contains times of recently deleted time series data in Java milliseconds';
COMMENT ON COLUMN AT_TS_DELETED_TIMES.DELETED_TIME IS 'Time at which the data were deleted';
COMMENT ON COLUMN AT_TS_DELETED_TIMES.TS_CODE      IS 'TS_CODE of the deleted data';
COMMENT ON COLUMN AT_TS_DELETED_TIMES.VERSION_DATE IS 'VERSION_DATE of the deleted data';
COMMENT ON COLUMN AT_TS_DELETED_TIMES.DATE_TIME    IS 'DATE_TIME of the deleted data';

create table at_boolean_state(
   name  varchar2(64) primary key,
   state char(1),
   constraint at_boolean_state_ck1 check (nvl(state, 'T') in ('T','F'))
)
tablespace cwms_20at_data
/

comment on table  at_boolean_state       is 'Holds named boolean states';
comment on column at_boolean_state.name  is 'Name of boolean state';
comment on column at_boolean_state.state is 'Value (T/F) of boolean state';

create unique index at_boolean_state_u1 on at_boolean_state(upper(name)) tablespace cwms_20at_data;


create global temporary table at_schema_object_diff
(
   object_type      varchar2(30),
   object_name      varchar2(30),
   deployed_version varchar2(64),
   deployed_ddl     clob,
   current_ddl      clob,
   constraint at_schema_object_diff_pk primary key (object_type, object_name)
)
on commit delete rows
/

create table cwms_media_type (
   media_type_code number(4)    not null,
   media_type_id   varchar2(84) not null,
   constraint cwms_media_type_pk  primary key(media_type_code),
   constraint cwms_media_type_u1  unique(media_type_id),
   constraint cwms_media_type_ck1 check(lower(media_type_id) = media_type_id)
) tablespace CWMS_20AT_DATA
/
comment on table  cwms_media_type                 is 'Contains internet media type (MIME type) strings';
comment on column cwms_media_type.media_type_code is 'Synthetic key';
comment on column cwms_media_type.media_type_id   is 'The internet media type';
--
create table at_file_extension(
   office_code     number(10)   not null,
   file_ext        varchar2(16) not null,
   media_type_code number(4)    not null,
   constraint at_file_extension_pk  primary key(office_code, file_ext),
   constraint at_file_extension_ck1 check(lower(file_ext) = file_ext),
   constraint at_file_extension_fk1 foreign key(media_type_code) references cwms_media_type(media_type_code)
) tablespace cwms_20at_data
/
comment on table  at_file_extension                 is 'Relates file extensions to media types';
comment on column at_file_extension.office_code     is 'The office that owns the file extension relationship (may be CWMS office code)';
comment on column at_file_extension.file_ext        is 'The file extension (without leading ''.'')';
comment on column at_file_extension.media_type_code is 'References the related media type for the file extension';
--
create table at_blob(
   blob_code       number(10)    not null,
   office_code     number(10)    not null,
   id              varchar2(256) not null,
   description     varchar2(256),
   media_type_code number(4)     not null,
   value           blob,
   constraint at_blob_pk  primary key(blob_code),
   constraint at_blob_fk1 foreign key(media_type_code) references cwms_media_type(media_type_code)
) tablespace cwms_20at_data
/
create unique index at_blob_u1 on at_blob(office_code, upper(id)) tablespace cwms_20at_data
/
comment on table  at_blob                 is 'Contains binary data';
comment on column at_blob.blob_code       is 'Synthetic key';
comment on column at_blob.office_code     is 'Office that owns the binary data';
comment on column at_blob.id              is 'Text identifier of binary data';
comment on column at_blob.description     is 'Description of binary data';
comment on column at_blob.media_type_code is 'References media type of the binary data';
comment on column at_blob.value           is 'The binary data';
--
create table at_std_text(
   std_text_code number(10)   not null,
   office_code   number(10)   not null,
   std_text_id   varchar2(16) not null,
   clob_code     number(10),
   constraint at_std_text_pk  primary key(std_text_code),
   constraint at_std_text_u1  unique(office_code, std_text_id),
   constraint at_std_text_ck1 check(std_text_id = upper(std_text_id)),
   constraint at_std_text_fk1 foreign key(clob_code) references at_clob(clob_code)
) tablespace cwms_20at_data
/
comment on table  at_std_text               is 'Contains short references to descriptive text';
comment on column at_std_text.std_text_code is 'Synthetic key';
comment on column at_std_text.office_code   is 'Office that owns the standard text';
comment on column at_std_text.std_text_id   is 'The short identifier';
comment on column at_std_text.clob_code     is 'Reference to the descriptive text - may be null if short identifier is self-descriptive';
--
create table at_tsv_std_text(
   ts_code         number(10)   not null,
   date_time       date         not null,
   version_date    date         not null,
   std_text_code   number(10)   not null,
   data_entry_date timestamp(6) not null,
   attribute       number,
   constraint at_tsv_std_text_pk  primary key(ts_code, date_time, version_date, std_text_code),
   constraint at_tsv_std_text_fk1 foreign key(ts_code) references at_cwms_ts_spec(ts_code),
   constraint at_tsv_std_text_fk2 foreign key(std_text_code) references at_std_text(std_text_code)
) tablespace cwms_20_tsv
/
create index at_tsv_std_text_idx1 on at_tsv_std_text(data_entry_date) tablespace cwms_20_tsv
/
comment on table  at_tsv_std_text                 is 'Contains references to standard text from a time series';
comment on column at_tsv_std_text.ts_code         is 'The time series';
comment on column at_tsv_std_text.date_time       is 'The date/time in the time series for the reference';
comment on column at_tsv_std_text.version_date    is 'The version date/time of the time series';
comment on column at_tsv_std_text.std_text_code   is 'Reference to the standard text';
comment on column at_tsv_std_text.data_entry_date is 'The date/time the reference was stored';
comment on column at_tsv_std_text.attribute       is 'Attribute that can be used for sorting or other puropses';
--
create table at_tsv_text(
   ts_code         number(10)   not null,
   date_time       date         not null,
   version_date    date         not null,
   clob_code       number(10)   not null,
   data_entry_date timestamp(6) not null,
   attribute       number,
   constraint at_tsv_text_pk  primary key(ts_code, date_time, version_date, clob_code),
   constraint at_tsv_text_fk1 foreign key(ts_code) references at_cwms_ts_spec(ts_code),
   constraint at_tsv_text_fk2 foreign key(clob_code) references at_clob(clob_code)
) tablespace cwms_20_tsv
/
create index at_tsv_text_idx1 on at_tsv_text(data_entry_date) tablespace cwms_20_tsv
/
comment on table  at_tsv_text                 is 'Contains references to (nonstandard) text from a time series';
comment on column at_tsv_text.ts_code         is 'The time series';
comment on column at_tsv_text.date_time       is 'The date/time in the time series for the reference';
comment on column at_tsv_text.version_date    is 'The version date/time of the time series';
comment on column at_tsv_text.clob_code       is 'Reference to the text';
comment on column at_tsv_text.data_entry_date is 'The date/time the reference was stored';
comment on column at_tsv_text.attribute       is 'Attribute that can be used for sorting or other puropses';
--
create table at_tsv_binary(
   ts_code         number(10)   not null,
   date_time       date         not null,
   version_date    date         not null,
   blob_code       number(10)   not null,
   data_entry_date timestamp(6) not null,
   attribute       number,
   constraint at_tsv_binary_pk  primary key(ts_code, date_time, version_date, blob_code),
   constraint at_tsv_binary_fk1 foreign key(ts_code) references at_cwms_ts_spec(ts_code),
   constraint at_tsv_binary_fk2 foreign key(blob_code) references at_blob(blob_code)
) tablespace cwms_20_tsv
/
create index at_tsv_binary_idx1 on at_tsv_binary(data_entry_date) tablespace cwms_20_tsv
/
comment on table  at_tsv_binary                 is 'Contains references to binary data from a time series';
comment on column at_tsv_binary.ts_code         is 'The time series';
comment on column at_tsv_binary.date_time       is 'The date/time in the time series for the reference';
comment on column at_tsv_binary.version_date    is 'The version date/time of the time series';
comment on column at_tsv_binary.blob_code       is 'Reference to the binary data';
comment on column at_tsv_binary.data_entry_date is 'The date/time the references was stored';
comment on column at_tsv_binary.attribute       is 'Attribute that can be used for sorting or other puropses';
--
begin
   insert into cwms_base_parameter values(-2, 'Binary', 19, 55, 55, 55, 'Binary Data', 'Binary data such as images, documents, etc...');
   insert into cwms_base_parameter values(-1, 'Text',   19, 55, 55, 55, 'Text Data',   'Text data only, no numeric values');
exception
   when others then
      if sqlcode = -1 then
         null;
      else
         raise;
      end if;
end;
/
begin
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/A', '''A'' code from DATAMAN', 'NO RECORD');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/B', '''B'' code from DATAMAN', 'CHANNEL DRY');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/C', '''C'' code from DATAMAN', 'POOL STAGE');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/D', '''D'' code from DATAMAN', 'AFFECTED BY WIND');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/E', '''E'' code from DATAMAN', 'ESTIMATED');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/F', '''F'' code from DATAMAN', 'NOT AT STATED TIME');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/G', '''G'' code from DATAMAN', 'GATES CLOSED');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/H', '''H'' code from DATAMAN', 'PEAK STAGE');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/I', '''I'' code from DATAMAN', 'ICE/SHORE ICE');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/J', '''J'' code from DATAMAN', 'INTAKES OUT OF WATER');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/K', '''K'' code from DATAMAN', 'FLOAT FROZEN/FLOATING ICE');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/L', '''L'' code from DATAMAN', 'GAGE FROZEN');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/M', '''M'' code from DATAMAN', 'MALFUNCTION');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/N', '''N'' code from DATAMAN', 'MEAN STAGE FOR THE DAY');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/O', '''O'' code from DATAMAN', 'OBSERVERS READING');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/P', '''P'' code from DATAMAN', 'INTERPOLATED');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/Q', '''Q'' code from DATAMAN', 'DISCHARGE MISSING');
   insert into at_clob values(cwms_seq.nextval, 53, '/DATMAN/R', '''R'' code from DATAMAN', 'HIGH WATER, NO ACCESS');
--
   insert into at_std_text values(cwms_seq.nextval, 53, 'A', (select clob_code from at_clob where id = '/DATMAN/A'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'B', (select clob_code from at_clob where id = '/DATMAN/B'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'C', (select clob_code from at_clob where id = '/DATMAN/C'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'D', (select clob_code from at_clob where id = '/DATMAN/D'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'E', (select clob_code from at_clob where id = '/DATMAN/E'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'F', (select clob_code from at_clob where id = '/DATMAN/F'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'G', (select clob_code from at_clob where id = '/DATMAN/G'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'H', (select clob_code from at_clob where id = '/DATMAN/H'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'I', (select clob_code from at_clob where id = '/DATMAN/I'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'J', (select clob_code from at_clob where id = '/DATMAN/J'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'K', (select clob_code from at_clob where id = '/DATMAN/K'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'L', (select clob_code from at_clob where id = '/DATMAN/L'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'M', (select clob_code from at_clob where id = '/DATMAN/M'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'N', (select clob_code from at_clob where id = '/DATMAN/N'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'O', (select clob_code from at_clob where id = '/DATMAN/O'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'P', (select clob_code from at_clob where id = '/DATMAN/P'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'Q', (select clob_code from at_clob where id = '/DATMAN/Q'));
   insert into at_std_text values(cwms_seq.nextval, 53, 'R', (select clob_code from at_clob where id = '/DATMAN/R'));
end;
/
commit;
declare
   i number(4) := 0;
begin
   insert into cwms_media_type values(i, 'other/unknown'); i := i + 1;
   insert into cwms_media_type values(i, 'application/1d-interleaved-parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'application/3gpp-ims+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/activemessage'); i := i + 1;
   insert into cwms_media_type values(i, 'application/andrew-inset'); i := i + 1;
   insert into cwms_media_type values(i, 'application/applefile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/applixware'); i := i + 1;
   insert into cwms_media_type values(i, 'application/atom+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/atomcat+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/atomicmail'); i := i + 1;
   insert into cwms_media_type values(i, 'application/atomsvc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/auth-policy+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/batch-smtp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/beep+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/calendar+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cals-1840'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ccmp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ccxml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cdmi-capability'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cdmi-container'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cdmi-domain'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cdmi-object'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cdmi-queue'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cea-2018+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cellml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cfw'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cnrp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/commonground'); i := i + 1;
   insert into cwms_media_type values(i, 'application/conference-info+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cpl+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/csta+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cstadata+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cu-seeme'); i := i + 1;
   insert into cwms_media_type values(i, 'application/cybercash'); i := i + 1;
   insert into cwms_media_type values(i, 'application/davmount+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dca-rft'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dec-dx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dialog-info+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dicom'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dns'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dskpp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dssc+der'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dssc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/dvcs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ecmascript'); i := i + 1;
   insert into cwms_media_type values(i, 'application/edi-consent'); i := i + 1;
   insert into cwms_media_type values(i, 'application/edifact'); i := i + 1;
   insert into cwms_media_type values(i, 'application/edi-x12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/emma+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/epp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/epub+zip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/eshop'); i := i + 1;
   insert into cwms_media_type values(i, 'application/example'); i := i + 1;
   insert into cwms_media_type values(i, 'application/exi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/fastinfoset'); i := i + 1;
   insert into cwms_media_type values(i, 'application/fastsoap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/fits'); i := i + 1;
   insert into cwms_media_type values(i, 'application/font-tdpfr'); i := i + 1;
   insert into cwms_media_type values(i, 'application/framework-attributes+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/h224'); i := i + 1;
   insert into cwms_media_type values(i, 'application/held+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/http'); i := i + 1;
   insert into cwms_media_type values(i, 'application/hyperstudio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ibe-key-request+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ibe-pkg-reply+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ibe-pp-data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/iges'); i := i + 1;
   insert into cwms_media_type values(i, 'application/im-iscomposing+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/index'); i := i + 1;
   insert into cwms_media_type values(i, 'application/index.cmd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/index.obj'); i := i + 1;
   insert into cwms_media_type values(i, 'application/index.response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/index.vnd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/inkml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/iotp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ipfix'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ipp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/isup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/java-archive'); i := i + 1;
   insert into cwms_media_type values(i, 'application/javascript'); i := i + 1;
   insert into cwms_media_type values(i, 'application/java-serialized-object'); i := i + 1;
   insert into cwms_media_type values(i, 'application/java-vm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/json'); i := i + 1;
   insert into cwms_media_type values(i, 'application/kpml-request+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/kpml-response+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/lost+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mac-binhex40'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mac-compactpro'); i := i + 1;
   insert into cwms_media_type values(i, 'application/macwriteii'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mads+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/marc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/marcxml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mathematica'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mathml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mathml-content+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mathml-presentation+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-associated-procedure-description+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-deregister+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-envelope+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-msk+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-msk-response+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-protection-description+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-reception-report+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-register+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-register-response+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbms-user-service-description+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mbox'); i := i + 1;
   insert into cwms_media_type values(i, 'application/media_control+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mediaservercontrol+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/metalink4+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mets+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mikey'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mods+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mosskey-data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mosskey-request'); i := i + 1;
   insert into cwms_media_type values(i, 'application/moss-keys'); i := i + 1;
   insert into cwms_media_type values(i, 'application/moss-signature'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mp21'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mp4'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mpeg4-generic'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mpeg4-iod'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mpeg4-iod-xmt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/msc-ivr+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/msc-mixer+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/msword'); i := i + 1;
   insert into cwms_media_type values(i, 'application/mxf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/nasdata'); i := i + 1;
   insert into cwms_media_type values(i, 'application/news-checkgroups'); i := i + 1;
   insert into cwms_media_type values(i, 'application/news-groupinfo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/news-transmission'); i := i + 1;
   insert into cwms_media_type values(i, 'application/nss'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ocsp-request'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ocsp-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/octet-stream'); i := i + 1;
   insert into cwms_media_type values(i, 'application/oda'); i := i + 1;
   insert into cwms_media_type values(i, 'application/oebps-package+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ogg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/onenote'); i := i + 1;
   insert into cwms_media_type values(i, 'application/oxps'); i := i + 1;
   insert into cwms_media_type values(i, 'application/parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'application/patch-ops-error+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pgp-encrypted'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pgp-keys'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pgp-signature'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pics-rules'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pidf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pidf-diff+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkcs10'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkcs7-mime'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkcs7-signature'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkcs8'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkix-attr-cert'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkix-cert'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkixcmp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkix-crl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pkix-pkipath'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pls+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/poc-settings+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/postscript'); i := i + 1;
   insert into cwms_media_type values(i, 'application/prs.alvestrand.titrax-sheet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/prs.cww'); i := i + 1;
   insert into cwms_media_type values(i, 'application/prs.nprend'); i := i + 1;
   insert into cwms_media_type values(i, 'application/prs.plucker'); i := i + 1;
   insert into cwms_media_type values(i, 'application/prs.rdf-xml-crypt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/prs.xsf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/pskc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/qsig'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rdf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/reginfo+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/relax-ng-compact-syntax'); i := i + 1;
   insert into cwms_media_type values(i, 'application/remote-printing'); i := i + 1;
   insert into cwms_media_type values(i, 'application/resource-lists+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/resource-lists-diff+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/riscos'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rlmi+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rls-services+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rpki-manifest'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rpki-roa'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rpki-updown'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rsd+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rss+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rtf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/rtx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/samlassertion+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/samlmetadata+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sbml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/scvp-cv-request'); i := i + 1;
   insert into cwms_media_type values(i, 'application/scvp-cv-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/scvp-vp-request'); i := i + 1;
   insert into cwms_media_type values(i, 'application/scvp-vp-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sdp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/set-payment'); i := i + 1;
   insert into cwms_media_type values(i, 'application/set-payment-initiation'); i := i + 1;
   insert into cwms_media_type values(i, 'application/set-registration'); i := i + 1;
   insert into cwms_media_type values(i, 'application/set-registration-initiation'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sgml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sgml-open-catalog'); i := i + 1;
   insert into cwms_media_type values(i, 'application/shf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sieve'); i := i + 1;
   insert into cwms_media_type values(i, 'application/simple-filter+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/simple-message-summary'); i := i + 1;
   insert into cwms_media_type values(i, 'application/simplesymbolcontainer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/slate'); i := i + 1;
   insert into cwms_media_type values(i, 'application/smil'); i := i + 1;
   insert into cwms_media_type values(i, 'application/smil+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/soap+fastinfoset'); i := i + 1;
   insert into cwms_media_type values(i, 'application/soap+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sparql-query'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sparql-results+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/spirits-event+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/srgs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/srgs+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/sru+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ssml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-apex-update'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-apex-update-confirm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-community-update'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-community-update-confirm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-error'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-sequence-adjust'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-sequence-adjust-confirm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-status-query'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-status-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-update'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tamp-update-confirm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tei+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/thraud+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/timestamped-data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/timestamp-query'); i := i + 1;
   insert into cwms_media_type values(i, 'application/timestamp-reply'); i := i + 1;
   insert into cwms_media_type values(i, 'application/tve-trigger'); i := i + 1;
   insert into cwms_media_type values(i, 'application/ulpfec'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vcard+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vemmi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp.bsf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp.pic-bw-large'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp.pic-bw-small'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp.pic-bw-var'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp.sms'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp2.bcmcsinfo+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp2.sms'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3gpp2.tcap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.3m.post-it-notes'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.accpac.simply.aso'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.accpac.simply.imp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.acucobol'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.acucorp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.adobe.air-application-installer-package+zip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.adobe.fxp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.adobe.partial-upload'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.adobe.xdp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.adobe.xfdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.aether.imp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ah-barcode'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ahead.space'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.airzip.filesecure.azf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.airzip.filesecure.azs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.amazon.ebook'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.americandynamics.acc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.amiga.ami'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.amundsen.maze+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.android.package-archive'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.anser-web-certificate-issue-initiation'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.anser-web-funds-transfer-initiation'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.antix.game-component'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.apple.installer+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.apple.mpegurl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.arastra.swi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.aristanetworks.swi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.astraea-software.iota'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.audiograph'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.autopackage'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.avistar+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.blueice.multipass'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.bluetooth.ep.oob'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.bmi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.businessobjects'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cab-jscript'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.canon-cpdl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.canon-lips'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cendio.thinlinc.clientconf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.chemdraw+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.chipnuts.karaoke-mmd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cinderella'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cirpack.isdn-ext'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.claymore'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cloanto.rp9'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.clonk.c4group'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cluetrust.cartomobile-config'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cluetrust.cartomobile-config-pkg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.collection+json'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.commerce-battelle'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.commonspace'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.contact.cmsg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cosmocaller'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.crick.clicker'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.crick.clicker.keyboard'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.crick.clicker.palette'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.crick.clicker.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.crick.clicker.wordbank'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.criticaltools.wbs+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ctc-posml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ctct.ws+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cups-pdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cups-postscript'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cups-ppd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cups-raster'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cups-raw'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.curl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.curl.car'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.curl.pcurl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.cybank'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.data-vision.rdz'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dece.data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dece.ttml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dece.unspecified'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dece.zip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.denovo.fcselayout-link'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dir-bi.plate-dl-nosuffix'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dna'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dolby.mlp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dolby.mobile.1'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dolby.mobile.2'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dpgraph'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dreamfactory'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.ait'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.dvbj'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.esgcontainer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.ipdcdftnotifaccess'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.ipdcesgaccess'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.ipdcesgaccess2'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.ipdcesgpdd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.ipdcroaming'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.iptv.alfec-base'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.iptv.alfec-enhancement'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-aggregate-root+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-container+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-generic+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-ia-msglist+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-ia-registration-request+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-ia-registration-response+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.notif-init+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.pfr'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dvb.service'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dxr'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.dynageo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.easykaraoke.cdgdownload'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecdis-update'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecowin.chart'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecowin.filerequest'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecowin.fileupdate'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecowin.series'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecowin.seriesrequest'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ecowin.seriesupdate'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.emclient.accessrequest+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.enliven'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.eprints.data+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.epson.esf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.epson.msf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.epson.quickanime'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.epson.salt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.epson.ssf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ericsson.quickcall'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.eszigno3+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.aoc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.cug+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvcommand+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvdiscovery+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvprofile+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvsad-bc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvsad-cod+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvsad-npvr+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvservice+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvsync+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.iptvueprofile+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.mcid+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.overload-control-policy-dataset+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.sci+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.simservs+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.tsl.der'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.etsi.tsl+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.eudora.data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ezpix-album'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ezpix-package'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fdsn.mseed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fdsn.seed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ffsns'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fints'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.flographit'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fluxtime.clip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.font-fontforge-sfd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.framemaker'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.frogans.fnc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.frogans.ltf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fsc.weblaunch'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.f-secure.mobile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujitsu.oasys'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujitsu.oasys2'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujitsu.oasys3'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujitsu.oasysgp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujitsu.oasysprs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujixerox.art4'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujixerox.art-ex'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujixerox.ddd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujixerox.docuworks'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujixerox.docuworks.binder'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fujixerox.hbpl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fut-misnet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.fuzzysheet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.genomatix.tuxedo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geocube+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geogebra.file'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geogebra.tool'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geometry-explorer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geonext'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geoplan'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.geospace'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.globalplatform.card-content-mgt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.globalplatform.card-content-mgt-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.gmx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.google-earth.kml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.google-earth.kmz'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.grafeq'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.gridmp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-account'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-help'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-identity-message'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-injector'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-tool-message'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-tool-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.groove-vcard'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hal+json'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hal+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.handheld-entertainment+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hbci'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hcl-bireports'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hhe.lesson-player'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hp-hpgl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hp-hpid'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hp-hps'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hp-jlyt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hp-pcl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hp-pclxl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.httphone'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hydrostatix.sof-data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.hzn-3d-crossword'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ibm.afplinedata'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ibm.electronic-media'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ibm.minipay'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ibm.modcap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ibm.rights-management'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ibm.secure-container'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.iccprofile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.igloader'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.immervision-ivp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.immervision-ivu'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.informedcontrol.rms+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.informix-visionary'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.infotech.project'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.infotech.project+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.insors.igm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.intercon.formnet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.intergeo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.intertrust.digibox'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.intertrust.nncp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.intu.qbo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.intu.qfx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.iptc.g2.conceptitem+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.iptc.g2.knowledgeitem+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.iptc.g2.newsitem+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.iptc.g2.packageitem+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ipunplugged.rcprofile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.irepository.package+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.isac.fcs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.is-xpr'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.jam'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-directory-service'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-jpnstore-wakeup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-payment-wakeup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-registration'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-registration-wakeup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-setstore-wakeup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-verification'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.japannet-verification-wakeup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.jcp.javame.midlet-rms'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.jisp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.joost.joda-archive'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kahootz'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.karbon'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kchart'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kformula'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kivio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kontour'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kpresenter'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kspread'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kde.kword'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kenameaapp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kidspiration'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kinar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.koan'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.kodak-descriptor'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.las.las+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.liberty-request+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.llamagraphics.life-balance.desktop'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.llamagraphics.life-balance.exchange+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-1-2-3'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-approach'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-freelance'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-notes'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-organizer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-screencam'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.lotus-wordpro'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.macports.portpkg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.marlin.drm.actiontoken+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.marlin.drm.conftoken+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.marlin.drm.license+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.marlin.drm.mdcf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mcd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.medcalcdata'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mediastation.cdkey'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.meridian-slingshot'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mfer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mfmp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.micrografx.flo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.micrografx.igx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mif'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.minisoft-hp3000-save'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mitsubishi.misty-guard.trustweb'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.daf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.dis'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.mbk'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.mqy'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.msl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.plc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mobius.txf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mophun.application'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mophun.certificate'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite.adsi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite.fis'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite.gotap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite.kmr'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite.ttc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.flexsuite.wem'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.motorola.iprm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mozilla.xul+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-artgalry'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-asf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-cab-compressed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mseq'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-excel'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-excel.addin.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-excel.sheet.binary.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-excel.sheet.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-excel.template.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-fontobject'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-htmlhelp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.msign'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-ims'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-lrm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-office.activex+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-officetheme'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-pki.seccat'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-pki.stl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-playready.initiator+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-powerpoint'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-powerpoint.addin.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-powerpoint.presentation.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-powerpoint.slide.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-powerpoint.slideshow.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-powerpoint.template.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-project'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-tnef'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-wmdrm.lic-chlg-req'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-wmdrm.lic-resp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-wmdrm.meter-chlg-req'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-wmdrm.meter-resp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-word.document.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-word.template.macroenabled.12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-works'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-wpl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ms-xpsdocument'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.multiad.creator'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.multiad.creator.cif'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.musician'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.music-niff'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.muvee.style'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.mynfc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ncd.control'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ncd.reference'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nervana'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.netfpx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.neurolanguage.nlu'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.noblenet-directory'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.noblenet-sealer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.noblenet-web'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.catalogs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.conml+wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.conml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.iptv.config+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.isds-radio-presets'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.landmark+wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.landmark+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.landmarkcollection+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.ncd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.n-gage.ac+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.n-gage.data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.n-gage.symbian.install'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.pcd+wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.pcd+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.radio-preset'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.nokia.radio-presets'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.novadigm.edm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.novadigm.edx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.novadigm.ext'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ntt-local.file-transfer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ntt-local.sip-ta_remote'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ntt-local.sip-ta_tcp_stream'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.chart'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.chart-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.database'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.formula'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.formula-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.graphics'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.graphics-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.image'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.image-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.presentation'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.presentation-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.spreadsheet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.spreadsheet-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.text'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.text-master'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.text-template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oasis.opendocument.text-web'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.obn'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oftn.l10n+json'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.contentaccessdownload+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.contentaccessstreaming+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.cspg-hexbinary'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.dae.svg+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.dae.xhtml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.mippvcontrolmessage+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.pae.gem'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.spdiscovery+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.spdlist+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.ueprofile+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oipf.userprofile+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.olpc-sugar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.associated-procedure-parameter+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.drm-trigger+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.imd+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.ltkm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.notification+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.provisioningtrigger'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.sgboot'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.sgdd+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.sgdu'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.simple-symbol-container'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.smartcard-trigger+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.sprov+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.bcast.stkm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.cab-address-book+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.cab-feature-handler+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.cab-pcc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.cab-user-prefs+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.dcd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.dcdc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.dd2+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.drm.risd+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.group-usage-list+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.pal+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.poc.detailed-progress-report+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.poc.final-report+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.poc.groups+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.poc.invocation-descriptor+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.poc.optimized-progress-report+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.push'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.scidm.messages+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma.xcap-directory+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.omads-email+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.omads-file+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.omads-folder+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.omaloc-supl-init'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma-scws-config'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma-scws-http-request'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.oma-scws-http-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openofficeorg.extension'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.custom-properties+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.customxmlproperties+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawing+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawingml.chart+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawingml.chartshapes+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawingml.diagramcolors+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawingml.diagramdata+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawingml.diagramlayout+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.drawingml.diagramstyle+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.extended-properties+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.commentauthors+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.comments+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.handoutmaster+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.notesmaster+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.notesslide+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.presentation'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.presprops+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slide'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slide+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slidelayout+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slidemaster+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slideshow'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slideshow.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.slideupdateinfo+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.tablestyles+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.tags+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.template.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.presentationml.viewprops+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.calcchain+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.chartsheet+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.connections+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.dialogsheet+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.externallink+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.pivotcachedefinition+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.pivotcacherecords+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.pivottable+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.querytable+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.revisionheaders+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.revisionlog+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sharedstrings+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheetmetadata+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.tablesinglecells+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.template.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.usernames+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.volatiledependencies+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.theme+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.themeoverride+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.vmldrawing'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document.glossary+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.fonttable+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-officedocument.wordprocessingml.websettings+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-package.core-properties+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-package.digital-signature-xmlsignature+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.openxmlformats-package.relationships+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.osa.netdeploy'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.osgeo.mapguide.package'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.osgi.bundle'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.osgi.dp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.otps.ct-kip+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.palm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.paos.xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pawaafile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pg.format'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pg.osasli'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.piaccess.application-licence'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.picsel'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pmi.widget'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.poc.group-advertisement+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pocketlearn'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.powerbuilder6'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.powerbuilder6-s'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.powerbuilder7'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.powerbuilder75'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.powerbuilder75-s'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.powerbuilder7-s'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.preminet'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.previewsystems.box'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.proteus.magazine'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.publishare-delta-tree'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pvi.ptid1'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pwg-multiplexed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.pwg-xhtml-print+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.qualcomm.brew-app-res'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.quark.quarkxpress'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.quobject-quoxdocument'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.moml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-audit+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-audit-conf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-audit-conn+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-audit-dialog+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-audit-stream+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-conf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog-base+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog-fax-detect+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog-fax-sendrecv+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog-group+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog-speech+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.radisys.msml-dialog-transform+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.rainstor.data'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.rapid'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.realvnc.bed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.recordare.musicxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.recordare.musicxml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.renlearn.rlprint'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.rig.cryptonote'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.rim.cod'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.rn-realmedia'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.route66.link66+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ruckus.download'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.s3sms'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sailingtracker.track'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sbm.cid'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sbm.mid2'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.scribus'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.3df'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.csf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.doc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.eml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.mht'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.net'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.ppt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.tiff'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealed.xls'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealedmedia.softseal.html'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sealedmedia.softseal.pdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.seemail'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sema'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.semd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.semf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.shana.informed.formdata'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.shana.informed.formtemplate'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.shana.informed.interchange'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.shana.informed.package'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.simtech-mindmapper'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.smaf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.smart.notebook'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.smart.teacher'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.software602.filler.form+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.software602.filler.form-xml-zip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.solent.sdkm+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.spotfire.dxp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.spotfire.sfs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sss-cod'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sss-dtf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sss-ntf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stardivision.calc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stardivision.draw'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stardivision.impress'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stardivision.math'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stardivision.writer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stardivision.writer-global'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stepmania.package'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.stepmania.stepchart'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.street-stream'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.wadl+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.calc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.calc.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.draw'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.draw.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.impress'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.impress.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.math'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.writer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.writer.global'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sun.xml.writer.template'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.sus-calendar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.svd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.swiftview-ics'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.symbian.install'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.syncml.dm.notification'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.syncml.dm+wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.syncml.dm+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.syncml.ds.notification'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.syncml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.tao.intent-module-archive'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.tcpdump.pcap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.tmobile-livetv'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.trid.tpt'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.triscape.mxs'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.trueapp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.truedoc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ubisoft.webplayer'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.ufdl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uiq.theme'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.umajin'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.unity'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uoml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.alert'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.alert-wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.bearer-choice'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.bearer-choice-wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.cacheop'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.cacheop-wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.channel'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.channel-wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.list'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.listcmd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.listcmd-wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.list-wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.uplanet.signal'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.vcx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.vd-study'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.vectorworks'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.verimatrix.vcas'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.vidsoft.vidconference'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.visio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.visionary'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.vividence.scriptfile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.vsf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wap.sic'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wap.slc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wap.wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wap.wmlc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wap.wmlscriptc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.webturbo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wfa.wsc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wmc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wmf.bootstrap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wolfram.mathematica'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wolfram.mathematica.package'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wolfram.player'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wordperfect'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wqd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wrq-hp3000-labelled'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wt.stf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wv.csp+wbxml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wv.csp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.wv.ssp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xara'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xfdl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xfdl.webform'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xmi+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xmpie.cpkg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xmpie.dpkg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xmpie.plan'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xmpie.ppkg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.xmpie.xlim'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.hv-dic'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.hv-script'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.hv-voice'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.openscoreformat'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.openscoreformat.osfpvg+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.remote-setup'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.smaf-audio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.smaf-phrase'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.through-ngn'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yamaha.tunnel-udpencap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.yellowriver-custom-menu'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.zul'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vnd.zzazz.deck+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/voicexml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/vq-rtcpxr'); i := i + 1;
   insert into cwms_media_type values(i, 'application/watcherinfo+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/whoispp-query'); i := i + 1;
   insert into cwms_media_type values(i, 'application/whoispp-response'); i := i + 1;
   insert into cwms_media_type values(i, 'application/widget'); i := i + 1;
   insert into cwms_media_type values(i, 'application/winhlp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/wita'); i := i + 1;
   insert into cwms_media_type values(i, 'application/wordperfect5.1'); i := i + 1;
   insert into cwms_media_type values(i, 'application/wsdl+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/wspolicy+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x400-bp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-7z-compressed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-abiword'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-ace-compressed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-authorware-bin'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-authorware-map'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-authorware-seg'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-bcpio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-bittorrent'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-bzip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-bzip2'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcap-att+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcap-caps+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcap-diff+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcap-el+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcap-error+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcap-ns+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-cdlink'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-chat'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-chess-pgn'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcon-conference-info+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xcon-conference-info-diff+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-cpio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-csh'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-debian-package'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-director'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-doom'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-dtbncx+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-dtbook+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-dtbresource+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-dvi'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xenc+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-bdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-ghostscript'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-linux-psf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-otf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-pcf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-snf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-ttf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-type1'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-font-woff'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-futuresplash'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-gnumeric'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-gtar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-hdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xhtml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xhtml-voice+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-java-jnlp-file'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-latex'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xml-dtd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xml-external-parsed-entity'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-mobipocket-ebook'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xmpp+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msaccess'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-ms-application'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msbinder'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-mscardfile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msclip'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msdownload'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msmediaview'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msmetafile'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msmoney'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-mspublisher'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msschedule'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-msterminal'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-ms-wmd'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-ms-wmz'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-mswrite'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-ms-xbap'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-netcdf'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xop+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-pkcs12'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-pkcs7-certificates'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-pkcs7-certreqresp'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-rar-compressed'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-sh'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-shar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-shockwave-flash'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-silverlight-app'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xslt+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xspf+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-stuffit'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-stuffitx'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-sv4cpio'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-sv4crc'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-tar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-tcl'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-tex'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-texinfo'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-tex-tfm'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-ustar'); i := i + 1;
   insert into cwms_media_type values(i, 'application/xv+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-wais-source'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-x509-ca-cert'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-xfig'); i := i + 1;
   insert into cwms_media_type values(i, 'application/x-xpinstall'); i := i + 1;
   insert into cwms_media_type values(i, 'application/yang'); i := i + 1;
   insert into cwms_media_type values(i, 'application/yin+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'application/zip'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/1d-interleaved-parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/32kadpcm'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/3gpp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/3gpp2'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/ac3'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/adpcm'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/amr'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/amr-wb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/amr-wb+'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/asc'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/atrac3'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/atrac-advanced-lossless'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/atrac-x'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/basic'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/bv16'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/bv32'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/clearmode'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/cn'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dat12'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dls'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dsr-es201108'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dsr-es202050'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dsr-es202211'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dsr-es202212'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/dvi4'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/eac3'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrc'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrc0'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrc1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrcb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrcb0'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrcb1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrc-qcp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrcwb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrcwb0'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/evrcwb1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/example'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/fwdred'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g719'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g722'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g7221'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g723'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g726-16'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g726-24'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g726-32'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g726-40'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g728'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g729'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g7291'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g729d'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/g729e'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/gsm'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/gsm-efr'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/gsm-hr-08'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/ilbc'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/ip-mr_v2.5'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/l16'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/l20'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/l24'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/l8'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/lpc'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/midi'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mobile-xmf'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mp4'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mp4a-latm'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mpa'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mpa-robust'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/mpeg4-generic'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/ogg'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/pcma'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/pcma-wb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/pcmu'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/pcmu-wb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/prs.sid'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/qcelp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/red'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/rtp-enc-aescm128'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/rtp-midi'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/rtx'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/smv'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/smv0'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/smv-qcp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/speex'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/sp-midi'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/t140c'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/t38'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/telephone-event'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/tone'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/uemclip'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/ulpfec'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vdvi'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vmr-wb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.3gpp.iufp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.4sb'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.audiokoz'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.celp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.cisco.nse'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.cmles.radio-events'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.cns.anp1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.cns.inf1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dece.audio'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.digital-winds'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dlna.adts'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.heaac.1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.heaac.2'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.mlp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.mps'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.pl2'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.pl2x'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.pl2z'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dolby.pulse.1'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dra'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dts'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dts.hd'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.dvb.file'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.everad.plj'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.hns.audio'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.lucent.voice'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.ms-playready.media.pya'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.nokia.mobile-xmf'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.nortel.vbk'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.nuera.ecelp4800'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.nuera.ecelp7470'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.nuera.ecelp9600'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.octel.sbc'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.qcelp'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.rhetorex.32kadpcm'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.rip'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.sealedmedia.softseal.mpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vnd.vmx.cvsd'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vorbis'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/vorbis-config'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/webm'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-aac'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-aiff'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-mpegurl'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-ms-wax'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-ms-wma'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-pn-realaudio'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-pn-realaudio-plugin'); i := i + 1;
   insert into cwms_media_type values(i, 'audio/x-wav'); i := i + 1;
   insert into cwms_media_type values(i, 'chemical/x-cdx'); i := i + 1;
   insert into cwms_media_type values(i, 'chemical/x-cif'); i := i + 1;
   insert into cwms_media_type values(i, 'chemical/x-cmdf'); i := i + 1;
   insert into cwms_media_type values(i, 'chemical/x-cml'); i := i + 1;
   insert into cwms_media_type values(i, 'chemical/x-csml'); i := i + 1;
   insert into cwms_media_type values(i, 'chemical/x-xyz'); i := i + 1;
   insert into cwms_media_type values(i, 'image/bmp'); i := i + 1;
   insert into cwms_media_type values(i, 'image/cgm'); i := i + 1;
   insert into cwms_media_type values(i, 'image/example'); i := i + 1;
   insert into cwms_media_type values(i, 'image/fits'); i := i + 1;
   insert into cwms_media_type values(i, 'image/g3fax'); i := i + 1;
   insert into cwms_media_type values(i, 'image/gif'); i := i + 1;
   insert into cwms_media_type values(i, 'image/ief'); i := i + 1;
   insert into cwms_media_type values(i, 'image/jp2'); i := i + 1;
   insert into cwms_media_type values(i, 'image/jpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'image/jpm'); i := i + 1;
   insert into cwms_media_type values(i, 'image/jpx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/ktx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/naplps'); i := i + 1;
   insert into cwms_media_type values(i, 'image/png'); i := i + 1;
   insert into cwms_media_type values(i, 'image/prs.btif'); i := i + 1;
   insert into cwms_media_type values(i, 'image/prs.pti'); i := i + 1;
   insert into cwms_media_type values(i, 'image/svg+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'image/t38'); i := i + 1;
   insert into cwms_media_type values(i, 'image/tiff'); i := i + 1;
   insert into cwms_media_type values(i, 'image/tiff-fx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.adobe.photoshop'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.cns.inf2'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.dece.graphic'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.djvu'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.dvb.subtitle'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.dwg'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.dxf'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.fastbidsheet'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.fpx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.fst'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.fujixerox.edmics-mmr'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.fujixerox.edmics-rlc'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.globalgraphics.pgb'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.microsoft.icon'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.mix'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.ms-modi'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.net-fpx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.radiance'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.sealed.png'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.sealedmedia.softseal.gif'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.sealedmedia.softseal.jpg'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.svf'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.wap.wbmp'); i := i + 1;
   insert into cwms_media_type values(i, 'image/vnd.xiff'); i := i + 1;
   insert into cwms_media_type values(i, 'image/webp'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-cmu-raster'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-cmx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-freehand'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-icon'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-pcx'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-pict'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-portable-anymap'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-portable-bitmap'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-portable-graymap'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-portable-pixmap'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-rgb'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-xbitmap'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-xpixmap'); i := i + 1;
   insert into cwms_media_type values(i, 'image/x-xwindowdump'); i := i + 1;
   insert into cwms_media_type values(i, 'message/cpim'); i := i + 1;
   insert into cwms_media_type values(i, 'message/delivery-status'); i := i + 1;
   insert into cwms_media_type values(i, 'message/disposition-notification'); i := i + 1;
   insert into cwms_media_type values(i, 'message/example'); i := i + 1;
   insert into cwms_media_type values(i, 'message/external-body'); i := i + 1;
   insert into cwms_media_type values(i, 'message/feedback-report'); i := i + 1;
   insert into cwms_media_type values(i, 'message/global'); i := i + 1;
   insert into cwms_media_type values(i, 'message/global-delivery-status'); i := i + 1;
   insert into cwms_media_type values(i, 'message/global-disposition-notification'); i := i + 1;
   insert into cwms_media_type values(i, 'message/global-headers'); i := i + 1;
   insert into cwms_media_type values(i, 'message/http'); i := i + 1;
   insert into cwms_media_type values(i, 'message/imdn+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'message/news'); i := i + 1;
   insert into cwms_media_type values(i, 'message/partial'); i := i + 1;
   insert into cwms_media_type values(i, 'message/rfc822'); i := i + 1;
   insert into cwms_media_type values(i, 'message/s-http'); i := i + 1;
   insert into cwms_media_type values(i, 'message/sip'); i := i + 1;
   insert into cwms_media_type values(i, 'message/sipfrag'); i := i + 1;
   insert into cwms_media_type values(i, 'message/tracking-status'); i := i + 1;
   insert into cwms_media_type values(i, 'message/vnd.si.simp'); i := i + 1;
   insert into cwms_media_type values(i, 'model/example'); i := i + 1;
   insert into cwms_media_type values(i, 'model/iges'); i := i + 1;
   insert into cwms_media_type values(i, 'model/mesh'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.collada+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.dwf'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.flatland.3dml'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.gdl'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.gs-gdl'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.gtw'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.moml+xml'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.mts'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.parasolid.transmit.binary'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.parasolid.transmit.text'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vnd.vtu'); i := i + 1;
   insert into cwms_media_type values(i, 'model/vrml'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/alternative'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/appledouble'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/byteranges'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/digest'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/encrypted'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/example'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/form-data'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/header-set'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/mixed'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/parallel'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/related'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/report'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/signed'); i := i + 1;
   insert into cwms_media_type values(i, 'multipart/voice-message'); i := i + 1;
   insert into cwms_media_type values(i, 'text/1d-interleaved-parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'text/calendar'); i := i + 1;
   insert into cwms_media_type values(i, 'text/css'); i := i + 1;
   insert into cwms_media_type values(i, 'text/csv'); i := i + 1;
   insert into cwms_media_type values(i, 'text/directory'); i := i + 1;
   insert into cwms_media_type values(i, 'text/dns'); i := i + 1;
   insert into cwms_media_type values(i, 'text/ecmascript'); i := i + 1;
   insert into cwms_media_type values(i, 'text/enriched'); i := i + 1;
   insert into cwms_media_type values(i, 'text/example'); i := i + 1;
   insert into cwms_media_type values(i, 'text/fwdred'); i := i + 1;
   insert into cwms_media_type values(i, 'text/html'); i := i + 1;
   insert into cwms_media_type values(i, 'text/javascript'); i := i + 1;
   insert into cwms_media_type values(i, 'text/n3'); i := i + 1;
   insert into cwms_media_type values(i, 'text/parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'text/plain'); i := i + 1;
   insert into cwms_media_type values(i, 'text/prs.fallenstein.rst'); i := i + 1;
   insert into cwms_media_type values(i, 'text/prs.lines.tag'); i := i + 1;
   insert into cwms_media_type values(i, 'text/red'); i := i + 1;
   insert into cwms_media_type values(i, 'text/rfc822-headers'); i := i + 1;
   insert into cwms_media_type values(i, 'text/richtext'); i := i + 1;
   insert into cwms_media_type values(i, 'text/rtf'); i := i + 1;
   insert into cwms_media_type values(i, 'text/rtp-enc-aescm128'); i := i + 1;
   insert into cwms_media_type values(i, 'text/rtx'); i := i + 1;
   insert into cwms_media_type values(i, 'text/sgml'); i := i + 1;
   insert into cwms_media_type values(i, 'text/t140'); i := i + 1;
   insert into cwms_media_type values(i, 'text/tab-separated-values'); i := i + 1;
   insert into cwms_media_type values(i, 'text/troff'); i := i + 1;
   insert into cwms_media_type values(i, 'text/turtle'); i := i + 1;
   insert into cwms_media_type values(i, 'text/ulpfec'); i := i + 1;
   insert into cwms_media_type values(i, 'text/uri-list'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vcard'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.abc'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.curl'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.curl.dcurl'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.curl.mcurl'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.curl.scurl'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.dmclientscript'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.dvb.subtitle'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.esmertec.theme-descriptor'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.fly'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.fmi.flexstor'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.graphviz'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.in3d.3dml'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.in3d.spot'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.iptc.newsml'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.iptc.nitf'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.latex-z'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.motorola.reflex'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.ms-mediapackage'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.net2phone.commcenter.command'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.radisys.msml-basic-layout'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.si.uricatalogue'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.sun.j2me.app-descriptor'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.trolltech.linguist'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.wap.si'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.wap.sl'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.wap.wml'); i := i + 1;
   insert into cwms_media_type values(i, 'text/vnd.wap.wmlscript'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-asm'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-c'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-fortran'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-java-source'); i := i + 1;
   insert into cwms_media_type values(i, 'text/xml'); i := i + 1;
   insert into cwms_media_type values(i, 'text/xml-external-parsed-entity'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-pascal'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-setext'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-uuencode'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-vcalendar'); i := i + 1;
   insert into cwms_media_type values(i, 'text/x-vcard'); i := i + 1;
   insert into cwms_media_type values(i, 'video/1d-interleaved-parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'video/3gpp'); i := i + 1;
   insert into cwms_media_type values(i, 'video/3gpp2'); i := i + 1;
   insert into cwms_media_type values(i, 'video/3gpp-tt'); i := i + 1;
   insert into cwms_media_type values(i, 'video/bmpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'video/bt656'); i := i + 1;
   insert into cwms_media_type values(i, 'video/celb'); i := i + 1;
   insert into cwms_media_type values(i, 'video/dv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/example'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h261'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h263'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h263-1998'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h263-2000'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h264'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h264-rcdo'); i := i + 1;
   insert into cwms_media_type values(i, 'video/h264-svc'); i := i + 1;
   insert into cwms_media_type values(i, 'video/jpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'video/jpeg2000'); i := i + 1;
   insert into cwms_media_type values(i, 'video/jpm'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mj2'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mp1s'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mp2p'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mp2t'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mp4'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mp4v-es'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mpeg4-generic'); i := i + 1;
   insert into cwms_media_type values(i, 'video/mpv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/nv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/ogg'); i := i + 1;
   insert into cwms_media_type values(i, 'video/parityfec'); i := i + 1;
   insert into cwms_media_type values(i, 'video/pointer'); i := i + 1;
   insert into cwms_media_type values(i, 'video/quicktime'); i := i + 1;
   insert into cwms_media_type values(i, 'video/raw'); i := i + 1;
   insert into cwms_media_type values(i, 'video/rtp-enc-aescm128'); i := i + 1;
   insert into cwms_media_type values(i, 'video/rtx'); i := i + 1;
   insert into cwms_media_type values(i, 'video/smpte292m'); i := i + 1;
   insert into cwms_media_type values(i, 'video/ulpfec'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vc1'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.cctv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dece.hd'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dece.mobile'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dece.mp4'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dece.pd'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dece.sd'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dece.video'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.directv.mpeg'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.directv.mpeg-tts'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dlna.mpeg-tts'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.dvb.file'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.fvt'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.hns.video'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.iptvforum.1dparityfec-1010'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.iptvforum.1dparityfec-2005'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.iptvforum.2dparityfec-1010'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.iptvforum.2dparityfec-2005'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.iptvforum.ttsavc'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.iptvforum.ttsmpeg2'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.motorola.video'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.motorola.videop'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.mpegurl'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.ms-playready.media.pyv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.nokia.interleaved-multimedia'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.nokia.videovoip'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.objectvideo'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.sealed.mpeg1'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.sealed.mpeg4'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.sealed.swf'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.sealedmedia.softseal.mov'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.uvvu.mp4'); i := i + 1;
   insert into cwms_media_type values(i, 'video/vnd.vivo'); i := i + 1;
   insert into cwms_media_type values(i, 'video/webm'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-f4v'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-fli'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-flv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-m4v'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-ms-asf'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-msvideo'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-ms-wm'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-ms-wmv'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-ms-wmx'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-ms-wvx'); i := i + 1;
   insert into cwms_media_type values(i, 'video/x-sgi-movie'); i := i + 1;
   insert into cwms_media_type values(i, 'x-conference/x-cooltalk'); i := i + 1;
end;
/
commit;
begin
   insert into at_file_extension values(53, '123',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-1-2-3'));
   insert into at_file_extension values(53, '3dml',        (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.in3d.3dml'));
   insert into at_file_extension values(53, '3g2',         (select media_type_code from cwms_media_type where media_type_id = 'video/3gpp2'));
   insert into at_file_extension values(53, '3gp',         (select media_type_code from cwms_media_type where media_type_id = 'video/3gpp'));
   insert into at_file_extension values(53, '7z',          (select media_type_code from cwms_media_type where media_type_id = 'application/x-7z-compressed'));
   insert into at_file_extension values(53, 'aab',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-authorware-bin'));
   insert into at_file_extension values(53, 'aac',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-aac'));
   insert into at_file_extension values(53, 'aam',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-authorware-map'));
   insert into at_file_extension values(53, 'aas',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-authorware-seg'));
   insert into at_file_extension values(53, 'abw',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-abiword'));
   insert into at_file_extension values(53, 'ac',          (select media_type_code from cwms_media_type where media_type_id = 'application/pkix-attr-cert'));
   insert into at_file_extension values(53, 'acc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.americandynamics.acc'));
   insert into at_file_extension values(53, 'ace',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-ace-compressed'));
   insert into at_file_extension values(53, 'acu',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.acucobol'));
   insert into at_file_extension values(53, 'acutc',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.acucorp'));
   insert into at_file_extension values(53, 'adp',         (select media_type_code from cwms_media_type where media_type_id = 'audio/adpcm'));
   insert into at_file_extension values(53, 'aep',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.audiograph'));
   insert into at_file_extension values(53, 'afm',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-type1'));
   insert into at_file_extension values(53, 'afp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ibm.modcap'));
   insert into at_file_extension values(53, 'ahead',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ahead.space'));
   insert into at_file_extension values(53, 'ai',          (select media_type_code from cwms_media_type where media_type_id = 'application/postscript'));
   insert into at_file_extension values(53, 'aif',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-aiff'));
   insert into at_file_extension values(53, 'aifc',        (select media_type_code from cwms_media_type where media_type_id = 'audio/x-aiff'));
   insert into at_file_extension values(53, 'aiff',        (select media_type_code from cwms_media_type where media_type_id = 'audio/x-aiff'));
   insert into at_file_extension values(53, 'air',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.adobe.air-application-installer-package+zip'));
   insert into at_file_extension values(53, 'ait',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dvb.ait'));
   insert into at_file_extension values(53, 'ami',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.amiga.ami'));
   insert into at_file_extension values(53, 'apk',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.android.package-archive'));
   insert into at_file_extension values(53, 'application', (select media_type_code from cwms_media_type where media_type_id = 'application/x-ms-application'));
   insert into at_file_extension values(53, 'apr',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-approach'));
   insert into at_file_extension values(53, 'asc',         (select media_type_code from cwms_media_type where media_type_id = 'application/pgp-signature'));
   insert into at_file_extension values(53, 'asf',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-ms-asf'));
   insert into at_file_extension values(53, 'asm',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-asm'));
   insert into at_file_extension values(53, 'aso',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.accpac.simply.aso'));
   insert into at_file_extension values(53, 'asx',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-ms-asf'));
   insert into at_file_extension values(53, 'atc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.acucorp'));
   insert into at_file_extension values(53, 'atom',        (select media_type_code from cwms_media_type where media_type_id = 'application/atom+xml'));
   insert into at_file_extension values(53, 'atomcat',     (select media_type_code from cwms_media_type where media_type_id = 'application/atomcat+xml'));
   insert into at_file_extension values(53, 'atomsvc',     (select media_type_code from cwms_media_type where media_type_id = 'application/atomsvc+xml'));
   insert into at_file_extension values(53, 'atx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.antix.game-component'));
   insert into at_file_extension values(53, 'au',          (select media_type_code from cwms_media_type where media_type_id = 'audio/basic'));
   insert into at_file_extension values(53, 'avi',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-msvideo'));
   insert into at_file_extension values(53, 'aw',          (select media_type_code from cwms_media_type where media_type_id = 'application/applixware'));
   insert into at_file_extension values(53, 'azf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.airzip.filesecure.azf'));
   insert into at_file_extension values(53, 'azs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.airzip.filesecure.azs'));
   insert into at_file_extension values(53, 'azw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.amazon.ebook'));
   insert into at_file_extension values(53, 'bat',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msdownload'));
   insert into at_file_extension values(53, 'bcpio',       (select media_type_code from cwms_media_type where media_type_id = 'application/x-bcpio'));
   insert into at_file_extension values(53, 'bdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-bdf'));
   insert into at_file_extension values(53, 'bdm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.syncml.dm+wbxml'));
   insert into at_file_extension values(53, 'bed',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.realvnc.bed'));
   insert into at_file_extension values(53, 'bh2',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujitsu.oasysprs'));
   insert into at_file_extension values(53, 'bin',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'bmi',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.bmi'));
   insert into at_file_extension values(53, 'bmp',         (select media_type_code from cwms_media_type where media_type_id = 'image/bmp'));
   insert into at_file_extension values(53, 'book',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.framemaker'));
   insert into at_file_extension values(53, 'box',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.previewsystems.box'));
   insert into at_file_extension values(53, 'boz',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-bzip2'));
   insert into at_file_extension values(53, 'bpk',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'btif',        (select media_type_code from cwms_media_type where media_type_id = 'image/prs.btif'));
   insert into at_file_extension values(53, 'bz',          (select media_type_code from cwms_media_type where media_type_id = 'application/x-bzip'));
   insert into at_file_extension values(53, 'bz2',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-bzip2'));
   insert into at_file_extension values(53, 'c',           (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'c11amc',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.cluetrust.cartomobile-config'));
   insert into at_file_extension values(53, 'c11amz',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.cluetrust.cartomobile-config-pkg'));
   insert into at_file_extension values(53, 'c4d',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.clonk.c4group'));
   insert into at_file_extension values(53, 'c4f',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.clonk.c4group'));
   insert into at_file_extension values(53, 'c4g',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.clonk.c4group'));
   insert into at_file_extension values(53, 'c4p',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.clonk.c4group'));
   insert into at_file_extension values(53, 'c4u',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.clonk.c4group'));
   insert into at_file_extension values(53, 'cab',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-cab-compressed'));
   insert into at_file_extension values(53, 'car',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.curl.car'));
   insert into at_file_extension values(53, 'cat',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-pki.seccat'));
   insert into at_file_extension values(53, 'cc',          (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'cct',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'ccxml',       (select media_type_code from cwms_media_type where media_type_id = 'application/ccxml+xml'));
   insert into at_file_extension values(53, 'cdbcmsg',     (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.contact.cmsg'));
   insert into at_file_extension values(53, 'cdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-netcdf'));
   insert into at_file_extension values(53, 'cdkey',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mediastation.cdkey'));
   insert into at_file_extension values(53, 'cdmia',       (select media_type_code from cwms_media_type where media_type_id = 'application/cdmi-capability'));
   insert into at_file_extension values(53, 'cdmic',       (select media_type_code from cwms_media_type where media_type_id = 'application/cdmi-container'));
   insert into at_file_extension values(53, 'cdmid',       (select media_type_code from cwms_media_type where media_type_id = 'application/cdmi-domain'));
   insert into at_file_extension values(53, 'cdmio',       (select media_type_code from cwms_media_type where media_type_id = 'application/cdmi-object'));
   insert into at_file_extension values(53, 'cdmiq',       (select media_type_code from cwms_media_type where media_type_id = 'application/cdmi-queue'));
   insert into at_file_extension values(53, 'cdx',         (select media_type_code from cwms_media_type where media_type_id = 'chemical/x-cdx'));
   insert into at_file_extension values(53, 'cdxml',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.chemdraw+xml'));
   insert into at_file_extension values(53, 'cdy',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.cinderella'));
   insert into at_file_extension values(53, 'cer',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkix-cert'));
   insert into at_file_extension values(53, 'cgm',         (select media_type_code from cwms_media_type where media_type_id = 'image/cgm'));
   insert into at_file_extension values(53, 'chat',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-chat'));
   insert into at_file_extension values(53, 'chm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-htmlhelp'));
   insert into at_file_extension values(53, 'chrt',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kchart'));
   insert into at_file_extension values(53, 'cif',         (select media_type_code from cwms_media_type where media_type_id = 'chemical/x-cif'));
   insert into at_file_extension values(53, 'cii',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.anser-web-certificate-issue-initiation'));
   insert into at_file_extension values(53, 'cil',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-artgalry'));
   insert into at_file_extension values(53, 'cla',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.claymore'));
   insert into at_file_extension values(53, 'class',       (select media_type_code from cwms_media_type where media_type_id = 'application/java-vm'));
   insert into at_file_extension values(53, 'clkk',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.crick.clicker.keyboard'));
   insert into at_file_extension values(53, 'clkp',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.crick.clicker.palette'));
   insert into at_file_extension values(53, 'clkt',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.crick.clicker.template'));
   insert into at_file_extension values(53, 'clkw',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.crick.clicker.wordbank'));
   insert into at_file_extension values(53, 'clkx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.crick.clicker'));
   insert into at_file_extension values(53, 'clp',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msclip'));
   insert into at_file_extension values(53, 'cmc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.cosmocaller'));
   insert into at_file_extension values(53, 'cmdf',        (select media_type_code from cwms_media_type where media_type_id = 'chemical/x-cmdf'));
   insert into at_file_extension values(53, 'cml',         (select media_type_code from cwms_media_type where media_type_id = 'chemical/x-cml'));
   insert into at_file_extension values(53, 'cmp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yellowriver-custom-menu'));
   insert into at_file_extension values(53, 'cmx',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-cmx'));
   insert into at_file_extension values(53, 'cod',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.rim.cod'));
   insert into at_file_extension values(53, 'com',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msdownload'));
   insert into at_file_extension values(53, 'conf',        (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'cpio',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-cpio'));
   insert into at_file_extension values(53, 'cpp',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'cpt',         (select media_type_code from cwms_media_type where media_type_id = 'application/mac-compactpro'));
   insert into at_file_extension values(53, 'crd',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-mscardfile'));
   insert into at_file_extension values(53, 'crl',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkix-crl'));
   insert into at_file_extension values(53, 'crt',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-x509-ca-cert'));
   insert into at_file_extension values(53, 'cryptonote',  (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.rig.cryptonote'));
   insert into at_file_extension values(53, 'csh',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-csh'));
   insert into at_file_extension values(53, 'csml',        (select media_type_code from cwms_media_type where media_type_id = 'chemical/x-csml'));
   insert into at_file_extension values(53, 'csp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.commonspace'));
   insert into at_file_extension values(53, 'css',         (select media_type_code from cwms_media_type where media_type_id = 'text/css'));
   insert into at_file_extension values(53, 'cst',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'csv',         (select media_type_code from cwms_media_type where media_type_id = 'text/csv'));
   insert into at_file_extension values(53, 'cu',          (select media_type_code from cwms_media_type where media_type_id = 'application/cu-seeme'));
   insert into at_file_extension values(53, 'curl',        (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.curl'));
   insert into at_file_extension values(53, 'cww',         (select media_type_code from cwms_media_type where media_type_id = 'application/prs.cww'));
   insert into at_file_extension values(53, 'cxt',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'cxx',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'dae',         (select media_type_code from cwms_media_type where media_type_id = 'model/vnd.collada+xml'));
   insert into at_file_extension values(53, 'daf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.daf'));
   insert into at_file_extension values(53, 'dataless',    (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fdsn.seed'));
   insert into at_file_extension values(53, 'davmount',    (select media_type_code from cwms_media_type where media_type_id = 'application/davmount+xml'));
   insert into at_file_extension values(53, 'dcr',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'dcurl',       (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.curl.dcurl'));
   insert into at_file_extension values(53, 'dd2',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oma.dd2+xml'));
   insert into at_file_extension values(53, 'ddd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujixerox.ddd'));
   insert into at_file_extension values(53, 'deb',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-debian-package'));
   insert into at_file_extension values(53, 'def',         (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'deploy',      (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'der',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-x509-ca-cert'));
   insert into at_file_extension values(53, 'dfac',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dreamfactory'));
   insert into at_file_extension values(53, 'dic',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'dir',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'dis',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.dis'));
   insert into at_file_extension values(53, 'dist',        (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'distz',       (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'djv',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.djvu'));
   insert into at_file_extension values(53, 'djvu',        (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.djvu'));
   insert into at_file_extension values(53, 'dll',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msdownload'));
   insert into at_file_extension values(53, 'dmg',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'dms',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'dna',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dna'));
   insert into at_file_extension values(53, 'doc',         (select media_type_code from cwms_media_type where media_type_id = 'application/msword'));
   insert into at_file_extension values(53, 'docm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-word.document.macroenabled.12'));
   insert into at_file_extension values(53, 'docx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'));
   insert into at_file_extension values(53, 'dot',         (select media_type_code from cwms_media_type where media_type_id = 'application/msword'));
   insert into at_file_extension values(53, 'dotm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-word.template.macroenabled.12'));
   insert into at_file_extension values(53, 'dotx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.wordprocessingml.template'));
   insert into at_file_extension values(53, 'dp',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.osgi.dp'));
   insert into at_file_extension values(53, 'dpg',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dpgraph'));
   insert into at_file_extension values(53, 'dra',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.dra'));
   insert into at_file_extension values(53, 'dsc',         (select media_type_code from cwms_media_type where media_type_id = 'text/prs.lines.tag'));
   insert into at_file_extension values(53, 'dssc',        (select media_type_code from cwms_media_type where media_type_id = 'application/dssc+der'));
   insert into at_file_extension values(53, 'dtb',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-dtbook+xml'));
   insert into at_file_extension values(53, 'dtd',         (select media_type_code from cwms_media_type where media_type_id = 'application/xml-dtd'));
   insert into at_file_extension values(53, 'dts',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.dts'));
   insert into at_file_extension values(53, 'dtshd',       (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.dts.hd'));
   insert into at_file_extension values(53, 'dump',        (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'dvi',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-dvi'));
   insert into at_file_extension values(53, 'dwf',         (select media_type_code from cwms_media_type where media_type_id = 'model/vnd.dwf'));
   insert into at_file_extension values(53, 'dwg',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dwg'));
   insert into at_file_extension values(53, 'dxf',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dxf'));
   insert into at_file_extension values(53, 'dxp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.spotfire.dxp'));
   insert into at_file_extension values(53, 'dxr',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'ecelp4800',   (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.nuera.ecelp4800'));
   insert into at_file_extension values(53, 'ecelp7470',   (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.nuera.ecelp7470'));
   insert into at_file_extension values(53, 'ecelp9600',   (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.nuera.ecelp9600'));
   insert into at_file_extension values(53, 'ecma',        (select media_type_code from cwms_media_type where media_type_id = 'application/ecmascript'));
   insert into at_file_extension values(53, 'edm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.novadigm.edm'));
   insert into at_file_extension values(53, 'edx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.novadigm.edx'));
   insert into at_file_extension values(53, 'efif',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.picsel'));
   insert into at_file_extension values(53, 'ei6',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.pg.osasli'));
   insert into at_file_extension values(53, 'elc',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'eml',         (select media_type_code from cwms_media_type where media_type_id = 'message/rfc822'));
   insert into at_file_extension values(53, 'emma',        (select media_type_code from cwms_media_type where media_type_id = 'application/emma+xml'));
   insert into at_file_extension values(53, 'eol',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.digital-winds'));
   insert into at_file_extension values(53, 'eot',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-fontobject'));
   insert into at_file_extension values(53, 'eps',         (select media_type_code from cwms_media_type where media_type_id = 'application/postscript'));
   insert into at_file_extension values(53, 'epub',        (select media_type_code from cwms_media_type where media_type_id = 'application/epub+zip'));
   insert into at_file_extension values(53, 'es3',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.eszigno3+xml'));
   insert into at_file_extension values(53, 'esf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.epson.esf'));
   insert into at_file_extension values(53, 'et3',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.eszigno3+xml'));
   insert into at_file_extension values(53, 'etx',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-setext'));
   insert into at_file_extension values(53, 'exe',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msdownload'));
   insert into at_file_extension values(53, 'exi',         (select media_type_code from cwms_media_type where media_type_id = 'application/exi'));
   insert into at_file_extension values(53, 'ext',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.novadigm.ext'));
   insert into at_file_extension values(53, 'ez',          (select media_type_code from cwms_media_type where media_type_id = 'application/andrew-inset'));
   insert into at_file_extension values(53, 'ez2',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ezpix-album'));
   insert into at_file_extension values(53, 'ez3',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ezpix-package'));
   insert into at_file_extension values(53, 'f',           (select media_type_code from cwms_media_type where media_type_id = 'text/x-fortran'));
   insert into at_file_extension values(53, 'f4v',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-f4v'));
   insert into at_file_extension values(53, 'f77',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-fortran'));
   insert into at_file_extension values(53, 'f90',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-fortran'));
   insert into at_file_extension values(53, 'fbs',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.fastbidsheet'));
   insert into at_file_extension values(53, 'fcs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.isac.fcs'));
   insert into at_file_extension values(53, 'fdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fdf'));
   insert into at_file_extension values(53, 'fe_launch',   (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.denovo.fcselayout-link'));
   insert into at_file_extension values(53, 'fg5',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujitsu.oasysgp'));
   insert into at_file_extension values(53, 'fgd',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'fh',          (select media_type_code from cwms_media_type where media_type_id = 'image/x-freehand'));
   insert into at_file_extension values(53, 'fh4',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-freehand'));
   insert into at_file_extension values(53, 'fh5',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-freehand'));
   insert into at_file_extension values(53, 'fh7',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-freehand'));
   insert into at_file_extension values(53, 'fhc',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-freehand'));
   insert into at_file_extension values(53, 'fig',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-xfig'));
   insert into at_file_extension values(53, 'fli',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-fli'));
   insert into at_file_extension values(53, 'flo',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.micrografx.flo'));
   insert into at_file_extension values(53, 'flv',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-flv'));
   insert into at_file_extension values(53, 'flw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kivio'));
   insert into at_file_extension values(53, 'flx',         (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.fmi.flexstor'));
   insert into at_file_extension values(53, 'fly',         (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.fly'));
   insert into at_file_extension values(53, 'fm',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.framemaker'));
   insert into at_file_extension values(53, 'fnc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.frogans.fnc'));
   insert into at_file_extension values(53, 'for',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-fortran'));
   insert into at_file_extension values(53, 'fpx',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.fpx'));
   insert into at_file_extension values(53, 'frame',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.framemaker'));
   insert into at_file_extension values(53, 'fsc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fsc.weblaunch'));
   insert into at_file_extension values(53, 'fst',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.fst'));
   insert into at_file_extension values(53, 'ftc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fluxtime.clip'));
   insert into at_file_extension values(53, 'fti',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.anser-web-funds-transfer-initiation'));
   insert into at_file_extension values(53, 'fvt',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.fvt'));
   insert into at_file_extension values(53, 'fxp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.adobe.fxp'));
   insert into at_file_extension values(53, 'fxpl',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.adobe.fxp'));
   insert into at_file_extension values(53, 'fzs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fuzzysheet'));
   insert into at_file_extension values(53, 'g2w',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geoplan'));
   insert into at_file_extension values(53, 'g3',          (select media_type_code from cwms_media_type where media_type_id = 'image/g3fax'));
   insert into at_file_extension values(53, 'g3w',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geospace'));
   insert into at_file_extension values(53, 'gac',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-account'));
   insert into at_file_extension values(53, 'gdl',         (select media_type_code from cwms_media_type where media_type_id = 'model/vnd.gdl'));
   insert into at_file_extension values(53, 'geo',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dynageo'));
   insert into at_file_extension values(53, 'gex',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geometry-explorer'));
   insert into at_file_extension values(53, 'ggb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geogebra.file'));
   insert into at_file_extension values(53, 'ggt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geogebra.tool'));
   insert into at_file_extension values(53, 'ghf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-help'));
   insert into at_file_extension values(53, 'gif',         (select media_type_code from cwms_media_type where media_type_id = 'image/gif'));
   insert into at_file_extension values(53, 'gim',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-identity-message'));
   insert into at_file_extension values(53, 'gmx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.gmx'));
   insert into at_file_extension values(53, 'gnumeric',    (select media_type_code from cwms_media_type where media_type_id = 'application/x-gnumeric'));
   insert into at_file_extension values(53, 'gph',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.flographit'));
   insert into at_file_extension values(53, 'gqf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.grafeq'));
   insert into at_file_extension values(53, 'gqs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.grafeq'));
   insert into at_file_extension values(53, 'gram',        (select media_type_code from cwms_media_type where media_type_id = 'application/srgs'));
   insert into at_file_extension values(53, 'gre',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geometry-explorer'));
   insert into at_file_extension values(53, 'grv',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-injector'));
   insert into at_file_extension values(53, 'grxml',       (select media_type_code from cwms_media_type where media_type_id = 'application/srgs+xml'));
   insert into at_file_extension values(53, 'gsf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-ghostscript'));
   insert into at_file_extension values(53, 'gtar',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-gtar'));
   insert into at_file_extension values(53, 'gtm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-tool-message'));
   insert into at_file_extension values(53, 'gtw',         (select media_type_code from cwms_media_type where media_type_id = 'model/vnd.gtw'));
   insert into at_file_extension values(53, 'gv',          (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.graphviz'));
   insert into at_file_extension values(53, 'gxt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.geonext'));
   insert into at_file_extension values(53, 'h',           (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'h261',        (select media_type_code from cwms_media_type where media_type_id = 'video/h261'));
   insert into at_file_extension values(53, 'h263',        (select media_type_code from cwms_media_type where media_type_id = 'video/h263'));
   insert into at_file_extension values(53, 'h264',        (select media_type_code from cwms_media_type where media_type_id = 'video/h264'));
   insert into at_file_extension values(53, 'hal',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hal+xml'));
   insert into at_file_extension values(53, 'hbci',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hbci'));
   insert into at_file_extension values(53, 'hdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-hdf'));
   insert into at_file_extension values(53, 'hh',          (select media_type_code from cwms_media_type where media_type_id = 'text/x-c'));
   insert into at_file_extension values(53, 'hlp',         (select media_type_code from cwms_media_type where media_type_id = 'application/winhlp'));
   insert into at_file_extension values(53, 'hpgl',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hp-hpgl'));
   insert into at_file_extension values(53, 'hpid',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hp-hpid'));
   insert into at_file_extension values(53, 'hps',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hp-hps'));
   insert into at_file_extension values(53, 'hqx',         (select media_type_code from cwms_media_type where media_type_id = 'application/mac-binhex40'));
   insert into at_file_extension values(53, 'htke',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kenameaapp'));
   insert into at_file_extension values(53, 'htm',         (select media_type_code from cwms_media_type where media_type_id = 'text/html'));
   insert into at_file_extension values(53, 'html',        (select media_type_code from cwms_media_type where media_type_id = 'text/html'));
   insert into at_file_extension values(53, 'hvd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.hv-dic'));
   insert into at_file_extension values(53, 'hvp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.hv-voice'));
   insert into at_file_extension values(53, 'hvs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.hv-script'));
   insert into at_file_extension values(53, 'i2g',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.intergeo'));
   insert into at_file_extension values(53, 'icc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.iccprofile'));
   insert into at_file_extension values(53, 'ice',         (select media_type_code from cwms_media_type where media_type_id = 'x-conference/x-cooltalk'));
   insert into at_file_extension values(53, 'icm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.iccprofile'));
   insert into at_file_extension values(53, 'ico',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-icon'));
   insert into at_file_extension values(53, 'ics',         (select media_type_code from cwms_media_type where media_type_id = 'text/calendar'));
   insert into at_file_extension values(53, 'ief',         (select media_type_code from cwms_media_type where media_type_id = 'image/ief'));
   insert into at_file_extension values(53, 'ifb',         (select media_type_code from cwms_media_type where media_type_id = 'text/calendar'));
   insert into at_file_extension values(53, 'ifm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.shana.informed.formdata'));
   insert into at_file_extension values(53, 'iges',        (select media_type_code from cwms_media_type where media_type_id = 'model/iges'));
   insert into at_file_extension values(53, 'igl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.igloader'));
   insert into at_file_extension values(53, 'igm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.insors.igm'));
   insert into at_file_extension values(53, 'igs',         (select media_type_code from cwms_media_type where media_type_id = 'model/iges'));
   insert into at_file_extension values(53, 'igx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.micrografx.igx'));
   insert into at_file_extension values(53, 'iif',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.shana.informed.interchange'));
   insert into at_file_extension values(53, 'imp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.accpac.simply.imp'));
   insert into at_file_extension values(53, 'ims',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-ims'));
   insert into at_file_extension values(53, 'in',          (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'ipfix',       (select media_type_code from cwms_media_type where media_type_id = 'application/ipfix'));
   insert into at_file_extension values(53, 'ipk',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.shana.informed.package'));
   insert into at_file_extension values(53, 'irm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ibm.rights-management'));
   insert into at_file_extension values(53, 'irp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.irepository.package+xml'));
   insert into at_file_extension values(53, 'iso',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'itp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.shana.informed.formtemplate'));
   insert into at_file_extension values(53, 'ivp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.immervision-ivp'));
   insert into at_file_extension values(53, 'ivu',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.immervision-ivu'));
   insert into at_file_extension values(53, 'jad',         (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.sun.j2me.app-descriptor'));
   insert into at_file_extension values(53, 'jam',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.jam'));
   insert into at_file_extension values(53, 'jar',         (select media_type_code from cwms_media_type where media_type_id = 'application/java-archive'));
   insert into at_file_extension values(53, 'java',        (select media_type_code from cwms_media_type where media_type_id = 'text/x-java-source'));
   insert into at_file_extension values(53, 'jisp',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.jisp'));
   insert into at_file_extension values(53, 'jlt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hp-jlyt'));
   insert into at_file_extension values(53, 'jnlp',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-java-jnlp-file'));
   insert into at_file_extension values(53, 'joda',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.joost.joda-archive'));
   insert into at_file_extension values(53, 'jpe',         (select media_type_code from cwms_media_type where media_type_id = 'image/jpeg'));
   insert into at_file_extension values(53, 'jpeg',        (select media_type_code from cwms_media_type where media_type_id = 'image/jpeg'));
   insert into at_file_extension values(53, 'jpg',         (select media_type_code from cwms_media_type where media_type_id = 'image/jpeg'));
   insert into at_file_extension values(53, 'jpgm',        (select media_type_code from cwms_media_type where media_type_id = 'video/jpm'));
   insert into at_file_extension values(53, 'jpgv',        (select media_type_code from cwms_media_type where media_type_id = 'video/jpeg'));
   insert into at_file_extension values(53, 'jpm',         (select media_type_code from cwms_media_type where media_type_id = 'video/jpm'));
   insert into at_file_extension values(53, 'js',          (select media_type_code from cwms_media_type where media_type_id = 'application/javascript'));
   insert into at_file_extension values(53, 'json',        (select media_type_code from cwms_media_type where media_type_id = 'application/json'));
   insert into at_file_extension values(53, 'kar',         (select media_type_code from cwms_media_type where media_type_id = 'audio/midi'));
   insert into at_file_extension values(53, 'karbon',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.karbon'));
   insert into at_file_extension values(53, 'kfo',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kformula'));
   insert into at_file_extension values(53, 'kia',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kidspiration'));
   insert into at_file_extension values(53, 'kml',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.google-earth.kml+xml'));
   insert into at_file_extension values(53, 'kmz',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.google-earth.kmz'));
   insert into at_file_extension values(53, 'kne',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kinar'));
   insert into at_file_extension values(53, 'knp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kinar'));
   insert into at_file_extension values(53, 'kon',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kontour'));
   insert into at_file_extension values(53, 'kpr',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kpresenter'));
   insert into at_file_extension values(53, 'kpt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kpresenter'));
   insert into at_file_extension values(53, 'ksp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kspread'));
   insert into at_file_extension values(53, 'ktr',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kahootz'));
   insert into at_file_extension values(53, 'ktx',         (select media_type_code from cwms_media_type where media_type_id = 'image/ktx'));
   insert into at_file_extension values(53, 'ktz',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kahootz'));
   insert into at_file_extension values(53, 'kwd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kword'));
   insert into at_file_extension values(53, 'kwt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kde.kword'));
   insert into at_file_extension values(53, 'lasxml',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.las.las+xml'));
   insert into at_file_extension values(53, 'latex',       (select media_type_code from cwms_media_type where media_type_id = 'application/x-latex'));
   insert into at_file_extension values(53, 'lbd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.llamagraphics.life-balance.desktop'));
   insert into at_file_extension values(53, 'lbe',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.llamagraphics.life-balance.exchange+xml'));
   insert into at_file_extension values(53, 'les',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hhe.lesson-player'));
   insert into at_file_extension values(53, 'lha',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'link66',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.route66.link66+xml'));
   insert into at_file_extension values(53, 'list',        (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'list3820',    (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ibm.modcap'));
   insert into at_file_extension values(53, 'listafp',     (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ibm.modcap'));
   insert into at_file_extension values(53, 'log',         (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'lostxml',     (select media_type_code from cwms_media_type where media_type_id = 'application/lost+xml'));
   insert into at_file_extension values(53, 'lrf',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'lrm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-lrm'));
   insert into at_file_extension values(53, 'ltf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.frogans.ltf'));
   insert into at_file_extension values(53, 'lvp',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.lucent.voice'));
   insert into at_file_extension values(53, 'lwp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-wordpro'));
   insert into at_file_extension values(53, 'lzh',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'm13',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msmediaview'));
   insert into at_file_extension values(53, 'm14',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msmediaview'));
   insert into at_file_extension values(53, 'm1v',         (select media_type_code from cwms_media_type where media_type_id = 'video/mpeg'));
   insert into at_file_extension values(53, 'm21',         (select media_type_code from cwms_media_type where media_type_id = 'application/mp21'));
   insert into at_file_extension values(53, 'm2a',         (select media_type_code from cwms_media_type where media_type_id = 'audio/mpeg'));
   insert into at_file_extension values(53, 'm2v',         (select media_type_code from cwms_media_type where media_type_id = 'video/mpeg'));
   insert into at_file_extension values(53, 'm3a',         (select media_type_code from cwms_media_type where media_type_id = 'audio/mpeg'));
   insert into at_file_extension values(53, 'm3u',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-mpegurl'));
   insert into at_file_extension values(53, 'm3u8',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.apple.mpegurl'));
   insert into at_file_extension values(53, 'm4u',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.mpegurl'));
   insert into at_file_extension values(53, 'm4v',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-m4v'));
   insert into at_file_extension values(53, 'ma',          (select media_type_code from cwms_media_type where media_type_id = 'application/mathematica'));
   insert into at_file_extension values(53, 'mads',        (select media_type_code from cwms_media_type where media_type_id = 'application/mads+xml'));
   insert into at_file_extension values(53, 'mag',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ecowin.chart'));
   insert into at_file_extension values(53, 'maker',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.framemaker'));
   insert into at_file_extension values(53, 'man',         (select media_type_code from cwms_media_type where media_type_id = 'text/troff'));
   insert into at_file_extension values(53, 'mathml',      (select media_type_code from cwms_media_type where media_type_id = 'application/mathml+xml'));
   insert into at_file_extension values(53, 'mb',          (select media_type_code from cwms_media_type where media_type_id = 'application/mathematica'));
   insert into at_file_extension values(53, 'mbk',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.mbk'));
   insert into at_file_extension values(53, 'mbox',        (select media_type_code from cwms_media_type where media_type_id = 'application/mbox'));
   insert into at_file_extension values(53, 'mc1',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.medcalcdata'));
   insert into at_file_extension values(53, 'mcd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mcd'));
   insert into at_file_extension values(53, 'mcurl',       (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.curl.mcurl'));
   insert into at_file_extension values(53, 'mdb',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msaccess'));
   insert into at_file_extension values(53, 'mdi',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.ms-modi'));
   insert into at_file_extension values(53, 'me',          (select media_type_code from cwms_media_type where media_type_id = 'text/troff'));
   insert into at_file_extension values(53, 'mesh',        (select media_type_code from cwms_media_type where media_type_id = 'model/mesh'));
   insert into at_file_extension values(53, 'meta4',       (select media_type_code from cwms_media_type where media_type_id = 'application/metalink4+xml'));
   insert into at_file_extension values(53, 'mets',        (select media_type_code from cwms_media_type where media_type_id = 'application/mets+xml'));
   insert into at_file_extension values(53, 'mfm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mfmp'));
   insert into at_file_extension values(53, 'mgp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.osgeo.mapguide.package'));
   insert into at_file_extension values(53, 'mgz',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.proteus.magazine'));
   insert into at_file_extension values(53, 'mid',         (select media_type_code from cwms_media_type where media_type_id = 'audio/midi'));
   insert into at_file_extension values(53, 'midi',        (select media_type_code from cwms_media_type where media_type_id = 'audio/midi'));
   insert into at_file_extension values(53, 'mif',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mif'));
   insert into at_file_extension values(53, 'mime',        (select media_type_code from cwms_media_type where media_type_id = 'message/rfc822'));
   insert into at_file_extension values(53, 'mj2',         (select media_type_code from cwms_media_type where media_type_id = 'video/mj2'));
   insert into at_file_extension values(53, 'mjp2',        (select media_type_code from cwms_media_type where media_type_id = 'video/mj2'));
   insert into at_file_extension values(53, 'mlp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dolby.mlp'));
   insert into at_file_extension values(53, 'mmd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.chipnuts.karaoke-mmd'));
   insert into at_file_extension values(53, 'mmf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.smaf'));
   insert into at_file_extension values(53, 'mmr',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.fujixerox.edmics-mmr'));
   insert into at_file_extension values(53, 'mny',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msmoney'));
   insert into at_file_extension values(53, 'mobi',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-mobipocket-ebook'));
   insert into at_file_extension values(53, 'mods',        (select media_type_code from cwms_media_type where media_type_id = 'application/mods+xml'));
   insert into at_file_extension values(53, 'mov',         (select media_type_code from cwms_media_type where media_type_id = 'video/quicktime'));
   insert into at_file_extension values(53, 'movie',       (select media_type_code from cwms_media_type where media_type_id = 'video/x-sgi-movie'));
   insert into at_file_extension values(53, 'mp2',         (select media_type_code from cwms_media_type where media_type_id = 'audio/mpeg'));
   insert into at_file_extension values(53, 'mp21',        (select media_type_code from cwms_media_type where media_type_id = 'application/mp21'));
   insert into at_file_extension values(53, 'mp2a',        (select media_type_code from cwms_media_type where media_type_id = 'audio/mpeg'));
   insert into at_file_extension values(53, 'mp3',         (select media_type_code from cwms_media_type where media_type_id = 'audio/mpeg'));
   insert into at_file_extension values(53, 'mp4',         (select media_type_code from cwms_media_type where media_type_id = 'video/mp4'));
   insert into at_file_extension values(53, 'mp4a',        (select media_type_code from cwms_media_type where media_type_id = 'audio/mp4'));
   insert into at_file_extension values(53, 'mp4s',        (select media_type_code from cwms_media_type where media_type_id = 'application/mp4'));
   insert into at_file_extension values(53, 'mp4v',        (select media_type_code from cwms_media_type where media_type_id = 'video/mp4'));
   insert into at_file_extension values(53, 'mpc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mophun.certificate'));
   insert into at_file_extension values(53, 'mpe',         (select media_type_code from cwms_media_type where media_type_id = 'video/mpeg'));
   insert into at_file_extension values(53, 'mpeg',        (select media_type_code from cwms_media_type where media_type_id = 'video/mpeg'));
   insert into at_file_extension values(53, 'mpg',         (select media_type_code from cwms_media_type where media_type_id = 'video/mpeg'));
   insert into at_file_extension values(53, 'mpg4',        (select media_type_code from cwms_media_type where media_type_id = 'video/mp4'));
   insert into at_file_extension values(53, 'mpga',        (select media_type_code from cwms_media_type where media_type_id = 'audio/mpeg'));
   insert into at_file_extension values(53, 'mpkg',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.apple.installer+xml'));
   insert into at_file_extension values(53, 'mpm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.blueice.multipass'));
   insert into at_file_extension values(53, 'mpn',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mophun.application'));
   insert into at_file_extension values(53, 'mpp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-project'));
   insert into at_file_extension values(53, 'mpt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-project'));
   insert into at_file_extension values(53, 'mpy',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ibm.minipay'));
   insert into at_file_extension values(53, 'mqy',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.mqy'));
   insert into at_file_extension values(53, 'mrc',         (select media_type_code from cwms_media_type where media_type_id = 'application/marc'));
   insert into at_file_extension values(53, 'mrcx',        (select media_type_code from cwms_media_type where media_type_id = 'application/marcxml+xml'));
   insert into at_file_extension values(53, 'ms',          (select media_type_code from cwms_media_type where media_type_id = 'text/troff'));
   insert into at_file_extension values(53, 'mscml',       (select media_type_code from cwms_media_type where media_type_id = 'application/mediaservercontrol+xml'));
   insert into at_file_extension values(53, 'mseed',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fdsn.mseed'));
   insert into at_file_extension values(53, 'mseq',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mseq'));
   insert into at_file_extension values(53, 'msf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.epson.msf'));
   insert into at_file_extension values(53, 'msh',         (select media_type_code from cwms_media_type where media_type_id = 'model/mesh'));
   insert into at_file_extension values(53, 'msi',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msdownload'));
   insert into at_file_extension values(53, 'msl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.msl'));
   insert into at_file_extension values(53, 'msty',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.muvee.style'));
   insert into at_file_extension values(53, 'mts',         (select media_type_code from cwms_media_type where media_type_id = 'model/vnd.mts'));
   insert into at_file_extension values(53, 'mus',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.musician'));
   insert into at_file_extension values(53, 'musicxml',    (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.recordare.musicxml+xml'));
   insert into at_file_extension values(53, 'mvb',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msmediaview'));
   insert into at_file_extension values(53, 'mwf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mfer'));
   insert into at_file_extension values(53, 'mxf',         (select media_type_code from cwms_media_type where media_type_id = 'application/mxf'));
   insert into at_file_extension values(53, 'mxl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.recordare.musicxml'));
   insert into at_file_extension values(53, 'mxml',        (select media_type_code from cwms_media_type where media_type_id = 'application/xv+xml'));
   insert into at_file_extension values(53, 'mxs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.triscape.mxs'));
   insert into at_file_extension values(53, 'mxu',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.mpegurl'));
   insert into at_file_extension values(53, 'n-gage',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.nokia.n-gage.symbian.install'));
   insert into at_file_extension values(53, 'n3',          (select media_type_code from cwms_media_type where media_type_id = 'text/n3'));
   insert into at_file_extension values(53, 'nb',          (select media_type_code from cwms_media_type where media_type_id = 'application/mathematica'));
   insert into at_file_extension values(53, 'nbp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wolfram.player'));
   insert into at_file_extension values(53, 'nc',          (select media_type_code from cwms_media_type where media_type_id = 'application/x-netcdf'));
   insert into at_file_extension values(53, 'ncx',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-dtbncx+xml'));
   insert into at_file_extension values(53, 'ngdat',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.nokia.n-gage.data'));
   insert into at_file_extension values(53, 'nlu',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.neurolanguage.nlu'));
   insert into at_file_extension values(53, 'nml',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.enliven'));
   insert into at_file_extension values(53, 'nnd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.noblenet-directory'));
   insert into at_file_extension values(53, 'nns',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.noblenet-sealer'));
   insert into at_file_extension values(53, 'nnw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.noblenet-web'));
   insert into at_file_extension values(53, 'npx',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.net-fpx'));
   insert into at_file_extension values(53, 'nsf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-notes'));
   insert into at_file_extension values(53, 'oa2',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujitsu.oasys2'));
   insert into at_file_extension values(53, 'oa3',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujitsu.oasys3'));
   insert into at_file_extension values(53, 'oas',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujitsu.oasys'));
   insert into at_file_extension values(53, 'obd',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msbinder'));
   insert into at_file_extension values(53, 'oda',         (select media_type_code from cwms_media_type where media_type_id = 'application/oda'));
   insert into at_file_extension values(53, 'odb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.database'));
   insert into at_file_extension values(53, 'odc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.chart'));
   insert into at_file_extension values(53, 'odf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.formula'));
   insert into at_file_extension values(53, 'odft',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.formula-template'));
   insert into at_file_extension values(53, 'odg',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.graphics'));
   insert into at_file_extension values(53, 'odi',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.image'));
   insert into at_file_extension values(53, 'odm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.text-master'));
   insert into at_file_extension values(53, 'odp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.presentation'));
   insert into at_file_extension values(53, 'ods',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.spreadsheet'));
   insert into at_file_extension values(53, 'odt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.text'));
   insert into at_file_extension values(53, 'oga',         (select media_type_code from cwms_media_type where media_type_id = 'audio/ogg'));
   insert into at_file_extension values(53, 'ogg',         (select media_type_code from cwms_media_type where media_type_id = 'audio/ogg'));
   insert into at_file_extension values(53, 'ogv',         (select media_type_code from cwms_media_type where media_type_id = 'video/ogg'));
   insert into at_file_extension values(53, 'ogx',         (select media_type_code from cwms_media_type where media_type_id = 'application/ogg'));
   insert into at_file_extension values(53, 'onepkg',      (select media_type_code from cwms_media_type where media_type_id = 'application/onenote'));
   insert into at_file_extension values(53, 'onetmp',      (select media_type_code from cwms_media_type where media_type_id = 'application/onenote'));
   insert into at_file_extension values(53, 'onetoc',      (select media_type_code from cwms_media_type where media_type_id = 'application/onenote'));
   insert into at_file_extension values(53, 'onetoc2',     (select media_type_code from cwms_media_type where media_type_id = 'application/onenote'));
   insert into at_file_extension values(53, 'opf',         (select media_type_code from cwms_media_type where media_type_id = 'application/oebps-package+xml'));
   insert into at_file_extension values(53, 'oprc',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.palm'));
   insert into at_file_extension values(53, 'org',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-organizer'));
   insert into at_file_extension values(53, 'osf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.openscoreformat'));
   insert into at_file_extension values(53, 'osfpvg',      (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.openscoreformat.osfpvg+xml'));
   insert into at_file_extension values(53, 'otc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.chart-template'));
   insert into at_file_extension values(53, 'otf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-otf'));
   insert into at_file_extension values(53, 'otg',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.graphics-template'));
   insert into at_file_extension values(53, 'oth',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.text-web'));
   insert into at_file_extension values(53, 'oti',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.image-template'));
   insert into at_file_extension values(53, 'otp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.presentation-template'));
   insert into at_file_extension values(53, 'ots',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.spreadsheet-template'));
   insert into at_file_extension values(53, 'ott',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.oasis.opendocument.text-template'));
   insert into at_file_extension values(53, 'oxt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openofficeorg.extension'));
   insert into at_file_extension values(53, 'p',           (select media_type_code from cwms_media_type where media_type_id = 'text/x-pascal'));
   insert into at_file_extension values(53, 'p10',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkcs10'));
   insert into at_file_extension values(53, 'p12',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-pkcs12'));
   insert into at_file_extension values(53, 'p7b',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-pkcs7-certificates'));
   insert into at_file_extension values(53, 'p7c',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkcs7-mime'));
   insert into at_file_extension values(53, 'p7m',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkcs7-mime'));
   insert into at_file_extension values(53, 'p7r',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-pkcs7-certreqresp'));
   insert into at_file_extension values(53, 'p7s',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkcs7-signature'));
   insert into at_file_extension values(53, 'p8',          (select media_type_code from cwms_media_type where media_type_id = 'application/pkcs8'));
   insert into at_file_extension values(53, 'pas',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-pascal'));
   insert into at_file_extension values(53, 'paw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.pawaafile'));
   insert into at_file_extension values(53, 'pbd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.powerbuilder6'));
   insert into at_file_extension values(53, 'pbm',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-portable-bitmap'));
   insert into at_file_extension values(53, 'pcf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-pcf'));
   insert into at_file_extension values(53, 'pcl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hp-pcl'));
   insert into at_file_extension values(53, 'pclxl',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hp-pclxl'));
   insert into at_file_extension values(53, 'pct',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-pict'));
   insert into at_file_extension values(53, 'pcurl',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.curl.pcurl'));
   insert into at_file_extension values(53, 'pcx',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-pcx'));
   insert into at_file_extension values(53, 'pdb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.palm'));
   insert into at_file_extension values(53, 'pdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/pdf'));
   insert into at_file_extension values(53, 'pfa',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-type1'));
   insert into at_file_extension values(53, 'pfb',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-type1'));
   insert into at_file_extension values(53, 'pfm',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-type1'));
   insert into at_file_extension values(53, 'pfr',         (select media_type_code from cwms_media_type where media_type_id = 'application/font-tdpfr'));
   insert into at_file_extension values(53, 'pfx',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-pkcs12'));
   insert into at_file_extension values(53, 'pgm',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-portable-graymap'));
   insert into at_file_extension values(53, 'pgn',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-chess-pgn'));
   insert into at_file_extension values(53, 'pgp',         (select media_type_code from cwms_media_type where media_type_id = 'application/pgp-encrypted'));
   insert into at_file_extension values(53, 'pic',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-pict'));
   insert into at_file_extension values(53, 'pkg',         (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'pki',         (select media_type_code from cwms_media_type where media_type_id = 'application/pkixcmp'));
   insert into at_file_extension values(53, 'pkipath',     (select media_type_code from cwms_media_type where media_type_id = 'application/pkix-pkipath'));
   insert into at_file_extension values(53, 'plb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.3gpp.pic-bw-large'));
   insert into at_file_extension values(53, 'plc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.plc'));
   insert into at_file_extension values(53, 'plf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.pocketlearn'));
   insert into at_file_extension values(53, 'pls',         (select media_type_code from cwms_media_type where media_type_id = 'application/pls+xml'));
   insert into at_file_extension values(53, 'pml',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ctc-posml'));
   insert into at_file_extension values(53, 'png',         (select media_type_code from cwms_media_type where media_type_id = 'image/png'));
   insert into at_file_extension values(53, 'pnm',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-portable-anymap'));
   insert into at_file_extension values(53, 'portpkg',     (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.macports.portpkg'));
   insert into at_file_extension values(53, 'pot',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint'));
   insert into at_file_extension values(53, 'potm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint.template.macroenabled.12'));
   insert into at_file_extension values(53, 'potx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.presentationml.template'));
   insert into at_file_extension values(53, 'ppam',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint.addin.macroenabled.12'));
   insert into at_file_extension values(53, 'ppd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.cups-ppd'));
   insert into at_file_extension values(53, 'ppm',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-portable-pixmap'));
   insert into at_file_extension values(53, 'pps',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint'));
   insert into at_file_extension values(53, 'ppsm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint.slideshow.macroenabled.12'));
   insert into at_file_extension values(53, 'ppsx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.presentationml.slideshow'));
   insert into at_file_extension values(53, 'ppt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint'));
   insert into at_file_extension values(53, 'pptm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint.presentation.macroenabled.12'));
   insert into at_file_extension values(53, 'pptx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'));
   insert into at_file_extension values(53, 'pqa',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.palm'));
   insert into at_file_extension values(53, 'prc',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-mobipocket-ebook'));
   insert into at_file_extension values(53, 'pre',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-freelance'));
   insert into at_file_extension values(53, 'prf',         (select media_type_code from cwms_media_type where media_type_id = 'application/pics-rules'));
   insert into at_file_extension values(53, 'ps',          (select media_type_code from cwms_media_type where media_type_id = 'application/postscript'));
   insert into at_file_extension values(53, 'psb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.3gpp.pic-bw-small'));
   insert into at_file_extension values(53, 'psd',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.adobe.photoshop'));
   insert into at_file_extension values(53, 'psf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-linux-psf'));
   insert into at_file_extension values(53, 'pskcxml',     (select media_type_code from cwms_media_type where media_type_id = 'application/pskc+xml'));
   insert into at_file_extension values(53, 'ptid',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.pvi.ptid1'));
   insert into at_file_extension values(53, 'pub',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-mspublisher'));
   insert into at_file_extension values(53, 'pvb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.3gpp.pic-bw-var'));
   insert into at_file_extension values(53, 'pwn',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.3m.post-it-notes'));
   insert into at_file_extension values(53, 'pya',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.ms-playready.media.pya'));
   insert into at_file_extension values(53, 'pyv',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.ms-playready.media.pyv'));
   insert into at_file_extension values(53, 'qam',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.epson.quickanime'));
   insert into at_file_extension values(53, 'qbo',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.intu.qbo'));
   insert into at_file_extension values(53, 'qfx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.intu.qfx'));
   insert into at_file_extension values(53, 'qps',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.publishare-delta-tree'));
   insert into at_file_extension values(53, 'qt',          (select media_type_code from cwms_media_type where media_type_id = 'video/quicktime'));
   insert into at_file_extension values(53, 'qwd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.quark.quarkxpress'));
   insert into at_file_extension values(53, 'qwt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.quark.quarkxpress'));
   insert into at_file_extension values(53, 'qxb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.quark.quarkxpress'));
   insert into at_file_extension values(53, 'qxd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.quark.quarkxpress'));
   insert into at_file_extension values(53, 'qxl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.quark.quarkxpress'));
   insert into at_file_extension values(53, 'qxt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.quark.quarkxpress'));
   insert into at_file_extension values(53, 'ra',          (select media_type_code from cwms_media_type where media_type_id = 'audio/x-pn-realaudio'));
   insert into at_file_extension values(53, 'ram',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-pn-realaudio'));
   insert into at_file_extension values(53, 'rar',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-rar-compressed'));
   insert into at_file_extension values(53, 'ras',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-cmu-raster'));
   insert into at_file_extension values(53, 'rcprofile',   (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ipunplugged.rcprofile'));
   insert into at_file_extension values(53, 'rdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/rdf+xml'));
   insert into at_file_extension values(53, 'rdz',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.data-vision.rdz'));
   insert into at_file_extension values(53, 'rep',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.businessobjects'));
   insert into at_file_extension values(53, 'res',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-dtbresource+xml'));
   insert into at_file_extension values(53, 'rgb',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-rgb'));
   insert into at_file_extension values(53, 'rif',         (select media_type_code from cwms_media_type where media_type_id = 'application/reginfo+xml'));
   insert into at_file_extension values(53, 'rip',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.rip'));
   insert into at_file_extension values(53, 'rl',          (select media_type_code from cwms_media_type where media_type_id = 'application/resource-lists+xml'));
   insert into at_file_extension values(53, 'rlc',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.fujixerox.edmics-rlc'));
   insert into at_file_extension values(53, 'rld',         (select media_type_code from cwms_media_type where media_type_id = 'application/resource-lists-diff+xml'));
   insert into at_file_extension values(53, 'rm',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.rn-realmedia'));
   insert into at_file_extension values(53, 'rmi',         (select media_type_code from cwms_media_type where media_type_id = 'audio/midi'));
   insert into at_file_extension values(53, 'rmp',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-pn-realaudio-plugin'));
   insert into at_file_extension values(53, 'rms',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.jcp.javame.midlet-rms'));
   insert into at_file_extension values(53, 'rnc',         (select media_type_code from cwms_media_type where media_type_id = 'application/relax-ng-compact-syntax'));
   insert into at_file_extension values(53, 'roff',        (select media_type_code from cwms_media_type where media_type_id = 'text/troff'));
   insert into at_file_extension values(53, 'rp9',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.cloanto.rp9'));
   insert into at_file_extension values(53, 'rpss',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.nokia.radio-presets'));
   insert into at_file_extension values(53, 'rpst',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.nokia.radio-preset'));
   insert into at_file_extension values(53, 'rq',          (select media_type_code from cwms_media_type where media_type_id = 'application/sparql-query'));
   insert into at_file_extension values(53, 'rs',          (select media_type_code from cwms_media_type where media_type_id = 'application/rls-services+xml'));
   insert into at_file_extension values(53, 'rsd',         (select media_type_code from cwms_media_type where media_type_id = 'application/rsd+xml'));
   insert into at_file_extension values(53, 'rss',         (select media_type_code from cwms_media_type where media_type_id = 'application/rss+xml'));
   insert into at_file_extension values(53, 'rtf',         (select media_type_code from cwms_media_type where media_type_id = 'application/rtf'));
   insert into at_file_extension values(53, 'rtx',         (select media_type_code from cwms_media_type where media_type_id = 'text/richtext'));
   insert into at_file_extension values(53, 's',           (select media_type_code from cwms_media_type where media_type_id = 'text/x-asm'));
   insert into at_file_extension values(53, 'saf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.smaf-audio'));
   insert into at_file_extension values(53, 'sbml',        (select media_type_code from cwms_media_type where media_type_id = 'application/sbml+xml'));
   insert into at_file_extension values(53, 'sc',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ibm.secure-container'));
   insert into at_file_extension values(53, 'scd',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msschedule'));
   insert into at_file_extension values(53, 'scm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.lotus-screencam'));
   insert into at_file_extension values(53, 'scq',         (select media_type_code from cwms_media_type where media_type_id = 'application/scvp-cv-request'));
   insert into at_file_extension values(53, 'scs',         (select media_type_code from cwms_media_type where media_type_id = 'application/scvp-cv-response'));
   insert into at_file_extension values(53, 'scurl',       (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.curl.scurl'));
   insert into at_file_extension values(53, 'sda',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.draw'));
   insert into at_file_extension values(53, 'sdc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.calc'));
   insert into at_file_extension values(53, 'sdd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.impress'));
   insert into at_file_extension values(53, 'sdkd',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.solent.sdkm+xml'));
   insert into at_file_extension values(53, 'sdkm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.solent.sdkm+xml'));
   insert into at_file_extension values(53, 'sdp',         (select media_type_code from cwms_media_type where media_type_id = 'application/sdp'));
   insert into at_file_extension values(53, 'sdw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.writer'));
   insert into at_file_extension values(53, 'see',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.seemail'));
   insert into at_file_extension values(53, 'seed',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fdsn.seed'));
   insert into at_file_extension values(53, 'sema',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sema'));
   insert into at_file_extension values(53, 'semd',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.semd'));
   insert into at_file_extension values(53, 'semf',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.semf'));
   insert into at_file_extension values(53, 'ser',         (select media_type_code from cwms_media_type where media_type_id = 'application/java-serialized-object'));
   insert into at_file_extension values(53, 'setpay',      (select media_type_code from cwms_media_type where media_type_id = 'application/set-payment-initiation'));
   insert into at_file_extension values(53, 'setreg',      (select media_type_code from cwms_media_type where media_type_id = 'application/set-registration-initiation'));
   insert into at_file_extension values(53, 'sfd-hdstx',   (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hydrostatix.sof-data'));
   insert into at_file_extension values(53, 'sfs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.spotfire.sfs'));
   insert into at_file_extension values(53, 'sgl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.writer-global'));
   insert into at_file_extension values(53, 'sgm',         (select media_type_code from cwms_media_type where media_type_id = 'text/sgml'));
   insert into at_file_extension values(53, 'sgml',        (select media_type_code from cwms_media_type where media_type_id = 'text/sgml'));
   insert into at_file_extension values(53, 'sh',          (select media_type_code from cwms_media_type where media_type_id = 'application/x-sh'));
   insert into at_file_extension values(53, 'shar',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-shar'));
   insert into at_file_extension values(53, 'shf',         (select media_type_code from cwms_media_type where media_type_id = 'application/shf+xml'));
   insert into at_file_extension values(53, 'sig',         (select media_type_code from cwms_media_type where media_type_id = 'application/pgp-signature'));
   insert into at_file_extension values(53, 'silo',        (select media_type_code from cwms_media_type where media_type_id = 'model/mesh'));
   insert into at_file_extension values(53, 'sis',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.symbian.install'));
   insert into at_file_extension values(53, 'sisx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.symbian.install'));
   insert into at_file_extension values(53, 'sit',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-stuffit'));
   insert into at_file_extension values(53, 'sitx',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-stuffitx'));
   insert into at_file_extension values(53, 'skd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.koan'));
   insert into at_file_extension values(53, 'skm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.koan'));
   insert into at_file_extension values(53, 'skp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.koan'));
   insert into at_file_extension values(53, 'skt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.koan'));
   insert into at_file_extension values(53, 'sldm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-powerpoint.slide.macroenabled.12'));
   insert into at_file_extension values(53, 'sldx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.presentationml.slide'));
   insert into at_file_extension values(53, 'slt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.epson.salt'));
   insert into at_file_extension values(53, 'sm',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stepmania.stepchart'));
   insert into at_file_extension values(53, 'smf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.math'));
   insert into at_file_extension values(53, 'smi',         (select media_type_code from cwms_media_type where media_type_id = 'application/smil+xml'));
   insert into at_file_extension values(53, 'smil',        (select media_type_code from cwms_media_type where media_type_id = 'application/smil+xml'));
   insert into at_file_extension values(53, 'snd',         (select media_type_code from cwms_media_type where media_type_id = 'audio/basic'));
   insert into at_file_extension values(53, 'snf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-snf'));
   insert into at_file_extension values(53, 'so',          (select media_type_code from cwms_media_type where media_type_id = 'application/octet-stream'));
   insert into at_file_extension values(53, 'spc',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-pkcs7-certificates'));
   insert into at_file_extension values(53, 'spf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.yamaha.smaf-phrase'));
   insert into at_file_extension values(53, 'spl',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-futuresplash'));
   insert into at_file_extension values(53, 'spot',        (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.in3d.spot'));
   insert into at_file_extension values(53, 'spp',         (select media_type_code from cwms_media_type where media_type_id = 'application/scvp-vp-response'));
   insert into at_file_extension values(53, 'spq',         (select media_type_code from cwms_media_type where media_type_id = 'application/scvp-vp-request'));
   insert into at_file_extension values(53, 'spx',         (select media_type_code from cwms_media_type where media_type_id = 'audio/ogg'));
   insert into at_file_extension values(53, 'src',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-wais-source'));
   insert into at_file_extension values(53, 'sru',         (select media_type_code from cwms_media_type where media_type_id = 'application/sru+xml'));
   insert into at_file_extension values(53, 'srx',         (select media_type_code from cwms_media_type where media_type_id = 'application/sparql-results+xml'));
   insert into at_file_extension values(53, 'sse',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.kodak-descriptor'));
   insert into at_file_extension values(53, 'ssf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.epson.ssf'));
   insert into at_file_extension values(53, 'ssml',        (select media_type_code from cwms_media_type where media_type_id = 'application/ssml+xml'));
   insert into at_file_extension values(53, 'st',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sailingtracker.track'));
   insert into at_file_extension values(53, 'stc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.calc.template'));
   insert into at_file_extension values(53, 'std',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.draw.template'));
   insert into at_file_extension values(53, 'stf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wt.stf'));
   insert into at_file_extension values(53, 'sti',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.impress.template'));
   insert into at_file_extension values(53, 'stk',         (select media_type_code from cwms_media_type where media_type_id = 'application/hyperstudio'));
   insert into at_file_extension values(53, 'stl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-pki.stl'));
   insert into at_file_extension values(53, 'str',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.pg.format'));
   insert into at_file_extension values(53, 'stw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.writer.template'));
   insert into at_file_extension values(53, 'sub',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dvb.subtitle'));
   insert into at_file_extension values(53, 'sus',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sus-calendar'));
   insert into at_file_extension values(53, 'susp',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sus-calendar'));
   insert into at_file_extension values(53, 'sv4cpio',     (select media_type_code from cwms_media_type where media_type_id = 'application/x-sv4cpio'));
   insert into at_file_extension values(53, 'sv4crc',      (select media_type_code from cwms_media_type where media_type_id = 'application/x-sv4crc'));
   insert into at_file_extension values(53, 'svc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dvb.service'));
   insert into at_file_extension values(53, 'svd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.svd'));
   insert into at_file_extension values(53, 'svg',         (select media_type_code from cwms_media_type where media_type_id = 'image/svg+xml'));
   insert into at_file_extension values(53, 'svgz',        (select media_type_code from cwms_media_type where media_type_id = 'image/svg+xml'));
   insert into at_file_extension values(53, 'swa',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'swf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-shockwave-flash'));
   insert into at_file_extension values(53, 'swi',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.aristanetworks.swi'));
   insert into at_file_extension values(53, 'sxc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.calc'));
   insert into at_file_extension values(53, 'sxd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.draw'));
   insert into at_file_extension values(53, 'sxg',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.writer.global'));
   insert into at_file_extension values(53, 'sxi',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.impress'));
   insert into at_file_extension values(53, 'sxm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.math'));
   insert into at_file_extension values(53, 'sxw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.sun.xml.writer'));
   insert into at_file_extension values(53, 't',           (select media_type_code from cwms_media_type where media_type_id = 'text/troff'));
   insert into at_file_extension values(53, 'tao',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.tao.intent-module-archive'));
   insert into at_file_extension values(53, 'tar',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-tar'));
   insert into at_file_extension values(53, 'tcap',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.3gpp2.tcap'));
   insert into at_file_extension values(53, 'tcl',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-tcl'));
   insert into at_file_extension values(53, 'teacher',     (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.smart.teacher'));
   insert into at_file_extension values(53, 'tei',         (select media_type_code from cwms_media_type where media_type_id = 'application/tei+xml'));
   insert into at_file_extension values(53, 'teicorpus',   (select media_type_code from cwms_media_type where media_type_id = 'application/tei+xml'));
   insert into at_file_extension values(53, 'tex',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-tex'));
   insert into at_file_extension values(53, 'texi',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-texinfo'));
   insert into at_file_extension values(53, 'texinfo',     (select media_type_code from cwms_media_type where media_type_id = 'application/x-texinfo'));
   insert into at_file_extension values(53, 'text',        (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'tfi',         (select media_type_code from cwms_media_type where media_type_id = 'application/thraud+xml'));
   insert into at_file_extension values(53, 'tfm',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-tex-tfm'));
   insert into at_file_extension values(53, 'thmx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-officetheme'));
   insert into at_file_extension values(53, 'tif',         (select media_type_code from cwms_media_type where media_type_id = 'image/tiff'));
   insert into at_file_extension values(53, 'tiff',        (select media_type_code from cwms_media_type where media_type_id = 'image/tiff'));
   insert into at_file_extension values(53, 'tmo',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.tmobile-livetv'));
   insert into at_file_extension values(53, 'torrent',     (select media_type_code from cwms_media_type where media_type_id = 'application/x-bittorrent'));
   insert into at_file_extension values(53, 'tpl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-tool-template'));
   insert into at_file_extension values(53, 'tpt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.trid.tpt'));
   insert into at_file_extension values(53, 'tr',          (select media_type_code from cwms_media_type where media_type_id = 'text/troff'));
   insert into at_file_extension values(53, 'tra',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.trueapp'));
   insert into at_file_extension values(53, 'trm',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msterminal'));
   insert into at_file_extension values(53, 'tsd',         (select media_type_code from cwms_media_type where media_type_id = 'application/timestamped-data'));
   insert into at_file_extension values(53, 'tsv',         (select media_type_code from cwms_media_type where media_type_id = 'text/tab-separated-values'));
   insert into at_file_extension values(53, 'ttc',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-ttf'));
   insert into at_file_extension values(53, 'ttf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-ttf'));
   insert into at_file_extension values(53, 'ttl',         (select media_type_code from cwms_media_type where media_type_id = 'text/turtle'));
   insert into at_file_extension values(53, 'twd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.simtech-mindmapper'));
   insert into at_file_extension values(53, 'twds',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.simtech-mindmapper'));
   insert into at_file_extension values(53, 'txd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.genomatix.tuxedo'));
   insert into at_file_extension values(53, 'txf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mobius.txf'));
   insert into at_file_extension values(53, 'txt',         (select media_type_code from cwms_media_type where media_type_id = 'text/plain'));
   insert into at_file_extension values(53, 'u32',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-authorware-bin'));
   insert into at_file_extension values(53, 'udeb',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-debian-package'));
   insert into at_file_extension values(53, 'ufd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ufdl'));
   insert into at_file_extension values(53, 'ufdl',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ufdl'));
   insert into at_file_extension values(53, 'umj',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.umajin'));
   insert into at_file_extension values(53, 'unityweb',    (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.unity'));
   insert into at_file_extension values(53, 'uoml',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.uoml+xml'));
   insert into at_file_extension values(53, 'uri',         (select media_type_code from cwms_media_type where media_type_id = 'text/uri-list'));
   insert into at_file_extension values(53, 'uris',        (select media_type_code from cwms_media_type where media_type_id = 'text/uri-list'));
   insert into at_file_extension values(53, 'urls',        (select media_type_code from cwms_media_type where media_type_id = 'text/uri-list'));
   insert into at_file_extension values(53, 'ustar',       (select media_type_code from cwms_media_type where media_type_id = 'application/x-ustar'));
   insert into at_file_extension values(53, 'utz',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.uiq.theme'));
   insert into at_file_extension values(53, 'uu',          (select media_type_code from cwms_media_type where media_type_id = 'text/x-uuencode'));
   insert into at_file_extension values(53, 'uva',         (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.dece.audio'));
   insert into at_file_extension values(53, 'uvd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.data'));
   insert into at_file_extension values(53, 'uvf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.data'));
   insert into at_file_extension values(53, 'uvg',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dece.graphic'));
   insert into at_file_extension values(53, 'uvh',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.hd'));
   insert into at_file_extension values(53, 'uvi',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dece.graphic'));
   insert into at_file_extension values(53, 'uvm',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.mobile'));
   insert into at_file_extension values(53, 'uvp',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.pd'));
   insert into at_file_extension values(53, 'uvs',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.sd'));
   insert into at_file_extension values(53, 'uvt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.ttml+xml'));
   insert into at_file_extension values(53, 'uvu',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.uvvu.mp4'));
   insert into at_file_extension values(53, 'uvv',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.video'));
   insert into at_file_extension values(53, 'uvva',        (select media_type_code from cwms_media_type where media_type_id = 'audio/vnd.dece.audio'));
   insert into at_file_extension values(53, 'uvvd',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.data'));
   insert into at_file_extension values(53, 'uvvf',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.data'));
   insert into at_file_extension values(53, 'uvvg',        (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dece.graphic'));
   insert into at_file_extension values(53, 'uvvh',        (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.hd'));
   insert into at_file_extension values(53, 'uvvi',        (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.dece.graphic'));
   insert into at_file_extension values(53, 'uvvm',        (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.mobile'));
   insert into at_file_extension values(53, 'uvvp',        (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.pd'));
   insert into at_file_extension values(53, 'uvvs',        (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.sd'));
   insert into at_file_extension values(53, 'uvvt',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.ttml+xml'));
   insert into at_file_extension values(53, 'uvvu',        (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.uvvu.mp4'));
   insert into at_file_extension values(53, 'uvvv',        (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.dece.video'));
   insert into at_file_extension values(53, 'uvvx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.unspecified'));
   insert into at_file_extension values(53, 'uvx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.dece.unspecified'));
   insert into at_file_extension values(53, 'vcd',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-cdlink'));
   insert into at_file_extension values(53, 'vcf',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-vcard'));
   insert into at_file_extension values(53, 'vcg',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.groove-vcard'));
   insert into at_file_extension values(53, 'vcs',         (select media_type_code from cwms_media_type where media_type_id = 'text/x-vcalendar'));
   insert into at_file_extension values(53, 'vcx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.vcx'));
   insert into at_file_extension values(53, 'vis',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.visionary'));
   insert into at_file_extension values(53, 'viv',         (select media_type_code from cwms_media_type where media_type_id = 'video/vnd.vivo'));
   insert into at_file_extension values(53, 'vor',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.stardivision.writer'));
   insert into at_file_extension values(53, 'vox',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-authorware-bin'));
   insert into at_file_extension values(53, 'vrml',        (select media_type_code from cwms_media_type where media_type_id = 'model/vrml'));
   insert into at_file_extension values(53, 'vsd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.visio'));
   insert into at_file_extension values(53, 'vsf',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.vsf'));
   insert into at_file_extension values(53, 'vss',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.visio'));
   insert into at_file_extension values(53, 'vst',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.visio'));
   insert into at_file_extension values(53, 'vsw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.visio'));
   insert into at_file_extension values(53, 'vtu',         (select media_type_code from cwms_media_type where media_type_id = 'model/vnd.vtu'));
   insert into at_file_extension values(53, 'vxml',        (select media_type_code from cwms_media_type where media_type_id = 'application/voicexml+xml'));
   insert into at_file_extension values(53, 'w3d',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-director'));
   insert into at_file_extension values(53, 'wad',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-doom'));
   insert into at_file_extension values(53, 'wav',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-wav'));
   insert into at_file_extension values(53, 'wax',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-ms-wax'));
   insert into at_file_extension values(53, 'wbmp',        (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.wap.wbmp'));
   insert into at_file_extension values(53, 'wbs',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.criticaltools.wbs+xml'));
   insert into at_file_extension values(53, 'wbxml',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wap.wbxml'));
   insert into at_file_extension values(53, 'wcm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-works'));
   insert into at_file_extension values(53, 'wdb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-works'));
   insert into at_file_extension values(53, 'weba',        (select media_type_code from cwms_media_type where media_type_id = 'audio/webm'));
   insert into at_file_extension values(53, 'webm',        (select media_type_code from cwms_media_type where media_type_id = 'video/webm'));
   insert into at_file_extension values(53, 'webp',        (select media_type_code from cwms_media_type where media_type_id = 'image/webp'));
   insert into at_file_extension values(53, 'wg',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.pmi.widget'));
   insert into at_file_extension values(53, 'wgt',         (select media_type_code from cwms_media_type where media_type_id = 'application/widget'));
   insert into at_file_extension values(53, 'wks',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-works'));
   insert into at_file_extension values(53, 'wm',          (select media_type_code from cwms_media_type where media_type_id = 'video/x-ms-wm'));
   insert into at_file_extension values(53, 'wma',         (select media_type_code from cwms_media_type where media_type_id = 'audio/x-ms-wma'));
   insert into at_file_extension values(53, 'wmd',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-ms-wmd'));
   insert into at_file_extension values(53, 'wmf',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-msmetafile'));
   insert into at_file_extension values(53, 'wml',         (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.wap.wml'));
   insert into at_file_extension values(53, 'wmlc',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wap.wmlc'));
   insert into at_file_extension values(53, 'wmls',        (select media_type_code from cwms_media_type where media_type_id = 'text/vnd.wap.wmlscript'));
   insert into at_file_extension values(53, 'wmlsc',       (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wap.wmlscriptc'));
   insert into at_file_extension values(53, 'wmv',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-ms-wmv'));
   insert into at_file_extension values(53, 'wmx',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-ms-wmx'));
   insert into at_file_extension values(53, 'wmz',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-ms-wmz'));
   insert into at_file_extension values(53, 'woff',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-font-woff'));
   insert into at_file_extension values(53, 'wpd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wordperfect'));
   insert into at_file_extension values(53, 'wpl',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-wpl'));
   insert into at_file_extension values(53, 'wps',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-works'));
   insert into at_file_extension values(53, 'wqd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.wqd'));
   insert into at_file_extension values(53, 'wri',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-mswrite'));
   insert into at_file_extension values(53, 'wrl',         (select media_type_code from cwms_media_type where media_type_id = 'model/vrml'));
   insert into at_file_extension values(53, 'wsdl',        (select media_type_code from cwms_media_type where media_type_id = 'application/wsdl+xml'));
   insert into at_file_extension values(53, 'wspolicy',    (select media_type_code from cwms_media_type where media_type_id = 'application/wspolicy+xml'));
   insert into at_file_extension values(53, 'wtb',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.webturbo'));
   insert into at_file_extension values(53, 'wvx',         (select media_type_code from cwms_media_type where media_type_id = 'video/x-ms-wvx'));
   insert into at_file_extension values(53, 'x32',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-authorware-bin'));
   insert into at_file_extension values(53, 'x3d',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.hzn-3d-crossword'));
   insert into at_file_extension values(53, 'xap',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-silverlight-app'));
   insert into at_file_extension values(53, 'xar',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.xara'));
   insert into at_file_extension values(53, 'xbap',        (select media_type_code from cwms_media_type where media_type_id = 'application/x-ms-xbap'));
   insert into at_file_extension values(53, 'xbd',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujixerox.docuworks.binder'));
   insert into at_file_extension values(53, 'xbm',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-xbitmap'));
   insert into at_file_extension values(53, 'xdf',         (select media_type_code from cwms_media_type where media_type_id = 'application/xcap-diff+xml'));
   insert into at_file_extension values(53, 'xdm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.syncml.dm+xml'));
   insert into at_file_extension values(53, 'xdp',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.adobe.xdp+xml'));
   insert into at_file_extension values(53, 'xdssc',       (select media_type_code from cwms_media_type where media_type_id = 'application/dssc+xml'));
   insert into at_file_extension values(53, 'xdw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.fujixerox.docuworks'));
   insert into at_file_extension values(53, 'xenc',        (select media_type_code from cwms_media_type where media_type_id = 'application/xenc+xml'));
   insert into at_file_extension values(53, 'xer',         (select media_type_code from cwms_media_type where media_type_id = 'application/patch-ops-error+xml'));
   insert into at_file_extension values(53, 'xfdf',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.adobe.xfdf'));
   insert into at_file_extension values(53, 'xfdl',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.xfdl'));
   insert into at_file_extension values(53, 'xht',         (select media_type_code from cwms_media_type where media_type_id = 'application/xhtml+xml'));
   insert into at_file_extension values(53, 'xhtml',       (select media_type_code from cwms_media_type where media_type_id = 'application/xhtml+xml'));
   insert into at_file_extension values(53, 'xhvml',       (select media_type_code from cwms_media_type where media_type_id = 'application/xv+xml'));
   insert into at_file_extension values(53, 'xif',         (select media_type_code from cwms_media_type where media_type_id = 'image/vnd.xiff'));
   insert into at_file_extension values(53, 'xla',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel'));
   insert into at_file_extension values(53, 'xlam',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel.addin.macroenabled.12'));
   insert into at_file_extension values(53, 'xlc',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel'));
   insert into at_file_extension values(53, 'xlm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel'));
   insert into at_file_extension values(53, 'xls',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel'));
   insert into at_file_extension values(53, 'xlsb',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel.sheet.binary.macroenabled.12'));
   insert into at_file_extension values(53, 'xlsm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel.sheet.macroenabled.12'));
   insert into at_file_extension values(53, 'xlsx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
   insert into at_file_extension values(53, 'xlt',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel'));
   insert into at_file_extension values(53, 'xltm',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel.template.macroenabled.12'));
   insert into at_file_extension values(53, 'xltx',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.openxmlformats-officedocument.spreadsheetml.template'));
   insert into at_file_extension values(53, 'xlw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-excel'));
   insert into at_file_extension values(53, 'xml',         (select media_type_code from cwms_media_type where media_type_id = 'application/xml'));
   insert into at_file_extension values(53, 'xo',          (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.olpc-sugar'));
   insert into at_file_extension values(53, 'xop',         (select media_type_code from cwms_media_type where media_type_id = 'application/xop+xml'));
   insert into at_file_extension values(53, 'xpi',         (select media_type_code from cwms_media_type where media_type_id = 'application/x-xpinstall'));
   insert into at_file_extension values(53, 'xpm',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-xpixmap'));
   insert into at_file_extension values(53, 'xpr',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.is-xpr'));
   insert into at_file_extension values(53, 'xps',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.ms-xpsdocument'));
   insert into at_file_extension values(53, 'xpw',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.intercon.formnet'));
   insert into at_file_extension values(53, 'xpx',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.intercon.formnet'));
   insert into at_file_extension values(53, 'xsl',         (select media_type_code from cwms_media_type where media_type_id = 'application/xml'));
   insert into at_file_extension values(53, 'xslt',        (select media_type_code from cwms_media_type where media_type_id = 'application/xslt+xml'));
   insert into at_file_extension values(53, 'xsm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.syncml+xml'));
   insert into at_file_extension values(53, 'xspf',        (select media_type_code from cwms_media_type where media_type_id = 'application/xspf+xml'));
   insert into at_file_extension values(53, 'xul',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.mozilla.xul+xml'));
   insert into at_file_extension values(53, 'xvm',         (select media_type_code from cwms_media_type where media_type_id = 'application/xv+xml'));
   insert into at_file_extension values(53, 'xvml',        (select media_type_code from cwms_media_type where media_type_id = 'application/xv+xml'));
   insert into at_file_extension values(53, 'xwd',         (select media_type_code from cwms_media_type where media_type_id = 'image/x-xwindowdump'));
   insert into at_file_extension values(53, 'xyz',         (select media_type_code from cwms_media_type where media_type_id = 'chemical/x-xyz'));
   insert into at_file_extension values(53, 'yang',        (select media_type_code from cwms_media_type where media_type_id = 'application/yang'));
   insert into at_file_extension values(53, 'yin',         (select media_type_code from cwms_media_type where media_type_id = 'application/yin+xml'));
   insert into at_file_extension values(53, 'zaz',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.zzazz.deck+xml'));
   insert into at_file_extension values(53, 'zip',         (select media_type_code from cwms_media_type where media_type_id = 'application/zip'));
   insert into at_file_extension values(53, 'zir',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.zul'));
   insert into at_file_extension values(53, 'zirz',        (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.zul'));
   insert into at_file_extension values(53, 'zmm',         (select media_type_code from cwms_media_type where media_type_id = 'application/vnd.handheld-entertainment+xml'));
end;
/
commit;

--                 
-- CWMS_APEX_ROLES  (Table) 
--
--   Row count:10
CREATE TABLE CWMS_APEX_ROLES
(
  USER_GROUP_CODE       NUMBER,
  USER_GROUP_ID         VARCHAR2(32 BYTE),
  APEX_ROLE_DISPLAY_ID  VARCHAR2(32 BYTE),
  APEX_ROLE_RETURN_ID   VARCHAR2(32 BYTE)
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/



SET DEFINE OFF;
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (0, 'CWMS DBA Users', 'CWMS Admin User', 'CWMS_AU');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (0, 'CWMS DBA Users', 'CWMS VT User', 'CWMS_VT');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (0, 'CWMS DBA Users', 'CWMS General User', 'CWMS_GU');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (7, 'CWMS User Admins', 'CWMS Admin User', 'CWMS_AU');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (3, 'CWMS Data Acquisition Mgr', 'CWMS DA User', 'CWMS_DA');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (3, 'CWMS Data Acquisition Mgr', 'CWMS General User', 'CWMS_GU');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (5, 'VT Mgr', 'CWMS VT User', 'CWMS_VT');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (3, 'CWMS Data Acquisition Mgr', 'CWMS VT User', 'CWMS_VT');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (0, 'CWMS DBA Users', 'CWMS DA User', 'CWMS_DA');
Insert into CWMS_APEX_ROLES
   (USER_GROUP_CODE, USER_GROUP_ID, APEX_ROLE_DISPLAY_ID, APEX_ROLE_RETURN_ID)
 Values
   (5, 'VT Mgr', 'CWMS General User', 'CWMS_GU');
COMMIT;

SHOW ERRORS;
COMMIT ;
SET define on


-- HOST pwd
@@rowcps_schema.sql
