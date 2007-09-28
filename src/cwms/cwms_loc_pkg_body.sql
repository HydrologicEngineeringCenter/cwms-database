/* Formatted on 2007/09/28 12:25 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_loc
AS
--
-- num_group_assigned_to_shef return the number of groups -
-- currently assigned in the at_shef_decode table.
   FUNCTION znum_group_assigned_to_shef (
      p_group_cat_array   IN   group_cat_tab_t,
      p_db_office_code    IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_tmp   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO l_tmp
        FROM at_shef_decode
       WHERE loc_group_code IN (
                SELECT loc_group_code
                  FROM (SELECT a.loc_category_code, b.loc_group_id
                          FROM at_loc_category a,
                               TABLE
                                   (CAST (p_group_cat_array AS group_cat_tab_t)
                                   ) b
                         WHERE UPPER (a.loc_category_id) =
                                              UPPER (TRIM (b.loc_category_id))
                           AND a.db_office_code IN
                                  (p_db_office_code,
                                   cwms_util.db_office_code_all
                                  )) c,
                       at_loc_group d
                 WHERE UPPER (d.loc_group_id) = UPPER (TRIM (c.loc_group_id))
                   AND d.loc_category_code = c.loc_category_code
                   AND d.db_office_code IN
                             (p_db_office_code, cwms_util.db_office_code_all));

      RETURN l_tmp;
   END;

   FUNCTION num_group_assigned_to_shef (
      p_group_cat_array   IN   group_cat_tab_t,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_db_office_code   NUMBER
                             := cwms_util.get_db_office_code (p_db_office_id);
   BEGIN
      RETURN znum_group_assigned_to_shef (p_group_cat_array,
                                          l_db_office_code);
   END;

--loc_cat_grp_rec_tab_t IS TABLE OF loc_cat_grp_rec_t
--********************************************************************** -
--********************************************************************** -
--
-- get_ts_code returns ts_code...
--
---------------------------------------------------------------------------
   FUNCTION get_ts_code (p_office_id IN VARCHAR2, p_cwms_ts_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_ts_code   NUMBER := NULL;
   BEGIN
      SELECT ts_code
        INTO l_ts_code
        FROM mv_cwms_ts_id
       WHERE UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id)
         AND UPPER (db_office_id) = UPPER (p_office_id);

      RETURN l_ts_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('TS_ID_NOT_FOUND',
                         p_office_id || '.' || p_cwms_ts_id
                        );
      WHEN OTHERS
      THEN
         RAISE;
   END get_ts_code;

--********************************************************************** -
--********************************************************************** -
--
-- get_location_code returns location_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_location_code (
      p_db_office_id   IN   VARCHAR2,
      p_location_id    IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      l_db_office_code   NUMBER := cwms_util.get_office_code (p_db_office_id);
   BEGIN
      RETURN get_location_code (p_db_office_code      => l_db_office_code,
                                p_location_id         => p_location_id
                               );
   END;

--
   FUNCTION get_location_code (
      p_db_office_code   IN   NUMBER,
      p_location_id      IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      l_location_code   NUMBER;
   BEGIN
      --
      SELECT apl.location_code
        INTO l_location_code
        FROM at_physical_location apl, at_base_location abl
       WHERE apl.base_location_code = abl.base_location_code
         AND UPPER (abl.base_location_id) =
                                 UPPER (cwms_util.get_base_id (p_location_id))
         AND NVL (UPPER (apl.sub_location_id), '.') =
                       NVL (UPPER (cwms_util.get_sub_id (p_location_id)), '.')
         AND abl.db_office_code = p_db_office_code;

      --
      RETURN l_location_code;
   --
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('LOCATION_ID_NOT_FOUND', p_location_id);
      WHEN OTHERS
      THEN
         RAISE;
   END get_location_code;

--********************************************************************** -
--********************************************************************** -
--
-- get_state_code returns state_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_state_code (p_state_initial IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_state_code   NUMBER;
   BEGIN
       --dbms_output.put_line('function: get_county_code');
      --
      -- initialize l_state_initial...
      IF p_state_initial IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT state_code
        INTO l_state_code
        FROM cwms_state
       WHERE UPPER (state_initial) = UPPER (p_state_initial);

      RETURN l_state_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20213,
                                     p_state_initial
                                  || ' is an invalid State Abreviation',
                                  TRUE
                                 );
      WHEN OTHERS
      THEN
         RAISE;
   END;

--********************************************************************** -
--********************************************************************** -
--
-- get_county_code returns county_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_county_code (
      p_county_name     IN   VARCHAR2 DEFAULT NULL,
      p_state_initial   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_county_code     NUMBER;
      l_county_name     VARCHAR2 (40);
      l_state_initial   VARCHAR2 (2);
   BEGIN
      -- initialize l_county_name...
      IF p_county_name IS NULL
      THEN
         l_county_name := 'Unknown County or County N/A';
      ELSE
         l_county_name := p_county_name;
      END IF;

       --
      -- initialize l_state_initial...
      IF p_state_initial IS NULL
      THEN
         l_state_initial := '00';
      ELSE
         l_state_initial := p_state_initial;
      END IF;

      --dbms_output.put_line('function: get_county_code_code');
      SELECT county_code
        INTO l_county_code
        FROM cwms_county
       WHERE UPPER (county_name) = UPPER (l_county_name)
         AND state_code = get_state_code (l_state_initial);

      RETURN l_county_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20214,
                                     'Could not find '
                                  || p_county_name
                                  || ' county/parish '
                                  || ' in '
                                  || p_state_initial,
                                  TRUE
                                 );
      WHEN OTHERS
      THEN
         RAISE;
   END;

--********************************************************************** -
--********************************************************************** -
--
-- get_county_code returns zone_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_timezone_code (p_time_zone_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_zone_code   NUMBER;
   BEGIN
      --dbms_output.put_line('function: get_county_code');
      SELECT time_zone_code
        INTO l_zone_code
        FROM cwms_time_zone
       WHERE UPPER (time_zone_name) = UPPER (p_time_zone_id);

      RETURN l_zone_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20215,
                                     'Could not find a '
                                  || p_time_zone_id
                                  || ' time zone',
                                  TRUE
                                 );
      WHEN OTHERS
      THEN
         RAISE;
   END;

--********************************************************************** -
--********************************************************************** -
--
-- CONVERT_FROM_TO converts a pararameter from one unit to antoher
--
------------------------------------------------------------------------------*/
   FUNCTION convert_from_to (
      p_orig_value           IN   NUMBER,
      p_from_unit_name       IN   VARCHAR2,
      p_to_unit_name         IN   VARCHAR2,
      p_abstract_paramname   IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      l_return_value   NUMBER;
   BEGIN
      --
      -- retrieve correct unit conversion factor/offset...
      BEGIN
         SELECT p_orig_value * factor + offset
           INTO l_return_value
           FROM cwms_unit_conversion
          WHERE from_unit_id = p_from_unit_name
                AND to_unit_id = p_to_unit_name;

         RETURN l_return_value;
      --
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            raise_application_error
                                (-20216,
                                    'Unable to find conversion factor from '
                                 || p_from_unit_name
                                 || ' to '
                                 || p_to_unit_name
                                 || ' in CWMS DB',
                                 TRUE
                                );
         WHEN OTHERS
         THEN
            RAISE;
      END;
   END convert_from_to;

--********************************************************************** -
--********************************************************************** -
--
-- get_unit_code returns zone_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_unit_code (unitname IN VARCHAR2, abstractparamname IN VARCHAR2)
      RETURN NUMBER
   IS
      l_unit_code   NUMBER;
   BEGIN
      SELECT unit_code
        INTO l_unit_code
        FROM cwms_unit
       WHERE UPPER (unit_id) = UPPER (unitname)
         AND abstract_param_code =
                                (SELECT abstract_param_code
                                   FROM cwms_abstract_parameter
                                  WHERE abstract_param_id = abstractparamname);

      RETURN l_unit_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20217,
                                     '"'
                                  || unitname
                                  || '" is not a recognized '
                                  || abstractparamname
                                  || ' unit',
                                  TRUE
                                 );
      WHEN OTHERS
      THEN
         RAISE;
   END;

   FUNCTION is_cwms_id_valid (p_base_loc_id IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count   NUMBER := 0;
   BEGIN
      -- Check that cwmsIdNew starts with an alphnumeric and does
      -- not conatain a period.
      l_count := REGEXP_INSTR (p_base_loc_id, '[\.]');
      l_count := l_count + REGEXP_INSTR (p_base_loc_id, '[^[:alnum:]]');

      IF l_count > 0
      THEN
         RETURN FALSE;
      END IF;

      RETURN TRUE;
   END is_cwms_id_valid;

--********************************************************************** -
--********************************************************************** -
--.
--  CREATE_LOCATION_RAW -
--.
--********************************************************************** -
--
-- The create_location_raw call is called by create_location and -
-- rename_location. It's intended to be only called internally because -
-- the call accepts raw codeed values such as db_office_code. -
--.
--*---------------------------------------------------------------------*-
--
   PROCEDURE create_location_raw (
      p_base_location_code   OUT      NUMBER,
      p_location_code        OUT      NUMBER,
      p_base_location_id     IN       VARCHAR2,
      p_sub_location_id      IN       VARCHAR2,
      p_db_office_code       IN       NUMBER,
      p_location_type        IN       VARCHAR2 DEFAULT NULL,
      p_elevation            IN       NUMBER DEFAULT NULL,
      p_vertical_datum       IN       VARCHAR2 DEFAULT NULL,
      p_latitude             IN       NUMBER DEFAULT NULL,
      p_longitude            IN       NUMBER DEFAULT NULL,
      p_horizontal_datum     IN       VARCHAR2 DEFAULT NULL,
      p_public_name          IN       VARCHAR2 DEFAULT NULL,
      p_long_name            IN       VARCHAR2 DEFAULT NULL,
      p_description          IN       VARCHAR2 DEFAULT NULL,
      p_time_zone_code       IN       NUMBER DEFAULT NULL,
      p_county_code          IN       NUMBER DEFAULT NULL,
      p_active_flag          IN       VARCHAR2 DEFAULT 'T'
   )
   IS
      l_hashcode          NUMBER;
      l_ret               NUMBER;
      l_base_loc_exists   BOOLEAN := TRUE;
      l_sub_loc_exists    BOOLEAN := TRUE;
   BEGIN
      BEGIN
         -- Check if base_location exists -
         SELECT base_location_code
           INTO p_base_location_code
           FROM at_base_location abl
          WHERE UPPER (abl.base_location_id) = UPPER (p_base_location_id)
            AND abl.db_office_code = p_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_base_loc_exists := FALSE;
      END;

      IF l_base_loc_exists
      THEN
         BEGIN
            -- Check if sub_location exists -
            IF p_sub_location_id IS NULL
            THEN
               SELECT location_code
                 INTO p_location_code
                 FROM at_physical_location apl
                WHERE apl.base_location_code = p_base_location_code
                  AND apl.sub_location_id IS NULL;
            ELSE
               SELECT location_code
                 INTO p_location_code
                 FROM at_physical_location apl
                WHERE apl.base_location_code = p_base_location_code
                  AND UPPER (apl.sub_location_id) = UPPER (p_sub_location_id);
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_sub_loc_exists := FALSE;
         END;
      END IF;

      IF NOT l_base_loc_exists OR NOT l_sub_loc_exists
      THEN
           ---------.
           ---------.
         -- Create new base and sub locations in database...
         l_hashcode :=
            DBMS_UTILITY.get_hash_value (   p_db_office_code
                                         || UPPER (p_base_location_id)
                                         || UPPER (p_sub_location_id),
                                         0,
                                         1073741823
                                        );
         l_ret :=
            DBMS_LOCK.request (ID                     => l_hashcode,
                               TIMEOUT                => 0,
                               lockmode               => 5,
                               release_on_commit      => TRUE
                              );

         IF l_ret > 0
         THEN
            DBMS_LOCK.sleep (2);
         ELSE
            ---------.
            ---------.
             -- Create new Base Location (if necessary)...
             --.
            IF NOT l_base_loc_exists
            THEN
                 --.
               -- Insert new Base Location -
               INSERT INTO at_base_location
                           (base_location_code, db_office_code,
                            base_location_id, active_flag
                           )
                    VALUES (cwms_seq.NEXTVAL, p_db_office_code,
                            p_base_location_id, p_active_flag
                           )
                 RETURNING base_location_code
                      INTO p_base_location_code;

                 --
               --.Insert new Base Location into at_physical_location -
               INSERT INTO at_physical_location
                           (location_code, base_location_code,
                            time_zone_code, county_code, location_type,
                            elevation, vertical_datum, longitude,
                            latitude, horizontal_datum, public_name,
                            long_name, description, active_flag
                           )
                    VALUES (p_base_location_code, p_base_location_code,
                            p_time_zone_code, p_county_code, p_location_type,
                            p_elevation, p_vertical_datum, p_longitude,
                            p_latitude, p_horizontal_datum, p_public_name,
                            p_long_name, p_description, p_active_flag
                           );

               p_location_code := p_base_location_code;
            END IF;

            ---------.
            ---------.
             -- Create new (Sub) Location (if necessary)...
             --.
            IF p_sub_location_id IS NOT NULL
            THEN
               INSERT INTO at_physical_location
                           (location_code, base_location_code,
                            sub_location_id, time_zone_code,
                            county_code, location_type, elevation,
                            vertical_datum, longitude, latitude,
                            horizontal_datum, public_name, long_name,
                            description, active_flag
                           )
                    VALUES (cwms_seq.NEXTVAL, p_base_location_code,
                            p_sub_location_id, p_time_zone_code,
                            p_county_code, p_location_type, p_elevation,
                            p_vertical_datum, p_longitude, p_latitude,
                            p_horizontal_datum, p_public_name, p_long_name,
                            p_description, p_active_flag
                           )
                 RETURNING location_code
                      INTO p_location_code;
            END IF;
         END IF;
      END IF;

      --
      COMMIT;                                  -- needed to release dbms_lock.
   --
   END create_location_raw;

--********************************************************************** -
--********************************************************************** -
--
-- UPDATE_LOC -
--
--*---------------------------------------------------------------------*-
--
-- This is the v1.4 api call - ported for backward compatibility.
--
--*---------------------------------------------------------------------*-
----
---
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
   PROCEDURE update_loc (
      p_office_id        IN   VARCHAR2,
      p_base_loc_id      IN   VARCHAR2,
      p_location_type    IN   VARCHAR2 DEFAULT NULL,
      p_elevation        IN   NUMBER DEFAULT NULL,
      p_elev_unit_id     IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum   IN   VARCHAR2 DEFAULT NULL,
      p_latitude         IN   NUMBER DEFAULT NULL,
      p_longitude        IN   NUMBER DEFAULT NULL,
      p_public_name      IN   VARCHAR2 DEFAULT NULL,
      p_description      IN   VARCHAR2 DEFAULT NULL,
      p_timezone_id      IN   VARCHAR2 DEFAULT NULL,
      p_county_name      IN   VARCHAR2 DEFAULT NULL,
      p_state_initial    IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls      IN   NUMBER DEFAULT cwms_util.true_num
   )
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--
   IS
      l_loc_new            loc_type_ds;
      l_horizontal_datum   VARCHAR2 (16) := NULL;
      l_long_name          VARCHAR2 (80) := NULL;
      l_active             VARCHAR2 (1)  := NULL;
      l_ignorenulls        VARCHAR2 (1)  := 'T';
   BEGIN
      IF p_ignorenulls <> cwms_util.true_num
      THEN
         l_ignorenulls := 'F';
      END IF;

      update_location (p_office_id,
                       p_base_loc_id,
                       p_location_type,
                       p_elevation,
                       p_elev_unit_id,
                       p_vertical_datum,
                       p_latitude,
                       p_longitude,
                       l_horizontal_datum,
                       p_public_name,
                       l_long_name,
                       p_description,
                       p_timezone_id,
                       p_county_name,
                       p_state_initial,
                       l_active,
                       p_ignorenulls
                      );
   END update_loc;

--********************************************************************** -
--********************************************************************** -
--
-- UPDATE_LOCATION -
--
--*---------------------------------------------------------------------*-
--
-- Version 2.0 api call -
--
--*---------------------------------------------------------------------*-
--
   PROCEDURE update_location (
      p_location_id        IN   VARCHAR2,
      p_location_type      IN   VARCHAR2 DEFAULT NULL,
      p_elevation          IN   NUMBER DEFAULT NULL,
      p_elev_unit_id       IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum     IN   VARCHAR2 DEFAULT NULL,
      p_latitude           IN   NUMBER DEFAULT NULL,
      p_longitude          IN   NUMBER DEFAULT NULL,
      p_horizontal_datum   IN   VARCHAR2 DEFAULT NULL,
      p_public_name        IN   VARCHAR2 DEFAULT NULL,
      p_long_name          IN   VARCHAR2 DEFAULT NULL,
      p_description        IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_id       IN   VARCHAR2 DEFAULT NULL,
      p_county_name        IN   VARCHAR2 DEFAULT NULL,
      p_state_initial      IN   VARCHAR2 DEFAULT NULL,
      p_active             IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_code      at_physical_location.location_code%TYPE;
      l_time_zone_code     at_physical_location.time_zone_code%TYPE;
      l_county_code        cwms_county.county_code%TYPE;
      l_location_type      at_physical_location.location_type%TYPE;
      l_elevation          at_physical_location.elevation%TYPE;
      l_vertical_datum     at_physical_location.vertical_datum%TYPE;
      l_longitude          at_physical_location.longitude%TYPE;
      l_latitude           at_physical_location.latitude%TYPE;
      l_horizontal_datum   at_physical_location.horizontal_datum%TYPE;
      l_state_code         cwms_state.state_code%TYPE;
      l_public_name        at_physical_location.public_name%TYPE;
      l_long_name          at_physical_location.long_name%TYPE;
      l_description        at_physical_location.description%TYPE;
      l_active_flag        at_physical_location.active_flag%TYPE;
      --
      l_state_initial      cwms_state.state_initial%TYPE;
      l_county_name        cwms_county.county_name%TYPE;
      l_ignorenulls        BOOLEAN       := cwms_util.is_true (p_ignorenulls);
   BEGIN
      --.
      -- dbms_output.put_line('Bienvenue a update_loc');

      -- Retrieve the location's Location Code.
      --
      l_location_code := get_location_code (p_db_office_id, p_location_id);
      DBMS_OUTPUT.put_line ('l_location_code: ' || l_location_code);

      --
      --  If get_location_code did not throw an exception, then a valid base_location_id &.
      --  office_id pair was passed in, therefore continue to update the.
      --  at_physical_location table by first retrieving data for the existing location...
      --
      SELECT apl.location_type, apl.elevation, apl.vertical_datum,
             apl.latitude, apl.longitude, apl.horizontal_datum,
             apl.public_name, apl.long_name, apl.description,
             apl.time_zone_code, apl.county_code, apl.active_flag
        INTO l_location_type, l_elevation, l_vertical_datum,
             l_latitude, l_longitude, l_horizontal_datum,
             l_public_name, l_long_name, l_description,
             l_time_zone_code, l_county_code, l_active_flag
        FROM at_physical_location apl
       WHERE apl.location_code = l_location_code;

      DBMS_OUTPUT.put_line ('l_elevation: ' || l_elevation);

----------------------------------------------------------
----------------------------------------------------------
-- Perform validation checks on newly passed parameters...

      ---------.
      ---------.
       -- Update location_type...
       --.
      IF p_location_type IS NOT NULL
      THEN
         l_location_type := p_location_type;
      ELSIF NOT l_ignorenulls
      THEN
         l_location_type := NULL;
      END IF;

      ---------.
      ---------.
       -- Update any new elvation to the correct DB units...
       --.
      IF p_elevation IS NOT NULL
      THEN
         l_elevation :=
            convert_from_to (p_elevation,
                             p_elev_unit_id,
                             l_elev_db_unit,
                             l_abstract_elev_param
                            );
      ELSIF NOT l_ignorenulls
      THEN
         l_elevation := NULL;
      END IF;

      ---------.
      ---------.
       -- Update vertical datum...
       --
      IF p_vertical_datum IS NOT NULL
      THEN
         l_vertical_datum := p_vertical_datum;
      ELSIF NOT l_ignorenulls
      THEN
         l_vertical_datum := NULL;
      END IF;

      ---------.
      ---------.
       -- Update latitude...
       --
      IF p_latitude IS NOT NULL
      THEN
         IF ABS (p_latitude) > 90
         THEN
            raise_application_error (-20219,
                                        'INVALID Latitude value: '
                                     || p_latitude
                                     || ' - must be between -90 and +90',
                                     TRUE
                                    );
         END IF;

         l_latitude := p_latitude;
      ELSIF NOT l_ignorenulls
      THEN
         l_latitude := NULL;
      END IF;

      ---------.
      ---------.
       -- Update longitude...
       --
      IF p_longitude IS NOT NULL
      THEN
         IF ABS (p_longitude) > 180
         THEN
            raise_application_error (-20218,
                                        'INVALID Longitude value: '
                                     || p_longitude
                                     || ' - must be between -180 and +180',
                                     TRUE
                                    );
         END IF;

         l_longitude := p_longitude;
      ELSIF NOT l_ignorenulls
      THEN
         l_longitude := NULL;
      END IF;

      ---------.
      ---------.
       -- Update horizontal datum...
       --
      IF p_horizontal_datum IS NOT NULL
      THEN
         l_horizontal_datum := p_horizontal_datum;
      ELSIF NOT l_ignorenulls
      THEN
         l_horizontal_datum := NULL;
      END IF;

      ---------.
      ---------.
       -- Update public_name...
       --
      IF p_public_name IS NOT NULL
      THEN
         l_public_name := p_public_name;
      ELSIF NOT l_ignorenulls
      THEN
         l_public_name := NULL;
      END IF;

      ---------.
      ---------.
       -- Update long_name...
       --
      IF p_long_name IS NOT NULL
      THEN
         l_long_name := p_long_name;
      ELSIF NOT l_ignorenulls
      THEN
         l_long_name := NULL;
      END IF;

      ---------.
      ---------.
       -- Update description...
       --
      IF p_description IS NOT NULL
      THEN
         l_description := p_description;
      ELSIF NOT l_ignorenulls
      THEN
         l_description := NULL;
      END IF;

      ---------.
      ---------.
       -- Update time_zone...
       --
      IF p_time_zone_id IS NOT NULL
      THEN
         l_time_zone_code := get_timezone_code (p_time_zone_id);
      ELSIF NOT l_ignorenulls
      THEN
         l_time_zone_code := NULL;
      END IF;

      ---------.
      ---------.
       -- Check and Update he State/County pair...
       --
      IF p_state_initial IS NULL AND p_county_name IS NOT NULL
      THEN        -- Throw exception - if a county name is passed in one must.
         -- also pass-in the county's state initials.
         cwms_err.RAISE ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
      ELSIF p_state_initial IS NOT NULL
      THEN                              -- Find the corresponding county_code.
         l_county_code := get_county_code (p_county_name, p_state_initial);
      ELSIF NOT l_ignorenulls
      THEN
         l_county_code := NULL;
      END IF;

      ---------.
      ---------.
       -- Update active_flag.
       --.
      IF p_active IS NOT NULL
      THEN
         IF cwms_util.is_true (p_active)
         THEN
            l_active_flag := 'T';
         ELSIF cwms_util.is_false (p_active)
         THEN
            l_active_flag := 'F';
         ELSE
            cwms_err.RAISE ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
         END IF;
      END IF;

--.
--*************************************.
-- Update at_physical_location table...
--.
      UPDATE at_physical_location
         SET location_type = l_location_type,
             elevation = l_elevation,
             vertical_datum = l_vertical_datum,
             latitude = l_latitude,
             longitude = l_longitude,
             horizontal_datum = l_horizontal_datum,
             public_name = l_public_name,
             long_name = l_long_name,
             description = l_description,
             time_zone_code = l_time_zone_code,
             county_code = l_county_code,
             active_flag = l_active_flag
       WHERE location_code = l_location_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         RAISE;
   END update_location;

--********************************************************************** -
--********************************************************************** -
--
-- INSERT_LOC -
--
--*---------------------------------------------------------------------*-
--
-- This is the v1.4 api call - ported for backward compatibility.
--
--*---------------------------------------------------------------------*-
--
---
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv...
   PROCEDURE insert_loc (
      p_office_id        IN   VARCHAR2,
      p_base_loc_id      IN   VARCHAR2,
      p_state_initial    IN   VARCHAR2 DEFAULT NULL,
      p_county_name      IN   VARCHAR2 DEFAULT NULL,
      p_timezone_name    IN   VARCHAR2 DEFAULT NULL,
      p_location_type    IN   VARCHAR2 DEFAULT NULL,
      p_latitude         IN   NUMBER DEFAULT NULL,
      p_longitude        IN   NUMBER DEFAULT NULL,
      p_elevation        IN   NUMBER DEFAULT NULL,
      p_elev_unit_id     IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum   IN   VARCHAR2 DEFAULT NULL,
      p_public_name      IN   VARCHAR2 DEFAULT NULL,
      p_long_name        IN   VARCHAR2 DEFAULT NULL,
      p_description      IN   VARCHAR2 DEFAULT NULL
   )
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--
   IS
      l_horizontal_datum   VARCHAR2 (16) := NULL;
      l_active             VARCHAR2 (1)  := 'T';
   BEGIN
      create_location (p_base_loc_id,
                       p_office_id,
                       p_location_type,
                       p_elevation,
                       p_elev_unit_id,
                       p_vertical_datum,
                       p_latitude,
                       p_longitude,
                       l_horizontal_datum,
                       p_public_name,
                       p_long_name,
                       p_description,
                       p_timezone_name,
                       p_county_name,
                       p_state_initial,
                       l_active
                      );
   END insert_loc;

--********************************************************************** -
--********************************************************************** -
--
-- CREATE_LOCATION -
--
--*---------------------------------------------------------------------*-
--
-- Replaces insert_loc in the 2.0 api -
--
--*---------------------------------------------------------------------*-
--
   PROCEDURE create_location (
      p_location_id        IN   VARCHAR2,
      p_location_type      IN   VARCHAR2 DEFAULT NULL,
      p_elevation          IN   NUMBER DEFAULT NULL,
      p_elev_unit_id       IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum     IN   VARCHAR2 DEFAULT NULL,
      p_latitude           IN   NUMBER DEFAULT NULL,
      p_longitude          IN   NUMBER DEFAULT NULL,
      p_horizontal_datum   IN   VARCHAR2 DEFAULT NULL,
      p_public_name        IN   VARCHAR2 DEFAULT NULL,
      p_long_name          IN   VARCHAR2 DEFAULT NULL,
      p_description        IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_id       IN   VARCHAR2 DEFAULT NULL,
      p_county_name        IN   VARCHAR2 DEFAULT NULL,
      p_state_initial      IN   VARCHAR2 DEFAULT NULL,
      p_active             IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_base_location_id     at_base_location.base_location_id%TYPE
                                     := cwms_util.get_base_id (p_location_id);
      --
      l_sub_location_id      at_physical_location.sub_location_id%TYPE
                                      := cwms_util.get_sub_id (p_location_id);
      --
      l_db_office_id         cwms_office.office_id%TYPE;
      l_db_office_code       cwms_office.office_code%TYPE;
      l_base_location_code   at_base_location.base_location_code%TYPE;
      l_location_code        at_physical_location.location_code%TYPE;
      l_base_loc_exists      BOOLEAN;
      l_loc_exists           BOOLEAN                                 := FALSE;
      --
      l_location_type        at_physical_location.location_type%TYPE;
      l_elevation            at_physical_location.elevation%TYPE      := NULL;
      l_vertical_datum       at_physical_location.vertical_datum%TYPE;
      l_latitude             at_physical_location.latitude%TYPE       := NULL;
      l_longitude            at_physical_location.longitude%TYPE      := NULL;
      l_horizontal_datum     at_physical_location.horizontal_datum%TYPE;
      l_public_name          at_physical_location.public_name%TYPE;
      l_long_name            at_physical_location.long_name%TYPE;
      l_description          at_physical_location.description%TYPE;
      l_time_zone_code       at_physical_location.time_zone_code%TYPE := NULL;
      l_county_code          cwms_county.county_code%TYPE             := NULL;
      l_active_flag          at_physical_location.active_flag%TYPE;
      --
      l_ret                  NUMBER;
      l_hashcode             NUMBER;
   --
   BEGIN
      --
--------------------------------------------------------
-- Set office_id...
--------------------------------------------------------
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      DBMS_APPLICATION_INFO.set_module ('rename_ts_code', 'get office code');
--------------------------------------------------------
-- Get the office_code...
--------------------------------------------------------
      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      --.
      -- Check if a Base Location already exists for this p_location_id...
      BEGIN
         SELECT base_location_code, base_location_id
           INTO l_base_location_code, l_base_location_id
           FROM at_base_location abl
          WHERE UPPER (abl.base_location_id) = l_base_location_id
            AND abl.db_office_code = l_db_office_code;

         l_base_loc_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_base_loc_exists := FALSE;
         WHEN OTHERS
         THEN
            RAISE;
      END;

      --.
      -- If Base Location exists, check if Sub Location already exists...
      IF l_base_loc_exists
      THEN
         BEGIN
            l_location_code :=
                            get_location_code (l_db_office_id, p_location_id);
            --.
            l_loc_exists := TRUE;
         EXCEPTION
            WHEN OTHERS         -- location_code does not exist so continue...
            THEN
               NULL;
         END;
      END IF;

      IF l_loc_exists
      THEN
         cwms_err.RAISE ('LOCATION_ID_ALREADY_EXISTS',
                         'cwms_loc',
                         p_location_id
                        );
      END IF;

----------------------------------------------------------
----------------------------------------------------------
-- Perform validation checks on newly passed parameters...
      ---------.
      ---------.
       -- location_type...
       --.
      l_location_type := p_location_type;

      ---------.
      ---------.
       -- Convert any new elvation to the correct DB units...
       --.
      IF p_elevation IS NOT NULL
      THEN
         l_elevation :=
            convert_from_to (p_elevation,
                             p_elev_unit_id,
                             l_elev_db_unit,
                             l_abstract_elev_param
                            );
      END IF;

      ---------.
      ---------.
       -- vertical datum...
       --
      l_vertical_datum := p_vertical_datum;

      ---------.
      ---------.
       -- latitude...
       --
      IF p_latitude IS NOT NULL
      THEN
         IF ABS (p_latitude) > 90
         THEN
            raise_application_error (-20219,
                                        'INVALID Latitude value: '
                                     || p_latitude
                                     || ' - must be between -90 and +90',
                                     TRUE
                                    );
         END IF;

         l_latitude := p_latitude;
      END IF;

      ---------.
      ---------.
       -- longitude...
       --
      IF p_longitude IS NOT NULL
      THEN
         IF ABS (p_longitude) > 180
         THEN
            raise_application_error (-20218,
                                        'INVALID Longitude value: '
                                     || p_longitude
                                     || ' - must be between -180 and +180',
                                     TRUE
                                    );
         END IF;

         l_longitude := p_longitude;
      END IF;

      ---------.
      ---------.
       --  horizontal datum...
       --
      l_horizontal_datum := p_horizontal_datum;
      ---------.
      ---------.
       -- public_name...
       --
      l_public_name := p_public_name;
      ---------.
      ---------.
       -- long_name...
       --
      l_long_name := p_long_name;
      ---------.
      ---------.
       -- description...
       --
      l_description := p_description;

      ---------.
      ---------.
       -- time_zone...
       --
      IF p_time_zone_id IS NOT NULL
      THEN
         l_time_zone_code := get_timezone_code (p_time_zone_id);
      END IF;

      ---------.
      ---------.
       -- Check and Update he State/County pair...
       --
      IF p_state_initial IS NULL AND p_county_name IS NOT NULL
      THEN        -- Throw exception - if a county name is passed in one must.
         -- also pass-in the county's state initials.
         cwms_err.RAISE ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
      ELSIF p_state_initial IS NOT NULL
      THEN                              -- Find the corresponding county_code.
         l_county_code := get_county_code (p_county_name, p_state_initial);
      END IF;

      ---------.
      ---------.
       -- Update active_flag.
       --.
      IF p_active IS NOT NULL
      THEN
         IF cwms_util.is_true (p_active)
         THEN
            l_active_flag := 'T';
         ELSIF cwms_util.is_false (p_active)
         THEN
            l_active_flag := 'F';
         ELSE
            cwms_err.RAISE ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
         END IF;
      ELSE
         l_active_flag := 'T';
      END IF;

       ---------.
       ---------.
      -- Create new base and sub locations in database...
      --.
      --.
      create_location_raw (l_base_location_code,
                           l_location_code,
                           l_base_location_id,
                           l_sub_location_id,
                           l_db_office_code,
                           l_location_type,
                           l_elevation,
                           l_vertical_datum,
                           l_latitude,
                           l_longitude,
                           l_horizontal_datum,
                           l_public_name,
                           l_long_name,
                           l_description,
                           l_time_zone_code,
                           l_county_code,
                           l_active_flag
                          );
   --
   END create_location;

--********************************************************************** -
--********************************************************************** -
--
-- RENAME_LOC -
--
--*---------------------------------------------------------------------*-
--
-- This is the v1.4 api call - ported for backward compatibility.
--
--*---------------------------------------------------------------------*-
---
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv...
   PROCEDURE rename_loc (
      p_officeid          IN   VARCHAR2,
      p_base_loc_id_old   IN   VARCHAR2,
      p_base_loc_id_new   IN   VARCHAR2
   )
   IS
   BEGIN
      rename_location (p_base_loc_id_old, p_base_loc_id_new, p_officeid);
   END rename_loc;

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--
--********************************************************************** -
--********************************************************************** -
--
-- RENAME_LOCATION -
--
--*---------------------------------------------------------------------*-
--
-- Version 2.0 rename_location...
--
--*---------------------------------------------------------------------*-
   PROCEDURE rename_location (
      p_location_id_old   IN   VARCHAR2,
      p_location_id_new   IN   VARCHAR2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_id_old          VARCHAR2 (49)    := TRIM (p_location_id_old);
      l_location_id_new          VARCHAR2 (49)    := TRIM (p_location_id_new);
      l_base_location_id_old     at_base_location.base_location_id%TYPE
                                 := cwms_util.get_base_id (l_location_id_old);
      --
      l_sub_location_id_old      at_physical_location.sub_location_id%TYPE
                                  := cwms_util.get_sub_id (l_location_id_old);
      --
      l_base_location_id_new     at_base_location.base_location_id%TYPE
                                 := cwms_util.get_base_id (l_location_id_new);
      --
      l_sub_location_id_new      at_physical_location.sub_location_id%TYPE
                                  := cwms_util.get_sub_id (l_location_id_new);
       --
      -- l_db_office_code           cwms_office.office_code%TYPE;
      l_base_location_code_old   at_base_location.base_location_code%TYPE;
      l_base_location_code_new   at_base_location.base_location_code%TYPE;
      l_location_code_old        at_physical_location.location_code%TYPE;
      l_location_code_new        at_physical_location.location_code%TYPE;
      --
      l_base_location_id_exist   at_base_location.base_location_id%TYPE;
      l_sub_location_id_exist    at_physical_location.sub_location_id%TYPE
                                                                      := NULL;
      --
      l_old_loc_is_base_loc      BOOLEAN                             := FALSE;
      l_base_id_case_change      BOOLEAN                             := FALSE;
      l_sub_id_case_change       BOOLEAN                             := FALSE;
      l_id_case_change           BOOLEAN                             := FALSE;
      --
      l_location_type            at_physical_location.location_type%TYPE;
      l_elevation                at_physical_location.elevation%TYPE  := NULL;
      l_vertical_datum           at_physical_location.vertical_datum%TYPE;
      l_latitude                 at_physical_location.latitude%TYPE   := NULL;
      l_longitude                at_physical_location.longitude%TYPE  := NULL;
      l_horizontal_datum         at_physical_location.horizontal_datum%TYPE;
      l_public_name              at_physical_location.public_name%TYPE;
      l_long_name                at_physical_location.long_name%TYPE;
      l_description              at_physical_location.description%TYPE;
      l_time_zone_code           at_physical_location.time_zone_code%TYPE
                                                                      := NULL;
      l_county_code              cwms_county.county_code%TYPE         := NULL;
      l_active_flag              at_physical_location.active_flag%TYPE;
      l_db_office_id             VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code           cwms_office.office_code%TYPE
                             := cwms_util.get_db_office_code (l_db_office_id);
   BEGIN
      ---------.
      ---------.
      --.
      --  New location can not already exist...
      BEGIN
         l_location_code_new :=
                        get_location_code (l_db_office_id, l_location_id_new);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- The get_location_code call should throw an exception becasue --
            -- the new location shouldn't exist.
            l_location_code_new := NULL;
      END;

      IF l_location_code_new IS NOT NULL
      THEN
         IF UPPER (l_location_id_old) != UPPER (l_location_id_new)
         THEN
            -- If l_location_code_new is found then the new location --
            -- already exists - so throw an exception...
            cwms_err.RAISE ('RENAME_LOC_BASE_2', p_location_id_new);
         END IF;
      END IF;

      ---------.
      ---------.
      --.
      -- retrieve existing base_location_code...
      --.
      BEGIN
         SELECT base_location_code, base_location_id
           INTO l_base_location_code_old, l_base_location_id_exist
           FROM at_base_location abl
          WHERE UPPER (abl.base_location_id) = UPPER (l_base_location_id_old)
            AND abl.db_office_code = l_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('LOCATION_ID_NOT_FOUND',
                            'rename_location',
                            p_location_id_old
                           );
      END;

       ---------.
       ---------.
       --.
       -- retrieve existing location data...
      --.
      IF l_sub_location_id_old IS NULL  -- A BASE Location is being renamed --
      THEN
         SELECT location_code, time_zone_code, county_code,
                location_type, elevation, vertical_datum, longitude,
                latitude, horizontal_datum, public_name, long_name,
                description, active_flag
           INTO l_location_code_old, l_time_zone_code, l_county_code,
                l_location_type, l_elevation, l_vertical_datum, l_longitude,
                l_latitude, l_horizontal_datum, l_public_name, l_long_name,
                l_description, l_active_flag
           FROM at_physical_location apl
          WHERE apl.base_location_code = l_base_location_code_old
            AND apl.sub_location_id IS NULL;

         --
         l_old_loc_is_base_loc := TRUE;
      ELSE                                         -- For BASE-SUB Locations -
         BEGIN
            SELECT location_code, sub_location_id,
                   time_zone_code, county_code, location_type,
                   elevation, vertical_datum, longitude, latitude,
                   horizontal_datum, public_name, long_name,
                   description, active_flag
              INTO l_location_code_old, l_sub_location_id_exist,
                   l_time_zone_code, l_county_code, l_location_type,
                   l_elevation, l_vertical_datum, l_longitude, l_latitude,
                   l_horizontal_datum, l_public_name, l_long_name,
                   l_description, l_active_flag
              FROM at_physical_location apl
             WHERE apl.base_location_code = l_base_location_code_old
               AND UPPER (apl.sub_location_id) = UPPER (l_sub_location_id_old);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.RAISE ('LOCATION_ID_NOT_FOUND',
                               'rename_location',
                               p_location_id_old
                              );
         END;
      END IF;

       ---------.
       ---------.
       --.
       -- Confirm that the new location id is valid...
      --.
      -- CHECK #1 - If old name is a base location, then new.
      -- name must also be a base location...
      --.
      IF l_old_loc_is_base_loc AND l_sub_location_id_new IS NOT NULL
      THEN
         cwms_err.RAISE ('RENAME_LOC_BASE_1',
                         p_location_id_old,
                         p_location_id_new
                        );
      END IF;

      --.
      -- CHECK #2 - The new location can not already exist...
      --.
      -- first check if this is a simple upper/lower case change rename -
      --.
      IF UPPER (l_location_id_new) = UPPER (l_location_id_old)
      THEN
         -- if old = new then find if base or sub or both have case changes -
         --.
         IF l_base_location_id_exist <> l_base_location_id_new
         THEN
            l_base_id_case_change := TRUE;
         END IF;

         --.
         IF l_sub_location_id_old IS NOT NULL
         THEN
            IF l_sub_location_id_exist <> l_sub_location_id_new
            THEN
               l_sub_id_case_change := TRUE;
            END IF;
         END IF;

         --.
         IF l_base_id_case_change OR l_sub_id_case_change
         THEN
            l_id_case_change := TRUE;
         ELSE
            cwms_err.RAISE ('RENAME_LOC_BASE_3', l_location_id_new);
         END IF;
      END IF;

      ---------.
      ---------.
      --.
      -- RENAME the location...
      --.
      CASE
         WHEN l_old_loc_is_base_loc
         THEN                                     -- Simple Base Loc Rename --
            UPDATE at_base_location abl
               SET base_location_id = l_base_location_id_new
             WHERE abl.base_location_code = l_base_location_code_old;
         --
      WHEN l_sub_location_id_new IS NULL
         THEN                            -- Old Loc renamed to new Base Loc --
            --.
            -- 1) create a new Base Location with the new Base_Location_ID -
            --.
            INSERT INTO at_base_location
                        (base_location_code, db_office_code,
                         base_location_id, active_flag
                        )
                 VALUES (cwms_seq.NEXTVAL, l_db_office_code,
                         l_base_location_id_new, l_active_flag
                        )
              RETURNING base_location_code
                   INTO l_base_location_code_new;

            --.
            -- 2) update the old location by:
            --    a) updating its Base Location Code with the newly generated --
            --       Base_Location_Code, --
            --    b) setting the sub_location_id to null --
            --.
            UPDATE at_physical_location apl
               SET base_location_code = l_base_location_code_new,
                   sub_location_id = NULL
             WHERE apl.location_code = l_location_code_old;
         ELSE
            IF UPPER (l_base_location_id_old) =
                                               UPPER (l_base_location_id_new)
            THEN               -- Simple rename of Base and/or Sub Loc IDs --
               IF l_base_id_case_change
               THEN
                  UPDATE at_base_location abl
                     SET base_location_id = l_base_location_id_new
                   WHERE abl.base_location_code = l_base_location_code_old;
               END IF;

               --
               UPDATE at_physical_location apl
                  SET sub_location_id = l_sub_location_id_new
                WHERE apl.location_code = l_location_code_old;
            ELSE          -- rename to a new Base Loc requires new Base Loc --
                          --.
               --
               -- 1) create a new Base Location with the new Base Location_name -
               --.
               create_location_raw (l_base_location_code_new,
                                    l_location_code_new,
                                    l_base_location_id_new,
                                    NULL,
                                    l_db_office_code,
                                    l_location_type,
                                    l_elevation,
                                    l_vertical_datum,
                                    l_latitude,
                                    l_longitude,
                                    l_horizontal_datum,
                                    l_public_name,
                                    l_long_name,
                                    l_description,
                                    l_time_zone_code,
                                    l_county_code,
                                    l_active_flag
                                   );

               --.
               -- 2) update the old location by:
               --    a) updating its Base Location Code with the newly generated --
               --       Base_Location_Code, --
               --    b) setting the sub_location_id to the new sub_location_id --
               --.
               UPDATE at_physical_location apl
                  SET base_location_code = l_base_location_code_new,
                      sub_location_id = l_sub_location_id_new
                WHERE apl.location_code = l_location_code_old;
            END IF;
      END CASE;

      COMMIT;
   --
   END rename_location;

