/* Formatted on 2006/11/24 13:04 (Formatter Plus v4.8.7) */
CREATE OR REPLACE PACKAGE cwms_cat AUTHID CURRENT_USER
IS
   TYPE cat_ts_rec_t IS RECORD (
      office_id             VARCHAR2 (16),
      cwms_ts_id            VARCHAR2 (183),
      interval_utc_offset   NUMBER
   );

   TYPE cat_ts_tab_t IS TABLE OF cat_ts_rec_t;

   TYPE cat_ts_cwms_20_rec_t IS RECORD (
      office_id             VARCHAR2 (16),
      cwms_ts_id            VARCHAR2 (183),
      interval_utc_offset   NUMBER (10),
      user_privileges       NUMBER,
      inactive              NUMBER,
      lrts_timezone         VARCHAR2 (28)
   );

   TYPE cat_ts_cwms_20_tab_t IS TABLE OF cat_ts_cwms_20_rec_t;

   TYPE cat_loc_rec_t IS RECORD (
      office_id        VARCHAR2 (16),
      base_loc_id      VARCHAR2 (16),
      state_initial    VARCHAR2 (2),
      county_name      VARCHAR2 (40),
      timezone_name    VARCHAR2 (28),
      location_type    VARCHAR2 (16),
      latitude         NUMBER,
      longitude        NUMBER,
      elevation        NUMBER,
      elev_unit_id     VARCHAR2 (16),
      vertical_datum   VARCHAR2 (16),
      public_name      VARCHAR2 (32),
      long_name        VARCHAR2 (80),
      description      VARCHAR2 (512)
   );

   TYPE cat_loc_tab_t IS TABLE OF cat_loc_rec_t;

   TYPE cat_loc_alias_rec_t IS RECORD (
      office_id   VARCHAR2 (16),
      cwms_id     VARCHAR2 (16),
      source_id   VARCHAR2 (16),
      gage_id     VARCHAR2 (32)
   );

   TYPE cat_loc_alias_abrev_rec_t IS RECORD (
      office_id     VARCHAR2 (16),
      location_id   VARCHAR2 (49),
      agency_id     VARCHAR2 (16),
      alias_id      VARCHAR2 (16)
   );

   TYPE cat_loc_alias_abrev_tab_t IS TABLE OF cat_loc_alias_abrev_rec_t;

   TYPE cat_loc_alias_tab_t IS TABLE OF cat_loc_alias_rec_t;

   TYPE cat_param_rec_t IS RECORD (
      parameter_id        VARCHAR2 (16),
      param_long_name     VARCHAR2 (80),
      param_description   VARCHAR2 (160),
      unit_id             VARCHAR2 (16),
      unit_long_name      VARCHAR2 (80),
      unit_description    VARCHAR2 (80)
   );

   TYPE cat_param_tab_t IS TABLE OF cat_param_rec_t;

   TYPE cat_sub_param_rec_t IS RECORD (
      parameter_id      VARCHAR2 (16),
      subparameter_id   VARCHAR2 (32),
      description       VARCHAR2 (80)
   );

   TYPE cat_sub_param_tab_t IS TABLE OF cat_sub_param_rec_t;

   TYPE cat_sub_loc_rec_t IS RECORD (
      sublocation_id   VARCHAR2 (32),
      description      VARCHAR2 (80)
   );

   TYPE cat_sub_loc_tab_t IS TABLE OF cat_sub_loc_rec_t;

   TYPE cat_state_rec_t IS RECORD (
      state_initial   VARCHAR2 (2),
      state_name      VARCHAR2 (40)
   );

   TYPE cat_state_tab_t IS TABLE OF cat_state_rec_t;

   TYPE cat_county_rec_t IS RECORD (
      county_id       VARCHAR2 (3),
      county_name     VARCHAR2 (40),
      state_initial   VARCHAR2 (2)
   );

   TYPE cat_county_tab_t IS TABLE OF cat_county_rec_t;

   TYPE cat_timezone_rec_t IS RECORD (
      timezone_name   VARCHAR2 (28),
      utc_offset      INTERVAL DAY (2)TO SECOND (6),
      dst_offset      INTERVAL DAY (2)TO SECOND (6)
   );

   TYPE cat_timezone_tab_t IS TABLE OF cat_timezone_rec_t;

   TYPE cat_dss_file_rec_t IS RECORD (
      dss_filemgr_url   VARCHAR2 (32),
      dss_file_name     NUMBER (10)
   );

   TYPE cat_dss_file_tab_t IS TABLE OF cat_dss_file_rec_t;

   TYPE cat_dss_xchg_set_rec_t IS RECORD (
      office_id                  VARCHAR2 (16),
      dss_xchg_set_id            VARCHAR (32),
      dss_xchg_set_description   VARCHAR (80),
      dss_filemgr_url            VARCHAR2 (32),
      dss_file_name              VARCHAR2 (255),
      dss_xchg_direction_id      VARCHAR2 (16),
      dss_xchg_last_update       TIMESTAMP(6)
   );

   TYPE cat_dss_xchg_set_tab_t IS TABLE OF cat_dss_xchg_set_rec_t;

   TYPE cat_dss_xchg_ts_map_rec_t IS RECORD (
      cwms_ts_id              VARCHAR2 (183),
      dss_pathname            VARCHAR2 (391),
      dss_parameter_type_id   VARCHAR2 (8),
      dss_unit_id             VARCHAR2 (16),
      dss_timezone_name       VARCHAR2 (28),
      dss_tz_usage_id         VARCHAR2 (8)
   );

   TYPE cat_dss_xchg_ts_map_tab_t IS TABLE OF cat_dss_xchg_ts_map_rec_t;

   TYPE cat_property_rec_t IS RECORD (
      office_id      VARCHAR2(16),
      prop_catergory VARCHAR2(256),
      prop_id        VARCHAR2(256),
      prop_value     VARCHAR2(256),
      prop_comment   VARCHAR2(256)
   );

   TYPE cat_property_tab_t IS TABLE OF cat_property_rec_t;
   
