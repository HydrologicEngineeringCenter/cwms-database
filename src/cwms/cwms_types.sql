/* Formatted on 2008/06/24 06:40 (Formatter Plus v4.8.8) */
-- Defines the CWMS date-time, value, and quality types.
---------------------------------------------------------------------------
-- This script may create type bodies with errors due to interdependence --
-- on packages. Continue past the errors and let the schema re-compile   --
-- in the main script determine if there is actually a problem.          --
---------------------------------------------------------------------------
-- WHENEVER sqlerror exit sql.sqlcode
WHENEVER sqlerror continue
SET define on
@@../cwms/defines.sql
SET serveroutput on

------------------------------
-- drop types if they exist --
------------------------------

DECLARE
   not_defined        EXCEPTION;
   has_dependencies   EXCEPTION;
   PRAGMA EXCEPTION_INIT (not_defined, -4043);
   PRAGMA EXCEPTION_INIT (has_dependencies, -2303);

   TYPE id_array_t IS TABLE OF VARCHAR2 (32);

   dropped_count      PLS_INTEGER;
   defined_count      PLS_INTEGER := 0;
   total_count        PLS_INTEGER := 0;
   pass_count         PLS_INTEGER := 0;
   type_names         id_array_t  := id_array_t();
BEGIN
   for rec in (select object_name
                 from dba_objects
                where owner = '&cwms_schema'
                  and object_type = 'TYPE'
                  and object_name not like 'SYS\_%' escape '\'
             order by object_name)
   loop
      defined_count := defined_count + 1;
      type_names.extend;
      type_names(defined_count) := rec.object_name;
   end loop;

   LOOP
      pass_count := pass_count + 1;
      DBMS_OUTPUT.put_line ('Pass ' || pass_count);
      dropped_count := 0;
      DBMS_OUTPUT.put_line ('');

      FOR i IN 1..defined_count
      LOOP
         IF LENGTH (type_names (i)) > 0
         THEN
            BEGIN
               EXECUTE IMMEDIATE 'drop type ' || type_names (i);

               DBMS_OUTPUT.put_line ('   Dropped type ' || type_names (i));
               dropped_count := dropped_count + 1;
               total_count := total_count + 1;
               type_names (i) := '';
            EXCEPTION
               WHEN not_defined
               THEN
                  IF pass_count = 1
                  THEN
                  defined_count := defined_count - 1;
                  END IF;
               WHEN has_dependencies
               THEN
                  NULL;
            END;
         END IF;
      END LOOP;

      EXIT WHEN dropped_count = 0;
   END LOOP;

   DBMS_OUTPUT.put_line ('');

   IF total_count != defined_count
   THEN
      DBMS_OUTPUT.put ('*** WARNING: Only ');
   END IF;

   DBMS_OUTPUT.put_line (   ''
                         || total_count
                         || ' out of '
                         || defined_count
                         || ' types dropped'
                        );
END;
/

CREATE OR REPLACE
TYPE SHEF_SPEC_TYPE
AS
   OBJECT (
      cwms_ts_id VARCHAR2 (132),
      shef_location_id VARCHAR2 (8),
      shef_pe_code VARCHAR2 (2),
      shef_tse_code VARCHAR2 (3),
      shef_duration VARCHAR2 (4),
      shef_incoming_units VARCHAR2 (16),
      shef_time_zone_id VARCHAR2 (3),
      daylight_savings VARCHAR2 (1),               -- T or F psuedo boolean.
      interval_utc_offset NUMBER,                             -- in minutes.
      snap_forward_minutes NUMBER,
      snap_backward_minutes NUMBER,
      ts_active_flag VARCHAR2 (1)                  -- T or F psuedo boolean.
   );
/

CREATE OR REPLACE
TYPE  SHEF_SPEC_ARRAY IS TABLE OF shef_spec_type;
/

CREATE TYPE tsv_type AS OBJECT (
   date_time      TIMESTAMP WITH TIME ZONE,
   VALUE          BINARY_DOUBLE,
   quality_code   NUMBER
);
/

CREATE TYPE tsv_array IS TABLE OF tsv_type;
/

CREATE OR REPLACE TYPE ztsv_type
AS
   OBJECT (date_time DATE, VALUE BINARY_DOUBLE, quality_code NUMBER);
/

CREATE OR REPLACE TYPE ztsv_array IS TABLE OF ztsv_type;
/

CREATE OR REPLACE TYPE ztimeseries_type
AS
   OBJECT (tsid VARCHAR2 (183), unit VARCHAR2 (16), data ztsv_array);
/

CREATE OR REPLACE TYPE ztimeseries_array IS TABLE OF ztimeseries_type;
/
/*
-- This type represents a row in the time series value table.
-- BINARY_INTEGER or PLS_INTEGER should be used instead of NUMBER, which is better?
-- Also creating a type using either of those datatypes issues an error...

CREATE TYPE at_tsv_type AS OBJECT (
   date_time   DATE,
   VALUE       BINARY_DOUBLE,
   quality     NUMBER
);
/

-- This type represents an array of the time series value table rows.

CREATE TYPE at_tsv_array IS TABLE OF at_tsv_type;
/
*/

-- 16 character id array.

CREATE TYPE char_16_array_type IS TABLE OF VARCHAR2 (16);
/

-- 32 character id array.

CREATE TYPE char_32_array_type IS TABLE OF VARCHAR2 (32);
/

-- 49 character id array.

CREATE TYPE char_49_array_type IS TABLE OF VARCHAR2 (49);
/

-- the size of a time series id.

CREATE TYPE char_183_array_type IS TABLE OF VARCHAR2 (183);
/

CREATE TYPE date_table_type AS TABLE OF DATE;
/

-- used for store_ts_multi

CREATE TYPE timeseries_type AS OBJECT (
   tsid   VARCHAR2 (183),
   unit   VARCHAR2 (16),
   DATA   tsv_array
);
/

CREATE TYPE timeseries_array IS TABLE OF timeseries_type;
/

-- used for retrieve_ts2_multi

CREATE TYPE timeseries_req_type AS OBJECT (
   tsid         VARCHAR2 (183),
   unit         VARCHAR2 (16),
   start_time   DATE,
   end_time     DATE
);
/

CREATE TYPE timeseries_req_array IS TABLE OF timeseries_req_type;
/

CREATE TYPE nested_ts_type AS OBJECT (
   SEQUENCE     INTEGER,
   tsid         VARCHAR2 (183),
   units        VARCHAR2 (16),
   start_time   DATE,
   end_time     DATE,
   DATA         tsv_array
);
/

CREATE TYPE nested_ts_table IS TABLE OF nested_ts_type;
/

-- CREATE TYPE TSVArray IS TABLE OF AT_TIME_SERIES_VALUE%ROWTYPE
--    INDEX BY BINARY_INTEGER;

CREATE TYPE source_type AS OBJECT (
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/

CREATE TYPE source_array IS TABLE OF source_type;
/

CREATE OR REPLACE TYPE tr_template_set_type AS OBJECT (
   description             VARCHAR2 (132),
   store_dep_flag          VARCHAR2 (1),
   unit_system             VARCHAR2 (2),
   transform_id            VARCHAR2 (32),
   lookup_agency           VARCHAR2 (32),
   lookup_rating_version   VARCHAR2 (32),
   scaling_arg_a           NUMBER,
   scaling_arg_b           NUMBER,
   scaling_arg_c           NUMBER,
   array_of_masks          char_183_array_type
);
/

CREATE OR REPLACE TYPE tr_template_set_array IS TABLE OF tr_template_set_type;
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
   agency_id           VARCHAR2 (16),
   alias_id            VARCHAR2 (16),
   agency_name         VARCHAR2 (80),
   alias_public_name   VARCHAR2 (32),
   alias_long_name     VARCHAR2 (80)
)
/

CREATE TYPE alias_array IS TABLE OF alias_type;
/

CREATE OR REPLACE TYPE screen_dur_mag_type AS OBJECT (
   duration_id   VARCHAR2 (16),
   reject_lo     NUMBER,
   reject_hi     NUMBER,
   question_lo   NUMBER,
   question_hi   NUMBER
)
/

CREATE OR REPLACE TYPE screen_dur_mag_array IS TABLE OF screen_dur_mag_type
/

CREATE OR REPLACE TYPE screen_crit_type AS OBJECT (
   season_start_day           NUMBER,
   season_start_month         NUMBER,
   range_reject_lo            NUMBER,
   range_reject_hi            NUMBER,
   range_question_lo          NUMBER,
   range_question_hi          NUMBER,
   rate_change_reject_rise    NUMBER,
   rate_change_reject_fall    NUMBER,
   rate_change_quest_rise     NUMBER,
   rate_change_quest_fall     NUMBER,
   const_reject_duration_id   VARCHAR2 (16),
   const_reject_min           NUMBER,
   const_reject_tolerance     NUMBER,
   const_reject_n_miss        NUMBER,
   const_quest_duration_id    VARCHAR2 (16),
   const_quest_min            NUMBER,
   const_quest_tolerance      NUMBER,
   const_quest_n_miss         NUMBER,
   estimate_expression        VARCHAR2 (32 BYTE),
   dur_mag_array              screen_dur_mag_array
)
/

CREATE TYPE screen_crit_array IS TABLE OF screen_crit_type
/

CREATE OR REPLACE TYPE screening_control_t AS OBJECT (
   range_active_flag         VARCHAR2 (1),
   rate_change_active_flag   VARCHAR2 (1),
   const_active_flag         VARCHAR2 (1),
   dur_mag_active_flag       VARCHAR2 (1)
)
/

CREATE OR REPLACE TYPE cwms_ts_id_t AS OBJECT (
   cwms_ts_id   VARCHAR2 (183)
);
/

CREATE OR REPLACE TYPE cwms_ts_id_array IS TABLE OF cwms_ts_id_t;
/

-------------------------------------------------
-- Types coresponding to CWMS_CAT record types --
-- so JPublisher stays happy                   --
-------------------------------------------------

CREATE TYPE cat_ts_obj_t AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2 (183),
   interval_utc_offset   NUMBER
);
/

CREATE TYPE cat_ts_otab_t AS TABLE OF cat_ts_obj_t;
/

CREATE TYPE cat_ts_cwms_20_obj_t AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2 (183),
   interval_utc_offset   NUMBER (10),
   user_privileges       NUMBER,
   inactive              NUMBER,
   lrts_timezone         VARCHAR2 (28)
);
/

CREATE TYPE cat_ts_cwms_20_otab_t AS TABLE OF cat_ts_cwms_20_obj_t;
/

CREATE TYPE cat_loc_obj_t AS OBJECT (
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
);
/

CREATE TYPE cat_loc_otab_t AS TABLE OF cat_loc_obj_t;
/

