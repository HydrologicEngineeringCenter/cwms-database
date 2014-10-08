/* Formatted on 12/29/2011 8:07:55 AM (QP5 v5.185.11230.41888) */
SET DEFINE ON
@@defines.sql


CREATE OR REPLACE PACKAGE BODY cwms_util
AS
   FUNCTION min_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
      l_min_dms   NUMBER;
   BEGIN
      l_sec_dms :=
         ROUND (
            ( (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60.0)
             - TRUNC (
                  ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60))
            * 60.0,
            2);
      l_min_dms :=
         TRUNC (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);

      IF l_sec_dms = 60
      THEN
         RETURN l_min_dms + 1;
      ELSE
         RETURN l_min_dms;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END min_dms;

   --
   FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
      l_sec_60    NUMBER;
   BEGIN
      l_sec_dms :=
         ( (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60.0)
          - min_dms (p_decimal_degrees))
         * 60.0;
      l_sec_60 := ROUND (l_sec_dms, 2);

      IF l_sec_60 = 60
      THEN
         RETURN 0;
      ELSE
         RETURN l_sec_dms;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END sec_dms;

   --
   FUNCTION min_dm (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
   BEGIN
      RETURN (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END min_dm;

   --
   -- Filter out PST and CST
   function get_timezone (p_timezone in varchar2)
   return varchar2
   is
      l_timezone varchar2(28);
   begin
      if p_timezone is not null then
         begin
            select time_zone_name
              into l_timezone
              from cwms_time_zone_alias
             where upper(time_zone_alias) = upper(p_timezone); 
         exception
            when no_data_found then l_timezone := p_timezone;
         end;
      end if;
      return l_timezone;
   end get_timezone;

   FUNCTION get_xml_time (p_local_time IN DATE, p_local_tz IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_interval        INTERVAL DAY TO SECOND;
      l_tz_designator   VARCHAR2 (6);
      l_xml_time        VARCHAR2 (32);
   BEGIN
      l_xml_time := TO_CHAR (p_local_time, 'yyyy-mm-dd"T"hh24:mi:ss');
      l_interval :=
         CAST (p_local_time AS TIMESTAMP)
         - CAST (
              cwms_util.change_timezone (p_local_time, p_local_tz, 'UTC') AS TIMESTAMP);
      l_tz_designator :=
         CASE l_interval = TO_DSINTERVAL ('00 00:00:00')
            WHEN TRUE
      THEN
               'Z'
         ELSE
                  TO_CHAR (EXTRACT (HOUR FROM l_interval), 'S09')
               || ':'
               || TRIM (TO_CHAR (EXTRACT (MINUTE FROM l_interval), '09'))
         END;
      RETURN l_xml_time || l_tz_designator;
   END get_xml_time;

   FUNCTION FIXUP_TIMEZONE (p_time IN TIMESTAMP WITH TIME ZONE)
      RETURN TIMESTAMP WITH TIME ZONE
   IS
      l_time   TIMESTAMP WITH TIME ZONE;
   BEGIN
      CASE EXTRACT (TIMEZONE_REGION FROM p_time)
         WHEN 'PST'
         THEN
            CASE EXTRACT (TIMEZONE_ABBR FROM p_time)
               WHEN 'PDT'
               THEN
                  l_time :=
                     (p_time + TO_DSINTERVAL ('0 01:00:00'))
                        AT TIME ZONE 'ETC/GMT+8';
               ELSE
                  l_time := p_time;
            END CASE;
         WHEN 'CST'
         THEN
            CASE EXTRACT (TIMEZONE_ABBR FROM p_time)
               WHEN 'CDT'
               THEN
                  l_time :=
                     (p_time + TO_DSINTERVAL ('0 01:00:00'))
                        AT TIME ZONE 'ETC/GMT+6';
               ELSE
                  l_time := p_time;
            END CASE;
         ELSE
            l_time := p_time;
      END CASE;

      RETURN l_time;
   END FIXUP_TIMEZONE;

   --
   -- return the p_in_date which is in p_in_tz as a date in UTC
   FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      RETURN change_timezone (p_in_date, p_in_tz);
   END date_from_tz_to_utc;

   --
   -- return the input date in a different time zone
   FUNCTION change_timezone (p_in_date   IN TIMESTAMP,
                             p_from_tz   IN VARCHAR2,
                             p_to_tz     IN VARCHAR2 DEFAULT 'UTC')
      RETURN TIMESTAMP
      RESULT_CACHE
   IS
   BEGIN
      RETURN CASE p_to_tz = p_from_tz
                WHEN TRUE
                THEN
                   p_in_date
                ELSE
                   FROM_TZ (p_in_date, get_timezone (p_from_tz))
                      AT TIME ZONE get_timezone (p_to_tz)
             END;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END change_timezone;

   --
   -- return the input date in a different time zone
   FUNCTION change_timezone (p_in_date   IN DATE,
                             p_from_tz   IN VARCHAR2,
                             p_to_tz     IN VARCHAR2 DEFAULT 'UTC')
      RETURN DATE
      RESULT_CACHE
   IS
   BEGIN
      RETURN CASE p_to_tz = p_from_tz
                WHEN TRUE
                THEN
                   p_in_date
                ELSE
                   CAST (
                      FROM_TZ (CAST (p_in_date AS TIMESTAMP),
                               get_timezone (p_from_tz))
                         AT TIME ZONE get_timezone (p_to_tz) AS DATE)
             END;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END change_timezone;

   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_num          NUMBER
                        := INSTR (p_full_id,
                                  '-',
                                  1,
                                  1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id,
                   '.',
                   1,
                   1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.raise ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN p_full_id;
      ELSE
         RETURN SUBSTR (p_full_id, 1, l_num - 1);
      END IF;
   END get_base_id;

   FUNCTION get_base_param_code (p_param_id     IN VARCHAR2,
                                 p_is_full_id   IN VARCHAR2 DEFAULT 'F')
      RETURN NUMBER
      RESULT_CACHE
   IS
      l_base_param_code   NUMBER (10);
      l_base_param_id     VARCHAR2 (16);
   BEGIN
      CASE cwms_util.is_true (p_is_full_id)
         WHEN TRUE
         THEN
            l_base_param_id := get_base_id (p_param_id);
         WHEN FALSE
         THEN
            l_base_param_id := p_param_id;
      END CASE;

      SELECT base_parameter_code
        INTO l_base_param_code
        FROM cwms_base_parameter
       WHERE UPPER (base_parameter_id) = UPPER (TRIM (l_base_param_id));

      RETURN l_base_param_code;
   END get_base_param_code;

   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_num          NUMBER
                        := INSTR (p_full_id,
                                  '-',
                                  1,
                                  1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id,
                   '.',
                   1,
                   1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.raise ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN NULL;
      ELSE
         RETURN SUBSTR (p_full_id, l_num + 1, l_sub_length);
      END IF;
   END get_sub_id;

   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
      RESULT_CACHE
   IS
   BEGIN
      IF UPPER (p_true_false) = 'T' OR UPPER (p_true_false) = 'TRUE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_true;

   --
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
      RESULT_CACHE
   IS
   BEGIN
      IF UPPER (p_true_false) = 'F' OR UPPER (p_true_false) = 'FALSE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_false;

   -- Retruns TRUE if p_true_false is T or True
   -- Returns FALSE if p_true_false is F or False.
   FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
      RESULT_CACHE
   IS
   BEGIN
      IF cwms_util.is_true (p_true_false)
      THEN
         RETURN TRUE;
      ELSIF cwms_util.is_false (p_true_false)
      THEN
         RETURN FALSE;
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG', p_true_false);
      END IF;
   END return_true_or_false;

   -- Retruns 'T' if p_true_false is T or True
   -- Returns 'F 'if p_true_false is F or False.
   FUNCTION return_t_or_f_flag (p_true_false IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
   BEGIN
      IF cwms_util.is_true (p_true_false)
      THEN
         RETURN 'T';
      ELSIF cwms_util.is_false (p_true_false)
      THEN
         RETURN 'F';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG', p_true_false);
      END IF;
   END return_t_or_f_flag;

   --------------------------------------------------------------------------------
   -- function get_real_name
   --
   FUNCTION get_real_name (p_synonym IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_name             VARCHAR2 (32) := UPPER (p_synonym);
      invalid_sql_name   EXCEPTION;
      PRAGMA EXCEPTION_INIT (invalid_sql_name, -44003);
   BEGIN
      BEGIN
         SELECT DBMS_ASSERT.simple_sql_name (l_name) INTO l_name FROM DUAL;

         SELECT table_name
           INTO l_name
           FROM sys.all_synonyms
          WHERE     synonym_name = l_name
                AND owner = 'PUBLIC'
                AND table_owner = '&cwms_schema';
      EXCEPTION
         WHEN invalid_sql_name
         THEN
            cwms_err.raise ('INVALID_ITEM', p_synonym, 'schema item name');
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      RETURN l_name;
   END get_real_name;

   --------------------------------------------------------
   -- Return the current session user's primary office id
   --
   FUNCTION user_office_id
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16);
      l_username    VARCHAR2 (32);
   BEGIN
      l_username := get_user_id;


      SELECT SYS_CONTEXT ('CWMS_ENV', 'SESSION_OFFICE_ID')
        INTO l_office_id
        FROM DUAL;

      IF l_office_id IS NULL
      THEN
         IF l_username = '&cwms_schema' or l_username = 'NOBODY' or l_username = 'CCP'
         THEN
            RETURN 'CWMS';
         ELSE
      BEGIN
         SELECT a.office_id
           INTO l_office_id
           FROM cwms_office a, at_sec_user_office b
          WHERE     b.username = l_username
		AND a.office_code=b.db_office_code;
	    EXCEPTION WHEN OTHERS THEN
                cwms_err.raise ('SESSION_OFFICE_ID_NOT_SET');
            END;
         END IF;
         END IF;

      RETURN l_office_id;
   END user_office_id;

   PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                   p_office_long_name   OUT VARCHAR2)
   IS
      l_office_id   VARCHAR2 (16) := user_office_id;
   BEGIN
      SELECT office_id, long_name
           INTO p_office_id, p_office_long_name
        FROM cwms_office
       WHERE office_id = l_office_id;
   END get_user_office_data;

   --------------------------------------------------------
   -- Return the current session user's primary office code
   --
   FUNCTION user_office_code
      RETURN NUMBER
   IS
      l_office_code   NUMBER (10) := 0;
      l_office_id     VARCHAR2 (16) := user_office_id;
      BEGIN
      SELECT office_code
        INTO l_office_code
        FROM cwms_office
       WHERE office_id = l_office_id;


      RETURN l_office_code;
   END user_office_code;

   --------------------------------------------------------
   -- Return the office code for the specified office id,
   -- or the user's primary office if the office id is null
   --
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code   NUMBER := NULL;
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_code := user_office_code;
      ELSE
         SELECT office_code
           INTO l_office_code
           FROM cwms_office
          WHERE (office_id) = UPPER (p_office_id);
      END IF;

      RETURN l_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_OFFICE_ID', p_office_id);
   END get_office_code;

   --------------------------------------------------------
   -- Return the db host office code for the specified office id,
   -- or the user's primary office if the office id is null
   --
   FUNCTION get_db_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_db_office_code   NUMBER := NULL;
   BEGIN
      RETURN get_office_code (p_office_id);
   END get_db_office_code;

   FUNCTION get_db_office_id_from_code (p_db_office_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_db_office_id   VARCHAR2 (64);
   BEGIN
      l_db_office_id := NULL;

      SELECT office_id
        INTO l_db_office_id
        FROM cwms_office
       WHERE office_code = p_db_office_code;


      RETURN l_db_office_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN l_db_office_id;
   END get_db_office_id_from_code;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_db_office_id (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_db_office_code   NUMBER := NULL;
      l_db_office_id     VARCHAR2 (16);
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := user_office_id;
      ELSE
         SELECT office_id
           INTO l_db_office_id
           FROM cwms_office
          WHERE (office_id) = UPPER (p_db_office_id);
      END IF;

      RETURN l_db_office_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_OFFICE_ID', p_db_office_id);
   END get_db_office_id;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_location_id (p_location_code    IN NUMBER,
                             p_prepend_office   IN VARCHAR2 DEFAULT 'F')
      RETURN VARCHAR2
   IS
      l_location_id   VARCHAR2 (183);
      l_office_id     VARCHAR2 (16);
   BEGIN
      SELECT o.office_id,
                bl.base_location_id
             || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
             || pl.sub_location_id
        INTO l_office_id, l_location_id
        FROM at_physical_location pl, at_base_location bl, cwms_office o
       WHERE     pl.location_code = p_location_code
             AND bl.base_location_code = pl.base_location_code
             AND o.office_code = bl.db_office_code;

      IF is_true (p_prepend_office)
      THEN
         RETURN l_office_id || '/' || l_location_id;
      END IF;

      RETURN l_location_id;
   END get_location_id;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_parameter_id (p_parameter_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_parameter_id   VARCHAR2 (49);
   BEGIN
      BEGIN
         SELECT    cbp.base_parameter_id
                || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
                || atp.sub_parameter_id
           INTO l_parameter_id
           FROM at_parameter atp, cwms_base_parameter cbp
          WHERE atp.parameter_code = p_parameter_code
                AND atp.base_parameter_code = cbp.base_parameter_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               p_parameter_code || ' is not a valid parameter_code.');
      END;

      RETURN l_parameter_id;
   END get_parameter_id;

   --------------------------------------------------------
   -- Replace filename wildcard chars (?,*) with SQL ones
   -- (_,%), using '\' as an escape character.
   --
   --  A null input generates a result of '%'.
   --
   -- +--------------+-------------------------------------------------------------------------+
   -- |     |       Output String                |
   -- |     +------------------------------------------------------------+------------+
   -- |     |          Recognize SQL       |      |
   -- |     |           Wildcards?        |      |
   -- |     +------+---------------------------+-----+-------------------+      |
   -- | Input String | No  : comments        | Yes : comments    | Different? |
   -- +--------------+------+---------------------------+-----+-------------------+------------+
   -- | %    | \%  : literal '%'               | %   : multi-wildcard    | Yes        |
   -- | _    | \_  : literal '_'               | _   : single-wildcard   | Yes        |
   -- | *    | %  : multi-wildcard      | %   : multi-wildcard  | No     |
   -- | ?    | _  : single-wildcard     | _   : single-wildcard  | No     |
   -- | \%    |   : not allowed       | \%  : literal '%'       | Yes        |
   -- | \_    |   : not allowed       | \_  : literal '_'       | Yes        |
   -- | \*    | *  : literal '*'               | *   : literal '*'       | No         |
   -- | \?    | ?  : literal '?'               | ?   : literal '?'       | No         |
   -- | \\%    | \\\% : literal '\' + literal '%' | \\% : literal '\' + mwc | Yes        |
   -- | \\_    | \\\_ : literal '\' + literal '\' | \\_ : literal '\' + swc | Yes        |
   -- | \\*    | \\%  : literal '\' + mwc         | \\% : literal '\' + mwc | No         |
   -- | \\?    | \\_  : literal '\' + swc         | \\_ : literal '\' + swc | No         |
   -- +--------------+------+---------------------------+-----+-------------------+------------+
   --
   FUNCTION normalize_wildcards (p_string          IN VARCHAR2,
                                 p_recognize_sql   IN BOOLEAN DEFAULT FALSE)
      RETURN VARCHAR2
   IS
      l_result              VARCHAR2 (32767);
      c_slash      CONSTANT VARCHAR2 (1) := CHR (1);
      c_star       CONSTANT VARCHAR2 (1) := CHR (2);
      c_question   CONSTANT VARCHAR2 (1) := CHR (3);
   BEGIN
      --------------------------------
      -- default null string to '%' --
      --------------------------------
      IF p_string IS NULL
      THEN
         RETURN '%';
      END IF;

      l_result := REPLACE (p_string, '\\', c_slash);
      l_result := REPLACE (l_result, '\*', c_star);
      l_result := REPLACE (l_result, '\?', c_question);

      IF SUBSTR (l_result, LENGTH (l_result), 1) = '\'
      THEN
         cwms_err.raise (
            'ERROR',
            'Escape characater ''\'' cannot be the last character.');
      END IF;

      IF NOT p_recognize_sql
      THEN
         IF INSTR (l_result, '\%') + INSTR (l_result, '\_') != 0
         THEN
            cwms_err.raise (
               'ERROR',
               'Cannot have ''\%'' or ''\_'' if p_recognize_sql is false.');
         END IF;

         l_result := REGEXP_REPLACE (l_result, '%', '\%');
         l_result := REGEXP_REPLACE (l_result, '_', '\_');
      END IF;

      l_result := REPLACE (l_result, '*', '%');
      l_result := REPLACE (l_result, '?', '_');
      l_result := REPLACE (l_result, c_slash, '\\');
      l_result := REPLACE (l_result, c_star, '*');
      l_result := REPLACE (l_result, c_question, '?');

      RETURN l_result;
   END normalize_wildcards;

   --------------------------------------------------------
   -- Replace SQL ones (_,%) with filename wildcard chars (?,*),
   -- using '\' as an escape character.
   FUNCTION denormalize_wildcards (p_string IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_result              VARCHAR2 (32767);
      c_slash      CONSTANT VARCHAR2 (1) := CHR (1);
      c_percent    CONSTANT VARCHAR2 (1) := CHR (2);
      c_underbar   CONSTANT VARCHAR2 (1) := CHR (3);
   BEGIN
      --------------------------------
      -- default null string to '*' --
      --------------------------------
      IF p_string IS NULL
      THEN
         RETURN '*';
      END IF;

      l_result := REPLACE (p_string, '\\', c_slash);
      l_result := REPLACE (l_result, '\%', c_percent);
      l_result := REPLACE (l_result, '\_', c_underbar);

      IF SUBSTR (l_result, LENGTH (l_result), 1) = '\'
      THEN
         cwms_err.raise (
            'ERROR',
            'Escape characater ''\'' cannot be the last character.');
      END IF;

      l_result := REPLACE (l_result, '%', '*');
      l_result := REPLACE (l_result, '_', '?');
      l_result := REPLACE (l_result, c_slash, '\\');
      l_result := REPLACE (l_result, c_percent, '%');
      l_result := REPLACE (l_result, c_underbar, '_');

      RETURN l_result;
   END denormalize_wildcards;

   PROCEDURE parse_ts_id (p_base_location_id       OUT VARCHAR2,
                          p_sub_location_id        OUT VARCHAR2,
                          p_base_parameter_id      OUT VARCHAR2,
                          p_sub_parameter_id       OUT VARCHAR2,
                          p_parameter_type_id      OUT VARCHAR2,
                          p_interval_id            OUT VARCHAR2,
                          p_duration_id            OUT VARCHAR2,
                          p_version_id             OUT VARCHAR2,
                          p_cwms_ts_id          IN     VARCHAR2)
   IS
   BEGIN
      cwms_ts.parse_ts (p_cwms_ts_id          => p_cwms_ts_id,
                        p_base_location_id    => p_base_location_id,
                        p_sub_location_id     => p_sub_location_id,
                        p_base_parameter_id   => p_base_parameter_id,
                        p_sub_parameter_id    => p_sub_parameter_id,
                        p_parameter_type_id   => p_parameter_type_id,
                        p_interval_id         => p_interval_id,
                        p_duration_id         => p_duration_id,
                        p_version_id          => p_version_id);
   END parse_ts_id;

   --------------------------------------------------------------------------------
   -- Parses a search string into one or more AND/OR LIKE/NOT LIKE predicate lines.
   -- A search string contains one or more search patterns separated by a blank -
   -- space. When constructing search patterns on can use AND, OR, and NOT between-
   -- search patterns. a blank space between two patterns is assumed to be an AND.
   -- Quotes can be used to aggregate search patterns that contain one or more  -
   -- blank spaces.
   --
   FUNCTION parse_search_string (p_search_patterns   IN VARCHAR2,
                                 p_search_column     IN VARCHAR2,
                                 p_use_upper         IN BOOLEAN DEFAULT TRUE)
      RETURN VARCHAR2
   --------------------------------------------------------------------------------
   -- Usage:                    -
   --   *  - wild card character matches zero or more occurences.   -
   --   ?  - wild card character matches zero or one occurence.   -
   --   and - AND or a blank space, e.g., abc* *123 is eqivalent to   -
   --             abc* AND *123       -
   --   or - OR  e.g., abc* OR *123             -
   --   not - NOT or a dash, e.g., 'NOT abc*' is equivalent to '-abc*'     -
   --   " " - quotes are used to aggregate patters that have blank spaces   -
   --   e.g., "abc 123*"                                              -
   --
   --   One can use the backslash as an escape character for the following  -
   --   special characters:               -
   --   \* used to make an asterisks a literal instead of a wild character  -                    -
   --   \? used to make a question mark a literal instead of a wild   -
   --   character                   -
   --   \- used to start a new parse pattern with a dash instead of a NOT -
   --   \" used to make a quote a literal part of the parse pattern.        -
   --
   -- Example:
   -- p_search_column: COLUMN_OF_INTEREST           -
   -- p_search_patterns: cb* NOT cbt* OR NOT cbk*         -
   --   will return:                  -
   --    AND UPPER(COLUMN_OF_INTEREST)  LIKE 'CB%'                -
   --    AND UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBT%'            -
   --    OR UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBK%'             -
   --
   --  if p_use_upper is set to false, the above will return:
   --
   --     AND COLUMN_OF_INTEREST  LIKE 'cb%'                      -
   --     AND COLUMN_OF_INTEREST NOT LIKE 'cbt%'                  -
   --     OR COLUMN_OF_INTEREST NOT LIKE 'cbk%'                   -
   --
   --  A null p_search_patterns generates a result of '%'.
   --
   --     AND COLUMN_OF_INTEREST  LIKE '%'                        -
   --------------------------------------------------------------------------------
   --
   IS
      l_string                VARCHAR2 (256) := TRIM (p_search_patterns);
      l_search_column         VARCHAR2 (30) := UPPER (TRIM (p_search_column));
      l_use_upper             BOOLEAN := NVL (p_use_upper, TRUE);
      l_recognize_sql         BOOLEAN := FALSE;
      l_string_length         NUMBER := NVL (LENGTH (l_string), 0);
      l_skip                  NUMBER := 0;
      l_looking_first_quote   BOOLEAN := TRUE;
      l_sub_string_done       BOOLEAN := FALSE;
      l_first_char            BOOLEAN := TRUE;
      l_char                  VARCHAR2 (1);
      l_sub_string            VARCHAR2 (64) := NULL;
      l_not                   VARCHAR2 (3) := NULL;
      l_and_or                VARCHAR2 (3) := 'AND';
      l_result                VARCHAR2 (1000) := NULL;
      l_open_upper            VARCHAR2 (7);
      l_close_upper           VARCHAR2 (2);
      l_open_paran            VARCHAR2 (10) := NULL;
      l_close_paran           VARCHAR2 (10) := NULL;
      l_space                 VARCHAR2 (1) := ' ';
      l_num_open_paran        NUMBER := 0;
      l_char_position         NUMBER := 0;
      l_num_element           NUMBER := 0;
      l_t                     VARCHAR2 (1);
      l_tmp_string            VARCHAR2 (100) := NULL;
      l_is_closing_quotes     BOOLEAN;
   BEGIN
      --
      -- set the UPPER( ) wrapper...
      IF l_use_upper
      THEN
         l_open_upper := ' UPPER(';
         l_close_upper := ') ';
      ELSE
         l_open_upper := ' ';
         l_close_upper := ' ';
      END IF;

      --
      -- Make sure something was passed in.
      IF l_string_length > 0
      THEN
         FOR i IN 1 .. LENGTH (l_string)
         LOOP
            --   IF l_looking_first_quote
            --   THEN
            --   l_t := 'T';
            --   ELSE
            --   l_t := 'F';
            --   END IF;

            --   DBMS_OUTPUT.put_line (  l_t
            --         || l_char_position
            --         || '>'
            --         || l_sub_string
            --         || '< skip: '
            --         || l_skip
            --        );
            IF l_skip > 0
            THEN
               l_skip := l_skip - 1;
            ELSE
               l_char := SUBSTR (l_string, i, 1);

               --dbms_output.put_line('>>' || l_char || '<<');
               CASE l_char
                  WHEN '\'
                  THEN
                     IF REGEXP_INSTR (NVL (SUBSTR (l_string, i + 1, 1), ' '),
                                      '["*?\(\)]') = 1
                     THEN
                        l_sub_string :=
                           l_sub_string || '\' || SUBSTR (l_string, i + 1, 1);
                        l_char_position := l_char_position + 2;
                     ELSE
                        l_sub_string :=
                           l_sub_string || SUBSTR (l_string, i + 1, 1);
                        l_char_position := l_char_position + 1;
                     END IF;

                     l_skip := l_skip + 1;
                  WHEN '('
                  THEN
                     IF l_char_position = 0
                     THEN
                        l_sub_string := l_sub_string || l_char;
                     ELSE
                        l_sub_string := l_sub_string || l_char;
                        l_char_position := l_char_position + 1;
                     END IF;
                  WHEN ')'
                  THEN
                     l_tmp_string := NULL;

                     FOR j IN i .. l_string_length
                     LOOP
                        l_tmp_string := l_tmp_string || ')';
                        l_skip := l_skip + 1;

                        --DBMS_OUTPUT.put_line (l_tmp_string);
                        IF j = l_string_length
                           OR INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                     ' ') = 1
                        THEN
                           l_is_closing_quotes := TRUE;
                           EXIT;
                        ELSIF INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                     ')') = 1
                        THEN
                           NULL;
                        ELSE
                           l_is_closing_quotes := FALSE;
                           EXIT;
                        END IF;
                     END LOOP;

                     IF l_is_closing_quotes
                     THEN
                        l_close_paran := l_tmp_string;
                     ELSE
                        l_sub_string := l_sub_string || l_tmp_string;
                     END IF;
                  WHEN '"'
                  THEN
                     IF l_looking_first_quote
                     THEN
                        IF l_char_position = 0
                        THEN
                           l_looking_first_quote := FALSE;
                        ELSE
                           l_sub_string := l_sub_string || l_char;
                           l_char_position := l_char_position + 1;
                        END IF;
                     ELSE                        -- looking for the end quote.
                        --
                        -- An end quote must be followed by a space or end the string.
                        --
                        l_tmp_string := NULL;

                        FOR j IN i .. l_string_length
                        LOOP
                           -- l_tmp_string := l_tmp_string || ')';
                           --l_skip := l_skip + 1;
                           --DBMS_OUTPUT.put_line (l_tmp_string);
                           IF j = l_string_length
                              OR INSTR (
                                    NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                    ' ') = 1
                           THEN
                              l_is_closing_quotes := TRUE;
                              l_sub_string_done := TRUE;
                              --dbms_output.put_line('string is done!');
                              EXIT;
                           ELSIF INSTR (
                                    NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                    ')') = 1
                           THEN
                              l_tmp_string := l_tmp_string || ')';
                              l_skip := l_skip + 1;
                           ELSE
                              l_is_closing_quotes := FALSE;
                              EXIT;
                           END IF;
                        END LOOP;

                        IF l_is_closing_quotes
                        THEN
                           l_close_paran := l_tmp_string;
                        ELSE
                           l_sub_string := '"' || l_sub_string || l_tmp_string;
                        END IF;
                     -----------------
                     --     IF  INSTR (NVL (SUBSTR (l_string, i + 1), ' '), ' ') =
                     --                       1
                     --      OR i = l_string_length
                     --     THEN
                     --      l_skip := l_skip + 1;
                     --      l_sub_string_done := TRUE;
                     --     ELSE
                     --      l_sub_string := l_sub_string || l_char;
                     --      l_char_position := l_char_position + 1;
                     --     END IF;
                     END IF;
                  WHEN ' '
                  THEN
                     IF l_looking_first_quote
                     THEN
                        l_sub_string_done := TRUE;
                     ELSE
                        l_sub_string := l_sub_string || l_char;
                        l_char_position := l_char_position + 1;
                     END IF;
                  ELSE
                     l_sub_string := l_sub_string || l_char;
                     l_char_position := l_char_position + 1;
               END CASE;
            END IF;

            IF l_sub_string_done OR i = l_string_length
            THEN
               IF LENGTH (l_sub_string) > 0
               THEN
                  IF i = l_string_length
                  THEN
                     l_sub_string_done := TRUE;
                  END IF;

                  IF l_looking_first_quote
                  THEN
                     CASE l_sub_string
                        WHEN 'OR'
                        THEN
                           l_and_or := 'OR';
                           l_sub_string_done := FALSE;
                        WHEN 'AND'
                        THEN
                           l_and_or := 'AND';
                           l_sub_string_done := FALSE;
                        WHEN 'NOT'
                        THEN
                           l_not := 'NOT';
                           l_sub_string_done := FALSE;
                        ELSE
                           NULL;
                     END CASE;
                  END IF;

                  IF l_sub_string_done
                  THEN
                     l_sub_string :=
                        cwms_util.normalize_wildcards (
                           p_string          => l_sub_string,
                           p_recognize_sql   => l_recognize_sql);

                     IF l_use_upper
                     THEN
                        l_sub_string := UPPER (l_sub_string);
                     END IF;

                     IF l_num_element = 0
                     THEN
                        l_and_or := ' ( ';
                        l_num_element := 1;
                     END IF;

                     l_result :=
                           l_result
                        || ' '
                        || l_and_or
                        || l_space
                        || l_open_paran
                        || l_open_upper
                        || l_search_column
                        || l_close_upper
                        || l_not
                        || ' LIKE '''
                        || l_sub_string
                        || ''' '
                        || l_close_paran
                        || l_space
                        || CHR (10);
                     l_and_or := 'AND';
                     l_not := NULL;
                     l_open_paran := NULL;
                     l_close_paran := NULL;
                     l_looking_first_quote := TRUE;
                  END IF;
               END IF;

               l_first_char := TRUE;
               l_sub_string := NULL;
               l_sub_string_done := FALSE;
               l_char_position := 0;
            END IF;
         END LOOP;

         l_result := l_result || ' ) ';
      ELSE
         l_result := ' 1 = 1 ';
      END IF;

      RETURN l_result;
   END parse_search_string;

   --------------------------------------------------------------------
   -- Return a string with all leading and trailing whitespace removed.
   --
   FUNCTION strip (p_text IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_first   PLS_INTEGER := 1;
      l_last    PLS_INTEGER := LENGTH (p_text);
   BEGIN
      if p_text is null then 
         return null; 
      end if;
      FOR i IN l_first .. l_last
      LOOP
         l_first := i;
         EXIT WHEN ASCII (SUBSTR (p_text, i, 1)) BETWEEN 33 AND 126;
      END LOOP;

      FOR i IN REVERSE l_first .. l_last
      LOOP
         l_last := i;
         EXIT WHEN ASCII (SUBSTR (p_text, i, 1)) BETWEEN 33 AND 126;
      END LOOP;

      RETURN SUBSTR (p_text, l_first, l_last - l_first + 1);
   END strip;

   --------------------------------------------------------------------------------
   PROCEDURE test
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('successful test');
   END test;

   FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
   BEGIN
      RETURN    p_base_id
             || SUBSTR ('-', 1, LENGTH (TRIM (p_sub_id)))
             || TRIM (p_sub_id);
   END concat_base_sub_id;

   FUNCTION concat_ts_id (p_base_location_id    IN VARCHAR2,
                          p_sub_location_id     IN VARCHAR2,
                          p_base_parameter_id   IN VARCHAR2,
                          p_sub_parameter_id    IN VARCHAR2,
                          p_parameter_type_id   IN VARCHAR2,
                          p_interval_id         IN VARCHAR2,
                          p_duration_id         IN VARCHAR2,
                          p_version_id          IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_base_location_id    VARCHAR2 (16) := TRIM (p_base_location_id);
      l_sub_location_id     VARCHAR2 (32) := TRIM (p_sub_location_id);
      l_base_parameter_id   VARCHAR2 (16) := TRIM (p_base_parameter_id);
      l_sub_parameter_id    VARCHAR2 (32) := TRIM (p_sub_parameter_id);
      l_parameter_type_id   VARCHAR2 (16) := TRIM (p_parameter_type_id);
      l_interval_id         VARCHAR2 (16) := TRIM (p_interval_id);
      l_duration_id         VARCHAR2 (16) := TRIM (p_duration_id);
      l_version_id          VARCHAR2 (32) := TRIM (p_version_id);
   BEGIN
      SELECT cbp.base_parameter_id
        INTO l_base_parameter_id
        FROM cwms_base_parameter cbp
       WHERE UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

      SELECT cpt.parameter_type_id
        INTO l_parameter_type_id
        FROM cwms_parameter_type cpt
       WHERE UPPER (cpt.parameter_type_id) = UPPER (l_parameter_type_id);

      SELECT interval_id
        INTO l_interval_id
        FROM cwms_interval ci
       WHERE UPPER (ci.interval_id) = UPPER (l_interval_id);

      SELECT duration_id
        INTO l_duration_id
        FROM cwms_duration cd
       WHERE UPPER (cd.duration_id) = UPPER (l_duration_id);

      IF l_parameter_type_id = 'Inst' AND l_duration_id != '0'
      THEN
         cwms_err.raise (
            'ERROR',
               'The Duration Id for an "Inst" record cannot be "'
            || l_duration_id
            || '". The Duration Id must be "0".');
      -----------------------------------------------------------------
      -- This condition is no longer true. A "0" duration indicates  --
      -- a duration from the last irregular value to the current one --
      -----------------------------------------------------------------
      -- ELSIF l_parameter_type_id IN ('Ave', 'Max', 'Min', 'Total') AND l_duration_id = '0'
      -- THEN
      --  cwms_err.raise (
      --   'ERROR',
      --    'A Parameter Type of "'
      --   || l_parameter_type_id
      --   || '" cannot have a "0" Duration Id.'
      --  );
      END IF;

      RETURN    l_base_location_id
             || SUBSTR ('-', 1, LENGTH (l_sub_location_id))
             || l_sub_location_id
             || '.'
             || l_base_parameter_id
             || SUBSTR ('-', 1, LENGTH (l_sub_parameter_id))
             || l_sub_parameter_id
             || '.'
             || l_parameter_type_id
             || '.'
             || l_interval_id
             || '.'
             || l_duration_id
             || '.'
             || l_version_id;
   END concat_ts_id;

   --------------------------------------------------------------------------------
   -- function get_time_zone_code
   --
   FUNCTION get_time_zone_code (p_time_zone_name IN VARCHAR2)
      RETURN NUMBER
   IS
      l_time_zone_code   NUMBER (10);
   BEGIN
      SELECT time_zone_code
        INTO l_time_zone_code
        FROM mv_time_zone
       WHERE time_zone_name = get_timezone (NVL (p_time_zone_name, 'UTC'));

      RETURN l_time_zone_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_TIME_ZONE', p_time_zone_name);
   END get_time_zone_code;

   --------------------------------------------------------------------------------
   -- function get_time_zone_name
   --
   FUNCTION get_time_zone_name (p_time_zone_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_time_zone_name   VARCHAR2 (28);
   BEGIN
      SELECT z.time_zone_name
        INTO l_time_zone_name
        FROM mv_time_zone v, cwms_time_zone z
       WHERE v.time_zone_name = get_timezone (p_time_zone_name)
             AND z.time_zone_code = v.time_zone_code;

      RETURN l_time_zone_name;
   END get_time_zone_name;

   --------------------------------------------------------------------------------
   -- function get_tz_usage_code
   --
   FUNCTION get_tz_usage_code (p_tz_usage_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_tz_usage_code   NUMBER (10);
   BEGIN
      SELECT tz_usage_code
        INTO l_tz_usage_code
        FROM cwms_tz_usage
       WHERE UPPER (tz_usage_id) = UPPER (NVL (p_tz_usage_id, 'Standard'));

      RETURN l_tz_usage_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_tz_usage_id,
                         'CWMS time zone usage');
   END get_tz_usage_code;

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
         SELECT * FROM at_ts_table_properties;
   BEGIN
      -- Create the partitioned timeseries table view

      -- Note: start_date and end_date are coded as ANSI DATE literals

      -- CREATE OR REPLACE FORCE VIEW AV_TSV AS
      -- select ts_code, date_time, data_entry_date, value, quality,
      --   DATE '2000-01-01' start_date, DATE '2001-01-01' end_date from IOT_2000
      -- union all
      -- select ts_code, date_time, data_entry_date, value, quality,
      --   DATE '2001-01-01' start_date, DATE '2002-01-01' end_date from IOT_2001
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

   -------------------------------------------------------------------------------
   -- function split_text(...) overload to return a single element of the split
   --
   --
   FUNCTION split_text (p_text           IN VARCHAR2,
                        p_return_index   IN INTEGER,
                        p_separator      IN VARCHAR2 DEFAULT NULL,
                        p_max_split      IN INTEGER DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_str_tab        str_tab_t;
      l_return_index   INTEGER;
   BEGIN
      -- default index is first.
      IF p_return_index IS NULL
      THEN
         l_return_index := 1;
      ELSE
         l_return_index := p_return_index;
      END IF;

      --split the text.
      l_str_tab := split_text (p_text, p_separator, p_max_split);

      --error handle indexes.
      IF l_return_index <= 0 OR l_return_index > l_str_tab.COUNT
      THEN
         RETURN NULL;
      END IF;

      --grab element.
      RETURN l_str_tab (p_return_index);
   END split_text;

   -------------------------------------------------------------------------------
   -- function split_text(...)
   --
   --
   FUNCTION split_text (p_text        IN VARCHAR2,
                        p_separator   IN VARCHAR2 DEFAULT NULL,
                        p_max_split   IN INTEGER DEFAULT NULL)
      RETURN str_tab_t
      RESULT_CACHE
   IS
      l_str_tab        str_tab_t := str_tab_t ();
      l_str            VARCHAR2 (32767);
      l_field          VARCHAR2 (32767);
      l_pos            PLS_INTEGER;
      l_sep            VARCHAR2 (32767);
      l_sep_len        PLS_INTEGER;
      l_split_count    PLS_INTEGER := 0;
      l_count_splits   BOOLEAN;
   BEGIN
      IF p_text IS NOT NULL
      THEN
         l_count_splits := p_max_split IS NOT NULL;

         IF p_separator IS NULL
         THEN
            l_str := REGEXP_REPLACE (p_text, '\s+', ' ');
            l_sep := ' ';
         ELSE
            l_str := p_text;
            l_sep := p_separator;
         END IF;

         l_sep_len := LENGTH (l_sep);

         LOOP
            l_pos := INSTR (l_str, l_sep);

            IF l_count_splits AND l_split_count = p_max_split
            THEN
               l_pos := 0;
            END IF;

            IF l_pos = 0
            THEN
               l_field := l_str;
               l_str := NULL;
            ELSE
               l_split_count := l_split_count + 1;
               l_field := SUBSTR (l_str, 1, l_pos - 1);
               l_str := SUBSTR (l_str, l_pos + l_sep_len);
            END IF;

            l_str_tab.EXTEND;
            l_str_tab (l_str_tab.LAST) := l_field;
            EXIT WHEN l_pos = 0;

            IF l_str IS NULL
            THEN
               l_str_tab.EXTEND;
               l_str_tab (l_str_tab.LAST) := l_str;
               EXIT;
            END IF;
         END LOOP;
      END IF;

      RETURN l_str_tab;
   END split_text;

   -------------------------------------------------------------------------------
   -- function split_text(...)
   --
   --
   FUNCTION split_text (p_text        IN CLOB,
                        p_separator   IN VARCHAR2 DEFAULT NULL,
                        p_max_split   IN INTEGER DEFAULT NULL)
      RETURN str_tab_t
   IS
      l_clob                CLOB := p_text;
      l_rows                str_tab_t := str_tab_t ();
      l_new_rows            str_tab_t;
      l_buf                 VARCHAR2 (32767) := '';
      l_chunk               VARCHAR2 (4000);
      l_clob_offset         BINARY_INTEGER := 1;
      l_buf_offset          BINARY_INTEGER := 1;
      l_amount              BINARY_INTEGER;
      l_clob_len            BINARY_INTEGER;
      l_last                BINARY_INTEGER;
      l_done_reading        BOOLEAN;
      chunk_size   CONSTANT BINARY_INTEGER := 4000;
   BEGIN
      IF p_text IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_clob_len := DBMS_LOB.getlength (l_clob);
      l_amount := LEAST (chunk_size, l_clob_len);
      DBMS_LOB.open (l_clob, DBMS_LOB.lob_readonly);

      IF l_amount > 0
      THEN
         LOOP
            DBMS_LOB.read (l_clob,
                           l_amount,
                           l_clob_offset,
                           l_chunk);
            l_clob_offset := l_clob_offset + l_amount;
            l_done_reading := l_clob_offset > l_clob_len;
            l_buf := l_buf || l_chunk;

            IF INSTR (l_buf, p_separator) > 0 OR l_done_reading
            THEN
               l_new_rows := split_text (l_buf, p_separator);

               FOR i IN 1 .. l_new_rows.COUNT - 1
               LOOP
                  l_rows.EXTEND;
                  l_rows (l_rows.LAST) := l_new_rows (i);
               END LOOP;

               l_buf := l_new_rows (l_new_rows.COUNT);

               IF l_done_reading
               THEN
                  l_rows.EXTEND;
                  l_rows (l_rows.LAST) := l_buf;
               END IF;
            END IF;

            EXIT WHEN l_done_reading;
         END LOOP;
      END IF;

      DBMS_LOB.close (l_clob);
      RETURN l_rows;
   END split_text;

   -------------------------------------------------------------------------------
   -- function join_text(...)
   --
   --
   FUNCTION join_text (p_text_tab    IN str_tab_t,
                       p_separator   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_text   VARCHAR2 (32767) := NULL;
   BEGIN
      FOR i IN 1 .. p_text_tab.COUNT
      LOOP
         IF i > 1
         THEN
            l_text := l_text || p_separator;
         END IF;

         l_text := l_text || p_text_tab (i);
      END LOOP;

      RETURN l_text;
   END join_text;

   --------------------------------------------------------------------------------
   -- procedure format_xml(...)
   --
   PROCEDURE format_xml (p_xml_clob IN OUT NOCOPY CLOB, p_indent IN VARCHAR2)
   IS
      l_lines              str_tab_t;
      l_level              BINARY_INTEGER := 0;
      l_len                BINARY_INTEGER := LENGTH (NVL (p_indent, ''));
      l_newline   CONSTANT VARCHAR2 (1) := CHR (10);

      PROCEDURE write_line (p_line IN VARCHAR2)
      IS
      BEGIN
         IF l_len > 0
         THEN
            FOR i IN 1 .. l_level
            LOOP
               DBMS_LOB.writeappend (p_xml_clob, l_len, p_indent);
            END LOOP;
         END IF;

         DBMS_LOB.writeappend (p_xml_clob,
                               LENGTH (p_line) + 1,
                               p_line || l_newline);
      END;
   BEGIN
      IF p_xml_clob IS NOT NULL
      THEN
         p_xml_clob := REPLACE (p_xml_clob, '<', l_newline || '<');
         p_xml_clob := REPLACE (p_xml_clob, '>', '>' || l_newline);
         p_xml_clob := REPLACE (p_xml_clob, l_newline || l_newline, l_newline);
         l_lines := split_text (p_xml_clob, l_newline);
         DBMS_LOB.open (p_xml_clob, DBMS_LOB.lob_readwrite);
         DBMS_LOB.TRIM (p_xml_clob, 0);

         FOR i IN l_lines.FIRST .. l_lines.LAST
         LOOP
            FOR once IN 1 .. 1
            LOOP
               EXIT WHEN l_lines (i) IS NULL;
               l_lines (i) := TRIM (l_lines (i));
               EXIT WHEN LENGTH (l_lines (i)) = 0;

               IF INSTR (l_lines (i), '<') = 1
               THEN
                  IF INSTR (l_lines (i), '<!--') = 1
                  THEN
                     write_line (l_lines (i));
                  ELSIF INSTR (l_lines (i), '</') = 1
                  THEN
                     l_level := l_level - 1;
                     write_line (l_lines (i));
                  ELSE
                     write_line (l_lines (i));

                     IF INSTR (l_lines (i), '<xml?') != 1
                        AND INSTR (l_lines (i), '/>', -1) !=
                               LENGTH (l_lines (i)) - 1
                     THEN
                        l_level := l_level + 1;
                     END IF;
                  END IF;
               ELSE
                  write_line (l_lines (i));
               END IF;
            END LOOP;
         END LOOP;

         DBMS_LOB.close (p_xml_clob);
      END IF;
   END format_xml;

   -------------------------------------------------------------------------------
   -- function parse_clob_recordset(...)
   --
   --
   FUNCTION parse_clob_recordset (p_clob IN CLOB)
      RETURN str_tab_tab_t
   IS
      l_rows   str_tab_t;
      l_tab    str_tab_tab_t := str_tab_tab_t ();
   BEGIN
      IF p_clob IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_rows := split_text (p_clob, record_separator);

      IF l_rows.COUNT > 0
      THEN
         FOR i IN l_rows.FIRST .. l_rows.LAST
         LOOP
            l_tab.EXTEND;
            l_tab (l_tab.LAST) := split_text (l_rows (i), field_separator);
         END LOOP;
      END IF;

      RETURN l_tab;
   END parse_clob_recordset;

   -------------------------------------------------------------------------------
   -- function parse_string_recordset(...)
   --
   --
   FUNCTION parse_string_recordset (p_string IN VARCHAR2)
      RETURN str_tab_tab_t
   IS
      l_rows   str_tab_t;
      l_tab    str_tab_tab_t := str_tab_tab_t ();
   BEGIN
      IF p_string IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_rows := split_text (p_string, record_separator);

      IF l_rows.COUNT > 0
      THEN
         FOR i IN l_rows.FIRST .. l_rows.LAST
         LOOP
            l_tab.EXTEND;
            l_tab (l_tab.LAST) := split_text (l_rows (i), field_separator);
         END LOOP;
      END IF;

      RETURN l_tab;
   END parse_string_recordset;

   --------------------------------------------------------------------
   -- Return UTC timestamp for specified ISO 8601 string
   --
   FUNCTION TO_TIMESTAMP (p_iso_str IN VARCHAR2)
      RETURN TIMESTAMP
   IS
      l_yr                     VARCHAR2 (5);
      l_mon                    VARCHAR2 (2) := '01';
      l_day                    VARCHAR2 (2) := '01';
      l_hr                     VARCHAR2 (2) := '00';
      l_min                    VARCHAR2 (2) := '00';
      l_sec                    VARCHAR2 (8) := '00.0';
      l_tz                     VARCHAR2 (32) := '+00:00';
      l_time                   VARCHAR2 (32);
      l_parts                  str_tab_t;
      l_ts                     TIMESTAMP;
      l_offset                 INTERVAL DAY (9) TO SECOND (9);
      l_iso_pattern   CONSTANT VARCHAR2 (71)
         := '-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:(\d{2}([.]\d+)?))?([-+]\d{2}:\d{2}|Z)?' ;
      l_str                    VARCHAR2 (64) := strip (p_iso_str);
      l_pos                    BINARY_INTEGER;
      l_add_day                BOOLEAN := FALSE;
   BEGIN
      IF REGEXP_INSTR (l_str, l_iso_pattern) != 1
         OR REGEXP_INSTR (l_str,
                          l_iso_pattern,
                          1,
                          1,
                          1) != LENGTH (l_str) + 1
      THEN
         cwms_err.raise ('INVALID_ITEM', l_str, 'dateTime-formatted string');
      END IF;

      l_pos :=
         REGEXP_INSTR (l_str,
                       '-?\d{4}',
                       1,
                       1,
                       1);
      l_yr := SUBSTR (l_str, 1, l_pos - 1);
      l_str := SUBSTR (l_str, l_pos + 1);
      l_mon := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 4);
      l_day := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 4);
      l_hr := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 4);
      l_min := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 3);

      IF SUBSTR (l_str, 1, 1) = ':'
      THEN
         l_pos :=
            REGEXP_INSTR (l_str,
                          ':\d{2}([.]\d+)?',
                          1,
                          1,
                          1);
         l_sec := SUBSTR (l_str, 2, l_pos - 2);
         l_str := SUBSTR (l_str, l_pos);
      END IF;

      IF LENGTH (l_str) > 0
      THEN
         l_tz := l_str;
      END IF;

      IF l_hr = '24'
      THEN
         l_add_day := TRUE;
         l_hr := '00';
      END IF;

      l_time :=
            l_yr
         || '-'
         || l_mon
         || '-'
         || l_day
         || 'T'
         || l_hr
         || ':'
         || l_min
         || ':'
         || l_sec;

      ----------------------------------------------------------------------
      -- use select to avoid namespace collision with CWMS_UTIL functions --
      ----------------------------------------------------------------------
      SELECT TO_TIMESTAMP (l_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF')
        INTO l_ts
        FROM DUAL;

      IF l_add_day
      THEN
         l_ts := l_ts + INTERVAL '1 00:00:00' DAY TO SECOND;
      END IF;

      --------------------------------------------------------------
      -- for some reason the TZH:TZM format only works on TO_CHAR --
      --------------------------------------------------------------
      l_tz := REPLACE (l_tz, 'Z', '+00:00');
      l_parts := split_text (SUBSTR (l_tz, 2), ':');
      l_hr := l_parts (1);
      l_min := l_parts (2);
      l_offset := TO_DSINTERVAL ('0 ' || l_hr || ':' || l_min || ':00');

      IF SUBSTR (l_tz, 1, 1) = '-'
      THEN
         l_ts := l_ts + l_offset;
      ELSE
         l_ts := l_ts - l_offset;
      END IF;

      RETURN l_ts;
   END TO_TIMESTAMP;

   --------------------------------------------------------------------
   -- Return UTC timestamp for specified Java milliseconds
   --
   FUNCTION TO_TIMESTAMP (p_millis IN NUMBER)
      RETURN TIMESTAMP
   IS
      l_millis     NUMBER := ABS (p_millis);
      l_day        NUMBER;
      l_hour       NUMBER;
      l_min        NUMBER;
      l_sec        NUMBER;
      l_negative   BOOLEAN := p_millis < 0;
      l_interval   INTERVAL DAY (9) TO SECOND (9);
   BEGIN
      l_day := TRUNC (l_millis / 86400000);
      l_millis := l_millis - (l_day * 86400000);
      l_hour := TRUNC (l_millis / 3600000);
      l_millis := l_millis - (l_hour * 3600000);
      l_min := TRUNC (l_millis / 60000);
      l_millis := l_millis - (l_min * 60000);
      l_sec := TRUNC (l_millis / 1000);
      l_millis := l_millis - (l_sec * 1000);
      l_interval :=
         TO_DSINTERVAL (
               ''
            || l_day
            || ' '
            || TO_CHAR (l_hour, '00')
            || ':'
            || TO_CHAR (l_min, '00')
            || ':'
            || TO_CHAR (l_sec, '00')
            || '.'
            || TO_CHAR (l_millis, '000'));

      IF l_negative
      THEN
         RETURN epoch - l_interval;
      ELSE
         RETURN epoch + l_interval;
      END IF;
   END TO_TIMESTAMP;

   --------------------------------------------------------------------
   -- Return Java milliseconds for a specified UTC timestamp.
   --
   FUNCTION to_millis (p_timestamp IN TIMESTAMP)
      RETURN NUMBER
   IS
      l_intvl    INTERVAL DAY (9) TO SECOND (9);
      l_millis   NUMBER;
   BEGIN
      l_intvl := p_timestamp - epoch;
      l_millis :=
         TRUNC (
              EXTRACT (DAY FROM l_intvl) * 86400000
            + EXTRACT (HOUR FROM l_intvl) * 3600000
            + EXTRACT (MINUTE FROM l_intvl) * 60000
            + EXTRACT (SECOND FROM l_intvl) * 1000);
      RETURN l_millis;
   END to_millis;

   --------------------------------------------------------------------
   -- Return Java milliseconds for current time.
   --
   FUNCTION current_millis
      RETURN NUMBER
   IS
   BEGIN
      RETURN to_millis (SYSTIMESTAMP AT TIME ZONE 'UTC');
   END current_millis;

   --------------------------------------------------------------------
   -- Return Java microseconds for a specified UTC timestamp.
   --
   FUNCTION to_micros (p_timestamp IN TIMESTAMP)
      RETURN NUMBER
   IS
      l_intvl    INTERVAL DAY (9) TO SECOND (9);
      l_micros   NUMBER;
   BEGIN
      l_intvl := p_timestamp - epoch;
      l_micros :=
         TRUNC (
              EXTRACT (DAY FROM l_intvl) * 86400000000
            + EXTRACT (HOUR FROM l_intvl) * 3600000000
            + EXTRACT (MINUTE FROM l_intvl) * 60000000
            + EXTRACT (SECOND FROM l_intvl) * 1000000);
      RETURN l_micros;
   END to_micros;

   --------------------------------------------------------------------
   -- Return Java microseconds for current time.
   --
   FUNCTION current_micros
      RETURN NUMBER
   IS
   BEGIN
      RETURN to_micros (SYSTIMESTAMP AT TIME ZONE 'UTC');
   END current_micros;


   FUNCTION get_ts_interval (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
      RESULT_CACHE
   IS
      l_ts_interval   NUMBER;
   BEGIN
      SELECT a.interval
        INTO l_ts_interval
        FROM cwms_interval a, at_cwms_ts_spec b
       WHERE b.interval_code = a.interval_code AND b.ts_code = p_cwms_ts_code;

      RETURN l_ts_interval;
   END get_ts_interval;

   FUNCTION get_unit_id (p_unit_or_alias   IN VARCHAR2,
                         p_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS              
      l_unit_id_in    VARCHAR2 (16) := parse_unit(p_unit_or_alias);
      l_unit_id_out   VARCHAR2 (16);
      l_office_code   NUMBER (10) := get_db_office_code (p_office_id);
   BEGIN
      BEGIN
         SELECT unit_id
           INTO l_unit_id_out
           FROM cwms_unit
          WHERE unit_id = l_unit_id_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      IF l_unit_id_out IS NULL
      THEN
         BEGIN
            SELECT u.unit_id
              INTO l_unit_id_out
              FROM at_unit_alias ua, cwms_unit u
             WHERE ua.alias_id = l_unit_id_in
                   AND ua.db_office_code IN
                          (db_office_code_all, l_office_code)
                   AND u.unit_code = ua.unit_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;
      END IF;

      IF l_unit_id_out IS NULL
      THEN
         BEGIN
            SELECT unit_id
              INTO l_unit_id_out
              FROM cwms_unit
             WHERE UPPER (unit_id) = (l_unit_id_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF l_unit_id_out IS NULL
      THEN
         BEGIN
            SELECT u.unit_id
              INTO l_unit_id_out
              FROM at_unit_alias ua, cwms_unit u
             WHERE UPPER (ua.alias_id) = UPPER (l_unit_id_in)
                   AND ua.db_office_code IN
                          (db_office_code_all, l_office_code)
                   AND u.unit_code = ua.unit_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      RETURN l_unit_id_out;
   END get_unit_id;

   FUNCTION get_unit_id2 (p_unit_code IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_unit_id   VARCHAR2 (16);
   BEGIN
      SELECT unit_id
        INTO l_unit_id
        FROM cwms_unit
       WHERE unit_code = p_unit_code;

      RETURN l_unit_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM', p_unit_code, 'CWMS unit');
   END get_unit_id2;

   PROCEDURE get_valid_units (p_valid_units       OUT SYS_REFCURSOR,
                              p_parameter_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      IF p_parameter_id IS NULL
      THEN
         OPEN p_valid_units FOR
            SELECT a.unit_id
              FROM cwms_unit a;
      ELSE
         OPEN p_valid_units FOR
            SELECT a.unit_id
              FROM cwms_unit a
             WHERE abstract_param_code =
                      (SELECT abstract_param_code
                         FROM cwms_base_parameter
                        WHERE UPPER (base_parameter_id) =
                                 UPPER (get_base_id (p_parameter_id)));
      END IF;
   END get_valid_units;

   /* get_valid_unit_id return the properly cased unit_id for p_unit_id.
    */


   FUNCTION get_valid_unit_id (p_unit_id        IN VARCHAR2,
                               p_parameter_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_unit_id   VARCHAR2 (16);
   BEGIN
      BEGIN
         SELECT unit_id
           INTO l_unit_id
           FROM TABLE (get_valid_units_tab (p_parameter_id))
          WHERE unit_id = p_unit_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT unit_id
                 INTO l_unit_id
                 FROM TABLE (get_valid_units_tab (p_parameter_id))
                WHERE UPPER (unit_id) = UPPER (p_unit_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF p_parameter_id IS NULL
                  THEN
                     raise_application_error (
                        -20102,
                           'The unit: '
                        || TRIM (p_unit_id)
                        || ' is not a recognized CWMS Database unit.',
                        TRUE);
                  ELSE
                     raise_application_error (
                        -20102,
                           'The unit: '
                        || TRIM (p_unit_id)
                        || ' is not a recognized CWMS Database unit for the '
                        || TRIM (p_parameter_id)
                        || ' Parameter_ID.',
                        TRUE);
                  END IF;
               WHEN TOO_MANY_ROWS
               THEN
                  raise_application_error (
                     -20102,
                        'The unit: '
                     || TRIM (p_unit_id)
                     || ' has multiple matches in the CWMS Database.'
                     || ' Please specify the Parameter_ID and/or use the'
                     || ' exact letter casing for the desired unit.',
                     TRUE);
            END;
      END;

      RETURN l_unit_id;
   END get_valid_unit_id;

   FUNCTION get_valid_units_tab (p_parameter_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_unit_tab_t
      PIPELINED
   IS
      l_query_cursor   SYS_REFCURSOR;
      l_output_row     cat_unit_rec_t;
   BEGIN
      get_valid_units (l_query_cursor, p_parameter_id);

      LOOP
         FETCH l_query_cursor INTO l_output_row;

         EXIT WHEN l_query_cursor%NOTFOUND;
         PIPE ROW (l_output_row);
      END LOOP;

      CLOSE l_query_cursor;
   END get_valid_units_tab;

   FUNCTION get_unit_code (p_unit_id             IN VARCHAR2,
                           p_abstract_param_id   IN VARCHAR2 DEFAULT NULL,
                           p_db_office_id        IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_unit_code        NUMBER;
      l_db_office_code   VARCHAR2 (16) := get_db_office_code (p_db_office_id);
   BEGIN
      IF p_abstract_param_id IS NULL
      THEN
         BEGIN
            SELECT unit_code
              INTO l_unit_code
              FROM av_unit
             WHERE unit_id = TRIM (p_unit_id)
                   AND db_office_code IN (l_db_office_code, 53);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               TRIM (p_unit_id),
                               'unit id. Note units are case senstive.');
            WHEN TOO_MANY_ROWS
            THEN
               cwms_err.raise (
                  'ERROR',
                     'More than one entry was found for the unit: "'
                  || TRIM (p_unit_id)
                  || '". Try specifying the p_abstract_param for this unit.');
         END;
      ELSE
         BEGIN
            SELECT unit_code
              INTO l_unit_code
              FROM av_unit
             WHERE unit_id = TRIM (p_unit_id)
                   AND db_office_code IN (l_db_office_code, 53)
                   AND abstract_param_code =
                          (SELECT abstract_param_code
                             FROM cwms_abstract_parameter
                            WHERE abstract_param_id =
                                     UPPER (TRIM (p_abstract_param_id)));
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               TRIM (p_unit_id),
                               'unit id. Note units are case senstive.');
         END;
      END IF;

      RETURN l_unit_code;
   END get_unit_code;

   FUNCTION get_ts_group_code (p_ts_category_id   IN VARCHAR2,
                               p_ts_group_id      IN VARCHAR2,
                               p_db_office_code   IN NUMBER)
      RETURN NUMBER
   IS
      l_ts_group_code   NUMBER;
   BEGIN
      IF p_db_office_code IS NULL
      THEN
         cwms_err.raise ('ERROR', 'p_db_office_code cannot be null.');
      END IF;

      --
      IF p_ts_category_id IS NOT NULL AND p_ts_group_id IS NOT NULL
      THEN
         BEGIN
            SELECT ts_group_code
              INTO l_ts_group_code
              FROM at_ts_group a, at_ts_category b
             WHERE a.ts_category_code = b.ts_category_code
                   AND UPPER (b.ts_category_id) =
                          UPPER (TRIM (p_ts_category_id))
                   AND b.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all)
                   AND UPPER (a.ts_group_id) = UPPER (TRIM (p_ts_group_id))
                   AND a.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise (
                  'ERROR',
                     'Could not find '
                  || TRIM (p_ts_category_id)
                  || '-'
                  || TRIM (p_ts_group_id)
                  || ' category-group combination');
         END;
      ELSIF (p_ts_category_id IS NOT NULL AND p_ts_group_id IS NULL)
            OR (p_ts_category_id IS NULL AND p_ts_group_id IS NOT NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The ts_category_id and ts_group_id is not a valid combination');
      END IF;

      RETURN l_ts_group_code;
   END get_ts_group_code;

   FUNCTION get_loc_group_code (p_loc_category_id   IN VARCHAR2,
                                p_loc_group_id      IN VARCHAR2,
                                p_db_office_code    IN NUMBER)
      RETURN NUMBER
   IS
      l_loc_group_code   NUMBER;
   BEGIN
      IF p_db_office_code IS NULL
      THEN
         cwms_err.raise ('ERROR', 'p_db_office_code cannot be null.');
      END IF;

      --
      IF p_loc_category_id IS NOT NULL AND p_loc_group_id IS NOT NULL
      THEN
         BEGIN
            SELECT loc_group_code
              INTO l_loc_group_code
              FROM at_loc_group a, at_loc_category b
             WHERE a.loc_category_code = b.loc_category_code
                   AND UPPER (b.loc_category_id) =
                          UPPER (TRIM (p_loc_category_id))
                   AND b.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all)
                   AND UPPER (a.loc_group_id) = UPPER (TRIM (p_loc_group_id))
                   AND a.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise (
                  'ERROR',
                     'Could not find '
                  || TRIM (p_loc_category_id)
                  || '-'
                  || TRIM (p_loc_group_id)
                  || ' category-group combination');
         END;
      ELSIF (p_loc_category_id IS NOT NULL AND p_loc_group_id IS NULL)
            OR (p_loc_category_id IS NULL AND p_loc_group_id IS NOT NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The loc_category_id and loc_group_id is not a valid combination');
      END IF;

      RETURN l_loc_group_code;
   END get_loc_group_code;

   FUNCTION get_loc_group_code (p_loc_category_id   IN VARCHAR2,
                                p_loc_group_id      IN VARCHAR2,
                                p_db_office_id      IN VARCHAR2)
      RETURN NUMBER
   IS
   BEGIN
      RETURN get_loc_group_code (
                p_loc_category_id   => p_loc_category_id,
                p_loc_group_id      => p_loc_group_id,
                p_db_office_code    => cwms_util.get_db_office_code (
                                         p_db_office_id));
   END get_loc_group_code;

   --------------------------------------------------------------------------------
   -- get_user_id uses either sys_context or the apex authenticated user id. -
   --
   -- The "v" function is installed with apex - so apex needs to be installed     -
   -- for this package to compile.
   --------------------------------------------------------------------------------
   FUNCTION get_user_id
      RETURN VARCHAR2
   IS
      l_user_id   VARCHAR2 (31);
   BEGIN
      IF v ('APP_USER') != 'APEX_PUBLIC_USER' AND v ('APP_USER') IS NOT NULL
      THEN
         l_user_id := v ('APP_USER');
      ELSE
         l_user_id := SYS_CONTEXT ('userenv', 'session_user');
      END IF;

      RETURN UPPER (l_user_id);
   END get_user_id;

   PROCEDURE user_display_unit (
      p_unit_id           OUT VARCHAR2,
      p_value_out         OUT NUMBER,
      p_parameter_id   IN     VARCHAR2,
      p_value_in       IN     NUMBER DEFAULT NULL,
      p_user_id        IN     VARCHAR2 DEFAULT NULL,
      p_office_id      IN     VARCHAR2 DEFAULT NULL)
   IS
      l_unit_system           VARCHAR2 (2);
      l_user_id               VARCHAR2 (31) := UPPER (NVL (p_user_id, get_user_id));
      l_office_id             VARCHAR2 (16) := get_db_office_id (p_office_id);
      l_base_parameter_id     VARCHAR2 (16) := get_base_id (p_parameter_id);
      l_office_code           NUMBER := get_db_office_code (p_office_id);
      l_unit_code             NUMBER;
      l_base_parameter_code   NUMBER;
   BEGIN
      p_unit_id := NULL;
      p_value_out := NULL;
      --
      -- get preferred unit system or default to 'SI'
      --
      l_unit_system :=
         cwms_properties.get_property ('Pref_User.' || l_user_id,
                                       'Unit_System',
                                       cwms_properties.get_property (
                                          'Pref_Office',
                                          'Unit_System',
                                          'SI',
                                          l_office_id),
                                       l_office_id);

      --
      -- get display unit for parameter in preferred unit system
      --
      BEGIN
         SELECT base_parameter_code,
                CASE l_unit_system
                   WHEN 'SI' THEN display_unit_code_si
                   WHEN 'EN' THEN display_unit_code_en
                END
           INTO l_base_parameter_code, l_unit_code
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (l_base_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('INVALID_PARAM_ID', p_parameter_id);
      END;

      SELECT unit_id
        INTO p_unit_id
        FROM cwms_unit
       WHERE unit_code = l_unit_code;

      --
      -- convert the specified value from storage unit
      --
      IF p_value_in IS NOT NULL
      THEN
         SELECT p_value_in * cuc.factor + cuc.offset
           INTO p_value_out
           FROM cwms_unit_conversion cuc, cwms_base_parameter bp
          WHERE     bp.base_parameter_code = l_base_parameter_code
                AND cuc.from_unit_code = bp.unit_code
                AND cuc.to_unit_code = l_unit_code;
      END IF;
   END user_display_unit;

   FUNCTION get_interval_string (p_interval IN NUMBER)
      RETURN VARCHAR2
   IS
      --   public static final String YEAR_TIME_INTERVAL  = "yr";
      --   public static final String MONTH_TIME_INTERVAL = "mo";
      --   public static final String WEEK_TIME_INTERVAL  = "wk";
      --   public static final String DAY_TIME_INTERVAL = "dy";
      --   public static final String HOUR_TIME_INTERVAL  = "hr";
      --   public static final String MINUTE_TIME_INTERVAL = "mi";
      l_num_yr    NUMBER;
      l_num_mo    NUMBER;
      l_num_wk    NUMBER;
      l_num_dy    NUMBER;
      l_num_hr    NUMBER;
      l_num_mi    NUMBER;
      l_min_rem   NUMBER;
      l_lvl       VARCHAR2 (2) := NULL;
      l_return    VARCHAR2 (64) := NULL;
   BEGIN
      --
      l_num_yr := TRUNC (p_interval / CWMS_TS.MIN_IN_YR);
      l_min_rem := l_num_yr * CWMS_TS.MIN_IN_YR;

      IF l_num_yr > 0
      THEN
         l_return := l_num_yr || 'yr';
         l_lvl := 'YR';
      END IF;

      --
      l_num_mo := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_MO);
      l_min_rem := l_min_rem + l_num_mo * CWMS_TS.MIN_IN_MO;

      CASE
         WHEN l_lvl IS NULL
         THEN
            IF l_num_mo > 0
            THEN
               l_return := l_num_mo || 'mo';
               l_lvl := 'MO';
            END IF;
         ELSE
            l_return := l_return || l_num_mo || 'mo';
      END CASE;

      --
      --      l_num_wk := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_WK);
      --      l_min_rem := l_min_rem + l_num_wk * CWMS_TS.MIN_IN_WK;
      --
      --      CASE
      --         WHEN l_lvl IS NULL
      --         THEN
      --            IF l_num_wk > 0
      --            THEN
      --               l_return := l_num_wk || 'wk';
      --               l_lvl := 'WK';
      --            END IF;
      --         ELSE
      --            l_return := l_return || l_num_wk || 'wk';
      --      END CASE;

      --
      l_num_dy := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_DY);
      l_min_rem := l_min_rem + l_num_dy * CWMS_TS.MIN_IN_DY;

      CASE
         WHEN l_lvl IS NULL
         THEN
            IF l_num_dy > 0
            THEN
               l_return := l_num_dy || 'dy';
               l_lvl := 'DY';
            END IF;
         ELSE
            l_return := l_return || l_num_dy || 'dy';
      END CASE;

      --
      l_num_hr := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_HR);
      l_min_rem := l_min_rem + l_num_hr * CWMS_TS.MIN_IN_HR;

      CASE
         WHEN l_lvl IS NULL
         THEN
            IF l_num_hr > 0
            THEN
               l_return := l_num_hr || 'hr';
               l_lvl := 'HR';
            END IF;
         ELSE
            l_return := l_return || l_num_hr || 'hr';
      END CASE;

      --
      l_num_mi := p_interval - l_min_rem;
      l_return := l_return || l_num_mi || 'mi';
      --



      RETURN l_return;
   END get_interval_string;

   FUNCTION get_user_display_unit (p_parameter_id   IN VARCHAR2,
                                   p_user_id        IN VARCHAR2 DEFAULT NULL,
                                   p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_unit_id     VARCHAR2 (16);
      l_value_out   NUMBER;
   BEGIN
      user_display_unit (l_unit_id,
                         l_value_out,
                         p_parameter_id,
                         1.0,
                         p_user_id,
                         p_office_id);

      RETURN l_unit_id;
   END get_user_display_unit;

   ----------------------------------------------------------------------------

   FUNCTION get_default_units (p_parameter_id   IN VARCHAR2,
                               p_unit_system    IN VARCHAR2 DEFAULT 'SI')
      RETURN VARCHAR2
   AS
      l_default_units     VARCHAR2 (16);
      l_base_param_code   NUMBER;
   BEGIN
      IF p_parameter_id IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_base_param_code := get_base_param_code (get_base_id (p_parameter_id));

      IF UPPER (p_unit_system) = 'SI'
      THEN
         SELECT a.unit_id
           INTO l_default_units
           FROM cwms_unit a, cwms_base_parameter b
          WHERE a.unit_code = b.display_unit_code_si
                AND b.base_parameter_code = l_base_param_code;
      ELSIF UPPER (p_unit_system) = 'EN'
      THEN
         SELECT a.unit_id
           INTO l_default_units
           FROM cwms_unit a, cwms_base_parameter b
          WHERE a.unit_code = b.display_unit_code_en
                AND b.base_parameter_code = l_base_param_code;
      ELSE
         cwms_err.raise ('INVALID_ITEM',
                         p_unit_system,
                         'Unit System. Use either SI or EN');
      END IF;

      RETURN l_default_units;
   END get_default_units;

   FUNCTION get_db_unit_code (p_parameter_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_unit_code   NUMBER (10);
   BEGIN
      SELECT unit_code
        INTO l_unit_code
        FROM cwms_base_parameter
       WHERE base_parameter_id = get_base_id (p_parameter_id);

      RETURN l_unit_code;
   END get_db_unit_code;

   FUNCTION get_db_unit_code (p_parameter_code IN NUMBER)
      RETURN NUMBER
   IS
      l_unit_code   NUMBER (10);
   BEGIN
      SELECT bp.unit_code
        INTO l_unit_code
        FROM cwms_base_parameter bp, at_parameter p
       WHERE p.parameter_code = p_parameter_code
             AND bp.base_parameter_code = p.base_parameter_code;

      RETURN l_unit_code;
   END get_db_unit_code;

   FUNCTION convert_to_db_units (p_value          IN BINARY_DOUBLE,
                                 p_parameter_id   IN VARCHAR2,
                                 p_unit_id        IN VARCHAR2)
      RETURN BINARY_DOUBLE
   IS
      l_factor   BINARY_DOUBLE;
      l_offset   BINARY_DOUBLE;
   BEGIN
      SELECT uc.factor, uc.offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion uc, cwms_base_parameter bp
       WHERE     bp.base_parameter_id = get_base_id (p_parameter_id)
             AND uc.to_unit_code = bp.unit_code
             AND uc.from_unit_id = p_unit_id;

      RETURN p_value * l_factor + l_offset;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot convert parameter '
            || p_parameter_id
            || ' in unit '
            || p_unit_id
            || ' to database unit.');
   END convert_to_db_units;

   FUNCTION get_factor_and_offset (p_from_unit_id   IN VARCHAR2,
                                   p_to_unit_id     IN VARCHAR2)
      RETURN double_tab_t
      RESULT_CACHE
   IS
      l_factor_and_offset   double_tab_t := double_tab_t ();
   BEGIN
      l_factor_and_offset.EXTEND (2);

      SELECT factor, offset
        INTO l_factor_and_offset (1), l_factor_and_offset (2)
        FROM cwms_unit_conversion
       WHERE from_unit_id = get_unit_id (p_from_unit_id)
             AND to_unit_id = get_unit_id (p_to_unit_id);

      RETURN l_factor_and_offset;
   END get_factor_and_offset;

   FUNCTION convert_units (p_value          IN BINARY_DOUBLE,
                           p_from_unit_id   IN VARCHAR2,
                           p_to_unit_id     IN VARCHAR2)
      RETURN BINARY_DOUBLE
      RESULT_CACHE
   IS
      l_factor_and_offset   double_tab_t;
   BEGIN
      l_factor_and_offset :=
         get_factor_and_offset (p_from_unit_id, p_to_unit_id);
      RETURN p_value * l_factor_and_offset (1) + l_factor_and_offset (2);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot convert from unit '
            || p_from_unit_id
            || ' to unit '
            || p_to_unit_id);
   END convert_units;

   FUNCTION convert_units (p_value            IN BINARY_DOUBLE,
                           p_from_unit_code   IN NUMBER,
                           p_to_unit_code     IN NUMBER)
      RETURN BINARY_DOUBLE
      RESULT_CACHE
   IS
      l_factor   BINARY_DOUBLE;
      l_offset   BINARY_DOUBLE;
   BEGIN
      SELECT factor, offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion
       WHERE from_unit_code = p_from_unit_code
             AND to_unit_code = p_to_unit_code;

      RETURN p_value * l_factor + l_offset;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot convert from unit '
            || get_unit_id2 (p_from_unit_code)
            || ' to unit '
            || get_unit_id2 (p_to_unit_code));
   END convert_units;

   FUNCTION convert_units (p_value            IN BINARY_DOUBLE,
                           p_from_unit_code   IN NUMBER,
                           p_to_unit_id       IN VARCHAR2)
      RETURN BINARY_DOUBLE
      RESULT_CACHE
   IS
      l_factor   BINARY_DOUBLE;
      l_offset   BINARY_DOUBLE;
   BEGIN
      SELECT factor, offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion
       WHERE from_unit_code = p_from_unit_code
             AND to_unit_id = get_unit_id (p_to_unit_id);

      RETURN p_value * l_factor + l_offset;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot convert from unit '
            || get_unit_id2 (p_from_unit_code)
            || ' to unit '
            || p_to_unit_id);
   END convert_units;

   FUNCTION convert_units (p_value          IN BINARY_DOUBLE,
                           p_from_unit_id   IN VARCHAR2,
                           p_to_unit_code   IN NUMBER)
      RETURN BINARY_DOUBLE
      RESULT_CACHE
   IS
      l_factor   BINARY_DOUBLE;
      l_offset   BINARY_DOUBLE;
   BEGIN
      SELECT factor, offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion
       WHERE from_unit_id = get_unit_id (p_from_unit_id)
             AND to_unit_code = p_to_unit_code;

      RETURN p_value * l_factor + l_offset;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot convert from unit '
            || p_from_unit_id
            || ' to unit '
            || get_unit_id2 (p_to_unit_code));
   END convert_units;

   --
   -- sign-extends 32-bit integers so they can be retrieved by
   -- java int type
   --

   FUNCTION sign_extend (p_int IN INTEGER)
      RETURN INTEGER
   IS
   BEGIN
      DBMS_OUTPUT.put_line (
         'Warning: Use of CWMS_UTIL.SIGN_EXTEND is deprecated');
      RETURN p_int;
   END sign_extend;

   -----------------------------------
   -- function months_to_yminterval --
   -----------------------------------

   FUNCTION months_to_yminterval (p_months IN INTEGER)
      RETURN INTERVAL YEAR TO MONTH
   IS
   BEGIN
      IF p_months IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_YMINTERVAL (
                   TO_CHAR (TRUNC (p_months / 12))
                || '-'
                || TO_CHAR (MOD (p_months, 12)));
   END months_to_yminterval;

   ------------------------------------
   -- function minutes_to_dsinterval --
   ------------------------------------

   FUNCTION minutes_to_dsinterval (p_minutes IN INTEGER)
      RETURN INTERVAL DAY TO SECOND
   IS
   BEGIN
      IF p_minutes IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_DSINTERVAL (
                   TO_CHAR (TRUNC (p_minutes / 1440))
                || ' '
                || TO_CHAR (TRUNC (MOD (p_minutes, 1440) / 60))
                || ':'
                || TO_CHAR (MOD (p_minutes, 60) || ': 00'));
   END minutes_to_dsinterval;

   -----------------------------------
   -- function yminterval_to_months --
   -----------------------------------

   FUNCTION yminterval_to_months (p_intvl IN yminterval_unconstrained)
      RETURN INTEGER
   IS
   BEGIN
      IF p_intvl IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN 12 * EXTRACT (YEAR FROM p_intvl) + EXTRACT (MONTH FROM p_intvl);
   END yminterval_to_months;

   ------------------------------------
   -- function dsinterval_to_minutes --
   ------------------------------------

   FUNCTION dsinterval_to_minutes (p_intvl IN dsinterval_unconstrained)
      RETURN INTEGER
   IS
   BEGIN
      IF p_intvl IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN   1440 * EXTRACT (DAY FROM p_intvl)
             + 60 * EXTRACT (HOUR FROM p_intvl)
             + EXTRACT (MINUTE FROM p_intvl);
   END dsinterval_to_minutes;

   ----------------------------------
   -- function minutes_to_duration --
   ----------------------------------

   function minutes_to_duration (
      p_minutes in integer)
      return varchar2
   is
      l_duration varchar2(16);
      l_dsintvl  dsinterval_unconstrained;
      l_days     integer;
      l_hours    integer;
      l_minutes  integer;
   begin
      if p_minutes is not null then
         l_duration := 'P';
         l_dsintvl  := minutes_to_dsinterval(p_minutes);
         l_days     := extract(day from l_dsintvl);
         l_hours    := extract(hour from l_dsintvl);
         l_minutes  := extract(minute from l_dsintvl);
         if l_days > 0 then
            l_duration := l_duration || l_days || 'D';
         end if;
         if l_hours + l_minutes > 0 then
            l_duration := l_duration || 'T';
         end if;
         if l_hours > 0 then
            l_duration := l_duration || l_hours || 'H';
         end if;
         if l_minutes > 0 or l_days + l_hours = 0 then
            l_duration := l_duration || l_minutes || 'M';
         end if;
      end if;                      
      return l_duration;
   end minutes_to_duration;

   ----------------------------------
   -- function duration_to_minutes --
   ----------------------------------

   function duration_to_minutes(
      p_duration in varchar2)
      return integer
   is
      --                                     1      2      3      4 5      6      7   8
      l_pattern constant varchar2(128) := '^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+([.]\d+)?S)?)?$';
      l_duration varchar2(64) := trim(p_duration);
      l_text    varchar2(8);        
      l_minutes integer;
   begin                                                                                     
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 0) is null then
         cwms_err.raise('INVALID_ITEM', l_duration, 'ISO 8601 duration');
      end if;                                             
      for i in 1..2 loop
         if regexp_substr(l_duration, l_pattern, 1, 1, 'i', i) is not null then
            l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', i);
            if to_number(substr(l_text, 1, length(l_text)-1)) > 0 then
               cwms_err.raise('ERROR', 'Cannont compute minutes. Duration "'||l_duration||'" contains years and/or months');
            end if;
         end if;
      end loop;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 7) is not null then
            l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 7);
            if to_number(substr(l_text, 1, length(l_text)-1)) > 0 then
               cwms_err.raise('ERROR', 'Cannont compute minutes. Duration "'||l_duration||'" contains seconds');
            end if;
      end if;
      l_minutes := 0;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 3) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 3);
         l_minutes := l_minutes + 1440 * to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 5) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 5);
         l_minutes := l_minutes + 60 * to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 6) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 6);
         l_minutes := l_minutes + to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      return l_minutes;
   end duration_to_minutes;      

   -----------------------------------
   -- function parse_odbc_ts_string --
   -----------------------------------

   FUNCTION parse_odbc_ts_string (p_odbc_str IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      IF p_odbc_str IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_DATE (p_odbc_str, odbc_ts_fmt);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_odbc_str,
                         'ODBC timestamp format (' || odbc_ts_fmt || ')');
   END parse_odbc_ts_string;

   ----------------------------------
   -- function parse_odbc_d_string --
   ----------------------------------

   FUNCTION parse_odbc_d_string (p_odbc_str IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      IF p_odbc_str IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_DATE (p_odbc_str, odbc_d_fmt);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_odbc_str,
                         'ODBC date format (' || odbc_d_fmt || ')');
   END parse_odbc_d_string;

   ----------------------------------------
   -- function parse_odbc_ts_or_d_string --
   ----------------------------------------

   FUNCTION parse_odbc_ts_or_d_string (p_odbc_str IN VARCHAR2)
      RETURN DATE
   IS
      l_date   DATE;
   BEGIN
      IF p_odbc_str IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_date := parse_odbc_ts_string (p_odbc_str);
      RETURN l_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            l_date := parse_odbc_d_string (p_odbc_str);
            RETURN l_date;
         EXCEPTION
            WHEN OTHERS
            THEN
               cwms_err.raise (
                  'INVALID_ITEM',
                  p_odbc_str,
                     'ODBC timestamp or date format ('
                  || odbc_ts_fmt
                  || ', '
                  || ')');
         END;
   END parse_odbc_ts_or_d_string;

   FUNCTION is_expression_constant (p_token IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count   INTEGER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM DUAL
       WHERE p_token IN (SELECT * FROM TABLE (expression_constants));

      RETURN l_count > 0;
   END is_expression_constant;

   FUNCTION is_expression_operator (p_token IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count   INTEGER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM DUAL
       WHERE p_token IN (SELECT * FROM TABLE (expression_operators));

      RETURN l_count > 0;
   END is_expression_operator;

   FUNCTION is_expression_function (p_token IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count   INTEGER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM DUAL
       WHERE p_token IN (SELECT * FROM TABLE (expression_functions));

      RETURN l_count > 0;
   END is_expression_function;

   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_algebraic
   --
   -- Returns a table of RPN tokens for a specified algebraic expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --           ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   -----------------------------------------------------------------------------

   FUNCTION tokenize_algebraic (p_algebraic_expr IN VARCHAR2)
      RETURN str_tab_t
      RESULT_CACHE
   IS
      l_infix_tokens        str_tab_t;
      l_postfix_tokens      str_tab_t := NEW str_tab_t ();
      l_stack               str_tab_t := NEW str_tab_t ();
      l_func_stack          str_tab_t := NEW str_tab_t ();
      l_left_paren_count    BINARY_INTEGER := 0;
      l_right_paren_count   BINARY_INTEGER := 0;
      l_func                VARCHAR2 (8);
      l_dummy               VARCHAR2 (1);

      PROCEDURE error
      IS
      BEGIN
         cwms_err.raise (
            'ERROR',
            'Invalid algebraic expression: ' || p_algebraic_expr);
      END;

      PROCEDURE token_error (token IN VARCHAR2)
      IS
      BEGIN
         cwms_err.raise ('ERROR', 'Invalid token in equation: ' || token);
      END;

      FUNCTION precedence (op IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         RETURN CASE op
                   WHEN '+' THEN 1
                   WHEN '-' THEN 1
                   WHEN '*' THEN 2
                   WHEN '/' THEN 2
                   WHEN '//' THEN 2
                   WHEN '%' THEN 2
                   WHEN '^' THEN 3
                END;
      END;

      PROCEDURE push (p_op IN VARCHAR2)
      IS
      BEGIN
         l_stack.EXTEND;
         l_stack (l_stack.COUNT) := p_op;
      END;

      FUNCTION pop
         RETURN VARCHAR2
      IS
         l_op   VARCHAR2 (8);
      BEGIN
         BEGIN
            l_op := l_stack (l_stack.COUNT);
         EXCEPTION
            WHEN OTHERS
            THEN
               error;
         END;

         l_stack.TRIM;
         RETURN l_op;
      END;

      PROCEDURE push_func (p_func IN VARCHAR2)
      IS
      BEGIN
         l_func_stack.EXTEND;
         l_func_stack (l_func_stack.COUNT) := p_func;
      END;

      FUNCTION pop_func
         RETURN VARCHAR2
      IS
         l_func   VARCHAR2 (8);
      BEGIN
         BEGIN
            l_func := l_func_stack (l_func_stack.COUNT);
         EXCEPTION
            WHEN OTHERS
            THEN
               error;
         END;

         l_func_stack.TRIM;
         RETURN l_func;
      END;
   BEGIN
      ---------------------------------
      -- parse the infix into tokens --
      ---------------------------------
      l_infix_tokens :=
         cwms_util.split_text (
            TRIM (
               REGEXP_REPLACE (
                  UPPER (REPLACE (p_algebraic_expr, CHR (10), ' ')),
                  '([()])',
                  ' \1 ')));

      -------------------------------------
      -- process the tokens into postfix --
      -------------------------------------
      FOR i IN 1 .. l_infix_tokens.COUNT
      LOOP
         CASE
            ---------------
            -- operators --
            ---------------
            WHEN is_expression_operator (l_infix_tokens (i))
            THEN
               IF l_stack.COUNT > 0
                  AND precedence (l_stack (l_stack.COUNT)) >=
                         precedence (l_infix_tokens (i))
               THEN
                  l_postfix_tokens.EXTEND;
                  l_postfix_tokens (l_postfix_tokens.COUNT) := pop;
               END IF;

               push (l_infix_tokens (i));
            ---------------
            -- functions --
            ---------------
            WHEN is_expression_function (l_infix_tokens (i))
            THEN
               push_func (l_infix_tokens (i));
            ----------------------
            -- open parentheses --
            ----------------------
            WHEN l_infix_tokens (i) = '('
            THEN
               push (NULL);
               push_func (NULL);
               l_left_paren_count := l_left_paren_count + 1;
            ------------------------
            -- close parentheses --
            ------------------------
            WHEN l_infix_tokens (i) = ')'
            THEN
               WHILE l_stack (l_stack.COUNT) IS NOT NULL
               LOOP
                  l_postfix_tokens.EXTEND;
                  l_postfix_tokens (l_postfix_tokens.COUNT) := pop;
               END LOOP;

               l_dummy := pop;
               l_func := pop_func;

               IF l_func_stack.COUNT > 0
                  AND l_func_stack (l_func_stack.COUNT) IS NOT NULL
               THEN
                  l_func := pop_func;
                  l_postfix_tokens.EXTEND;
                  l_postfix_tokens (l_postfix_tokens.COUNT) := l_func;
               END IF;

               l_right_paren_count := l_right_paren_count + 1;
            ---------------------
            -- everything else --
            ---------------------
            ELSE
               l_postfix_tokens.EXTEND;
               l_postfix_tokens (l_postfix_tokens.COUNT) := l_infix_tokens (i);
         END CASE;
      END LOOP;

      IF l_right_paren_count != l_left_paren_count
      THEN
         error;
      END IF;

      WHILE l_stack.COUNT > 0
      LOOP
         l_postfix_tokens.EXTEND;
         l_postfix_tokens (l_postfix_tokens.COUNT) := pop;
      END LOOP;

      RETURN l_postfix_tokens;
   END tokenize_algebraic;

   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_RPN
   --
   -- Returns a table of RPN tokens for a specified delimited RPN expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --           ln, log, sign, sin, tan, trunc
   --
   -- All numbers, arguments and operators must be separated by whitespace
   -----------------------------------------------------------------------------

   FUNCTION tokenize_rpn (p_rpn_expr IN VARCHAR2)
      RETURN str_tab_t
      RESULT_CACHE
   IS
   BEGIN
      RETURN split_text (TRIM (UPPER (REPLACE (p_rpn_expr, CHR (10), ' '))));
   END tokenize_rpn;

   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_expression
   --
   -- Returns a table of RPN tokens for a specified algebraic or RPN expression
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --           ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   -----------------------------------------------------------------------------

   FUNCTION tokenize_expression (p_expr IN VARCHAR2)
      RETURN str_tab_t
      RESULT_CACHE
   IS
      l_tokens   str_tab_t;
      l_count    INTEGER := 0;
   BEGIN
      IF INSTR (p_expr, '(') > 0
      THEN
         -----------------------------------------------------
         -- must be algebraic, rpn doesn't have parentheses --
         -----------------------------------------------------
         l_tokens := tokenize_algebraic (p_expr);
      ELSE
         -------------------
         -- first try rpn --
         -------------------
         l_tokens := tokenize_rpn (p_expr);

         IF     l_tokens.COUNT > 0
            AND NOT is_expression_operator (l_tokens (l_tokens.COUNT))
            AND NOT is_expression_function (l_tokens (l_tokens.COUNT))
         THEN
            -----------------------------------------------------------------
            -- last token isn't an operator or function, must be algebraic --
            -----------------------------------------------------------------
            l_tokens := tokenize_algebraic (p_expr);
         END IF;
      END IF;

      RETURN l_tokens;
   END tokenize_expression;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_expression
   --
   -- Returns the result of evaluating RPN tokens against specified arguments
   --
   -- The tokens are not case sensitive
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------

   FUNCTION eval_tokenized_expression (p_rpn_tokens    IN str_tab_t,
                                       p_args          IN double_tab_t,
                                       p_args_offset   IN INTEGER DEFAULT 0)
      RETURN NUMBER
   IS
      l_stack   number_tab_t := NEW number_tab_t ();
      l_val1    BINARY_DOUBLE;
      l_val2    BINARY_DOUBLE;
      l_idx     BINARY_INTEGER;

      PROCEDURE token_error (token IN VARCHAR2)
      IS
      BEGIN
         cwms_err.raise ('ERROR', 'Invalid token in equation: ' || token);
      END;

      PROCEDURE argument_error (l_idx IN INTEGER)
      IS
      BEGIN
         cwms_err.raise ('ERROR', 'ARG' || l_idx || ' does not exist');
      END;

      PROCEDURE push (val IN NUMBER)
      IS
      BEGIN
         l_stack.EXTEND;
         l_stack (l_stack.COUNT) := val;
      -- dbms_output.put_line('pushed '||val);
      END;

      FUNCTION pop
         RETURN NUMBER
      IS
         val   NUMBER;
      BEGIN
         val := l_stack (l_stack.LAST);
         l_stack.TRIM;
         -- dbms_output.put_line('popped '||val);
         RETURN val;
      END;
   BEGIN
      FOR i IN 1 .. p_rpn_tokens.COUNT
      LOOP
         -- dbms_output.put_line('token('||i||') = '||p_RPN_tokens(i));
         CASE
            ---------------
            -- operators --
            ---------------
            WHEN p_rpn_tokens (i) = '+'
            THEN
               push (pop + pop);
            WHEN p_rpn_tokens (i) = '-'
            THEN
               push (-pop + pop);
            WHEN p_rpn_tokens (i) = '*'
            THEN
               push (pop * pop);
            WHEN p_rpn_tokens (i) = '/'
            THEN
               l_val2 := NULLIF (pop, 0);
               l_val1 := pop;
               push (l_val1 / l_val2);
            WHEN p_rpn_tokens (i) = '//'
            THEN                                             -- same as Python
               l_val2 := NULLIF (pop, 0);
               l_val1 := pop;
               push (FLOOR (l_val1 / l_val2));
            WHEN p_rpn_tokens (i) = '%'
            THEN                            -- same as Python math.fmod, not %
               l_val2 := NULLIF (pop, 0);
               l_val1 := pop;
               push (MOD (l_val1, l_val2));
            WHEN p_rpn_tokens (i) = '^'
            THEN
               l_val2 := pop;
               l_val1 := pop;
               push (POWER (l_val1, l_val2));
            ---------------
            -- constants --
            ---------------
            WHEN p_rpn_tokens (i) = 'E'
            THEN
               push (2.7182818284590451);
            WHEN p_rpn_tokens (i) = 'PI'
            THEN
               push (3.1415926535897931);
            ---------------------
            -- unary functions --
            ---------------------
            WHEN p_rpn_tokens (i) = 'ABS'
            THEN
               push (ABS (pop));
            WHEN p_rpn_tokens (i) = 'ACOS'
            THEN
               push (ACOS (pop));
            WHEN p_rpn_tokens (i) = 'ASIN'
            THEN
               push (ASIN (pop));
            WHEN p_rpn_tokens (i) = 'ATAN'
            THEN
               push (ATAN (pop));
            WHEN p_rpn_tokens (i) = 'CEIL'
            THEN
               push (CEIL (pop));
            WHEN p_rpn_tokens (i) = 'COS'
            THEN
               push (COS (pop));
            WHEN p_rpn_tokens (i) = 'EXP'
            THEN
               push (EXP (pop));
            WHEN p_rpn_tokens (i) = 'FLOOR'
            THEN
               push (FLOOR (pop));
            WHEN p_rpn_tokens (i) = 'INV'
            THEN
               push (1 / pop);
            WHEN p_rpn_tokens (i) = 'LN'
            THEN
               push (LN (pop));
            WHEN p_rpn_tokens (i) = 'LOG'
            THEN                                                -- log base 10
               push (LOG (10, pop));
            WHEN p_rpn_tokens (i) = 'NEG'
            THEN
               push (pop * -1);
            WHEN p_rpn_tokens (i) = 'ROUND'
            THEN
               push (ROUND (pop));
            WHEN p_rpn_tokens (i) = 'SIGN'
            THEN                             -- not SQL sign, but +1, 0, or -1
               l_val1 := pop;

               CASE
                  WHEN l_val1 < 0
                  THEN
                     push (-1);
                  WHEN l_val1 > 0
                  THEN
                     push (1);
                  ELSE
                     push (0);
               END CASE;
            WHEN p_rpn_tokens (i) = 'SIN'
            THEN
               push (SIN (pop));
            WHEN p_rpn_tokens (i) = 'SQRT'
            THEN
               push (SQRT (pop));
            WHEN p_rpn_tokens (i) = 'TAN'
            THEN
               push (TAN (pop));
            WHEN p_rpn_tokens (i) = 'TRUNC'
            THEN
               push (TRUNC (pop));
            ---------------
            -- arguments --
            ---------------
            WHEN SUBSTR (p_rpn_tokens (i), 1, 3) = 'ARG'
            THEN
               BEGIN
                  l_idx :=
                     TO_NUMBER (SUBSTR (p_rpn_tokens (i), 4)) + p_args_offset;

                  IF l_idx < 1 OR l_idx > p_args.COUNT
                  THEN
                     argument_error (l_idx - p_args_offset);
                  END IF;

                  IF p_args (l_idx) IS NULL
                  THEN
                     RETURN NULL;
                  END IF;

                  push (p_args (l_idx));
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     token_error (p_rpn_tokens (i));
               END;
            WHEN SUBSTR (p_rpn_tokens (i), 1, 4) = '-ARG'
            THEN
               BEGIN
                  l_idx := TO_NUMBER (SUBSTR (p_rpn_tokens (i), 5));

                  IF l_idx < 1 OR l_idx > p_args.COUNT
                  THEN
                     argument_error (l_idx - p_args_offset);
                  END IF;

                  IF p_args (l_idx) IS NULL
                  THEN
                     RETURN NULL;
                  END IF;

                  push (p_args (l_idx));
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     token_error (p_rpn_tokens (i));
               END;
            -------------
            -- numbers --
            -------------
            ELSE
               BEGIN
                  push (TO_NUMBER (p_rpn_tokens (i)));
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     token_error (p_rpn_tokens (i));
               END;
         END CASE;
      END LOOP;

      IF l_stack.COUNT != 1
      THEN
         cwms_err.raise ('ERROR', 'Remaining items on stack');
      END IF;

      RETURN pop;
   END eval_tokenized_expression;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_algebraic_expression
   --
   -- Returns the result of evaluating an algebraic expression against specified
   -- arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --           ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------

   FUNCTION eval_algebraic_expression (
      p_algebraic_expr   IN VARCHAR2,
      p_args             IN double_tab_t,
      p_args_offset      IN INTEGER DEFAULT 0)
      RETURN NUMBER
   IS
   BEGIN
      RETURN eval_tokenized_expression (
                tokenize_algebraic (p_algebraic_expr),
                p_args,
                p_args_offset);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise (
            'ERROR',
            'Invalid algebraic expression: ' || p_algebraic_expr);
   END eval_algebraic_expression;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_RPN_expression
   --
   -- Returns the result of evaluating a delimited RPN expression against
   -- specified arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --           ln, log, sign, sin, tan, trunc
   --
   -- All numbers, arguments and operators must be separated by whitespace
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------

   FUNCTION eval_rpn_expression (p_rpn_expr      IN VARCHAR2,
                                 p_args          IN double_tab_t,
                                 p_args_offset   IN INTEGER DEFAULT 0)
      RETURN NUMBER
   IS
   BEGIN
      RETURN eval_tokenized_expression (tokenize_rpn (p_rpn_expr),
                                        p_args,
                                        p_args_offset);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise ('ERROR', 'Invalid RPN expression: ' || p_rpn_expr);
   END eval_rpn_expression;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_expression
   --
   -- Returns the result of evaluating an algebraic or RPN expression against
   -- specified arguments
   --
   -- The expression is not case sensitive
   --
   -- The operators supported are +, -, *, /, //, %, and ^
   --
   -- The constants supported are pi and e
   --
   -- The functions supported are abs, acos, asin, atan, ceil, cos, exp, floor,
   --           ln, log, sign, sin, tan, trunc
   --
   -- Standard operator precedence (order of operations) applies and can be
   -- overridden by parentheses
   --
   -- All numbers, arguments and operators must be separated by whitespace,
   -- except than no space is required adjacent to parentheses
   --
   -- Arguments are specified as arg1, arg2, etc...  Negated arguments (-arg1)
   -- are accepted
   --
   -- p_args_offset is the offset into the args table for arg1
   -----------------------------------------------------------------------------

   FUNCTION eval_expression (p_expr          IN VARCHAR2,
                             p_args          IN double_tab_t,
                             p_args_offset   IN INTEGER DEFAULT 0)
      RETURN NUMBER
   IS
      l_tokens   str_tab_t;
   BEGIN
      l_tokens := tokenize_expression (p_expr);
      RETURN eval_tokenized_expression (l_tokens, p_args, p_args_offset);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise ('ERROR', 'Invalid expression: ' || p_expr);
   END eval_expression;


   ---------------------
   -- Append routines --
   ---------------------

   PROCEDURE append (p_dst IN OUT NOCOPY CLOB, p_src IN CLOB)
   IS
   BEGIN
      DBMS_LOB.append (p_dst, p_src);
   END append;

   PROCEDURE append (p_dst IN OUT NOCOPY CLOB, p_src IN VARCHAR2)
   IS
   BEGIN
      DBMS_LOB.writeappend (p_dst, LENGTH (p_src), p_src);
   END append;

   PROCEDURE append (p_dst IN OUT NOCOPY CLOB, p_src IN XMLTYPE)
   IS
      l_src   CLOB := p_src.getclobval;
   BEGIN
      append (p_dst, l_src);
   END append;

   PROCEDURE append (p_dst IN OUT NOCOPY XMLTYPE, p_src IN CLOB)
   IS
      l_dst   CLOB := p_dst.getclobval;
   BEGIN
      append (l_dst, p_src);
      p_dst := xmltype (l_dst);
   END append;

   PROCEDURE append (p_dst IN OUT NOCOPY XMLTYPE, p_src IN VARCHAR2)
   IS
      l_dst   CLOB := p_dst.getclobval;
   BEGIN
      append (l_dst, p_src);
      p_dst := xmltype (l_dst);
   END append;

   PROCEDURE append (p_dst IN OUT NOCOPY XMLTYPE, p_src IN XMLTYPE)
   IS
      l_dst   CLOB := p_dst.getclobval;
   BEGIN
      append (l_dst, p_src);
      p_dst := xmltype (l_dst);
   END append;

   --------------------------
   -- XML Utility routines --
   --------------------------

   FUNCTION get_xml_node (p_xml IN XMLTYPE, p_path IN VARCHAR)
      RETURN XMLTYPE
   IS
   BEGIN
      RETURN CASE p_xml IS NULL OR p_path IS NULL
                WHEN TRUE THEN NULL
                WHEN FALSE THEN p_xml.EXTRACT (p_path)
             END;
   END get_xml_node;

   FUNCTION get_xml_text (p_xml IN XMLTYPE, p_path IN VARCHAR)
      RETURN VARCHAR2
   IS
      l_xml    XMLTYPE;
      l_text   VARCHAR2 (32767);
   BEGIN
      l_xml := get_xml_node (p_xml, p_path);

      IF l_xml IS NULL
      THEN
         RETURN NULL;
      ELSE
         l_text := l_xml.getstringval;

         IF INSTR (p_path, '/@') = 0
         THEN
            l_xml := l_xml.EXTRACT ('/node()/text()');
         END IF;
      END IF;

      IF l_xml IS NULL
      THEN
         RETURN NULL;
      ELSE
         l_text :=
            REGEXP_REPLACE (REGEXP_REPLACE (l_xml.getstringval, '^\s+'),
                            '\s+$');
         RETURN l_text;
      END IF;
   END get_xml_text;

   FUNCTION get_xml_number (p_xml IN XMLTYPE, p_path IN VARCHAR)
      RETURN NUMBER
   IS
   BEGIN
      RETURN TO_NUMBER (get_xml_text (p_xml, p_path));
   END get_xml_number;


   FUNCTION x_minus_y (p_list_1      IN VARCHAR2,
                       p_list_2      IN VARCHAR2,
                       p_separator   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_list_1   str_tab_t;
      l_list_2   str_tab_t;
      l_list_3   str_tab_t;
   BEGIN
      l_list_1 := split_text (p_text => p_list_1, p_separator => p_separator);
      l_list_2 := split_text (p_text => p_list_2, p_separator => p_separator);

      SELECT *
        BULK COLLECT INTO l_list_3
        FROM (SELECT * FROM TABLE (l_list_1)
              MINUS
              SELECT * FROM TABLE (l_list_2));

      RETURN cwms_util.join_text (p_text_tab    => l_list_3,
                                  p_separator   => p_separator);
   END x_minus_y;


   PROCEDURE set_boolean_state (p_name IN VARCHAR2, p_state IN BOOLEAN)
   IS
   BEGIN
      set_boolean_state (
         p_name,
         CASE p_state WHEN TRUE THEN 'T' WHEN FALSE THEN 'F' END);
   END set_boolean_state;

   PROCEDURE set_boolean_state (p_name IN VARCHAR2, p_state IN CHAR)
   IS
      l_name   VARCHAR2 (64);
   BEGIN
      SELECT name
        INTO l_name
        FROM at_boolean_state
       WHERE UPPER (name) = UPPER (p_name);

      UPDATE at_boolean_state
         SET state = p_state
       WHERE name = l_name;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO at_boolean_state
              VALUES (p_name, p_state);
   END set_boolean_state;

   FUNCTION get_boolean_state_char (p_name IN VARCHAR2)
      RETURN CHAR
   IS
      l_state   CHAR (1);
   BEGIN
      BEGIN
         SELECT state
           INTO l_state
           FROM at_boolean_state
          WHERE UPPER (name) = UPPER (p_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      RETURN l_state;
   END get_boolean_state_char;

   FUNCTION get_boolean_state (p_name IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_state   CHAR (1);
   BEGIN
      l_state := get_boolean_state_char (p_name);
      RETURN CASE l_state IS NULL WHEN TRUE THEN NULL ELSE l_state = 'T' END;
   END get_boolean_state;

   PROCEDURE set_session_info (p_item_name   IN VARCHAR2,
                               p_txt_value   IN VARCHAR2,
                               p_num_value   IN NUMBER)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------------
      -- insert/update the table --
      -----------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      MERGE INTO at_session_info t
           USING (SELECT l_item_name AS item_name FROM DUAL) d
              ON (t.item_name = d.item_name)
      WHEN MATCHED
      THEN
         UPDATE SET str_value = p_txt_value, num_value = p_num_value
      WHEN NOT MATCHED
      THEN
         INSERT     VALUES (l_item_name, p_txt_value, p_num_value);
   END set_session_info;

   PROCEDURE set_session_info (p_item_name   IN VARCHAR2,
                               p_txt_value   IN VARCHAR2)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------------
      -- insert/update the table --
      -----------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      MERGE INTO at_session_info t
           USING (SELECT l_item_name AS item_name FROM DUAL) d
              ON (t.item_name = d.item_name)
      WHEN MATCHED
      THEN
         UPDATE SET str_value = p_txt_value
      WHEN NOT MATCHED
      THEN
         INSERT     VALUES (l_item_name, p_txt_value, NULL);
   END set_session_info;

   PROCEDURE set_session_info (p_item_name   IN VARCHAR2,
                               p_num_value   IN NUMBER)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------------
      -- insert/update the table --
      -----------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      MERGE INTO at_session_info t
           USING (SELECT l_item_name AS item_name FROM DUAL) d
              ON (t.item_name = d.item_name)
      WHEN MATCHED
      THEN
         UPDATE SET num_value = p_num_value
      WHEN NOT MATCHED
      THEN
         INSERT     VALUES (l_item_name, NULL, p_num_value);
   END set_session_info;

   PROCEDURE get_session_info (p_txt_value      OUT VARCHAR2,
                               p_num_value      OUT NUMBER,
                               p_item_name   IN     VARCHAR2)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -------------------------
      -- retrieve the values --
      -------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      BEGIN
         SELECT str_value, num_value
           INTO p_txt_value, p_num_value
           FROM at_session_info
          WHERE item_name = l_item_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;
   END get_session_info;

   FUNCTION get_session_info_txt (p_item_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_txt_value   VARCHAR2 (256);
      l_num_value   NUMBER;
   BEGIN
      get_session_info (l_txt_value, l_num_value, p_item_name);

      RETURN l_txt_value;
   END get_session_info_txt;

   FUNCTION get_session_info_num (p_item_name IN VARCHAR2)
      RETURN NUMBER
   IS
      l_txt_value   VARCHAR2 (256);
      l_num_value   NUMBER;
   BEGIN
      get_session_info (l_txt_value, l_num_value, p_item_name);

      RETURN l_num_value;
   END get_session_info_num;

   PROCEDURE reset_session_info (p_item_name IN VARCHAR2)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------
      -- delete the record --
      -----------------------
      l_item_name := UPPER (TRIM (p_item_name));

      BEGIN
         DELETE FROM at_session_info
               WHERE item_name = l_item_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;
   END reset_session_info;

   FUNCTION is_nan (p_value IN BINARY_DOUBLE)
      RETURN VARCHAR2
   IS
      l_is_nan   BOOLEAN := p_value IS NAN;
   BEGIN
      RETURN CASE l_is_nan WHEN TRUE THEN 'T' ELSE 'F' END;
   END is_nan;

      
   function parse_unit_spec(
      p_unit_spec in varchar2,
      p_key       in varchar2)
      return varchar2
   is
      l_parts1 str_tab_t;
      l_parts2 str_tab_t;
      l_parsed varchar2(16);
      l_key    varchar2(1) := upper(trim(p_key));
      begin
      l_parts1 := split_text(p_unit_spec, '|');
      for i in 1..l_parts1.count loop
         l_parts2 := split_text(trim(l_parts1(i)), '=');
         if l_parts2.count = 2 and upper(trim(l_parts2(1))) = l_key then
            l_parsed := trim(l_parts2(2));
            exit;
         end if;
      end loop;
      return l_parsed;
   end parse_unit_spec;

   function parse_unit(
      p_unit_spec in varchar2)
      return varchar2
   is
   begin
      if instr(p_unit_spec, '=') > 0 then
         return parse_unit_spec(p_unit_spec, 'U');
      else
         return p_unit_spec;
      end if;
   end parse_unit;

   function parse_vertical_datum(
      p_unit_spec in varchar2)
      return varchar2
   is
   begin
      return parse_unit_spec(p_unit_spec, 'V');
   end parse_vertical_datum;

   function get_effective_vertical_datum(
      p_unit_spec in varchar2)
      return varchar2
   is
      l_vertical_datum varchar2(16);
   begin
      l_vertical_datum := parse_vertical_datum(p_unit_spec);
      if l_vertical_datum is null then
         l_vertical_datum := cwms_loc.get_default_vertical_datum;
      end if;
      l_vertical_datum := upper(trim(l_vertical_datum));
      if l_vertical_datum = 'NULL' then
         l_vertical_datum := null;
      end if;
      return l_vertical_datum;
   end get_effective_vertical_datum;

   procedure check_dynamic_sql(
      p_sql in varchar2)
   is 
      l_sql_no_quotes varchar2(32767);

      function remove_quotes(p_text in varchar2) return varchar2
      as
         l_test varchar2(32767);
         l_result varchar2(32767);
         l_pos    pls_integer;
   begin
         l_test := p_text;
         loop
            l_pos := regexp_instr(l_test, '[''"]');
            if l_pos > 0 then
               if substr(l_test, l_pos, 1) = '"' then 
                  ------------------------
                  -- double-quote first --
                  ------------------------
                  l_result := regexp_replace(l_test, '"[^"]*?"', '#', 1, 1);
                  l_result := regexp_replace(l_result, '''[^'']*?''', '$', 1, 1);
               else
                  ------------------------
                  -- single-quote first --
                  ------------------------
                  l_result := regexp_replace(l_test, '''[^'']*?''', '$', 1, 1);
                  l_result := regexp_replace(l_result, '"[^"]*?"', '#', 1, 1);
               end if;
            else
      -----------------------
              -- no quotes in text --
      -----------------------
               l_result := l_test;
            end if;
            exit when l_result = l_test;
            l_test := l_result;
         end loop;
         return l_result;
      end;
   begin
      l_sql_no_quotes := remove_quotes(p_sql);
      if regexp_instr(l_sql_no_quotes, '([''";]|--|/\*)') > 0 then
         cwms_err.raise(
            'ERROR',
            'UNSAFE DYNAMIC SQL : '||p_sql);
      end if;
   end check_dynamic_sql;      

   
   function get_url(
      p_url     in varchar2,
      p_timeout in integer default 60)
      return clob
   is
      l_req  utl_http.req;
      l_resp utl_http.resp;
      l_buf  varchar2(32767);
      l_clob clob;
      
      procedure write_clob(p_text in varchar2)
      is
         l_len binary_integer := length(p_text);
      begin
         dbms_lob.writeappend(l_clob, l_len, p_text);
      end;
   begin       
      dbms_lob.createtemporary(l_clob, true);
      dbms_lob.open(l_clob, dbms_lob.lob_readwrite);   
   begin
         utl_http.set_transfer_timeout(p_timeout);
         l_req := utl_http.begin_request(p_url);
         utl_http.set_header(l_req, 'User-Agent', 'Mozilla/4.0');
         l_resp := utl_http.get_response(l_req);
         utl_http.set_transfer_timeout;
          loop                             
            utl_http.read_text(l_resp, l_buf);
            write_clob(l_buf);
         end loop;
      exception
         when utl_http.end_of_body then
            utl_http.end_response(l_resp);
      end;
      dbms_lob.close(l_clob);
      return l_clob;
   end get_url;      
   
   function get_column(
      p_table  in double_tab_tab_t,
      p_column in pls_integer)
      return double_tab_t
   is
      l_results double_tab_t;
      l_count   pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_table is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_table');
      end if;
      if p_column is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_column');
      end if;
      select count(*) into l_count from table(p_table) where column_value is null;
      if l_count != 0 then 
         cwms_err.raise(
            'ERROR',
            'Table has one or more null rows');
      end if;
      l_count := p_table(1).count;
      if not p_column between 1 and l_count then
         cwms_err.raise(
            'ERROR',
            'Specified column ('
            ||p_column
            ||') is not valid for a table of width '
            ||l_count);
      end if;
      select value_in_column
        bulk collect
        into l_results 
        from (select t2.column_value as value_in_column, 
                     rownum as r 
                from table(p_table) t1,
                     table(t1.column_value) t2
               where t2.column_value in (select column_value from table(t1.column_value))             
             )
             where mod(r, l_count) = mod(p_column, l_count);
      return l_results;
   end get_column;            
   
    FUNCTION str2tbl (p_str IN VARCHAR2, p_delim IN VARCHAR2 DEFAULT ',')
       RETURN str2tblType
       PIPELINED
    AS
       l_str   LONG DEFAULT p_str || p_delim;
       l_n     NUMBER;
    BEGIN
       LOOP
          l_n := INSTR (l_str, p_delim);
          EXIT WHEN (NVL (l_n, 0) = 0);
          PIPE ROW (LTRIM (RTRIM (SUBSTR (l_str, 1, l_n - 1))));
          l_str := SUBSTR (l_str, l_n + 1);
       END LOOP;

       RETURN;
    END;

   function get_column(
      p_table  in str_tab_tab_t,
      p_column in pls_integer)
      return str_tab_t
   is
      l_results str_tab_t;
      l_count   pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_table is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_table');
      end if;
      if p_column is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_column');
      end if;
      select count(*) into l_count from table(p_table) where column_value is null;
      if l_count != 0 then 
         cwms_err.raise(
            'ERROR',
            'Table has one or more null rows');
      end if;
      l_count := p_table(1).count;
      if not p_column between 1 and l_count then
         cwms_err.raise(
            'ERROR',
            'Specified column ('
            ||p_column
            ||') is not valid for a table of width '
            ||l_count);
      end if;
      select value_in_column
        bulk collect
        into l_results 
        from (select t2.column_value as value_in_column, 
                     rownum as r 
                from table(p_table) t1,
                     table(t1.column_value) t2
               where t2.column_value in (select column_value from table(t1.column_value))             
             )
             where mod(r, l_count) = mod(p_column, l_count);
      return l_results;
   end get_column;            

/*
BEGIN
 -- anything put here will be executed on every mod_plsql call
  NULL;
*/

END cwms_util;
/

SHOW ERRORS;