--********************************************************************** -
--********************************************************************** -
--
-- DELETE_LOC -
--
--*---------------------------------------------------------------------*-
--
-- This is the v1.4 api call - ported for backward compatibility.
--
--*---------------------------------------------------------------------*-
--
--
---
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
   PROCEDURE delete_loc (p_officeid IN VARCHAR2, p_base_loc_id IN VARCHAR2)
   IS
   BEGIN
      delete_location (p_base_loc_id, p_officeid);
   END delete_loc;

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--
--********************************************************************** -
--********************************************************************** -
--
-- DELETE_LOCATION -
--
--*---------------------------------------------------------------------*-
--
-- This delete is the new version 2.0 delete_location. It will only -
-- delete locations if there are no timeseries identifiers associated -
-- with the location to be deleted. -
--
-- NOTE: Deleting a Base Location will delete ALL associated Sub -
-- Locations -
    -- valid p_delete_actions:
    --                                         --
    --  delete_loc:         This action will delete the location_id only if there
    --                      are no cwms_ts_id's associated with this location_id.
    --                      If there are cwms_ts_id's assciated with the location_id,
    --                      then an exception is thrown.
    --  delete_ts_data:     This action will delete all of the data associated
    --                      with all of the cwms_ts_id's associated with this
    --                      location_id. The location_id and the cwms_ts_id's
    --                      themselves are not deleted.
    --  delete_ts_id:       This action will delete any cwms_ts_id that has
    --                      no associated data. Only ts_id's that have data
    --                      along with the location_id itself will remain.
    --  delete_ts_cascade:  This action will delete all data and all cwms_ts_id's
    --                      associazted with this location_id. It does not delete
    --                      the location_id.
    --  delete_loc_cascade: This will delete all data, all cwms_ts_id's, as well
    --                      as the location_id itself.

   --
