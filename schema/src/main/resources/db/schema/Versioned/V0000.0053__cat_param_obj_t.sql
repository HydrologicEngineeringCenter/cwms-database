CREATE TYPE cat_param_obj_t
-- not documented
AS OBJECT (
   parameter_id        VARCHAR2 (16),
   param_long_name     VARCHAR2 (80),
   param_description   VARCHAR2 (160),
   unit_id             VARCHAR2 (16),
   unit_long_name      VARCHAR2 (80),
   unit_description    VARCHAR2 (80)
);
/


create or replace public synonym cwms_t_cat_param_obj for cat_param_obj_t;

