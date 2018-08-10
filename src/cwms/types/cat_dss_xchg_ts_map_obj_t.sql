create or replace TYPE cat_dss_xchg_ts_map_obj_t
-- not documented
AS OBJECT (
   office_id               VARCHAR2 (16),
   cwms_ts_id              VARCHAR2(191),
   dss_pathname            VARCHAR2 (391),
   dss_parameter_type_id   VARCHAR2 (8),
   dss_unit_id             VARCHAR2 (16),
   dss_timezone_name       VARCHAR2 (28),
   dss_tz_usage_id         VARCHAR2 (8)
);
/


create or replace public synonym cwms_t_cat_dss_xchg_ts_map_obj for cat_dss_xchg_ts_map_obj_t;

