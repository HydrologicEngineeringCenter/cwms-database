set define off
CREATE OR REPLACE PACKAGE cwms_level
/**
 * Facilities for working with location levels.<p>
 *
 * General information about CWMS location levels can be found <a href="CWMS LOCATION LEVELS.pdf">here</a>.
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.1
 */
AS
/*
 * Not documented. Package-specific and session-specific logging properties
 */
v_package_log_prop_text varchar2(30);
function package_log_property_text return varchar2;

/**
 * Sets text value of package logging property
 *
 * @param p_text The text of the package logging property. If unspecified or NULL, the current session identifier is used.
 */
procedure set_package_log_property_text(
   p_text in varchar2 default null);
/**
 * Parses an attribute identifier into its components
 *
 * @param p_parameter_id     The parameter component
 * @param p_paramter_type_id The paramter type comonent
 * @param p_duration_id      The duration component
 * @param p_attribute_id     The attribute identifier to parse
 *
 */
procedure parse_attribute_id(
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_attribute_id       in  varchar2);
/**
 * Constructs an attribute identifier from its components
 *
 * @param p_parameter_id     The parameter component
 * @param p_paramter_type_id The paramter type comonent
 * @param p_duration_id      The duration component
 *
 * @return The attribute identifier
 */
function get_attribute_id(
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2)
   return varchar2;
/**
 * Parses a location level identifier into its components
 *
 * @param p_location_id        The location component
 * @param p_parameter_id       The parameter component
 * @param p_paramter_type_id   The paramter type comonent
 * @param p_duration_id        The duration component
 * @param p_specified_level_id The specified level component
 * @param p_location_level_id  The location level identifier to parse
 */
procedure parse_location_level_id(
   p_location_id        out varchar2,
   p_parameter_id       out varchar2,
   p_parameter_type_id  out varchar2,
   p_duration_id        out varchar2,
   p_specified_level_id out varchar2,
   p_location_level_id  in  varchar2);
/**
 * Retrieves a location level identifier based on its unique numeric code
 *
 * @param p_location_level_code The unique numeric code that identifies the location level
 *
 * @return The location level identifier
 */
function get_location_level_id(
   p_location_level_code in number)
   return varchar2;
/**
 * Constructs a location level identifier from its components
 *
 * @param p_location_id        The location component
 * @param p_parameter_id       The parameter component
 * @param p_paramter_type_id   The paramter type comonent
 * @param p_duration_id        The duration component
 * @param p_specified_level_id The specified level component
 *
 * @return The location level identifier
 */
function get_location_level_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2)
   return varchar2 ;
/**
 * Parses a location level indicator identifier into its components
 *
 * @param p_location_id          The location component
 * @param p_parameter_id         The parameter component
 * @param p_paramter_type_id     The paramter type comonent
 * @param p_duration_id          The duration component
 * @param p_specified_level_id   The specified level component
 * @param p_level_indicator_id   The incidator component
 * @param p_loc_lvl_indicator_id The location level indicator identifier to parse
 */
procedure parse_loc_lvl_indicator_id(
   p_location_id          out varchar2,
   p_parameter_id         out varchar2,
   p_parameter_type_id    out varchar2,
   p_duration_id          out varchar2,
   p_specified_level_id   out varchar2,
   p_level_indicator_id   out varchar2,
   p_loc_lvl_indicator_id in  varchar2);
/**
 * Constructs a location level indicator identifier from its components
 *
 * @param p_location_id          The location component
 * @param p_parameter_id         The parameter component
 * @param p_paramter_type_id     The paramter type comonent
 * @param p_duration_id          The duration component
 * @param p_specified_level_id   The specified level component
 * @param p_level_indicator_id   The incidator component
 *
 * @return The location level indicator identifier
 */
function get_loc_lvl_indicator_id(
   p_location_id        in varchar2,
   p_parameter_id       in varchar2,
   p_parameter_type_id  in varchar2,
   p_duration_id        in varchar2,
   p_specified_level_id in varchar2,
   p_level_indicator_id in varchar2)
   return varchar2;
/**
 * Stores (inserts or update) a specified level to the database, returning its numeric code
 *
 * @param p_level_code     The unique numeric code that identifies the specified level
 * @param p_level_id       The specified level identifier
 * @param p_description    A description of the specified level
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the specified level already exists. If 'F' the existing numeric code is returned
 * @param p_office_id      The office that owns the specified level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified level already exists
 */
procedure create_specified_level_out(
   p_level_code     out number,
   p_level_id       in  varchar2,
   p_description    in  varchar2,
   p_fail_if_exists in  varchar2 default 'T',
   p_office_id      in  varchar2 default null);
/**
 * Stores (inserts or update) a specified level to the database
 *
 * @param p_level_id       The specified level identifier
 * @param p_description    A description of the specified level
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the specified level already exists. If 'F' the existing numeric code is returned
 * @param p_office_id      The office that owns the specified level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified level already exists
 */
procedure store_specified_level(
   p_level_id       in varchar2,
   p_description    in varchar2,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null);
/**
 * Stores (inserts or update) a specified level to the database
 *
 * @param p_obj            The specified level to store
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the specified level already exists. If 'F' the existing numeric code is returned
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the specified level already exists
 */
procedure store_specified_level(
   p_obj            in specified_level_t,
   p_fail_if_exists in varchar2 default 'T');
/**
 * Retrieves the unique numeric code that identifies a specified level
 *
 * @param p_level_id          The specified level identifier
 * @param p_fail_if_not_found A flag ('T' or 'F') that specifies whether the routine should fail if no such specified level exists in the database. If 'F' NULL is returned
 * @param p_office_id         The office that owns the specified level. If not specified or NULL, the session user's default office is used
 *
 * @return The unique numeric code that identifies the specified level
 *
 * @exception ITEM_DOES_NOT_EXIST if p_fail_if_not_found is 'T' and the specified level does not exist
 */
function get_specified_level_code(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null)
   return number;
/**
 * Retrieves the description for a specified level
 *
 * @param p_description The description for the specified level
 * @param p_level_id    The specified level identifier
 * @param p_office_id   The office that owns the specified level. If not specified or NULL, the session user's default office is used
 */
procedure retrieve_specified_level(
   p_description    out varchar2,
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null);
/**
 * Retrieves a specified level
 *
 * @param p_level_id   The specified level identifier
 * @param p_office_id  The office that owns the specified level. If not specified or NULL, the session user's default office is used
 *
 * @return The specified level
 */
function retrieve_specified_level(
   p_level_id       in  varchar2,
   p_office_id      in  varchar2 default null)
   return specified_level_t;
/**
 * Deletes a specified level
 *
 * @param p_level_id          The specified level identifier
 * @param p_fail_if_not_found A flag ('T' or 'F') that specifies whether the routine should fail if no such specified level exists in the database
 * @param p_office_id         The office that owns the specified level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_DOES_NOT_EXIST if p_fail_if_not_found is 'T' and the specified level does not exist
 */
procedure delete_specified_level(
   p_level_id          in  varchar2,
   p_fail_if_not_found in  varchar2 default 'T',
   p_office_id         in  varchar2 default null);
/**
 * Renames a specified level
 *
 * @param old_p_level_id The existing specified level identifier
 * @param new_p_level_id The new specified level identifier
 * @param p_office_id    The office that owns the specified level. If not specified or NULL, the session user's default office is used
 */
procedure rename_specified_level(
   p_old_level_id in varchar2,
   p_new_level_id in varchar2,
   p_office_id    in varchar2 default null);
/**
 * Catalogs specified levels in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_level_cursor A cursor containing all matching specified levels.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the specified level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specified_level_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The identifier of the specified level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">A description, if any, of the specified level</td>
 *   </tr>
 * </table>
 *
 * @param p_level_id_mask  The specified level pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 */
procedure cat_specified_levels(
   p_level_cursor   out sys_refcursor,
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null);
/**
 * Catalogs specified levels in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_level_id_mask  The specified level pattern to match. Use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @return A cursor containing all matching specified levels.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the specified level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">specified_level_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The identifier of the specified level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">A description, if any, of the specified level</td>
 *   </tr>
 * </table>
 */
function cat_specified_levels(
   p_level_id_mask  in  varchar2,
   p_office_id_mask in  varchar2 default null)
   return sys_refcursor;
/**
 * Stores (inserts or updates) a location level to the database. To specify an irregularly varying level
 * using a time series, use <a href="store_location_level3">store_location_level3</a>.
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Applies from this time forward
 * @param p_timezone_id        The time zone of p_effective_date and p_interval_origin, if applicable
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_comment  A comment about the attribute, if applicable
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern
 * @param p_fail_if_exists     A flag ('T' or 'F') that specifies whether the routine should fail if the location level already exists in the database
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the location level already exists in the database
 */
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
/**
 * Stores (inserts or updates) a location level to the database. To specify an irregularly varying level
 * using a time series, use <a href="store_location_level3">store_location_level3</a>.
 *
 * @param p_location_level  The location level to store
 */
procedure store_location_level(
   p_location_level in  location_level_t);
/**
 * Stores (inserts or updates) a location level to the database using simple data types. To specify an irregularly varying level
 * using a time series, use <a href="#store_location_level3">store_location_level3</a>.
 *
 * @see cwms_util.parse_string_recordset
 * @see constant cwms_util.field_separator
 * @see constant cwms_util.record_separator
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Format is 'yyyy/mm/dd hh:mm:ss'. Applies from this time forward
 * @param p_timezone_id        The time zone of p_effective_date and p_interval_origin, if applicable
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_comment  A comment about the attribute, if applicable
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern, as a text recordset. Each record should contain offset_months, offset_minutes, and offset_value.
 * @param p_fail_if_exists     A flag ('T' or 'F') that specifies whether the routine should fail if the location level already exists in the database
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the location level already exists in the database
 */
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
/**
 * Stores (inserts or updates) a location level to the database
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Applies from this time forward
 * @param p_timezone_id        The time zone of p_effective_date and p_interval_origin, if applicable
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_comment  A comment about the attribute, if applicable
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern or time series value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_tsid               The time series identifier that represents the location level, if the level varies irregularly
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern
 * @param p_fail_if_exists     A flag ('T' or 'F') that specifies whether the routine should fail if the location level already exists in the database
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the location level already exists in the database
 */
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
/**
 * Stores (inserts or updates) a location level to the database
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Applies from this time forward
 * @param p_timezone_id        The time zone of p_effective_date and p_interval_origin, if applicable
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_comment  A comment about the attribute, if applicable
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern or time series value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_tsid               The time series identifier that represents the location level, if the level varies irregularly
 * @param p_expiration_date    The date/time that the location level expires
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern
 * @param p_fail_if_exists     A flag ('T' or 'F') that specifies whether the routine should fail if the location level already exists in the database
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the location level already exists in the database
 */
procedure store_location_level4(
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
   p_expiration_date         in  date     default null,
   p_seasonal_values         in  seasonal_value_tab_t default null,
   p_fail_if_exists          in  varchar2 default 'T',
   p_office_id               in  varchar2 default null);
/**
 * Stores location levels specified in an XML instance
 *
 * @param p_errors         On output, contains error reports of any errors that occured storing the location levels.
 *                         If NULL on input and no errors occur, it will be NULL on output.
 *                         If NULL on input and errors occur, it will be a new temporary CLOB that should be freed after use.
 *                         If not NULL on input, any errors will be appended to the input value.
 * @param p_xml            The XML instance containing the location levels to store
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether to fail if one of the location levels in the input already exists
 * @param p_fail_on_error  A flag ('T' of 'F') that specifies whether to fail if there is an error storing one of the location levels in the input
 */
procedure store_location_levels_xml(
   p_errors         out nocopy clob,
   p_xml            in  clob,
   p_fail_if_exists in  varchar2 default 'T',
   p_fail_on_error  in  varchar2 default 'F');
