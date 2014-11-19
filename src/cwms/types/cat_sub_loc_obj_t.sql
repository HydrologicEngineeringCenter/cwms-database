CREATE TYPE cat_sub_loc_obj_t
-- not documented
AS OBJECT (
   sublocation_id   VARCHAR2 (32),
   description      VARCHAR2 (80)
);
/


create or replace public synonym cwms_t_cat_sub_loc_obj for cat_sub_loc_obj_t;

