/* Formatted on 2008/11/03 02:43 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY zz_utils
AS
/******************************************************************************
   NAME:       zz_utils
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/3/2008             1. Created this package body.
******************************************************************************/
   PROCEDURE load_cwms_shef_pe_codes
   IS
      query_cursor            sys_refcursor;
      l_pe_code               VARCHAR2 (2 BYTE);
      l_base_parameter_id     VARCHAR2 (32 BYTE);
      l_sub_parameter_id      VARCHAR2 (32 BYTE);
      l_parameter_type_id     VARCHAR2 (16 BYTE);
      l_unit_en_id            VARCHAR2 (16 BYTE);
      l_unit_si_id            VARCHAR2 (16 BYTE);
      l_shef_duration_id      VARCHAR2 (16 BYTE);
      l_shef_tse_code         VARCHAR2 (3 BYTE);
      l_shef_req_send_code    VARCHAR2 (7 BYTE);
      l_description           VARCHAR2 (256 BYTE);
      l_notes                 VARCHAR2 (256 BYTE);
      --
      l_parameter_code        NUMBER;
      l_base_parameter_code   NUMBER;
      l_sub_parameter_code    NUMBER;
      l_parameter_type_code   NUMBER;
      l_max_code              INTEGER;
      l_unit_code_en          NUMBER;
      l_unit_code_si          NUMBER;
   BEGIN
      OPEN query_cursor FOR
         SELECT *
           FROM zz_shef_pe;

      LOOP
         FETCH query_cursor
          INTO l_pe_code, l_base_parameter_id, l_sub_parameter_id,
               l_parameter_type_id, l_unit_en_id, l_unit_si_id,
               l_shef_duration_id, l_shef_tse_code, l_shef_req_send_code,
               l_description, l_notes;

         EXIT WHEN query_cursor%NOTFOUND;
         DBMS_OUTPUT.put_line (   l_pe_code
                               || ' '
                               || l_base_parameter_id
                               || ' '
                               || l_sub_parameter_id
                               || ' '
                               || l_parameter_type_id
                               || ' '
                               || l_unit_en_id
                               || ' '
                               || l_unit_si_id
                              );

         IF l_base_parameter_id IS NULL
         THEN
            l_parameter_code := 0;
         ELSE
            SELECT base_parameter_code
              INTO l_base_parameter_code
              FROM cwms_base_parameter
             WHERE UPPER (base_parameter_id) = UPPER (l_base_parameter_id);

            BEGIN
               IF l_sub_parameter_id IS NULL
               THEN
                  SELECT parameter_code
                    INTO l_parameter_code
                    FROM at_parameter
                   WHERE base_parameter_code = l_base_parameter_code
                     AND sub_parameter_id IS NULL
                     AND db_office_code = 53;
               ELSE
                  SELECT parameter_code
                    INTO l_parameter_code
                    FROM at_parameter
                   WHERE base_parameter_code = l_base_parameter_code
                     AND UPPER (sub_parameter_id) = UPPER (l_sub_parameter_id)
                     AND db_office_code = 53;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  SELECT MAX (parameter_code)
                    INTO l_max_code
                    FROM at_parameter
                   WHERE db_office_code = 53;

                  l_parameter_code := l_max_code + 1;

                  INSERT INTO at_parameter
                              (parameter_code, db_office_code,
                               base_parameter_code, sub_parameter_id
                              )
                       VALUES (l_parameter_code, 53,
                               l_base_parameter_code, l_sub_parameter_id
                              );
            END;
         END IF;

         IF l_parameter_type_id IS NULL
         THEN
            l_parameter_type_code := 0;
         ELSE
            BEGIN
               SELECT parameter_type_code
                 INTO l_parameter_type_code
                 FROM cwms_parameter_type
                WHERE UPPER (parameter_type_id) = UPPER (l_parameter_type_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_parameter_type_code := 0;
            END;
         END IF;

         IF l_unit_en_id IS NULL
         THEN
            l_unit_code_en := NULL;
         ELSE
            BEGIN
               SELECT unit_code
                 INTO l_unit_code_en
                 FROM cwms_unit
                WHERE unit_id = l_unit_en_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_unit_code_en := NULL;
               WHEN OTHERS
               THEN
                  l_unit_code_en := NULL;
            END;
         END IF;

         IF l_unit_si_id IS NULL
         THEN
            l_unit_code_si := NULL;
         ELSE
            BEGIN
               SELECT unit_code
                 INTO l_unit_code_si
                 FROM cwms_unit
                WHERE unit_id = l_unit_si_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_unit_code_si := NULL;
               WHEN OTHERS
               THEN
                  l_unit_code_si := NULL;
            END;
         END IF;

         INSERT INTO cwms_shef_pe_codes
                     (shef_pe_code, shef_tse_code, shef_duration_code,
                      shef_req_send_code, unit_code_en, unit_code_si,
                      parameter_code, parameter_type_code, description,
                      notes
                     )
              VALUES (l_pe_code, l_shef_tse_code, l_shef_duration_id,
                      l_shef_req_send_code, l_unit_code_en, l_unit_code_si,
                      l_parameter_code, l_parameter_type_code, l_description,
                      l_notes
                     );
      END LOOP;

      CLOSE query_cursor;
   END;
END zz_utils;
/