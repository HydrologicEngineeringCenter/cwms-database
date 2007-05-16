/* Formatted on 2007/05/16 13:49 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_util
AS
/******************************************************************************
*   Name:       CWMS_UTL
*   Purpose:    Miscellaneous CWMS Procedures
*
*   Revisions:
*   Ver        Date        Author      Descriptio
*   ---------  ----------  ----------  ----------------------------------------
*   1.1        9/07/2005   Portin      create_view: at_ts_table_properties start and end dates
*                                      changed to DATE datatype
*   1.0        8/29/2005   Portin      Original
******************************************************************************/

   -- Constants for Storage Business Rules
   replace_all                   CONSTANT VARCHAR2 (16)      := 'REPLACE ALL';
   do_not_replace                CONSTANT VARCHAR2 (16)   := 'DO NOT REPLACE';
   replace_missing_values_only   CONSTANT VARCHAR2 (32)
                                             := 'REPLACE MISSING VALUES ONLY';
   replace_with_non_missing      CONSTANT VARCHAR2 (32)
                                                := 'REPLACE WITH NON MISSING';
   delete_insert                 CONSTANT VARCHAR2 (16)    := 'DELETE INSERT';
   --
   ---
   ---- DEPRICATED
   delete_key                    CONSTANT VARCHAR2 (16)       := 'DELETE KEY';
   delete_data                   CONSTANT VARCHAR2 (22)      := 'DELETE DATA';
   delete_all                    CONSTANT VARCHAR2 (16)       := 'DELETE ALL';
   ----DEPRICATED.
   ---
   --
   delete_ts_id                  CONSTANT VARCHAR2 (22)     := 'DELETE TS ID';
   delete_loc                    CONSTANT VARCHAR2 (22)       := 'DELETE LOC';
   delete_ts_data                CONSTANT VARCHAR2 (22)   := 'DELETE TS DATA';
   delete_ts_cascade             CONSTANT VARCHAR2 (22)
                                                       := 'DELETE TS CASCADE';
   delete_loc_cascade            CONSTANT VARCHAR2 (22)
                                                      := 'DELETE LOC CASCADE';
   --
   -- non_versioned is the default version_date for non-versioned timeseries
   non_versioned                 CONSTANT DATE           := DATE '1111-11-11';
   utc_offset_irregular          CONSTANT NUMBER               := -2147483648;
   utc_offset_undefined          CONSTANT NUMBER                := 2147483647;
   true_num                      CONSTANT NUMBER                 := 1;
   false_num                     CONSTANT NUMBER                 := 0;
   max_base_id_length            CONSTANT NUMBER                 := 16;
   max_sub_id_length             CONSTANT NUMBER                 := 32;
   max_full_id_length            CONSTANT NUMBER
                                := max_base_id_length + max_sub_id_length + 1;
   --
   db_office_code_all            CONSTANT NUMBER                 := 53;
   --
   irregular_interval_code       CONSTANT NUMBER                 := 29;
   --
   field_separator               CONSTANT VARCHAR2 (1)           := CHR (29);
   record_separator              CONSTANT VARCHAR2 (1)           := CHR (30);
   escape_char                   CONSTANT VARCHAR2 (1)           := '\';
   mv_pause_timeout_interval     CONSTANT INTERVAL DAY TO SECOND
                                                                := '0 0:30:0';
   mv_pause_job_run_interval     CONSTANT NUMBER                 := 60;
                                                                   -- minutes
   -- CWMS_PRIVILEGES...
   read_privilege                CONSTANT NUMBER                 := 4;
   write_privilege               CONSTANT NUMBER                 := 2;
   --
   -- CWMS SPECIAL USER GROUPS...
   dba_users                     CONSTANT NUMBER                 := 1;
   dbi_users                     CONSTANT NUMBER                 := 2;
   data_exchange_mgr             CONSTANT NUMBER                 := 4;
   data_acquisition_mgr          CONSTANT NUMBER                 := 8;
   ts_creator                    CONSTANT NUMBER                 := 16;
   vt_mgr                        CONSTANT NUMBER                 := 32;
   all_users                     CONSTANT NUMBER                 := 64;
   epoch                         CONSTANT TIMESTAMP
      := STANDARD.TO_TIMESTAMP ('1970/01/01/ 00:00:00',
                                'yyyy/mm/dd hh24:mi:ss'
                               );

   TYPE str_tab_t IS TABLE OF VARCHAR2 (32767);

   -- table row with string fields
   TYPE str_tab_tab_t IS TABLE OF str_tab_t;

   -- table of rows with string fields
   TYPE cat_unit_rec_t IS RECORD (
      unit_id   VARCHAR2 (16)
   );

   TYPE cat_unit_tab_t IS TABLE OF cat_unit_rec_t;

   --------------------------------------------------------------------------------
