whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_FORECAST_EX';
whenever sqlerror exit sqlcode
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FORECAST_EX', null,
'
/**
 * Displays information about forecasts in the database
 *
 * @since CWMS 3.1
 *
 * @param office_id           The office that owns the location and forecast
 * @param location_id         The target location for the forecast
 * @param forecast_id         The forecast identifier
 * @param utc_forecast_time   The forecast target time in UTC
 * @param local_forecast_time The forecast target time in local time zone of the target location
 * @param utc_issue_time      The forecast issue time in UTC
 * @param local_issue_time    The forecast issue time in local time zone of the target location
 * @param local_time_zone     The local time zone of the target location
 * @param valid               A flag (T/F/NULL) specifying whether the forecast is still in its valid time frame
 * @param text_id             The id to use with CwmsText.RetrieveText() function to get the forecast text
 * @param cwms_ts_id          The time series identifier of one of the forecast time series
 * @param utc_version_time    The version time of the time series in UTC
 * @param local_version_time  The version time of the time series in the local time zone of the target location
 * @param utc_min_time        The earliest time in the time series in UTC
 * @param local_min_time      The earliest time in the time series in the local time zone of the target location
 * @param utc_max_time        The lastest time in the time series in UTC
 * @param local_max_time      The lastest time in the time series in the local time zone of the target location
 * @param office_code         The unique numeric code identifying the office that owns the location and the forecast
 * @param forecast_spec_code  The unique numeric code identifying the forecast specification for the forecast
 * @param location_code       The unique numeric code identifying the target location for the forecast
 * @param clob_code           The unique numeric code identifying the forecast text
 * @param ts_code             The unique numeric code identifying the forecast time series
 */
');

create or replace force view av_forecast_ex (
   office_id,
   location_id,
   forecast_id,
   utc_forecast_time,
   local_forecast_time,
   utc_issue_time,
   local_issue_time,
   local_time_zone,
   valid,
   text_id,
   cwms_ts_id,
   utc_version_time,
   local_version_time,
   utc_min_time,
   local_min_time,
   utc_max_time,
   local_max_time,
   office_code,
   forecast_spec_code,
   location_code,
   clob_code,
   ts_code
)  as
select nvl(q1.office_id, q2.office_id) as office_id,
       cwms_loc.get_location_id(nvl(q1.target_location_code, q2.target_location_code)) as location_id,
       nvl(q1.forecast_id, q2.forecast_id) as forecast_id,
       nvl(q1.utc_forecast_date, q2.utc_forecast_date) as utc_forecast_time,
       nvl(q1.local_forecast_date, q2.local_forecast_date) as local_forecast_time,
       nvl(q1.utc_issue_date, q2.utc_issue_date) as utc_issue_time,
       nvl(q1.local_issue_date, q2.local_issue_date) as local_issue_time,
       nvl(q1.local_time_zone, q2.local_time_zone) as local_time_zone,
       nvl(q1.valid, q2.valid) as valid,
       q2.text_id,
       q1.cwms_ts_id,
       q1.utc_version_time,
       q1.local_version_time,
       q1.utc_min_time,
       cwms_util.change_timezone(q1.utc_min_time, 'UTC', q1.local_time_zone) as local_min_time,
       q1.utc_max_time,
       cwms_util.change_timezone(q1.utc_max_time, 'UTC', q1.local_time_zone) as local_max_time,
       nvl(q1.office_code, q2.office_code) as office_code,
       nvl(q1.forecast_spec_code, q2.forecast_spec_code) as forecast_spec_code,
       nvl(q1.target_location_code, q2.target_location_code) as location_code,
       q2.clob_code,
       q1.ts_code
  from ( select o.office_id,
                o.office_code,
                fs.target_location_code,
                fs.forecast_id,
                fts.forecast_spec_code,
                fts.forecast_date as utc_forecast_date,
                cwms_util.change_timezone(fts.forecast_date, 'UTC', cwms_loc.get_local_timezone(pl.location_code)) as local_forecast_date,
                fts.issue_date as utc_issue_date,
                cwms_util.change_timezone(fts.issue_date, 'UTC', cwms_loc.get_local_timezone(pl.location_code)) as local_issue_date,
                cwms_loc.get_local_timezone(pl.location_code) as local_time_zone,
                case
                when fs.max_age is null then null
                when (sysdate - fts.issue_date) * 24 < fs.max_age then 'T'
                else 'F'
                end as valid,
                cwms_ts.get_ts_id(fts.ts_code) as cwms_ts_id,
                fts.ts_code,
                fts.version_date as utc_version_time,
                cwms_util.change_timezone(fts.version_date, 'UTC', cwms_loc.get_local_timezone(pl.location_code)) as local_version_time,
                cwms_ts.get_ts_min_date_utc(fts.ts_code, fts.version_date) as utc_min_time,
                cwms_ts.get_ts_max_date_utc(fts.ts_code, fts.version_date) as utc_max_time
           from at_forecast_ts fts,
                at_forecast_spec fs,
                at_physical_location pl,
                at_base_location bl,
                at_cwms_ts_spec cts,
                cwms_office o
          where bl.db_office_code = o.office_code
            and pl.base_location_code = bl.base_location_code
            and fs.target_location_code = pl.location_code
            and cts.location_code = pl.location_code
            and fts.ts_code = cts.ts_code
            and fts.forecast_spec_code = fs.forecast_spec_code
       ) q1
       full outer join
       ( select o.office_id,
                o.office_code,
                fs.target_location_code,
                fs.forecast_id,
                ft.forecast_spec_code,
                ft.forecast_date as utc_forecast_date,
                cwms_util.change_timezone(ft.forecast_date, 'UTC', cwms_loc.get_local_timezone(pl.location_code)) as local_forecast_date,
                ft.issue_date as utc_issue_date,
                cwms_util.change_timezone(ft.issue_date, 'UTC', cwms_loc.get_local_timezone(pl.location_code)) as local_issue_date,
                cwms_loc.get_local_timezone(pl.location_code) as local_time_zone,
                case
                when fs.max_age is null then null
                when (sysdate - ft.issue_date) * 24 < fs.max_age then 'T'
                else 'F'
                end as valid,
                c.id as text_id,
                c.clob_code as clob_code
           from at_forecast_text ft,
                at_forecast_spec fs,
                at_physical_location pl,
                at_base_location bl,
                at_clob c,
                cwms_office o
          where bl.db_office_code = o.office_code
            and pl.base_location_code = bl.base_location_code
            and fs.target_location_code = pl.location_code
            and ft.forecast_spec_code = fs.forecast_spec_code
            and c.clob_code = ft.clob_code
       ) q2 on q2.forecast_spec_code = q1.forecast_spec_code
           and q2.utc_forecast_date      = q1.utc_forecast_date
           and q2.utc_issue_date         = q1.utc_issue_date;

begin
	execute immediate 'grant select on av_forecast_ex to cwms_user';
exception
	when others then null;
end;
create or replace public synonym cwms_v_forecast_ex for av_forecast_ex;

