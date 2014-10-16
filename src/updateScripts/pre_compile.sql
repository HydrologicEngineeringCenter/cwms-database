accept inst        char prompt 'Enter the database SID           : '
accept cwms_passwd char prompt 'Enter the password for &cwms_schema   : '

connect &cwms_schema/&cwms_passwd@&inst

PROMPT Disabling all background jobs

BEGIN
   FOR c IN (SELECT owner, job_name
               FROM dba_scheduler_jobs
              WHERE owner = '&cwms_schema')
   LOOP
      BEGIN
         DBMS_OUTPUT.PUT_LINE (c.job_name);
         DBMS_SCHEDULER.DISABLE (c.owner || '.' || c.job_name, TRUE);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END LOOP;
END;
/


whenever sqlerror continue; 

PROMPT update cwms_ts package body

@../cwms/cwms_ts_pkg_body.sql

PROMPT rename at_sec_user_office column

ALTER TABLE at_sec_user_office
  RENAME COLUMN user_db_office_code to db_office_code;

PROMPT Append additional entries into CWMS_TIME_ZONE_ALIAS

INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('CST', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('PST', 'Etc/GMT+8');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('EDT', 'Etc/GMT+4');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('CDT', 'Etc/GMT+5');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('MDT', 'Etc/GMT+6');
INSERT INTO CWMS_TIME_ZONE_ALIAS VALUES ('PDT', 'Etc/GMT+7');

commit;

PROMPT Correct AT_PROJECT_PURPOSES Table

delete FROM AT_PROJECT_PURPOSES WHERE PURPOSE_CODE=3;
set escape on
insert into at_project_purposes values ( 3, 53, 'Fish \& Wildlife Pond', 'Fish \& Wildlife Pond', 'T', 'F');
set escape off

commit;

PROMPT Switch from AT_LOCATION_KIND to CWMS_LOCATION_KIND

alter table at_physical_location drop constraint at_physical_location_fk4;
drop table at_location_kind;

create table cwms_location_kind
(
  location_kind_code    number(10)         not null,
  parent_location_kind  number(10),
  location_kind_id      varchar2(32 byte)  not null,
  representative_point  varchar2(32 byte)  not null,
  description           varchar2(256 byte)
);

alter table cwms_location_kind add constraint cwms_location_kind_pk  primary key (location_kind_code) using index;
alter table cwms_location_kind add constraint cwms_location_kind_u1  unique (location_kind_id) using index;
alter table cwms_location_kind add constraint cwms_location_kind_fk1 foreign key (parent_location_kind) references cwms_location_kind (location_kind_code);

comment on table  cwms_location_kind is 'Contains location kinds.';
comment on column cwms_location_kind.location_kind_code   is 'Primary key relating location kinds locations.';
comment on column cwms_location_kind.parent_location_kind is 'References the code of the location kind that this kind is a sub-kind of.';
comment on column cwms_location_kind.location_kind_id     is 'Text name used as an input to the lookup.';
comment on column cwms_location_kind.representative_point is 'The point represented by the single lat/lon in the physical location tabel.';
comment on column cwms_location_kind.description          is 'Descriptive text about the location kind.';

insert into cwms_location_kind values ( 1, null, 'SITE',        'The point identified with site',  'A location with no entry in one of the location kind tables');
insert into cwms_location_kind values ( 2,    1, 'STREAM',      'The downstream-most point',       'A stream or river');
insert into cwms_location_kind values ( 3,    1, 'BASIN',       'The outlet of the basin',         'A basin or water catchment');
insert into cwms_location_kind values ( 4,    1, 'PROJECT',     'The project office or other loc', 'One or more associated structures constructed to manage the flow of water in a river or stream');
insert into cwms_location_kind values ( 5,    1, 'EMBANKMENT',  'The midpoint of the centerline',  'A raised structure constructed to impede or direct the flow of water in a river or stream');
insert into cwms_location_kind values ( 6,    1, 'OUTLET',      'The discharge point or midpoint', 'A structure constructed to allow the flow of water through, under, or over an embankment');
insert into cwms_location_kind values ( 7,    1, 'TURBINE',     'The discharge point',             'An structure constructed to generate electricity from the flow of water');
insert into cwms_location_kind values ( 8,    1, 'LOCK',        'The center of the chamber',       'A structure that raises and lowers waterborne vessels between upper and lower pools');
insert into cwms_location_kind values ( 9,    1, 'STREAMGAGE',  'The gage location',               'A gage on or along a stream, used to measure stage and possibly other parameters');
insert into cwms_location_kind values (10,    6, 'GATE',        'The discharge point',             'An outlet that can restrict or prevent the flow of water.');
insert into cwms_location_kind values (11,    6, 'OVERFLOW',    'The midpoint of the discharge',   'An outlet that passes the flow of water without restriction above a certain elevation'); 

comment on column cwms_20.at_physical_location.location_kind is 'Reference to location kind in CWMS_LOCATION_KIND';
alter table at_physical_location add constraint at_physical_location_fk4 foreign key (location_kind) references cwms_location_kind (location_kind_code);

PROMPT Modify AT_STREAM_LOCATION to allow NULLs

alter table at_stream_location modify stream_location_code null;
alter table at_stream_location modify station null;

PROMPT Adding USGS Parameter Table

create table at_usgs_parameter(
   office_code              integer,
   usgs_parameter_code      integer,
   cwms_parameter_code      integer not null,
   cwms_parameter_type_code integer not null,
   cwms_unit_code           integer not null,
   factor                   binary_double default 1.0,
   offset                   binary_double default 0.0,
   constraint at_usgs_parameter_pk  primary key (office_code, usgs_parameter_code),
   constraint at_usgs_parameter_fk1 foreign key (cwms_parameter_code) references at_parameter (parameter_code),
   constraint at_usgs_parameter_fk2 foreign key (cwms_parameter_type_code) references cwms_parameter_type (parameter_type_code),
   constraint at_usgs_parameter_fk3 foreign key (cwms_unit_code) references cwms_unit (unit_code)
) tablespace cwms_20at_data
/

comment on table  at_usgs_parameter is 'Holds information for storing time series retrieved from USGS into CWMS';
comment on column at_usgs_parameter.office_code              is 'Office that owns this conversion record. CWMS office applies to all unless overridden';
comment on column at_usgs_parameter.usgs_parameter_code      is 'The USGS parameter code of the retrieved data';
comment on column at_usgs_parameter.cwms_parameter_code      is 'The CWMS parameter to use when storing the data';
comment on column at_usgs_parameter.cwms_parameter_type_code is 'The CWMS parameter type to use when storing the data';
comment on column at_usgs_parameter.cwms_unit_code           is 'The CWMS unit to use when storing the data';
comment on column at_usgs_parameter.factor                   is 'CWMS = USGS * factor + offset to get to CWMS unit';
comment on column at_usgs_parameter.offset                   is 'CWMS = USGS * factor + offset to get to CWMS unit';
-- 00010 - Temp-Water.Inst in C
insert 
  into at_usgs_parameter 
 values(53,
        10,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Temp'
                                      ) 
            and sub_parameter_id = 'Water'
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'C'
        ),
        1.0,
        0.0);
