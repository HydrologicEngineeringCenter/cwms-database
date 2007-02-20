/* Formatted on 2006/12/18 14:04 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_vt
AS
/******************************************************************************
   NAME:       CWMS_VAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/11/2006             1. Created this package body.
******************************************************************************/
   FUNCTION get_screening_code (
      p_screening_id     IN   VARCHAR2,
      p_ts_ni_hash       IN   VARCHAR2,
      p_db_office_code   IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_screening_code   NUMBER;
   BEGIN
      BEGIN
         SELECT screening_code
           INTO l_screening_code
           FROM at_screening_id
          WHERE UPPER (screening_id) = UPPER (p_screening_id)
            AND ts_ni_hash = p_ts_ni_hash
            AND db_office_code = p_db_office_code;

         --
         RETURN l_screening_code;
      --
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('GENERIC_ERROR',
                               'Screening code for: '
                            || p_screening_id
                            || ' not found'
                           );
      END;
   END;

   FUNCTION create_screening_code (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_ts_ni_hash          VARCHAR2 (80);
      l_db_office_code      NUMBER;
      l_screening_code      NUMBER;
      l_id_already_exists   BOOLEAN;
   BEGIN
      --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- Determine the ts_ni_hash...
      --
      l_ts_ni_hash :=
         cwms_ts.create_ts_ni_hash (p_parameter_id,
                                    p_parameter_type_id,
                                    p_duration_id,
                                    p_db_office_id
                                   );

      --
      -- confirm that ts_screening_id does NOT already exist    -
      --
      BEGIN
         l_screening_code :=
            get_screening_code (p_screening_id,
                                l_ts_ni_hash,
                                l_db_office_code
                               );
         --
         l_id_already_exists := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_id_already_exists := FALSE;
      END;

      IF l_id_already_exists
      THEN
         cwms_err.RAISE ('GENERIC',
                            'Screening id: '
                         || p_screening_id
                         || ' already exists, cannot create.'
                        );
      END IF;

      --
      -- Insert new screening_id into database...
      --
      INSERT INTO at_screening_id
                  (screening_code, ts_ni_hash, db_office_code,
                   screening_id, screening_id_desc
                  )
           VALUES (cwms_seq.NEXTVAL, l_ts_ni_hash, l_db_office_code,
                   p_screening_id, p_screening_id_desc
                  )
        RETURNING screening_code
             INTO l_screening_code;

      COMMIT;
      --
      RETURN l_screening_code;
   --
   END create_screening_code;

   PROCEDURE create_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_screening_code   NUMBER;
   BEGIN
      l_screening_code :=
         create_screening_code (p_screening_id,
                                p_screening_id_desc,
                                p_parameter_id,
                                p_parameter_type_id,
                                p_duration_id,
                                p_db_office_id
                               );
   END create_screening_id;

   PROCEDURE rename_screening_id (
      p_screening_id_old    IN   VARCHAR2,
      p_screening_id_new    IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code      NUMBER;
      l_screening_code      NUMBER;
      l_ts_ni_hash          VARCHAR2 (80);
      l_id_already_exists   BOOLEAN;
   BEGIN
      --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- Determine the ts_ni_hash...
      --
      l_ts_ni_hash :=
         cwms_ts.create_ts_ni_hash (p_parameter_id,
                                    p_parameter_type_id,
                                    p_duration_id
                                   );

      --
      -- Confirm the new screening_id does NOT exist...
      BEGIN
         l_screening_code :=
            get_screening_code (p_screening_id_new,
                                l_ts_ni_hash,
                                l_db_office_code
                               );
         --
         l_id_already_exists := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_id_already_exists := FALSE;
      END;

      IF l_id_already_exists
      THEN
         -- the rename may simply be changing the case of the
         -- screening id, so only throw an exception if
         -- the nEw and OlD id's are not identical...
         IF UPPER (p_screening_id_old) != UPPER (p_screening_id_new)
         THEN
            cwms_err.RAISE ('GENERIC',
                               'Screening id: '
                            || p_screening_id_new
                            || ' already exists, cannot rename '
                            || p_screening_id_old
                            || ' to an existing screening id..'
                           );
         END IF;
      END IF;

      --
      -- Confirm the old screening_id exists...
      BEGIN
         l_screening_code :=
            get_screening_code (p_screening_id_old,
                                l_ts_ni_hash,
                                l_db_office_code
                               );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('',
                               'Screeing id: '
                            || p_screening_id_old
                            || ' does not exist, cannot rename.'
                           );
      END;

      --
      -- Rename the screening id...
      UPDATE at_screening_id
         SET screening_id = p_screening_id_new
       WHERE screening_code = l_screening_code;

      --
      COMMIT;
   END;

   PROCEDURE update_screening_id_desc (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code      NUMBER;
      l_screening_code      NUMBER;
      l_ts_ni_hash          VARCHAR2 (80);
      l_id_already_exists   BOOLEAN;
   BEGIN
      --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- Determine the ts_ni_hash...
      --
      l_ts_ni_hash :=
         cwms_ts.create_ts_ni_hash (p_parameter_id,
                                    p_parameter_type_id,
                                    p_duration_id
                                   );

      --
      -- Confirm the screening_id exists...
      BEGIN
         l_screening_code :=
            get_screening_code (p_screening_id,
                                l_ts_ni_hash,
                                l_db_office_code
                               );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('',
                               'Screeing id: '
                            || p_screening_id
                            || ' does not exist, cannot update description.'
                           );
      END;

      --
      -- Rename the screening id...
      UPDATE at_screening_id
         SET screening_id_desc = p_screening_id_desc
       WHERE screening_code = l_screening_code;

      COMMIT;
   END update_screening_id_desc;

--
--*******************************************************************   --
--*******************************************************************   --
--
-- delete_screening_id
--
---------------------------------------------------------------------   --
--
-- By default, delete_screening_id will throw an exception if there are
-- any ts_codes assigned to the screening_id to be deleted. One can
-- override this by setting p_cascade to "T".
   PROCEDURE delete_screening_id (
      p_screening_id        IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2,
      p_duration_id         IN   VARCHAR2,
      p_cascade             IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_ts_ni_hash       VARCHAR2 (80);
      l_db_office_code   NUMBER;
      l_screening_code   NUMBER;
      l_count            NUMBER;
      l_cascade          BOOLEAN
                     := cwms_util.return_true_or_false (NVL (p_cascade, 'F'));
   BEGIN
      --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- Determine the ts_ni_hash...
      --
      l_ts_ni_hash :=
         cwms_ts.create_ts_ni_hash (p_parameter_id,
                                    p_parameter_type_id,
                                    p_duration_id
                                   );

      --
      -- confirm that ts_screening_id exists    -
      --
      BEGIN
         l_screening_code :=
            get_screening_code (p_screening_id,
                                l_ts_ni_hash,
                                l_db_office_code
                               );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('GENERIC ERROR',
                               'Screening id: '
                            || p_screening_id
                            || ' does not exist, cannot delete.'
                           );
      END;

      IF l_cascade
      THEN
         DELETE FROM at_screening
               WHERE screening_code = l_screening_code;
      ELSE
         SELECT COUNT (*)
           INTO l_count
           FROM at_screening
          WHERE screening_code = l_screening_code;

         IF l_count > 0
         THEN
            cwms_err.RAISE ('GENERIC ERROR',
                               'Cannot delete the Screening id: '
                            || p_screening_id
                            || ' because '
                            || l_count
                            || ' cwms_ts_id(s) is(are) assigned to it. '
                           );
         END IF;
      END IF;

      DELETE FROM at_screening_dur_mag
            WHERE screening_code = l_screening_code;

      DELETE FROM at_screening_criteria
            WHERE screening_code = l_screening_code;

      DELETE FROM at_screening_id
            WHERE screening_code = l_screening_code;

      COMMIT;
   --
   END delete_screening_id;

   --
--********************************************************************** -
--********************************************************************** -
--
-- STORE_ALIASES                                                         -
--
-- p_store_rule - Valid store rules are:                                 -
--                Delete Insert - This will delete all existing aliases  -
--                                and insert the new set of aliases      -
--                                in your p_alias_array. This is the     -
--                                Default.                               -
--                Replace All   - This will update any pre-existing      -
--                                aliases and insert new ones            -
--
-- p_ignorenulls - is only valid when the "Replace All" store rull is    -
--                 envoked.
--                 if 'T' then do not update a pre-existing value        -
--                   with a newly passed-in null value.                  -
--                 if 'F' then update a pre-existing value               -
--                   with a newly passed-in null value.                  -
--*--------------------------------------------------------------------- -
--
   PROCEDURE store_screening_criteria (
      p_screening_id              IN   VARCHAR2,
      p_parameter_id              IN   VARCHAR2,
      p_parameter_type_id         IN   VARCHAR2,
      p_duration_id               IN   VARCHAR2,
      p_rate_change_interval_id   IN   VARCHAR2,
      p_unit_id                   IN   VARCHAR2,
      p_screen_crit_array         IN   screen_crit_array,
      p_store_rule                IN   VARCHAR2 DEFAULT 'DELETE INSERT',
      p_ignore_nulls              IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id              IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_store_rule                  VARCHAR2 (16)
                       := UPPER (NVL (p_store_rule, cwms_util.delete_insert));
      l_count                       NUMBER       := p_screen_crit_array.COUNT;
      l_office_id                   VARCHAR2 (16);
      l_office_code                 NUMBER;
      l_screening_code              NUMBER;
      l_ts_ni_hash                  VARCHAR2 (80);
      l_rate_change_interval_code   NUMBER;
      l_to_unit_code                NUMBER;
      l_abstract_param_code         NUMBER;
   BEGIN
      DBMS_OUTPUT.put_line ('hi gk: ' || p_db_office_id);

      IF l_count = 0
      THEN
         cwms_err.RAISE
                       ('GENERIC_ERROR',
                        'No screening criteria found in p_screen_crit_array.'
                       );
      END IF;

      IF p_db_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_db_office_id);
      END IF;

      l_office_code := cwms_util.get_office_code (l_office_id);
      l_ts_ni_hash :=
         cwms_ts.create_ts_ni_hash (p_parameter_id,
                                    p_parameter_type_id,
                                    p_duration_id,
                                    l_office_id
                                   );

      BEGIN
         SELECT screening_code
           INTO l_screening_code
           FROM at_screening_id
          WHERE db_office_code = l_office_code
            AND ts_ni_hash = l_ts_ni_hash
            AND UPPER (screening_id) = UPPER (p_screening_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('GENERIC_ERROR',
                               'Screening id: '
                            || p_screening_id
                            || ' not found. Cannot store screening criteria.'
                           );
      END;

      IF l_store_rule = cwms_util.delete_insert
      THEN
         --
         DELETE FROM at_screening_dur_mag
               WHERE screening_code = l_screening_code;

         --
         DELETE FROM at_screening_criteria
               WHERE screening_code = l_screening_code;

         COMMIT;
      --
      ELSIF l_store_rule != cwms_util.replace_all
      THEN
         cwms_err.RAISE ('INVALID_STORE_RULE', p_store_rule);
      END IF;

      SELECT interval_code
        INTO l_rate_change_interval_code
        FROM cwms_interval
       WHERE UPPER (interval_id) = UPPER (p_rate_change_interval_id);

      SELECT cbp.unit_code, cbp.abstract_param_code
        INTO l_to_unit_code, l_abstract_param_code
        FROM cwms_base_parameter cbp, at_parameter ap
       WHERE parameter_code =
                cwms_ts.get_parameter_code
                                       (cwms_util.get_base_id (p_parameter_id),
                                        cwms_util.get_sub_id (p_parameter_id),
                                        l_office_id,
                                        'F'
                                       )
         AND cbp.base_parameter_code = ap.base_parameter_code;

      --
      MERGE INTO at_screening_criteria a
         USING (SELECT season_start_day, season_start_month,
                       range_reject_lo * cuc.factor + offset range_reject_lo,
                       range_reject_hi * cuc.factor + offset range_reject_hi,
                         range_question_lo * cuc.factor
                       + offset range_question_lo,
                         range_question_hi * cuc.factor
                       + offset range_question_hi,
                           rate_change_reject_rise
                         * cuc.factor
                       + offset rate_change_reject_rise,
                           rate_change_reject_fall
                         * cuc.factor
                       + offset rate_change_reject_fall,
                           rate_change_quest_rise
                         * cuc.factor
                       + offset rate_change_quest_rise,
                           rate_change_quest_fall
                         * cuc.factor
                       + offset rate_change_quest_fall,
                       (SELECT duration_code
                          FROM cwms_duration
                         WHERE UPPER (duration_id) =
                                  UPPER
                                     (const_reject_duration_id
                                     )) const_reject_duration_code,
                       const_reject_min * cuc.factor
                       + offset const_reject_min,
                       const_reject_max * cuc.factor
                       + offset const_reject_max,
                       const_reject_n_miss,
                       (SELECT duration_code
                          FROM cwms_duration
                         WHERE UPPER (duration_id) =
                                  UPPER
                                     (const_quest_duration_id
                                     )) const_quest_duration_code,
                       const_quest_min * cuc.factor + offset const_quest_min,
                       const_quest_max * cuc.factor + offset const_quest_max,
                       const_quest_n_miss, estimate_expression,
                       duration_mag_test_flag
                  FROM TABLE (CAST (p_screen_crit_array AS screen_crit_array)),
                       cwms_unit_conversion cuc
                 WHERE cuc.to_unit_code = l_to_unit_code
                   AND cuc.from_unit_id = p_unit_id
                   AND cuc.abstract_param_code = l_abstract_param_code) t
         ON (    a.screening_code = l_screening_code
             AND a.season_start_date =
                           t.season_start_day
                           + (t.season_start_month - 1) * 30)
         WHEN MATCHED THEN
            UPDATE
               SET a.range_reject_lo = t.range_reject_lo,
                   a.range_reject_hi = t.range_reject_hi,
                   a.range_question_lo = t.range_question_lo,
                   a.range_question_hi = t.range_question_hi,
                   a.rate_change_reject_rise = t.rate_change_reject_rise,
                   a.rate_change_reject_fall = t.rate_change_reject_fall,
                   a.rate_change_quest_rise = t.rate_change_quest_rise,
                   a.rate_change_quest_fall = t.rate_change_quest_fall,
                   a.rate_change_disp_interval_code =
                                                   l_rate_change_interval_code,
                   a.const_reject_duration_code = t.const_reject_duration_code,
                   a.const_reject_min = t.const_reject_min,
                   a.const_reject_max = t.const_reject_max,
                   a.const_reject_n_miss = t.const_reject_n_miss,
                   a.const_quest_duration_code = t.const_quest_duration_code,
                   a.const_quest_min = t.const_quest_min,
                   a.const_quest_max = t.const_quest_max,
                   a.const_quest_n_miss = t.const_quest_n_miss,
                   a.estimate_expression = t.estimate_expression,
                   a.dur_mag_test_flag = t.duration_mag_test_flag
         WHEN NOT MATCHED THEN
            INSERT (a.screening_code, a.season_start_date, a.range_reject_lo,
                    a.range_reject_hi, a.range_question_lo,
                    a.range_question_hi, a.rate_change_reject_rise,
                    a.rate_change_reject_fall, a.rate_change_quest_rise,
                    a.rate_change_quest_fall,
                    a.rate_change_disp_interval_code,
                    a.const_reject_duration_code, a.const_reject_min,
                    a.const_reject_max, a.const_reject_n_miss,
                    a.const_quest_duration_code, a.const_quest_min,
                    a.const_quest_max, a.const_quest_n_miss,
                    a.estimate_expression, a.dur_mag_test_flag)
            VALUES (l_screening_code,
                    t.season_start_day + (t.season_start_month - 1) * 30,
                    t.range_reject_lo, t.range_reject_hi, t.range_question_lo,
                    t.range_question_hi, t.rate_change_reject_rise,
                    t.rate_change_reject_fall, t.rate_change_quest_rise,
                    t.rate_change_quest_fall, l_rate_change_interval_code,
                    t.const_reject_duration_code, t.const_reject_min,
                    t.const_reject_max, t.const_reject_n_miss,
                    t.const_quest_duration_code, t.const_quest_min,
                    t.const_quest_max, t.const_quest_n_miss,
                    t.estimate_expression, t.duration_mag_test_flag);
   --
   END store_screening_criteria;
END cwms_vt;
/