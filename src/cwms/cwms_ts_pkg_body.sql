CREATE OR REPLACE PACKAGE BODY cwms_ts AS

   function get_max_open_cursors return integer
   is
      l_max_open_cursors integer;
   begin
      select value into l_max_open_cursors from v$parameter where name = 'open_cursors';
      return l_max_open_cursors;
   end get_max_open_cursors;

 
    /* Formatted on 2007/06/25 10:58 (Formatter Plus v4.8.8) */
    FUNCTION get_ts_id (p_ts_code IN NUMBER)
       RETURN VARCHAR2
    IS
       l_cwms_ts_id   VARCHAR2 (183);
    BEGIN
       SELECT cwms_ts_id
         INTO l_cwms_ts_id
         FROM mv_cwms_ts_id
        WHERE ts_code = p_ts_code;
    END;
 --******************************************************************************/   
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_CWMS_TS_ID -
   --
   -- Simply returns the cwms_ts_id using the case stored in the database   --
   --
   FUNCTION get_cwms_ts_id (p_cwms_ts_id IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_cwms_ts_id   VARCHAR2 (183);
   BEGIN
      SELECT cwms_ts_id
        INTO l_cwms_ts_id
        FROM mv_cwms_ts_id mcti
       WHERE UPPER (mcti.cwms_ts_id) = UPPER (p_cwms_ts_id)
         AND UPPER (mcti.db_office_id) = UPPER (p_office_id);
   
      --
      RETURN l_cwms_ts_id;
   END;
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
                l_version_id
               );
   
      --
      SELECT unit_id
        INTO l_db_unit_id
        FROM cwms_unit cu, cwms_base_parameter cbp
       WHERE cu.unit_code = cbp.unit_code
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
    /* Formatted on 2007/07/24 16:01 (Formatter Plus v4.8.8) */
    FUNCTION get_time_on_after_interval (
       p_datetime      IN   DATE,
       p_ts_offset     IN   NUMBER,                                 -- in minutes.
       p_ts_interval   IN   NUMBER                                  -- in minutes.
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
       DBMS_APPLICATION_INFO.set_module ('create_ts',
                                         'Function get_Time_On_After_Interval'
                                        );

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
       l_normalized_datetime := TRUNC (p_datetime, 'MI') - (p_ts_offset / 1440);

       IF p_ts_interval = 1
       THEN
          NULL;                                               -- nothing to do...
       ELSIF l_ts_interval < 10080                -- intervals less than a week...
       THEN
          l_delta := (l_normalized_datetime - cwms_util.l_epoch) * 1440;
          l_mod := MOD (l_delta, l_ts_interval);

          IF l_mod <= 0
          THEN
             l_normalized_datetime := l_normalized_datetime - (l_mod / 1440);
          ELSE
             l_normalized_datetime :=
                            l_normalized_datetime
                            + (l_ts_interval - l_mod) / 1440;
          END IF;
       ELSIF l_ts_interval = 10080                           -- weekly interval...
       THEN
          l_delta := (l_normalized_datetime - cwms_util.l_epoch_wk_dy_1) * 1440;
          l_mod := MOD (l_delta, l_ts_interval);

          IF l_mod <= 0
          THEN
             l_normalized_datetime := l_normalized_datetime - (l_mod / 1440);
          ELSE
             l_normalized_datetime :=
                            l_normalized_datetime
                            + (l_ts_interval - l_mod) / 1440;
          END IF;
       ELSIF l_ts_interval = 43200                          -- monthly interval...
       THEN
          l_datetime_tmp := TRUNC (l_normalized_datetime, 'Month');

          IF l_datetime_tmp != l_normalized_datetime
          THEN
             l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 1);
          END IF;
       ELSIF l_ts_interval = 525600                          -- yearly interval...
       THEN
          l_datetime_tmp := TRUNC (l_normalized_datetime, 'YEAR');

          IF l_datetime_tmp != l_normalized_datetime
          THEN
             l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 12);
          END IF;
       ELSIF l_ts_interval = 5256000                        -- decadal interval...
       THEN
          l_mod := MOD (TO_NUMBER (TO_CHAR (l_normalized_datetime, 'YYYY')), 10);
          l_datetime_tmp :=
                ADD_MONTHS (TRUNC (l_normalized_datetime, 'YEAR'),
                            - (l_mod * 12));

          IF l_datetime_tmp != l_normalized_datetime
          THEN
             l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 120);
          END IF;
       ELSE
          cwms_err.RAISE ('ERROR',
                             l_ts_interval
                          || ' minutes is not a valid/supported CWMS interval'
                         );
       END IF;

       RETURN l_normalized_datetime + (p_ts_offset / 1440);
       DBMS_APPLICATION_INFO.set_module (NULL, NULL);
    END get_time_on_after_interval;
