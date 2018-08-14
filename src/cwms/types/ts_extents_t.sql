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
show errors
create or replace public synonym cwms_t_ts_extents for ts_extents_t;

