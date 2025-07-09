CREATE TYPE anydata_tab_t
/**
 * Holds a collection of anydata objects
 *
 */
IS
  TABLE OF anydata;
/


create or replace public synonym cwms_t_anydata_tab for anydata_tab_t;

create type str_tab_t
/**
 * Holds a collection of strings
 *
 * @see type str_tab_tab_t
 */
is table of varchar2(32767);
/


create or replace public synonym cwms_t_str_tab for str_tab_t;

create type str_tab_tab_t
/**
 * Holds a collection of string collections
 *
 * @see type str_tab_t
 */
is table of str_tab_t;
/


create or replace public synonym cwms_t_str_tab_tab for str_tab_tab_t;

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
      cwms_ts_id VARCHAR2 (191),
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


create or replace public synonym cwms_t_shef_spec for shef_spec_type;

create type SHEF_SPEC_ARRAY
/**
 * Table of <code><big>shef_spec_type</big></code> records.  This collection usually
 * comprises the entire SHEF decoding criteria set for a single CWMS data stream.
 *
 * @see type shef_spec_type
 */
IS TABLE OF shef_spec_type;
/

create or replace public synonym cwms_t_shef_spec_array for shef_spec_array;

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


create or replace public synonym cwms_t_tsv for tsv_type;

CREATE TYPE tsv_array
/**
 * Table of <code><big>tsv_type</big></code> records. This collection specifies
 * a time series of values for a certain time range.  This type carries time zone
 * information, so any usage of it should not explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type tsv_type
 * @see type tsv_array_tab
 * @see type ztsv_array
 */
IS TABLE OF tsv_type;
/


create or replace public synonym cwms_t_tsv_array for tsv_array;

create type tsv_array_tab
/**
 * Table of <code><big>tsv_array</big></code> records. This collection specifies
 * multiple time series.  There is no implicit constraint that all of the time series
 * are for the same location or time range, although any routine that uses this type
 * may impose these constraints.  This type carries time zone information, so
 * any usage of it should not explicitly declare the time zone. External specification of
 * time series attributes is also required for proper usage.
 *
 * @see type tsv_type
 * @see type tsv_array
 */
as table of tsv_array;
/


create or replace public synonym cwms_t_tsv_array_tab for tsv_array_tab;

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
   quality_code NUMBER) NOT FINAL;
/


create or replace public synonym cwms_t_ztsv for ztsv_type;

create type ztsv_entry_type under ztsv_type
/**
 * Object type representing a single time series value with the data entry dates.
 * This type does not carry time zone information, so any usage of it needs
 * to explicitly declare the time zone.
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
 * @see type ztsv_entry_array
 */
(data_entry_date   TIMESTAMP);
/

create type ztsv_entry_array
/**
 * Table of <code><big>ztsv_entry_type</big></code> records. This collection specifies
 * a time series of values for a certain time range with their data entry dates.
 * This type does not carry time zone information, so any usage of it
 * should explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type ztsv_entry_array
 * @see type ztsv_entry_array_tab
 */
IS TABLE OF ztsv_entry_type;
/

create or replace public synonym cwms_t_ztsv_entry_array for ztsv_entry_array;

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


create or replace public synonym cwms_t_ztsv_array for ztsv_array;

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
 * @see type tsv_array_tab
 */
as table of ztsv_array;
/


create or replace public synonym cwms_t_ztsv_array_tab for ztsv_array_tab;

create or replace type ztimeseries_type
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
   tsid VARCHAR2(191),
   unit VARCHAR2 (16),
   data ztsv_array);
/

   
create or replace public synonym cwms_t_ztimeseries for ztimeseries_type;

create type ztimeseries_array
/**
 * Table of <code><big>ztimeseries_type</big></code> records. This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 */
IS TABLE OF ztimeseries_type;
/


create or replace public synonym cwms_t_ztimeseries_array for ztimeseries_array;

CREATE TYPE char_16_array_type
/**
 * Type suitable for holding multiple base locations, base parameters, or other text
 * not longer than 16 bytes.
 */
IS TABLE OF VARCHAR2 (16);
/


create or replace public synonym cwms_t_char_16_array for char_16_array_type;

CREATE TYPE char_32_array_type
/**
 * Type suitable for holding multiple sub-locations, sub-parameters, or other text
 * not longer than 32 bytes.
 */
IS TABLE OF VARCHAR2 (32);
/


create or replace public synonym cwms_t_char_32_array for char_32_array_type;

create or replace TYPE char_49_array_type
/**
 * Type suitable for holding parameters or other text
 * not longer than 49 bytes.
 */
IS TABLE OF VARCHAR2 (49);
/


create or replace public synonym cwms_t_char_49_array for char_49_array_type;

CREATE TYPE char_183_array_type
/**
 * Type suitable for holding multiple time series identifiers or other text
 * not longer than 183 bytes.
 */
IS TABLE OF VARCHAR2 (183);
/


create or replace public synonym cwms_t_char_183_array for char_183_array_type;

CREATE TYPE date_table_type
/**
 * Type suitable for holding multiple date/time values
 */
AS TABLE OF DATE;
/


create or replace public synonym cwms_t_date_table for date_table_type;

create or replace TYPE timeseries_type
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
   tsid   VARCHAR2(191),
   unit   VARCHAR2 (16),
   DATA   tsv_array
);
/


create or replace public synonym cwms_t_timeseries for timeseries_type;

CREATE TYPE timeseries_array
/**
 * Type suitable for holding multiple time series.
 *
 * @see type timeseries_type
 */
IS TABLE OF timeseries_type;
/


create or replace public synonym cwms_t_timeseries_array for timeseries_array;
create or replace type ts_extents_t
/**
 * Holds date/time and value extent information for time series (basically at_ts_extents%rowtype)
 *
 * @member ts_code                       Unique nummeric value identifying time series
 * @member version_time                  The version date/time of the time series (always 11-Nov-1111 00:00:00 for unversioned time series)
 * @member earliest_time                 The earliest time that a value exists for the time series
 * @member earliest_time_entry           The time that the earliest value was entered (stored)
 * @member earliest_entry_time           The earliest time that a value (for any time) was entered (stored) for the time series
 * @member earliest_non_null_time        The earliest time that a non-null value exists for the time series
 * @member earliest_non_null_time_entry  The time that the earliest non-null value was entered (stored)
 * @member earliest_non_null_entry_time  The earliest time that a non-null value (for any time) was entered (stored) for the time series
 * @member latest_time                   The latest time that a value exists for the time series
 * @member latest_time_entry             The time that the latest value was entered (stored)
 * @member latest_entry_time             The latest time that a value (for any time) was entered (stored) for the time series
 * @member latest_non_null_time          The latest time that a non-null value exists for the time series
 * @member latest_non_null_time_entry    The time that latest non-null value was entered (stored)
 * @member latest_non_null_entry_time    The latest time that a non-null value (for any time) was entered (stored) for the time series
 * @member least_value                   The least non-null value (in database units) that has been stored for the time series
 * @member least_value_time              The time that the least non-null value (in database units) that has been stored for the time series is for
 * @member least_value_entry             The time that the least non-null value (in database units) that has been stored for the time series was entered (stored)
 * @member least_accepted_value          The least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series
 * @member least_accepted_value_time     The time that the least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series is for
 * @member least_accepted_value_entry    The time that the least accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series was entered (stored)
 * @member greatest_value                The greatest non-null value (in database units) that has been stored for the time series
 * @member greatest_value_time           The time that the greatest non-null value (in database units) that has been stored for the time series is for
 * @member greatest_value_entry          The time that the greatest non-null value (in database units) that has been stored for the time series was entered (stored)
 * @member greatest_accepted_value       The greatest_accepted non-null value (in database units) that has been stored for the time series
 * @member greatest_accepted_value_time  The time that the greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series is for
 * @member greatest_accepted_value_entry The time that the greatest accepted (not missing or rejected) non-null value (in database units) that has been stored for the time series was entered (stored)
 * @member last_update                   The time that this record was updated
 *
 * @see ts_extents_tab_t
 *
 */
as object (
   ts_code                       integer,
   version_time                  date,
   earliest_time                 date,
   earliest_time_entry           timestamp,
   earliest_entry_time           timestamp,
   earliest_non_null_time        date,
   earliest_non_null_time_entry  timestamp,
   earliest_non_null_entry_time  timestamp,
   latest_time                   date,
   latest_time_entry             timestamp,
   latest_entry_time             timestamp,
   latest_non_null_time          date,
   latest_non_null_time_entry    timestamp,
   latest_non_null_entry_time    timestamp,
   least_value                   binary_double,
   least_value_time              date,
   least_value_entry             timestamp,
   least_accepted_value          binary_double,
   least_accepted_value_time     date,
   least_accepted_value_entry    timestamp,
   greatest_value                binary_double,
   greatest_value_time           date,
   greatest_value_entry          timestamp,
   greatest_accepted_value       binary_double,
   greatest_accepted_value_time  date,
   greatest_accepted_value_entry timestamp,
   last_update                   timestamp,
   /**
    * Null constructor. Initializes all attributes to null
    */
   constructor function ts_extents_t
      return self as result,
   /**
    * Constructor from AT_TS_EXTENTS row
    *
    * @param p_rowid The rowid in AT_TS_EXTENTS to construct from
    */
   constructor function ts_extents_t(
      p_rowid in urowid)
      return self as result,
   /**
    * Converts the units of the value fields
    *
    * @param p_from_unit The unit to convert from. If unspecified or NULL, the default database unit is used.
    * @param p_to_unit   The unit to convert to. If unspecified or NULL, the default database unit is used.
    */
   member procedure convert_units(
      p_from_unit in varchar2 default null,
      p_to_unit   in varchar2 default null),
   /**
    * Changes the time zone of the date and timestamp fields
    *
    * @param p_from_timezone The time zone to change from. If unspecified or NULL, the database time zone of 'UTC' is used. If 'LOCAL', the location's local time zone is used.
    * @param p_to_timezone The time zone to change to. If unspecified or NULL, the database time zone of 'UTC' is used. If 'LOCAL', the location's local time zone is used.
    */
   member procedure change_timezone(
      p_from_timezone in varchar2 default null,
      p_to_timezone   in varchar2 default null)
);
/
create or replace public synonym cwms_t_ts_extents for ts_extents_t;
create or replace type text_file_t
/**
 * Holds a text-based file object
 *
 * @member the_text The text content of the file
 */
under file_t (
   the_text clob,

   constructor function text_file_t(filename varchar2, media_type varchar2, quality_code integer, description varchar2, the_text clob)
      return self as result,

   constructor function text_file_t(filename varchar2, media_type varchar2, quality_code integer, the_text clob)
      return self as result,

   overriding map member function to_string
      return varchar2,

   overriding member procedure validate_obj
)
final;
/


create or replace type text_file_tab_t as table of text_file_t;
/

create or replace public synonym cwms_t_text_file for test_file_t;
create or replace public synonym cwms_t_text_file_tab for test_file_tab_t;create type rating_conn_map_tab_t
/**
 * Holds connection information for all source ratings for a virtual rating
 *
 * @see type rating_conn_map_t
 */
is table of rating_conn_map_t;
/


create or replace public synonym cwms_t_rating_conn_map_tab for rating_conn_map_tab_t;

create type rating_value_t
/**
 * Holds one lookup value for an independent parameter for a rating, as well as the
 * associated dependent value or dependent rating sub-table.
 *
 * @see type abs_rating_ind_param_t
 * @see type rating_value_tab_t
 *
 * @member ind_value            The independent value
 * @member dep_value            The dependent value if the independent value is for the highest-position (or only) independent parameter
 * @member dep_rating_ind_param The dependent value if the independent value is not for the highest-position independent parameter
 * @member note_id              The identifier of a rating value note, if any
 */
as object(
   ind_value            binary_double,
   dep_value            binary_double,
   dep_rating_ind_param abs_rating_ind_param_t,
   note_id              varchar2(16),
   /**
    * Zero-parameter constructor. Constructs an object with all fields set to NULL.
    */
   constructor function rating_value_t
   return self as result,
   /**
    * Normal constructor.
    *
    * @param p_rating_ind_param_code The CWMS parameter code for the independent parameter represented by this lookup value
    * @param p_other_ind             A collection of the values of all lower-position independent parameters, if any, that lead to this independent parameter value
    * @param p_other_ind_hash        A hash value used to identify the collection held in the p_other_ind parameter
    * @param p_ind_value             The independent lookup value for this independent parameter
    * @param p_is_extension          A flag ('T' or 'F') that specifies whether this lookup value belongs to a rating ('F') or to a rating extension ('T')
    */
   constructor function rating_value_t(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_other_ind_hash        in varchar2,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result,
   /**
    * Stores this rating_value_t object to the databse
    *
    * @param p_rating_ind_param_code The CWMS parameter code for the independent parameter represented by this lookup value
    * @param p_other_ind             A collection of the values of all lower-position independent parameters, if any, that lead to this independent parameter value
    * @param p_is_extension          A flag ('T' or 'F') that specifies whether this lookup value belongs to a rating ('F') or to a rating extension ('T')
    * @param p_office_id             The office owning the rating value
    */
   member procedure store(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_is_extension          in varchar2,
      p_office_id             in varchar2),
   /**
    * Generates a unique hash code to identify the specified collection of values
    *
    * @param p_other_ind A collection of the values
    *
    * @return a unique hash code to identify the specified collection of values
    */
   static function hash_other_ind(
      p_other_ind in double_tab_t)
   return varchar2      
);
/


create or replace public synonym cwms_t_rating_value for rating_value_t;

create or replace type time_series_range_t
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
   time_series_id varchar2(191),
   start_time     date,
   end_time       date,
   time_zone      varchar2(28),
   minimum_value  binary_double,
   maximum_value  binary_double,
   unit           varchar2(16));
/


create or replace public synonym cwms_t_time_series_range for time_series_range_t;

create type loc_lvl_indicator_tab_t
/**
 * Holds a collection of loc_lvl_indicator_t objects.
 *
 * @see type loc_lvl_indicator_t
 */
is table of loc_lvl_indicator_t;
/


create or replace public synonym cwms_t_loc_lvl_indicator_tab for loc_lvl_indicator_tab_t;

create type entity_t
/**
 * Object representing a single entity in the database
 *
 * @member office_id   The office that owns the entity
 * @member category_id Category describing the type of entity
 * @member entity_id   The text identifier of the entity
 * @member entity_name The name of the entity
 */
as object (
   office_id   varchar2(16),
   category_id varchar2(3),
   entity_id   varchar2(32),
   entity_name varchar2(128)
);
/

create or replace public synonym cwms_t_entity for entity_t;
CREATE TYPE document_tab_t
/**
 * Holds a collection of document identifiers
 *
 * @see type document_obj_t
 */
IS
  TABLE OF document_obj_t;
/


create or replace public synonym cwms_t_document_tab for document_tab_t;

create or replace type loc_lvl_ind_cond_tab_t
/**
 * A collectiion of location level indicator conditions
 *
 * @see type loc_lvl_indicator_cond_t
 * @see type loc_lvl_indicator_t
 */
is table of loc_lvl_indicator_cond_t;
/


create or replace public synonym cwms_t_loc_lvl_ind_cond_tab for loc_lvl_ind_cond_tab_t;
create type tstz_tab_t
/**
 * Type suitable for holding multiple timestamp with time zone values
 */
as table of timestamp with time zone;
/


create or replace public synonym cwms_t_tstz_tab for tstz_tab_t;

create or replace type blob_file_t
/**
 * Holds a blob-based file object
 *
 * @member the_blob The blob content of the file
 */
under file_t (
   the_blob blob,

   constructor function blob_file_t(filename varchar2, media_type varchar2, quality_code integer, description varchar2, the_blob blob)
      return self as result,

   constructor function blob_file_t(filename varchar2, media_type varchar2, quality_code integer, the_blob blob)
      return self as result,

   overriding map member function to_string
      return varchar2,

   overriding member procedure validate_obj
)
final;
/

create or replace type blob_file_tab_t as table of blob_file_t;
/

create or replace public synonym cwms_t_blob_file for blob_file_t;
create or replace public synonym cwms_t_blob_file_tab for blob_file_tab_t;CREATE TYPE lookup_type_tab_t
/**
 * Holds a collection of lookup_type_obj_t objects
 *
 * @see type lookup_type_obj_t
 */
IS
  TABLE OF lookup_type_obj_t;
/


create or replace public synonym cwms_t_lookup_type_tab for lookup_type_tab_t;

CREATE TYPE cat_sub_param_obj_t
-- not documented
AS OBJECT (
   parameter_id      VARCHAR2 (16),
   subparameter_id   VARCHAR2 (32),
   description       VARCHAR2 (80)
);
/


create or replace public synonym cwms_t_cat_sub_param_obj for cat_sub_param_obj_t;

CREATE TYPE characteristic_ref_t
/**
 * Identifies a characteristic
 *
 * @member office_id         The office that owns the characteristic
 * @member characteristic_id The characteristic identifier
 */
AS
  OBJECT
  (
    office_id         VARCHAR2 (16), -- the office id for this ref
    characteristic_id VARCHAR2 (64)  -- the id of this characteristic.
  );
/


create or replace public synonym cwms_t_characteristic_ref for characteristic_ref_t;

CREATE TYPE cat_dss_xchg_tsmap_otab_t
-- not documented
AS TABLE OF cat_dss_xchg_ts_map_obj_t;
/


create or replace public synonym cwms_t_cat_dss_xchg_tsmap_otab for cat_dss_xchg_tsmap_otab_t;

create type pvq_t
/**
 * Holds an undated value and quality code for a specified parameter
 *
 * @member parameter_code The unique parameter code for the value
 * @member value          The value for the parameter
 * @member quality_code   The quality code for the value
 *
 * @since CWMS schema 18.1.6
 * @see type pvq_tab_t
 */
as object(
   parameter_code integer,
   value          binary_double,
   quality_code   integer);
/
grant execute on pvq_t to cwms_user;
create or replace public synonym cwms_t_pvq for pvq_t;

