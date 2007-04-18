/* Formatted on 2007/04/18 08:52 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_shef
AS
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

   PROCEDURE store_shef_spec (
      p_cwms_ts_id              IN   VARCHAR2,
      p_data_stream_id          IN   VARCHAR2,
      p_shef_pe_code            IN   VARCHAR2,
      p_shef_duration_code      IN   VARCHAR2,
      p_shef_tse_code           IN   VARCHAR2,
      p_shef_unit_id            IN   VARCHAR2,
      p_time_zone_id            IN   VARCHAR2,
      p_daylight_savings        IN   VARCHAR2 DEFAULT 'F',  -- psuedo boolean.
      p_snap_forward_minutes    IN   NUMBER,
      p_snap_backward_minutes   IN   NUMBER,
      p_loc_category_id         IN   VARCHAR2,
      p_loc_group_id            IN   VARCHAR2,
      p_interval_utc_offset     IN   NUMBER,                    -- in minutes.
      p_ts_active_flag          IN   VARCHAR2 DEFAULT 'T',
      p_permit_multiple_specs   IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id            IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code     NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
      l_cwms_ts_code       NUMBER
               := cwms_util.get_cwms_ts_code (p_cwms_ts_id, l_db_office_code);
      l_data_stream_code   NUMBER
                 := get_data_stream_code (p_data_stream_id, l_db_office_code);
   BEGIN
      NULL;
   END;

   PROCEDURE delete_shef_spec (
      p_cwms_ts_id       IN   VARCHAR2,
      p_data_stream_id   IN   VARCHAR2,
      p_db_office_id     IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      NULL;
   END;

-- left kernal must be unique.

   -- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
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
-- -----------------------------------------------------------------------------
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

   PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT sys_refcursor)
   IS
   BEGIN
      OPEN p_shef_time_zones FOR
         SELECT   shef_time_zone_id, shef_time_zone_desc
             FROM cwms_shef_time_zone
         ORDER BY shef_time_zone_id;
   END cat_shef_time_zones;

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
----------------------------------
END cwms_shef;
/