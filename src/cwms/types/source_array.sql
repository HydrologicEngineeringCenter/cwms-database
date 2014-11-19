CREATE TYPE source_array
-- not documented, used only in routine body
IS TABLE OF source_type;
/


create or replace public synonym cwms_t_source_array for source_array;