create type rating_conn_map_t
/**
 * Holds connection information for a single source rating for a virtual rating
 *
 */ 
as object(
   ind_params str_tab_t, 
   dep_param  varchar2(4),
   units      str_tab_t,
   functions  str_tab_t
);
/


create or replace public synonym cwms_t_rating_conn_map for rating_conn_map_t;

CREATE TYPE cat_timezone_obj_t
-- not documented
AS OBJECT (
   timezone_name   VARCHAR2 (28),
   utc_offset      INTERVAL DAY (2)TO SECOND (6),
   dst_offset      INTERVAL DAY (2)TO SECOND (6)
);
/


create or replace public synonym cwms_t_cat_timezone_obj for cat_timezone_obj_t;

CREATE TYPE lookup_type_obj_t
/**
 * Holds data from one of several similarly-structured tables in the database.
 * Primarily used to hold brief names and descriptions for REGI/ROWCPS application.
 *
 * @see type lookup_table_tab_t
 *
 * @member office_id     The office that owns the information
 * @member display_value The brief name or identifier
 * @member tooltip       The longer description, often targeted for a tooltip
 * @member active        A flag ('T' or 'F') that specifies whether this item is active
 */
AS
  OBJECT
  (
    office_id     VARCHAR2 (16),      -- the office id for this lookup type
    display_value VARCHAR2(25 byte),  --The value to display for this lookup record
    tooltip       VARCHAR2(255 byte), --The tooltip or meaning of this lookup record
    active        VARCHAR2(1 byte)    --Whether this lookup record entry is currently active
  );
/


  
create or replace public synonym cwms_t_lookup_type_obj_t for lookup_type_obj_t;

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
   county_name          VARCHAR2 (60),
   time_zone_name       VARCHAR2 (28),
   location_type        VARCHAR2 (32),
   latitude             NUMBER,
   longitude            NUMBER,
   horizontal_datum     VARCHAR2 (16),
   elevation            NUMBER,
   elev_unit_id         VARCHAR2 (16),
   vertical_datum       VARCHAR2 (16),
   public_name          VARCHAR2 (57),
   long_name            VARCHAR2 (80),
   description          VARCHAR2 (1024),
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


create or replace public synonym cwms_t_location_obj for location_obj_t;

create type timestamp_tab_t
/**
 * Type suitable for holding multiple timestamp values
 */
as table of timestamp;
/


create or replace public synonym cwms_t_timestamp_tab for timestamp_tab_t;


create type streamflow_meas_t
/**
 * Holds a stream flow measurement
 * @since CWMS 3.0
 *
 * @member location       The location for this measurement
 * @member meas_number    The serial number of the measurement
 * @member date_time      The date and time the measurement was performed
 * @member used           Flag (T/F) indicating if the discharge measurement is marked as used
 * @member party          The person(s) that performed the measurement
 * @member agency_id      The agency that performed the measurement
 * @member gage_height    Gage height as shown on the inside staff gage or read off the recorder inside the gage house
 * @member flow           The computed discharge
 * @member cur_rating_num The number of the rating used to calculate the streamflow from the gage height
 * @member shift_used     The current shift being applied to the rating
 * @member pct_diff       The percent difference between the measurement and the rating with the shift applied
 * @member quality        The relative quality of the measurement
 * @member delta_height   The amount the gage height changed while the measurement was being made
 * @member delta_time     The amount of time elapsed while the measurement was being made (hours)
 * @member ctrl_cond_id   The condition of the rating control at the time of the measurement
 * @member flow_adj_id    The adjustment code for the measured discharge
 * @member remarks        Any remarks about the rating
 * @member time_zone      The time zone of the date_time field
 * @member height_unit    The unit of the gage_height, shift_used, and delta_height fields
 * @member flow_unit      The unit of the flow field
 * @member temp_unit      The unit of the temperature fields
 * @member air_temp       The air temperature at the location when the measurement was performed
 * @member water_temp     The water temperature at the location when the measurement was performed
 * @member wm_comments    Comments about the rating by water management personnel
 */
as object (
   location       location_ref_t,
   meas_number    varchar2(8),
   date_time      date,
   used           varchar2(1),
   party          varchar2(12),
   agency_id      varchar2(32),
   gage_height    binary_double,
   flow           binary_double,
   cur_rating_num varchar2(4),
   shift_used     binary_double,
   pct_diff       binary_double,
   quality        varchar2(1),
   delta_height   binary_double,
   delta_time     binary_double,
   ctrl_cond_id   varchar2(20),
   flow_adj_id    varchar2(4),
   remarks        varchar2(256),
   time_zone      varchar2(28),
   height_unit    varchar2(16),
   flow_unit      varchar2(16),
   temp_unit      varchar2(16),
   air_temp       binary_double,
   water_temp     binary_double,
   wm_comments    varchar2(256),

   /**
    * Constructs a streamflow_meas_t object from one record of a rdb-formated measurement from USGS NWIS
    *
    * @param p_rdb_line   The rdb-formatted record
    * @param p_office_id  The office to construct the measurement for. If not specified or NULL, the session user's default office is used
    */
   constructor function streamflow_meas_t (
      p_rdb_line  in varchar2,
      p_office_id in varchar2 default null)
      return self as result,
   /**
    * Contstucts a streamflow_meas_t object from an XML document.
    *
    * @param p_xml The XML document. The format required is like:
    * <pre><big>
    * &lt;stream-flow-measurement office-id="SWT" height-unit="ft" flow-unit="cfs" temp_unit="F" used="true"&gt;
    *   &lt;location&gt;TULA&lt;/location&gt;
    *   &lt;number&gt;1737&lt;/number&gt;
    *   &lt;date&gt;2014-01-14T17:08:30Z&lt;/date&gt;
    *   &lt;agency&gt;USGS&lt;/agency&gt;
    *   &lt;party&gt;WZM/JEP&lt;/party&gt;
    *   &lt;gage-height&gt;.81&lt;/gage-height&gt;
    *   &lt;flow&gt;221&lt;/flow&gt;
    *   &lt;current-rating&gt;19.0&lt;/current-rating&gt;
    *   &lt;shift-used&gt;.88&lt;/shift-used&gt;
    *   &lt;percent-difference&gt;61.3&lt;/percent-difference&gt;
    *   &lt;quality&gt;Fair&lt;/quality&gt;
    *   &lt;delta-height&gt;-.02&lt;/delta-height&gt;
    *   &lt;delta-time&gt;1.07&lt;/delta-time&gt;
    *   &lt;control-condition&gt;CLER&lt;/control-condition&gt;
    *   &lt;flow-adjustment&gt;MEAS&lt;/flow-adjustment&gt;
    *   &lt;remarks/&gt;
    *   &lt;air-temp unit="F"/&gt;
    *   &lt;water-temp unit="F"/&gt;
    *   &lt;wm-comments/&gt;
    * &lt;/stream-flow-measurement&gt;
    * </big></pre>
    */
   constructor function streamflow_meas_t (
      p_xml in xmltype)
      return self as result,
   /**
    * Contstucts a streamflow_meas_t object from an entry in the CWMS database
    *
    * @param p_location    The location of the measurements
    * @param p_date_time   The date and time of the measuerement
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    * @param p_time_zone   The time zone of the p_date_time parameter. If not specified or NULL, the location's time zone is use
    */
   constructor function streamflow_meas_t (
      p_location    in location_ref_t,
      p_date_time   in date,
      p_unit_system in varchar2 default 'EN',
      p_time_zone   in varchar2 default null)
      return self as result,
   /**
    * Contstucts a streamflow_meas_t object from an entry in the CWMS database
    *
    * @param p_location    The location of the measurements
    * @param p_date_time   The serial number of the measurement
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    */
   constructor function streamflow_meas_t (
      p_location    in location_ref_t,
      p_meas_number in varchar2,
      p_unit_system in varchar2 default 'EN')
      return self as result,
   /**
    * Contstucts a streamflow_meas_t object from an entry in the CWMS database
    *
    * @param p_rowid       The row identifier of the measurement's record in the AT_STREAMFLOW_MEAS table.
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    */
   constructor function streamflow_meas_t (
      p_rowid       in urowid,
      p_unit_system in varchar2 default 'EN')
      return self as result,
   /**
    * Sets the height unit for the streamflow_meas_t object, converting all heights to the specified unit
    *
    * @param h_height_unit The height unit to use.  If 'EN' or 'SI' are specified, the height unit is set to the default for or Engilsh or SI unit system, respectively
    */
   member procedure set_height_unit(
      p_height_unit in varchar2),
   /**
    * Sets the flow unit for the streamflow_meas_t object, converting the flow to the specified unit
    *
    * @param h_flow_unit The flow unit to use.  If 'EN' or 'SI' are specified, the flow unit is set to the default for or Engilsh or SI unit system, respectively
    */
   member procedure set_flow_unit(
      p_flow_unit in varchar2),
   /**
    * Sets the time zone for the streamflow_meas_t object, converting the date_time field.
    *
    * @param p_time_zone The time zone to use. If not specified or NULL, the measurement location's local time zone is used.
    */
   member procedure set_time_zone(
      p_time_zone in varchar2 default null),
   /**
    * Stores a streamflow_meas_t object to the database
    */
   member procedure store(
      p_fail_if_exists varchar2),
   /**
    * Returns a streamflow_meas_t object as an XMLTYPE
    *
    * @return The object as an XMLTYPE
    */
   member function to_xml
      return xmltype,
   /**
    * Returns a streamflow_meas_t object as a VARCHAR2.  The preferred name of to_string
    * cause conlicts with JPublisher-generated Java function toString().
    *
    * @return The object as a VARCHAR2
    */
   member function to_string1
      return varchar2
);
/



create or replace public synonym cwms_t_streamflow_meas for streamflow_meas_t;
CREATE TYPE cat_ts_cwms_20_otab_t
-- not documented
AS TABLE OF cat_ts_cwms_20_obj_t;
/


create or replace public synonym cwms_t_cat_ts_cwms_20_otab for cat_ts_cwms_20_otab_t;

CREATE TYPE cat_county_obj_t
-- not documented
AS OBJECT (
   county_id       VARCHAR2 (3),
   county_name     VARCHAR2 (40),
   state_initial   VARCHAR2 (2)
);
/


create or replace public synonym cwms_t_cat_county_obj for cat_county_obj_t;

CREATE TYPE logic_expr_tab_t
/**
 * Hold a collection of logic_expr_t objects
 *
 * @see type logic_expr_t
 */
IS
  TABLE OF logic_expr_t;
/


create or replace public synonym cwms_t_logic_expr_tab for logic_expr_tab_t;

create type date2_tab_t
/**
 * Holds a collection of date pairs
 *
 * @see type date2_t
 */
as table of date2_t;
/


create or replace public synonym cwms_t_date2_tab for date2_tab_t;

create type rating_template_tab_t
/**
 * Holds a collection of rating templates
 *
 * @see type rating_template_t
 */
as table of rating_template_t;
/


create or replace public synonym cwms_t_rating_template_tab for rating_template_tab_t;

create type ts_prof_data_rec_t
/**
 * Holds an undated value and quality code for a specified parameter
 *
 * @member key_parameter A The date/time, value, and quality code of the key parameter in a time series profile.
 * @member assoc_params  A table of parameter values and quality codes associated with the date/time and key parameter value
 *
 * @since CWMS schema 18.1.6
 * @see type pvq_tab_t
 * @see type ts_prof_data_tab_t
 */
as object(
   date_time  date,
   parameters pvq_tab_t);
/
grant execute on ts_prof_data_rec_t to cwms_user;
create or replace public synonym cwms_t_ts_prof_data_rec for ts_prof_data_rec_t;

create type configuration_t
/**
 * Object representing a single configuration in the database
 *
 * @member office_id          The office that owns the configuration
 * @member category_id        Category describing the type of configuration
 * @member configuration_id   The text identifier of the configuration
 * @member configuration_name The name of the configuration
 */
as object (
   office_id          varchar2(16),
   category_id        varchar2(16),
   configuration_id   varchar2(32),
   configuration_name varchar2(128)
);
/

create or replace public synonym cwms_t_configuration for configuration_t;
create type seasonal_loc_lvl_tab_t
-- not documented
is table of seasonal_location_level_t;
/


create or replace public synonym cwms_t_seasonal_loc_lvl_tab for seasonal_loc_lvl_tab_t;

CREATE TYPE gate_change_tab_t
/**
 * Holds information on a collection of gate changes
 *
 * @see type gate_change_obj_t
 */
is
  TABLE OF gate_change_obj_t;
/


create or replace public synonym cwms_t_gate_change_tab for gate_change_tab_t;

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


create or replace public synonym cwms_t_specified_level for specified_level_t;

create type stream_tab_t
/**
 * Holds a collection of streams
 *
 * @see type stream_t
 */
is table of stream_t;
/

create or replace public synonym cwms_t_stream_tab for stream_tab_t;


create or replace TYPE cat_location_obj_t
-- not documented
AS OBJECT (
   db_office_id       VARCHAR2 (16),
   location_id        VARCHAR2 (57),
   base_location_id   VARCHAR2 (24),
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
   public_name        VARCHAR2 (57),
   long_name          VARCHAR2 (80),
   description        VARCHAR2 (512),
   active_flag        VARCHAR2 (1)
);
/


create or replace public synonym cwms_t_cat_location_obj for cat_location_obj_t;

CREATE TYPE cat_county_otab_t
-- not documented
AS TABLE OF cat_county_obj_t;
/


create or replace public synonym cwms_t_cat_county_otab for cat_county_otab_t;

-- drop type location_level_t force;
create or replace type location_level_t
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
 * @member timezone_id                 The time zone of the level_date member
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
 * @member expiration_date             The date/time at which this level expires
 * @member indicators                  The location level indicators associated with this location level
 * @member constituents                The constituents table if this is a virtual location level, one constituent per row. Each row has 3, 5, or 6 values. The first 3 values
 *                                     are the constituent abbreviation, type, and name, respectively. The next values are used only for location level constituents that have
 *                                     attributes, and are the constituent level attribute id, attribute value, and attribute value unit, respectively. If there are only five
 *                                     values, the attribute value is in database storage units for the attribute parameter.
 * @member connections                 The constituents connections string if this is a virtual location level
 * @member vertical_datum              The vertical datum of any elevation values in the level. Null indicates native vertical datum for the location.
 */
is object (
   office_id                   varchar2(16),
   location_id                 varchar2(57),
   parameter_id                varchar2(49),
   parameter_type_id           varchar2(16),
   duration_id                 varchar2(16),
   specified_level_id          varchar2(256),
   level_date                  date,
   timezone_id                 varchar2(28),
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
   tsid                        varchar2(191),
   expiration_date             date,
   seasonal_values             seasonal_value_tab_t,
   indicators                  loc_lvl_indicator_tab_t,
   constituents                str_tab_tab_t,
   connections                 varchar2(256),
   vertical_datum              varchar2(16),
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
    * Returns the full location level identifier
    */
   member function location_level_id
      return varchar2,
   /**
    * Returns the full attribute identifier, if any
    */
   member function attribute_id
      return varchar2,
   /**
    * Converts the location level to the specified time zone. Sets the timzone_id member and converts level_date, expiration_date and interval_origin members
    *
    * @param p_timezone_id The time zone to convert to
    */
   member procedure set_timezone(
      p_timezone_id in varchar2),
   /**
    * Converts the location level to use the specified unit for values. Sets the level_units_id member and converts level_value and seasonal_values members
    *
    * @param p_level_unit The unit to convert the level values to.
    */
   member procedure set_level_unit(
      p_level_unit in varchar2),
   /**
    * Converts the location level to use the specified attribute unit. Sets the attribute_units_id member and converts attribute_value member
    *
    * @param p_attribute_unit The unit to convert the attribute value to.
    */
   member procedure set_attribute_unit(
      p_attribute_unit in varchar2),
   /**
    * Sets the level and attribute units to the default units for the specified unit system
    *
    * @param p_unit_system The unit system to set. Must be ''EN'' or ''SI''
    */
   member procedure set_unit_system(
      p_unit_system in varchar2),
   /**
    * Converts the location level to use the specified vertical datum for elevation values. Sets the vertical_datum member and converts level_value and seasonal_value members
    *
    * @param p_vertical_datum The vertical datum to convert the level elevation values to.
    */
   member procedure set_vertical_datum(
      p_vertical_datum in varchar2),
   /**
    * Converts the location level to use the location native vertical datum for elevation values. Sets the vertical_datum member and converts level_value and seasonal_value members
    */
   member procedure set_to_native_vertical_datum,
   /**
    * Returns whether this is a virtual location level
    */
   member function is_virtual
      return boolean,
   /**
    * Stores the location level to the database
    */
   member procedure store
);
/


create or replace public synonym cwms_t_location_level for location_level_t;

CREATE TYPE cat_location_otab_t
-- not documented
AS TABLE OF cat_location_obj_t;
/


create or replace public synonym cwms_t_cat_location_otab for cat_location_otab_t;

CREATE TYPE characteristic_tab_t
/**
 * Holds a table of characteristics
 *
 * @see type characteristic_obj_t
 */
IS
  TABLE OF characteristic_obj_t;
/


create or replace public synonym cwms_t_characteristic_tab for characteristic_tab_t;

create type abs_rating_ind_param_t
/**
 * Abstract base type for type rating_ind_parameter_t.  This type is necessary to
 * allow ratings to rating_ind_parameter_t objects to have recursive self references
 * through the rating_value_tab_t and rating_value_t types.
 *
 * @see type rating_value_t
 * @see type rating_ind_parameter_t
 *
 * @member constructed A flag ('T' or 'F') specifying whether the construction of
 *         the object has been completed
 */
as object(
   constructed varchar2(1),
   -- not documented
   member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t),
   -- not documented
   member procedure validate_obj(
      p_parameter_position in number),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function to_xml
   return xmltype,
   /**
    * Declaration forcing implemenation in sub-type
    */
   member procedure add_offset(
      p_offset in binary_double,
      p_depth  in pls_integer),    
   /**
    * Declaration forcing implemenation in sub-type
    */
   member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double
      
) not final
  not instantiable;
