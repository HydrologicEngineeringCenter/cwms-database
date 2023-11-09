/**
 * Displays information about concrete and virtual location levels.
 * Selecting records from this view is much quicker if the critera include location_code instead of location_id.
 *
 * @since CWMS Database Schema 18.2.0
 *
 * @field office_id                The text identifier of the office that owns the location level
 * @field location_level_id        The text identifier of the location level
 * @field effective_date_utc       The UTC date/time that the level became effective
 * @field expiration_date_utc      The UTC date/time that the level expires/expired, if any
 * @field attribute_id             The text identifier of the location level attribute, if any
 * @field attr_value_en            The attribute, if any, in English units
 * @field attr_unit_en             The English unit of the attribute value, if any
 * @field attr_value_si            The attribute, if any, in SI units
 * @field attr_unit_si             The SI unit of the attribute value, if any
 * @field level_type               The type of location level (CONSTANT, REGULARLY-VARYING, IRREGULARLY-VARYING, or VIRTUAL)
 * @field location_id              The text identifier of the full location for of the location level
 * @field base_location_id         The text identifier of the base location for the location level
 * @field sub_location_id          The text identifier of the sub-location for the location level
 * @field parameter_id             The text identifier of the full parameter for the location level
 * @field base_parameter_id        The text identifier of the base parameter for the location level
 * @field sub_parameter_id         The text identifier of the sub-parameter for the location level
 * @field duration_id              The text identifier of the duration for the location level
 * @field specified_level_id       The text identifier of the specified level of the location level
 * @field attr_parameter_id        The text identifier of the full parameter for the location level attribute, if any
 * @field attr_base_parameter_id   The text identifier of the base parameter for the location level attribute, if any
 * @field attr_sub_parameter_id    The text identifier of the sub-parameter for the location level attribute, if any
 * @field attr_parameter_type_id   The text identifier of the parameter type for the location level attribute, if any
 * @field attr_duration_id         The text identifier of the duration for the location level attribute, if any
 * @field office_code              The numeric code of the office that owns the location level
 * @field location_level_code      The numeric code of the location level
 * @field location_code            The numeric code of the full location for of the location level
 * @field base_location_code       The numeric code of the base location for the location level
 * @field base_parameter_code      The numeric code of the full parameter for the location level
 * @field parameter_code           The numeric code of the base parameter for the location level
 * @field duration_code            The numeric code of the duration for the location level
 * @field specified_level_code     The numeric code of the specified level of the location level
 * @field attr_parameter_code      The numeric code of the full parameter for the location level attribute, if any
 * @field attr_base_parameter_code The numeric code of the base parameter for the location level attribute, if any
 * @field attr_parameter_type_code The numeric code of the parameter type for the location level attribute, if any
 * @field attr_duration_code       The numeric code of the duration for the location level attribute, if any
 * @field aliased_item             Specifies the portion of the location_id that is aliaed, if any (NULL, ''LOCATION'', or ''BASE LOCATION'')
 * @field loc_alias_category       The text identifier of the location group category if the  location_id is a location alias
 * @field loc_alias_group,         The text identifier of the location group if the  location_id is a location alias
 */
create or replace force view av_location_level2 (
   office_id,
   location_level_id,
   effective_date_utc,
   expiration_date_utc,
   attribute_id,
   attr_value_en,
   attr_unit_en,
   attr_value_si,
   attr_unit_si,
   level_type,
   location_id,
   base_location_id,
   sub_location_id,
   parameter_id,
   base_parameter_id,
   sub_parameter_id,
   duration_id,
   specified_level_id,
   attr_parameter_id,
   attr_base_parameter_id,
   attr_sub_parameter_id,
   attr_parameter_type_id,
   attr_duration_id,
   office_code,
   location_level_code,
   location_code,
   base_location_code,
   base_parameter_code,
   parameter_code,
   duration_code,
   specified_level_code,
   attr_parameter_code,
   attr_base_parameter_code,
   attr_parameter_type_code,
   attr_duration_code,
   aliased_item,
   loc_alias_category,
   loc_alias_group)
