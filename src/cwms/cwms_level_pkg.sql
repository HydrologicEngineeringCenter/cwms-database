CREATE OR REPLACE PACKAGE cwms_level
AS

--------------------------------------------------------------------------------
-- PROCEDURE create_specified_level
--------------------------------------------------------------------------------
procedure create_specified_level(
   p_level_code     out number,
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION create_specified_level
--------------------------------------------------------------------------------
function create_specified_level(
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_specified_level
--------------------------------------------------------------------------------
procedure retrieve_specified_level(
   p_level_code        out number,
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_specified_level
--------------------------------------------------------------------------------
function retrieve_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE update_specified_level
--------------------------------------------------------------------------------
procedure update_specified_level(
   p_level_id    in  varchar2,
   p_description in  varchar2,
   p_office_id   in  varchar2 default null);

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
-- PROCEDURE create_location_level
--------------------------------------------------------------------------------
procedure create_location_level(
   p_location_level_code     out number,
   p_fail_if_exists          in  varchar2 default 'T',
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  date default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_array default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION create_location_level
--------------------------------------------------------------------------------
function create_location_level(
   p_fail_if_exists          in varchar2 default 'T',
   p_spec_level_id           in varchar2,
   p_location_id             in varchar2,
   p_parameter_id            in varchar2,
   p_parameter_type_id       in varchar2,
   p_duration_id             in varchar2,
   p_level_value             in number,
   p_level_units             in varchar2,
   p_level_comment           in varchar2 default null,
   p_effective_date          in date default null,
   p_timezone_id             in varchar2 default 'UTC',
   p_attribute_value         in number default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_parameter_id  in varchar2 default null,
   p_attribute_param_type_id in varchar2 default null,
   p_attribute_duration_id   in varchar2 default null,
   p_attribute_comment       in varchar2 default null,
   p_interval_origin         in date default null,
   p_interval_months         in integer default null,
   p_interval_minutes        in integer default null,
   p_interpolate             in varchar2 default 'T',
   p_seasonal_values         in seasonal_value_array default null,
   p_office_id               in varchar2 default null)
   return  number;

--------------------------------------------------------------------------------
-- PROCEDURE create_location_level2
--------------------------------------------------------------------------------
procedure create_location_level2(
   p_location_level_code     out number,
   p_fail_if_exists          in  varchar2 default 'T',
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION create_location_level2
--------------------------------------------------------------------------------
function create_location_level2(
   p_fail_if_exists          in  varchar2 default 'T',
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2 default null,
   p_interval_origin         in  varchar2 default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE update_location_level
--------------------------------------------------------------------------------
procedure update_location_level(
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_level_comment           in  varchar2 default null,
   p_effective_date          in  date default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_attribute_comment       in  varchar2,
   p_interval_origin         in  date default null,
   p_interval_months         in  integer default null,
   p_interval_minutes        in  integer default null,
   p_interpolate             in  varchar2 default 'T',
   p_seasonal_values         in  seasonal_value_array default null,
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
   p_seasonal_values         out seasonal_value_array,
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number default null,
   p_attribut_units          in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_values
--
-- Note: The returned QUALITY_CODE values will be zero.
--------------------------------------------------------------------------------
procedure retrieve_location_level_values(
   p_level_values            out ztsv_array,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
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
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
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
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_value
--------------------------------------------------------------------------------
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_value
--------------------------------------------------------------------------------
function retrieve_location_level_value(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date default null,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs(
   p_attribute_values        out sys_refcursor,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--------------------------------------------------------------------------------
function retrieve_location_level_attrs(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- PROCEDURE retrieve_location_level_attrs2
--------------------------------------------------------------------------------
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION retrieve_location_level_attrs
--------------------------------------------------------------------------------
function retrieve_location_level_attrs2(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_units         in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return varchar2;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_level_by_attribute
--------------------------------------------------------------------------------
procedure lookup_level_by_attribute(
   p_level                   out number,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION lookup_level_by_attribute
--------------------------------------------------------------------------------
function lookup_level_by_attribute(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_attribute_value         in  number,
   p_attribute_units         in  varchar2,
   p_level_units             in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE lookup_attribute_by_level
--------------------------------------------------------------------------------
procedure lookup_attribute_by_level(
   p_attribute               out number,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null);

--------------------------------------------------------------------------------
-- FUNCTION lookup_attribute_by_level
--------------------------------------------------------------------------------
function lookup_attribute_by_level(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_attribute_parameter_id  in  varchar2,
   p_attribute_param_type_id in  varchar2,
   p_attribute_duration_id   in  varchar2,
   p_level_value             in  number,
   p_level_units             in  varchar2,
   p_attribute_units         in  varchar2,
   p_in_range_behavior       in  integer default cwms_lookup.in_range_interp,
   p_out_range_behavior      in  integer default cwms_lookup.out_range_null,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date default null,
   p_office_id               in  varchar2 default null)
   return number;

--------------------------------------------------------------------------------
-- PROCEDURE delete_location_level
--------------------------------------------------------------------------------
procedure delete_location_level(
   p_spec_level_id           in  varchar2,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_cascade                 in  varchar2 default ('F'),
   p_office_id               in  varchar2 default null);

END cwms_level;
/

show errors;