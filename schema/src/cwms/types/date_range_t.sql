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
    * 0-parameter constructor - leaves everything undefined
    */
   constructor function date_range_t
      return self as result,
   /**
    * 2-parameter constructor - defines dates leaving time zone and inclusion flags undefined
    */
   constructor function date_range_t(
      p_start_date date,
      p_end_date   date)
      return self as result,
   /**
    * 3-parameter constructor - defines dates and time zone leaving inclusion flags undefined
    */
   constructor function date_range_t(
      p_start_date date,
      p_end_date   date,
      p_time_zone  varchar2)
      return self as result,
   /**
    * 5-parameter constructor - defines everything
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
      return date
);
/

create or replace public synonym cwms_t_date_range for date_range_t;