CREATE TYPE cat_location_obj_t AS OBJECT (
   db_office_id       VARCHAR2 (16),
   location_id        VARCHAR2 (49),
   base_location_id   VARCHAR2 (16),
   sub_location_id    VARCHAR2 (32),
   state_initial      VARCHAR2 (2),
   county_name        VARCHAR2 (40),
   time_zone_name     VARCHAR2 (28),
   location_type      VARCHAR2 (32),
   latitude           NUMBER,
   longitude          NUMBER,
   horizontal_datum   VARCHAR2 (16),
   elevation          NUMBER,
   elev_unit_id       VARCHAR2 (16),
   vertical_datum     VARCHAR2 (16),
   public_name        VARCHAR2 (32),
   long_name          VARCHAR2 (80),
   description        VARCHAR2 (512),
   active_flag        VARCHAR2 (1)
);
/

CREATE TYPE cat_location_otab_t AS TABLE OF cat_location_obj_t;
/

CREATE TYPE cat_location2_obj_t AS OBJECT (
   db_office_id         VARCHAR2 (16),
   location_id          VARCHAR2 (49),
   base_location_id     VARCHAR2 (16),
   sub_location_id      VARCHAR2 (32),
   state_initial        VARCHAR2 (2),
   county_name          VARCHAR2 (40),
   time_zone_name       VARCHAR2 (28),
   location_type        VARCHAR2 (32),
   latitude             NUMBER,
   longitude            NUMBER,
   horizontal_datum     VARCHAR2 (16),
   elevation            NUMBER,
   elev_unit_id         VARCHAR2 (16),
   vertical_datum       VARCHAR2 (16),
   public_name          VARCHAR2 (32),
   long_name            VARCHAR2 (80),
   description          VARCHAR2 (512),
   active_flag          VARCHAR2 (1),
   location_kind_id     varchar2(32),
   map_label            varchar2(50),
   published_latitude   number,
   published_longitude  number,
   bounding_office_id   varchar2(16),
   nation_id            varchar2(48),
   nearest_city         varchar2(50)
);
/

CREATE TYPE cat_location2_otab_t AS TABLE OF cat_location2_obj_t;
/

CREATE TYPE cat_location_kind_obj_t AS OBJECT (
   office_id        VARCHAR2(16),
   location_kind_id VARCHAR2(32),
   description      VARCHAR2(256)
);
/

CREATE TYPE cat_location_kind_otab_t AS TABLE OF cat_location_kind_obj_t;
/

CREATE TYPE cat_loc_alias_obj_t AS OBJECT (
   office_id   VARCHAR2 (16),
   cwms_id     VARCHAR2 (16),
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/

CREATE TYPE cat_loc_alias_otab_t AS TABLE OF cat_loc_alias_obj_t;
/

CREATE TYPE cat_param_obj_t AS OBJECT (
   parameter_id        VARCHAR2 (16),
   param_long_name     VARCHAR2 (80),
   param_description   VARCHAR2 (160),
   unit_id             VARCHAR2 (16),
   unit_long_name      VARCHAR2 (80),
   unit_description    VARCHAR2 (80)
);
/

CREATE TYPE cat_param_otab_t AS TABLE OF cat_param_obj_t;
/

CREATE TYPE cat_sub_param_obj_t AS OBJECT (
   parameter_id      VARCHAR2 (16),
   subparameter_id   VARCHAR2 (32),
   description       VARCHAR2 (80)
);
/

CREATE TYPE cat_sub_param_otab_t AS TABLE OF cat_sub_param_obj_t;
/

CREATE TYPE cat_sub_loc_obj_t AS OBJECT (
   sublocation_id   VARCHAR2 (32),
   description      VARCHAR2 (80)
);
/

CREATE TYPE cat_sub_loc_otab_t AS TABLE OF cat_sub_loc_obj_t;
/

CREATE TYPE cat_state_obj_t AS OBJECT (
   state_initial   VARCHAR2 (2),
   state_name      VARCHAR2 (40)
);
/

CREATE TYPE cat_state_otab_t AS TABLE OF cat_state_obj_t;
/

CREATE TYPE cat_county_obj_t AS OBJECT (
   county_id       VARCHAR2 (3),
   county_name     VARCHAR2 (40),
   state_initial   VARCHAR2 (2)
);
/

CREATE TYPE cat_county_otab_t AS TABLE OF cat_county_obj_t;
/

CREATE TYPE cat_timezone_obj_t AS OBJECT (
   timezone_name   VARCHAR2 (28),
   utc_offset      INTERVAL DAY (2)TO SECOND (6),
   dst_offset      INTERVAL DAY (2)TO SECOND (6)
);
/

CREATE TYPE cat_timezone_otab_t AS TABLE OF cat_timezone_obj_t;
/

CREATE TYPE cat_dss_file_obj_t AS OBJECT (
   office_id         VARCHAR2 (16),
   dss_filemgr_url   VARCHAR2 (32),
   dss_file_name     NUMBER (10)
);
/

CREATE TYPE cat_dss_file_otab_t AS TABLE OF cat_dss_file_obj_t;
/

CREATE TYPE cat_dss_xchg_set_obj_t AS OBJECT (
   office_id                  VARCHAR2 (16),
   dss_xchg_set_id            VARCHAR (32),
   dss_xchg_set_description   VARCHAR (80),
   dss_filemgr_url            VARCHAR2 (32),
   dss_file_name              VARCHAR2 (255),
   dss_xchg_direction_id      VARCHAR2 (16),
   dss_xchg_last_update       TIMESTAMP ( 6 )
);
/

CREATE TYPE cat_dss_xchg_set_otab_t AS TABLE OF cat_dss_xchg_set_obj_t;
/

CREATE TYPE cat_dss_xchg_ts_map_obj_t AS OBJECT (
   office_id               VARCHAR2 (16),
   cwms_ts_id              VARCHAR2 (183),
   dss_pathname            VARCHAR2 (391),
   dss_parameter_type_id   VARCHAR2 (8),
   dss_unit_id             VARCHAR2 (16),
   dss_timezone_name       VARCHAR2 (28),
   dss_tz_usage_id         VARCHAR2 (8)
);
/

CREATE TYPE cat_dss_xchg_tsmap_otab_t AS TABLE OF cat_dss_xchg_ts_map_obj_t;
/

CREATE OR REPLACE TYPE screen_assign_t AS OBJECT (
   cwms_ts_id        VARCHAR2 (183),
   active_flag       VARCHAR2 (1),
   resultant_ts_id   VARCHAR2 (183)
)
/

CREATE OR REPLACE TYPE screen_assign_array IS TABLE OF screen_assign_t
/

CREATE OR REPLACE TYPE loc_alias_type AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_alias_id   VARCHAR2 (128)
)
/

CREATE OR REPLACE TYPE loc_alias_array IS TABLE OF loc_alias_type;
/

CREATE OR REPLACE TYPE loc_alias_type2 AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_attribute  NUMBER,
   loc_alias_id   VARCHAR2 (128)
)
/

CREATE OR REPLACE TYPE loc_alias_array2 IS TABLE OF loc_alias_type2;
/

CREATE OR REPLACE TYPE loc_alias_type3 AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_attribute  NUMBER,
   loc_alias_id   VARCHAR2 (128),
   loc_ref_id     VARCHAR2 (49)
)
/

CREATE OR REPLACE TYPE loc_alias_array3 IS TABLE OF loc_alias_type3;
/

CREATE OR REPLACE TYPE group_type AS OBJECT (
   GROUP_ID     VARCHAR2 (32),
   group_desc   VARCHAR2 (128)
)
/

CREATE OR REPLACE TYPE group_array IS TABLE OF group_type;
/

CREATE OR REPLACE TYPE group_type2 AS OBJECT (
   GROUP_ID          VARCHAR2 (32),
   group_desc        VARCHAR2 (128),
   shared_alias_id   VARCHAR2 (128),
   shared_loc_ref_id VARCHAR2 (49)
)
/

CREATE OR REPLACE TYPE group_array2 IS TABLE OF group_type2;
/

CREATE OR REPLACE TYPE group_cat_t AS OBJECT (
   loc_category_id   VARCHAR2 (32),
   loc_group_id      VARCHAR2 (32)
)
/

CREATE OR REPLACE TYPE group_cat_tab_t IS TABLE OF group_cat_t
/


create or replace type str_tab_t is table of varchar2(32767)
/

create or replace type str_tab_tab_t is table of str_tab_t
/

create or replace type number_tab_t is table of number;
/

create or replace type double_tab_t is table of binary_double;
/

create or replace type double_tab_tab_t is table of double_tab_t;
/

create or replace type log_message_properties_t as object (
   msg_id     varchar2(32),
   prop_name  varchar2(64),
   prop_type  number(1),
   prop_value number,
   prop_text  varchar2(4000)
)
/

create or replace type log_message_props_tab_t as table of log_message_properties_t
/

