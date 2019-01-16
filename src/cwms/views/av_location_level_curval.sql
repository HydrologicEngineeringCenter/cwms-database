--delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL_CURVAL';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_LEVEL_CURVAL', null,
'
/**
 * Displays information about location levels, including the current value
 *
 * @since Schema 18.1
 *
 * @field office_id           Office that owns the location level
 * @field location_level_id   The location level identifier
 * @field attribute_id        The attribute identifier, if any, for the location level
 * @field level_date          The effective data for the location level
 * @field unit_system         The unit system (SI or EN) that units are displayed in
 * @field attribute_unit      The unit of the attribute, if any
 * @field level_unit          The unit of the level
 * @field attribute_value     The value of the attribute, if any
 * @field constant_level      The value of the location level, if it is a constant value
 * @field interval_origin     The beginning of one interval, if the location level is a recurring pattern
 * @field calendar_interval   The length of the interval if expressed in months or years (cannot be used with time_interval)
 * @field time_interval       The length of the interval if expressed in days or less (cannot be used with calendar_interval)
 * @field interpolate         Flag <code><big>''T''</big></code> or <code><big>''F''</big></code> specifying whether to interpolate between pattern breakpoints
 * @field calendar_offset     Years and months into the interval for the seasonal level (combined with time_offset)
 * @field time_offset         Days, hours, and minutes into the interval for the seasonal level (combined with calendar_offset)
 * @field seasonal_level      The level value at the offset into the interval specified by calendar_offset and time_offset
 * @field tsid                The time series identifier for the level, if it is specified as a time series
 * @field level_comment       Comment about the location level
 * @field attribute_comment   Comment about the attribute, if any
 * @field base_location_id    The base location portion of the location level
 * @field sub_location_id     The sub-location portion of the location level
 * @field location_id         The full location portion of the location level
 * @field base_parameter_id   The base parameter portion of the location level
 * @field sub_parameter_id    The sub-parameter portion of the location level
 * @field parameter_id        The full parameter portion of the location level
 * @field duration_id         The duration portion of the location level
 * @field specified_level_id  The specified level portion of the location level
 * @field location_code       The unique numeric code that identifies the location in the database
 * @field location_level_code The unique numeric code that identifies the location level in the database
 * @field expiration_date             The date/time at which the level expires
 * @field parameter_type_id           The parameter type of the location level
 * @field attribute_parameter_id      The attribute of the parameter, if any
 * @field attribute_base_parameter_id The base parameter of the attribute, if any
 * @field attribute_sub_parameter_id  The sub-parameter of the attribute, if any
 * @field attribute_parameter_type_id The parameter type of the attribute, if any
 * @field attribute_duration_id       The duration of the attribute, if any
 * @field default_label               The label assoicated with the location level and the ''GENERAL/OTHER'' configuration, if any
 * @field source                      The source entity for the location level values
 * @field current_value               The current value (in level_unit) for the office_id/location_level_id combination (not necessarily for this level_date)
 */
');

