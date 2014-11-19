CREATE TYPE timeseries_req_array
/**
 * Type suitable for requesting the retrieval of multiple time series.
 *
 * @see type timeseries_req_type
 * @see cwms_ts.retrieve_ts_multi
 */
IS TABLE OF timeseries_req_type;
/


create or replace public synonym cwms_t_timeseries_req_array for timeseries_req_array;

