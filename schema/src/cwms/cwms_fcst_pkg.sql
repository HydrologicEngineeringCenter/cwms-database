create or replace package cwms_fcst
/**
 * Routines for storing and retrieving forecast information. Replaces package cwms_forecast.
 */
as
/**
 * Stores (inserts or updates) a forecast specification
 *
 * @param p_fcst_spec_id    The "main name" of the forecast. Must be non-null
 * @param p_fcst_designator The "sub-name" of the foreast specification if necessary
 * @param p_entity_id       The agency/office that generates forecasts for this specification. Must match an entity in the
 *                          AT_ENTITY table.
 * @param p_description     A description of the forecast specification. If unspecified or NULL no description is used.
 * @param p_location_id     The primary location associated with forecast specification (e.g., project, basin, control point).
 *                          If unspecified or NULL no location will be associated.
 * @param p_timeseries_ids  A list of time series IDs that are stored for this forecast specification separated by newline
 *                          characters ("\n")
 *                          If unspecified or NULL no time series will be associated with the forecast specification until
 *                          actual time series are stored.
 * @param p_fail_if_exists  A flag ('T'/'F') that specifies whether to raise an exception if this specification already
 *                          exists. If unspecified, 'T' will be used.
 * @param p_ignore_nulls    A flag ('T'/'F') that specifies whether NULL values for p_description, p_location_id, and
 *                          p_timeseries_ids will be ignored if updating an existing specification. If 'T', existing values
 *                          for these parameters will not be modified on update. If 'F', NULL values for any of these
 *                          parameters will cause existing values to be deleted.
 * @param p_office_id       The office that owns the forecast specification. If unspecified or NULL, the session user's
 *                          current office will be used.
 */
procedure store_fcst_spec(
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2,
   p_entity_id       in varchar2,
   p_description     in varchar2 default null,
   p_location_id     in varchar2 default null,
   p_timeseries_ids  in clob     default null,
   p_fail_if_exists  in varchar2 default 'T',
   p_ignore_nulls    in varchar2 default 'T',
   p_office_id       in varchar2 default null);
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
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The the forecast designator</td>
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
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">A description of the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">time_series_ids</td>
 *     <td class="descr">sys_refcursor containing a single varchar2(193) column named time_series_id</td>
 *     <td class="descr">The time series ids stored for the forecast</td>
 *   </tr>
 * </table>
 * @param p_fcst_spec_id_mask    The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all
 *                               forecast_specification identifiers will be matched.
 * @param p_fcst_designator_mask The wildcard pattern to retrieve forecast specification locations for. If unspecified, all
 *                               forecast specification locations will be matched. Specify NULL to match forecast specifications
 *                               without designators.
 * @param p_entity_id_mask       The wildcard pattern to retrieve entities for. If unspecified, all entities will be matched.
 * @param p_office_id_mask       The wildcard pattern to retrieve offices for. If unspecified or NULL the session user's current
 *                               office will be used.
 */
procedure cat_fcst_spec(
   p_cursor               out sys_refcursor,
   p_fcst_spec_id_mask    in varchar2 default '*',
   p_fcst_designator_mask in varchar2 default '*',
   p_entity_id_mask       in varchar2 default '*',
   p_office_id_mask       in varchar2 default null);
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
 * @param p_fcst_spec_id_mask    The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all
 *                               forecast_specification identifiers will be matched.
 * @param p_fcst_designator_mask The wildcard pattern to retrieve forecast specification locations for. If unspecified, all
 *                               forecast specification locations will be matched. Specify NULL to match forecast specifications
 *                               without designators.
 * @param p_entity_id_mask       The wildcard pattern to retrieve entities for. If unspecified, all entities will be matched.
 * @param p_office_id_mask       The wildcard pattern to retrieve offices for. If unspecified or NULL the session user's current
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
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">location_id</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The the forecast designator</td>
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
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">A description of the forecast specification</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">7</td>
 *     <td class="descr">time_series_ids</td>
 *     <td class="descr">sys_refcursor containing a single varchar2(193) column named time_series_id</td>
 *     <td class="descr">The time series ids stored for the forecast</td>
 *   </tr>
 * </table>
 */
