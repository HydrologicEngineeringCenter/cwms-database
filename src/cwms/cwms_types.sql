-- Defines the CWMS date-time, value, and quality types. 
--
SET TIME ON
SELECT SYSDATE FROM DUAL;
SET ECHO ON

-- Is there a way to check if the types exist prior to dropping them?

DROP TYPE tsv_array force;
DROP TYPE tsv_type force;

CREATE OR REPLACE TYPE tsv_type 
                    AS OBJECT (date_time timestamp with time zone,
                               value BINARY_DOUBLE, 
							   quality_code NUMBER);
/

CREATE OR REPLACE TYPE tsv_array IS TABLE OF tsv_type;
/

-- Need to drop the array type due to its dependency on the at_tsv_type.
DROP TYPE at_tsv_array;

-- This type represents a row in the time series value table.
-- BINARY_INTEGER or PLS_INTEGER should be used instead of NUMBER, which is better?
-- Also creating a type using either of those datatypes issues an error...
CREATE OR REPLACE TYPE at_tsv_type AS OBJECT (date_time DATE, value BINARY_DOUBLE, quality NUMBER);
/
-- This type represents an array of the time series value table rows.
CREATE OR REPLACE TYPE at_tsv_array IS TABLE OF at_tsv_type;
/


-- 16 character id array.
CREATE OR REPLACE TYPE char_16_array_type IS TABLE OF VARCHAR2(16);
/
-- 32 character id array.
CREATE OR REPLACE TYPE char_32_array_type IS TABLE OF VARCHAR2(32);
/
-- the size of a time series id.
CREATE OR REPLACE TYPE char_183_array_type IS TABLE OF VARCHAR2(183);
/
CREATE OR REPLACE TYPE date_table_type AS TABLE OF DATE;
/

-- CREATE OR REPLACE TYPE TSVArray IS TABLE OF AT_TIME_SERIES_VALUE%ROWTYPE
--	INDEX BY BINARY_INTEGER;

DROP TYPE source_array;
CREATE OR REPLACE TYPE source_type AS OBJECT (source_id VARCHAR2(16), gage_id   VARCHAR2(32));
/
CREATE OR REPLACE TYPE source_array IS TABLE OF source_type;
/

CREATE OR REPLACE TYPE loc_type_ds AS OBJECT (
   office_id        VARCHAR2 (16),
   base_loc_id      VARCHAR2 (16),
   state_initial    VARCHAR2 (2),
   county_name      VARCHAR2 (40),
   timezone_name    VARCHAR2 (28),
   location_type    VARCHAR2 (16),
   latitude         NUMBER,
   longitude        NUMBER,
   elevation        NUMBER,
   elev_unit_id     VARCHAR2 (16),
   vertical_datum   VARCHAR2 (16),
   public_name      VARCHAR2 (32),
   long_name        VARCHAR2 (80),
   description      VARCHAR2 (512),
   data_sources     source_array
);
/

CREATE OR REPLACE TYPE loc_type AS OBJECT (
   office_id        VARCHAR2 (16),
   base_loc_id      VARCHAR2 (16),
   state_initial    VARCHAR2 (2),
   county_name      VARCHAR2 (40),
   timezone_name    VARCHAR2 (28),
   location_type    VARCHAR2 (16),
   latitude         NUMBER,
   longitude        NUMBER,
   elevation        NUMBER,
   elev_unit_id     VARCHAR2 (16),
   vertical_datum   VARCHAR2 (16),
   public_name      VARCHAR2 (32),
   long_name        VARCHAR2 (80),
   description      VARCHAR2 (512)
)
/

DROP TYPE alias_array;

CREATE OR REPLACE TYPE alias_type AS OBJECT (
   agency_id           VARCHAR2(16),
   alias_id            VARCHAR2(16),
   agency_name         VARCHAR2(80),
   alias_public_name   VARCHAR2(32),
   alias_long_name     VARCHAR2(80)
)
/

CREATE OR REPLACE
TYPE alias_array IS TABLE OF alias_type
/

-------------------------------------------------
-- Types coresponding to CWMS_CAT record types --
-- so JPublisher stays happy                   --
-------------------------------------------------

