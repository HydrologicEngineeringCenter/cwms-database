whenever sqlerror continue
delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_PROFILE_PARSER_PARAM';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_PROFILE_PARSER_PARAM', null,
'
/**
 * Parameter parsing information for time series profile instances
 *
 * @since Schema 18.1.6
 *
 * @field location_code       The numeric code of the location of the time seires profile
 * @field key_parameter_code  The numeric code of the key parameter of the time series profile
 * @field office_id           The office that owns the location of the profile
 * @field parameter_code      The numeric code of the profile parameter
 * @field location_id         The location of the time series profile
 * @field key_parameter_id    The key parameter of the time series profile
 * @field parameter_id        The profile parameter
 * @field parameter_unit      The unit of the profile parameter in the text to be parsed
 * @field parameter_field     The 1-based field number in the text to be parsed containing the profile parameter (null if not delimited)
 * @field parameter_col_start The 1-based column in the text to be parsed that this parameter field starts (null if delimited)
 * @field parameter_col_end   The 1-based column in the text to be parsed that this parameter field ends (null if delimited)
 * @field aliased_item        Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category  The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group     The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
');
whenever sqlerror exit

create or replace view av_ts_profile_parser_param (
   location_code,
   key_parameter_code,
   parameter_code,
   office_id,
   location_id,
   key_parameter_id,
   parameter_id,
   parameter_unit,
   parameter_field,
   parameter_col_start,
   parameter_col_end,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select tppp.location_code,
       tppp.key_parameter_code,
       tppp.parameter_code,
       vl.db_office_id as office_id,
       vl.location_id,
       cwms_util.get_parameter_id(tppp.key_parameter_code) as key_parameter_id,
       cwms_util.get_parameter_id(tppp.parameter_code) as parameter_id,
       cwms_util.get_unit_id2(tppp.parameter_unit) as parameter_unit,
       tppp.parameter_field,
       tppp.parameter_col_start,
       tppp.parameter_col_end,
       vl.aliased_item,
       vl.loc_alias_category,
       vl.loc_alias_group
  from at_ts_profile_parser_param tppp,
       av_loc2 vl
 where vl.location_code = tppp.location_code
   and vl.active_flag = 'T'
   and vl.unit_system = 'EN';

begin
	execute immediate 'grant select on av_ts_profile_parser_param to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_parser_param for av_ts_profile_parser_param;
