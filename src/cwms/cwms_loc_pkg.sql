/* Formatted on 2007/05/16 07:56 (Formatter Plus v4.8.8) */
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
   function get_location_id(
      p_location_id_or_alias varchar2,
      p_office_id            varchar2 default null)
      return varchar2;

   function get_location_id(
      p_location_id_or_alias varchar2,
      p_office_code          number)
      return varchar2; 
      
   function get_location_id(
      p_location_code in number)
      return varchar2;      

   FUNCTION get_location_code (
      p_db_office_id   IN   VARCHAR2,
      p_location_id    IN   VARCHAR2
   )
      RETURN NUMBER result_cache;

   FUNCTION get_location_code (
      p_db_office_code   IN   NUMBER,
      p_location_id      IN   VARCHAR2
   )
      RETURN NUMBER result_cache;



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
--.
--  CREATE_LOCATION2 -
--.
--********************************************************************** -
--
   PROCEDURE create_location2 (
      p_location_id          IN   VARCHAR2,
      p_location_type        IN   VARCHAR2 DEFAULT NULL,
      p_elevation            IN   NUMBER DEFAULT NULL,
      p_elev_unit_id         IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum       IN   VARCHAR2 DEFAULT NULL,
      p_latitude             IN   NUMBER DEFAULT NULL,
      p_longitude            IN   NUMBER DEFAULT NULL,
      p_horizontal_datum     IN   VARCHAR2 DEFAULT NULL,
      p_public_name          IN   VARCHAR2 DEFAULT NULL,
      p_long_name            IN   VARCHAR2 DEFAULT NULL,
      p_description          IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_id         IN   VARCHAR2 DEFAULT NULL,
      p_county_name          IN   VARCHAR2 DEFAULT NULL,
      p_state_initial        IN   VARCHAR2 DEFAULT NULL,
      p_active               IN   VARCHAR2 DEFAULT NULL,
      p_location_kind_id     IN   VARCHAR2 DEFAULT NULL,
      p_map_label            IN   VARCHAR2 DEFAULT NULL,
      p_published_latitude   IN   NUMBER DEFAULT NULL,
      p_published_longitude  IN   NUMBER DEFAULT NULL,
      p_bounding_office_id   IN   VARCHAR2 DEFAULT NULL,
      p_nation_id            IN   VARCHAR2 DEFAULT NULL,
      p_nearest_city         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
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

--********************************************************************** -
--.
--  CREATE_LOCATION_RAW2 -
--.
--********************************************************************** -
--
   PROCEDURE create_location_raw2 (
      p_base_location_code   OUT  NUMBER,
      p_location_code        OUT  NUMBER,
      p_base_location_id     IN   VARCHAR2,
      p_sub_location_id      IN   VARCHAR2,
      p_db_office_code       IN   NUMBER,
      p_location_type        IN   VARCHAR2 DEFAULT NULL,
      p_elevation            IN   NUMBER DEFAULT NULL,
      p_vertical_datum       IN   VARCHAR2 DEFAULT NULL,
      p_latitude             IN   NUMBER DEFAULT NULL,
      p_longitude            IN   NUMBER DEFAULT NULL,
      p_horizontal_datum     IN   VARCHAR2 DEFAULT NULL,
      p_public_name          IN   VARCHAR2 DEFAULT NULL,
      p_long_name            IN   VARCHAR2 DEFAULT NULL,
      p_description          IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_code       IN   NUMBER DEFAULT NULL,
      p_county_code          IN   NUMBER DEFAULT NULL,
      p_active_flag          IN   VARCHAR2 DEFAULT 'T',
      p_location_kind_id     IN   VARCHAR2 DEFAULT NULL,
      p_map_label            IN   VARCHAR2 DEFAULT NULL,
      p_published_latitude   IN   NUMBER DEFAULT NULL,
      p_published_longitude  IN   NUMBER DEFAULT NULL,
      p_bounding_office_id   IN   VARCHAR2 DEFAULT NULL,
      p_nation_id            IN   VARCHAR2 DEFAULT NULL,
      p_nearest_city         IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
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

   PROCEDURE update_location2 (
      p_location_id          IN   VARCHAR2,
      p_location_type        IN   VARCHAR2 DEFAULT NULL,
      p_elevation            IN   NUMBER DEFAULT NULL,
      p_elev_unit_id         IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum       IN   VARCHAR2 DEFAULT NULL,
      p_latitude             IN   NUMBER DEFAULT NULL,
      p_longitude            IN   NUMBER DEFAULT NULL,
      p_horizontal_datum     IN   VARCHAR2 DEFAULT NULL,
      p_public_name          IN   VARCHAR2 DEFAULT NULL,
      p_long_name            IN   VARCHAR2 DEFAULT NULL,
      p_description          IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_id         IN   VARCHAR2 DEFAULT NULL,
      p_county_name          IN   VARCHAR2 DEFAULT NULL,
      p_state_initial        IN   VARCHAR2 DEFAULT NULL,
      p_active               IN   VARCHAR2 DEFAULT NULL,
      p_location_kind_id     IN   VARCHAR2 DEFAULT NULL,
      p_map_label            IN   VARCHAR2 DEFAULT NULL,
      p_published_latitude   IN   NUMBER DEFAULT NULL,
      p_published_longitude  IN   NUMBER DEFAULT NULL,
      p_bounding_office_id   IN   VARCHAR2 DEFAULT NULL,
      p_nation_id            IN   VARCHAR2 DEFAULT NULL,
      p_nearest_city         IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls          IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
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

--   PROCEDURE store_aliases (
--      p_location_id    IN   VARCHAR2,
--      p_alias_array    IN   alias_array,
--      p_store_rule     IN   VARCHAR2 DEFAULT 'DELETE INSERT',
--      p_ignorenulls    IN   VARCHAR2 DEFAULT 'T',
--      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
--   );

   --   PROCEDURE store_alias (
--      p_location_id         IN   VARCHAR2,
--      p_agency_id           IN   VARCHAR2,
--      p_alias_id            IN   VARCHAR2,
--      p_agency_name         IN   VARCHAR2 DEFAULT NULL,
--      p_alias_public_name   IN   VARCHAR2 DEFAULT NULL,
--      p_alias_long_name     IN   VARCHAR2 DEFAULT NULL,
--      p_ignorenulls         IN   VARCHAR2 DEFAULT 'T',
--      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
--   );
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
   );

   PROCEDURE store_location2 (
      p_location_id          IN   VARCHAR2,
      p_location_type        IN   VARCHAR2 DEFAULT NULL,
      p_elevation            IN   NUMBER DEFAULT NULL,
      p_elev_unit_id         IN   VARCHAR2 DEFAULT NULL,
      p_vertical_datum       IN   VARCHAR2 DEFAULT NULL,
      p_latitude             IN   NUMBER DEFAULT NULL,
      p_longitude            IN   NUMBER DEFAULT NULL,
      p_horizontal_datum     IN   VARCHAR2 DEFAULT NULL,
      p_public_name          IN   VARCHAR2 DEFAULT NULL,
      p_long_name            IN   VARCHAR2 DEFAULT NULL,
      p_description          IN   VARCHAR2 DEFAULT NULL,
      p_time_zone_id         IN   VARCHAR2 DEFAULT NULL,
      p_county_name          IN   VARCHAR2 DEFAULT NULL,
      p_state_initial        IN   VARCHAR2 DEFAULT NULL,
      p_active               IN   VARCHAR2 DEFAULT NULL,
      p_location_kind_id     IN   VARCHAR2 DEFAULT NULL,
      p_map_label            IN   VARCHAR2 DEFAULT NULL,
      p_published_latitude   IN   NUMBER DEFAULT NULL,
      p_published_longitude  IN   NUMBER DEFAULT NULL,
      p_bounding_office_id   IN   VARCHAR2 DEFAULT NULL,
      p_nation_id            IN   VARCHAR2 DEFAULT NULL,
      p_nearest_city         IN   VARCHAR2 DEFAULT NULL,
      p_ignorenulls          IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id         IN   VARCHAR2 DEFAULT NULL
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

   PROCEDURE retrieve_location2(
      p_location_id          IN OUT   VARCHAR2,
      p_elev_unit_id         IN       VARCHAR2 DEFAULT 'm',
      p_location_type        OUT      VARCHAR2,
      p_elevation            OUT      NUMBER,
      p_vertical_datum       OUT      VARCHAR2,
      p_latitude             OUT      NUMBER,
      p_longitude            OUT      NUMBER,
      p_horizontal_datum     OUT      VARCHAR2,
      p_public_name          OUT      VARCHAR2,
      p_long_name            OUT      VARCHAR2,
      p_description          OUT      VARCHAR2,
      p_time_zone_id         OUT      VARCHAR2,
      p_county_name          OUT      VARCHAR2,
      p_state_initial        OUT      VARCHAR2,
      p_active               OUT      VARCHAR2,
      p_location_kind_id     OUT      VARCHAR2,
      p_map_label            OUT      VARCHAR2,
      p_published_latitude   OUT      NUMBER,
      p_published_longitude  OUT      NUMBER,
      p_bounding_office_id   OUT      VARCHAR2,
      p_nation_id            OUT      VARCHAR2,
      p_nearest_city         OUT      VARCHAR2,
      p_alias_cursor         OUT      sys_refcursor,
      p_db_office_id         IN       VARCHAR2 DEFAULT NULL
   );

	procedure create_location_kind(
	   p_location_kind_id IN varchar2,
	   p_description      IN varchar2);

	procedure update_location_kind(
	   p_location_kind_id IN varchar2,
	   p_description      IN varchar2);

	procedure delete_location_kind(
	   p_location_kind_id in varchar2);
	   
   --------------------------------------------------------------------------------
   -- FUNCTION get_local_timezone
   --------------------------------------------------------------------------------
   function get_local_timezone(
      p_location_code in number)
      return varchar2;

   --------------------------------------------------------------------------------
   -- FUNCTION get_local_timezone
   --------------------------------------------------------------------------------
   function get_local_timezone(
      p_location_id in varchar2,
      p_office_id   in varchar2)
      return varchar2;

   PROCEDURE create_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE create_loc_group2 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL,
      p_shared_alias_id   IN   VARCHAR2 DEFAULT NULL,
      p_shared_loc_ref_id IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE store_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      p_fail_if_exists    IN   VARCHAR2 DEFAULT 'F',
      p_ignore_nulls      IN   VARCHAR2 DEFAULT 'T',
      p_shared_alias_id   IN   VARCHAR2 DEFAULT NULL,
      p_shared_loc_ref_id IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_loc_group (
      p_loc_category_id    IN   VARCHAR2,
      p_loc_group_id_old   IN   VARCHAR2,
      p_loc_group_id_new   IN   VARCHAR2,
      p_loc_group_desc     IN   VARCHAR2 DEFAULT NULL,
      p_ignore_null        IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE create_loc_category (
      p_loc_category_id     IN   VARCHAR2,
      p_loc_category_desc   IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   FUNCTION create_loc_category_f (
      p_loc_category_id     IN   VARCHAR2,
      p_loc_category_desc   IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;

   PROCEDURE store_loc_category (
      p_loc_category_id     IN   VARCHAR2,
      p_loc_category_desc   IN   VARCHAR2 DEFAULT NULL,
      p_fail_if_exists      IN   VARCHAR2 DEFAULT 'F',
      p_ignore_null         IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   );

   FUNCTION store_loc_category_f (
      p_loc_category_id     IN   VARCHAR2,
      p_loc_category_desc   IN   VARCHAR2 DEFAULT NULL,
      p_fail_if_exists      IN   VARCHAR2 DEFAULT 'F',
      p_ignore_null         IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;
      
   PROCEDURE delete_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id		IN VARCHAR2,
      p_db_office_id		IN VARCHAR2 DEFAULT NULL
   );

   PROCEDURE delete_loc_cat (
      p_loc_category_id IN   VARCHAR2,
      p_cascade 			IN VARCHAR2 DEFAULT 'F' ,
      p_db_office_id		IN VARCHAR2 DEFAULT NULL
   );

--   PROCEDURE store_alias (
--      p_location_id    IN   VARCHAR2,
--      p_category_id    IN   VARCHAR2,
--      p_group_id       IN   VARCHAR2,
--      p_alias_id       IN   VARCHAR2,
--      p_db_office_id   IN   VARCHAR2 DEFAULT NULL
--   );
   PROCEDURE assign_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_id       IN   VARCHAR2,
      p_loc_alias_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_group2 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_id       IN   VARCHAR2,
      p_loc_attribute     IN   NUMBER   DEFAULT NULL,
      p_loc_alias_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_group3 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_id       IN   VARCHAR2,
      p_loc_attribute     IN   NUMBER   DEFAULT NULL,
      p_loc_alias_id      IN   VARCHAR2 DEFAULT NULL,
      p_ref_loc_id        IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_groups (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_alias_array   IN   loc_alias_array,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_groups2 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_alias_array   IN   loc_alias_array2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_groups3 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_alias_array   IN   loc_alias_array3,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE rename_loc_category (
      p_loc_category_id_old   IN   VARCHAR2,
      p_loc_category_id_new   IN   VARCHAR2,
      p_loc_category_desc     IN   VARCHAR2 DEFAULT NULL,
      p_ignore_null           IN   VARCHAR2 DEFAULT 'T',
      p_db_office_id          IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_grp_cat (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_grps_cat (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_array   IN   group_array,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_grp_cat2 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_loc_group_desc    IN   VARCHAR2 DEFAULT NULL,
	   p_shared_alias_id   IN   VARCHAR2 DEFAULT NULL,
	   p_shared_loc_ref_id IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE assign_loc_grps_cat2 (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_array   IN   group_array2,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE unassign_loc_group (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_id       IN   VARCHAR2,
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE unassign_loc_groups (
      p_loc_category_id   IN   VARCHAR2,
      p_loc_group_id      IN   VARCHAR2,
      p_location_array    IN   char_49_array_type,
      p_unassign_all      IN   VARCHAR2 DEFAULT 'F',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   );

   FUNCTION num_group_assigned_to_shef (
      p_group_cat_array   IN   group_cat_tab_t,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;
      
   FUNCTION retrieve_location (
      p_location_code IN NUMBER
   )
      RETURN location_obj_t;
      
   FUNCTION retrieve_location (
      p_location_id  in VARCHAR2,
      p_db_office_id in VARCHAR2 DEFAULT NULL
   )
      RETURN location_obj_t;
      
   PROCEDURE store_location (
      p_location       IN location_obj_t,
      p_fail_if_exists IN VARCHAR2 default 'T'
   );

  FUNCTION store_location_f (
    p_location       IN location_obj_t,
    p_fail_if_exists IN VARCHAR2 default 'T'
  )
    RETURN NUMBER;

   function get_location_id_from_alias(
      p_alias_id    in varchar2,
      p_group_id    in varchar2 default null,
      p_category_id in varchar2 default null,
      p_office_id   in varchar2 default null)
      return varchar2;
   
   function get_location_code_from_alias(
      p_alias_id    in varchar2,
      p_group_id    in varchar2 default null,
      p_category_id in varchar2 default null,
      p_office_id   in varchar2 default null)
      return number;
   
   procedure check_alias_id(
      p_alias_id    in varchar2,
      p_location_id in varchar2,
      p_category_id in varchar2,
      p_group_id    in varchar2,
      p_office_id   in varchar2 default null);      
   
   function check_alias_id_f(
      p_alias_id    in varchar2,
      p_location_id in varchar2,
      p_category_id in varchar2,
      p_group_id    in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2;
      
   procedure store_url(
      p_location_id    in varchar2,
      p_url_id         in varchar2,
      p_url_address    in varchar2,
      p_fail_if_exists in varchar2,
      p_ignore_nulls   in varchar2,
      p_url_title      in varchar2 default null,
      p_office_id      in varchar2 default null);
      
   procedure retrieve_url(
      p_url_address    out varchar2,
      p_url_title      out varchar2,
      p_location_id    in  varchar2,
      p_url_id         in  varchar2,
      p_office_id      in  varchar2 default null);
      
   procedure delete_url(
      p_location_id in varchar2,
      p_url_id      in varchar2,-- NULL = all urls
      p_office_id   in varchar2 default null);
      
   procedure rename_url(
      p_location_id in varchar2,
      p_old_url_id  in varchar2,
      p_new_url_id  in varchar2,
      p_office_id   in varchar2 default null);

   -- cursor contains:
   --
   --    office_id   varchar2(16)   sort column 1
   --    location_id varchar2(49)   sort column 2
   --    url_id      varchar2(32)   sort column 3
   --    url_address varchar2(1024)
   --    url_title   varchar2(256)
   --   
   procedure cat_urls(
      p_url_catalog      out sys_refcursor,
      p_location_id_mask in  varchar2 default '*',
      p_url_id_mask      in  varchar2 default '*',
      p_url_address_mask in  varchar2 default '*',
      p_url_title_mask   in  varchar2 default '*',
      p_office_id_mask   in  varchar2 default null);
      
   -- cursor contains:
   --
   --    office_id   varchar2(16)   sort column 1
   --    location_id varchar2(49)   sort column 2
   --    url_id      varchar2(32)   sort column 3
   --    url_address varchar2(1024)
   --    url_title   varchar2(256)
   --   
   function cat_urls_f(
      p_location_id_mask in  varchar2 default '*',
      p_url_id_mask      in  varchar2 default '*',
      p_url_address_mask in  varchar2 default '*',
      p_url_title_mask   in  varchar2 default '*',
      p_office_id_mask   in  varchar2 default null)
      return sys_refcursor;
            
END cwms_loc;
/
show errors;
