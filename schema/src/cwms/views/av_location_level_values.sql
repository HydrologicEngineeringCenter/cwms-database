begin
   delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL_VALUES';
   insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_LEVEL_VALUES', null,
                            '
                            /**
                             * Displays information about location level values
                             *
                             *
                             * @field location_level_code The unique numeric code that identifies the location level in the database
                             * @field constant_level_en   The constant level value in English units
                             * @field constant_level_si   The constant level value in SI units
                             * @field seasonal_value_en   The seasonal level value in English units
                             * @field seasonal_value_si   The seasonal level value in SI units
                             * @field interpolate         Indicates whether the level is interpolated
                             * @field interval_origin     Indicates the date/time origin of the interval for seasonal levels
                             * @field calendar_interval   Indicates the calendar interval for seasonal levels
                             * @field time_interval       Indicates the time interval for seasonal levels
                             * @field calendar_offset     The calendar offset for the seasonal level
                             * @field time_offset         The time offset for the seasonal level
                             * @field tsid                The time series identifier for a time series backed location level
                             * @field attribute_value_en        The attribute value in English units
                             * @field attribute_value_si        The attribute value in SI units
                             * @field level_unit_en       The unit of measure for the level value in English units
                             * @field level_unit_si       The unit of measure for the level value in SI units
                             * @field attribute_unit_en   The unit of measure for the attribute value in English units
                             * @field attribute_unit_si   The unit of measure for the attribute value in SI units
                             * @field connections         The list of constituent connections that make up the virtual location level
                             * @field expiration_date     The date/time at which the level expires
                             * @field default_label       The label associated with the location level and the ''GENERAL/OTHER'' configuration, if any
                             * @field source              The source entity for the location level values
                             */
                            ');
end;
/
create or replace force view av_location_level_values
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
/* ============================================================
   Parameter + unit resolution (ROW-SCOPED)
   ============================================================ */
with param_units as (select /*+ INLINE */
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
                             on cx.location_level_code = s.location_level_code)
/* ============================================================
   Constant+Seasonal projection
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
       CAST(null as VARCHAR2(4000))                 as connections,
       p.expiration_date,
       lbl.label                                      as default_label,
       cwms_entity.get_entity_id(src.source_entity)   as source
from phys p
        left join seasonal s
                  on s.location_level_code = p.location_level_code
        left join at_loc_lvl_label lbl
                  on lbl.loc_lvl_label_code = p.location_level_code
                     and lbl.configuration_code = 1
        left join at_loc_lvl_source src
                  on src.loc_lvl_source_code = p.location_level_code
union all
/* ============================================================
   Virtual levels
   ============================================================ */
select v.location_level_code,
       null                                         as constant_level_en,
       null                                         as constant_level_si,
       null                                         as seasonal_value_en,
       null                                         as seasonal_value_si,
       null                                         as interpolate,
       null                                         as interval_origin,
       null                                         as calendar_interval,
       null                                         as time_interval,
       null                                         as calendar_offset,
       null                                         as time_offset,
       null                                         as tsid,
       null                                         as attribute_value_en,
       null                                         as attribute_value_si,
       null                                         as level_unit_en,
       null                                         as level_unit_si,
       null                                         as attribute_unit_en,
       null                                         as attribute_unit_si,
       v.constituent_connections                    as connections,
       v.expiration_date,
       lbl.label                                    as default_label,
       cwms_entity.get_entity_id(src.source_entity) as source
from at_virtual_location_level v
        left join at_loc_lvl_label lbl
                  on lbl.loc_lvl_label_code = v.location_level_code
                     and lbl.configuration_code = 1
        left join at_loc_lvl_source src
                  on src.loc_lvl_source_code = v.location_level_code;
/
begin
   execute immediate 'grant select on av_location_level_values to cwms_user';
exception
   when others then null;
end;
/
create or replace public synonym cwms_v_location_level_values for av_location_level_values;
/
