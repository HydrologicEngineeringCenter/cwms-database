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
   return varchar2 /*result_cache*/;

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
   return varchar2 /*result_cache*/;

--------------------------------------------------------------------------------
-- FUNCTION get_location_level_id
--------------------------------------------------------------------------------
function get_location_level_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2)
   return varchar2 /*result_cache*/;
   
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
   return varchar2 /*result_cache*/;
   
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
   return number;
   
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
-- PROCEDURE rename_specified_level
--------------------------------------------------------------------------------
procedure rename_specified_level(
   p_old_level_id in varchar2,
   p_new_level_id in varchar2,
   p_office_id    in varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE cat_specified_levels
--
-- The cursor returned by this routine contains three fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--    3 : description        varchar2(256)
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure cat_specified_levels(
   p_level_cursor   out sys_refcursor,
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION cat_specified_levels
--
-- The cursor returned by this routine contains three fields:
--    1 : office_id          varchar(16)
--    2 : specified_level_id varchar2(256)
--    3 : description        varchar2(256)
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
function cat_specified_levels(
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level
--
-- Creates or updates a Location Level in the database
--
-- Only one of p_interval_months and p_interval_minutes can be specified for
-- seasonal levels
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
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
--
-- Creates or updates a Location Level in the database
--------------------------------------------------------------------------------
procedure store_location_level(
   p_location_level in  location_level_t);

--------------------------------------------------------------------------------
-- PROCEDURE store_location_level2
--
-- Creates or updates a Location Level in the database using only text and 
-- numeric parameters
--
-- Only one of p_interval_months and p_interval_minutes can be specified for
-- seasonal levels
--
-- p_effective_date should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_interval_origin should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_seasonal_values should be specified as text records separated by the RS
-- character (chr(30)) with each record containing offset_months, offset_minutes
-- and offset_value, each separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure store_location_level2(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null);


procedure store_location_level3(
   p_location_level_id       in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date     default null,
   p_interval_months         in  integer  default null,
   p_interval_minutes        in  integer  default null,
   p_interpolate             in  varchar2 default 'T',
   p_tsid                    in  varchar2 default null,
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level
--
-- Retrieves the Location Level in effect at a specified time
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
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level2
--
-- Retrieves the Location Level in effect at a specified time using only text
-- and numeric parameters
--
-- p_date should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- If p_match_date is false ('F'), then the location level that has the latest
-- effective date on or before p_date is returned.
--
-- If p_match_date is true ('T'), then a location level is returned only if
-- it has an effective date matching p_date.
--
-- p_effective_date is returned as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_interval_origin is returned as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_seasonal_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing offset_months, offset_minutes
-- and offset_value, each separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure retrieve_location_level2(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out varchar2,
   p_interval_origin         out varchar2,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_seasonal_values         out varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null);

procedure retrieve_location_level3(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_seasonal_values         out seasonal_value_tab_t,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level
--
-- Returns the Location Level in effect at a specified time
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
-- Retreives a time series of Location Level values for a specified time window
--
-- The returned QUALITY_CODE values of the time series will be zero.
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
-- Returns a time series of Location Level values for a specified time window
--
-- The returned QUALITY_CODE values of the time series will be zero.
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
--
-- Retreives a time series of Location Level values for a specified time window
-- using only text and numeric parameters
--
-- p_start_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_end_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_level_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing date-time and value
-- separated by the GS character (chr(29))
--------------------------------------------------------------------------------
procedure retrieve_loc_lvl_values2(
   p_level_values            out varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2,
   p_end_time                in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_loc_lvl_values2
--
-- Returns a time series of Location Level values for a specified time window
-- using only text and numeric parameters
--
-- p_start_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_end_time should be specified as ‘yyyy/mm/dd hh:mm:ss’
--
-- p_level_values is returned as as text records separated by the RS
-- character (chr(30)) with each record containing date-time and value
-- separated by the GS character (chr(29))
--------------------------------------------------------------------------------
function retrieve_loc_lvl_values2(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2,
   p_end_time                in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return varchar2;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Retreives a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_values
--
-- Returns a time series of Location Level values for a specified time window
-- for a specified Time Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
--
-- The returned QUALITY_CODE values of the time series will be zero.
--------------------------------------------------------------------------------
function retrieve_location_level_values(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return ztsv_array;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--
-- Retreives a Location Level value for a specified time
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
--
-- Returns a Location Level value for a specified time
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
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--
-- Retreives a Location Level value for a specified time for a specified Time
-- Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
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
--
-- Retrurns a Location Level value for a specified time for a specified Time
-- Series Identifier and Specified Level Identifier
--
-- The Location Level Identifier is computed from p_ts_id and p_spec_level_id
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
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time
--
-- The attribute values are returned in the units specified
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
--
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time
--
-- The attribute values are returned in the units specified
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
--
-- Retrieves a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--
-- p_date should be specifed as 'yyyy/mm/dd hh:mm:ss'
--
-- p_attribute_values is returned as text records separated by the RS character
-- (chr(30)) with each record containing an attribute value in the units 
-- specified
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs2
--
-- Returns a table of attribute values for a Location Level in effect at a
-- specified time using only text and numeric parameters
--
-- p_date should be specifed as 'yyyy/mm/dd hh:mm:ss'
--
-- The attribute values are returned as text records separated by the RS
-- character (chr(30)) with each record containing an attribute value in the 
-- units specified
--------------------------------------------------------------------------------
function retrieve_location_level_attrs2(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return varchar2;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_level_by_attribute
--
-- Retrieves the level value of a Location Level that corresponds to a specified
-- attribute value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- attribute value is within the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION lookup_level_by_attribute
--
-- Returns the level value of a Location Level that corresponds to a specified
-- attribute value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- attribute value is within the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- attribute value is outside the range of attributes for the Location Level and
-- is specified as one of the following constants from the CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of attribute and level values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of attribute and level values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of attribute values, Logarithmic of level values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of attribute values, Linear of level values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_attribute_by_level
--
-- Retrieves the attribute value of a Location Level that corresponds to a 
-- specified level value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- level value is within the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION lookup_attribute_by_level
--
-- Returns the attribute value of a Location Level that corresponds to a 
-- specified level value and date
--
-- p_in_range_behavior specifies how the lookup is performed when the specified
-- level value is within the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if between values                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception if between values                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear interpolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic interpolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear interpolation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic interpolation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_LOWER       Return the value that is lower in magnitude                                                
-- CWMS_LOOKUP.METHOD_HIGHER      Return the value that is higher in magnitude                                               
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude                                              
--
-- p_out_range_behavior specifies how the lookup is performed when the specified
-- level value is outside the range of levels associated attributes for the
-- Location Level and is specified as one of the following constants from the
-- CWMS_LOOKUP package:
--
-- CWMS_LOOKUP.METHOD_NULL        Return null if outside range                                             
-- CWMS_LOOKUP.METHOD_ERROR       Raise an exception outside range                                      
-- CWMS_LOOKUP.METHOD_LINEAR      Linear extrapolation of level and attribute values                  
-- CWMS_LOOKUP.METHOD_LOGARITHMIC Logarithmic extrapolation of level and attribute values             
-- CWMS_LOOKUP.METHOD_LIN_LOG     Linear extrapoloation of level values, Logarithmic of attribute values 
-- CWMS_LOOKUP.METHOD_LOG_LIN     Logarithmic extrapoloation of level values, Linear of attribute values 
-- CWMS_LOOKUP.METHOD_CLOSEST     Return the value that is closest in magnitude
--                                              
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer  default cwms_lookup.method_linear,
   p_out_range_behavior      in  integer  default cwms_lookup.method_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE rename_location_level
--
-- Renames a location level
--------------------------------------------------------------------------------
procedure rename_location_level(
   p_old_location_level_id in  varchar2,
   p_new_location_level_id in  varchar2,
   p_office_id             in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE delete_location_level
--
-- Deletes the specified Location Level from the database
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
-- PROCEDURE delete_location_level_ex
--
-- Deletes the specified Location Level from the database, and optionally any 
-- associated location level indicators and conditions
--------------------------------------------------------------------------------
procedure delete_location_level_ex(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_delete_indicators       in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE cat_location_levels
--
-- in this procedure SQL- (%, _) or glob-style (*, ?) wildcards can be used
-- in masks, and all masks are case insensitive
--
-- muilt-part masks need not specify all the parts if a partial mask will match
-- all desired results 
--
-- p_cursor
--   the cursor that is opened by this procedure. it must be manually closed
--   after use.
--
-- p_location_level_id_mask
--   a wildcard mask of the five-part location level identifier.  defaults
--   to matching every location level identifier
--
-- p_attribute_id_mask
--   a wildcard mask of the three-part attribute identifier.  null attribute
--   identifiers are matched by '*' (or '%'), to match ONLY null attributes, 
--   specify null for this parameter.  defaults to matching all attribute
--   identifiers
--
-- p_office_id_mask
--   a wildcard mask of the office identifier that owns the location levels.
--   specify '*' (or '%') for this parameter to match every office identifier.
--   defaults to matching only the calling user's office identifier
--
-- p_timezone_id
--   the time zone in which location level dates are to be represented in the
--   cursor opened by this procedure.  defaults to 'UTC'
--
-- p_unit_system
--   the unit system in which the attribute values are to be represented in the
--   cursor opened by this procedure.  The actual units will be determined by
--   the entry in the AT_DISPLAY_UNITS table for the office that owns the 
--   location level and the attribute parameter. defaults to 'SI'
--
-- The cursor opened by this routine contains six fields:
--    1 : office_id           varchar2(16)
--    2 : location_level_id   varchar2(390)
--    3 : attribute_id        varchar2(83)
--    4 : attribute_value     binary_double
--    5 : attribute_unit      varchar2(16)
--    6 : location_level_date date
--
-- Calling this routine with no parameters returns all specified
-- levels for the calling user's office.
--------------------------------------------------------------------------------
procedure cat_location_levels(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2 default '*',
   p_attribute_id_mask      in  varchar2 default '*',
   p_office_id_mask         in  varchar2 default null,
   p_timezone_id            in  varchar2 default 'UTC',
   p_unit_system            in  varchar2 default 'SI');
   
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
   return number;
   
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
--
-- Creates or updates a Location Level Indicator Condition in the database
--
-- p_rate_interval is specified as 'ddd hh:mm:ss'
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
   p_rate_interval               in varchar2 default null,
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
--
-- Creates or updates a Location Level Indicator in the database
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
--
-- Creates or updates a Location Level Indicator in the database using only text
-- and numeric parameters
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
--------------------------------------------------------------------------------
function cat_loc_lvl_indicator_codes(
   p_loc_lvl_indicator_id_mask in  varchar2 default null, -- '%.%.%.%.%.%' if null
   p_attribute_id_mask         in  varchar2 default null,
   p_office_id_mask            in  varchar2 default null) -- user's office if null
   return sys_refcursor;

--------------------------------------------------------------------------------
-- PROCEDURE cat_loc_lvl_indicator
--
-- Retrieves a cursor of Location Level Indicators and associated Conditions
-- that match the input masks
--
-- p_location_level_id_mask - Location Level Identifier that can contain SQL
-- wildcards (%, _) or filename wildcards (*, ?), cannot be NULL
--
-- p_attribute_id_mask - Attribute Identifier that can contain wildcards, cannot
-- be NULL
--
-- p_office_id_mask - Office Identifier that can contain wildcards, if NULL, the
-- user's office id is used
--
-- p_unit_system is 'EN' or 'SI'
--
-- p_cursor contains 18 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(256)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       interval day(3) to second(0)
--  15 : maximum_age            interval day(3) to second(0)
--  16 : ref_specified_level_id varchar2(256)
--  17 : ref_attribute_value    number
--  18 : conditions             sys_refcursor
--
-- The cursor returned in field 18 contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day(3) to second(0)
--  17 : description                 varchar2(256)  
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
-- Retrieves a cursor of Location Level Indicators and associated Conditions
-- that match the input masks and contains only text and numeric fields
--
-- p_location_level_id_mask - Location Level Identifier that can contain SQL
-- wildcards (%, _) or filename wildcards (*, ?), cannot be NULL
--
-- p_attribute_id_mask - Attribute Identifier that can contain wildcards, cannot
-- be NULL
--
-- p_office_id_mask - Office Identifier that can contain wildcards, if NULL, the
-- user's office id is used
--
-- p_unit_system is 'EN' or 'SI'
--
-- p_cursor contains 18 fields:
--   1 : office_id              varchar2(16)
--   2 : location_id            varchar2(49)
--   3 : parameter_id           varchar2(49)
--   4 : parameter_type_id      varchar2(16)
--   5 : duration_id            varchar2(16)
--   6 : specified_level_id     varchar2(256)
--   7 : level_indicator_id     varchar2(32)
--   8 : level_units_id         varchar2(16)
--   9 : attr_parameter_id      varchar2(49)
--  10 : attr_parameter_type_id varchar2(16)
--  11 : attr_duration_id       varchar2(16)
--  12 : attr_units_id          varchar2(16)
--  13 : attr_value             number
--  14 : minimum_duration       varchar2(12)
--  15 : maximum_age            varchar2(12)
--  16 : ref_specified_level_id varchar2(256)
--  17 : ref_attribute_value    number
--  18 : conditions             varchar2(4096)
--
-- Fields 14 and 15 are in the format 'ddd hh:mm:ss'
--
-- The character string returned in field 18 contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2(12)
--  17 : description                 varchar2(256)  
--
-- Field 16 is in the format 'ddd hh:mm:ss'
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
-- Retrieves a Location Level Indicator and its associated Conditions
--
-- The cursor returned in p_conditions contains 17 fields:
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               interval day(3) to second(0)
--  17 : description                 varchar2(256)  
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
-- Retrieves a Location Level Indicator and its associated Conditions and uses
-- only text and numeric fields
--
-- p_minimum_duration is in the format 'ddd hh:mm:ss'
--
-- p_maximum_age is in the format 'ddd hh:mm:ss'
--
-- The character string returned in p_conditions contains text records separated
-- by the RS character (chr(30)), each record having 17 fields separated by
-- the GS character (chr(29)):
--   1 : indicator_value             integer  (1..5)
--   2 : expression                  varchar2(64)
--   3 : comparison_operator_1       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   4 : comparison_value_1          number
--   5 : comparison_unit_id          varchar2(16)
--   6 : connector                   varchar2(3) (AND,OR) 
--   7 : comparison_operator_2       varchar2(2) (LT,LE,EQ,NE,GE,GT)
--   8 : comparison_value_2          number  
--   9 : rate_expression             varchar2(64)
--  10 : rate_comparison_operator_1  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  11 : rate_comparison_value_1     number
--  12 : rate_comparison_unit_id     varchar2(16)
--  13 : rate_connector              varchar2(3) (AND,OR) 
--  14 : rate_comparison_operator_2  varchar2(2) (LT,LE,EQ,NE,GE,GT)
--  15 : rate_comparison_value_2     number  
--  16 : rate_interval               varchar2(12)
--  17 : description                 varchar2(256)  
--
-- Field 16 is in the format 'ddd hh:mm:ss'
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
--
-- Returns a Location Level Indicator and its associated Conditions in a
-- LOC_LVL_INDICATOR_T object
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
--
-- Deletes a Location Level Indicator and its associated Conditions
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
-- Retreieves the values for all Location Level Indicator Conditions that are
-- set at p_eval_time and that match the input parameters.  Each indicator may
-- have multiple condions set.
--
-- p_tsid - time series identifier, p_cursor will only include Conditions for 
-- Location Levels that have the same Location, Parameter, and Parameter Type
-- 
-- p_eval_time - evaluation time, current time if NULL
--
-- p_time_zone - time zone of p_eval_time, 'UTC' if NULL
--
-- p_specified_level_mask - Specified Level Indicator with optional SQL
-- wildcards (%, _) or filename wildcards (*, ?), '%' if NULL
--
-- p_indicator_id_mask - Location Level Identifier with optional wildcards, '%'
-- if NULL
--
-- p_unit_system - unit system for which to retrieve attribute values, 'EN' or 
-- 'SI', 'SI' if NULL
--
-- p_office_id - office identifier for p_tsid, user's office identifier if NULL
-- 
-- p_cursor contains the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number           
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values number_tab_t
--------------------------------------------------------------------------------
procedure get_level_indicator_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_eval_time            in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_specified_level_mask in  varchar2 default null,
   p_indicator_id_mask    in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_office_id            in  varchar2 default null); 

--------------------------------------------------------------------------------
-- PROCEDURE get_level_indicator_max_values
--
-- Retrieves a time series of the maximum Condition value that is set for each 
-- Location Level Indicator that matches the input parameters.  Each time series 
-- has the same times as the time series defined by p_tsid, p_start_time and
-- p_end_time.  Each date_time in the time series is in the specified time
-- zone. The quality_code of each time series value is set to zero.
--
-- p_tsid - time series identifier, p_cursor will only include Conditions for 
-- Location Levels that have the same Location, Parameter, and Parameter Type
-- 
-- p_start_time - start of the time window for p_tsid, in p_time_zone
-- 
-- p_end_time - end of the time window for p_tsid, in p_time_zone
--
-- p_time_zone - time zone of p_start_time, p_end_time and the date_times of the
-- retrieved time series, 'UTC' if NULL
--
-- p_specified_level_mask - Specified Level Indicator with optional SQL
-- wildcards (%, _) or filename wildcards (*, ?), '%' if NULL
--
-- p_indicator_id_mask - Location Level Identifier with optional wildcards, '%'
-- if NULL
--
-- p_unit_system - unit system for which to retrieve attribute values, 'EN' or 
-- 'SI', 'SI' if NULL
--
-- p_office_id - office identifier for p_tsid, user's office identifier if NULL
-- 
-- p_cursor has the following fields:
-- 1 indicator_id     varchar2(423)
-- 2 attribute_id     varchar2(83)
-- 3 attribute_value  number
-- 4 attribute_units  varchar2(16)
-- 5 indicator_values ztsv_array  
--------------------------------------------------------------------------------
procedure get_level_indicator_max_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_start_time           in  date,
   p_end_time             in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_specified_level_mask in  varchar2 default null,
   p_indicator_id_mask    in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_office_id            in  varchar2 default null); 

END cwms_level;
/

show errors;