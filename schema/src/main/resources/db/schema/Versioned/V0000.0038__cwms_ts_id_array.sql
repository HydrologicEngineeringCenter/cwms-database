create type cwms_ts_id_array
/**
 * Type for holding multiple CWMS time series identifiers
 *
 * @see cwms_ts_id_t
 */
IS TABLE OF cwms_ts_id_t;
/


create or replace public synonym cwms_t_cwms_ts_id_array for cwms_ts_id_array;

