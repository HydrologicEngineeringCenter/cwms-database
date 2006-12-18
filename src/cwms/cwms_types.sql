-- Defines the CWMS date-time, value, and quality types. 
set serveroutput on

------------------------------
-- drop types if they exist --
------------------------------
declare
   not_defined exception;
   has_dependencies exception;
   pragma exception_init(not_defined, -4043);
   pragma exception_init(has_dependencies, -2303);
   type id_array_t is table of varchar2(32);
   dropped_count   pls_integer;     
   defined_count   pls_integer;
   total_count     pls_integer := 0;
   pass_count      pls_integer := 0;
   type_names id_array_t := id_array_t(
      'tsv_type',
      'tsv_array',
      'at_tsv_type',
      'at_tsv_array',
      'char_16_array_type',
      'char_32_array_type',
      'char_183_array_type',
      'date_table_type',
      'source_type',
      'source_array',
      'loc_type_ds',
      'loc_type',
      'alias_type',
      'alias_array',
      'screen_crit_type',
      'SCREEN_CRIT_ARRAY',
      'cat_ts_obj_t',
      'cat_ts_otab_t',
      'cat_ts_cwms_20_obj_t',
      'cat_ts_cwms_20_otab_t',
      'cat_loc_obj_t',
      'cat_loc_otab_t',
      'cat_loc_alias_obj_t',
      'cat_loc_alias_otab_t',
      'cat_param_obj_t',
      'cat_param_otab_t',
      'cat_sub_param_obj_t',
      'cat_sub_param_otab_t',
      'cat_sub_loc_obj_t',
      'cat_sub_loc_otab_t',
      'cat_state_obj_t',
      'cat_state_otab_t',
      'cat_county_obj_t',
      'cat_county_otab_t',
      'cat_timezone_obj_t',
      'cat_timezone_otab_t',
      'cat_dss_file_obj_t',
      'cat_dss_file_otab_t',
      'cat_dss_xchg_set_obj_t',
      'cat_dss_xchg_set_otab_t',
      'cat_dss_xchg_ts_map_obj_t',
      'cat_dss_xchg_ts_map_otab_t');
begin
   defined_count := type_names.count;
   loop
      pass_count := pass_count + 1;
      dbms_output.put_line('Pass ' || pass_count);
      dropped_count := 0;
      dbms_output.put_line('');
      for i in type_names.first .. type_names.last loop
         if length(type_names(i)) > 0 then
            begin 
               execute immediate 'drop type ' || type_names(i);
               dbms_output.put_line('   Dropped type ' || type_names(i));
               dropped_count := dropped_count + 1;
               total_count   := total_count   + 1;
               type_names(i) := '';
            exception               
               when not_defined then defined_count := defined_count - 1; 
               when has_dependencies then null;
            end;
         end if;
      end loop;
      exit when dropped_count = 0;
   end loop;
   dbms_output.put_line('');
   if total_count != defined_count then
      dbms_output.put('*** WARNING: Only ' );
   end if;
   dbms_output.put_line('' || total_count || ' out of ' || defined_count || ' types dropped');
end;
/

CREATE TYPE tsv_type AS OBJECT (
   date_time    timestamp with time zone,
   value        BINARY_DOUBLE, 
   quality_code NUMBER);
/

CREATE TYPE tsv_array IS TABLE OF tsv_type;
/

-- This type represents a row in the time series value table.
-- BINARY_INTEGER or PLS_INTEGER should be used instead of NUMBER, which is better?
-- Also creating a type using either of those datatypes issues an error...
CREATE TYPE at_tsv_type AS OBJECT (date_time DATE, value BINARY_DOUBLE, quality NUMBER);
/
-- This type represents an array of the time series value table rows.
CREATE TYPE at_tsv_array IS TABLE OF at_tsv_type;
/


-- 16 character id array.
CREATE TYPE char_16_array_type IS TABLE OF VARCHAR2(16);
/
-- 32 character id array.
CREATE TYPE char_32_array_type IS TABLE OF VARCHAR2(32);
/
-- the size of a time series id.
CREATE TYPE char_183_array_type IS TABLE OF VARCHAR2(183);
/
CREATE TYPE date_table_type AS TABLE OF DATE;
/

-- CREATE TYPE TSVArray IS TABLE OF AT_TIME_SERIES_VALUE%ROWTYPE
--    INDEX BY BINARY_INTEGER;

CREATE TYPE source_type AS OBJECT (source_id VARCHAR2(16), gage_id   VARCHAR2(32));
/
CREATE TYPE source_array IS TABLE OF source_type;
/

