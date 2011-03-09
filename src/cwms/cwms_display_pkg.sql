create or replace package cwms_display as
--------------------------------------------------------------------------------
-- procedure adjust_scale_limits
--
-- p_adjustment_level
--    determines whether and how the limits are adjusted
--
--    0 - no adjustement
--    1 - range (max - min) follows 1-2-5 increment rule, and min is an even
--        multiple of increment
--    2 - range (max - min) follows 1-2-5 increment rule, and min is an even
--        multiple of range
--        
--------------------------------------------------------------------------------
procedure adjust_scale_limits(
   p_min_value        in out number,
   p_max_value        in out number,
   p_adjustment_level in     integer);

--------------------------------------------------------------------------------
-- procedure store_scale_limits
--------------------------------------------------------------------------------
procedure store_scale_limits(
   p_location_id    in varchar2,
   p_parameter_id   in varchar2, 
   p_unit_id        in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_scale_min      in number,
   p_scale_max      in number,
   p_office_id      in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure retrieve_scale_limits
--
-- p_adjustment_level
--    determines whether and how the limits are adjusted
--
--    0 - no adjustement
--    1 - range (max - min) follows 1-2-5 increment rule, and min is an even
--        multiple of increment
--    2 - range (max - min) follows 1-2-5 increment rule, and min is an even
--        multiple of range
--
-- p_derived
--    speifies whether returned limits were determined by a match with
--    p_unit_id ('F') or derived from limits set for another unit ('T')
--        
--------------------------------------------------------------------------------
procedure retrieve_scale_limits(
   p_scale_min        out number,
   p_scale_max        out number,
   p_derived          out varchar2,
   p_location_id      in  varchar2,
   p_parameter_id     in  varchar2, 
   p_unit_id          in  varchar2, 
   p_adjustment_level in  number default 0,
   p_office_id        in  varchar2 default null);

--------------------------------------------------------------------------------
-- procedure delete_scale_limits
--
-- p_unit_id
--    unit to delete scale limits for, if NULL, delete scale limits for all
--    units
--------------------------------------------------------------------------------
procedure delete_scale_limits(
   p_location_id    in varchar2,
   p_parameter_id   in varchar2, 
   p_unit_id        in varchar2,
   p_office_id      in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_scale_limits
--
-- p_limits_catalog
--    cursor with catalog records that match input with the following fields,
--    sorted by the first 3
--
--    office_id     varchar2(16)
--    location_id   varchar2(49)
--    parameter_id  varchar2(49)
--    unit_id       varchar2(16)
--    scale_min     number
--    scale_max     number
--
--------------------------------------------------------------------------------
procedure cat_scale_limits(
   p_limits_catalog    out sys_refcursor,
   p_location_id_mask  in  varchar2 default '*',
   p_parameter_id_mask in  varchar2 default '*', 
   p_unit_id_mask      in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_scale_limits_f
--
-- returned cursor contains records that match input with the following fields,
-- sorted by the first 3
--
--    office_id     varchar2(16)
--    location_id   varchar2(49)
--    parameter_id  varchar2(49)
--    unit_id       varchar2(16)
--    scale_min     number
--    scale_max     number
--
--------------------------------------------------------------------------------
function cat_scale_limits_f(
   p_location_id_mask  in  varchar2 default '*',
   p_parameter_id_mask in  varchar2 default '*', 
   p_unit_id_mask      in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure store_unit
--------------------------------------------------------------------------------
procedure store_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2,
   p_unit_id        in varchar2,
   p_office_id      in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure retrieve_unit
--------------------------------------------------------------------------------
procedure retrieve_unit(
   p_unit_id        out varchar2,
   p_parameter_id   in  varchar2,
   p_unit_system    in  varchar2,
   p_office_id      in  varchar2 default null);

--------------------------------------------------------------------------------
-- procedure delete_unit
--
-- p_unit_system
--    unit system ('EN', 'SI') to delete display unit for - if NULL then delete
--    display unit for all unit systems
--------------------------------------------------------------------------------
procedure delete_unit(
   p_parameter_id   in varchar2,
   p_unit_system    in varchar2,
   p_office_id      in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_unit
--
-- p_unit_catalog
--    cursor with catalog records that match input with the following fields,
--    sorted by the first 3
--
--    office_id     varchar2(16)
--    parameter_id  varchar2(49)
--    unit_system   varchar2(2)
--    unit_id       varchar2(16)
--
--------------------------------------------------------------------------------
procedure cat_unit(
   p_unit_catalog      out sys_refcursor,
   p_parameter_id_mask in  varchar2 default '*',
   p_unit_system_mask  in  varchar2 default '*',
   p_office_id_mask    in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_unit_f
--
-- returned cursor contains records that match input with the following fields,
-- sorted by the first 3
--
--    office_id     varchar2(16)
--    parameter_id  varchar2(49)
--    unit_system   varchar2(2)
--    unit_id       varchar2(16)
--
--------------------------------------------------------------------------------
function cat_unit_f(
   p_parameter_id_mask in varchar2 default '*',
   p_unit_system_mask  in varchar2 default '*',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure retrieve_status_indicators
--
-- p_expression
--    an algebraic or RPN expression to map the integer values of 1..5 onto
--    a different range, the indicator value to be mapped is specified as ARG1
--
--    the following expressions can be used to map the values onto the integer
--    range of 1..3 in various ways:
--
--    'TRUNC((ARG1 + 2) / 2)'              skinny bottom : 1,2,2,3,3
--    'TRUNC((ARG1 + 1) / 2)'              skinny top    : 1,1,2,2,3
--    'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'      fat bottom    : 1,1,1,2,3
--    'TRUNC((ARG1 - 2) / 3 + 2)',         fat middle    : 1,2,2,2,3 
--    'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'  fat top       : 1,2,3,3,3
--
--------------------------------------------------------------------------------
procedure retrieve_status_indicators(
   p_indicators   out tsv_array,
   p_tsid         in  varchar2,
   p_level_id     in  varchar2,
   p_indicator_id in  varchar2,
   p_start_time   in  date,
   p_end_time     in  date,
   p_time_zone    in  varchar2 default 'UTC',
   p_expression   in  varchar2 default null,
   p_office_id    in  varchar2 default null);

--------------------------------------------------------------------------------
-- function retrieve_status_indicators_f
--
-- p_expression
--    an algebraic or RPN expression to map the integer values of 1..5 onto
--    a different range, the indicator value to be mapped is specified as ARG1
--
--    the following expressions can be used to map the values onto the integer
--    range of 1..3 in various ways:
--
--    'TRUNC((ARG1 + 2) / 2)'              skinny bottom : 1,2,2,3,3
--    'TRUNC((ARG1 + 1) / 2)'              skinny top    : 1,1,2,2,3
--    'ROUND((ARG1 / 5) ^ 3 * 2 + 1)'      fat bottom    : 1,1,1,2,3
--    'TRUNC((ARG1 - 2) / 3 + 2)',         fat middle    : 1,2,2,2,3 
--    'ROUND((ARG1 - 1) ^ .3 * 1.25 + 1)'  fat top       : 1,2,3,3,3
--
--------------------------------------------------------------------------------
function retrieve_status_indicators_f(
   p_tsid         in varchar2,
   p_level_id     in varchar2,
   p_indicator_id in varchar2,
   p_start_time   in date,
   p_end_time     in date,
   p_time_zone    in varchar2 default 'UTC',
   p_expression   in varchar2 default null,
   p_office_id    in varchar2 default null)
   return tsv_array;
   
end cwms_display;
/
show errors;