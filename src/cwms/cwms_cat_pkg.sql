/* Formatted on 2008/11/07 08:47 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_cat
/**
 * Routines that catalog various items in the CWMS database.<p>
 * Most of the procedures in this package have an associated function that returns
 * a table type.  Although these package types are not formally documented, they
 * are tables of record types have the same fields as the cursors, which <em>are</em>
 * documented.  The return values of these functions are suitable for using in SELECT
 * statements, provided that they the return values are wrapped in a TABLE() function.
 *
 * @author Various
 *
 * @since CWMS 2.0
 */
IS
   -- not documented
   TYPE cat_ts_rec_t IS RECORD (
      office_id             VARCHAR2 (16),
      cwms_ts_id            VARCHAR2 (183),
      interval_utc_offset   NUMBER
   );
   -- not documented
   TYPE cat_ts_tab_t IS TABLE OF cat_ts_rec_t;
   -- not documented
   TYPE cat_ts_cwms_20_rec_t IS RECORD (
      office_id             VARCHAR2 (16),
      cwms_ts_id            VARCHAR2 (183),
      interval_utc_offset   NUMBER (10),
      user_privileges       NUMBER,
      inactive              NUMBER,
      lrts_timezone         VARCHAR2 (28)
   );
   -- not documented
   TYPE cat_ts_cwms_20_tab_t IS TABLE OF cat_ts_cwms_20_rec_t;
   -- not documented
   TYPE cat_ts_id_rec_t IS RECORD (
      db_office_id          VARCHAR2 (16),
      base_location_id      VARCHAR2 (16),
      cwms_ts_id            VARCHAR2 (183),
      interval_utc_offset   NUMBER (10),
      lrts_timezone         VARCHAR2 (28),
      active_flag           VARCHAR2 (1),
      user_privileges       NUMBER
   );
   -- not documented
   TYPE cat_ts_id_tab_t IS TABLE OF cat_ts_id_rec_t;
   -- not documented
   TYPE cat_loc_rec_t IS RECORD (
      office_id        VARCHAR2 (16),
      base_loc_id      VARCHAR2 (16),
      state_initial    VARCHAR2 (2),
      county_name      VARCHAR2 (40),
      timezone_name    VARCHAR2 (28),
      location_type    VARCHAR2 (32),
      latitude         NUMBER,
      longitude        NUMBER,
      elevation        NUMBER,
      elev_unit_id     VARCHAR2 (16),
      vertical_datum   VARCHAR2 (16),
      public_name      VARCHAR2 (32),
      long_name        VARCHAR2 (80),
      description      VARCHAR2 (512)
   );
   -- not documented
   TYPE cat_loc_tab_t IS TABLE OF cat_loc_rec_t;
   -- not documented
   TYPE cat_location_rec_t IS RECORD (
      db_office_id       VARCHAR2 (16),
      location_id        VARCHAR2 (49),
      base_location_id   VARCHAR2 (16),
      sub_location_id    VARCHAR2 (32),
      state_initial      VARCHAR2 (2),
      county_name        VARCHAR2 (40),
      time_zone_name     VARCHAR2 (28),
      location_type      VARCHAR2 (32),
      latitude           NUMBER,
      longitude          NUMBER,
      horizontal_datum   VARCHAR2 (16),
      elevation          NUMBER,
      elev_unit_id       VARCHAR2 (16),
      vertical_datum     VARCHAR2 (16),
      public_name        VARCHAR2 (32),
      long_name          VARCHAR2 (80),
      description        VARCHAR2 (512),
      active_flag        VARCHAR2 (1)
   );
   -- not documented
   TYPE cat_location_tab_t IS TABLE OF cat_location_rec_t;
   -- not documented
   TYPE cat_location2_rec_t IS RECORD (
      db_office_id         VARCHAR2 (16),
      location_id          VARCHAR2 (49),
      base_location_id     VARCHAR2 (16),
      sub_location_id      VARCHAR2 (32),
      state_initial        VARCHAR2 (2),
      county_name          VARCHAR2 (40),
      time_zone_name       VARCHAR2 (28),
      location_type        VARCHAR2 (32),
      latitude             NUMBER,
      longitude            NUMBER,
      horizontal_datum     VARCHAR2 (16),
      elevation            NUMBER,
      elev_unit_id         VARCHAR2 (16),
      vertical_datum       VARCHAR2 (16),
      public_name          VARCHAR2 (32),
      long_name            VARCHAR2 (80),
      description          VARCHAR2 (512),
      active_flag          VARCHAR2 (1),
      location_kind_id     varchar2(32),
      map_label            varchar2(50),
      published_latitude   number,
      published_longitude  number,
      bounding_office_id   varchar2(16),
      nation_id            varchar2(48),
      nearest_city         varchar2(50)
   );
   -- not documented
   TYPE cat_location2_tab_t IS TABLE OF cat_location2_rec_t;
   -- not documented
   TYPE cat_location_kind_rec_t IS RECORD (
    office_id        VARCHAR2(16),
		location_kind_id VARCHAR2(32),
		description      VARCHAR2(256)
	);
   -- not documented
	TYPE cat_location_kind_tab_t IS TABLE OF cat_location_kind_rec_t;
   -- not documented
   TYPE cat_loc_grp_rec_t IS RECORD (
      cat_db_office_id    VARCHAR2 (16),
      loc_category_id     VARCHAR2 (32),
      loc_category_desc   VARCHAR2 (128),
      grp_db_office_id    VARCHAR2 (16),
      loc_group_id        VARCHAR2 (32),
      loc_group_desc      VARCHAR2 (128),
	   shared_loc_alias_id VARCHAR2 (128),
		shared_loc_ref_id   VARCHAR2 (49)
   );
   -- not documented
   TYPE cat_loc_grp_tab_t IS TABLE OF cat_loc_grp_rec_t;
   -- not documented
   TYPE cat_loc_alias_rec_t IS RECORD (
      db_office_id        VARCHAR2 (16),
      location_id         VARCHAR2 (49),
      cat_db_office_id    VARCHAR2 (16),
      loc_category_id     VARCHAR2 (32),
      grp_db_office_id    VARCHAR2 (16),
      loc_group_id        VARCHAR2 (32),
      loc_group_desc      VARCHAR2 (128),
      loc_alias_id        VARCHAR2 (128),
		loc_ref_id          VARCHAR2 (49),
      shared_loc_alias_id VARCHAR2 (128),
      shared_loc_ref_id   VARCHAR2 (49),
      attribute           NUMBER
   );
   -- not documented
   TYPE cat_loc_alias_tab_t IS TABLE OF cat_loc_alias_rec_t;
   -- not documented
   TYPE cat_loc_alias_abbrev_rec_t IS RECORD (
      office_id     VARCHAR2 (16),
      location_id   VARCHAR2 (49),
      agency_id     VARCHAR2 (16),
      alias_id      VARCHAR2 (128),
		loc_ref_id    VARCHAR2 (49)
   );
   -- not documented
   TYPE cat_loc_alias_abbrev_tab_t IS TABLE OF cat_loc_alias_abbrev_rec_t;
   -- not documented
   TYPE cat_ts_grp_rec_t IS RECORD (
      cat_db_office_id   VARCHAR2 (16),
      ts_category_id     VARCHAR2 (32),
      ts_category_desc   VARCHAR2 (128),
      grp_db_office_id   VARCHAR2 (16),
      ts_group_id        VARCHAR2 (32),
      ts_group_desc      VARCHAR2 (128),
      shared_ts_alias_id VARCHAR2 (256),
      shared_ts_ref_id   VARCHAR2 (256)
   );
   -- not documented
   TYPE cat_ts_grp_tab_t IS TABLE OF cat_ts_grp_rec_t;
   -- not documented
   TYPE cat_ts_alias_rec_t IS RECORD (
      db_office_id       VARCHAR2 (16),
      ts_id              VARCHAR2 (183),
      cat_db_office_id   VARCHAR2 (16),
      ts_category_id     VARCHAR2 (32),
      grp_db_office_id   VARCHAR2 (16),
      ts_group_id        VARCHAR2 (32),
      ts_group_desc      VARCHAR2 (128),
      ts_alias_id        VARCHAR2 (256),
      ts_ref_id          VARCHAR2 (183),
      shared_ts_alias_id VARCHAR2 (256),
      shared_ts_ref_id   VARCHAR2 (183),
      attribute          NUMBER
   );
   -- not documented
   TYPE cat_ts_alias_tab_t IS TABLE OF cat_ts_alias_rec_t;
   -- not documented
   TYPE cat_base_param_rec_t IS RECORD (
      parameter_id        VARCHAR2 (16),
      param_long_name     VARCHAR2 (80),
      param_description   VARCHAR2 (160),
      db_unit_id          VARCHAR2 (16),
      unit_long_name      VARCHAR2 (80),
      unit_description    VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_base_param_tab_t IS TABLE OF cat_base_param_rec_t;
   -- not documented
   TYPE cat_parameter_rec_t IS RECORD (
      parameter_id         VARCHAR2 (49),
      base_parameter_id    VARCHAR2 (16),
      sub_parameter_id     VARCHAR2 (32),
      sub_parameter_desc   VARCHAR2 (160),
      db_office_id         VARCHAR2 (16),
      db_unit_id           VARCHAR2 (16),
      unit_long_name       VARCHAR2 (80),
      unit_description     VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_parameter_tab_t IS TABLE OF cat_parameter_rec_t;
   -- not documented
   TYPE cat_param_rec_t IS RECORD (
      parameter_id        VARCHAR2 (16),
      param_long_name     VARCHAR2 (80),
      param_description   VARCHAR2 (160),
      unit_id             VARCHAR2 (16),
      unit_long_name      VARCHAR2 (80),
      unit_description    VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_param_tab_t IS TABLE OF cat_param_rec_t;
   -- not documented
   TYPE cat_sub_param_rec_t IS RECORD (
      parameter_id      VARCHAR2 (16),
      subparameter_id   VARCHAR2 (32),
      description       VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_sub_param_tab_t IS TABLE OF cat_sub_param_rec_t;
   -- not documented
   TYPE cat_sub_loc_rec_t IS RECORD (
      sublocation_id   VARCHAR2 (32),
      description      VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_sub_loc_tab_t IS TABLE OF cat_sub_loc_rec_t;
   -- not documented
   TYPE cat_parameter_type_rec_t IS RECORD (
      parameter_type_id   VARCHAR2 (16),
      description         VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_parameter_type_tab_t IS TABLE OF cat_parameter_type_rec_t;
   -- not documented
   TYPE cat_interval_rec_t IS RECORD (
      interval_id    VARCHAR2 (16),
      interval_min   NUMBER,
      description    VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_interval_tab_t IS TABLE OF cat_interval_rec_t;
   -- not documented
   TYPE cat_duration_rec_t IS RECORD (
      duration_id    VARCHAR2 (16),
      duration_min   NUMBER,
      description    VARCHAR2 (80)
   );
   -- not documented
   TYPE cat_duration_tab_t IS TABLE OF cat_duration_rec_t;
   -- not documented
   TYPE cat_state_rec_t IS RECORD (
      state_initial   VARCHAR2 (2),
      state_name      VARCHAR2 (40)
   );
   -- not documented
   TYPE cat_state_tab_t IS TABLE OF cat_state_rec_t;
   -- not documented
   TYPE cat_county_rec_t IS RECORD (
      county_id       VARCHAR2 (3),
      county_name     VARCHAR2 (40),
      state_initial   VARCHAR2 (2)
   );
   -- not documented
   TYPE cat_county_tab_t IS TABLE OF cat_county_rec_t;
   -- not documented
   TYPE cat_timezone_rec_t IS RECORD (
      timezone_name   VARCHAR2 (28),
      utc_offset      INTERVAL DAY (2)TO SECOND (6),
      dst_offset      INTERVAL DAY (2)TO SECOND (6)
   );
   -- not documented
   TYPE cat_timezone_tab_t IS TABLE OF cat_timezone_rec_t;
   -- not documented
   TYPE cat_dss_file_rec_t IS RECORD (
      office_id         VARCHAR2 (16),
      dss_filemgr_url   VARCHAR2 (256),
      dss_file_name     VARCHAR2 (256)
   );
   -- not documented
   TYPE cat_dss_file_tab_t IS TABLE OF cat_dss_file_rec_t;
   -- not documented
   TYPE cat_dss_xchg_set_rec_t IS RECORD (
      office_id                  VARCHAR2 (16),
      dss_xchg_set_id            VARCHAR (32),
      dss_xchg_set_description   VARCHAR (80),
      dss_filemgr_url            VARCHAR2 (32),
      dss_file_name              VARCHAR2 (255),
      dss_xchg_direction_id      VARCHAR2 (16),
      dss_xchg_last_update       TIMESTAMP ( 6 )
   );
   -- not documented
   TYPE cat_dss_xchg_set_tab_t IS TABLE OF cat_dss_xchg_set_rec_t;
   -- not documented
   TYPE cat_dss_xchg_ts_map_rec_t IS RECORD (
      office_id               VARCHAR2 (16),
      cwms_ts_id              VARCHAR2 (183),
      dss_pathname            VARCHAR2 (391),
      dss_parameter_type_id   VARCHAR2 (8),
      dss_unit_id             VARCHAR2 (16),
      dss_timezone_name       VARCHAR2 (28),
      dss_tz_usage_id         VARCHAR2 (8)
   );
   -- not documented
   TYPE cat_dss_xchg_ts_map_tab_t IS TABLE OF cat_dss_xchg_ts_map_rec_t;
   -- not documented
   TYPE cat_property_rec_t IS RECORD (
      office_id        VARCHAR2 (16),
      prop_category    VARCHAR2 (256),
      prop_id          VARCHAR2 (256)
   );
   -- not documented
   TYPE cat_property_tab_t IS TABLE OF cat_property_rec_t;
-- cat_ts...
   -- not documented
   FUNCTION cat_ts_rec2obj (r IN cat_ts_rec_t)
      RETURN cat_ts_obj_t;
   -- not documented
   FUNCTION cat_ts_tab2obj (t IN cat_ts_tab_t)
      RETURN cat_ts_otab_t;
   -- not documented
   FUNCTION cat_ts_obj2rec (o IN cat_ts_obj_t)
      RETURN cat_ts_rec_t;
   -- not documented
   FUNCTION cat_ts_obj2tab (o IN cat_ts_otab_t)
      RETURN cat_ts_tab_t;
-- cat_ts_cwms_20...
   -- not documented
   FUNCTION cat_ts_cwms_20_rec2obj (r IN cat_ts_cwms_20_rec_t)
      RETURN cat_ts_cwms_20_obj_t;
   -- not documented
   FUNCTION cat_ts_cwms_20_tab2obj (t IN cat_ts_cwms_20_tab_t)
      RETURN cat_ts_cwms_20_otab_t;
   -- not documented
   FUNCTION cat_ts_cwms_20_obj2rec (o IN cat_ts_cwms_20_obj_t)
      RETURN cat_ts_cwms_20_rec_t;
   -- not documented
   FUNCTION cat_ts_cwms_20_obj2tab (o IN cat_ts_cwms_20_otab_t)
      RETURN cat_ts_cwms_20_tab_t;
-- cat_loc...
   -- not documented
   FUNCTION cat_loc_rec2obj (r IN cat_loc_rec_t)
      RETURN cat_loc_obj_t;
   -- not documented
   FUNCTION cat_loc_tab2obj (t IN cat_loc_tab_t)
      RETURN cat_loc_otab_t;
   -- not documented
   FUNCTION cat_loc_obj2rec (o IN cat_loc_obj_t)
      RETURN cat_loc_rec_t;
   -- not documented
   FUNCTION cat_loc_obj2tab (o IN cat_loc_otab_t)
      RETURN cat_loc_tab_t;
-- cat_location...
   -- not documented
   FUNCTION cat_location_rec2obj (r IN cat_location_rec_t)
      RETURN cat_location_obj_t;
   -- not documented
   FUNCTION cat_location_tab2obj (t IN cat_location_tab_t)
      RETURN cat_location_otab_t;
   -- not documented
   FUNCTION cat_location_obj2rec (o IN cat_location_obj_t)
      RETURN cat_location_rec_t;
   -- not documented
   FUNCTION cat_location_obj2tab (o IN cat_location_otab_t)
      RETURN cat_location_tab_t;
-- cat_location2...
   -- not documented
   FUNCTION cat_location2_rec2obj (r IN cat_location2_rec_t)
      RETURN cat_location2_obj_t;
   -- not documented
   FUNCTION cat_location2_tab2obj (t IN cat_location2_tab_t)
      RETURN cat_location2_otab_t;
   -- not documented
   FUNCTION cat_location2_obj2rec (o IN cat_location2_obj_t)
      RETURN cat_location2_rec_t;
   -- not documented
   FUNCTION cat_location2_obj2tab (o IN cat_location2_otab_t)
      RETURN cat_location2_tab_t;
-- cat_location_kind...
   -- not documented
   FUNCTION cat_location_kind_rec2obj (r IN cat_location_kind_rec_t)
      RETURN cat_location_kind_obj_t;
   -- not documented
   FUNCTION cat_location_kind_tab2obj (t IN cat_location_kind_tab_t)
      RETURN cat_location_kind_otab_t;
   -- not documented
   FUNCTION cat_location_kind_obj2rec (o IN cat_location_kind_obj_t)
      RETURN cat_location_kind_rec_t;
   -- not documented
   FUNCTION cat_location_kind_obj2tab (o IN cat_location_kind_otab_t)
      RETURN cat_location_kind_tab_t;
-- cat_param...
   -- not documented
   FUNCTION cat_param_rec2obj (r IN cat_param_rec_t)
      RETURN cat_param_obj_t;
   -- not documented
   FUNCTION cat_param_tab2obj (t IN cat_param_tab_t)
      RETURN cat_param_otab_t;
   -- not documented
   FUNCTION cat_param_obj2rec (o IN cat_param_obj_t)
      RETURN cat_param_rec_t;
   -- not documented
   FUNCTION cat_param_obj2tab (o IN cat_param_otab_t)
      RETURN cat_param_tab_t;
-- cat_sub_param.
   -- not documented
   FUNCTION cat_sub_param_rec2obj (r IN cat_sub_param_rec_t)
      RETURN cat_sub_param_obj_t;
   -- not documented
   FUNCTION cat_sub_param_tab2obj (t IN cat_sub_param_tab_t)
      RETURN cat_sub_param_otab_t;
   -- not documented
   FUNCTION cat_sub_param_obj2rec (o IN cat_sub_param_obj_t)
      RETURN cat_sub_param_rec_t;
   -- not documented
   FUNCTION cat_sub_param_obj2tab (o IN cat_sub_param_otab_t)
      RETURN cat_sub_param_tab_t;
-- cat_sub_loc...
   -- not documented
   FUNCTION cat_sub_loc_rec2obj (r IN cat_sub_loc_rec_t)
      RETURN cat_sub_loc_obj_t;
   -- not documented
   FUNCTION cat_sub_loc_tab2obj (t IN cat_sub_loc_tab_t)
      RETURN cat_sub_loc_otab_t;
   -- not documented
   FUNCTION cat_sub_loc_obj2rec (o IN cat_sub_loc_obj_t)
      RETURN cat_sub_loc_rec_t;
   -- not documented
   FUNCTION cat_sub_loc_obj2tab (o IN cat_sub_loc_otab_t)
      RETURN cat_sub_loc_tab_t;
-- cat_state.
   -- not documented
   FUNCTION cat_state_rec2obj (r IN cat_state_rec_t)
      RETURN cat_state_obj_t;
   -- not documented
   FUNCTION cat_state_tab2obj (t IN cat_state_tab_t)
      RETURN cat_state_otab_t;
   -- not documented
   FUNCTION cat_state_obj2rec (o IN cat_state_obj_t)
      RETURN cat_state_rec_t;
   -- not documented
   FUNCTION cat_state_obj2tab (o IN cat_state_otab_t)
      RETURN cat_state_tab_t;
-- cat_county.
   -- not documented
   FUNCTION cat_county_rec2obj (r IN cat_county_rec_t)
      RETURN cat_county_obj_t;
   -- not documented
   FUNCTION cat_county_tab2obj (t IN cat_county_tab_t)
      RETURN cat_county_otab_t;
   -- not documented
   FUNCTION cat_county_obj2rec (o IN cat_county_obj_t)
      RETURN cat_county_rec_t;
   -- not documented
   FUNCTION cat_county_obj2tab (o IN cat_county_otab_t)
      RETURN cat_county_tab_t;
-- cat_timezone.
   -- not documented
   FUNCTION cat_timezone_rec2obj (r IN cat_timezone_rec_t)
      RETURN cat_timezone_obj_t;
   -- not documented
   FUNCTION cat_timezone_tab2obj (t IN cat_timezone_tab_t)
      RETURN cat_timezone_otab_t;
   -- not documented
   FUNCTION cat_timezone_obj2rec (o IN cat_timezone_obj_t)
      RETURN cat_timezone_rec_t;
   -- not documented
   FUNCTION cat_timezone_obj2tab (o IN cat_timezone_otab_t)
      RETURN cat_timezone_tab_t;
-- cat_dss_file.
   -- not documented
   FUNCTION cat_dss_file_rec2obj (r IN cat_dss_file_rec_t)
      RETURN cat_dss_file_obj_t;
   -- not documented
   FUNCTION cat_dss_file_tab2obj (t IN cat_dss_file_tab_t)
      RETURN cat_dss_file_otab_t;
   -- not documented
   FUNCTION cat_dss_file_obj2rec (o IN cat_dss_file_obj_t)
      RETURN cat_dss_file_rec_t;
   -- not documented
   FUNCTION cat_dss_file_obj2tab (o IN cat_dss_file_otab_t)
      RETURN cat_dss_file_tab_t;
-- cat_dss_xchg_set.
   -- not documented
   FUNCTION cat_dss_xchg_set_rec2obj (r IN cat_dss_xchg_set_rec_t)
      RETURN cat_dss_xchg_set_obj_t;
   -- not documented
   FUNCTION cat_dss_xchg_set_tab2obj (t IN cat_dss_xchg_set_tab_t)
      RETURN cat_dss_xchg_set_otab_t;
   -- not documented
   FUNCTION cat_dss_xchg_set_obj2rec (o IN cat_dss_xchg_set_obj_t)
      RETURN cat_dss_xchg_set_rec_t;
   -- not documented
   FUNCTION cat_dss_xchg_set_obj2tab (o IN cat_dss_xchg_set_otab_t)
      RETURN cat_dss_xchg_set_tab_t;
-- cat_dss_xchg_ts_map.
   -- not documented
   FUNCTION cat_dss_xchg_ts_map_rec2obj (r IN cat_dss_xchg_ts_map_rec_t)
      RETURN cat_dss_xchg_ts_map_obj_t;
   -- not documented
   FUNCTION cat_dss_xchg_ts_map_tab2obj (t IN cat_dss_xchg_ts_map_tab_t)
      RETURN cat_dss_xchg_tsmap_otab_t;
   -- not documented
   FUNCTION cat_dss_xchg_ts_map_obj2rec (o IN cat_dss_xchg_ts_map_obj_t)
      RETURN cat_dss_xchg_ts_map_rec_t;
   -- not documented
   FUNCTION cat_dss_xchg_ts_map_obj2tab (o IN cat_dss_xchg_tsmap_otab_t)
      RETURN cat_dss_xchg_ts_map_tab_t;
-------------------------------------------------------------------------------
-- CAT_TS
--
-- These procedures and functions catalog time series identifiers in the
-- database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records or cursors contain the following columns:
--
--    Name                Datatype      Description
--    ------------------- ------------- ----------------------------
--    office_id           varchar2(16)  Name of owning office
--    cwms_ts_id          varchar2(183) Time series identifier
--    interval_utc_offset number(10)    Offset into the UTC interval
--    lrts_timezone*      varchar2(28)  Name of LRTS time zone or null
--
-- *The lrts_timezone column is returned only for cat_ts_cwms_20
--
-- If the p_office_id parameter is not null, only records with matching office
-- ids are returned.  Otherwise, records for all offices are returned.
--
-- If the p_ts_subselect_string is not null, it is used in a LIKE clause to
-- match the cwms_ts_id field.  This parameter may use filename-type wildcards
-- (*, ?) and/or SQL-type wildcards (%, _).
--
-- The records are returned sorted first by office_id (ascending) and then by
-- cwms_ts_id (ascending, non-case-sensitive).
--
-------------------------------------------------------------------------------
-- function cat_ts_tab(...)
--
   -- not documented
   FUNCTION cat_ts_tab (
      p_office_id             IN   VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_tab_t PIPELINED;
-------------------------------------------------------------------------------
-- procedure cat_ts(...)
--
--
   -- not documented
   PROCEDURE cat_ts (
      p_cwms_cat              OUT      sys_refcursor,
      p_office_id             IN       VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL
   );
   -- not documented
-------------------------------------------------------------------------------
-- function cat_ts_cwms_20_tab(...)
--
--
   -- not documented
   FUNCTION cat_ts_cwms_20_tab (
      p_office_id             IN   VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_cwms_20_tab_t PIPELINED;
-------------------------------------------------------------------------------
-- procedure cat_ts_cwms_20(...)
--
--
   -- not documented
   PROCEDURE cat_ts_cwms_20 (
      p_cwms_cat              OUT      sys_refcursor,
      p_office_id             IN       VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs time series in the database that match specified parameter. Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat  A cursor containing the cataloged time series. The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">base_location_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base location identifier of the time serires</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">cwms_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">The time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">interval_utc_offset</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The offset into the UTC interval for regular time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">time_zone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The local time zone for the location of the time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">lrts_timezone</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">Not used</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">ts_active_flag</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the time series is marked as active</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">user_privileges</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The session user's privileges for the time series</td>
    *   </tr>
    * </table>
    * @param p_ts_subselect_string  The time series identifier pattern to match. Use glob-style wildcards characters as shown above.
    * @param p_loc_category_id      A location category to restrict the catalog to. If not specified or NULL, no location category restriction will be used.
    * @param p_loc_group_id         A location group to restrict the catalog to. If not specified or NULL, no location group restriction will be used.
    * @param p_ts_category_id       A time series category to restrict the catalog to. If not specified or NULL, no time series category restriction will be used.
    * @param p_ts_group_id          A time series group to restrict the catalog to. If not specified or NULL, no time series group restriction will be used.
    * @param p_db_office_id         The office to restrict the catalog to.  If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_ts_id_tab
    */
   PROCEDURE cat_ts_id (
      p_cwms_cat              OUT      sys_refcursor,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL,
      p_loc_category_id       IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id          IN       VARCHAR2 DEFAULT NULL,
      p_ts_category_id        IN       VARCHAR2 DEFAULT NULL,
      p_ts_group_id           IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id          IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs time series in the database that match specified parameter. Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    *
    * @param p_ts_subselect_string  The time series identifier pattern to match. Use glob-style wildcards characters as shown above.
    * @param p_loc_category_id      A location category to restrict the catalog to. If not specified or NULL, no location category restriction will be used.
    * @param p_loc_group_id         A location group to restrict the catalog to. If not specified or NULL, no location group restriction will be used.
    * @param p_ts_category_id       A time series category to restrict the catalog to. If not specified or NULL, no time series category restriction will be used.
    * @param p_ts_group_id          A time series group to restrict the catalog to. If not specified or NULL, no time series group restriction will be used.
    * @param p_db_office_id         The office to restrict the catalog to.  If not specified or NULL, the session user's default office will be used.
    *
    * @return  A cursor containing the cataloged time series. The cursor is suitable
    * for using in a SELECT statement by wrapping it in the TABLE function. The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">base_location_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base location identifier of the time serires</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">cwms_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">The time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">interval_utc_offset</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The offset into the UTC interval for regular time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">time_zone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The local time zone for the location of the time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">lrts_timezone</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">Not used</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">ts_active_flag</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the time series is marked as active</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">user_privileges</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The session user's privileges for the time series</td>
    *   </tr>
    * </table>
    *
    * @see cat_ts_id
    */
   FUNCTION cat_ts_id_tab (
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL,
      p_loc_category_id       IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id          IN   VARCHAR2 DEFAULT NULL,
      p_ts_category_id        IN   VARCHAR2 DEFAULT NULL,
      p_ts_group_id           IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id          IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_id_tab_t PIPELINED;
   -- not documented
   procedure cat_ts_alias (
      p_cwms_cat     out sys_refcursor,
      p_cwms_ts_id   in  varchar2 default null,
      p_db_office_id in  varchar2 default null
   );
   /**
    * Catalogs time series aliases in the database that match specified parameters.
    * Matching is accomplished with glob-style wildcards, as shown below, instead
    * SQL-style wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat The cursor containing the time series aliases that match the specified parameters.
    * The cursor will contain the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">The time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">ts_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time series category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">ts_group_id</td>
    *     <td class="descr">varchar2(65)</td>
    *     <td class="descr">The time series group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">ts_group_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">ts_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The alias for the time series with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">ref_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">A referenced time series identifier for the time series with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">shared_ts_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">An alias shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">shared_ref_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">A referenced time series identifier shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">ts_attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A numeric attribute for the time series with respect to the group. Can be used for sorting, etc...</td>
    *   </tr>
    * </table>
    * @param p_ts_id          The time series identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all time series identifiers will be matched.
    * @param p_ts_category_id The time series category identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all time series category identifiers will be matched.
    * @param p_ts_group_id    The time series group identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all time series group identifiers will be matched.
    * @param p_abbreviated    A flag ('T' or 'F') specifying whether to catalog only time series that are members of time series groups.
    * @param p_db_office_id   The office that owns the time series. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_ts_aliases_tab
    */
   procedure cat_ts_aliases (
      p_cwms_cat       out sys_refcursor,
      p_ts_id          in  varchar2 default null,
      p_ts_category_id in  varchar2 default null,
      p_ts_group_id    in  varchar2 default null,
      p_abbreviated    in  varchar2 default 'T',
      p_db_office_id   in  varchar2 default null
   );
   /**
    * Catalogs time series aliases in the database that match specified parameters.
    * Matching is accomplished with glob-style wildcards, as shown below, instead
    * SQL-style wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_ts_id          The time series identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all time series identifiers will be matched.
    * @param p_ts_category_id The time series category identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all time series category identifiers will be matched.
    * @param p_ts_group_id    The time series group identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all time series group identifiers will be matched.
    * @param p_abbreviated    A flag ('T' or 'F') specifying whether to catalog only time series that are members of time series groups.
    * @param p_db_office_id   The office that owns the time series. If not specified or NULL, the session user's default office will be used.
    *
    * @return The cursor containing the time series aliases that match the specified parameters.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">The time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">ts_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time series category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">ts_group_id</td>
    *     <td class="descr">varchar2(65)</td>
    *     <td class="descr">The time series group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">ts_group_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">ts_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The alias for the time series with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">ref_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">A referenced time series identifier for the time series with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">shared_ts_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">An alias shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">shared_ref_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">A referenced time series identifier shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">ts_attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A numeric attribute for the time series with respect to the group. Can be used for sorting, etc...</td>
    *   </tr>
    * </table>
    *
    * @see cat_ts_aliases
    */
   function cat_ts_aliases_tab (
      p_ts_id          in varchar2 default null,
      p_ts_category_id in varchar2 default null,
      p_ts_group_id    in varchar2 default null,
      p_abbreviated    in varchar2 default 'T',
      p_db_office_id   in varchar2 default null
   )  return cat_ts_alias_tab_t pipelined;
   /**
    * Catalogs time series groups in the database for the specified office
    *
    * @param p_cwms_cat The cursor containing the time series groups for the specified office.
    * The cursor will contain the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">ts_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time series category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">ts_category_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the time series category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">ts_group_id</td>
    *     <td class="descr">varchar2(65)</td>
    *     <td class="descr">The time series group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">ts_group_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">shared_ts_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">An alias shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">shared_ref_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">A referenced time series identifier shared by all members of the group</td>
    *   </tr>
    * </table>
    * @param p_db_office_id   The office that owns the time series group. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_ts_group_tab
    */
   procedure cat_ts_group (
      p_cwms_cat     out      sys_refcursor,
      p_db_office_id in       varchar2 default null
   );
   /**
    * Catalogs time series groups in the database for the specified office
    *
    * @param p_db_office_id   The office that owns the time series group. If not specified or NULL, the session user's default office will be used.
    *
    * @return The cursor containing the time series groups for the specified office.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">ts_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time series category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">ts_category_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the time series category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">ts_group_id</td>
    *     <td class="descr">varchar2(65)</td>
    *     <td class="descr">The time series group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">ts_group_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the time series group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">shared_ts_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">An alias shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">shared_ref_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">A referenced time series identifier shared by all members of the group</td>
    *   </tr>
    * </table>
    *
    * @see cat_ts_group
    */
   function cat_ts_group_tab (p_db_office_id in varchar2 default null)
      return cat_ts_grp_tab_t pipelined;
   -- not documented
   FUNCTION cat_loc_tab (
      p_office_id        IN   VARCHAR2 DEFAULT NULL,
      p_elevation_unit   IN   VARCHAR2 DEFAULT 'm'
   )
      RETURN cat_loc_tab_t PIPELINED;
   -- not documented
   PROCEDURE cat_loc (
      p_cwms_cat         OUT      sys_refcursor,
      p_office_id        IN       VARCHAR2 DEFAULT NULL,
      p_elevation_unit   IN       VARCHAR2 DEFAULT 'm'
   );
   -- not documented
   PROCEDURE cat_loc_alias (
      p_cwms_cat       OUT      sys_refcursor,
      p_cwms_ts_id     IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs locations in the database that match specified parameters.
    *
    * @param p_cwms_cat        A cursor containing the locations. The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">base_location_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">sub_location_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The sub-location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation of the state containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">county_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the county containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">time_zone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The local time zone of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">location_type</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A user-defined type for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">latitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual latitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">longitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual longitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">horizontal_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the latitude and longitude</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">elevation</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The elevation of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">13</td>
    *     <td class="descr">elev_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The elevation unit</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">14</td>
    *     <td class="descr">vertical_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the elevation</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">15</td>
    *     <td class="descr">public_name</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The public name of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">16</td>
    *     <td class="descr">long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A long name for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">17</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(512)</td>
    *     <td class="descr">A description of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">18</td>
    *     <td class="descr">active_flag</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the location is marked as active</td>
    *   </tr>
    * </table>
    * @param p_elevation_unit  The unit to retrieve the location elevation in
    * @param p_base_loc_only   A flag ('T' or 'F') specifying whether to catalog only locations that have no sub-location identifier
    * @param p_loc_category_id The location category of the location group to restrict the catalog to. Must be NULL only if p_loc_group is also NULL.
    * @param p_loc_group_id    The location group to restict the catalog to. If not specified or NULL, no location group restriction will be used.
    * @param p_db_office_id    The office that owns the locations to be cataloged. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_location_tab
    * @see cat_location2
    * @see cat_location2_tab
    */
   PROCEDURE cat_location (
      p_cwms_cat          OUT      sys_refcursor,
      p_elevation_unit    IN       VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN       VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs locations in the database that match specified parameters.
    *
    * @param p_elevation_unit  The unit to retrieve the location elevation in
    * @param p_base_loc_only   A flag ('T' or 'F') specifying whether to catalog only locations that have no sub-location identifier
    * @param p_loc_category_id The location category of the location group to restrict the catalog to. Must be NULL only if p_loc_group is also NULL.
    * @param p_loc_group_id    The location group to restict the catalog to. If not specified or NULL, no location group restriction will be used.
    * @param p_db_office_id    The office that owns the locations to be cataloged. If not specified or NULL, the session user's default office will be used.
    *
    * @return A cursor containing the locations.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">base_location_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">sub_location_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The sub-location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation of the state containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">county_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the county containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">time_zone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The local time zone of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">location_type</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A user-defined type for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">latitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual latitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">longitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual longitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">horizontal_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the latitude and longitude</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">elevation</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The elevation of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">13</td>
    *     <td class="descr">elev_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The elevation unit</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">14</td>
    *     <td class="descr">vertical_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the elevation</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">15</td>
    *     <td class="descr">public_name</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The public name of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">16</td>
    *     <td class="descr">long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A long name for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">17</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(512)</td>
    *     <td class="descr">A description of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">18</td>
    *     <td class="descr">active_flag</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the location is marked as active</td>
    *   </tr>
    * </table>
    *
    * @see cat_location
    * @see cat_location2
    * @see cat_location2_tab
    */
   FUNCTION cat_location_tab (
      p_elevation_unit    IN   VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN   VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_location_tab_t PIPELINED;
   /**
    * Catalogs locations in the database that match specified parameters.
    *
    * @param p_cwms_cat        A cursor containing the locations. The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">base_location_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">sub_location_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The sub-location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation of the state containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">county_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the county containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">time_zone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The local time zone of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">location_type</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A user-defined type for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">latitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual latitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">longitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual longitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">horizontal_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the latitude and longitude</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">elevation</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The elevation of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">13</td>
    *     <td class="descr">elev_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The elevation unit</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">14</td>
    *     <td class="descr">vertical_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the elevation</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">15</td>
    *     <td class="descr">public_name</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The public name of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">16</td>
    *     <td class="descr">long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A long name for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">17</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(512)</td>
    *     <td class="descr">A description of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">18</td>
    *     <td class="descr">active_flag</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the location is marked as active</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">19</td>
    *     <td class="descr">location_kind_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The geographic type of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">20</td>
    *     <td class="descr">map_label</td>
    *     <td class="descr">varchar2(50)</td>
    *     <td class="descr">A label to use for the location on maps</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">21</td>
    *     <td class="descr">published_latitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The published latitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">22</td>
    *     <td class="descr">published_longitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The published longitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">23</td>
    *     <td class="descr">bounding_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office whose boundaries encompass the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">24</td>
    *     <td class="descr">nation_id</td>
    *     <td class="descr">varchar2(48)</td>
    *     <td class="descr">The nation the location resides in</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">25</td>
    *     <td class="descr">nearest_city</td>
    *     <td class="descr">varchar2(50)</td>
    *     <td class="descr">The name of the city nearest the location</td>
    *   </tr>
    * </table>
    * @param p_elevation_unit  The unit to retrieve the location elevation in
    * @param p_base_loc_only   A flag ('T' or 'F') specifying whether to catalog only locations that have no sub-location identifier
    * @param p_loc_category_id The location category of the location group to restrict the catalog to. Must be NULL only if p_loc_group is also NULL.
    * @param p_loc_group_id    The location group to restict the catalog to. If not specified or NULL, no location group restriction will be used.
    * @param p_db_office_id    The office that owns the locations to be cataloged. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_location
    * @see cat_location_tab
    * @see cat_location2_tab
    */
   PROCEDURE cat_location2 (
      p_cwms_cat          OUT      sys_refcursor,
      p_elevation_unit    IN       VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN       VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs locations in the database that match specified parameters.
    *
    * @param p_elevation_unit  The unit to retrieve the location elevation in
    * @param p_base_loc_only   A flag ('T' or 'F') specifying whether to catalog only locations that have no sub-location identifier
    * @param p_loc_category_id The location category of the location group to restrict the catalog to. Must be NULL only if p_loc_group is also NULL.
    * @param p_loc_group_id    The location group to restict the catalog to. If not specified or NULL, no location group restriction will be used.
    * @param p_db_office_id    The office that owns the locations to be cataloged. If not specified or NULL, the session user's default office will be used.
    *
    * @return A cursor containing the locations.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">base_location_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">sub_location_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The sub-location identifier of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation of the state containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">county_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the county containing the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">time_zone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The local time zone of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">location_type</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">A user-defined type for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">latitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual latitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">longitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The actual longitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">horizontal_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the latitude and longitude</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">elevation</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The elevation of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">13</td>
    *     <td class="descr">elev_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The elevation unit</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">14</td>
    *     <td class="descr">vertical_datum</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The datum of the elevation</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">15</td>
    *     <td class="descr">public_name</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The public name of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">16</td>
    *     <td class="descr">long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A long name for the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">17</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(512)</td>
    *     <td class="descr">A description of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">18</td>
    *     <td class="descr">active_flag</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the location is marked as active</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">19</td>
    *     <td class="descr">location_kind_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The geographic type of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">20</td>
    *     <td class="descr">map_label</td>
    *     <td class="descr">varchar2(50)</td>
    *     <td class="descr">A label to use for the location on maps</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">21</td>
    *     <td class="descr">published_latitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The published latitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">22</td>
    *     <td class="descr">published_longitude</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The published longitude of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">23</td>
    *     <td class="descr">bounding_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office whose boundaries encompass the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">24</td>
    *     <td class="descr">nation_id</td>
    *     <td class="descr">varchar2(48)</td>
    *     <td class="descr">The nation the location resides in</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">25</td>
    *     <td class="descr">nearest_city</td>
    *     <td class="descr">varchar2(50)</td>
    *     <td class="descr">The name of the city nearest the location</td>
    *   </tr>
    * </table>
    * </table>
    *
    * @see cat_location2
    * @see cat_location
    * @see cat_location_tab
    */
   FUNCTION cat_location2_tab (
      p_elevation_unit    IN   VARCHAR2 DEFAULT 'm',
      p_base_loc_only     IN   VARCHAR2 DEFAULT 'F',
      p_loc_category_id   IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN   VARCHAR2 DEFAULT NULL,
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_location2_tab_t PIPELINED;
   /**
    * Catalogs location aliases in the database that match specified parameters.
    * Matching is accomplished with glob-style wildcards, as shown below, instead
    * SQL-style wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat The cursor containing the location aliases that match the specified parameters.
    * The cursor will contain the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">loc_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">loc_group_id</td>
    *     <td class="descr">varchar2(65)</td>
    *     <td class="descr">The location group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">loc_group_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">loc_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The alias for the location with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">ref_location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">A referenced location identifier for the location with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">shared_loc_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">An alias shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">shared_loc_ref_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">A referenced location identifier shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A numeric attribute for the location with respect to the group. Can be used for sorting, etc...</td>
    *   </tr>
    * </table>
    * @param p_location_id     The location identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all location identifiers will be matched.
    * @param p_loc_category_id The location category identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all location category identifiers will be matched.
    * @param p_loc_group_id    The location group identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all location group identifiers will be matched.
    * @param p_abbreviated    A flag ('T' or 'F') specifying whether to catalog only locations that are members of location groups.
    * @param p_db_office_id   The office that owns the location. If not specified or NULL, the session user's default office will be used.
    */
   PROCEDURE cat_loc_aliases (
      p_cwms_cat          OUT sys_refcursor,
      p_location_id       IN  VARCHAR2 DEFAULT NULL,
      p_loc_category_id   IN  VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN  VARCHAR2 DEFAULT NULL,
      p_abbreviated       IN  VARCHAR2 DEFAULT 'T',
      p_db_office_id      IN  VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs location aliases in the database that match specified parameters.
    * Matching is accomplished with glob-style wildcards, as shown below, instead
    * SQL-style wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_location_id     The location identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all location identifiers will be matched.
    * @param p_loc_category_id The location category identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all location category identifiers will be matched.
    * @param p_loc_group_id    The location group identifier pattern to match. Use glob-style wildcards as shown above instead of SQL-style wildcards. If not specified or NULL, all location group identifiers will be matched.
    * @param p_abbreviated    A flag ('T' or 'F') specifying whether to catalog only locations that are members of location groups.
    * @param p_db_office_id   The office that owns the location. If not specified or NULL, the session user's default office will be used.
    *
    * @return The cursor containing the location aliases that match the specified parameters.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">loc_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">loc_group_id</td>
    *     <td class="descr">varchar2(65)</td>
    *     <td class="descr">The location group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">loc_group_desc</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">loc_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The alias for the location with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">ref_location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">A referenced location identifier for the location with respect to the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">shared_loc_alias_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">An alias shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">shared_loc_ref_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">A referenced location identifier shared by all members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">attribute</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A numeric attribute for the location with respect to the group. Can be used for sorting, etc...</td>
    *   </tr>
    * </table>
    */
   FUNCTION cat_loc_aliases_tab (
      p_location_id       IN   VARCHAR2 DEFAULT NULL,
      p_loc_category_id   IN   VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN   VARCHAR2 DEFAULT NULL,
      p_abbreviated       IN   VARCHAR2 default 'T',
      p_db_office_id      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_tab_t PIPELINED;
   -- not documented, same as cat_loc_aliases
   PROCEDURE cat_loc_aliases_java (
      p_cwms_cat          OUT      sys_refcursor,
      p_location_id       IN       VARCHAR2 DEFAULT NULL,
      p_loc_category_id   IN       VARCHAR2 DEFAULT NULL,
      p_loc_group_id      IN       VARCHAR2 DEFAULT NULL,
      P_ABBREVIATED       IN       VARCHAR2 DEFAULT 'T',
      p_db_office_id      IN       VARCHAR2 DEFAULT NULL
   );
   -- not documented
   PROCEDURE cat_param (p_cwms_cat OUT sys_refcursor);
   -- not documented
   FUNCTION cat_param_tab
      RETURN cat_param_tab_t PIPELINED;
   /**
    * Catalogs all base parameters in the CWMS database
    *
    * @param p_cwms_cat The cursor containing the base parameters.  The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">base_parameter_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">param_long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">The long name of the base parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">param_description</td>
    *     <td class="descr">varchar2(160)</td>
    *     <td class="descr">A description of the parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The database storage unit for the base parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">unit_long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">The office that owns the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">unit_description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the unit</td>
    *   </tr>
    * </table>
    * @see cat_base_parameter_tab
    * @see cat_parameter
    * @see cat_parameter_tab
    */
   PROCEDURE cat_base_parameter (p_cwms_cat OUT sys_refcursor);
   /**
    * Catalogs all base parameters in the CWMS database
    *
    * @return The cursor containing the base parameters.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">base_parameter_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">param_long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">The long name of the base parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">param_description</td>
    *     <td class="descr">varchar2(160)</td>
    *     <td class="descr">A description of the parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The database storage unit for the base parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">unit_long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">The office that owns the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">unit_description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the unit</td>
    *   </tr>
    * </table>
    * @see cat_base_parameter
    * @see cat_parameter
    * @see cat_parameter_tab
    */
   FUNCTION cat_base_parameter_tab
      RETURN cat_base_param_tab_t PIPELINED;
   /**
    * Catalogs all parameters in the CWMS database for a specified office
    *
    * @param p_cwms_cat The cursor containing the base parameters.  The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">parameter_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">base_parameter_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">sub_parameter_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The sub-parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">sub_parameter_desc</td>
    *     <td class="descr">varchar2(160)</td>
    *     <td class="descr">A description of the sub-parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the parameter, will be specifed office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">db_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The database storage unit for the base parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">unit_long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">The office that owns the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">unit_description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the unit</td>
    *   </tr>
    * </table>
    *
    * @param p_db_office_id The office to catalog the parameters for. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_parameter_tab
    * @see cat_base_parameter
    * @see cat_base_parameter_tab
    */
   PROCEDURE cat_parameter (
      p_cwms_cat       OUT      sys_refcursor,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs all parameters in the CWMS database for a specified office
    *
    * @param p_db_office_id The office to catalog the parameters for. If not specified or NULL, the session user's default office will be used.
    *
    * @return The cursor containing the base parameters.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">parameter_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">base_parameter_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The base parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">sub_parameter_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The sub-parameter identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">sub_parameter_desc</td>
    *     <td class="descr">varchar2(160)</td>
    *     <td class="descr">A description of the sub-parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the parameter, will be specifed office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">db_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The database storage unit for the base parameter</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">unit_long_name</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">The office that owns the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">unit_description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the unit</td>
    *   </tr>
    * </table>
    *
    * @see cat_parameter
    * @see cat_base_parameter
    * @see cat_base_parameter_tab
    */
   FUNCTION cat_parameter_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_parameter_tab_t PIPELINED;
   -- not documented
   FUNCTION cat_sub_param_tab
      RETURN cat_sub_param_tab_t PIPELINED;
   -- not documented
   PROCEDURE cat_sub_param (p_cwms_cat OUT sys_refcursor);
   -- not documented
   PROCEDURE cat_sub_loc (
      p_cwms_cat   OUT      sys_refcursor,
      p_office_id  IN       VARCHAR2 DEFAULT NULL
   );
   -- not documented
   FUNCTION cat_sub_loc_tab (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_sub_loc_tab_t PIPELINED;
   /**
    * Catalogs parameter types in the CWMS database
    *
    * @param p_cwms_cat A cursor containing the parameter types.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">parameter_type_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The parameter type identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the parameter type</td>
    *   </tr>
    * </table>
    *
    * @see cat_parameter_type_tab
    */
   PROCEDURE cat_parameter_type (p_cwms_cat OUT sys_refcursor);
   /**
    * Catalogs parameter types in the CWMS database
    *
    * @return A cursor containing the parameter types.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">parameter_type_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The parameter type identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the parameter type</td>
    *   </tr>
    * </table>
    *
    * @see cat_parameter_type_tab
    */
   FUNCTION cat_parameter_type_tab
      RETURN cat_parameter_type_tab_t PIPELINED;
   /**
    * Catalogs intervals in the CWMS database
    *
    * @param p_cwms_cat A cursor containing the parameter types.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">interval_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The parameter type identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">interval</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The interval in minutes. For intervals of 1Month or greater this is a symbolic interval and not a literal interval</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the parameter type</td>
    *   </tr>
    * </table>
    *
    * @see cat_interval_tab
    */
   PROCEDURE cat_interval (p_cwms_cat OUT sys_refcursor);
   /**
    * Catalogs intervals in the CWMS database
    *
    * @return A cursor containing the parameter types.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">interval_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The parameter type identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">interval</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The interval in minutes. For intervals of 1Month or greater this is a symbolic interval and not a literal interval</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the parameter type</td>
    *   </tr>
    * </table>
    *
    * @see cat_interval
    */
   FUNCTION cat_interval_tab
      RETURN cat_interval_tab_t PIPELINED;
   /**
    * Catalogs durations in the CWMS database
    *
    * @param p_cwms_cat A cursor containing the parameter types.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">duration_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The parameter type identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">duration</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The duration in minutes. For durations of 1Month or greater this is a symbolic duration and not a literal duration</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the parameter type</td>
    *   </tr>
    * </table>
    *
    * @see cat_duration_tab
    */
   PROCEDURE cat_duration (p_cwms_cat OUT sys_refcursor);
   /**
    * Catalogs durations in the CWMS database
    *
    * @return A cursor containing the parameter types.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">duration_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The parameter type identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">duration</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The duration in minutes. For durations of 1Month or greater this is a symbolic duration and not a literal duration</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(80)</td>
    *     <td class="descr">A description of the parameter type</td>
    *   </tr>
    * </table>
    *
    * @see cat_duration
    */
   FUNCTION cat_duration_tab
      RETURN cat_duration_tab_t PIPELINED;
   /**
    * Catalogs states in the CWMS database
    *
    * @param p_cwms_cat A cursor containing the states.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation for the state</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">state_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the state</td>
    *   </tr>
    * </table>
    *
    * @see cat_state_tab
    */
   PROCEDURE cat_state (p_cwms_cat OUT sys_refcursor);
   /**
    * Catalogs states in the CWMS database
    *
    * @return A cursor containing the states.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation for the state</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">state_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the state</td>
    *   </tr>
    * </table>
    *
    * @see cat_state_tab
    */
   FUNCTION cat_state_tab
      RETURN cat_state_tab_t PIPELINED;
   /**
    * Catalogs counties in the CWMS database
    *
    * @param p_cwms_cat A cursor containing the counties.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">county_id</td>
    *     <td class="descr">varchar2(3)</td>
    *     <td class="descr">The county identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">county_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the county</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation of the state the county is in</td>
    *   </tr>
    * </table>
    *
    * @param p_stateint The two letter abbreviation of the state to restrict the catalog to. If not specified or NULL, counties for all states are cataloged.
    *
    * @see cat_county_tab
    */
   PROCEDURE cat_county (
      p_cwms_cat   OUT      sys_refcursor,
      p_stateint   IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs counties in the CWMS database
    *
    * @param p_stateint The two letter abbreviation of the state to restrict the catalog to. If not specified or NULL, counties for all states are cataloged.
    *
    * @return A cursor containing the counties.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">county_id</td>
    *     <td class="descr">varchar2(3)</td>
    *     <td class="descr">The county identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">county_name</td>
    *     <td class="descr">varchar2(40)</td>
    *     <td class="descr">The name of the county</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">state_initial</td>
    *     <td class="descr">varchar2(2)</td>
    *     <td class="descr">The two letter abbreviation of the state the county is in</td>
    *   </tr>
    * </table>
    *
    * @see cat_county
    */
   FUNCTION cat_county_tab (p_stateint IN VARCHAR2 DEFAULT NULL)
      RETURN cat_county_tab_t PIPELINED;
   /**
    * Catalogs time zones in the CWMS database.
    *
    * @param p_cwms_cat A cursor containing the time zones.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">timezone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The time zone identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">utc_offset</td>
    *     <td class="descr">interval day to second</td>
    *     <td class="descr">The amount of time that the time zone is ahead of UTC</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">dst_offset</td>
    *     <td class="descr">interval day to second</td>
    *     <td class="descr">The amount of time added to the UTC offset during daylight savings time</td>
    *   </tr>
    * </table>
    *
    * @see cat_timezone_tab
    */
   PROCEDURE cat_timezone (p_cwms_cat OUT sys_refcursor);
   /**
    * Catalogs time zones in the CWMS database.
    *
    * @return A cursor containing the time zones.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">timezone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The time zone identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">utc_offset</td>
    *     <td class="descr">interval day to second</td>
    *     <td class="descr">The amount of time that the time zone is ahead of UTC</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">dst_offset</td>
    *     <td class="descr">interval day to second</td>
    *     <td class="descr">The amount of time added to the UTC offset during daylight savings time</td>
    *   </tr>
    * </table>
    *
    * @see cat_timezone
    */
   FUNCTION cat_timezone_tab
      RETURN cat_timezone_tab_t PIPELINED;
   /**
    * Catalogs DSS file references in the database that match specified parameters.  Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat A cursor containing the DSS file references.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">dss_filemgr_url</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time URL of the DSSFileManager</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">dss_file_name</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">The full pathname of the DSS file</td>
    *   </tr>
    * </table>
    * @param p_filemgr_url The DSSFileManager URL pattern to match.  Use glob-style wildcards characters as shown above. If not specified or NULL, all URLs will be matched.
    * @param p_file_name   The DSS file pathname pattern to match.  Use glob-style wildcards characters as shown above. If not specified or NULL, all pathnames will be matched.
    * @param p_office_id   The office owning the DSS file references. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_dss_file_tab
    */
   PROCEDURE cat_dss_file (
      p_cwms_cat      OUT      sys_refcursor,
      p_filemgr_url   IN       VARCHAR2 DEFAULT NULL,
      p_file_name     IN       VARCHAR2 DEFAULT NULL,
      p_office_id     IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs DSS file references in the database that match specified parameters.  Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_filemgr_url The DSSFileManager URL pattern to match.  Use glob-style wildcards characters as shown above. If not specified or NULL, all URLs will be matched.
    * @param p_file_name   The DSS file pathname pattern to match.  Use glob-style wildcards characters as shown above. If not specified or NULL, all pathnames will be matched.
    * @param p_office_id   The office owning the DSS file references. If not specified or NULL, the session user's default office will be used.
    *
    * @return A cursor containing the DSS file references.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">dss_filemgr_url</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time URL of the DSSFileManager</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">dss_file_name</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">The full pathname of the DSS file</td>
    *   </tr>
    * </table>
    *
    * @see cat_dss_file
    */
   FUNCTION cat_dss_file_tab (
      p_filemgr_url   IN   VARCHAR2 DEFAULT NULL,
      p_file_name     IN   VARCHAR2 DEFAULT NULL,
      p_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_dss_file_tab_t PIPELINED;
   /**
    * Catalogs data exchange sets in the database that match specified parameters.  Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat A cursor containing the data exchange sets.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office owning the data exhcange set</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">dss_xchg_set_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The data exchange set identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">dss_xchg_set_description</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">A description of the data exchange set</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">dss_filemgr_url</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time URL of the DSSFileManager</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">dss_file_name</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">The full pathname of the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">dss_xchg_direction_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The real time direction identifier</td>
    *   </tr>
    * </table>
    * @param p_office_id   The office owning the data exchange sets. Use glob-style wildcards characters as shown above. If not specified or NULL, the session user's default office will be used.
    * @param p_filemgr_url The DSSFileManager URL pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all URLs will be matched.
    * @param p_file_name   The DSS file pathname pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all pathnames will be matched.
    *
    * @see cat_dss_xchg_set_tab
    */
   PROCEDURE cat_dss_xchg_set (
      p_cwms_cat      OUT      sys_refcursor,
      p_office_id     IN       VARCHAR2 DEFAULT NULL,
      p_filemgr_url   IN       VARCHAR2 DEFAULT NULL,
      p_file_name     IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs data exchange sets in the database that match specified parameters.  Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_office_id   The office owning the data exchange sets. Use glob-style wildcards characters as shown above. If not specified or NULL, the session user's default office will be used.
    * @param p_filemgr_url The DSSFileManager URL pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all URLs will be matched.
    * @param p_file_name   The DSS file pathname pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all pathnames will be matched.
    *
    * @return A cursor containing the data exchange sets.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office owning the data exhcange set</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">dss_xchg_set_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The data exchange set identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">dss_xchg_set_description</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">A description of the data exchange set</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">dss_filemgr_url</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The time URL of the DSSFileManager</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">dss_file_name</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">The full pathname of the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">dss_xchg_direction_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The real time direction identifier</td>
    *   </tr>
    * </table>
    *
    * @see cat_dss_xchg_set
    */
   FUNCTION cat_dss_xchg_set_tab (
      p_office_id     IN   VARCHAR2 DEFAULT NULL,
      p_filemgr_url   IN   VARCHAR2 DEFAULT NULL,
      p_file_name     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_dss_xchg_set_tab_t PIPELINED;
   /**
    * Catalogs data exchange set time series mappings in the database that match specified parameters.  Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat A cursor containing the data exchange sets.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cwms_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">The CWMS time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">dss_pathname</td>
    *     <td class="descr">varchar2(391)</td>
    *     <td class="descr">The DSS pathname. The D pathname part will be empty.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">dss_parameter_type_id</td>
    *     <td class="descr">varchar2(8)</td>
    *     <td class="descr">The data type for the time series in the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">dss_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The unit for the time series in the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">dss_timezone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The time zone of the time series in the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">dss_tz_usage_id</td>
    *     <td class="descr">varchar2(8)</td>
    *     <td class="descr">Deprecated. Do not depend on values in this column</td>
    *   </tr>
    * </table>
    * @param p_office_id   The office owning the data exchange sets. Use glob-style wildcards characters as shown above. If not specified or NULL, the session user's default office will be used.
    * @param p_dss_xchg_set_id The data exchange set identifier pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all data exchange identifiers will be matched.
    *
    * @see cat_dss_xchg_ts_map_tab
    */
   PROCEDURE cat_dss_xchg_ts_map (
      p_cwms_cat      OUT      sys_refcursor,
      p_office_id     IN       VARCHAR2,
      p_xchg_set_id   IN       VARCHAR2
   );
   /**
    * Catalogs data exchange set time series mappings in the database that match specified parameters.  Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_office_id   The office owning the data exchange sets. Use glob-style wildcards characters as shown above. If not specified or NULL, the session user's default office will be used.
    * @param p_dss_xchg_set_id The data exchange set identifier pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all data exchange identifiers will be matched.
    *
    * @return A cursor containing the data exchange sets.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cwms_ts_id</td>
    *     <td class="descr">varchar2(183)</td>
    *     <td class="descr">The CWMS time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">dss_pathname</td>
    *     <td class="descr">varchar2(391)</td>
    *     <td class="descr">The DSS pathname. The D pathname part will be empty.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">dss_parameter_type_id</td>
    *     <td class="descr">varchar2(8)</td>
    *     <td class="descr">The data type for the time series in the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">dss_unit_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The unit for the time series in the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">dss_timezone_name</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The time zone of the time series in the DSS file</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">dss_tz_usage_id</td>
    *     <td class="descr">varchar2(8)</td>
    *     <td class="descr">Deprecated. Do not depend on values in this column</td>
    *   </tr>
    * </table>
    *
    * @see cat_dss_xchg_ts_map
    */
   FUNCTION cat_dss_xchg_ts_map_tab (
      p_office_id         IN   VARCHAR2,
      p_dss_xchg_set_id   IN   VARCHAR2
   )
      RETURN cat_dss_xchg_ts_map_tab_t
      PIPELINED;
   /**
    * Catalogs property keys in the database that match specified parameters.
    * <p>
    * <dl>CWMS database properties are modeled after property files widely used in
    * UNIX and Java environments. Each property has the following:
    * <dd><dl>
    *   <dt>office_id</dt>
    *   <dd>The office owning the property. This is <em>somewhat</em> analogous to the host on which a property file resides</dd>
    *   <dt>prop_category</dt>
    *   <dd>The property category. This is analogous to a property file name</dd>
    *   <dt>prop_id</dt>
    *   <dd>The property identifier. This is analogous to the left of equals sign in a property file</dd>
    *   <dt>prop_value</dt>
    *   <dd>The property value. This is analogous to the right side of the equals sign in a properties file</dd>
    *   <dt>prop_comment</dt>
    *   <dd>A comment about the property. This is <em>somewhat</em> analogous to a comment line above the property in a property file</dd>
    * </dl></dd></dl>
    * <p>
    * Matching is accomplished with glob-style wildcards, as shown below.
    * SQL-style wildcards may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat A cursor containing the property keys.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office owning the property</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">prop_category</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">prop_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property identifier</td>
    *   </tr>
    * </table>
    * @param p_office_id     The office owning the properties. If not specified or NULL, the session user's default office will be used.
    * @param p_prop_category The property category pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all property categories will be matched.
    * @param p_prop_id       The property identifier pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all property identifiers will be matched.
    *
    * @see cat_property_tab
    * @see cwms_properties.get_property
    */
   PROCEDURE cat_property (
      p_cwms_cat        OUT      sys_refcursor,
      p_office_id       IN       VARCHAR2 DEFAULT NULL,
      p_prop_category   IN       VARCHAR2 DEFAULT NULL,
      p_prop_id         IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs property keys in the database that match specified parameters.
    * <p>
    * <dl>CWMS database properties are modeled after property files widely used in
    * UNIX and Java environments. Each property has the following:
    * <dd><dl>
    *   <dt>office_id</dt>
    *   <dd>The office owning the property. This is <em>somewhat</em> analogous to the host on which a property file resides</dd>
    *   <dt>prop_category</dt>
    *   <dd>The property category. This is analogous to a property file name</dd>
    *   <dt>prop_id</dt>
    *   <dd>The property identifier. This is analogous to the left of equals sign in a property file</dd>
    *   <dt>prop_value</dt>
    *   <dd>The property value. This is analogous to the right side of the equals sign in a properties file</dd>
    *   <dt>prop_comment</dt>
    *   <dd>A comment about the property. This is <em>somewhat</em> analogous to a comment line above the property in a property file</dd>
    * </dl></dd></dl>
    * <p>
    * Matching is accomplished with glob-style wildcards, as shown below.
    * SQL-style wildcards may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_office_id     The office owning the properties. If not specified or NULL, the session user's default office will be used.
    * @param p_prop_category The property category pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all property categories will be matched.
    * @param p_prop_id       The property identifier pattern to match. Use glob-style wildcards characters as shown above. If not specified or NULL, all property identifiers will be matched.
    *
    * @return A cursor containing the property keys.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office owning the property</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">prop_category</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">prop_id</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">The property identifier</td>
    *   </tr>
    * </table>
    *
    * @see cat_property
    * @see cwms_properties.get_property
    */
   FUNCTION cat_property_tab (
      p_office_id       IN   VARCHAR2 DEFAULT NULL,
      p_prop_category   IN   VARCHAR2 DEFAULT NULL,
      p_prop_id         IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_property_tab_t PIPELINED;
   /**
    * Catalogs location kinds in the database that match specified parameters. Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_cwms_cat A cursor containing the location groups.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location kind. Will be the specified office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_kind_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location kind identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the location kind</td>
    *   </tr>
    * </table>
    * @param p_location_kind_id_mask The location kind identifier pattern to match. If not specified or NULL, all location kind identifiers will be matched.
    * @param p_office_id_mask The office to catalog the location kinds for. If not specified or NULL, the session user's default office will be used. To catalog for multiple offices, use the glob-style wildcards mentioned above.
    *
    *
    * @see cat_location_kind_tab
    */
   PROCEDURE cat_location_kind (
      p_cwms_cat              out sys_refcursor,
      p_location_kind_id_mask in  varchar2 default null,
      p_office_id_mask        in  varchar2 default null
   );
   /**
    * Catalogs location kinds in the database that match specified parameters. Matching is
    * accomplished with glob-style wildcards, as shown below. SQL-style wildcards
    * may also be used.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_location_kind_id_mask The location kind identifier pattern to match. If not specified or NULL, all location kind identifiers will be matched.
    * @param p_office_id_mask The office to catalog the location kinds for. If not specified or NULL, the session user's default office will be used. To catalog for multiple offices, use the glob-style wildcards mentioned above.
    *
    * @return A cursor containing the location groups.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location kind. Will be the specified office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">location_kind_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location kind identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">description</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">A description of the location kind</td>
    *   </tr>
    * </table>
    *
    * @see cat_location_kind
    */
   FUNCTION cat_location_kind_tab (
      p_location_kind_id_mask in  varchar2 default null,
      p_office_id_mask        in  varchar2 default null
   )
      RETURN cat_location_kind_tab_t PIPELINED;
   /**
    * Catalogs location groups in the database for the specified office.
    *
    * @param p_cwms_cat A cursor containing the location groups.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location category. Will be the specified office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">loc_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">loc_category_desc</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">A description of the location category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location group. Will be the specified office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">loc_group_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">loc_group_desc</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">A description of the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">shared_loc_alias_id</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">An alias shared by all locations that are members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">shared_loc_ref_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">A location identifer referenced by all locations that are members of the group</td>
    *   </tr>
    * </table>
    * @param p_db_office_id The office to catalog the location groups for. If not specified or NULL, the session user's default office will be used.
    *
    * @see cat_loc_group_tab
    */
   PROCEDURE cat_loc_group (
      p_cwms_cat       OUT      sys_refcursor,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );
   /**
    * Catalogs location groups in the database for the specified office.
    *
    * @param p_db_office_id The office to catalog the location groups for. If not specified or NULL, the session user's default office will be used.
    *
    * @return A cursor containing the location groups.
    * The cursor is suitable for using in a SELECT statement by wrapping it in the TABLE function.
    * The cursor contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cat_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location category. Will be the specified office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">loc_category_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location category identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">loc_category_desc</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">A description of the location category</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">grp_db_office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the location group. Will be the specified office or CWMS</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">loc_group_id</td>
    *     <td class="descr">varchar2(32)</td>
    *     <td class="descr">The location group identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">loc_group_desc</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">A description of the location group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">shared_loc_alias_id</td>
    *     <td class="descr">varchar2(128)</td>
    *     <td class="descr">An alias shared by all locations that are members of the group</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">shared_loc_ref_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">A location identifer referenced by all locations that are members of the group</td>
    *   </tr>
    * </table>
    *
    * @see cat_loc_group
    */
   FUNCTION cat_loc_group_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_loc_grp_tab_t PIPELINED;
   /**
    * Retrieves a set of values that conform a common structure but different names.
    * <p>
    * All tables accessed by this function have the same structure:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr"><em>prefix</em>_code</td>
    *     <td class="descr">number(10)</td>
    *     <td class="descr">The primary key of the table</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">db_office_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A foreign key into the CWMS_OFFICE table. Idenifies the owning office</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr"><em>prefix</em>_display_value</td>
    *     <td class="descr">varchar2(25)</td>
    *     <td class="descr">A text identifier for the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr"><em>prefix</em>_tooltip</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">A description of the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr"><em>prefix</em>_active</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the value is marked as active</td>
    *   </tr>
    * </table>
    * <p>
    * The following combinations of p_lookup_category and p_lookup_prefix parameters are currently valid:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_lookup_category (table name)</th>
    *     <th class="descr">p_lookup_prefix (column name prefix)</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_DOCUMENT_TYPE</td>
    *     <td class="descr">DOCUMENT_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_EMBANK_PROTECTION_TYPE</td>
    *     <td class="descr">PROTECTION_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_EMBANK_STRUCTURE_TYPE</td>
    *     <td class="descr">STRUCTURE_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_GATE_CH_COMPUTATION_CODE</td>
    *     <td class="descr">DISCHARGE_COMP</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_GATE_RELEASE_REASON_CODE</td>
    *     <td class="descr">RELEASE_REASON</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_PHYSICAL_TRANSFER_TYPE</td>
    *     <td class="descr">PHYS_TRANS_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_PROJECT_PURPOSES</td>
    *     <td class="descr">PURPOSE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_TURBINE_COMPUTATION_CODE</td>
    *     <td class="descr">TURBINE_COMP</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_TURBINE_SETTING_REASON</td>
    *     <td class="descr">TURB_SET_REASON</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_WS_CONTRACT_TYPE</td>
    *     <td class="descr">WS_CONTRACT_TYPE</td>
    *   </tr>
    * </table>
    *
    * @param p_lookup_type_tab The retrieved values
    * @param p_lookup_category The name of the table to retrieve values from
    * @param p_lookup_prefix   The column name prefix in the table
    * @param p_db_office_id    The office to retrieve values for. If not specified or NULL, the session user's default office is used.
    *
    * @see set_lookup_table
    */
   procedure get_lookup_table(
      p_lookup_type_tab out lookup_type_tab_t,
      p_lookup_category in  varchar2,
      p_lookup_prefix   in  varchar2,
      p_db_office_id    in  varchar2 default null);
   /**
    * Stores (inserts or updates) a set of values that conform a common structure but different names.
    * <p>
    * All tables accessed by this procedure have the same structure:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr"><em>prefix</em>_code</td>
    *     <td class="descr">number(10)</td>
    *     <td class="descr">The primary key of the tabe.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">db_office_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A foreign key into the CWMS_OFFICE table. Idenifies the owning office</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr"><em>prefix</em>_display_value</td>
    *     <td class="descr">varchar2(25)</td>
    *     <td class="descr">A text identifier for the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr"><em>prefix</em>_tooltip</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">A description of the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr"><em>prefix</em>_active</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the value is marked as active</td>
    *   </tr>
    * </table>
    * <p>
    * The following combinations of p_lookup_category and p_lookup_prefix parameters are currently valid:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_lookup_category (table name)</th>
    *     <th class="descr">p_lookup_prefix (column name prefix)</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_DOCUMENT_TYPE</td>
    *     <td class="descr">DOCUMENT_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_EMBANK_PROTECTION_TYPE</td>
    *     <td class="descr">PROTECTION_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_EMBANK_STRUCTURE_TYPE</td>
    *     <td class="descr">STRUCTURE_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_GATE_CH_COMPUTATION_CODE</td>
    *     <td class="descr">DISCHARGE_COMP</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_GATE_RELEASE_REASON_CODE</td>
    *     <td class="descr">RELEASE_REASON</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_PHYSICAL_TRANSFER_TYPE</td>
    *     <td class="descr">PHYS_TRANS_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_PROJECT_PURPOSES</td>
    *     <td class="descr">PURPOSE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_TURBINE_COMPUTATION_CODE</td>
    *     <td class="descr">TURBINE_COMP</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_TURBINE_SETTING_REASON</td>
    *     <td class="descr">TURB_SET_REASON</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_WS_CONTRACT_TYPE</td>
    *     <td class="descr">WS_CONTRACT_TYPE</td>
    *   </tr>
    * </table>
    *
    * @param p_lookup_type_tab The values to store
    * @param p_lookup_category The name of the table to store values to
    * @param p_lookup_prefix   The column name prefix in the table
    *
    * @see get_lookup_table
    */
   procedure set_lookup_table(
      p_lookup_type_tab IN lookup_type_tab_t,
      p_lookup_category IN VARCHAR2,
      p_lookup_prefix   IN VARCHAR2);
   
   /**
    * Deletes a set of lookup values that conform to a common structure but different names. 
    * The identifying parts within the arg lookup table type are used to determine which row
    * values to delete from the look up table.
    * <p>
    * All tables accessed by this procedure have the same structure:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr"><em>prefix</em>_code</td>
    *     <td class="descr">number(10)</td>
    *     <td class="descr">The primary key of the tabe.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">db_office_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">A foreign key into the CWMS_OFFICE table. Idenifies the owning office</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr"><em>prefix</em>_display_value</td>
    *     <td class="descr">varchar2(25)</td>
    *     <td class="descr">A text identifier for the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr"><em>prefix</em>_tooltip</td>
    *     <td class="descr">varchar2(255)</td>
    *     <td class="descr">A description of the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr"><em>prefix</em>_active</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">A flag ('T' or 'F') specifying whether the value is marked as active</td>
    *   </tr>
    * </table>
    * <p>
    * The following combinations of p_lookup_category and p_lookup_prefix parameters are currently valid:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_lookup_category (table name)</th>
    *     <th class="descr">p_lookup_prefix (column name prefix)</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_DOCUMENT_TYPE</td>
    *     <td class="descr">DOCUMENT_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_EMBANK_PROTECTION_TYPE</td>
    *     <td class="descr">PROTECTION_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_EMBANK_STRUCTURE_TYPE</td>
    *     <td class="descr">STRUCTURE_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_GATE_CH_COMPUTATION_CODE</td>
    *     <td class="descr">DISCHARGE_COMP</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_GATE_RELEASE_REASON_CODE</td>
    *     <td class="descr">RELEASE_REASON</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_PHYSICAL_TRANSFER_TYPE</td>
    *     <td class="descr">PHYS_TRANS_TYPE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_PROJECT_PURPOSES</td>
    *     <td class="descr">PURPOSE</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_TURBINE_COMPUTATION_CODE</td>
    *     <td class="descr">TURBINE_COMP</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_TURBINE_SETTING_REASON</td>
    *     <td class="descr">TURB_SET_REASON</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">AT_WS_CONTRACT_TYPE</td>
    *     <td class="descr">WS_CONTRACT_TYPE</td>
    *   </tr>
    * </table>
    *
    * @param p_lookup_type_tab The values to delete, only identifying parts are required.
    * @param p_lookup_category The name of the table to store values to
    * @param p_lookup_prefix   The column name prefix in the table
    *
    * @see get_lookup_table
    */   
   procedure delete_lookups(
      p_lookup_type_tab IN lookup_type_tab_t,
      p_lookup_category IN VARCHAR2,
      p_lookup_prefix   IN VARCHAR2);
  
   /**
    * Catalogs streams in the database that match input parameters. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_catalog A cursor containing all matching streams.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the stream location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">stream_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">stationing_starts_ds</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">Specifies whether the zero station is at the downstream most end</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">flows_into_stream</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the receiving stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">flows_into_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The station on the receiving stream of the confluence with this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">flows_into_bank</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">The bank on the receiving stream of the confluence with this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">diverts_from_stream</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the diverting stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">diverts_from_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The station on the diverting stream of the diversion into this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">diverts_from_bank</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">The bank on the diverting stream of the diversion into this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">stream_length</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The length of this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">average_slope</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The average slope of this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">comments</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">Any comments for this stream</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_station_units The units for stations and length
    *
    * @param p_stationing_starts_ds_mask  The stream location pattern to match. Use 'T', 'F', or '*'
    *
    * @param p_flows_into_stream_id_mask  The receiving stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_flows_into_station_min The minimum station on the receiving stream, if any, to match
    *
    * @param p_flows_into_station_max The maximum station on the receiving stream, if any, to match
    *
    * @param p_flows_into_bank_mask The bank on the receiving stream, if any, to match. Use 'L', 'R', or '*'
    *
    * @param p_diverts_from_stream_id_mask  The diverting stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_diverts_from_station_min The minimum station on the diverting stream, if any, to match
    *
    * @param p_diverts_from_station_max The maximum station on the diverting stream, if any, to match
    *
    * @param p_diverts_from_bank_mask The bank on the diverting stream, if any, to match. Use 'L', 'R', or '*'
    *
    * @param p_length_min The minimum stream length to match
    *
    * @param p_length_max The maximum stream length to match
    *
    * @param p_average_slope_min The minimum average slope to match
    *
    * @param p_average_slope_max The maximum average slope to match
    *
    * @param p_comments_mask  The comments pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_office_id_mask  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
   procedure cat_streams(
      p_stream_catalog              out sys_refcursor,
      p_stream_id_mask              in  varchar2 default '*',
      p_station_units               in  varchar2 default 'km',
      p_stationing_starts_ds_mask   in  varchar2 default '*',
      p_flows_into_stream_id_mask   in  varchar2 default '*',
      p_flows_into_station_min      in  binary_double default null,
      p_flows_into_station_max      in  binary_double default null,
      p_flows_into_bank_mask        in  varchar2 default '*',
      p_diverts_from_stream_id_mask in  varchar2 default '*',
      p_diverts_from_station_min    in  binary_double default null,
      p_diverts_from_station_max    in  binary_double default null,
      p_diverts_from_bank_mask      in  varchar2 default '*',
      p_length_min                  in  binary_double default null,
      p_length_max                  in  binary_double default null,
      p_average_slope_min           in  binary_double default null,
      p_average_slope_max           in  binary_double default null,
      p_comments_mask               in  varchar2 default '*',
      p_office_id_mask              in  varchar2 default null);
   /**
    * Catalogs streams in the database that match input parameters. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_station_units The units for stations and length
    *
    * @param p_stationing_starts_ds_mask  The stream location pattern to match. Use 'T', 'F', or '*'
    *
    * @param p_flows_into_stream_id_mask  The receiving stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_flows_into_station_min The minimum station on the receiving stream, if any, to match
    *
    * @param p_flows_into_station_max The maximum station on the receiving stream, if any, to match
    *
    * @param p_flows_into_bank_mask The bank on the receiving stream, if any, to match. Use 'L', 'R', or '*'
    *
    * @param p_diverts_from_stream_id_mask  The diverting stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_diverts_from_station_min The minimum station on the diverting stream, if any, to match
    *
    * @param p_diverts_from_station_max The maximum station on the diverting stream, if any, to match
    *
    * @param p_diverts_from_bank_mask The bank on the diverting stream, if any, to match. Use 'L', 'R', or '*'
    *
    * @param p_length_min The minimum stream length to match
    *
    * @param p_length_max The maximum stream length to match
    *
    * @param p_average_slope_min The minimum average slope to match
    *
    * @param p_average_slope_max The maximum average slope to match
    *
    * @param p_comments_mask  The comments pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_office_id_mask  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @return A cursor containing all matching streams.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the stream location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">stream_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">stationing_starts_ds</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">Specifies whether the zero station is at the downstream most end</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">flows_into_stream</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the receiving stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">flows_into_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The station on the receiving stream of the confluence with this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">flows_into_bank</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">The bank on the receiving stream of the confluence with this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">diverts_from_stream</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the diverting stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">diverts_from_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The station on the diverting stream of the diversion into this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">diverts_from_bank</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">The bank on the diverting stream of the diversion into this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">stream_length</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The length of this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">average_slope</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The average slope of this stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">comments</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">Any comments for this stream</td>
    *   </tr>
    * </table>
    */
   function cat_streams_f(
      p_stream_id_mask              in varchar2 default '*',
      p_station_units               in varchar2 default 'km',
      p_stationing_starts_ds_mask   in varchar2 default '*',
      p_flows_into_stream_id_mask   in varchar2 default '*',
      p_flows_into_station_min      in binary_double default null,
      p_flows_into_station_max      in binary_double default null,
      p_flows_into_bank_mask        in varchar2 default '*',
      p_diverts_from_stream_id_mask in varchar2 default '*',
      p_diverts_from_station_min    in binary_double default null,
      p_diverts_from_station_max    in binary_double default null,
      p_diverts_from_bank_mask      in varchar2 default '*',
      p_length_min                  in binary_double default null,
      p_length_max                  in binary_double default null,
      p_average_slope_min           in binary_double default null,
      p_average_slope_max           in binary_double default null,
      p_comments_mask               in varchar2 default '*',
      p_office_id_mask              in varchar2 default null)
      return sys_refcursor;
   /**
    * Catalogs stream reaches in the database that match input parameters. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_reach_catalog A cursor containing all matching basins.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the stream location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">stream_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">stream_reach_id</td>
    *     <td class="descr">varchar2(64)</td>
    *     <td class="descr">The stream reach identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">upstream_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The upstream station of the reach</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">downstream_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The downstream station of the reach</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">stream_type_id</td>
    *     <td class="descr">varchar2(4)</td>
    *     <td class="descr">The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> of the reach</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">comments</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">Any comments for this stream</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_reach_id_mask  The stream reach pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_reach_id_mask  The stream type pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
     * @param p_comments_mask  The comments pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_office_id_mask  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
   procedure cat_stream_reaches(
      p_reach_catalog       out sys_refcursor,
      p_stream_id_mask      in  varchar2 default '*',
      p_reach_id_mask       in  varchar2 default '*',
      p_stream_type_id_mask in  varchar2 default '*',
      p_comments_mask       in  varchar2 default '*',
      p_office_id_mask      in  varchar2 default null);
   /**
    * Catalogs stream reaches in the database that match input parameters. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_id_mask  The stream location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_reach_id_mask  The stream reach pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_reach_id_mask  The stream type pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_comments_mask  The comments pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @return  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_reach_catalog A cursor containing all matching basins.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the stream location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">stream_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">stream_reach_id</td>
    *     <td class="descr">varchar2(64)</td>
    *     <td class="descr">The stream reach identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">upstream_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The upstream station of the reach</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">downstream_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The downstream station of the reach</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">stream_type_id</td>
    *     <td class="descr">varchar2(4)</td>
    *     <td class="descr">The <a href="http://www.epa.gov/owow/watershed/wacademy/acad2000/stream_class/index.htm">Rosgen Level II Stream Type</a> of the reach</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">comments</td>
    *     <td class="descr">varchar2(256)</td>
    *     <td class="descr">Any comments for this stream</td>
    *   </tr>
    * </table>
    */
   function cat_stream_reaches_f(
      p_stream_id_mask      in varchar2 default '*',
      p_reach_id_mask       in varchar2 default '*',
      p_stream_type_id_mask in varchar2 default '*',
      p_comments_mask       in varchar2 default '*',
      p_office_id_mask      in varchar2 default null)
      return sys_refcursor;
   /**
    * Catalogs stream locations in the database that match input parameters. Matching is
    * accomplished with glob-style wildcards, as shown below, instead of sql-style
    * wildcards.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Wildcard</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">*</td>
    *     <td class="descr">Match zero or more characters</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">?</td>
    *     <td class="descr">Match a single character</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_location_catalog A cursor containing all matching stream locations.  The cursor contains
    * the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office that owns the stream and location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">stream_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">location_id</td>
    *     <td class="descr">varchar2(49)</td>
    *     <td class="descr">The location identifier of the location on the stream</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The actual stream station of the location>/td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">published_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The published stream station of the location>/td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">navigation_station</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The navigation stream station of the location>/td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">bank</td>
    *     <td class="descr">varchar2(1)</td>
    *     <td class="descr">The stream bank of the location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">8</td>
    *     <td class="descr">lowest_measurable_stage</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The lowest stream stage at this location that can be measured</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">9</td>
    *     <td class="descr">drainage_area</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The total drainage area above this location</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">10</td>
    *     <td class="descr">ungaged_drainage_area</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The drainage area above this location that is ungaged</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">11</td>
    *     <td class="descr">station_unit</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The station unit</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">12</td>
    *     <td class="descr">stage_unit</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The stage unit</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">13</td>
    *     <td class="descr">area_unit</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The area unit</td>
    *   </tr>
    * </table>
    *
    * @param p_stream_id_mask  The stream pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_location_id_mask The location pattern to match. Use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    *
    * @param p_station_unit The units for stations
    *
    * @param p_stage_unit The units for stage
    *
    * @param p_area_unit The units for area
    *
    * @param p_office_id_mask  The office pattern to match.  If the routine is called
    * without this parameter, or if this parameter is set to NULL, the session user's
    * default office will be used. For matching multiple office, use glob-style
    * wildcard characters as shown above instead of sql-style wildcard characters for pattern
    * matching.
    */
   procedure cat_stream_locations(
      p_stream_location_catalog out sys_refcursor,
      p_stream_id_mask          in  varchar2 default '*',
      p_location_id_mask        in  varchar2 default '*',
      p_station_unit            in  varchar2 default null,
      p_stage_unit              in  varchar2 default null,
      p_area_unit               in  varchar2 default null,
      p_office_id_mask          in  varchar2 default null);
/**
 * Catalogs stream locations in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_stream_id_mask  The stream pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_location_id_mask The location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_station_unit The units for stations
 *
 * @param p_stage_unit The units for stage
 *
 * @param p_area_unit The units for area
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching stream locations.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the stream and location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the location on the stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The actual stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">published_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The published stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">navigation_station</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The navigation stream station of the location>/td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">bank</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The stream bank of the location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">lowest_measurable_stage</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The lowest stream stage at this location that can be measured</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area above this location</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">ungaged_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The drainage area above this location that is ungaged</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">station_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The station unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">stage_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The stage unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The area unit</td>
 *   </tr>
 * </table>
 */
   function cat_stream_locations_f(
      p_stream_id_mask   in  varchar2 default '*',
      p_location_id_mask in  varchar2 default '*',
      p_station_unit     in  varchar2 default null,
      p_stage_unit       in  varchar2 default null,
      p_area_unit        in  varchar2 default null,
      p_office_id_mask   in  varchar2 default null)
      return sys_refcursor;
/**
 * Catalogs basins in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_basins_catalog A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the parent basin, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">sort_order</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The sort order of the basin within it parent basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">primary_stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the primary stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">total_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">contributing_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The contributing area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the total and contributing drainage areas</td>
 *   </tr>
 * </table>
 *
 * @param p_basin_id_mask  The basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_parent_basin_id_mask  The parent basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_primary_stream_id_mask   The primary stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_area_unit The unit in which to list areas
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
   procedure cat_basins(
      p_basins_catalog         out sys_refcursor,
      p_basin_id_mask          in  varchar2 default '*',
      p_parent_basin_id_mask   in  varchar2 default '*',
      p_primary_stream_id_mask in  varchar2 default '*',
      p_area_unit              in  varchar2 default null,
      p_office_id_mask         in  varchar2 default null);
/**
 * Catalogs basins in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_basin_id_mask  The basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_parent_basin_id_mask  The parent basin location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_primary_stream_id_mask   The primary stream location pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_area_unit The unit in which to list areas
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching basins.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parent_basin_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the parent basin, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">sort_order</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The sort order of the basin within it parent basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">primary_stream_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The location identifier of the primary stream</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">total_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The total drainage area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">contributing_drainage_area</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The contributing area of the basin</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">area_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the total and contributing drainage areas</td>
 *   </tr>
 * </table>
 */
   function cat_basins_f(
      p_basin_id_mask          in varchar2 default '*',
      p_parent_basin_id_mask   in varchar2 default '*',
      p_primary_stream_id_mask in varchar2 default '*',
      p_area_unit              in varchar2 default null,
      p_office_id_mask         in varchar2 default null)
      return sys_refcursor;

END cwms_cat;
/

SHOW error;
