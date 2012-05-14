---------------------------------------------------------------------------
-- This script may create type bodies with errors due to interdependence --
-- on packages. Continue past the errors and let the schema re-compile   --
-- in the main script determine if there is actually a problem.          --
---------------------------------------------------------------------------
-- WHENEVER sqlerror exit sql.sqlcode
WHENEVER sqlerror continue
SET define on
@@../cwms/defines.sql
SET serveroutput on

------------------------------
-- drop types if they exist --
------------------------------
begin
   for rec in (select object_name
                 from dba_objects
                where owner = '&cwms_schema'
                  and object_type = 'TYPE'
                  and object_name not like 'SYS\_%' escape '\'
             order by object_name)
   loop
      dbms_output.put_line('Dropping type '||rec.object_name);
      execute immediate 'drop type '||rec.object_name||' force';
   end loop;
end;
/

create type SHEF_SPEC_TYPE
/**
 * Object type representing SHEF processing for a CWMS time series
 *
 * @member cwms_ts_id the CWMS time series identifier
 * @member shef_location_id the SHEF location identifier
 * @member shef_pe_code the SHEF physical element identifier
 * @member shef_tse_code the SHEF identifiers for type, source, and extremum
 * @member shef_duration the SHEF duration identifier
 * @member shef_incoming_units the unit of the incoming data. This is necessary
 *         in case incoming data is not in the SHEF standard unit.
 * @member shef_time_zone_id the time zone of the incoming data. This is necessary
 *         in case incoming data is not in UTC.
 * @member daylight_savings specifies whether the <code><big>shef_time_zone_id</big></code>
 *         observes daylight savings.
 *         <ul>
 *         <li><code><big>'T'</big></code> - specifies daylight savings is observed
 *         <li><code><big>'F'</big></code> - specifies daylight savings is not observed
 *         </ul>
 * @member interval_utc_offset data offset from start of UTC interval, in minutes.
 *         Valid only for regular time series.
 *         <ul>
 *         <li><code><big><a href="cwms_util#const=utc_offset_irregular">cwms_util.utc_offset_irregular</a></big></code> - value used for irregular time series
 *         <li><code><big><a href="cwms_util#const=utc_offset_undefined">cwms_util.utc_offset_undefined</a></big></code> - value indicating offset has not yet been defined for regular time sereies
 *         </ul>
 * @member snap_forward_minutes number of minutes before the expected time to accept a regular time series value.
 *         The value specifies the number of minutes before the <code><big>interval_utc_offset</big></code>
 *         within which to accept data as being at the specified offset.
 * @member snap_backward_minutes number of minutes after the expected time to accept a regular time series value.
 *         The value specifies the number of minutes after the <code><big>interval_utc_offset</big></code>
 *         within which to accept data as being at the specified offset.
 * @member ts_active_flag flag specifying whether to process the indicated time series.
 *         Allows turning the processing of a specific time series on and off.
 *         <ul>
 *         <li><code><big>'T'</big></code> - specifies the time series is to be processed
 *         <li><code><big>'F'</big></code> - specifies the time series is not to be processed
 *         </ul>
 * @see constant cwms_util.utc_offset_irregular
 * @see constant cwms_util.utc_offset_undefined
 */
AS
   OBJECT (
      cwms_ts_id VARCHAR2 (132),
      shef_location_id VARCHAR2 (8),
      shef_pe_code VARCHAR2 (2),
      shef_tse_code VARCHAR2 (3),
      shef_duration VARCHAR2 (4),
      shef_incoming_units VARCHAR2 (16),
      shef_time_zone_id VARCHAR2 (3),
      daylight_savings VARCHAR2 (1),      -- T or F psuedo boolean.
      interval_utc_offset NUMBER,         -- in minutes.
      snap_forward_minutes NUMBER,
      snap_backward_minutes NUMBER,
      ts_active_flag VARCHAR2 (1)         -- T or F psuedo boolean.
   );
/

create type  SHEF_SPEC_ARRAY
/**
 * Table of <code><big>shef_spec_type</big></code> records.  This collection usually
 * comprises the entire SHEF decoding criteria set for a single CWMS data stream.
 *
 * @see type shef_spec_type
 */
IS TABLE OF shef_spec_type;
/

CREATE TYPE tsv_type
/**
 * Object type representing a single time series value.  This type carries time zone
 * information, so any usage of it should not explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @member date_time    the time of the value, including time zone
 * @member value        the actual time series value
 * @member quality_code the quality assigned to the time series value.
 *
 * @see type ztsv_type
 * @see view mv_data_quality
 */
AS OBJECT (
   date_time      TIMESTAMP WITH TIME ZONE,
   VALUE          BINARY_DOUBLE,
   quality_code   NUMBER
);
/

CREATE TYPE tsv_array
/**
 * Table of <code><big>tsv_type</big></code> records. This collection specifies
 * a time series of values for a certain time range.  This type carries time zone
 * information, so any usage of it should not explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type tsv_type
 * @see type ztsv_array
 */
IS TABLE OF tsv_type;
/

create type ztsv_type
/**
 * Object type representing a single time series value. This type does not carry
 * time zone information, so any usage of it needs to explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @member date_time the time of the value, not including time zone
 *
 * @member value the actual time series value
 *
 * @member quality_code the quality assigned to the time series value.
 *
 * @see type tsv_type
 * @see type ztsv_type
 * @see type ztsv_array
 * @see view mv_data_quality
 */
AS OBJECT (
   date_time    DATE,
   VALUE        BINARY_DOUBLE,
   quality_code NUMBER);
/

create type ztsv_array
/**
 * Table of <code><big>ztsv_type</big></code> records. This collection specifies
 * a time series of values for a certain time range.  This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type ztsv_type
 * @see type ztsv_array_tab
 */
IS TABLE OF ztsv_type;
/

create type ztsv_array_tab
/**
 * Table of <code><big>ztsv_array</big></code> records. This collection specifies
 * multiple time series.  There is no implicit constraint that all of the time series
 * are for the same location or time range, although any routine that uses this type
 * may impose these constraints.  This type does not carrytime zone information, so
 * any usage of it should explicitly declare the time zone. External specification of
 * time series attributes is also required for proper usage.
 *
 * @see type ztsv_type
 * @see type ztsv_array
 */
as table of ztsv_array;
/

create type ztimeseries_type
/**
 * Object type representing time series values with attributes. This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 *
 * @member tsid CWMS time series identifier. This identifier includes six parts separated
 *         by the period (.) character:
 *         <ol>
 *         <li>location and optionally sub-location</li>
 *         <li>parameter and optionally sub-parameter</li>
 *         <li>parameter type</li>
 *         <li>interval (recurrance period)</li>
 *         <li>duration (coverage period)</li>
 *         <li>version</li>
 *         </ol>
 *
 * @member unit the unit of the value member of each record in the <code><big>data</big></code>
 *          member.
 *
 * @member data the time series values
 *
 * @see type ztsv_array
 */
AS OBJECT (
   tsid VARCHAR2 (183),
   unit VARCHAR2 (16),
   data ztsv_array);
/

create type ztimeseries_array
/**
 * Table of <code><big>ztimeseries_type</big></code> records. This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 */
IS TABLE OF ztimeseries_type;
/

CREATE TYPE char_16_array_type
/**
 * Type suitable for holding multiple base locations, base parameters, or other text
 * not longer than 16 bytes.
 */
IS TABLE OF VARCHAR2 (16);
/

CREATE TYPE char_32_array_type
/**
 * Type suitable for holding multiple sub-locations, sub-parameters, or other text
 * not longer than 32 bytes.
 */
IS TABLE OF VARCHAR2 (32);
/

CREATE TYPE char_49_array_type
/**
 * Type suitable for holding multiple locations, parameters, or other text
 * not longer than 49 bytes.
 */
IS TABLE OF VARCHAR2 (49);
/

CREATE TYPE char_183_array_type
/**
 * Type suitable for holding multiple time series identifiers or other text
 * not longer than 183 bytes.
 */
IS TABLE OF VARCHAR2 (183);
/

CREATE TYPE date_table_type
/**
 * Type suitable for holding multiple date/time values
 */
AS TABLE OF DATE;
/

CREATE TYPE timeseries_type
/**
 * Type suitable for holding a single time series.
 *
 * @member tsid the time series identifier
 * @member unit the unit of the data values
 * @member data the time series times, data values, and quality codes.  This type
 *         carries time zone information, so any usage of it should not explicitly
 *         declare the time zone.
 *
 * @see type tsv_array
 */
AS OBJECT (
   tsid   VARCHAR2 (183),
   unit   VARCHAR2 (16),
   DATA   tsv_array
);
/

CREATE TYPE timeseries_array
/**
 * Type suitable for holding multiple time series.
 *
 * @see type timeseries_type
 */
IS TABLE OF timeseries_type;
/

CREATE TYPE timeseries_req_type
/**
 * Type suitable for requesting the retrieval of a time series.
 *
 * @member tsid the time seried identifier
 * @member unit the unit to return data values in
 * @member start_time  the beginning of the time window for which to retrieve data
 * @member end_time    the end of the time window for which to retrieve data
 *
 * @see type timeseries_req_array
 */
AS OBJECT (
   tsid         VARCHAR2 (183),
   unit         VARCHAR2 (16),
   start_time   DATE,
   end_time     DATE
);
/

CREATE TYPE timeseries_req_array
/**
 * Type suitable for requesting the retrieval of multiple time series.
 *
 * @see type timeseries_req_type
 * @see cwms_ts.retrieve_ts_multi
 */
IS TABLE OF timeseries_req_type;
/

-- not documented, used only in body of retrieve_ts_multi
CREATE TYPE nested_ts_type AS OBJECT (
   SEQUENCE     INTEGER,
   tsid         VARCHAR2 (183),
   units        VARCHAR2 (16),
   start_time   DATE,
   end_time     DATE,
   DATA         tsv_array
);
/

-- not documented, used only in body of retrieve_ts_multi
CREATE TYPE nested_ts_table IS TABLE OF nested_ts_type;
/

-- not documented, used only in routine body
CREATE TYPE source_type AS OBJECT (
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/

-- not documented, used only in routine body
CREATE TYPE source_array IS TABLE OF source_type;
/

create type tr_template_set_type
/**
 * [description needed]
 *
 * @see type tr_template_set_array
 * @see type char_183_array_type
 *
 * @member description           [description needed]
 * @member store_dep_flag        [description needed]
 * @member unit_system           [description needed]
 * @member transform_id          [description needed]
 * @member lookup_agency         [description needed]
 * @member lookup_rating_version [description needed]
 * @member scaling_arg_a         [description needed]
 * @member scaling_arg_b         [description needed]
 * @member scaling_arg_c         [description needed]
 * @member array_of_masks        [description needed]
 */
AS OBJECT (
   description             VARCHAR2 (132),
   store_dep_flag          VARCHAR2 (1),
   unit_system             VARCHAR2 (2),
   transform_id            VARCHAR2 (32),
   lookup_agency           VARCHAR2 (32),
   lookup_rating_version   VARCHAR2 (32),
   scaling_arg_a           NUMBER,
   scaling_arg_b           NUMBER,
   scaling_arg_c           NUMBER,
   array_of_masks          char_183_array_type
);
/

create type tr_template_set_array
/**
 * [description needed]
 *
 * @see type tr_template_set_type
 * @see cwms_vt.store_tr_template
 */
IS TABLE OF tr_template_set_type;
/

-- not documented, used only in routine body
CREATE TYPE loc_type_ds AS OBJECT (
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
   description      VARCHAR2 (512),
   data_sources     source_array
);
/

/*
CREATE TYPE loc_type AS OBJECT (
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
/

CREATE TYPE alias_type AS OBJECT (
   agency_id           VARCHAR2 (16),
   alias_id            VARCHAR2 (16),
   agency_name         VARCHAR2 (80),
   alias_public_name   VARCHAR2 (32),
   alias_long_name     VARCHAR2 (80)
);
/

CREATE TYPE alias_array IS TABLE OF alias_type;
/
*/

create type screen_dur_mag_type
/**
 * [description needed]
 *
 * @member duration_id  [description needed]
 * @member reject_lo    [description needed]
 * @member reject_hi    [description needed]
 * @member question_lo  [description needed]
 * @member question_hi  [description needed]
 *
 * @see type screen_dur_mag_array
 */
AS OBJECT (
   duration_id   VARCHAR2 (16),
   reject_lo     NUMBER,
   reject_hi     NUMBER,
   question_lo   NUMBER,
   question_hi   NUMBER
);
/
create type screen_dur_mag_array
/**
 * [description needed]
 *
 * @see type screen_dur_mag_type
 */
IS TABLE OF screen_dur_mag_type;
/

create type screen_crit_type
/**
 * [description needed]
 *
 * @member season_start_day         [description needed]
 * @member season_start_month       [description needed]
 * @member range_reject_lo          [description needed]
 * @member range_reject_hi          [description needed]
 * @member range_question_lo        [description needed]
 * @member range_question_hi        [description needed]
 * @member rate_change_reject_rise  [description needed]
 * @member rate_change_reject_fall  [description needed]
 * @member rate_change_quest_rise   [description needed]
 * @member rate_change_quest_fall   [description needed]
 * @member const_reject_duration_id [description needed]
 * @member const_reject_min         [description needed]
 * @member const_reject_tolerance   [description needed]
 * @member const_reject_n_miss      [description needed]
 * @member const_quest_duration_id  [description needed]
 * @member const_quest_min          [description needed]
 * @member const_quest_tolerance    [description needed]
 * @member const_quest_n_miss       [description needed]
 * @member estimate_expression      [description needed]
 * @member dur_mag_array            [description needed]
 *
 * @see type screen_crit_array
 */
AS OBJECT (
   season_start_day           NUMBER,
   season_start_month         NUMBER,
   range_reject_lo            NUMBER,
   range_reject_hi            NUMBER,
   range_question_lo          NUMBER,
   range_question_hi          NUMBER,
   rate_change_reject_rise    NUMBER,
   rate_change_reject_fall    NUMBER,
   rate_change_quest_rise     NUMBER,
   rate_change_quest_fall     NUMBER,
   const_reject_duration_id   VARCHAR2 (16),
   const_reject_min           NUMBER,
   const_reject_tolerance     NUMBER,
   const_reject_n_miss        NUMBER,
   const_quest_duration_id    VARCHAR2 (16),
   const_quest_min            NUMBER,
   const_quest_tolerance      NUMBER,
   const_quest_n_miss         NUMBER,
   estimate_expression        VARCHAR2 (32 BYTE),
   dur_mag_array              screen_dur_mag_array
);
/

CREATE TYPE screen_crit_array
/**
 * [description needed]
 *
 * @see type screen_crit_type
 * @see cwms_vt.store_screening_criteria
 */
IS TABLE OF screen_crit_type;
/

create type screening_control_t
/**
 * [description needed]
 *
 * @see cwms_vt.store_screening_criteria
 *
 * @member range_active_flag       [description needed]
 * @member rate_change_active_flag [description needed]
 * @member const_active_flag       [description needed]
 * @member dur_mag_active_flag     [description needed]
 */
AS OBJECT (
   range_active_flag         VARCHAR2 (1),
   rate_change_active_flag   VARCHAR2 (1),
   const_active_flag         VARCHAR2 (1),
   dur_mag_active_flag       VARCHAR2 (1)
);
/

create type cwms_ts_id_t
/**
 * Type for holding a CWMS time series identifier
 *
 * @see cwms_ts_id_array
 *
 * @member cwms_ts_id the time series identifier
 */
AS OBJECT (
   cwms_ts_id   VARCHAR2 (183)
);
/

create type cwms_ts_id_array
/**
 * Type for holding multiple CWMS time series identifiers
 *
 * @see cwms_ts_id_t
 */
IS TABLE OF cwms_ts_id_t;
/


-------------------------------------------------
-- Types coresponding to CWMS_CAT record types --
-- so JPublisher stays happy                   --
-------------------------------------------------

-- not documented
CREATE TYPE cat_ts_obj_t AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2 (183),
   interval_utc_offset   NUMBER
);
/