-- cat_ts...
   FUNCTION cat_ts_rec2obj (r IN cat_ts_rec_t)
      RETURN cat_ts_obj_t;

   FUNCTION cat_ts_tab2obj (t IN cat_ts_tab_t)
      RETURN cat_ts_otab_t;

   FUNCTION cat_ts_obj2rec (o IN cat_ts_obj_t)
      RETURN cat_ts_rec_t;

   FUNCTION cat_ts_obj2tab (o IN cat_ts_otab_t)
      RETURN cat_ts_tab_t;

-- cat_ts_cwms_20...
   FUNCTION cat_ts_cwms_20_rec2obj (r IN cat_ts_cwms_20_rec_t)
      RETURN cat_ts_cwms_20_obj_t;

   FUNCTION cat_ts_cwms_20_tab2obj (t IN cat_ts_cwms_20_tab_t)
      RETURN cat_ts_cwms_20_otab_t;

   FUNCTION cat_ts_cwms_20_obj2rec (o IN cat_ts_cwms_20_obj_t)
      RETURN cat_ts_cwms_20_rec_t;

   FUNCTION cat_ts_cwms_20_obj2tab (o IN cat_ts_cwms_20_otab_t)
      RETURN cat_ts_cwms_20_tab_t;

-- cat_loc...
   FUNCTION cat_loc_rec2obj (r IN cat_loc_rec_t)
      RETURN cat_loc_obj_t;

   FUNCTION cat_loc_tab2obj (t IN cat_loc_tab_t)
      RETURN cat_loc_otab_t;

   FUNCTION cat_loc_obj2rec (o IN cat_loc_obj_t)
      RETURN cat_loc_rec_t;

   FUNCTION cat_loc_obj2tab (o IN cat_loc_otab_t)
      RETURN cat_loc_tab_t;

-- cat_loc_alias...
   FUNCTION cat_loc_alias_rec2obj (r IN cat_loc_alias_rec_t)
      RETURN cat_loc_alias_obj_t;

   FUNCTION cat_loc_alias_tab2obj (t IN cat_loc_alias_tab_t)
      RETURN cat_loc_alias_otab_t;

   FUNCTION cat_loc_alias_obj2rec (o IN cat_loc_alias_obj_t)
      RETURN cat_loc_alias_rec_t;

   FUNCTION cat_loc_alias_obj2tab (o IN cat_loc_alias_otab_t)
      RETURN cat_loc_alias_tab_t;

-- cat_param...
   FUNCTION cat_param_rec2obj (r IN cat_param_rec_t)
      RETURN cat_param_obj_t;

   FUNCTION cat_param_tab2obj (t IN cat_param_tab_t)
      RETURN cat_param_otab_t;

   FUNCTION cat_param_obj2rec (o IN cat_param_obj_t)
      RETURN cat_param_rec_t;

   FUNCTION cat_param_obj2tab (o IN cat_param_otab_t)
      RETURN cat_param_tab_t;