/


create or replace public synonym cwms_t_abs_rating_ind_param for abs_rating_ind_param_t;

create or replace type vdatum_stream_rating_t
/**
 * Holds a USGS-style stream rating with vertical datum information
 *
 * @see type rating_t
 *
 * @member native_datum   The location's vertical datum in the datbase
 * @member current_datum  The vertical datum the rating is currently represented in
 * @member elev_positions A table of positions in the parameter list that are elevations. Positive positions indicate independent parameters, -1 indicates the dependent parameter.
 */
under stream_rating_t
(
-- office_id       varchar2(16),
-- rating_spec_id  varchar2(380),
-- effective_date  date,
-- transition_date date,
-- create_date     date,
-- active_flag     varchar2(1),
-- formula         varchar2(1000),
-- native_units    varchar2(256),
-- description     varchar2(256),
-- rating_info     rating_ind_parameter_t,
-- current_units   varchar2(1), -- 'D' = database, 'N' = native, other = don't know
-- current_time    varchar2(2), -- 'D' = database, 'L' = native, other = don't know
-- offsets         rating_t,
-- shifts          rating_tab_t,
   native_datum    varchar2(16),
   current_datum   varchar2(16),
   elev_position   number,  
                           
   /**
    * Constructs a vdatum_stream_rating_t object from a stream_rating_t object and a current datum
    *
    * @param p_rating         The existing stream_rating_t object
    * @param p_current_datum  The current datum that the rating object is represented in
    *
    */
   constructor function vdatum_stream_rating_t(
      p_rating         in stream_rating_t,
      p_current_datum  in varchar2
   ) return self as result,
   /**
    * Copy constructor
    */
   constructor function vdatum_stream_rating_t(
      p_other in vdatum_stream_rating_t
   ) return self as result,
   /**
    * Modifies the elevations in the rating to be in the specified datum
    *
    * @param p_vertical_datum The vertical datum to adjust the elevations to
    */   
   member procedure to_vertical_datum(
      p_vertical_datum in varchar2),
   /**
    * Modifies the elevations in the rating to be in the location's local datum
    */      
   member procedure to_native_datum,
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   overriding member function to_clob(
      self         in out nocopy vdatum_stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   overriding member function to_xml(
      self         in out nocopy vdatum_stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return xmltype      
);
/


create or replace public synonym cwms_t_vdatum_stream_rating for vdatum_stream_rating_t;

create type rating_ind_param_spec_t
/**
 * Holds information about an independent parameter for ratings
 *
 * @see cwms_lookup.method_null
 * @see cwms_lookup.method_error
 * @see cwms_lookup.method_linear
 * @see cwms_lookup.method_logarithmic
 * @see cwms_lookup.method_lin_log
 * @see cwms_lookup.method_log_lin
 * @see cwms_lookup.method_previous
 * @see cwms_lookup.method_next
 * @see cwms_lookup.method_nearest
 * @see cwms_lookup.method_lower
 * @see cwms_lookup.method_higher
 * @see cwms_lookup.method_closest
 * @see type rating_ind_param_spec_tab_t
 *
 * @member parameter_position           The parameter position for this independent parameter. 1 specifies the first (or only) independent parameter, etc...
 * @member parameter_id                 The CWMS parameter identifier for this independent parameter
 * @member in_range_rating_method       The rating behavior when a table of values for this independent parameter encompasses the value to be looked up
 * @member out_range_low_rating_method  The rating behavior when the least value in a table of values for this independent parameter is greater than the value to be looked up
 * @member out_range_high_rating_method The rating behavior when the greatest value in a table of values for this independent parameter is less than the value to be looked up
 */
as object(
   parameter_position           number(1),
   parameter_id                 varchar2(49),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   
   /**
    * Constructs a rating_ind_param_spec_t object from a record in the AT_RATING_IND_PARAM_SPEC table
    *
    * @param p_ind_param_spec_code The primary key for the record
    */
   constructor function rating_ind_param_spec_t(
      p_ind_param_spec_code in number)
   return self as result,
   /**
    * Constructs a rating_ind_param_spec_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_ind_param_spec_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure validate_obj,
   /**
    * Retrieves the CWMS parameter code for this independent parameter
    *
    * @param p_office_id Specifies the office for which to retrieve the parameter code
    */
   member function get_parameter_code(
      p_office_id in varchar2)
   return number,
   -- not documented
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   -- not documented
   member function get_in_range_rating_code
   return number,
   -- not documented
   member function get_out_range_low_rating_code
   return number,
   -- not documented
   member function get_out_range_high_rating_code
   return number,
   -- not documented
   member procedure store(
      p_template_code  in number,
      p_fail_if_exists in varchar2),
   -- not documented
   member function to_xml
   return xmltype,      
   -- not documented
   member function to_clob
   return clob      
);
/


create or replace public synonym cwms_t_rating_ind_param_spec for rating_ind_param_spec_t;

create type ts_prof_data_tab_t
/**
 * Holds a table of ts_prof_data_rec_t objects
 *
 * @since CWMS schema 18.1.6
 * @see type ts_prof_data_rec_t
 */
as table of ts_prof_data_rec_t;
/
grant execute on ts_prof_data_tab_t to cwms_user;
create or replace public synonym cwms_t_ts_prof_data_tab for ts_prof_data_tab_t;

create or replace type streamflow_meas2_t
/**
 * Holds a stream flow measurement
 * @since CWMS 3.0
 *
 * @member location       The location for this measurement
 * @member meas_number    The serial number of the measurement
 * @member date_time      The date and time the measurement was performed
 * @member used           Flag (T/F) indicating if the discharge measurement is marked as used
 * @member party          The person(s) that performed the measurement
 * @member agency_id      The agency that performed the measurement
 * @member gage_height    Gage height as shown on the inside staff gage or read off the recorder inside the gage house
 * @member flow           The computed discharge
 * @member cur_rating_num The number of the rating used to calculate the streamflow from the gage height
 * @member shift_used     The current shift being applied to the rating
 * @member pct_diff       The percent difference between the measurement and the rating with the shift applied
 * @member quality        The relative quality of the measurement
 * @member delta_height   The amount the gage height changed while the measurement was being made
 * @member delta_time     The amount of time elapsed while the measurement was being made (hours)
 * @member ctrl_cond_id   The condition of the rating control at the time of the measurement
 * @member flow_adj_id    The adjustment code for the measured discharge
 * @member remarks        Any remarks about the rating
 * @member time_zone      The time zone of the date_time field    
 * @member height_unit    The unit of the gage_height, shift_used, and delta_height fields
 * @member flow_unit      The unit of the flow field
 * @member temp_unit      The unit of the temperature fields
 * @member air_temp       The air temperature at the location when the measurement was performed
 * @member water_temp     The water temperature at the location when the measurement was performed
 * @member wm_comments    Comments about the rating by water management personnel
 * @member supplemental_streamflow The supplemental streamflow data encapsulated in a UDT
 */
as object (
   location       location_ref_t,
   meas_number    varchar2(8),
   date_time      date,
   used           varchar2(1),
   party          varchar2(12),
   agency_id      varchar2(32),
   gage_height    binary_double,
   flow           binary_double,
   cur_rating_num varchar2(4),
   shift_used     binary_double,
   pct_diff       binary_double,
   quality        varchar2(1),
   delta_height   binary_double,
   delta_time     binary_double,
   ctrl_cond_id   varchar2(20),
   flow_adj_id    varchar2(4),       
   remarks        varchar2(256),
   time_zone      varchar2(28),
   height_unit    varchar2(16),
   flow_unit      varchar2(16),
   temp_unit      varchar2(16),
   area_unit      varchar2(16),
   velocity_unit  varchar2(16),
   air_temp       binary_double,
   water_temp     binary_double,
   wm_comments    varchar2(256),
   supp_streamflow_meas supp_streamflow_meas_t,
   /**
    * Constructs a streamflow_meas2_t object from one record of a rdb-formated measurement from USGS NWIS
    *
    * @param p_rdb_line   The rdb-formatted record
    * @param p_office_id  The office to construct the measurement for. If not specified or NULL, the session user's default office is used
    */
   constructor function streamflow_meas2_t (
      p_rdb_line  in varchar2,
      p_office_id in varchar2 default null)
      return self as result,
   /**
    * Contstucts a streamflow_meas2_t object from an XML document.
    *
    * @param p_xml The XML document. The format required is like:
    * <pre><big>
    * &lt;stream-flow-measurement office-id="SWT" height-unit="ft" flow-unit="cfs" temp_unit="F" used="true"&gt;
    *   &lt;location&gt;TULA&lt;/location&gt;
    *   &lt;number&gt;1737&lt;/number&gt;
    *   &lt;date&gt;2014-01-14T17:08:30Z&lt;/date&gt;
    *   &lt;agency&gt;USGS&lt;/agency&gt;
    *   &lt;party&gt;WZM/JEP&lt;/party&gt;
    *   &lt;gage-height&gt;.81&lt;/gage-height&gt;
    *   &lt;flow&gt;221&lt;/flow&gt;
    *   &lt;current-rating&gt;19.0&lt;/current-rating&gt;
    *   &lt;shift-used&gt;.88&lt;/shift-used&gt;
    *   &lt;percent-difference&gt;61.3&lt;/percent-difference&gt;
    *   &lt;quality&gt;Fair&lt;/quality&gt;
    *   &lt;delta-height&gt;-.02&lt;/delta-height&gt;
    *   &lt;delta-time&gt;1.07&lt;/delta-time&gt;
    *   &lt;control-condition&gt;CLER&lt;/control-condition&gt;
    *   &lt;flow-adjustment&gt;MEAS&lt;/flow-adjustment&gt;
    *   &lt;remarks/&gt; 
    *   &lt;air-temp unit="F"/&gt; 
    *   &lt;water-temp unit="F"/&gt;
    *   &lt;wm-comments/&gt; 
    * &lt;/stream-flow-measurement&gt;
    * </big></pre>
    */
   constructor function streamflow_meas2_t (
      p_xml in xmltype)
      return self as result,       
   /**
    * Contstucts a streamflow_meas2_t object from an entry in the CWMS database
    *
    * @param p_location    The location of the measurements
    * @param p_date_time   The date and time of the measuerement
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    * @param p_time_zone   The time zone of the p_date_time parameter. If not specified or NULL, the location's time zone is use 
    */
   constructor function streamflow_meas2_t (
      p_location    in location_ref_t,
      p_date_time   in date,
      p_unit_system in varchar2 default 'EN',
      p_time_zone   in varchar2 default null)
      return self as result,      
   /**
    * Contstucts a streamflow_meas2_t object from an entry in the CWMS database
    *
    * @param p_location    The location of the measurements
    * @param p_date_time   The serial number of the measurement
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    */
   constructor function streamflow_meas2_t (
      p_location    in location_ref_t,
      p_meas_number in varchar2,
      p_unit_system in varchar2 default 'EN')
      return self as result,
   /**
    * Contstucts a streamflow_meas2_t object from an entry in the CWMS database
    *
    * @param p_rowid       The row identifier of the measurement's record in the AT_STREAMFLOW_MEAS table. 
    * @param p_unit_system The unit system (EN/SI) for the height and flow values
    */
   constructor function streamflow_meas2_t (
      p_rowid       in urowid,
      p_unit_system in varchar2 default 'EN')
      return self as result,
   /**
    * Sets the height unit for the streamflow_meas2_t object, converting all heights to the specified unit
    *
    * @param h_height_unit The height unit to use.  If 'EN' or 'SI' are specified, the height unit is set to the default for or Engilsh or SI unit system, respectively
    */ 
   member procedure set_height_unit(
      p_height_unit in varchar2),
   /**
    * Sets the flow unit for the streamflow_meas2_t object, converting the flow to the specified unit
    *
    * @param h_flow_unit The flow unit to use.  If 'EN' or 'SI' are specified, the flow unit is set to the default for or Engilsh or SI unit system, respectively
    */ 
   member procedure set_flow_unit(
      p_flow_unit in varchar2),
   /**
    * Sets the time zone for the streamflow_meas2_t object, converting the date_time field.
    *
    * @param p_time_zone The time zone to use. If not specified or NULL, the measurement location's local time zone is used.
    */
   member procedure set_time_zone(
      p_time_zone in varchar2 default null),
   /**
    * Stores a streamflow_meas2_t object to the database
    */
   member procedure store(
      p_fail_if_exists varchar2),
   /**
    * Returns a streamflow_meas2_t object as an XMLTYPE
    *
    * @return The object as an XMLTYPE
    */
   member function to_xml
      return xmltype,
   /**
    * Returns a streamflow_meas2_t object as a VARCHAR2.  The preferred name of to_string
    * cause conlicts with JPublisher-generated Java function toString().
    *
    * @return The object as a VARCHAR2
    */
   member function to_string1
      return varchar2         
);
/

create or replace public synonym cwms_t_streamflow_meas2 for streamflow_meas2_t;
create type rating_spec_tab_t
/**
 * Holds a collection of rating specifications
 *
 * @see type rating_spec_t
 */
as table of rating_spec_t;
/


create or replace public synonym cwms_t_rating_spec_tab for rating_spec_tab_t;

create type streamflow_meas_tab_t
is table of streamflow_meas_t;
/

create or replace public synonym cwms_t_streamflow_meas_tab for streamflow_meas_tab_t;


create or replace type loc_lvl_cur_max_ind_t
/**
 * Holds a record for AV_LOC_LVL_CUR_MAX_IND view.
 *
 * @since CWMS 2.1
 *
 * @field office_id          Identifies the office that owns the time series
 * @field cwms_ts_id         Identifies the time series
 * @field level_indicator_id Identifies the location level indicator
 * @field attribute_id       Identifies the attribute, if any
 * @field attribute_value    The value of the specified attribute
 * @field max_indicator      The maximum indicator that is currently set
 * @field indicator_name     The name of the indicator
 */
as object(
   office_id          varchar2(16),
   cwms_ts_id         varchar2(191),
   level_indicator_id varchar2(431),
   attribute_id       varchar2(83),
   attribute_value    number,
   max_indicator      number,
   indicator_name     varchar2(256));
/


create or replace public synonym cwms_t_loc_lvl_cur_max_ind for loc_lvl_cur_max_ind_t;

create type xml_tab_t
/**
 * Holds a collection of xmltype objects
 */
is table of xmltype;
/

create or replace public synonym cwms_t_xml_tab for xml_tab_t;
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


create or replace public synonym cwms_t_ts_alias_tab for ts_alias_tab_t;

CREATE TYPE project_structure_obj_t
/**
 * Holds information about a structure at a CWMS project
 *
 * @see type project_structure_tab_t
 *
 * @member project_location_ref Identifies the project
 * @member structure_location   The location information about structure
 * @member characteristic_ref   Identifies the characteristic
 */
AS
  OBJECT
  (
    project_location_ref location_ref_t,           --The project this structure is a child of
    structure_location location_obj_t,                  --The location for this structure
    characteristic_ref characteristic_ref_t   -- the characteristic for this structure.
  );
/


create or replace public synonym cwms_t_project_structure_obj for project_structure_obj_t;

create type seasonal_location_level_t
-- not documented
is object
(
   calendar_offset interval year(2) to month,
   time_offset     interval day(3) to second(0),
   level_value     number
);
/


create or replace public synonym cwms_t_seasonal_location_level for seasonal_location_level_t;

CREATE type water_user_contract_obj_t
/**
 * Holds information about a water user contract
 *
 * @see type water_user_contract_ref_t
 * @see type water_user_contract_tab_t
 *
 * @member water_user_contract_ref       Identifies the water user and contract
 * @member water_supply_contract_type    The type of water supply contract
 * @member ws_contract_effective_date    The effective date of the contract
 * @member ws_contract_expiration_date   The expiration date of the contract
 * @member contracted_storage            The storage under contract
 * @member initial_use_allocation        The initial storage allocation for this contract
 * @member future_use_allocation         The future storage allocation for this contract
 * @member storage_units_id              The unit for storage
 * @member future_use_percent_activated  The percentage of the future storage allocation that has been utilized
 * @member total_alloc_percent_activated The percentage of the total storage allocation that has been utilized
 * @member pump_out_location             The location where water is withrawn from the project, if any
 * @member pump_out_below_location       The location where water is withdrawn below the project, if any
 * @member pump_in_location              The location where water is pumped in to the project, if any
 */
AS
  object
  (
    water_user_contract_ref water_user_contract_ref_t,
    -- contract_documents VARCHAR2(64 BYTE),--The documents for the contract
    water_supply_contract_type lookup_type_obj_t, -- The type of water supply contract. FK'ed to a LU table.
    ws_contract_effective_date DATE,              --The start date of the contract for this water user contract
    ws_contract_expiration_date DATE,             --The expiration date for the contract of this water user contract
    contracted_storage BINARY_DOUBLE,             --Param: Stor. The contracted storage amount for this water user contract
    initial_use_allocation BINARY_DOUBLE,         --Param: Stor. The initial contracted allocation for this water user contract
    future_use_allocation BINARY_DOUBLE,          --Param: Stor. The future contracted allocation for this water user contract
    storage_units_id VARCHAR2(15),                -- the units used for contracted storage and allocations.
    future_use_percent_activated BINARY_DOUBLE,   --Param: ??. The percent allocated future use for this water user contract
    total_alloc_percent_activated BINARY_DOUBLE,  --Param: ??. The percentage of total allocation for this water user contract
    pump_out_location location_obj_t,             -- used to be withdrawal
    pump_out_below_location location_obj_t,       -- used to be supply
    pump_in_location location_obj_t               
  );
/


create or replace public synonym cwms_t_water_user_contract_obj for water_user_contract_obj_t;

CREATE TYPE cat_location2_otab_t
-- not documented
AS TABLE OF cat_location2_obj_t;
/


create or replace public synonym cwms_t_cat_location2_otab for cat_location2_otab_t;

create type number_tab_t
/**
 * Holds a collection of integer or floating point numeric values
 *
 * @see type double_tab_t
 */
is table of number;
/


create or replace public synonym cwms_t_number_tab for number_tab_t;

CREATE type loc_ref_time_window_obj_t
/**
 * Holds a time window for a location
 *
 * @see type loc_ref_time_window_tab_t
 *
 * @member location_ref Identifies the location
 * @member start_date   The beginning of the time window
 * @member end_dete     The end of the time window
 */
AS
  object
  (
    location_ref location_ref_t, 
    start_date DATE,
    end_date DATE
    );
/


create or replace public synonym cwms_t_loc_ref_time_window_obj for loc_ref_time_window_obj_t;

CREATE TYPE characteristic_obj_t
/**
 * Holds information about a characteristic
 *
 * @see type characteristic_ref_t
 * @see type characteristic_tab_t
 *
 * @member characteristic_ref  Identifies the characteristic
 * @member general_description Describes the characteristic
 */
AS
  OBJECT
  (
    characteristic_ref characteristic_ref_t, -- office id and characteristic id
--    opening_parameter_id VARCHAR2 (16),             -- A foreign key to an AT_PARAMETER record that constrains the gate opening to a defined parameter and unit.
--    height BINARY_DOUBLE,                           -- The height of the gate
--    width binary_double,                            -- The width of the gate
--    opening_radius binary_double,                   -- The radius of the pipe or circular conduit that this outlet is a control for.  This is not applicable to rectangular outlets, tainter gates, or uncontrolled spillways
--    opening_units_id VARCHAR2(16),                  -- the units of the opening radius value.
--    elev_invert binary_double,                      -- The elevation of the invert for the outlet
--    flow_capacity_max BINARY_DOUBLE,                --  The maximum flow capacity of the gate
--    flow_units_id VARCHAR2(16),                     -- the units of the flow value.
--    net_length_spillway binary_double,              -- The net length of the spillway
--    spillway_notch_length binary_double,            -- The length of the spillway notch
--    length_units_id            VARCHAR2(16),                   -- the units of the height, width, and length.
    general_description VARCHAR2(255)                   -- description of the outlet characteristic
  );
/


create or replace public synonym cwms_t_characteristic_obj for characteristic_obj_t;

create type time_series_range_tab_t
/**
 * Holds a collection of time series value range objects
 *
 * @see type time_series_range_t
 */
as table of time_series_range_t;
/


create or replace public synonym cwms_t_time_series_range_tab for time_series_range_tab_t;

CREATE TYPE cat_sub_loc_otab_t
-- not documented
AS TABLE OF cat_sub_loc_obj_t;
/


create or replace public synonym cwms_t_cat_sub_loc_otab for cat_sub_loc_otab_t;

CREATE TYPE cat_ts_otab_t
-- not documented
AS TABLE OF cat_ts_obj_t;
/


create or replace public synonym cwms_t_cat_ts_otab for cat_ts_otab_t;

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


create or replace public synonym cwms_t_property_info for property_info_t;

create or replace type vdatum_rating_t
/**
 * Holds a rating with vertical datum information
 *
 * @see type rating_t
 *
 * @member native_datum   The location's vertical datum in the datbase
 * @member current_datum  The vertical datum the rating is currently represented in
 * @member elev_positions A table of positions in the parameter list that are elevations. Positive positions indicate independent parameters, -1 indicates the dependent parameter.
 */
under rating_t
(
-- office_id       varchar2(16),
-- rating_spec_id  varchar2(380),
-- effective_date  date,
-- transition_date date,
-- create_date     date,
-- active_flag     varchar2(1),
-- formula         varchar2(1000),
-- connections     varchar2(80),
-- native_units    varchar2(256),
-- description     varchar2(256),
-- rating_info     rating_ind_parameter_t,
-- current_units   varchar2(1), -- 'D' = database, 'N' = native, other = don't know
-- current_time    varchar2(2), -- 'D' = database, 'L' = native, other = don't know
-- formula_tokens  str_tab_t,
-- source_ratings  rating_tab_t,
   native_datum    varchar2(16),
   current_datum   varchar2(16),
   elev_positions  number_tab_t,

   /**
    * Constructs a vdatum_rating_t object from a rating_t object and a current datum
    *
    * @param p_rating         The existing rating_t object
    * @param p_current_datum  The current datum that the rating object is represented in
    * @param p_elev_positions A table of positions in the parameter list that are elevations. Positive positions indicate independent parameters, -1 indicates the dependent parameter.
    *
    */
   constructor function vdatum_rating_t(
      p_rating         in rating_t,
      p_current_datum  in varchar2,
      p_elev_positions in number_tab_t
   ) return self as result,
   /**
    * Copy constructor
    */
   constructor function vdatum_rating_t(
      p_other in vdatum_rating_t
   ) return self as result,

   /**
    * Modifies the elevations in the rating to be in the specified datum
    *
    * @param p_vertical_datum The vertical datum to adjust the elevations to
    */
   member procedure to_vertical_datum(
      p_vertical_datum in varchar2),
   /**
    * Modifies the elevations in the rating to be in the location's local datum
    */
   member procedure to_native_datum,
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   overriding member function to_clob(
      self         in out nocopy vdatum_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   overriding member function to_xml(
      self         in out nocopy vdatum_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
      return xmltype
);
/

create or replace public synonym cwms_t_vdatum_rating for vdatum_rating_t;
create or replace type ts_alias_t
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
   ts_id         VARCHAR2(191),
   ts_attribute  NUMBER,
   ts_alias_id   VARCHAR2 (256),
   ts_ref_id     VARCHAR2(191)
);
/


create or replace public synonym cwms_t_ts_alias for ts_alias_t;

create or replace TYPE cat_ts_obj_t
-- not documented
AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2(191),
   interval_utc_offset   NUMBER
);
/


create or replace public synonym cwms_t_cat_ts_obj for cat_ts_obj_t;

create type vert_datum_offset_tab_t
/**
 * Holds a table of loc_lvl_cur_max_ind_t records.
 *
 * @since CWMS 2.2
 *
 * @see type vert_datum_offset_t
 */
as table of vert_datum_offset_t;
/
    

create or replace public synonym cwms_t_vert_datum_offset_tab for vert_datum_offset_tab_t;

create type ts_prof_data_t
/**
 * Holds data for a time series profile
 *
 * @param location_code The unique numeric identifier for the location of the profile
 * @param key_parameter The 1-based index into the records(n).parameters table of the key parameter of the profile
 * @param time_zone     The time zone of the data records(n).date_time values
 * @param units         A table of units of the records(n).parameters(m).value values
 * @param values        The profile times and parameter values/quality codes
 *
 * @since CWMS schema 18.1.6
 * @see type ts_prof_data_tab_t
 */
as object(
   location_code integer,
   key_parameter integer,
   time_zone     varchar2(28),
   units         str_tab_t,
   records       ts_prof_data_tab_t);
/
grant execute on ts_prof_data_t to cwms_user;
create or replace public synonym cwms_t_ts_prof_data for ts_prof_data_t;

create type specified_level_tab_t
/**
 * Holds a collection of specified levels
 *
 * @see type specified_level_t
 */
is table of specified_level_t;
/


create or replace public synonym cwms_t_specified_level_tab for specified_level_tab_t;

CREATE TYPE gate_setting_tab_t
/**
 * Holds a collection of gate settings
 *
 * @see type gate_setting_obj_t
 * @see type gate_change_obj_t
 */
is
  TABLE OF gate_setting_obj_t;
/


create or replace public synonym cwms_t_gate_setting_tab for gate_setting_tab_t;

create or replace type uuid_t
/** 
 * Creates and holds UUIDs
 */
as object (
   the_string varchar2(36),
   
   constructor function uuid_t
      return self as result,
      
   map member function to_string
      return varchar2
      
)
final;
/



create or replace type uuid_tab_t as table of uuid_t;
/


create or replace public synonym cwms_t_uuid for uuid_t;
create or replace public synonym cwms_tab_t_uuid for uuid_tab_t;

create type double_tab_tab_t
/**
 * Holds a collection of collections of floating point numeric values in IEEE-754 format
 *
 * @see type double_tab_t
 */
is table of double_tab_t;
/


create or replace public synonym cwms_t_double_tab_tab_t for double_tab_tab_t;

create or replace type location_ref_t
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
   base_location_id varchar2(24),
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


create or replace public synonym cwms_t_location_ref for location_ref_t;

CREATE TYPE cat_state_otab_t
-- not documented
AS TABLE OF cat_state_obj_t;
/


create or replace public synonym cwms_t_cat_state_otab for cat_state_otab_t;

create or replace TYPE cat_ts_cwms_20_obj_t
-- not documented
AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2(191),
   interval_utc_offset   NUMBER (14),
   user_privileges       NUMBER,
   inactive              NUMBER,
   lrts_timezone         VARCHAR2 (28)
);
/


create or replace public synonym cwms_t_cat_ts_cwms_20_obj for cat_ts_cwms_20_obj_t;

CREATE TYPE cat_loc_alias_obj_t
-- not documented
AS OBJECT (
   office_id   VARCHAR2 (16),
   cwms_id     VARCHAR2 (16),
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/


create or replace public synonym cwms_t_cat_loc_alias_obj for cat_loc_alias_obj_t;

create type jms_map_msg_tab_t
-- not documented
as table of sys.aq$_jms_map_message;
/


create or replace public synonym cwms_t_jms_map_msg_tab for jms_map_msg_tab_t;

create type rating_tab_t
/**
 * Holds a collection of ratings
 *
 * @see type rating_t
 */
as table of rating_t;
/


create or replace public synonym cwms_t_rating_tab for rating_tab_t;

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


create or replace public synonym cwms_t_date2 for date2_t;

create or replace type stream_rating_t
/**
 * Holds a USGS-style stream rating with shifts and offsets
 *
 * @see type rating_t
 *
 * @member offsets The logarithmic stage interpolation offsets, if any to use with the rating
 * @member shifts  The stage shifts, if any, to use with the rating
 */
under rating_t (
-- office_id       varchar2(16),
-- rating_spec_id  varchar2(380),
-- effective_date  date,
-- transition_date date,
-- create_date     date,
-- active_flag     varchar2(1),
-- formula         varchar2(1000),
-- native_units    varchar2(256),
-- description     varchar2(256),
-- rating_info     rating_ind_parameter_t,
-- current_units   varchar2(1), -- 'D' = database, 'N' = native, other = don't know
-- current_time    varchar2(2), -- 'D' = database, 'L' = native, other = don't know
   offsets         rating_t,
   shifts          rating_tab_t,
   
   /**
    * Construct a stream_rating_t object from data in the database.
    *
    * @param p_rating_code The primary key of the AT_RATING table
    */
   constructor function stream_rating_t(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T')
   return self as result,
   /**
    * Construct a stream_rating_t object from data in the database.
    *
    * @param p_rating_spec_id The rating specification of the rating to construct
    * @param p_effective_date The effective date
    * @param p_match_date     A flag ('T' or 'F') specifying whether the p_effective_date parameter is to be matched exactly.  If 'F', the latest effective date on or before p_effective_date will be used.
    * @param p_time_zone      The time zone for p_effective_date.  If NULL, the local time zone of the rating's location will be used.
    * @param p_office_id      The office owning the rating.  If NULL, the session user's default office will be used
    */
   constructor function stream_rating_t(
      p_rating_id      in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_usgs-stream-rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function stream_rating_t(
      p_xml in xmltype)
   return self as result,
   /**
    * Construction one stream_rating_t object from another.
    *
    * @param p_other another object of type stream_rating_t or one of its subclasses
    */   
   constructor function stream_rating_t(
      p_other in stream_rating_t)
   return self as result,
   -- not documented
   overriding member procedure init(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T'),
   -- not documented
   member procedure init(
      p_other in stream_rating_t),
   -- not documented
   overriding member procedure validate_obj(
      p_include_points in varchar2 default 'T'),
   /**
    * Sets all rating values of this rating to database storage units, converting if necessary
    */
   overriding member procedure convert_to_database_units,
   /**
    * Sets all rating values of this rating to native units, converting if necessary
    */
   overriding member procedure convert_to_native_units,
   /**
    * Sets the times of this rating to UTC, converting if necessary
    */
   overriding member procedure convert_to_database_time,
   /**
    * Sets the times of this rating to the local time of the rating's location, converting if necessary
    */
   overriding member procedure convert_to_local_time,
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   overriding member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @param p_replace A flag('T' or 'F') that specifies whether any existing rating
    *        should be completely replaced even if the base ratings are the same.
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Flag</th>
    *     <th class="descr">Behavior</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">'T'</td>
    *     <td class="descr">The existing rating will be completely replaced with this one, even if the only difference is a new shift</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">'F'</td>
    *     <td class="descr">If this rating differs from the existing one only by the existence of a new shift, only the new shift is stored</td>
    *   </tr>
    * </table>
    *  
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2,
      p_replace        in varchar2),
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   overriding member function to_clob(
      self         in out nocopy stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   overriding member function to_xml(
      self         in out nocopy stream_rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)
   return xmltype,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in binary_double)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in tsv_array)
   return tsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in tsv_type)
   return tsv_type,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   overriding member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array,
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type,      
   /**
    * Reverse rate the specified dependent values
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   overriding member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type,     
   -- not documented
   member procedure trim_to_effective_date(
      p_date_time in date),
   -- not documented
   member procedure trim_to_create_date(
      p_date_time in date),
   -- not documented
   member function latest_shift_date
   return date      
) not final;
/


create or replace public synonym cwms_t_stream_rating for stream_rating_t;

create type property_info_tab_t
/**
 * Holds a collection of property keys
 *
 * @see type property_info_t
 * @see type property_info2_tab_t
 */
as table of property_info_t;
/


create or replace public synonym cwms_t_property_info_tab for property_info_tab_t;

CREATE TYPE embankment_tab_t
/**
 * Holds a collection of embankment_obj_t objects
 *
 * @see type embankment_obj_t
 */
IS
  TABLE OF embankment_obj_t;
/


create or replace public synonym cwms_t_embankment_tab for embankment_tab_t;

CREATE TYPE cat_dss_xchg_set_otab_t
-- not documented
AS TABLE OF cat_dss_xchg_set_obj_t;
/


create or replace public synonym cwms_t_cat_dss_xchg_set_otab for cat_dss_xchg_set_otab_t;

create type vert_datum_offset_t
/**
 * Holds a vertical datum conversion offset for a location
 *
 * @since CWMS 2.2
 *
 * @field location            The location the offset applies to
 * @field vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
 * @field vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
 * @field effective_date      The date and time the offset became effective.  The date 01-JAN-1000 represents a long-ago effective date
 * @field time_zone           The time zone of the effective date field
 * @field offset              The offset that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
 * @field unit                The unit of the offset
 * @field description         A description of the offset
 *
 * @see type location_ref_t
 * @see type vert_datum_offset_tab_t
 *
 */
as object(
   location            location_ref_t,
   vertical_datum_id_1 varchar2(16),
   vertical_datum_id_2 varchar2(16),
   effective_date      date,
   time_zone           varchar2(28),
   offset              binary_double,
   unit                varchar2(16),
   description         varchar2(64));
/
  

create or replace public synonym cwms_t_vert_datum_offset for vert_datum_offset_t;

CREATE type wat_usr_contract_acct_obj_t
/**
 * Holds a water user contract accounting record
 *
 * @see type wat_usr_contract_acct_tab_t
 *
 * @member water_user_contract_ref Identifies the water user contract
 * @member pump_location_ref       The location of the pump for this accounting record
 * @member physical_transfer_type  Identifies the type of water transfer for this accounting record
 * @member pump_flow               The pump flow for this accounting record
 * @member transfer_start_datetime The beginning time for the water transfer for this accounting record
 * @member accounting_remarks      Remarks for this accounting record
 */
AS
  object
  (
    water_user_contract_ref water_user_contract_ref_t,--The contract for this water movement. SEE AT_WATER_USER_CONTRACT.
    pump_location_ref location_ref_t, --the contract pump that was used for this accounting.
    physical_transfer_type lookup_type_obj_t,         --The type of transfer for this water movement.  See AT_PHYSICAL_TRANSFER_TYPE_CODE.
    pump_flow binary_double,                  --Param: Flow. The flow associated with the water accounting record
    transfer_start_datetime date,                     --The date this water movement began, DATE includes the time zone.
    accounting_remarks varchar2(255 byte)             --Any comments regarding this water accounting movement
  );
/


create or replace public synonym cwms_t_wat_usr_cntrct_acct_obj for wat_usr_contract_acct_obj_t;

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


create or replace public synonym cwms_t_log_message_properties for log_message_properties_t;

CREATE TYPE loc_ref_time_window_tab_t
/**
 * Holds a collection of location time windows
 */
IS
  TABLE OF loc_ref_time_window_obj_t;
/


create or replace public synonym cwms_t_loc_ref_time_window_tab for loc_ref_time_window_tab_t;

create type location_level_tab_t
/**
 * Holds a collection of location levels
 *
 * @see type location_level_t
 */
is table of location_level_t;
/


create or replace public synonym cwms_t_location_level_tab for location_level_tab_t;

CREATE TYPE water_user_contract_tab_t
/**
 * Holds a collection of water_user_contract_obj_t objects
 *
 * @see type water_user_contract_obj_t
 */
IS
  TABLE OF water_user_contract_obj_t;
/


create or replace public synonym cwms_t_water_user_contract_tab for water_user_contract_tab_t;

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


create or replace public synonym cwms_t_property_info2 for property_info2_t;

create or replace type rating_spec_t
/**
 * Holds a rating specification. A rating specification is identified by a location,
 * a rating template, and a version. It also contains information about
 * <ul>
 *   <li>rating behaviors for when the date of a rated value falls before, within, or after the range of rating effective dates</li>
 *   <li>flags for whether the the specification is active and for automated updating procedures</li>
 *   <li>how values for independent and dependent parameters are rounded for public display</li>
 * </ul>
 *
 * @see cwms_lookup.method_null
 * @see cwms_lookup.method_error
 * @see cwms_lookup.method_linear
 * @see cwms_lookup.method_previous
 * @see cwms_lookup.method_next
 * @see cwms_lookup.method_nearest
 * @see cwms_lookup.method_lower
 * @see cwms_lookup.method_higher
 * @see cwms_lookup.method_closest
 * @see type cwms_rating_spec_tab_t
 *
 * @member office_id                    The office that owns the rating spec
 * @member location_id                  The location for the rating spec
 * @member template_id                  The rating template for the rating spec
 * @member version                      The version of the rating spec
 * @member source_agency_id             The agency that provides ratings for the rating spec
 * @member in_range_rating_method       The rating behavior when the effective dates of the ratings encompass the date of a value being rated
 * @member out_range_low_rating_method  The rating behavior when the earliest of effective dates of the ratings is later than the date of a value being rated
 * @member out_range_high_rating_method The rating behavior when the latest of effective dates of the ratings is earlier than the date of a value being rated
 * @member active_flag                  A flag ('T' or 'F') specifying whether this rating spec is active
 * @member auto_update_flag             A flag ('T' or 'F') specifying whether new ratings with this rating spec should automatically be loaded into the database
 * @member auto_activate_flag           A flag ('T' or 'F') specifying whether newly-loaded ratings with this rating spec should automatically be marked as active
 * @member auto_migrate_ext_flag        A flag ('T' or 'F') specifying whether newly-loaded ratings with this rating spec should automatically have previously-defined rating extensions applied
 * @member ind_rounding_specs           USGS-style rounding specifications for each of the independent parameters. Used for public display of data rated by ratings under this rating spec.  Multiple rounding specs are separated by <a href="pkg_cwms_rating.html#separator3">','</a>
 * @member dep_rounding_spec            USGS-style rounding specifications for each of the dependent parameter. Used for public display of data rated by ratings under this rating spec.
 * @member description                  A description of this rating spec
 */
as object(
   office_id                    varchar2(16),
   location_id                  varchar2(57),
   template_id                  varchar2(289), -- template.parameters_id + template.version
   version                      varchar2(32),
   source_agency_id             varchar2(32),
   in_range_rating_method       varchar2(32),
   out_range_low_rating_method  varchar2(32),
   out_range_high_rating_method varchar2(32),
   active_flag                  varchar2(1),
   auto_update_flag             varchar2(1),
   auto_activate_flag           varchar2(1),
   auto_migrate_ext_flag        varchar2(1),
   ind_rounding_specs           str_tab_t,
   dep_rounding_spec            varchar2(10),
   description                  varchar2(256),
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_rating_spec_code The primary key for the table record
    */
   constructor function rating_spec_t(
      p_rating_spec_code in number)
   return self as result,
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_location_id The location for the rating spec
    * @param p_template_id The rating template for the rating spec
    * @param p_version     The version of the rating spec
    * @param p_office_id   The office that owns the rating spec. If NULL or not specified, the session user's default office will be used.
    */
   constructor function rating_spec_t(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return self as result,      
   /**
    * Constructs a rating_spec_t object from a record in the AT_RATING_SPEC table
    *
    * @param p_rating_id The rating identifier. A rating identifier is comprised of the location_id, template_id, and version, separated by <a href="pkg_cwms_rating.html#separator1">'.'</a>
    * @param p_office_id The office that owns the rating spec. If NULL or not specified, the session user's default office will be used.
    */
   constructor function rating_spec_t(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_spec_t object from an XML instance. The XML instance
    * must conform to the <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Rating XML Schema</a>. The rating spec
    * portion is <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-spec">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_spec_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure init(
      p_rating_spec_code in number),
   -- not documented
   member procedure init(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null),
   -- not documented
   member procedure validate_obj,
   -- not documented
   member function get_location_code
   return number,
   -- not documented
   member function get_template_code
   return number,
   -- not documented
   member function get_source_agency_code
   return number,
   -- not documented
   member function get_rating_code(
      p_rating_id in varchar2)
   return number,
   -- not documented
   member function get_in_range_rating_code
   return number,     
   -- not documented
   member function get_out_range_low_rating_code
   return number,     
   -- not documented
   member function get_out_range_high_rating_code
   return number,
   /**
    * Stores the rating specification to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating specification already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating specification already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),     
   /**
    * Retrieves the rating specification as an XML instance in a CLOB object
    *
    * @return the rating specification as an XML instance in a CLOB object
    */
   member function to_clob
   return clob,
   /**
    * Retrieves the rating specification as an XML instance in an XMLTYPE object
    *
    * @return the rating specification as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,
   -- not documented
   static function get_rating_spec_code(
      p_location_id in varchar2,
      p_template_id in varchar2,
      p_version     in varchar2,
      p_office_id   in varchar2 default null)
   return number,      
   -- not documented
   static function get_rating_spec_code(
      p_rating_id in varchar2,
      p_office_id in varchar2 default null)
   return number
);
/


create or replace public synonym cwms_t_rating_spec for rating_spec_t;

create or replace type zloc_lvl_indicator_t
-- not documented
is object
(
   level_indicator_code     number(14),
   location_code            number(14),
   specified_level_code     number(14),
   parameter_code           number(14),
   parameter_type_code      number(14),
   duration_code            number(14),
   attr_value               number,
   attr_parameter_code      number(14),
   attr_parameter_type_code number(14),
   attr_duration_code       number(14),
   ref_specified_level_code number(14),
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


create or replace public synonym cwms_t_zloc_lvl_indicator for zloc_lvl_indicator_t;
CREATE TYPE cat_state_obj_t
-- not documented
AS OBJECT (
   state_initial   VARCHAR2 (2),
   state_name      VARCHAR2 (40)
);
/


create or replace public synonym cwms_t_cat_state_obj for cat_state_obj_t;

CREATE TYPE cat_param_otab_t
-- not documented
AS TABLE OF cat_param_obj_t;
/


create or replace public synonym cwms_t_cat_param_otab for cat_param_otab_t;

CREATE TYPE water_user_tab_t
/**
 * Hold a collection of water_user_obj_t objects
 *
 * @see type water_uer_obj_t
 */
IS
  TABLE OF water_user_obj_t;
/


create or replace public synonym cwms_t_water_user_tab for water_user_tab_t;

create type rating_ind_parameter_t
/**
 * Holds rating lookup values and optionally extension lookup values for an independent parameter
 *
 * @member rating_values    The rating lookup values that apply to this independent parameter
 * @member extension_values The rating extension, if any, that applies to this independent parameter
 */
under abs_rating_ind_param_t(
   rating_values      rating_value_tab_t,
   extension_values   rating_value_tab_t,
   /**
    * Zero-parameter constructor.  Constructs a rating_ind_parameter_t object with all fields NULL
    */
   constructor function rating_ind_parameter_t
   return self as result,
   /**
    * Constructs a rating_ind_parameter_t object from a record in the AT_RATING_IND_PARAMETER table.
    * The object will be for the lowest-position (or only) independent parameter for the
    * specified rating code.
    *
    * @param p_rating_code.  The CWMS rating code for which to create the object.
    */
   constructor function rating_ind_parameter_t(
      p_rating_code in number)
   return self as result,
   /**
    * Constructs a rating_ind_parameter_t object from a record in the AT_RATING_IND_PARAMETER table.
    * The object will be for the independent parameter position that is one greater than the
    * length of the p_other_ind parameter and will be for the specific independent parameter
    * values specified in the p_other_ind paramter
    *
    * @param p_rating_code The CWMS rating code for which to create the object.
    * @param p_other_ind   The lower-position independent paramter values for which to construct the object
    */
   constructor function rating_ind_parameter_t(
      p_rating_code in number,
      p_other_ind   in double_tab_t)
   return self as result,
   -- not documented
   constructor function rating_ind_parameter_t(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t,
      p_additional_ind            in binary_double)
   return self as result,
   -- not documented
   constructor function rating_ind_parameter_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   overriding member procedure init(
      p_rating_ind_parameter_code in number,
      p_other_ind                 in double_tab_t),
   -- not documented
   overriding member procedure validate_obj(
      p_parameter_position in number),
   -- not documented
   overriding member procedure convert_to_database_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   -- not documented
   overriding member procedure convert_to_native_units(
      p_parameters_id in varchar2,
      p_units_id      in varchar2),
   -- not documented
   overriding member procedure store(
      p_rating_ind_param_code out number,
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   -- not documented
   overriding member procedure store(
      p_rating_code           in  number,
      p_other_ind             in  double_tab_t,
      p_fail_if_exists        in  varchar2),
   overriding member function to_clob(
      p_ind_params   in double_tab_t default null,
      p_is_extension in boolean default false)
   return clob,
   -- not documented
   overriding member function to_xml
   return xmltype,
   -- not documented
   overriding member procedure add_offset(
      p_offset in binary_double,
      p_depth  in pls_integer),    
   -- not documented
   overriding member function rate(
      p_ind_values  in out nocopy double_tab_t,
      p_position    in            pls_integer,
      p_param_specs in out nocopy rating_ind_par_spec_tab_t)
   return binary_double,
   -- not documented
   static function get_rating_ind_parameter_code(
      p_rating_code in number)
   return number      
);
/


create or replace public synonym cwms_t_rating_ind_parameter for rating_ind_parameter_t;

CREATE TYPE lock_obj_t
/**
 * Holds information about a lock at a CWMS project
 *
 * @member project_location_ref Identifies the CWMS project
 * @member lock_location        The location information about the locak
 * @member volume_per_lockage   The volume of water released for each lockage
 * @member volume_units_id      The unit for lockage volume
 * @member lock_width           The width of the lock
 * @member lock_length          The length of the lock
 * @member minimum_draft        The minimum draft for the lock
 * @member normal_lock_lift     The elevation difference between upstream and downstream pools
 * @member units_id             The unit of length, width, draft, and lift
 * @member maximum_lock_lift    The maximum lift the lock can support
 * @member elev_units_id        The unit of the elevation pool values
 * @member elev_closure_high_water_upper_pool The elevation that a lock closes due to high water in the upper pool
 * @member elev_closure_high_water_lower_pool The elevation that a lock closes due to high water in the lower pool
 * @member elev_closure_low_water_upper_pool The elevation that a lock closes due to lower water in the upper pool
 * @member elev_closure_low_water_lower_pool The elevation that a lock closes due to low water in the lower pool
 * @member elev_closure_high_water_upper_pool_warning
 * @member elev_closure_high_water_lower_pool_warning
 * @member chamber_location_description A single chamber, le main, land side aux, river side main, river side aux.
 */
AS
   OBJECT
   (
      project_location_ref location_ref_t, --The project this lock is a child of
      lock_location location_obj_t,        --The location for this lock
      -- the volume of water discharged for one lockage at
      --normal headwater and tailwater elevations.  this volume includes any flushing water.
      volume_per_lockage binary_double, -- Param: Stor.
      volume_units_id VARCHAR2(16),     -- the units of the volume value.
      lock_width binary_double,         -- Param: Width. The width of the lock chamber
      lock_length binary_double,        -- Param: Length. the length of the lock chamber
      minimum_draft binary_double,      -- Param: Depth. the minimum depth of water that is maintained for vessels for this particular lock
      normal_lock_lift binary_double,   -- Param: Height. The difference between upstream pool and downstream pool at normal elevation.
      units_id VARCHAR2(16),            -- the units id used for width, length, draft, and lift.
      maximum_lock_lift binary_double,  -- Param: Height. The maximum lift the lock can support
      elev_units_id VARCHAR2(16),       -- the units of the elevation pool values
      elev_closure_high_water_upper_pool binary_double, -- Param: Elev-Pool. The elevation that a lock closes due to high water in the upper pool
      elev_closure_high_water_lower_pool binary_double, -- Param: Elev-Pool. The elevation that a lock closes due to high water in the lower pool
      elev_closure_low_water_upper_pool binary_double,  -- Param: Elev-Pool. The elevation that a lock closes due to lower water in the upper pool
      elev_closure_low_water_lower_pool binary_double,  -- Param: Elev-Pool. The elevation that a lock closes due to low water in the lower pool
      elev_closure_high_water_upper_pool_warning binary_double,
      elev_closure_high_water_lower_pool_warning binary_double,
      chamber_location_description lookup_type_obj_t -- A single chamber, le main, land side aux, river side main, river side aux.
   );
/


create or replace public synonym cwms_t_lock_obj for lock_obj_t;

CREATE type TURBINE_SETTING_OBJ_T
/**
 * Holds information about a turbine setting at a CWMS project
 *
 * @see type turbine_setting_tab_t
 * @see type turbine_change_obj_t
 *
 * @member turbine_location_ref Identifies the turbine
 * @member old_discharge        The discharge through the turbine before the setting
 * @member new_discharge        The discharge through the turbine after the setting
 * @member discharge_units      The discharge unit
 * @member real_power           The actual power generated by the turbine after the setting
 * @member scheduled_load       The scheduled load for the turbine at the time of the setting
 * @member generation_units     The unit of power generation and load
 */
AS
  object
  (
  --required
  turbine_location_ref location_ref_t,
  old_discharge binary_double,
  new_discharge binary_double,
  --setting lookup?
  --discharge lookup?

  --not required
  discharge_units varchar2(16),
  real_power binary_double,
  scheduled_load binary_double,
  generation_units varchar2(16)
);
/


create or replace public synonym cwms_t_TURBINE_SETTING_OBJ for TURBINE_SETTING_OBJ_T;

CREATE TYPE wat_usr_contract_acct_tab_t
/**
 * Holds a collection of water user accounting records
 */
IS
  TABLE OF wat_usr_contract_acct_obj_t;
/


create or replace public synonym cwms_t_wat_usr_cntrct_acct_tab for wat_usr_contract_acct_tab_t;

create or replace type ts_extents_tab_t
/**
 * Holds date/time and value extent information for time series (basically at_ts_extents%rowtype)
 *
 * @see ts_extents_t
 *
 */
as table of ts_extents_t;
/

create or replace public synonym cwms_t_ts_extents_tab for ts_extents_tab_t;
CREATE TYPE document_obj_t
/**
 * Holds a document identifier
 *
 * @see type document_tab_t
 *
 * @member office_id   The office that owns the document
 * @member document_id The document identifier
 */
AS
  OBJECT
  (
    office_id   VARCHAR2 (16),    -- the office id for this lookup type
    document_id VARCHAR2(64 BYTE) -- The unique identifier for the individual document, user provided
  );
/


create or replace public synonym cwms_t_document_obj for document_obj_t;

create or replace TYPE cat_loc_obj_t
-- not documented
AS OBJECT (
   office_id        VARCHAR2 (16),
   base_loc_id      VARCHAR2 (24),
   state_initial    VARCHAR2 (2),
   county_name      VARCHAR2 (40),
   timezone_name    VARCHAR2 (28),
   location_type    VARCHAR2 (16),
   latitude         NUMBER,
   longitude        NUMBER,
   elevation        NUMBER,
   elev_unit_id     VARCHAR2 (16),
   vertical_datum   VARCHAR2 (16),
   public_name      VARCHAR2 (57),
   long_name        VARCHAR2 (80),
   description      VARCHAR2 (512)
);
/


create or replace public synonym cwms_t_cat_loc_obj for cat_loc_obj_t;

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
   offset_minutes number,
   value          number,
   /**
    * Constructs a seasonal_value_t object from Oracle interval types instead of integer types
    *
    * @param p_calendar_offset The calendar offset (years and months) into the interval (combined with time offset)
    * @param p_time_offset     The time offset (days, hours and minutes) into the interval (combined with calendar offset)
    * @param p_value           The value at the specified offset into the interval
    */
   constructor function seasonal_value_t(
      p_calendar_offset in yminterval_unconstrained,
      p_time_offset     in dsinterval_unconstrained,
      p_value           in number)
      return self as result,

   member procedure init(
      p_offset_months  in integer,
      p_offset_minutes in integer,
      p_value          in number)
);
/


create or replace public synonym cwms_t_seasonal_value for seasonal_value_t;

CREATE TYPE cat_dss_file_otab_t
-- not documented
AS TABLE OF cat_dss_file_obj_t;
/


create or replace public synonym cwms_t_cat_dss_file_otab for cat_dss_file_otab_t;

create type property_info2_tab_t
/**
 * Holds a collection of properties
 *
 * @see type property_info2_t
 * @see type property_info_tab_t
 */
as table of property_info2_t;
/


create or replace public synonym cwms_t_property_info2_tab for property_info2_tab_t;

create type clob_tab_t
/**
 * Holds a collection of CLOBs
 */
is table of clob;
/


create or replace public synonym cwms_t_clob_tab for clob_tab_t;

CREATE TYPE embankment_obj_t
  /**
   * Holds information about an embankment at a CWMS project
   *
   * @see type embankment_tab_t
   *
   * @member project_location_ref Identifies the CWMS project
   * @member embankment_location  Location information about the embankment
   * @member structure_type       The type of the embankment structure
   * @member upstream_prot_type   The type of upstream protection of the embankment
   * @member downstream_prot_type The type of downstream protection of the embankment
   * @member upstream_sideslope   The slope of the upstream side of the embankment
   * @member downstream_sideslope The slope of the downstream side of the embankment
   * @member structure_length     The length of the embankment
   * @member height_max           The maximum height of the embankment
   * @member top_width            The top width of the embankment
   * @member units_id             The unit of length, height, and width
   */
AS
  OBJECT
  (
    project_location_ref location_ref_t,    --The project this embankment is a child of
    embankment_location location_obj_t,     --The location for this embankment
    structure_type lookup_type_obj_t,       --The lookup code for the type of the embankment structure
    upstream_prot_type lookup_type_obj_t,   --The upstream protection type code for the embankment structure
    downstream_prot_type lookup_type_obj_t, --The downstream protection type codefor the embankment structure
    upstream_sideslope BINARY_DOUBLE,       --Param: ??. The upstream side slope of the embankment structure
    downstream_sideslope BINARY_DOUBLE,     --Param: ??. The downstream side slope of the embankment structure
    structure_length BINARY_DOUBLE,         --Param: Length. The overall length of the embankment structure
    height_max BINARY_DOUBLE,               --Param: Height. The maximum height of the embankment structure
    top_width BINARY_DOUBLE,                --Param: Width. The width at the top of the embankment structure
    units_id VARCHAR2(16)                   --The units id of the lenght, width, and height values
  );
/


create or replace public synonym cwms_t_embankment_obj for embankment_obj_t;

create type log_message_props_tab_t
/**
 * Holds a collection of message properites for a database log message
 *
 * @see type log_message_properties_t
 * @see cwms_msg.parse_log_msg_prop_tab
 */
as table of log_message_properties_t;
/


create or replace public synonym cwms_t_log_message_props_tab for log_message_props_tab_t;

CREATE type gate_setting_obj_t
/**
 * Holds information about a gate setting
 *
 * @see type gate_setting_tab_t
 * @see type gate_change_obj_t
 *
 * @member outlet_location_ref Identifies the gate
 * @member opening             The opening value
 * @member opening_parameter   The opening parameter
 * @member opening_units       The opening unit
 * @member invert_elev         The invert elevation for gates that support variable inverts
 */
AS
  object
  (
  --required
  outlet_location_ref location_ref_t,
  opening binary_double,
  opening_parameter varchar2(49),
  opening_units varchar2(16),
  invert_elev binary_double
  );
/


create or replace public synonym cwms_t_gate_setting_obj for gate_setting_obj_t;

create type streamflow_meas2_tab_t
is table of streamflow_meas2_t;
/

create or replace public synonym cwms_t_streamflow_meas2_tab for streamflow_meas2_tab_t;


CREATE type turbine_change_obj_t
/**
 * Holds information about a turbine change at a CWMS project
 *
 * @see type tubine_change_tab_t
 *
 * @member project_location_ref         Identifies the project
 * @member change_date                  The date/time of the turbine change
 * @member discharge_computation        The discharge computation used for the turbine change
 * @member setting_reason               The reason for the turbine change
 * @member settings                     The individual turbine settings
 * @member elev_pool                    The pool elevation at the time of the turbine change
 * @member elev_tailwater               The tailwater elevation at the time of the turbine change
 * @member elev_units                   The elevation unit
 * @member old_total_discharge_override The total discharge before the turbine change
 * @member new_total_discharge_override The total discharge after the turbine change
 * @member discharge_units              The discharge unit
 * @member change_notes                 Notes about the turbine change
 * @member protected                    A flag ('T' or 'F') specifying whether the turbine change is protected from future updates
 */
AS
  object
  (
      --required
      project_location_ref location_ref_t, --PROJECT_LOCATION_CODE
      change_date date, --xxx_CHANGE_DATE
      
      discharge_computation lookup_type_obj_t, --turbine_discharge_comp_code
      setting_reason lookup_type_obj_t, --turbine_setting_reason_code
      
      settings turbine_setting_tab_t,
      --not required 
      elev_pool binary_double,
      elev_tailwater binary_double,
      elev_units varchar2(16),
      old_total_discharge_override binary_double, --OLD_TOTAL_DISCHARGE_OVERRIDE
      new_total_discharge_override binary_double, --NEW_TOTAL_DISCHARGE_OVERRIDE
      discharge_units  varchar2(16), 
      change_notes VARCHAR2(255 BYTE), --GATE_CHANGE_NOTES
      protected varchar2(1) --PROTECTED_FLAG
);
/


create or replace public synonym cwms_t_turbine_change_obj for turbine_change_obj_t;

create type logic_expr_t
/**
 * Holds a logic expression that can be evaluated to TRUE or FALSE. The logic operator (combinator), if any,
 * is included in the super-type. Logic expressions may be combination expressions (with operators NOT, AND, XOR, and OR) or comparison expressions (without any operator).
 * Comparison expressions are comprised of two arithmetic expressions from simple constants to complex formulae and one comparison operator (comparitor).
 *
 * @member operand_1  The first sub-expression for binary operators (AND, XOR, OR) and the only one for the unary operator (NOT). Used only if this expression contains an operator.
 * @member operand_2  The second sub-expression for binary operators (AND, XOR, OR). Used only if this expression contains an operator.
 * @member expression The comparison expression to be evaluated if this expression does not contain a combinator
 *
 * @see type abs_logic_expr
 * @see variable cwms_util.combinators
 * @see variable cwms_util.comparitors
 *
 */
under abs_logic_expr_t (
-- operator   varchar2(3),
   operand_1  abs_logic_expr_t,
   operand_2  abs_logic_expr_t,
   expression str_tab_tab_t,

   /**
    * Constructs a logic expression object from a text expression.
    *
    * @param p_expr The logic expression in infix (algebraic) or postfix (RPN) notation.
    */
   constructor function logic_expr_t(
      p_expr in varchar2)
      return self as result,
   /**
    * Constructs a logic expression object from its tokenized form.
    *
    * @param p_table The logic expression tokens. This table is consumed during object creation and has length of zero afterward.
    *
    * @see cwms_util.tokenize_logic_expression
    */
   constructor function logic_expr_t(
      p_table in out nocopy str_tab_tab_t)
      return self as result,
   /**
    * Evaluates the logic expression given specific arguments arg1..argN. This evaluation uses the short-circuit behavior of PL/SQL
    * logic operators. The first expression of any operator is always evaluated.  The second expression of binary operators will
    * not be evaluated if it cannot affect the outcome.
    *
    * @param p_args the actual values to use for arg1...argN. Values are assigned
    *        positionally beginning with the specified or default offset
    * @param p_args_offset the offset into <code><big>p_args</big></code> from which
    *        to start assigning values.  If 0 (default) then the arg1 will be assigned
    *        the first value, etc...
    *
    * @return TRUE or FALSE
    *
    * @see cwms_util.eval_expression
    */
   overriding member function evaluate(
      p_args   in double_tab_t,
      p_args_offset in integer default 0)
      return boolean,
   /**
    * Uses the DBMS_OUTPUT package to output a schematic of the evaluation tree
    *
    * @param p_level Depth of the outermost operator. Used for recursive calls only.
    */
   overriding member procedure print(
      p_level in integer default 0),

   overriding member function to_algebraic(
      self in out nocopy logic_expr_t)
      return varchar2,

   overriding member procedure to_algebraic(
      p_expr in out nocopy varchar2),

   overriding member function to_rpn(
      self in out nocopy logic_expr_t)
      return varchar2,

   overriding member procedure to_rpn(
      p_expr in out nocopy varchar2),

   overriding member function to_xml_text(
      self in out nocopy logic_expr_t)
      return varchar2,

   overriding member procedure to_xml_text(
      p_expr in out nocopy varchar2)
);
/

create or replace public synonym cwms_t_logic_expr for logic_expr_t;
create or replace TYPE project_obj_t
/**
 * Holds information about a CWMS project
 *
 * @member project_location               Location identifier of project
 * @member pump_back_location             Location identifier of pump-back to this project, if any
 * @member near_gage_location             Location identifier of the nearest gage to the project
 * @member authorizing_law                The law that authorized construction of the project
 * @member cost_year                      Year that costs are indexed to
 * @member federal_cost                   Federal cost to construct the project
 * @member nonfederal_cost                Non-federal cost to construct the project
 * @member federal_om_cost                Federal cost of annual operation and maintenance
 * @member nonfederal_om_cost             Non-federal cost of annual operation and maintenance
 * @member cost_units_id                  Unit of costs
 * @member remarks                        General remarks about project
 * @member project_owner                  Owner of the project
 * @member hydropower_description         Description of the hydopower at this project, if applicable
 * @member sedimentation_description      Description of the sedimentation at this project, if applicable
 * @member downstream_urban_description   Description of urbanization downstream of this project, if applicable
 * @member bank_full_capacity_description Description of the bank-full capacity at th is project, if applicable
 * @member yield_time_frame_start         Beginning of time window for critical period for this project
 * @member yield_time_frame_end           End of time window for critical period for this project
 */
AS
  OBJECT
  (

    --locations
    --the location associated with this project,
    --an instance of the location type.
    --has the db office id for this project.
    project_location location_obj_t,
    --The location code where the water is pumped back to
    pump_back_location location_obj_t,
    --The location code known as the near gage for the project
    near_gage_location location_obj_t,
    --The law authorizing this project
    authorizing_law VARCHAR2(32),
    --The year the project cost data is from
    cost_year DATE,
    federal_cost       NUMBER, --Param: Currency. The federal cost of this project
    nonfederal_cost    NUMBER, --Param: Currency. The non-federal cost of this project
    federal_om_cost    NUMBER, --Param: Currency. The om federal cost of this project
    nonfederal_om_cost NUMBER, --Param: Currency. the non-federal cost of this project
    -- the units id of the cost fields.
    cost_units_id VARCHAR2(16),
    --The general remarks regarding this project
    --Should this be a  CLOB?
    remarks VARCHAR2(1000),
    --The assigned owner of this project
    project_owner VARCHAR2(255),
    --The description of the hydro-power located at this project
    hydropower_description VARCHAR2(255),
    --The description of the projects sedimentation
    sedimentation_description VARCHAR2(255),
    --The description of the urban area downstream
    downstream_urban_description VARCHAR2(255),
    --The description of the full capacity
    bank_full_capacity_description VARCHAR2(255),
    --The start date of the yield time frame
    yield_time_frame_start DATE,
    --The end date of the yield time frame
    yield_time_frame_end DATE,
    
   constructor function project_obj_t(
      self                             in out nocopy project_obj_t,
      p_project_location               in            location_obj_t,
      p_pump_back_location             in            location_obj_t,
      p_near_gage_location             in            location_obj_t,
      p_authorizing_law                in            varchar2,
      p_cost_year                      in            date,
      p_federal_cost                   in            number,
      p_nonfederal_cost                in            number,
      p_federal_om_cost                in            number,
      p_nonfederal_om_cost             in            number,
      p_remarks                        in            varchar2,
      p_project_owner                  in            varchar2,
      p_hydropower_description         in            varchar2,
      p_sedimentation_description      in            varchar2,
      p_downstream_urban_description   in            varchar2,
      p_bank_full_capacity_descript    in            varchar2,
      p_yield_time_frame_start         in            date,
      p_yield_time_frame_end           in            date)
      return self as result       
   )
/

create or replace public synonym cwms_t_project_obj for project_obj_t;

create type rating_template_t
/**
 * Holds information about a rating template.  Rating templates specify "classes"
 * of ratings by specifying the parameters and lookup behaviors. Templates are
 * then incorporated into rating specifications which add additional information
 * such as specific locations.
 *
 * @see type rating_ind_par_spec_tab_t
 * @see type rating_template_tab_t
 *
 * @member office_id         The office that owns the rating template
 * @member parameters_id     The parameters used by the rating template. Multiple independent parameters are separated by <a href="pkg_cwms_rating.html#separator3">','</a>, the dependent parameter is separated by <a href="pkg_cwms_rating.html#separator2">';'</a>
 * @member version           The version for this parameter. Used to differentiate this template from others with the same parameters
 * @member ind_parameters    The independent parameter(s) specification for this rating template
 * @member dep_parameter_id  The dependent parameter for this rating template
 * @member description       A description of the rating template
 */
as object(
   office_id         varchar2(16),
   parameters_id     varchar2(256),
   version           varchar2(32),
   ind_parameters    rating_ind_par_spec_tab_t,
   dep_parameter_id  varchar2(49),
   description       varchar2(256),
   /**
    * Constructs a rating_template_t object from unique parameters. The parameters_id field is generated from the p_ind_parameters and p_dep_parmeter_id arguments.
    *
    * @param p_office_id         The office that owns the rating template
    * @param p_version           The version for this parameter. Used to differentiate this template from others with the same parameters
    * @param p_ind_parameters    The independent parameter(s) specification for this rating template
    * @param p_dep_parameter_id  The dependent parameter for this rating template
    * @param p_description       A description of the rating template
    */
   constructor function rating_template_t(
      p_office_id         in varchar2,
      p_version           in varchar2,
      p_ind_parameters    in rating_ind_par_spec_tab_t,
      p_dep_parameter_id  in varchar2,
      p_description       in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_template_code the primary key of the table record
    */
   constructor function rating_template_t(
      p_template_code in number)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_office_id     The office that owns the rating template
    * @param p_parameters_id The parameters used by the rating template. Multiple independent parameters are separated by <a href="pkg_cwms_rating.html#separator3">','</a>, the dependent parameter is separated by <a href="pkg_cwms_rating.html#separator2">';'</a>
    * @param p_version       The version for this parameter. Used to differentiate this template from others with the same parameters
    */
   constructor function rating_template_t(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from a row in the AT_RATING_TEMPLATE table
    *
    * @param p_office_id   The office that owns the rating template
    * @param p_template_id The template identifier.  The parameters_id, comprised of the parameters_id and verssion, separated by <a href="pkg_cwms_rating.html#separator1">'.'</a>
    */
   constructor function rating_template_t(
      p_office_id   in varchar2,
      p_template_id in varchar2)
   return self as result,
   /**
    * Constructs a rating_template_t object from an XML instance. The XML instance
    * must conform to the <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Rating XML Schema</a>. The rating template
    * portion is <a href="https://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating-template">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_template_t(
      p_xml in xmltype)
   return self as result,
   -- not documented
   member procedure init(
      p_template_code in number),
   -- not documented
   member procedure init(
      p_office_id     in varchar2,
      p_parameters_id in varchar2,
      p_version       in varchar2),
   -- not documented
   member procedure validate_obj,
   -- not documented
   member function get_office_code
   return number,
   -- not documented
   member function get_dep_parameter_code
   return number,
   /**
    * Stores the rating template to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating template already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating template already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating template as an XML instance in an XMLTYPE object
    *
    * @return the rating template as an XML instance in an XMLTYPE object
    */
   member function to_xml
   return xmltype,
   /**
    * Retrieves the rating template as an XML instance in a CLOB object
    *
    * @return the rating template as an XML instance in a CLOB object
    */
   member function to_clob
   return clob,
   -- not documented
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_id     in varchar2 default null)
   return number,
   -- not documented
   static function get_template_code(
      p_parameters_id in varchar2,
      p_version       in varchar2,
      p_office_code   in number)
   return number,
   -- not documented
   static function get_template_code(
      p_template_id in varchar2,
      p_office_code in number)
   return number
);
/


create or replace public synonym cwms_t_rating_template for rating_template_t;

create or replace type screen_assign_t
/* (non-javadoc)
 * [description needed]
 *
 * @see type screen_assign_array
 *
 * @member cwms_ts_id      [description needed]
 * @member active_flag     [description needed]
 * @member resultant_ts_id [description needed]
 */
AS OBJECT (
   cwms_ts_id        VARCHAR2(191),
   active_flag       VARCHAR2 (1),
   resultant_ts_id   VARCHAR2(191)
);
/


create or replace public synonym cwms_t_screen_assign for screen_assign_t;

CREATE type gate_change_obj_t
/**
 * Holds information about a gate change at a CWMS project
 *
 * @see type gate_change_tab_t
 *
 * @member project_location_ref         Identifies the project
 * @member change_date                  The date/time of the gate change
 * @member elev_pool                    The pool elevation at the time of the gate change
 * @member discharge_computation        The type of discharge computation used
 * @member release_reason               The reason for the gate change
 * @member settings                     Settings of individual gates
 * @member elev_tailwater               The tailwater elevation at the time of the gate change
 * @member elev_units                   The elevation unit
 * @member old_total_discharge_override The discharge before the gate change
 * @member new_total_discharge_override The discharge after the gate change
 * @member discharge_units              The discharge unit
 * @member change_notes                 Notes about the gate change
 * @member protected                    A flag ('T' or 'F') specifying whether this gate change is protected from future updates
 * @member reference_elev               An additional reference elevation if required to describe this gate change
 */
AS
  object
  (
      --required
      project_location_ref location_ref_t, --PROJECT_LOCATION_CODE
      change_date date, --GATE_CHANGE_DATE
      elev_pool binary_double, --ELEV_POOL
      discharge_computation lookup_type_obj_t, --DISCHARGE_COMPUTATION_CODE
      release_reason lookup_type_obj_t, --release_reason_code
      settings gate_setting_tab_t,
      --not required
      elev_tailwater binary_double, --ELEV_TAILWATER
      elev_units varchar2(16), 
      old_total_discharge_override binary_double, --OLD_TOTAL_DISCHARGE_OVERRIDE
      new_total_discharge_override binary_double, --NEW_TOTAL_DISCHARGE_OVERRIDE
      discharge_units  varchar2(16), 
      change_notes VARCHAR2(255 BYTE), --GATE_CHANGE_NOTES
      protected varchar2(1), --PROTECTED_FLAG
      reference_elev binary_double
);
/


create or replace public synonym cwms_t_gate_change_obj_t for gate_change_obj_t;

create type entity_tab_t
/**
 * Holds a collection of entities
 */
as table of entity_t;
/

create or replace public synonym cwms_t_entity_tab for entity_tab_t;
create or replace type file_t
/**
 * Base of any stored file type (blob or clob)
 *
 * @member filename        Name of file (extension should be consistent with media tye)
 * @member media_type      Media type string for file content
 * @member data_entry_date Date/time the file was stored
 * @member quality_code    Value in CWMS_DATA_QUALITY table
 * @member description     Description of file content
 */
as object (
   filename        varchar2(256),
   media_type      varchar2(256),
   data_entry_date timestamp with time zone,
   quality_code    number(14),
   description     varchar2(4000),
   
   map member function to_string
      return varchar2,

   member procedure validate_obj
)
not final
not instantiable;
/


create or replace public synonym cwms_t_file for file_t;create type pvq_tab_t
/**
 * Holds a table of pvq_t objects
 *
 * @since CWMS schema 18.1.6
 * @see type pvq_t
 */
as table of pvq_t;
/
grant execute on pvq_tab_t to cwms_user;
create or replace public synonym cwms_t_pvq_tab for pvq_tab_t;

create or replace type loc_lvl_indicator_t
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
   location_id            varchar2(57),
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
   /**
    * Constructs an object with all member set to null
    */
   constructor function loc_lvl_indicator_t
      return self as result,
   /**
    * Constructor from zloc_lvl_indicator_t
    * @param p_obj The zloc_lvl_indicatort_t to initialize from
    */
   constructor function loc_lvl_indicator_t(
      p_obj in zloc_lvl_indicator_t)
      return self as result,
   /**
    * Constructor from database row
    * @param p_rowid The rowid of the database row to initialize from
    */
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
    * Retrieves the computed values of the indicator condition expressions for specified time series values, conditions, and evaluation time 
    *
    * @see type ztsv_array
    * @see type number_tab_tab_t
    *
    * @param p_ts        The time series to evaluate the conditions against.
    * @param p_unit      The unit of the values in p_ts.  If null, the values are expected to be in database storage units.
    * @param p_condition The condition to evaluate (range = 1..5). If not specified or null, all five condtions will be evalutated.
    * @param p_eval_time The time at which to evaluate the condition expression(s). If not specified or null, one evaluation will be performed
    *                    for every p_ts.date_time value.
    * @param p_time_zone The time zone of p_eval_time (or p_ts.date_time values is p_eval_time is null).  If not specified or NULL, 'UTC' is used.
    *
    * @return The computed values if the indicator condition expressions. The outer dimension of the table will have one inner row for
    *         each evaluation time (one if p_eval_time is not null, one for each p_ts.date_time value otherwise).  The inner rows will
    *         each have have one value (if p_condition is specified) or five values (one for each condition is p_condition is not specified).
    *
    */
   member function get_indicator_expr_values(
      p_ts        in ztsv_array,
      p_unit      in varchar2 default null,
      p_condition in integer  default null,
      p_eval_time in date     default null,
      p_time_zone in varchar2 default null)
      return double_tab_tab_t,
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


create or replace public synonym cwms_t_loc_lvl_indicator for loc_lvl_indicator_t;

create type zloc_lvl_indicator_tab_t
-- not documented
is table of zloc_lvl_indicator_t;
/


create or replace public synonym cwms_t_zloc_lvl_indicator_tab for zloc_lvl_indicator_tab_t;

create or replace TYPE cat_dss_xchg_ts_map_obj_t
-- not documented
AS OBJECT (
   office_id               VARCHAR2 (16),
   cwms_ts_id              VARCHAR2(191),
   dss_pathname            VARCHAR2 (391),
   dss_parameter_type_id   VARCHAR2 (8),
   dss_unit_id             VARCHAR2 (16),
   dss_timezone_name       VARCHAR2 (28),
   dss_tz_usage_id         VARCHAR2 (8)
);
/


create or replace public synonym cwms_t_cat_dss_xchg_ts_map_obj for cat_dss_xchg_ts_map_obj_t;

create type abs_logic_expr_t
/**
 * Holds an abstract logic expression.  This type is used only to allow the sub-type to be recursively defined.
 *
 * @member operator The logic operator (combinator) for this expression, if it has one
 *
 * @see type logic_expr_t
 * @see variable cwms_util.combinators
 *
 */
as object(
   operator varchar2(3),

   member function evaluate(
      p_args   in double_tab_t,
      p_args_offset in integer default 0)
      return boolean,

   member procedure print(
      p_level in integer default 0),

   member function to_algebraic(
      self in out nocopy abs_logic_expr_t)
      return varchar2,

   member procedure to_algebraic(
      p_expr in out nocopy varchar2),

   member function to_rpn(
      self in out nocopy abs_logic_expr_t)
      return varchar2,

   member procedure to_rpn(
      p_expr in out nocopy varchar2),

   member function to_xml_text(
      self in out nocopy abs_logic_expr_t)
      return varchar2,

   member procedure to_xml_text(
      p_expr in out nocopy varchar2)
) not final;
/

create or replace public synonym cwms_t_abs_logic_expr for abs_logic_expr_t;
create or replace type cwms_ts_id_t
/**
 * Type for holding a CWMS time series identifier
 *
 * @see cwms_ts_id_array
 *
 * @member cwms_ts_id the time series identifier
 */
AS OBJECT (
   cwms_ts_id   VARCHAR2(191)
);
/


create or replace public synonym cwms_t_cwms_ts_id for cwms_ts_id_t;

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


create or replace public synonym cwms_t_group_cat for group_cat_t;

create type zlocation_level_t
-- not documented
is object(
   location_level_code           number(14),
   location_code                 number(14),
   specified_level_code          number(14),
   parameter_code                number(14),
   parameter_type_code           number(14),
   duration_code                 number(14),
   location_level_date           date,
   location_level_value          number,
   location_level_comment        varchar2(256),
   attribute_value               number,
   attribute_parameter_code      number(14),
   attribute_param_type_code     number(14),
   attribute_duration_code       number(14),
   attribute_comment             varchar2(256),
   interval_origin               date,
   calendar_interval             interval year(2) to month,
   time_interval                 interval day(3) to second(0),
   interpolate                   varchar2(1),
   ts_code                       number(14),
   expiration_date               date,
   seasonal_level_values         seasonal_loc_lvl_tab_t,
   indicators                    loc_lvl_indicator_tab_t,
   constituents                  str_tab_tab_t,
   connections                   varchar2(256),

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
      p_ts_code                       in number,
      p_expiration_date               in date,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t,
      p_constituents                  in str_tab_tab_t,
      p_connections                   in varchar2),

   member procedure store
);
/


create or replace public synonym cwms_t_zlocation_level for zlocation_level_t;

-- drop type rating_t force;
create or replace type rating_t
/**
 * Holds a rating
 *
 * @see type rating_ind_parameter_t
 * @see type rating_spec_t
 * @see type stream_rating_t
 * @see type rating_tab_t
 *
 * @member office_id       The office that owns the rating
 * @member rating_spec_id  The rating specification identifier
 * @member effective_date  The earliest date/time that the rating is to be in effect
 * @member transition_date The date to start transition (interpolation) from previous rating
 * @member create_date     The date/time that the rating was loaded into the datbase
 * @member active_flag     A flag ('T' or 'F') specifying whether the rating is active
 * @member formula         The formula (algebraic or RPN) for the rating if the rating is formula-based
 * @member connections     The connection strings for the source ratings if the rating is a virtual rating
 * @member native_units    The native units for the rating
 * @member description     The description of the rating
 * @member rating_info     The rating lookup values if the rating is lookup-based
 * @member current_units   A flag ('D' or 'N') specfying whether the lookup values are currently in database storage ('D') or native ('N') units
 * @member current_time    A flag ('D' or 'L') specifying whether the times are currently in database ('D') (=UTC) or rating location local ('L') time zone
 * @member formula_tokens  A collection of formula tokens if the rating is formula-based
 * @member source_ratings  An ordered collection of source rating specifications if the rating is a virtual rating, or alternative ratings if this is a transitional rating
 * @member connections_map A map of data inputs to ratings inputs if the rating is a virtual rating
 * @member conditions      An ordered collection of conditions to test in order to determine which evaluation to return
 * @member evaluations     An ordered collection of tokenized expressions based on alternative ratings.  This collection must be one element longer than the
 *                         conditions collection in order to provide an evaluation in the case that no conditions are met.
 */
as object (
   office_id       varchar2(16),
   rating_spec_id  varchar2(380),
   effective_date  date,                   -- for all ratings
   transition_date date,                   -- for all ratings
   create_date     date,                   -- for all ratings
   active_flag     varchar2(1),
   formula         varchar2(1000),         -- for expression ratings
   connections     varchar2(80),           -- for virtual ratings
   native_units    varchar2(256),          -- for formula, expression, or transitional ratings
   description     varchar2(256),
   rating_info     rating_ind_parameter_t, -- for table ratings
   current_units   varchar2(1), -- 'D' = database, 'N' = native, other = don't know
   current_time    varchar2(2), -- 'D' = database, 'L' = native, other = don't know
   formula_tokens  str_tab_t,              -- for expresison ratings
   source_ratings  str_tab_t,              -- for virtual and transitional ratings
   connections_map rating_conn_map_tab_t,  -- for virtual ratings
   conditions      logic_expr_tab_t,       -- for transitional ratings
   evaluations     str_tab_tab_t,          -- for transitional ratings
   effective_datum varchar2(16),           -- transient for table ratings
   /**
    * Construct a rating_t object for a simple concrete rating.
    *
    * @param p_rating_spec_id  The rating specification identifier
    * @param p_native_units    The native units for the rating
    * @param p_effective_date  The earliest date/time that the rating is to be in effect
    * @param p_active_flag     A flag ('T' or 'F') specifying whether the rating is active
    * @param p_formula         The formula (algebraic or RPN) for the rating if the rating is formula-based
    * @param p_description     The description of the rating
    * @param p_rating_info     The rating lookup values if the rating is lookup-based
    * @param p_office_id       The office that owns the rating
    */
   constructor function rating_t(
      p_rating_spec_id  varchar2,
      p_native_units    varchar2,
      p_effective_date  date,
      p_active_flag     varchar2,
      p_formula         varchar2,
      p_rating_info     rating_ind_parameter_t,
      p_description     varchar2,
      p_office_id       varchar2 default null)
      return self as result,
   /**
    * Construct a rating_t object for a simple concrete rating.
    *
    * @param p_rating_spec_id  The rating specification identifier
    * @param p_native_units    The native units for the rating
    * @param p_effective_date  The earliest date/time that the rating is to be in effect
    * @param p_transition_date The date/time to begin transition (interpolation) from previous rating
    * @param p_active_flag     A flag ('T' or 'F') specifying whether the rating is active
    * @param p_formula         The formula (algebraic or RPN) for the rating if the rating is formula-based
    * @param p_description     The description of the rating
    * @param p_rating_info     The rating lookup values if the rating is lookup-based
    * @param p_office_id       The office that owns the rating
    */
   constructor function rating_t(
      p_rating_spec_id  varchar2,
      p_native_units    varchar2,
      p_effective_date  date,
      p_transition_date date,
      p_active_flag     varchar2,
      p_formula         varchar2,
      p_rating_info     rating_ind_parameter_t,
      p_description     varchar2,
      p_office_id       varchar2 default null)
      return self as result,
   /**
    * Construct a rating_t object from data in the database.
    *
    * @param p_rating_code    The primary key of the AT_RATING table
    * @param p_include_points Specifies whether to include rating points ('T') or just everything else ('F')
    */
   constructor function rating_t(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T')
   return self as result,
   /**
    * Construct a rating_t object from data in the database.
    *
    * @param p_rating_spec_id The rating specification of the rating to construct
    * @param p_effective_date The effective date
    * @param p_match_date     A flag ('T' or 'F') specifying whether the p_effective_date parameter is to be matched exactly.  If 'F', the latest effective date on or before p_effective_date will be used.
    * @param p_time_zone      The time zone for p_effective_date.  If NULL, the local time zone of the rating's location will be used.
    * @param p_office_id      The office owning the rating.  If NULL, the session user's default office will be used
    */
   constructor function rating_t(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return self as result,
   /**
    * Constructs a rating_t object from an XML instance.  The XML
    * instance must conform to the <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.xsd">CWMS Ratings XML Schema</a>.
    * The instance structure is <a href="http://www.hec.usace.army.mil/xmlSchema/CWMS/Ratings.htm#element_rating">documented here</a>.
    *
    * @param p_xml The XML instance
    */
   constructor function rating_t(
      p_xml in xmltype)
   return self as result,
   /**
    * Construction one rating_t object from another.
    *
    * @param p_other another object of type rating_t or one of its subclasses
    */
   constructor function rating_t(
      p_other in rating_t)
   return self as result,
   -- not documented
   member procedure init(
      p_rating_code    in number,
      p_include_points in varchar2 default 'T'),
   -- not documented
   member procedure init(
      p_other in rating_t),
   -- not documented
   member procedure init(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null),
   -- not documented
   member function rating_expr_ind_param_count(
      p_text in varchar2)
      return pls_integer,
   -- not documented
   member procedure parse_source_rating(
      self           in  rating_t, -- to keep from implicity being defined as OUT type
      p_is_rating    out boolean,
      p_rating_part  out varchar2,
      p_units_part   out varchar2,
      p_text         in  varchar2),
   -- not documented
   member procedure parse_connection_part(
      self        in  rating_t, -- to keep from implicity being defined as OUT type
      p_rating    out pls_integer,
      p_ind_param out pls_integer,
      p_conn_part in  varchar2),
   -- not documented
   member procedure validate_obj(
      p_include_points varchar2 default 'T'),
   /**
    * Sets all rating values of this rating to database storage units, converting if necessary
    */
   member procedure convert_to_database_units,
   /**
    * Sets all rating values of this rating to native units, converting if necessary
    */
   member procedure convert_to_native_units,
   /**
    * Sets the times of this rating to UTC, converting if necessary
    */
   member procedure convert_to_database_time,
   /**
    * Sets the times of this rating to the local time of the rating's location, converting if necessary
    */
   member procedure convert_to_local_time,
   -- not documented
   member procedure store(
      p_rating_code    out number,
      p_fail_if_exists in  varchar2),
   /**
    * Stores the rating to the database
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating already exists
    */
   member procedure store(
      p_fail_if_exists in varchar2),
   /**
    * Retrieves the rating as an XML instance in an CLOB object
    *
    * @return the rating as an XML instance in an CLOB object
    */
   member function to_clob(
      self         in out nocopy rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)  
   return clob,
   /**
    * Retrieves the rating as an XML instance in an XMLTYPE object
    *
    * @return the rating as an XML instance in an XMLTYPE object
    */
   member function to_xml(
      self         in out nocopy rating_t,
      p_timezone   in varchar2 default null,
      p_units      in varchar2 default null,
      p_vert_datum in varchar2 default null)  
   return xmltype,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in double_tab_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in double_tab_t)
   return double_tab_t,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate_one(
      p_ind_values in double_tab_t)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in binary_double)
   return binary_double,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in tsv_array)
   return tsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_values in ztsv_array)
   return ztsv_array,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in tsv_type)
   return tsv_type,
   /**
    * Rate the specified independent values
    *
    * @param p_ind_values the values to rate
    *
    * @return the rated values
    */
   member function rate(
      p_ind_value in ztsv_type)
   return ztsv_type,
   /*
    * not documented, called only from CWMS_RATING.RATE
    * only for virtual ratings
    *
    */
   member function rate(
      p_values      in  double_tab_tab_t,
      p_units       in  str_tab_t,
      p_round       in  varchar2,
      p_value_times in  date_table_type,
      p_rating_time in  date,
      p_time_zone   in  varchar2)
   return double_tab_t,
   /*
    * not documented, called only from CWMS_RATING.RATE
    * only for transitional ratings
    *
    */
   member function rate(
      p_values          in double_tab_tab_t,
      p_value_times_utc in date_table_type,
      p_rating_time_utc in date)            
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in double_tab_t)
   return double_tab_t,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in binary_double)
   return binary_double,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in tsv_array)
   return tsv_array,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_values in ztsv_array)
   return ztsv_array,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in tsv_type)
   return tsv_type,
   /**
    * Reverse rate the specified dependent values. This method id valid only if
    * the rating contains a signle independent value.
    *
    * @param p_dep_values the values to rate
    *
    * @return the rated values
    */
   member function reverse_rate(
      p_dep_value in ztsv_type)
   return ztsv_type,
   /*
    * not documented, called only from CWMS_RATING.RATE
    * only for virtual ratings
    *
    */
   member function reverse_rate(
      p_values      in  double_tab_t,
      p_units       in  str_tab_t,
      p_round       in  varchar2,
      p_value_times in  date_table_type,
      p_rating_time in  date,
      p_time_zone   in  varchar2)
   return double_tab_t,
   -- not documented
   member function get_date(
      p_timestr in varchar2)
   return date,
   /**
    * Returns the number of independent paramters for this rating
    *
    * @return the number of independent paramters for this rating
    */
   member function get_ind_parameter_count
   return pls_integer,
   /**
    * Returns the independent parameters for this rating
    *
    * @return the independent parameters for this rating
    */
   member function get_ind_parameters
   return str_tab_t,
   /**
    * Returns the independent paramter at the specified position
    *
    * @param p_position The position (starting at 1) of the independent paramter to retrieve
    *
    * @return the independent paramter at the specified position
    */
   member function get_ind_parameter(
      p_position in integer)
   return varchar2,
   /**
    * Returns the dependent parameter for this rating
    *
    * @return the dependent parameter for this rating
    */
   member function get_dep_parameter
   return varchar2,
   -- not documented
    member function reverse
    return rating_t,
   -- not documented
   static function get_rating_code(
      p_rating_spec_id in varchar2,
      p_effective_date in date     default null,
      p_match_date     in varchar2 default 'F',
      p_time_zone      in varchar2 default null,
      p_office_id      in varchar2 default null)
   return number

) not final;
/

