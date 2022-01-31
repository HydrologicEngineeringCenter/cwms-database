CREATE TYPE cat_dss_file_otab_t
-- not documented
AS TABLE OF cat_dss_file_obj_t;
/


create or replace public synonym cwms_t_cat_dss_file_otab for cat_dss_file_otab_t;

