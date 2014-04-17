connect / as sysdba
define cwms_schema = CWMS_20
set define on
set verify off
alter session set current_schema=&cwms_schema;
alter system enable restricted session;
whenever sqlerror exit sql.sqlcode

spool updateCWMS21_DB.log
 
PROMPT Creating AT_SEC_CWMS_USERS and AT_SEC_CWMS_PERMISSIONS tables

@@../cwms/at_schema_sec_2

PROMPT Adding an entry to CWMS_ERROR

INSERT INTO CWMS_ERROR (ERR_CODE, ERR_NAME, ERR_MSG) VALUES (-20047, 'SESSION_OFFICE_ID_NOT_SET', 'Session office id is not set by the application');

PROMPT Update packages/types/views
@@../cwms/updateCwmsSchema

PROMPT Creating AV_SEC_USERS view
@@../cwms/views/av_sec_users

PROMPT Creating Additional synonyms and grants
CREATE PUBLIC SYNONYM CWMS_ALARM FOR &CWMS_SCHEMA..CWMS_ALARM;
CREATE PUBLIC SYNONYM CWMS_ENV FOR &CWMS_SCHEMA..CWMS_ENV;
GRANT EXECUTE ON &CWMS_SCHEMA..LOC_LVL_INDICATOR_COND_T TO CWMS_USER;
GRANT EXECUTE ON &CWMS_SCHEMA..LOC_LVL_CUR_MAX_IND_TAB_T TO CWMS_USER;
GRANT EXECUTE ON &CWMS_SCHEMA..RATING_T TO CWMS_USER;
GRANT EXECUTE ON &CWMS_SCHEMA..CWMS_ENV TO CWMS_USER;

PROMPT Creating CWMS_ENV context
@@../cwms/at_schema_env


PROMPT Recreating at_sec_users_r02 constraint

alter table at_sec_users drop constraint at_sec_users_r02;

PROMPT Inserting Additional CCP groups
@@insert_new_groups

ALTER TABLE at_sec_users ADD (
  CONSTRAINT at_sec_users_r02
 FOREIGN KEY (username)
 REFERENCES at_sec_cwms_users (userid))
/


PROMPT Dropping AT_SEC_USER_OFFICE table

drop table at_sec_user_office;

PROMPT Dropping AT_SEC_USER_OFFICE table

drop table at_sec_dbi_user;

PROMPT Adding Vertical Datum Offset Types

CREATE OR REPLACE TYPE &cwms_schema..vert_datum_offset_t
/**
 * Holds a vertical datum conversion offset for a location
 *
 * @since CWMS 2.2
 *
 * @field location            The location the offset applies to
 * @field vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
 * @field vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
 * @field effective_date      The date and time the offset became effective.  The date 01-JAN-1000 represents a long-ago effective date
 * @field time_zone           The time zone of the effective date field
 * @field offset              The offset that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
 * @field unit                The unit of the offset
 * @field description         A description of the offset
 *
 * @see type location_ref_t
 * @see type vert_datum_offset_tab_t
 *
 */
as object(
   location            location_ref_t,
   vertical_datum_id_1 varchar2(16),
   vertical_datum_id_2 varchar2(16),
   effective_date      date,
   time_zone           varchar2(28),                        
   offset              binary_double,
   unit                varchar2(16),
   description         varchar2(64));
/

CREATE OR REPLACE PUBLIC SYNONYM CWMS_T_VERT_DATUM_OFFSET FOR &cwms_schema..VERT_DATUM_OFFSET_T;

GRANT EXECUTE ON &cwms_schema..VERT_DATUM_OFFSET_T TO CWMS_USER;

CREATE OR REPLACE TYPE &cwms_schema..vert_datum_offset_tab_t
/**
 * Holds a table of loc_lvl_cur_max_ind_t records.
 *
 * @since CWMS 2.2
 *
 * @see type vert_datum_offset_t
 */
as table of vert_datum_offset_t;
/

CREATE OR REPLACE PUBLIC SYNONYM CWMS_T_VERT_DATUM_OFFSET_TAB FOR &cwms_schema..VERT_DATUM_OFFSET_TAB_T;

GRANT EXECUTE ON &cwms_schema..VERT_DATUM_OFFSET_TAB_T TO CWMS_USER;

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

@@../cwms/views/av_vert_datum_offset
CREATE OR REPLACE PUBLIC SYNONYM CWMS_V_VERT_DATUM_OFFSET FOR &cwms_schema..AV_VERT_DATUM_OFFSET;
GRANT SELECT ON &cwms_schema..AV_VERT_DATUM_OFFSET TO CWMS_USER;

PROMPT Adding Vertical Datum Conversion Code            

@@../cwms/cwms_loc_pkg.sql
@@../cwms/cwms_loc_pkg_body.sql