create or replace public synonym cwms_t_rating for rating_t;

create type configuration_tab_t
/**
 * Holds a collection of configurations
 */
as table of configuration_t;
/

create or replace public synonym cwms_t_configuration_tab for configuration_tab_t;
create type rating_ind_par_spec_tab_t
/**
 * Holds information about the independent parameters for a rating
 *
 * @see type rating_ind_param_spec
 */
as table of rating_ind_param_spec_t;
/


create or replace public synonym cwms_t_rating_ind_par_spec_tab for rating_ind_par_spec_tab_t;

CREATE TYPE project_structure_tab_t
/**
 * Holds a collection of project_structure_obj_t objects
 *
 * @see type project_structure_obj_t
 */
IS
  TABLE OF project_structure_obj_t;
/


create or replace public synonym cwms_t_project_structure_tab for project_structure_tab_t;

CREATE TYPE turbine_setting_tab_t
/**
 * Holds information about a collection of turbine settings
 *
 * @see type turbine_setting_obj_t
 * @see type turbine_change_obj_t
 */
is
  TABLE OF turbine_setting_obj_t;
/


create or replace public synonym cwms_t_turbine_setting_tab for turbine_setting_tab_t;

create or replace type date_range_t
/**
 * Object type representing a date/time range such as a time window.
 *
 * @member start_date      The beginning of the date/time range
 * @member end_date        The end of the date/time range
 * @member time_zone       The time zone of the date/time range
 * @member start_inclusive A flag ('T'/'F') specifying whether the date/time range includes start_date
 * @member end_inclusive   A flag ('T'/'F') specifying whether the date/time range includes end_date
function
 */
