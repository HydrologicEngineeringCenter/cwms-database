/**
 * Displays information about concrete location levels
 *
 * @since CWMS 2.1 (extended in 3.0)
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
 */

--------------------------------------------------------------------------------
-- AV_LOCATION_LEVEL_XXXX5h3
-- 
-- XXXX5h3      MATERIALIZE the UNITS sub-select
--              calls CWMS_20 RETRIEVE_USER_UNIT_F with 4 parameters (no defaults)
--              This requires NULL parameter filtering for the attribute parameter
--              Tried using filtering WITH function (later permissions issue found)
--              Appears to be an Oracle bug: WITH function references resolved at run time
--              CASE expression filtering works
--------------------------------------------------------------------------------

--create or replace force view av_location_level
create or replace force view av_location_level
( OFFICE_ID, 
  LOCATION_LEVEL_ID, 
  ATTRIBUTE_ID, 
  LEVEL_DATE, 
  UNIT_SYSTEM, 
  ATTRIBUTE_UNIT, 
  LEVEL_UNIT, 
  ATTRIBUTE_VALUE, 
  CONSTANT_LEVEL, 
  INTERVAL_ORIGIN, 
  CALENDAR_INTERVAL,
  TIME_INTERVAL, 
  INTERPOLATE, 
  CALENDAR_OFFSET, 
  TIME_OFFSET, 
  SEASONAL_LEVEL, 
  TSID, 
  LEVEL_COMMENT, 
  ATTRIBUTE_COMMENT, 
  BASE_LOCATION_ID, 
  SUB_LOCATION_ID, 
  LOCATION_ID, 
  BASE_PARAMETER_ID, 
  SUB_PARAMETER_ID, 
  PARAMETER_ID, 
  DURATION_ID, 
  SPECIFIED_LEVEL_ID, 
  LOCATION_CODE, 
  LOCATION_LEVEL_CODE, 
  EXPIRATION_DATE, 
  PARAMETER_TYPE_ID, 
  ATTRIBUTE_PARAMETER_ID, 
  ATTRIBUTE_BASE_PARAMETER_ID, 
  ATTRIBUTE_SUB_PARAMETER_ID, 
  ATTRIBUTE_PARAMETER_TYPE_ID, 
  ATTRIBUTE_DURATION_ID,
  DEFAULT_LABEL, 
  "SOURCE"
)
as
with 
function dash (p1 varchar2, p2 varchar2) return varchar2 as
   begin
      return p1||case when p2 is not null then '-' end||p2;
      --return p1||NVL2(p2,'-'||p2,'');
   end;
