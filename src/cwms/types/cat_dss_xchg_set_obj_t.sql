CREATE TYPE cat_dss_xchg_set_obj_t
-- not documented
AS OBJECT (
   office_id                  VARCHAR2 (16),
   dss_xchg_set_id            VARCHAR (32),
   dss_xchg_set_description   VARCHAR (80),
   dss_filemgr_url            VARCHAR2 (32),
   dss_file_name              VARCHAR2 (255),
   dss_xchg_direction_id      VARCHAR2 (16),
   dss_xchg_last_update       TIMESTAMP ( 6 )
);
/


create or replace public synonym cwms_t_cat_dss_xchg_set_obj for cat_dss_xchg_set_obj_t;