as object(
   start_date      date,
   end_date        date,
   time_zone       varchar2(28),
   start_inclusive varchar2(1),
   end_inclusive   varchar2(1),
   dummy           char(1), -- dummy member to allow 5-parameter constructor function
   /**
    * 0-parameter constructor: dates undefined - time zone and inclusion flags default to UTC and 'T'
    */
   constructor function date_range_t
      return self as result,
   /**
    * 2-parameter constructor: dates specified - time zone and inclusion flags default to UTC and 'T'
    */
   constructor function date_range_t(
      p_start_date date,
      p_end_date   date)
      return self as result,
   /**
    * 3-parameter constructor: dates and time zone specified - inclusion flags default to 'T'
    */
   constructor function date_range_t(
      p_start_date date,
      p_end_date   date,
      p_time_zone  varchar2)
      return self as result,
   /**
    * 5-parameter constructor: everything specified
    */
   constructor function date_range_t(
      p_start_date      date,
      p_end_date        date,
      p_time_zone       varchar2,
      p_start_inclusive varchar2,
      p_end_inclusive   varchar2)
      return self as result,
   /**
    * Returns the start time in the specified time zone. If start_inclusive = 'F', then the time returned will be one second
    * later than the start_time field.
    *
    * @param p_time_zone The time zone to return the start time in. If NULL or not specified, no time zone conversion is performed
    * @return  The start time in the specified or default time zone
    */
   member function start_time(
      p_time_zone varchar2 default null)
      return date,
   /**
    * Returns the end time in the specified time zone. If start_inclusive = 'F', then the time returned will be one second
    * earlier than the end_time field.
    *
    * @param p_time_zone The time zone to return the start time in. If NULL or not specified, no time zone conversion is performed
    * @return  The end time in the specified or default time zone
    */
   member function end_time(
      p_time_zone varchar2 default null)
      return date,
   /**
    * Returns a string representation of the object
    */
   member function to_string
      return varchar2
);
/

