CREATE TYPE tsv_type
/**
 * Object type representing a single time series value.  This type carries time zone
 * information, so any usage of it should not explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @member date_time    the time of the value, including time zone
 * @member value        the actual time series value
 * @member quality_code the quality assigned to the time series value.
 *
 * @see type ztsv_type
 * @see view mv_data_quality
 */
AS OBJECT (
   date_time      TIMESTAMP WITH TIME ZONE,
   VALUE          BINARY_DOUBLE,
   quality_code   NUMBER
);
/


create or replace public synonym cwms_t_tsv for tsv_type;

