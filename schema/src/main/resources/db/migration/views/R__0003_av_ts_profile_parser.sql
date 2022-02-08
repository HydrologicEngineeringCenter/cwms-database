delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_PROFILE_PARSER';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_PROFILE_PARSER', null,
'
/**
 * Base parsing information for time series profile instances
 *
 * @since Schema 18.1.6
 *
 * @field location_code             The numeric code of the location of the time seires profile
 * @field key_parameter_code        The numeric code of the key parameter of the time series profile
 * @field office_id                 The office that owns the location of the profile
 * @field location_id               The location of the time series profile
 * @field key_parameter_id          The key parameter of the time series profile
 * @field time_field                The 1-based field number containing the timestamp (null if not delimited)
 * @field time_col_start            The 1-based column in the parser that the timestamp field starts (null if delimited)
 * @field time_col_end              The 1-based column in the parser that the timestamp field ends (null if delimited)
 * @field time_zone_id              The time zone of the timestamp
 * @field time_format               The Oracle date/time format model string for the timestamp
 * @field record_delimiter_value    The record delimiter character of the parser text to be parsed
 * @field record_delimiter_ordinal  The character code of record delimiter of the parser text to be parsed
 * @field field_delimiter_value     The field delimiter character of the text to be parsed, if fields are delimited and not fixed width
 * @field field_delimiter_ordinal   The character code of the field delimiter of the text to be parsed, if fields are delimited and not fixed width
 * @field aliased_item              Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category        The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group           The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
');


create or replace view av_ts_profile_parser (
   location_code,
   key_parameter_code,
   office_id,
   location_id,
   key_parameter_id,
   time_field,
   time_col_start,
   time_col_end,
   time_zone_id,
   time_format,
   record_delimter_value,
   record_delimiter_ordinal,
   field_delimieter_value,
   field_delimieter_ordinal,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select tpp.location_code,
       tpp.key_parameter_code,
       vl.db_office_id as office_id,
       vl.location_id,
       cwms_util.get_parameter_id(tpp.key_parameter_code) as key_parameter_id,
       tpp.time_field,
       tpp.time_col_start,
       tpp.time_col_end,
       tz.time_zone_name as time_zone_id,
       tpp.time_format,
       tpp.record_delimiter as record_delimiter_value,
       ascii(tpp.record_delimiter) as record_delimiter_ordinal,
       tpp.field_delimiter as field_delimieter_value,
       ascii(tpp.field_delimiter) as field_delimieter_ordinal,
       vl.aliased_item,
       vl.loc_alias_category,
       vl.loc_alias_group
  from at_ts_profile_parser tpp,
       av_loc2 vl,
       cwms_time_zone tz
 where vl.location_code = tpp.location_code
   and tz.time_zone_code = tpp.time_zone_code
   and vl.active_flag = 'T'
   and vl.unit_system = 'EN';

begin
	execute immediate 'grant select on av_ts_profile_parser to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile_parser for av_ts_profile_parser;
