CREATE TYPE date_table_type
/**
 * Type suitable for holding multiple date/time values
 */
AS TABLE OF DATE;
/


create or replace public synonym cwms_t_date_table for date_table_type;

