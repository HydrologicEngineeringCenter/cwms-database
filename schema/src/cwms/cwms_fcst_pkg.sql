create or replace package cwms_fcst
/**
 * Routines for storing and retrieving forecast information. Replaces package cwms_forecast.
 */
as
c_forecast_info_filename constant varchar2(17) := 'forecast_info.xml';
/**
 * Stores (inserts or updates) a forecast specification
 *
 * @param p_fcst_spec_id   The forecast specification identifier (e.g. 'CAVI', 'RVF', etc)
 * @param p_location_id    The forecast specification location
 * @param p_entity_id      The agency/office that generates forecasts for this specification
 * @param p_description    A description of the forecast specification
 * @param p_fail_if_exists A flag ('T'/'F') that specifies whether to raise an exception if this specification already exists. If unspecified, 'T' will be used.
 * @param p_office_id      The office that owns the forecast specification. If unspecified or NULL, the session user's current office will be used.
 */
procedure store_fcst_spec(
   p_fcst_spec_id   in varchar2,
   p_location_id    in varchar2,
   p_entity_id      in varchar2,
   p_description    in varchar2 default null,
   p_fail_if_exists in varchar2 default 'T',
   p_office_id      in varchar2 default null);
/**
 * Catalogs forecast specifications that match the specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
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
 * @param p_cursor A cursor containing all matching forecast specifications. The cursor contains the following columns:
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
 *     <td class="descr">The office that owns the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">fcst_spec_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The target location for the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">entity_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The identifier of the agency/office that generates forecasts for this specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">entity_name</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The name of the agency/office that generates forecasts for this specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The name of the agency/office that generates forecasts for this specification</td>
 *   </tr>
 * </table>
 * @param p_fcst_spec_id_mask The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all forecast_specification identifiers will be matched.
 * @param p_location_id_mask  The wildcard pattern to retrieve forecast specification locations for. If unspecified, all forecast specification locations will be matched.
 * @param p_entity_id_mask    The wildcard pattern to retrieve entities for. If unspecified, all entities will be matched.
 * @param p_office_id_mask    The wildcard pattern to retrieve offices for. If unspecified or NULL the session user's current office will be used.
 */
procedure cat_fcst_spec(
   p_cursor            out sys_refcursor,
   p_fcst_spec_id_mask in varchar2 default '*',
   p_location_id_mask  in varchar2 default '*',
   p_entity_id_mask    in varchar2 default '*',
   p_office_id_mask    in varchar2 default null);
/**
 * Catalogs forecast specifications that match the specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
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
 * @param p_fcst_spec_id_mask The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all forecast_specification identifiers will be matched.
 * @param p_location_id_mask  The wildcard pattern to retrieve forecast specification locations for. If unspecified, all forecast specification locations will be matched.
 * @param p_entity_id_mask    The wildcard pattern to retrieve entities for. If unspecified, all entities will be matched.
 * @param p_office_id_mask    The wildcard pattern to retrieve offices for. If unspecified or NULL the session user's current office will be used.
 *
 * @return A cursor containing all matching forecast specifications. The cursor contains the following columns:
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
 *     <td class="descr">The office that owns the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">fcst_spec_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The target location for the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">entity_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The identifier of the agency/office that generates forecasts for this specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">entity_name</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The name of the agency/office that generates forecasts for this specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">description</td>
 *     <td class="descr">varchar2(64)</td>
 *     <td class="descr">The name of the agency/office that generates forecasts for this specification</td>
 *   </tr>
 * </table>
 */
function cat_fcst_spec_f(
   p_fcst_spec_id_mask in varchar2 default '*',
   p_location_id_mask  in varchar2 default '*',
   p_entity_id_mask    in varchar2 default '*',
   p_office_id_mask    in varchar2 default null)
   return sys_refcursor;