-- 00021 - Temp-Air.Inst in F
insert 
  into at_usgs_parameter 
 values(53,
        21,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Temp'
                                      ) 
            and sub_parameter_id = 'Air'
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'F'
        ),
        1.0,
        0.0);
-- 00045 - Precip.Total in in
insert 
  into at_usgs_parameter 
 values(53,
        45,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Precip'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Total'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'in'
        ),
        1.0,
        0.0);
-- 00060 - Flow.Inst in cfs
--
-- USGS specifies this is average discharge over 1 day but then uses it in
-- combination with instantaneous gage heights on hourly or sub-hourly data!
insert 
  into at_usgs_parameter 
 values(53,
        60,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Flow'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'cfs'
        ),
        1.0,
        0.0);
-- 00061 - Flow.Inst in cfs
insert 
  into at_usgs_parameter 
 values(53,
        61,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Flow'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'cfs'
        ),
        1.0,
        0.0);
-- 00062 - Elev.Inst in ft
insert 
  into at_usgs_parameter 
 values(53,
        62,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Elev'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'ft'
        ),
        1.0,
        0.0);
-- 00065 - Stage.Inst in ft
insert 
  into at_usgs_parameter 
 values(53,
        65,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Stage'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'ft'
        ),
        1.0,
        0.0);
