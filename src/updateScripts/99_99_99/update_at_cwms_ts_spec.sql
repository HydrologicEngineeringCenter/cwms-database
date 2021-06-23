declare
   utc_time_zone_code cwms_time_zone.time_zone_code%type;
begin
   select time_zone_code
     into utc_time_zone_code
     from cwms_time_zone
    where time_zone_name = 'UTC';

   update at_cwms_ts_spec
      set time_zone_code = nvl(cwms_loc.get_local_timezone_code(location_code), utc_time_zone_code);
end;
/
