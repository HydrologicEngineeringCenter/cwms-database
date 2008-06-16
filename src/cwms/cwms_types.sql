/* Formatted on 2007/10/29 14:13 (Formatter Plus v4.8.8) */
-- Defines the CWMS date-time, value, and quality types. 
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
   defined_count      PLS_INTEGER;
   total_count        PLS_INTEGER := 0;
   pass_count         PLS_INTEGER := 0;
   type_names         id_array_t
      := id_array_t ('tr_template_set_type',
                     'tr_template_set_array',
                     'tsv_type',
                     'tsv_array',
                     'at_tsv_type',
                     'at_tsv_array',
                     'char_16_array_type',
                     'char_32_array_type',
                     'char_49_array_type',
                     'char_183_array_type',
                     'date_table_type',
                     'timeseries_type',
                     'timeseries_array',
                     'timeseries_req_type',
                     'timeseries_req_array',
                     'ts_request_type',
                     'ts_request_array',
                     'source_type',
                     'source_array',
                     'loc_type_ds',
                     'loc_type',
                     'loc_alias_type',
                     'loc_alias_array',
                     'alias_type',
                     'alias_array',
                     'cwms_ts_id_array',
                     'cwms_ts_id_t',
                     'screen_assign_array',
                     'screen_assign_t',
                     'screen_dur_mag_array',
                     'screen_dur_mag_type',
                     'screen_crit_array',
                     'screen_crit_type',
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
                     'cat_dss_xchg_ts_map_otab_t',
                     'group_type',
                     'group_array',
                     'group_cat_t',
                     'group_cat_tab_t'
                    );
BEGIN
   defined_count := type_names.COUNT;

   LOOP
      pass_count := pass_count + 1;
      DBMS_OUTPUT.put_line ('Pass ' || pass_count);
      dropped_count := 0;
      DBMS_OUTPUT.put_line ('');

      FOR i IN type_names.FIRST .. type_names.LAST
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
                  defined_count := defined_count - 1;
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
CREATE OR REPLACE TYPE tr_template_set_type AS OBJECT (
   store_dep_flag          VARCHAR2 (1),
   unit_system             VARCHAR2 (2),
   trans_id                VARCHAR2 (32),
   lookup_agency_source    VARCHAR2 (32),
   lookup_source_version   VARCHAR2 (32),
   scaling_arg_a           NUMBER,
   scaling_arg_b           NUMBER,
   scaling_arg_c           NUMBER,
   array_of_masks          char_183_array_type
);
/

CREATE OR REPLACE TYPE tr_template_set_array IS TABLE OF tr_template_set_type;
/

CREATE TYPE tsv_type AS OBJECT (
   date_time      TIMESTAMP WITH TIME ZONE,
   VALUE          BINARY_DOUBLE,
   quality_code   NUMBER
);
/

CREATE TYPE tsv_array IS TABLE OF tsv_type;
/

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
   tsid  varchar2(183),
   unit  varchar2(16),
   data tsv_array
);
/

CREATE TYPE timeseries_array IS TABLE OF timeseries_type;
/

-- used for retrieve_ts2_multi

CREATE TYPE timeseries_req_type AS OBJECT (
   tsid       varchar2(183),
   unit       varchar2(16),
   start_time date,
   end_time   date
);
/

CREATE TYPE timeseries_req_array IS TABLE OF timeseries_req_type;
/

CREATE TYPE nested_ts_type as object (
   sequence    integer,
   tsid        varchar2(183),
   units       varchar2(16),
   start_time  date,
   end_time    date,
   data        tsv_array
);
/

CREATE TYPE nested_ts_table IS TABLE OF  nested_ts_type;
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
   cwms_ts_id              VARCHAR2 (183),
   dss_pathname            VARCHAR2 (391),
   dss_parameter_type_id   VARCHAR2 (8),
   dss_unit_id             VARCHAR2 (16),
   dss_timezone_name       VARCHAR2 (28),
   dss_tz_usage_id         VARCHAR2 (8)
);
/

CREATE TYPE cat_dss_xchg_ts_map_otab_t AS TABLE OF cat_dss_xchg_ts_map_obj_t;
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

CREATE OR REPLACE TYPE group_type AS OBJECT (
   GROUP_ID     VARCHAR2 (32),
   group_desc   VARCHAR2 (128)
)
/

CREATE OR REPLACE TYPE group_array IS TABLE OF group_type;
/

CREATE OR REPLACE TYPE group_cat_t AS OBJECT (
   loc_category_id   VARCHAR2 (32),
   loc_group_id      VARCHAR2 (32)
)
/

CREATE OR REPLACE TYPE group_cat_tab_t IS TABLE OF group_cat_t
/

COMMIT ;