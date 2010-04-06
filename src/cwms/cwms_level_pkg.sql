CREATE OR REPLACE PACKAGE cwms_level
AS

--------------------------------------------------------------------------------
-- This package makes use of the following identifiers:
-- 
--    location_level_id
--    loc_lvl_indicator_id
--    attribute_id
--    
-- These types follow the time series identifier convention of concatenating
-- multiple identifiers together, separated by the '.' characater.
-- 
-- The location_level_id is contains (in order):
--    location_id
--    parameter_id
--    parameter_type_id
--    duration_id
--    specified_level_id
-- 
-- The loc_lvl_indicator_id is contains (in order):
--    location_id
--    parameter_id
--    parameter_type_id
--    duration_id
--    specified_level_id
--    level_indicator_id
--    
-- The attribute_id is contains (in order):
--    attribute_parameter_id
--    attribute_param_type_id
--    attribute_duration_id
--    
-- This package includes functions to create each of these identifiers from 
-- their constituent parts and procedures to decompose each of them into their
-- constituent parts.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- PROCEDURE parse_attribute_id
--------------------------------------------------------------------------------
procedure parse_attribute_id(
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_attribute_id       in  varchar2);

--------------------------------------------------------------------------------
-- FUNCTION get_attribute_id
--------------------------------------------------------------------------------
function get_attribute_id(
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2)
   return varchar2 result_cache;

--------------------------------------------------------------------------------
-- PROCEDURE parse_location_level_id
--------------------------------------------------------------------------------
procedure parse_location_level_id(
   p_location_id        out varchar2,
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_specified_level_id out varchar2,
   p_location_level_id  in  varchar2);

--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_level_code in number)
   return varchar2 result_cache;

--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2)
   return varchar2 result_cache;
   
--------------------------------------------------------------------------------
-- PROCEDURE parse_loc_lvl_indicator_id
--------------------------------------------------------------------------------
procedure parse_loc_lvl_indicator_id(
   p_location_id          out varchar2,
   p_parameter_id         out varchar2,
   p_parameter_type_id    out varchar2,
   p_duration_id          out varchar2,
   p_specified_level_id   out varchar2,
   p_level_indicator_id   out varchar2,
   p_loc_lvl_indicator_id in  varchar2);
   
--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indicator_id
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2,
   p_level_indicator_id in varchar2)
   return varchar2 result_cache;
   