as
select office_id,
       location_level_id,
       effective_date_utc,
       expiration_date_utc,
       attribute_id,
       attr_value_en,
       attr_unit_en,
       attr_value_si,
       attr_unit_si,
       level_type,
       location_id,
       base_location_id,
       sub_location_id,
       parameter_id,
       base_parameter_id,
       sub_parameter_id
       parameter_id,
       duration_id,
       specified_level_id,
       attr_parameter_id,
       attr_base_parameter_id,
       attr_sub_parameter_id,
       attr_parameter_type_id,
       attr_duration_id,
       office_code,
       location_level_code,
       location_code,
       base_location_code,
       base_parameter_code,
       parameter_code,
       duration_code,
       specified_level_code,
       attr_parameter_code,
       attr_base_parameter_code,
       attr_parameter_type_code,
       attr_duration_code,
       aliased_item,
       loc_alias_category,
       loc_alias_group
  from (select loc.office_id,
               loc.location_id||'.'||lvl.parameter_id||'.'||lvl.parameter_type_id||'.'||lvl.duration_id||'.'||lvl.specified_level_id as location_level_id,
               lvl.effective_date_utc,
               lvl.expiration_date_utc,
               case
               when lvl.attr_parameter_id is null then null
               else lvl.attr_parameter_id||'.'||lvl.attr_parameter_type_id||'.'||lvl.attr_duration_id
               end as attribute_id,
               round(cwms_util.convert_units(lvl.attr_value, lvl.attr_unit, lvl.attr_unit_en), 9) as attr_value_en,
               lvl.attr_unit_en,
               round(cwms_util.convert_units(lvl.attr_value, lvl.attr_unit, lvl.attr_unit_si), 9) as attr_value_si,
               lvl.attr_unit_si,
               lvl.level_type,
               loc.location_id,
               loc.base_location_id,
               loc.sub_location_id,
               lvl.parameter_id,
               lvl.base_parameter_id,
               lvl.sub_parameter_id,
               lvl.duration_id,
               lvl.specified_level_id,
               lvl.attr_parameter_id,
               lvl.attr_base_parameter_id,
               lvl.attr_sub_parameter_id,
               lvl.attr_parameter_type_id,
               lvl.attr_duration_id,
               loc.office_code,
               lvl.location_level_code,
               loc.location_code,
               loc.base_location_code,
               lvl.base_parameter_code,
               lvl.parameter_code,
               lvl.duration_code,
               lvl.specified_level_code,
               lvl.attr_parameter_code,
               lvl.attr_base_parameter_code,
               lvl.attr_parameter_type_code,
               lvl.attr_duration_code,
               loc.aliased_item,
               loc.loc_alias_category,
               loc.loc_alias_group
          from (select office_id,
                       location_id,
                       base_location_id,
                       sub_location_id,
                       location_code,
                       base_location_code,
                       db_office_code as office_code,
                       aliased_item,
                       loc_alias_category,
                       loc_alias_group
                  from (select distinct
                               o.office_id,
                               bl.base_location_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
                               bl.base_location_id,
                               pl.sub_location_id,
                               pl.location_code,
                               bl.base_location_code,
                               bl.db_office_code,
                               null as aliased_item,
                               null as loc_alias_category,
                               null as loc_alias_group
                          from at_physical_location pl,
                               at_base_location bl,
                               cwms_office o
                         where bl.base_location_code = pl.base_location_code
                           and o.office_code = bl.db_office_code
                        union all
                        select distinct
                               o.office_id,
                               lga.loc_alias_id as location_id,
                               bl.base_location_id,
                               pl.sub_location_id,
                               pl.location_code,
                               bl.base_location_code,
                               bl.db_office_code,
                               'LOCATION' as aliased_item,
                               lc.loc_category_id,
                               lg.loc_group_id
                          from at_physical_location pl,
                               at_base_location bl,
                               cwms_office o,
                               at_loc_group_assignment lga,
                               at_loc_group lg,
                               at_loc_category lc
                         where bl.base_location_code = pl.base_location_code
                           and o.office_code = bl.db_office_code
                           and lga.location_code = pl.location_code
                           and lg.loc_group_code = lga.loc_group_code
                           and lc.loc_category_code = lg.loc_category_code
                           and lga.loc_alias_id is not null
                           and pl.sub_location_id is not null
                        union all
                        select distinct
                               o.office_id,
                               lga.loc_alias_id||substr('-', 1, length(pl.sub_location_id))||pl.sub_location_id as location_id,
                               bl.base_location_id,
                               pl.sub_location_id,
                               pl.location_code,
                               bl.base_location_code,
                               bl.db_office_code,
                               'BASE LOCATION' as aliased_item,
                               lc.loc_category_id,
                               lg.loc_group_id
                          from at_physical_location pl,
                               at_base_location bl,
                               cwms_office o,
                               at_loc_group_assignment lga,
                               at_loc_group lg,
                               at_loc_category lc
                         where bl.base_location_code = pl.base_location_code
                           and o.office_code = bl.db_office_code
                           and lga.location_code = pl.base_location_code
                           and lg.loc_group_code = lga.loc_group_code
                           and lc.loc_category_code = lg.loc_category_code
                           and lga.loc_alias_id is not null
                       )
               ) loc
               join
               (select q1.effective_date_utc,
                       q1.expiration_date_utc,
                       q1.level_type,
                       q1.parameter_id,
                       q1.base_parameter_id,
                       q1.sub_parameter_id,
                       q1.parameter_type_id,
                       q1.duration_id,
                       q1.specified_level_id,
                       q2.attr_parameter_id,
                       q2.attr_base_parameter_id,
                       q2.attr_sub_parameter_id,
                       q2.attr_parameter_type_id,
                       q2.attr_duration_id,
                       q2.attr_unit_en,
                       q2.attr_unit_si,
                       q1.location_level_code,
                       q1.location_code,
                       q1.parameter_code,
                       q1.base_parameter_code,
                       q1.duration_code,
                       q1.specified_level_code,
                       q2.attr_parameter_code,
                       q2.attr_base_parameter_code,
                       q2.attr_parameter_type_code,
                       q2.attr_duration_code,
                       q1.attr_value,
                       case
                       when q2.attr_parameter_code is null then null
                       else cwms_util.get_unit_id2(cwms_util.get_db_unit_code(q2.attr_parameter_code))
                       end as attr_unit
                  from (select distinct
                               bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id as parameter_id,
                               bp.base_parameter_id,
                               p.sub_parameter_id,
                               pt.parameter_type_id,
                               d.duration_id,
                               sl.specified_level_id,
                               ll.location_level_date as effective_date_utc,
                               ll.expiration_date as expiration_date_utc,
                               case
                               when ll.location_level_value is not null then 'CONSTANT'
                               when ll.interval_origin is not null then 'REGULARLY-VARYING'
                               when ll.ts_code is not null then 'IRREGULARLY-VARYING'
                               end as level_type,
                               ll.location_level_code,
                               ll.location_code,
                               p.parameter_code,
                               bp.base_parameter_code,
                               pt.parameter_type_code,
                               d.duration_code,
                               sl.specified_level_code,
                               ll.attribute_parameter_code,
                               ll.attribute_parameter_type_code,
                               ll.attribute_duration_code,
                               ll.attribute_value as attr_value
                          from at_location_level ll,
                               at_parameter p,
                               cwms_base_parameter bp,
                               cwms_parameter_type pt,
                               cwms_duration d,
                               at_specified_level sl
                         where p.parameter_code = ll.parameter_code
                           and bp.base_parameter_code = p.base_parameter_code
                           and pt.parameter_type_code = ll.parameter_type_code
                           and d.duration_code = ll.duration_code
                           and sl.specified_level_code = ll.specified_level_code
                       ) q1
                       left outer join
                       (select bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id as attr_parameter_id,
                               bp.base_parameter_id as attr_base_parameter_id,
                               p.sub_parameter_id as attr_sub_parameter_id,
                               pt.parameter_type_id as attr_parameter_type_id,
                               d.duration_id as attr_duration_id,
                               cwms_display.retrieve_user_unit_f(
                                 p_parameter_id => bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id,
                                 p_unit_system  => 'EN') as attr_unit_en,
                               cwms_display.retrieve_user_unit_f(
                                 p_parameter_id => bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id,
                                 p_unit_system  => 'SI') as attr_unit_si,
                               p.parameter_code as attr_parameter_code,
                               bp.base_parameter_code as attr_base_parameter_code,
                               pt.parameter_type_code as attr_parameter_type_code,
                               d.duration_code as attr_duration_code
                          from cwms_base_parameter bp,
                               at_parameter p,
                               cwms_parameter_type pt,
                               cwms_duration d
                         where bp.base_parameter_code = p.base_parameter_code
                       ) q2 on q2.attr_parameter_code = q1.attribute_parameter_code
                          and q2.attr_parameter_type_code = q1.attribute_parameter_type_code
                          and q2.attr_duration_code = q1.attribute_duration_code
                union all
                select q3.effective_date_utc,
                       q3.expiration_date_utc,
                       q3.level_type,
                       q3.parameter_id,
                       q3.base_parameter_id,
                       q3.sub_parameter_id,
                       q3.parameter_type_id,
                       q3.duration_id,
                       q3.specified_level_id,
                       q4.attr_parameter_id,
                       q4.attr_base_parameter_id,
                       q4.attr_sub_parameter_id,
                       q4.attr_parameter_type_id,
                       q4.attr_duration_id,
                       q4.attr_unit_en,
                       q4.attr_unit_si,
                       q3.location_level_code,
                       q3.location_code,
                       q3.parameter_code,
                       q3.base_parameter_code,
                       q3.duration_code,
                       q3.specified_level_code,
                       q4.attr_parameter_code,
                       q4.attr_base_parameter_code,
                       q4.attr_parameter_type_code,
                       q4.attr_duration_code,
                       q3.attr_value,
                       case
                       when q4.attr_parameter_code is null then null
                       else cwms_util.get_unit_id2(cwms_util.get_db_unit_code(q4.attr_parameter_code))
                       end as attr_unit
                  from (select distinct
                               bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id as parameter_id,
                               bp.base_parameter_id,
                               p.sub_parameter_id,
                               pt.parameter_type_id,
                               d.duration_id,
                               sl.specified_level_id,
                               ll.effective_date as effective_date_utc,
                               ll.expiration_date as expiration_date_utc,
                              'VIRTUAL' as level_type,
                               ll.location_code,
                               p.parameter_code,
                               bp.base_parameter_code,
                               pt.parameter_type_code,
                               d.duration_code,
                               sl.specified_level_code,
                               ll.location_level_code,
                               ll.attribute_parameter_code,
                               ll.attribute_parameter_type_code,
                               ll.attribute_duration_code,
                               ll.attribute_value as attr_value
                          from at_virtual_location_level ll,
                               at_parameter p,
                               cwms_base_parameter bp,
                               cwms_parameter_type pt,
                               cwms_duration d,
                               at_specified_level sl
                         where p.parameter_code = ll.parameter_code
                           and bp.base_parameter_code = p.base_parameter_code
                           and pt.parameter_type_code = ll.parameter_type_code
                           and d.duration_code = ll.duration_code
                           and sl.specified_level_code = ll.specified_level_code
                       ) q3
                       left outer join
                       (select bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id as attr_parameter_id,
                               bp.base_parameter_id as attr_base_parameter_id,
                               p.sub_parameter_id as attr_sub_parameter_id,
                               pt.parameter_type_id as attr_parameter_type_id,
                               d.duration_id as attr_duration_id,
                               cwms_display.retrieve_user_unit_f(
                                 p_parameter_id => bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id,
                                 p_unit_system  => 'EN') as attr_unit_en,
                               cwms_display.retrieve_user_unit_f(
                                 p_parameter_id => bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id))||p.sub_parameter_id,
                                 p_unit_system  => 'SI') as attr_unit_si,
                               p.parameter_code as attr_parameter_code,
                               bp.base_parameter_code as attr_base_parameter_code,
                               pt.parameter_type_code as attr_parameter_type_code,
                               d.duration_code as attr_duration_code
                          from cwms_base_parameter bp,
                               at_parameter p,
                               cwms_parameter_type pt,
                               cwms_duration d
                         where bp.base_parameter_code = p.base_parameter_code
                       ) q4 on q4.attr_parameter_code = q3.attribute_parameter_code
                          and q4.attr_parameter_type_code = q3.attribute_parameter_type_code
                          and q4.attr_duration_code = q3.attribute_duration_code
               ) lvl on lvl.location_code = loc.location_code
       );

create or replace public synonym cwms_v_location_level2 for av_location_level2;
grant select on av_location_level2 to cwms_user;