-- Splits string into a table of strings using the specified delimiter.
-- If no delmiter is specified, the string is split around whitespace.
--
-- Sequential delimiters in the source string result in null fields in the table,
-- except that if no delimiter is supplied, sequential whitespace characters are
-- treated as a single delimiter.
--
   FUNCTION split_text (
      p_text        IN   VARCHAR2,
      p_separator   IN   VARCHAR2 DEFAULT NULL,
      p_max_split   IN   INTEGER DEFAULT NULL
   )
      RETURN str_tab_t;

--------------------------------------------------------------------------------
-- Joins a table of strings into a single string using the specified delimiter.
-- If no delimiter is supplied, the table fields are simply concatenated together.
--
-- Null fields in the table result in sequential delimiters in the returned string.
--
   FUNCTION join_text (
      p_text_tab    IN   str_tab_t,
      p_separator   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Parses a CLOB into a table of tables of strings.
--
-- Records are delimited by the record_separator character defined above.
-- Fields are delmited by the field_separator character defined above.
--
   FUNCTION parse_clob_recordset (p_clob IN CLOB)
      RETURN str_tab_tab_t;

--------------------------------------------------------------------------------
-- Parses a string into a table of tables of strings.
--
-- Records are delimited by the record_separator character defined above.
-- Fields are delmited by the field_separator character defined above.
--
   FUNCTION parse_string_recordset (p_string IN VARCHAR2)
      RETURN str_tab_tab_t;

   TYPE ts_list IS TABLE OF VARCHAR2 (200)
      INDEX BY BINARY_INTEGER;

   --
   FUNCTION min_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER;

   --
   FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER;

   --
   FUNCTION min_dm (p_decimal_degrees IN NUMBER)
      RETURN NUMBER;

   --
   -- return the p_in_date which is in p_in_tz as a date in UTC
   FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
      RETURN DATE;

   --
   -- Retruns TRUE if p_true_false is T or True.
   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN;

      --
   -- Retruns TRUE if p_true_false is F or False.
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN;

   --
   -- Retruns TRUE if p_true_false is T or True
   -- Returns FALSE if p_true_false is F or False.
   FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_ts_code (p_cwms_ts_id IN VARCHAR2, p_db_office_code IN NUMBER)
      RETURN NUMBER;

   FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION concat_ts_id (
      p_base_location_id    IN   VARCHAR2,
      p_sub_location_id     IN   VARCHAR2,
      p_base_parameter_id   IN   VARCHAR2,
      p_sub_parameter_id    IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_interval_id         IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_version_id          IN   VARCHAR2
   )
      RETURN VARCHAR2;

--------------------------------------------------------
-- Return the current session user's primary office id
--
   FUNCTION user_office_id
      RETURN VARCHAR2;

--------------------------------------------------------
-- return the current session user's primary office code
--
   FUNCTION user_office_code
      RETURN NUMBER;

--------------------------------------------------------
-- Return the office code for the specified office id,
-- or the user's primary office if the office id is null
--
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   FUNCTION get_db_office_id (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   FUNCTION get_parameter_id (p_parameter_code IN NUMBER)
      RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- function get_time_zone_code
--
   FUNCTION get_time_zone_code (p_time_zone_name IN VARCHAR2)
      RETURN NUMBER;

--------------------------------------------------------------------------------
-- function get_tz_usage_code
--
   FUNCTION get_tz_usage_code (p_tz_usage_id IN VARCHAR2)
      RETURN NUMBER;

--------------------------------------------------------------------------------
-- function get_real_name
--
   FUNCTION get_real_name (p_synonym IN VARCHAR2)
      RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- function pause_mv_refresh
--
   FUNCTION pause_mv_refresh (
      p_mview_name   IN   VARCHAR2,
      p_reason       IN   VARCHAR2 DEFAULT NULL
   )
      RETURN UROWID;

--------------------------------------------------------------------------------
-- procedure resume_mv_refresh
--
   PROCEDURE resume_mv_refresh (p_paused_handle IN UROWID);

--------------------------------------------------------------------------------
-- procedure timeout_mv_refresh_paused
--
   PROCEDURE timeout_mv_refresh_paused;

--------------------------------------------------------------------------------
-- procedure start_timeout_mv_refresh_job
--
   PROCEDURE start_timeout_mv_refresh_job;

--------------------------------------------------------
-- Return the db host office code for the specified office id,
-- or the user's primary office if the office id is null
--
   FUNCTION get_db_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

--------------------------------------------------------
-- Replace filename wildcard chars (?,*) with SQL ones
-- (_,%), using '\' as an escape character.
--
--  A null input generates a result of '%'.
--
-- +--------------+-------------------------------------------------------------------------+
-- |              |                             Output String                               |
-- |              +------------------------------------------------------------+------------+
-- |              |                            Recognize SQL                   |            |
-- |              |                             Wildcards?                     |            |
-- |              +------+---------------------------+-----+-------------------+            |
-- | Input String | No   : comments                  | Yes : comments          | Different? |
-- +--------------+------+---------------------------+-----+-------------------+------------+
-- | %            | \%   : literal '%'               | %   : multi-wildcard    | Yes        |
-- | _            | \_   : literal '_'               | _   : single-wildcard   | Yes        |
-- | *            | %    : multi-wildcard            | %   : multi-wildcard    | No         |
-- | ?            | _    : single-wildcard           | _   : single-wildcard   | No         |
-- | \%           |      : not allowed               | \%  : literal '%'       | Yes        |
-- | \_           |      : not allowed               | \_  : literal '_'       | Yes        |
-- | \*           | *    : literal '*'               | *   : literal '*'       | No         |
-- | \?           | ?    : literal '?'               | ?   : literal '?'       | No         |
-- | \\%          | \\\% : literal '\' + literal '%' | \\% : literal '\' + mwc | Yes        |
-- | \\_          | \\\_ : literal '\' + literal '\' | \\_ : literal '\' + swc | Yes        |
-- | \\*          | \\%  : literal '\' + mwc         | \\% : literal '\' + mwc | No         |
-- | \\?          | \\_  : literal '\' + swc         | \\_ : literal '\' + swc | No         |
-- +--------------+------+---------------------------+-----+-------------------+------------+
   FUNCTION normalize_wildcards (
      p_string          IN   VARCHAR2,
      p_recognize_sql        BOOLEAN DEFAULT FALSE
   )
      RETURN VARCHAR2;

   PROCEDURE parse_ts_id (
      p_base_location_id    OUT      VARCHAR2,
      p_sub_location_id     OUT      VARCHAR2,
      p_base_parameter_id   OUT      VARCHAR2,
      p_sub_parameter_id    OUT      VARCHAR2,
      p_parameter_type_id   OUT      VARCHAR2,
      p_interval_id         OUT      VARCHAR2,
      p_duration_id         OUT      VARCHAR2,
      p_version_id          OUT      VARCHAR2,
      p_cwms_ts_id          IN       VARCHAR2
   );

--------------------------------------------------------------------
-- Returns an AND/OR predicate string for a multi-element search set.
--
   FUNCTION parse_search_string (
      p_search_patterns   IN   VARCHAR2,
      p_search_column     IN   VARCHAR2,
      p_use_upper         IN   BOOLEAN DEFAULT TRUE
   )
      RETURN VARCHAR2;

--------------------------------------------------------------------
-- Return a string with all leading and trailing whitespace removed.
--
   FUNCTION strip (p_text IN VARCHAR2)
      RETURN VARCHAR2;

--------------------------------------------------------------------
-- Return UTC timestamp for specified Java milliseconds
--
   FUNCTION TO_TIMESTAMP (p_millis IN NUMBER)
      RETURN TIMESTAMP;

--------------------------------------------------------------------
-- Return Java milliseconds for a specified UTC timestamp.
--
   FUNCTION to_millis (p_timestamp IN TIMESTAMP)
      RETURN NUMBER;

--------------------------------------------------------------------
-- Return Java milliseconds for current time.
--
   FUNCTION current_millis
      RETURN NUMBER;

--------------------------------------------------------------------
   PROCEDURE TEST;

   -- Dump (put_line) a character string p_str in chunks of length p_len
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80);

   -- Create the partitioned timeseries table view
   PROCEDURE create_view;

   PROCEDURE get_valid_units (
      p_valid_units    OUT      sys_refcursor,
      p_parameter_id   IN       VARCHAR2 DEFAULT NULL
   );

   FUNCTION get_valid_units_tab (p_parameter_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_unit_tab_t PIPELINED;

   FUNCTION get_unit_code (
      p_unit_id             IN   VARCHAR2,
      p_abstract_param_id   IN   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION get_loc_group_code (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_db_office_code    IN   NUMBER
   )
      RETURN NUMBER;

   FUNCTION get_loc_group_code (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_db_office_id      IN   VARCHAR2
   )
      RETURN NUMBER;
END cwms_util;
/

SHOW errors;