--
--  See get_time_on_after_interval for description/comments/etc...
--
    FUNCTION get_time_on_before_interval (
       p_datetime      IN   DATE,
       p_ts_offset     IN   NUMBER,
       p_ts_interval   IN   NUMBER
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
       DBMS_APPLICATION_INFO.set_module ('create_ts',
                                         'Function get_Time_On_Before_Interval'
                                        );

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
       l_normalized_datetime := TRUNC (p_datetime, 'MI') - (p_ts_offset / 1440);

       IF p_ts_interval = 1
       THEN
          NULL;                                               -- nothing to do...
       ELSIF l_ts_interval < 10080                -- intervals less than a week...
       THEN
          l_delta := (l_normalized_datetime - cwms_util.l_epoch) * 1440;
          l_mod := MOD (l_delta, l_ts_interval);

          IF l_mod < 0
          THEN
             l_normalized_datetime :=
                            l_normalized_datetime
                            - (l_ts_interval + l_mod) / 1440;
          ELSE
             l_normalized_datetime := l_normalized_datetime - (l_mod / 1440);
          END IF;
       ELSIF l_ts_interval = 10080                           -- weekly interval...
       THEN
          l_delta := (l_normalized_datetime - cwms_util.l_epoch_wk_dy_1) * 1440;
          l_mod := MOD (l_delta, l_ts_interval);

          IF l_mod < 0
          THEN
             l_normalized_datetime :=
                            l_normalized_datetime
                            - (l_ts_interval + l_mod) / 1440;
          ELSE
             l_normalized_datetime := l_normalized_datetime - (l_mod / 1440);
          END IF;
       ELSIF l_ts_interval = 43200                          -- monthly interval...
       THEN
          l_normalized_datetime := TRUNC (l_normalized_datetime, 'Month');
       ELSIF l_ts_interval = 525600                          -- yearly interval...
       THEN
          l_normalized_datetime := TRUNC (l_normalized_datetime, 'YEAR');
       ELSIF l_ts_interval = 5256000                        -- decadal interval...
       THEN
          l_mod := MOD (TO_NUMBER (TO_CHAR (l_normalized_datetime, 'YYYY')), 10);
          l_normalized_datetime :=
                ADD_MONTHS (TRUNC (l_normalized_datetime, 'YEAR'),
                            - (l_mod * 12));
       ELSE
          cwms_err.RAISE ('ERROR',
                             l_ts_interval
                          || ' minutes is not a valid/supported CWMS interval'
                         );
       END IF;

       RETURN l_normalized_datetime + (p_ts_offset / 1440);
       DBMS_APPLICATION_INFO.set_module (NULL, NULL);
    END get_time_on_before_interval;
   
   
    /* Formatted on 2007/06/29 09:39 (Formatter Plus v4.8.8) */
    FUNCTION get_location_id (p_cwms_ts_id IN VARCHAR2, p_db_office_id IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN get_location_id
                (p_cwms_ts_code      => cwms_util.get_ts_code
                                           (p_cwms_ts_id          => p_cwms_ts_id,
                                            p_db_office_code      => cwms_util.get_db_office_code
                                                                        (p_office_id      => p_db_office_id
                                                                        )
                                           )
                );
    END;

    /* Formatted on 2007/06/29 09:41 (Formatter Plus v4.8.8) */
    FUNCTION get_location_id (p_cwms_ts_code IN NUMBER)
       RETURN VARCHAR2
    IS
       l_location_id   VARCHAR2 (49);
    BEGIN
       SELECT location_id
         INTO l_location_id
         FROM mv_cwms_ts_id
        WHERE ts_code = p_cwms_ts_code;
    END;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_PARAMETER_CODE -
--
   FUNCTION get_parameter_code (
      p_base_parameter_id   IN   VARCHAR2,
      p_sub_parameter_id    IN   VARCHAR2,
      p_office_id           IN   VARCHAR2 DEFAULT NULL,
      p_create              IN   VARCHAR2 DEFAULT 'T'
   )
      RETURN NUMBER
   IS
      l_base_parameter_code   NUMBER;
   BEGIN
      SELECT base_parameter_code
        INTO l_base_parameter_code
        FROM cwms_base_parameter
       WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);
       
      dbms_output.put_line(l_base_parameter_code);
      --
      RETURN get_parameter_code (l_base_parameter_code,
                                 p_sub_parameter_id,
                                 cwms_util.get_db_office_code (p_office_id),
                                 cwms_util.return_true_or_false (p_create)
                                );
   END;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_PARAMETER_CODE -
--
   FUNCTION get_parameter_code (
      p_base_parameter_code   IN   NUMBER,
      p_sub_parameter_id      IN   VARCHAR2,
      p_office_code           IN   NUMBER,
      p_create                IN   BOOLEAN DEFAULT TRUE
   )
      RETURN NUMBER
   IS
      l_parameter_code      NUMBER;
      l_base_parameter_id   cwms_base_parameter.base_parameter_id%TYPE;
   BEGIN
      BEGIN
         IF p_sub_parameter_id IS NOT NULL
         THEN
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE base_parameter_code = p_base_parameter_code
               AND db_office_code IN
                                   (p_office_code, cwms_util.db_office_code_all)
               AND UPPER (sub_parameter_id) = UPPER (p_sub_parameter_id);
         ELSE
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE base_parameter_code = p_base_parameter_code
                and ap.sub_parameter_id is null
               AND db_office_code IN (cwms_util.db_office_code_all);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN                                      -- Insert new sub_parameter...
            IF p_create OR p_create IS NULL
            THEN
               INSERT INTO at_parameter
                           (parameter_code, db_office_code,
                            base_parameter_code, sub_parameter_id
                           )
                    VALUES (cwms_seq.NEXTVAL, p_office_code,
                            p_base_parameter_code, p_sub_parameter_id
                           )
                 RETURNING parameter_code
                      INTO l_parameter_code;
            ELSE
               SELECT base_parameter_id
                 INTO l_base_parameter_id
                 FROM cwms_base_parameter
                WHERE base_parameter_code = p_base_parameter_code;
   
               cwms_err.RAISE ('INVALID_PARAM_ID',
                               cwms_util.concat_base_sub_id (l_base_parameter_id,
                                                             p_sub_parameter_id
                                                            )
                              );
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
   FUNCTION get_parameter_code (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_parameter_code number := null;
   BEGIN
      select parameter_code 
        into l_parameter_code 
        from at_cwms_ts_spec 
       where ts_code = p_cwms_ts_code;

      return l_parameter_code;
      
   EXCEPTION
      WHEN no_data_found THEN
         cwms_err.raise(
            'INVALID_ITEM', 
            ''||nvl(p_cwms_ts_code, 'NULL'), 
            'CWMS time series code.');
         
   END get_parameter_code;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_PARAMETER_ID -
--
   FUNCTION get_parameter_id (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      l_parameter_row at_parameter%rowtype;
      l_parameter_id varchar2(49) := null;
   BEGIN
      select *
        into l_parameter_row
        from at_parameter 
       where parameter_code = get_parameter_code(p_cwms_ts_code);

      select base_parameter_id
        into l_parameter_id
        from cwms_base_parameter
       where base_parameter_code = l_parameter_row.base_parameter_code;

      if l_parameter_row.sub_parameter_id is not null then
         l_parameter_id := l_parameter_id 
            || '-' 
            || l_parameter_row.sub_parameter_id;
      end if;

      return l_parameter_id;
      
   END get_parameter_id;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_BASE_PARAMETER_CODE -
--
   FUNCTION get_base_parameter_code (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_base_parameter_code number(10) := null;
   BEGIN
      select base_parameter_code
        into l_base_parameter_code
        from at_parameter
       where parameter_code = get_parameter_code(p_cwms_ts_code);

      return l_base_parameter_code;

   END get_base_parameter_code;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_BASE_PARAMETER_ID -
--
   FUNCTION get_base_parameter_id (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      l_base_parameter_id varchar2(16) := null;
   BEGIN
      select base_parameter_id
        into l_base_parameter_id
        from cwms_base_parameter
       where base_parameter_code = get_base_parameter_code(p_cwms_ts_code);

      return l_base_parameter_id;

   END get_base_parameter_id;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_PARAMETER_TYPE_CODE -
--
   FUNCTION get_parameter_type_code (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_parameter_type_code number := null;
   BEGIN
      select parameter_type_code 
        into l_parameter_type_code 
        from at_cwms_ts_spec 
       where ts_code = p_cwms_ts_code;

      return l_parameter_type_code;
      
   EXCEPTION
      WHEN no_data_found THEN
         cwms_err.raise(
            'INVALID_ITEM', 
            ''||nvl(p_cwms_ts_code, 'NULL'), 
            'CWMS time series code.');
         
   END get_parameter_type_code;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_PARAMETER_TYPE_ID -
--
   FUNCTION get_parameter_type_id (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      l_parameter_type_id varchar2(16) := null;
   BEGIN
      select parameter_type_id
        into l_parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = get_parameter_type_code(p_cwms_ts_code);

      return l_parameter_type_id;
      
   END get_parameter_type_id;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_DB_OFFICE_CODE -
--
   FUNCTION get_db_office_code (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_db_office_code at_base_location.db_office_code%type := null;
   BEGIN
      select db_office_code
        into l_db_office_code
        from at_base_location bl,
             at_physical_location pl,
             at_cwms_ts_spec ts
       where ts.ts_code = p_cwms_ts_code
         and pl.location_code = ts.location_code
         and bl.base_location_code = pl.base_location_code;

      return l_db_office_code;
      
   EXCEPTION
      WHEN no_data_found THEN
         cwms_err.raise(
            'INVALID_ITEM', 
            ''||nvl(p_cwms_ts_code, 'NULL'), 
            'CWMS time series code.');
         
   END get_db_office_code;

--*******************************************************************   --
--*******************************************************************   --
--
-- GET_DB_OFFICE_ID -
--
   FUNCTION get_db_office_id (
      p_cwms_ts_code          IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      l_db_office_id cwms_office.office_id%type := null;
   BEGIN
      select office_id
        into l_db_office_id
        from cwms_office
       where office_code = get_db_office_code(p_cwms_ts_code);

      return l_db_office_id;
      
   END get_db_office_id;


PROCEDURE update_ts_id (
   p_ts_code                  IN   NUMBER,
   p_interval_utc_offset      IN   NUMBER DEFAULT NULL,         -- in minutes.
   p_snap_forward_minutes     IN   NUMBER DEFAULT NULL,
   p_snap_backward_minutes    IN   NUMBER DEFAULT NULL,
   p_local_reg_time_zone_id   IN   VARCHAR2 DEFAULT NULL,
   p_ts_active_flag           IN   VARCHAR2 DEFAULT NULL
)
IS
   l_ts_interval                 NUMBER;
   l_interval_utc_offset_old     NUMBER;
   l_interval_utc_offset_new     NUMBER;
   l_snap_forward_minutes_new    NUMBER;
   l_snap_forward_minutes_old    NUMBER;
   l_snap_backward_minutes_new   NUMBER;
   l_snap_backward_minutes_old   NUMBER;
   l_time_zone_code_old          NUMBER;
   l_time_zone_code_new          NUMBER;
   l_ts_active_new               VARCHAR2 (1)   := upper(p_ts_active_flag);
   l_ts_active_old               VARCHAR2 (1);
   l_tmp                         NUMBER         := NULL;
BEGIN
   --
   --
   BEGIN
      SELECT a.interval_utc_offset, a.interval_backward,
             a.interval_forward, a.active_flag,
             a.time_zone_code, b.INTERVAL
        INTO l_interval_utc_offset_old, l_snap_backward_minutes_old,
             l_snap_forward_minutes_old, l_ts_active_old,
             l_time_zone_code_old, l_ts_interval
        FROM at_cwms_ts_spec a, cwms_interval b
       WHERE a.interval_code = b.interval_code AND a.ts_code = p_ts_code;
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
         if p_interval_utc_offset is not null or p_interval_utc_offset != cwms_util.utc_offset_irregular
         then
                        cwms_err.RAISE ('INVALID_UTC_OFFSET',
                               p_interval_utc_offset,
                               'Irregular'
                              );
         else
         l_interval_utc_offset_new := cwms_util.utc_offset_irregular;
         end if;
      ELSE
         IF p_interval_utc_offset = cwms_util.utc_offset_undefined
         THEN
            l_interval_utc_offset_new := cwms_util.utc_offset_undefined;
         ELSE
            IF p_interval_utc_offset >= 0 and p_interval_utc_offset < l_ts_interval
            THEN
               l_interval_utc_offset_new := p_interval_utc_offset;
            ELSE
               cwms_err.RAISE ('INVALID_UTC_OFFSET',
                               p_interval_utc_offset,
                               l_ts_interval
                              );
            END IF;
         END IF;

         --
         -- check if the utc offset is being changed and can it be changed.
         --
         IF     l_interval_utc_offset_old != cwms_util.utc_offset_undefined
            AND l_interval_utc_offset_old != l_interval_utc_offset_new
         THEN  -- need to check if this ts_code already holds data, if it does
               -- then can't change interval_utc_offset.
            SELECT COUNT (*)
              INTO l_tmp
              FROM av_tsv
             WHERE ts_code = p_ts_code;

            IF l_tmp > 0
            THEN
               cwms_err.RAISE ('CANNOT_CHANGE_OFFSET', get_ts_id(p_ts_code));
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
      OR l_interval_utc_offset_new != cwms_util.utc_offset_irregular
   THEN
      IF    p_snap_forward_minutes IS NOT NULL
         OR p_snap_backward_minutes IS NOT NULL
      THEN
         l_snap_forward_minutes_new := NVL (p_snap_forward_minutes, 0);
         l_snap_backward_minutes_new := NVL (p_snap_backward_minutes, 0);

         IF l_snap_forward_minutes_new + l_snap_backward_minutes_new >=
                                                                l_ts_interval
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
   IF p_local_reg_time_zone_id IS NULL
   THEN
      l_time_zone_code_new := l_time_zone_code_old;
   ELSE
      l_time_zone_code_new :=
                      cwms_util.get_time_zone_code (p_local_reg_time_zone_id);
   END IF;

   --
   UPDATE at_cwms_ts_spec a
      SET a.interval_utc_offset = l_interval_utc_offset_new,
          a.interval_forward = l_snap_forward_minutes_new,
          a.interval_backward = l_snap_backward_minutes_new,
          a.time_zone_code = l_time_zone_code_new,
          a.active_flag = l_ts_active_new
    WHERE a.ts_code = p_ts_code;
--
--
END;

    /* Formatted on 2007/06/27 10:28 (Formatter Plus v4.8.8) */

    PROCEDURE update_ts_id (
       p_cwms_ts_id               IN   VARCHAR2,
       p_interval_utc_offset      IN   NUMBER DEFAULT NULL,         -- in minutes.
       p_snap_forward_minutes     IN   NUMBER DEFAULT NULL,
       p_snap_backward_minutes    IN   NUMBER DEFAULT NULL,
       p_local_reg_time_zone_id   IN   VARCHAR2 DEFAULT NULL,
       p_ts_active_flag           IN   VARCHAR2 DEFAULT NULL,
       p_db_office_id             IN   VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN
       update_ts_id
          (p_ts_code                     => cwms_util.get_ts_code
                                               (p_cwms_ts_id,
                                                cwms_util.get_db_office_code
                                                                   (p_db_office_id)
                                               ),
           p_interval_utc_offset         => p_interval_utc_offset,
           -- in minutes.
           p_snap_forward_minutes        => p_snap_forward_minutes,
           p_snap_backward_minutes       => p_snap_backward_minutes,
           p_local_reg_time_zone_id      => p_local_reg_time_zone_id,
           p_ts_active_flag              => p_ts_active_flag
          );
    END;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- SET_TS_TIME_ZONE -
--
procedure set_ts_time_zone (p_ts_code        in number,
                            p_time_zone_name in varchar2)
is
  l_time_zone_name varchar2(28) := nvl(p_time_zone_name, 'UTC');
  l_time_zone_code number;
  l_interval_val   number;
  l_tz_offset      number;
  l_office_id      varchar2(16);
  l_tsid           varchar2(193);
begin
   if p_time_zone_name is null then
      l_time_zone_code := null;
   else
      begin
         select time_zone_code
           into l_time_zone_code
           from cwms_time_zone
          where upper(time_zone_name) = upper(p_time_zone_name);
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_time_zone_name, 'time zone name');
      end;
   end if;
   select interval
     into l_interval_val
     from at_cwms_ts_spec ts,
          cwms_interval   i
    where ts.ts_code = p_ts_code
      and i.interval_code = ts.interval_code;
   if l_interval_val > 60 then
      begin
         execute immediate replace('
            select distinct mod(round((cast((cast(date_time as timestamp) at time zone ''$tz'') as date)
                               - trunc(cast((cast(date_time as timestamp) at time zone ''$tz'') as date)))
                               * 1440, 0), :a)
              from (select distinct date_time
                      from av_tsv_dqu
                     where ts_code = :b)', '$tz', l_time_zone_name)
         into l_tz_offset using l_interval_val, p_ts_code;
      exception
         when no_data_found then
            null;
         when too_many_rows then
            select cwms_ts_id,
                   db_office_id
              into l_tsid,
                   l_office_id
              from mv_cwms_ts_id
             where ts_code = p_ts_code;
            cwms_err.raise(
               'ERROR',
               'Cannot set '
               || l_office_id 
               || '.' 
               || l_tsid
               || ' to time zone '
               || nvl(p_time_zone_name, 'NULL')
               || '.  Existing data does not conform to time zone.');
      end;
   end if;
   update at_cwms_ts_spec
      set time_zone_code = l_time_zone_code
    where ts_code = p_ts_code;
end set_ts_time_zone;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- set_tsid_time_zone -
--
procedure set_tsid_time_zone (p_ts_id          in varchar2,
                              p_time_zone_name in varchar2,
                              p_office_id      in varchar2 default null)
is
   l_ts_code   number;
   l_office_id varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
begin
   begin
      select ts_code
        into l_ts_code
        from mv_cwms_ts_id
       where upper(cwms_ts_id) = upper(p_ts_id)
         and upper(db_office_id) = upper(l_office_id);
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_ts_id, 'CWMS Timeseries Identifier');
   end;
   set_ts_time_zone(l_ts_code, p_time_zone_name);
end set_tsid_time_zone;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- get_ts_time_zone -
--
function get_ts_time_zone (p_ts_code in number)
return varchar2
is
   l_time_zone_code number;
   l_time_zone_id   varchar2(28);
begin
   select time_zone_code
     into l_time_zone_code
     from at_cwms_ts_spec
    where ts_code = p_ts_code;
   if l_time_zone_code is null then
      l_time_zone_id := null;
   else
      select time_zone_name
        into l_time_zone_id
        from cwms_time_zone
       where time_zone_code = l_time_zone_code;
   end if;
   return l_time_zone_id;
end get_ts_time_zone;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- GET_TSID_TIME_ZONE -
--
function get_tsid_time_zone (p_ts_id     in varchar2,
                             p_office_id in varchar2 default null)
return varchar2
is
   l_ts_code   number;
   l_office_id varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
begin
   begin
      select ts_code
        into l_ts_code
        from mv_cwms_ts_id
       where upper(cwms_ts_id) = upper(p_ts_id)
         and upper(db_office_id) = upper(l_office_id);
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_ts_id, 'CWMS Timeseries Identifier');
   end;
   return get_ts_time_zone(l_ts_code);
end get_tsid_time_zone;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (
      p_office_id         IN   VARCHAR2,
      p_cwms_ts_id   IN   VARCHAR2,
      p_utc_offset        IN   NUMBER DEFAULT NULL
   )
   IS
      l_ts_code number;
   BEGIN
   create_ts_code (p_ts_code => l_ts_code,
                   p_cwms_ts_id => p_cwms_ts_id,
                   p_utc_offset => p_utc_offset,
                   p_office_id => p_office_id
                  );
   END create_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- CREATE_TS -
--
   PROCEDURE create_ts (
      p_cwms_ts_id     IN   VARCHAR2,
      p_utc_offset          IN   NUMBER DEFAULT NULL,
      p_interval_forward    IN   NUMBER DEFAULT NULL,
      p_interval_backward   IN   NUMBER DEFAULT NULL,
      p_versioned           IN   VARCHAR2 DEFAULT 'F',
      p_active_flag         IN   VARCHAR2 DEFAULT 'T',
      p_office_id           IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (p_ts_code           => l_ts_code,
                      p_cwms_ts_id        => p_cwms_ts_id,
                      p_utc_offset        => p_utc_offset,
                      p_interval_forward  => p_interval_forward,
                      p_interval_backward => p_interval_backward,
                      p_versioned         => p_versioned,
                      p_active_flag       => p_active_flag,
                      p_office_id         => p_office_id
                     );
                                    
   END create_ts;
    --
    --*******************************************************************   --
    --*******************************************************************   --
    --
    -- CREATE_TS_TZ -
    --
    PROCEDURE create_ts_tz (p_cwms_ts_id IN varchar2,
                         p_utc_offset IN number DEFAULT NULL ,
                         p_interval_forward IN number DEFAULT NULL ,
                         p_interval_backward IN number DEFAULT NULL ,
                         p_versioned IN varchar2 DEFAULT 'F' ,
                         p_active_flag IN varchar2 DEFAULT 'T' ,
                         p_time_zone_name IN VARCHAR2 DEFAULT 'UTC',
                         p_office_id IN varchar2 DEFAULT NULL
    )
   IS
      l_ts_code   NUMBER;
   BEGIN

        -- 	  create_ts_code (p_ts_code			  => l_ts_code,
        -- 							p_cwms_ts_id		  => p_cwms_ts_id,
        -- 							p_utc_offset		  => p_utc_offset,
        -- 							p_interval_forward  => p_interval_forward,
        -- 							p_interval_backward => p_interval_backward,
        -- 							p_versioned 		  => p_versioned,
        -- 							p_active_flag		  => p_active_flag,
        -- 							p_time_zone_name,
        -- 							p_office_id 		  => p_office_id
        -- 						  );
        null;
        cwms_err.RAISE ('ERROR', 'create_ts_tz is not compelete - see Gemini Issue: CWDB-1654');
    END create_ts_tz;

    --
    --*******************************************************************   --
    --*******************************************************************   --
    --
    -- CREATE_TS_CODE - v2.0 -
    --
/* Formatted on 2007/06/25 13:47 (Formatter Plus v4.8.8) */
PROCEDURE create_ts_code (
   p_ts_code             OUT      NUMBER,
   p_cwms_ts_id          IN       VARCHAR2,
   p_utc_offset          IN       NUMBER DEFAULT NULL,
   p_interval_forward    IN       NUMBER DEFAULT NULL,
   p_interval_backward   IN       NUMBER DEFAULT NULL,
   p_versioned           IN       VARCHAR2 DEFAULT 'F',
   p_active_flag         IN       VARCHAR2 DEFAULT 'T',
   p_fail_if_exists      IN       VARCHAR2 DEFAULT 'T',
   p_office_id           IN       VARCHAR2 DEFAULT NULL
)
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
   l_duration_code         NUMBER;
   l_version               VARCHAR2 (50);
   l_office_code           NUMBER;
   l_location_code         NUMBER;
   l_ts_code_nv            NUMBER;
   l_ret                   NUMBER;
   l_hashcode              NUMBER;
   l_str_error             VARCHAR2 (256);
   l_utc_offset            NUMBER;
   l_all_office_code       NUMBER         := cwms_util.db_office_code_all;
   l_active_flag           VARCHAR2 (1)   := 'T';
   l_ts_id_exists          BOOLEAN        := FALSE;
BEGIN
   IF p_office_id IS NULL
   THEN
      l_office_id := cwms_util.user_office_id;
   ELSE
      l_office_id := UPPER (p_office_id);
   END IF;
   

   DBMS_APPLICATION_INFO.set_module ('create_ts_code',
                                     'parse timeseries_desc using regexp'
                                    );
   --parse values from timeseries_desc using regular expressions
   parse_ts (p_cwms_ts_id,
             l_base_location_id,
             l_sub_location_id,
             l_base_parameter_id,
             l_sub_parameter_id,
             l_parameter_type_id,
             l_interval_id,
             l_duration_id,
             l_version
            );
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
   
   if l_office_code = 0 
   then
      cwms_err.RAISE ('INVALID_OFFICE_ID', l_office_id);
   end if;

   -- check for valid cwms_code based on id passed in, if not there then create, if create error then fail and return
   DBMS_APPLICATION_INFO.set_action
                                   ('check for cwms_code, create if necessary');

   --generate hash and lock table for that hash value to serialize ts_create as timeseries_desc is not pkeyed.
   SELECT ORA_HASH (UPPER (l_office_id) || UPPER (p_cwms_ts_id), 1073741823)
     INTO l_hashcode
     FROM DUAL;

   l_ret :=
      DBMS_LOCK.request (id                => l_hashcode,
                           timeout           => 0,
                           lockmode          => DBMS_LOCK.x_mode,
                           release_on_commit => TRUE);

   IF l_ret > 0
   THEN
      DBMS_LOCK.sleep (2);
   ELSE
      -- BEGIN...
      DBMS_APPLICATION_INFO.set_action
                              ('check for location_code, create if necessary');
         -- check for valid base_location_code based on id passed in, if not there then create, -
      -- if create error then fail and return -
      cwms_loc.create_location_raw (l_base_location_code,
                                    l_location_code,
                                    l_base_location_id,
                                    l_sub_location_id,
                                    l_office_code
                                   );

      IF l_location_code IS NULL
      THEN
         raise_application_error (-20203,
                                  'Unable to generate location_code',
                                  TRUE
                                 );
      END IF;

      -- determine rest of lookup codes based on passed in values, use scalar subquery to minimize context switches, return error if lookups not found
      DBMS_APPLICATION_INFO.set_action ('check code lookups, scalar subquery');

      SELECT (SELECT base_parameter_code
                FROM cwms_base_parameter p
               WHERE UPPER (p.base_parameter_id) = UPPER (l_base_parameter_id))
                                                                            p,
             (SELECT duration_code
                FROM cwms_duration d
               WHERE UPPER (d.duration_id) = UPPER (l_duration_id)) d,
             (SELECT parameter_type_code
                FROM cwms_parameter_type p
               WHERE UPPER (p.parameter_type_id) = UPPER (l_parameter_type_id))
                                                                           pt,
             (SELECT interval_code
                FROM cwms_interval i
               WHERE UPPER (i.interval_id) = UPPER (l_interval_id)) i,
             (SELECT INTERVAL
                FROM cwms_interval ii
               WHERE UPPER (ii.interval_id) = UPPER (l_interval_id)) ii
        INTO l_base_parameter_code,
             l_duration_code,
             l_parameter_type_code,
             l_interval_code,
             l_interval
        FROM DUAL;

      IF    l_base_parameter_code IS NULL
         OR l_duration_code IS NULL
         OR l_parameter_type_code IS NULL
         OR l_interval_code IS NULL
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

         raise_application_error (-20205, l_str_error, TRUE);
      END IF;

      BEGIN
         IF l_sub_parameter_id IS NULL
         THEN
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE base_parameter_code = l_base_parameter_code
               AND sub_parameter_id IS NULL
               AND db_office_code IN (l_office_code, l_all_office_code);
         ELSE
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE base_parameter_code = l_base_parameter_code
               AND UPPER (sub_parameter_id) = UPPER (l_sub_parameter_id)
               AND db_office_code IN (l_office_code, l_all_office_code);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_sub_parameter_id IS NULL
            THEN
               cwms_err.RAISE
                  ('GENERIC_ERROR',
                      l_base_parameter_id
                   || ' is not a valid Base Parameter. Cannot Create a new CWMS_TS_ID'
                  );
            ELSE                                -- Insert new sub_parameter...
               INSERT INTO at_parameter
                           (parameter_code, db_office_code,
                            base_parameter_code, sub_parameter_id
                           )
                    VALUES (cwms_seq.NEXTVAL, l_office_code,
                            l_base_parameter_code, l_sub_parameter_id
                           )
                 RETURNING parameter_code
                      INTO l_parameter_code;
            END IF;
      END;

      --after all lookups, check for existing ts_code, insert it if not found, and verify that it was inserted with the returning, error if no valid ts_code is returned
      DBMS_APPLICATION_INFO.set_action
                                     ('check for ts_code, create if necessary');

      BEGIN
         SELECT ts_code
           INTO p_ts_code
           FROM at_cwms_ts_spec acts
          WHERE     /*office_code = l_office_code
                AND */ acts.location_code = l_location_code
            AND acts.parameter_code = l_parameter_code
            AND acts.parameter_type_code = l_parameter_type_code
            AND acts.interval_code = l_interval_code
            AND acts.duration_code = l_duration_code
            AND UPPER (NVL (acts.VERSION, 1)) = UPPER (NVL (l_version, 1))
            AND acts.delete_date IS NULL;

         --
         l_ts_id_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_interval_id = '0'
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
                                     l_interval_id
                                    );
                  END IF;
               END IF;
            END IF;

            INSERT INTO at_cwms_ts_spec t
                        (ts_code, location_code, parameter_code,
                         parameter_type_code, interval_code,
                         duration_code, VERSION, interval_utc_offset,
                         active_flag
                        )
                 VALUES (cwms_seq.NEXTVAL, l_location_code, l_parameter_code,
                         l_parameter_type_code, l_interval_code,
                         l_duration_code, l_version, l_utc_offset,
                         l_active_flag
                        )
              RETURNING ts_code
                   INTO p_ts_code;

            COMMIT;
      END;
   END IF;

   IF p_ts_code IS NULL
   THEN
      raise_application_error (-20204,
                               'Unable to generate timeseries_code',
                               TRUE
                              );
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
   p_ts_code             OUT      NUMBER,
   p_cwms_ts_id          IN       VARCHAR2,
   p_utc_offset          IN       NUMBER DEFAULT NULL,
   p_interval_forward    IN       NUMBER DEFAULT NULL,
   p_interval_backward   IN       NUMBER DEFAULT NULL,
   p_versioned           IN       VARCHAR2 DEFAULT 'F',
   p_active_flag         IN       VARCHAR2 DEFAULT 'T',
   p_fail_if_exists      IN       VARCHAR2 DEFAULT 'T',
   p_time_zone_name      IN       VARCHAR2 DEFAULT 'UTC',
   p_office_id           IN       VARCHAR2 DEFAULT NULL
)
IS
   l_ts_code NUMBER;
BEGIN
   create_ts_code(
      l_ts_code,
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
function tz_offset_at_gmt(
   p_date_time in date, 
   p_tz_name   in varchar2)
   return integer
is
   l_offset        integer := 0;
   l_tz_offset_str varchar2(8) := rtrim(tz_offset(p_tz_name), chr(0));
   l_ts_utc        timestamp;
   l_ts_loc        timestamp;
   l_hours         integer;
   l_minutes       integer;
   l_parts         cwms_util.str_tab_t;
begin
   if l_tz_offset_str != '+00:00' and l_tz_offset_str != '-00:00' then
      l_parts   := cwms_util.split_text(l_tz_offset_str, ':');
      l_hours   := to_number(l_parts(1));
      l_minutes := to_number(l_parts(2));
      if l_hours < 0 then
         l_minutes := l_hours * 60 - l_minutes;
      else
        l_minutes := l_hours * 60 + l_minutes;
      end if;
      l_ts_utc := cast(p_date_time as timestamp);
      l_ts_loc := from_tz(l_ts_utc, 'UTC') at time zone p_tz_name;
      l_offset := l_minutes - round((cwms_util.to_millis(l_ts_loc) - cwms_util.to_millis(l_ts_utc)) / 60000);
   end if;
   return l_offset;
end;

--*******************************************************************   --
--*******************************************************************   --
--
-- shift_for_localtime
--
function shift_for_localtime(
   p_date_time in date, 
   p_tz_name   in varchar2)
   return date
is
begin
   RETURN p_date_time + tz_offset_at_gmt(p_date_time, p_tz_name) / 1440;
end shift_for_localtime;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- setup_retrieve
--
procedure setup_retrieve(
   p_start_time      in out date,
   p_end_time        in out date,
   p_reg_start_time  out    date,
   p_reg_end_time    out    date,
   p_ts_code         in     number,
   p_interval        in     number,
   p_offset          in     number,
   p_start_inclusive in     boolean,
   p_end_inclusive   in     boolean,
   p_previous        in     boolean,
   p_next            in     boolean,
   p_trim            in     boolean)
is
   l_start_time     date := p_start_time;
   l_end_time       date := p_end_time;
   l_temp_time      date;
begin
   --
   -- handle inclusive/exclusive by adjusting start/end times inward
   --
   if not p_start_inclusive then
      l_start_time := l_start_time + 1 / 86400;
   end if;

   if not p_end_inclusive then
      l_end_time   := l_end_time   - 1 / 86400;
   end if;
   --
   -- handle previous/next by adjusting start/end times outward
   --
   if p_previous then
      if p_interval = 0 then
         select max(date_time)
           into l_temp_time
           from av_tsv
          where ts_code    =  p_ts_code
            and date_time  <  l_start_time
            and start_date <= l_end_time 
            and end_date   >  l_start_time;

         if l_temp_time is not null then
            l_start_time := l_temp_time;
         end if;
      else
         l_start_time := l_start_time - p_interval / 1440;
      end if;         
   end if;       
      
   if p_next then
      if p_interval = 0 then
         select min(date_time)
           into l_temp_time
           from av_tsv
          where ts_code    =  p_ts_code
            and date_time  >  l_end_time
            and start_date <= l_end_time 
            and end_date   >  l_start_time;

         if l_temp_time is not null then
            l_end_time := l_temp_time;
         end if;
      else
         l_end_time := l_end_time + p_interval / 1440;
      end if;
   end if;       
   --
   -- handle trim by adjusting start/end times inward to first/last
   -- non-missing values
   --    
   if p_trim then
      select min(date_time), 
             max(date_time)
        into l_start_time,
             l_end_time
        from (
             select date_time
               from av_tsv v,
                    cwms_data_quality q
              where v.ts_code = p_ts_code
                and v.date_time between l_start_time and l_end_time
                and v.start_date <= l_end_time 
                and v.end_date > l_start_time
                and v.quality_code = q.quality_code
                and q.validity_id != 'MISSING'
                and v.value is not null
             );
   end if;
   --
   -- set the out parameters
   --
   p_start_time := l_start_time;
   p_end_time   := l_end_time;
   if p_interval = 0 then
      --
      -- These parameters are used to generate a regular time series from which
      -- to fill in the times of missing values.  In the case of irregular time
      -- series, set them so that they will not generate a time series at all.
      --
      p_reg_start_time := null;
      p_reg_end_time   := null;
   else
      if p_offset = cwms_util.utc_offset_undefined then
         p_reg_start_time := get_time_on_after_interval(l_start_time, null, p_interval);
         p_reg_end_time   := get_time_on_before_interval(l_end_time, null, p_interval);
      else
         p_reg_start_time := get_time_on_after_interval(l_start_time, p_offset, p_interval);
         p_reg_end_time   := get_time_on_before_interval(l_end_time, p_offset, p_interval);
     end if;        
   end if;
   
end setup_retrieve;   
--
--*******************************************************************   --
--*******************************************************************   --
--
-- BUILD_RETRIEVE_TS_QUERY - v2.0 -
--
function build_retrieve_ts_query (
   p_cwms_ts_id_out  out varchar2,
   p_units_out       out varchar2,
   p_cwms_ts_id      in  varchar2,
   p_units           in  varchar2,
   p_start_time      in  date,
   p_end_time        in  date,
   p_time_zone       in  varchar2 default 'UTC',
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_version_date    in  date     default null,
   p_max_version     in  varchar2 default 'T',
   p_office_id       in  varchar2 default null
   )
   return varchar2
is
   l_ts_code          number;
   l_interval         number;
   l_offset           number;
   l_office_id        varchar2(16)    := nvl(p_office_id, cwms_util.user_office_id);
   l_cwms_ts_id       varchar2(183)   := get_cwms_ts_id(p_cwms_ts_id, l_office_id);
   l_units            varchar2(16)    := nvl(p_units, get_db_unit_id(l_cwms_ts_id));
   l_time_zone        varchar2(28)    := nvl(p_time_zone, 'UTC');
   l_trim             boolean         := cwms_util.return_true_or_false(nvl(p_trim,      'F'));
   l_start_inclusive  boolean         := cwms_util.return_true_or_false(nvl(p_start_inclusive, 'T'));
   l_end_inclusive    boolean         := cwms_util.return_true_or_false(nvl(p_end_inclusive, 'T'));
   l_previous         boolean         := cwms_util.return_true_or_false(nvl(p_previous,  'F'));
   l_next             boolean         := cwms_util.return_true_or_false(nvl(p_next     , 'F'));
   l_start_time       date            := cwms_util.date_from_tz_to_utc(p_start_time, l_time_zone);
   l_end_time         date            := cwms_util.date_from_tz_to_utc(p_end_time, l_time_zone);
   l_version_date     date            := cwms_util.date_from_tz_to_utc(p_version_date, l_time_zone);
   l_reg_start_time   date;
   l_reg_end_time     date;
   l_max_version      boolean         := cwms_util.return_true_or_false(nvl(p_max_version, 'F'));
   l_query_str        varchar2(4000);
   l_start_str        varchar2(32);
   l_end_str          varchar2(32);
   l_reg_start_str    varchar2(32);
   l_reg_end_str      varchar2(32);
   l_missing          number          := 5;  -- MISSING quality code
   l_date_format      varchar2(32)    := 'yyyy/mm/dd-hh24.mi.ss';

   procedure set_action(text in varchar2)
   is
   begin
      dbms_application_info.set_action(text);
      dbms_output.put_line(text);
   end;   
begin
   --
   -- set the out parameters
   --
   p_cwms_ts_id_out := l_cwms_ts_id;
   p_units_out := l_units;
   --
   -- get ts code
   --
   dbms_application_info.set_module ('cwms_ts.build_retrieve_ts_query','Get TS Code');
   select ts_code,
          interval,
          interval_utc_offset
     into l_ts_code,
          l_interval,
          l_offset
     from mv_cwms_ts_id
    where db_office_id = upper(l_office_id)
      and upper(cwms_ts_id) = upper(p_cwms_ts_id);

   set_action('Handle start and end times');
   setup_retrieve(
      l_start_time,
      l_end_time,
      l_reg_start_time,
      l_reg_end_time,
      l_ts_code,
      l_interval,
      l_offset,
      l_start_inclusive,
      l_end_inclusive,
      l_previous,
      l_next,
      l_trim);
   --
   -- change interval from minutes to days
   --
   l_interval := l_interval / 1440;       
   --
   -- build the query string - for some reason the time zone must be a
   -- string literal and bind variables are problematic
   --
   if l_version_date is null then
      --
      -- min or max version date
      --
      if l_interval > 0 then
         --
         -- regular time series
         --
         if mod(l_interval, 30) = 0 or mod(l_interval, 365) = 0 then
            --
            -- must use calendar math
            --
            -- change interval from days to months
            --
            if mod(l_interval, 30) = 0 then
               l_interval := l_interval / 30;
            else
               l_interval := l_interval / 365 * 12;
            end if;
            l_query_str := 
               'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      value,
                      nvl(quality_code, :missing) "QUALITY_CODE"
                 from (
                      select date_time,
                             max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                             max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                        from av_tsv_dqu
                       where ts_code    =  :ts_code 
                         and date_time  >= to_date('':start'', '':datefmt'')  
                         and date_time  <= to_date('':end'',   '':datefmt'') 
                         and unit_id    =  '':units''
                         and start_date <= to_date('':end'',   '':datefmt'') 
                         and end_date   >  to_date('':start'', '':datefmt'')
                    group by date_time
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(add_months(to_date('':reg_start'', '':datefmt''), (level-1) * :interval), '':tz'') date_time
                        from dual
                       where to_date('':reg_start'', '':datefmt'') is not null
                  connect by level <= months_between(to_date('':reg_end'',   '':datefmt''),
                                                     to_date('':reg_start'', '':datefmt'')) / :interval + 1
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
         else
            --
            -- can use date arithmetic
            --
            l_query_str := 
               'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      value,
                      nvl(quality_code, :missing) "QUALITY_CODE"
                 from (
                      select date_time,
                             max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                             max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                        from av_tsv_dqu
                       where ts_code    =  :ts_code 
                         and date_time  >= to_date('':start'', '':datefmt'')  
                         and date_time  <= to_date('':end'',   '':datefmt'') 
                         and unit_id    =  '':units''
                         and start_date <= to_date('':end'',   '':datefmt'') 
                         and end_date   >  to_date('':start'', '':datefmt'')
                    group by date_time
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(to_date('':reg_start'', '':datefmt'') + (level-1) * :interval, '':tz'') date_time
                        from dual
                       where to_date('':reg_start'', '':datefmt'') is not null
                  connect by level <= round((to_date('':reg_end'',   '':datefmt'')  - 
                                             to_date('':reg_start'', '':datefmt'')) / :interval + 1)
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
         end if;
      else
        --
        -- irregular time series
        --
         l_query_str := 
            'select cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                    max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                    max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
               from av_tsv_dqu
              where ts_code    =  :ts_code 
                and date_time  >= to_date('':start'', '':datefmt'')  
                and date_time  <= to_date('':end'',   '':datefmt'') 
                and unit_id    =  '':units''
                and start_date <= to_date('':end'',   '':datefmt'') 
                and end_date   >  to_date('':start'', '':datefmt'')
           group by date_time
           order by date_time asc';
      end if;
                         
      if l_max_version then
         l_query_str := replace(l_query_str, ':first_or_last', 'last');
      else
         l_query_str := replace(l_query_str, ':first_or_last', 'first');
      end if;
      
   else
      --
      -- specified version date
      --
      if l_interval > 0 then
         --
         -- regular time series
         --
         if mod(l_interval, 30) = 0 or mod(l_interval, 365) = 0 then
            --
            -- must use calendar math
            --
            -- change interval from days to months
            --
            if mod(l_interval, 30) = 0 then
               l_interval := l_interval / 30;
            else
               l_interval := l_interval / 365 * 12;
            end if;
            l_query_str := 
               'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      value,
                      nvl(quality_code, :missing) "QUALITY_CODE"
                 from (
                      select date_time,
                             value,
                             quality_code
                        from av_tsv_dqu
                       where ts_code      =  :ts_code 
                         and date_time    >= to_date('':start'',   '':datefmt'')  
                         and date_time    <= to_date('':end'',     '':datefmt'') 
                         and unit_id      =  '':units''
                         and start_date   <= to_date('':end'',     '':datefmt'') 
                         and end_date     >  to_date('':start'',   '':datefmt'')
                         and version_date =  to_date('':version'', '':datefmt'')
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(add_months(to_date('':reg_start'', ''datefmt''), (level-1) * :interval), '':tz'') date_time
                        from dual
                       where to_date('':reg_start'', ''datefmt'') is not null
                  connect by level <= months_between(to_date('':reg_start'', ''datefmt''),
                                                     to_date('':reg_end'',   ''datefmt'')) / :interval + 1)
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
         else
            --
            -- can use date arithmetic
            --
            l_query_str := 
               'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      value,
                      nvl(quality_code, :missing) "QUALITY_CODE"
                 from (
                      select date_time,
                             value,
                             quality_code
                        from av_tsv_dqu
                       where ts_code      =  :ts_code 
                         and date_time    >= to_date('':start'',   '':datefmt'')  
                         and date_time    <= to_date('':end'',     '':datefmt'') 
                         and unit_id      =  '':units''
                         and start_date   <= to_date('':end'',     '':datefmt'') 
                         and end_date     >  to_date('':start'',   '':datefmt'')
                         and version_date =  to_date('':version'', '':datefmt'')
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(to_date('':reg_start'', '':datefmt'') + (level-1) * :interval, '':tz'') date_time
                        from dual
                       where to_date('':reg_start'', '':datefmt'') is not null
                  connect by level <= months_between(to_date('':reg_end'',   '':datefmt''),
                                                     to_date('':reg_start'', '':datefmt'')) / :interval + 1
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
         end if;
      else
        --
        -- irregular time series
        --
         l_query_str := 
            'select cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                    value,
                    quality_code
               from av_tsv_dqu
              where ts_code      =  :ts_code 
                and date_time    >= to_date('':start'',   '':datefmt'')  
                and date_time    <= to_date('':end'',     '':datefmt'') 
                and unit_id      =  '':units''
                and start_date   <= to_date('':end'',     '':datefmt'') 
                and end_date     >  to_date('':start'',   '':datefmt'')
                and version_date =  to_date('':version'', '':datefmt'')
           order by date_time asc';
      end if;                   
           
      l_query_str := replace(l_query_str, ':version', to_char(l_version_date, l_date_format));
      
   end if;
   
   l_start_str := to_char(l_start_time, l_date_format);
   l_end_str   := to_char(l_end_time,   l_date_format);
   
   l_query_str := replace(l_query_str, ':tz',      l_time_zone);
   l_query_str := replace(l_query_str, ':missing', l_missing);
   l_query_str := replace(l_query_str, ':ts_code', l_ts_code);
   l_query_str := replace(l_query_str, ':start',   l_start_str);
   l_query_str := replace(l_query_str, ':end',     l_end_str);
   l_query_str := replace(l_query_str, ':units',   l_units);
   l_query_str := replace(l_query_str, ':datefmt', l_date_format);
   
   if l_interval > 0 then
      l_reg_start_str := to_char(l_reg_start_time, l_date_format);
      l_reg_end_str   := to_char(l_reg_end_time,   l_date_format);
      
      l_query_str := replace(l_query_str, ':reg_start', l_reg_start_str);
      l_query_str := replace(l_query_str, ':reg_end',   l_reg_end_str);
      l_query_str := replace(l_query_str, ':interval',  l_interval);
   end if;
   
   --
   -- Return the query string
   --
   set_action('Return query string');
   dbms_application_info.set_module(null,null);
   return l_query_str;
    
end build_retrieve_ts_query;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS_OUT - v2.0 -
--
procedure retrieve_ts_out (
   p_at_tsv_rc       out sys_refcursor,
   p_cwms_ts_id_out  out varchar2,
   p_units_out       out varchar2,
   p_cwms_ts_id      in  varchar2,
   p_units           in  varchar2,
   p_start_time      in  date,
   p_end_time        in  date,
   p_time_zone       in  varchar2 default 'UTC',
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_version_date    in  date     default null,
   p_max_version     in  varchar2 default 'T',
   p_office_id       in  varchar2 default null
   )
is
   l_query_str varchar2(4000);

   procedure set_action(text in varchar2)
   is
   begin
      dbms_application_info.set_action(text);
      dbms_output.put_line(text);
   end;   
begin
   
   --
   -- Get the query string
   --
   dbms_application_info.set_module ('cwms_ts.retrieve_ts','Get query string');

   l_query_str := build_retrieve_ts_query(
      p_cwms_ts_id_out,
      p_units_out,
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

   l_query_str := replace(l_query_str, ':date_time_type', 'date');
   --
   -- open the cursor
   --
   set_action('Open cursor');
   open p_at_tsv_rc for l_query_str;
    
   dbms_application_info.set_module(null,null);
      
end retrieve_ts_out;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS - v1.4 -
--
procedure retrieve_ts (
   p_at_tsv_rc         in out   sys_refcursor,
   p_units             in       varchar2,
   p_officeid          in       varchar2,
   p_cwms_ts_id        in       varchar2,
   p_start_time        in       date,
   p_end_time          in       date,
   p_timezone          in       varchar2 default 'GMT',
   p_trim              in       number default cwms_util.false_num,
   p_inclusive         in       number default null,
   p_versiondate       in       date default null,
   p_max_version       in       number default cwms_util.true_num
)
is
   l_trim        varchar2(1);
   l_max_version varchar2(1);
   l_query_str   varchar2(4000);
   l_tsid        varchar2(183);
   l_unit        varchar2(16);
   
   procedure set_action(text in varchar2)
   is
   begin
      dbms_application_info.set_action(text);
      dbms_output.put_line(text);
   end;   
begin
   --
   -- handle input parameters
   --
   dbms_application_info.set_module ('cwms_ts.retrieve_ts','Handle input parameters');
   if p_trim is null or p_trim = cwms_util.false_num then
      l_trim := 'F';
   elsif p_trim = cwms_util.true_num then
      l_trim := 'T';
   else
      cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_trim);
   end if;

   if p_max_version is null or p_max_version = cwms_util.true_num then
      l_max_version := 'T';
   elsif p_max_version = cwms_util.false_num then
      l_max_version := 'F';
   else
      cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_max_version);
   end if;
   --
   -- Get the query string
   --
   dbms_application_info.set_module ('cwms_ts.retrieve_ts','Get query string');

   l_query_str := build_retrieve_ts_query(
      l_tsid,         -- p_cwms_ts_id_out  
      l_unit,         -- p_units_out       
      p_cwms_ts_id,   -- p_cwms_ts_id      
      p_units,        -- p_units           
      p_start_time,   -- p_start_time      
      p_end_time,     -- p_end_time        
      p_timezone,     -- p_time_zone       
      l_trim,         -- p_trim            
      'T',            -- p_start_inclusive 
      'T',            -- p_end_inclusive   
      'F',            -- p_previous        
      'F',            -- p_next            
      p_versiondate,  -- p_version_date    
      l_max_version,  -- p_max_version     
      p_officeid);    -- p_office_id       

   l_query_str := replace(l_query_str, ':date_time_type', 'timestamp with time zone');
   --
   -- open the cursor
   --
   set_action('Open cursor');
   open p_at_tsv_rc for l_query_str;

   dbms_application_info.set_module(null,null);

end retrieve_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS_2 - v1.4 -
--
procedure retrieve_ts_2 (
   p_at_tsv_rc         out       sys_refcursor,
   p_units             in       varchar2,
   p_officeid          in       varchar2,
   p_cwms_ts_id        in       varchar2,
   p_start_time        in       date,
   p_end_time          in       date,
   p_timezone          in       varchar2 default 'GMT',
   p_trim              in       number default cwms_util.false_num,
   p_inclusive         in       number default null,
   p_versiondate       in       date default null,
   p_max_version       in       number default cwms_util.true_num
)
is
   l_at_tsv_rc sys_refcursor;
begin
   retrieve_ts(
      p_at_tsv_rc,
      p_units,
      p_officeid,
      p_cwms_ts_id,
      p_start_time,
      p_end_time,
      p_timezone,
      p_trim,
      p_inclusive,
      p_versiondate,
      p_max_version
   );
end retrieve_ts_2;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS - v2.0 -
--
procedure retrieve_ts (
   p_at_tsv_rc       out sys_refcursor,
   p_cwms_ts_id      in  varchar2,
   p_units           in  varchar2,
   p_start_time      in  date,
   p_end_time        in  date,
   p_time_zone       in  varchar2 default 'UTC',
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_version_date    in  date     default null,
   p_max_version     in  varchar2 default 'T',
   p_office_id       in  varchar2 default null
   )
is
   l_cwms_ts_id_out varchar2(183);
   l_units_out      varchar2(16);
   l_at_tsv_rc      sys_refcursor;
begin
   retrieve_ts_out (
      l_at_tsv_rc,
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
      p_office_id
      );
   p_at_tsv_rc := l_at_tsv_rc;      
end retrieve_ts;    
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RETREIVE_TS_MULTI - v2.0 -
--
procedure retrieve_ts_multi (
   p_at_tsv_rc       out sys_refcursor,
   p_timeseries_info in  timeseries_req_array,
   p_time_zone       in  varchar2 default 'UTC',
   p_trim            in  varchar2 default 'F',
   p_start_inclusive in  varchar2 default 'T',
   p_end_inclusive   in  varchar2 default 'T',
   p_previous        in  varchar2 default 'F',
   p_next            in  varchar2 default 'F',
   p_version_date    in  date     default null,
   p_max_version     in  varchar2 default 'T',
   p_office_id       in  varchar2 default null
   )
is
   type date_tab_t is table of date;
   type val_tab_t  is table of binary_double;
   type qual_tab_t is table of number;
   
   date_tab    date_tab_t := date_tab_t();
   val_tab     val_tab_t  := val_tab_t();
   qual_tab    qual_tab_t := qual_tab_t();
   i           integer;
   j           pls_integer;
   t           nested_ts_table  := nested_ts_table();
   rec         sys_refcursor;
   l_time_zone varchar2(28) := nvl(p_time_zone, 'UTC');
   
begin

   dbms_application_info.set_module ('cwms_ts.retrieve_ts_multi','Preparation loop');
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
   for i in 1..p_timeseries_info.count loop
      t.extend;
      t(i) := nested_ts_type(
         i,
         p_timeseries_info(i).tsid,
         p_timeseries_info(i).unit,
         p_timeseries_info(i).start_time,
         p_timeseries_info(i).end_time,
         tsv_array());
      retrieve_ts_out(
         rec,
         t(i).tsid,
         t(i).units,
         p_timeseries_info(i).tsid,
         p_timeseries_info(i).unit,
         p_timeseries_info(i).start_time,
         p_timeseries_info(i).end_time,
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
         
      fetch rec bulk collect into date_tab, val_tab, qual_tab;
      
      t(i).data.extend(rec%rowcount);
      for j in 1..rec%rowcount loop
         t(i).data(j) := tsv_type(from_tz(cast(date_tab(j) as timestamp), 'UTC'), val_tab(j), qual_tab(j));
      end loop;
      
   end loop;
      
   open p_at_tsv_rc for 
      select sequence,
             tsid,
             units,
             start_time,
             end_time,
             l_time_zone "TIME_ZONE",
             cursor (
                    select date_time,
                           value,
                           quality_code
                      from table(t1.data)
                   order by date_time asc
                    ) "DATA" 
        from table(t) t1 order by sequence asc;
    
   dbms_application_info.set_module(null,null);
   
end retrieve_ts_multi;
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS -
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE store_ts (
      p_office_id         IN   VARCHAR2,
      p_cwms_ts_id   IN   VARCHAR2,
      p_units             IN   VARCHAR2,
      p_timeseries_data   IN   tsv_array,
      p_store_rule        IN   VARCHAR2 DEFAULT NULL,
      p_override_prot     IN   NUMBER DEFAULT cwms_util.false_num,
      p_versiondate       IN   DATE DEFAULT cwms_util.non_versioned
   )
   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   IS
      l_override_prot VARCHAR2(1);
   BEGIN
    cwms_apex.aa1(to_char(sysdate, 'YYYY-MM-DD HH24:MI') || 'store_ts(1.4): ' || p_cwms_ts_id);
      IF p_override_prot IS NULL OR p_override_prot = cwms_util.false_num
      THEN
         l_override_prot := 'F';
      ELSIF p_override_prot = cwms_util.true_num
      THEN
         l_override_prot := 'T';
      ELSE
         cwms_err.raise('INVALID_T_F_FLAG_OLD', p_override_prot);
      END IF;
      dbms_output.put_line('tag wie gehts2?');
      store_ts (p_cwms_ts_id,
                p_units,
                p_timeseries_data,
                p_store_rule,
                l_override_prot,
                p_versiondate,
             p_office_id
               );
   END store_ts; -- v1.4 --
--   
--
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS -
--   
   PROCEDURE store_ts (
      p_cwms_ts_id   IN   VARCHAR2,
      p_units             IN   VARCHAR2,
      p_timeseries_data   IN   tsv_array,
      p_store_rule        IN   VARCHAR2 DEFAULT NULL,
      p_override_prot     IN   VARCHAR2 DEFAULT 'F',
      p_version_date      IN   DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_id           VARCHAR2 (16);
      t1count               NUMBER;
      t2count               NUMBER;
      l_ucount              NUMBER;
      l_store_date          TIMESTAMP ( 3 )  DEFAULT SYSTIMESTAMP;
      l_ts_code             NUMBER;
      l_interval_id         VARCHAR2 (100);
      l_interval_value      NUMBER;
      l_local_tz_code       NUMBER;
      l_tz_name             VARCHAR2 (28) := 'UTC';
      l_utc_offset          NUMBER;
      existing_utc_offset   NUMBER;
      table_cnt             NUMBER;
      mindate               DATE;
      maxdate               DATE;
      l_sql_txt             VARCHAR2 (10000);
      l_override_prot       BOOLEAN;
      l_version_date        DATE;
   BEGIN
      dbms_application_info.set_module('cwms_ts_store.store_ts','get tscode from ts_id');
    cwms_apex.aa1(to_char(sysdate, 'YYYY-MM-DD HH24:MI') || 'store_ts: ' || p_cwms_ts_id);

      -- set default values, don't be fooled by NULL as an actual argument

      if p_office_id is null 
      then
         l_office_id := cwms_util.user_office_id;
         --
         if l_office_id = 'UNK'
         then
           cwms_err.RAISE ('INVALID_OFFICE_ID', 'Unkown');
         end if;
         --
       else                           
         l_office_id := p_office_id;
       end if;

       l_version_date   := nvl(p_version_date, cwms_util.non_versioned);
   
      if NVL(p_override_prot, 'F') = 'F' 
      then
         l_override_prot := FALSE;
      else
           l_override_prot := TRUE;
      end if;
   
      dbms_application_info.set_action('Determine utc_offset of incoming data set');
   
       select regexp_substr(p_cwms_ts_id,'[^.]+',1,4) interval_id 
        into l_interval_id 
        from dual;
   
   begin
      select i.interval 
        into l_interval_value 
       from cwms_interval i 
       where upper(i.interval_id) = upper(l_interval_id);
     exception
     when NO_DATA_FOUND then
       raise_application_error(-20110, 'ERROR: ' || l_interval_id || ' is not a valid time series interval', true);
    end;    
   
   dbms_application_info.set_action('Find or create a TS_CODE for your TS Desc');
  
    begin -- BEGIN - Find the TS_CODE 
      
      select ts_code, interval_utc_offset 
        into l_ts_code, existing_utc_offset
       from mv_CWMS_TS_ID m 
       where upper(m.CWMS_TS_ID) = upper(p_cwms_ts_id)
        and m.db_OFFICE_ID = upper(l_office_id);
       
    exception
    when no_data_found then
      /*
      Exception is thrown when the Time Series Description passed 
      does not exist in the database for the office_id. If this is
      the case a new TS_CODE will be created for the Time Series 
      Descriptor. 
     */
      
      create_ts_code(p_ts_code=>l_ts_code, 
                     p_office_id=>l_office_id, 
                     p_cwms_ts_id=>p_cwms_ts_id, 
                     p_utc_offset=> cwms_util.UTC_OFFSET_UNDEFINED);
      
      existing_utc_offset := cwms_util.UTC_OFFSET_UNDEFINED;
 
    end; -- END - Find TS_CODE

    if l_ts_code is null then
      raise_application_error(-20105, 'Unable to create or locate ts_code for '||p_cwms_ts_id, true);
    end if;
    
    IF l_interval_value > 0 
    THEN 
     
      dbms_application_info.set_action('Incoming data set has a regular interval, confirm data set matches interval_id');
      
      SELECT time_zone_code 
        INTO l_local_tz_code
        FROM at_cwms_ts_spec
       WHERE ts_code = l_ts_code;
      IF l_local_tz_code IS NOT NULL AND l_local_tz_code != 0 THEN
         SELECT time_zone_name
           INTO l_tz_name
           FROM cwms_time_zone
          WHERE time_zone_code = l_local_tz_code;
      END IF;
      BEGIN
         execute IMMEDIATE REPLACE('
         SELECT DISTINCT MOD ( ROUND (
                                     ( CAST ((date_time at time zone ''$TZ'') AS DATE)
                                       - TRUNC (CAST ((date_time at time zone ''$TZ'') AS DATE))
                                     ) * 1440, 
                                     0
                                   ),
                               :l_interval_value
                             )
               INTO :l_tz_name
               FROM TABLE (:p_timeseries_data)', '$TZ', l_tz_name) INTO l_utc_offset using l_interval_value, p_timeseries_data;
      EXCEPTION
        WHEN NO_DATA_FOUND
          THEN 
	       dbms_application_info.set_action('Returning due to no data provided');
          RETURN; -- Have already created TS_CODE if it didn't exist
        WHEN TOO_MANY_ROWS 
          THEN
          raise_application_error(-20110, 'ERROR: Incoming data set appears to contain irregular data. Unable to store data for '||p_cwms_ts_id, true);
      END;
      
      IF l_local_tz_code IS NOT NULL THEN
         DECLARE
            l_offset_str VARCHAR2(8);
            l_parts      cwms_util.str_tab_t;
            l_hours      INTEGER;
            l_minutes    INTEGER;
         BEGIN
            dbms_application_info.set_action('Modify utc offset for LRTS.');
            l_offset_str := rtrim(tz_offset(l_tz_name), chr(0));
            l_parts      := cwms_util.split_text(l_offset_str, ':');
            l_hours      := to_number(l_parts(1));
            l_minutes    := to_number(l_parts(2));
            IF l_hours < 0 THEN
               l_minutes := 60 * l_hours - l_minutes;
            ELSE
               l_minutes := 60 * l_hours + l_minutes;
            END IF;
            l_utc_offset := l_utc_offset - l_minutes;
            if l_utc_offset < 0 then
               l_utc_offset := l_utc_offset + l_interval_value;
            end if;
         END;
      END IF;


      dbms_application_info.set_action('Check utc_offset against the dataset''s and/or set an undefined utc_offset');
      
      if existing_utc_offset = cwms_util.UTC_OFFSET_UNDEFINED then
       -- Existing TS_Code did not have a defined UTC_OFFSET, so set it equal to the offset of this data set.

       update at_cwms_ts_spec acts
         set acts.INTERVAL_UTC_OFFSET = l_utc_offset
       where acts.TS_CODE = l_ts_code;

      elsif existing_utc_offset != l_utc_offset then
       -- Existing TS_Code's UTC_OFFSET does not match the offset of the data set - so storage of data set fails.

        raise_application_error(-20101, 'Incoming Data Set''s UTC_OFFSET does not match UTC_OFFSET of previously stored data - data set was NOT stored', true);

      end if; 
     
   else
   
     dbms_application_info.set_action('Incoming data set is irregular');
     
      l_utc_offset := cwms_util.UTC_OFFSET_IRREGULAR;
   
    end if;   

    dbms_application_info.set_action('check for unit conversion factors');


      SELECT COUNT (*)
        INTO l_ucount
        FROM at_cwms_ts_spec s,
             at_parameter ap,
             cwms_unit_conversion c,
             cwms_base_parameter p,
             cwms_unit u
       WHERE s.ts_code = l_ts_code
         AND s.parameter_code = ap.parameter_code
         AND ap.base_parameter_code =p.base_parameter_code
         AND p.unit_code = c.from_unit_code
         AND c.to_unit_code = u.unit_code
         AND u.unit_id = p_units;


      if l_ucount <> 1 
      then
         raise_application_error(-20103, 'Requested unit conversion is not available', true);
      end if;

    select count(*) 
      into table_cnt
      from at_ts_table_properties;

   -- 
   -- Determine the min and max date in the dataset, convert 
   -- the min and max dates to GMT dates.
   -- The min and max dates are used to determine which 
   -- at_tsv tables need to be accessed during the store.
   --
          
    if table_cnt>1 then 
      select min(CAST((t.date_time AT TIME ZONE 'GMT') AS DATE)), 
            max(CAST((t.date_time AT TIME ZONE 'GMT') AS DATE))
        into mindate, maxdate 
       from TABLE(cast(p_timeseries_data as tsv_array)) t;
    end if;

   
   dbms_output.put_line('*****************************'         || CHR(10) ||
                        'IN STORE_TS'                           || CHR(10) ||
                   'TS Description: ' || p_cwms_ts_id || CHR(10) ||
                   '       TS CODE: ' || l_ts_code           || CHR(10) ||
                   '    Store Rule: ' || p_store_rule      || CHR(10) ||
                   '      Override: ' || p_override_prot   || CHR(10) ||
                   '*****************************');

   CASE
   WHEN l_override_prot and upper(p_store_rule) = cwms_util.replace_all 
   THEN
      --
      --**********************************
      -- CASE 1 - Store Rule: REPLACE ALL 
      --          Override:   TRUE  
      --**********************************
      --
      dbms_application_info.set_action('merge into table, override, replace_all ');
      dbms_output.put_line('CASE 1: store_all override: TRUE');
      dbms_output.put_line('CASE 1: table_cnt = ' || table_cnt);
     
      IF table_cnt=1
      THEN
   
         MERGE INTO at_tsv t1
            USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                          (t.value * c.factor + c.offset) VALUE, t.quality_code
                     FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                          at_cwms_ts_spec s,
                          at_parameter ap,
                          cwms_unit_conversion c,
                          cwms_base_parameter p,
                          cwms_unit u
                    WHERE s.ts_code = l_ts_code
                      AND s.parameter_code = ap.parameter_code
                      AND ap.base_parameter_code = p.base_parameter_code
                      AND p.unit_code = c.to_unit_code
                      AND c.from_unit_code = u.unit_code
                      AND u.unit_id = p_units) t2
            ON (    t1.ts_code = l_ts_code
                AND t1.date_time = t2.date_time
                AND t1.version_date = l_version_date)
            WHEN MATCHED THEN
               UPDATE
                  SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
                      t1.quality_code = t2.quality_code
            WHEN NOT MATCHED THEN
               INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
                       version_date)
               VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
                       l_version_date);

         ELSE
 
            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                          where start_date<=maxdate 
                         and end_date>mindate)
              LOOP

               dbms_output.put_line('CASE 1: multi-table storage: ' || x.table_name);

               l_sql_txt:=
                  ' merge into '||x.table_name||' t1
                  using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                              (t.value * c.factor + c.offset) value, 
                           t.quality_code 
                            from TABLE(cast(:p_timeseries_data as tsv_array)) t,
                            at_cwms_ts_spec s, 
                            at_parameter ap,
                            cwms_unit_conversion c, 
                            cwms_base_parameter p, 
                            cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
                        and ap.base_parameter_code = p.base_parameter_code
                               and p.unit_code      =  c.to_unit_code
                               and c.from_unit_code   =  u.unit_code
                               and u.UNIT_ID        =  :p_units
                               and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                               and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'') 
                        ) t2
                        on (    t1.ts_code      = :l_ts_code 
                      and t1.date_time    = t2.date_time 
                     and t1.version_date = :l_version_date )
                      when matched then
                      update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                      when not matched then 
                      insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
                  values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';

               dbms_output.put_line('CASE 1: exectuing dynamic merge statement');
        
                 execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date, 
                                   l_ts_code, l_version_date, 
                                   l_store_date, 
                                   l_ts_code, l_store_date, l_version_date;
          
                dbms_output.put_line('CASE 1: merge stament completed');
        
              END LOOP;
      
            dbms_output.put_line('CASE 1: multi table store completed');
      
         END IF;
 
       WHEN NOT l_override_prot and upper(p_store_rule) = cwms_util.replace_all
      THEN
         --
         --*************************************
         -- CASE 2 - Store Rule: REPLACE ALL -
         --         Override:   FALSE -
         --*************************************
         -- 
         dbms_application_info.set_action('CASE 2: merge into  table, no override, replace_all ');
         dbms_output.put_line('CASE 2: store_all override: FALSE');
         dbms_output.put_line('CASE 2: table_cnt = ' || table_cnt);
          
           IF table_cnt=1
         THEN
     
              dbms_output.put_line('CASE 2: single table');

            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN MATCHED THEN
                  UPDATE
                     SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
                         t1.quality_code = t2.quality_code
                     WHERE    (t1.quality_code IN (SELECT quality_code
                                                     FROM cwms_data_quality q
                                                    WHERE q.protection_id = 'UNPROTECTED')
                              )
                           OR (t2.quality_code IN (SELECT quality_code
                                                     FROM cwms_data_quality q
                                                    WHERE q.protection_id = 'PROTECTED'))
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
                          version_date)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
                          l_version_date);
         ELSE
        
              dbms_output.put_line('CASE 2: number of at_tables in schema: ' || table_cnt);
      
            FOR x IN (select start_date, end_date, table_name 
                         from at_ts_table_properties 
                         where start_date<=maxdate 
                          and end_date>mindate)
            LOOP
      
               dbms_output.put_line('CASE 2: begin storage loop, table_name: ' || x.table_name);

               l_sql_txt:=
                  ' merge into '||x.table_name||' t1 
                     using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                              (t.value * c.factor + c.offset) value, 
                           t.quality_code 
                            from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                            at_cwms_ts_spec s, 
                            at_parameter ap,
                            cwms_unit_conversion c, 
                            cwms_base_parameter p, 
                            cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
                               AND ap.base_parameter_code = p.base_parameter_code
                                and p.unit_code      =  c.to_unit_code 
                                and c.from_unit_code   =  u.unit_code 
                                and u.UNIT_ID        =  :p_units 
                                and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                                and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'') 
                        ) t2
                        on (    t1.ts_code      = :l_ts_code 
                      and t1.date_time    = t2.date_time 
                     and t1.version_date = :l_version_date )
                      when matched then 
                      update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                         where (t1.quality_code in (select quality_code 
                                                     from cwms_data_quality q 
                                                   where q.PROTECTION_ID=''UNPROTECTED''
                                                )
                         )
                      or (t2.quality_code in (select quality_code 
                                                      from cwms_data_quality q 
                                                    where q.PROTECTION_ID=''PROTECTED''
                                       )
                        )
                      when not matched then 
                      insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
                     values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code,:l_version_date )
                    ';
                  
               --dbms_output.put_line(l-sql_txt);         

               dbms_output.put_line('CASE 2: Executing dynamic merge statment');
        
                 execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date, 
                                 l_ts_code,l_version_date, 
                                 l_store_date,
                                 l_ts_code, l_store_date, l_version_date;
        
                 dbms_output.put_line('CASE 2: Merge statement completed');
        
              END LOOP;
      
            dbms_output.put_line('CASE 2: done with loop');
      
         END IF;
         
      WHEN upper(p_store_rule) = cwms_util.do_not_replace
      THEN
         --
         --*************************************
         -- CASE 3 - Store Rule: DO NOT REPLACE
         --*************************************
         --  
         dbms_application_info.set_action('merge into table, do_not_replace ');

         IF table_cnt=1
         THEN
         
            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
                          version_date)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
                          l_version_date);

         ELSE
      
            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                       where start_date<=maxdate 
                         and end_date>mindate)
            LOOP

               l_sql_txt:='merge into '||x.table_name||' t1
                      using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                               (t.value * c.factor + c.offset) value, 
                           t.quality_code 
                             from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                            at_cwms_ts_spec s, 
                            at_parameter ap,
                            cwms_unit_conversion c, 
                            cwms_base_parameter p, 
                            cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
                        and ap.base_parameter_code = p.base_parameter_code
                                and p.unit_code      =  c.to_unit_code
                                and c.from_unit_code   =  u.unit_code
                                and u.UNIT_ID        =  :p_units
                                and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                                and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'') 
                         ) t2
                         on (    t1.ts_code      = :l_ts_code 
                       and t1.date_time    = t2.date_time 
                      and t1.version_date = :l_version_date)
                       when not matched then
                       insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
                       values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';
         
               execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date, 
                                 l_ts_code, l_version_date,  
                                 l_ts_code, l_store_date, l_version_date;
            END LOOP;
            
         END IF;
      WHEN upper(p_store_rule) = cwms_util.replace_missing_values_only
      THEN
         --
         --***************************************************
         -- CASE 4 - Store Rule: REPLACE MISSING VALUES ONLY -
         --*************************************************
         --
         dbms_application_info.set_action('merge into table, replace_missing_values_only');
   
         IF table_cnt=1
         THEN

            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN MATCHED THEN
                  UPDATE
                     SET t1.VALUE = t2.VALUE, t1.quality_code = t2.quality_code,
                         t1.data_entry_date = l_store_date
                     WHERE t1.quality_code IN (SELECT quality_code
                                                 FROM cwms_data_quality q
                                                WHERE q.validity_id = 'MISSING')
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code);

         ELSE
      
            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                       where start_date<=maxdate 
                        and end_date>mindate)
            LOOP
        
               l_sql_txt:='merge into '||x.table_name||' t1
                      using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                               (t.value * c.factor + c.offset) value, 
                           t.quality_code 
                             from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                            at_cwms_ts_spec s, 
                            at_parameter ap,
                            cwms_unit_conversion c, 
                            cwms_base_parameter p, 
                            cwms_unit u
                             where s.ts_code        =  :l_ts_code
                               and s.parameter_code =  ap.parameter_code
                        and ap.base_parameter_code = p.base_parameter_code
                                and p.unit_code      =  c.to_unit_code
                                and c.from_unit_code   =  u.unit_code
                                and u.UNIT_ID        =  :p_units
                                and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                                and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'')
                         ) t2
                         on (    t1.ts_code      = :l_ts_code 
                       and t1.date_time    = t2.date_time 
                      and t1.version_date = :l_version_date)
                       when matched then 
                       update set t1.value = t2.value, t1.quality_code = t2.quality_code, t1.data_entry_date = :l_store_date 
                          where t1.quality_code in (select quality_code 
                                                from cwms_data_quality q 
                                        where q.VALIDITY_ID=''MISSING'')
                       when not matched then 
                       insert (ts_code,  date_time,    data_entry_date, value,    quality_code,    version_date ) 
                        values (:l_ts_code, t2.date_time, :l_store_date,      t2.value, t2.quality_code, :l_version_date )';
 
                execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date, 
                                 l_ts_code, l_version_date, 
                                 l_store_date, 
                                 l_ts_code, l_store_date, l_version_date;
            END LOOP;
            
         END IF;
      WHEN l_override_prot AND upper(p_store_rule) = cwms_util.replace_with_non_missing
      THEN
         --
         --*******************************************
         -- CASE 5 - Store Rule: REPLACE W/NON-MISSING -
         --         Override:   TRUE -
         --*******************************************
         --  
         dbms_application_info.set_action('merge into table, override, replace_with_non_missing ');

         IF table_cnt=1
         THEN
         
            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u,
                             cwms_data_quality q
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND q.quality_code = t.quality_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN MATCHED THEN
                  UPDATE
                     SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
                         t1.quality_code = t2.quality_code
                     WHERE t2.quality_code NOT IN (SELECT quality_code
                                                     FROM cwms_data_quality
                                                    WHERE validity_id = 'MISSING')
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code);

         ELSE
   
            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                       where start_date <= maxdate 
                         and end_date   >  mindate)
            LOOP
        
               l_sql_txt:='merge into '||x.table_name||' t1
                      using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                               (t.value * c.factor + c.offset) value, 
                           t.quality_code 
                          from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                             at_cwms_ts_spec s, 
                             at_parameter ap,
                           cwms_unit_conversion c, 
                           cwms_base_parameter p, 
                           cwms_unit u, 
                           cwms_data_quality q
                              where s.ts_code        =  :l_ts_code
                                and s.parameter_code =  ap.parameter_code
                        and ap.base_parameter_code = p.base_parameter_code
                                and q.quality_code   =  t.quality_code
                                and p.unit_code      =  c.to_unit_code
                                and c.from_unit_code   =  u.unit_code
                                and u.UNIT_ID        =  :p_units
                                and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                                and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'')   
                      ) t2
                         on (    t1.ts_code      = :l_ts_code 
                       and t1.date_time    = t2.date_time 
                      and t1.version_date = :l_version_date)
                       when matched then 
                    update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                    where t2.quality_code not in (select quality_code
                                                    from cwms_data_quality
                                           where validity_id = ''MISSING'')                            
                       when not matched then 
                    insert (ts_code,  date_time,    data_entry_date, value,    quality_code,    version_date ) 
                   values (:l_ts_code, t2.date_time, :l_store_date,      t2.value, t2.quality_code, :l_version_date )';  
   
               execute immediate l_sql_txt using p_timeseries_data, 
                              l_ts_code, p_units, x.start_date, x.end_date, 
                              l_ts_code, l_version_date, 
                              l_store_date, 
                              l_ts_code, l_store_date, l_version_date;
            END LOOP;
         END IF;

      WHEN NOT l_override_prot AND upper(p_store_rule) = cwms_util.replace_with_non_missing
      THEN
         --
         --******************************************* 
         -- Case 6 - Store Rule: Replace w/Non-Missing -
         --         Override:   FALSE -
         --*******************************************
         --  
         dbms_application_info.set_action('merge into table, no override, replace_with_non_missing ');

         IF table_cnt=1
         THEN 
  
            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u,
                             cwms_data_quality q
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND q.quality_code = t.quality_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN MATCHED THEN
                  UPDATE
                     SET t1.VALUE = t2.VALUE, t1.data_entry_date = l_store_date,
                         t1.quality_code = t2.quality_code
                     WHERE     (   (t1.quality_code IN (
                                                     SELECT quality_code
                                                       FROM cwms_data_quality q
                                                      WHERE q.protection_id =
                                                                             'UNPROTECTED')
                                   )
                                OR (t2.quality_code IN (
                                                       SELECT quality_code
                                                         FROM cwms_data_quality q
                                                        WHERE q.protection_id =
                                                                               'PROTECTED')
                                   )
                               )
                           AND (t2.quality_code NOT IN (SELECT quality_code
                                                          FROM cwms_data_quality q
                                                         WHERE q.validity_id = 'MISSING')
                               )
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code,
                          version_date)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code,
                          l_version_date);

         ELSE

            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                       where start_date<=maxdate 
                         and end_date>mindate)
            LOOP
        
                 l_sql_txt:='merge into '||x.table_name||' t1
                    using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                             (t.value * c.factor + c.offset) value, 
                          t.quality_code 
                        from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                           at_cwms_ts_spec s, 
                           at_parameter ap,
                          cwms_unit_conversion c, 
                          cwms_base_parameter p, 
                          cwms_unit u,  
                          cwms_data_quality q
                            where s.ts_code        =  :l_ts_code
                              and s.parameter_code =  p.parameter_code
                       and ap.base_parameter_code = p.base_parameter_code
                              and q.quality_code   =  t.quality_code
                              and p.unit_code      =  c.to_unit_code
                              and c.from_unit_code   =  u.unit_code
                              and u.UNIT_ID        =  :p_units
                              and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                              and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'')     
                    ) t2
                       on ( t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                     when matched then 
                  update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                        where (  (t1.quality_code in (select quality_code 
                                              from cwms_data_quality q 
                                       where q.PROTECTION_ID=''UNPROTECTED''
                                      )
                          )
                           or (t2.quality_code in (select quality_code 
                                                    from cwms_data_quality q 
                                                  where q.PROTECTION_ID=''PROTECTED''
                                         )
                             )
                       )
                    and (t2.quality_code not in (select quality_code 
                                                        from cwms_data_quality q 
                                                      where q.VALIDITY_ID=''MISSING''
                                             )
                          )
                     when not matched then 
                  insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
                  values (:l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';
   
               execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date, 
                                 l_ts_code, l_version_date, 
                                 l_store_date, 
                                 l_ts_code, l_store_date, l_version_date;
            END LOOP;
            
         END IF;
      WHEN NOT l_override_prot AND upper(p_store_rule)=cwms_util.delete_insert
      THEN
         --
         --*************************************
         -- CASE 7 - Store Rule: DELETE - INSERT -
         --         Override:   FALSE -
         --*************************************
         --  
         dbms_application_info.set_action('delete/merge from table, no override, delete_insert ');
         dbms_output.put_line('CASE 7: STORE_TS rule: delete-insert, FALSE');
         dbms_output.put_line('CASE 7: table_cnt: ' || table_cnt);

         IF table_cnt=1
         THEN
     
              dbms_output.put_line('CASE 7: Single Table Section');
      
            DELETE FROM at_tsv t1
                  WHERE date_time
                           BETWEEN (SELECT MIN (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
                                      FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
                               AND (SELECT MAX (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
                                      FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
                    AND t1.ts_code = l_ts_code
                    AND t1.version_date = l_version_date
                    AND t1.quality_code IN (SELECT quality_code
                                              FROM cwms_data_quality q
                                             WHERE q.protection_id = 'UNPROTECTED');

            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code)
               WHEN MATCHED THEN
                  UPDATE
                     SET t1.VALUE = t2.VALUE, t1.quality_code = t2.quality_code,
                         t1.data_entry_date = l_store_date
                     WHERE t2.quality_code IN (SELECT quality_code
                                                 FROM cwms_data_quality q
                                                WHERE q.protection_id = 'PROTECTED');
                                                
         ELSE
     
              dbms_output.put_line('CASE 7: Multiple Table Section');

            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                       where start_date <= maxdate 
                         and end_date   >  mindate)
            LOOP
        
                 dbms_output.put_line('CASE 7: preparing DELETE FROM dynamic sql for table: ' || x.table_name);
      
               l_sql_txt:=' delete from '||x.table_name||' t1
                      where date_time between (select min(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
                                            from TABLE(cast(:p_timeseries_data as tsv_array)) t) 
                                and (select max(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
                                       from TABLE(cast(:p_timeseries_data as tsv_array)) t)
                        and t1.ts_code = :l_ts_code
                        and t1.version_date = :l_version_date
                        and t1.quality_code in (select quality_code 
                                            from cwms_data_quality q 
                                     where q.PROTECTION_ID=''UNPROTECTED'')';

               --dbms_output.put_line(l_sql_txt);        
               dbms_output.put_line('CASE 7: Executing DELETE FROM dynamic sql for table: ' || x.table_name);

               execute immediate l_sql_txt using p_timeseries_data, p_timeseries_data, l_ts_code, l_version_date;

               dbms_output.put_line('CASE 7: preparing MERGE INTO dynamic sql for table: ' || x.table_name);

               l_sql_txt:='merge into '||x.table_name||' t1
                    using (select  CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time,
                              (t.value * c.factor + c.offset) value, 
                           t.quality_code 
                        from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                           at_cwms_ts_spec s,
                           at_parameter ap,
                          cwms_unit_conversion c, 
                          cwms_base_parameter p, 
                          cwms_unit u
                            where s.ts_code        =  :l_ts_code
                              and s.parameter_code =  ap.parameter_code
                              and ap.base_parameter_code = p.base_parameter_code
                              and p.unit_code      =  c.to_unit_code
                              and c.from_unit_code   =  u.unit_code
                              and u.UNIT_ID        =  :p_units
                              and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                              and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'')   
                    ) t2
                       on (    t1.ts_code      = :l_ts_code 
                      and t1.date_time    =  t2.date_time 
                     and t1.version_date = :l_version_date)
                     when not matched then
                  insert (ts_code, date_time, data_entry_date, value, quality_code, version_date ) 
                  values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )
                   when matched then 
                  update set t1.value = t2.value,  t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                        where t2.quality_code in (select quality_code from cwms_data_quality q where q.PROTECTION_ID=''PROTECTED'')
                 ';
             
                dbms_output.put_line('CASE 7: Executing MERGE INTO dynamic sql for table: ' || x.table_name);
               --dbms_output.put_line(l_sql_txt);
        
                 execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date, 
                                 l_ts_code, l_version_date, 
                                 l_ts_code, l_store_date, l_version_date,
                                 l_store_date;
        
                 dbms_output.put_line('CASE 7: Merge completed.');
        
              END LOOP;
      
            dbms_output.put_line('CASE 7: delete-insert FALSE Completed.');
            
         END IF;
 
       WHEN l_override_prot AND upper(p_store_rule) = cwms_util.delete_insert
      THEN
         --
         --************************************* 
         --CASE 8 - Store Rule: DELETE - INSERT -
         --         Override:   TRUE -
         --*************************************
         -- 
         dbms_application_info.set_action('delete/merge from  table, override, delete_insert ');
         dbms_output.put_line('CASE 8: STORE_TS rule: delete-insert, TRUE');
         dbms_output.put_line('CASE 8: table_cnt: ' || table_cnt);
      
         IF table_cnt=1
         THEN 

            dbms_output.put_line('CASE 8: Single Table Section');
     
            DELETE FROM at_tsv t1
                  WHERE date_time
                           BETWEEN (SELECT MIN (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
                                      FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
                               AND (SELECT MAX (CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE))
                                      FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t)
                    AND t1.ts_code = l_ts_code
                    AND t1.version_date = l_version_date;
            
            MERGE INTO at_tsv t1
               USING (SELECT CAST ((t.date_time AT TIME ZONE 'GMT') AS DATE) date_time,
                             (t.value * c.factor + c.offset) VALUE, t.quality_code
                        FROM TABLE (CAST (p_timeseries_data AS tsv_array)) t,
                             at_cwms_ts_spec s,
                             at_parameter ap,
                             cwms_unit_conversion c,
                             cwms_base_parameter p,
                             cwms_unit u
                       WHERE s.ts_code = l_ts_code
                         AND s.parameter_code = ap.parameter_code
                         AND ap.base_parameter_code = p.base_parameter_code
                         AND p.unit_code = c.to_unit_code
                         AND c.from_unit_code = u.unit_code
                         AND u.unit_id = p_units) t2
               ON (    t1.ts_code = l_ts_code
                   AND t1.date_time = t2.date_time
                   AND t1.version_date = l_version_date)
               WHEN NOT MATCHED THEN
                  INSERT (ts_code, date_time, data_entry_date, VALUE, quality_code)
                  VALUES (l_ts_code, t2.date_time, l_store_date, t2.VALUE, t2.quality_code);

         ELSE
   
            FOR x IN (select start_date, end_date, table_name 
                        from at_ts_table_properties 
                       where start_date<=maxdate 
                         and end_date>mindate)
            LOOP
        
                 dbms_output.put_line('CASE 8: preparing DELETE FROM dynamic sql for av_tsv view');

               l_sql_txt:='delete from '||x.table_name||' t1
                     where date_time between (select min(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
                                           from TABLE(cast(:p_timeseries_data as tsv_array)) t) 
                                 and (select max(CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE)) 
                                      from TABLE(cast(:p_timeseries_data as tsv_array)) t)
                       and t1.ts_code =: l_tcode
                       and t1.version_date = :l_version_date';

                  --dbms_output.put_line(l_sql_txt);
               dbms_output.put_line('CASE 8: executing DELETE FROM dynamic sql for av_tsv view');

                execute immediate l_sql_txt using p_timeseries_data, p_timeseries_data, l_ts_code, l_version_date;

               dbms_output.put_line('CASE 8: preparing MERGE INTO dynamic sql for table: ' || x.table_name);
        
                 l_sql_txt:='merge into '||x.table_name||' t1
                    using (select CAST((t.date_time AT TIME ZONE ''GMT'') AS DATE) date_time, 
                             (t.value * c.factor + c.offset) value, 
                          t.quality_code 
                        from TABLE(cast(:p_timeseries_data as tsv_array)) t, 
                           at_cwms_ts_spec s, 
                           at_parameter ap,
                          cwms_unit_conversion c, 
                          cwms_base_parameter p, 
                          cwms_unit u
                            where s.ts_code        =  :l_ts_code
                              and s.parameter_code =  ap.parameter_code
                              AND ap.base_parameter_code = p.base_parameter_code
                              and p.unit_code      =  c.to_unit_code
                              and c.from_unit_code   =  u.unit_code
                              and u.UNIT_ID        =  :p_units
                              and date_time        >= from_tz(cast(:start_date as timestamp), ''UTC'') 
                              and date_time        <  from_tz(cast(:end_date as timestamp), ''UTC'') 
                    ) t2
                       on (    t1.ts_code      = :l_ts_code 
                      and t1.date_time    = t2.date_time 
                     and t1.version_date = :l_version_date)
                     when not matched then
                  insert (ts_code, date_time, data_entry_date, value, quality_code,version_date ) 
                  values ( :l_ts_code, t2.date_time, :l_store_date, t2.value, t2.quality_code, :l_version_date )';

               dbms_output.put_line('CASE 8: Executing MERGE INTO dynamic sql for table: ' || x.table_name);

               execute immediate l_sql_txt using p_timeseries_data, 
                                 l_ts_code, p_units, x.start_date, x.end_date,
                                 l_ts_code, l_version_date, 
                                 l_ts_code, l_store_date, l_version_date;
        
                 dbms_output.put_line('CASE 8: Merge completed.');
               
            END LOOP;
      
            dbms_output.put_line('CASE 8: delete-insert TRUE Completed.');
            
         END IF;
      
      ELSE
      
         cwms_err.raise('INVALID_STORE_RULE',nvl(p_store_rule, '<NULL>'));
      
      END CASE;

      COMMIT;

   -----------------------------------------------                                                                    
   -- notify the real-time Oracle->DSS exchange --
   ----------------------------------------------- 
   if cwms_xchg.is_realtime_export(l_ts_code) then 
      dbms_application_info.set_action('queuing time_series_updated message');
      cwms_xchg.time_series_updated(
            l_ts_code, 
            p_cwms_ts_id,
            p_timeseries_data(p_timeseries_data.first).date_time,
            p_timeseries_data(p_timeseries_data.last).date_time);
   end if;
       
   dbms_application_info.set_module(null, null);

   END store_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- STORE_TS - This version is for Python/CxOracle
--
   PROCEDURE store_ts (
      p_cwms_ts_id        IN   VARCHAR2,
      p_units             IN   VARCHAR2,
      p_times             IN   number_array,
      p_values            IN   double_array,
      p_qualities         IN   number_array,
      p_store_rule        IN   VARCHAR2 DEFAULT NULL,
      p_override_prot     IN   VARCHAR2 DEFAULT 'F',
      p_version_date      IN   DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_timeseries_data tsv_array := tsv_array();
      i binary_integer;
   BEGIN
      if p_values.count != p_times.count then
         cwms_err.raise('ERROR', 'Inconsistent number of times and values.');
      end if;
      if p_qualities.count != p_times.count then
         cwms_err.raise('ERROR', 'Inconsistent number of times and qualities.');
      end if;
      l_timeseries_data.extend(p_times.count);
      for i in 1..p_times.count loop
         l_timeseries_data(i) := tsv_type(
            from_tz(cwms_util.to_timestamp(p_times(i)), 'UTC'),
            p_values(i),
            p_qualities(i));
      end loop;
      store_ts(
         p_cwms_ts_id,
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
		p_cwms_ts_id IN varchar2,
      p_units         IN varchar2,
      p_times         IN number_tab_t,
      p_values        IN number_tab_t,
      p_qualities     IN number_tab_t,
      p_store_rule    IN varchar2 DEFAULT NULL ,
      p_override_prot IN varchar2 DEFAULT 'F' ,
      p_version_date  IN date DEFAULT cwms_util.non_versioned ,
      p_office_id     IN varchar2 DEFAULT NULL
   )
   IS
      l_timeseries_data tsv_array := tsv_array();
      i binary_integer;
   BEGIN
      if p_values.count != p_times.count then
         cwms_err.raise('ERROR', 'Inconsistent number of times and values.');
      end if;
      if p_qualities.count != p_times.count then
         cwms_err.raise('ERROR', 'Inconsistent number of times and qualities.');
      end if;
      l_timeseries_data.extend(p_times.count);
      for i in 1..p_times.count loop
         l_timeseries_data(i) := tsv_type(
            from_tz(cwms_util.to_timestamp(p_times(i)), 'UTC'),
            p_values(i),
            p_qualities(i));
      end loop;
      store_ts(
         p_cwms_ts_id,
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
PROCEDURE store_ts_multi (
   p_timeseries_array  IN   timeseries_array,
   p_store_rule        IN   VARCHAR2 DEFAULT NULL,
   p_override_prot     IN   VARCHAR2 DEFAULT 'F',
   p_version_date      IN   DATE DEFAULT cwms_util.non_versioned,
   p_office_id         IN   VARCHAR2 DEFAULT NULL
)
IS
   l_timeseries timeseries_type;
BEGIN
   dbms_application_info.set_module(
      'cwms_ts_store.store_ts_multi',
      'selecting time series from input');
   for l_timeseries in (select * from table(p_timeseries_array)) loop
      dbms_application_info.set_module(
         'cwms_ts_store.store_ts_multi',
         'calling store_ts');
      store_ts(
         l_timeseries.tsid, 
         l_timeseries.unit, 
         l_timeseries.data, 
         p_store_rule,
         p_override_prot, 
         p_version_date, 
         p_office_id);
   end loop;
   
   dbms_application_info.set_module(null, null);
   
END store_ts_multi;

--
--*******************************************************************   --
--** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE ****   --
--
-- DELETE_TS_CLEANUP -
--
/* Formatted on 2006/12/21 16:35 (Formatter Plus v4.8.8) */
PROCEDURE delete_ts_cleanup (
   p_ts_code_old     IN   NUMBER,
   p_ts_code_new     IN   NUMBER,
   p_delete_action   IN   VARCHAR2
)
IS
BEGIN
   IF p_delete_action = cwms_util.delete_ts_cascade
   THEN
      NULL;                -- NOTE TO GERHARD Need to think about cleaning up
                           -- all of the dependancies when deleting.
      delete from at_shef_decode
      where ts_code = p_ts_code_old;
      
   ELSIF p_delete_action = cwms_util.delete_ts_data
   THEN
      UPDATE at_transform_criteria
         SET ts_code = p_ts_code_new
       WHERE ts_code = p_ts_code_old;

      --
      UPDATE at_transform_criteria
         SET resultant_ts_code = p_ts_code_new
       WHERE resultant_ts_code = p_ts_code_old;

      --
      UPDATE at_alarm
         SET ts_code = p_ts_code_new
       WHERE ts_code = p_ts_code_old;

      --
      UPDATE at_screening
         SET ts_code = p_ts_code_new
       WHERE ts_code = p_ts_code_old;
   END IF;
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
/* Formatted on 2006/12/21 16:23 (Formatter Plus v4.8.8) */
/* Formatted on 2006/12/21 16:33 (Formatter Plus v4.8.8) */
PROCEDURE delete_ts (
   p_cwms_ts_id      IN   VARCHAR2,
   p_delete_action   IN   VARCHAR2 DEFAULT cwms_util.delete_ts_id,
   p_db_office_id    IN   VARCHAR2 DEFAULT NULL
)
IS
   l_db_office_code number := cwms_util.GET_OFFICE_CODE(p_db_office_id);
BEGIN
   delete_ts (p_cwms_ts_id       => p_cwms_ts_id,
              p_delete_action    => p_delete_action,
              p_db_office_code   => l_db_office_code);
END;

PROCEDURE delete_ts (
   p_cwms_ts_id      IN   VARCHAR2,
   p_delete_action   IN   VARCHAR2 DEFAULT cwms_util.delete_ts_id,
   p_db_office_code  IN   NUMBER DEFAULT NULL
)
IS
   l_db_office_code  NUMBER := p_db_office_code;
   l_ts_code         NUMBER;
   l_count           NUMBER;
   l_ts_code_new     NUMBER        := NULL;
   l_delete_action   VARCHAR2 (22)
                       := UPPER (NVL (p_delete_action, cwms_util.delete_ts_id));
   l_delete_date     DATE          := SYSDATE;
   l_tmp_del_date    DATE          := l_delete_date + 1;
--
BEGIN
   --
   IF p_db_office_code IS NULL
   THEN
      l_db_office_code := cwms_util.GET_OFFICE_CODE(null);
   END IF;

   --
   BEGIN
      SELECT ts_code
        INTO l_ts_code
        FROM mv_cwms_ts_id mcts
       WHERE UPPER (mcts.cwms_ts_id) = UPPER (p_cwms_ts_id)
         AND mcts.db_office_code = l_db_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('TS_ID_NOT_FOUND', p_cwms_ts_id);
   END;

   BEGIN
      SELECT ts_code
        INTO l_ts_code
        FROM at_cwms_ts_spec a
       WHERE a.TS_CODE = l_ts_code
         AND a.DELETE_DATE is null;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('TS_ID_NOT_FOUND', p_cwms_ts_id);
   END;

          --
   -- Process Depricated delete_actions -
   IF l_delete_action = cwms_util.delete_key
   THEN
      l_delete_action := cwms_util.delete_ts_id;
   END IF;

   IF l_delete_action = cwms_util.delete_all
   THEN
      l_delete_action := cwms_util.delete_ts_cascade;
   END IF;
   IF l_delete_action = cwms_util.delete_data
   THEN
      l_delete_action := cwms_util.delete_ts_data;
   END IF;

   IF l_delete_action = cwms_util.delete_ts_id
   THEN
      SELECT COUNT (*)
        INTO l_count
        FROM av_tsv
       WHERE ts_code = l_ts_code;

      --
      IF l_count = 0
      THEN
         UPDATE at_cwms_ts_spec
            SET location_code = 0,
                delete_date = l_delete_date
          WHERE ts_code = l_ts_code;
      ELSE
         cwms_err.RAISE ('GENERIC_ERROR',
                            'cwms_ts_id: '
                         || p_cwms_ts_id
                         || ' contains data. Cannot use the DELETE TS ID action'
                        );
      END IF;
   --
   --
   ELSIF    l_delete_action = cwms_util.delete_ts_cascade
         OR l_delete_action = cwms_util.delete_ts_data
   THEN
      -- If deleting the data only, then a new replacement ts_code must --
      -- be created --
      --
      IF l_delete_action = cwms_util.delete_ts_data
      THEN
         -- Create replacement ts_id - temporarily disabled by setting a --
         -- delete date - need to do this so as not to violate unique    --
         -- constraint --
         SELECT cwms_seq.NEXTVAL
           INTO l_ts_code_new
           FROM DUAL;

         INSERT INTO at_cwms_ts_spec
            SELECT l_ts_code_new, location_code, parameter_code,
                   parameter_type_code, interval_code, duration_code, VERSION,
                   description, interval_utc_offset,
                   interval_forward, interval_backward, interval_offset_id,
                   time_zone_code, version_flag, migrate_ver_flag,
                   active_flag, l_tmp_del_date, data_source
              FROM at_cwms_ts_spec acts
             WHERE acts.ts_code = l_ts_code;
      END IF;

      -- Delete the timeseries id --
      UPDATE at_cwms_ts_spec
         SET location_code = 0,
             delete_date = l_delete_date
       WHERE ts_code = l_ts_code;

      IF l_delete_action = cwms_util.delete_ts_data
      THEN
         -- Activate the replacement ts_id by setting the delete_date to null --
         UPDATE at_cwms_ts_spec
            SET delete_date = NULL
          WHERE ts_code = l_ts_code_new;
      END IF;
   --
   ELSE
      cwms_err.RAISE ('INVALID_DELETE_ACTION', p_delete_action);
   END IF;

   --
   COMMIT;
   --
   delete_ts_cleanup (l_ts_code, l_ts_code_new, l_delete_action);
--
END delete_ts;
--
--*******************************************************************   --
--*******************************************************************   --
--
-- RENAME...
--
--v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE rename_ts (
      p_office_id             IN   VARCHAR2,
      p_timeseries_desc_old   IN   VARCHAR2,
      p_timeseries_desc_new   IN   VARCHAR2
   )
--^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   IS
      l_utc_offset   NUMBER := NULL;
   BEGIN
      rename_ts (p_timeseries_desc_old,
                 p_timeseries_desc_new,
                 l_utc_offset,
                 p_office_id
                );
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
   PROCEDURE rename_ts (
      p_cwms_ts_id_old   IN   VARCHAR2,
      p_cwms_ts_id_new   IN   VARCHAR2,
      p_utc_offset_new   IN   NUMBER DEFAULT NULL,
      p_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_utc_offset_old            at_cwms_ts_spec.interval_utc_offset%TYPE;
      --
      l_location_code_old         at_cwms_ts_spec.location_code%TYPE;
      l_interval_code_old         cwms_interval.interval_code%TYPE;
      --
      l_base_location_id_new      at_base_location.base_location_id%TYPE;
      l_sub_location_id_new       at_physical_location.sub_location_id%TYPE;
      l_location_new              VARCHAR2 (49);
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
                                        'get ts_code from materialized view'
                                       );
   
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
      l_ts_code_old := cwms_loc.get_ts_code (l_office_id, p_cwms_ts_id_old);
   
   --
   --------------------------------------------------------
   -- Retrieve old codes for the old ts_code...
   --------------------------------------------------------
   --
      SELECT location_code, interval_code, acts.INTERVAL_UTC_OFFSET
        INTO l_location_code_old, l_interval_code_old, l_utc_offset_old
        FROM at_cwms_ts_spec acts
       WHERE ts_code = l_ts_code_old;
   dbms_output.put_line('l_utc_offset_old-1: ' || l_utc_offset_old);
   --------------------------------------------------------
   -- Confirm new cwms_ts_id does not exist...
   --------------------------------------------------------
      BEGIN
         --
         l_ts_code_new := cwms_loc.get_ts_code (l_office_id, p_cwms_ts_id_new);
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
                         l_office_id || '.' || p_cwms_ts_id_new
                        );
      END IF;
   
   ------------------------------------------------------------------
   -- Parse cwms_id_new --
   ------------------------------------------------------------------
      parse_ts (p_cwms_ts_id_new,
                l_base_location_id_new,
                l_sub_location_id_new,
                l_base_parameter_id_new,
                l_sub_parameter_id_new,
                l_parameter_type_id_new,
                l_interval_id_new,
                l_duration_id_new,
                l_version_id_new
               );
      --
      l_location_new :=
         cwms_util.concat_base_sub_id (l_base_location_id_new,
                                       l_sub_location_id_new
                                      );
   
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
   -- Set default utc_offset if null was passed in as new...
   --------------------------------------------------------
      IF p_utc_offset_new IS NULL
      THEN
         dbms_output.put_line('l_utc_offset_old-2: ' || l_utc_offset_old);
         l_utc_offset_new := l_utc_offset_old;
      ELSIF l_interval_code_new = cwms_util.irregular_interval_code
      THEN
         l_utc_offset_new := cwms_util.utc_offset_irregular;
      ELSIF l_utc_offset_new < 0 OR l_utc_offset_new >= l_interval_dur_new
      THEN
            cwms_err.RAISE ('INVALID_UTC_OFFSET',
                            l_utc_offset_new,
                            l_interval_dur_new
                           );
      ELSE
         l_utc_offset_new := p_utc_offset_new;
      END IF;
      dbms_output.put_line('l_utc_offset_new: ' || l_utc_offset_new);
   ---------------------------------------------------
   -- Check whether the ts_code has associated data --
   ---------------------------------------------------
      SELECT COUNT (*)
        INTO l_tmp
        FROM at_tsv
       WHERE ts_code = l_ts_code_old;
   
      l_has_data := l_tmp > 0;
   
   ------------------------------------------------------------------
   -- Perform these checks only if the ts_code has associated data --
   ------------------------------------------------------------------
      IF l_has_data
      THEN
   --------------------------------------------------------------
   -- Do not allow the interval to change, except to irregular --
   --------------------------------------------------------------
         IF     l_interval_code_old <> cwms_util.irregular_interval_code
            AND l_interval_code_new <> l_interval_code_old
         THEN
            cwms_err.RAISE
                     ('GENERIC_ERROR',
                      'Cannot change to a regular interval when data is present'
                     );
         END IF;
   
   ----------------------------------------------------
   -- Do not allow the interval UTC offset to change --
   ----------------------------------------------------
         IF l_utc_offset_new <> l_utc_offset_old
         THEN
            cwms_err.RAISE
                          ('GENERIC_ERROR',
                           'Cannot change interval offsets when data is present'
                          );
         END IF;
      END IF;
   ----------------------------------------------------
   -- Determine the new location_code --
   ----------------------------------------------------
      BEGIN
         l_location_code_new :=
                        cwms_loc.get_location_code (l_office_id, l_location_new);
      EXCEPTION                                 -- New Location does not exist...
         WHEN OTHERS
         THEN
            cwms_loc.create_location (p_location_id => l_location_new, 
                                      p_db_office_id   => l_office_id);
            --
            l_location_code_new :=
                        cwms_loc.get_location_code (l_office_id, l_location_new);
      END;
   
   ----------------------------------------------------
   -- Determine the new parameter_code --
   ----------------------------------------------------
      l_parameter_code_new :=
         get_parameter_code (p_base_parameter_code      => l_base_parameter_code_new,
                             p_sub_parameter_id         => l_sub_parameter_id_new,
                             p_office_code              => l_office_code,
                             p_create                   => TRUE
                            );
   

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
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   --
   END rename_ts;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- PARSE_TS -
--
   PROCEDURE parse_ts (
         p_cwms_ts_id          IN       VARCHAR2,
         p_base_location_id    OUT      VARCHAR2,
         p_sub_location_id     OUT      VARCHAR2,
         p_base_parameter_id   OUT      VARCHAR2,
         p_sub_parameter_id    OUT      VARCHAR2,
         p_parameter_type_id   OUT      VARCHAR2,
         p_interval_id         OUT      VARCHAR2,
         p_duration_id         OUT      VARCHAR2,
         p_version_id          OUT      VARCHAR2
   )
   IS
   BEGIN
      SELECT cwms_util.get_base_id (REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 1))
                                                                base_location_id,
             cwms_util.get_sub_id (REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 1))
                                                                 sub_location_id,
             cwms_util.get_base_id (REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 2))
                                                               base_parameter_id,
             cwms_util.get_sub_id (REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 2))
                                                                sub_parameter_id,
             REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 3) parameter_type_id,
             REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 4) interval_id,
             REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 5) duration_id,
             REGEXP_SUBSTR (p_cwms_ts_id, '[^.]+', 1, 6) VERSION
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

