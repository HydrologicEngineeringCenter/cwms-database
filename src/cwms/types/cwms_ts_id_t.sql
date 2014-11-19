create type cwms_ts_id_t
/**
 * Type for holding a CWMS time series identifier
 *
 * @see cwms_ts_id_array
 *
 * @member cwms_ts_id the time series identifier
 */
AS OBJECT (
   cwms_ts_id   VARCHAR2 (183)
);
/


create or replace public synonym cwms_t_cwms_ts_id for cwms_ts_id_t;

