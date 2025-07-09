CREATE TYPE nested_ts_table
-- not documented, used only in body of retrieve_ts_multi
IS TABLE OF nested_ts_type;
/


create or replace public synonym cwms_t_nested_ts_table for nested_ts_table;