create or replace public synonym cwms_t_date_range for date_range_t;create type double_tab_t
/**
 * Holds a collection of floating point numeric values in IEEE-754 format
 *
 * @see type double_tab_tab_t
 * @see type number_tab_t
 */
is table of binary_double;
/


create or replace public synonym cwms_t_double_tab for double_tab_t;

create type rating_value_note_t
/**
 * Hold a not about a rating value. Rating value notes can apply to multiple rating
 * values.
 *
 * @see type rating_value_note_tab_t
 *
 * @member office_id   The office owning the note
 * @member note_id     The identifier of the note
 * @member description The text of the note
 */
as object(
   office_id   varchar2(16),
   note_id     varchar2(16),
   description varchar2(256),
   -- not documented
   constructor function rating_value_note_t(
      p_note_code in number)
   return self as result,      
   -- not documented
   member function get_note_code
   return number,
   /**
    * Stores a rating value not to the databse
    *
    * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the function
    *        should fail if the rating value note already exists in the database
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is set to 'T' and the
    *            rating value note already exists
    */
   member procedure store(
      p_fail_if_exists in varchar)
);
/


create or replace public synonym cwms_t_rating_value_note for rating_value_note_t;

create type stream_t
/**
 * Holds information about a stream
 *
 * @member office_id            The office that owns the stream
 * @member name                 The name of the stream
 * @member unit                 The unit used in this object for stationing and length
 * @member stationing_starts_ds A flag (T/F) specifying whether stationing increases upstream
 * @member flows_into_stream    The name of the stream that this stream flows into
 * @member flows_into_station   The station on the receiving stream where this stream joins
 * @member flows_into_bank      The bank on the receiving stream where this stream joins
 * @member diverts_from_stream  The name of the stream that this stream diverts from
 * @member diverts_from_station The station on the source stream where this stream diverts
 * @member diverts_from_bank    The bank on the source stream that this stream diverts from
 * @member length               The length of this stream
 * @member average_slope        The average slope in percent of this stream
 * @member comments             Additional comments for this stream
 */