/* Formatted on 2007/04/11 18:50 (Formatter Plus v4.8.8) */
/* Formatted on 2007/04/11 20:03 (Formatter Plus v4.8.8) */
PROCEDURE zretrieve_ts (
   p_at_tsv_rc      IN OUT   sys_refcursor,
   p_units          IN       VARCHAR2,
   p_cwms_ts_id     IN       VARCHAR2,
   p_start_time     IN       DATE,
   p_end_time       IN       DATE,
   p_trim           IN       VARCHAR2 DEFAULT 'F',
   p_inclusive      IN       NUMBER DEFAULT NULL,
   p_version_date   IN       DATE DEFAULT NULL,
   p_max_version    IN       VARCHAR2 DEFAULT 'T',
   p_db_office_id   IN       VARCHAR2 DEFAULT NULL
)
IS
   l_whichretrieve   VARCHAR2 (10);
   l_numvals         INTEGER;
   l_errnum          INTEGER;
   l_ts_interval     NUMBER;
   l_ts_offset       NUMBER;
   l_versioned       NUMBER;
   l_ts_code         NUMBER;
   l_version_date    DATE;
   l_max_version     BOOLEAN;
   l_trim            BOOLEAN;
   l_start_time      DATE          := p_start_time;
   l_start_trim_time date;
   l_end_time        DATE          := p_end_time;
   l_end_trim_time   date;
   l_end_time_init   DATE          := l_end_time;
   l_db_office_id    VARCHAR2 (16);