-- not documented
CREATE TYPE cat_ts_otab_t AS TABLE OF cat_ts_obj_t;
/


-- not documented
CREATE TYPE cat_ts_cwms_20_obj_t AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2 (183),
   interval_utc_offset   NUMBER (10),
   user_privileges       NUMBER,
   inactive              NUMBER,
   lrts_timezone         VARCHAR2 (28)
);
/


-- not documented
CREATE TYPE cat_ts_cwms_20_otab_t AS TABLE OF cat_ts_cwms_20_obj_t;
/


-- not documented
CREATE TYPE cat_loc_obj_t AS OBJECT (
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
/


-- not documented
CREATE TYPE cat_loc_otab_t AS TABLE OF cat_loc_obj_t;
/


-- not documented
CREATE TYPE cat_location_obj_t AS OBJECT (
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
/


-- not documented
CREATE TYPE cat_location_otab_t AS TABLE OF cat_location_obj_t;
/


-- not documented
CREATE TYPE cat_location2_obj_t AS OBJECT (
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
/


-- not documented
CREATE TYPE cat_location2_otab_t AS TABLE OF cat_location2_obj_t;
/


-- not documented
CREATE TYPE cat_location_kind_obj_t AS OBJECT (
   office_id        VARCHAR2(16),
   location_kind_id VARCHAR2(32),
   description      VARCHAR2(256)
);
/


-- not documented
CREATE TYPE cat_location_kind_otab_t AS TABLE OF cat_location_kind_obj_t;
/


-- not documented
CREATE TYPE cat_loc_alias_obj_t AS OBJECT (
   office_id   VARCHAR2 (16),
   cwms_id     VARCHAR2 (16),
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/


-- not documented
CREATE TYPE cat_loc_alias_otab_t AS TABLE OF cat_loc_alias_obj_t;
/


-- not documented
CREATE TYPE cat_param_obj_t AS OBJECT (
   parameter_id        VARCHAR2 (16),
   param_long_name     VARCHAR2 (80),
   param_description   VARCHAR2 (160),
   unit_id             VARCHAR2 (16),
   unit_long_name      VARCHAR2 (80),
   unit_description    VARCHAR2 (80)
);
/


-- not documented
CREATE TYPE cat_param_otab_t AS TABLE OF cat_param_obj_t;
/


-- not documented
CREATE TYPE cat_sub_param_obj_t AS OBJECT (
   parameter_id      VARCHAR2 (16),
   subparameter_id   VARCHAR2 (32),
   description       VARCHAR2 (80)
);
/


-- not documented
CREATE TYPE cat_sub_param_otab_t AS TABLE OF cat_sub_param_obj_t;
/


-- not documented
CREATE TYPE cat_sub_loc_obj_t AS OBJECT (
   sublocation_id   VARCHAR2 (32),
   description      VARCHAR2 (80)
);
/


-- not documented
CREATE TYPE cat_sub_loc_otab_t AS TABLE OF cat_sub_loc_obj_t;
/


-- not documented
CREATE TYPE cat_state_obj_t AS OBJECT (
   state_initial   VARCHAR2 (2),
   state_name      VARCHAR2 (40)
);
/


-- not documented
CREATE TYPE cat_state_otab_t AS TABLE OF cat_state_obj_t;
/


-- not documented
CREATE TYPE cat_county_obj_t AS OBJECT (
   county_id       VARCHAR2 (3),
   county_name     VARCHAR2 (40),
   state_initial   VARCHAR2 (2)
);
/


-- not documented
CREATE TYPE cat_county_otab_t AS TABLE OF cat_county_obj_t;
/


-- not documented
CREATE TYPE cat_timezone_obj_t AS OBJECT (
   timezone_name   VARCHAR2 (28),
   utc_offset      INTERVAL DAY (2)TO SECOND (6),
   dst_offset      INTERVAL DAY (2)TO SECOND (6)
);
/


-- not documented
CREATE TYPE cat_timezone_otab_t AS TABLE OF cat_timezone_obj_t;
/


-- not documented
CREATE TYPE cat_dss_file_obj_t AS OBJECT (
   office_id         VARCHAR2 (16),
   dss_filemgr_url   VARCHAR2 (32),
   dss_file_name     NUMBER (10)
);
/


-- not documented
CREATE TYPE cat_dss_file_otab_t AS TABLE OF cat_dss_file_obj_t;
/


-- not documented
CREATE TYPE cat_dss_xchg_set_obj_t AS OBJECT (
   office_id                  VARCHAR2 (16),
   dss_xchg_set_id            VARCHAR (32),
   dss_xchg_set_description   VARCHAR (80),
   dss_filemgr_url            VARCHAR2 (32),
   dss_file_name              VARCHAR2 (255),
   dss_xchg_direction_id      VARCHAR2 (16),
   dss_xchg_last_update       TIMESTAMP ( 6 )
);
/


-- not documented
CREATE TYPE cat_dss_xchg_set_otab_t AS TABLE OF cat_dss_xchg_set_obj_t;
/


-- not documented
CREATE TYPE cat_dss_xchg_ts_map_obj_t AS OBJECT (
   office_id               VARCHAR2 (16),
   cwms_ts_id              VARCHAR2 (183),
   dss_pathname            VARCHAR2 (391),
   dss_parameter_type_id   VARCHAR2 (8),
   dss_unit_id             VARCHAR2 (16),
   dss_timezone_name       VARCHAR2 (28),
   dss_tz_usage_id         VARCHAR2 (8)
);
/


-- not documented
CREATE TYPE cat_dss_xchg_tsmap_otab_t AS TABLE OF cat_dss_xchg_ts_map_obj_t;
/

create type screen_assign_t
/**
 * [description needed]
 *
 * @see type screen_assign_array
 *
 * @member cwms_ts_id      [description needed]
 * @member active_flag     [description needed]
 * @member resultant_ts_id [description needed]
 */
AS OBJECT (
   cwms_ts_id        VARCHAR2 (183),
   active_flag       VARCHAR2 (1),
   resultant_ts_id   VARCHAR2 (183)
);
/

create type screen_assign_array
/**
 * [description needed]
 *
 * @see type screen_assign_t
 * @see cwms_vt.assign_screening_id
 */
IS TABLE OF screen_assign_t;
/

create type loc_alias_type
/**
 * Holds basic information about a location alias.  This information doesn't
 * contain any context for the alias.
 *
 * @see type_loc_alias_array
 * @see type loc_alias_type2
 * @see type loc_alias_type3
 *
 * @member location_id  the location identifier
 * @member loc_alias_id the alias for the location
 */
AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_alias_id   VARCHAR2 (128)
);
/

create type loc_alias_array
/**
 * Holds basic information about a collection of location aliases.  This information
 * doesn't contain any context for the aliases.
 *
 * @see type_loc_alias_type
 * @see type loc_alias_array2
 * @see type loc_alias_array3
 * @see cwms_loc.assign_loc_groups
 */
IS TABLE OF loc_alias_type;
/


create type loc_alias_type2
/**
 * Holds intermediate information about a location alias.  This information doesn't
 * contain any context for the alias.
 *
 * @see type_loc_alias_array2
 * @see type loc_alias_type
 * @see type loc_alias_type3
 *
 * @member location_id   the location identifier
 * @member loc_attribute a numeric attribute associated with the location and alias.
 *         This can be used for sorting locations within a location group or other
 *         user-defined purposes.
 * @member loc_alias_id  the alias for the location
 */
AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_attribute  NUMBER,
   loc_alias_id   VARCHAR2 (128)
);
/

create type loc_alias_array2
/**
 * Holds intermediate information about a collection of location aliases.  This
 * information doesn't contain any context for the aliases.
 *
 * @see type_loc_alias_type2
 * @see type loc_alias_array
 * @see type loc_alias_array3
 * @see cwms_loc.assign_loc_groups2
 */
IS TABLE OF loc_alias_type2;
/


create type loc_alias_type3
/**
 * Holds detailed information about a location alias.  This information doesn't
 * contain any context for the alias.
 *
 * @see type_loc_alias_array3
 * @see type loc_alias_type2
 * @see type loc_alias_type3
 *
 * @member location_id   the location identifier
 * @member loc_attribute a numeric attribute associated with the location and alias.
 *         This can be used for sorting locations within a location group or other
 *         user-defined purposes.
 * @member loc_alias_id  the alias for the location
 * @member loc_ref_id    the location identifier of a referenced location
 */
AS OBJECT (
   location_id    VARCHAR2 (49),
   loc_attribute  NUMBER,
   loc_alias_id   VARCHAR2 (128),
   loc_ref_id     VARCHAR2 (49)
);
/

create type loc_alias_array3
/**
 * Holds detailed information about a collection of location aliases.  This
 * information doesn't contain any context for the aliases.
 *
 * @see type_loc_alias_type3
 * @see type loc_alias_array2
 * @see type loc_alias_array3
 * @see cwms_loc.assign_loc_groups3
 */
IS TABLE OF loc_alias_type3;
/


create type group_type
/**
 * Holds basic information about location groups
 *
 * @see type group_type2
 * @see type group_array
 *
 * @member group_id   the location group identifier
 * @member group_desc a description of the location group
 */
AS OBJECT (
   GROUP_ID     VARCHAR2 (32),
   group_desc   VARCHAR2 (128)
);
/

create type group_array
/**
 * Holds basic information about a collection of location groups
 *
 * @see type group_type
 * @see type group_array2
 * @see cwms_loc.assign_loc_grps_cat
 */
IS TABLE OF group_type;
/


create type group_type2
/**
 * Holds detailed information about location groups.
 *
 * @see type group_type
 * @see type group_array2
 *
 * @member group_id          the location group identifier
 * @member group_desc        a description of the location group
 * @member shared_alias_id   a location alias shared by all members of the
 *         location group
 * @member shared_loc_ref_id the location identifier for a referenced location
 *         shared by all members of the location group
 */
AS OBJECT (
   GROUP_ID          VARCHAR2 (32),
   group_desc        VARCHAR2 (128),
   shared_alias_id   VARCHAR2 (128),
   shared_loc_ref_id VARCHAR2 (49)
);
/

create type group_array2
/**
 * Holds basic information about a collection of location groups
 *
 * @see type group_type2
 * @see type group_array
 * @see cwms_loc.assign_loc_grps_cat2
 */
IS TABLE OF group_type2;
/

create type group_cat_t
/**
 * Holds the name of a location group within a specific location category
 *
 * @see group_cat_tab_t
 *
 * @member loc_category_id the location category identifier (parent of location group)
 * @member loc_group_id    the location group identifier (child of location category)
 */
AS OBJECT (
   loc_category_id   VARCHAR2 (32),
   loc_group_id      VARCHAR2 (32)
);
/

create type group_cat_tab_t
/**
 * Holds a collection of location group names within specific location categories
 *
 * @see group_cat_t
 * @see cwms_loc.num_group_assigned_to_shef
 */
IS TABLE OF group_cat_t;
/

create type ts_alias_t
/**
 * Holds information about a time series alias.  This information doesn't contain
 * any context for the alias.
 *
 * @see ts_alias_tab_t
 *
 * @member ts_id        the time series identifier
 * @member ts_attribute a numeric attribute associated with the time series and alias.
 *         This can be used for sorting time series within a time series group or other
 *         user-defined purposes.
 * @member ts_alias_id  the alias for the time series
 * @member ts_ref_id    the time series identifier of a referenced time series
 */
AS OBJECT (
   ts_id         VARCHAR2 (183),
   ts_attribute  NUMBER,
   ts_alias_id   VARCHAR2 (256),
   ts_ref_id     VARCHAR2 (183)
);
/

create type ts_alias_tab_t
/**
 * Holds information about a collection of time series aliases.  This information
 * doesn't contain any context for the aliases.
 *
 * @see ts_alias_t
 * @see cwms_ts.assign_ts_groups
 */
IS TABLE OF ts_alias_t;
/

/*
create type TS_GROUP_T AS OBJECT (
   GROUP_ID          VARCHAR2 (32),
   group_desc        VARCHAR2 (128),
   shared_alias_id   VARCHAR2 (256),
   shared_loc_ref_id VARCHAR2 (183)
);
/


create type TS_GROUP_TAB_T IS TABLE OF ts_group_t;
/

create type ts_group_cat_t AS OBJECT (
   ts_category_id   VARCHAR2 (32),
   ts_group_id      VARCHAR2 (32)
);
/

create type ts_group_cat_tab_t IS TABLE OF ts_group_cat_t;
/
*/

create type str_tab_t
/**
 * Holds a collection of strings
 *
 * @see type str_tab_tab_t
 */
is table of varchar2(32767);
/

create type str_tab_tab_t
/**
 * Holds a collection of string collections
 *
 * @see type str_tab_t
 */
is table of str_tab_t;
/

create type number_tab_t
/**
 * Holds a collection of integer or floating point numeric values
 *
 * @see type double_tab_t
 */
is table of number;
/

create type double_tab_t
/**
 * Holds a collection of floating point numeric values in IEEE-754 format
 *
 * @see type double_tab_tab_t
 * @see type number_tab_t
 */
is table of binary_double;
/

create type double_tab_tab_t
/**
 * Holds a collection of collections of floating point numeric values in IEEE-754 format
 *
 * @see type double_tab_t
 */
is table of double_tab_t;
/

create type log_message_properties_t
/**
 * Holds a single property for a database log message
 *
 * @see type log_message_props_tab_t
 *
 * @member msg_id     the unique message identifier
 * @member prop_name  the name of the property
 * @member prop_type  the property type
 * @member prop_value the property value, if numeric
 * @member prop_text  the property value, if text
 */
as object (
   msg_id     varchar2(32),
   prop_name  varchar2(64),
   prop_type  number(1),
   prop_value number,
   prop_text  varchar2(4000)
);
/


create type log_message_props_tab_t
/**
 * Holds a collection of message properites for a database log message
 *
 * @see type log_message_properties_t
 * @see cwms_msg.parse_log_msg_prop_tab
 */
as table of log_message_properties_t;
/

create type location_ref_t
/**
 * Object type representing a location reference.
 *
 * @member base_location_id specifies the base location portion
 *
 * @member sub_location_id specifies the sub-location portion
 *
 * @member office_id specifies the office which owns the referenced location
 *
 * @see type location_obj_t
 * @see type location_ref_tab_t
 */
is object(
   base_location_id varchar2(16),
   sub_location_id  varchar2(32),
   office_id        varchar2(16),
   /**
    * Constructs an instance from separate location and office identifiers
    *
    * @param p_location_id the location identifier
    * @param p_office_id   the office that owns the location.  If <code><big>NULL</big></code>
    *        the session user's office is used.
    *
    * @throws INVALID_OFFICE_ID if <code><big>p_office_id</big></code>
    *         contains an invalid office identifier.
    */
   constructor function location_ref_t (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   return self as result,
   /**
    * Constructs an instance from a combined office/location identifier
    *
    * @param p_office_and_location_id the combined identifier in the form
    *        office_id<code><big>'/'</big></code>location_id. If the office
    *        identifier portion isomitted (with or without the <code><big>'/'</big></code>),
    *        the the session user's default office is used.
    *
    * @throws INVALID_OFFICE_ID if <code><big>p_office_and_location_id</big></code>
    *         contains an invalid office identifier.
    */
   constructor function location_ref_t (
      p_office_and_location_id in varchar2) -- office-id/location-id
   return self as result,
   /**
    * Constructs an instance from a database location code
    *
    * @param p_location_code the database location code
    *
    * @throws NO_DATA_FOUND if <code><big>p_location_code</big></code> is
    *         not a valid location code.
    */
   constructor function location_ref_t (
      p_location_code in number)
   return self as result,
   /**
    * Returns the database location code for the instance, optionally creating
    * it first if it doesn't already exist
    *
    * @param p_create_if_necessary specifies whether to create the location
    *        code if it doesn't already exist in the database. Valid values
    *        are <code><big>'T'</big></code> and <code><big>'F'</big></code>.
    *
    * @return the database location code for the instance
    *
    * @throws NO_DATA_FOUND if <code><big>p_create_if_necessary</big></code> is
    *         <code><big>'F'</big></code> and the location code does not already
    *         exist in the database.
    */
   member function get_location_code(
      p_create_if_necessary in varchar2 default 'F')
   return number,
   /**
    * Returns the location identifer of the instance
    *
    * @return the location identifier of the instance
    */
   member function get_location_id
   return varchar2,
   /**
    * Returns the office identifer of the instance
    *
    * @return the office code of the instance
    */
   member function get_office_code
   return number,
   /**
    * Returns the office identifer of the instance
    *
    * @return the office identifier of the instance
    */
   member function get_office_id
   return varchar2,
   /**
    * Retrieves the office and location codes of the instance, optionally creating
    * the location code if it doesn't already exist
    *
    * @param p_location_code receives the location code
    * @param p_office_code receives the office code
    * @param p_create_if_necessary specifies whether to create the location
    *        code if it doesn't already exist in the database. Valid values
    *        are <code><big>'T'</big></code> and <code><big>'F'</big></code>.
    *
    * @throws NO_DATA_FOUND if <code><big>p_create_if_necessary</big></code> is
    *         <code><big>'F'</big></code> and the location code does not already
    *         exist in the database.
    */
   member procedure get_codes(
      p_location_code       out number,
      p_office_code         out number,
      p_create_if_necessary in  varchar2 default 'F'),
   /**
    * Creates a location in the database from the instance
    *
    * @param p_fail_if_exists specifies whether the method should return silently
    *        or raise an exception if the location already exists in the database.
    *        Valid values are <code><big>'T'</big></code> and <code><big>'F'</big></code>.
    *
    * @throws LOCATION_ID_ALREADY_EXISTS if <code><big>p_fail_if_exists</big></code>
    *         is <code><big>'T'</big></code> and the location already exists in
    *         the database.
    */
   member procedure create_location(
      p_fail_if_exists in varchar2)
);
/

create type body location_ref_t
as
   constructor function location_ref_t (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   return self as result
   is
   begin
      cwms_util.check_inputs(str_tab_t(p_location_id, p_office_id));
      base_location_id := cwms_util.get_base_id(p_location_id);
      sub_location_id  := cwms_util.get_sub_id(p_location_id);
      office_id        := cwms_util.get_db_office_id(p_office_id);
      return;
   end location_ref_t;

   constructor function location_ref_t (
      p_office_and_location_id in varchar2)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_office_and_location_id, '/', 1);
      if l_parts.count = 2 then
         base_location_id := cwms_util.get_base_id(trim(l_parts(2)));
         sub_location_id  := cwms_util.get_sub_id(trim(l_parts(2)));
         office_id        := cwms_util.get_db_office_id(l_parts(1));
      else
         base_location_id := cwms_util.get_base_id(trim(l_parts(1)));
         sub_location_id  := cwms_util.get_sub_id(trim(l_parts(1)));
         office_id        := cwms_util.user_office_id;
      end if;
      return;
   end location_ref_t;

   constructor function location_ref_t (
      p_location_code in number)
   return self as result
   is
   begin
      select bl.base_location_id,
             pl.sub_location_id,
             o.office_id
        into self.base_location_id,
             self.sub_location_id,
             self.office_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      return;
   end location_ref_t;

   member function get_location_code(
      p_create_if_necessary in varchar2 default 'F')
   return number
   is
      l_location_code number(10);
   begin
      if cwms_util.is_true(p_create_if_necessary) then
         declare
            LOCATION_ID_ALREADY_EXISTS exception; pragma exception_init (LOCATION_ID_ALREADY_EXISTS, -20026);
         begin
            cwms_loc.create_location2(
               p_location_id => base_location_id
                  || substr('-', 1, length(sub_location_id))
                  || sub_location_id,
               p_db_office_id => office_id);
         exception
            when LOCATION_ID_ALREADY_EXISTS then
               null;
         end;
      end if;
      select pl.location_code
        into l_location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = self.get_office_id
         and bl.db_office_code = o.office_code
         and bl.base_location_id = self.base_location_id
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, '.') = nvl(self.sub_location_id, '.');
      return l_location_code;
   end get_location_code;

   member function get_location_id
   return varchar2
   is
      l_location_id varchar2(49);
   begin
      l_location_id := self.base_location_id
        || SUBSTR ('-', 1, LENGTH (self.sub_location_id))
        || self.sub_location_id;
      return l_location_id;
   end get_location_id;

   member function get_office_code
   return number
   is
      l_office_code number(10);
   begin
      select office_code
        into l_office_code
        from cwms_office
       where office_id = self.get_office_id;
      return l_office_code;
   end get_office_code;

   member function get_office_id
   return varchar2
   is
   begin
      return office_id;
   end;

   member procedure get_codes(
      p_location_code       out number,
      p_office_code         out number,
      p_create_if_necessary in  varchar2 default 'F')
   is
   begin
      if cwms_util.is_true(p_create_if_necessary) then
         create_location(p_fail_if_exists => 'F');
      end if;
      select pl.location_code,
             o.office_code
        into p_location_code,
             p_office_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = self.get_office_id
         and bl.db_office_code = o.office_code
         and bl.base_location_id = self.base_location_id
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, '.') = nvl(self.sub_location_id, '.');
      return;
   end get_codes;

   member procedure create_location(
      p_fail_if_exists in varchar2)
   is
      LOCATION_ID_ALREADY_EXISTS exception; pragma exception_init (LOCATION_ID_ALREADY_EXISTS, -20026);
   begin
      cwms_loc.create_location2(
         p_location_id => base_location_id
            || substr('-', 1, length(sub_location_id))
            || sub_location_id,
         p_db_office_id => office_id);
   exception
      when LOCATION_ID_ALREADY_EXISTS then
         if cwms_util.is_true(p_fail_if_exists) then
            raise;
         else
            null;
         end if;
   end create_location;

end;
/
show errors;

create type location_ref_tab_t
/**
 * Holds a collection of location references.
 *
 * @see type location_ref_t
 */
is table of location_ref_t;
/


create type location_obj_t
/**
 * Holds information about at CWMS location
 *
 * @see type location_ref_t
 *
 * @member location_ref         the <a href=type_location_ref_t.html>location reference</a>
 * @member state_initial        State encompassing location
 * @member county_name          County encompassing location
 * @member time_zone_name       Location's local time zone
 * @member location_type        User-defined type for location
 * @member latitude             Actual latitude of location
 * @member longitude            Actual longitude of location
 * @member horizontal_datum     Datum used for actual latitude and longitude
 * @member elevation            Elevation of location
 * @member elev_unit_id         Unit of elevation
 * @member vertical_datum       Datum used for elevation
 * @member public_name          Public name for location
 * @member long_name            Long name for location
 * @member description          Description of location
 * @member active_flag          Flag (<code><big>'T'</big></code> or <code><big>'F'</big></code> specifying whether the location is marked as active
 * @member location_kind_id     The geographic type of the location
 * @member map_label            Label to be used on maps for location
 * @member published_latitude   Published latitude of location
 * @member published_longitude  Published longitude of location
 * @member bounding_office_id   Office whose boundary encompasses location
 * @member nation_id            Nation encompassing location
 * @member nearest_city         City nearest to location
 */
as object
(
   location_ref         location_ref_t,
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
   bounding_office_name varchar2(32),
   nation_id            varchar2(48),
   nearest_city         varchar2(50),
   /**
    * Constructs a location_obj_t from a <a href=type_location_ref_t.html>location_ref_t</a>.
    * All other fields are undefined.
    *
    * @param p_location_ref the <a href=type_location_ref_t.html>location_ref_t</a> object
    */
   constructor function location_obj_t(
      p_location_ref in location_ref_t)
      return self as result,
   /**
    * Construction a location_obj_t from a location in the datbase
    *
    * @param p_location_code the database location code
    */
   constructor function location_obj_t(
      p_location_code in number)
      return self as result,
   -- undocumented
   member procedure init(
      p_location_code in number)
             
);
/

create type body location_obj_t as

   constructor function location_obj_t(
      p_location_ref in location_ref_t)
      return self as result
   is
   begin
      begin
         self.init(p_location_ref.get_location_code);
      exception
         when no_data_found then
            self.location_ref := p_location_ref;
      end;
      return;
   end;
   
   constructor function location_obj_t(
      p_location_code in number)
      return self as result
   is
   begin
      self.init(p_location_code);
      return;
   end;      

   member procedure init(
      p_location_code in number)
   is
   begin
      for rec in 
         (  select l.location_code,
                   l.base_location_id,
                   l.sub_location_id,
                   s.state_initial,
                   s.county_name,
                   tz.time_zone_name,
                   l.location_type,
                   l.latitude,
                   l.longitude,
                   l.horizontal_datum,
                   l.elevation,
                   l.vertical_datum,
                   l.public_name,
                   l.long_name,
                   l.description,
                   l.active_flag,
                   lk.location_kind_id,
                   l.map_label,
                   l.published_latitude,
                   l.published_longitude,
                   o.office_id as bounding_office_id,
                   o.public_name as bounding_office_name,
                   n.nation_id,
                   l.nearest_city
              from ( select pl.location_code,
                            bl.base_location_id,
                            pl.sub_location_id,
                            pl.time_zone_code,
                            pl.county_code,
                            pl.location_type,
                            pl.elevation,
                            pl.vertical_datum,
                            pl.longitude,
                            pl.latitude,
                            pl.horizontal_datum,
                            pl.public_name,
                            pl.long_name,
                            pl.description,
                            pl.active_flag,
                            pl.location_kind,
                            pl.map_label,
                            pl.published_latitude,
                            pl.published_longitude,
                            pl.office_code,
                            pl.nation_code,
                            pl.nearest_city                
                       from at_physical_location pl,
                            at_base_location     bl
                      where bl.base_location_code = pl.base_location_code
                        and pl.location_code = p_location_code
                   ) l
                   left outer join
                   ( select county_code,
                            county_name,
                            state_initial
                       from cwms_county,
                            cwms_state
                      where cwms_state.state_code = cwms_county.state_code
                   ) s on s.county_code = l.county_code
                   left outer join cwms_time_zone   tz on tz.time_zone_code = l.time_zone_code
                   left outer join at_location_kind lk on lk.location_kind_code = l.location_kind
                   left outer join cwms_office      o  on o.office_code = l.office_code
                   left outer join cwms_nation      n  on n.nation_code = l.nation_code
         )   
      loop
         self.location_ref         := location_ref_t(p_location_code);
         self.state_initial        := rec.state_initial;
         self.county_name          := rec.county_name;
         self.time_zone_name       := rec.time_zone_name;
         self.location_type        := rec.location_type;
         self.latitude             := rec.latitude;
         self.longitude            := rec.longitude;
         self.horizontal_datum     := rec.horizontal_datum;
         self.elevation            := rec.elevation;
         self.elev_unit_id         := 'm';
         self.vertical_datum       := rec.vertical_datum;
         self.public_name          := rec.public_name;
         self.long_name            := rec.long_name;
         self.description          := rec.description;
         self.active_flag          := rec.active_flag;
         self.location_kind_id     := rec.location_kind_id;
         self.map_label            := rec.map_label;
         self.published_latitude   := rec.published_latitude;
         self.published_longitude  := rec.published_longitude;
         self.bounding_office_id   := rec.bounding_office_id;
         self.bounding_office_name := rec.bounding_office_name;
         self.nation_id            := rec.nation_id;
         self.nearest_city         := rec.nearest_city;
      end loop;
   end;      
      
end;
/
show errors;

create type specified_level_t
/**
 * Holds information about a specified level.  Specified levels are named levels
 * that can be associated with combinations of locations, parameters, and durations.
 *
 * @see type specified_level_tab_t
 *
 * @member office_id   The office owning the specified level
 * @member level_id    The specified level identifier
 * @member description A description of the specified level
 */
is object(
   office_id   varchar2(16),
   level_id    varchar2(256),
   description varchar2(256),
   /**
    * Constructs a specified_level_t object from an office code and level id
    *
    * @param p_office_code a unique numeric value identifying the office that owns the specified level.
    * @param p_level_id    the specified level identifier
    * @param p_description an optional description of the specified level
    */
   constructor function specified_level_t(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2 default null)
      return self as result,
   /**
    * Constructs a specified_level_t object from information stored in the database
    *
    * @param p_level_code a unique numeric value identifying the specified level in the database
    */
   constructor function specified_level_t(
      p_level_code number)
      return self as result,
   -- undocumented
   member procedure init(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2),
   /**
    * Stores the specified level information to the database
    */
   member procedure store
);
/


create type body specified_level_t
as
   constructor function specified_level_t(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2 default null)
      return self as result
   is
   begin
      init(p_office_code, p_level_id, p_description);
      return;
   end specified_level_t;

   constructor function specified_level_t(
      p_level_code number)
      return self as result
   is
      l_level_id    varchar2(256);
      l_description varchar2(256);
   begin
      select specified_level_id,
             description
        into l_level_id,
             l_description
        from at_specified_level
       where specified_level_code = p_level_code;

      init(p_level_code, l_level_id, l_description);
      return;
   end specified_level_t;

   member procedure init(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2)
   is
   begin
      select office_id
        into office_id
        from cwms_office
       where office_code = p_office_code;

      level_id    := p_level_id;
      description := p_description;
   end init;

   member procedure store
   is
   begin
      cwms_level.store_specified_level(level_id, description, 'F', office_id);
   end store;
end;
/
show errors;
create type specified_level_tab_t
/**
 * Holds a collection of specified levels
 *
 * @see type specified_level_t
 */
is table of specified_level_t;
/

create type loc_lvl_indicator_cond_t
/**
 * Holds information about a location level indicator condition.  A location level
 * indicator condition is a condition that must evalutate to TRUE for the encompassing
 * indicator to be set. The condition may be an absolute magnitude conition or a
 * rate of change condition. If the condition is a rate of change condition, the
 * absolute magnitude portion is treated as a preliminary test to determine whether
 * the rate of change should be evaluated.  In this case a condition may evalutate
 * to FALSE even if the rate of change portion would evaluate to TRUE because the
 * preliminary test (absolute magnitued portion) evaluated to FALSE. <bold>Do not use
 * the default constructor to create objects of this type since several transient
 * fields need to be computed from specified values.</bold>
 *
 * @see type loc_lvl_ind_cond_tab_t
 *
 * @member indicator_value            The value (1..5) of the indicator
 * @member expression                 A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two absolute magnitude values.
 * @member comparison_operator_1      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the first comparison value
 * @member comparison_value_1         The first (required) comparison value used to compare with the expression
 * @member comparison_unit            The unit of the comparison value(s)
 * @member connector                  The logical operator (AND, OR) used to connect the first and second comparisons if two comparisons are used
 * @member comparison_operator_2      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the second comparison value if two comparisons are used
 * @member comparison_value_2         The second (optional) comparison value used to compare with the expression
 * @member rate_expression            A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two rate-of-change values. Optional. Only evaluated if the absolute magnitude comparison(s) evaluate(s) to true
 * @member rate_comparison_operator_1 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the first rate comparison value
 * @member rate_comparison_value_1    The first comparison value used to compare with the rate expression. Required if a rate expression is used.
 * @member rate_comparison_unit       The unit of the rate comparison value(s)
 * @member rate_connector             The logical operator (AND, OR) used to connect the first and second rate comparisons if two rate comparisons are used
 * @member rate_comparison_operator_2 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the second rate comparison value if two rate comparisons are used
 * @member rate_comparison_value_2    The second comparison value used to compare with the rate expression if two rate comparisons are used
 * @member rate_interval              The time interval used in computing the rate of change
 * @member description                A description of the location level indicator
 * @member factor                     The unit conversion factor for absolute magnitude comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member offset                     The unit conversion offset for absolute magnitude comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member rate_factor                The unit conversion factor for rate of change comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member rate_offset                The unit conversion offset for rate of change comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member interval_factor            A conversion factor to convert from data interval to the specified rate interval. <bold>Transient</bold>
 * @member uses_reference             A flag (T or F) that specifes whether the indicator references a second location level. <bold>Transient</bold>
 * @member expression_tokens          A tokenized version of the absolute magnitude expression. <bold>Transient</bold>
 * @member rate_expression_tokens     A tokenized version of the rate expression. <bold>Transient</bold>
 */
is object
(
   indicator_value            number(1),
   expression                 varchar2(64),
   comparison_operator_1      varchar2(2),
   comparison_value_1         binary_double,
   comparison_unit            number(10),
   connector                  varchar2(3),
   comparison_operator_2      varchar2(2),
   comparison_value_2         binary_double,
   rate_expression            varchar2(64),
   rate_comparison_operator_1 varchar2(2),
   rate_comparison_value_1    binary_double,
   rate_comparison_unit       number(10),
   rate_connector             varchar2(3),
   rate_comparison_operator_2 varchar2(2),
   rate_comparison_value_2    binary_double,
   rate_interval              interval day(3) to second(0),
   description                varchar2(256),
   factor                     binary_double,
   offset                     binary_double,
   rate_factor                binary_double,
   rate_offset                binary_double,
   interval_factor            binary_double,
   uses_reference             varchar2(1),
   expression_tokens          str_tab_t,
   rate_expression_tokens     str_tab_t,
   /**
    * Constructs a loc_lvl_indicator_cond_t object.  <bold>Use this constructor instead
    * of the default constructor when building an object from components</bold>.
    *
    * @param p_indicator_value            The value (1..5) of the indicator
    * @param p_expression                 A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two absolute magnitude values.
    * @param p_comparison_operator_1      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the first comparison value
    * @param p_comparison_value_1         The first (required) comparison value used to compare with the expression
    * @param p_comparison_unit            The unit of the comparison value(s)
    * @param p_connector                  The logical operator (AND, OR) used to connect the first and second comparisons if two comparisons are used
    * @param p_comparison_operator_2      The operator (LT, LE, EQ, NE, GE, GT) used to compare the expression the the second comparison value if two comparisons are used
    * @param p_comparison_value_2         The second (optional) comparison value used to compare with the expression
    * @param p_rate_expression            A mathematical expression (algebraic or RPN) that is evaluated and compared with one or two rate-of-change values. Optional. Only evaluated if the absolute magnitude comparison(s) evaluate(s) to true
    * @param p_rate_comparison_operator_1 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the first rate comparison value
    * @param p_rate_comparison_value_1    The first comparison value used to compare with the rate expression. Required if a rate expression is used.
    * @param p_rate_comparison_unit       The unit of the rate comparison value(s)
    * @param p_rate_connector             The logical operator (AND, OR) used to connect the first and second rate comparisons if two rate comparisons are used
    * @param p_rate_comparison_operator_2 The operator (LT, LE, EQ, NE, GE, GT) used to compare the rate expression the the second rate comparison value if two rate comparisons are used
    * @param p_rate_comparison_value_2    The second comparison value used to compare with the rate expression if two rate comparisons are used
    * @param p_rate_interval              The time interval used in computing the rate of change
    * @param p_description                A description of the location level indicator
    */
   constructor function loc_lvl_indicator_cond_t(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   return self as result,
   -- not documented
   constructor function loc_lvl_indicator_cond_t(
      p_row in urowid)
      return self as result,
   -- not documented
   member procedure init(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2),
   /**
    * Stores a loc_lvl_indicator_cont_t object to the AT_LOC_LEVL_INDICATOR_COND table
    */
   member procedure store(
      p_level_indicator_code in number),
   -----------------------------------------------------------------------------
   -- member fields factor and offset must previously be set to provide any
   -- necessary units conversion for the comparison
   --
   -- p_rate must be specified for the interval indicated in the member field
   -- rate_interval
   -----------------------------------------------------------------------------
   /**
    * Tests whether the specified parameters cause the location level indicator condition
    * to be set
    *
    * param p_value   The value (expression variable V) in the object's comparison unit,
    * param p_level   The level value (expression variable L or L1) in the object's comparison unit,
    * param p_level_2 The referenced level value (expression variable L2) in the object's comparison unit, if a referenced location level is used
    * param p_rate    The rate of change (expression variable R) in the object's rate comparison unit, if a rate expression is used
    *
    * return whether the specified parameters cause the location level indicator
    *        condition to be set
    */
   member function is_set(
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double,
      p_rate    in binary_double)
   return boolean
);
/
show errors;

create type body loc_lvl_indicator_cond_t
as
   constructor function loc_lvl_indicator_cond_t(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   return self as result
   is
   begin
      init(p_indicator_value,
           p_expression,
           p_comparison_operator_1,
           p_comparison_value_1,
           p_comparison_unit,
           p_connector,
           p_comparison_operator_2,
           p_comparison_value_2,
           p_rate_expression,
           p_rate_comparison_operator_1,
           p_rate_comparison_value_1,
           p_rate_comparison_unit,
           p_rate_connector,
           p_rate_comparison_operator_2,
           p_rate_comparison_value_2,
           p_rate_interval,
           p_description);
         return;
   end loc_lvl_indicator_cond_t;

   constructor function loc_lvl_indicator_cond_t(
      p_row in urowid)
      return self as result
   is
      l_rec at_loc_lvl_indicator_cond%rowtype;
   begin
      select *
        into l_rec
        from at_loc_lvl_indicator_cond
       where rowid = p_row;
      init(l_rec.level_indicator_value,
           l_rec.expression,
           l_rec.comparison_operator_1,
           l_rec.comparison_value_1,
           l_rec.comparison_unit,
           l_rec.connector,
           l_rec.comparison_operator_2,
           l_rec.comparison_value_2,
           l_rec.rate_expression,
           l_rec.rate_comparison_operator_1,
           l_rec.rate_comparison_value_1,
           l_rec.rate_comparison_unit,
           l_rec.rate_connector,
           l_rec.rate_comparison_operator_2,
           l_rec.rate_comparison_value_2,
           l_rec.rate_interval,
           l_rec.description);

      return;
   end loc_lvl_indicator_cond_t;


   member procedure init(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   is
      l_expression                 varchar2(128) := trim(upper(p_expression));
      l_comparison_operator_1      varchar2(2)   := trim(upper(p_comparison_operator_1));
      l_connector                  varchar2(3)   := trim(upper(p_connector));
      l_comparison_operator_2      varchar2(2)   := trim(upper(p_comparison_operator_2));
      l_rate_expression            varchar2(128) := trim(upper(p_rate_expression));
      l_rate_comparison_operator_1 varchar2(2)   := trim(upper(p_rate_comparison_operator_1));
      l_rate_connector             varchar2(3)   := trim(upper(p_rate_connector));
      l_rate_comparison_operator_2 varchar2(2)   := trim(upper(p_rate_comparison_operator_2));
      l_description                varchar2(256) := trim(p_description);

      function tokenize_expression(
         p_expr    in varchar2,
         p_is_rate in boolean)
      return str_tab_t
      is
         l_expr   varchar2(128) := p_expr;
         l_tokens str_tab_t;
      begin
         if p_expr is not null then
            ---------------------------------------------------------------
            -- replace V, L, L1, L2, R with ARG1, ARG2, ARG2, ARG3, ARG4 --
            ---------------------------------------------------------------
            if p_is_rate then
               if regexp_instr(p_expr, '(^|\(|[[:space:]])(-?)(V|L[12]?)([[:space:]]|\)|$)') > 0 then
                  cwms_err.raise('ERROR', 'Cannot reference variables V, L, L1, or L2 in rate expression');
               end if;
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)R([[:space:]]|\)|$)',   '\1\2ARG4\3');
            else
               if regexp_instr(p_expr, '(^|\(|[[:space:]])(-?)R([[:space:]]|\)|$)') > 0 then
                  cwms_err.raise('ERROR', 'Cannot reference variable R in non-rate expression');
               end if;
               l_expr := regexp_replace(p_expr, '(^|\(|[[:space:]])(-?)V([[:space:]]|\)|$)',   '\1\2ARG1\3');
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)L1?([[:space:]]|\)|$)', '\1\2ARG2\3');
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)L2([[:space:]]|\)|$)',  '\1\2ARG3\3');
            end if;
            -------------------------------
            -- tokenize algebraic or RPN --
            -------------------------------
            if instr(l_expr, '(') > 0 then
               l_tokens := cwms_util.tokenize_algebraic(l_expr);
            else
               l_tokens := cwms_util.tokenize_rpn(l_expr);
               if l_tokens.count > 1 and
                  l_tokens(l_tokens.count) not in
                  ('+','-','*','/','//','%','^','ABS','ACOS','ASIN','ATAN','CEIL',
                   'COS','EXP','FLOOR','LN','LOG', 'SIGN','SIN','TAN','TRUNC')
               then
                  l_tokens := cwms_util.tokenize_algebraic(l_expr);
               end if;
            end if;
         end if;
         return l_tokens;
      end;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_indicator_value not in (1,2,3,4,5) then
         cwms_err.raise(
            'INVALID_ITEM',
            p_indicator_value,
            'location level indicator value');
      end if;
      if l_expression is null then
         cwms_err.raise('ERROR', 'Comparison expression must be specified');
      end if;
      if regexp_instr(l_expression, '(^|\(|[[:space:]])-?R([[:space:]]|\)|$)') > 0 then
         cwms_err.raise('ERROR', 'Expression cannot reference rate variable R');
      end if;
      if l_expression is not null then
         if regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?V([[:space:]]|\)|$)') > 0 or
            regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?L1?([[:space:]]|\)|$)') > 0 or
            regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?L2([[:space:]]|\)|$)') > 0
         then
            cwms_err.raise('ERROR', 'Rate expression cannot reference non-rate variables V, L (or L1) and L2');
         end if;
      end if;
      if l_comparison_operator_1 not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_comparison_operator_1,
            'comparison operator');
      end if;
      if nvl(l_rate_comparison_operator_1, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_comparison_operator_1,
            'rate comparison operator');
      end if;
      if nvl(l_connector, 'AND') not in ('AND','OR') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_connector,
            'compound comparison connection operator');
      end if;
      if nvl(l_rate_connector, 'AND') not in ('AND','OR') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_connector,
            'compound rate comparison connection operator');
      end if;
      if nvl(l_comparison_operator_2, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_comparison_operator_2,
            'comparison operator');
      end if;
      if nvl(l_rate_comparison_operator_2, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_comparison_operator_2,
            'rate comparison operator');
      end if;
      if p_comparison_value_1 is null then
         cwms_err.raise('ERROR', 'Comparison value must be specified');
      end if;
      if p_connector             is null or
         p_comparison_operator_2 is null or
         p_comparison_value_2    is null
      then
         if p_connector             is not null or
            p_comparison_operator_2 is not null or
            p_comparison_value_2    is not null
         then
            cwms_err.raise(
               'ERROR',
               'Secondary comparison parameters must all be specified or all be null');
         end if;
      end if;
      if p_rate_connector             is null or
         p_rate_comparison_operator_2 is null or
         p_rate_comparison_value_2    is null
      then
         if p_rate_connector             is not null or
            p_rate_comparison_operator_2 is not null or
            p_rate_comparison_value_2    is not null
         then
            cwms_err.raise(
               'ERROR',
               'Secondary rate comparison parameters must all be specified or all be null');
         end if;
      end if;
      if p_comparison_unit is not null then
         declare
            l_code number(10);
         begin
            select unit_code
              into l_code
              from cwms_unit
             where unit_code = p_comparison_unit;
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_comparison_unit,
                  'CWMS unit code');
         end;
      end if;
      if p_rate_comparison_unit is not null then
         declare
            l_code number(10);
         begin
            select unit_code
              into l_code
              from cwms_unit
             where unit_code = p_rate_comparison_unit;
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_rate_comparison_unit,
                  'CWMS unit code');
         end;
      end if;
      --------------------
      -- set the values --
      --------------------
      indicator_value            := p_indicator_value;
      expression                 := l_expression;
      comparison_operator_1      := l_comparison_operator_1;
      comparison_value_1         := p_comparison_value_1;
      comparison_unit            := p_comparison_unit;
      connector                  := l_connector;
      comparison_operator_2      := l_comparison_operator_2;
      comparison_value_2         := p_comparison_value_2;
      rate_expression            := l_rate_expression;
      rate_comparison_operator_1 := l_rate_comparison_operator_1;
      rate_comparison_value_1    := p_rate_comparison_value_1;
      rate_comparison_unit       := p_rate_comparison_unit;
      rate_connector             := l_rate_connector;
      rate_comparison_operator_2 := l_rate_comparison_operator_2;
      rate_comparison_value_2    := p_rate_comparison_value_2;
      rate_interval              := p_rate_interval;
      description                := l_description;
      factor                     := 1.0;
      offset                     := 0.0;
      rate_factor                := 1.0;
      rate_offset                := 0.0;
      interval_factor            := 1.0;
      expression_tokens          := tokenize_expression(expression, false);
      rate_expression_tokens     := tokenize_expression(rate_expression, true);
      uses_reference :=
         case regexp_instr(expression, '(^|\(|[[:space:]])-?L2([[:space:]]|\)|$)') > 0
            when true  then 'T'
            when false then 'F'
         end;
   end init;


   member procedure store(
      p_level_indicator_code in number)
   is
   begin
      cwms_level.store_loc_lvl_indicator_cond(
         p_level_indicator_code,
         indicator_value,
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
         description,
         'F',
         'F');

   end store;

   -----------------------------------------------------------------------------
   -- member fields factor and offset must previously be set to provide any
   -- necessary units conversion for the comparison
   --
   -- p_rate must be specified for the interval indicated in the member field
   -- rate_interval
   -----------------------------------------------------------------------------
   member function is_set(
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double,
      p_rate    in binary_double)
   return boolean
   is
      l_result       binary_double;
      l_comparison_1 boolean;
      l_comparison_2 boolean;
      l_is_set       boolean;
      l_arguments    double_tab_t;
   begin
      -------------------------------------------------
      -- evaluate the expression with the parameters --
      -------------------------------------------------
      l_arguments := new double_tab_t();
      l_arguments.extend(4);
      l_arguments(1) :=  p_value   * factor + offset;
      l_arguments(2) :=  p_level   * factor + offset;
      l_arguments(3) :=  p_level_2 * factor + offset;
      l_arguments(4) := (p_rate    * rate_factor + rate_offset) * interval_factor;
      l_result := cwms_util.eval_tokenized_expression(expression_tokens, l_arguments);
      -----------------------------------
      -- evaluate the first comparison --
      -----------------------------------
      l_comparison_1 :=
         case comparison_operator_1
            when 'LT' then l_result  < comparison_value_1
            when 'LE' then l_result <= comparison_value_1
            when 'EQ' then l_result  = comparison_value_1
            when 'NE' then l_result != comparison_value_1
            when 'GE' then l_result >= comparison_value_1
            when 'GT' then l_result  > comparison_value_1
         end;
      -------------------------------------------------
      -- evaluate the second comparison if specified --
      -------------------------------------------------
      if connector is null then
         l_is_set := l_comparison_1;
      else
         l_comparison_2 :=
            case comparison_operator_2
               when 'LT' then l_result  < comparison_value_2
               when 'LE' then l_result <= comparison_value_2
               when 'EQ' then l_result  = comparison_value_2
               when 'NE' then l_result != comparison_value_2
               when 'GE' then l_result >= comparison_value_2
               when 'GT' then l_result  > comparison_value_2
            end;
         l_is_set :=
            case connector
               when 'AND' then l_comparison_1 and l_comparison_2
               when 'OR'  then l_comparison_1 or  l_comparison_2
            end;
      end if;
      ---------------------------------------------------
      -- evaluate the rate if a rate expression exists --
      ---------------------------------------------------
      if l_is_set and rate_expression_tokens is not null then
         l_result := cwms_util.eval_tokenized_expression(rate_expression_tokens, l_arguments);
         ----------------------------------------
         -- evaluate the first rate comparison --
         ----------------------------------------
         l_comparison_1 :=
            case rate_comparison_operator_1
               when 'LT' then l_result  < rate_comparison_value_1
               when 'LE' then l_result <= rate_comparison_value_1
               when 'EQ' then l_result  = rate_comparison_value_1
               when 'NE' then l_result != rate_comparison_value_1
               when 'GE' then l_result >= rate_comparison_value_1
               when 'GT' then l_result  > rate_comparison_value_1
            end;
         ------------------------------------------------------
         -- evaluate the second rate comparison if specified --
         ------------------------------------------------------
         if rate_connector is null then
            l_is_set := l_comparison_1;
         else
            l_comparison_2 :=
               case rate_comparison_operator_2
                  when 'LT' then l_result  < rate_comparison_value_2
                  when 'LE' then l_result <= rate_comparison_value_2
                  when 'EQ' then l_result  = rate_comparison_value_2
                  when 'NE' then l_result != rate_comparison_value_2
                  when 'GE' then l_result >= rate_comparison_value_2
                  when 'GT' then l_result  > rate_comparison_value_2
               end;
            l_is_set :=
               case rate_connector
                  when 'AND' then l_comparison_1 and l_comparison_2
                  when 'OR'  then l_comparison_1 or  l_comparison_2
               end;
         end if;
      end if;
      return l_is_set;
   end is_set;