create or replace force view av_location_level_curval
as
select q1.office_id,
       q1.location_id || '.' || q1.parameter_id || '.' || q1.parameter_type_id || '.' || q1.duration_id || '.' || q1.specified_level_id as location_level_id,
       q1.attribute_parameter_id || substr ('.', 1, length (q1.attribute_parameter_type_id)) || q1.attribute_parameter_type_id || substr ('.', 1, length (q1.attribute_duration_id)) || q1.attribute_duration_id as attribute_id,
       q1.level_date, q1.unit_system, q1.attribute_unit, q1.level_unit,
       q1.attribute_value, q1.constant_level, q1.interval_origin,
       substr (q1.calendar_interval_, 2) as calendar_interval,
       q1.time_interval, q1.interpolate,
       substr (q1.calendar_offset_, 2) as calendar_offset,
       substr (q1.time_offset_, 2) as time_offset,
       q1.seasonal_level,
       q1.tsid,
       q1.level_comment,
       q1.attribute_comment,
       cwms_util.get_base_id(q1.location_id) as base_location_id,
       cwms_util.get_sub_id(q1.location_id) as sub_location_id,
       q1.location_id,
       cwms_util.get_base_id(q1.parameter_id) as base_parameter_id,
       cwms_util.get_sub_id(q1.parameter_id) as sub_parameter_id,
       q1.parameter_id,
       q1.duration_id,
       q1.specified_level_id,
       q1.location_code,
       q1.location_level_code,
       q1.expiration_date,
       q1.parameter_type_id,
       q1.attribute_parameter_id,
       cwms_util.get_base_id(q1.attribute_parameter_id) as attribute_base_parameter_id,
       cwms_util.get_sub_id(q1.attribute_parameter_id) as attribute_sub_parameter_id,
       q1.attribute_parameter_type_id,
       q1.attribute_duration_id,
       q2.label as default_label,
       q3.source_entity as source,
       cwms_rounding.round_f(
          cwms_level.retrieve_loc_lvl_value_ex(
             p_location_level_id => location_id || '.' || parameter_id || '.' || parameter_type_id || '.' || duration_id || '.' || specified_level_id,
             p_level_units       => level_unit,
             p_attribute_id      => attribute_parameter_id || SUBSTR ('.', 1, LENGTH (attribute_parameter_type_id)) || attribute_parameter_type_id || SUBSTR ('.', 1, LENGTH (attribute_duration_id)) || attribute_duration_id,
             p_attribute_value   => attribute_value,
             p_attribute_units   => attribute_unit,
             p_ignore_errors     => 'T',
             p_office_id         => office_id),
          10) as current_value
  from (--
        -- constant level
        -- withtout attribute
        --
        (select c_o.office_id as office_id,
                a_bl.base_location_id || substr ('-', 1, length (a_pl.sub_location_id)) || a_pl.sub_location_id as location_id,
                c_bp1.base_parameter_id || substr ('-', 1, length (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id as parameter_id,
                c_pt1.parameter_type_id as parameter_type_id,
                c_d1.duration_id as duration_id,
                a_sl.specified_level_id as specified_level_id,
                null as attribute_parameter_id,
                null as attribute_parameter_type_id,
                null as attribute_duration_id,
                a_ll.location_level_date as level_date,
                us.unit_system as unit_system,
                c_uc1.to_unit_id as level_unit,
                null as attribute_unit,
                a_ll.attribute_value as attribute_value,
                a_ll.location_level_value * c_uc1.factor + c_uc1.offset as constant_level,
                a_ll.interval_origin as interval_origin,
                a_ll.calendar_interval as calendar_interval_,
                a_ll.time_interval as time_interval,
                a_ll.interpolate as interpolate,
                null as calendar_offset_, null as time_offset_,
                null as seasonal_level,
                null as tsid,
                a_ll.location_level_comment as level_comment,
                a_ll.attribute_comment as attribute_comment,
                a_ll.location_code,
                a_ll.specified_level_code,
                a_ll.parameter_code,
                a_ll.parameter_type_code,
                a_ll.duration_code,
                a_ll.location_level_date,
                a_ll.location_level_value,
                a_ll.location_level_comment,
                a_ll.attribute_parameter_code,
                a_ll.attribute_parameter_type_code,
                a_ll.attribute_duration_code,
                a_ll.location_level_code,
                a_ll.expiration_date
           from at_location_level a_ll,
                at_specified_level a_sl,
                at_physical_location a_pl,
                at_base_location a_bl,
                at_parameter a_p1,
                cwms_duration c_d1,
                cwms_base_parameter c_bp1,
                cwms_parameter_type c_pt1,
                cwms_unit_conversion c_uc1,
                cwms_office c_o,
                (select 'EN' as unit_system from  dual
                 union all
                 select 'SI' as unit_system from dual) us
          where a_pl.location_code = a_ll.location_code
            and a_bl.base_location_code = a_pl.base_location_code
            and c_o.office_code = a_bl.db_office_code
            and a_p1.parameter_code = a_ll.parameter_code
            and c_bp1.base_parameter_code = a_p1.base_parameter_code
            and c_pt1.parameter_type_code = a_ll.parameter_type_code
            and c_d1.duration_code = a_ll.duration_code
            and a_sl.specified_level_code = a_ll.specified_level_code
            and c_uc1.from_unit_code = c_bp1.unit_code
            and c_uc1.to_unit_code =
                   decode (us.unit_system,
                           'EN', c_bp1.display_unit_code_en,
                           'SI', c_bp1.display_unit_code_si
                           )
            and a_ll.attribute_parameter_code is null
            and a_ll.location_level_value is not null
            and a_ll.ts_code is null
          )
          union all
          --
          -- regularly varying (seasonal) level
          -- withtout attribute
          --
          (select c_o.office_id as office_id,
                 a_bl.base_location_id || substr ('-', 1, length (a_pl.sub_location_id)) || a_pl.sub_location_id as location_id,
                 c_bp1.base_parameter_id || substr ('-', 1, length (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id as parameter_id,
                 c_pt1.parameter_type_id as parameter_type_id,
                 c_d1.duration_id as duration_id,
                 a_sl.specified_level_id as specified_level_id,
                 null as attribute_parameter_id,
                 null as attribute_parameter_type_id,
                 null as attribute_duration_id,
                 a_ll.location_level_date as level_date,
                 us.unit_system as unit_system,
                 c_uc1.to_unit_id as level_unit, null as attribute_unit,
                 a_ll.attribute_value as attribute_value,
                 null as constant_level,
                 a_ll.interval_origin as interval_origin,
                 a_ll.calendar_interval as calendar_interval_,
                 a_ll.time_interval as time_interval,
                 a_ll.interpolate as interpolate,
                 a_sll.calendar_offset as calendar_offset_,
                 a_sll.time_offset as time_offset_,
                 a_sll.value * c_uc1.factor + c_uc1.offset as seasonal_level,
                 null as tsid,
                 a_ll.location_level_comment as level_comment,
                 a_ll.attribute_comment as attribute_comment,
                 a_ll.location_code,
                 a_ll.specified_level_code,
                 a_ll.parameter_code,
                 a_ll.parameter_type_code,
                 a_ll.duration_code,
                 a_ll.location_level_date,
                 a_ll.location_level_value,
                 a_ll.location_level_comment,
                 a_ll.attribute_parameter_code,
                 a_ll.attribute_parameter_type_code,
                 a_ll.attribute_duration_code,
                 a_ll.location_level_code,
                 a_ll.expiration_date
            from at_location_level a_ll,
                 at_seasonal_location_level a_sll,
                 at_specified_level a_sl,
                 at_physical_location a_pl,
                 at_base_location a_bl,
                 at_parameter a_p1,
                 cwms_duration c_d1,
                 cwms_base_parameter c_bp1,
                 cwms_parameter_type c_pt1,
                 cwms_unit_conversion c_uc1,
                 cwms_office c_o,
                 (select 'EN' as unit_system from dual
                  union all
                  select 'SI' as unit_system from dual
                 ) us
           where a_pl.location_code = a_ll.location_code
             and a_bl.base_location_code = a_pl.base_location_code
             and c_o.office_code = a_bl.db_office_code
             and a_p1.parameter_code = a_ll.parameter_code
             and c_bp1.base_parameter_code = a_p1.base_parameter_code
             and c_pt1.parameter_type_code = a_ll.parameter_type_code
             and c_d1.duration_code = a_ll.duration_code
             and a_sl.specified_level_code = a_ll.specified_level_code
             and c_uc1.from_unit_code = c_bp1.unit_code
             and c_uc1.to_unit_code =
                    decode (us.unit_system,
                            'EN', c_bp1.display_unit_code_en,
                            'SI', c_bp1.display_unit_code_si
                           )
             and a_ll.attribute_parameter_code is null
             and a_ll.location_level_value is null
             and a_ll.ts_code is null
             and a_sll.location_level_code = a_ll.location_level_code
           )
           union all
           --
           -- constant level
           -- with attribute
           --
           (select c_o.office_id as office_id,
                   a_bl.base_location_id || substr ('-', 1, length (a_pl.sub_location_id)) || a_pl.sub_location_id as location_id,
                   c_bp1.base_parameter_id || substr ('-', 1, length (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id as parameter_id,
                   c_pt1.parameter_type_id as parameter_type_id,
                   c_d1.duration_id as duration_id,
                   a_sl.specified_level_id as specified_level_id,
                   c_bp2.base_parameter_id || substr ('-', 1, length (a_p2.sub_parameter_id)) || a_p2.sub_parameter_id as attribute_parameter_id,
                   c_pt2.parameter_type_id as attribute_parameter_type_id,
                   c_d2.duration_id as attribute_duration_id,
                   a_ll.location_level_date as level_date,
                   us.unit_system as unit_system,
                   c_uc1.to_unit_id as level_unit,
                   c_uc2.to_unit_id as attribute_unit,
                   a_ll.attribute_value * c_uc2.factor + c_uc2.offset as attribute_value,
                   a_ll.location_level_value * c_uc1.factor + c_uc1.offset as constant_level,
                   a_ll.interval_origin as interval_origin,
                   a_ll.calendar_interval as calendar_interval_,
                   a_ll.time_interval as time_interval,
                   a_ll.interpolate as interpolate,
                   null as calendar_offset_, null as time_offset_,
                   null as seasonal_level,
                   null as tsid,
                   a_ll.location_level_comment as level_comment,
                   a_ll.attribute_comment as attribute_comment,
                   a_ll.location_code,
                   a_ll.specified_level_code,
                   a_ll.parameter_code,
                   a_ll.parameter_type_code,
                   a_ll.duration_code,
                   a_ll.location_level_date,
                   a_ll.location_level_value,
                   a_ll.location_level_comment,
                   a_ll.attribute_parameter_code,
                   a_ll.attribute_parameter_type_code,
                   a_ll.attribute_duration_code,
                   a_ll.location_level_code,
                   a_ll.expiration_date
              from at_location_level a_ll,
                   at_specified_level a_sl,
                   at_physical_location a_pl,
                   at_base_location a_bl,
                   at_parameter a_p1,
                   at_parameter a_p2,
                   cwms_duration c_d1,
                   cwms_base_parameter c_bp1,
                   cwms_parameter_type c_pt1,
                   cwms_unit_conversion c_uc1,
                   cwms_duration c_d2,
                   cwms_base_parameter c_bp2,
                   cwms_parameter_type c_pt2,
                   cwms_unit_conversion c_uc2,
                   cwms_office c_o,
                   (select 'EN' as unit_system from dual
                    union all
                    select 'SI' as unit_system from dual
                   ) us
             where a_pl.location_code = a_ll.location_code
               and a_bl.base_location_code = a_pl.base_location_code
               and c_o.office_code = a_bl.db_office_code
               and a_p1.parameter_code = a_ll.parameter_code
               and c_bp1.base_parameter_code = a_p1.base_parameter_code
               and c_pt1.parameter_type_code = a_ll.parameter_type_code
               and c_d1.duration_code = a_ll.duration_code
               and a_sl.specified_level_code = a_ll.specified_level_code
               and c_uc1.from_unit_code = c_bp1.unit_code
               and c_uc1.to_unit_code =
                      decode (us.unit_system,
                              'EN', c_bp1.display_unit_code_en,
                              'SI', c_bp1.display_unit_code_si
                             )
               and a_ll.attribute_parameter_code is not null
               and a_p2.parameter_code = a_ll.attribute_parameter_code
               and c_bp2.base_parameter_code = a_p2.base_parameter_code
               and c_pt2.parameter_type_code = a_ll.attribute_parameter_type_code
               and c_d2.duration_code = a_ll.attribute_duration_code
               and c_uc2.from_unit_code = c_bp2.unit_code
               and c_uc2.to_unit_code =
                      decode (us.unit_system,
                              'EN', c_bp2.display_unit_code_en,
                              'SI', c_bp2.display_unit_code_si
                             )
               and a_ll.location_level_value is not null
               and a_ll.ts_code is null
           )
           union all
           --
           -- regularly varying (seasonal) level
           -- with attribute
           --
           (select c_o.office_id as office_id,
                   a_bl.base_location_id || substr ('-', 1, length (a_pl.sub_location_id)) || a_pl.sub_location_id as location_id,
                   c_bp1.base_parameter_id || substr ('-', 1, length (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id as parameter_id,
                   c_pt1.parameter_type_id as parameter_type_id,
                   c_d1.duration_id as duration_id,
                   a_sl.specified_level_id as specified_level_id,
                   c_bp2.base_parameter_id || substr ('-', 1, length (a_p2.sub_parameter_id)) || a_p2.sub_parameter_id as attribute_parameter_id,
                   c_pt2.parameter_type_id as attribute_parameter_type_id,
                   c_d2.duration_id as attribute_duration_id,
                   a_ll.location_level_date as level_date,
                   us.unit_system as unit_system,
                   c_uc1.to_unit_id as level_unit,
                   c_uc2.to_unit_id as attribute_unit,
                   a_ll.attribute_value * c_uc2.factor + c_uc2.offset as attribute_value,
                   null as constant_level,
                   a_ll.interval_origin as interval_origin,
                   a_ll.calendar_interval as calendar_interval_,
                   a_ll.time_interval as time_interval,
                   a_ll.interpolate as interpolate,
                   a_sll.calendar_offset as calendar_offset_,
                   a_sll.time_offset as time_offset_,
                   a_sll.value * c_uc1.factor + c_uc1.offset as seasonal_level,
                   null as tsid,
                   a_ll.location_level_comment as level_comment,
                   a_ll.attribute_comment as attribute_comment,
                   a_ll.location_code,
                   a_ll.specified_level_code,
                   a_ll.parameter_code,
                   a_ll.parameter_type_code,
                   a_ll.duration_code,
                   a_ll.location_level_date,
                   a_ll.location_level_value,
                   a_ll.location_level_comment,
                   a_ll.attribute_parameter_code,
                   a_ll.attribute_parameter_type_code,
                   a_ll.attribute_duration_code,
                   a_ll.location_level_code,
                   a_ll.expiration_date
              from at_location_level a_ll,
                   at_seasonal_location_level a_sll,
                   at_specified_level a_sl,
                   at_physical_location a_pl,
                   at_base_location a_bl,
                   at_parameter a_p1,
                   at_parameter a_p2,
                   cwms_duration c_d1,
                   cwms_base_parameter c_bp1,
                   cwms_parameter_type c_pt1,
                   cwms_unit_conversion c_uc1,
                   cwms_duration c_d2,
                   cwms_base_parameter c_bp2,
                   cwms_parameter_type c_pt2,
                   cwms_unit_conversion c_uc2,
                   cwms_office c_o,
                   (select 'EN' as unit_system from dual
                    union all
                    select 'SI' as unit_system from dual) us
            where  a_pl.location_code = a_ll.location_code
               and a_bl.base_location_code = a_pl.base_location_code
               and c_o.office_code = a_bl.db_office_code
               and a_p1.parameter_code = a_ll.parameter_code
               and c_bp1.base_parameter_code = a_p1.base_parameter_code
               and c_pt1.parameter_type_code = a_ll.parameter_type_code
               and c_d1.duration_code = a_ll.duration_code
               and a_sl.specified_level_code = a_ll.specified_level_code
               and c_uc1.from_unit_code = c_bp1.unit_code
               and c_uc1.to_unit_code =
                      decode (us.unit_system,
                              'EN', c_bp1.display_unit_code_en,
                              'SI', c_bp1.display_unit_code_si
                             )
               and a_ll.attribute_parameter_code is not null
               and a_p2.parameter_code = a_ll.attribute_parameter_code
               and c_bp2.base_parameter_code = a_p2.base_parameter_code
               and c_pt2.parameter_type_code = a_ll.attribute_parameter_type_code
               and c_d2.duration_code = a_ll.attribute_duration_code
               and c_uc2.from_unit_code = c_bp2.unit_code
               and c_uc2.to_unit_code =
                      decode (us.unit_system,
                              'EN', c_bp2.display_unit_code_en,
                              'SI', c_bp2.display_unit_code_si
                             )
               and a_ll.location_level_value is null
               and a_ll.ts_code is null
               and a_sll.location_level_code = a_ll.location_level_code
           )
           union all
           --
           -- irregularly varying (time series) level
           -- withtout attribute
           --
           (select c_o.office_id as office_id,
                   a_bl.base_location_id || substr ('-', 1, length (a_pl.sub_location_id)) || a_pl.sub_location_id as location_id,
                   c_bp1.base_parameter_id || substr ('-', 1, length (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id as parameter_id,
                   c_pt1.parameter_type_id as parameter_type_id,
                   c_d1.duration_id as duration_id,
                   a_sl.specified_level_id as specified_level_id,
                   null as attribute_parameter_id,
                   null as attribute_parameter_type_id,
                   null as attribute_duration_id,
                   a_ll.location_level_date as level_date,
                   null as unit_system,
                   null as level_unit,
                   null as attribute_unit,
                   a_ll.attribute_value as attribute_value,
                   null as constant_level,
                   a_ll.interval_origin as interval_origin,
                   a_ll.calendar_interval as calendar_interval_,
                   a_ll.time_interval as time_interval,
                   a_ll.interpolate as interpolate,
                   null as calendar_offset_, null as time_offset_,
                   null as seasonal_level,
                   cwms_ts.get_ts_id(a_ll.ts_code) as tsid,
                   a_ll.location_level_comment as level_comment,
                   a_ll.attribute_comment as attribute_comment,
                   a_ll.location_code,
                   a_ll.specified_level_code,
                   a_ll.parameter_code,
                   a_ll.parameter_type_code,
                   a_ll.duration_code,
                   a_ll.location_level_date,
                   a_ll.location_level_value,
                   a_ll.location_level_comment,
                   a_ll.attribute_parameter_code,
                   a_ll.attribute_parameter_type_code,
                   a_ll.attribute_duration_code,
                   a_ll.location_level_code,
                   a_ll.expiration_date
            from   at_location_level a_ll,
                   at_specified_level a_sl,
                   at_physical_location a_pl,
                   at_base_location a_bl,
                   at_parameter a_p1,
                   cwms_duration c_d1,
                   cwms_base_parameter c_bp1,
                   cwms_parameter_type c_pt1,
                   cwms_office c_o
             where a_pl.location_code = a_ll.location_code
               and a_bl.base_location_code = a_pl.base_location_code
               and c_o.office_code = a_bl.db_office_code
               and a_p1.parameter_code = a_ll.parameter_code
               and c_bp1.base_parameter_code = a_p1.base_parameter_code
               and c_pt1.parameter_type_code = a_ll.parameter_type_code
               and c_d1.duration_code = a_ll.duration_code
               and a_sl.specified_level_code = a_ll.specified_level_code
               and a_ll.attribute_parameter_code is null
               and a_ll.location_level_value is null
               and a_ll.ts_code is not null
           )
           union all
           --
           -- irregularly varying (time series) level
           -- with attribute
           --
           (select c_o.office_id as office_id,
                   a_bl.base_location_id || substr ('-', 1, length (a_pl.sub_location_id)) || a_pl.sub_location_id as location_id,
                   c_bp1.base_parameter_id || substr ('-', 1, length (a_p1.sub_parameter_id)) || a_p1.sub_parameter_id as parameter_id,
                   c_pt1.parameter_type_id as parameter_type_id,
                   c_d1.duration_id as duration_id,
                   a_sl.specified_level_id as specified_level_id,
                   c_bp2.base_parameter_id || substr ('-', 1, length (a_p2.sub_parameter_id)) || a_p2.sub_parameter_id as attribute_parameter_id,
                   c_pt2.parameter_type_id as attribute_parameter_type_id,
                   c_d2.duration_id as attribute_duration_id,
                   a_ll.location_level_date as level_date,
                   us.unit_system as unit_system,
                   null as level_unit,
                   c_uc2.to_unit_id as attribute_unit,
                   a_ll.attribute_value * c_uc2.factor + c_uc2.offset as attribute_value,
                   null as constant_level,
                   a_ll.interval_origin as interval_origin,
                   a_ll.calendar_interval as calendar_interval_,
                   a_ll.time_interval as time_interval,
                   a_ll.interpolate as interpolate,
                   null as calendar_offset_,
                   null as time_offset_,
                   null as seasonal_level,
                   cwms_ts.get_ts_id(a_ll.ts_code) as tsid,
                   a_ll.location_level_comment as level_comment,
                   a_ll.attribute_comment as attribute_comment,
                   a_ll.location_code,
                   a_ll.specified_level_code,
                   a_ll.parameter_code,
                   a_ll.parameter_type_code,
                   a_ll.duration_code,
                   a_ll.location_level_date,
                   a_ll.location_level_value,
                   a_ll.location_level_comment,
                   a_ll.attribute_parameter_code,
                   a_ll.attribute_parameter_type_code,
                   a_ll.attribute_duration_code,
                   a_ll.location_level_code,
                   a_ll.expiration_date
              from at_location_level a_ll,
                   at_specified_level a_sl,
                   at_physical_location a_pl,
                   at_base_location a_bl,
                   at_parameter a_p1,
                   at_parameter a_p2,
                   cwms_duration c_d1,
                   cwms_base_parameter c_bp1,
                   cwms_parameter_type c_pt1,
                   cwms_duration c_d2,
                   cwms_base_parameter c_bp2,
                   cwms_parameter_type c_pt2,
                   cwms_unit_conversion c_uc2,
                   cwms_office c_o,
                   (select 'EN' as unit_system from dual
                    union all
                    select 'SI' as unit_system from dual
                   ) us
             where a_pl.location_code = a_ll.location_code
               and a_bl.base_location_code = a_pl.base_location_code
               and c_o.office_code = a_bl.db_office_code
               and a_p1.parameter_code = a_ll.parameter_code
               and c_bp1.base_parameter_code = a_p1.base_parameter_code
               and c_pt1.parameter_type_code = a_ll.parameter_type_code
               and c_d1.duration_code = a_ll.duration_code
               and a_sl.specified_level_code = a_ll.specified_level_code
               and a_ll.attribute_parameter_code is not null
               and a_p2.parameter_code = a_ll.attribute_parameter_code
               and c_bp2.base_parameter_code = a_p2.base_parameter_code
               and c_pt2.parameter_type_code = a_ll.attribute_parameter_type_code
               and c_d2.duration_code = a_ll.attribute_duration_code
               and c_uc2.from_unit_code = c_bp2.unit_code
               and c_uc2.to_unit_code =
                      decode (us.unit_system,
                              'EN', c_bp2.display_unit_code_en,
                              'SI', c_bp2.display_unit_code_si
                             )
               and a_ll.location_level_value is null
               and a_ll.ts_code is not null)
           ) q1
           left outer join
           (select location_code,
                   specified_level_code,
                   parameter_code,
                   parameter_type_code,
                   duration_code,
                   attr_value,
                   attr_parameter_code,
                   attr_parameter_type_code,
                   attr_duration_code,
                   label
              from at_loc_lvl_label
             where configuration_code = 1 -- default configuration
           ) q2 on q2.location_code                                 = q1.location_code
               and q2.specified_level_code                          = q1.specified_level_code
               and q2.parameter_code                                = q1.parameter_code
               and q2.parameter_type_code                           = q1.parameter_type_code
               and q2.duration_code                                 = q1.duration_code
               and nvl(cwms_rounding.round_f(q2.attr_value, 9), -1) = nvl(cwms_rounding.round_f(q1.attribute_value, 9), -1)
               and nvl(q2.attr_parameter_code, -1)                  = nvl(q1.attribute_parameter_code, -1)
               and nvl(q2.attr_parameter_type_code, -1)             = nvl(q1.attribute_parameter_type_code, -1)
               and nvl(q2.attr_duration_code, -1)                   = nvl(q1.attribute_duration_code, -1)
           left outer join
           (select location_code,
                   specified_level_code,
                   parameter_code,
                   parameter_type_code,
                   duration_code,
                   attr_value,
                   attr_parameter_code,
                   attr_parameter_type_code,
                   attr_duration_code,
                   cwms_entity.get_entity_id(source_entity) as source_entity
              from at_loc_lvl_source
           ) q3 on q3.location_code                                 = q1.location_code
               and q3.specified_level_code                          = q1.specified_level_code
               and q3.parameter_code                                = q1.parameter_code
               and q3.parameter_type_code                           = q1.parameter_type_code
               and q3.duration_code                                 = q1.duration_code
               and nvl(cwms_rounding.round_f(q3.attr_value, 9), -1) = nvl(cwms_rounding.round_f(q1.attribute_value, 9), -1)
               and nvl(q3.attr_parameter_code, -1)                  = nvl(q1.attribute_parameter_code, -1)
               and nvl(q3.attr_parameter_type_code, -1)             = nvl(q1.attribute_parameter_type_code, -1)
               and nvl(q3.attr_duration_code, -1)                   = nvl(q1.attribute_duration_code, -1)
           order by q1.office_id,
              q1.location_id || '.' || q1.parameter_id || '.' || q1.parameter_type_id || '.' || q1.duration_id || '.' || q1.specified_level_id,
              q1.attribute_parameter_id || substr ('.', 1, length (q1.attribute_parameter_type_id)) || q1.attribute_parameter_type_id || substr ('.', 1, length (q1.attribute_duration_id)) || q1.attribute_duration_id,
              q1.level_date,
              q1.unit_system,
              q1.attribute_value,
              q1.interval_origin + q1.calendar_offset_ + q1.time_offset_;

create or replace public synonym cwms_v_location_level_curval for av_location_level_curval;
