create or replace TYPE cat_ts_obj_t
-- not documented
AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2(191),
   interval_utc_offset   NUMBER
);
/


create or replace public synonym cwms_t_cat_ts_obj for cat_ts_obj_t;

