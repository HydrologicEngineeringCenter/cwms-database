/* Formatted on 2006/12/11 09:10 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_util AUTHID CURRENT_USER
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
   replace_all                   CONSTANT VARCHAR2 (16) := 'REPLACE ALL';
   do_not_replace                CONSTANT VARCHAR2 (16) := 'DO NOT REPLACE';
   replace_missing_values_only   CONSTANT VARCHAR2 (32)
                                             := 'REPLACE MISSING VALUES ONLY';
   replace_with_non_missing      CONSTANT VARCHAR2 (32)
                                                := 'REPLACE WITH NON MISSING';
   delete_insert                 CONSTANT VARCHAR2 (16) := 'DELETE INSERT';
   --
   delete_key                    CONSTANT VARCHAR2 (16) := 'DELETE KEY';
   delete_data                   CONSTANT VARCHAR2 (16) := 'DELETE DATA';
   delete_all                    CONSTANT VARCHAR2 (16) := 'DELETE ALL';
   --
   -- non_versioned is the default version_date for non-versioned timeseries
   non_versioned                 CONSTANT DATE          := DATE '1111-11-11';
   utc_offset_irregular          CONSTANT NUMBER        := -2147483648;
   utc_offset_undefined          CONSTANT NUMBER        := 2147483647;
   true_num                      CONSTANT NUMBER        := 1;
   false_num                     CONSTANT NUMBER        := 0;
   max_base_id_length            CONSTANT NUMBER        := 16;
   max_sub_id_length             CONSTANT NUMBER        := 32;
   max_full_id_length            CONSTANT NUMBER
                                := max_base_id_length + max_sub_id_length + 1;
   --
   db_office_code_all            CONSTANT NUMBER        := 53;
   --
   irregular_interval_code       CONSTANT NUMBER        := 29;
   --
   field_separator               CONSTANT VARCHAR2(1)   := CHR(29);
   record_separator              CONSTANT VARCHAR2(1)   := CHR(30);

   type str_tab_t     is table of varchar2(32767); -- table row with string fields
   type str_tab_tab_t is table of str_tab_t;       -- table of rows with string fields

--------------------------------------------------------------------------------
-- Splits string into a table of strings using the specified delimiter.
-- If no delmiter is specified, the string is split around whitespace.
-- 
-- Sequential delimiters in the source string result in null fields in the table,
-- except that if no delimiter is supplied, sequential whitespace characters are
-- treated as a single delimiter.
--
   FUNCTION split_text (
      p_text      in varchar2,
      p_separator in varchar2 default null)
      return str_tab_t;
      
--------------------------------------------------------------------------------
-- Joins a table of strings into a single string using the specified delimiter.
-- If no delimiter is supplied, the table fields are simply concatenated together.
--
-- Null fields in the table result in sequential delimiters in the returned string.
--
   FUNCTION join_text(
      p_text_tab  in str_tab_t,                      
      p_separator in varchar2 default null) 
      return varchar2;
--------------------------------------------------------------------------------
-- Parses a CLOB into a table of tables of strings.
--
-- Records are delimited by the record_separator character defined above.
-- Fields are delmited by the field_separator character defined above.
--
   FUNCTION parse_clob_recordset (p_clob IN  CLOB)
      return str_tab_tab_t;

--------------------------------------------------------------------------------
-- Parses a string into a table of tables of strings.
--
-- Records are delimited by the record_separator character defined above.
-- Fields are delmited by the field_separator character defined above.
--
   FUNCTION parse_string_recordset (p_string IN  VARCHAR2)
      return str_tab_tab_t;

   
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

   FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
      RETURN VARCHAR2;

--------------------------------------------------------
-- Return the current session user's primary office id
--
   function user_office_id
      return varchar2;
--------------------------------------------------------
-- return the current session user's primary office code
--
   function user_office_code
      return number;

--------------------------------------------------------
-- Return the office code for the specified office id,
-- or the user's primary office if the office id is null
--
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;
      
--------------------------------------------------------
-- Return the db host office code for the specified office id,
-- or the user's primary office if the office id is null
--
   function get_db_office_code (p_office_id in varchar2 default null)
      return number;

   PROCEDURE TEST;

   -- Dump (put_line) a character string p_str in chunks of length p_len
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80);

   -- Create the partitioned timeseries table view
   PROCEDURE create_view;
END cwms_util;
/