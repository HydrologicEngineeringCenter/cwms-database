/* Formatted on 2007/10/29 13:38 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_20.cwms_apex
AS
   TYPE varchar2_t IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;

   PROCEDURE aa1 (p_string IN VARCHAR2)
   IS
   BEGIN
--      INSERT INTO aa1
--                  (stringstuff
--                  )
--           VALUES (p_string
--                  );
--                  commit;
      NULL;
   END;

   -- Private functions --{{{
   PROCEDURE delete_collection (                                         --{{{
                                -- Delete the collection if it exists
                                p_collection_name IN VARCHAR2)
   IS
   BEGIN
      IF (apex_collection.collection_exists (p_collection_name))
      THEN
         apex_collection.delete_collection (p_collection_name);
      END IF;
   END delete_collection;                                                --}}}

   --
   --
   PROCEDURE csv_to_array (                                              --{{{
      -- Utility to take a CSV string, parse it into a PL/SQL table
      -- Note that it takes care of some elements optionally enclosed
      -- by double-quotes.
      p_csv_string   IN       VARCHAR2,
      p_array        OUT      wwv_flow_global.vc_arr2,
      p_separator    IN       VARCHAR2 := ','
   )
   IS
      l_start_separator   PLS_INTEGER    := 0;
      l_stop_separator    PLS_INTEGER    := 0;
      l_length            PLS_INTEGER    := 0;
      l_idx               BINARY_INTEGER := 0;
      l_quote_enclosed    BOOLEAN        := FALSE;
      l_offset            PLS_INTEGER    := 1;
   BEGIN
      l_length := NVL (LENGTH (p_csv_string), 0);

      IF (l_length <= 0)
      THEN
         RETURN;
      END IF;

      LOOP
         l_idx := l_idx + 1;
         l_quote_enclosed := FALSE;

         IF SUBSTR (p_csv_string, l_start_separator + 1, 1) = '"'
         THEN
            l_quote_enclosed := TRUE;
            l_offset := 2;
            l_stop_separator :=
                   INSTR (p_csv_string, '"', l_start_separator + l_offset, 1);
         ELSE
            l_offset := 1;
            l_stop_separator :=
               INSTR (p_csv_string,
                      p_separator,
                      l_start_separator + l_offset,
                      1
                     );
         END IF;

         IF l_stop_separator = 0
         THEN
            l_stop_separator := l_length + 1;
         END IF;

         p_array (l_idx) :=
            (SUBSTR (p_csv_string,
                     l_start_separator + l_offset,
                     (l_stop_separator - l_start_separator - l_offset
                     )
                    )
            );
         EXIT WHEN l_stop_separator >= l_length;

         IF l_quote_enclosed
         THEN
            l_stop_separator := l_stop_separator + 1;
         END IF;

         l_start_separator := l_stop_separator;
      END LOOP;
   END csv_to_array;                                                     --}}}

   ---
   PROCEDURE crit_to_array (                                             --{{{
      -- Utility to take a criteria file string, parse it into a PL/SQL table
      --
      p_criteria_record   IN       VARCHAR2,
      p_comment           OUT      VARCHAR2,
      p_array             OUT      wwv_flow_global.vc_arr2
   )
   IS
   BEGIN
      cwms_shef.parse_criteria_record (p_shef_id                 => p_array
                                                                           (2),
                                       p_shef_pe_code            => p_array
                                                                           (3),
                                       p_shef_tse_code           => p_array
                                                                           (4),
                                       p_shef_duration_code      => p_array
                                                                           (5),
                                       p_units                   => p_array
                                                                           (6),
                                       p_unit_sys                => p_array
                                                                           (7),
                                       p_tz                      => p_array
                                                                           (8),
                                       p_dltime                  => p_array
                                                                           (9),
                                       p_int_offset              => p_array
                                                                           (10),
                                       p_int_backward            => p_array
                                                                           (11),
                                       p_int_forward             => p_array
                                                                           (12),
                                       p_cwms_ts_id              => p_array
                                                                           (1),
                                       p_comment                 => p_comment,
                                       p_criteria_record         => p_criteria_record
                                      );
   END;

   --
   PROCEDURE get_records (p_blob IN BLOB, p_records OUT varchar2_t)      --{{{
   IS
      l_record_separator   VARCHAR2 (2) := CHR (13) || CHR (10);
      l_last               INTEGER;
      l_current            INTEGER;
   BEGIN
      -- Sigh, stupid DOS/Unix newline stuff. If HTMLDB has generated the file,
      -- it will be a Unix text file. If user has manually created the file, it
      -- will have DOS newlines.
      -- If the file has a DOS newline (cr+lf), use that
      -- If the file does not have a DOS newline, use a Unix newline (lf)
      IF (NVL (DBMS_LOB.INSTR (p_blob,
                               UTL_RAW.cast_to_raw (l_record_separator),
                               1,
                               1
                              ),
               0
              ) = 0
         )
      THEN
         l_record_separator := CHR (10);
      END IF;

      l_last := 1;

      LOOP
         l_current :=
            DBMS_LOB.INSTR (p_blob,
                            UTL_RAW.cast_to_raw (l_record_separator),
                            l_last,
                            1
                           );
         EXIT WHEN (NVL (l_current, 0) = 0);
         p_records (p_records.COUNT + 1) :=
            UTL_RAW.cast_to_varchar2 (DBMS_LOB.SUBSTR (p_blob,
                                                       l_current - l_last,
                                                       l_last
                                                      )
                                     );
         l_last := l_current + LENGTH (l_record_separator);
      END LOOP;
   END get_records;                                                      --}}}

   --}}}
   -- Utility functions --{{{
   PROCEDURE parse_textarea (                                            --{{{
      p_textarea          IN   VARCHAR2,
      p_collection_name   IN   VARCHAR2
   )
   IS
      l_index     INTEGER;
      l_string    VARCHAR2 (32767)
                := TRANSLATE (p_textarea, CHR (10) || CHR (13) || ' ,',
                              '@@@@');
      l_element   VARCHAR2 (100);
   BEGIN
      l_string := l_string || '@';
      htmldb_collection.create_or_truncate_collection (p_collection_name);

      LOOP
         l_index := INSTR (l_string, '@');
         EXIT WHEN NVL (l_index, 0) = 0;
         l_element := SUBSTR (l_string, 1, l_index - 1);

         IF (TRIM (l_element) IS NOT NULL)
         THEN
            apex_collection.add_member (p_collection_name, l_element);
         END IF;

         l_string := SUBSTR (l_string, l_index + 1);
      END LOOP;
   END parse_textarea;                                                   --}}}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
   PROCEDURE parse_file (                                                --{{{
      p_file_name               IN       VARCHAR2,
      p_collection_name         IN       VARCHAR2,
      p_error_collection_name   IN       VARCHAR2,
      p_headings_item           IN       VARCHAR2,
      p_columns_item            IN       VARCHAR2,
      p_ddl_item                IN       VARCHAR2,
      p_number_of_records       OUT      NUMBER,
        p_number_of_columns       OUT      number,
      p_is_csv                  IN       VARCHAR2 DEFAULT 'T',
      p_table_name              IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_blob           BLOB;
      l_records        varchar2_t;
      l_record         wwv_flow_global.vc_arr2;
      l_datatypes      wwv_flow_global.vc_arr2;
      l_headings       VARCHAR2 (4000);
      l_columns        VARCHAR2 (4000);
      l_seq_id         NUMBER;
      l_num_columns    INTEGER;
      l_ddl            VARCHAR2 (4000);
      l_is_csv         BOOLEAN;
      l_is_crit_file   BOOLEAN;
      l_tmp            NUMBER;
      l_comment        VARCHAR2 (128)          := NULL;
   BEGIN
      IF cwms_util.is_true (NVL (p_is_csv, 'T'))
      THEN
         l_is_csv := TRUE;
         l_is_crit_file := FALSE;
      ELSE
         l_is_csv := FALSE;
         l_is_crit_file := TRUE;
      END IF;

      aa1 ('parse collection name: ' || p_collection_name);

      IF (p_table_name IS NOT NULL)
      THEN
         BEGIN
            EXECUTE IMMEDIATE 'drop table ' || p_table_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         l_ddl := 'create table ' || p_table_name || ' ' || v (p_ddl_item);
         apex_util.set_session_state ('P149_DEBUG', l_ddl);

         EXECUTE IMMEDIATE l_ddl;

         l_ddl :=
               'insert into '
            || p_table_name
            || ' '
            || 'select '
            || v (p_columns_item)
            || ' '
            || 'from htmldb_collections '
            || 'where seq_id > 1 and collection_name='''
            || p_collection_name
            || '''';
         apex_util.set_session_state ('P149_DEBUG',
                                      v ('P149_DEBUG') || '/' || l_ddl
                                     );

         EXECUTE IMMEDIATE l_ddl;

         RETURN;
      END IF;

      BEGIN
         SELECT blob_content
           INTO l_blob
           FROM wwv_flow_files
          WHERE NAME = p_file_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            raise_application_error (-20000,
                                     'File not found, id=' || p_file_name
                                    );
      END;

      get_records (l_blob, l_records);

      IF (l_records.COUNT < 2)
      THEN
         raise_application_error (-20000,
                                     'File must have at least 2 ROWS, id='
                                  || p_file_name
                                 );
      END IF;

      -- Initialize collection
      apex_collection.create_or_truncate_collection (p_collection_name);
      apex_collection.create_or_truncate_collection (p_error_collection_name);

      -- Get column headings and datatypes
      IF l_is_crit_file
      THEN
         l_record (1) := 'Line No.';
         l_datatypes (1) := 'number';
         l_record (2) := 'cwms_ts_id';
         l_datatypes (2) := 'varchar2(183)';
         l_record (3) := 'shef_id';
         l_datatypes (3) := 'varchar2(32)';
         l_record (4) := 'pe_code';
         l_datatypes (4) := 'varchar2(32)';
         l_record (5) := 'tse_code';
         l_datatypes (5) := 'varchar2(32)';
         l_record (6) := 'dur_code';
         l_datatypes (6) := 'varchar2(32)';
         l_record (7) := 'units';
         l_datatypes (7) := 'varchar2(32)';
         l_record (8) := 'unit_system';
         l_datatypes (8) := 'varchar2(32)';
         l_record (9) := 'tz';
         l_datatypes (9) := 'varchar2(32)';
         l_record (10) := 'dltime';
         l_datatypes (10) := 'varchar2(32)';
         l_record (11) := 'int_offset';
         l_datatypes (11) := 'varchar2(32)';
         l_record (12) := 'int_backward';
         l_datatypes (12) := 'varchar2(32)';
         l_record (13) := 'int_forward';
         l_datatypes (13) := 'varchar2(32)';
      ELSE
         csv_to_array (l_records (1), l_record);
         csv_to_array (l_records (2), l_datatypes);
      END IF;

      l_num_columns := l_record.COUNT;

      IF (l_num_columns > 50)
      THEN
         raise_application_error (-20000,
                                     'Max. of 50 columns allowed, id='
                                  || p_file_name
                                 );
      END IF;
      
      p_number_of_columns := l_num_columns;
      
      -- Get column headings and names
      FOR i IN 1 .. l_record.COUNT
      LOOP
         l_headings := l_headings || ':' || l_record (i);
         l_columns := l_columns || ',c' || LPAD (i, 3, '0');
      END LOOP;

      l_headings := LTRIM (l_headings, ':');
      l_columns := LTRIM (l_columns, ',');
      apex_util.set_session_state (p_headings_item, l_headings);
      apex_util.set_session_state (p_columns_item, l_columns);

      -- Get datatypes
      FOR i IN 1 .. l_record.COUNT
      LOOP
         l_ddl := l_ddl || ',' || l_record (i) || ' ' || l_datatypes (i);
      END LOOP;

      l_ddl := '(' || LTRIM (l_ddl, ',') || ')';
      apex_util.set_session_state (p_ddl_item, l_ddl);
      -- Save data into specified collection
      p_number_of_records := l_records.COUNT;

      FOR i IN 1 .. p_number_of_records
      LOOP
         IF l_is_crit_file
         THEN
            crit_to_array (l_records (i), l_comment, l_record);
         ELSE
            csv_to_array (l_records (i), l_record);
         END IF;

         IF INSTR (l_comment, 'ERROR') = 1
         THEN
            l_seq_id :=
                apex_collection.add_member (p_error_collection_name, 'dummy');
            apex_collection.update_member_attribute
                               (p_collection_name      => p_error_collection_name,
                                p_seq                  => l_seq_id,
                                p_attr_number          => 1,
                                p_attr_value           => i
                               );
            apex_collection.update_member_attribute
                                (p_collection_name      => p_error_collection_name,
                                 p_seq                  => l_seq_id,
                                 p_attr_number          => 2,
                                 p_attr_value           => l_comment
                                );
            apex_collection.update_member_attribute
                                (p_collection_name      => p_error_collection_name,
                                 p_seq                  => l_seq_id,
                                 p_attr_number          => 3,
                                 p_attr_value           => l_records (i)
                                );
         ELSIF INSTR (l_comment, 'COMMENT') = 1
         THEN
            NULL;                                  -- comment, so throw away.
         ELSE
            l_seq_id :=
                      apex_collection.add_member (p_collection_name, 'dummy');
            apex_collection.update_member_attribute
                                     (p_collection_name      => p_collection_name,
                                      p_seq                  => l_seq_id,
                                      p_attr_number          => 1,
                                      p_attr_value           => i
                                     );

            FOR j IN 1 .. l_record.COUNT
            LOOP
               apex_collection.update_member_attribute
                                     (p_collection_name      => p_collection_name,
                                      p_seq                  => l_seq_id,
                                      p_attr_number          => j + 1,
                                      p_attr_value           => l_record (j)
                                     );
            END LOOP;
         END IF;
      END LOOP;

--      DELETE FROM wwv_flow_files
--            WHERE NAME = p_file_name;
      SELECT COUNT (*)
        INTO l_seq_id
        FROM apex_collections
       WHERE collection_name = p_collection_name;

      aa1 (   'parse collection name: '
           || p_collection_name
           || ' Row count: '
           || l_seq_id
          );
   END;

--
--  example:..
--     desired result is either:
--     if p_expr_value is equal to the p_expr_value_test          -
--     then the string:                                                    -
--             ' 1 = 1 '   is returned                                       -
--      else the string returned is...
--              ' p_column_id = p_expr_string '                            -
--
--      For exmple:
--         get_equal_predicate('sub_parameter_id', ':P535_SUB_PARM', :P535_SUB_PARM, '%');   -
--      if :P535_SUB_PARM is '%' then....
--              " 1=1 "  is returned.
--
--      if :P535_SUB_PARM is not '%' then...
--               " sub_parameter_id = :P535_SUB_PARM " is returned.
--      NOTE: quotes are not part of the string - there is a leading and trailing space character.
--
   FUNCTION get_equal_predicate (
      p_column_id         IN   VARCHAR2,
      p_expr_string       IN   VARCHAR2,
      p_expr_value        IN   VARCHAR2,
      p_expr_value_test   IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_return_predicate   VARCHAR2 (100) := ' 1=1 ';
      l_column_id          VARCHAR2 (31)  := TRIM (p_column_id);
   BEGIN
      IF p_expr_value != p_expr_value_test
      THEN
         l_return_predicate :=
                 ' ' || l_column_id || ' = ''' || TRIM (p_expr_value)
                 || ''' ';
      ELSIF p_expr_value IS NULL
      THEN
         l_return_predicate := ' ' || l_column_id || ' IS NULL ';
      END IF;

      RETURN l_return_predicate;
   END;

   FUNCTION get_primary_db_office_id
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN cwms_util.user_office_id;
   END get_primary_db_office_id;

   PROCEDURE store_parsed_crit_file (
      p_parsed_collection_name      IN   VARCHAR2,
      p_store_err_collection_name   IN   VARCHAR2,
      p_loc_group_id                IN   VARCHAR2,
      p_data_stream_id              IN   VARCHAR2,
      p_db_office_id                IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_parsed_rows          NUMBER;
      l_shef_duration_code   VARCHAR2 (5);
      l_line_no              VARCHAR2 (32);
      l_cwms_ts_id           VARCHAR2 (200);
      l_shef_id              VARCHAR2 (32);
      l_pe_code              VARCHAR2 (32);
      l_tse_code             VARCHAR2 (32);
      l_dur_code             VARCHAR2 (32);
      l_units                VARCHAR2 (32);
      l_unit_system          VARCHAR2 (32);
      l_tz                   VARCHAR2 (32);
      l_dltime               VARCHAR2 (32);
      l_int_offset           VARCHAR2 (32);
      l_int_backward         VARCHAR2 (32);
      l_int_forward          VARCHAR2 (32);
      l_min                  NUMBER;
      l_max                  NUMBER;
   BEGIN
      aa1 (   'store_parsed_crit_file - collection name: '
           || p_parsed_collection_name
          );

      SELECT COUNT (*), MIN (seq_id), MAX (seq_id)
        INTO l_parsed_rows, l_min, l_max
        FROM apex_collections
       WHERE collection_name = p_parsed_collection_name;

      aa1 (   'l_parsed_rows = '
           || l_parsed_rows
           || ' min '
           || l_min
           || ' max '
           || l_max
          );

      FOR i IN 1 .. l_parsed_rows
      LOOP
         aa1 ('looping: ' || i);

         SELECT c001, c002, c003, c004, c005,
                c006, c007, c008, c009, c010,
                c011, c012, c013
           INTO l_line_no, l_cwms_ts_id, l_shef_id, l_pe_code, l_tse_code,
                l_dur_code, l_units, l_unit_system, l_tz, l_dltime,
                l_int_offset, l_int_backward, l_int_forward
           FROM apex_collections
          WHERE collection_name = p_parsed_collection_name AND seq_id = i;

         -- convert duration numeric to duration code
         BEGIN
            SELECT shef_duration_code || shef_duration_numeric
              INTO l_shef_duration_code
              FROM cwms_shef_duration
             WHERE shef_duration_numeric = l_dur_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_shef_duration_code := 'V' || TRIM (l_dur_code);
         END;

         -- confert dltime to t or f
         IF l_dltime IS NOT NULL
         THEN
            IF l_dltime = 'false'
            THEN
               l_dltime := 'F';
            ELSIF l_dltime = 'true'
            THEN
               l_dltime := 'T';
            END IF;
         END IF;

         aa1 (   'storing spec: '
              || l_cwms_ts_id
              || ' --datastream->'
              || p_data_stream_id
              || ' --shef id->'
              || l_shef_id
             );
         --
         aa1 (   'l_int_offset = '
              || l_int_offset
              || ' l_int_forward '
              || l_int_forward
              || ' l_int_backward '
              || l_int_backward
             );
         cwms_shef.store_shef_spec
                        (p_cwms_ts_id                 => l_cwms_ts_id,
                         p_data_stream_id             => p_data_stream_id,
                         p_loc_group_id               => p_loc_group_id,
                         p_shef_loc_id                => l_shef_id,
                         -- normally use loc_group_id
                         p_shef_pe_code               => l_pe_code,
                         p_shef_tse_code              => l_tse_code,
                         p_shef_duration_code         => l_shef_duration_code,
                         p_shef_unit_id               => l_units,
                         p_time_zone_id               => l_tz,
                         p_daylight_savings           => l_dltime,
                         -- psuedo boolean.
                         p_interval_utc_offset        => TO_NUMBER
                                                                 (l_int_offset),
                         -- in minutes.
                         p_snap_forward_minutes       => TO_NUMBER
                                                                (l_int_forward),
                         p_snap_backward_minutes      => TO_NUMBER
                                                               (l_int_backward),
                         p_ts_active_flag             => NULL,
                         p_db_office_id               => p_db_office_id
                        );
      END LOOP;
   END;

   PROCEDURE store_parsed_loc_short_file (
      p_parsed_collection_name      IN   VARCHAR2,
      p_store_err_collection_name   IN   VARCHAR2,
      p_db_office_id                IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_id     VARCHAR2 (200);
      l_public_name     VARCHAR2 (200);
      l_county_name     VARCHAR2 (200);
      l_state_initial   VARCHAR2 (20);
      l_active          VARCHAR2 (10);
      l_ignorenulls     VARCHAR2 (1);
      l_parsed_rows     NUMBER;
      l_line_no         VARCHAR2 (32);
      l_min             NUMBER;
      l_max             NUMBER;
   BEGIN
      aa1 (   'store_parsed_loc_short_file - collection name: '
           || p_parsed_collection_name
          );

      SELECT COUNT (*), MIN (seq_id), MAX (seq_id)
        INTO l_parsed_rows, l_min, l_max
        FROM apex_collections
       WHERE collection_name = p_parsed_collection_name;

      aa1 (   'l_parsed_rows = '
           || l_parsed_rows
           || ' min '
           || l_min
           || ' max '
           || l_max
          );

-- Start at 2 to skip first line of column titles
      FOR i IN 2 .. l_parsed_rows
      LOOP
         aa1 ('looping: ' || i);

         SELECT c001, c002, c003, c004,
                c005, c006
           INTO l_line_no, l_location_id, l_public_name, l_county_name,
                l_state_initial, l_active
           FROM apex_collections
          WHERE collection_name = p_parsed_collection_name AND seq_id = i;

         aa1 ('storing locs: ' || l_location_id);
--
         cwms_loc.update_location (p_location_id        => l_location_id,
                                   p_public_name        => l_public_name,
                                   p_county_name        => l_county_name,
                                   p_state_initial      => l_state_initial,
                                   p_active             => l_active,
                                   p_ignorenulls        => 'T',
                                   p_db_office_id       => p_db_office_id
                                  );
      END LOOP;
   END;

   PROCEDURE store_parsed_loc_full_file (
      p_parsed_collection_name      IN   VARCHAR2,
      p_store_err_collection_name   IN   VARCHAR2,
      p_db_office_id                IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_id        VARCHAR2 (200);
      l_location_type      VARCHAR2 (200);
      l_elevation          NUMBER;
      l_elev_unit_id       VARCHAR2 (200);
      l_vertical_datum     VARCHAR2 (200);
      l_latitude           NUMBER;
      l_longitude          NUMBER;
      l_horizontal_datum   VARCHAR2 (200);
      l_public_name        VARCHAR2 (200);
      l_long_name          VARCHAR2 (200);
      l_description        VARCHAR2 (200);
      l_time_zone_id       VARCHAR2 (200);
      l_county_name        VARCHAR2 (200);
      l_state_initial      VARCHAR2 (200);
      l_active             VARCHAR2 (200);
      l_ignorenulls        VARCHAR2 (1);
      l_parsed_rows        NUMBER;
      l_line_no            VARCHAR2 (32);
      l_min                NUMBER;
      l_max                NUMBER;
   BEGIN
      aa1 (   'store_parsed_loc_full_file - collection name: '
           || p_parsed_collection_name
          );

      SELECT COUNT (*), MIN (seq_id), MAX (seq_id)
        INTO l_parsed_rows, l_min, l_max
        FROM apex_collections
       WHERE collection_name = p_parsed_collection_name;

      aa1 (   'l_parsed_rows = '
           || l_parsed_rows
           || ' min '
           || l_min
           || ' max '
           || l_max
          );

--  Start at   2,   Skip first line in file to bypass column headings
      FOR i IN 2 .. l_parsed_rows
      LOOP
         aa1 ('looping: ' || i);

         SELECT c001, c002, c003, c004,
                c005, c006, c007,
                c008, c009, c010,
                c011, c012, c013, c014,
                c015, c016
           INTO l_line_no, l_location_id, l_public_name, l_county_name,
                l_state_initial, l_active, l_location_type,
                l_vertical_datum, l_elevation, l_elev_unit_id,
                l_horizontal_datum, l_latitude, l_longitude, l_time_zone_id,
                l_long_name, l_description
           FROM apex_collections
          WHERE collection_name = p_parsed_collection_name AND seq_id = i;

         aa1 ('storing locs: ' || l_location_id);
         --
         cwms_loc.update_location (l_location_id,
                                   l_location_type,
                                   l_elevation,
                                   l_elev_unit_id,
                                   l_vertical_datum,
                                   l_latitude,
                                   l_longitude,
                                   l_horizontal_datum,
                                   l_public_name,
                                   l_long_name,
                                   l_description,
                                   l_time_zone_id,
                                   l_county_name,
                                   l_state_initial,
                                   l_active,
                                   'F',
                                   p_db_office_id
                                  );
      END LOOP;
   END;
END cwms_apex;
/