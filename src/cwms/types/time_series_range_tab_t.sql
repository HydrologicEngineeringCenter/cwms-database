create type time_series_range_tab_t
/**
 * Holds a collection of time series value range objects
 *
 * @see type time_series_range_t
 */
as table of time_series_range_t;
/


create or replace public synonym cwms_t_time_series_range_tab for time_series_range_tab_t;

