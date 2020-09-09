whenever sqlerror continue
delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_PROFILE_INST';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_PROFILE_INST', null,
'
/**
 * Time series profile instances
 *
 * @since Schema 18.1.6
 *
 * @field location_code       The numeric code of the location of the time seires profile
 * @field key_parameter_code  The numeric code of the key parameter of the time series profile
 * @field office_id           The office that owns the location of the profile
 * @field location_id         The location of the time series profile
 * @field key_parameter_id    The key parameter of the time series profile
 * @field version_id          The version identifier of the instance and associated data
 * @field first_date_time     The date/time (UTC) of the first value of the instance data
 * @field last_date_time      The date/time (UTC) of the last value of the instance data
 * @field version_date        The version date (UTC) of the instance data
 * @field aliased_item        Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category  The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group     The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
');
whenever sqlerror exit

create or replace view av_ts_profile_inst (
   location_code,
   key_parameter_code,
   office_id,
   location_id,
   key_parameter_id,
   version_id,
   first_date_time,
   last_date_time,
   version_date,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select vl.location_code,
       tpi.key_parameter_code,
       vl.db_office_id as office_id,
       vl.location_id,
       cwms_util.get_parameter_id(tpi.key_parameter_code) as key_parameter_id,
       version_id,
       tpi.first_date_time,
       tpi.last_date_time,
       tpi.version_date,
       vl.aliased_item,
       vl.loc_alias_category,
       vl.loc_alias_group
  from at_ts_profile_instance tpi,
       av_loc2 vl
 where vl.location_code = tpi.location_code
   and vl.unit_system = 'SI';

begin
	execute immediate 'grant select on av_ts_profile_inst to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_inst for av_ts_profile_inst;
