create type seasonal_location_level_t
-- not documented
is object
(
   calendar_offset interval year(2) to month,
   time_offset     interval day(3) to second(0),
   level_value     number
);
/


create or replace public synonym cwms_t_seasonal_location_level for seasonal_location_level_t;

