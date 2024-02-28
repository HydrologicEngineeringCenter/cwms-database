insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_INST', null,
'
/**
 * Information about forecast instances. A forecast instance is identified by a forecast specification
 * (office_id, fcst_spec_id, and location_id) plus the fcst_date_time_utc and issue_date_time_utc.
 *
 * @field office_id           The office that owns the forecast
 * @field fcst_spec_id        The specification ID of the forecast
 * @field location_id         The location that the forecast is for
 * @field fcst_date_time_utc  The date/time the forecast is for
 * @field issue_date_time_utc The date/time the forecast was issued (also version date of any time series)
 * @field first_date_time_utc The earliest date/time of all time series for this forecast
 * @field last_date_time_utc  The latest date/time of all time series for this forecast
 * @field valid_hours         The number of hours past the issue date that the forecast is valid
 * @field valid               A flag (''T''/''F'') specifying whether the forecast is currently valid
 * @field time_series_count   The number of time series stored for the forecast
 * @field file_count          The number of files stored for the forecast
 * @field key_count           The number of (key, value) pairs stored for  the forecast
 * @field notes               Notes about the forecast
 */
');
create or replace view av_fcst_inst (
   office_id,
   fcst_spec_id,
   location_id,
   fcst_date_time_utc,
   issue_date_time_utc,
   first_date_time_utc,
   last_date_time_utc,
   valid_hours,
   valid,
   time_series_count,
   file_count,
   key_count,
   notes)
as
select o.office_id,
       fs.fcst_spec_id,
       bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
       fi.fcst_date_time as fcst_date_time_utc,
       fi.issue_date_time as issue_date_time_utc,
       fi.first_date_time as first_date_time_utc,
       fi.last_date_time as last_date_time_utc,
       fi.max_age as valid_hours,
       case when max_age is null then null when (sysdate - fi.issue_date_time) * 24 <= max_age then 'T' else 'F' end as valid,
       fi.time_series_count,
       fi.file_count,
       fi.key_count,
       fi.notes
  from at_fcst_inst fi,
       at_fcst_spec fs,
       at_physical_location pl,
       at_base_location bl,
       cwms_office o
 where fs.fcst_spec_code = fi.fcst_spec_code
   and o.office_code = fs.office_code
   and pl.location_code = fs.location_code
   and bl.base_location_code = pl.base_location_code;

grant select on av_fcst_inst to cwms_user;
create or replace public synonym cwms_v_fcst_inst for av_fcst_inst;
