CREATE TYPE cat_county_obj_t
-- not documented
AS OBJECT (
   county_id       VARCHAR2 (3),
   county_name     VARCHAR2 (40),
   state_initial   VARCHAR2 (2)
);
/


create or replace public synonym cwms_t_cat_county_obj for cat_county_obj_t;

