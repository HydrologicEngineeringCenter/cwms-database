-- delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL_VALUES';
-- insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_LEVEL_VALUES', null,
--                             '
--                             /**
--                              * Displays information about concrete location levels
--                              *
--                              * @since CWMS 2.1 (extended in 3.0)
--                              *
--                              * @field office_id           Office that owns the location level
--                              * @field attribute_id        The attribute identifier, if any, for the location level
--                              * @field location_level_date          The effective data for the location level
--                              * @field base_location_id    The base location portion of the location level
--                              * @field sub_location_id     The sub-location portion of the location level
--                              * @field location_id         The full location portion of the location level
--                              * @field base_parameter_id   The base parameter portion of the location level
--                              * @field sub_parameter_id    The sub-parameter portion of the location level
--                              * @field parameter_id        The full parameter portion of the location level
--                              * @field duration_id         The duration portion of the location level
--                              * @field specified_level_id  The specified level portion of the location level
--                              * @field location_code       The unique numeric code that identifies the location in the database
--                              * @field location_level_code The unique numeric code that identifies the location level in the database
--                              * @field expiration_date             The date/time at which the level expires
--                              * @field parameter_type_id           The parameter type of the location level
--                              * @field attribute_parameter_id      The attribute of the parameter, if any
--                              * @field attribute_base_parameter_id The base parameter of the attribute, if any
--                              * @field attribute_sub_parameter_id  The sub-parameter of the attribute, if any
--                              * @field attribute_parameter_type_id The parameter type of the attribute, if any
--                              * @field attribute_duration_id       The duration of the attribute, if any
--                              * @field default_label               The label assoicated with the location level and the ''GENERAL/OTHER'' configuration, if any
--                              * @field source                      The source entity for the location level values
--                              */
--                             ');

create or replace view av_location_level_values
      (
       location_level_code,
       constant_level_en,
       constant_level_si,
       seasonal_value_en,
       seasonal_value_si,
       interpolate,
       interval_origin,
       calendar_interval,
       time_interval,
       calendar_offset,
       time_offset,
       tsid,
       attribute_value_en,
       attribute_value_si,
       level_unit_en,
       level_unit_si,
       attribute_unit_en,
       attribute_unit_si,
       connections,
       expiration_date,
       default_label,
       source
         )
as
with
/* ============================================================
   Parameter + unit resolution (ROW-SCOPED)
   ============================================================ */
   param_units as (select /*+ INLINE */
                      ll.location_level_code,
                      ll.parameter_code,
                      ll.attribute_parameter_code,
                      cwms_util.get_parameter_id(ll.parameter_code)           as parameter_id,
                      cwms_util.get_parameter_id(ll.attribute_parameter_code) as attribute_parameter_id,
                      cwms_util.get_default_units(
                         cwms_util.get_parameter_id(ll.parameter_code), 'SI'
                      )                                                       as db_level_unit_id,
                      case
                         when ll.attribute_parameter_code is not null
                            then cwms_util.get_default_units(
                            cwms_util.get_parameter_id(ll.attribute_parameter_code), 'SI'
                                 )
                         end                                                  as db_attr_unit_id,
                      case
                         when ll.parameter_code is not null
                            then cwms_display.retrieve_user_unit_f(
                            cwms_util.get_parameter_id(ll.parameter_code), 'EN'
                                 )
                         end                                                  as level_unit_en,
                      case
                         when ll.parameter_code is not null
                            then cwms_display.retrieve_user_unit_f(
                            cwms_util.get_parameter_id(ll.parameter_code), 'SI'
                                 )
                         end                                                  as level_unit_si,
                      case
                         when ll.attribute_parameter_code is not null
                            then cwms_display.retrieve_user_unit_f(
                            cwms_util.get_parameter_id(ll.attribute_parameter_code), 'EN'
                                 )
                         end                                                  as attribute_unit_en,
                      case
                         when ll.attribute_parameter_code is not null
                            then cwms_display.retrieve_user_unit_f(
                            cwms_util.get_parameter_id(ll.attribute_parameter_code), 'SI'
                                 )
                         end                                                  as attribute_unit_si
                   from at_location_level ll),
/* ============================================================
   Conversion metadata (JOINED, NOT PREBUILT)
   ============================================================ */
   conversion_ctx as (select /*+ INLINE */
                         pu.location_level_code,
                         pu.level_unit_en,
                         pu.level_unit_si,
                         pu.attribute_unit_en,
                         pu.attribute_unit_si,
                         ucen.factor    as lvl_factor_en,
                         ucen.offset    as lvl_offset_en,
                         ucen.function  as lvl_function_en,
                         ucsi.factor    as lvl_factor_si,
                         ucsi.offset    as lvl_offset_si,
                         ucsi.function  as lvl_function_si,
                         ucaen.factor   as attr_factor_en,
                         ucaen.offset   as attr_offset_en,
                         ucaen.function as attr_function_en,
                         ucasi.factor   as attr_factor_si,
                         ucasi.offset   as attr_offset_si,
                         ucasi.function as attr_function_si
                      from param_units pu
                              left join cwms_unit_conversion ucen
                                        on ucen.from_unit_id = pu.db_level_unit_id
                                           and ucen.to_unit_id = pu.level_unit_en
                              left join cwms_unit_conversion ucsi
                                        on ucsi.from_unit_id = pu.db_level_unit_id
                                           and ucsi.to_unit_id = pu.level_unit_si
                              left join cwms_unit_conversion ucaen
                                        on ucaen.from_unit_id = pu.db_attr_unit_id
                                           and ucaen.to_unit_id = pu.attribute_unit_en
                              left join cwms_unit_conversion ucasi
                                        on ucasi.from_unit_id = pu.db_attr_unit_id
                                           and ucasi.to_unit_id = pu.attribute_unit_si),
