create type ztsv_entry_array
/**
 * Table of <code><big>ztsv_entry_type</big></code> records. This collection specifies
 * a time series of values for a certain time range with their data entry dates.
 * This type does not carry time zone information, so any usage of it
 * should explicitly declare the time zone.
 * External specification of time series attributes is also required for proper usage.
 *
 * @see type ztsv_entry_array
 * @see type ztsv_entry_array_tab
 */
IS TABLE OF ztsv_entry_type;
/

create or replace public synonym cwms_t_ztsv_entry_array for ztsv_entry_array;
