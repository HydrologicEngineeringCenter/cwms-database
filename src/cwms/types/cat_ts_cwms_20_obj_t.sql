create or replace TYPE cat_ts_cwms_20_obj_t
-- not documented
AS OBJECT (
   office_id             VARCHAR2 (16),
   cwms_ts_id            VARCHAR2(191),
   interval_utc_offset   NUMBER (10),
   user_privileges       NUMBER,
   inactive              NUMBER,
   lrts_timezone         VARCHAR2 (28)
);
/


create or replace public synonym cwms_t_cat_ts_cwms_20_obj for cat_ts_cwms_20_obj_t;

