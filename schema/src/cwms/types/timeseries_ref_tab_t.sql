create type timeseries_ref_tab_t
/**
 * Holds a collection of time series references.
 *
 * @see type timeseries_ref_t
 */
is table of timeseries_ref_t;
/


create or replace public synonym cwms_t_timeseries_ref_tab for timeseries_ref_tab_t;