create type location_ref_t is object(
   base_location_id varchar2(16),
   sub_location_id  varchar2(32),
   office_id        varchar2(16),

   constructor function location_ref_t (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   return self as result,

   constructor function location_ref_t (
      p_office_and_location_id in varchar2) -- office-id/location-id
   return self as result,

   constructor function location_ref_t (
      p_location_code in number)
   return self as result,

   member function get_location_code(
      p_create_if_necessary in varchar2 default 'F')
   return number,

   member function get_location_id
   return varchar2,

   member function get_office_code
   return number,

   member function get_office_id
   return varchar2,

   member procedure get_codes(
      p_location_code       out number,
      p_office_code         out number,
      p_create_if_necessary in  varchar2 default 'F'),

   member procedure create_location(
      p_fail_if_exists in varchar2)
)
/

create or replace type body location_ref_t
as
   constructor function location_ref_t (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   return self as result
   is
   begin
      base_location_id := cwms_util.get_base_id(p_location_id);
      sub_location_id  := cwms_util.get_sub_id(p_location_id);
      office_id        := nvl(p_office_id, cwms_util.user_office_id);
      return;
   end location_ref_t;

   constructor function location_ref_t (
      p_office_and_location_id in varchar2)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_office_and_location_id, '/', 1);
      if l_parts.count = 2 and length(l_parts(1)) <= 16 then
         base_location_id := cwms_util.get_base_id(trim(l_parts(2)));
         sub_location_id  := cwms_util.get_sub_id(trim(l_parts(2)));
         office_id        := upper(trim(l_parts(1)));
      else
         base_location_id := cwms_util.get_base_id(trim(l_parts(1)));
         sub_location_id  := cwms_util.get_sub_id(trim(l_parts(1)));
         office_id        := cwms_util.user_office_id;
      end if;
      return;
   end location_ref_t;

   constructor function location_ref_t (
      p_location_code in number)
   return self as result
   is
   begin
      select bl.base_location_id,
             pl.sub_location_id,
             o.office_id
        into self.base_location_id,
             self.sub_location_id,
             self.office_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      return;
   end location_ref_t;

   member function get_location_code(
      p_create_if_necessary in varchar2 default 'F')
   return number
   is
      l_location_code number(10);
   begin
      if cwms_util.is_true(p_create_if_necessary) then
         declare
            LOCATION_ID_ALREADY_EXISTS exception; pragma exception_init (LOCATION_ID_ALREADY_EXISTS, -20026);
         begin
            cwms_loc.create_location2(
               p_location_id => base_location_id
                  || substr('-', 1, length(sub_location_id))
                  || sub_location_id,
               p_db_office_id => office_id);
         exception
            when LOCATION_ID_ALREADY_EXISTS then
               null;
         end;
      end if;
      select pl.location_code
        into l_location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = self.get_office_id
         and bl.db_office_code = o.office_code
         and bl.base_location_id = self.base_location_id
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, '.') = nvl(self.sub_location_id, '.');
      return l_location_code;
   end get_location_code;

   member function get_location_id
   return varchar2
   is
      l_location_id varchar2(49);
   begin
      l_location_id := self.base_location_id
        || SUBSTR ('-', 1, LENGTH (self.sub_location_id))
        || self.sub_location_id;
      return l_location_id;
   end get_location_id;

   member function get_office_code
   return number
   is
      l_office_code number(10);
   begin
      select office_code
        into l_office_code
        from cwms_office
       where office_id = self.get_office_id;
      return l_office_code;
   end get_office_code;

   member function get_office_id
   return varchar2
   is
   begin
      return nvl(office_id, cwms_util.user_office_id);
   end;

   member procedure get_codes(
      p_location_code       out number,
      p_office_code         out number,
      p_create_if_necessary in  varchar2 default 'F')
   is
   begin
      if cwms_util.is_true(p_create_if_necessary) then
         create_location(p_fail_if_exists => 'F');
      end if;
      select pl.location_code,
             o.office_code
        into p_location_code,
             p_office_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = self.get_office_id
         and bl.db_office_code = o.office_code
         and bl.base_location_id = self.base_location_id
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, '.') = nvl(self.sub_location_id, '.');
      return;
   end get_codes;

   member procedure create_location(
      p_fail_if_exists in varchar2)
   is
      LOCATION_ID_ALREADY_EXISTS exception; pragma exception_init (LOCATION_ID_ALREADY_EXISTS, -20026);
   begin
      cwms_loc.create_location2(
         p_location_id => base_location_id
            || substr('-', 1, length(sub_location_id))
            || sub_location_id,
         p_db_office_id => office_id);
   exception
      when LOCATION_ID_ALREADY_EXISTS then
         if cwms_util.is_true(p_fail_if_exists) then
            raise;
         else
            null;
         end if;
   end create_location;

end;
/
show errors;

create or replace type location_ref_tab_t is table of location_ref_t;
/

create or replace type location_obj_t as object
(
   location_ref         location_ref_t,
   state_initial        VARCHAR2 (2),
   county_name          VARCHAR2 (40),
   time_zone_name       VARCHAR2 (28),
   location_type        VARCHAR2 (32),
   latitude             NUMBER,
   longitude            NUMBER,
   horizontal_datum     VARCHAR2 (16),
   elevation            NUMBER,
   elev_unit_id         VARCHAR2 (16),
   vertical_datum       VARCHAR2 (16),
   public_name          VARCHAR2 (32),
   long_name            VARCHAR2 (80),
   description          VARCHAR2 (512),
   active_flag          VARCHAR2 (1),
   location_kind_id     varchar2(32),
   map_label            varchar2(50),
   published_latitude   number,
   published_longitude  number,
   bounding_office_id   varchar2(16),
   bounding_office_name varchar2(32),
   nation_id            varchar2(48),
   nearest_city         varchar2(50)
);
/



create or replace type specified_level_t is object(
   office_id   varchar2(16),
   level_id    varchar2(256),
   description varchar2(256),

   constructor function specified_level_t(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2 default null)
      return self as result,

   constructor function specified_level_t(
      p_level_code number)
      return self as result,

   member procedure init(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2),

   member procedure store
)
/

create or replace type body specified_level_t
as
   constructor function specified_level_t(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2 default null)
      return self as result
   is
   begin
      init(p_office_code, p_level_id, p_description);
      return;
   end specified_level_t;

   constructor function specified_level_t(
      p_level_code number)
      return self as result
   is
      l_level_id    varchar2(256);
      l_description varchar2(256);
   begin
      select specified_level_id,
             description
        into l_level_id,
             l_description
        from at_specified_level
       where specified_level_code = p_level_code;

      init(p_level_code, l_level_id, l_description);
      return;
   end specified_level_t;

   member procedure init(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2)
   is
   begin
      select office_id
        into office_id
        from cwms_office
       where office_code = p_office_code;

      level_id    := p_level_id;
      description := p_description;
   end init;

   member procedure store
   is
   begin
      cwms_level.store_specified_level(level_id, description, 'F', office_id);
   end store;
end;
/
show errors;

create or replace type specified_level_tab_t is table of specified_level_t
/