-- 00095 - Cond.Inst in umho/cm
insert 
  into at_usgs_parameter 
 values(53,
        95,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Cond'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'umho/cm'
        ),
        1.0,
        0.0);
-- 00096 - Conc-Salinity.Inst in mg/l
insert 
  into at_usgs_parameter 
 values(53,
        96,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Conc'
                                      ) 
            and sub_parameter_id = 'Salinity'
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'mg/l'
        ),
        0.001,
        0.0);
-- 72036 - Stor.Inst in ac-ft
insert 
  into at_usgs_parameter 
 values(53,
        72036,
        (select parameter_code 
           from at_parameter 
          where base_parameter_code = (select base_parameter_code 
                                         from cwms_base_parameter 
                                        where base_parameter_id = 'Stor'
                                      ) 
            and sub_parameter_id is null
        ),
        (select parameter_type_code 
           from cwms_parameter_type 
          where parameter_type_id = 'Inst'
        ),
        (select unit_code 
           from cwms_unit 
          where unit_id = 'ac-ft'
        ),
        1000.0,
        0.0);
commit;        

PROMPT AT virtual rating tables

-----------------------
-- AT_VIRTUAL_RATING --
-----------------------
create table at_virtual_rating (
   virtual_rating_code number(10),
   rating_spec_code    number(10) not null,
   connections         varchar2(80) not null,
   description         varchar2(256),
   constraint at_virtual_rating_pk  primary key (virtual_rating_code),
   constraint at_virtual_rating_u1  unique (rating_spec_code) using index,
   constraint at_virtual_rating_fk1 foreign key (rating_spec_code) references at_rating_spec (rating_spec_code),
   constraint at_virtual_rating_ck1 check (regexp_instr(connections, 'R\d(D|I\d)=(I\d|R\d(D|I\d))(,R\d(D|I\d)=(I\d|R\d(D|I\d)))*', 1, 1, 0, 'i') = 1)
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_virtual_rating is 'Holds information about virtual ratings';
comment on column at_virtual_rating.virtual_rating_code is 'Synthetic key';
comment on column at_virtual_rating.rating_spec_code    is 'Foreign key to rating specification for this virtual rating';
comment on column at_virtual_rating.connections         is 'String specifying how source ratings are connected to form virtual rating';
comment on column at_virtual_rating.description         is 'Descriptive text about this virtual rating';

-------------------------------
-- AT_VIRTUAL_RATING_ELEMENT --
-------------------------------
create table at_virtual_rating_element (
   virtual_rating_element_code number(10),
   virtual_rating_code         number(10),
   position                    integer,
   rating_spec_code            number(10),
   rating_expression           varchar2(32),
   constraint at_virtual_rating_element_pk  primary key (virtual_rating_element_code),
   constraint at_virtual_rating_element_fk1 foreign key (virtual_rating_code) references at_virtual_rating (virtual_rating_code),
   constraint at_virtual_rating_element_ck1 check ((rating_spec_code is null or  rating_expression is null) and not 
                                                   (rating_spec_code is null and rating_expression is null))
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_virtual_rating_element is 'Holds source ratings (rating specs or rating expressions) for virtual ratings';
comment on column at_virtual_rating_element.virtual_rating_element_code is 'Synthetic key';
comment on column at_virtual_rating_element.virtual_rating_code         is 'Foreign key to the virtual rating that this source rating is for';
comment on column at_virtual_rating_element.position                    is 'The sequential position of this source rating in the virtual rating';
comment on column at_virtual_rating_element.rating_spec_code            is 'Foreign key to the rating spec for this source rating if it is a rating';
comment on column at_virtual_rating_element.rating_expression           is 'Mathematical expression for this source rating if it is an expression. For longer expressions use formula-based ratings.';

----------------------------
-- AT_VRITUAL_RATING_UNIT --
----------------------------
create table at_virtual_rating_unit (
   virtual_rating_element_code number(10),
   position                    integer,
   unit_code                   number(10) not null,
   constraint at_virtual_rating_unit_pk  primary key (virtual_rating_element_code, position),
   constraint at_virtual_rating_unit_fk1 foreign key (virtual_rating_element_code) references at_virtual_rating_element (virtual_rating_element_code),
   constraint at_virtual_rating_unit_fk2 foreign key (unit_code) references cwms_unit (unit_code)
)
organization index
tablespace CWMS_20AT_DATA;

comment on table  at_virtual_rating_unit is 'Holds units for virtual rating elements (source ratings)';
comment on column at_virtual_rating_unit.virtual_rating_element_code is 'Foreign key to the virtual rating element this unit is for';
comment on column at_virtual_rating_unit.position                    is 'Sequential position of the paramter in the virtual rating element that this unit is for';
comment on column at_virtual_rating_unit.unit_code                   is 'Foreign key intto the units table for this unit';

   
PROMPT Adding Vertical Datum Structures            

CREATE TABLE CWMS_VERTICAL_DATUM (
   VERTICAL_DATUM_ID VARCHAR2(16) PRIMARY KEY
)
TABLESPACE CWMS_20DATA
/
COMMENT ON TABLE  CWMS_VERTICAL_DATUM                   IS 'Contains constrained list of vertical datums';
COMMENT ON COLUMN CWMS_VERTICAL_DATUM.VERTICAL_DATUM_ID IS 'Text identifier of vertical datum';

INSERT INTO CWMS_VERTICAL_DATUM VALUES ('STAGE');
INSERT INTO CWMS_VERTICAL_DATUM VALUES ('LOCAL');
INSERT INTO CWMS_VERTICAL_DATUM VALUES ('NGVD29');
INSERT INTO CWMS_VERTICAL_DATUM VALUES ('NAVD88');
COMMIT;
CREATE TABLE CWMS_VERTCON_HEADER (
   DATASET_CODE NUMBER(10)    NOT NULL,
   OFFICE_CODE  NUMBER(10)    NOT NULL,
   DATASET_ID   VARCHAR2(32)  NOT NULL,
   MIN_LAT      BINARY_DOUBLE NOT NULL,
   MAX_LAT      BINARY_DOUBLE NOT NULL,
   MIN_LON      BINARY_DOUBLE NOT NULL,
   MAX_LON      BINARY_DOUBLE NOT NULL,
   MARGIN       BINARY_DOUBLE NOT NULL,
   DELTA_LAT    BINARY_DOUBLE NOT NULL,
   DELTA_LON    BINARY_DOUBLE NOT NULL
)
TABLESPACE CWMS_20DATA
/
ALTER TABLE CWMS_VERTCON_HEADER ADD (
   CONSTRAINT CWMS_VERTCON_HEADER_PK  PRIMARY KEY (DATASET_CODE) USING INDEX TABLESPACE CWMS_20DATA,
   CONSTRAINT CWMS_VERTCON_HEADER_CK1 CHECK (MIN_LAT BETWEEN -90 AND 90),
   CONSTRAINT CWMS_VERTCON_HEADER_CK2 CHECK (MAX_LAT BETWEEN -90 AND 90),
   CONSTRAINT CWMS_VERTCON_HEADER_CK3 CHECK (MAX_LAT > MIN_LAT),
   CONSTRAINT CWMS_VERTCON_HEADER_CK4 CHECK (MIN_LON BETWEEN -180 AND 180),
   CONSTRAINT CWMS_VERTCON_HEADER_CK5 CHECK (MAX_LON BETWEEN -180 AND 180),
   CONSTRAINT CWMS_VERTCON_HEADER_CK6 CHECK (MAX_LON > MIN_LON),
   CONSTRAINT CWMS_VERTCON_HEADER_CK7 CHECK (MARGIN BETWEEN 0 AND MAX_LON - MIN_LON),
   CONSTRAINT CWMS_VERTCON_HEADER_CK8 CHECK (DELTA_LAT > 0 AND DELTA_LAT < (MAX_LAT - MIN_LAT) / 2),
   CONSTRAINT CWMS_VERTCON_HEADER_CK9 CHECK (DELTA_LON > 0 AND DELTA_LON < (MAX_LON - MIN_LON) / 2)
)
/
CREATE UNIQUE INDEX CWMS_VERTCON_HEADER_U1 ON CWMS_VERTCON_HEADER(UPPER(DATASET_ID)) TABLESPACE CWMS_20DATA
/                                                         
CREATE INDEX CWMS_VERTCON_HEADER_IDX1 ON CWMS_VERTCON_HEADER(MIN_LAT, MAX_LAT, MIN_LON, MAX_LON) TABLESPACE CWMS_20DATA
/
COMMENT ON TABLE  CWMS_VERTCON_HEADER 	           IS 'Contains header information for a vertcon data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.DATASET_CODE IS 'Unique numeric code of this data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.DATASET_ID   IS 'Unique text identifier of this data set (commonly identifies vertcon data file)';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.MIN_LAT      IS 'Minimum latitude for this data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.MAX_LAT      IS 'Maximum latitude for this data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.MIN_LON      IS 'Minimum longitude for this data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.MAX_LON      IS 'Maximum longitude for this data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.MARGIN	   IS 'Longitude buffer for maximum longitude';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.DELTA_LAT    IS 'Difference between adjacent latitudes in data set';
COMMENT ON COLUMN CWMS_VERTCON_HEADER.DELTA_LON    IS 'Difference between adjacent longitudes in data set';

CREATE TABLE CWMS_VERTCON_DATA (
   DATASET_CODE NUMBER(10),
   TABLE_ROW    INTEGER,
   TABLE_COL    INTEGER,
   TABLE_VAL    BINARY_DOUBLE
)
TABLESPACE CWMS_20DATA
/
ALTER TABLE CWMS_VERTCON_DATA ADD (
   CONSTRAINT CWMS_VERTCON_DATA_PK  PRIMARY KEY (DATASET_CODE, TABLE_ROW, TABLE_COL) USING INDEX TABLESPACE CWMS_20DATA,
   CONSTRAINT CWMS_VERTCON_DATA_FK1 FOREIGN KEY (DATASET_CODE) REFERENCES CWMS_VERTCON_HEADER (DATASET_CODE)
)
/                                          
COMMENT ON TABLE  CWMS_VERTCON_DATA              IS 'Contains datum offsets for all loaded vercon data sets';
COMMENT ON COLUMN CWMS_VERTCON_DATA.DATASET_CODE IS 'Data set identifier - foreign key to cwms_vertcon_header table';
COMMENT ON COLUMN CWMS_VERTCON_DATA.TABLE_ROW    IS 'Row index in vertcon data table';
COMMENT ON COLUMN CWMS_VERTCON_DATA.TABLE_COL    IS 'Column index in vertcon data table';
COMMENT ON COLUMN CWMS_VERTCON_DATA.TABLE_VAL    IS 'Datum offset in millimeters for row and column in vertcon data table';

create table at_vert_datum_offset (
   location_code       number(10)    not null,
   vertical_datum_id_1 varchar2(16)  not null,
   vertical_datum_id_2 varchar2(16)  not null,
   effective_date      date          default date '1000-01-01',
   offset              binary_double not null,
   description         varchar2(64),
   constraint at_vert_datum_offset_pk  primary key (location_code, vertical_datum_id_1, vertical_datum_id_2, effective_date),
   constraint at_vert_datum_offset_fk1 foreign key (location_code) references at_physical_location (location_code),
   constraint at_vert_datum_offset_fk2 foreign key (vertical_datum_id_1) references cwms_vertical_datum (vertical_datum_id),
   constraint at_vert_datum_offset_fk3 foreign key (vertical_datum_id_2) references cwms_vertical_datum (vertical_datum_id),
   constraint at_vert_datum_offset_ck1 check (vertical_datum_id_1 <> vertical_datum_id_2)
) tablespace cwms_20at_data
/

comment on table  at_vert_datum_offset                     is 'Contains vertical datum offsets for CWMS locations';
comment on column at_vert_datum_offset.location_code       is 'References CWMS location';
comment on column at_vert_datum_offset.vertical_datum_id_1 is 'References vertical datum for input';
comment on column at_vert_datum_offset.vertical_datum_id_2 is 'References vertical datum for output';
comment on column at_vert_datum_offset.effective_date      is 'Earliest date/time the offset if in effect';
comment on column at_vert_datum_offset.offset              is 'Value added to input to generate output';
comment on column at_vert_datum_offset.description         is 'Description or comment';

create table at_vert_datum_local (
   location_code    number(10),
   local_datum_name varchar2(16) not null,
   constraint at_vert_datum_local_pk  primary key (location_code) using index,
   constraint at_vert_datum_local_fk1 foreign key (location_code) references at_physical_location(location_code)
) tablespace cwms_20at_data
/

comment on table  at_vert_datum_local                  is 'Contains names of local vertical datums for locations.';
comment on column at_vert_datum_local.location_code    is 'References location with a named local vertical datum.';
comment on column at_vert_datum_local.local_datum_name is 'Name of local vertical datum for location.';

PROMPT Adding an entry to CWMS_ERROR

INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20047, 'SESSION_OFFICE_ID_NOT_SET', 'Session office id is not set by the application');

alter table at_sec_users drop constraint at_sec_users_r02;

PROMPT Inserting Additional CCP groups

INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-1, 'CCP Proc', 'Intended for Service Accounts that will be running CCP daemon services in the background, e.g., the service account running compproc.'
              );
              
INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-2, 'CCP Mgr', 'Users that will be managing (i.e., adding/modifying) CCP computations. This privilege is intended to be assigned to real people/user accounts.'
              );
              
INSERT INTO cwms_sec_user_groups (
                                                 user_group_code,
                                                 user_group_id,
                                                 user_group_desc
              )
  VALUES   (-3, 'CCP Reviewer', 'Users who will be allowed to review (i.e., read only) an office’s CCP computations.'
              );

DECLARE
BEGIN
        INSERT INTO at_sec_user_groups
                SELECT  a.office_code, b.user_group_code, b.user_group_id,
                                        b.user_group_desc
                  FROM  cwms_office a, cwms_sec_user_groups b
		  WHERE b.user_group_code in (-1,-2,-3);
END;
/

COMMIT;
insert into at_sec_cwms_users(userid,createdby) (select unique username,user from at_sec_users where username not in (select userid from at_sec_cwms_users));

ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r02
 FOREIGN KEY (username)
 REFERENCES at_sec_cwms_users (userid))
/

ALTER TABLE AT_SEC_USER_OFFICE DROP CONSTRAINT AT_SEC_USER_OFFICE_PK;
DROP INDEX AT_SEC_USER_OFFICE_PK;
ALTER TABLE AT_SEC_USER_OFFICE DROP CONSTRAINT AT_SEC_USER_OFFICE_R01;
COMMENT ON TABLE AT_SEC_USER_OFFICE IS 'Table to indicate whether a user has any permissions for a given office';
CREATE UNIQUE INDEX AT_SEC_USER_OFFICE_PK ON AT_SEC_USER_OFFICE
(USERNAME,DB_OFFICE_CODE)
LOGGING
TABLESPACE CWMS_20AT_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;
ALTER TABLE CWMS_20.AT_SEC_USER_OFFICE ADD (
  CONSTRAINT AT_SEC_USER_OFFICE_PK
  PRIMARY KEY
  (USERNAME, DB_OFFICE_CODE)
  USING INDEX CWMS_20.AT_SEC_USER_OFFICE_PK
  ENABLE VALIDATE);

