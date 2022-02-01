create or replace TYPE timeseries_req_type
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
   tsid         VARCHAR2(191),
   unit         VARCHAR2 (16),
   start_time   DATE,
   end_time     DATE
);
/


create or replace public synonym cwms_t_timeseries_req for timeseries_req_type;

