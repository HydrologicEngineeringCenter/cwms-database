whenever sqlerror continue
delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_PROFILE_INST_TS';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_PROFILE_INST_TS', null,
'
/**
 * Time series identifiers that hold parameter values for time series profile instances
 *
 * @since Schema 18.1.6
 *
 * @field location_code       The numeric code of the location of the time seires profile
 * @field key_parameter_code  The numeric code of the key parameter of the time series profile
 * @field ts_code             The numeric code of the time series for the parameter in the profile
 * @field office_id           The office that owns the location of the profile
 * @field location_id         The location of the time series profile
 * @field key_parameter       The key parameter of the time series profile
 * @field version_id          The version identifier of the instance and associated data
 * @field position            The position of the profile parameter in the profile definition
 * @field parameter_id        The parameter included in the profile definition
 * @field cwms_ts_id          The time series identifier assosicated with the parameter and the version
 * @field aliased_item        Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category  The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group     The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
');
whenever sqlerror exit


create or replace view av_ts_profile_inst_ts (
   location_code,
   key_parameter_code,
   ts_code,
   office_id,
   location_id,
   key_parameter,
   version_id,
   position,
   parameter_id,
   cwms_ts_id,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
with inst_info as (
   select distinct
          location_code,
          key_parameter_code,
          version_id
     from at_ts_profile_instance)
select ii.location_code,
       ii.key_parameter_code,
       tsid.ts_code,
       vl.db_office_id as office_id,
       vl.location_id as location_id,
       cwms_util.get_parameter_id(ii.key_parameter_code) as key_parameter,
       ii.version_id,
       tpp.position,
       cwms_util.get_parameter_id(tpp.parameter_code) as parameter_id,
       cwms_ts_profile.make_ts_id(ii.location_code, tpp.parameter_code, ii.version_id) as cwms_ts_id,
       vl.aliased_item,
       vl.loc_alias_category,
       vl.loc_alias_group
  from inst_info ii,
       at_ts_profile_param tpp,
       at_cwms_ts_id tsid,
       av_loc2 vl
 where vl.location_code = ii.location_code
   and ii.location_code = tpp.location_code
   and ii.key_parameter_code = tpp.key_parameter_code
   and tsid.cwms_ts_id = cwms_ts_profile.make_ts_id(ii.location_code, tpp.parameter_code, ii.version_id)
   and vl.unit_system = 'EN';

begin
	execute immediate 'grant select on av_ts_profile_inst_ts to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_inst_ts for av_ts_profile_inst_ts;