/* ============================================================
   Physical scalar values (DRIVING ROWSET)
   ============================================================ */
   phys as (select /*+ LEADING(ll) USE_NL(cx id) */
               ll.location_level_code,
               ll.expiration_date,
               ll.interpolate,
               ll.interval_origin,
               ll.calendar_interval,
               ll.time_interval,
               id.cwms_ts_id as tsid,
               case
                  when cx.lvl_function_en is not null
                     then cwms_util.eval_expression(
                     cx.lvl_function_en,
                     double_tab_t(ll.location_level_value)
                          )
                  when cx.lvl_factor_en is not null
                     then ll.location_level_value * cx.lvl_factor_en + cx.lvl_offset_en
                  else ll.location_level_value
                  end        as constant_level_en,
               case
                  when cx.lvl_function_si is not null
                     then cwms_util.eval_expression(
                     cx.lvl_function_si,
                     double_tab_t(ll.location_level_value)
                          )
                  when cx.lvl_factor_si is not null
                     then ll.location_level_value * cx.lvl_factor_si + cx.lvl_offset_si
                  else ll.location_level_value
                  end        as constant_level_si,
               case
                  when cx.attr_function_en is not null
                     then cwms_util.eval_expression(
                     cx.attr_function_en,
                     double_tab_t(ll.attribute_value)
                          )
                  when cx.attr_factor_en is not null
                     then ll.attribute_value * cx.attr_factor_en + cx.attr_offset_en
                  else ll.attribute_value
                  end        as attribute_value_en,
               case
                  when cx.attr_function_si is not null
                     then cwms_util.eval_expression(
                     cx.attr_function_si,
                     double_tab_t(ll.attribute_value)
                          )
                  when cx.attr_factor_si is not null
                     then ll.attribute_value * cx.attr_factor_si + cx.attr_offset_si
                  else ll.attribute_value
                  end        as attribute_value_si,
               cx.level_unit_en,
               cx.level_unit_si,
               cx.attribute_unit_en,
               cx.attribute_unit_si
            from at_location_level ll
                    join conversion_ctx cx
                         on cx.location_level_code = ll.location_level_code
                    left join av_cwms_ts_id id
                              on id.ts_code = ll.ts_code),
/* ============================================================
   Seasonal values (INDEX-DRIVEN)
   ============================================================ */
   seasonal as (select /*+ LEADING(s) USE_NL(cx) */
                   s.location_level_code,
                   case
                      when cx.lvl_function_en is not null
                         then cwms_util.eval_expression(
                         cx.lvl_function_en,
                         double_tab_t(s.value)
                              )
                      when cx.lvl_factor_en is not null
                         then s.value * cx.lvl_factor_en + cx.lvl_offset_en
                      else s.value
                      end as seasonal_value_en,
                   case
                      when cx.lvl_function_si is not null
                         then cwms_util.eval_expression(
                         cx.lvl_function_si,
                         double_tab_t(s.value)
                              )
                      when cx.lvl_factor_si is not null
                         then s.value * cx.lvl_factor_si + cx.lvl_offset_si
                      else s.value
                      end as seasonal_value_si,
                   s.calendar_offset,
                   s.time_offset
                from at_seasonal_location_level s
                        join conversion_ctx cx
                             on cx.location_level_code = s.location_level_code),
/* ============================================================
   Virtual levels
   ============================================================ */
   virt as (select location_level_code,
                   constituent_connections as connections,
                   expiration_date
            from at_virtual_location_level)
/* ============================================================
   Final projection
   ============================================================ */
select p.location_level_code,
       p.constant_level_en,
       p.constant_level_si,
       s.seasonal_value_en,
       s.seasonal_value_si,
       p.interpolate,
       p.interval_origin,
       p.calendar_interval,
       p.time_interval,
       s.calendar_offset,
       s.time_offset,
       p.tsid,
       p.attribute_value_en,
       p.attribute_value_si,
       p.level_unit_en,
       p.level_unit_si,
       p.attribute_unit_en,
       p.attribute_unit_si,
       v.connections,
       coalesce(v.expiration_date, p.expiration_date) as expiration_date,
       lbl.label                                      as default_label,
       cwms_entity.get_entity_id(src.source_entity)   as source
from phys p
        left join seasonal s
                  on s.location_level_code = p.location_level_code
        left join virt v
                  on v.location_level_code = p.location_level_code
        left join at_loc_lvl_label lbl
                  on lbl.loc_lvl_label_code = p.location_level_code
                     and lbl.configuration_code = 1
        left join at_loc_lvl_source src
                  on src.loc_lvl_source_code = p.location_level_code;

/
begin
   execute immediate 'grant select on av_location_level_values to cwms_user';
exception
   when others then null;
end;
/
create or replace public synonym cwms_v_location_level_values for av_location_level_values;