--*---------------------------------------------------------------------*-
   PROCEDURE delete_location (
      p_location_id     IN   VARCHAR2,
      p_delete_action   IN   VARCHAR2 DEFAULT cwms_util.delete_loc,
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_count                NUMBER;
      l_base_location_id     at_base_location.base_location_id%TYPE
                                     := cwms_util.get_base_id (p_location_id);
      --
      l_sub_location_id      at_physical_location.sub_location_id%TYPE
                                      := cwms_util.get_sub_id (p_location_id);
      --
      l_base_location_code   NUMBER;
      l_location_code        NUMBER;
      l_db_office_code       NUMBER;
      --l_db_office_id         VARCHAR2 (16);
      l_delete_action        VARCHAR2 (22)
                := NVL (UPPER (TRIM (p_delete_action)), cwms_util.delete_loc);
      l_ts_ids_cur           sys_refcursor;
      l_this_is_a_base_loc   BOOLEAN                                 := FALSE;
      --
      l_count_ts             NUMBER                                      := 0;
      l_cwms_ts_id           VARCHAR2 (183);
      l_ts_code              NUMBER;
   --
   BEGIN
      l_db_office_code := cwms_util.get_office_code (p_db_office_id);

       -- You can only delete a location if that location does not have
      -- any time series identifiers associated with it.
      BEGIN
         SELECT base_location_code
           INTO l_base_location_code
           FROM at_base_location abl
          WHERE UPPER (abl.base_location_id) = UPPER (l_base_location_id)
            AND abl.db_office_code = l_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('LOCATION_ID_NOT_FOUND', p_location_id);
      END;

      l_location_code := get_location_code (p_db_office_id, p_location_id);

      --
      IF l_sub_location_id IS NULL
      THEN
         l_this_is_a_base_loc := TRUE;
      END IF;

      --
      -- Process Depricated delete_actions -
      IF l_delete_action = cwms_util.delete_key
      THEN
         l_delete_action := cwms_util.delete_loc;
      END IF;

      --
      -- Retrieve cwms_ts_ids for this location...
      IF l_this_is_a_base_loc
      THEN
         OPEN l_ts_ids_cur FOR
            SELECT cwms_ts_id
              FROM mv_cwms_ts_id
             WHERE location_code IN (
                              SELECT location_code
                                FROM at_physical_location
                               WHERE base_location_code =
                                                         l_base_location_code);
      ELSE
         OPEN l_ts_ids_cur FOR
            SELECT cwms_ts_id
              FROM mv_cwms_ts_id
             WHERE location_code = l_location_code;
      END IF;

      LOOP
         FETCH l_ts_ids_cur
          INTO l_cwms_ts_id;

         EXIT WHEN l_ts_ids_cur%NOTFOUND;

         IF l_delete_action = cwms_util.delete_loc
         THEN
            cwms_err.RAISE ('CAN_NOT_DELETE_LOC_1', p_location_id);
         END IF;

         CASE
            WHEN l_delete_action = cwms_util.delete_loc_cascade
             OR l_delete_action = cwms_util.delete_ts_cascade
            THEN
               cwms_ts.delete_ts (l_cwms_ts_id,
                                  cwms_util.delete_ts_cascade,
                                  l_db_office_code
                                 );
            WHEN l_delete_action = cwms_util.delete_ts_id
            THEN
               BEGIN
                  cwms_ts.delete_ts (l_cwms_ts_id,
                                     cwms_util.delete_ts_id,
                                     l_db_office_code
                                    );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;             -- exception thrown if ts_id has data.
               END;
            WHEN l_delete_action = cwms_util.delete_ts_data
            THEN
               cwms_ts.delete_ts (l_cwms_ts_id,
                                  cwms_util.delete_ts_data,
                                  l_db_office_code
                                 );
            ELSE
               cwms_err.RAISE ('INVALID_DELETE_ACTION', p_delete_action);
         END CASE;

         --
         l_count_ts := l_count_ts + 1;
      END LOOP;

      --
      CLOSE l_ts_ids_cur;

      --
      IF    l_delete_action = cwms_util.delete_loc_cascade
         OR l_delete_action = cwms_util.delete_loc
      THEN
         IF l_this_is_a_base_loc
         THEN                                     -- Deleting Base Location -
            DELETE FROM at_loc_group_assignment atlga
                  WHERE atlga.location_code IN (
                           SELECT location_code
                             FROM at_physical_location apl
                            WHERE apl.base_location_code =
                                                         l_base_location_code);

            DELETE FROM at_physical_location apl
                  WHERE apl.base_location_code = l_base_location_code;

            DELETE FROM at_base_location abl
                  WHERE abl.base_location_code = l_base_location_code;

            COMMIT;
         ELSE                              -- Deleting a single Sub Location -
            DELETE FROM at_loc_group_assignment atlga
                  WHERE atlga.location_code = l_location_code;

            DELETE FROM at_physical_location apl
                  WHERE apl.location_code = l_location_code;

            COMMIT;
         END IF;
      END IF;
   --
   END delete_location;

--********************************************************************** -
--********************************************************************** -
--
-- DELETE_LOCATION_CASCADE -
--
--*---------------------------------------------------------------------*-
--
-- This delete WILL DELETE any data associated with the location, -
-- NO QUESTIONS ASKED -
-- SO USE WITH CARE -
--
-- NOTE: Deleting a Base Location will delete ALL associated Sub -
-- Locations Including All DATA -
--
--*---------------------------------------------------------------------*-
   PROCEDURE delete_location_cascade (
      p_location_id    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_count                NUMBER;
      l_base_location_id     at_base_location.base_location_id%TYPE
                                     := cwms_util.get_base_id (p_location_id);
      --
      l_sub_location_id      at_physical_location.sub_location_id%TYPE
                                      := cwms_util.get_sub_id (p_location_id);
      --
      l_base_location_code   NUMBER;
      l_location_code        NUMBER;
      l_db_office_code       NUMBER;
      l_delete_date          DATE                                  := SYSDATE;
   BEGIN
      SELECT office_code
        INTO l_db_office_code
        FROM cwms_office
       WHERE office_id = UPPER (p_db_office_id);

       --
      --
      BEGIN
         SELECT base_location_code
           INTO l_base_location_code
           FROM at_base_location abl
          WHERE UPPER (abl.base_location_id) = UPPER (l_base_location_id)
            AND abl.db_office_code = l_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('LOCATION_ID_NOT_FOUND', p_location_id);
      END;

      IF l_sub_location_id IS NOT NULL
      THEN
         BEGIN
            SELECT location_code
              INTO l_location_code
              FROM at_physical_location
             WHERE base_location_code = l_base_location_code
               AND UPPER (sub_location_id) = UPPER (l_sub_location_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.RAISE ('LOCATION_ID_NOT_FOUND', p_location_id);
         END;
      END IF;

      IF l_sub_location_id IS NULL
      THEN                                         -- Deleting Base Location -
         BEGIN
            UPDATE at_cwms_ts_spec acts
               SET location_code = 0,
                   delete_date = l_delete_date
             WHERE ts_code IN (
                      SELECT ts_code
                        FROM at_cwms_ts_spec
                       WHERE location_code IN (
                                SELECT location_code
                                  FROM at_physical_location
                                 WHERE base_location_code =
                                                          l_base_location_code));
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               NULL;
         END;

         DELETE FROM at_loc_group_assignment atlga
               WHERE atlga.location_code IN (
                           SELECT location_code
                             FROM at_physical_location apl
                            WHERE apl.base_location_code =
                                                          l_base_location_code);

         DELETE FROM at_physical_location apl
               WHERE apl.base_location_code = l_base_location_code;

         DELETE FROM at_base_location abl
               WHERE abl.base_location_code = l_base_location_code;

         COMMIT;
      ELSE                                        -- Deleting a Sub Location -
         BEGIN
            UPDATE at_cwms_ts_spec acts
               SET location_code = 0,
                   delete_date = l_delete_date
             WHERE ts_code IN (SELECT ts_code
                                 FROM at_cwms_ts_spec
                                WHERE location_code = l_location_code);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               NULL;
         END;

         DELETE FROM at_loc_group_assignment atlga
               WHERE atlga.location_code = l_base_location_code;

         DELETE FROM at_physical_location apl
               WHERE apl.location_code = l_location_code;

         COMMIT;
      END IF;
   --
   END delete_location_cascade;

--********************************************************************** -
--********************************************************************** -
--
-- COPY_LOCATION -
--
--*---------------------------------------------------------------------*-
   PROCEDURE copy_location (
      p_location_id_old   IN   VARCHAR2,
      p_location_id_new   IN   VARCHAR2,
      p_active            IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      NULL;
   END copy_location;

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
--   PROCEDURE store_aliases (
--      p_location_id    IN   VARCHAR2,
--      p_alias_array    IN   alias_array,
--      p_store_rule     IN   VARCHAR2 DEFAULT 'DELETE INSERT',
--      p_ignorenulls    IN   VARCHAR2 DEFAULT 'T',
--      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
--   )
--   IS
--      l_agency_code         NUMBER;
--      l_office_id           VARCHAR2 (16);
--      l_office_code         NUMBER;
--      l_location_code       NUMBER;
--      l_array_count         NUMBER        := p_alias_array.COUNT;
--      l_count               NUMBER        := 1;
--      l_distinct            NUMBER;
--      l_store_rule          VARCHAR2 (16);
--      l_alias_id            VARCHAR2 (16);
--      l_alias_public_name   VARCHAR2 (32);
--      l_alias_long_name     VARCHAR2 (80);
--      l_insert              BOOLEAN;
--      l_ignorenulls         BOOLEAN
--                            := cwms_util.return_true_or_false (p_ignorenulls);
--   BEGIN
--      --
--      IF l_count = 0
--      THEN
--         cwms_err.RAISE
--                      ('GENERIC_ERROR',
--                       'No viable agency/alias data passed to store_aliases.'
--                      );
--      END IF;

   --------------------------------------------------------------------
---- Check that passed-in aliases are do not contain duplicates...
--------------------------------------------------------------------
--      SELECT COUNT (*)
--        INTO l_distinct
--        FROM (SELECT DISTINCT UPPER (t.agency_id)
--                         FROM TABLE (CAST (p_alias_array AS alias_array)) t);

   --      --
--      IF l_distinct != l_array_count
--      THEN
--         cwms_err.RAISE
--            ('GENERIC_ERROR',
--             'Duplicate Agency/Alias pairs are not permited. Only one Alias is permited per Agency (store_aliases).'
--            );
--      END IF;

   --      --
--      -- Make sure none of the alias_id's are null
--      --
--      SELECT COUNT (*)
--        INTO l_distinct
--        FROM (SELECT t.alias_id
--                FROM TABLE (CAST (p_alias_array AS alias_array)) t
--               WHERE alias_id IS NULL);

   --      --
--      IF l_distinct != 0
--      THEN
--         cwms_err.RAISE
--            ('GENERIC_ERROR',
--             'A NULL alias_id was submitted. alias_id may not be NULL. (store_aliases).'
--            );
--      END IF;

   --      --
--      IF p_db_office_id IS NULL
--      THEN
--         l_office_id := cwms_util.user_office_id;
--      ELSE
--         l_office_id := UPPER (p_db_office_id);
--      END IF;

   --      --
--      l_office_code := get_office_code (l_office_id);
--      l_location_code := get_location_code (l_office_id, p_location_id);

   --      --
--      IF p_store_rule IS NULL
--      THEN
--         l_store_rule := cwms_util.delete_all;
--      ELSIF UPPER (p_store_rule) = cwms_util.delete_all
--      THEN
--         l_store_rule := cwms_util.delete_all;
--      ELSIF UPPER (p_store_rule) = cwms_util.replace_all
--      THEN
--         l_store_rule := cwms_util.replace_all;
--      ELSE
--         cwms_err.RAISE ('GENERIC_ERROR',
--                            p_store_rule
--                         || ' is an invalid store rule. (store_aliases)'
--                        );
--      END IF;

   --      --
--      IF l_store_rule = cwms_util.delete_all
--      THEN
--         DELETE FROM at_loc_group_assignment atlga
--                  WHERE atlga.location_code = l_location_code;

   --         --
--         LOOP
--            EXIT WHEN l_count > l_array_count;

   --            --
--            BEGIN
--               SELECT agency_code
--                 INTO l_agency_code
--                 FROM at_agency_name
--                WHERE UPPER (agency_id) =
--                                     UPPER (p_alias_array (l_count).agency_id)
--                  AND db_office_code IN
--                                (l_office_code, cwms_util.db_office_code_all);
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  --.
--                  INSERT INTO at_agency_name
--                              (agency_code,
--                               agency_id,
--                               agency_name,
--                               db_office_code
--                              )
--                       VALUES (cwms_seq.NEXTVAL,
--                               p_alias_array (l_count).agency_id,
--                               p_alias_array (l_count).agency_name,
--                               l_office_code
--                              )
--                    RETURNING agency_code
--                         INTO l_agency_code;
--            END;

   --            --
--            INSERT INTO at_alias_name
--                        (location_code, agency_code,
--                         alias_id,
--                         alias_public_name,
--                         alias_long_name
--                        )
--                 VALUES (l_location_code, l_agency_code,
--                         p_alias_array (l_count).alias_id,
--                         p_alias_array (l_count).alias_public_name,
--                         p_alias_array (l_count).alias_long_name
--                        );

   --            --
--            l_count := l_count + 1;
--         END LOOP;
--      ELSE           -- store_rule is REPLACE ALL                            -
--         LOOP
--            EXIT WHEN l_count > l_array_count;

   --            --
--            -- retrieve agency_code...
--            BEGIN
--               SELECT agency_code
--                 INTO l_agency_code
--                 FROM at_agency_name
--                WHERE UPPER (agency_id) =
--                                     UPPER (p_alias_array (l_count).agency_id)
--                  AND db_office_code IN
--                                (l_office_code, cwms_util.db_office_code_all);
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN                  -- No agency_code found, so create one...
--                  --.
--                  INSERT INTO at_agency_name
--                              (agency_code,
--                               agency_id,
--                               agency_name,
--                               db_office_code
--                              )
--                       VALUES (cwms_seq.NEXTVAL,
--                               p_alias_array (l_count).agency_id,
--                               p_alias_array (l_count).agency_name,
--                               l_office_code
--                              )
--                    RETURNING agency_code
--                         INTO l_agency_code;
--            END;

   --            --
--            --
--            -- retrieve existing alias information...
--            l_insert := FALSE;

   --            BEGIN
--               SELECT alias_id, alias_public_name, alias_long_name
--                 INTO l_alias_id, l_alias_public_name, l_alias_long_name
--                 FROM at_alias_name
--                WHERE location_code = l_location_code
--                  AND agency_code = l_agency_code;

   --               --
--               IF     p_alias_array (l_count).alias_public_name IS NULL
--                  AND NOT l_ignorenulls
--               THEN
--                  l_alias_public_name := NULL;
--               END IF;

   --               IF     p_alias_array (l_count).alias_long_name IS NULL
--                  AND NOT l_ignorenulls
--               THEN
--                  l_alias_long_name := NULL;
--               END IF;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  l_insert := TRUE;
--            END;

   --            --
--            IF l_insert
--            THEN
--               --
--               INSERT INTO at_alias_name
--                           (location_code, agency_code,
--                            alias_id,
--                            alias_public_name,
--                            alias_long_name
--                           )
--                    VALUES (l_location_code, l_agency_code,
--                            p_alias_array (l_count).alias_id,
--                            p_alias_array (l_count).alias_public_name,
--                            p_alias_array (l_count).alias_long_name
--                           );
--            ELSE
--               UPDATE at_alias_name
--                  SET alias_id = p_alias_array (l_count).alias_id,
--                      alias_public_name = l_alias_public_name,
--                      alias_long_name = l_alias_long_name
--                WHERE location_code = l_location_code
--                  AND agency_code = l_agency_code;
--            --
--            END IF;

   --            --
--            l_count := l_count + 1;
--         END LOOP;
--      END IF;

   --      --
--      COMMIT;
----
--      NULL;
--   END store_aliases;

   --   PROCEDURE store_alias (
--      p_location_id         IN   VARCHAR2,
--      p_agency_id           IN   VARCHAR2,
--      p_alias_id            IN   VARCHAR2,
--      p_agency_name         IN   VARCHAR2 DEFAULT NULL,
--      p_alias_public_name   IN   VARCHAR2 DEFAULT NULL,
--      p_alias_long_name     IN   VARCHAR2 DEFAULT NULL,
--      p_ignorenulls         IN   VARCHAR2 DEFAULT 'T',
--      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
--   )
--   IS
--      l_alias_array   alias_array   := alias_array ();
--      l_store_rule    VARCHAR2 (16) := 'REPLACE ALL';
--   BEGIN
--      --
--      l_alias_array.EXTEND;
--      --
--      l_alias_array (1) :=
--         alias_type (p_agency_id,
--                     p_alias_id,
--                     p_agency_name,
--                     p_alias_public_name,
--                     p_alias_long_name
--                    );
--      --
--      store_aliases (p_location_id,
--                     l_alias_array,
--                     l_store_rule,
--                     p_ignorenulls,
--                     p_db_office_id
--                    );
--   END store_alias;

   --********************************************************************** -
--********************************************************************** -
--
-- STORE_LOC provides backward compatiblity for the dbi.  It will update a
-- location if it already exists by calling update_loc or create a new location
-- by calling create_loc.
--
--*---------------------------------------------------------------------*-
--
   PROCEDURE store_location (
      p_location_id        IN   VARCHAR2,
      p_location_type      IN   VARCHAR2 DEFAULT NULL,
      p_elevation          IN   NUMBER DEFAULT NULL,
      p_elev_unit_id       IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum     IN   VARCHAR2 DEFAULT NULL,
      p_latitude           IN   NUMBER DEFAULT NULL,
      p_longitude          IN   NUMBER DEFAULT NULL,
      p_horizontal_datum   IN   VARCHAR2 DEFAULT NULL,
      p_public_name        IN   VARCHAR2 DEFAULT NULL,
      p_long_name          IN   VARCHAR2 DEFAULT NULL,
      p_description        IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_id       IN   VARCHAR2 DEFAULT NULL,
      p_county_name        IN   VARCHAR2 DEFAULT NULL,
      p_state_initial      IN   VARCHAR2 DEFAULT NULL,
      p_active             IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_cwms_code     NUMBER;
      l_office_id     VARCHAR2 (16);
      l_office_code   NUMBER;
   BEGIN
      --
      -- check if cwms_id for this office already exists...
      BEGIN
         update_location (p_location_id,
                          p_location_type,
                          p_elevation,
                          p_elev_unit_id,
                          p_vertical_datum,
                          p_latitude,
                          p_longitude,
                          p_horizontal_datum,
                          p_public_name,
                          p_long_name,
                          p_description,
                          p_time_zone_id,
                          p_county_name,
                          p_state_initial,
                          p_active,
                          p_ignorenulls,
                          p_db_office_id
                         );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE;
         WHEN OTHERS
         THEN                                   --l_cwms_code was not found...
            DBMS_OUTPUT.put_line ('entering create_location');
            create_location (p_location_id,
                             p_location_type,
                             p_elevation,
                             p_elev_unit_id,
                             p_vertical_datum,
                             p_latitude,
                             p_longitude,
                             p_horizontal_datum,
                             p_public_name,
                             p_long_name,
                             p_description,
                             p_time_zone_id,
                             p_county_name,
                             p_state_initial,
                             p_active,
                             p_db_office_id
                            );
      END;
   --

   --      store_aliases (p_location_id,
--                     p_alias_array,
--                     'DELETE INSERT',
--                     p_ignorenulls,
--                     p_db_office_id
--                    );
   --
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END store_location;

--
--********************************************************************** -
--********************************************************************** -
--
-- RETRIEVE_LOCATION provides backward compatiblity for the dbi.  It will update a
-- location if it already exists by calling update_loc or create a new location
-- by calling create_loc.
--
--*---------------------------------------------------------------------*-
--
   PROCEDURE retrieve_location (
      p_location_id        IN OUT   VARCHAR2,
      p_elev_unit_id       IN       VARCHAR2 DEFAULT 'm',
      p_location_type      OUT      VARCHAR2,
      p_elevation          OUT      NUMBER,
      p_vertical_datum     OUT      VARCHAR2,
      p_latitude           OUT      NUMBER,
      p_longitude          OUT      NUMBER,
      p_horizontal_datum   OUT      VARCHAR2,
      p_public_name        OUT      VARCHAR2,
      p_long_name          OUT      VARCHAR2,
      p_description        OUT      VARCHAR2,
      p_time_zone_id       OUT      VARCHAR2,
      p_county_name        OUT      VARCHAR2,
      p_state_initial      OUT      VARCHAR2,
      p_active             OUT      VARCHAR2,
      p_alias_cursor       OUT      sys_refcursor,
      p_db_office_id       IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_id       VARCHAR2 (16);
      l_office_code     NUMBER;
      l_location_code   NUMBER;
      --
      -- l_alias_cursor    sys_refcursor;
   --
   BEGIN
      l_office_id := cwms_util.get_db_office_id (p_db_office_id);
      --
      l_office_code := cwms_util.get_db_office_code (l_office_id);
      l_location_code := get_location_code (l_office_id, p_location_id);

      --
      SELECT al.location_id
        INTO p_location_id
        FROM av_loc al
       WHERE al.location_code = l_location_code AND unit_system = 'SI';

      --
      SELECT apl.location_type,
             convert_from_to (apl.elevation, 'm', p_elev_unit_id, 'Length')
                                                                         elev,
             apl.latitude, apl.longitude, apl.horizontal_datum,
             apl.public_name, apl.long_name, apl.description,
             ctz.time_zone_name, cc.county_name, cs.state_initial,
             apl.active_flag
        INTO p_location_type,
             p_elevation,
             p_latitude, p_longitude, p_horizontal_datum,
             p_public_name, p_long_name, p_description,
             p_time_zone_id, p_county_name, p_state_initial,
             p_active
        FROM at_physical_location apl,
             cwms_county cc,
             cwms_state cs,
             cwms_time_zone ctz
       WHERE apl.county_code = cc.county_code
         AND cc.state_code = cs.state_code
         AND apl.time_zone_code = ctz.time_zone_code
         AND apl.location_code = l_location_code;

      --
--      cwms_cat.cat_loc_aliases (l_alias_cursor,
--                                p_location_id,
--                                NULL,
--                                'F',
--                                l_office_id
--                               );
      cwms_cat.cat_loc_aliases (p_cwms_cat             => p_alias_cursor,
                                p_location_id          => p_location_id,
                                p_loc_category_id      => NULL,
                                p_loc_group_id         => NULL,
                                p_abreviated           => 'F',
                                p_db_office_id         => l_office_id
                               );
      --
      -- p_alias_cursor := l_alias_cursor;
      --
   --
   END retrieve_location;

   FUNCTION get_loc_category_code (
      p_loc_category_id   IN   VARCHAR2,
      p_db_office_code    IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_loc_category_code   NUMBER;
   BEGIN
      BEGIN
         SELECT atlc.loc_category_code
           INTO l_loc_category_code
           FROM at_loc_category atlc
          WHERE atlc.db_office_code IN (53, p_db_office_code)
            AND UPPER (atlc.loc_category_id) =
                                              UPPER (TRIM (p_loc_category_id));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('ITEM_DOES_NOT__EXIST',
                            'Category id: ',
                            p_loc_category_id
                           );
      END;

      RETURN l_loc_category_code;
   END get_loc_category_code;

   FUNCTION get_loc_group_code (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_db_office_code    IN   NUMBER
   )
      RETURN NUMBER
   IS
      l_loc_category_code   NUMBER;
      l_loc_group_code      NUMBER;
   BEGIN
      l_loc_category_code :=
                  get_loc_category_code (p_loc_category_id, p_db_office_code);

      BEGIN
         SELECT loc_group_code
           INTO l_loc_group_code
           FROM at_loc_group atlg
          WHERE atlg.loc_category_code = l_loc_category_code
            AND UPPER (atlg.loc_group_id) = UPPER (p_loc_group_id)
            AND db_office_code IN (53, p_db_office_code);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('ITEM_DOES_NOT__EXIST',
                            'group id: ',
                            p_loc_group_id
                           );
      END;

      RETURN l_loc_group_code;
   END get_loc_group_code;

   PROCEDURE create_loc_category (
      p_loc_category_id     IN   VARCHAR2,
      p_loc_category_desc   IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_tmp   NUMBER;
   BEGIN
      l_tmp :=
         create_loc_category_f (p_loc_category_id        => p_loc_category_id,
                                p_loc_category_desc      => p_loc_category_desc,
                                p_db_office_id           => p_db_office_id
                               );
   END;

   FUNCTION create_loc_category_f (
      p_loc_category_id     IN   VARCHAR2,
      p_loc_category_desc   IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code      NUMBER;
      l_cat_is_cwms_cat     BOOLEAN;
      l_tmp                 NUMBER;
      l_loc_category_id     VARCHAR2 (32)  := TRIM (p_loc_category_id);
      l_loc_category_desc   VARCHAR2 (128) := TRIM (p_loc_category_desc);
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      -- Confirm that the new category is not a system/cwms category..
      --
      BEGIN
         SELECT atlc.loc_category_code
           INTO l_tmp
           FROM at_loc_category atlc
          WHERE UPPER (loc_category_id) = UPPER (l_loc_category_id)
            AND db_office_code = (SELECT office_code
                                    FROM cwms_office
                                   WHERE office_id = 'CWMS');

         l_cat_is_cwms_cat := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_cat_is_cwms_cat := FALSE;
      END;

      IF l_cat_is_cwms_cat
      THEN
         cwms_err.RAISE
                 ('ITEM_ALREADY_EXISTS',
                     'Cannot create the '
                  || l_loc_category_id
                  || ' category because it already exists as a system category.'
                 );
      END IF;

      BEGIN
         INSERT INTO at_loc_category
                     (loc_category_code, loc_category_id, db_office_code,
                      loc_category_desc
                     )
              VALUES (cwms_seq.NEXTVAL, l_loc_category_id, l_db_office_code,
                      p_loc_category_desc
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE ('ITEM_ALREADY_EXISTS',
                               'Cannot create the '
                            || l_loc_category_id
                            || ' category as it already exists.'
                           );
      END;

      RETURN l_tmp;
   END;

   PROCEDURE create_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id           VARCHAR2 (16);
      l_db_office_code         NUMBER;
      l_loc_category_code      NUMBER;
      l_loc_group_code         NUMBER;
      l_group_already_exists   BOOLEAN       := FALSE;
      l_loc_category_id        VARCHAR2 (32) := TRIM (p_loc_category_id);
      l_loc_group_id           VARCHAR2 (32) := TRIM (p_loc_group_id);
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      -- Does Category exist?.
      --
      BEGIN
         l_loc_category_code :=
            get_loc_category_code (p_loc_category_id      => p_loc_category_id,
                                   p_db_office_code       => l_db_office_code
                                  );
      EXCEPTION
         WHEN OTHERS
         THEN
            -- need to add new category.
            l_loc_category_code :=
               create_loc_category_f (p_loc_category_id        => l_loc_category_id,
                                      p_loc_category_desc      => NULL,
                                      p_db_office_id           => l_db_office_id
                                     );
      END;

      --
      -- Does Group already exist?.
      BEGIN
         SELECT loc_group_code
           INTO l_loc_group_code
           FROM at_loc_group atlg
          WHERE atlg.loc_category_code = l_loc_category_code
            AND UPPER (atlg.loc_group_id) = UPPER (p_loc_group_id);

         l_group_already_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            INSERT INTO at_loc_group
                        (loc_group_code, loc_category_code,
                         loc_group_id, loc_group_desc
                        )
                 VALUES (cwms_seq.NEXTVAL, l_loc_category_code,
                         p_loc_group_id, p_loc_group_desc
                        );
      END;

      IF l_group_already_exists
      THEN
         cwms_err.RAISE ('ITEM_ALREADY_EXISTS', 'Group id: ', p_loc_group_id);
      END IF;
   END create_loc_group;

   PROCEDURE rename_loc_group (
      p_loc_category_id    IN   VARCHAR2,
      p_loc_group_id_old   IN   VARCHAR2,
      p_loc_group_id_new   IN   VARCHAR2,
      p_loc_group_desc     IN   VARCHAR2 DEFAULT NULL,
      p_ignore_null        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id           VARCHAR2 (16);
      l_db_office_code         NUMBER;
      l_loc_category_code      NUMBER;
      l_loc_group_code         NUMBER;
      l_loc_group_id_old       VARCHAR2 (32) := TRIM (p_loc_group_id_old);
      l_loc_group_id_new       VARCHAR2 (32) := TRIM (p_loc_group_id_new);
      l_group_already_exists   BOOLEAN       := FALSE;
      l_ignore_null            BOOLEAN;
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      IF NVL (p_ignore_null, 'T') = 'T'
      THEN
         l_ignore_null := TRUE;
      ELSE
         l_ignore_null := FALSE;
      END IF;

      -- Does Category exist?.
      --
      BEGIN
         l_loc_category_code :=
                  get_loc_category_code (p_loc_category_id, l_db_office_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE
               ('ITEM_DOES_NOT_EXIST',
                'Category id must exist to rename group id - Category id that does not exist: ',
                p_loc_category_id
               );
      END;

      --
      -- Does NEW Group id already exist?.
      BEGIN
         l_loc_group_code :=
            get_loc_group_code (p_loc_category_id,
                                p_loc_group_id_new,
                                l_db_office_code
                               );
         l_group_already_exists := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_group_already_exists := FALSE;
      END;

      IF l_group_already_exists
      THEN
         IF UPPER (l_loc_group_id_old) != UPPER (l_loc_group_id_new)
         THEN                              -- or there's not a case change...
            cwms_err.RAISE
                   ('ITEM_ALREADY_EXISTS',
                    'p_loc_group_id_new already exists - can''t rename to: ',
                    p_loc_group_id_new
                   );
         END IF;
      END IF;

      --
      -- Does OLD Group id exist?.
      BEGIN
         l_loc_group_code :=
            get_loc_group_code (p_loc_category_id,
                                p_loc_group_id_old,
                                l_db_office_code
                               );
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE
               ('ITEM_DOES_NOT_EXIST',
                'p_loc_group_id_old does not exist - can''t perform rename of: ',
                p_loc_group_id_old
               );
      END;

      --
      -- all checks passed, perform the rename...
      IF p_loc_group_desc IS NULL AND l_ignore_null
      THEN
         UPDATE at_loc_group
            SET loc_group_id = l_loc_group_id_new
          WHERE loc_group_code = l_loc_group_code;
      ELSE
         UPDATE at_loc_group
            SET loc_group_id = l_loc_group_id_new,
                loc_group_desc = TRIM (p_loc_group_desc)
          WHERE loc_group_code = l_loc_group_code;
      END IF;
   --
   --
   END rename_loc_group;

   --
--********************************************************************** -
--********************************************************************** -
--
-- STORE_ALIAS                                                           -
--
--*---------------------------------------------------------------------*-
--
--   PROCEDURE store_alias (
--      p_location_id    IN   VARCHAR2,
--      p_category_id    IN   VARCHAR2,
--      p_group_id       IN   VARCHAR2,
--      p_alias_id       IN   VARCHAR2,
--      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
--   )
--   IS
--      l_loc_category_code   NUMBER;
--      l_loc_group_code      NUMBER;
--      l_location_code       NUMBER;
--      l_db_office_id        VARCHAR2 (16);
--      l_db_office_code      NUMBER;
--      l_tmp                 VARCHAR2 (128);
--   BEGIN
--      IF p_db_office_id IS NULL
--      THEN
--         l_db_office_id := cwms_util.user_office_id;
--      ELSE
--         l_db_office_id := UPPER (p_db_office_id);
--      END IF;

   --      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

   --      BEGIN
--         l_loc_category_code :=
--                      get_loc_category_code (p_category_id, l_db_office_code);
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            cwms_err.RAISE ('GENERIC_ERROR',
--                               'The category id: '
--                            || p_category_id
--                            || ' does not exist.'
--                           );
--      END;

   --      DBMS_OUTPUT.put_line ('gk 1');

   --      BEGIN
--         l_loc_group_code :=
--             get_loc_group_code (p_category_id, p_group_id, l_db_office_code);
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            cwms_err.RAISE ('GENERIC_ERROR',
--                               'There is no group: '
--                            || p_group_id
--                            || ' in the '
--                            || p_category_id
--                            || ' category.'
--                           );
--      END;

   --      DBMS_OUTPUT.put_line ('gk 2');

   --      BEGIN
--         l_location_code := get_location_code (p_db_office_id, p_location_id);
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            cwms_err.RAISE ('GENERIC_ERROR',
--                               'The '
--                            || p_location_id
--                            || ' location id does not exist.'
--                           );
--      END;

   --      DBMS_OUTPUT.put_line ('gk 3');

   --      BEGIN
--         SELECT loc_alias_id
--           INTO l_tmp
--           FROM at_loc_group_assignment
--          WHERE location_code = l_location_code
--            AND loc_group_code = l_loc_group_code;

   --         UPDATE at_loc_group_assignment
--            SET loc_alias_id = trim(p_alias_id)
--          WHERE location_code = l_location_code
--            AND loc_group_code = l_loc_group_code;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            INSERT INTO at_loc_group_assignment
--                        (loc_group_code, location_code, loc_alias_id
--                        )
--                 VALUES (l_loc_group_code, l_location_code, trim(p_alias_id)
--                        );
--      END;

   ----      MERGE INTO at_loc_group_assignment a
----         USING (SELECT loc_group_code, location_code, loc_alias_id
----                  FROM at_loc_group_assignment
----                 WHERE loc_group_code = l_loc_group_code
----                   AND location_code = l_location_code) b
----         ON (    a.loc_group_code = l_loc_group_code
----             AND a.location_code = l_location_code)
----         WHEN MATCHED THEN
----            UPDATE
----               SET a.loc_alias_id = p_alias_id
----         WHEN NOT MATCHED THEN
----            INSERT (loc_group_code, location_code, loc_alias_id)
----            VALUES (cwms_seq.NEXTVAL, l_location_code, p_alias_id);
--   END;

   --
--
-- assign_groups is used to assign one or more location_id's --
-- to a location group.
--
--   loc_alias_type AS OBJECT (
--           location_id             VARCHAR2 (49),
--           loc_alias_id            VARCHAR2 (16),
--           loc_alias_     name     VARCHAR2 (80)
--
   PROCEDURE assign_loc_groups (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_alias_array   IN   loc_alias_array,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code      NUMBER;
      l_loc_category_code   NUMBER;
      l_loc_group_code      NUMBER;
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      BEGIN
         l_loc_category_code :=
                  get_loc_category_code (p_loc_category_id, l_db_office_code);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('GENERIC_ERROR',
                               'The category id: '
                            || p_loc_category_id
                            || ' does not exist.'
                           );
      END;

      BEGIN
         l_loc_group_code :=
            get_loc_group_code (p_loc_category_id,
                                p_loc_group_id,
                                l_db_office_code
                               );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('GENERIC_ERROR',
                               'There is no group: '
                            || p_loc_group_id
                            || ' in the '
                            || p_loc_category_id
                            || ' category.'
                           );
      END;

      MERGE INTO at_loc_group_assignment a
         USING (SELECT get_location_code (l_db_office_id,
                                          plaa.location_id
                                         ) location_code,
                       plaa.loc_alias_id
                  FROM TABLE (p_loc_alias_array) plaa) b
         ON (    a.loc_group_code = l_loc_group_code
             AND a.location_code = b.location_code)
         WHEN MATCHED THEN
            UPDATE
               SET a.loc_alias_id = b.loc_alias_id
         WHEN NOT MATCHED THEN
            INSERT (location_code, loc_group_code, loc_alias_id)
            VALUES (b.location_code, l_loc_group_code, b.loc_alias_id);
   END;

-- creates it and will rename the aliases if they already exist.
   PROCEDURE assign_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_id       IN   VARCHAR2,
      p_loc_alias_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_loc_alias_array   loc_alias_array
          := loc_alias_array (loc_alias_type (p_location_id, p_loc_alias_id));
   BEGIN
      assign_loc_groups (p_loc_category_id      => p_loc_category_id,
                         p_loc_group_id         => p_loc_group_id,
                         p_loc_alias_array      => l_loc_alias_array,
                         p_db_office_id         => p_db_office_id
                        );
   END;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- unassign_loc_groups and
-- unassign_loc_group
--
--These procedures unassign (delete) group/location pairs. The -
--unassign_loc_groups procedure accepts an array of locations so that one or -
--more group/location pairs can be unassigned. The unassign_loc_group procedure -
--only accepts a single group location pair for unassignment.
--
--Both calls allow the possibility to unassign all group/location pairs by -
--setting the p_unassign_all parameter to "T" for TURE. The default value for -
--this parameter is "F" for FALSE.
--
--For the unassign_loc_groups call, the p_location_array uses the CWMS -
--"char_49_array_type" table type, which is an array of table type varchar2(49).

   --Note that you cannot unassign group/location pairs if a group/location pair -
--is being referenced by a SHEF decode entry.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
   PROCEDURE unassign_loc_groups (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_array    IN   char_49_array_type,
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_code   NUMBER := cwms_util.get_office_code (p_db_office_id);
      l_loc_group_code   NUMBER
         := get_loc_group_code (p_loc_category_id      => p_loc_category_id,
                                p_loc_group_id         => p_loc_group_id,
                                p_db_office_code       => l_db_office_code
                               );
      l_tmp              NUMBER;
      l_unassign_all     BOOLEAN := FALSE;
   BEGIN
      IF UPPER (TRIM (p_unassign_all)) = 'T'
      THEN
         l_unassign_all := TRUE;
      END IF;

      BEGIN
         IF l_unassign_all
         THEN                     -- delete all group/location assignments...
            DELETE FROM at_loc_group_assignment
                  WHERE location_code = l_loc_group_code;
         ELSE                  -- delete only group/location assignments for -
                               -- given locations...
            DELETE FROM at_loc_group_assignment
                  WHERE location_code = l_loc_group_code
                    AND location_code IN (
                           SELECT location_code
                             FROM av_loc b,
                                  TABLE
                                     (CAST
                                         (p_location_array AS char_49_array_type
                                         )
                                     ) c
                            WHERE UPPER (b.location_code) =
                                                 UPPER (TRIM (c.COLUMN_VALUE)));
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE
               ('GENERIC_ERROR',
                'Cannot unassign Location/Group pair(s). One or more group assignments are still assigned to SHEF Decoding.'
               );
      END;
   END;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- unassign_loc_group --
-- See description for unassign_loc_groups above.--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
   PROCEDURE unassign_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_id       IN   VARCHAR2,
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_array   char_49_array_type
                                 := char_49_array_type (TRIM (p_location_id));
   BEGIN
      unassign_loc_groups (p_loc_category_id      => p_loc_category_id,
                           p_loc_group_id         => p_loc_group_id,
                           p_location_array       => l_location_array,
                           p_unassign_all         => p_unassign_all,
                           p_db_office_id         => p_db_office_id
                          );
   END;

   -- can only delete if there are no shef decoding references.
   PROCEDURE delete_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      NULL;
   END;

   PROCEDURE delete_loc_cat (
      p_loc_category_id   IN   VARCHAR2,
      p_cascade           IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      NULL;
   END;

   PROCEDURE rename_loc_category (
      p_loc_category_id_old   IN   VARCHAR2,
      p_loc_category_id_new   IN   VARCHAR2,
      p_loc_category_desc     IN   VARCHAR2 DEFAULT NULL,
      p_ignore_null           IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id          IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id              VARCHAR2 (16);
      l_db_office_code            NUMBER;
      l_loc_category_code_old     NUMBER;
      l_loc_category_code_new     NUMBER;
      l_loc_category_id_old       VARCHAR2 (32)
                                              := TRIM (p_loc_category_id_old);
      l_loc_category_id_new       VARCHAR2 (32)
                                              := TRIM (p_loc_category_id_new);
      l_category_already_exists   BOOLEAN       := FALSE;
      l_ignore_null               BOOLEAN;
      l_cat_owned_by_cwms         BOOLEAN;
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      IF NVL (p_ignore_null, 'T') = 'T'
      THEN
         l_ignore_null := TRUE;
      ELSE
         l_ignore_null := FALSE;
      END IF;

      -- Is the p_loc_category_OLD owned by CWMS?...
      ---
      BEGIN
         SELECT loc_category_code
           INTO l_loc_category_code_old
           FROM at_loc_category
          WHERE UPPER (loc_category_id) = UPPER (l_loc_category_id_old)
            AND db_office_code = (SELECT office_code
                                    FROM cwms_office
                                   WHERE office_id = 'CWMS');

         l_cat_owned_by_cwms := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_cat_owned_by_cwms := FALSE;
      END;

      IF l_cat_owned_by_cwms
      THEN
         cwms_err.RAISE
            ('ITEM_ALREADY_EXISTS',
                'The '
             || l_loc_category_id_old
             || ' category is owned by the system. You cannot rename this category.'
            );
      END IF;

      -- Is the p_loc_category_NEW owned by CWMS?...
      ---
      BEGIN
         SELECT loc_category_code
           INTO l_loc_category_code_new
           FROM at_loc_category
          WHERE UPPER (loc_category_id) = UPPER (l_loc_category_id_new)
            AND db_office_code = (SELECT office_code
                                    FROM cwms_office
                                   WHERE office_id = 'CWMS');

         l_cat_owned_by_cwms := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_cat_owned_by_cwms := FALSE;
      END;

      IF l_cat_owned_by_cwms
      THEN
         cwms_err.RAISE
            ('ITEM_ALREADY_EXISTS',
                'The '
             || l_loc_category_id_new
             || ' category is owned by the system. You cannot rename to this category.'
            );
      END IF;

      -- Does Category exist?.
      --
      BEGIN
         l_loc_category_code_old :=
              get_loc_category_code (l_loc_category_id_old, l_db_office_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.RAISE
               ('ITEM_DOES_NOT_EXIST',
                'Category id must exist to rename it - Category id that does not exist: ',
                l_loc_category_id_old
               );
      END;

      --
      -- Does NEW Category id already exist?.
      BEGIN
         l_loc_category_code_new :=
              get_loc_category_code (l_loc_category_id_new, l_db_office_code);
         l_category_already_exists := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_category_already_exists := FALSE;
      END;

      IF l_category_already_exists
      THEN
         IF UPPER (l_loc_category_id_old) != UPPER (l_loc_category_id_new)
         THEN                              -- or there's not a case change...
            cwms_err.RAISE
                ('ITEM_ALREADY_EXISTS',
                 'p_loc_category_id_new already exists - can''t rename to: ',
                 l_loc_category_id_old
                );
         END IF;
      END IF;

      --
      -- all checks passed, perform the rename...
      IF p_loc_category_desc IS NULL AND l_ignore_null
      THEN
         UPDATE at_loc_category
            SET loc_category_id = l_loc_category_id_new
          WHERE loc_category_code = l_loc_category_code_old;
      ELSE
         UPDATE at_loc_category
            SET loc_category_id = l_loc_category_id_new,
                loc_category_desc = TRIM (p_loc_category_desc)
          WHERE loc_category_code = l_loc_category_code_old;
      END IF;
   --
   --
   END rename_loc_category;

--
-- used to assign one or more groups to an existing category.
--
   PROCEDURE assign_loc_grps_cat (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_array   IN   group_array,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code      NUMBER;
      l_loc_category_code   NUMBER;
      l_loc_group_code      NUMBER;
      l_loc_category_id     VARCHAR2 (32)  := TRIM (p_loc_category_id);
      l_loc_group_id        VARCHAR2 (32);
      l_loc_group_desc      VARCHAR2 (128);
      l_tmp                 NUMBER;
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := UPPER (p_db_office_id);
      END IF;

      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      IF l_db_office_code = cwms_util.db_office_code_all
      THEN
         cwms_err.RAISE ('GENERIC_ERROR',
                         'Cannot assign system office groups with this call.'
                        );
      END IF;

      -- get the category_code...
      BEGIN
         l_loc_category_code :=
                  get_loc_category_code (l_loc_category_id, l_db_office_code);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      l_tmp := p_loc_group_array.COUNT;

      IF l_tmp > 0
      THEN
         FOR i IN 1 .. l_tmp
         LOOP
            l_loc_group_id := TRIM (p_loc_group_array (i).GROUP_ID);
            l_loc_group_desc := TRIM (p_loc_group_array (i).group_desc);

            BEGIN
               --
               -- If the group_id already exists, then update -
               -- the group_id and group_desc...
               SELECT loc_group_code
                 INTO l_loc_group_code
                 FROM at_loc_group
                WHERE UPPER (loc_group_id) = UPPER (l_loc_group_id)
                  AND loc_category_code = l_loc_category_code
                  AND db_office_code = l_db_office_code;

               UPDATE at_loc_group
                  SET loc_group_id = l_loc_group_id,
                      loc_group_desc = l_loc_group_desc
                WHERE loc_group_code = l_loc_group_code;

               l_loc_group_code := NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     --
                     -- Check if the group_id is a CWMS owned -
                     -- group_id, if it is, do nothing...
                     SELECT loc_group_code
                       INTO l_loc_group_code
                       FROM at_loc_group
                      WHERE UPPER (loc_group_id) = UPPER (l_loc_group_id)
                        AND loc_category_code = l_loc_category_code
                        AND db_office_code = cwms_util.db_office_code_all;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        --
                        -- Insert a new group_id...
                        INSERT INTO at_loc_group
                                    (loc_group_code, loc_category_code,
                                     loc_group_id, loc_group_desc,
                                     db_office_code
                                    )
                             VALUES (cwms_seq.NEXTVAL, l_loc_category_code,
                                     l_loc_group_id, l_loc_group_desc,
                                     l_db_office_code
                                    );
                  END;
            END;
         END LOOP;
      END IF;
   END;

--
-- used to assign a group to an existing category.
--
   PROCEDURE assign_loc_grp_cat (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_loc_group_array   group_array
         := group_array (group_type (TRIM (p_loc_group_id),
                                     TRIM (p_loc_group_desc)
                                    )
                        );
   BEGIN
      assign_loc_grps_cat (p_loc_category_id,
                           l_loc_group_array,
                           p_db_office_id
                          );
   END;
END cwms_loc;
/