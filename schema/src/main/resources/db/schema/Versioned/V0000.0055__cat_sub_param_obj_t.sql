CREATE TYPE cat_sub_param_obj_t
-- not documented
AS OBJECT (
   parameter_id      VARCHAR2 (16),
   subparameter_id   VARCHAR2 (32),
   description       VARCHAR2 (80)
);
/


create or replace public synonym cwms_t_cat_sub_param_obj for cat_sub_param_obj_t;

