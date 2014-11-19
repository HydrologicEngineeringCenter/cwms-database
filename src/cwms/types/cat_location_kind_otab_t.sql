CREATE TYPE cat_location_kind_otab_t
-- not documented
AS TABLE OF cat_location_kind_obj_t;
/


create or replace public synonym cwms_t_cat_location_kind_otab for cat_location_kind_otab_t;

