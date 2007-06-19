/* Formatted on 2007/06/12 13:43 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_20.cwms_shef
AS
   FUNCTION get_loc_category_code (
      p_loc_category_id   IN   VARCHAR2,
      p_db_office_code    IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_loc_category_code   NUMBER;
   BEGIN
      SELECT a.loc_category_code
        INTO l_loc_category_code
        FROM at_loc_category a
       WHERE UPPER (a.loc_category_id) = UPPER (TRIM (p_loc_category_id))
         AND a.db_office_code IN
                             (p_db_office_code, cwms_util.db_office_code_all);

      RETURN l_loc_category_code;
   END;

   FUNCTION get_loc_group_code (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_db_office_code    IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_loc_category_code   NUMBER
               := get_loc_category_code (p_loc_category_id, p_db_office_code);
      l_loc_group_code      NUMBER;
   BEGIN
      SELECT a.loc_group_code
        INTO l_loc_group_code
        FROM at_loc_group a
       WHERE a.loc_category_code = l_loc_category_code
         AND UPPER (a.loc_group_id) = UPPER (TRIM (p_loc_group_id))
         AND a.db_office_code IN
                             (p_db_office_code, cwms_util.db_office_code_all);

      RETURN l_loc_group_code;
   END;

   FUNCTION get_data_stream_code (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_code   IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_data_stream_code   NUMBER;
   BEGIN
      BEGIN
         SELECT a.data_stream_code
           INTO l_data_stream_code
           FROM at_data_stream_id a
          WHERE UPPER (a.data_stream_id) = UPPER (TRIM (p_data_stream_id))
            AND a.db_office_code = p_db_office_code;

         RETURN l_data_stream_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
      END;
   END;

   FUNCTION get_data_stream_code (
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_db_office_code   NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   BEGIN
      RETURN get_data_stream_code (p_data_stream_id      => p_data_stream_id,
                                   p_db_office_code      => l_db_office_code
                                  );
   END;

   FUNCTION get_shef_duration_numeric (p_shef_duration_code IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_shef_duration_code      VARCHAR2 (1);
      l_shef_duration_numeric   VARCHAR2 (4);
      l_tmp                     VARCHAR2 (5)
                                       := UPPER (TRIM (p_shef_duration_code));
      l_num                     NUMBER;
   BEGIN
      IF REGEXP_INSTR (SUBSTR (l_tmp, 1, 1), '[A-Z]') = 1
      THEN
         l_shef_duration_code :=
                           UPPER (SUBSTR (TRIM (p_shef_duration_code), 1, 1));

         IF l_shef_duration_code = 'V'
         THEN
            l_shef_duration_numeric :=
                                   SUBSTR (TRIM (p_shef_duration_code), 2, 4);

            IF    LENGTH (l_shef_duration_numeric) != 4
               OR SUBSTR (l_shef_duration_numeric, 1, 1) != '5'
            THEN
               cwms_err.RAISE ('ERROR',
                                  l_shef_duration_numeric
                               || ' is not a valid SHEF Duration Numeric.'
                              );
            END IF;
         ELSE
            BEGIN
               SELECT a.shef_duration_numeric
                 INTO l_shef_duration_numeric
                 FROM cwms_shef_duration a
                WHERE a.shef_duration_code = l_shef_duration_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  cwms_err.RAISE ('ERROR',
                                     l_shef_duration_code
                                  || ' is not a valid SHEF duration code.'
                                 );
            END;
         END IF;
      ELSE
         l_shef_duration_numeric := l_tmp;
      END IF;

      RETURN l_shef_duration_numeric;
   END;

   PROCEDURE store_shef_spec (
      p_cwms_ts_id              IN   VARCHAR2,
      p_data_stream_id          IN   VARCHAR2,
      p_loc_group_id            IN   VARCHAR2,
      p_shef_loc_id             IN   VARCHAR2 DEFAULT NULL,
      -- normally use loc_group_id
      p_shef_pe_code            IN   VARCHAR2,
      p_shef_tse_code           IN   VARCHAR2,
      p_shef_duration_code      IN   VARCHAR2,
      -- e.g., V5002 or simply L     -
      p_shef_unit_id            IN   VARCHAR2,
      p_time_zone_id            IN   VARCHAR2,
      p_daylight_savings        IN   VARCHAR2 DEFAULT 'F',  -- psuedo boolean.
      p_interval_utc_offset     IN   NUMBER DEFAULT NULL,       -- in minutes.
      p_snap_forward_minutes    IN   NUMBER DEFAULT NULL,
      p_snap_backward_minutes   IN   NUMBER DEFAULT NULL,
      p_ts_active_flag          IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id            IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id            VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code          NUMBER
                             := cwms_util.get_db_office_code (l_db_office_id);
      l_ts_code                 NUMBER;
      --
      l_data_stream_code        NUMBER;
      l_spec_exists             BOOLEAN;
      l_shef_pe_code            VARCHAR2 (2)  := UPPER (p_shef_pe_code);
      l_shef_tse_code           VARCHAR2 (3)  := UPPER (p_shef_tse_code);
      l_shef_duration_code      VARCHAR2 (1);
      l_shef_duration_numeric   VARCHAR2 (4);
      l_shef_unit_code          NUMBER;
      l_shef_time_zone_code     NUMBER;
      l_time_zone_id            VARCHAR2 (16) := NVL (p_time_zone_id, 'UTC');
      l_dl_time                 VARCHAR2 (1)
                                     := UPPER (NVL (p_daylight_savings, 'F'));
      l_ts_active_flag          VARCHAR2 (1)
                                       := UPPER (NVL (p_ts_active_flag, 'T'));
      l_shef_loc_id             VARCHAR2 (8)  := UPPER (TRIM (p_shef_loc_id));
      l_shef_id                 VARCHAR2 (8)  := NULL;
      l_location_code           NUMBER;
      l_loc_group_code          NUMBER;
      l_tmp                     NUMBER;
   BEGIN
      cwms_apex.aa1 ('in store_shef_spec.');

      --
      IF l_dl_time NOT IN ('T', 'F')
      THEN
         cwms_err.RAISE ('INVALID_T_F_FLAG', 'p_daylight_savings');
      END IF;

      --
      -- get the ts_code -
      BEGIN
         l_ts_code := cwms_util.get_ts_code (p_cwms_ts_id, l_db_office_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_ts.create_ts_code (p_ts_code                => l_ts_code,
                                    p_cwms_ts_id             => p_cwms_ts_id,
                                    p_utc_offset             => NULL,
                                    p_interval_forward       => NULL,
                                    p_interval_backward      => NULL,
                                    p_versioned              => 'F',
                                    p_active_flag            => 'T',
                                    p_fail_if_exists         => 'T',
                                    p_office_id              => l_db_office_id
                                   );
      END;

      cwms_apex.aa1 ('store_shef_spec - ts_code: ' || l_ts_code);
      l_data_stream_code :=
                     get_data_stream_code (p_data_stream_id, l_db_office_code);
      l_loc_group_code :=
         get_loc_group_code ('Agency Alias', p_loc_group_id, l_db_office_code);

      SELECT a.location_code
        INTO l_location_code
        FROM at_cwms_ts_spec a
       WHERE a.ts_code = l_ts_code;

      cwms_apex.aa1 ('store_shef_spec - location code: ' || l_location_code);

      --
      -- confirm that an alias exists for the loc group code and/or matches  -
      -- the shef_loc_id passed in...
      ---
      BEGIN
         SELECT a.loc_alias_id
           INTO l_shef_id
           FROM at_loc_group_assignment a
          WHERE a.loc_group_code = l_loc_group_code
            AND a.location_code = l_location_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            -- if a loc_group assignment for this location/group has not already-
            -- been made, then try and make the assignment.
            l_shef_id := NULL;

            --
            IF l_shef_loc_id IS NOT NULL
            THEN
               INSERT INTO at_loc_group_assignment
                           (location_code, loc_group_code, loc_alias_id
                           )
                    VALUES (l_location_code, l_loc_group_code, l_shef_loc_id
                           );
            ELSE
               cwms_err.RAISE
                  ('ERROR',
                      'Unable to find a SHEF Location Id for this CWMS_TS_ID: '
                   || p_cwms_ts_id
                   || ' and this Location Group: '
                   || p_loc_group_id
                  );
            END IF;
      END;

      cwms_apex.aa1 (   'store_shef_spec - shef id: '
                     || l_shef_loc_id
                     || ' - '
                     || l_shef_id
                    );

      IF l_shef_id IS NOT NULL AND l_shef_loc_id IS NOT NULL
      THEN
         IF UPPER (l_shef_id) != UPPER (l_shef_loc_id)
         THEN
            cwms_err.RAISE ('ERROR',
                               'The provided SHEF Loc Id: '
                            || l_shef_loc_id
                            || ' does not match an existing SHEF Loc Id: '
                            || l_shef_id
                            || ' set for this Location Group: '
                            || p_loc_group_id
                            || ' and CWMS_TS_ID: '
                            || p_cwms_ts_id
                           );
         END IF;
      ELSIF l_shef_id IS NULL
      THEN
         l_shef_id := l_shef_loc_id;
      END IF;

      l_tmp := LENGTH (TRIM (l_shef_id));

      IF l_tmp = 0
      THEN
         cwms_err.RAISE
            ('ERROR',
                'Unable to set shef spec - No SHEF Id found for this cwms_ts_id and Agency: '
             || p_loc_group_id
            );
      ELSIF l_tmp > 8
      THEN
         cwms_err.RAISE
                    ('ERROR',
                        'SHEF Id is longer than eight characters in length: '
                     || l_shef_id
                    );
      END IF;

      --
      l_shef_duration_numeric :=
                              get_shef_duration_numeric (p_shef_duration_code);

      BEGIN
         SELECT shef_duration_code
           INTO l_shef_duration_code
           FROM cwms_shef_duration
          WHERE shef_duration_numeric = l_shef_duration_numeric;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_shef_duration_code := 'V';
      END;

      cwms_apex.aa1 (   'in store_shef_spec - duration: .'
                     || l_shef_duration_numeric
                     || ' - '
                     || l_shef_duration_code
                    );

      SELECT a.unit_code
        INTO l_shef_unit_code
        FROM cwms_unit a
       WHERE a.unit_id = p_shef_unit_id;

      cwms_apex.aa1 ('store_shef_spec - shef_unit_coded: ' || l_shef_unit_code);

      SELECT shef_time_zone_code
        INTO l_shef_time_zone_code
        FROM cwms_shef_time_zone a
       WHERE UPPER (a.shef_time_zone_id) = UPPER (l_time_zone_id);

      cwms_ts.update_ts (p_ts_code                     => l_ts_code,
                         p_interval_utc_offset         => p_interval_utc_offset,
                         -- in minutes.
                         p_snap_forward_minutes        => p_snap_forward_minutes,
                         p_snap_backward_minutes       => p_snap_backward_minutes,
                         p_local_reg_time_zone_id      => NULL,
                         p_ts_active_flag              => l_ts_active_flag
                        );

      --
      --
      BEGIN
         cwms_apex.aa1
                    ('store_shef_spec - trying to insert into at_shef_decode');

         INSERT INTO at_shef_decode
                     (ts_code, data_stream_code, shef_loc_id,
                      shef_pe_code, shef_tse_code,
                      shef_duration_numeric, shef_unit_code,
                      shef_time_zone_code, dl_time, location_code,
                      loc_group_code, shef_duration_code
                     )
              VALUES (l_ts_code, l_data_stream_code, l_shef_id,
                      l_shef_pe_code, l_shef_tse_code,
                      l_shef_duration_numeric, l_shef_unit_code,
                      l_shef_time_zone_code, l_dl_time, l_location_code,
                      l_loc_group_code, l_shef_duration_code
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            DECLARE
               ERROR_CODE   NUMBER := SQLCODE;
            BEGIN
               IF ERROR_CODE = -1
               THEN
                  cwms_err.RAISE ('SHEF_DUP_TS_ID', p_cwms_ts_id);
               ELSE
                  cwms_apex.aa1
                     ('store_shef_spec - trying to update into at_shef_decode'
                     );
                  cwms_apex.aa1 (   'store_shef_spec - tse code is:'
                                 || l_shef_tse_code
                                );

                  UPDATE at_shef_decode
                     SET shef_loc_id = l_shef_id,
                         shef_pe_code = l_shef_pe_code,
                         shef_tse_code = l_shef_tse_code,
                         shef_duration_numeric = l_shef_duration_numeric,
                         shef_unit_code = l_shef_unit_code,
                         shef_time_zone_code = l_shef_time_zone_code,
                         dl_time = l_dl_time,
                         location_code = l_location_code,
                         loc_group_code = l_loc_group_code,
                         shef_duration_code = l_shef_duration_code
                   WHERE ts_code = l_ts_code
                     AND data_stream_code = l_data_stream_code;
               END IF;
            END;
      END;
--      MERGE INTO at_shef_decode a
--         USING (SELECT SYSDATE
--                  FROM DUAL) b
----         USING (SELECT l_ts_code, l_data_stream_code, l_shef_id,
----                       l_shef_pe_code, l_shef_tse_code,
----                       l_shef_duration_numeric, l_shef_duration_code,
----                       l_shef_unit_code, l_shef_time_zone_code, l_dl_time,
----                       l_loc_group_code, l_location_code
----                  FROM DUAL) b
--      ON (a.ts_code = l_ts_code AND a.data_stream_code = l_data_stream_code)
--         WHEN MATCHED THEN
--            UPDATE
--               SET shef_loc_id = l_shef_id, shef_pe_code = l_shef_pe_code,
--                   shef_tse_code = l_shef_tse_code,
--                   shef_duration_numeric = l_shef_duration_numeric,
--                   shef_unit_code = l_shef_unit_code,
--                   shef_time_zone_code = l_shef_time_zone_code,
--                   dl_time = l_dl_time, location_code = l_location_code,
--                   loc_group_code = l_loc_group_code,
--                   shef_duration_code = l_shef_duration_code
--         WHEN NOT MATCHED THEN
--            INSERT (ts_code, data_stream_code, shef_loc_id, shef_pe_code,
--                    shef_tse_code, shef_duration_numeric, shef_unit_code,
--                    shef_time_zone_code, dl_time, location_code,
--                    loc_group_code, shef_duration_code)
--            VALUES (l_ts_code, l_data_stream_code, l_shef_id, l_shef_pe_code,
--                    l_shef_tse_code, l_shef_duration_numeric,
--                    l_shef_unit_code, l_shef_time_zone_code, l_dl_time,
--                    l_location_code, l_loc_group_code, l_shef_duration_code);
   END;

-- ****************************************************************************
-- cwms_shef.delete_shef_spec is used to delete an existing SHEF spec. SHEF
-- specs are assigned to pairs of cwms_ts_id and data stream.
--
-- p_cwms_ts_id(varchar2(183) - required parameter) and
-- p_data_stream_id (varchar2(16 - required parameter) -- is the cwms_ts_id
--         data stream pair whose SHEF spec you wish to delete.
--
-- p_db_office_id (varchar2(16) - optional parameter) is the database office
--         id that this data stream will be/is assigned too. Normally this is
--         left null and the user's default database office id is used.
--
   PROCEDURE delete_shef_spec (
      p_cwms_ts_id       IN   VARCHAR2,
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code     NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_cwms_ts_code       NUMBER
                    := cwms_util.get_ts_code (p_cwms_ts_id, l_db_office_code);
      l_data_stream_code   NUMBER;
   BEGIN
      -- Check if data_stream already exists...
      BEGIN
         l_data_stream_code :=
            get_data_stream_code (p_data_stream_id      => p_data_stream_id,
                                  p_db_office_code      => l_db_office_code
                                 );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
      END;

      DELETE      at_shef_decode
            WHERE ts_code = l_cwms_ts_code
              AND data_stream_code = l_data_stream_code;
   END;

-- ****************************************************************************
-- cwms_shef.store_data_stream is used to:
--    a) create a new data stream entry
--    b) revise an existing data stream's description and/or active_flag.
--
-- p_data_stream_id (varchar2(16) - required parameter)is either a new or
--         existing data stream id. If the data stream id is new, then a new
--         data steam is created in the database. If the data stream exists,
--         then the data stream's description and/or active flag are updated.
--
-- p_data_stream_desc (varchar2(128) - optional parameter) is an optional
--         description field for the data stream.
--
-- p_active_flag (optional parameter, can be either "T" or "F" with the default
--         being "T") Indicates whether this data stream is active ("T") or
--         inactive ("F"). ProcessSHEFIT will only process data for an active
--         ("T") data stream.
--
-- p_ignore_nulls (optional parameter, can be either "T" or "F" with the
--         default being "T") Only valid when store_data_stream is being used
--         to update an existing data stream's active flag. When set to "T"
--         (the default), a null p_data_stream_desc is ignored - this allows
--         one to change the active flag without having to pass in the data
--         stream's description - you can simply leave the description null
--         and the null will not overwrite any existing description in the
--         database.
--
-- p_db_office_id (varchar2(16) - optional parameter) is the database office
--         id that this data stream will be/is assigned too. Normally this is
--         left null and the user's default database office id is used.
--
   PROCEDURE store_data_stream (
      p_data_stream_id     IN   VARCHAR2,
      p_data_stream_desc   IN   VARCHAR2 DEFAULT NULL,
      p_active_flag        IN   VARCHAR2 DEFAULT 'T',
      p_ignore_nulls       IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code     NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_data_stream_code   NUMBER;
      l_active_flag        VARCHAR2 (1)  := NVL (UPPER (p_active_flag), 'T');
      l_ignore_nulls       VARCHAR2 (1)  := NVL (UPPER (p_ignore_nulls), 'T');
      l_data_stream_id     VARCHAR2 (16) := TRIM (p_data_stream_id);
   BEGIN
      IF l_data_stream_id IS NULL
      THEN
         cwms_err.RAISE ('PARAM_CANNOT_BE_NULL', 'p_data_stream_id');
      END IF;

      IF l_active_flag NOT IN ('T', 'F')
      THEN
         cwms_err.RAISE ('INVALID_T_F_FLAG', 'p_active_flag');
      END IF;

      IF l_ignore_nulls NOT IN ('T', 'F')
      THEN
         cwms_err.RAISE ('INVALID_T_F_FLAG', 'p_active_flag');
      END IF;

      -- Check if data_stream already exists...
      BEGIN
         l_data_stream_code :=
            get_data_stream_code (p_data_stream_id      => p_data_stream_id,
                                  p_db_office_code      => l_db_office_code
                                 );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_data_stream_code := NULL;
      END;

      IF l_data_stream_code IS NULL
      THEN                                     -- storing a new data stream...
         INSERT INTO at_data_stream_id
                     (data_stream_code, db_office_code, data_stream_id,
                      data_stream_desc, active_flag
                     )
              VALUES (cwms_seq.NEXTVAL, l_db_office_code, l_data_stream_id,
                      TRIM (p_data_stream_desc), l_active_flag
                     );
      ELSE                              -- updating an existing data stream...
         IF p_data_stream_desc IS NULL AND l_ignore_nulls = 'T'
         THEN               -- update that ignores a null data_stream_desc...
            UPDATE at_data_stream_id
               SET data_stream_id = l_data_stream_id,
                   active_flag = l_active_flag
             WHERE data_stream_code = l_data_stream_code;
         ELSE        -- update that does not ignore a null data_stream_desc...
            UPDATE at_data_stream_id
               SET data_stream_id = l_data_stream_id,
                   data_stream_desc = TRIM (p_data_stream_desc),
                   active_flag = l_active_flag
             WHERE data_stream_code = l_data_stream_code;
         END IF;
      END IF;
   END;

-- ****************************************************************************
-- cwms_shef.rename_data_stream is used to rename an existing data stream id.
--
-- p_data_stream_id _old(varchar2(16) - required parameter)is the id of the
--         existing data stream id.
--
-- p_data_stream_id _newvarchar2(16) - required parameter)is the id that you
--         are renaming the old data stream name too.
--
-- p_db_office_id (varchar2(16) - optional parameter) is the database office
--         id that this data stream will be/is assigned too. Normally this is
--         left null and the user's default database office id is used.
--
   PROCEDURE rename_data_stream (
      p_data_stream_id_old   IN   VARCHAR2,
      p_data_stream_id_new   IN   VARCHAR2,
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code     NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_data_stream_code   NUMBER;
      l_tmp                NUMBER;
      l_case_change        BOOLEAN := FALSE;
   BEGIN
      -- Check if "old" data_stream already exists...
      BEGIN
         l_data_stream_code :=
            get_data_stream_code (p_data_stream_id      => p_data_stream_id_old,
                                  p_db_office_code      => l_db_office_code
                                 );
      EXCEPTION
         WHEN OTHERS
         THEN             -- old data stream does not exist - cannot rename...
            cwms_err.RAISE ('CANNOT_RENAME_1', TRIM (p_data_stream_id_old));
      END;

      -- Check if the case of the old id is being changed...
      IF UPPER (TRIM (p_data_stream_id_old)) =
                                           UPPER (TRIM (p_data_stream_id_new))
      THEN                   -- then old and new are syntactically the same...
         IF TRIM (p_data_stream_id_old) = TRIM (p_data_stream_id_new)
         THEN       -- the old and new are exactly the same - so no rename...
            cwms_err.RAISE ('CANNOT_RENAME_3', TRIM (p_data_stream_id_old));
         ELSE
            l_case_change := TRUE;
         END IF;
      END IF;

      -- Check if "new" data_stream already exists...
      IF NOT l_case_change
      THEN
         BEGIN
            l_tmp :=
               get_data_stream_code
                                   (p_data_stream_id      => p_data_stream_id_new,
                                    p_db_office_code      => l_db_office_code
                                   );
         EXCEPTION
            WHEN OTHERS
            THEN             -- new datastream does not exist - good thing!...
               l_tmp := NULL;
         END;

         IF l_tmp != NULL
         THEN
            cwms_err.RAISE ('CANNOT_RENAME_2', TRIM (p_data_stream_id_new));
         END IF;
      END IF;

      -- pefform the update...
      UPDATE at_data_stream_id
         SET data_stream_id = TRIM (p_data_stream_id_new)
       WHERE data_stream_code = l_data_stream_code;
   END;

-- ****************************************************************************
-- cwms_shef.delete_data_stream is used to delete an existing data stream id.
--
-- p_data_stream_id(varchar2(16) - required parameter)is the id of the
--         existing data stream to be deleted.
--
-- p_cascade_all (optional parameter, can be either "T" or "F" with the default
--         being "F") -- A data stream can only be deleted if there are no
--         SHEF specs assigned to it. You can force a deletion by setting
--         p_cascade_all to "T", which will delete all SHEF specs associated
--         with this data stream. WARNING - this is a very powerfull option -
--         all SHEF specs are permanently deleted!!
--
-- p_db_office_id (varchar2(16) - optional parameter) is the database office
--         id that this data stream will be/is assigned too. Normally this is
--         left null and the user's default database office id is used.
--
   PROCEDURE delete_data_stream (
      p_data_stream_id   IN   VARCHAR2,
      p_cascade_all      IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code     NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_data_stream_code   NUMBER;
      l_cascade_all        VARCHAR2 (1) := NVL (UPPER (p_cascade_all), 'F');
   BEGIN
      IF l_cascade_all NOT IN ('T', 'F')
      THEN
         cwms_err.RAISE ('INVALID_T_F_FLAG', 'p_cascade_all');
      END IF;

      -- Check if data_stream already exists...
      BEGIN
         l_data_stream_code :=
            get_data_stream_code (p_data_stream_id      => p_data_stream_id,
                                  p_db_office_code      => l_db_office_code
                                 );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
      END;

      IF l_cascade_all = 'T'
      THEN                 -- delete all shef criteria for this data stream...
         DELETE FROM at_shef_decode
               WHERE data_stream_code = l_data_stream_code;
      END IF;

      -- delete data stream from database...
      BEGIN
         DELETE FROM at_data_stream_id
               WHERE data_stream_code = l_data_stream_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('CANNOT_DELETE_DATA_STREAM',
                            TRIM (p_data_stream_id)
                           );
      END;
   END;

   PROCEDURE cat_shef_data_streams (
      p_shef_data_streams   OUT      sys_refcursor,
      p_db_office_id        IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code   NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   BEGIN
      OPEN p_shef_data_streams FOR
         SELECT   a.data_stream_code, a.data_stream_id, a.data_stream_desc,
                  a.active_flag, b.office_id
             FROM at_data_stream_id a, cwms_office b
            WHERE a.db_office_code = b.office_code
              AND a.db_office_code = l_db_office_code
         ORDER BY a.data_stream_id;
   END cat_shef_data_streams;

   FUNCTION cat_shef_data_streams_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_data_stream_tab_t PIPELINED
   IS
      output_row     cat_data_stream_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_shef_data_streams (query_cursor, p_db_office_id);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_shef_data_streams_tab;

   PROCEDURE cat_shef_durations (p_shef_durations OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_shef_durations FOR
         SELECT   a.shef_duration_code, a.shef_duration_desc,
                  a.shef_duration_numeric
             FROM cwms_shef_duration a
         ORDER BY TO_NUMBER (a.shef_duration_numeric);
   END cat_shef_durations;

   PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_shef_time_zones FOR
         SELECT   shef_time_zone_id, shef_time_zone_desc
             FROM cwms_shef_time_zone
         ORDER BY shef_time_zone_id;
   END cat_shef_time_zones;

   PROCEDURE cat_shef_units (p_shef_units OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_shef_units FOR
         SELECT   unit_id shef_unit_id
             FROM cwms_unit
         ORDER BY abstract_param_code, unit_id;
   END cat_shef_units;

   FUNCTION cat_shef_durations_tab
      RETURN cat_shef_dur_tab_t PIPELINED
   IS
      output_row     cat_shef_dur_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_shef_durations (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_shef_durations_tab;

   FUNCTION cat_shef_time_zones_tab
      RETURN cat_shef_tz_tab_t PIPELINED
   IS
      output_row     cat_shef_tz_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_shef_time_zones (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_shef_time_zones_tab;

   FUNCTION cat_shef_units_tab
      RETURN cat_shef_units_tab_t PIPELINED
   IS
      output_row     cat_shef_units_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_shef_units (query_cursor);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_shef_units_tab;

----------------------------------
   PROCEDURE parse_criteria_record (
      p_shef_id              OUT      VARCHAR2,
      p_shef_pe_code         OUT      VARCHAR2,
      p_shef_tse_code        OUT      VARCHAR2,
      p_shef_duration_code   OUT      VARCHAR2,
      p_units                OUT      VARCHAR2,
      p_unit_sys             OUT      VARCHAR2,
      p_tz                   OUT      VARCHAR2,
      p_dltime               OUT      VARCHAR2,
      p_int_offset           OUT      VARCHAR2,
      p_int_backward         OUT      VARCHAR2,
      p_int_forward          OUT      VARCHAR2,
      p_cwms_ts_id           OUT      VARCHAR2,
      p_comment              OUT      VARCHAR2,
      p_criteria_record      IN       VARCHAR2
   )
   IS
      l_criteria_record      VARCHAR2 (600) := TRIM (p_criteria_record);
      l_record_length        NUMBER         := LENGTH (l_criteria_record);
      l_left_string          VARCHAR2 (50);
      l_left_length          NUMBER;
      l_right_string         VARCHAR2 (550);
      l_right_length         NUMBER;
      l_tmp                  NUMBER;
      --
      l_shef_id              VARCHAR2 (8);
      l_shef_pe_code         VARCHAR2 (2);
      l_shef_tse_code        VARCHAR2 (3);
      l_shef_duration_code   VARCHAR2 (4);
      l_cwms_ts_id           VARCHAR2 (183);
      --
      l_param_id             VARCHAR2 (32);
      l_param                VARCHAR2 (32);
      --
      l_dltime               VARCHAR2 (32)  := NULL;
      l_tz                   VARCHAR2 (32)  := NULL;
      l_units                VARCHAR2 (32)  := NULL;
      l_int_offset           VARCHAR2 (32)  := NULL;
      l_int_backward         VARCHAR2 (32)  := NULL;
      l_int_forward          VARCHAR2 (32)  := NULL;
      l_unit_sys             VARCHAR2 (32)  := NULL;

      --
      TYPE list_of_num_t IS TABLE OF NUMBER;

      l_pos                  list_of_num_t  := list_of_num_t ();
      l_pos_r                list_of_num_t  := list_of_num_t ();
      l_num                  NUMBER;
      l_end                  NUMBER;
      l_sub_length           NUMBER;
      l_sub_string           VARCHAR2 (64);
   BEGIN
      p_comment := NULL;

      -- Check if the line is commented out, i.e., starts with a "#",
      IF INSTR (l_criteria_record, '#') = 1
      THEN
         p_comment := 'COMMENT - This is a comment line';
         -- THIS IS A COMMENT LINE - IGNORE.
         GOTO fin;
      END IF;

      --
      -- split the line into the right and left parts...
      --
      l_tmp := INSTR (l_criteria_record, '=');

      IF l_tmp IN (0, 1, l_record_length)
      THEN
         p_comment := 'ERROR - Malformed criteria line';
         -- malformed record...
         GOTO fin;
      END IF;

      SELECT TRIM (SUBSTR (l_criteria_record, 1, l_tmp - 1)),
             TRIM (SUBSTR (l_criteria_record,
                           l_tmp + 1,
                           l_record_length - l_tmp
                          )
                  )
        INTO l_left_string,
             l_right_string
        FROM DUAL;

      --
      -- split the left side into its four components...
      --
      ---- Find the three expected period delimiters...
      ----
      FOR i IN 1 .. 3
      LOOP
         l_tmp := INSTR (l_left_string, '.', 1, i);

         IF l_tmp = 0
         THEN
            p_comment := 'ERROR - Malformed SHEF signature';
            -- malformed record...
            GOTO fin;
         ELSE
            l_pos.EXTEND;
            l_pos (i) := l_tmp;
         END IF;
      END LOOP;

      ----
      ---- SHEF Id...
      l_sub_length := l_pos (1) - 1;

      IF l_sub_length <= 0 OR l_sub_length > 8
      THEN
         p_comment := 'ERROR - SHEF Id is null or longer than 8 characters.';
         -- malformed record...
         GOTO fin;
      ELSE
         l_shef_id := TRIM (SUBSTR (l_left_string, 1, l_sub_length));
      END IF;

      ----
      ---- SHEF PE Code...
      l_sub_length := l_pos (2) - l_pos (1) - 1;

      IF l_sub_length != 2
      THEN
         p_comment := 'ERROR - SHEF PE code must be 2 characters in length.';
         -- malformed record...
         GOTO fin;
      ELSE
         l_shef_pe_code := TRIM (SUBSTR (l_left_string, l_pos (1) + 1, 2));
      END IF;

      ----
      ---- SHEF TSE Code...
      l_sub_length := l_pos (3) - l_pos (2) - 1;

      IF l_sub_length != 3
      THEN
         p_comment := 'ERROR - SHEF TSE code must be 3 characters in length.';
         -- malformed record...
         GOTO fin;
      ELSE
         l_shef_tse_code := TRIM (SUBSTR (l_left_string, l_pos (2) + 1, 3));
      END IF;

      ----
      ---- SHEF Duration Code...
      l_sub_length := LENGTH (l_left_string) - l_pos (3);

      IF l_sub_length < 1 OR l_sub_length > 4
      THEN
         p_comment :=
            'ERROR - SHEF Duration code must be between 1 adn 4 characters long.';
         -- malformed record...
         GOTO fin;
      ELSE
         l_shef_duration_code :=
                    TRIM (SUBSTR (l_left_string, l_pos (3) + 1, l_sub_length));
      END IF;

      --
      -- split the right side into its components...
      --
      ----
      ---- right side is parsed with ';' - need to determine how many elements -
      ---- there are...
      ----
      l_tmp := 1;
      l_num := 1;
      l_right_length := LENGTH (l_right_string);

      WHILE l_tmp < l_right_length
      LOOP
         l_tmp := INSTR (l_right_string, ';', 1, l_num);

         IF l_tmp = 0
         THEN
            l_tmp := l_right_length;
         ELSE
            l_pos_r.EXTEND;
            l_pos_r (l_num) := l_tmp;
            l_num := l_num + 1;
         END IF;
      END LOOP;

      ----
      ---- extract the ts_id from the right side...
      ----
      IF l_num = 1
      THEN
         l_tmp := l_right_length;
      ELSE
         l_tmp := l_pos_r (1) - 1;
      END IF;

      l_cwms_ts_id := SUBSTR (l_right_string, 1, l_tmp);

      ----
      ---- extract any of the parameters that are set...
      ----
      IF l_num > 1
      THEN
         l_num := l_num - 1;

         FOR i IN 1 .. l_num
         LOOP
            IF i = l_num
            THEN
               l_tmp := l_right_length;
            ELSE
               l_tmp := l_pos_r (i + 1) - 1;
            END IF;

            --
            l_sub_length := l_tmp - l_pos_r (i);

            IF l_sub_length > 0
            THEN
               l_sub_string :=
                        SUBSTR (l_right_string, l_pos_r (i) + 1,
                                l_sub_length);
               --
               l_param_id :=
                  UPPER (SUBSTR (l_right_string,
                                 l_pos_r (i) + 1,
                                   INSTR (l_right_string, '=', 1, i)
                                 - l_pos_r (i)
                                 - 1
                                )
                        );
               l_param :=
                  SUBSTR (l_right_string,
                          INSTR (l_right_string, '=', 1, i) + 1,
                          l_tmp - INSTR (l_right_string, '=', 1, i)
                         );

               CASE l_param_id
                  WHEN 'DLTIME'
                  THEN
                     l_dltime := l_param;
                  WHEN 'TZ'
                  THEN
                     l_tz := l_param;
                  WHEN 'UNITS'
                  THEN
                     l_units := l_param;
                  WHEN 'INTERVALOFFSET'
                  THEN
                     l_int_offset := l_param;
                  WHEN 'INTERVALBACKWARD'
                  THEN
                     l_int_backward := l_param;
                  WHEN 'INTERVALFORWARD'
                  THEN
                     l_int_forward := l_param;
                  WHEN 'UNITSYS'
                  THEN
                     l_unit_sys := l_param;
                  ELSE
                     p_comment :=
                           'ERROR - "'
                        || l_sub_string
                        || '" does not contain a valid processSHEFIT parameter.';
                     -- malformed record...
                     GOTO fin;
               END CASE;
            END IF;
         END LOOP;
      END IF;

      --
      -- Prepare to return data...
      --
      <<fin>>
      p_shef_id := l_shef_id;
      p_shef_pe_code := l_shef_pe_code;
      p_shef_tse_code := l_shef_tse_code;
      p_shef_duration_code := l_shef_duration_code;
      p_cwms_ts_id := l_cwms_ts_id;
      p_dltime := l_dltime;
      p_tz := l_tz;
      p_units := l_units;
      p_int_offset := l_int_offset;
      p_int_backward := l_int_backward;
      p_int_forward := l_int_forward;
      p_unit_sys := l_unit_sys;
   END;

   PROCEDURE cat_shef_crit_lines (
      p_shef_crit_lines   OUT      sys_refcursor,
      p_data_stream       IN       VARCHAR2,
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code     NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_data_stream_code   NUMBER
                    := get_data_stream_code (p_data_stream, l_db_office_code);
   BEGIN
      OPEN p_shef_crit_lines FOR
         SELECT    a.shef_loc_id
                || '.'
                || a.shef_pe_code
                || '.'
                || a.shef_tse_code
                || '.'
                || a.shef_duration_numeric
                || '='
                || b.cwms_ts_id
                || CASE
                      WHEN a.shef_unit_code IS NOT NULL
                         THEN ';Units=' || c.unit_id
                   END
                || CASE
                      WHEN a.shef_time_zone_code IS NOT NULL
                         THEN ';TZ=' || d.shef_time_zone_id
                   END
                || ';DLTime='
                || CASE
                      WHEN a.dl_time = 'T'
                         THEN 'true'
                      ELSE 'false'
                   END
                || CASE
                      WHEN e.interval_offset_id NOT IN
                             (cwms_util.utc_offset_irregular,
                              cwms_util.utc_offset_undefined
                             )
                         THEN    ';IntervalOffset='
                              || cwms_util.get_interval_string
                                                        (e.interval_utc_offset)
                              || CASE
                                    WHEN e.interval_forward IS NOT NULL
                                       THEN    ';IntervalForward='
                                            || cwms_util.get_interval_string
                                                           (e.interval_forward)
                                 END
                              || CASE
                                    WHEN e.interval_backward IS NOT NULL
                                       THEN    ';IntervalBackward='
                                            || cwms_util.get_interval_string
                                                          (e.interval_backward)
                                 END
                   END shef_crit_line
           FROM at_shef_decode a,
                mv_cwms_ts_id b,
                cwms_unit c,
                cwms_shef_time_zone d,
                at_cwms_ts_spec e,
                at_base_location f
          WHERE a.ts_code = b.ts_code
            AND a.shef_unit_code = c.unit_code
            AND a.shef_time_zone_code = d.shef_time_zone_code
            AND a.ts_code = e.ts_code
            AND b.base_location_code = f.base_location_code
            -- AND e.active_flag = 'T'
             --AND f.active_flag = 'T'
            AND a.data_stream_code = l_data_stream_code;
   END cat_shef_crit_lines;

   FUNCTION cat_shef_crit_lines_tab (
      p_data_stream    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_shef_crit_lines_tab_t PIPELINED
   IS
      output_row     cat_shef_crit_lines_rec_t;
      query_cursor   sys_refcursor;
   BEGIN
      cat_shef_crit_lines (query_cursor, p_data_stream, p_db_office_id);

      LOOP
         FETCH query_cursor
          INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END cat_shef_crit_lines_tab;
END cwms_shef;
/