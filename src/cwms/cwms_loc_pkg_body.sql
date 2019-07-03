CREATE OR REPLACE PACKAGE BODY cwms_loc
AS
   --
   -- num_group_assigned_to_shef return the number of groups -
   -- currently assigned in the at_shef_decode table.
   FUNCTION znum_group_assigned_to_shef (
      p_group_cat_array   IN group_cat_tab_t,
      p_db_office_code     IN NUMBER
   )
      RETURN NUMBER
   IS
      l_tmp   NUMBER;
   BEGIN
      SELECT   COUNT (*)
        INTO   l_tmp
        FROM   at_shef_decode
       WHERE   loc_group_code IN
                  (SELECT    loc_group_code
                     FROM    (SELECT   a.loc_category_code,
                                      b.loc_group_id
                               FROM   at_loc_category a,
                                      TABLE (
                                         CAST (
                                            p_group_cat_array AS group_cat_tab_t
                                         )
                                      ) b
                              WHERE   UPPER (a.loc_category_id) =
                                         UPPER (TRIM (b.loc_category_id))
                                      AND a.db_office_code IN
                                             (p_db_office_code,
                                              cwms_util.db_office_code_all)) c,
                            at_loc_group d
                    WHERE    UPPER (d.loc_group_id) =
                               UPPER (TRIM (c.loc_group_id))
                            AND d.loc_category_code = c.loc_category_code
                            AND d.db_office_code IN
                                   (p_db_office_code,
                                    cwms_util.db_office_code_all));

      RETURN l_tmp;
   END znum_group_assigned_to_shef;

   FUNCTION num_group_assigned_to_shef (
      p_group_cat_array   IN group_cat_tab_t,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_db_office_code    NUMBER
                            := cwms_util.get_db_office_code (p_db_office_id);
   BEGIN
      RETURN znum_group_assigned_to_shef (p_group_cat_array,
                                          l_db_office_code
                                         );
   END num_group_assigned_to_shef;

   --loc_cat_grp_rec_tab_t IS TABLE OF loc_cat_grp_rec_t

   FUNCTION get_location_id (p_location_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_location_id    VARCHAR2 (57);
   BEGIN
      IF p_location_code IS NOT NULL
      THEN
         SELECT      bl.base_location_id
                  || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                  || pl.sub_location_id
           INTO   l_location_id
           FROM   at_physical_location pl, at_base_location bl
          WHERE   pl.location_code = p_location_code
                  AND bl.base_location_code = pl.base_location_code;
      END IF;

      RETURN l_location_id;
   END get_location_id;

   function get_location_id(
      p_location_id_or_alias varchar2,
      p_office_id            varchar2 default null)
      return varchar2
   is
      l_office_id   varchar2(16);
      l_location_id varchar2(57);
   begin
      l_office_id := nvl(upper(trim(p_office_id)), cwms_util.user_office_id);
      -----------------------------
      -- first try a location id --
      -----------------------------
      begin
         select bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id
           into l_location_id
           from at_physical_location pl,
                at_base_location bl,
                cwms_office o
          where o.office_id = l_office_id
            and bl.db_office_code = o.office_code
            and pl.base_location_code = bl.base_location_code
            and upper(p_location_id_or_alias) = upper(bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id);
      exception
         when no_data_found then
         -------------------------------
         -- next try a location alias --
         -------------------------------
         l_location_id :=  get_location_id_from_alias(
            p_alias_id  => p_location_id_or_alias,
            p_office_id => l_office_id);
         if l_location_id is null then
            -------------------------------
            -- finally try a public name --
            -------------------------------
            begin
               select bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id
                 into l_location_id
                 from at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where o.office_id = l_office_id
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and upper(p_location_id_or_alias) = upper(pl.public_name);
            exception
               when no_data_found then
                  cwms_err.raise('LOCATION_ID_NOT_FOUND', p_location_id_or_alias);
            end;
         end if;
      end;
      return l_location_id;
   end get_location_id;

   FUNCTION get_location_id (p_location_id_or_alias    VARCHAR2,
                             p_office_code             NUMBER
                            )
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      SELECT   office_id
        INTO   l_office_id
        FROM   cwms_office
       WHERE   office_code = p_office_code;

      RETURN get_location_id (p_location_id_or_alias, l_office_id);
   END get_location_id;


   --********************************************************************** -
   --********************************************************************** -
   --********************************************************************** -
   --
   -- get_location_code returns location_code
   --
   ------------------------------------------------------------------------------*/
   FUNCTION get_location_code (p_db_office_id   IN VARCHAR2,
                               p_location_id    IN VARCHAR2,
                               p_check_aliases  IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE
   IS
      l_db_office_code    NUMBER := cwms_util.get_office_code (p_db_office_id);
   BEGIN
      RETURN get_location_code (p_db_office_code   => l_db_office_code,
                                p_location_id      => p_location_id,
                                p_check_aliases    => p_check_aliases
                               );
   END;

   --
   FUNCTION get_location_code (p_db_office_code   IN NUMBER,
                               p_location_id      IN VARCHAR2,
                               p_check_aliases    IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE
   IS
      l_location_code   NUMBER;
   BEGIN
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('ERROR',
                         'The P_LOCATION_ID parameter cannot be NULL'
                        );
      END IF;

      --
      SELECT   apl.location_code
        INTO   l_location_code
        FROM   at_physical_location apl, at_base_location abl
       WHERE   apl.base_location_code = abl.base_location_code
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
         IF cwms_util.is_true(p_check_aliases) THEN
            DECLARE
               l_office_id   VARCHAR2 (16);
            BEGIN
               SELECT   office_id
                 INTO   l_office_id
                 FROM   cwms_office
                WHERE   office_code = p_db_office_code;

               l_location_code :=
                  get_location_code_from_alias (p_alias_id  => p_location_id,
                                                p_office_id => l_office_id
                                               );
               IF l_location_code IS NULL
               THEN
                  cwms_err.raise('LOCATION_ID_NOT_FOUND', p_location_id);
               END IF;

               RETURN l_location_code;
            END;
         ELSE
            RAISE;
         END IF;
      WHEN OTHERS
      THEN
         RAISE;
   END get_location_code;

   FUNCTION get_location_code (p_db_office_code   IN NUMBER,
                               p_location_id      IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE
   IS
   BEGIN
      return get_location_code(p_db_office_code, p_location_id, 'T');
   END get_location_code;

   FUNCTION get_location_code (p_db_office_id   IN VARCHAR2,
                               p_location_id    IN VARCHAR2
                              )
      RETURN NUMBER
      RESULT_CACHE
   IS
   BEGIN
      return get_location_code(p_db_office_id, p_location_id, 'T');
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
      IF p_state_initial IS NULL OR p_state_initial = '0'
      THEN
         RETURN 0;
      END IF;

      SELECT   state_code
        INTO   l_state_code
        FROM   cwms_state
       WHERE   UPPER (state_initial) = UPPER (p_state_initial);

      RETURN l_state_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (
            -20213,
            p_state_initial || ' is an invalid State Abreviation',
            TRUE
         );
      WHEN OTHERS
      THEN
         RAISE;
   END get_state_code;

   --********************************************************************** -
   --********************************************************************** -
   --
   -- get_county_code returns county_code
   --
   ------------------------------------------------------------------------------*/
   FUNCTION get_county_code (p_county_name     IN VARCHAR2 DEFAULT NULL,
                             p_state_initial   IN VARCHAR2 DEFAULT NULL
                            )
      RETURN NUMBER
   IS
      l_county_code      NUMBER;
      l_county_name      VARCHAR2 (40);
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
      IF p_state_initial IS NULL OR p_state_initial = '0'
      THEN
         l_state_initial := '00';
      ELSE
         l_state_initial := p_state_initial;
      END IF;

      --dbms_output.put_line('function: get_county_code_code');
      SELECT   county_code
        INTO   l_county_code
        FROM   cwms_county
       WHERE   UPPER (county_name) = UPPER (l_county_name)
               AND state_code = get_state_code (l_state_initial);

      RETURN l_county_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (
            -20214,
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
   END get_county_code;


   --********************************************************************** -
   --********************************************************************** -
   --
   -- CONVERT_FROM_TO converts a pararameter from one unit to antoher
   --
   ------------------------------------------------------------------------------*/
   FUNCTION convert_from_to (p_orig_value           IN NUMBER,
                             p_from_unit_name       IN VARCHAR2,
                             p_to_unit_name          IN VARCHAR2,
                             p_abstract_paramname    IN VARCHAR2
                            )
      RETURN NUMBER
   IS
      l_return_value   NUMBER;
   BEGIN
      --
      -- retrieve correct unit conversion factor/offset...
      BEGIN
         SELECT   p_orig_value * factor + offset
           INTO   l_return_value
           FROM   cwms_unit_conversion
          WHERE   from_unit_id = cwms_util.get_unit_id(p_from_unit_name)
                  AND to_unit_id = cwms_util.get_unit_id(p_to_unit_name);

         RETURN l_return_value;
      --
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            raise_application_error (
               -20216,
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
   -- get_unit_code
   --
   ------------------------------------------------------------------------------*/
   FUNCTION get_unit_code (unitname            IN VARCHAR2,
                           abstractparamname   IN VARCHAR2
                          )
      RETURN NUMBER
   IS
      l_unit_code   NUMBER;
   BEGIN
      SELECT   unit_code
        INTO   l_unit_code
        FROM   cwms_unit
       WHERE   UPPER (unit_id) = UPPER (cwms_util.get_unit_id(unitname))
               AND abstract_param_code =
                      (SELECT   abstract_param_code
                         FROM   cwms_abstract_parameter
                        WHERE   abstract_param_id = abstractparamname);

      RETURN l_unit_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (
            -20217,
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
   END get_unit_code;

   FUNCTION is_cwms_id_valid (p_base_loc_id IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count    NUMBER := 0;
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
   --.
   --  CREATE_LOCATION_RAW2 -
   --.
   --********************************************************************** -
   --
   PROCEDURE create_location_raw2 (
      p_base_location_code       OUT NUMBER,
      p_location_code            OUT NUMBER,
      p_base_location_id      IN     VARCHAR2,
      p_sub_location_id       IN     VARCHAR2,
      p_db_office_code         IN     NUMBER,
      p_location_type         IN     VARCHAR2 DEFAULT NULL,
      p_elevation             IN     NUMBER DEFAULT NULL,
      p_vertical_datum         IN     VARCHAR2 DEFAULT NULL,
      p_latitude               IN     NUMBER DEFAULT NULL,
      p_longitude             IN     NUMBER DEFAULT NULL,
      p_horizontal_datum      IN     VARCHAR2 DEFAULT NULL,
      p_public_name            IN     VARCHAR2 DEFAULT NULL,
      p_long_name             IN     VARCHAR2 DEFAULT NULL,
      p_description            IN     VARCHAR2 DEFAULT NULL,
      p_time_zone_code         IN     NUMBER DEFAULT NULL,
      p_county_code            IN     NUMBER DEFAULT NULL,
      p_active_flag            IN     VARCHAR2 DEFAULT 'T',
      p_location_kind_id      IN     VARCHAR2 DEFAULT NULL,
      p_map_label             IN     VARCHAR2 DEFAULT NULL,
      p_published_latitude    IN     NUMBER DEFAULT NULL,
      p_published_longitude   IN     NUMBER DEFAULT NULL,
      p_bounding_office_id    IN     VARCHAR2 DEFAULT NULL,
      p_nation_id             IN     VARCHAR2 DEFAULT NULL,
      p_nearest_city          IN     VARCHAR2 DEFAULT NULL,
      p_db_office_id          IN     VARCHAR2 DEFAULT NULL
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      l_hashcode                NUMBER;
      l_ret                    NUMBER;
      l_base_loc_exists        BOOLEAN := TRUE;
      l_sub_loc_exists          BOOLEAN := TRUE;
      l_nation_id              VARCHAR2 (48) := NVL (p_nation_id, 'UNITED STATES');
      l_bounding_office_id     VARCHAR2 (16);
      l_location_kind_code     NUMBER := 1; -- SITE
      l_bounding_office_code    NUMBER := NULL;
      l_nation_code             VARCHAR2 (2);
      l_cwms_office_code       NUMBER (10)
                                  := cwms_util.get_office_code ('CWMS');
   BEGIN
      IF p_bounding_office_id IS NOT NULL
      THEN
         BEGIN
            SELECT   office_code
              INTO   l_bounding_office_code
              FROM   cwms_office
             WHERE   office_id = UPPER (p_bounding_office_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               p_bounding_office_id,
                               'office id'
                              );
         END;
      END IF;

      BEGIN
         SELECT   nation_code
           INTO   l_nation_code
           FROM   cwms_nation
          WHERE   nation_id = UPPER (l_nation_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('INVALID_ITEM', l_nation_id, 'nation id');
      END;

      BEGIN
         -- Check if base_location exists -
         SELECT   base_location_code
           INTO   p_base_location_code
           FROM   at_base_location abl
          WHERE   UPPER (abl.base_location_id) = UPPER (p_base_location_id)
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
               SELECT   location_code
                 INTO   p_location_code
                 FROM   at_physical_location apl
                WHERE   apl.base_location_code = p_base_location_code
                        AND apl.sub_location_id IS NULL;
            ELSE
               SELECT   location_code
                 INTO   p_location_code
                 FROM   at_physical_location apl
                WHERE   apl.base_location_code = p_base_location_code
                        AND UPPER (apl.sub_location_id) =
                               UPPER (p_sub_location_id);
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
            DBMS_UTILITY.get_hash_value (
                  p_db_office_code
               || UPPER (p_base_location_id)
               || UPPER (p_sub_location_id),
               0,
               1073741823
            );
         l_ret :=
            DBMS_LOCK.request (id                  => l_hashcode,
                               timeout             => 0,
                               lockmode            => 5,
                               release_on_commit   => TRUE
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
               INSERT
                    INTO   at_base_location (base_location_code,
                                             db_office_code,
                                             base_location_id,
                                             active_flag
                                            )
                  VALUES   (
                              cwms_seq.NEXTVAL,
                              p_db_office_code,
                              p_base_location_id,
                              p_active_flag
                           )
               RETURNING   base_location_code
                    INTO   p_base_location_code;

               --
               --.Insert new Base Location into at_physical_location -
               INSERT
                 INTO   at_physical_location (location_code,
                                              base_location_code,
                                              time_zone_code,
                                              county_code,
                                              location_type,
                                              elevation,
                                              vertical_datum,
                                              longitude,
                                              latitude,
                                              horizontal_datum,
                                              public_name,
                                              long_name,
                                              description,
                                              active_flag,
                                              location_kind,
                                              map_label,
                                              published_latitude,
                                              published_longitude,
                                              office_code,
                                              nation_code,
                                              nearest_city
                                             )
               VALUES   (
                           p_base_location_code,
                           p_base_location_code,
                           p_time_zone_code,
                           p_county_code,
                           p_location_type,
                           p_elevation,
                           p_vertical_datum,
                           p_longitude,
                           p_latitude,
                           p_horizontal_datum,
                           p_public_name,
                           p_long_name,
                           p_description,
                           p_active_flag,
                           l_location_kind_code,
                           p_map_label,
                           p_published_latitude,
                           p_published_longitude,
                           l_bounding_office_code,
                           l_nation_code,
                           p_nearest_city
                        );

               p_location_code := p_base_location_code;
            END IF;

            ---------.
            ---------.
            -- Create new (Sub) Location (if necessary)...
            --.
            IF p_sub_location_id IS NOT NULL
            THEN
               INSERT
                    INTO   at_physical_location (location_code,
                                                 base_location_code,
                                                 sub_location_id,
                                                 time_zone_code,
                                                 county_code,
                                                 location_type,
                                                 elevation,
                                                 vertical_datum,
                                                 longitude,
                                                 latitude,
                                                 horizontal_datum,
                                                 public_name,
                                                 long_name,
                                                 description,
                                                 active_flag,
                                                 location_kind,
                                                 map_label,
                                                 published_latitude,
                                                 published_longitude,
                                                 office_code,
                                                 nation_code,
                                                 nearest_city
                                                )
                  VALUES   (
                              cwms_seq.NEXTVAL,
                              p_base_location_code,
                              p_sub_location_id,
                              p_time_zone_code,
                              p_county_code,
                              p_location_type,
                              p_elevation,
                              p_vertical_datum,
                              p_longitude,
                              p_latitude,
                              p_horizontal_datum,
                              p_public_name,
                              p_long_name,
                              p_description,
                              p_active_flag,
                              l_location_kind_code,
                              p_map_label,
                              p_published_latitude,
                              p_published_longitude,
                              l_bounding_office_code,
                              l_nation_code,
                              p_nearest_city
                           )
               RETURNING   location_code
                    INTO   p_location_code;
            END IF;
         END IF;
      END IF;

      --
      COMMIT;                                   -- needed to release dbms_lock.
   --
   END create_location_raw2;

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
      p_base_location_code      OUT NUMBER,
      p_location_code           OUT NUMBER,
      p_base_location_id     IN      VARCHAR2,
      p_sub_location_id      IN      VARCHAR2,
      p_db_office_code        IN      NUMBER,
      p_location_type        IN      VARCHAR2 DEFAULT NULL,
      p_elevation            IN      NUMBER DEFAULT NULL,
      p_vertical_datum        IN      VARCHAR2 DEFAULT NULL,
      p_latitude              IN      NUMBER DEFAULT NULL,
      p_longitude            IN      NUMBER DEFAULT NULL,
      p_horizontal_datum     IN      VARCHAR2 DEFAULT NULL,
      p_public_name           IN      VARCHAR2 DEFAULT NULL,
      p_long_name            IN      VARCHAR2 DEFAULT NULL,
      p_description           IN      VARCHAR2 DEFAULT NULL,
      p_time_zone_code        IN      NUMBER DEFAULT NULL,
      p_county_code           IN      NUMBER DEFAULT NULL,
      p_active_flag           IN      VARCHAR2 DEFAULT 'T'
   )
   IS
   BEGIN
      create_location_raw2 (p_base_location_code,
                            p_location_code,
                            p_base_location_id,
                            p_sub_location_id,
                            p_db_office_code,
                            p_location_type,
                            p_elevation,
                            p_vertical_datum,
                            p_latitude,
                            p_longitude,
                            p_horizontal_datum,
                            p_public_name,
                            p_long_name,
                            p_description,
                            p_time_zone_code,
                            p_county_code,
                            p_active_flag
                           );
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
      p_office_id        IN VARCHAR2,
      p_base_loc_id       IN VARCHAR2,
      p_location_type    IN VARCHAR2 DEFAULT NULL,
      p_elevation        IN NUMBER DEFAULT NULL,
      p_elev_unit_id     IN VARCHAR2 DEFAULT NULL,
      p_vertical_datum    IN VARCHAR2 DEFAULT NULL,
      p_latitude          IN NUMBER DEFAULT NULL,
      p_longitude        IN NUMBER DEFAULT NULL,
      p_public_name       IN VARCHAR2 DEFAULT NULL,
      p_description       IN VARCHAR2 DEFAULT NULL,
      p_timezone_id       IN VARCHAR2 DEFAULT NULL,
      p_county_name       IN VARCHAR2 DEFAULT NULL,
      p_state_initial    IN VARCHAR2 DEFAULT NULL,
      p_ignorenulls       IN NUMBER DEFAULT cwms_util.true_num
   )
   --^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   --- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
   ---
   --
   IS
      l_horizontal_datum   VARCHAR2 (16) := NULL;
      l_long_name          VARCHAR2 (80) := NULL;
      l_active             VARCHAR2 (1) := NULL;
      l_ignorenulls         VARCHAR2 (1) := 'T';
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


   PROCEDURE update_location2 (
      p_location_id           IN VARCHAR2,
      p_location_type         IN VARCHAR2 DEFAULT NULL,
      p_elevation             IN NUMBER DEFAULT NULL,
      p_elev_unit_id          IN VARCHAR2 DEFAULT NULL,
      p_vertical_datum        IN VARCHAR2 DEFAULT NULL,
      p_latitude              IN NUMBER DEFAULT NULL,
      p_longitude             IN NUMBER DEFAULT NULL,
      p_horizontal_datum      IN VARCHAR2 DEFAULT NULL,
      p_public_name           IN VARCHAR2 DEFAULT NULL,
      p_long_name             IN VARCHAR2 DEFAULT NULL,
      p_description           IN VARCHAR2 DEFAULT NULL,
      p_time_zone_id          IN VARCHAR2 DEFAULT NULL,
      p_county_name           IN VARCHAR2 DEFAULT NULL,
      p_state_initial         IN VARCHAR2 DEFAULT NULL,
      p_active                IN VARCHAR2 DEFAULT NULL,
      p_location_kind_id      IN VARCHAR2 DEFAULT NULL,
      p_map_label             IN VARCHAR2 DEFAULT NULL,
      p_published_latitude    IN NUMBER DEFAULT NULL,
      p_published_longitude   IN NUMBER DEFAULT NULL,
      p_bounding_office_id    IN VARCHAR2 DEFAULT NULL,
      p_nation_id             IN VARCHAR2 DEFAULT NULL,
      p_nearest_city          IN VARCHAR2 DEFAULT NULL,
      p_ignorenulls           IN VARCHAR2 DEFAULT 'T',
      p_db_office_id          IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_code          at_physical_location.location_code%TYPE;
      l_base_location_code     at_physical_location.base_location_code%TYPE;
      l_time_zone_code         at_physical_location.time_zone_code%TYPE;
      l_county_code            cwms_county.county_code%TYPE;
      l_location_type          at_physical_location.location_type%TYPE;
      l_elevation              at_physical_location.elevation%TYPE;
      l_vertical_datum         at_physical_location.vertical_datum%TYPE;
      l_longitude              at_physical_location.longitude%TYPE;
      l_latitude               at_physical_location.latitude%TYPE;
      l_horizontal_datum       at_physical_location.horizontal_datum%TYPE;
      l_state_code             cwms_state.state_code%TYPE;
      l_public_name            at_physical_location.public_name%TYPE;
      l_long_name              at_physical_location.long_name%TYPE;
      l_description            at_physical_location.description%TYPE;
      l_active_flag            at_physical_location.active_flag%TYPE;
      l_location_kind_code     at_physical_location.location_kind%TYPE;
      l_map_label              at_physical_location.map_label%TYPE;
      l_published_latitude     at_physical_location.published_latitude%TYPE;
      l_published_longitude    at_physical_location.published_longitude%TYPE;
      l_bounding_office_code   at_physical_location.office_code%TYPE;
      l_nation_code            at_physical_location.nation_code%TYPE;
      l_nearest_city           at_physical_location.nearest_city%TYPE;
      --
      l_state_initial          cwms_state.state_initial%TYPE;
      l_county_name             cwms_county.county_name%TYPE;
      l_ignorenulls             BOOLEAN := cwms_util.is_true (p_ignorenulls);
      l_office_code             NUMBER (10)
         := cwms_util.get_office_code (p_db_office_id);
      l_cwms_office_code       NUMBER (10)
                                  := cwms_util.get_office_code ('CWMS');
      l_old_time_zone_code      number(10);
   BEGIN
      --.
      -- dbms_output.put_line('Bienvenue a update_loc');

      -- Retrieve the location's Location Code.
      --
      l_location_code := get_location_code (p_db_office_id, p_location_id);
      -- DBMS_OUTPUT.put_line ('l_location_code: ' || l_location_code);

      --
      --  If get_location_code did not throw an exception, then a valid base_location_id &.
      --  office_id pair was passed in, therefore continue to update the.
      --  at_physical_location table by first retrieving data for the existing location...
      --
      SELECT   base_location_code, location_type, elevation, vertical_datum, latitude, longitude,
               horizontal_datum, public_name, long_name, description,
               time_zone_code, county_code, active_flag, location_kind,
               map_label, published_latitude, published_longitude,
               office_code, nation_code, nearest_city
        INTO   l_base_location_code, l_location_type, l_elevation, l_vertical_datum, l_latitude,
               l_longitude, l_horizontal_datum, l_public_name, l_long_name,
               l_description, l_time_zone_code, l_county_code, l_active_flag,
               l_location_kind_code, l_map_label, l_published_latitude,
               l_published_longitude, l_bounding_office_code, l_nation_code,
               l_nearest_city
        FROM   at_physical_location
       WHERE   location_code = l_location_code;

      -- DBMS_OUTPUT.put_line ('l_elevation: ' || l_elevation);

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
            raise_application_error (
               -20219,
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
            raise_application_error (
               -20218,
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
         l_time_zone_code := cwms_util.get_time_zone_code (p_time_zone_id);
         select time_zone_code
           into l_old_time_zone_code
           from at_physical_location
          where location_code = l_location_code;
         if l_time_zone_code = l_old_time_zone_code then
            null;
         else
            declare
               l_tmp          integer;
            begin
               for rec in (select tss.ts_code,
                                  -tss.interval_utc_offset as interval_utc_offset,
                                  ci.interval,
                                  tsi.cwms_ts_id
                             from at_cwms_ts_spec tss,
                                  at_cwms_ts_id   tsi,
                                  cwms_interval   ci
                            where tss.location_code = l_location_code
                              and tsi.ts_code = tss.ts_code
                              and tss.interval_utc_offset < 0
                              and tss.interval_utc_offset != cwms_util.utc_offset_irregular
                              and ci.interval_id = substr(tsi.interval_id, 2)
                          )
               loop
                  select count(*)
                    into l_tmp
                    from (select local_time,
                                 cwms_ts.get_time_on_before_interval(
                                    local_time,
                                    rec.interval_utc_offset,
                                    rec.interval) as interval_time
                            from (select cwms_util.change_timezone(date_time, 'UTC', p_time_zone_id) as local_time
                                    from av_tsv where ts_code = rec.ts_code
                                 )
                         )
                   where local_time != interval_time;
                  if l_tmp > 0 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot change time zone.  Time series is incompatible with new time zone: '||rec.cwms_ts_id);
                  end if;
               end loop;
            end;
         end if;
      ELSIF NOT l_ignorenulls
      THEN
         l_time_zone_code := NULL;
      END IF;

      ---------.
      ---------.
      -- Check and Update he State/County pair...
      --
      IF p_state_initial IS NULL AND p_county_name IS NOT NULL
      THEN         -- Throw exception - if a county name is passed in one must.
         -- also pass-in the county's state initials.
         cwms_err.raise ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
      ELSIF p_state_initial IS NOT NULL
      THEN                               -- Find the corresponding county_code.
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
            cwms_err.raise ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
         END IF;
      END IF;

      -------------------
      -- location kind --  NOT UPDATED
      -------------------

      ---------------
      -- map label --
      ---------------
      IF p_map_label IS NOT NULL
      THEN
         l_map_label := p_map_label;
      ELSIF NOT l_ignorenulls
      THEN
         l_map_label := NULL;
      END IF;

      ------------------------
      -- published latitude --
      ------------------------
      IF p_published_latitude IS NOT NULL
      THEN
         l_published_latitude := p_published_latitude;
      ELSIF NOT l_ignorenulls
      THEN
         l_published_latitude := NULL;
      END IF;

      -------------------------
      -- published longitude --
      -------------------------
      IF p_published_longitude IS NOT NULL
      THEN
         l_published_longitude := p_published_longitude;
      ELSIF NOT l_ignorenulls
      THEN
         l_published_longitude := NULL;
      END IF;

      -----------------
      -- office code --
      -----------------
      IF p_bounding_office_id IS NOT NULL
      THEN
         BEGIN
            SELECT   office_code
              INTO   l_bounding_office_code
              FROM   cwms_office
             WHERE   office_id = UPPER (p_bounding_office_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               p_bounding_office_id,
                               'office id'
                              );
         END;
      ELSIF NOT l_ignorenulls
      THEN
         l_bounding_office_code := NULL;
      END IF;

      -----------------
      -- nation code --
      -----------------
      IF p_nation_id IS NOT NULL
      THEN
         BEGIN
            SELECT   nation_code
              INTO   l_nation_code
              FROM   cwms_nation
             WHERE   nation_id = UPPER (p_nation_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM', p_nation_id, 'nation id');
         END;
      ELSIF NOT l_ignorenulls
      THEN
         l_nation_code := NULL;
      END IF;

      ------------------
      -- nearest city --
      ------------------
      IF p_nearest_city IS NOT NULL
      THEN
         l_nearest_city := p_nearest_city;
      ELSIF NOT l_ignorenulls
      THEN
         l_nearest_city := NULL;
      END IF;


      ---------------------------------------
      -- update at_physical_location table --
      ---------------------------------------
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
             active_flag = l_active_flag,
             location_kind = l_location_kind_code,
             map_label = l_map_label,
             published_latitude = l_published_latitude,
             published_longitude = l_published_longitude,
             office_code = l_bounding_office_code,
             nation_code = l_nation_code,
             nearest_city = l_nearest_city
       WHERE location_code = l_location_code;
       if l_base_location_code = l_location_code and p_active is not null then
          -----------------------------------
          -- update at_base_location table --
          -----------------------------------
          update at_base_location
             set active_flag = l_active_flag
           where base_location_code = l_base_location_code;
       end if;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         RAISE;
   END update_location2;


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
   PROCEDURE update_location (p_location_id         IN VARCHAR2,
                              p_location_type      IN VARCHAR2 DEFAULT NULL,
                              p_elevation          IN NUMBER DEFAULT NULL,
                              p_elev_unit_id       IN VARCHAR2 DEFAULT NULL,
                              p_vertical_datum      IN VARCHAR2 DEFAULT NULL,
                              p_latitude            IN NUMBER DEFAULT NULL,
                              p_longitude          IN NUMBER DEFAULT NULL,
                              p_horizontal_datum   IN VARCHAR2 DEFAULT NULL,
                              p_public_name         IN VARCHAR2 DEFAULT NULL,
                              p_long_name          IN VARCHAR2 DEFAULT NULL,
                              p_description         IN VARCHAR2 DEFAULT NULL,
                              p_time_zone_id       IN VARCHAR2 DEFAULT NULL,
                              p_county_name         IN VARCHAR2 DEFAULT NULL,
                              p_state_initial      IN VARCHAR2 DEFAULT NULL,
                              p_active             IN VARCHAR2 DEFAULT NULL,
                              p_ignorenulls         IN VARCHAR2 DEFAULT 'T',
                              p_db_office_id       IN VARCHAR2 DEFAULT NULL
                             )
   IS
      l_location_code      at_physical_location.location_code%TYPE;
      l_time_zone_code      at_physical_location.time_zone_code%TYPE;
      l_county_code         cwms_county.county_code%TYPE;
      l_location_type      at_physical_location.location_type%TYPE;
      l_elevation          at_physical_location.elevation%TYPE;
      l_vertical_datum      at_physical_location.vertical_datum%TYPE;
      l_longitude          at_physical_location.longitude%TYPE;
      l_latitude            at_physical_location.latitude%TYPE;
      l_horizontal_datum   at_physical_location.horizontal_datum%TYPE;
      l_state_code         cwms_state.state_code%TYPE;
      l_public_name         at_physical_location.public_name%TYPE;
      l_long_name          at_physical_location.long_name%TYPE;
      l_description         at_physical_location.description%TYPE;
      l_active_flag         at_physical_location.active_flag%TYPE;
      --
      l_state_initial      cwms_state.state_initial%TYPE;
      l_county_name         cwms_county.county_name%TYPE;
      l_ignorenulls         BOOLEAN := cwms_util.is_true (p_ignorenulls);
      l_old_time_zone_code      number(10);
   BEGIN
      --.
      -- dbms_output.put_line('Bienvenue a update_loc');

      -- Retrieve the location's Location Code.
      --
      l_location_code := get_location_code (p_db_office_id, p_location_id);
      -- DBMS_OUTPUT.put_line ('l_location_code: ' || l_location_code);

      --
      --  If get_location_code did not throw an exception, then a valid base_location_id &.
      --  office_id pair was passed in, therefore continue to update the.
      --  at_physical_location table by first retrieving data for the existing location...
      --
      SELECT   location_type, elevation, vertical_datum, latitude, longitude,
               horizontal_datum, public_name, long_name, description,
               time_zone_code, county_code, active_flag
        INTO   l_location_type, l_elevation, l_vertical_datum, l_latitude,
               l_longitude, l_horizontal_datum, l_public_name, l_long_name,
               l_description, l_time_zone_code, l_county_code, l_active_flag
        FROM   at_physical_location
       WHERE   location_code = l_location_code;

      -- DBMS_OUTPUT.put_line ('l_elevation: ' || l_elevation);

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
            raise_application_error (
               -20219,
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
            raise_application_error (
               -20218,
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
         l_time_zone_code := cwms_util.get_time_zone_code (p_time_zone_id);
         select time_zone_code
           into l_old_time_zone_code
           from at_physical_location
          where location_code = l_location_code;
         if l_time_zone_code = l_old_time_zone_code then
            null;
         else
            declare
               l_tmp          integer;
            begin
               for rec in (select tss.ts_code,
                                  -tss.interval_utc_offset as interval_utc_offset,
                                  ci.interval,
                                  tsi.cwms_ts_id
                             from at_cwms_ts_spec tss,
                                  at_cwms_ts_id   tsi,
                                  cwms_interval   ci
                            where tss.location_code = l_location_code
                              and tsi.ts_code = tss.ts_code
                              and tss.interval_utc_offset < 0
                              and tss.interval_utc_offset != cwms_util.utc_offset_irregular
                              and ci.interval_id = substr(tsi.interval_id, 2)
                          )
               loop
                  select count(*)
                    into l_tmp
                    from (select local_time,
                                 cwms_ts.get_time_on_before_interval(
                                    local_time,
                                    rec.interval_utc_offset,
                                    rec.interval) as interval_time
                            from (select cwms_util.change_timezone(date_time, 'UTC', p_time_zone_id) as local_time
                                    from av_tsv where ts_code = rec.ts_code
                                 )
                         )
                   where local_time != interval_time;
                  if l_tmp > 0 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot change time zone.  Time series is incompatible with new time zone: '||rec.cwms_ts_id);
                  end if;
               end loop;
            end;
         end if;
      ELSIF NOT l_ignorenulls
      THEN
         l_time_zone_code := NULL;
      END IF;

      ---------.
      ---------.
      -- Check and Update he State/County pair...
      --
      IF p_state_initial IS NULL AND p_county_name IS NOT NULL
      THEN         -- Throw exception - if a county name is passed in one must.
         -- also pass-in the county's state initials.
         cwms_err.raise ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
      ELSIF p_state_initial IS NOT NULL
      THEN                               -- Find the corresponding county_code.
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
            cwms_err.raise ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
         END IF;
      END IF;

      --.
      --*************************************.
      -- Update at_physical_location table...
      --.
      UPDATE   at_physical_location
         SET   location_type = l_location_type,
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
       WHERE   location_code = l_location_code;
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
   PROCEDURE insert_loc (p_office_id        IN VARCHAR2,
                         p_base_loc_id      IN VARCHAR2,
                         p_state_initial     IN VARCHAR2 DEFAULT NULL,
                         p_county_name      IN VARCHAR2 DEFAULT NULL,
                         p_timezone_name     IN VARCHAR2 DEFAULT NULL,
                         p_location_type     IN VARCHAR2 DEFAULT NULL,
                         p_latitude         IN NUMBER DEFAULT NULL,
                         p_longitude        IN NUMBER DEFAULT NULL,
                         p_elevation        IN NUMBER DEFAULT NULL,
                         p_elev_unit_id     IN VARCHAR2 DEFAULT NULL,
                         p_vertical_datum   IN VARCHAR2 DEFAULT NULL,
                         p_public_name      IN VARCHAR2 DEFAULT NULL,
                         p_long_name        IN VARCHAR2 DEFAULT NULL,
                         p_description      IN VARCHAR2 DEFAULT NULL
                        )
   --^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   --- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
   ---
   --
   IS
      l_horizontal_datum   VARCHAR2 (16) := NULL;
      l_active             VARCHAR2 (1) := 'T';
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
   --.
   --  CREATE_LOCATION2 -
   --.
   --********************************************************************** -
   --
   PROCEDURE create_location2 (
      p_location_id            IN VARCHAR2,
      p_location_type         IN VARCHAR2 DEFAULT NULL,
      p_elevation             IN NUMBER DEFAULT NULL,
      p_elev_unit_id          IN VARCHAR2 DEFAULT NULL,
      p_vertical_datum         IN VARCHAR2 DEFAULT NULL,
      p_latitude               IN NUMBER DEFAULT NULL,
      p_longitude             IN NUMBER DEFAULT NULL,
      p_horizontal_datum      IN VARCHAR2 DEFAULT NULL,
      p_public_name            IN VARCHAR2 DEFAULT NULL,
      p_long_name             IN VARCHAR2 DEFAULT NULL,
      p_description            IN VARCHAR2 DEFAULT NULL,
      p_time_zone_id          IN VARCHAR2 DEFAULT NULL,
      p_county_name            IN VARCHAR2 DEFAULT NULL,
      p_state_initial         IN VARCHAR2 DEFAULT NULL,
      p_active                IN VARCHAR2 DEFAULT NULL,
      p_location_kind_id      IN VARCHAR2 DEFAULT NULL,
      p_map_label             IN VARCHAR2 DEFAULT NULL,
      p_published_latitude    IN NUMBER DEFAULT NULL,
      p_published_longitude   IN NUMBER DEFAULT NULL,
      p_bounding_office_id    IN VARCHAR2 DEFAULT NULL,
      p_nation_id             IN VARCHAR2 DEFAULT NULL,
      p_nearest_city          IN VARCHAR2 DEFAULT NULL,
      p_db_office_id          IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_base_location_id     at_base_location.base_location_id%TYPE
                                := cwms_util.get_base_id (p_location_id);
      --
      l_sub_location_id      at_physical_location.sub_location_id%TYPE
                                := cwms_util.get_sub_id (p_location_id);
      --
      l_db_office_id         cwms_office.office_id%TYPE;
      l_db_office_code        cwms_office.office_code%TYPE;
      l_base_location_code   at_base_location.base_location_code%TYPE;
      l_location_code        at_physical_location.location_code%TYPE;
      l_base_loc_exists      BOOLEAN;
      l_loc_exists           BOOLEAN := FALSE;
      --
      l_location_type        at_physical_location.location_type%TYPE;
      l_elevation            at_physical_location.elevation%TYPE := NULL;
      l_vertical_datum        at_physical_location.vertical_datum%TYPE;
      l_latitude              at_physical_location.latitude%TYPE := NULL;
      l_longitude            at_physical_location.longitude%TYPE := NULL;
      l_horizontal_datum     at_physical_location.horizontal_datum%TYPE;
      l_public_name           at_physical_location.public_name%TYPE;
      l_long_name            at_physical_location.long_name%TYPE;
      l_description           at_physical_location.description%TYPE;
      l_time_zone_code        at_physical_location.time_zone_code%TYPE := NULL;
      l_county_code           cwms_county.county_code%TYPE := NULL;
      l_active_flag           at_physical_location.active_flag%TYPE;
      --
      l_ret                  NUMBER;
      l_hashcode              NUMBER;
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

      DBMS_APPLICATION_INFO.set_module ('create_location2', 'get office code');
      --------------------------------------------------------
      -- Get the office_code...
      --------------------------------------------------------
      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      --.
      -- Check if a Base Location already exists for this p_location_id...
      BEGIN
         SELECT   base_location_code, base_location_id
           INTO   l_base_location_code, l_base_location_id
           FROM   at_base_location abl
          WHERE   UPPER (abl.base_location_id) = l_base_location_id
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
         cwms_err.raise ('LOCATION_ID_ALREADY_EXISTS',
                         'cwms_loc',
                         l_db_office_id || ':' || p_location_id
                        );
      END IF;

      check_alias_id(p_location_id, p_location_id, null, null, l_db_office_id);

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
            raise_application_error (
               -20219,
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
            raise_application_error (
               -20218,
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
         l_time_zone_code := cwms_util.get_time_zone_code (p_time_zone_id);
      END IF;

      ---------.
      ---------.
      -- Check and Update he State/County pair...
      --
      IF p_state_initial IS NULL AND p_county_name IS NOT NULL
      THEN         -- Throw exception - if a county name is passed in one must.
         -- also pass-in the county's state initials.
         cwms_err.raise ('STATE_CANNOT_BE_NULL', 'CWMS_LOC');
      ELSIF p_state_initial IS NOT NULL
      THEN                               -- Find the corresponding county_code.
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
            cwms_err.raise ('INVALID_T_F_FLAG', 'cwms_loc', 'p_active');
         END IF;
      ELSE
         l_active_flag := 'T';
      END IF;

      ---------.
      ---------.
      -- Create new base and sub locations in database...
      --.
      --.
      create_location_raw2 (l_base_location_code,
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
                            l_active_flag,
                            p_location_kind_id,
                            p_map_label,
                            p_published_latitude,
                            p_published_longitude,
                            p_bounding_office_id,
                            p_nation_id,
                            p_nearest_city,
                            p_db_office_id
                           );
   --
   END create_location2;

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

   PROCEDURE create_location (p_location_id         IN VARCHAR2,
                              p_location_type      IN VARCHAR2 DEFAULT NULL,
                              p_elevation          IN NUMBER DEFAULT NULL,
                              p_elev_unit_id       IN VARCHAR2 DEFAULT NULL,
                              p_vertical_datum      IN VARCHAR2 DEFAULT NULL,
                              p_latitude            IN NUMBER DEFAULT NULL,
                              p_longitude          IN NUMBER DEFAULT NULL,
                              p_horizontal_datum   IN VARCHAR2 DEFAULT NULL,
                              p_public_name         IN VARCHAR2 DEFAULT NULL,
                              p_long_name          IN VARCHAR2 DEFAULT NULL,
                              p_description         IN VARCHAR2 DEFAULT NULL,
                              p_time_zone_id       IN VARCHAR2 DEFAULT NULL,
                              p_county_name         IN VARCHAR2 DEFAULT NULL,
                              p_state_initial      IN VARCHAR2 DEFAULT NULL,
                              p_active             IN VARCHAR2 DEFAULT NULL,
                              p_db_office_id       IN VARCHAR2 DEFAULT NULL
                             )
   IS
   BEGIN
      create_location2 (p_location_id            => p_location_id,
                        p_location_type         => p_location_type,
                        p_elevation             => p_elevation,
                        p_elev_unit_id          => p_elev_unit_id,
                        p_vertical_datum         => p_vertical_datum,
                        p_latitude               => p_latitude,
                        p_longitude             => p_longitude,
                        p_horizontal_datum      => p_horizontal_datum,
                        p_public_name            => p_public_name,
                        p_long_name             => p_long_name,
                        p_description            => p_description,
                        p_time_zone_id          => p_time_zone_id,
                        p_county_name            => p_county_name,
                        p_state_initial         => p_state_initial,
                        p_active                => p_active,
                        p_location_kind_id      => NULL,
                        p_map_label             => NULL,
                        p_published_latitude    => NULL,
                        p_published_longitude   => NULL,
                        p_bounding_office_id    => NULL,
                        p_nation_id             => NULL,
                        p_nearest_city          => NULL,
                        p_db_office_id          => p_db_office_id
                       );
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
   PROCEDURE rename_loc (p_officeid          IN VARCHAR2,
                         p_base_loc_id_old   IN VARCHAR2,
                         p_base_loc_id_new   IN VARCHAR2
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
   PROCEDURE rename_location (p_location_id_old   IN VARCHAR2,
                              p_location_id_new   IN VARCHAR2,
                              p_db_office_id      IN VARCHAR2 DEFAULT NULL
                             )
   IS
      l_location_id_old          VARCHAR2 (57) := TRIM (p_location_id_old);
      l_location_id_new          VARCHAR2 (57) := TRIM (p_location_id_new);
      l_base_location_id_old      at_base_location.base_location_id%TYPE
         := cwms_util.get_base_id (l_location_id_old);
      --
      l_sub_location_id_old      at_physical_location.sub_location_id%TYPE
                                    := cwms_util.get_sub_id (l_location_id_old);
      --
      l_base_location_id_new      at_base_location.base_location_id%TYPE
         := cwms_util.get_base_id (l_location_id_new);
      --
      l_sub_location_id_new      at_physical_location.sub_location_id%TYPE
                                    := cwms_util.get_sub_id (l_location_id_new);
      --
      -- l_db_office_code cwms_office.office_code%TYPE;
      l_base_location_code_old   at_base_location.base_location_code%TYPE;
      l_base_location_code_new   at_base_location.base_location_code%TYPE;
      l_location_code_old         at_physical_location.location_code%TYPE;
      l_location_code_new         at_physical_location.location_code%TYPE;
      --
      l_base_location_id_exist   at_base_location.base_location_id%TYPE;
      l_sub_location_id_exist    at_physical_location.sub_location_id%TYPE
                                    := NULL;
      --
      l_old_loc_is_base_loc      BOOLEAN := FALSE;
      l_base_id_case_change      BOOLEAN := FALSE;
      l_sub_id_case_change       BOOLEAN := FALSE;
      l_id_case_change            BOOLEAN := FALSE;
      --
      l_location_type            at_physical_location.location_type%TYPE;
      l_elevation                at_physical_location.elevation%TYPE := NULL;
      l_vertical_datum            at_physical_location.vertical_datum%TYPE;
      l_latitude                  at_physical_location.latitude%TYPE := NULL;
      l_longitude                at_physical_location.longitude%TYPE := NULL;
      l_horizontal_datum         at_physical_location.horizontal_datum%TYPE;
      l_public_name               at_physical_location.public_name%TYPE;
      l_long_name                at_physical_location.long_name%TYPE;
      l_description               at_physical_location.description%TYPE;
      l_time_zone_code            at_physical_location.time_zone_code%TYPE
                                    := NULL;
      l_county_code               cwms_county.county_code%TYPE := NULL;
      l_active_flag               at_physical_location.active_flag%TYPE;
      l_location_kind            at_physical_location.location_kind%TYPE
                                    := NULL;
      l_map_label                at_physical_location.map_label%TYPE := NULL;
      l_published_latitude       at_physical_location.published_latitude%TYPE
                                    := NULL;
      l_published_longitude      at_physical_location.published_longitude%TYPE
         := NULL;
      l_office_code               at_physical_location.office_code%TYPE
                                    := NULL;
      l_nation_code               at_physical_location.nation_code%TYPE
                                    := NULL;
      l_nearest_city             at_physical_location.nearest_city%TYPE
                                    := NULL;
      l_db_office_id             VARCHAR2 (16)
         := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code            cwms_office.office_code%TYPE
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
            cwms_err.raise ('RENAME_LOC_BASE_2', p_location_id_new);
         END IF;
      END IF;

      ---------.
      ---------.
      --.
      -- retrieve existing base_location_code...
      --.
      BEGIN
         SELECT   base_location_code, base_location_id
           INTO   l_base_location_code_old, l_base_location_id_exist
           FROM   at_base_location abl
          WHERE   UPPER (abl.base_location_id) =
                     UPPER (l_base_location_id_old)
                  AND abl.db_office_code = l_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('LOCATION_ID_NOT_FOUND',
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
         SELECT   location_code, time_zone_code, county_code, location_type,
                  elevation, vertical_datum, longitude, latitude,
                  horizontal_datum, public_name, long_name, description,
                  active_flag, location_kind, map_label, published_latitude,
                  published_longitude, office_code, nation_code, nearest_city
           INTO   l_location_code_old, l_time_zone_code, l_county_code,
                  l_location_type, l_elevation, l_vertical_datum, l_longitude,
                  l_latitude, l_horizontal_datum, l_public_name, l_long_name,
                  l_description, l_active_flag, l_location_kind, l_map_label,
                  l_published_latitude, l_published_longitude, l_office_code,
                  l_nation_code, l_nearest_city
           FROM   at_physical_location apl
          WHERE   apl.base_location_code = l_base_location_code_old
                  AND apl.sub_location_id IS NULL;

         --
         l_old_loc_is_base_loc := TRUE;
      ELSE                                          -- For BASE-SUB Locations -
         BEGIN
            SELECT   location_code, sub_location_id, time_zone_code,
                     county_code, location_type, elevation, vertical_datum,
                     longitude, latitude, horizontal_datum, public_name,
                     long_name, description, active_flag, location_kind,
                     map_label, published_latitude, published_longitude,
                     office_code, nation_code, nearest_city
              INTO   l_location_code_old, l_sub_location_id_exist,
                     l_time_zone_code, l_county_code, l_location_type,
                     l_elevation, l_vertical_datum, l_longitude, l_latitude,
                     l_horizontal_datum, l_public_name, l_long_name,
                     l_description, l_active_flag, l_location_kind,
                     l_map_label, l_published_latitude, l_published_longitude,
                     l_office_code, l_nation_code, l_nearest_city
              FROM   at_physical_location apl
             WHERE   apl.base_location_code = l_base_location_code_old
                     AND UPPER (apl.sub_location_id) =
                            UPPER (l_sub_location_id_old);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('LOCATION_ID_NOT_FOUND',
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
         cwms_err.raise ('RENAME_LOC_BASE_1',
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
            cwms_err.raise ('RENAME_LOC_BASE_3', l_location_id_new);
         END IF;
      END IF;

      ---------.
      ---------.
      --.
      -- RENAME the location...
      --.
      CASE
         WHEN l_old_loc_is_base_loc
         THEN                                      -- Simple Base Loc Rename --
            UPDATE   at_base_location abl
               SET   base_location_id = l_base_location_id_new
             WHERE   abl.base_location_code = l_base_location_code_old;
         --
         WHEN l_sub_location_id_new IS NULL
         THEN                             -- Old Loc renamed to new Base Loc --
            --.
            -- 1) create a new Base Location with the new Base_Location_ID -
            --.
            INSERT
                 INTO   at_base_location (base_location_code,
                                          db_office_code,
                                          base_location_id,
                                          active_flag
                                         )
               VALUES   (
                           cwms_seq.NEXTVAL,
                           l_db_office_code,
                           l_base_location_id_new,
                           l_active_flag
                        )
            RETURNING   base_location_code
                 INTO   l_base_location_code_new;

            --.
            -- 2) update the old location by:
            --   a) updating its Base Location Code with the newly generated --
            --   Base_Location_Code, --
            --   b) setting the sub_location_id to null --
            --.
            UPDATE   at_physical_location apl
               SET   base_location_code = l_base_location_code_new,
                     sub_location_id = NULL
             WHERE   apl.location_code = l_location_code_old;
         ELSE
            IF UPPER (l_base_location_id_old) =
                  UPPER (l_base_location_id_new)
            THEN                 -- Simple rename of Base and/or Sub Loc IDs --
               IF l_base_id_case_change
               THEN
                  UPDATE   at_base_location abl
                     SET   base_location_id = l_base_location_id_new
                   WHERE   abl.base_location_code = l_base_location_code_old;
               END IF;

               --
               UPDATE   at_physical_location apl
                  SET   sub_location_id = l_sub_location_id_new
                WHERE   apl.location_code = l_location_code_old;
            ELSE           -- rename to a new Base Loc requires new Base Loc --
               --.
               --
               -- 1) create a new Base Location with the new Base Location_name -
               --.
               create_location_raw2 (l_base_location_code_new,
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
                                     l_active_flag,
                                     l_location_kind,
                                     l_map_label,
                                     l_published_latitude,
                                     l_published_longitude,
                                     l_office_code,
                                     l_nation_code,
                                     l_nearest_city
                                    );

               --.
               -- 2) update the old location by:
               --   a) updating its Base Location Code with the newly generated --
               --   Base_Location_Code, --
               --   b) setting the sub_location_id to the new sub_location_id --
               --.
               UPDATE   at_physical_location apl
                  SET   base_location_code = l_base_location_code_new,
                        sub_location_id = l_sub_location_id_new
                WHERE   apl.location_code = l_location_code_old;
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
   --   --
   --  delete_loc:  This action will delete the location_id only if there
   --  are no cwms_ts_id's associated with this location_id.
   --  If there are cwms_ts_id's assciated with the location_id,
   --  then an exception is thrown.
   --  delete_ts_data: This action will delete all of the data associated
   --  with all of the cwms_ts_id's associated with this
   --  location_id. The location_id and the cwms_ts_id's
   --  themselves are not deleted.
   --  delete_ts_id:   This action will delete any cwms_ts_id that has
   --  no associated data. Only ts_id's that have data
   --  along with the location_id itself will remain.
   --  delete_ts_cascade: This action will delete all data and all cwms_ts_id's
   --  associazted with this location_id. It does not delete
   --  the location_id.
   --  delete_loc_cascade: This will delete all data, all cwms_ts_id's, as well
   --  as the location_id itself.

   --
   --*---------------------------------------------------------------------*-
   PROCEDURE delete_location (
      p_location_id      IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_loc,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_count                 NUMBER;
      l_base_location_id     at_base_location.base_location_id%TYPE;
      --
      l_sub_location_id      at_physical_location.sub_location_id%TYPE;
      --
      l_base_location_code   NUMBER;
      l_location_code        NUMBER;
      l_db_office_code        NUMBER;
      l_delete_action        VARCHAR2 (22);
      l_cursor               SYS_REFCURSOR;
      l_this_is_a_base_loc   BOOLEAN := FALSE;
      --
      l_count_ts              NUMBER := 0;
      l_cwms_ts_id           VARCHAR2(191);
      l_ts_code              NUMBER;
      --
      l_location_codes        number_tab_t;
      l_location_ids         str_tab_t;
   --
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Location identifier must not be null.');
      END IF;

      IF p_delete_action IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Delete action must not be null.');
      END IF;

      l_delete_action :=
         NVL (UPPER (TRIM (p_delete_action)), cwms_util.delete_loc);

      IF l_delete_action NOT IN
            (cwms_util.delete_key,                           -- delete loc only
             cwms_util.delete_data,                -- delete all children only
             cwms_util.delete_all,               -- delete loc and all children
             cwms_util.delete_loc,                           -- delete loc only
             cwms_util.delete_loc_cascade,      -- delete loc and all children
             cwms_util.delete_ts_id,               -- delete child ts ids only
             cwms_util.delete_ts_data,            -- delete child ts data only
             cwms_util.delete_ts_cascade   -- delete child ts data and ids only
                                        )
      THEN
         cwms_err.raise ('INVALID_DELETE_ACTION', p_delete_action);
      END IF;

      l_base_location_id := cwms_util.get_base_id (p_location_id);
      l_sub_location_id  := cwms_util.get_sub_id (p_location_id);
      l_db_office_code   := cwms_util.get_office_code (p_db_office_id);

      -- You can only delete a location if that location does not have
      -- any child records.
      BEGIN
         SELECT   base_location_code
           INTO   l_base_location_code
           FROM   at_base_location abl
          WHERE   UPPER (abl.base_location_id) = UPPER (l_base_location_id)
                  AND abl.db_office_code = l_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('LOCATION_ID_NOT_FOUND', p_location_id);
      END;

      l_location_code := get_location_code (p_db_office_id, p_location_id);

      --
      IF l_sub_location_id IS NULL
      THEN
         l_this_is_a_base_loc := TRUE;
      END IF;

      ----------------------------------------------------------------
      -- Handle the times series separately since there are special --
      -- delete actions just for time series  --
      ----------------------------------------------------------------
      IF l_this_is_a_base_loc
      THEN
         OPEN l_cursor FOR
            SELECT   cwms_ts_id
              FROM   at_cwms_ts_id
             WHERE   base_location_code = l_base_location_code;
      ELSE
         OPEN l_cursor FOR
            SELECT   cwms_ts_id
              FROM   at_cwms_ts_id
             WHERE   location_code = l_location_code;
      END IF;

      LOOP
         FETCH l_cursor
         INTO l_cwms_ts_id;

         EXIT WHEN l_cursor%NOTFOUND;

         IF l_delete_action IN (cwms_util.delete_key, cwms_util.delete_loc)
         THEN
            CLOSE l_cursor;

            cwms_err.raise ('CAN_NOT_DELETE_LOC_1', p_location_id);
         END IF;

         CASE
            WHEN l_delete_action IN
                    (cwms_util.delete_data,
                     cwms_util.delete_all,
                     cwms_util.delete_loc_cascade,
                     cwms_util.delete_ts_cascade)
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
                     NULL;              -- exception thrown if ts_id has data.
               END;
            WHEN l_delete_action = cwms_util.delete_ts_data
            THEN
               cwms_ts.delete_ts (l_cwms_ts_id,
                                  cwms_util.delete_ts_data,
                                  l_db_office_code
                                 );
            ELSE
               cwms_err.raise ('INVALID_DELETE_ACTION', p_delete_action);
         END CASE;

         --
         l_count_ts := l_count_ts + 1;
      END LOOP;

      --
      CLOSE l_cursor;

      ---------------------------------------------
      -- delete other child records if specified --
      ---------------------------------------------
      if l_delete_action in
            (cwms_util.delete_data,
             cwms_util.delete_all,
             cwms_util.delete_loc_cascade)
      then
         if l_this_is_a_base_loc then
            --------------------------------------------
            -- collect location and all sub-locations --
            --------------------------------------------
            select location_code,
                   p_location_id || substr ('-', 1, length (sub_location_id)) || sub_location_id
              bulk collect into
                   l_location_codes,
                   l_location_ids
              from at_physical_location
             where base_location_code = l_base_location_code;
         else
            -------------------------------
            -- collect just the location --
            -------------------------------
            select location_code,
                   p_location_id
              bulk collect
              into l_location_codes,
                   l_location_ids
              from at_physical_location
             where location_code = l_location_code;
         end if;
         -----------------------
         -- group assignments --
         -----------------------
         delete
           from at_loc_group_assignment
          where location_code in (select * from table(l_location_codes));

         update at_loc_group_assignment
            set loc_ref_code = null
          where loc_ref_code in (select * from table(l_location_codes));
         ------------
         -- groups --
         ------------
         update at_loc_group
            set shared_loc_ref_code = null
          where shared_loc_ref_code in (select * from table(l_location_codes));
         ---------------------
         -- vertical datums --
         ---------------------
         delete
           from at_vert_datum_local
          where location_code in (select * from table(l_location_codes));
         delete
           from at_vert_datum_offset
          where location_code in (select * from table(l_location_codes));
         ------------
         -- basins --
         ------------
         update at_basin
            set parent_basin_code = null
          where parent_basin_code in (select * from table (l_location_codes));

         update at_basin
            set primary_stream_code = null
          where primary_stream_code in (select * from table (l_location_codes));

         delete from at_basin
               where basin_location_code in (select * from table (l_location_codes));
         -----------
         -- pumps --
         -----------
         delete
           from at_pump
          where pump_location_code in (select * from table(l_location_codes));
         -----------------------------------------------------------------------------
         -- streams, stream reaches, stream locations, and stream flow measurements --
         -----------------------------------------------------------------------------
         update at_stream
            set diverting_stream_code = null
          where diverting_stream_code in (select * from table (l_location_codes));

         update at_stream
            set receiving_stream_code = null
          where receiving_stream_code in (select * from table (l_location_codes));

         delete
           from at_stream_reach
          where stream_reach_location_code in (select * from table (l_location_codes))
             or upstream_location_code     in (select * from table (l_location_codes))
             or downstream_location_code   in (select * from table (l_location_codes))
             or stream_location_code       in (select * from table (l_location_codes));

         update at_stream_location
            set stream_location_code = null
          where stream_location_code in (select *from table (l_location_codes));

         delete
           from at_stream_location
          where location_code in (select * from table (l_location_codes));

         delete
           from at_stream
          where stream_location_code in (select * from table (l_location_codes));

         delete
           from at_streamflow_meas
          where location_code in (select * from table (l_location_codes));
         -----------------
         -- embankments --
         -----------------
         delete
           from at_embankment
          where embankment_location_code in (select * from table (l_location_codes));
         -----------
         -- locks --
         -----------
         delete
           from at_lockage
          where lockage_location_code in (select * from table (l_location_codes));

         delete
           from at_lock
          where lock_location_code in (select * from table (l_location_codes));
         -----------------------------
         -- compound outlet outlets --
         -----------------------------
         delete
           from at_comp_outlet_conn
          where outlet_location_code in (select * from table (l_location_codes))
             or next_outlet_code     in (select * from table (l_location_codes));
         ---------------
         -- overflows --
         ---------------
         delete
           from at_overflow
          where overflow_location_code in (select * from table(l_location_codes));
         -------------
         -- outlets --
         -------------
         delete
           from at_gate_setting
          where outlet_location_code in (select * from table (l_location_codes));

         delete
           from at_outlet
          where outlet_location_code in (select * from table (l_location_codes));
         ------------------------------
         -- compound outlet projects --
         ------------------------------
         for rec in (select compound_outlet_id,
                            get_location_id(project_location_code) as project_id
                       from at_comp_outlet
                      where project_location_code in (select * from table (l_location_codes))
                    )
         loop
            cwms_outlet.delete_compound_outlet(
               rec.project_id,
               rec.compound_outlet_id,
               cwms_util.delete_all,
               p_db_office_id);
         end loop;
         --------------
         -- turbines --
         --------------
         delete
           from at_turbine_setting
          where turbine_location_code in (select * from table (l_location_codes));

         delete from at_turbine
               where turbine_location_code in (select * from table (l_location_codes));
         --------------
         -- projects --
         --------------
         for i in 1..l_location_codes.count loop
            for rec in
               (select project_location_code
                  from at_project
                 where project_location_code = l_location_codes (i)
               )
            loop
               cwms_project.delete_project(
                  l_location_ids (i),
                  cwms_util.delete_all,
                  p_db_office_id);
            end loop;
         end loop;
         --------------
         -- entities --
         --------------
         delete
           from at_entity_location
          where location_code in (select * from table(l_location_codes));
         -----------
         -- gages --
         -----------
         delete
           from at_gage_sensor
          where gage_code in
                   (select gage_code
                      from at_gage
                     where gage_location_code in (select * from table (l_location_codes)));

         delete
           from at_goes
          where gage_code in
                   (select gage_code
                      from at_gage
                     where gage_location_code in (select * from table (l_location_codes)));

         delete
           from at_gage
          where gage_location_code in (select * from table (l_location_codes));
         ---------------
         -- documents --
         ---------------
         delete
           from at_document
          where document_location_code in (select * from table (l_location_codes));
         --------------------------
         -- geographic locations --
         --------------------------
         delete
           from at_geographic_location
          where location_code in (select * from table (l_location_codes));
         -----------
         -- urls --
         -----------
         delete
           from at_location_url
          where location_code in (select * from table (l_location_codes));
         -------------------
         -- display scale --
         -------------------
         delete
           from at_display_scale
          where location_code in (select * from table (l_location_codes));
         ---------------
         -- forecasts --
         ---------------
         delete
           from at_forecast_spec
          where target_location_code in (select * from table (l_location_codes))
             or source_location_code in (select * from table (l_location_codes));
         -------------
         -- ratings --
         -------------
         for i in 1..l_location_ids.count loop
            cwms_rating.delete_specs(
               l_location_ids (i) || '.*',
               cwms_util.delete_all,
               p_db_office_id);
         end loop;
         ---------------------
         -- location levels --
         ---------------------
         for i in 1..l_location_ids.count loop
            for rec
               in (select distinct
                          office_id,
                          location_level_id,
                          level_date,
                          attribute_id,
                          attribute_value,
                          attribute_unit
                     from cwms_v_location_level
                    where office_id = nvl (upper (trim (p_db_office_id)),cwms_util.user_office_id)
                      and location_level_id like l_location_ids (i) || '.%'
                      and unit_system = 'SI')
            loop
               cwms_level.delete_location_level_ex(
                  rec.location_level_id,
                  rec.level_date,
                  'UTC',
                  rec.attribute_id,
                  rec.attribute_value,
                  rec.attribute_unit,
                  'T',
                  'T',
                  rec.office_id);
            end loop;
         end loop;
         ----------------------------------
         -- A2W time series associations -- NOTE: Not foreign keyed
         ----------------------------------
         delete
           from at_a2w_ts_codes_by_loc
          where location_code in (select * from table (l_location_codes));
      end if;

      --------------------------------------------------------------
      -- finally, delete the actual location records if specified --
      --------------------------------------------------------------
      if l_delete_action in
            (cwms_util.delete_key,
             cwms_util.delete_all,
             cwms_util.delete_loc,
             cwms_util.delete_loc_cascade)
      then
         if l_this_is_a_base_loc
         then -- Deleting Base Location ----------------------------------------
            ----------------------
            -- actual locations --
            ----------------------
            delete
              from at_physical_location apl
             where apl.base_location_code = l_base_location_code;

            delete
              from at_base_location abl
             where abl.base_location_code = l_base_location_code;
         else -- Deleting a single Sub Location --------------------------------
            delete
              from at_physical_location apl
             where apl.location_code = l_location_code;
         end if;
      end if;

      commit;

   end delete_location;

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
      p_location_id     IN VARCHAR2,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      delete_location (p_location_id, cwms_util.delete_all, p_db_office_id);
   END delete_location_cascade;

   --********************************************************************** -
   --********************************************************************** -
   --
   -- COPY_LOCATION -
   --
   --*---------------------------------------------------------------------*-
   PROCEDURE copy_location (p_location_id_old   IN VARCHAR2,
                            p_location_id_new   IN VARCHAR2,
                            p_active            IN VARCHAR2 DEFAULT 'T',
                            p_db_office_id      IN VARCHAR2 DEFAULT NULL
                           )
   IS
   BEGIN
      NULL;
   END copy_location;

   --
   --********************************************************************** -
   --********************************************************************** -
   --
   -- STORE_ALIASES -
   --
   -- p_store_rule - Valid store rules are: -
   --  Delete Insert - This will delete all existing aliases  -
   --  and insert the new set of aliases -
   --  in your p_alias_array. This is the -
   --  Default.  -
   --  Replace All - This will update any pre-existing  -
   --  aliases and insert new ones -
   --
   -- p_ignorenulls - is only valid when the "Replace All" store rull is    -
   --   envoked.
   --   if 'T' then do not update a pre-existing value        -
   --   with a newly passed-in null value.  -
   --   if 'F' then update a pre-existing value               -
   --   with a newly passed-in null value.  -
   --*--------------------------------------------------------------------- -
   --
   --   PROCEDURE store_aliases (
   --   p_location_id  IN VARCHAR2,
   --   p_alias_array  IN alias_array,
   --   p_store_rule   IN VARCHAR2 DEFAULT 'DELETE INSERT',
   --   p_ignorenulls  IN VARCHAR2 DEFAULT 'T',
   --   p_db_office_id IN VARCHAR2 DEFAULT NULL
   --   )
   --   IS
   --   l_agency_code  NUMBER;
   --   l_office_id VARCHAR2 (16);
   --   l_office_code  NUMBER;
   --   l_location_code   NUMBER;
   --   l_array_count  NUMBER   := p_alias_array.COUNT;
   --   l_count  NUMBER  := 1;
   --   l_distinct NUMBER;
   --   l_store_rule   VARCHAR2 (16);
   --   l_alias_id VARCHAR2 (16);
   --   l_alias_public_name  VARCHAR2 (57);
   --   l_alias_long_name VARCHAR2 (80);
   --   l_insert BOOLEAN;
   --   l_ignorenulls  BOOLEAN
   --  := cwms_util.return_true_or_false (p_ignorenulls);
   --   BEGIN
   --   --
   --   IF l_count = 0
   --   THEN
   --   cwms_err.RAISE
   --  ('GENERIC_ERROR',
   --   'No viable agency/alias data passed to store_aliases.'
   --  );
   --   END IF;

   --------------------------------------------------------------------
   ---- Check that passed-in aliases are do not contain duplicates...
   --------------------------------------------------------------------
   --   SELECT COUNT (*)
   --   INTO l_distinct
   --   FROM (SELECT DISTINCT UPPER (t.agency_id)
   --   FROM TABLE (CAST (p_alias_array AS alias_array)) t);

   --   --
   --   IF l_distinct != l_array_count
   --   THEN
   --   cwms_err.RAISE
   --  ('GENERIC_ERROR',
   --   'Duplicate Agency/Alias pairs are not permited. Only one Alias is permited per Agency (store_aliases).'
   --  );
   --   END IF;

   --   --
   --   -- Make sure none of the alias_id's are null
   --   --
   --   SELECT COUNT (*)
   --   INTO l_distinct
   --   FROM (SELECT t.alias_id
   --  FROM TABLE (CAST (p_alias_array AS alias_array)) t
   --   WHERE alias_id IS NULL);

   --   --
   --   IF l_distinct != 0
   --   THEN
   --   cwms_err.RAISE
   --  ('GENERIC_ERROR',
   --   'A NULL alias_id was submitted. alias_id may not be NULL. (store_aliases).'
   --  );
   --   END IF;

   --   --
   --   IF p_db_office_id IS NULL
   --   THEN
   --   l_office_id := cwms_util.user_office_id;
   --   ELSE
   --   l_office_id := UPPER (p_db_office_id);
   --   END IF;

   --   --
   --   l_office_code := get_office_code (l_office_id);
   --   l_location_code := get_location_code (l_office_id, p_location_id);

   --   --
   --   IF p_store_rule IS NULL
   --   THEN
   --   l_store_rule := cwms_util.delete_all;
   --   ELSIF UPPER (p_store_rule) = cwms_util.delete_all
   --   THEN
   --   l_store_rule := cwms_util.delete_all;
   --   ELSIF UPPER (p_store_rule) = cwms_util.replace_all
   --   THEN
   --   l_store_rule := cwms_util.replace_all;
   --   ELSE
   --   cwms_err.RAISE ('GENERIC_ERROR',
   --  p_store_rule
   --   || ' is an invalid store rule. (store_aliases)'
   --  );
   --   END IF;

   --   --
   --   IF l_store_rule = cwms_util.delete_all
   --   THEN
   --   DELETE FROM at_loc_group_assignment atlga
   --  WHERE atlga.location_code = l_location_code;

   --   --
   --   LOOP
   --  EXIT WHEN l_count > l_array_count;

   --  --
   --  BEGIN
   --   SELECT agency_code
   --   INTO l_agency_code
   --   FROM at_agency_name
   --  WHERE UPPER (agency_id) =
   --   UPPER (p_alias_array (l_count).agency_id)
   --  AND db_office_code IN
   --  (l_office_code, cwms_util.db_office_code_all);
   --  EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN
   --  --.
   --  INSERT INTO at_agency_name
   --  (agency_code,
   --   agency_id,
   --   agency_name,
   --   db_office_code
   --  )
   --   VALUES (cwms_seq.NEXTVAL,
   --   p_alias_array (l_count).agency_id,
   --   p_alias_array (l_count).agency_name,
   --   l_office_code
   --  )
   --  RETURNING agency_code
   --   INTO l_agency_code;
   --  END;

   --  --
   --  INSERT INTO at_alias_name
   --  (location_code, agency_code,
   --   alias_id,
   --   alias_public_name,
   --   alias_long_name
   --  )
   --   VALUES (l_location_code, l_agency_code,
   --   p_alias_array (l_count).alias_id,
   --   p_alias_array (l_count).alias_public_name,
   --   p_alias_array (l_count).alias_long_name
   --  );

   --  --
   --  l_count := l_count + 1;
   --   END LOOP;
   --   ELSE  -- store_rule is REPLACE ALL -
   --   LOOP
   --  EXIT WHEN l_count > l_array_count;

   --  --
   --  -- retrieve agency_code...
   --  BEGIN
   --   SELECT agency_code
   --   INTO l_agency_code
   --   FROM at_agency_name
   --  WHERE UPPER (agency_id) =
   --   UPPER (p_alias_array (l_count).agency_id)
   --  AND db_office_code IN
   --  (l_office_code, cwms_util.db_office_code_all);
   --  EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN -- No agency_code found, so create one...
   --  --.
   --  INSERT INTO at_agency_name
   --  (agency_code,
   --   agency_id,
   --   agency_name,
   --   db_office_code
   --  )
   --   VALUES (cwms_seq.NEXTVAL,
   --   p_alias_array (l_count).agency_id,
   --   p_alias_array (l_count).agency_name,
   --   l_office_code
   --  )
   --  RETURNING agency_code
   --   INTO l_agency_code;
   --  END;

   --  --
   --  --
   --  -- retrieve existing alias information...
   --  l_insert := FALSE;

   --  BEGIN
   --   SELECT alias_id, alias_public_name, alias_long_name
   --   INTO l_alias_id, l_alias_public_name, l_alias_long_name
   --   FROM at_alias_name
   --  WHERE location_code = l_location_code
   --  AND agency_code = l_agency_code;

   --   --
   --   IF p_alias_array (l_count).alias_public_name IS NULL
   --  AND NOT l_ignorenulls
   --   THEN
   --  l_alias_public_name := NULL;
   --   END IF;

   --   IF p_alias_array (l_count).alias_long_name IS NULL
   --  AND NOT l_ignorenulls
   --   THEN
   --  l_alias_long_name := NULL;
   --   END IF;
   --  EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN
   --  l_insert := TRUE;
   --  END;

   --  --
   --  IF l_insert
   --  THEN
   --   --
   --   INSERT INTO at_alias_name
   --   (location_code, agency_code,
   --  alias_id,
   --  alias_public_name,
   --  alias_long_name
   --   )
   --  VALUES (l_location_code, l_agency_code,
   --  p_alias_array (l_count).alias_id,
   --  p_alias_array (l_count).alias_public_name,
   --  p_alias_array (l_count).alias_long_name
   --   );
   --  ELSE
   --   UPDATE at_alias_name
   --  SET alias_id = p_alias_array (l_count).alias_id,
   --  alias_public_name = l_alias_public_name,
   --  alias_long_name = l_alias_long_name
   --  WHERE location_code = l_location_code
   --  AND agency_code = l_agency_code;
   --  --
   --  END IF;

   --  --
   --  l_count := l_count + 1;
   --   END LOOP;
   --   END IF;

   --   --
   --   COMMIT;
   ----
   --   NULL;
   --   END store_aliases;

   --   PROCEDURE store_alias (
   --   p_location_id  IN VARCHAR2,
   --   p_agency_id IN VARCHAR2,
   --   p_alias_id IN VARCHAR2,
   --   p_agency_name  IN VARCHAR2 DEFAULT NULL,
   --   p_alias_public_name  IN VARCHAR2 DEFAULT NULL,
   --   p_alias_long_name IN VARCHAR2 DEFAULT NULL,
   --   p_ignorenulls  IN VARCHAR2 DEFAULT 'T',
   --   p_db_office_id IN VARCHAR2 DEFAULT NULL
   --   )
   --   IS
   --   l_alias_array  alias_array := alias_array ();
   --   l_store_rule   VARCHAR2 (16) := 'REPLACE ALL';
   --   BEGIN
   --   --
   --   l_alias_array.EXTEND;
   --   --
   --   l_alias_array (1) :=
   --   alias_type (p_agency_id,
   --   p_alias_id,
   --   p_agency_name,
   --   p_alias_public_name,
   --   p_alias_long_name
   --  );
   --   --
   --   store_aliases (p_location_id,
   --   l_alias_array,
   --   l_store_rule,
   --   p_ignorenulls,
   --   p_db_office_id
   --  );
   --   END store_alias;

   --********************************************************************** -

   PROCEDURE store_location2 (
      p_location_id            IN VARCHAR2,
      p_location_type         IN VARCHAR2 DEFAULT NULL,
      p_elevation             IN NUMBER DEFAULT NULL,
      p_elev_unit_id          IN VARCHAR2 DEFAULT NULL,
      p_vertical_datum         IN VARCHAR2 DEFAULT NULL,
      p_latitude               IN NUMBER DEFAULT NULL,
      p_longitude             IN NUMBER DEFAULT NULL,
      p_horizontal_datum      IN VARCHAR2 DEFAULT NULL,
      p_public_name            IN VARCHAR2 DEFAULT NULL,
      p_long_name             IN VARCHAR2 DEFAULT NULL,
      p_description            IN VARCHAR2 DEFAULT NULL,
      p_time_zone_id          IN VARCHAR2 DEFAULT NULL,
      p_county_name            IN VARCHAR2 DEFAULT NULL,
      p_state_initial         IN VARCHAR2 DEFAULT NULL,
      p_active                IN VARCHAR2 DEFAULT NULL,
      p_location_kind_id      IN VARCHAR2 DEFAULT NULL,
      p_map_label             IN VARCHAR2 DEFAULT NULL,
      p_published_latitude    IN NUMBER DEFAULT NULL,
      p_published_longitude   IN NUMBER DEFAULT NULL,
      p_bounding_office_id    IN VARCHAR2 DEFAULT NULL,
      p_nation_id             IN VARCHAR2 DEFAULT NULL,
      p_nearest_city          IN VARCHAR2 DEFAULT NULL,
      p_ignorenulls            IN VARCHAR2 DEFAULT 'T',
      p_db_office_id          IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_id     VARCHAR2 (16);
      l_office_code    NUMBER;
   BEGIN
      --
      -- check if cwms_id for this office already exists...
      BEGIN
         update_location2 (p_location_id,
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
                           p_location_kind_id,
                           p_map_label,
                           p_published_latitude,
                           p_published_longitude,
                           p_bounding_office_id,
                           p_nation_id,
                           p_nearest_city,
                           p_ignorenulls,
                           p_db_office_id
                          );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            CASE
            WHEN instr(lower(sqlerrm), 'time zone') > 0 THEN
               RAISE;
            ELSE
            create_location2 (p_location_id,
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
                              p_location_kind_id,
                              p_map_label,
                              p_published_latitude,
                              p_published_longitude,
                              p_bounding_office_id,
                              p_nation_id,
                              p_nearest_city,
                              p_db_office_id
                             );
            END CASE;
      END;
   --

   --  store_aliases (p_location_id,
   --   p_alias_array,
   --   'DELETE INSERT',
   --   p_ignorenulls,
   --   p_db_office_id
   --  );
   --
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END store_location2;

   --********************************************************************** -
   --
   -- STORE_LOC provides backward compatiblity for the dbi.  It will update a
   -- location if it already exists by calling update_loc or create a new location
   -- by calling create_loc.
   --
   --*---------------------------------------------------------------------*-
   --

   PROCEDURE store_location (p_location_id        IN VARCHAR2,
                             p_location_type      IN VARCHAR2 DEFAULT NULL,
                             p_elevation           IN NUMBER DEFAULT NULL,
                             p_elev_unit_id        IN VARCHAR2 DEFAULT NULL,
                             p_vertical_datum     IN VARCHAR2 DEFAULT NULL,
                             p_latitude           IN NUMBER DEFAULT NULL,
                             p_longitude           IN NUMBER DEFAULT NULL,
                             p_horizontal_datum   IN VARCHAR2 DEFAULT NULL,
                             p_public_name        IN VARCHAR2 DEFAULT NULL,
                             p_long_name           IN VARCHAR2 DEFAULT NULL,
                             p_description        IN VARCHAR2 DEFAULT NULL,
                             p_time_zone_id        IN VARCHAR2 DEFAULT NULL,
                             p_county_name        IN VARCHAR2 DEFAULT NULL,
                             p_state_initial      IN VARCHAR2 DEFAULT NULL,
                             p_active              IN VARCHAR2 DEFAULT NULL,
                             p_ignorenulls        IN VARCHAR2 DEFAULT 'T',
                             p_db_office_id        IN VARCHAR2 DEFAULT NULL
                            )
   IS
   BEGIN
      --
      -- DBMS_OUTPUT.put_line ('entering store_location2');

      store_location2 (p_location_id        => p_location_id,
                       p_location_type      => p_location_type,
                       p_elevation           => p_elevation,
                       p_elev_unit_id        => p_elev_unit_id,
                       p_vertical_datum     => p_vertical_datum,
                       p_latitude           => p_latitude,
                       p_longitude           => p_longitude,
                       p_horizontal_datum   => p_horizontal_datum,
                       p_public_name        => p_public_name,
                       p_long_name           => p_long_name,
                       p_description        => p_description,
                       p_time_zone_id        => p_time_zone_id,
                       p_county_name        => p_county_name,
                       p_state_initial      => p_state_initial,
                       p_active              => p_active,
                       p_ignorenulls        => p_ignorenulls,
                       p_db_office_id        => p_db_office_id
                      );
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
   --
   PROCEDURE retrieve_location2 (
      p_location_id            IN OUT VARCHAR2,
      p_elev_unit_id          IN     VARCHAR2 DEFAULT 'm',
      p_location_type            OUT VARCHAR2,
      p_elevation                OUT NUMBER,
      p_vertical_datum            OUT VARCHAR2,
      p_latitude                  OUT NUMBER,
      p_longitude                OUT NUMBER,
      p_horizontal_datum         OUT VARCHAR2,
      p_public_name               OUT VARCHAR2,
      p_long_name                OUT VARCHAR2,
      p_description               OUT VARCHAR2,
      p_time_zone_id             OUT VARCHAR2,
      p_county_name               OUT VARCHAR2,
      p_state_initial            OUT VARCHAR2,
      p_active                   OUT VARCHAR2,
      p_location_kind_id         OUT VARCHAR2,
      p_map_label                OUT VARCHAR2,
      p_published_latitude       OUT NUMBER,
      p_published_longitude      OUT NUMBER,
      p_bounding_office_id       OUT VARCHAR2,
      p_nation_id                OUT VARCHAR2,
      p_nearest_city             OUT VARCHAR2,
      p_alias_cursor             OUT SYS_REFCURSOR,
      p_db_office_id          IN     VARCHAR2 DEFAULT NULL
   )
   IS
      l_office_id              VARCHAR2 (16);
      l_office_code             NUMBER;
      l_location_code          NUMBER;
      l_bounding_office_code    NUMBER := NULL;
      l_nation_code             VARCHAR (2) := NULL;
      l_cwms_office_code       NUMBER := cwms_util.get_office_code ('CWMS');
   --
   -- l_alias_cursor   sys_refcursor;
   --
   BEGIN
      l_office_id := cwms_util.get_db_office_id (p_db_office_id);
      --
      l_office_code := cwms_util.get_db_office_code (l_office_id);
      l_location_code := get_location_code (l_office_id, p_location_id);

      --
      SELECT   al.location_id
        INTO   p_location_id
        FROM   av_loc al
       WHERE   al.location_code = l_location_code AND unit_system = 'SI';

      --
      BEGIN
         SELECT   apl.location_type,
                  convert_from_to (apl.elevation, 'm', p_elev_unit_id, 'Length') elev,
                  apl.vertical_datum,
                  apl.latitude, apl.longitude, apl.horizontal_datum,
                  apl.public_name, apl.long_name, apl.description,
                  ctz.time_zone_name, cc.county_name, cs.state_initial,
                  apl.active_flag, clk.location_kind_id, apl.map_label,
                  apl.published_latitude, apl.published_longitude,
                  apl.office_code, apl.nation_code, apl.nearest_city
           INTO   p_location_type, p_elevation, p_vertical_datum, p_latitude, p_longitude,
                  p_horizontal_datum, p_public_name, p_long_name,
                  p_description, p_time_zone_id, p_county_name,
                  p_state_initial, p_active, p_location_kind_id, p_map_label,
                  p_published_latitude, p_published_longitude,
                  l_bounding_office_code, l_nation_code, p_nearest_city
           FROM   at_physical_location apl,
                  cwms_county cc,
                  cwms_state cs,
                  cwms_time_zone ctz,
                  cwms_location_kind clk
          WHERE       NVL (apl.county_code, 0) = cc.county_code
                  AND NVL (cc.state_code, 0) = cs.state_code
                  AND NVL (apl.time_zone_code, 0) = ctz.time_zone_code
                  AND clk.location_kind_code = apl.location_kind
                  AND apl.location_code = l_location_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      IF l_bounding_office_code IS NULL
      THEN
         p_bounding_office_id := NULL;
      ELSE
         SELECT   office_id
           INTO   p_bounding_office_id
           FROM   cwms_office
          WHERE   office_code = l_bounding_office_code;
      END IF;

      IF l_nation_code IS NULL
      THEN
         p_nation_id := NULL;
      ELSE
         SELECT   nation_id
           INTO   p_nation_id
           FROM   cwms_nation
          WHERE   nation_code = l_nation_code;
      END IF;

      --
      --   cwms_cat.cat_loc_aliases (l_alias_cursor,
      --  p_location_id,
      --  NULL,
      --  'F',
      --  l_office_id
      --   );
      cwms_cat.cat_loc_aliases (p_cwms_cat          => p_alias_cursor,
                                p_location_id       => p_location_id,
                                p_loc_category_id    => NULL,
                                p_loc_group_id       => NULL,
                                p_abbreviated       => 'T',
                                p_db_office_id       => l_office_id
                               );
   --
   -- p_alias_cursor := l_alias_cursor;
   --
   --
   END retrieve_location2;

   function adjust_location_elevation(
      p_location      in out nocopy location_obj_t,
      p_location_code in integer,
      p_elev_unit     in varchar2,
      p_vert_datum    in varchar2)
      return varchar2
   is
      l_estimate       varchar2(8)  := 'false';
      l_elev_unit      varchar2(16) := nvl(trim(p_elev_unit), 'm');
      l_vert_datum     varchar2(16) := upper(trim(p_vert_datum));
      l_vert_datum_xml xmltype;
      l_offset_xml     xmltype;
   begin
      if p_location.elevation is null then
         p_location.vertical_datum := null;
         l_estimate := null;
      else
         if l_elev_unit != 'm' then
            p_location.elevation := cwms_util.convert_units(p_location.elevation, 'm', l_elev_unit);
         end if;
         if l_vert_datum is not null then
            l_vert_datum_xml := xmltype(get_vertical_datum_info_f(p_location_code, l_elev_unit));
            case
               when regexp_like(l_vert_datum, 'ngvd[ -]?(19)?29', 'i') then
                  if cwms_util.get_xml_text(l_vert_datum_xml, '/vertical-datum-info/native-datum') != 'NGVD-29' then
                     l_offset_xml := cwms_util.get_xml_node(l_vert_datum_xml, './vertical-datum-info/offset[to-datum=''NGVD-29'']');
                     p_location.elevation := p_location.elevation + cwms_util.get_xml_number(l_offset_xml, '/offset/value');
                     p_location.vertical_datum := 'NGVD29';
                     l_estimate := cwms_util.get_xml_text(l_offset_xml, '/offset/@estimate');
                  end if;
               when regexp_like(l_vert_datum, 'navd[ -]?(19)?88', 'i') then
                  if cwms_util.get_xml_text(l_vert_datum_xml, '/vertical-datum-info/native-datum') != 'NAVD-88' then
                     l_offset_xml := cwms_util.get_xml_node(l_vert_datum_xml, './vertical-datum-info/offset[to-datum=''NAVD-88'']');
                     p_location.elevation := p_location.elevation + cwms_util.get_xml_number(l_offset_xml, '/offset/value');
                     p_location.vertical_datum := 'NAVD88';
                     l_estimate := cwms_util.get_xml_text(l_offset_xml, '/offset/@estimate');
                  end if;
               else
                  cwms_err.raise('ERROR', 'Vertical datum must be eithe NGVD29 or NAVD88');
            end case;
         end if;
         p_location.elevation := cwms_rounding.round_nn_f(p_location.elevation, '7777777773');
      end if;
      return l_estimate;
   end adjust_location_elevation;

   --
   --********************************************************************** -
   --********************************************************************** -
   --
   -- RETRIEVE_LOCATION provides backward compatiblity for the dbi. It will update a
   -- location if it already exists by calling update_loc or create a new location
   -- by calling create_loc.
   --
   --*---------------------------------------------------------------------*-
   --
   PROCEDURE retrieve_location (
      p_location_id         IN OUT VARCHAR2,
      p_elev_unit_id       IN     VARCHAR2 DEFAULT 'm',
      p_location_type         OUT VARCHAR2,
      p_elevation             OUT NUMBER,
      p_vertical_datum         OUT VARCHAR2,
      p_latitude               OUT NUMBER,
      p_longitude             OUT NUMBER,
      p_horizontal_datum      OUT VARCHAR2,
      p_public_name            OUT VARCHAR2,
      p_long_name             OUT VARCHAR2,
      p_description            OUT VARCHAR2,
      p_time_zone_id          OUT VARCHAR2,
      p_county_name            OUT VARCHAR2,
      p_state_initial         OUT VARCHAR2,
      p_active                OUT VARCHAR2,
      p_alias_cursor          OUT SYS_REFCURSOR,
      p_db_office_id       IN     VARCHAR2 DEFAULT NULL
   )
   IS
      l_location_kind_id      cwms_location_kind.location_kind_id%TYPE;
      l_map_label             at_physical_location.map_label%TYPE;
      l_published_latitude    at_physical_location.published_latitude%TYPE;
      l_published_longitude   at_physical_location.published_longitude%TYPE;
      l_bounding_office_id    cwms_office.office_id%TYPE;
      l_nation_id             cwms_nation.nation_id%TYPE;
      l_nearest_city          at_physical_location.nearest_city%TYPE;
   BEGIN
      retrieve_location2 (p_location_id,
                          p_elev_unit_id,
                          p_location_type,
                          p_elevation,
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
                          l_location_kind_id,
                          l_map_label,
                          l_published_latitude,
                          l_published_longitude,
                          l_bounding_office_id,
                          l_nation_id,
                          l_nearest_city,
                          p_alias_cursor,
                          p_db_office_id
                         );
   END retrieve_location;

   --------------------------------------------------------------------------------
   -- FUNCTION get_local_timezone
   --------------------------------------------------------------------------------
   function get_local_timezone (p_location_code in number)
      return varchar2
   is
      l_local_tz varchar2 (28);
      l_rec      at_physical_location%rowtype;
   begin
      select * into l_rec from at_physical_location where location_code = p_location_code;
      if l_rec.time_zone_code is null and l_rec.base_location_code != p_location_code then
         select * into l_rec from at_physical_location where location_code = l_rec.base_location_code;
      end if;

      select time_zone_name
        into l_local_tz
        from cwms_time_zone
       where time_zone_code = nvl(l_rec.time_zone_code, 0);

      if l_local_tz = 'Unknown or Not Applicable' then
         l_local_tz := 'UTC';
      end if;

      return l_local_tz;
   end get_local_timezone;

   --------------------------------------------------------------------------------
   -- FUNCTION get_local_timezone
   --------------------------------------------------------------------------------
   function get_local_timezone (
      p_location_id   in varchar2,
      p_office_id      in varchar2)
      return varchar2
   is
   begin
      return get_local_timezone(get_location_code(p_office_id, p_location_id, 'T'));
   end get_local_timezone;

   FUNCTION get_loc_category_code (p_loc_category_id    IN VARCHAR2,
                                   p_db_office_code    IN NUMBER
                                  )
      RETURN NUMBER
   IS
      l_loc_category_code    NUMBER;
   BEGIN
      BEGIN
         SELECT   atlc.loc_category_code
           INTO   l_loc_category_code
           FROM   at_loc_category atlc
          WHERE   atlc.db_office_code IN (53, p_db_office_code)
                  AND UPPER (atlc.loc_category_id) =
                         UPPER (TRIM (p_loc_category_id));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Category id: ',
                            p_loc_category_id
                           );
      END;

      RETURN l_loc_category_code;
   END get_loc_category_code;

   FUNCTION get_loc_group_code (p_loc_category_id    IN VARCHAR2,
                                p_loc_group_id       IN VARCHAR2,
                                p_db_office_code    IN NUMBER
                               )
      RETURN NUMBER
   IS
      l_loc_category_code    NUMBER;
      l_loc_group_code       NUMBER;
   BEGIN
      l_loc_category_code :=
         get_loc_category_code (p_loc_category_id, p_db_office_code);

      BEGIN
         SELECT   loc_group_code
           INTO   l_loc_group_code
           FROM   at_loc_group atlg
          WHERE       atlg.loc_category_code = l_loc_category_code
                  AND UPPER (atlg.loc_group_id) = UPPER (p_loc_group_id)
                  AND db_office_code IN (53, p_db_office_code);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'group id: ',
                            p_loc_group_id
                           );
      END;

      RETURN l_loc_group_code;
   END get_loc_group_code;

   PROCEDURE store_loc_category (
      p_loc_category_id     IN VARCHAR2,
      p_loc_category_desc    IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists       IN VARCHAR2 DEFAULT 'F',
      p_ignore_null          IN VARCHAR2 DEFAULT 'T',
      p_db_office_id        IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_tmp   NUMBER;
   BEGIN
      l_tmp :=
         store_loc_category_f (p_loc_category_id,
                               p_loc_category_desc,
                               p_fail_if_exists,
                               p_ignore_null,
                               p_db_office_id
                              );
   END store_loc_category;

   FUNCTION store_loc_category_f (
      p_loc_category_id     IN VARCHAR2,
      p_loc_category_desc    IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists       IN VARCHAR2 DEFAULT 'F',
      p_ignore_null          IN VARCHAR2 DEFAULT 'T',
      p_db_office_id        IN VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code       NUMBER;
      l_loc_category_id     VARCHAR2 (32) := TRIM (p_loc_category_id);
      l_loc_category_desc    VARCHAR2 (128) := TRIM (p_loc_category_desc);
      l_fail_if_exists       BOOLEAN := cwms_util.is_true (p_fail_if_exists);
      l_ignore_null          BOOLEAN := cwms_util.is_true (p_ignore_null);
      l_rec                 at_loc_category%ROWTYPE;
      l_exists              BOOLEAN;
   BEGIN
      l_db_office_id := NVL (UPPER (p_db_office_id), cwms_util.user_office_id);
      l_db_office_code := cwms_util.get_office_code (l_db_office_id);

      -------------------------------------------
      -- determine whether the category exists --
      -------------------------------------------
      BEGIN
         SELECT   *
           INTO   l_rec
           FROM   at_loc_category
          WHERE   UPPER (loc_category_id) = UPPER (l_loc_category_id)
                  AND db_office_code IN
                         (l_db_office_code, cwms_util.db_office_code_all);

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      --------------------------------
      -- fail if conditions warrant --
      --------------------------------
      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
                  l_db_office_id
               || '/'
               || l_loc_category_id
               || ' already exists.'
            );
         ELSIF l_rec.db_office_code = cwms_util.db_office_code_all
         THEN
            -------------------------------------------------------
            -- this is OK if we're not trying to update anything --
            -------------------------------------------------------
            IF (l_ignore_null AND p_loc_category_desc IS NULL)
               OR (p_loc_category_desc = l_rec.loc_category_desc)
            THEN
               RETURN l_rec.loc_category_code;
            END IF;

            ----------------------------------
            -- can't change a CWMS category --
            ----------------------------------
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
                  'Cannot store the '
               || l_loc_category_id
               || ' category because it already exists as a system category.'
            );
         END IF;
      END IF;

      ---------------------------------
      -- insert or update the record --
      ---------------------------------
      IF l_exists
      THEN
         IF NOT (l_ignore_null AND p_loc_category_desc IS NULL)
         THEN
            l_rec.loc_category_desc := p_loc_category_desc;
         END IF;

         UPDATE   at_loc_category
            SET   row = l_rec
          WHERE   loc_category_code = l_rec.loc_category_code;
      ELSE
         l_rec.loc_category_code := cwms_seq.NEXTVAL;
         l_rec.loc_category_id := p_loc_category_id;
         l_rec.loc_category_desc := p_loc_category_desc;
         l_rec.db_office_code := l_db_office_code;

         INSERT INTO   at_loc_category
              VALUES   l_rec;
      END IF;

      RETURN l_rec.loc_category_code;
   END store_loc_category_f;

   PROCEDURE create_loc_category (
      p_loc_category_id     IN VARCHAR2,
      p_loc_category_desc    IN VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      store_loc_category (p_loc_category_id,
                          p_loc_category_desc,
                          'T',
                          'F',
                          p_db_office_id
                         );
   END create_loc_category;

   FUNCTION create_loc_category_f (
      p_loc_category_id     IN VARCHAR2,
      p_loc_category_desc    IN VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER
   IS
   BEGIN
      RETURN store_loc_category_f (p_loc_category_id,
                                   p_loc_category_desc,
                                   'T',
                                   'F',
                                   p_db_office_id
                                  );
   END create_loc_category_f;

   PROCEDURE store_loc_group (p_loc_category_id     IN VARCHAR2,
                              p_loc_group_id        IN VARCHAR2,
                              p_loc_group_desc      IN VARCHAR2 DEFAULT NULL,
                              p_fail_if_exists      IN VARCHAR2 DEFAULT 'F',
                              p_ignore_nulls        IN VARCHAR2 DEFAULT 'T',
                              p_shared_alias_id     IN VARCHAR2 DEFAULT NULL,
                              p_shared_loc_ref_id   IN VARCHAR2 DEFAULT NULL,
                              p_db_office_id        in varchar2 default null
                             )
   IS
   begin
      store_loc_group2 (
         p_loc_category_id,
         p_loc_group_id,
         p_loc_group_desc,
         null,
         p_fail_if_exists,
         p_ignore_nulls,
         p_shared_alias_id,
         p_shared_loc_ref_id,
         p_db_office_id);
   END store_loc_group;

   PROCEDURE store_loc_group2 (p_loc_category_id     IN VARCHAR2,
                               p_loc_group_id        IN VARCHAR2,
                               p_loc_group_desc      IN VARCHAR2 DEFAULT NULL,
                               p_loc_group_attribute in number default null,
                               p_fail_if_exists      IN VARCHAR2 DEFAULT 'F',
                               p_ignore_nulls        IN VARCHAR2 DEFAULT 'T',
                               p_shared_alias_id     IN VARCHAR2 DEFAULT NULL,
                               p_shared_loc_ref_id   IN VARCHAR2 DEFAULT NULL,
                               p_db_office_id        in varchar2 default null
                              )
   IS
      l_rec              at_loc_group%ROWTYPE;
      l_office_code       NUMBER (10)
                            := cwms_util.get_db_office_code (p_db_office_id);
      l_fail_if_exists    BOOLEAN := cwms_util.is_true (p_fail_if_exists);
      l_ignore_nulls     BOOLEAN := cwms_util.is_true (p_ignore_nulls);
      l_exists           BOOLEAN;
   BEGIN
      -----------------------------------------
      -- determine whether the record exists --
      -----------------------------------------
      BEGIN
         SELECT   g.loc_group_code, g.loc_category_code, g.loc_group_id,
                  g.loc_group_desc, g.db_office_code, g.shared_loc_alias_id,
                  g.shared_loc_ref_code, g.loc_group_attribute
           INTO   l_rec
           FROM   at_loc_group g, at_loc_category c
          WHERE       UPPER (c.loc_category_id) = UPPER (p_loc_category_id)
                  AND g.loc_category_code = c.loc_category_code
                  AND UPPER (g.loc_group_id) = UPPER (p_loc_group_id)
                  AND g.db_office_code IN
                         (l_office_code, cwms_util.db_office_code_all);

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      --------------------------------
      -- fail if conditions warrant --
      --------------------------------
      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
                  'CWMS location group '
               || NVL (UPPER (p_db_office_id), cwms_util.user_office_id)
               || '/'
               || p_loc_category_id
               || '/'
               || p_loc_group_id
            );
         END IF;

         IF l_rec.db_office_code = cwms_util.db_office_code_all
         THEN
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
               'Cannot store location group because it is a CWMS system item.'
            );
         END IF;
      END IF;

      ---------------------------------
      -- insert or update the record --
      ---------------------------------
      IF l_exists
      THEN
         IF NOT (l_ignore_nulls AND p_loc_group_desc IS NULL)
         THEN
            l_rec.loc_group_desc := p_loc_group_desc;
         END IF;

         IF NOT (l_ignore_nulls AND p_loc_group_attribute IS NULL)
         THEN
            l_rec.loc_group_attribute := p_loc_group_attribute;
         end if;

         IF NOT (l_ignore_nulls AND p_shared_alias_id IS NULL)
         THEN
            l_rec.shared_loc_alias_id := p_shared_alias_id;
         END IF;

         IF NOT (l_ignore_nulls AND p_shared_loc_ref_id IS NULL)
         THEN
            l_rec.shared_loc_ref_code :=
               cwms_loc.get_location_code (l_office_code,
                                           p_shared_loc_ref_id
                                          );
         END IF;

         UPDATE   at_loc_group
            SET   row = l_rec
          WHERE   loc_group_code = l_rec.loc_group_code;
      ELSE
         l_rec.loc_group_code := cwms_seq.NEXTVAL;
         l_rec.loc_category_code :=
            store_loc_category_f (p_loc_category_id,
                                  NULL,
                                  'F',
                                  'T',
                                  p_db_office_id
                                 );
         l_rec.loc_group_id := p_loc_group_id;
         l_rec.loc_group_desc := p_loc_group_desc;
         l_rec.loc_group_attribute := p_loc_group_attribute;
         l_rec.db_office_code := l_office_code;
         l_rec.shared_loc_alias_id := p_shared_alias_id;

         IF p_shared_loc_ref_id IS NOT NULL
         THEN
            l_rec.shared_loc_ref_code :=
               cwms_loc.get_location_code (l_office_code,
                                           p_shared_loc_ref_id
                                          );
         END IF;

         INSERT INTO   at_loc_group
              VALUES   l_rec;
      end if;
   END store_loc_group2;

   PROCEDURE create_loc_group (p_loc_category_id   IN VARCHAR2,
                               p_loc_group_id      IN VARCHAR2,
                               p_loc_group_desc    IN VARCHAR2 DEFAULT NULL,
                               p_db_office_id      IN VARCHAR2 DEFAULT NULL
                              )
   IS
   BEGIN
      cwms_loc.store_loc_group (p_loc_category_id,
                                p_loc_group_id,
                                p_loc_group_desc,
                                'T',
                                'F',
                                NULL,
                                NULL,
                                p_db_office_id
                               );
   END create_loc_group;


   PROCEDURE create_loc_group2 (
      p_loc_category_id     IN VARCHAR2,
      p_loc_group_id        IN VARCHAR2,
      p_loc_group_desc       IN VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN VARCHAR2 DEFAULT NULL,
      p_shared_alias_id     IN VARCHAR2 DEFAULT NULL,
      p_shared_loc_ref_id    IN VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      store_loc_group (p_loc_category_id,
                       p_loc_group_id,
                       p_loc_group_desc,
                       'T',
                       'F',
                       p_shared_alias_id,
                       p_shared_loc_ref_id,
                       p_db_office_id
                      );
   END create_loc_group2;

   PROCEDURE rename_loc_group (p_loc_category_id    IN VARCHAR2,
                               p_loc_group_id_old    IN VARCHAR2,
                               p_loc_group_id_new    IN VARCHAR2,
                               p_loc_group_desc     IN VARCHAR2 DEFAULT NULL,
                               p_ignore_null        IN VARCHAR2 DEFAULT 'T',
                               p_db_office_id       IN VARCHAR2 DEFAULT NULL
                              )
   IS
      l_db_office_id           VARCHAR2 (16);
      l_db_office_code          NUMBER;
      l_loc_category_code       NUMBER;
      l_loc_group_code          NUMBER;
      l_loc_group_id_old       VARCHAR2 (32) := TRIM (p_loc_group_id_old);
      l_loc_group_id_new       VARCHAR2 (32) := TRIM (p_loc_group_id_new);
      l_group_already_exists    BOOLEAN := FALSE;
      l_ignore_null             BOOLEAN;
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
            cwms_err.raise (
               'ITEM_DOES_NOT_EXIST',
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
         THEN                                -- or there's not a case change...
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
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
            cwms_err.raise (
               'ITEM_DOES_NOT_EXIST',
               'p_loc_group_id_old does not exist - can''t perform rename of: ',
               p_loc_group_id_old
            );
      END;

      --
      -- all checks passed, perform the rename...
      IF p_loc_group_desc IS NULL AND l_ignore_null
      THEN
         UPDATE   at_loc_group
            SET   loc_group_id = l_loc_group_id_new
          WHERE   loc_group_code = l_loc_group_code;
      ELSE
         UPDATE   at_loc_group
            SET   loc_group_id = l_loc_group_id_new,
                  loc_group_desc = TRIM (p_loc_group_desc)
          WHERE   loc_group_code = l_loc_group_code;
      END IF;
   --
   --
   END rename_loc_group;

   --
   --********************************************************************** -
   --********************************************************************** -
   --
   -- STORE_ALIAS   -
   --
   --*---------------------------------------------------------------------*-
   --
   --   PROCEDURE store_alias (
   --   p_location_id  IN VARCHAR2,
   --   p_category_id  IN VARCHAR2,
   --   p_group_id  IN VARCHAR2,
   --   p_alias_id  IN VARCHAR2,
   --   p_db_office_id IN VARCHAR2 DEFAULT NULL
   --   )
   --   IS
   --   l_loc_category_code  NUMBER;
   --   l_loc_group_code  NUMBER;
   --   l_location_code   NUMBER;
   --   l_db_office_id VARCHAR2 (16);
   --   l_db_office_code  NUMBER;
   --   l_tmp VARCHAR2 (128);
   --   BEGIN
   --   IF p_db_office_id IS NULL
   --   THEN
   --   l_db_office_id := cwms_util.user_office_id;
   --   ELSE
   --   l_db_office_id := UPPER (p_db_office_id);
   --   END IF;

   --   l_db_office_code := cwms_util.get_office_code (l_db_office_id);

   --   BEGIN
   --   l_loc_category_code :=
   --  get_loc_category_code (p_category_id, l_db_office_code);
   --   EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN
   --  cwms_err.RAISE ('GENERIC_ERROR',
   --   'The category id: '
   --  || p_category_id
   --  || ' does not exist.'
   --   );
   --   END;

   --   DBMS_OUTPUT.put_line ('gk 1');

   --   BEGIN
   --   l_loc_group_code :=
   --   get_loc_group_code (p_category_id, p_group_id, l_db_office_code);
   --   EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN
   --  cwms_err.RAISE ('GENERIC_ERROR',
   --   'There is no group: '
   --  || p_group_id
   --  || ' in the '
   --  || p_category_id
   --  || ' category.'
   --   );
   --   END;

   --   DBMS_OUTPUT.put_line ('gk 2');

   --   BEGIN
   --   l_location_code := get_location_code (p_db_office_id, p_location_id);
   --   EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN
   --  cwms_err.RAISE ('GENERIC_ERROR',
   --   'The '
   --  || p_location_id
   --  || ' location id does not exist.'
   --   );
   --   END;

   --   DBMS_OUTPUT.put_line ('gk 3');

   --   BEGIN
   --   SELECT loc_alias_id
   --   INTO l_tmp
   --   FROM at_loc_group_assignment
   --   WHERE location_code = l_location_code
   --  AND loc_group_code = l_loc_group_code;

   --   UPDATE at_loc_group_assignment
   --  SET loc_alias_id = trim(p_alias_id)
   --   WHERE location_code = l_location_code
   --  AND loc_group_code = l_loc_group_code;
   --   EXCEPTION
   --   WHEN NO_DATA_FOUND
   --   THEN
   --  INSERT INTO at_loc_group_assignment
   --  (loc_group_code, location_code, loc_alias_id
   --  )
   --   VALUES (l_loc_group_code, l_location_code, trim(p_alias_id)
   --  );
   --   END;

   ---- MERGE INTO at_loc_group_assignment a
   ---- USING (SELECT loc_group_code, location_code, loc_alias_id
   ---- FROM at_loc_group_assignment
   ---- WHERE loc_group_code = l_loc_group_code
   ---- AND location_code = l_location_code) b
   ---- ON (  a.loc_group_code = l_loc_group_code
   ---- AND a.location_code = l_location_code)
   ---- WHEN MATCHED THEN
   ---- UPDATE
   ---- SET a.loc_alias_id = p_alias_id
   ---- WHEN NOT MATCHED THEN
   ---- INSERT (loc_group_code, location_code, loc_alias_id)
   ---- VALUES (cwms_seq.NEXTVAL, l_location_code, p_alias_id);
   --   END;

   --
   --
   -- assign_groups is used to assign one or more location_id's --
   -- to a location group.
   --
   --   loc_alias_type AS OBJECT (
   --   location_id VARCHAR2 (57),
   --   loc_alias_id  VARCHAR2 (16),
   --
   PROCEDURE assign_loc_groups (p_loc_category_id    IN VARCHAR2,
                                p_loc_group_id       IN VARCHAR2,
                                p_loc_alias_array    IN loc_alias_array,
                                p_db_office_id       IN VARCHAR2 DEFAULT NULL
                               )
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code       NUMBER;
      l_loc_category_code    NUMBER;
      l_loc_group_code       NUMBER;
      l_location_code       NUMBER;
      l_cnt                 NUMBER;
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
            cwms_err.raise (
               'GENERIC_ERROR',
               'The category id: ' || p_loc_category_id || ' does not exist.'
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
            cwms_err.raise (
               'ERROR',
                  'There is no group: '
               || p_loc_group_id
               || ' in the '
               || p_loc_category_id
               || ' category.'
            );
      END;


      FOR i IN 1 .. p_loc_alias_array.COUNT
      LOOP
         check_alias_id (p_loc_alias_array (i).loc_alias_id,
                         p_loc_alias_array (i).location_id,
                         p_loc_category_id,
                         p_loc_group_id,
                         l_db_office_id
                        );
         l_location_code :=
            get_location_code (l_db_office_id,
                               p_loc_alias_array (i).location_id
                              );

         IF l_location_code IS NULL
         THEN
            cwms_err.raise (
               'ERROR',
                  'Unable to assign the Alias_ID: '
               || p_loc_alias_array (i).loc_alias_id
               || ' under the '
               || p_loc_group_id
               || ' Group in the '
               || p_loc_category_id
               || ' Location Category to the Location_ID: '
               || p_loc_alias_array (i).location_id
               || ' because that Location ID does not exist for your Office_ID: '
               || l_db_office_id
            );
         ELSE
            SELECT   COUNT (*)
              INTO   l_cnt
              FROM   at_loc_group_assignment
             WHERE   location_code = l_location_code
                     AND loc_group_code = l_loc_group_code;

            IF l_cnt = 0
            THEN
               INSERT
                 INTO   at_loc_group_assignment (location_code,
                                                 loc_group_code,
                                                 loc_attribute,
                                                 loc_alias_id,
                                                 loc_ref_code,
                                                 office_code
                                                )
               VALUES   (
                           l_location_code,
                           l_loc_group_code,
                           NULL,
                           p_loc_alias_array (i).loc_alias_id,
                           NULL,
                           l_db_office_code
                        );
            ELSE
               UPDATE   at_loc_group_assignment
                  SET   loc_attribute = NULL,
                        loc_alias_id = p_loc_alias_array (i).loc_alias_id,
                        loc_ref_code = NULL
                WHERE   location_code = l_location_code
                        AND loc_group_code = l_loc_group_code;
            END IF;
         END IF;
      END LOOP;
   --
   -- When we upgraded to 11.2.0.2.0 the update portion of this merge ran
   -- into table mutating errors because get_location_code() selects from
   -- table AT_LOC_GROUP_ASSIGNMENT
   --
   --  MERGE INTO  at_loc_group_assignment a
   --  USING  (SELECT get_location_code (l_db_office_id, plaa.location_id) location_code,
   --  plaa.loc_alias_id
   --   FROM TABLE (p_loc_alias_array) plaa) b
   --  ON  (a.loc_group_code = l_loc_group_code
   --  AND a.location_code = b.location_code)
   --  WHEN MATCHED
   --  THEN
   --  UPDATE SET
   --  a.loc_attribute = NULL,
   --  a.loc_alias_id = b.loc_alias_id,
   --  a.loc_ref_code = NULL
   --  WHEN NOT MATCHED
   --  THEN
   --  INSERT (location_code,
   --  loc_group_code,
   --  loc_attribute,
   --  loc_alias_id,
   --  loc_ref_code
   --   )
   --   VALUES  (
   --   b.location_code,
   --   l_loc_group_code,
   --   NULL,
   --   b.loc_alias_id,
   --   NULL
   --   );

   END assign_loc_groups;

   --
   -- assign_groups is used to assign one or more location_id's --
   -- to a location group.
   --
   --   loc_alias_type2 AS OBJECT (
   --   location_id VARCHAR2 (57),
   --   loc_attribute NUMBER,
   --   loc_alias_id  VARCHAR2 (128)
   --
   PROCEDURE assign_loc_groups2 (p_loc_category_id   IN VARCHAR2,
                                 p_loc_group_id      IN VARCHAR2,
                                 p_loc_alias_array   IN loc_alias_array2,
                                 p_db_office_id      IN VARCHAR2 DEFAULT NULL
                                )
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code       NUMBER;
      l_loc_category_code    NUMBER;
      l_loc_group_code       NUMBER;
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
            cwms_err.raise (
               'GENERIC_ERROR',
               'The category id: ' || p_loc_category_id || ' does not exist.'
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
            cwms_err.raise (
               'GENERIC_ERROR',
                  'There is no group: '
               || p_loc_group_id
               || ' in the '
               || p_loc_category_id
               || ' category.'
            );
      END;


      FOR i IN 1 .. p_loc_alias_array.COUNT
      LOOP
         check_alias_id (p_loc_alias_array (i).loc_alias_id,
                         p_loc_alias_array (i).location_id,
                         p_loc_category_id,
                         p_loc_group_id,
                         l_db_office_id
                        );
      END LOOP;

      MERGE INTO    at_loc_group_assignment a
           USING    (SELECT   get_location_code (l_db_office_id, plaa.location_id) location_code,
                             plaa.loc_attribute, plaa.loc_alias_id
                      FROM   TABLE (p_loc_alias_array) plaa) b
              ON    (a.loc_group_code = l_loc_group_code
                    AND a.location_code = b.location_code)
      WHEN MATCHED
      THEN
         UPDATE SET
            a.loc_attribute = b.loc_attribute,
            a.loc_alias_id = b.loc_alias_id
      WHEN NOT MATCHED
      THEN
         INSERT       (location_code,
                       loc_group_code,
                       loc_attribute,
                       loc_alias_id,
                       office_code
                      )
             VALUES    (
                         b.location_code,
                         l_loc_group_code,
                         b.loc_attribute,
                         b.loc_alias_id,
                         l_db_office_code
                      );
   END assign_loc_groups2;

   --
   -- assign_groups is used to assign one or more location_id's --
   -- to a location group.
   --
   --   loc_alias_type3 AS OBJECT (
   --   location_id VARCHAR2 (57),
   --   loc_attribute NUMBER,
   --   loc_alias_id  VARCHAR2 (128),
   --   loc_ref_id  VARCHAR2 (57)
   --
   PROCEDURE assign_loc_groups3 (p_loc_category_id   IN VARCHAR2,
                                 p_loc_group_id      IN VARCHAR2,
                                 p_loc_alias_array   IN loc_alias_array3,
                                 p_db_office_id      IN VARCHAR2 DEFAULT NULL
                                )
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code       NUMBER;
      l_loc_category_code    NUMBER;
      l_loc_group_code       NUMBER;
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
            cwms_err.raise (
               'GENERIC_ERROR',
               'The category id: ' || p_loc_category_id || ' does not exist.'
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
            cwms_err.raise (
               'GENERIC_ERROR',
                  'There is no group: '
               || p_loc_group_id
               || ' in the '
               || p_loc_category_id
               || ' category.'
            );
      END;

      FOR i IN 1 .. p_loc_alias_array.COUNT
      LOOP
         check_alias_id (p_loc_alias_array (i).loc_alias_id,
                         p_loc_alias_array (i).location_id,
                         p_loc_category_id,
                         p_loc_group_id,
                         l_db_office_id
                        );
      END LOOP;

      MERGE INTO    at_loc_group_assignment a
           USING    (SELECT   get_location_code (p_db_office_id => l_db_office_id, p_location_id => plaa.location_id, p_check_aliases => 'F') location_code,
                             plaa.loc_attribute, plaa.loc_alias_id,
                             plaa.loc_ref_id
                      FROM   TABLE (p_loc_alias_array) plaa) b
              ON    (a.loc_group_code = l_loc_group_code
                    AND a.location_code = b.location_code)
      WHEN MATCHED
      THEN
         UPDATE SET
            a.loc_attribute = b.loc_attribute,
            a.loc_alias_id = b.loc_alias_id,
            a.loc_ref_code =
               DECODE (
                  b.loc_ref_id,
                  NULL, NULL,
                  get_location_code (p_db_office_code   => l_db_office_code,
                                     p_location_id      => b.loc_ref_id,
                                     p_check_aliases    => 'F'
                                    )
               )
      WHEN NOT MATCHED
      THEN
         INSERT       (location_code,
                       loc_group_code,
                       loc_attribute,
                       loc_alias_id,
                       loc_ref_code,
                       office_code
                      )
             VALUES    (
                         b.location_code,
                         l_loc_group_code,
                         b.loc_attribute,
                         b.loc_alias_id,
                         DECODE (
                            b.loc_ref_id,
                            NULL, NULL,
                            get_location_code (
                               p_db_office_code   => l_db_office_code,
                               p_location_id      => b.loc_ref_id,
                               p_check_aliases    => 'F'
                            )
                         ),
                         l_db_office_code
                      );
   END assign_loc_groups3;

   -- creates it and will rename the aliases if they already exist.
   PROCEDURE assign_loc_group (p_loc_category_id   IN VARCHAR2,
                               p_loc_group_id      IN VARCHAR2,
                               p_location_id       IN VARCHAR2,
                               p_loc_alias_id      IN VARCHAR2 DEFAULT NULL,
                               p_db_office_id      IN VARCHAR2 DEFAULT NULL
                              )
   IS
      l_loc_alias_array   loc_alias_array
         := loc_alias_array (loc_alias_type (p_location_id, p_loc_alias_id));
   BEGIN
      assign_loc_groups (p_loc_category_id   => p_loc_category_id,
                         p_loc_group_id      => p_loc_group_id,
                         p_loc_alias_array   => l_loc_alias_array,
                         p_db_office_id      => p_db_office_id
                        );
   END assign_loc_group;

   PROCEDURE assign_loc_group2 (p_loc_category_id    IN VARCHAR2,
                                p_loc_group_id       IN VARCHAR2,
                                p_location_id       IN VARCHAR2,
                                p_loc_attribute     IN NUMBER DEFAULT NULL,
                                p_loc_alias_id       IN VARCHAR2 DEFAULT NULL,
                                p_db_office_id       IN VARCHAR2 DEFAULT NULL
                               )
   IS
      l_loc_alias_array2   loc_alias_array2
         := loc_alias_array2 (
               loc_alias_type2 (p_location_id,
                                p_loc_attribute,
                                p_loc_alias_id
                               )
            );
   BEGIN
      assign_loc_groups2 (p_loc_category_id    => p_loc_category_id,
                          p_loc_group_id       => p_loc_group_id,
                          p_loc_alias_array    => l_loc_alias_array2,
                          p_db_office_id       => p_db_office_id
                         );
   END assign_loc_group2;

   PROCEDURE assign_loc_group3 (p_loc_category_id    IN VARCHAR2,
                                p_loc_group_id       IN VARCHAR2,
                                p_location_id       IN VARCHAR2,
                                p_loc_attribute     IN NUMBER DEFAULT NULL,
                                p_loc_alias_id       IN VARCHAR2 DEFAULT NULL,
                                p_ref_loc_id        IN VARCHAR2 DEFAULT NULL,
                                p_db_office_id       IN VARCHAR2 DEFAULT NULL
                               )
   IS
      l_loc_alias_array   loc_alias_array3;
   BEGIN
      l_loc_alias_array :=
         loc_alias_array3 (
            loc_alias_type3 (
               p_location_id,
               p_loc_attribute,
               p_loc_alias_id,
               p_ref_loc_id
            )
         );
      assign_loc_groups3 (p_loc_category_id    => p_loc_category_id,
                          p_loc_group_id       => p_loc_group_id,
                          p_loc_alias_array    => l_loc_alias_array,
                          p_db_office_id       => p_db_office_id
                         );
   END assign_loc_group3;

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

   --Note that you cannot unassign group/location pairs if a group/location pair -
   --is being referenced by a SHEF decode entry.
   -------------------------------------------------------------------------------
   -------------------------------------------------------------------------------
procedure unassign_loc_groups(
   p_loc_category_id in varchar2,
   p_loc_group_id    in varchar2,
   p_location_array  in str_tab_t,
   p_unassign_all    in varchar2 default 'F',
   p_db_office_id    in varchar2 default null)
is
   l_db_office_code number;
   l_loc_group_code number;
   l_unassign_all   boolean := false;
begin
   if upper(trim(p_unassign_all)) = 'T' then
      l_unassign_all := true;
   end if;
   l_db_office_code := cwms_util.get_office_code(p_db_office_id);
   l_loc_group_code := get_loc_group_code(
            p_loc_category_id => p_loc_category_id,
            p_loc_group_id    => p_loc_group_id,
            p_db_office_code  => l_db_office_code);

   begin
      if l_unassign_all then
         -------------------------------------------
         -- delete all group/location assignments --
         -------------------------------------------
         delete
           from at_loc_group_assignment
          where loc_group_code = l_loc_group_code
            and office_code = l_db_office_code;
      else
         ----------------------------------------------------------------
         -- delete only group/location assignments for given locations --
         ----------------------------------------------------------------
         delete
           from at_loc_group_assignment
          where loc_group_code = l_loc_group_code
            and location_code in
                (select cwms_loc.get_location_code(l_db_office_code, trim(column_value))
                  from table(p_location_array)
                );
      end if;
   exception
      when others then
         cwms_err.raise(
            'ERROR',
            'Cannot unassign Location/Group pair(s). One or more group assignments are still assigned.');
   end;
end unassign_loc_groups;
   -------------------------------------------------------------------------------
   -------------------------------------------------------------------------------
   -- unassign_loc_group --
   -- See description for unassign_loc_groups above.--
   -------------------------------------------------------------------------------
   -------------------------------------------------------------------------------
   PROCEDURE unassign_loc_group (p_loc_category_id   IN VARCHAR2,
                                 p_loc_group_id      IN VARCHAR2,
                                 p_location_id        IN VARCHAR2,
                                 p_unassign_all      IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id      IN VARCHAR2 DEFAULT NULL
                                )
   IS
      l_location_array    str_tab_t
                            := str_tab_t (TRIM (p_location_id));
   BEGIN
      unassign_loc_groups (p_loc_category_id   => p_loc_category_id,
                           p_loc_group_id      => p_loc_group_id,
                           p_location_array     => l_location_array,
                           p_unassign_all      => p_unassign_all,
                           p_db_office_id      => p_db_office_id
                          );
   END unassign_loc_group;

   PROCEDURE delete_loc_group (p_loc_group_code   IN NUMBER,
                               p_cascade           IN VARCHAR2 DEFAULT 'F'
                              )
   IS
   BEGIN
      IF cwms_util.is_true (p_cascade)
      THEN
         DELETE FROM   at_loc_group_assignment
               WHERE   loc_group_code = p_loc_group_code;

         UPDATE   at_rating_spec
            SET   source_agency_code = NULL
          WHERE   source_agency_code = p_loc_group_code;
      END IF;

      --------------------------------------------------------------------
      -- delete the group (will fail if there are location assignments) --
      --------------------------------------------------------------------
      DELETE FROM   at_loc_group
            WHERE   loc_group_code = p_loc_group_code;
   END delete_loc_group;

   PROCEDURE delete_loc_group (p_loc_category_id   IN VARCHAR2,
                               p_loc_group_id      IN VARCHAR2,
                               p_cascade            IN VARCHAR2 DEFAULT 'F',
                               p_db_office_id      IN VARCHAR2 DEFAULT NULL
                              )
   IS
      l_loc_group_code    NUMBER (10);
      l_db_office_code    NUMBER := cwms_util.get_office_code (p_db_office_id);
   BEGIN
      IF l_db_office_code = cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
            'Groups owned by the CWMS office id can not be deleted.'
         );
      END IF;

      ------------------------------------------
      -- get the the category and group codes --
      ------------------------------------------
      l_loc_group_code :=
         get_loc_group_code (p_loc_category_id    => p_loc_category_id,
                             p_loc_group_id       => p_loc_group_id,
                             p_db_office_code    => l_db_office_code
                            );
      delete_loc_group (p_loc_group_code    => l_loc_group_code,
                        p_cascade          => p_cascade
                       );
   END delete_loc_group;

   -- can only delete if there are no assignments to this group.
   PROCEDURE delete_loc_group (p_loc_category_id   IN VARCHAR2,
                               p_loc_group_id      IN VARCHAR2,
                               p_db_office_id      IN VARCHAR2 DEFAULT NULL
                              )
   IS
      l_loc_group_code    NUMBER (10);
      l_db_office_code    NUMBER := cwms_util.get_office_code (p_db_office_id);
   BEGIN
      delete_loc_group (p_loc_category_id   => p_loc_category_id,
                        p_loc_group_id      => p_loc_group_id,
                        p_cascade           => 'F',
                        p_db_office_id      => p_db_office_id
                       );
   END delete_loc_group;

   PROCEDURE delete_loc_cat (p_loc_category_id    IN VARCHAR2,
                             p_cascade           IN VARCHAR2 DEFAULT 'F',
                             p_db_office_id       IN VARCHAR2 DEFAULT NULL
                            )
   IS
      l_loc_category_code    NUMBER (10);
      l_db_office_code       NUMBER;
   BEGIN
      ---------------------------
      -- get the category code --
      ---------------------------

      l_loc_category_code :=
         get_loc_category_code (
            p_loc_category_id   => p_loc_category_id,
            p_db_office_code     => cwms_util.get_office_code (p_db_office_id)
         );

      ---------------------------------------------------
      -- delete groups in this caegory if specified  --
      -- (will fail if there are location assignments) --
      ---------------------------------------------------
      IF cwms_util.is_true (p_cascade)
      THEN
         NULL;

         FOR loc_group_code_rec
            IN (SELECT    loc_group_code
                  FROM    at_loc_group
                 WHERE    loc_category_code = l_loc_category_code)
         LOOP
            delete_loc_group (
               p_loc_group_code    => loc_group_code_rec.loc_group_code,
               p_cascade             => 'T'
            );
         END LOOP;
      END IF;

      ---------------------------------------------------------------
      -- delete the category (will fail if there are still groups) --
      ---------------------------------------------------------------
      DELETE FROM   at_loc_category
            WHERE   loc_category_code = l_loc_category_code;
   END delete_loc_cat;

   PROCEDURE rename_loc_category (
      p_loc_category_id_old   IN VARCHAR2,
      p_loc_category_id_new   IN VARCHAR2,
      p_loc_category_desc      IN VARCHAR2 DEFAULT NULL,
      p_ignore_null            IN VARCHAR2 DEFAULT 'T',
      p_db_office_id          IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id              VARCHAR2 (16);
      l_db_office_code             NUMBER;
      l_loc_category_code_old     NUMBER;
      l_loc_category_code_new     NUMBER;
      l_loc_category_id_old       VARCHAR2 (32) := TRIM (p_loc_category_id_old);
      l_loc_category_id_new       VARCHAR2 (32) := TRIM (p_loc_category_id_new);
      l_category_already_exists    BOOLEAN := FALSE;
      l_ignore_null                BOOLEAN;
      l_cat_owned_by_cwms          BOOLEAN;
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
         SELECT   loc_category_code
           INTO   l_loc_category_code_old
           FROM   at_loc_category
          WHERE   UPPER (loc_category_id) = UPPER (l_loc_category_id_old)
                  AND db_office_code = (SELECT    office_code
                                          FROM    cwms_office
                                         WHERE    office_id = 'CWMS');

         l_cat_owned_by_cwms := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_cat_owned_by_cwms := FALSE;
      END;

      IF l_cat_owned_by_cwms
      THEN
         cwms_err.raise (
            'ITEM_ALREADY_EXISTS',
            'The ' || l_loc_category_id_old
            || ' category is owned by the system. You cannot rename this category.'
         );
      END IF;

      -- Is the p_loc_category_NEW owned by CWMS?...
      ---
      BEGIN
         SELECT   loc_category_code
           INTO   l_loc_category_code_new
           FROM   at_loc_category
          WHERE   UPPER (loc_category_id) = UPPER (l_loc_category_id_new)
                  AND db_office_code = (SELECT    office_code
                                          FROM    cwms_office
                                         WHERE    office_id = 'CWMS');

         l_cat_owned_by_cwms := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_cat_owned_by_cwms := FALSE;
      END;

      IF l_cat_owned_by_cwms
      THEN
         cwms_err.raise (
            'ITEM_ALREADY_EXISTS',
            'The ' || l_loc_category_id_new
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
            cwms_err.raise (
               'ITEM_DOES_NOT_EXIST',
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
         THEN                                -- or there's not a case change...
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
               'p_loc_category_id_new already exists - can''t rename to: ',
               l_loc_category_id_old
            );
         END IF;
      END IF;

      --
      -- all checks passed, perform the rename...
      IF p_loc_category_desc IS NULL AND l_ignore_null
      THEN
         UPDATE   at_loc_category
            SET   loc_category_id = l_loc_category_id_new
          WHERE   loc_category_code = l_loc_category_code_old;
      ELSE
         UPDATE   at_loc_category
            SET   loc_category_id = l_loc_category_id_new,
                  loc_category_desc = TRIM (p_loc_category_desc)
          WHERE   loc_category_code = l_loc_category_code_old;
      END IF;
   --
   --
   END rename_loc_category;

   --
   -- used to assign one or more groups to an existing category.
   --
   PROCEDURE assign_loc_grps_cat3 (
      p_loc_category_id   IN VARCHAR2,
      p_loc_group_array   IN group_array3,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_db_office_id        VARCHAR2 (16);
      l_db_office_code       NUMBER;
      l_loc_category_code    NUMBER;
      l_loc_group_code       NUMBER;
      l_loc_category_id     VARCHAR2 (32) := TRIM (p_loc_category_id);
      l_loc_group_id        VARCHAR2 (32);
      l_loc_group_desc       VARCHAR2 (128);
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
         cwms_err.raise ('GENERIC_ERROR',
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
               SELECT   loc_group_code
                 INTO   l_loc_group_code
                 FROM   at_loc_group
                WHERE       UPPER (loc_group_id) = UPPER (l_loc_group_id)
                        AND loc_category_code = l_loc_category_code
                        AND db_office_code = l_db_office_code;

               UPDATE   at_loc_group
                  SET   loc_group_id = l_loc_group_id,
                        loc_group_desc = l_loc_group_desc,
                        loc_group_attribute = p_loc_group_array(i).group_attribute,
                        shared_loc_alias_id =
                           p_loc_group_array (i).shared_alias_id,
                        shared_loc_ref_code =
                           get_location_code (
                              l_db_office_code,
                              p_loc_group_array (i).shared_loc_ref_id
                           )
                WHERE   loc_group_code = l_loc_group_code;

               l_loc_group_code := NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     --
                     -- Check if the group_id is a CWMS owned -
                     -- group_id, if it is, do nothing...
                     SELECT   loc_group_code
                       INTO   l_loc_group_code
                       FROM   at_loc_group
                      WHERE   UPPER (loc_group_id) = UPPER (l_loc_group_id)
                              AND loc_category_code = l_loc_category_code
                              AND db_office_code =
                                     cwms_util.db_office_code_all;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        --
                        -- Insert a new group_id...
                        INSERT
                          INTO   at_loc_group (loc_group_code,
                                               loc_category_code,
                                               loc_group_id,
                                               loc_group_desc,
                                               loc_group_attribute,
                                               shared_loc_alias_id,
                                               shared_loc_ref_code,
                                               db_office_code
                                              )
                        VALUES   (
                                    cwms_seq.NEXTVAL,
                                    l_loc_category_code,
                                    l_loc_group_id,
                                    l_loc_group_desc,
                                    p_loc_group_array(i).group_attribute,
                                    l_db_office_code,
                                    p_loc_group_array(i).shared_alias_id,
                                    get_location_code (
                                       l_db_office_code,
                                       p_loc_group_array (i).shared_loc_ref_id
                                    )
                                 );
                  END;
            END;
         END LOOP;
      end if;
   END assign_loc_grps_cat3;

   --
   -- used to assign a group to an existing category.
   --
   PROCEDURE assign_loc_grp_cat3 (
		p_loc_category_id 	 IN VARCHAR2,
		p_loc_group_id 		 IN VARCHAR2,
		p_loc_group_desc		 IN VARCHAR2 DEFAULT NULL,
      p_loc_group_attribute IN NUMBER DEFAULT NULL,
		p_shared_alias_id 	 IN VARCHAR2 DEFAULT NULL,
		p_shared_loc_ref_id	 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_loc_group_array   group_array3
         := group_array3 (
               group_type3 (TRIM (p_loc_group_id),
                            TRIM (P_LOC_GROUP_DESC),
                            p_loc_group_attribute,
                            p_shared_alias_id,
                            p_shared_loc_ref_id
                           )
            );
   BEGIN
      assign_loc_grps_cat3 (p_loc_category_id,
                            l_loc_group_array,
                            p_db_office_id
                           );
   END assign_loc_grp_cat3;
   --
   -- used to assign one or more groups to an existing category.
   --
   PROCEDURE assign_loc_grps_cat2 (
      p_loc_category_id   IN VARCHAR2,
      p_loc_group_array   IN group_array2,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_loc_group_array   group_array3 := group_array3 ();
   BEGIN
      l_loc_group_array.EXTEND (p_loc_group_array.COUNT);

      FOR i IN 1 .. p_loc_group_array.COUNT
      LOOP
         l_loc_group_array (i) :=
            group_type3 (p_loc_group_array (i).GROUP_ID,
                         p_loc_group_array (i).group_desc,
                         NULL,
                         p_loc_group_array (i).shared_alias_id,
                         p_loc_group_array (i).shared_loc_ref_id
                        );
      END LOOP;

      assign_loc_grps_cat3 (p_loc_category_id,
                            l_loc_group_array,
                            p_db_office_id
                           );
   END assign_loc_grps_cat2;

   --
   -- used to assign a group to an existing category.
   --
   PROCEDURE assign_loc_grp_cat2 (
      p_loc_category_id     IN VARCHAR2,
      p_loc_group_id        IN VARCHAR2,
      p_loc_group_desc       IN VARCHAR2 DEFAULT NULL,
      p_shared_alias_id     IN VARCHAR2 DEFAULT NULL,
      p_shared_loc_ref_id    IN VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_loc_group_array   group_array3
         := group_array3 (
               group_type3 (TRIM (p_loc_group_id),
                            trim (p_loc_group_desc),
                            null,
                            p_shared_alias_id,
                            p_shared_loc_ref_id
                           )
            );
   BEGIN
      assign_loc_grps_cat3 (p_loc_category_id,
                            l_loc_group_array,
                            p_db_office_id
                           );
   end assign_loc_grp_cat2;

   --
   -- used to assign one or more groups to an existing category.
   --
   PROCEDURE assign_loc_grps_cat (
      p_loc_category_id   IN VARCHAR2,
      p_loc_group_array   IN group_array,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL
   )
   IS
      l_loc_group_array   group_array3 := group_array3 ();
   BEGIN
      l_loc_group_array.EXTEND (p_loc_group_array.COUNT);

      FOR i IN 1 .. p_loc_group_array.COUNT
      LOOP
         l_loc_group_array (i) :=
            group_type3 (p_loc_group_array (i).GROUP_ID,
                         p_loc_group_array (i).group_desc,
                         NULL,
                         NULL,
                         NULL
                        );
      END LOOP;

      assign_loc_grps_cat3 (p_loc_category_id,
                            l_loc_group_array,
                            p_db_office_id
                           );
   END assign_loc_grps_cat;

   --
   -- used to assign a group to an existing category.
   --
   PROCEDURE assign_loc_grp_cat (
      p_loc_category_id   IN VARCHAR2,
      p_loc_group_id      IN VARCHAR2,
      p_loc_group_desc     IN VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      assign_loc_grp_cat3 (p_loc_category_id     => p_loc_category_id,
                           p_loc_group_id        => p_loc_group_id,
                           p_loc_group_desc      => p_loc_group_desc,
                           p_loc_group_attribute => null,
                           p_shared_alias_id     => NULL,
                           p_shared_loc_ref_id   => NULL,
                           p_db_office_id        => p_db_office_id
                          );
   END assign_loc_grp_cat;

   FUNCTION retrieve_location (p_location_code IN NUMBER)
      RETURN location_obj_t
   IS
      l_location_obj   location_obj_t := NULL;
      l_location_ref   location_ref_t := NULL;

      FUNCTION elev_unit (p_office_id IN VARCHAR2)
         RETURN VARCHAR2
      IS
         l_unit     VARCHAR2 (16);
         l_factor   NUMBER;
      BEGIN
         cwms_util.user_display_unit (l_unit,
                                      l_factor,
                                      'Elev',
                                      1.0,
                                      NULL,
                                      p_office_id
                                     );
         RETURN l_unit;
      END;

      FUNCTION elev_factor (p_office_id IN VARCHAR2)
         RETURN NUMBER
      IS
         l_unit     VARCHAR2 (16);
         l_factor   NUMBER;
      BEGIN
         cwms_util.user_display_unit (l_unit,
                                      l_factor,
                                      'Elev',
                                      1.0,
                                      NULL,
                                      p_office_id
                                     );
         RETURN l_factor;
      END;
   BEGIN
      FOR rec IN (SELECT   o.office_id office_id, o.office_code office_code,
                           pl.location_code location_code,
                           bl.base_location_id base_location_id,
                           pl.sub_location_id sub_location_id,
                           s.state_initial state_initial,
                           c.county_name county_name,
                           tz.time_zone_name time_zone_name,
                           pl.location_type location_type,
                           pl.latitude latitude, pl.longitude longitude,
                           pl.horizontal_datum horizontal_datum,
                           pl.elevation elevation,
                           pl.vertical_datum vertical_datum,
                           pl.public_name public_name, pl.long_name long_name,
                           pl.description description,
                           pl.active_flag active_flag,
                           lk.location_kind_id location_kind_id,
                           pl.map_label map_label,
                           pl.published_latitude published_latitude,
                           pl.published_longitude published_longitude,
                           o2.office_id bounding_office_id,
                           o2.public_name bounding_office_name,
                           n.nation_id nation_id,
                           pl.nearest_city nearest_city
                    FROM   at_physical_location pl
                           LEFT OUTER JOIN at_base_location bl
                              ON (pl.base_location_code =
                                     bl.base_location_code)
                           LEFT OUTER JOIN cwms_location_kind lk
                              ON (pl.location_kind = lk.location_kind_code)
                           LEFT OUTER JOIN cwms_time_zone tz
                              ON (pl.time_zone_code = tz.time_zone_code)
                           LEFT OUTER JOIN cwms_county c
                              ON (pl.county_code = c.county_code)
                           LEFT OUTER JOIN cwms_state s
                              ON (c.state_code = s.state_code)
                           LEFT OUTER JOIN cwms_nation n
                              ON (pl.nation_code = n.nation_code)
                           LEFT OUTER JOIN cwms_office o
                              ON (bl.db_office_code = o.office_code)
                           LEFT OUTER JOIN cwms_office o2
                              ON (pl.office_code = o2.office_code)
                   WHERE   pl.location_code = p_location_code)
      LOOP
         l_location_ref :=
            NEW location_ref_t (rec.base_location_id,
                                rec.sub_location_id,
                                rec.office_id
                               );
         l_location_obj :=
            NEW location_obj_t (l_location_ref,
                                rec.state_initial,
                                rec.county_name,
                                rec.time_zone_name,
                                rec.location_type,
                                rec.latitude,
                                rec.longitude,
                                rec.horizontal_datum,
                                rec.elevation * elev_factor (rec.office_id),
                                elev_unit (rec.office_id),
                                rec.vertical_datum,
                                rec.public_name,
                                rec.long_name,
                                rec.description,
                                rec.active_flag,
                                rec.location_kind_id,
                                rec.map_label,
                                rec.published_latitude,
                                rec.published_longitude,
                                rec.bounding_office_id,
                                rec.bounding_office_name,
                                rec.nation_id,
                                rec.nearest_city
                               );
      END LOOP;

      RETURN l_location_obj;
   END retrieve_location;

   FUNCTION retrieve_location (p_location_id    IN VARCHAR2,
                               p_db_office_id   IN VARCHAR2 DEFAULT NULL
                              )
      RETURN location_obj_t
   IS
   BEGIN
      RETURN retrieve_location (
                get_location_code (p_db_office_id, p_location_id)
             );
   END retrieve_location;

   PROCEDURE store_location (p_location         IN location_obj_t,
                             p_fail_if_exists   IN VARCHAR2 DEFAULT 'T'
                            )
   IS
      l_location_code   NUMBER;
   BEGIN
      l_location_code := store_location_f (p_location, p_fail_if_exists);
   END store_location;

   FUNCTION store_location_f (p_location          IN location_obj_t,
                              p_fail_if_exists    IN VARCHAR2 DEFAULT 'T'
                             )
      RETURN NUMBER
   IS
      l_location_code         NUMBER;
      location_id_not_found   EXCEPTION;
      PRAGMA EXCEPTION_INIT (location_id_not_found, -20025);
   BEGIN
      BEGIN
         l_location_code :=
            cwms_loc.get_location_code (
               p_location.location_ref.get_office_id,
               p_location.location_ref.get_location_id
            );
      EXCEPTION
         WHEN location_id_not_found
         THEN
            NULL;
      END;

      IF l_location_code IS NOT NULL
      THEN
         IF cwms_util.is_true (p_fail_if_exists)
         THEN
            cwms_err.raise ('LOCATION_ID_ALREADY_EXISTS',
                            p_location.location_ref.get_office_id,
                            p_location.location_ref.get_location_id
                           );
         END IF;
      END IF;

      cwms_loc.store_location2 (p_location.location_ref.get_location_id,
                                p_location.location_type,
                                p_location.elevation,
                                p_location.elev_unit_id,
                                p_location.vertical_datum,
                                p_location.latitude,
                                p_location.longitude,
                                p_location.horizontal_datum,
                                p_location.public_name,
                                p_location.long_name,
                                p_location.description,
                                p_location.time_zone_name,
                                p_location.county_name,
                                p_location.state_initial,
                                p_location.active_flag,
                                p_location.location_kind_id,
                                p_location.map_label,
                                p_location.published_latitude,
                                p_location.published_longitude,
                                p_location.bounding_office_id,
                                p_location.nation_id,
                                p_location.nearest_city,
                                'T',
                                p_location.location_ref.get_office_id
                               );

      l_location_code :=
         cwms_loc.get_location_code (p_location.location_ref.get_office_id,
                                     p_location.location_ref.get_location_id
                                    );

      RETURN l_location_code;
   END store_location_f;


   function get_location_id_from_alias (
      p_alias_id       in varchar2,
      p_group_id       in varchar2 default null,
      p_category_id    in varchar2 default null,
      p_office_id     in varchar2 default null)
      return varchar2
   is
      l_office_code   number(10);
      l_location_code number(10);
      l_office_id     varchar2(16);
      l_location_id   varchar2(57);
      l_parts         str_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code(upper(trim(p_office_id)));
      select office_id into l_office_id from cwms_office where office_code = l_office_code;

      -----------------------------------------
      -- retrieve and return the location id --
      -----------------------------------------
      begin
         select distinct
                a.location_code
           into l_location_code
           from at_loc_group_assignment a,
                at_loc_group g,
                at_loc_category c
          where a.office_code = l_office_code
            and g.loc_group_code = a.loc_group_code
            and c.loc_category_code = g.loc_category_code
            and upper(a.loc_alias_id) = upper(trim(p_alias_id))
            and upper(g.loc_group_id) = upper(trim(nvl(p_group_id, g.loc_group_id)))
            and upper(c.loc_category_id) = upper(trim(nvl(p_category_id, c.loc_category_id)));
      exception
         when no_data_found then
            -----------------------------------------------
            -- perhaps only the base location is aliased --
            -----------------------------------------------
            l_parts := cwms_util.split_text(trim(p_alias_id), '-', 1);
            if (l_parts.count = 2) then
               l_location_id := get_location_id_from_alias(l_parts(1), p_group_id, p_category_id, l_office_id);
               if l_location_id is not null then
                  begin
                     select distinct
                            location_id
                       into l_location_id
                       from cwms_v_loc
                      where location_id = l_location_id || '-' || trim(l_parts(2))
                        and db_office_id = l_office_id;
                  exception
                     when no_data_found then
                        l_location_id := null;
                  end;
               end if;
            end if;
         when too_many_rows then
            cwms_err.raise (
               'ERROR',
               'Alias (' || p_alias_id || ') matches more than one location.');
      end;

      if l_location_id is null and l_location_code is not null then
         l_location_id := cwms_loc.get_location_id(l_location_code);
      end if;
      return l_location_id;
   end get_location_id_from_alias;


   function get_location_code_from_alias (
      p_alias_id    in varchar2,
      p_group_id    in varchar2 default null,
      p_category_id in varchar2 default null,
      p_office_id   in varchar2 default null)
      return number
   is
      l_location_code number(10);
      l_location_id   varchar2(256);
      l_office_id     varchar2(16);
   begin
      -------------------
      -- sanity checks --
      -------------------
      l_office_id := cwms_util.get_db_office_id(p_office_id);

      l_location_id := get_location_id_from_alias(p_alias_id, p_group_id, p_category_id, l_office_id);
      if l_location_id is not null then
         l_location_code := cwms_loc.get_location_code(
            p_db_office_id  => l_office_id,
            p_location_id   => l_location_id,
            p_check_aliases => 'F');
      end if;

      return l_location_code;

   end get_location_code_from_alias;

   procedure check_alias_id (p_alias_id      in varchar2,
                             p_location_id   in varchar2,
                             p_category_id   in varchar2,
                             p_group_id      in varchar2,
                             p_office_id      in varchar2 default null
                            )
   is
      location_id_not_found exception;
      pragma exception_init(location_id_not_found, -20025);
      l_location_id    varchar2(57);
      l_location_code  number(10);
      l_office_id      varchar2(16);
      l_count          pls_integer;
      l_multiple_ids   boolean := false;
      l_property_id    varchar2(256);
   begin
      l_office_id := cwms_util.get_db_office_id(p_office_id);

      -----------------------------------------------------------
      -- first, check for multiple locations in the same group --
      -----------------------------------------------------------
      if p_alias_id is not null and p_category_id is not null and p_group_id is not null then
         l_location_code := nvl(get_location_code(l_office_id, p_location_id, 'F'), -1);
         begin
            select count(*)
              into l_count
              from at_loc_category c,
                   at_loc_group g,
                   at_loc_group_assignment a
             where upper(c.loc_category_id) = upper(p_category_id)
               and upper(g.loc_group_id) = upper(p_group_id)
               and upper(a.loc_alias_id) = upper(p_alias_id)
               and a.location_code != l_location_code
               and g.loc_category_code = c.loc_category_code
               and a.loc_group_code = g.loc_group_code;
         exception
            when no_data_found then
               l_count := 0;
         end;

         if l_count > 0 then
            cwms_err.raise (
               'ERROR',
               'Alias '
               || p_alias_id
               || ' is already in use in location office/category/group ('
               || l_office_id
               || '/'
               || p_category_id
               || '/'
               || p_group_id
               || ').');
         end if;
      end if;

      -----------------------------------------------------------
      -- next, see if the alias is already a location id or is --
      -- used in another group to references anothter location --
      -----------------------------------------------------------
      begin
         l_location_id  := get_location_id(p_alias_id, p_office_id);
      exception
         when location_id_not_found then
            null;
         when too_many_rows then
            l_multiple_ids := true;
      end;
      l_multiple_ids := l_multiple_ids or (l_location_id is not null and upper(l_location_id) != upper(p_location_id));

      if l_multiple_ids then
         l_property_id := 'Allow_multiple_locations_for_alias';

         if not cwms_util.is_true(cwms_properties.get_property('CWMSDB', l_property_id, 'F', l_office_id)) then
            cwms_err.raise(
               'ERROR',
               'Alias ('
               || p_alias_id
               || ') would reference multiple locations.  '
               || 'If you want to allow this, set the CWMSDB/'
               || l_property_id
               || ' '
               || 'property to ''T'' for office id '
               || l_office_id
               || '.  Note that this action will '
               || 'eliminate the ability to look up a location using the alias or any others that '
               || 'reference multiple locations.'
            );
         end if;
      end if;
   end check_alias_id;

   FUNCTION check_alias_id_f (p_alias_id       IN VARCHAR2,
                              p_location_id    IN VARCHAR2,
                              p_category_id    IN VARCHAR2,
                              p_group_id       IN VARCHAR2,
                              p_office_id     IN VARCHAR2 DEFAULT NULL
                             )
      RETURN VARCHAR2
   IS
   BEGIN
      check_alias_id (p_alias_id,
                      p_location_id,
                      p_category_id,
                      p_group_id,
                      p_office_id
                     );
      RETURN p_alias_id;
   END check_alias_id_f;

   PROCEDURE store_url (p_location_id       IN VARCHAR2,
                        p_url_id           IN VARCHAR2,
                        p_url_address       IN VARCHAR2,
                        p_fail_if_exists    IN VARCHAR2,
                        p_ignore_nulls     IN VARCHAR2,
                        p_url_title        IN VARCHAR2 DEFAULT NULL,
                        p_office_id        IN VARCHAR2 DEFAULT NULL
                       )
   IS
      l_fail_if_exists    BOOLEAN;
      l_ignore_nulls     BOOLEAN;
      l_exists           BOOLEAN;
      l_rec              at_location_url%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Location identifier must not be null.');
      END IF;

      IF p_url_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'URL identifier must not be null.');
      END IF;

      ------------------------------
      -- see if the record exists --
      ------------------------------
      l_rec.location_code := get_location_code (p_office_id, p_location_id);
      l_rec.url_id := p_url_id;

      BEGIN
         SELECT   *
           INTO   l_rec
           FROM   at_location_url
          WHERE   location_code = l_rec.location_code
                  AND url_id = l_rec.url_id;

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise (
               'ITEM_ALREADY_EXISTS',
               'CWMS Location URL',
                  NVL (UPPER (p_office_id), cwms_util.user_office_id)
               || '/'
               || p_location_id
               || '/'
               || p_url_id
            );
         END IF;
      ELSE
         IF p_url_address IS NULL
         THEN
            cwms_err.raise ('ERROR',
                            'URL address must not be null on new record.'
                           );
         END IF;
      END IF;

      -------------------------
      -- populate the record --
      -------------------------
      IF p_url_address IS NOT NULL
      THEN
         l_rec.url_address := p_url_address;
      END IF;

      IF p_url_title IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.url_title := p_url_title;
      END IF;

      ---------------------------------
      -- insert or update the record --
      ---------------------------------
      IF l_exists
      THEN
         UPDATE   at_location_url
            SET   row = l_rec
          WHERE   location_code = l_rec.location_code
                  AND url_id = l_rec.url_id;
      ELSE
         INSERT INTO   at_location_url
              VALUES   l_rec;
      END IF;
   END store_url;

   PROCEDURE retrieve_url (p_url_address       OUT VARCHAR2,
                           p_url_title        OUT VARCHAR2,
                           p_location_id    IN     VARCHAR2,
                           p_url_id        IN     VARCHAR2,
                           p_office_id     IN     VARCHAR2 DEFAULT NULL
                          )
   IS
      l_rec   at_location_url%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Location identifier must not be null.');
      END IF;

      IF p_url_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'URL identifier must not be null.');
      END IF;

      -------------------------
      -- retrieve the record --
      -------------------------
      l_rec.location_code := get_location_code (p_office_id, p_location_id);
      l_rec.url_id := p_url_id;

      BEGIN
         SELECT   *
           INTO   l_rec
           FROM   at_location_url
          WHERE   location_code = l_rec.location_code
                  AND url_id = l_rec.url_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ITEM_DOES_NOT_EXIST',
               'CWMS Location URL',
                  NVL (UPPER (p_office_id), cwms_util.user_office_id)
               || '/'
               || p_location_id
               || '/'
               || p_url_id
            );
      END;

      ---------------------------
      -- set the out variables --
      ---------------------------
      p_url_address := l_rec.url_address;
      p_url_title := l_rec.url_title;
   END retrieve_url;

   PROCEDURE delete_url (p_location_id   IN VARCHAR2,
                         p_url_id        IN VARCHAR2,       -- NULL = all urls
                         p_office_id     IN VARCHAR2 DEFAULT NULL
                        )
   IS
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Location identifier must not be null.');
      END IF;

      ---------------------
      -- delete the urls --
      ---------------------
      BEGIN
         DELETE FROM   at_location_url
               WHERE   location_code =
                          get_location_code (p_office_id, p_location_id)
                       AND url_id = NVL (p_url_id, url_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ITEM_DOES_NOT_EXIST',
               'CWMS Location URL',
                  NVL (UPPER (p_office_id), cwms_util.user_office_id)
               || '/'
               || p_location_id
               || '/'
               || NVL (p_url_id, '<any>')
            );
      END;
   END delete_url;

   PROCEDURE rename_url (p_location_id   IN VARCHAR2,
                         p_old_url_id     IN VARCHAR2,
                         p_new_url_id     IN VARCHAR2,
                         p_office_id     IN VARCHAR2 DEFAULT NULL
                        )
   IS
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Location identifier must not be null.');
      END IF;

      IF p_old_url_id IS NULL
      THEN
         cwms_err.raise ('ERROR',
                         'Existing URL identifier must not be null.'
                        );
      END IF;

      IF p_new_url_id IS NULL
      THEN
         cwms_err.raise ('ERROR', 'New URL identifier must not be null.');
      END IF;

      --------------------
      -- rename the url --
      --------------------
      BEGIN
         UPDATE   at_location_url
            SET   url_id = p_new_url_id
          WHERE   location_code =
                     get_location_code (p_office_id, p_location_id)
                  AND url_id = p_old_url_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ITEM_DOES_NOT_EXIST',
               'CWMS Location URL',
                  NVL (UPPER (p_office_id), cwms_util.user_office_id)
               || '/'
               || p_location_id
               || '/'
               || p_old_url_id
            );
      END;
   END rename_url;

   PROCEDURE cat_urls (p_url_catalog           OUT SYS_REFCURSOR,
                       p_location_id_mask   IN      VARCHAR2 DEFAULT '*',
                       p_url_id_mask        IN      VARCHAR2 DEFAULT '*',
                       p_url_address_mask   IN      VARCHAR2 DEFAULT '*',
                       p_url_title_mask     IN      VARCHAR2 DEFAULT '*',
                       p_office_id_mask     IN      VARCHAR2 DEFAULT NULL
                      )
   IS
      l_location_id_mask   VARCHAR2 (57);
      l_url_id_mask         VARCHAR2 (32);
      l_url_address_mask   VARCHAR2 (1024);
      l_url_title_mask      VARCHAR2 (256);
      l_office_id_mask      VARCHAR2 (16);
   BEGIN
      ----------------------
      -- set up the masks --
      ----------------------
      l_location_id_mask :=
         cwms_util.normalize_wildcards (UPPER (p_location_id_mask));
      l_url_id_mask := cwms_util.normalize_wildcards (UPPER (p_url_id_mask));
      l_url_address_mask :=
         cwms_util.normalize_wildcards (UPPER (p_url_address_mask));
      l_url_title_mask :=
         cwms_util.normalize_wildcards (UPPER (p_url_title_mask));
      l_office_id_mask :=
         cwms_util.normalize_wildcards (
            UPPER (NVL (p_url_address_mask, cwms_util.user_office_id))
         );

      -----------------------
      -- perform the query --
      -----------------------
      OPEN p_url_catalog FOR
         SELECT     o.office_id,
                    bl.base_location_id || SUBSTR ('-', 1, LENGTH (pl.sub_location_id)) || pl.sub_location_id AS location_id,
                    lu.url_id, lu.url_address, lu.url_title
             FROM   at_location_url lu,
                    at_physical_location pl,
                    at_base_location bl,
                    cwms_office o
            WHERE       o.office_id LIKE l_office_id_mask ESCAPE '\'
                    AND bl.db_office_code = o.office_code
                    AND pl.base_location_code = bl.base_location_code
                    AND UPPER (
                              bl.base_location_id
                           || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                           || pl.sub_location_id
                        ) LIKE
                           l_location_id_mask ESCAPE '\'
                    AND lu.location_code = pl.location_code
                    AND UPPER (lu.url_id) LIKE l_url_id_mask ESCAPE '\'
                    AND UPPER (lu.url_address) LIKE
                           l_url_address_mask ESCAPE '\'
                    AND UPPER (lu.url_title) LIKE l_url_title_mask ESCAPE '\'
         ORDER BY   o.office_id,
                    bl.base_location_id,
                    pl.sub_location_id NULLS FIRST,
                    lu.url_id;
   END cat_urls;

   FUNCTION cat_urls_f (p_location_id_mask   IN VARCHAR2 DEFAULT '*',
                        p_url_id_mask         IN VARCHAR2 DEFAULT '*',
                        p_url_address_mask   IN VARCHAR2 DEFAULT '*',
                        p_url_title_mask      IN VARCHAR2 DEFAULT '*',
                        p_office_id_mask      IN VARCHAR2 DEFAULT NULL
                       )
      RETURN SYS_REFCURSOR
   IS
      l_cursor   SYS_REFCURSOR;
   BEGIN
      cat_urls (l_cursor,
                p_location_id_mask,
                p_url_id_mask,
                p_url_address_mask,
                p_url_title_mask,
                p_office_id_mask
               );

      RETURN l_cursor;
   END cat_urls_f;

   function get_loc_kind_names(
      p_location_code in number)
      return str_tab_t
   is
      l_table_types str_tab_tab_t := str_tab_tab_t(
         str_tab_t('AT_STREAM_LOCATION', 'LOCATION_CODE',              'STREAM_LOCATION'),
         str_tab_t('AT_GAGE',            'GAGE_LOCATION_CODE',         'WEATHER_GAGE'),
         str_tab_t('AT_EMBANKMENT',      'EMBANKMENT_LOCATION_CODE',   'EMBANKMENT'), -- can also be stream location
         str_tab_t('AT_LOCK',            'LOCK_LOCATION_CODE',         'LOCK'),       -- can also be stream location
         str_tab_t('AT_PROJECT',         'PROJECT_LOCATION_CODE',      'PROJECT'),    -- can also be stream location
         str_tab_t('AT_OUTLET',          'OUTLET_LOCATION_CODE',       'OUTLET'),     -- can also be stream location
         str_tab_t('AT_TURBINE',         'TURBINE_LOCATION_CODE',      'TURBINE'),    -- can also be stream location
         str_tab_t('AT_BASIN',           'BASIN_LOCATION_CODE',        'BASIN'),
         str_tab_t('AT_STREAM',          'STREAM_LOCATION_CODE',       'STREAM'),
         str_tab_t('AT_ENTITY_LOCATION', 'LOCATION_CODE',              'ENTITY'),
         str_tab_t('AT_STREAM_REACH',    'STREAM_REACH_LOCATION_CODE', 'STREAM_REACH'),
         str_tab_t('AT_OVERFLOW',        'OVERFLOW_LOCATION_CODE',     'OVERFLOW'),
         str_tab_t('AT_PUMP',            'PUMP_LOCATION_CODE',         'PUMP'));
      l_type_names str_tab_t := str_tab_t();
      l_count      pls_integer;
   begin
      ----------------
      -- first pass --
      ----------------
      for i in 1..l_table_types.count loop
         execute immediate 'select count(*) from '||l_table_types(i)(1)||' where '||l_table_types(i)(2)||' = :1'
            into l_count
           using p_location_code;
         if case
            when l_table_types(i)(1)  = 'AT_GAGE' and l_count > 0 then 1
            when l_table_types(i)(1) != 'AT_GAGE' and l_count = 1 then 1
            else 0
            end  = 1
         then
            l_type_names.extend;
            l_type_names(l_type_names.count) := l_table_types(i)(3);
         end if;
      end loop;
      -----------------------------------------------------
      -- change WEATHER_GAGE to STREAM_GAGE if necessary --
      -----------------------------------------------------
      for i in 1..l_type_names.count loop
         if l_type_names(i) = 'WEATHER_GAGE' then
            for j in 1..l_type_names.count loop
               if l_type_names(j) = 'STREAM_LOCATION' then
                  l_type_names(i) := 'STREAM_GAGE';
                  exit;
               end if;
            end loop;
            exit;
         end if;
      end loop;
      --------------------
      -- check for GATE --
      --------------------
      <<outer_loop>>
      for i in 1..l_type_names.count loop
         if l_type_names(i) = 'OUTLET' then
            for j in 1..l_type_names.count loop
               exit outer_loop when l_type_names(j) = 'OVERFLOW';
            end loop;
            select count(*)
              into l_count
              from at_loc_group_assignment lga,
                   at_gate_group gg
             where lga.location_code = p_location_code
               and gg.loc_group_code = lga.loc_group_code;
            if l_count > 0 then
               l_type_names.extend;
               l_type_names(l_type_names.count) := 'GATE';
            end if;
            exit;
         end if;
      end loop;

      return l_type_names;
   end get_loc_kind_names;

   function check_location_kind(
      p_location_code in number)
      return varchar2
   is
      type valid_combination_tab_t is table of str_tab_tab_t index by varchar2(32);
      l_type_names         str_tab_t := str_tab_t();
      l_count              pls_integer;
      l_location_kind_id   varchar2(32);
      l_valid_combinations valid_combination_tab_t;
      l_temp               str_tab_t;
      l_kind_ids           varchar2(32767);
   begin
      l_valid_combinations('BASIN'          ) := str_tab_tab_t(str_tab_t('BASIN'                                                              ));
      l_valid_combinations('EMBANKMENT'     ) := str_tab_tab_t(str_tab_t('EMBANKMENT'                                                         ),
                                                               str_tab_t('EMBANKMENT',     'WEATHER_GAGE'                                     ),
                                                               str_tab_t('EMBANKMENT',     'STREAM_LOCATION'                                  ),
                                                               str_tab_t('EMBANKMENT',     'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('ENTITY'         ) := str_tab_tab_t(str_tab_t('ENTITY'                                                             ),
                                                               str_tab_t('ENTITY',         'WEATHER_GAGE'                                     ),
                                                               str_tab_t('ENTITY',         'STREAM_LOCATION'                                  ),
                                                               str_tab_t('ENTITY',         'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('GATE'           ) := str_tab_tab_t(str_tab_t('GATE',           'OUTLET'                                           ),
                                                               str_tab_t('GATE',           'OUTLET',          'WEATHER_GAGE'                  ),
                                                               str_tab_t('GATE',           'OUTLET',          'STREAM_LOCATION'               ),
                                                               str_tab_t('GATE',           'OUTLET',          'STREAM_LOCATION', 'STREAM_GAGE'));
      l_valid_combinations('LOCK'           ) := str_tab_tab_t(str_tab_t('LOCK'                                                               ),
                                                               str_tab_t('LOCK',           'WEATHER_GAGE'                                     ),
                                                               str_tab_t('LOCK',           'STREAM_LOCATION'                                  ),
                                                               str_tab_t('LOCK',           'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('OUTLET'         ) := str_tab_tab_t(str_tab_t('OUTLET'                                                             ),
                                                               str_tab_t('OUTLET',         'WEATHER_GAGE'                                     ),
                                                               str_tab_t('OUTLET',         'STREAM_LOCATION'                                  ),
                                                               str_tab_t('OUTLET',         'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('OVERFLOW'       ) := str_tab_tab_t(str_tab_t('OVERFLOW',       'OUTLET'                                           ),
                                                               str_tab_t('OVERFLOW',       'OUTLET',          'WEATHER_GAGE'                  ),
                                                               str_tab_t('OVERFLOW',       'OUTLET',          'STREAM_LOCATION'               ),
                                                               str_tab_t('OVERFLOW',       'OUTLET',          'STREAM_LOCATION', 'STREAM_GAGE'));
      l_valid_combinations('PROJECT'        ) := str_tab_tab_t(str_tab_t('PROJECT'                                                            ),
                                                               str_tab_t('PROJECT',        'WEATHER_GAGE'                                     ),
                                                               str_tab_t('PROJECT',        'STREAM_LOCATION'                                  ),
                                                               str_tab_t('PROJECT',        'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('PUMP'           ) := str_tab_tab_t(str_tab_t('PUMP',           'STREAM_LOCATION'                                  ),
                                                               str_tab_t('PUMP',           'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('STREAM'         ) := str_tab_tab_t(str_tab_t('STREAM'                                                             ));
      l_valid_combinations('STREAM_GAGE'    ) := str_tab_tab_t(str_tab_t('STREAM_GAGE',    'STREAM_LOCATION'                                  ));
      l_valid_combinations('STREAM_LOCATION') := str_tab_tab_t(str_tab_t('STREAM_LOCATION'                                                    ));
      l_valid_combinations('STREAM_REACH'   ) := str_tab_tab_t(str_tab_t('STREAM_REACH'                                                       ));
      l_valid_combinations('TURBINE'        ) := str_tab_tab_t(str_tab_t('TURBINE'                                                            ),
                                                               str_tab_t('TURBINE',        'WEATHER_GAGE'                                     ),
                                                               str_tab_t('TURBINE',        'STREAM_LOCATION'                                  ),
                                                               str_tab_t('TURBINE',        'STREAM_LOCATION', 'STREAM_GAGE'                   ));
      l_valid_combinations('WEATHER_GAGE'   ) := str_tab_tab_t(str_tab_t('WEATHER_GAGE'                                                       ));

      l_type_names := get_loc_kind_names(p_location_code);
      if l_type_names.count = 0 then
         select location_kind_id
           into l_location_kind_id
           from at_physical_location pl,
                cwms_location_kind lk
          where pl.location_code = p_location_code
            and lk.location_kind_code = pl.location_kind;

         if l_location_kind_id != 'SITE' then
            l_location_kind_id := null;
         end if;
      else
         select column_value bulk collect into l_temp from table(l_type_names) order by 1;
         l_kind_ids := cwms_util.join_text(l_temp, ',');
         l_location_kind_id := l_valid_combinations.first;
         <<outer_loop>>
         loop
            exit when l_location_kind_id is null;
            for i in 1..l_valid_combinations(l_location_kind_id).count loop
               if l_valid_combinations(l_location_kind_id)(i).count = l_type_names.count then
                  select column_value bulk collect into l_temp from table(l_valid_combinations(l_location_kind_id)(i)) order by 1;
                  exit outer_loop when cwms_util.join_text(l_temp, ',') = l_kind_ids;
               end if;
            end loop;
            l_location_kind_id := l_valid_combinations.next(l_location_kind_id);
         end loop;
      end if;

      if l_location_kind_id is null then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||p_location_code
            ||'/'
            ||cwms_loc.get_location_id(p_location_code)
            || ' location kind ('
            ||cwms_util.join_text(l_type_names, ', ')
            ||') is invalid and/or does not agree with tables');
      end if;

      return l_location_kind_id;
   end check_location_kind;

   function get_location_type(
      p_location_code in number)
      return varchar2
   is
   begin
      return check_location_kind(p_location_code);
   end get_location_type;

   function check_location_kind_code(
      p_location_code in number)
      return integer
   is
      l_location_kind_code integer;
   begin
      select location_kind_code
        into l_location_kind_code
        from cwms_location_kind
       where location_kind_id = check_location_kind(p_location_code);

      return l_location_kind_code;
   end check_location_kind_code;

   function check_location_kind(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return check_location_kind(cwms_loc.get_location_code(p_office_id, p_location_id));
   end check_location_kind;

   function get_location_type(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return check_location_kind(p_location_id, p_office_id);
   end get_location_type;

   procedure clear_location_kind(
      p_location_code in number)
   is
   begin
      -- use loop for convenience; will only match once
      for rec in (select db_office_id,
                         location_id
                    from av_loc
                   where location_code = p_location_code
                 )
      loop
         clear_location_kind(rec.location_id, rec.db_office_id);
      end loop;
   end clear_location_kind;

   procedure clear_location_kind(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
   is
      l_location_code         integer;
   begin
      l_location_code := get_location_code(p_office_id, p_location_id);
      case check_location_kind(l_location_code)
         when 'BASIN'      then cwms_basin.delete_basin(p_location_id, cwms_util.delete_key, p_office_id);
         when 'STREAM'     then cwms_stream.delete_stream(p_location_id, cwms_util.delete_key, p_office_id);
         when 'OUTLET'     then cwms_outlet.delete_outlet(p_location_id, cwms_util.delete_key, p_office_id);
         when 'TURBINE'    then cwms_turbine.delete_turbine(p_location_id, cwms_util.delete_key, p_office_id);
         when 'EMBANKMENT' then cwms_embank.delete_embankment(p_location_id, cwms_util.delete_key, p_office_id);
         when 'LOCK'       then cwms_lock.delete_lock(p_location_id, cwms_util.delete_key, p_office_id);
         when 'PROJECT'    then cwms_project.delete_project(p_location_id, cwms_util.delete_key, p_office_id);
         else null;
      end case;

      update at_physical_location
         set location_kind = check_location_kind_code(l_location_code)
       where location_code = l_location_code;
   end clear_location_kind;

   function get_vertcon_offset(
      p_lat in binary_double,
      p_lon in binary_double)
      return binary_double
      deterministic
   is
      l_missing        constant binary_double := 9999;
      l_file_names     str_tab_t;
      l_data_set_codes double_tab_t;
      l_min_lat        binary_double;
      l_min_lon        binary_double;
      l_delta_lat      binary_double;
      l_delta_lon      binary_double;
      -------------------------------------
      -- variables below are named after --
      -- variables in vertcon.for source --
      -------------------------------------
      x                binary_double;
      y                binary_double;
      i                binary_integer;
      j                binary_integer;
      t1               binary_double;
      t2               binary_double;
      t3               binary_double;
      t4               binary_double;
      a                binary_double;
      b                binary_double;
      c                binary_double;
      d                binary_double;
      row              binary_double;
      col              binary_double;
      z1               binary_double;
      z2               binary_double;
      z3               binary_double;
      z4               binary_double;
      z                binary_double;
   begin
      begin
         select dataset_id,
                dataset_code
           bulk collect
           into l_file_names,
                l_data_set_codes
           from cwms_vertcon_header
          where p_lat >= min_lat
            and p_lat <= max_lat
            and p_lon >= min_lon
            and p_lon <= max_lon - margin;

         select min_lat,
                min_lon,
                delta_lat,
                delta_lon
           into l_min_lat,
                l_min_lon,
                l_delta_lat,
                l_delta_lon
           from cwms_vertcon_header
          where dataset_code = l_data_set_codes(1);
      exception
         when no_data_found then
            cwms_err.raise('ERROR', 'No VERTCON data found for lat, lon : '||p_lat||', '||p_lon);
      end;
      ------------------------------------------------
      -- variables xgrid and ygrid from vertcon.for --
      ------------------------------------------------
      x := (p_lon - l_min_lon) / l_delta_lon + 1;
      y := (p_lat - l_min_lat) / l_delta_lat + 1;
      ----------------------------------------------
      -- variables irow and jcol from vertcon.for --
      ----------------------------------------------
      i := trunc(y);
      j := trunc(x);
      -----------------------------------------------------------
      -- variables tee1, tee2, tee2, and tee4 from vertcon.for --
      -----------------------------------------------------------
      select table_val into t1 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i   and table_col = j;
      select table_val into t2 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i+1 and table_col = j;
      select table_val into t3 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i   and table_col = j+1;
      select table_val into t4 from cwms_vertcon_data where dataset_code = l_data_set_codes(1) and table_row = i+1 and table_col = j+1;

      if t1 = l_missing or t2 = l_missing or t3 = l_missing or t4 = l_missing then
         cwms_err.raise('ERROR', 'Cannot compute datum shift due to missing value in grid');
      end if;
      ------------------------------------------------------
      -- variables ay, bee, cee, and dee from vertcon.for --
      ------------------------------------------------------
      a := t1;
      b := t3-t1;
      c := t2-t1;
      d := t4-t3-t2+t1;
      ----------------------------------
      -- same names as in vertcon.for --
      ----------------------------------
      row := y - i;
      col := x - j;
      ----------------------------------------------------------------
      -- variables zee1, zee2, zee3, zee4, and zee from vertcon.for --
      ----------------------------------------------------------------
      z1 := a;
      z2 := b*col;
      z3 := c*row;
      z4 := d*col*row;
      z  := z1 + z2 + z3 + z4;

      return z / 1000.;
   end get_vertcon_offset;

   function get_vertical_datum_offset_row(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date       in date,
      p_time_zone            in varchar2,
      p_match_effective_date in varchar2 default 'F',
      p_office_id            in varchar2 default null)
      return urowid
   is
      l_rowid urowid;
      l_location_code number(10);
      l_vertical_datum_id_1 varchar2(16);
      l_vertical_datum_id_2 varchar2(16);
      l_effective_date_utc  date;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_1);
      end if;
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_2);
      end if;
      if p_effective_date is null then
         cwms_err.raise('NULL_ARGUMENT', p_effective_date);
      end if;
      -----------------
      -- do the work --
      -----------------
      l_vertical_datum_id_1 := upper(p_vertical_datum_id_1);
      l_vertical_datum_id_2 := upper(p_vertical_datum_id_2);
      l_location_code       := cwms_loc.get_location_code(p_office_id, p_location_id);
      l_effective_date_utc  := cwms_util.change_timezone(
         p_effective_date,
         nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code)),
         'UTC');
      begin
         if cwms_util.is_true(p_match_effective_date) then
            --------------------------
            -- exact effective date --
            --------------------------
            select rowid
              into l_rowid
              from at_vert_datum_offset
             where location_code = l_location_code
               and vertical_datum_id_1 = l_vertical_datum_id_1
               and vertical_datum_id_2 = l_vertical_datum_id_2
               and effective_date = l_effective_date_utc;
         else
            -----------------------------------------------
            -- latest effective date not after specified --
            -----------------------------------------------
            select rowid
              into l_rowid
              from at_vert_datum_offset
             where location_code = l_location_code
               and vertical_datum_id_1 = l_vertical_datum_id_1
               and vertical_datum_id_2 = l_vertical_datum_id_2
               and effective_date = (select max(effective_date)
                                       from at_vert_datum_offset
                                      where location_code = l_location_code
                                        and vertical_datum_id_1 = l_vertical_datum_id_1
                                        and vertical_datum_id_2 = l_vertical_datum_id_2
                                        and effective_date <= l_effective_date_utc
                                    );
         end if;
      exception
         when no_data_found then null;
      end;
      return l_rowid;
   end get_vertical_datum_offset_row;

   procedure store_vertical_datum_offset(
      p_location_id         in varchar2,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_offset              in binary_double,
      p_unit                in varchar2,
      p_effective_date      in date     default date '1000-01-01',
      p_time_zone           in varchar2 default null,
      p_description         in varchar2 default null,
      p_fail_if_exists      in varchar2 default 'T',
      p_office_id           in varchar2 default null)
   is
      l_rowid          urowid;
      l_fail_if_exists boolean := cwms_util.is_true(p_fail_if_exists);
      l_effective_date date := p_effective_date;
      l_time_zone      varchar2(28) := nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id));
      l_reversed       boolean := false;
      l_delete         boolean := false;
      l_insert         boolean := false;
      l_update         boolean := false;
   begin
      ---------------------------
      -- normalize cookie date --
      ---------------------------
      if abs(l_effective_date - date '1000-01-01') < 1 then
         l_effective_date := date '1000-01-01';
         l_time_zone := 'UTC';
      end if;
      -------------------------------------------------
      -- get the existing record if it already exits --
      -------------------------------------------------
      l_rowid := get_vertical_datum_offset_row(
         p_location_id,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         l_effective_date,
         l_time_zone,
         'T',
         p_office_id);
      if l_rowid is null then
         ------------------------------------------
         -- get the reversed record if it exists --
         ------------------------------------------
         l_rowid := get_vertical_datum_offset_row(
            p_location_id,
            p_vertical_datum_id_2,
            p_vertical_datum_id_1,
            l_effective_date,
            l_time_zone,
            'T',
            p_office_id);
         l_reversed := l_rowid is not null;
      end if;
      if l_rowid is null then
         --------------------------
         -- record doesn't exist --
         --------------------------
         l_insert := true;
      else
         -------------------
         -- record exists --
         -------------------
         if l_fail_if_exists then
            if l_reversed then
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'CWMS Vertical Datum Offset',
                  cwms_util.get_db_office_id(p_office_id)
                  ||'/'||p_location_id
                  ||'/'||upper(p_vertical_datum_id_2)
                  ||'/'||upper(p_vertical_datum_id_1)
                  ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
                  ||'('||l_time_zone
                  ||')');
            else
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'CWMS Vertical Datum Offset',
                  cwms_util.get_db_office_id(p_office_id)
                  ||'/'||p_location_id
                  ||'/'||upper(p_vertical_datum_id_1)
                  ||'/'||upper(p_vertical_datum_id_2)
                  ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
                  ||'('||l_time_zone
                  ||')');
            end if;
         end if;
         if l_reversed then
            l_delete := true;
            l_insert := true;
         else
            l_update := true;
         end if;
      end if;
      if l_update then
            update at_vert_datum_offset
               set offset = cwms_util.convert_units(p_offset, p_unit, 'm'),
                   description = p_description
             where rowid = l_rowid;
      elsif l_insert then
         if l_delete then
            delete
              from at_vert_datum_offset
             where rowid = l_rowid;
         end if;
         insert
           into at_vert_datum_offset
         values (cwms_loc.get_location_code(p_office_id, p_location_id),
                 regexp_replace(upper(p_vertical_datum_id_1), '(N[AG]VD)[ -]', '\1', 1, 0),
                 regexp_replace(upper(p_vertical_datum_id_2), '(N[AG]VD)[ -]', '\1', 1, 0),
                 cwms_util.change_timezone(
                    l_effective_date,
                    l_time_zone,
                    'UTC'),
                 cwms_util.convert_units(p_offset, p_unit, 'm'),
                 p_description
                );
      end if;
    end store_vertical_datum_offset;

   procedure store_vertical_datum_offset(
      p_vertical_datum_offset in vert_datum_offset_t,
      p_fail_if_exists        in varchar2 default 'T')
   is
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_vertical_datum_offset is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_vertical_datum_offset');
      end if;
      -----------------
      -- do the work --
      -----------------
      store_vertical_datum_offset(
         p_location_id         => p_vertical_datum_offset.location.get_location_id,
         p_vertical_datum_id_1 => p_vertical_datum_offset.vertical_datum_id_1,
         p_vertical_datum_id_2 => p_vertical_datum_offset.vertical_datum_id_2,
         p_offset              => p_vertical_datum_offset.offset,
         p_unit                => p_vertical_datum_offset.unit,
         p_effective_date      => p_vertical_datum_offset.effective_date,
         p_time_zone           => p_vertical_datum_offset.time_zone,
         p_description         => p_vertical_datum_offset.description,
         p_fail_if_exists      => p_fail_if_exists,
         p_office_id           => p_vertical_datum_offset.location.office_id);
   end store_vertical_datum_offset;

   procedure retrieve_vertical_datum_offset(
      p_offset               out binary_double,
      p_unit_out             out varchar2,
      p_description          out varchar2,
      p_effective_date_out   out date,
      p_location_id          in  varchar2,
      p_vertical_datum_id_1  in  varchar2,
      p_vertical_datum_id_2  in  varchar2,
      p_effective_date_in    in  date     default null,
      p_time_zone            in  varchar2 default null,
      p_unit_in              in  varchar2 default null,
      p_match_effective_date in  varchar2 default 'F',
      p_office_id            in  varchar2 default null)
   is
      l_rowid          urowid;
      l_effective_date date;
      l_time_zone      varchar2(28);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_1);
      end if;
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_2);
      end if;
      -----------------
      -- do the work --
      -----------------
      l_effective_date := nvl(p_effective_date_in, sysdate);
      l_time_zone := case p_effective_date_in is null
                        when true then 'UTC'
                        else nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id))
                     end;
      l_rowid := get_vertical_datum_offset_row(
         p_location_id          => p_location_id,
         p_vertical_datum_id_1  => p_vertical_datum_id_1,
         p_vertical_datum_id_2  => p_vertical_datum_id_2,
         p_effective_date       => l_effective_date,
         p_time_zone            => l_time_zone,
         p_match_effective_date => p_match_effective_date,
         p_office_id            => p_office_id);
      if l_rowid is null then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS Vertical Datum Offset',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||upper(p_vertical_datum_id_1)
            ||'/'||upper(p_vertical_datum_id_2)
            ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
            ||'('||l_time_zone
            ||')');
      end if;
      select case
                when p_unit_in is null then offset
                else cwms_util.convert_units(offset, 'm', p_unit_in)
             end,
             nvl(p_unit_in, 'm'),
             description
        into p_offset,
             p_unit_out,
             p_description
        from at_vert_datum_offset
       where rowid = l_rowid;
   end retrieve_vertical_datum_offset;

   function retrieve_vertical_datum_offset(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date_in    in date     default null,
      p_time_zone            in varchar2 default null,
      p_unit                 in varchar2 default null,
      p_match_effective_date in varchar2 default 'F',
      p_office_id            in varchar2 default null)
      return vert_datum_offset_t
   is
      l_offset             binary_double;
      l_unit_out           varchar2(16);
      l_description        varchar2(64);
      l_effective_date_out date;
   begin
      retrieve_vertical_datum_offset(
         p_offset               => l_offset,
         p_unit_out             => l_unit_out,
         p_description          => l_description,
         p_effective_date_out   => l_effective_date_out,
         p_location_id          => p_location_id,
         p_vertical_datum_id_1  => p_vertical_datum_id_1,
         p_vertical_datum_id_2  => p_vertical_datum_id_2,
         p_effective_date_in    => p_effective_date_in,
         p_time_zone            => p_time_zone,
         p_unit_in              => p_unit,
         p_match_effective_date => p_match_effective_date,
         p_office_id            => p_office_id);

      return vert_datum_offset_t(
         location_ref_t(p_location_id, p_office_id),
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         l_effective_date_out,
         case p_effective_date_in is null
            when true then 'UTC'
            else nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id))
         end,
         l_offset,
         l_unit_out,
         l_description);

   end retrieve_vertical_datum_offset;

   procedure delete_vertical_datum_offset(
      p_location_id          in varchar2,
      p_vertical_datum_id_1  in varchar2,
      p_vertical_datum_id_2  in varchar2,
      p_effective_date_in    in date     default null,
      p_time_zone            in varchar2 default null,
      p_match_effective_date in varchar2 default 'T',
      p_office_id            in varchar2 default null)
   is
      l_rowid          urowid;
      l_effective_date date;
      l_time_zone      varchar2(28);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_1);
      end if;
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', p_vertical_datum_id_2);
      end if;
      -----------------
      -- do the work --
      -----------------
      l_effective_date := nvl(p_effective_date_in, sysdate);
      l_time_zone := case p_effective_date_in is null
                        when true then 'UTC'
                        else nvl(p_time_zone, cwms_loc.get_local_timezone(p_location_id, p_office_id))
                     end;
      l_rowid := get_vertical_datum_offset_row(
         p_location_id          => p_location_id,
         p_vertical_datum_id_1  => p_vertical_datum_id_1,
         p_vertical_datum_id_2  => p_vertical_datum_id_2,
         p_effective_date       => l_effective_date,
         p_time_zone            => l_time_zone,
         p_match_effective_date => p_match_effective_date,
         p_office_id            => p_office_id);
      if l_rowid is null then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS Vertical Datum Offset',
            cwms_util.get_db_office_id(p_office_id)
            ||'/'||p_location_id
            ||'/'||upper(p_vertical_datum_id_1)
            ||'/'||upper(p_vertical_datum_id_2)
            ||'@'||to_char(l_effective_date, 'yyyy-mm-dd hh24:mi:ss')
            ||'('||l_time_zone
            ||')');
      end if;

      delete from at_vert_datum_offset where rowid = l_rowid;

   end delete_vertical_datum_offset;

   procedure get_vertical_datum_offset(
      p_offset              out binary_double,
      p_effective_date      out date,
      p_estimate            out varchar2,
      p_location_code       in  number,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_datetime_utc        in  date default sysdate)
   is
      pragma autonomous_transaction; -- for inserting VERTCON offset estimate
      l_offset              binary_double;
      l_effective_date      date;
      l_vertical_datum_id_1 varchar2(16);
      l_vertical_datum_id_2 varchar2(16);
      l_description         varchar2(64);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_code is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_location_code');
      end if;
      if p_vertical_datum_id_1 is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_vertical_datum_id_1');
      end if;
      if p_vertical_datum_id_2 is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_vertical_datum_id_2');
      end if;
      if p_datetime_utc is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_datetime_utc');
      end if;
      -----------------
      -- do the work --
      -----------------
      l_vertical_datum_id_1 := upper(p_vertical_datum_id_1);
      l_vertical_datum_id_2 := upper(p_vertical_datum_id_2);
      if l_vertical_datum_id_2 = l_vertical_datum_id_1 then
         ----------------------
         -- identity mapping --
         ----------------------
         l_offset := 0;
         l_effective_date := date '1000-01-01';
      end if;
      if l_offset is null then
         begin
            -------------------------------------------------
            -- generate a 29->88 estimate if it might help --
            -------------------------------------------------
            if (l_vertical_datum_id_1 in ('NGVD29', 'NAVD88')  or
                l_vertical_datum_id_2 in ('NGVD29', 'NAVD88')) and not
               (l_vertical_datum_id_1 in ('NGVD29', 'NAVD88')  and
                l_vertical_datum_id_2 in ('NGVD29', 'NAVD88'))
            then
               get_vertical_datum_offset(
                  l_offset,
                  l_effective_date,
                  l_description,
                  p_location_code,
                  'NGVD29',
                  'NAVD88');
               l_offset := null;
               l_effective_date := null;
               l_description := null;
            end if;
            --------------------------------------
            -- search for the specified mapping --
            --------------------------------------
            select offset,
                   effective_date,
                   description
              into l_offset,
                   l_effective_date,
                   l_description
              from at_vert_datum_offset
             where location_code = p_location_code
               and vertical_datum_id_1 = l_vertical_datum_id_1
               and vertical_datum_id_2 = l_vertical_datum_id_2
               and effective_date = (select max(effective_date)
                                       from at_vert_datum_offset
                                      where location_code = p_location_code
                                        and vertical_datum_id_1 = l_vertical_datum_id_1
                                        and vertical_datum_id_2 = l_vertical_datum_id_2
                                        and effective_date <= p_datetime_utc
                                    );
         exception
            when no_data_found then null;
         end;
         if l_offset is null then
            ------------------------------------
            -- search for the reverse mapping --
            ------------------------------------
            begin
               select offset,
                      effective_date,
                      description
                 into l_offset,
                      l_effective_date,
                      l_description
                 from at_vert_datum_offset
                where location_code = p_location_code
                  and vertical_datum_id_1 = l_vertical_datum_id_2
                  and vertical_datum_id_2 = l_vertical_datum_id_1
                  and effective_date = (select max(effective_date)
                                          from at_vert_datum_offset
                                         where location_code = p_location_code
                                           and vertical_datum_id_1 = l_vertical_datum_id_2
                                           and vertical_datum_id_2 = l_vertical_datum_id_1
                                           and effective_date <= p_datetime_utc
                                       );
               l_offset := -l_offset;
            exception
               when no_data_found then null;
            end;
         end if;
      end if;
      if l_offset is null then
         -------------------------------------------------------------------------
         -- search for any indirect mappings separated by a single common datum --
         -------------------------------------------------------------------------
         for rec_1 in (
            select v1.vertical_datum_id_1,
                   v1.vertical_datum_id_2,
                   v1.offset,
                   v1.effective_date,
                   v1.description
              from at_vert_datum_offset v1
             where location_code = p_location_code
               and (v1.vertical_datum_id_1 = l_vertical_datum_id_1 or v1.vertical_datum_id_2 = l_vertical_datum_id_1)
               and effective_date = (select max(effective_date)
                                       from at_vert_datum_offset
                                      where location_code = p_location_code
                                        and vertical_datum_id_1 = v1.vertical_datum_id_1
                                        and vertical_datum_id_2 = v1.vertical_datum_id_2
                                        and effective_date <= p_datetime_utc
                                    )
                    )
         loop
            for rec_2 in (
               select v2.vertical_datum_id_1,
                      v2.vertical_datum_id_2,
                      v2.offset,
                      v2.effective_date,
                      v2.description
                 from at_vert_datum_offset v2
                where location_code = p_location_code
                  and (v2.vertical_datum_id_1 = l_vertical_datum_id_2 or v2.vertical_datum_id_2 = l_vertical_datum_id_2)
                  and effective_date = (select max(effective_date)
                                          from at_vert_datum_offset
                                         where location_code = p_location_code
                                           and vertical_datum_id_1 = v2.vertical_datum_id_1
                                           and vertical_datum_id_2 = v2.vertical_datum_id_2
                                           and effective_date <= p_datetime_utc
                                       )
                       )
            loop
               if rec_1.vertical_datum_id_1 = l_vertical_datum_id_1 then
                  if rec_2.vertical_datum_id_1 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_2 = rec_1.vertical_datum_id_2 then
                        --------------------------------------------
                        -- datum_1 ==> common; datum_2 ==> common --
                        --------------------------------------------
                        l_offset := rec_1.offset - rec_2.offset;
                     end if;
                  elsif rec_2.vertical_datum_id_2 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_1 = rec_1.vertical_datum_id_2 then
                        --------------------------------------------
                        -- datum_1 ==> common; common ==> datum_2 --
                        --------------------------------------------
                        l_offset := rec_1.offset + rec_2.offset;
                     end if;
                  end if;
               elsif rec_1.vertical_datum_id_2 = l_vertical_datum_id_1 then
                  if rec_2.vertical_datum_id_1 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_2 = rec_1.vertical_datum_id_1 then
                        --------------------------------------------
                        -- common ==> datum_1; datum_2 ==> common --
                        --------------------------------------------
                        l_offset := -rec_1.offset - rec_2.offset;
                     end if;
                  elsif rec_2.vertical_datum_id_2 = l_vertical_datum_id_2 then
                     if rec_2.vertical_datum_id_1 = rec_1.vertical_datum_id_1 then
                        --------------------------------------------
                        -- common ==> datum_1; common ==> datum_2 --
                        --------------------------------------------
                        l_offset := -rec_1.offset + rec_2.offset;
                     end if;
                  end if;
               end if;
               if l_offset is not null then
                  l_effective_date := greatest(rec_1.effective_date, rec_2.effective_date);
                  if rec_1.description is not null and instr(upper(rec_1.description), 'ESTIMATE') > 0 then
                     l_description := rec_1.description;
                  else
                     l_description := rec_2.description;
                  end if;
                  exit;
               end if;
            end loop;
            exit when l_offset is not null;
         end loop;
      end if;
      if l_offset is null then
         if l_vertical_datum_id_1 in ('NGVD29', 'NAVD88') and
            l_vertical_datum_id_2 in ('NGVD29', 'NAVD88')
         then
            ---------------------------------------------
            -- estimate offset using VERTCON algorithm --
            ---------------------------------------------
            declare
               l_lat binary_double;
               l_lon binary_double;
            begin
               select latitude,
                      longitude
                 into l_lat,
                      l_lon
                 from cwms_v_loc
                where location_code = p_location_code
                  and unit_system = 'SI';

               if l_lat is not null and l_lon is not null then
                  begin
                     l_offset := get_vertcon_offset(l_lat, l_lon);
                     l_description := 'VERTCON ESTIMATE';
                  exception
                     when others then
                        l_offset := binary_double_nan;
                        l_description := substr(sqlerrm, 1, 64);
                  end;
                  l_effective_date := date '1000-01-01';
                  insert
                    into at_vert_datum_offset
                  values (p_location_code,
                          'NGVD29',
                          'NAVD88',
                          l_effective_date,
                          l_offset,
                          l_description);
                  if l_vertical_datum_id_1 = 'NAVD88' then
                     l_offset := -l_offset;
                  end if;
                  commit;
               end if;
            exception
               when no_data_found then null;
            end;
         end if;
      end if;
--      if l_offset is null then
--         ---------------------
--         -- declare failure --
--         ---------------------
--         declare
--            l_location location_ref_t := location_ref_t(p_location_code);
--         begin
--            cwms_err.raise(
--               'ERROR',
--               'No vertical offset exists for '
--               ||l_location.get_office_id
--               ||'/'
--               ||l_location.get_location_id
--               ||' from '
--               ||l_vertical_datum_id_1
--               ||' to '
--               ||l_vertical_datum_id_2);
--         end;
--      end if;
      p_offset := l_offset;
      p_effective_date := l_effective_date;
      if l_description is null or instr(upper(l_description), 'ESTIMATE') = 0 then
         p_estimate := 'F';
      else
         p_estimate := 'T';
      end if;
   end get_vertical_datum_offset;

   function get_vertical_datum_offsets(
      p_location_code       in number,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_start_time_utc      in date,
      p_end_time_utc        in date)
      return ztsv_array
   is
      l_offsets ztsv_array;
   begin
      get_vertical_datum_offsets(
         l_offsets,
         p_location_code,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         p_start_time_utc,
         p_end_time_utc);

      return l_offsets;
   end get_vertical_datum_offsets;

   procedure get_vertical_datum_offsets(
      p_offsets             out ztsv_array,
      p_location_code       in  number,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_start_time_utc      in  date,
      p_end_time_utc        in  date)
   is
      l_offsets        ztsv_array;
      l_offsets2       ztsv_array;
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_start_time_utc is null then
         cwms_err.raise('NULL_ARGUMENT', p_start_time_utc);
      end if;
      if p_end_time_utc is null then
         cwms_err.raise('NULL_ARGUMENT', p_end_time_utc);
      end if;
      if p_end_time_utc < p_start_time_utc then
         cwms_err.raise('ERROR', 'End time must be be earlier than start time.');
      end if;
      -----------------
      -- do the work --
      -----------------
      l_effective_date := p_end_time_utc;
      loop
         begin
            get_vertical_datum_offset(
               l_offset,
               l_effective_date,
               l_estimate,
               p_location_code,
               p_vertical_datum_id_1,
               p_vertical_datum_id_2,
               l_effective_date);
            if l_offsets is null then
               l_offsets := ztsv_array();
               l_offsets.extend;
            end if;
            l_offsets(l_offsets.count) := ztsv_type(l_effective_date, l_offset, null);
            exit when l_effective_date < p_start_time_utc;
            l_effective_date := l_effective_date - 1 / 86400;
         exception
            when others then exit;
         end;
      end loop;
      if l_offsets is not null then
         l_offsets2 := ztsv_array();
         l_offsets2.extend(l_offsets.count);
         for i in 1..l_offsets.count loop
            l_offsets2(i) := l_offsets(l_offsets.count+1-i);
         end loop;
      end if;
      p_offsets := l_offsets2;
   end get_vertical_datum_offsets;

   function get_vertical_datum_offset(
      p_location_code       in number,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_datetime_utc        in date     default sysdate,
      p_unit                in varchar2 default null)
      return binary_double
   is
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_code is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_code);
      end if;
      -----------------
      -- do the work --
      -----------------
      get_vertical_datum_offset(
          p_offset              => l_offset,
          p_effective_date      => l_effective_date,
          p_estimate            => l_estimate,
          p_location_code       => p_location_code,
          p_vertical_datum_id_1 => p_vertical_datum_id_1,
          p_vertical_datum_id_2 => p_vertical_datum_id_2,
          p_datetime_utc        => p_datetime_utc);
      if p_unit is not null then
         l_offset := cwms_util.convert_units(l_offset, 'm', p_unit);
      end if;
      return l_offset;
   end get_vertical_datum_offset;

   function get_vertical_datum_offset(
      p_location_id         in varchar,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_datetime            in date     default null,
      p_time_zone           in varchar2 default null,
      p_unit                in varchar2 default null,
      p_office_id           in varchar2 default null)
      return binary_double
   is
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      get_vertical_datum_offset(
         l_offset,
         l_effective_date,
         l_estimate,
         p_location_id,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         p_datetime,
         p_time_zone,
         p_unit,
         p_office_id);
      return l_offset;
   end get_vertical_datum_offset;

   procedure get_vertical_datum_offset(
      p_offset              out binary_double,
      p_effective_date      out date,
      p_estimate            out varchar2,
      p_location_id         in  varchar,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_datetime            in  date     default null,
      p_time_zone           in  varchar2 default null,
      p_unit                in  varchar2 default null,
      p_office_id           in  varchar2 default null)
   is
      l_location_code  number(10);
      l_timezone       varchar2(28);
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      -----------------
      -- do the work --
      -----------------
      l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
      l_timezone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      get_vertical_datum_offset(
         l_offset,
         l_effective_date,
         l_estimate,
         l_location_code,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         nvl(cwms_util.change_timezone(p_datetime, l_timezone, 'UTC'), sysdate));
      if p_unit is null then
         p_offset := l_offset;
      else
         p_offset := cwms_util.convert_units(l_offset, 'm', p_unit);
      end if;
      p_effective_date := cwms_util.change_timezone(l_effective_date, 'UTC', l_timezone);
      p_estimate := l_estimate;

   end get_vertical_datum_offset;

   function get_vertical_datum_offsets(
      p_location_id         in varchar,
      p_vertical_datum_id_1 in varchar2,
      p_vertical_datum_id_2 in varchar2,
      p_start_time          in date,
      p_end_time            in date,
      p_time_zone           in varchar2 default null,
      p_unit                in varchar2 default null,
      p_office_id           in varchar2 default null)
      return ztsv_array
   is
      l_offsets ztsv_array;
   begin
      get_vertical_datum_offsets(
         l_offsets,
         p_location_id,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         p_start_time,
         p_end_time,
         p_time_zone,
         p_unit,
         p_office_id);
      return l_offsets;
   end get_vertical_datum_offsets;

   procedure get_vertical_datum_offsets(
      p_offsets             out ztsv_array,
      p_location_id         in  varchar,
      p_vertical_datum_id_1 in  varchar2,
      p_vertical_datum_id_2 in  varchar2,
      p_start_time          in  date,
      p_end_time            in  date,
      p_time_zone           in  varchar2 default null,
      p_unit                in  varchar2 default null,
      p_office_id           in  varchar2 default null)
   is
      l_location_code  number(10);
      l_timezone       varchar2(28);
      l_offsets        ztsv_array;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_id is null then
         cwms_err.raise('NULL_ARGUMENT', p_location_id);
      end if;
      -----------------
      -- do the work --
      -----------------
      l_location_code := cwms_loc.get_location_code(p_office_id, p_location_id);
      l_timezone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_location_code));
      get_vertical_datum_offsets(
         l_offsets,
         l_location_code,
         p_vertical_datum_id_1,
         p_vertical_datum_id_2,
         cwms_util.change_timezone(p_start_time, l_timezone, 'UTC'),
         cwms_util.change_timezone(p_end_time, l_timezone, 'UTC'));
      if l_offsets is not null then
         for i in 1..l_offsets.count loop
            l_offsets(i).date_time := cwms_util.change_timezone(l_offsets(i).date_time, 'UTC', l_timezone);
            if p_unit is not null then
               l_offsets(i).value := cwms_util.convert_units(l_offsets(i).value, 'm', p_unit);
            end if;
         end loop;
      end if;
   end get_vertical_datum_offsets;


   procedure set_default_vertical_datum(
      p_vertical_datum in varchar2)
   is
      l_vertical_datum varchar(16);
   begin
      if p_vertical_datum is null then
         cwms_util.reset_session_info('VERTICAL DATUM');
      else
         select vertical_datum_id
           into l_vertical_datum
           from cwms_vertical_datum
          where vertical_datum_id = upper(p_vertical_datum)
            and vertical_datum_id <> 'STAGE';
         cwms_util.set_session_info('VERTICAL DATUM', l_vertical_datum);
      end if;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_vertical_datum, 'CWMS vertical datum');
   end set_default_vertical_datum;

   procedure get_default_vertical_datum(
      p_vertical_datum out varchar2)
   is
   begin
      p_vertical_datum := get_default_vertical_datum;
   end get_default_vertical_datum;

   function get_default_vertical_datum
      return varchar2
   is
   begin
      return cwms_util.get_session_info_txt('VERTICAL DATUM');
   end get_default_vertical_datum;

   procedure get_location_vertical_datum(
      p_vertical_datum out varchar2,
      p_location_code  in  number)
   is
      l_vertical_datum     varchar2(16);
      l_base_location_code number(10);
   begin
      select base_location_code,
             vertical_datum
        into l_base_location_code,
             l_vertical_datum
        from at_physical_location
       where location_code = p_location_code;
      if l_vertical_datum is null and l_base_location_code != p_location_code then
         select base_location_code,
                vertical_datum
           into l_base_location_code,
                l_vertical_datum
           from at_physical_location
          where location_code = l_base_location_code;
      end if;
      p_vertical_datum := l_vertical_datum;
   end get_location_vertical_datum;

   procedure get_location_vertical_datum(
      p_vertical_datum out varchar2,
      p_location_id    in  varchar2,
      p_office_id      in  varchar2 default null)
   is
   begin
      get_location_vertical_datum(
         p_vertical_datum,
         get_location_code(p_office_id, p_location_id));
   end get_location_vertical_datum;

   function get_location_vertical_datum(
      p_location_code in number)
      return varchar2
   is
      l_vertical_datum varchar2(16);
   begin
      get_location_vertical_datum(l_vertical_datum, p_location_code);
      return l_vertical_datum;
   end get_location_vertical_datum;

   function get_location_vertical_datum(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
      l_vertical_datum varchar2(16);
   begin
      get_location_vertical_datum(l_vertical_datum, p_location_id, p_office_id);
      return l_vertical_datum;
   end get_location_vertical_datum;

   function get_vertical_datum_offset(
      p_location_code in number,
      p_unit          in varchar2)
      return binary_double
   is
      l_location_datum  varchar2(16);
      l_effective_datum varchar2(16);
      l_datum_offset    binary_double;
   begin
      l_location_datum  := get_location_vertical_datum(p_location_code);
      l_effective_datum := cwms_util.get_effective_vertical_datum(p_unit);
      case
         when l_effective_datum is null or l_location_datum = l_effective_datum then
            l_datum_offset := 0;
         when l_location_datum is null then
            cwms_err.raise('ERROR', 'Cannot convert between NULL and non-NULL vertical datums');
         else
            l_datum_offset := get_vertical_datum_offset(
                 p_location_code,
                 l_location_datum,
                 l_effective_datum,
                 sysdate,
                 p_unit);
      end case;
      return l_datum_offset;
   end get_vertical_datum_offset;

   function get_vertical_datum_offset(
      p_location_id  in varchar2,
      p_unit         in varchar2,
      p_office_id    in varchar2 default null)
      return binary_double
   is
   begin
      return get_vertical_datum_offset(
         get_location_code(p_office_id, p_location_id),
         p_unit);
   end get_vertical_datum_offset;


   procedure get_vertical_datum_info(
      p_vert_datum_info out varchar2,
      p_location_code   in  number,
      p_unit            in  varchar2)
   is
      l_location_id      varchar2(57);
      l_office_id        varchar2(16);
      l_elevation        number;
      l_unit             varchar2(16);
      l_vert_datum_info  varchar2(4000);
      l_native_datum     varchar2(16);
      l_local_datum_name varchar2(16);
      l_datum_offset     binary_double;
      l_effective_date   date;
      l_estimate         varchar2(1);
      l_rounding_spec    varchar2(10) := '4444444449';
   begin
      l_unit := cwms_util.get_unit_id(p_unit);

      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
             ||pl.sub_location_id,
             o.office_id,
             cwms_util.convert_units(pl.elevation, 'm', l_unit),
             pl.vertical_datum
        into l_location_id,
             l_office_id,
             l_elevation,
             l_native_datum
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      l_vert_datum_info := '<vertical-datum-info office="'
         ||l_office_id
         ||'" unit="'
         ||l_unit
         ||'">'
         ||chr(10);
      l_vert_datum_info := l_vert_datum_info
         ||'  <location>'
         ||dbms_xmlgen.convert(l_location_id)
         ||'</location>'
         ||chr(10);
      l_vert_datum_info := l_vert_datum_info
         ||'  <native-datum>'
         ||nvl(replace(l_native_datum, 'LOCAL', 'OTHER'), 'UNKNOWN')
         ||'</native-datum>'
         ||chr(10);
      if l_native_datum = 'LOCAL' then
         l_local_datum_name := get_local_vert_datum_name_f(p_location_code);
         if l_local_datum_name is null then
            l_vert_datum_info := l_vert_datum_info
               ||'  <local-datum-name/>'
               ||chr(10);
         else
            l_vert_datum_info := l_vert_datum_info
               ||'  <local-datum-name>'
               ||dbms_xmlgen.convert(l_local_datum_name)
               ||'</local-datum-name>'
               ||chr(10);
         end if;
      end if;
      if l_elevation is not null then
         l_vert_datum_info := l_vert_datum_info
            ||'  <elevation>'
            ||cwms_rounding.round_nt_f(l_elevation, l_rounding_spec)
            ||'</elevation>'
            ||chr(10);
      end if;

      for rec in (select vertical_datum_id
                    from cwms_vertical_datum
                   where vertical_datum_id != l_native_datum
                   order by vertical_datum_id
                 )
      loop
         begin
            get_vertical_datum_offset(
               l_datum_offset,
               l_effective_date,
               l_estimate,
               p_location_code,
               l_native_datum,
               rec.vertical_datum_id);
            if l_datum_offset is not null then
               l_vert_datum_info := l_vert_datum_info
                  ||'  <offset estimate="'
                  || case l_estimate when 'T' then 'true' else 'false' end
                  ||'">'
                  ||chr(10)
                  ||'    <to-datum>'
                  ||rec.vertical_datum_id
                  ||'</to-datum>'
                  ||chr(10)
                  ||'    <value>'
                  ||regexp_replace(cwms_rounding.round_dt_f(cwms_util.convert_units(l_datum_offset, 'm', l_unit), l_rounding_spec), '^\.', '0.', 1, 1)
                  ||'</value>'
                  ||chr(10)
                  ||'  </offset>'
                  ||chr(10);
            end if;
         exception
            when others then
               if instr(sqlerrm, 'No vertical offset exists') = 1 then null; end if;
         end;
      end loop;
      l_vert_datum_info := l_vert_datum_info
         ||'</vertical-datum-info>';
      l_vert_datum_info := regexp_replace(l_vert_datum_info, '(N[AG]VD)(29|88)', '\1-\2');
      p_vert_datum_info := l_vert_datum_info;
   end get_vertical_datum_info;

   procedure get_vertical_datum_info(
      p_vert_datum_info out varchar2,
      p_location_id     in  varchar2,
      p_unit            in  varchar2,
      p_office_id       in  varchar2 default null)
   is
      l_location_records str_tab_tab_t;
      l_office_records   str_tab_tab_t;
      l_record_count     pls_integer := 0;
      l_field_count      pls_integer := 0;
      l_total            pls_integer := 0;
      l_vert_datum_info  varchar2(4000);
      l_office_id        varchar2(16);
      function indent(p_str in varchar2) return varchar2
      is
         l_lines str_tab_t;
         l_str   varchar2(32767);
      begin
         l_lines := cwms_util.split_text(p_str, chr(10));
         for i in 1..l_lines.count loop
            l_str := l_str
               ||'  '||replace(l_lines(i), chr(13), null)||chr(10);
         end loop;
         return substr(l_str, 1, length(l_str)-1);
      end;
   begin
      l_location_records := cwms_util.parse_string_recordset(p_location_id);
      l_record_count := l_location_records.count;
      if p_office_id is not null then
         l_office_records := cwms_util.parse_string_recordset(p_office_id);
      end if;
      for i in 1..l_record_count loop
         l_total := l_total + l_location_records(i).count;
         exit when l_total > 1;
      end loop;
      if l_total > 1 then
         l_vert_datum_info := '<vertical-datum-info-set>'||chr(10);
         for i in 1..l_record_count loop
            l_field_count := case when l_location_records(i) is null then 0 else l_location_records(i).count end;
            for j in 1..l_field_count loop
               case
                  when l_office_records is null or l_office_records.count = 0 then
                     -- no office ids
                     l_office_id := null;
                  when l_office_records.count = l_record_count then
                     case
                        when l_office_records(i) is null or l_office_records(i).count = 0 then
                           -- null office for this record
                           l_office_id := null;
                        when l_office_records(i).count = 1 then
                           -- single office for this record
                           l_office_id := l_office_records(i)(1);
                        when l_office_records(i).count = l_field_count then
                           -- one office per location
                           l_office_id := l_office_records(i)(j);
                        else
                           -- office count error for this record
                           cwms_err.raise(
                              'ERROR',
                              'Invalid office count on record '
                              ||i
                              ||', expected 0, 1, or '
                              ||l_field_count
                              ||', got '
                              ||l_office_records(i).count);
                     end case;
                  when l_office_records.count = 1 then -- l_record_count != 1 or would match above
                     -- single office_id for all records
                     if l_office_records(1) is null or l_office_records(1).count = 0 then
                        l_office_id := null;
                     else
                        l_office_id := l_office_records(1)(1);
                     end if;
                  else
                     -- total office count error
                     cwms_err.raise(
                        'ERROR',
                        'Invalid office record count, expected 0, 1, or '
                        ||l_record_count
                        ||', got '
                        ||l_office_records.count);
               end case;
               l_vert_datum_info := l_vert_datum_info
                  ||indent(get_vertical_datum_info_f(l_location_records(i)(j), p_unit, l_office_id))
                  ||chr(10);
            end loop;
         end loop;
         l_vert_datum_info := l_vert_datum_info||'</vertical-datum-info-set>';
      else
         get_vertical_datum_info(
            l_vert_datum_info,
            get_location_code(p_office_id, p_location_id),
            p_unit);
      end if;
      p_vert_datum_info := l_vert_datum_info;
   end get_vertical_datum_info;

   function get_vertical_datum_info_f(
      p_location_code in number,
      p_unit          in varchar2)
      return varchar2
   is
      l_vert_datum_info varchar2(4000);
   begin
      get_vertical_datum_info(
         l_vert_datum_info,
         p_location_code,
         p_unit);
      return l_vert_datum_info;
   end get_vertical_datum_info_f;

   procedure set_vertical_datum_info(
      p_location_code   in number,
      p_vert_datum_info in xmltype,
      p_fail_if_exists  in varchar2 default 'F')
   is
      l_node                xmltype;
      l_location_id         varchar2(57);
      l_location_id_2       varchar2(57);
      l_office_id           varchar2(16);
      l_office_id_2         varchar2(16);
      l_native_datum        varchar2(16);
      l_native_datum_db     varchar2(16);
      l_local_datum_name    varchar2(16);
      l_local_datum_name_db varchar2(16);
      l_to_datum            varchar2(16);
      l_unit                varchar2(16);
      l_estimate            boolean;
      l_offset              binary_double;
      l_elevation           binary_double;
      l_elevation_db        binary_double;
      l_fail_if_exists      boolean;
   begin
      delete from at_vert_datum_local  where location_code = p_location_code;
      delete from at_vert_datum_offset where location_code = p_location_code;
      l_location_id := get_location_id(p_location_code);
      select o.office_id
        into l_office_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
      l_node := cwms_util.get_xml_node(p_vert_datum_info, '/vertical-datum-info');
      if l_node is null then
         cwms_err.raise('ERROR', 'Vertical datum info does not have <vertical-datum-info> as root element');
      end if;
      l_office_id_2   := cwms_util.get_xml_text(l_node, '/vertical-datum-info/@office');
      l_location_id_2 := cwms_util.get_xml_text(l_node, '/vertical-datum-info/location');
      if (l_office_id_2 is null) != (l_location_id_2 is null) then
         cwms_err.raise('ERROR', 'Office and location must be specified together (both or neither)');
      end if;
      if l_office_id_2 is not null then
         if get_location_code(l_office_id_2, l_location_id_2) != p_location_code then
            cwms_err.raise('ERROR', 'Location specified in XML is not same as that specified in p_location_code parameter');
         end if;
      end if;
      l_unit := cwms_util.get_xml_text(l_node, '/vertical-datum-info/@unit');
      if l_unit is null then
         cwms_err.raise('ERROR', 'Vertical datum info does not specify unit');
      end if;
      l_native_datum := upper(cwms_util.get_xml_text(l_node, '/vertical-datum-info/native-datum'));
      if l_native_datum is not null then
         l_native_datum := replace(l_native_datum, 'OTHER', 'LOCAL');
         l_native_datum := regexp_replace(l_native_datum, '(N[AG]VD).+(29|88)', '\1\2');
         l_native_datum_db := get_location_vertical_datum(p_location_code);
         if l_native_datum_db is not null and l_native_datum_db != l_native_datum then
            cwms_err.raise(
               'ERROR',
               'Specified native datum for '
               ||l_office_id||'/'||l_location_id
               ||' of '
               ||cwms_util.get_xml_text(l_node, '/vertical-datum-info/native-datum')
               ||' does not agree with native datum in database of '
               ||l_native_datum_db);
         end if;
         if l_native_datum = 'LOCAL' then
            l_local_datum_name := cwms_util.get_xml_text(l_node, '/vertical-datum-info/local-datum-name');
            if l_local_datum_name is not null then
               l_local_datum_name_db := get_local_vert_datum_name_f(p_location_code);
               if l_local_datum_name_db is not null and l_local_datum_name_db != l_local_datum_name then
                  cwms_err.raise(
                     'ERROR',
                     'Specified local datum name for '
                     ||l_office_id||'/'||l_location_id
                     ||' of '
                     ||l_local_datum_name
                     ||' does not agree with local datum name in database of '
                     ||l_local_datum_name_db);
               end if;
            end if;
         end if;
      end if;
      l_elevation := cwms_util.get_xml_number(l_node, '/vertical-datum-info/elevation');
      if l_elevation is not null then
         select cwms_util.convert_units(elevation, 'm', l_unit)
           into l_elevation_db
           from at_physical_location
          where location_code = p_location_code;
         if l_elevation_db is not null and l_elevation_db != l_elevation then
            cwms_err.raise(
               'ERROR',
               'Specified elevation for '
               ||l_office_id||'/'||l_location_id
               ||' of '
               ||l_elevation
               ||' '
               ||l_unit
               ||' does not agree with elevation in database of '
               ||l_elevation_db
               ||' '
               ||l_unit);
         end if;
      end if;
      for i in 1..999999 loop
         l_node := cwms_util.get_xml_node(p_vert_datum_info, '/vertical-datum-info/offset['||i||']');
         exit when l_node is null;
         l_to_datum := cwms_util.get_xml_text(l_node, '/offset/to-datum');
         if l_to_datum is null then
            cwms_err.raise('ERROR', '<offset> element does not specify datum in <to-datum> child element');
         end if;
         l_offset := cwms_util.get_xml_number(l_node, '/offset/value');
         if l_offset is null then
            cwms_err.raise('ERROR', '<offset> element does not specify datum in <value> child element');
         end if;
         case upper(nvl(cwms_util.get_xml_text(l_node, '/offset/@estimate'), 'NULL'))
            when 'TRUE'  then l_estimate := true;
            when 'FALSE' then l_estimate := false;
            when 'NULL'  then cwms_err.raise('ERROR', 'Estimate attribute is missing from <offset> element for datum '||l_to_datum);
            else cwms_err.raise('ERROR', 'Estimate attribute in <offset> element for datum '||l_to_datum||' must be "true" or "false"');
         end case;
         cwms_loc.store_vertical_datum_offset(
            p_location_id         => l_location_id,
            p_vertical_datum_id_1 => l_native_datum,
            p_vertical_datum_id_2 => l_to_datum,
            p_offset              => l_offset,
            p_unit                => l_unit,
            p_description         => case l_estimate when true then 'ESTIMATE' else null end,
            p_fail_if_exists      => p_fail_if_exists,
            p_office_id           => l_office_id);
      end loop;
      if l_native_datum_db is null then
         update at_physical_location
            set vertical_datum = l_native_datum_db
          where location_code = p_location_code;
      end if;
      if l_local_datum_name is not null and l_local_datum_name_db is null then
         set_local_vert_datum_name(p_location_code, l_local_datum_name);
      end if;
      if l_elevation_db is null and l_elevation is not null then
         update at_physical_location
            set elevation = cwms_util.convert_units(l_elevation, l_unit, 'm')
          where location_code = p_location_code;
      end if;
   end set_vertical_datum_info;

   function get_vertical_datum_info_f(
      p_location_id in varchar2,
      p_unit        in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
      l_vert_datum_info varchar2(4000);
   begin
      get_vertical_datum_info(
         l_vert_datum_info,
         p_location_id,
         p_unit,
         p_office_id);
      return l_vert_datum_info;
   end get_vertical_datum_info_f;

   procedure set_vertical_datum_info(
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2)
   is
      l_xml  xmltype;
      l_node xmltype;
      function get_location_code(l_node in xmltype) return varchar2
      is
         l_location_id varchar2(57);
         l_office_id   varchar2(16);
      begin
         l_office_id := cwms_util.get_xml_text(l_node, '/vertical-datum-info/@office');
         if l_office_id is null then
               cwms_err.raise('ERROR', 'Office attribute is missing from <vertical-datum-info> element');
         end if;
         l_location_id := cwms_util.get_xml_text(l_node, '/vertical-datum-info/location');
         if l_location_id is null then
               cwms_err.raise('ERROR', '<vertical-datum-info> does not specify location in <location> element');
         end if;
         return cwms_loc.get_location_code(l_office_id, l_location_id);
      end;
   begin
      l_xml := xmltype(p_vert_datum_info);
      case l_xml.getrootelement
         when 'vertical-datum-info-set' then
            for i in 1..999999 loop
               l_node := cwms_util.get_xml_node(l_xml, '/vertical-datum-info-set/vertical-datum-info['||i||']');
               exit when l_node is null;
               set_vertical_datum_info(
                  get_location_code(l_node),
                  l_node,
                  p_fail_if_exists);
            end loop;
         when 'vertical-datum-info' then
            set_vertical_datum_info(
               get_location_code(l_xml),
               l_xml,
               p_fail_if_exists);
         else
            cwms_err.raise(
               'ERROR',
               'Unexpected root element for vertical datum info: '
               ||l_xml.getrootelement);
      end case;
   end set_vertical_datum_info;

   procedure set_vertical_datum_info(
      p_location_code   in number,
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2)
   is
   begin
      set_vertical_datum_info(
         p_location_code,
         xmltype(p_vert_datum_info),
         p_fail_if_exists);
   end set_vertical_datum_info;

   procedure set_vertical_datum_info(
      p_location_id     in varchar2,
      p_vert_datum_info in varchar2,
      p_fail_if_exists  in varchar2,
      p_office_id       in varchar2 default null)
   is
   begin
      set_vertical_datum_info(
         get_location_code(p_office_id, p_location_id),
         p_vert_datum_info,
         p_fail_if_exists);
   end set_vertical_datum_info;

   procedure get_local_vert_datum_name (
      p_local_vert_datum_name out varchar2,
      p_location_code         in  number)
   is
   begin
      p_local_vert_datum_name := get_local_vert_datum_name_f(p_location_code);
   end get_local_vert_datum_name;

   function get_local_vert_datum_name_f (
      p_location_code in number)
      return varchar2
   is
      l_local_vert_datum_name varchar2(16);
   begin
      begin
         select local_datum_name
           into l_local_vert_datum_name
           from at_vert_datum_local
          where location_code = p_location_code;
      exception
         when no_data_found then null;
      end;
      return l_local_vert_datum_name;
   end get_local_vert_datum_name_f;

   procedure get_local_vert_datum_name (
      p_local_vert_datum_name out varchar2,
      p_location_id           in  varchar2,
      p_office_id             in  varchar2 default null)
   is
   begin
      p_local_vert_datum_name := get_local_vert_datum_name_f(p_location_id, p_office_id);
   end get_local_vert_datum_name;

   function get_local_vert_datum_name_f (
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return get_local_vert_datum_name_f(cwms_loc.get_location_code(p_office_id, p_location_id));
   end get_local_vert_datum_name_f;

   procedure set_local_vert_datum_name(
      p_location_code   in number,
      p_vert_datum_name in varchar2,
      p_fail_if_exists  in varchar2 default 'T')
   is
      l_local_vert_datum_name varchar2(16);
   begin
      l_local_vert_datum_name := get_local_vert_datum_name_f(p_location_code);
      case
         when l_local_vert_datum_name is null then
            insert into at_vert_datum_local values (p_location_code, p_vert_datum_name);
         when l_local_vert_datum_name = p_vert_datum_name then
            null;
         when cwms_util.is_true(p_fail_if_exists) then
            declare
               l_office_id   varchar2(16);
               l_location_id varchar2(57);
            begin
               select o.office_id,
                      bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id
                 into l_office_id,
                      l_location_id
                 from at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
                where pl.location_code = p_location_code
                  and bl.base_location_code = pl.base_location_code
                  and o.office_code = bl.db_office_code;
               cwms_err.raise(
                  'ERROR',
                  'Location '
                  ||l_office_id
                  ||'/'
                  ||l_location_id
                  ||' already has a local vertical datum name of '
                  ||l_local_vert_datum_name);
            end;
         else
            update at_vert_datum_local
               set local_datum_name = p_vert_datum_name
             where location_code = p_location_code;
      end case;
   end set_local_vert_datum_name;

   procedure set_local_vert_datum_name(
      p_location_id     in varchar2,
      p_vert_datum_name in varchar2,
      p_fail_if_exists  in varchar2 default 'T',
      p_office_id       in varchar2 default null)
   is
   begin
      set_local_vert_datum_name(
         p_location_code   => cwms_loc.get_location_code(p_office_id, p_location_id),
         p_vert_datum_name => p_vert_datum_name,
         p_fail_if_exists  => p_fail_if_exists);
   end set_local_vert_datum_name;

   procedure delete_local_vert_datum_name (
      p_location_code in number)
   is
   begin
      delete from at_vert_datum_local where location_code = p_location_code;
   exception
      when no_data_found then null;
   end delete_local_vert_datum_name;

   procedure delete_local_vert_datum_name (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   is
   begin
      delete_local_vert_datum_name(get_location_code(p_office_id, p_location_id));
   end delete_local_vert_datum_name;


   function is_vert_datum_offset_estimated(
      p_location_code in integer,
      p_from_datum    in varchar2,
      p_to_datum      in varchar2)
      return varchar2
   is
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      get_vertical_datum_offset(
         l_offset,
         l_effective_date,
         l_estimate,
         p_location_code,
         p_from_datum,
         p_to_datum);

      return l_estimate;
   end is_vert_datum_offset_estimated;

   function is_vert_datum_offset_estimated(
      p_location_id in varchar2,
      p_from_datum  in varchar2,
      p_to_datum    in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
      l_offset         binary_double;
      l_effective_date date;
      l_estimate       varchar2(1);
   begin
      get_vertical_datum_offset(
         l_offset,
         l_effective_date,
         l_estimate,
         p_location_id,
         p_from_datum,
         p_to_datum,
         p_office_id=>p_office_id);

      return l_estimate;
   end is_vert_datum_offset_estimated;


   function get_location_kind_ancestors(
      p_location_kind_id  in varchar2,
      p_include_this_kind in varchar2 default 'F')
      return str_tab_t
   is
      l_ancestors          str_tab_t;
      l_location_kind_code integer;
   begin
      begin
         select location_kind_code
           into l_location_kind_code
           from cwms_location_kind
          where location_kind_id = upper(trim(p_location_kind_id));
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_location_kind_id, 'CWMS location kind');
      end;
      select location_kind_id
        bulk collect
        into l_ancestors
        from cwms_location_kind
       where location_kind_code in (select * from table(get_location_kind_ancestors(l_location_kind_code, p_include_this_kind)));

      return l_ancestors;
   end get_location_kind_ancestors;

   function get_location_kind_code(p_location_code in number)
      return integer
   is
   begin
     begin
       return check_location_kind_code(p_location_code);
     exception
       when others then
         return 0;
     end;
   end get_location_kind_code;

   function get_location_kind_ancestors(
      p_location_kind_code in integer,
      p_include_this_kind  in varchar2 default 'F')
      return number_tab_t
   is
      l_ancestors  number_tab_t;
      l_code       integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_kind_code is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_KIND_CODE');
      end if;
      if p_include_this_kind is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_INCLUDE_THIS_KIND');
      end if;
      begin
         select location_kind_code
           into l_code
           from cwms_location_kind
          where location_kind_code = p_location_kind_code;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_location_kind_code, 'CWMS location kind code');
      end;
      select location_kind_code
        bulk collect
        into l_ancestors
        from (select location_kind_code,
                      rownum as seq
                 from cwms_location_kind
                start with location_kind_code = p_location_kind_code
             connect by prior parent_location_kind = location_kind_code
             )
       order by seq desc;
      if not cwms_util.return_true_or_false(p_include_this_kind) then
         l_ancestors.trim;
      end if;
      return l_ancestors;
   end get_location_kind_ancestors;

   function get_location_kind_descendants(
      p_location_kind_id   in varchar2,
      p_include_this_kind  in varchar2 default 'F',
      p_include_all_levels in varchar2 default 'T')
      return str_tab_t
   is
      l_location_kind_code integer;
      l_descendants        str_tab_t;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_kind_id is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_KIND_ID');
      end if;
      if p_include_all_levels is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_INCLUDE_ALL_LEVELS');
      end if;
      begin
         select location_kind_code
           into l_location_kind_code
           from cwms_location_kind
          where location_kind_id = upper(trim(p_location_kind_id));
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_location_kind_id, 'CWMS location kind');
      end;

      select location_kind_id
        bulk collect
        into l_descendants
        from cwms_location_kind
       where location_kind_code in (select * from table(get_location_kind_descendants(l_location_kind_code, p_include_this_kind, p_include_all_levels)));

      return l_descendants;
   end get_location_kind_descendants;

   function get_location_kind_descendants(
      p_location_kind_code in integer,
      p_include_this_kind  in varchar2 default 'F',
      p_include_all_levels in varchar2 default 'T')
      return number_tab_t
   is
      l_descendants number_tab_t;
      l_code        integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_location_kind_code is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_KIND_CODE');
      end if;
      if p_include_all_levels is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_INCLUDE_ALL_LEVELS');
      end if;
      begin
         select location_kind_code
           into l_code
           from cwms_location_kind
          where location_kind_code = p_location_kind_code;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', p_location_kind_code, 'CWMS location kind code');
      end;

      if cwms_util.return_true_or_false(p_include_all_levels) then
          select location_kind_code
             bulk collect
             into l_descendants
             from cwms_location_kind
            start with location_kind_code = p_location_kind_code
         connect by prior location_kind_code = parent_location_kind;
         if not cwms_util.return_true_or_false(p_include_this_kind) then
            l_descendants.delete(1);
         end if;
      else
         if cwms_util.return_true_or_false(p_include_this_kind) then
            select location_kind_code
              bulk collect
              into l_descendants
              from cwms_location_kind
             where p_location_kind_code in (location_kind_code, parent_location_kind);
         else
            select location_kind_code
              bulk collect
              into l_descendants
              from cwms_location_kind
             where parent_location_kind = p_location_kind_code;
         end if;
      end if;
      return l_descendants;
   end get_location_kind_descendants;

   function get_valid_loc_kind_ids_txt(
      p_loc_kind_id in varchar2)
      return varchar2
   is
      type valid_kinds_t is table of varchar2(32767) index by varchar2(32);
      l_valid_kinds valid_kinds_t;
   begin
      l_valid_kinds('BASIN'          ) := 'BASIN';
      l_valid_kinds('EMBANKMENT'     ) := 'EMBANKMENT,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('ENTITY'         ) := 'ENTITY,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('GATE'           ) := 'GATE,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('LOCK'           ) := 'LOCK,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('OUTLET'         ) := 'OUTLET,STREAM_LOCATION,WEATHER_GAGE,OVERFLOW,GATE';
      l_valid_kinds('OVERFLOW'       ) := 'OVERFLOW,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('PROJECT'        ) := 'PROJECT,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('PUMP'           ) := 'PUMP,STREAM_GAGE';
      l_valid_kinds('SITE'           ) := 'SITE,BASIN,EMBANKMENT,ENTITY,LOCK,OUTLET,PROJECT,PUMP,STREAM,STREAM_LOCATION,STREAM_REACH,TURBINE,WEATHER_GAGE';
      l_valid_kinds('STREAM'         ) := 'STREAM';
      l_valid_kinds('STREAM_GAGE'    ) := 'STREAM_GAGE,EMBANKMENT,ENTITY,LOCK,OUTLET,PROJECT,PUMP,TURBINE';
      l_valid_kinds('STREAM_LOCATION') := 'STREAM_LOCATION,EMBANKMENT,ENTITY,LOCK,OUTLET,PROJECT,PUMP,TURBINE,STREAM_GAGE';
      l_valid_kinds('STREAM_REACH'   ) := 'STREAM_REACH';
      l_valid_kinds('TURBINE'        ) := 'TURBINE,STREAM_LOCATION,WEATHER_GAGE';
      l_valid_kinds('WEATHER_GAGE'   ) := 'EMBANKMENT,ENTITY,LOCK,OUTLET,PROJECT,PUMP,TURBINE,STREAM_LOCATION,WEATHER_GAGE';

      return l_valid_kinds(upper(trim(p_loc_kind_id)));
   end get_valid_loc_kind_ids_txt;

   function get_valid_loc_kind_ids(
      p_loc_kind_id in varchar)
      return str_tab_t
   is
   begin
      return cwms_util.split_text(get_valid_loc_kind_ids_txt(p_loc_kind_id), ',');
   end get_valid_loc_kind_ids;

   function get_valid_loc_kind_ids_txt(
      p_location_code in integer)
      return varchar2
   is
      l_loc_kind_id      cwms_location_kind.location_kind_id%type;
      l_valid_kind_ids   str_tab_t;
   begin
      select lk.location_kind_id
        into l_loc_kind_id
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = p_location_code
         and lk.location_kind_code = pl.location_kind;

      l_valid_kind_ids := cwms_util.split_text(get_valid_loc_kind_ids_txt(l_loc_kind_id), ',');
      return cwms_util.join_text(l_valid_kind_ids, ',');
   end get_valid_loc_kind_ids_txt;

   function get_valid_loc_kind_ids(
      p_location_code in integer)
      return str_tab_t
   is
   begin
      return cwms_util.split_text(get_valid_loc_kind_ids_txt(p_location_code), ',');
   end get_valid_loc_kind_ids;

   function can_store(
      p_location_code    in integer,
      p_location_kind_id in varchar2)
      return boolean
   is
      l_can_store_kind_ids str_tab_t;
      l_location_kind      at_physical_location.location_kind%type;
      l_location_kind_id   cwms_location_kind.location_kind_id%type;
      l_count              pls_integer;
   begin
      l_location_kind_id := upper(trim(p_location_kind_id));
      select location_kind
        into l_location_kind
        from at_physical_location
       where location_code = p_location_code;

      select location_kind_id
        bulk collect
        into l_can_store_kind_ids
        from (select column_value as location_kind_id
                from table(get_valid_loc_kind_ids(p_location_code))
              union
              select location_kind_id
                from cwms_location_kind
               where location_kind_code in
                     (select column_value
                       from table(get_location_kind_ancestors(l_location_kind))
                     )
             );
      select count(*)
        into l_count
        from table(l_can_store_kind_ids)
       where column_value = l_location_kind_id
          or (l_location_kind_id = 'GAGE'
              and column_value in ('STREAM_GAGE', 'WEATHER_GAGE')
             );
      return l_count > 0;
   end can_store;

   function can_store_txt(
      p_location_code    in integer,
      p_location_kind_id in varchar2)
      return varchar2
   is
   begin
      return case can_store(p_location_code, p_location_kind_id)
             when true  then 'T'
             when false then 'F'
             end;
   end can_store_txt;

   procedure update_location_kind(
      p_location_code    in integer,
      p_location_kind_id in varchar2,
      p_add_delete       in varchar2)
   is
      l_location_kind_id     cwms_location_kind.location_kind_id%type;
      l_current_kind_id      cwms_location_kind.location_kind_id%type;
      l_update               boolean;
      l_add                  boolean;
      l_count                pls_integer;
      l_loc_kind_names       str_tab_t;
      l_loc_kind_descendants str_tab_t;
   begin
      if p_add_delete not in ('a', 'A', 'd', 'D') then
         cwms_err.raise('ERROR', 'Parameter P_Add_Delete must be one of ''A'' or ''D''');
      end if;
      l_add := p_add_delete in ('a', 'A');

      select lk.location_kind_id
        into l_current_kind_id
        from at_physical_location pl,
             cwms_location_kind lk
       where pl.location_code = p_location_code
         and lk.location_kind_code = pl.location_kind;

      l_location_kind_id := upper(trim(p_location_kind_id));

      if l_add then
         ----------------------------
         -- adding a location kind --
         ----------------------------
         if l_location_kind_id in ('GAGE', 'STREAM_GAGE', 'WEATHER_GAGE') then
            case l_current_kind_id
            when 'SITE' then
               l_update := true;
               l_location_kind_id := 'WEATHER_GAGE';
            when 'STREAM_LOCATION' then
               l_update := true;
               l_location_kind_id := 'STREAM_GAGE';
            else
               l_update := false;
            end case;
         else
            l_update := case l_location_kind_id
                        when 'BASIN'           then l_current_kind_id = 'SITE'
                        when 'EMBANKMENT'      then l_current_kind_id in ('SITE', 'STREAM_LOCATION', 'STREAM_GAGE', 'WEATHER_GAGE')
                        when 'ENTITY'          then l_current_kind_id in ('SITE', 'STREAM_LOCATION', 'STREAM_GAGE', 'WEATHER_GAGE')
                        when 'GATE'            then l_current_kind_id = 'OUTLET'
                        when 'LOCK'            then l_current_kind_id in ('SITE', 'STREAM_LOCATION', 'STREAM_GAGE', 'WEATHER_GAGE')
                        when 'OUTLET'          then l_current_kind_id in ('SITE', 'STREAM_LOCATION', 'STREAM_GAGE', 'WEATHER_GAGE')
                        when 'OVERFLOW'        then l_current_kind_id = 'OUTLET'
                        when 'PROJECT'         then l_current_kind_id in ('SITE', 'STREAM_LOCATION', 'STREAM_GAGE', 'WEATHER_GAGE')
                        when 'PUMP'            then l_current_kind_id in ('STREAM_LOCATION', 'STREAM_GAGE')
                        when 'SITE'            then false
                        when 'STREAM'          then l_current_kind_id = 'SITE'
                        when 'STREAM_LOCATION' then l_current_kind_id = 'SITE'
                        when 'STREAM_REACH'    then l_current_kind_id = 'SITE'
                        when 'TURBINE'         then l_current_kind_id in ('SITE', 'STREAM_LOCATION', 'STREAM_GAGE', 'WEATHER_GAGE')
                        end;
         end if;
      else
         ------------------------------
         -- deleting a location kind --
         ------------------------------
         case
         when l_location_kind_id in ('GAGE', 'STREAM_GAGE', 'WEATHER_GAGE') then
            case
            when l_current_kind_id = 'WEATHER_GAGE' then
               l_location_kind_id := 'SITE';
               l_update := true;
            when l_current_kind_id = 'STREAM_GAGE' then
               l_location_kind_id := 'STREAM_LOCATION';
               l_update := true;
            else
               l_update := false;
            end case;
         when l_location_kind_id = 'STREAM_LOCATION' then
            case
            when l_current_kind_id = 'STREAM_GAGE' then
               l_location_kind_id := 'WEATHER_GAGE';
               l_update := true;
            when l_current_kind_id = 'STREAM_LOCATION' then
               l_location_kind_id := 'SITE';
               l_update := true;
            else
               l_update := false;
            end case;
         else
            l_loc_kind_names := get_loc_kind_names(p_location_code);
            select column_value
              bulk collect
              into l_loc_kind_descendants
              from (select column_value from table(get_location_kind_descendants(l_current_kind_id, 'F'))
                    union
                    select column_value from table(get_location_kind_descendants(l_location_kind_id, 'F'))
                   );
            select count(*)
              into l_count
              from table(l_loc_kind_names) a,
                   table(l_loc_kind_descendants) b
             where a.column_value = b.column_value;
            l_update := l_count = 0;
            if l_update then
               case l_location_kind_id
               when 'BASIN' then
                  l_location_kind_id := 'SITE';
               when 'EMBANKMENT' then
                  if regexp_instr(get_valid_loc_kind_ids_txt(p_location_code), '\WSTREAM_LOCATION\W') > 0 then
                     l_location_kind_id := 'STREAM_LOCATION';
                  else
                     l_location_kind_id := 'SITE';
                  end if;
               when 'ENTITY' then
                  select count(*) into l_count from at_stream_location where location_code = p_location_code;
                  if l_count = 0 then
                     l_location_kind_id := 'SITE';
                  else
                     l_location_kind_id := 'STREAM_LOCATION';
                  end if;
               when 'GATE' then
                  l_location_kind_id := 'OUTLET';
               when 'LOCK' then
                  select count(*) into l_count from at_stream_location where location_code = p_location_code;
                  if l_count = 0 then
                     l_location_kind_id := 'SITE';
                  else
                     l_location_kind_id := 'STREAM_LOCATION';
                  end if;
               when 'OUTLET' then
                  select count(*) into l_count from at_stream_location where location_code = p_location_code;
                  if l_count = 0 then
                     l_location_kind_id := 'SITE';
                  else
                     l_location_kind_id := 'STREAM_LOCATION';
                  end if;
               when 'OVERFLOW' then
                  l_location_kind_id := 'OUTLET';
               when 'PROJECT' then
                  select count(*) into l_count from at_stream_location where location_code = p_location_code;
                  if l_count = 0 then
                     l_location_kind_id := 'SITE';
                  else
                     l_location_kind_id := 'STREAM_LOCATION';
                  end if;
               when 'PUMP' then
                  l_location_kind_id := 'STREAM_LOCATION';
               when 'SITE' then
                  l_update := false;
               when 'STREAM' then
                  l_location_kind_id := 'SITE';
               when 'STREAM_LOCATION' then
                  select count(*) into l_count from at_gage where gage_location_code = p_location_code;
                  if l_count =  0 then
                     l_location_kind_id := 'SITE';
                  else
                     l_location_kind_id := 'WEATHER_GAGE';
                  end if;
               when 'STREAM_REACH' then
                  l_location_kind_id := 'SITE';
               when 'TURBINE' then
                  select count(*) into l_count from at_stream_location where location_code = p_location_code;
                  if l_count = 0 then
                     l_location_kind_id := 'SITE';
                  else
                     l_location_kind_id := 'STREAM_LOCATION';
                  end if;
               end case;
            end if;
         end case;
      end if;
      if l_update is null then
         cwms_err.raise('INVALID_ITEM', l_location_kind_id, 'CWMS location kind');
      end if;
      if l_update then
         update at_physical_location
            set location_kind =
                (select location_kind_code
                   from cwms_location_kind
                  where location_kind_id = l_location_kind_id
                )
          where location_code = p_location_code;
      end if;
   end update_location_kind;

   PROCEDURE get_valid_loc_kind_ids (p_loc_kind_ids      OUT SYS_REFCURSOR,
                                 p_location_id    IN     VARCHAR2,
                                 p_office_id      IN     VARCHAR2)
   IS
      l_loc_kind_id cwms_location_kind.location_kind_id%TYPE;
   BEGIN
      BEGIN
         l_loc_kind_id :=
            cwms_loc.check_location_kind (p_location_id   => p_location_id,
                                          p_office_id     => p_office_id);

         l_loc_kind_id := get_valid_loc_kind_ids_txt(l_loc_kind_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_loc_kind_id := 'ERROR';
      END;

      open p_loc_kind_ids for
         select * from table(cwms_util.split_text(l_loc_kind_id, ','));
   END;

   FUNCTION get_valid_loc_kind_ids_tab (p_location_id   IN VARCHAR2,
                                    p_office_id     IN VARCHAR2)
      RETURN cat_loc_kind_tab_t
      PIPELINED
   IS
      query_cursor   SYS_REFCURSOR;
      output_row     cat_loc_kind_rec_t;
   BEGIN
      get_valid_loc_kind_ids (query_cursor, p_location_id, p_office_id);

      LOOP
         FETCH query_cursor INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;
   END;

   FUNCTION can_revert_loc_kind_to (p_location_id   IN VARCHAR2,
                                p_office_id     IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_loc_code        at_physical_location.location_code%TYPE;
      l_loc_kind_id     cwms_location_kind.location_kind_id%TYPE;
      l_gage            pls_integer;
      l_stream          pls_integer;
   BEGIN
      l_loc_code :=
         CWMS_LOC.get_location_code (p_db_office_id   => p_office_id,
                                     p_location_id    => p_location_id);

      l_loc_kind_id :=
         cwms_loc.check_location_kind (p_location_id   => p_location_id,
                                       p_office_id     => p_office_id);

      case
      when l_loc_kind_id in ('BASIN', 'STREAM', 'STREAM_LOCATION', 'STREAM_REACH', 'WEATHER_GAGE') then
         l_loc_kind_id := 'SITE';
      when l_loc_kind_id in ('EMBANKMENT', 'ENTITY', 'LOCK', 'OUTLET', 'PROJECT', 'TURBINE') then
         select count(*) into l_gage from at_gage where gage_location_code = l_loc_code;
         select count(*) into l_stream from at_stream_location where location_code = l_loc_code;
         if l_gage = 0 then
            if l_stream = 0 then
               l_loc_kind_id := 'SITE';
            else
               l_loc_kind_id := 'STREAM_LOCATION';
            end if;
         else
            if l_stream = 0 then
               l_loc_kind_id := 'WEATHER_GAGE';
            else
               l_loc_kind_id := 'STREAM_GAGE';
            end if;
         end if;
      when l_loc_kind_id in ('GATE', 'OVERFLOW') then
         l_loc_kind_id := 'OUTLET';
      when l_loc_kind_id = 'PUMP' then
         select count(*) into l_gage from at_gage where gage_location_code = l_loc_code;
         if l_gage = 0 then
            l_loc_kind_id := 'STREAM_LOCATION';
         else
            l_loc_kind_id := 'STREAM_GAGE';
         end if;
      when l_loc_kind_id = 'STREAM_GAGE' then
         l_loc_kind_id := 'STREAM_LOCATION';
      else
         l_loc_kind_id := 'ERROR';
      end case;

      return l_loc_kind_id;
   END;

   function get_location_ids(
      p_location_code in integer,
      p_exclude       in varchar2 default null)
      return varchar2
   is
      l_names str_tab_t;
   begin
      select name
        bulk collect
        into l_names
        from (select distinct
                     loc_alias_id as name
                from at_loc_group_assignment
               where location_code = p_location_code
                 and loc_alias_id is not null
              union all
              select bl.base_location_id
                     ||substr('-', 1, length(pl.sub_location_id))
                     ||pl.sub_location_id as name
                from at_physical_location pl,
                     at_base_location bl
               where pl.location_code = p_location_code
                 and bl.base_location_code = pl.base_location_code
             )
       where name != case when p_exclude is null then '.' else p_exclude end
       order by 1;
       return cwms_util.join_text(l_names, '.');
   end get_location_ids;

   function point_in_bounding_box(
      p_shape in sdo_geometry,
      p_x     in number,
      p_y     in number)
      return boolean
   is
      l_xy double_tab_tab_t := double_tab_tab_t();
   begin
      for rec in (select rownum as i, x, y from table(sdo_util.getvertices(sdo_geom.sdo_mbr(p_shape)))) loop
         l_xy.extend;
         l_xy(rec.i) := double_tab_t(rec.x, rec.y);
      end loop;
      return p_x between l_xy(1)(1) and l_xy(2)(1) and p_y between l_xy(1)(2) and l_xy(2)(2);
   end point_in_bounding_box;

   function point_below_line(
      p_x  in out nocopy number,
      p_y  in out nocopy number,
      p_x1 in number,
      p_y1 in number,
      p_x2 in number,
      p_y2 in number)
      return boolean
   is
      l_slope     number;
      l_intercept number;
   begin
      if (p_x1 < p_x and p_x <= p_x2) or
         (p_x2 < p_x and p_x <= p_x1)
      then
         if p_y1 >= p_y and p_y2 >= p_y then
            return true;
         elsif p_y1 < p_y and p_y2 < p_y then
            return false;
         else
            l_slope := (p_y2 - p_y1) / (p_x2 - p_x1);
            l_intercept := p_y1 - l_slope * p_x1;
            return l_slope * p_x + l_intercept >= p_y;
         end if;
      else
         return false;
      end if;
   end point_below_line;

   function point_in_polygon(
      p_shape in sdo_geometry,
      p_x     in number,
      p_y     in number)
      return varchar
   is
      l_x        number := p_x;
      l_y        number := p_y;
      l_vertices double_tab_tab_t;
      l_count    integer;
      l_vertex_count integer;
   begin
      if point_in_bounding_box(p_shape, l_x, l_y) then
         select double_tab_t(x, y)
           bulk collect
           into l_vertices
           from table(select sdo_util.getvertices(p_shape) from dual);
         select count(*)
           into l_vertex_count
           from table(l_vertices);
         l_count := 0;
         for i in 1..l_vertex_count-1 loop
            if point_below_line(
                  l_x,
                  l_y,
                  l_vertices(i)(1),
                  l_vertices(i)(2),
                  l_vertices(i+1)(1),
                  l_vertices(i+1)(2))
            then
               l_count := l_count + 1;
            end if;
         end loop;
         return case
                when mod(l_count, 2) = 1 then 'T'
                else 'F'
                end;
      else
         return 'F';
      end if;
   end point_in_polygon;

   function point_in_polygon(
      p_vertices in double_tab_tab_t,
      p_x        in number,
      p_y        in number)
      return varchar
   is
      l_x            number := p_x;
      l_y            number := p_y;
      l_vertices     double_tab_tab_t;
      l_min_x        number;
      l_max_x        number;
      l_min_y        number;
      l_max_y        number;
      l_count        integer;
      l_vertex_count integer;
   begin
      ----------------------------------------
      -- get the minimum bounding rectangle --
      ----------------------------------------
      select min(column_value),
             max(column_value)
        into l_min_x,
             l_max_x
        from table(cwms_util.get_column(p_vertices, 1));

      select min(column_value),
             max(column_value)
        into l_min_y,
             l_max_y
        from table(cwms_util.get_column(p_vertices, 2));

      if l_x between l_min_x and l_max_x and
         l_y between l_min_y and l_max_y
      then
         -------------------------
         -- point is in the MBR --
         -------------------------
         select count(*)
           into l_vertex_count
           from table(p_vertices);
         l_vertices := p_vertices;
         ------------------------------------
         -- close the polygon if necessary --
         ------------------------------------
         if l_vertices(l_vertex_count) != l_vertices(1) then
            l_vertex_count := l_vertex_count + 1;
            l_vertices.extend;
            l_vertices(l_vertex_count) := l_vertices(1);
         end if;
         -------------------------------------------------------
         -- count the number of line segments above the point --
         -------------------------------------------------------
         l_count := 0;
         for i in 1..l_vertex_count-1 loop
            if point_below_line(
                  l_x,
                  l_y,
                  p_vertices(i)(1),
                  p_vertices(i)(2),
                  p_vertices(i+1)(1),
                  p_vertices(i+1)(2))
            then
               l_count := l_count + 1;
            end if;
         end loop;
         return case
                when mod(l_count, 2) = 1 then 'T'
                else 'F'
                end;
      else
         return 'F';
      end if;
   end point_in_polygon;

   function get_bounding_ofc_code(
      p_lat in number,
      p_lon in number)
      return integer
   is
      l_codes number_tab_t;
   begin
      select office_code
        bulk collect
        into l_codes
        from cwms_agg_district ad
       where sdo_contains(
         ad.shape,
         sdo_geometry(
            2003,
            8265 ,
            null,
            mdsys.sdo_elem_info_array(1,1003,1),
            mdsys.sdo_ordinate_array(p_lon, p_lat))) = 'TRUE';
      return case
             when l_codes.count = 1 then l_codes(1)
             else null
             end;
   end get_bounding_ofc_code;

   function get_bounding_ofc_id(
      p_lat in number,
      p_lon in number)
      return varchar2
   is
      l_office_id cwms_office.office_id%type;
   begin
      select office_id
        into l_office_id
        from cwms_office
       where office_code = get_bounding_ofc_code(p_lat, p_lon);

      return l_office_id;
   end get_bounding_ofc_id;

   function get_bounding_ofc_code_for_loc(
      p_location_code in integer)
      return integer
   is
      l_sub_rec  at_physical_location%rowtype;
      l_base_rec at_physical_location%rowtype;
   begin
      select * into l_sub_rec  from at_physical_location where location_code = p_location_code;
      select * into l_base_rec from at_physical_location where location_code = l_sub_rec.base_location_code;
      return get_bounding_ofc_code(
                coalesce(l_sub_rec.latitude,  l_base_rec.latitude),
                coalesce(l_sub_rec.longitude, l_base_rec.longitude));
   end get_bounding_ofc_code_for_loc;

   function get_bounding_ofc_code_for_loc(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return integer
   is
   begin
      return get_bounding_ofc_code_for_loc(get_location_code(p_office_id, p_location_id));
   end get_bounding_ofc_code_for_loc;

   function get_bounding_ofc_id_for_loc(
      p_location_code in integer)
      return varchar2
   is
      l_office_id cwms_office.office_id%type;
   begin
      select office_id
        into l_office_id
        from cwms_office
       where office_code = get_bounding_ofc_code_for_loc(p_location_code);

      return l_office_id;
   end get_bounding_ofc_id_for_loc;

   function get_bounding_ofc_id_for_loc(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2
   is
   begin
      return get_bounding_ofc_id_for_loc(get_location_code(p_office_id, p_location_id));
   end get_bounding_ofc_id_for_loc;

   function get_county_code(
      p_lat in number,
      p_lon in number)
      return integer
   is
      l_codes      number_tab_t;
   begin
   select c.county_code
     bulk collect
     into l_codes
     from cwms_county_sp c
    where sdo_contains(
      c.shape,
      sdo_geometry(
         2003,
         8265 ,
         null,
         mdsys.sdo_elem_info_array(1,1003,1),
         mdsys.sdo_ordinate_array(p_lon, p_lat))) = 'TRUE';
      return case
             when l_codes.count = 1 then l_codes(1)
             else null
             end;
   end get_county_code;

   function get_county_id(
      p_lat in number,
      p_lon in number)
      return str_tab_t
   is
      l_county_code integer;
      l_results     str_tab_t := str_tab_t(null, null);
   begin
      l_county_code := get_county_code(p_lat, p_lon);
      if l_county_code is not null then
         select county,
                state
           into l_results(1),
                l_results(2)
           from cwms_county_sp
          where county_code = l_county_code;
      end if;
      return l_results;
   end get_county_id;

   function get_county_code_for_loc(
      p_location_code in integer)
      return integer
   is
      l_sub_rec  at_physical_location%rowtype;
      l_base_rec at_physical_location%rowtype;
   begin
      select * into l_sub_rec  from at_physical_location where location_code = p_location_code;
      select * into l_base_rec from at_physical_location where location_code = l_sub_rec.base_location_code;
      return get_county_code(
                coalesce(l_sub_rec.latitude,  l_base_rec.latitude),
                coalesce(l_sub_rec.longitude, l_base_rec.longitude));
   end get_county_code_for_loc;

   function get_county_code_for_loc(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return integer
   is
   begin
      return get_county_code_for_loc(cwms_loc.get_location_code(p_office_id, p_location_id));
   end get_county_code_for_loc;

   function get_county_id_for_loc(
      p_location_code in integer)
      return str_tab_t
   is
      l_county_code integer;
      l_results     str_tab_t := str_tab_t(null, null);
   begin
      l_county_code := get_county_code_for_loc(p_location_code);
      if l_county_code is not null then
         select county,
                state
           into l_results(1),
                l_results(2)
           from cwms_county_sp
          where county_code = l_county_code;
      end if;
      return l_results;
   end get_county_id_for_loc;

   function get_county_id_for_loc(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return str_tab_t
   is
   begin
      return get_county_id_for_loc(cwms_loc.get_location_code(p_office_id, p_location_id));
   end get_county_id_for_loc;


   function get_nearest_city(
      p_lat in number,
      p_lon in number)
      return str_tab_t
   is
      l_results str_tab_t;
   begin
      select str_tab_t(city_name, state_name)
        into l_results
        from cwms_cities_sp
       where sdo_nn(shape,
                    sdo_geometry(2001, 8265, null, mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(p_lon, p_lat)),
                    'sdo_num_res=1',
                    1) = 'TRUE';
       return l_results;
   end get_nearest_city;

   function get_nearest_city_for_loc(
      p_location_code in integer)
      return str_tab_t
   is
      l_sub_rec  at_physical_location%rowtype;
      l_base_rec at_physical_location%rowtype;
   begin
      select * into l_sub_rec  from at_physical_location where location_code = p_location_code;
      select * into l_base_rec from at_physical_location where location_code = l_sub_rec.base_location_code;
      return get_nearest_city(
                coalesce(l_sub_rec.latitude,  l_base_rec.latitude),
                coalesce(l_sub_rec.longitude, l_base_rec.longitude));
   end get_nearest_city_for_loc;

   function get_nearest_city_for_loc(
      p_location_id in varchar2,
      p_office_id   in varchar2 default null)
      return str_tab_t
   is
   begin
      return get_nearest_city_for_loc(cwms_loc.get_location_code(p_office_id, p_location_id));
   end get_nearest_city_for_loc;

   procedure retrieve_locations(
      p_results        out clob,
      p_date_time      out date,
      p_query_time     out integer,
      p_format_time    out integer,
      p_location_count out integer,
      p_names          in  varchar2 default null,
      p_format         in  varchar2 default null,
      p_units          in  varchar2 default null,
      p_datums         in  varchar2 default null,
      p_office_id      in  varchar2 default null)
   is
      type loc_rec_t is record(
         location_code       at_physical_location.location_code%type,
         office_id           cwms_office.office_id%type,
         location_id         av_loc2.location_id%type,
         long_name           at_physical_location.long_name%type,
         public_name         at_physical_location.public_name%type,
         description         at_physical_location.description%type,
         latitude            at_physical_location.latitude%type,
         longitude           at_physical_location.longitude%type,
         horizontal_datum    at_physical_location.horizontal_datum%type,
         elevation           at_physical_location.elevation%type,
         elevation_unit      cwms_unit.unit_id%type,
         elevation_estimated varchar2(1),
         vertical_datum      at_physical_location.vertical_datum%type,
         time_zone_name      cwms_time_zone.time_zone_name%type,
         county              cwms_county.county_name%type,
         state_initial       cwms_state.state_initial%type,
         nation_id           cwms_nation.nation_id%type,
         nearest_city        at_physical_location.nearest_city%type,
         bounding_office     cwms_office.office_id%type,
         location_kind       cwms_location_kind.location_kind_id%type,
         location_type       at_physical_location.location_type%type);
      type loc_tab_t is table of loc_rec_t;
      type loc_tab_tab_t is table of loc_tab_t;
      type vchar_set_t is table of boolean index by varchar2(32767);
      type indexes_rec_t is record(i integer, j integer);
      type indexes_tab_t is table of indexes_rec_t index by varchar2(32767);
      type str_tab_tab_tab_t is table of str_tab_tab_t;
      l_data                 clob;
      l_names                str_tab_t;
      l_format               varchar2(16);
      l_units                str_tab_t;
      l_datums               str_tab_t;
      l_office_id            varchar2(16);
      l_location_id_mask     varchar2(256);
      l_ts1                  timestamp;
      l_ts2                  timestamp;
      l_query_time           date;
      l_elapsed_query        interval day (0) to second (6);
      l_elapsed_format       interval day (0) to second (6);
      l_count                pls_integer;
      l_temp                 varchar2(256);
      l_alternate_names      str_tab_tab_tab_t;
      l_locations            loc_tab_tab_t;
      l_unique_codes         vchar_set_t;
      l_indexes              indexes_tab_t;
      l_text                 varchar2(32767);

      function iso_duration(
         p_intvl in dsinterval_unconstrained)
         return varchar2
      is
         l_hours   integer := extract(hour   from p_intvl);
         l_minutes integer := extract(minute from p_intvl);
         l_seconds number  := extract(second from p_intvl);
         l_iso     varchar2(17) := 'PT';
      begin
         if l_hours > 0 then
            l_iso := l_iso || l_hours || 'H';
         end if;
         if l_minutes > 0 then
            l_iso := l_iso || l_minutes || 'M';
         end if;
         if l_seconds > 0 then
            l_iso := l_iso || trim(to_char(l_seconds, '90.999')) || 'S';
         end if;
         if l_iso = 'PT' then
            l_iso := l_iso || '0S';
         end if;
         return l_iso;
      end;

   begin
   l_query_time := sysdate;
   ----------------------------
   -- process the parameters --
   ----------------------------
   -----------
   -- names --
   -----------
   if p_names is null then
      l_names := str_tab_t();
      l_names.extend;
      l_names(1) := '*';
   else
      l_names := cwms_util.split_text(p_names, '|');
      for i in 1..l_names.count loop
         l_names(i) := trim(l_names(i));
      end loop;
   end if;
   ------------
   -- format --
   ------------
   if p_format is null then
      l_format := 'TAB';
   else
      l_format := upper(trim(p_format));
      if l_format not in ('TAB','CSV','XML','JSON') then
         cwms_err.raise('INVALID_ITEM', l_format, 'rating response format');
      end if;
   end if;
   ------------
   -- office --
   ------------
   if p_office_id is null then
      l_office_id := '*';
   else
      begin
         l_office_id := upper(trim(p_office_id));
         select office_id into l_office_id from cwms_office where office_id = l_office_id;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_OFFICE_ID', l_office_id);
      end;
   end if;
   -----------
   -- units --
   -----------
   if p_units is null then
      l_units := str_tab_t();
      l_units.extend(l_names.count);
      for i in 1..l_units.count loop
         l_units(i) := 'EN';
      end loop;
   else
      l_units := cwms_util.split_text(p_units, '|');
      for i in 1..l_units.count loop
         l_units(i) := upper(trim(l_units(i)));
         if l_units(i) not in  ('EN', 'SI') then
            cwms_err.raise('ERROR', 'Expected unit specification of EN or SI, got '||l_units(i));
         end if;
      end loop;
      l_count := l_units.count - l_names.count;
      if l_count > 0 then
         l_units.trim(l_count);
      elsif l_count < 0 then
         l_temp := l_units(l_units.count);
         l_count := -l_count;
         l_units.extend(l_count);
         for i in 1..l_count loop
            l_units(l_units.count - i + 1) := l_temp;
         end loop;
      end if;
   end if;
   ------------
   -- datums --
   ------------
   if p_datums is null then
      l_datums := str_tab_t();
      l_datums.extend(l_names.count);
      for i in 1..l_datums.count loop
         l_datums(i) := 'NATIVE';
      end loop;
   else
      l_datums := cwms_util.split_text(p_datums, '|');
      for i in 1..l_datums.count loop
         l_datums(i) := trim(l_datums(i));
         if upper(l_datums(i)) in ('NATIVE', 'NAVD88', 'NGVD29') then
            l_datums(i) := upper(l_datums(i));
         else
            cwms_err.raise('INVALID_ITEM', l_datums(i), 'rating response datum');
         end if;
      end loop;
      l_count := l_datums.count - l_names.count;
      if l_count > 0 then
         l_datums.trim(l_count);
      elsif l_count < 0 then
         l_temp := l_datums(l_datums.count);
         l_count := -l_count;
         l_datums.extend(l_count);
         for i in 1..l_count loop
            l_datums(l_datums.count - i + 1) := l_temp;
         end loop;
      end if;
   end if;

   l_ts1 := systimestamp;

   l_count := 0;
   l_locations := loc_tab_tab_t();
   l_alternate_names := str_tab_tab_tab_t();
   for i in 1..l_names.count loop
      l_locations.extend;
      l_locations(i) := loc_tab_t();
      l_location_id_mask := cwms_util.normalize_wildcards(upper(l_names(i)));
      select distinct
             v2.location_code,
             v2.db_office_id,
             v2.location_id,
             pl1.long_name,
             pl1.public_name,
             pl1.description,
             coalesce(pl1.latitude, pl2.latitude),
             coalesce(pl1.longitude, pl2.longitude),
             coalesce(pl1.horizontal_datum, pl2.horizontal_datum),
             -- elevation
             case
             when pl1.elevation is null then
                -- sub-location elevation is null
                case
                when pl2.elevation is null then
                   -- base location elevation is also null, no elevation to report
                   null
                else
                   -- use base location elevation
                   case
                   when l_units(i) = 'SI' then
                      -- SI Units
                      case
                      when pl1.vertical_datum is null then
                         -- sub-location vertical datum is null
                         case
                         when pl2.vertical_datum is null then
                            -- base location vertical datum is also null, can't compute an offset
                            pl2.elevation
                         else
                            -- use base location vertical datum to compute the offset
                            pl2.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                               pl2.location_code,
                               pl2.vertical_datum,
                               replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                               sysdate,
                               'm'), null)
                         end
                      else
                         -- use sub-location vertical datum to compute the offset
                         pl2.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                            pl2.location_code,
                            pl1.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl1.vertical_datum),
                            sysdate,
                            'm'), null)
                      end
                   else
                      -- English Units
                      case
                      when pl1.vertical_datum is null then
                         -- sub-location vertical datum is null
                         case
                         when pl2.vertical_datum is null then
                            -- base location vertical datum is also null, can't compute an offset
                            cwms_util.convert_units(pl2.elevation, 'm', 'ft')
                         else
                            -- use base location vertical datum to compute the offset
                            cwms_util.convert_units(pl2.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                               pl2.location_code,
                               pl2.vertical_datum,
                               replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                               sysdate,
                               'm'), null), 'm', 'ft')
                         end
                      else
                         -- use sub-location vertical datum to compute the offset
                         cwms_util.convert_units(pl2.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                            pl2.location_code,
                            pl1.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl1.vertical_datum),
                            sysdate,
                            'm'), null), 'm', 'ft')
                      end
                   end
                end
             else
                -- sub-location elevation is not null, so use it
                case
                when l_units(i) = 'SI' then
                   -- SI Units
                   case
                   when pl1.vertical_datum is null then
                      -- sub-location vertical datum is null
                      case
                      when pl2.vertical_datum is null then
                         -- base location vertical datum is also null, can't compute an offset
                         pl2.elevation
                      else
                         -- use base location vertical datum to compute the offset
                         pl1.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                            pl1.location_code,
                            pl2.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                            sysdate,
                            'm'), null)
                      end
                   else
                      -- use sub-location vertical datum to compute the offset
                      pl1.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                         pl1.location_code,
                         pl1.vertical_datum,
                         replace(l_datums(i), 'NATIVE', pl1.vertical_datum),
                         sysdate,
                         'm'), null)
                   end
                else
                   -- English Units
                   case
                   when pl1.vertical_datum is null then
                      -- sub-location vertical datum is null
                      case
                      when pl2.vertical_datum is null then
                         -- base location vertical datum is also null, can't compute an offset
                         cwms_util.convert_units(pl1.elevation, 'm', 'ft')
                      else
                         -- use base location vertical datum to compute the offset
                         cwms_util.convert_units(pl1.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                            pl1.location_code,
                            pl2.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                            sysdate,
                            'm'), null), 'm', 'ft')
                      end
                   else
                      -- use sub-location vertical datum to compute the offset
                      cwms_util.convert_units(pl1.elevation + nanvl(cwms_loc.get_vertical_datum_offset(
                         pl1.location_code,
                         pl1.vertical_datum,
                         replace(l_datums(i), 'NATIVE', pl1.vertical_datum),
                         sysdate,
                         'm'), null), 'm', 'ft')
                   end
                end
             end,
             -- elevation unit
             case
             when coalesce(pl1.elevation, pl2.elevation) is null then null
             else
                case when l_units(i) = 'SI' then 'm' else 'ft' end
             end,
             -- elevation is estimated
             case
             when coalesce(pl1.elevation, pl2.elevation) is null then null
             else
                case
                when pl1.vertical_datum is null then
                   case
                   when pl2.vertical_datum is null then 'F'
                   else
                      cwms_loc.is_vert_datum_offset_estimated(
                        pl2.location_code,
                        pl2.vertical_datum,
                        replace(l_datums(i), 'NATIVE', pl2.vertical_datum))
                   end
                else
                   cwms_loc.is_vert_datum_offset_estimated(
                     pl1.location_code,
                     pl1.vertical_datum,
                     replace(l_datums(i), 'NATIVE', pl1.vertical_datum))
                end
             end,
             -- vertical datum
             case
             when l_datums(i) = 'NATIVE' then
                case
                when nvl(pl1.vertical_datum, nvl(pl2.vertical_datum, 'UNKNOWN')) = 'LOCAL' then
                   cwms_loc.get_local_vert_datum_name_f(pl1.location_code)
                else
                   nvl(pl1.vertical_datum, nvl(pl2.vertical_datum, 'UNKNOWN'))
                end
             else
                l_datums(i)
             end,
             -- time zone
             case
             when pl1.time_zone_code is null then
                case
                when pl2.time_zone_code is null then null
                else tz2.time_zone_name
                end
             else tz1.time_zone_name
             end,
             -- county
             case
             when pl1.county_code is null then
                case
                when pl2.county_code is null then null
                else c2.county_name
                end
             else c1.county_name
             end,
             -- state
             case
             when pl1.county_code is null then
                case
                when pl2.county_code is null then null
                else s2.state_initial
                end
             else s1.state_initial
             end,
             -- nation
             case
             when pl1.nation_code is null then
                case
                when pl2.nation_code is null then null
                else n2.nation_id
                end
             else n1.nation_id
             end,
             case
             when pl1.nearest_city is null then
                case
                when pl2.nearest_city is null then null
                else pl2.nearest_city
                end
             else pl1.nearest_city
             end,
             -- bounding office
             case
             when pl1.office_code is null then
                case
                when pl2.office_code is null then null
                else o2.office_id
                end
             else o1.office_id
             end,
             lk.location_kind_id,
             pl1.location_type
        bulk collect
        into l_locations(i)
        from av_loc2 v2,
             at_physical_location pl1,
             at_physical_location pl2,
             cwms_time_zone tz1,
             cwms_time_zone tz2,
             cwms_county c1,
             cwms_county c2,
             cwms_state s1,
             cwms_state s2,
             cwms_nation n1,
             cwms_nation n2,
             cwms_office o1,
             cwms_office o2,
             cwms_location_kind lk
       where upper(v2.location_id) like l_location_id_mask
         and v2.db_office_id = case when l_office_id = '*' then v2.db_office_id else l_office_id end
         and v2.base_loc_active_flag = 'T'
         and v2.loc_active_flag = 'T'
         and pl1.location_code = v2.location_code
         and tz1.time_zone_code = nvl(pl1.time_zone_code, 0)
         and c1.county_code = nvl(pl1.county_code, 0)
         and s1.state_code = c1.state_code
         and n1.nation_code = nvl(pl1.nation_code, 'US')
         and o1.office_code = nvl(pl1.office_code, 0)
         and lk.location_kind_code = pl1.location_kind
         and pl2.location_code = pl1.base_location_code
         and tz2.time_zone_code = nvl(pl2.time_zone_code, 0)
         and c2.county_code = nvl(pl2.county_code, 0)
         and s2.state_code = c2.state_code
         and n2.nation_code = nvl(pl2.nation_code, 'US')
         and o2.office_code = nvl(pl2.office_code, 0);

      l_count := l_count + l_locations(i).count;

      l_alternate_names.extend;
      l_alternate_names(i) := str_tab_tab_t();
      for j in 1..l_locations(i).count loop
         l_alternate_names(i).extend;
         l_temp := to_char(l_locations(i)(j).location_code);
         if not l_unique_codes.exists(l_temp) then
            l_unique_codes(l_temp) := true;
         end if;
         l_text := l_locations(i)(j).office_id||'/'||l_locations(i)(j).location_id;
         l_indexes(l_text).i := i;
         l_indexes(l_text).j := j;
         select distinct
                location_id
           bulk collect
           into l_alternate_names(i)(j)
           from av_loc2
          where location_code = l_locations(i)(j).location_code
            and location_id != l_locations(i)(j).location_id
          order by 1;
      end loop;
   end loop;

   l_ts2 := systimestamp;
   l_elapsed_query := l_ts2 - l_ts1;
   l_ts1 := systimestamp;

   dbms_lob.createtemporary(l_data, true);
   case
   when l_format = 'XML' then
      null;
      ---------
      -- XML --
      ---------
		cwms_util.append(l_data, '<?xml version="1.0" encoding="windows-1252"?><locations>');
      l_text := l_indexes.first;
      loop
         exit when l_text is null;
         cwms_util.append(
            l_data,
            '<location><identity><office>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).office_id
            ||'</office><name>'
            ||dbms_xmlgen.convert(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_id, dbms_xmlgen.entity_encode)
            ||'</name>');
         cwms_util.append(l_data, '<alternate-names>');
         for i in 1..l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j).count loop
            cwms_util.append(
               l_data,
               '<name>'
               ||dbms_xmlgen.convert(l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j)(i), dbms_xmlgen.entity_encode)
               ||'</name>');
         end loop;
         cwms_util.append(l_data, '</alternate-names>');
         cwms_util.append(
            l_data,
            '</identity><label><public-name>'
            ||dbms_xmlgen.convert(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).public_name, dbms_xmlgen.entity_encode)
            ||'</public-name><long-name>'
            ||dbms_xmlgen.convert(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).long_name, dbms_xmlgen.entity_encode)
            ||'</long-name><description>'
            ||dbms_xmlgen.convert(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).description, dbms_xmlgen.entity_encode)
            ||'</description></label><geolocation><latitude>'
            ||cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).latitude, '7777777777')
            ||'</latitude><longitude>'
            ||cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).longitude, '7777777777')
            ||'</longitude><horizontal-datum>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).horizontal_datum
            ||'</horizontal-datum>'
            ||case
              when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation is null then '<elevation/>'
              else
                 '<elevation unit="'
                 ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation_unit
                 ||'" estimate="'
                 ||case when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation_estimated = 'T' then 'true' else 'false' end
                 ||'" vertical-datum="'
                 ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).vertical_datum
                 ||'">'
                 ||cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation, '7777777777')
                 ||'</elevation>'
            end
            ||'</geolocation><political><timezone>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).time_zone_name
            ||'</timezone><county>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).county
            ||'</county><state>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).state_initial
            ||'</state><nation>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).nation_id
            ||'</nation><nearest-city>'
            ||dbms_xmlgen.convert(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).nearest_city, dbms_xmlgen.entity_encode)
            ||'</nearest-city><bounding-office>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).bounding_office
            ||'</bounding-office></political><classification><location-kind>'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_kind
            ||'</location-kind><location-type>'
            ||dbms_xmlgen.convert(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_type, dbms_xmlgen.entity_encode)
            ||'</location-type></classification></location>');
         l_text := l_indexes.next(l_text);
      end loop;
      l_data := regexp_replace(l_data, '<([^>]+)></\1>', '<\1/>', 1, 0);
      cwms_util.append(l_data, '</locations>');
   when l_format = 'JSON' then
      null;
      ----------
      -- JSON --
      ----------
      cwms_util.append(l_data, '{"locations":{"locations":[');
      l_text := l_indexes.first;
      loop
         exit when l_text is null;
         cwms_util.append(
            l_data,
            case
            when l_text = l_indexes.first then
               '{"identity":{"office":"'
            else
               ',{"identity":{"office":"'
            end
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).office_id
            ||'","name":"'
            ||replace(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_id, '"', '\"')
            ||'","alternate-names":[');
         for i in 1..l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j).count loop
            cwms_util.append(
               l_data,
               case i
               when 1 then '"'||replace(l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j)(i), '"', '\"')||'"'
               else ',"'||replace(l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j)(i), '"', '\"')||'"'
               end);
         end loop;
         cwms_util.append(
            l_data,
            ']},"label":{"public-name":"'
            ||replace(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).public_name, '"', '\"')
            ||'","long-name":"'
            ||replace(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).long_name, '"', '\"')
            ||'","description":"'
            ||replace(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).description, '"', '\"')
            ||'"},"geolocation":{"latitude":'
            ||case
              when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).latitude is null then 'null'
              else cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).latitude, '7777777777')
              end
            ||',"longitude":'
            ||case
              when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).longitude is null then 'null'
              else cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).longitude, '7777777777')
              end
            ||',"horizontal-datum":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).horizontal_datum
            ||'","elevation":'
            ||case
              when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation is null then 'null'
              else '{"value":'
                   ||regexp_replace(cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation, '7777777777'), '(^|[^0-9])\.', '\10.')
                   ||',"unit":"'
                   ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation_unit
                   ||'","datum":"'
                   ||nvl(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).vertical_datum, null)
                   ||'","estimate":'
                   ||case when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation_estimated = 'T' then '"true"' else '"false"' end
                   ||'}'
              end
            ||'},"political":{"nation":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).nation_id
            ||'","state":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).state_initial
            ||'","county":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).county
            ||'","timezone":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).time_zone_name
            ||'","nearest-city":"'
            ||replace(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).nearest_city, '"', '\"')
            ||'","bounding-office":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).bounding_office
            ||'"},"classification":{"location-kind":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_kind
            ||'","location-type":"'
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_type
            ||'"}}');
         l_text := l_indexes.next(l_text);
      end loop;
      cwms_util.append(l_data, ']}}');
      l_data := replace(l_data, '""', 'null');
   when l_format in ('TAB', 'CSV') then
      ----------------
      -- TAB or CSV --
      ----------------
      cwms_util.append(
         l_data,
         cwms_util.join_text(
            str_tab_t(
               '#Office',
               'Name',
               'Public Name',
               'Long Name',
               'Description',
               'Latitude',
               'Longitude',
               'Horiz. Datum',
               'Elevation',
               'Time Zone',
               'Nation',
               'State',
               'County',
               'Nearest City',
               'Bounding Office',
               'Location Kind',
               'Location Type',
               'Alternate Names'),
         chr(9))
         ||chr(10));
      l_text := l_indexes.first;
      loop
         exit when l_text is null;
         cwms_util.append(
            l_data,
            l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).office_id||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_id||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).public_name||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).long_name||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).description||chr(9)
            ||cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).latitude, '7777777777')||chr(9)
            ||cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).longitude, '7777777777')||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).horizontal_datum||chr(9)
            ||case
              when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation is null then null
              else
                 cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation, '7777777777')
                 ||' '||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation_unit
                 ||case
                   when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).vertical_datum is null then null
                   else ' '||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).vertical_datum
                   end
                 ||case
                   when l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation_estimated = 'T' then ' estimated'
                   else null
                   end
              end
            ||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).time_zone_name||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).nation_id||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).state_initial||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).county||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).nearest_city||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).bounding_office||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_kind||chr(9)
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_type
            ||case
              when l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j) is null then null
              else chr(9)||cwms_util.join_text(l_alternate_names(l_indexes(l_text).i)(l_indexes(l_text).j), chr(9))
              end
            ||chr(10));
         l_text := l_indexes.next(l_text);
      end loop;
   end case;

   if l_format = 'CSV' then
      ---------
      -- CSV --
      ---------
      l_data := cwms_util.tab_to_csv(l_data);
   end if;

   l_ts2 := systimestamp;
   l_elapsed_format := l_ts2 - l_ts1;


   declare
      l_data2 clob;
      l_name  varchar2(32767);
   begin
      dbms_lob.createtemporary(l_data2, true);
      l_name := cwms_util.get_db_name;
      case
      when l_format = 'XML' then
         cwms_util.append(
            l_data2,
            '<query-info><processed-at>'
            ||utl_inaddr.get_host_name
            ||':'
            ||l_name
            ||'</processed-at><time-of-query>'
            ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
            ||'Z</time-of-query><process-query>'
            ||iso_duration(l_elapsed_query)
            ||'</process-query><format-output>'
            ||iso_duration(l_elapsed_format)
            ||'</format-output><requested-format>'
            ||l_format
            ||'</requested-format><requested-office>'
            ||l_office_id
            ||'</requested-office>');
            for i in 1..l_names.count loop
               cwms_util.append(
                  l_data2,
                  '<requested-item><name>'
                  ||l_names(i)
                  ||'</name><unit>'
                  ||l_units(i)
                  ||'</unit><datum>'
                  ||l_datums(i)
                  ||'</datum></requested-item>');
            end loop;
         cwms_util.append(
            l_data2,
            '<total-locations-retrieved>'
            ||l_count
            ||'</total-locations-retrieved><unique-locations_retrieved>'
            ||l_unique_codes.count
            ||'</unique-locations_retrieved></query-info>');
         l_data := regexp_replace(l_data, '^((<\?xml .+?\?>)?(<locations>))', '\1'||l_data2, 1, 1);
         p_results := l_data;
      when l_format = 'JSON' then
         cwms_util.append(
            l_data2,
            '"query-info":{"processed-at":"'
            ||utl_inaddr.get_host_name
            ||':'
            ||l_name
            ||'","time-of-query":"'
            ||to_char(l_query_time, 'yyyy-mm-dd"T"hh24:mi:ss')
            ||'Z","process-query":"'
            ||iso_duration(l_elapsed_query)
            ||'","format-output":"'
            ||iso_duration(l_elapsed_format)
            ||'","requested-format":"'
            ||l_format
            ||'","requested-office":"'
            ||l_office_id
            ||'","requested-items":[');
         for i in 1..l_names.count loop
            cwms_util.append(
               l_data2,
               case
               when i = 1 then '{"name":"'
               else  ',{"name":"'
               end
               ||l_names(i)
               ||'","unit":"'
               ||l_units(i)
               ||'","datum":"'
               ||l_datums(i)
               ||'"}');
         end loop;
         cwms_util.append(
            l_data2,
            '],"total-locations-retrieved":'
            ||l_count
            ||',"unique-locations-retrieved":'
            ||l_unique_codes.count
            ||'},');
         l_data := regexp_replace(l_data, '^({"locations":{)', '\1'||l_data2, 1, 1);
         p_results := l_data;
      when l_format in ('TAB', 'CSV') then
         cwms_util.append(l_data2, '#Processed At'       ||chr(9)||utl_inaddr.get_host_name ||':'||l_name||chr(10));
         cwms_util.append(l_data2, '#Time Of Query'      ||chr(9)||to_char(l_query_time, 'Dd-Mon-Yyyy Hh24:Mi')||' UTC'||chr(10));
         cwms_util.append(l_data2, '#Process Query'      ||chr(9)||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' Milliseconds'||chr(10));
         cwms_util.append(l_data2, '#Format Output'      ||chr(9)||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' Milliseconds'||chr(10));
         cwms_util.append(l_data2, '#Requested Format'   ||chr(9)||l_format||chr(10));
         cwms_util.append(l_data2, '#Requested Office'   ||chr(9)||l_office_id||chr(10));
         cwms_util.append(l_data2, '#Requested Names'    ||chr(9)||cwms_util.join_text(l_names, chr(9))||chr(10));
         cwms_util.append(l_data2, '#Requested Units'    ||chr(9)||cwms_util.join_text(l_units, chr(9))||chr(10));
         cwms_util.append(l_data2, '#Requested Datums'   ||chr(9)||cwms_util.join_text(l_datums, chr(9))||chr(10));
         cwms_util.append(l_data2, '#Total Locations Retrieved'||chr(9)||l_count||chr(10));
         cwms_util.append(l_data2, '#Unique Locations Retrieved'||chr(9)||l_unique_codes.count||chr(10)||chr(10));
         if l_format = 'CSV' then
            l_data2 := cwms_util.tab_to_csv(l_data2);
         end if;
         cwms_util.append(l_data2, l_data);
         p_results := l_data2;
      end case;
   end;

   p_date_time      := l_query_time;
   p_query_time     := trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)));
   p_format_time    := trunc(1000 * (extract(minute from l_elapsed_format) *60 +  extract(second from l_elapsed_format)));
   p_location_count := l_count;

   end retrieve_locations;

   function retrieve_locations_f(
      p_names       in  varchar2 default null,
      p_format      in  varchar2 default null,
      p_units       in  varchar2 default null,
      p_datums      in  varchar2 default null,
      p_office_id   in  varchar2 default null)
      return clob
   is
      l_results        clob;
      l_date_time      date;
      l_query_time     integer;
      l_format_time    integer;
      l_location_count integer;
   begin
      retrieve_locations(
            l_results,
            l_date_time,
            l_query_time,
            l_format_time,
            l_location_count,
            p_names,
            p_format,
            p_units,
            p_datums,
            p_office_id);

      -- dbms_output.put_line(l_query_time);
      -- dbms_output.put_line(l_format_time);
      return l_results;
   end retrieve_locations_f;


   function package_log_property_text
      return varchar2
   is
   begin
      return v_package_log_prop_text;
   end package_log_property_text;

   procedure set_package_log_property_text(
      p_text in varchar2 default null)
   is
   begin
      v_package_log_prop_text := nvl(p_text, userenv('sessionid'));
   end set_package_log_property_text;

END cwms_loc;
/
show errors;
