/* Formatted on 2007/03/19 07:47 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_loc
AS
/******************************************************************************
   NAME:       CWMS_LOC
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        4/13/2005             1. Created this package.
******************************************************************************/
   l_elev_db_unit          VARCHAR2 (16) := 'm';
   l_abstract_elev_param   VARCHAR2 (32) := 'Length';

   --
   FUNCTION get_ts_code (p_office_id IN VARCHAR2, p_cwms_ts_id IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_location_code (
      p_office_id     IN   VARCHAR2,
      p_location_id   IN   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION get_office_code (p_office_id IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_state_code (p_state_initial IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   FUNCTION get_county_code (
      p_county_name     IN   VARCHAR2 DEFAULT NULL,
      p_state_initial   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

   FUNCTION convert_from_to (
      p_orig_value           IN   NUMBER,
      p_from_unit_name       IN   VARCHAR2,
      p_to_unit_name         IN   VARCHAR2,
      p_abstract_paramname   IN   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION get_unit_code (unitname IN VARCHAR2, abstractparamname IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION is_cwms_id_valid (p_base_loc_id IN VARCHAR2)
      RETURN BOOLEAN;

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
   );

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--********************************************************************** -
--********************************************************************** -
--.
--  CREATE_LOCATION -
--.
--********************************************************************** -
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
   );

--********************************************************************** -
--********************************************************************** -
--.
--  CREATE_LOCATION_RAW -
--.
--********************************************************************** -
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
   );

--
---
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv...
   PROCEDURE rename_loc (
      p_officeid          IN   VARCHAR2,
      p_base_loc_id_old   IN   VARCHAR2,
      p_base_loc_id_new   IN   VARCHAR2
   );

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--
   PROCEDURE rename_location (
      p_location_id_old   IN   VARCHAR2,
      p_location_id_new   IN   VARCHAR2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

--
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
   );

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
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
   );

--
---
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
   PROCEDURE delete_loc (p_officeid IN VARCHAR2, p_base_loc_id IN VARCHAR2);

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--- This is the 1.4 signature - MUST NOT CHANGE!!!!!!!!!!!!
---
--
   PROCEDURE delete_location (
      p_location_id     IN   VARCHAR2,
      p_delete_action   IN   VARCHAR2 DEFAULT cwms_util.delete_loc,
      p_db_office_id    IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_location_cascade (
      p_location_id    IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   );

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
   );

   PROCEDURE store_aliases (
      p_location_id    IN   VARCHAR2,
      p_alias_array    IN   alias_array,
      p_store_rule     IN   VARCHAR2 DEFAULT 'DELETE INSERT',
      p_ignorenulls    IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE store_alias (
      p_location_id         IN   VARCHAR2,
      p_agency_id           IN   VARCHAR2,
      p_alias_id            IN   VARCHAR2,
      p_agency_name         IN   VARCHAR2 DEFAULT NULL,
      p_alias_public_name   IN   VARCHAR2 DEFAULT NULL,
      p_alias_long_name     IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls         IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

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
   );

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
   );

   PROCEDURE create_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_name    IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_loc_group (
      p_loc_category_id    IN   VARCHAR2,
      p_loc_group_id_old   IN   VARCHAR2,
      p_loc_group_id_new   IN   VARCHAR2,
      p_loc_group_name     IN   VARCHAR2 DEFAULT NULL,
      p_ignore_null        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );
END cwms_loc;
/