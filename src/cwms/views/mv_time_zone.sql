insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/MV_TIME_ZONE', null,
'
/**
 * Displays CWMS time zones and time zone aliases
 *
 * @since CWMS 2.1
 *
 * @field time_zone_code  Unique numeric value identifying the time zone
 * @field time_zone_name  Time zone name or time zone alias
 * @field utc_offset      Offset from UTC
 * @field dst_offset      Offset for Daylight Saving Time
*/
');
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
create index mv_time_zone_idx2 on mv_time_zone(time_zone_code);
create index mv_time_zone_idx3 on mv_time_zone(UPPER("TIME_ZONE_NAME"));
