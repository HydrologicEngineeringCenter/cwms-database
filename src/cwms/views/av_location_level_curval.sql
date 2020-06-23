--delete from at_clob where id = '/VIEWDOCS/AV_LOCATION_LEVEL_CURVAL';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOCATION_LEVEL_CURVAL', null,
'
/**
 * Displays information about location levels, including the current value
 *
 * @since Schema 18.1
 *
 * @field office_id                     The office that owns the location level
 * @field location_level_id             The location level identifier
 * @field attribute_id                  The attribute identifier, if any, for the location level
 * @field attribute_value_si            The value of the attribute, if any, in the SI default unit
 * @field attribute_unit_si             The default SI unit of attribute value, if any
 * @field attribute_value_en            The value of the attribute, if any, in the Default english unit
 * @field attribute_unit_en             The default English unit of attribute value, if any
 * @field current_value_si              The value of the location level at the current time, in the default SI unit
 * @field value_unit_si                 The default SI unit of location level value
 * @field current_value_en              The value of the location level at the current time, in the default English unit
 * @field value_unit_en                 The default English unit of location level value
 * @field varying_type                  The manner in which the level value varies with time: CONSTANT, REGULAR, or IRREGULAR
 * @field effective_date_utc            The date/time in UTC that the current definition of the location level became effective
 * @field effective_date_local          The date/time in the location''s local time zone that the current definition of the location level became effective
 * @field local_time_zone               The location''s local time zone
 * @field expiration_date_utc           The date/time in UTC that the current definition of the location level expires, if any. If prior to current time, the current value will be null
 * @field expiration_date_local         The date/time in the location''s local time zone that the current definition of the location level expires, if any. If prior to current time, the current value will be null
 * @field location_id                   The location portion of the location level
 * @field parameter_id                  The parameter portion of the location level
 * @field parameter_type_id             The parameter type of the location level
 * @field duration_id                   The duration portion of the location level
 * @field specified_level_id            The specified level portion of the location level
 * @field attribute_parameter_id        The attribute of the parameter, if any
 * @field attribute_parameter_type_id   The parameter type of the attribute, if any
 * @field attribute_duration_id         The duration of the attribute, if any
 * @field location_level_code           The unique numeric code that identifies the location level in the database
 * @field office_code                   The unique numeric code that identifies the office in the database
 * @field location_code                 The unique numeric code that identifies the location in the database
 * @field base_parameter_code           The unique numeric code that identifies the base parameter in the database
 * @field parameter_code                The unique numeric code that identifies the parameter in the database
 * @field duration_code                 The unique numeric code that identifies the duration in the database
 * @field specified_level_code          The unique numeric code that identifies the specified level in the database
 * @field attribute_base_parameter_code The unique numeric code that identifies the attribute base parameter in the database
 * @field attribute_parameter_code      The unique numeric code that identifies the attribute parameter in the database
 * @field attribute_duration_code       The unique numeric code that identifies the attribute duration in the database
*/
');

