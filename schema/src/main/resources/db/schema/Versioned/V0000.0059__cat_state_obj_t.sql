CREATE TYPE cat_state_obj_t
-- not documented
AS OBJECT (
   state_initial   VARCHAR2 (2),
   state_name      VARCHAR2 (40)
);
/


create or replace public synonym cwms_t_cat_state_obj for cat_state_obj_t;