as object(
   office_id            varchar2(16),
   name                 varchar2(49),
   unit                 varchar2(16),
   stationing_starts_ds varchar2(1),
   flows_into_stream    varchar2(49),
   flows_into_station   binary_double,
   flows_into_bank      varchar2(1),
   diverts_from_stream  varchar2(49),
   diverts_from_station binary_double,
   diverts_from_bank    varchar2(1),
   length               binary_double,
   average_slope        binary_double,
   comments             varchar2(256),
   /**
    * Zero-parameter constructor
    * @return A new stream_t object with all fields set to NULL.
    */
   constructor function stream_t
   return self as result,
   /**
    * Constructor from database using location code
    * 
    * @param p_stream_location_code The stream's location code in the database
    * @return A new stream_t object populated from the database
    */
   constructor function stream_t(
      p_stream_location_code in number)
   return self as result,
   /**
    * Constructor from database using location identifier
    *
    * @param p_stream_location_id The stream's location identifier in the database
    * @param p_office_id          The office that owns the stream in the database. If not specified or NULL, the current session user's default office will be used.  
    * @return A new stream_t object populated from the database
    */
   constructor function stream_t(
      p_stream_location_id in varchar2,
      p_office_id          in varchar2 default null)
   return self as result,
   /**
    * Constructor from members. Used for backward compatibility when additional members are added
    *
    * @param p_office_id            The office that owns the stream
    * @param p_name                 The name of the stream
    * @param p_unit                 The unit used in this object for stationing and length
    * @param p_stationing_starts_ds A flag (T/F) specifying whether stationing increases upstream
    * @param p_flows_into_stream    The name of the stream that this stream flows into
    * @param p_flows_into_station   The station on the receiving stream where this stream joins
    * @param p_flows_into_bank      The bank on the receiving stream where this stream joins
    * @param p_diverts_from_stream  The name of the stream that this stream diverts from
    * @param p_diverts_from_station The station on the source stream where this stream diverts
    * @param p_diverts_from_bank    The bank on the source stream that this stream diverts from
    * @param p_length               The length of this stream
    * @param p_average_slope        The average slope in percent of this stream
    * @param p_comments             Additional comments for this stream
    * @return A new stream_t object populated from the parameters
    */
   constructor function stream_t(
      p_office_id            in varchar2,
      p_name                 in varchar2,
      p_unit                 in varchar2,
      p_stationing_starts_ds in varchar2,
      p_flows_into_stream    in varchar2,
      p_flows_into_station   in binary_double,
      p_flows_into_bank      in varchar2,
      p_diverts_from_stream  in varchar2,
      p_diverts_from_station in binary_double,
      p_diverts_from_bank    in varchar2,
      p_length               in binary_double,
      p_average_slope        in binary_double,
      p_comments             in varchar2)
   return self as result,
   /**
    * Converts object from current station/length unit to specified station/length unit
    *
    * @param p_unit The station/length unit to convert to.
    */
   member procedure convert_to_unit(
      p_unit in varchar2),
   /**
    * Stores a stream object to the database
    *
    * @param p_fail_if_exists A flag (T/F) specifying whether to fail if a stream with the same office and name already exists in the database.  Specifying 'F' forces updating any such stream.
    * @param p_ignore_nulls   A flag (T/F) specifying whether to ignore any NULL members in the object when updating an existing object in the database. Specifying 'F' forces any NULL values in the object to overwrite any non-NULL values in the database.
    */
   member procedure store(
      p_fail_if_exists in varchar2,
      p_ignore_nulls   in varchar2)
);
/

