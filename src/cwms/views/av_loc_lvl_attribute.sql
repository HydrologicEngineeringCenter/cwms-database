insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_LVL_ATTRIBUTE', null,
'
/**
 * Displays the location level attributes
 *
 * @since CWMS 2.1
 *
 * @field location_level_code    The numeric identifier that uniquely specifies the location level
 * @field office_id              The office that owns the location level
 * @field location_level_id      The location level identifier
 * @field attribute_id           The attribute identifier
 * @field si_attr_value          The attribute value in the database standard SI unit
 * @field si_attr_unit           The database standard SI unit
 * @field en_attr_value          The attribute value in the database standard English unig
 * @field en_attr_unit           The database standard English unit
 * @field base_location_id       The base location identifier for the location level
 * @field sub_location_id        The sub-location identifier for the location level
 * @field base_parameter_id      The base parameter identifier for the location level
 * @field sub_parameter_id       The sub-parameter identifier for the location level
 * @field parameter_type_id      The parameter type identifier for the location level
 * @field duration_id            The duration identifier for the location level
 * @field attr_base_parameter_id The base parameter identifier for the attribute
 * @field attr_sub_parameter_id  The sub-parameter identifier for the attribute
 * @field attr_parameter_type_id The parameter type identifier for the attribute
 * @field attr_duration_id       The duration identifier for the attribute
 */
');
create or replace force view av_loc_lvl_attribute(
   location_level_code,
   office_id,
   location_level_id,
   attribute_id,
   si_attr_value,
   si_attr_unit,
   en_attr_value,
   en_attr_unit,
   base_location_id,
   sub_location_id,
   base_parameter_id,
   sub_parameter_id,
   parameter_type_id,
   duration_id,
   attr_base_parameter_id,
   attr_sub_parameter_id,
   attr_parameter_type_id,
   attr_duration_id)
as
   select ll.location_level_code,
          o.office_id,
          bl.base_location_id
          || substr('-', 1, length(pl.sub_location_id))
          || pl.sub_location_id
          || '.'
          || bp1.base_parameter_id
          || substr('-', 1, length(p1.sub_parameter_id))
          || p1.sub_parameter_id
          || '.'
          || pt1.parameter_type_id
          || '.'
          || d1.duration_id
             as location_level_id,
          bp2.base_parameter_id
          || substr('-', 1, length(p2.sub_parameter_id))
          || p2.sub_parameter_id
          || '.'
          || pt2.parameter_type_id
          || '.'
          || d2.duration_id
             as attribute_id,
          cwms_rounding.round_f(
             cwms_util.convert_units(
                ll.attribute_value,
                cwms_util.get_default_units(cwms_util.get_parameter_id(ll.attribute_parameter_code), 'SI'),
                cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(ll.attribute_parameter_code), 'SI')),
             9)
             as si_attr_value,
          cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(ll.attribute_parameter_code), 'SI') as si_attr_unit,
          cwms_rounding.round_f(
             cwms_util.convert_units(
                ll.attribute_value,
                cwms_util.get_default_units(cwms_util.get_parameter_id(ll.attribute_parameter_code), 'SI'),
                cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(ll.attribute_parameter_code), 'EN')),
             9)
             as en_attr_value,
          cwms_display.retrieve_user_unit_f(cwms_util.get_parameter_id(ll.attribute_parameter_code), 'EN') as en_attr_unit,
          bl.base_location_id,
          pl.sub_location_id,
          bp1.base_parameter_id,
          p1.sub_parameter_id,
          pt1.parameter_type_id,
          d1.duration_id,
          bp2.base_parameter_id as attr_base_parameter_id,
          p2.sub_parameter_id as attr_sub_parameter_id,
          pt2.parameter_type_id as attr_parameter_type_id,
          d2.duration_id as attr_duration_id
     from at_location_level ll,
          at_base_location bl,
          at_physical_location pl,
          at_parameter p1,
          cwms_base_parameter bp1,
          cwms_parameter_type pt1,
          cwms_duration d1,
          at_parameter p2,
          cwms_base_parameter bp2,
          cwms_parameter_type pt2,
          cwms_duration d2,
          cwms_office o
    where ll.attribute_value is not null
      and pl.location_code = ll.location_code
      and bl.base_location_code = pl.base_location_code
      and o.office_code = bl.db_office_code
      and p1.parameter_code = ll.parameter_code
      and bp1.base_parameter_code = p1.base_parameter_code
      and pt1.parameter_type_code = ll.parameter_type_code
      and d1.duration_code = ll.duration_code
      and p2.parameter_code = ll.attribute_parameter_code
      and bp2.base_parameter_code = p2.base_parameter_code
      and pt2.parameter_type_code = ll.attribute_parameter_type_code
      and d2.duration_code = ll.attribute_duration_code
/
show errors;

grant select on av_loc_lvl_attribute to cwms_user;

create or replace public synonym cwms_v_loc_lvl_attribute for av_loc_lvl_attribute;


