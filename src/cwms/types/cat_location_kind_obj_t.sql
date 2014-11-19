CREATE TYPE cat_location_kind_obj_t
-- not documented
AS OBJECT (
   office_id        VARCHAR2(16),
   location_kind_id VARCHAR2(32),
   description      VARCHAR2(256)
);
/


create or replace public synonym cwms_t_cat_location_kind_obj for cat_location_kind_obj_t;

