CREATE TYPE cat_state_otab_t
-- not documented
AS TABLE OF cat_state_obj_t;
/


create or replace public synonym cwms_t_cat_state_otab for cat_state_otab_t;

