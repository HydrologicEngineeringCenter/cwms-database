/* Formatted on 2007/03/05 08:02 (Formatter Plus v4.8.8) */
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
   FUNCTION min_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
      l_min_dms   NUMBER;
   BEGIN
      l_sec_dms :=
         ROUND (  (  (  ABS (p_decimal_degrees - TRUNC (p_decimal_degrees))
                      * 60.0
                     )
                   - TRUNC (  ABS (  p_decimal_degrees
                                   - TRUNC (p_decimal_degrees)
                                  )
                            * 60
                           )
                  )
                * 60.0,
                2
               );
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
   BEGIN
      l_sec_dms :=
         ROUND (  (  (  ABS (p_decimal_degrees - TRUNC (p_decimal_degrees))
                      * 60.0
                     )
                   - min_dms (p_decimal_degrees)
                  )
                * 60.0,
                2
               );

      IF l_sec_dms = 60
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
      RETURN ROUND ((ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60
                    ),
                    2
                   );
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
         SELECT dbms_assert.simple_sql_name (l_name)
           INTO l_name
           FROM DUAL;

         SELECT table_name
           INTO l_name
           FROM SYS.all_synonyms
          WHERE synonym_name = l_name
            AND owner = 'PUBLIC'
            AND table_owner = 'CWMS_20';
      EXCEPTION
         WHEN invalid_sql_name
         THEN
            cwms_err.RAISE ('INVALID_ITEM',
                            p_synonym,
                            'materialized view name'
                           );
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      RETURN l_name;
   END get_real_name;

