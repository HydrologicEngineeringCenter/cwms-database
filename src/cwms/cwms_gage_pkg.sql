create or replace package cwms_gage
/**
 * Routines for working with gages and sensors
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.1
 */
as

goes_category_id       constant varchar2(12) := 'GOES ALIASES';
goes_category_desc     constant varchar2(28) := 'GOES location aliases by gage';
goes_group_desc_prefix constant varchar2(43) := 'GOES location aliases for gage id ';
-- not documented
function get_gage_code(
   p_office_id   in varchar2,
   p_location_id in varchar2,
   p_gage_id     in varchar2)
   return number;
/**
 * Stores (inserts or updates) a gage to the database
 *
 * @param p_location_id     The location identifier for the gage
 * @param p_gage_id         The gage identifier (unique per location)
 * @param p_fail_if_exists  A flag ('T' or 'F') specifying whether the routine should fail if the specified gage already exists.
 * @param p_ignore_nulls    A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating. If 'T', no data is overwritten by NULL values
 * @param p_gage_type       The gage type
 * @param p_assoc_loc_id    The location identifier of the associated location, if any
 * @param p_discontinued    A flag ('T' or 'F') specifying whether the gage has been discontinued
 * @param p_out_of_service  A flag ('T' or 'F') specifying whether the gage is currently out of service
 * @param p_manufacturer    The gage manufacturer
 * @param p_model_number    The gage model number
 * @param p_serial_number   The gage serial number
 * @param p_phone_number    The phone number of the gage, if equipped with a telephone modem
 * @param p_internet_addr   The internet protocol address of the gage if connected to the internet
 * @param p_other_access_id Any other acccess identifier, if applicable
 * @param p_comments        Any comments about the gage
 * @param p_office_id       The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
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
   p_comments        in varchar2 default null,
   p_office_id       in varchar2 default null);
/**
 * Retreieve a gage from the database
 *
 * @param p_gage_type       The gage type
 * @param p_assoc_loc_id    The location identifier of the associated location, if any
 * @param p_discontinued    A flag ('T' or 'F') specifying whether the gage has been discontinued
 * @param p_out_of_service  A flag ('T' or 'F') specifying whether the gage is currently out of service
 * @param p_manufacturer    The gage manufacturer
 * @param p_model_number    The gage model number
 * @param p_serial_number   The gage serial number
 * @param p_phone_number    The phone number of the gage, if equipped with a telephone modem
 * @param p_internet_addr   The internet protocol address of the gage if connected to the internet
 * @param p_other_access_id Any other acccess identifier, if applicable
 * @param p_comments        Any comments about the gage.
 * @param p_location_id     The location identifier for the gage
 * @param p_gage_id         The gage identifier (unique per location)
 * @param p_office_id       The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
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
   p_comments        out varchar2,
   p_location_id     in  varchar2,
   p_gage_id         in  varchar2,
   p_office_id       in  varchar2 default null);
/**
 * Delete a gage from the database
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 *
 * @param p_location_id   The location identifier for the gage
 * @param p_gage_id       The gage identifier (unique per location)
 * @param p_delete_action Specifies what to delete.  Actions are as follows:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">p_delete_action</th>
 *     <th style="border:1px solid black;">Action</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_key</td>
 *     <td style="border:1px solid black;">deletes only the gage, and then only if no other data refers to it</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_data</td>
 *     <td style="border:1px solid black;">deletes only data that refers to this gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">cwms_util.delete_all</td>
 *     <td style="border:1px solid black;">deletes the gage and all data that refers to it</td>
 *   </tr>
 * </table>
 * @param p_office_id     The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
procedure delete_gage(
   p_location_id   in varchar2,
   p_gage_id       in varchar2,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id     in varchar2 default null);
/**
 * Renames a gage in the database
 *
 * @param p_location_id   The location identifier for the gage
 * @param p_old_gage_id   The existing gage identifier
 * @param p_new_gage_id   The new gage identifier
 * @param p_office_id     The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
procedure rename_gage(
   p_location_id   in varchar2,
   p_old_gage_id   in varchar2,
   p_new_gage_id   in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Catalogs gages that match specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_gage_catalog A cursor containing the matching gage information. The cursor
 * contains the following columns, sorted by the first three:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">gage_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">gage_type</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage type</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">discontinued</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Discontinued flag</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">out_of_service</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Out of service flag</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">phone_number</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The phone number of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">internet_address</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The internet address of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">other_access_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The other access identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">associated_location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The associated location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comment about the gage</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask The location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_id_mask The gage identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_type_mask The gage type to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_discontinued_mask The discontinued flag to match. Use 'T', 'F', or '*"
 *
 * @param p_out_of_service_mask The out of service flag to match. Use 'T', 'F' or '*'
 *
 * @param p_manufacturer_mask The gage manufacturer to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_model_number_mask The gage model number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_serial_number_mask The gage serial number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_phone_number_mask The gage phone number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_internet_addr_mask The gage internet address to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_other_access_id_mask The gage other access identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_assoc_location_id_mask The gage associated location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_comments_mask  The gage comments to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_office_id_mask The gage identifier to match. If not specified or NULL, the session
 * user's default office is used. To match multiple offices, use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 */
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
/**
 * Catalogs gages that match specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask The location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_id_mask The gage identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_type_mask The gage type to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_discontinued_mask The discontinued flag to match. Use 'T', 'F', or '*"
 *
 * @param p_out_of_service_mask The out of service flag to match. Use 'T', 'F' or '*'
 *
 * @param p_manufacturer_mask The gage manufacturer to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_model_number_mask The gage model number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_serial_number_mask The gage serial number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_phone_number_mask The gage phone number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_internet_addr_mask The gage internet address to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_other_access_id_mask The gage other access identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_assoc_location_id_mask The gage associated location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_comments_mask  The gage comments to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_office_id_mask The gage identifier to match. If not specified or NULL, the session
 * user's default office is used. To match multiple offices, use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @return A cursor containing the matching gage information. The cursor
 * contains the following columns, sorted by the first three:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">gage_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">gage_type</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage type</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">discontinued</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Discontinued flag</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">out_of_service</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Out of service flag</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">phone_number</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The phone number of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">internet_address</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The internet address of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">other_access_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The other access identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">associated_location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The associated location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comment about the gage</td>
 *   </tr>
 * </table>
 */
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
/**
 * Stores (inserts or updates) a gage to the database
 *
 * @param p_location_id      The location identifier for the gage
 * @param p_gage_id          The gage identifier (unique per location)
 * @param p_sensor_id        The sensor identifier (unique per gage)
 * @param p_fail_if_exists   A flag ('T' or 'F') specifying whether the routine should fail if the specified sensor already exists.
 * @param p_ignore_nulls     A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating. If 'T', no data is overwritten by NULL values
 * @param p_parameter_id     The CWMS parameter identifier for the sensed physical parameter
 * @param p_report_unit_id   The CWMS unit, if any, that the gage reports data from the sensor in
 * @param p_valid_range_min  The bottom of the valid value range for the sensor
 * @param p_valid_range_max  The top of the valid value range for the sensor
 * @param p_zero_reading_val The parameter value corresponding to a reading of zero from the sensor
 * @param p_values_unit      The unit for the valid range and zero reading parameters
 * @param p_out_of_service   A flag ('T' or 'F') specifying whether the sensor is currently out of service
 * @param p_manufacturer     The sensor manufacturer
 * @param p_model_number     The sensor model number
 * @param p_serial_number    The sensor serial number
 * @param p_comments         Any comments about the sensor
 * @param p_office_id        The office that owns the sensor gage location. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Retrieves a sensor from the database
 *
 * @param p_parameter_id     The CWMS parameter identifier for the sensed physical parameter
 * @param p_report_unit_id   The CWMS unit, if any, that the gage reports data from the sensor in
 * @param p_valid_range_min  The bottom of the valid value range for the sensor
 * @param p_valid_range_max  The top of the valid value range for the sensor
 * @param p_zero_reading_val The parameter value corresponding to a reading of zero from the sensor
 * @param p_out_of_service   A flag ('T' or 'F') specifying whether the sensor is currently out of service
 * @param p_manufacturer     The sensor manufacturer
 * @param p_model_number     The sensor model number
 * @param p_serial_number    The sensor serial number
 * @param p_comments         Any comments about the sensor
 * @param p_location_id      The location identifier for the gage
 * @param p_gage_id          The gage identifier
 * @param p_sensor_id        The sensor identifier
 * @param p_values_unit      The unit for the valid range and zero reading parameters
 * @param p_office_id        The office that owns the sensor gage location. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Deletes a sensor from the database
 *
 * @param p_location_id  The location identifier for the gage
 * @param p_gage_id      The gage identifier
 * @param p_sensor_id    The sensor identifier
 * @param p_office_id    The office that owns the sensor gage location. If not specified or NULL, the session user's default office is used
 */