create or replace type loc_lvl_indicator_cond_t is object
(
   indicator_value            number(1),
   expression                 varchar2(64),
   comparison_operator_1      varchar2(2),
   comparison_value_1         binary_double,
   comparison_unit            number(10),
   connector                  varchar2(3),
   comparison_operator_2      varchar2(2),
   comparison_value_2         binary_double,
   rate_expression            varchar2(64),
   rate_comparison_operator_1 varchar2(2),
   rate_comparison_value_1    binary_double,
   rate_comparison_unit       number(10),
   rate_connector             varchar2(3),
   rate_comparison_operator_2 varchar2(2),
   rate_comparison_value_2    binary_double,
   rate_interval              interval day(3) to second(0),
   description                varchar2(256),
   factor                     binary_double,
   offset                     binary_double,
   rate_factor                binary_double,
   rate_offset                binary_double,
   interval_factor            binary_double,
   uses_reference             varchar2(1),
   expression_tokens          str_tab_t,
   rate_expression_tokens     str_tab_t,

   constructor function loc_lvl_indicator_cond_t(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   return self as result,

   constructor function loc_lvl_indicator_cond_t(
      p_row in urowid)
      return self as result,

   member procedure init(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2),

   member procedure store(
      p_level_indicator_code in number),

   -----------------------------------------------------------------------------
   -- member fields factor and offset must previously be set to provide any
   -- necessary units conversion for the comparison
   --
   -- p_rate must be specified for the interval indicated in the member field
   -- rate_interval
   -----------------------------------------------------------------------------
   member function is_set(
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double,
      p_rate    in binary_double)
   return boolean
)
/
show errors;

create or replace type body loc_lvl_indicator_cond_t
as
   constructor function loc_lvl_indicator_cond_t(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   return self as result
   is
   begin
      init(p_indicator_value,
           p_expression,
           p_comparison_operator_1,
           p_comparison_value_1,
           p_comparison_unit,
           p_connector,
           p_comparison_operator_2,
           p_comparison_value_2,
           p_rate_expression,
           p_rate_comparison_operator_1,
           p_rate_comparison_value_1,
           p_rate_comparison_unit,
           p_rate_connector,
           p_rate_comparison_operator_2,
           p_rate_comparison_value_2,
           p_rate_interval,
           p_description);
         return;
   end loc_lvl_indicator_cond_t;

   constructor function loc_lvl_indicator_cond_t(
      p_row in urowid)
      return self as result
   is
      l_rec at_loc_lvl_indicator_cond%rowtype;
   begin
      select *
        into l_rec
        from at_loc_lvl_indicator_cond
       where rowid = p_row;
      init(l_rec.level_indicator_value,
           l_rec.expression,
           l_rec.comparison_operator_1,
           l_rec.comparison_value_1,
           l_rec.comparison_unit,
           l_rec.connector,
           l_rec.comparison_operator_2,
           l_rec.comparison_value_2,
           l_rec.rate_expression,
           l_rec.rate_comparison_operator_1,
           l_rec.rate_comparison_value_1,
           l_rec.rate_comparison_unit,
           l_rec.rate_connector,
           l_rec.rate_comparison_operator_2,
           l_rec.rate_comparison_value_2,
           l_rec.rate_interval,
           l_rec.description);

      return;
   end loc_lvl_indicator_cond_t;


   member procedure init(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   is
      l_expression                 varchar2(128) := trim(upper(p_expression));
      l_comparison_operator_1      varchar2(2)   := trim(upper(p_comparison_operator_1));
      l_connector                  varchar2(3)   := trim(upper(p_connector));
      l_comparison_operator_2      varchar2(2)   := trim(upper(p_comparison_operator_2));
      l_rate_expression            varchar2(128) := trim(upper(p_rate_expression));
      l_rate_comparison_operator_1 varchar2(2)   := trim(upper(p_rate_comparison_operator_1));
      l_rate_connector             varchar2(3)   := trim(upper(p_rate_connector));
      l_rate_comparison_operator_2 varchar2(2)   := trim(upper(p_rate_comparison_operator_2));
      l_description                varchar2(256) := trim(p_description);

      function tokenize_expression(
         p_expr    in varchar2,
         p_is_rate in boolean)
      return str_tab_t
      is
         l_expr   varchar2(128) := p_expr;
         l_tokens str_tab_t;
      begin
         if p_expr is not null then
            ---------------------------------------------------------------
            -- replace V, L, L1, L2, R with ARG1, ARG2, ARG2, ARG3, ARG4 --
            ---------------------------------------------------------------
            if p_is_rate then
               if regexp_instr(p_expr, '(^|\(|[[:space:]])(-?)(V|L[12]?)([[:space:]]|\)|$)') > 0 then
                  cwms_err.raise('ERROR', 'Cannot reference variables V, L, L1, or L2 in rate expression');
               end if;
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)R([[:space:]]|\)|$)',   '\1\2ARG4\3');
            else
               if regexp_instr(p_expr, '(^|\(|[[:space:]])(-?)R([[:space:]]|\)|$)') > 0 then
                  cwms_err.raise('ERROR', 'Cannot reference variable R in non-rate expression');
               end if;
               l_expr := regexp_replace(p_expr, '(^|\(|[[:space:]])(-?)V([[:space:]]|\)|$)',   '\1\2ARG1\3');
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)L1?([[:space:]]|\)|$)', '\1\2ARG2\3');
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)L2([[:space:]]|\)|$)',  '\1\2ARG3\3');
            end if;
            -------------------------------
            -- tokenize algebraic or RPN --
            -------------------------------
            if instr(l_expr, '(') > 0 then
               l_tokens := cwms_util.tokenize_algebraic(l_expr);
            else
               l_tokens := cwms_util.tokenize_rpn(l_expr);
               if l_tokens.count > 1 and
                  l_tokens(l_tokens.count) not in
                  ('+','-','*','/','//','%','^','ABS','ACOS','ASIN','ATAN','CEIL',
                   'COS','EXP','FLOOR','LN','LOG', 'SIGN','SIN','TAN','TRUNC')
               then
                  l_tokens := cwms_util.tokenize_algebraic(l_expr);
               end if;
            end if;
         end if;
         return l_tokens;
      end;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_indicator_value not in (1,2,3,4,5) then
         cwms_err.raise(
            'INVALID_ITEM',
            p_indicator_value,
            'location level indicator value');
      end if;
      if l_expression is null then
         cwms_err.raise('ERROR', 'Comparison expression must be specified');
      end if;
      if regexp_instr(l_expression, '(^|\(|[[:space:]])-?R([[:space:]]|\)|$)') > 0 then
         cwms_err.raise('ERROR', 'Expression cannot reference rate variable R');
      end if;
      if l_expression is not null then
         if regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?V([[:space:]]|\)|$)') > 0 or
            regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?L1?([[:space:]]|\)|$)') > 0 or
            regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?L2([[:space:]]|\)|$)') > 0
         then
            cwms_err.raise('ERROR', 'Rate expression cannot reference non-rate variables V, L (or L1) and L2');
         end if;
      end if;
      if l_comparison_operator_1 not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_comparison_operator_1,
            'comparison operator');
      end if;
      if nvl(l_rate_comparison_operator_1, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_comparison_operator_1,
            'rate comparison operator');
      end if;
      if nvl(l_connector, 'AND') not in ('AND','OR') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_connector,
            'compound comparison connection operator');
      end if;
      if nvl(l_rate_connector, 'AND') not in ('AND','OR') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_connector,
            'compound rate comparison connection operator');
      end if;
      if nvl(l_comparison_operator_2, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_comparison_operator_2,
            'comparison operator');
      end if;
      if nvl(l_rate_comparison_operator_2, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_comparison_operator_2,
            'rate comparison operator');
      end if;
      if p_comparison_value_1 is null then
         cwms_err.raise('ERROR', 'Comparison value must be specified');
      end if;
      if p_connector             is null or
         p_comparison_operator_2 is null or
         p_comparison_value_2    is null
      then
         if p_connector             is not null or
            p_comparison_operator_2 is not null or
            p_comparison_value_2    is not null
         then
            cwms_err.raise(
               'ERROR',
               'Secondary comparison parameters must all be specified or all be null');
         end if;
      end if;
      if p_rate_connector             is null or
         p_rate_comparison_operator_2 is null or
         p_rate_comparison_value_2    is null
      then
         if p_rate_connector             is not null or
            p_rate_comparison_operator_2 is not null or
            p_rate_comparison_value_2    is not null
         then
            cwms_err.raise(
               'ERROR',
               'Secondary rate comparison parameters must all be specified or all be null');
         end if;
      end if;
      if p_comparison_unit is not null then
         declare
            l_code number(10);
         begin
            select unit_code
              into l_code
              from cwms_unit
             where unit_code = p_comparison_unit;
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_comparison_unit,
                  'CWMS unit code');
         end;
      end if;
      if p_rate_comparison_unit is not null then
         declare
            l_code number(10);
         begin
            select unit_code
              into l_code
              from cwms_unit
             where unit_code = p_rate_comparison_unit;
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_rate_comparison_unit,
                  'CWMS unit code');
         end;
      end if;
      --------------------
      -- set the values --
      --------------------
      indicator_value            := p_indicator_value;
      expression                 := l_expression;
      comparison_operator_1      := l_comparison_operator_1;
      comparison_value_1         := p_comparison_value_1;
      comparison_unit            := p_comparison_unit;
      connector                  := l_connector;
      comparison_operator_2      := l_comparison_operator_2;
      comparison_value_2         := p_comparison_value_2;
      rate_expression            := l_rate_expression;
      rate_comparison_operator_1 := l_rate_comparison_operator_1;
      rate_comparison_value_1    := p_rate_comparison_value_1;
      rate_comparison_unit       := p_rate_comparison_unit;
      rate_connector             := l_rate_connector;
      rate_comparison_operator_2 := l_rate_comparison_operator_2;
      rate_comparison_value_2    := p_rate_comparison_value_2;
      rate_interval              := p_rate_interval;
      description                := l_description;
      factor                     := 1.0;
      offset                     := 0.0;
      rate_factor                := 1.0;
      rate_offset                := 0.0;
      interval_factor            := 1.0;
      expression_tokens          := tokenize_expression(expression, false);
      rate_expression_tokens     := tokenize_expression(rate_expression, true);
      uses_reference :=
         case regexp_instr(expression, '(^|\(|[[:space:]])-?L2([[:space:]]|\)|$)') > 0
            when true  then 'T'
            when false then 'F'
         end;
   end init;


   member procedure store(
      p_level_indicator_code in number)
   is
   begin
      cwms_level.store_loc_lvl_indicator_cond(
         p_level_indicator_code,
         indicator_value,
         expression,
         comparison_operator_1,
         comparison_value_1,
         comparison_unit,
         connector,
         comparison_operator_2,
         comparison_value_2,
         rate_expression,
         rate_comparison_operator_1,
         rate_comparison_value_1,
         rate_comparison_unit,
         rate_connector,
         rate_comparison_operator_2,
         rate_comparison_value_2,
         rate_interval,
         description,
         'F',
         'F');

   end store;

   -----------------------------------------------------------------------------
   -- member fields factor and offset must previously be set to provide any
   -- necessary units conversion for the comparison
   --
   -- p_rate must be specified for the interval indicated in the member field
   -- rate_interval
   -----------------------------------------------------------------------------
   member function is_set(
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double,
      p_rate    in binary_double)
   return boolean
   is
      l_result       binary_double;
      l_comparison_1 boolean;
      l_comparison_2 boolean;
      l_is_set       boolean;
      l_arguments    double_tab_t;
   begin
      -------------------------------------------------
      -- evaluate the expression with the parameters --
      -------------------------------------------------
      l_arguments := new double_tab_t();
      l_arguments.extend(4);
      l_arguments(1) :=  p_value   * factor + offset;
      l_arguments(2) :=  p_level   * factor + offset;
      l_arguments(3) :=  p_level_2 * factor + offset;
      l_arguments(4) := (p_rate    * rate_factor + rate_offset) * interval_factor;
      /*
      cwms_msg.log_db_message('x', 7, 'expression = '||expression);
      declare
         l_str varchar2(1024) := 'tokens = (';
      begin
         for i in 1..expression_tokens.count loop
            if i > 1 then
               l_str := l_str || ' ';
            end if;
            l_str := l_str || expression_tokens(i);
         end loop;
         l_str := l_str || ')';
         cwms_msg.log_db_message('x', 7, l_str);
      end;
      cwms_msg.log_db_message('x', 7, 'args = ('||l_arguments(1)||', '||l_arguments(2)||', '||l_arguments(3)||', '||l_arguments(4)||')');
      */
      l_result := cwms_util.eval_tokenized_expression(expression_tokens, l_arguments);
      -- cwms_msg.log_db_message('x', 7, 'result = '||l_result);
      -----------------------------------
      -- evaluate the first comparison --
      -----------------------------------
      l_comparison_1 :=
         case comparison_operator_1
            when 'LT' then l_result  < comparison_value_1
            when 'LE' then l_result <= comparison_value_1
            when 'EQ' then l_result  = comparison_value_1
            when 'NE' then l_result != comparison_value_1
            when 'GE' then l_result >= comparison_value_1
            when 'GT' then l_result  > comparison_value_1
         end;
      -------------------------------------------------
      -- evaluate the second comparison if specified --
      -------------------------------------------------
      if connector is null then
         l_is_set := l_comparison_1;
      else
         l_comparison_2 :=
            case comparison_operator_2
               when 'LT' then l_result  < comparison_value_2
               when 'LE' then l_result <= comparison_value_2
               when 'EQ' then l_result  = comparison_value_2
               when 'NE' then l_result != comparison_value_2
               when 'GE' then l_result >= comparison_value_2
               when 'GT' then l_result  > comparison_value_2
            end;
         l_is_set :=
            case connector
               when 'AND' then l_comparison_1 and l_comparison_2
               when 'OR'  then l_comparison_1 or  l_comparison_2
            end;
      end if;
      ---------------------------------------------------
      -- evaluate the rate if a rate expression exists --
      ---------------------------------------------------
      if l_is_set and rate_expression_tokens is not null then
         /*
         cwms_msg.log_db_message('x', 7, 'rate expression = '||rate_expression);
         declare
            l_str varchar2(1024) := 'rate tokens = (';
         begin
            for i in 1..rate_expression_tokens.count loop
               if i > 1 then
                  l_str := l_str || ' ';
               end if;
               l_str := l_str || rate_expression_tokens(i);
            end loop;
            l_str := l_str || ')';
            cwms_msg.log_db_message('x', 7, l_str);
         end;
         */
         l_result := cwms_util.eval_tokenized_expression(rate_expression_tokens, l_arguments);
         -- cwms_msg.log_db_message('x', 7, 'result = '||l_result);
         ----------------------------------------
         -- evaluate the first rate comparison --
         ----------------------------------------
         l_comparison_1 :=
            case rate_comparison_operator_1
               when 'LT' then l_result  < rate_comparison_value_1
               when 'LE' then l_result <= rate_comparison_value_1
               when 'EQ' then l_result  = rate_comparison_value_1
               when 'NE' then l_result != rate_comparison_value_1
               when 'GE' then l_result >= rate_comparison_value_1
               when 'GT' then l_result  > rate_comparison_value_1
            end;
         ------------------------------------------------------
         -- evaluate the second rate comparison if specified --
         ------------------------------------------------------
         if rate_connector is null then
            l_is_set := l_comparison_1;
         else
            l_comparison_2 :=
               case rate_comparison_operator_2
                  when 'LT' then l_result  < rate_comparison_value_2
                  when 'LE' then l_result <= rate_comparison_value_2
                  when 'EQ' then l_result  = rate_comparison_value_2
                  when 'NE' then l_result != rate_comparison_value_2
                  when 'GE' then l_result >= rate_comparison_value_2
                  when 'GT' then l_result  > rate_comparison_value_2
               end;
            l_is_set :=
               case rate_connector
                  when 'AND' then l_comparison_1 and l_comparison_2
                  when 'OR'  then l_comparison_1 or  l_comparison_2
               end;
         end if;
      end if;
      return l_is_set;
   end is_set;

end;
/
show errors;

create or replace type loc_lvl_ind_cond_tab_t is table of loc_lvl_indicator_cond_t
/

create or replace type zloc_lvl_indicator_t is object
(
   level_indicator_code     number(10),
   location_code            number(10),
   specified_level_code     number(10),
   parameter_code           number(10),
   parameter_type_code      number(10),
   duration_code            number(10),
   attr_value               number,
   attr_parameter_code      number(10),
   attr_parameter_type_code number(10),
   attr_duration_code       number(10),
   ref_specified_level_code number(10),
   ref_attr_value           number,
   level_indicator_id       varchar2(32),
   minimum_duration         interval day to second,
   maximum_age              interval day to second,
   conditions               loc_lvl_ind_cond_tab_t,

   constructor function zloc_lvl_indicator_t
      return self as result,

   constructor function zloc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result,

   member procedure store
)
/
show errors;

