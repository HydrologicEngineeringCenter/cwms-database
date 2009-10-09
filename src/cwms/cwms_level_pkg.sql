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
   p_location_level_code  out number,
   p_location_id          in  varchar2,
   p_parameter_id         in  varchar2,
   p_parameter_type_id    in  varchar2,
   p_duration_id          in  varchar2,
   p_spec_level_id        in  varchar2,
   p_level_value          in  number,
   p_level_units          in  varchar2,
   p_fail_if_exists       in  varchar2 default 'T',
   p_interval_in_local_tz in  varchar2 default 'T',
   p_interpolate          in  varchar2 default 'T',
   p_level_comment        in  varchar2 default null,
   p_effective_date       in  date default null,
   p_interval_origin      in  date default null,
   p_calendar_interval    in  interval year to month default null,
   p_time_interval        in  interval day to second default null,
   p_seasonal_values      in  seasonal_value_array default null,
   p_office_id            in  varchar2 default null);


END cwms_level;
/

show errors;