--------------------------------------------------------------------------------
-- function pause_mv_refresh
--
   FUNCTION pause_mv_refresh (
      p_mview_name   IN   VARCHAR2,
      p_reason       IN   VARCHAR2 DEFAULT NULL
   )
      RETURN UROWID
   IS
      l_mview_name   VARCHAR2 (32);
      l_user_id      VARCHAR2 (32);
      l_rowid        UROWID        := NULL;
      l_tstamp       TIMESTAMP;
   BEGIN
      SAVEPOINT pause_mv_refresh_start;
      l_user_id := SYS_CONTEXT ('userenv', 'session_user');
      l_tstamp := SYSTIMESTAMP;
      l_mview_name := get_real_name (p_mview_name);
      LOCK TABLE at_mview_refresh_paused IN EXCLUSIVE MODE;

      INSERT INTO at_mview_refresh_paused
           VALUES (l_tstamp, l_mview_name, l_user_id, p_reason)
        RETURNING ROWID, paused_at
             INTO l_rowid, l_tstamp;

      EXECUTE IMMEDIATE    'alter materialized view '
                        || l_mview_name
                        || ' refresh on demand';

      COMMIT;
      DBMS_OUTPUT.put_line (   'MVIEW '''
                            || l_mview_name
                            || ''' on-commit refresh paused at '
                            || l_tstamp
                            || ' by '
                            || l_user_id
                            || ', reason: '
                            || p_reason
                           );
      RETURN l_rowid;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK TO pause_mv_refresh_start;
         RAISE;
   END pause_mv_refresh;

--------------------------------------------------------------------------------
-- procedure resume_mv_refresh
--
   PROCEDURE resume_mv_refresh (p_paused_handle IN UROWID)
   IS
      l_mview_name   VARCHAR2 (30);
      l_count        BINARY_INTEGER;
      l_user_id      VARCHAR2 (30);
   BEGIN
      l_user_id := SYS_CONTEXT ('userenv', 'session_user');
      SAVEPOINT resume_mv_refresh_start;
      LOCK TABLE at_mview_refresh_paused IN EXCLUSIVE MODE;

      SELECT mview_name
        INTO l_mview_name
        FROM at_mview_refresh_paused
       WHERE ROWID = p_paused_handle;

      DELETE FROM at_mview_refresh_paused
            WHERE ROWID = p_paused_handle;

      SELECT COUNT (*)
        INTO l_count
        FROM at_mview_refresh_paused
       WHERE mview_name = l_mview_name;

      IF l_count = 0
      THEN
         dbms_mview.REFRESH (l_mview_name, 'c');

         EXECUTE IMMEDIATE    'alter materialized view '
                           || l_mview_name
                           || ' refresh on commit';

         DBMS_OUTPUT.put_line (   'MVIEW '''
                               || l_mview_name
                               || ''' on-commit refresh resumed at '
                               || SYSTIMESTAMP
                               || ' by '
                               || l_user_id
                              );
      ELSE
         DBMS_OUTPUT.put_line (   'MVIEW '''
                               || l_mview_name
                               || ''' on-commit refresh not resumed at '
                               || SYSTIMESTAMP
                               || ' by '
                               || l_user_id
                               || ', paused by '
                               || l_count
                               || ' other process(es)'
                              );
      END IF;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         COMMIT;
      WHEN OTHERS
      THEN
         ROLLBACK TO resume_mv_refresh_start;
         RAISE;
   END resume_mv_refresh;

--------------------------------------------------------------------------------
-- procedure timeout_mv_refresh_paused
--
   PROCEDURE timeout_mv_refresh_paused
   IS
      TYPE ts_by_mv_t IS TABLE OF at_mview_refresh_paused.paused_at%TYPE
         INDEX BY at_mview_refresh_paused.mview_name%TYPE;

      l_abandonded_pauses   ts_by_mv_t;
      l_mview_name          at_mview_refresh_paused.mview_name%TYPE;
      l_now                 TIMESTAMP                         := SYSTIMESTAMP;
   BEGIN
      SAVEPOINT timeout_mv_rfrsh_paused_start;
      LOCK TABLE at_mview_refresh_paused IN EXCLUSIVE MODE;

      FOR rec IN (SELECT *
                    FROM at_mview_refresh_paused)
      LOOP
         IF l_now - rec.paused_at > mv_pause_timeout_interval
         THEN
            IF l_abandonded_pauses.EXISTS (rec.mview_name)
            THEN
               IF rec.paused_at > l_abandonded_pauses (rec.mview_name)
               THEN
                  l_abandonded_pauses (rec.mview_name) := rec.paused_at;
               END IF;
            ELSE
               l_abandonded_pauses (rec.mview_name) := rec.paused_at;
            END IF;
         END IF;
      END LOOP;

      l_mview_name := l_abandonded_pauses.FIRST;

      BEGIN
         LOOP
            EXIT WHEN l_mview_name IS NULL;
            dbms_mview.REFRESH (l_mview_name, 'c');

            EXECUTE IMMEDIATE    'alter materialized view '
                              || l_mview_name
                              || ' refresh on commit';

            DBMS_OUTPUT.put_line
                             (   'MVIEW '''
                              || l_mview_name
                              || ''' ABANDONDED on-commit refresh resumed at '
                              || SYSTIMESTAMP
                             );

            DELETE FROM at_mview_refresh_paused
                  WHERE mview_name = l_mview_name
                    AND paused_at <= l_abandonded_pauses (l_mview_name);

            l_mview_name := l_abandonded_pauses.NEXT (l_mview_name);
         END LOOP;
      END;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         COMMIT;
      WHEN OTHERS
      THEN
         ROLLBACK TO timeout_mv_rfrsh_paused_start;
         RAISE;
   END timeout_mv_refresh_paused;

--------------------------------------------------------------------------------
-- procedure start_timeout_mv_refresh_job
--
   PROCEDURE start_timeout_mv_refresh_job
   IS
      l_count     BINARY_INTEGER;
      l_user_id   VARCHAR2 (30);
      l_job_id    VARCHAR2 (30)  := 'TIMEOUT_MV_REFRESH_JOB';

      FUNCTION job_count
         RETURN BINARY_INTEGER
      IS
      BEGIN
         SELECT COUNT (*)
           INTO l_count
           FROM SYS.dba_scheduler_jobs
          WHERE job_name = l_job_id AND owner = l_user_id;

         RETURN l_count;
      END;
   BEGIN
--------------------------------------
-- make sure we're the correct user --
--------------------------------------
      l_user_id := SYS_CONTEXT ('userenv', 'session_user');

      IF l_user_id != 'CWMS_20'
      THEN
         raise_application_error (-20999,
                                     'Must be CWMS_20 user to start job '
                                  || l_job_id,
                                  TRUE
                                 );
      END IF;

-------------------------------------------
-- drop the job if it is already running --
-------------------------------------------
      IF job_count > 0
      THEN
         DBMS_OUTPUT.put ('Dropping existing job ' || l_job_id || '...');
         DBMS_SCHEDULER.drop_job (l_job_id);

--------------------------------
-- verify that it was dropped --
--------------------------------
         IF job_count = 0
         THEN
            DBMS_OUTPUT.put_line ('done.');
         ELSE
            DBMS_OUTPUT.put_line ('failed.');
         END IF;
      END IF;

      IF job_count = 0
      THEN
         BEGIN
---------------------
-- restart the job --
---------------------
            DBMS_SCHEDULER.create_job
               (job_name             => l_job_id,
                job_type             => 'stored_procedure',
                job_action           => 'cwms_util.timeout_mv_refresh_paused',
                start_date           => NULL,
                repeat_interval      =>    'freq=minutely; interval='
                                        || mv_pause_job_run_interval,
                end_date             => NULL,
                job_class            => 'default_job_class',
                enabled              => TRUE,
                auto_drop            => FALSE,
                comments             => 'Times out abandoned pauses to on-commit refreshes on mviews.'
               );

            IF job_count = 1
            THEN
               DBMS_OUTPUT.put_line
                              (   'Job '
                               || l_job_id
                               || ' successfully scheduled to execute every '
                               || mv_pause_job_run_interval
                               || ' minutes.'
                              );
            ELSE
               cwms_err.RAISE ('ITEM_NOT_CREATED', 'job', l_job_id);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               cwms_err.RAISE ('ITEM_NOT_CREATED',
                               'job',
                               l_job_id || ':' || SQLERRM
                              );
         END;
      END IF;
   END start_timeout_mv_refresh_job;

--------------------------------------------------------
-- Return the current session user's primary office id
--
   FUNCTION user_office_id
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16) := NULL;
      l_user_id     VARCHAR2 (32);
   BEGIN
      l_user_id := SYS_CONTEXT ('userenv', 'session_user');

      BEGIN
         SELECT primary_office_id
           INTO l_office_id
           FROM at_sec_user_office
          WHERE user_id = l_user_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT office_id
                 INTO l_office_id
                 FROM cwms_office
                WHERE eroc = UPPER (SUBSTR (l_user_id, 1, 2));
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
      END;

      RETURN l_office_id;
   END user_office_id;

--------------------------------------------------------
-- Return the current session user's primary office code
--
   FUNCTION user_office_code
      RETURN NUMBER
   IS
      l_office_code   NUMBER (10)   := NULL;
      l_user_id       VARCHAR2 (32);
   BEGIN
      l_user_id := SYS_CONTEXT ('userenv', 'session_user');

      BEGIN
         SELECT office_code
           INTO l_office_code
           FROM cwms_office
          WHERE office_id = (SELECT primary_office_id
                               FROM at_sec_user_office
                              WHERE user_id = l_user_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT office_code
                 INTO l_office_code
                 FROM cwms_office
                WHERE eroc = UPPER (SUBSTR (l_user_id, 1, 2));
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
      END;

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
          WHERE office_id = p_office_id;
      END IF;

      RETURN l_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', p_office_id);
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
      SELECT db_host_office_code
        INTO l_db_office_code
        FROM cwms_office
       WHERE office_code = get_office_code (p_office_id);

      RETURN l_db_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', p_office_id);
   END get_db_office_code;

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
      p_recognize_sql   IN   BOOLEAN DEFAULT FALSE
   )
      RETURN VARCHAR2
   IS
      l_result   VARCHAR2 (32767);
      l_char     VARCHAR2 (1);
      l_skip     BOOLEAN          := FALSE;
   BEGIN
--------------------------------
-- default null string to '%' --
--------------------------------
      IF p_string IS NULL
      THEN
         RETURN '%';
      END IF;

      l_result := NULL;

      FOR i IN 1 .. LENGTH (p_string)
      LOOP
         IF l_skip
         THEN
            l_skip := FALSE;
         ELSE
            l_char := SUBSTR (p_string, i, 1);

            CASE l_char
               WHEN '\'
               THEN
                  IF i = LENGTH (p_string)
                  THEN
                     cwms_err.RAISE
                         ('ERROR',
                          'Escape character ''\'' cannot end a match string.'
                         );
                  END IF;

                  l_skip := TRUE;

                  IF REGEXP_INSTR (NVL (SUBSTR (p_string, i + 1), ' '),
                                   '\\[*?%_]'
                                  ) = 1
                  THEN
                     l_result := l_result || '\\';
                  ELSE
                     l_char := SUBSTR (p_string, i + 1, 1);

                     IF p_recognize_sql
                     THEN
                        CASE l_char
                           WHEN '\'
                           THEN
                              l_result := l_result || '\';
                           WHEN '*'
                           THEN
                              l_result := l_result || '*';
                           WHEN '?'
                           THEN
                              l_result := l_result || '?';
                           WHEN '%'
                           THEN
                              l_result := l_result || '\%';
                           WHEN '_'
                           THEN
                              l_result := l_result || '\_';
                           ELSE
                              cwms_err.RAISE ('INVALID_ITEM',
                                              p_string,
                                              'match string'
                                             );
                        END CASE;
                     ELSE
                        CASE l_char
                           WHEN '\'
                           THEN
                              l_result := l_result || '\';
                           WHEN '*'
                           THEN
                              l_result := l_result || '*';
                           WHEN '?'
                           THEN
                              l_result := l_result || '?';
                           WHEN '%'
                           THEN
                              cwms_err.RAISE
                                 ('ERROR',
                                  'Escape sequence ''\%'' is not valid when p_recognize_sql is FALSE.'
                                 );
                           WHEN '_'
                           THEN
                              cwms_err.RAISE
                                 ('ERROR',
                                  'Escape sequence ''\_'' is not valid when p_recognize_sql is FALSE.'
                                 );
                           ELSE
                              cwms_err.RAISE ('INVALID_ITEM',
                                              p_string,
                                              'match string'
                                             );
                        END CASE;
                     END IF;
                  END IF;
               WHEN '*'
               THEN
                  l_result := l_result || '%';
               WHEN '?'
               THEN
                  l_result := l_result || '_';
               WHEN '%'
               THEN
                  IF NOT p_recognize_sql
                  THEN
                     l_result := l_result || '\';
                  END IF;

                  l_result := l_result || '%';
               WHEN '_'
               THEN
                  IF NOT p_recognize_sql
                  THEN
                     l_result := l_result || '\';
                  END IF;

                  l_result := l_result || '_';
               ELSE
                  l_result := l_result || l_char;
            END CASE;
         END IF;
      END LOOP;

      RETURN l_result;
   END normalize_wildcards;

--------------------------------------------------------------------------------
-- Parses a search string into one or more AND/OR LIKE/NOT LIKE predicate lines.
-- A search string contains one or more search patterns separated by a blank  -
-- space. When constructing search patterns on can use AND, OR, and NOT between-
-- search patterns. a blank space between two patterns is assumed to be an AND.
-- Quotes can be used to aggregate search patterns that contain one or more    -
-- blank spaces.
--
   FUNCTION parse_search_string (
      p_search_patterns   IN   VARCHAR2,
      p_search_column     IN   VARCHAR2,
      p_use_upper         IN   BOOLEAN DEFAULT TRUE
   )
      RETURN VARCHAR2
--------------------------------------------------------------------------------
-- Usage:                                                                      -
--         *   - wild card character matches zero or more occurences.          -
--         ?   - wild card character matches zero or one occurence.            -
--         and - AND or a blank space, e.g., abc* *123 is eqivalent to         -
--                                           abc* AND *123                     -
--         or  - OR  e.g., abc* OR *123                                        -
--         not - NOT or a dash, e.g.,  'NOT abc*' is equivalent to '-abc*'     -
--         " " - quotes are used to aggregate patters that have blank spaces   -
--               e.g., "abc 123*"                                              -
--
--         One can use the backslash as an escape character for the following  -
--         special characters:                                                 -
--         \* used to make an asterisks a literal instead of a wild character  -                                                            -
--         \? used to make a question mark a literal instead of a wild         -
--            character                                                        - 
--         \- used to start a new parse pattern with a dash instead of a NOT   -
--         \" used to make a quote a literal part of the parse pattern.        -
--
-- Example:
-- p_search_column:   COLUMN_OF_INTEREST                                       -
-- p_search_patterns: cb* NOT cbt* OR NOT cbk*                                 -
--       will return:                                                          -
--                    AND UPPER(COLUMN_OF_INTEREST)  LIKE 'CB%'                -
--                    AND UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBT%'            -
--                    OR UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBK%'             -
--
--  if p_use_upper is set to false, the above will return:
--
--                     AND COLUMN_OF_INTEREST  LIKE 'cb%'                      -
--                     AND COLUMN_OF_INTEREST NOT LIKE 'cbt%'                  -
--                     OR COLUMN_OF_INTEREST NOT LIKE 'cbk%'                   -
--
--  A null p_search_patterns generates a result of '%'.
--
--                     AND COLUMN_OF_INTEREST  LIKE '%'                        -
--------------------------------------------------------------------------------
--
   IS
      l_string                VARCHAR2 (256)  := TRIM (p_search_patterns);
      l_search_column         VARCHAR2 (30) := UPPER (TRIM (p_search_column));
      l_use_upper             BOOLEAN         := NVL (p_use_upper, TRUE);
      l_recognize_sql         BOOLEAN         := FALSE;
      l_string_length         NUMBER          := NVL (LENGTH (l_string), 0);
      l_skip                  BOOLEAN         := FALSE;
      l_looking_first_quote   BOOLEAN         := TRUE;
      l_sub_string_done       BOOLEAN         := FALSE;
      l_first_char            BOOLEAN         := TRUE;
      l_char                  VARCHAR2 (1);
      l_sub_string            VARCHAR2 (64)   := NULL;
      l_not                   VARCHAR2 (3)    := NULL;
      l_and_or                VARCHAR2 (3)    := 'AND';
      l_result                VARCHAR2 (1000) := NULL;
      l_open_upper            VARCHAR2 (7);
      l_close_upper           VARCHAR2 (2);
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
      IF l_string_length <= 0
      THEN
         l_result := ' AND UPPER(' || l_search_column || ') LIKE ''%'' ';
      ELSE
         FOR i IN 1 .. LENGTH (l_string)
         LOOP
            IF l_skip
            THEN
               l_skip := FALSE;
            ELSE
               l_char := SUBSTR (l_string, i, 1);

               CASE l_char
                  WHEN '\'
                  THEN
                     IF REGEXP_INSTR (NVL (SUBSTR (l_string, i + 1), ' '),
                                      '["*?-]'
                                     ) = 1
                     THEN
                        l_char := SUBSTR (l_string, i + 1, 1);

                        CASE l_char
                           WHEN '*'
                           THEN
                              l_sub_string := l_sub_string || '\';
                           WHEN '?'
                           THEN
                              l_sub_string := l_sub_string || '\';
                           WHEN '"'
                           THEN
                              l_sub_string := l_sub_string || '"';
                              l_skip := TRUE;
                           WHEN '-'
                           THEN
                              l_sub_string := l_sub_string || '-';
                              l_skip := TRUE;
                           ELSE
                              l_skip := TRUE;
                        END CASE;
                     END IF;
                  WHEN '-'
                  THEN
                     IF l_first_char
                     THEN
                        l_not := 'NOT';
                     ELSE
                        l_sub_string := l_sub_string || l_char;
                     END IF;
                  WHEN '"'
                  THEN
                     IF l_looking_first_quote
                     THEN
                        IF    INSTR (NVL (SUBSTR (l_string, i - 1, 2), ' "'),
                                     ' "'
                                    ) = 1
                           OR i = 1
                           OR (    i >= 2
                               AND INSTR (SUBSTR (l_string, i - 2, 3), ' -"') =
                                                                             1
                              )
                           OR (    i = 2
                               AND INSTR (SUBSTR (l_string, i - 2, 2), '-"') =
                                                                             1
                              )
                        THEN
                           l_looking_first_quote := FALSE;
                        ELSE
                           l_sub_string := l_sub_string || l_char;
                        END IF;
                     ELSE                        -- looking for the end quote.
                        /*
                        An end quote must be followed by a space or end the string.
                        */
                        IF INSTR (NVL (SUBSTR (l_string, i + 1), ' '), ' ') =
                                                                            1
                        THEN
                           l_skip := TRUE;
                           l_sub_string_done := TRUE;
                        ELSE
                           l_sub_string := l_sub_string || l_char;
                        END IF;
                     END IF;
                  WHEN ' '
                  THEN
                     IF l_looking_first_quote
                     THEN
                        l_sub_string_done := TRUE;
                     ELSE
                        l_sub_string := l_sub_string || l_char;
                     END IF;
                  ELSE
                     l_sub_string := l_sub_string || l_char;
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
                        cwms_util.normalize_wildcards
                                          (p_string             => l_sub_string,
                                           p_recognize_sql      => l_recognize_sql
                                          );

                     IF l_use_upper
                     THEN
                        l_sub_string := UPPER (l_sub_string);
                     END IF;

                     l_result :=
                           l_result
                        || ' '
                        || l_and_or
                        || l_open_upper
                        || l_search_column
                        || l_close_upper
                        || l_not
                        || ' LIKE '''
                        || l_sub_string
                        || ''' '
                        || CHR (10);
                     l_and_or := 'AND';
                     l_not := NULL;
                  END IF;
               END IF;

               l_first_char := TRUE;
               l_sub_string := NULL;
               l_sub_string_done := FALSE;
               l_looking_first_quote := TRUE;
            END IF;
         END LOOP;
      END IF;

      RETURN l_result;
   END parse_search_string;

--------------------------------------------------------------------
-- Return a string with all leading and trailing whitespace removed.
--
   FUNCTION strip (p_text IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_text   VARCHAR2 (32767);
   BEGIN
      l_text :=
              REGEXP_REPLACE (p_text, '^[[:space:]]*(.*)[[:space:]]*$', '\1');
      RETURN l_text;
   END strip;

--------------------------------------------------------------------------------
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
        FROM cwms_time_zone
       WHERE UPPER (time_zone_name) = UPPER (NVL (p_time_zone_name, 'UTC'));

      RETURN l_time_zone_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('INVALID_TIME_ZONE', p_time_zone_name);
   END get_time_zone_code;

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
         cwms_err.RAISE ('INVALID_ITEM',
                         p_tz_usage_id,
                         'CWMS time zone usage'
                        );
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

-------------------------------------------------------------------------------
-- function split_text(...)
--
--
   FUNCTION split_text (
      p_text        IN   VARCHAR2,
      p_separator   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN str_tab_t
   IS
      l_str_tab   str_tab_t        := str_tab_t ();
      l_str       VARCHAR2 (32767);
      l_field     VARCHAR2 (32767);
      l_pos       BINARY_INTEGER;
      l_sep       VARCHAR2 (32767);
      l_sep_len   BINARY_INTEGER;
   BEGIN
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
         l_pos := NVL (INSTR (l_str, l_sep), 0);

         IF l_pos = 0
         THEN
            l_field := l_str;
            l_str := NULL;
         ELSE
            l_field := SUBSTR (l_str, 1, l_pos - 1);
            l_str := SUBSTR (l_str, l_pos + l_sep_len);
         -- null if > length(l_str)
         END IF;

         l_str_tab.EXTEND;
         l_str_tab (l_str_tab.LAST) := l_field;
         EXIT WHEN l_pos = 0;
      END LOOP;

      RETURN l_str_tab;
   END split_text;

-------------------------------------------------------------------------------
-- function join_text(...)
--
--
   FUNCTION join_text (
      p_text_tab    IN   str_tab_t,
      p_separator   IN   VARCHAR2 DEFAULT NULL
   )
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

-------------------------------------------------------------------------------
-- function parse_clob_recordset(...)
--
--
   FUNCTION parse_clob_recordset (p_clob IN CLOB)
      RETURN str_tab_tab_t
   IS
      l_rows                str_tab_t;
      l_tab                 str_tab_tab_t    := str_tab_tab_t ();
      l_buf                 VARCHAR2 (32767) := '';
      l_chunk               VARCHAR2 (4000);
      l_clob_offset         BINARY_INTEGER   := 1;
      l_buf_offset          BINARY_INTEGER   := 1;
      l_amount              BINARY_INTEGER;
      l_clob_len            BINARY_INTEGER;
      l_last                BINARY_INTEGER;
      l_done_reading        BOOLEAN;
      chunk_size   CONSTANT BINARY_INTEGER   := 4000;
   BEGIN
      IF p_clob IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_clob_len := DBMS_LOB.getlength (p_clob);
      l_amount := chunk_size;

      LOOP
         DBMS_LOB.READ (p_clob, l_amount, l_clob_offset, l_chunk);
         l_clob_offset := l_clob_offset + l_amount;
         l_done_reading := l_clob_offset > l_clob_len;
         l_buf := l_buf || l_chunk;

         IF INSTR (l_buf, record_separator) > 0 OR l_done_reading
         THEN
            l_rows := split_text (l_buf, record_separator);
            l_buf := l_rows (l_rows.COUNT);

            IF l_done_reading
            THEN
               l_last := l_rows.COUNT;
            ELSE
               l_last := l_rows.COUNT - 1;
            END IF;

            FOR i IN l_rows.FIRST .. l_last
            LOOP
               l_tab.EXTEND;
               l_tab (l_tab.LAST) := split_text (l_rows (i), field_separator);
            END LOOP;
         END IF;

         EXIT WHEN l_done_reading;
      END LOOP;

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

      FOR i IN l_rows.FIRST .. l_rows.LAST
      LOOP
         l_tab.EXTEND;
         l_tab (i) := split_text (l_rows (i), field_separator);
      END LOOP;

      RETURN l_tab;
   END parse_string_recordset;
----------------------------------------------------------------------------
BEGIN
   -- anything put here will be executed on every mod_plsql call
   NULL;
END cwms_util;
/

SHOW errors;