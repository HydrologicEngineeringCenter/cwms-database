CREATE TYPE cat_loc_alias_obj_t
-- not documented
AS OBJECT (
   office_id   VARCHAR2 (16),
   cwms_id     VARCHAR2 (16),
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/


create or replace public synonym cwms_t_cat_loc_alias_obj for cat_loc_alias_obj_t;

