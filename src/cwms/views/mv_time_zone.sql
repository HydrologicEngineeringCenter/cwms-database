create materialized view mv_time_zone as
   select * from
      (
      select time_zone_code,
             time_zone_name,
             utc_offset,
             dst_offset
        from cwms_time_zone
      union all     
      select z.time_zone_code,
             a.time_zone_alias as time_zone_name,
             z.utc_offset,
             z.dst_offset
        from cwms_time_zone_alias a,
             cwms_time_zone z
       where z.time_zone_name = a.time_zone_name
       ) order by time_zone_code, time_zone_name;              

create index mv_time_zone_idx1 on mv_time_zone(time_zone_name);