CREATE TYPE timeseries_type
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
   tsid   VARCHAR2 (183),
   unit   VARCHAR2 (16),
   DATA   tsv_array
);
/


create or replace public synonym cwms_t_timeseries for timeseries_type;