end;
/
show errors;

create type loc_lvl_ind_cond_tab_t
/**
 * A collectiion of location level indicator conditions
 *
 * @see type loc_lvl_indicator_cond_t
 * @see type loc_lvl_indicator_t
 */
is table of loc_lvl_indicator_cond_t;
/
-- not documented
create type zloc_lvl_indicator_t is object
(
   level_indicator_code     number(10),
   location_code            number(10),
   specified_level_code     number(10),
   parameter_code           number(10),
   parameter_type_code      number(10),
   duration_code            number(10),
   attr_value               number,
   attr_parameter_code      number(10),
   attr_parameter_type_code number(10),
   attr_duration_code       number(10),
   ref_specified_level_code number(10),
   ref_attr_value           number,
   level_indicator_id       varchar2(32),
   minimum_duration         interval day to second,
   maximum_age              interval day to second,
   conditions               loc_lvl_ind_cond_tab_t,

   constructor function zloc_lvl_indicator_t
      return self as result,

   constructor function zloc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result,

   member procedure store
);
/
show errors;

create type body zloc_lvl_indicator_t
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
      l_level_indicator_code number(10);
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

      l_level_indicator_code := level_indicator_code;
      for rec in (select rowid
                    from at_loc_lvl_indicator_cond
                   where level_indicator_code = l_level_indicator_code
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
-- not documented
create type zloc_lvl_indicator_tab_t is table of zloc_lvl_indicator_t;
/

create type loc_lvl_indicator_t
/**
 * Holds a location level indiator.  A location level indicator indicates the status
 * of a time series of values with respect to a location level.  A location level
 * indicator may have up to five conditions, each with a unique level value in the
 * range (1..5), and multiple conditions may be set simultaneously (e.g. the conditions
 * need not be mutually exclusive).
 *
 * @see type loc_lvl_ind_cond_tab_t
 * @see type loc_lvl_indicator_tab_t
 *
 * @member office_id              The office that owns the location and specified level
 * @member location_id            The location portion of the location level indicator
 * @member parameter_id           The parameter portion of the location level indicator
 * @member parameter_type_id      The parameter type portion of the location level indicator
 * @member duration_id            The duration portion of the location level indicator
 * @member specified_level_id     The specified level portion of the location level indicator
 * @member level_indicator_id     The indicator portion of the location level indicator
 * @member attr_value             The attribute value of the location level, if any, in the specified unit
 * @member attr_units_id          The specified unit of the location level attribute, if any
 * @member attr_parameter_id      The parameter of the location level attribute, if any
 * @member attr_parameter_type_id The parameter type of the location level attribute, if any
 * @member attr_duration_id       The duration of the location level attribute, if any
 * @member ref_specified_level_id The specified level portion of the referenced location level, if any
 * @member ref_attr_value         The attribute value of the referenced location level, if any, in the specified unit
 * @member minimum_duration       The minimum amount of time a condition must continuously evalutate to TRUE for that condition to be considered to be set
 * @member maximum_age            The maximum age of the most current time series value for any conditions to be evalutated
 * @member conditions             The location level indicator conditions
 */
is object
(
   office_id              varchar2(16),
   location_id            varchar2(49),
   parameter_id           varchar2(49),
   parameter_type_id      varchar2(16),
   duration_id            varchar2(16),
   specified_level_id     varchar2(256),
   level_indicator_id     varchar2(32),
   attr_value             number,
   attr_units_id          varchar2(16),
   attr_parameter_id      varchar2(49),
   attr_parameter_type_id varchar2(16),
   attr_duration_id       varchar2(16),
   ref_specified_level_id varchar2(256),
   ref_attr_value         number,
   minimum_duration       interval day to second,
   maximum_age            interval day to second,
   conditions             loc_lvl_ind_cond_tab_t,
   -- not documented
   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result,
   -- not documented
   constructor function loc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result,
   -- not documented
   member procedure init(
      p_obj in zloc_lvl_indicator_t),
   -- not documented
   member function zloc_lvl_indicator
      return zloc_lvl_indicator_t,
   /**
    * Stores the loc_lvl_indicator_t object to the database
    */
   member procedure store,
   /**
    * Retrieves which indicator conditions are set, if any, for the specifed time
    * series values
    *
    * @see type ztsv_array
    * @see type number_tab_t
    *
    * @param p_ts        the time series to use in determining which indicator
    *                    conditions are set
    * @param p_eval_time the date/time to use in determining which indicator conditions
    *        are set.  If NULL, the current date/time is used.
    *
    * @return the condition values for each condition that is set. If no conditions are
    *         set, an empty collection (not NULL) is returned.
    */
   member function get_indicator_values(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number_tab_t,
   /**
    * Retrieves the maximum condition level that is set, if any, for the specified
    * time series values
    *
    * @see type ztsv_array
    *
    * @param p_ts        the time series to use in determining which indicator
    *                    conditions are set
    * @param p_eval_time the date/time to use in determining which indicator conditions
    *        are set.  If NULL, the current date/time is used.
    *
    * @return the maximum condition level that is set, if any, for the specified
    *         time series values. If no condition is set, 0 (zero) is returned.
    */
   member function get_max_indicator_value(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number,
   /**
    * Generates a time series of maximum set level conditions, if, any for the specified
    * time series.
    *
    * @see type ztsv_array
    *
    * @param p_ts         the time series to use in determining which indicator
    *                     conditions are set
    * @param p_start_time the earliest time for which to retrieve the maximum level
    *                     condition that is set
    *
    * @return a time series of the maximum set level conditions, if any. Each element
    *         of the returned time series has its fields set as:
    *         <dl>
    *           <dd>date_time</dd><dt>the time date_time field of the input time series</dt>
    *           <dd>value</dd><dt>the maximum location level condition that was set at that date/time, or 0 (zero) if none were set</dt>
    *           <dd>quality_code</dd><dt>Unused, always set to 0 (zero)</dt>
    *         </dl>
    */
   member function get_max_indicator_values(
      p_ts         in ztsv_array,
      p_start_time in date)
      return ztsv_array

);
/
show errors;

create type body loc_lvl_indicator_t
as
   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result
   is
   begin
      init(p_obj);
      return;
   end loc_lvl_indicator_t;

   constructor function loc_lvl_indicator_t(
      p_rowid in urowid)
      return self as result
   is
   begin
      init(zloc_lvl_indicator_t(p_rowid));
      return;
   end loc_lvl_indicator_t;

   member procedure init(
      p_obj in zloc_lvl_indicator_t)
   is
   begin
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into office_id,
             location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_obj.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;

      select bp.base_parameter_id
             || substr('-', 1, length(p.sub_parameter_id))
             || p.sub_parameter_id
        into parameter_id
        from at_parameter p,
             cwms_base_parameter bp
       where p.parameter_code = p_obj.parameter_code
         and bp.base_parameter_code = p.base_parameter_code;

      select parameter_type_id
        into parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = p_obj.parameter_type_code;

      select duration_id
        into duration_id
        from cwms_duration
       where duration_code = p_obj.duration_code;

      select specified_level_id
        into specified_level_id
        from at_specified_level
       where specified_level_code = p_obj.specified_level_code;

      if p_obj.attr_value is not null then
         select bp.base_parameter_id
                || substr('-', 1, length(p.sub_parameter_id))
                || p.sub_parameter_id,
                u.unit_id
           into attr_parameter_id,
                attr_units_id
           from at_parameter p,
                cwms_base_parameter bp,
                cwms_unit u
          where p.parameter_code = p_obj.attr_parameter_code
            and bp.base_parameter_code = p.base_parameter_code
            and u.unit_code = bp.unit_code;

         select parameter_type_id
           into attr_parameter_type_id
           from cwms_parameter_type
          where parameter_type_code = p_obj.attr_parameter_type_code;

         select duration_id
           into attr_duration_id
           from cwms_duration
          where duration_code = p_obj.attr_duration_code;
         attr_value := p_obj.attr_value;
      end if;

      if p_obj.ref_specified_level_code is not null then
         select specified_level_id
           into ref_specified_level_id
           from at_specified_level
          where specified_level_code = p_obj.ref_specified_level_code;
         ref_attr_value := p_obj.ref_attr_value;
      end if;

      level_indicator_id := p_obj.level_indicator_id;
      minimum_duration   := p_obj.minimum_duration;
      maximum_age        := p_obj.maximum_age;
      conditions         := p_obj.conditions;
   end init;

   member function zloc_lvl_indicator
      return zloc_lvl_indicator_t
   is
      l_parts       str_tab_t;
      l_obj         zloc_lvl_indicator_t := new zloc_lvl_indicator_t;
      l_sub_id      varchar2(48);
      l_id          varchar2(256);
      l_factor      binary_double;
      l_offset      binary_double;
   begin
      l_parts := cwms_util.split_text(location_id, '-', 1);
      l_sub_id := case l_parts.count
                     when 1 then null
                     else l_parts(2)
                  end;
      select pl.location_code
        into l_obj.location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where upper(o.office_id) = upper(self.office_id)
         and bl.db_office_code = o.office_code
         and upper(bl.base_location_id) = upper(l_parts(1))
         and pl.base_location_code = bl.base_location_code
         and upper(nvl(pl.sub_location_id, '@')) = upper(nvl(l_sub_id, '@'));

      l_parts := cwms_util.split_text(parameter_id, '-', 1);
      l_sub_id := case l_parts.count
                     when 1 then null
                     else l_parts(2)
                  end;
      select p.parameter_code
        into l_obj.parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(l_parts(1))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '@')) = upper(nvl(l_sub_id, '@'))
         and p.db_office_code in (cwms_util.get_db_office_code(self.office_id), cwms_util.db_office_code_all);

      l_id := parameter_type_id;
      select parameter_type_code
        into l_obj.parameter_type_code
        from cwms_parameter_type
       where upper(parameter_type_id) = upper(l_id);

      l_id := duration_id;
      select duration_code
        into l_obj.duration_code
        from cwms_duration
       where upper(duration_id) = upper(l_id);

      l_id := specified_level_id;
      select specified_level_code
        into l_obj.specified_level_code
        from at_specified_level
       where upper(specified_level_id) = upper(l_id);

      if attr_value is not null then
         l_parts := cwms_util.split_text(attr_parameter_id, '-', 1);
         l_sub_id := case l_parts.count
                        when 1 then null
                        else l_parts(2)
                     end;
         select p.parameter_code
           into l_obj.attr_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(l_parts(1))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '@')) = upper(nvl(l_sub_id, '@'));
         select parameter_type_code
           into l_obj.attr_parameter_type_code
           from cwms_parameter_type
          where upper(parameter_type_id) = upper(attr_parameter_type_id);

         select duration_code
           into l_obj.attr_duration_code
           from cwms_duration
          where upper(duration_id) = upper(attr_duration_id);

         select factor,
                offset
           into l_factor,
                l_offset
           from cwms_unit_conversion
          where from_unit_id = attr_units_id
            and to_unit_id = cwms_util.get_default_units(attr_parameter_id);
      end if;

      if ref_specified_level_id is not null then
         select sl.specified_level_code
           into l_obj.ref_specified_level_code
           from at_specified_level sl
          where upper(sl.specified_level_id) = upper(ref_specified_level_id)
            and sl.office_code in (
                select office_code
                  from cwms_office
                 where office_id in (self.office_id, 'CWMS'));
      end if;

      l_obj.level_indicator_id := level_indicator_id;
      l_obj.attr_value         := attr_value * l_factor + l_offset;
      l_obj.ref_attr_value     := ref_attr_value * l_factor + l_offset;
      l_obj.minimum_duration   := minimum_duration;
      l_obj.maximum_age        := maximum_age;
      l_obj.conditions         := conditions;

      return l_obj;
   end zloc_lvl_indicator;

   member procedure store
   is
      l_obj zloc_lvl_indicator_t := zloc_lvl_indicator;
   begin
      l_obj.store;
   end store;

   member function get_indicator_values(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number_tab_t
   is
      l_eval_time            date := nvl(p_eval_time, cast(systimestamp at time zone 'UTC' as date));
      l_max_age              number;
      l_min_dur              number;
      l_indicator_values     number_tab_t := number_tab_t();
      l_rate_of_change       boolean := false;
      l_is_set               boolean;
      l_set                  boolean;
      l_last                 pls_integer;
      l_level_values_1       ztsv_array;
      l_level_values_2       ztsv_array;
      l_level_values_array_1 double_tab_t := double_tab_t();
      l_level_values_array_2 double_tab_t := double_tab_t();
      l_rate_values_array    double_tab_t := double_tab_t();
      i                      binary_integer;
      j                      binary_integer;
      function is_valid(
         p_quality_code in number)
         return boolean
      is
         -- l_validity_id varchar2(16);
      begin
         /*
         select validity_id
           into l_validity_id
           from cwms_data_quality
          where quality_code = p_quality_code;
         return l_validity_id not in ('MISSING', 'REJECTED');
         */
         return bitand(p_quality_code, 20) = 0; -- 30 x faster!
      end is_valid;
   begin
      --------------------------------------
      -- create day values from durations --
      --------------------------------------
      l_max_age := extract(day    from maximum_age) +
                  (extract(hour   from maximum_age) / 24) +
                  (extract(minute from maximum_age) / 1440) +
                  (extract(second from maximum_age) / 86400);
      l_min_dur := extract(day    from minimum_duration) +
                  (extract(hour   from minimum_duration) / 24) +
                  (extract(minute from minimum_duration) / 1440) +
                  (extract(second from minimum_duration) / 86400);
      -------------------------------------                  
      -- determine whether we need rates --
      -------------------------------------
      for i in 1..conditions.count loop
         if not l_rate_of_change and conditions(i).rate_expression is not null then
            l_rate_of_change := true;
         end if;
         exit when l_rate_of_change;          
      end loop;
      ----------------------------------------------------------------
      -- find the last valid value on or before the evaluation time --
      ----------------------------------------------------------------
      if p_ts is null or p_ts.count = 0 then
         return l_indicator_values;
      end if;
      for i in reverse 1..p_ts.count loop
         l_last := i;
         continue when p_ts(l_last).date_time > l_eval_time;
         exit when bitand(p_ts(l_last).quality_code, 20) = 0; --is_valid(p_ts(l_last).quality_code);
      end loop;
      -------------------------------------------------------
      -- only evaluate if last valid time is recent enough --
      -------------------------------------------------------
      if l_eval_time - p_ts(l_last).date_time <= l_max_age then
         l_rate_values_array.extend(l_last);
         if l_rate_of_change then
            -------------------------------------------------------
            -- compute the hourly rates of change if using rates --
            -------------------------------------------------------
            for i in reverse 2..l_last loop
               continue when bitand(p_ts(i).quality_code, 20) != 0; --not is_valid(p_ts(i).quality_code);
               for j in reverse 1..i-1 loop
                  get_indicator_values.j := j;
                  exit when bitand(p_ts(j).quality_code, 20) = 0; --is_valid(p_ts(j).quality_code);
               end loop;
               l_rate_values_array(i) :=
                  (p_ts(i).value - p_ts(j).value) /
                  ((p_ts(i).date_time - p_ts(j).date_time) * 24);
               -- cwms_msg.log_db_message('z', 7, ''||i||', '||j||': '||l_rate_values_array(i));                  
            end loop;
         end if;
         --------------------------------------------------
         -- retrieve the level values to compare against --
         --------------------------------------------------
         l_level_values_1 := cwms_level.retrieve_location_level_values(
            cwms_level.get_location_level_id(
               location_id,
               parameter_id,
               parameter_type_id,
               duration_id,
               specified_level_id),
            cwms_util.get_default_units(parameter_id),
            p_ts(1).date_time,
            p_ts(l_last).date_time,
            cwms_level.get_attribute_id(
               attr_parameter_id,
               attr_parameter_type_id,
               attr_duration_id),
            attr_value,
            attr_units_id,
            'UTC',
            office_id);
         if ref_specified_level_id is not null then
            l_level_values_2 := cwms_level.retrieve_location_level_values(
               cwms_level.get_location_level_id(
                  location_id,
                  parameter_id,
                  parameter_type_id,
                  duration_id,
                  ref_specified_level_id),
               cwms_util.get_default_units(parameter_id),
               p_ts(1).date_time,
               p_ts(l_last).date_time,
               cwms_level.get_attribute_id(
                  attr_parameter_id,
                  attr_parameter_type_id,
                  attr_duration_id),
               ref_attr_value,
               attr_units_id,
               'UTC',
               office_id);
         end if;
         ----------------------------------
         -- build tables of level values --
         ----------------------------------
         l_level_values_array_1.extend(l_last);
         l_level_values_array_2.extend(l_last);
         j := l_level_values_1.count;
         for i in reverse 1..l_last loop
            while l_level_values_1(j).date_time > p_ts(i).date_time loop
               exit when j = 1;
               j := j - 1;
            end loop;
            l_level_values_array_1(i) := l_level_values_1(j).value;
         end loop;
         if ref_specified_level_id is not null then
            j := l_level_values_2.count;
            for i in reverse 1..l_last loop
               while l_level_values_2(j).date_time > p_ts(i).date_time loop
                  exit when j = 1;
                  j := j - 1;
               end loop;
               l_level_values_array_2(i) := l_level_values_2(j).value;
            end loop;
         end if;
         -----------------------------
         -- evaluate each condition --
         -----------------------------
         for i in 1..conditions.count loop
            l_set := false;
            for j in reverse 1..l_last loop
               continue when bitand(p_ts(j).quality_code, 20) != 0; --not is_valid(p_ts(j).quality_code);
               exit when not conditions(i).is_set(
                  p_ts(j).value,
                  l_level_values_array_1(j),
                  l_level_values_array_2(j),
                  l_rate_values_array(j));
               if (p_ts(l_last).date_time - p_ts(j).date_time) >= l_min_dur then
                  l_set := true;
                  exit;
               end if;
            end loop;
            if l_set then
               l_indicator_values.extend;
               l_indicator_values(l_indicator_values.count) := conditions(i).indicator_value;
            end if;
         end loop;
      end if;
      return l_indicator_values;
   end get_indicator_values;

   member function get_max_indicator_value(
      p_ts        in ztsv_array,
      p_eval_time in date default null)
      return number
   is
      l_eval_time           date;
      l_lookback_time       date;
      l_indicator_values    number_tab_t;
      l_max_indicator_value number;
      l_eval_times          date_table_type;
   begin
      l_eval_time     := nvl(p_eval_time, sysdate);
      l_lookback_time := cast(cast(l_eval_time as timestamp) - maximum_age as date);
      ------------------------------------------------------------------------------------------
      -- get a reversed-ordered collection of times in the data and also within lookback time --
      ------------------------------------------------------------------------------------------
      select t.date_time
        bulk collect into l_eval_times
        from table(p_ts) t
       where t.date_time between l_lookback_time and l_eval_time
       order by t.date_time desc;
      ----------------------------------------------------------------
      -- get the first (most recent) time that has a non-zero value --
      ----------------------------------------------------------------
      for i in 1..l_eval_times.count loop
         l_indicator_values := get_indicator_values(p_ts, l_eval_times(i));
         case l_indicator_values.count
            when 0 then l_max_indicator_value :=  0;
            else l_max_indicator_value := l_indicator_values(l_indicator_values.count);
         end case;
         exit when l_max_indicator_value != 0;
      end loop;
      return l_max_indicator_value;
   end get_max_indicator_value;

   member function get_max_indicator_values(
      p_ts         in ztsv_array,
      p_start_time in date)
      return ztsv_array
   is
      l_results ztsv_array := new ztsv_array();
   begin
      for i in 1..p_ts.count loop
         continue when p_ts(i).date_time < p_start_time;
         l_results.extend;
         l_results(l_results.count) := new ztsv_type(
            p_ts(i).date_time,
            get_max_indicator_value(p_ts, p_ts(i).date_time),
            0);
      end loop;
      return l_results;
   end get_max_indicator_values;
   
end;
/
show errors;

create type loc_lvl_indicator_tab_t
/**
 * Holds a collection of loc_lvl_indicator_t objects.
 *
 * @see type loc_lvl_indicator_t
 */
is table of loc_lvl_indicator_t;
/

create type seasonal_value_t
/**
 * Holds a single value at a specified time offset into a recurring interval. The offset
 * into the interval is specified as a combination of months and minutes
 *
 * @see type seasonal_value_tab_t
 *
 * @member offset_months  The integer number of months offset into the interval (combined with offset minutes)
 * @member offset_minutes The integer number of minutes offset into the interval (combined with offset months)
 * @member value          The value at the specified offset into the interval
 */
is object (
   offset_months  number(2),
   offset_minutes number(5),
   value          number,
   /**
    * Constructs a seasonal_value_t object from Oracle interval types instead of integer types
    *
    * @param p_calendar_offset The calendar offset (years and months) into the interval (combined with time offset)
    * @param p_time_offset     The time offset (days, hours and minutes) into the interval (combined with calendar offset)
    * @param p_value           The value at the specified offset into the interval
    */
   constructor function seasonal_value_t(
      p_calendar_offset in interval year to month,
      p_time_offset     in interval day to second,
      p_value           in number)
      return self as result,

   member procedure init(
      p_offset_months  in integer,
      p_offset_minutes in integer,
      p_value          in number)
);
/

create type body seasonal_value_t
as
   constructor function seasonal_value_t(
      p_calendar_offset in interval year to month,
      p_time_offset     in interval day to second,
      p_value           in number)
      return self as result
   is
   begin
      init(cwms_util.yminterval_to_months(p_calendar_offset),
           cwms_util.dsinterval_to_minutes(p_time_offset),
           p_value);
      return;
   end seasonal_value_t;

   member procedure init(
      p_offset_months  in integer,
      p_offset_minutes in integer,
      p_value          in number)
   is
   begin
      offset_months  := p_offset_months;
      offset_minutes := p_offset_minutes;
      value          := p_value;
   end init;

end;
/
show errors;

/**
 * Holds a collection of values at specified offsets into a recurring interval
 *
 * @see type seasonal_value_t
 */
create type seasonal_value_tab_t is table of seasonal_value_t;
/

-- not documented
create type seasonal_location_level_t is object
(
   calendar_offset interval year(2) to month,
   time_offset     interval day(3) to second(0),
   level_value     number
);
/

-- not documented
create type seasonal_loc_lvl_tab_t is table of seasonal_location_level_t;
/

-- not documented
create type zlocation_level_t is object(
   location_level_code           number(10),
   location_code                 number(10),
   specified_level_code          number(10),
   parameter_code                number(10),
   parameter_type_code           number(10),
   duration_code                 number(10),
   location_level_date           date,
   location_level_value          number,
   location_level_comment        varchar2(256),
   attribute_value               number,
   attribute_parameter_code      number(10),
   attribute_param_type_code     number(10),
   attribute_duration_code       number(10),
   attribute_comment             varchar2(256),
   interval_origin               date,
   calendar_interval             interval year(2) to month,
   time_interval                 interval day(3) to second(0),
   interpolate                   varchar2(1),
   ts_code                       number(10),
   seasonal_level_values         seasonal_loc_lvl_tab_t,
   indicators                    loc_lvl_indicator_tab_t,

   constructor function zlocation_level_t(
      p_location_level_code           in number)
      return self as result,  
      
   constructor function zlocation_level_t
      return self as result,      

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
      p_ts_code                       number,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t),

   member procedure store
);
/

