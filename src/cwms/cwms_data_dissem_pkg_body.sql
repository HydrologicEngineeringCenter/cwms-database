/* Formatted on 4/29/2014 1:45:31 PM (QP5 v5.215.12089.38647) */
CREATE OR REPLACE PACKAGE BODY cwms_data_dissem
AS
   FUNCTION allowed_dest (p_ts_code IN NUMBER)
      RETURN INT
   IS
      l_filter_to_CorpsNet   VARCHAR2 (1);
      l_filter_to_DMZ        VARCHAR2 (1);
      l_db_office_code       NUMBER;
   BEGIN
      --
      IF allowed_to_dmz (p_ts_code)
      THEN
         RETURN stream_to_dmz;
      ELSIF allowed_to_CorpsNet (p_ts_code)
      THEN
         RETURN stream_to_CorpsNet;
      ELSE
         RETURN do_not_stream;
      END IF;
   --
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN do_not_stream;
   END;

   FUNCTION allowed_to_corpsnet (p_ts_code IN NUMBER)
      RETURN BOOLEAN
   IS
      l_filter_to_CorpsNet   VARCHAR2 (1);
      l_filter_to_DMZ        VARCHAR2 (1);
      l_db_office_code       NUMBER;

      l_cnt                  NUMBER := 0;
   BEGIN
      BEGIN
         SELECT db_office_code
           INTO l_db_office_code
           FROM at_cwms_ts_id
          WHERE ts_code = p_ts_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN FALSE;
      END;

      BEGIN
         SELECT filter_to_corpsnet, filter_to_dmz
           INTO l_filter_to_corpsnet, l_filter_to_dmz
           FROM at_data_dissem
          WHERE office_code = l_db_office_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_filter_to_CorpsNet := 'F';
            l_filter_to_DMZ := 'T';
      END;

      --
      -- If filtering to CorpsNet is False, then all data will be sent,
      -- therefore return TRUE.
      IF l_filter_to_CorpsNet = 'F'
      THEN
         RETURN TRUE;
      END IF;

      -- Filtering to CorpsNet is True, however if Filtering to DMZ is False
      -- then all data flows to CorpsNet too.
      IF l_filter_to_DMZ = 'F'
      THEN
         RETURN TRUE;
      END IF;

      -- Filtering to CorpsNet is enforced, therefore check if ts_code is in
      -- include/exclude lists...
      SELECT COUNT (*)
        INTO l_cnt
        FROM at_ts_group_assignment
       WHERE ts_group_code = CorpsNet_include_gp_code AND ts_code = p_ts_code;

      -- if l_cnt is zero, then ts_code is not in include list, so
      -- return FALSE...
      IF l_cnt = 0
      THEN
         RETURN FALSE;
      END IF;

      -- ts_code is in include list, check if it's in CorpsNet exclude list
      SELECT COUNT (*)
        INTO l_cnt
        FROM at_ts_group_assignment
       WHERE ts_group_code = CorpsNet_exclude_gp_code AND ts_code = p_ts_code;

      -- if l_cnt is zero, then ok to send to CorpsNet...
      IF l_cnt = 0
      THEN
         RETURN TRUE;
      END IF;

      -- if you get here, then do not send to CorpsNet...
      RETURN FALSE;
   END;

   FUNCTION allowed_to_dmz (p_ts_code IN NUMBER)
      RETURN BOOLEAN
   IS
      l_filter_to_CorpsNet   VARCHAR2 (1);
      l_filter_to_DMZ        VARCHAR2 (1);
      l_db_office_code       NUMBER;

      l_cnt                  NUMBER := 0;
   BEGIN
      BEGIN
         SELECT db_office_code
           INTO l_db_office_code
           FROM at_cwms_ts_id
          WHERE ts_code = p_ts_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN FALSE;
      END;

      BEGIN
         SELECT filter_to_corpsnet, filter_to_dmz
           INTO l_filter_to_corpsnet, l_filter_to_dmz
           FROM at_data_dissem
          WHERE office_code = l_db_office_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_filter_to_CorpsNet := 'F';
            l_filter_to_DMZ := 'T';
      END;

      --
      -- If filtering to DMZ is False, then all data will be sent to DMZ,
      -- therefore return TRUE.
      IF l_filter_to_DMZ = 'F'
      THEN
         RETURN TRUE;
      END IF;

      -- Filtering is True, therefore check if ts_code is in include/exclude
      -- lists...
      SELECT COUNT (*)
        INTO l_cnt
        FROM at_ts_group_assignment
       WHERE ts_group_code = DMZ_include_gp_code AND ts_code = p_ts_code;

      -- if l_cnt is zero, then ts_code is not in include list, so
      -- return FALSE...
      IF l_cnt = 0
      THEN
         RETURN FALSE;
      END IF;

      -- ts_code is in include list, check if it's in any of the exclude lists
      SELECT COUNT (*)
        INTO l_cnt
        FROM at_ts_group_assignment
       WHERE     ts_group_code IN
                    (CorpsNet_exclude_gp_code, DMZ_exclude_gp_code)
             AND ts_code = p_ts_code;

      -- if l_cnt is zero, then ok to send to DMZ...
      IF l_cnt = 0
      THEN
         RETURN TRUE;
      END IF;

      -- if you get here, then do not send to DMZ...
      RETURN FALSE;
   END;


   FUNCTION is_filtering_to (p_dest_db IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_db_office_code       NUMBER;
      l_dest_db              VARCHAR2 (16);
      l_filter_to_CorpsNet   VARCHAR2 (1);
      l_filter_to_DMZ        VARCHAR2 (1);
   BEGIN
      --
      IF UPPER (TRIM (p_dest_db)) = DMZ_DB
      THEN
         l_dest_db := DMZ_DB;
      ELSIF UPPER (TRIM (p_dest_db)) = CorpsNet_DB
      THEN
         l_dest_db := CorpsNet_DB;
      ELSE
         cwms_err.raise (
            'ERROR',
               'The p_dest_db of: '
            || TRIM (p_dest_db)
            || ' is not recognized. Valid p_dest_db are: '
            || DMZ_DB
            || ' and '
            || CorpsNet_DB
            || '.');
      END IF;

      l_db_office_code := cwms_util.get_db_office_code (p_office_id);

      --
      BEGIN
         SELECT filter_to_corpsnet, filter_to_dmz
           INTO l_filter_to_corpsnet, l_filter_to_dmz
           FROM at_data_dissem
          WHERE office_code = l_db_office_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_filter_to_CorpsNet := 'F';
            l_filter_to_DMZ := 'T';
      END;

      --
      IF l_dest_db = DMZ_DB
      THEN
         IF l_filter_to_DMZ = 'T'
         THEN
            RETURN TRUE;
         END IF;
      ELSIF l_dest_db = CorpsNet_DB
      THEN
         IF l_filter_to_CorpsNet = 'T'
         THEN
            RETURN TRUE;
         END IF;
      END IF;

      --
      RETURN FALSE;
   END;

   PROCEDURE set_ts_filtering (p_filter_to_corpsnet   IN VARCHAR2,
                               p_filter_to_dmz        IN VARCHAR2,
                               p_office_id            IN VARCHAR2)
   IS
      l_office_code          NUMBER;
      l_filter_to_dmz        VARCHAR2 (5);
      l_filter_to_corpsnet   VARCHAR2 (5);
   BEGIN
      l_office_code := cwms_util.get_db_office_code (p_office_id);
      --
      l_filter_to_dmz := cwms_util.return_t_or_f_flag (p_filter_to_dmz);
      l_filter_to_corpsnet :=
         cwms_util.return_t_or_f_flag (p_filter_to_corpsnet);

      IF l_filter_to_corpsnet = 'T' AND l_filter_to_dmz = 'F'
      THEN
         cwms_err.raise (
            'ERROR',
            'The combination of CorpsNet Filtering TRUE and DMZ Filtering FALSE is not allowed.');
      END IF;

      BEGIN
         UPDATE at_data_dissem
            SET filter_to_corpsnet = l_filter_to_corpsnet,
                filter_to_dmz = l_filter_to_dmz
          WHERE office_code = l_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            INSERT
              INTO at_data_dissem (office_code,
                                   filter_to_corpsnet,
                                   filter_to_dmz)
            VALUES (l_office_code, l_filter_to_corpsnet, l_filter_to_dmz);
         WHEN OTHERS
         THEN
            RAISE;
      END;
   END;

   FUNCTION cat_ts_transfer_tab (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_ts_transfer_tab_t
      PIPELINED
   IS
      query_cursor   SYS_REFCURSOR;
      output_row     cat_ts_transfer_rec_t;
   BEGIN
      cat_ts_transfer (query_cursor, p_office_id);

      LOOP
         FETCH query_cursor INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;
   EXCEPTION
      WHEN OTHERS
      THEN
         CLOSE query_cursor;

         RAISE;
   END cat_ts_transfer_tab;


   PROCEDURE cat_ts_transfer (
      p_ts_transfer_cat   IN OUT SYS_REFCURSOR,
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      l_office_code          NUMBER;

      l_filter_to_CorpsNet   VARCHAR2 (1);
      l_filter_to_DMZ        VARCHAR2 (1);

      l_loc_group_code       NUMBER := NULL;
      l_ts_group_code        NUMBER := NULL;
   BEGIN
      l_office_code := cwms_util.get_db_office_code (p_office_id);


      BEGIN
         SELECT filter_to_corpsnet, filter_to_dmz
           INTO l_filter_to_corpsnet, l_filter_to_dmz
           FROM at_data_dissem
          WHERE office_code = l_office_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_filter_to_CorpsNet := 'F';
            l_filter_to_DMZ := 'T';
      END;

      IF l_filter_to_CorpsNet = 'F' AND l_filter_to_DMZ = 'T'
      THEN
         -- This is Default Setting. All Data to CorpsNe, only Filtered
         -- data to DMZ
         OPEN p_ts_transfer_cat FOR
            SELECT cwms_ts_id,
                   public_name,
                   db_office_id,
                   ts_code,
                   db_office_code,
                   destination
              FROM at_cwms_ts_id a
                   JOIN at_physical_location b
                      USING (location_code)
                   JOIN (SELECT UNIQUE ts_code, 'corpsnet' DESTINATION
                           FROM at_ts_group_assignment
                          WHERE ts_code IN
                                   ( (SELECT ts_code FROM at_cwms_ts_id)
                                    MINUS
                                    (SELECT ts_code
                                       FROM at_ts_group_assignment
                                      WHERE ts_group_code = 102
                                     MINUS
                                     (SELECT ts_code
                                        FROM at_ts_group_assignment
                                       WHERE ts_group_code = 101
                                      UNION ALL
                                      SELECT ts_code
                                        FROM at_ts_group_assignment
                                       WHERE ts_group_code = 103)))
                         UNION ALL
                         SELECT UNIQUE ts_code, 'dmz' DESTINATION
                           FROM (SELECT ts_code
                                   FROM at_ts_group_assignment
                                  WHERE ts_group_code = 102
                                 MINUS
                                 (SELECT ts_code
                                    FROM at_ts_group_assignment
                                   WHERE ts_group_code = 101
                                  UNION ALL
                                  SELECT ts_code
                                    FROM at_ts_group_assignment
                                   WHERE ts_group_code = 103)))
                      USING (ts_code)
             WHERE db_office_code = l_office_code;
      --
      --
      ELSIF l_filter_to_CorpsNet = 'T' AND l_filter_to_DMZ = 'T'
      THEN
         -- Filtering for both CorpsNet and DMZ
         OPEN p_ts_transfer_cat FOR
            SELECT cwms_ts_id,
                   public_name,
                   db_office_id,
                   ts_code,
                   db_office_code,
                   destination
              FROM at_cwms_ts_id a
                   JOIN at_physical_location b
                      USING (location_code)
                   JOIN (SELECT UNIQUE ts_code, 'corpsnet' DESTINATION
                           FROM at_ts_group_assignment
                          WHERE ts_code IN
                                   ( (SELECT ts_code
                                        FROM at_ts_group_assignment
                                       WHERE     office_code = l_office_code
                                             AND ts_group_code =
                                                    CorpsNet_include_gp_code
                                      MINUS
                                      SELECT ts_code
                                        FROM at_ts_group_assignment
                                       WHERE     office_code = l_office_code
                                             AND ts_group_code =
                                                    CorpsNet_exclude_gp_code)
                                    MINUS
                                    (SELECT ts_code
                                       FROM at_ts_group_assignment
                                      WHERE     office_code = l_office_code
                                            AND ts_group_code =
                                                   DMZ_include_gp_code
                                     MINUS
                                     (SELECT ts_code
                                        FROM at_ts_group_assignment
                                       WHERE     office_code = l_office_code
                                             AND ts_group_code =
                                                    CorpsNet_exclude_gp_code
                                      UNION ALL
                                      SELECT ts_code
                                        FROM at_ts_group_assignment
                                       WHERE     office_code = l_office_code
                                             AND ts_group_code =
                                                    DMZ_exclude_gp_code)))
                         UNION ALL
                         SELECT UNIQUE ts_code, 'dmz' DESTINATION
                           FROM (SELECT ts_code
                                   FROM at_ts_group_assignment
                                  WHERE     office_code = l_office_code
                                        AND ts_group_code =
                                               DMZ_include_gp_code
                                 MINUS
                                 (SELECT ts_code
                                    FROM at_ts_group_assignment
                                   WHERE     office_code = l_office_code
                                         AND ts_group_code =
                                                CorpsNet_exclude_gp_code
                                  UNION ALL
                                  SELECT ts_code
                                    FROM at_ts_group_assignment
                                   WHERE     office_code = l_office_code
                                         AND ts_group_code =
                                                DMZ_exclude_gp_code)))
                      USING (ts_code);
      --
      --
      ELSE
         -- All data to both DMZ and CorpsNet
         OPEN p_ts_transfer_cat FOR
            SELECT cwms_ts_id,
                   public_name,
                   db_office_id,
                   ts_code,
                   db_office_code,
                   'DMZ'
              FROM    at_cwms_ts_id a
                   JOIN
                      at_physical_location b
                   USING (location_code)
             WHERE db_office_code = l_office_code;
      END IF;
   /*

         ---------------------------------------------------
         -- get the loc_group_code if cat/group passed in --
         ---------------------------------------------------
         IF (p_loc_category_id IS NULL) != (p_loc_group_id IS NULL)
         THEN
            cwms_err.raise (
               'ERROR',
               'The loc_category_id and loc_group_id is not a valid combination');
         END IF;

         IF p_loc_group_id IS NOT NULL
         THEN
            l_loc_group_code :=
               cwms_util.get_loc_group_code (p_loc_category_id,
                                             p_loc_group_id,
                                             l_db_office_code);
         END IF;

         ---------------------------------------------------
         -- get the ts_group_code if cat/group passed in --
         ---------------------------------------------------
         IF (p_ts_category_id IS NULL) != (p_ts_group_id IS NULL)
         THEN
            cwms_err.raise (
               'ERROR',
               'The ts_category_id and ts_group_id is not a valid combination');
         END IF;

         IF p_ts_group_id IS NOT NULL
         THEN
            l_ts_group_code :=
               cwms_util.get_ts_group_code (p_ts_category_id,
                                            p_ts_group_id,
                                            l_db_office_code);
         END IF;

         --
         ---- Revised Select 11Mar2011
         --
         IF p_db_office_id IS NULL
         THEN
            l_db_office_code := NULL;     -- i.e., return ts_id's for all offices
         END IF;

         OPEN p_cwms_cat FOR
              SELECT v.db_office_id,
                     v.base_location_id,
                     v.cwms_ts_id,
                     v.interval_utc_offset,
                     z.time_zone_name lrts_timezone,
                     v.ts_active_flag,
                     a.user_privileges
                FROM at_cwms_ts_id v
                     JOIN (SELECT ts_code, net_privilege_bit user_privileges
                             FROM av_sec_ts_privileges
                            WHERE username = cwms_util.get_user_id) a
                        USING (ts_code)
                     JOIN at_cwms_ts_spec s
                        USING (ts_code)
                     LEFT OUTER JOIN cwms_time_zone z
                        USING (time_zone_code)
               WHERE     (   l_loc_group_code IS NULL
                          OR v.location_code IN
                                (SELECT location_code
                                   FROM at_loc_group_assignment
                                  WHERE loc_group_code = l_loc_group_code))
                     AND (   l_ts_group_code IS NULL
                          OR ts_code IN (SELECT ts_code
                                           FROM at_ts_group_assignment
                                          WHERE ts_group_code = l_ts_group_code))
                     AND (   l_db_office_code IS NULL
                          OR v.db_office_code = l_db_office_code)
                     AND UPPER (v.cwms_ts_id) LIKE
                            UPPER (l_ts_subselect_string) ESCAPE '\'
            ORDER BY UPPER (v.cwms_ts_id), UPPER (v.db_office_id) ASC;

         --
         ---- Original Released Select...
         --
         --       OPEN p_cwms_cat FOR
         --             SELECT DISTINCT
         --                      b.db_office_id,
         --                      b.base_location_id,
         --                      b.cwms_ts_id,
         --                      b.interval_utc_offset,
         --                      z.time_zone_name lrts_timezone,
         --                      b.ts_active_flag,
         --                      b.user_privileges
         --              FROM  (   SELECT a.ts_code,
         --                                     v.location_code,
         --                                     v.db_office_id,
         --                                     v.base_location_id,
         --                                     v.cwms_ts_id,
         --                                     v.interval_utc_offset,
         --                                     v.ts_active_flag,
         --                                     a.user_privileges
         --                              FROM at_cwms_ts_id v,
         --                                     (     SELECT ts_code,
         --                                                   net_privilege_bit user_privileges
         --                                             FROM av_sec_ts_privileges
         --                                           WHERE username = cwms_util.get_user_id
         --                                     ) a
         --                             WHERE v.ts_code = a.ts_code
         --                               AND v.db_office_code = l_db_office_code
         --                      ) b,
         --                      (   SELECT location_code
         --                              FROM at_loc_group_assignment
         --                             WHERE loc_group_code = nvl(l_loc_group_code, loc_group_code)
         --                      ) c,
         --                      at_cwms_ts_spec s,
         --                      cwms_time_zone z
         --              WHERE (l_loc_group_code IS NULL OR (b.location_code = c.location_code))
         --                 AND b.ts_code = s.ts_code
         --                 AND s.time_zone_code = z.time_zone_code(+)
         --                 AND UPPER(b.cwms_ts_id) LIKE UPPER(l_ts_subselect_string)
         --          ORDER BY UPPER(b.cwms_ts_id), UPPER(b.db_office_id) ASC;
         --
         */
   END cat_ts_transfer;
END cwms_data_dissem;
/
show errors;
GRANT EXECUTE ON CWMS_DATA_DISSEM TO CWMS_USER
/