-- cat_sub_param.
   FUNCTION cat_sub_param_rec2obj (r IN cat_sub_param_rec_t)
      RETURN cat_sub_param_obj_t;

   FUNCTION cat_sub_param_tab2obj (t IN cat_sub_param_tab_t)
      RETURN cat_sub_param_otab_t;

   FUNCTION cat_sub_param_obj2rec (o IN cat_sub_param_obj_t)
      RETURN cat_sub_param_rec_t;

   FUNCTION cat_sub_param_obj2tab (o IN cat_sub_param_otab_t)
      RETURN cat_sub_param_tab_t;

-- cat_sub_loc...
   FUNCTION cat_sub_loc_rec2obj (r IN cat_sub_loc_rec_t)
      RETURN cat_sub_loc_obj_t;

   FUNCTION cat_sub_loc_tab2obj (t IN cat_sub_loc_tab_t)
      RETURN cat_sub_loc_otab_t;

   FUNCTION cat_sub_loc_obj2rec (o IN cat_sub_loc_obj_t)
      RETURN cat_sub_loc_rec_t;

   FUNCTION cat_sub_loc_obj2tab (o IN cat_sub_loc_otab_t)
      RETURN cat_sub_loc_tab_t;

-- cat_state.
   FUNCTION cat_state_rec2obj (r IN cat_state_rec_t)
      RETURN cat_state_obj_t;

   FUNCTION cat_state_tab2obj (t IN cat_state_tab_t)
      RETURN cat_state_otab_t;

   FUNCTION cat_state_obj2rec (o IN cat_state_obj_t)
      RETURN cat_state_rec_t;

   FUNCTION cat_state_obj2tab (o IN cat_state_otab_t)
      RETURN cat_state_tab_t;

-- cat_county.
   FUNCTION cat_county_rec2obj (r IN cat_county_rec_t)
      RETURN cat_county_obj_t;

   FUNCTION cat_county_tab2obj (t IN cat_county_tab_t)
      RETURN cat_county_otab_t;

   FUNCTION cat_county_obj2rec (o IN cat_county_obj_t)
      RETURN cat_county_rec_t;

   FUNCTION cat_county_obj2tab (o IN cat_county_otab_t)
      RETURN cat_county_tab_t;

-- cat_timezone.
   FUNCTION cat_timezone_rec2obj (r IN cat_timezone_rec_t)
      RETURN cat_timezone_obj_t;

   FUNCTION cat_timezone_tab2obj (t IN cat_timezone_tab_t)
      RETURN cat_timezone_otab_t;

   FUNCTION cat_timezone_obj2rec (o IN cat_timezone_obj_t)
      RETURN cat_timezone_rec_t;

   FUNCTION cat_timezone_obj2tab (o IN cat_timezone_otab_t)
      RETURN cat_timezone_tab_t;

-- cat_dss_file.
   FUNCTION cat_dss_file_rec2obj (r IN cat_dss_file_rec_t)
      RETURN cat_dss_file_obj_t;

   FUNCTION cat_dss_file_tab2obj (t IN cat_dss_file_tab_t)
      RETURN cat_dss_file_otab_t;

   FUNCTION cat_dss_file_obj2rec (o IN cat_dss_file_obj_t)
      RETURN cat_dss_file_rec_t;

   FUNCTION cat_dss_file_obj2tab (o IN cat_dss_file_otab_t)
      RETURN cat_dss_file_tab_t;

-- cat_dss_xchg_set.
   FUNCTION cat_dss_xchg_set_rec2obj (r IN cat_dss_xchg_set_rec_t)
      RETURN cat_dss_xchg_set_obj_t;

   FUNCTION cat_dss_xchg_set_tab2obj (t IN cat_dss_xchg_set_tab_t)
      RETURN cat_dss_xchg_set_otab_t;

   FUNCTION cat_dss_xchg_set_obj2rec (o IN cat_dss_xchg_set_obj_t)
      RETURN cat_dss_xchg_set_rec_t;

   FUNCTION cat_dss_xchg_set_obj2tab (o IN cat_dss_xchg_set_otab_t)
      RETURN cat_dss_xchg_set_tab_t;

