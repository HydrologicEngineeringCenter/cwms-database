CREATE TYPE cat_dss_file_obj_t
-- not documented
AS OBJECT (
   office_id         VARCHAR2 (16),
   dss_filemgr_url   VARCHAR2 (32),
   dss_file_name     NUMBER (14)
);
/


create or replace public synonym cwms_t_cat_dss_file_obj for cat_dss_file_obj_t;