parameters as
(  select 
          c_bp1.base_parameter_code, 
          a_ll.parameter_code,
          c_bp1.base_parameter_id, 
          a_p1.sub_parameter_id, 
          dash(c_bp1.base_parameter_id, a_p1.sub_parameter_id) as parameter_id,
          c_bp1.display_unit_code_si                           as default_unit_code, 
          c_bp2.base_parameter_code                            as attribute_base_parameter_code, 
          a_ll.attribute_parameter_code                        as attribute_parameter_code, 
          c_bp2.base_parameter_id                              as attribute_base_parameter_id, 
          a_p2.sub_parameter_id                                as attribute_sub_parameter_id,
          dash(c_bp2.base_parameter_id, a_p2.sub_parameter_id) as attribute_parameter_id, 
          c_bp2.display_unit_code_si                           as attribute_default_unit_code,
          --   For unit conversion
          --   Scalar Sub-query Caching works well here
          ( select cwms_util.get_user_id    from dual )        as user_id,
          ( select cwms_util.user_office_id from dual )        as user_office_id          
   from   ( select distinct parameter_code, attribute_parameter_code from at_location_level)   a_ll  left join 
          at_parameter        a_p1   on (a_p1.parameter_code       = a_ll.parameter_code)            left join
          at_parameter        a_p2   on (a_p2.parameter_code       = a_ll.attribute_parameter_code)  left join
          cwms_base_parameter c_bp1  on (c_bp1.base_parameter_code = a_p1.base_parameter_code)       left join
          cwms_base_parameter c_bp2  on (c_bp2.base_parameter_code = a_p2.base_parameter_code)
)
, units as
(  select /*+ MATERIALIZE */ t.*, 
          us.unit_system, 
          c_cu1.unit_id                                                                             as parm_def_units,
          c_cu2.unit_id                                                                             as attr_parm_def_units, 
          cwms_display.retrieve_user_unit_f(parameter_id, us.unit_system, user_id, user_office_id)  as parm_user_units,  
          case 
          when attribute_parameter_id is null then null 
          else cwms_display.retrieve_user_unit_f(attribute_parameter_id, us.unit_system, user_id, user_office_id)  
          end                                                                                       as attr_parm_user_units
   from   parameters         t                                                     left join
          cwms_unit      c_cu1  on (c_cu1.unit_code = default_unit_code)           left join
          cwms_unit      c_cu2  on (c_cu2.unit_code = attribute_default_unit_code) cross join 
          ( select 'EN' as unit_system from dual union all select 'SI' as unit_system from dual ) us     
) 
, factors as
(  select  t.*, 
          c_cuc1.factor, 
          c_cuc1.offset, 
          c_cuc1.function,
          c_cuc2.factor   as attr_factor, 
          c_cuc2.offset   as attr_offset, 
          c_cuc2.function as attr_function
   from   units                     t                                                      left join
          cwms_unit_conversion c_cuc1 on (c_cuc1.from_unit_id = t.parm_def_units and 
                                          c_cuc1.to_unit_id   = t.parm_user_units)         left join
          cwms_unit_conversion c_cuc2 on (c_cuc2.from_unit_id = t.attr_parm_def_units and 
                                          c_cuc2.to_unit_id   = t.attr_parm_user_units) 
) 
, location_level as
(  select location_level_code, location_code, specified_level_code, --parameter_code, 
          parameter_type_code, duration_code, 
          location_level_date, location_level_value, location_level_comment, --attribute_parameter_code, 
          attribute_parameter_type_code, attribute_duration_code, attribute_value, attribute_comment, 
          interval_origin, calendar_interval, time_interval, interpolate, ts_code, expiration_date
          , f.*
   from   at_location_level  a_ll  left join -- 3498 rows
          factors               f  on (f.parameter_code = a_ll.parameter_code and 
                                       nvl(f.attribute_parameter_code,-1) = nvl(a_ll.attribute_parameter_code,-1))
)
, location_level_id as
(  select a_ll.*,
          c_o.office_id,
          a_bl.base_location_id, 
          a_pL.sub_location_id,
          dash(a_bl.base_location_id, a_pL.sub_location_id) as location_id,
          c_pt1.parameter_type_id,
          c_d1.duration_id,
          a_sl.specified_level_id, 
          c_pt2.parameter_type_id     as attribute_parameter_type_id,
          c_d2.duration_id            as attribute_duration_id,
          a_ll.location_level_date    as level_date,
          a_ll.location_level_value   as constant_level,
          a_ll.calendar_interval      as calendar_interval_,
          a_sll.calendar_offset       as calendar_offset_,
          a_sll.time_offset           as time_offset_,
          a_sll.value                 as seasonal_level,
          a_id.cwms_ts_id             as tsid,
          a_ll.location_level_comment as level_comment
   from   location_level              a_ll   left join 
          at_specified_level          a_sl   on (a_sl.specified_level_code = a_ll.specified_level_code)          left join
          cwms_duration               c_d1   on (c_d1.duration_code        = a_ll.duration_code)                 left join
          cwms_duration               c_d2   on (c_d2.duration_code        = a_ll.attribute_duration_code)       left join
          cwms_parameter_type         c_pt1  on (c_pt1.parameter_type_code = a_ll.parameter_type_code)           left join
          cwms_parameter_type         c_pt2  on (c_pt2.parameter_type_code = a_ll.attribute_parameter_type_code) left join 
          at_parameter                a_p1   on (a_p1.parameter_code       = a_ll.parameter_code)                left join
          at_parameter                a_p2   on (a_p2.parameter_code       = a_ll.attribute_parameter_code)      left join
          cwms_base_parameter         c_bp1  on (c_bp1.base_parameter_code = a_p1.base_parameter_code)           left join
          at_physical_location        a_pL   on (a_pL.location_code        = a_ll.location_code)                 left join
          at_base_location            a_bl   on (a_bl.base_location_code   = a_pL.base_location_code)            left join
          cwms_office                 c_o    on (c_o.office_code           = a_bl.db_office_code)                left join
          cwms_base_parameter         c_bp1  on (c_bp1.base_parameter_code = a_p1.base_parameter_code)           left join
          cwms_base_parameter         c_bp2  on (c_bp2.base_parameter_code = a_p2.base_parameter_code)           left join
          at_seasonal_location_level  a_sll  on (a_sll.location_level_code = a_ll.location_level_code)           left join
          at_cwms_ts_id               a_id   on (a_id.ts_code              = a_ll.ts_code) 
) 
select q1.office_id,
       q1.location_id || '.' || q1.parameter_id || '.' || q1.parameter_type_id || '.' || q1.duration_id || '.' || q1.specified_level_id as location_level_id,        
       -- q1.attribute_parameter_id, q1.attribute_parameter_type_id, q1.attribute_duration_id,
       -- the following is a bit confusing
       -- it is possible to have "parameter_id.duration_id" without a parameter_type_id
       q1.attribute_parameter_id || substr ('.', 1, length (q1.attribute_parameter_type_id)) || q1.attribute_parameter_type_id || substr ('.', 1, length (q1.attribute_duration_id)) || q1.attribute_duration_id as attribute_id,
       q1.level_date,
       q1.unit_system,
       q1.attr_parm_user_units                          as attribute_unit,
       q1.parm_user_units                               as level_unit,
       case 
       when q1.attr_function is null 
       then q1.attribute_value * q1.attr_factor + q1.attr_offset 
       else cwms_util.eval_expression(q1.attr_function, double_tab_t(q1.attribute_value))
       end                                              as attribute_value,
       case 
       when q1.function is null 
       then q1.constant_level * q1.factor + q1.offset 
       else cwms_util.eval_expression(q1.function, double_tab_t(q1.attribute_value))
       end                                              as constant_level,
       q1.interval_origin,
       substr (q1.calendar_interval_, 2)                as calendar_interval,
       q1.time_interval, 
       q1.interpolate,
       substr (q1.calendar_offset_, 2)                  as calendar_offset,
       substr (q1.time_offset_, 2)                      as time_offset,        
       case 
       when q1.function is null 
       then q1.seasonal_level * q1.factor + q1.offset 
       else cwms_util.eval_expression(q1.function, double_tab_t(q1.seasonal_level))
       end                                              as seasonal_level, 
       q1.tsid, 
       q1.level_comment, 
       q1.attribute_comment,
       q1.base_location_id, 
       q1.sub_location_id,        
       q1.location_id, 
       q1.base_parameter_id, 
       q1.sub_parameter_id, 
       q1.parameter_id, 
       q1.duration_id, 
       q1.specified_level_id, 
       q1.location_code, 
       q1.location_level_code, 
       q1.expiration_date, 
       q1.parameter_type_id, 
       q1.attribute_parameter_id,  
       q1.attribute_base_parameter_id, 
       q1.attribute_sub_parameter_id,
       q1.attribute_parameter_type_id,
       q1.attribute_duration_id, 
       q2.label as default_label,
       -- probably want to put this in a DETERMINISTIC WITH function
       cwms_entity.get_entity_id(source_entity)         as source     
