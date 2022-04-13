--delete from at_clob where id = '/VIEWDOCS/AV_VLOC_LVL_CONSTITUENT';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_VLOC_LVL_CONSTITUENT', null, '
/**
 * Displays information about and virtual location level constituents
 *
 * @since CWMS Database Schema 18.2.0
 *
 * @field location_level_code       The numeric code for the virutal location level this constituent is for
 * @field constituent_abbr          The abbreviation for this constituent in the connection string of the virtual locaton level
 * @field constituent_role          The role of this constituent (''INTPUT'', or ''TRANSFORM'')
 * @field constituent_type          The type of this constituent (''LOCATION_LEVEL'', ''TIME_SERIES'', ''RATING'', or ''FORMULA'')
 * @field constituent_name          The "name" of this constituent<p>
 *                                  <table class="descr">
 *                                    <tr>
 *                                      <th class="descr">constituent_type</th>
 *                                      <th class="descr">constituent_name</th>
 *                                    </tr>
 *                                    <tr>
 *                                      <td class="descr">LOCATION_LEVEL</td>
 *                                      <td class="descr">A location level ID</td>
 *                                    </tr>
 *                                    <tr>
 *                                      <td class="descr">TIME_SERIES</td>
 *                                      <td class="descr">A time series ID</td>
 *                                    </tr>
 *                                    <tr>
 *                                      <td class="descr">RATING</td>
 *                                      <td class="descr">A rating specification</td>
 *                                    </tr>
 *                                    <tr>
 *                                      <td class="descr">FORMULA</td>
 *                                      <td class="descr">A mathematical expression with units</td>
 *                                    </tr>
 *                                  </table>
 * @field constituent_attr_id       The attribute ID if the constituent is a location level with an attribute
 * @field constituent_attr_value_en The attribute value in English units if the constituent is a location level with an attribute
 * @field constituent_attr_unit_en  The English unit of the attribute value if the constituent is a location level with an attribute
 * @field constitusit_attr_value_si The attribute value in SI units if the constituent is a location level with an attribute
 * @field constitusit_attr_unit_si  The SI unit of the attribute value if the constituent is a location level with an attribute
 */
');
create or replace force view av_vloc_lvl_constituent (
   location_level_code,
   constituent_abbr,
   constituent_role,
   constituent_type,
   constituent_name,
   constituent_attr_id,
   constituent_attr_value_en,
   constituent_attr_unit_en,
   constitusit_attr_value_si,
   constitusit_attr_unit_si)
as
select location_level_code,
       constituent_abbr,
       case
       when constituent_type in ('LOCATION_LEVEL', 'TIME_SERIES') then 'INPUT'
       else 'TRANSFORM'
       end as constituent_role,
       constituent_type,
       constituent_name,
       constituent_attribute_id as constituent_attr_id,
       case
       when constituent_attribute_value is null then
          null
       else
          round(cwms_util.convert_units(
            constituent_attribute_value,
            cwms_util.get_default_units(cwms_util.split_text(constituent_attribute_id, 1, '.')),
            cwms_display.retrieve_user_unit_f(cwms_util.split_text(constituent_attribute_id, 1, '.'), 'EN')), 9)
       end as constituent_attr_value_en,
       case
       when constituent_attribute_value is null then
          null
       else
          cwms_display.retrieve_user_unit_f(cwms_util.split_text(constituent_attribute_id, 1, '.'), 'EN')
       end as constituent_attr_unit_en,
       case
       when constituent_attribute_value is null then
          null
       else
          round(cwms_util.convert_units(
            constituent_attribute_value,
            cwms_util.get_default_units(cwms_util.split_text(constituent_attribute_id, 1, '.')),
            cwms_display.retrieve_user_unit_f(cwms_util.split_text(constituent_attribute_id, 1, '.'), 'SI')), 9)
       end as constitusit_attr_value_si,
       case
       when constituent_attribute_value is null then
          null
       else
          cwms_display.retrieve_user_unit_f(cwms_util.split_text(constituent_attribute_id, 1, '.'), 'SI')
       end as constitusit_attr_unit_si
  from at_vloc_lvl_constituent;

create public synonym cwms_v_vloc_lvl_constituent for av_vloc_lvl_constituent;
grant select on av_vloc_lvl_constituent to cwms_user;

