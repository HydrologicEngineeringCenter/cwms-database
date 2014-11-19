CREATE TYPE cat_location2_otab_t
-- not documented
AS TABLE OF cat_location2_obj_t;
/


create or replace public synonym cwms_t_cat_location2_otab for cat_location2_otab_t;

