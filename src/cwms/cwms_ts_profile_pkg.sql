create or replace package cwms_ts_profile
/**
 * Routines for working with time series profile data.
 *
 * @author Mike Perryman
 * @since CWMS schema 18.1.6
 */
as
--------------------------------------------------------------------------------
-- undocumented function make_ts_id
--------------------------------------------------------------------------------
function make_ts_id(
   p_location_code  in integer,
   p_parameter_code in integer,
   p_version_id     in varchar2)
   return varchar2;
/**
 * Stores a time series profile definition
 *
 * @param p_location_id        The location id of the time series profile
 * @param p_key_parameter_id   The text identifier of the parameter to which all other profile parameters are associated
 * @param p_profile_params     A CSV string of the parameter identifiers for the profile (including the key parameter).
 *                             The order of the parameters defines the parameter positions for the profile.
 * @param p_description        A text description of the time series profile
 * @param p_ref_ts_id          A time series identifier of a reference parameter value (normally Elev) for this profile
 * @param p_fail_if_exists     A flag (T/F) specifying whether to fail if time series profile already exists
 * @param p_ignore_nulls       A flag (T/F) specifying whether to ignore null values, and thus allow partial updates
 * @param p_office_id          The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure store_ts_profile(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_profile_params   in varchar2,
   p_description      in varchar2,
   p_ref_ts_id        in varchar2 default null,
   p_fail_if_exists   in varchar2 default 'T',
   p_ignore_nulls     in varchar2 default 'T',
   p_office_id        in varchar2 default null);
/**
 * Stores a time series profile definition
 *
 * @param p_ts_profile     The time series profile information. The order of the parameters defines the parameter positions for the profile.
 * @param p_fail_if_exists A flag (T/F) specifying whether to fail if time series profile already exists
 * @param p_ignore_nulls   A flag (T/F) specifying whether to ignore null values, and thus allow partial updates
 *
 * @since CWMS schema 18.1.6
 * @see type ts_profile_t
 */
procedure store_ts_profile(
   p_ts_profile     in ts_profile_t,
   p_fail_if_exists in varchar2 default 'T',
   p_ignore_nulls   in varchar2 default 'T');
/**
 * Retrieves a time series profile definition
 *
 * @param p_ts_profile       The time series profile information. The parameters are in order of the defined parameter positions.
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 * @see type ts_profile_t
 */
procedure retrieve_ts_profile(
   p_profile          out nocopy ts_profile_t,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Retrieves a time series profile definition
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 * @return                   The time series profile information. The parameters are in order of the defined parameter positions.
 *
 * @since CWMS schema 18.1.6
 * @see type ts_profile_t
 */
function retrieve_ts_profile_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_office_id        in varchar2 default null)
   return ts_profile_t;
/**
 * Retrieves time series profile parameters in parameter position order
 *
 * @param p_profile_params    A CSV string of parameter identifiers for the profile, in position order
 * @param p_location_id       The location id of the time series profile
 * @param p_key_parameter_id  The text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id         The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure retrieve_ts_profile_params(
   p_profile_params   out nocopy varchar2,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Retrieves time series profile parameters in parameter position order
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 * @return A CSV string of parameter identifiers for the profile, in position order
 *
 * @since CWMS schema 18.1.6
 */
function retrieve_ts_profile_params_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_office_id        in varchar2 default null)
   return varchar2;
/**
 * Deletes a time series profile definition
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_delete_action    Specfies whether to delete just the definition (only if no data), just the data, or both
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 */
procedure delete_ts_profile(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_delete_action    in varchar2 default cwms_util.delete_key,
   p_office_id        in varchar2 default null);
