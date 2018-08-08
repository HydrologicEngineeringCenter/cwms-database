/*
The update process for the at_a2w_ts_codes_by_loc table includes the deletion
of rows that point to no longer existing locations. To assure no data loss,
a copy of the original data is made.
*/

whenever sqlerror continue; 

PROMPT creating table zz_a2w_loc

CREATE TABLE ZZ_A2W_LOC
(
  DB_OFFICE_ID   VARCHAR2(16 BYTE),
  LOCATION_ID    VARCHAR2(49 BYTE),
  LOCATION_CODE  NUMBER(10)
)
TABLESPACE CWMS_20DATA
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
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
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

comment on table zz_a2w_loc is
   'The ZZ_A2W_LOC table is a temp table used to speed-up updating the
   revised AT_A2W_TS_CODES_BY_LOC table with location_codes.
   (January 2015)';

CREATE UNIQUE INDEX ZZ_A2W_LOC_PK ON ZZ_A2W_LOC
(DB_OFFICE_ID, LOCATION_ID)
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

ALTER TABLE ZZ_A2W_LOC ADD (
  CONSTRAINT ZZ_A2W_LOC_PK
  PRIMARY KEY
  (DB_OFFICE_ID, LOCATION_ID)
  USING INDEX ZZ_A2W_LOC_PK
  ENABLE VALIDATE);
   
insert into zz_a2w_loc
   (select o.office_id db_office_id,
              base_location_id
           || substr ('-', 1, length (p1.sub_location_id))
           || p1.sub_location_id
              as location_id,
           p1.location_code
      from ((at_physical_location p1
             left outer join cwms_office o1 using (office_code))
            join
            (at_physical_location p2
             left outer join cwms_office o2 using (office_code))
               on p2.location_code = p1.base_location_code
            join at_base_location b
               on b.base_location_code = p1.base_location_code)
           join cwms_office o on b.db_office_code = o.office_code
     where p1.location_code != 0);

commit;

PROMPT creating table zz_a2w_ts_codes_by_loc
create table zz_a2w_ts_codes_by_loc
(
   location_id            varchar2 (199 byte),
   db_office_id           varchar2 (5 byte),
   ts_code_elev           number,
   ts_code_precip         number,
   ts_code_stage          number,
   ts_code_inflow         number,
   ts_code_outflow        number,
   date_refreshed         date not null,
   ts_code_stor_flood     number,
   notes                  clob,
   display_flag           varchar2 (1 byte) default 'F' not null,
   num_ts_codes           number default 0 not null,
   ts_code_stor_drought   number,
   lake_summary_tf        varchar2 (1 byte) default 'F' not null,
   ts_code_sur_release    number,
   supplemental log data ( primary key ) columns,
   supplemental log data ( unique ) columns,
   supplemental log data ( foreign key ) columns
)
lob (notes) store as
   (tablespace cwms_20at_data
    enable storage in row
    chunk 8192
    retention
    nocache logging
    storage (initial 64 k
             next 1 m
             minextents 1
             maxextents unlimited
             pctincrease 0
             buffer_pool default
             flash_cache default
             cell_flash_cache default))
tablespace cwms_20data
result_cache (mode default)
pctused 0
pctfree 10
initrans 1
maxtrans 255
storage (initial 64 k
         next 1 m
         maxsize unlimited
         minextents 1
         maxextents unlimited
         pctincrease 0
         buffer_pool default
         flash_cache default
         cell_flash_cache default)
logging
nocompress
nocache
noparallel
monitoring;

comment on table zz_a2w_ts_codes_by_loc is
   'The ZZ_A2W_TS_CODES_BY_LOC table is a backup of the AT_A2W_TS_CODES_BY_LOC 
   table before the AT table is updated with a location_code column. 
   The update and cleaned-up of the AT table deletes rows that no longer 
   had valid locations. As a safty pre-caution, this copy is made before any
   deletes occur. (January 2015)';

PROMPT create unique index zz_a2w_ts_codes_by_loc_pk
create unique index zz_a2w_ts_codes_by_loc_pk
   on zz_a2w_ts_codes_by_loc (location_id, db_office_id)
   logging
   tablespace cwms_20data
   pctfree 10
   initrans 2
   maxtrans 255
   storage (initial 64 k
            next 1 m
            maxsize unlimited
            minextents 1
            maxextents unlimited
            pctincrease 0
            buffer_pool default
            flash_cache default
            cell_flash_cache default)
   noparallel;

alter table zz_a2w_ts_codes_by_loc add (
  constraint zz_a2w_ts_codes_by_loc_pk
  primary key
  (location_id, db_office_id)
  using index zz_a2w_ts_codes_by_loc_pk
  enable validate);

insert into zz_a2w_ts_codes_by_loc
   (select *
      from at_a2w_ts_codes_by_loc);

commit;

PROMPT add the new location_code column...
alter table at_a2w_ts_codes_by_loc add (location_code number(10));

PROMPT populate the new location_code column in at_a2w_ts_codes_by_loc

update at_a2w_ts_codes_by_loc aa
   set aa.location_code =
          (select location_code
             from zz_a2w_loc bb
            where     bb.db_office_id = aa.db_office_id
                  and bb.location_id = aa.location_id);
commit;

prompt delete rows from at_a2w_ts_codes_by_loc that contain non-existant locations
declare
   l_num_at   integer;
   l_num_zz   integer;
begin
   select count (*) into l_num_at from at_a2w_ts_codes_by_loc;

   select count (*) into l_num_zz from zz_a2w_ts_codes_by_loc;

   if l_num_at = l_num_zz
   then
      delete at_a2w_ts_codes_by_loc
       where location_code is null;

      commit;
   else
      raise_application_error (
         -20202,
         'The at_a2w_ts_codes_by_loc table copy failed');
   end if;
end;
/

PROMPT drop old and add new indexes and constraints...
alter table at_a2w_ts_codes_by_loc
   drop primary key cascade;

drop index at_a2w_ts_codes_by_loc_pk;

drop index a2w_counts_idx;

alter table cwms_20.at_a2w_ts_codes_by_loc add
constraint at_a2w_ts_codes_by_loc_pk
 primary key (location_code)
 enable
 validate;

alter table at_a2w_ts_codes_by_loc add (
  constraint at_a2w_ts_codes_by_loc_r01
  foreign key (location_code)
  references at_physical_location (location_code)
  enable validate);

ALTER TABLE CWMS_20.AT_A2W_TS_CODES_BY_LOC
 ADD (TS_CODE_ELEV_TW  NUMBER);

ALTER TABLE CWMS_20.AT_A2W_TS_CODES_BY_LOC
 ADD (TS_CODE_STAGE_TW  NUMBER);

ALTER TABLE CWMS_20.AT_A2W_TS_CODES_BY_LOC
 ADD (TS_CODE_RULE_CURVE_ELEV  NUMBER);

ALTER TABLE CWMS_20.AT_A2W_TS_CODES_BY_LOC
 MODIFY (LOCATION_CODE  NUMBER);