create type body zlocation_level_t
as
   constructor function zlocation_level_t(
      p_location_level_code in number)
      return self as result
   as
      l_rec             at_location_level%rowtype;
      l_seasonal_values seasonal_loc_lvl_tab_t := new seasonal_loc_lvl_tab_t();
      l_indicators      loc_lvl_indicator_tab_t := new loc_lvl_indicator_tab_t();
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
      p_ts_code                       number,
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
      self.ts_code                       :=  p_ts_code;
      self.seasonal_level_values         := p_seasonal_values;
      self.indicators                    := p_indicators;
   end init;

   member procedure store
   as
      l_rec    at_location_level%rowtype;
      l_exists boolean;
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
          for i in 1..self.seasonal_level_values.count loop
            insert
              into at_seasonal_location_level
            values (l_rec.location_level_code,
                    self.seasonal_level_values(i).calendar_offset,
                    self.seasonal_level_values(i).time_offset,
                    self.seasonal_level_values(i).level_value);
          end loop;
       end if;
      --------------------------
      -- store the indicators --
      --------------------------
       if l_exists then
         delete
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

create type location_level_t
/**
 * Holds a location level.  A location level combines a location, parameter, parameter type,
 * duration, and specified level to describe a named level that can be compared against values
 * to determine status conditions. Location levels contain up to five indicators that may
 * be set during such a comparison. Location levels also have optional attribute values
 * that make them suitable for describing guide curves/rule curves
 *
 * @see type seasonal_value_tab_t
 * @see type loc_lvl_indicator_tab_t
 * @see type location_level_tab_t
 *
 * @member office_id                   The office that owns the location and specified level
 * @member location_id                 The location component of the location level
 * @member parameter_id                The parameter component of the location level
 * @member parameter_type_id           The parameter type component of the location level
 * @member duration_id                 The duration component of the location level
 * @member specified_level_id          The specified level component of the location level
 * @member level_date                  The effective date of the location level
 * @member level_value                 The value of the location level if it is a constant value (not recurring pattern or time series)
 * @member level_units_id              The unit used for the constant or varying location level value
 * @member level_comment               A comment about the location level
 * @member attribute_parameter_id      The parameter component of the location level attribute, if any
 * @member attribute_parameter_type_id The parameter type component of the location level attribute, if any
 * @member attribute_duration_id       The duration component of the location level attribute, if any
 * @member attribute_value             The value of the location level attribute, if any
 * @member attribute_units_id          The unit of the location level attribute value, if any
 * @member attribute_comment           A comment about the location level attribute
 * @member interval_origin             The start time of any of the recurring intervals if the location level is a recurring pattern of values
 * @member interval_months             The recurring interval duration if the location level is a recurring pattern and is described in units of months and/or years
 * @member interval_minutes            The recurring interval duration if the location level is a recurring pattern and is described in units of days or less
 * @member interpolate                 A flag ('T' or 'F') specifying whether to interpolate for level values at offsets between the specified offsets into the interval
 * @member seasonal_values             The values of the location level if it is a recurring pattern of values (not constant value or time series)
 * @member tsid                        The time series identifier representing the location level if it is a time series (not constant value or recurring pattern)
 * @member indicators                  The location level indicators associated with this location level
 */