/**
 * Deletes a forecast specification and/or all instances.
 *
 * @param p_fcst_spec_id   The forecast specification identifier to delete information for
 * @param p_location_id    The forecast specification location to delete information for
 * @param p_delete_action  Specifies what to delete.  Actions are as follows:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">p_delete_action</th>
 *     <th class="descr">Action</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_key</td>
 *     <td class="descr">deletes only the forecast specification, fails if specification has any forecast instances</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_data</td>
 *     <td class="descr">deletes only the forecast instances, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">cwms_util.delete_all</td>
 *     <td class="descr">deletes the forecast specification and all instances</td>
 *   </tr>
 * </table>
 * @param p_office_id  The office that owns the forecast specification. If not specified or NULL, the current user's office is used.
 *
 * @see constant cwms_util.delete_key
 * @see constant cwms_util.delete_data
 * @see constant cwms_util.delete_all
 */
procedure delete_fcst_spec(
   p_fcst_spec_id   in varchar2,
   p_location_id    in varchar2,
   p_delete_action  in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Store (creates or updates) a forecast (forecast time series and/or files)
 *
 * @param p_fcst_spec_id       The forecast specification identifier to store the forecast for
 * @param p_location_id        The forecast specification location to store the forecast for
 * @param p_forecast_date_time The forecast date/time (context specific to forecast specification identifier)
 * @param p_issue_date_time    The issue date/time for the forecast
 * @param p_time_zone          The time zone of the forecast and issue date/times and of the time series. If not specified or NULL, the location's time zone is used.
 * @param p_max_age            The number of hours after p_issue_date_time that the forcast is valid
 * @param p_notes              Any notes specific to the forecast
 * @param p_time_series        The forecast time series, if any
 * @param p_files              The forecast files, if any
 * @param p_fail_if_exists     A flag ('T'/'F') specifying whether to raise an exception if the forecast already exists
 * @param p_office_id          The office that owns the forecast specification. If not specified or NULL, the current user's office is used.
 *
 * @see type ztimeseries_array
 * @see type fcst_file_tab_t
 */
procedure store_fcst(
   p_fcst_spec_id       in varchar2,
   p_location_id        in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2          default null,
   p_max_age            in binary_integer    default null,
   p_notes              in varchar2          default null,
   p_time_series        in ztimeseries_array default null,
   p_files              in fcst_file_tab_t   default null,
   p_fail_if_exists     in varchar2          default 'T',
   p_office_id          in varchar2          default null);
/**
 * Catalogs forecasts that match the specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
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
 * @param p_cursor A cursor containing all matching forecasts. The cursor contains the following columns:
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
 *     <td class="descr">The office that owns the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">fcst_spec_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The target location for the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">time_zone</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone of the following date/times. Will be the specified time zone or the location's time zone if none is specified</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">fcst_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The forecast date</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">issue_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The issue date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">first_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The start of the time window for any included time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">last_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The end of the time window for any included time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">max_age</td>
 *     <td class="descr">number(6)</td>
 *     <td class="descr">The number of hours after the issue date/time that the forecast is valid</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">valid</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag ('T'/'F') specifying whether the forecast was valid at the time of the catalog</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">notes</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The notes specific to the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">time_sereies_ids</td>
 *     <td class="descr">sys_refcursor containing the following columns
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">cwms_ts_id</td>
 *           <td class="descr">varchar2(193)</td>
 *           <td class="descr">The time series identifier</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The time series identifiers in the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">file_names</td>
 *     <td class="descr">sys_refcursor containing the following columns
 *       <p>
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">file_name</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The base name (no directories) of the file</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">description</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">A desription of the file contents</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The file names in the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">key_value_pairs</td>
 *     <td class="descr">sys_refcursor containing the following columns
 *       <p>
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">key</td>
 *           <td class="descr">varchar2(32)</td>
 *           <td class="descr">The key</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">value</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The value associated with the key</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The matched (key, value) pairs for the forecast</td>
 *   </tr>
 * </table>
 * @param p_fcst_spec_id_mask      The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all forecast_specification identifiers will be matched.
 * @param p_location_id_mask       The wildcard pattern to retrieve forecast specification locations for. If unspecified, all forecast specification locations will be matched.
 * @param p_min_forecast_date_time The earliest forecast date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_forecast_date_time The latest forecast date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_min_issue_date_time    The earliest issue date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_issue_date_time    The latest issue date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_time_zone              The time zone of the min and max date/times and date/times returned in the cursor.
 *                                 If unspecified or NULL, any specified date/times will be interpreted as 'UTC' and returned date/times will be in the location's local time zone.
 * @param p_valid_forecasts_only   A flag ('T'/'F') specifying whether to catalog only valid or all forecasts. Valid forecasts have issue date/times since the current date/time minus max_age hours.
 * @param p_key_mask               The wildcard pattern that the key field in returned records must match. If unspecified, all key fields will be matched
 * @param p_value_mask             The wildcard pattern that the value field in returned records must match. If unspecified, all value fields will be matched.
 * @param p_office_id_mask         The wildcard pattern to retrieve offices for. If unspecified or NULL, the session user's current office will be used.
 */
procedure cat_fcst(
   p_cursor                 out sys_refcursor,
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_location_id_mask       in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default null,
   p_valid_forecasts_only   in varchar2 default 'F',
   p_key_mask               in varchar2 default '*',
   p_value_mask             in varchar2 default '*',
   p_office_id_mask         in varchar2 default null);
/**
 * Catalogs forecasts that match the specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below, instead of sql-style
 * wildcards.
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
 * @param p_fcst_spec_id_mask      The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all forecast_specification identifiers will be matched.
 * @param p_location_id_mask       The wildcard pattern to retrieve forecast specification locations for. If unspecified, all forecast specification locations will be matched.
 * @param p_min_forecast_date_time The earliest forecast date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_forecast_date_time The latest forecast date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_min_issue_date_time    The earliest issue date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_issue_date_time    The latest issue date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_time_zone              The time zone of the min and max date/times and date/times returned in the cursor.
 *                                 If unspecified or NULL, any specified date/times will be interpreted as 'UTC' and returned date/times will be in the location's local time zone.
 * @param p_key_mask               The wildcard pattern that the key field in returned records must match. If unspecified, all key fields will be matched.
 * @param p_value_mask             The wildcard pattern that the value field in returned records must match. If unspecified, all value fields will be matched.
 * @param p_valid_forecasts_only   A flag ('T'/'F') specifying whether to catalog only valid or all forecasts. Valid forecasts have issue date/times since the current date/time minus max_age hours.
 * @param p_office_id_mask         The wildcard pattern to retrieve offices for. If unspecified or NULL the session user's current office will be used.
 *
 * @return A cursor containing all matching forecasts. The cursor contains the following columns:
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
 *     <td class="descr">The office that owns the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">2</td>
 *     <td class="descr">fcst_spec_id</td>
 *     <td class="descr">varchar2(32)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(57)</td>
 *     <td class="descr">The target location for the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">4</td>
 *     <td class="descr">time_zone</td>
 *     <td class="descr">varchar2(28)</td>
 *     <td class="descr">The time zone of the following date/times</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">5</td>
 *     <td class="descr">fcst_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The forecast date</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">6</td>
 *     <td class="descr">issue_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The issue date of the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">first_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The start of the time window for any included time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">last_date_time</td>
 *     <td class="descr">date</td>
 *     <td class="descr">The end of the time window for any included time series</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">max_age</td>
 *     <td class="descr">number(6)</td>
 *     <td class="descr">The number of hours after the issue date/time that the forecast is valid</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">valid</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag ('T'/'F') specifying whether the forecast was valid at the time of the catalog</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">notes</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The notes specific to the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">time_sereies_ids</td>
 *     <td class="descr">sys_refcursor containing the following columns
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">cwms_ts_id</td>
 *           <td class="descr">varchar2(193)</td>
 *           <td class="descr">The time series identifier</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The time series identifiers in the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
 *     <td class="descr">file_names</td>
 *     <td class="descr">sys_refcursor containing the following columns
 *       <p>
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">file_name</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The base name (no directories) of the file</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">description</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">A desription of the file contents</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The file names in the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">14</td>
 *     <td class="descr">key_value_pairs</td>
 *     <td class="descr">sys_refcursor containing the following columns
 *       <p>
 *       <table class="descr">
 *         <tr>
 *           <th class="descr">Column No.</th>
 *           <th class="descr">Column Name</th>
 *           <th class="descr">Data Type</th>
 *           <th class="descr">Contents</th>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">1</td>
 *           <td class="descr">key</td>
 *           <td class="descr">varchar2(32)</td>
 *           <td class="descr">The key</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">value</td>
 *           <td class="descr">varchar2(64)</td>
 *           <td class="descr">The value associated with the key</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The matched (key, value) pairs for the forecast</td>
 *   </tr>
 * </table>
 */
function cat_fcst_f(
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_location_id_mask       in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default null,
   p_valid_forecasts_only   in varchar2 default 'F',
   p_key_mask               in varchar2 default '*',
   p_value_mask             in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves a forecast (forecast time series and/or files)
 *
 * @param p_time_series_out    The forecast time series whose ts_ids matched p_ts_id_mask
 * @param p_files_out          The forecast files whose file names matched p_file_name_mask
 * @param p_fcst_spec_id       The forecast specification identifier (e.g. 'CAVI', 'RVF', etc)
 * @param p_location_id        The forecast specification location
 * @param p_forecast_date_time The forecast date/time
 * @param p_issue_date_time    The issue date/time of the forecast
 * @param p_time_zone          The time zone of the date/time parameters of of any returned time series. If unspecified or NULL, the location time zone is used.
 * @param p_unit_system        The unit system ('EN'/'SI') for any returned time series. If unspecified, 'SI' is used.
 * @param p_ts_id_mask         The wildcard pattern used to match time series to return, using glob-style ('*','?') wildcards and not sql-style ('%','_').
                               If unspecified, '*' is used. If NULL, no time series are returned.
 * @param p_file_name_mask     The wildcard pattern used to match file names to return, using glob-style ('*','?') wildcards and not sql-style ('%','_').
                               If unspecified, '*' is used. If NULL, no files are returned.
 * @param p_office_id          The office that owns the forecast
 *
 * @see type ztimeseries_array
 * @see type fcst_file_tab_t
 */
procedure retrieve_fcst(
   p_time_series_out    out nocopy ztimeseries_array,
   p_files_out          out nocopy fcst_file_tab_t,
   p_fcst_spec_id       in varchar2,
   p_location_id        in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2 default null,
   p_unit_system        in varchar2 default 'SI',
   p_ts_id_mask         in varchar2 default '*',
   p_file_name_mask     in varchar2 default '*',
   p_office_id          in varchar2 default null);
/**
 * Deletes forecast information
 *
 * @param p_fcst_spec_id       The forecast specification identifier to store the forecast for
 * @param p_location_id        The forecast specification location to store the forecast for
 * @param p_forecast_date_time The forecast date/time (context specific to forecast specification identifier)
 * @param p_issue_date_time    The issue date/time for the forecast
 * @param p_time_zone           The time zone of the forecast and issue date/times and of the time series. If not specified or NULL, the location's time zone is used.
 * @param p_ts_id_mask          in varchar2 default '*',
 * @param p_file_name_mask      in varchar2 default '*',
 * @param p_office_id           The office that owns the forecast specification. If not specified or NULL, the current user's office is used.
 */
procedure delete_fcst(
   p_fcst_spec_id        in varchar2,
   p_location_id         in varchar2,
   p_forecast_date_time  in date,
   p_issue_date_time     in date,
   p_time_zone           in varchar2 default null,
   p_ts_id_mask          in varchar2 default '*',
   p_file_name_mask      in varchar2 default '*',
   p_office_id           in varchar2 default null);

end;
/
