CREATE TYPE timeseries_array
/**
 * Type suitable for holding multiple time series.
 *
 * @see type timeseries_type
 */
IS TABLE OF timeseries_type;
/


create or replace public synonym cwms_t_timeseries_array for timeseries_array;