create or replace force view av_location_level_curval
as
select q1.office_id,
       q1.location_level_id,
       q2.attribute_id,
       cwms_rounding.round_f(q1.attribute_value, 10) as attribute_value_si,
       q2.unit_si as attribute_unit_si,
       cwms_rounding.round_f(cwms_util.convert_units(q1.attribute_value, q2.unit_si, q2.unit_en), 10) as attribute_value_en,
       q2.unit_en as attribute_unit_en,
       cwms_rounding.round_f(cwms_level.retrieve_loc_lvl_value_ex(
         p_location_level_id => q1.location_level_id,
         p_level_units       => cwms_display.retrieve_user_unit_f(q1.parameter_id, 'SI'),
         p_attribute_id      => q2.attribute_id,
         p_attribute_value   => q1.attribute_value,
         p_attribute_units   => q2.unit_si,
         p_ignore_errors     => 'T',
         p_office_id         => q1.office_id), 10) as current_value_si,
       cwms_display.retrieve_user_unit_f(q1.parameter_id, 'SI') as value_unit_si,
       cwms_rounding.round_f(cwms_level.retrieve_loc_lvl_value_ex(
         p_location_level_id => q1.location_level_id,
         p_level_units       => cwms_display.retrieve_user_unit_f(q1.parameter_id, 'EN'),
         p_attribute_id      => q2.attribute_id,
         p_attribute_value   => q1.attribute_value,
         p_attribute_units   => q2.unit_si,
         p_ignore_errors     => 'T',
         p_office_id         => q1.office_id), 10) as current_value_en,
       cwms_display.retrieve_user_unit_f(q1.parameter_id, 'EN') as value_unit_en,
       case
       when q1.location_level_value is not null then 'CONSTANT'
       when q1.interval_origin is not null then 'REGULAR'
       when q1.ts_code is not null then 'IRREGULAR'
       else 'UNKNOWN'
       end as varying_type,
       q1.location_level_date as effective_date_utc,
       cwms_util.change_timezone(q1.location_level_date, 'UTC', cwms_loc.get_local_timezone(q1.location_code)) as effective_date_local,
       cwms_loc.get_local_timezone(q1.location_code) as local_time_zone,
       q1.expiration_date as expiration_date_utc,
       cwms_util.change_timezone(q1.expiration_date, 'UTC', cwms_loc.get_local_timezone(q1.location_code)) as expiration_date_local,
       q1.location_id,
       q1.parameter_id,
       q1.parameter_type_id,
       q1.duration_id,
       q1.specified_level_id,
       q2.parameter_id as attribute_parameter_id,
       q2.parameter_type_id as attribute_parameter_type_id,
       q2.duration_id as attribute_duration_id,
       q1.location_level_code,
       q1.office_code,
       q1.location_code,
       q1.base_parameter_code,
       q1.parameter_code,
       q1.duration_code,
       q1.specified_level_code,
       q2.base_parameter_code as attribute_base_parameter_code,
       q2.parameter_code as attribute_parameter_code,
       q2.duration_code as attribute_duration_code
  from (select o.office_id,
               bl.base_location_id
               ||substr('-', 1, length(pl.sub_location_id))
               ||pl.sub_location_id
               ||'.'
               ||bp1.base_parameter_id
               ||substr('-', 1, length(p1.sub_parameter_id))
               ||p1.sub_parameter_id
               ||'.'
               ||pt1.parameter_type_id
               ||'.'
               ||d1.duration_id
               ||'.'
               ||sl.specified_level_id as location_level_id,
               bl.base_location_id
               ||substr('-', 1, length(pl.sub_location_id))
               ||pl.sub_location_id as location_id,
               bp1.base_parameter_id
               ||substr('-', 1, length(p1.sub_parameter_id))
               ||p1.sub_parameter_id as parameter_id,
               pt1.parameter_type_id,
               d1.duration_id,
               sl.specified_level_id,
               ll.location_code,
               ll.location_level_date,
               ll.expiration_date,
               ll.attribute_value,
               ll.attribute_parameter_code,
               ll.attribute_parameter_type_code,
               ll.attribute_duration_code,
               ll.location_level_value,
               ll.interval_origin,
               ll.ts_code,
               ll.location_level_code,
               o.office_code,
               bp1.base_parameter_code,
               ll.parameter_code,
               ll.duration_code,
               ll.specified_level_code
         from at_location_level ll,
              at_physical_location pl,
              at_base_location bl,
              cwms_office o,
              at_parameter p1,
              cwms_base_parameter bp1,
              cwms_parameter_type pt1,
              cwms_duration d1,
              at_specified_level sl
        where (ll.location_code,
               ll.parameter_code,
               ll.parameter_type_code,
               ll.duration_code,
               ll.specified_level_code,
               nvl(ll.attribute_parameter_code, -1),
               nvl(ll.attribute_parameter_type_code, -1),
               nvl(ll.attribute_duration_code, -1),
               nvl(ll.attribute_value, -1),
               ll.location_level_date) in
              (select location_code,
                      parameter_code,
                      parameter_type_code,
                      duration_code,
                      specified_level_code,
                      nvl(attribute_parameter_code, -1),
                      nvl(attribute_parameter_type_code, -1),
                      nvl(attribute_duration_code, -1),
                      nvl(attribute_value, -1),
                      max(location_level_date) as location_level_date
                 from at_location_level
                group by location_code,
                         parameter_code,
                         parameter_type_code,
                         duration_code,
                         specified_level_code,
                         nvl(attribute_parameter_code, -1),
                         nvl(attribute_parameter_type_code, -1),
                         nvl(attribute_duration_code, -1),
                         nvl(attribute_value, -1)
              )
          and pl.location_code = ll.location_code
          and bl.base_location_code = pl.base_location_code
          and o.office_code = bl.db_office_code
          and p1.parameter_code = ll.parameter_code
          and bp1.base_parameter_code = p1.base_parameter_code
          and pt1.parameter_type_code = ll.parameter_type_code
          and d1.duration_code = ll.duration_code
          and sl.specified_level_code = ll.specified_level_code
       ) q1
       left outer join
       (select p.parameter_code,
               pt.parameter_type_code,
               d.duration_code,
               bp.base_parameter_code,
               bp.base_parameter_id
               ||substr('-', 1, length(p.sub_parameter_id))
               ||p.sub_parameter_id
               ||'.'
               ||pt.parameter_type_id
               ||'.'
               ||d.duration_id as attribute_id,
               bp.base_parameter_id
               ||substr('-', 1, length(p.sub_parameter_id))
               ||p.sub_parameter_id as parameter_id,
               pt.parameter_type_id,
               d.duration_id,
               cwms_display.retrieve_user_unit_f(bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id)) ||p.sub_parameter_id, 'SI') as unit_si,
               cwms_display.retrieve_user_unit_f(bp.base_parameter_id||substr('-', 1, length(p.sub_parameter_id)) ||p.sub_parameter_id, 'EN') as unit_en
          from at_parameter p,
               cwms_base_parameter bp,
               cwms_parameter_type pt,
               cwms_duration d
         where bp.base_parameter_code = p.base_parameter_code
       ) q2 on q2.parameter_code = q1.attribute_parameter_code
           and q2.parameter_type_code = q1.attribute_parameter_type_code
           and q2.duration_code = q1.attribute_duration_code;

begin
	execute immediate 'grant select on av_location_level_curval to cwms_user';
exception
	when others then null;
end;

create or replace public synonym cwms_v_location_level_curval for av_location_level_curval;
