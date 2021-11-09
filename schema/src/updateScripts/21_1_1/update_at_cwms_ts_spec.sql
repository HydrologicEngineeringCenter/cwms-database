declare
   utc_time_zone_code cwms_time_zone.time_zone_code%type;
begin
   select time_zone_code
     into utc_time_zone_code
     from cwms_time_zone
    where time_zone_name = 'UTC';

   execute immediate 'alter trigger AT_CWMS_TS_SPEC_T01 disable';
   update at_cwms_ts_spec
      set time_zone_code = nvl(cwms_loc.get_local_timezone_code(location_code), utc_time_zone_code) where delete_date is null;
   commit;
   execute immediate 'alter trigger AT_CWMS_TS_SPEC_T01 enable';
   cwms_ts_id.refresh_at_cwms_ts_id;
   commit;
end;
/