is object (
   office_id                   varchar2(16),
   location_id                 varchar2(49),
   parameter_id                varchar2(49),
   parameter_type_id           varchar2(16),
   duration_id                 varchar2(16),
   specified_level_id          varchar2(256),
   level_date                  date,
   level_value                 number,
   level_units_id              varchar2(16),
   level_comment               varchar2(256),
   attribute_parameter_id      varchar2(49),
   attribute_parameter_type_id varchar2(16),
   attribute_duration_id       varchar2(16),
   attribute_value             number,
   attribute_units_id          varchar2(16),
   attribute_comment           varchar2(256),
   interval_origin             date,
   interval_months             integer,
   interval_minutes            integer,
   interpolate                 varchar2(1),
   tsid                        varchar2(183),
   seasonal_values             seasonal_value_tab_t,
   indicators                  loc_lvl_indicator_tab_t,
   -- not documented
   constructor function location_level_t(
      p_obj zlocation_level_t)
      return self as result,
   -- not documented
   constructor function location_level_t
      return self as result,        
   -- not documented
   member function zlocation_level
      return zlocation_level_t,
   /**
    * Stores the location level to the database
    */
   member procedure store
);
/

create type body location_level_t
as

   constructor function location_level_t(
      p_obj zlocation_level_t)
      return self as result
   is
   begin
      select o.office_id,
             bl.base_location_id
             || substr('-', 1, length(pl.sub_location_id))
             || pl.sub_location_id
        into self.office_id,
             self.location_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_obj.location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;

      select bp.base_parameter_id
             || substr('-', 1, length(p.sub_parameter_id))
             || p.sub_parameter_id
        into self.parameter_id
        from at_parameter p,
             cwms_base_parameter bp
       where p.parameter_code = p_obj.parameter_code
         and bp.base_parameter_code = p.base_parameter_code;

      select parameter_type_id
        into self.parameter_type_id
        from cwms_parameter_type
       where parameter_type_code = p_obj.parameter_type_code;

      select duration_id
        into self.duration_id
        from cwms_duration
       where duration_code = p_obj.duration_code;

      select specified_level_id
        into self.specified_level_id
        from at_specified_level
       where specified_level_code = p_obj.specified_level_code;

      self.level_date := p_obj.location_level_date;
      self.level_value := p_obj.location_level_value;
      self.level_units_id := cwms_util.get_default_units(parameter_id);

      if p_obj.attribute_parameter_code is not null then
         select bp.base_parameter_id
                || substr('-', 1, length(p.sub_parameter_id))
                || p.sub_parameter_id
           into self.attribute_parameter_id
           from at_parameter p,
                cwms_base_parameter bp
          where p.parameter_code = p_obj.attribute_parameter_code
            and bp.base_parameter_code = p.base_parameter_code;

         select parameter_type_id
           into self.attribute_parameter_type_id
           from cwms_parameter_type
          where parameter_type_code = p_obj.attribute_param_type_code;

         select duration_id
           into self.attribute_duration_id
           from cwms_duration
          where duration_code = p_obj.attribute_duration_code;
         attribute_value := p_obj.attribute_value;
         level_units_id := cwms_util.get_default_units(attribute_parameter_id);

         attribute_comment := p_obj.attribute_comment;
      end if;

      self.interval_origin  := p_obj.interval_origin;
      self.interval_months  := cwms_util.yminterval_to_months(p_obj.calendar_interval);
      self.interval_minutes := cwms_util.dsinterval_to_minutes(p_obj.time_interval);
      self.interpolate      := p_obj.interpolate;
      self.tsid             := case p_obj.ts_code is null
                                  when true  then null
                                  when false then cwms_ts.get_ts_id(p_obj.ts_code)
                               end;
      if p_obj.seasonal_level_values is not null then
         self.seasonal_values := new seasonal_value_tab_t();
         for i in 1..p_obj.seasonal_level_values.count loop
            self.seasonal_values.extend;
            self.seasonal_values(i) := seasonal_value_t(
               p_obj.seasonal_level_values(i).calendar_offset,
               p_obj.seasonal_level_values(i).time_offset,
               p_obj.seasonal_level_values(i).level_value);
         end loop;
      end if;
      self.indicators := p_obj.indicators;
      return;
   end location_level_t;

 constructor function location_level_t
      return self as result
   is
   begin
      --------------------------
      -- all members are null --
      --------------------------
      return;
   end;               

   member function zlocation_level
      return zlocation_level_t
   is
      l_office_code                   number(10);
      l_cwms_office_code              number(10) := cwms_util.get_office_code('CWMS');
      l_location_level_code           number(10);
      l_location_code                 number(10);
      l_specified_level_code          number(10);
      l_parameter_code                number(10);
      l_parameter_type_code           number(10);
      l_duration_code                 number(10);
      l_location_level_value          number;
      l_attribute_value               number;
      l_attribute_parameter_code      number(10);
      l_attribute_param_type_code     number(10);
      l_attribute_duration_code       number(10);
      l_calendar_interval             interval year(2) to month;
      l_time_interval                 interval day(3) to second(0);
      l_seasonal_level_values         seasonal_loc_lvl_tab_t;
      l_obj                           zlocation_level_t;
      l_parameter_type_id             parameter_type_id%type := parameter_type_id;
      l_duration_id                   duration_id%type := duration_id;
      l_specified_level_id            specified_level_id%type := specified_level_id;

   begin
      select o.office_code,
             pl.location_code
        into l_office_code,
             l_location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where upper(o.office_id) = upper(self.office_id)
         and bl.db_office_code = o.office_code
         and bl.base_location_code = pl.base_location_code
         and upper(bl.base_location_id) = upper(cwms_util.get_base_id(self.location_id))
         and upper(nvl(pl.sub_location_id, '.')) = upper(nvl(cwms_util.get_sub_id(self.location_id), '.'));

      select p.parameter_code
        into l_parameter_code
        from at_parameter p,
             cwms_base_parameter bp
       where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(self.parameter_id))
         and p.base_parameter_code = bp.base_parameter_code
         and upper(nvl(p.sub_parameter_id, '.')) = upper(nvl(cwms_util.get_sub_id(self.parameter_id), '.'))
         and p.db_office_code in (l_office_code, l_cwms_office_code);

      select pt.parameter_type_code
        into l_parameter_type_code
        from cwms_parameter_type pt
       where upper(pt.parameter_type_id) = upper(l_parameter_type_id);

      select d.duration_code
        into l_duration_code
        from cwms_duration d
       where upper(d.duration_id) = upper(l_duration_id);

      select sl.specified_level_code
        into l_specified_level_code
        from at_specified_level sl
       where upper(sl.specified_level_id) = upper(l_specified_level_id);

      select level_value * factor + offset
        into l_location_level_value
        from cwms_unit_conversion cuc
       where from_unit_id = self.level_units_id
         and to_unit_id = cwms_util.get_default_units(self.parameter_id);

      if self.attribute_parameter_id is not null then
         select p.parameter_code
           into l_attribute_parameter_code
           from at_parameter p,
                cwms_base_parameter bp
          where upper(bp.base_parameter_id) = upper(cwms_util.get_base_id(self.attribute_parameter_id))
            and p.base_parameter_code = bp.base_parameter_code
            and upper(nvl(p.sub_parameter_id, '.')) = upper(nvl(cwms_util.get_sub_id(self.attribute_parameter_id), '.'))
            and p.db_office_code in (l_office_code, l_cwms_office_code);

         select pt.parameter_type_code
           into l_attribute_param_type_code
           from cwms_parameter_type pt
          where upper(pt.parameter_type_id) = upper(self.attribute_parameter_type_id);

         select d.duration_code
           into l_attribute_duration_code
           from cwms_duration d
          where upper(d.duration_id) = upper(self.attribute_duration_id);

         select self.attribute_value * factor + offset
           into l_attribute_value
           from cwms_unit_conversion cuc
          where from_unit_id = attribute_units_id
            and to_unit_id = cwms_util.get_default_units(self.attribute_parameter_id);
      end if;

      l_calendar_interval := cwms_util.months_to_yminterval(self.interval_months);
      l_time_interval     := cwms_util.minutes_to_dsinterval(self.interval_minutes);

      if self.seasonal_values is not null then
         l_seasonal_level_values := new seasonal_loc_lvl_tab_t();
         for i in 1..self.seasonal_values.count loop
            l_seasonal_level_values.extend;
            l_seasonal_level_values(i) := seasonal_location_level_t(
               cwms_util.months_to_yminterval(self.seasonal_values(i).offset_months),
               cwms_util.minutes_to_dsinterval(self.seasonal_values(i).offset_minutes),
               seasonal_values(i).value);
         end loop;
      end if;

      begin
         select location_level_code
           into l_location_level_code
           from at_location_level
          where location_code = l_location_code
            and parameter_code = l_parameter_code
            and parameter_type_code = l_parameter_type_code
            and duration_code = l_duration_code
            and specified_level_code = l_specified_level_code
            and location_level_date = self.level_date
            and location_level_value = l_location_level_value
            and nvl(to_char(attribute_value), '@') = nvl(to_char(l_attribute_value), '@')
            and nvl(attribute_parameter_code, -1) = nvl(l_attribute_parameter_code, -1)
            and nvl(attribute_parameter_type_code, -1) = nvl(l_attribute_param_type_code, -1)
            and nvl(attribute_duration_code, -1) = nvl(l_attribute_duration_code, -1);
      exception
         when no_data_found then null;
      end;
      if l_location_level_code is null then
         l_obj := zlocation_level_t();
         l_obj.init(
            cwms_seq.nextval,
            l_location_code,
            l_specified_level_code,
            l_parameter_code,
            l_parameter_type_code,
            l_duration_code,
            self.level_date,
            l_location_level_value,
            self.level_comment,
            l_attribute_value,
            l_attribute_parameter_code,
            l_attribute_param_type_code,
            l_attribute_duration_code,
            self.attribute_comment,
            self.interval_origin,
            l_calendar_interval,
            l_time_interval,
            self.interpolate,
            case self.tsid is null
               when true  then null
               when false then cwms_ts.get_ts_code(self.tsid, l_office_code)
            end,
            l_seasonal_level_values,
            self.indicators);
      else
         l_obj := zlocation_level_t(l_location_level_code);
      end if;
      return l_obj;
   end zlocation_level;

   member procedure store
   is
      l_obj zlocation_level_t;
   begin
      l_obj:= zlocation_level;
      l_obj.store;
   end store;
