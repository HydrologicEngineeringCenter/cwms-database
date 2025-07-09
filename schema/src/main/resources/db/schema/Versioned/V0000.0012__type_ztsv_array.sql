create type ztsv_array
/**
 * Table of <code><big>ztsv_type</big></code> records. This collection specifies
 * a time series of values for a certain time range.  This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type ztsv_type
 * @see type ztsv_array_tab
 */
IS TABLE OF ztsv_type;
/


create or replace public synonym cwms_t_ztsv_array for ztsv_array;

