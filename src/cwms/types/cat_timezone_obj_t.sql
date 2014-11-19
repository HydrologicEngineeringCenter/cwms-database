CREATE TYPE cat_timezone_obj_t
-- not documented
AS OBJECT (
   timezone_name   VARCHAR2 (28),
   utc_offset      INTERVAL DAY (2)TO SECOND (6),
   dst_offset      INTERVAL DAY (2)TO SECOND (6)
);
/


create or replace public synonym cwms_t_cat_timezone_obj for cat_timezone_obj_t;

