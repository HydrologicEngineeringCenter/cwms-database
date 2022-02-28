/**
 * Spacial coordinates of sensor for time series profile instances
 *
 * @since Schema 18.1.6
 *
 * @field location_code            The numeric code of the location of the time seires profile
 * @field key_parameter_code       The numeric code of the key parameter of the time series profile
 * @field office_id                The office that owns the location of the profile
 * @field location_id              The location of the time series profile
 * @field key_parameter_id         The key parameter of the time series profile
 * @field version_id               The version identifier of the instance and associated data
 * @field first_date_time          The date/time (UTC) of the first value of the instance data
 * @field last_date_time           The date/time (UTC) of the last value of the instance data
 * @field version_date             The version date (UTC) of the instance data
 * @field date_time                The date/time (UTC) of the sensor reading in the profile
 * @field latitude                 The latitude of the location
 * @field longitude                The longitude of the location
 * @field elevation                The sensor elevation, computed using the indicated method
 * @field shape                    The sensor location computed by using longitude, latitude, and elevation values as NAD83
 * @field elevation_method         The method of computing the elevation: ''REFERENCE_TS'' if a reference time series is available otherwise, ''LOCATION_ELEV'' if the location elevation is available, otherwise ''NONE''''
 * @field aliased_item             Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category       The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group          The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
create or replace view av_ts_profile_inst_sp (
   location_code,
   key_parameter_code,
   office_id,
   location_id,
   key_parameter_id,
   version_id,
   first_date_time,
   last_date_time,
   version_date,
   date_time,
   latitude,
   longitude,
   elevation,
   shape,
   elevation_method,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select ve.location_code,
       ve.key_parameter_code,
       ve.office_id,
       ve.location_id,
       ve.key_parameter_id,
       ve.version_id,
       ve.first_date_time,
       ve.last_date_time,
       ve.version_date,
       ve.date_time,
       vl.latitude,
       vl.longitude,
       nvl(ve.elev_by_ref_ts_navd88_si, ve.elev_by_loc_navd88_si) as elevation,
       mdsys.sdo_geometry(
          sdo_gtype     => 3001,
          sdo_srid      => 8265,
          sdo_point     => mdsys.sdo_point_type(
                              vl.longitude,
                              vl.latitude,
                              nvl(ve.elev_by_ref_ts_navd88_si, ve.elev_by_loc_navd88_si)),
          sdo_elem_info => null,
          sdo_ordinates => null) as shape,
       case when ve.elev_by_ref_ts_navd88_si is not null then 'REFERENCE_TS'
            when ve.elev_by_loc_navd88_si is not null then 'LOCATION_ELEV'
            else 'NONE'
       end as elevation_method,
       ve.aliased_item,
       ve.loc_alias_category,
       ve.loc_alias_group
  from av_ts_profile_inst_elev ve,
       av_loc vl
 where vl.location_code = ve.location_code
   and vl.unit_system = 'SI';

begin
	execute immediate 'grant select on av_ts_profile_inst_sp to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_inst_sp for av_ts_profile_inst_sp;