ALTER TABLE CWMS_20.AT_SEC_USER_OFFICE ADD (
  CONSTRAINT AT_SEC_USER_OFFICE_FK1 
  FOREIGN KEY (DB_OFFICE_CODE) 
  REFERENCES CWMS_20.CWMS_OFFICE (OFFICE_CODE)
  ENABLE VALIDATE,
  CONSTRAINT AT_SEC_USER_OFFICE_FK2 
  FOREIGN KEY (USERNAME) 
  REFERENCES CWMS_20.AT_SEC_CWMS_USERS (USERID)
  ENABLE VALIDATE);
COMMIT;

revoke execute on &cwms_schema..cwms_upass from cwms_user;


PROMPT Dropping CWMS_ENV public synonym

drop public synonym cwms_env;

-----------------------------
-- add not null constraint --
-----------------------------

COMMENT ON COLUMN CWMS_20.CWMS_MEDIA_TYPE.MEDIA_TYPE_CLOB_TF IS 'Flag (T/F) specifying whether media type documents is stored as CLOBs';

COMMENT ON COLUMN CWMS_20.AT_PROJECT_PURPOSES.PURPOSE_NID_CODE IS 'National Inventory of Dams code for this purpose';

COMMENT ON COLUMN CWMS_20.AT_LOC_GROUP_ASSIGNMENT.OFFICE_CODE IS 'Reference to the office that owns the location - used for index';