CREATE TYPE loc_type_ds AS OBJECT (
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

CREATE TYPE loc_type AS OBJECT (
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

CREATE TYPE alias_type AS OBJECT (
   agency_id           VARCHAR2(16),
   alias_id            VARCHAR2(16),
   agency_name         VARCHAR2(80),
   alias_public_name   VARCHAR2(32),
   alias_long_name     VARCHAR2(80)
)
/
CREATE TYPE alias_array IS TABLE OF alias_type;
/

CREATE TYPE screen_crit_type AS OBJECT (
   season_start_day                 NUMBER,
   season_start_month               NUMBER,
   range_reject_lo                  NUMBER,
   range_reject_hi                  NUMBER,
   range_question_lo                NUMBER,
   range_question_hi                NUMBER,
   rate_change_reject_rise          NUMBER,
   rate_change_reject_fall          NUMBER,
   rate_change_quest_rise           NUMBER,
   rate_change_quest_fall           NUMBER,
   const_reject_duration_id         VARCHAR2 (16),
   const_reject_min                 NUMBER,
   const_reject_max                 NUMBER,
   const_reject_n_miss              NUMBER,
   const_quest_duration_id          VARCHAR2 (16),
   const_quest_min                  NUMBER,
   const_quest_max                  NUMBER,
   const_quest_n_miss               NUMBER,
   estimate_expression              VARCHAR2 (32 BYTE),
   duration_mag_test_flag           VARCHAR2 (1 BYTE)
)
/

CREATE TYPE SCREEN_CRIT_ARRAY IS TABLE OF SCREEN_CRIT_type
/
-------------------------------------------------
-- Types coresponding to CWMS_CAT record types --
-- so JPublisher stays happy                   --
-------------------------------------------------

create type cat_ts_obj_t as object(
   office_id           varchar2(16),
   cwms_ts_id          varchar2(183),
   interval_utc_offset number);
/                   
create type cat_ts_otab_t as table of cat_ts_obj_t;
/

create type cat_ts_cwms_20_obj_t as object(
   office_id           varchar2(16),
   cwms_ts_id          varchar2(183),
   interval_utc_offset number(10),   
   user_privileges     number,
   inactive            number,
   lrts_timezone       varchar2(28));
/
create type cat_ts_cwms_20_otab_t as table of cat_ts_cwms_20_obj_t;
/

create type cat_loc_obj_t as object(
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

create type cat_loc_alias_obj_t as object(
   office_id varchar2(16),
   cwms_id   varchar2(16),
   source_id varchar2(16),
   gage_id   varchar2(32));
/
create type cat_loc_alias_otab_t as table of cat_loc_alias_obj_t;
/

create type cat_param_obj_t as object(
   parameter_id      varchar2(16),
   param_long_name   varchar2(80),
   param_description varchar2(160),
   unit_id           varchar2(16),
   unit_long_name    varchar2(80),
   unit_description  varchar2(80));
/
create type cat_param_otab_t as table of cat_param_obj_t;
/

create type cat_sub_param_obj_t as object(
   parameter_id    varchar2(16),
   subparameter_id varchar2(32),
   description     varchar2(80));
/
create type cat_sub_param_otab_t as table of cat_sub_param_obj_t;
/

create type cat_sub_loc_obj_t as object(
   sublocation_id  varchar2(32),
   description     varchar2(80));
/
create type cat_sub_loc_otab_t as table of cat_sub_loc_obj_t;
/

create type cat_state_obj_t as object(
   state_initial varchar2(2),
   state_name    varchar2(40));
/
create type cat_state_otab_t as table of cat_state_obj_t;
/

create type cat_county_obj_t as object(
   county_id     varchar2(3),
   county_name   varchar2(40),
   state_initial varchar2(2));
/
create type cat_county_otab_t as table of cat_county_obj_t;
/

create type cat_timezone_obj_t as object(
   timezone_name varchar2(28),
   utc_offset    interval day(2) to second(6),
   dst_offset    interval day(2) to second(6)); 
/
create type cat_timezone_otab_t as table of cat_timezone_obj_t;
/

create type cat_dss_file_obj_t as object(
   dss_filemgr_url varchar2(32),
   dss_file_name   number(10));
/
create type cat_dss_file_otab_t as table of cat_dss_file_obj_t;
/

create type cat_dss_xchg_set_obj_t as object(
   office_id                varchar2(16),
   dss_xchg_set_id          varchar(32),
   dss_xchg_set_description varchar(80), 
   dss_filemgr_url          varchar2(32),
   dss_file_name            varchar2(255),
   dss_xchg_direction_id    varchar2(16),
   dss_xchg_last_update     timestamp(6));
/                                         
create type cat_dss_xchg_set_otab_t as table of cat_dss_xchg_set_obj_t;
/

create type cat_dss_xchg_ts_map_obj_t as object(
   cwms_ts_id            varchar2(183),
   dss_pathname          varchar2(391),
   dss_parameter_type_id varchar2(8),
   dss_unit_id           varchar2(16),
   dss_timezone_name     varchar2(28),
   dss_tz_usage_id       varchar2(8));
/
create type cat_dss_xchg_ts_map_otab_t as table of cat_dss_xchg_ts_map_obj_t;
/

commit;
