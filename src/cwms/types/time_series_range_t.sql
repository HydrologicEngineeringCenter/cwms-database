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

