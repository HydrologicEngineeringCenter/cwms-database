/* Formatted on 1/18/2012 2:59:32 PM (QP5 v5.185.11230.41888) */
set define on
@@defines
CREATE OR REPLACE PACKAGE BODY cwms_ts
AS
   FUNCTION get_max_open_cursors
      RETURN INTEGER
   IS
      l_max_open_cursors   INTEGER;
   BEGIN
      SELECT VALUE
        INTO l_max_open_cursors
        FROM v$parameter
       WHERE name = 'open_cursors';

      RETURN l_max_open_cursors;
   END get_max_open_cursors;

   --********************************************************************** -
   --
   -- get_ts_code returns ts_code...
   --
   FUNCTION get_ts_code (p_cwms_ts_id     IN VARCHAR2,
                         p_db_office_id   IN VARCHAR2)
      RETURN NUMBER
   IS
      l_ts_code   NUMBER := NULL;
   BEGIN
      RETURN get_ts_code (
                p_cwms_ts_id       => p_cwms_ts_id,
                p_db_office_code   => cwms_util.get_db_office_code (
                                        p_db_office_id));
   END get_ts_code;

   function get_ts_code (
      p_cwms_ts_id     in varchar2,
      p_db_office_code in number)
      return number
   is
      l_office_id    varchar2(16) := cwms_util.get_db_office_id_from_code(p_db_office_code);
      l_cwms_ts_code number;
   begin
      begin
         select ts_code
           into l_cwms_ts_code
           from at_cwms_ts_id
          where upper(cwms_ts_id) = upper(get_cwms_ts_id(trim(p_cwms_ts_id), l_office_id))
            and db_office_code = p_db_office_code;
      exception
         when no_data_found then
            cwms_err.raise (
               'TS_ID_NOT_FOUND',
               trim (p_cwms_ts_id),
               l_office_id);
      end;
      return l_cwms_ts_code;
   end get_ts_code;

   ---------------------------------------------------------------------------

   FUNCTION get_ts_id (p_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_cwms_ts_id   VARCHAR2(191);
   BEGIN
      BEGIN
         SELECT cwms_ts_id
           INTO l_cwms_ts_id
           FROM at_cwms_ts_id
          WHERE ts_code = p_ts_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT cwms_ts_id
              INTO l_cwms_ts_id
              FROM at_cwms_ts_id
             WHERE ts_code = p_ts_code;
      END;

      RETURN l_cwms_ts_id;
   END;

   function clean_ts_id(
      p_ts_id in varchar2)
      return varchar2
   is
      l_parts str_tab_t;
      l_ts_id varchar2(191);
   begin
      l_parts := cwms_util.split_text(p_ts_id, '.');
      for i in 1..l_parts.count loop
         l_parts(i) := cwms_util.strip(l_parts(i));
      end loop;
      l_ts_id := cwms_util.join_text(l_parts, '.');
      if length(l_ts_id) != length(p_ts_id) then
         cwms_msg.log_db_message(
            'CWMS_TS.CLEAN_TS_ID',
            cwms_msg.msg_level_normal,
            'Cleaned invalid TSID: '||p_ts_id);
      end if;
      return l_ts_id;
   end clean_ts_id;

   --******************************************************************************/
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_CWMS_TS_ID -
   --
   function get_cwms_ts_id (
      p_cwms_ts_id   in varchar2,
      p_office_id    in varchar2)
      return varchar2
   is
      l_cwms_ts_id varchar2(191);
      l_parts      str_tab_t;
   begin
      -----------
      -- as is --
      -----------
      begin
         select cwms_ts_id
           into l_cwms_ts_id
           from at_cwms_ts_id
          where upper(cwms_ts_id) = upper(p_cwms_ts_id)
            and upper(db_office_id) = upper(p_office_id);
      exception
         when no_data_found then
            ----------------------------
            -- try time series alias  --
            -- (will try loc aliases) --
            ----------------------------
            l_cwms_ts_id := cwms_ts.get_ts_id_from_alias(p_cwms_ts_id, null, null, p_office_id);
      end;
      if l_cwms_ts_id is null then
         l_cwms_ts_id := p_cwms_ts_id;
      end if;
      return l_cwms_ts_id;
   end;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DB_UNIT_ID -
   --
   FUNCTION get_db_unit_id (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_base_location_id    at_base_location.base_location_id%TYPE;
      l_sub_location_id     at_physical_location.sub_location_id%TYPE;
      l_base_parameter_id   cwms_base_parameter.base_parameter_id%TYPE;
      l_sub_parameter_id    at_parameter.sub_parameter_id%TYPE;
      l_parameter_type_id   cwms_parameter_type.parameter_type_id%TYPE;
      l_interval_id         cwms_interval.interval_id%TYPE;
      l_duration_id         cwms_duration.duration_id%TYPE;
      l_version_id          at_cwms_ts_spec.VERSION%TYPE;
      l_db_unit_id          cwms_unit.unit_id%TYPE;
   BEGIN
      parse_ts (p_cwms_ts_id,
                l_base_location_id,
                l_sub_location_id,
                l_base_parameter_id,
                l_sub_parameter_id,
                l_parameter_type_id,
                l_interval_id,
                l_duration_id,
                l_version_id);

      --
      SELECT unit_id
        INTO l_db_unit_id
        FROM cwms_unit cu, cwms_base_parameter cbp
       WHERE     cu.unit_code = cbp.unit_code
             AND cbp.base_parameter_id = l_base_parameter_id;

      --
      RETURN l_db_unit_id;
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_TIME_ON_AFTER_INTERVAL - if p_datetime is on the interval, than
   --      p_datetime is returned, if p_datetime is off of the interval, than
   --      the first datetime after p_datetime is returned.
   --
   --      Function is usable down to 1 minute.
   --
   --      All offsets stored in the database are in minutes. --
   --      p_ts_offset and p_ts_interval are passed in as minutes --
   --      p_datetime is assumed to be in UTC --
   --
   --      Weekly intervals - the weekly interval starts with Sunday.
   --
   ----------------------------------------------------------------------------
   --

   FUNCTION get_time_on_after_interval (p_datetime      IN DATE,
                                        p_ts_offset     IN NUMBER, -- in minutes.
                                        p_ts_interval   IN NUMBER -- in minutes.
                                                                 )
      RETURN DATE
   IS
      l_datetime_tmp          DATE;
      l_normalized_datetime   DATE;
      l_tmp                   NUMBER;
      l_delta                 BINARY_INTEGER;
      l_multiplier            BINARY_INTEGER;
      l_mod                   BINARY_INTEGER;
      l_ts_interval           BINARY_INTEGER := TRUNC (p_ts_interval, 0);
   BEGIN
      DBMS_APPLICATION_INFO.set_module (
         'create_ts',
         'Function get_Time_On_After_Interval');

      -- Basic checks - interval cannot be zero - irregular...
      IF l_ts_interval <= 0
      THEN
         cwms_err.RAISE ('ERROR', 'Interval must be > zero.');
      END IF;

      -- Basic checks - offset cannot ve >= to interval...
      IF p_ts_offset >= l_ts_interval
      THEN
         cwms_err.RAISE ('ERROR', 'Offset cannot be >= to the Interval');
      END IF;

      --
      l_normalized_datetime :=
         TRUNC (p_datetime, 'MI') - (p_ts_offset / min_in_dy);

      IF p_ts_interval = 1
      THEN
         NULL;                                             -- nothing to do...
      ELSIF l_ts_interval < min_in_wk             -- intervals less than a week...
      THEN
         l_delta := (l_normalized_datetime - cwms_util.l_epoch) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod <= 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime + (l_ts_interval - l_mod) / min_in_dy;
         END IF;
      ELSIF l_ts_interval = min_in_wk                        -- weekly interval...
      THEN
         l_delta :=
            (l_normalized_datetime - cwms_util.l_epoch_wk_dy_1) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod <= 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime + (l_ts_interval - l_mod) / min_in_dy;
         END IF;
      ELSIF l_ts_interval = min_in_mo                       -- monthly interval...
      THEN
         l_datetime_tmp := TRUNC (l_normalized_datetime, 'Month');

         IF l_datetime_tmp != l_normalized_datetime
         THEN
            l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 1);
         END IF;
      ELSIF l_ts_interval = min_in_yr                       -- yearly interval...
      THEN
         l_datetime_tmp := TRUNC (l_normalized_datetime, 'YEAR');

         IF l_datetime_tmp != l_normalized_datetime
         THEN
            l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 12);
         END IF;
      ELSIF l_ts_interval = min_in_dc                     -- decadal interval...
      THEN
         l_mod :=
            MOD (TO_NUMBER (TO_CHAR (l_normalized_datetime, 'YYYY')), 10);
         l_datetime_tmp :=
            ADD_MONTHS (TRUNC (l_normalized_datetime, 'YEAR'),
                        - (l_mod * 12));

         IF l_datetime_tmp != l_normalized_datetime
         THEN
            l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 120);
         END IF;
      ELSE
         cwms_err.RAISE (
            'ERROR',
               l_ts_interval
            || ' minutes is not a valid/supported CWMS interval');
      END IF;

      RETURN l_normalized_datetime + (p_ts_offset / min_in_dy);
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END get_time_on_after_interval;

   --
   --  See get_time_on_after_interval for description/comments/etc...
   --
   FUNCTION get_time_on_before_interval (p_datetime      IN DATE,
                                         p_ts_offset     IN NUMBER,
                                         p_ts_interval   IN NUMBER)
      RETURN DATE
   IS
      l_datetime_tmp          DATE;
      l_normalized_datetime   DATE;
      l_tmp                   NUMBER;
      l_delta                 BINARY_INTEGER;
      l_multiplier            BINARY_INTEGER;
      l_mod                   BINARY_INTEGER;
      l_ts_interval           BINARY_INTEGER := TRUNC (p_ts_interval, 0);
   BEGIN
      DBMS_APPLICATION_INFO.set_module (
         'create_ts',
         'Function get_Time_On_Before_Interval');

      -- Basic checks - interval cannot be zero - irregular...
      IF l_ts_interval <= 0
      THEN
         cwms_err.RAISE ('ERROR', 'Interval must be > zero.');
      END IF;

      -- Basic checks - offset cannot ve >= to interval...
      IF p_ts_offset >= l_ts_interval
      THEN
         cwms_err.RAISE ('ERROR', 'Offset cannot be >= to the Interval');
      END IF;

      --
      l_normalized_datetime :=
         TRUNC (p_datetime, 'MI') - (p_ts_offset / min_in_dy);

      IF p_ts_interval = 1
      THEN
         NULL;                                             -- nothing to do...
      ELSIF l_ts_interval < min_in_wk             -- intervals less than a week...
      THEN
         l_delta := (l_normalized_datetime - cwms_util.l_epoch) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod < 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_ts_interval + l_mod) / min_in_dy;
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         END IF;
      ELSIF l_ts_interval = min_in_wk                        -- weekly interval...
      THEN
         l_delta :=
            (l_normalized_datetime - cwms_util.l_epoch_wk_dy_1) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod < 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_ts_interval + l_mod) / min_in_dy;
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         END IF;
      ELSIF l_ts_interval = min_in_mo                       -- monthly interval...
      THEN
         l_normalized_datetime := TRUNC (l_normalized_datetime, 'Month');
      ELSIF l_ts_interval = min_in_yr                       -- yearly interval...
      THEN
         l_normalized_datetime := TRUNC (l_normalized_datetime, 'YEAR');
      ELSIF l_ts_interval = min_in_dc                     -- decadal interval...
      THEN
         l_mod :=
            MOD (TO_NUMBER (TO_CHAR (l_normalized_datetime, 'YYYY')), 10);
         l_normalized_datetime :=
            ADD_MONTHS (TRUNC (l_normalized_datetime, 'YEAR'),
                        - (l_mod * 12));
      ELSE
         cwms_err.RAISE (
            'ERROR',
               l_ts_interval
            || ' minutes is not a valid/supported CWMS interval');
      END IF;

      RETURN l_normalized_datetime + (p_ts_offset / min_in_dy);
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END get_time_on_before_interval;



   FUNCTION get_location_id (p_cwms_ts_id     IN VARCHAR2,
                             p_db_office_id   IN VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN get_location_id (
                p_cwms_ts_code => get_ts_code (
                                    p_cwms_ts_id       => p_cwms_ts_id,
                                    p_db_office_code   => cwms_util.get_db_office_code (
                                                            p_office_id => p_db_office_id)));
   END;


   FUNCTION get_location_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_location_id   VARCHAR2 (57);
   BEGIN
      BEGIN
         SELECT location_id
           INTO l_location_id
           FROM at_cwms_ts_id
          WHERE ts_code = p_cwms_ts_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT location_id
              INTO l_location_id
              FROM at_cwms_ts_id
             WHERE ts_code = p_cwms_ts_code;
      END;

      RETURN l_location_id;
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_CODE -
   --
   FUNCTION get_parameter_code (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL,
      p_create              IN VARCHAR2 DEFAULT 'T')
      RETURN NUMBER
   IS
      l_base_parameter_code   NUMBER;
   BEGIN
      SELECT base_parameter_code
        INTO l_base_parameter_code
        FROM cwms_base_parameter
       WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);

      --dbms_output.put_line(l_base_parameter_code);
      --
      RETURN get_parameter_code (l_base_parameter_code,
                                 p_sub_parameter_id,
                                 cwms_util.get_db_office_code (p_office_id),
                                 cwms_util.return_true_or_false (p_create));
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DISPLAY_PARAMETER_CODE -
   --
   FUNCTION get_display_parameter_code (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_display_parameter_code   NUMBER := NULL;
      l_parameter_code           NUMBER := NULL;
      l_count                    INTEGER;
   BEGIN
      l_parameter_code :=
         get_parameter_code (p_base_parameter_id,
                             p_sub_parameter_id,
                             p_office_id,
                             'F');

      SELECT COUNT (*)
        INTO l_count
        FROM at_display_units
       WHERE parameter_code = l_parameter_code;

      IF l_count = 0
      THEN
         l_parameter_code :=
            get_parameter_code (p_base_parameter_id, NULL, p_office_id);

         SELECT COUNT (*)
           INTO l_count
           FROM at_display_units
          WHERE parameter_code = l_parameter_code;

         IF l_count > 0
         THEN
            l_display_parameter_code := l_parameter_code;
         END IF;
      ELSE
         l_display_parameter_code := l_parameter_code;
      END IF;

      RETURN l_display_parameter_code;
   END;

   FUNCTION get_display_parameter_code2 (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      invalid_param_id           EXCEPTION;
      PRAGMA EXCEPTION_INIT (invalid_param_id, -20006);
      l_display_parameter_code   NUMBER;
   BEGIN
      BEGIN
         l_display_parameter_code :=
            get_display_parameter_code (p_base_parameter_id,
                                        p_sub_parameter_id,
                                        p_office_id);
      EXCEPTION
         WHEN invalid_param_id
         THEN
            NULL;
      END;

      RETURN l_display_parameter_code;
   END get_display_parameter_code2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_CODE -
   --
   FUNCTION get_parameter_code (
      p_base_parameter_code   IN NUMBER,
      p_sub_parameter_id      IN VARCHAR2,
      p_office_code           IN NUMBER,
      p_create                IN BOOLEAN DEFAULT TRUE)
      RETURN NUMBER
   IS
      l_parameter_code      NUMBER;
      l_base_parameter_id   cwms_base_parameter.base_parameter_id%TYPE;
      l_office_code         NUMBER
         := NVL (p_office_code, cwms_util.user_office_code);
      l_office_id           VARCHAR2 (16);
   BEGIN
      BEGIN
         IF p_sub_parameter_id IS NOT NULL
         THEN
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND db_office_code IN
                          (p_office_code, cwms_util.db_office_code_all)
                   AND UPPER (sub_parameter_id) = UPPER (p_sub_parameter_id);
         ELSE
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND ap.sub_parameter_id IS NULL
                   AND db_office_code IN (cwms_util.db_office_code_all);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN                                   -- Insert new sub_parameter...
            IF p_create OR p_create IS NULL
            THEN
               INSERT INTO at_parameter (parameter_code,
                                         db_office_code,
                                         base_parameter_code,
                                         sub_parameter_id)
                    VALUES (cwms_seq.NEXTVAL,
                            p_office_code,
                            p_base_parameter_code,
                            p_sub_parameter_id)
                 RETURNING parameter_code
                      INTO l_parameter_code;
            ELSE
               SELECT office_id
                 INTO l_office_id
                 FROM cwms_office
                WHERE office_code = l_office_code;

               SELECT base_parameter_id
                 INTO l_base_parameter_id
                 FROM cwms_base_parameter
                WHERE base_parameter_code = p_base_parameter_code;

               cwms_err.RAISE (
                  'INVALID_PARAM_ID',
                     l_office_id
                  || '/'
                  || cwms_util.concat_base_sub_id (l_base_parameter_id,
                                                   p_sub_parameter_id));
            END IF;
      END;

      RETURN l_parameter_code;
   END get_parameter_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_CODE -
   --
   FUNCTION get_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_parameter_code   NUMBER := NULL;
   BEGIN
      SELECT parameter_code
        INTO l_parameter_code
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      RETURN l_parameter_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         '' || NVL (p_cwms_ts_code, 'NULL'),
                         'CWMS time series code.');
   END get_parameter_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_ID -
   --
   FUNCTION get_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_parameter_row   at_parameter%ROWTYPE;
      l_parameter_id    VARCHAR2 (49) := NULL;
   BEGIN
      SELECT *
        INTO l_parameter_row
        FROM at_parameter
       WHERE parameter_code = get_parameter_code (p_cwms_ts_code);

      SELECT base_parameter_id
        INTO l_parameter_id
        FROM cwms_base_parameter
       WHERE base_parameter_code = l_parameter_row.base_parameter_code;

      IF l_parameter_row.sub_parameter_id IS NOT NULL
      THEN
         l_parameter_id :=
            l_parameter_id || '-' || l_parameter_row.sub_parameter_id;
      END IF;

      RETURN l_parameter_id;
   END get_parameter_id;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_BASE_PARAMETER_CODE -
   --
   FUNCTION get_base_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_base_parameter_code   NUMBER (10) := NULL;
   BEGIN
      SELECT base_parameter_code
        INTO l_base_parameter_code
        FROM at_parameter
       WHERE parameter_code = get_parameter_code (p_cwms_ts_code);

      RETURN l_base_parameter_code;
   END get_base_parameter_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_BASE_PARAMETER_ID -
   --
   FUNCTION get_base_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_base_parameter_id   VARCHAR2 (16) := NULL;
   BEGIN
      SELECT base_parameter_id
        INTO l_base_parameter_id
        FROM cwms_base_parameter
       WHERE base_parameter_code = get_base_parameter_code (p_cwms_ts_code);

      RETURN l_base_parameter_id;
   END get_base_parameter_id;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_TYPE_CODE -
   --
   FUNCTION get_parameter_type_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_parameter_type_code   NUMBER := NULL;
   BEGIN
      SELECT parameter_type_code
        INTO l_parameter_type_code
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      RETURN l_parameter_type_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         '' || NVL (p_cwms_ts_code, 'NULL'),
                         'CWMS time series code.');
   END get_parameter_type_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_TYPE_ID -
   --
   FUNCTION get_parameter_type_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_parameter_type_id   VARCHAR2 (16) := NULL;
   BEGIN
      SELECT parameter_type_id
        INTO l_parameter_type_id
        FROM cwms_parameter_type
       WHERE parameter_type_code = get_parameter_type_code (p_cwms_ts_code);

      RETURN l_parameter_type_id;
   END get_parameter_type_id;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DB_OFFICE_CODE -
   --
   FUNCTION get_db_office_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_db_office_code   at_base_location.db_office_code%TYPE := NULL;
   BEGIN
      SELECT db_office_code
        INTO l_db_office_code
        FROM at_base_location bl, at_physical_location pl, at_cwms_ts_spec ts
       WHERE     ts.ts_code = p_cwms_ts_code
             AND pl.location_code = ts.location_code
             AND bl.base_location_code = pl.base_location_code;

      RETURN l_db_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         '' || NVL (p_cwms_ts_code, 'NULL'),
                         'CWMS time series code.');
   END get_db_office_code;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DB_OFFICE_ID -
   --
   FUNCTION get_db_office_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_db_office_id   cwms_office.office_id%TYPE := NULL;
   BEGIN
      SELECT office_id
        INTO l_db_office_id
        FROM cwms_office
       WHERE office_code = get_db_office_code (p_cwms_ts_code);

      RETURN l_db_office_id;
   END get_db_office_id;


   PROCEDURE update_ts_id (
      p_ts_code                  IN NUMBER,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes     IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_interval                 NUMBER;
      l_interval_utc_offset_old     NUMBER;
      l_interval_utc_offset_new     NUMBER;
      l_snap_forward_minutes_new    NUMBER;
      l_snap_forward_minutes_old    NUMBER;
      l_snap_backward_minutes_new   NUMBER;
      l_snap_backward_minutes_old   NUMBER;
      l_ts_active_new               VARCHAR2 (1) := UPPER (p_ts_active_flag);
      l_ts_active_old               VARCHAR2 (1);
      l_interval_id                 varchar2(16);
      l_tz                          varchar2(28);
      l_location_code               NUMBER;
      l_irregular_interval          NUMBER;
      l_tmp                         NUMBER := NULL;
   BEGIN
      --
      --
      BEGIN
         SELECT a.location_code,
                a.interval_utc_offset,
                a.interval_backward,
                a.interval_forward,
                a.active_flag,
                b.interval,
                c.interval_id
           INTO l_location_code,
                l_interval_utc_offset_old,
                l_snap_backward_minutes_old,
                l_snap_forward_minutes_old,
                l_ts_active_old,
                l_ts_interval,
                l_interval_id
           FROM at_cwms_ts_spec a, cwms_interval b, at_cwms_ts_id c
          WHERE a.interval_code = b.interval_code AND a.ts_code = p_ts_code and c.ts_code = p_ts_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      --
      IF l_ts_active_new IS NULL
      THEN
         l_ts_active_new := l_ts_active_old;
      ELSE
         IF l_ts_active_new NOT IN ('T', 'F')
         THEN
            cwms_err.RAISE ('INVALID_T_F_FLAG', 'p_ts_active_flag');
         END IF;
      END IF;

      --
      IF p_interval_utc_offset IS NULL
      THEN
         l_interval_utc_offset_new := l_interval_utc_offset_old;
      ELSE
         --
         -- Are interval utc offset set and if so is it a valid offset?.
         --
         IF l_ts_interval = 0
         THEN
            --
            -- irregular time series
            --
            IF l_interval_id LIKE '~%'
            THEN
               --
               -- pseudo-irregular
               --
               IF p_interval_utc_offset != cwms_util.utc_offset_irregular
               THEN
                  SELECT INTERVAL
                    INTO l_irregular_interval
                    FROM cwms_interval
                   WHERE interval_id = substr(l_interval_id, 2);

                  IF p_interval_utc_offset >= l_irregular_interval
                  THEN
                     cwms_err.RAISE ('INVALID_UTC_OFFSET',
                                     p_interval_utc_offset,
                                     l_interval_id);
                  end if;
                  --
                  -- see if we can change interval
                  --
                  l_tz := cwms_loc.get_local_timezone(l_location_code);
                  SELECT COUNT (*)
                    INTO l_tmp
                    FROM (SELECT local_time,
                                 cwms_ts.get_time_on_before_interval(
                                    local_time,
                                    p_interval_utc_offset,
                                    l_irregular_interval) as interval_time
                            FROM (SELECT cwms_util.change_timezone(date_time, 'UTC', l_tz) AS local_time
                                    FROM av_tsv WHERE ts_code = p_ts_code
                                 )
                         )
                   WHERE local_time != interval_time;

                  IF l_tmp > 0
                  THEN
                     cwms_err.RAISE ('CANNOT_CHANGE_OFFSET',
                                     get_ts_id (p_ts_code));
                  END IF;
               END IF;
               l_interval_utc_offset_new := p_interval_utc_offset;
            ELSE
               --
               -- straight irregular
               --
               IF p_interval_utc_offset != cwms_util.utc_offset_irregular
            THEN
               cwms_err.RAISE ('INVALID_UTC_OFFSET',
                               p_interval_utc_offset,
                               'Irregular');
            ELSE
               l_interval_utc_offset_new := cwms_util.utc_offset_irregular;
            END IF;
            END IF;
         ELSE
            --
            -- regular time series
            --
            IF p_interval_utc_offset = cwms_util.utc_offset_undefined
            THEN
               l_interval_utc_offset_new := cwms_util.utc_offset_undefined;
            ELSE
               IF     p_interval_utc_offset >= 0
                  AND p_interval_utc_offset < l_ts_interval
               THEN
                  l_interval_utc_offset_new := p_interval_utc_offset;
               ELSE
                  cwms_err.RAISE ('INVALID_UTC_OFFSET',
                                  p_interval_utc_offset,
                                  l_ts_interval);
               END IF;
            END IF;

            --
            -- check if the utc offset is being changed and can it be changed.
            --
            IF     l_interval_utc_offset_old !=
                      cwms_util.utc_offset_undefined
               AND l_interval_utc_offset_old != l_interval_utc_offset_new
            THEN -- need to check if this ts_code already holds data, if it does
               -- then can't change interval_utc_offset.
               SELECT COUNT (*)
                 INTO l_tmp
                 FROM av_tsv
                WHERE ts_code = p_ts_code;

               IF l_tmp > 0
               THEN
                  cwms_err.RAISE ('CANNOT_CHANGE_OFFSET',
                                  get_ts_id (p_ts_code));
               END IF;
            END IF;
         END IF;
      END IF;

      --
      -- Set snap back/forward..
      ----
      ---- Confirm that snap back/forward times are valid....
      ----
      IF    l_interval_utc_offset_new != cwms_util.utc_offset_undefined
         AND l_interval_utc_offset_new != cwms_util.utc_offset_irregular
      THEN
         IF    p_snap_forward_minutes IS NOT NULL
            OR p_snap_backward_minutes IS NOT NULL
         THEN
            l_snap_forward_minutes_new := NVL (p_snap_forward_minutes, 0);
            l_snap_backward_minutes_new := NVL (p_snap_backward_minutes, 0);

            IF l_snap_forward_minutes_new + l_snap_backward_minutes_new >=
                  greatest(l_ts_interval, nvl(l_irregular_interval, 0))
            THEN
               cwms_err.RAISE ('INVALID_SNAP_WINDOW');
            END IF;
         ELSE
            l_snap_forward_minutes_new := l_snap_forward_minutes_old;
            l_snap_backward_minutes_new := l_snap_backward_minutes_old;
         END IF;
      ELSE
         l_snap_forward_minutes_new := NULL;
         l_snap_backward_minutes_new := NULL;
      END IF;

      --
      IF     l_ts_interval = 0
         AND l_interval_utc_offset_new != cwms_util.utc_offset_irregular
      THEN
         l_interval_utc_offset_new := -l_interval_utc_offset_new;
      END IF;

      --
      UPDATE at_cwms_ts_spec a
         SET a.interval_utc_offset = l_interval_utc_offset_new,
             a.interval_forward = l_snap_forward_minutes_new,
             a.interval_backward = l_snap_backward_minutes_new,
             a.active_flag = l_ts_active_new
       WHERE a.ts_code = p_ts_code;
   --
   --
   END;



   PROCEDURE update_ts_id (
      p_cwms_ts_id               IN VARCHAR2,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes     IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN VARCHAR2 DEFAULT NULL,
      p_db_office_id             IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      update_ts_id (
         p_ts_code                  => get_ts_code (
                                         p_cwms_ts_id       => p_cwms_ts_id,
                                         p_db_office_code   => cwms_util.get_db_office_code (
                                                                 p_db_office_id)),
         p_interval_utc_offset      => p_interval_utc_offset,
         -- in minutes.
         p_snap_forward_minutes     => p_snap_forward_minutes,
         p_snap_backward_minutes    => p_snap_backward_minutes,
         p_local_reg_time_zone_id   => p_local_reg_time_zone_id,
         p_ts_active_flag           => p_ts_active_flag);
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- SET_TS_TIME_ZONE -
   --
   PROCEDURE set_ts_time_zone (p_ts_code          IN NUMBER,
                               p_time_zone_name   IN VARCHAR2)
   IS
      l_time_zone_name   VARCHAR2 (28) := NVL (p_time_zone_name, 'UTC');
      l_time_zone_code   NUMBER;
      l_interval_val     NUMBER;
      l_tz_offset        NUMBER;
      l_office_id        VARCHAR2 (16);
      l_tsid             VARCHAR2 (193);
      l_query            VARCHAR2 (32767);
   BEGIN
      IF p_time_zone_name IS NULL
      THEN
         l_time_zone_code := NULL;
      ELSE
         BEGIN
            SELECT time_zone_code
              INTO l_time_zone_code
              FROM mv_time_zone
             WHERE UPPER (time_zone_name) = UPPER (p_time_zone_name);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               p_time_zone_name,
                               'time zone name');
         END;
      END IF;

      SELECT interval
        INTO l_interval_val
        FROM at_cwms_ts_spec ts, cwms_interval i
       WHERE ts.ts_code = p_ts_code AND i.interval_code = ts.interval_code;

      IF l_interval_val > 60
      THEN
         BEGIN
            l_query := REPLACE (
               'select distinct mod(round((cast((cast(date_time as timestamp) at time zone ''$tz'') as date)
                                   - trunc(cast((cast(date_time as timestamp) at time zone ''$tz'') as date)))
                                   * 1440, 0), :a)
                  from (select distinct date_time
                          from av_tsv_dqu
                         where ts_code = :b
                       )',
                       '$tz',
                       l_time_zone_name);

            cwms_util.check_dynamic_sql(l_query);

            EXECUTE IMMEDIATE l_query
               INTO l_tz_offset
               USING l_interval_val, p_ts_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN TOO_MANY_ROWS
            THEN
               SELECT cwms_ts_id, db_office_id
                 INTO l_tsid, l_office_id
                 FROM at_cwms_ts_id
                WHERE ts_code = p_ts_code;

               cwms_err.raise (
                  'ERROR',
                     'Cannot set '
                  || l_office_id
                  || '.'
                  || l_tsid
                  || ' to time zone '
                  || NVL (p_time_zone_name, 'NULL')
                  || '.  Existing data does not conform to time zone.');
         END;
      END IF;

      UPDATE at_cwms_ts_spec
         SET time_zone_code = l_time_zone_code
       WHERE ts_code = p_ts_code;
   END set_ts_time_zone;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- set_tsid_time_zone -
   --
   PROCEDURE set_tsid_time_zone (p_ts_id            IN VARCHAR2,
                                 p_time_zone_name   IN VARCHAR2,
                                 p_office_id        IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code     NUMBER;
      l_office_id   VARCHAR2 (16)
                       := NVL (p_office_id, cwms_util.user_office_id);
   BEGIN
      BEGIN
         SELECT ts_code
           INTO l_ts_code
           FROM at_cwms_ts_id
          WHERE     UPPER (cwms_ts_id) = UPPER (p_ts_id)
                AND UPPER (db_office_id) = UPPER (l_office_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('INVALID_ITEM',
                            p_ts_id,
                            'CWMS Timeseries Identifier');
      END;

      set_ts_time_zone (l_ts_code, p_time_zone_name);
   END set_tsid_time_zone;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- get_ts_time_zone -
   --
   FUNCTION get_ts_time_zone (p_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_time_zone_code   NUMBER;
      l_time_zone_id     VARCHAR2 (28);
   BEGIN
      SELECT time_zone_code
        INTO l_time_zone_code
        FROM at_cwms_ts_spec
       WHERE ts_code = p_ts_code;

      IF l_time_zone_code IS NULL
      THEN
         l_time_zone_id := NULL;
      ELSE
         SELECT time_zone_name
           INTO l_time_zone_id
           FROM cwms_time_zone
          WHERE time_zone_code = l_time_zone_code;
      END IF;

      RETURN l_time_zone_id;
   END get_ts_time_zone;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_TSID_TIME_ZONE -
   --
   FUNCTION get_tsid_time_zone (p_ts_id       IN VARCHAR2,
                                p_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_ts_code     NUMBER;
      l_office_id   VARCHAR2 (16)
                       := NVL (p_office_id, cwms_util.user_office_id);
   BEGIN
      BEGIN
         SELECT ts_code
           INTO l_ts_code
           FROM at_cwms_ts_id
          WHERE     UPPER (cwms_ts_id) = UPPER (p_ts_id)
                AND UPPER (db_office_id) = UPPER (l_office_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT ts_code
                 INTO l_ts_code
                 FROM at_cwms_ts_id
                WHERE     UPPER (cwms_ts_id) = UPPER (p_ts_id)
                      AND UPPER (db_office_id) = UPPER (l_office_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  cwms_err.raise ('INVALID_ITEM',
                                  p_ts_id,
                                  'CWMS Timeseries Identifier');
            END;
      END;

      RETURN get_ts_time_zone (l_ts_code);
   END get_tsid_time_zone;


   PROCEDURE set_ts_versioned (p_cwms_ts_code   IN NUMBER,
                               p_versioned      IN VARCHAR2 DEFAULT 'T')
   IS
      l_version_flag         VARCHAR2 (1);
      l_is_versioned         BOOLEAN;
      l_version_date_count   INTEGER;
   BEGIN
      IF p_versioned NOT IN ('T', 'F', 't', 'f')
      THEN
         cwms_err.raise ('ERROR', 'Version flag must be ''T'' or ''F''');
      END IF;

      SELECT version_flag
        INTO l_version_flag
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      l_is_versioned := nvl(l_version_flag, 'F') = 'T';

      IF p_versioned IN ('T', 't') AND NOT l_is_versioned
      THEN
         ------------------------
         -- turn on versioning --
         ------------------------
         UPDATE at_cwms_ts_spec
            SET version_flag = 'T'
          WHERE ts_code = p_cwms_ts_code;
      ELSIF p_versioned IN ('F', 'f') AND l_is_versioned
      THEN
         -------------------------
         -- turn off versioning --
         -------------------------
         SELECT COUNT (version_date)
           INTO l_version_date_count
           FROM av_tsv
          WHERE     ts_code = p_cwms_ts_code
                AND version_date != DATE '1111-11-11';

         IF l_version_date_count = 0
         THEN
            UPDATE at_cwms_ts_spec
               SET version_flag = 'F'
             WHERE ts_code = p_cwms_ts_code;
         ELSE
            cwms_err.raise (
               'ERROR',
               'Cannot turn off versioning for a time series that has versioned data');
         END IF;
      END IF;
   END set_ts_versioned;

   PROCEDURE set_tsid_versioned (p_cwms_ts_id     IN VARCHAR2,
                                 p_versioned      IN VARCHAR2 DEFAULT 'T',
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      set_ts_versioned (get_ts_code (p_cwms_ts_id, p_db_office_id),
                        p_versioned);
   END set_tsid_versioned;

   PROCEDURE is_ts_versioned (p_is_versioned      OUT VARCHAR2,
                              p_cwms_ts_code   IN     NUMBER)
   IS
      l_version_flag   VARCHAR2 (1);
   BEGIN
      SELECT version_flag
        INTO l_version_flag
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      p_is_versioned :=
         case nvl(l_version_flag , 'F')
            when 'T' then 'T'
            else 'F'
         end;
   END is_ts_versioned;

   PROCEDURE is_tsid_versioned (
      p_is_versioned      OUT VARCHAR2,
      p_cwms_ts_id     IN     VARCHAR2,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      is_ts_versioned (p_is_versioned,
                       get_ts_code (p_cwms_ts_id, p_db_office_id));
   END is_tsid_versioned;

   FUNCTION is_tsid_versioned_f (p_cwms_ts_id     IN VARCHAR2,
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_is_versioned   VARCHAR2 (1);
   BEGIN
      is_tsid_versioned (l_is_versioned, p_cwms_ts_id, p_db_office_id);

      RETURN l_is_versioned;
   END is_tsid_versioned_f;

   PROCEDURE get_ts_version_dates (
      p_date_cat       OUT SYS_REFCURSOR,
      p_cwms_ts_code   IN  NUMBER,
      p_start_time     IN  DATE,
      p_end_time       IN  DATE,
      p_time_zone      IN  VARCHAR2 DEFAULT 'UTC')
   IS
      l_start_time DATE;
      l_end_time   DATE;
   BEGIN
      l_start_time := cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC');
      l_end_time   := cwms_util.change_timezone(p_end_time,   p_time_zone, 'UTC');
      OPEN p_date_cat FOR
           SELECT DISTINCT
                  case
                     when version_date = cwms_util.non_versioned then version_date
                     else cwms_util.change_timezone(version_date, 'UTC', p_time_zone)
                  end as version_date
             FROM av_tsv
            WHERE ts_code = p_cwms_ts_code
              AND date_time BETWEEN l_start_time AND l_end_time
         ORDER BY version_date;
   END get_ts_version_dates;

   PROCEDURE get_tsid_version_dates (
      p_date_cat          OUT SYS_REFCURSOR,
      p_cwms_ts_id     IN     VARCHAR2,
      p_start_time     IN     DATE,
      p_end_time       IN     DATE,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC',
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      get_ts_version_dates (p_date_cat,
                            get_ts_code (p_cwms_ts_id, p_db_office_id),
                            p_start_time,
                            p_end_time,
                            p_time_zone);
   END get_tsid_version_dates;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (p_office_id    IN VARCHAR2,
                        p_cwms_ts_id   IN VARCHAR2,
                        p_utc_offset   IN NUMBER DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (p_ts_code      => l_ts_code,
                      p_cwms_ts_id   => p_cwms_ts_id,
                      p_utc_offset   => p_utc_offset,
                      p_office_id    => p_office_id);
   END create_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   PROCEDURE create_ts (p_cwms_ts_id          IN VARCHAR2,
                        p_utc_offset          IN NUMBER DEFAULT NULL,
                        p_interval_forward    IN NUMBER DEFAULT NULL,
                        p_interval_backward   IN NUMBER DEFAULT NULL,
                        p_versioned           IN VARCHAR2 DEFAULT 'F',
                        p_active_flag         IN VARCHAR2 DEFAULT 'T',
                        p_office_id           IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (p_ts_code             => l_ts_code,
                      p_cwms_ts_id          => p_cwms_ts_id,
                      p_utc_offset          => p_utc_offset,
                      p_interval_forward    => p_interval_forward,
                      p_interval_backward   => p_interval_backward,
                      p_versioned           => p_versioned,
                      p_active_flag         => p_active_flag,
                      p_office_id           => p_office_id);
   END create_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_TZ -
   --
   PROCEDURE create_ts_tz (p_cwms_ts_id          IN VARCHAR2,
                           p_utc_offset          IN NUMBER DEFAULT NULL,
                           p_interval_forward    IN NUMBER DEFAULT NULL,
                           p_interval_backward   IN NUMBER DEFAULT NULL,
                           p_versioned           IN VARCHAR2 DEFAULT 'F',
                           p_active_flag         IN VARCHAR2 DEFAULT 'T',
                           p_time_zone_name      IN VARCHAR2 DEFAULT 'UTC',
                           p_office_id           IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (l_ts_code,
                      p_cwms_ts_id,
                      p_utc_offset,
                      p_interval_forward,
                      p_interval_backward,
                      p_versioned,
                      p_active_flag,
                      'F',
                      p_office_id);

      set_ts_time_zone (l_ts_code, p_time_zone_name);
   END create_ts_tz;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_CODE - v2.0 -
   --

   PROCEDURE create_ts_code (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward   IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag         IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists      IN     VARCHAR2 DEFAULT 'T',
      p_office_id           IN     VARCHAR2 DEFAULT NULL)
   IS
      l_office_id             VARCHAR2 (16);
      l_base_location_id      VARCHAR2 (50);
      l_base_location_code    NUMBER;
      l_sub_location_id       VARCHAR2 (50);
      l_base_parameter_id     VARCHAR2 (50);
      l_base_parameter_code   NUMBER;
      l_sub_parameter_id      VARCHAR2 (50);
      l_parameter_code        NUMBER;
      l_parameter_type_id     VARCHAR2 (50);
      l_parameter_type_code   NUMBER;
      l_interval              NUMBER;
      l_interval_id           VARCHAR2 (50);
      l_interval_code         NUMBER;
      l_duration_id           VARCHAR2 (50);
      l_duration              NUMBER;
      l_duration_code         NUMBER;
      l_version               VARCHAR2 (50);
      l_office_code           NUMBER;
      l_location_code         NUMBER;
      l_ret                   NUMBER;
      l_hashcode              NUMBER;
      l_str_error             VARCHAR2 (256);
      l_utc_offset            NUMBER;
      l_all_office_code       NUMBER := cwms_util.db_office_code_all;
      l_ts_id_exists          BOOLEAN := FALSE;
      l_can_create            BOOLEAN := TRUE;
      l_cwms_ts_id            varchar2(191);
      l_parts                 str_tab_t;
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_office_id);
      END IF;


      DBMS_APPLICATION_INFO.set_module ('create_ts_code',
                                        'parse timeseries_desc using regexp');
      ----------------------------------------------
      -- remove any aliases from location portion --
      ----------------------------------------------
      l_parts := cwms_util.split_text(p_cwms_ts_id, '.', 1);
      l_parts(1) := cwms_loc.get_location_id(l_parts(1), p_office_id);
      if l_parts(1) is null then
         l_cwms_ts_id := p_cwms_ts_id;
      else
         l_cwms_ts_id := cwms_util.join_text(l_parts, '.');
      end if;
      --parse values from timeseries_desc using regular expressions
      parse_ts (l_cwms_ts_id,
                l_base_location_id,
                l_sub_location_id,
                l_base_parameter_id,
                l_sub_parameter_id,
                l_parameter_type_id,
                l_interval_id,
                l_duration_id,
                l_version);
      --office codes must exist, if not fail and return error  (prebuilt table, dynamic office addition not allowed)
      DBMS_APPLICATION_INFO.set_action ('check for office_code');

      BEGIN
         SELECT office_code
           INTO l_office_code
           FROM cwms_office o
          WHERE o.office_id = l_office_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_OFFICE_ID', l_office_id);
      END;

      IF l_office_code = 0
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', l_office_id);
      END IF;

      DBMS_APPLICATION_INFO.set_action (
         'check for location_code, create if necessary');
      -- check for valid base_location_code based on id passed in, if not there then create, -
      -- if create error then fail and return -

      cwms_loc.create_location_raw (l_base_location_code,
                                    l_location_code,
                                    l_base_location_id,
                                    l_sub_location_id,
                                    l_office_code);

      IF l_location_code IS NULL
      THEN
         raise_application_error (-20203,
                                  'Unable to generate location_code',
                                  TRUE);
      END IF;

      -- check for valid cwms_code based on id passed in, if not there then create, if create error then fail and return
      DBMS_APPLICATION_INFO.set_action (
         'check for cwms_code, create if necessary');

      --generate hash and lock table for that hash value to serialize ts_create as timeseries_desc is not pkeyed.
      SELECT ORA_HASH (UPPER (l_office_id) || UPPER (p_cwms_ts_id),
                       1073741823)
        INTO l_hashcode
        FROM DUAL;

      l_ret :=
         DBMS_LOCK.request (id                  => l_hashcode,
                            timeout             => 0,
                            lockmode            => DBMS_LOCK.x_mode,
                            release_on_commit   => TRUE);

      IF l_ret > 0
      THEN
         l_can_create := FALSE; -- don't create a ts_code, just retrieve the one we're blocking against.
         DBMS_LOCK.sleep (2);
      END IF;

      -- BEGIN...

      -- determine rest of lookup codes based on passed in values, use scalar subquery to minimize context switches, return error if lookups not found
      DBMS_APPLICATION_INFO.set_action (
         'check code lookups, scalar subquery');

      SELECT (SELECT base_parameter_code
                FROM cwms_base_parameter p
               WHERE UPPER (p.base_parameter_id) =
                        UPPER (l_base_parameter_id))
                p,
             (SELECT duration_code
                FROM cwms_duration d
               WHERE UPPER (d.duration_id) = UPPER (l_duration_id))
                d,
             (SELECT duration
                FROM cwms_duration d
               WHERE UPPER (d.duration_id) = UPPER (l_duration_id))
                dd,
             (SELECT parameter_type_code
                FROM cwms_parameter_type p
               WHERE UPPER (p.parameter_type_id) =
                        UPPER (l_parameter_type_id))
                pt,
             (SELECT interval_code
                FROM cwms_interval i
               WHERE UPPER (i.interval_id) = UPPER (l_interval_id))
                i,
             (SELECT INTERVAL
                FROM cwms_interval ii
               WHERE UPPER (ii.interval_id) = UPPER (l_interval_id))
                ii
        INTO l_base_parameter_code,
             l_duration_code,
	     l_duration,
             l_parameter_type_code,
             l_interval_code,
             l_interval
        FROM DUAL;

      IF    l_base_parameter_code IS NULL
         OR l_duration_code IS NULL
         OR l_parameter_type_code IS NULL
         OR l_interval_code IS NULL
         OR (upper (l_parameter_type_id) =  'INST' AND l_duration <> 0)
         OR (UPPER (l_parameter_type_id) <> 'INST' AND l_duration =  0 AND l_interval <> 0)
      THEN
         l_str_error :=
            'ERROR: Invalid Time Series Description: ' || p_cwms_ts_id;

         IF l_base_parameter_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_base_parameter_id
               || ' is not a valid base parameter';
         END IF;

         IF l_duration_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_duration_id
               || ' is not a valid duration';
         END IF;

         IF l_interval_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_interval_id
               || ' is not a valid interval';
         END IF;

         IF (UPPER (l_parameter_type_id) = 'INST' AND l_duration <> 0)
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || ' Inst parameter type cannot have non-zero duration';
         END IF;

         IF (UPPER (l_parameter_type_id) <> 'INST' AND l_duration = 0 and l_interval <> 0)
         THEN
            l_str_error :=
                  l_str_error
               || chr (10)
               || ' Non-Inst parameter type cannot have zero duration on regular time series';
         END IF;

         IF l_can_create
         THEN
            l_ret := DBMS_LOCK.release (l_hashcode);
         END IF;

         raise_application_error (-20205, l_str_error, TRUE);
      END IF;

      BEGIN
         IF l_sub_parameter_id IS NULL
         THEN
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = l_base_parameter_code
                   AND sub_parameter_id IS NULL
                   AND db_office_code IN (l_office_code, l_all_office_code);
         ELSE
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = l_base_parameter_code
                   AND UPPER (sub_parameter_id) = UPPER (l_sub_parameter_id)
                   AND db_office_code IN (l_office_code, l_all_office_code);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_sub_parameter_id IS NULL
            THEN
               IF l_can_create
               THEN
                  l_ret := DBMS_LOCK.release (l_hashcode);
               END IF;

               cwms_err.RAISE (
                  'GENERIC_ERROR',
                     l_base_parameter_id
                  || ' is not a valid Base Parameter. Cannot Create a new CWMS_TS_ID');
            ELSE                                -- Insert new sub_parameter...
               INSERT INTO at_parameter (parameter_code,
                                         db_office_code,
                                         base_parameter_code,
                                         sub_parameter_id)
                    VALUES (cwms_seq.NEXTVAL,
                            l_office_code,
                            l_base_parameter_code,
                            l_sub_parameter_id)
                 RETURNING parameter_code
                      INTO l_parameter_code;
            END IF;
      END;

      --after all lookups, check for existing ts_code, insert it if not found, and verify that it was inserted with the returning, error if no valid ts_code is returned
      DBMS_APPLICATION_INFO.set_action (
         'check for ts_code, create if necessary');

      BEGIN
         SELECT ts_code
           INTO p_ts_code
           FROM at_cwms_ts_spec acts
          WHERE              /*office_code = l_office_code
                         AND */
               acts .location_code = l_location_code
                AND acts.parameter_code = l_parameter_code
                AND acts.parameter_type_code = l_parameter_type_code
                AND acts.interval_code = l_interval_code
                AND acts.duration_code = l_duration_code
                AND UPPER (NVL (acts.VERSION, 1)) =
                       UPPER (NVL (l_version, 1))
                AND acts.delete_date IS NULL;

         --
         l_ts_id_exists := TRUE;

         IF l_can_create
         THEN
            l_ret := DBMS_LOCK.release (l_hashcode);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_can_create
            THEN
               IF l_interval = 0
               THEN
                  l_utc_offset := cwms_util.utc_offset_irregular;
               ELSE
                  l_utc_offset := cwms_util.utc_offset_undefined;

                  IF p_utc_offset IS NOT NULL
                  THEN
                     IF p_utc_offset = cwms_util.utc_offset_undefined
                     THEN
                        NULL;
                     ELSIF p_utc_offset >= 0 AND p_utc_offset < l_interval
                     THEN
                        l_utc_offset := p_utc_offset;
                     ELSE
                        COMMIT;
                        cwms_err.RAISE ('INVALID_UTC_OFFSET',
                                        p_utc_offset,
                                        l_interval_id);
                     END IF;
                  END IF;
               END IF;

               IF p_interval_forward < 0 OR p_interval_forward >= l_interval
               THEN
                  COMMIT;
                  cwms_err.raise (
                     'ERROR',
                        'Interval forward ('
                     || p_interval_forward
                     || ') must be >= 0 and < interval ('
                     || l_interval
                     || ')');
               END IF;

               IF    p_interval_backward < 0
                  OR p_interval_backward >= l_interval
               THEN
                  COMMIT;
                  cwms_err.raise (
                     'ERROR',
                        'Interval backward ('
                     || p_interval_backward
                     || ') must be >= 0 and < interval ('
                     || l_interval
                     || ')');
               END IF;

               IF p_interval_forward + p_interval_backward >= l_interval
               THEN
                  COMMIT;
                  cwms_err.raise (
                     'ERROR',
                        'Interval backward ('
                     || p_interval_backward
                     || ') plus interval forward ('
                     || p_interval_forward
                     || ') must be < interval ('
                     || l_interval
                     || ')');
               END IF;

               IF UPPER (p_active_flag) NOT IN ('T', 'F')
               THEN
                  COMMIT;
                  cwms_err.raise ('ERROR',
                                  'Active flag must be ''T'' or ''F''');
               END IF;

               IF UPPER (p_versioned) NOT IN ('T', 'F')
               THEN
                  COMMIT;
                  cwms_err.raise ('ERROR',
                                  'Versioned flag must be ''T'' or ''F''');
               END IF;

               INSERT INTO at_cwms_ts_spec t (ts_code,
                                              location_code,
                                              parameter_code,
                                              parameter_type_code,
                                              interval_code,
                                              duration_code,
                                              VERSION,
                                              interval_utc_offset,
                                              interval_forward,
                                              interval_backward,
                                              version_flag,
                                              active_flag)
                    VALUES (
                              cwms_seq.NEXTVAL,
                              l_location_code,
                              l_parameter_code,
                              l_parameter_type_code,
                              l_interval_code,
                              l_duration_code,
                              l_version,
                              l_utc_offset,
                              p_interval_forward,
                              p_interval_backward,
                              UPPER (p_versioned),
                              UPPER (p_active_flag))
                 RETURNING ts_code
                      INTO p_ts_code;

               ---------------------------------
               -- Publish a TSCreated message --
               ---------------------------------
               DECLARE
                  l_msg     SYS.aq$_jms_map_message;
                  l_msgid   PLS_INTEGER;
                  i         INTEGER;
               BEGIN
                  cwms_msg.new_message (l_msg, l_msgid, 'TSCreated');
                  l_msg.set_string (l_msgid, 'ts_id', p_cwms_ts_id);
                  l_msg.set_string (l_msgid, 'office_id', l_office_id);
                  l_msg.set_long (l_msgid, 'ts_code', p_ts_code);
                  i :=
                     cwms_msg.publish_message (l_msg,
                                               l_msgid,
                                               l_office_id || '_ts_stored');
               END;

               COMMIT;
            END IF;
      END;

      IF p_ts_code IS NULL
      THEN
         raise_application_error (-20204,
                                  'Unable to generate timeseries_code',
                                  TRUE);
      ELSIF l_ts_id_exists
      THEN
         IF UPPER (p_fail_if_exists) != 'F'
         THEN
            cwms_err.RAISE ('TS_ALREADY_EXISTS', p_cwms_ts_id);
         END IF;
      END IF;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END create_ts_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_CODE_TZ - v2.0 -
   --
   PROCEDURE create_ts_code_tz (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward   IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag         IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists      IN     VARCHAR2 DEFAULT 'T',
      p_time_zone_name      IN     VARCHAR2 DEFAULT 'UTC',
      p_office_id           IN     VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (l_ts_code,
                      p_cwms_ts_id,
                      p_utc_offset,
                      p_interval_forward,
                      p_interval_backward,
                      p_versioned,
                      p_active_flag,
                      p_fail_if_exists,
                      p_office_id);

      set_ts_time_zone (l_ts_code, p_time_zone_name);
      p_ts_code := l_ts_code;
   END create_ts_code_tz;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- tz_offset_at_gmt
   --
   FUNCTION tz_offset_at_gmt (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN INTEGER
   IS
      l_offset          INTEGER := 0;
      l_tz_offset_str   VARCHAR2 (8)
                           := RTRIM (TZ_OFFSET (p_tz_name), CHR (0));
      l_ts_utc          TIMESTAMP;
      l_ts_loc          TIMESTAMP;
      l_hours           INTEGER;
      l_minutes         INTEGER;
      l_parts           str_tab_t;
   BEGIN
      IF l_tz_offset_str != '+00:00' AND l_tz_offset_str != '-00:00'
      THEN
         l_parts := cwms_util.split_text (l_tz_offset_str, ':');
         l_hours := TO_NUMBER (l_parts (1));
         l_minutes := TO_NUMBER (l_parts (2));

         IF l_hours < 0
         THEN
            l_minutes := l_hours * 60 - l_minutes;
         ELSE
            l_minutes := l_hours * 60 + l_minutes;
         END IF;

         l_ts_utc := CAST (p_date_time AS TIMESTAMP);
         l_ts_loc := FROM_TZ (l_ts_utc, 'UTC') AT TIME ZONE p_tz_name;
         l_offset :=
              l_minutes
            - ROUND (
                   (  cwms_util.to_millis (l_ts_loc)
                    - cwms_util.to_millis (l_ts_utc))
                 / 60000);
      END IF;

      RETURN l_offset;
   END;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- shift_for_localtime
   --
   FUNCTION shift_for_localtime (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      RETURN p_date_time + tz_offset_at_gmt (p_date_time, p_tz_name) / 1440;
   END shift_for_localtime;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- setup_retrieve
   --
   PROCEDURE setup_retrieve (p_start_time        IN OUT DATE,
                             p_end_time          IN OUT DATE,
                             p_reg_start_time       OUT DATE,
                             p_reg_end_time         OUT DATE,
                             p_ts_code           IN     NUMBER,
                             p_interval          IN     NUMBER,
                             p_offset            IN     NUMBER,
                             p_start_inclusive   IN     BOOLEAN,
                             p_end_inclusive     IN     BOOLEAN,
                             p_previous          IN     BOOLEAN,
                             p_next              IN     BOOLEAN,
                             p_trim              IN     BOOLEAN)
   IS
      l_start_time   DATE := p_start_time;
      l_end_time     DATE := p_end_time;
      l_temp_time    DATE;
   BEGIN
      --
      -- handle inclusive/exclusive by adjusting start/end times inward
      --
      IF NOT p_start_inclusive
      THEN
         l_start_time := l_start_time + 1 / 86400;
      END IF;

      IF NOT p_end_inclusive
      THEN
         l_end_time := l_end_time - 1 / 86400;
      END IF;

      --
      -- handle previous/next by adjusting start/end times outward
      --
      IF p_previous
      THEN
         IF p_interval = 0
         THEN
            SELECT MAX (date_time)
              INTO l_temp_time
              FROM av_tsv
             WHERE     ts_code = p_ts_code
                   AND date_time < l_start_time
                   AND start_date <= l_end_time;

            IF l_temp_time IS NOT NULL
            THEN
               l_start_time := l_temp_time;
            END IF;
         ELSE
            l_start_time := l_start_time - p_interval / 1440;
         END IF;
      END IF;

      IF p_next
      THEN
         IF p_interval = 0
         THEN
            SELECT MIN (date_time)
              INTO l_temp_time
              FROM av_tsv
             WHERE     ts_code = p_ts_code
                   AND date_time > l_end_time
                   AND end_date > l_start_time;

            IF l_temp_time IS NOT NULL
            THEN
               l_end_time := l_temp_time;
            END IF;
         ELSE
            l_end_time := l_end_time + p_interval / 1440;
         END IF;
      END IF;

      --
      -- handle trim by adjusting start/end times inward to first/last
      -- non-missing values
      --
      IF p_trim
      THEN
         SELECT MIN (date_time), MAX (date_time)
           INTO l_start_time, l_end_time
           FROM (SELECT date_time
                   FROM av_tsv v, cwms_data_quality q
                  WHERE     v.ts_code = p_ts_code
                        AND v.date_time BETWEEN l_start_time AND l_end_time
                        AND v.start_date <= l_end_time
                        AND v.end_date > l_start_time
                        AND v.quality_code = q.quality_code
                        AND q.validity_id != 'MISSING'
                        AND v.VALUE IS NOT NULL);
      END IF;

      --
      -- set the out parameters
      --
      p_start_time := l_start_time;
      p_end_time := l_end_time;

      IF p_interval = 0
      THEN
         --
         -- These parameters are used to generate a regular time series from which
         -- to fill in the times of missing values.  In the case of irregular time
         -- series, set them so that they will not generate a time series at all.
         --
         p_reg_start_time := NULL;
         p_reg_end_time := NULL;
      ELSE
         IF p_offset = cwms_util.utc_offset_undefined
         THEN
            p_reg_start_time :=
               get_time_on_after_interval (l_start_time, NULL, p_interval);
            p_reg_end_time :=
               get_time_on_before_interval (l_end_time, NULL, p_interval);
         ELSE
            p_reg_start_time :=
               get_time_on_after_interval (l_start_time,
                                           p_offset,
                                           p_interval);
            p_reg_end_time :=
               get_time_on_before_interval (l_end_time, p_offset, p_interval);
         END IF;
      END IF;
   END setup_retrieve;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- BUILD_RETRIEVE_TS_QUERY - v2.0 -
   --
   FUNCTION build_retrieve_ts_query (
      p_cwms_ts_id_out       OUT VARCHAR2,
      p_units_out            OUT VARCHAR2,
      p_cwms_ts_id        IN     VARCHAR2,
      p_units             IN     VARCHAR2,
      p_start_time        IN     DATE,
      p_end_time          IN     DATE,
      p_date_time_type    IN     VARCHAR2,
      p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
      p_trim              IN     VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_previous          IN     VARCHAR2 DEFAULT 'F',
      p_next              IN     VARCHAR2 DEFAULT 'F',
      p_version_date      IN     DATE DEFAULT NULL,
      p_max_version       IN     VARCHAR2 DEFAULT 'T',
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
      RETURN SYS_REFCURSOR
   IS
      l_ts_code           NUMBER;
      l_location_code     NUMBER;
      l_interval          NUMBER;
      l_interval2         NUMBER := 60 / 1440;
      l_utc_offset        NUMBER;
      l_office_id         VARCHAR2 (16);
      l_cwms_ts_id        VARCHAR2(191);
      l_units             VARCHAR2 (16);
      l_time_zone         VARCHAR2 (28);
      l_base_parameter_id VARCHAR2(16);
      l_trim              BOOLEAN;
      l_start_inclusive   BOOLEAN;
      l_end_inclusive     BOOLEAN;
      l_previous          BOOLEAN;
      l_next              BOOLEAN;
      l_start_time        DATE;
      l_end_time          DATE;
      l_version_date      DATE;
      l_reg_start_time    DATE;
      l_reg_end_time      DATE;
      l_max_version       BOOLEAN;
      l_query_str         VARCHAR2 (32767);
      l_start_str         VARCHAR2 (32);
      l_end_str           VARCHAR2 (32);
      l_reg_start_str     VARCHAR2 (32);
      l_reg_end_str       VARCHAR2 (32);
      l_missing           NUMBER := 5;                 -- MISSING quality code
      l_date_format       VARCHAR2 (32) := 'yyyy/mm/dd-hh24.mi.ss';
      l_cursor            SYS_REFCURSOR;
      l_strict_times      BOOLEAN := FALSE;
      l_value_offset      binary_double := 0;

      PROCEDURE set_action (text IN VARCHAR2)
      IS
      BEGIN
         DBMS_APPLICATION_INFO.set_action (text);
         --DBMS_OUTPUT.put_line (text);
      END;

      PROCEDURE replace_strings
      IS
      BEGIN
         l_query_str := REPLACE (l_query_str, ':tz', l_time_zone);
         l_query_str :=
            REPLACE (l_query_str, ':date_time_type', p_date_time_type);

         IF l_max_version
         THEN
            l_query_str := REPLACE (l_query_str, ':first_or_last', 'last');
         ELSE
            l_query_str := REPLACE (l_query_str, ':first_or_last', 'first');
         END IF;
      END;
   BEGIN
      --------------------
      -- initialization --
      --------------------
      l_office_id := NVL (p_office_id, cwms_util.user_office_id);
      l_cwms_ts_id := get_cwms_ts_id (p_cwms_ts_id, l_office_id);
      l_units := NVL (cwms_util.get_unit_id(p_units, l_Office_id), get_db_unit_id (l_cwms_ts_id));
      l_time_zone := NVL (p_time_zone, 'UTC');

      IF SUBSTR (l_time_zone, 1, 1) = '!'
      THEN
         l_strict_times := TRUE;
         l_time_zone := SUBSTR (l_time_zone, 2);
      END IF;

      l_time_zone := cwms_util.get_time_zone_name (l_time_zone);
      l_trim := cwms_util.return_true_or_false (NVL (p_trim, 'F'));
      l_start_inclusive :=
         cwms_util.return_true_or_false (NVL (p_start_inclusive, 'T'));
      l_end_inclusive :=
         cwms_util.return_true_or_false (NVL (p_end_inclusive, 'T'));
      l_previous := cwms_util.return_true_or_false (NVL (p_previous, 'F'));
      l_next := cwms_util.return_true_or_false (NVL (p_next, 'F'));
      l_start_time :=
         cwms_util.change_timezone (p_start_time, l_time_zone, 'UTC');
      l_end_time := cwms_util.change_timezone (p_end_time, l_time_zone, 'UTC');
      l_version_date :=
         cwms_util.change_timezone (p_version_date, l_time_zone, 'UTC');
      l_max_version :=
         cwms_util.return_true_or_false (NVL (p_max_version, 'F'));
      --
      -- set the out parameters
      --
      p_cwms_ts_id_out := l_cwms_ts_id;
      p_units_out      := l_units;

      --
      -- allow cwms_util.non_versioned to be used regarless of time zone
      --
      IF p_version_date = cwms_util.non_versioned
      THEN
         l_version_date := cwms_util.non_versioned;
      END IF;

      --
      -- get ts code
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.build_retrieve_ts_query',
                                        'Get TS Code');

      BEGIN
         select ts_code,
                interval,
                interval_utc_offset,
                base_parameter_id,
                location_code
           into l_ts_code,
                l_interval,
                l_utc_offset,
                l_base_parameter_id,
                l_location_code
           from at_cwms_ts_id
          where upper(db_office_id) = upper(l_office_id)
            and upper(cwms_ts_id) = upper(p_cwms_ts_id_out);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               select ts_code,
                      interval,
                      interval_utc_offset,
                      base_parameter_id,
                      location_code
                 into l_ts_code,
                      l_interval,
                      l_utc_offset,
                      l_base_parameter_id,
                      l_location_code
                 from at_cwms_ts_id
                where upper(db_office_id) = upper(l_office_id)
                  and upper(cwms_ts_id) = upper(p_cwms_ts_id_out);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  cwms_err.raise('TS_ID_NOT_FOUND', l_cwms_ts_id, l_office_id);
            END;
      END;

      if l_base_parameter_id = 'Elev' then
         l_value_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_units);
      end if;

      set_action ('Handle start and end times');
      setup_retrieve (l_start_time,
                      l_end_time,
                      l_reg_start_time,
                      l_reg_end_time,
                      l_ts_code,
                      l_interval,
                      l_utc_offset,
                      l_start_inclusive,
                      l_end_inclusive,
                      l_previous,
                      l_next,
                      l_trim);
      --
      -- change interval from minutes to days
      --
      l_interval := l_interval / 1440;

      IF l_interval > 0
      THEN
         l_reg_start_str := TO_CHAR (l_reg_start_time, l_date_format);
         l_reg_end_str := TO_CHAR (l_reg_end_time, l_date_format);
      END IF;

      l_start_str := TO_CHAR (l_start_time, l_date_format);
      l_end_str := TO_CHAR (l_end_time, l_date_format);

      --
      -- build the query string - for some reason the time zone must be a
      -- string literal and bind variables are problematic
      --
      IF l_version_date IS NULL
      THEN
         --
         -- min or max version date
         --
         IF l_interval > 0
         THEN
            --
            -- regular time series
            --
            IF MOD (l_interval, 30) = 0 OR MOD (l_interval, 365) = 0
            THEN
               --
               -- must use calendar math
               --
               -- change interval from days to months
               --
               IF MOD (l_interval, 30) = 0
               THEN
                  l_interval := l_interval / 30;
               ELSE
                  l_interval := l_interval / 365 * 12;
               END IF;

               l_query_str :=
                  'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      case
                         when value is nan then null
                         else value + :l_value_offset
                      end "VALUE",
                      cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                 from (
                      select date_time,
                             max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                             max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                        from av_tsv_dqu
                       where ts_code    =  :ts_code
                         and date_time  >= to_date(:l_start, :l_date_fmt)
                         and date_time  <= to_date(:l_end,   :l_date_fmt)
                         and unit_id    =  :units
                         and start_date <= to_date(:l_end,   :l_date_fmt)
                         and end_date   >  to_date(:l_start, :l_date_fmt)
                    group by date_time
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(add_months(to_date(:reg_start, :l_date_fmt), (level-1) * :interval), :l_time_zone) date_time
                        from dual
                       where to_date(:reg_start, :l_date_format) is not null
                  connect by level <= months_between(to_date(:reg_end,   :l_date_format),
                                                     to_date(:reg_start, :l_date_format)) / :interval + 1
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_missing,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_reg_start_str,
                        l_date_format,
                        l_interval,
                        l_time_zone,
                        l_reg_start_str,
                        l_date_format,
                        l_reg_end_str,
                        l_date_format,
                        l_reg_start_str,
                        l_date_format,
                        l_interval;
            ELSE
               --
               -- can use date arithmetic
               --
               IF l_strict_times
               THEN
                  l_query_str :=
                     'select date_time,
                          case
                             when value is nan then null
                             else value + :l_value_offset
                          end "VALUE",
                          cwms_ts.normalize_quality(quality_code) as quality_code
                     from ((select cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                                  value,
                                  quality_code
                             from (select t.date_time as date_time,
                                          case
                                             when value is nan then null
                                             else value
                                          end as value,
                                          nvl(quality_code, :missing) as quality_code
                                     from (
                                          select date_time,
                                                 max(value) keep(dense_rank :first_or_last order by version_date) as value,
                                                 max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                                            from av_tsv_dqu
                                           where ts_code    =  :ts_code
                                             and date_time  >= to_date(:l_start, :l_date_fmt)
                                             and date_time  <= to_date(:l_end,   :l_date_fmt)
                                             and unit_id    =  :units
                                             and start_date <= to_date(:l_end,   :l_date_fmt)
                                             and end_date   >  to_date(:l_start, :l_date_fmt)
                                        group by date_time
                                          ) v
                                          right outer join
                                          (
                                          select max(date_time) date_time
                                            from (select date_time,
                                                         cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                                                    from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                                            from dual
                                                      connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                               - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                                         )
                                                 )
                                         group by local_time
                                          ) t
                                          on v.date_time = t.date_time
                                  )
                           )
                           union all
                           (select date_time,
                                   null as value,
                                   :missing as quality_code
                              from (select prev_time + (level + :interval2 / :interval - 1) * :interval as date_time,
                                           level as level_count
                                      from (select date_time,
                                                   prev_time
                                              from (select date_time,
                                                           lag(date_time, 1, null) over (order by date_time) as prev_time,
                                                           date_time - lag(date_time, 1, null) over (order by date_time) as time_diff
                                                      from (select cwms_util.change_timezone(to_date(:reg_start, :l_date_fmt) + (level-1) * :interval2, ''UTC'', :l_timezone) as date_time
                                                              from dual
                                                   connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                            - to_date(:reg_start, :l_date_fmt)) / :interval2 + 1)
                                                           )
                                                   )
                                             where time_diff > greatest(:interval, :interval2)
                                          order by date_time
                                           )
                               connect by level < (date_time - prev_time) / :interval
                                   )
                             where level_count <= round(:interval2 / :interval)
                           ))
                 order by date_time';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);

                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_missing,
                           l_interval2,
                           l_interval,
                           l_interval,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_time_zone,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval;
               ELSE
                  l_query_str :=
                     'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                             case
                                when value is nan then null
                                else value + :l_value_offset
                             end "VALUE",
                             cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                        from (
                             select date_time,
                                    max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                                    max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                               from av_tsv_dqu
                              where ts_code    =  :ts_code
                                and date_time  >= to_date(:l_start, :l_date_fmt)
                                and date_time  <= to_date(:l_end,   :l_date_fmt)
                                and unit_id    =  :units
                                and start_date <= to_date(:l_end,   :l_date_fmt)
                                and end_date   >  to_date(:l_start, :l_date_fmt)
                              group by date_time
                             ) v
                             right outer join
                            (select date_time,
                                    cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                               from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                       from dual
                                 connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                          - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                    )
                             ) t
                             on v.date_time = t.date_time
                       order by t.date_time asc';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);

                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval;
               END IF;
            END IF;
         ELSE
            --
            -- irregular time series
            --
            IF l_strict_times
            THEN
               l_query_str :=
                  'select cast(from_tz(cast(max(date_time) as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                       max(value) keep(dense_rank last order by date_time) + :l_value_offset as value,
                       cwms_ts.normalize_quality(max(quality_code) keep(dense_rank last order by date_time)) as quality_code
                  from (select date_time,
                               cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) as local_time,
                               case
                                  when max(value) keep(dense_rank :first_or_last order by version_date) is nan then null
                                  else max(value) keep(dense_rank :first_or_last order by version_date)
                               end as value,
                               max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                          from av_tsv_dqu
                         where ts_code    =  :ts_code
                           and date_time  >= to_date(:l_start, :l_date_fmt)
                           and date_time  <= to_date(:l_end,   :l_date_fmt)
                           and unit_id    =  :units
                           and start_date <= to_date(:l_end,   :l_date_fmt)
                           and end_date   >  to_date(:l_start, :l_date_fmt)
                      group by date_time
                      )
                group by local_time
                order by local_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_time_zone,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format;
            ELSE
               l_query_str :=
               'select local_time as date_time,
                       case
                         when value is nan then null
                         else value + :l_value_offset
                       end "VALUE",
                       cwms_ts.normalize_quality(quality_code) as quality_code
                  from (select date_time,
                               cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as local_time,
                               case
                                  when max(value) keep(dense_rank :first_or_last order by version_date) is nan then null
                                  else max(value) keep(dense_rank :first_or_last order by version_date)
                               end as value,
                               max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                          from av_tsv_dqu
                         where ts_code    =  :ts_code
                           and date_time  >= to_date(:l_start, :l_date_fmt)
                           and date_time  <= to_date(:l_end,   :l_date_fmt)
                           and unit_id    =  :units
                           and start_date <= to_date(:l_end,   :l_date_fmt)
                           and end_date   >  to_date(:l_start, :l_date_fmt)
                         group by date_time
                       )
                 order by date_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format;
            END IF;
         END IF;
      ELSE
         --
         -- specified version date
         --
         IF l_interval > 0
         THEN
            --
            -- regular time series
            --
            IF MOD (l_interval, 30) = 0 OR MOD (l_interval, 365) = 0
            THEN
               --
               -- must use calendar math
               --
               -- change interval from days to months
               --
               IF MOD (l_interval, 30) = 0
               THEN
                  l_interval := l_interval / 30;
               ELSE
                  l_interval := l_interval / 365 * 12;
               END IF;

               l_query_str :=
                  'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      case
                         when value is nan then null
                         else value + :l_value_offset
                      end "VALUE",
                      cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                 from (
                      select date_time,
                             value,
                             quality_code
                        from av_tsv_dqu
                       where ts_code      =  :ts_code
                         and date_time    >= to_date(:l_start,   :l_date_fmt)
                         and date_time    <= to_date(:l_end,     :l_date_fmt)
                         and unit_id      =  :units
                         and start_date   <= to_date(:l_end,     :l_date_fmt)
                         and end_date     >  to_date(:l_start,   :l_date_fmt)
                         and version_date =  :version
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(add_months(to_date(:reg_start, :l_date_format), (level-1) * :interval), :tz) date_time
                        from dual
                       where to_date(:reg_start, :l_date_format) is not null
                  connect by level <= months_between(to_date(:reg_start, :l_date_format),
                                                     to_date(:reg_end,   :l_date_format)) / :interval + 1)
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_missing,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_version_date,
                        l_reg_start_str,
                        l_date_format,
                        l_interval,
                        l_time_zone,
                        l_reg_start_str,
                        l_date_format,
                        l_reg_start_str,
                        l_date_format,
                        l_reg_end_str,
                        l_date_format,
                        l_interval;
            ELSE
               --
               -- can use date arithmetic
               --
               IF l_strict_times
               THEN
                  l_query_str :=
                  'select date_time,
                          case
                             when value is nan then null
                             else value + :l_value_offset
                          end "VALUE",
                          cwms_ts.normalize_quality(quality_code) as quality_code
                     from ((select cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                                  value,
                                  quality_code
                             from (select t.date_time as date_time,
                                          case
                                             when value is nan then null
                                             else value
                                          end as value,
                                          nvl(quality_code, :missing) as quality_code
                                     from (
                                          select date_time,
                                                 value,
                                                 quality_code
                                            from av_tsv_dqu
                                           where ts_code     =  :ts_code
                                             and date_time   >= to_date(:l_start, :l_date_fmt)
                                             and date_time   <= to_date(:l_end,   :l_date_fmt)
                                             and unit_id     =  :units
                                             and start_date  <= to_date(:l_end,   :l_date_fmt)
                                             and end_date    >  to_date(:l_start, :l_date_fmt)
                                             and version_date = :version
                                          ) v
                                          right outer join
                                          (
                                          select max(date_time) date_time
                                            from (select date_time,
                                                         cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                                                    from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                                            from dual
                                                      connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                               - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                                         )
                                                 )
                                         group by local_time
                                          ) t
                                          on v.date_time = t.date_time
                                  )
                           )
                           union all
                           (select date_time,
                                   null as value,
                                   :missing as quality_code
                              from (select prev_time + (level + :interval2 / :interval - 1) * :interval as date_time,
                                           level as level_count
                                      from (select date_time,
                                                   prev_time
                                              from (select date_time,
                                                           lag(date_time, 1, null) over (order by date_time) as prev_time,
                                                           date_time - lag(date_time, 1, null) over (order by date_time) as time_diff
                                                      from (select cwms_util.change_timezone(to_date(:reg_start, :l_date_fmt) + (level-1) * :interval2, ''UTC'', :l_timezone) as date_time
                                                              from dual
                                                   connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                            - to_date(:reg_start, :l_date_fmt)) / :interval2 + 1)
                                                           )
                                                   )
                                             where time_diff > greatest(:interval, :interval2)
                                          order by date_time
                                           )
                               connect by level < (date_time - prev_time) / :interval
                                   )
                             where level_count <= round(:interval2 / :interval)
                           ))
                 order by date_time';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);

                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_version_date,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_missing,
                           l_interval2,
                           l_interval,
                           l_interval,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_time_zone,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval;
               ELSE
                  l_query_str :=
                  'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                          case
                             when value is nan then null
                             else value + :l_value_offset
                          end "VALUE",
                          cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                     from (
                          select date_time,
                                 max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                                 max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                            from av_tsv_dqu
                           where ts_code     =  :ts_code
                             and date_time   >= to_date(:l_start, :l_date_fmt)
                             and date_time   <= to_date(:l_end,   :l_date_fmt)
                             and unit_id     =  :units
                             and start_date  <= to_date(:l_end,   :l_date_fmt)
                             and end_date    >  to_date(:l_start, :l_date_fmt)
                             and version_date = :version
                           group by date_time
                          ) v
                          right outer join
                          (select date_time,
                                  cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                             from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                     from dual
                               connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                        - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                  )
                          ) t
                          on v.date_time = t.date_time
                    order by t.date_time asc';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);
                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_version_date,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval;
               END IF;
            END IF;
         ELSE
            --
            -- irregular time series
            --
            IF l_strict_times
            THEN
               l_query_str :=
                  'select cast(from_tz(cast(max(date_time) as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                       max(value) keep(dense_rank last order by date_time) + :l_value_offset as value,
                       cwms_ts.normalize_quality(max(quality_code) keep(dense_rank last order by date_time)) as quality_code
                  from (select date_time,
                               cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) as local_time,
                               case
                                  when value is nan then null
                                  else value
                               end as value,
                               quality_code
                          from av_tsv_dqu
                         where ts_code     =  :ts_code
                           and date_time   >= to_date(:l_start, :l_date_fmt)
                           and date_time   <= to_date(:l_end,   :l_date_fmt)
                           and unit_id     =  :units
                           and start_date  <= to_date(:l_end,   :l_date_fmt)
                           and end_date    >  to_date(:l_start, :l_date_fmt)
                           and version_date = :version
                      )
             group by local_time
             order by local_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_time_zone,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_version_date;
            ELSE
               l_query_str :=
                'select local_time as date_time,
                        case
                          when value is nan then null
                          else value + :l_value_offset
                       end "VALUE",
                       cwms_ts.normalize_quality(quality_code) as quality_code
                  from (select date_time,
                               cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as local_time,
                               case
                                  when max(value) keep(dense_rank :first_or_last order by version_date) is nan then null
                                  else max(value) keep(dense_rank :first_or_last order by version_date)
                               end as value,
                               max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                          from av_tsv_dqu
                         where ts_code     =  :ts_code
                           and date_time   >= to_date(:l_start, :l_date_fmt)
                           and date_time   <= to_date(:l_end,   :l_date_fmt)
                           and unit_id     =  :units
                           and start_date  <= to_date(:l_end,   :l_date_fmt)
                           and end_date    >  to_date(:l_start, :l_date_fmt)
                           and version_date = :version
                         group by date_time
                       )
                 order by date_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_version_date;
            END IF;
         END IF;
      END IF;

      RETURN l_cursor;
   END build_retrieve_ts_query;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_OUT - v2.0 -
   --
   PROCEDURE retrieve_ts_out (
      p_at_tsv_rc            OUT SYS_REFCURSOR,
      p_cwms_ts_id_out       OUT VARCHAR2,
      p_units_out            OUT VARCHAR2,
      p_cwms_ts_id        IN     VARCHAR2,
      p_units             IN     VARCHAR2,
      p_start_time        IN     DATE,
      p_end_time          IN     DATE,
      p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
      p_trim              IN     VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_previous          IN     VARCHAR2 DEFAULT 'F',
      p_next              IN     VARCHAR2 DEFAULT 'F',
      p_version_date      IN     DATE DEFAULT NULL,
      p_max_version       IN     VARCHAR2 DEFAULT 'T',
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      l_query_str   VARCHAR2 (4000);

      PROCEDURE set_action (text IN VARCHAR2)
      IS
      BEGIN
         DBMS_APPLICATION_INFO.set_action (text);
         -- DBMS_OUTPUT.put_line (text);
      END;
   BEGIN
      --
      -- Get the query string
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts',
                                        'Get query string');

      p_at_tsv_rc :=
         build_retrieve_ts_query (p_cwms_ts_id_out,
                                  p_units_out,
                                  p_cwms_ts_id,
                                  p_units,
                                  p_start_time,
                                  p_end_time,
                                  'date',
                                  p_time_zone,
                                  p_trim,
                                  p_start_inclusive,
                                  p_end_inclusive,
                                  p_previous,
                                  p_next,
                                  p_version_date,
                                  p_max_version,
                                  p_office_id);

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END retrieve_ts_out;

   --*******************************************************************   --

   FUNCTION retrieve_ts_out_tab (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_start_time        IN DATE,
      p_end_time          IN DATE,
      p_time_zone         IN VARCHAR2 DEFAULT 'UTC',
      p_trim              IN VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN VARCHAR2 DEFAULT 'T',
      p_previous          IN VARCHAR2 DEFAULT 'F',
      p_next              IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT NULL,
      p_max_version       IN VARCHAR2 DEFAULT 'T',
      p_office_id         IN VARCHAR2 DEFAULT NULL)
      RETURN zts_tab_t
      PIPELINED
   IS
      query_cursor       SYS_REFCURSOR;
      output_row         zts_rec_t;
      l_cwms_ts_id_out   VARCHAR2(191);
      l_units_out        VARCHAR2 (16);
   BEGIN
      retrieve_ts_out (p_at_tsv_rc         => query_cursor,
                       p_cwms_ts_id_out    => l_cwms_ts_id_out,
                       p_units_out         => l_units_out,
                       p_cwms_ts_id        => p_cwms_ts_id,
                       p_units             => p_units,
                       p_start_time        => p_start_time,
                       p_end_time          => p_end_time,
                       p_time_zone         => p_time_zone,
                       p_trim              => p_trim,
                       p_start_inclusive   => p_start_inclusive,
                       p_end_inclusive     => p_end_inclusive,
                       p_previous          => p_previous,
                       p_next              => p_next,
                       p_version_date      => p_version_date,
                       p_max_version       => p_max_version,
                       p_office_id         => p_office_id);

      LOOP
         FETCH query_cursor INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END retrieve_ts_out_tab;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS - v1.4 -
   --
   PROCEDURE retrieve_ts (
      p_at_tsv_rc     IN OUT SYS_REFCURSOR,
      p_units         IN     VARCHAR2,
      p_officeid      IN     VARCHAR2,
      p_cwms_ts_id    IN     VARCHAR2,
      p_start_time    IN     DATE,
      p_end_time      IN     DATE,
      p_timezone      IN     VARCHAR2 DEFAULT 'GMT',
      p_trim          IN     NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN     NUMBER DEFAULT NULL,
      p_versiondate   IN     DATE DEFAULT NULL,
      p_max_version   IN     NUMBER DEFAULT cwms_util.true_num)
   IS
      l_trim          VARCHAR2 (1);
      l_max_version   VARCHAR2 (1);
      l_query_str     VARCHAR2 (4000);
      l_tsid          VARCHAR2(191);
      l_unit          VARCHAR2 (16);

      PROCEDURE set_action (text IN VARCHAR2)
      IS
      BEGIN
         DBMS_APPLICATION_INFO.set_action (text);
         -- DBMS_OUTPUT.put_line (text);
      END;
   BEGIN
      --
      -- handle input parameters
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts',
                                        'Handle input parameters');

      IF p_trim IS NULL OR p_trim = cwms_util.false_num
      THEN
         l_trim := 'F';
      ELSIF p_trim = cwms_util.true_num
      THEN
         l_trim := 'T';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_trim);
      END IF;

      IF p_max_version IS NULL OR p_max_version = cwms_util.true_num
      THEN
         l_max_version := 'T';
      ELSIF p_max_version = cwms_util.false_num
      THEN
         l_max_version := 'F';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_max_version);
      END IF;

      --
      -- Get the query string
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts',
                                        'Get query string');

      p_at_tsv_rc :=
         build_retrieve_ts_query (l_tsid,                  -- p_cwms_ts_id_out
                                  l_unit,                       -- p_units_out
                                  p_cwms_ts_id,                -- p_cwms_ts_id
                                  p_units,                          -- p_units
                                  p_start_time,                -- p_start_time
                                  p_end_time,                    -- p_end_time
                                  'timestamp with time zone', -- p_date_time_type
                                  p_timezone,                   -- p_time_zone
                                  l_trim,                            -- p_trim
                                  'T',                    -- p_start_inclusive
                                  'T',                      -- p_end_inclusive
                                  'F',                           -- p_previous
                                  'F',                               -- p_next
                                  p_versiondate,             -- p_version_date
                                  l_max_version,              -- p_max_version
                                  p_officeid);                  -- p_office_id

      --l_query_str := replace(l_query_str, ':date_time_type', 'timestamp with time zone');
      --
      -- open the cursor
      --
      --set_action('Open cursor');
      --open p_at_tsv_rc for l_query_str;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END retrieve_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_2 - v1.4 -
   --
   PROCEDURE retrieve_ts_2 (
      p_at_tsv_rc        OUT SYS_REFCURSOR,
      p_units         IN     VARCHAR2,
      p_officeid      IN     VARCHAR2,
      p_cwms_ts_id    IN     VARCHAR2,
      p_start_time    IN     DATE,
      p_end_time      IN     DATE,
      p_timezone      IN     VARCHAR2 DEFAULT 'GMT',
      p_trim          IN     NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN     NUMBER DEFAULT NULL,
      p_versiondate   IN     DATE DEFAULT NULL,
      p_max_version   IN     NUMBER DEFAULT cwms_util.true_num)
   IS
      l_at_tsv_rc   SYS_REFCURSOR;
   BEGIN
      retrieve_ts (p_at_tsv_rc,
                   p_units,
                   p_officeid,
                   p_cwms_ts_id,
                   p_start_time,
                   p_end_time,
                   p_timezone,
                   p_trim,
                   p_inclusive,
                   p_versiondate,
                   p_max_version);
   END retrieve_ts_2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS - v2.0 -
   --
   PROCEDURE retrieve_ts (p_at_tsv_rc            OUT SYS_REFCURSOR,
                          p_cwms_ts_id        IN     VARCHAR2,
                          p_units             IN     VARCHAR2,
                          p_start_time        IN     DATE,
                          p_end_time          IN     DATE,
                          p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
                          p_trim              IN     VARCHAR2 DEFAULT 'F',
                          p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
                          p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
                          p_previous          IN     VARCHAR2 DEFAULT 'F',
                          p_next              IN     VARCHAR2 DEFAULT 'F',
                          p_version_date      IN     DATE DEFAULT NULL,
                          p_max_version       IN     VARCHAR2 DEFAULT 'T',
                          p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      l_cwms_ts_id_out   VARCHAR2(191);
      l_units_out        VARCHAR2 (16);
      l_at_tsv_rc        SYS_REFCURSOR;
   BEGIN
      retrieve_ts_out (l_at_tsv_rc,
                       l_cwms_ts_id_out,
                       l_units_out,
                       p_cwms_ts_id,
                       p_units,
                       p_start_time,
                       p_end_time,
                       p_time_zone,
                       p_trim,
                       p_start_inclusive,
                       p_end_inclusive,
                       p_previous,
                       p_next,
                       p_version_date,
                       p_max_version,
                       p_office_id);
      p_at_tsv_rc := l_at_tsv_rc;
   END retrieve_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_MULTI - v2.0 -
   --
   PROCEDURE retrieve_ts_multi (
      p_at_tsv_rc            OUT SYS_REFCURSOR,
      p_timeseries_info   IN     timeseries_req_array,
      p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
      p_trim              IN     VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_previous          IN     VARCHAR2 DEFAULT 'F',
      p_next              IN     VARCHAR2 DEFAULT 'F',
      p_version_date      IN     DATE DEFAULT NULL,
      p_max_version       IN     VARCHAR2 DEFAULT 'T',
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      TYPE date_tab_t IS TABLE OF DATE;

      TYPE val_tab_t IS TABLE OF BINARY_DOUBLE;

      TYPE qual_tab_t IS TABLE OF NUMBER;

      TS_ID_NOT_FOUND       EXCEPTION;
      LOCATION_ID_NOT_FOUND EXCEPTION;
      PRAGMA EXCEPTION_INIT (TS_ID_NOT_FOUND, -20001);
      PRAGMA EXCEPTION_INIT (LOCATION_ID_NOT_FOUND, -20025);
      date_tab          date_tab_t := date_tab_t ();
      val_tab           val_tab_t := val_tab_t ();
      qual_tab          qual_tab_t := qual_tab_t ();
      i                 INTEGER;
      j                 PLS_INTEGER;
      t                 nested_ts_table := nested_ts_table ();
      rec               SYS_REFCURSOR;
      l_time_zone       VARCHAR2 (28) := NVL (p_time_zone, 'UTC');
      must_exist        BOOLEAN;
      tsid              VARCHAR2(191);
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts_multi',
                                        'Preparation loop');

      --
      -- This routine actually iterates all the results in order to pack them into
      -- a collection that can be queried to generate the nested cursors.
      --
      -- I used this setup becuase I was not able to get the complex query used in
      --  retrieve_ts_out to work as a cursor expression.
      --
      -- MDP
      -- 01 May 2008
      --
      FOR i IN 1 .. p_timeseries_info.COUNT
      LOOP
         tsid := p_timeseries_info (i).tsid;

         IF SUBSTR (tsid, 1, 1) = '?'
         THEN
            tsid := SUBSTR (tsid, 2);
            must_exist := FALSE;
         ELSE
            must_exist := TRUE;
         END IF;

         t.EXTEND;
         t (i) :=
            nested_ts_type (i,
                            tsid,
                            p_timeseries_info (i).unit,
                            p_timeseries_info (i).start_time,
                            p_timeseries_info (i).end_time,
                            tsv_array ());

         BEGIN
            retrieve_ts_out (rec,
                             t (i).tsid,
                             t (i).units,
                             t (i).tsid,
                             p_timeseries_info (i).unit,
                             p_timeseries_info (i).start_time,
                             p_timeseries_info (i).end_time,
                             p_time_zone,
                             p_trim,
                             p_start_inclusive,
                             p_end_inclusive,
                             p_previous,
                             p_next,
                             p_version_date,
                             p_max_version,
                             p_office_id);

            date_tab.delete;
            val_tab.delete;
            qual_tab.delete;

            FETCH rec
            BULK COLLECT INTO date_tab, val_tab, qual_tab;

            t (i).data.EXTEND (rec%ROWCOUNT);
            close rec;
            FOR j IN 1 .. t(i).data.count
            LOOP
               t (i).data (j) :=
                  tsv_type (
                     FROM_TZ (CAST (date_tab (j) AS TIMESTAMP), 'UTC'),
                     val_tab (j),
                     qual_tab (j));
            END LOOP;
         EXCEPTION
            WHEN TS_ID_NOT_FOUND OR LOCATION_ID_NOT_FOUND
            THEN
               IF NOT must_exist
               THEN
                  NULL;
               END IF;
         END;
      END LOOP;

      OPEN p_at_tsv_rc FOR
           SELECT sequence,
                  tsid,
                  units,
                  start_time,
                  end_time,
                  l_time_zone "TIME_ZONE",
                  CURSOR (  SELECT date_time, VALUE, quality_code
                              FROM TABLE (t1.data)
                          ORDER BY date_time ASC)
                     "DATA"
             FROM TABLE (t) t1
         ORDER BY sequence ASC;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END retrieve_ts_multi;

   -------------------------------------------------------------------------------
   -- function QUALITY_SCORE
   --
   function quality_score(
      p_quality_code in integer)
      return integer
   is
      l_score pls_integer;

   begin
      return case bitand(p_quality_code, 1)
             when 0 then 1      -- unscreened
             else case bitand(p_quality_code / 2, 15)
                  when 0 then 1 -- unknown
                  when 1 then 3 -- okay
                  when 2 then 0 -- missing
                  when 4 then 2 -- questionable
                  when 8 then 0 -- rejected
                  end
             end;
   end quality_score;

   --
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CLEAN_QUALITY_CODE -
   --
   function clean_quality_code(
      p_quality_code in number)
      return number
      result_cache
   is
      /*
      Data Quality Rules :

          1. Unless the Screened bit is set, no other bits can be set.

          2. Unused bits(22, 24, 27-31, 32+) must be reset(zero).

          3. The Okay, Missing, Questioned and Rejected bits are mutually
             exclusive.

          4. No replacement cause or replacement method bits can be set unless
             the changed(different) bit is also set, and if the changed(different)
             bit is set, one of the cause bits and one of the replacement
             method bits must be set.

          5. Replacement Cause integer is in range 0..4.

          6. Replacement Method integer is in range 0..4

          7. The Test Failed bits are not mutually exclusive(multiple tests can be
             marked as failed).

      Bit Mappings :

               3                   2                   1
           2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1

           P - - - - - T T - T - T T T T T T M M M M C C C D R R V V V V S
           |           <---------+---------> <--+--> <-+-> | <+> <--+--> |
           |                     |              |      |   |  |     |    +------Screened T/F
           |                     |              |      |   |  |     +-----------Validity Flags
           |                     |              |      |   |  +--------------Value Range Integer
           |                     |              |      |   +-------------------Different T/F
           |                     |              |      +---------------Replacement Cause Integer
           |                     |              +---------------------Replacement Method Integer
           |                     +-------------------------------------------Test Failed Flags
           +-------------------------------------------------------------------Protected T/F
      */
      c_used_bits             constant integer := 2204106751; -- 1000 0011 0101 1111 1111 1111 1111 1111
      c_screened              constant integer := 1;          -- 0000 0000 0000 0000 0000 0000 0000 0001
      c_ok                    constant integer := 2;          -- 0000 0000 0000 0000 0000 0000 0000 0010
      c_ok_mask               constant integer := 4294967267; -- 1111 1111 1111 1111 1111 1111 1110 0011
      c_missing               constant integer := 4;          -- 0000 0000 0000 0000 0000 0000 0000 0100
      c_missing_mask          constant integer := 4294967269; -- 1111 1111 1111 1111 1111 1111 1110 0101
      c_questioned            constant integer := 8;          -- 0000 0000 0000 0000 0000 0000 0000 1000
      c_questioned_mask       constant integer := 4294967273; -- 1111 1111 1111 1111 1111 1111 1110 1001
      c_rejected              constant integer := 16;         -- 0000 0000 0000 0000 0000 0000 0001 0000
      c_rejected_mask         constant integer := 4294967281; -- 1111 1111 1111 1111 1111 1111 1111 0001
      c_different_mask        constant integer := 128;        -- 0000 0000 0000 0000 0000 0000 1000 0000
      c_not_different_mask    constant integer := -129;       -- 1111 1111 1111 1111 1111 1111 0111 1111
      c_repl_cause_mask       constant integer := 1792;       -- 0000 0000 0000 0000 0000 0111 0000 0000
      c_no_repl_cause_mask    constant integer := 4294965503; -- 1111 1111 1111 1111 1111 1000 1111 1111
      c_repl_method_mask      constant integer := 30720;      -- 0000 0000 0000 0000 0111 1000 0000 0000
      c_no_repl_method_mask   constant integer := 4294936575; -- 1111 1111 1111 1111 1000 0111 1111 1111
      c_repl_cause_factor     constant integer := 256;        -- 2 ** 8 for shifting 8 bits
      c_repl_method_factor    constant integer := 2048;       -- 2 ** 11 for shifting 11 bits
      l_quality_code                   integer;
      l_repl_cause                     integer;
      l_repl_method                    integer;
      l_different                      boolean;

      function bitor(
         num1 in integer,
         num2 in integer)
         return integer
      is
      begin
         return num1 + num2 - bitand(num1, num2);
      end;
   begin
      if p_quality_code is null then
         l_quality_code := 0;
      else
         l_quality_code := p_quality_code;
         begin
            --------------------------------------------
            -- first see if the code is already clean --
            --------------------------------------------
            select quality_code
              into l_quality_code
              from cwms_data_quality
             where quality_code = l_quality_code;
         exception
            when no_data_found
            then
               -----------------------------------------------
               -- clear all bits if screened bit is not set --
               -----------------------------------------------
               if bitand(l_quality_code, c_screened) = 0 then
                  l_quality_code := 0;
               else
                  ---------------------------------------------------------------------
                  -- ensure only used bits are set(also counteracts sign-extension) --
                  ---------------------------------------------------------------------
                  l_quality_code := bitand(l_quality_code, c_used_bits);

                  -----------------------------------------
                  -- ensure only one validity bit is set --
                  -----------------------------------------
                  if bitand(l_quality_code, c_missing) != 0 then
                     l_quality_code := bitand(l_quality_code, c_missing_mask);
                  elsif bitand(l_quality_code, c_rejected) != 0 then
                     l_quality_code := bitand(l_quality_code, c_rejected_mask);
                  elsif bitand(l_quality_code, c_questioned) != 0 then
                     l_quality_code := bitand(l_quality_code, c_questioned_mask);
                  elsif bitand(l_quality_code, c_ok) != 0 then
                     l_quality_code := bitand(l_quality_code, c_ok_mask);
                  end if;

                  --------------------------------------------------------
                  -- ensure the replacement cause is not greater than 4 --
                  --------------------------------------------------------
                  l_repl_cause := trunc(bitand(l_quality_code, c_repl_cause_mask) / c_repl_cause_factor);

                  if l_repl_cause > 4 then
                     l_repl_cause := 4;
                     l_quality_code := bitor(bitand(l_quality_code, c_no_repl_cause_mask), l_repl_cause * c_repl_cause_factor);
                  end if;

                  ---------------------------------------------------------
                  -- ensure the replacement method is not greater than 4 --
                  ---------------------------------------------------------
                  l_repl_method := trunc(bitand(l_quality_code, c_repl_method_mask)/ c_repl_method_factor);

                  if l_repl_method > 4 then
                     l_repl_method := 4;
                     l_quality_code := bitor(bitand(l_quality_code, c_no_repl_method_mask), l_repl_method * c_repl_method_factor);
                  end if;

                  --------------------------------------------------------------------------------------------------------------
                  -- ensure that if 2 of replacement cause, replacement method, and different are 0, the remaining one is too --
                  --------------------------------------------------------------------------------------------------------------
                  l_different := bitand(l_quality_code, c_different_mask) != 0;

                  if l_repl_cause = 0 then
                     if l_repl_method = 0 and l_different then
                        l_quality_code := bitand(l_quality_code, c_not_different_mask);
                        l_different := false;
                     elsif(not l_different) and l_repl_method != 0 then
                        l_repl_method := 0;
                        l_quality_code := bitand(l_quality_code, c_no_repl_method_mask);
                     end if;
                  elsif l_repl_method = 0 and not l_different then
                     l_repl_cause := 0;
                     l_quality_code := bitand(l_quality_code, c_no_repl_cause_mask);
                  end if;

                  ------------------------------------------------------------------------------------------------------------------------------
                  -- ensure that if 2 of replacement cause, replacement method, and different are NOT 0, the remaining one is set accordingly --
                  ------------------------------------------------------------------------------------------------------------------------------
                  if l_repl_cause != 0 then
                     if l_repl_method != 0 and not l_different then
                        l_quality_code := bitor(l_quality_code, c_different_mask);
                        l_different := true;
                     elsif l_different and l_repl_method = 0 then
                        l_repl_method := 2;                           -- EXPLICIT
                        l_quality_code := bitor(l_quality_code, l_repl_method * c_repl_method_factor);
                     end if;
                  elsif l_repl_method != 0 and l_different then
                     l_repl_cause := 3;                                 -- MANUAL
                     l_quality_code := bitor(l_quality_code, l_repl_cause * c_repl_cause_factor);
                  end if;
               end if;
         end;
      end if;

      return l_quality_code;
   end clean_quality_code;

   -------------------------------------------------------------------------------
   -- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
   --
   FUNCTION use_first_table (p_timestamp IN TIMESTAMP DEFAULT NULL)
      RETURN BOOLEAN
   IS
      pragma autonomous_transaction;
      l_ts_month    integer;
      l_table_month integer;
      l_first_table boolean;
      l_table_ts    timestamp;
   BEGIN
      l_ts_month := to_number(to_char(nvl(p_timestamp, systimestamp), 'MM'));
      l_first_table := mod(l_ts_month, 2) = 1;
      -- if l_first_table then
      --    select min(message_time) into l_table_ts from at_ts_msg_archive_1;
      -- else
      --    select min(message_time) into l_table_ts from at_ts_msg_archive_2;
      -- end if;
      -- l_table_month := to_number(to_char(l_table_ts, 'MM'));
      -- if l_table_month != l_ts_month then
      --    execute immediate case l_first_table
      --                         when true  then 'truncate table at_ts_msg_archive_1'
      --                         when false then 'truncate table at_ts_msg_archive_2'
      --                      end;
      --    commit;
      -- end if;
      return l_first_table;
   END use_first_table;

   -------------------------------------------------------------------------------
   -- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
   --
   FUNCTION use_first_table (p_timestamp IN INTEGER)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN use_first_table (cwms_util.TO_TIMESTAMP (p_timestamp));
   END use_first_table;

   -------------------------------------------------------------------------------
   -- PROCEDURE TIME_SERIES_UPDATED(...)
   --
   PROCEDURE time_series_updated (p_ts_code      IN INTEGER,
                                  p_ts_id        IN VARCHAR2,
                                  p_office_id    IN VARCHAR2,
                                  p_first_time   IN TIMESTAMP WITH TIME ZONE,
                                  p_last_time    IN TIMESTAMP WITH TIME ZONE,
                                  p_version_date IN TIMESTAMP WITH TIME ZONE,
                                  p_store_time   IN TIMESTAMP WITH TIME ZONE,
                                  p_store_rule   IN VARCHAR2)
   IS
      l_msg          SYS.aq$_jms_map_message;
      l_dx_msg       SYS.aq$_jms_map_message;
      l_msgid        PLS_INTEGER;
      l_dx_msgid     PLS_INTEGER;
      l_first_time   TIMESTAMP;
      l_last_time    TIMESTAMP;
      l_version_date TIMESTAMP;
      l_store_time   TIMESTAMP;
      i              INTEGER;
   BEGIN
      -------------------------------------------------------
      -- insert the time series update info into the table --
      -------------------------------------------------------
      l_first_time   := trunc(sys_extract_utc(cwms_util.fixup_timezone(p_first_time)),   'mi');
      l_last_time    := trunc(sys_extract_utc(cwms_util.fixup_timezone(p_last_time)),    'mi');
--    l_version_date := trunc(sys_extract_utc(cwms_util.fixup_timezone(p_version_date)), 'mi');
      l_version_date := cast(cast(sys_extract_utc(cwms_util.fixup_timezone(p_version_date)) as date) as timestamp); -- trunc to second
      l_store_time   := sys_extract_utc(cwms_util.fixup_timezone(p_store_time));

      for i in 1..3 loop
         -- try a few times; give up if not successful
         begin
            IF use_first_table
            THEN
               ----------------
               -- odd months --
               ----------------
               INSERT INTO at_ts_msg_archive_1
                    VALUES (cwms_msg.get_msg_id,
                            p_ts_code,
                            SYSTIMESTAMP,
                            CAST (l_first_time AS DATE),
                            CAST (l_last_time AS DATE));
            ELSE
               -----------------
               -- even months --
               -----------------
               INSERT INTO at_ts_msg_archive_2
                    VALUES (cwms_msg.get_msg_id,
                            p_ts_code,
                            SYSTIMESTAMP,
                            CAST (l_first_time AS DATE),
                            CAST (l_last_time AS DATE));
            END IF;
         exception
            when others then
               if sqlcode = -1 then
                  if i < 3 then
                     continue;
                  else
                     cwms_err.raise('ERROR', 'Could not get unique message id in 3 attempts');
                  end if;
               end if;
         end;
         exit; -- no exception
      end loop;

      -------------------------
      -- publish the message --
      -------------------------
      cwms_msg.new_message (l_msg, l_msgid, 'TSDataStored');
      l_msg.set_string (l_msgid, 'ts_id', p_ts_id);
      l_msg.set_string (l_msgid, 'office_id', p_office_id);
      l_msg.set_long (l_msgid, 'ts_code', p_ts_code);
      l_msg.set_long (l_msgid,
                      'start_time',
                      cwms_util.to_millis (l_first_time));
      l_msg.set_long (l_msgid, 'end_time', cwms_util.to_millis (l_last_time));
      l_msg.set_long (l_msgid, 'version_date', cwms_util.to_millis (l_version_date));
      l_msg.set_long (l_msgid, 'store_time', cwms_util.to_millis (l_store_time));
      l_msg.set_string (l_msgid, 'store_rule', p_store_rule);
      i :=
         cwms_msg.publish_message (l_msg,
                                   l_msgid,
                                   p_office_id || '_ts_stored');

      IF cwms_xchg.is_realtime_export (p_ts_code)
      THEN
         -----------------------------------------------
         -- notify the real-time Oracle->DSS exchange --
         -----------------------------------------------
         cwms_msg.new_message (l_dx_msg, l_dx_msgid, 'TSDataStored');
         l_dx_msg.set_string (l_dx_msgid, 'ts_id', p_ts_id);
         l_dx_msg.set_string (l_dx_msgid, 'office_id', p_office_id);
         l_dx_msg.set_long (l_dx_msgid, 'ts_code', p_ts_code);
         l_dx_msg.set_long (l_dx_msgid,
                        'start_time',
                        cwms_util.to_millis (l_first_time));
         l_dx_msg.set_long (l_dx_msgid, 'end_time', cwms_util.to_millis (l_last_time));
         i :=
            cwms_msg.publish_message (l_dx_msg,
                                      l_dx_msgid,
                                      p_office_id || '_realtime_ops');
      END IF;
   END time_series_updated;

   function same_val(
      v1 in binary_double,
      v2 in binary_double)
      return varchar2
   is
      l_result varchar2(1);
   begin
      case
      when (v1 is null) != (v2 is null) then
         l_result := 'F'; -- mixed nullity
      when v1 is null then
         l_result := 'T'; -- null values
      else
         if abs(v1 - v2) < 1e-8D then
            l_result := 'T'; -- same values
         else
            l_result := 'F'; -- different values
         end if;
      end case;
      return l_result;
   end same_val;

   function same_vq(
      v1 in binary_double,
      q1 in integer,
      v2 in binary_double,
      q2 in integer)
      return varchar2
   is
      l_result varchar2(1);
   begin
      case
      when (v1 is null) != (v2 is null) then
         l_result := 'F'; -- mixed nullity on values
      when (q1 is null) != (q2 is null) then
         l_result := 'F'; -- mixed nullity on quality
      when v1 is null then
         if q1 is null or q1 = q2 then
            l_result := 'T'; -- null values / same quality
         else
            l_result := 'F'; -- null values / different quality
         end if;
      else
         case
         when q1 is not null and q1 != q2 then
            l_result := 'F'; -- values present / different quality
         when abs(v1 - v2) < 1e-8D then
            l_result := 'T'; -- same values / same quality
         else
            l_result := 'F'; -- different values
         end case;
      end case;
      return l_result;
   end same_vq;

   function same_vq2(
      v1 in binary_double,
      q1 in integer,
      v2 in binary_double,
      q2 in integer)
      return varchar2
   is
      l_result varchar2(1);
      qq1      integer;
      qq2      integer;
   begin
      if q1 is not null then
         qq1 := bitand(q1, to_number('7FFFFFFF', 'XXXXXXXX')); -- unset protection bit
      end if;
      if q2 is not null then
         qq2 := bitand(q2, to_number('7FFFFFFF', 'XXXXXXXX')); --unset protection bit
      end if;
      case
      when (v1 is null) != (v2 is null) then
         l_result := 'F'; -- mixed nullity on values
      when (qq1 is null) != (qq2 is null) then
         l_result := 'F'; -- mixed nullity on quality
      when v1 is null then
         if qq1 is null or qq1 = qq2 then
            l_result := 'T'; -- null values / same quality
         else
            l_result := 'F'; -- null values / different quality
         end if;
      else
         case
         when qq1 is not null and qq1 != qq2 then
            l_result := 'F'; -- values present / different quality
         when abs(v1 - v2) < 1e-8D then
            l_result := 'T'; -- same values / same quality
         else
            l_result := 'F'; -- different values
         end case;
      end case;
      return l_result;
   end same_vq2;

   function update_ts_extents(
      p_ts_extents_rec in at_ts_extents%rowtype)
      return boolean
   is
      l_rec     at_ts_extents%rowtype;
      l_updated boolean := false;
   begin
      begin
         select *
           into l_rec
           from at_ts_extents
          where ts_code = p_ts_extents_rec.ts_code
            and version_time = p_ts_extents_rec.version_time;
         ---------------------
         -- existing record --
         ---------------------
         if p_ts_extents_rec.earliest_time is not null
            and (l_rec.earliest_time is null or p_ts_extents_rec.earliest_time < l_rec.earliest_time)
         then
            l_rec.earliest_time                 := p_ts_extents_rec.earliest_time;
            l_rec.earliest_time_entry           := p_ts_extents_rec.earliest_time_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.earliest_non_null_time is not null
            and (l_rec.earliest_non_null_time is null or p_ts_extents_rec.earliest_non_null_time < l_rec.earliest_non_null_time)
         then
            l_rec.earliest_non_null_time        := p_ts_extents_rec.earliest_non_null_time;
            l_rec.earliest_non_null_time_entry  := p_ts_extents_rec.earliest_non_null_time_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.earliest_non_null_entry_time is not null
            and (l_rec.earliest_non_null_entry_time is null or p_ts_extents_rec.earliest_non_null_entry_time < l_rec.earliest_non_null_entry_time)
         then
            l_rec.earliest_non_null_entry_time  := p_ts_extents_rec.earliest_non_null_entry_time;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.latest_time is not null
            and (l_rec.latest_time is null or p_ts_extents_rec.latest_time > l_rec.latest_time)
         then
            l_rec.latest_time                   := p_ts_extents_rec.latest_time;
            l_rec.latest_time_entry             := p_ts_extents_rec.latest_time_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.latest_non_null_time is not null
            and (l_rec.latest_non_null_time is null or p_ts_extents_rec.latest_non_null_time > l_rec.latest_non_null_time)
         then
            l_rec.latest_non_null_time          := p_ts_extents_rec.latest_non_null_time;
            l_rec.latest_non_null_time_entry    := p_ts_extents_rec.latest_non_null_time_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.latest_entry_time is not null
            and (l_rec.latest_entry_time is null or p_ts_extents_rec.latest_entry_time > l_rec.latest_entry_time)
         then
            l_rec.latest_entry_time             := p_ts_extents_rec.latest_entry_time;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.latest_non_null_entry_time is not null
            and (l_rec.latest_non_null_entry_time is null or p_ts_extents_rec.latest_non_null_entry_time > l_rec.latest_non_null_entry_time)
         then
            l_rec.latest_non_null_entry_time    := p_ts_extents_rec.latest_non_null_entry_time;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.least_value is not null
            and (l_rec.least_value is null or p_ts_extents_rec.least_value < l_rec.least_value)
         then
            l_rec.least_value                   := p_ts_extents_rec.least_value;
            l_rec.least_value_time              := p_ts_extents_rec.least_value_time;
            l_rec.least_value_entry             := p_ts_extents_rec.least_value_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.least_accepted_value is not null
            and (l_rec.least_accepted_value is null or p_ts_extents_rec.least_accepted_value < l_rec.least_accepted_value)
         then
            l_rec.least_accepted_value          := p_ts_extents_rec.least_accepted_value;
            l_rec.least_accepted_value_time     := p_ts_extents_rec.least_accepted_value_time;
            l_rec.least_accepted_value_entry    := p_ts_extents_rec.least_accepted_value_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.greatest_value is not null
            and (l_rec.greatest_value is null or p_ts_extents_rec.greatest_value > l_rec.greatest_value)
         then
            l_rec.greatest_value                := p_ts_extents_rec.greatest_value;
            l_rec.greatest_value_time           := p_ts_extents_rec.greatest_value_time;
            l_rec.greatest_value_entry          := p_ts_extents_rec.greatest_value_entry;
            l_updated                           := true;
         end if;
         if p_ts_extents_rec.greatest_accepted_value is not null
            and (l_rec.greatest_accepted_value is null or p_ts_extents_rec.greatest_accepted_value > l_rec.greatest_accepted_value)
         then
            l_rec.greatest_accepted_value       := p_ts_extents_rec.greatest_accepted_value;
            l_rec.greatest_accepted_value_time  := p_ts_extents_rec.greatest_accepted_value_time;
            l_rec.greatest_accepted_value_entry := p_ts_extents_rec.greatest_accepted_value_entry;
            l_updated                           := true;
         end if;
         if l_updated then
            update at_ts_extents
               set row = l_rec
             where ts_code = l_rec.ts_code
               and version_time = l_rec.version_time;
         end if;
      exception
         when no_data_found then
            ------------------------
            -- no existing record --
            ------------------------
            l_updated := true;
            insert
              into at_ts_extents
            values p_ts_extents_rec;
      end;
      return l_updated;
   end update_ts_extents;

   procedure update_ts_extents(
      p_ts_code      in integer default null,
      p_version_date in date default null)
   is
      type at_ts_extents_tabtype is table of at_ts_extents%rowtype;
      l_crsr       sys_refcursor;
      l_ts1        timestamp;
      l_ts2        timestamp;
      l_ts_start       timestamp;
      l_ts_end         timestamp;
      l_ts_table_start timestamp;
      l_ts_table_end   timestamp;
      l_elapsed    interval day (0) to second (6);
      l_ts_extents     at_ts_extents_tabtype;
      l_rec        at_ts_extents%rowtype;
      l_updated    integer;
      l_ts_codes       number_tab_t;
      l_query      varchar2(32767) := '
         select
                q1.ts_code,
                q1.version_date as version_time,
                --------------
                -- earliest --
                --------------
                q1.earliest_time,
                q6.earliest_time_entry,
                q1.earliest_entry_time,
                q2.earliest_non_null_time,
                q3.earliest_non_null_time_entry,
                q2.earliest_non_null_entry_time,
                ------------
                -- latest --
                ------------
                q1.latest_time,
                q7.latest_time_entry,
                q1.latest_entry_time,
                q2.latest_non_null_time,
                q4.latest_non_null_time_entry,
                q2.latest_non_null_entry_time,
                -----------
                -- least --
                -----------
                q1.least_value,
                q8.least_value_time,
                q9.least_value_entry,
                q5.least_accepted_value,
                q12.least_accepted_value_time,
                q13.least_accepted_value_entry,
                --------------
                -- greatest --
                --------------
                q1.greatest_value,
                q10.greatest_value_time,
                q11.greatest_value_entry,
                q5.greatest_accepted_value,
                q14.greatest_accepted_value_time,
                q15.greatest_accepted_value_entry,
                systimestamp
           from (select ts_code,
                        version_date,
                        min(date_time) as earliest_time,
                        max(date_time) as latest_time,
                        min(data_entry_date) as earliest_entry_time,
                        max(data_entry_date) as latest_entry_time,
                        min(value) as least_value,
                        max(value) as greatest_value
                   from :table_name
                  where ts_code = :ts_code
                    and version_date = nvl(:version_date, version_date)
                  group by ts_code, version_date
                ) q1
                join
                (select ts_code,
                        version_date,
                        min(date_time) as earliest_non_null_time,
                        max(date_time) as latest_non_null_time,
                        min(data_entry_date) as earliest_non_null_entry_time,
                        max(data_entry_date) as latest_non_null_entry_time
                   from :table_name
                  where value is not null
                  group by ts_code, version_date
                ) q2 on q2.ts_code = q1.ts_code
                    and q2.version_date = q1.version_date
                join
                (select ts_code,
                        version_date,
                        date_time,
                        max(data_entry_date) as earliest_non_null_time_entry
                   from :table_name
                  group by ts_code, version_date, date_time
                ) q3 on q3.ts_code = q1.ts_code
                    and q3.version_date = q1.version_date
                    and q3.date_time = q2.earliest_non_null_time
                join
                (select ts_code,
                        version_date,
                        date_time,
                        max(data_entry_date) as latest_non_null_time_entry
                   from :table_name
                  group by ts_code, version_date, date_time
                ) q4 on q4.ts_code = q1.ts_code
                    and q4.version_date = q1.version_date
                    and q4.date_time = q2.latest_non_null_time
                join
                (select ts_code,
                        version_date,
                        min(value) as least_accepted_value,
                        max(value) as greatest_accepted_value
                   from :table_name
                  where bitand(quality_code, 30) in (0,2,8)
                  group by ts_code, version_date
                ) q5 on q5.ts_code = q1.ts_code
                    and q5.version_date = q1.version_date
                join
                (select ts_code,
                        version_date,
                        date_time,
                        data_entry_date as earliest_time_entry
                   from :table_name
                ) q6 on q6.ts_code = q1.ts_code
                    and q6.version_date = q1.version_date
                    and q6.date_time = q1.earliest_time
                join
                (select ts_code,
                        version_date,
                        date_time,
                        data_entry_date as latest_time_entry
                   from :table_name
                ) q7 on q7.ts_code = q1.ts_code
                    and q7.version_date = q1.version_date
                    and q7.date_time = q1.latest_time
                join
                (select ts_code,
                        version_date,
                        value,
                        max(date_time) as least_value_time
                   from :table_name
                  group by ts_code, version_date, value
                ) q8 on q8.ts_code = q1.ts_code
                    and q8.version_date = q1.version_date
                    and q8.value = q1.least_value
                join
                (select ts_code,
                        version_date,
                        date_time,
                        data_entry_date as least_value_entry
                   from :table_name
                ) q9 on q9.ts_code = q1.ts_code
                    and q9.version_date = q1.version_date
                    and q9.date_time = q8.least_value_time
                join
                (select ts_code,
                        version_date,
                        value,
                        max(date_time) as greatest_value_time
                   from :table_name
                  group by ts_code, version_date, value
                ) q10 on q10.ts_code = q1.ts_code
                    and q10.version_date = q1.version_date
                    and q10.value = q1.greatest_value
                join
                (select ts_code,
                        version_date,
                        date_time,
                        data_entry_date as greatest_value_entry
                   from :table_name
                ) q11 on q11.ts_code = q1.ts_code
                    and q11.version_date = q1.version_date
                    and q11.date_time = q10.greatest_value_time
                join
                (select ts_code,
                        version_date,
                        max(date_time) as least_accepted_value_time,
                        value
                   from :table_name
                  group by ts_code, version_date, value
                ) q12 on q12.ts_code = q1.ts_code
                    and q12.version_date = q1.version_date
                    and q12.value = q5.least_accepted_value
                join
                (select ts_code,
                        version_date,
                        date_time,
                        data_entry_date as least_accepted_value_entry
                   from :table_name
                ) q13 on q13.ts_code = q1.ts_code
                    and q13.version_date = q1.version_date
                    and q13.date_time = q12.least_accepted_value_time
                join
                (select ts_code,
                        version_date,
                        max(date_time) as greatest_accepted_value_time,
                        value
                   from :table_name
                  group by ts_code, version_date, value
                ) q14 on q14.ts_code = q1.ts_code
                    and q14.version_date = q1.version_date
                    and q14.value = q5.greatest_accepted_value
                join
                (select ts_code,
                        version_date,
                        date_time,
                        data_entry_date as greatest_accepted_value_entry
                   from :table_name
                ) q15 on q15.ts_code = q1.ts_code
                    and q15.version_date = q1.version_date
                    and q15.date_time = q14.greatest_accepted_value_time';
   begin
      l_ts_start := systimestamp;
      cwms_msg.log_db_message(cwms_msg.msg_level_normal, 'UPDATE_TS_EXTENTS starting with '||nvl(to_char(p_ts_code), 'NULL')||', '||nvl(to_char(p_version_date), 'NULL'));
      if p_ts_code is null then
         select ts_code bulk collect into l_ts_codes from at_cwms_ts_id;
      end if;
      ------------------------------------
      -- loop across time series tables --
      ------------------------------------
      for rec in (select table_name from at_ts_table_properties order by start_date) loop
         l_ts1 := systimestamp;
         l_ts_table_start := l_ts1;
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, 'Starting table '||rec.table_name);
         if p_ts_code is null then
            -------------------------
            -- update all ts_codes --
            -------------------------
            --
            -- NOTE: I tried various methods of selecting values from each table, including a single query to get the extents for
            --       every ts_cod as well as a single query to get extents for no more than 100 ts_codes at a time. Each of these
            --       seemed to work okay interactively but took *way* too long when running as a job. I wasn't able to account for
            --       this, but I found that querying each table for a single ts_code at a time performed much faster than the bulk
            --       queries - at least when running as a job.
            --
            -- MDP
            for i in 1..l_ts_codes.count loop
               if mod(i, 100) = 1 then
                  cwms_msg.log_db_message(cwms_msg.msg_level_verbose, 'Starting ts_codes '||i||'..'||least(i+99, l_ts_codes.count)||' in '||rec.table_name);
               end if;
               ------------
               -- select --
               ------------
               open l_crsr for replace(l_query, ':table_name', rec.table_name) using l_ts_codes(i), p_version_date;
         fetch l_crsr bulk collect into l_ts_extents;
         close l_crsr;
               if mod(i, 100) = 1 then
            l_ts2 := systimestamp;
            l_elapsed := l_ts2 - l_ts1;
                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_verbose,
                     'Selected '
                     ||l_ts_extents.count
                     ||' time series extents from ts_codes '
                     ||i
                     ||'..'
                     ||least(i+99, l_ts_codes.count)
                     ||' from '
                     ||rec.table_name
                     ||' in '
                     ||l_elapsed);
            l_ts1 := systimestamp;
                  l_updated := 0;
         end if;
               ------------
               -- update --
               ------------
               for j in 1..l_ts_extents.count loop
                  if update_ts_extents(l_ts_extents(j)) then
                     l_updated := l_updated + 1;
                  end if;
               end loop;
               if mod(i, 100) = 1 then
                  l_ts2 := systimestamp;
                  l_elapsed := l_ts2 - l_ts1;
                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_verbose,
                     'Updated '
                     ||l_updated
                     ||' time series extents from ts_codes '
                     ||i
                     ||'..'
                     ||least(i+99, l_ts_codes.count)
                     ||' from '
                     ||rec.table_name
                     ||' in '
                     ||l_elapsed);
                  l_ts1 := systimestamp;
                  commit;
               end if;
            end loop;
            commit;
         else
            -----------------------------
            -- update specific ts_code --
            -----------------------------
            ------------
            -- select --
            ------------
            open l_crsr for replace(l_query, ':table_name', rec.table_name) using p_ts_code, p_version_date;
            fetch l_crsr bulk collect into l_ts_extents;
            close l_crsr;
            ------------
            -- update --
            ------------
         l_updated := 0;
         for i in 1..l_ts_extents.count loop
            if update_ts_extents(l_ts_extents(i)) then
               l_updated := l_updated + 1;
            end if;
            if mod(l_updated, 100) = 0 then
               commit;
            end if;
         end loop;
         commit;
         end if;
         l_ts_table_end := systimestamp;
         l_elapsed := l_ts_table_end - l_ts_table_start;
         cwms_msg.log_db_message(cwms_msg.msg_level_normal, 'Finished table '||rec.table_name||' in '||l_elapsed);
      end loop;
      -------------------------
      -- update null extents --
      -------------------------
      if p_ts_code is null and p_version_date is null then
         l_ts_extents.delete;
         l_ts_extents.extend;
         l_ts_extents(1).version_time := cwms_util.non_versioned;
         l_ts_extents(1).last_update  := systimestamp;
         l_updated := 0;
         l_ts1 := systimestamp;
         l_elapsed := l_ts2 - l_ts1;
         for rec in (select ts_code from at_cwms_ts_spec minus select distinct ts_code from at_ts_extents) loop
            l_ts_extents(1).ts_code := rec.ts_code;
            if update_ts_extents(l_ts_extents(1)) then
               l_updated := l_updated + 1;
            end if;
            if mod(l_updated, 100) = 0 then
               commit;
            end if;
         end loop;
         commit;
         if p_ts_code is null then
            l_ts2 := systimestamp;
            l_elapsed := l_ts2 - l_ts1;
            cwms_msg.log_db_message(cwms_msg.msg_level_verbose, 'Updated '||l_updated||' null time series extents in '||l_elapsed);
         end if;
         end if;
      cwms_msg.log_db_message(cwms_msg.msg_level_normal, 'UPDATE_TS_EXTENTS done');
   end update_ts_extents;

   -- not documented
   procedure start_update_ts_extents_job
   is
      l_job_name varchar2(30) := 'UPDATE_TS_EXTENTS_JOB';
      l_now    date;
      l_dow    varchar2(3);
      l_start  date;
      l_timezone varchar2(28);

      function job_count return pls_integer
      is
         l_count pls_integer;
      begin
         select count(*) into l_count from user_scheduler_jobs where job_name = l_job_name;
         return l_count;
      end job_count;
   begin
      ----------------------------------------
      -- only allow schema owner to execute --
      ----------------------------------------
      if cwms_util.get_user_id != '&cwms_schema' then
         cwms_err.raise('ERROR', 'Must be &cwms_schema user to start job '||l_job_name);
      end if;
      ----------------------------------------------
      -- allow only a single copy to be scheduled --
      ----------------------------------------------
      if job_count > 0 then
         cwms_err.raise('ERROR', 'Cannot start job '||l_job_name||',  another instance is already running');
      end if;
      -----------------------------------------------
      -- get the "local" time zone of the database --
      -----------------------------------------------
      begin
         select time_zone_name
           into l_timezone
           from (select tz.time_zone_name,
                        count(pl.location_code)as count
                   from at_physical_location pl,
                        cwms_time_zone tz
                  where tz.time_zone_code = pl.time_zone_code
                  group by tz.time_zone_name
                  order by 2 desc
                )
          where rownum = 1;
      exception
         when no_data_found then l_timezone := 'UTC';
      end;
      ----------------------------------------------------------------------------------
      -- create the job to start next Friday at 10:00 pm local time and repeat weekly --
      ----------------------------------------------------------------------------------
      l_start := cwms_util.change_timezone(date '2018-07-06' + 22/24, l_timezone, 'UTC');
      dbms_scheduler.create_job (
         job_name            => l_job_name,
         job_type            => 'stored_procedure',
         job_action          => 'cwms_ts.update_ts_extents',
         start_date          => from_tz(cast(l_start as timestamp), 'UTC'),
         repeat_interval     => 'freq=weekly; interval=1',
         number_of_arguments => 2,
         comments            => 'Updates all time series extents.');
      dbms_scheduler.set_job_argument_value(
         job_name          => l_job_name,
         argument_position => 1,
         argument_value    => null);
      dbms_scheduler.set_job_argument_value(
         job_name          => l_job_name,
         argument_position => 2,
         argument_value    => null);
      dbms_scheduler.enable(l_job_name);
      if job_count != 1 then
         cwms_err.raise('ERROR', 'Job '||l_job_name||' not started');
      end if;
   end start_update_ts_extents_job;

   -- not documented
   procedure start_immediate_upd_tsx_job
   is
      l_job_name varchar2(30) := 'IMMEDIATE_UPD_TS_EXTENTS_JOB';

      function job_count return pls_integer
      is
         l_count pls_integer;
      begin
         select count(*) into l_count from user_scheduler_jobs where job_name = l_job_name;
         return l_count;
      end job_count;
   begin
      ----------------------------------------
      -- only allow schema owner to execute --
      ----------------------------------------
      if cwms_util.get_user_id != '&cwms_schema' then
         cwms_err.raise('ERROR', 'Must be &cwms_schema user to start job '||l_job_name);
      end if;
      ----------------------------------------------
      -- allow only a single copy to be scheduled --
      ----------------------------------------------
      if job_count > 0 then
         cwms_err.raise('ERROR', 'Cannot start job '||l_job_name||',  another instance is already running');
      end if;
      ----------------------------------------------------------
      -- create the job to start immediately and never repeat --
      ----------------------------------------------------------
      dbms_scheduler.create_job (
         job_name            => l_job_name,
         job_type            => 'stored_procedure',
         job_action          => 'cwms_ts.update_ts_extents',
         number_of_arguments => 2,
         comments            => 'Updates all time series extents.');
      dbms_scheduler.set_job_argument_value(
         job_name          => l_job_name,
         argument_position => 1,
         argument_value    => null);
      dbms_scheduler.set_job_argument_value(
         job_name          => l_job_name,
         argument_position => 2,
         argument_value    => null);
      dbms_scheduler.enable(l_job_name);
      if job_count != 1 then
         cwms_err.raise('ERROR', 'Job '||l_job_name||' not started');
      end if;
   end start_immediate_upd_tsx_job;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE store_ts (
      p_office_id         IN VARCHAR2,
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN NUMBER DEFAULT cwms_util.false_num,
      p_versiondate       IN DATE DEFAULT cwms_util.non_versioned)
   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   IS
      l_override_prot   VARCHAR2 (1);
   BEGIN
      cwms_apex.aa1 (
            TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI')
         || 'store_ts(1.4): '
         || p_cwms_ts_id);

      IF p_override_prot IS NULL OR p_override_prot = cwms_util.false_num
      THEN
         l_override_prot := 'F';
      ELSIF p_override_prot = cwms_util.true_num
      THEN
         l_override_prot := 'T';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_override_prot);
      END IF;

      -- DBMS_OUTPUT.put_line ('tag wie gehts2?');
      store_ts (p_cwms_ts_id,
                p_units,
                p_timeseries_data,
                p_store_rule,
                l_override_prot,
                p_versiondate,
                p_office_id);
   END store_ts;                                                    -- v1.4 --

   --
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS -
   --
   PROCEDURE store_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      TS_ID_NOT_FOUND       EXCEPTION;
      PRAGMA EXCEPTION_INIT (ts_id_not_found, -20001);
      l_timeseries_data     tsv_array;
      l_cwms_ts_id          VARCHAR2(191);
      l_office_id           VARCHAR2 (16);
      l_office_code         NUMBER;
      l_location_code       NUMBER;
      l_ucount              NUMBER;
      l_store_date          TIMESTAMP (3) DEFAULT SYSTIMESTAMP AT TIME ZONE 'UTC';
      l_ts_code             number;
      l_ts_active           char(1);
      l_interval_id         cwms_interval.interval_id%TYPE;
      l_interval_value      NUMBER;
      l_utc_offset          NUMBER;
      existing_utc_offset   NUMBER;
      mindate               DATE;
      maxdate               DATE;
      l_sql_txt             VARCHAR2 (10000);
      l_override_prot       BOOLEAN;
      l_version_date        DATE;
      --
      l_units               VARCHAR2 (16);
      l_base_parameter_id   VARCHAR2 (16);
      l_base_parameter_code NUMBER(10);
      l_base_unit_id        VARCHAR2 (16);
      --
      l_first_time          DATE;
      l_last_time           DATE;
      l_msg                 SYS.aq$_jms_map_message;
      l_msgid               PLS_INTEGER;
      i                     INTEGER;
      l_millis              number (14) := cwms_util.to_millis (l_store_date);
      i_max_iterations      NUMBER := 100;
      --
      l_date_times          date_table_type;
      l_min_interval        number;
      l_count               number;
      l_value_offset        binary_double := 0;
   --
      l_tz_code             integer;
      l_loc_tz              varchar2(28);
      l_irr_interval        integer;
      l_irr_offset          integer;
      l_filtered_ts_data    tsv_array;
      l_filter_duplicates   varchar2(1);
      l_ts_extents_rec      at_ts_extents%rowtype;
      z_timeseries_data     ztsv_array;
      l_delete_times        date_table_type;
      l_remaining_times     date_table_type;
      l_quality_codes       str_tab_t;
   --
      function bitor (num1 in integer, num2 in integer)
         return integer
      is
      begin
         return num1 + num2 - bitand (num1, num2);
      end bitor;

   begin
      DBMS_APPLICATION_INFO.set_module ('cwms_ts_store.store_ts',
                                        'get tscode from ts_id');
      cwms_apex.aa1 (
            TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI')
         || 'store_ts: '
         || p_cwms_ts_id);

      -- set default values, don't be fooled by NULL as an actual argument


      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;

         --
         IF l_office_id = 'UNK'
         THEN
            cwms_err.RAISE ('INVALID_OFFICE_ID', 'Unkown');
         END IF;
      --
      ELSE
         l_office_id := cwms_util.strip(p_office_id);
      END IF;
      l_office_code := CWMS_UTIL.GET_OFFICE_CODE (l_office_id);

      begin
         l_cwms_ts_id := clean_ts_id(p_cwms_ts_id);
         l_cwms_ts_id := get_cwms_ts_id(l_cwms_ts_id, l_office_id);
      exception
         when ts_id_not_found then
            null;
      end;

      l_location_code := cwms_loc.get_location_code(l_office_code, cwms_Util.split_text(l_cwms_ts_id, 1, '.', 1));

--    l_version_date := trunc(NVL(p_version_date, cwms_util.non_versioned), 'mi');
      l_version_date := NVL(p_version_date, cwms_util.non_versioned); -- allow seconds on version date
      if l_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot use CWMS_UTIL.ALL_VERSION_DATES for storing data.');
      end if;

      IF NVL (p_override_prot, 'F') = 'F'
      THEN
         l_override_prot := FALSE;
      ELSE
         l_override_prot := TRUE;
      END IF;

      BEGIN
         SELECT i.interval
           INTO l_interval_value
           FROM cwms_interval i
          WHERE UPPER (i.interval_id) = UPPER (regexp_substr (l_cwms_ts_id, '[^.]+', 1, 4));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise('INVALID_INTERVAL_ID', regexp_substr (l_cwms_ts_id, '[^.]+', 1, 4));
      END;

      begin
         select base_parameter_code,
                base_parameter_id
           into l_base_parameter_code,
                l_base_parameter_id
           from cwms_base_parameter
          where upper(base_parameter_id) = upper(cwms_util.get_base_id(regexp_substr (l_cwms_ts_id, '[^.]+', 1, 2)));
      exception
         when no_data_found then
            cwms_err.raise('INVALID_PARAM_ID', regexp_substr (l_cwms_ts_id, '[^.]+', 1, 2));
      end;
      if l_base_parameter_code < 0 then
         cwms_err.raise('ERROR', 'Cannot store values to time series with parameter "'||regexp_substr (l_cwms_ts_id, '[^.]+', 1, 2)||'"');
      end if;

      DBMS_APPLICATION_INFO.set_action (
         'Find or create a TS_CODE for your TS Desc');

      BEGIN                                        -- BEGIN - Find the TS_CODE
         l_ts_code :=
            get_ts_code (p_cwms_ts_id       => l_cwms_ts_id,
                         p_db_office_code   => l_office_code);

         SELECT interval_utc_offset
           INTO existing_utc_offset
           FROM at_cwms_ts_spec
          WHERE ts_code = l_ts_code;
      EXCEPTION
         WHEN TS_ID_NOT_FOUND
         THEN
            /*
            Exception is thrown when the Time Series Description passed
            does not exist in the database for the office_id. If this is
            the case a new TS_CODE will be created for the Time Series
            Descriptor.
            */
            create_ts_code (p_ts_code        => l_ts_code,
                            p_office_id      => l_office_id,
                            p_cwms_ts_id     => l_cwms_ts_id,
                            p_fail_if_exists => 'F', -- in case of race condition will return ts_code generated by other thread
                            p_utc_offset     => cwms_util.UTC_OFFSET_UNDEFINED);

            existing_utc_offset := cwms_util.UTC_OFFSET_UNDEFINED;
      END;                                               -- END - Find TS_CODE

      IF l_ts_code IS NULL
      THEN
         raise_application_error (
            -20105,
            'Unable to create or locate ts_code for ' || l_cwms_ts_id,
            TRUE);
      END IF;

      --------------------------------------
      -- verify the time series is active --
      --------------------------------------
      select net_ts_active_flag
        into l_ts_active
        from at_cwms_ts_id
       where ts_code = l_ts_code;

      if l_ts_active <> 'T' then
         cwms_err.raise('ERROR', 'Cannot store to inactive time series '||l_office_id||'/'||l_cwms_ts_id);
      end if;
      ------------------------------------
      -- verify we have values to store --
      ------------------------------------
      if p_timeseries_data.count = 0 then
         dbms_application_info.set_action ('Returning due to no data provided');
         return;      -- have already created ts_code if it didn't exist
      end if;
      ------------------------
      -- handle null values --
      ------------------------
      DBMS_APPLICATION_INFO.set_action ('Check for nulls in incoming data');
      case get_nulls_storage_policy(l_ts_code)
      when set_null_values_to_missing then
         --------------------------------------------
         -- add missing quality to all null values --
         --------------------------------------------
         select tsv_type(
                   date_time,
                   value,
                   case when value is null then quality_code + 5 - bitand(quality_code, 5) else quality_code end)
           bulk collect
           into l_timeseries_data
           from table(p_timeseries_data);
      when reject_ts_with_null_values then
         ------------------------------------------------
         -- reject ts if nulls without missing quality --
         ------------------------------------------------
         select count(*)
           into l_count
           from table(p_timeseries_data)
          where value is null and get_quality_validity(quality_code) != 'MISSING';
         if l_count > 0 then
            cwms_err.raise('ERROR', 'Incoming data contains null values with non-missing quality.');
         end if;
         l_timeseries_data := p_timeseries_data;
      else -- filter_out_null_values or unset
         --------------------------------------------------
         -- filter out any nulls without missing quality --
         --------------------------------------------------
         select tsv_type(
                   date_time,
                   value,
                   quality_code)
           bulk collect
           into l_timeseries_data
           from table(p_timeseries_data)
          where value is not null or get_quality_validity(quality_code) = 'MISSING';
      end case;

      if l_timeseries_data.count = 0 then
         dbms_application_info.set_action ('Returning due to no data passed null filter');
         return;      -- have already created ts_code if it didn't exist
      end if;

      DBMS_APPLICATION_INFO.set_action (
         'Truncate incoming times to minute and verify validity');
      ---------------------------------------------------------
      -- get the times as date types truncated to the minute --
      ---------------------------------------------------------
      select trunc(cast(date_time at time zone 'UTC' as date), 'mi')
        bulk collect into l_date_times
        from table(l_timeseries_data)
       order by date_time;

      select min(interval)
        into l_min_interval
        from (select column_value - lag(column_value, 1, null) over (order by column_value) as interval
                from table(l_date_times));

      if l_min_interval = 0 then
         cwms_err.raise('ERROR', 'Incoming data has multiple values for same minute.');
      end if;

      IF l_interval_value > 0
      THEN
         DBMS_APPLICATION_INFO.set_action (
            'Incoming data set has a regular interval, confirm data set matches interval_id');

         -----------------------------
         -- test for irregular data --
         -----------------------------
         begin
            select distinct get_utc_interval_offset(column_value, l_interval_value)
              into l_utc_offset
              from table(l_date_times);
         exception
            when too_many_rows then
               raise_application_error (
                  -20110,
                  'ERROR: Incoming data set appears to contain irregular data. Unable to store data for '
                  || l_cwms_ts_id,
                  TRUE);
         end;
         if existing_utc_offset = cwms_util.utc_offset_undefined then
            --------------------
            -- set the offset --
            --------------------
            update at_cwms_ts_spec
               set interval_utc_offset = l_utc_offset
             where ts_code = l_ts_code;
         else
            -----------------------------
            -- test for invalid offset --
            -----------------------------
            if get_utc_interval_offset(l_date_times(1), l_interval_value) != existing_utc_offset then
               raise_application_error (
                  -20101,
                  'Incoming Data Set''s UTC_OFFSET: '
                  || l_utc_offset
                  || ' does not match its previously stored UTC_OFFSET of: '
                  || existing_utc_offset
                  || ' - data set was NOT stored',
                  TRUE);
            end if;
         end if;


      ELSE
         DBMS_APPLICATION_INFO.set_action ('Incoming data set is irregular');
         if existing_utc_offset in (cwms_util.utc_offset_irregular, cwms_util.utc_offset_undefined) then
            null;
         else
            l_irr_offset := -existing_utc_offset;
            select ci.interval
              into l_irr_interval
              from cwms_interval ci,
                   at_cwms_ts_id ts
             where ts.ts_code = l_ts_code
               and ci.interval_id = substr(ts.interval_id, 2);
            ------------------------------------------------------------
            -- filter out data not on interval offset (from local tz) --
            ------------------------------------------------------------
            select time_zone_code
              into l_tz_code
              from at_physical_location
             where location_code = l_location_code;

            if l_tz_code > 0 then
               select time_zone_name
                 into l_loc_tz
                 from cwms_time_zone
                where time_zone_code = l_tz_code;

               select cwms_util.change_timezone(trunc(cast(date_time at time zone 'UTC' as date), 'mi'), 'UTC', l_loc_tz)
                 bulk collect
                 into l_date_times
                 from table(l_timeseries_data);

               l_count := 0;
               l_filtered_ts_data := tsv_array();
               l_filtered_ts_data.extend(l_timeseries_data.count);
               for i in 1..l_timeseries_data.count loop
                  if get_time_on_before_interval(
                        l_date_times(i),
                        l_irr_offset,
                        l_irr_interval) = l_date_times(i)
                  then
                     l_filtered_ts_data(i-l_count) := l_timeseries_data(i);
                  else
                     l_count := l_count + 1;
                  end if;
               end loop;
               case
               when l_count = l_timeseries_data.count then
                  dbms_application_info.set_action ('Returning due to no data passed constrained pseudo-regular filter');
                  return;      -- have already created ts_code if it didn't exist
               when l_count > 0 then
                  l_filtered_ts_data.trim(l_count);
               else
                  null; -- no times filetered out
               end case;
               l_timeseries_data := l_filtered_ts_data;
            end if;
         end if;
      END IF;


      DBMS_APPLICATION_INFO.set_action (
         'getting vertical datum offset if parameter is elevation');

      l_units := cwms_util.get_unit_id(p_units, l_office_id);
      if l_units is null then l_units := p_units; end if;
      if l_base_parameter_id = 'Elev' then
         l_value_offset  := cwms_loc.get_vertical_datum_offset(l_location_code, l_units);
      end if;

      DBMS_APPLICATION_INFO.set_action (
         'check p_units is a valid unit for this parameter');

      SELECT a.base_parameter_id
        INTO l_base_parameter_id
        FROM cwms_base_parameter a, at_parameter b, at_cwms_ts_spec c
       WHERE     A.BASE_PARAMETER_CODE = B.BASE_PARAMETER_CODE
             AND B.PARAMETER_CODE = C.PARAMETER_CODE
             AND c.ts_code = l_ts_code;

      l_units := cwms_util.get_valid_unit_id (l_units, l_base_parameter_id);

      DBMS_APPLICATION_INFO.set_action ('check for unit conversion factors');


      SELECT COUNT (*)
        INTO l_ucount
        FROM at_cwms_ts_spec s,
             at_parameter ap,
             cwms_unit_conversion c,
             cwms_base_parameter p,
             cwms_unit u
       WHERE     s.ts_code = l_ts_code
             AND s.parameter_code = ap.parameter_code
             AND ap.base_parameter_code = p.base_parameter_code
             AND p.unit_code = c.from_unit_code
             AND c.to_unit_code = u.unit_code
             AND u.unit_id = l_units;


      IF l_ucount <> 1
      THEN
         SELECT unit_id
           INTO l_base_unit_id
           FROM cwms_unit a, cwms_base_parameter b
          WHERE     A.UNIT_CODE = B.UNIT_CODE
                AND B.BASE_PARAMETER_ID = l_base_parameter_id;

         raise_application_error (
            -20103,
               'Unit conversion from '
            || l_units
            || ' to the CWMS Database Base Units of '
            || l_base_unit_id
            || ' is not available for the '
            || l_base_parameter_id
            || ' parameter_id.',
            TRUE);
      END IF;

      --
      -- Determine the min and max date in the dataset, convert
      -- the min and max dates to GMT dates.
      -- The min and max dates are used to determine which
      -- at_tsv tables need to be accessed during the store.
      --

      SELECT MIN (trunc(CAST ( (t.date_time AT TIME ZONE 'UTC') AS DATE), 'mi')),
             MAX (trunc(CAST ( (t.date_time AT TIME ZONE 'UTC') AS DATE), 'mi'))
        INTO mindate, maxdate
        FROM TABLE (CAST (l_timeseries_data AS tsv_array)) t;

      l_filter_duplicates := get_filter_duplicates(l_ts_code);

--      DBMS_OUTPUT.put_line (
--            '*****************************'
--         || CHR (10)
--         || 'IN STORE_TS'
--         || CHR (10)
--         || 'TS Description: '
--         || l_cwms_ts_id
--         || CHR (10)
--         || '       TS CODE: '
--         || l_ts_code
--         || CHR (10)
--         || '    Store Rule: '
--         || p_store_rule
--         || CHR (10)
--         || '      Override: '
--         || p_override_prot
--         || CHR (10)
--         || '*****************************');

      /*
     A LOOP was added to catch primary key violations when multiple
     threads are simultaneously processing data for the same ts code and
     the data blocks have overlapping time windows. The loop allows
     repeated attempts to store the data block, with the hope that the
     initial data block that successfully stored data for the overlapping
     date/times has finally completed and COMMITed the inserts. If after
     i_max_iterations, the dup_value_on_index exception is still being
     thrown, then the loop ends and the dup_value_on_index exception is
     raised one last time.
     */
      for idx in 1..i_max_iterations loop
         begin
            l_count := 0;
            case
            when l_override_prot and upper (p_store_rule) = cwms_util.replace_all then
               --------------------------------------
               -- Case 1 - Store Rule: REPLACE ALL --
               --          Override:   TRUE        --
               --------------------------------------
               dbms_application_info.set_action ('STORE_TS case 1: REPLACE ALL/TRUE');

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  execute immediate
                     'merge into '||x.table_name||' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= :start_date
                                     and date_time < :end_date) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                         where :l_filter_duplicates = ''F'' or cwms_ts.same_vq(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F''
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)'
                     using l_value_offset,
                           l_timeseries_data,
                           l_ts_code,
                           l_units,
                           from_tz(cast(x.start_date as timestamp),'0:00'),
                           from_tz(cast(x.end_date as timestamp),'0:00'),
                           l_ts_code,
                           l_version_date,
                           l_store_date,
                           l_filter_duplicates,
                           l_ts_code,
                           l_store_date,
                           l_version_date;

                  l_count := l_count + sql%rowcount;
               end loop;
            when not l_override_prot and upper (p_store_rule) = cwms_util.replace_all then
               --------------------------------------
               -- Case 2 - Store Rule: REPLACE ALL --
               --          Override:   FALSE       --
               --------------------------------------
               dbms_application_info.set_action ('STORE_TS case 2: REPLACE ALL/FALSE');

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  execute immediate
                     'merge into '||x.table_name||' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset)  - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= :start_date
                                     and date_time < :end_date) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                          where ((t1.quality_code in (select quality_code
                                                        from cwms_data_quality q
                                                       where q.protection_id = ''UNPROTECTED''))
                                 or
                                 (t2.quality_code in (select quality_code
                                                        from cwms_data_quality q
                                                       where q.protection_id = ''PROTECTED'')))
                            and (:l_filter_duplicates = ''F'' or cwms_ts.same_vq(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F'')
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)'
                     using l_value_offset,
                           l_timeseries_data,
                           l_ts_code,
                           l_units,
                           from_tz(cast(x.start_date as timestamp),'0:00'),
                           from_tz(cast(x.end_date as timestamp),'0:00'),
                           l_ts_code,
                           l_version_date,
                           l_store_date,
                           l_filter_duplicates,
                           l_ts_code,
                           l_store_date,
                           l_version_date;

                  l_count := l_count + sql%rowcount;
               end loop;
            when upper (p_store_rule) = cwms_util.do_not_replace then
               -------------------------------------------
               -- Case 3 - Store Rule: DO NOT REPLACE   --
               --          Override:   TRUE or FALSE    --
               -------------------------------------------
               dbms_application_info.set_action ('STORE_TS case 3: DO NOT REPLACE');

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  execute immediate
                     'merge into '||x.table_name||' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and (t.value is not null 
                                          or (:l_interval_value <= 0 
                                              and cwms_ts.quality_is_missing_text(t.quality_code) = ''T''
                                             ) 
                                          or cwms_ts.quality_is_protected_text(t.quality_code) = ''T''
                                         )
                                     and (cwms_ts.quality_is_missing_text(t.quality_code) = ''F'' 
                                          or :l_interval_value <= 0
                                          or cwms_ts.quality_is_protected_text(t.quality_code) = ''T''
                                         )
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= :start_date
                                     and date_time < :end_date) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)'
                     using l_value_offset,
                           l_timeseries_data,
                           l_interval_value,
                           l_interval_value,
                           l_ts_code,
                           l_units,
                           from_tz(cast(x.start_date as timestamp),'0:00'),
                           from_tz(cast(x.end_date as timestamp),'0:00'),
                           l_ts_code,
                           l_version_date,
                           l_ts_code,
                           l_store_date,
                           l_version_date;

                  l_count := l_count + sql%rowcount;
               end loop;
            when upper (p_store_rule) = cwms_util.replace_missing_values_only then
               --------------------------------------------------------
               -- Case 4 - Store Rule: REPLACE MISSING VALUES ONLY   --
               --          Override:   TRUE or FALSE                 --
               --------------------------------------------------------
               dbms_application_info.set_action ('STORE_TS case 4: REPLACE MISSING VALUES ONLY');

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  if not l_override_prot then
                     -------------------------------
                     -- don't override protection --
                     -------------------------------
                     l_sql_txt :=
                           'merge into '||x.table_name||' t1
                                 using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                               (t.value * c.factor + c.offset) - :l_value_offset value,
                                               cwms_ts.clean_quality_code(t.quality_code) quality_code
                                          from table(cast(:l_timeseries_data as tsv_array)) t,
                                               at_cwms_ts_spec s,
                                               at_parameter ap,
                                               cwms_unit_conversion c,
                                               cwms_base_parameter p,
                                               cwms_unit u
                                         where cwms_util.is_nan(t.value) = ''F''
                                           and s.ts_code = :l_ts_code
                                           and s.parameter_code = ap.parameter_code
                                           and ap.base_parameter_code = p.base_parameter_code
                                           and p.unit_code = c.to_unit_code
                                           and c.from_unit_code = u.unit_code
                                           and u.unit_id = :l_units
                                           and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                           and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                                    on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                            when matched then
                               update set t1.value = t2.value, t1.quality_code = t2.quality_code, t1.data_entry_date = :l_store_date
                                where (t1.quality_code in (select quality_code
                                                             from cwms_data_quality q
                                                            where q.validity_id = ''MISSING'')
                                       and
                                       ((t1.quality_code in (select quality_code
                                                               from cwms_data_quality q
                                                              where q.protection_id = ''UNPROTECTED''))
                                        or
                                        (t2.quality_code in (select quality_code
                                                               from cwms_data_quality q
                                                              where q.protection_id = ''PROTECTED'')))
                                      )
                                      and
                                      (:l_filter_duplicates = ''F'' or cwms_ts.same_vq(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F'')
                            when not matched then
                               insert     (  ts_code,
                                             date_time,
                                             data_entry_date,
                                             value,
                                             quality_code,
                                             version_date)
                                   values (  :l_ts_code,
                                             t2.date_time,
                                             :l_store_date,
                                             t2.value,
                                             t2.quality_code,
                                             :l_version_date)';
                  else
                     -------------------------
                     -- override protection --
                     -------------------------
                     l_sql_txt :=
                           'merge into '||x.table_name||' t1
                                 using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                               (t.value * c.factor + c.offset) - :l_value_offset value,
                                               cwms_ts.clean_quality_code(t.quality_code) quality_code
                                          from table(cast(:l_timeseries_data as tsv_array)) t,
                                               at_cwms_ts_spec s,
                                               at_parameter ap,
                                               cwms_unit_conversion c,
                                               cwms_base_parameter p,
                                               cwms_unit u
                                         where cwms_util.is_nan(t.value) = ''F''
                                           and s.ts_code = :l_ts_code
                                           and s.parameter_code = ap.parameter_code
                                           and ap.base_parameter_code = p.base_parameter_code
                                           and p.unit_code = c.to_unit_code
                                           and c.from_unit_code = u.unit_code
                                           and u.unit_id = :l_units
                                           and date_time >= :start_date
                                           and date_time < :end_date) t2
                                    on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                            when matched then
                               update set t1.value = t2.value, t1.quality_code = t2.quality_code, t1.data_entry_date = :l_store_date
                                where (t1.quality_code in (select quality_code
                                                            from cwms_data_quality q
                                                           where q.validity_id = ''MISSING'')
                                      )
                                      and
                                      (:l_filter_duplicates = ''F'' or cwms_ts.same_vq(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F'')
                            when not matched then
                               insert     (  ts_code,
                                             date_time,
                                             data_entry_date,
                                             value,
                                             quality_code,
                                             version_date)
                                   values (  :l_ts_code,
                                             t2.date_time,
                                             :l_store_date,
                                             t2.value,
                                             t2.quality_code,
                                             :l_version_date)';
                  end if;
                  execute immediate l_sql_txt
                     using l_value_offset,
                           l_timeseries_data,
                           l_ts_code,
                           l_units,
                           from_tz(cast(x.start_date as timestamp),'0:00'),
                           from_tz(cast(x.end_date as timestamp),'0:00'),
                           l_ts_code,
                           l_version_date,
                           l_store_date,
                           l_filter_duplicates,
                           l_ts_code,
                           l_store_date,
                           l_version_date;

                  l_count := l_count + sql%rowcount;
               end loop;
            when l_override_prot and upper (p_store_rule) = cwms_util.replace_with_non_missing then
               ---------------------------------------------------
               -- Case 5 - Store Rule: REPLACE WITH NON MISSING --
               --          Override:   TRUE                     --
               ---------------------------------------------------
               dbms_application_info.set_action ('STORE_TS case 5: REPLACE WITH NON MISSING/TRUE');

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  execute immediate
                     'merge into '||x.table_name||' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u,
                                         cwms_data_quality q
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and (t.value is not null 
                                          or (:l_interval_value <= 0 
                                              and cwms_ts.quality_is_missing_text(t.quality_code) = ''T''
                                             ) 
                                          or cwms_ts.quality_is_protected_text(t.quality_code) = ''T''
                                         )
                                     and (cwms_ts.quality_is_missing_text(t.quality_code) = ''F'' 
                                          or :l_interval_value <= 0
                                          or cwms_ts.quality_is_protected_text(t.quality_code) = ''T''
                                         )
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and q.quality_code = t.quality_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= :start_date
                                     and date_time <  :end_date) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                          where (t2.quality_code not in (select quality_code
                                                           from cwms_data_quality
                                                          where validity_id = ''MISSING'')
                                )
                                and
                                (:l_filter_duplicates = ''F'' or cwms_ts.same_vq(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F'')
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)'
                     using l_value_offset,
                           l_timeseries_data,
                           l_interval_value,
                           l_interval_value,
                           l_ts_code,
                           l_units,
                           from_tz(cast(x.start_date as timestamp),'0:00'),
                           from_tz(cast(x.end_date as timestamp),'0:00'),
                           l_ts_code,
                           l_version_date,
                           l_store_date,
                           l_filter_duplicates,
                           l_ts_code,
                           l_store_date,
                           l_version_date;

                  l_count := l_count + sql%rowcount;
               end loop;
            when not l_override_prot and upper (p_store_rule) = cwms_util.replace_with_non_missing then
               ---------------------------------------------------
               -- Case 6 - Store Rule: REPLACE WITH NON MISSING --
               --          Override:   FALSE                    --
               ---------------------------------------------------
               dbms_application_info.set_action ('STORE_TS case 6: REPLACE WITH NON MISSING/FALSE');

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  execute immediate
                     'merge into '||x.table_name||' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''UTC'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u,
                                         cwms_data_quality q
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and (t.value is not null 
                                          or (:l_interval_value <= 0 
                                              and cwms_ts.quality_is_missing_text(t.quality_code) = ''T''
                                             ) 
                                          or cwms_ts.quality_is_protected_text(t.quality_code) = ''T''
                                         )
                                     and (cwms_ts.quality_is_missing_text(t.quality_code) = ''F'' 
                                          or :l_interval_value <= 0
                                          or cwms_ts.quality_is_protected_text(t.quality_code) = ''T''
                                         )
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and q.quality_code = t.quality_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= :start_date
                                     and date_time <  :end_date) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                          where (((t1.quality_code in (select quality_code
                                                         from cwms_data_quality q
                                                        where q.protection_id = ''UNPROTECTED''))
                                  or
                                  (t2.quality_code in (select quality_code
                                                         from cwms_data_quality q
                                                        where q.protection_id = ''PROTECTED'')))
                                 and
                                 (t2.quality_code not in (select quality_code
                                                            from cwms_data_quality q
                                                           where q.validity_id = ''MISSING''))
                                )
                                and
                                (:l_filter_duplicates = ''F'' or cwms_ts.same_vq(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F'')
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)'
                     using l_value_offset,
                           l_timeseries_data,
                           l_interval_value,
                           l_interval_value,
                           l_ts_code,
                           l_units,
                           from_tz(cast(x.start_date as timestamp),'0:00'),
                           from_tz(cast(x.end_date as timestamp),'0:00'),
                           l_ts_code,
                           l_version_date,
                           l_store_date,
                           l_filter_duplicates,
                           l_ts_code,
                           l_store_date,
                           l_version_date;

                  l_count := l_count + sql%rowcount;
               end loop;
            when upper (p_store_rule) = cwms_util.delete_insert then
               ----------------------------------------
               -- CASE 7 - Store Rule: DELETE INSERT --
               --          Override:   TRUE or FALSE --
               ----------------------------------------
               dbms_application_info.set_action ('STORE_TS case 7: DELETE INSERT');
               --------------------------------------------
               -- pre-process filtered input time series --
               --------------------------------------------
               select ztsv_type(
                         trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone 'UTC') as date), 'mi'),
                         (t.value * c.factor + c.offset) - l_value_offset,
                         cwms_ts.clean_quality_code(t.quality_code))
                 bulk collect
                 into z_timeseries_data
                 from table(cast(l_timeseries_data as tsv_array)) t,
                     at_cwms_ts_spec s,
                     at_parameter p,
                     cwms_unit_conversion c,
                     cwms_base_parameter bp,
                     cwms_unit u
                where cwms_util.is_nan(t.value) = 'F'
                  and s.ts_code = l_ts_code
                  and u.unit_id = l_units
                  and c.from_unit_code = u.unit_code
                  and p.parameter_code = s.parameter_code
                  and bp.base_parameter_code = p.base_parameter_code
                  and c.to_unit_code = bp.unit_code;

               for x in (select start_date, end_date, table_name
                           from at_ts_table_properties
                          where start_date <= maxdate and end_date > mindate
                        )
               loop
                  -------------------------------------------------
                  -- capture the times to delete from this table --
                  -------------------------------------------------
                  execute immediate
                     'select date_time
                        from (select t1.date_time
                                from '||x.table_name||' t1,
                                     table(:z_timeseries_data) t2
                               where t1.ts_code = :ts_code
                                 and t1.date_time = t2.date_time
                                 and t1.version_date = :version_date
                                 and (:filter_duplicates = ''F'' or cwms_ts.same_vq2(t1.value, t1.quality_code, t2.value, t2.quality_code) = ''F'')
                                 and (nvl(:override_prot, ''F'') = ''T''
                                      or
                                      (t2.quality_code in (select quality_code from cwms_data_quality where protection_id = ''PROTECTED'')
                                       or
                                       t1.quality_code not in (select quality_code from cwms_data_quality where protection_id = ''PROTECTED'')
                                      )
                                     )
                              union all
                              select t1.date_time
                                from '||x.table_name||' t1
                               where t1.ts_code = :ts_code
                                 and t1.date_time between :mindate and :maxdate
                                 and t1.date_time not in (select date_time from table(:z_timeseries_data))
                                 and t1.version_date = :version_date
                                 and (nvl(:override_prot, ''F'') = ''T''
                                      or
                                      t1.quality_code not in (select quality_code from cwms_data_quality where protection_id = ''PROTECTED'')
                                     )
                             )
                       order by 1'
                  bulk collect
                     into l_delete_times
                  using
                     z_timeseries_data,
                     l_ts_code,
                     l_version_date,
                     l_filter_duplicates,
                     p_override_prot,
                     l_ts_code,
                     mindate,
                     maxdate,
                     z_timeseries_data,
                     l_version_date,
                     p_override_prot;

                  execute immediate
                     'select t1.date_time
                        from '||x.table_name||' t1
                        where t1.ts_code = :ts_code
                          and t1.version_date = :version_date
                          and t1.date_time between :mindate and :maxdate
                          and t1.date_time not in (select column_value from table(:times))'
                  bulk collect
                  into l_remaining_times
                  using
                     l_ts_code,
                     l_version_date,
                     mindate,
                     maxdate,
                     l_delete_times;

                  if l_delete_times.count > 0 then
                     ------------------------
                     -- record the deletes --
                     ------------------------
                     execute immediate
                        'insert
                           into at_ts_deleted_times
                         select :millis,
                                :ts_code,
                                :version_date,
                                date_time
                           from (select column_value as date_time from table(:times))'
                     using
                        l_millis,
                        l_ts_code,
                        l_version_date,
                              l_delete_times;
                     -------------------------
                     -- delete the old data --
                     -------------------------
                     execute immediate
                        'delete
                           from '||x.table_name||'
                          where ts_code = :ts_code
                            and version_date = :version_date
                            and date_time in (select column_value from table(:times))'
                     using
                        l_ts_code,
                        l_version_date,
                              l_delete_times;
                  end if;
                  -------------------------
                  -- insert the new data --
                  -------------------------
                  execute immediate
                     'insert
                        into '||x.table_name||'
                      select :ts_code,
                             date_time,
                             :version_date,
                             :data_entry_date,
                             value,
                             quality_code,
                             null
                           from (select date_time, value, quality_code from table(:z_timeseries_data) where date_time not in (select column_value from table(:times)))
                       where date_time >= :start_date
                         and date_time <  :end_date'
                  using
                     l_ts_code,
                     l_version_date,
                     l_store_date,
                     z_timeseries_data,
                     l_remaining_times,
                     from_tz(cast(x.start_date as timestamp),'0:00'),
                     from_tz(cast(x.end_date as timestamp),'0:00');

                  l_count := l_count + sql%rowcount;
               end loop;
            else
               cwms_err.raise ('INVALID_STORE_RULE', NVL (p_store_rule, '<NULL>'));
            end case;
            if idx > 1 then
               select distinct
                      to_char(quality_code)
                 bulk collect
                 into l_quality_codes
                 from table(l_timeseries_data)
                order by 1;

               cwms_msg.log_db_message(
                  cwms_msg.msg_level_detailed,
                  'STORE_TS : data stored after '||(idx-1)||' failed tries for '||l_cwms_ts_id||chr(10)||
                  'Store Rule    = '||upper(p_store_rule)||chr(10)||
                  'Override Prot = '||case when l_override_prot then 'TRUE' else 'FALSE' end||chr(10)||
                  'Quality Codes = '||cwms_util.join_text(l_quality_codes, ', '));
            end if;
            exit; -- successfully stored data
         exception
            when dup_val_on_index then
               if idx < i_max_iterations then
                  ---------------
                  -- try again --
                  ---------------
                  dbms_lock.sleep(.02);
               else
                  ---------------------
                  -- tries exhausted --
                  ---------------------
                  select distinct
                         to_char(quality_code)
                    bulk collect
                    into l_quality_codes
                    from table(l_timeseries_data)
                   order by 1;

                  cwms_msg.log_db_message(
                     cwms_msg.msg_level_detailed,
                     'STORE_TS : data not stored after '||(idx)||' failed tries for '||l_cwms_ts_id||chr(10)||
                     'Store Rule    = '||upper(p_store_rule)||chr(10)||
                     'Override Prot = '||case when l_override_prot then 'TRUE' else 'FALSE' end||chr(10)||
                     'Quality Codes = '||cwms_util.join_text(l_quality_codes, ', '));
                  raise;
               end if;
         end;
      end loop;

      if l_count > 0  then
         ------------------------------------
         -- update the time series extents --
         ------------------------------------
         if upper (p_store_rule) = cwms_util.delete_insert then
            ----------------------------------------------
            -- possibly deleted some time series values --
            ----------------------------------------------
            if l_delete_times is not null then
               declare
                  job_name_already_exists exception;
                  l_plsql_block             VARCHAR2 (256);
                  pragma exception_init(job_name_already_exists, -27477);
                  l_job_name varchar2(64) := 'UTX_'||l_ts_code||'_'||to_char(l_version_date, 'yyyymmdd_hh24miss');
               begin
                  begin
                    IF (l_version_date IS NULL)
                            THEN
                                l_plsql_block :=
                                       'begin cwms_env.set_session_office_id('''
                                    || SYS_CONTEXT ('CWMS_ENV',
                                                    'SESSION_OFFICE_ID')
                                    || '''); cwms_ts.update_ts_extents('''
                                    || l_ts_code
                                    || '''); end;';
                            ELSE
                                l_plsql_block :=
                                       'begin cwms_env.set_session_office_id('''
                                    || SYS_CONTEXT ('CWMS_ENV',
                                                    'SESSION_OFFICE_ID')
                                    || '''); cwms_ts.update_ts_extents('''
                                    || l_ts_code
                                    || ''',to_date('''
                                    || TO_CHAR (l_version_date,
                                                'YYYY-MM-DD HH24:MI:SS')
                                    || ''',''YYYY-MM-DD HH24:MI:SS'')); end;';
                            END IF;
                     dbms_scheduler.create_job (
                        job_name            => l_job_name,
                        job_type            => 'PLSQL_BLOCK',
                        job_action          => l_plsql_block,
                        comments            => 'Updates the time series extents.');
                       dbms_scheduler.enable(l_job_name);
                  exception
                     when job_name_already_exists then
                        cwms_msg.log_db_message(
                           cwms_msg.msg_level_normal,
                           'UPDATE_TS_EXTENTS with '
                           ||l_ts_code
                           ||', '
                           ||nvl(to_char(l_version_date), 'NULL')
                           ||' already running.');
                  end;
               end;
            end if;
         else
            ----------------
            -- no deletes --
            ----------------
            begin
            select l_ts_code,
                   l_version_date,
                   mindate,
                   l_store_date,
                   l_store_date,
                   q2.earliest_non_null_time,
                   l_store_date,
                   l_store_date,
                   maxdate,
                   l_store_date,
                   l_store_date,
                   q2.latest_non_null_time,
                   l_store_date,
                   l_store_date,
                   case
                   when c.function is null then q1.least_value * c.factor + c.offset
                   else cwms_util.eval_expression(c.function, double_tab_t(q1.least_value))
                   end,
                   q4.least_value_time,
                   l_store_date,
                   case
                   when c.function is null then q3.least_accepted_value * c.factor + c.offset
                   else cwms_util.eval_expression(c.function, double_tab_t(q3.least_accepted_value))
                   end,
                   q6.least_accepted_value_time,
                   l_store_date,
                   case
                   when c.function is null then q1.greatest_value * c.factor + c.offset
                   else cwms_util.eval_expression(c.function, double_tab_t(q1.greatest_value))
                   end,
                   q5.greatest_value_time,
                   l_store_date,
                   case
                   when c.function is null then q3.greatest_accepted_value * c.factor + c.offset
                   else cwms_util.eval_expression(c.function, double_tab_t(q3.greatest_accepted_value))
                   end,
                   q7.greatest_accepted_value_time,
                   l_store_date,
                   l_store_date
              into l_ts_extents_rec
              from at_cwms_ts_spec s,
                   at_parameter p,
                   cwms_unit_conversion c,
                   cwms_base_parameter bp,
                   cwms_unit u,
                   (select min(value) as least_value,
                           max(value) as greatest_value
                      from table(l_timeseries_data)
                   ) q1
                   join
                   (select min(date_time) as earliest_non_null_time,
                           max(date_time) as latest_non_null_time
                      from table(l_timeseries_data)
                     where value is not null
                   ) q2 on 1=1
                   join
                   (select min(value) as least_accepted_value,
                           max(value) as greatest_accepted_value
                      from table(l_timeseries_data)
                     where bitand(quality_code, 30) in (0,2,8)
                   ) q3 on 1=1
                   join
                   (select value,
                           max(date_time) as least_value_time
                      from table(l_timeseries_data)
                     group by value
                   ) q4 on q4.value = q1.least_value
                   join
                   (select value,
                           max(date_time) as greatest_value_time
                      from table(l_timeseries_data)
                     group by value
                   ) q5 on q5.value = q1.greatest_value
                   join
                   (select max(date_time) as least_accepted_value_time,
                           value
                      from table(l_timeseries_data)
                     group by value
                   ) q6 on q6.value = q3.least_accepted_value
                   join
                   (select max(date_time) as greatest_accepted_value_time,
                           value
                      from table(l_timeseries_data)
                     group by value
                   ) q7 on q7.value = q3.greatest_accepted_value
             where s.ts_code = l_ts_code
               and u.unit_id = l_units
               and c.from_unit_code = u.unit_code
               and p.parameter_code = s.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and c.to_unit_code = bp.unit_code;

            declare
               l_updated boolean;
            begin
               l_updated := update_ts_extents(l_ts_extents_rec);
            end;
            exception
               when no_data_found then cwms_msg.log_db_message (
                  1,
                  'NO DATA FOUND on updating TS Extents for '||l_office_id||'/'||l_cwms_ts_id);
            end;
         end if;

         ---------------------------------
         -- archive and publish message --
         ---------------------------------
         declare
            l_first_time timestamp with time zone;
            l_last_time  timestamp with time zone;
         begin
            select min(date_time)
              into l_first_time
              from table(l_timeseries_data);
            select max(date_time)
              into l_last_time
              from table(l_timeseries_data);
            time_series_updated (
               l_ts_code,
               l_cwms_ts_id,
               l_office_id,
               l_first_time,
               l_last_time,
               FROM_TZ (CAST (l_version_date AS TIMESTAMP), 'UTC'),
               l_store_date,
               upper(p_store_rule));
         end;
      end if;


      dbms_application_info.set_module (null, null);
      commit;
   exception
      when others
      then
         if l_timeseries_data is null then
            cwms_msg.log_db_message (
               1,
               'STORE_TS ERROR on '
               || l_cwms_ts_id
               ||chr(10)
               ||sqlerrm
               ||chr(10)
               ||dbms_utility.format_error_backtrace);
         else
            cwms_msg.log_db_message (
               1,
               'STORE_TS ERROR on '
               || l_cwms_ts_id
               ||chr(10)
               ||sqlerrm
               ||chr(10)
               ||dbms_utility.format_error_backtrace
               ||l_timeseries_data.count
               ||' values'
               ||chr(10)
               ||'first = '
               ||l_timeseries_data(1).date_time
               ||chr(9)
               ||l_timeseries_data(1).value
               ||chr(9)
               ||l_timeseries_data(1).quality_code
               ||chr(10)
               ||'last = '
               ||l_timeseries_data(l_timeseries_data.count).date_time
               ||chr(9)
               ||l_timeseries_data(l_timeseries_data.count).value
               ||chr(9)
               ||l_timeseries_data(l_timeseries_data.count).quality_code);
         end if;
         cwms_err.raise ('ERROR', dbms_utility.format_error_backtrace);
   end store_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS - This version is for Python/CxOracle
   --
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units           IN VARCHAR2,
      p_times           IN number_array,
      p_values          IN double_array,
      p_qualities       IN number_array,
      p_store_rule      IN VARCHAR2,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries_data   tsv_array := tsv_array ();
      i                   BINARY_INTEGER;
   BEGIN
      IF p_values.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR', 'Inconsistent number of times and values.');
      END IF;

      IF p_qualities.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR',
                         'Inconsistent number of times and qualities.');
      END IF;

      l_timeseries_data.EXTEND (p_times.COUNT);

      FOR i IN 1 .. p_times.COUNT
      LOOP
         l_timeseries_data (i) :=
            tsv_type (FROM_TZ (cwms_util.TO_TIMESTAMP (p_times (i)), 'UTC'),
                      p_values (i),
                      p_qualities (i));
      END LOOP;

      store_ts (p_cwms_ts_id,
                p_units,
                l_timeseries_data,
                p_store_rule,
                p_override_prot,
                p_version_date,
                p_office_id);
   END store_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS - This version is for Java/Jython bypassing TIMESTAMPTZ type
   --
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units           IN VARCHAR2,
      p_times           IN number_tab_t,
      p_values          IN number_tab_t,
      p_qualities       IN number_tab_t,
      p_store_rule      IN VARCHAR2,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries_data   tsv_array := tsv_array ();
      i                   BINARY_INTEGER;
   BEGIN
      IF p_values.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR', 'Inconsistent number of times and values.');
      END IF;

      IF p_qualities.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR',
                         'Inconsistent number of times and qualities.');
      END IF;

      l_timeseries_data.EXTEND (p_times.COUNT);

      FOR i IN 1 .. p_times.COUNT
      LOOP
         l_timeseries_data (i) :=
            tsv_type (FROM_TZ (cwms_util.TO_TIMESTAMP (p_times (i)), 'UTC'),
                      p_values (i),
                      p_qualities (i));
      END LOOP;

      store_ts (p_cwms_ts_id,
                p_units,
                l_timeseries_data,
                p_store_rule,
                p_override_prot,
                p_version_date,
                p_office_id);
   END store_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS_MULTI -
   --
   procedure store_ts_multi (
      p_timeseries_array   in timeseries_array,
      p_store_rule         in varchar2,
      p_override_prot      in varchar2 default 'F',
      p_version_dates      in date_table_type default null,
      p_office_id          in varchar2 default null)
   is
      l_err_msg        varchar2 (722)  := null;
      l_all_err_msgs   varchar2 (2048) := null;
      l_version_dates  date_table_type := date_table_type();
      l_len            pls_integer := 0;
      l_total_len      pls_integer := 0;
      l_num_ts_ids     pls_integer := 0;
      l_num_errors     pls_integer := 0;
      l_excep_errors   pls_integer := 0;
   begin

      if p_timeseries_array is not null then
         dbms_application_info.set_module (
            'cwms_ts_store.store_ts_multi',
            'processing parameters');
         if p_version_dates is not null and p_version_dates.count != p_timeseries_array.count then
            cwms_err.raise(
               'ERROR',
               'Counts of time series and version dates don''t match.');
         end if;
         l_version_dates.extend(p_timeseries_array.count);
         for i in 1..l_version_dates.count loop
            if p_version_dates is null or p_version_dates(i) is null then
               l_version_dates(i) := cwms_util.non_versioned;
            else
               l_version_dates(i) := p_version_dates(i);
            end if;
         end loop;
         for i in 1..p_timeseries_array.count loop
            dbms_application_info.set_module (
               'cwms_ts_store.store_ts_multi',
               'calling store_ts');

            begin
               store_ts (p_timeseries_array(i).tsid,
                         p_timeseries_array(i).unit,
                         p_timeseries_array(i).data,
                         p_store_rule,
                         p_override_prot,
                         l_version_dates(i),
                         p_office_id);
            exception
               when others then
                  l_num_errors := l_num_errors + 1;

                  l_err_msg :=
                        'STORE_ERROR ***'
                     || p_timeseries_array(i).tsid
                     || '*** '
                     || sqlcode
                     || ': '
                     || sqlerrm;

                  if   nvl (length (l_all_err_msgs), 0)
                     + nvl (length (l_err_msg),      0) <= 1930
                  then
                     l_excep_errors := l_excep_errors + 1;
                     l_all_err_msgs := l_all_err_msgs || ' ' || l_err_msg;
                  end if;
            end;
         end loop;
      end if;

      if l_all_err_msgs is not null then
         l_all_err_msgs :=
               'STORE ERRORS: store_ts_multi processed '
            || l_num_ts_ids
            || ' ts_ids of which '
            || l_num_errors
            || ' had STORE ERRORS. '
            || l_excep_errors
            || ' of those errors are: '
            || l_all_err_msgs;

         raise_application_error (-20999, l_all_err_msgs);
      end if;


      dbms_application_info.set_module (null, null);
   end store_ts_multi;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS_MULTI -
   --
   procedure store_ts_multi (
      p_timeseries_array   in timeseries_array,
      p_store_rule         in varchar2,
      p_override_prot      in varchar2 default 'F',
      p_version_date       in date default cwms_util.non_versioned,
      p_office_id          in varchar2 default null)
   is
      l_version_dates date_table_type;
   begin
      if p_timeseries_array is not null then
         l_version_dates := date_table_type();
         l_version_dates.extend(p_timeseries_array.count);
         for i in 1..p_timeseries_array.count loop
            l_version_dates(i) := p_version_date;
         end loop;
         store_ts_multi(
            p_timeseries_array,
            p_store_rule,
            p_override_prot,
            l_version_dates,
            p_office_id);
      end if;
   end store_ts_multi;

   --
   --*******************************************************************   --
   --** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE ****   --
   --
   -- DELETE_TS_CLEANUP -
   --

   PROCEDURE delete_ts_cleanup (p_ts_code_old IN NUMBER)
   IS
   BEGIN
      -- NOTE TO GERHARD Need to think about cleaning up
      -- all of the dependancies when deleting.
      DELETE FROM at_shef_decode
            WHERE ts_code = p_ts_code_old;
   END delete_ts_cleanup;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- DELETE_TS -
   --
   ---------------------------------------------------------------------   --
   -- valid p_delete_actions:                                              --
   --  delete_ts_id:      This action will delete the cwms_ts_id only if there
   --                     is no actual data associated with this cwms_ts_id.
   --                     If there is data assciated with the cwms_ts_id, then
   --                     an exception is thrown.
   --  delete_ts_data:    This action will delete all of the data associated
   --                     with the cwms_ts_id. The cwms_ts_id is not deleted.
   --  delete_ts_cascade: This action will delete both the data and the
   --                     cwms_ts_id.
   ----------------------------------------------------------------------  --


   PROCEDURE delete_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_ts_id,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_code   NUMBER := cwms_util.GET_OFFICE_CODE (p_db_office_id);
   BEGIN
      delete_ts (p_cwms_ts_id       => p_cwms_ts_id,
                 p_delete_action    => p_delete_action,
                 p_db_office_code   => l_db_office_code);
   END;

   procedure delete_ts(
      p_cwms_ts_id     in varchar2,
      p_delete_action  in varchar2,
      p_db_office_code in number)
   is
      l_db_office_code   number := p_db_office_code;
      l_db_office_id     varchar2(16);
      l_cwms_ts_id       varchar2(191);
      l_ts_code          number;
      l_count            number;
      l_value_count      number;
      l_std_text_count   number;
      l_text_count       number;
      l_binary_count     number;
      l_delete_action    varchar2(22) := upper(nvl(p_delete_action, cwms_util.delete_ts_id));
      l_delete_date      timestamp(9) := systimestamp;
      l_msg              sys.aq$_jms_map_message;
      l_msgid            pls_integer;
      i                  integer;
   begin
      if p_db_office_code is null then
         l_db_office_code := cwms_util.get_office_code(null);
      end if;

      select office_id
        into l_db_office_id
        from cwms_office
       where office_code = l_db_office_code;

      l_cwms_ts_id := get_cwms_ts_id(p_cwms_ts_id, l_db_office_id);

      begin
         select ts_code
           into l_ts_code
           from at_cwms_ts_id mcts
          where upper(mcts.cwms_ts_id) = upper(l_cwms_ts_id) and mcts.db_office_code = l_db_office_code;
      exception
         when no_data_found then
            begin
               select ts_code
                 into l_ts_code
                 from at_cwms_ts_id mcts
                where upper(mcts.cwms_ts_id) = upper(l_cwms_ts_id) and mcts.db_office_code = l_db_office_code;
            exception
               when no_data_found then
                  cwms_err.raise('TS_ID_NOT_FOUND', l_cwms_ts_id,cwms_util.get_db_office_id_from_code(p_db_office_code));
            end;
      end;

      ----------------------------------------------
      -- translate non-ts-specific delete_actions --
      ----------------------------------------------
      if l_delete_action = cwms_util.delete_key then
         l_delete_action := cwms_util.delete_ts_id;
      end if;

      if l_delete_action = cwms_util.delete_all then
         l_delete_action := cwms_util.delete_ts_cascade;
      end if;

      if l_delete_action = cwms_util.delete_data then
         l_delete_action := cwms_util.delete_ts_data;
      end if;

      case
         when l_delete_action = cwms_util.delete_ts_id then
            select count(*)
              into l_value_count
              from av_tsv
             where ts_code = l_ts_code;

            select count(*)
              into l_std_text_count
              from at_tsv_std_text
             where ts_code = l_ts_code;

            select count(*)
              into l_text_count
              from at_tsv_text
             where ts_code = l_ts_code;

            select count(*)
              into l_binary_count
              from at_tsv_binary
             where ts_code = l_ts_code;

            l_count := l_value_count + l_std_text_count + l_text_count + l_binary_count;

            if l_count = 0 then
               loop
                  begin
                     update at_cwms_ts_spec
                        set location_code = 0, delete_date = l_delete_date
                      where ts_code = l_ts_code;

                     exit;
                  exception
                     when others then
                        if sqlcode = -1 then
                           l_delete_date := systimestamp;
                        end if;
                  end;
               end loop;
            else
               cwms_err.raise('ERROR', 'cwms_ts_id: ' || p_cwms_ts_id || ' contains data. Cannot use the DELETE TS ID action');
            end if;
         when l_delete_action in (cwms_util.delete_ts_cascade, cwms_util.delete_ts_data) then
            -------------------------------
            -- delete data from database --
            -------------------------------
            for rec in (select table_name
                          from at_ts_table_properties
                         where start_date in (select distinct start_date
                                                from av_tsv
                                               where ts_code = l_ts_code)) loop
               execute immediate replace('delete from $t where ts_code = :1', '$t', rec.table_name) using l_ts_code;
            end loop;

            delete from at_tsv_std_text
                  where ts_code = l_ts_code;

            delete from at_tsv_text
                  where ts_code = l_ts_code;

            delete from at_tsv_binary
                  where ts_code = l_ts_code;

            if l_delete_action = cwms_util.delete_ts_cascade then
               ---------------------------------------
               -- delete location group assignments --
               ---------------------------------------
               delete
                 from at_ts_group_assignment
                where ts_code = l_ts_code
                   or ts_ref_code = l_ts_code;
               ------------------------------
               -- delete the timeseries id --
               ------------------------------
               update at_cwms_ts_spec
                  set location_code = 0, delete_date = l_delete_date
                where ts_code = l_ts_code;

               delete_ts_cleanup(l_ts_code);
            end if;

            commit;
         else
            cwms_err.raise('INVALID_DELETE_ACTION', p_delete_action);
      end case;

      ---------------------------
      -- update the ts extents --
      ---------------------------
      delete from at_ts_extents where ts_code = l_ts_code;

      if l_delete_action in (cwms_util.delete_ts_id, cwms_util.delete_ts_cascade) then
         -------------------------------
         -- publish TSDeleted message --
         -------------------------------
         cwms_msg.new_message(l_msg, l_msgid, 'TSDeleted');
         l_msg.set_string(l_msgid, 'ts_id', l_cwms_ts_id);
         l_msg.set_string(l_msgid, 'office_id', l_db_office_id);
         l_msg.set_long(l_msgid, 'ts_code', l_ts_code);
         i := cwms_msg.publish_message(l_msg, l_msgid, l_db_office_id || '_ts_stored');
      end if;
   end delete_ts;

   procedure delete_ts (
      p_cwms_ts_id           in varchar2,
      p_override_protection  in varchar2,
      p_start_time           in date,
      p_end_time             in date,
      p_start_time_inclusive in varchar2,
      p_end_time_inclusive   in varchar2,
      p_version_date         in date,
      p_time_zone            in varchar2 default null,
      p_date_times           in date_table_type default null,
      p_max_version          in varchar2 default 'T',
      p_ts_item_mask         in integer default cwms_util.ts_all,
      p_db_office_id         in varchar2 default null)
   is
      l_ts_code    integer;
      l_start_time date;
      l_end_time   date;
      l_time_zone  varchar2(28);
      l_date_times date_table_type;
   begin
      l_ts_code := get_ts_code(p_cwms_ts_id, p_db_office_id);
      l_time_zone := cwms_util.get_timezone(nvl(p_time_zone, cwms_loc.get_local_timezone(cwms_util.split_text(p_cwms_ts_id, 1, '.'), p_db_office_id)));
      if p_date_times is not null then
         select cwms_util.change_timezone(column_value, l_time_zone, 'UTC')
           bulk collect
           into l_date_times
           from table(p_date_times);
      end if;
      if p_date_times is null then
         if cwms_util.is_true(p_start_time_inclusive) then
            l_start_time := p_start_time;
         else
            l_start_time := p_start_time + 1/86400;
         end if;
         if cwms_util.is_true(p_end_time_inclusive) then
            l_end_time := p_end_time;
         else
            l_end_time := p_end_time - 1/86400;
         end if;
      end if;
      purge_ts_data(
         l_ts_code,
         p_override_protection,
         case p_version_date = cwms_util.non_versioned
            when true then p_version_date
            else cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC')
         end,
         cwms_util.change_timezone(l_start_time, l_time_zone, 'UTC'),
         cwms_util.change_timezone(l_end_time, l_time_zone, 'UTC'),
         l_date_times,
         p_max_version,
         p_ts_item_mask);
   end delete_ts;

   procedure delete_ts (
      p_timeseries_info      in timeseries_req_array,
      p_override_protection  in varchar2,
      p_start_time_inclusive in varchar2,
      p_end_time_inclusive   in varchar2,
      p_version_date         in date,
      p_time_zone            in varchar2 default null,
      p_max_version          in varchar2 default 'T',
      p_ts_item_mask         in integer default cwms_util.ts_all,
      p_db_office_id         in varchar2 default null)
   is
   begin
      if p_timeseries_info is not null then
         for i in 1..p_timeseries_info.count loop
            delete_ts(
                p_cwms_ts_id           => p_timeseries_info(i).tsid,
                p_override_protection  => p_override_protection,
                p_start_time           => p_timeseries_info(i).start_time,
                p_end_time             => p_timeseries_info(i).end_time,
                p_start_time_inclusive => p_start_time_inclusive,
                p_end_time_inclusive   => p_end_time_inclusive,
                p_version_date         => p_version_date,
                p_time_zone            => p_time_zone,
                p_date_times           => null,
                p_max_version          => p_max_version,
                p_ts_item_mask         => p_ts_item_mask,
                p_db_office_id         => p_db_office_id);
         end loop;
      end if;
   end delete_ts;

   procedure purge_ts_data(
      p_ts_code          in number,
      p_version_date_utc in date,
      p_start_time_utc   in date,
      p_end_time_utc     in date,
      p_date_times_utc   in date_table_type default null,
      p_max_version      in varchar2 default 'T',
      p_ts_item_mask     in integer default cwms_util.ts_all)
   is
   begin
      purge_ts_data(
         p_ts_code,
         'ERROR',
         p_version_date_utc,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_max_version,
         p_ts_item_mask);
   end purge_ts_data;

   procedure purge_ts_data(
      p_ts_code             in number,
      p_override_protection in varchar2,
      p_version_date_utc    in date,
      p_start_time_utc      in date,
      p_end_time_utc        in date,
      p_date_times_utc      in date_table_type default null,
      p_max_version         in varchar2 default 'T',
      p_ts_item_mask        in integer default cwms_util.ts_all)
   is
      l_tsid                     varchar2(191);
      l_office_id                varchar2(16);
      l_override_protection      boolean;
      l_error_on_protection      boolean;
      l_deleted_time             timestamp := systimestamp at time zone 'UTC';
      l_msg                      sys.aq$_jms_map_message;
      l_msgid                    pls_integer;
      i                          integer;
      l_protected_count          integer;
      l_max_version              boolean;
      l_date_times_values        date_table_type := date_table_type();
      l_version_dates_values     date_table_type := date_table_type();
      l_date_times_std_text      date_table_type := date_table_type();
      l_version_dates_std_text   date_table_type := date_table_type();
      l_date_times_text          date_table_type := date_table_type();
      l_version_dates_text       date_table_type := date_table_type();
      l_date_times_binary        date_table_type := date_table_type();
      l_version_dates_binary     date_table_type := date_table_type();
      l_times_values             date2_tab_t := date2_tab_t();
      l_times_std_text           date2_tab_t := date2_tab_t();
      l_times_text               date2_tab_t := date2_tab_t();
      l_times_binary             date2_tab_t := date2_tab_t();
      l_cursor                   sys_refcursor;
      l_ts_extents_rec           at_ts_extents%rowtype;
      l_text                     varchar2(32767);
   begin
      if p_date_times_utc is null then
         l_text := 'NULL';
      else
         select listagg(to_char(column_value, 'yyyy-mm-dd hh24:mi'), ',') within group (order by column_value)
           into l_text
           from table(p_date_times_utc);
         l_text := '('||l_text||')';
      end if;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_normal,
         'CWMS_TS.PURGE_TS('
         ||chr(10)||'   p_ts_code             =>'||p_ts_code||','
         ||chr(10)||'   p_override_protection =>'||p_override_protection||','
         ||chr(10)||'   p_version_date_utc    =>'||to_char(p_version_date_utc, 'yyyy-mm-dd hh24:mi')||','
         ||chr(10)||'   p_start_time_utc      =>'||to_char(p_start_time_utc, 'yyyy-mm-dd hh24:mi')||','
         ||chr(10)||'   p_end_time_utc        =>'||to_char(p_end_time_utc, 'yyyy-mm-dd hh24:mi')||','
         ||chr(10)||'   p_date_times_utc      =>'||l_text||','
         ||chr(10)||'   p_max_version         =>'||p_max_version||','
         ||chr(10)||'   p_ts_item_mask        =>'||p_ts_item_mask||')');

      l_max_version := cwms_util.return_true_or_false(p_max_version);
      if instr('ERROR', upper(trim(p_override_protection))) = 1 then
         l_override_protection := false;
         l_error_on_protection := true;
      else
         l_override_protection := cwms_util.return_true_or_false(p_override_protection);
         l_error_on_protection := false;
      end if;

      --------------------------------------------------------------------
      -- get the date_times and version_dates of all the items to purge --
      --------------------------------------------------------------------
      if bitand(p_ts_item_mask, cwms_util.ts_values) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_values);

         fetch l_cursor
         bulk collect into l_date_times_values, l_version_dates_values;
         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_std_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_std_text);

         fetch l_cursor
         bulk collect into l_date_times_std_text, l_version_dates_std_text;
         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_text);

         fetch l_cursor
         bulk collect into l_date_times_text, l_version_dates_text;
         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_binary) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_binary);

         fetch l_cursor
         bulk collect into l_date_times_binary, l_version_dates_binary;
         close l_cursor;
      end if;

      -------------------------------------------------
      -- collect the times into queryable structures --
      -------------------------------------------------
      l_times_values.extend(l_date_times_values.count);

      for i in 1 .. l_date_times_values.count loop
         l_times_values(i) := date2_t(l_date_times_values(i), l_version_dates_values(i));
      end loop;

      l_times_std_text.extend(l_date_times_std_text.count);

      for i in 1 .. l_date_times_std_text.count loop
         l_times_std_text(i) := date2_t(l_date_times_std_text(i), l_version_dates_std_text(i));
      end loop;

      l_times_text.extend(l_date_times_text.count);

      for i in 1 .. l_date_times_text.count loop
         l_times_text(i) := date2_t(l_date_times_text(i), l_version_dates_text(i));
      end loop;

      l_times_binary.extend(l_date_times_binary.count);

      for i in 1 .. l_date_times_binary.count loop
         l_times_binary(i) := date2_t(l_date_times_binary(i), l_version_dates_binary(i));
      end loop;

      ----------------------------------------
      -- perform actions specific to values --
      ----------------------------------------
      if l_times_values.count > 0 then
         if l_error_on_protection then
            ------------------------------
            -- check for protected data --
            ------------------------------
            for rec
               in (select table_name
                     from at_ts_table_properties
                    where start_date in (select distinct v.start_date
                                           from cwms_v_tsv v, table(l_times_values) d
                                          where v.ts_code = p_ts_code and v.date_time = d.date_1 and v.version_date = d.date_2)) loop
               execute immediate replace(
                    'select count(*)
                       from $t
                      where rowid in (select t.rowid
                                         from $t t,
                                              table(:1) d
                                        where t.ts_code = :2
                                          and t.date_time = d.date_1
                                          and t.version_date = d.date_2
                                          and bitand(t.quality_code, 2147483648) <> 0)', '$t', rec.table_name)
                  into l_protected_count
                 using l_times_values, p_ts_code;

               if l_protected_count > 0 then
                  cwms_err.raise('ERROR', 'One or more values are protected');
               end if;
            end loop;

         end if;
         ------------------------------------------
         -- insert records into at_deleted_times --
         ------------------------------------------
         insert into at_ts_deleted_times
            select cwms_util.to_millis(l_deleted_time),
                   p_ts_code,
                   d.version_date,
                   d.date_time
              from (select date_1 as date_time, date_2 as version_date from table(l_times_values)) d;
        ------------------------------------
         -- Publish TSDataDeleted messages --
         ------------------------------------
         select cwms_ts_id, db_office_id
           into l_tsid, l_office_id
           from cwms_v_ts_id
          where ts_code = p_ts_code;

         for rec1 in (select distinct date_2 as version_date from table(l_times_values)) loop
            for rec2 in (select min(date_1) as start_time, max(date_1) as end_time
                           from table(l_times_values)
                          where date_2 = rec1.version_date) loop
               cwms_msg.new_message(l_msg, l_msgid, 'TSDataDeleted');
               l_msg.set_string(l_msgid, 'ts_id', l_tsid);
               l_msg.set_string(l_msgid, 'office_id', l_office_id);
               l_msg.set_long(l_msgid, 'ts_code', p_ts_code);
               l_msg.set_long(l_msgid, 'start_time', cwms_util.to_millis(cast(rec2.start_time as timestamp)));
               l_msg.set_long(l_msgid, 'end_time', cwms_util.to_millis(cast(rec2.end_time as timestamp)));
               l_msg.set_long(l_msgid, 'version_date', cwms_util.to_millis(cast(rec1.version_date as timestamp)));
               l_msg.set_long(l_msgid, 'deleted_time', cwms_util.to_millis(l_deleted_time));
               i := cwms_msg.publish_message(l_msg, l_msgid, l_office_id || '_ts_stored');
            end loop;
         end loop;
      end if;
      ------------------------------
      -- actually delete the data --
      ------------------------------
      for rec
         in (select table_name
               from at_ts_table_properties
              where start_date in (select distinct v.start_date
                                     from cwms_v_tsv v, table(l_times_values) d
                                    where v.ts_code = p_ts_code and v.date_time = d.date_1 and v.version_date = d.date_2)) loop
         if l_override_protection then
            execute immediate replace(
                 'delete
                    from $t
                   where rowid in (select t.rowid
                                      from $t t,
                                           table(:1) d
                                     where t.ts_code = :2
                                       and t.date_time = d.date_1
                                       and t.version_date = d.date_2)', '$t', rec.table_name)
               using l_times_values, p_ts_code;
         else
            execute immediate replace(
                 'delete
                    from $t
                   where rowid in (select t.rowid
                                      from $t t,
                                           table(:1) d
                                     where t.ts_code = :2
                                       and t.date_time = d.date_1
                                       and t.version_date = d.date_2
                                       and bitand(t.quality_code, 2147483648) = 0)', '$t', rec.table_name)
               using l_times_values, p_ts_code;
         end if;
      end loop;

      delete from at_tsv_std_text
            where rowid in (select t.rowid
                              from at_tsv_std_text t, table(l_times_std_text) d
                             where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      delete from at_tsv_text
            where rowid in (select t.rowid
                              from at_tsv_text t, table(l_times_text) d
                             where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      delete from at_tsv_binary
            where rowid in (select t.rowid
                              from at_tsv_binary t, table(l_times_binary) d
                             where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);
      ---------------------------
      -- update the ts extents --
      ---------------------------
      declare
         job_name_already_exists exception;
         pragma exception_init(job_name_already_exists, -27477);
         l_job_name varchar2(64) := 'UTX_'||p_ts_code||'_'||to_char(p_version_date_utc, 'yyyymmdd_hh24miss');
      begin
         begin
            dbms_scheduler.create_job (
               job_name            => l_job_name,
               job_type            => 'stored_procedure',
               job_action          => 'cwms_ts.update_ts_extents',
               number_of_arguments => 2,
               comments            => 'Updates the time series extents.');
            dbms_scheduler.set_job_argument_value(
               job_name          => l_job_name,
               argument_position => 1,
               argument_value    => p_ts_code);
            dbms_scheduler.set_job_argument_value(
               job_name          => l_job_name,
               argument_position => 2,
               argument_value    => p_version_date_utc);
            dbms_scheduler.enable(l_job_name);
         exception
            when job_name_already_exists then
               cwms_msg.log_db_message(
                  cwms_msg.msg_level_normal,
                  'UPDATE_TS_EXTENTS with '
                  ||p_ts_code
                  ||', '
                  ||nvl(to_char(p_version_date_utc), 'NULL')
                  ||' already running.');
         end;
      end;
   end purge_ts_data;

   procedure change_version_date(
      p_ts_code              in number,
      p_old_version_date_utc in date,
      p_new_version_date_utc in date,
      p_start_time_utc       in date,
      p_end_time_utc         in date,
      p_date_times_utc       in date_table_type default null,
      p_ts_item_mask         in integer default cwms_util.ts_all)
   is
      l_is_versioned             varchar2(1);
      l_date_times_values        date_table_type := date_table_type();
      l_version_dates_values     date_table_type := date_table_type();
      l_date_times_std_text      date_table_type := date_table_type();
      l_version_dates_std_text   date_table_type := date_table_type();
      l_date_times_text          date_table_type := date_table_type();
      l_version_dates_text       date_table_type := date_table_type();
      l_date_times_binary        date_table_type := date_table_type();
      l_version_dates_binary     date_table_type := date_table_type();
      l_times_values             date2_tab_t := date2_tab_t();
      l_times_std_text           date2_tab_t := date2_tab_t();
      l_times_text               date2_tab_t := date2_tab_t();
      l_times_binary             date2_tab_t := date2_tab_t();
      l_cursor                   sys_refcursor;
   begin
      -------------------
      -- sanity checks --
      -------------------
      is_ts_versioned(l_is_versioned, p_ts_code);

      if cwms_util.is_false(l_is_versioned) then
         cwms_err.raise('ERROR', 'Cannot change version date on non-versioned data.');
      end if;

      if cwms_util.all_version_dates in (p_old_version_date_utc, p_new_version_date_utc) then
         cwms_err.raise('ERROR', 'CWMS_UTIL.ALL_VERSION_DATES cannot be used for actual version date');
      end if;

      -------------------------------------------------------------------------------
      -- NOTE: The version dates in all the following collections will be the same --
      -- as the p_old_version_date_utc parameter                                   --
      -------------------------------------------------------------------------------

      ---------------------------------------------------------------------
      -- get the date_times and version_dates of all the items to update --
      ---------------------------------------------------------------------
      if bitand(p_ts_item_mask, cwms_util.ts_values) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_values);

         fetch l_cursor
         bulk collect into l_date_times_values, l_version_dates_values;

         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_std_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_std_text);

         fetch l_cursor
         bulk collect into l_date_times_std_text, l_version_dates_std_text;

         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_text);

         fetch l_cursor
         bulk collect into l_date_times_text, l_version_dates_text;

         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_binary) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_binary);

         fetch l_cursor
         bulk collect into l_date_times_binary, l_version_dates_binary;

         close l_cursor;
      end if;

      -------------------------------------------------
      -- collect the times into queryable structures --
      -------------------------------------------------
      l_times_values.extend(l_date_times_values.count);

      for i in 1 .. l_date_times_values.count loop
         l_times_values(i) := date2_t(l_date_times_values(i), l_version_dates_values(i));
      end loop;

      l_times_std_text.extend(l_date_times_std_text.count);

      for i in 1 .. l_date_times_std_text.count loop
         l_times_std_text(i) := date2_t(l_date_times_std_text(i), l_version_dates_std_text(i));
      end loop;

      l_times_text.extend(l_date_times_text.count);

      for i in 1 .. l_date_times_text.count loop
         l_times_text(i) := date2_t(l_date_times_text(i), l_version_dates_text(i));
      end loop;

      l_times_binary.extend(l_date_times_binary.count);

      for i in 1 .. l_date_times_binary.count loop
         l_times_binary(i) := date2_t(l_date_times_binary(i), l_version_dates_binary(i));
      end loop;

      ---------------------
      -- update the data --
      ---------------------
      for rec
         in (select table_name
               from at_ts_table_properties
              where start_date in (select distinct v.start_date
                                     from cwms_v_tsv v, table(l_times_values) d
                                    where v.ts_code = p_ts_code and v.date_time = d.date_1 and v.version_date = d.date_2)) loop
         execute immediate replace(
                 'update $t
                     set version_date = :1
                    where rowid in (select t.rowid
                                      from $t t,
                                           table(:2) d
                                     where t.ts_code = :3
                                       and t.date_time = d.date_1
                                       and t.version_date = d.date_2)', '$t', rec.table_name)
            using p_new_version_date_utc, l_times_values, p_ts_code;
      end loop;

      update at_tsv_std_text
         set version_date = p_new_version_date_utc
       where rowid in (select t.rowid
                         from at_tsv_std_text t, table(l_times_std_text) d
                        where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      update at_tsv_text
         set version_date = p_new_version_date_utc
       where rowid in (select t.rowid
                         from at_tsv_text t, table(l_times_text) d
                        where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      update at_tsv_binary
         set version_date = p_new_version_date_utc
       where rowid in (select t.rowid
                         from at_tsv_binary t, table(l_times_binary) d
                        where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);
   end change_version_date;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RENAME...
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE rename_ts (p_office_id             IN VARCHAR2,
                        p_timeseries_desc_old   IN VARCHAR2,
                        p_timeseries_desc_new   IN VARCHAR2)
   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   IS
      l_utc_offset   NUMBER := NULL;
   BEGIN
      rename_ts (p_timeseries_desc_old,
                 p_timeseries_desc_new,
                 l_utc_offset,
                 p_office_id);
   END;

   --
   ---------------------------------------------------------------------
   --
   -- Rename a time series id.
   -- If no data exists, then you can rename every part of a cwms_ts_id.
   -- If data exists then you can rename everything except the interval.
   --
   ---------------------------------------------------------------------
   --
   PROCEDURE rename_ts (p_cwms_ts_id_old   IN VARCHAR2,
                        p_cwms_ts_id_new   IN VARCHAR2,
                        p_utc_offset_new   IN NUMBER DEFAULT NULL,
                        p_office_id        IN VARCHAR2 DEFAULT NULL)
   IS
      l_utc_offset_old            at_cwms_ts_spec.interval_utc_offset%TYPE;
      --
      l_location_code_old         at_cwms_ts_spec.location_code%TYPE;
      l_interval_code_old         cwms_interval.interval_code%TYPE;
      --
      l_base_location_id_new      at_base_location.base_location_id%TYPE;
      l_sub_location_id_new       at_physical_location.sub_location_id%TYPE;
      l_location_new              VARCHAR2 (57);
      l_base_parameter_id_new     cwms_base_parameter.base_parameter_id%TYPE;
      l_sub_parameter_id_new      at_parameter.sub_parameter_id%TYPE;
      l_parameter_type_id_new     cwms_parameter_type.parameter_type_id%TYPE;
      l_interval_id_new           cwms_interval.interval_id%TYPE;
      l_duration_id_new           cwms_duration.duration_id%TYPE;
      l_version_id_new            at_cwms_ts_spec.VERSION%TYPE;
      l_utc_offset_new            at_cwms_ts_spec.interval_utc_offset%TYPE;
      --
      l_location_code_new         at_cwms_ts_spec.location_code%TYPE;
      l_interval_dur_new          cwms_interval.INTERVAL%TYPE;
      l_interval_code_new         cwms_interval.interval_code%TYPE;
      l_base_parameter_code_new   cwms_base_parameter.base_parameter_code%TYPE;
      l_parameter_type_code_new   cwms_parameter_type.parameter_type_code%TYPE;
      l_parameter_code_new        at_parameter.parameter_code%TYPE;
      l_duration_code_new         cwms_duration.duration_code%TYPE;
      --
      l_office_code               NUMBER;
      l_ts_code_old               NUMBER;
      l_ts_code_new               NUMBER;
      l_office_id                 cwms_office.office_id%TYPE;
      l_has_data                  BOOLEAN;
      l_tmp                       NUMBER;
   --
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('rename_ts_code',
                                        'get ts_code from materialized view');

      --
      --------------------------------------------------------
      -- Set office_id...
      --------------------------------------------------------
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_office_id);
      END IF;

      DBMS_APPLICATION_INFO.set_module ('rename_ts_code', 'get office code');
      --------------------------------------------------------
      -- Get the office_code...
      --------------------------------------------------------
      l_office_code := cwms_util.get_office_code (l_office_id);
      --------------------------------------------------------
      -- Confirm old cwms_ts_id exists...
      --------------------------------------------------------
      l_ts_code_old :=
         get_ts_code (p_cwms_ts_id     => clean_ts_id(p_cwms_ts_id_old),
                      p_db_office_id   => l_office_id);

      --
      --------------------------------------------------------
      -- Retrieve old codes for the old ts_code...
      --------------------------------------------------------
      --
      SELECT location_code, interval_code, acts.INTERVAL_UTC_OFFSET
        INTO l_location_code_old, l_interval_code_old, l_utc_offset_old
        FROM at_cwms_ts_spec acts
       WHERE ts_code = l_ts_code_old;

--      DBMS_OUTPUT.put_line ('l_utc_offset_old-1: ' || l_utc_offset_old);

      --------------------------------------------------------
      -- Confirm new cwms_ts_id does not exist...
      --------------------------------------------------------
      BEGIN
         --
         l_ts_code_new :=
            get_ts_code (p_cwms_ts_id     => clean_ts_id(p_cwms_ts_id_new),
                         p_db_office_id   => l_office_id);
      --

      EXCEPTION
         -----------------------------------------------------------------
         -- Exception means cwms_ts_id_new does not exist - a good thing!.
         -----------------------------------------------------------------
         WHEN OTHERS
         THEN
            l_ts_code_new := NULL;
      END;

      IF l_ts_code_new IS NOT NULL
      THEN
         cwms_err.RAISE ('TS_ALREADY_EXISTS',
                         l_office_id || '.' || p_cwms_ts_id_new);
      END IF;

      ------------------------------------------------------------------
      -- Parse cwms_id_new --
      ------------------------------------------------------------------
      parse_ts (clean_ts_id(p_cwms_ts_id_new),
                l_base_location_id_new,
                l_sub_location_id_new,
                l_base_parameter_id_new,
                l_sub_parameter_id_new,
                l_parameter_type_id_new,
                l_interval_id_new,
                l_duration_id_new,
                l_version_id_new);
      --
      l_location_new :=
         cwms_util.concat_base_sub_id (l_base_location_id_new,
                                       l_sub_location_id_new);

      ---------------------------
      -- Validate the interval --
      ---------------------------
      BEGIN
         SELECT interval_code, INTERVAL, interval_id
           INTO l_interval_code_new, l_interval_dur_new, l_interval_id_new
           FROM cwms_interval ci
          WHERE UPPER (ci.interval_id) = UPPER (l_interval_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_INTERVAL_ID', l_interval_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      ----------------------------------
      -- Validate the base parameter --
      ----------------------------------
      BEGIN
         SELECT base_parameter_code
           INTO l_base_parameter_code_new
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (l_base_parameter_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_PARAM_ID', l_base_parameter_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      ---------------------------------
      -- Validate the parameter type --
      ---------------------------------
      BEGIN
         SELECT parameter_type_code
           INTO l_parameter_type_code_new
           FROM cwms_parameter_type
          WHERE UPPER (parameter_type_id) = UPPER (l_parameter_type_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_PARAM_TYPE', l_parameter_type_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      ---------------------------
      -- Validate the duration --
      ---------------------------
      BEGIN
         SELECT duration_code
           INTO l_duration_code_new
           FROM cwms_duration
          WHERE UPPER (duration_id) = UPPER (l_duration_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_DURATION_ID', l_duration_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      --------------------------------------------------------
      -- set default utc_offset if null was passed in as new...
      --------------------------------------------------------
      if p_utc_offset_new is null then
         -------------------------
         -- no offset specified --
         -------------------------
         if l_interval_code_new = l_interval_code_old then
            -------------------
            -- same interval --
            -------------------
            l_utc_offset_new := l_utc_offset_old;
         else
            -------------------------
            -- different intervals --
            -------------------------
            if cwms_util.is_irregular_code (l_interval_code_new) then
               if cwms_util.is_irregular_code (l_interval_code_old) then
                  ----------------
                  -- irr -> irr --
                  ----------------
                  l_utc_offset_new := l_utc_offset_old;
               else
                  ----------------
                  -- reg -> irr --
                  ----------------
                  l_utc_offset_new := cwms_util.utc_offset_irregular;
               end if;
            elsif cwms_util.is_irregular_code (l_interval_code_old) then
               if l_utc_offset_old < 0 then
                  -----------------
                  -- lrts -> reg --
                  -----------------
                  l_utc_offset_new := abs(l_utc_offset_old);
               else
                  ----------------------
                  -- other irr -> reg --
                  ----------------------
                  l_utc_offset_new := cwms_util.utc_offset_undefined;
               end if;
            else
               ----------------
               -- reg -> reg --
               ----------------
               l_utc_offset_new := l_utc_offset_old;
            end if;
         end if;
      else
         ----------------------
         -- offset specified --
         ----------------------
         if abs(p_utc_offset_new) >= l_interval_dur_new then
            cwms_err.raise ('INVALID_UTC_OFFSET', p_utc_offset_new, l_interval_dur_new);
         end if;
         if cwms_util.is_irregular_code (l_interval_code_new) then
            l_utc_offset_new := -abs(p_utc_offset_new);
         else
            l_utc_offset_new := p_utc_offset_new;
         end if;
      end if;

      -------------------------------------------------------------
      ---- Make sure that 'Inst' Parameter type doesn't have a duration--
      --------------------------------------------------------------
      IF (UPPER (l_parameter_type_id_new) = 'INST' AND l_duration_id_new <> '0')
      THEN
        raise_application_error (-20205, 'Inst parameter type can not have non-zero duration', TRUE);
      END IF;

      ---------------------------------------------------
      -- Check whether the ts_code has associated data --
      ---------------------------------------------------
      SELECT COUNT (*)
        INTO l_tmp
        FROM av_tsv
       WHERE ts_code = l_ts_code_old;

      l_has_data := l_tmp > 0;
      if l_has_data then
         -- will verify new offset is okay or raise an exception
         update_ts_id(
            p_ts_code             => l_ts_code_old,
            p_interval_utc_offset => l_utc_offset_new);
      end if;
      ----------------------------------------------------
      -- Determine the new location_code --
      ----------------------------------------------------
      BEGIN
         l_location_code_new :=
            cwms_loc.get_location_code (l_office_id, l_location_new);
      EXCEPTION                              -- New Location does not exist...
         WHEN OTHERS
         THEN
            cwms_loc.create_location (p_location_id    => l_location_new,
                                      p_db_office_id   => l_office_id);
            --
            l_location_code_new :=
               cwms_loc.get_location_code (l_office_id, l_location_new);
      END;

      ----------------------------------------------------
      -- Determine the new parameter_code --
      ----------------------------------------------------
      l_parameter_code_new :=
         get_parameter_code (
            p_base_parameter_code   => l_base_parameter_code_new,
            p_sub_parameter_id      => l_sub_parameter_id_new,
            p_office_code           => l_office_code,
            p_create                => TRUE);


      --
      ----------------------------------------------------
      -- Perform the Rename by updating at_cwms_ts_spec --
      ----------------------------------------------------
      --
      UPDATE at_cwms_ts_spec s
         SET s.location_code = l_location_code_new,
             s.parameter_code = l_parameter_code_new,
             s.parameter_type_code = l_parameter_type_code_new,
             s.interval_code = l_interval_code_new,
             s.duration_code = l_duration_code_new,
             s.VERSION = l_version_id_new,
             s.interval_utc_offset = l_utc_offset_new
       WHERE s.ts_code = l_ts_code_old;

      COMMIT;

      --
      ---------------------------------
      -- Publish a TSRenamed message --
      ---------------------------------
      --
      DECLARE
         l_msg     SYS.aq$_jms_map_message;
         l_msgid   PLS_INTEGER;
         i         INTEGER;
      BEGIN
         cwms_msg.new_message (l_msg, l_msgid, 'TSRenamed');
         l_msg.set_string (l_msgid, 'ts_id', p_cwms_ts_id_old);
         l_msg.set_string (l_msgid, 'new_ts_id', p_cwms_ts_id_new);
         l_msg.set_string (l_msgid, 'office_id', l_office_id);
         l_msg.set_long (l_msgid, 'ts_code', l_ts_code_old);
         i :=
            cwms_msg.publish_message (l_msg,
                                      l_msgid,
                                      l_office_id || '_ts_stored');
      END;

      --
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   --
   END rename_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- PARSE_TS -
   --
   PROCEDURE parse_ts (p_cwms_ts_id          IN     VARCHAR2,
                       p_base_location_id       OUT VARCHAR2,
                       p_sub_location_id        OUT VARCHAR2,
                       p_base_parameter_id      OUT VARCHAR2,
                       p_sub_parameter_id       OUT VARCHAR2,
                       p_parameter_type_id      OUT VARCHAR2,
                       p_interval_id            OUT VARCHAR2,
                       p_duration_id            OUT VARCHAR2,
                       p_version_id             OUT VARCHAR2)
   IS
   BEGIN
      SELECT cwms_util.get_base_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                   '[^.]+',
                                                   1,
                                                   1))
                base_location_id,
             cwms_util.get_sub_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                  '[^.]+',
                                                  1,
                                                  1))
                sub_location_id,
             cwms_util.get_base_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                   '[^.]+',
                                                   1,
                                                   2))
                base_parameter_id,
             cwms_util.get_sub_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                  '[^.]+',
                                                  1,
                                                  2))
                sub_parameter_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            3)
                parameter_type_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            4)
                interval_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            5)
                duration_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            6)
                VERSION
        INTO p_base_location_id,
             p_sub_location_id,
             p_base_parameter_id,
             p_sub_parameter_id,
             p_parameter_type_id,
             p_interval_id,
             p_duration_id,
             p_version_id
        FROM DUAL;
   END parse_ts;



   PROCEDURE zretrieve_ts (p_at_tsv_rc      IN OUT SYS_REFCURSOR,
                           p_units          IN     VARCHAR2,
                           p_cwms_ts_id     IN     VARCHAR2,
                           p_start_time     IN     DATE,
                           p_end_time       IN     DATE,
                           p_trim           IN     VARCHAR2 DEFAULT 'F',
                           p_inclusive      IN     NUMBER DEFAULT NULL,
                           p_version_date   IN     DATE DEFAULT NULL,
                           p_max_version    IN     VARCHAR2 DEFAULT 'T',
                           p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      retrieve_ts (p_at_tsv_rc         => p_at_tsv_rc,
                   p_cwms_ts_id        => p_cwms_ts_id,
                   p_units             => p_units,
                   p_start_time        => p_start_time,
                   p_end_time          => p_end_time,
                   p_time_zone         => 'UTC',
                   p_trim              => p_trim,
                   p_start_inclusive   => p_inclusive,
                   p_end_inclusive     => p_inclusive,
                   p_previous          => 'F',
                   p_next              => 'F',
                   p_version_date      => p_version_date,
                   p_max_version       => p_max_version,
                   p_office_id         => p_db_office_id);
   END zretrieve_ts;

   PROCEDURE zretrieve_ts_java (
      p_transaction_time      OUT DATE,
      p_at_tsv_rc             OUT SYS_REFCURSOR,
      p_units_out             OUT VARCHAR2,
      p_cwms_ts_id_out        OUT VARCHAR2,
      p_units_in           IN     VARCHAR2,
      p_cwms_ts_id_in      IN     VARCHAR2,
      p_start_time         IN     DATE,
      p_end_time           IN     DATE,
      p_trim               IN     VARCHAR2 DEFAULT 'F',
      p_inclusive          IN     NUMBER DEFAULT NULL,
      p_version_date       IN     DATE DEFAULT NULL,
      p_max_version        IN     VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN     VARCHAR2 DEFAULT NULL)
   IS
      /*l_at_tsv_rc   sys_refcursor;*/
      l_inclusive   VARCHAR2 (1);
   BEGIN
      p_transaction_time := CAST ( (SYSTIMESTAMP AT TIME ZONE 'UTC') AS DATE);

      IF NVL (p_inclusive, 0) = 0
      THEN
         l_inclusive := 'F';
      ELSE
         l_inclusive := 'T';
      END IF;

      retrieve_ts_out (p_at_tsv_rc,
                       p_cwms_ts_id_out,
                       p_units_out,
                       p_cwms_ts_id_in,
                       p_units_in,
                       p_start_time,
                       p_end_time,
                       'UTC',
                       p_trim,
                       l_inclusive,
                       l_inclusive,
                       'F',
                       'F',
                       p_version_date,
                       p_max_version,
                       p_db_office_id);
   END zretrieve_ts_java;

   PROCEDURE retrieve_existing_times(
      p_cursor           OUT sys_refcursor,
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE,
      p_item_mask        IN  BINARY_INTEGER  DEFAULT cwms_util.ts_all)
   IS
   BEGIN
      p_cursor := retrieve_existing_times_f(
         p_ts_code,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_version_date_utc,
         p_max_version);

   END retrieve_existing_times;

   FUNCTION retrieve_existing_times_f(
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE,
      p_item_mask        IN  BINARY_INTEGER  DEFAULT cwms_util.ts_all)
      RETURN sys_refcursor
   IS
      l_is_versioned           varchar2(1);
      l_version_date_utc       date;
      l_date_times_values      date_table_type := date_table_type();
      l_version_dates_values   date_table_type := date_table_type();
      l_date_times_std_text    date_table_type := date_table_type();
      l_version_dates_std_text date_table_type := date_table_type();
      l_date_times_text        date_table_type := date_table_type();
      l_version_dates_text     date_table_type := date_table_type();
      l_date_times_binary      date_table_type := date_table_type();
      l_version_dates_binary   date_table_type := date_table_type();
      l_value_times            date2_tab_t := date2_tab_t();
      l_std_text_times         date2_tab_t := date2_tab_t();
      l_text_times             date2_tab_t := date2_tab_t();
      l_binary_times           date2_tab_t := date2_tab_t();
      l_cursor                 sys_refcursor;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      if p_ts_code is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TS_CODE');
      end if;
      if p_date_times_utc is not null and (p_start_time_utc is not null or p_end_time_utc is not null) then
         cwms_err.raise('ERROR', 'Start and/or end times cannot be specified with specific times.');
      end if;

      -----------------------------------------------
      -- collect the times for the specified items --
      -----------------------------------------------
      cwms_ts.is_ts_versioned(l_is_versioned, p_ts_code);
      if p_version_date_utc is null then
         -------------------------------
         -- no version_date specified --
         -------------------------------
         if cwms_util.return_true_or_false(l_is_versioned) then
            ---------------------------
            -- versioned time series --
            ---------------------------
            if p_max_version then
               ---------------------------
               -- max_version specified --
               ---------------------------
               if bitand(p_item_mask, cwms_util.ts_values) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
            else
               ---------------------------
               -- min_version specified --
               ---------------------------
               if bitand(p_item_mask, cwms_util.ts_values) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
            end if;
         else
            -------------------------------
            -- non-versioned time series --
            -------------------------------
            if bitand(p_item_mask, cwms_util.ts_values) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_values, l_version_dates_values
                    from av_tsv
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_values, l_version_dates_values
                    from av_tsv
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
            if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_std_text, l_version_dates_std_text
                    from at_tsv_std_text
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_std_text, l_version_dates_std_text
                    from at_tsv_std_text
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
            if bitand(p_item_mask, cwms_util.ts_text) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_text, l_version_dates_text
                    from at_tsv_text
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_text, l_version_dates_text
                    from at_tsv_text
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
            if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_binary, l_version_dates_binary
                    from at_tsv_binary
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_binary, l_version_dates_binary
                    from at_tsv_binary
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
         end if;
      else
         -------------------------------
         -- version_date is specified --
         -------------------------------
         if p_version_date_utc != cwms_util.all_version_dates then
            l_version_date_utc := p_version_date_utc;
         end if;
         if bitand(p_item_mask, cwms_util.ts_values) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_values, l_version_dates_values
                 from av_tsv
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_values, l_version_dates_values
                 from av_tsv
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
         if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_std_text, l_version_dates_std_text
                 from at_tsv_std_text
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_std_text, l_version_dates_std_text
                 from at_tsv_std_text
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
         if bitand(p_item_mask, cwms_util.ts_text) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_text, l_version_dates_text
                 from at_tsv_text
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_text, l_version_dates_text
                 from at_tsv_text
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
         if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_binary, l_version_dates_binary
                 from at_tsv_binary
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_binary, l_version_dates_binary
                 from at_tsv_binary
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
      end if;
      ----------------------------------------------------
      -- collect the results into queryable collections --
      ----------------------------------------------------
      l_value_times.extend(l_date_times_values.count);
      for i in 1..l_date_times_values.count loop
         l_value_times(i) := date2_t(l_date_times_values(i), l_version_dates_values(i));
      end loop;
      l_std_text_times.extend(l_date_times_std_text.count);
      for i in 1..l_date_times_std_text.count loop
         l_std_text_times(i) := date2_t(l_date_times_std_text(i), l_version_dates_std_text(i));
      end loop;
      l_text_times.extend(l_date_times_text.count);
      for i in 1..l_date_times_text.count loop
         l_text_times(i) := date2_t(l_date_times_text(i), l_version_dates_text(i));
      end loop;
      l_binary_times.extend(l_date_times_binary.count);
      for i in 1..l_date_times_binary.count loop
         l_binary_times(i) := date2_t(l_date_times_binary(i), l_version_dates_binary(i));
      end loop;
      --------------------------------------
      -- return a cursor into the results --
      --------------------------------------
      open l_cursor for
         select date_1 as date_time,
                date_2 as version_date
           from (select * from table(l_value_times)
                 union
                 select * from table(l_std_text_times)
                 union
                 select * from table(l_text_times)
                 union
                 select * from table(l_binary_times)
                )
          order by date_1, date_2;
      return l_cursor;
   END retrieve_existing_times_f;

   PROCEDURE retrieve_existing_item_counts(
      p_cursor           OUT sys_refcursor,
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE)
   IS
   BEGIN
      p_cursor := retrieve_existing_item_counts(
         p_ts_code,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_version_date_utc,
         p_max_version);
   END retrieve_existing_item_counts;

function retrieve_existing_item_counts(
   p_ts_code          in number,
   p_start_time_utc   in date default null,
   p_end_time_utc     in date default null,
   p_date_times_utc   in date_table_type default null,
   p_version_date_utc in date default null,
   p_max_version      in boolean default true)
   return sys_refcursor
is
   l_cursor          sys_refcursor;
   l_date_times      date_table_type;
   l_version_dates   date_table_type;
   l_times           date2_tab_t := date2_tab_t();
begin
   l_cursor      :=
      retrieve_existing_times_f(
         p_ts_code,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_version_date_utc,
         p_max_version,
         cwms_util.ts_all);

   fetch l_cursor
   bulk collect into l_date_times, l_version_dates;

   close l_cursor;

   l_times.extend(l_date_times.count);

   for i in 1 .. l_date_times.count loop
      l_times(i) := date2_t(l_date_times(i), l_version_dates(i));
   end loop;

   open l_cursor for
        select d.date_time,
               d.version_date,
               count(v.date_time) as value_count,
               count(s.date_time) as std_text_count,
               count(t.date_time) as text_count,
               count(b.date_time) as binary_count
          from (select date_1 as date_time, date_2 as version_date from table(l_times)) d
               left outer join (select date_time, version_date
                                  from av_tsv
                                 where ts_code = p_ts_code) v
                  on v.date_time = d.date_time and v.version_date = d.version_date
               left outer join (select date_time, version_date
                                  from at_tsv_std_text
                                 where ts_code = p_ts_code) s
                  on s.date_time = d.date_time and s.version_date = d.version_date
               left outer join (select date_time, version_date
                                  from at_tsv_text
                                 where ts_code = p_ts_code) t
                  on t.date_time = d.date_time and t.version_date = d.version_date
               left outer join (select date_time, version_date
                                  from at_tsv_binary
                                 where ts_code = p_ts_code) b
                  on b.date_time = d.date_time and b.version_date = d.version_date
      group by d.date_time, d.version_date
      order by d.date_time, d.version_date;

   return l_cursor;
end retrieve_existing_item_counts;

   PROCEDURE collect_deleted_times (p_deleted_time   IN TIMESTAMP,
                                    p_ts_code        IN NUMBER,
                                    p_version_date   IN DATE,
                                    p_start_time     IN DATE,
                                    p_end_time       IN DATE)
   IS
      l_table_names   str_tab_t;
      l_millis        NUMBER (14);
   BEGIN
      SELECT table_name
        BULK COLLECT INTO l_table_names
        FROM at_ts_table_properties
       WHERE start_date <= p_end_time AND end_date > p_start_time;

      l_millis := cwms_util.to_millis (p_deleted_time);

      FOR i IN 1 .. l_table_names.COUNT
      LOOP
         EXECUTE IMMEDIATE REPLACE (
            'insert
               into at_ts_deleted_times
             select :millis,
                    :ts_code,
                    :version_date,
                    date_time
               from table_name
              where ts_code = :ts_code
                and version_date = :version_date
                and date_time between :start_time and :end_time',
                             'table_name',
                             l_table_names (i))
            USING l_millis,
                  p_ts_code,
                  p_version_date,
                  p_ts_code,
                  p_version_date,
                  p_start_time,
                  p_end_time;
      END LOOP;
   END collect_deleted_times;

   PROCEDURE retrieve_deleted_times (
      p_deleted_times      OUT date_table_type,
      p_deleted_time    IN     NUMBER,
      p_ts_code         IN     NUMBER,
      p_version_date    IN     NUMBER)
   IS
   BEGIN
        SELECT date_time
          BULK COLLECT INTO p_deleted_times
          FROM at_ts_deleted_times
         WHERE     deleted_time = p_deleted_time
               AND ts_code = p_ts_code
               AND version_date =
                      CAST (cwms_util.TO_TIMESTAMP (p_version_date) AS DATE)
      ORDER BY date_time;
   END retrieve_deleted_times;

   FUNCTION retrieve_deleted_times_f (p_deleted_time   IN NUMBER,
                                      p_ts_code        IN NUMBER,
                                      p_version_date   IN NUMBER)
      RETURN date_table_type
   IS
      l_deleted_times   date_table_type;
   BEGIN
      retrieve_deleted_times (l_deleted_times,
                              p_deleted_time,
                              p_ts_code,
                              p_version_date);

      RETURN l_deleted_times;
   END retrieve_deleted_times_f;

   -- p_fail_if_exists 'T' will throw an exception if the parameter_id already    -
   --                        exists.                                              -
   --                  'F' will simply return the parameter code of the already   -
   --                        existing parameter id.                               -
   PROCEDURE create_parameter_code (
      p_base_parameter_code      OUT NUMBER,
      p_parameter_code           OUT NUMBER,
      p_base_parameter_id     IN     VARCHAR2,
      p_sub_parameter_id      IN     VARCHAR2,
      p_fail_if_exists        IN     VARCHAR2 DEFAULT 'T',
      p_db_office_code        IN     NUMBER)
   IS
      l_all_office_code       NUMBER := cwms_util.db_office_code_all;
      l_parameter_id_exists   BOOLEAN := FALSE;
   BEGIN
      IF p_db_office_code = 0
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', 'Unkown');
      END IF;

      BEGIN
         SELECT base_parameter_code
           INTO p_base_parameter_code
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE (
               'INVALID_PARAM_ID',
                  p_base_parameter_id
               || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
               || p_sub_parameter_id);
      END;

      BEGIN
         IF p_sub_parameter_id IS NULL
         THEN
            SELECT parameter_code
              INTO p_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND sub_parameter_id IS NULL
                   AND db_office_code IN
                          (p_db_office_code, l_all_office_code);
         ELSE
            SELECT parameter_code
              INTO p_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND UPPER (sub_parameter_id) = UPPER (p_sub_parameter_id)
                   AND db_office_code IN
                          (p_db_office_code, l_all_office_code);
         END IF;

         l_parameter_id_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF p_sub_parameter_id IS NULL
            THEN
               cwms_err.RAISE (
                  'INVALID_PARAM_ID',
                     p_base_parameter_id
                  || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
                  || p_sub_parameter_id);
            ELSE                                -- Insert new sub_parameter...
               INSERT INTO at_parameter (parameter_code,
                                         db_office_code,
                                         base_parameter_code,
                                         sub_parameter_id)
                    VALUES (cwms_seq.NEXTVAL,
                            p_db_office_code,
                            p_base_parameter_code,
                            p_sub_parameter_id)
                 RETURNING parameter_code
                      INTO p_parameter_code;
            END IF;
      END;

      IF UPPER (NVL (p_fail_if_exists, 'T')) = 'T' AND l_parameter_id_exists
      THEN
         cwms_err.RAISE (
            'ITEM_ALREADY_EXISTS',
               p_base_parameter_id
            || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
            || p_sub_parameter_id,
            'Parameter Id');
      END IF;
   END create_parameter_code;


   PROCEDURE create_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_code        NUMBER
                                 := cwms_util.get_db_office_code (p_db_office_id);
      l_base_parameter_code   NUMBER;
      l_parameter_code        NUMBER;
   BEGIN
      create_parameter_code (
         p_base_parameter_code   => l_base_parameter_code,
         p_parameter_code        => l_parameter_code,
         p_base_parameter_id     => cwms_util.get_base_id (p_parameter_id),
         p_sub_parameter_id      => cwms_util.get_sub_id (p_parameter_id),
         p_fail_if_exists        => 'F',
         p_db_office_code        => l_db_office_code);
   END;


   PROCEDURE delete_parameter_id (p_base_parameter_id   IN VARCHAR2,
                                  p_sub_parameter_id    IN VARCHAR2,
                                  p_db_office_code      IN NUMBER)
   IS
      l_base_parameter_code   NUMBER;
      l_parameter_code        NUMBER;
   BEGIN
      BEGIN
         SELECT base_parameter_code
           INTO l_base_parameter_code
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE (
               'INVALID_PARAM_ID',
                  p_base_parameter_id
               || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
               || p_sub_parameter_id);
      END;

      DELETE FROM at_parameter
            WHERE     base_parameter_code = l_base_parameter_code
                  AND UPPER (sub_parameter_id) =
                         UPPER (TRIM (p_sub_parameter_id))
                  AND db_office_code = p_db_office_code;
   END;

   PROCEDURE delete_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      delete_parameter_id (
         p_base_parameter_id   => cwms_util.get_base_id (p_parameter_id),
         p_sub_parameter_id    => cwms_util.get_sub_id (p_parameter_id),
         p_db_office_code      => cwms_util.get_db_office_code (
                                    p_db_office_id));
   END;


   PROCEDURE rename_parameter_id (
      p_parameter_id_old   IN VARCHAR2,
      p_parameter_id_new   IN VARCHAR2,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_code_all        NUMBER := cwms_util.db_office_code_all;
      l_db_office_code            NUMBER
         := cwms_util.get_db_office_code (p_db_office_id);
      --
      l_db_office_code_old        NUMBER;
      l_base_parameter_code_old   NUMBER;
      l_parameter_code_old        NUMBER;
      l_sub_parameter_id_old      VARCHAR2 (32);
      l_parameter_code_new        NUMBER;
      l_base_parameter_code_new   NUMBER;
      l_base_parameter_id_new     VARCHAR2 (16);
      l_sub_parameter_id_new      VARCHAR2 (32);
      --
      l_new_parameter_id_exists   BOOLEAN := FALSE;
   BEGIN
      SELECT db_office_code,
             base_parameter_code,
             parameter_code,
             sub_parameter_id
        INTO l_db_office_code_old,
             l_base_parameter_code_old,
             l_parameter_code_old,
             l_sub_parameter_id_old
        FROM av_parameter
       WHERE     UPPER (parameter_id) = UPPER (TRIM (p_parameter_id_old))
             AND db_office_code IN (l_db_office_code_all, l_db_office_code);

      IF l_db_office_code_old = l_db_office_code_all
      THEN
         cwms_err.RAISE ('ITEM_OWNED_BY_CWMS', p_parameter_id_old);
      END IF;

      BEGIN
         SELECT base_parameter_code, parameter_code, sub_parameter_id
           INTO l_base_parameter_code_new,
                l_parameter_code_new,
                l_sub_parameter_id_new
           FROM av_parameter
          WHERE     UPPER (parameter_id) = UPPER (TRIM (p_parameter_id_new))
                AND db_office_code IN
                       (l_db_office_code_all, l_db_office_code);

         l_new_parameter_id_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_base_parameter_id_new :=
               cwms_util.get_base_id (cwms_util.strip(p_parameter_id_new));
            l_sub_parameter_id_new :=
               cwms_util.get_sub_id (cwms_util.strip(p_parameter_id_new));

            SELECT base_parameter_code
              INTO l_base_parameter_code_old
              FROM cwms_base_parameter
             WHERE UPPER (base_parameter_id) =
                      UPPER (l_base_parameter_id_new);

            l_parameter_code_new := 0;
      END;


      IF l_new_parameter_id_exists
      THEN
         IF     l_parameter_code_new = l_parameter_code_old
            AND l_sub_parameter_id_old = l_sub_parameter_id_new
         THEN
            cwms_err.RAISE ('CANNOT_RENAME_3', p_parameter_id_new);
         ELSE
            cwms_err.RAISE ('CANNOT_RENAME_2', p_parameter_id_new);
         END IF;
      END IF;

      UPDATE at_parameter
         SET sub_parameter_id = l_sub_parameter_id_new
       WHERE parameter_code = l_parameter_code_old;
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- ZSTORE_TS -
   --
   PROCEDURE zstore_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN ztsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries_data   tsv_array := tsv_array ();
   BEGIN
      l_timeseries_data.EXTEND (p_timeseries_data.COUNT);

      FOR i IN 1 .. p_timeseries_data.COUNT
      LOOP
         l_timeseries_data (i) :=
            tsv_type (
               FROM_TZ (CAST (p_timeseries_data (i).date_time AS TIMESTAMP),
                        'UTC'),
               p_timeseries_data (i).VALUE,
               p_timeseries_data (i).quality_code);
      --         DBMS_OUTPUT.put_line(   l_timeseries_data (i).date_time
      --                              || ' '
      --                              || l_timeseries_data (i).value
      --                              || ' '
      --                              || l_timeseries_data (i).quality_code);
      END LOOP;

      cwms_ts.store_ts (p_cwms_ts_id,
                        p_units,
                        l_timeseries_data,
                        p_store_rule,
                        p_override_prot,
                        p_version_date,
                        p_office_id);
   END zstore_ts;


   PROCEDURE zstore_ts_multi (
      p_timeseries_array   IN ztimeseries_array,
      p_store_rule         IN VARCHAR2,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_date       IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id          IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries     ztimeseries_type;
      l_err_msg        VARCHAR2 (722) := NULL;
      l_all_err_msgs   VARCHAR2 (2048) := NULL;
      l_len            NUMBER := 0;
      l_total_len      NUMBER := 0;
      l_num_ts_ids     NUMBER := 0;
      l_num_errors     NUMBER := 0;
      l_excep_errors   NUMBER := 0;
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.zstore_ts_multi',
                                        'selecting time series from input');

      FOR l_timeseries IN (SELECT * FROM TABLE (p_timeseries_array))
      LOOP
         DBMS_APPLICATION_INFO.set_module ('cwms_ts_store.zstore_ts_multi',
                                           'calling zstore_ts');

         BEGIN
            l_num_ts_ids := l_num_ts_ids + 1;

            cwms_ts.zstore_ts (l_timeseries.tsid,
                               l_timeseries.unit,
                               l_timeseries.data,
                               p_store_rule,
                               p_override_prot,
                               p_version_date,
                               p_office_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_num_errors := l_num_errors + 1;

               l_err_msg :=
                     'STORE_ERROR ***'
                  || l_timeseries.tsid
                  || '*** '
                  || SQLCODE
                  || ': '
                  || SQLERRM;

               IF   NVL (LENGTH (l_all_err_msgs), 0)
                  + NVL (LENGTH (l_err_msg), 0) <= 1930
               THEN
                  l_excep_errors := l_excep_errors + 1;
                  l_all_err_msgs := l_all_err_msgs || ' ' || l_err_msg;
               END IF;
         END;
      END LOOP;

      IF l_all_err_msgs IS NOT NULL
      THEN
         l_all_err_msgs :=
               'STORE ERRORS: zstore_ts_multi processed '
            || l_num_ts_ids
            || ' ts_ids of which '
            || l_num_errors
            || ' had STORE ERRORS. '
            || l_excep_errors
            || ' of those errors are: '
            || l_all_err_msgs;

         raise_application_error (-20999, l_all_err_msgs);
      END IF;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END zstore_ts_multi;

   PROCEDURE validate_ts_queue_name (p_queue_name IN VARCHAR)
   IS
      l_pattern   CONSTANT VARCHAR2 (39)
                              := '([a-z0-9_$]+\.)?([a-z0-9$]+_)?ts_stored' ;
      l_last               INTEGER := LENGTH (p_queue_name) + 1;
   BEGIN
      IF    REGEXP_INSTR (p_queue_name,
                          l_pattern,
                          1,
                          1,
                          0,
                          'i') != 1
         OR REGEXP_INSTR (p_queue_name,
                          l_pattern,
                          1,
                          1,
                          1,
                          'i') != l_last
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_queue_name,
                         'queue name for (un)registister_ts_callback');
      END IF;
   END validate_ts_queue_name;

   FUNCTION register_ts_callback (
      p_procedure_name    IN VARCHAR2,
      p_subscriber_name   IN VARCHAR2 DEFAULT NULL,
      p_queue_name        IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_queue_name   VARCHAR2 (61) := NVL (p_queue_name, 'ts_stored');
   BEGIN
      validate_ts_queue_name (l_queue_name);
      RETURN cwms_msg.register_msg_callback (p_procedure_name,
                                             l_queue_name,
                                             p_subscriber_name);
   END register_ts_callback;

   PROCEDURE unregister_ts_callback (
      p_procedure_name    IN VARCHAR2,
      p_subscriber_name   IN VARCHAR2,
      p_queue_name        IN VARCHAR2 DEFAULT NULL)
   IS
      l_queue_name   VARCHAR2 (61) := NVL (p_queue_name, 'ts_stored');
   BEGIN
      validate_ts_queue_name (l_queue_name);
      cwms_msg.unregister_msg_callback (p_procedure_name,
                                        l_queue_name,
                                        p_subscriber_name);
   END unregister_ts_callback;

   PROCEDURE refresh_ts_catalog
   IS
   BEGIN
      -- Catalog is now refreshed during the  call to fetch the catalog
      -- cwms_util.refresh_mv_cwms_ts_id;
      NULL;
   END refresh_ts_catalog;

   -------------------------------
   -- Timeseries group routines --
   -------------------------------
   PROCEDURE store_ts_category (
      p_ts_category_id     IN VARCHAR2,
      p_ts_category_desc   IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
      p_ignore_null        IN VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_code   NUMBER (10);
   BEGIN
      l_code :=
         store_ts_category_f (p_ts_category_id,
                              p_ts_category_desc,
                              p_fail_if_exists,
                              p_ignore_null,
                              p_db_office_id);
   END store_ts_category;

   FUNCTION store_ts_category_f (
      p_ts_category_id     IN VARCHAR2,
      p_ts_category_desc   IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
      p_ignore_null        IN VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code      NUMBER;
      l_ignore_null      BOOLEAN;
      l_fail_if_exists   BOOLEAN;
      l_exists           BOOLEAN;
      l_rec              at_ts_category%ROWTYPE;
   BEGIN
      --------------------
      -- santity checks --
      --------------------
      l_fail_if_exists := cwms_util.is_true (p_fail_if_exists);
      l_ignore_null := cwms_util.is_true (p_ignore_null);
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);
      ----------------------------------
      -- determine if category exists --
      ----------------------------------
      l_rec.ts_category_id := UPPER (cwms_util.strip(p_ts_category_id));

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = l_rec.ts_category_id;

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise ('ITEM_ALREADY_EXISTS',
                            'Time series category',
                            cwms_util.strip(p_ts_category_id));
         ELSE
            IF     l_rec.db_office_code = cwms_util.db_office_code_all
               AND l_office_code != cwms_util.db_office_code_all
            THEN
               cwms_err.raise (
                  'ERROR',
                     'CWMS time series category '
                  || p_ts_category_id
                  || ' can only be updated by owner.');
            END IF;
         END IF;
      END IF;

      -----------------------------------
      -- insert or update the category --
      -----------------------------------
      l_rec.ts_category_id := cwms_util.strip(p_ts_category_id);
      IF NOT l_exists OR p_ts_category_desc IS NOT NULL OR NOT l_ignore_null
      THEN
         l_rec.ts_category_desc := cwms_util.strip(p_ts_category_desc);
      END IF;

      IF l_exists
      THEN
         UPDATE at_ts_category
            SET row = l_rec
          WHERE ts_category_code = l_rec.ts_category_code;
      ELSE
         l_rec.ts_category_code := cwms_seq.NEXTVAL;
         l_rec.db_office_code := l_office_code;

         INSERT INTO at_ts_category
              VALUES l_rec;
      END IF;

      RETURN l_rec.ts_category_code;
   END store_ts_category_f;

   PROCEDURE rename_ts_category (
      p_ts_category_id_old   IN VARCHAR2,
      p_ts_category_id_new   IN VARCHAR2,
      p_db_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code    NUMBER;
      l_category_rec   at_ts_category%ROWTYPE;
   BEGIN
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      --------------------------------------
      -- determine if old category exists --
      --------------------------------------
      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = UPPER (p_ts_category_id_old);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series location category',
                            p_ts_category_id_old);
      END;

      --------------------------------------
      -- determine if new category exists --
      --------------------------------------
      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = UPPER (cwms_util.strip(p_ts_category_id_new));

         cwms_err.raise ('ITEM_ALREADY_EXISTS',
                         'Time series location category',
                         cwms_util.strip(p_ts_category_id_new));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_category_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series category '
            || p_ts_category_id_old
            || ' can only be renamed by owner.');
      END IF;

      -------------------------
      -- rename the category --
      -------------------------
      UPDATE at_ts_category
         SET ts_category_id = cwms_util.strip(p_ts_category_id_new)
       WHERE ts_category_code = l_category_rec.ts_category_code;
   END rename_ts_category;

   PROCEDURE delete_ts_category (p_ts_category_id   IN VARCHAR2,
                                 p_cascade          IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code    NUMBER;
      l_cascade        BOOLEAN;
      l_category_rec   at_ts_category%ROWTYPE;
   BEGIN
      --------------------
      -- santity checks --
      --------------------
      l_cascade := cwms_util.is_true (p_cascade);
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      ----------------------------------
      -- determine if category exists --
      ----------------------------------
      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = UPPER (p_ts_category_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series location category',
                            p_ts_category_id);
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_category_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series category '
            || p_ts_category_id
            || ' can only be deleted by owner');
      END IF;

      -----------------
      -- do the work --
      -----------------
      IF l_cascade
      THEN
         ----------------------------------------------------------------------------
         -- delete any groups in the category (will fail if there are assignments) --
         ----------------------------------------------------------------------------
         FOR group_rec
            IN (SELECT ts_group_code
                  FROM at_ts_group
                 WHERE ts_category_code = l_category_rec.ts_category_code)
         LOOP
            FOR assign_rec
               IN (SELECT ts_code
                     FROM at_ts_group_assignment
                    WHERE ts_group_code = group_rec.ts_group_code)
            LOOP
               cwms_err.raise (
                  'ERROR',
                     'Cannot delete time series category '
                  || p_ts_category_id
                  || ' because at least one of its groups is not empty.');
            END LOOP;

            ----------------------
            -- delete the group --
            ----------------------
            DELETE FROM at_ts_group
                  WHERE ts_group_code = group_rec.ts_group_code;
         END LOOP;
      ELSE
         ------------------------------
         -- test for existing groups --
         ------------------------------
         FOR group_rec
            IN (SELECT ts_group_code
                  FROM at_ts_group
                 WHERE ts_category_code = l_category_rec.ts_category_code)
         LOOP
            cwms_err.raise (
               'ERROR',
                  'Cannot delete time series category '
               || p_ts_category_id
               || ' because it is not empty.');
         END LOOP;
      END IF;

      -------------------------
      -- delete the category --
      -------------------------
      DELETE FROM at_ts_category
            WHERE ts_category_code = l_category_rec.ts_category_code;
   END delete_ts_category;

   PROCEDURE store_ts_group (p_ts_category_id     IN VARCHAR2,
                             p_ts_group_id        IN VARCHAR2,
                             p_ts_group_desc      IN VARCHAR2 DEFAULT NULL,
                             p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
                             p_ignore_nulls       IN VARCHAR2 DEFAULT 'T',
                             p_shared_alias_id    IN VARCHAR2 DEFAULT NULL,
                             p_shared_ts_ref_id   IN VARCHAR2 DEFAULT NULL,
                             p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_code   NUMBER (10);
   BEGIN
      l_code :=
         store_ts_group_f (p_ts_category_id,
                           p_ts_group_id,
                           p_ts_group_desc,
                           p_fail_if_exists,
                           p_ignore_nulls,
                           p_shared_alias_id,
                           p_shared_ts_ref_id,
                           p_db_office_id);
   END store_ts_group;

   FUNCTION store_ts_group_f (p_ts_category_id     IN VARCHAR2,
                              p_ts_group_id        IN VARCHAR2,
                              p_ts_group_desc      IN VARCHAR2 DEFAULT NULL,
                              p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
                              p_ignore_nulls       IN VARCHAR2 DEFAULT 'T',
                              p_shared_alias_id    IN VARCHAR2 DEFAULT NULL,
                              p_shared_ts_ref_id   IN VARCHAR2 DEFAULT NULL,
                              p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code      NUMBER (10);
      l_fail_if_exists   BOOLEAN;
      l_exists           BOOLEAN;
      l_ignore_nulls     BOOLEAN;
      l_rec              at_ts_group%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_fail_if_exists := cwms_util.is_true (p_fail_if_exists);
      l_ignore_nulls := cwms_util.is_true (p_ignore_nulls);
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);
      --------------------------------------------------
      -- get the category code, creating if necessary --
      --------------------------------------------------
      l_rec.ts_category_code :=
         cwms_ts.store_ts_category_f (p_ts_category_id     => p_ts_category_id,
                                      p_ts_category_desc   => NULL,
                                      p_fail_if_exists     => 'F',
                                      p_ignore_null        => 'T',
                                      p_db_office_id       => p_db_office_id);
      -----------------------------------
      -- determine if the group exists --
      -----------------------------------
      l_rec.ts_group_id := cwms_util.strip(p_ts_group_id);

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_ts_group
          WHERE     UPPER (ts_group_id) = UPPER (l_rec.ts_group_id)
                AND ts_category_code = l_rec.ts_category_code
                AND db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise ('ITEM_ALREADY_EXISTS',
                            'Time series group',
                            cwms_util.strip(p_ts_category_id) || '/' || cwms_util.strip(p_ts_group_id));
         ELSE
            IF     l_rec.db_office_code = cwms_util.db_office_code_all
               AND l_office_code != cwms_util.db_office_code_all
            THEN
               cwms_err.raise (
                  'ERROR',
                     'CWMS time series group '
                  || cwms_util.strip(p_ts_category_id)
                  || '/'
                  || cwms_util.strip(p_ts_group_id)
                  || ' can only be updated by owner.');
            END IF;
         END IF;
      END IF;

      ------------------------
      -- prepare the record --
      ------------------------
      l_rec.db_office_code := l_office_code;

      IF NOT l_exists OR p_ts_group_desc IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.ts_group_desc := cwms_util.strip(p_ts_group_desc);
      END IF;

      IF NOT l_exists OR p_shared_alias_id IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.shared_ts_alias_id := p_shared_alias_id;
      END IF;

      IF NOT l_exists OR p_shared_ts_ref_id IS NOT NULL OR NOT l_ignore_nulls
      THEN
         IF p_shared_ts_ref_id IS NOT NULL
         THEN
            l_rec.shared_ts_ref_code :=
               cwms_ts.get_ts_code (p_shared_ts_ref_id, l_office_code);
         END IF;
      END IF;

      ---------------------------------
      -- update or insert the record --
      ---------------------------------
      IF l_exists
      THEN
         UPDATE at_ts_group
            SET row = l_rec
          WHERE ts_group_code = l_rec.ts_group_code;
      ELSE
         l_rec.ts_group_code := cwms_seq.NEXTVAL;

         INSERT INTO at_ts_group
              VALUES l_rec;
      END IF;

      RETURN l_rec.ts_group_code;
   END store_ts_group_f;

   PROCEDURE rename_ts_group (p_ts_category_id    IN VARCHAR2,
                              p_ts_group_id_old   IN VARCHAR2,
                              p_ts_group_id_new   IN VARCHAR2,
                              p_db_office_id      IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code   NUMBER (10);
      l_rec           at_ts_group%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      -----------------------------------
      -- determine if the group exists --
      -----------------------------------
      BEGIN
         SELECT g.ts_group_code,
                g.ts_category_code,
                g.ts_group_id,
                g.ts_group_desc,
                g.db_office_code,
                g.shared_ts_alias_id,
                g.shared_ts_ref_code
           INTO l_rec
           FROM at_ts_category c, at_ts_group g
          WHERE     UPPER (c.ts_category_id) = UPPER (p_ts_category_id)
                AND UPPER (g.ts_group_id) = UPPER (p_ts_group_id_old)
                AND g.ts_category_code = c.ts_category_code
                AND g.db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series group',
                            p_ts_category_id || '/' || p_ts_group_id_old);
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series group '
            || p_ts_category_id
            || '/'
            || p_ts_group_id_old
            || ' can only be renamed by owner.');
      END IF;

      ----------------------
      -- rename the group --
      ----------------------
      UPDATE at_ts_group
         SET ts_group_id = cwms_util.strip(p_ts_group_id_new)
       WHERE ts_group_code = l_rec.ts_group_code;
   END rename_ts_group;

   PROCEDURE delete_ts_group (p_ts_category_id   IN VARCHAR2,
                              p_ts_group_id      IN VARCHAR2,
                              p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code   NUMBER (10);
      l_rec           at_ts_group%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      -----------------------------------
      -- determine if the group exists --
      -----------------------------------
      BEGIN
         SELECT g.ts_group_code,
                g.ts_category_code,
                g.ts_group_id,
                g.ts_group_desc,
                g.db_office_code,
                g.shared_ts_alias_id,
                g.shared_ts_ref_code
           INTO l_rec
           FROM at_ts_category c, at_ts_group g
          WHERE     UPPER (c.ts_category_id) = UPPER (p_ts_category_id)
                AND UPPER (g.ts_group_id) = UPPER (p_ts_group_id)
                AND g.ts_category_code = c.ts_category_code
                AND g.db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series group',
                            p_ts_category_id || '/' || p_ts_group_id);
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series group '
            || p_ts_category_id
            || '/'
            || p_ts_group_id
            || ' can only be deleted by owner.');
      END IF;

      FOR rec IN (SELECT ts_code
                    FROM at_ts_group_assignment
                   WHERE ts_group_code = l_rec.ts_group_code)
      LOOP
         cwms_err.raise (
            'ERROR',
               'Cannot delete time series group '
            || p_ts_category_id
            || '/'
            || p_ts_group_id
            || ' because it is not empty.');
      END LOOP;

      ----------------------
      -- delete the group --
      ----------------------
      DELETE FROM at_ts_group
            WHERE ts_group_code = l_rec.ts_group_code;
   END delete_ts_group;

   procedure assign_ts_group (
      p_ts_category_id   in varchar2,
      p_ts_group_id      in varchar2,
      p_ts_id            in varchar2,
      p_ts_attribute     in number default null,
      p_ts_alias_id      in varchar2 default null,
      p_ref_ts_id        in varchar2 default null,
      p_db_office_id     in varchar2 default null)
   is
      l_office_code     number(10);
      l_ts_group_code   number(10);
      l_ts_code         number(10);
      l_ts_ref_code     number(10);
      l_rec             at_ts_group_assignment%rowtype;
      l_exists          boolean;
   begin
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code(p_db_office_id);

      ------------------------
      -- get the group code --
      ------------------------
      begin
         select ts_group_code
           into l_ts_group_code
           from at_ts_category c, at_ts_group g
          where upper(c.ts_category_id) = upper(p_ts_category_id)
            and upper(g.ts_group_id) = upper(p_ts_group_id)
            and g.ts_category_code = c.ts_category_code
            and g.db_office_code in (l_office_code, cwms_util.db_office_code_all);
      exception
         when no_data_found
         then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Time series group',
               p_ts_category_id || '/' || p_ts_group_id);
      end;

      -----------------------------------------------
      -- determine if an assignment already exists --
      -----------------------------------------------
      l_ts_code := get_ts_code(p_ts_id, l_office_code);

      if p_ref_ts_id is not null then
         l_ts_ref_code := get_ts_code(p_ref_ts_id, l_office_code);
      end if;

      begin
         select *
           into l_rec
           from at_ts_group_assignment
          where ts_code = l_ts_code and ts_group_code = l_ts_group_code;

         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;

      ------------------------
      -- prepare the record --
      ------------------------
      l_rec.ts_attribute := nvl(p_ts_attribute, l_rec.ts_attribute);
      l_rec.ts_alias_id  := nvl(p_ts_alias_id, l_rec.ts_alias_id);
      l_rec.ts_ref_code  := nvl(l_ts_ref_code, l_rec.ts_ref_code);
      l_rec.office_code  := l_office_code;

      ---------------------------------
      -- insert or update the record --
      ---------------------------------
      if l_exists then
         update at_ts_group_assignment
            set row = l_rec
          where ts_code = l_rec.ts_code
            and ts_group_code = l_rec.ts_group_code;
      else
         l_rec.ts_code := l_ts_code;
         l_rec.ts_group_code := l_ts_group_code;

         insert into at_ts_group_assignment
              values l_rec;
      end if;
   end assign_ts_group;

   PROCEDURE unassign_ts_group (p_ts_category_id   IN VARCHAR2,
                                p_ts_group_id      IN VARCHAR2,
                                p_ts_id            IN VARCHAR2,
                                p_unassign_all     IN VARCHAR2 DEFAULT 'F',
                                p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code     NUMBER (10);
      l_ts_group_code   NUMBER (10);
      l_ts_code         NUMBER (10);
      l_exists          BOOLEAN;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      ------------------------
      -- get the group code --
      ------------------------
      BEGIN
         SELECT ts_group_code
           INTO l_ts_group_code
           FROM at_ts_category c, at_ts_group g
          WHERE     UPPER (c.ts_category_id) = UPPER (p_ts_category_id)
                AND UPPER (g.ts_group_id) = UPPER (p_ts_group_id)
                AND g.ts_category_code = c.ts_category_code
                AND g.db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series group',
                            p_ts_category_id || '/' || p_ts_group_id);
      END;

      ------------------------------
      -- delete the assignment(s) --
      ------------------------------
      IF cwms_util.is_true (p_unassign_all)
      THEN
         DELETE FROM at_ts_group_assignment
               WHERE ts_group_code = l_ts_group_code
                 AND get_db_office_code(ts_code) = l_office_code;
      ELSE
         l_ts_code := get_ts_code (p_ts_id, l_office_code);
         DELETE FROM at_ts_group_assignment
               WHERE ts_group_code = l_ts_group_code
                 AND ts_code = l_ts_code;
      END IF;
   END unassign_ts_group;

   PROCEDURE assign_ts_groups (p_ts_category_id   IN VARCHAR2,
                               p_ts_group_id      IN VARCHAR2,
                               p_ts_alias_array   IN ts_alias_tab_t,
                               p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      IF p_ts_alias_array IS NOT NULL
      THEN
         FOR i IN 1 .. p_ts_alias_array.COUNT
         LOOP
            cwms_ts.assign_ts_group (p_ts_category_id,
                                     p_ts_group_id,
                                     p_ts_alias_array (i).ts_id,
                                     p_ts_alias_array (i).ts_attribute,
                                     p_ts_alias_array (i).ts_alias_id,
                                     p_ts_alias_array (i).ts_ref_id,
                                     p_db_office_id);
         END LOOP;
      END IF;
   END assign_ts_groups;

   PROCEDURE unassign_ts_groups (p_ts_category_id   IN VARCHAR2,
                                 p_ts_group_id      IN VARCHAR2,
                                 p_ts_array         IN str_tab_t,
                                 p_unassign_all     IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      IF p_ts_array IS NULL
      THEN
         cwms_ts.unassign_ts_group (p_ts_category_id,
                                    p_ts_group_id,
                                    NULL,
                                    p_unassign_all,
                                    p_db_office_id);
      ELSE
         FOR i IN 1 .. p_ts_array.COUNT
         LOOP
            cwms_ts.unassign_ts_group (p_ts_category_id,
                                       p_ts_group_id,
                                       p_ts_array (i),
                                       p_unassign_all,
                                       p_db_office_id);
         END LOOP;
      END IF;
   END unassign_ts_groups;

   function get_ts_id_from_alias (
      p_alias_id      in varchar2,
      p_group_id      in varchar2 default null,
      p_category_id   in varchar2 default null,
      p_office_id     in varchar2 default null)
      return varchar2
   is
      l_office_code number(10);
      l_ts_code     number(10);
      l_ts_id       varchar2(191);
      l_parts       str_tab_t;
      l_location_id varchar2(57);
   begin
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code(p_office_id);

      -----------------------------------
      -- retrieve and return the ts id --
      -----------------------------------
      begin
         select distinct ts_code
           into l_ts_code
           from at_ts_group_assignment a,
                at_ts_group g,
                at_ts_category c
          where a.office_code = l_office_code
            and upper(c.ts_category_id) = upper(nvl(p_category_id, c.ts_category_id))
            and upper(g.ts_group_id) = upper(nvl(p_group_id, g.ts_group_id))
            and upper(a.ts_alias_id) = upper(p_alias_id)
            and g.ts_category_code = c.ts_category_code
            and a.ts_group_code = g.ts_group_code;
      exception
         when no_data_found then
            ------------------------------------
            -- see if the location is aliased --
            ------------------------------------
            l_parts := cwms_util.split_text(p_alias_id, '.');
            if l_parts.count = 6 then
               l_location_id := cwms_loc.get_location_id(l_parts(1), p_office_id);
               if l_location_id is not null and l_location_id != l_parts(1) then
                  l_parts(1) := l_location_id;
                  l_ts_id := cwms_util.join_text(l_parts, '.');
                  l_ts_code := cwms_ts.get_ts_code(l_ts_id, p_office_id);
                  if l_ts_code is null then
                     l_ts_id := null;
                  end if;
               end if;
            end if;
         when too_many_rows
         then
            cwms_err.raise (
               'ERROR',
               'Alias ('
               || p_alias_id
               || ') matches more than one time series.');
      end;

      if l_ts_code is not null and l_ts_id is null then
         l_ts_id := get_ts_id (l_ts_code);
      end if;

      return l_ts_id;
   END get_ts_id_from_alias;


   FUNCTION get_ts_code_from_alias (p_alias_id      IN VARCHAR2,
                                    p_group_id      IN VARCHAR2 DEFAULT NULL,
                                    p_category_id   IN VARCHAR2 DEFAULT NULL,
                                    p_office_id     IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
   BEGIN
      RETURN get_ts_code (get_ts_id_from_alias (p_alias_id,
                                                p_group_id,
                                                p_category_id,
                                                p_office_id),
                          p_office_id);
   END get_ts_code_from_alias;

   FUNCTION get_ts_id (p_ts_id_or_alias IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      ts_id_not_found   EXCEPTION;
      PRAGMA EXCEPTION_INIT (ts_id_not_found, -20001);
      l_ts_code         NUMBER (10);
      l_ts_id           VARCHAR2(191);
   BEGIN
      BEGIN
         l_ts_code := get_ts_code (p_ts_id_or_alias, p_office_id);
      EXCEPTION
         WHEN ts_id_not_found
         THEN
            NULL;
      END;

      IF l_ts_code IS NOT NULL
      THEN
         l_ts_id := get_ts_id (l_ts_code);
      END IF;

      RETURN l_ts_id;
   END get_ts_id;

   FUNCTION get_ts_id (p_ts_id_or_alias IN VARCHAR2, p_office_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      SELECT office_id
        INTO l_office_id
        FROM cwms_office
       WHERE office_code = p_office_code;

      RETURN get_ts_id (p_ts_id_or_alias, l_office_id);
   END get_ts_id;

   ---------------------------
   -- Data quality routines --
   ---------------------------
   FUNCTION get_quality_validity (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
      l_validity   VARCHAR2 (16);
   BEGIN
      SELECT validity_id
        INTO l_validity
        FROM cwms_data_quality
       WHERE quality_code = p_quality_code + case
                                                when p_quality_code < 0 then 4294967296
                                                else  0
                                             end;
      RETURN l_validity;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise('INVALID_ITEM', p_quality_code, 'CWMS quality value');
   END get_quality_validity;

   FUNCTION get_quality_validity (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN get_quality_validity (p_value.quality_code);
   END get_quality_validity;

   FUNCTION get_quality_validity (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN get_quality_validity (p_value.quality_code);
   END get_quality_validity;

   FUNCTION quality_is_okay (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'OKAY';
   END quality_is_okay;

   FUNCTION quality_is_okay (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_okay (p_value.quality_code);
   END quality_is_okay;

   FUNCTION quality_is_okay (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_okay (p_value.quality_code);
   END quality_is_okay;

   FUNCTION quality_is_okay_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'OKAY'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_okay_text;

   FUNCTION quality_is_okay_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_okay_text (p_value.quality_code);
   END quality_is_okay_text;

   FUNCTION quality_is_okay_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_okay_text (p_value.quality_code);
   END quality_is_okay_text;

   FUNCTION quality_is_missing (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'MISSING';
   END quality_is_missing;

   FUNCTION quality_is_missing (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_missing (p_value.quality_code);
   END quality_is_missing;

   FUNCTION quality_is_missing (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_missing (p_value.quality_code);
   END quality_is_missing;

   FUNCTION quality_is_missing_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'MISSING'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;

   END quality_is_missing_text;

   FUNCTION quality_is_missing_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_missing_text (p_value.quality_code);
   END quality_is_missing_text;

   FUNCTION quality_is_missing_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_missing_text (p_value.quality_code);
   END quality_is_missing_text;

   FUNCTION quality_is_questionable (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'QUESTIONABLE';
   END quality_is_questionable;

   FUNCTION quality_is_questionable (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_questionable (p_value.quality_code);
   END quality_is_questionable;

   FUNCTION quality_is_questionable (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_okay (p_value.quality_code);
   END quality_is_questionable;

   FUNCTION quality_is_questionable_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'QUESTIONABLE'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_questionable_text;

   FUNCTION quality_is_questionable_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_questionable_text (p_value.quality_code);
   END quality_is_questionable_text;

   FUNCTION quality_is_questionable_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_questionable_text (p_value.quality_code);
   END quality_is_questionable_text;

   FUNCTION quality_is_rejected (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'REJECTED';
   END quality_is_rejected;

   FUNCTION quality_is_rejected (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_rejected (p_value.quality_code);
   END quality_is_rejected;

   FUNCTION quality_is_rejected (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_rejected (p_value.quality_code);
   END quality_is_rejected;

   FUNCTION quality_is_rejected_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'REJECTED'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_rejected_text;

   FUNCTION quality_is_rejected_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_rejected_text (p_value.quality_code);
   END quality_is_rejected_text;

   FUNCTION quality_is_rejected_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_rejected_text (p_value.quality_code);
   END quality_is_rejected_text;

   FUNCTION quality_is_protected (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   is
      l_protection_id varchar2(16);
   BEGIN
      select protection_id
        into l_protection_id
        from cwms_data_quality
       where quality_code = p_quality_code;
       
      return l_protection_id = 'PROTECTED';
   END quality_is_protected;

   FUNCTION quality_is_protected (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_protected (p_value.quality_code);
   END quality_is_protected;

   FUNCTION quality_is_protected (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_protected (p_value.quality_code);
   END quality_is_protected;

   FUNCTION quality_is_protected_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   begin
      RETURN CASE quality_is_protected (p_quality_code)
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_protected_text;

   FUNCTION quality_is_protected_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_protected_text (p_value.quality_code);
   END quality_is_protected_text;

   FUNCTION quality_is_protected_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_protected_text (p_value.quality_code);
   END quality_is_protected_text;

   FUNCTION get_quality_description (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
      l_description   VARCHAR2 (4000);
      l_rec           cwms_data_quality%ROWTYPE;
   BEGIN
      SELECT *
        INTO l_rec
        FROM cwms_data_quality
       WHERE quality_code = p_quality_code + case
                                                when p_quality_code < 0 then 4294967296
                                                else  0
                                             end;

      IF l_rec.screened_id = 'UNSCREENED'
      THEN
         l_description := l_rec.screened_id;
      ELSE
         l_description :=
            l_rec.screened_id || ', validity=' || l_rec.validity_id;

         IF l_rec.range_id != 'NO_RANGE'
         THEN
            l_description := l_description || ', range=' || l_rec.range_id;
         END IF;

         IF l_rec.changed_id != 'ORIGINAL'
         THEN
            l_description :=
                  l_description
               || ', '
               || l_rec.changed_id
               || ' (cause='
               || l_rec.repl_cause_id
               || ', method='
               || l_rec.repl_method_id
               || ')';
         END IF;

         IF l_rec.test_failed_id != 'NONE'
         THEN
            l_description :=
               l_description || ', failed=' || l_rec.test_failed_id;
         END IF;

         IF l_rec.protection_id != 'UNPROTECTED'
         THEN
            l_description := l_description || ', ' || l_rec.protection_id;
         END IF;
      END IF;

      l_description := INITCAP (l_description);
      RETURN l_description;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise('INVALID_ITEM', p_quality_code, 'CWMS quality value');
   END get_quality_description;

   FUNCTION get_ts_interval (p_ts_code IN NUMBER)
      RETURN NUMBER result_cache
   IS
      l_interval NUMBER;
   BEGIN
      select interval
        into l_interval
        from cwms_v_ts_id
       where ts_code = p_ts_code;

      return l_interval;
   END get_ts_interval;

   FUNCTION get_ts_interval (p_cwms_ts_id IN VARCHAR2)
      RETURN NUMBER result_cache
   IS
   BEGIN
      RETURN get_interval(get_ts_interval_string(p_cwms_ts_id));
   END get_ts_interval;

   FUNCTION get_ts_interval_string (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2 result_cache
   IS
   BEGIN
      return regexp_substr (p_cwms_ts_id, '[^.]+', 1, 4);
   END get_ts_interval_string;

   FUNCTION get_interval (p_interval_id IN VARCHAR2)
      RETURN NUMBER result_cache
   IS
      l_interval NUMBER;
   BEGIN
      SELECT interval
        INTO l_interval
        FROM cwms_interval
       WHERE UPPER(interval_id) = UPPER(p_interval_id);

      RETURN l_interval;
   END get_interval;

   FUNCTION get_utc_interval_offset (
      p_date_time_utc    IN DATE,
      p_interval_minutes IN NUMBER)
      RETURN NUMBER result_cache
   IS
   BEGIN
      return round((p_date_time_utc - get_time_on_before_interval(p_date_time_utc, 0, p_interval_minutes)) * 1440);
   END get_utc_interval_offset;

   FUNCTION get_times_for_time_window (
      p_start_time                  IN DATE,
      p_end_time                    IN DATE,
      p_interval_minutes            IN INTEGER,
      p_utc_interval_offset_minutes IN INTEGER,
      p_time_zone                   IN VARCHAR2 DEFAULT 'UTC')
      RETURN date_table_type
   IS
      c_one_month_interval constant integer := 43200;
      c_one_year_interval  constant integer := 525600;
      l_start_time_utc   date;
      l_end_time_utc     date;
      l_months           integer;
      l_valid_interval   boolean := false;
      l_date_times       date_table_type;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      if p_start_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME'); end if;
      if p_end_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME'); end if;
      if p_interval_minutes is null then cwms_err.raise('NULL_ARGUMENT', 'P_INTERVAL_MINUTES'); end if;
      if p_utc_interval_offset_minutes is null then cwms_err.raise('NULL_ARGUMENT', 'P_UTC_INTERVAL_OFFSET_MINUTES'); end if;
      if p_start_time > p_end_time then cwms_err.raise('ERROR', 'End time is greater than start time'); end if;
      for rec in (select distinct interval from cwms_interval) loop
         if p_interval_minutes = rec.interval then
            l_valid_interval := true;
            exit;
         end if;
      end loop;
      if not l_valid_interval then
         cwms_err.raise('INVALID_ITEM', p_interval_minutes, 'CWMS interval minutes');
      end if;
      ----------------------------------------------------------------------
      -- get first and last times that are in time window and on interval --
      ----------------------------------------------------------------------
      l_start_time_utc := get_time_on_after_interval(
         cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC'),
         p_utc_interval_offset_minutes,
         p_interval_minutes);
      l_end_time_utc := get_time_on_before_interval(
         cwms_util.change_timezone(p_end_time, p_time_zone, 'UTC'),
         p_utc_interval_offset_minutes,
         p_interval_minutes);
      if l_start_time_utc > l_end_time_utc then cwms_err.raise('ERROR', 'Time window contains no times on interval.'); end if;
      -------------------
      -- get the times --
      -------------------
      if p_interval_minutes >= c_one_month_interval then
         -----------------------
         -- calendar interval --
         -----------------------
         l_months := case mod(p_interval_minutes, c_one_month_interval) = 0
                        when true  then p_interval_minutes / c_one_month_interval
                        when false then p_interval_minutes / c_one_year_interval * 12
                     end;
         select add_months(l_start_time_utc, (level - 1) * l_months)
           bulk collect into l_date_times
           from dual
        connect by level <= months_between(l_end_time_utc, l_start_time_utc) / l_months + 1;
      else
         -------------------
         -- time interval --
         -------------------
         select l_start_time_utc + (level - 1) * p_interval_minutes / 1440
           bulk collect into l_date_times
           from dual
        connect by level <= round((l_end_time_utc - l_start_time_utc) * 1440 / p_interval_minutes + 1);
      end if;
      ----------------------------------------------------------------
      -- convert the times back to the input time zone if necessary --
      ----------------------------------------------------------------
      if p_time_zone != 'UTC' then
         for i in 1..l_date_times.count loop
            l_date_times(i) := cwms_util.change_timezone(l_date_times(i), 'UTC', p_time_zone);
         end loop;
      end if;
      return l_date_times;
   END get_times_for_time_window;

   FUNCTION get_times_for_time_window (
      p_start_time IN DATE,
      p_end_time   IN DATE,
      p_ts_code    IN INTEGER,
      p_time_zone  IN VARCHAR2 DEFAULT 'UTC')
      RETURN date_table_type
   IS
      l_interval INTEGER;
      l_offset   INTEGER;
   BEGIN
      select interval,
             interval_utc_offset
        into l_interval,
             l_offset
        from cwms_v_ts_id
       where ts_code = p_ts_code;

      if l_interval = 0 then
         cwms_err.raise('ERROR', 'Cannot retrieve times for irregular time series.');
      end if;
      if l_offset = cwms_util.utc_offset_undefined then
         cwms_err.raise('ERROR', 'UTC interval offset is undefined for time series');
      end if;

      return get_times_for_time_window(
         p_start_time,
         p_end_time,
         l_interval,
         l_offset,
         p_time_zone);
   END get_times_for_time_window;

   FUNCTION get_times_for_time_window (
      p_start_time IN DATE,
      p_end_time   IN DATE,
      p_ts_id      IN VARCHAR2,
      p_time_zone  IN VARCHAR2 DEFAULT 'UTC',
      p_office_id  IN VARCHAR2 DEFAULT NULL)
      RETURN date_table_type
   IS
   BEGIN
      return get_times_for_time_window(
         p_start_time,
         p_end_time,
         get_ts_code(p_ts_id, p_office_id),
         p_time_zone);
   END get_times_for_time_window;

   function get_ts_min_date_utc (
      p_ts_code          in number,
      p_version_date_utc in date default cwms_util.non_versioned)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date_utc);
      return l_ts_extents.earliest_non_null_time;
   end get_ts_min_date_utc;

   function get_ts_min_date2_utc (
      p_ts_code          in number,
      p_version_date_utc in date default cwms_util.non_versioned)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date_utc);
      return l_ts_extents.earliest_time;
   end get_ts_min_date2_utc;

   function get_ts_min_date (
      p_cwms_ts_id   in varchar2,
      p_time_zone    in varchar2 default 'UTC',
      p_version_date in date default cwms_util.non_versioned,
      p_office_id    in varchar2 default null)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone);
      return l_ts_extents.earliest_non_null_time;
   end get_ts_min_date;

   function get_ts_min_date2 (
      p_cwms_ts_id   in varchar2,
      p_time_zone    in varchar2 default 'UTC',
      p_version_date in date default cwms_util.non_versioned,
      p_office_id    in varchar2 default null)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone);
      return l_ts_extents.earliest_time;
   end get_ts_min_date2;

   function get_ts_max_date_utc (
      p_ts_code          in number,
      p_version_date_utc in date default cwms_util.non_versioned)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date_utc);
      return l_ts_extents.latest_non_null_time;
   end get_ts_max_date_utc;

   function get_ts_max_date2_utc (
      p_ts_code          in number,
      p_version_date_utc in date default cwms_util.non_versioned)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date_utc);
      return l_ts_extents.latest_time;
   end get_ts_max_date2_utc;

   function get_ts_max_date (
      p_cwms_ts_id   in varchar2,
      p_time_zone    in varchar2 default 'UTC',
      p_version_date in date default cwms_util.non_versioned,
      p_office_id    in varchar2 default null)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone);
      return l_ts_extents.latest_non_null_time;
   end get_ts_max_date;

   function get_ts_max_date2 (
      p_cwms_ts_id   in varchar2,
      p_time_zone    in varchar2 default 'UTC',
      p_version_date in date default cwms_util.non_versioned,
      p_office_id    in varchar2 default null)
      return date
   is
      l_ts_extents ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone);
      return l_ts_extents.latest_time;
   end get_ts_max_date2;

   function get_ts_max_date_utc_2 (
      p_ts_code            in number,
      p_version_date_utc   in date default cwms_util.non_versioned,
      p_year               in number default null)
      return date
   is
      l_max_date_utc   date;
   begin
      for rec in (  select table_name
                         , to_number(to_char(start_date, 'YYYY')) table_year
                      from at_ts_table_properties
                  order by start_date desc)
      loop

         case
          when p_year is null then
          --process for the max date time for this at_tsv_xxxx table
             begin
               execute immediate
                  'select max(date_time)
                     from '||rec.table_name||'
                    where ts_code = :1
                      and version_date = :2'
                  into l_max_date_utc
                  using p_ts_code, p_version_date_utc;

            exception
             when no_data_found then
              l_max_date_utc := null;
            end;

        when p_year = rec.table_year then

          --process only for one year
          begin
            execute immediate
            'select max(date_time)
               from '||rec.table_name||'
              where ts_code = :1
                and version_date = :2'
            into l_max_date_utc
            using p_ts_code, p_version_date_utc;

        exception
         when no_data_found then
          l_max_date_utc := null;
        end;
        else
          --do nothing
          null;

        end case;

         exit when l_max_date_utc is not null;

      end loop;

      return l_max_date_utc;
   end get_ts_max_date_utc_2;

   procedure get_ts_extents_utc (
      p_min_date_utc     out date,
      p_max_date_utc     out date,
      p_ts_code          in  number,
      p_version_date_utc in  date default cwms_util.non_versioned)
	is
      l_ts_extents ts_extents_t;
	begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date_utc);
      p_min_date_utc := l_ts_extents.earliest_non_null_time;
      p_max_date_utc := l_ts_extents.latest_non_null_time;
   end get_ts_extents_utc;

   procedure get_ts_extents2_utc (
      p_min_date_utc     out date,
      p_max_date_utc     out date,
      p_ts_code          in  number,
      p_version_date_utc in  date default cwms_util.non_versioned)
   is
      l_ts_extents ts_extents_t;
	begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date_utc);
      p_min_date_utc := l_ts_extents.earliest_time;
      p_max_date_utc := l_ts_extents.latest_time;
   end get_ts_extents2_utc;

   procedure get_ts_extents (
      p_min_date     out date,
      p_max_date     out date,
      p_cwms_ts_id   in  varchar2,
      p_time_zone    in  varchar2 default 'UTC',
      p_version_date in  date default cwms_util.non_versioned,
      p_office_id    in  varchar2 default null)
   is
      l_ts_extents       ts_extents_t;
   begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone);
      p_min_date := l_ts_extents.earliest_non_null_time;
      p_max_date := l_ts_extents.latest_non_null_time;
   end get_ts_extents;

   procedure get_ts_extents2 (
      p_min_date     out date,
      p_max_date     out date,
      p_cwms_ts_id   in  varchar2,
      p_time_zone    in  varchar2 default 'UTC',
      p_version_date in  date default cwms_util.non_versioned,
      p_office_id    in  varchar2 default null)
   is
      l_version_date_utc date;
      l_ts_extents       ts_extents_t;
   begin
      if p_version_date is null or p_version_date = cwms_util.non_versioned then
         l_version_date_utc := cwms_util.non_versioned;
      else
         l_version_date_utc := cwms_util.change_timezone(p_version_date, p_time_zone, 'UTC');
      end if;
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone);
      p_min_date := l_ts_extents.earliest_time;
      p_max_date := l_ts_extents.latest_time;
   end get_ts_extents2;

   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_cwms_ts_id   in  varchar2,
      p_version_date in  date,
      p_unit         in  varchar2 default null,
      p_office_id    in  varchar2 default null)
	is
	begin
      get_ts_extents(
         p_ts_extents   => p_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_unit         => p_unit);
	end get_ts_extents;

   function get_ts_extents_f(
      p_cwms_ts_id   in varchar2,
      p_version_date in date,
      p_unit         in varchar2 default null,
      p_office_id    in varchar2 default null)
      return ts_extents_t
	is
      l_ts_extents ts_extents_t;
	begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_unit         => p_unit);

      return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_ts_code      in  integer,
      p_version_date in  date,
      p_unit         in  varchar2 default null)
	is
	begin
      get_ts_extents(
         p_ts_extents   => p_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date,
         p_time_zone    => 'UTC',
         p_unit         => p_unit);
	end get_ts_extents;

   function get_ts_extents_f(
      p_ts_code      in integer,
      p_version_date in date,
      p_unit         in varchar2 default null)
      return ts_extents_t
	is
      l_ts_extents ts_extents_t;
	begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date,
         p_unit         => p_unit);

      return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_cwms_ts_id in  varchar2,
      p_unit       in  varchar2 default null,
      p_office_id  in  varchar2 default null)
	is
	begin
		get_ts_extents(
         p_ts_extents => p_ts_extents,
         p_ts_code    => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_unit       => p_unit);
	end get_ts_extents;

   function get_ts_extents_f(
      p_cwms_ts_id in varchar2,
      p_unit       in varchar2 default null,
      p_office_id  in varchar2 default null)
      return ts_extents_tab_t
	is
      l_ts_extents ts_extents_tab_t;
	begin
      get_ts_extents(
         p_ts_extents => l_ts_extents,
         p_cwms_ts_id => p_cwms_ts_id,
         p_unit       => p_unit,
         p_office_id  => p_office_id);
		return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_ts_code    in  integer,
      p_unit       in  varchar2 default null)
	is
      l_version_dates date_table_type;
	begin
		select distinct
             version_date
        bulk collect
        into l_version_dates
        from av_tsv
       where ts_code = p_ts_code
       order by 1;

      p_ts_extents := ts_extents_tab_t();
      p_ts_extents.extend(l_version_dates.count);
      for i in 1..l_version_dates.count loop
         get_ts_extents(
            p_ts_extents   => p_ts_extents(i),
            p_ts_code      => p_ts_code,
            p_version_date => l_version_dates(i),
            p_time_zone    => 'UTC',
            p_unit         => p_unit);
      end loop;
	end get_ts_extents;

   function get_ts_extents_f(
      p_ts_code in integer,
      p_unit    in varchar2 default null)
      return ts_extents_tab_t
	is
      l_ts_extents ts_extents_tab_t;
	begin
      get_ts_extents(
         p_ts_extents => l_ts_extents,
         p_ts_code    => p_ts_code,
         p_unit       => p_unit);
		return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_cwms_ts_id   in  varchar2,
      p_version_date in  date,
      p_time_zone    in  varchar2,
      p_unit         in  varchar2 default null,
      p_office_id    in  varchar2 default null)
	is
	begin
      get_ts_extents(
         p_ts_extents   => p_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone,
         p_unit         => p_unit);
	end get_ts_extents;

   function get_ts_extents_f(
      p_cwms_ts_id   in varchar2,
      p_version_date in date,
      p_time_zone    in varchar2,
      p_unit         in varchar2 default null,
      p_office_id    in varchar2 default null)
      return ts_extents_t
	is
      l_ts_extents ts_extents_t;
	begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone,
         p_unit         => p_unit);
      return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_ts_code      in  integer,
      p_version_date in  date,
      p_time_zone    in  varchar2,
      p_unit         in  varchar2 default null)
	is
      l_rowid            urowid;
      l_ts_extents       ts_extents_t;
      l_version_date_utc date;
      l_time_zone        varchar(28);
      l_parameter_id     varchar2(49);
      l_default_unit     varchar2(16);
	begin
      if p_time_zone is null then
         begin
            select tz.time_zone_name
              into l_time_zone
              from at_cwms_ts_spec ts,
                   at_physical_location pl,
                   cwms_time_zone tz
             where ts.ts_code = p_ts_code
               and pl.location_code = ts.location_code
               and tz.time_zone_code = pl.time_zone_code;
         exception
            when no_data_found then
               l_time_zone := 'UTC';
         end;
      else
         l_time_zone := p_time_zone;
      end if;
      if p_version_date is null or p_version_date = cwms_util.non_versioned then
         l_version_date_utc := cwms_util.non_versioned;
      else
         l_version_date_utc := cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC');
      end if;
      for i in 1..2 loop
         begin
            select rowid
              into l_rowid
              from at_ts_extents
             where ts_code = p_ts_code
               and version_time = l_version_date_utc;
         exception
            when no_data_found then null;
         end;
         exit when l_rowid is not null;
         update_ts_extents(p_ts_code, l_version_date_utc);
      end loop;
      if l_rowid is not null then
         l_ts_extents := ts_extents_t(l_rowid);
         if l_time_zone != 'UTC' then
            l_ts_extents.change_timezone(p_to_timezone => l_time_zone);
         end if;
         if p_unit is not null then
            l_ts_extents.convert_units(p_to_unit => p_unit);
         end if;
      end if;
      p_ts_extents := l_ts_extents;
	end get_ts_extents;

   function get_ts_extents_f(
      p_ts_code      in integer,
      p_version_date in date,
      p_time_zone    in varchar2,
      p_unit         in varchar2 default null)
      return ts_extents_t
	is
      l_ts_extents ts_extents_t;
	begin
      get_ts_extents(
         p_ts_extents   => l_ts_extents,
         p_ts_code      => p_ts_code,
         p_version_date => p_version_date,
         p_time_zone    => p_time_zone,
         p_unit         => p_unit);
		return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_cwms_ts_id in  varchar2,
      p_time_zone  in  varchar2,
      p_unit       in  varchar2 default null,
      p_office_id  in  varchar2 default null)
	is
	begin
		get_ts_extents(
         p_ts_extents => p_ts_extents,
         p_ts_code    => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_time_zone  => p_time_zone,
         p_unit       => p_unit);
	end get_ts_extents;

   function get_ts_extents_f(
      p_cwms_ts_id in varchar2,
      p_time_zone  in varchar2,
      p_unit       in varchar2 default null,
      p_office_id  in varchar2 default null)
      return ts_extents_tab_t
	is
      l_ts_extents ts_extents_tab_t;
	begin
		get_ts_extents(
         p_ts_extents => l_ts_extents,
         p_ts_code    => cwms_ts.get_ts_code(p_cwms_ts_id => p_cwms_ts_id, p_db_office_id => p_office_id),
         p_time_zone  => p_time_zone,
         p_unit       => p_unit);

      return l_ts_extents;
	end get_ts_extents_f;

   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_ts_code    in  integer,
      p_time_zone  in  varchar2,
      p_unit       in  varchar2 default null)
	is
	   type urowid_tab_t is table of urowid;
      l_rowids       urowid_tab_t;
      l_ts_extents   ts_extents_tab_t;
      l_time_zone    varchar(28);
      l_parameter_id varchar2(49);
      l_default_unit varchar2(16);
	begin
      if p_time_zone is null then
         begin
            select tz.time_zone_name
              into l_time_zone
              from at_cwms_ts_spec ts,
                   at_physical_location pl,
                   cwms_time_zone tz
             where ts.ts_code = p_ts_code
               and pl.location_code = ts.location_code
               and tz.time_zone_code = pl.time_zone_code;
         exception
            when no_data_found then
               l_time_zone := 'UTC';
         end;
      else
         l_time_zone := p_time_zone;
      end if;
      for i in 1..2 loop
         begin
            select rowid
              bulk collect
              into l_rowids
              from at_ts_extents
             where ts_code = p_ts_code
             order by version_time;
         exception
            when no_data_found then null;
         end;
         exit when l_rowids.count > 0;
         update_ts_extents(p_ts_code);
      end loop;
      l_ts_extents := ts_extents_tab_t();
      l_ts_extents.extend(l_rowids.count);
      for i in 1..l_rowids.count loop
         l_ts_extents(i) := ts_extents_t(l_rowids(i));
         if l_time_zone != 'UTC' then
            l_ts_extents(i).change_timezone(p_to_timezone => l_time_zone);
         end if;
         if p_unit is not null then
            l_ts_extents(i).convert_units(p_to_unit => p_unit);
         end if;
      end loop;
      p_ts_extents := l_ts_extents;
	end get_ts_extents;

   function get_ts_extents_f(
      p_ts_code   in integer,
      p_time_zone in varchar2,
      p_unit      in  varchar2 default null)
      return ts_extents_tab_t
	is
      l_ts_extents ts_extents_tab_t;
	begin
      get_ts_extents(
         p_ts_extents => l_ts_extents,
         p_ts_code    => p_ts_code,
         p_time_zone  => p_time_zone,
         p_unit       => p_unit);

		return l_ts_extents;
	end get_ts_extents_f;

   procedure get_value_extents (
      p_min_value out binary_double,
      p_max_value out binary_double,
      p_ts_id     in  varchar2,
      p_unit      in  varchar2,
      p_min_date  in  date default null,
      p_max_date  in  date default null,
      p_time_zone in  varchar2 default null,
      p_office_id in  varchar2 default null)
   is
      l_min_value      binary_double;
      l_max_value      binary_double;
      l_temp_min       binary_double;
      l_temp_max       binary_double;
      l_office_id      varchar2 (16);
      l_unit           varchar2 (16);
      l_time_zone      varchar2 (28);
      l_min_date       date;
      l_max_date       date;
      l_ts_code        number (10);
      l_parts          str_tab_t;
      l_location_id    varchar2 (57);
      l_parameter_id   varchar2 (49);
      l_ts_extents     ts_extents_tab_t;
   begin
      if l_min_date is null and l_max_date is null then
         ----------------------------------------
         -- short ciruit through AT_TS_EXTENTS --
         ----------------------------------------
         get_ts_extents(
            p_ts_extents   => l_ts_extents,
            p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_ts_id, p_db_office_id => p_office_id),
            p_time_zone    => p_time_zone,
            p_unit         => p_unit);
         for i in 1..l_ts_extents.count loop
            if l_min_value is null or l_min_value > l_ts_extents(i).least_value then
               l_min_value := l_ts_extents(i).least_value;
            end if;
            if l_max_value is null or l_min_value < l_ts_extents(i).greatest_value then
               l_max_value := l_ts_extents(i).greatest_value;
            end if;
         end loop;
         p_min_value := l_min_value;
         p_max_value := l_max_value;
      else
         ----------------------------
         -- set values from inputs --
         ----------------------------
         l_office_id := cwms_util.get_db_office_id (p_office_id);
         l_ts_code := cwms_ts.get_ts_code (p_ts_id, l_office_id);
         l_parts := cwms_util.split_text (p_ts_id, '.');
         l_location_id := l_parts (1);
         l_parameter_id := l_parts (2);
         l_unit := cwms_util.get_default_units (l_parameter_id);
         l_time_zone :=
            case p_time_zone is null
               when true
               then
                  cwms_loc.get_local_timezone (l_location_id, l_office_id)
               when false
               then
                  p_time_zone
            end;
         l_min_date :=
            case p_min_date is null
               when true
               then
                  date '1700-01-01'
               when false
               then
                  cwms_util.change_timezone (p_min_date, l_time_zone, 'UTC')
            end;
         l_max_date :=
            case p_max_date is null
               when true
               then
                  date '2100-01-01'
               when false
               then
                  cwms_util.change_timezone (p_max_date, l_time_zone, 'UTC')
            end;

         -----------------------
         -- perform the query --
         -----------------------
         for rec in (  select table_name, start_date, end_date
                         from at_ts_table_properties
                     order by start_date)
         loop
            continue when    rec.start_date > l_max_date
                          or rec.end_date < l_min_date;

            begin
               execute immediate
                  'select min(value),
                          max(value)
                     from '||rec.table_name||'
                    where ts_code = :1
                      and date_time between :2 and :3'
                  into l_temp_min, l_temp_max
                  using l_ts_code, l_min_date, l_max_date;

               if l_min_value is null or l_temp_min < l_min_value
               then
                  l_min_value := l_temp_min;
               end if;

               if l_max_value is null or l_temp_max > l_max_value
               then
                  l_max_value := l_temp_max;
               end if;
            exception
               when no_data_found
               then
                  null;
            end;
         end loop;

         if l_min_value is not null
         then
            p_min_value := cwms_util.convert_units (l_min_value, l_unit, p_unit);
         end if;

         if l_max_value is not null
         then
            p_max_value := cwms_util.convert_units (l_max_value, l_unit, p_unit);
         end if;
      end if;
   end get_value_extents;

   procedure get_value_extents (
      p_min_value      out binary_double,
      p_max_value      out binary_double,
      p_min_value_date out date,
      p_max_value_date out date,
      p_ts_id          in  varchar2,
      p_unit           in  varchar2,
      p_min_date       in  date default null,
      p_max_date       in  date default null,
      p_time_zone      in  varchar2 default null,
      p_office_id      in  varchar2 default null)
   is
      l_min_value        binary_double;
      l_max_value        binary_double;
      l_temp_min         binary_double;
      l_temp_max         binary_double;
      l_min_value_date   date;
      l_max_value_date   date;
      l_temp_min_date    date;
      l_temp_max_date    date;
      l_office_id        varchar2 (16);
      l_unit             varchar2 (16);
      l_time_zone        varchar2 (28);
      l_min_date         date;
      l_max_date         date;
      l_ts_code          number (10);
      l_parts            str_tab_t;
      l_location_id      varchar2 (57);
      l_parameter_id     varchar2 (49);
      l_ts_extents     ts_extents_tab_t;
   begin
      if l_min_date is null and l_max_date is null then
         ----------------------------------------
         -- short ciruit through AT_TS_EXTENTS --
         ----------------------------------------
         get_ts_extents(
            p_ts_extents   => l_ts_extents,
            p_ts_code      => cwms_ts.get_ts_code(p_cwms_ts_id => p_ts_id, p_db_office_id => p_office_id),
            p_time_zone    => p_time_zone,
            p_unit         => p_unit);
         for i in 1..l_ts_extents.count loop
            if l_min_value is null or l_min_value > l_ts_extents(i).least_value then
               l_min_value      := l_ts_extents(i).least_value;
               l_min_value_date := l_ts_extents(i).least_value_time;
            end if;
            if l_max_value is null or l_min_value < l_ts_extents(i).greatest_value then
               l_max_value      := l_ts_extents(i).greatest_value;
               l_max_value_date := l_ts_extents(i).greatest_value_time;
            end if;
         end loop;
         p_min_value      := l_min_value;
         p_min_value_date := l_min_value_date;
         p_max_value      := l_max_value;
         p_max_value_date := l_max_value_date;
      else
         ----------------------------
         -- set values from inputs --
         ----------------------------
         l_office_id := cwms_util.get_db_office_id (p_office_id);
         l_ts_code := cwms_ts.get_ts_code (p_ts_id, l_office_id);
         l_parts := cwms_util.split_text (p_ts_id, '.');
         l_location_id := l_parts (1);
         l_parameter_id := l_parts (2);
         l_unit := cwms_util.get_default_units (l_parameter_id);
         l_time_zone :=
            case p_time_zone is null
               when true
               then
                  cwms_loc.get_local_timezone (l_location_id, l_office_id)
               when false
               then
                  p_time_zone
            end;
         l_min_date :=
            case p_min_date is null
               when true
               then
                  date '1700-01-01'
               when false
               then
                  cwms_util.change_timezone (p_min_date, l_time_zone, 'utc')
            end;
         l_max_date :=
            case p_max_date is null
               when true
               then
                  date '2100-01-01'
               when false
               then
                  cwms_util.change_timezone (p_max_date, l_time_zone, 'utc')
            end;

         -----------------------
         -- perform the query --
         -----------------------
         for rec in (  select table_name, start_date, end_date
                         from at_ts_table_properties
                     order by start_date)
         loop
            continue when    rec.start_date > l_max_date
                          or rec.end_date < l_min_date;

            begin
               execute immediate
                  'select date_time,
                          value
                     from '||rec.table_name||'
                    where ts_code = :1
                      and date_time between :2 and :3
                      and value = (select min(value)
                                     from '||rec.table_name||'
                                    where ts_code = :4
                                      and date_time between :5 and :6
                                  )
                      and rownum = 1'
                  into l_temp_min_date, l_temp_min
                  using l_ts_code,
                        l_min_date,
                        l_max_date,
                        l_ts_code,
                        l_min_date,
                        l_max_date;

               if l_min_value is null or l_temp_min < l_min_value
               then
                  l_min_value_date := l_temp_min_date;
                  l_min_value := l_temp_min;
               end if;
            exception
               when no_data_found
               then
                  null;
            end;

            begin
               execute immediate
                  'select date_time,
                          value
                     from '||rec.table_name||'
                    where ts_code = :1
                      and date_time between :2 and :3
                      and value = (select max(value)
                                     from '||rec.table_name||'
                                    where ts_code = :4
                                      and date_time between :5 and :6
                                  )
                      and rownum = 1'
                  into l_temp_max_date, l_temp_max
                  using l_ts_code,
                        l_min_date,
                        l_max_date,
                        l_ts_code,
                        l_min_date,
                        l_max_date;

               if l_max_value is null or l_temp_max > l_max_value
               then
                  l_max_value_date := l_temp_max_date;
                  l_max_value := l_temp_max;
               end if;
            exception
               when no_data_found
               then
                  null;
            end;
         end loop;

         if l_min_value is not null
         then
            p_min_value := cwms_util.convert_units (l_min_value, l_unit, p_unit);
            p_min_value_date :=
               cwms_util.change_timezone (l_min_value_date, 'utc', l_time_zone);
         end if;

         if l_max_value is not null
         then
            p_max_value := cwms_util.convert_units (l_max_value, l_unit, p_unit);
            p_max_value_date :=
               cwms_util.change_timezone (l_max_value_date, 'utc', l_time_zone);
         end if;
      end if;
   end get_value_extents;

   FUNCTION get_values_in_range (p_ts_id       IN VARCHAR2,
                                 p_min_value   IN BINARY_DOUBLE,
                                 p_max_value   IN BINARY_DOUBLE,
                                 p_unit        IN VARCHAR2,
                                 p_min_date    IN DATE DEFAULT NULL,
                                 p_max_date    IN DATE DEFAULT NULL,
                                 p_time_zone   IN VARCHAR2 DEFAULT NULL,
                                 p_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN ztsv_array
   IS
   BEGIN
      RETURN get_values_in_range (time_series_range_t (p_office_id,
                                                       p_ts_id,
                                                       p_min_date,
                                                       p_max_date,
                                                       p_time_zone,
                                                       p_min_value,
                                                       p_max_value,
                                                       p_unit));
   END;

   FUNCTION get_values_in_range (p_criteria IN time_series_range_t)
      RETURN ztsv_array
   IS
      l_results         ztsv_array;
      l_table_results   ztsv_array;
      l_office_id       VARCHAR2 (16);
      l_unit            VARCHAR2 (16);
      l_time_zone       VARCHAR2 (28);
      l_min_value       BINARY_DOUBLE;
      l_max_value       BINARY_DOUBLE;
      l_min_date        DATE;
      l_max_date        DATE;
      l_ts_code         NUMBER (10);
      l_parts           str_tab_t;
      l_location_id     VARCHAR2 (57);
      l_parameter_id    VARCHAR2 (49);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      ----------------------------
      -- set values from inputs --
      ----------------------------
      l_office_id := cwms_util.get_db_office_id (p_criteria.office_id);
      l_ts_code :=
         cwms_ts.get_ts_code (p_criteria.time_series_id, l_office_id);
      l_parts := cwms_util.split_text (p_criteria.time_series_id, '.');
      l_location_id := l_parts (1);
      l_parameter_id := l_parts (2);
      l_unit := cwms_util.get_default_units (l_parameter_id);
      l_min_value :=
         CASE p_criteria.minimum_value IS NULL
            WHEN TRUE
            THEN
               -binary_double_max_normal
            WHEN FALSE
            THEN
               cwms_util.convert_units (p_criteria.minimum_value,
                                        p_criteria.unit,
                                        l_unit)
         END;
      l_max_value :=
         CASE p_criteria.maximum_value IS NULL
            WHEN TRUE
            THEN
               binary_double_max_normal
            WHEN FALSE
            THEN
               cwms_util.convert_units (p_criteria.maximum_value,
                                        p_criteria.unit,
                                        l_unit)
         END;
      l_time_zone :=
         CASE p_criteria.time_zone IS NULL
            WHEN TRUE
            THEN
               cwms_loc.get_local_timezone (l_location_id, l_office_id)
            WHEN FALSE
            THEN
               p_criteria.time_zone
         END;
      l_min_date :=
         CASE p_criteria.start_time IS NULL
            WHEN TRUE
            THEN
               DATE '1700-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_criteria.start_time,
                                          l_time_zone,
                                          'UTC')
         END;
      l_max_date :=
         CASE p_criteria.end_time IS NULL
            WHEN TRUE
            THEN
               DATE '2100-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_criteria.end_time,
                                          l_time_zone,
                                          'UTC')
         END;

      -----------------------
      -- perform the query --
      -----------------------
      IF     p_criteria.minimum_value IS NULL
         AND p_criteria.maximum_value IS NULL
      THEN
         -----------------------------
         -- just call retrieve_ts() --
         -----------------------------
         DECLARE
            l_cursor      SYS_REFCURSOR;
            l_dates       date_table_type;
            l_values      double_tab_t;
            l_qualities   number_tab_t;
         BEGIN
            retrieve_ts (p_at_tsv_rc         => l_cursor,
                         p_cwms_ts_id        => p_criteria.time_series_id,
                         p_units             => l_unit,
                         p_start_time        => l_min_date,
                         p_end_time          => l_max_date,
                         p_time_zone         => 'UTC',
                         p_trim              => 'T',
                         p_start_inclusive   => 'T',
                         p_end_inclusive     => 'T',
                         p_previous          => 'F',
                         p_next              => 'F',
                         p_version_date      => NULL,
                         p_max_version       => 'T',
                         p_office_id         => l_office_id);

            FETCH l_cursor
            BULK COLLECT INTO l_dates, l_values, l_qualities;

            CLOSE l_cursor;

            IF l_dates IS NOT NULL AND l_dates.COUNT > 0
            THEN
               l_results := ztsv_array ();
               l_results.EXTEND (l_dates.COUNT);

               FOR i IN 1 .. l_dates.COUNT
               LOOP
                  l_results (i) :=
                     ztsv_type (
                        cwms_util.change_timezone (l_dates (i),
                                                   'UTC',
                                                   l_time_zone),
                        l_values (i),
                        l_qualities (i));
               END LOOP;
            END IF;
         END;
      ELSE
         ---------------------------------------
         -- find the values that are in range --
         ---------------------------------------
         FOR rec IN (  SELECT table_name, start_date, end_date
                         FROM at_ts_table_properties
                     ORDER BY start_date)
         LOOP
            CONTINUE WHEN    rec.start_date > l_max_date
                          OR rec.end_date < l_min_date;

            BEGIN
               EXECUTE IMMEDIATE
                  'select ztsv_type(date_time, value, quality_code)
                    from '||rec.table_name||'
                   where ts_code = :1
                     and date_time between :1 and :2
                     and value between :3 and :4'
                  BULK COLLECT INTO l_table_results
                  USING l_ts_code,
                        l_min_date,
                        l_max_date,
                        l_min_value,
                        l_max_value;

               IF l_results IS NULL
               THEN
                  l_results := ztsv_array ();
               END IF;

               l_results.EXTEND (l_table_results.COUNT);

               FOR i IN 1 .. l_table_results.COUNT
               LOOP
                  l_table_results (i).date_time :=
                     cwms_util.change_timezone (
                        l_table_results (i).date_time,
                        'UTC',
                        l_time_zone);
                  l_table_results (i).VALUE :=
                     cwms_util.convert_units (l_table_results (i).VALUE,
                                              l_unit,
                                              p_criteria.unit);
                  l_results (l_results.COUNT - l_table_results.COUNT + i) :=
                     l_table_results (i);
               END LOOP;

               l_table_results.delete;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
         END LOOP;
      END IF;

      RETURN l_results;
   END get_values_in_range;

   FUNCTION get_values_in_range (p_criteria IN time_series_range_tab_t)
      RETURN ztsv_array_tab
   IS
      TYPE index_by_date_t IS TABLE OF INTEGER
                                 INDEX BY VARCHAR (12);

      TYPE index_by_date_tab_t IS TABLE OF index_by_date_t;

      c_date_fmt   CONSTANT VARCHAR2 (14) := 'yyyymmddhh24mi';
      l_criteria            time_series_range_tab_t := p_criteria;
      l_original_results    ztsv_array_tab := ztsv_array_tab ();
      l_results             ztsv_array_tab := ztsv_array_tab ();
      l_common_dates        index_by_date_t;
      l_individual_dates    index_by_date_tab_t := index_by_date_tab_t ();
      l_count               PLS_INTEGER;
      l_date                VARCHAR2 (12);
      l_dates               date_table_type := date_table_type ();
      l_min_date            DATE;
      l_max_date            DATE;
   BEGIN
      IF l_criteria IS NOT NULL
      THEN
         l_count := l_criteria.COUNT;
         l_individual_dates.EXTEND (l_count);
         l_original_results.EXTEND (l_count);
         l_results.EXTEND (l_count);

         ------------------------------------------------------
         -- get the data for each individual criteria object --
         ------------------------------------------------------
         FOR i IN 1 .. l_count
         LOOP
            IF l_min_date IS NOT NULL
            THEN
               l_criteria (i).start_time :=
                  GREATEST (l_criteria (i).start_time, l_min_date);
            END IF;

            IF l_max_date IS NOT NULL
            THEN
               l_criteria (i).start_time :=
                  LEAST (l_criteria (i).start_time, l_max_date);
            END IF;

            l_original_results (i) := get_values_in_range (l_criteria (i));

            IF     l_original_results (i) IS NOT NULL
               AND l_original_results (i).COUNT > 0
            THEN
               IF l_original_results (i) (1).date_time > l_min_date
               THEN
                  l_min_date := l_original_results (i) (1).date_time;
               END IF;

               IF l_original_results (i) (l_original_results (i).COUNT).date_time <
                     l_max_date
               THEN
                  l_max_date :=
                     l_original_results (i) (l_original_results (i).COUNT).date_time;
               END IF;

               FOR j IN 1 .. l_original_results (i).COUNT
               LOOP
                  l_date :=
                     TO_CHAR (l_original_results (i) (j).date_time,
                              c_date_fmt);
                  l_common_dates (l_date) := 0;
                  l_individual_dates (i) (l_date) := j;
               END LOOP;
            END IF;
         END LOOP;

         --------------------------------------------------------
         -- determine the times that are common to all results --
         --------------------------------------------------------
         FOR i IN 1 .. l_count
         LOOP
            EXIT WHEN l_common_dates.COUNT = 0;
            l_date := l_common_dates.LAST;

            LOOP
               EXIT WHEN l_date IS NULL;

               IF NOT l_individual_dates (i).EXISTS (l_date)
               THEN
                  l_common_dates.delete (l_date);
               END IF;

               l_date := l_common_dates.PRIOR (l_date);
            END LOOP;
         END LOOP;

         ------------------------------------------------
         -- build the result set from the common times --
         ------------------------------------------------
         IF l_common_dates.COUNT > 0
         THEN
            FOR i IN 1 .. l_count
            LOOP
               l_results (i) := ztsv_array ();
               l_date := l_common_dates.FIRST;

               LOOP
                  EXIT WHEN l_date IS NULL;
                  l_results (i).EXTEND;
                  l_results (i) (l_results (i).COUNT) :=
                     l_original_results (i) (l_individual_dates (i) (l_date));
                  l_date := l_common_dates.NEXT (l_date);
               END LOOP;
            END LOOP;
         END IF;
      END IF;

      RETURN l_results;
   END get_values_in_range;

   PROCEDURE trim_ts_deleted_times
   IS
      l_millis_count   NUMBER (14);
      l_millis_date    NUMBER (14);
      l_count          NUMBER;
      l_count2         NUMBER;
      l_max_count      NUMBER;
      l_max_days       NUMBER;
      l_office_id      VARCHAR2 (16) := cwms_util.user_office_id;
   BEGIN
      cwms_msg.log_db_message (cwms_msg.msg_level_basic,
                               'Start trimming AT_TS_DELETED_TIMES entries');
      ---------------------------------------
      -- get the count and date properties --
      ---------------------------------------
      l_max_count :=
         TO_NUMBER (cwms_properties.get_property (
                       'CWMSDB',
                       'ts_deleted.table.max_entries',
                       '1000000',
                       l_office_id));
      l_max_days :=
         TO_NUMBER (cwms_properties.get_property ('CWMSDB',
                                                  'ts_deleted.table.max_age',
                                                  '7',
                                                  l_office_id));

      -------------------------------------------
      -- determine the millis cutoff for count --
      -------------------------------------------
      SELECT COUNT (*) INTO l_count FROM at_ts_deleted_times;

      cwms_msg.log_db_message (
         cwms_msg.msg_level_detailed,
         'AT_TS_DELETED_TIMES has ' || l_count || ' records.');

      IF l_count > l_max_count
      THEN
         SELECT deleted_time
           INTO l_millis_count
           FROM (  SELECT deleted_time, ROWNUM AS rn
                     FROM at_ts_deleted_times
                 ORDER BY deleted_time DESC)
          WHERE rn = TRUNC (l_max_count);
      END IF;

      ------------------------------------------
      -- determine the millis cutoff for date --
      ------------------------------------------
      l_millis_date :=
         cwms_util.to_millis (
              SYSTIMESTAMP AT TIME ZONE 'UTC'
            - NUMTODSINTERVAL (l_max_days, 'DAY'));

      --------------------
      -- trim the table --
      --------------------
      DELETE FROM at_ts_deleted_times
            WHERE deleted_time < GREATEST (l_millis_count, l_millis_date);

      SELECT COUNT (*) INTO l_count2 FROM at_ts_deleted_times;

      l_count := l_count - l_count2;
      cwms_msg.log_db_message (
         cwms_msg.msg_level_detailed,
         'Deleted ' || l_count || ' records from AT_TS_DELETED_TIMES');

      cwms_msg.log_db_message (cwms_msg.msg_level_basic,
                               'Done trimming AT_TS_DELETED_TIMES entries');
   END trim_ts_deleted_times;

   PROCEDURE start_trim_ts_deleted_job
   IS
      l_count          BINARY_INTEGER;
      l_user_id        VARCHAR2 (30);
      l_job_id         VARCHAR2 (30) := 'TRIM_TS_DELETED_TIMES_JOB';
      l_run_interval   VARCHAR2 (8);
      l_comment        VARCHAR2 (256);

      FUNCTION job_count
         RETURN BINARY_INTEGER
      IS
      BEGIN
         SELECT COUNT (*)
           INTO l_count
           FROM sys.dba_scheduler_jobs
          WHERE job_name = l_job_id AND owner = l_user_id;

         RETURN l_count;
      END;
   BEGIN
      --------------------------------------
      -- make sure we're the correct user --
      --------------------------------------
      l_user_id := cwms_util.get_user_id;

      IF UPPER (l_user_id) != UPPER ('&cwms_schema')
      THEN
--         DBMS_OUTPUT.put_line ('User ID = ' || l_user_id);
--         DBMS_OUTPUT.put_line ('Must be : ' || 'CWMS_20');
         raise_application_error (
            -20999,
            'Must be &cwms_schema user to start job ' || l_job_id,
            TRUE);
      END IF;

      -------------------------------------------
      -- drop the job if it is already running --
      -------------------------------------------
      IF job_count > 0
      THEN
--         DBMS_OUTPUT.put ('Dropping existing job ' || l_job_id || '...');
         DBMS_SCHEDULER.drop_job (l_job_id);

         --------------------------------
         -- verify that it was dropped --
         --------------------------------
--         IF job_count = 0
--         THEN
--            DBMS_OUTPUT.put_line ('done.');
--         ELSE
--            DBMS_OUTPUT.put_line ('failed.');
--         END IF;
      END IF;

      IF job_count = 0
      THEN
         BEGIN
            ---------------------
            -- restart the job --
            ---------------------
            cwms_properties.get_property (l_run_interval,
                                          l_comment,
                                          'CWMSDB',
                                          'ts_deleted.auto_trim.interval',
                                          '15',
                                          'CWMS');
            DBMS_SCHEDULER.create_job (
               job_name          => l_job_id,
               job_type          => 'stored_procedure',
               job_action        => 'cwms_ts.trim_ts_deleted_times',
               start_date        => NULL,
               repeat_interval   =>    'freq=minutely; interval='
                                    || l_run_interval,
               end_date          => NULL,
               job_class         => 'default_job_class',
               enabled           => TRUE,
               auto_drop         => FALSE,
               comments          => 'Trims at_ts_deleted_times to specified max entries and max age.');

            IF job_count = 1
            THEN
               null;
--               DBMS_OUTPUT.put_line (
--                     'Job '
--                  || l_job_id
--                  || ' successfully scheduled to execute every '
--                  || l_run_interval
--                  || ' minutes.');
            ELSE
               cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               cwms_err.raise ('ITEM_NOT_CREATED',
                               'job',
                               l_job_id || ':' || SQLERRM);
         END;
      END IF;
   END start_trim_ts_deleted_job;

   FUNCTION get_associated_timeseries (
      p_location_id         IN VARCHAR2,
      p_association_type    IN VARCHAR2,
      p_usage_category_id   IN VARCHAR2,
      p_usage_id            IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   AS
      l_office_id   VARCHAR2 (16);
      l_tsid        VARCHAR2(191);
   BEGIN
      l_office_id := cwms_util.get_db_office_id (p_office_id);

      ----------------------------------------------------------------------------
      -- retrieve the associated time series with specified or default location --
      ----------------------------------------------------------------------------
      BEGIN
         SELECT timeseries_id
           INTO l_tsid
           FROM (  SELECT timeseries_id
                     FROM cwms_v_ts_association
                    WHERE     UPPER (association_id) IN
                                 ('?GLOBAL?', UPPER (p_location_id))
                          AND association_type = UPPER (p_association_type)
                          AND UPPER (usage_category_id) =
                                 UPPER (p_usage_category_id)
                          AND UPPER (usage_id) = UPPER (p_usage_id)
                          AND office_id = l_office_id
                 ORDER BY association_id DESC -- '?GLOBAL?' sorts after actual location
                )
          WHERE ROWNUM < 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               'No such time series association: '''
               || l_office_id
               || '/'
               || '?GLOBAL?/'
               || p_association_type
               || '/'
               || p_usage_category_id
               || '/'
               || p_usage_id
               || '''');
      END get_associated_timeseries;

      ---------------------------------------
      -- return the associated time series --
      ---------------------------------------
      RETURN REPLACE (l_tsid, '?GLOBAL?', p_location_id);
   END;

   procedure set_retrieve_unsigned_quality
   is
   begin
      cwms_util.set_session_info('UNSIGNED QUALITY', 'T');
   end set_retrieve_unsigned_quality;

   procedure set_retrieve_signed_quality
   is
   begin
      cwms_util.reset_session_info('UNSIGNED QUALITY');
   end set_retrieve_signed_quality;

   function normalize_quality(
      p_quality in number)
      return number
      result_cache
   is
      l_quality number;
   begin
      case cwms_util.get_session_info_txt('UNSIGNED QUALITY')
         when 'T' then
            if p_quality < 0 then
               l_quality := 4294967296 + p_quality;
            else
               l_quality := p_quality;
            end if;
         else
            if p_quality > 2147483647 then
               l_quality := p_quality - 4294967296;
            else
               l_quality := p_quality;
            end if;
      end case;
      return l_quality;
   end normalize_quality;

   procedure set_nulls_storage_policy_ofc(
      p_storage_policy in integer,
      p_office_id      in varchar2 default null)
   as
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_storage_policy is not null and
         p_storage_policy not in (
            filter_out_null_values,
            set_null_values_to_missing,
            reject_ts_with_null_values)
      then
         cwms_err.raise(
            'ERROR',
            'P_STORAGE_POLICY must be one of FILTER_OUT_NULL_VALUES, SET_NULL_VALUES_TO_MISSING, or REJECT_TS_WITH_NULL_VALUES');
      end if;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_normal,
         'Setting NULLs storage policy to '
         || case p_storage_policy is null
               when true then 'NULL'
               else case p_storage_policy
               	      when filter_out_null_values then
               	         'FILTER_OUT_NULL_VALUES'
               	      when set_null_values_to_missing then
               	      	 'SET_NULL_VALUES_TO_MISSING'
               	      when reject_ts_with_null_values then
               	      	 'REJECT_TS_WITH_NULL_VALUES'
                    end
            end
         ||' for office '
         ||cwms_util.get_db_office_id(p_office_id));
      if p_storage_policy is null then
         cwms_properties.delete_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.office.'||cwms_util.get_db_office_code(p_office_id),
            p_office_id => 'CWMS');
      else
         cwms_properties.set_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.office.'||cwms_util.get_db_office_code(p_office_id),
            p_value     => p_storage_policy,
            p_comment   => null,
            p_office_id => 'CWMS');
      end if;
   end set_nulls_storage_policy_ofc;

   procedure set_nulls_storage_policy_ts(
      p_storage_policy in integer,
      p_ts_id          in varchar2,
      p_office_id      in varchar2 default null)
   as
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_storage_policy is not null and
         p_storage_policy not in (
            filter_out_null_values,
            set_null_values_to_missing,
            reject_ts_with_null_values)
      then
         cwms_err.raise(
            'ERROR',
            'P_STORAGE_POLICY must be one of FILTER_OUT_NULL_VALUES, SET_NULL_VALUES_TO_MISSING, or REJECT_TS_WITH_NULL_VALUES');
      end if;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_normal,
         'Setting NULLs storage policy to '
         || case p_storage_policy is null
               when true then 'NULL'
               else case p_storage_policy
               	      when filter_out_null_values then
               	         'FILTER_OUT_NULL_VALUES'
               	      when set_null_values_to_missing then
               	      	 'SET_NULL_VALUES_TO_MISSING'
               	      when reject_ts_with_null_values then
               	      	 'REJECT_TS_WITH_NULL_VALUES'
                    end
            end
         ||' for time seires '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_ts_id
         ||' ('
         ||get_ts_code(p_ts_id, p_office_id)
         ||')');
      if p_storage_policy is null then
         cwms_properties.delete_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.tscode.'||get_ts_code(p_ts_id, p_office_id),
            p_office_id => 'CWMS');
      else
         cwms_properties.set_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.tscode.'||get_ts_code(p_ts_id, p_office_id),
            p_value     => p_storage_policy,
            p_comment   => null,
            p_office_id => 'CWMS');

      end if;
   end set_nulls_storage_policy_ts;

   function get_nulls_storage_policy_ofc(
      p_office_id in varchar2 default null)
      return integer
   as
   begin
      return cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.nulls.office.'||cwms_util.get_db_office_code(p_office_id),
         p_default   => null,
         p_office_id => 'CWMS');
   end get_nulls_storage_policy_ofc;

   function get_nulls_storage_policy_ts(
      p_ts_id     in varchar2,
      p_office_id in varchar2 default null)
      return integer
   as
   begin
      return cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.nulls.tscode.'||get_ts_code(p_ts_id, p_office_id),
         p_default   => null,
         p_office_id => 'CWMS');
   end get_nulls_storage_policy_ts;

   function get_nulls_storage_policy(
      p_ts_code in integer)
      return integer
   as
      l_policy      integer;
      l_office_code integer;
   begin
      l_policy := cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.nulls.tscode.'||p_ts_code,
         p_default   => null,
         p_office_id => 'CWMS');
      if l_policy is null then
         select bl.db_office_code
           into l_office_code
           from at_cwms_ts_spec ts,
                at_physical_location pl,
                at_base_location bl
          where ts.ts_code = p_ts_code
            and pl.location_code = ts.location_code
            and bl.base_location_code = pl.base_location_code;
         l_policy := cwms_properties.get_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.office.'||l_office_code,
            p_default   => null,
            p_office_id => 'CWMS');
         if l_policy is null then
            l_policy := filter_out_null_values;
         end if;
      end if;
      return l_policy;
   end get_nulls_storage_policy;

   procedure set_filter_duplicates_ofc(
      p_filter_duplicates in varchar2,
      p_office_id         in varchar2 default null)
   is
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_filter_duplicates is not null and p_filter_duplicates not in ('T', 'F') then
         cwms_err.raise(
            'ERROR',
            'P_FILTER_DUPLICATES must be NULL, ''T'', or ''F''');
      end if;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_normal,
         'Setting filter duplicates policy to '
         || nvl(p_filter_duplicates, 'NULL (reset) for office')
         ||cwms_util.get_db_office_id(p_office_id));
      if p_filter_duplicates is null
      then
         cwms_properties.delete_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.filter_duplicates.office',
            p_office_id => cwms_util.get_db_office_id(p_office_id));
      else
         cwms_properties.set_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.filter_duplicates.office',
            p_value     => p_filter_duplicates,
            p_comment   => null,
            p_office_id => cwms_util.get_db_office_id(p_office_id));
      end if;
   end set_filter_duplicates_ofc;

   procedure set_filter_duplicates_ts(
      p_filter_duplicates in varchar2,
      p_ts_id             in varchar2,
      p_office_id         in varchar2 default null)
   is
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_ts_id is null then
         cwms_err.raise(
            'ERROR',
            'P_TS_ID must not be NULL');
      end if;
      set_filter_duplicates_ts(
         p_filter_duplicates,
         get_ts_code(p_ts_id, p_office_id));
   end set_filter_duplicates_ts;

   procedure set_filter_duplicates_ts(
      p_filter_duplicates in varchar2,
      p_ts_code           in integer)
   is
      l_office_id varchar2(16);
      l_ts_id     varchar2(256);
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_ts_code is null then
         cwms_err.raise(
            'ERROR',
            'P_TS_CODE must not be NULL');
      end if;
      if p_filter_duplicates is not null and p_filter_duplicates not in ('T', 'F') then
         cwms_err.raise(
            'ERROR',
            'P_FILTER_DUPLICATES must be NULL, ''T'', or ''F''');
      end if;
      select db_office_id,
             cwms_ts_id
        into l_office_id,
             l_ts_id
        from at_cwms_ts_id
       where ts_code = p_ts_code;
      cwms_msg.log_db_message(
         cwms_msg.msg_level_normal,
         'Setting filter duplicates policy to '
         || nvl(p_filter_duplicates, 'NULL (reset)')
         ||' for time series '
         ||p_ts_code
         ||' : '
         ||l_office_id
         ||'/'
         ||l_ts_id);
      if p_filter_duplicates is null then
         cwms_properties.delete_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.filter_duplicates.tscode.'||p_ts_code,
            p_office_id => cwms_util.get_db_office_id(l_office_id));
      else
         cwms_properties.set_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.filter_duplicates.tscode.'||p_ts_code,
            p_value     => p_filter_duplicates,
            p_comment   => null,
            p_office_id => l_office_id);
      end if;
   end set_filter_duplicates_ts;

   function get_filter_duplicates_ofc(
      p_office_id in varchar2 default null)
      return varchar2
   is
   begin
      return cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.filter_duplicates.office',
         p_default   => null,
         p_office_id => cwms_util.get_db_office_id(p_office_id));
   end get_filter_duplicates_ofc;

   function get_filter_duplicates(
      p_ts_id     in varchar2,
      p_office_id in varchar2 default null)
      return varchar2
   is
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_ts_id is null then
         cwms_err.raise(
            'ERROR',
            'P_TS_ID must not be NULL');
      end if;
      return get_filter_duplicates(get_ts_code(p_ts_id, p_office_id));
   end get_filter_duplicates;

   function get_filter_duplicates(
      p_ts_code in integer)
      return varchar2
   is
      l_office_id varchar2(16);
      l_ts_id     varchar2(256);
      l_prop_val  varchar2(256);
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_ts_code is null then
         cwms_err.raise(
            'ERROR',
            'P_TS_CODE must not be NULL');
      end if;
      select db_office_id
        into l_office_id
        from at_cwms_ts_id
       where ts_code = p_ts_code;
      l_prop_val := cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.filter_duplicates.tscode.'||p_ts_code,
         p_default   => null,
         p_office_id => cwms_util.get_db_office_id(l_office_id));
      if l_prop_val is null then
         l_prop_val := get_filter_duplicates_ofc(l_office_id);
      end if;
      return nvl(l_prop_val, 'F');
   end get_filter_duplicates;

   procedure set_historic(
      p_ts_id       in varchar2,
      p_is_historic in varchar2 default 'T',
      p_office_id   in varchar2 default null)
   is
   begin
      set_historic(get_ts_code(p_ts_id, p_office_id), p_is_historic);
   end set_historic;

   procedure set_historic(
      p_ts_code     in integer,
      p_is_historic in varchar2 default 'T')
   is
   begin
      update at_cwms_ts_spec
         set historic_flag = nvl(upper(p_is_historic), 'T')
       where ts_code = p_ts_code;
   end set_historic;

   function is_historic(
      p_ts_id       in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return is_historic(get_ts_code(p_ts_id, p_office_id));
   end is_historic;

   function is_historic(
      p_ts_code     in integer,
      p_office_id   in varchar2 default null)
      return varchar2
   is
      l_is_historic varchar2(1);
   begin
      select historic_flag into l_is_historic from at_cwms_ts_spec where ts_code = p_ts_code;
      return l_is_historic;
   end is_historic;

   procedure retrieve_time_series(
      p_results        out clob,
      p_date_time      out date,
      p_query_time     out integer,
      p_format_time    out integer,
      p_ts_count       out integer,
      p_value_count    out integer,
      p_names          in  varchar2 default null,
      p_format         in  varchar2 default null,
      p_units          in  varchar2 default null,
      p_datums         in  varchar2 default null,
      p_start          in  varchar2 default null,
      p_end            in  varchar2 default null,
      p_timezone       in  varchar2 default null,
      p_office_id      in  varchar2 default null)
   is
      type tsid_rec_t is record(ts_code integer, office varchar2(16), name varchar2(512));
      type tsid_tab_t is table of tsid_rec_t;
      type tsid_tab_tab_t is table of tsid_tab_t;
      type idx_t is table of str_tab_t index by varchar2(16);
      type bool_t is table of boolean index by varchar2(32767);
      type indexes_rec_t is record(i integer, j integer);
      type indexes_tab_t is table of indexes_rec_t index by varchar2(32767);
      type tsv_t is record(date_time date, value binary_double, quality_code integer);
      type tsv_tab_t is table of tsv_t;
      type values_by_code_t is table of tsv_tab_t index by varchar2(32767);
      type segment_t is record(start_time date, end_time date, first_index integer, last_index integer);
      type seg_tab_t is table of segment_t;
      l_input_names        varchar2(32767);
      l_data               clob;
      l_format             varchar2(16);
      l_names              str_tab_t;
      l_normalized_names   str_tab_t;
      l_units              str_tab_t;
      l_datums             str_tab_t;
      l_alternate_names    str_tab_t;
      l_start              date;
      l_end                date;
      l_start_utc          date;
      l_end_utc            date;
      l_timezone           varchar2(28);
      l_office_id          varchar2(16);
      l_code               integer;
      l_code_str           varchar2(32767);
      l_codes1             number_tab_t;
      l_codes2             number_tab_t;
      l_codes3             number_tab_t;
      l_parts              str_tab_t;
      l_unit               varchar2(16);
      l_datum              varchar2(16);
      l_count              pls_integer;
      l_tsid_count         integer := 0;
      l_unique_tsid_count  integer := 0;
      l_value_count        integer := 0;
      l_unique_value_count integer := 0;
      l_name               varchar2(512);
      l_xml                xmltype;
      l_first              boolean;
      l_lines              str_tab_t;
      l_ts1                timestamp;
      l_ts2                timestamp;
      l_elapsed_query      interval day (0) to second (6);
      l_elapsed_format     interval day (0) to second (6);
      l_query_time         date;
      c                    sys_refcursor;
      l_tsids              tsid_tab_tab_t;
      l_tsids2             idx_t;
      l_quality_used       bool_t;
      l_text               varchar2(32767);
      l_tsv                tsv_tab_t;
      l_segments           seg_tab_t;
      l_last_non_null      integer;
      l_intvl              pls_integer;
      l_intvl_str          varchar2(16);
      l_estimated          boolean;
      l_is_elev            boolean;
      l_only_cwms_names    boolean;
      l_indexes            indexes_tab_t;
      l_values_by_code     values_by_code_t;
      l_max_size           integer;
      l_max_time           interval day (0) to second (3);
      l_max_size_msg       varchar2(17) := 'MAX SIZE EXCEEDED';
      l_max_time_msg       varchar2(17) := 'MAX TIME EXCEEDED';

   function iso_duration(
      p_intvl in dsinterval_unconstrained)
      return varchar2
   is
      l_hours   integer := extract(hour   from p_intvl);
      l_minutes integer := extract(minute from p_intvl);
      l_seconds number  := extract(second from p_intvl);
      l_iso     varchar2(17) := 'PT';
   begin
      if l_hours > 0 then
         l_iso := l_iso || l_hours || 'H';
      end if;
      if l_minutes > 0 then
         l_iso := l_iso || l_minutes || 'M';
      end if;
      if l_seconds > 0 then
         l_iso := l_iso || trim(to_char(l_seconds, '90.999')) || 'S';
      end if;
      if l_iso = 'PT' then
         l_iso := l_iso || '0S';
      end if;
      return l_iso;
   end;

   begin
      l_query_time := cast(systimestamp at time zone 'UTC' as date);

      l_max_size := to_number(cwms_properties.get_property('CWMS-RADAR', 'results.max-size', '5242880', 'CWMS')); -- 5 MB default
      l_max_time := to_dsinterval(cwms_properties.get_property('CWMS-RADAR', 'query.max-time', '00 00:00:30', 'CWMS')); -- 30 sec default
      ----------------------------
      -- process the parameters --
      ----------------------------
      -----------
      -- names --
      -----------
      l_only_cwms_names := instr(p_names, '@') = 1;
      if l_only_cwms_names then
         l_input_names := substr(p_names, 2);
      else
         l_input_names := p_names;
      end if;
      if l_input_names is not null then
         l_names := cwms_util.split_text(l_input_names, '|');
         for i in 1..l_names.count loop
            l_names(i) := trim(l_names(i));
         end loop;
      end if;
      ------------
      -- format --
      ------------
      if p_format is null then
         l_format := 'TAB';
      else
         l_format := upper(trim(p_format));
         if l_format not in ('TAB','CSV','XML','JSON') then
            cwms_err.raise('INVALID_ITEM', l_format, 'time series response format');
         end if;
      end if;
      ------------
      -- office --
      ------------
      if p_office_id is null then
         l_office_id := '*';
      else
         begin
            l_office_id := upper(trim(p_office_id));
            select office_id into l_office_id from cwms_office where office_id = l_office_id;
         exception
            when no_data_found then
               cwms_err.raise('INVALID_OFFICE_ID', l_office_id);
         end;
      end if;
      l_office_id := cwms_util.normalize_wildcards(l_office_id);
      if l_names is not null then
         -----------
         -- units --
         -----------
         if p_units is null then
            l_units := str_tab_t();
            l_units.extend(l_names.count);
            for i in 1..l_units.count loop
               l_units(i) := 'EN';
            end loop;
         else
            l_units := cwms_util.split_text(p_units, '|');
            l_count := l_units.count - l_names.count;
            if l_count > 0 then
               l_units.trim(l_count);
            elsif l_count < 0 then
               l_unit := l_units(l_units.count);
               l_count := -l_count;
               l_units.extend(l_count);
               for i in 1..l_count loop
                  l_units(l_units.count - i + 1) := l_unit;
               end loop;
            end if;
         end if;
         ------------
         -- datums --
         ------------
         if p_datums is null then
            l_datums := str_tab_t();
            l_datums.extend(l_names.count);
            for i in 1..l_datums.count loop
               l_datums(i) := 'NATIVE';
            end loop;
         else
            l_datums := cwms_util.split_text(p_datums, '|');
            for i in 1..l_datums.count loop
               l_datums(i) := trim(l_datums(i));
               if upper(l_datums(i)) in ('NATIVE', 'NAVD88', 'NGVD29') then
                  l_datums(i) := upper(l_datums(i));
               else
                  cwms_err.raise('INVALID_ITEM', l_datums(i), 'time series response datum');
               end if;
            end loop;
            l_count := l_datums.count - l_names.count;
            if l_count > 0 then
               l_datums.trim(l_count);
            elsif l_count < 0 then
               l_datum := l_datums(l_datums.count);
               l_count := -l_count;
               l_datums.extend(l_count);
               for i in 1..l_count loop
                  l_datums(l_datums.count - i + 1) := l_datum;
               end loop;
            end if;
         end if;
      end if;
      -----------------
      -- time window --
      -----------------
      if p_timezone is null then
         l_timezone := 'UTC';
      else
         l_timezone := cwms_util.get_time_zone_name(trim(p_timezone));
         if l_timezone is null then
            cwms_err.raise('INVALID_ITEM', p_timezone, 'CWMS time zone name');
         end if;
      end if;
      if p_end is null then
         l_end_utc := sysdate;
         l_end     := cwms_util.change_timezone(l_end_utc, 'UTC', l_timezone);
      else
         l_end     := cast(from_tz(cwms_util.to_timestamp(p_end), l_timezone) as date);
         l_end_utc := cwms_util.change_timezone(l_end, l_timezone, 'UTC');
      end if;
      if p_start is null then
         l_start     := l_end - 1;
         l_start_utc := l_end_utc - 1;
      else
         l_start     := cast(from_tz(cwms_util.to_timestamp(p_start), l_timezone) as date);
         l_start_utc := cwms_util.change_timezone(l_start, l_timezone, 'UTC');
      end if;
      -----------------------
      -- retreive the data --
      -----------------------
      dbms_lob.createtemporary(l_data, true);
      l_value_count := 0;
      l_tsids := tsid_tab_tab_t();
      l_ts1 := systimestamp;
      l_elapsed_query := l_ts1 - l_ts1;
      l_elapsed_format := l_elapsed_query;
      begin
         if l_names is null then
            --------------------------------------------------------------
            -- retrieve catalog of time series with data in time window --
            --------------------------------------------------------------
            l_tsids.extend;
            for rec in (select table_name
                          from at_ts_table_properties
                         where start_date <= l_end_utc
                           and end_date > l_start_utc
                       )
            loop
               open c for
                  'select distinct
                          tsv.ts_code
                     from '||rec.table_name||' tsv,
                          at_cwms_ts_id tsid,
                          cwms_office o
                    where o.office_id like :office
                      and tsid.db_office_code = o.office_code
                      and tsv.ts_code = tsid.ts_code
                      and tsv.date_time between :begin and :end
                      and tsid.net_ts_active_flag = ''T'''
                  using l_office_id, l_start_utc, l_end_utc;
               fetch c bulk collect into l_codes1;
               close c;
               select column_value
                 bulk collect
                 into l_codes2
                 from (select column_value from table(l_codes1));
            end loop;

            l_unique_tsid_count := l_codes2.count;

            if l_only_cwms_names then
               select distinct
                      ts_code,
                      db_office_id,
                      cwms_ts_id
                 bulk collect
                 into l_tsids(1)
                 from av_cwms_ts_id2 ts
                where ts_code in (select * from table(l_codes2))
                  and aliased_item is null
                order by db_office_id, cwms_ts_id;
            else
            select distinct
                   ts_code,
                   db_office_id,
                   cwms_ts_id
              bulk collect
              into l_tsids(1)
              from av_cwms_ts_id2 ts
             where ts_code in (select * from table(l_codes2))
             order by db_office_id, cwms_ts_id;
            end if;

            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
            l_tsid_count := l_tsids(1).count;

            if l_only_cwms_names then
               for i in 1..l_tsids(1).count loop
                  select distinct
                         cwms_ts_id
                    bulk collect
                    into l_tsids2(l_tsids(1)(i).ts_code)
                    from av_cwms_ts_id2
                   where ts_code = l_tsids(1)(i).ts_code
                     and aliased_item in ('BASE LOCATION', 'LOCATION');
               end loop;
            else
            for i in 1..l_tsids(1).count loop
               if not l_tsids2.exists(l_tsids(1)(i).ts_code) then
                  l_tsids2(l_tsids(1)(i).ts_code) := str_tab_t();
               end if;
               l_tsids2(l_tsids(1)(i).ts_code).extend;
               l_tsids2(l_tsids(1)(i).ts_code)(l_tsids2(l_tsids(1)(i).ts_code).count) := l_tsids(1)(i).name;
            end loop;
            end if;

            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
            l_ts1 := systimestamp;

            case
            when l_format = 'XML' then
               -----------------
               -- XML Catalog --
               -----------------
               cwms_util.append(
                  l_data,
                  '<?xml version="1.0" encoding="windows-1252"?><time-series-catalog><!-- Catalog of time series that contain data between '
                  ||cwms_util.get_xml_time(l_start, l_timezone)
                  ||' and '
                  ||cwms_util.get_xml_time(l_end, l_timezone)
                  ||' -->');
               for i in 1..l_tsids(1).count loop
                  cwms_util.append(
                     l_data,
                     '<time-series><office>'
                     ||l_tsids(1)(i).office
                     ||'</office><name>'
                     ||dbms_xmlgen.convert(l_tsids(1)(i).name, dbms_xmlgen.entity_encode)
                     ||'</name><alternate-names>');
                  for j in 1..l_tsids2(l_tsids(1)(i).ts_code).count loop
                     if l_tsids2(l_tsids(1)(i).ts_code)(j) != l_tsids(1)(i).name then
                        cwms_util.append(
                           l_data,
                           '<name>'
                           ||dbms_xmlgen.convert(l_tsids2(l_tsids(1)(i).ts_code)(j), dbms_xmlgen.entity_encode)
                           ||'</name>');
                     end if;
                  end loop;
                  cwms_util.append(l_data, '</alternate-names></time-series>');
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
               cwms_util.append(l_data, '</time-series-catalog>');
            when l_format = 'JSON' then
               ------------------
               -- JSON catalog --
               ------------------
               cwms_util.append(
                  l_data,
                  '{"time-series-catalog":{"comment":"Catalog of time series that contain data between '
                  ||cwms_util.get_xml_time(l_start, l_timezone)
                  ||' and '
                  ||cwms_util.get_xml_time(l_end, l_timezone)
                  ||'","time-series":[');
               for i in 1..l_tsids(1).count loop
                  l_text := case i when 1 then '{"office":"' else ',{"office":"' end
                     ||l_tsids(1)(i).office
                     ||'","name":"'
                     ||replace(l_tsids(1)(i).name, '"', '\"')
                     ||'","alternate-names":[';
                  l_first := true;
                  for j in 1..l_tsids2(l_tsids(1)(i).ts_code).count loop
                     if l_tsids2(l_tsids(1)(i).ts_code)(j) != l_tsids(1)(i).name then
                        case l_first
                        when true then
                           l_first := false;
                           l_text := l_text ||'"'||replace(l_tsids2(l_tsids(1)(i).ts_code)(j), '"', '\"')||'"';
                        else
                           l_text := l_text ||',"'||replace(l_tsids2(l_tsids(1)(i).ts_code)(j), '"', '\"')||'"';
                        end case;
                     end if;
                  end loop;
                  cwms_util.append(l_data, l_text||']}');
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
               cwms_util.append(l_data, ']}}');
            when l_format in ('TAB', 'CSV') then
               ------------------------
               -- TAB or CSV catalog --
               ------------------------
               cwms_util.append(
                  l_data,
                  '#Catalog of time series that contain data between '
                  ||to_char(l_start, 'dd-Mon-yyyy hh24:mi')
                  ||' and '
                  ||to_char(l_end, 'dd-Mon-yyyy hh24:mi')
                  ||' ('
                  ||l_timezone
                  ||')'
                  ||chr(10));
               cwms_util.append(l_data, '#Office'||chr(9)||'Name'||chr(9)||'Alternate Names'||chr(10));
               for i in 1..l_tsids(1).count loop
                  select column_value
                    bulk collect
                    into l_alternate_names
                    from table(l_tsids2(l_tsids(1)(i).ts_code))
                   where column_value != l_tsids(1)(i).name
                   order by 1;
                  cwms_util.append(
                     l_data,
                     l_tsids(1)(i).office
                     ||chr(9)
                     ||l_tsids(1)(i).name
                     ||chr(9)
                     ||cwms_util.join_text(l_alternate_names, chr(9))
                     ||chr(10));
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            else
               cwms_err.raise('ERROR', 'Unexpected format : '''||l_format||'''');
            end case;
            p_results := l_data;
            l_ts2 := systimestamp;
            l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
            l_ts1 := systimestamp;
         else
            ----------------------------------------------
            -- retrieve time series data in time window --
            ----------------------------------------------
            l_normalized_names := str_tab_t();
            l_normalized_names.extend(l_names.count);
            l_tsids.extend(l_names.count);
            <<names>>
            for i in 1..l_names.count loop
               l_normalized_names(i) := upper(cwms_util.normalize_wildcards(l_names(i)));
               for rec in (select table_name
                             from at_ts_table_properties
                            where start_date <= l_end_utc
                              and end_date > l_start_utc
                          )
               loop
                  open c for
                     'select distinct
                             tsv.ts_code
                        from '||rec.table_name||' tsv,
                             av_cwms_ts_id2 v
                       where v.db_office_id like :office
                         and upper(v.cwms_ts_id) like :name escape ''\''
                         and v.net_ts_active_flag = ''T''
                         and tsv.ts_code = v.ts_code
                         and tsv.date_time between :begin and :end'
                     using l_office_id, l_normalized_names(i), l_start_utc, l_end_utc;
                  fetch c bulk collect into l_codes1;
                  close c;
                  select column_value
                    bulk collect
                    into l_codes3
                    from (select column_value from table(l_codes1)
                          union
                          select column_value from table(l_codes2)
                         );
                  l_codes2 := l_codes3;
               end loop;
               if l_only_cwms_names then
                  select distinct
                         ts_code,
                         db_office_id,
                         cwms_ts_id
                    bulk collect
                    into l_tsids(i)
                    from av_cwms_ts_id2
                   where ts_code in (select column_value from table(l_codes2))
                     and upper(cwms_ts_id) like l_normalized_names(i) escape '\'
                     and aliased_item is null;
               else
               select distinct
                      ts_code,
                      db_office_id,
                      cwms_ts_id
                 bulk collect
                 into l_tsids(i)
                 from av_cwms_ts_id2
                where ts_code in (select column_value from table(l_codes2))
                  and upper(cwms_ts_id) like l_normalized_names(i) escape '\';
               end if;
               l_tsid_count := l_tsid_count + l_tsids(i).count;
               l_ts2 := systimestamp;
               l_elapsed_query := l_ts2 - l_ts1;
               if l_elapsed_query > l_max_time then
                  cwms_err.raise('ERROR', l_max_time_msg);
               end if;
            end loop names;
            l_unique_tsid_count := least(l_codes2.count, l_tsid_count);

            for i in 1..l_tsids.count loop
               for j in 1..l_tsids(i).count loop
                  l_text := l_tsids(i)(j).office||'/'||l_tsids(i)(j).name;
                  l_indexes(l_text).i := i;
                  l_indexes(l_text).j := j;
               end loop;
            end loop;

            l_text := l_indexes.first;
            <<tsids>>
            loop
               exit when l_text is null;
               l_intvl_str := cwms_util.split_text(l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name, 4, '.');
               l_intvl := cwms_ts.get_interval(l_intvl_str);
               if l_format not in ('TAB', 'CSV') then
                  case
                  when l_intvl  = 5256000 then l_intvl_str := 'P10Y';
                  when l_intvl >= 525600  then l_intvl_str := 'P' ||(l_intvl/525600)||'Y';
                  when l_intvl >= 43200   then l_intvl_str := 'P' ||(l_intvl/43200) ||'M';
                  when l_intvl >= 1440    then l_intvl_str := 'P' ||(l_intvl/1440)  ||'D';
                  when l_intvl >= 60      then l_intvl_str := 'PT'||(l_intvl/60)    ||'H';
                  else                         l_intvl_str := 'PT'||(l_intvl)       ||'M';
                  end case;
               end if;
               l_code := l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).ts_code;
               select distinct
                      cwms_ts_id
                 bulk collect
                 into l_alternate_names
                 from av_cwms_ts_id2
                where ts_code = l_code
                  and cwms_ts_id != l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name
                order by 1;
               l_code_str := to_char(l_code);
               if not l_values_by_code.exists(l_code_str) then
                  declare
                     l_errmsg       varchar2(32767);
                     l_native_datum varchar2(32);
                     l_unit_spec    varchar2(64);
                     l_xml          xmltype;
                  begin
                     --------------------------------
                     -- get the actual unit to use --
                     --------------------------------
                     l_parts := cwms_util.split_text(l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name, '.');
                     if l_units(l_indexes(l_text).i) in ('EN', 'SI') then
                        l_unit := cwms_util.get_default_units(l_parts(2), l_units(l_indexes(l_text).i));
                     else
                        l_unit := l_units(l_indexes(l_text).i);
                        declare
                           l_converted binary_double;
                        begin
                           l_converted := cwms_util.convert_units(1, cwms_util.get_default_units(l_parts(2)), l_unit);
                        exception
                           when others then
                              cwms_err.raise('ERROR', 'Unit "'||l_unit||'" is not valid for parameter "'||l_parts(2)||'"');
                        end;
                     end if;
                     ---------------------------------
                     -- get the acutal datum to use --
                     ---------------------------------
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_is_elev := true;
                        l_datum := upper(l_datums(l_indexes(l_text).i));
                        l_xml := xmltype(cwms_loc.get_vertical_datum_info_f(l_parts(1), l_unit, l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office));
                        l_native_datum := cwms_util.get_xml_text(l_xml, '/*/native-datum');
                        if l_native_datum not in ('NAVD-88', 'NGVD-29') then
                           l_native_datum := cwms_loc.get_local_vert_datum_name_f(l_parts(1), l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office);
                        end if;
                        case
                        when l_datum = 'NATIVE' then
                           l_unit_spec := l_unit;
                           l_estimated := false;
                           l_datum := nvl(replace(l_native_datum, '-', null), 'Unknown');
                        when l_datum = replace(l_native_datum, '-', null) then
                           l_unit_spec := l_unit;
                           l_estimated := false;
                        else
                           l_xml := cwms_util.get_xml_node(l_xml, '/*/offset[to-datum='''||substr(l_datum, 1, 4)||'-'||substr(l_datum, 5)||''']');
                           if l_xml is null then
                              cwms_err.raise('ERROR', 'Location '||l_parts(1)||' does not currently support vertical datum '||l_datum);
                           end if;
                           l_estimated := cwms_util.get_xml_text(l_xml, '/*/@estimate') = 'true';
                           l_unit_spec := 'U='||l_unit||'|V='||l_datum;
                        end case;
                     else
                        l_is_elev   := false;
                        l_unit_spec := l_unit;
                        l_estimated := false;
                     end if;
                     retrieve_ts (
                        p_at_tsv_rc         => c,
                        p_cwms_ts_id        => l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name,
                        p_units             => l_unit_spec,
                        p_start_time        => l_start,
                        p_end_time          => l_end,
                        p_time_zone         => l_timezone,
                        p_trim              => 'T',
                        p_start_inclusive   => 'T',
                        p_end_inclusive     => 'T',
                        p_previous          => 'F',
                        p_next              => 'F',
                        p_version_date      => NULL,
                        p_max_version       => 'T',
                        p_office_id         => l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office);

                     fetch c bulk collect into l_values_by_code(l_code_str);
                     close c;
                  exception
                     when others then
                        l_ts2 := systimestamp;
                        l_elapsed_query := l_elapsed_query + l_ts2 - l_ts1;
                        l_ts1 := systimestamp;
                        l_errmsg := regexp_replace(cwms_util.split_text(sqlerrm, 1, chr(10)), '^\w{3}-\d{5}: ', null);
                        if l_text = l_indexes.first then
                           case
                           when l_format = 'XML' then
                              ----------------
                              -- XML Header --
                              ----------------
                              cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><time-series>!!Quality Codes!!');
                           when l_format = 'JSON' then
                              -----------------
                              -- JSON Header --
                              -----------------
                              cwms_util.append(l_data, '{"time-series":!!Quality Codes!!{"time-series":[');
                           when l_format in ('TAB', 'CSV') then
                              -----------------------
                              -- TAB or CSV Header --
                              -----------------------
                              cwms_util.append(l_data, '!!Quality Codes!!');
                           else
                              cwms_err.raise('ERROR', 'Unexpected format : '''||l_format||'''');
                           end case;
                        end if;
                        case
                        when l_format = 'XML' then
                           ---------------
                           -- XML Error --
                           ---------------
                           cwms_util.append(
                              l_data,
                              '<?xml version="1.0" encoding="windows-1252"?><time-series><office>'
                              ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office
                              ||'</office><name>'
                              ||dbms_xmlgen.convert(l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name, dbms_xmlgen.entity_encode)
                              ||'</name><alternate-names>');
                           for i in 1..l_alternate_names.count loop
                              cwms_util.append(
                                 l_data,
                                 '<name>'
                                 ||dbms_xmlgen.convert(l_alternate_names(i), dbms_xmlgen.entity_encode)
                                 ||'</name>');
                           end loop;
                           cwms_util.append(
                              l_data,
                              '</alternate-names><error>'
                              ||dbms_xmlgen.convert(l_errmsg, dbms_xmlgen.entity_encode)
                              ||'</error></time-series>');
                        when l_format = 'JSON' then
                           ----------------
                           -- JSON Error --
                           ----------------
                           cwms_util.append(
                              l_data,
                              case l_text = l_indexes.first
                              when true then '{"office":"'
                              else ',{"office":"'
                              end
                              ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office
                              ||'","name":"'
                              ||replace(l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name, '"', '\"')
                              ||'","alternate-names":[');
                           for i in 1..l_alternate_names.count loop
                              cwms_util.append(
                                 l_data,
                                 case i when 1 then '"' else ',"' end
                                 ||replace(l_alternate_names(i), '"', '\"')
                                 ||'"');
                           end loop;
                           cwms_util.append(
                              l_data,
                              '],"error":"'
                              ||replace(l_errmsg, '"', '\"')
                              ||'"}');
                        when l_format in ('TAB', 'CSV') then
                           ----------------------
                           -- TAB or CSV Error --
                           ----------------------
                           cwms_util.append(
                              l_data,
                              chr(10)
                              ||'#Office = '
                              ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office
                              ||chr(9)
                              ||'Name = '
                              ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name
                              ||chr(9)
                              ||'Interval = '
                              ||case
                                when l_intvl = 0 then 'Irregular'
                                else l_intvl_str
                                end
                              ||chr(9)
                              ||'Time Zone = '
                              ||l_timezone
                              ||chr(9)
                              ||'Unit = '
                              ||l_unit
                              ||case
                                when l_is_elev then
                                   ' '
                                   ||l_datum
                                   ||case l_estimated
                                     when true then ' estimated'
                                     else null
                                     end
                                else null
                                end
                              ||chr(9)
                              ||'Alternate Names = '
                              ||cwms_util.join_text(l_alternate_names, chr(9))
                              ||chr(10)
                              ||'#Error'
                              ||chr(9)
                              ||l_errmsg
                              ||chr(10));
                        else
                           cwms_err.raise('ERROR', 'Unexpected format : '''||l_format||'''');
                        end case;
                        l_ts2 := systimestamp;
                        l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
                        l_ts1 := systimestamp;
                        l_text := l_indexes.next(l_text);
                        continue tsids;
                  end;
                  l_unique_value_count := l_unique_value_count + l_values_by_code(l_code_str).count;
               end if;
               l_value_count := l_value_count + l_values_by_code(l_code_str).count;

               l_ts2 := systimestamp;
               l_elapsed_query := l_elapsed_query + l_ts2 - l_ts1;
               if l_elapsed_query > l_max_time then
                  cwms_err.raise('ERROR', l_max_time_msg);
               end if;
               l_ts1 := systimestamp;
               if l_intvl = 0 then
                  for i in 1..l_values_by_code(l_code_str).count loop
                     if l_values_by_code(l_code_str)(i).quality_code > 2147483647 then
                        l_values_by_code(l_code_str)(i).quality_code := l_tsv(i).quality_code - 4294967296;
                     end if;
                     l_quality_used(to_char(l_values_by_code(l_code_str)(i).quality_code)) := true;
                  end loop;
               else
                  l_segments := seg_tab_t();
                  for i in 1..l_values_by_code(l_code_str).count loop
                     if l_segments.count > 1 and l_segments(l_segments.count-1).last_index is null then
                        l_segments(l_segments.count-1).last_index := i-1;
                        l_segments(l_segments.count-1).end_time := l_values_by_code(l_code_str)(i-1).date_time;
                     end if;
                     if l_values_by_code(l_code_str)(i).value is null then
                        continue;
                     end if;
                     if l_values_by_code(l_code_str)(i).quality_code > 2147483647 then
                        l_values_by_code(l_code_str)(i).quality_code := l_values_by_code(l_code_str)(i).quality_code - 4294967296;
                     end if;
                     l_quality_used(to_char(l_values_by_code(l_code_str)(i).quality_code)) := true;
                     if i = 1 or l_values_by_code(l_code_str)(i-1).value is null then
                        l_segments.extend;
                        if l_segments.count > 1 then
                           l_segments(l_segments.count-1).last_index  := l_last_non_null;
                           l_segments(l_segments.count-1).end_time    := l_values_by_code(l_code_str)(l_last_non_null).date_time;
                        end if;
                        l_segments(l_segments.count).start_time  := l_values_by_code(l_code_str)(i).date_time;
                        l_segments(l_segments.count).end_time    := null;
                        l_segments(l_segments.count).first_index := i;
                        l_segments(l_segments.count).last_index  := null;
                     end if;
                     l_last_non_null := i;
                  end loop;
                  if l_segments.count > 0 and l_segments(l_segments.count).last_index is null then
                     l_segments(l_segments.count).last_index := l_values_by_code(l_code_str).count;
                     l_segments(l_segments.count).end_time := l_values_by_code(l_code_str)(l_values_by_code(l_code_str).count).date_time;
                  end if;
               end if;
               if l_text = l_indexes.first then
                  case
                  when l_format = 'XML' then
                     ----------------
                     -- XML Header --
                     ----------------
                     cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><time-series>!!Quality Codes!!');
                  when l_format = 'JSON' then
                     -----------------
                     -- JSON Header --
                     -----------------
                     cwms_util.append(l_data, '{"time-series":!!Quality Codes!!{"time-series":[');
                  when l_format in ('TAB', 'CSV') then
                     -----------------------
                     -- TAB or CSV Header --
                     -----------------------
                     cwms_util.append(l_data, '!!Quality Codes!!');
                  end case;
               end if;
               case
               when l_format = 'XML' then
                  --------------
                  -- XML DATA --
                  --------------
                  cwms_util.append(
                     l_data,
                     '<time-series><office>'
                     ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office
                     ||'</office><name>'
                     ||dbms_xmlgen.convert(l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name, dbms_xmlgen.entity_encode)
                     ||'</name><alternate-names>');
                  for i in 1..l_alternate_names.count loop
                     cwms_util.append(
                        l_data,
                        '<name>'
                        ||dbms_xmlgen.convert(l_alternate_names(i), dbms_xmlgen.entity_encode)
                        ||'</name>');
                  end loop;
                  cwms_util.append(l_data, '</alternate-names>');
                  if l_intvl = 0 then
                     cwms_util.append(
                        l_data, '<irregular-interval-values unit="'
                        ||l_unit
                        ||case l_is_elev
                          when true then
                             ' '
                             ||l_datum
                             ||case l_estimated
                                when true then ' estimated'
                                else null
                                end
                          else null
                          end
                        ||'" first-time="'
                        ||cwms_util.get_xml_time(l_values_by_code(l_code_str)(1).date_time, l_timezone)
                        ||'" last-time="'
                        ||cwms_util.get_xml_time(l_values_by_code(l_code_str)(l_values_by_code(l_code_str).count).date_time, l_timezone)
                        ||'" value-count="'
                        ||l_values_by_code(l_code_str).count
                        ||'"><!-- date-time value quality-code -->'
                        ||chr(10));
                     for i in 1..l_values_by_code(l_code_str).count loop
                        continue when l_values_by_code(l_code_str)(i).date_time is null;
                        cwms_util.append(
                           l_data,
                           cwms_util.get_xml_time(l_values_by_code(l_code_str)(i).date_time, l_timezone)
                           ||' '
                           ||nvl(cwms_rounding.round_dt_f(l_values_by_code(l_code_str)(i).value, '7777777777'), 'null')
                           ||' '
                           ||l_values_by_code(l_code_str)(i).quality_code
                           ||chr(10));
                     end loop;
                     cwms_util.append(l_data, chr(10)||'</irregular-interval-values></time-series>');
                  else
                     cwms_util.append(
                        l_data,
                        '<regular-interval-values interval="'
                        ||l_intvl_str
                        ||'" unit="'
                        ||l_unit
                        ||case l_is_elev
                          when true then
                             ' '
                             ||l_datum
                             ||case l_estimated
                                when true then ' estimated'
                                else null
                                end
                          else null
                          end
                        ||'" segment-count="'
                        ||l_segments.count
                        ||'">'
                        ||chr(10));
                     for i in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           '<segment position="'
                           ||i
                           ||'" first-time="'
                           ||cwms_util.get_xml_time(l_segments(i).start_time, l_timezone)
                           ||'" last-time="'
                           ||cwms_util.get_xml_time(l_segments(i).end_time, l_timezone)
                           ||'" value-count="'
                           ||(l_segments(i).last_index - l_segments(i).first_index + 1)
                           ||'"><!-- value quality-code -->'
                           ||chr(10));
                        for j in l_segments(i).first_index..l_segments(i).last_index loop
                           cwms_util.append(
                              l_data,
                              cwms_rounding.round_dt_f(l_values_by_code(l_code_str)(j).value, '7777777777')
                              ||' '
                              ||l_values_by_code(l_code_str)(j).quality_code
                              ||chr(10));
                        end loop;
                        cwms_util.append(l_data, '</segment>');
                     end loop;
                     cwms_util.append(l_data, chr(10)||'</regular-interval-values></time-series>');
                  end if;
               when l_format = 'JSON' then
                  ---------------
                  -- JSON DATA --
                  ---------------
                  cwms_util.append(
                     l_data,
                     case l_text = l_indexes.first
                     when true then '{"office":"'
                     else ',{"office":"'
                     end
                     ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office
                     ||'","name":"'
                     ||replace(l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name, '"', '\"')
                     ||'","alternate-names":[');
                  for i in 1..l_alternate_names.count loop
                     cwms_util.append(
                        l_data,
                        case i
                        when 1 then '"'
                        else ',"'
                        end
                        ||replace(l_alternate_names(i), '"', '\"')
                        ||'"');
                  end loop;
                  cwms_util.append(l_data, ']');
                  if l_intvl = 0 then
                     cwms_util.append(
                        l_data,
                        ',"irregular-interval-values":{"unit":"'
                        ||l_unit
                        ||case l_is_elev
                          when true then
                             ' '
                             ||l_datum
                             ||case l_estimated
                                when true then ' estimated'
                                else null
                                end
                          else null
                          end
                        ||'","comment":"time, value, quality code","values":[');
                     for i in 1..l_values_by_code(l_code_str).count loop
                        continue when l_values_by_code(l_code_str)(i).date_time is null;
                        cwms_util.append(
                           l_data,
                           case when i = 1 then '["' else ',["' end
                           ||cwms_util.get_xml_time(l_values_by_code(l_code_str)(i).date_time, l_timezone)
                           ||'",'
                           ||regexp_replace(nvl(cwms_rounding.round_dt_f(l_values_by_code(l_code_str)(i).value, '7777777777'), 'null'), '(^|[^0-9])\.', '\10.')
                           ||','
                           ||l_values_by_code(l_code_str)(i).quality_code
                           ||']');
                     end loop;
                     cwms_util.append(l_data, ']}}');
                  else
                     cwms_util.append(
                        l_data,
                        ',"regular-interval-values":{"interval":"'
                        ||l_intvl_str
                        ||'","unit":"'
                        ||l_unit
                        ||case l_is_elev
                          when true then
                             ' '
                             ||l_datum
                             ||case l_estimated
                                when true then ' estimated'
                                else null
                                end
                          else null
                          end
                        ||'","segment-count":'
                        ||l_segments.count
                        ||',"segments":[');
                     for i in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           case
                           when i = 1 then '{"first-time":"'
                           else ',{"first-time":"'
                           end
                           ||cwms_util.get_xml_time(l_segments(i).start_time, l_timezone)
                           ||'","last-time":"'
                           ||cwms_util.get_xml_time(l_segments(i).end_time, l_timezone)
                           ||'","value-count":'
                           ||(l_segments(i).last_index - l_segments(i).first_index + 1)
                           ||',"comment":"value, quality code","values":[');
                        for j in l_segments(i).first_index..l_segments(i).last_index loop
                           cwms_util.append(
                              l_data,
                              case
                              when j = l_segments(i).first_index then '['
                              else ',['
                              end
                              ||regexp_replace(cwms_rounding.round_dt_f(l_values_by_code(l_code_str)(j).value, '7777777777'), '^\.', '0.', 1, 1)
                              ||','
                              ||l_values_by_code(l_code_str)(j).quality_code
                              ||']');
                        end loop;
                        cwms_util.append(l_data, ']}');
                     end loop;
                     cwms_util.append(l_data, ']}}');
                  end if;
               when l_format in ('TAB', 'CSV') then
                  ---------------------
                  -- TAB or CSV DATA --
                  ---------------------
                  cwms_util.append(
                     l_data,
                     chr(10)
                     ||'#Office = '
                     ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).office
                     ||chr(9)
                     ||'Name = '
                     ||l_tsids(l_indexes(l_text).i)(l_indexes(l_text).j).name
                     ||chr(9)
                     ||'Interval = '
                     ||case
                       when l_intvl = 0 then 'Irregular'
                       else l_intvl_str
                       end
                     ||chr(9)
                     ||'Time Zone = '
                     ||l_timezone
                     ||chr(9)
                     ||'Unit = '
                     ||l_unit
                     ||case
                       when l_is_elev then
                          ' '
                          ||l_datum
                          ||case l_estimated
                            when true then
                               ' estimated'
                            else
                               null
                            end
                       else
                          null
                       end
                     ||chr(9)
                     ||'Alternate Names = '
                     ||cwms_util.join_text(l_alternate_names, chr(9))
                     ||chr(10));
                  if l_intvl = 0 then
                     --------------------------------
                     -- irregular time series data --
                     --------------------------------
                     cwms_util.append(
                        l_data,
                        '#Time'
                        ||chr(9)
                        ||'Value'
                        ||chr(9)
                        ||'Quality Code'
                        ||chr(10));
                     for i in 1..l_values_by_code(l_code_str).count loop
                        continue when l_values_by_code(l_code_str)(i).date_time is null;
                        cwms_util.append(
                           l_data,
                           to_char(l_values_by_code(l_code_str)(i).date_time, 'dd-Mon-yyyy hh24:mi')
                           ||chr(9)
                           ||nvl(cwms_rounding.round_dt_f(l_values_by_code(l_code_str)(i).value, '7777777777'), 'null')
                           ||chr(9)
                           ||l_values_by_code(l_code_str)(i).quality_code
                           ||chr(10));
                     end loop;
                  else
                     ------------------------------
                     -- regular time series data --
                     ------------------------------
                     for i in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           '#Segment '
                           ||i
                           ||' of '
                           ||l_segments.count
                           ||chr(9)
                           ||'First Time = '
                           ||to_char(l_segments(i).start_time, 'dd-Mon-yyyy hh24:mi')
                           ||chr(9)
                           ||'Last Time = '
                           ||to_char(l_segments(i).end_time, 'dd-Mon-yyyy hh24:mi')
                           ||chr(9)
                           ||'Count = '
                           ||(l_segments(i).last_index - l_segments(i).first_index + 1)
                           ||chr(10)
                           ||'#Value'
                           ||chr(9)
                           ||'Quality Code'
                           ||chr(10));
                        for j in l_segments(i).first_index..l_segments(i).last_index loop
                           cwms_util.append(
                              l_data,
                              cwms_rounding.round_dt_f(l_values_by_code(l_code_str)(j).value, '7777777777')
                              ||chr(9)
                              ||l_values_by_code(l_code_str)(j).quality_code
                              ||chr(10));
                        end loop;
                     end loop;
                  end if;
               end case;
               l_ts2 := systimestamp;
               l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
               l_ts1 := systimestamp;
               l_text := l_indexes.next(l_text);
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop tsids;
         end if;
         ---------------------------------------
         -- get the quality code descriptions --
         ---------------------------------------
         l_codes1 := number_tab_t();
         l_codes1.extend(l_quality_used.count);
         for i in 1..l_quality_used.count loop
            case
            when i = 1 then l_codes1(i) := to_number(l_quality_used.first);
            else l_codes1(i) := to_number(l_quality_used.next(l_codes1(i-1)));
            end case;
         end loop;
         select qcode
           bulk collect
           into l_codes2
           from (select case
                        when column_value >= 0 then column_value
                        else column_value + 4294967296
                        end as qcode
                   from table(l_codes1)
                );
          select cwms_ts.get_quality_description(column_value)
           bulk collect
           into l_lines
           from table(l_codes2);
         l_ts2 := systimestamp;
         l_elapsed_query := l_elapsed_query + l_ts2 - l_ts1;
         l_ts1 := systimestamp;
         case
         when l_format = 'XML' then
            ----------------
            -- XML Wrapup --
            ----------------
            if l_names is not null then
               l_text := '<quality-codes><!-- The following quality codes are used in this dataset-->';
               for i in 1..l_lines.count loop
                  l_text := l_text
                     ||'<code value="'
                     ||l_codes1(i)
                     ||'" meaning="'
                     ||l_lines(i)
                     ||'"/>';
               end loop;
               l_text := l_text||'</quality-codes>';
               l_data := replace(l_data, '!!Quality Codes!!', l_text);
               if dbms_lob.getlength(l_data) = 0 then
                  cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><time-series>');
               end if;
               cwms_util.append(l_data, '</time-series>');
            end if;
         when l_format = 'JSON' then
            -----------------
            -- JSON Wrapup --
            -----------------
            l_text := '{"quality-codes":{"comment":"The following quality codes are used in this dataset","codes":[';
            for i in 1..l_lines.count loop
               l_text := l_text
                  ||case when i = 1 then '{' else ',{' end
                  ||'"code":'
                  ||l_codes1(i)
                  ||',"meaning":"'
                  ||l_lines(i)
                  ||'"}';
            end loop;
            l_text := l_text||']},';
            l_data := replace(l_data, '!!Quality Codes!!{', l_text);
            if l_names is not null then
               if dbms_lob.getlength(l_data) = 0 then
                  cwms_util.append(l_data, '{"time-series":{"time-series":[');
               end if;
               cwms_util.append(l_data, ']}}');
            end if;
         when l_format in ('TAB', 'CSV') then
            l_text := '#Quality Codes Used';
            for i in 1..l_lines.count loop
               l_text := l_text||chr(9)||l_codes1(i)||' = '||l_lines(i);
            end loop;
            l_text := l_text||chr(10);
            l_data := replace(l_data, '!!Quality Codes!!', l_text);
            -----------------------
            -- TAB or CSV Wrapup --
            -----------------------
            if l_format = 'CSV' then
               ----------------
               -- CSV Wrapup --
               ----------------
               l_data := cwms_util.tab_to_csv(l_data);
            end if;
         end case;

         l_ts2 := systimestamp;
         l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;

      exception
         when others then
            case
            when instr(sqlerrm, l_max_time_msg) > 0 then
               dbms_lob.createtemporary(l_data, true);
               case l_format
               when  'XML' then
                  if l_names is null then
                     cwms_util.append(l_data, '<time-series-catalog><error>Query exceeded maximum time of '||l_max_time||'</error></time-series-catalog>');
                  else
                     cwms_util.append(l_data, '<time-series><error>Query exceeded maximum time of '||l_max_time||'</error></time-series>');
                  end if;
               when 'JSON' then
                  if l_names is null then
                     cwms_util.append(l_data, '{"time-series-catalog":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
                  else
                     cwms_util.append(l_data, '{"time-series":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
                  end if;
               when 'TAB' then
                  cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum time of '||l_max_time||chr(10));
               when 'CSV' then
                  cwms_util.append(l_data, 'ERROR,Query exceeded maximum time of '||l_max_time||chr(10));
               end case;
            when instr(sqlerrm, l_max_size_msg) > 0 then
               dbms_lob.createtemporary(l_data, true);
               case l_format
               when  'XML' then
                  if l_names is null then
                     cwms_util.append(l_data, '<time-series-catalog><error>Query exceeded maximum size of '||l_max_size||' characters</error></time-series-catalog>');
                  else
                     cwms_util.append(l_data, '<time-series><error>Query exceeded maximum size of '||l_max_size||' characters</error></time-series>');
                  end if;
               when 'JSON' then
                  if l_names is null then
                     cwms_util.append(l_data, '{"time-series-catalog":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
                  else
                     cwms_util.append(l_data, '{"time-series":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
                  end if;
               when 'TAB' then
                  cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
               when 'CSV' then
                  cwms_util.append(l_data, 'ERROR,Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
               end case;
            else raise;
            end case;
      end;

      declare
         l_data2 clob;
      begin
         dbms_lob.createtemporary(l_data2, true);
         l_name := cwms_util.get_db_name;
         case
         when l_format = 'XML' then
            ---------
            -- XML --
            ---------
            cwms_util.append(
               l_data2,
               '<query-info><processed-at>'
               ||utl_inaddr.get_host_name
               ||':'
               ||l_name
               ||'</processed-at><time-of-query>'
               ||cwms_util.get_xml_time(l_query_time, 'UTC')
               ||'</time-of-query><process-query>'
               ||iso_duration(l_elapsed_query)
               ||'</process-query><format-output>'
               ||iso_duration(l_elapsed_format)
               ||'</format-output><requested-start-time>'
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||'</requested-start-time><requested-end-time>'
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||'</requested-end-time><requested-format>'
               ||l_format
               ||'</requested-format><requested-office>'
               ||l_office_id
               ||'</requested-office>');
            if l_names is null then
               cwms_util.append(
                  l_data2,
                  '<total-time-series-cataloged>'
                  ||l_tsid_count
                  ||'</total-time-series-cataloged><unique-time-series-cataloged>'
                  ||l_unique_tsid_count
                  ||'</unique-time-series-cataloged></query-info>');
            else
               for i in 1..l_names.count loop
                  cwms_util.append(
                     l_data2,
                     '<requested-item><name>'
                     ||l_names(i)
                     ||'</name><unit>'
                     ||l_units(i)
                     ||'</unit><datum>'
                     ||l_datums(i)
                     ||'</datum></requested-item>');
               end loop;
               cwms_util.append(
                  l_data2,
                  '<total-time-series-retrieved>'
                  ||l_tsid_count
                  ||'</total-time-series-retrieved><unique-time-series-retrieved>'
                  ||l_unique_tsid_count
                  ||'</unique-time-series-retrieved><total-values-retrieved>'
                  ||l_value_count
                  ||'</total-values-retrieved><unique-values-retrieved>'
                  ||l_unique_value_count
                  ||'</unique-values-retrieved></query-info>');
            end if;
				l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<time-series.*?>))', '\1'||l_data2, 1, 1);
            p_results := l_data;
         when l_format = 'JSON' then
            ----------
            -- JSON --
            ----------
            cwms_util.append(
               l_data2,
               '{"query-info":{"processed-at":"'
               ||utl_inaddr.get_host_name
               ||':'
               ||l_name
               ||'","time-of-query":"'
               ||cwms_util.get_xml_time(l_query_time, 'UTC')
               ||'","process-query":"'
               ||iso_duration(l_elapsed_query)
               ||'","format-output":"'
               ||iso_duration(l_elapsed_format)
               ||'","requested-start-time":"'
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||'","requested-end-time":"'
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||'","requested-format":"'
               ||l_format
               ||'","requested-office":"'
               ||l_office_id
               ||'"');
            if l_names is null then
               cwms_util.append(
                  l_data2,
                  ',"total-time-series-cataloged":'
                  ||l_tsid_count
                  ||',"unique-time-series-cataloged":'
                  ||l_unique_tsid_count
                  ||'}');
            else
               cwms_util.append(l_data2, ',"requested-items":[');
               for i in 1..l_names.count loop
                  cwms_util.append(
                     l_data2,
                     case
                     when i = 1 then '{"name":"'
                     else ',{"name":"'
                     end
                     ||l_names(i)
                     ||'","unit":"'
                     ||l_units(i)
                     ||'","datum":"'
                     ||l_datums(i)
                     ||'"}');
               end loop;
               cwms_util.append(
                  l_data2,
                  '],"total-time-series-retrieved":'
                  ||l_tsid_count
                  ||',"unique-time-series-retrieved":'
                  ||l_unique_tsid_count
                  ||',"total-values-retrieved":'
                  ||l_value_count
                  ||',"unique-values-retrieved":'
                  ||l_unique_value_count
                  ||'}');
            end if;
            l_data := regexp_replace(l_data, '^({"time-series.*?":){', '\1'||l_data2||',', 1, 1);
            p_results := l_data;
         when l_format in ('TAB', 'CSV') then
            ----------------
            -- TAB or CSV --
            ----------------
            l_name := cwms_util.get_db_name;
            cwms_util.append(l_data2, '#Processed At'||chr(9)||utl_inaddr.get_host_name ||':'||l_name||chr(10));
            cwms_util.append(l_data2, '#Time of Query'||chr(9)||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||chr(10));
            cwms_util.append(l_data2, '#Process Query'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' milliseconds'||chr(10));
            cwms_util.append(l_data2, '#Format Output'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' milliseconds'||chr(10));
            cwms_util.append(l_data2, '#Requested Start Time'||chr(9)||to_char(l_start, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
            cwms_util.append(l_data2, '#Requested End Time'||chr(9)||to_char(l_end, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
            cwms_util.append(l_data2, '#Requested Format'||chr(9)||l_format||chr(10));
            cwms_util.append(l_data2, '#Requested Office'||chr(9)||l_office_id||chr(10));
            if l_names is null then
               cwms_util.append(l_data2, '#Total Time Series Cataloged'||chr(9)||l_tsid_count||chr(10));
               cwms_util.append(l_data2, '#Unique Time Series Cataloged'||chr(9)||l_unique_tsid_count||chr(10)||chr(10));
            else
               cwms_util.append(l_data2, '#Requested Names"'||chr(9)||cwms_util.join_text(l_names, chr(9))||chr(10));
               cwms_util.append(l_data2, '#Requested Units"'||chr(9)||cwms_util.join_text(l_units, chr(9))||chr(10));
               cwms_util.append(l_data2, '#Requested Datums"'||chr(9)||cwms_util.join_text(l_datums, chr(9))||chr(10));
               cwms_util.append(l_data2, '#Total Time Series Retrieved'||chr(9)||l_tsid_count||chr(10));
               cwms_util.append(l_data2, '#Unique Time Series Retrieved'||chr(9)||l_unique_tsid_count||chr(10));
               cwms_util.append(l_data2, '#Total Values Retrieved'||chr(9)||l_value_count||chr(10));
               cwms_util.append(l_data2, '#Unique Values Retrieved'||chr(9)||l_unique_value_count||chr(10)||chr(10));
            end if;
            if l_format = 'CSV' then
               l_data2 := cwms_util.tab_to_csv(l_data2);
            end if;
            cwms_util.append(l_data2, l_data);
            p_results := l_data2;
         end case;
      end;

      p_date_time   := l_query_time;
      p_query_time  := trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)));
      p_format_time := trunc(1000 * (extract(minute from l_elapsed_format) *60 +  extract(second from l_elapsed_format)));
      p_ts_count    := l_tsids.count;
      p_value_count := l_value_count;
   end retrieve_time_series;

   function retrieve_time_series_f(
      p_names       in  varchar2,
      p_format      in  varchar2,
      p_units       in  varchar2 default null,
      p_datums      in  varchar2 default null,
      p_start       in  varchar2 default null,
      p_end         in  varchar2 default null,
      p_timezone    in  varchar2 default null,
      p_office_id   in  varchar2 default null)
      return clob
   is
      l_results        clob;
      l_date_time      date;
      l_query_time     integer;
      l_format_time    integer;
      l_ts_count       integer;
      l_value_count    integer;
   begin
      retrieve_time_series(
         l_results,
         l_date_time,
         l_query_time,
         l_format_time,
         l_ts_count,
         l_value_count,
         p_names,
         p_format,
         p_units,
         p_datums,
         p_start,
         p_end,
         p_timezone,
         p_office_id);

      return l_results;
   end retrieve_time_series_f;

   procedure truncate_ts_msg_archive_table
   is
      l_today            date;
      l_truncate_date    date;
      l_truncate_weekday integer;
      l_rowcount         integer;
   begin
      cwms_msg.log_db_message(cwms_msg.msg_level_normal, 'TRUNCATE_TS_MSG_ARCHIVE_TABLE Starting');
      -------------------------------
      -- weekdays are SUN=1..SAT=7 --
      -------------------------------
      l_today            := trunc(sysdate, 'DD');
      l_truncate_date    := add_months(trunc(l_today, 'MM'), 1) - 1; -- last day of this month
      l_truncate_weekday := to_char(l_truncate_date, 'D');
      --------------------------------
      -- only truncate on TUE..THUR --
      --------------------------------
      if l_truncate_weekday in (1, 2) then
         l_truncate_date := l_truncate_date - (l_truncate_weekday + 2);
      elsif l_truncate_weekday in (6,7) then
         l_truncate_date := l_truncate_date - (l_truncate_weekday - 5);
      end if;
      cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'Truncate date = '||to_char(l_truncate_date, 'yyyy-mm-dd'));
      ----------------------------------------------
      -- truncate the table if it's time to do so --
      ----------------------------------------------
      if l_today >= l_truncate_date then
         if mod(extract(month from l_today), 2) = 0 then
            ------------------------------------------
            -- even month, truncate odd month table --
            ------------------------------------------
            select count(*) into l_rowcount from at_ts_msg_archive_1;
            if l_rowcount > 0 then
               cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'Truncationg table AT_TS_MSG_ARCHIVE_1 ('||l_rowcount||' rows)');
               execute immediate 'truncate table at_ts_msg_archive_1 drop storage';
            else
               cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'Table AT_TS_MSG_ARCHIVE_1 already truncated');
            end if;
         else
            ------------------------------------------
            -- odd month, truncate even month table --
            ------------------------------------------
            select count(*) into l_rowcount from at_ts_msg_archive_2;
            if l_rowcount > 0 then
               cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'Truncationg table AT_TS_MSG_ARCHIVE_2 ('||l_rowcount||' rows)');
               execute immediate 'truncate table at_ts_msg_archive_2 drop storage';
            else
               cwms_msg.log_db_message(cwms_msg.msg_level_detailed, 'Table AT_TS_MSG_ARCHIVE_2 already truncated');
            end if;
         end if;
      end if;
      cwms_msg.log_db_message(cwms_msg.msg_level_normal, 'TRUNCATE_TS_MSG_ARCHIVE_TABLE Ending');
   end truncate_ts_msg_archive_table;

   procedure start_truncate_ts_msg_arch_job
   is
      l_job_name varchar2(30) := 'TRUNCATE_TS_MSG_ARCH_JOB';

      function job_count return pls_integer
      is
         l_count pls_integer;
      begin
         select count(*) into l_count from user_scheduler_jobs where job_name = l_job_name;
         return l_count;
      end job_count;
   begin
      ----------------------------------------
      -- only allow schema owner to execute --
      ----------------------------------------
      if cwms_util.get_user_id != '&cwms_schema' then
         cwms_err.raise('ERROR', 'Must be &cwms_schema user to start job '||l_job_name);
      end if;
      ----------------------------------------------
      -- allow only a single copy to be scheduled --
      ----------------------------------------------
      if job_count > 0 then
         cwms_err.raise('ERROR', 'Cannot start job '||l_job_name||',  another instance is already running');
      end if;
      ----------------------------------------------------------
      -- create the job to start immediately and never repeat --
      ----------------------------------------------------------
      dbms_scheduler.create_job (
         job_name            => l_job_name,
         job_type            => 'stored_procedure',
         job_action          => 'cwms_ts.truncate_ts_msg_archive_table',
         start_date          => sysdate,
         repeat_interval     => 'freq=hourly; interval=6',
         number_of_arguments => 0,
         comments            => 'Truncates AS_TS_MSG_ARCHIVE_X table that is not currently in use.');
      dbms_scheduler.enable(l_job_name);
      if job_count != 1 then
         cwms_err.raise('ERROR', 'Job '||l_job_name||' not started');
      end if;
   end start_truncate_ts_msg_arch_job;

   function package_log_property_text
      return varchar2
   is
   begin
      return v_package_log_prop_text;
   end package_log_property_text;

   procedure set_package_log_property_text(
      p_text in varchar2 default null)
   is
   begin
      v_package_log_prop_text := nvl(p_text, userenv('sessionid'));
   end set_package_log_property_text;

END cwms_ts;                                                --end package body
/

SHOW ERRORS;
commit;

