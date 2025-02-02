insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_LVL_SOURCE', null,
'
/**
 * Displays source entities associated with location levels
 *
 * @since CWMS 3.2
 *
 * @field office_id                The identifier for the office that owns the location level
 * @field location_level_id        The full location level identifier
 * @field attribute_id             The full attribute identifier, if any
 * @field attr_value_si            The attribute value, if any, in SI units
 * @field attr_unit_si             The SI unit of the attribute value, if any
 * @field attr_value_en            The attribute value, if any, in English units
 * @field attr_unit_en             The English unit of the attribute value, if any
 * @field source_entity            The source_entity associated with the location level
 * @field location_id              The location identifier for the location level
 * @field parameter_id             The parameter identifier for the location level
 * @field parameter_type_id        The parameter type identifier for the location level
 * @field duration_id              The duration identifier for the location level
 * @field specified_level_id       The specified level identifier for the location level
 * @field attr_parameter_id        The attribute parameter identifier, if any, for the location level
 * @field attr_parameter_type_id   The attribute parameter type identifier, if any, for the location level
 * @field attr_duration_id         The attribute duration identifier, if any, for the location level
 * @field loc_lvl_source_code     The unique numeric code for the location level source record
 * @field office_code              The unique numeric code that identifies the office
 * @field location_code            The unique numeric code that identifies the location
 * @field base_location_code       The unique numeric code that identifies the base location
 * @field parameter_code           The unique numeric code that identifies the parameter
 * @field duration_code            The unique numeric code that identifies the duration
 * @field specified_level_code     The unique numeric code that identifies the specified level
 * @field attr_parameter_code      The unique numeric code that identifies the attribute parameter, if any
 * @field attr_parameter_type_code The unique numeric code that identifies the attribute parameter type, if any
 * @field attr_duration_code       The unique numeric code that identifies the attribute parameter, if any
 */
');

create or replace force view av_loc_lvl_source (
   office_id,
   location_level_id,
   attribute_id,
   attr_value_si,
   attr_unit_si,
   attr_value_en,
   attr_unit_en,
   source_entity,
   location_id,
   parameter_id,
   parameter_type_id,
   duration_id,
   specified_level_id,
   attr_parameter_id,
   attr_parameter_type_id,
   attr_duration_id,
   loc_lvl_source_code,
   office_code,
   location_code,
   base_location_code,
   parameter_code,
   duration_code,
   specified_level_code,
   attr_parameter_code,
   attr_parameter_type_code,
   attr_duration_code)
as
select q1.office_id,
       q1.location_level_id,
       q2.attribute_id,
       q2.attr_value_si,
       q2.attr_unit_si,
       q2.attr_value_en,
       q2.attr_unit_en,
       q1.source_entity,
       q1.location_id,
       q1.parameter_id,
       q1.parameter_type_id,
       q1.duration_id,
       q1.specified_level_id,
       q2.attr_parameter_id,
       q2.attr_parameter_type_id,
       q2.attr_duration_id,
       q1.loc_lvl_source_code,
       q1.office_code,
       q1.location_code,
       q1.base_location_code,
       q1.parameter_code,
       q1.duration_code,
       q1.specified_level_code,
       q2.attr_parameter_code,
       q2.attr_parameter_type_code,
       q2.attr_duration_code
  from (select lls.loc_lvl_source_code,
               o.office_code,
               lls.location_code,
               bl.base_location_code,
               lls.parameter_code,
               lls.parameter_type_code,
               lls.duration_code,
               lls.specified_level_code,
               o.office_id,
               bl.base_location_id
                  ||substr('-', 1, length(pl.sub_location_id))
                  ||pl.sub_location_id as location_id,
               cwms_util.get_parameter_id(parameter_code) as parameter_id,
               pt.parameter_type_id,
               d.duration_id,
               sl.specified_level_id,
               bl.base_location_id
                  ||substr('-', 1, length(pl.sub_location_id))
                  ||pl.sub_location_id
                  ||'.'||cwms_util.get_parameter_id(parameter_code)
                  ||'.'||pt.parameter_type_id
                  ||'.'||d.duration_id
                  ||'.'||specified_level_id as location_level_id,
               e.entity_id as source_entity
          from at_loc_lvl_source lls,
               at_physical_location pl,
               at_base_location bl,
               cwms_office o,
               cwms_parameter_type pt,
               cwms_duration d,
               at_specified_level sl,
               at_entity e
         where pl.location_code = lls.location_code
           and bl.base_location_code = pl.base_location_code
           and o.office_code = bl.db_office_code
           and pt.parameter_type_code = lls.parameter_type_code
           and d.duration_code = lls.duration_code
           and sl.specified_level_code = lls.specified_level_code
           and e.entity_code = lls.source_entity
        ) q1
        left outer join
        (
        select lls.loc_lvl_source_code,
               lls.attr_parameter_code,
               lls.attr_parameter_type_code,
               lls.attr_duration_code,
               cwms_util.get_parameter_id(lls.attr_parameter_code) as attr_parameter_id,
               pt.parameter_type_id as attr_parameter_type_id,
               d.duration_id as attr_duration_id,
               case
                  when lls.attr_parameter_code is null or lls.attr_parameter_type_code is null or lls.duration_code is null then null
                  else cwms_util.get_parameter_id(lls.attr_parameter_code)||'.'||pt.parameter_type_id||'.'||d.duration_id
               end as attribute_id,
               cwms_rounding.round_f(
                  cwms_util.convert_units(
                     attr_value,
                     cwms_util.get_default_units(cwms_util.get_parameter_id(lls.attr_parameter_code), 'SI'),
                     cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(lls.attr_parameter_code), 'SI')),
                  9) as attr_value_si,
               cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(lls.attr_parameter_code), 'SI') as attr_unit_si,
               cwms_rounding.round_f(
                  cwms_util.convert_units(
                     attr_value,
                     cwms_util.get_default_units(cwms_util.get_parameter_id(lls.attr_parameter_code), 'SI'),
                     cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(lls.attr_parameter_code), 'EN')),
                  9) as attr_value_en,
               cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(lls.attr_parameter_code), 'EN') as attr_unit_en
          from at_loc_lvl_source lls,
               cwms_parameter_type pt,
               cwms_duration d
         where pt.parameter_type_code = lls.attr_parameter_type_code
           and d.duration_code = lls.attr_duration_code
        ) q2 on q2.loc_lvl_source_code = q1.loc_lvl_source_code;

begin
	execute immediate 'grant select on av_loc_lvl_source to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_loc_lvl_source for av_loc_lvl_source;

