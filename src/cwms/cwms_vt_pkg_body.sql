/* Formatted on 2007/03/20 09:05 (Formatter Plus v4.8.8) */
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
      p_parameter_id   IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_screening_code        NUMBER;
      l_db_office_code        NUMBER;
      l_base_parameter_id     VARCHAR2 (16);
      l_base_parameter_code   NUMBER;
   BEGIN
            --
      -- Retrieve the db_office_code...
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);
      --
      -- Determine the parameter codes...
      --
      l_base_parameter_id := cwms_util.get_base_id (p_parameter_id);

      --
      -- GET the Base Parameter Code.
      SELECT base_parameter_code
        INTO l_base_parameter_code
        FROM cwms_base_parameter cbp
       WHERE UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

      --
      -- confirm that screening_id does NOT already exist    -
      --
      l_screening_code :=
         get_screening_code (p_screening_id,
                             l_base_parameter_code,
                             l_db_office_code
                            );
      RETURN l_screening_code;
   END;

   FUNCTION get_screening_code (
      p_screening_id          IN   VARCHAR2,
      p_base_parameter_code   IN   NUMBER,
      p_db_office_code        IN   NUMBER DEFAULT NULL
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
            AND asi.base_parameter_code = p_base_parameter_code
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
            get_screening_code (p_screening_id,
                                l_base_parameter_code,
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

   PROCEDURE rename_screening_id (
      p_screening_id_old   IN   VARCHAR2,
      p_screening_id_new   IN   VARCHAR2,
      p_parameter_id       IN   VARCHAR2,
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
      l_base_parameter_id := cwms_util.get_base_id (p_parameter_id);

      --
      -- Retrieve base_parameter_code.
      SELECT cbp.base_parameter_code, cbp.base_parameter_id
        INTO l_base_parameter_code, l_base_parameter_id
        FROM cwms_base_parameter cbp
       WHERE UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

      --
      --
      -- Confirm the new screening_id does NOT exist...
      BEGIN
         l_screening_code :=
            get_screening_code
                             (p_screening_id             => p_screening_id_new,
                              p_base_parameter_code      => l_base_parameter_code,
                              p_db_office_code           => l_db_office_code
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
            get_screening_code (p_screening_id_old,
                                l_base_parameter_code,
                                l_db_office_code
                               );
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
      p_parameter_id        IN   VARCHAR2,
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
            get_screening_code (p_screening_id,
                                p_parameter_id,
                                p_db_office_id
                               );
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
            get_screening_code (p_screening_id,
                                p_parameter_id,
                                p_db_office_id
                               );
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
   PROCEDURE store_screening_criteria (
      p_screening_id              IN   VARCHAR2,
      p_parameter_id              IN   VARCHAR2,
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
            get_screening_code (p_screening_id,
                                p_parameter_id,
                                l_db_office_id
                               );
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
       WHERE parameter_code =
                cwms_ts.get_parameter_code
                                       (cwms_util.get_base_id (p_parameter_id),
                                        cwms_util.get_sub_id (p_parameter_id),
                                        l_db_office_id,
                                        'F'
                                       )
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
                      CASE
                         WHEN l_sc_rec.const_reject_duration_id IS NULL
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
                         WHEN l_sc_rec.const_quest_duration_id IS NULL
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

         IF l_count > 0
         THEN
            FOR i IN 1 .. l_count
            LOOP
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

   PROCEDURE get_process_shefit_files (
      p_use_crit_clob   OUT      VARCHAR2,
      p_crit_file       OUT      CLOB,
      p_use_otf_clob    OUT      VARCHAR2,
      p_otf_file        OUT      CLOB,
      p_data_stream     IN       VARCHAR2,
      p_db_office_id    IN       VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      NULL;
   END;
END cwms_vt;
/