BEGIN
   --
   DBMS_APPLICATION_INFO.set_module ('Cwms_ts_retrieve', 'Check Interval');
   --
    -- set default values, don't be fooled by NULL as an actual argument
   IF p_db_office_id IS NULL
   THEN
      l_db_office_id := cwms_util.user_office_id;
   ELSE
      l_db_office_id := p_db_office_id;
   END IF;

   IF p_trim IS NULL
   THEN
      l_trim := FALSE;
   ELSE
      l_trim := cwms_util.return_true_or_false (p_trim);
   END IF;

   IF NVL (p_max_version, 'T') = 'T'
   THEN
      l_max_version := FALSE;
   ELSE
      l_max_version := TRUE;
   END IF;

   l_version_date := NVL (p_version_date, cwms_util.non_versioned);
   
   -- Make initial checks on start/end dates...
   if p_start_time is null or p_end_time is null
   then
   cwms_err.raise('ERROR','No way Jose');
   end if;
   
   if p_end_time < p_start_time
   then
   cwms_err.raise('ERROR','No way Jose');
   end if;
      

   --Get Time series parameters for retrieval load into record structure
   SELECT INTERVAL,
          CASE interval_utc_offset
             WHEN cwms_util.utc_offset_undefined
                THEN NULL
             WHEN cwms_util.utc_offset_irregular
                THEN NULL
             ELSE (interval_utc_offset)
          END,
          version_flag, ts_code
     INTO l_ts_interval,
          l_ts_offset,
          l_versioned, l_ts_code
     FROM mv_cwms_ts_id
    WHERE db_office_id = UPPER (l_db_office_id)
      AND UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id);


   IF l_ts_interval = 0
   THEN
      IF p_inclusive IS NOT NULL
      THEN
         IF l_versioned IS NULL
         THEN                                        -- l_versioned IS NULL -
            --
            -- nonl_versioned, irregular, inclusive retrieval
            --
            DBMS_OUTPUT.put_line ('RETRIEVE_TS #1');

            --
            OPEN p_at_tsv_rc FOR
               SELECT   date_time, VALUE, quality_code
                   FROM (SELECT date_time, VALUE, quality_code,
                                LAG (date_time, 1, l_start_time) OVER (ORDER BY date_time)
                                                                      lagdate,
                                LEAD (date_time, 1, l_end_time) OVER (ORDER BY date_time)
                                                                     leaddate
                           FROM av_tsv_dqu v
                          WHERE v.ts_code = l_ts_code
                            AND v.unit_id = p_units
                            AND v.start_date <= l_end_time
                            AND v.end_date > l_start_time)
                  WHERE leaddate >= l_start_time AND lagdate <= l_end_time
               ORDER BY date_time ASC;
         ELSE                                     -- l_versioned IS NOT NULL -
            --
            -- l_versioned, irregular, inclusive retrieval -
            IF p_version_date IS NULL
            THEN                                  -- p_version_date IS NULL -
               IF l_max_version
               THEN                                -- l_max_version is TRUE -
                  --latest version_date query -
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #2');

                  --
                  OPEN p_at_tsv_rc FOR
                     SELECT   date_time, VALUE, quality_code
                         FROM (SELECT date_time,
                                      MAX (VALUE)KEEP (DENSE_RANK LAST ORDER BY version_date)
                                                                        VALUE,
                                      MAX (quality_code)KEEP (DENSE_RANK LAST ORDER BY version_date)
                                                                 quality_code
                                 FROM (SELECT date_time, VALUE, quality_code,
                                              version_date,
                                              LAG (date_time,
                                                   1,
                                                   l_start_time
                                                  ) OVER (ORDER BY date_time)
                                                                      lagdate,
                                              LEAD (date_time,
                                                    1,
                                                    l_end_time
                                                   ) OVER (ORDER BY date_time)
                                                                     leaddate
                                         FROM av_tsv_dqu v
                                        WHERE v.ts_code = l_ts_code
                                          AND v.unit_id = p_units
                                          AND v.start_date <= l_end_time
                                          AND v.end_date > l_start_time)
                                WHERE leaddate >= l_start_time
                                  AND lagdate <= l_end_time)
                     ORDER BY date_time ASC;
               ELSE                                 --l_max_version is FALSE -
                  -- first version_date query -
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #3');

                  --
                  OPEN p_at_tsv_rc FOR
                     SELECT   date_time, VALUE, quality_code
                         FROM (SELECT date_time,
                                      MAX (VALUE)KEEP (DENSE_RANK FIRST ORDER BY version_date)
                                                                        VALUE,
                                      MAX (quality_code)KEEP (DENSE_RANK FIRST ORDER BY version_date)
                                                                 quality_code
                                 FROM (SELECT date_time, VALUE, quality_code,
                                              version_date,
                                              LAG (date_time,
                                                   1,
                                                   l_start_time
                                                  ) OVER (ORDER BY date_time)
                                                                      lagdate,
                                              LEAD (date_time,
                                                    1,
                                                    l_end_time
                                                   ) OVER (ORDER BY date_time)
                                                                     leaddate
                                         FROM av_tsv_dqu v
                                        WHERE v.ts_code = l_ts_code
                                          AND v.unit_id = p_units
                                          AND v.start_date <= l_end_time
                                          AND v.end_date > l_start_time)
                                WHERE leaddate >= l_start_time
                                  AND lagdate <= l_end_time)
                     ORDER BY date_time ASC;
               END IF;                                       --l_max_version -
            ELSE                                --p_version_date IS NOT NULL -
               --
               --selected version_date query -
               --
               DBMS_OUTPUT.put_line ('RETRIEVE_TS #4');

               --
               OPEN p_at_tsv_rc FOR
                  SELECT   date_time, VALUE, quality_code
                      FROM (SELECT date_time, VALUE, quality_code,
                                   LAG (date_time, 1, l_start_time) OVER (ORDER BY date_time)
                                                                      lagdate,
                                   LEAD (date_time, 1, l_end_time) OVER (ORDER BY date_time)
                                                                     leaddate
                              FROM av_tsv_dqu v
                             WHERE v.ts_code = l_ts_code
                               AND v.unit_id = p_units
                               AND v.version_date = p_version_date
                               AND v.start_date <= l_end_time
                               AND v.end_date > l_start_time)
                     WHERE leaddate >= l_start_time AND lagdate <= l_end_time
                  ORDER BY date_time ASC;
            END IF;                                         --p_version_date -
         END IF;                                              -- l_versioned -
      ELSE                                            -- p_inclusive IS NULL -
         DBMS_APPLICATION_INFO.set_action (   'return  irregular  ts '
                                           || l_ts_code
                                           || ' from '
                                           || TO_CHAR (l_start_time,
                                                       'mm/dd/yyyy hh24:mi'
                                                      )
                                           || ' to '
                                           || TO_CHAR (l_end_time,
                                                       'mm/dd/yyyy hh24:mi'
                                                      )
                                           || ' in units '
                                           || p_units
                                          );

         IF l_versioned IS NULL
         THEN
            -- nonl_versioned, irregular, noninclusive retrieval -
            --
            DBMS_OUTPUT.put_line (   'gk - RETRIEVE_TS #5 ');

            --
            OPEN p_at_tsv_rc FOR
               SELECT   date_time, VALUE, quality_code
                   FROM av_tsv_dqu v
                  WHERE v.ts_code = l_ts_code
                    AND v.date_time BETWEEN l_start_time AND l_end_time
                    AND v.unit_id = p_units
                    AND v.start_date <= l_end_time
                    AND v.end_date > l_start_time
               ORDER BY date_time ASC;

         ELSE                                     -- l_versioned IS NOT NULL -
            --
            -- l_versioned, irregular, noninclusive retrieval -
            --
            IF p_version_date IS NULL
            THEN
               IF l_max_version
               THEN
                  --latest version_date query
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #6');

                  --
                  OPEN p_at_tsv_rc FOR
                     SELECT   date_time, VALUE, quality_code
                         FROM (SELECT   date_time,
                                        MAX (VALUE)KEEP (DENSE_RANK LAST ORDER BY version_date)
                                                                        VALUE,
                                        MAX (quality_code)KEEP (DENSE_RANK LAST ORDER BY version_date)
                                                                 quality_code
                                   FROM (SELECT date_time, VALUE,
                                                quality_code, version_date
                                           FROM av_tsv_dqu v
                                          WHERE v.ts_code = l_ts_code
                                            AND v.date_time BETWEEN l_start_time
                                                                AND l_end_time
                                            AND v.unit_id = p_units
                                            AND v.start_date <= l_end_time
                                            AND v.end_date > l_start_time)
                               GROUP BY date_time)
                     ORDER BY date_time ASC;
               ELSE                            -- p_version_date IS NOT NULL -
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #7');

                  --
                  OPEN p_at_tsv_rc FOR
                     SELECT   date_time, VALUE, quality_code
                         FROM (SELECT   date_time,
                                        MAX (VALUE)KEEP (DENSE_RANK FIRST ORDER BY version_date)
                                                                        VALUE,
                                        MAX (quality_code)KEEP (DENSE_RANK FIRST ORDER BY version_date)
                                                                 quality_code
                                   FROM (SELECT date_time, VALUE,
                                                quality_code, version_date
                                           FROM av_tsv_dqu v
                                          WHERE v.ts_code = l_ts_code
                                            AND v.date_time BETWEEN l_start_time
                                                                AND l_end_time
                                            AND v.unit_id = p_units
                                            AND v.start_date <= l_end_time
                                            AND v.end_date > l_start_time)
                               GROUP BY date_time)
                     ORDER BY date_time ASC;
               END IF;                         -- p_version_date IS NOT NULL -
            ELSE                                   -- l_max_version is FALSE -
               --
               DBMS_OUTPUT.put_line ('RETRIEVE_TS #8');

               --
               OPEN p_at_tsv_rc FOR
                  SELECT   date_time, VALUE, quality_code
                      FROM av_tsv_dqu v
                     WHERE v.ts_code = l_ts_code
                       AND v.date_time BETWEEN l_start_time AND l_end_time
                       AND v.unit_id = p_units
                       AND v.version_date = version_date
                       AND v.start_date <= l_end_time
                       AND v.end_date > l_start_time
                  ORDER BY date_time ASC;
            END IF;                                         -- l_max_version -
         END IF;                                              -- l_versioned -
      END IF;                                                 -- p_inclusive -
   ELSE                                                -- l_ts_interval <> 0 -
      DBMS_APPLICATION_INFO.set_action (   'return  regular  ts '
                                        || l_ts_code
                                        || ' from '
                                        || TO_CHAR (l_start_time,
                                                    'mm/dd/yyyy hh24:mi'
                                                   )
                                        || ' to '
                                        || TO_CHAR (l_end_time,
                                                    'mm/dd/yyyy hh24:mi'
                                                   )
                                        || ' in units '
                                        || p_units
                                       );
      -- Make sure start_time and end_time fall on a valid date/time for the regular -
      --    time series given the interval and offset. -
      l_start_time :=
         get_time_on_after_interval (l_start_time, l_ts_offset, l_ts_interval);
      l_end_time :=
           get_time_on_after_interval (l_end_time, l_ts_offset, l_ts_interval);

      IF l_end_time > l_end_time_init
      THEN
         l_end_time := l_end_time - (l_ts_interval / 1440);
      END IF;

      IF l_versioned IS NULL
      THEN
         --
         -- non_versioned, regular ts query
         --
         DBMS_OUTPUT.put_line
                         ('RETRIEVE_TS #9 - non versioned, regular ts query');
         --
         
           IF l_trim
           THEN
              SELECT MAX (date_time), MIN (date_time)
                INTO l_end_trim_time, l_start_trim_time
                FROM av_tsv v
               WHERE v.ts_code = l_ts_code
                 AND v.date_time BETWEEN l_start_time AND l_end_time
                 AND v.start_date <= l_end_time
                 AND v.end_date > l_start_time;
           ELSE
              l_end_trim_time := l_end_time;
              l_start_trim_time := l_start_time;
           END IF;

           OPEN p_at_tsv_rc FOR
              SELECT   date_time "DATE_TIME", VALUE,
                       NVL (quality_code, 0) quality_code
                  FROM (SELECT date_time, v.VALUE, v.quality_code
                          FROM (SELECT date_time, v.VALUE, v.quality_code
                                  FROM av_tsv_dqu v
                                 WHERE v.ts_code = l_ts_code
                                   AND v.date_time BETWEEN l_start_time AND l_end_time
                                   AND v.unit_id = p_units
                                   AND v.start_date <= l_end_time
                                   AND v.end_date > l_start_time) v
                               RIGHT OUTER JOIN
                               (SELECT       l_start_trim_time
                                           + ((LEVEL - 1) / (1440 / (l_ts_interval))
                                             ) date_time
                                      FROM DUAL
                                CONNECT BY 1 = 1
                                       AND LEVEL <=
                                                (  ROUND (  (  l_end_trim_time
                                                             - l_start_trim_time
                                                            )
                                                          * 1440
                                                         )
                                                 / l_ts_interval
                                                )
                                              + 1) t USING (date_time)
                               )
              ORDER BY date_time;
      ELSE                                       --  l_versioned IS NOT NULL -
         IF p_version_date IS NULL
         THEN
            IF l_max_version
            THEN
               --
               DBMS_OUTPUT.put_line ('RETRIEVE_TS #10');

               --
               OPEN p_at_tsv_rc FOR
                  SELECT   date_time, VALUE, quality_code
                      FROM (SELECT   jdate_time date_time,
                                     MAX (VALUE)KEEP (DENSE_RANK LAST ORDER BY version_date)
                                                                        VALUE,
                                     MAX (quality_code)KEEP (DENSE_RANK LAST ORDER BY version_date)
                                                                 quality_code
                                FROM (SELECT *
                                        FROM (SELECT *
                                                FROM av_tsv_dqu v
                                               WHERE v.ts_code = l_ts_code
                                                 AND v.date_time
                                                        BETWEEN l_start_time
                                                            AND l_end_time
                                                 AND v.unit_id = p_units
                                                 AND v.start_date <=
                                                                    l_end_time
                                                 AND v.end_date > l_start_time) v
                                             RIGHT OUTER JOIN
                                             (SELECT       l_start_time
                                                         + (  (LEVEL - 1)
                                                            / (  1440
                                                               / l_ts_interval
                                                              )
                                                           ) jdate_time
                                                    FROM DUAL
                                              CONNECT BY 1 = 1
                                                     AND LEVEL <=
                                                              (  ROUND
                                                                    (  (  l_end_time
                                                                        - l_start_time
                                                                       )
                                                                     * 1440
                                                                    )
                                                               / l_ts_interval
                                                              )
                                                            + 1) t
                                             ON t.jdate_time = v.date_time
                                             )
                            ORDER BY jdate_time)
                  GROUP BY date_time;
            ELSE                                   -- l_max_version is FALSE -
               --
               DBMS_OUTPUT.put_line ('RETRIEVE_TS #11');

               --
               OPEN p_at_tsv_rc FOR
                  SELECT   date_time, VALUE, quality_code
                      FROM (SELECT   jdate_time date_time,
                                     MAX (VALUE)KEEP (DENSE_RANK FIRST ORDER BY version_date)
                                                                        VALUE,
                                     MAX (quality_code)KEEP (DENSE_RANK FIRST ORDER BY version_date)
                                                                 quality_code
                                FROM (SELECT *
                                        FROM (SELECT *
                                                FROM av_tsv_dqu v
                                               WHERE v.ts_code = l_ts_code
                                                 AND v.date_time
                                                        BETWEEN l_start_time
                                                            AND l_end_time
                                                 AND v.unit_id = p_units
                                                 AND v.start_date <=
                                                                    l_end_time
                                                 AND v.end_date > l_start_time) v
                                             RIGHT OUTER JOIN
                                             (SELECT       l_start_time
                                                         + (  (LEVEL - 1)
                                                            / (  1440
                                                               / l_ts_interval
                                                              )
                                                           ) jdate_time
                                                    FROM DUAL
                                              CONNECT BY 1 = 1
                                                     AND LEVEL <=
                                                              (  ROUND
                                                                    (  (  l_end_time
                                                                        - l_start_time
                                                                       )
                                                                     * 1440
                                                                    )
                                                               / l_ts_interval
                                                              )
                                                            + 1) t
                                             ON t.jdate_time = v.date_time
                                             )
                            ORDER BY jdate_time)
                  GROUP BY date_time;
            END IF;                                         -- l_max_version -
         ELSE                                  -- p_version_date IS NOT NULL -
            --
            DBMS_OUTPUT.put_line ('RETRIEVE_TS #12');

            --
            OPEN p_at_tsv_rc FOR
               SELECT   jdate_time date_time, VALUE,
                        NVL (quality_code, 0) quality_code
                   FROM (SELECT *
                           FROM (SELECT *
                                   FROM av_tsv_dqu v
                                  WHERE v.ts_code = l_ts_code
                                    AND v.date_time BETWEEN l_start_time
                                                        AND l_end_time
                                    AND v.unit_id = p_units
                                    AND v.version_date = p_version_date
                                    AND v.start_date <= l_end_time
                                    AND v.end_date > l_start_time) v
                                RIGHT OUTER JOIN
                                (SELECT       l_start_time
                                            + (  (LEVEL - 1)
                                               / (1440 / l_ts_interval)
                                              ) jdate_time
                                       FROM DUAL
                                 CONNECT BY 1 = 1
                                        AND LEVEL <=
                                                 (  ROUND (  (  l_end_time
                                                              - l_start_time
                                                             )
                                                           * 1440
                                                          )
                                                  / l_ts_interval
                                                 )
                                               + 1) t
                                ON t.jdate_time = v.date_time
                                )
               ORDER BY jdate_time;
         END IF;
      END IF;
   END IF;

   DBMS_APPLICATION_INFO.set_module (NULL, NULL);
