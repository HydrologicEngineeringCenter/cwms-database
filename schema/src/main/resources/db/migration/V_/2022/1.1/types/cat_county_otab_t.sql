CREATE TYPE cat_county_otab_t
-- not documented
AS TABLE OF cat_county_obj_t;
/


create or replace public synonym cwms_t_cat_county_otab for cat_county_otab_t;

