delete from at_clob where id = '/VIEWDOCS/MV_LOCATION_LEVEL_CURVAL';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/MV_LOCATION_LEVEL_CURVAL', null,
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
 * @field ll_as_of                      The date/time that this snapshot was last refreshed
*/
');

create materialized view mv_location_level_curval
   tablespace cwms_20data
   build immediate using index
   refresh force on demand start with sysdate next sysdate+1/24 with rowid using trusted constraints
as
   select ll.*,
          sysdate as ll_as_of
     from av_location_level_curval ll;

create index mv_location_level_curval_idx2 on mv_location_level_curval (office_id, location_level_id, current_value_en, value_unit_en, varying_type);
create index mv_location_level_curval_idx3 on mv_location_level_curval (office_id, location_level_id, varying_type, location_code, location_id, attribute_value_en, attribute_unit_si);

comment on materialized view mv_location_level_curval is 'Snapshot table for CWMS_20.AV_LOCATION_LEVEL_CURVAL view';

create or replace public synonym cwms_v_mlocation_level_curval for mv_location_level_curval;