from   location_level_id q1  left outer join            
       at_loc_lvl_label  q2  on ( q2.configuration_code                                = 1 -- default configuration
                                  and q2.location_code                                 = q1.location_code
                                  and q2.specified_level_code                          = q1.specified_level_code
                                  and q2.parameter_code                                = q1.parameter_code
                                  and q2.parameter_type_code                           = q1.parameter_type_code
                                  and q2.duration_code                                 = q1.duration_code
                                  and nvl(cwms_rounding.round_f(q2.attr_value, 9), -1) = nvl(cwms_rounding.round_f(q1.attribute_value, 9), -1)
                                  and nvl(q2.attr_parameter_code, -1)                  = nvl(q1.attribute_parameter_code, -1)
                                  and nvl(q2.attr_parameter_type_code, -1)             = nvl(q1.attribute_parameter_type_code, -1)
                                  and nvl(q2.attr_duration_code, -1)                   = nvl(q1.attribute_duration_code, -1) )
                             left outer join
      at_loc_lvl_source  q3  on ( q3.location_code                                     = q1.location_code
                                  and q3.specified_level_code                          = q1.specified_level_code
                                  and q3.parameter_code                                = q1.parameter_code
                                  and q3.parameter_type_code                           = q1.parameter_type_code
                                  and q3.duration_code                                 = q1.duration_code
                                  and nvl(cwms_rounding.round_f(q3.attr_value, 9), -1) = nvl(cwms_rounding.round_f(q1.attribute_value, 9), -1)
                                  and nvl(q3.attr_parameter_code, -1)                  = nvl(q1.attribute_parameter_code, -1)
                                  and nvl(q3.attr_parameter_type_code, -1)             = nvl(q1.attribute_parameter_type_code, -1)
                                  and nvl(q3.attr_duration_code, -1)                   = nvl(q1.attribute_duration_code, -1) )
      --  WHAT IS THE COST OF THIS SORT AND IS IT BETTER TO LET THE USER SPECIFY 
      --  THE SORT ORDER IF IT IS IMPORTANT?
      --  MAYBE THE VIEW SHOULD PASS THE "EFFECTIVE DATE" AS COMPUTED IN THE ORDER BY
order  by q1.office_id,
          q1.location_id || '.' || q1.parameter_id || '.' || q1.parameter_type_id || '.' || q1.duration_id || '.' || q1.specified_level_id,
          q1.attribute_parameter_id || substr ('.', 1, length (q1.attribute_parameter_type_id)) || q1.attribute_parameter_type_id || substr ('.', 1, length (q1.attribute_duration_id)) || q1.attribute_duration_id,
          q1.level_date,
          q1.unit_system,
          q1.attribute_value,
          q1.interval_origin + q1.calendar_offset_ + q1.time_offset_
;
/


begin
	execute immediate 'grant select on av_location_level to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_location_level for av_location_level;
