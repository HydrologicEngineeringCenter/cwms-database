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

