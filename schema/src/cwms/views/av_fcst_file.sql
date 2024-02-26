insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_FCST_FILE', null,
'
/**
 * Information about forecast files.
 *
 * @field office_id           The office that owns the forecast
 * @field fcst_spec_id        The specification ID of the forecast
 * @field location_id         The location that the forecast is for
 * @field fcst_date_time_utc  The date/time the forecast is for
 * @field issue_date_time_utc The date/time the forecast was issued
 * @field valid               A flag (''T''/''F'') specifying whether the forecast for this file is currently valid
 * @field file_name           Base name of the file (no directories).
 * @field description         Description of the file contents.
 */
');
create or replace view av_fcst_file (
   office_id,
   fcst_spec_id,
   location_id,
   fcst_date_time_utc,
   issue_date_time_utc,
   valid,
   file_name,
   description)
as
select o.office_id,
       fs.fcst_spec_id,
       bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
       fi.fcst_date_time as fcst_date_time_utc,
       fi.issue_date_time as issue_date_time_utc,
       case when max_age is null then null when (sysdate - fi.issue_date_time) * 24 <= max_age then 'T' else 'F' end as valid,
       ff.file_name,
       ff.description
  from at_fcst_file ff,
       at_fcst_inst fi,
       at_fcst_spec fs,
       at_physical_location pl,
       at_base_location bl,
       cwms_office o
 where fi.fcst_inst_code = ff.fcst_inst_code
   and fs.fcst_spec_code = fi.fcst_spec_code
   and o.office_code = fs.office_code
   and pl.location_code = fs.location_code
   and bl.base_location_code = pl.base_location_code;

grant select on av_fcst_file to cwms_user;
create or replace public synonym cwms_v_fcst_file for av_fcst_file;