--------------------------------------------------------------------------------
-- PROCEDURE create_specified_level_out
--------------------------------------------------------------------------------
procedure create_specified_level_out(
   p_level_code     out number,
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- PROCEDURE store_specified_level
--------------------------------------------------------------------------------
procedure store_specified_level(
   p_level_id       in varchar2,
   p_description    in varchar2,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null);
   
--------------------------------------------------------------------------------
-- PROCEDURE store_specified_level
--------------------------------------------------------------------------------
procedure store_specified_level(
   p_obj            in specified_level_t,
   p_fail_if_exists in varchar2 default 'T');

--------------------------------------------------------------------------------
-- FUNCTION get_specified_level_code
--------------------------------------------------------------------------------
function get_specified_level_code(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
   return number result_cache;
   
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_specified_level
--------------------------------------------------------------------------------
procedure retrieve_specified_level(
   p_description    out varchar2,
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- FUNCTION retrieve_specified_level
--------------------------------------------------------------------------------
function retrieve_specified_level(
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null)
   return specified_level_t;

--------------------------------------------------------------------------------
-- PROCEDURE delete_specified_level
--------------------------------------------------------------------------------
procedure delete_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE catalog_specified_levels
--
-- The cursor returned by this routine contains two fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure catalog_specified_levels(
   p_level_cursor   out sys_refcursor,
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION catalog_specified_levels
--
-- The cursor returned by this routine contains two fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
function catalog_specified_levels(
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level in  location_level_t);

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level2
--------------------------------------------------------------------------------
procedure store_location_level2(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null, -- recordset of (offset_months, offset_minutes, offset_values) records
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
procedure retrieve_location_level(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribut_units          in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level2
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
procedure retrieve_location_level2(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out varchar2, -- 'yyyy/mm/dd hh:mm:ss'
   p_interval_origin         out varchar2, -- 'yyyy/mm/dd hh:mm:ss'
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out varchar2, -- recordset of (offset_months, offset_minutes, offset_values) records
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  varchar2 default null, -- 'yyyy/mm/dd hh:mm:ss'
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribut_units          in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--------------------------------------------------------------------------------
function retrieve_location_level(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null)
   return location_level_t;
   
--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_values2
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_values2(
   p_level_values            out varchar2, -- recordset of (date, value) records
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2, -- yy/mm/dd hh:mm:ss
   p_end_time                in  varchar2, -- yy/mm/dd hh:mm:ss
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_values2
--------------------------------------------------------------------------------
function retrieve_loc_lvl_values2(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2, -- yy/mm/dd hh:mm:ss
   p_end_time                in  varchar2, -- yy/mm/dd hh:mm:ss
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return varchar2 result_cache; -- recordset of (date, value) records

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number result_cache;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number result_cache;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs(
   p_attribute_values        out number_tab_t,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--------------------------------------------------------------------------------
function retrieve_location_level_attrs(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number_tab_t;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs2
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2, -- table of values separated by RS characater (chr(30))
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null, -- yyyy/mm/dd hh:mm:ss
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--------------------------------------------------------------------------------
function retrieve_location_level_attrs2(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null, -- yyyy/mm/dd hh:mm:ss
   p_office_id               in  varchar2 default null)
   return varchar2 result_cache; -- table of values separated by RS characater (chr(30))

--------------------------------------------------------------------------------
-- PROCEDURE lookup_level_by_attribute
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION lookup_level_by_attribute
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number result_cache;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_attribute_by_level
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION lookup_attribute_by_level
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer  default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number result_cache;

--------------------------------------------------------------------------------
-- PROCEDURE delete_location_level
--------------------------------------------------------------------------------
procedure delete_location_level(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION get_loc_lvl_indciator_code
--------------------------------------------------------------------------------
function get_loc_lvl_indicator_code(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return number result_cache;
   
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_cond
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_cond(
   p_level_indicator_code        in number,
   p_level_indicator_value       in number,
   p_expression                  in varchar2,
   p_comparison_operator_1       in varchar2,
   p_comparison_value_1          in binary_double,
   p_comparison_unit_code        in number                 default null,
   p_connector                   in varchar2               default null, 
   p_comparison_operator_2       in varchar2               default null,
   p_comparison_value_2          in binary_double          default null,
   p_rate_expression             in varchar2               default null,
   p_rate_comparison_operator_1  in varchar2               default null,
   p_rate_comparison_value_1     in binary_double          default null,
   p_rate_comparison_unit_code   in number                 default null,
   p_rate_connector              in varchar2               default null, 
   p_rate_comparison_operator_2  in varchar2               default null,
   p_rate_comparison_value_2     in binary_double          default null,
   p_rate_interval               in interval day to second default null,
   p_description                 in varchar2               default null,
   p_fail_if_exists              in varchar2               default 'F',
   p_ignore_nulls_on_update      in varchar2               default 'T');

--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_cond
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_cond(
   p_loc_lvl_indicator_id        in varchar2,
   p_level_indicator_value       in number,
   p_expression                  in varchar2,
   p_comparison_operator_1       in varchar2,
   p_comparison_value_1          in number,
   p_comparison_unit_id          in varchar2 default null,
   p_connector                   in varchar2 default null, 
   p_comparison_operator_2       in varchar2 default null,
   p_comparison_value_2          in number   default null,
   p_rate_expression             in varchar2 default null,
   p_rate_comparison_operator_1  in varchar2 default null,
   p_rate_comparison_value_1     in number   default null,
   p_rate_comparison_unit_id     in varchar2 default null,
   p_rate_connector              in varchar2 default null, 
   p_rate_comparison_operator_2  in varchar2 default null,
   p_rate_comparison_value_2     in number   default null,
   p_rate_interval               in varchar2 default null, -- 'ddd hh:mm:ss'
   p_description                 in varchar2 default null,
   p_attr_value                  in number   default null,
   p_attr_units_id               in varchar2 default null,
   p_attr_id                     in varchar2 default null,
   p_ref_specified_level_id      in varchar2 default null,
   p_ref_attr_value              in number   default null,
   p_fail_if_exists              in varchar2 default 'F',
   p_ignore_nulls_on_update      in varchar2 default 'T',
   p_office_id                   in varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator_out
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator_out(
   p_level_indicator_code     out number,
   p_location_code            in  number,
   p_parameter_code           in  number,
   p_parameter_type_code      in  number,
   p_duration_code            in  number,
   p_specified_level_code     in  number,
   p_level_indicator_id       in  varchar2,
   p_attr_value               in  number default null,
   p_attr_parameter_code      in  number default null,
   p_attr_parameter_type_code in  number default null,
   p_attr_duration_code       in  number default null,
   p_ref_specified_level_code in  number default null,
   p_ref_attr_value           in  number default null,
   p_minimum_duration         in  interval day to second default null,
   p_maximum_age              in  interval day to second default null,
   p_fail_if_exists           in  varchar2 default 'F',
   p_ignore_nulls_on_update   in  varchar2 default 'T');
   
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  interval day to second default null,
   p_maximum_age            in  interval day to second default null,
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- PROCEDURE store_loc_lvl_indicator2
--------------------------------------------------------------------------------
procedure store_loc_lvl_indicator2(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  varchar2 default null, -- 'ddd hh:mi:ss'
   p_maximum_age            in  varchar2 default null, -- 'ddd hh:mi:ss'
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator_codes
--
-- The returned cursor contains only the matching location_level_code
--
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator_codes(
   p_cursor                     out sys_refcursor,
   p_loc_lvl_indicator_id_mask  in  varchar2 default null,  -- '%.%.%.%.%.%' if null
   p_attribute_id_mask          in  varchar2 default null,
   p_office_id_mask             in  varchar2 default null); -- user's office if null

--------------------------------------------------------------------------------
-- FUNCTION cat_loc_lvl_indicator_codes
--
-- The returned cursor contains only the matching location_level_code
--
--------------------------------------------------------------------------------
function cat_loc_lvl_indicator_codes(
   p_loc_lvl_indicator_id_mask in  varchar2 default null, -- '%.%.%.%.%.%' if null
   p_attribute_id_mask         in  varchar2 default null,
   p_office_id_mask            in  varchar2 default null) -- user's office if null
   return sys_refcursor;

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator
--
-- The cursor returned by this routine contains 19fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(265)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       interval day to second
--  15 : maximum_age            interval day to second
--  16 : rate_of_change         varchar2(1) ('T' or 'F')
--  17 : ref_specified_level_id varchar2(256)
--  18 : ref_attribute_value    number
--  19 : conditions             sys_refcursor
--
-- The cursor returned in field 19 contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2
--   3 : comparison_operator_1       varchar2 (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number,
--   5 : comparison_unit_id          varchar2
--   6 : connector                   varchar2 (AND,OR) 
--   7 : comparison_operator_2       varchar2 (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2
--  10 : rate_comparison_operator_1  varchar2 (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number,
--  12 : rate_comparison_unit_id     varchar2
--  13 : rate_connector              varchar2 (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2 (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day to second
--  17 : description                 varchar2  
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI');

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator2
--
-- The cursor returned by this routine contains 19 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(265)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       varchar2 (ddd hh:mm:ss)
--  15 : maximum_age            varchar2 (ddd hh:mm:ss)
--  16 : rate_of_change         varchar2(1) ('T' or 'F')
--  17 : ref_specified_level_id varchar2(256)
--  18 : ref_attribute_value    number
--  19 : conditions             varchar2(4096)
--
-- The character string returned in field 19 contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2
--   3 : comparison_operator_1       varchar2 (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number,
--   5 : comparison_unit_id          varchar2
--   6 : connector                   varchar2 (AND,OR) 
--   7 : comparison_operator_2       varchar2 (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2
--  10 : rate_comparison_operator_1  varchar2 (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number,
--  12 : rate_comparison_unit_id     varchar2
--  13 : rate_connector              varchar2 (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2 (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2 (ddd hh:mm:ss)
--  17 : description                 varchar2  
--------------------------------------------------------------------------------
procedure cat_loc_lvl_indicator2(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI');

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_indicator
--
-- The cursor returned in p_conditions contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2
--   3 : comparison_operator_1       varchar2 (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number,
--   5 : comparison_unit_id          varchar2
--   6 : connector                   varchar2 (AND,OR) 
--   7 : comparison_operator_2       varchar2 (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2
--  10 : rate_comparison_operator_1  varchar2 (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number,
--  12 : rate_comparison_unit_id     varchar2
--  13 : rate_connector              varchar2 (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2 (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day to second
--  17 : description                 varchar2  
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_indicator(
   p_minimum_duration       out interval day to second,
   p_maximum_age            out interval day to second,
   p_conditions             out sys_refcursor,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_loc_lvl_indicator2
--
-- The character string returned in p_conditions contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2
--   3 : comparison_operator_1       varchar2 (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number,
--   5 : comparison_unit_id          varchar2
--   6 : connector                   varchar2 (AND,OR) 
--   7 : comparison_operator_2       varchar2 (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2
--  10 : rate_comparison_operator_1  varchar2 (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number,
--  12 : rate_comparison_unit_id     varchar2
--  13 : rate_connector              varchar2 (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2 (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2 (ddd hh:mm:ss)
--  17 : description                 varchar2  
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_indicator2(
   p_minimum_duration       out varchar2, -- 'ddd hh:mi:ss'
   p_maximum_age            out varchar2, -- 'ddd hh:mi:ss'
   p_conditions             out varchar2,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_indicator
--------------------------------------------------------------------------------
function retrieve_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return loc_lvl_indicator_t;

--------------------------------------------------------------------------------
-- PROCEDURE delete_loc_lvl_indicator
--------------------------------------------------------------------------------
procedure delete_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_values
--
-- This procedure returns the values for all indicator conditions that are set
-- at p_eval_time and that match the input parameters.  Each indicator may have
-- multiple condions set.
-- 
-- The returned cursor has the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number           
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values number_tab_t (table of values for conditions that are set)
--
--------------------------------------------------------------------------------
procedure get_level_indicator_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_eval_time            in  date     default null,   -- sysdate if null
   p_time_zone            in  varchar2 default null,   -- 'UTC' if null
   p_specified_level_mask in  varchar2 default null,   -- '%' if null
   p_indicator_id_mask    in  varchar2 default null,   -- '%' if null
   p_unit_system          in  varchar2 default null,   -- 'SI' if null
   p_office_id            in  varchar2 default null);  -- user's office if null 

--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_max_values
--
-- This procedure returns a time series of indicator condition values for all
-- indicators that match the input parameters.  The returned time series have
-- the same times as the time series defined by p_tsid, p_start_time and
-- p_end_time.  Each date_time in the time series is in the specified time
-- zone. Each value the the time series is the maximum of values for conditions
-- that are set for that indicator at the time specified by the time series 
-- date_time field.  The quality_code of each time series value is set to zero.
-- 
-- The returned cursor has the following fields:
-- 1 indicator_id
-- 2 attribute_id
-- 3 attribute_value
-- 4 attribute_units
-- 5 indicator_values ztsv_array  
--
--------------------------------------------------------------------------------
procedure get_level_indicator_max_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_start_time           in  date,
   p_end_time             in  date     default null,   -- sysdate if null
   p_time_zone            in  varchar2 default null,   -- 'UTC' if null
   p_specified_level_mask in  varchar2 default null,   -- '%' if null
   p_indicator_id_mask    in  varchar2 default null,   -- '%' if null
   p_unit_system          in  varchar2 default null,   -- 'SI' if null
   p_office_id            in  varchar2 default null);  -- user's office if null 

END cwms_level;
/

show errors;