procedure delete_gage_sensor(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_sensor_id   in varchar2,
   p_office_id   in varchar2 default null);
/**
 * Renames a sensor in the database
 *
 * @param p_location_id   The location identifier for the gage
 * @param p_gage_id       The gage identifier
 * @param p_old_sensor_id The existing sensor identifier
 * @param p_new_sensor_id The new sensor identifier
 * @param p_office_id     The office that owns the sensor gage location. If not specified or NULL, the session user's default office is used
 */
procedure rename_gage_sensor(
   p_location_id   in varchar2,
   p_gage_id       in varchar2,
   p_old_sensor_id in varchar2,
   p_new_sensor_id in varchar2,
   p_office_id     in varchar2 default null);
/**
 * Catalogs sensors that match specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_sensor_catalog A cursor containing the matching sensor information. The cursor
 * contains the following columns, sorted by the first four:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the sensor gage location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">gage_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">sensor_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">parameter_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The CWMS parameter associated with the sensor</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">report_unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The CWMS unit the sensor reports data in</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">valid_range_min</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The bottom of the valid range for the sensor</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">valid_range_max</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The top of the valid range for the sensor</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">zero_reading_value</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The CWMS parameter value corresponding to a sensor reading of zero</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">value_units</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The unit of the valid range and zero reading columns</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">out_of_service</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Out of service flag</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">manufacturer</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor manufacturer</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">model_number</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor model number</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">serial_number</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor serial number</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">15</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comment about the sensor</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask The location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_id_mask The gage identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_sensor_id_mask The sensor identifier type to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_parameter_id_mask The CWMS parameter identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_reporting_unit_id_mask The sensor reporting unit to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_out_of_service_mask The out of service flag to match. Use 'T', 'F' or '*'
 *
 * @param p_manufacturer_mask The sensor manufacturer to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_model_number_mask The sensor model number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_serial_number_mask The sensor serial number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_comments_mask  The sensor comments to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_unit_system The unit system ('EN' or 'SI') to report the valid range and zero reading
 * values in
 *
 * @param p_office_id_mask The office identifier to match. If not specified or NULL, the session
 * user's default office is used. To match multiple offices, use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 */
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
/**
 * Catalogs sensors that match specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask The location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_id_mask The gage identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_sensor_id_mask The sensor identifier type to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_parameter_id_mask The CWMS parameter identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_reporting_unit_id_mask The sensor reporting unit to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_out_of_service_mask The out of service flag to match. Use 'T', 'F' or '*'
 *
 * @param p_manufacturer_mask The sensor manufacturer to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_model_number_mask The sensor model number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_serial_number_mask The sensor serial number to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_comments_mask  The sensor comments to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_unit_system The unit system ('EN' or 'SI') to report the valid range and zero reading
 * values in
 *
 * @param p_office_id_mask The office identifier to match. If not specified or NULL, the session
 * user's default office is used. To match multiple offices, use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @return A cursor containing the matching sensor information. The cursor
 * contains the following columns, sorted by the first four:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the sensor gage location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">gage_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">sensor_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">parameter_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The CWMS parameter associated with the sensor</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">report_unit_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The CWMS unit the sensor reports data in</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">valid_range_min</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The bottom of the valid range for the sensor</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">valid_range_max</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The top of the valid range for the sensor</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">zero_reading_value</td>
 *     <td style="border:1px solid black;">binary_double</td>
 *     <td style="border:1px solid black;">The CWMS parameter value corresponding to a sensor reading of zero</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">value_units</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The unit of the valid range and zero reading columns</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">out_of_service</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">Out of service flag</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">manufacturer</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor manufacturer</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">model_number</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor model number</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">serial_number</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The sensor serial number</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">15</td>
 *     <td style="border:1px solid black;">comments</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">Any comment about the sensor</td>
 *   </tr>
 * </table>
 */
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
/**
 * Stores (inserts or updates) GOES information about a gage to the database
 *
 * @param p_location_id        The location identifier for the gage
 * @param p_gage_id            The gage identifier (unique per location)
 * @param p_fail_if_exists     A flag ('T' or 'F') specifying whether the routine should fail if the specified GOES information already exists.
 * @param p_ignore_nulls       A flag ('T' or 'F') specifying whether to ignore NULL parameters when updating. If 'T', no data is overwritten by NULL values
 * @param p_goes_id            The GOES platform identifier of the gage
 * @param p_goes_satellite     The satellite ('E' or 'W') the gage transmits to
 * @param p_selftimed_channel  The satellite channel used for timed transmissions
 * @param p_selftimed_rate     The transmission rate for timed transmissions, in bits/s
 * @param p_selftimed_interval The timed transmission interval, in minutes
 * @param p_selftimed_offset   The transmission offset into the timed interval, in minutes
 * @param p_selftimed_length   The timed transmission time window, in seconds
 * @param p_random_channel     The satellite channel used for triggered transmissions
 * @param p_random_rate        The transmission rate for triggered transmissions, in bits/s
 * @param p_random_interval    The triggered transmission interval, in minutes
 * @param p_random_offset      The transmission offset into the triggered transmission interval, in minutes
 * @param p_office_id          The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Retrieve GOES information about a gage from the database
 *
 * @param p_goes_id            The GOES platform identifier of the gage
 * @param p_goes_satellite     The satellite ('E' or 'W') the gage transmits to
 * @param p_selftimed_channel  The satellite channel used for timed transmissions
 * @param p_selftimed_rate     The transmission rate for timed transmissions, in bits/s
 * @param p_selftimed_interval The timed transmission interval, in minutes
 * @param p_selftimed_offset   The transmission offset into the timed interval, in minutes
 * @param p_selftimed_length   The timed transmission time window, in seconds
 * @param p_random_channel     The satellite channel used for triggered transmissions
 * @param p_random_rate        The transmission rate for triggered transmissions, in bits/s
 * @param p_random_interval    The triggered transmission interval, in minutes
 * @param p_random_offset      The transmission offset into the triggered transmission interval, in minutes
 * @param p_location_id        The location identifier for the gage
 * @param p_gage_id            The gage identifier
 * @param p_office_id          The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Delete GOES information about a gage from the database
 *
 * @param p_location_id        The location identifier for the gage
 * @param p_gage_id            The gage identifier
 * @param p_office_id          The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
procedure delete_goes(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_office_id   in varchar2 default null);   
/**
 * Assigns a new GOES platform identifier to a gage in the database
 *
 * @param p_location_id The location identifier for the gage
 * @param p_gage_id     The gage identifier
 * @param p_new_goes_id The new GOES platform identifier
 * @param p_office_id   The office that owns the gage location. If not specified or NULL, the session user's default office is used
 */
