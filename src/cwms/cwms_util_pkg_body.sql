/* Formatted on 2006/10/25 05:10 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE BODY cwms_util
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
******************************************************************************/--
   -- return the p_in_date which is in p_in_tz as a date in UTC
   FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      RETURN FROM_TZ (CAST (p_in_date AS TIMESTAMP), p_in_tz) AT TIME ZONE 'GMT';
   END;

   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_num          NUMBER := INSTR (p_full_id, '-', 1, 1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id, '.', 1, 1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.RAISE ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN p_full_id;
      ELSE
         RETURN SUBSTR (p_full_id, 1, l_num - 1);
      END IF;
   END;

   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_num          NUMBER := INSTR (p_full_id, '-', 1, 1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id, '.', 1, 1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.RAISE ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN NULL;
      ELSE
         RETURN SUBSTR (p_full_id, l_num + 1, l_sub_length);
      END IF;
   END;

   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF UPPER (p_true_false) = 'T' OR UPPER (p_true_false) = 'TRUE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   --
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF UPPER (p_true_false) = 'F' OR UPPER (p_true_false) = 'FALSE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

      -- Retruns TRUE if p_true_false is T or True
   -- Returns FALSE if p_true_false is F or False.
   FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF cwms_util.is_true (p_true_false)
      THEN
         RETURN TRUE;
      ELSIF cwms_util.is_false (p_true_false)
      THEN
         RETURN FALSE;
      ELSE
         cwms_err.RAISE ('INVALID_T_F_FLAG', p_true_false);
      END IF;
   END;

   --------------------------------------------------------
-- Return the current session user's primary office id
--
   FUNCTION user_office_id
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16) := NULL;
   BEGIN
--   select office_id
--     into l_office_id
--     from cwms_office
--    where office_code =
--          (
--            select primary_office
--              from at_sec_user_office
--             where user_id = sys_context('userenv', 'session_user')
--          );
      NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
         RETURN l_office_id;
   END user_office_id;

--------------------------------------------------------
-- Return the office code for the specified office id,
-- or the user's primary office if the office id is null
--
	FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
	   RETURN NUMBER
	IS
	   l_office_code   NUMBER := NULL;
	BEGIN
-- 	   IF p_office_id IS NULL
-- 	   THEN
-- 	      SELECT primary_office
-- 	        INTO l_office_code
-- 	        FROM at_sec_user_office
-- 	       WHERE user_id = SYS_CONTEXT ('userenv', 'session_user');
-- 	   ELSE
	      SELECT office_code
	        INTO l_office_code
	        FROM cwms_office
	       WHERE office_id = p_office_id;
--	   END IF;
	  RETURN l_office_code;
	EXCEPTION
	   WHEN NO_DATA_FOUND
	   THEN
	      cwms_err.RAISE ('INVALID_OFFICE_ID', p_office_id);
	      
	END get_office_code;


   PROCEDURE TEST
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('successful test');
   END;

	FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
	   RETURN VARCHAR2
	IS
	BEGIN
	   RETURN p_base_id || SUBSTR ('-', 1, LENGTH (p_sub_id)) || p_sub_id;
	END;

----------------------------------------------------------------------------
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80)
   IS
      i   PLS_INTEGER;
   BEGIN
      -- Dump (put_line) a character string p_str in chunks of length p_len
      i := 1;

      WHILE i < LENGTH (p_str)
      LOOP
         DBMS_OUTPUT.put_line (SUBSTR (p_str, i, p_len));
         i := i + p_len;
      END LOOP;
   END DUMP;

----------------------------------------------------------------------------
   PROCEDURE create_view
   IS
      l_sel   VARCHAR2 (120);
      l_sql   VARCHAR2 (4000);

      CURSOR c1
      IS
         SELECT *
           FROM at_ts_table_properties;
   BEGIN
      -- Create the partitioned timeseries table view

      -- Note: start_date and end_date are coded as ANSI DATE literals

      -- CREATE OR REPLACE FORCE VIEW AV_TSV AS
      -- select ts_code, date_time, data_entry_date, value, quality,
      --        DATE '2000-01-01' start_date, DATE '2001-01-01' end_date from IOT_2000
      -- union all
      -- select ts_code, date_time, data_entry_date, value, quality,
      --        DATE '2001-01-01' start_date, DATE '2002-01-01' end_date from IOT_2001
      l_sql := 'create or replace force view av_tsv as ';
      l_sel :=
         'select ts_code, date_time, version_date, data_entry_date, value, quality_code, DATE ''';

      FOR rec IN c1
      LOOP
         IF c1%ROWCOUNT > 1
         THEN
            l_sql := l_sql || ' union all ';
         END IF;

         l_sql :=
               l_sql
            || l_sel
            || TO_CHAR (rec.start_date, 'yyyy-mm-dd')
            || ''' start_date, DATE '''
            || TO_CHAR (rec.end_date, 'yyyy-mm-dd')
            || ''' end_date from '
            || rec.table_name;
      END LOOP;

      cwms_util.DUMP (l_sql);

      EXECUTE IMMEDIATE l_sql;
   EXCEPTION
      -- ORA-24344: success with compilation error
      WHEN OTHERS
      THEN
         --dbms_output.put_line(SQLERRM);
         RAISE;
   END create_view;
----------------------------------------------------------------------------
BEGIN
   -- anything put here will be executed on every mod_plsql call
   NULL;
END cwms_util;
/