/**
 * Copies a time series profile definition to a new location. The destination location may or may not already have a profile definition,
 * but it cannot have any existing profile data.
 *
 * @param p_location_id      The location id of the time series profile to copy
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_dest_location_id The destination location to copy the profile definition to
 * @param p_dest_ref_ts_id   The time series identifier of a reference parameter value (normally Elev) for the copied profile
 * @param p_fail_if_exists   A flag (T/F) specifying whether to fail if the destination time series profile already exists
 * @param p_copy_parser      A flag (T/F) specifying whether to also copy any parser defined for this profile to the destination location.
 *                           If 'T', the p_fail_if_exists parameter applies to this copy as well.
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure copy_ts_profile(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_dest_location_id in varchar2,
   p_dest_ref_ts_id   in varchar2,
   p_fail_if_exists   in varchar2 default 'T',
   p_copy_parser      in varchar2 default 'F',
   p_office_id        in varchar2 default null);
/**
 * Retrieves a catlog of time series profiles
 * <p>
 * Matching is accomplished with glob-style wildcards, as shown below.
 * <p>
 * <table class="descr">
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
 * @param p_profile_rc A cursor containing the following columns, ordered by office_id, location_id, and key_parameter_id
 * <p>
 * <table class="descr">
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
 *     <td class="descr">The office that owns the location for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The location identifier for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">key_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter that all other profile parameter values are associated with</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">value_parameters</td>
 *     <td class="descr">sys_refcursor</td>
 *     <td class="descr">A cursor containing the following columns, ordered in profile parameter position
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">parameter_id</td>
 *           <td class="descr">varchar2(49)</td>
 *           <td class="descr">The text identifier of the parameter</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">position</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based position of the parameter in the profile</td>
 *         </tr>
 *       </table>
 *     </td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">ref_ts_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The time series identifier of a reference parameter value (normally Elev) for this profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The description of the time series profile</td>
 *   </tr>
 * </table>
 * @param p_location_id_mask      The pattern to match the location id of the time series profile
 * @param p_key_parameter_id_mask The pattern to match the text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id_mask        The patterh to match office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure cat_ts_profile(
   p_profile_rc            out nocopy sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_key_parameter_id_mask in  varchar2 default '*',
   p_office_id_mask        in  varchar2 default null);
/**
 * Retrieves a catlog of time series profiles
 * <p>
 * Matching is accomplished with glob-style wildcards, as shown below.
 * <p>
 * <table class="descr">
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
 * @param p_location_id_mask      The pattern to match the location id of the time series profile
 * @param p_key_parameter_id_mask The pattern to match the text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id_mask        The patterh to match office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 * @return A cursor containing    the following columns, ordered by office_id, location_id, and key_parameter_id
 * <p>
 * <table class="descr">
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
 *     <td class="descr">The office that owns the location for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The location identifier for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">key_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter that all other profile parameter values are associated with</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">value_parameters</td>
 *     <td class="descr">sys_refcursor</td>
 *     <td class="descr">A cursor containing the following columns, ordered in profile parameter position
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">parameter_id</td>
 *           <td class="descr">varchar2(49)</td>
 *           <td class="descr">The text identifier of the parameter</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">position</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based position of the parameter in the profile</td>
 *         </tr>
 *       </table>
 *     </td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">ref_ts_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The time series identifier of a reference parameter value (normally Elev) for this profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The description of the time series profile</td>
 *   </tr>
 * </table>
 *
 * @since CWMS schema 18.1.6
 */
