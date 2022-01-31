create type zlocation_level_t
-- not documented
is object(
   location_level_code           number(14),
   location_code                 number(14),
   specified_level_code          number(14),
   parameter_code                number(14),
   parameter_type_code           number(14),
   duration_code                 number(14),
   location_level_date           date,
   location_level_value          number,
   location_level_comment        varchar2(256),
   attribute_value               number,
   attribute_parameter_code      number(14),
   attribute_param_type_code     number(14),
   attribute_duration_code       number(14),
   attribute_comment             varchar2(256),
   interval_origin               date,
   calendar_interval             interval year(2) to month,
   time_interval                 interval day(3) to second(0),
   interpolate                   varchar2(1),
   ts_code                       number(14),
   expiration_date               date,
   seasonal_level_values         seasonal_loc_lvl_tab_t,
   indicators                    loc_lvl_indicator_tab_t,
   constituents                  str_tab_tab_t,
   connections                   varchar2(256),

   constructor function zlocation_level_t(
      p_location_level_code           in number)
      return self as result,

   constructor function zlocation_level_t
      return self as result,

   member procedure init(
      p_location_level_code           in number,
      p_location_code                 in number,
      p_specified_level_code          in number,
      p_parameter_code                in number,
      p_parameter_type_code           in number,
      p_duration_code                 in number,
      p_location_level_date           in date,
      p_location_level_value          in number,
      p_location_level_comment        in varchar2,
      p_attribute_value               in number,
      p_attribute_parameter_code      in number,
      p_attribute_param_type_code     in number,
      p_attribute_duration_code       in number,
      p_attribute_comment             in varchar2,
      p_interval_origin               in date,
      p_calendar_interval             in interval year to month,
      p_time_interval                 in interval day to second,
      p_interpolate                   in varchar2,
      p_ts_code                       in number,
      p_expiration_date               in date,
      p_seasonal_values               in seasonal_loc_lvl_tab_t,
      p_indicators                    in loc_lvl_indicator_tab_t,
      p_constituents                  in str_tab_tab_t,
      p_connections                   in varchar2),

   member procedure store
);
/


create or replace public synonym cwms_t_zlocation_level for zlocation_level_t;

