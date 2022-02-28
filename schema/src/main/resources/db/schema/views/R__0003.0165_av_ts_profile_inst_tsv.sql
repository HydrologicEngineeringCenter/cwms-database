/**
 * Time seires values in database units for time series profile instances
 *
 * @since Schema 18.1.6
 *
 * @field location_code       The numeric code of the location of the time seires profile
 * @field key_parameter_code  The numeric code of the key parameter of the time series profile
 * @field ts_code             The numeric code of the time series for the parameter in the profile
 * @field office_id           The office that owns the location of the profile
 * @field location_id         The location of the time series profile
 * @field key_parameter_id    The key parameter of the time series profile
 * @field version_id          The version identifier of the instance and associated data
 * @field first_date_time     The date/time (UTC) of the first value of the instance data
 * @field last_date_time      The date/time (UTC) of the last value of the instance data
 * @field version_date        The version date (UTC) of the profile instance and associated time series values
 * @field position            The position of the profile parameter in the profile definition
 * @field parameter_id        The parameter included in the profile definition
 * @field cwms_ts_id          The time series identifier assosicated with the parameter and the version
 * @field date_time           The date/time (UTC) of the time series value for the parameter
 * @field value               The time series value for the parameter, in database storage units
 * @field quality_code        The quality code of the value for the parameter
 * field data_entry_date      The date/time (UTC) that the time series value for the parameter was stored in the database
 * @field aliased_item        Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category  The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group     The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
create or replace view av_ts_profile_inst_tsv (
   location_code,
   key_parameter_code,
   ts_code,
   office_id,
   location_id,
   key_parameter_id,
   version_id,
   first_date_time,
   last_date_time,
   version_date,
   position,
   parameter_id,
   cwms_ts_id,
   date_time,
   value,
   quality_code,
   data_entry_date,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select tpi.location_code,
       tpi.key_parameter_code,
       tsid.ts_code,
       vl.db_office_id as office_id,
       vl.location_id as location_id,
       cwms_util.get_parameter_id(tpi.key_parameter_code) as key_parameter_id,
       tpi.version_id,
       tpi.first_date_time,
       tpi.last_date_time,
       tpi.version_date,
       tpp.position,
       cwms_util.get_parameter_id(tpp.parameter_code) as parameter_id,
       cwms_ts_profile.make_ts_id(tpi.location_code, tpp.parameter_code, tpi.version_id) as cwms_ts_id,
       vt.date_time,
       vt.value,
       vt.quality_code,
       vt.data_entry_date,
       vl.aliased_item,
       vl.loc_alias_category,
       vl.loc_alias_group
  from at_ts_profile_instance tpi,
       at_ts_profile_param tpp,
       at_cwms_ts_id tsid,
       av_loc2 vl,
       av_tsv vt
 where vl.location_code = tpi.location_code
   and tpi.location_code = tpp.location_code
   and tpi.key_parameter_code = tpp.key_parameter_code
   and tsid.cwms_ts_id = cwms_ts_profile.make_ts_id(tpi.location_code, tpp.parameter_code, tpi.version_id)
   and vt.ts_code = tsid.ts_code
   and vt.start_date <= tpi.first_date_time
   and vt.end_date >= tpi.last_date_time
   and vt.date_time between tpi.first_date_time and tpi.last_date_time
   and vl.unit_system = 'EN';

begin
	execute immediate 'grant select on av_ts_profile_inst_tsv to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_inst_tsv for av_ts_profile_inst_tsv;