-- cat_dss_xchg_ts_map.
   FUNCTION cat_dss_xchg_ts_map_rec2obj (r IN cat_dss_xchg_ts_map_rec_t)
      RETURN cat_dss_xchg_ts_map_obj_t;

   FUNCTION cat_dss_xchg_ts_map_tab2obj (t IN cat_dss_xchg_ts_map_tab_t)
      RETURN cat_dss_xchg_ts_map_otab_t;

   FUNCTION cat_dss_xchg_ts_map_obj2rec (o IN cat_dss_xchg_ts_map_obj_t)
      RETURN cat_dss_xchg_ts_map_rec_t;

   FUNCTION cat_dss_xchg_ts_map_obj2tab (o IN cat_dss_xchg_ts_map_otab_t)
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
   FUNCTION cat_ts_tab (
      p_officeid              IN   VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_ts(...)
--
--
   PROCEDURE cat_ts (
      p_cwms_cat              OUT      sys_refcursor,
      p_officeid              IN       VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- function cat_ts_cwms_20_tab(...)
--
--
   FUNCTION cat_ts_cwms_20_tab (
      p_officeid              IN   VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_ts_cwms_20_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_ts_cwms_20(...)
--
--
   PROCEDURE cat_ts_cwms_20 (
      p_cwms_cat              OUT      sys_refcursor,
      p_officeid              IN       VARCHAR2 DEFAULT NULL,
      p_ts_subselect_string   IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_LOC
--
-- These procedures and functions catalog locations in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                Datatype      Description
--    ------------------- ------------- ------------------------------------------
--    office_id           varchar2(16)  Name of owning office
--    base_loc_id         varchar2(16)  CWMS location name
--    state_initial       varchar2(2)   Location state
--    county_name         varchar2(40)  Location county
--    timezone_id         varchar2(28)  Location time zone
--    location_type       varchar2(16)  Location type
--    latitude            number        Location latitude
--    longitude           number        Location longitude
--    elevation           number        Location elevation
--    elev_unit_id        varchar2(16)  Elvation units
--    vertical_datum      varchar2(16)  Location vertical datum
--    public_name         varchar2(32)  Location public name
--    long_name           varchar2(80)  Location long name
--    description         varchar2(512) Location description
--
-- If the p_office_id parameter is not null, only records with matching office ids
-- are returned.  Otherwise, records for all offices are returned.
--
-- The records are returned sorted first by office_id (ascending) and then by
-- cwms_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_loc_tab(...)
--
--
   FUNCTION cat_loc_tab (
      p_officeid         IN   VARCHAR2 DEFAULT NULL,
      p_elevation_unit   IN   VARCHAR2 DEFAULT 'm'
   )
      RETURN cat_loc_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_loc(...)
--
--
   PROCEDURE cat_loc (
      p_cwms_cat         OUT      sys_refcursor,
      p_officeid         IN       VARCHAR2 DEFAULT NULL,
      p_elevation_unit   IN       VARCHAR2 DEFAULT 'm'
   );

-------------------------------------------------------------------------------
-- CAT_LOC_ALIAS
--
-- These procedures and functions catalog location aliases in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                Datatype      Description
--    ------------------- ------------- ------------------------------------------
--    office_id           varchar2(16)  Name of owning office
--    cwms_id             varchar2(16)  CWMS location name
--    source_id           varchar2(16)  Location naming convention (SHEF, GOES, ...)
--    gage_id             varchar2(32)  Location name in naming convention
--
-- If the p_office_id parameter is not null, only records with matching office ids
-- are returned.  Otherwise, records for all offices are returned.
--
-- If the p_cwmsid parameter is not null, only records with matching the specified
-- location are returned.  Otherwise, records for all locations are returned.
--
-- The records are returned sorted first by office_id (ascending) and then by
-- cwms_id (ascending), source_id (ascending) and gage_id (ascending).
--
-------------------------------------------------------------------------------
-- cat_loc_alias_tab_t function cat_loc_alias_tab(...)
--
--
   FUNCTION cat_loc_alias_tab (
      p_officeid   IN   VARCHAR2 DEFAULT NULL,
      p_cwmsid     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_loc_alias(...)
--
--
   PROCEDURE cat_loc_alias (
      p_cwms_cat   OUT      sys_refcursor,
      p_officeid   IN       VARCHAR2 DEFAULT NULL,
      p_cwmsid     IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_PARAM
--
-- These procedures and functions catalog parameters in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                Datatype      Description
--    ------------------- ------------- ---------------------------------------
--    parameter_id        varchar2(16)  Short name of parameter
--    param_long_name     varchar2(80)  Long name of parameter
--    param_description   varchar2(160) Description of parameter
--    unit_id             varchar2(16)  Short name of parameter database units
--    unit_long_name      varchar2(80)  Long name of parameter database units
--    unit_description    varchar2(80)  Description of paramter database units
--
-- The records are returned sorted by parameter_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_param_tab(...)
--
--
   FUNCTION cat_param_tab
      RETURN cat_param_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_param(...)
--
--
   PROCEDURE cat_param (p_cwms_cat OUT sys_refcursor);

-------------------------------------------------------------------------------
-- CAT_SUB_PARAM
--
-- These procedures and functions catalog sub_parameters in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name             Datatype      Description
--    ---------------- ------------- ---------------------------------------
--    parameter_id     varchar2(16)  Short name of parameter
--    subparameter_id  varchar2(32)  Name of sub-parameter
--    description      varchar2(80)  Description of sub-parameter
--
-- The records are returned sorted first by parameter_id (ascending), then by
-- subparameter_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_sub_param_tab(...)
--
--
   FUNCTION cat_sub_param_tab
      RETURN cat_sub_param_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_sub_param(...)
--
--
   PROCEDURE cat_sub_param (p_cwms_cat OUT sys_refcursor);

-------------------------------------------------------------------------------
-- CAT_SUB_LOC...
--
-- These procedures and functions produce a catalog sub_locations in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name             Datatype      Description
--    ---------------- ------------- ---------------------------------------
--    sublocation_id   varchar2(32)  Name of sub-location.
--    description      varchar2(80)  Description of sub-location.
--
-- The records are returned sorted first by sublocation_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_sub_loc_tab(...)
--
--
   FUNCTION cat_sub_loc_tab (p_officeid IN VARCHAR2 DEFAULT NULL)
      RETURN cat_sub_loc_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_sub_loc(...)
--
--
   PROCEDURE cat_sub_loc (
      p_cwms_cat   OUT      sys_refcursor,
      p_officeid   IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_STATE
--
-- These procedures and functions catalog states in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name             Datatype      Description
--    ---------------- ------------- ---------------------------------------
--    state_initial    varchar2(2)   State abbreviation
--    state_name       varchar2(40)  Name of state
--
-- The records are returned sorted by state_initial (ascending).
--
-------------------------------------------------------------------------------
-- function cat_state_tab(...)
--
--
   FUNCTION cat_state_tab
      RETURN cat_state_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_state(...)
--
--
   PROCEDURE cat_state (p_cwms_cat OUT sys_refcursor);

-------------------------------------------------------------------------------
-- CAT_COUNTY
--
-- These procedures and functions catalog counties in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name           Datatype      Description
--    -------------- ------------- --------------------
--    county_id      varchar2(3)   County abbreviation
--    county_name    varchar2(40)  Name of county
--    state_initial  varchar2(2)   State abbreviation
--
-- If p_stateint is null, all counties in the database are returned.  Otherwise
-- only the counties for the specified state.
--
-- The records are returned sorted first by state_initial (ascending), then by
-- county_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_county_tab(...)
--
--
   FUNCTION cat_county_tab (p_stateint IN VARCHAR2 DEFAULT NULL)
      RETURN cat_county_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_county(...)
--
--
   PROCEDURE cat_county (
      p_cwms_cat   OUT      sys_refcursor,
      p_stateint   IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_TIMEZONE
--
-- These procedures and functions catalog time zones in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name             Datatype                      Description
--    ---------------- ----------------------------- ----------------------------------------
--    timezone_name    varchar2(28)                  Name of time zone
--    utc_offset       interval day(2) to second(6)  Amount of time (in seconds) ahead of UTC
--    dst_offset       interval day(2) to second(6)  Amount of time shift (in seconds) for DST
--
-- The records are returned sorted by timezone_name (ascending).
--
-------------------------------------------------------------------------------
-- function cat_timezone_tab(...)
--
--
   FUNCTION cat_timezone_tab
      RETURN cat_timezone_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_timezone(...)
--
--
   PROCEDURE cat_timezone (p_cwms_cat OUT sys_refcursor);

-------------------------------------------------------------------------------
-- CAT_DSS_FILE
--
-- These procedures and functions catalog DSS file references in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name            Datatype      Description
--    --------------- ------------- -------------------
--    dss_filemgr_url varchar2(32)  DSSFileManager URL
--    dss_file_name   varchar2(255) DSS file name
--
-- If both input parameters are null, then records for every DSS file referenced
-- in the database are returned.
--
-- If either of the input parameters is non-null, it is used as in a LIKE clause
-- to filter the retuned values.  The returned values may be filtered by only one
-- input parameter or by both of them.
--
-- The input parameters may use filename-type wildcards (*, ?) and/or SQL-type
-- wildcards (%, _).
--
-- The records are returned sorted first by dss_filemgr_url (ascending) and then
-- by dss_file_name (ascending).
--
-------------------------------------------------------------------------------
-- function cat_dss_file_tab(...)
--
--
   FUNCTION cat_dss_file_tab (
      p_filemgr_url   IN   VARCHAR2 DEFAULT NULL,
      p_file_name     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_dss_file_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_dss_file(...)
--
--
   PROCEDURE cat_dss_file (
      p_cwms_cat      OUT      sys_refcursor,
      p_filemgr_url   IN       VARCHAR2 DEFAULT NULL,
      p_file_name     IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_SET
--
-- These procedures and functions catalog DSS exchange sets in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    office_id                varchar2(16)  Name of owning office
--    dss_xchg_set_id          varchar(32)   DSS exchange set name
--    dss_xchg_set_description varchar(80)   DSS exchange set description
--    dss_filemgr_url          varchar2(32)  DSSFileManager URL
--    dss_file_name            varchar2(255) DSS file name
--    dss_xchg_direction_id    varchar2(16)  Real time direction identifier
--
-- The dss_xchg_direction_id is returned as 'DssToOracle' or 'OracleToDss' for
-- real time exchange sets.  It is returned as null for batch-only exchange
-- sets.
--
-- If the office_id parameter is null, then records will be returned for every
-- CWMS office.  Otherwise, only records for the specified office are returned.
--
-- If either of p_filemgr_url or p_file_name is non-null, it is used as in a
-- LIKE clause to filter the retuned values.  The returned values may be filtered
-- by only one input parameter or by both of them.
--
-- The p_filemgr_url or p_file_name parameters may use filename-type wildcards
-- (*, ?) and/or SQL-typewildcards (%, _).
--
-- The records are returned sorted by dss_xchg_set_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_dss_xchg_set_tab(...)
--
--
   FUNCTION cat_dss_xchg_set_tab (
      p_officeid      IN   VARCHAR2 DEFAULT NULL,
      p_filemgr_url   IN   VARCHAR2 DEFAULT NULL,
      p_file_name     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_dss_xchg_set_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_dss_xchg_set(...)
--
--
   PROCEDURE cat_dss_xchg_set (
      p_cwms_cat      OUT      sys_refcursor,
      p_officeid      IN       VARCHAR2 DEFAULT NULL,
      p_filemgr_url   IN       VARCHAR2 DEFAULT NULL,
      p_file_name     IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_DSS_XCHG_TS_MAP
--
-- These procedures and functions catalog time series mappings for DSS exchange
-- sets in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                   Datatype      Description
--    ---------------------- ------------- ----------------------------
--    cwms_ts_id             varchar2(183) CWMS time series identifier
--    dss_pathname           varchar2(391) HEC-DSS pathname
--    dss_parameter_type_id  varchar2(8)   HEC-DSS parameter type
--    dss_unit_id            varchar2(16)  HEC-DSS units
--    dss_timezone_name      varchar2(28)  HEC-DSS timezone
--    dss_tz_usage_id        varchar2(8)   HEC-DSS timezone usage
--
-- The records are returned sorted by cwms_ts_id (ascending).
--
-------------------------------------------------------------------------------
-- function cat_dss_xchg_ts_map_tab(...)
--
--
   FUNCTION cat_dss_xchg_ts_map_tab (
      p_officeid          IN   VARCHAR2,
      p_dss_xchg_set_id   IN   VARCHAR2
   )
      RETURN cat_dss_xchg_ts_map_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_dss_xchg_ts_map(...)
--
--
   PROCEDURE cat_dss_xchg_ts_map (
      p_cwms_cat          OUT      sys_refcursor,
      p_officeid          IN       VARCHAR2,
      p_dss_xchg_set_id   IN       VARCHAR2
   );

-------------------------------------------------------------------------------
-- CAT_LOC_ALIASES                                                           --
--
-- These procedures and functions catalog a location's aliases in the database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The p_abbreviated option allows one to choose between an abreviated ref cursor
-- that only contains the agency and alias ids or a complete ref cursor that
-- contains more descriptive information on the agency and alias ids.
--
-- Default abreviated ref cursor contains...
--
--    Name                Datatype      Description
--    ------------------- ------------- ------------------------------------------
--    office_id           varchar2(16)  Name of owning office
--    location_id         varchar2(49)  CWMS base-sub location name.
--    agency_id           varchar2(16)  Agency Id.
--    alias_id            varchar2(16)  Alias Id.
--
-- The complete ref cursor (p_abreviated = F)...
--
--    Name                Datatype      Description
--    ------------------- ------------- ------------------------------------------
--    office_id           varchar2(16)  Name of owning office
--    location_id         varchar2(49)  CWMS base-sub location name.
--    agency_id           varchar2(16)  Agency's Id.
--    alias_id            varchar2(16)  Alias' Id.
--    agency_name         varchar2(80)  Agency's Name.
--    alias_public_name   varchar2(32)  Alias' Public Name.
--    alias_long_name     varchar2(80)  Alias' Long Name.
--
-- If the p_office_id parameter is not null, only records with matching office ids
-- are returned.  Otherwise, records for all offices are returned.
--
-- The records are returned sorted by office_id, location_id, agency_id, alias_id.
--
--
-------------------------------------------------------------------------------
-- function cat_loc_alias_abrev_tab(...)
--
--
   FUNCTION cat_loc_alias_abrev_tab (
      p_location_id   IN   VARCHAR2 DEFAULT NULL,
      p_agency_id     IN   VARCHAR2 DEFAULT NULL,
      p_office_id     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN cat_loc_alias_abrev_tab_t PIPELINED;

-------------------------------------------------------------------------------
-- procedure cat_loc_aliases(...)
--
--
   PROCEDURE cat_loc_aliases (
      p_cwms_cat      OUT      sys_refcursor,
      p_location_id   IN       VARCHAR2 DEFAULT NULL,
      p_agency_id     IN       VARCHAR2 DEFAULT NULL,
      p_abreviated    IN       VARCHAR2 DEFAULT 'T',
      p_office_id     IN       VARCHAR2 DEFAULT NULL
   );

-------------------------------------------------------------------------------
-- CAT_PROPERTY
--
-- These procedures and functions catalog (Java-like) properties in the CWMS.
-- database.
--
-- Function returns may be used as source of SELECT statements.
--
-- The returned records contain the following columns:
--
--    Name                      Datatype      Description
--    ------------------------ ------------- ----------------------------
--    office_id                varchar2(16)  Name of owning office
--    prop_category            varchar2(256) Category or component to which 
--                                           property applies
--    prop_id                  varchar2(256) Property name
--    prop_value               varchar2(256) Property value
--    prop_comment             varchar2(256) Comment on property value or its use
--
-- If the office_id parameter is null, then records will be returned for every
-- CWMS office.  Otherwise, only records for the specified office are returned.
--
-- If either of prop_category or prop_id is non-null, it is used as in a
-- LIKE clause to filter the retuned values.  The returned values may be filtered
-- by only one input parameter or by both of them.  If either is null, it matches
-- everything.  These parameters are matched without regard to character case.
--
-- The prop_category or prop_id parameters may use filename-type wildcards
-- (*, ?) and/or SQL-typewildcards (%, _).
--
-- The records are returned sorted by office_id, prop_category, and prop_id  
-- (ascending, non-case-sensitive).
--
-------------------------------------------------------------------------------
-- function cat_property_tab(...)
--
--
   FUNCTION cat_property_tab (
      p_office_id     IN  VARCHAR2 DEFAULT NULL,
      p_prop_category IN  VARCHAR2 DEFAULT NULL,
      p_prop_id       IN  VARCHAR2 DEFAULT NULL
   )
      RETURN cat_property_tab_t PIPELINED;
   
-------------------------------------------------------------------------------
-- procedure cat_property(...)
--
--
   PROCEDURE cat_property (
      p_cwms_cat      OUT sys_refcursor,
      p_office_id     IN  VARCHAR2 DEFAULT NULL,
      p_prop_category IN  VARCHAR2 DEFAULT NULL,
      p_prop_id       IN  VARCHAR2 DEFAULT NULL
   );
   
END cwms_cat;
/
