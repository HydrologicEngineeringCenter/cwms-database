CREATE TYPE cat_timezone_otab_t
-- not documented
AS TABLE OF cat_timezone_obj_t;
/


create or replace public synonym cwms_t_cat_timezone_otab for cat_timezone_otab_t;

