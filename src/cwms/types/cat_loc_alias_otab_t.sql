CREATE TYPE cat_loc_alias_otab_t
-- not documented
AS TABLE OF cat_loc_alias_obj_t;
/


create or replace public synonym cwms_t_cat_loc_alias_otab for cat_loc_alias_otab_t;

