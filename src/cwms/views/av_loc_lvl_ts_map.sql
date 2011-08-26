insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_LVL_TS_MAP', null,
'
/**
 * Displays mappings from time series to location levels and indicators
 *
 * @since CWMS 2.1
 *
 * @field office_id          The office that owns the time series
 * @field cwms_ts_id         The time series
 * @field location_level_id  The location level that maps to the time series
 * @field level_indicator_id The location level indicator
 * @field attribute_id       The attribute, if any
 * @field attribute_value    The value of any specified attribute
 */');
create or replace force view av_loc_lvl_ts_map as
select office_id,
       cwms_ts_id,
       location_level_id,
       level_indicator_id,
       attribute_id,
       attribute_value
  from ( select lvl.office_id,
                lvl.cwms_ts_id,
                lvl.location_level_id,
                ind.level_indicator_id,
                lvl.attribute_id,
                lvl.attribute_value,
                ind.level_indicator_code
           from ( select o.office_id,
                         ts.ts_code,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||i.interval_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||ts.version as cwms_ts_id,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||sl.specified_level_id as location_level_id,
                         null as attribute_value,
                         null as attribute_id,
                         ll.location_code,
                         ll.specified_level_code,
                         ll.parameter_code,
                         ll.parameter_type_code,
                         ll.duration_code,
                         null as attribute_parameter_code,
                         null as attribute_parameter_type_code,
                         null as attribute_duration_code
                    from at_cwms_ts_spec ts,
                         at_physical_location pl,
                         at_base_location bl,
                         at_parameter p,
                         cwms_base_parameter bp,
                         cwms_parameter_type pt,
                         cwms_interval i,
                         cwms_duration d,
                         at_location_level ll,
                         at_specified_level sl,
                         cwms_office o
                   where bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and ts.location_code = pl.location_code
                     and p.parameter_code = ts.parameter_code
                     and bp.base_parameter_code = p.base_parameter_code
                     and pt.parameter_type_code = ts.parameter_type_code
                     and i.interval_code = ts.interval_code
                     and d.duration_code = ts.duration_code
                     and ll.location_code = pl.location_code
                     and ll.parameter_code = p.parameter_code
                     and ll.parameter_type_code = pt.parameter_type_code
                     and ll.duration_code = d.duration_code
                     and sl.specified_level_code = ll.specified_level_code
                     and ll.location_level_date = (select max(location_level_date)
                                                     from at_location_level
                                                    where location_level_code = ll.location_level_code)
                     and ll.attribute_value is null
--                     
                   union all
--
                  select o.office_id,
                         ts.ts_code,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||i.interval_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||ts.version as cwms_ts_id,
                         bl.base_location_id
                         ||substr('-', 1, length(pl.sub_location_id))
                         ||pl.sub_location_id
                         ||'.'
                         ||bp.base_parameter_id
                         ||substr('-', 1, length(p.sub_parameter_id))
                         ||p.sub_parameter_id
                         ||'.'
                         ||pt.parameter_type_id
                         ||'.'
                         ||d.duration_id
                         ||'.'
                         ||sl.specified_level_id as location_level_id,
                         ll.attribute_value,
                         bp2.base_parameter_id
                         ||substr('-', 1, length(p2.sub_parameter_id))
                         ||p2.sub_parameter_id
                         ||'.'
                         ||pt2.parameter_type_id
                         ||'.'
                         ||d2.duration_id attribute_id,
                         ll.location_code,
                         ll.specified_level_code,
                         ll.parameter_code,
                         ll.parameter_type_code,
                         ll.duration_code,
                         ll.attribute_parameter_code,
                         ll.attribute_parameter_type_code,
                         ll.attribute_duration_code
                    from at_cwms_ts_spec ts,
                         at_physical_location pl,
                         at_base_location bl,
                         at_parameter p,
                         cwms_base_parameter bp,
                         cwms_parameter_type pt,
                         cwms_interval i,
                         cwms_duration d,
                         at_location_level ll,
                         at_specified_level sl,
                         cwms_office o,
                         at_parameter p2,
                         cwms_base_parameter bp2,
                         cwms_parameter_type pt2,
                         cwms_duration d2
                   where bl.db_office_code = o.office_code
                     and pl.base_location_code = bl.base_location_code
                     and ts.location_code = pl.location_code
                     and p.parameter_code = ts.parameter_code
                     and bp.base_parameter_code = p.base_parameter_code
                     and pt.parameter_type_code = ts.parameter_type_code
                     and i.interval_code = ts.interval_code
                     and d.duration_code = ts.duration_code
                     and ll.location_code = pl.location_code
                     and ll.parameter_code = p.parameter_code
                     and ll.parameter_type_code = pt.parameter_type_code
                     and ll.duration_code = d.duration_code
                     and sl.specified_level_code = ll.specified_level_code
                     and ll.location_level_date = (select max(location_level_date)
                                                     from at_location_level
                                                    where location_level_code = ll.location_level_code)
                     and ll.attribute_value is not null
                     and p2.parameter_code = ll.attribute_parameter_code and
                         bp2.base_parameter_code = p2.base_parameter_code and
                         pt2.parameter_type_code = ll.attribute_parameter_type_code and
                         d2.duration_code = ll.duration_code
                ) lvl
--                
                join
--                
                ( select lli.level_indicator_code,
                         lli.level_indicator_id,
                         lli.location_code,
                         lli.specified_level_code,
                         lli.parameter_code,
                         lli.parameter_type_code,
                         lli.duration_code,
                         null as attribute_value,
                         null as attribute_parameter_code,
                         null as attribute_parameter_type_code,
                         null as attribute_duration_code
                    from at_loc_lvl_indicator lli
                   where lli.attr_value is null
--                   
                  union all
--                    
                  select lli.level_indicator_code,
                         lli.level_indicator_id,
                         lli.location_code,
                         lli.specified_level_code,
                         lli.parameter_code,
                         lli.parameter_type_code,
                         lli.duration_code,
                         lli.attr_value as attribute_value,
                         lli.attr_parameter_code as attribute_parameter_code,
                         lli.attr_parameter_type_code as attribute_parameter_type_code,
                         lli.attr_duration_code as attribute_duration_code
                    from at_loc_lvl_indicator lli
                   where lli.attr_value is not null
--                    
                ) ind
                on  ind.location_code = lvl.location_code
                and ind.specified_level_code = lvl.specified_level_code
                and ind.parameter_code = lvl.parameter_code
                and ind.parameter_type_code = lvl.parameter_type_code
                and ind.duration_code = lvl.duration_code
                and nvl((to_char(ind.attribute_value)), '@') = nvl((to_char(lvl.attribute_value)), '@')
                and nvl((to_char(ind.attribute_parameter_code)), '@') = nvl((to_char(lvl.attribute_parameter_code)), '@')
                and nvl((to_char(ind.attribute_parameter_type_code)), '@') = nvl((to_char(lvl.attribute_parameter_type_code)), '@')
                and nvl((to_char(ind.attribute_duration_code)), '@') = nvl((to_char(lvl.attribute_duration_code)), '@')
       )
/
show errors;