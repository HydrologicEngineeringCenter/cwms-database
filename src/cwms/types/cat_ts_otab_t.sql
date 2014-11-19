CREATE TYPE cat_ts_otab_t
-- not documented
AS TABLE OF cat_ts_obj_t;
/


create or replace public synonym cwms_t_cat_ts_otab for cat_ts_otab_t;

