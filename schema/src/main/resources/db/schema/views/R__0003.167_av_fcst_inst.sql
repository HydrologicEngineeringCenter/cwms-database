delete from at_clob where id = '/VIEWDOCS/AV_FCST_INST';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_INST', null,
'
/**
 * Information about forecast instances. A forecast instance is identified by a forecast specification
 * (office_id, fcst_spec_id, and location_id) plus the fcst_date_time_utc and issue_date_time_utc.
 *
 * @field office_id           The office that owns the forecast
 * @field fcst_spec_id        "Main name" of the forecast specification
 * @field fcst_designator     "Sub-name" of the forecast specification, if any
 * @field fcst_date_time_utc  The date/time the forecast is for
 * @field issue_date_time_utc The date/time the forecast was issued (also version date of any time series)
 * @field valid_hours         The number of hours past the issue date that the forecast is valid
 * @field valid               A flag (''T''/''F'') specifying whether the forecast is currently valid
 * @field file_name           The name of the forecast file, if any
 * @field file_size           The size of the forecast file, if any
 * @field file_media_type     The media type of the forecast file, if any
 * @field notes               Notes about the forecast
 */
');
create or replace view av_fcst_inst (
   office_id,
   fcst_spec_id,
   fcst_designator,
   fcst_date_time_utc,
   issue_date_time_utc,
   valid_hours,
   valid,
   file_name,
   file_size,
   file_media_type,
   notes)
as
select o.office_id,
       fs.fcst_spec_id,
       fs.fcst_designator,
       fi.fcst_date_time as fcst_date_time_utc,
       fi.issue_date_time as issue_date_time_utc,
       fi.max_age as valid_hours,
       case when max_age is null then null when (sysdate - fi.issue_date_time) * 24 <= max_age then 'T' else 'F' end as valid,
       case when fi.blob_file is null then null else fi.blob_file.filename end,
       case when fi.blob_file is null then null else dbms_lob.getlength(fi.blob_file.the_blob) end,
       case when fi.blob_file is null then null else fi.blob_file.media_type end,
       fi.notes
  from at_fcst_inst fi,
       at_fcst_spec fs,
       cwms_office o
 where fs.fcst_spec_code = fi.fcst_spec_code
   and o.office_code = fs.office_code;

grant select on av_fcst_inst to cwms_user;
create or replace public synonym cwms_v_fcst_inst for av_fcst_inst;
