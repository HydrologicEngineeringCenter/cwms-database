delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_TS_PROFILE';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TS_PROFILE', null,
'
/**
 * Time series profile definitions
 *
 * @since Schema 18.1.6
 *
 * @field location_code         The numeric code of the location of the profile
 * @field key_parameter_code    The numeric code of the key parameter (normally Depth or Height) of the profile
 * @field reference_ts_code     The numeric code of the reference time series for elevations for the profile
 * @field office_id             The office that owns the profile location in the database
 * @field location_id           The location identifier of the profile
 * @field key_parameter_id      The key parameter (normally Depth or Height) of the profile
 * @field location_elevation_si The location elevation in the indicated SI units
 * @field location_unit_si      The unit of the location_elevation_si field
 * @field location_elevation_en The location elevation in the indicated English units
 * @field location_unit_en      The unit of the location_elevation_en field
 * @field vertical_datum        The vertical datum of the location
 * @field elev_ts_id            A reference time series for elevations for the profile
 * @field description           A description of the profile definition
 * @field parameters            The parameters defined for the profile, in position order
 * @field aliased_item          Null if the location_id is not an alias, ''LOCATION'' if the entire location_id is aliased, or ''BASE LOCATION'' if only the base_location_id is alaised.
 * @field loc_alias_category    The location category that owns the location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 * @field loc_alias_group       The location group to which the alias for the location_id or base_location_id belongs. Null if location_id is not an alias.
 */
');

create or replace force view av_ts_profile(
   location_code,
   key_parameter_code,
   reference_ts_code,
   office_id,
   location_id,
   key_parameter_id,
   location_elevation_si,
   location_unit_si,
   location_elevation_en,
   location_unit_en,
   vertical_datum,
   elev_ts_id,
   description,
   parameters,
   aliased_item,
   loc_alias_category,
   loc_alias_group
)
as
select vl.location_code,
       tp.key_parameter_code,
       tp.reference_ts_code,
       vl.db_office_id as office_id,
       vl.location_id,
       cwms_util.get_parameter_id(tp.key_parameter_code) as key_parameter_id,
       vl.elevation as location_elevation_si,
       'm' as elevation_unit_si,
       cwms_util.convert_units(vl.elevation, 'm', 'ft') as location_elevation_en,
       'ft' as elevation_unit_en,
       vl.vertical_datum as location_vertical_datum,
       cwms_ts.get_ts_id(tp.reference_ts_code) as elev_ts_id,
       tp.description,
       cwms_util.join_text(cast(multiset(select cwms_util.get_parameter_id(parameter_code)
                                           from at_ts_profile_param
                                          where location_code = tp.location_code
                                            and key_parameter_code = tp.key_parameter_code
                                          order by position
                                        ) as str_tab_t
                               )
                          , ','
                          ) as parameters,
       vl.aliased_item,
       vl.loc_alias_category,
       vl.loc_alias_group
  from at_ts_profile tp,
       av_loc2 vl
 where vl.location_code = tp.location_code
   and vl.unit_system = 'SI';

begin
	execute immediate 'grant select on av_ts_profile to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_ts_profile for av_ts_profile;