end;
/
show errors;

create type location_level_tab_t
/**
 * Holds a collection of location levels
 *
 * @see type location_level_t
 */
is table of location_level_t;
/
-- not documented
create type jms_map_msg_tab_t as table of sys.aq$_jms_map_message;
/

create type property_info_t
/**
 * Holds information about a property key
 *
 * @see type property_info2_t
 * @see type property_info_tab_t
 *
 * @member office_id     The office that owns the property
 * @member prop_category The property category. Analogous to the file name of a properties file
 * @member prop_id       The property identifier.  Analogous to the property key in a properties file
 */
as object (
   office_id     varchar2 (16),
   prop_category varchar2 (256),
   prop_id       varchar2 (256));
/

create type property_info_tab_t
/**
 * Holds a collection of property keys
 *
 * @see type property_info_t
 * @see type property_info2_tab_t
 */
as table of property_info_t;
/

create type property_info2_t
/**
 * Holds information about a property
 *
 * @see type property_info_t
 * @see type property_info2_tab_t
 *
 * @member office_id     The office that owns the property
 * @member prop_category The property category. Analogous to the file name of a properties file
 * @member prop_id       The property identifier.  Analogous to the property key in a properties file
 * @member prop_value    The property value. Analogous to the property value in a properties file
 * @member prop_comment  A comment about the property. No analog in a properties file except a comment line before the property
 */
