/* Formatted on 2006/11/29 08:57 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE BODY cwms_loc
AS
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
         AND UPPER (office_id) = UPPER (p_office_id);

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
      p_office_id     IN   VARCHAR2,
      p_location_id   IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      l_location_code   NUMBER;
   BEGIN
      SELECT location_code
        INTO l_location_code
        FROM av_loc
       WHERE db_office_id = UPPER (p_office_id)
         AND UPPER (location_id) = UPPER (p_location_id);

      RETURN l_location_code;
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
-- get_county_code return office_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_office_code (p_office_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_office_code   NUMBER;
   BEGIN

      SELECT office_code
        INTO l_office_code
        FROM cwms_office
       WHERE office_id = UPPER (p_office_id);

      RETURN l_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', p_office_id);
      WHEN OTHERS
      THEN
         RAISE;
   END;

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
         l_county_name := 'p_county_name';
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
-- get_county_code returns zone_code
--
------------------------------------------------------------------------------*/
   FUNCTION get_unit_code (unitname IN VARCHAR2, abstractparamname IN VARCHAR2)
      RETURN NUMBER
   IS
      l_unit_code   NUMBER;
   BEGIN
      DBMS_OUTPUT.put_line ('function: get_county_code');

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
            cwms_err.RAISE ('LOCATION_ID_ALREADY_EXISTS',
                            'cwms_loc',
                            p_location_id
                           );
         EXCEPTION
            WHEN OTHERS         -- location_code does not exist so continue...
            THEN
               NULL;
         END;
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
      l_db_office_code           cwms_office.office_code%TYPE;
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
      l_office_id                VARCHAR2 (16)      := UPPER (p_db_office_id);
   BEGIN
      l_db_office_code := get_office_code (l_office_id);

      ---------.
      ---------.
      --.
      --  New location can not already exist...
      BEGIN
         l_location_code_new :=
                           get_location_code (l_office_id, l_location_id_new);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- The get_location_code call should throw an exception becasue --
            -- the new location shouldn't exist.
            l_location_code_new := NULL;
      END;

      IF l_location_code_new IS NOT NULL
      THEN
         -- If l_location_code_new is found then the new location --
         -- already exists - so throw an exception...
         cwms_err.RAISE ('RENAME_LOC_BASE_2', p_location_id_new);
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
          WHERE UPPER (abl.base_location_id) = UPPER (l_base_location_id_old);
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
--
--*---------------------------------------------------------------------*-
   PROCEDURE delete_location (
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
   BEGIN
      SELECT office_code
        INTO l_db_office_code
        FROM cwms_office
       WHERE office_id = UPPER (p_db_office_id);

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
         SELECT COUNT (*)
           INTO l_count
           FROM at_cwms_ts_spec
          WHERE location_code IN (
                               SELECT location_code
                                 FROM at_physical_location
                                WHERE base_location_code =
                                                          l_base_location_code);

         IF l_count = 0
         THEN
            DELETE FROM at_alias_name aan
                  WHERE aan.location_code IN (
                           SELECT location_code
                             FROM at_physical_location apl
                            WHERE apl.base_location_code =
                                                         l_base_location_code);

            DELETE FROM at_physical_location apl
                  WHERE apl.base_location_code = l_base_location_code;

            DELETE FROM at_base_location abl
                  WHERE abl.base_location_code = l_base_location_code;

            COMMIT;
         ELSE
            cwms_err.RAISE ('CAN_NOT_DELETE_LOC_1', p_location_id);
         END IF;
      ELSE                                 -- Deleting a single Sub Location -
         SELECT COUNT (*)
           INTO l_count
           FROM at_cwms_ts_spec
          WHERE location_code = l_location_code;

         IF l_count = 0
         THEN
            DELETE FROM at_alias_name aan
                  WHERE aan.location_code = l_location_code;

            DELETE FROM at_physical_location apl
                  WHERE apl.location_code = l_location_code;

            COMMIT;
         ELSE
            cwms_err.RAISE ('CAN_NOT_DELETE_LOC_1', p_location_id);
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

         DELETE FROM at_alias_name aan
               WHERE aan.location_code IN (
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

         DELETE FROM at_alias_name aan
               WHERE aan.location_code = l_base_location_code;

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
   PROCEDURE store_aliases (
      p_location_id    IN   VARCHAR2,
      p_alias_array    IN   alias_array,
      p_store_rule     IN   VARCHAR2 DEFAULT 'DELETE INSERT',
      p_ignorenulls    IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_agency_code         NUMBER;
      l_office_id           VARCHAR2 (16);
      l_office_code         NUMBER;
      l_location_code       NUMBER;
      l_array_count         NUMBER        := p_alias_array.COUNT;
      l_count               NUMBER        := 1;
      l_distinct            NUMBER;
      l_store_rule          VARCHAR2 (16);
      l_alias_id            VARCHAR2 (16);
      l_alias_public_name   VARCHAR2 (32);
      l_alias_long_name     VARCHAR2 (80);
      l_insert              BOOLEAN;
      l_ignorenulls         BOOLEAN
                            := cwms_util.return_true_or_false (p_ignorenulls);
   BEGIN
      --
      IF l_count = 0
      THEN
         cwms_err.RAISE
                      ('GENERIC_ERROR',
                       'No viable agency/alias data passed to store_aliases.'
                      );
      END IF;

------------------------------------------------------------------
-- Check that passed-in aliases are do not contain duplicates...
------------------------------------------------------------------
      SELECT COUNT (*)
        INTO l_distinct
        FROM (SELECT DISTINCT UPPER (t.agency_id)
                         FROM TABLE (CAST (p_alias_array AS alias_array)) t);

      --
      IF l_distinct != l_array_count
      THEN
         cwms_err.RAISE
            ('GENERIC_ERROR',
             'Duplicate Agency/Alias pairs are not permited. Only one Alias is permited per Agency (store_aliases).'
            );
      END IF;

      --
      -- Make sure none of the alias_id's are null
      --
      SELECT COUNT (*)
        INTO l_distinct
        FROM (SELECT t.alias_id
                FROM TABLE (CAST (p_alias_array AS alias_array)) t
               WHERE alias_id IS NULL);

      --
      IF l_distinct != 0
      THEN
         cwms_err.RAISE
            ('GENERIC_ERROR',
             'A NULL alias_id was submitted. alias_id may not be NULL. (store_aliases).'
            );
      END IF;

      --
      IF p_db_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_db_office_id);
      END IF;

      --
      l_office_code := get_office_code (l_office_id);
      l_location_code := get_location_code (l_office_id, p_location_id);

      --
      IF p_store_rule IS NULL
      THEN
         l_store_rule := cwms_util.delete_all;
      ELSIF UPPER (p_store_rule) = cwms_util.delete_all
      THEN
         l_store_rule := cwms_util.delete_all;
      ELSIF UPPER (p_store_rule) = cwms_util.replace_all
      THEN
         l_store_rule := cwms_util.replace_all;
      ELSE
         cwms_err.RAISE ('GENERIC_ERROR',
                            p_store_rule
                         || ' is an invalid store rule. (store_aliases)'
                        );
      END IF;

      --
      IF l_store_rule = cwms_util.delete_all
      THEN
         DELETE FROM at_alias_name
               WHERE location_code = l_location_code;

         --
         LOOP
            EXIT WHEN l_count > l_array_count;

            --
            BEGIN
               SELECT agency_code
                 INTO l_agency_code
                 FROM at_agency_name
                WHERE UPPER (agency_id) =
                                     UPPER (p_alias_array (l_count).agency_id)
                  AND db_office_code IN
                                (l_office_code, cwms_util.db_office_code_all);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --.
                  INSERT INTO at_agency_name
                              (agency_code,
                               agency_id,
                               agency_name,
                               db_office_code
                              )
                       VALUES (cwms_seq.NEXTVAL,
                               p_alias_array (l_count).agency_id,
                               p_alias_array (l_count).agency_name,
                               l_office_code
                              )
                    RETURNING agency_code
                         INTO l_agency_code;
            END;

            --
            INSERT INTO at_alias_name
                        (location_code, agency_code,
                         alias_id,
                         alias_public_name,
                         alias_long_name
                        )
                 VALUES (l_location_code, l_agency_code,
                         p_alias_array (l_count).alias_id,
                         p_alias_array (l_count).alias_public_name,
                         p_alias_array (l_count).alias_long_name
                        );

            --
            l_count := l_count + 1;
         END LOOP;
      ELSE           -- store_rule is REPLACE ALL                            -
         LOOP
            EXIT WHEN l_count > l_array_count;

            --
            -- retrieve agency_code...
            BEGIN
               SELECT agency_code
                 INTO l_agency_code
                 FROM at_agency_name
                WHERE UPPER (agency_id) =
                                     UPPER (p_alias_array (l_count).agency_id)
                  AND db_office_code IN
                                (l_office_code, cwms_util.db_office_code_all);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN                  -- No agency_code found, so create one...
                  --.
                  INSERT INTO at_agency_name
                              (agency_code,
                               agency_id,
                               agency_name,
                               db_office_code
                              )
                       VALUES (cwms_seq.NEXTVAL,
                               p_alias_array (l_count).agency_id,
                               p_alias_array (l_count).agency_name,
                               l_office_code
                              )
                    RETURNING agency_code
                         INTO l_agency_code;
            END;

            --
            --
            -- retrieve existing alias information...
            l_insert := FALSE;

            BEGIN
               SELECT alias_id, alias_public_name, alias_long_name
                 INTO l_alias_id, l_alias_public_name, l_alias_long_name
                 FROM at_alias_name
                WHERE location_code = l_location_code
                  AND agency_code = l_agency_code;

               --
               IF     p_alias_array (l_count).alias_public_name IS NULL
                  AND NOT l_ignorenulls
               THEN
                  l_alias_public_name := NULL;
               END IF;

               IF     p_alias_array (l_count).alias_long_name IS NULL
                  AND NOT l_ignorenulls
               THEN
                  l_alias_long_name := NULL;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_insert := TRUE;
            END;

            --
            IF l_insert
            THEN
               --
               INSERT INTO at_alias_name
                           (location_code, agency_code,
                            alias_id,
                            alias_public_name,
                            alias_long_name
                           )
                    VALUES (l_location_code, l_agency_code,
                            p_alias_array (l_count).alias_id,
                            p_alias_array (l_count).alias_public_name,
                            p_alias_array (l_count).alias_long_name
                           );
            ELSE
               UPDATE at_alias_name
                  SET alias_id = p_alias_array (l_count).alias_id,
                      alias_public_name = l_alias_public_name,
                      alias_long_name = l_alias_long_name
                WHERE location_code = l_location_code
                  AND agency_code = l_agency_code;
            --
            END IF;

            --
            l_count := l_count + 1;
         END LOOP;
      END IF;

      --
      COMMIT;
--
   END store_aliases;

--
--********************************************************************** -
--********************************************************************** -
--
-- STORE_ALIAS                                                           -
--
--*---------------------------------------------------------------------*-
--
   PROCEDURE store_alias (
      p_location_id         IN   VARCHAR2,
      p_agency_id           IN   VARCHAR2,
      p_alias_id            IN   VARCHAR2,
      p_agency_name         IN   VARCHAR2 DEFAULT NULL,
      p_alias_public_name   IN   VARCHAR2 DEFAULT NULL,
      p_alias_long_name     IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls         IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
   IS
      l_alias_array   alias_array   := alias_array ();
      l_store_rule    VARCHAR2 (16) := 'REPLACE ALL';
   BEGIN
      --
      l_alias_array.EXTEND;
      --
      l_alias_array (1) :=
         alias_type (p_agency_id,
                     p_alias_id,
                     p_agency_name,
                     p_alias_public_name,
                     p_alias_long_name
                    );
      --
      store_aliases (p_location_id,
                     l_alias_array,
                     l_store_rule,
                     p_ignorenulls,
                     p_db_office_id
                    );
   END store_alias;

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
      p_alias_array        IN   alias_array,
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
      store_aliases (p_location_id,
                     p_alias_array,
                     'DELETE INSERT',
                     p_ignorenulls,
                     p_db_office_id
                    );
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
      p_location_id        IN       VARCHAR2,
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
      l_office_id          VARCHAR2 (16);
      l_office_code        NUMBER;
      l_location_code      NUMBER;
      --
      l_alias_cursor       sys_refcursor;
		--
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_db_office_id);
      END IF;

      --
      l_office_code := get_office_code (l_office_id);
      l_location_code := get_location_code (l_office_id, p_location_id);

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
      cwms_cat.cat_loc_aliases (l_alias_cursor,
                                p_location_id,
                                NULL,
                                'F',
                                l_office_id
                               );
      --
		p_alias_cursor := l_alias_cursor;
		--
   --
   END retrieve_location;
END cwms_loc;
/