create or replace type body zloc_lvl_indicator_t
as
   constructor function zloc_lvl_indicator_t
      return self as result
   is
   begin
      return;
   end zloc_lvl_indicator_t;

   constructor function zloc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result
   is
      l_level_indicator_code number(10);
   begin
      conditions := new loc_lvl_ind_cond_tab_t();
      select level_indicator_code,
             location_code,
             specified_level_code,
             parameter_code,
             parameter_type_code,
             duration_code,
             attr_value,
             attr_parameter_code,
             attr_parameter_type_code,
             attr_duration_code,
             ref_specified_level_code,
             ref_attr_value,
             level_indicator_id,
             minimum_duration,
             maximum_age
       into  level_indicator_code,
             location_code,
             specified_level_code,
             parameter_code,
             parameter_type_code,
             duration_code,
             attr_value,
             attr_parameter_code,
             attr_parameter_type_code,
             attr_duration_code,
             ref_specified_level_code,
             ref_attr_value,
             level_indicator_id,
             minimum_duration,
             maximum_age
        from at_loc_lvl_indicator
       where rowid = p_rowid;

      l_level_indicator_code := level_indicator_code;
      for rec in (select rowid
                    from at_loc_lvl_indicator_cond
                   where level_indicator_code = l_level_indicator_code
                order by level_indicator_value)
      loop
         conditions.extend;
         conditions(conditions.count) := loc_lvl_indicator_cond_t(rec.rowid);
         if conditions(conditions.count).comparison_unit is not null then
            ------------------------------------------------------------------------
            -- set factor and offset to convert from db units to comparison units --
            ------------------------------------------------------------------------
            select factor,
                   offset
              into conditions(conditions.count).factor,
                   conditions(conditions.count).offset
              from at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit_conversion uc
             where p.parameter_code = self.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and uc.from_unit_code = bp.unit_code
               and uc.to_unit_code = conditions(conditions.count).comparison_unit;
         end if;
         if conditions(conditions.count).rate_interval is not null then
            if conditions(conditions.count).rate_comparison_unit is not null then
               ----------------------------------------------------------------------------------
               -- set rate_factor and rate_offset to convert from db units to comparison units --
               ----------------------------------------------------------------------------------
               select factor,
                      offset
                 into conditions(conditions.count).rate_factor,
                      conditions(conditions.count).rate_offset
                 from at_parameter p,
                      cwms_base_parameter bp,
                      cwms_unit_conversion uc
                where p.parameter_code = self.parameter_code
                  and bp.base_parameter_code = p.base_parameter_code
                  and uc.from_unit_code = bp.unit_code
                  and uc.to_unit_code = conditions(conditions.count).rate_comparison_unit;
            end if;
            -----------------------------------------------------------------
            -- set interval_factor to convert from 1 hour to rate interval --
            -----------------------------------------------------------------
            conditions(conditions.count).interval_factor := 24 *
               (extract(day    from conditions(conditions.count).rate_interval)        +
                extract(hour   from conditions(conditions.count).rate_interval) / 24   +
                extract(minute from conditions(conditions.count).rate_interval) / 3600 +
                extract(second from conditions(conditions.count).rate_interval) / 86400);
         end if;
      end loop;
      return;
   end zloc_lvl_indicator_t;

   member procedure store
   is
   begin
      cwms_level.store_loc_lvl_indicator_out(
         level_indicator_code,
         location_code,
         parameter_code,
         parameter_type_code,
         duration_code,
         specified_level_code,
         level_indicator_id,
         attr_value,
         attr_parameter_code,
         attr_parameter_type_code,
         attr_duration_code,
         ref_specified_level_code,
         ref_attr_value,
         minimum_duration,
         maximum_age,
         'F',
         'F');
      for i in 1..conditions.count loop
         conditions(i).store(level_indicator_code);
      end loop;
   end store;
end;
/
show errors;

create or replace type zloc_lvl_indicator_tab_t is table of zloc_lvl_indicator_t
/