as object (
   office_id     varchar2 (16),
   prop_category varchar2 (256),
   prop_id       varchar2 (256),
   prop_value    varchar2 (256),
   prop_comment  varchar2 (256));
/

create type property_info2_tab_t
/**
 * Holds a collection of properties
 *
 * @see type property_info2_t
 * @see type property_info_tab_t
 */
as table of property_info2_t;
/

create type time_series_range_t
/**
 * Holds information about the range of values for a time series and time window
 *
 * @see type time_series_range_tab_t
 *
 * @member office_id      The office that owns the time series
 * @member time_series_id The time series identifier
 * @member start_time     The start of the time window
 * @member end_time       The end of the time window
 * @member time_zone      The time zone of the start and end times
 * @member minimum_value  The minimum value for the time series in the time window
 * @member maximum_value  The maximum value for the time series in the time window
 * @member unit           The unit for the minimum and maximum values
 */
as object (
   office_id      varchar2(16),
   time_series_id varchar2(183),
   start_time     date,
   end_time       date,
   time_zone      varchar2(28),
   minimum_value  binary_double,
   maximum_value  binary_double,
   unit           varchar2(16));
/

create type time_series_range_tab_t
/**
 * Holds a collection of time series value range objects
 *
 * @see type time_series_range_t
 */
as table of time_series_range_t;
/

create type date2_t
/**
 * Holds a pair of dates
 *
 * @see type date2_tab_t
 *
 * @member date_1 The first date
 * @member date_2 The second date
 */
as object(
   date_1 date,
   date_2 date);
/

create type date2_tab_t
/**
 * Holds a collection of date pairs
 *
 * @see type date2_t
 */
as table of date2_t;
/

-- HOST pwd
@@rowcps_types
@@cwms_types_rating
COMMIT ;