COMMENT ON COLUMN CWMS_20.AT_TS_GROUP_ASSIGNMENT.OFFICE_CODE IS 'Reference to the office that owns the time series - used for index';

-- Add constraints to AT_WATER_USER_CONTRACT

ALTER TABLE CWMS_20.AT_WATER_USER_CONTRACT ADD (
  CONSTRAINT AT_WATER_USER_CONTRACT_CK1
  CHECK (nvl(pump_out_location_code, -1) not in (nvl(pump_out_below_location_code, -2), nvl(pump_in_location_code, -3)))
  ENABLE VALIDATE,
  CONSTRAINT AT_WATER_USER_CONTRACT_CK2
  CHECK (nvl(pump_out_below_location_code, -2) != nvl(pump_in_location_code, -3))
  ENABLE VALIDATE);

-- Add foreign constraintis to AT_LOC_GROUP_ASSIGNMENT 

ALTER TABLE CWMS_20.AT_LOC_GROUP_ASSIGNMENT ADD (
CONSTRAINT AT_LOC_GROUP_ASSIGNMENT_FK4 
  FOREIGN KEY (OFFICE_CODE) 
  REFERENCES CWMS_20.CWMS_OFFICE (OFFICE_CODE)
  ENABLE VALIDATE);

-- Add foreign constraintis to AT_TS_GROUP_ASSIGNMENT 