create or replace type loc_lvl_indicator_t is object
(
   office_id              varchar2(16),
   location_id            varchar2(49),
   parameter_id           varchar2(49),
   parameter_type_id      varchar2(16),
   duration_id            varchar2(16),
   specified_level_id     varchar2(256),
   level_indicator_id     varchar2(32),
   attr_value             number,
   attr_units_id          varchar2(16),
   attr_parameter_id      varchar2(49),
   attr_parameter_type_id varchar2(16),
   attr_duration_id       varchar2(16),
   ref_specified_level_id varchar2(256),
   ref_attr_value         number,
   minimum_duration       interval day to second,
   maximum_age            interval day to second,
   conditions             loc_lvl_ind_cond_tab_t,

   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result,

   constructor function loc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result,

   member procedure init(
      p_obj in zloc_lvl_indicator_t),

   member function zloc_lvl_indicator
      return zloc_lvl_indicator_t,

   member procedure store,

   member function get_indicator_values(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number_tab_t,

   member function get_max_indicator_value(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number,

   member function get_max_indicator_values(
      p_ts         in ztsv_array,
      p_start_time in date)
      return ztsv_array

)
/
show errors;

create or replace type body loc_lvl_indicator_t
as
   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result
   is
   begin
      init(p_obj);
      return;
   end loc_lvl_indicator_t;

   constructor function loc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result
   is
   begin
      init(zloc_lvl_indicator_t(p_rowid));
      return;
   end loc_lvl_indicator_t;

   member procedure init(
      p_obj in zloc_lvl_indicator_t)
   is
   begin
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into office_id,
             location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_obj.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;

      select bp.base_parameter_id
             || substr('-', 1, length(p.sub_parameter_id))
             || p.sub_parameter_id
        into parameter_id
        from at_parameter p,
             cwms_base_parameter bp
       where p.parameter_code = p_obj.parameter_code
         and bp.base_parameter_code = p.base_parameter_code;

      select parameter_type_id
        into parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = p_obj.parameter_type_code;

      select duration_id
        into duration_id
        from cwms_duration
       where duration_code = p_obj.duration_code;

      select specified_level_id
        into specified_level_id
        from at_specified_level
       where specified_level_code = p_obj.specified_level_code;

      if p_obj.attr_value is not null then
         select bp.base_parameter_id
                || substr('-', 1, length(p.sub_parameter_id))
                || p.sub_parameter_id,
                u.unit_id
           into attr_parameter_id,
                attr_units_id
           from at_parameter p,
                cwms_base_parameter bp,
                cwms_unit u
          where p.parameter_code = p_obj.attr_parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and u.unit_code = bp.unit_code;

         select parameter_type_id
           into attr_parameter_type_id
           from cwms_parameter_type
          where parameter_type_code = p_obj.attr_parameter_type_code;

         select duration_id
           into attr_duration_id
           from cwms_duration
          where duration_code = p_obj.attr_duration_code;
         attr_value := p_obj.attr_value;
      end if;

      if p_obj.ref_specified_level_code is not null then
         select specified_level_id
           into ref_specified_level_id
           from at_specified_level
          where specified_level_code = p_obj.ref_specified_level_code;
         ref_attr_value := p_obj.ref_attr_value;
      end if;

      level_indicator_id := p_obj.level_indicator_id;
      minimum_duration   := p_obj.minimum_duration;
      maximum_age        := p_obj.maximum_age;
      conditions         := p_obj.conditions;
   end init;

   member function zloc_lvl_indicator
      return zloc_lvl_indicator_t
   is
      l_parts       str_tab_t;
      l_obj         zloc_lvl_indicator_t := new zloc_lvl_indicator_t;
      l_sub_id      varchar2(48);
      l_id          varchar2(256);
      l_factor      binary_double;
      l_offset      binary_double;
   begin
      l_parts := cwms_util.split_text(location_id, '-', 1);
      l_sub_id := case l_parts.count
                     when 1 then null
                     else l_parts(2)
                  end;
      select pl.location_code
        into l_obj.location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where upper(o.office_id) = upper(self.office_id)
         and bl.db_office_code = o.office_code
         and upper(bl.base_location_id) = upper(l_parts(1))
         and pl.base_location_code = bl.base_location_code
         and upper(nvl(pl.sub_location_id, '@')) = upper(nvl(l_sub_id, '@'));

      l_parts := cwms_util.split_text(parameter_id, '-', 1);
      l_sub_id := case l_parts.count
                     when 1 then null
                     else l_parts(2)
                  end;
      select p.parameter_code
        into l_obj.parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(l_parts(1))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '@')) = upper(nvl(l_sub_id, '@'))
         and p.db_office_code = cwms_util.get_db_office_code(self.office_id);

      l_id := parameter_type_id;
      select parameter_type_code
        into l_obj.parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_id);

      l_id := duration_id;
      select duration_code
        into l_obj.duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_id);

      l_id := specified_level_id;
      select specified_level_code
        into l_obj.specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(l_id);

      if attr_value is not null then
         l_parts := cwms_util.split_text(attr_parameter_id, '-', 1);
         l_sub_id := case l_parts.count
                        when 1 then null
                        else l_parts(2)
                     end;
         select p.parameter_code
           into l_obj.attr_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(l_parts(1))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '@')) = upper(nvl(l_sub_id, '@'));
         select parameter_type_code
           into l_obj.attr_parameter_type_code
           from cwms_parameter_type
          where upper(parameter_type_id) = upper(attr_parameter_type_id);

         select duration_code
           into l_obj.attr_duration_code
           from cwms_duration
          where upper(duration_id) = upper(attr_duration_id);

         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = attr_units_id
            and to_unit_id = cwms_util.get_default_units(attr_parameter_id);
      end if;

      if ref_specified_level_id is not null then
         select sl.specified_level_code
           into l_obj.ref_specified_level_code
           from at_specified_level sl
          where upper(sl.specified_level_id) = upper(ref_specified_level_id)
            and sl.office_code in (
                select office_code
                  from cwms_office
                 where office_id in (office_id, 'CWMS'));
      end if;

      l_obj.level_indicator_id := level_indicator_id;
      l_obj.attr_value         := attr_value * l_factor + l_offset;
      l_obj.ref_attr_value     := ref_attr_value * l_factor + l_offset;
      l_obj.minimum_duration   := minimum_duration;
      l_obj.maximum_age        := maximum_age;
      l_obj.conditions         := conditions;

      return l_obj;
   end zloc_lvl_indicator;

   member procedure store
   is
      l_obj zloc_lvl_indicator_t := zloc_lvl_indicator;
   begin
      l_obj.store;
   end store;

   member function get_indicator_values(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number_tab_t
   is
      l_eval_time            date := nvl(p_eval_time, cast(systimestamp at time zone 'UTC' as date));
      l_max_age              number;
      l_min_dur              number;
      l_indicator_values     number_tab_t := number_tab_t();
      l_rate_of_change       boolean := false;
      l_is_set               boolean;
      l_set                  boolean;
      l_last                 pls_integer;
      l_level_values_1       ztsv_array;
      l_level_values_2       ztsv_array;
      l_level_values_array_1 double_tab_t := double_tab_t();
      l_level_values_array_2 double_tab_t := double_tab_t();
      l_rate_values_array    double_tab_t := double_tab_t();
      i                      binary_integer;
      j                      binary_integer;
      function is_valid(
         p_quality_code in number)
         return boolean
      is
         -- l_validity_id varchar2(16);
      begin
         /*
         select validity_id
           into l_validity_id
           from cwms_data_quality
          where quality_code = p_quality_code;
         return l_validity_id not in ('MISSING', 'REJECTED');
         */
         return bitand(p_quality_code, 20) = 0; -- 30 x faster!
      end is_valid;
   begin
      --------------------------------------
      -- create day values from durations --
      --------------------------------------
      l_max_age := extract(day    from maximum_age) +
                  (extract(hour   from maximum_age) / 24) +
                  (extract(minute from maximum_age) / 1440) +
                  (extract(second from maximum_age) / 86400);
      l_min_dur := extract(day    from minimum_duration) +
                  (extract(hour   from minimum_duration) / 24) +
                  (extract(minute from minimum_duration) / 1440) +
                  (extract(second from minimum_duration) / 86400);
      -------------------------------------
      -- determine whether we need rates --
      -------------------------------------
      for i in 1..conditions.count loop
         if not l_rate_of_change and conditions(i).rate_expression is not null then
            l_rate_of_change := true;
         end if;
         exit when l_rate_of_change;
      end loop;
      ----------------------------------------------------------------
      -- find the last valid value on or before the evaluation time --
      ----------------------------------------------------------------
      if p_ts is null or p_ts.count = 0 then
         return l_indicator_values;
      end if;
      for i in reverse 1..p_ts.count loop
         l_last := i;
         continue when p_ts(l_last).date_time > l_eval_time;
         exit when bitand(p_ts(l_last).quality_code, 20) = 0; --is_valid(p_ts(l_last).quality_code);
      end loop;
      -------------------------------------------------------
      -- only evaluate if last valid time is recent enough --
      -------------------------------------------------------
      if l_eval_time - p_ts(l_last).date_time <= l_max_age then
         l_rate_values_array.extend(l_last);
         if l_rate_of_change then
            -------------------------------------------------------
            -- compute the hourly rates of change if using rates --
            -------------------------------------------------------
            for i in reverse 2..l_last loop
               continue when bitand(p_ts(i).quality_code, 20) != 0; --not is_valid(p_ts(i).quality_code);
               for j in reverse 1..i-1 loop
                  get_indicator_values.j := j;
                  exit when bitand(p_ts(j).quality_code, 20) = 0; --is_valid(p_ts(j).quality_code);
               end loop;
               l_rate_values_array(i) :=
                  (p_ts(i).value - p_ts(j).value) /
                  ((p_ts(i).date_time - p_ts(j).date_time) * 24);
               -- cwms_msg.log_db_message('z', 7, ''||i||', '||j||': '||l_rate_values_array(i));
            end loop;
         end if;
         --------------------------------------------------
         -- retrieve the level values to compare against --
         --------------------------------------------------
         l_level_values_1 := cwms_level.retrieve_location_level_values(
            cwms_level.get_location_level_id(
               location_id,
               parameter_id,
               parameter_type_id,
               duration_id,
               specified_level_id),
            cwms_util.get_default_units(parameter_id),
            p_ts(1).date_time,
            p_ts(l_last).date_time,
            cwms_level.get_attribute_id(
               attr_parameter_id,
               attr_parameter_type_id,
               attr_duration_id),
            attr_value,
            attr_units_id,
            'UTC',
            office_id);
         if ref_specified_level_id is not null then
            l_level_values_2 := cwms_level.retrieve_location_level_values(
               cwms_level.get_location_level_id(
                  location_id,
                  parameter_id,
                  parameter_type_id,
                  duration_id,
                  ref_specified_level_id),
               cwms_util.get_default_units(parameter_id),
               p_ts(1).date_time,
               p_ts(l_last).date_time,
               cwms_level.get_attribute_id(
                  attr_parameter_id,
                  attr_parameter_type_id,
                  attr_duration_id),
               ref_attr_value,
               attr_units_id,
               'UTC',
               office_id);
         end if;
         ----------------------------------
         -- build tables of level values --
         ----------------------------------
         l_level_values_array_1.extend(l_last);
         l_level_values_array_2.extend(l_last);
         j := l_level_values_1.count;
         for i in reverse 1..l_last loop
            while l_level_values_1(j).date_time > p_ts(i).date_time loop
               exit when j = 1;
               j := j - 1;
            end loop;
            l_level_values_array_1(i) := l_level_values_1(j).value;
         end loop;
         if ref_specified_level_id is not null then
            j := l_level_values_2.count;
            for i in reverse 1..l_last loop
               while l_level_values_2(j).date_time > p_ts(i).date_time loop
                  exit when j = 1;
                  j := j - 1;
               end loop;
               l_level_values_array_2(i) := l_level_values_2(j).value;
            end loop;
         end if;
      end if;
      -----------------------------
      -- evaluate each condition --
      -----------------------------
      for i in 1..conditions.count loop
         l_set := false;
         for j in reverse 1..l_last loop
            continue when bitand(p_ts(j).quality_code, 20) != 0; --not is_valid(p_ts(j).quality_code);
            exit when not conditions(i).is_set(
               p_ts(j).value,
               l_level_values_array_1(j),
               l_level_values_array_2(j),
               l_rate_values_array(j));
            if (p_ts(l_last).date_time - p_ts(j).date_time) >= l_min_dur then
               l_set := true;
               exit;
            end if;
         end loop;
         if l_set then
            l_indicator_values.extend;
            l_indicator_values(l_indicator_values.count) := conditions(i).indicator_value;
         end if;
      end loop;
      return l_indicator_values;
   end get_indicator_values;

   member function get_max_indicator_value(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number
   is
      l_indicator_values number_tab_t;
   begin
      l_indicator_values := get_indicator_values(p_ts, p_eval_time);
      return case l_indicator_values.count > 0
                when true then  l_indicator_values(l_indicator_values.count)
                when false then 0
             end;
   end get_max_indicator_value;

   member function get_max_indicator_values(
      p_ts         in ztsv_array,
      p_start_time in date)
      return ztsv_array
   is
      l_results ztsv_array := new ztsv_array();
   begin
      for i in 1..p_ts.count loop
         continue when p_ts(i).date_time < p_start_time;
         l_results.extend;
         l_results(l_results.count) := new ztsv_type(
            p_ts(i).date_time,
            get_max_indicator_value(p_ts, p_ts(i).date_time),
            0);
      end loop;
      return l_results;
   end get_max_indicator_values;

end;
/
show errors;

create or replace type loc_lvl_indicator_tab_t is table of loc_lvl_indicator_t
/

create or replace type seasonal_value_t is object (
   offset_months  number(2),
   offset_minutes number(5),
   value          number,

   constructor function seasonal_value_t(
      p_calendar_offset in interval year to month,
      p_time_offset     in interval day to second,
      p_value           in number)
      return self as result,

   member procedure init(
      p_offset_months  in integer,
      p_offset_minutes in integer,
      p_value          in number)
)
/

create or replace type body seasonal_value_t
as
   constructor function seasonal_value_t(
      p_calendar_offset in interval year to month,
      p_time_offset     in interval day to second,
      p_value           in number)
      return self as result
   is
   begin
      init(cwms_util.yminterval_to_months(p_calendar_offset),
           cwms_util.dsinterval_to_minutes(p_time_offset),
           p_value);
      return;
   end seasonal_value_t;

   member procedure init(
      p_offset_months  in integer,
      p_offset_minutes in integer,
      p_value          in number)
   is
   begin
      offset_months  := p_offset_months;
      offset_minutes := p_offset_minutes;
      value          := p_value;
   end init;

end;
/
show errors;

create or replace type seasonal_value_tab_t is table of seasonal_value_t
/

create or replace type seasonal_location_level_t is object
(
   calendar_offset interval year(2) to month,
   time_offset     interval day(3) to second(0),
   level_value     number
)
/

create or replace type seasonal_loc_lvl_tab_t is table of seasonal_location_level_t
/

create or replace type zlocation_level_t is object(
   location_level_code           number(10),
   location_code                 number(10),
   specified_level_code          number(10),
   parameter_code                number(10),
   parameter_type_code           number(10),
   duration_code                 number(10),
   location_level_date           date,
   location_level_value          number,
   location_level_comment        varchar2(256),
   attribute_value               number,
   attribute_parameter_code      number(10),
   attribute_param_type_code     number(10),
   attribute_duration_code       number(10),
   attribute_comment             varchar2(256),
   interval_origin               date,
   calendar_interval             interval year(2) to month,
   time_interval                 interval day(3) to second(0),
   interpolate                   varchar2(1),
   seasonal_level_values         seasonal_loc_lvl_tab_t,
   indicators                    loc_lvl_indicator_tab_t,


   constructor function zlocation_level_t(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t)
      return self as result,

   constructor function zlocation_level_t(
      p_location_level_code           in number)
      return self as result,  
      
   constructor function zlocation_level_t
      return self as result,      

   member procedure init(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t),

   member procedure store
)
/

create or replace type body zlocation_level_t
as
   constructor function zlocation_level_t(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t)
      return self as result
   as
   begin
      init(
         p_location_level_code,
         p_location_code,
         p_specified_level_code,
         p_parameter_code,
         p_parameter_type_code,
         p_duration_code,
         p_location_level_date,
         p_location_level_value,
         p_location_level_comment,
         p_attribute_value,
         p_attribute_parameter_code,
         p_attribute_param_type_code,
         p_attribute_duration_code,
         p_attribute_comment,
         p_interval_origin,
         p_calendar_interval,
         p_time_interval,
         p_interpolate,
         p_seasonal_values,
         p_indicators);
      return;
   end zlocation_level_t;

   constructor function zlocation_level_t(
      p_location_level_code in number)
      return self as result
   as
      l_rec             at_location_level%rowtype;
      l_seasonal_values seasonal_loc_lvl_tab_t := new seasonal_loc_lvl_tab_t();
      l_indicators      loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
   begin
      -------------------------
      -- get the main record --
      -------------------------
      select *
        into l_rec
        from at_location_level
       where location_level_code = p_location_level_code;
      -----------------------------
      -- get the seasonal values --
      -----------------------------
      for rec in (
         select *
           from at_seasonal_location_level
          where location_level_code = p_location_level_code
       order by l_rec.interval_origin + calendar_offset + time_offset)
      loop
         l_seasonal_values.extend;
         l_seasonal_values(l_seasonal_values.count) := seasonal_location_level_t(
            rec.calendar_offset,
            rec.time_offset,
            rec.value);
      end loop;
      ---------------------------------------
      -- get the location level indicators --
      ---------------------------------------
      for rec in (
         select rowid
           from at_loc_lvl_indicator
          where location_code                     = l_rec.location_code
            and parameter_code                    = l_rec.parameter_code
            and parameter_type_code               = l_rec.parameter_type_code
            and duration_code                     = l_rec.duration_code
            and specified_level_code              = l_rec.specified_level_code
            and nvl(to_char(attr_value), '@')     = nvl(to_char(l_rec.attribute_value), '@')
            and nvl(attr_parameter_code, -1)      = nvl(l_rec.attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_rec.attribute_parameter_type_code, -1)
            and nvl(attr_duration_code, -1)       = nvl(l_rec.attribute_duration_code, -1))
      loop
         l_indicators.extend;
         l_indicators(l_indicators.count) := loc_lvl_indicator_t(rec.rowid);
      end loop;
      ---------------------------
      -- initialize the object --
      ---------------------------
      init(
         l_rec.location_level_code,
         l_rec.location_code,
         l_rec.specified_level_code,
         l_rec.parameter_code,
         l_rec.parameter_type_code,
         l_rec.duration_code,
         l_rec.location_level_date,
         l_rec.location_level_value,
         l_rec.location_level_comment,
         l_rec.attribute_value,
         l_rec.attribute_parameter_code,
         l_rec.attribute_parameter_type_code,
         l_rec.attribute_duration_code,
         l_rec.attribute_comment,
         l_rec.interval_origin,
         l_rec.calendar_interval,
         l_rec.time_interval,
         l_rec.interpolate,
         l_seasonal_values,
         l_indicators);
      return;
   end zlocation_level_t;
      
   constructor function zlocation_level_t
      return self as result
   is
   begin
      --------------------------
      -- all members are null --
      --------------------------
      return;
   end;            

   member procedure init(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t)
   as
      indicator zloc_lvl_indicator_t;
   begin
      ---------------------------
      -- verify the indicators --
      ---------------------------
      if p_indicators is not null then
         for i in 1..p_indicators.count loop
            indicator := p_indicators(i).zloc_lvl_indicator;
            if indicator.location_code                        != location_code
               or indicator.parameter_code                    != parameter_code
               or indicator.parameter_type_code               != parameter_type_code
               or indicator.duration_code                     != duration_code
               or nvl(to_char(indicator.attr_value), '@')     != nvl(to_char(attribute_value), '@')
               or nvl(indicator.attr_parameter_code, -1)      != nvl(attribute_parameter_code, -1)
               or nvl(indicator.attr_parameter_type_code, -1) != nvl(attribute_param_type_code, -1)
               or nvl(indicator.attr_duration_code, -1)       != nvl(attribute_duration_code, -1)
            then
               cwms_err.raise(
                  'ERROR',
                  'Location level indicator does not match location level.');
            end if;
         end loop;
      end if;
      ---------------------------
      -- set the member fields --
      ---------------------------
      location_level_code           := p_location_level_code;
      location_code                 := p_location_code;
      specified_level_code          := p_specified_level_code;
      parameter_code                := p_parameter_code;
      parameter_type_code           := p_parameter_type_code;
      duration_code                 := p_duration_code;
      location_level_date           := p_location_level_date;
      location_level_value          := p_location_level_value;
      location_level_comment        := p_location_level_comment;
      attribute_value               := p_attribute_value;
      attribute_parameter_code      := p_attribute_parameter_code;
      attribute_param_type_code     := p_attribute_param_type_code;
      attribute_duration_code       := p_attribute_duration_code;
      attribute_comment             := p_attribute_comment;
      interval_origin               := p_interval_origin;
      calendar_interval             := p_calendar_interval;
      time_interval                 := p_time_interval;
      interpolate                   := p_interpolate;
      seasonal_level_values         := p_seasonal_values;
      indicators                    := p_indicators;
   end init;

   member procedure store
   as
      l_rec    at_location_level%rowtype;
      l_exists boolean;
   begin
      ------------------------------
      -- find any existing record --
      ------------------------------
      begin
         select *
           into l_rec
           from at_location_level
          where location_level_code = location_level_code;
         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;
      ---------------------------
      -- set the record fields --
      ---------------------------
      l_rec.location_level_code           := location_level_code;
      l_rec.location_code                 := location_code;
      l_rec.specified_level_code          := specified_level_code;
      l_rec.parameter_code                := parameter_code;
      l_rec.parameter_type_code           := parameter_type_code;
      l_rec.duration_code                 := duration_code;
      l_rec.location_level_date           := location_level_date;
      l_rec.location_level_value          := location_level_value;
      l_rec.location_level_comment        := location_level_comment;
      l_rec.attribute_value               := attribute_value;
      l_rec.attribute_parameter_code      := attribute_parameter_code;
      l_rec.attribute_parameter_type_code := attribute_param_type_code;
      l_rec.attribute_duration_code       := attribute_duration_code;
      l_rec.attribute_comment             := attribute_comment;
      l_rec.interval_origin               := interval_origin;
      l_rec.calendar_interval             := calendar_interval;
      l_rec.time_interval                 := time_interval;
      l_rec.interpolate                   := interpolate;
      --------------------------------------
      -- insert or update the main record --
      --------------------------------------
      if l_exists then
         update at_location_level
            set row = l_rec
          where location_level_code = l_rec.location_level_code;
      else
         l_rec.location_level_code := cwms_seq.nextval;
         insert
           into at_location_level
         values l_rec;
      end if;
      -------------------------------
      -- store the seasonal values --
      -------------------------------
       if l_exists then
         delete
           from at_seasonal_location_level
          where location_level_code = l_rec.location_level_code;
       end if;
       if seasonal_level_values is not null then
          for i in 1..seasonal_level_values.count loop
            insert
              into at_seasonal_location_level
            values (l_rec.location_level_code,
                    seasonal_level_values(i).calendar_offset,
                    seasonal_level_values(i).time_offset,
                    seasonal_level_values(i).level_value);
          end loop;
       end if;
      --------------------------
      -- store the indicators --
      --------------------------
       if l_exists then
         delete
           from at_loc_lvl_indicator
          where location_code                     = l_rec.location_code
            and parameter_code                    = l_rec.parameter_code
            and parameter_type_code               = l_rec.parameter_type_code
            and duration_code                     = l_rec.duration_code
            and specified_level_code              = l_rec.specified_level_code
            and nvl(to_char(attr_value), '@')     = nvl(to_char(l_rec.attribute_value), '@')
            and nvl(attr_parameter_code, -1)      = nvl(l_rec.attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_rec.attribute_parameter_type_code, -1)
            and nvl(attr_duration_code, -1)       = nvl(l_rec.attribute_duration_code, -1);
       end if;
       if indicators is not null then
         for i in 1..indicators.count loop
            indicators(i).store;
         end loop;
       end if;
   end store;

end;
/
show errors;

create or replace type location_level_t is object (
   office_id                   varchar2(16),
   location_id                 varchar2(49),
   parameter_id                varchar2(49),
   parameter_type_id           varchar2(16),
   duration_id                 varchar2(16),
   specified_level_id          varchar2(256),
   level_date                  date,
   level_value                 number,
   level_units_id              varchar2(16),
   level_comment               varchar2(256),
   attribute_parameter_id      varchar2(49),
   attribute_parameter_type_id varchar2(16),
   attribute_duration_id       varchar2(16),
   attribute_value             number,
   attribute_units_id          varchar2(16),
   attribute_comment           varchar2(256),
   interval_origin             date,
   interval_months             integer,
   interval_minutes            integer,
   interpolate                 varchar2(1),
   seasonal_values             seasonal_value_tab_t,
   indicators                  loc_lvl_indicator_tab_t,

   constructor function location_level_t(
      p_office_id                   in varchar2,
      p_location_id                 in varchar2,
      p_parameter_id                in varchar2,
      p_parameter_type_id           in varchar2,
      p_duration_id                 in varchar2,
      p_specified_level_id          in varchar2,
      p_level_date                  in date,
      p_level_value                 in number,
      p_level_units_id              in varchar2,
      p_level_comment               in varchar2,
      p_attribute_parameter_id      in varchar2,
      p_attribute_parameter_type_id in varchar2,
      p_attribute_duration_id       in varchar2,
      p_attribute_value             in number,
      p_attribute_units_id          in varchar2,
      p_attribute_comment           in varchar2,
      p_interval_origin             in date,
      p_interval_months             in integer,
      p_interval_minutes            in integer,
      p_interpolate                 in varchar2,
      p_seasonal_values             in seasonal_value_tab_t,
      p_indicators                  in loc_lvl_indicator_tab_t)
      return self as result,

   constructor function location_level_t(
      p_obj zlocation_level_t)
      return self as result,

   constructor function location_level_t
      return self as result,        

   member procedure init(
      p_office_id                   in varchar2,
      p_location_id                 in varchar2,
      p_parameter_id                in varchar2,
      p_parameter_type_id           in varchar2,
      p_duration_id                 in varchar2,
      p_specified_level_id          in varchar2,
      p_level_date                  in date,
      p_level_value                 in number,
      p_level_units_id              in varchar2,
      p_level_comment               in varchar2,
      p_attribute_parameter_id      in varchar2,
      p_attribute_parameter_type_id in varchar2,
      p_attribute_duration_id       in varchar2,
      p_attribute_value             in number,
      p_attribute_units_id          in varchar2,
      p_attribute_comment           in varchar2,
      p_interval_origin             in date,
      p_interval_months             in integer,
      p_interval_minutes            in integer,
      p_interpolate                 in varchar2,
      p_seasonal_values             in seasonal_value_tab_t,
      p_indicators                  in loc_lvl_indicator_tab_t),

   member function zlocation_level
      return zlocation_level_t,

   member procedure store
)
/

create or replace type body location_level_t
as
   constructor function location_level_t(
      p_office_id                   in varchar2,
      p_location_id                 in varchar2,
      p_parameter_id                in varchar2,
      p_parameter_type_id           in varchar2,
      p_duration_id                 in varchar2,
      p_specified_level_id          in varchar2,
      p_level_date                  in date,
      p_level_value                 in number,
      p_level_units_id              in varchar2,
      p_level_comment               in varchar2,
      p_attribute_parameter_id      in varchar2,
      p_attribute_parameter_type_id in varchar2,
      p_attribute_duration_id       in varchar2,
      p_attribute_value             in number,
      p_attribute_units_id          in varchar2,
      p_attribute_comment           in varchar2,
      p_interval_origin             in date,
      p_interval_months             in integer,
      p_interval_minutes            in integer,
      p_interpolate                 in varchar2,
      p_seasonal_values             in seasonal_value_tab_t,
      p_indicators                  in loc_lvl_indicator_tab_t)
      return self as result
   is
   begin
      init(p_office_id,
           p_location_id,
           p_parameter_id,
           p_parameter_type_id,
           p_duration_id,
           p_specified_level_id,
           p_level_date,
           p_level_value,
           p_level_units_id,
           p_level_comment,
           p_attribute_parameter_id,
           p_attribute_parameter_type_id,
           p_attribute_duration_id,
           p_attribute_value,
           p_attribute_units_id,
           p_attribute_comment,
           p_interval_origin,
           p_interval_months,
           p_interval_minutes,
           p_interpolate,
           p_seasonal_values,
           p_indicators);
      return;
   end location_level_t;

   constructor function location_level_t(
      p_obj zlocation_level_t)
      return self as result
   is
   begin
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into office_id,
             location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_obj.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;

      select bp.base_parameter_id
             || substr('-', 1, length(p.sub_parameter_id))
             || p.sub_parameter_id
        into parameter_id
        from at_parameter p,
             cwms_base_parameter bp
       where p.parameter_code = p_obj.parameter_code
         and bp.base_parameter_code = p.base_parameter_code;

      select parameter_type_id
        into parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = p_obj.parameter_type_code;

      select duration_id
        into duration_id
        from cwms_duration
       where duration_code = p_obj.duration_code;

      select specified_level_id
        into specified_level_id
        from at_specified_level
       where specified_level_code = p_obj.specified_level_code;

      level_date := p_obj.location_level_date;
      level_value := p_obj.location_level_value;
      level_units_id := cwms_util.get_default_units(parameter_id);

      if p_obj.attribute_parameter_code is not null then
         select bp.base_parameter_id
                || substr('-', 1, length(p.sub_parameter_id))
                || p.sub_parameter_id
           into attribute_parameter_id
           from at_parameter p,
                cwms_base_parameter bp
          where p.parameter_code = p_obj.attribute_parameter_code
            and bp.base_parameter_code = p.base_parameter_code;

         select parameter_type_id
           into attribute_parameter_type_id
           from cwms_parameter_type
          where parameter_type_code = p_obj.attribute_param_type_code;

         select duration_id
           into attribute_duration_id
           from cwms_duration
          where duration_code = p_obj.attribute_duration_code;
         attribute_value := p_obj.attribute_value;
         level_units_id := cwms_util.get_default_units(attribute_parameter_id);

         attribute_comment := p_obj.attribute_comment;
      end if;

      interval_origin  := p_obj.interval_origin;
      interval_months  := cwms_util.yminterval_to_months(p_obj.calendar_interval);
      interval_minutes := cwms_util.dsinterval_to_minutes(p_obj.time_interval);
      if p_obj.seasonal_level_values is not null then
         seasonal_values := new seasonal_value_tab_t();
         for i in 1..p_obj.seasonal_level_values.count loop
            seasonal_values.extend;
            seasonal_values(i) := seasonal_value_t(
               p_obj.seasonal_level_values(i).calendar_offset,
               p_obj.seasonal_level_values(i).time_offset,
               p_obj.seasonal_level_values(i).level_value);
         end loop;
      end if;
      interpolate := p_obj.interpolate;
      indicators  := p_obj.indicators;
      return;
   end location_level_t;
   
 constructor function location_level_t
      return self as result
   is
   begin
      --------------------------
      -- all members are null --
      --------------------------
      return;
   end;               

   member procedure init(
      p_office_id                   in varchar2,
      p_location_id                 in varchar2,
      p_parameter_id                in varchar2,
      p_parameter_type_id           in varchar2,
      p_duration_id                 in varchar2,
      p_specified_level_id          in varchar2,
      p_level_date                  in date,
      p_level_value                 in number,
      p_level_units_id              in varchar2,
      p_level_comment               in varchar2,
      p_attribute_parameter_id      in varchar2,
      p_attribute_parameter_type_id in varchar2,
      p_attribute_duration_id       in varchar2,
      p_attribute_value             in number,
      p_attribute_units_id          in varchar2,
      p_attribute_comment           in varchar2,
      p_interval_origin             in date,
      p_interval_months             in integer,
      p_interval_minutes            in integer,
      p_interpolate                 in varchar2,
      p_seasonal_values             in seasonal_value_tab_t,
      p_indicators                  in loc_lvl_indicator_tab_t)
   is
      l_obj zlocation_level_t;
   begin
      -----------------------
      -- set member fields --
      -----------------------
      office_id                   := p_office_id;
      location_id                 := p_location_id;
      parameter_id                := p_parameter_id;
      parameter_type_id           := p_parameter_type_id;
      duration_id                 := p_duration_id;
      specified_level_id          := p_specified_level_id;
      level_date                  := p_level_date;
      level_value                 := p_level_value;
      level_units_id              := p_level_units_id;
      level_comment               := p_level_comment;
      attribute_parameter_id      := p_attribute_parameter_id;
      attribute_parameter_type_id := p_attribute_parameter_type_id;
      attribute_duration_id       := p_attribute_duration_id;
      attribute_value             := p_attribute_value;
      attribute_units_id          := p_attribute_units_id;
      attribute_comment           := p_attribute_comment;
      interval_origin             := p_interval_origin;
      interval_months             := p_interval_months;
      interval_minutes            := p_interval_minutes;
      interpolate                 := p_interpolate;
      seasonal_values             := p_seasonal_values;
      indicators                  := p_indicators;
      -------------------------
      -- forces verification --
      -------------------------
      l_obj := zlocation_level;
   end init;

   member function zlocation_level
      return zlocation_level_t
   is
      l_office_code                   number(10);
      l_cwms_office_code              number(10) := cwms_util.get_office_code('CWMS');
      l_location_level_code           number(10);
      l_location_code                 number(10);
      l_specified_level_code          number(10);
      l_parameter_code                number(10);
      l_parameter_type_code           number(10);
      l_duration_code                 number(10);
      l_location_level_value          number;
      l_attribute_value               number;
      l_attribute_parameter_code      number(10);
      l_attribute_param_type_code     number(10);
      l_attribute_duration_code       number(10);
      l_calendar_interval             interval year(2) to month;
      l_time_interval                 interval day(3) to second(0);
      l_seasonal_level_values         seasonal_loc_lvl_tab_t;
      l_obj                           zlocation_level_t;
      l_parameter_type_id             parameter_type_id%type := parameter_type_id;
      l_duration_id                   duration_id%type := duration_id;
      l_specified_level_id            specified_level_id%type := specified_level_id;

   begin
      select o.office_code,
             pl.location_code
        into l_office_code,
             l_location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where upper(o.office_id) = upper(office_id)
         and bl.db_office_code = o.office_code
         and bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = upper(cwms_util.get_base_id(location_id))
         and upper(nvl(pl.sub_location_id, '.')) = upper(nvl(cwms_util.get_sub_id(location_id), '.'));

      select p.parameter_code
        into l_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(parameter_id))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '.')) = upper(nvl(cwms_util.get_sub_id(parameter_id), '.'))
         and p.db_office_code in (l_office_code, l_cwms_office_code);

      select pt.parameter_type_code
        into l_parameter_type_code
        from cwms_parameter_type pt
       where upper(pt.parameter_type_id) = upper(l_parameter_type_id);

      select d.duration_code
        into l_duration_code
        from cwms_duration d
       where upper(d.duration_id) = upper(l_duration_id);

      select sl.specified_level_code
        into l_specified_level_code
        from at_specified_level sl
       where upper(sl.specified_level_id) = upper(l_specified_level_id);

      select level_value * factor + offset
        into l_location_level_value
        from cwms_unit_conversion cuc
       where from_unit_id = level_units_id
         and to_unit_id = cwms_util.get_default_units(parameter_id);

      if attribute_parameter_id is not null then
         select p.parameter_code
           into l_attribute_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(attribute_parameter_id))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '.')) = upper(nvl(cwms_util.get_sub_id(attribute_parameter_id), '.'))
            and p.db_office_code in (l_office_code, l_cwms_office_code);

         select pt.parameter_type_code
           into l_attribute_param_type_code
           from cwms_parameter_type pt
          where upper(pt.parameter_type_id) = upper(attribute_parameter_type_id);

         select d.duration_code
           into l_attribute_duration_code
           from cwms_duration d
          where upper(d.duration_id) = upper(attribute_duration_id);

         select attribute_value * factor + offset
           into l_attribute_value
           from cwms_unit_conversion cuc
          where from_unit_id = attribute_units_id
            and to_unit_id = cwms_util.get_default_units(attribute_parameter_id);
      end if;

      l_calendar_interval := cwms_util.months_to_yminterval(interval_months);
      l_time_interval     := cwms_util.minutes_to_dsinterval(interval_minutes);

      if seasonal_values is not null then
         l_seasonal_level_values := new seasonal_loc_lvl_tab_t();
         for i in 1..seasonal_values.count loop
            l_seasonal_level_values.extend;
            l_seasonal_level_values(i) := seasonal_location_level_t(
               cwms_util.months_to_yminterval(seasonal_values(i).offset_months),
               cwms_util.minutes_to_dsinterval(seasonal_values(i).offset_minutes),
               seasonal_values(i).value);
         end loop;
      end if;

      begin
         select location_level_code
           into l_location_level_code
           from at_location_level
          where location_code = l_location_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and duration_code = l_duration_code
            and specified_level_code = l_specified_level_code
            and location_level_date = location_level_date
            and location_level_value = l_location_level_value
            and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
            and nvl(attribute_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
            and nvl(attribute_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
            and nvl(attribute_duration_code, -1) = nvl(l_attribute_duration_code, -1);
      exception
         when no_data_found then null;
      end;
      if l_location_level_code is null then
         l_obj := zlocation_level_t();
         l_obj.init(
            cwms_seq.nextval,
            l_location_code,
            l_specified_level_code,
            l_parameter_code,
            l_parameter_type_code,
            l_duration_code,
            level_date,
            l_location_level_value,
            level_comment,
            l_attribute_value,
            l_attribute_parameter_code,
            l_attribute_param_type_code,
            l_attribute_duration_code,
            attribute_comment,
            interval_origin,
            l_calendar_interval,
            l_time_interval,
            interpolate,
            l_seasonal_level_values,
            indicators);
      else
         l_obj := zlocation_level_t(l_location_level_code);
      end if;
      return l_obj;
   end zlocation_level;

   member procedure store
   is
      l_obj zlocation_level_t;
   begin
      l_obj:= zlocation_level;
      l_obj.store;
   end store;
end;
/
show errors;

create or replace type location_level_tab_t is table of location_level_t
/

create or replace type jms_map_msg_tab_t as table of sys.aq$_jms_map_message;
/


create or replace type property_info_t as object (
   office_id     varchar2 (16),
   prop_category varchar2 (256),
   prop_id       varchar2 (256));
/

create or replace type property_info_tab_t as table of property_info_t;
/

create or replace type property_info2_t as object (
   office_id     varchar2 (16),
   prop_category varchar2 (256),
   prop_id       varchar2 (256),
   prop_value    varchar2 (256),
   prop_comment  varchar2 (256));
/

create or replace type property_info2_tab_t as table of property_info2_t;
/

-- HOST pwd
@@rowcps_types
@@cwms_types_rating
COMMIT ;