/**
 * Retrieves a location level from the database. To retrieve an irregularly varying level
 * using a time series, use <a href="retrieve_location_level3">store_location_level3</a>.
 *
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Applies from this time forward
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_date               The date for which to retrieve the level
 * @param p_timezone_id        The time zone of p_date. Retrieved dates are also in this time zone
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_match_date         A flag ('T' or 'F') that specifies whether p_date is interpreted as an effective date.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_match_date</th>
 *     <th class="descr">If p_date matches an effective date</th>
 *     <th class="descr">If p_date does not match an effective date</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'T'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'F'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves the level with the latest effecitve date before p_date</td>
 *   </tr>
 * </table>
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Retrieves a location level from the database using simple data types. To retrieve an irregularly varying level
 * using a time series, use <a href="retrieve_location_level3">store_location_level3</a>.
 *
 * @see cwms_util.parse_string_recordset
 * @see constant cwms_util.field_separator
 * @see constant cwms_util.record_separator
 *
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Format is 'yyyy/mm/dd hh:mm:ss'. Applies from this time forward
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern. See <a href="cwms_util.parse_string_recordset">cwms_util.parse_string_recordset</a>.
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_date               The date for which to retrieve the level. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_timezone_id        The time zone of p_date. Retrieved dates are also in this time zone
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_match_date         A flag ('T' or 'F') that specifies whether p_date is interpreted as an effective date.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_match_date</th>
 *     <th class="descr">If p_date matches an effective date</th>
 *     <th class="descr">If p_date does not match an effective date</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'T'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'F'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves the level with the latest effecitve date before p_date</td>
 *   </tr>
 * </table>
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Retrieves a location level from the database
 *
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Applies from this time forward
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_tsid               The time series identifier that represents the location level, if the level varies irregularly
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_date               The date for which to retrieve the level
 * @param p_timezone_id        The time zone of p_date. Retrieved dates are also in this time zone
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_match_date         A flag ('T' or 'F') that specifies whether p_date is interpreted as an effective date.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_match_date</th>
 *     <th class="descr">If p_date matches an effective date</th>
 *     <th class="descr">If p_date does not match an effective date</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'T'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'F'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves the level with the latest effecitve date before p_date</td>
 *   </tr>
 * </table>
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Retrieves a location level from the database
 *
 * @param p_level_value        The level value, if the level is constant
 * @param p_level_comment      A comment about the location level
 * @param p_effective_date     The effective date for the location level. Applies from this time forward
 * @param p_interval_origin    The start of any pattern interval, if the level varies in a recurring pattern
 * @param p_interval_months    The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in months and/or years
 * @param p_interval_minutes   The length of the pattern interval, if the level varies in a recurring pattern and the interval is expressed in hours and/or days
 * @param p_interpolate        A flag ('T' or 'F') that specifies whether the level value changes linearly from one pattern value to the next ('T') or takes on the preceding value ('F'), if the level varies in a recurring pattern
 * @param p_tsid               The time series identifier that represents the location level, if the level varies irregularly
 * @param p_expiration_date    The date/time that the location level expires
 * @param p_seasonal_values    The recurring pattern values, if the level varies in a recurring pattern
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_date               The date for which to retrieve the level
 * @param p_timezone_id        The time zone of p_date. Retrieved dates are also in this time zone
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_match_date         A flag ('T' or 'F') that specifies whether p_date is interpreted as an effective date.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_match_date</th>
 *     <th class="descr">If p_date matches an effective date</th>
 *     <th class="descr">If p_date does not match an effective date</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'T'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'F'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves the level with the latest effecitve date before p_date</td>
 *   </tr>
 * </table>
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 */
procedure retrieve_location_level4(
   p_level_value             out number,
   p_level_comment           out varchar2,
   p_effective_date          out date,
   p_interval_origin         out date,
   p_interval_months         out integer,
   p_interval_minutes        out integer,
   p_interpolate             out varchar2,
   p_tsid                    out varchar2,
   p_expiration_date         out date,
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
/**
 * Retrieves a location level from the database
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit of p_level_value or p_seasonal_values
 * @param p_date               The date for which to retrieve the level
 * @param p_timezone_id        The time zone of p_date. Retrieved dates are also in this time zone
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_match_date         A flag ('T' or 'F') that specifies whether p_date is interpreted as an effective date.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_match_date</th>
 *     <th class="descr">If p_date matches an effective date</th>
 *     <th class="descr">If p_date does not match an effective date</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'T'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">'F'</td>
 *     <td class="descr">Retrieves the level with the matched effecitve date</td>
 *     <td class="descr">Retrieves the level with the latest effecitve date before p_date</td>
 *   </tr>
 * </table>
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels to be retrieved. Valid value are:
 * <ul>
 *   <li><b>N</b> retrieves a non-virtual (normal) location level or NULL if not matched
 *   <li><b>V</b> retrieves a virtual location level or NULL if not matched
 *   <li><b>NV</b> retrieves non-virtual (normal) location level if matched, otherwise a virtual location level if matched, otherwise NULL
 *   <li><b>VN</b> (default) retrieves virtual location level if matched, otherwise a non-virtual (normal) location level if matched, otherwise NULL
 * </ul>
 *
 * @return The location level
 */
function retrieve_location_level(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_match_date              in  varchar2 default 'F',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return location_level_t;
/**
 * Retrieves location levels matching input specifications in XML format. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_levels            The location levels matching the specified parameters, in XML format
 * @param p_location_level_id_mask     The location level identifiers to match, using glob-style wildcards. If not specified, '*' is used.
 * @param p_attribute_id_mask          The location level attribute identifiers to match, using glob-style wildcards. If not specified, '*' is used. If NULL, only levels without attributes are matched.
 * @param p_start_time                 The earilest time to match levels for. If not specified or NULL, no earliest time constraint is used
 * @param p_end_time                   The latest time match levels for. If not specified or NULL, no latest time constraint is used.
 * @param p_timezone_id                The time zone of p_start_time and p_end_time, and also of effective and expiration times in the output. If not specified, 'UTC' is used.
 * @param p_unit_system                The unit system ('SI' or 'EN') to output the information in. If not specified, 'SI' is used.
 * @param p_attribute_value            The value of the location level attribute, if any
 * @param p_attribute_unit             The unit of p_attribute_value, if any
 * @param p_level_type                 One or two characters that specify which types of location levels to include. If not specified, 'VN' is used.
 * <ul>
 *   <li><b>N</b> include non-virtual (normal) location levels only
 *   <li><b>V</b> include virtual location levels only (but see p_include_constituent_levels below)
 *   <li><b>NV</b> include both non-virtual and virtual location levels
 *   <li><b>VN</b> include both non-virtual and virtual location levels
 * </ul>
 * @param p_include_levels             A flag ('T' or 'F') that specifies whether actual location levels will be included in the output.
 * @param p_include_constituent_levels A flag ('T' or 'F') that specifies whether information for location level constituents of virtual location levels will be included in the output.
 *                                     If 'T', non-virtual constituent location levels will be included even if p_level_type is 'V'. If unspecified, 'F' is used.
 * @param p_include_level_sources      A flag ('T' or 'F') that specifies whether location level sources will be included in the output.
 * @param p_include_level_labels       A flag ('T' or 'F') that specifies whether location level labels will be included in the output.
 * @param p_retrieve_level_indicators  A flag ('T' or 'F') that specifies whether location level indicators will be included in the output.
 * @param p_office_id                  The office to output the location levels for. If unspecified or NULL, the session user's default office is used.
 */
procedure retrieve_location_levels_xml(
   p_location_levels            out nocopy clob,
   p_location_level_id_mask     in  varchar2 default '*',
   p_attribute_id_mask          in  varchar2 default '*',
   p_start_time                 in  date     default null,
   p_end_time                   in  date     default null,
   p_timezone_id                in  varchar2 default 'UTC',
   p_unit_system                in  varchar2 default 'SI',
   p_attribute_value            in  number   default null,
   p_attribute_unit             in  varchar2 default null,
   p_level_type                 in  varchar2 default 'VN',
   p_include_levels             in  varchar2 default 'T',
   p_include_constituent_levels in  varchar2 default 'F',
   p_include_level_sources      in  varchar2 default 'F',
   p_include_level_labels       in  varchar2 default 'F',
   p_include_level_indicators   in  varchar2 default 'F',
   p_office_id                  in  varchar2 default null);
/**
 * Retrieves location levels matching input specifications in XML format. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_location_level_id_mask     The location level identifiers to match, using glob-style wildcards. If not specified, '*' is used.
 * @param p_attribute_id_mask          The location level attribute identifiers to match, using glob-style wildcards. If not specified, '*' is used. If NULL, only levels without attributes are matched.
 * @param p_start_time                 The earilest time to match levels for. If not specified or NULL, no earliest time constraint is used
 * @param p_end_time                   The latest time match levels for. If not specified or NULL, no latest time constraint is used.
 * @param p_timezone_id                The time zone of p_start_time and p_end_time, and also of effective and expiration times in the output. If not specified, 'UTC' is used.
 * @param p_unit_system                The unit system ('SI' or 'EN') to output the information in. If not specified, 'SI' is used.
 * @param p_attribute_value            The value of the location level attribute, if any
 * @param p_attribute_unit             The unit of p_attribute_value, if any
 * @param p_level_type                 One or two characters that specify which types of location levels to include. If not specified, 'VN' is used.
 * <ul>
 *   <li><b>N</b> include non-virtual (normal) location levels only
 *   <li><b>V</b> include virtual location levels only (but see p_include_constituent_levels below)
 *   <li><b>NV</b> include both non-virtual and virtual location levels
 *   <li><b>VN</b> include both non-virtual and virtual location levels
 * </ul>
 * @param p_include_levels             A flag ('T' or 'F') that specifies whether actual location levels will be included in the output.
 * @param p_include_constituent_levels A flag ('T' or 'F') that specifies whether information for location level constituents of virtual location levels will be included in the output.
 *                                     If 'T', non-virtual constituent location levels will be included even if p_level_type is 'V'. If unspecified, 'F' is used.
 * @param p_include_level_sources      A flag ('T' or 'F') that specifies whether location level sources will be included in the output.
 * @param p_include_level_labels       A flag ('T' or 'F') that specifies whether location level labels will be included in the output.
 * @param p_retrieve_level_indicators  A flag ('T' or 'F') that specifies whether location level indicators will be included in the output.
 * @param p_office_id                  The office to output the location levels for. If unspecified or NULL, the session user's default office is used.
 * @return The location levels matching the specified parameters, in XML format
 */
function retrieve_location_levels_xml_f(
   p_location_level_id_mask     in varchar2 default '*',
   p_attribute_id_mask          in varchar2 default '*',
   p_start_time                 in date     default null,
   p_end_time                   in date     default null,
   p_timezone_id                in varchar2 default 'UTC',
   p_unit_system                in varchar2 default 'SI',
   p_attribute_value            in number   default null,
   p_attribute_unit             in varchar2 default null,
   p_level_type                 in varchar2 default 'VN',
   p_include_levels             in varchar2 default 'T',
   p_include_constituent_levels in varchar2 default 'F',
   p_include_level_sources      in varchar2 default 'F',
   p_include_level_labels       in varchar2 default 'F',
   p_include_level_indicators   in varchar2 default 'F',
   p_office_id                  in varchar2 default null)
   return clob;
--
-- not documented
--
function get_prev_effective_date(
   p_location_level_code in integer,
   p_timezone            in varchar2 default 'UTC')
   return date;
--
-- not documented
--
function get_next_effective_date(
   p_location_level_code in integer,
   p_timezone            in varchar2 default 'UTC')
   return date;
/**
 * Retrieves a time series of location level values for a specified location level
 * and a time window
 *
 * @param p_level_values       The location level values. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window
 * @param p_end_time           The end of the time window
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_end_time
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a time series of location level values for a specified location level
 * and a time window
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window
 * @param p_end_time           The end of the time window
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level values. The time series contains values at the spcified
 * start and end times of the time window and may contain values at intermediate times.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_end_time
 */
function retrieve_location_level_values(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return ztsv_array;
/**
 * Retrieves a time series of location level values for a specified location level
 * and a time window, using simple types
 *
 * @see cwms_util.parse_string_recordset
 *
 * @param p_level_values       The location level values as a string recordset. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times. Each record in the recordset contains fields for date/time, value, and quality code. See <a href="cwms_util.parse_string_recordset">cwms_util.parse_string_recordset</a>.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_end_time           The end of the time window. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a time series of location level values for a specified location level
 * and a time window, using simple types
 *
 * @see cwms_util.parse_string_recordset
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_end_time           The end of the time window. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level values as a string recordset. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times. Each record in the recordset contains fields for date/time, value, and quality code. See <a href="cwms_util.parse_string_recordset">cwms_util.parse_string_recordset</a>.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 */
function retrieve_loc_lvl_values2(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  varchar2,
   p_end_time                in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return varchar2;
/**
 * Retrieves a time series of location level values for a specified location level
 * and specified times
 *
 * @param p_level_values       The location level values as a ztsv_array. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times. Each record in the recordset contains fields for date/time, value, and quality code. See <a href="cwms_util.parse_string_recordset">cwms_util.parse_string_recordset</a>.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 * @param p_specified_times    The times to retrieve the location level values for (only date_time member is used from each element)
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 */
procedure retrieve_loc_lvl_values3(
   p_level_values            out ztsv_array,
   p_specified_times         in  ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a time series of location level values for a specified location level
 * and specified times
 *
 * @param p_specified_times    The times to retrieve the location level values for (only date_time member is used from each element)
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level values as a ztsv_array. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times. Each record in the recordset contains fields for date/time, value, and quality code. See <a href="cwms_util.parse_string_recordset">cwms_util.parse_string_recordset</a>.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 */
function retrieve_loc_lvl_values3(
   p_specified_times         in  ztsv_array,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return ztsv_array;
/**
 * Retrieves a time series of location level values for a specified location level
 * and specified times
 *
 * @param p_level_values       The location level values as a double_tab_t
 * @param p_specified_times    The times to retrieve the location level values
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 */
procedure retrieve_loc_lvl_values3(
   p_level_values            out double_tab_t,
   p_specified_times         in  date_table_type,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a time series of location level values for a specified location level
 * and specified times
 *
 * @param p_specified_times    The times to retrieve the location level values
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level values as a double_tab_t
 */
function retrieve_loc_lvl_values3(
   p_specified_times         in  date_table_type,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return double_tab_t;
/**
 * Retrieves a time series of location level values for a specified location level
 * and times taken from a specified time series
 *
 * @param p_level_values       The location level values as a ztsv_array. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times. Each record in the recordset contains fields for date/time, value, and quality code. See <a href="cwms_util.parse_string_recordset">cwms_util.parse_string_recordset</a>.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 * @param p_ts_id              A time series to take the times from (using the specified time window)
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window
 * @param p_end_time           The end of the time window
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 */
procedure retrieve_loc_lvl_values3(
   p_level_values            out ztsv_array,
   p_ts_id                   in  varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a time series of location level values for a specified location level
 * and times taken from a specified time series
 *
 * @param p_ts_id              A time series to take the times from (using the specified time window)
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window
 * @param p_end_time           The end of the time window
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @param p_level_values       The location level values as a ztsv_array
 */
function retrieve_loc_lvl_values3(
   p_ts_id                   in  varchar2,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_start_time              in  date,
   p_end_time                in  date,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return ztsv_array;
/**
 * Retrieves a time series of location level values for a specified location level
 * time series, specified level, and time window.  The location level identifier
 * is generated from p_ts_id and p_spec_level_id
 *
 * @param p_level_values       The location level values. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 * @param p_ts_id                       The time series identifier
 * @param p_spec_level_id               The specified level identifier
 * @param p_level_units                 The value unit to retrieve the level values in
 * @param p_start_time                  The start of the time window
 * @param p_end_time                    The end of the time window
 * @param p_attribute_value             The value of the attribute, if applicable
 * @param p_attribute_units             The unit of the attribute, if applicable
 * @param p_attribute_parameter_id      The parameter identifier of the attribute, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_parameter_type_id The parameter type identifier of the attribute, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_duration_id       The duratino identifier of the attribute, if applicable. Format is parameter.parameter_type.duration
 * @param p_timezone_id                 The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id                   The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_end_time
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a time series of location level values for a specified location level
 * time series, specified level, and time window.  The location level identifier
 * is generated from p_ts_id and p_spec_level_id
 *
 * @param p_ts_id                       The time series identifier
 * @param p_spec_level_id               The specified level identifier
 * @param p_level_units                 The value unit to retrieve the level values in
 * @param p_start_time                  The start of the time window
 * @param p_end_time                    The end of the time window
 * @param p_attribute_value             The value of the attribute, if applicable
 * @param p_attribute_units             The unit of the attribute, if applicable
 * @param p_attribute_parameter_id      The parameter identifier of the attribute, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_parameter_type_id The parameter type identifier of the attribute, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_duration_id       The duratino identifier of the attribute, if applicable. Format is parameter.parameter_type.duration
 * @param p_timezone_id                 The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id                   The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level values. The time series contains
 * values at the spcified start and end times of the time window and may contain
 * values at intermediate times.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_end_time
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return ztsv_array;
/**
 * Retrieves a location level value for a specified location level and time
 *
 * @param p_level_value        The location level value
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level value in
 * @param p_date               The date/time to retrieve the level for
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of p_date
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_date
 */
procedure retrieve_location_level_value(
   p_level_value             out number,
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a location level value for a specified location level and time
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level value in
 * @param p_date               The date/time to retrieve the level for
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level value
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_date
 */
function retrieve_location_level_value(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return number;
/**
 * Retrieves a location level value for a specified location level
 * time series, specified level, and time.  The location level identifier
 * is generated from p_ts_id and p_spec_level_id
 *
 * @param p_level_value        The location level value
 * @param p_ts_id              The time series identifier
 * @param p_spec_level_id      The specified level identifier
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_date               The date/time to retrieve the level for
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of p_date
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_date
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves a location level value for a specified location level
 * time series, specified level, and time.  The location level identifier
 * is generated from p_ts_id and p_spec_level_id
 *
 * @param p_ts_id              The time series identifier
 * @param p_spec_level_id      The specified level identifier
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_date               The date/time to retrieve the level for
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of p_date
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level value
 *
 * @exception ITEM_DOES_NOT_EXIST if p_location_level_id doesn't exist for the the specified or default office, or is only effective after p_date
 */
function retrieve_location_level_value(
   p_ts_id                   in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null,
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return number;
/**
 * Retrieves a location level value for a specified location level and time, with maximum age if level is irregularly varying (backed by a time seiries)
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level value in
 * @param p_date               The date/time to retrieve the level for. If not specified or NULL, the current date/time is used
 * @param p_timezone_id        The time zone of p_date, ignored if p_date is null. If not specified or NULL when p_date is not NULL, the local time zone of the level's location is used
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_max_ts_timespan    The maximum timespan allowed for irregularly varying levels (i.e., levels backed by time series), in ISO 8601 (web time duration) format.
 *                             The timespan is one of
 *                             <ul>
 *                             <li>For un-interpolated (step) levels or intepolated levels with no time seires values after the specified or default date/time, this is the time between the latest time seiries value prior to the date/time and the date/time itself</li>
 *                             <li>For interpolated levels with a time series value after the specified or default date/time, this is the timespan between latest time series value before the date/time to the earliest time series value after the date/time</li>
 *                             </ul>
 *                             If the timepsan exceeds the specified maximum, NULL is returned. If not specified or NULL, no restriction on the timespan is used
 * @param p_ignore_errors      A flag ('T'/'F') that specifies whether to handle any exceptions raised during execution and return a NULL value ('T'). If 'F', exceptions are passed back to the calling environment
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels in the results.
 *                             The default value 'VN' gives virtual location levels higher precedence, allowing them to hide non-virtual location levels
 *                             where the two types overlap in time. Valid value are:
 * <ul>
 *   <li><b>N</b> specifies results from non-virtual (normal) location levels only
 *   <li><b>V</b> specifies results from virtual location levels only
 *   <li><b>NV</b> specifies results from non-virtual (normal) location levels where they exist, with virtual location levels allowed where non-virtual levels don't exist
 *   <li><b>VN</b> (default) specifies results from virtual location levels where they exist, with non-virtual location levels allowed where virtual levels don't exist
 * </ul>
 *
 * @return The location level value
 */
function retrieve_loc_lvl_value_ex(
   p_location_level_id       in  varchar2,
   p_level_units             in  varchar2,
   p_date                    in  date     default null, -- defaults to current time
   p_timezone_id             in  varchar2 default null, -- defaults to location time zone with non-null p_date
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null, -- required with non-null p_attribute_id
   p_attribute_units         in  varchar2 default null, -- required with non-null p_attribute_id
   p_max_ts_timespan         in  varchar2 default null, -- ISO 8601 format, returns null if time series timespan too long
   p_ignore_errors           in  varchar2 default 'F',  -- returns null on error if 'T'
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN') -- user's office id if null
   return number;
/**
 * Retrieves all the attribute values for a Location Level in effect at a specified time
 *
 * @param p_attribute_values   The retrieved attribute values
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the p_date
 * @param p_date               The date/time to retrieve the attribute values for
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to lookup values for. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual location levels only
 *   <li><b>NV</b> lookup values for both non-virtual and virtual location levels
 *   <li><b>VN</b> lookup values for both non-virtual and virtual location levels
 * </ul>
 */
procedure retrieve_location_level_attrs(
   p_attribute_values        out number_tab_t,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN');
/**
 * Retrieves all the attribute values for a Location Level in effect at a specified time
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the p_date
 * @param p_date               The date/time to retrieve the attribute values for
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to lookup values for. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual location levels only
 *   <li><b>NV</b> lookup values for both non-virtual and virtual location levels
 *   <li><b>VN</b> lookup values for both non-virtual and virtual location levels
 * </ul>
 *
 * @return The retrieved attribute values
 */
function retrieve_location_level_attrs(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  date     default null,
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN')
   return number_tab_t;
/**
 * Retrieves all the attribute values for a Location Level in effect at a specified time using simple types
 *
 * @param p_attribute_values   The retrieved attribute values
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the p_date
 * @param p_date               The date/time to retrieve the attribute values for. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to lookup values for. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual location levels only
 *   <li><b>NV</b> lookup values for both non-virtual and virtual location levels
 *   <li><b>VN</b> lookup values for both non-virtual and virtual location levels
 * </ul>
 */
procedure retrieve_location_level_attrs2(
   p_attribute_values        out varchar2,
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN');
/**
 * Retrieves all the attribute values for a Location Level in effect at a specified time using simple types
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the p_date
 * @param p_date               The date/time to retrieve the attribute values for. Format is 'yyyy/mm/dd hh:mm:ss'
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to lookup values for. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual location levels only
 *   <li><b>NV</b> lookup values for both non-virtual and virtual location levels
 *   <li><b>VN</b> lookup values for both non-virtual and virtual location levels
 * </ul>
 *
 * @return The retrieved attribute values
 */
function retrieve_location_level_attrs2(
   p_location_level_id       in  varchar2,
   p_attribute_id            in  varchar2,
   p_attribute_units         in  varchar2,
   p_timezone_id             in  varchar2 default null,
   p_date                    in  varchar2 default null,
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN')
   return varchar2;
/**
 * Retrieves the level value of a Location Level that corresponds to a specified attribute value and date
 *
 * @see constant cwms_lookup.method_closest
 * @see constant cwms_lookup.method_error
 * @see constant cwms_lookup.method_higher
 * @see constant cwms_lookup.method_lin_log
 * @see constant cwms_lookup.method_linear
 * @see constant cwms_lookup.method_log_lin
 * @see constant cwms_lookup.method_logarithmic
 * @see constant cwms_lookup.method_lower
 * @see constant cwms_lookup.method_null
 *
 * @param p_level              The retrieved location level value
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute
 * @param p_attribute_units    The unit of the attribute
 * @param p_level_units        The value unit to retrieve the level value in
 * @param p_in_range_behavior  Specifies the lookup behavior if the specified attribute value is between two stored attribute values for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_in_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of level value based on linear ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of level value based on linear ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lower</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is immediately lower in magnitude than p_attribute_value if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_higher</td>
 *     <td class="descr">11</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is immediately higher in magnitude than p_attribute_value if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_closest</td>
 *     <td class="descr">12</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is closest in magnitude than p_attribute_value if p_attribute_value is between stored attribute values</td>
 *   </tr>
 * </table>
 * @param p_out_range_behavior Specifies the lookup behavior if the specified attribute is outside the range of attributes for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_out_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of level value based on linear ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of level value based on linear ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_closest</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is immediately lower in magnitude than p_attribute_value if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 * </table>
 * @param p_timezone_id        The time zone of p_date
 * @param p_date               The date/time to retrieve the attribute value for
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels to lookup values for. Valid value are:
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual (normal) location levels only
 *   <li><b>NV</b> lookup values for non-virtual (normal) location levels, but if none exists, lookup values for virtual location levels
 *   <li><b>VN</b> (default) lookup values for virtual location levels, but if none exists, lookup values for non-virtual (normal) location levels
 * </ul>
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves the level value of a Location Level that corresponds to a specified attribute value and date
 *
 * @see constant cwms_lookup.method_closest
 * @see constant cwms_lookup.method_error
 * @see constant cwms_lookup.method_higher
 * @see constant cwms_lookup.method_lin_log
 * @see constant cwms_lookup.method_linear
 * @see constant cwms_lookup.method_log_lin
 * @see constant cwms_lookup.method_logarithmic
 * @see constant cwms_lookup.method_lower
 * @see constant cwms_lookup.method_null
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute
 * @param p_attribute_units    The unit of the attribute
 * @param p_level_units        The value unit to retrieve the level value in
 * @param p_in_range_behavior  Specifies the lookup behavior if the specified attribute value is between two stored attribute values for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_in_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of level value based on linear ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of level value based on linear ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lower</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is immediately lower in magnitude than p_attribute_value if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_higher</td>
 *     <td class="descr">11</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is immediately higher in magnitude than p_attribute_value if p_attribute_value is between stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_closest</td>
 *     <td class="descr">12</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is closest in magnitude than p_attribute_value if p_attribute_value is between stored attribute values</td>
 *   </tr>
 * </table>
 * @param p_out_range_behavior Specifies the lookup behavior if the specified attribute is outside the range of attributes for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_out_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of level value based on linear ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of level value based on linear ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of level value based on logarithmic ratio of attribute values if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_closest</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the level value that is associated with the stored attribute value that is immediately lower in magnitude than p_attribute_value if p_attribute_value is outside the range of stored attribute values</td>
 *   </tr>
 * </table>
 * @param p_timezone_id        The time zone of p_date
 * @param p_date               The date/time to retrieve the attribute value for
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels to lookup values for. Valid value are:
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual (normal) location levels only
 *   <li><b>NV</b> lookup values for non-virtual (normal) location levels, but if none exists, lookup values for virtual location levels
 *   <li><b>VN</b> (default) lookup values for virtual location levels, but if none exists, lookup values for non-virtual (normal) location levels
 * </ul>
 *
 * @return The retrieved location level value
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return number;
/**
 * Retrieves the attribute value of a Location Level that corresponds to a specified level value and date
 *
 * @see constant cwms_lookup.method_closest
 * @see constant cwms_lookup.method_error
 * @see constant cwms_lookup.method_higher
 * @see constant cwms_lookup.method_lin_log
 * @see constant cwms_lookup.method_linear
 * @see constant cwms_lookup.method_log_lin
 * @see constant cwms_lookup.method_logarithmic
 * @see constant cwms_lookup.method_lower
 * @see constant cwms_lookup.method_null
 *
 * @param p_attribute          The retrieved attribute level value
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier. Format is parameter.parameter_type.duration
 * @param p_level_value        The level value
 * @param p_level_units        The unit of the level value
 * @param p_attribute_units    The unit of the attribute to return the attribute in
 * @param p_in_range_behavior  Specifies the lookup behavior if the specified level value between stored level values of attributes for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_in_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of attribute value based on linear ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on logarithmic ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on linear ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of attribute value based on logarithmic ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lower</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is immediately lower in magnitude than p_level_value if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_higher</td>
 *     <td class="descr">11</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is immediately higher in magnitude than p_level_value if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_closest</td>
 *     <td class="descr">12</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is closest in magnitude than p_level_value if p_level_value is between stored level values</td>
 *   </tr>
 * </table>
 * @param p_out_range_behavior Specifies the lookup behavior if the specified level value is outside the range of level values for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_in_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of attribute value based on linear ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on logarithmic ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on linear ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of attribute value based on logarithmic ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lower</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is immediately lower in magnitude than p_level_value if p_level_value is outside the range of stored level values</td>
 *   </tr>
 * </table>
 * @param p_timezone_id        The time zone of p_date
 * @param p_date               The date/time to retrieve the attribute value for
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels to lookup values for. Valid value are:
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual (normal) location levels only
 *   <li><b>NV</b> lookup values for non-virtual (normal) location levels, but if none exists, lookup values for virtual location levels
 *   <li><b>VN</b> (default) lookup values for virtual location levels, but if none exists, lookup values for non-virtual (normal) location levels
 * </ul>
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN');
/**
 * Retrieves the attribute value of a Location Level that corresponds to a specified level value and date
 *
 * @see constant cwms_lookup.method_closest
 * @see constant cwms_lookup.method_error
 * @see constant cwms_lookup.method_higher
 * @see constant cwms_lookup.method_lin_log
 * @see constant cwms_lookup.method_linear
 * @see constant cwms_lookup.method_log_lin
 * @see constant cwms_lookup.method_logarithmic
 * @see constant cwms_lookup.method_lower
 * @see constant cwms_lookup.method_null
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_attribute_id       The attribute identifier. Format is parameter.parameter_type.duration
 * @param p_level_value        The level value
 * @param p_level_units        The unit of the level value
 * @param p_attribute_units    The unit of the attribute to return the attribute in
 * @param p_in_range_behavior  Specifies the lookup behavior if the specified level value between stored level values of attributes for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_in_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of attribute value based on linear ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on logarithmic ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on linear ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of attribute value based on logarithmic ratio of level values if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lower</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is immediately lower in magnitude than p_level_value if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_higher</td>
 *     <td class="descr">11</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is immediately higher in magnitude than p_level_value if p_level_value is between stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_closest</td>
 *     <td class="descr">12</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is closest in magnitude than p_level_value if p_level_value is between stored level values</td>
 *   </tr>
 * </table>
 * @param p_out_range_behavior Specifies the lookup behavior if the specified level value is outside the range of level values for the specified level and date.
 * Valid values are
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">p_in_range_behavior</th>
 *     <th class="descr">numeric value</th>
 *     <th class="descr">lookup behavior</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_null</td>
 *     <td class="descr">1</td>
 *     <td class="descr">Return null if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_error</td>
 *     <td class="descr">2</td>
 *     <td class="descr">Raise an exception if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_linear</td>
 *     <td class="descr">3</td>
 *     <td class="descr">Linear interpolation of attribute value based on linear ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_logarithmic</td>
 *     <td class="descr">4</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on logarithmic ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lin_log</td>
 *     <td class="descr">5</td>
 *     <td class="descr">Logarithmic interpolation of attribute value based on linear ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_log_lin</td>
 *     <td class="descr">6</td>
 *     <td class="descr">Linear interpolation of attribute value based on logarithmic ratio of level values if p_level_value is outside the range of stored level values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_lookup.method_lower</td>
 *     <td class="descr">10</td>
 *     <td class="descr">Return the attribute value that is associated with the stored level value that is immediately lower in magnitude than p_level_value if p_level_value is outside the range of stored level values</td>
 *   </tr>
 * </table>
 * @param p_timezone_id        The time zone of p_date
 * @param p_date               The date/time to retrieve the attribute value for
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_precedence   One or two characters that specify the precedence of virtual and non-virtual location levels to lookup values for. Valid value are:
 * <ul>
 *   <li><b>N</b> lookup values for non-virtual (normal) location levels only
 *   <li><b>V</b> lookup values for virtual (normal) location levels only
 *   <li><b>NV</b> lookup values for non-virtual (normal) location levels, but if none exists, lookup values for virtual location levels
 *   <li><b>VN</b> (default) lookup values for virtual location levels, but if none exists, lookup values for non-virtual (normal) location levels
 * </ul>
 *
 * @return The retrieved attribute level value
 */
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
   p_office_id               in  varchar2 default null,
   p_level_precedence        in  varchar2 default 'VN')
   return number;
/**
 * Renames a location level in the database
 *
 * param p_old_location_level_id The existing location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * param p_new_location_level_id The existing location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * param p_office_id             The office that owns the location level. If not specified or NULL, the session user's default office is used
 */
procedure rename_location_level(
   p_old_location_level_id in  varchar2,
   p_new_location_level_id in  varchar2,
   p_office_id             in  varchar2 default null);
/**
 * Deletes a location level, optionally deleting any recurring pattern records
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_effective_date     The effective date of the level to delete
 * @param p_timezone_id        The time zone of p_effective_date
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_cascade            A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to delete. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> delete non-virtual (normal) location levels only
 *   <li><b>V</b> delete virtual location levels only
 *   <li><b>NV</b> delete both non-virtual and virtual location levels
 *   <li><b>VN</b> delete both non-virtual and virtual location levels
 * </ul>
*/
procedure delete_location_level(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default 'F',
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN');
/**
 * Deletes a location level, optionally deleting any recurring pattern records
 *
 * @param p_location_level_code  The unique numeric value that identifies the location level in the database
 * @param p_cascade              A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 */
procedure delete_location_level(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default 'F');
/**
 * Deletes a location level, optionally deleting any recurring pattern records and location level indicators
 *
 * @deprecated Use Delete_Location_Level3 instead.
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_effective_date     The effective date of the level to delete
 * @param p_timezone_id        The time zone of p_effective_date
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_cascade            A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 * @param p_delete_indicators  A flag ('T' or 'F') that specifies whether to delete any location level indicators associated with the location level
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to delete. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> delete non-virtual (normal) location levels only
 *   <li><b>V</b> delete virtual location levels only
 *   <li><b>NV</b> delete both non-virtual and virtual location levels
 *   <li><b>VN</b> delete both non-virtual and virtual location levels
 * </ul>
 */
procedure delete_location_level_ex(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default 'F',
   p_delete_indicators       in  varchar2 default 'F',
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN');
pragma deprecate(delete_location_level_ex, 'Use DELETE_LOCATION_LEVEL3 instead of DELETE_LOCATION_LEVEL_EX');
/**
 * Deletes a location level, optionally deleting any recurring pattern records and location level indicators
 *
 * @deprecated Use Delete_Location_Level3 instead.
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_effective_date     The effective date of the level to delete
 * @param p_timezone_id        The time zone of p_effective_date
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_cascade            A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 * @param p_delete_indicators  A flag ('T' or 'F') that specifies whether to delete any location level indicators associated with the location level
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type         One or two characters that specify which types of location levels to delete. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> delete non-virtual (normal) location levels only
 *   <li><b>V</b> delete virtual location levels only
 *   <li><b>NV</b> delete both non-virtual and virtual location levels
 *   <li><b>VN</b> delete both non-virtual and virtual location levels
 * </ul>
 */
procedure delete_location_level2(
   p_location_level_id       in  varchar2,
   p_effective_date          in  date     default null,
   p_timezone_id             in  varchar2 default 'UTC',
   p_attribute_id            in  varchar2 default null,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_cascade                 in  varchar2 default 'F',
   p_delete_indicators       in  varchar2 default 'F',
   p_office_id               in  varchar2 default null,
   p_level_type              in  varchar2 default 'VN');
pragma deprecate(delete_location_level2, 'Use DELETE_LOCATION_LEVEL3 instead of DELETE_LOCATION_LEVEL2');
/**
 * Deletes a location level, optionally deleting any recurring pattern records and location level indicators
 *
 * @param p_location_level_code  The unique numeric value that identifies the location level in the database
 * @param p_cascade              A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 * @param p_delete_indicators    A flag ('T' or 'F') that specifies whether to delete any location level indicators associated with the location level
 */
procedure delete_location_level2(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default 'F',
   p_delete_indicators   in  varchar2 default 'F');
/**
 * Deletes a location level, optionally deleting any recurring pattern records, location level indicators, and associated pool definitions
 *
 * @param p_location_level_id          The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_effective_date             The effective date of the level to delete. If null, one of p_most_recent_effective_date or p_all_effective_dates must be 'T'
 * @param p_timezone_id                The time zone of p_effective_date
 * @param p_attribute_id               The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value            The value of the attribute, if applicable
 * @param p_attribute_units            The unit of the attribute, if applicable
 * @param p_cascade                    A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 * @param p_delete_indicators          A flag ('T' or 'F') that specifies whether to delete any location level indicators associated with the location level
 * @param p_delete_pools               A flag ('T' or 'F') that specifies whether to delete any explicit pool definitions associated with the location level
 * @param p_office_id                  The office that owns the location level. If not specified or NULL, the session user's default office is used
 * @param p_level_type                 One or two characters that specify which types of location levels to delete. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> delete non-virtual (normal) location levels only
 *   <li><b>V</b> delete virtual location levels only
 *   <li><b>NV</b> delete both non-virtual and virtual location levels
 *   <li><b>VN</b> delete both non-virtual and virtual location levels
 * </ul>
 * @param p_most_recent_effective_date A flag ('T' or 'F') That specifies deleting the latest effective date on or before the specified effective dates of the specified level type(s).
 *                                     If 'T' and p_effective_date is null, then the latest effective date on or before the current time will be deleted.
 * @param p_all_effective_dates        A flag ('T' or 'F') that specifies deleting all effective dates of the specified level type(s).
 *                                     If 'T', p_effective_date is ignored.
 * @param p_all_attribute_values       A flag ('T' or 'F') that specifies deleting levels with all attribute values for the specified id, effective date(s) and level type(s).
 *                                     If 'T', p_attribute_value is ignored.
 */
procedure delete_location_level3(
   p_location_level_id          in varchar2,
   p_effective_date             in date     default null,
   p_timezone_id                in varchar2 default 'UTC',
   p_attribute_id               in varchar2 default null,
   p_attribute_value            in number   default null,
   p_attribute_units            in varchar2 default null,
   p_cascade                    in varchar2 default 'F',
   p_delete_indicators          in varchar2 default 'F',
   p_delete_pools               in varchar2 default 'F',
   p_office_id                  in varchar2 default null,
   p_level_type                 in varchar2 default 'VN',
   p_most_recent_effective_date in varchar2 default 'F',
   p_all_effective_dates        in varchar2 default 'F',
   p_all_attribute_values       in varchar2 default 'F');
/**
 * Deletes a location level, optionally deleting any recurring pattern records, location level indicators, and associated pool definitions
 *
 * @param p_location_level_code  The unique numeric value that identifies the location level in the database
 * @param p_cascade              A flag ('T' or 'F') that specifies whether to delete any recurring pattern records. If 'F' and such records exist, the routine will fail
 * @param p_delete_pools         A flag ('T' or 'F') that specifies whether to delete any explicit pool definitions associated with the location level
 * @param p_delete_indicators    A flag ('T' or 'F') that specifies whether to delete any location level indicators associated with the location level
 */
procedure delete_location_level3(
   p_location_level_code in integer,
   p_cascade             in  varchar2 default 'F',
   p_delete_pools        in  varchar2 default 'F',
   p_delete_indicators   in  varchar2 default 'F');
/**
 * Sets the configuration-specific label for a location level
 *
 * @param p_loc_lvl_label     The configuration-specific label for the location level,
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_configuration_id  The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 * @param p_fail_if_exists    A flag (T/F) specifying whether to fail if a label already exists for the level and configuration
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 */
procedure set_loc_lvl_label(
   p_loc_lvl_label           in varchar2,
   p_location_level_id       in varchar2,
   p_attribute_value         in number   default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_configuration_id        in varchar2 default null,
   p_fail_if_exists          in varchar2 default 'T',
   p_office_id               in varchar2 default null);
/**
 * Gets the configuration-specific label for a location level
 *
 * @param p_loc_lvl_label     The configuration-specific label for the location level,
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_configuration_id  The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 */
procedure get_loc_lvl_label(
   p_loc_lvl_label           out varchar2,
   p_location_level_id       in  varchar2,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_configuration_id        in  varchar2 default null,
   p_office_id               in  varchar2 default null);
/**
 * Gets the configuration-specific label for a location level
 *
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_configuration_id  The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 *
 * @return The configuration-specific label for the location level,
 */
function get_loc_lvl_label_f(
   p_location_level_id       in varchar2,
   p_attribute_value         in number   default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_configuration_id        in varchar2 default null,
   p_office_id               in varchar2 default null)
   return varchar2;
/**
 * Deletes the configuration-specific label for a location level
 *
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_configuration_id  The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 */
procedure delete_loc_lvl_label(
   p_location_level_id       in varchar2,
   p_attribute_value         in number   default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_configuration_id        in varchar2 default null,
   p_office_id               in varchar2 default null);
/**
 * Sets the configuration-specific label for a location level
 *
 * @param p_loc_lvl_label            The configuration-specific label for the location level,
 * @param p_location_code            The location code for the location level
 * @param p_specified_level_code     The specified level code for the location level
 * @param p_parameter_code           The parameter code for the location level
 * @param p_parameter_type_code      The the parameter type code for the location level
 * @param p_duration_code            The duration code for the location level
 * @param p_attr_value               The value of the attribute for the location level, if any, in database units
 * @param p_attr_parameter_code      The parameter code of the attributes for the location lavel, if any
 * @param p_attr_parameter_type_code The parameter type code of the attributes for the location lavel, if any
 * @param p_attr_duration_code       The duration code of the attributes for the location lavel, if any
 * @param p_configuration_code       The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 * @param p_fail_if_exists           A flag (T/F) specifying whether to fail if a label already exists for the level and configuration
 */
procedure set_loc_lvl_label(
   p_loc_lvl_label            in varchar2,
   p_location_code            in integer,
   p_specified_level_code     in integer,
   p_parameter_code           in integer,
   p_parameter_type_code      in integer,
   p_duration_code            in integer,
   p_attr_value               in number  default null,
   p_attr_parameter_code      in integer default null,
   p_attr_parameter_type_code in integer default null,
   p_attr_duration_code       in integer default null,
   p_configuration_code       in integer default null,
   p_fail_if_exists           in varchar2 default 'T');
/**
 * Gets the configuration-specific label for a location level
 *
 * @param p_loc_lvl_label            The configuration-specific label for the location level,
 * @param p_location_code            The location code for the location level
 * @param p_specified_level_code     The specified level code for the location level
 * @param p_parameter_code           The parameter code for the location level
 * @param p_parameter_type_code      The the parameter type code for the location level
 * @param p_duration_code            The duration code for the location level
 * @param p_attr_value               The value of the attribute for the location level, if any, in database units
 * @param p_attr_parameter_code      The parameter code of the attributes for the location lavel, if any
 * @param p_attr_parameter_type_code The parameter type code of the attributes for the location lavel, if any
 * @param p_attr_duration_code       The duration code of the attributes for the location lavel, if any
 * @param p_configuration_code       The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 */
procedure get_loc_lvl_label(
   p_loc_lvl_label            out varchar2,
   p_location_code            in  integer,
   p_specified_level_code     in  integer,
   p_parameter_code           in  integer,
   p_parameter_type_code      in  integer,
   p_duration_code            in  integer,
   p_attr_value               in  number  default null,
   p_attr_parameter_code      in  integer default null,
   p_attr_parameter_type_code in  integer default null,
   p_attr_duration_code       in  integer default null,
   p_configuration_code       in  integer default null);
/**
 * Deletes the configuration-specific label for a location level
 *
 * @param p_location_code            The location code for the location level
 * @param p_specified_level_code     The specified level code for the location level
 * @param p_parameter_code           The parameter code for the location level
 * @param p_parameter_type_code      The the parameter type code for the location level
 * @param p_duration_code            The duration code for the location level
 * @param p_attr_value               The value of the attribute for the location level, if any, in database units
 * @param p_attr_parameter_code      The parameter code of the attributes for the location lavel, if any
 * @param p_attr_parameter_type_code The parameter type code of the attributes for the location lavel, if any
 * @param p_attr_duration_code       The duration code of the attributes for the location lavel, if any
 * @param p_configuration_code       The configuration associated with the label. If NULL or not specified, the configuration will default to 'GENERAL/OTHER'
 */
procedure delete_loc_lvl_label(
   p_location_code            in integer,
   p_specified_level_code     in integer,
   p_parameter_code           in integer,
   p_parameter_type_code      in integer,
   p_duration_code            in integer,
   p_attr_value               in number  default null,
   p_attr_parameter_code      in integer default null,
   p_attr_parameter_type_code in integer default null,
   p_attr_duration_code       in integer default null,
   p_configuration_code       in integer default null);
/**
 * Sets the source for a location level
 *
 * @param p_loc_lvl_source    The source for the location level,
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_fail_if_exists    A flag (T/F) specifying whether to fail if a source already exists for the level
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 */
procedure set_loc_lvl_source(
   p_loc_lvl_source          in varchar2,
   p_location_level_id       in varchar2,
   p_attribute_value         in number   default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_fail_if_exists          in varchar2 default 'T',
   p_office_id               in varchar2 default null);
/**
 * Gets the source for a location level
 *
 * @param p_loc_lvl_source    The source for the location level,
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 */
procedure get_loc_lvl_source(
   p_loc_lvl_source          out varchar2,
   p_location_level_id       in  varchar2,
   p_attribute_value         in  number   default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_id            in  varchar2 default null,
   p_office_id               in  varchar2 default null);
/**
 * Gets the source for a location level
 *
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 *
 * @return The source for the location level,
 */
function get_loc_lvl_source_f(
   p_location_level_id       in varchar2,
   p_attribute_value         in number   default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_office_id               in varchar2 default null)
   return varchar2;
/**
 * Deletes the source for a location level
 *
 * @param p_location_level_id The location level identifier
 * @param p_attribute_value   The value of the attribute, if any
 * @param p_attribute_units   The unit for the attribute value, if any
 * @param p_attribute_id      The attribute identifier for the location level
 * @param p_office_id         The office that owns the location level. If NULL or not specified, the current session's default office is used.
 */
procedure delete_loc_lvl_source(
   p_location_level_id       in varchar2,
   p_attribute_value         in number   default null,
   p_attribute_units         in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_office_id               in varchar2 default null);
/**
 * Sets the source for a location level
 *
 * @param p_loc_lvl_source           The source for the location level,
 * @param p_location_code            The location code for the location level
 * @param p_specified_level_code     The specified level code for the location level
 * @param p_parameter_code           The parameter code for the location level
 * @param p_parameter_type_code      The the parameter type code for the location level
 * @param p_duration_code            The duration code for the location level
 * @param p_attr_value               The value of the attribute for the location level, if any, in database units
 * @param p_attr_parameter_code      The parameter code of the attributes for the location lavel, if any
 * @param p_attr_parameter_type_code The parameter type code of the attributes for the location lavel, if any
 * @param p_attr_duration_code       The duration code of the attributes for the location lavel, if any
 * @param p_fail_if_exists           A flag (T/F) specifying whether to fail if a source already exists for the level
 */
procedure set_loc_lvl_source(
   p_loc_lvl_source           in varchar2,
   p_location_code            in integer,
   p_specified_level_code     in integer,
   p_parameter_code           in integer,
   p_parameter_type_code      in integer,
   p_duration_code            in integer,
   p_attr_value               in number  default null,
   p_attr_parameter_code      in integer default null,
   p_attr_parameter_type_code in integer default null,
   p_attr_duration_code       in integer default null,
   p_fail_if_exists           in varchar2 default 'T');
/**
 * Gets the source for a location level
 *
 * @param p_loc_lvl_source           The source for the location level,
 * @param p_location_code            The location code for the location level
 * @param p_specified_level_code     The specified level code for the location level
 * @param p_parameter_code           The parameter code for the location level
 * @param p_parameter_type_code      The the parameter type code for the location level
 * @param p_duration_code            The duration code for the location level
 * @param p_attr_value               The value of the attribute for the location level, if any, in database units
 * @param p_attr_parameter_code      The parameter code of the attributes for the location lavel, if any
 * @param p_attr_parameter_type_code The parameter type code of the attributes for the location lavel, if any
 * @param p_attr_duration_code       The duration code of the attributes for the location lavel, if any
 */
procedure get_loc_lvl_source(
   p_loc_lvl_source           out varchar2,
   p_location_code            in  integer,
   p_specified_level_code     in  integer,
   p_parameter_code           in  integer,
   p_parameter_type_code      in  integer,
   p_duration_code            in  integer,
   p_attr_value               in  number  default null,
   p_attr_parameter_code      in  integer default null,
   p_attr_parameter_type_code in  integer default null,
   p_attr_duration_code       in  integer default null);
/**
 * Deletes the source for a location level
 *
 * @param p_location_code            The location code for the location level
 * @param p_specified_level_code     The specified level code for the location level
 * @param p_parameter_code           The parameter code for the location level
 * @param p_parameter_type_code      The the parameter type code for the location level
 * @param p_duration_code            The duration code for the location level
 * @param p_attr_value               The value of the attribute for the location level, if any, in database units
 * @param p_attr_parameter_code      The parameter code of the attributes for the location lavel, if any
 * @param p_attr_parameter_type_code The parameter type code of the attributes for the location lavel, if any
 * @param p_attr_duration_code       The duration code of the attributes for the location lavel, if any
 */
procedure delete_loc_lvl_source(
   p_location_code            in integer,
   p_specified_level_code     in integer,
   p_parameter_code           in integer,
   p_parameter_type_code      in integer,
   p_duration_code            in integer,
   p_attr_value               in number  default null,
   p_attr_parameter_code      in integer default null,
   p_attr_parameter_type_code in integer default null,
   p_attr_duration_code       in integer default null);
--------------------------------------------------------------------------------
/**
 * Catalogs location levels in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, SQL-style wildcards can also be used.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_cursor A cursor containing all matching basins.  The cursor contains
 * the following columns, and is sorted ascending by columns 1, 2, 3, 4, 6, & 8
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the location levels</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_level_id</td>
 *     <td class="descr">varchar2(390)</td>
 *     <td class="descr">The location level identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">attribute_id</td>
 *     <td class="descr">varchar2(83)</td>
 *     <td class="descr">The attribute identifier, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">attribute_value</td>
 *     <td class="descr">binary_double</td>
 *     <td class="descr">The attribue value, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">attribute_unit</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the attribute, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">effective_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The effective date of the location level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">expiration_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The expiration date of the location level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">level_type</td>
 *     <td class="descr">varchar2(11)</td>
 *     <td class="descr">Either 'NON-VIRTUAL' or 'VIRTUAL'</td>
 *   </tr>
 * </table>
 *
 * @param p_location_level_id_mask  The location level identifier pattern to match.
 *
 * @param p_attribute_id_mask  The attribute identifier pattern to match.
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above instead of sql-style wildcard characters for pattern
 * matching.
 *
 * @param p_timezone_id The time zone to retrieve dates/times in
 * @param p_unit_system The unit system ('EN' or 'SI') to retrieve values in
 * @param p_level_type  One or two characters that specify which types of location levels to catalog. If not specified, 'VN' will be used.
 * <ul>
 *   <li><b>N</b> catalog non-virtual (normal) location levels only
 *   <li><b>V</b> catalog virtual location levels only
 *   <li><b>NV</b> catalog both non-virtual and virtual location levels
 *   <li><b>VN</b> catalog both non-virtual and virtual location levels
 * </ul>
 */
procedure cat_location_levels(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2 default '*',
   p_attribute_id_mask      in  varchar2 default '*',
   p_office_id_mask         in  varchar2 default null,
   p_timezone_id            in  varchar2 default 'UTC',
   p_unit_system            in  varchar2 default 'SI',
   p_level_type             in  varchar2 default 'VN');
-- not documented
function get_loc_lvl_indicator_code(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null)
   return number;
-- not documented
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
   p_rate_interval               in dsinterval_unconstrained default null,
   p_description                 in varchar2               default null,
   p_fail_if_exists              in varchar2               default 'F',
   p_ignore_nulls_on_update      in varchar2               default 'T');
/**
 * Stores (inserts or updates) a location level indicator condition to the database
 *
 * @param p_loc_lvl_indicator_id        The location level indicator identifier
 * @param p_level_indicator_value       The value (1..5) of the indicator condition
 * @param p_expression                  The arithmetic expression for value comparisons. This can be an algebraic or RPN expression with the following variables
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Variable</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">V</td>
 *     <td class="descr">The value (specified explicitly or in a time series) to use in the comparison</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">L or L1</td>
 *     <td class="descr">The location level value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">L2</td>
 *     <td class="descr">The location level value of the referenced (secondary) location level</td>
 *   </tr>
 * </table>
 * @param p_comparison_operator_1       The comparison operator ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT') to use in comparing the result of the expression evalutaion with p_comparison_value_1
 * @param p_comparison_value_1          The first or only value to compare against the result of the expression evaluation via p_comparison_operator_1
 * @param p_comparison_unit_id          The unit of p_comparison_value_1 and p_comparison_value_2, if appilcable
 * @param p_connector                   The logical operator ('AND', 'OR') used to connect the first and second value comparisons, if two value comparisons are used.
 * @param p_comparison_operator_2       The comparison operator ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT') to use in comparing the result of the expression evalutaion with p_comparison_value_2, if two value comparisons are used
 * @param p_comparison_value_2          The second value to compare against the result of the expression evaluation via p_comparison_operator_2, if two value comparisons are used
 * @param p_rate_expression             The arithmetic expression for rate-of-change comparisons, if rate-of-change comparisons are used. This can be an algebraic or RPN expression with the following variables
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Variable</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">R</td>
 *     <td class="descr">The rate-of-change value to use in the comparison. Computed by the difference of two time series values divided by the interval</td>
 *   </tr>
 * </table>
 * @param p_rate_comparison_operator_1  The comparison operator ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT') to use in comparing the result of the expression evalutaion with p_rate_comparison_value_1, if rate comparisons are used
 * @param p_rate_comparison_value_1     The first or only value to compare against the result of the expression evaluation via p_rate_comparison_operator_1 if rate comparisons are used
 * @param p_rate_comparison_unit_id     The unit of p_rate_comparison_value_1 and p_rate_comparison_value_2, if appilcable
 * @param p_rate_connector              The logical operator ('AND', 'OR') used to connect the first and second rate comparisons, if two rate comparisons are used.
 * @param p_rate_comparison_operator_2  The comparison operator ('LT', 'LE', 'EQ', 'NE', 'GE', 'GT') to use in comparing the result of the expression evalutaion with p_rate_comparison_value_2, if two rate comparisons are used
 * @param p_rate_comparison_value_2     The second value to compare against the result of the expression evaluation via p_rate_comparison_operator_2, if two rate comparisons are used
 * @param p_rate_interval               The time interval to use in rate comparisons if rate comparisons are used, regardless of the time series interval
 * @param p_description                 A description of the location level indicator condition
 * @param p_attr_value                  The attribute value of the location indicator, if applicable
 * @param p_attr_units_id               The attribute unit if attribute value(s) is/are specified
 * @param p_attr_id                     The attribute identifier of the location level indidcator, if applicable
 * @param p_ref_specified_level_id      The specified level identifier of the referenced (secondary) location level, if any
 * @param p_ref_attr_value              The attribute value of the referenced location level, if any
 * @param p_fail_if_exists              A flag ('T' or 'F') that specifies whether the routine should fail if the location level indicator condition already exists
 * @param p_ignore_nulls_on_update      A flag ('T' or 'F') that specifies whether NULL parameters should be ignored when updating
 * @param p_office_id                   The office that owns the location level indicator. If not specified or NULL, the session user's default office is used.
 */
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
-- not documented
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
   p_minimum_duration         in  dsinterval_unconstrained default null,
   p_maximum_age              in  dsinterval_unconstrained default null,
   p_fail_if_exists           in  varchar2 default 'F',
   p_ignore_nulls_on_update   in  varchar2 default 'T');
/**
 * Stores (inserts or updates) a location level indicator to the database
 *
 * @param p_loc_lvl_indicator_id   The location level indicator identifier
 * @param p_attr_value             The attribute value, if applicable
 * @param p_attr_units_id          The attribute unit, if applicable
 * @param p_attribute_id           The attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced location level, if applicable
 * @param p_minimum_duration       The minumum amount of time that a condition must evalutate to TRUE for the indicator value to be considered to be set
 * @param p_maximum_age            The amount of time beyond which data is not considered current enough to evaluate indicator conditions
 * @param p_fail_if_exists         A flag ('T' or 'F') that specifies whether the routine should fail if the location level indicator already exists
 * @param p_ignore_nulls_on_update A flag ('T' or 'F') that specifies whether the routine should ignore NULL parameters when updating an existing location level indicator
 * @param p_office_id              The office that owns the location level indicator. If not specified or NULL, the session user's default office will be used
 */
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attribute_id           in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_minimum_duration       in  dsinterval_unconstrained default null,
   p_maximum_age            in  dsinterval_unconstrained default null,
   p_fail_if_exists         in  varchar2 default 'F',
   p_ignore_nulls_on_update in  varchar2 default 'T',
   p_office_id              in  varchar2 default null);
/**
 * Stores (inserts or updates) a location level indicator to the database
 *
 * @param p_loc_lvl_indicator  The location level indicator object to store
 */
procedure store_loc_lvl_indicator(
   p_loc_lvl_indicator in  loc_lvl_indicator_t);

/**
 * Stores (inserts or updates) a location level indicator to the database using simple types
 *
 * @param p_loc_lvl_indicator_id   The location level indicator identifier
 * @param p_attr_value             The attribute value, if applicable
 * @param p_attr_units_id          The attribute unit, if applicable
 * @param p_attribute_id           The attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced location level, if applicable
 * @param p_minimum_duration       The minumum amount of time that a condition must evalutate to TRUE for the indicator value to be considered to be set. Format is 'ddd hh:mm:ss'
 * @param p_maximum_age            The amount of time beyond which data is not considered current enough to evaluate indicator conditions. Format is 'ddd hh:mm:ss'
 * @param p_fail_if_exists         A flag ('T' or 'F') that specifies whether the routine should fail if the location level indicator already exists
 * @param p_ignore_nulls_on_update A flag ('T' or 'F') that specifies whether the routine should ignore NULL parameters when updating an existing location level indicator
 * @param p_office_id              The office that owns the location level indicator. If not specified or NULL, the session user's default office will be used
 */
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
-- not documented
procedure cat_loc_lvl_indicator_codes(
   p_cursor                     out sys_refcursor,
   p_loc_lvl_indicator_id_mask  in  varchar2 default null,  -- '%.%.%.%.%.%' if null
   p_attribute_id_mask          in  varchar2 default null,
   p_office_id_mask             in  varchar2 default null); -- user's office if null
-- not documented
function cat_loc_lvl_indicator_codes(
   p_loc_lvl_indicator_id_mask in  varchar2 default null, -- '%.%.%.%.%.%' if null
   p_attribute_id_mask         in  varchar2 default null,
   p_office_id_mask            in  varchar2 default null) -- user's office if null
   return sys_refcursor;
/**
 * Catalogs location level indicators in the database that match input parameters. Matching is
 * accomplished with glob-style wildcards, as shown below. SQL-style wildcards may also be used.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_level_cursor A cursor containing all matching location level indicators.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the location level indicator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The location identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">parameter_type_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The parameter type identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">duration_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The duration identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">specified_level_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The specified level identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">level_indicator_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The indicator identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">level_units_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The level value unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">attr_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The attribute parameter identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">attr_parameter_type_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The attribute parameter type identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">attr_duration_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The attribute duration identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">attr_units_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The attribute value unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">attr_value</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The attribute value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">minimum_duration</td>
 *     <td class="descr">interval day(3) to second(0)</td>
 *     <td class="descr">The minumum amount of time that a condition must evalutate to TRUE for the indicator value to be considered to be set</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">15</td>
 *     <td class="descr">maximum_age</td>
 *     <td class="descr">interval day(3) to second(0)</td>
 *     <td class="descr">The amount of time beyond which data is not considered current enough to evaluate indicator conditions</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">16</td>
 *     <td class="descr">ref_specified_level_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The specified level identifier of the referenced location level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">17</td>
 *     <td class="descr">ref_attr_value</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The attribute value of the referenced location level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">18</td>
 *     <td class="descr">conditions</td>
 *     <td class="descr">sys_refcursor</td>
 *     <td class="descr">
 *       The location level indicator condtions
 *       <p>
 *       <table class="descr"">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">level_indicator_value</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The indicator value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">expression</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The value expression</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">3</td>
 *           <td class="descr">comparison_operator_1</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The first value comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">4</td>
 *           <td class="descr">comparison_value_1</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The first value comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">5</td>
 *           <td class="descr">comparison_unit_id</td>
 *           <td class="descr">varchar2(16)</td>
 *           <td class="descr">The value comparison unit</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">6</td>
 *           <td class="descr">connector</td>
 *           <td class="descr">varchar2(3)</td>
 *           <td class="descr">The logical operator connecting the first and second value comparisons</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">7</td>
 *           <td class="descr">comparison_operator_2</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The second value comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">8</td>
 *           <td class="descr">comparison_value_2</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The second value comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">9</td>
 *           <td class="descr">rate_expression</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The rate-of-chane expression</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">10</td>
 *           <td class="descr">rate_comparison_operator_1</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The first rate-of-change comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">11</td>
 *           <td class="descr">rate_comparison_value_1</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The first rate-of-change comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">12</td>
 *           <td class="descr">rate_comparison_unit_id</td>
 *           <td class="descr">varchar2(16)</td>
 *           <td class="descr">The rate-of-change comparison unit</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">13</td>
 *           <td class="descr">rate_connector</td>
 *           <td class="descr">varchar2(3)</td>
 *           <td class="descr">The logical operator connecting the first and second rate comparisons</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">14</td>
 *           <td class="descr">rate_comparison_operator_2</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The second rate-of-change comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">15</td>
 *           <td class="descr">rate_comparison_value_2</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The second rate-of-change comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">16</td>
 *           <td class="descr">rate_interval</td>
 *           <td class="descr">interval day(3) to second(0)</td>
 *           <td class="descr">The time used to compute rate-of-change from the difference in successive values</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">17</td>
 *           <td class="descr">description</td>
 *           <td class="descr">varchar2(256)</td>
 *           <td class="descr">A description of the location level indicator condition</td>
 *         </tr>
 *       </table>
 *     </td>
 *   </tr>
 * </table>
 *
 * @param p_location_level_id_mask  The location level identifier pattern to match. If not specified or NULL, all location level identifiers will be matched
 *
 * @param p_attribute_id_mask  The attribute identifier pattern to match. If not specified or NULL, all attribute identifiers will be matched
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used
 *
 * @param p_unit_system The unit system ('EN' or 'SI') to retrive values in
 */
procedure cat_loc_lvl_indicator(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI');
/**
 * Catalogs location level indicators in the database that match input parameters, returning data in simple types. Matching is
 * accomplished with glob-style wildcards, as shown below. SQL-style wildcards may also be used.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_level_cursor A cursor containing all matching location level indicators.  The cursor contains
 * the following columns:
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">office_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The office that owns the location level indicator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The location identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">parameter_type_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The parameter type identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">duration_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The duration identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">specified_level_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The specified level identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">level_indicator_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The indicator identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">level_units_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The level value unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">attr_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The attribute parameter identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">attr_parameter_type_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The attribute parameter type identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">attr_duration_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The attribute duration identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">attr_units_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The attribute value unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">attr_value</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The attribute value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">minimum_duration</td>
 *     <td class="descr">varchar2(12)</td>
 *     <td class="descr">The minumum amount of time that a condition must evalutate to TRUE for the indicator value to be considered to be set. Format is 'ddd hh:mm:ss'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">15</td>
 *     <td class="descr">maximum_age</td>
 *     <td class="descr">varchar2(12)</td>
 *     <td class="descr">The amount of time beyond which data is not considered current enough to evaluate indicator conditions. Format is 'ddd hh:mm:ss'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">16</td>
 *     <td class="descr">ref_specified_level_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The specified level identifier of the referenced location level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">17</td>
 *     <td class="descr">ref_attribute_value</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The attribute value of the referenced location level</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">18</td>
 *     <td class="descr">conditions</td>
 *     <td class="descr">sys_refcursor</td>
 *     <td class="descr">
 *       The location level indicator condtions
 *       <p>
 *       <table class="descr"">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">indicator_value</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The indicator value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">expression</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The value expression</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">3</td>
 *           <td class="descr">comparison_operator_1</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The first value comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">4</td>
 *           <td class="descr">comparison_value_1</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The first value comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">5</td>
 *           <td class="descr">comparison_unit_id</td>
 *           <td class="descr">varchar2(16)</td>
 *           <td class="descr">The value comparison unit</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">6</td>
 *           <td class="descr">connector</td>
 *           <td class="descr">varchar2(3)</td>
 *           <td class="descr">The logical operator connecting the first and second value comparisons</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">7</td>
 *           <td class="descr">comparison_operator_2</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The second value comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">8</td>
 *           <td class="descr">comparison_value_2</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The second value comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">9</td>
 *           <td class="descr">rate_expression</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The rate-of-chane expression</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">10</td>
 *           <td class="descr">rate_comparison_operator_1</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The first rate-of-change comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">11</td>
 *           <td class="descr">rate_comparison_value_1</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The first rate-of-change comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">12</td>
 *           <td class="descr">rate_comparison_unit_id</td>
 *           <td class="descr">varchar2(16)</td>
 *           <td class="descr">The rate-of-change comparison unit</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">13</td>
 *           <td class="descr">rate_connector</td>
 *           <td class="descr">varchar2(3)</td>
 *           <td class="descr">The logical operator connecting the first and second rate comparisons</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">14</td>
 *           <td class="descr">rate_comparison_operator_2</td>
 *           <td class="descr">varchar2(2)</td>
 *           <td class="descr">The second rate-of-change comparison operator</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">15</td>
 *           <td class="descr">rate_comparison_value_2</td>
 *           <td class="descr">number</td>
 *           <td class="descr">The second rate-of-change comparison value</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">16</td>
 *           <td class="descr">rate_interval</td>
 *           <td class="descr">varchar2(12)</td>
 *           <td class="descr">The time used to compute rate-of-change from the difference in successive values. Format is 'ddd hh:mm:ss'</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">17</td>
 *           <td class="descr">description</td>
 *           <td class="descr">varchar2(256)</td>
 *           <td class="descr">A description of the location level indicator condition</td>
 *         </tr>
 *       </table>
 *     </td>
 *   </tr>
 * </table>
 *
 * @param p_location_level_id_mask  The location level identifier pattern to match. If not specified or NULL, all location level identifiers will be matched
 *
 * @param p_attribute_id_mask  The attribute identifier pattern to match. If not specified or NULL, all attribute identifiers will be matched
 *
 * @param p_office_id_mask  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used
 *
 * @param p_unit_system The unit system ('EN' or 'SI') to retrive values in
 */
procedure cat_loc_lvl_indicator2(
   p_cursor                 out sys_refcursor,
   p_location_level_id_mask in  varchar2,
   p_attribute_id_mask      in  varchar2 default null,
   p_office_id_mask         in  varchar2 default null,
   p_unit_system            in  varchar2 default 'SI');
/**
 * Retrieves a location level indicator and its associated conditions
 *
 * @param p_minimum_duration       The minumum amount of time that a condition must evalutate to TRUE for the indicator value to be considered to be set
 * @param p_maximum_age            The amount of time beyond which data is not considered current enough to evaluate indicator conditions
 * @param p_conditions             The location level indicator condtions
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">indicator_value</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The indicator value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">expression</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The value expression</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">comparison_operator_1</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The first value comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">comparison_value_1</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The first value comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">comparison_unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The value comparison unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">connector</td>
 *     <td class="descr">varchar2(3)</td>
 *     <td class="descr">The logical operator connecting the first and second value comparisons</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">comparison_operator_2</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The second value comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">comparison_value_2</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The second value comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">rate_expression</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The rate-of-chane expression</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">rate_comparison_operator_1</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The first rate-of-change comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">rate_comparison_value_1</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The first rate-of-change comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">rate_comparison_unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The rate-of-change comparison unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">rate_connector</td>
 *     <td class="descr">varchar2(3)</td>
 *     <td class="descr">The logical operator connecting the first and second rate comparisons</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">rate_comparison_operator_2</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The second rate-of-change comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">15</td>
 *     <td class="descr">rate_comparison_value_2</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The second rate-of-change comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">16</td>
 *     <td class="descr">rate_interval</td>
 *     <td class="descr">interval day(3) to second(0)</td>
 *     <td class="descr">The time used to compute rate-of-change from the difference in successive values</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">17</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">A description of the location level indicator condition</td>
 *   </tr>
 * </table>
 * @param p_loc_lvl_indicator_id   The location level indidicator identifier
 * @param p_level_units_id         The unit to retrieve values in
 * @param p_attr_value             The location level attribute value, if applicable
 * @param p_attr_units_id          The location level attribute unit, if applicable
 * @param p_attr_id                The location level attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced (secondary) location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced (secondary) location level, if applicable
 * @param p_office_id              The office that owns the location level indicator
 */
procedure retrieve_loc_lvl_indicator(
   p_minimum_duration       out dsinterval_unconstrained,
   p_maximum_age            out dsinterval_unconstrained,
   p_conditions             out sys_refcursor,
   p_loc_lvl_indicator_id   in  varchar2,
   p_level_units_id         in  varchar2 default null,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null);
/**
 * Retrieves a location level indicator and its associated conditions, in simple data types
 *
 * @param p_minimum_duration       The minumum amount of time that a condition must evalutate to TRUE for the indicator value to be considered to be set
 * @param p_maximum_age            The amount of time beyond which data is not considered current enough to evaluate indicator conditions
 * @param p_conditions             The location level indicator condtions. If not specified or NULL, the session user's default office is used
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">indicator_value</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The indicator value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">expression</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The value expression</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">comparison_operator_1</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The first value comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">comparison_value_1</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The first value comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">comparison_unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The value comparison unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">connector</td>
 *     <td class="descr">varchar2(3)</td>
 *     <td class="descr">The logical operator connecting the first and second value comparisons</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">comparison_operator_2</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The second value comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">comparison_value_2</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The second value comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">rate_expression</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The rate-of-chane expression</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">rate_comparison_operator_1</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The first rate-of-change comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">rate_comparison_value_1</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The first rate-of-change comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">rate_comparison_unit_id</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The rate-of-change comparison unit</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">rate_connector</td>
 *     <td class="descr">varchar2(3)</td>
 *     <td class="descr">The logical operator connecting the first and second rate comparisons</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">rate_comparison_operator_2</td>
 *     <td class="descr">varchar2(2)</td>
 *     <td class="descr">The second rate-of-change comparison operator</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">15</td>
 *     <td class="descr">rate_comparison_value_2</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The second rate-of-change comparison value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">16</td>
 *     <td class="descr">rate_interval</td>
 *     <td class="descr">varchar2(12)</td>
 *     <td class="descr">The time used to compute rate-of-change from the difference in successive values. Format is 'ddd hh:mm:ss'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">17</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">A description of the location level indicator condition</td>
 *   </tr>
 * </table>
 * @param p_loc_lvl_indicator_id   The location level indidicator identifier
 * @param p_level_units_id         The unit to retrieve values in
 * @param p_attr_value             The location level attribute value, if applicable
 * @param p_attr_units_id          The location level attribute unit, if applicable
 * @param p_attr_id                The location level attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced (secondary) location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced (secondary) location level, if applicable
 * @param p_office_id              The office that owns the location level indicator. If not specified or NULL, the session user's default office is used
 */
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
/**
 * Retrieves a location level indicator and its associated conditions
 *
 * @param p_loc_lvl_indicator_id   The location level indidicator identifier
 * @param p_level_units_id         The unit to retrieve values in
 * @param p_attr_value             The location level attribute value, if applicable
 * @param p_attr_units_id          The location level attribute unit, if applicable
 * @param p_attr_id                The location level attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced (secondary) location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced (secondary) location level, if applicable
 * @param p_office_id              The office that owns the location level indicator
 *
 * @return The specified location level indicator and its associated conditions
 */
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
/**
 * Deletes a location level indicator and its associated conditions from the database
 *
 * @param p_loc_lvl_indicator_id   The location level indidicator identifier
 * @param p_attr_value             The location level attribute value, if applicable
 * @param p_attr_units_id          The location level attribute unit, if applicable
 * @param p_attr_id                The location level attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced (secondary) location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced (secondary) location level, if applicable
 * @param p_office_id              The office that owns the location level indicator. If not specified or NULL, the session user's default office is used
 */
procedure delete_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null);
/**
 * Renames a location level indicator in the database
 *
 * @param p_loc_lvl_indicator_id   The complete location level indidicator identifier
 * @param p_new_indicator_id       The new level indicator identifier (last portion only, does not include location...specified level)
 * @param p_attr_value             The location level attribute value, if applicable
 * @param p_attr_units_id          The location level attribute unit, if applicable
 * @param p_attr_id                The location level attribute identifier, if applicable
 * @param p_ref_specified_level_id The specified level identifier of the referenced (secondary) location level, if applicable
 * @param p_ref_attr_value         The attribute value of the referenced (secondary) location level, if applicable
 * @param p_office_id              The office that owns the location level indicator. If not specified or NULL, the session user's default office is used
 */
procedure rename_loc_lvl_indicator(
   p_loc_lvl_indicator_id   in  varchar2,
   p_new_indicator_id       in  varchar2,
   p_attr_value             in  number   default null,
   p_attr_units_id          in  varchar2 default null,
   p_attr_id                in  varchar2 default null,
   p_ref_specified_level_id in  varchar2 default null,
   p_ref_attr_value         in  number   default null,
   p_office_id              in  varchar2 default null);
/**
 * Evaluates time series values in a location level indicator condition expression and return the results in a time series. If the specified (or default) condition
 * is a rate expression, the results of the rate expression evaluation will be returned. Otherwise, the results of the level expression will be returned.
 *
 * @param p_tsid                   The time series whose values are to be evaluated in the location level indicator condition expression
 * @param p_start_time             The start of the time window to retrieve data from p_tsid to evaluate
 * @param p_end_time               The end of the time window to retrieve data from p_tsid to evaluate
 * @param p_unit                   The unit of the values in the time series
 * @param p_specified_level_id     The specified level identifier to evaluate the indicator condition expression for (L or L1 in the level expression)
 * @param p_indicator_id           The location level indicator id to evaluate the condition expression for
 * @param p_attribute_id           The attribute id of the location level to evaluate the indicator condition expression for. If unspecifed or NULL, no attribute will be used.
 * @param p_attribute_value        The attribute value of the location level to evaluate the indicator condition expression for. May be NULL if no attribute is used.
 * @param p_attribute_unit         The attribute unit of the location level to evaluate the indicator condition expression for. May be NULL if no attribute is used.
 * @param p_ref_specified_level_id The referenced specified level (L2 in the level expression), if any
 * @param p_ref_attribute_value    The attribute value of the referenced specified level (L2 in the level expression), if any
 * @param p_time_zone              The time zone of p_start_time, p_end_time, and the retrieved data.  If not specified or NULL, the location's local time zone is used.
 * @param p_condition_number       The condition number whose expression is to be evaluated.  If not specified, the first condition (number 1) will be used.
 * @param p_office_id              The office that owns the time series, location level, and location level indicator
 *
 * @return The results of the evaluation expressions, one element for every element in the input time series.
 */
function eval_level_indicator_expr(
   p_tsid                   in varchar2,
   p_start_time             in date,
   p_end_time               in date,
   p_unit                   in varchar2,
   p_specified_level_id     in varchar2,
   p_indicator_id           in varchar2,
   p_attribute_id           in varchar2      default null,
   p_attribute_value        in binary_double default null,
   p_attribute_unit         in varchar2      default null,
   p_ref_specified_level_id in varchar2      default null,
   p_ref_attribute_value    in number        default null,
   p_time_zone              in varchar2      default null,
   p_condition_number       in integer       default 1,
   p_office_id              in varchar2      default null)
   return ztsv_array;
/**
 * Evaluates time series values in a location level indicator condition expression and return the results in a time series. If the specified (or default) condition
 * is a rate expression, the results of the rate expression evaluation will be returned. Otherwise, the results of the level expression will be returned.
 *
 * @param p_ts                     The time series whose values are to be evaluated in the location level indicator condition expression
 * @param p_unit                   The unit of the values in the time series
 * @param p_loc_lvl_indicator_id   The location level indicator id to evaluate the condition expression for
 * @param p_attribute_id           The attribute id of the location level to evaluate the indicator condition expression for. If unspecifed or NULL, no attribute will be used.
 * @param p_attribute_value        The attribute value of the location level to evaluate the indicator condition expression for. May be NULL if no attribute is used.
 * @param p_attribute_unit         The attribute unit of the location level to evaluate the indicator condition expression for. May be NULL if no attribute is used.
 * @param p_ref_specified_level_id The referenced specified level (L2 in the level expression), if any
 * @param p_ref_attribute_value    The attribute value of the referenced specified level (L2 in the level expression), if any
 * @param p_time_zone              The time zone of p_start_time, p_end_time, and the retrieved data.  If not specified or NULL, the location's local time zone is used.
 * @param p_condition_number       The condition number whose expression is to be evaluated.  If not specified, the first condition (number 1) will be used.
 * @param p_office_id              The office that owns the time series, location level, and location level indicator
 *
 * @return The results of the evaluation expressions, one element for every element in the input time series.
 */
function eval_level_indicator_expr(
   p_ts                     in ztsv_array,
   p_unit                   in varchar2,
   p_loc_lvl_indicator_id   in varchar2,
   p_attribute_id           in varchar2      default null,
   p_attribute_value        in binary_double default null,
   p_attribute_unit         in varchar2      default null,
   p_ref_specified_level_id in varchar2      default null,
   p_ref_attribute_value    in number        default null,
   p_time_zone              in varchar2      default null,
   p_condition_number       in integer       default 1,
   p_office_id              in varchar2      default null)
   return ztsv_array;
/**
 * Retreieves the values for all Location level indicator conditions that are set at
 * p_eval_time and that match the input parameters.  Each indicator may have multiple condions set. Matching is
 * accomplished with glob-style wildcards, as shown below. SQL-style wildcards may also be used.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_cursor               The retrieved location level indicator values
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">indicator_id</td>
 *     <td class="descr">varchar2(431)</td>
 *     <td class="descr">The location level indicator identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">attribute_id</td>
 *     <td class="descr">varchar2(83)</td>
 *     <td class="descr">The location level attribute identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">attribute_value</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The location level attribute</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">attribute_units</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the location level attribute value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">indicator_values</td>
 *     <td class="descr">number_tab_t</td>
 *     <td class="descr">The location level indicator condition values that are set for the specified parameters</td>
 *   </tr>
 * </table>
 * @param p_tsid                 A time series identifier. p_cursor will only include conditions for location levels that have the same location, parameter, and parameter type
 * @param p_eval_time            The evaluation time.  If not specified or NULL, the current time is used
 * @param p_time_zone            The time zone of p_eval_time. If not specified or NULL, UTC is used
 * @param p_specified_level_mask The specified level identifier pattern to match. If not specified or NULL, all specified level identifiers are matched
 * @param p_indicator_id_mask    The location level indicator identifier pattern to match. If not specified or NULL, all location level indicator identifiers are matched
 * @param p_unit_system          The unit system ('EN' or 'SI') to retrieve values in. If not specified or NULL, SI is used
 * @param p_office_id            The office that owns the time series and location level indicators. If not specified or NULL, the session user's default office is used
 */
procedure get_level_indicator_values(
   p_cursor               out sys_refcursor,
   p_tsid                 in  varchar2,
   p_eval_time            in  date     default null,
   p_time_zone            in  varchar2 default null,
   p_specified_level_mask in  varchar2 default null,
   p_indicator_id_mask    in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_office_id            in  varchar2 default null);
/**
 * Retrieves a time series of the maximum Condition value that is set for each location
 * level indicator that matches the input parameters.  Each time series has the same
 * times as the time series defined by p_tsid, p_start_time and p_end_time.  Each date_time
 * in the time series is in the specified time zone. Matching is
 * accomplished with glob-style wildcards, as shown below. SQL-style wildcards may also be used.
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Wildcard</th>
 *     <th class="descr">Meaning</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">*</td>
 *     <td class="descr">Match zero or more characters</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">?</td>
 *     <td class="descr">Match a single character</td>
 *   </tr>
 * </table>
 *
 * @param p_cursor               The retrieved location level indicator values
 * <p>
 * <table class="descr"">
 *   <tr>
 *     <th class="descr">Column No.</th>
 *     <th class="descr">Column Name</th>
 *     <th class="descr">Data Type</th>
 *     <th class="descr">Contents</th>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">1</td>
 *     <td class="descr">indicator_id</td>
 *     <td class="descr">varchar2(431)</td>
 *     <td class="descr">The location level indicator identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">attribute_id</td>
 *     <td class="descr">varchar2(83)</td>
 *     <td class="descr">The location level attribute identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">attribute_value</td>
 *     <td class="descr">number</td>
 *     <td class="descr">The location level attribute</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">attribute_units</td>
 *     <td class="descr">varchar2(16)</td>
 *     <td class="descr">The unit of the location level attribute value</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">indicator_values</td>
 *     <td class="descr">ztsv_array</td>
 *     <td class="descr">The maximum location level indicator condition values that are set for the specified parameters at each time of the time series in time window. The times are in the specified time zone.</td>
 *   </tr>
 * </table>
 * @param p_tsid                 A time series identifier. p_cursor will only include conditions for location levels that have the same location, parameter, and parameter type
 * @param p_start_time           The start of the time window
 * @param p_end_time             The end of the time window
 * @param p_time_zone            The time zone of p_eval_time. If not specified or NULL, UTC is used
 * @param p_specified_level_mask The specified level identifier pattern to match. If not specified or NULL, all specified level identifiers are matched
 * @param p_indicator_id_mask    The location level indicator identifier pattern to match. If not specified or NULL, all location level indicator identifiers are matched
 * @param p_unit_system          The unit system ('EN' or 'SI') to retrieve values in. If not specified or NULL, SI is used
 * @param p_office_id            The office that owns the time series and location level indicators. If not specified or NULL, the session user's default office is used
 */
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

/**
 * Retreives location level values as time series in a number of formats for a combination time window, timezone, formats, and vertical datums
 *
 * @param p_results        The location level values as time series, in the specified time zones, formats, and vertical datums
 * @param p_date_time      The time that the routine was called, in UTC
 * @param p_query_time     The time the routine took to retrieve the specified location levels from the database
 * @param p_format_time    The time the routine took to format the results into the specified format, in milliseconds
 * @param p_count          The number of location levels retrieved by the routine
 * @param p_names          The names (location levels identifers) of the location levels to retrieve.  Multiple location levels can be specified by
 *                         <or><li>specifying multiple location levels ids separated by the <b>'|'</b> character (multiple name positions)</li>
 *                         <li>specifying a location levels spec id with wildcard (<b>'*'</b> and/or <b>'?'</b> characters) (single name position)</li>
 *                         <li>a combination of 1 and 2 (multiple name positions with one or more positions matching possibly more than one location levels)</li></ol>
 *                         If unspecified or NULL, a listing of location levels identifiers with data in the specified or default time window will be returned.
 * @param p_format         The format to retrieve the location levels in. Valid formats are <ul><li>TAB</li><li>CSV</li><li>XML</li><li>JSON</li></ul>
 *                         If the format is unspecified or NULL, the TAB format will be used.
 * @param p_units          The units to return the location levels in.  Valid units are <ul><li>EN</li><li>SI</li><li>actual unit of parameter (e.g. ft, cfs)</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_units variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_units variable has fewer positions than the p_name variable, the last unit position is used for all
 * @param p_datums         The vertical datums to return the units in.  Valid datums are <ul><li>NATIVE</li><li>NGVD29</li><li>NAVD88</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_datums variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_datums variable has fewer positions than the p_name variable, the last datum position is used for all
 *                         remaning names. If the datums are unspecified or NULL, the NATIVE veritcal datum will be used for all location levels.
 * @param p_start          The start of the time window to retrieve location levels for.  No location levels values earlier this time will be retrieved.
 *                         If unspecified or NULL, a value of 24 hours prior to the specified or default end of the time window will be used. for the start of the time window
 * @param p_end            The end of the time window to retrieve location levels for.  No location levels values later this time will be retrieved.
 *                         If unspecified or NULL, the current time will be used for the end of the time window.
 * @param p_timezone       The time zone to retrieve the location levels in. The p_start and p_end parameters - if used - are also interpreted according to this time zone.
 *                         If unspecified or NULL, the UTC time zone is used.
 * @param p_office_id      The office to retrieve location levels for.  If unspecified or NULL, location levels for all offices in the database that match the other criteria will be retrieved.
 */
procedure retrieve_location_levels(
   p_results        out clob,
   p_date_time      out date,
   p_query_time     out integer,
   p_format_time    out integer,
   p_count          out integer,
   p_names          in  varchar2 default null,
   p_format         in  varchar2 default null,
   p_units          in  varchar2 default null,
   p_datums         in  varchar2 default null,
   p_start          in  varchar2 default null,
   p_end            in  varchar2 default null,
   p_timezone       in  varchar2 default null,
   p_office_id      in  varchar2 default null);
/**
 * Retreives location level values as time series in a number of formats for a combination time window, timezone, formats, and vertical datums
 *
 * @param p_names          The names (location levels identifers) of the location levels to retrieve.  Multiple location levels can be specified by
 *                         <or><li>specifying multiple location levels ids separated by the <b>'|'</b> character (multiple name positions)</li>
 *                         <li>specifying a location levels spec id with wildcard (<b>'*'</b> and/or <b>'?'</b> characters) (single name position)</li>
 *                         <li>a combination of 1 and 2 (multiple name positions with one or more positions matching possibly more than one location levels)</li></ol>
 *                         If unspecified or NULL, a listing of location levels identifiers with data in the specified or default time window will be returned.
 * @param p_format         The format to retrieve the location levels in. Valid formats are <ul><li>TAB</li><li>CSV</li><li>XML</li><li>JSON</li></ul>
 *                         If the format is unspecified or NULL, the TAB format will be used.
 * @param p_units          The units to return the location levels in.  Valid units are <ul><li>EN</li><li>SI</li><li>actual unit of parameter (e.g. ft, cfs)</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_units variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_units variable has fewer positions than the p_name variable, the last unit position is used for all
 *                         remaning names. If the units are unspecified or NULL, the NATIVE units will be used for all time series.
 * @param p_datums         The vertical datums to return the units in.  Valid datums are <ul><li>NATIVE</li><li>NGVD29</li><li>NAVD88</li></ul> If the p_names variable (q.v.) has more
 *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_datums variable may also have multiple positions separated by the
 *                         <b>'|',</b> charcter. If the p_datums variable has fewer positions than the p_name variable, the last datum position is used for all
 *                         remaning names. If the datums are unspecified or NULL, the NATIVE veritcal datum will be used for all location levels.
 * @param p_start          The start of the time window to retrieve location levels for.  No location levels values earlier this time will be retrieved.
 *                         If unspecified or NULL, a value of 24 hours prior to the specified or default end of the time window will be used. for the start of the time window
 * @param p_end            The end of the time window to retrieve location levels for.  No location levels values later this time will be retrieved.
 *                         If unspecified or NULL, the current time will be used for the end of the time window.
 * @param p_timezone       The time zone to retrieve the location levels in. The p_start and p_end parameters - if used - are also interpreted according to this time zone.
 *                         If unspecified or NULL, the UTC time zone is used.
 * @param p_office_id      The office to retrieve location levels for.  If unspecified or NULL, location levels for all offices in the database that match the other criteria will be retrieved.
 *
 * @return                 The location level values as time series, in the specified time zones, formats, and vertical datums
 */
function retrieve_location_levels_f(
   p_names       in  varchar2,
   p_format      in  varchar2,
   p_units       in  varchar2 default null,
   p_datums      in  varchar2 default null,
   p_start       in  varchar2 default null,
   p_end         in  varchar2 default null,
   p_timezone    in  varchar2 default null,
   p_office_id   in  varchar2 default null)
   return clob;
/*
 * Virtual location level routines
 */
procedure process_constituents(
   p_values                  out nocopy ztsv_array,         -- generated values
   p_unit                    in varchar2,                   -- specified output unit
   p_connections_str         in varchar2,                   -- comma-separated list of constituent connections
   p_constituent_abbrs       in str_tab_t,                  -- table of constituent abbreviations
   p_constituent_types       in str_tab_t,                  -- table of consituent types
   p_constituent_names       in str_tab_t,                  -- table of constituent names (type-dependent)
   p_constituent_attr_ids    in str_tab_t    default null,  -- table of attribute identifiers for location level constituents
   p_constituent_attr_values in number_tab_t default null,  -- table of attribute values for location level constituents
   p_constituent_attr_units  in str_tab_t    default null,  -- table of attribute units for location level constituents
   p_start_time              in date         default null,  -- start of the time window
   p_end_time                in date         default null,  -- end of the time window
   p_time_zone               in varchar2     default null,  -- time zone of date/times
   p_office                  in varchar2     default null); -- office identifier of owning office

procedure process_constituents(
   p_values                  out nocopy ztsv_array,            -- generated values
   p_unit                    in varchar2,                      -- specified output unit
   p_connections_str         in varchar2,                      -- comma-separated list of constituent connections
   p_constituent_abbrs       in str_tab_t,                     -- table of constituent abbreviations
   p_constituent_types       in str_tab_t,                     -- table of consituent types
   p_constituent_names       in str_tab_t,                     -- table of constituent names (type-dependent)
   p_constituent_attr_ids    in str_tab_t       default null,  -- table of attribute identifiers for location level constituents
   p_constituent_attr_values in number_tab_t    default null,  -- table of attribute values for location level constituents
   p_constituent_attr_units  in str_tab_t       default null,  -- table of attribute units for location level constituents
   p_date_times              in date_table_type default null,  -- table of date/times to generate values for
   p_time_zone               in varchar2        default null,  -- time zone of date/times
   p_office                  in varchar2        default null);  -- office identifier of owning office

procedure validate_constituents(
   p_connections_str         in varchar2,                   -- comma-separated list of constituent connections
   p_constituent_abbrs       in str_tab_t,                  -- table of constituent abbreviations
   p_constituent_types       in str_tab_t,                  -- table of consituent types
   p_constituent_names       in str_tab_t,                  -- table of constituent names (type-dependent)
   p_constituent_attr_ids    in str_tab_t    default null,  -- table of attribute identifiers for location level constituents
   p_constituent_attr_values in number_tab_t default null,  -- table of attribute values for location level constituents
   p_constituent_attr_units  in str_tab_t    default null,  -- table of attribute units for location level constituents
   p_office                  in varchar2     default null);  -- office identifier of owning office

function get_virtual_loc_lvl_code(
   p_location_level_id in varchar2,
   p_effective_date    in date,
   p_timezone_id       in varchar2,
   p_attribute_id      in varchar2 default null,
   p_attribute_value   in number   default null,
   p_attribute_unit    in varchar2 default null,
   p_match_time        in varchar2 default 'F',
   p_office_id         in varchar2 default null)
   return integer;
/**
 * Stores (inserts or updates) a virtual location level to the database.
 * <p>
 * Each virtual location level is computed from a set of CONSTITUENTS, each of which is either an INPUT or a TRANSFORM as shown below.
 * <table border="1" cellpadding="4" style="border-collapse:collapse">
 *   <tr style="font-weight:bold"><td>Category</td><td>Type</td><td>Name</td><td>Example</td></tr>
 *   <tr><td rowspan="2">INPUT</td><td>LOCATION_LEVEL</td><td>Location Level ID</td><td>Freemont.Elev.Inst.0.Top of Flood</td></tr>
 *   <tr><td>TIME_SERIES</td><td>Time Series ID</td><td>Freemont.Elev.Inst.0.0.rev-ccp</td></tr>
 *   <tr><td rowspan="2">TRANSFORM</td><td>RATING</td><td>Rating Specification</td><td>Freemont.Elev;Stor.Linear.Standard.Step</td></tr>
 *   <tr><td>FORMULA</td><td>Mathematical Expression with Units</td><td>(ARG1 + ARG2) / 2 {ac-ft,ac-ft;ac-ft}</td></tr>
 * </table>
 * <p>
 * The constituent name for a formula constituent must include the units for each input (e.g. ARGn) separated by a comma, followed by a
 * semicolon and the unit of the the result of the formula. This string must be surrounded by curly braces {}.
 * <p>
 * Each virtual location levels must have at least one INPUT and one TRANSFORM, although it may have multiple of each. The values of a virtual
 * location level is always the output of a TRANSFORM.
 * <p>
 * Each constituent has a TYPE and a NAME - as described above - and an ABBREVIATION that is used in the connection string. The rules for
 * constituent abbreviations are:
 * <ul>
 *   <li>The first character of the abbreviation must be the same as the first character of the contituent type (L, T, R, or F)</li>
 *   <li>The abbreviation can be no more that four characters in length</li>
 * </ul>
 * Normally, the abbreviation of the first specified location level constituent is L1, that of the seconds specified location level is L2, etc....
 * Likewise for time seires (T1, T2, ...), ratings (R1, R2, ...), and formula (F1, F2, ...) constituents. However, this convention is not
 * required.
 * <p>
 * Each constituent has one or more connection points which connect it to one or more of the other constituents. Input constituents have
 * only one connection point, which is named the same as the constiuent's abbreviation. Transform constituents have a minimum of two
 * connection points: they have one or more independent (normally input) connection points and one dependent (normally output). These connection
 * points are named by appending I1, I2, etc... to the constituent abbreviation for independent connection points and appending D to the
 * abbreviation for dependent connection points (e.g, R1I1, F2I1, R2D, etc...). Only when the transform constituent is a reversible rating
 * (monotonic single indpependent paramter rating) can the dependent connection point be an input and the independent connection point
 * be an output.
 * <p>
 * Each virtual location level has a CONNECTION STRING that specifies how the constiuents are tied together. The connection string specifies
 * one or more sets of connected connection points by placing them on either side of an equals sign character ('='). If more than one connection
 * is required, the sets of connected connection points are separated by the comma character (','). The connections string must connect every
 * input connection point to the independent connection point of one or more transforms and must leave exactly one transform dependent connection
 * point unconnectd. Complex virtual location levels may connect input connection points or transform dependent connection points to more than one
 * transform independent connection points. Some example connection strings are:
 * <table border="1" cellpadding="4" style="border-collapse:collapse">
 *   <tr style="font-weight:bold"><td>Type</td><td>Name</td><td>Abbreviation</td><td>Connection string</td><td>Result</td><td>Description</td></tr>
 *   <tr><td>LOCATION_LEVEL</td><td>Freemont.Elev.Inst.0.Top of Flood</td><td>L1</td><td rowspan="2">L1=R1I1</td><td rowspan="2">R1D</td><td rowspan="2">Storage location level rated from elevation location level</td></tr>
 *   <tr><td>RATING</td><td>Freemont.Elev;Stor.Linear.Step</td><td>R1</td></tr>
 *   <tr><td>TIME_SERIES</td><td>Freemont.Elev-UpperEnd.Ave.6Hour.0.Computed-ccp</td><td>T1</td><td rowspan="3">T1=F1I1,T2=F1I2</td><td rowspan="3">F1D</td><td rowspan="3">Average elevattion location level</td></tr>
 *   <tr><td>TIME_SERIES</td><td>Freemont.Elev-LowerEnd.Ave.6Hour.0.Computed-ccp</td><td>T2</td></tr>
 *   <tr><td>FORMULA</td><td>(ARG1 + ARG2) / 2 {ft,ft;ft}</td><td>F1</td></tr>
 *   <tr><td>LOCATION_LEVEL</td><td>Freemont.Elev.Inst.0.Top of Flood</td><td>L1</td><td rowspan="2">L1=F1I1</td><td rowspan="2">F1D</td><td rowspan="2">Elev location level limited to max elevation</td></tr>
 *   <tr><td>FORMULA</td><td>MIN($I1, 1070.35)</td><td>F1</td></tr>
 * </table>
 * <p>
 * Formulas may be specified in infix (algebraic) or postfix (RPN) notation. Input arguments by be specified as ARG1, ARG2, etc... or
 * $I1, $I2, etc.... Negated arguments (e.g., -ARG1, -$I1) may be specified. All forumla arguments, operators, and function names must be
 * separated by spaces except for parentheses used in infix notation. The operators, functions, and constants available for use in
 * formulas is shown below.
 * <table border="1" cellpadding="4" style="border-collapse:collapse">
 *   <tr style="font-weight:bold"><td colspan="3">Unary Operator</td></tr>
 *   <tr><td>-</td><td>negation</td><td>prepend to argument without spaces, can be used only on numbers and arguments (not expressions)</td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Binary Operators</td></tr>
 *   <tr><td>+</td><td>addition</td><td></td></tr>
 *   <tr><td>-</td><td>subtraction</td><td></td></tr>
 *   <tr><td>*</td><td>multiplication</td><td></td></tr>
 *   <tr><td>/</td><td>division</td><td></td></tr>
 *   <tr><td>//</td><td>integer division</td><td>like Python operator</td></tr>
 *   <tr><td>%</td><td>modulus</td><td>like Python math.fmod, not Python %</td></tr>
 *   <tr><td>^</td><td>exponentiation</td><td></td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Unary Functions</td></tr>
 *   <tr><td>ABS</td><td>absolute value</td><td></td></tr>
 *   <tr><td>ACOS</td><td>arccosine</td><td></td></tr>
 *   <tr><td>ASIN</td><td>arcsine</td><td></td></tr>
 *   <tr><td>ATAN</td><td>arctangent</td><td></td></tr>
 *   <tr><td>CEIL</td><td>ceiling</td><td>smallest integer value &gt;= argument</td></tr>
 *   <tr><td>COS</td><td>cosine</td><td></td></tr>
 *   <tr><td>EXP</td><td>exponential</td><td><em>e</em> raised to power of argument</td></tr>
 *   <tr><td>FLOOR</td><td>floor</td><td>largest integer value &lt;= argument</td></tr>
 *   <tr><td>INV</td><td>inverse</td><td>1 / argument</td></tr>
 *   <tr><td>LN</td><td>natural logarithm</td><td></td></tr>
 *   <tr><td>LOG</td><td>base 10 logarithm</td><td></td></tr>
 *   <tr><td>NEG</td><td>negation</td><td></td></tr>
 *   <tr><td>ROUND</td><td>round to nearest integer</td><td></td></tr>
 *   <tr><td>SIGN</td><td>signum</td><td>sign of argument: -1 or +1</td></tr>
 *   <tr><td>SIN</td><td>sine</td><td></td></tr>
 *   <tr><td>SQRT</td><td>square root</td><td></td></tr>
 *   <tr><td>TAN</td><td>tangent</td><td></td></tr>
 *   <tr><td>TRUNC</td><td>truncate to integer portion</td><td></td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Binary Functions</td></tr>
 *   <tr><td>MAX</td><td>maximum of two arguments</td><td></td></tr>
 *   <tr><td>MIN</td><td>minimum of two arguments</td><td></td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Constants</td></tr>
 *   <tr><td>E</td><td style="font-style:italic">e</td><td>Euler's number</td></tr>
 *   <tr><td>PI</td><td>&pi;</td><td>ratio of a cirlce's circumference to its diameter</td></tr>
 * </table>
 * @param p_location_level_id       The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_constituents            The constituents as a table of tables. Each row of the outer table specifies a single constituent and each
 *                                  row of the inner table specifies the abbreviation, type, name, and optionally the attribute id, value, and unit
 *                                  for the constituent, as described above.
 * @param p_constituent_connections The connection string for the constituents
 * @param p_level_comment           A comment about the location level
 * @param p_attribute_id            The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value         The value of the attribute, if applicable
 * @param p_attribute_unit          he unit of the attribute, if applicable
 * @param p_attribute_comment       A comment about the attribute, if applicable
 * @param p_effective_date          The effective date for the location level. Applies from this time forward
 * @param p_expiration_date         The date/time that the location level expires
 * @param p_timezone_id             The time zone of p_effective_date and p_interval_origin, if applicable
 * @param p_fail_if_exists          A flag ('T' or 'F') that specifies whether the routine should fail if the location level already exists in the database
 * @param p_ignore_nulls            A flag ('T' or 'F') that specifies whether NULL parameters should be ignored when updating
 * @param p_office_id               The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the location level already exists in the database
 */
procedure store_virtual_location_level(
   p_location_level_id       in varchar2,
   p_constituents            in str_tab_tab_t,
   p_constituent_connections in varchar2 default null,
   p_level_comment           in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_attribute_value         in number   default null,
   p_attribute_unit          in varchar2 default null,
   p_attribute_comment       in varchar2 default null,
   p_effective_date          in date     default null,
   p_expiration_date         in date     default null,
   p_timezone_id             in varchar2 default 'UTC',
   p_fail_if_exists          in varchar2 default 'T',
   p_ignore_nulls            in varchar2 default 'T',
   p_office_id               in varchar2 default null);
/**
 * Stores (inserts or updates) a virtual location level to the database.
 * <p>
 * Each virtual location level is computed from a set of CONSTITUENTS, each of which is either an INPUT or a TRANSFORM as shown below.
 * <table border="1" cellpadding="4" style="border-collapse:collapse">
 *   <tr style="font-weight:bold"><td>Category</td><td>Type</td><td>Name</td><td>Example</td></tr>
 *   <tr><td rowspan="2">INPUT</td><td>LOCATION_LEVEL</td><td>Location Level ID</td><td>Freemont.Elev.Inst.0.Top of Flood</td></tr>
 *   <tr><td>TIME_SERIES</td><td>Time Series ID</td><td>Freemont.Elev.Inst.0.0.rev-ccp</td></tr>
 *   <tr><td rowspan="2">TRANSFORM</td><td>RATING</td><td>Rating Specification</td><td>Freemont.Elev;Stor.Linear.Standard.Step</td></tr>
 *   <tr><td>FORMULA</td><td>Mathematical Expression with Units</td><td>(ARG1 + ARG2) / 2 {ac-ft,ac-ft;ac-ft}</td></tr>
 * </table>
 * <p>
 * The constituent name for a formula constituent must include the units for each input (e.g. ARGn) separated by a comma, followed by a
 * semicolon and the unit of the the result of the formula. This string must be surrounded by curly braces {}.
 * <p>
 * Each virtual location levels must have at least one INPUT and one TRANSFORM, although it may have multiple of each. The values of a virtual
 * location level is always the output of a TRANSFORM.
 * <p>
 * Each constituent has a TYPE and a NAME - as described above - and an ABBREVIATION that is used in the connection string. The rules for
 * constituent abbreviations are:
 * <ul>
 *   <li>The first character of the abbreviation must be the same as the first character of the contituent type (L, T, R, or F)</li>
 *   <li>The abbreviation can be no more that four characters in length</li>
 * </ul>
 * Normally, the abbreviation of the first specified location level constituent is L1, that of the seconds specified location level is L2, etc....
 * Likewise for time seires (T1, T2, ...), ratings (R1, R2, ...), and formula (F1, F2, ...) constituents. However, this convention is not
 * required.
 * <p>
 * Each constituent has one or more connection points which connect it to one or more of the other constituents. Input constituents have
 * only one connection point, which is named the same as the constiuent's abbreviation. Transform constituents have a minimum of two
 * connection points: they have one or more independent (normally input) connection points and one dependent (normally output). These connection
 * points are named by appending I1, I2, etc... to the constituent abbreviation for independent connection points and appending D to the
 * abbreviation for dependent connection points (e.g, R1I1, F2I1, R2D, etc...). Only when the transform constituent is a reversible rating
 * (monotonic single indpependent paramter rating) can the dependent connection point be an input and the independent connection point
 * be an output.
 * <p>
 * Each virtual location level has a CONNECTION STRING that specifies how the constiuents are tied together. The connection string specifies
 * one or more sets of connected connection points by placing them on either side of an equals sign character ('='). If more than one connection
 * is required, the sets of connected connection points are separated by the comma character (','). The connections string must connect every
 * input connection point to the independent connection point of one or more transforms and must leave exactly one transform dependent connection
 * point unconnectd. Complex virtual location levels may connect input connection points or transform dependent connection points to more than one
 * transform independent connection points. Some example connection strings are:
 * <table border="1" cellpadding="4" style="border-collapse:collapse">
 *   <tr style="font-weight:bold"><td>Type</td><td>Name</td><td>Abbreviation</td><td>Connection string</td><td>Result</td><td>Description</td></tr>
 *   <tr><td>LOCATION_LEVEL</td><td>Freemont.Elev.Inst.0.Top of Flood</td><td>L1</td><td rowspan="2">L1=R1I1</td><td rowspan="2">R1D</td><td rowspan="2">Storage location level rated from elevation location level</td></tr>
 *   <tr><td>RATING</td><td>Freemont.Elev;Stor.Linear.Step</td><td>R1</td></tr>
 *   <tr><td>TIME_SERIES</td><td>Freemont.Elev-UpperEnd.Ave.6Hour.0.Computed-ccp</td><td>T1</td><td rowspan="3">T1=F1I1,T2=F1I2</td><td rowspan="3">F1D</td><td rowspan="3">Average elevattion location level</td></tr>
 *   <tr><td>TIME_SERIES</td><td>Freemont.Elev-LowerEnd.Ave.6Hour.0.Computed-ccp</td><td>T2</td></tr>
 *   <tr><td>FORMULA</td><td>(ARG1 + ARG2) / 2 {ft,ft;ft}</td><td>F1</td></tr>
 *   <tr><td>LOCATION_LEVEL</td><td>Freemont.Elev.Inst.0.Top of Flood</td><td>L1</td><td rowspan="2">L1=F1I1</td><td rowspan="2">F1D</td><td rowspan="2">Elev location level limited to max elevation</td></tr>
 *   <tr><td>FORMULA</td><td>MIN($I1, 1070.35)</td><td>F1</td></tr>
 * </table>
 * <p>
 * Formulas may be specified in infix (algebraic) or postfix (RPN) notation. Input arguments by be specified as ARG1, ARG2, etc... or
 * $I1, $I2, etc.... Negated arguments (e.g., -ARG1, -$I1) may be specified. All forumla arguments, operators, and function names must be
 * separated by spaces except for parentheses used in infix notation. The operators, functions, and constants available for use in
 * formulas is shown below.
 * <table border="1" cellpadding="4" style="border-collapse:collapse">
 *   <tr style="font-weight:bold"><td colspan="3">Unary Operator</td></tr>
 *   <tr><td>-</td><td>negation</td><td>prepend to argument without spaces, can be used only on numbers and arguments (not expressions)</td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Binary Operators</td></tr>
 *   <tr><td>+</td><td>addition</td><td></td></tr>
 *   <tr><td>-</td><td>subtraction</td><td></td></tr>
 *   <tr><td>*</td><td>multiplication</td><td></td></tr>
 *   <tr><td>/</td><td>division</td><td></td></tr>
 *   <tr><td>//</td><td>integer division</td><td>like Python operator</td></tr>
 *   <tr><td>%</td><td>modulus</td><td>like Python math.fmod, not Python %</td></tr>
 *   <tr><td>^</td><td>exponentiation</td><td></td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Unary Functions</td></tr>
 *   <tr><td>ABS</td><td>absolute value</td><td></td></tr>
 *   <tr><td>ACOS</td><td>arccosine</td><td></td></tr>
 *   <tr><td>ASIN</td><td>arcsine</td><td></td></tr>
 *   <tr><td>ATAN</td><td>arctangent</td><td></td></tr>
 *   <tr><td>CEIL</td><td>ceiling</td><td>smallest integer value &gt;= argument</td></tr>
 *   <tr><td>COS</td><td>cosine</td><td></td></tr>
 *   <tr><td>EXP</td><td>exponential</td><td><em>e</em> raised to power of argument</td></tr>
 *   <tr><td>FLOOR</td><td>floor</td><td>largest integer value &lt;= argument</td></tr>
 *   <tr><td>INV</td><td>inverse</td><td>1 / argument</td></tr>
 *   <tr><td>LN</td><td>natural logarithm</td><td></td></tr>
 *   <tr><td>LOG</td><td>base 10 logarithm</td><td></td></tr>
 *   <tr><td>NEG</td><td>negation</td><td></td></tr>
 *   <tr><td>ROUND</td><td>round to nearest integer</td><td></td></tr>
 *   <tr><td>SIGN</td><td>signum</td><td>sign of argument: -1 or +1</td></tr>
 *   <tr><td>SIN</td><td>sine</td><td></td></tr>
 *   <tr><td>SQRT</td><td>square root</td><td></td></tr>
 *   <tr><td>TAN</td><td>tangent</td><td></td></tr>
 *   <tr><td>TRUNC</td><td>truncate to integer portion</td><td></td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Binary Functions</td></tr>
 *   <tr><td>MAX</td><td>maximum of two arguments</td><td></td></tr>
 *   <tr><td>MIN</td><td>minimum of two arguments</td><td></td></tr>
 *   <tr style="font-weight:bold"><td colspan="3">Constants</td></tr>
 *   <tr><td>E</td><td style="font-style:italic">e</td><td>Euler's number</td></tr>
 *   <tr><td>PI</td><td>&pi;</td><td>ratio of a cirlce's circumference to its diameter</td></tr>
 * </table>
 * @param p_location_level_id       The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_constituents            The constituents as a table of tables. Each row of the outer table specifies a single constituent and each
 *                                  row of the inner table specifies the abbreviation, type, name, and optionally the attribute id, value, and unit
 *                                  for the constituent, as described above. The table structure stored in a text string, with the linefeed character
 *                                  ('\n', chr(10)) separating rows of the outer table and the tab character ('\t', chr(9)) separating rows of
 *                                  each inner table.
 * @param p_constituent_connections The connection string for the constituents
 * @param p_level_comment           A comment about the location level
 * @param p_attribute_id            The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value         The value of the attribute, if applicable
 * @param p_attribute_unit          he unit of the attribute, if applicable
 * @param p_attribute_comment       A comment about the attribute, if applicable
 * @param p_effective_date          The effective date for the location level. Applies from this time forward
 * @param p_expiration_date         The date/time that the location level expires
 * @param p_timezone_id             The time zone of p_effective_date and p_interval_origin, if applicable
 * @param p_fail_if_exists          A flag ('T' or 'F') that specifies whether the routine should fail if the location level already exists in the database
 * @param p_ignore_nulls            A flag ('T' or 'F') that specifies whether NULL parameters should be ignored when updating
 * @param p_office_id               The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the location level already exists in the database
 */
procedure store_virtual_location_level(
   p_location_level_id       in varchar2,
   p_constituents            in varchar2 default null,
   p_constituent_connections in varchar2 default null,
   p_level_comment           in varchar2 default null,
   p_attribute_id            in varchar2 default null,
   p_attribute_value         in number   default null,
   p_attribute_unit          in varchar2 default null,
   p_attribute_comment       in varchar2 default null,
   p_effective_date          in date     default null,
   p_expiration_date         in date     default null,
   p_timezone_id             in varchar2 default 'UTC',
   p_fail_if_exists          in varchar2 default 'T',
   p_ignore_nulls            in varchar2 default 'T',
   p_office_id               in varchar2 default null);
/**
 * Retrieves a time series of location level values for a specified virtual location level
 * and a time window
 *
 * @param p_location_level_id  The location level identifier. Format is location.parameter.parameter_type.duration.specified_level
 * @param p_level_units        The value unit to retrieve the level values in
 * @param p_start_time         The start of the time window
 * @param p_end_time           The end of the time window
 * @param p_attribute_id       The attribute identifier, if applicable. Format is parameter.parameter_type.duration
 * @param p_attribute_value    The value of the attribute, if applicable
 * @param p_attribute_units    The unit of the attribute, if applicable
 * @param p_timezone_id        The time zone of the time window. Retrieved dates are also in this time zone
 * @param p_office_id          The office that owns the location level. If not specified or NULL, the session user's default office is used
 *
 * @return The location level values. The time series contains values at the spcified
 * start and end times of the time window and may contain values at intermediate times.
 * <ul>
 *   <li>If the level <b>is constant</b>, the time series will be of length 2 and the quality_codes of both elements will be zero</li>
 *   <li>If the level <b>varies in a recurring pattern</b>, the time series will include values at any pattern breakpoints in the time window. The quality_codes of all elements will be zero</li>
 *   <li>If the level <b>varies irregularly</b>, the time series will include values of at any times of the representing time series that are in the time window.  The quality codes of times within the time window will be the quality codes of the representing time series. The quality codes of the elements at the beginning and end of the time window may be zero</li>
 * </ul>
 * The quality code of each returned value will be one of the following
 * <ul>
 *   <li><b>0:&nbsp;</b>The value for all times between the previous value time and this one is the same as the previous value</li>
 *   <li><b>1:&nbsp;</b>The value for all times between the previous value time and this one is interpolated between the previous value and this one</li>
 * </ul>
 */
function retrieve_vloc_lvl_values(
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

/* maybe */
function get_vloc_lvl_eff_and_exp(
   p_location_level_id in varchar2,
   p_start_time        in date,
   p_end_time          in date,
   p_timezone_id       in varchar2 default 'UTC',
   p_attribute_id      in varchar2 default null,
   p_attribute_value   in number   default null,
   p_attribute_unit    in varchar2 default null,
   p_office_id         in varchar2 default null)
   return date2_tab_t;

/* maybe */
procedure retrieve_vloc_lvl_values_utc(
   p_level_values            out nocopy ztsv_array,
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time_utc          in  date,
   p_end_time_utc            in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_office_id               in  varchar2 default null);

/* maybe */
function retrieve_vloc_lvl_values_utc_f(
   p_location_id             in  varchar2,
   p_parameter_id            in  varchar2,
   p_parameter_type_id       in  varchar2,
   p_duration_id             in  varchar2,
   p_spec_level_id           in  varchar2,
   p_level_units             in  varchar2,
   p_start_time_utc          in  date,
   p_end_time_utc            in  date,
   p_attribute_value         in  number default null,
   p_attribute_units         in  varchar2 default null,
   p_attribute_parameter_id  in  varchar2 default null,
   p_attribute_param_type_id in  varchar2 default null,
   p_attribute_duration_id   in  varchar2 default null,
   p_office_id               in  varchar2 default null)
   return ztsv_array;
   return number;

END cwms_level;
/

show errors;
create or replace context cwms_level using cwms_level;