ALTER TABLE CWMS_20.AT_TS_GROUP_ASSIGNMENT ADD (
CONSTRAINT AT_TS_GROUP_ASSIGNMENT_FK4 
  FOREIGN KEY (OFFICE_CODE) 
  REFERENCES CWMS_20.CWMS_OFFICE (OFFICE_CODE)
  ENABLE VALIDATE);

-- Recreate CWMS_STORE_RULE constraints

ALTER TABLE CWMS_STORE_RULE DROP UNIQUE(store_rule_id)  CASCADE;

BEGIN
   FOR c IN (SELECT constraint_name
               FROM user_constraints
              WHERE table_name = 'CWMS_STORE_RULE')
   LOOP
      EXECUTE IMMEDIATE
         'alter table cwms_store_rule drop constraint ' || c.constraint_name;
   END LOOP;
END;

/

CREATE UNIQUE INDEX CWMS_20.CWMS_STORE_RULE_U1 ON CWMS_20.CWMS_STORE_RULE
(STORE_RULE_ID)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;

CREATE UNIQUE INDEX CWMS_20.CWMS_STORE_RULE_PK ON CWMS_20.CWMS_STORE_RULE
(STORE_RULE_CODE)
LOGGING
TABLESPACE CWMS_20DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;

ALTER TABLE CWMS_20.CWMS_STORE_RULE ADD (
  CONSTRAINT CWMS_STORE_RULE_CK1
  CHECK (use_as_default in ('T', 'F'))
  ENABLE VALIDATE,
  CONSTRAINT CWMS_STORE_RULE_PK
  PRIMARY KEY
  (STORE_RULE_CODE)
  USING INDEX CWMS_20.CWMS_STORE_RULE_PK
  ENABLE VALIDATE,
  CONSTRAINT CWMS_STORE_RULE_U1
  UNIQUE (STORE_RULE_ID)
  USING INDEX CWMS_20.CWMS_STORE_RULE_U1
  ENABLE VALIDATE);

alter table CWMS_20.cwms_store_rule modify (USE_AS_DEFAULT   VARCHAR2(1 BYTE)             NOT NULL);

-- Add constraints to AT_STORE_RULE_DEFAULT 
ALTER TABLE CWMS_20.AT_STORE_RULE_DEFAULT ADD (
  CONSTRAINT AT_STORE_RULE_DEFAULT_FK2 
  FOREIGN KEY (DEFAULT_STORE_RULE) 
  REFERENCES CWMS_20.CWMS_STORE_RULE (STORE_RULE_ID)
  ENABLE VALIDATE);

-- Add constraints to AT_STORE_RULE_ORDER 
ALTER TABLE CWMS_20.AT_STORE_RULE_ORDER ADD (
  CONSTRAINT AT_STORE_RULE_ORDER_FK2 
  FOREIGN KEY (STORE_RULE_ID) 
  REFERENCES CWMS_20.CWMS_STORE_RULE (STORE_RULE_ID)
  ENABLE VALIDATE);

COMMIT;
whenever sqlerror exit; 


