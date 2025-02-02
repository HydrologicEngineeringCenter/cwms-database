create type ztsv_type
/**
 * Object type representing a single time series value. This type does not carry
 * time zone information, so any usage of it needs to explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @member date_time the time of the value, not including time zone
 *
 * @member value the actual time series value
 *
 * @member quality_code the quality assigned to the time series value.
 *
 * @see type tsv_type
 * @see type ztsv_type
 * @see type ztsv_array
 * @see view mv_data_quality
 */
AS OBJECT (
   date_time    DATE,
   VALUE        BINARY_DOUBLE,
   quality_code NUMBER);
/


create or replace public synonym cwms_t_ztsv for ztsv_type;

