/* Formatted on 2006/11/20 14:30 (Formatter Plus v4.8.7) */
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
   -- delete_key                    CONSTANT VARCHAR2 (16) := 'DELETE KEY';
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
	irregular_interval_code			CONSTANT NUMBER		  := 29;

   TYPE ts_list IS TABLE OF VARCHAR2 (200)
      INDEX BY BINARY_INTEGER;

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
   FUNCTION user_office_id
      RETURN VARCHAR2;

--------------------------------------------------------
-- Return the office code for the specified office id,
-- or the user's primary office if the office id is null
--
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   PROCEDURE TEST;

   -- Dump (put_line) a character string p_str in chunks of length p_len
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80);

   -- Create the partitioned timeseries table view
   PROCEDURE create_view;
END cwms_util;
/
