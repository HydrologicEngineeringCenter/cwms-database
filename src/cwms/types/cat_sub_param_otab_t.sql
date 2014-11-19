CREATE TYPE cat_sub_param_otab_t
-- not documented
AS TABLE OF cat_sub_param_obj_t;
/


create or replace public synonym cwms_t_cat_sub_param_otab for cat_sub_param_otab_t;