function cat_ts_profile_f(
   p_location_id_mask      in varchar2 default '*',
   p_key_parameter_id_mask in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor;
/**
 * Stores data for a time series profile
 *
 * @param p_profile_data  The time series profile data
 * @param p_version_id    The version to use for the instance and associated time series
 * @param p_store_rule    The store rule to use
 * @param p_override_prot A flag (T/F) that specifies whether to override the protection flag of any existing data values. If not specified, 'F' will be used.
 * @param p_version_date  The version date of the data. If not specified, the data will be stored as non-versioned.
 * @param p_office_id     The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 * @see type ztsvx_tab_t
 * @see constant cwms_util.delete_insert
 * @see constant cwms_util.do_not_replace
 * @see constant cwms_util.replace_all
 * @see constant cwms_util.replace_missing_values_only
 * @see constant cwms_util.replace_with_non_missing
 * @see constant cwms_util.non_versioned
 */
procedure store_ts_profile_instance(
   p_profile_data  in ts_prof_data_t,
   p_version_id    in varchar2,
   p_store_rule    in varchar2,
   p_override_prot in varchar  default 'F',
   p_version_date  in date     default cwms_util.non_versioned,
   p_office_id     in varchar2 default null);
/**
 * Stores data for a time series profile from a CLOB. A parser must be defined for the profile.
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_units            A table of parameter units. The unit of the key parameter must be first and the remaining units must be in the same order
 *                           as the data values, regardless of the parameter positions defined for the profile.
 * @param p_profile_data     The text data values to be parsed
 * @param p_version_id       The version to use for the instance and associated time series
 * @param p_store_rule       The store rule to use
 * @param p_override_prot    A flag (T/F) that specifies whether to override the protection flag of any existing data values. If not specified, 'F' will be used.
 * @param p_version_date     The version date of the data. If not specified, the data will be stored as non-versioned.
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 * @see constant cwms_util.delete_insert
 * @see constant cwms_util.do_not_replace
 * @see constant cwms_util.replace_all
 * @see constant cwms_util.replace_missing_values_only
 * @see constant cwms_util.replace_with_non_missing
 * @see constant cwms_util.non_versioned
 */
procedure store_ts_profile_instance(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_profile_data     in clob,
   p_version_id       in varchar2,
   p_store_rule       in varchar2,
   p_override_prot    in varchar  default 'F',
   p_version_date     in date     default cwms_util.non_versioned,
   p_office_id        in varchar2 default null);
/**
 * Retrieves data for a time series profile
 *
 * @param p_profile_data     The profile data
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_version_id       The version identifier for the profile instance(s) and associated time series
 * @param p_units            A CSV string of the units to retrieve the data in, in parameter position order of the profile
 * @param p_start_time       The start time of the time window
 * @param p_end_time         The end time of the time window. If unspecified or NULL, the data for a profile instance at p_start_time is retrieved.
 * @param p_time_zone        The time zone for the time window and retrieved times
 * @param p_start_inclusive  A flag (T/F) that specifies whether the time window begins on (T) or after (F) the start time
 * @param p_end_inclusive    A flag (T/F) that specifies whether the time window end on (T) or before (F) the end time
 * @param p_previous         A flag (T/F) that specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             A flag (T/F) that specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
 * @param p_max_version      A flag (T/F) that specifies whether to retrieve the maximum (T) or minimum (F) version date if p_version_date is NULL
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current sessions default user is used
 *
 * @since CWMS schema 18.1.6
 * @see type ztsvx_tab_t
 * @see constant cwms_util.non_versioned
 */
procedure retrieve_ts_profile_data(
   p_profile_data     out nocopy ts_prof_data_t,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_units            in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves data for a time series profile
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_version_id       The version identifier for the profile instance(s) and associated time series
 * @param p_units            A CSV string of the units to retrieve the data in, in parameter position order of the profile
 * @param p_start_time       The start time of the time window
 * @param p_end_time         The end time of the time window. If unspecified or NULL, the data for a profile instance at p_start_time is retrieved.
 * @param p_time_zone        The time zone for the time window and retrieved times
 * @param p_start_inclusive  A flag (T/F) that specifies whether the time window begins on (T) or after (F) the start time
 * @param p_end_inclusive    A flag (T/F) that specifies whether the time window end on (T) or before (F) the end time
 * @param p_previous         A flag (T/F) that specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             A flag (T/F) that specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
 * @param p_max_version      A flag (T/F) that specifies whether to retrieve the maximum (T) or minimum (F) version date if p_version_date is NULL
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current sessions default user is used
 * @return The profile data
 *
 * @since CWMS schema 18.1.6
 * @see type ztsvx_tab_t
 * @see constant cwms_util.non_versioned
 */
function retrieve_ts_profile_data_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_version_id       in varchar2,
   p_units            in varchar2,
   p_start_time       in date,
   p_end_time         in date     default null,
   p_time_zone        in varchar2 default 'UTC',
   p_start_inclusive  in varchar2 default 'T',
   p_end_inclusive    in varchar2 default 'T',
   p_previous         in varchar2 default 'F',
   p_next             in varchar2 default 'F',
   p_version_date     in date     default null,
   p_max_version      in varchar2 default 'T',
   p_office_id        in varchar2 default null)
   return ts_prof_data_t;
/**
 * Retrieves elevation data for a time series profile based on the reference time series
 *
 * @param p_elevations       The profile elevations
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated. Base parameter must be Depth or Height.
 * @param p_version_id       The version identifier for the profile instance(s) and associated time series
 * @param p_unit             The unit of the elevations
 * @param p_start_time       The start time of the time window
 * @param p_end_time         The end time of the time window. If unspecified or NULL, the data for a profile instance at p_start_time is retrieved.
 * @param p_time_zone        The time zone for the time window and retrieved times
 * @param p_start_inclusive  A flag (T/F) that specifies whether the time window begins on (T) or after (F) the start time
 * @param p_end_inclusive    A flag (T/F) that specifies whether the time window end on (T) or before (F) the end time
 * @param p_previous         A flag (T/F) that specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             A flag (T/F) that specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
 * @param p_max_version      A flag (T/F) that specifies whether to retrieve the maximum (T) or minimum (F) version date if p_version_date is NULL
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current sessions default user is used
 *
 * @since CWMS schema 18.1.6
 * @see type ztsv_array
 * @see constant cwms_util.non_versioned
 */
procedure retrieve_ts_profile_elevs(
   p_elevations       out nocopy ztsv_array,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves elevation data for a time series profile based on the reference time series
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated. Base parameter must be Depth or Height.
 * @param p_version_id       The version identifier for the profile instance(s) and associated time series
 * @param p_unit             The unit of the elevations
 * @param p_start_time       The start time of the time window
 * @param p_end_time         The end time of the time window. If unspecified or NULL, the data for a profile instance at p_start_time is retrieved.
 * @param p_time_zone        The time zone for the time window and retrieved times
 * @param p_start_inclusive  A flag (T/F) that specifies whether the time window begins on (T) or after (F) the start time
 * @param p_end_inclusive    A flag (T/F) that specifies whether the time window end on (T) or before (F) the end time
 * @param p_previous         A flag (T/F) that specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             A flag (T/F) that specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
 * @param p_max_version      A flag (T/F) that specifies whether to retrieve the maximum (T) or minimum (F) version date if p_version_date is NULL
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current sessions default user is used
 * @return The profile elevations
 *
 * @since CWMS schema 18.1.6
 * @see type ztsv_array
 * @see constant cwms_util.non_versioned
 */
function retrieve_ts_profile_elevs_f(
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
   return ztsv_array;
/**
 * Retrieves elevation data for a time series profile based on the elevation of the location
 *
 * @param p_elevations       The profile elevations
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated. Base parameter must be Depth or Height.
 * @param p_version_id       The version identifier for the profile instance(s) and associated time series
 * @param p_unit             The unit of the elevations
 * @param p_start_time       The start time of the time window
 * @param p_end_time         The end time of the time window. If unspecified or NULL, the data for a profile instance at p_start_time is retrieved.
 * @param p_time_zone        The time zone for the time window and retrieved times
 * @param p_start_inclusive  A flag (T/F) that specifies whether the time window begins on (T) or after (F) the start time
 * @param p_end_inclusive    A flag (T/F) that specifies whether the time window end on (T) or before (F) the end time
 * @param p_previous         A flag (T/F) that specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             A flag (T/F) that specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
 * @param p_max_version      A flag (T/F) that specifies whether to retrieve the maximum (T) or minimum (F) version date if p_version_date is NULL
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current sessions default user is used
 *
 * @since CWMS schema 18.1.6
 * @see type ztsv_array
 * @see constant cwms_util.non_versioned
 */
procedure retrieve_ts_profile_elevs_2(
   p_elevations       out nocopy ztsv_array,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null);
/**
 * Retrieves elevation data for a time series profile based on the elevation of the location
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated. Base parameter must be Depth or Height.
 * @param p_version_id       The version identifier for the profile instance(s) and associated time series
 * @param p_unit             The unit of the elevations
 * @param p_start_time       The start time of the time window
 * @param p_end_time         The end time of the time window. If unspecified or NULL, the data for a profile instance at p_start_time is retrieved.
 * @param p_time_zone        The time zone for the time window and retrieved times
 * @param p_start_inclusive  A flag (T/F) that specifies whether the time window begins on (T) or after (F) the start time
 * @param p_end_inclusive    A flag (T/F) that specifies whether the time window end on (T) or before (F) the end time
 * @param p_previous         A flag (T/F) that specifies whether to retrieve the latest value before the start of the time window
 * @param p_next             A flag (T/F) that specifies whether to retrieve the earliest value after the end of the time window
 * @param p_version_date     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
 * @param p_max_version      A flag (T/F) that specifies whether to retrieve the maximum (T) or minimum (F) version date if p_version_date is NULL
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current sessions default user is used
 * @return The profile elevations
 *
 * @since CWMS schema 18.1.6
 * @see type ztsv_array
 * @see constant cwms_util.non_versioned
 */
function retrieve_ts_profile_elevs_2_f(
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_version_id       in  varchar2,
   p_unit             in  varchar2,
   p_start_time       in  date,
   p_end_time         in  date     default null,
   p_time_zone        in  varchar2 default 'UTC',
   p_start_inclusive  in  varchar2 default 'T',
   p_end_inclusive    in  varchar2 default 'T',
   p_previous         in  varchar2 default 'F',
   p_next             in  varchar2 default 'F',
   p_version_date     in  date     default null,
   p_max_version      in  varchar2 default 'T',
   p_office_id        in  varchar2 default null)
   return ztsv_array;
/**
 * Deletes a time series profile instance
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_version_id       The version (e.g., Raw, Rev) of the profile instance and its associated time series
 * @param p_first_date_time  The earliest timestamp in the profile instance
 * @param p_time_zone        The time zone of p_first_date_time. If NULL or not specified, UTC will be used
 * @param p_override_prot    A flag (T/F) specifying whether to override protection when deleting associated time series values
 * @param p_version_date     The version date of the instance and associated time series values. If unspecified or NULL, non-versioned data will be deleted.
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure delete_ts_profile_instance(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_version_id       in varchar2,
   p_first_date_time  in date,
   p_time_zone        in varchar2 default 'UTC',
   p_override_prot    in varchar2 default 'F',
   p_version_date     in date default cwms_util.non_versioned,
   p_office_id        in varchar2 default null);
/**
 * Retrieves a catlog of time series profile instances
 * <p>
 * Matching is accomplished with glob-style wildcards, as shown below.
 * <p>
 * <table class="descr">
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
 * @param p_instance_rc A cursor containing the following columns, ordered by office_id, location_id, key_parameter_id, ts_version, version_date, and first_data_time
 * <p>
 * <table class="descr">
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
 *     <td class="descr">The office that owns the location for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The location identifier for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">key_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter that all other profile parameter values are associated with</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">version_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The version identifier for the instance</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">version_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The version date of the profile instance and its associated time series, in the specified or default time zone</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">first_data_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The earliest time stamp in the profile instance, in the specified or default time zone</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">last_data_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The latest time stamp in the profile instance, in the specified or default time zone</td>
 *   </tr>
 * </table>
 * @param p_location_id_mask      The pattern to match the location id of the time series profile
 * @param p_key_parameter_id_mask The pattern to match the key parmeter identifier of the time series profile
 * @param p_version_id_mask       The pattern to match the version of the instance
 * @param p_start_time            The start of the time window that encompasses the <b>first_data_time</b> of the instance. If NULL or not specified, no start boundary is used.
 * @param p_end_time              The end of the time window that encompasses the <b>first_data_time</b> of the instance. If NULL or not specified, no end boundary is used.
 * @param p_time_zone             The time zone of p_start_time and p_end_time, and also of the date/times in the returned catalog
 * @param p_office_id_mask        The patterh to match office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure cat_ts_profile_instance(
   p_instance_rc           out nocopy sys_refcursor,
   p_location_id_mask      in  varchar2 default '*',
   p_key_parameter_id_mask in  varchar2 default '*',
   p_version_id_mask       in  varchar2 default '*',
   p_start_time            in  date     default null,
   p_end_time              in  date     default null,
   p_time_zone             in  varchar2 default 'UTC',
   p_office_id_mask        in  varchar2 default null);
/**
 * Retrieves a catlog of time series profile instances
 * <p>
 * Matching is accomplished with glob-style wildcards, as shown below.
 * <p>
 * <table class="descr">
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
 * @param p_location_id_mask      The pattern to match the location id of the time series profile
 * @param p_key_parameter_id_mask The pattern to match the text identifier of the parameter to which all other profile parameters are associated
 * @param p_version_id_mask       The pattern to match the version of the instance
 * @param p_start_time            The start of the time window that encompasses the <b>first_data_time</b> of the instance. If NULL or not specified, no start boundary is used.
 * @param p_end_time              The end of the time window that encompasses the <b>first_data_time</b> of the instance. If NULL or not specified, no end boundary is used.
 * @param p_time_zone             The time zone of p_start_time and p_end_time, and also of the date/times in the returned catalog
 * @param p_office_id_mask        The patterh to match office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 * @return A cursor containing the following columns, ordered by office_id, location_id, key_parameter_id, ts_version, version_date, and first_data_time
 * <p>
 * <table class="descr">
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
 *     <td class="descr">The office that owns the location for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The location identifier for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">key_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter that all other profile parameter values are associated with</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">version_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The version identifier for the instance</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">version_date</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The version date of the profile instance and its associated time series, in the specified or default time zone</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">first_data_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The earliest time stamp in the profile instance, in the specified or default time zone</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">last_data_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The latest time stamp in the profile instance, in the specified or default time zone</td>
 *   </tr>
 * </table>
 *
 * @since CWMS schema 18.1.6
 */
function cat_ts_profile_instance_f(
   p_location_id_mask      in varchar2 default '*',
   p_key_parameter_id_mask in varchar2 default '*',
   p_version_id_mask       in varchar2 default '*',
   p_start_time            in date     default null,
   p_end_time              in date     default null,
   p_time_zone             in varchar2 default 'UTC',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor;
/**
 * Stores text parsing information for a profile
 *
 * @param p_location_id         The location id of the time series profile
 * @param p_key_parameter_id    The text identifier of the parameter to which all other profile parameters are associated
 * @param p_record_delimiter    The character used to separate records in the text, normally the newline character
 * @param p_field_delimiter     The character used to separate fields within a record, if the fields are delimited, normally comma or tab character.
 *                              Use NULL if fields are fixed width.
 * @param p_time_field          The 1-based number of the field (or the first of two adjacent fields) in each record that contains the record timestamp
 * @param p_time_start_col      The 1-based beginning column number of the timestamp field in each record, if the fields are fixed width.
 *                              Use NULL if fields are delimited.
 * @param p_time_end_col        The 1-based ending column number of the timestamp field in each record, if the fields are fixed width.
 *                              Use NULL if fields are delimited.
 * @param p_time_format         The Oracle time format of the timestamp field (e.g., 'YYYY-MM-DD HH24:MI:SS'). If timestamp is two adjacent fields, place a field delimiter between the date and time portions of the format
 * @param p_time_zone           The time zone of the timestamps in the text
 * @param p_parameter_info      The parsing information for the profile parameters (including the key parameter), in CSV format.
 *                              <p>
 *                              Each record contains the fields:
 *                              <ol>
 *                              <li>parameter id (required)</li>
 *                              <li>parameter unit (required)</li>
 *                              <li>1-based field number (required)</li>
 *                              <li>1-based beginning column of the field (required only if fields are fixed width)</li>
 *                              <li>1-based ending column of the field (required only if fields are fixed width)</li>
 *                              </ol>
 *                              The order of the records is unimportant.
 *                              <p>
 *                              May be expanded in a future release to accept information in JSON and/or XML formats.
 * @param p_time_in_two_fields  A flag (T/F) specifying whether the date and time portions of the time stamp are in adjacent fields
 * @param p_fail_if_exists      A flag (T/F) specifying whether to fail if parsing information already exists for the time series profile
 * @param p_ignore_nulls        A flag (T/F) specifying whether to ignore null values, and thus allow partial updates
 * @param p_office_id           The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure store_ts_profile_parser(
   p_location_id        in varchar2,
   p_key_parameter_id   in varchar2,
   p_record_delimiter   in varchar2,
   p_field_delimiter    in varchar2,
   p_time_field         in integer,
   p_time_start_col     in integer,
   p_time_end_col       in integer,
   p_time_format        in varchar2,
   p_time_zone          in varchar2,
   p_parameter_info     in varchar2,
   p_time_in_two_fields in varchar2 default 'F',
   p_fail_if_exists     in varchar2 default 'T',
   p_ignore_nulls       in varchar2 default 'T',
   p_office_id          in varchar2 default null);
/**
 * Retrieves text parsing information for a profile
 *
 * @param p_record_delimiter The character used to separate records in the text
 * @param p_field_delimiter  The character used to separate fields within a record, if the fields are delimited, otherwise NULL
 * @param p_time_field       The 1-based number of the field in each record that contains the record timestamp
 * @param p_time_start_col   The 1-based beginning column number of the timestamp field in each record, if the fields are fixed width, otherwise NULL
 * @param p_time_end_col     The 1-based ending column number of the timestamp field in each record, if the fields are fixed width, otherwise NULL
 * @param p_time_format      The Oracle time format of the timestamp field
 * @param p_time_zone        The time zone of the timestamps in the text
 * @param p_parameter_info   The parsing information for the profile parameters (including the key parameter), in CSV format.
 *                           <p>
 *                           Each record contains the fields:
 *                           <ol>
 *                           <li>parameter id</li>
 *                           <li>parameter unit</li>
 *                           <li>1-based field number</li>
 *                           <li>1-based beginning column of the field (only if fields are fixed width)</li>
 *                           <li>1-based ending column of the field (only if fields are fixed width)</li>
 *                           </ol>
 *                           May be expanded in a future release to return information in JSON and/or XML formats.
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure retrieve_ts_profile_parser(
   p_record_delimiter out nocopy varchar2,
   p_field_delimiter  out nocopy varchar2,
   p_time_field       out nocopy pls_integer,
   p_time_col_start   out nocopy pls_integer,
   p_time_col_end     out nocopy pls_integer,
   p_time_format      out nocopy varchar2,
   p_time_zone        out nocopy varchar2,
   p_parameter_info   out nocopy varchar2,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Deletes text parsing information for a time series profile
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure delete_ts_profile_parser(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_office_id        in varchar2 default null);
/**
 * Copies text parsing information for a time series profile to a new location.
 *
 * @param p_location_id      The location id of the time profile to copy the parsing information from
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_dest_location_id The destination location to copy the profile parsing information to
 * @param p_fail_if_exists   A flag (T/F) specifying whether to fail if the destination time series profile already exists
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure copy_ts_profile_parser(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_dest_location_id in varchar2,
   p_fail_if_exists   in varchar2 default 'T',
   p_office_id        in varchar2 default null);
/**
 * Retrieves a catlog of parsing information for time series profiles
 * <p>
 * Matching is accomplished with glob-style wildcards, as shown below.
 * <p>
 * <table class="descr">
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
 * @param p_profile_parser_rc A cursor containing the following columns, ordered by office_id, location_id, and key_parameter_id
 * <p>
 * <table class="descr">
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
 *     <td class="descr">The office that owns the location for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The location identifier for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">key_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter that all other profile parameter values are associated with</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">record_delimiter</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The character used to separate records in the text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">field_delimiter</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The character used to separate fields within a record, if the fields are delimited, otherwise NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">time_field</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The 1-based number of the field in each record that contains the record timestamp</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">time_start_col</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The 1-based beginning column number of the timestamp field in each record, if the fields are fixed width, otherwise NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">time_end_col</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The 1-based ending column number of the timestamp field in each record, if the fields are fixed width, otherwise NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">time_format</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The Oracle time format of the timestamp field</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">time_zone</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone of the timestamps in the text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">parameter_info</td>
 *     <td class="descr">sys_refcursor</td>
 *     <td class="descr">A cursor containing the following columns, orderd in order of field or start_col
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">parameter_id</td>
 *           <td class="descr">varchar2(49)</td>
 *           <td class="descr">The text identifier of the parameter</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">unit</td>
 *           <td class="descr">varchar2(16)</td>
 *           <td class="descr">The unit of the parameter in the text</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">3</td>
 *           <td class="descr">field_number</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based field number of the parameter in the text records</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">4</td>
 *           <td class="descr">start_col</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based beginning column of the field (only if fields are fixed width)</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">5</td>
 *           <td class="descr">end_col</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based ending column of the field (only if fields are fixed width)</td>
 *         </tr>
 *       </table>
 *     </td>
 *   </tr>
 * </table>
 * @param p_location_id_mask      The pattern to match the location id of the time series profile
 * @param p_key_parameter_id_mask The pattern to match the text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id_mask        The patterh to match office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @since CWMS schema 18.1.6
 */
procedure cat_ts_profile_parser(
   p_profile_parser_rc     out nocopy sys_refcursor, -- office, location_id, key_parameter_id, record_delimiter, field_delimiter, time_field, time_format, time_zone, param_cursor(param, unit, field, start_col, end_col)
   p_location_id_mask      in  varchar2 default '*',
   p_key_parameter_id_mask in  varchar2 default '*',
   p_office_id_mask        in  varchar2 default null);
/**
 * Retrieves a catlog of parsing information for time series profiles
 * <p>
 * Matching is accomplished with glob-style wildcards, as shown below.
 * <p>
 * <table class="descr">
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
 * @param p_location_id_mask      The pattern to match the location id of the time series profile
 * @param p_key_parameter_id_mask The pattern to match the text identifier of the parameter to which all other profile parameters are associated
 * @param p_office_id_mask        The patterh to match office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 * @return A cursor containing the following columns, ordered by office_id, location_id, and key_parameter_id
 * <p>
 * <table class="descr">
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
 *     <td class="descr">The office that owns the location for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(191)</td>
 *     <td class="descr">The location identifier for the profile</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">key_parameter_id</td>
 *     <td class="descr">varchar2(49)</td>
 *     <td class="descr">The parameter that all other profile parameter values are associated with</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">record_delimiter</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The character used to separate records in the text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">field_delimiter</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">The character used to separate fields within a record, if the fields are delimited, otherwise NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">time_field</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The 1-based number of the field in each record that contains the record timestamp</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">time_start_col</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The 1-based beginning column number of the timestamp field in each record, if the fields are fixed width, otherwise NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">time_end_col</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The 1-based ending column number of the timestamp field in each record, if the fields are fixed width, otherwise NULL</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">time_format</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The Oracle time format of the timestamp field</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">time_zone</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone of the timestamps in the text</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">parameter_info</td>
 *     <td class="descr">sys_refcursor</td>
 *     <td class="descr">A cursor containing the following columns, orderd in order of field or start_col
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">parameter_id</td>
 *           <td class="descr">varchar2(49)</td>
 *           <td class="descr">The text identifier of the parameter</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">unit</td>
 *           <td class="descr">varchar2(16)</td>
 *           <td class="descr">The unit of the parameter in the text</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">3</td>
 *           <td class="descr">field_number</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based field number of the parameter in the text records</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">4</td>
 *           <td class="descr">start_col</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based beginning column of the field (only if fields are fixed width)</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">5</td>
 *           <td class="descr">end_col</td>
 *           <td class="descr">integer</td>
 *           <td class="descr">The 1-based ending column of the field (only if fields are fixed width)</td>
 *         </tr>
 *       </table>
 *     </td>
 *   </tr>
 * </table>
 *
 * @since CWMS schema 18.1.6
 */
function cat_ts_profile_parser_f(
   p_location_id_mask      in varchar2 default '*',
   p_key_parameter_id_mask in varchar2 default '*',
   p_office_id_mask        in varchar2 default null)
   return sys_refcursor;
/**
 * Parses time series profile text into a ts_prof_data_t object
 *
 * @param p_ts_profile_data  The parsed data
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_text             The text to parse
 * @param p_time_zone        The time zone of the timestamps in the profile text
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @see type ts_prof_data_t
 * @see store_ts_profile_instance
 * @since CWMS schema 18.1.6
 */
procedure parse_ts_profile_inst_text(
   p_ts_profile_data  out nocopy ts_prof_data_t,
   p_location_id      in  varchar2,
   p_key_parameter_id in  varchar2,
   p_text             in  clob,
   p_time_zone        in  varchar2,
   p_office_id        in  varchar2 default null);
/**
 * Parses time series profile text into a ts_prof_data_t object
 *
 * @param p_location_id      The location id of the time series profile
 * @param p_key_parameter_id The text identifier of the parameter to which all other profile parameters are associated
 * @param p_text             The text to parse
 * @param p_time_zone        The time zone of the timestamps in the profile text
 * @param p_office_id        The office that owns the location of the profile. If unspecified or NULL, the current session's default user is used
 *
 * @return The parsed data
 *
 * @see type ts_prof_data_t
 * @see store_ts_profile_instance
 * @since CWMS schema 18.1.6
 */
function parse_ts_profile_inst_text_f(
   p_location_id      in varchar2,
   p_key_parameter_id in varchar2,
   p_text             in clob,
   p_time_zone        in varchar2,
   p_office_id        in varchar2 default null)
   return ts_prof_data_t;

end cwms_ts_profile;
/