drop type cat_ts_otab_t;
drop type cat_ts_cwms_20_otab_t;
drop type cat_loc_otab_t;
drop type cat_loc_alias_otab_t;
drop type cat_param_otab_t;
drop type cat_sub_param_otab_t;
drop type cat_sub_loc_otab_t;
drop type cat_state_otab_t;
drop type cat_county_otab_t;
drop type cat_timezone_otab_t;
drop type cat_dss_file_otab_t;
drop type cat_dss_xchg_set_otab_t;
drop type cat_dss_xchg_ts_map_otab_t;

create or replace type cat_ts_obj_t as object(
   office_id           varchar2(16),
   cwms_ts_id          varchar2(183),
   interval_utc_offset number);
/                   

create type cat_ts_otab_t as table of cat_ts_obj_t;
/

create or replace type cat_ts_cwms_20_obj_t as object(
   office_id           varchar2(16),
   cwms_ts_id          varchar2(183),
   interval_utc_offset number(10),   
   user_privileges     number,
   inactive            number,
   lrts_timezone       varchar2(28));
/

create type cat_ts_cwms_20_otab_t as table of cat_ts_cwms_20_obj_t;
/

create or replace type cat_loc_obj_t as object(
   office_id      varchar2(16),
   base_loc_id    varchar2(16),
   state_initial  varchar2(2),
   county_name    varchar2(40),
   timezone_name  varchar2(28),
   location_type  varchar2(16),
   latitude       number,
   longitude      number,
   elevation      number,
   elev_unit_id   varchar2(16),
   vertical_datum varchar2(16),
   public_name    varchar2(32),
   long_name      varchar2(80),
   description    varchar2(512));
/

create type cat_loc_otab_t as table of cat_loc_obj_t;
/

create or replace type cat_loc_alias_obj_t as object(
   office_id varchar2(16),
   cwms_id   varchar2(16),
   source_id varchar2(16),
   gage_id   varchar2(32));
/

create type cat_loc_alias_otab_t as table of cat_loc_alias_obj_t;
/

create or replace type cat_param_obj_t as object(
   parameter_id      varchar2(16),
   param_long_name   varchar2(80),
   param_description varchar2(160),
   unit_id           varchar2(16),
   unit_long_name    varchar2(80),
   unit_description  varchar2(80));
/

create type cat_param_otab_t as table of cat_param_obj_t;
/

create or replace type cat_sub_param_obj_t as object(
   parameter_id    varchar2(16),
   subparameter_id varchar2(32),
   description     varchar2(80));
/

create type cat_sub_param_otab_t as table of cat_sub_param_obj_t;
/

create or replace type cat_sub_loc_obj_t as object(
   sublocation_id  varchar2(32),
   description     varchar2(80));
/

create type cat_sub_loc_otab_t as table of cat_sub_loc_obj_t;
/

create or replace type cat_state_obj_t as object(
   state_initial varchar2(2),
   state_name    varchar2(40));
/

create type cat_state_otab_t as table of cat_state_obj_t;
/

create or replace type cat_county_obj_t as object(
   county_id     varchar2(3),
   county_name   varchar2(40),
   state_initial varchar2(2));
/

create type cat_county_otab_t as table of cat_county_obj_t;
/

create or replace type cat_timezone_obj_t as object(
   timezone_name varchar2(28),
   utc_offset    interval day(2) to second(6),
   dst_offset    interval day(2) to second(6)); 
/

create type cat_timezone_otab_t as table of cat_timezone_obj_t;
/

create or replace type cat_dss_file_obj_t as object(
   dss_filemgr_url varchar2(32),
   dss_file_name   number(10));
/

create type cat_dss_file_otab_t as table of cat_dss_file_obj_t;
/

create or replace type cat_dss_xchg_set_obj_t as object(
   office_id                varchar2(16),
   dss_xchg_set_id          varchar(32),
   dss_xchg_set_description varchar(80), 
   dss_filemgr_url          varchar2(32),
   dss_file_name            varchar2(255),
   dss_xchg_direction_id    varchar2(16));
/                                         

create type cat_dss_xchg_set_otab_t as table of cat_dss_xchg_set_obj_t;
/

create or replace type cat_dss_xchg_ts_map_obj_t as object(
   cwms_ts_id            varchar2(183),
   dss_pathname          varchar2(391),
   dss_parameter_type_id varchar2(8),
   dss_unit_id           varchar2(16),
   dss_timezone_name     varchar2(28),
   dss_tz_usage_id       varchar2(8));
/

create type cat_dss_xchg_ts_map_otab_t as table of cat_dss_xchg_ts_map_obj_t;
/


SHOW ERRORS
SET ECHO OFF
SET TIME OFF

