CREATE TYPE tsv_array
/**
 * Table of <code><big>tsv_type</big></code> records. This collection specifies
 * a time series of values for a certain time range.  This type carries time zone
 * information, so any usage of it should not explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type tsv_type
 * @see type tsv_array_tab
 * @see type ztsv_array
 */
IS TABLE OF tsv_type;
/


create or replace public synonym cwms_t_tsv_array for tsv_array;

