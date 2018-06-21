CREATE TYPE cat_location_obj_t
-- not documented
AS OBJECT (
   db_office_id       VARCHAR2 (16),
   location_id        VARCHAR2 (49),
   base_location_id   VARCHAR2 (16),
   sub_location_id    VARCHAR2 (32),
   state_initial      VARCHAR2 (2),
   county_name        VARCHAR2 (40),
   time_zone_name     VARCHAR2 (28),
   location_type      VARCHAR2 (32),
   latitude           NUMBER,
   longitude          NUMBER,
   horizontal_datum   VARCHAR2 (16),
   elevation          NUMBER,
   elev_unit_id       VARCHAR2 (16),
   vertical_datum     VARCHAR2 (16),
   public_name        VARCHAR2 (57),
   long_name          VARCHAR2 (80),
   description        VARCHAR2 (512),
   active_flag        VARCHAR2 (1)
);
/


create or replace public synonym cwms_t_cat_location_obj for cat_location_obj_t;

