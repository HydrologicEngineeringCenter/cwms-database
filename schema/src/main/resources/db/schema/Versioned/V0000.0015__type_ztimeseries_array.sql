create type ztimeseries_array
/**
 * Table of <code><big>ztimeseries_type</big></code> records. This type does not carry
 * time zone information, so any usage of it should explicitly declare the time zone.
 */
IS TABLE OF ztimeseries_type;
/


create or replace public synonym cwms_t_ztimeseries_array for ztimeseries_array;

