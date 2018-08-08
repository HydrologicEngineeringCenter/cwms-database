------------------------------------------
-- RUN THIS SCRIPT AS CWMS_20 or SYSDBA --
------------------------------------------
set define off
spool 3_0_4-to-3_0_5.log
set linesize 1000
set time on
set trimspool on
whenever sqlerror exit sql.sqlcode
select systimestamp from dual;
----------------------------------------------------------
-- verify that the schema is the version that we expect --
----------------------------------------------------------
begin
   for rec in 
      (select version,
              to_char(version_date, 'DDMONYYYY') as version_date
         from cwms_20.av_db_change_log
        where version_date = (select max(version_date) from cwms_20.av_db_change_log)
      )
   loop
      if rec.version != '3.0.4' or rec.version_date != '01JUN2016' then
      	cwms_err.raise('ERROR', 'Expected version 3.0.4 (01JUN2016), got version '||rec.version||' ('||rec.version_date||')');
      end if;
   end loop;
end;
/
--------------------------------------------------------------------------------
alter session set current_schema = CWMS_20;
prompt Updating CWMS_LOC Package Body
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
      l_location_id    VARCHAR2 (49);
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

   FUNCTION get_location_id (p_location_id_or_alias    VARCHAR2,
                             p_office_id                VARCHAR2 DEFAULT NULL
                            )
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      l_office_id :=
         NVL (UPPER (TRIM (p_office_id)), cwms_util.user_office_id);

      FOR rec
         IN (SELECT       bl.base_location_id
                      || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                      || pl.sub_location_id
                         AS location_id
               FROM    at_physical_location pl,
                      at_base_location bl,
                      cwms_office o
              WHERE        o.office_id = l_office_id
                      AND bl.db_office_code = o.office_code
                      AND pl.base_location_code = bl.base_location_code
                      AND UPPER (bl.base_location_id) =
                             UPPER (
                                cwms_util.get_base_id (p_location_id_or_alias
                                                      )
                             )
                      AND NVL (UPPER (pl.sub_location_id), '.') =
                             NVL (
                                UPPER (
                                   cwms_util.get_sub_id (
                                      p_location_id_or_alias
                                   )
                                ),
                                '.'
                             ))
      LOOP
         RETURN TRIM (rec.location_id);
      END LOOP;

      ------------------------------------------------
      -- if we get here we didn't find the location --
      ------------------------------------------------
      BEGIN
         RETURN get_location_id_from_alias (
                   p_alias_id    => p_location_id_or_alias,
                   p_office_id   => l_office_id
                );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('LOCATION_ID_NOT_FOUND', p_location_id_or_alias);
      END;
   END get_location_id;

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
      l_location_code          at_physical_location.location_code%TYPE;
      l_time_zone_code          at_physical_location.time_zone_code%TYPE;
      l_county_code             cwms_county.county_code%TYPE;
      l_location_type          at_physical_location.location_type%TYPE;
      l_elevation              at_physical_location.elevation%TYPE;
      l_vertical_datum          at_physical_location.vertical_datum%TYPE;
      l_longitude              at_physical_location.longitude%TYPE;
      l_latitude                at_physical_location.latitude%TYPE;
      l_horizontal_datum       at_physical_location.horizontal_datum%TYPE;
      l_state_code             cwms_state.state_code%TYPE;
      l_public_name             at_physical_location.public_name%TYPE;
      l_long_name              at_physical_location.long_name%TYPE;
      l_description             at_physical_location.description%TYPE;
      l_active_flag             at_physical_location.active_flag%TYPE;
      l_location_kind_code     at_physical_location.location_kind%TYPE;
      l_map_label              at_physical_location.map_label%TYPE;
      l_published_latitude     at_physical_location.published_latitude%TYPE;
      l_published_longitude    at_physical_location.published_longitude%TYPE;
      l_bounding_office_code    at_physical_location.office_code%TYPE;
      l_nation_code             at_physical_location.nation_code%TYPE;
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
      SELECT   location_type, elevation, vertical_datum, latitude, longitude,
               horizontal_datum, public_name, long_name, description,
               time_zone_code, county_code, active_flag, location_kind,
               map_label, published_latitude, published_longitude,
               office_code, nation_code, nearest_city
        INTO   l_location_type, l_elevation, l_vertical_datum, l_latitude,
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
               active_flag = l_active_flag,
               location_kind = l_location_kind_code,
               map_label = l_map_label,
               published_latitude = l_published_latitude,
               published_longitude = l_published_longitude,
               office_code = l_bounding_office_code,
               nation_code = l_nation_code,
               nearest_city = l_nearest_city
       WHERE   location_code = l_location_code;
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
      l_location_id_old          VARCHAR2 (49) := TRIM (p_location_id_old);
      l_location_id_new          VARCHAR2 (49) := TRIM (p_location_id_new);
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
      l_cwms_ts_id           VARCHAR2 (183);
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
   --   l_alias_public_name  VARCHAR2 (32);
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
   FUNCTION get_local_timezone (p_location_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_local_tz    VARCHAR2 (28);
   BEGIN
      SELECT   time_zone_name
        INTO   l_local_tz
        FROM   cwms_time_zone ctz, at_physical_location atp
       WHERE   atp.location_code = p_location_code
               AND ctz.time_zone_code = NVL (atp.time_zone_code, 0);

      IF l_local_tz = 'Unknown or Not Applicable'
      THEN
         l_local_tz := 'UTC';
      END IF;

      RETURN l_local_tz;
   END get_local_timezone;

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
   --   location_id VARCHAR2 (49),
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
   --   location_id VARCHAR2 (49),
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
   --   location_id VARCHAR2 (49),
   --   loc_attribute NUMBER,
   --   loc_alias_id  VARCHAR2 (128),
   --   loc_ref_id  VARCHAR2 (49)
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
   --"char_49_array_type" table type, which is an array of table type varchar2(49).

   --Note that you cannot unassign group/location pairs if a group/location pair -
   --is being referenced by a SHEF decode entry.
   -------------------------------------------------------------------------------
   -------------------------------------------------------------------------------
procedure unassign_loc_groups(
   p_loc_category_id in varchar2,
   p_loc_group_id    in varchar2,
   p_location_array  in char_49_array_type,
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
      l_location_array    char_49_array_type
                            := char_49_array_type (TRIM (p_location_id));
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
      l_location_id   varchar2(49); 
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
      l_location_id     varchar2(49);
      l_location_code  number(10);
      l_office_id      varchar2(16);
      l_count           pls_integer;
      l_multiple_ids   boolean;
      l_property_id     varchar2(256);
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
      l_location_id_mask   VARCHAR2 (49);
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
                 upper(p_vertical_datum_id_1),
                 upper(p_vertical_datum_id_2),
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
                  l_offset := get_vertcon_offset(l_lat, l_lon);
                  l_effective_date := date '1000-01-01';
                  l_description := 'VERTCON ESTIMATE';
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
      l_location_id      varchar2(49);
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
         ||l_location_id
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
               ||l_local_datum_name
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
      for i in 1..l_record_count loop
         l_total := l_total + l_location_records(i).count;
      end loop;
      if p_office_id is not null then
         l_office_records := cwms_util.parse_string_recordset(p_office_id);
      end if;
      if l_total > 1 then
         l_vert_datum_info := '<vertical-datum-info-set>'||chr(10);
         for i in 1..l_record_count loop
            l_field_count := l_location_records(i).count;
            for j in 1..l_field_count loop
               case
                  when l_office_records is null then
                     -- no office ids
                     l_office_id := null;
                  when l_office_records.count = l_record_count then
                     case 
                        when l_office_records(i).count = 1 then
                           -- single office for this record
                           l_office_id := l_office_records(i)(1);
                        when l_office_records(i).count = l_field_count then
                           -- one office per location
                           l_office_id := l_office_records(i)(j);
                        else
                           -- office count error for this record
                           cwms_err.raise('ERROR', 'Invalid office count on record '||i);
                     end case;
                  else
                     -- total office count error
                     cwms_err.raise('ERROR', 'Invalid total office count');
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
      l_location_id         varchar2(49);
      l_location_id_2       varchar2(49);
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
         l_location_id varchar2(49);
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
               l_location_id varchar2(49);
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
      l_valid_kinds('SITE'           ) := 'SITE,BASIN,EMBANKMENT,ENTITY,LOCK,OUTLET,PROJECT,STREAM,STREAM_LOCATION,STREAM_REACH,TURBINE,WEATHER_GAGE';
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
            l_iso := l_iso || trim(to_char(l_seconds, '0.999')) || 'S';
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
                -- sub-location elevation is null, use base-location elevation
                case
                when pl2.elevation is null then null
                else
                   case
                   when l_units(i) = 'SI' then
                      case
                      when pl2.vertical_datum is null then
                         pl2.elevation
                      else
                         pl2.elevation + cwms_loc.get_vertical_datum_offset(
                            pl2.location_code,
                            pl2.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                            sysdate,
                            case when l_units(i) = 'SI' then 'm' else 'ft' end)
                      end
                   else
                      case
                      when pl2.vertical_datum is null then
                         cwms_util.convert_units(pl2.elevation, 'm', 'ft')
                      else
                         cwms_util.convert_units(
                            pl2.elevation + cwms_loc.get_vertical_datum_offset(
                               pl2.location_code,
                               pl2.vertical_datum,
                               replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                               sysdate,
                               case when l_units(i) = 'SI' then 'm' else 'ft' end),
                            'm', 'ft')
                      end
                   end
                end
             else
                -- sub-location elevation is not null, so use it
                case
                when l_units(i) = 'SI' then
                   -- SI units
                   case
                   when pl1.vertical_datum is null then
                      -- sub-location vertical datum is null, so use base-location vertical datum with sub-location elevation
                      case
                      when pl2.vertical_datum is null then
                         pl1.elevation
                      else
                         pl1.elevation + cwms_loc.get_vertical_datum_offset(
                            pl2.location_code,
                            pl2.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                            sysdate,
                            case when l_units(i) = 'SI' then 'm' else 'ft' end)
                      end
                   else
                      -- sub-location vertical datum is not null so use it with sub-location elevation
                      pl1.elevation + cwms_loc.get_vertical_datum_offset(
                         pl1.location_code,
                         pl1.vertical_datum,
                         replace(l_datums(i), 'NATIVE', pl1.vertical_datum),
                         sysdate,
                         case when l_units(i) = 'SI' then 'm' else 'ft' end)
                   end
                else
                   -- English units
                   case
                   when pl1.vertical_datum is null then
                      -- sub-location vertical datum is null, so use base-location vertical datum with sub-location elevation
                      case
                      when pl2.vertical_datum is null then
                         cwms_util.convert_units(pl1.elevation, 'm', 'ft')
                      else
                         cwms_util.convert_units(
                            pl1.elevation + cwms_loc.get_vertical_datum_offset(
                               pl2.location_code,
                               pl2.vertical_datum,
                               replace(l_datums(i), 'NATIVE', pl2.vertical_datum),
                               sysdate,
                               case when l_units(i) = 'SI' then 'm' else 'ft' end),
                            'm', 'ft')
                      end
                   else
                      -- sub-location vertical datum is not null so use it with sub-location elevation
                      cwms_util.convert_units(
                         pl1.elevation + cwms_loc.get_vertical_datum_offset(
                            pl1.location_code,
                            pl1.vertical_datum,
                            replace(l_datums(i), 'NATIVE', pl1.vertical_datum),
                            sysdate,
                            case when l_units(i) = 'SI' then 'm' else 'ft' end),
                         'm', 'ft')
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
                        replace(l_datums(i), 'NATIVE', pl1.vertical_datum))
                   end
                else
                   cwms_loc.is_vert_datum_offset_estimated(
                     pl1.location_code,
                     pl1.vertical_datum,
                     replace(l_datums(i), 'NATIVE', pl1.vertical_datum))
                end
             end,
             -- vertical datum
             l_datums(i),
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
      cwms_util.append(l_data, '<locations>');
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
            ||l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).location_type
            ||'</location-type></classification></location>');
         l_text := l_indexes.next(l_text);
      end loop;
      cwms_util.append(l_data, '</locations>');
      l_data := regexp_replace(l_data, '<([^>]+)></\1>', '<\1/>', 1, 0);
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
                   ||cwms_rounding.round_dt_f(l_locations(l_indexes(l_text).i)(l_indexes(l_text).j).elevation, '7777777777')
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
      select db_unique_name into l_name from v$database;
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
         l_data := regexp_replace(l_data, '^(<locations.*?>)', '\1'||l_data2, 1, 1);
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
   
END cwms_loc;
/
show errors;
commit;
prompt Updating CWMS_ERR Package Body
CREATE OR REPLACE package body cwms_err
is
   procedure raise (
      p_err in varchar2,               -- exception name in cwms_error table
      p_1   in varchar2 default null,  -- optional substitution value for %1  
      p_2   in varchar2 default null,  -- optional substitution value for %2  
      p_3   in varchar2 default null,  -- optional substitution value for %3  
      p_4   in varchar2 default null,  -- optional substitution value for %4  
      p_5   in varchar2 default null,  -- optional substitution value for %5  
      p_6   in varchar2 default null,  -- optional substitution value for %6  
      p_7   in varchar2 default null,  -- optional substitution value for %7  
      p_8   in varchar2 default null,  -- optional substitution value for %8  
      p_9   in varchar2 default null   -- optional substitution value for %9 
      ) is
      l_code  number;
      l_errm  varchar2(32767);
   begin
      -- raise user-defined exception p_err
      -- substitute optional values p_1 - p_9 in the error message for %n
      -- add the exception to the error stack  
   
      begin
         select err_code, err_name||': '||err_msg into l_code, l_errm
         from cwms_error where err_name=upper(p_err);

      exception when NO_DATA_FOUND then
         l_code := -20999;
         l_errm := 'UNKNOWN_EXCEPTION: The requested exception not in the CWMS_ERROR table: "'||p_err||'"';
      end;

      if p_1 is not null then 
         l_errm := replace(l_errm,'%1',p_1);
         if p_2 is not null then 
            l_errm := replace(l_errm,'%2',p_2);
            if p_3 is not null then 
               l_errm := replace(l_errm,'%3',p_3);
               if p_4 is not null then 
                  l_errm := replace(l_errm,'%4',p_4);
                  if p_5 is not null then 
                     l_errm := replace(l_errm,'%5',p_5);
                     if p_6 is not null then 
                        l_errm := replace(l_errm,'%6',p_6);
                        if p_7 is not null then 
                           l_errm := replace(l_errm,'%7',p_7);
                           if p_8 is not null then 
                              l_errm := replace(l_errm,'%8',p_8);
                              if p_9 is not null then 
                                 l_errm := replace(l_errm,'%9',p_9);
                              end if;
                           end if;
                        end if;
                     end if;
                  end if;
               end if;
            end if;
         end if;
      end if;

      raise_application_error(l_code, l_errm, TRUE);

   end raise;

end;
/
commit;
prompt Updating CWMS_LEVEL Package Body
CREATE OR REPLACE PACKAGE BODY cwms_level as
            
--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE validate_specified_level_input
--------------------------------------------------------------------------------
procedure validate_specified_level_input(
   p_office_code out number,
   p_office_id   in  varchar2,
   p_level_id    in  varchar2)
is          
begin       
   if p_level_id != ltrim(rtrim(p_level_id)) then
      cwms_err.raise('ERROR', 'Level id includes leading or trailing spaces');
   end if;  
   if p_level_id is null then
      cwms_err.raise('ERROR', 'Level id cannot be null');
   end if;  
   begin    
      select office_code
        into p_office_code
        from cwms_office
       where office_id = nvl(upper(p_office_id), cwms_util.user_office_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_OFFICE_ID',
            p_office_id);
   end;     
end validate_specified_level_input;        
            
--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_units_conversion
--------------------------------------------------------------------------------
procedure get_units_conversion(
   p_factor         out binary_double,
   p_offset         out binary_double,
   p_to_cwms        in  boolean,
   p_units          in  varchar2,
   p_parameter_code in  number)
is          
   l_parameter_id      varchar2(49);
   l_sub_parameter_id  varchar2(32);
begin       
   if p_to_cwms is null then
      cwms_err.raise(
         'ERROR',
         'Parameter p_to_cwms must be true (To CWMS) or false (From CWMS)');
   end if;      
   if p_units is null then
      p_factor := 1;
      p_offset := 0;
   else     
      begin 
         if p_to_cwms then
            -------------
            -- TO CWMS --
            -------------
            select factor,
                   offset
              into p_factor,
                   p_offset
              from cwms_unit_conversion uc,
                   cwms_base_parameter bp,
                   at_parameter ap
             where uc.to_unit_code = bp.unit_code
               and bp.base_parameter_code = ap.base_parameter_code
               and ap.parameter_code = p_parameter_code
               and uc.from_unit_id = p_units;
         else
            ---------------
            -- FROM CWMS --
            ---------------
            select factor,
                   offset
              into p_factor,
                   p_offset
              from cwms_unit_conversion uc,
                   cwms_base_parameter bp,
                   at_parameter ap
             where uc.from_unit_code = bp.unit_code
               and bp.base_parameter_code = ap.base_parameter_code
               and ap.parameter_code = p_parameter_code
               and uc.to_unit_id = p_units;
         end if;
      exception
         when no_data_found then
            select base_parameter_id,
                   sub_parameter_id
              into l_parameter_id,
                   l_sub_parameter_id
              from at_parameter ap,
                   cwms_base_parameter bp
             where ap.parameter_code = p_parameter_code
               and bp.base_parameter_code = ap.base_parameter_code;
            if l_sub_parameter_id is not null then
               l_parameter_id :=
                  l_parameter_id || '-' || l_sub_parameter_id;
            end if;
            cwms_err.raise(
               'ERROR',
               'Cannot convert parameter '
               || l_parameter_id
               || case p_to_cwms
                     when true then ' to'
                     else           ' from'
                  end
               || ' specified units: '
               || p_units);
      end;  
   end if;  
end get_units_conversion;        
            
--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_location_level_codes
--------------------------------------------------------------------------------
procedure get_location_level_codes(
   p_location_level_code       out number,
   p_spec_level_code           out number,
   p_location_code             out number,
   p_parameter_code            out number,
   p_parameter_type_code       out number,
   p_duration_code             out number,
   p_effective_date_out        out date,
   p_expiration_date_out       out date,
   p_attribute_parameter_code  out number,
   p_attribute_param_type_code out number,
   p_attribute_duration_code   out number,
   p_location_id               in  varchar2,
   p_parameter_id              in  varchar2,
   p_parameter_type_id         in  varchar2,
   p_duration_id               in  varchar2,
   p_spec_level_id             in  varchar2,
   p_effective_date_in         in  date,      -- UTC
   p_match_date                in  boolean,   -- earlier date OK if false
   p_attribute_value           in  number,
   p_attribute_units           in  varchar2,
   p_attribute_parameter_id    in  varchar2,
   p_attribute_param_type_id   in  varchar2,
   p_attribute_duration_id     in  varchar2,
   p_office_id                 in  varchar2)
is          
   l_parts              str_tab_t;
   l_base_parameter_id  varchar2(16);
   l_sub_parameter_id   varchar2(32) := null;
   l_office_id          varchar2(16) := nvl(p_office_id, cwms_util.user_office_id);
   l_office_code        number(10)   := cwms_util.get_office_code(l_office_id);
   l_factor             binary_double;
   l_offset             binary_double;
   l_attribute_value    number := null;
begin       
   --------------
   -- location --
   --------------
   p_location_code := cwms_loc.get_location_code(l_office_code, p_location_id);
   ---------------
   -- parameter --
   ---------------
   l_parts := cwms_util.split_text(p_parameter_id, '-', 1);
   l_base_parameter_id := l_parts(1);
   if l_parts.count > 1 then
      l_sub_parameter_id := l_parts(2);
   end if;  
   p_parameter_code := cwms_ts.get_parameter_code(
      l_base_parameter_id,
      l_sub_parameter_id,
      p_office_id,
      'T'); 
   --------------------
   -- parameter type --
   --------------------
   begin    
      select parameter_type_code
        into p_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(p_parameter_type_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_parameter_type_id,
            'parameter type id');
   end;     
   --------------
   -- duration --
   --------------
   begin    
      select duration_code
        into p_duration_code
        from cwms_duration
       where upper(duration_id) = upper(p_duration_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_duration_id,
            'duration id');
   end;     
   ---------------------
   -- specified level --
   ---------------------
   p_spec_level_code := get_specified_level_code(
      p_spec_level_id,
      'F',  
      p_office_id);
   if p_spec_level_code is null then
      create_specified_level_out(
         p_spec_level_code,
         p_spec_level_id,
         null,
         'T',
         p_office_id);
   end if;  
   ---------------
   -- attribute --
   ---------------
   if p_attribute_value is null then
      ----------------------------
      -- no attribute specified --
      ----------------------------
      p_attribute_parameter_code := null;
      p_attribute_param_type_code := null;
      p_attribute_duration_code := null;
      l_attribute_value := null;
   else     
      -------------------------
      -- attribute specified --
      -------------------------
      -------------------------
      -- attribute parameter --
      -------------------------
      l_parts := cwms_util.split_text(p_attribute_parameter_id, '-', 1);
      if l_parts.count > 1 then
         l_base_parameter_id := l_parts(1);
         l_sub_parameter_id := l_parts(2);
      else  
         l_base_parameter_id := p_attribute_parameter_id;
         l_sub_parameter_id := null;
      end if;
      p_attribute_parameter_code := cwms_ts.get_parameter_code(
         l_base_parameter_id,
         l_sub_parameter_id,
         p_office_id,
         'T');
      ------------------------------
      -- attribute parameter type --
      ------------------------------
      begin 
         select parameter_type_code
           into p_attribute_param_type_code
           from cwms_parameter_type
          where parameter_type_id = p_attribute_param_type_id;
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               p_parameter_type_id,
               'parameter type id');
      end;  
      ------------------------
      -- attribute duration --
      ------------------------
      begin 
         select duration_code
           into p_attribute_duration_code
           from cwms_duration
          where duration_id = p_attribute_duration_id;
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_ITEM',
               p_duration_id,
               'duration id');
      end;  
      --------------------------------
      -- attribute units conversion --
      --------------------------------
      get_units_conversion(
         l_factor,
         l_offset,
         true, -- To CWMS
         p_attribute_units,
         p_attribute_parameter_code);
      l_attribute_value := cwms_rounding.round_f(p_attribute_value * l_factor + l_offset, 12);
   end if;  
   begin    
      if p_match_date then
         ------------------------
         -- match date exactly --
         ------------------------
         select distinct
                location_level_code,
                location_level_date,
                expiration_date
           into p_location_level_code,
                p_effective_date_out,
                p_expiration_date_out
           from at_location_level
          where location_code = p_location_code
            and specified_level_code = p_spec_level_code
            and parameter_code = p_parameter_code
            and parameter_type_code = p_parameter_type_code
            and duration_code = p_duration_code
            and location_level_date = p_effective_date_in
            and nvl(to_char(attribute_parameter_code), '@')
                = nvl(to_char(p_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@')
                = nvl(to_char(p_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@')
                = nvl(to_char(p_attribute_duration_code), '@')
            and nvl(to_char(attribute_value), '@')
                = nvl(to_char(l_attribute_value), '@');
      else  
         ---------------------
         -- earlier date OK --
         ---------------------
         select location_level_code,
                location_level_date,
                expiration_date
           into p_location_level_code,
                p_effective_date_out,
                p_expiration_date_out
           from at_location_level
          where location_code = p_location_code
            and specified_level_code = p_spec_level_code
            and parameter_code = p_parameter_code
            and parameter_type_code = p_parameter_type_code
            and duration_code = p_duration_code
            and location_level_date = (select max(location_level_date)
                                         from at_location_level
                                        where location_code = p_location_code
                                          and specified_level_code = p_spec_level_code
                                          and parameter_code = p_parameter_code
                                          and parameter_type_code = p_parameter_type_code
                                          and duration_code = p_duration_code
                                          and location_level_date <= p_effective_date_in
                                          and nvl(to_char(attribute_parameter_code), '@')
                                              = nvl(to_char(p_attribute_parameter_code), '@')
                                          and nvl(to_char(attribute_parameter_type_code), '@')
                                              = nvl(to_char(p_attribute_param_type_code), '@')
                                          and nvl(to_char(attribute_duration_code), '@')
                                              = nvl(to_char(p_attribute_duration_code), '@')
                                          and nvl(to_char(attribute_value), '@')
                                              = nvl(to_char(l_attribute_value), '@'))
            and nvl(to_char(attribute_parameter_code), '@')
                = nvl(to_char(p_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@')
                = nvl(to_char(p_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@')
                = nvl(to_char(p_attribute_duration_code), '@')
            and nvl(to_char(attribute_value), '@')
                = nvl(to_char(l_attribute_value), '@');
      end if;
   exception
      when no_data_found then
         p_location_level_code := null;
   end;     
end get_location_level_codes;

function get_prev_effective_date(
   p_location_level_code in integer,
   p_timezone            in varchar2 default 'UTC')
   return date
is
   l_rec            at_location_level%rowtype;
   l_effective_date date;
begin
   select *
     into l_rec
     from at_location_level
    where location_level_code = p_location_level_code;
    
   begin
      select cwms_util.change_timezone(location_level_date, 'UTC', p_timezone)
        into l_effective_date
        from at_location_level
       where location_code = l_rec.location_code
         and specified_level_code = l_rec.specified_level_code
         and parameter_code = l_rec.parameter_code
         and parameter_type_code = l_rec.parameter_type_code
         and duration_code = l_rec.duration_code
         and location_level_date = (select max(location_level_date)
                                      from at_location_level
                                     where location_code = l_rec.location_code
                                       and specified_level_code = l_rec.specified_level_code
                                       and parameter_code = l_rec.parameter_code
                                       and parameter_type_code = l_rec.parameter_type_code
                                       and duration_code = l_rec.duration_code
                                       and location_level_date < l_rec.location_level_date
                                   )
         and rownum = 1;
   exception
      when no_data_found then null;
   end;
   return l_effective_date;
end get_prev_effective_date;

function get_next_effective_date(
   p_location_level_code in integer,
   p_timezone            in varchar2 default 'UTC')
   return date
is
   l_rec            at_location_level%rowtype;
   l_effective_date date;
begin
   select *
     into l_rec
     from at_location_level
    where location_level_code = p_location_level_code;
    
   begin
      select cwms_util.change_timezone(location_level_date, 'UTC', p_timezone)
        into l_effective_date
        from at_location_level
       where location_code = l_rec.location_code
         and specified_level_code = l_rec.specified_level_code
         and parameter_code = l_rec.parameter_code
         and parameter_type_code = l_rec.parameter_type_code
         and duration_code = l_rec.duration_code
         and location_level_date = (select min(location_level_date)
                                      from at_location_level
                                     where location_code = l_rec.location_code
                                       and specified_level_code = l_rec.specified_level_code
                                       and parameter_code = l_rec.parameter_code
                                       and parameter_type_code = l_rec.parameter_type_code
                                       and duration_code = l_rec.duration_code
                                       and location_level_date > l_rec.location_level_date
                                   )
         and rownum = 1;
   exception
      when no_data_found then null;
   end;
   return l_effective_date;
end get_next_effective_date;
            
--------------------------------------------------------------------------------
-- PRIVATE FUNCTION get_location_level_code
--------------------------------------------------------------------------------
function get_location_level_code(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_effective_date_in       in  date,      -- UTC
   p_match_date              in  boolean,   -- earlier date OK if false
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_office_id               in  varchar2)
   return number
is          
   l_location_level_code       number(10);
   l_spec_level_code           number(10);
   l_location_code             number(10);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_effective_date            date;
   l_expiration_date           date;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
begin       
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_effective_date,
      l_expiration_date,
      l_attribute_parameter_code,
      l_attribute_param_type_code,
      l_attribute_duration_code,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      p_effective_date_in,
      p_match_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_office_id);
            
   return l_location_level_code;
end get_location_level_code;
            
--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE get_tsid_ids
--------------------------------------------------------------------------------
procedure get_tsid_ids(
   p_location_id       out varchar2,
   p_parameter_id      out varchar2,
   p_parameter_type_id out varchar2,
   p_duration_id       out varchar2,
   p_tsid              in  varchar2)
is          
   l_parts str_tab_t := cwms_util.split_text(p_tsid, '.');
begin       
   p_location_id       := l_parts(1);
   p_parameter_id      := l_parts(2);
   p_parameter_type_id := l_parts(3);
   p_duration_id       := l_parts(5);
end get_tsid_ids;
            
--------------------------------------------------------------------------------
-- PRIVATE FUNCTION top_of_interval_on_or_before
--------------------------------------------------------------------------------
function top_of_interval_on_or_before(
   p_rec  in at_location_level%rowtype,
   p_date in date,
   p_tz   in varchar2 default null)
   return date
is          
   l_ts               timestamp;
   l_intvl            timestamp;
   l_origin           timestamp;
   l_high             integer;
   l_low              integer;
   l_mid              integer;
   l_expansion_factor integer := 5;
   l_tz               varchar2(28) := nvl(p_tz, 'UTC');
begin       
   -------------------------------------
   -- get the date to interpolate for --
   -------------------------------------
   if p_date is null then
      l_ts := systimestamp at time zone l_tz;
   else     
      l_ts := from_tz(cast(p_date as timestamp), l_tz);
   end if;
   -----------------------------
   -- get the interval origin --
   -----------------------------
   l_origin := from_tz(p_rec.interval_origin, 'UTC') at time zone l_tz;
   -------------------------------
   -- find the desired interval --
   -------------------------------
   if p_rec.calendar_interval is null then
      if p_date > l_origin then
         ---------------------------------------
         -- time interval, origin before time --
         ---------------------------------------
         l_low  := 0;
         l_high := 1;
         while l_origin + l_high * p_rec.time_interval < p_date loop
            l_low  := l_high;
            l_high := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.time_interval > p_date then
               l_high := l_mid;
            else
               l_low := l_mid;
            end if;
         end loop;
      else  
         --------------------------------------
         -- time interval, origin after time --
         --------------------------------------
         l_low  := -1;
         l_high :=  0;
         while l_origin + l_low * p_rec.time_interval >= p_date loop
            l_high := l_low;
            l_low  := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.time_interval <= p_date then
               l_low := l_mid;
            else
               l_high := l_mid;
            end if;
         end loop;
      end if;
      l_intvl := l_origin + l_low * p_rec.time_interval;
   else     
      if p_date > l_origin then
         -------------------------------------------
         -- calendar interval, origin before time --
         -------------------------------------------
         l_low  := 0;
         l_high := 1;
         while l_origin + l_high * p_rec.calendar_interval < p_date loop
            l_low  := l_high;
            l_high := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.calendar_interval > p_date then
               l_high := l_mid;
            else
               l_low := l_mid;
            end if;
         end loop;
      else  
         ------------------------------------------
         -- calendar interval, origin after time --
         ------------------------------------------
         l_low  := -1;
         l_high :=  0;
         while l_origin + l_low * p_rec.calendar_interval >= p_date loop
            l_high := l_low;
            l_low  := l_high * l_expansion_factor;
         end loop;
         while l_high - l_low > 1 loop
            l_mid := (l_low + l_high) / 2;
            if l_origin + l_mid * p_rec.calendar_interval <= p_date then
               l_low := l_mid;
            else
               l_high := l_mid;
            end if;
         end loop;
      end if;
      l_intvl := l_origin + l_low * p_rec.calendar_interval;
   end if;  
   ---------------------------------------------------------------
   -- return the top of the interval in the specified time zone --
   ---------------------------------------------------------------
   return cast(l_intvl as date);
end top_of_interval_on_or_before;
            
--------------------------------------------------------------------------------
-- PRIVATE PROCEDURE find_nearest
--------------------------------------------------------------------------------
procedure find_nearest(
   p_nearest_date  out date,
   p_nearest_value out number,
   p_rec           in  at_location_level%rowtype,
   p_date          in  date,
   p_direction     in  varchar2,
   p_tz            in  varchar2 default 'UTC')
is          
   l_after        boolean;
   l_intvl        timestamp;
   l_date         date;
   l_date_before  date;
   l_date_after   date;
   l_value_before number;
   l_value_after  number;
begin
   l_date := cwms_util.change_timezone(p_date, 'UTC', p_tz);      
   l_intvl := top_of_interval_on_or_before(p_rec, l_date, 'UTC');
   l_after :=
      case upper(p_direction)
         when 'BEFORE' then false
         when 'AFTER'  then true
         else               null
      end;  
   if l_after is null then
      -------------------------------------
      -- CLOSEST REGARDLESS OF DIRECTION --
      -------------------------------------
      find_nearest(
         l_date_before,
         l_value_before,
         p_rec,
         l_date,
         'BEFORE',
         p_tz);
      find_nearest(
         l_date_after,
         l_value_after,
         p_rec,
         l_date,
         'AFTER',
         p_tz);
      if (l_date - l_date_before) < (l_date_after - l_date) then
         p_nearest_date  := l_date_before;
         p_nearest_value := l_value_before;
      else  
         p_nearest_date  := l_date_after;
         p_nearest_value := l_value_after;
      end if;
   else     
      if l_after then
         ------------------------
         -- ON OR AFTER P_DATE --
         ------------------------
         for i in 1..2 loop
            begin
               select distinct
                      cast(l_intvl + calendar_offset + time_offset as date),
                      value
                 into p_nearest_date,
                      p_nearest_value
                 from at_seasonal_location_level
                where location_level_code = p_rec.location_level_code
                  and cast(l_intvl + calendar_offset + time_offset as date) =
                         (select min(cast(l_intvl + calendar_offset + time_offset as date))
                            from at_seasonal_location_level
                           where location_level_code = p_rec.location_level_code
                                 and cast(l_intvl + calendar_offset + time_offset as date) >= l_date);
               exit; -- when found                                 
            exception
               when no_data_found then
                  if i = 2 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot locate seasonal level date before '
                        || to_char(p_date, 'ddMonyyyy hh24mi')
                        || ' for '
                        || get_location_level_id(p_rec.location_level_code));
                  else
                     if p_rec.calendar_interval is null then
                        l_intvl := l_intvl + p_rec.time_interval;
                     else
                        l_intvl := l_intvl + p_rec.calendar_interval;
                     end if;
                  end if;
            end;
         end loop;
      else  
         ------------------------
         -- ON OR BEFORE P_DATE --
         ------------------------
         for i in 1..2 loop  
            begin
               select distinct
                      cast(l_intvl + calendar_offset + time_offset as date),
                      value
                 into p_nearest_date,
                      p_nearest_value
                 from at_seasonal_location_level
                where location_level_code = p_rec.location_level_code
                  and cast(l_intvl + calendar_offset + time_offset as date) =
                         (select max(cast(l_intvl + calendar_offset + time_offset as date))
                            from at_seasonal_location_level
                           where location_level_code = p_rec.location_level_code
                                 and cast(l_intvl + calendar_offset + time_offset as date) <= l_date);
               exit; -- when found                                 
            exception
               when no_data_found then
                  if i = 2 then
                     cwms_err.raise(
                        'ERROR',
                        'Cannot locate seasonal level date after '
                        || to_char(p_date, 'ddMonyyyy hh24mi')
                        || ' for '
                        || get_location_level_id(p_rec.location_level_code));
                  else
                     if p_rec.calendar_interval is null then
                        l_intvl := l_intvl - p_rec.time_interval;
                     else
                        l_intvl := l_intvl - p_rec.calendar_interval;
                     end if;
                  end if;
            end;
         end loop;
      end if;
   end if;  
end find_nearest;        
            
--------------------------------------------------------------------------------
-- PROCEDURE parse_attribute_id
--------------------------------------------------------------------------------
procedure parse_attribute_id(
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_attribute_id       in  varchar2)
is          
   l_parts str_tab_t := cwms_util.split_text(p_attribute_id, '.');
begin       
   if p_attribute_id is null then
      p_parameter_id       := null;
      p_parameter_type_id  := null;
      p_duration_id        := null;
   else     
      if l_parts.count < 3 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_attribute_id,
            'location level attribute identifier');
      end if;
      p_parameter_id       := l_parts(1);
      p_parameter_type_id  := l_parts(2);
      p_duration_id        := l_parts(3);
   end if;  
end parse_attribute_id;   
            
--------------------------------------------------------------------------------
-- FUNCTION get_attribute_id
--------------------------------------------------------------------------------
function get_attribute_id(
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2)
   return varchar2 /*result_cache*/
is          
   l_attribute_id varchar2(83);
begin       
   if p_parameter_id is null 
      or p_parameter_type_id is null
      or p_duration_id is null
   then     
      return null;
   end if;  
   l_attribute_id := p_parameter_id
                     || '.' || p_parameter_type_id
                     || '.' || p_duration_id;
                          
   return l_attribute_id;                          
end get_attribute_id;
            
--------------------------------------------------------------------------------
-- PROCEDURE parse_location_level_id
--------------------------------------------------------------------------------
procedure parse_location_level_id(
   p_location_id        out varchar2,
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_specified_level_id out varchar2,
   p_location_level_id  in  varchar2)
is          
   l_parts str_tab_t := cwms_util.split_text(p_location_level_id, '.');
begin       
   if l_parts.count < 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_location_level_id,
         'location level identifier');
   end if;  
   p_location_id        := l_parts(1);
   p_parameter_id       := l_parts(2);
   p_parameter_type_id  := l_parts(3);
   p_duration_id        := l_parts(4);
   p_specified_level_id := l_parts(5);
end parse_location_level_id;   
            
--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_level_code in number)
   return varchar2 /*result_cache*/
is          
   l_location_level_id varchar2(422);
   l_office_id         varchar2(16);
   l_location_id       varchar2(49);
   l_parameter_id      varchar2(49);
   l_parameter_type_id varchar2(16);
   l_duration_id       varchar2(16);
   l_spec_level_id     varchar2(256);
   l_effective_date    varchar2(14);
begin       
   select co.office_id,
          vl.location_id,
          vp.parameter_id,
          cpt.parameter_type_id,
          cd.duration_id,
          asl.specified_level_id,
          to_char(a_ll.location_level_date, 'ddMonyyyy hh24mi')
     into l_office_id,
          l_location_id,
          l_parameter_id,
          l_parameter_type_id,
          l_duration_id,
          l_spec_level_id,
          l_effective_date
     from at_location_level a_ll,
          cwms_office co,
          av_loc vl,
          av_parameter vp,
          cwms_parameter_type cpt,
          cwms_duration cd,
          at_specified_level asl
    where a_ll.location_level_code = p_location_level_code
      and vl.location_code = a_ll.location_code
      and vl.unit_system = 'EN'
      and vp.parameter_code = a_ll.parameter_code
      and cpt.parameter_type_code = a_ll.parameter_type_code
      and cd.duration_code = a_ll.duration_code
      and asl.specified_level_code = a_ll.specified_level_code
      and co.office_code = vp.db_office_code;
            
   l_location_level_id :=
      l_office_id
      || '/' || l_location_id
      || '.' || l_parameter_id
      || '.' || l_parameter_type_id
      || '.' || l_duration_id
      || '.' || l_spec_level_id
      || '@' || l_effective_date;
            
   return l_location_level_id;
            
end get_location_level_id;
            
--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2)
   return varchar2  /*result_cache*/
is          
   l_location_level_id varchar2(390);
begin       
   l_location_level_id := p_location_id
                          || '.' || p_parameter_id
                          || '.' || p_parameter_type_id
                          || '.' || p_duration_id
                          || '.' || p_specified_level_id;
                          
   return l_location_level_id;                          
end get_location_level_id;   
            
--------------------------------------------------------------------------------
-- PROCEDURE parse_loc_lvl_indicator_id
--------------------------------------------------------------------------------
procedure parse_loc_lvl_indicator_id(
   p_location_id          out varchar2,
   p_parameter_id         out varchar2,
   p_parameter_type_id    out varchar2,
   p_duration_id          out varchar2,
   p_specified_level_id   out varchar2,
   p_level_indicator_id   out varchar2,
   p_loc_lvl_indicator_id in  varchar2)
is          
   l_parts str_tab_t := cwms_util.split_text(p_loc_lvl_indicator_id, '.');
begin       
   if l_parts.count < 6 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_loc_lvl_indicator_id,
         'location level indicator identifier');
   end if;  
   p_location_id        := l_parts(1);
   p_parameter_id       := l_parts(2);
   p_parameter_type_id  := l_parts(3);
   p_duration_id        := l_parts(4);
   p_specified_level_id := l_parts(5);
   p_level_indicator_id := l_parts(6);
end parse_loc_lvl_indicator_id;   
            
--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_id
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2,
   p_level_indicator_id in varchar2)
   return varchar2 /*result_cache*/
is          
   l_location_level_id varchar2(374);
begin       
   l_location_level_id := p_location_id
                          || '.' || p_parameter_id
                          || '.' || p_parameter_type_id
                          || '.' || p_duration_id
                          || '.' || p_specified_level_id
                          || '.' || p_level_indicator_id;
   return l_location_level_id;                          
end get_loc_lvl_indicator_id;   
            
--------------------------------------------------------------------------------
-- PROCEDURE create_specified_level_out
--------------------------------------------------------------------------------
procedure create_specified_level_out(
   p_level_code     out number,
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null)
is          
   l_office_code      number;
   l_cwms_office_code number;
   l_fail_if_exists   boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_level_code       number(10) := null;
   l_rec              at_specified_level%rowtype;
begin       
   -------------------
   -- sanity checks --
   -------------------
   validate_specified_level_input(l_office_code, p_office_id, p_level_id);
   select office_code
     into l_cwms_office_code
     from cwms_office
    where office_id = 'CWMS';
         ------------------------------------------------------------
         -- see if the level id already exists for the CWMS office --
         ------------------------------------------------------------
   begin    
      select *
        into l_rec
        from at_specified_level
       where office_code = l_cwms_office_code
         and upper(specified_level_id) = upper(p_level_id);
      if l_fail_if_exists then
         --------------------
         -- raise an error --
         --------------------
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Specified level',
            p_level_id);
      else  
         p_level_code := l_rec.specified_level_code;
      end if;
   exception
      when no_data_found then
         -----------------------------------------------------------------
         -- see if the level id already exists for the specified office --
         -----------------------------------------------------------------
         begin
            select *
              into l_rec
              from at_specified_level
             where office_code = l_office_code
               and upper(specified_level_id) = upper(p_level_id);
            if l_fail_if_exists then
               --------------------
               -- raise an error --
               --------------------
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'Specified level',
                  p_level_id);
            else
               --------------------------------
               -- update the existing record --
               --------------------------------
               p_level_code := l_rec.specified_level_code;
               update at_specified_level
                  set specified_level_id = p_level_id, -- might change case
                      description = p_description
                where specified_level_code = p_level_code;
            end if;
         exception
            when no_data_found then
               ---------------------------
               -- create the new record --
               ---------------------------
               p_level_code := cwms_seq.nextval;
               insert
                 into at_specified_level
               values (p_level_code, l_office_code, p_level_id, p_description);
         end;
   end;     
            
end create_specified_level_out;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_specified_level
--------------------------------------------------------------------------------
procedure store_specified_level(
   p_level_id       in varchar2,
   p_description    in varchar2,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null)
is          
   l_specified_level_code number(10);
begin       
   create_specified_level_out(
      l_specified_level_code,
      p_level_id,
      p_description,
      p_fail_if_exists,
      p_office_id);
end store_specified_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_specified_level
--------------------------------------------------------------------------------
procedure store_specified_level(
   p_obj            in specified_level_t,
   p_fail_if_exists in varchar2 default 'T')
is          
begin       
   store_specified_level(
      p_obj.level_id,
      p_obj.description,
      p_fail_if_exists,   
      p_obj.office_id);
end store_specified_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE get_specified_level_code
--------------------------------------------------------------------------------
procedure get_specified_level_code(
   p_level_code        out number,
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
is          
   l_office_code       number(10);
   l_cwms_office_code  number(10);
   l_fail_if_not_found boolean;
begin       
   -------------------
   -- sanity checks --
   -------------------
   validate_specified_level_input(l_office_code, p_office_id, p_level_id);
   l_fail_if_not_found := cwms_util.return_true_or_false(p_fail_if_not_found);
   select office_code
     into l_cwms_office_code
     from cwms_office
    where office_id = 'CWMS';
   -----------------------
   -- retrieve the code --
   -----------------------
   begin    
      select specified_level_code
        into p_level_code
        from at_specified_level
       where office_code = l_cwms_office_code
         and upper(specified_level_id) = upper(p_level_id);
   exception
      when no_data_found then
         begin
            select specified_level_code
              into p_level_code
              from at_specified_level
             where office_code = l_office_code
               and upper(specified_level_id) = upper(p_level_id);
         exception
            when no_data_found then
               if l_fail_if_not_found then
                  cwms_err.raise(
                     'ITEM_DOES_NOT_EXIST',
                     'Specified level',
                     p_level_id);
               else
                  p_level_code := null;
               end if;
         end;
   end;     
end get_specified_level_code;
            
--------------------------------------------------------------------------------
-- FUNCTION get_specified_level_code
--------------------------------------------------------------------------------
function get_specified_level_code(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
   return number
is          
   l_level_code number(10);
begin       
   get_specified_level_code(
      l_level_code,
      p_level_id,
      p_fail_if_not_found,
      p_office_id);
            
   return l_level_code;
end get_specified_level_code;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_specified_level
--------------------------------------------------------------------------------
procedure retrieve_specified_level(
   p_description    out varchar2,
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null)
is          
begin       
   select description
     into p_description
     from at_specified_level
    where specified_level_code = 
      get_specified_level_code(
         p_level_id,
         'T',
         p_office_id);
end retrieve_specified_level;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_specified_level
--------------------------------------------------------------------------------
function retrieve_specified_level(
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null)
   return specified_level_t
is          
begin       
   return specified_level_t(get_specified_level_code(
         p_level_id,
         'T',
         p_office_id));
end retrieve_specified_level;
   
--------------------------------------------------------------------------------
-- PROCEDURE rename_specified_level
--------------------------------------------------------------------------------
procedure rename_specified_level(
   p_old_level_id in varchar2,
   p_new_level_id in varchar2,
   p_office_id    in varchar2 default null)
is
   l_office_code  number(10) := cwms_util.get_db_office_code(p_office_id);
   l_old_level_id at_specified_level.specified_level_id%type; 
begin
   begin
      select office_code,
             specified_level_id
        into l_office_code,
             l_old_level_id
        from at_specified_level
       where upper(specified_level_id) = upper(p_old_level_id)
         and office_code in (l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_old_level_id,
            'Specified Level ID');
   end;
   if l_office_code = cwms_util.db_office_code_all then
      cwms_err.raise(
         'ERROR',
         'Cannot rename a Specified Level owned by CWMS');
   end if;
   update at_specified_level
      set specified_level_id = p_new_level_id
    where specified_level_id = l_old_level_id
      and office_code = l_office_code; 
end rename_specified_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE delete_specified_level
--------------------------------------------------------------------------------
procedure delete_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
is
   l_spec_level_code  number;
begin       
   --------------------------------
   -- delete the existing record --
   --------------------------------
   l_spec_level_code := get_specified_level_code(
             p_level_id, 
             p_fail_if_not_found, 
             p_office_id);
   delete from at_specified_level
    where specified_level_code = l_spec_level_code;
end delete_specified_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE cat_specified_levels
--          
-- The cursor returned by this routine contains three fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--    3 : description        varchar2(256)
--          
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure cat_specified_levels(
   p_level_cursor   out sys_refcursor,
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
is          
   l_level_id_mask  varchar2(256);
   l_office_id_mask varchar2(16);
begin       
   ----------------------------------------------
   -- normalize the wildcards (handle * and ?) --
   ----------------------------------------------
   l_level_id_mask  := cwms_util.normalize_wildcards(upper(p_level_id_mask));
   l_office_id_mask := nvl(upper(p_office_id_mask), cwms_util.user_office_id);
   l_office_id_mask := cwms_util.normalize_wildcards(l_office_id_mask);
   -----------------------------
   -- get the matching levels --
   -----------------------------
   open p_level_cursor
    for select o.office_id,
               l.specified_level_id,
               l.description
          from cwms_office o,
               at_specified_level l
         where upper(o.office_id) like l_office_id_mask
           and l.office_code = o.office_code
           and upper(l.specified_level_id) like l_level_id_mask;
end cat_specified_levels;
            
--------------------------------------------------------------------------------
-- FUNCTION cat_specified_levels
--          
-- The cursor returned by this routine contains three fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--    3 : description        varchar2(256)
--          
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
function cat_specified_levels(
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor
is          
   l_level_cursor sys_refcursor;
begin       
   cat_specified_levels(
      l_level_cursor,
      p_level_id_mask,
      p_office_id_mask);
            
   return l_level_cursor;
end cat_specified_levels;
            
--------------------------------------------------------------------------------
-- PROCEDURE create_location_level
--------------------------------------------------------------------------------
procedure create_location_level(
   p_location_level_code     out number,
   p_fail_if_exists          in  varchar2 default 'T',
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_tsid                    in  varchar2 default null,
   p_expiration_date         in  date, 
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_office_id               in  varchar2 default null)
is          
   l_location_level_code       number(10) := null;
   l_office_code               number;
   l_fail_if_exists            boolean;
   l_spec_level_code           number(10);
   l_interval_origin           date;
   l_location_code             number(10);
   l_location_tz_code          number(10);
   l_parts                     str_tab_t;
   l_base_parameter_id         varchar2(16);
   l_sub_parameter_id          varchar2(32);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_level_factor              binary_double;
   l_level_offset              binary_double;
   l_attr_factor               binary_double;
   l_attr_offset               binary_double;
   l_attribute_value           number;
   l_effective_date            date;
   l_expiration_date           date;
   l_timezone_id               varchar2(28);
   l_effective_date_out        date;
   l_expiration_date_out       date;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_calendar_interval         yminterval_unconstrained;
   l_time_interval             dsinterval_unconstrained;
   l_ts_code                   number(10);
   l_count                     pls_integer;
   l_interpolate               varchar2(1);
   l_level_param_is_elev       boolean;
   l_attr_param_is_elev        boolean;
   l_level_vert_datum_offset   binary_double;
   l_attr_vert_datum_offset    binary_double;
begin       
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   if p_interval_months is not null then
      l_calendar_interval := cwms_util.months_to_yminterval(p_interval_months);
   end if;  
   if p_interval_minutes is not null then
      l_time_interval := cwms_util.minutes_to_dsinterval(p_interval_minutes);
   end if;  
   -------------------
   -- sanity checks --
   -------------------
   l_count :=
      case p_level_value is null
         when true  then 0
         when false then 1
      end +
      case p_seasonal_values is null
         when true  then 0
         when false then 1
      end +
      case p_tsid is null
         when true  then 0
         when false then 1
      end;
   validate_specified_level_input(l_office_code, p_office_id, p_spec_level_id);
   l_location_code := cwms_loc.get_location_code(l_office_code, p_location_id);
   if p_attribute_value is not null and p_attribute_parameter_id is null then
      cwms_err.raise(
         'ERROR',
         'Must specify attribute parameter id with attribute value '
         || 'in CREATE_LOCATION_LEVEL');
   end if;
   if l_count != 1 then
      cwms_err.raise(
         'ERROR',
         'Must specify exactly one of p_level_value, p_seasonal_values, and p_tsid '
         || 'in CREATE_LOCATION_LEVEL');
   end if;
   if p_seasonal_values is not null then
      if l_calendar_interval is null and l_time_interval is null then
         cwms_err.raise(
            'ERROR',
            'seasonal values require either months interval or minutes interval '
            || 'in CREATE_LOCATION_LEVEL');
      elsif l_calendar_interval is not null and l_time_interval is not null then
         cwms_err.raise(
            'ERROR',
            'seasonal values cannot have months interval and minutes interval '
            || 'in CREATE_LOCATION_LEVEL');
      end if;
   end if;
   if p_level_value is null then
      l_interpolate := p_interpolate;
   end if;
   -------------------------------------------------------
   -- default the time zone to the location's time zone --
   -------------------------------------------------------
   if p_timezone_id is null then
      select time_zone_code
        into l_location_tz_code
        from at_physical_location
       where location_code = l_location_code;
      if l_location_tz_code is null then
         cwms_err.raise(
            'ERROR',
            'Location '''
            ||p_location_id
            ||''' must be assigned a time zone before calling this routine.');
      end if;    
      select time_zone_name
        into l_timezone_id
        from cwms_time_zone
       where time_zone_code = l_location_tz_code;
   else     
      l_timezone_id := p_timezone_id;
   end if;  
   ---------------------------------
   -- get the codes for input ids --
   ---------------------------------
   l_effective_date := cwms_util.change_timezone(
      nvl(p_effective_date, date '1900-01-01'),
      l_timezone_id, 
      'UTC');
   l_expiration_date := cwms_util.change_timezone(
      p_expiration_date,
      l_timezone_id, 
      'UTC');
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_effective_date_out,
      l_expiration_date_out,
      l_attribute_parameter_code,
      l_attribute_param_type_code,
      l_attribute_duration_code,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      l_effective_date,
      true,             -- match date exactly
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_office_id);
   if p_tsid is not null then
      l_ts_code := cwms_ts.get_ts_code(p_tsid, l_office_code);
   end if;
   -------------------------------
   -- get the units conversions --
   -------------------------------
   get_units_conversion(
      l_level_factor,
      l_level_offset,
      true, -- To CWMS
      p_level_units,
      l_parameter_code);
   if p_attribute_value is null then
      l_attribute_value := null;
   else     
      get_units_conversion(
         l_attr_factor,
         l_attr_offset,
         true, -- To CWMS
         p_attribute_units,
         l_attribute_parameter_code);
      l_attribute_value := cwms_rounding.round_f(p_attribute_value * l_attr_factor + l_attr_offset, 12);
   end if;  
   ----------------------------------------------
   -- get vertical datum offset for elevations --
   ----------------------------------------------
   l_level_param_is_elev := instr(upper(p_parameter_id), 'ELEV') = 1; 
   l_attr_param_is_elev  := instr(upper(p_attribute_parameter_id), 'ELEV') = 1;
   if l_level_param_is_elev then
      l_level_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_level_units);
      l_level_offset := l_level_offset - l_level_vert_datum_offset;
   end if;
   if l_attr_param_is_elev then
      l_attr_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_attribute_units);
      l_attribute_value := l_attribute_value - l_attr_vert_datum_offset;
   end if;
   --------------------------------------
   -- determine whether already exists --
   --------------------------------------
   if l_location_level_code is null then
      ------------------------------------
      -- new location level - insert it --
      ------------------------------------
      l_location_level_code := cwms_seq.nextval;
      if p_seasonal_values is null then
         -----------------------------------
         -- constant value or time series --
         -----------------------------------
         insert
           into at_location_level
         values(l_location_level_code,
                l_location_code,
                l_spec_level_code,
                l_parameter_code,
                l_parameter_type_code,
                l_duration_code,
                l_effective_date,
                p_level_value * l_level_factor + l_level_offset,
                p_level_comment,
                l_attribute_value,
                l_attribute_parameter_code,
                l_attribute_param_type_code,
                l_attribute_duration_code,
                p_attribute_comment,
                null, null, null,
                l_interpolate,
                l_ts_code,
                l_expiration_date);
      else  
         ---------------------
         -- seasonal values --
         ---------------------
         ----------------------------------------------------
         -- set the interval origin for the seaonal values --
         -- (always stored in UTC in the database)         --
         ----------------------------------------------------
         l_interval_origin := cwms_util.change_timezone(
            nvl(p_interval_origin, to_date('01JAN2000 0000', 'ddmonyyyy hh24mi')), 
            l_timezone_id, 
            'UTC');
         
         if l_calendar_interval is null then
            -------------------
            -- time interval --
            -------------------
            insert
              into at_location_level
            values(l_location_level_code,
                   l_location_code,
                   l_spec_level_code,
                   l_parameter_code,
                   l_parameter_type_code,
                   l_duration_code,
                   l_effective_date,
                   null,
                   p_level_comment,
                   l_attribute_value,
                   l_attribute_parameter_code,
                   l_attribute_param_type_code,
                   l_attribute_duration_code,
                   p_attribute_comment,
                   l_interval_origin,
                   null,
                   l_time_interval,
                   l_interpolate,
                   l_ts_code,
                   l_expiration_date);
         else
            -----------------------
            -- calendar interval --
            -----------------------
            insert
              into at_location_level
            values(l_location_level_code,
                   l_location_code,
                   l_spec_level_code,
                   l_parameter_code,
                   l_parameter_type_code,
                   l_duration_code,
                   l_effective_date,
                   null,
                   p_level_comment,
                   l_attribute_value,
                   l_attribute_parameter_code,
                   l_attribute_param_type_code,
                   l_attribute_duration_code,
                   p_attribute_comment,
                   l_interval_origin,
                   l_calendar_interval,
                   null,
                   l_interpolate,
                   l_ts_code,
                   l_expiration_date);
         end if;
         for i in 1..p_seasonal_values.count loop
            insert
              into at_seasonal_location_level
            values(l_location_level_code,
                   cwms_util.months_to_yminterval(p_seasonal_values(i).offset_months),
                   cwms_util.minutes_to_dsinterval(p_seasonal_values(i).offset_minutes),
                   p_seasonal_values(i).value * l_level_factor + l_level_offset);
         end loop;
      end if;
   else     
      -----------------------------
      -- existing location level --
      -----------------------------
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Location level ',
            get_location_level_id(l_location_level_code));
      end if;
      -------------------------------
      -- update the existing level --
      -------------------------------
      if p_seasonal_values is null then
         -----------------------------------
         -- constant value or time series --
         -----------------------------------
         update at_location_level
            set location_level_value = p_level_value * l_level_factor + l_level_offset,
                location_level_comment = p_level_comment,
                location_level_date = l_effective_date,
                attribute_value = l_attribute_value,
                attribute_parameter_code = l_attribute_parameter_code,
                attribute_comment = p_attribute_comment,
                interval_origin = null,
                calendar_interval = null,
                time_interval = null,
                interpolate = l_interpolate,
                ts_code = l_ts_code,
                expiration_date = l_expiration_date
          where location_level_code = l_location_level_code;
         delete
           from at_seasonal_location_level
          where location_level_code = l_location_level_code;
      else  
         ---------------------
         -- seasonal values --
         ---------------------
         ----------------------------------------------------
         -- set the interval origin for the seaonal values --
         -- (always stored in UTC in the database)         --
         ----------------------------------------------------
         if p_interval_origin is null then
            l_interval_origin := to_date('01JAN2000 0000', 'ddmonyyyy hh24mi');
         else
            l_interval_origin := cast(
               from_tz(cast(p_interval_origin as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
         end if;
         update at_location_level
            set location_level_value = null,
                location_level_comment = p_level_comment,
                location_level_date = l_effective_date,
                attribute_value = l_attribute_value,
                attribute_parameter_code = l_attribute_parameter_code,
                attribute_comment = p_attribute_comment,
                interval_origin = l_interval_origin,
                calendar_interval = l_calendar_interval,
                time_interval = l_time_interval,
                interpolate = l_interpolate,
                expiration_date = l_expiration_date
          where location_level_code = l_location_level_code;
         delete
           from at_seasonal_location_level
          where location_level_code = l_location_level_code;
         for i in 1..p_seasonal_values.count loop
            insert
              into at_seasonal_location_level
            values(l_location_level_code,
                   cwms_util.months_to_yminterval(p_seasonal_values(i).offset_months),
                   cwms_util.minutes_to_dsinterval(p_seasonal_values(i).offset_minutes),
                   p_seasonal_values(i).value * l_level_factor + l_level_offset);
         end loop;
      end if;
   end if;  
end create_location_level;
            
--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--          
-- Creates or updates a Location Level in the database
--          
-- Only one of p_interval_months and p_interval_minutes can be specified for
-- seasonal levels
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null)
is          
   l_location_level_code     number(10);
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin       
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
            
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);
            
   create_location_level(
      l_location_level_code,
      p_fail_if_exists,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      p_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_comment,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      null,
      null,
      p_seasonal_values,
      p_office_id);               
            
end store_location_level;
   
procedure store_location_level3(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_tsid                    in  varchar2 default null,
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null)
is
   l_location_level_code     number(10);
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);

   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);

   create_location_level(
      l_location_level_code,
      p_fail_if_exists,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      p_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_comment,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_tsid,
      null,
      p_seasonal_values,
      p_office_id);

end store_location_level3;

   
procedure store_location_level4(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_tsid                    in  varchar2 default null,
   p_expiration_date         in  date     default null, 
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null)
is
   l_location_level_code     number(10);
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);

   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);

   create_location_level(
      l_location_level_code,
      p_fail_if_exists,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      p_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_comment,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_tsid,
      p_expiration_date,
      p_seasonal_values,
      p_office_id);

end store_location_level4;

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--          
-- Creates or updates a Location Level in the database
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level in  location_level_t)
is          
   l_location_level location_level_t := p_location_level;
begin       
   l_location_level.store;
end store_location_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_location_level2
--          
-- Creates or updates a Location Level in the database using only text and 
-- numeric parameters
--          
-- Only one of p_interval_months and p_interval_minutes can be specified for
-- seasonal levels
--          
-- p_effective_date should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_interval_origin should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_seasonal_values should be specified as text records separated by the RS
-- character (chr(30)) with each record containing offset_months, offset_minutes
-- and offset_value, each separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure store_location_level2(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null, -- recordset of (offset_months, offset_minutes, offset_values) records
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null)
is          
   l_seasonal_values seasonal_value_tab_t := null;
   l_recordset       str_tab_tab_t;
   l_offset_months   integer;
   l_offset_minutes  integer;
   l_offset_value    number;
   l_effective_date  date;
   l_interval_origin date;
begin       
   ----------------------------
   -- parse the date strings --
   ----------------------------
   if p_effective_date is not null then
      l_effective_date := to_date(p_effective_date, 'YYYY/MM/DD HH24:MI:SS');
   end if;  
   if p_interval_origin is not null then
      l_interval_origin := to_date(p_interval_origin, 'YYYY/MM/DD HH24:MI:SS');
   end if;  
   -------------------------------------------
   -- parse the data seasonal values string --
   -------------------------------------------
   if p_seasonal_values is not null then
      l_seasonal_values := new seasonal_value_tab_t();
      l_recordset := cwms_util.parse_string_recordset(p_seasonal_values);
      for i in 1..l_recordset.count loop
         begin
            l_offset_months := to_number(l_recordset(i)(1));
            if l_offset_months != trunc(l_offset_months) then
               raise_application_error(-20999, 'Invalid');
            end if;
         exception 
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_recordset(i)(1),
                  'months offset (integer)');
         end;
         begin
            l_offset_minutes := to_number(l_recordset(i)(2));
            if l_offset_minutes != trunc(l_offset_minutes) then
               raise_application_error(-20999, 'Invalid');
            end if;
         exception 
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_recordset(i)(2),
                  'minutes offset (integer)');
         end;
         begin
            l_offset_value := to_number(l_recordset(i)(3));
         exception 
            when others then
               cwms_err.raise(
                  'INVALID_ITEM',
                  l_recordset(i)(3),
                  'seasonal value (number)');
         end;
         l_seasonal_values.extend;
         l_seasonal_values(i) := new seasonal_value_t(
            l_offset_months, 
            l_offset_minutes, 
            l_offset_value);
      end loop;
   end if;  
   -----------------------------
   -- call the base procedure --
   -----------------------------
   store_location_level(
      p_location_level_id,
      p_level_value,
      p_level_units,
      p_level_comment,
      l_effective_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      p_attribute_id,
      p_attribute_comment,
      l_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_seasonal_values,
      p_fail_if_exists,
      p_office_id);
end store_location_level2;   

procedure retrieve_location_level4(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_expiration_date         out date,
   p_seasonal_values         out seasonal_value_tab_t,
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_rec                       at_location_level%rowtype;
   l_spec_level_code           number(10);
   l_location_level_code       number(10);
   l_interval_origin           date;
   l_location_code             number(10);
   l_parts                     str_tab_t;
   l_base_parameter_id         varchar2(16);
   l_sub_parameter_id          varchar2(32);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_factor                    binary_double;
   l_offset                    binary_double;
   l_date                      date;
   l_match_date                boolean := cwms_util.return_true_or_false(p_match_date);
   l_office_code               number := cwms_util.get_office_code(p_office_id);
   l_office_id                 varchar2(16);
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
begin
   ----------------------------
   -- get the specified date --
   ----------------------------
   if p_date is null then
      l_date := cast(systimestamp at time zone 'UTC' as date);
   else
      l_date := cast(
         from_tz(cast(p_date as timestamp), p_timezone_id)
         at time zone 'UTC' as date);
   end if;
   ---------------------------------
   -- get the codes for input ids --
   ---------------------------------
   get_location_level_codes(
      l_location_level_code,
      l_spec_level_code,
      l_location_code,
      l_parameter_code,
      l_parameter_type_code,
      l_duration_code,
      l_date,
      p_expiration_date,
      l_attribute_parameter_code,
      l_attribute_param_type_code,
      l_attribute_duration_code,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_spec_level_id,
      l_date,
      l_match_date,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_office_id);

   if l_location_level_code is null then
      select office_id
        into l_office_id
        from cwms_office
       where office_code = l_office_code;
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         l_office_id
         || '/' || p_location_id
         || '.' || p_parameter_id
         || '.' || p_parameter_type_id
         || '.' || p_duration_id
         || '.' || p_spec_level_id
         || '@' || l_date);
   end if;
   ------------------------------
   -- get the units conversion --
   ------------------------------
   get_units_conversion(
      l_factor,
      l_offset,
      false, -- From CWMS
      p_level_units,
      l_parameter_code);
   --------------------------------------
   -- get the at_location_level record --
   --------------------------------------
   select *
     into l_rec
     from at_location_level
    where location_level_code = l_location_level_code;
   p_level_comment        := l_rec.location_level_comment;
   p_effective_date       := l_rec.location_level_date;
   p_interval_months      := cwms_util.yminterval_to_months(l_rec.calendar_interval);
   p_interval_minutes     := cwms_util.dsinterval_to_minutes(l_rec.time_interval);
   p_interval_origin      := l_rec.interval_origin;
   p_interpolate          := l_rec.interpolate;
   p_tsid                 := case l_rec.ts_code is null
                                when true  then null
                                when false then cwms_ts.get_ts_id(l_rec.ts_code)
                             end;
   p_expiration_date      := l_rec.expiration_date;
   if l_rec.location_level_value is null then
      ---------------------
      -- seasonal values --
      ---------------------
      p_level_value     := null;
      p_seasonal_values := new seasonal_value_tab_t();
      for rec in (select *
                    from at_seasonal_location_level
                   where location_level_code = l_rec.location_level_code
                order by l_rec.interval_origin + calendar_offset + time_offset)
      loop
         p_seasonal_values.extend;
         p_seasonal_values(p_seasonal_values.count) :=
            new seasonal_value_t(
               cwms_util.yminterval_to_months(rec.calendar_offset),
               cwms_util.dsinterval_to_minutes(rec.time_offset),
               rec.value * l_factor + l_offset);
      end loop;
   else
      --------------------
      -- constant value --
      --------------------
      p_seasonal_values := null;
      p_level_value := l_rec.location_level_value * l_factor + l_offset;
   end if;
end retrieve_location_level4;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level
--          
-- Retrieves the Location Level in effect at a specified time
--          
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--          
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
procedure retrieve_location_level(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_tsid varchar2(183);
   l_expiration_date date;
begin
   retrieve_location_level4(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_tsid,
      l_expiration_date,
      p_seasonal_values,
      p_spec_level_id,
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_level_units,
      p_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_match_date,
      p_office_id);
end retrieve_location_level;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level
--          
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--          
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
procedure retrieve_location_level(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin       
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_seasonal_values,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_units,
      p_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_match_date,
      p_office_id);
end retrieve_location_level;

procedure retrieve_location_level3(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
   l_expiration_date         date;
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);
   retrieve_location_level4(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_tsid,
      l_expiration_date,
      p_seasonal_values,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_units,
      p_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_match_date,
      p_office_id);
end retrieve_location_level3;

procedure retrieve_location_level4(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_expiration_date         out date,
   p_seasonal_values         out seasonal_value_tab_t,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);
   retrieve_location_level4(
      p_level_value,
      p_level_comment,
      p_effective_date,
      p_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      p_tsid,
      p_expiration_date,
      p_seasonal_values,
      l_specified_level_id,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_level_units,
      p_date,
      p_timezone_id,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_match_date,
      p_office_id);
end retrieve_location_level4;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level2
--          
-- Retrieves the Location Level in effect at a specified time using only text
-- and numeric parameters
--          
-- p_date should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--          
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--          
-- p_effective_date is returned as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_interval_origin is returned as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_seasonal_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing offset_months, offset_minutes
-- and offset_value, each separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure retrieve_location_level2(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out varchar2,
   p_interval_origin         out varchar2,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
is          
   l_effective_date  date;
   l_interval_origin date;
   l_date            date := to_date(p_date, 'yyyy/mm/dd hh24:mi:ss');
   l_seasonal_values seasonal_value_tab_t;
   l_recordset_txt   varchar2(32767);
   l_rs              varchar2(1) := chr(30);
   l_gs              varchar2(1) := chr(29);
begin       
   retrieve_location_level(
      p_level_value,
      p_level_comment,
      l_effective_date,
      l_interval_origin,
      p_interval_months,
      p_interval_minutes,
      p_interpolate,
      l_seasonal_values,
      p_location_level_id,
      p_level_units,
      l_date,
      p_timezone_id,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_match_date,
      p_office_id);
            
   p_effective_date  := to_char(l_effective_date, 'yyyy/mm/dd hh24:mi:ss');      
   p_interval_origin := to_char(l_interval_origin, 'yyyy/mm/dd hh24:mi:ss');
   for i in 1..l_seasonal_values.count loop
      l_recordset_txt := l_recordset_txt
         || l_rs
         || to_char(l_seasonal_values(i).offset_months)
         || l_gs
         || to_char(l_seasonal_values(i).offset_minutes)
         || l_gs
         || to_char(l_seasonal_values(i).value);
   end loop;
   p_seasonal_values := substr(l_recordset_txt, 2);      
            
end retrieve_location_level2;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level
--          
-- Returns the Location Level in effect at a specified time
--          
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--          
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
function retrieve_location_level(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
   return location_level_t
is          
   l_location_id                 varchar2(49);
   l_parameter_id                varchar2(49);
   l_parameter_type_id           varchar2(16);
   l_duration_id                 varchar2(16);
   l_specified_level_id          varchar2(256);
   l_attribute_parameter_id      varchar2(49);
   l_attribute_parameter_type_id varchar2(16);
   l_attribute_duration_id       varchar2(16);
   l_location_level_code         number;
begin       
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
            
   parse_attribute_id(      
      l_attribute_parameter_id,
      l_attribute_parameter_type_id,
      l_attribute_duration_id,
      p_attribute_id);
            
   l_location_level_code := get_location_level_code(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_date,
      cwms_util.return_true_or_false(p_match_date),
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_parameter_type_id,
      l_attribute_duration_id,
      p_office_id);
            
            
   return case l_location_level_code is null
      when true  then null
      when false then location_level_t(zlocation_level_t(l_location_level_code))
   end;      
            
end retrieve_location_level;   
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_values_utc(
   p_level_values            out ztsv_array,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time_utc          in  date,
   p_end_time_utc            in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_office_id               in  varchar2 default null,
   p_in_recursion            in boolean default false)
is
   type encoded_date_t is table of boolean index by binary_integer;
   l_encoded_dates             encoded_date_t;
   l_rec                       at_location_level%rowtype;
   l_level_values              ztsv_array;
   l_spec_level_code           number(10);
   l_location_level_code       number(10);
   l_start_time                date;
   l_end_time                  date;
   l_start_time_utc            date := p_start_time_utc;
   l_end_time_utc              date;
   l_location_code             number(10);
   l_parameter_code            number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_effective_date            date;
   l_expiration_date           date;
   l_factor                    binary_double;
   l_offset                    binary_double;
   l_vert_datum_offset         binary_double;
   l_office_code               number := cwms_util.get_office_code(p_office_id);
   l_office_id                 varchar2(16) := cwms_util.get_db_office_id(p_office_id);
   l_date_prev                 date;
   l_date_next                 date;
   l_value                     number;
   l_value_prev                number;
   l_value_next                number;
   l_attribute_value           number := null;
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_attribute_factor          binary_double := null;
   l_attribute_offset          binary_double := null;
   l_unit                      varchar2(16);
   --------------------
   -- local routines --
   --------------------
   function encode_date(p_date in date) return binary_integer /*result_cache*/
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return (p_date - l_origin) * 1440;
   end;

   function decode_date(p_int in binary_integer) return date /*result_cache*/
   is
      l_origin constant date := to_date('01Jan2000 0000', 'ddMonyyyy hh24mi');
   begin
      return l_origin + p_int / 1440;
   end;
   
   function get_quality(p_rec in at_location_level%rowtype) return integer
   is 
      l_quality integer := 0;
   begin
      if p_rec.location_level_value is null and p_rec.interpolate = 'T' then   
         l_quality := 1; -- interpolate between values
      end if;  
      return l_quality; 
   end;
   
begin
   l_level_values := ztsv_array();
   -------------------------------------------------------
   -- get_location_level_codes() will try to create the --
   -- specified level if it doesn't exist, so test here --
   -------------------------------------------------------
   begin
      select specified_level_code
        into l_spec_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(p_spec_level_id)
         and office_code in (l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise('ITEM_DOES_NOT_EXIST', 'Specified level', l_office_id||'/'||p_spec_level_id);
   end;
   -----------------------------------------------------------
   -- get the codes and effective dates for the time window --
   -----------------------------------------------------------
   if p_end_time_utc is not null and p_end_time_utc != p_start_time_utc then
      if p_end_time_utc < p_start_time_utc then
         cwms_err.raise('ERROR', 'Parameter p_end_time_utc must be later than p_start_time_utc');
      end if;
      get_location_level_codes(
         l_location_level_code,
         l_spec_level_code,
         l_location_code,
         l_parameter_code,
         l_parameter_type_code,
         l_duration_code,
         l_effective_date,
         l_expiration_date,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         p_end_time_utc,
         false,
         p_attribute_value,
         p_attribute_units,
         p_attribute_parameter_id,
         p_attribute_param_type_id,
         p_attribute_duration_id,
         p_office_id);
      if l_location_level_code is null then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location level',
            l_office_id
            || '/' || p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '.' || p_spec_level_id
            || '@' || to_char(p_end_time_utc, 'dd-Mon-yyyy hh24:mi'));
      end if;
      l_encoded_dates(encode_date(l_effective_date)) := true;
      l_start_time_utc := l_effective_date;
      l_end_time_utc := get_next_effective_date(l_location_level_code, 'UTC');
      l_end_time_utc := least(p_end_time_utc, nvl(l_end_time_utc, p_end_time_utc));
      while l_effective_date > p_start_time_utc loop
         get_location_level_codes(
            l_location_level_code,
            l_spec_level_code,
            l_location_code,
            l_parameter_code,
            l_parameter_type_code,
            l_duration_code,
            l_effective_date,
            l_expiration_date,
            l_attribute_parameter_code,
            l_attribute_param_type_code,
            l_attribute_duration_code,
            p_location_id,
            p_parameter_id,
            p_parameter_type_id,
            p_duration_id,
            p_spec_level_id,
            l_effective_date - 1 / 1440,
            false,
            p_attribute_value,
            p_attribute_units,
            p_attribute_parameter_id,
            p_attribute_param_type_id,
            p_attribute_duration_id,
            p_office_id);
         if l_location_level_code is null then
            exit;
         end if;
         l_encoded_dates(encode_date(l_effective_date)) := true;
         l_start_time_utc := l_effective_date;
      end loop;
      l_start_time_utc := greatest(l_start_time_utc, p_start_time_utc);
   else
      -----------------------------------------
      -- no time window, just the start time --
      -----------------------------------------
      get_location_level_codes(
         l_location_level_code,
         l_spec_level_code,
         l_location_code,
         l_parameter_code,
         l_parameter_type_code,
         l_duration_code,
         l_effective_date,
         l_expiration_date,
         l_attribute_parameter_code,
         l_attribute_param_type_code,
         l_attribute_duration_code,
         p_location_id,
         p_parameter_id,
         p_parameter_type_id,
         p_duration_id,
         p_spec_level_id,
         l_start_time_utc,
         false,
         p_attribute_value,
         p_attribute_units,
         p_attribute_parameter_id,
         p_attribute_param_type_id,
         p_attribute_duration_id,
         p_office_id);
      if l_location_level_code is null then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location level',
            l_office_id
            || '/' || p_location_id
            || '.' || p_parameter_id
            || '.' || p_parameter_type_id
            || '.' || p_duration_id
            || '.' || p_spec_level_id
            || '@' || to_char(l_start_time_utc, 'dd-Mon-yyyy hh24:mi'));
      end if;
      l_encoded_dates(encode_date(l_effective_date)) := true;
   end if;
   if l_encoded_dates.count > 1 then
      -------------------------------------------
      -- working with multiple effective dates --
      -------------------------------------------
      declare
         l_values       ztsv_array;
         l_encoded_start_time integer := l_encoded_dates.first;
         l_encoded_end_time   integer := l_encoded_dates.next(l_encoded_start_time);
      begin
         while l_encoded_start_time is not null loop
            l_start_time := greatest(decode_date(l_encoded_start_time), l_start_time_utc);
            l_end_time := decode_date(l_encoded_end_time - 1); -- one minute before
            -------------------------------------
            -- recurse for the sub time window --
            -------------------------------------
            retrieve_loc_lvl_values_utc(
               l_values,
               p_location_id,
               p_parameter_id,
               p_parameter_type_id,
               p_duration_id,
               p_spec_level_id,
               p_level_units,
               l_start_time,
               l_end_time,
               p_attribute_value,
               p_attribute_units,
               p_attribute_parameter_id,
               p_attribute_param_type_id,
               p_attribute_duration_id,
               p_office_id,
               p_in_recursion => true);
            for i in 1..l_values.count loop
               l_level_values.extend;
               l_level_values(l_level_values.count) := l_values(i);
            end loop;
            l_encoded_start_time := l_encoded_dates.next(l_encoded_start_time);
            l_encoded_end_time   := nvl(l_encoded_dates.next(l_encoded_start_time), encode_date(l_end_time_utc));
         end loop;
         l_level_values(l_level_values.count).date_time := nvl(l_level_values(l_level_values.count).date_time, l_end_time_utc);
      end;
   else
      ------------------------------------------
      -- working with a single effective date --
      ------------------------------------------
      -------------------------------
      -- get the units conversions --
      -------------------------------
      l_unit := cwms_util.get_unit_id(cwms_util.parse_unit(p_level_units), l_office_id);
      get_units_conversion(
         l_factor,
         l_offset,
         false, -- From CWMS
         l_unit,
         l_parameter_code);
      if p_attribute_value is not null then
         get_units_conversion(
            l_attribute_factor,
            l_attribute_offset,
            true, -- To CWMS
            p_attribute_units,
            l_attribute_parameter_code);
         l_attribute_value := cwms_rounding.round_f(p_attribute_value * l_attribute_factor + l_attribute_offset, 12);
         if instr(upper(p_parameter_id), 'ELEV') = 1 and not p_in_recursion then
            l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_level_units);
            l_attribute_value := l_attribute_value - l_vert_datum_offset;
         end if;
      end if;
      --------------------------------------
      -- get the at_location_level record --
      --------------------------------------
      begin
         select *
           into l_rec
           from at_location_level
          where location_code = l_location_code
            and specified_level_code = l_spec_level_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and duration_code = l_duration_code
            and nvl(to_char(attribute_parameter_code), '@') = nvl(to_char(l_attribute_parameter_code), '@')
            and nvl(to_char(attribute_parameter_type_code), '@') = nvl(to_char(l_attribute_param_type_code), '@')
            and nvl(to_char(attribute_duration_code), '@') = nvl(to_char(l_attribute_duration_code), '@')
            and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
            and location_level_date = (select max(location_level_date)
                                         from at_location_level
                                        where location_code = l_location_code
                                          and specified_level_code = l_spec_level_code
                                          and parameter_code = l_parameter_code
                                          and parameter_type_code = l_parameter_type_code
                                          and duration_code = l_duration_code
                                          and nvl(to_char(attribute_parameter_code), '@') = nvl(to_char(l_attribute_parameter_code), '@')
                                          and nvl(to_char(attribute_parameter_type_code), '@') = nvl(to_char(l_attribute_param_type_code), '@')
                                          and nvl(to_char(attribute_duration_code), '@') = nvl(to_char(l_attribute_duration_code), '@')
                                          and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
                                          and location_level_date <= l_start_time_utc);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Location level',
               l_office_id
               || '/' || p_location_id
               || '.' || p_parameter_id
               || '.' || p_parameter_type_id
               || '.' || p_duration_id
               || '.' || p_spec_level_id
               || case
                     when p_attribute_value is null then
                        null
                     else
                        ' (' || p_attribute_value || ' ' || p_attribute_units || ')'
                  end
               || '@' || l_start_time_utc);
      end;
      ----------------------------
      -- fill out the tsv array --
      ----------------------------
      if l_rec.location_level_value is null and l_rec.ts_code is null then
         ---------------------
         -- seasonal values --
         ---------------------
         ---------------------------------------------------------
         -- find the nearest date/value on or before start time --
         ---------------------------------------------------------
         find_nearest(
            l_date_prev,
            l_value_prev,
            l_rec,
            l_start_time_utc,
            'BEFORE',
            'UTC');
         if l_date_prev = l_start_time_utc then
            l_value := l_value_prev * l_factor + l_offset;
         else
            --------------------------------------------------------
            -- find the nearest date/value on or after start time --
            --------------------------------------------------------
            find_nearest(
               l_date_next,
               l_value_next,
               l_rec,
               l_start_time_utc,
               'AFTER',
               'UTC');
            if l_date_next = l_start_time_utc then
               l_value := l_value_next * l_factor + l_offset;
            else
               -----------------------------
               -- compute the level value --
               -----------------------------
               if l_rec.interpolate = 'T' then
                  l_value := (
                     l_value_prev +
                     (l_start_time_utc - l_date_prev) /
                     (l_date_next - l_date_prev) *
                     (l_value_next - l_value_prev)) * l_factor + l_offset;
               else
                  l_value := l_value_prev * l_factor + l_offset;
               end if;
            end if;
         end if;
         l_level_values.extend;
         l_level_values(1) := new ztsv_type(l_start_time_utc, l_value, get_quality(l_rec));
         if l_end_time_utc is null then
            --------------------------------------------------
            -- called from retrieve_location_level_value(), --
            -- just looking for a single value              --
            --------------------------------------------------
            null;
         else
            -----------------------------------------------------
            -- find the remainder of values in the time window --
            -----------------------------------------------------
            loop
               find_nearest(
                  l_date_next,
                  l_value_next,
                  l_rec,
                  l_level_values(l_level_values.count).date_time + 1 / 86400,
                  'AFTER',
                  'UTC');
               l_level_values.extend;
               if l_date_next <= l_end_time_utc then
                  -------------------------------------
                  -- on or before end of time window --
                  -------------------------------------
                  l_level_values(l_level_values.count) :=
                     new ztsv_type(l_date_next, l_value_next * l_factor + l_offset, get_quality(l_rec));
               else
                  -------------------------------
                  -- beyond end of time window --
                  -------------------------------
                  find_nearest(
                     l_date_prev,
                     l_value_prev,
                     l_rec,
                     l_date_next - 1 / 86400,
                     'BEFORE',
                     'UTC');
                  -----------------------------
                  -- compute the level value --
                  -----------------------------
                  if l_rec.interpolate = 'T' and l_date_next != l_date_prev then
                     l_value := (
                        l_value_prev +
                        (l_end_time_utc - l_date_prev) /
                        (l_date_next - l_date_prev) *
                        (l_value_next - l_value_prev)) * l_factor + l_offset;
                  else
                     l_value := l_value_prev * l_factor + l_offset;
                  end if;
                  l_level_values(l_level_values.count) :=
                     new ztsv_type(l_end_time_utc, l_value, get_quality(l_rec));
               end if;
               if l_date_next > l_end_time_utc then
                  exit;
               end if;
            end loop;
         end if;
      elsif l_rec.location_level_value is null then
         -----------------
         -- time series --
         -----------------
         declare
            l_ts_cur sys_refcursor;
            l_dates   date_table_type;
            l_values  double_tab_t;
            l_quality number_tab_t;
            l_ts      ztsv_array;
            l_first   pls_integer;
            l_last    pls_integer;
            a         pls_integer;
            b         pls_integer;
         begin
            cwms_ts.retrieve_ts(
               p_at_tsv_rc       => l_ts_cur,
               p_cwms_ts_id      => cwms_ts.get_ts_id(l_rec.ts_code),
               p_units           => p_level_units,
               p_start_time      => l_start_time_utc,
               p_end_time        => l_end_time_utc,
               p_time_zone       => 'UTC',
               p_start_inclusive => 'T',
               p_end_inclusive   => 'T',
               p_previous        => 'T',
               p_next            => 'T',
               p_version_date    => cwms_util.non_versioned,
               p_max_version     => 'T',
               p_office_id       => l_office_id);
            fetch l_ts_cur bulk collect into l_dates, l_values, l_quality;
            close l_ts_cur;                                              
            l_ts := ztsv_array();
            l_ts.extend(l_dates.count);
            for i in 1..l_dates.count loop
               l_ts(i) := ztsv_type(l_dates(i), l_values(i), get_quality(l_rec));
            end loop;
            if l_ts is not null and l_ts.count > 0 then
               if l_ts(1).date_time < l_start_time_utc then
                  l_first := 2;
                  if l_ts(2).date_time > l_start_time_utc then
                     l_level_values.extend;
                     l_level_values(1) := ztsv_type(l_start_time_utc, null, get_quality(l_rec));
                     if l_rec.interpolate = 'T' then
                        a := 1;
                        b := 2;
                        l_level_values(1).value := l_ts(a).value + (l_start_time_utc  - l_ts(a).date_time) / (l_ts(b).date_time - l_ts(a).date_time) * (l_ts(b).value - l_ts(a).value);
                     else
                        l_level_values(1).value := l_ts(1).value;
                     end if;
                  end if;
               else
                  l_first := 1;
               end if;
               if l_ts(l_ts.count).date_time > l_end_time_utc then
                  l_last := l_ts.count - 1;
               else
                  l_last := l_ts.count;
               end if;
               for i in l_first..l_last loop
                  l_level_values.extend;
                  l_level_values(l_level_values.count) := l_ts(i);
               end loop;
               if l_ts(l_ts.count).date_time > l_end_time_utc then
                  if l_ts(l_ts.count - 1).date_time < l_end_time_utc then
                     l_level_values.extend;
                     l_level_values(l_level_values.count) := ztsv_type(l_end_time_utc, null, get_quality(l_rec));
                     if l_rec.interpolate = 'T' then
                        a := l_ts.count - 1;
                        b := l_ts.count;
                        l_level_values(l_level_values.count).value := l_ts(a).value + (l_end_time_utc  - l_ts(a).date_time) / (l_ts(b).date_time - l_ts(a).date_time) * (l_ts(b).value - l_ts(a).value);
                     else
                        l_level_values(l_level_values.count).value := l_ts(l_ts.count - 1).value;
                     end if;
                  end if;
               end if;
            end if;
         end;
      else
         --------------------
         -- constant value --
         --------------------
         l_value := l_rec.location_level_value * l_factor + l_offset;
         l_level_values.extend(2);
         l_level_values(1) := new ztsv_type(l_start_time_utc, l_value, get_quality(l_rec));
         l_level_values(2) := new ztsv_type(l_end_time_utc,   l_value, get_quality(l_rec));
      end if;
      if l_rec.expiration_date is not null then
         -----------------------------------------------------------------------------
         -- level has expiration date - see if it expires before end of time window --
         -----------------------------------------------------------------------------
         declare
            l_next   pls_integer;
            l_prev   pls_integer;
            l_values ztsv_array;
         begin
            select min(seq)
              into l_next
              from ( select date_time,
                            rownum as seq
                       from table(l_level_values)
                   )
             where date_time > l_rec.expiration_date;
             
            if l_next is not null then
               ---------------------------------------------
               -- level expires before end of time window --
               ---------------------------------------------
               if l_next = 1 then
                  ---------------------------------------------
                  -- level is expired for entire time window --
                  ---------------------------------------------
                  l_values := ztsv_array(
                     ztsv_type(l_level_values(1).date_time, null, get_quality(l_rec)),
                     ztsv_type(l_level_values(l_level_values.count).date_time, null, get_quality(l_rec)));
               else
                  ----------------------------------------------
                  -- level is expired for part of time window --
                  ----------------------------------------------
                  select ztsv_type(date_time, value, quality_code)
                    bulk collect
                    into l_values
                    from table(l_level_values)
                   where rownum < l_next; 
                   
                  l_prev := l_next - 1;
                  if l_rec.interpolate = 'T' then
                     declare
                        t  date := l_rec.expiration_date;
                        t1 date := l_level_values(l_prev).date_time;
                        t2 date := l_level_values(l_next).date_time;
                        v  binary_double;
                        v1 binary_double := l_level_values(l_prev).value;
                        v2 binary_double := l_level_values(l_next).value;
                     begin
                        v := v1 + (v2 - v1) * (t - t1) / (t2 - t1);
                        l_values.extend;
                        l_values(l_values.count) := ztsv_type(t-1/1440, v, get_quality(l_rec));
                     end;
                  else
                     l_values.extend;
                     l_values(l_values.count) := ztsv_type(l_rec.expiration_date-1/1440, l_level_values(l_prev).value, get_quality(l_rec));
                  end if;
                  l_values.extend(2);
                  l_values(l_values.count-1) := ztsv_type(l_rec.expiration_date, null, get_quality(l_rec));
                  l_values(l_values.count  ) := ztsv_type(l_level_values(l_level_values.count).date_time, null, get_quality(l_rec));
               end if;
               l_level_values := l_values;
            end if;
         end;
      end if;
      if instr(upper(p_parameter_id), 'ELEV') = 1 and l_rec.ts_code is null and not p_in_recursion then
         l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_level_units);
         if l_vert_datum_offset != 0 then
            for i in 1..l_level_values.count loop
               if l_level_values(i).value is not null then
                  l_level_values(i).value := l_level_values(i).value + l_vert_datum_offset;
               end if;
            end loop;
         end if;
      end if;
   end if;
   p_level_values := l_level_values;
end retrieve_loc_lvl_values_utc;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_office_id    varchar2(16);
   l_timezone_id  varchar2(28);
   l_start_time   date;
   l_end_time     date;
   l_level_values ztsv_array;
begin
   -----------------------------------------------------------
   -- get the start and end times of the time window in UTC --
   -----------------------------------------------------------
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_timezone_id := nvl(p_timezone_id, cwms_loc.get_local_timezone(p_location_id, l_office_id)); 
   if p_start_time is null then
      l_start_time := cast(systimestamp at time zone 'UTC' as date);
   else
      l_start_time := cast(
               from_tz(cast(p_start_time as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
   end if;
   if p_end_time is null then
      l_end_time := null;
   else
      l_end_time := cast(
               from_tz(cast(p_end_time as timestamp), l_timezone_id)
               at time zone 'UTC' as date);
   end if;
   -----------------------------------------------
   -- retrieve the location level values in UTC --
   -----------------------------------------------
   retrieve_loc_lvl_values_utc(
      p_level_values            =>  p_level_values,
      p_location_id             =>  p_location_id,
      p_parameter_id            =>  p_parameter_id,
      p_parameter_type_id       =>  p_parameter_type_id,
      p_duration_id             =>  p_duration_id,
      p_spec_level_id           =>  p_spec_level_id,
      p_level_units             =>  p_level_units,
      p_start_time_utc          =>  l_start_time,
      p_end_time_utc            =>  l_end_time,
      p_attribute_value         =>  p_attribute_value,
      p_attribute_units         =>  p_attribute_units,
      p_attribute_parameter_id  =>  p_attribute_parameter_id,
      p_attribute_param_type_id =>  p_attribute_param_type_id,
      p_attribute_duration_id   =>  p_attribute_duration_id,
      p_office_id               =>  p_office_id);
     
   -------------------------------------------------------   
   -- convert the times back to the specified time zone --
   -------------------------------------------------------
   select ztsv_type(cwms_util.change_timezone(date_time, 'UTC', l_timezone_id), value, quality_code)
     bulk collect
     into l_level_values
     from table(p_level_values);
     
   p_level_values := l_level_values;        
end retrieve_location_level_values;   
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is          
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_specified_level_id      varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin       
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level_values(
      p_level_values,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_specified_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_timezone_id,
      p_office_id);
end retrieve_location_level_values;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--          
-- Returns a time series of Location Level values for a specified time window
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is          
   l_values ztsv_array;
begin       
   retrieve_location_level_values(
      l_values,
      p_location_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
            
   return l_values;
end retrieve_location_level_values;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_values2
--          
-- Retreives a time series of Location Level values for a specified time window
-- using only text and numeric parameters
--          
-- p_start_time should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_end_time should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_level_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing date-time and value
-- separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_values2(
   p_level_values            out varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2,
   p_end_time                in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is          
   l_loc_lvl_values varchar2(32767);
   l_level_values   ztsv_array;
   l_rs             varchar2(1) := chr(30);
   l_gs             varchar2(1) := chr(29);
begin       
   retrieve_location_level_values(
      l_level_values,
      p_location_level_id,
      p_level_units,
      to_date(p_start_time, 'yyyy/mm/dd hh24:mi:ss'),
      to_date(p_end_time, 'yyyy/mm/dd hh24:mi:ss'),
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   for i in 1..l_level_values.count loop
      l_loc_lvl_values := l_loc_lvl_values
         || l_rs
         || to_char(l_level_values(i).date_time, 'yyyy/mm/dd hh24:mi:ss') 
         || l_gs
         || to_char(l_level_values(i).value); 
   end loop;
   p_level_values := substr(l_loc_lvl_values, 2);      
end retrieve_loc_lvl_values2;   
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_values2
--          
-- Returns a time series of Location Level values for a specified time window
-- using only text and numeric parameters
--          
-- p_start_time should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_end_time should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_level_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing date-time and value
-- separated by the GS character (chr(29))
--------------------------------------------------------------------------------
            
function retrieve_loc_lvl_values2(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2, -- yyyy/mm/dd hh:mm:ss
   p_end_time                in  varchar2, -- yyyy/mm/dd hh:mm:ss
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return varchar2 -- recordset of (date, value) records
is          
   l_level_values varchar2(32767);
begin       
   retrieve_loc_lvl_values2(
      l_level_values,
      p_location_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
            
   return l_level_values;
end retrieve_loc_lvl_values2;   
            

procedure retrieve_loc_lvl_values3(
   p_level_values            out ztsv_array,
   p_specified_times         in  ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_utc_dates    date_table_type;
   l_min_date_utc date;
   l_max_date_utc date;
   l_level_id_parts str_tab_t;
   l_attr_id_parts  str_tab_t;
   l_level_values ztsv_array;
   l_date_offset  number;  
   l_date_offsets number_tab_t;
   l_values       double_tab_t;
   l_quality      number_tab_t; 
   l_seq_props    cwms_lookup.sequence_properties_t;
   l_hi_idx       pls_integer;
   l_lo_idx       pls_integer;
   l_log_used     boolean; 
   l_ratio        number;
begin
   if p_specified_times is not null then 
      -------------------------------------------------- 
      -- collect the times and the time window in UTC --
      -------------------------------------------------- 
      select cwms_util.change_timezone(date_time, p_timezone_id, 'UTC')
        bulk collect
        into l_utc_dates
        from table(p_specified_times);
        
      select min(column_value),
             max(column_value)
        into l_min_date_utc,
             l_max_date_utc
        from table(l_utc_dates);
      ---------------------------------------------------------                              
      -- get the location level values the level breakpoints --
      ---------------------------------------------------------                              
      l_level_id_parts := cwms_util.split_text(p_location_level_id, '.');
      if p_attribute_id is null then
         l_attr_id_parts := str_tab_t(null, null, null);
      else
         l_attr_id_parts :=  cwms_util.split_text(p_attribute_id, '.'); 
      end if;                                           
      retrieve_loc_lvl_values_utc(
         p_level_values            => l_level_values,
         p_location_id             => l_level_id_parts(1),
         p_parameter_id            => l_level_id_parts(2),
         p_parameter_type_id       => l_level_id_parts(3),
         p_duration_id             => l_level_id_parts(4),
         p_spec_level_id           => l_level_id_parts(5),
         p_level_units             => p_level_units,
         p_start_time_utc          => l_min_date_utc,
         p_end_time_utc            => l_max_date_utc,
         p_attribute_value         => p_attribute_value,
         p_attribute_units         => p_attribute_units,
         p_attribute_parameter_id  => l_attr_id_parts(1),
         p_attribute_param_type_id => l_attr_id_parts(2),
         p_attribute_duration_id   => l_attr_id_parts(3),
         p_office_id               => p_office_id); 
      -----------------------------------------          
      -- set up variables to do lookups with --
      -----------------------------------------          
      select date_time - l_min_date_utc,
             value,
             quality_code
        bulk collect
        into l_date_offsets,
             l_values,
             l_quality 
        from table(l_level_values);
      l_seq_props := cwms_lookup.analyze_sequence(l_date_offsets);
      -------------------------------------------- 
      -- do the lookups for the specified times --
      -------------------------------------------- 
      p_level_values := ztsv_array();
      p_level_values.extend(p_specified_times.count);
      for i in 1..p_specified_times.count loop
         p_level_values(i) := ztsv_type(p_specified_times(i).date_time, null, 0);
         l_date_offset := l_utc_dates(i) - l_min_date_utc;
         l_hi_idx := cwms_lookup.find_high_index(l_date_offset, l_date_offsets, l_seq_props);
         l_lo_idx := l_hi_idx -1 ;
         l_ratio  := cwms_lookup.find_ratio(
            p_log_used                => l_log_used, 
            p_value                   => l_date_offset, 
            p_sequence                => l_date_offsets, 
            p_high_index              => l_hi_idx, 
            p_increasing              => l_seq_props.increasing_range, 
            p_in_range_behavior       => cwms_lookup.method_linear, 
            p_out_range_low_behavior  => cwms_lookup.method_null,   -- set values to null before earliest effective date 
            p_out_range_high_behavior => cwms_lookup.method_linear);
         if l_ratio is not null then
            if l_level_values(l_lo_idx).quality_code = 0 then
               ----------------------
               -- no interpolation --
               ----------------------
               p_level_values(i).value := l_level_values(l_lo_idx).value; 
            else
               -------------------
               -- interpolation --
               -------------------
               p_level_values(i).value := l_level_values(l_lo_idx).value + l_ratio * (l_level_values(l_hi_idx).value - l_level_values(l_lo_idx).value); 
            end if;
         end if;
      end loop;
      ---------------------------------------------------------      
      -- filter out any times before earliest effective date --
      ---------------------------------------------------------      
      select ztsv_type(date_time, value, quality_code)
        bulk collect
        into l_level_values
        from table(p_level_values)
       where value is not null;
      p_level_values := l_level_values;                        
   end if;
end retrieve_loc_lvl_values3;   
   

function retrieve_loc_lvl_values3(
   p_specified_times         in  ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is
   l_level_values ztsv_array;
begin
   retrieve_loc_lvl_values3(
      l_level_values,
      p_specified_times,
      p_location_level_id,
      p_level_units,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   return l_level_values;      
end retrieve_loc_lvl_values3;   

procedure retrieve_loc_lvl_values3(
   p_level_values            out double_tab_t,
   p_specified_times         in  date_table_type,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
begin
   if p_specified_times is not null then
      p_level_values := double_tab_t();
      p_level_values.extend(p_specified_times.count);
      for i in 1..p_specified_times.count loop
         p_level_values(i) := 
            retrieve_location_level_value(
               p_location_level_id, 
               p_level_units, 
               p_specified_times(i), 
               p_attribute_id, 
               p_attribute_value, 
               p_attribute_units, 
               p_timezone_id, 
               p_office_id);                           
      end loop;
   end if;
end retrieve_loc_lvl_values3;

function retrieve_loc_lvl_values3(
   p_specified_times         in  date_table_type,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return double_tab_t
is
   l_level_values double_tab_t;
begin
   retrieve_loc_lvl_values3(
      l_level_values,
      p_specified_times,
      p_location_level_id,
      p_level_units,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   return l_level_values;      
end retrieve_loc_lvl_values3;

procedure retrieve_loc_lvl_values3(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is
   l_cursor          sys_refcursor;
   l_specified_times date_table_type;
   l_level_values    double_tab_t;
   l_quality_codes   number_tab_t;
begin
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_cursor,
      p_cwms_ts_id      => p_ts_id, 
      p_units           => cwms_util.get_default_units(cwms_util.split_text(p_ts_id, 2, '.')), 
      p_start_time      => p_start_time, 
      p_end_time        => p_end_time, 
      p_time_zone       => p_timezone_id, 
      p_trim            => 'T', 
      p_start_inclusive => 'T', 
      p_end_inclusive   => 'T', 
      p_previous        => 'F', 
      p_next            => 'F', 
      p_version_date    => cwms_util.non_versioned, 
      p_max_version     => 'T', 
      p_office_id       => p_office_id);
   fetch l_cursor
     bulk collect
     into l_specified_times,
          l_level_values,
          l_quality_codes;
          
   close l_cursor;
   
   l_level_values := cwms_level.retrieve_loc_lvl_values3(
      p_specified_times   => l_specified_times, 
      p_location_level_id => p_location_level_id, 
      p_level_units       => p_level_units, 
      p_attribute_id      => p_attribute_id, 
      p_attribute_value   => p_attribute_value, 
      p_attribute_units   => p_attribute_units, 
      p_timezone_id       => p_timezone_id, 
      p_office_id         => p_office_id);
      
   p_level_values := ztsv_array();
   p_level_values.extend(l_level_values.count);
   for i in 1..l_level_values.count loop
      p_level_values(i) := ztsv_type(l_specified_times(i), l_level_values(i), 0);
   end loop;                
      
end retrieve_loc_lvl_values3;   

function retrieve_loc_lvl_values3(
   p_ts_id                   in  varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is
   l_level_values ztsv_array;
begin
   retrieve_loc_lvl_values3(
      l_level_values,
      p_ts_id,
      p_location_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
   return l_level_values;      
end retrieve_loc_lvl_values3;   

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--          
-- Retreives a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--          
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is          
   l_location_id       varchar2(49);
   l_parameter_id      varchar2(49);
   l_parameter_type_id varchar2(16);
   l_duration_id       varchar2(16);
begin       
   get_tsid_ids(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_ts_id);
            
   retrieve_location_level_values(
      p_level_values,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_spec_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);
            
end retrieve_location_level_values;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--          
-- Returns a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--          
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--          
-- The returned QUALITY_CODE values of the time series will be zero or one,
-- depending on whether the level is set to interpolate (1=interpolate, 0=no).
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array
is          
   l_values ztsv_array;
begin       
   retrieve_location_level_values(
      l_values,
      p_ts_id,
      p_spec_level_id,
      p_level_units,
      p_start_time,
      p_end_time,
      p_attribute_value,
      p_attribute_units,
      p_attribute_parameter_id,
      p_attribute_param_type_id,
      p_attribute_duration_id,
      p_timezone_id,
      p_office_id);
            
   return l_values;
end retrieve_location_level_values;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--          
-- Retreives a Location Level value for a specified time
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is          
   l_values ztsv_array;
begin       
   retrieve_location_level_values(
      l_values,
      p_location_level_id,
      p_level_units,
      p_date,
      null, 
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
            
   p_level_value := l_values(1).value;
end retrieve_location_level_value;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--          
-- Returns a Location Level value for a specified time
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number
is          
   l_level_value number;
begin       
   retrieve_location_level_value(
      l_level_value,
      p_location_level_id,
      p_level_units,
      p_date,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
            
   return l_level_value;
end retrieve_location_level_value;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--          
-- Retreives a Location Level value for a specified time for a specified Time
-- Series Identifier and Specified Level Identifier
--          
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
is          
   l_location_id       varchar2(49);
   l_parameter_id      varchar2(49);
   l_parameter_type_id varchar2(16);
   l_duration_id       varchar2(16);
begin       
   get_tsid_ids(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      p_ts_id);
            
   retrieve_location_level_value(
      p_level_value,
      get_location_level_id(
         l_location_id,
         l_parameter_id,
         l_parameter_type_id,
         l_duration_id,
         p_spec_level_id),
      p_level_units,
      p_date,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
            
end retrieve_location_level_value;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--          
-- Retrurns a Location Level value for a specified time for a specified Time
-- Series Identifier and Specified Level Identifier
--          
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number
is          
   l_location_level_value number(10);
begin       
   retrieve_location_level_value(
      l_location_level_value,
      p_ts_id,
      p_spec_level_id,
      p_level_units,
      p_date,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_timezone_id,
      p_office_id);
            
   return l_location_level_value;
end retrieve_location_level_value;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--          
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time
--          
-- The attribute values are returned in the units specified
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs(
   p_attribute_values        out number_tab_t,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
is          
   l_attribute_values number_tab_t := new number_tab_t();
begin       
   for rec in (
      select a_ll.attribute_value * c_uc.factor + c_uc.offset as attribute_value
        from at_location_level    a_ll,
             at_physical_location a_pl,
             at_base_location     a_bl,
             at_parameter         a_p1,
             at_parameter         a_p2,
             at_specified_level   a_sl,
             cwms_office          c_o,
             cwms_base_parameter  c_bp1,
             cwms_base_parameter  c_bp2,
             cwms_parameter_type  c_pt1,
             cwms_parameter_type  c_pt2,
             cwms_duration        c_d1,
             cwms_duration        c_d2,
             cwms_unit_conversion c_uc
       where c_o.office_code = cwms_util.get_office_code(upper(p_office_id))
         and a_bl.db_office_code = c_o.office_code
         and upper(a_bl.base_location_id) =
             upper(case
                      when instr(p_location_id, '-') = 0 then p_location_id
                      else substr(p_location_id, 1, instr(p_location_id, '-') - 1)
                   end)
         and nvl(upper(a_pl.sub_location_id), '.') =
             nvl(upper(case
                          when instr(p_location_id, '-') = 0 then null
                          else substr(p_location_id, instr(p_location_id, '-') + 1)
                       end), '.')
         and a_pl.base_location_code = a_bl.base_location_code
         and a_ll.location_code = a_pl.location_code
         and upper(c_bp1.base_parameter_id) =
             upper(case
                      when instr(p_parameter_id, '-') = 0 then p_parameter_id
                      else substr(p_parameter_id, 1, instr(p_parameter_id, '-') - 1)
                        end)
         and nvl(upper(a_p1.sub_parameter_id), '.') =
             nvl(upper(case
                          when instr(p_parameter_id, '-') = 0 then null
                          else substr(p_parameter_id, instr(p_parameter_id, '-') + 1)
                       end), '.')
         and a_ll.parameter_code = a_p1.parameter_code
         and upper(c_pt1.parameter_type_id) = upper(p_parameter_type_id)
         and a_ll.parameter_type_code = c_pt1.parameter_type_code
         and upper(c_d1.duration_id) = upper(p_duration_id)
         and a_ll.duration_code = c_d1.duration_code
         and upper(a_sl.specified_level_id) = upper(p_spec_level_id)
         and a_ll.specified_level_code = a_sl.specified_level_code
         and upper(c_bp2.base_parameter_id) =
             upper(case
                      when instr(p_attribute_parameter_id, '-') = 0 then p_attribute_parameter_id
                      else substr(p_attribute_parameter_id, 1, instr(p_attribute_parameter_id, '-') - 1)
                   end)
         and nvl(upper(a_p2.sub_parameter_id), '.') =
             nvl(upper(case
                          when instr(p_attribute_parameter_id, '-') = 0 then null
                          else substr(p_attribute_parameter_id, instr(p_attribute_parameter_id, '-') + 1)
                       end), '.')
         and a_ll.attribute_parameter_code = a_p2.parameter_code
         and upper(c_pt2.parameter_type_id) = upper(p_attribute_param_type_id)
         and a_ll.parameter_type_code = c_pt2.parameter_type_code
         and upper(c_d2.duration_id) = upper(p_attribute_duration_id)
         and a_ll.duration_code = c_d2.duration_code
         and c_uc.abstract_param_code = c_bp2.abstract_param_code
         and c_uc.from_unit_code = c_bp2.unit_code
         and c_uc.to_unit_id = p_attribute_units
         and a_ll.location_level_date = (
             select max(a_ll.location_level_date)
               from at_location_level    a_ll,
                    at_physical_location a_pl,
                    at_base_location     a_bl,
                    at_parameter         a_p1,
                    at_parameter         a_p2,
                    at_specified_level   a_sl,
                    cwms_office          c_o,
                    cwms_base_parameter  c_bp1,
                    cwms_base_parameter  c_bp2,
                    cwms_parameter_type  c_pt1,
                    cwms_parameter_type  c_pt2,
                    cwms_duration        c_d1,
                    cwms_duration        c_d2
             where c_o.office_code = cwms_util.get_office_code(upper(p_office_id))
                and a_bl.db_office_code = c_o.office_code
                and upper(a_bl.base_location_id) =
                    upper(case
                             when instr(p_location_id, '-') = 0 then p_location_id
                             else substr(p_location_id, 1, instr(p_location_id, '-') - 1)
                          end)
                and nvl(upper(a_pl.sub_location_id), '.') =
                    nvl(upper(case
                                 when instr(p_location_id, '-') = 0 then null
                                 else substr(p_location_id, instr(p_location_id, '-') + 1)
                              end), '.')
                and a_pl.base_location_code = a_bl.base_location_code
                and a_ll.location_code = a_pl.location_code
                and upper(c_bp1.base_parameter_id) =
                    upper(case
                             when instr(p_parameter_id, '-') = 0 then p_parameter_id
                             else substr(p_parameter_id, 1, instr(p_parameter_id, '-') - 1)
                               end)
                and nvl(upper(a_p1.sub_parameter_id), '.') =
                    nvl(upper(case
                                 when instr(p_parameter_id, '-') = 0 then null
                                 else substr(p_parameter_id, instr(p_parameter_id, '-') + 1)
                              end), '.')
                and a_ll.parameter_code = a_p1.parameter_code
                and upper(c_pt1.parameter_type_id) = upper(p_parameter_type_id)
                and a_ll.parameter_type_code = c_pt1.parameter_type_code
                and upper(c_d1.duration_id) = upper(p_duration_id)
                and a_ll.duration_code = c_d1.duration_code
                and upper(a_sl.specified_level_id) = upper(p_spec_level_id)
                and a_ll.specified_level_code = a_sl.specified_level_code
                and upper(c_bp2.base_parameter_id) =
                    upper(case
                             when instr(p_attribute_parameter_id, '-') = 0 then p_attribute_parameter_id
                             else substr(p_attribute_parameter_id, 1, instr(p_attribute_parameter_id, '-') - 1)
                          end)
                and nvl(upper(a_p2.sub_parameter_id), '.') =
                    nvl(upper(case
                                 when instr(p_attribute_parameter_id, '-') = 0 then null
                                 else substr(p_attribute_parameter_id, instr(p_attribute_parameter_id, '-') + 1)
                              end), '.')
                and a_ll.attribute_parameter_code = a_p2.parameter_code
                and upper(c_pt2.parameter_type_id) = upper(p_attribute_param_type_id)
                and a_ll.parameter_type_code = c_pt2.parameter_type_code
                and upper(c_d2.duration_id) = upper(p_attribute_duration_id)
                and a_ll.duration_code = c_d2.duration_code
                and a_ll.location_level_date <=
                    case
                      when p_date is null then
                         cast(systimestamp at time zone 'UTC' as date)
                      else
                         cast(from_tz(cast(p_date as timestamp), nvl(p_timezone_id, 'UTC')) as date)
                    end)
    order by a_ll.attribute_value * c_uc.factor + c_uc.offset)
   loop     
      l_attribute_values.extend;
      l_attribute_values(l_attribute_values.count) := cwms_rounding.round_f(rec.attribute_value, 9);
   end loop;
   p_attribute_values := l_attribute_values;    
end retrieve_location_level_attrs;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--          
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time
--          
-- The attribute values are returned in the units specified
--------------------------------------------------------------------------------
            
procedure retrieve_location_level_attrs(
   p_attribute_values        out number_tab_t,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
is          
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_spec_level_id           varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
begin       
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level_attrs(
      p_attribute_values,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
end retrieve_location_level_attrs;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--          
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time
--          
-- The attribute values are returned in the units specified
--------------------------------------------------------------------------------
function retrieve_location_level_attrs(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number_tab_t
is          
   l_attribute_values number_tab_t;
begin       
   retrieve_location_level_attrs(
      l_attribute_values,
      p_location_level_id,
      p_attribute_id,
      p_attribute_units,
      p_timezone_id,
      p_date,
      p_office_id);
            
   return l_attribute_values;
end retrieve_location_level_attrs;
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs2
--          
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--          
-- p_date should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- p_attribute_values is returned as text records separated by the RS character
-- (chr(30)) with each record containing an attribute value in the units 
-- specified
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
is          
   l_attribute_values number_tab_t;
begin       
   p_attribute_values := null;
   retrieve_location_level_attrs(
      l_attribute_values,
      p_location_level_id,
      p_attribute_id,
      p_attribute_units,
      p_timezone_id,
      to_date(p_date, 'yyyy/mm/dd hh24:mi:ss'),
      p_office_id);
   for i in 1..l_attribute_values.count loop 
      if i = l_attribute_values.count then
         p_attribute_values := p_attribute_values || to_char(l_attribute_values(i));
      else
         p_attribute_values := p_attribute_values || to_char(l_attribute_values(i)) || cwms_util.record_separator;
      end if;
   end loop;
end retrieve_location_level_attrs2;
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs2
--          
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--          
-- p_date should be specified as 'yyyy/mm/dd hh:mm:ss'
--          
-- The attribute values are returned as text records separated by the RS
-- character (chr(30)) with each record containing an attribute value in the 
-- units specified
--------------------------------------------------------------------------------
function retrieve_location_level_attrs2(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return varchar2
is          
   l_attribute_values varchar2(32767);
begin       
   retrieve_location_level_attrs2(
      l_attribute_values,
      p_location_level_id,
      p_attribute_id,
      p_attribute_units,
      p_timezone_id,
      p_date,
      p_office_id);
            
   return l_attribute_values;
end retrieve_location_level_attrs2;        
            
--------------------------------------------------------------------------------
-- PRIVATE FUNCTION lookup_level_or_attribute
--------------------------------------------------------------------------------
function lookup_level_or_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_value                   in  number,
   p_lookup_level            in  boolean,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number
is          
   l_location_id             varchar2(49);
   l_parameter_id            varchar2(49);
   l_parameter_type_id       varchar2(16);
   l_duration_id             varchar2(16);
   l_spec_level_id           varchar2(256);
   l_attribute_parameter_id  varchar2(49);
   l_attribute_param_type_id varchar2(16);
   l_attribute_duration_id   varchar2(16);
   l_value                   number;
   l_attrs                   number_tab_t;
   l_levels                  number_tab_t := new number_tab_t();
begin       
   -----------------------------
   -- retrieve the attributes --
   -----------------------------
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);      
   retrieve_location_level_attrs(
      l_attrs,
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_timezone_id,
      p_date,
      p_office_id);
   if l_attrs.count = 0 then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level with attribute',
         nvl(p_office_id, cwms_util.user_office_id)
         || '/' || p_location_level_id
         || '/' || p_attribute_id
         || '@' || to_char(nvl(p_date, sysdate), 'yyyy-mm-dd hh24mi'));
   end if;  
   -------------------------
   -- retrieve the levels --
   -------------------------
   l_levels.extend(l_attrs.count);
   for i in 1..l_attrs.count loop
      l_levels(i) := retrieve_location_level_value(
         p_location_level_id,
         p_level_units,
         p_date,
         l_attrs(i),
         p_attribute_id,
         p_attribute_units,
         p_timezone_id,
         p_office_id);
   end loop;
   ------------------------
   -- perform the lookup --
   ------------------------
   if p_lookup_level then
      l_value := cwms_lookup.lookup(
         p_value,
         l_attrs,
         l_levels,
         null,
         p_in_range_behavior,
         p_out_range_behavior,
         p_out_range_behavior);
   else     
      l_value := cwms_lookup.lookup(
         p_value,
         l_levels,
         l_attrs,
         null,
         p_in_range_behavior,
         p_out_range_behavior,
         p_out_range_behavior);
   end if;  
   -----------------------
   -- return the result --
   -----------------------
   return l_value;
end lookup_level_or_attribute;
            
--------------------------------------------------------------------------------
-- PROCEDURE lookup_level_by_attribute
--
-- Retrieves the level value of a Location Level that corresponds to a specified
-- attribute value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- attribute value is within the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
is          
begin       
   p_level := lookup_level_or_attribute(
      p_location_level_id,
      p_attribute_id,
      p_attribute_value,
      true, 
      p_level_units,
      p_attribute_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
end lookup_level_by_attribute;
            
--------------------------------------------------------------------------------
-- FUNCTION lookup_level_by_attribute
--
-- Returns the level value of a Location Level that corresponds to a specified
-- attribute value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- attribute value is within the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number
is          
   l_level number;
begin       
   lookup_level_by_attribute(
      l_level,
      p_location_level_id,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_level_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
            
   return l_level;
end lookup_level_by_attribute;
            
--------------------------------------------------------------------------------
-- PROCEDURE lookup_attribute_by_level
--
-- Retrieves the attribute value of a Location Level that corresponds to a 
-- specified level value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- level value is within the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
is          
begin       
   p_attribute := lookup_level_or_attribute(
      p_location_level_id,
      p_attribute_id,
      p_level_value,
      false,
      p_level_units,
      p_attribute_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
end lookup_attribute_by_level;
            
--------------------------------------------------------------------------------
-- FUNCTION lookup_attribute_by_level
--
-- Returns the attribute value of a Location Level that corresponds to a 
-- specified level value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- level value is within the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number
is          
   l_attribute number;
begin       
   lookup_attribute_by_level(
      l_attribute,
      p_location_level_id,
      p_attribute_id,
      p_level_value,
      p_level_units,
      p_attribute_units,
      p_in_range_behavior,
      p_out_range_behavior,
      p_timezone_id,
      p_date,
      p_office_id);
            
   return l_attribute;
end lookup_attribute_by_level;

--------------------------------------------------------------------------------
-- PROCEDURE rename_location_level
--------------------------------------------------------------------------------
procedure rename_location_level(
   p_old_location_level_id in  varchar2,
   p_new_location_level_id in  varchar2,
   p_office_id             in  varchar2 default null)
is
   l_office_code              number(10) := cwms_util.get_db_office_code(p_office_id);
   l_old_parts                str_tab_t; 
   l_new_parts                str_tab_t; 
   l_old_location_code        number(10);
   l_old_parameter_code       number(10);
   l_old_parameter_type_code  number(10);
   l_old_duration_code        number(10);  
   l_old_specified_level_code number(10);
   l_new_location_code        number(10);
   l_new_parameter_code       number(10);
   l_new_parameter_type_code  number(10);
   l_new_duration_code        number(10);
   l_new_specified_level_code number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_old_location_level_id is null or
      p_new_location_level_id is null
   then   
      cwms_err.raise(
         'ERROR',
         'Location Level IDs must not be null.');
   end if;
   l_old_parts := cwms_util.split_text(p_old_location_level_id, '.');
   if l_old_parts.count != 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_old_location_level_id,
         'Location Level ID');
   end if;
   l_new_parts := cwms_util.split_text(p_new_location_level_id, '.');
   if l_new_parts.count != 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_new_location_level_id,
         'Location Level ID');
   end if;
   -------------------------------
   -- get the codes for the ids --
   -------------------------------
   begin
      select pl.location_code
        into l_old_location_code
        from at_physical_location pl,
             at_base_location bl
       where bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = cwms_util.get_base_id(upper(l_old_parts(1)))
         and upper(nvl(pl.sub_location_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_old_parts(1))), '.') 
         and bl.db_office_code = l_office_code;
         
      select p.parameter_code
        into l_old_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where bp.base_parameter_code = p.base_parameter_code
         and upper(bp.base_parameter_id) = cwms_util.get_base_id(upper(l_old_parts(2)))
         and upper(nvl(p.sub_parameter_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_old_parts(2))), '.') 
         and p.db_office_code in (l_office_code, cwms_util.db_office_code_all);

      select parameter_type_code
        into l_old_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_old_parts(3));

      select duration_code
        into l_old_duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_old_parts(4));

      select specified_level_code
        into l_old_specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(l_old_parts(5))
         and office_code in(l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_old_location_level_id,
            'Location Level ID');
   end;
   begin
      select pl.location_code
        into l_new_location_code
        from at_physical_location pl,
             at_base_location bl
       where bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = cwms_util.get_base_id(upper(l_new_parts(1)))
         and upper(nvl(pl.sub_location_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_new_parts(1))), '.') 
         and bl.db_office_code = l_office_code;
         
      select p.parameter_code
        into l_new_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where bp.base_parameter_code = p.base_parameter_code
         and upper(bp.base_parameter_id) = cwms_util.get_base_id(upper(l_new_parts(2)))
         and upper(nvl(p.sub_parameter_id, '.')) = nvl(cwms_util.get_sub_id(upper(l_new_parts(2))), '.') 
         and p.db_office_code in (l_office_code, cwms_util.db_office_code_all);

      select parameter_type_code
        into l_new_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_new_parts(3));

      select duration_code
        into l_new_duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_new_parts(4));

      select specified_level_code
        into l_new_specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(l_new_parts(5))
         and office_code in(l_office_code, cwms_util.db_office_code_all);
   exception
      when no_data_found then
         cwms_err.raise(
            'INVALID_ITEM',
            p_new_location_level_id,
            'Location Level ID');
   end;
   ----------------------        
   -- update the table --
   ----------------------
   update at_location_level
      set location_code        = l_new_location_code,
          parameter_code       = l_new_parameter_code,        
          parameter_type_code  = l_new_parameter_type_code,        
          duration_code        = l_new_duration_code,        
          specified_level_code = l_new_specified_level_code
    where location_code        = l_old_location_code
      and parameter_code       = l_old_parameter_code        
      and parameter_type_code  = l_old_parameter_type_code        
      and duration_code        = l_old_duration_code        
      and specified_level_code = l_old_specified_level_code;
                
end rename_location_level;   


procedure delete_location_level(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null)
is          
begin
   delete_location_level_ex(
      p_location_level_id,
      p_effective_date,
      p_timezone_id,
      p_attribute_id,
      p_attribute_value,
      p_attribute_units,
      p_cascade,
      'F',
      p_office_id);
end delete_location_level;

procedure delete_location_level(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default ('F'))
is
begin
   delete_location_level_ex(
      p_location_level_code,
      p_cascade,
      'F');
end delete_location_level;   

procedure delete_location_level_ex(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_delete_indicators       in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null)
is
   l_location_level_code       number(10);
   l_location_id               varchar2(49);
   l_parameter_id              varchar2(49);
   l_parameter_type_id         varchar2(16);
   l_duration_id               varchar2(16);
   l_spec_level_id             varchar2(256);
   l_date                      date;
   l_attribute_parameter_id    varchar2(49);
   l_attribute_param_type_id   varchar2(16);
   l_attribute_duration_id     varchar2(16); 
begin
   l_date := cast(
      from_tz(cast(p_effective_date as timestamp), p_timezone_id)
      at time zone 'UTC' as date);
   -----------------------------
   -- verify the level exists --
   -----------------------------
   parse_location_level_id(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      p_location_level_id);
   parse_attribute_id(
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_attribute_id);
   l_location_level_code := get_location_level_code(
      l_location_id,
      l_parameter_id,
      l_parameter_type_id,
      l_duration_id,
      l_spec_level_id,
      l_date,
      true,
      p_attribute_value,
      p_attribute_units,
      l_attribute_parameter_id,
      l_attribute_param_type_id,
      l_attribute_duration_id,
      p_office_id);

   if l_location_level_code is null then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Location level',
         nvl(p_office_id, cwms_util.user_office_id)
         || '/' || p_location_level_id
         || case
               when p_attribute_value is null then
                  null
               else
                  ' (' || p_attribute_value || ' ' || p_attribute_units || ')'
            end
         || '@' || p_effective_date);
   end if;
          
   delete_location_level_ex(
      l_location_level_code,
      p_cascade,
      p_delete_indicators);
        
end delete_location_level_ex;

procedure delete_location_level_ex(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default ('F'),
   p_delete_indicators   in  varchar2 default ('F'))
is
   l_location_code             number(10);
   l_parameter_type_code       number(10);
   l_duration_code             number(10);
   l_specified_level_code      number(10);
   l_attribute_parameter_code  number(10);
   l_attribute_param_type_code number(10);
   l_attribute_duration_code   number(10);
   l_attribute_value           number;
   l_cascade                   boolean := cwms_util.return_true_or_false(p_cascade);
   l_delete_indicators         boolean := cwms_util.return_true_or_false(p_delete_indicators);
   l_seasonal_count            pls_integer;
   l_level_count               pls_integer;
   l_indicator_count           pls_integer;
   l_parameter_code            number(10);
begin
   ----------------------------------------------------
   -- check for seasonal records and p_cascase = 'F' --
   ----------------------------------------------------
   select count(*)
     into l_seasonal_count
     from at_seasonal_location_level
    where location_level_code = p_location_level_code;
   if l_seasonal_count > 0 and not l_cascade then
      declare
         ll location_level_t := location_level_t(zlocation_level_t(p_location_level_code));
      begin
         cwms_err.raise(
            'ERROR',
            'Cannot delete location level '
            ||ll.office_id || '/'
            ||ll.location_id || '.'
            ||ll.parameter_id || '.'
            ||ll.parameter_type_id || '.'
            ||ll.duration_id || '.'
            ||ll.specified_level_id
            || case
                  when ll.attribute_value is null then
                     null
                  else
                     ' ('||ll.attribute_value || ' ' || ll.attribute_units_id || ')'
               end
            || '@' || ll.level_date
            || ' with p_cascade = ''F''');
      end;
   end if;
   ------------------------------------------------------------------------------------    
   -- check for indicators and p_delete_indicators = 'F' and no more matching levels --
   ------------------------------------------------------------------------------------    
   select location_code,
          parameter_code,
          parameter_type_code,
          duration_code,
          specified_level_code,
          attribute_parameter_code,
          attribute_parameter_type_code,
          attribute_duration_code,
          attribute_value
     into l_location_code,
          l_parameter_code,
          l_parameter_type_code,
          l_duration_code,
          l_specified_level_code,
          l_attribute_parameter_code,
          l_attribute_param_type_code,
          l_attribute_duration_code,
          l_attribute_value
     from at_location_level            
    where location_level_code = p_location_level_code;
    
   select count(*)
     into l_level_count
     from at_location_level
    where location_code = l_location_code
      and parameter_code = l_parameter_code
      and parameter_type_code = l_parameter_type_code
      and specified_level_code = l_specified_level_code
      and nvl(attribute_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
      and nvl(attribute_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
      and nvl(attribute_duration_code, -1) = nvl(l_attribute_duration_code, -1)
      and nvl(cwms_rounding.round_dt_f(attribute_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@');
   if l_level_count > 1 then
      l_indicator_count := 0;
   else
      select count(*)
        into l_indicator_count
        from at_loc_lvl_indicator
       where location_code = l_location_code
         and parameter_code = l_parameter_code
         and parameter_type_code = l_parameter_type_code
         and specified_level_code = l_specified_level_code
         and nvl(attr_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
         and nvl(attr_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
         and nvl(attr_duration_code, -1) = nvl(l_attribute_duration_code, -1)
         and nvl(cwms_rounding.round_nt_f(attr_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@');          
   end if;                
   if l_indicator_count > 0 and not l_delete_indicators then
      declare
         ll location_level_t := location_level_t(zlocation_level_t(p_location_level_code));
      begin
         cwms_err.raise(
            'ERROR',
            'Cannot delete location level '
            ||ll.office_id || '/'
            ||ll.location_id || '.'
            ||ll.parameter_id || '.'
            ||ll.parameter_type_id || '.'
            ||ll.duration_id || '.'
            ||ll.specified_level_id
            || case
                  when ll.attribute_value is null then
                     null
                  else
                     ' ('||ll.attribute_value || ' ' || ll.attribute_units_id || ')'
               end
            || '@' || ll.level_date
            || ' with p_delete_indicators = ''F''');
      end;
   end if;    
   ---------------------------------
   -- delete any seasonal records --
   ---------------------------------
   if l_seasonal_count > 0 then
      delete
        from at_seasonal_location_level
       where location_level_code = p_location_level_code;
   end if;
   --------------------------------------    
   -- delete any associated indicators --
   --------------------------------------
   if l_indicator_count > 0 then
      begin
         select location_code,
                parameter_code,
                parameter_type_code,
                duration_code,
                specified_level_code,
                attribute_parameter_code,
                attribute_parameter_type_code,
                attribute_duration_code,
                attribute_value
           into l_location_code,
                l_parameter_code,
                l_parameter_type_code,
                l_duration_code,
                l_specified_level_code,
                l_attribute_parameter_code,
                l_attribute_param_type_code,
                l_attribute_duration_code,
                l_attribute_value
           from at_location_level           
          where location_level_code = p_location_level_code;
         delete
           from at_loc_lvl_indicator_cond
          where level_indicator_code in 
                (  select level_indicator_code
                     from at_loc_lvl_indicator
                    where location_code = l_location_code
                      and parameter_code = l_parameter_code
                      and parameter_type_code = l_parameter_type_code
                      and specified_level_code = l_specified_level_code
                      and nvl(attr_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
                      and nvl(attr_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
                      and nvl(attr_duration_code, -1) = nvl(l_attribute_duration_code, -1)
                      and nvl(cwms_rounding.round_dt_f(attr_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@')
                );
         delete
           from at_loc_lvl_indicator
          where location_code = l_location_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and specified_level_code = l_specified_level_code
            and nvl(attr_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
            and nvl(attr_duration_code, -1) = nvl(l_attribute_duration_code, -1)
            and nvl(cwms_rounding.round_nt_f(attr_value, '9999999999'), '@') = nvl(cwms_rounding.round_nt_f(l_attribute_value, '9999999999'), '@');          
      exception
         when no_data_found then null;
      end;
   end if;
   -------------------------------
   -- delete the location level --
   -------------------------------
   delete
     from at_location_level
    where location_level_code = p_location_level_code;
end delete_location_level_ex;   

            
--------------------------------------------------------------------------------
-- PROCEDURE cat_location_levels
--
-- in this procedure SQL- (%, _) or glob-style (*, ?) wildcards can be used
-- in masks, and all masks are case insensitive
--
-- muilt-part masks need not specify all the parts if a partial mask will match
-- all desired results 
--
-- p_cursor
--   the cursor that is opened by this procedure. it must be manually closed
--   after use.
--
-- p_location_level_id_mask
--   a wildcard mask of the five-part location level identifier.  defaults
--   to matching every location level identifier
--
-- p_attribute_id_mask
--   a wildcard mask of the three-part attribute identifier.  null attribute
--   identifiers are matched by '*' (or '%'), to match ONLY null attributes, 
--   specify null for this parameter.  defaults to matching all attribute
--   identifiers
--
-- p_office_id_mask
--   a wildcard mask of the office identifier that owns the location levels.
--   specify '*' (or '%') for this parameter to match every office identifier.
--   defaults to matching only the calling user's office identifier
--
-- p_timezone_id
--   the time zone in which location level dates are to be represented in the
--   cursor opened by this procedure.  defaults to 'UTC'
--
-- p_unit_system
--   the unit system in which the attribute values are to be represented in the
--   cursor opened by this procedure.  The actual units will be determined by
--   the entry in the AT_DISPLAY_UNITS table for the office that owns the 
--   location level and the attribute parameter. defaults to SI
--
-- The cursor opened by this routine contains six fields:
--    1 : office_id           varchar2(16)
--    2 : location_level_id   varchar2(390)
--    3 : attribute_id        varchar2(83)
--    4 : attribute_value     binary_double
--    5 : attribute_unit      varchar2(16)
--    6 : location_level_date date
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure cat_location_levels(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2 default '*',
   p_attribute_id_mask      in  varchar2 default '*',
   p_office_id_mask         in  varchar2 default null,
   p_timezone_id            in  varchar2 default 'UTC',
   p_unit_system            in  varchar2 default 'SI')
is          
   l_parts                    str_tab_t;
   l_count                    binary_integer;
   l_office_id_mask           varchar2(16);
   l_location_mask            varchar2(49);
   l_parameter_mask           varchar2(49);
   l_parameter_type_mask      varchar2(16);
   l_duration_mask            varchar2(16);
   l_specified_level_mask     varchar2(256);
   l_attr_parameter_mask      varchar2(49);
   l_attr_parameter_type_mask varchar2(16);
   l_attr_duration_mask       varchar2(16);
   l_query_str                varchar2(32767);
begin       
   -------------------------------------------------------
   -- process the office id mask (NULL = user's office) --
   -------------------------------------------------------
   l_office_id_mask := cwms_util.normalize_wildcards(upper(p_office_id_mask));
   if l_office_id_mask is null then
      l_office_id_mask := cwms_util.user_office_id;
   end if;  
   ---------------------------------------------------------------
   -- process the location level id mask into constituent parts --
   ---------------------------------------------------------------
   l_parts := cwms_util.split_text(p_location_level_id_mask, '.');
   l_count := l_parts.count;
   if l_count < 5 then
      l_parts.extend(5 - l_count);
      for i in l_count+1..5 loop
         l_parts(i) := '*';
      end loop;
   elsif l_parts.count > 5 then
      cwms_err.raise(
         'INVALID_ITEM',
         p_location_level_id_mask,
         'location level identifier mask (too many parts).');
   end if;  
   l_location_mask        := cwms_util.normalize_wildcards(upper(l_parts(1)));
   l_parameter_mask       := cwms_util.normalize_wildcards(upper(l_parts(2)));
   l_parameter_type_mask  := cwms_util.normalize_wildcards(upper(l_parts(3)));
   l_duration_mask        := cwms_util.normalize_wildcards(upper(l_parts(4)));
   l_specified_level_mask := cwms_util.normalize_wildcards(upper(l_parts(5)));
   ----------------------------------------------------------
   -- process the attribute id mask into constituent parts --
   ----------------------------------------------------------
   if p_attribute_id_mask is not null then
      l_parts := cwms_util.split_text(p_attribute_id_mask, '.');
      l_count := l_parts.count;
      if l_count < 3 then
         l_parts.extend(3 - l_count);
         for i in l_count+1..3 loop
            l_parts(i) := '*';
         end loop;
      elsif l_count > 3 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_attribute_id_mask,
            'attribute identifier mask (too many parts).');
      end if;  
      l_attr_parameter_mask      := cwms_util.normalize_wildcards(upper(l_parts(1)));
      l_attr_parameter_type_mask := cwms_util.normalize_wildcards(upper(l_parts(2)));
      l_attr_duration_mask       := cwms_util.normalize_wildcards(upper(l_parts(3)));
   end if;
   ---------------------
   -- build the query --
   ---------------------
   l_query_str :=    
     'select office_id,
             location_level_id,
             attribute_parameter_id
             || substr(''.'', 1, length(attribute_parameter_type_id))
             || attribute_parameter_type_id
             || substr(''.'', 1, length(attribute_duration_id))
             ||attribute_duration_id as attribute_parameter_type_id,
             cwms_rounding.round_f(
                case
                when attr_base_parameter_id =  ''Elev'' then
                   attribute_value * factor + offset + cwms_loc.get_vertical_datum_offset(location_code, attribute_unit_id)
                else
                   attribute_value * factor + offset
                end, 9) as attribute_value,
             attribute_unit_id,
             cwms_util.change_timezone(location_level_date, ''UTC'', :p_timezone_id)
        from (  (  select o.office_code as office_code1,
                          o.office_id as office_id,
                          pl.location_code,
                          bl.base_location_id
                          || substr(''-'', 1, length(pl.sub_location_id))
                          || pl.sub_location_id
                          || ''.''
                          || bp1.base_parameter_id
                          || substr(''-'', 1, length(p1.sub_parameter_id))
                          || p1.sub_parameter_id
                          || ''.''
                          || pt1.parameter_type_id
                          || ''.''
                          || d1.duration_id
                          || ''.''
                          || sl.specified_level_id as location_level_id,
                          ll.attribute_parameter_code as attr_parameter_code1,
                          ll.attribute_parameter_type_code as attr_parameter_type_code1,
                          ll.attribute_duration_code as attr_duration_code1,
                          ll.attribute_value,
                          ll.location_level_date
                     from at_location_level ll,
                          at_physical_location pl,
                          at_base_location bl,
                          cwms_office o,
                          cwms_base_parameter bp1,
                          at_parameter p1,
                          cwms_parameter_type pt1,
                          cwms_duration d1,
                          at_specified_level sl
                    where pl.location_code = ll.location_code
                      and bl.base_location_code = pl.base_location_code
                      and o.office_code = bl.db_office_code
                      and upper(o.office_id) like :l_office_id_mask escape ''\''
                      and upper(bl.base_location_id
                          || substr(''-'', 1, length(pl.sub_location_id))
                          || pl.sub_location_id) like :l_location_mask escape ''\''
                      and p1.parameter_code = ll.parameter_code
                      and bp1.base_parameter_code = p1.base_parameter_code
                      and upper(bp1.base_parameter_id
                          || substr(''-'', 1, length(p1.sub_parameter_id))
                          || p1.sub_parameter_id) like :l_parameter_mask escape ''\''
                      and pt1.parameter_type_code = ll.parameter_type_code
                      and upper(pt1.parameter_type_id) like :l_parameter_type_mask escape ''\''
                      and d1.duration_code = ll.duration_code
                      and upper(d1.duration_id) like :l_duration_mask escape ''\''
                      and sl.specified_level_code = ll.specified_level_code
                      and upper(sl.specified_level_id) like :l_specified_level_mask escape ''\''
                          -- the next clause evaluates to false only when the 
                          -- attribute mask is null and the attribute code is non-null
                          -- (thus it filters out all levels with an attribute when
                          -- the attribute_mask is null)
                      and nvl(ll.attribute_parameter_code, -1) = 
                          decode(nvl(:l_attr_parameter_mask, ''.''), ''.'', -1, nvl(ll.attribute_parameter_code, -1))
                )
                left outer join
                (  select p2.parameter_code as attr_parameter_code2,
                          bp2.base_parameter_id as attr_base_parameter_id,
                          bp2.base_parameter_id
                          || substr(''-'', 1, length(p2.sub_parameter_id))
                          || p2.sub_parameter_id as attribute_parameter_id,
                          pt2.parameter_type_code as attr_parameter_type_code2,
                          pt2.parameter_type_id as attribute_parameter_type_id,
                          du.db_office_code as office_code2,
                          cu.to_unit_id as attribute_unit_id,
                          d2.duration_code as attr_duration_code2,
                          d2.duration_id as attribute_duration_id,
                          cu.factor as factor,
                          cu.offset as offset
                     from cwms_base_parameter bp2,
                          at_parameter p2,
                          cwms_parameter_type pt2,
                          cwms_duration d2,
                          at_display_units du,
                          cwms_unit_conversion cu
                    where bp2.base_parameter_code = p2.base_parameter_code
                      and upper(bp2.base_parameter_id
                          || substr(''-'', 1, length(p2.sub_parameter_id))
                          || p2.sub_parameter_id) like :l_attr_parameter_mask escape ''\''
                      and upper(pt2.parameter_type_id) like :l_attr_parameter_type_mask escape ''\''
                      and upper(d2.duration_id) like :l_attr_duration_mask escape ''\''
                      and du.parameter_code = p2.parameter_code
                      and du.unit_system = :p_unit_system
                      and cu.from_unit_code = bp2.unit_code
                      and cu.to_unit_code = du.display_unit_code
                ) on attr_parameter_code2 = attr_parameter_code1
                 and attr_parameter_type_code2 = attr_parameter_type_code1 
                 and attr_duration_code2 = attr_duration_code1
                 and office_code2 = office_code1
             )';
   ------------------------------------------------------------              
   -- change the outer join to an inner join if we specify a --
   -- non-null attribute mask that doesn't match everything  --
   -- (null attribute masks are handled in the decode(...)   --
   ------------------------------------------------------------              
   if l_attr_parameter_mask      != '%' or 
      l_attr_parameter_type_mask != '%' or 
      l_attr_duration_mask       != '%'
   then
      l_query_str := replace(l_query_str, 'left outer join', 'inner join');
   end if;
   --------------------------
   -- retrieve the catalog --
   --------------------------
   open p_cursor 
    for l_query_str 
  using p_timezone_id,
        l_office_id_mask,
        l_location_mask,
        l_parameter_mask,
        l_parameter_type_mask,
        l_duration_mask,
        l_specified_level_mask,
        l_attr_parameter_mask,
        l_attr_parameter_mask,
        l_attr_parameter_type_mask,
        l_attr_duration_mask,
        p_unit_system;

end cat_location_levels;
            
--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_code
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_code(
   p_location_id            in  varchar2,
   p_parameter_id           in  varchar2,
   p_parameter_type_id      in  varchar2,
   p_duration_id            in  varchar2,
   p_specified_level_id     in  varchar2,
   p_level_indicator_id     in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_parameter_id      in  varchar2 default null,
   p_attr_parameter_type_id in  varchar2 default null,
   p_attr_duration_id       in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return number
is          
   l_location_code            number(10);
   l_parameter_code           number(10);
   l_parameter_type_code      number(10);
   l_duration_code            number(10);
   l_specified_level_code     number(10);
   l_level_indicator_code     number(10);
   l_attr_parameter_code      number(10);
   l_attr_parameter_type_code number(10);
   l_attr_duration_code       number(10);
   l_ref_specified_level_code number(10);
   l_office_code              number(10) := cwms_util.get_office_code(upper(p_office_id));
   l_cwms_office_code         number(10) := cwms_util.get_office_code('CWMS');
   l_loc_lvl_indicator_code   number(10);
   l_factor                   number := 1.;
   l_offset                   number := 0.;
   l_has_attribute            boolean;
   l_attr_value               number;
   l_ref_attr_value           number;
begin       
   -------------------
   -- sanity checks --
   -------------------
   if p_attr_value             is null or
      p_attr_units_id          is null or
      p_attr_parameter_id      is null or
      p_attr_parameter_type_id is null or
      p_attr_duration_id       is null
   then     
      if p_attr_value             is not null or
         p_attr_units_id          is not null or
         p_attr_parameter_id      is not null or
         p_attr_parameter_type_id is not null or
         p_attr_duration_id       is not null
      then  
         cwms_err.raise(
            'ERROR',
            'Attribute parameters must either all be null or all be non-null.');
      else  
         l_has_attribute := false;            
      end if;
   else     
      l_has_attribute := true;            
   end if;      
   if p_ref_specified_level_id is null
      and p_ref_attr_value     is not null
   then      
      cwms_err.raise(
         'ERROR',
         'Cannot have a reference attribute without a reference specified level.');
   end if;  
   -----------------------------     
   -- get the component codes --
   -----------------------------     
   begin    
      select pl.location_code
        into l_location_code
        from at_physical_location pl,
             at_base_location bl
       where BL.DB_OFFICE_CODE = l_office_code
         and upper(BL.BASE_LOCATION_ID) = upper(cwms_util.get_base_id(p_location_id))
         and pl.base_location_code = bl.base_location_code
         and upper(nvl(pl.sub_location_id, '-')) = upper(nvl(cwms_util.get_sub_id(p_location_id), '-'));
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location',
            p_location_id);
   end;     
   begin    
      select p.parameter_code
        into l_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(p_parameter_id))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '-')) = upper(nvl(cwms_util.get_sub_id(p_parameter_id), '-'))
         and p.db_office_code in (l_office_code, l_cwms_office_code);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Parameter',
            p_parameter_id);
   end;     
   begin    
      select parameter_type_code
        into l_parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(p_parameter_type_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Parameter type',
            p_parameter_type_id);
   end;               
   begin    
      select duration_code
        into l_duration_code
        from cwms_duration
       where upper(duration_id) = upper(p_duration_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Duration',
            p_duration_id);
   end;               
   begin    
      select specified_level_code
        into l_specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(p_specified_level_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Specified level',
            p_specified_level_id);
   end;     
   if l_has_attribute then
      begin 
         select p.parameter_code
           into l_attr_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(p_attr_parameter_id))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '-')) = upper(nvl(cwms_util.get_sub_id(p_attr_parameter_id), '-'))
            and p.db_office_code in (l_office_code, l_cwms_office_code);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Parameter',
               p_attr_parameter_id);
      end;  
      begin 
         select parameter_type_code
           into l_attr_parameter_type_code
           from cwms_parameter_type
          where upper(parameter_type_id) = upper(p_attr_parameter_type_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Parameter type',
               p_attr_parameter_type_id);
      end;               
      begin 
         select duration_code
           into l_attr_duration_code
           from cwms_duration
          where upper(duration_id) = upper(p_attr_duration_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Duration',
               p_attr_duration_id);
      end;  
      select factor,
             offset
        into l_factor,
             l_offset
        from cwms_unit_conversion
       where from_unit_id = p_attr_units_id
         and to_unit_id = cwms_util.get_default_units(p_attr_parameter_id);                
   end if;  
   if p_ref_specified_level_id is not null then
      begin 
         select specified_level_code
           into l_ref_specified_level_code
           from at_specified_level
          where upper(specified_level_id) = upper(p_ref_specified_level_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Specified level',
               p_ref_specified_level_id);
      end;  
   end if;  
   ------------------------------------               
   -- get the loc_lvl_indicator code --
   ------------------------------------
   if p_attr_value is not null then
      if instr(upper(p_attr_parameter_id), 'ELEV') = 1 then
         l_attr_value := cwms_rounding.round_f(p_attr_value * l_factor + l_offset - cwms_loc.get_vertical_datum_offset(l_location_code, p_attr_units_id), 12);
      else
         l_attr_value := cwms_rounding.round_f(p_attr_value * l_factor + l_offset, 12);
      end if;
   end if;  
   if p_ref_attr_value is not null then
      l_ref_attr_value := cwms_rounding.round_f(p_ref_attr_value * l_factor + l_offset, 12);
   end if;  
   begin    
      select level_indicator_code
        into l_loc_lvl_indicator_code
        from at_loc_lvl_indicator
       where location_code = l_location_code
         and parameter_code = l_parameter_code
         and parameter_type_code = l_parameter_type_code
         and duration_code = l_duration_code
         and specified_level_code = l_specified_level_code
         and nvl(to_char(attr_value), '@') = nvl(to_char(l_attr_value), '@')
         and nvl(attr_parameter_code, -1) = nvl(l_attr_parameter_code, -1)
         and nvl(attr_parameter_type_code, -1) = nvl(l_attr_parameter_type_code, -1)
         and nvl(attr_duration_code, -1) = nvl(l_attr_duration_code, -1)
         and nvl(to_char(ref_attr_value), '@') = nvl(to_char(l_ref_attr_value), '@')
         and nvl(ref_specified_level_code, -1) = nvl(l_ref_specified_level_code, -1)
         and level_indicator_id = upper(p_level_indicator_id);
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'Location level indicator',
            null);
   end;     
   return l_loc_lvl_indicator_code;               
end get_loc_lvl_indicator_code;   
            
--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_code
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_code(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return number
is          
   ITEM_DOES_NOT_EXIST      exception; pragma exception_init (ITEM_DOES_NOT_EXIST, -20034);
   l_location_id            varchar2(49);
   l_parameter_id           varchar2(49);
   l_param_type_id          varchar2(16);
   l_duration_id            varchar2(16);
   l_specified_level_id     varchar2(256);
   l_level_indicator_id     varchar2(32);
   l_attr_parameter_id      varchar2(49);
   l_attr_param_type_id     varchar2(16);
   l_attr_duration_id       varchar2(16);
   l_loc_lvl_indicator_code number(10);
begin       
   cwms_level.parse_loc_lvl_indicator_id(
      l_location_id,
      l_parameter_id,
      l_param_type_id,
      l_duration_id,
      l_specified_level_id,
      l_level_indicator_id,
      p_loc_lvl_indicator_id);
            
   cwms_level.parse_attribute_id(
      l_attr_parameter_id,
      l_attr_param_type_id,
      l_attr_duration_id,
      p_attr_id);
            
   begin    
      l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
         l_location_id,
         l_parameter_id,
         l_param_type_id,
         l_duration_id,
         l_specified_level_id,
         l_level_indicator_id,
         p_attr_value,
         p_attr_units_id,
         l_attr_parameter_id,
         l_attr_param_type_id,
         l_attr_duration_id,
         p_ref_specified_level_id,
         p_ref_attr_value,
         p_office_id);
            
      return l_loc_lvl_indicator_code;      
   exception
      when ITEM_DOES_NOT_EXIST then
         declare
            l_location_level_text varchar2(4000);
         begin
            l_location_level_text := p_loc_lvl_indicator_id;
            if p_attr_id is not null then
               l_location_level_text := l_location_level_text
                  || ' (attribute '
                  || p_attr_id
                  || ' = '
                  || p_attr_value
                  || ' '
                  || p_attr_units_id
                  ||')';
            end if;
            if p_ref_specified_level_id is not null then
               l_location_level_text := l_location_level_text
                  || ' (reference = '
                  || p_ref_specified_level_id;
               if p_ref_attr_value is not null then
                  l_location_level_text := l_location_level_text
                     || ' (attribute '
                     || p_attr_id
                     || ' = '
                     || p_ref_attr_value
                     || ' '
                     || p_attr_units_id
                     || ')';
               end if;                  
               l_location_level_text := l_location_level_text || ')';
            end if;
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Location Level Indicator',
               l_location_level_text);
         end;
   end;      
end get_loc_lvl_indicator_code;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_cond
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_cond(
   p_level_indicator_code        in number,
   p_level_indicator_value       in number,
   p_expression                  in varchar2,
   p_comparison_operator_1       in varchar2,
   p_comparison_value_1          in binary_double,
   p_comparison_unit_code        in number                 default null,
   p_connector                   in varchar2               default null, 
   p_comparison_operator_2       in varchar2               default null,
   p_comparison_value_2          in binary_double          default null,
   p_rate_expression             in varchar2               default null,
   p_rate_comparison_operator_1  in varchar2               default null,
   p_rate_comparison_value_1     in binary_double          default null,
   p_rate_comparison_unit_code   in number                 default null,
   p_rate_connector              in varchar2               default null, 
   p_rate_comparison_operator_2  in varchar2               default null,
   p_rate_comparison_value_2     in binary_double          default null,
   p_rate_interval               in dsinterval_unconstrained default null,
   p_description                 in varchar2               default null,
   p_fail_if_exists              in varchar2               default 'F',
   p_ignore_nulls_on_update      in varchar2               default 'T')
is          
   l_fail_if_exists         boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls_on_update boolean := cwms_util.return_true_or_false(p_ignore_nulls_on_update);
   l_exists                 boolean := true;
   l_rec                    at_loc_lvl_indicator_cond%rowtype;
   l_unit_code              number(10);
   l_na_unit_code           number(10);
   l_from_unit_id           varchar2(16);
   l_to_unit_id             varchar2(16);
begin       
   begin    
      select *
        into l_rec
        from at_loc_lvl_indicator_cond
       where level_indicator_code = p_level_indicator_code
         and level_indicator_value = p_level_indicator_value;
   exception
      when no_data_found then
         l_exists := false;
   end;     
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Location level indicator condition',
         null);
   end if;  
   if l_exists and l_ignore_nulls_on_update then
      l_rec.expression                 := nvl(upper(trim(p_expression)), l_rec.expression);
      l_rec.comparison_operator_1      := nvl(upper(trim(p_comparison_operator_1)), l_rec.comparison_operator_1);
      l_rec.comparison_value_1         := nvl(p_comparison_value_1, l_rec.comparison_value_1);
      l_rec.comparison_unit            := nvl(trim(p_comparison_unit_code), l_rec.comparison_unit);
      l_rec.connector                  := nvl(upper(trim(p_connector)), l_rec.connector);
      l_rec.comparison_operator_2      := nvl(upper(trim(p_comparison_operator_2)), l_rec.comparison_operator_2);
      l_rec.comparison_value_2         := nvl(p_comparison_value_2, l_rec.comparison_value_2);
      l_rec.rate_expression            := nvl(upper(trim(p_rate_expression)), l_rec.rate_expression);
      l_rec.rate_comparison_operator_1 := nvl(upper(trim(p_rate_comparison_operator_1)), l_rec.rate_comparison_operator_1);
      l_rec.rate_comparison_value_1    := nvl(p_rate_comparison_value_1, l_rec.rate_comparison_value_1);
      l_rec.rate_comparison_unit       := nvl(trim(p_rate_comparison_unit_code), l_rec.rate_comparison_unit);
      l_rec.rate_connector             := nvl(upper(trim(p_rate_connector)), l_rec.rate_connector);
      l_rec.rate_comparison_operator_2 := nvl(upper(trim(p_rate_comparison_operator_2)), l_rec.rate_comparison_operator_2);
      l_rec.rate_comparison_value_2    := nvl(p_rate_comparison_value_2, l_rec.rate_comparison_value_2);
      l_rec.rate_interval              := nvl(p_rate_interval, l_rec.rate_interval);
      l_rec.description                := nvl(trim(p_description), l_rec.description);
   else     
      l_rec.level_indicator_value      := p_level_indicator_value;
      l_rec.expression                 := p_expression;
      l_rec.comparison_operator_1      := p_comparison_operator_1;
      l_rec.comparison_value_1         := p_comparison_value_1;
      l_rec.comparison_unit            := p_comparison_unit_code;
      l_rec.connector                  := p_connector;
      l_rec.comparison_operator_2      := p_comparison_operator_2;
      l_rec.comparison_value_2         := p_comparison_value_2;
      l_rec.rate_expression            := p_rate_expression;
      l_rec.rate_comparison_operator_1 := p_rate_comparison_operator_1;
      l_rec.rate_comparison_value_1    := p_rate_comparison_value_1;
      l_rec.rate_comparison_unit       := p_rate_comparison_unit_code;
      l_rec.rate_connector             := p_rate_connector;
      l_rec.rate_comparison_operator_2 := p_rate_comparison_operator_2;
      l_rec.rate_comparison_value_2    := p_rate_comparison_value_2;
      l_rec.rate_interval              := p_rate_interval;
      l_rec.description                := p_description;
   end if;  
   l_rec.level_indicator_code := p_level_indicator_code;
   --------------------------------------
   -- sanity check on comparison units --
   --------------------------------------
   select unit_code
     into l_na_unit_code
     from cwms_unit
    where unit_id = 'n/a';
   if l_rec.comparison_unit is not null and l_rec.comparison_unit != l_na_unit_code then
      begin 
         select uc.from_unit_id,
                uc.to_unit_id
           into l_from_unit_id,
                l_to_unit_id
           from at_loc_lvl_indicator lli,
                at_parameter p,
                cwms_base_parameter bp,
                cwms_unit_conversion uc
          where lli.level_indicator_code = l_rec.level_indicator_code
            and p.parameter_code = lli.parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and uc.from_unit_code = bp.unit_code
            and uc.to_unit_code = l_rec.comparison_unit;
      exception
         when no_data_found then
            select u.unit_id
              into l_from_unit_id
              from at_loc_lvl_indicator lli,
                   at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit u
             where lli.level_indicator_code = l_rec.level_indicator_code
               and p.parameter_code = lli.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and u.unit_code = bp.unit_code;
            select unit_id 
              into l_to_unit_id 
              from cwms_unit 
             where unit_code = l_rec.comparison_unit;
         cwms_err.raise(
            'ERROR',
            'Cannot convert from database unit ('
            || l_from_unit_id
            ||') to comparison unit ('
            || l_to_unit_id
            || ')');             
      end;  
   end if;  
   -------------------------------------------
   -- sanity check on rate comparison units --
   -------------------------------------------
   if l_rec.rate_comparison_unit is not null then
      begin 
         select uc.from_unit_id,
                uc.to_unit_id
           into l_from_unit_id,
                l_to_unit_id
           from at_loc_lvl_indicator lli,
                at_parameter p,
                cwms_base_parameter bp,
                cwms_unit_conversion uc
          where lli.level_indicator_code = l_rec.level_indicator_code
            and p.parameter_code = lli.parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and uc.from_unit_code = bp.unit_code
            and uc.to_unit_code = l_rec.rate_comparison_unit;
      exception
         when no_data_found then
            select u.unit_id
              into l_from_unit_id
              from at_loc_lvl_indicator lli,
                   at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit u
             where lli.level_indicator_code = l_rec.level_indicator_code
               and p.parameter_code = lli.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and u.unit_code = bp.unit_code;
            select unit_id 
              into l_to_unit_id 
              from cwms_unit 
             where unit_code = l_rec.rate_comparison_unit;
         cwms_err.raise(
            'ERROR',
            'Cannot convert from database unit ('
            || l_from_unit_id
            ||') to rate comparison unit ('
            || l_to_unit_id
            || ')');             
      end;  
   end if;  
   ---------------------------------------
   -- insert or update condition record --
   ---------------------------------------
   if l_exists then
      update at_loc_lvl_indicator_cond
         set row = l_rec
       where level_indicator_code = l_rec.level_indicator_code
         and level_indicator_value = l_rec.level_indicator_value;
   else     
      insert into at_loc_lvl_indicator_cond values l_rec;
   end if;  
end store_loc_lvl_indicator_cond;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_cond
--          
-- Creates or updates a Location Level Indicator Condition in the database
--          
-- p_rate_interval is specified as 'ddd hh:mm:ss'
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_cond(
   p_loc_lvl_indicator_id        in varchar2,
   p_level_indicator_value       in number,
   p_expression                  in varchar2,
   p_comparison_operator_1       in varchar2,
   p_comparison_value_1          in number,
   p_comparison_unit_id          in varchar2 default null,
   p_connector                   in varchar2 default null, 
   p_comparison_operator_2       in varchar2 default null,
   p_comparison_value_2          in number   default null,
   p_rate_expression             in varchar2 default null,
   p_rate_comparison_operator_1  in varchar2 default null,
   p_rate_comparison_value_1     in number   default null,
   p_rate_comparison_unit_id     in varchar2 default null,
   p_rate_connector              in varchar2 default null, 
   p_rate_comparison_operator_2  in varchar2 default null,
   p_rate_comparison_value_2     in number   default null,
   p_rate_interval               in varchar2 default null,
   p_description                 in varchar2 default null,
   p_attr_value                  in number   default null,
   p_attr_units_id               in varchar2 default null,
   p_attr_id                     in varchar2 default null,
   p_ref_specified_level_id      in varchar2 default null,
   p_ref_attr_value              in number   default null,
   p_fail_if_exists              in varchar2 default 'F',
   p_ignore_nulls_on_update      in varchar2 default 'T',
   p_office_id                   in varchar2 default null)
is          
   l_unit_code               number(10);
   l_rate_unit_code          number(10);
   l_loc_lvl_indicator_code  number(10);
   l_rate_interval           interval day(3) to second(0);
begin       
   if p_comparison_unit_id is not null then
      select unit_code
        into l_unit_code
        from cwms_unit
       where unit_id = p_comparison_unit_id;
   end if;  
   if p_rate_comparison_unit_id is not null then
      select unit_code
        into l_rate_unit_code
        from cwms_unit
       where unit_id = p_rate_comparison_unit_id;
   end if;  
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
   l_rate_interval := to_dsinterval(p_rate_interval);      
            
   store_loc_lvl_indicator_cond(
      l_loc_lvl_indicator_code,
      p_level_indicator_value,
      p_expression,
      p_comparison_operator_1,
      p_comparison_value_1,
      l_unit_code,
      p_connector, 
      p_comparison_operator_2,
      p_comparison_value_2,
      p_rate_expression,
      p_rate_comparison_operator_1,
      p_rate_comparison_value_1,
      l_rate_unit_code,
      p_rate_connector, 
      p_rate_comparison_operator_2,
      p_rate_comparison_value_2,
      l_rate_interval,
      p_description,
      p_fail_if_exists,
      p_ignore_nulls_on_update);
end store_loc_lvl_indicator_cond;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_out
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_out(
   p_level_indicator_code     out number,
   p_location_code            in  number,
   p_parameter_code           in  number,
   p_parameter_type_code      in  number,
   p_duration_code            in  number,
   p_specified_level_code     in  number,
   p_level_indicator_id       in  varchar2,
   p_attr_value               in  number default null,
   p_attr_parameter_code      in  number default null,
   p_attr_parameter_type_code in  number default null,
   p_attr_duration_code       in  number default null,
   p_ref_specified_level_code in  number default null,
   p_ref_attr_value           in  number default null,
   p_minimum_duration         in  dsinterval_unconstrained default null,
   p_maximum_age              in  dsinterval_unconstrained default null,
   p_fail_if_exists           in  varchar2 default 'F',
   p_ignore_nulls_on_update   in  varchar2 default 'T')
is          
   l_fail_if_exists         boolean := cwms_util.return_true_or_false(p_fail_if_exists);
   l_ignore_nulls_on_update boolean := cwms_util.return_true_or_false(p_ignore_nulls_on_update);
   l_exists                 boolean := true;
   l_rec                    at_loc_lvl_indicator%rowtype;
   l_parameter_code         number(10);
   l_vert_datum_offset      binary_double;
begin       
   begin    
      select *
        into l_rec
        from at_loc_lvl_indicator
       where location_code = p_location_code
         and parameter_code = p_parameter_code
         and parameter_type_code = p_parameter_type_code
         and duration_code = p_duration_code
         and specified_level_code = p_specified_level_code
         and nvl(to_char(attr_parameter_code), '@') = nvl(to_char(p_attr_parameter_code), '@')
         and level_indicator_id = upper(p_level_indicator_id); 
   exception
      when no_data_found then
         l_exists := false;
   end;     
   if l_exists and l_fail_if_exists then
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'Location level indicator',
         null);
   end if;  
   if l_exists and l_ignore_nulls_on_update then
      l_rec.attr_value               := nvl(cwms_rounding.round_f(p_attr_value, 12), l_rec.attr_value);
      l_rec.attr_parameter_code      := nvl(p_attr_parameter_code,      l_rec.attr_parameter_code);
      l_rec.attr_parameter_type_code := nvl(p_attr_parameter_type_code, l_rec.attr_parameter_type_code);
      l_rec.attr_duration_code       := nvl(p_attr_duration_code,       l_rec.attr_duration_code);
      l_rec.ref_specified_level_code := nvl(p_ref_specified_level_code, l_rec.ref_specified_level_code);
      l_rec.ref_attr_value           := nvl(cwms_rounding.round_f(p_ref_attr_value, 12), l_rec.ref_attr_value);
      l_rec.minimum_duration         := nvl(p_minimum_duration,         l_rec.minimum_duration);
      l_rec.maximum_age              := nvl(p_maximum_age,              l_rec.maximum_age);
   else     
      l_rec.location_code            := p_location_code;
      l_rec.parameter_code           := p_parameter_code;
      l_rec.parameter_type_code      := p_parameter_type_code;
      l_rec.duration_code            := p_duration_code;
      l_rec.specified_level_code     := p_specified_level_code;
      l_rec.level_indicator_id       := upper(p_level_indicator_id);
      l_rec.attr_value               := cwms_rounding.round_f(p_attr_value, 12);
      l_rec.attr_parameter_code      := p_attr_parameter_code;
      l_rec.attr_parameter_type_code := p_attr_parameter_type_code;
      l_rec.attr_duration_code       := p_attr_duration_code;
      l_rec.ref_specified_level_code := p_ref_specified_level_code;
      l_rec.ref_attr_value           := cwms_rounding.round_f(p_ref_attr_value, 12);
      l_rec.minimum_duration         := p_minimum_duration;
      l_rec.maximum_age              := p_maximum_age;
   end if;
   ----------------------------------------------------------
   -- adjust elevation attribute values for vertical datum --
   ----------------------------------------------------------
   begin
      select ap.parameter_code
        into l_parameter_code
        from at_parameter ap,
             cwms_base_parameter bp
       where ap.parameter_code = l_rec.attr_parameter_code
         and bp.base_parameter_code = ap.base_parameter_code
         and bp.base_parameter_id = 'Elev';
   exception
      when no_data_found then null;
   end;
   if l_parameter_code != null then
      l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(p_location_code, 'm');
      l_rec.attr_value := l_rec.attr_value - l_vert_datum_offset;
      l_rec.ref_attr_value := l_rec.ref_attr_value - l_vert_datum_offset;
   end if;
   if l_exists then
      update at_loc_lvl_indicator
         set row = l_rec
       where level_indicator_code = l_rec.level_indicator_code;
   else     
      l_rec.level_indicator_code := cwms_seq.nextval;
      insert into at_loc_lvl_indicator values l_rec; 
   end if;  
   p_level_indicator_code := l_rec.level_indicator_code;
end store_loc_lvl_indicator_out;   
            
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator
--          
-- Creates or updates a Location Level Indicator in the database
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_location_id            in  varchar2,
   p_parameter_id           in  varchar2,
   p_parameter_type_id      in  varchar2,
   p_duration_id            in  varchar2,
   p_specified_level_id     in  varchar2,
   p_level_indicator_id     in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_parameter_id      in  varchar2 default null,
   p_attr_parameter_type_id in  varchar2 default null,
   p_attr_duration_id       in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  dsinterval_unconstrained default null,
   p_maximum_age            in  dsinterval_unconstrained default null,
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null)
is          
   l_obj  loc_lvl_indicator_t;
   l_zobj zloc_lvl_indicator_t;
begin       
   l_obj := loc_lvl_indicator_t(
      nvl(p_office_id, cwms_util.user_office_id),                 
      p_location_id,
      p_parameter_id,
      p_parameter_type_id,
      p_duration_id,
      p_specified_level_id,
      p_level_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_parameter_id,
      p_attr_parameter_type_id,
      p_attr_duration_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_minimum_duration,
      p_maximum_age,
      null); -- conditions
            
   l_zobj := l_obj.zloc_lvl_indicator; 
            
   store_loc_lvl_indicator_out(
      l_zobj.level_indicator_code,
      l_zobj.location_code,
      l_zobj.parameter_code,
      l_zobj.parameter_type_code,
      l_zobj.duration_code,
      l_zobj.specified_level_code,
      l_zobj.level_indicator_id,
      l_zobj.attr_value,
      l_zobj.attr_parameter_code,
      l_zobj.attr_parameter_type_code,
      l_zobj.attr_duration_code,
      l_zobj.ref_specified_level_code,
      l_zobj.ref_attr_value,
      l_zobj.minimum_duration,
      l_zobj.maximum_age,
      p_fail_if_exists,
      p_ignore_nulls_on_update);
            
end store_loc_lvl_indicator;
            
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator
--          
-- Creates or updates a Location Level Indicator in the database
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  dsinterval_unconstrained default null,
   p_maximum_age            in  dsinterval_unconstrained default null,
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null)
is          
   l_location_id        varchar2(49);
   l_parameter_id       varchar2(49);
   l_param_type_id      varchar2(16);
   l_duration_id        varchar2(16);
   l_specified_level_id varchar2(256);
   l_level_indicator_id varchar2(32);
   l_attr_parameter_id  varchar2(49);
   l_attr_param_type_id varchar2(16);
   l_attr_duration_id   varchar2(16);
begin       
   cwms_level.parse_loc_lvl_indicator_id(
      l_location_id,
      l_parameter_id,
      l_param_type_id,
      l_duration_id,
      l_specified_level_id,
      l_level_indicator_id,
      p_loc_lvl_indicator_id);
            
   cwms_level.parse_attribute_id(
      l_attr_parameter_id,
      l_attr_param_type_id,
      l_attr_duration_id,
      p_attribute_id);
            
   store_loc_lvl_indicator(
      l_location_id,
      l_parameter_id,
      l_param_type_id,
      l_duration_id,
      l_specified_level_id,
      l_level_indicator_id,
      p_attr_value,
      p_attr_units_id,
      l_attr_parameter_id,
      l_attr_param_type_id,
      l_attr_duration_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_minimum_duration,
      p_maximum_age,
      p_fail_if_exists,
      p_ignore_nulls_on_update,
      p_office_id);
end store_loc_lvl_indicator;
            
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator
--          
-- Creates or updates a Location Level Indicator in the database
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator in  loc_lvl_indicator_t)
is
   l_loc_lvl_indicator loc_lvl_indicator_t;
begin
   l_loc_lvl_indicator := l_loc_lvl_indicator;
   l_loc_lvl_indicator.store;
end store_loc_lvl_indicator;    

--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator2
--          
-- Creates or updates a Location Level Indicator in the database using only text
-- and numeric parameters
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator2(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  varchar2 default null, -- 'ddd hh:mi:ss'
   p_maximum_age            in  varchar2 default null, -- 'ddd hh:mi:ss'
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null)
is          
begin       
   store_loc_lvl_indicator(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attribute_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      to_dsinterval(p_minimum_duration),
      to_dsinterval(p_maximum_age),
      p_fail_if_exists,
      p_ignore_nulls_on_update,
      p_office_id);
end store_loc_lvl_indicator2;
            
--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator_codes
--          
-- The returned cursor contains only the matching location_level_code
--          
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator_codes(
   p_cursor                     out sys_refcursor,
   p_loc_lvl_indicator_id_mask  in  varchar2 default null,  -- '*.*.*.*.*.*' if null
   p_attribute_id_mask          in  varchar2 default null,
   p_office_id_mask             in  varchar2 default null) -- user's office if null
is          
   l_loc_lvl_indicator_id_mask varchar2(423) := p_loc_lvl_indicator_id_mask;
   l_attribute_id_mask         varchar2(83)  := p_attribute_id_mask;
   l_office_id_mask            varchar2(16)  := nvl(p_office_id_mask, cwms_util.user_office_id);
   l_location_id_mask          varchar2(49);
   l_parameter_id_mask         varchar2(49);
   l_param_type_id_mask        varchar2(16);
   l_duration_id_mask          varchar2(16);
   l_spec_level_id_mask        varchar2(256);
   l_level_indicator_id_mask   varchar2(32);
   l_attr_parameter_id_mask    varchar2(49);
   l_attr_param_type_id_mask   varchar2(16);
   l_attr_duration_id_mask     varchar2(16);
   l_cwms_office_code          number := cwms_util.get_office_code('CWMS');
   l_include_null_attrs        boolean := false;
begin       
   if l_loc_lvl_indicator_id_mask is null or 
      l_loc_lvl_indicator_id_mask = '*'
   then     
      l_loc_lvl_indicator_id_mask := '*.*.*.*.*.*';
   end if;  
   if l_attribute_id_mask is null or
      l_attribute_id_mask = '*'
   then     
      l_attribute_id_mask := '*.*.*';
   end if;  
   if l_attribute_id_mask = '*.*.*'
   then     
      l_include_null_attrs := true;
   end if;  
   parse_loc_lvl_indicator_id(
      l_location_id_mask,
      l_parameter_id_mask,
      l_param_type_id_mask,
      l_duration_id_mask,
      l_spec_level_id_mask,
      l_level_indicator_id_mask,
      l_loc_lvl_indicator_id_mask);
   parse_attribute_id(      
      l_attr_parameter_id_mask,
      l_attr_param_type_id_mask,
      l_attr_duration_id_mask,
      l_attribute_id_mask);
   l_office_id_mask          := upper(cwms_util.normalize_wildcards(l_office_id_mask));      
   l_location_id_mask        := upper(cwms_util.normalize_wildcards(l_location_id_mask));      
   l_parameter_id_mask       := upper(cwms_util.normalize_wildcards(l_parameter_id_mask));      
   l_param_type_id_mask      := upper(cwms_util.normalize_wildcards(l_param_type_id_mask));      
   l_duration_id_mask        := upper(cwms_util.normalize_wildcards(l_duration_id_mask));      
   l_spec_level_id_mask      := upper(cwms_util.normalize_wildcards(l_spec_level_id_mask));      
   l_level_indicator_id_mask := upper(cwms_util.normalize_wildcards(l_level_indicator_id_mask));      
   l_attr_parameter_id_mask  := upper(cwms_util.normalize_wildcards(l_attr_parameter_id_mask));      
   l_attr_param_type_id_mask := upper(cwms_util.normalize_wildcards(l_attr_param_type_id_mask));      
   l_attr_duration_id_mask   := upper(cwms_util.normalize_wildcards(l_attr_duration_id_mask));
            
   if l_include_null_attrs then
      open p_cursor for
         select level_indicator_code from ( 
            select lli.level_indicator_code as level_indicator_code,
                   o.office_id as office_id,
                   upper(bl.base_location_id
                         || substr('-', 1, length(pl.sub_location_id))
                         || pl.sub_location_id) as location_id,         
                   upper(bp.base_parameter_id
                         || substr('-', 1, length(p.sub_parameter_id))
                         || p.sub_parameter_id) as parameter_id,
                   upper(pt.parameter_type_id) as parameter_type_id,
                   upper(d.duration_id) as duration_id,
                   upper(sl.specified_level_id) as specified_level_id,
                   upper(lli.level_indicator_id) as level_indicator_id,
                   null as attr_parameter_id,
                   null as attr_parameter_type_id,
                   null as attr_duration_id
               from at_loc_lvl_indicator lli,
                    at_physical_location pl,
                    at_base_location bl,
                    cwms_office o,
                    at_parameter p,
                    cwms_base_parameter bp,
                    cwms_parameter_type pt,
                    cwms_duration d,
                    at_specified_level sl
              where o.office_id like l_office_id_mask escape '\'
                and bl.db_office_code = o.office_code
                and upper(bl.base_location_id
                          || substr('-', 1, length(pl.sub_location_id))
                          || pl.sub_location_id) like l_location_id_mask escape '\'
                and pl.base_location_code = bl.base_location_code
                and lli.location_code = pl.location_code
                and upper(bp.base_parameter_id
                          || substr('-', 1, length(p.sub_parameter_id))
                          || p.sub_parameter_id) like l_parameter_id_mask escape '\'
                and bp.base_parameter_code = p.base_parameter_code
                and p.db_office_code in (o.office_code, l_cwms_office_code)
                and lli.parameter_code = p.parameter_code
                and upper(pt.parameter_type_id) like l_param_type_id_mask escape '\'
                and lli.parameter_type_code = pt.parameter_type_code
                and upper(d.duration_id) like l_duration_id_mask escape '\'
                and lli.duration_code = d.duration_code
                and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
                and lli.specified_level_code = sl.specified_level_code
                and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
                and lli.attr_parameter_code is null
            union all
            select distinct 
                   lli.level_indicator_code as level_indicator_code,
                   o.office_id as office_id,
                   upper(bl.base_location_id
                         || substr('-', 1, length(pl.sub_location_id))
                         || pl.sub_location_id) as location_id,         
                   upper(bp1.base_parameter_id
                         || substr('-', 1, length(p1.sub_parameter_id))
                         || p1.sub_parameter_id) as parameter_id,
                   upper(pt1.parameter_type_id) as parameter_type_id,
                   upper(d1.duration_id) as duration_id,
                   upper(sl.specified_level_id) as specified_level_id,
                   upper(lli.level_indicator_id) as level_indicator_id,
                   upper(bp2.base_parameter_id
                         || substr('-', 1, length(p2.sub_parameter_id))
                         || p2.sub_parameter_id) as attr_parameter_id,
                   upper(pt2.parameter_type_id) as attr_parameter_type_id,
                   upper(d2.duration_id) as attr_duration_id
               from at_loc_lvl_indicator lli,
                    at_physical_location pl,
                    at_base_location bl,
                    cwms_office o,
                    at_parameter p1,
                    cwms_base_parameter bp1,
                    cwms_parameter_type pt1,
                    cwms_duration d1,
                    at_specified_level sl,
                    at_parameter p2,
                    cwms_base_parameter bp2,
                    cwms_parameter_type pt2,
                    cwms_duration d2
              where o.office_id like l_office_id_mask escape '\'
                and bl.db_office_code = o.office_code
                and upper(bl.base_location_id
                          || substr('-', 1, length(pl.sub_location_id))
                          || pl.sub_location_id) like l_location_id_mask escape '\'
                and pl.base_location_code = bl.base_location_code
                and lli.location_code = pl.location_code
                and upper(bp1.base_parameter_id
                          || substr('-', 1, length(p1.sub_parameter_id))
                          || p1.sub_parameter_id) like l_parameter_id_mask escape '\'
                and bp1.base_parameter_code = p1.base_parameter_code
                and p1.db_office_code in (o.office_code, l_cwms_office_code)
                and lli.parameter_code = p1.parameter_code
                and upper(pt1.parameter_type_id) like l_param_type_id_mask escape '\'
                and lli.parameter_type_code = pt1.parameter_type_code
                and upper(d1.duration_id) like l_duration_id_mask escape '\'
                and lli.duration_code = d1.duration_code
                and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
                and lli.specified_level_code = sl.specified_level_code
                and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
                and lli.attr_parameter_code is not null
                and upper(bp2.base_parameter_id
                          || substr('-', 1, length(p2.sub_parameter_id))
                          || p2.sub_parameter_id) like l_attr_parameter_id_mask escape '\'
                and bp2.base_parameter_code = p2.base_parameter_code
                and p2.db_office_code in (o.office_code, l_cwms_office_code)
                and lli.attr_parameter_code = p2.parameter_code
                and upper(pt2.parameter_type_id) like l_attr_param_type_id_mask escape '\'
                and lli.attr_parameter_type_code = pt2.parameter_type_code
                and upper(d2.duration_id) like l_attr_duration_id_mask escape '\'
                and lli.attr_duration_code = d2.duration_code
           order by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
   else  
      open p_cursor for 
         select distinct 
                lli.level_indicator_code as level_indicator_code
           from at_loc_lvl_indicator lli,
                at_physical_location pl,
                at_base_location bl,
                cwms_office o,
                at_parameter p1,
                cwms_base_parameter bp1,
                cwms_parameter_type pt1,
                cwms_duration d1,
                at_specified_level sl,
                at_parameter p2,
                cwms_base_parameter bp2,
                cwms_parameter_type pt2,
                cwms_duration d2
          where o.office_id like l_office_id_mask escape '\'
            and bl.db_office_code = o.office_code
            and upper(bl.base_location_id
                      || substr('-', 1, length(pl.sub_location_id))
                      || pl.sub_location_id) like l_location_id_mask escape '\'
            and pl.base_location_code = bl.base_location_code
            and lli.location_code = pl.location_code
            and upper(bp1.base_parameter_id
                      || substr('-', 1, length(p1.sub_parameter_id))
                      || p1.sub_parameter_id) like l_parameter_id_mask escape '\'
            and bp1.base_parameter_code = p1.base_parameter_code
            and p1.db_office_code in (o.office_code, l_cwms_office_code)
            and lli.parameter_code = p1.parameter_code
            and upper(pt1.parameter_type_id) like l_param_type_id_mask escape '\'
            and lli.parameter_type_code = pt1.parameter_type_code
            and upper(d1.duration_id) like l_duration_id_mask escape '\'
            and lli.duration_code = d1.duration_code
            and upper(sl.specified_level_id) like l_spec_level_id_mask escape '\'
            and lli.specified_level_code = sl.specified_level_code
            and upper(lli.level_indicator_id) like l_level_indicator_id_mask escape '\'
            and upper(bp2.base_parameter_id
                      || substr('-', 1, length(p2.sub_parameter_id))
                      || p2.sub_parameter_id) like l_attr_parameter_id_mask escape '\'
            and bp2.base_parameter_code = p2.base_parameter_code
            and p2.db_office_code in (o.office_code, l_cwms_office_code)
            and lli.attr_parameter_code = p2.parameter_code
            and upper(pt2.parameter_type_id) like l_attr_param_type_id_mask escape '\'
            and lli.attr_parameter_type_code = pt2.parameter_type_code
            and upper(d2.duration_id) like l_attr_duration_id_mask escape '\'
            and lli.attr_duration_code = d2.duration_code
       order by o.office_id,
                upper(bl.base_location_id
                      || substr('-', 1, length(pl.sub_location_id))
                      || pl.sub_location_id),         
                upper(bp1.base_parameter_id
                      || substr('-', 1, length(p1.sub_parameter_id))
                      || p1.sub_parameter_id),
                upper(pt1.parameter_type_id),
                upper(d1.duration_id),
                upper(sl.specified_level_id),
                upper(lli.level_indicator_id),
                upper(bp2.base_parameter_id
                      || substr('-', 1, length(p2.sub_parameter_id))
                      || p2.sub_parameter_id),
                upper(pt2.parameter_type_id),
                upper(d2.duration_id);
   end if;             
                          
end cat_loc_lvl_indicator_codes;   
            
--------------------------------------------------------------------------------
-- FUNCTION cat_loc_lvl_indicator_codes
--          
-- The returned cursor contains only the matching location_level_code
--          
--------------------------------------------------------------------------------
function cat_loc_lvl_indicator_codes(
   p_loc_lvl_indicator_id_mask in  varchar2 default null, -- '*.*.*.*.*.*' if null
   p_attribute_id_mask         in  varchar2 default null,
   p_office_id_mask            in  varchar2 default null) -- user's office if null
   return sys_refcursor
is          
   l_cursor sys_refcursor;
begin       
   cat_loc_lvl_indicator_codes(
      l_cursor,
      p_loc_lvl_indicator_id_mask,
      p_attribute_id_mask,
      p_office_id_mask);
            
   return l_cursor;      
end cat_loc_lvl_indicator_codes;      
            
--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator
--          
-- Retrieves a cursor of Location Level Indicators and associated Conditions
-- that match the input masks
--          
-- p_location_level_id_mask - Location Level Identifier that can contain SQL
-- wildcards (%, _) or filename wildcards (*, ?), cannot be NULL
--          
-- p_attribute_id_mask - Attribute Identifier that can contain wildcards, cannot
-- be NULL  
--          
-- p_office_id_mask - Office Identifier that can contain wildcards, if NULL, the
-- user's office id is used
--          
-- p_unit_system is 'EN' or 'SI'
--          
-- p_cursor contains 18 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(256)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       interval day(3) to second(0)
--  15 : maximum_age            interval day(3) to second(0)
--  16 : ref_specified_level_id varchar2(256)
--  17 : ref_attr_value         number
--  18 : conditions             sys_refcursor
--          
-- The cursor returned in field 18 contains 17 fields:
--   1 : level_indicator_value       integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day(3) to second(0)
--  17 : description                 varchar2(256)  
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI')
is          
   l_location_id_mask            varchar2(49);
   l_parameter_id_mask           varchar2(49);
   l_parameter_type_id_mask      varchar2(16);
   l_duration_id_mask            varchar2(16);
   l_specified_level_id_mask     varchar2(256);
   l_attr_parameter_id_mask      varchar2(49);
   l_attr_parameter_type_id_mask varchar2(16);
   l_attr_duration_id_mask       varchar2(16);
   l_office_id_mask              varchar2(16) := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id));
   l_cwms_office_code            number(10)   := cwms_util.get_office_code('CWMS');
begin       
   cwms_level.parse_location_level_id(
      l_location_id_mask,
      l_parameter_id_mask,
      l_parameter_type_id_mask,
      l_duration_id_mask,
      l_specified_level_id_mask,
      cwms_util.normalize_wildcards(p_location_level_id_mask));
   cwms_level.parse_attribute_id(
      l_attr_parameter_id_mask,
      l_attr_parameter_type_id_mask,
      l_attr_duration_id_mask,
      cwms_util.normalize_wildcards(p_attribute_id_mask));
            
   open p_cursor for
      with  
         indicator as 
         (select o.office_id as office_id,
                 bl.base_location_id
                 || substr('-', 1, length(pl.sub_location_id))
                 || pl.sub_location_id as location_id,
                 bp.base_parameter_id
                 || substr('-', 1, length(p.sub_parameter_id))
                 || p.sub_parameter_id as parameter_id,
                 pt.parameter_type_id as parameter_type_id,
                 d.duration_id as duration_id,
                 sl.specified_level_id as specified_level_id,
                 lli.level_indicator_code as level_indicator_code,
                 lli.level_indicator_id as level_indicator_id,
                 lli.minimum_duration as minimum_duration,
                 lli.maximum_age as maximum_age,
                 lli.attr_parameter_code as attr_parameter_code,
                 lli.attr_parameter_type_code as attr_parameter_type_code,
                 lli.attr_duration_code as attr_duration_code,
                 lli.attr_value as attr_value,
                 lli.ref_specified_level_code as ref_specified_level_code,
                 lli.ref_attr_value as ref_attr_value
            from at_loc_lvl_indicator lli,
                 at_physical_location pl,
                 at_base_location bl,
                 cwms_office o,
                 at_parameter p,
                 cwms_base_parameter bp,
                 cwms_parameter_type pt,
                 cwms_duration d,
                 at_specified_level sl,
                 cwms_unit_conversion cuc
           where upper(o.office_id) like upper(l_office_id_mask) escape '\'
             and upper(bl.base_location_id
                       || substr('-', 1, length(pl.sub_location_id))
                       || pl.sub_location_id) like upper(l_location_id_mask) escape '\'
             and upper(bp.base_parameter_id
                       || substr('-', 1, length(p.sub_parameter_id))
                       ||p.sub_parameter_id) like upper(l_parameter_id_mask) escape '\'
             and upper(pt.parameter_type_id) like upper(l_parameter_type_id_mask) escape '\'
             and upper(d.duration_id) like upper(l_duration_id_mask) escape '\'
             and upper(sl.specified_level_id) like upper(l_specified_level_id_mask) escape '\'
             and bl.db_office_code = o.office_code
             and pl.base_location_code = bl.base_location_code
             and lli.location_code = pl.location_code
             and p.base_parameter_code = bp.base_parameter_code
             and (p.db_office_code = o.office_code or p.db_office_code = l_cwms_office_code)
             and lli.parameter_code = p.parameter_code
             and lli.parameter_type_code = pt.parameter_type_code
             and lli.duration_code = d.duration_code
             and lli.specified_level_code = sl.specified_level_code
             and cuc.from_unit_id = cwms_util.get_default_units(bp.base_parameter_id)
             and cuc.to_unit_id = cwms_util.get_default_units(bp.base_parameter_id, p_unit_system)
         ), 
         attr_param as  
         (select bp.base_parameter_id
                 || substr('-', 1, length(p.sub_parameter_id))
                 || p.sub_parameter_id as attr_parameter_id,
                 p.parameter_code,
                 cuc.offset as offset,
                 cuc.factor as factor
            from cwms_office o,
                 at_parameter p,
                 cwms_base_parameter bp,
                 cwms_unit_conversion cuc
           where upper(o.office_id) like upper(l_office_id_mask) escape '\'
             and upper(bp.base_parameter_id) like upper(cwms_util.get_base_id(l_attr_parameter_id_mask)) escape '\'
             and upper(nvl(p.sub_parameter_id, '.')) like upper(nvl(cwms_util.get_sub_id(l_attr_parameter_id_mask), '.')) escape '\'
             and p.base_parameter_code = bp.base_parameter_code
             and (p.db_office_code = o.office_code or p.db_office_code = l_cwms_office_code)
             and cuc.from_unit_id = cwms_util.get_default_units(bp.base_parameter_id)
             and cuc.to_unit_id = cwms_util.get_default_units(bp.base_parameter_id, p_unit_system)
         ), 
         attr_param_type as
         (select parameter_type_code,
                 parameter_type_id as attr_parameter_type_id
            from cwms_parameter_type
           where upper(parameter_type_id) like upper(l_attr_parameter_type_id_mask) escape '\'
         ), 
         attr_duration as
         (select duration_code,
                 duration_id as attr_duration_id
            from cwms_duration
           where upper(duration_id) like upper(l_attr_duration_id_mask) escape '\'
         ), 
         ref as    
         (select specified_level_code,
                 specified_level_id as ref_specified_level_id
            from at_specified_level
         )  
      select office_id,
             location_id,
             parameter_id,
             parameter_type_id,
             duration_id,
             specified_level_id,
             level_indicator_id,
             cwms_util.get_default_units(parameter_id, p_unit_system) as level_units_id,
             attr_parameter_id,
             attr_parameter_type_id,
             attr_duration_id,
             cwms_util.get_default_units(attr_parameter_id, p_unit_system) as attr_units_id,
             cwms_rounding.round_f(attr_value * attr_param.factor + attr_param.offset, 9) as attr_value,
             minimum_duration,
             maximum_age,
             ref_specified_level_id,
             cwms_rounding.round_f(ref_attr_value * attr_param.factor + attr_param.offset, 9) as ref_attr_value,
                 cursor (
                    select level_indicator_value,
                           expression,
                           comparison_operator_1,
                           comparison_value_1,
                           comparison_unit_id,
                           connector,
                           comparison_operator_2,
                           comparison_value_2,
                           rate_expression,
                           rate_comparison_operator_1,
                           rate_comparison_value_1,
                           rate_comparison_unit_id,
                           rate_connector,
                           rate_comparison_operator_2,
                           rate_comparison_value_2,
                           rate_interval,
                           description
                      from (select level_indicator_code,
                                   level_indicator_value,
                                   expression,
                                   comparison_operator_1,
                                   comparison_value_1,
                                   comparison_unit,
                                   connector,
                                   comparison_operator_2,
                                   comparison_value_2,
                                   rate_expression,
                                   rate_comparison_operator_1,
                                   rate_comparison_value_1,
                                   rate_comparison_unit,
                                   rate_connector,
                                   rate_comparison_operator_2,
                                   rate_comparison_value_2,
                                   rate_interval,
                                   description
                              from at_loc_lvl_indicator_cond
                           ) cond
                           left outer join
                           (select unit_code,
                                   unit_id as comparison_unit_id
                              from cwms_unit
                           ) unit
                           on unit.unit_code = cond.comparison_unit
                           left outer join
                           (select unit_code,
                                   unit_id as rate_comparison_unit_id
                              from cwms_unit
                           ) rate_unit
                           on rate_unit.unit_code = cond.rate_comparison_unit
                     where level_indicator_code = indicator.level_indicator_code
                  order by level_indicator_value
                 ) as conditions
        from ((((indicator left outer join attr_param
                 on attr_param.parameter_code = indicator.attr_parameter_code
                ) left outer join attr_param_type
                on attr_param_type.parameter_type_code = indicator.attr_parameter_type_code
               ) left outer join attr_duration
               on attr_duration.duration_code = indicator.attr_duration_code
              ) left outer join ref
              on ref.specified_level_code = indicator.ref_specified_level_code
             )
    order by office_id,
             location_id,
             parameter_id,
             parameter_type_id,
             duration_id,
             specified_level_id,
             level_indicator_id,
             attr_parameter_id,
             attr_parameter_type_id,
             attr_duration_id,
             ref_specified_level_id;             
end cat_loc_lvl_indicator;   
            
--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator2
--          
-- Retrieves a cursor of Location Level Indicators and associated Conditions
-- that match the input masks and contains only text and numeric fields
--          
-- p_location_level_id_mask - Location Level Identifier that can contain SQL
-- wildcards (%, _) or filename wildcards (*, ?), cannot be NULL
--          
-- p_attribute_id_mask - Attribute Identifier that can contain wildcards, cannot
-- be NULL  
--          
-- p_office_id_mask - Office Identifier that can contain wildcards, if NULL, the
-- user's office id is used
--          
-- p_unit_system is 'EN' or 'SI'
--          
-- p_cursor contains 18 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(256)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       varchar2(12)
--  15 : maximum_age            varchar2(12)
--  16 : ref_specified_level_id varchar2(256)
--  17 : ref_attribute_value    number
--  18 : conditions             varchar2(4096)
--          
-- Fields 14 and 15 are in the format 'ddd hh:mm:ss'
--          
-- The character string returned in field 18 contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2(12)
--  17 : description                 varchar2(256)  
--          
-- Field 16 is in the format 'ddd hh:mm:ss'
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator2(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI')
is          
   l_cursor                      sys_refcursor;
   l_parts                       str_tab_tab_t := str_tab_tab_t();
   l_seq                         integer;
   l_office_id                   varchar2(16);
   l_location_id                 varchar2(49);
   l_parameter_id                varchar2(49);
   l_parameter_type_id           varchar2(16);
   l_duration_id                 varchar2(16);
   l_specified_level_id          varchar2(256);
   l_level_indicator_id          varchar2(32);
   l_level_units_id              varchar2(16);
   l_attr_parameter_id           varchar2(49);
   l_attr_parameter_type_id      varchar2(16);
   l_attr_duration_id            varchar2(16);
   l_attr_units_id               varchar2(16);
   l_attr_value                  number;
   l_minimum_duration            interval day(3) to second(0);
   l_maximum_age                 interval day(3) to second(0);
   l_rate_of_change              varchar2(1);
   l_ref_specified_level_id      varchar2(256);
   l_ref_attribute_value         number;
   l_conditions                  sys_refcursor;
   l_conditions_txt              varchar2(4096);
   l_indicator_value             integer;
   l_expression                  varchar2(64);
   l_comparison_operator_1       varchar2(2);
   l_comparison_value_1          binary_double;
   l_comparison_unit_id          varchar2(16);
   l_connector                   varchar2(3);
   l_comparison_operator_2       varchar2(2);
   l_comparison_value_2          binary_double;
   l_rate_expression             varchar2(64);
   l_rate_comparison_operator_1  varchar2(2);
   l_rate_comparison_value_1     binary_double;
   l_rate_comparison_unit_id     varchar2(16);
   l_rate_connector              varchar2(3);
   l_rate_comparison_operator_2  varchar2(2);
   l_rate_comparison_value_2     binary_double;
   l_rate_interval               interval day(3) to second(0);
   l_description                 varchar2(256);
   l_rs                          varchar2(1) := chr(30);
   l_gs                          varchar2(1) := chr(29);
begin       
   delete from at_loc_lvl_indicator_tab;
   cat_loc_lvl_indicator(
      l_cursor,
      p_location_level_id_mask,
      p_attribute_id_mask,
      p_office_id_mask,
      p_unit_system);
   loop     
      fetch l_cursor 
       into l_office_id,
            l_location_id,
            l_parameter_id,
            l_parameter_type_id,
            l_duration_id,
            l_specified_level_id,
            l_level_indicator_id,
            l_level_units_id,
            l_attr_parameter_id,
            l_attr_parameter_type_id,
            l_attr_duration_id,
            l_attr_units_id,
            l_attr_value,
            l_minimum_duration,
            l_maximum_age,
            l_ref_specified_level_id,
            l_ref_attribute_value,
            l_conditions;
      exit when l_cursor%notfound;
      l_parts.delete; 
      loop  
         fetch l_conditions
               into l_indicator_value,
                    l_expression,
                    l_comparison_operator_1,
                    l_comparison_value_1,
                    l_comparison_unit_id,
                    l_connector,
                    l_comparison_operator_2,
                    l_comparison_value_2,
                    l_rate_expression,
                    l_rate_comparison_operator_1,
                    l_rate_comparison_value_1,
                    l_rate_comparison_unit_id,
                    l_rate_connector,
                    l_rate_comparison_operator_2,
                    l_rate_comparison_value_2,
                    l_rate_interval,
                    l_description;
         exit when l_conditions%notfound;
         l_parts.extend;
         l_parts(l_conditions%rowcount) := str_tab_t();
         l_parts(l_conditions%rowcount).extend(17);
         l_parts(l_conditions%rowcount)( 1) := to_char(l_indicator_value);               
         l_parts(l_conditions%rowcount)( 2) := l_expression;               
         l_parts(l_conditions%rowcount)( 3) := l_comparison_operator_1;               
         l_parts(l_conditions%rowcount)( 4) := to_char(l_comparison_value_1);               
         l_parts(l_conditions%rowcount)( 5) := l_comparison_unit_id;               
         l_parts(l_conditions%rowcount)( 6) := l_connector;               
         l_parts(l_conditions%rowcount)( 7) := l_comparison_operator_2;               
         l_parts(l_conditions%rowcount)( 8) := to_char(l_comparison_value_2);               
         l_parts(l_conditions%rowcount)( 9) := l_rate_expression;               
         l_parts(l_conditions%rowcount)(10) := l_rate_comparison_operator_1;               
         l_parts(l_conditions%rowcount)(11) := to_char(l_rate_comparison_value_1);               
         l_parts(l_conditions%rowcount)(12) := l_rate_comparison_unit_id;               
         l_parts(l_conditions%rowcount)(13) := l_rate_connector;               
         l_parts(l_conditions%rowcount)(14) := l_rate_comparison_operator_2;               
         l_parts(l_conditions%rowcount)(15) := to_char(l_rate_comparison_value_2);               
         l_parts(l_conditions%rowcount)(16) := substr(to_char(l_rate_interval), 2);               
         l_parts(l_conditions%rowcount)(17) := l_description;               
      end loop;
      close l_conditions;
      l_conditions_txt := '';
      for i in 1..l_parts.count loop
         if i > 1 then
            l_conditions_txt := l_conditions_txt || l_rs;
         end if;
         for j in 1..l_parts(i).count loop
            if j > 1 then
               l_conditions_txt := l_conditions_txt || l_gs;
            end if;
            l_conditions_txt := l_conditions_txt || l_parts(i)(j);
         end loop;            
      end loop;
      l_seq := l_cursor%rowcount;
      insert
        into at_loc_lvl_indicator_tab
      values (l_seq,
              l_office_id,
              l_location_id,
              l_parameter_id,
              l_parameter_type_id,
              l_duration_id,
              l_specified_level_id,
              l_level_indicator_id,
              l_level_units_id,
              l_attr_parameter_id,
              l_attr_parameter_type_id,
              l_attr_duration_id,
              l_attr_units_id,
              cwms_rounding.round_f(l_attr_value, 9),
              to_char(l_minimum_duration),            
              to_char(l_maximum_age),
              l_rate_of_change,
              l_ref_specified_level_id,
              cwms_rounding.round_f(l_ref_attribute_value, 9),
              l_conditions_txt);            
   end loop;
   close l_cursor;
   open p_cursor for
      select *
        from at_loc_lvl_indicator_tab
    order by seq;
end cat_loc_lvl_indicator2;   
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_indicator
--          
-- Retrieves a Location Level Indicator and its associated Conditions
--          
-- The cursor returned in p_conditions contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day(3) to second(0)
--  17 : description                 varchar2(256)  
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_indicator(
   p_minimum_duration       out dsinterval_unconstrained,
   p_maximum_age            out dsinterval_unconstrained,
   p_conditions             out sys_refcursor,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is          
   l_loc_lvl_indicator_code number(10);
   l_level_factor           number := 1.;
   l_level_offset           number := 0.;
   l_location_id            varchar2(49);
   l_parameter_id           varchar2(49);
   l_parameter_type_id      varchar2(16);
   l_duration_id            varchar2(16);
   l_specified_level_id     varchar2(256);
   l_level_indicator_id     varchar2(32);
begin       
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
            
      if p_level_units_id is not null then
         cwms_level.parse_loc_lvl_indicator_id(
            l_location_id,
            l_parameter_id,
            l_parameter_type_id,
            l_duration_id,
            l_specified_level_id,
            l_level_indicator_id,
            p_loc_lvl_indicator_id);
         select factor,
                offset
           into l_level_factor,
                l_level_offset
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_default_units(l_parameter_id)
            and to_unit_id = p_level_units_id;
      end if;
      select minimum_duration,
             maximum_age,
             conditions
        into p_minimum_duration,
             p_maximum_age,
             p_conditions             
        from (select lli.minimum_duration as minimum_duration,
                     lli.maximum_age as maximum_age,
                     cursor (
                        select level_indicator_value,
                                expression,
                                comparison_operator_1,
                                comparison_value_1,
                                comparison_unit_id,
                                connector,
                                comparison_operator_2,
                                comparison_value_2,
                                rate_expression,
                                rate_comparison_operator_1,
                                rate_comparison_value_1,
                                rate_comparison_unit_id,
                                rate_connector,
                                rate_comparison_operator_2,
                                rate_comparison_value_2,
                                rate_interval,
                                description
                           from ((select level_indicator_value,
                                          expression,
                                          comparison_operator_1,
                                          comparison_value_1,
                                          comparison_unit,
                                          connector,
                                          comparison_operator_2,
                                          comparison_value_2,
                                          rate_expression,
                                          rate_comparison_operator_1,
                                          rate_comparison_value_1,
                                          rate_comparison_unit,
                                          rate_connector,
                                          rate_comparison_operator_2,
                                          rate_comparison_value_2,
                                          rate_interval,
                                          description
                                     from at_loc_lvl_indicator_cond
                                 ) cond
                                 left outer join
                                 (select unit_code,
                                         unit_id as comparison_unit_id
                                    from cwms_unit
                                 ) unit
                                 on unit.unit_code = cond.comparison_unit
                                )
                                left outer join
                                (select unit_code,
                                        unit_id as rate_comparison_unit_id
                                   from cwms_unit
                                ) rate_unit
                                on rate_unit.unit_code = cond.rate_comparison_unit
                          where level_indicator_code = lli.level_indicator_code
                       order by level_indicator_value) as conditions
                from at_loc_lvl_indicator lli
               where lli.level_indicator_code = l_loc_lvl_indicator_code);
                
end retrieve_loc_lvl_indicator;   
            
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_indicator2
--          
-- Retrieves a Location Level Indicator and its associated Conditions and uses
-- only text and numeric fields
--          
-- p_minimum_duration is in the format 'ddd hh:mm:ss'
--          
-- p_maximum_age is in the format 'ddd hh:mm:ss'
--          
-- The character string returned in p_conditions contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2(12)
--  17 : description                 varchar2(256)  
--          
-- Field 16 is in the format 'ddd hh:mm:ss'
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_indicator2(
   p_minimum_duration       out varchar2, -- 'ddd hh:mi:ss'
   p_maximum_age            out varchar2, -- 'ddd hh:mi:ss'
   p_conditions             out varchar2,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is          
   l_minimum_duration            interval day(3) to second(0);
   l_maximum_age                 interval day(3) to second(0);
   l_parts                       str_tab_tab_t;
   l_conditions                  sys_refcursor;
   l_conditions_txt              varchar2(4096);
   l_indicator_value             integer;
   l_expression                  varchar2(64);
   l_comparison_operator_1       varchar2(2);
   l_comparison_value_1          binary_double;
   l_comparison_unit_id          varchar2(16);
   l_connector                   varchar2(3);
   l_comparison_operator_2       varchar2(2);
   l_comparison_value_2          binary_double;
   l_rate_expression             varchar2(64);
   l_rate_comparison_operator_1  varchar2(2);
   l_rate_comparison_value_1     binary_double;
   l_rate_comparison_unit_id     varchar2(16);
   l_rate_connector              varchar2(3);
   l_rate_comparison_operator_2  varchar2(2);
   l_rate_comparison_value_2     binary_double;
   l_rate_interval               interval day(3) to second(0);
   l_description                 varchar2(256);
   l_rs                          varchar2(1) := chr(30);
   l_gs                          varchar2(1) := chr(29);
begin       
   retrieve_loc_lvl_indicator(
      l_minimum_duration,
      l_maximum_age,
      l_conditions,
      p_loc_lvl_indicator_id,
      p_level_units_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
            
   p_minimum_duration := substr(to_char(l_minimum_duration), 2);      
   p_maximum_age      := substr(to_char(l_maximum_age), 2);      
   loop     
      fetch l_conditions
            into l_indicator_value,
                 l_expression,
                 l_comparison_operator_1,
                 l_comparison_value_1,
                 l_comparison_unit_id,
                 l_connector,
                 l_comparison_operator_2,
                 l_comparison_value_2,
                 l_rate_expression,
                 l_rate_comparison_operator_1,
                 l_rate_comparison_value_1,
                 l_rate_comparison_unit_id,
                 l_rate_connector,
                 l_rate_comparison_operator_2,
                 l_rate_comparison_value_2,
                 l_rate_interval,
                 l_description;
      exit when l_conditions%notfound;
      l_parts.extend;
      l_parts(l_conditions%rowcount).extend(17);
      l_parts(l_conditions%rowcount)( 1) := to_char(l_indicator_value);               
      l_parts(l_conditions%rowcount)( 2) := l_expression;               
      l_parts(l_conditions%rowcount)( 3) := l_comparison_operator_1;               
      l_parts(l_conditions%rowcount)( 4) := to_char(l_comparison_value_1);               
      l_parts(l_conditions%rowcount)( 5) := l_comparison_unit_id;               
      l_parts(l_conditions%rowcount)( 6) := l_connector;               
      l_parts(l_conditions%rowcount)( 7) := l_comparison_operator_2;               
      l_parts(l_conditions%rowcount)( 8) := to_char(l_comparison_value_2);               
      l_parts(l_conditions%rowcount)( 9) := l_rate_expression;               
      l_parts(l_conditions%rowcount)(10) := l_rate_comparison_operator_1;               
      l_parts(l_conditions%rowcount)(11) := to_char(l_rate_comparison_value_1);               
      l_parts(l_conditions%rowcount)(12) := l_rate_comparison_unit_id;               
      l_parts(l_conditions%rowcount)(13) := l_rate_connector;               
      l_parts(l_conditions%rowcount)(14) := l_rate_comparison_operator_2;               
      l_parts(l_conditions%rowcount)(15) := to_char(l_rate_comparison_value_2);               
      l_parts(l_conditions%rowcount)(16) := substr(to_char(l_rate_interval), 2);               
      l_parts(l_conditions%rowcount)(17) := l_description;               
   end loop;
   close l_conditions;
   l_conditions_txt := '';
   for i in 1..l_parts.count loop
      if i > 1 then
         l_conditions_txt := l_conditions_txt || l_rs;
      end if;
      for j in 1..l_parts(i).count loop
         if j > 1 then
            l_conditions_txt := l_conditions_txt || l_gs;
         end if;
         l_conditions_txt := l_conditions_txt || l_parts(i)(j);
      end loop;            
   end loop;
   p_conditions := l_conditions_txt;
end retrieve_loc_lvl_indicator2;   
            
--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_indicator 
--          
-- Returns a Location Level Indicator and its associated Conditions in a
-- LOC_LVL_INDICATOR_T object
--------------------------------------------------------------------------------
function retrieve_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return loc_lvl_indicator_t
is          
   l_loc_lvl_indicator_code number(10);
   l_row_id                 urowid;
   l_obj                    loc_lvl_indicator_t;
begin       
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
            
   select rowid
     into l_row_id
     from at_loc_lvl_indicator
    where level_indicator_code = l_loc_lvl_indicator_code;
            
   l_obj := loc_lvl_indicator_t(l_row_id);
   return l_obj;
             
end retrieve_loc_lvl_indicator;   
            
--------------------------------------------------------------------------------
-- PROCEDURE delete_loc_lvl_indicator
--          
-- Deletes a Location Level Indicator and its associated Conditions
--------------------------------------------------------------------------------
procedure delete_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is          
   l_loc_lvl_indicator_code number(10);
begin       
   l_loc_lvl_indicator_code := get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id,
      p_attr_value,
      p_attr_units_id,
      p_attr_id,
      p_ref_specified_level_id,
      p_ref_attr_value,
      p_office_id);
            
   delete   
     from at_loc_lvl_indicator_cond
    where level_indicator_code = l_loc_lvl_indicator_code;      
            
   delete   
     from at_loc_lvl_indicator
    where level_indicator_code = l_loc_lvl_indicator_code;      
end delete_loc_lvl_indicator;   

--------------------------------------------------------------------------------
-- PROCEDURE rename_loc_lvl_indicator
--          
-- Renames a Location Level Indicator
--------------------------------------------------------------------------------
procedure rename_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_new_indicator_id       in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
is
   l_level_indicator_code number(10);   
begin
   l_level_indicator_code := cwms_level.get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id, 
      p_attr_value, 
      p_attr_units_id, 
      p_attr_id, 
      p_ref_specified_level_id, 
      p_ref_attr_value, 
      p_office_id); 

   update at_loc_lvl_indicator
      set level_indicator_id = p_new_indicator_id
    where level_indicator_code = l_level_indicator_code; 
end rename_loc_lvl_indicator;
     
function eval_level_indicator_expr(
   p_tsid                   in varchar2,
   p_start_time             in date,
   p_end_time               in date,      
   p_unit                   in varchar2,
   p_specified_level_id     in varchar2,
   p_indicator_id           in varchar2,
   p_attribute_id           in varchar2      default null,
   p_attribute_value        in binary_double default null,
   p_attribute_unit         in varchar2      default null,
   p_ref_specified_level_id in varchar2      default null,
   p_ref_attribute_value    in number        default null,
   p_time_zone              in varchar2      default null,
   p_condition_number       in integer       default 1,
   p_office_id              in varchar2      default null)
   return ztsv_array
is
   l_unit         varchar2(16);
   l_time_zone    varchar2(28);
   l_ts           ztsv_array;   
   l_parts        str_tab_t;
   l_indicator_id varchar2(512);
   c              sys_refcursor;
   l_date_time    timestamp with time zone;
   l_value        binary_double;
   l_quality      number;
begin
   l_unit := cwms_util.get_unit_id(p_unit);      
   l_time_zone := nvl(
      cwms_util.get_timezone(p_time_zone), 
      cwms_loc.get_local_timezone(cwms_util.split_text(p_tsid, 1, '.'), p_office_id));
      
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => c,      
      p_cwms_ts_id      => p_tsid, 
      p_units           => l_unit, 
      p_start_time      => p_start_time, 
      p_end_time        => p_end_time, 
      p_time_zone       => l_time_zone, 
      p_trim            => 'T', 
      p_start_inclusive => 'T', 
      p_end_inclusive   => 'T', 
      p_previous        => 'F', 
      p_next            => 'F', 
      p_version_date    => cwms_util.non_versioned, 
      p_max_version     => 'T', 
      p_office_id       => p_office_id);
      
   l_ts := ztsv_array();
   loop    
      fetch c into l_date_time, l_value, l_quality;
      exit when c%notfound;
      l_ts.extend();
      l_ts(l_ts.count) := ztsv_type(cast(l_date_time as date), l_value, l_quality);
   end loop;
   close c;      
      
   l_parts := cwms_util.split_text(p_tsid, '.');         
   l_indicator_id := cwms_util.join_text(
      str_tab_t(
         l_parts(1),
         l_parts(2),
         l_parts(3),
         l_parts(5),
         p_specified_level_id,
         p_indicator_id),
      '.');   
                                                 
   l_ts := eval_level_indicator_expr(
      p_ts                     => l_ts,  
      p_unit                   => l_unit,
      p_loc_lvl_indicator_id   => l_indicator_id,
      p_attribute_id           => p_attribute_id,
      p_attribute_value        => p_attribute_value,
      p_attribute_unit         => p_attribute_unit,
      p_ref_specified_level_id => p_ref_specified_level_id,
      p_ref_attribute_value    => p_ref_attribute_value,
      p_time_zone              => l_time_zone,
      p_condition_number       => p_condition_number,
      p_office_id              => p_office_id);
      
   return l_ts;      
end eval_level_indicator_expr;    

function eval_level_indicator_expr(
   p_ts                     in ztsv_array,  
   p_unit                   in varchar2,
   p_loc_lvl_indicator_id   in varchar2,
   p_attribute_id           in varchar2      default null,
   p_attribute_value        in binary_double default null,
   p_attribute_unit         in varchar2      default null,
   p_ref_specified_level_id in varchar2      default null,
   p_ref_attribute_value    in number        default null,
   p_time_zone              in varchar2      default null,
   p_condition_number       in integer       default 1,
   p_office_id              in varchar2      default null)
   return ztsv_array 
is
   l_indicator loc_lvl_indicator_t;
   l_values    double_tab_tab_t;
   l_results   ztsv_array;
begin
   l_indicator := retrieve_loc_lvl_indicator(
      p_loc_lvl_indicator_id   => p_loc_lvl_indicator_id, 
      p_attr_value             => p_attribute_value, 
      p_attr_units_id          => p_attribute_unit, 
      p_attr_id                => p_attribute_id, 
      p_ref_specified_level_id => p_ref_specified_level_id, 
      p_ref_attr_value         => p_ref_attribute_value, 
      p_office_id              => p_office_id);
   l_values := l_indicator.get_indicator_expr_values(
      p_ts        => p_ts,
      p_unit      => p_unit,
      p_condition => p_condition_number,
      p_eval_time => null,
      p_time_zone => p_time_zone);

   l_results := ztsv_array();
   l_results.extend(l_values.count);
   for i in 1..l_values.count loop
      l_results(i) := ztsv_type(p_ts(i).date_time, l_values(i)(1), 0);
   end loop;
   return l_results;
end eval_level_indicator_expr;
       
--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_values
--          
-- Retreieves the values for all Location Level Indicator Conditions that are
-- set at p_eval_time and that match the input parameters.  Each indicator may
-- have multiple condions set.
--          
-- p_tsid - time series identifier, p_cursor will only include Conditions for 
-- Location Levels that have the same Location, Parameter, and Parameter Type
--          
-- p_eval_time - evaluation time, current time if NULL
--          
-- p_time_zone - time zone of p_eval_time, 'UTC' if NULL
--          
-- p_specified_level_mask - Specified Level Indicator with optional SQL
-- wildcards (%, _) or filename wildcards (*, ?), '%' if NULL
--          
-- p_indicator_id_mask - Location Level Identifier with optional wildcards, '%'
-- if NULL  
--          
-- p_unit_system - unit system for which to retrieve attribute values, 'EN' or 
-- 'SI', 'SI' if NULL
--          
-- p_office_id - office identifier for p_tsid, user's office identifier if NULL
--          
-- p_cursor contains the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number           
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values number_tab_t
--------------------------------------------------------------------------------
procedure get_level_indicator_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_eval_time            in  date     default null,   -- sysdate if null
   p_time_zone            in  varchar2 default null,   -- 'UTC' if null
   p_specified_level_mask in  varchar2 default null,   -- '%' if null
   p_indicator_id_mask    in  varchar2 default null,   -- '%' if null
   p_unit_system          in  varchar2 default null,   -- 'SI' if null
   p_office_id            in  varchar2 default null)   -- user's office if null 
is          
   l_tsid                   varchar2(183) := p_tsid;
   l_office_id              varchar2(16)  := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_specified_level_mask   varchar2(256) := nvl(p_specified_level_mask, '*');
   l_indicator_id_mask      varchar2(256) := nvl(p_indicator_id_mask, '*');
   l_unit_system            varchar2(2)   := nvl(p_unit_system, 'SI');
   l_location_level_id_mask varchar2(423);
   l_base_location_id       varchar2(16);
   l_sub_location_id        varchar2(32);
   l_base_parameter_id      varchar2(16);
   l_sub_parameter_id       varchar2(32);
   l_parameter_type_id      varchar2(16);
   l_interval_id            varchar2(16);
   l_duration_id            varchar2(16);
   l_version_id             varchar2(32);
   l_indicator_codes_crsr   sys_refcursor;
   l_ts_crsr                sys_refcursor;
   l_indicator_code         number(10);
   l_rowid                  rowid;
   l_loc_lvl_objs           loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
   l_ts_units               varchar2(16);
   l_start_time             timestamp;
   l_end_time               timestamp;
   l_ts_date_time           date;
   l_ts_value               binary_double;
   l_ts_quality             number;
   l_ts                     ztsv_array := new ztsv_array();
begin       
   ------------------------------------------------------------------
   -- open a cursor of all matching location level indicator codes --
   ------------------------------------------------------------------
   cwms_ts.parse_ts(
      l_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   l_indicator_codes_crsr := cat_loc_lvl_indicator_codes(
      get_loc_lvl_indicator_id(
         l_base_location_id
            || substr('-', 1, length(l_sub_location_id))
            || l_sub_location_id,
         l_base_parameter_id
            || substr('-', 1, length(l_sub_parameter_id))
            || l_sub_parameter_id,
         l_parameter_type_id,
         l_duration_id,
         l_specified_level_mask,
         l_indicator_id_mask),
      '*.*.*',
      l_office_id);
   --------------------------------------------------               
   -- build a table of loc_lvl_indicator_t objects --
   --------------------------------------------------
   loop     
      fetch l_indicator_codes_crsr into l_indicator_code;
      exit when l_indicator_codes_crsr%notfound;
      select rowid 
        into l_rowid
        from at_loc_lvl_indicator 
       where level_indicator_code = l_indicator_code;   
      l_loc_lvl_objs.extend;
      l_loc_lvl_objs(l_loc_lvl_objs.count) := new loc_lvl_indicator_t(l_rowid);
   end loop;
   close l_indicator_codes_crsr;
   -------------------------------------
   -- compute the start and end times --
   -------------------------------------
   if p_eval_time is null then
      l_end_time := systimestamp at time zone 'UTC';
   else     
      l_end_time := from_tz(cast(p_eval_time as timestamp), nvl(p_time_zone, 'UTC')) at time zone 'UTC';
   end if;  
   select min(l_end_time-minimum_duration-maximum_age)
     into l_start_time
     from table(l_loc_lvl_objs);
   ------------------------------               
   -- retrieve the time series --
   ------------------------------               
   l_ts_units := cwms_util.get_default_units(l_base_parameter_id);
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_ts_crsr,
      p_cwms_ts_id      => l_tsid,
      p_units           => l_ts_units,
      p_start_time      => cast(l_start_time as date),
      p_end_time        => cast(l_end_time as date),
      p_time_zone       => 'UTC',
      p_trim            => 'F',
      p_start_inclusive => 'T',
      p_end_inclusive   => 'T',
      p_previous        => 'T',
      p_next            => 'F',
      p_version_date    => null,
      p_max_version     => 'T',
      p_office_id       => l_office_id);
   loop     
      fetch l_ts_crsr into l_ts_date_time, l_ts_value, l_ts_quality;
      exit when l_ts_crsr%notfound;
      l_ts.extend;
      l_ts(l_ts.count) := ztsv_type(l_ts_date_time, l_ts_value, l_ts_quality);   
   end loop;
   close l_ts_crsr;
   -----------------------                     
   -- return the cursor --
   -----------------------
   open p_cursor for
      select get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id) as indicator_id,
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id) as attribute_id,
             cwms_rounding.round_f(o.attr_value * cuc.factor + cuc.offset, 9) as attribute_value,
             cuc.to_unit_id as attribute_units,
             o.get_indicator_values(
                l_ts,
                l_end_time) as indicator_values
        from table(l_loc_lvl_objs) o,
             cwms_unit_conversion cuc
       where cuc.from_unit_id = nvl(
                o.attr_units_id, 
                cwms_util.get_default_units
                   (nvl(o.attr_parameter_id, o.parameter_id), 
                   l_unit_system))
         and cuc.to_unit_id = cwms_util.get_default_units(
                nvl(o.attr_parameter_id, o.parameter_id), 
                l_unit_system)
    order by get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id),
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id),
             o.attr_value;
end get_level_indicator_values;    
            
--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_max_values
--          
-- Retrieves a time series of the maximum Condition value that is set for each 
-- Location Level Indicator that matches the input parameters.  Each time series 
-- has the same times as the time series defined by p_tsid, p_start_time and
-- p_end_time.  Each date_time in the time series is in the specified time
-- zone. The quality_code of each time series value is set to zero.
--          
-- p_tsid - time series identifier, p_cursor will only include Conditions for 
-- Location Levels that have the same Location, Parameter, and Parameter Type
--          
-- p_start_time - start of the time window for p_tsid, in p_time_zone
--          
-- p_end_time - end of the time window for p_tsid, in p_time_zone
--          
-- p_time_zone - time zone of p_start_time, p_end_time and the date_times of the
-- retrieved time series, 'UTC' if NULL
--          
-- p_specified_level_mask - Specified Level Indicator with optional SQL
-- wildcards (%, _) or filename wildcards (*, ?), '%' if NULL
--          
-- p_indicator_id_mask - Location Level Identifier with optional wildcards, '%'
-- if NULL  
--          
-- p_unit_system - unit system for which to retrieve attribute values, 'EN' or 
-- 'SI', 'SI' if NULL
--          
-- p_office_id - office identifier for p_tsid, user's office identifier if NULL
--          
-- p_cursor has the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values ztsv_array  
--------------------------------------------------------------------------------
procedure get_level_indicator_max_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_start_time           in  date,
   p_end_time             in  date     default null,   -- sysdate if null
   p_time_zone            in  varchar2 default null,   -- 'UTC' if null
   p_specified_level_mask in  varchar2 default null,   -- '%' if null
   p_indicator_id_mask    in  varchar2 default null,   -- '%' if null
   p_unit_system          in  varchar2 default null,   -- 'SI' if null
   p_office_id            in  varchar2 default null)   -- user's office if null
is          
   l_tsid                   varchar2(183) := p_tsid;
   l_office_id              varchar2(16)  := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_specified_level_mask   varchar2(256) := nvl(p_specified_level_mask, '*');
   l_indicator_id_mask      varchar2(256) := nvl(p_indicator_id_mask, '*');
   l_unit_system            varchar2(2)   := nvl(p_unit_system, 'SI');
   l_location_level_id_mask varchar2(423);
   l_base_location_id       varchar2(16);
   l_sub_location_id        varchar2(32);
   l_base_parameter_id      varchar2(16);
   l_sub_parameter_id       varchar2(32);
   l_parameter_type_id      varchar2(16);
   l_interval_id            varchar2(16);
   l_duration_id            varchar2(16);
   l_version_id             varchar2(32);
   l_indicator_codes_crsr   sys_refcursor;
   l_ts_crsr                sys_refcursor;
   l_indicator_code         number(10);
   l_rowid                  rowid;
   l_loc_lvl_objs           loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
   l_ts_units               varchar2(16);
   l_lookback_time          timestamp;
   l_start_time             timestamp;
   l_end_time               timestamp;
   l_ts_date_time           date;
   l_ts_value               binary_double;
   l_ts_quality             number;
   l_ts                     ztsv_array := new ztsv_array();
   l_units_out              varchar2(16);
   l_cwms_ts_id_out         varchar2(183);
begin       
   ------------------------------------------------------------------
   -- open a cursor of all matching location level indicator codes --
   ------------------------------------------------------------------
   cwms_ts.parse_ts(
      l_tsid,
      l_base_location_id,
      l_sub_location_id,
      l_base_parameter_id,
      l_sub_parameter_id,
      l_parameter_type_id,
      l_interval_id,
      l_duration_id,
      l_version_id);
   l_indicator_codes_crsr := cat_loc_lvl_indicator_codes(
      get_loc_lvl_indicator_id(
         l_base_location_id
            || substr('-', 1, length(l_sub_location_id))
            || l_sub_location_id,
         l_base_parameter_id
            || substr('-', 1, length(l_sub_parameter_id))
            || l_sub_parameter_id,
         l_parameter_type_id,
         l_duration_id,
         l_specified_level_mask,
         l_indicator_id_mask),
      '*.*.*',
      l_office_id);
   --------------------------------------------------               
   -- build a table of loc_lvl_indicator_t objects --
   --------------------------------------------------
   loop     
      fetch l_indicator_codes_crsr into l_indicator_code;
      exit when l_indicator_codes_crsr%notfound;
      select rowid 
        into l_rowid
        from at_loc_lvl_indicator 
       where level_indicator_code = l_indicator_code;   
      l_loc_lvl_objs.extend;
      l_loc_lvl_objs(l_loc_lvl_objs.count) := new loc_lvl_indicator_t(l_rowid);
   end loop;
   close l_indicator_codes_crsr;
   -------------------------------------
   -- compute the start and end times --
   -------------------------------------
   l_start_time := from_tz(cast(p_start_time as timestamp), nvl(p_time_zone, 'UTC')) at time zone 'UTC';
   if p_end_time is null then
      l_end_time := systimestamp at time zone 'UTC';
   else     
      l_end_time := from_tz(cast(p_end_time as timestamp), nvl(p_time_zone, 'UTC')) at time zone 'UTC';
   end if;  
   select min(l_start_time-minimum_duration-2*maximum_age)
     into l_lookback_time
     from table(l_loc_lvl_objs);
   ------------------------------               
   -- retrieve the time series --
   ------------------------------               
   l_ts_units := cwms_util.get_default_units(l_base_parameter_id);      
   cwms_ts.retrieve_ts(
      p_at_tsv_rc       => l_ts_crsr,
      p_cwms_ts_id      => l_tsid,
      p_units           => l_ts_units,
      p_start_time      => cast(l_start_time as date),
      p_end_time        => cast(l_end_time as date),
      p_time_zone       => 'UTC',
      p_trim            => 'F',
      p_start_inclusive => 'T',
      p_end_inclusive   => 'T',
      p_previous        => 'T',
      p_next            => 'F',
      p_version_date    => null,
      p_max_version     => 'T',
      p_office_id       => l_office_id);
   loop     
      fetch l_ts_crsr into l_ts_date_time, l_ts_value, l_ts_quality;
      exit when l_ts_crsr%notfound;
      l_ts.extend;
      l_ts_date_time := cast(from_tz(cast(l_ts_date_time as timestamp), 'UTC') at time zone nvl(p_time_zone, 'UTC') as date);
      l_ts(l_ts.count) := ztsv_type(l_ts_date_time, l_ts_value, l_ts_quality);   
   end loop;
   close l_ts_crsr;
   -----------------------                     
   -- return the cursor --
   -----------------------
   open p_cursor for
      select get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id) as indicator_id,
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id) as attribute_id,
             cwms_rounding.round_f(o.attr_value * cuc.factor + cuc.offset, 9) as attribute_value,
             cuc.to_unit_id as attribute_units,
             o.get_max_indicator_values(
                l_ts,
                l_start_time) as indicator_values
        from table(l_loc_lvl_objs) o,
             cwms_unit_conversion cuc
       where cuc.from_unit_id = nvl(
                o.attr_units_id, 
                cwms_util.get_default_units
                   (nvl(o.attr_parameter_id, o.parameter_id), 
                   l_unit_system))
         and cuc.to_unit_id = cwms_util.get_default_units(
                nvl(o.attr_parameter_id, o.parameter_id), 
                l_unit_system)
    order by get_loc_lvl_indicator_id(
                o.location_id,
                o.parameter_id,
                o.parameter_type_id,
                o.duration_id,
                o.specified_level_id,
                o.level_indicator_id),
             get_attribute_id(
                o.attr_parameter_id,
                o.attr_parameter_type_id,
                o.attr_duration_id),
             o.attr_value;
end get_level_indicator_max_values;    
            
function retrieve_location_levels_f(
   p_names       in  varchar2,            
   p_format      in  varchar2,
   p_units       in  varchar2 default null,   
   p_datums      in  varchar2 default null,
   p_start       in  varchar2 default null,
   p_end         in  varchar2 default null, 
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
   return clob
is
   l_results     clob;
   l_date_time   date;
   l_query_time  integer;
   l_format_time integer;
   l_count       integer;
begin
   retrieve_location_levels(
      p_results     => l_results,
      p_date_time   => l_date_time,
      p_query_time  => l_query_time,
      p_format_time => l_format_time, 
      p_count       => l_count,
      p_names       => p_names,            
      p_format      => p_format,
      p_units       => p_units,   
      p_datums      => p_datums,
      p_start       => p_start,
      p_end         => p_end, 
      p_timezone    => p_timezone,
      p_office_id   => p_office_id);
      
   return l_results;
end retrieve_location_levels_f;   
            
procedure retrieve_location_levels(
   p_results        out clob,
   p_date_time      out date,
   p_query_time     out integer,
   p_format_time    out integer, 
   p_count          out integer,
   p_names          in  varchar2 default null,            
   p_format         in  varchar2 default null,
   p_units          in  varchar2 default null,   
   p_datums         in  varchar2 default null,
   p_start          in  varchar2 default null,
   p_end            in  varchar2 default null, 
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null)
is
   type rec_t is record(
      lvl_code    integer, 
      office     varchar2(16), 
      name       varchar2(512), 
      unit       varchar2(16), 
      attr_name  varchar2(128), 
      attr_value binary_double, 
      attr_unit  varchar2(16));
   type rec_tab_t is table of rec_t;
   type idx_t is table of str_tab_t index by pls_integer;
   type bool_t is table of boolean index by varchar2(32767);
   type segment_t is record(first_index integer, last_index integer, interp varchar2(5));
   type seg_tab_t is table of segment_t;
   l_data             clob;  
   l_format           varchar2(16);
   l_names            str_tab_t;
   l_names_sql        str_tab_t; 
   l_units            str_tab_t;
   l_datums           str_tab_t;
   l_start            date;
   l_start_utc        date;
   l_end              date;  
   l_end_utc          date;
   l_timezone         varchar2(28);
   l_office_id        varchar2(16);
   l_parts            str_tab_t; 
   l_unit             varchar2(16);
   l_attr_unit        varchar2(16);
   l_datum            varchar2(16);  
   l_count            pls_integer := 0;
   l_unique_count     pls_integer := 0;
   l_name             varchar2(512);
   l_first            boolean;
   l_ts1              timestamp;
   l_ts2              timestamp;
   l_elapsed_query    interval day (0) to second (6);
   l_elapsed_format   interval day (0) to second (6);
   l_query_time       date; 
   l_attrs            str_tab_t;
   c                  sys_refcursor;
   l_lvlids           rec_tab_t := rec_tab_t();  
   l_lvlids2          idx_t;
   l_used             bool_t;
   l_text             varchar2(32767);
   l_text2            varchar2(32767);
   l_interp           pls_integer;
   l_estimated        boolean;
   l_level_values     ztsv_array_tab;
   l_code             pls_integer;
   l_segments         seg_tab_t;
   l_max_size         integer;
   l_max_time         interval day (0) to second (3);
   l_max_size_msg     varchar2(17) := 'MAX SIZE EXCEEDED';
   l_max_time_msg     varchar2(17) := 'MAX TIME EXCEEDED';
   
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
         l_iso := l_iso || trim(to_char(l_seconds, '0.999')) || 'S';
      end if;
      if l_iso = 'PT' then
         l_iso := l_iso || '0S';
      end if;
      return l_iso;
   end;
begin
   l_query_time := cast(systimestamp at time zone 'UTC' as date);
   l_max_size := to_number(cwms_properties.get_property('CWMS-RADAR', 'results.max-size', '5242880', 'CWMS')); -- 5 MB default
   l_max_time := to_dsinterval(cwms_properties.get_property('CWMS-RADAR', 'query.max-time', '00 00:00:30', 'CWMS')); -- 30 sec default
   ----------------------------
   -- process the parameters --
   ----------------------------
   -----------
   -- names --
   -----------
   if p_names is not null then
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
         cwms_err.raise('INVALID_ITEM', l_format, 'time series response format');
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
   l_office_id := cwms_util.normalize_wildcards(l_office_id);
   if l_names is not null then
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
               cwms_err.raise('INVALID_ITEM', l_datums(i), 'time series response datum');
            end if; 
         end loop;
         l_count := l_datums.count - l_names.count; 
         if l_count > 0 then
            l_datums.trim(l_count);
         elsif l_count < 0 then
            l_datum := l_datums(l_datums.count);
            l_count := -l_count;
            l_datums.extend(l_count);
            for i in 1..l_count loop
               l_datums(l_datums.count - i + 1) := l_datum;
            end loop; 
         end if;
      end if;
   end if;
   -----------
   -- units --
   -----------
   if p_units is null then
      if l_names is null then
         l_unit := 'EN';
      else
         l_units := str_tab_t();
         l_units.extend(l_names.count);
         for i in 1..l_units.count loop
            l_units(i) := 'EN';
         end loop;
      end if;
   else
      l_units := cwms_util.split_text(p_units, '|');
      if l_names is null then
         if l_units.count > 1 or upper(l_units(1)) not in ('EN', 'SI') then
            cwms_err.raise('ERROR', 'P_units must be ''EN'' or ''SI'' if p_names is null');
         end if;
         l_unit := upper(l_units(1));
      else
         l_count := l_units.count - l_names.count; 
         if l_count > 0 then
            l_units.trim(l_count);
         elsif l_count < 0 then
            l_unit := l_units(l_units.count);
            l_count := -l_count;
            l_units.extend(l_count);
            for i in 1..l_count loop
               l_units(l_units.count - i + 1) := l_unit;
            end loop; 
         end if;
      end if;
   end if;   
   -----------------      
   -- time window --
   -----------------
   if p_timezone is null then
      l_timezone := 'UTC';
   else
      l_timezone := cwms_util.get_time_zone_name(trim(p_timezone));
      if l_timezone is null then
         cwms_err.raise('INVALID_ITEM', p_timezone, 'CWMS time zone name');
      end if;
   end if;
   if p_end is null then
      l_end_utc := sysdate;
      l_end     := cwms_util.change_timezone(l_end_utc, 'UTC', l_timezone);
   else
      l_end     := cast(from_tz(cwms_util.to_timestamp(p_end), l_timezone) as date);
      l_end_utc := cwms_util.change_timezone(l_end, l_timezone, 'UTC');
   end if;
   if p_start is null then
      l_start     := l_end - 1;
      l_start_utc := l_end_utc - 1;
   else
      l_start     := cast(from_tz(cwms_util.to_timestamp(p_start), l_timezone) as date);
      l_start_utc := cwms_util.change_timezone(l_start, l_timezone, 'UTC');
   end if;
   -----------------------
   -- retreive the data --
   -----------------------
   dbms_lob.createtemporary(l_data, true);
   begin
      if l_names is null then
         -----------------------------------------
         -- retrieve catalog of location levels --
         -----------------------------------------
         l_ts1 := systimestamp;
         l_elapsed_format := l_ts1 - l_ts1;
         select *
           bulk collect
           into l_lvlids
           from (select ll.location_level_code, 
                        o.office_id,
                        bl.base_location_id
                        ||substr('-', 1, length(pl.sub_location_id))
                        ||pl.sub_location_id
                        ||'.'
                        ||bp1.base_parameter_id
                        ||substr('-', 1, length(p1.sub_parameter_id))
                        ||p1.sub_parameter_id
                        ||'.'
                        ||pt1.parameter_type_id
                        ||'.'
                        ||d1.duration_id
                        ||'.'
                        ||sl.specified_level_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'EN')
                        when l_unit = 'SI' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'SI')
                        else
                          l_unit
                        end,
                        bp2.base_parameter_id
                        ||substr('-', 1, length(p2.sub_parameter_id))
                        ||p2.sub_parameter_id
                        ||substr('.', 1, length(pt2.parameter_type_id))
                        ||pt2.parameter_type_id
                        ||substr('.', length(d2.duration_id))
                        ||d2.duration_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.convert_units(
                              ll.attribute_value,
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'SI'),
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'EN'))
                        else
                           ll.attribute_value
                        end,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'EN')
                        else
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'SI')
                        end
                   from at_location_level ll,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_base_parameter bp1,
                        cwms_base_parameter bp2,
                        at_parameter p1,
                        at_parameter p2,
                        cwms_parameter_type pt1,
                        cwms_parameter_type pt2,
                        cwms_duration d1,
                        cwms_duration d2,
                        at_specified_level sl,
                        cwms_office o
                  where pl.location_code = ll.location_code
                    and p1.parameter_code = ll.parameter_code
                    and pt1.parameter_type_code = ll.parameter_type_code
                    and d1.duration_code = ll.duration_code
                    and sl.specified_level_code = ll.specified_level_code
                    and ll.location_level_date < l_end_utc
                    and (ll.expiration_date is null or 
                         ll.expiration_date > l_start_utc
                        )
                    and (get_next_effective_date(ll.location_level_code) is null or
                         get_next_effective_date(ll.location_level_code) > l_start_utc
                        ) 
                    and bl.base_location_code = pl.base_location_code
                    and bp1.base_parameter_code = p1.base_parameter_code
                    and o.office_code = bl.db_office_code
                    and o.office_id like l_office_id escape '\'
                    and p2.parameter_code(+) = ll.attribute_parameter_code
                    and bp2.base_parameter_code(+) = p2.base_parameter_code
                    and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
                    and d2.duration_code(+) = ll.attribute_duration_code
                 union 
                 select ll.location_level_code, 
                        o.office_id,
                        lga.loc_alias_id
                        ||'.'
                        ||bp1.base_parameter_id
                        ||substr('-', 1, length(p1.sub_parameter_id))
                        ||p1.sub_parameter_id
                        ||'.'
                        ||pt1.parameter_type_id
                        ||'.'
                        ||d1.duration_id
                        ||'.'
                        ||sl.specified_level_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'EN')
                        when l_unit = 'SI' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'SI')
                        else
                          l_unit
                        end,
                        bp2.base_parameter_id
                        ||substr('-', 1, length(p2.sub_parameter_id))
                        ||p2.sub_parameter_id
                        ||substr('.', 1, length(pt2.parameter_type_id))
                        ||pt2.parameter_type_id
                        ||substr('.', length(d2.duration_id))
                        ||d2.duration_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.convert_units(
                              ll.attribute_value,
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'SI'),
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'EN'))
                        else
                           ll.attribute_value
                        end,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'EN')
                        else
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'SI')
                        end
                   from at_location_level ll,
                        at_loc_category lc,
                        at_loc_group lg,
                        at_loc_group_assignment lga,
                        cwms_base_parameter bp1,
                        cwms_base_parameter bp2,
                        at_parameter p1,
                        at_parameter p2,
                        cwms_parameter_type pt1,
                        cwms_parameter_type pt2,
                        cwms_duration d1,
                        cwms_duration d2,
                        at_specified_level sl,
                        cwms_office o
                  where lga.location_code = ll.location_code
                    and p1.parameter_code = ll.parameter_code
                    and pt1.parameter_type_code = ll.parameter_type_code
                    and d1.duration_code = ll.duration_code
                    and sl.specified_level_code = ll.specified_level_code
                    and ll.location_level_date < l_end_utc
                    and (ll.expiration_date is null or 
                         ll.expiration_date > l_start_utc
                        )
                    and (get_next_effective_date(ll.location_level_code) is null or
                         get_next_effective_date(ll.location_level_code) > l_start_utc
                        ) 
                    and lga.loc_alias_id is not null
                    and lg.loc_group_code = lga.loc_group_code
                    and lc.loc_category_code = lg.loc_category_code
                    and lc.loc_category_id = 'Agency Aliases'
                    and bp1.base_parameter_code = p1.base_parameter_code
                    and o.office_code = lga.office_code
                    and o.office_id like l_office_id escape '\'
                    and p2.parameter_code(+) = ll.attribute_parameter_code
                    and bp2.base_parameter_code(+) = p2.base_parameter_code
                    and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
                    and d2.duration_code(+) = ll.attribute_duration_code
                 union
                 select ll.location_level_code, 
                        o.office_id,
                        lga.loc_alias_id
                        ||substr('-', 1, length(pl.sub_location_id))
                        ||pl.sub_location_id
                        ||'.'
                        ||bp1.base_parameter_id
                        ||substr('-', 1, length(p1.sub_parameter_id))
                        ||p1.sub_parameter_id
                        ||'.'
                        ||pt1.parameter_type_id
                        ||'.'
                        ||d1.duration_id
                        ||'.'
                        ||sl.specified_level_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'EN')
                        when l_unit = 'SI' then
                           cwms_util.get_default_units(
                              bp1.base_parameter_id
                              ||substr('-', 1, length(p1.sub_parameter_id))
                              ||p1.sub_parameter_id,
                              'SI')
                        else
                          l_unit
                        end,
                        bp2.base_parameter_id
                        ||substr('-', 1, length(p2.sub_parameter_id))
                        ||p2.sub_parameter_id
                        ||substr('.', 1, length(pt2.parameter_type_id))
                        ||pt2.parameter_type_id
                        ||substr('.', length(d2.duration_id))
                        ||d2.duration_id,
                        case
                        when l_unit = 'EN' then
                           cwms_util.convert_units(
                              ll.attribute_value,
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'SI'),
                              cwms_util.get_default_units(
                                 bp2.base_parameter_id
                                 ||substr('-', 1, length(p2.sub_parameter_id))
                                 ||p2.sub_parameter_id,
                                 'EN'))
                        else
                           ll.attribute_value
                        end,
                        case
                        when l_unit = 'EN' then
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'EN')
                        else
                           cwms_util.get_default_units(
                              bp2.base_parameter_id
                              ||substr('-', 1, length(p2.sub_parameter_id))
                              ||p2.sub_parameter_id,
                              'SI')
                        end
                   from at_location_level ll,
                        at_loc_category lc,
                        at_loc_group lg,
                        at_loc_group_assignment lga,
                        at_physical_location pl,
                        at_base_location bl,
                        cwms_base_parameter bp1,
                        cwms_base_parameter bp2,
                        at_parameter p1,
                        at_parameter p2,
                        cwms_parameter_type pt1,
                        cwms_parameter_type pt2,
                        cwms_duration d1,
                        cwms_duration d2,
                        at_specified_level sl,
                        cwms_office o
                  where pl.location_code = ll.location_code
                    and pl.sub_location_id is not null
                    and bl.base_location_code = pl.base_location_code
                    and bl.base_location_code = lga.location_code
                    and p1.parameter_code = ll.parameter_code
                    and pt1.parameter_type_code = ll.parameter_type_code
                    and d1.duration_code = ll.duration_code
                    and sl.specified_level_code = ll.specified_level_code
                    and ll.location_level_date < l_end_utc
                    and (ll.expiration_date is null or 
                         ll.expiration_date > l_start_utc
                        )
                    and (get_next_effective_date(ll.location_level_code) is null or
                         get_next_effective_date(ll.location_level_code) > l_start_utc
                        ) 
                    and lga.loc_alias_id is not null
                    and lg.loc_group_code = lga.loc_group_code
                    and lc.loc_category_code = lg.loc_category_code
                    and lc.loc_category_id = 'Agency Aliases'
                    and bp1.base_parameter_code = p1.base_parameter_code
                    and o.office_code = lga.office_code
                    and o.office_id like l_office_id escape '\'
                    and p2.parameter_code(+) = ll.attribute_parameter_code
                    and bp2.base_parameter_code(+) = p2.base_parameter_code
                    and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
                    and d2.duration_code(+) = ll.attribute_duration_code
                )
          order by 2, 3, 5, 6;                
         l_ts2 := systimestamp;
         l_elapsed_query := l_ts2 - l_ts1;
         if l_elapsed_query > l_max_time then
            cwms_err.raise('ERROR', l_max_time_msg);
         end if;
         for i in 1..l_lvlids.count loop
            if not l_lvlids2.exists(l_lvlids(i).lvl_code) then
               l_lvlids2(l_lvlids(i).lvl_code) := str_tab_t();
            end if;
            l_lvlids2(l_lvlids(i).lvl_code).extend;
            l_lvlids2(l_lvlids(i).lvl_code)(l_lvlids2(l_lvlids(i).lvl_code).count) := l_lvlids(i).name;
         end loop;
         l_unique_count := l_lvlids2.count;
         l_ts2 := systimestamp;
         l_elapsed_query := l_ts2 - l_ts1;
         if l_elapsed_query > l_max_time then
            cwms_err.raise('ERROR', l_max_time_msg);
         end if;
         l_ts1 := systimestamp;
         
         case
         when l_format = 'XML' then
            -----------------
            -- XML Catalog --
            -----------------
            cwms_util.append(
               l_data, 
               '<location-levels-catalog><!-- Catalog of location levels that are effective between '
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||' and '
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||' -->');
            l_count := 0;
            for i in 1..l_lvlids.count loop
               if i = 1 
                  or l_lvlids(i).office != l_lvlids(i-1).office
                  or l_lvlids(i).name != l_lvlids(i-1).name
                  or nvl(l_lvlids(i).attr_name, '@') != nvl(l_lvlids(i-1).attr_name, '@')
                  or nvl(cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777'), '@') != nvl(cwms_rounding.round_dt_f(l_lvlids(i-1).attr_value, '7777777777'), '@')
                  or nvl(l_lvlids(i).attr_unit, '@') != nvl(l_lvlids(i-1).attr_unit, '@') 
               then
                  l_count := l_count + 1;
                  cwms_util.append(
                     l_data,
                     '<location-level><office>'
                     ||l_lvlids(i).office
                     ||'</office><name>'
                     ||dbms_xmlgen.convert(l_lvlids(i).name, dbms_xmlgen.entity_encode)
                     ||'</name><alternate-names>'); 
                  for j in 1..l_lvlids2(l_lvlids(i).lvl_code).count loop
                     if l_lvlids2(l_lvlids(i).lvl_code)(j) != l_lvlids(i).name then
                        cwms_util.append(
                           l_data,
                           '<name>'
                           ||dbms_xmlgen.convert(l_lvlids2(l_lvlids(i).lvl_code)(j), dbms_xmlgen.entity_encode)
                           ||'</name>');
                     end if;
                  end loop;
                  cwms_util.append(l_data, l_text||'</alternate-names>');
                  if l_lvlids(i).attr_name is not null then
                     cwms_util.append(
                        l_data, 
                        '<attribute><name>'
                        ||l_lvlids(i).attr_name
                        ||'</name><value unit="'
                        ||l_lvlids(i).attr_unit
                        ||'">'
                        ||cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777')
                        ||'</value></attribute>');
                  end if;
                  cwms_util.append(l_data, '</location-level>');
               end if;
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
            cwms_util.append(l_data, '</location-levels-catalog>');
         when l_format = 'JSON' then
            ------------------
            -- JSON Catalog --
            ------------------
            cwms_util.append(
               l_data, 
               '{"location-levels-catalog":{"comment":"Catalog of location levels that are effective between '
               ||cwms_util.get_xml_time(l_start, l_timezone)
               ||' and '
               ||cwms_util.get_xml_time(l_end, l_timezone)
               ||'","location-levels":[');
            l_count := 0;
            for i in 1..l_lvlids.count loop
               if i = 1 
                  or l_lvlids(i).office != l_lvlids(i-1).office
                  or l_lvlids(i).name != l_lvlids(i-1).name
                  or nvl(l_lvlids(i).attr_name, '@') != nvl(l_lvlids(i-1).attr_name, '@')
                  or nvl(cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777'), '@') != nvl(cwms_rounding.round_dt_f(l_lvlids(i-1).attr_value, '7777777777'), '@')
                  or nvl(l_lvlids(i).attr_unit, '@') != nvl(l_lvlids(i-1).attr_unit, '@') 
               then
                  l_count := l_count + 1;
                  cwms_util.append(
                     l_data,
                     case i when 1 then '{"office":"' else ',{"office":"' end
                     ||l_lvlids(i).office
                     ||'","name":"'
                     ||replace(l_lvlids(i).name, '"', '\"')
                     ||'","alternate-names":[');
                  l_first := true;   
                  for j in 1..l_lvlids2(l_lvlids(i).lvl_code).count loop
                     if l_lvlids2(l_lvlids(i).lvl_code)(j) != l_lvlids(i).name then
                        case l_first
                        when true then
                           l_first := false;
                           cwms_util.append(l_data, '"'||replace(l_lvlids2(l_lvlids(i).lvl_code)(j), '"', '\"')||'"');
                        else
                           cwms_util.append(l_data, ',"'||replace(l_lvlids2(l_lvlids(i).lvl_code)(j), '"', '\"')||'"');
                        end case;
                     end if;
                  end loop;
                  cwms_util.append(l_data, ']');
                  if l_lvlids(i).attr_name is not null then
                     cwms_util.append(
                     l_data, 
                     ',"attribute":{"name":"'
                     ||replace(l_lvlids(i).attr_name, '"', '\"')
                     ||'","unit":"'
                     ||replace(l_lvlids(i).attr_unit, '"', '\"')
                     ||'","value":'
                     ||regexp_replace(cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777'), '^\.', '0.')
                     ||'}');
                  end if;
                  cwms_util.append(l_data, l_text||'}');
               end if;
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
            cwms_util.append(l_data, ']}}');
         when l_format in ('TAB', 'CSV') then
            ------------------------
            -- TAB or CSV Catalog --
            ------------------------
            l_count := 0;
            cwms_util.append(
               l_data, 
               '# Catalog of location levels that are effective between '
               ||to_char(l_start, 'dd-Mon-yyyy hh24:mi')
               ||' and '
               ||to_char(l_end, 'dd-Mon-yyyy hh24:mi')
               ||' '
               ||l_timezone
               ||chr(10)
               ||chr(10)
               ||'#Office'
               ||chr(9)
               ||'Name'
               ||chr(9)
               ||'Attribute'
               ||chr(9)
               ||'Alternate Names'
               ||chr(10));
            for i in 1..l_lvlids.count loop
               if i = 1 or l_text != l_lvlids(i).office
                  ||chr(9)
                  ||l_lvlids(i).name
                  ||chr(9)
                  ||case l_lvlids(i).attr_name is not null
                    when true then l_lvlids(i).attr_name
                                   ||'='
                                   ||cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777')
                                   ||' '
                                   ||l_lvlids(i).attr_unit
                    else null
                    end
               then
                  l_count := l_count + 1;
                  l_text := l_lvlids(i).office
                  ||chr(9)
                  ||l_lvlids(i).name
                  ||chr(9)
                  ||case l_lvlids(i).attr_name is not null
                    when true then l_lvlids(i).attr_name
                                   ||'='
                                   ||cwms_rounding.round_dt_f(l_lvlids(i).attr_value, '7777777777')
                                   ||' '
                                   ||l_lvlids(i).attr_unit
                    else null
                    end;
                  cwms_util.append(l_data, l_text);
                     for j in 1..l_lvlids2(l_lvlids(i).lvl_code).count loop
                        if l_lvlids2(l_lvlids(i).lvl_code)(j) != l_lvlids(i).name then
                           cwms_util.append(l_data, chr(9)||l_lvlids2(l_lvlids(i).lvl_code)(j));
                        end if;
                     end loop;
                  cwms_util.append(l_data, chr(10));
               end if;
               if dbms_lob.getlength(l_data) > l_max_size then
                  cwms_err.raise('ERROR', l_max_size_msg);
               end if;
            end loop;
         end case;
         p_results := l_data;
         
         l_ts2 := systimestamp;
         l_elapsed_format := l_ts2 - l_ts1;
      else
         --------------------------------------------------------
         -- retrieve location level values data in time window --
         --------------------------------------------------------
         l_ts1 := systimestamp;
         l_elapsed_query := l_ts1 - l_ts1;
         l_elapsed_format := l_elapsed_query;
         l_names_sql := str_tab_t();
         l_names_sql.extend(l_names.count);
         l_count := 0;
         <<names>>
         for i in 1..l_names.count loop
            l_names_sql(i) := upper(cwms_util.normalize_wildcards(l_names(i)));
            l_parts := cwms_util.split_text(l_units(i), ';');
            l_unit := case
                      when upper(l_parts(1)) in ('EN', 'SI') then upper(l_parts(1))
                      else l_parts(1)
                      end;
            l_attr_unit := case l_parts.count > 1
                           when true then l_parts(2)
                           else l_parts(1)
                           end;
            select distinct 
                   ll.location_level_code, 
                   o.office_id,
                   bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id,
                   case
                   when l_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'EN')
                   when l_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'SI')
                   else
                     l_unit
                   end,
                   bp2.base_parameter_id
                   ||substr('-', 1, length(p2.sub_parameter_id))
                   ||p2.sub_parameter_id
                   ||substr('.', 1, length(pt2.parameter_type_id))
                   ||pt2.parameter_type_id
                   ||substr('.', length(d2.duration_id))
                   ||d2.duration_id,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'EN'))
                   when l_attr_unit = 'SI' then
                      ll.attribute_value
                   else
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         l_attr_unit)
                   end,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'EN')
                   when l_attr_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'SI')
                   else
                     l_attr_unit
                   end
              bulk collect
              into l_lvlids
              from at_location_level ll,
                   at_physical_location pl,
                   at_base_location bl,
                   cwms_base_parameter bp1,
                   cwms_base_parameter bp2,
                   at_parameter p1,
                   at_parameter p2,
                   cwms_parameter_type pt1,
                   cwms_parameter_type pt2,
                   cwms_duration d1,
                   cwms_duration d2,
                   at_specified_level sl,
                   cwms_office o
             where upper(bl.base_location_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id) like upper(l_names_sql(i)) escape '\'
               and pl.location_code = ll.location_code
               and p1.parameter_code = ll.parameter_code
               and pt1.parameter_type_code = ll.parameter_type_code
               and d1.duration_code = ll.duration_code
               and sl.specified_level_code = ll.specified_level_code
               and ll.location_level_date < cwms_util.change_timezone(l_end, l_timezone, 'UTC')
               and (ll.expiration_date is null or 
                    ll.expiration_date > cwms_util.change_timezone(l_start, l_timezone, 'UTC')
                   )
               and (get_next_effective_date(ll.location_level_code, l_timezone) is null or
                    get_next_effective_date(ll.location_level_code, l_timezone) > l_start
                   ) 
               and bl.base_location_code = pl.base_location_code
               and bp1.base_parameter_code = p1.base_parameter_code
               and o.office_code = bl.db_office_code
               and o.office_id like l_office_id escape '\'
               and p2.parameter_code(+) = ll.attribute_parameter_code
               and bp2.base_parameter_code(+) = p2.base_parameter_code
               and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
               and d2.duration_code(+) = ll.attribute_duration_code
            union  
            select distinct
                   ll.location_level_code, 
                   o.office_id,
                   lga.loc_alias_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id,
                   case
                   when l_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'EN')
                   when l_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'SI')
                   else
                     l_unit
                   end,
                   bp2.base_parameter_id
                   ||substr('-', 1, length(p2.sub_parameter_id))
                   ||p2.sub_parameter_id
                   ||substr('.', 1, length(pt2.parameter_type_id))
                   ||pt2.parameter_type_id
                   ||substr('.', length(d2.duration_id))
                   ||d2.duration_id,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'EN'))
                   when l_attr_unit = 'SI' then
                      ll.attribute_value
                   else
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         l_attr_unit)
                   end,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'EN')
                   when l_attr_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'SI')
                   else
                     l_attr_unit
                   end
              from at_location_level ll,
                   at_loc_category lc,
                   at_loc_group lg,
                   at_loc_group_assignment lga,
                   cwms_base_parameter bp1,
                   cwms_base_parameter bp2,
                   at_parameter p1,
                   at_parameter p2,
                   cwms_parameter_type pt1,
                   cwms_parameter_type pt2,
                   cwms_duration d1,
                   cwms_duration d2,
                   at_specified_level sl,
                   cwms_office o
             where upper(lga.loc_alias_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id) like upper(l_names_sql(i)) escape '\'
               and lga.location_code = ll.location_code
               and p1.parameter_code = ll.parameter_code
               and pt1.parameter_type_code = ll.parameter_type_code
               and d1.duration_code = ll.duration_code
               and sl.specified_level_code = ll.specified_level_code
               and ll.location_level_date < cwms_util.change_timezone(l_end, l_timezone, 'UTC')
               and (ll.expiration_date is null or 
                    ll.expiration_date > cwms_util.change_timezone(l_start, l_timezone, 'UTC')
                   )
               and (get_next_effective_date(ll.location_level_code, l_timezone) is null or
                    get_next_effective_date(ll.location_level_code, l_timezone) > l_start
                   ) 
               and lga.loc_alias_id is not null
               and lg.loc_group_code = lga.loc_group_code
               and lc.loc_category_code = lg.loc_category_code
               and lc.loc_category_id = 'Agency Aliases'
               and bp1.base_parameter_code = p1.base_parameter_code
               and o.office_code = lga.office_code
               and o.office_id like l_office_id escape '\'
               and p2.parameter_code(+) = ll.attribute_parameter_code
               and bp2.base_parameter_code(+) = p2.base_parameter_code
               and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
               and d2.duration_code(+) = ll.attribute_duration_code
            union  
            select distinct
                   ll.location_level_code, 
                   o.office_id,
                   lga.loc_alias_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id,
                   case
                   when l_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'EN')
                   when l_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp1.base_parameter_id
                         ||substr('-', 1, length(p1.sub_parameter_id))
                         ||p1.sub_parameter_id,
                         'SI')
                   else
                     l_unit
                   end,
                   bp2.base_parameter_id
                   ||substr('-', 1, length(p2.sub_parameter_id))
                   ||p2.sub_parameter_id
                   ||substr('.', 1, length(pt2.parameter_type_id))
                   ||pt2.parameter_type_id
                   ||substr('.', length(d2.duration_id))
                   ||d2.duration_id,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'EN'))
                   when l_attr_unit = 'SI' then
                      ll.attribute_value
                   else
                      cwms_util.convert_units(
                         ll.attribute_value,
                         cwms_util.get_default_units(
                            bp2.base_parameter_id
                            ||substr('-', 1, length(p2.sub_parameter_id))
                            ||p2.sub_parameter_id,
                            'SI'),
                         l_attr_unit)
                   end,
                   case
                   when l_attr_unit = 'EN' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'EN')
                   when l_attr_unit = 'SI' then
                      cwms_util.get_default_units(
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id,
                         'SI')
                   else
                     l_attr_unit
                   end
              from at_location_level ll,
                   at_loc_category lc,
                   at_loc_group lg,
                   at_loc_group_assignment lga,
                   at_physical_location pl,
                   at_base_location bl,
                   cwms_base_parameter bp1,
                   cwms_base_parameter bp2,
                   at_parameter p1,
                   at_parameter p2,
                   cwms_parameter_type pt1,
                   cwms_parameter_type pt2,
                   cwms_duration d1,
                   cwms_duration d2,
                   at_specified_level sl,
                   cwms_office o
             where upper(lga.loc_alias_id
                   ||substr('-', 1, length(pl.sub_location_id))
                   ||pl.sub_location_id
                   ||'.'
                   ||bp1.base_parameter_id
                   ||substr('-', 1, length(p1.sub_parameter_id))
                   ||p1.sub_parameter_id
                   ||'.'
                   ||pt1.parameter_type_id
                   ||'.'
                   ||d1.duration_id
                   ||'.'
                   ||sl.specified_level_id) like upper(l_names_sql(i)) escape '\'
               and pl.location_code = ll.location_code
               and pl.sub_location_id is not null
               and bl.base_location_code = pl.base_location_code
               and bl.base_location_code = lga.location_code
               and p1.parameter_code = ll.parameter_code
               and pt1.parameter_type_code = ll.parameter_type_code
               and d1.duration_code = ll.duration_code
               and sl.specified_level_code = ll.specified_level_code
               and ll.location_level_date < cwms_util.change_timezone(l_end, l_timezone, 'UTC')
               and (ll.expiration_date is null or 
                    ll.expiration_date > cwms_util.change_timezone(l_start, l_timezone, 'UTC')
                   )
               and (get_next_effective_date(ll.location_level_code, l_timezone) is null or
                    get_next_effective_date(ll.location_level_code, l_timezone) > l_start
                   ) 
               and lga.loc_alias_id is not null
               and lg.loc_group_code = lga.loc_group_code
               and lc.loc_category_code = lg.loc_category_code
               and lc.loc_category_id = 'Agency Aliases'
               and bp1.base_parameter_code = p1.base_parameter_code
               and o.office_code = lga.office_code
               and o.office_id like l_office_id escape '\'
               and p2.parameter_code(+) = ll.attribute_parameter_code
               and bp2.base_parameter_code(+) = p2.base_parameter_code
               and pt2.parameter_type_code(+) = ll.attribute_parameter_type_code
               and d2.duration_code(+) = ll.attribute_duration_code
             order by 2, 3, 5, 6;
             
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
      
            l_lvlids2.delete;      
            for i in 1..l_lvlids.count loop
               if not l_lvlids2.exists(l_lvlids(i).lvl_code) then
                  l_parts := cwms_util.split_text(l_lvlids(i).name, '.');
                  l_code := cwms_loc.get_location_code(l_lvlids(i).office, l_parts(1));
                  select location_id||'.'||l_parts(2)||'.'||l_parts(3)||'.'||l_parts(4)||'.'||l_parts(5)
                    bulk collect
                    into l_lvlids2(l_lvlids(i).lvl_code)
                    from (select location_id
                            from (select bl.base_location_id
                                         ||substr('-', 1, length(pl.sub_location_id))
                                         ||pl.sub_location_id as location_id
                                    from at_physical_location pl,
                                         at_base_location bl
                                   where pl.location_code = l_code
                                     and bl.base_location_code = pl.base_location_code
                                  union
                                  select loc_alias_id as location_id
                                    from at_loc_group_assignment lga,
                                         at_loc_group lg,
                                         at_loc_category lc
                                   where lga.location_code = l_code        
                                     and lg.loc_group_code = lga.loc_group_code
                                     and lc.loc_category_code = lg.loc_category_code
                                     and lc.loc_category_id = 'Agency Aliases'
                                  union
                                  select loc_alias_id
                                         ||substr('-', 1, length(pl.sub_location_id))
                                         ||pl.sub_location_id as location_id
                                    from at_physical_location pl,
                                         at_base_location bl,
                                         at_loc_group_assignment lga,
                                         at_loc_group lg,
                                         at_loc_category lc
                                   where pl.location_code = l_code
                                     and bl.base_location_code = pl.base_location_code
                                     and lga.location_code = bl.base_location_code        
                                     and lg.loc_group_code = lga.loc_group_code
                                     and lc.loc_category_code = lg.loc_category_code
                                     and lc.loc_category_id = 'Agency Aliases'
                                 )
                           order by 1
                         );
               end if;
            end loop;
            l_unique_count := l_unique_count + l_lvlids2.count;
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
      
            l_level_values := ztsv_array_tab();
            l_level_values.extend(l_lvlids.count);
            <<levels>>
            for j in 1..l_lvlids.count loop
               l_name:= l_lvlids(j).name||'/'||l_lvlids(j).attr_name||'/'||l_lvlids(j).attr_value||'/'||l_lvlids(j).attr_unit;
               if l_used.exists(l_name) then
                  continue levels;
               end if;
               l_used(l_name) := true;
               l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
               if instr(upper(l_parts(2)), 'ELEV') = 1 then
                  l_datum := case
                             when l_datums(i) != 'NATIVE' then l_datums(i)
                             else cwms_loc.get_local_vert_datum_name_f(l_parts(1), l_lvlids(j).office)
                             end;
               else
                  l_datum := null;
               end if;
               l_level_values(j) := retrieve_location_level_values(
                  l_lvlids(j).name,
                  case
                  when l_datum is null then l_lvlids(j).unit
                  else 'U='||l_lvlids(j).unit||'|V='||l_datum
                  end,
                  l_start,
                  l_end,
                  l_lvlids(j).attr_name,
                  l_lvlids(j).attr_value,
                  l_lvlids(j).attr_unit,
                  l_timezone,
                  l_lvlids(j).office);
            end loop;
            
            l_ts2 := systimestamp;
            l_elapsed_query := l_ts2 - l_ts1;
            if l_elapsed_query > l_max_time then
               cwms_err.raise('ERROR', l_max_time_msg);
            end if;
            l_ts1 := systimestamp;
      
            case
            when l_format = 'XML' then
               --------------
               -- XML Data --
               --------------
               for j in 1..l_lvlids.count loop
                  if l_level_values(j) is not null then
                     l_count := l_count + 1;
                     l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_name := cwms_loc.get_location_vertical_datum(l_parts(1), l_lvlids(j).office);
                        case
                        when l_name is null then
                           l_datum := 'unknown';
                           l_estimated := false;
                        when l_datums(i) in ('NATIVE', l_name) then
                           l_datum := l_name;
                           l_estimated := false;
                        else
                           l_datum := l_datums(i);
                           l_estimated := cwms_loc.is_vert_datum_offset_estimated(
                              l_parts(1),
                              l_name,
                              l_datum,
                              l_lvlids(j).office) = 'T';
                        end case;
                     else
                        l_datum := null;
                     end if;
                     if l_count = 1 then
                        cwms_util.append(l_data, '<location-levels>');
                     end if;
                     cwms_util.append(
                        l_data,
                        '<location-level><office>'
                        ||l_lvlids(j).office
                        ||'</office><name>'
                        ||l_lvlids(j).name
                        ||'</name><alternate-names>');
                     for k in 1..l_lvlids2(l_lvlids(j).lvl_code).count loop
                        if l_lvlids2(l_lvlids(j).lvl_code)(k) != l_lvlids(j).name then
                           cwms_util.append(
                              l_data,
                              '<name>'
                              ||l_lvlids2(l_lvlids(j).lvl_code)(k)
                              ||'</name>');
                        end if;
                     end loop;
                     if l_lvlids(j).attr_name is not null then
                        cwms_util.append(
                           l_data,
                           '<attribute><name>'
                           ||l_lvlids(j).attr_name
                           ||'</name>'
                           ||'<value unit="'
                           ||l_lvlids(j).attr_unit
                           ||'">'
                           ||cwms_rounding.round_dt_f(l_lvlids(j).attr_value, '7777777777')
                           ||'</value></attribute>');
                     end if;
                     cwms_util.append(
                        l_data,
                        '</alternate-names><values unit="'
                        ||l_lvlids(j).unit
                        ||'"');
                     if l_datum is not null then
                        cwms_util.append(
                           l_data,
                           ' datum="'
                           ||l_datum
                           ||'" estimate='
                           ||case l_estimated when true then '"true"' else '"false"' end);
                     end if;
                     cwms_util.append(l_data, '>');
                     l_segments := seg_tab_t();
                     l_interp := -1;
                     for k in 1..l_level_values(j).count loop
                        if l_level_values(j)(k).quality_code != l_interp then
                           l_segments.extend;
                           l_segments(l_segments.count).first_index := k;
                           l_segments(l_segments.count).interp := case when l_level_values(j)(k).quality_code = 0 then 'false' else 'true' end;
                           l_interp := l_level_values(j)(k).quality_code;
                        end if;
                        l_segments(l_segments.count).last_index := k;
                     end loop;
                     for k in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           '<segment position="'
                           ||k
                           ||'" interpolate="'
                           ||l_segments(k).interp
                           ||'">'
                           ||chr(10));
                        for m in l_segments(k).first_index..l_segments(k).last_index loop
                           continue when m > l_segments(k).first_index
                                     and m < l_segments(k).last_index
                                     and l_level_values(j)(m).value = l_level_values(j)(m-1).value  
                                     and l_level_values(j)(m).value = l_level_values(j)(m+1).value;  
                           cwms_util.append(
                              l_data,
                              cwms_util.get_xml_time(l_level_values(j)(m).date_time, l_timezone)
                              ||' '
                              ||regexp_replace(cwms_rounding.round_dt_f(l_level_values(j)(m).value, '7777777777'), '^\.', '0.')
                              ||chr(10));
                        end loop;
                        cwms_util.append(l_data, '</segment>');
                     end loop;
                     cwms_util.append(l_data, '</values></location-level>');
                  end if;
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            when l_format = 'JSON' then
               ---------------
               -- JSON Data --
               ---------------
               for j in 1..l_lvlids.count loop
                  if l_level_values(j) is not null then
                     l_count := l_count + 1;
                     l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_name := cwms_loc.get_location_vertical_datum(l_parts(1), l_lvlids(j).office);
                        case
                        when l_name is null then
                           l_datum := 'unknown';
                           l_estimated := false;
                        when l_datums(i) in ('NATIVE', l_name) then
                           l_datum := l_name;
                           l_estimated := false;
                        else
                           l_datum := l_datums(i);
                           l_estimated := cwms_loc.is_vert_datum_offset_estimated(
                              l_parts(1),
                              l_name,
                              l_datum,
                              l_lvlids(j).office) = 'T';
                        end case;
                     else
                        l_datum := null;
                     end if;
                     if l_count = 1 then
                        cwms_util.append(l_data, '{"location-levels":{"location-levels":[');
                     end if;
                     cwms_util.append(
                        l_data,
                        case when l_count=1 then '{"office":"' else ',{"office":"' end
                        ||l_lvlids(j).office
                        ||'","name":"'
                        ||l_lvlids(j).name
                        ||'","alternate-names":[');
                     l_first := true;
                     for k in 1..l_lvlids2(l_lvlids(j).lvl_code).count loop
                        if l_lvlids2(l_lvlids(j).lvl_code)(k) != l_lvlids(j).name then
                           cwms_util.append(
                              l_data, 
                              case l_first when true then '"' else ',"' end
                              ||l_lvlids2(l_lvlids(j).lvl_code)(k)
                              ||'"');
                           l_first := false;
                        end if;
                     end loop;
                     cwms_util.append(l_data, ']');
                     if l_lvlids(j).attr_name is not null then
                        cwms_util.append(
                           l_data, 
                           ',"attribute":{"name":"'
                           ||l_lvlids(j).attr_name
                           ||'","unit":"'
                           ||l_lvlids(j).attr_unit
                           ||'","value":'
                           ||regexp_replace(cwms_rounding.round_dt_f(l_lvlids(j).attr_value, '7777777777'), '^\.', '0.')
                           ||'}');
                     end if;          
                     cwms_util.append(
                        l_data,
                        ',"values":{"parameter":"'
                        ||cwms_util.split_text(l_lvlids(j).name, 2, '.')
                        ||' ('
                        ||l_lvlids(j).unit
                        ||case l_datum is null
                          when true then ')"'
                          else case l_estimated
                               when true then ' '||l_datum||' estimated)"'
                               else ' '||l_datum||')"'
                               end
                          end);
                     l_segments := seg_tab_t();
                     l_interp := -1;
                     for k in 1..l_level_values(j).count loop
                        if l_level_values(j)(k).quality_code != l_interp then
                           l_segments.extend;
                           l_segments(l_segments.count).first_index := k;
                           l_segments(l_segments.count).interp := case when l_level_values(j)(k).quality_code = 0 then 'false' else 'true' end;
                           l_interp := l_level_values(j)(k).quality_code;
                        end if;
                        l_segments(l_segments.count).last_index := k;
                     end loop;
                     cwms_util.append(l_data, ',"segments":[');
                     for k in 1..l_segments.count loop
                        cwms_util.append(
                           l_data,
                           '{"interpolate":"'
                           ||l_segments(k).interp
                           ||'","values":[');
                        for m in l_segments(k).first_index..l_segments(k).last_index loop
                           continue when m > l_segments(k).first_index
                                     and m < l_segments(k).last_index
                                     and l_level_values(j)(m).value = l_level_values(j)(m-1).value  
                                     and l_level_values(j)(m).value = l_level_values(j)(m+1).value;  
                           cwms_util.append(
                              l_data,
                              case m when 1 then '["' else ',["' end
                              ||cwms_util.get_xml_time(l_level_values(j)(m).date_time, l_timezone)
                              ||'",'
                              ||regexp_replace(cwms_rounding.round_dt_f(l_level_values(j)(m).value, '7777777777'), '^\.', '0.')
                              ||']');
                        end loop;
                        cwms_util.append(l_data, ']}');
                     end loop;
                     cwms_util.append(l_data, ']}}');
                  end if;
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            when l_format in ('TAB', 'CSV') then
               ---------------------
               -- TAB or CSV Data --
               ---------------------
               cwms_util.append(
                  l_data, 
                  '#Office'
                  ||chr(9)
                  ||'Name'
                  ||chr(9)
                  ||'Attribute'
                  ||chr(9)
                  ||'Alternate Names'
                  ||chr(10));
               for j in 1..l_lvlids.count loop
                  if l_level_values(j) is not null then
                     l_count := l_count + 1;
                     l_parts := cwms_util.split_text(l_lvlids(j).name, '.');
                     if instr(upper(l_parts(2)), 'ELEV') = 1 then
                        l_name := cwms_loc.get_location_vertical_datum(l_parts(1), l_lvlids(j).office);
                        case
                        when l_name is null then
                           l_datum := null;
                        when l_datums(i) in ('NATIVE', l_name) then
                           l_datum := l_name;
                        else
                           l_datum := l_datums(i);
                           if cwms_loc.is_vert_datum_offset_estimated(
                              l_parts(1),
                              l_name,
                              l_datum,
                              l_lvlids(j).office) = 'T'
                           then
                              l_datum := l_datum||' estimated';
                           end if;
                        end case;
                     else
                        l_datum := null;
                     end if;
                     cwms_util.append(
                        l_data,
                        chr(10)
                        ||l_lvlids(j).office
                        ||chr(9)
                        ||l_lvlids(j).name
                        ||chr(9)
                        ||case l_lvlids(j).attr_name is not null
                          when true then l_lvlids(j).attr_name
                                         ||'='
                                         ||trim(cwms_rounding.round_dt_f(l_lvlids(j).attr_value, '7777777777')
                                                ||' '
                                                ||l_lvlids(j).attr_unit)
                                                ||case instr(nvl(l_lvlids(j).attr_unit, '@'), 'Elev')
                                                  when 1 then l_datum
                                                  else null
                                                  end
                          else null
                          end);
                     if l_lvlids2.exists(l_lvlids(j).lvl_code) then
                        for k in 1..l_lvlids2(l_lvlids(j).lvl_code).count loop
                           if l_lvlids2(l_lvlids(j).lvl_code)(k) != l_lvlids(j).name then
                              cwms_util.append(l_data, chr(9)||l_lvlids2(l_lvlids(j).lvl_code)(k));
                           end if;
                        end loop;
                     end if;
                     cwms_util.append(l_data, chr(10));
                     l_interp := null;
                     for k in 1..l_level_values(j).count loop
                        if l_level_values(j)(k).value is not null and l_level_values(j)(k).quality_code != nvl(l_interp, -1) then
                           cwms_util.append(
                              l_data,
                              '#Segment'
                              ||chr(9)
                              ||'Interpolate='
                              ||case 
                                when l_level_values(j)(k).quality_code = 0 then 'False'
                                else 'True'
                                end
                              ||chr(10)
                              ||'#Date-Time '
                              ||l_timezone
                              ||chr(9)
                              ||cwms_util.split_text(l_lvlids(j).name, 2, '.')
                              || ' ('
                              ||l_lvlids(j).unit
                              ||case instr(cwms_util.split_text(l_lvlids(j).name, 2, '.'), 'Elev')
                                when 1 then
                                   case l_datum is not null
                                   when true then ' '||l_datum
                                   else null
                                   end
                                else null
                                end
                              ||')'  
                              ||chr(10));
                        end if;
                        if l_level_values(j)(k).value is null then
                           l_interp := null;
                        else
                           cwms_util.append(
                              l_data,
                              to_char(l_level_values(j)(k).date_time, 'dd-Mon-yyyy hh24:mi')
                              ||chr(9)
                              ||cwms_rounding.round_dt_f(l_level_values(j)(k).value, '7777777777')||chr(10));
                        end if;
                        l_interp := case
                                    when l_level_values(j)(k).value is null then null
                                    else l_level_values(j)(k).quality_code
                                    end;
                     end loop;
                  end if;
                  if dbms_lob.getlength(l_data) > l_max_size then
                     cwms_err.raise('ERROR', l_max_size_msg);
                  end if;
               end loop;
            end case;
            
            l_ts2 := systimestamp;
            l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
            l_ts1 := systimestamp;
         end loop;
      end if;
   exception
      when others then 
         case
         when instr(sqlerrm, l_max_time_msg) > 0 then
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               if l_names is null then
                  cwms_util.append(l_data, '<location-levels-catalog><error>Query exceeded maximum time of '||l_max_time||'</error></location-levels-catalog>');
               else
                  cwms_util.append(l_data, '<location-levels><error>Query exceeded maximum time of '||l_max_time||'</error></location-levels>');
               end if;
            when 'JSON' then
               if l_names is null then
                  cwms_util.append(l_data, '{"location-levels-catalog":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
               else
                  cwms_util.append(l_data, '{"location-levels":{"error":"Query exceeded maximum time of '||l_max_time||'"}}');
               end if;
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum time of '||l_max_time||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,Query exceeded maximum time of '||l_max_time||chr(10));
            end case;
         when instr(sqlerrm, l_max_size_msg) > 0 then
            dbms_lob.createtemporary(l_data, true);
            case l_format
            when  'XML' then
               if l_names is null then
                  cwms_util.append(l_data, '<location-levels-catalog><error>Query exceeded maximum size of '||l_max_size||' characters</error></location-levels-catalog>');
               else
                  cwms_util.append(l_data, '<location-levels><error>Query exceeded maximum size of '||l_max_size||' characters</error></location-levels>');
               end if;
            when 'JSON' then
               if l_names is null then
                  cwms_util.append(l_data, '{"location-levels-catalog":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
               else
                  cwms_util.append(l_data, '{"location-levels":{"error":"Query exceeded maximum size of '||l_max_size||' characters"}}');
               end if;
            when 'TAB' then
               cwms_util.append(l_data, 'ERROR'||chr(9)||'Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
            when 'CSV' then
               cwms_util.append(l_data, 'ERROR,Query exceeded maximum size of '||l_max_size||' characters'||chr(10));
            end case;
         else raise;
         end case;
   end;
   
   declare
      l_data2 clob;
   begin
      dbms_lob.createtemporary(l_data2, true);
      select db_unique_name into l_name from v$database;
      case 
      when l_format = 'XML' then
         ---------
         -- XML --
         ---------
         if l_names is not null then
            cwms_util.append(l_data, '</location-levels>');
            l_ts2 := systimestamp;
            l_elapsed_format := l_elapsed_format + l_ts2 - l_ts1;
            l_ts1 := systimestamp;
         end if;            
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
            ||'</requested-format><requested-start-time>'
            ||cwms_util.get_xml_time(l_start, l_timezone)
            ||'</requested-start-time><requested-end-time>'
            ||cwms_util.get_xml_time(l_end, l_timezone)
            ||'</requested-end-time><requested-office>'
            ||l_office_id
            ||'</requested-office>');
            if l_names is null then
               cwms_util.append(
                  l_data2,
                  '<requested-unit>'
                  ||l_unit
                  ||'</requested-unit>');
               cwms_util.append(
                  l_data2, 
                  '<total-location-levels-cataloged>'
                  ||l_count
                  ||'</total-location-levels-cataloged><unique-location-levels-cataloged>'
                  ||l_unique_count
                  ||'</unique-location-levels-cataloged></query-info>');
            else
               for i in 1..l_names.count loop
                  cwms_util.append(
                     l_data2,
                     '<requested-items position="'||i||'"><name>'
                     ||l_names(i)
                     ||'</name><unit>'
                     ||l_units(i)
                     ||'</unit><datum>'
                     ||l_datums(i)
                     ||'</datum></requested-items>');
               end loop;
               cwms_util.append(
                  l_data2, 
                  '<total-location-levels-retrieved>'
                  ||l_count
                  ||'</total-location-levels-retrieved><unique-location-levels-retrieved>'
                  ||l_unique_count
                  ||'</unique-location-levels-retrieved></query-info>');
            end if;
         l_data := regexp_replace(l_data, '(<location-levels(-catalog)?>)', '\1'||l_data2, 1, 1);
         p_results := l_data;
      when l_format = 'JSON' then
         ----------
         -- JSON --
         ----------
         if l_names is not null and instr(substr(l_data, 1, 50), '"error"') = 0 then
            cwms_util.append(l_data, ']}}');
         end if;
         cwms_util.append(
            l_data2, 
            '{"query-info":{"processed-at":"'
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
            ||'","requested-start-time":"'
            ||cwms_util.get_xml_time(l_start, l_timezone)
            ||'","requested-end-time":"'
            ||cwms_util.get_xml_time(l_end, l_timezone)
            ||'","requested-office":"'
            ||l_office_id
            ||'"');
            if l_names is null then
               cwms_util.append(
                  l_data2,
                  ',"requested-unit":"'
                  ||l_unit
                  ||'"');
               cwms_util.append(
                  l_data2, 
                  ',"total-location-levels-cataloged":'
                  ||l_count
                  ||',"unique-location-levels-cataloged":'
                  ||l_unique_count
                  ||'},');
            else
               cwms_util.append(l_data2, ',"requested-items":[');
               for i in 1..l_names.count loop
                  cwms_util.append(
                     l_data2,
                     case i when 1 then '{"name":"' else ',{"name":"' end
                     ||l_names(i)
                     ||'","unit":"'
                     ||l_units(i)
                     ||'","datum":"'
                     ||l_datums(i)
                     ||'"}');
               end loop;
               cwms_util.append(l_data2, ']');
               cwms_util.append(
                  l_data2, 
                  ',"total-location-levels-retrieved":'
                  ||l_count
                  ||',"unique-location-levels-retrieved":'
                  ||l_unique_count
                  ||'},');
            end if;
         l_data := regexp_replace(l_data, '^({"location-levels.*?":){', '\1'||l_data2, 1, 1);
         p_results := l_data;
      when l_format in ('TAB', 'CSV') then
         ----------------
         -- TAB or CSV --
         ----------------
         cwms_util.append(l_data2, '#Processed At'||chr(9)||utl_inaddr.get_host_name ||':'||l_name||chr(10));
         cwms_util.append(l_data2, '#Time Of Query'||chr(9)||to_char(l_query_time, 'dd-Mon-yyyy hh24:mi')||' UTC'||chr(10));
         cwms_util.append(l_data2, '#Process Query'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)))||' milliseconds'||chr(10));
         cwms_util.append(l_data2, '#Format Output'||chr(9)||trunc(1000 * (extract(minute from l_elapsed_format) * 60 + extract(second from l_elapsed_format)))||' milliseconds'||chr(10));
         cwms_util.append(l_data2, '#Requested Start Time'||chr(9)||to_char(l_start, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
         cwms_util.append(l_data2, '#Requested End Time'||chr(9)||to_char(l_end, 'dd-Mon-yyyy hh24:mi')||' '||l_timezone||chr(10));
         cwms_util.append(l_data2, '#Requested Format'   ||chr(9)||l_format||chr(10));
         cwms_util.append(l_data2, '#Requested Office'   ||chr(9)||l_office_id||chr(10));
         if l_names is not null then
            cwms_util.append(l_data2, '#Requested Names'    ||chr(9)||cwms_util.join_text(l_names, chr(9))||chr(10));
            cwms_util.append(l_data2, '#Requested Units'    ||chr(9)||cwms_util.join_text(l_units, chr(9))||chr(10));
            cwms_util.append(l_data2, '#Requested Datums'   ||chr(9)||cwms_util.join_text(l_datums, chr(9))||chr(10));
            cwms_util.append(l_data2, '#Total Location Levels Cataloged'||chr(9)||l_count||chr(10));
            cwms_util.append(l_data2, '#Unique Location Levels Cataloged'||chr(9)||l_unique_count||chr(10)||chr(10));
         else
            cwms_util.append(l_data2, '#Total Location Levels Retrieved'||chr(9)||l_count||chr(10));
            cwms_util.append(l_data2, '#Unique Location Levels Retrieved'||chr(9)||l_unique_count||chr(10)||chr(10));
         end if;
         cwms_util.append(l_data2, l_data);
         if l_format = 'CSV' then
            l_data2 := cwms_util.tab_to_csv(l_data2);
         end if;
         p_results := l_data2;
      end case;
   end;
         
   p_date_time   := l_query_time;
   p_query_time  := trunc(1000 * (extract(minute from l_elapsed_query) * 60 + extract(second from l_elapsed_query)));
   p_format_time := trunc(1000 * (extract(minute from l_elapsed_format) *60 +  extract(second from l_elapsed_format)));
   p_count       := l_count;
end retrieve_location_levels;   
         
            
END cwms_level;
/
show errors;
commit;
prompt Updating ZLOCATION_LEVEL_T Type Body
create or replace type body zlocation_level_t
as
   constructor function zlocation_level_t(
      p_location_level_code in number)
      return self as result
   as
      l_rec               at_location_level%rowtype;
      l_seasonal_values   seasonal_loc_lvl_tab_t := new seasonal_loc_lvl_tab_t();
      l_indicators        loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
      l_parameter_code    number(10);
      l_vert_datum_offset binary_double;
   begin
      -------------------------
      -- get the main record --
      -------------------------
      select *
        into l_rec
        from at_location_level
       where location_level_code = p_location_level_code;
      -----------------------------
      -- get the seasonal values --
      -----------------------------
      for rec in (
         select *
           from at_seasonal_location_level
          where location_level_code = p_location_level_code
       order by l_rec.interval_origin + calendar_offset + time_offset)
      loop
         l_seasonal_values.extend;
         l_seasonal_values(l_seasonal_values.count) := seasonal_location_level_t(
            rec.calendar_offset,
            rec.time_offset,
            rec.value);
      end loop;
      -------------------------------------------------
      -- check for elevation and adjust as necessary --
      -------------------------------------------------
      ------------------------------
      -- first the level value... --
      ------------------------------
      begin
         select ap.parameter_code
           into l_parameter_code
           from at_parameter ap,
                cwms_base_parameter bp
          where ap.parameter_code = self.parameter_code
            and bp.base_parameter_code = ap.base_parameter_code
            and bp.base_parameter_id = 'Elev';
      exception
         when no_data_found then null;
      end;
      if l_parameter_code is not null then
         self.location_level_value := self.location_level_value + cwms_loc.get_vertical_datum_offset(self.location_code, 'm');
      end if;
      -----------------------------
      -- ...then seasonal values --
      -----------------------------
      if l_seasonal_values.count > 0 then
         begin
            select ap.parameter_code
              into l_parameter_code
              from at_parameter ap,
                   cwms_base_parameter bp
             where ap.parameter_code = self.attribute_parameter_code
               and bp.base_parameter_code = ap.base_parameter_code
               and bp.base_parameter_id = 'Elev';
         exception
            when no_data_found then null;
         end;
         if l_parameter_code is not null then
            l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(self.location_code, 'm');
            for i in 1..l_seasonal_values.count loop
               l_seasonal_values(i).level_value := l_seasonal_values(i).level_value + l_vert_datum_offset;
            end loop;
         end if;
      end if;
      ---------------------------------------
      -- get the location level indicators --
      ---------------------------------------
      for rec in (
         select rowid
           from at_loc_lvl_indicator
          where location_code                     = l_rec.location_code
            and parameter_code                    = l_rec.parameter_code
            and parameter_type_code               = l_rec.parameter_type_code
            and duration_code                     = l_rec.duration_code
            and specified_level_code              = l_rec.specified_level_code
            and nvl(to_char(attr_value), '@')     = nvl(to_char(l_rec.attribute_value), '@')
            and nvl(attr_parameter_code, -1)      = nvl(l_rec.attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_rec.attribute_parameter_type_code, -1)
            and nvl(attr_duration_code, -1)       = nvl(l_rec.attribute_duration_code, -1))
      loop
         l_indicators.extend;
         l_indicators(l_indicators.count) := loc_lvl_indicator_t(rec.rowid);
      end loop;
      ---------------------------
      -- initialize the object --
      ---------------------------
      init(
         l_rec.location_level_code,
         l_rec.location_code,
         l_rec.specified_level_code,
         l_rec.parameter_code,
         l_rec.parameter_type_code,
         l_rec.duration_code,
         l_rec.location_level_date,
         l_rec.location_level_value,
         l_rec.location_level_comment,
         l_rec.attribute_value,
         l_rec.attribute_parameter_code,
         l_rec.attribute_parameter_type_code,
         l_rec.attribute_duration_code,
         l_rec.attribute_comment,
         l_rec.interval_origin,
         l_rec.calendar_interval,
         l_rec.time_interval,
         l_rec.interpolate,
         l_rec.ts_code,
         l_rec.expiration_date,
         l_seasonal_values,
         l_indicators);
      return;
   end zlocation_level_t;

   constructor function zlocation_level_t
      return self as result
   is
   begin
      --------------------------
      -- all members are null --
      --------------------------
      return;
   end;

   member procedure init(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_ts_code                       in number,
      p_expiration_date               in date,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t)
   as
      indicator zloc_lvl_indicator_t;
   begin
      ---------------------------
      -- verify the indicators --
      ---------------------------
      if p_indicators is not null then
         for i in 1..p_indicators.count loop
            indicator := p_indicators(i).zloc_lvl_indicator;
            if indicator.location_code                        != location_code
               or indicator.parameter_code                    != parameter_code
               or indicator.parameter_type_code               != parameter_type_code
               or indicator.duration_code                     != duration_code
               or nvl(to_char(indicator.attr_value), '@')     != nvl(to_char(attribute_value), '@')
               or nvl(indicator.attr_parameter_code, -1)      != nvl(attribute_parameter_code, -1)
               or nvl(indicator.attr_parameter_type_code, -1) != nvl(attribute_param_type_code, -1)
               or nvl(indicator.attr_duration_code, -1)       != nvl(attribute_duration_code, -1)
            then
               cwms_err.raise(
                  'ERROR',
                  'Location level indicator does not match location level.');
            end if;
         end loop;
      end if;
      ---------------------------
      -- set the member fields --
      ---------------------------
      self.location_level_code           := p_location_level_code;
      self.location_code                 := p_location_code;
      self.specified_level_code          := p_specified_level_code;
      self.parameter_code                := p_parameter_code;
      self.parameter_type_code           := p_parameter_type_code;
      self.duration_code                 := p_duration_code;
      self.location_level_date           := p_location_level_date;
      self.location_level_value          := p_location_level_value;
      self.location_level_comment        := p_location_level_comment;
      self.attribute_value               := p_attribute_value;
      self.attribute_parameter_code      := p_attribute_parameter_code;
      self.attribute_param_type_code     := p_attribute_param_type_code;
      self.attribute_duration_code       := p_attribute_duration_code;
      self.attribute_comment             := p_attribute_comment;
      self.interval_origin               := p_interval_origin;
      self.calendar_interval             := p_calendar_interval;
      self.time_interval                 := p_time_interval;
      self.interpolate                   := p_interpolate;
      self.ts_code                       := p_ts_code;
      self.expiration_date               := p_expiration_date;
      self.seasonal_level_values         := p_seasonal_values;
      self.indicators                    := p_indicators;
   end init;

   member procedure store
   as
      l_rec               at_location_level%rowtype;
      l_exists            boolean;
      l_ind_codes         number_tab_t;
      l_parameter_code    number(10);
      l_vert_datum_offset binary_double;
   begin
      ------------------------------
      -- find any existing record --
      ------------------------------
      begin
         select *
           into l_rec
           from at_location_level
          where location_level_code = self.location_level_code;
         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;
      ---------------------------
      -- set the record fields --
      ---------------------------
      l_rec.location_level_code           := self.location_level_code;
      l_rec.location_code                 := self.location_code;
      l_rec.specified_level_code          := self.specified_level_code;
      l_rec.parameter_code                := self.parameter_code;
      l_rec.parameter_type_code           := self.parameter_type_code;
      l_rec.duration_code                 := self.duration_code;
      l_rec.location_level_date           := self.location_level_date;
      l_rec.location_level_value          := self.location_level_value;
      l_rec.location_level_comment        := self.location_level_comment;
      l_rec.attribute_value               := self.attribute_value;
      l_rec.attribute_parameter_code      := self.attribute_parameter_code;
      l_rec.attribute_parameter_type_code := self.attribute_param_type_code;
      l_rec.attribute_duration_code       := self.attribute_duration_code;
      l_rec.attribute_comment             := self.attribute_comment;
      l_rec.interval_origin               := self.interval_origin;
      l_rec.calendar_interval             := self.calendar_interval;
      l_rec.time_interval                 := self.time_interval;
      l_rec.interpolate                   := self.interpolate;
      l_rec.ts_code                       := self.ts_code;
      l_rec.expiration_date               := self.expiration_date;
      --------------------------------------------
      -- adjust for vertical datum if necessary --
      --------------------------------------------
      begin
         select ap.parameter_code
           into l_parameter_code
           from at_parameter ap,
                cwms_base_parameter bp
          where ap.parameter_code = self.parameter_code
            and bp.base_parameter_code = ap.base_parameter_code
            and bp.base_parameter_id = 'Elev';
      exception
         when no_data_found then null;
      end;
      if l_parameter_code is not null then
         l_rec.location_level_value := l_rec.location_level_value + cwms_loc.get_vertical_datum_offset(self.location_code, 'm');
      end if;
      --------------------------------------
      -- insert or update the main record --
      --------------------------------------
      if l_exists then
         update at_location_level
            set row = l_rec
          where location_level_code = l_rec.location_level_code;
      else
         l_rec.location_level_code := cwms_seq.nextval;
         l_rec.location_level_date := nvl(l_rec.location_level_date, date '1900-01-01');
         insert
           into at_location_level
         values l_rec;
      end if;
      -------------------------------
      -- store the seasonal values --
      -------------------------------
      if l_exists then
        delete
          from at_seasonal_location_level
         where location_level_code = l_rec.location_level_code;
      end if;
      if self.seasonal_level_values is not null then
         l_vert_datum_offset := 0;
         begin
            select ap.parameter_code
              into l_parameter_code
              from at_parameter ap,
                   cwms_base_parameter bp
             where ap.parameter_code = self.attribute_parameter_code
               and bp.base_parameter_code = ap.base_parameter_code
               and bp.base_parameter_id = 'Elev';
         exception
            when no_data_found then null;
         end;
         if l_parameter_code is not null then
            l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(self.location_code, 'm');
         end if;
         for i in 1..self.seasonal_level_values.count loop
           insert
             into at_seasonal_location_level
           values (l_rec.location_level_code,
                   self.seasonal_level_values(i).calendar_offset,
                   self.seasonal_level_values(i).time_offset,
                   self.seasonal_level_values(i).level_value + l_vert_datum_offset);
         end loop;
      end if;
      --------------------------
      -- store the indicators --
      --------------------------
       if l_exists then
         select level_indicator_code
           bulk collect
           into l_ind_codes
           from at_loc_lvl_indicator
          where location_code                     = l_rec.location_code
            and parameter_code                    = l_rec.parameter_code
            and parameter_type_code               = l_rec.parameter_type_code
            and duration_code                     = l_rec.duration_code
            and specified_level_code              = l_rec.specified_level_code
            and nvl(to_char(attr_value), '@')     = nvl(to_char(l_rec.attribute_value), '@')
            and nvl(attr_parameter_code, -1)      = nvl(l_rec.attribute_parameter_code, -1)
            and nvl(attr_parameter_type_code, -1) = nvl(l_rec.attribute_parameter_type_code, -1)
            and nvl(attr_duration_code, -1)       = nvl(l_rec.attribute_duration_code, -1);
         delete
           from at_loc_lvl_indicator_cond
          where level_indicator_code in (select column_value from table(l_ind_codes));
         delete
           from at_loc_lvl_indicator
          where level_indicator_code in (select column_value from table(l_ind_codes));
       end if;
       if self.indicators is not null then
         for i in 1..indicators.count loop
            self.indicators(i).store;
         end loop;
       end if;
   end store;

end;
/
show errors;
commit;
prompt Updating ZLOC_LVL_INDICATOR_T Type Body
create or replace type body zloc_lvl_indicator_t
as
   constructor function zloc_lvl_indicator_t
      return self as result
   is
   begin
      return;
   end zloc_lvl_indicator_t;

   constructor function zloc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result
   is
      l_parameter_code    number(10);
      l_vert_datum_offset binary_double;
   begin
      conditions := new loc_lvl_ind_cond_tab_t();
      select level_indicator_code,
             location_code,
             specified_level_code,
             parameter_code,
             parameter_type_code,
             duration_code,
             attr_value,
             attr_parameter_code,
             attr_parameter_type_code,
             attr_duration_code,
             ref_specified_level_code,
             ref_attr_value,
             level_indicator_id,
             minimum_duration,
             maximum_age
       into  level_indicator_code,
             location_code,
             specified_level_code,
             parameter_code,
             parameter_type_code,
             duration_code,
             attr_value,
             attr_parameter_code,
             attr_parameter_type_code,
             attr_duration_code,
             ref_specified_level_code,
             ref_attr_value,
             level_indicator_id,
             minimum_duration,
             maximum_age
        from at_loc_lvl_indicator
       where rowid = p_rowid;
      begin
        select ap.parameter_code
          into l_parameter_code
          from at_parameter ap,
               cwms_base_parameter bp
         where ap.parameter_code = self.attr_parameter_code
           and bp.base_parameter_code = ap.base_parameter_code
           and bp.base_parameter_id = 'Elev';
      exception
        when no_data_found then null;
      end;
      if l_parameter_code is not null then
         l_vert_datum_offset := cwms_loc.get_vertical_datum_offset(self.location_code, 'm');
         self.attr_value := self.attr_value + l_vert_datum_offset;
         self.ref_attr_value := self.ref_attr_value + l_vert_datum_offset;
      end if;
      for rec in (select rowid
                    from at_loc_lvl_indicator_cond
                   where level_indicator_code = self.level_indicator_code
                order by level_indicator_value)
      loop
         conditions.extend;
         conditions(conditions.count) := loc_lvl_indicator_cond_t(rec.rowid);
         if conditions(conditions.count).comparison_unit is not null then
            ------------------------------------------------------------------------
            -- set factor and offset to convert from db units to comparison units --
            ------------------------------------------------------------------------
            select factor,
                   offset
              into conditions(conditions.count).factor,
                   conditions(conditions.count).offset
              from at_parameter p,
                   cwms_base_parameter bp,
                   cwms_unit_conversion uc
             where p.parameter_code = self.parameter_code
               and bp.base_parameter_code = p.base_parameter_code
               and uc.from_unit_code = bp.unit_code
               and uc.to_unit_code = conditions(conditions.count).comparison_unit;
         end if;
         if conditions(conditions.count).rate_interval is not null then
            if conditions(conditions.count).rate_comparison_unit is not null then
               ----------------------------------------------------------------------------------
               -- set rate_factor and rate_offset to convert from db units to comparison units --
               ----------------------------------------------------------------------------------
               select factor,
                      offset
                 into conditions(conditions.count).rate_factor,
                      conditions(conditions.count).rate_offset
                 from at_parameter p,
                      cwms_base_parameter bp,
                      cwms_unit_conversion uc
                where p.parameter_code = self.parameter_code
                  and bp.base_parameter_code = p.base_parameter_code
                  and uc.from_unit_code = bp.unit_code
                  and uc.to_unit_code = conditions(conditions.count).rate_comparison_unit;
            end if;
            -----------------------------------------------------------------
            -- set interval_factor to convert from 1 hour to rate interval --
            -----------------------------------------------------------------
            conditions(conditions.count).interval_factor := 24 *
               (extract(day    from conditions(conditions.count).rate_interval)        +
                extract(hour   from conditions(conditions.count).rate_interval) / 24   +
                extract(minute from conditions(conditions.count).rate_interval) / 3600 +
                extract(second from conditions(conditions.count).rate_interval) / 86400);
         end if;
      end loop;
      return;
   end zloc_lvl_indicator_t;

   member procedure store
   is
   begin
      cwms_level.store_loc_lvl_indicator_out(
         level_indicator_code,
         location_code,
         parameter_code,
         parameter_type_code,
         duration_code,
         specified_level_code,
         level_indicator_id,
         attr_value,
         attr_parameter_code,
         attr_parameter_type_code,
         attr_duration_code,
         ref_specified_level_code,
         ref_attr_value,
         minimum_duration,
         maximum_age,
         'F',
         'F');
      for i in 1..conditions.count loop
         conditions(i).store(level_indicator_code);
      end loop;
   end store;
end;
/
show errors;
commit;


prompt Updating CWMS_WATER_SUPPLY Package Body
CREATE OR REPLACE
PACKAGE BODY cwms_water_supply
AS
--------------------------------------------------------------------------------
-- procedure cat_water_user
-- returns a catalog of water users.
--
-- security: can be called by user and dba group.
--
-- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
-- Changing them will end up breaking external code (so make any changes prior
-- to development).
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    project_office_id         varchar2(16)  the office id of the parent project.
--    project_id                varchar2(49)  the identification (id) of the parent project.
--    entity_name               varchar2
--    water_right               varchar2
--
--------------------------------------------------------------------------------
-- errors will be thrown as exceptions
--
-- p_cursor
--   described above
-- p_project_id_mask
--   a mask to limit the query to certain projects.
-- p_db_office_id_mask
--   defaults to the connected user's office if null
--   the office id can use sql masks for retrieval of additional offices.
PROCEDURE cat_water_user(
	p_cursor            out sys_refcursor,
	p_project_id_mask   IN  VARCHAR2 DEFAULT NULL,
	p_db_office_id_mask IN  VARCHAR2 DEFAULT NULL )
IS
   l_office_id_mask  VARCHAR2(16) := 
      cwms_util.normalize_wildcards(nvl(upper(p_db_office_id_mask), '%'), TRUE);
   l_project_id_mask VARCHAR2(49) := 
      cwms_util.normalize_wildcards(nvl(upper(p_project_id_mask), '%'), TRUE);
BEGIN
   OPEN p_cursor FOR
      SELECT o.office_id AS project_office_id,
             bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id AS project_id,
             wu.entity_name, 
             wu.water_right
        FROM at_water_user wu,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       WHERE o.office_id LIKE l_office_id_mask ESCAPE '\'
         AND bl.db_office_code = o.office_code
         AND pl.base_location_code = bl.base_location_code
         AND upper(bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id) LIKE l_project_id_mask ESCAPE '\'
         AND wu.project_location_code = pl.location_code;
END cat_water_user;
--------------------------------------------------------------------------------
-- procedure cat_water_user_contract
-- returns a catalog of water user contracts.
--
-- security: can be called by user and dba group.
--
-- NOTE THAT THE COLUMN NAMES SHOULD NOT BE CHANGED AFTER BEING DEVELOPED.
-- Changing them will end up breaking external code (so make any changes prior
-- to development).
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    project_office_id         varchar2(16)  the office id of the parent project.
--    project_id                varchar2(49)  the identification (id) of the parent project.
--    entity_name               varchar2
--    contract_name             varchar2
--    contracted_storage        binary_double
--    contract_type             varchar2      the display value of the lookup.
--
--------------------------------------------------------------------------------
-- errors will be thrown as exceptions
--
-- p_cursor
--    described above
-- p_project_id_mask
--    a mask to limit the query to certain projects.
-- p_entity_name_mask
--    a mask to limit the query to certain entities.
-- p_db_office_id_mask
--    defaults to the connected user's office if null
--    the office id can use sql masks for retrieval of additional offices.
PROCEDURE cat_water_user_contract(
   p_cursor            out sys_refcursor,
   p_project_id_mask   IN  VARCHAR2 DEFAULT NULL,
   p_entity_name_mask  IN  VARCHAR2 DEFAULT NULL,
   p_db_office_id_mask IN  VARCHAR2 DEFAULT NULL )
IS
   l_office_id_mask  VARCHAR2(16) := 
      cwms_util.normalize_wildcards(nvl(upper(p_db_office_id_mask), '%'), TRUE);
   l_project_id_mask VARCHAR2(49) := 
      cwms_util.normalize_wildcards(nvl(upper(p_project_id_mask), '%'), TRUE);
   l_entity_name_mask VARCHAR2(49) := 
      cwms_util.normalize_wildcards(nvl(upper(p_entity_name_mask), '%'), TRUE);
BEGIN
   OPEN p_cursor FOR
      SELECT o.office_id AS project_office_id,
             bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id AS project_id,
             wu.entity_name,
             wuc.contract_name,
             wuc.contracted_storage,
             wct.ws_contract_type_display_value 
        FROM at_water_user wu,
             at_water_user_contract wuc,
             at_ws_contract_type wct,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
       WHERE o.office_id LIKE l_office_id_mask ESCAPE '\'
         AND bl.db_office_code = o.office_code
         AND pl.base_location_code = bl.base_location_code
         AND upper(bl.base_location_id
             || substr('-', 1, LENGTH(pl.sub_location_id))
             || pl.sub_location_id) LIKE l_project_id_mask ESCAPE '\'
         AND wu.project_location_code = pl.location_code
         AND upper(wu.entity_name) LIKE l_entity_name_mask ESCAPE '\'
         AND wuc.water_user_code = wu.water_user_code
         AND wct.ws_contract_type_code = wuc.water_supply_contract_type;
END cat_water_user_contract;
--------------------------------------------------------------------------------
-- Returns a set of water users for a given project. Returned data is encapsulated
-- in a table of water user oracle types.
--
-- security: can be called by user and dba group.
--
-- errors preventing the return of data will be issued as a thrown exception
--
-- p_water_users
--    returns a filled set of objects including location ref data
-- p_project_location_ref
--    a project location refs that identify the objects we want to retrieve.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
PROCEDURE retrieve_water_users(
	p_water_users          out water_user_tab_t,
	p_project_location_ref IN  location_ref_t )
IS
BEGIN
   p_water_users := water_user_tab_t();
   FOR rec IN (
      SELECT entity_name,
             water_right
        FROM at_water_user
       WHERE project_location_code = p_project_location_ref.get_location_code)
   loop
      p_water_users.EXTEND;
      p_water_users(p_water_users.count) := water_user_obj_t(
         p_project_location_ref,
         rec.entity_name,
         rec.water_right);
   END loop;       
END retrieve_water_users;

PROCEDURE store_water_user(
   p_water_user     IN water_user_obj_t,
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
   l_rec           at_water_user%rowtype;
   l_proj_loc_code NUMBER := p_water_user.project_location_ref.get_location_code; 
BEGIN
   BEGIN
      SELECT *
        INTO l_rec
        FROM at_water_user
       WHERE project_location_code = l_proj_loc_code 
         AND upper(entity_name) = upper(p_water_user.entity_name);
      IF cwms_util.is_true(p_fail_if_exists) THEN
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Water User',
            p_water_user.project_location_ref.get_office_id
            ||'/'
            || p_water_user.project_location_ref.get_location_id
            ||'/'
            || p_water_user.entity_name);
      END IF;
      IF l_rec.water_right != p_water_user.water_right THEN
         l_rec.water_right := p_water_user.water_right;
         UPDATE at_water_user
            SET ROW = l_rec
          WHERE water_user_code = l_rec.water_user_code; 			 
      END IF;
   exception
      WHEN no_data_found THEN
         l_rec.water_user_code := cwms_seq.nextval;
         l_rec.project_location_code := l_proj_loc_code;
         l_rec.entity_name := p_water_user.entity_name;
         l_rec.water_right := p_water_user.water_right;
      INSERT
        INTO at_water_user
      VALUES l_rec;			 			 
   END;
	
END store_water_user;
--------------------------------------------------------------------------------
-- store a set of water users.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_water_user
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the object already exists
PROCEDURE store_water_users(
   p_water_users    IN water_user_tab_t,
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
BEGIN
   IF p_water_users IS NOT NULL THEN
      FOR i IN 1..p_water_users.count loop
         store_water_user(p_water_users(i), p_fail_if_exists);
      END loop;
   END IF;
END store_water_users;
--------------------------------------------------------------------------------
-- deletes the water user identified by the project location ref and entity name.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_project_location_ref
--    project location ref.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name
-- p_delete_action
--    the water user entity name.
--    delete key will fail if there are references.
--    delete all will also delete the referring children.
PROCEDURE delete_water_user(
	p_project_location_ref IN location_ref_t,
	p_entity_name          IN VARCHAR,
	p_delete_action        IN VARCHAR2 DEFAULT cwms_util.delete_key )
IS
   l_proj_loc_code NUMBER := p_project_location_ref.get_location_code;
BEGIN
   IF NOT p_delete_action IN (cwms_util.delete_key, cwms_util.delete_all ) THEN
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be '''
         || cwms_util.delete_key
         || ''' or '''
         || cwms_util.delete_all
         || '');
   END IF;
   IF p_delete_action = cwms_util.delete_all THEN
      ---------------------------------------------------
      -- delete AT_WAT_USR_CONTRACT_ACCOUNTING records --
      ---------------------------------------------------
      DELETE
        FROM at_wat_usr_contract_accounting
       WHERE water_user_contract_code IN
             ( SELECT water_user_contract_code
                 FROM at_water_user_contract
                WHERE water_user_code IN
                      ( SELECT water_user_code
                          FROM at_water_user
                         WHERE project_location_code = l_proj_loc_code
                           AND upper(entity_name) = upper(p_entity_name)
                      )
             );
      --------------------------------------------------
      -- delete AT_XREF_WAT_USR_CONTRACT_DOCS records --
      --------------------------------------------------
      DELETE
        FROM at_xref_wat_usr_contract_docs
       WHERE water_user_contract_code IN
             ( SELECT water_user_contract_code
                 FROM at_water_user_contract
                WHERE water_user_code IN
                      ( SELECT water_user_code
                          FROM at_water_user
                         WHERE project_location_code = l_proj_loc_code
                           AND upper(entity_name) = upper(p_entity_name)
                      )
             );
      -------------------------------------------             
      -- delete AT_WATER_USER_CONTRACT records --
      -------------------------------------------             
      DELETE
        FROM at_water_user_contract
       WHERE water_user_code IN
             ( SELECT water_user_code
                 FROM at_water_user
                WHERE project_location_code = l_proj_loc_code
                  AND upper(entity_name) = upper(p_entity_name)
             );
   END IF;
   ---------------------------------- 
   -- delete AT_WATER_USER records --
   ---------------------------------- 
   DELETE 
     FROM at_water_user
    WHERE project_location_code = l_proj_loc_code
      AND upper(entity_name) = upper(p_entity_name);
END delete_water_user;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_project_location_ref
--    project location ref.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name_old
-- p_entity_name_new
PROCEDURE rename_water_user(
	p_project_location_ref IN location_ref_t,
	p_entity_name_old      IN VARCHAR2,
	p_entity_name_new      IN VARCHAR2 )
IS
BEGIN
   UPDATE at_water_user
      SET entity_name = p_entity_name_new
    WHERE project_location_code = p_project_location_ref.get_location_code
      AND upper(entity_name) = upper(p_entity_name_old);
END rename_water_user;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- water user contract procedures.
-- p_contracts
-- p_project_location_ref
--    a project location refs that identify the objects we want to retrieve.
--    includes the location id (base location + '-' + sublocation)
--    the office id if null will default to the connected user's office
-- p_entity_name
PROCEDURE retrieve_contracts(
   p_contracts            out water_user_contract_tab_t,
   p_project_location_ref IN  location_ref_t,
   p_entity_name          IN  VARCHAR2 )
IS
BEGIN
   p_contracts := water_user_contract_tab_t();
   FOR rec IN (
      SELECT wuc.contract_name,
             wuc.contracted_storage * uc.factor + uc.offset AS contracted_storage,
             wuc.water_supply_contract_type,
             wuc.ws_contract_effective_date,
             wuc.ws_contract_expiration_date,
             wuc.initial_use_allocation * uc.factor + uc.offset AS initial_use_allocation,
             wuc.future_use_allocation * uc.factor + uc.offset AS future_use_allocation,
             wuc.future_use_percent_activated,
             wuc.total_alloc_percent_activated,
             wuc.pump_out_location_code,
             wuc.pump_out_below_location_code,
             wuc.pump_in_location_code,
             o.office_id,
             wct.ws_contract_type_display_value,
             wct.ws_contract_type_tooltip,
             wct.ws_contract_type_active,
             wu.entity_name,
             wu.water_right,
             uc.to_unit_id AS storage_unit_id
        FROM at_water_user_contract wuc,
             at_water_user wu,
             at_ws_contract_type wct,
             cwms_base_parameter bp,
             cwms_unit_conversion uc,
             cwms_office o
       WHERE wu.project_location_code = p_project_location_ref.get_location_code
         AND upper(wu.entity_name) = upper(p_entity_name)
         AND wuc.water_user_code = wu.water_user_code
         AND wct.ws_contract_type_code = wuc.water_supply_contract_type
         AND o.office_code = wct.db_office_code
         AND bp.base_parameter_id = 'Stor'
         AND uc.from_unit_code = bp.unit_code
         AND uc.to_unit_code = wuc.storage_unit_code
         )
   loop
      p_contracts.EXTEND;
      p_contracts(p_contracts.count) := water_user_contract_obj_t(
         water_user_contract_ref_t(
            water_user_obj_t(
               p_project_location_ref,
               rec.entity_name,
               rec.water_right),
            rec.contract_name),
         lookup_type_obj_t(
            rec.office_id,
            rec.ws_contract_type_display_value,
            rec.ws_contract_type_tooltip,
            rec.ws_contract_type_active),
         rec.ws_contract_effective_date,
         rec.ws_contract_expiration_date,
         rec.contracted_storage,
         rec.initial_use_allocation,
         rec.future_use_allocation,
         rec.storage_unit_id,
         rec.future_use_percent_activated,
         rec.total_alloc_percent_activated,
         cwms_loc.retrieve_location(rec.pump_out_location_code),
         cwms_loc.retrieve_location(rec.pump_out_below_location_code),
         cwms_loc.retrieve_location(rec.pump_in_location_code));
   END loop;
END retrieve_contracts;
--------------------------------------------------------------------------------
-- stores a set of water user contracts.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contracts
-- p_fail_if_exists
--    a flag that will cause the procedure to fail if the objects already exist
PROCEDURE store_contracts(
   p_contracts      IN water_user_contract_tab_t,
   p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
   l_fail_if_exists boolean;
   l_rec            at_water_user_contract%rowtype;
   l_ref            water_user_contract_ref_t;
   l_water_user_code NUMBER(10);
   
   PROCEDURE populate_contract(
      p_rec IN out nocopy at_water_user_contract%rowtype,
      p_obj IN            water_user_contract_obj_t)
   IS
      l_factor             BINARY_DOUBLE;
      l_offset             BINARY_DOUBLE;
      l_contract_type_code NUMBER(10);
      l_storage_unit_code  NUMBER(10);
      l_water_user_code    NUMBER(10);
   BEGIN
      ----------------------------------
      -- get the unit conversion info --
      ----------------------------------
      SELECT uc.factor,
             uc.offset,
             uc.from_unit_code
        INTO l_factor,
             l_offset,
             l_storage_unit_code
        FROM cwms_base_parameter bp,
             cwms_unit_conversion uc
       WHERE bp.base_parameter_id = 'Stor'
         AND uc.to_unit_code = bp.unit_code
         AND uc.from_unit_id = nvl(p_obj.storage_units_id,'m3');
      --------------------------------         
      -- get the contract type code --
      --------------------------------
      SELECT ws_contract_type_code
        INTO l_contract_type_code
        FROM at_ws_contract_type
       WHERE db_office_code = cwms_util.get_office_code(p_obj.water_supply_contract_type.office_id)
         AND upper(ws_contract_type_display_value) = upper(p_obj.water_supply_contract_type.display_value);
      

      ---------------------------                  
      -- set the record fields --
      ---------------------------      
      p_rec.contracted_storage := p_obj.contracted_storage * l_factor + l_offset;
      p_rec.water_supply_contract_type := l_contract_type_code;
      p_rec.ws_contract_effective_date := p_obj.ws_contract_effective_date;
      p_rec.ws_contract_expiration_date := p_obj.ws_contract_expiration_date;
      p_rec.initial_use_allocation := p_obj.initial_use_allocation * l_factor + l_offset;
      p_rec.future_use_allocation := p_obj.future_use_allocation * l_factor + l_offset;
      p_rec.future_use_percent_activated := p_obj.future_use_percent_activated;
      p_rec.total_alloc_percent_activated := p_obj.total_alloc_percent_activated;
      IF p_obj.pump_out_location IS NOT NULL
      THEN
        --store location data
        cwms_loc.store_location(p_obj.pump_out_location,'F');
        --get location code
        p_rec.pump_out_location_code := p_obj.pump_out_location.location_ref.get_location_code('F');
      END IF;
      IF p_obj.pump_out_below_location IS NOT NULL
      THEN
        --store location data
        cwms_loc.store_location(p_obj.pump_out_below_location,'F');
        --get location code
        p_rec.pump_out_below_location_code := p_obj.pump_out_below_location.location_ref.get_location_code('F');
      END IF;
      IF p_obj.pump_in_location IS NOT NULL
      THEN
        --store location data
        cwms_loc.store_location(p_obj.pump_in_location,'F');
        --get location code.
        p_rec.pump_in_location_code := p_obj.pump_in_location.location_ref.get_location_code('F');
      END IF;      
      p_rec.storage_unit_code := l_storage_unit_code;
   END;
BEGIN
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   IF p_contracts IS NOT NULL THEN
      FOR i IN 1..p_contracts.count loop
         l_ref := p_contracts(i).water_user_contract_ref;
         BEGIN
            -- select the water user code
            SELECT water_user_code 
            INTO l_water_user_code
            FROM at_water_user
            WHERE project_location_code = l_ref.water_user.project_location_ref.get_location_code
            AND upper(entity_name) = upper(l_ref.water_user.entity_name);
        
            -- select the contract row.
            SELECT *
            INTO l_rec
            FROM at_water_user_contract
            WHERE water_user_code = l_water_user_code
            AND upper(contract_name) = upper(l_ref.contract_name);
            -- contract row exists
            -- check fail if exists
            IF l_fail_if_exists THEN
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'Water supply contract',
                  l_ref.water_user.project_location_ref.get_office_id
                  || '/'
                  || l_ref.water_user.project_location_ref.get_location_id
                  || '/'
                  || l_ref.water_user.entity_name
                  || '/'
                  || l_ref.contract_name);                  
            END IF;
            -- update row
            populate_contract(l_rec, p_contracts(i));
            UPDATE at_water_user_contract
            SET ROW = l_rec
            WHERE water_user_contract_code = l_rec.water_user_contract_code;
         exception
            -- contract row not found
            WHEN no_data_found THEN
              -- copy incoming non-key contract data to row.
              populate_contract(l_rec, p_contracts(i));
              -- set the contract name
              l_rec.contract_name := l_ref.contract_name;
              -- assign water user code
              l_rec.water_user_code := l_water_user_code;
              -- generate new key
              l_rec.water_user_contract_code := cwms_seq.nextval;
              -- insert into table
              INSERT
              INTO at_water_user_contract
              VALUES l_rec;
         END;
      END loop;
   END IF;
END store_contracts;
--------------------------------------------------------------------------------
-- deletes the water user contract associated with the argument ref.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- p_contract_ref
--    contains the identifying parts of the contract to delete.
-- p_delete_action
--    delete key will fail if there are references.
--    delete all will also delete the referring children.
PROCEDURE delete_contract(
   p_contract_ref  IN water_user_contract_ref_t,
   p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_key )
IS
   l_contract_code NUMBER;
BEGIN
   IF NOT p_delete_action IN (cwms_util.delete_key, cwms_util.delete_all ) THEN
      cwms_err.raise(
         'ERROR',
         'P_DELETE_ACTION must be '''
         || cwms_util.delete_key
         || ''' or '''
         || cwms_util.delete_all
         || '');
   END IF;
   SELECT water_user_contract_code
     INTO l_contract_code
     FROM at_water_user_contract
    WHERE water_user_code =
          ( SELECT water_user_code
              FROM at_water_user
             WHERE project_location_code = p_contract_ref.water_user.project_location_ref.get_location_code
               AND upper(entity_name) = upper(p_contract_ref.water_user.entity_name)
          )
      AND upper(contract_name) = upper(p_contract_ref.contract_name);    
   IF p_delete_action = cwms_util.delete_all THEN
      DELETE
        FROM at_wat_usr_contract_accounting
       WHERE water_user_contract_code = l_contract_code;
      DELETE
        FROM at_xref_wat_usr_contract_docs
       WHERE water_user_contract_code = l_contract_code;
   END IF;
   DELETE
     FROM at_water_user_contract
    WHERE water_user_contract_code = l_contract_code;    
END delete_contract;
--------------------------------------------------------------------------------
-- renames the water user contract associated with the contract arg from
-- the old contract name to the new contract name.
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
PROCEDURE rename_contract(
   p_water_user_contract IN water_user_contract_ref_t,
   p_old_contract_name   IN VARCHAR2,
   p_new_contract_name   IN VARCHAR2 )
IS
BEGIN
   UPDATE at_water_user_contract
      SET contract_name = p_new_contract_name
    WHERE water_user_code = 
          ( SELECT water_user_code
              FROM at_water_user
             WHERE project_location_code 
                   = p_water_user_contract.water_user.project_location_ref.get_location_code
               AND upper(entity_name) 
                   = upper(p_water_user_contract.water_user.entity_name)
          )
      AND upper(contract_name) = upper(p_old_contract_name); 
END rename_contract;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- look up procedures.
-- returns a listing of lookup objects.
-- p_lookup_type_tab_t
-- p_db_office_id
--    defaults to the connected user's office if null
PROCEDURE get_contract_types(
	p_contract_types out lookup_type_tab_t,
	p_db_office_id   IN  VARCHAR2 DEFAULT NULL )
IS
BEGIN
   p_contract_types := lookup_type_tab_t();
   FOR rec IN (
      SELECT o.office_id,
             wct.ws_contract_type_display_value,
             wct.ws_contract_type_tooltip,
             wct.ws_contract_type_active
        FROM at_ws_contract_type wct,
             cwms_office o
       WHERE o.office_id = nvl(upper(p_db_office_id), cwms_util.user_office_id)
         AND wct.db_office_code = o.office_code)
   loop
      p_contract_types.EXTEND;
      p_contract_types(p_contract_types.count) := lookup_type_obj_t(
         rec.office_id,
         rec.ws_contract_type_display_value,
         rec.ws_contract_type_tooltip,
         rec.ws_contract_type_active);
   END loop;              
END get_contract_types;
--------------------------------------------------------------------------------
-- errors preventing the return of data will be issued as a thrown exception
--------------------------------------------------------------------------------
-- inserts or updates a set of lookups.
-- if a lookup does not exist it will be inserted.
-- if a lookup already exists and p_fail_if_exists is false, the existing
-- lookup will be updated.
--
-- a failure will cause the whole set of lookups to not be stored.
-- p_lookup_type_tab_t IN lookup_type_tab_t,
-- p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )AS
--    a flag that will cause the procedure to fail if the objects already exist
PROCEDURE set_contract_types(
	p_contract_types IN lookup_type_tab_t,
	p_fail_if_exists IN VARCHAR2 DEFAULT 'T' )
IS
   l_office_code    NUMBER;
   l_fail_if_exists boolean; 
   l_rec            at_ws_contract_type%rowtype;
BEGIN
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists); 
   IF p_contract_types IS NOT NULL THEN
      FOR i IN 1..p_contract_types.count loop
         l_office_code := cwms_util.get_office_code(p_contract_types(i).office_id);
         BEGIN
            SELECT *
              INTO l_rec
              FROM at_ws_contract_type
             WHERE db_office_code = l_office_code
               AND upper(ws_contract_type_display_value) = 
                   upper(p_contract_types(i).display_value);
            IF l_fail_if_exists THEN
               cwms_err.raise(
                  'ITEM_ALREADY_EXISTS',
                  'WS_CONTRACT_TYPE',
                  upper(p_contract_types(i).office_id)
                  || '/'
                  || p_contract_types(i).display_value);
            END IF;                   
            l_rec.ws_contract_type_display_value := p_contract_types(i).display_value;                  
            l_rec.ws_contract_type_tooltip := p_contract_types(i).tooltip;                  
            l_rec.ws_contract_type_active := p_contract_types(i).active;
            UPDATE at_ws_contract_type
               SET ROW = l_rec
             WHERE ws_contract_type_code = l_rec.ws_contract_type_code;                  
         exception
            WHEN no_data_found THEN
               l_rec.ws_contract_type_code := cwms_seq.nextval;
               l_rec.db_office_code := l_office_code;
               l_rec.ws_contract_type_display_value := p_contract_types(i).display_value;                  
               l_rec.ws_contract_type_tooltip := p_contract_types(i).tooltip;                  
               l_rec.ws_contract_type_active := p_contract_types(i).active;
               INSERT
                 INTO at_ws_contract_type
               VALUES l_rec;
         END;
      END loop;
   END IF;
END set_contract_types;
--------------------------------------------------------------------------------
-- water supply accounting
--------------------------------------------------------------------------------


PROCEDURE retrieve_accounting_set(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,
    -- the water user contract ref
    p_contract_ref IN water_user_contract_ref_t,
    -- the units to return the flow as.
    p_units IN VARCHAR2,
    --time window stuff
    -- the transfer start date time
    p_start_time IN DATE,
    -- the transfer end date time
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    -- limit on the number of rows returned
    p_row_limit IN integer DEFAULT NULL,
    -- a mask for the transfer type.
    -- if null, return all transfers.
    -- do we need this?
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  )
is
    l_contract_code          NUMBER(10);
    l_project_location_code  number(10);
    
    l_pump_out_code number(10);
    l_pump_out_below_code number(10);
    l_pump_in_code number(10);    
    
    l_pump_out_set wat_usr_contract_acct_tab_t;
    l_pump_out_below_set wat_usr_contract_acct_tab_t;
    l_pump_in_set wat_usr_contract_acct_tab_t;
begin

    -- null check the contract.
    IF p_contract_ref IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Reference');
    END IF;
    
    --grab the project loc code.
    l_project_location_code :=  p_contract_ref.water_user.project_location_ref.get_location_code('F');

    -- get the contract code and pump locs
    select water_user_contract_code, pump_out_location_code, pump_out_below_location_code, pump_in_location_code
    INTO l_contract_code, l_pump_out_code, l_pump_out_below_code, l_pump_in_code
    FROM at_water_user_contract wuc,
        at_water_user wu
    WHERE wuc.water_user_code = wu.water_user_code
        AND upper(wuc.contract_name) = upper(p_contract_ref.contract_name)
        AND upper(wu.entity_name) = upper(p_contract_ref.water_user.entity_name)
        AND wu.project_location_code = l_project_location_code;
    
    --build the aggregate accting set
    p_accounting_set := wat_usr_contract_acct_tab_t();
    
    --get the pump out recs    
    IF l_pump_out_code IS NOT NULL THEN
        retrieve_pump_accounting(l_pump_out_set,
            l_contract_code,
            p_contract_ref,
            l_pump_out_code,
            p_units,
            p_start_time,
            p_end_time,
            p_time_zone,
            p_start_inclusive,
            p_end_inclusive,
            p_ascending_flag,
            p_row_limit,
            p_transfer_type);
        --add the recs to the aggregate.
        FOR i IN 1..l_pump_out_set.count loop
            p_accounting_set.extend;
            p_accounting_set(p_accounting_set.count) := l_pump_out_set(i);            
        end loop;
    END IF;
    --get the pump out below recs
    IF l_pump_out_below_code IS NOT NULL THEN
        retrieve_pump_accounting(l_pump_out_below_set,
            l_contract_code,
            p_contract_ref,
            l_pump_out_below_code,
            p_units,
            p_start_time,
            p_end_time,
            p_time_zone,
            p_start_inclusive,
            p_end_inclusive,
            p_ascending_flag,
            p_row_limit,
            p_transfer_type);
        --add the recs to the aggregate.
        FOR i IN 1..l_pump_out_below_set.count loop
            p_accounting_set.extend;
            p_accounting_set(p_accounting_set.count) := l_pump_out_below_set(i);            
        end loop;        
    END IF;
    --pump in recs...
    IF l_pump_in_code IS NOT NULL THEN
        retrieve_pump_accounting(l_pump_in_set,
            l_contract_code,
            p_contract_ref,
            l_pump_in_code,
            p_units,
            p_start_time,
            p_end_time,
            p_time_zone,
            p_start_inclusive,
            p_end_inclusive,
            p_ascending_flag,
            p_row_limit,
            p_transfer_type);
        FOR i IN 1..l_pump_in_set.count loop
            p_accounting_set.extend;
            p_accounting_set(p_accounting_set.count) := l_pump_in_set(i);            
        end loop;            
    END IF;
    
end retrieve_accounting_set;
  
--------------------------------------------------------------------------------
-- retrieve a water user contract accounting set.
--------------------------------------------------------------------------------
PROCEDURE retrieve_pump_accounting(
    -- the retrieved set of water user contract accountings
    p_accounting_set out wat_usr_contract_acct_tab_t,

    -- the water user contract ref
    p_contract_code in number,
    -- the water user contract ref
    p_contract_ref IN water_user_contract_ref_t,
    
    p_pump_loc_code IN number,
    
    -- the units to return the flow as.
    p_units IN VARCHAR2,
    --time window stuff
    -- the transfer start date time
    p_start_time IN DATE,
    -- the transfer end date time
    p_end_time IN DATE,
    -- the time zone of returned date time data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,
    -- if the start time is inclusive.
    p_start_inclusive IN VARCHAR2 DEFAULT 'T',
    -- if the end time is inclusive
    p_end_inclusive IN VARCHAR2 DEFAULT 'T',
    
    -- a boolean flag indicating if the returned data should be the head or tail
    -- of the set, i.e. the first n values or last n values.
    p_ascending_flag IN VARCHAR2 DEFAULT 'T',
    
    -- limit on the number of rows returned
    p_row_limit IN integer DEFAULT NULL,
    
    -- a mask for the transfer type.
    -- if null, return all transfers.
    -- do we need this?
    p_transfer_type IN VARCHAR2 DEFAULT NULL
  )
  IS
    l_pump_loc_ref    location_ref_t;
    l_unit_code              number(10);
    l_adjusted_start_time    DATE;
    l_adjusted_end_time      DATE;
    l_start_time_inclusive   boolean;
    l_end_time_inclusive     boolean;
    l_time_zone              VARCHAR2(28) := nvl(p_time_zone, 'UTC');
    l_time_zone_code         number(10);
    l_orderby_mod     NUMBER(1);
   
BEGIN

    -- get the out going unit code.
    select unit_code 
    into l_unit_code 
    from cwms_unit
    where unit_id = nvl(p_units,'cms');
    
    --------------------------------
    -- prepare selection criteria --
    --------------------------------
    IF p_ascending_flag IS NULL OR p_ascending_flag IN ('t','T') THEN
        --default to asc order
        l_orderby_mod := 1; 
    ELSE
        -- reverse order to desc
        l_orderby_mod := -1; 
    end if;
    
    l_start_time_inclusive := cwms_util.is_true(p_start_inclusive);
    l_end_time_inclusive   := cwms_util.is_true(p_end_inclusive);
    
    l_adjusted_start_time := cwms_util.change_timezone(
                     p_start_time,
                     l_time_zone, 
                     'UTC');
    l_adjusted_end_time := cwms_util.change_timezone(
                     p_end_time,
                     l_time_zone, 
                     'UTC');
    
    IF l_start_time_inclusive = FALSE THEN
       l_adjusted_start_time := l_adjusted_start_time + (1 / 86400);
    END IF;
    
    IF l_end_time_inclusive = FALSE THEN
       l_adjusted_end_time := l_adjusted_end_time - (1 / 86400);
    END IF;
    
    IF l_time_zone IS NOT NULL THEN
       SELECT tz.time_zone_code
         INTO l_time_zone_code
         FROM mv_time_zone tz
        where upper(tz.time_zone_name) = upper(l_time_zone);
    END IF;    
    
    l_pump_loc_ref := new location_ref_t(p_pump_loc_code);
    
       -- instantiate a table array to hold the output records.
    p_accounting_set := wat_usr_contract_acct_tab_t();
    ----------------------------------------
    -- select records and populate output --
    ----------------------------------------
    FOR rec IN (  
        WITH ordered_wuca AS
          (SELECT
            /*+ FIRST_ROWS(100) */
            wat_usr_contract_acct_code,
            water_user_contract_code,
            pump_location_code,
            phys_trans_type_code,
            pump_flow,
            transfer_start_datetime,
            accounting_remarks
          from at_wat_usr_contract_accounting
          where water_user_contract_code = p_contract_code
          and pump_location_code = p_pump_loc_code
          AND transfer_start_datetime BETWEEN l_adjusted_start_time AND l_adjusted_end_time
           ORDER BY cwms_util.to_millis(transfer_start_datetime) * l_orderby_mod),
          limited_wuca AS
          (SELECT wat_usr_contract_acct_code,
            water_user_contract_code,
            pump_location_code,
            phys_trans_type_code,
            pump_flow,
            transfer_start_datetime,
            accounting_remarks
            
          FROM ordered_wuca
          WHERE ROWNUM <= nvl(p_row_limit, rownum)
          )
        SELECT limited_wuca.pump_location_code,
          limited_wuca.transfer_start_datetime,
          limited_wuca.pump_flow,
          -- u.unit_id AS units_id,
          uc.factor,
          uc.offset,
          o.office_id AS transfer_type_office_id,
          ptt.phys_trans_type_display_value,
          ptt.phys_trans_type_tooltip,
          ptt.phys_trans_type_active,
          limited_wuca.accounting_remarks
        FROM limited_wuca
        INNER JOIN at_water_user_contract wuc
        ON (limited_wuca.water_user_contract_code = wuc.water_user_contract_code)
        INNER JOIN at_physical_transfer_type ptt
        ON (limited_wuca.phys_trans_type_code = ptt.phys_trans_type_code)
        INNER JOIN cwms_office o ON ptt.db_office_code = o.office_code
        inner join cwms_unit_conversion uc
        on (uc.to_unit_code = l_unit_code)
        inner join cwms_base_parameter bp
        ON (uc.from_unit_code = bp.unit_code AND bp.base_parameter_id = 'Flow')
    )
    loop
      --extend the array.
      p_accounting_set.EXTEND;
      
      p_accounting_set(p_accounting_set.count) := wat_usr_contract_acct_obj_t(
         --re-use arg contract ref
        p_contract_ref,
        l_pump_loc_ref,  -- the pump location
        lookup_type_obj_t(
          rec.transfer_type_office_id,
          rec.phys_trans_type_display_value,
          rec.phys_trans_type_tooltip,
          rec.phys_trans_type_active),
        rec.pump_flow * rec.factor + rec.offset,
        -- rec.units_id,
        cwms_util.change_timezone(
           rec.transfer_start_datetime, 
           'UTC',
           l_time_zone),
        rec.accounting_remarks);
   END loop;      
END retrieve_pump_accounting;

--------------------------------------------------------------------------------
-- store a water user contract accounting set.
--------------------------------------------------------------------------------
PROCEDURE store_accounting_set(
    -- the set of water user contract accountings to store to the database.
    p_accounting_tab IN wat_usr_contract_acct_tab_t,

    -- the contract ref for the incoming accountings.
    p_contract_ref IN water_user_contract_ref_t,
    
    --the following represents pump time windows where data needs to be cleared
    --out as part of the delete insert process.
    p_pump_time_window_tab loc_ref_time_window_tab_t,

    -- the time zone of all of the incoming data.
    p_time_zone IN VARCHAR2 DEFAULT NULL,    
    
    -- the units of the incoming accounting flow data
    p_flow_unit_id IN VARCHAR2 DEFAULT NULL,    

		-- store rule, this variable is not supported. 
    -- only delete insert initially supported.
    p_store_rule		IN VARCHAR2 DEFAULT NULL,

    -- if protection is to be ignored.
    -- this variable is not supported.
		p_override_prot	IN VARCHAR2 DEFAULT 'F'
    )   
   
   
IS

    l_contract_name at_water_user_contract.contract_name%TYPE;
    l_entity_name at_water_user.entity_name%TYPE;
    l_project_loc_code NUMBER(10);
    l_contract_code NUMBER(10);

    l_factor         BINARY_DOUBLE;
    l_offset         BINARY_DOUBLE;
    l_time_zone      varchar2(28) := nvl(p_time_zone, 'UTC');
--    l_count number;
BEGIN

    -- check arrays for errors
    IF p_pump_time_window_tab IS NULL 
    THEN
      cwms_err.raise(
      'NULL_ARGUMENT',
      'Pump Location and Time Window Array');
    END IF;
    
    IF p_contract_ref IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Reference');
    END IF;      

    l_contract_name := p_contract_ref.contract_name; -- 'WU CONTRACT 1'; 
    IF l_contract_name IS NULL THEN
      --error, the contract is null.
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Contract Name');
    END IF; 
    
    IF  p_contract_ref.water_user IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Contract Water User');
    END IF; 
    
    l_entity_name := p_contract_ref.water_user.entity_name; -- 'KEYS WU 1'; 
    IF  l_entity_name IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Entity Name');
    END IF; 
    
    IF p_contract_ref.water_user.project_location_ref IS NULL THEN
      cwms_err.raise(
            'NULL_ARGUMENT',
            'Water User Project Location Ref');
    END IF; 
    
    l_project_loc_code := p_contract_ref.water_user.project_location_ref.get_location_code('F'); -- 32051; 
    
    -- get the contract code
    SELECT wuc.water_user_contract_code
    INTO l_contract_code 
    FROM at_water_user_contract wuc
    INNER JOIN at_water_user wu ON (wuc.water_user_code = wu.water_user_code)
    WHERE upper(wuc.contract_name) = upper(l_contract_name)
    AND upper(wu.entity_name) = upper(l_entity_name)
    AND wu.project_location_code = l_project_loc_code;

    -- dbms_output.put_line('wuc code: '|| l_contract_code);
        
    --get the offset and factor
    ----------------------------------
    -- get the unit conversion info --
    ----------------------------------
    SELECT uc.factor,
          uc.offset
     INTO l_factor,
          l_offset
     from cwms_base_parameter bp,
          cwms_unit_conversion uc,
          cwms_unit u
    WHERE bp.base_parameter_id = 'Flow'
      and uc.to_unit_code = bp.unit_code
      and uc.from_unit_code = u.unit_code
      and u.unit_id = nvl(p_flow_unit_id,'cms');
    
    -- dbms_output.put_line('unit conv: '|| l_factor ||', '||l_offset);    
    
--    select count(*) into l_count from at_wat_usr_contract_accounting;
--    dbms_output.put_line('row count: '|| l_count);    
    -- delete existing data
    DELETE FROM at_wat_usr_contract_accounting 
    WHERE wat_usr_contract_acct_code IN (
        SELECT wuca.wat_usr_contract_acct_code acct_code
        FROM at_wat_usr_contract_accounting wuca
        INNER JOIN (
            SELECT loc_tw_tab.location_ref.get_location_code('F') loc_code, 
                -- convert to utc
--                loc_tw_tab.start_date start_date,
--                loc_tw_tab.end_date end_date
                cwms_util.change_timezone(
                  loc_tw_tab.start_date, 
                  l_time_zone, 
                  'UTC'
                )  start_date,
                cwms_util.change_timezone(
                  loc_tw_tab.end_date , 
                  l_time_zone, 
                  'UTC'
                ) end_date
            FROM TABLE (CAST (p_pump_time_window_tab AS loc_ref_time_window_tab_t)) loc_tw_tab
        ) loc_tw ON (
            wuca.pump_location_code = loc_tw.loc_code 
            --wuca value is in utc.
            AND wuca.transfer_start_datetime BETWEEN loc_tw.start_date AND loc_tw.end_date
        )
        WHERE wuca.water_user_contract_code = l_contract_code
    );
--    select count(*) into l_count from at_wat_usr_contract_accounting;
--    dbms_output.put_line('row count: '|| l_count);    
    
     -- insert new data
    INSERT INTO at_wat_usr_contract_accounting (
        wat_usr_contract_acct_code,
        water_user_contract_code,
        pump_location_code,
        phys_trans_type_code,
        pump_flow,
        transfer_start_datetime,
        accounting_remarks )

        select cwms_seq.nextval pk_code,
            l_contract_code contract_code,
            acct_tab.pump_location_ref.get_location_code('F') pump_code,
            ptt.phys_trans_type_code xfer_code,
            acct_tab.pump_flow * l_factor + l_offset flow,
            cwms_util.change_timezone(
                  acct_tab.transfer_start_datetime, 
                  l_time_zone, 
                  'UTC'
              ) xfer_date,
            acct_tab.accounting_remarks remarks
        from table (cast (p_accounting_tab as wat_usr_contract_acct_tab_t)) acct_tab
            left outer join cwms_office o on (o.office_id = acct_tab.physical_transfer_type.office_id)
            left outer join at_physical_transfer_type ptt on (
                ptt.phys_trans_type_display_value = acct_tab.physical_transfer_type.display_value 
                and ptt.db_office_code = o.office_code
            )
            left outer join at_water_user_contract wuc on (
                upper(acct_tab.water_user_contract_ref.contract_name) = upper(wuc.contract_name) 
                and wuc.water_user_contract_code = l_contract_code
            )
            left outer join at_water_user wu on (
                upper(acct_tab.water_user_contract_ref.water_user.entity_name) = upper(wu.entity_name) 
                and cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
                      acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
                      || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
                      || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
                    ) = l_project_loc_code
                and wuc.water_user_code = wu.water_user_code
            );
        -- where wuc.water_user_code = wu.water_user_code
        -- and wuc.water_user_contract_code = l_contract_code
--        and cwms_loc.get_location_code(acct_tab.water_user_contract_ref.water_user.project_location_ref.office_id,
--              acct_tab.water_user_contract_ref.water_user.project_location_ref.base_location_id
--              || substr ('-', 1, length (acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id))
--              || acct_tab.water_user_contract_ref.water_user.project_location_ref.sub_location_id
--            ) = l_project_loc_code
--        and upper(acct_tab.water_user_contract_ref.contract_name) = upper(wuc.contract_name)
--        AND upper(acct_tab.water_user_contract_ref.water_user.entity_name) = upper(wu.entity_name)
--        and acct_tab.physical_transfer_type.office_id = o.office_id
--        and acct_tab.physical_transfer_type.display_value = ptt.phys_trans_type_display_value
--        and ptt.db_office_code = o.office_code;

END store_accounting_set;

END cwms_water_supply;

/
show errors;
commit;

prompt Updating RATING_TEMPLATE_T type body

create or replace type body rating_template_t
as
   constructor function rating_template_t(
      p_template_code in number)
   return self as result
   is
   begin
      init(p_template_code);
      return;
   end;
   
   constructor function rating_template_t(
      p_office_id         in varchar2,
      p_version           in varchar2,
      p_ind_parameters    in rating_ind_par_spec_tab_t,
      p_dep_parameter_id  in varchar2,
      p_description       in varchar2)
   return self as result
   is
   begin
      self.office_id        := p_office_id;
      self.version          := p_version;
      self.ind_parameters   := p_ind_parameters;
      self.dep_parameter_id := p_dep_parameter_id;
      self.description      := p_description;
      for i in 1..ind_parameters.count  loop
         self.parameters_id := self.parameters_id || ind_parameters(i).parameter_id;
         if i < ind_parameters.count then
            self.parameters_id := self.parameters_id || cwms_rating.separator3;
         end if;
      end loop;
      self.parameters_id := self.parameters_id || cwms_rating.separator2 || dep_parameter_id;
      return;
   end;
   
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result
   is
   begin
      init(p_office_id, p_parameters_id, p_version);
      return;
   end;
   
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, cwms_rating.separator1);
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id,
            'Rating template identifier');
      end if;
      init(p_office_id, l_parts(1), l_parts(2));
      return;
   end;
   
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result
   is
      l_xml   xmltype;
      l_node  xmltype;
      l_parts str_tab_t;
      i       binary_integer;
      ------------------------------
      -- local function shortcuts --
      ------------------------------
      function get_node(p_xml in xmltype, p_path in varchar2) return xmltype is
      begin
         return cwms_util.get_xml_node(p_xml, p_path);
      end;
      function get_text(p_xml in xmltype, p_path in varchar2) return varchar2 is
      begin
         return cwms_util.get_xml_text(p_xml, p_path);
      end;
      function get_number(p_xml in xmltype, p_path in varchar2) return number is
      begin
         return cwms_util.get_xml_number(p_xml, p_path);
      end;
   begin
      if p_xml.existsnode('//rating-template') = 1 then
         l_xml := get_node(p_xml, '//rating-template');
      else
         cwms_err.raise(
            'ERROR',
            'Cannot locate <rating-template> element');
      end if;         
      self.office_id := get_text(l_xml, '/rating-template/@office-id');
      if self.office_id is null then
         cwms_err.raise(
            'ERROR',
            'Required "office-id" attribute is not found in <rating-template> element');
      end if;         
      self.parameters_id := get_text(l_xml, '/rating-template/parameters-id');
      if self.parameters_id is null then
         cwms_err.raise(
            'ERROR',
            '<parameters-id> element is not found under <rating-template> element');
      end if;         
      self.version := get_text(l_xml, '/rating-template/version');
      if self.version is null then
         cwms_err.raise(
            'ERROR',
            '<version> element is not found under <rating-template> element');
      end if;         
      self.dep_parameter_id := get_text(l_xml, '/rating-template/dep-parameter');
      if self.dep_parameter_id is null then
         cwms_err.raise(
            'ERROR',
            '<dep-parameter> element is not found under <rating-template> element');
      end if;
      for i in 1..9999999 loop
         l_node := get_node(l_xml, '/rating-template/ind-parameter-specs/ind-parameter-spec['||i||']');
         exit when l_node is null;
         if i = 1 then
            self.ind_parameters := rating_ind_par_spec_tab_t();
         end if;
         self.ind_parameters.extend;
         self.ind_parameters(i) := rating_ind_param_spec_t(l_node);
      end loop;
      self.description := get_text(l_xml, '/rating-template/description');
      self.validate_obj;
      return;
   end;
   
   member procedure init(
      p_template_code in number)
   is
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         ( select *
             from at_rating_template
            where template_code = p_template_code
         ) 
      loop
         self.ind_parameters    := rating_ind_par_spec_tab_t();
         self.parameters_id     := rec.parameters_id;
         self.version           := rec.version;        
         self.dep_parameter_id  := cwms_util.get_parameter_id(rec.dep_parameter_code);
         self.description       := rec.description; 
           
         select office_id
           into self.office_id
           from cwms_office
          where office_code = rec.office_code;
          
         for rec2 in 
            (  select ind_param_spec_code,
                      parameter_position
                 from at_rating_ind_param_spec
                where template_code = p_template_code
             order by parameter_position
            )
         loop
            self.ind_parameters.extend;
            self.ind_parameters(rec2.parameter_position) := -- will blow up if parameter_position is not same as .count 
               rating_ind_param_spec_t(rec2.ind_param_spec_code);
         end loop;          
      end loop;
      self.validate_obj;
   end;
   
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   is
      l_template_code number;
   begin
      l_template_code := rating_template_t.get_template_code(
         p_parameters_id,
         p_version,
         cwms_util.get_office_code(p_office_id));
         
      init(l_template_code);
   end;
   
   member procedure validate_obj
   is
      l_code  number(10);
      l_parts str_tab_t;
      l_base_id varchar2(16);
      l_sub_id  varchar2(32);
   begin
      ---------------
      -- office_id --
      ---------------
      begin
         select office_code
           into l_code
           from cwms_office
          where office_id = upper(self.office_id);
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_OFFICE_ID',
               self.office_id);
      end;
      -------------
      -- version --
      -------------
      if self.version is null then
         cwms_err.raise(
            'ERROR',
            'Rating template version cannot be null');
      end if;
      -------------------
      -- parameters_id --
      -------------------
      l_parts := cwms_util.split_text(self.parameters_id, cwms_rating.separator2);
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            self.parameters_id,
            'Rating template parameters identifier');
      end if;
      if upper(l_parts(2)) != upper(self.dep_parameter_id) then
         cwms_err.raise(
            'ERROR',
            'Rating template dependent parameter ('
            ||self.dep_parameter_id
            ||') does not agree with parameters identifier ('
            ||self.parameters_id
            ||')');
      end if;
      l_parts := cwms_util.split_text(l_parts(1), cwms_rating.separator3);
      if l_parts.count != self.ind_parameters.count then
         cwms_err.raise(
            'ERROR',
            'Rating template parameters identifier ('
            ||self.parameters_id
            ||') has '
            ||l_parts.count
            ||' independent parameters, but template contains '
            ||self.ind_parameters.count
            ||' independent parameters');
      end if;
      for i in 1..l_parts.count loop
         if upper(l_parts(i)) != upper(self.ind_parameters(i).parameter_id) then
            cwms_err.raise(
               'ERROR',
               'Rating template independent parameter position '
               ||i
               ||' ('
               ||self.ind_parameters(i).parameter_id
               ||') does not agree with parameters_id ('
               ||l_parts(i)
               ||')');
         end if;
      end loop;
      ---------------------------------         
      -- validate the lookup methods --
      ---------------------------------         
      for i in 1..self.ind_parameters.count loop
         if self.ind_parameters(i).in_range_rating_method is null or
            self.ind_parameters(i).in_range_rating_method = 'NEAREST'
         then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.ind_parameters(i).in_range_rating_method, '<NULL>'),
               'CWMS in-range rating template method');
         end if;
         if self.ind_parameters(i).out_range_low_rating_method is null or
            self.ind_parameters(i).out_range_low_rating_method in ('PREVIOUS', 'LOWER')
         then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.ind_parameters(i).out_range_low_rating_method, '<NULL>'),
               'CWMS out-range-low rating template method');
         end if;
         if self.ind_parameters(i).out_range_high_rating_method is null or
            self.ind_parameters(i).out_range_high_rating_method in ('NEXT', 'HIGHER')
         then
            cwms_err.raise(
               'INVALID_ITEM',
               nvl(self.ind_parameters(i).out_range_high_rating_method, '<NULL>'),
               'CWMS out-range-high rating template method');
         end if;
      end loop;
      -----------------------------
      -- case correct parameters --
      -----------------------------
      for i in 1..self.ind_parameters.count loop
         l_base_id := cwms_util.get_base_id(self.ind_parameters(i).parameter_id);
         l_sub_id := cwms_util.get_sub_id(self.ind_parameters(i).parameter_id);
         begin
            l_code := cwms_util.get_base_param_code(l_base_id, 'F');
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_PARAM_ID',
                  self.ind_parameters(i).parameter_id);
         end;
         select base_parameter_id
           into l_base_id 
           from cwms_base_parameter
          where base_parameter_code = l_code;
         if l_sub_id is not null then
            begin
               select distinct
                      sub_parameter_id
                 into l_sub_id 
                 from at_parameter
                where upper(sub_parameter_id) = upper(l_sub_id)
                  and db_office_code in (cwms_util.user_office_code, cwms_util.db_office_code_all); 
            exception                                                                                
               when no_data_found then null;
            end;
         end if;
         self.ind_parameters(i).parameter_id := l_base_id
            ||substr('-', 1, length(l_sub_id))
            ||l_sub_id;            
      end loop;
      l_base_id := cwms_util.get_base_id(self.dep_parameter_id);
      l_sub_id := cwms_util.get_sub_id(self.dep_parameter_id);
      begin
         l_code := cwms_util.get_base_param_code(l_base_id, 'F');
      exception
         when no_data_found then
            cwms_err.raise(
               'INVALID_PARAM_ID',
               self.dep_parameter_id);
      end;
      select base_parameter_id
        into l_base_id 
        from cwms_base_parameter
       where base_parameter_code = l_code;
      if l_sub_id is not null then
         begin
            select distinct
                   sub_parameter_id
              into l_sub_id 
              from at_parameter
             where base_parameter_code = l_code
               and upper(sub_parameter_id) = upper(l_sub_id)
               and db_office_code in (cwms_util.user_office_code, cwms_util.db_office_code_all); 
         exception                                                                                
            when no_data_found then null;
         end;
      end if;
      self.dep_parameter_id := l_base_id
         ||substr('-', 1, length(l_sub_id))
         ||l_sub_id;
      ----------------------------------------------------------------------                     
      -- reconstruct the parameters id from the case-corrected parameters --
      ----------------------------------------------------------------------
      self.parameters_id := self.ind_parameters(1).parameter_id;
      for i in 2..self.ind_parameters.count loop
         self.parameters_id := self.parameters_id 
            ||cwms_rating.separator3
            ||self.ind_parameters(i).parameter_id;
      end loop;                     
      self.parameters_id := self.parameters_id 
         ||cwms_rating.separator2
         ||self.dep_parameter_id;
         return;
   end;
      
   member function get_office_code
   return number
   is
      l_office_code number;
   begin
      select office_code
        into l_office_code
        from cwms_office
       where office_id = upper(self.office_id);
       
      return l_office_code;       
   end;
   
   member function get_dep_parameter_code
   return number
   is
      l_base_param_id varchar2(16) := cwms_util.get_base_id(self.dep_parameter_id);
      l_sub_param_id  varchar2(32) := cwms_util.get_sub_id(self.dep_parameter_id);
   begin
      return cwms_ts.get_parameter_code(l_base_param_id, l_sub_param_id, self.office_id, 'T');
   end;
   
   member procedure store(
      p_fail_if_exists in varchar2)
   is
      l_rec at_rating_template%rowtype;
      l_max_parameter_position integer := self.ind_parameters.count;
   begin
      l_rec.office_code   := self.get_office_code;
      l_rec.parameters_id := self.parameters_id;
      l_rec.version       := self.version;
      
      select *
        into l_rec
        from at_rating_template
       where office_code = l_rec.office_code
         and upper(parameters_id) = upper(l_rec.parameters_id)
         and upper(version) = upper(l_rec.version);

      if cwms_util.is_true(p_fail_if_exists) then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Rating template',
            self.office_id || '/' || self.parameters_id || cwms_rating.separator1 || self.version);
      end if;
      
      l_rec.dep_parameter_code := self.get_dep_parameter_code;
      l_rec.description        := self.description;
      
      update at_rating_template
         set row = l_rec
       where template_code = l_rec.template_code;
       
      for i in 1..l_max_parameter_position loop
         self.ind_parameters(i).store(l_rec.template_code, p_fail_if_exists);
      end loop;                
      
      delete 
        from at_rating_ind_param_spec
       where template_code = l_rec.template_code
         and parameter_position > l_max_parameter_position;
         
   exception         
      when no_data_found then
         l_rec.template_code      := cwms_seq.nextval;
         l_rec.dep_parameter_code := self.get_dep_parameter_code;
         l_rec.description        := self.description;
         
         insert
           into  at_rating_template
         values l_rec;
         
         for i in 1..l_max_parameter_position loop
            self.ind_parameters(i).store(l_rec.template_code, p_fail_if_exists);
         end loop;                
   end;

   member function to_xml
   return xmltype
   is
   begin
      return xmltype(self.to_clob);
   end;

   member function to_clob
   return clob
   is
      l_text clob;
   begin
      dbms_lob.createtemporary(l_text, true);
      dbms_lob.open(l_text, dbms_lob.lob_readwrite);
      cwms_util.append(l_text, '<rating-template office-id="'||self.office_id||'">'
         ||'<parameters-id>'||self.parameters_id||'</parameters-id>'
         ||'<version>'||self.version||'</version>'
         ||'<ind-parameter-specs>');
      for i in 1..self.ind_parameters.count loop
         cwms_util.append(l_text, self.ind_parameters(i).to_xml);
      end loop;
      cwms_util.append(l_text, '</ind-parameter-specs>'
         ||'<dep-parameter>'||self.dep_parameter_id||'</dep-parameter>'
         ||case self.description is null
              when true  then '<description/>'
              when false then '<description>'||self.description||'</description>'
           end
         ||'</rating-template>');
      dbms_lob.close(l_text);                  
      return l_text;
   end;

   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_id     in varchar2 default null)
   return number result_cache
   is
   begin
      return get_template_code(
         p_parameters_id,
         p_version,
         cwms_util.get_office_code(p_office_id));
   end;      
            
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_code   in number)
   return number result_cache
   is
      l_template_code number(10);
   begin
      select template_code
        into l_template_code
        from at_rating_template
       where office_code = p_office_code
         and upper(parameters_id) = upper(p_parameters_id)
         and upper(version) = upper(p_version);
         
      return l_template_code;
   exception
      when no_data_found then
         declare
            l_office_id varchar2(16);
         begin
            select office_id 
              into l_office_id 
              from cwms_office 
             where office_code = p_office_code;
             
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Rating template',
               l_office_id 
               || '/' 
               || p_parameters_id 
               || cwms_rating.separator1 
               || p_version);
         end;
   end;      
      
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number result_cache
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_template_id, cwms_rating.separator1);
      if l_parts.count != 2 then
         cwms_err.raise(
            'INVALID_ITEM',
            p_template_id,
            'Rating template identifier');
      end if;
      return rating_template_t.get_template_code(
         l_parts(1), 
         l_parts(2),
         p_office_code); 
   end;
   
end;
/
show errors;
commit

prompt Adding Unit 'knot'
INSERT INTO CWMS_UNIT (UNIT_CODE, UNIT_ID, ABSTRACT_PARAM_CODE, UNIT_SYSTEM, LONG_NAME, DESCRIPTION) VALUES (
        97,
        'knot',
        17, -- Linear Speed
        'EN',
        'Knots',
        'Velocity of 1 nautical mile per hour'
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'ft/s',
        'knot',
        17, -- Linear Speed
        41,
        97,
        0.5924838012958964,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'in/day',
        'knot',
        17, -- Linear Speed
        42,
        97,
        5.714542836573075E-7,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'in/hr',
        'knot',
        17, -- Linear Speed
        43,
        97,
        0.00001371490280777538,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'ft/s',
        17, -- Linear Speed
        97,
        41,
        1.687809857101196,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'in/day',
        17, -- Linear Speed
        97,
        42,
        1749921.259842520,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'in/hr',
        17, -- Linear Speed
        97,
        43,
        72913.38582677167,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'knot',
        17, -- Linear Speed
        97,
        97,
        1,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'kph',
        17, -- Linear Speed
        97,
        44,
        1.852000000000000,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'm/s',
        17, -- Linear Speed
        97,
        45,
        0.5144444444444444,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'mm/day',
        17, -- Linear Speed
        97,
        46,
        44448000.00000000,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'mm/hr',
        17, -- Linear Speed
        97,
        47,
        1852000.000000000,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'knot',
        'mph',
        17, -- Linear Speed
        97,
        48,
        1.150779448023542,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'kph',
        'knot',
        17, -- Linear Speed
        44,
        97,
        0.5399568034557236,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'm/s',
        'knot',
        17, -- Linear Speed
        45,
        97,
        1.943844492440605,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'mm/day',
        'knot',
        17, -- Linear Speed
        46,
        97,
        2.249820014398847E-8,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'mm/hr',
        'knot',
        17, -- Linear Speed
        47,
        97,
        5.399568034557236E-7,
        0,
        NULL
);
INSERT INTO CWMS_UNIT_CONVERSION (FROM_UNIT_ID, TO_UNIT_ID, ABSTRACT_PARAM_CODE, FROM_UNIT_CODE, TO_UNIT_CODE, FACTOR, OFFSET, FUNCTION) VALUES (
        'mph',
        'knot',
        17, -- Linear Speed
        48,
        97,
        0.8689762419006480,
        0,
        NULL
);
INSERT INTO AT_UNIT_ALIAS (ALIAS_ID, DB_OFFICE_CODE, UNIT_CODE) VALUES (
    'knots',
    (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'), (SELECT UNIT_CODE
        FROM   CWMS_UNIT
        WHERE  UNIT_ID='knot'
        AND    ABSTRACT_PARAM_CODE=
        (    SELECT ABSTRACT_PARAM_CODE
            FROM   CWMS_ABSTRACT_PARAMETER
            WHERE  ABSTRACT_PARAM_ID='Linear Speed'
        )
    )
);
INSERT INTO AT_UNIT_ALIAS (ALIAS_ID, DB_OFFICE_CODE, UNIT_CODE) VALUES (
    'kt',
    (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'), (SELECT UNIT_CODE
        FROM   CWMS_UNIT
        WHERE  UNIT_ID='knot'
        AND    ABSTRACT_PARAM_CODE=
        (    SELECT ABSTRACT_PARAM_CODE
            FROM   CWMS_ABSTRACT_PARAMETER
            WHERE  ABSTRACT_PARAM_ID='Linear Speed'
        )
    )
);
commit

prompt Updating Schema Version
select systimestamp from dual;

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS', 
             3,
             0,
             5,
             to_date ('30NOV2016', 'DDMONYYYY'),
             'CWMS Database Release 3.0.5',
             'Fixed bug that prevented deletion of locations with named local vertical datums.
Fixed bugs that kept elevation location levels from observing default or explicit vertical datums.
Added unit ''knot''.
');

commit;
exit
