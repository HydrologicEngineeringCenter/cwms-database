whenever sqlerror continue
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV_ELEV', null,
'
/**
 * Displays time series times, values, and quality of elevations in database storage units and various vertical datums
 *
 * @since CWMS 3.2
 *
 * @see view av_tsv
 * @see view av_tsv_dqu
 * @see view mv_data_quality
 * @see cwms_util.non_versioned
 *
 * @field ts_code          Unique numeric code identifying the time series
 * @field date_time        The date/time (in UTC) of the time series value
 * @field version_date     The version date of the time series
 * @field data_entry_date  The date/time (in UTC) that the time series value was inserted or updated
 * @field elevation_native The elevation in the location''s native datum and database storage units
 * @field elevation_ngvd29 The NGVD-29 elevation in database storage units
 * @field elevation_navd88 The NAVD-88 elevation in database storage units
 * @field native_datum     The location''s native datum
 * @field quality_code     The quality code associated with the time series value
 * @field start_date       The start date of the underlying table holding the time series value
 * @field end_date         The end date of the underlying table holding the time series value
 */
');
whenever sqlerror exit
create or replace force view av_tsv_elev
as
select ts_code,
       date_time,
       version_date,
       data_entry_date,
       elevation_native,
       elevation_ngvd29,
       elevation_navd88,
       nvl(q2.local_datum_name, native_datum) as native_datum,
       quality_code,
       start_date,
       end_date
  from (select pl.location_code,
               tsv.ts_code,
               tsv.date_time,
               tsv.version_date,
               tsv.data_entry_date,
               tsv.value as elevation_native,
               tsv.value + cwms_loc.get_vertical_datum_offset(pl.location_code, pl.vertical_datum, 'NGVD29') as elevation_ngvd29,
               tsv.value + cwms_loc.get_vertical_datum_offset(pl.location_code, pl.vertical_datum, 'NAVD88') as elevation_navd88,
               pl.vertical_datum as native_datum,
               tsv.quality_code,
               tsv.start_date,
               tsv.end_date
          from av_tsv tsv,
               at_cwms_ts_spec ts,
               at_parameter p,
               cwms_base_parameter bp,
               at_physical_location pl
         where ts.ts_code = tsv.ts_code
           and p.parameter_code = ts.parameter_code
           and bp.base_parameter_code = p.base_parameter_code
           and bp.base_parameter_id = 'Elev'
           and pl.location_code = ts.location_code
       ) q1
       left outer join
       (select location_code,
               local_datum_name
          from at_vert_datum_local
       ) q2 on q2.location_code = q1.location_code;

begin
	execute immediate 'grant select on av_tsv_elev to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_tsv_elev for av_tsv_elev;

