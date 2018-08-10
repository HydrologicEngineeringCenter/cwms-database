create or replace TYPE cat_loc_obj_t
-- not documented
AS OBJECT (
   office_id        VARCHAR2 (16),
   base_loc_id      VARCHAR2 (24),
   state_initial    VARCHAR2 (2),
   county_name      VARCHAR2 (40),
   timezone_name    VARCHAR2 (28),
   location_type    VARCHAR2 (16),
   latitude         NUMBER,
   longitude        NUMBER,
   elevation        NUMBER,
   elev_unit_id     VARCHAR2 (16),
   vertical_datum   VARCHAR2 (16),
   public_name      VARCHAR2 (57),
   long_name        VARCHAR2 (80),
   description      VARCHAR2 (512)
);
/


create or replace public synonym cwms_t_cat_loc_obj for cat_loc_obj_t;

