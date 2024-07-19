create type timestamp_tab_t
/**
 * Type suitable for holding multiple timestamp values
 */
as table of timestamp;
/


create or replace public synonym cwms_t_timestamp_tab for timestamp_tab_t;

