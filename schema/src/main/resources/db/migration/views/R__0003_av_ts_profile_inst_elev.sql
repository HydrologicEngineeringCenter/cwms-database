delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_PROFILE_INST_ELEV';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_PROFILE_INST_ELEV', null,
'
/**
 * Elevation information for time series profile instances
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
 * @field native_datum             The native vertical datum of the profile location
 * @field elev_by_loc_native_si    The elevation of the sensor, computed from the key parameter and  elevation of the location, at the indicated time and native vertica datum and in SI units
 * @field elev_by_ref_ts_native_si The elevation of the sensor, computed from the key parameter and  reference elevation time series, at the indicated time and native vertica datum and in SI units
 * @field elev_by_loc_navd88_si    The elevation of the sensor, computed from the key parameter and  elevation of the location, at the indicated time, in NAVD88 and SI units
 * @field elev_by_ref_ts_navd88_si The elevation of the sensor, computed from the key parameter and  reference elevation time series, at the indicated time, in NAVD88 and SI units
 * @field si_unit                  The SI unit used for elevations
 * @field elev_by_loc_native_en    The elevation of the sensor, computed from the key parameter and  elevation of the location, at the indicated time and native vertica datum and in English units
 * @field elev_by_ref_ts_native_en The elevation of the sensor, computed from the key parameter and  reference elevation time series, at the indicated time and native vertica datum and in English units
 * @field elev_by_loc_navd88_en    The elevation of the sensor, computed from the key parameter and  elevation of the location, at the indicated time, in NAVD88 and English units
 * @field elev_by_ref_ts_navd88_en The elevation of the sensor, computed from the key parameter and  reference elevation time series, at the indicated time, in NAVD88 and English units
 * @field en_unit                  The English unit used for elevations
 * @field aliased_item             Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category       The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group          The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
');


create or replace view av_ts_profile_inst_elev (
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
   native_datum,
   elev_by_loc_native_si,
   elev_by_ref_ts_native_si,
   elev_by_loc_navd88_si,
   elev_by_ref_ts_navd88_si,
   si_unit,
   elev_by_loc_native_en,
   elev_by_ref_ts_native_en,
   elev_by_loc_navd88_en,
   elev_by_ref_ts_navd88_en,
   en_unit,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select location_code,
       key_parameter_code,
       office_id,
       location_id,
       key_parameter_id,
       version_id,
       first_date_time,
       last_date_time,
       version_date,
       date_time,
       native_datum,
       elev_by_loc_native_si,
       elev_by_ref_ts_native_si,
       elev_by_loc_native_si + navd88_offset_si as elev_by_loc_navd88_si,
       elev_by_ref_ts_native_si + navd88_offset_si as elev_by_ref_ts_navd88_si,
       'm' as si_unit,
       cwms_util.convert_units(elev_by_loc_native_si, 'm', 'ft') as elev_by_loc_native_en,
       cwms_util.convert_units(elev_by_ref_ts_native_si, 'm', 'ft') as elev_by_ref_ts_native_en,
       cwms_util.convert_units(elev_by_loc_native_si + navd88_offset_si, 'm', 'ft') as elev_by_loc_navd88_en,
       cwms_util.convert_units(elev_by_ref_ts_native_si + navd88_offset_si, 'm', 'ft') as elev_by_ref_ts_navd88_en,
       'ft' as en_unit,
       aliased_item,
       loc_alias_category,
       loc_alias_group
  from (select location_code,
               key_parameter_code,
               office_id,
               location_id,
               key_parameter_id,
               version_id,
               first_date_time,
               last_date_time,
               version_date,
               date_time,
               loc_elevation,
               vertical_datum as native_datum,
               navd88_offset_si,
               case when key_parameter_id = 'Depth' then
                  loc_elevation - cwms_util.convert_units(key_parameter_value, cwms_util.get_default_units(key_parameter_id), 'm')
               when key_parameter_id = 'Height' then
                  loc_elevation + cwms_util.convert_units(key_parameter_value, cwms_util.get_default_units(key_parameter_id), 'm')
               else null
               end as elev_by_loc_native_si,
               case
               when q.reference_ts_code is null then
                  null
               else
                  (select value
                     from table(cwms_ts_profile.retrieve_ts_profile_elevs_f(
                                   p_location_id      => q.location_id,
                                   p_key_parameter_id => q.key_parameter_id,
                                   p_version_id       => q.version_id,
                                   p_unit             => 'm',
                                   p_start_time       => q.first_date_time,
                                   p_end_time         => q.last_date_time,
                                   p_time_zone        => 'UTC',
                                   p_version_date     => q.version_date,
                                   p_office_id        => q.office_id)
                               )
                    where date_time = q.date_time
                  )
               end as elev_by_ref_ts_native_si,
               aliased_item,
               loc_alias_category,
               loc_alias_group
          from (select vl.location_code,
                       tpi.key_parameter_code,
                       vl.db_office_id as office_id,
                       vl.location_id,
                       cwms_util.get_parameter_id(tpi.key_parameter_code) as key_parameter_id,
                       tpi.version_id,
                       tpi.first_date_time,
                       tpi.last_date_time,
                       tpi.version_date,
                       tp.reference_ts_code,
                       vt.date_time,
                       vt.value as key_parameter_value,
                       vl.vertical_datum,
                       vl.elevation as loc_elevation,
                       cwms_loc.get_vertical_datum_offset(vl.location_code, vl.vertical_datum, 'NAVD88', vt.date_time, 'm') as navd88_offset_si,
                       vl.aliased_item,
                       vl.loc_alias_category,
                       vl.loc_alias_group
                  from at_ts_profile_instance tpi,
                       at_ts_profile tp,
                       at_cwms_ts_id tsid,
                       av_loc2 vl,
                       av_tsv vt
                 where tp.location_code = tpi.location_code
                   and tp.key_parameter_code = tpi.key_parameter_code
                   and vl.location_code = tpi.location_code
                   and vl.unit_system = 'SI'
                   and tsid.cwms_ts_id = cwms_ts_profile.make_ts_id(tpi.location_code, tpi.key_parameter_code, tpi.version_id)
                   and vt.ts_code = tsid.ts_code
                   and vt.date_time between tpi.first_date_time and tpi.last_date_time
               ) q
       );

begin
	execute immediate 'grant select on av_ts_profile_inst_elev to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_inst_elev for av_ts_profile_inst_elev;
