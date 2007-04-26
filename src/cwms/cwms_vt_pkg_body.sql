/* Formatted on 2007/04/26 11:08 (Formatter Plus v4.8.8) */
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
   FUNCTION get_screening_code_ts_id_count (p_screening_code IN NUMBER)
      RETURN NUMBER
   IS
      l_count   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM at_screening
       WHERE screening_code = p_screening_code;

      RETURN l_count;
   END;

   FUNCTION get_screening_code (
      p_screening_id   IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_screening_code   NUMBER;
      l_db_office_code   NUMBER;
   BEGIN
            --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- confirm that screening_id does NOT already exist    -
      --
      l_screening_code :=
                        get_screening_code (p_screening_id, l_db_office_code);
      RETURN l_screening_code;
   END;

   FUNCTION get_screening_code (
      p_screening_id     IN   VARCHAR2,
      p_db_office_code   IN   NUMBER DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_screening_code   NUMBER;
   BEGIN
      BEGIN
         SELECT screening_code
           INTO l_screening_code
           FROM at_screening_id asi
          WHERE UPPER (asi.screening_id) = UPPER (p_screening_id)
            AND asi.db_office_code = p_db_office_code;

         --
         RETURN l_screening_code;
      --
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('ITEM_DOES_NOT_EXIST',
                            'Screening id: ',
                            p_screening_id
                           );
      END;
   END;

   FUNCTION create_screening_code (
      p_screening_id        IN   VARCHAR2,
      p_screening_id_desc   IN   VARCHAR2,
      p_parameter_id        IN   VARCHAR2,
      p_parameter_type_id   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_db_office_code        NUMBER;
      l_screening_code        NUMBER;
      l_base_parameter_id     VARCHAR2 (16);
      l_base_parameter_code   NUMBER;
      l_sub_parameter_id      VARCHAR2 (32);
      l_parameter_code        NUMBER;
      l_parameter_type_code   NUMBER        := NULL;
      l_duration_code         NUMBER        := NULL;
      l_id_already_exists     BOOLEAN;
   BEGIN
      --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- Determine the parameter codes...
      --
      l_base_parameter_id := cwms_util.get_base_id (p_parameter_id);
      l_sub_parameter_id := cwms_util.get_sub_id (p_parameter_id);

      --
      -- GET the Base Parameter Code.
      SELECT base_parameter_code, base_parameter_id
        INTO l_base_parameter_code, l_base_parameter_id
        FROM cwms_base_parameter cbp
       WHERE UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

      --
      -- confirm that screening_id does NOT already exist    -
      --
      BEGIN
         l_screening_code :=
                        get_screening_code (p_screening_id, l_db_office_code);
         --
         l_id_already_exists := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_id_already_exists := FALSE;
      END;

      IF l_id_already_exists
      THEN
         cwms_err.RAISE ('ITEM_ALREADY_EXISTS',
                         'Screening id: ',
                         p_screening_id
                        );
      END IF;

      -- Screening Id does not exist - continue...
      l_parameter_code :=
         cwms_ts.get_parameter_code
                              (p_base_parameter_code      => l_base_parameter_code,
                               p_sub_parameter_id         => l_sub_parameter_id,
                               p_office_code              => l_db_office_code,
                               p_create                   => FALSE
                              );

      IF p_parameter_type_id IS NOT NULL
      THEN
         SELECT parameter_type_code
           INTO l_parameter_type_code
           FROM cwms_parameter_type cpt
          WHERE UPPER (cpt.parameter_type_id) = UPPER (p_parameter_type_id);
      END IF;

      IF p_duration_id IS NOT NULL
      THEN
         SELECT duration_code
           INTO l_duration_code
           FROM cwms_duration cd
          WHERE UPPER (cd.duration_id) = UPPER (p_duration_id);
      END IF;

      --
      -- Insert new screening_id into database...
      --
      INSERT INTO at_screening_id
                  (screening_code, db_office_code, screening_id,
                   screening_id_desc, base_parameter_code,
                   parameter_code, parameter_type_code, duration_code
                  )
           VALUES (cwms_seq.NEXTVAL, l_db_office_code, p_screening_id,
                   p_screening_id_desc, l_base_parameter_code,
                   l_parameter_code, l_parameter_type_code, l_duration_code
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
      p_parameter_type_id   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id         IN   VARCHAR2 DEFAULT NULL,
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

   PROCEDURE copy_screening_id (
      p_screening_id_old        IN   VARCHAR2,
      p_screening_id_new        IN   VARCHAR2,
      p_screening_id_desc_new   IN   VARCHAR2,
      p_parameter_id_new        IN   VARCHAR2 DEFAULT NULL,
      p_parameter_type_id_new   IN   VARCHAR2 DEFAULT NULL,
      p_duration_id_new         IN   VARCHAR2 DEFAULT NULL,
      p_param_check             IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id            IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_param_check             BOOLEAN       := TRUE;
      l_new_id_already_exists   BOOLEAN       := FALSE;
      l_db_office_id            VARCHAR2 (16);
      l_parameter_id_old        VARCHAR2 (49);
      l_parameter_id_new        VARCHAR2 (49);
      l_db_office_code          NUMBER;
      l_screening_code_new      NUMBER;
      l_screening_code_old      NUMBER;
      l_parameter_code_new      NUMBER;
      l_parameter_code_old      NUMBER;
   BEGIN
      IF NVL (UPPER (p_param_check), 'T') = 'F'
      THEN
         l_param_check := FALSE;
      END IF;

      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      --
      -- Retrieve old screening id info...
      BEGIN
         l_screening_code_old :=
                      get_screening_code (p_screening_id_old, l_db_office_id);

         SELECT parameter_code
           INTO l_parameter_code_old
           FROM at_screening_id
          WHERE screening_code = l_screening_code_old;

         l_parameter_id_old :=
                             cwms_util.get_parameter_id (l_parameter_code_old);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('GENERIC_ERROR',
                               'Old Screening id: '
                            || p_screening_id_old
                            || ' not found. Cannot copy to '
                            || p_screening_id_new
                           );
      END;

      --
      -- The new screening id should not already exist...
      BEGIN
         l_screening_code_new :=
                      get_screening_code (p_screening_id_new, l_db_office_id);
         l_new_id_already_exists := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            -- expecting an exception - i.e., new screening id should not exist.
            NULL;
      END;

      IF l_new_id_already_exists
      THEN
         cwms_err.RAISE ('GENERIC_ERROR',
                            'New Screening id: '
                         || p_screening_id_new
                         || ' already exists.'
                        );
      END IF;

      IF p_parameter_id_new IS NULL
      THEN
         l_parameter_id_new := l_parameter_id_old;
      END IF;

      IF l_param_check
      THEN
         IF l_parameter_id_new != l_parameter_id_old
         THEN
            cwms_err.RAISE
               ('GENERIC_ERROR',
                'The old and new paramaeter id''s do not match. Set the p_param_check to False to override this check.'
               );
         END IF;
      END IF;

      l_screening_code_new :=
         create_screening_code (p_screening_id_new,
                                p_screening_id_desc_new,
                                l_parameter_id_new,
                                p_parameter_type_id_new,
                                p_duration_id_new,
                                p_db_office_id
                               );
      copy_screening_criteria (p_screening_id_old,
                               p_screening_id_new,
                               p_param_check,
                               p_db_office_id
                              );
   END;

   PROCEDURE rename_screening_id (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code        NUMBER;
      l_screening_code        NUMBER;
      l_base_parameter_id     VARCHAR2 (16);
      l_base_parameter_code   NUMBER;
      l_id_already_exists     BOOLEAN;
   BEGIN
      --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);

      --
      --
      -- Confirm the new screening_id does NOT exist...
      BEGIN
         l_screening_code :=
            get_screening_code (p_screening_id        => p_screening_id_new,
                                p_db_office_code      => l_db_office_code
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
         IF p_screening_id_old = p_screening_id_new
         THEN
            cwms_err.RAISE ('ITEM_ALREADY_EXISTS',
                            'Screening id: ',
                            p_screening_id_new
                           );
         ELSIF UPPER (p_screening_id_old) != UPPER (p_screening_id_new)
         THEN
            cwms_err.RAISE ('ITEM_ALREADY_EXISTS',
                            'Screening id: ',
                            p_screening_id_new
                           );
         END IF;
      END IF;

      --
      -- Confirm the old screening_id exists...
      BEGIN
         l_screening_code :=
                    get_screening_code (p_screening_id_old, l_db_office_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('ITEM_DOES_NOT_EXIST',
                            'Screening id: ',
                            p_screening_id_old
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
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code      NUMBER;
      l_screening_code      NUMBER;
      l_ts_ni_hash          VARCHAR2 (80);
      l_id_already_exists   BOOLEAN;
   BEGIN
      --
      --
      -- Confirm the screening_id exists...
      BEGIN
         l_screening_code :=
                          get_screening_code (p_screening_id, p_db_office_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('ITEM_DOES_NOT_EXIST',
                            'Screening id: ',
                            p_screening_id
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

      -- confirm that ts_screening_id exists    -
      --
      BEGIN
         l_screening_code :=
                          get_screening_code (p_screening_id, p_db_office_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('ITEM_DOES_NOT_EXIST',
                            'Screening id: ',
                            p_screening_id
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
   PROCEDURE copy_screening_criteria (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_param_check        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_param_check          BOOLEAN       := TRUE;
      l_db_office_id         VARCHAR2 (16);
      l_db_office_code       NUMBER;
      l_screening_code_new   NUMBER;
      l_screening_code_old   NUMBER;
      l_parameter_code_new   NUMBER;
      l_parameter_code_old   NUMBER;
   BEGIN
      IF NVL (UPPER (p_param_check), 'T') = 'F'
      THEN
         l_param_check := FALSE;
      END IF;

      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      --
      -- Retrieve old screening id info...
      BEGIN
         l_screening_code_old :=
                      get_screening_code (p_screening_id_old, l_db_office_id);

         SELECT parameter_code
           INTO l_parameter_code_old
           FROM at_screening_id
          WHERE screening_code = l_screening_code_old;
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('GENERIC_ERROR',
                               'Old Screening id: '
                            || p_screening_id_old
                            || ' not found. Cannot copy to '
                            || p_screening_id_new
                           );
      END;

      --
      -- Retrieve new screening id info...
      BEGIN
         l_screening_code_new :=
                      get_screening_code (p_screening_id_new, l_db_office_id);

         SELECT parameter_code
           INTO l_parameter_code_new
           FROM at_screening_id
          WHERE screening_code = l_screening_code_new;
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE
                     ('GENERIC_ERROR',
                         'New Screening id: '
                      || p_screening_id_new
                      || ' not found. Cannot copy to non-existant screening id.'
                     );
      END;

      --
      -- check old/new parameter id if p_param_check is true...
      IF l_param_check
      THEN
         IF l_parameter_code_old != l_parameter_code_new
         THEN
            cwms_err.RAISE
               ('GENERIC_ERROR',
                'The old and new paramaeter id''s do not match. Set the p_param_check to False to override this check.'
               );
         END IF;
      END IF;

      -- new and old check out, perform the copy...

      -- Delete any screening entries in the new screening id...
      DELETE FROM at_screening_dur_mag
            WHERE screening_code = l_screening_code_new;

      --
      DELETE FROM at_screening_criteria
            WHERE screening_code = l_screening_code_new;

      -- Copy old screening criteria entries into the new screening criteria...
      INSERT INTO at_screening_criteria
         SELECT l_screening_code_new, season_start_date, range_reject_lo,
                range_reject_hi, range_question_lo, range_question_hi,
                rate_change_reject_rise, rate_change_reject_fall,
                rate_change_quest_rise, rate_change_quest_fall,
                rate_change_disp_interval_code, const_reject_duration_code,
                const_reject_min, const_reject_max, const_reject_n_miss,
                const_quest_duration_code, const_quest_min, const_quest_max,
                const_quest_n_miss, estimate_expression
           FROM at_screening_criteria
          WHERE screening_code = l_screening_code_old;

      INSERT INTO at_screening_dur_mag
         SELECT l_screening_code_new, season_start_date, duration_code,
                reject_lo, reject_hi, question_lo, question_hi
           FROM at_screening_dur_mag
          WHERE screening_code = l_screening_code_old;
   END;

   PROCEDURE store_screening_criteria (
      p_screening_id              IN   VARCHAR2,
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
      l_db_office_id                VARCHAR2 (16);
      l_db_office_code              NUMBER;
      l_screening_code              NUMBER;
      l_rate_change_interval_code   NUMBER;
      l_to_unit_code                NUMBER;
      l_abstract_param_code         NUMBER;
      l_factor                      NUMBER;
      l_offset                      NUMBER;

      CURSOR l_sc_cur
      IS
         SELECT *
           FROM TABLE (CAST (p_screen_crit_array AS screen_crit_array));

      l_sc_rec                      l_sc_cur%ROWTYPE;
   BEGIN
      IF l_count = 0
      THEN
         cwms_err.RAISE
                       ('GENERIC_ERROR',
                        'No screening criteria found in p_screen_crit_array.'
                       );
      END IF;

      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      BEGIN
         l_screening_code :=
                          get_screening_code (p_screening_id, l_db_office_id);
      EXCEPTION
         WHEN OTHERS
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
      --
      ELSIF l_store_rule != cwms_util.replace_all
      THEN
         cwms_err.RAISE ('INVALID_STORE_RULE',
                         p_store_rule || ' is not yet supported. '
                        );
      END IF;

      SELECT interval_code
        INTO l_rate_change_interval_code
        FROM cwms_interval
       WHERE UPPER (interval_id) = UPPER (p_rate_change_interval_id);

      SELECT cbp.unit_code, cbp.abstract_param_code
        INTO l_to_unit_code, l_abstract_param_code
        FROM cwms_base_parameter cbp, at_parameter ap
       WHERE parameter_code = (SELECT parameter_code
                                 FROM at_screening_id
                                WHERE screening_code = l_screening_code)
         AND cbp.base_parameter_code = ap.base_parameter_code;

      SELECT factor, offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion
       WHERE from_unit_id = p_unit_id AND to_unit_code = l_to_unit_code;

      --
      OPEN l_sc_cur;

      LOOP
         FETCH l_sc_cur
          INTO l_sc_rec;

         EXIT WHEN l_sc_cur%NOTFOUND;

         INSERT INTO at_screening_criteria
                     (screening_code,
                      season_start_date,
                      range_reject_lo,
                      range_reject_hi,
                      range_question_lo,
                      range_question_hi,
                      rate_change_reject_rise,
                      rate_change_reject_fall,
                      rate_change_quest_rise,
                      rate_change_quest_fall,
                      rate_change_disp_interval_code,
                      const_reject_duration_code,
                      const_reject_min,
                      const_reject_max,
                      const_reject_n_miss,
                      const_quest_duration_code,
                      const_quest_min,
                      const_quest_max,
                      const_quest_n_miss,
                      estimate_expression
                     )
              VALUES (l_screening_code,
                        l_sc_rec.season_start_day
                      + (l_sc_rec.season_start_month - 1) * 30,
                      l_sc_rec.range_reject_lo * l_factor + l_offset,
                      l_sc_rec.range_reject_hi * l_factor + l_offset,
                      l_sc_rec.range_question_lo * l_factor + l_offset,
                      l_sc_rec.range_question_hi * l_factor + l_offset,
                      l_sc_rec.rate_change_reject_rise * l_factor + l_offset,
                      l_sc_rec.rate_change_reject_fall * l_factor + l_offset,
                      l_sc_rec.rate_change_quest_rise * l_factor + l_offset,
                      l_sc_rec.rate_change_quest_fall * l_factor + l_offset,
                      l_rate_change_interval_code,
                      CASE
                         WHEN l_sc_rec.const_reject_duration_id IS NOT NULL
                            THEN (SELECT duration_code
                                    FROM cwms_duration
                                   WHERE UPPER (duration_id) =
                                            UPPER
                                               (l_sc_rec.const_reject_duration_id
                                               ))
                         ELSE NULL
                      END,
                      l_sc_rec.const_reject_min * l_factor + l_offset,
                      l_sc_rec.const_reject_max * l_factor + l_offset,
                      l_sc_rec.const_reject_n_miss,
                      CASE
                         WHEN l_sc_rec.const_quest_duration_id IS NOT NULL
                            THEN (SELECT duration_code
                                    FROM cwms_duration
                                   WHERE UPPER (duration_id) =
                                            UPPER
                                               (l_sc_rec.const_quest_duration_id
                                               ))
                         ELSE NULL
                      END,
                      l_sc_rec.const_quest_min * l_factor + l_offset,
                      l_sc_rec.const_quest_max * l_factor + l_offset,
                      l_sc_rec.const_quest_n_miss,
                      l_sc_rec.estimate_expression
                     );

         l_count := l_sc_rec.dur_mag_array.COUNT;
         DBMS_OUTPUT.put_line ('number of dur mag elements: ' || l_count);

         IF l_count > 0
         THEN
            FOR i IN 1 .. l_count
            LOOP
               DBMS_OUTPUT.put_line (   i
                                     || ' '
                                     || l_sc_rec.dur_mag_array (i).duration_id
                                    );

               INSERT INTO at_screening_dur_mag
                           (screening_code,
                            season_start_date,
                            duration_code,
                            reject_lo,
                            reject_hi,
                            question_lo,
                            question_hi
                           )
                    VALUES (l_screening_code,
                              l_sc_rec.season_start_day
                            + (l_sc_rec.season_start_month - 1) * 30,
                            (SELECT duration_code
                               FROM cwms_duration
                              WHERE UPPER (duration_id) =
                                       UPPER
                                          (l_sc_rec.dur_mag_array (i).duration_id
                                          )),
                              l_sc_rec.dur_mag_array (i).reject_lo * l_factor
                            + l_offset,
                              l_sc_rec.dur_mag_array (i).reject_hi * l_factor
                            + l_offset,
                              l_sc_rec.dur_mag_array (i).question_lo
                              * l_factor
                            + l_offset,
                              l_sc_rec.dur_mag_array (i).question_hi
                              * l_factor
                            + l_offset
                           );
            END LOOP;
         END IF;
      --
      END LOOP;

      CLOSE l_sc_cur;
   END store_screening_criteria;

--------------------------------------------------------------------------------
--
-- get_process_shefit_files is normally called by processSHEFIT. The call lets 
--         processSHEFIT know if it should use the criteria file and/or OTF 
--         file passed back in place of any files found (and/or specified) on 
--         the file system. If the call throws and exception (e.g., the 
--         specified DataStream has not been defined in the database would 
--         cause this procedure to throw an exception) then processSHEFIT will
--         default to cirt and OTF files found on the file system.
--
-- Parameters:
-- p_use_db_crit - OUT - returns a varchar2(1). The returned parameter will be
--        "T" if processSHEFIT should use the DB's crit file. "F" indicates that
--        processSHEFIT should use the crit file found on the file system.
-- p_crit_file - OUT - returns a CLOB. This is the processSHEFIT criteria file
--        provide by the database.
-- p_use_db_otf - OUT - returns a varchar2(1). The returned parameter will be 
--       "T" if processSHEFIT should use the DB's otf file. "F" indicates that
--       processSHEFIT should use the otf file found on the file system.
-- p_otf_file - OUT - returns a CLOB. This is the processSHEFIT otf file
--       provide by the database.
-- p_data_stream - IN - varchar2(16) - required parameter. This is the name of
--       the datastream.
-- p_db_office_id - in - varchar2(16) - optional parameter) is the database 
--       office id that this data stream will be/is assigned too. Normally this
--       is left null and the user's default database office id is used.
--
   PROCEDURE get_process_shefit_files (
      p_use_db_crit    OUT      VARCHAR2,
      p_crit_file      OUT      CLOB,
      p_use_db_otf     OUT      VARCHAR2,
      p_otf_file       OUT      CLOB,
      p_data_stream    IN       VARCHAR2,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      NULL;
   END;

   PROCEDURE assign_screening_id (
      p_screening_id       IN   VARCHAR2,
      p_scr_assign_array   IN   screen_assign_array,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id            VARCHAR2 (16);
      l_db_office_code          NUMBER;
      l_num                     NUMBER        := p_scr_assign_array.COUNT;
      l_screening_code          NUMBER;
      l_base_parameter_code     NUMBER        := NULL;
      l_base_parameter_code_a   NUMBER        := NULL;
      l_parameter_code          NUMBER        := NULL;
      l_parameter_code_a        NUMBER        := NULL;
      l_parameter_type_code     NUMBER        := NULL;
      l_parameter_type_code_a   NUMBER        := NULL;
      l_duration_code           NUMBER        := NULL;
      l_duration_code_a         NUMBER        := NULL;
      l_sub_parameter_id        VARCHAR2 (32) := NULL;
      l_ts_code                 NUMBER;
      --
      l_params_match            BOOLEAN;
      l_param_types_match       BOOLEAN;
      l_duration_match          BOOLEAN;
   BEGIN
      DBMS_OUTPUT.put_line ('starting assign');

      IF l_num < 1
      THEN
         cwms_err.RAISE
                  ('GENERIC_ERROR',
                   'No screening id assignments found in p_scr_assign_array.'
                  );
      END IF;

      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);
      l_screening_code :=
                         get_screening_code (p_screening_id, l_db_office_code);

      -- retrieve data for scrrening id...
      SELECT base_parameter_code, parameter_code, parameter_type_code,
             duration_code
        INTO l_base_parameter_code, l_parameter_code, l_parameter_type_code,
             l_duration_code
        FROM at_screening_id
       WHERE screening_code = l_screening_code;

      SELECT sub_parameter_id
        INTO l_sub_parameter_id
        FROM at_parameter
       WHERE parameter_code = l_parameter_code;

      FOR i IN 1 .. l_num
      LOOP
         DBMS_OUTPUT.put_line (p_scr_assign_array (i).cwms_ts_id);

         SELECT mvcti.ts_code, atp.base_parameter_code,
                atcts.parameter_code, atcts.parameter_type_code,
                atcts.duration_code
           INTO l_ts_code, l_base_parameter_code_a,
                l_parameter_code_a, l_parameter_type_code_a,
                l_duration_code_a
           FROM mv_cwms_ts_id mvcti, at_cwms_ts_spec atcts, at_parameter atp
          WHERE mvcti.ts_code = atcts.ts_code
            AND atcts.parameter_code = atp.parameter_code
            AND UPPER (mvcti.cwms_ts_id) =
                                     UPPER (p_scr_assign_array (i).cwms_ts_id);

         l_params_match := FALSE;
         l_param_types_match := FALSE;
         l_duration_match := FALSE;

         IF l_sub_parameter_id IS NULL
         THEN
            IF l_base_parameter_code = l_base_parameter_code_a
            THEN
               l_params_match := TRUE;
            END IF;
         ELSE
            IF l_parameter_code = l_parameter_code_a
            THEN
               l_params_match := TRUE;
            END IF;
         END IF;

         IF    l_parameter_type_code IS NULL
            OR l_parameter_type_code = l_parameter_type_code_a
         THEN
            l_param_types_match := TRUE;
         END IF;

         IF l_duration_code IS NULL OR l_duration_code = l_duration_code_a
         THEN
            l_duration_match := TRUE;
         END IF;

         IF l_params_match AND l_param_types_match AND l_duration_match
         THEN
            NULL;
         ELSE
            cwms_err.RAISE ('GENERIC_ERROR',
                               'The cwms_ts_id: '
                            || p_scr_assign_array (i).cwms_ts_id
                            || ' cannot be assigned to the '
                            || p_screening_id
                            || ' screening id.'
                           );
         END IF;
      END LOOP;

      MERGE INTO at_screening ats
         USING (SELECT (SELECT mvcti.ts_code
                          FROM mv_cwms_ts_id mvcti
                         WHERE UPPER (cwms_ts_id) =
                                                 UPPER (a.cwms_ts_id))
                                                                      ts_code,
                       CASE
                          WHEN UPPER (a.active_flag) = 'T'
                             THEN 'T'
                          ELSE 'F'
                       END active_flag,
                       (SELECT mvcti.ts_code
                          FROM mv_cwms_ts_id mvcti
                         WHERE UPPER (cwms_ts_id) =
                                  UPPER (a.resultant_ts_id))
                                                            resultant_ts_code
                  FROM TABLE (p_scr_assign_array) a) b
         ON (ats.ts_code = b.ts_code)
         WHEN MATCHED THEN
            UPDATE
               SET ats.screening_code = l_screening_code,
                   ats.active_flag = b.active_flag,
                   ats.resultant_ts_code = b.resultant_ts_code
         WHEN NOT MATCHED THEN
            INSERT (ts_code, screening_code, active_flag, resultant_ts_code)
            VALUES (b.ts_code, l_screening_code, b.active_flag,
                    b.resultant_ts_code);
   END assign_screening_id;

   PROCEDURE unassign_screening_id (
      p_screening_id       IN   VARCHAR2,
      p_cwms_ts_id_array   IN   cwms_ts_id_array,
      p_unassign_all       IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_unassign_all     BOOLEAN       := FALSE;
      l_db_office_id     VARCHAR2 (16);
      l_db_office_code   NUMBER;
      l_num              NUMBER        := p_cwms_ts_id_array.COUNT;
      l_screening_code   NUMBER;
   BEGIN
      IF UPPER (NVL (p_unassign_all, 'F')) = 'T'
      THEN
         l_unassign_all := TRUE;
      END IF;

      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);
      l_screening_code :=
                         get_screening_code (p_screening_id, l_db_office_code);

      IF l_unassign_all
      THEN
         DELETE FROM at_screening
               WHERE screening_code = l_screening_code;
      ELSIF l_num < 1
      THEN
         cwms_err.RAISE ('GENERIC_ERROR',
                         'No cwms_ts_id''s passed-in to unassin.'
                        );
      ELSE
         DELETE FROM at_screening
               WHERE screening_code = l_screening_code
                 AND ts_code IN (
                         SELECT mvcti.ts_code
                           FROM mv_cwms_ts_id mvcti,
                                TABLE (p_cwms_ts_id_array) a
                          WHERE UPPER (mvcti.cwms_ts_id) =
                                                          UPPER (a.cwms_ts_id));
      END IF;
   END unassign_screening_id;
END cwms_vt;
/