function cat_fcst_spec_f(
   p_fcst_spec_id_mask    in varchar2 default '*',
   p_fcst_designator_mask in varchar2 default '*',
   p_entity_id_mask       in varchar2 default '*',
   p_office_id_mask       in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves information about a forecast specification
 *
 * @param p_entity_id       The agency/office that generates forecasts for this specification
 * @param p_desccription    The description of the forecast specification
 * @param p_location_id     The primary location associated with the forecast specification
 * @param p_timeseries_ids  The time series stored for this forecast specification, sorted lexically and separated by newline
 *                          characters ("\n")
 * @param p_fcst_spec_id    The "main name" of the forecast. Must be non-null
 * @param p_fcst_designator The "sub-name" of the foreast specification if necessary. If unspecified or NULL no designator is used.
 * @param p_office_id       The office that owns the forecast specification. If unspecified or NULL, the session user's
 *                          current office will be used.
 */
procedure retrieve_fcst_spec(
   p_entity_id       out varchar2,
   p_description     out varchar2,
   p_location_id     out varchar2,
   p_timeseries_ids  out nocopy clob,
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2 default null,
   p_office_id       in varchar2 default null);
/**
 * Deletes a forecast specification and/or all instances.
 *
 * @param p_fcst_spec_id    The forecast specification identifier to delete information for
 * @param p_fcst_designator The forecast designator to delete information for
 * @param p_delete_action   Specifies what to delete.  Actions are as follows:
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
   p_fcst_spec_id    in varchar2,
   p_fcst_designator in varchar2,
   p_delete_action   in varchar2,
   p_office_id       in varchar2 default null);
/**
 * Store (creates or updates) a forecast (forecast time series and/or files)
 *
 * @param p_fcst_spec_id       The forecast specification identifier to store the forecast for
 * @param p_fcst_designator    The forecast designator to store the forecast for
 * @param p_forecast_date_time The forecast date/time (context specific to forecast specification identifier)
 * @param p_issue_date_time    The issue date/time for the forecast
 * @param p_time_zone          The time zone of the forecast and issue date/times
 * @param p_max_age            The number of hours after p_issue_date_time that the forcast is valid
 * @param p_notes              Any notes specific to the forecast
 * @param p_fcst_info          A valid JSON object of key/value pairs for the forecast. It is recommended to include keys named
 *                             "startTime" and "endTime" with values in ISO 8601 format to indicate the bounding time window of any
 *                             time series stored for the forecast. Having this information available can improve the performance of
 *                             cataloging or retrieving the forecast time series.
 * @param p_fcst_file          The forecast file. If unspecified or null, no forecast file is stored.
 * @param p_fail_if_exists     A flag ('T'/'F') specifying whether to raise an exception if the forecast already exists
 * @param p_ignore_nulls       A flag ('T'/'F') specifying NULL values for the parameters p_max_age, p_notes, and p_fcst_info
 *                             should be ignored on update. If 'T', then existing data for these parametrs is not modified
 *                             if the value is NULL. If 'F', a NULL value for any of these parameters will cause the existing data
 *                             to be deleted.
 * @param p_office_id          The office that owns the forecast specification. If not specified or NULL, the current user's office is used.
 *
 * @see type ztimeseries_array
 * @see type fcst_file_tab_t
 */
procedure store_fcst(
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2,
   p_max_age            in binary_integer default null,
   p_notes              in varchar2       default null,
   p_fcst_info          in varchar2       default null,
   p_fcst_file          in blob_file_t    default null,
   p_fail_if_exists     in varchar2       default 'T',
   p_ignore_nulls       in varchar2       default 'T',
   p_office_id          in varchar2       default null);
/**
 * Stores a forecast file to an existing forecast instance
 *
 * @param p_fcst_spec_id       The forecast specification identifier to store the forecast for
 * @param p_fcst_designator    The forecast designator to store the forecast for
 * @param p_forecast_date_time The forecast date/time (context specific to forecast specification identifier)
 * @param p_issue_date_time    The issue date/time for the forecast
 * @param p_time_zone          The time zone of the forecast and issue date/times
 * @param p_fcst_file          The forecast file. Set this to NULL to delete an existing forecast file
 * @param p_fail_if_exists     A flag ('T'/'F') specifying whether to raise an exception if the forecast already file exists
 * @param p_office_id          The office that owns the forecast specification. If not specified or NULL, the current user's office is used.
 */
procedure store_fcst_file(
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2,
   p_fcst_file          in blob_file_t,
   p_fail_if_exists     in varchar2     default 'T',
   p_office_id          in varchar2     default null);
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
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">fcst_designator</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The forecast desigator</td>
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
 *     <td class="descr">max_age</td>
 *     <td class="descr">number(6)</td>
 *     <td class="descr">The number of hours after the issue date/time that the forecast is valid</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">valid</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag ('T'/'F') specifying whether the forecast was valid at the time of the catalog</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">notes</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The notes specific to the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">file_name</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The name of the forecast file, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">file_size</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The size of the forecast file, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">file_media_type</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The media type of the forecast file, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
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
 *           <td class="descr">varchar2(32767)</td>
 *           <td class="descr">The key</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">value</td>
 *           <td class="descr">varchar2(32767)</td>
 *           <td class="descr">The value associated with the key</td>
 *         </tr>
 *       </table>
 *     </td>
 *     <td class="descr">The matched (key, value) pairs for the forecast</td>
 *   </tr>
 * </table>
 * @param p_fcst_spec_id_mask      The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all
 *                                 forecast_specification identifiers will be matched.
 * @param p_fcst_designator_mask   The wildcard pattern to retrieve forecast designators for. If unspecified, all forecast
 *                                 specification locations will be matched. Specify NULL to catalog forecasts without designator.
 * @param p_min_forecast_date_time The earliest forecast date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_forecast_date_time The latest forecast date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_min_issue_date_time    The earliest issue date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_issue_date_time    The latest issue date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_time_zone              The time zone of the min and max date/times and date/times returned in the cursor.
 *                                 If unspecified 'UTC' will be used.
 * @param p_valid_forecasts_only   A flag ('T'/'F') specifying whether to catalog only valid or all forecasts. Valid forecasts have
 *                                 issue date/times since the current date/time minus max_age hours.
 * @param p_key_mask               The wildcard pattern that the key field in returned records must match. If unspecified, all key
 *                                 fields will be matched
 * @param p_value_mask             The wildcard pattern that the value field in returned records must match. If unspecified, all
 *                                 value fields will be matched.
 * @param p_office_id_mask         The wildcard pattern to retrieve offices for. If unspecified or NULL, the session user's current
 *                                 office will be used.
 */
procedure cat_fcst(
   p_cursor                 out sys_refcursor,
   p_fcst_spec_id_mask      in varchar2 default '*',
   p_fcst_designator_mask   in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default 'UTC',
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
 * @param p_fcst_spec_id_mask      The wildcard pattern to retrieve forecast specifications identifieres for. If unspecified all
 *                                 forecast_specification identifiers will be matched.
 * @param p_fcst_designator_mask   The wildcard pattern to retrieve forecast designators for. If unspecified, all forecast
 *                                 specification locations will be matched. Specify NULL to catalog forecasts without designator.
 * @param p_min_forecast_date_time The earliest forecast date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_forecast_date_time The latest forecast date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_min_issue_date_time    The earliest issue date/time to match. If unspecified or NULL, no minimum will be used.
 * @param p_max_issue_date_time    The latest issue date/time to match. If unspecified or NULL, no maximum will be used.
 * @param p_time_zone              The time zone of the min and max date/times and date/times returned in the cursor.
 *                                 If unspecified 'UTC' will be used.
  * @param p_valid_forecasts_only   A flag ('T'/'F') specifying whether to catalog only valid or all forecasts. Valid forecasts have
 *                                 issue date/times since the current date/time minus max_age hours.
 * @param p_key_mask               The wildcard pattern that the key field in returned records must match. If unspecified, all key
 *                                 fields will be matched
 * @param p_value_mask             The wildcard pattern that the value field in returned records must match. If unspecified, all
 *                                 value fields will be matched.
 * @param p_office_id_mask         The wildcard pattern to retrieve offices for. If unspecified or NULL, the session user's current
 *                                 office will be used.
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
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The forecast specification identifier</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">3</td>
 *     <td class="descr">fcst_designator</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The forecast desigator</td>
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
 *     <td class="descr">max_age</td>
 *     <td class="descr">number(6)</td>
 *     <td class="descr">The number of hours after the issue date/time that the forecast is valid</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">8</td>
 *     <td class="descr">valid</td>
 *     <td class="descr">varchar2(1)</td>
 *     <td class="descr">A flag ('T'/'F') specifying whether the forecast was valid at the time of the catalog</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">9</td>
 *     <td class="descr">notes</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The notes specific to the forecast</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">10</td>
 *     <td class="descr">file_name</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The name of the forecast file, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">11</td>
 *     <td class="descr">file_size</td>
 *     <td class="descr">integer</td>
 *     <td class="descr">The size of the forecast file, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">12</td>
 *     <td class="descr">file_media_type</td>
 *     <td class="descr">varchar2(256)</td>
 *     <td class="descr">The media type of the forecast file, if any</td>
 *   </tr>
 *   <tr>
 *     <td class="descr-center">13</td>
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
 *           <td class="descr">varchar2(32767)</td>
 *           <td class="descr">The key</td>
 *         </tr>
 *         <tr>
 *           <td class="descr-center">2</td>
 *           <td class="descr">value</td>
 *           <td class="descr">varchar2(32767)</td>
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
   p_fcst_designator_mask   in varchar2 default '*',
   p_min_forecast_date_time in date     default null,
   p_max_forecast_date_time in date     default null,
   p_min_issue_date_time    in date     default null,
   p_max_issue_date_time    in date     default null,
   p_time_zone              in varchar2 default 'UTC',
   p_valid_forecasts_only   in varchar2 default 'F',
   p_key_mask               in varchar2 default '*',
   p_value_mask             in varchar2 default '*',
   p_office_id_mask         in varchar2 default null)
   return sys_refcursor;
/**
 * Retrieves a forecast (forecast time series and/or files)
 *
 * @param p_max_age            The number of hours after p_issue_date_time that the forcast is valid
 * @param p_notes              Any notes specific to the forecast
 * @param p_fcst_info          A valid JSON object of key/value pairs for the forecast
 * @param p_has_file           A flag ('T'/'F') specifying whether a forecast file is stored for the forecast
 * @param p_timeseries_ids     The time series stored for this forecast, sorted lexically and separated by newline characters ("\n")
 * @param p_fcst_file          The forecast file
 * @param p_fcst_spec_id       The forecast specification identifier to retrieve the forecast for
 * @param p_fcst_designator    The forecast designator to retrieve the forecast for
 * @param p_forecast_date_time The forecast date/time
 * @param p_issue_date_time    The issue date/time of the forecast
 * @param p_time_zone          The time zone of the date/time parameters. If unspecified, 'UTC' is used.
 * @param p_retrieve_file      A flag ('T'/'F') specifying whther to retrieve the forecast file, if any. If unspecified the forecast
 *                             file will not be retrieved
 * @param p_office_id          The office that owns the forecast
 *
 * @see type ztimeseries_array
 * @see type fcst_file_tab_t
 */
procedure retrieve_fcst(
   p_max_age            out binary_integer,
   p_notes              out varchar2,
   p_fcst_info          out varchar2,
   p_has_file           out varchar2,
   p_timeseries_ids     out nocopy clob,
   p_fcst_file          out blob_file_t,
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2 default 'UTC',
   p_retrieve_file      in varchar2 default 'F',
   p_office_id          in varchar2 default null);
/**
 * Retrieves a forecast file to a forecast instance
 *
 * @param p_fcst_file          The forecast file
 * @param p_fcst_spec_id       The forecast specification identifier to store the forecast for
 * @param p_fcst_designator    The forecast designator to store the forecast for
 * @param p_forecast_date_time The forecast date/time (context specific to forecast specification identifier)
 * @param p_issue_date_time    The issue date/time for the forecast
 * @param p_time_zone          The time zone of the forecast and issue date/times
 * @param p_office_id          The office that owns the forecast specification. If not specified or NULL, the current user's office is used.
 */
procedure retrieve_fcst_file(
   p_fcst_file          out blob_file_t,
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2,
   p_office_id          in varchar2     default null);
/**
 * Deletes forecast information
 *
 * @param p_fcst_spec_id       The "main name" of the forecast. Must be non-null
 * @param p_fcst_designator    The "sub-name" of the foreast specification if necessary
 * @param p_forecast_date_time The forecast date/time
 * @param p_issue_date_time    The issue date/time for the forecast
 * @param p_time_zone          The time zone of the date/time parameters. If unspecified or NULL, 'UTC' is used.
 * @param p_office_id          The office that owns the forecast
 */
procedure delete_fcst(
   p_fcst_spec_id       in varchar2,
   p_fcst_designator    in varchar2,
   p_forecast_date_time in date,
   p_issue_date_time    in date,
   p_time_zone          in varchar2 default 'UTC',
   p_office_id          in varchar2 default null);

end;
/