END zretrieve_ts;
/* Formatted on 2007/04/12 09:41 (Formatter Plus v4.8.8) */
PROCEDURE zretrieve_ts_java (
   p_transaction_time   OUT      DATE,
   p_at_tsv_rc          OUT      sys_refcursor,
   p_units_out          OUT      VARCHAR2,
   p_cwms_ts_id_out     OUT      VARCHAR2,
   p_units_in           IN       VARCHAR2,
   p_cwms_ts_id_in      IN       VARCHAR2,
   p_start_time         IN       DATE,
   p_end_time           IN       DATE,
   p_trim               IN       VARCHAR2 DEFAULT 'F',
   p_inclusive          IN       NUMBER DEFAULT NULL,
   p_version_date       IN       DATE DEFAULT NULL,
   p_max_version        IN       VARCHAR2 DEFAULT 'T',
   p_db_office_id       IN       VARCHAR2 DEFAULT NULL
)
IS
   /*l_at_tsv_rc   sys_refcursor;*/
   l_inclusive varchar2(1);
BEGIN
   p_transaction_time := CAST ((SYSTIMESTAMP AT TIME ZONE 'GMT') AS DATE);
   --
   /*
   p_cwms_ts_id_out := get_cwms_ts_id (p_cwms_ts_id_in, 
                                       cwms_util.GET_DB_OFFICE_ID(p_db_office_id));

   --
   IF p_units_in IS NULL
   THEN
      p_units_out := get_db_unit_id (p_cwms_ts_id_in);
   ELSE
      p_units_out := p_units_in;
   END IF;
   --
   zretrieve_ts (p_at_tsv_rc         => l_at_tsv_rc,
                 p_units             => p_units_out,
                 p_cwms_ts_id        => p_cwms_ts_id_out,
                 p_start_time        => p_start_time,
                 p_end_time          => p_end_time,
                 p_trim              => p_trim,
                 p_inclusive         => p_inclusive,
                 p_version_date      => p_version_date,
                 p_max_version       => p_max_version,
                 p_db_office_id      => p_db_office_id
                );

   p_at_tsv_rc := l_at_tsv_rc;
   */
   if  nvl(p_inclusive, 0) = 0 then
      l_inclusive := 'F';
   else
      l_inclusive := 'T';
   end if;
   retrieve_ts_out(p_at_tsv_rc,
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

-- p_fail_if_exists 'T' will throw an exception if the parameter_id already    -
--                        exists.                                              -
--                  'F' will simply return the parameter code of the already   -
--                        existing parameter id.                               -
PROCEDURE create_parameter_code (
   p_base_parameter_code   OUT      NUMBER,
   p_parameter_code        OUT      NUMBER,
   p_base_parameter_id     IN       VARCHAR2,
   p_sub_parameter_id      IN       VARCHAR2,
   p_fail_if_exists        IN       VARCHAR2 DEFAULT 'T',
   p_db_office_code        IN       NUMBER
)
IS
   l_all_office_code       NUMBER  := cwms_util.db_office_code_all;
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
         cwms_err.RAISE ('INVALID_PARAM_ID',
                            p_base_parameter_id
                         || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
                         || p_sub_parameter_id
                        );
   END;

   BEGIN
      IF p_sub_parameter_id IS NULL
      THEN
         SELECT parameter_code
           INTO p_parameter_code
           FROM at_parameter ap
          WHERE base_parameter_code = p_base_parameter_code
            AND sub_parameter_id IS NULL
            AND db_office_code IN (p_db_office_code, l_all_office_code);
      ELSE
         SELECT parameter_code
           INTO p_parameter_code
           FROM at_parameter ap
          WHERE base_parameter_code = p_base_parameter_code
            AND UPPER (sub_parameter_id) = UPPER (p_sub_parameter_id)
            AND db_office_code IN (p_db_office_code, l_all_office_code);
      END IF;

      l_parameter_id_exists := TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         IF p_sub_parameter_id IS NULL
         THEN
            cwms_err.RAISE ('INVALID_PARAM_ID',
                               p_base_parameter_id
                            || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
                            || p_sub_parameter_id
                           );
         ELSE                                   -- Insert new sub_parameter...
            INSERT INTO at_parameter
                        (parameter_code, db_office_code,
                         base_parameter_code, sub_parameter_id
                        )
                 VALUES (cwms_seq.NEXTVAL, p_db_office_code,
                         p_base_parameter_code, p_sub_parameter_id
                        )
              RETURNING parameter_code
                   INTO p_parameter_code;
         END IF;
   END;

   IF UPPER (NVL (p_fail_if_exists, 'T')) = 'T' AND l_parameter_id_exists
   THEN
      cwms_err.RAISE ('ITEM_ALREADY_EXISTS',
                         p_base_parameter_id
                      || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
                      || p_sub_parameter_id,
                      'Parameter Id'
                     );
   END IF;
END create_parameter_code;

/* Formatted on 2007/06/14 14:40 (Formatter Plus v4.8.8) */
PROCEDURE create_parameter_id (
   p_parameter_id   IN   VARCHAR2,
   p_db_office_id   IN   VARCHAR2 DEFAULT NULL
)
IS
   l_db_office_code        NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   l_base_parameter_code   NUMBER;
   l_parameter_code        NUMBER;
BEGIN
   create_parameter_code
               (p_base_parameter_code      => l_base_parameter_code,
                p_parameter_code           => l_parameter_code,
                p_base_parameter_id        => cwms_util.get_base_id
                                                               (p_parameter_id),
                p_sub_parameter_id         => cwms_util.get_sub_id
                                                               (p_parameter_id),
                p_fail_if_exists           => 'F',
                p_db_office_code           => l_db_office_code
               );
END;

/* Formatted on 2007/06/14 15:35 (Formatter Plus v4.8.8) */
PROCEDURE delete_parameter_id (
   p_base_parameter_id   IN   VARCHAR2,
   p_sub_parameter_id    IN   VARCHAR2,
   p_db_office_code      IN   NUMBER
)
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
         cwms_err.RAISE ('INVALID_PARAM_ID',
                            p_base_parameter_id
                         || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
                         || p_sub_parameter_id
                        );
   END;

   DELETE FROM at_parameter
         WHERE base_parameter_code = l_base_parameter_code
           AND UPPER (sub_parameter_id) = UPPER (TRIM (p_sub_parameter_id))
           AND db_office_code = p_db_office_code;
END;
/* Formatted on 2007/06/14 15:37 (Formatter Plus v4.8.8) */
PROCEDURE delete_parameter_id (
   p_parameter_id   IN   VARCHAR2,
   p_db_office_id   IN   VARCHAR2 DEFAULT NULL
)
IS
BEGIN
   delete_parameter_id
            (p_base_parameter_id      => cwms_util.get_base_id (p_parameter_id),
             p_sub_parameter_id       => cwms_util.get_sub_id (p_parameter_id),
             p_db_office_code         => cwms_util.get_db_office_code
                                                               (p_db_office_id)
            );
END;

/* Formatted on 2007/06/15 08:00 (Formatter Plus v4.8.8) */
PROCEDURE rename_parameter_id (
   p_parameter_id_old   IN   VARCHAR2,
   p_parameter_id_new   IN   VARCHAR2,
   p_db_office_id       IN   VARCHAR2 DEFAULT NULL
)
IS
   l_db_office_code_all        NUMBER        := cwms_util.db_office_code_all;
   l_db_office_code            NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   --
   l_db_office_id_old          NUMBER;
   l_base_parameter_code_old   NUMBER;
   l_parameter_code_old        NUMBER;
   l_sub_parameter_id_old      VARCHAR2 (32);
   l_parameter_code_new        NUMBER;
   l_base_parameter_code_new   NUMBER;
   l_base_parameter_id_new     VARCHAR2 (16);
   l_sub_parameter_id_new      VARCHAR2 (32);
   --
   l_new_parameter_id_exists   BOOLEAN       := FALSE;
BEGIN
   SELECT db_office_id, base_parameter_code, parameter_code,
          sub_parameter_id
     INTO l_db_office_id_old, l_base_parameter_code_old, l_parameter_code_old,
          l_sub_parameter_id_old
     FROM av_parameter
    WHERE UPPER (parameter_id) = UPPER (TRIM (p_parameter_id_old))
      AND db_office_code IN (l_db_office_code_all, l_db_office_code);

   IF l_db_office_id_old = l_db_office_code_all
   THEN
      cwms_err.RAISE ('ITEM_OWNED_BY_CWMS',p_parameter_id_old );
   END IF;
   
   BEGIN
      SELECT base_parameter_code,
             parameter_code, sub_parameter_id
        INTO l_base_parameter_code_new,
             l_parameter_code_new, l_sub_parameter_id_new
        FROM av_parameter
       WHERE UPPER (parameter_id) = UPPER (TRIM (p_parameter_id_new))
         AND db_office_code IN (l_db_office_code_all, l_db_office_code);

      l_new_parameter_id_exists := TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_base_parameter_id_new :=
                                   cwms_util.get_base_id (p_parameter_id_new);
         l_sub_parameter_id_new := cwms_util.get_sub_id (p_parameter_id_new);

         SELECT base_parameter_code
           INTO l_base_parameter_code_old
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (l_base_parameter_id_new);

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
   PROCEDURE zstore_ts (p_cwms_ts_id      IN varchar2,
                        p_units           IN varchar2,
                        p_timeseries_data IN ztsv_array,
                        p_store_rule      IN varchar2 DEFAULT NULL ,
                        p_override_prot   IN varchar2 DEFAULT 'F' ,
                        p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
                        p_office_id       IN varchar2 DEFAULT NULL
   )
   IS
      l_timeseries_data   tsv_array := tsv_array ();
   BEGIN
      l_timeseries_data.EXTEND (p_timeseries_data.COUNT);

      FOR i IN 1 .. p_timeseries_data.COUNT
      LOOP
         l_timeseries_data (i)   :=
            tsv_type (FROM_TZ (CAST (p_timeseries_data (i).date_time AS timestamp
                               ),
                               'GMT'
                      ),
                      p_timeseries_data (i).VALUE,
                      p_timeseries_data (i).quality_code
            );
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
                        p_office_id
      );
   END zstore_ts;

   PROCEDURE zstore_ts_multi (p_timeseries_array IN ztimeseries_array,
                              p_store_rule       IN varchar2 DEFAULT NULL ,
                              p_override_prot    IN varchar2 DEFAULT 'F' ,
                              p_version_date     IN DATE     DEFAULT cwms_util.non_versioned,
                              p_office_id        IN varchar2 DEFAULT NULL
   )
   IS
      l_timeseries   ztimeseries_type;
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.zstore_ts_multi',
                                        'selecting time series from input'
      );

      FOR l_timeseries IN (SELECT *
                           FROM table (p_timeseries_array))
      LOOP
         DBMS_APPLICATION_INFO.set_module ('cwms_ts_store.zstore_ts_multi',
                                           'calling zstore_ts'
         );
         cwms_ts.zstore_ts (l_timeseries.tsid,
                   l_timeseries.unit,
                   l_timeseries.data,
                   p_store_rule,
                   p_override_prot,
                   p_version_date,
                   p_office_id
         );
      END LOOP;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END zstore_ts_multi;


   END cwms_ts; --end package body
/

show errors;
commit;