procedure rename_goes(
   p_location_id in varchar2,
   p_gage_id     in varchar2,
   p_new_goes_id in varchar2,
   p_office_id   in varchar2 default null);
/**
 * Catalogs GOES information that matches specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_goes_catalog A cursor containing the matching GOES information. The cursor
 * contains the following columns, sorted by the first four:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the gage location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">gage_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">goes_id</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">The GOES platform identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">goes_satellite</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The GOES satellite</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">selftimed_channel</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission channel</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">selftimed_rate</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission rate, in bits/s</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">selftimed_interval</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission interval, in minutes</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">selftimed_offset</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The transmission offset into the timed interval, in minutes</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">selftimed_length</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission window, in seconds</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">random_channel</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The triggered transmission channel</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">random_rate</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The triggered transmission rate, in bits/s</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">random_interval</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The triggered transmission interval, in minutes</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">random_offset</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The transmission offset into the triggered interval, in minutes</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask The location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_id_mask The gage identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_goes_id_mask The GOES platform identifier type to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_satellite_mask The GOES satellite identifier to match. Use 'E', 'W' or '*'
 *
 * @param p_min_selftimed_channel The minimum timed transmission channel to match
 *
 * @param p_max_selftimed_channel The maximum timed transmission channel to match
 *
 * @param p_min_random_channel The minimum triggered transmission channel to match
 *
 * @param p_max_random_channel The maximum triggered transmission channel to match
 *
 * @param p_office_id_mask The office identifier to match. If not specified or NULL, the session
 * user's default office is used. To match multiple offices, use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 */
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
/**
 * Catalogs GOES information that matches specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Wildcard</th>
 *     <th style="border:1px solid black;">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">*</td>
 *     <td style="border:1px solid black;">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">?</td>
 *     <td style="border:1px solid black;">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_id_mask The location identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_gage_id_mask The gage identifier to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_goes_id_mask The GOES platform identifier type to match. Use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @param p_satellite_mask The GOES satellite identifier to match. Use 'E', 'W' or '*'
 *
 * @param p_min_selftimed_channel The minimum timed transmission channel to match
 *
 * @param p_max_selftimed_channel The maximum timed transmission channel to match
 *
 * @param p_min_random_channel The minimum triggered transmission channel to match
 *
 * @param p_max_random_channel The maximum triggered transmission channel to match
 *
 * @param p_office_id_mask The office identifier to match. If not specified or NULL, the session
 * user's default office is used. To match multiple offices, use glob-style wildcards
 * as shown above instead of sql-style wildcards.
 *
 * @return A cursor containing the matching GOES information. The cursor
 * contains the following columns, sorted by the first four:
 * <p>
 * <table style="border-collapse:collapse; border:1px solid black;">
 *   <tr>
 *     <th style="border:1px solid black;">Column No.</th>
 *     <th style="border:1px solid black;">Column Name</th>
 *     <th style="border:1px solid black;">Data Type</th>
 *     <th style="border:1px solid black;">Contents</th>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">1</td>
 *     <td style="border:1px solid black;">office_id</td>
 *     <td style="border:1px solid black;">varchar2(16)</td>
 *     <td style="border:1px solid black;">The office that owns the gage location</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">2</td>
 *     <td style="border:1px solid black;">location_id</td>
 *     <td style="border:1px solid black;">varchar2(49)</td>
 *     <td style="border:1px solid black;">The location identifier of the gage</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">3</td>
 *     <td style="border:1px solid black;">gage_id</td>
 *     <td style="border:1px solid black;">varchar2(32)</td>
 *     <td style="border:1px solid black;">The gage identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">4</td>
 *     <td style="border:1px solid black;">goes_id</td>
 *     <td style="border:1px solid black;">varchar2(256)</td>
 *     <td style="border:1px solid black;">The GOES platform identifier</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">5</td>
 *     <td style="border:1px solid black;">goes_satellite</td>
 *     <td style="border:1px solid black;">varchar2(1)</td>
 *     <td style="border:1px solid black;">The GOES satellite</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">6</td>
 *     <td style="border:1px solid black;">selftimed_channel</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission channel</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">7</td>
 *     <td style="border:1px solid black;">selftimed_rate</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission rate, in bits/s</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">8</td>
 *     <td style="border:1px solid black;">selftimed_interval</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission interval, in minutes</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">9</td>
 *     <td style="border:1px solid black;">selftimed_offset</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The transmission offset into the timed interval, in minutes</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">10</td>
 *     <td style="border:1px solid black;">selftimed_length</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The timed transmission window, in seconds</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">11</td>
 *     <td style="border:1px solid black;">random_channel</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The triggered transmission channel</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">12</td>
 *     <td style="border:1px solid black;">random_rate</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The triggered transmission rate, in bits/s</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">13</td>
 *     <td style="border:1px solid black;">random_interval</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The triggered transmission interval, in minutes</td>
 *   </tr>
 *   <tr>
 *     <td style="border:1px solid black;">14</td>
 *     <td style="border:1px solid black;">random_offset</td>
 *     <td style="border:1px solid black;">number</td>
 *     <td style="border:1px solid black;">The transmission offset into the triggered interval, in minutes</td>
 *   </tr>
 * </table>
 */
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