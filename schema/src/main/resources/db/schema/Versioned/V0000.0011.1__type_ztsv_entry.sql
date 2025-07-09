create type ztsv_entry_type under ztsv_type
/**
 * Object type representing a single time series value with the data entry dates.
 * This type does not carry time zone information, so any usage of it needs
 * to explicitly declare the time zone.
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
 * @see type ztsv_entry_array
 */
(data_entry_date   TIMESTAMP);
/