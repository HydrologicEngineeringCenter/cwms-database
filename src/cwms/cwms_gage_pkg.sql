create or replace package cwms_gage as

--------------------------------------------------------------------------------
-- package constants
--------------------------------------------------------------------------------
goes_category_id       constant varchar2(12) := 'GOES ALIASES';
goes_category_desc     constant varchar2(28) := 'GOES location aliaes by gage';
goes_group_desc_prefix constant varchar2(43) := 'GOES location aliases for gage id ';

--------------------------------------------------------------------------------
-- function get_gage_code
--------------------------------------------------------------------------------
function get_gage_code(
   p_office_id   in varchar2,
   p_location_id in varchar2,
   p_gage_id     in varchar2)
   return number;

--------------------------------------------------------------------------------
-- procedure store_gage
--------------------------------------------------------------------------------
procedure store_gage(
   p_location_id     in varchar2,
   p_gage_id         in varchar2,
   p_fail_if_exists  in varchar2,
   p_ignore_nulls    in varchar2,
   p_gage_type       in varchar2 default null,
   p_assoc_loc_id    in varchar2 default null,
   p_discontinued    in varchar2 default 'F',
   p_out_of_service  in varchar2 default 'F',
   p_manufacturer    in varchar2 default null,
   p_model_number    in varchar2 default null,
   p_serial_number   in varchar2 default null,
   p_phone_number    in varchar2 default null,
   p_internet_addr   in varchar2 default null,
   p_other_access_id in varchar2 default null,
   p_office_id       in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure retrieve_gage
--------------------------------------------------------------------------------
procedure retrieve_gage(
   p_gage_type       out varchar2,
   p_assoc_loc_id    out varchar2,
   p_discontinued    out varchar2,
   p_out_of_service  out varchar2,
   p_manufacturer    out varchar2,
   p_model_number    out varchar2,
   p_serial_number   out varchar2,
   p_phone_number    out varchar2,
   p_internet_addr   out varchar2,
   p_other_access_id out varchar2,
   p_location_id     in  varchar2,
   p_gage_id         in  varchar2,
   p_office_id       in  varchar2 default null);

--------------------------------------------------------------------------------
-- procedure delete_gage
--------------------------------------------------------------------------------
procedure delete_gage(
   p_location_id   in varchar2,
   p_gage_id       in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure rename_gage
--------------------------------------------------------------------------------
procedure rename_gage(
   p_location_id   in varchar2,
   p_old_gage_id   in varchar2,
   p_new_gage_id   in varchar2,
   p_office_id     in varchar2 default null);
   
--------------------------------------------------------------------------------
-- procedure cat_gages
--
-- the output cursor has the following fields, sorted by the first 3
--
--    office_id               varchar2(16)
--    location_id             varchar2(49)
--    gage_id                 varchar2(32)
--    gage_type               varchar2(32)
--    discontinued            varchar2(1)
--    out_of_service          varchar2(1)
--    phone_number            varchar2(32)
--    internet_address        varchar2(32)
--    other_access_id         varchar2(32)
--    associated_location_id  varchar2(49)
--    comments                varchar2(256)
--
--------------------------------------------------------------------------------
procedure cat_gages(
   p_gage_catalog           out sys_refcursor,
   p_location_id_mask       in  varchar2 default '*',
   p_gage_id_mask           in  varchar2 default '*',
   p_gage_type_mask         in  varchar2 default '*',
   p_discontinued_mask      in  varchar2 default '*',
   p_out_of_service_mask    in  varchar2 default '*',
   p_manufacturer_mask      in  varchar2 default '*',
   p_model_number_mask      in  varchar2 default '*',
   p_serial_number_mask     in  varchar2 default '*',
   p_phone_number_mask      in  varchar2 default '*',
   p_internet_addr_mask     in  varchar2 default '*',
   p_other_access_id_mask   in  varchar2 default '*',
   p_assoc_location_id_mask in  varchar2 default '*',
   p_comments_mask          in  varchar2 default '*',
   p_office_id_mask         in  varchar2 default null);
   
--------------------------------------------------------------------------------
-- function cat_gages_f
--
-- the returned cursor has the following fields, sorted by the first 3
--
--    office_id               varchar2(16)
--    location_id             varchar2(49)
--    gage_id                 varchar2(32)
--    gage_type               varchar2(32)
--    discontinued            varchar2(1)
--    out_of_service          varchar2(1)
--    phone_number            varchar2(32)
--    internet_address        varchar2(32)
--    other_access_id         varchar2(32)
--    associated_location_id  varchar2(49)
--    comments                varchar2(256)
--
--------------------------------------------------------------------------------
function cat_gages_f(
   p_location_id_mask       in varchar2 default '*',
   p_gage_id_mask           in varchar2 default '*',
   p_gage_type_mask         in varchar2 default '*',
   p_discontinued_mask      in varchar2 default '*',
   p_out_of_service_mask    in varchar2 default '*',
   p_manufacturer_mask      in varchar2 default '*',
   p_model_number_mask      in varchar2 default '*',
   p_serial_number_mask     in varchar2 default '*',
   p_phone_number_mask      in varchar2 default '*',
   p_internet_addr_mask     in varchar2 default '*',
   p_other_access_id_mask   in varchar2 default '*',
   p_assoc_location_id_mask in varchar2 default '*',
   p_comments_mask          in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure store_gage_sensor
--------------------------------------------------------------------------------
procedure store_gage_sensor(
   p_location_id      in varchar2,
   p_gage_id          in varchar2,
   p_sensor_id        in varchar2,
   p_fail_if_exists   in varchar2,
   p_ignore_nulls     in varchar2,
   p_parameter_id     in varchar2,
   p_report_unit_id   in varchar2 default null,
   p_valid_range_min  in binary_double default null,
   p_valid_range_max  in binary_double default null,
   p_zero_reading_val in binary_double default null,
   p_values_unit      in varchar2 default null,
   p_out_of_service   in varchar2 default 'F',
   p_manufacturer     in varchar2 default null,
   p_model_number     in varchar2 default null,
   p_serial_number    in varchar2 default null,
   p_comments         in varchar2 default null,
   p_office_id        in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure retrieve_gage_sensor
--------------------------------------------------------------------------------
procedure retrieve_gage_sensor(
   p_parameter_id     out varchar2,
   p_report_unit_id   out varchar2,
   p_valid_range_min  out binary_double,
   p_valid_range_max  out binary_double,
   p_zero_reading_val out binary_double,
   p_out_of_service   out varchar2,
   p_manufacturer     out varchar2,
   p_model_number     out varchar2,
   p_serial_number    out varchar2,
   p_comments         out varchar2,
   p_location_id      in  varchar2,
   p_gage_id          in  varchar2,
   p_sensor_id        in  varchar2,
   p_values_unit      in  varchar2 default null,
   p_office_id        in  varchar2 default null);

--------------------------------------------------------------------------------
-- procedure delete_gage_sensor
--------------------------------------------------------------------------------
procedure delete_gage_sensor(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_sensor_id   in varchar2,
   p_office_id   in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure rename_gage_sensor
--------------------------------------------------------------------------------
procedure rename_gage_sensor(
   p_location_id   in varchar2,
   p_gage_id       in varchar2,
   p_old_sensor_id in varchar2,
   p_new_sensor_id in varchar2,
   p_office_id     in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_gage_sensors
--------------------------------------------------------------------------------
procedure cat_gage_sensors(
   p_sensor_catalog         out sys_refcursor,
   p_location_id_mask       in  varchar2 default '*',
   p_gage_id_mask           in  varchar2 default '*',
   p_sensor_id_mask         in  varchar2 default '*',
   p_parameter_id_mask      in  varchar2 default '*',
   p_reporting_unit_id_mask in  varchar2 default '*',
   p_out_of_service_mask    in  varchar2 default '*',
   p_manufacturer_mask      in  varchar2 default '*',
   p_model_number_mask      in  varchar2 default '*',
   p_serial_number_mask     in  varchar2 default '*',
   p_comments_mask          in  varchar2 default '*',
   p_unit_system            in  varchar2 default 'SI',
   p_office_id_mask         in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_gage_sensors_f
--------------------------------------------------------------------------------
function cat_gage_sensors_F(
   p_location_id_mask       in varchar2 default '*',
   p_gage_id_mask           in varchar2 default '*',
   p_sensor_id_mask         in varchar2 default '*',
   p_parameter_id_mask      in varchar2 default '*',
   p_reporting_unit_id_mask in varchar2 default '*',
   p_out_of_service_mask    in varchar2 default '*',
   p_manufacturer_mask      in varchar2 default '*',
   p_model_number_mask      in varchar2 default '*',
   p_serial_number_mask     in varchar2 default '*',
   p_comments_mask          in varchar2 default '*',
   p_unit_system            in varchar2 default 'SI',
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor;

--------------------------------------------------------------------------------
-- procedure store_goes
--------------------------------------------------------------------------------
procedure store_goes(
   p_location_id        in varchar2,
   p_gage_id            in varchar2,
   p_fail_if_exists     in varchar2,
   p_ignore_nulls       in varchar2,
   p_goes_id            in varchar2 default null,
   p_goes_satellite     in varchar2 default null,
   p_selftimed_channel  in number   default null,
   p_selftimed_rate     in number   default null, -- bits/s
   p_selftimed_interval in number   default null, -- minutes
   p_selftimed_offset   in number   default null, -- minutes
   p_selftimed_length   in number   default null, -- seconds
   p_random_channel     in number   default null,
   p_random_rate        in number   default null, -- bits/s
   p_random_interval    in number   default null, -- minutes
   p_random_offset      in number   default null, -- minutes
   p_office_id          in varchar2 default null);   

--------------------------------------------------------------------------------
-- procedure retrieve_goes
--------------------------------------------------------------------------------
procedure retrieve_goes(
   p_goes_id            out varchar2,
   p_goes_satellite     out varchar2,
   p_selftimed_channel  out number,
   p_selftimed_rate     out number, -- bits/s
   p_selftimed_interval out number, -- minutes
   p_selftimed_offset   out number, -- minutes
   p_selftimed_length   out number, -- seconds
   p_random_channel     out number,
   p_random_rate        out number, -- bits/s
   p_random_interval    out number, -- minutes
   p_random_offset      out number, -- minutes
   p_location_id        in  varchar2,
   p_gage_id            in  varchar2,
   p_office_id          in  varchar2 default null);   

--------------------------------------------------------------------------------
-- procedure delete_goes
--------------------------------------------------------------------------------
procedure delete_goes(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_office_id   in varchar2 default null);   

--------------------------------------------------------------------------------
-- procedure rename_goes
--------------------------------------------------------------------------------
procedure rename_goes(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_new_goes_id in varchar2,
   p_office_id   in varchar2 default null);

--------------------------------------------------------------------------------
-- procedure cat_goes
--------------------------------------------------------------------------------
procedure cat_goes(
   p_goes_catalog          out sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_gage_id_mask          in  varchar2 default '*',
   p_goes_id_mask          in  varchar2 default '*',
   p_satellite_mask        in  varchar2 default '*',
   p_min_selftimed_channel in  number default 0,
   p_max_selftimed_channel in  number default 999999,
   p_min_random_channel    in  number default 0,
   p_max_random_channel    in  number default 999999,
   p_office_id_mask        in  varchar2 default null);

--------------------------------------------------------------------------------
-- function cat_goes_f
--------------------------------------------------------------------------------
function cat_goes_f(
   p_location_id_mask      in varchar2 default '*',
   p_gage_id_mask          in varchar2 default '*',
   p_goes_id_mask          in varchar2 default '*',
   p_satellite_mask        in varchar2 default '*',
   p_min_selftimed_channel in number default 0,
   p_max_selftimed_channel in number default 999999,
   p_min_random_channel    in number default 0,
   p_max_random_channel    in number default 999999,
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor;

end cwms_gage;
/
show errors;