PROMPT Adding VERTCON Data as CLOBs            

HOST sqlldr userid=\"/ as sysdba\" control=vertcon_clobs.ctl

PROMPT Parsing VERTCON CLOBs into Tables            

declare
   l_clob          clob; 
   l_line          varchar2(32767);
   l_pos           integer; 
   l_pos2          integer; 
   l_parts         number_tab_t;
   l_lon_count     integer; 
   l_lat_count     integer; 
   l_z_count       integer; 
   l_min_lon       binary_double; 
   l_delta_lon     binary_double; 
   l_min_lat       binary_double;
   l_delta_lat     binary_double; 
   l_margin        binary_double;
   l_max_lon       binary_double;
   l_max_lat       binary_double;
   l_vals          number_tab_t := number_tab_t(); 
   l_data_set_code number(10);
   l_idx           pls_integer;
   
   procedure get_line(p_line out varchar2) is
      l_amount integer;
      l_buf    varchar2(32767);
   begin
      l_pos2 := dbms_lob.instr(l_clob, chr(10), l_pos, 1);
      if l_pos2 is null or l_pos2 = 0 then
         l_pos2 := dbms_lob.getlength(l_clob) + 1;
      else
         l_pos2 := l_pos2 + 1;
      end if;
      l_amount := greatest(l_pos2 - l_pos, 1);
      dbms_lob.read(l_clob, l_amount, l_pos, l_buf);
      l_pos := l_pos + l_amount;
      p_line := trim(trailing chr(13) from trim(trailing chr(10) from l_buf));
   end;  
begin
   ---------------------------
   -- for each vertcon clob --
   ---------------------------
   for rec in (select id from at_clob where clob_code < 0) loop          
      l_vals.delete;
      select value
        into l_clob
        from at_clob
       where id = upper(rec.id);
      dbms_lob.open(l_clob, dbms_lob.lob_readonly);
      l_pos := 1;       
      begin
         ---------------------
         -- read the header --
         ---------------------
         get_line(l_line); 
         get_line(l_line); 
         select column_value
           bulk collect
           into l_parts
           from table(cwms_util.split_text(trim(l_line)));
         if l_parts(3) != 1 then
            cwms_err.raise('ERROR', 'z_count must equal 1');
         end if;
         l_lon_count := l_parts(1);
         l_lat_count := l_parts(2);
         l_z_count   := l_parts(3);
         l_min_lon   := l_parts(4);
         l_delta_lon := l_parts(5);
         l_min_lat   := l_parts(6);
         l_delta_lat := l_parts(7);
         l_margin    := l_parts(8);
         l_max_lon := l_min_lon + (l_lon_count - 1) * l_delta_lon;
         l_max_lat := l_min_lat + (l_lat_count - 1) * l_delta_lat;
         l_vals.extend(l_lon_count * l_lat_count);
         ---------------------------------
         -- read the datum shift values --
         -- into a linear (1-D) table   --
         ---------------------------------
         l_idx := 0;
         <<read_vals>>
         while true loop
            begin
               get_line(l_line);   
               select column_value
                 bulk collect
                 into l_parts
                 from table(cwms_util.split_text(trim(l_line)));
               for j in 1..l_parts.count loop 
                  l_vals(l_idx+j) := l_parts(j);
               end loop;
               l_idx := l_idx + l_parts.count;
            exception
               when no_data_found then exit read_vals;
            end;
         end loop;
      exception
         when others then 
            dbms_lob.close(l_clob);
            raise;
      end;
      dbms_lob.close(l_clob);
      --------------------------
      -- load the header data --
      --------------------------
      insert
        into cwms_vertcon_header
             ( office_code,
               dataset_code,
               dataset_id,
               min_lat,
               max_lat,
               min_lon,
               max_lon,
               margin,
               delta_lat,
               delta_lon
             )
      values ( cwms_util.db_office_code_all,
               cwms_seq.nextval,
               replace(replace(lower(rec.id), 'asc', 'con'), '/vertcon/', ''),
               l_min_lat,
               l_max_lat,
               l_min_lon,
               l_max_lon,
               l_margin,
               l_delta_lat,
               l_delta_lon 
             )
   returning dataset_code
        into l_data_set_code;               
      -------------------------      
      -- load the table data --
      -------------------------      
      for j in 1..l_lat_count loop
         for k in 1..l_lon_count loop
            insert
              into cwms_vertcon_data
                   ( dataset_code,
                     table_row,
                     table_col,
                     table_val
                   )
            values ( l_data_set_code,
                     j,
                     k,
                     l_vals((j-1)*l_lon_count+k)
                   );
         end loop;
      end loop;      
   end loop;
   
   delete
     from at_clob
    where clob_code < 0;
    
   commit;    
end;
/

COMMIT;
alter system disable restricted session;
exit;