create or replace public synonym cwms_t_stream for stream_t;
CREATE TYPE water_user_obj_t
/**
 * Holds information about a water user for a CWMS project
 *
 * @see type water_user_tab_t
 *
 * @member project_location_ref Identifies the CWMS project
 * @member entity_name          The name of the water user
 * @member water_right          The water right for the water user at this project
 */
AS
  OBJECT
  (
    project_location_ref location_ref_t, --The project that this user is pertaining to.
    entity_name VARCHAR2(64 BYTE),       --The entity name associated with this user
    water_right VARCHAR2(255 BYTE)       --The water right of this user (optional)
  );
/


create or replace public synonym cwms_t_water_user_obj for water_user_obj_t;

CREATE TYPE cat_location_kind_obj_t
-- not documented
AS OBJECT (
   office_id        VARCHAR2(16),
   location_kind_id VARCHAR2(32),
   description      VARCHAR2(256)
);
/


create or replace public synonym cwms_t_cat_location_kind_obj for cat_location_kind_obj_t;

CREATE TYPE cat_loc_alias_otab_t
-- not documented
AS TABLE OF cat_loc_alias_obj_t;
/


create or replace public synonym cwms_t_cat_loc_alias_otab for cat_loc_alias_otab_t;

CREATE TYPE cat_param_obj_t
-- not documented
AS OBJECT (
   parameter_id        VARCHAR2 (16),
   param_long_name     VARCHAR2 (80),
   param_description   VARCHAR2 (160),
   unit_id             VARCHAR2 (16),
   unit_long_name      VARCHAR2 (80),
   unit_description    VARCHAR2 (80)
);
/


create or replace public synonym cwms_t_cat_param_obj for cat_param_obj_t;

create type loc_lvl_cur_max_ind_tab_t 
/**
 * Holds a table of loc_lvl_cur_max_ind_t records.
 *
 * @see type loc_lvl_cur_max_ind_t
 */
as table of loc_lvl_cur_max_ind_t;
/


create or replace public synonym cwms_t_loc_lvl_cur_max_ind_tab for loc_lvl_cur_max_ind_tab_t;

create type rating_value_note_tab_t
/**
 * Holds a collection of rating value notes
 *
 * @see type rating_value_note_t
 */
is table of rating_value_note_t;
/


create or replace public synonym cwms_t_rating_value_note_tab for rating_value_note_tab_t;

create type group_cat_tab_t
/**
 * Holds a collection of location group names within specific location categories
 *
 * @see group_cat_t
 * @see cwms_loc.num_group_assigned_to_shef
 */
IS TABLE OF group_cat_t;
/


create or replace public synonym cwms_t_group_cat_tab for group_cat_tab_t;

create type number_tab_tab_t
/**
 * Holds a collection of integer or floating point numeric values
 *
 * @see type double_tab_tab_t
 */
is table of number_tab_t;
/


create or replace public synonym cwms_t_number_tab_tab for number_tab_tab_t;

CREATE TYPE water_user_contract_ref_t
/**
 * Holds minimal information about a water user contract
 *
 * @see water_user_contract_obj_t
 *
 * @member water_user    The water user
 * @member contract_name The identifier for the water user contract
 */
AS
  OBJECT
  (
    water_user water_user_obj_t,   --The water user this record pertains to.  See table AT_WATER_USER.
    contract_name VARCHAR2(64 BYTE)--The identification name for the contract for this water user contract
  );
/


create or replace public synonym cwms_t_water_user_contract_ref for water_user_contract_ref_t;

create type seasonal_value_tab_t
/**
 * Holds a collection of values at specified offsets into a recurring interval
 *
 * @see type seasonal_value_t
 */
is table of seasonal_value_t;
/


create or replace public synonym cwms_t_seasonal_value_tab for seasonal_value_tab_t;

CREATE TYPE cat_dss_xchg_set_obj_t
-- not documented
AS OBJECT (
   office_id                  VARCHAR2 (16),
   dss_xchg_set_id            VARCHAR (32),
   dss_xchg_set_description   VARCHAR (80),
   dss_filemgr_url            VARCHAR2 (32),
   dss_file_name              VARCHAR2 (255),
   dss_xchg_direction_id      VARCHAR2 (16),
   dss_xchg_last_update       TIMESTAMP ( 6 )
);
/


create or replace public synonym cwms_t_cat_dss_xchg_set_obj for cat_dss_xchg_set_obj_t;

create or replace TYPE cat_location2_obj_t
-- not documented
AS OBJECT (
   db_office_id         VARCHAR2 (16),
   location_id          VARCHAR2 (57),
   base_location_id     VARCHAR2 (24),
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
   public_name          VARCHAR2 (57),
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


create or replace public synonym cwms_t_cat_location2_obj for cat_location2_obj_t;

CREATE TYPE cat_dss_file_obj_t
-- not documented
AS OBJECT (
   office_id         VARCHAR2 (16),
   dss_filemgr_url   VARCHAR2 (32),
   dss_file_name     NUMBER (14)
);
/


create or replace public synonym cwms_t_cat_dss_file_obj for cat_dss_file_obj_t;

create type screening_control_t
/* (non-javadoc)
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


create or replace public synonym cwms_t_screening_control for screening_control_t;

CREATE TYPE turbine_change_tab_t
/**
 * Holds a collection of turbine changes
 *
 * @see type turbine_change_obj_t
 */
is
  TABLE OF turbine_change_obj_t;
/


create or replace public synonym cwms_t_turbine_change_tab for turbine_change_tab_t;

create type rating_value_tab_t
/**
 * Holds a collection of rating lookup values
 *
 * @see type rating_value_t
 */
as table of rating_value_t;
/


create or replace public synonym cwms_t_rating_value_tab for rating_value_tab_t;

CREATE TYPE cat_location_kind_otab_t
-- not documented
AS TABLE OF cat_location_kind_obj_t;
/


create or replace public synonym cwms_t_cat_location_kind_otab for cat_location_kind_otab_t;

create type ts_profile_t
/**
 * Holds a definition of a time series profile
 *
 * @param location               The location for the profile
 * @param profile_params         A table of parameters for the profile, in defined position order
 * @param key_parameter_position The 1-based position in the profile_params table of the key parameter
 * @param reference_ts_id        A time series identifier of a reference parameter value (normally Elev) for this profile
 * @param description            A text description of the profile.
 *
 * @since CWMS schema 18.1.6
 * @see type location_ref_t
 */
as object(
   location               location_ref_t,
   key_parameter_id       varchar2(49),
   profile_params         str_tab_t,
   reference_ts_id        varchar2(191),
   description            varchar2(256));
/
grant execute on ts_profile_t to cwms_user;
create or replace public synonym cwms_t_ts_profile for ts_profile_t;

CREATE TYPE cat_loc_otab_t
-- not documented
AS TABLE OF cat_loc_obj_t;
/


create or replace public synonym cwms_t_cat_loc_otab for cat_loc_otab_t;

CREATE TYPE cat_sub_param_otab_t
-- not documented
AS TABLE OF cat_sub_param_obj_t;
/


create or replace public synonym cwms_t_cat_sub_param_otab for cat_sub_param_otab_t;

create type dsinterval_tab_t
/**
 * Type suitable for holding multiple interval day to second values
 */
as table of interval day to second;
/


create or replace public synonym cwms_t_dsinterval_tab for dsinterval_tab_t;

create or replace type loc_lvl_indicator_cond_t
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
 * @member function                   The unit conversion function for absolute magnitude comparison values to convert from specified units to database storage units. <bold>Transient</bold>
 * @member rate_function              The unit conversion function for rate of change comparison values to convert from specified units to database storage units. <bold>Transient</bold>
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
   comparison_unit            number(14),
   connector                  varchar2(3),
   comparison_operator_2      varchar2(2),
   comparison_value_2         binary_double,
   rate_expression            varchar2(64),
   rate_comparison_operator_1 varchar2(2),
   rate_comparison_value_1    binary_double,
   rate_comparison_unit       number(14),
   rate_connector             varchar2(3),
   rate_comparison_operator_2 varchar2(2),
   rate_comparison_value_2    binary_double,
   rate_interval              interval day(3) to second(0),
   description                varchar2(256),
   function                   varchar2(64),
   rate_function              varchar2(64),
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
   /**
    * Evaluates the condition's expression and returns the result
    *
    * param p_value   The value (expression variable V) in the object's comparison unit,
    * param p_level   The level value (expression variable L or L1) in the object's comparison unit,
    * param p_level_2 The referenced level value (expression variable L2) in the object's comparison unit, if a referenced location level is used
    *
    * return The numeric result of evaluation the expression
    */
   member function eval_expression(      
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double)
   return binary_double,
   /**
    * Evaluates the condition's rate expression and returns the result
    *
    * param p_rate The rate of change (expression variable R) in the object's rate comparison unit
    *
    * return The numeric result of evaluation the rate expression
    */
   member function eval_rate_expression(      
      p_rate in binary_double)
   return binary_double,
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


create or replace public synonym cwms_t_loc_lvl_indicator_cond for loc_lvl_indicator_cond_t;
create type rating_ind_param_tab_t
/**
 * Holds a collection of rating_ind_parameter_t objects
 *
 * @see type rating_ind_parameter_t
 */
as table of rating_ind_parameter_t;
/


create or replace public synonym cwms_t_rating_ind_param_tab for rating_ind_param_tab_t;

create type location_ref_tab_t
/**
 * Holds a collection of location references.
 *
 * @see type location_ref_t
 */
is table of location_ref_t;
/


create or replace public synonym cwms_t_location_ref_tab for location_ref_tab_t;

CREATE TYPE cat_timezone_otab_t
-- not documented
AS TABLE OF cat_timezone_obj_t;
/


create or replace public synonym cwms_t_cat_timezone_otab for cat_timezone_otab_t;

CREATE TYPE cat_sub_loc_obj_t
-- not documented
AS OBJECT (
   sublocation_id   VARCHAR2 (32),
   description      VARCHAR2 (80)
);
/


create or replace public synonym cwms_t_cat_sub_loc_obj for cat_sub_loc_obj_t;
