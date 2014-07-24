create or replace package cwms_xchg
/**
 * Facilities for working with Oracle/HEC-DSS Data Exhchange
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.0
 */
as
/**
 * Retrieves the status and real time operations queue names for an office
 *
 * @param p_status_queue_name   The name of the status queue
 * @param p_realtime_queue_name The name of the real time operations queue
 * @param p_office_id           The office that owns the queues. If not specified or NULL the session user's default office is used
 */
procedure get_queue_names(
   p_status_queue_name   out nocopy varchar2,
   p_realtime_queue_name out nocopy varchar2,
   p_office_id           in  varchar2 default null);
/**
 * Returns the datastore identifier of the CWMS database
 *
 * @return The datastore identifier of the CWMS database
 */
function db_datastore_id
   return varchar2;
/**
 * Parses a DSS pathname into its constituent parts
 *
 * @param p_a_pathname_part The A part
 * @param p_b_pathname_part The B part
 * @param p_c_pathname_part The C part
 * @param p_d_pathname_part The D part
 * @param p_e_pathname_part The E part
 * @param p_f_pathname_part The F part
 * @param p_pathname        The pathname to parse
 */
procedure parse_dss_pathname(
   p_a_pathname_part out nocopy varchar2,
   p_b_pathname_part out nocopy varchar2,
   p_c_pathname_part out nocopy varchar2,
   p_d_pathname_part out nocopy varchar2,
   p_e_pathname_part out nocopy varchar2,
   p_f_pathname_part out nocopy varchar2,
   p_pathname        in  varchar2);
/**
 * Returns whether an exchange set is marked for real time Oracle to DSS transfer
 *
 * @param p_ts_code The unique numeric code that identifies the exchagne set
 *
 * @return Whether the specified exchange set is marked for real time Oracle to DSS transfer
 */
function is_realtime_export(
   p_ts_code in integer)
   return boolean;
/**
 * Constructs a DSS pathname from its constituent parts
 *
 * @param p_a_pathname_part The A part
 * @param p_b_pathname_part The B part
 * @param p_c_pathname_part The C part
 * @param p_d_pathname_part The D part
 * @param p_e_pathname_part The E part
 * @param p_f_pathname_part The F part
 *
 * @return The resulting pathname
 */
function make_dss_pathname(
   p_a_pathname_part   in   varchar2,
   p_b_pathname_part   in   varchar2,
   p_c_pathname_part   in   varchar2,
   p_d_pathname_part   in   varchar2,
   p_e_pathname_part   in   varchar2,
   p_f_pathname_part   in   varchar2)
   return varchar2;
/**
 * Constructs a DSS time series identifier
 *
 * @param p_pathname        The DSS pathname
 * @param p_parameter_type  The DSS parameter type
 * @param p_units           The data unit
 * @param p_time_zone       The time zone
 * @param p_tz_usage        The time zone usage ('Standard', 'Daylight', or 'Local')
 *
 * @return the DSS time series identifier
 */
function make_dss_ts_id(
   p_pathname          in   varchar2,
   p_parameter_type    in   varchar2 default null,
   p_units             in   varchar2 default null,
   p_time_zone         in   varchar2 default null,
   p_tz_usage          in   varchar2 default null)
   return varchar2;
/**
 * Constructs a DSS time series identifier
 *
 * @param p_a_pathname_part The A part
 * @param p_b_pathname_part The B part
 * @param p_c_pathname_part The C part
 * @param p_d_pathname_part The D part
 * @param p_e_pathname_part The E part
 * @param p_f_pathname_part The F part
 * @param p_parameter_type  The DSS parameter type
 * @param p_units           The data unit
 * @param p_time_zone       The time zone
 * @param p_tz_usage        The time zone usage ('Standard', 'Daylight', or 'Local')
 *
 * @return the DSS time series identifier
 */
function make_dss_ts_id(
   p_a_pathname_part   in   varchar2,
   p_b_pathname_part   in   varchar2,
   p_c_pathname_part   in   varchar2,
   p_d_pathname_part   in   varchar2,
   p_e_pathname_part   in   varchar2,
   p_f_pathname_part   in   varchar2,
   p_parameter_type    in   varchar2 default null,
   p_units             in   varchar2 default null,
   p_time_zone         in   varchar2 default null,
   p_tz_usage          in   varchar2 default null)
   return varchar2;
/**
 * Deletes a data exchange set from the database
 *
 * @param p_dss_xchg_set_id The exchange set identifier
 * @param p_office_id       The office that owns the exchange set. If not specified or NULL, the session user's default office will be used.
 */
procedure delete_dss_xchg_set(
   p_dss_xchg_set_id   in   varchar2,
   p_office_id         in   varchar2 default null);
/**
 * Renames an existing data exchange set in the database
 *
 * @param p_old_xchg_set_id The existing exchange set identifier
 * @param p_new_xchg_set_id The new exchange set identifier
 * @param p_office_id       The office that owns the exchange set. If not specified or NULL, the session user's default office will be used.
 */
procedure rename_dss_xchg_set(
   p_old_xchg_set_id       in   varchar2,
   p_new_xchg_set_id   in   varchar2,
   p_office_id             in   varchar2 default null);
/**
 * Duplicates an existing data exchange set in the database
 *
 * @param p_old_xchg_set_id The existing exchange set identifier
 * @param p_new_xchg_set_id The new exchange set identifier
 * @param p_office_id       The office that owns the exchange set. If not specified or NULL, the session user's default office will be used.
 */
procedure duplicate_dss_xchg_set(
   p_old_xchg_set_id   in   varchar2,
   p_new_xchg_set_id   in   varchar2,
   p_office_id         in   varchar2 default null);
/**
 * Updates the last-update-time of an exchange set
 *
 * @param p_xchg_set_code The unique numeric code that identifies the exhcange set
 * @param p_last_update   The last update time in UTC
 */
procedure update_dss_xchg_set_time(
   p_xchg_set_code    in  number,
   p_last_update          in  timestamp);
/**
 * Retrieves exchage sets that match specified parameters. Matching is
 * accomplished with glob-style wildcards, as shown below. SQL-style wildcards can also be used.
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
 * @param p_dss_filemgr_url Reserved for future use. Not used.
 *
 * @param p_dss_file_name   Reserved for future use. Not used.
 *
 * @param p_dss_xchg_set_id Data exchange set identifier pattern to match. Use glob-style
 * wildcard characters as shown above. If not specified or NULL, all data exchange sets for the specified office will be retrieved
 *
 * @param p_office_id  The office pattern to match.  If the routine is called
 * without this parameter, or if this parameter is set to NULL, the session user's
 * default office will be used. For matching multiple office, use glob-style
 * wildcard characters as shown above.
 *
 * @return The matching data exchange sets in XML format
 */
function get_dss_xchg_sets(
   p_dss_filemgr_url in varchar2 default null,
   p_dss_file_name   in varchar2 default null,
   p_dss_xchg_set_id in varchar2 default null,
   p_office_id       in varchar2 default null)
   return clob;
/**
 * Store a data exchange configuration
 *
 * @param p_sets_inserted     The number of data exchange sets that were inserted
 * @param p_sets_updated      The number of data exchange sets that were updated
 * @param p_mappings_inserted The number of time series mappings that were inserted
 * @param p_mappings_updated  The number of time series mappings that were updated
 * @param p_mappings_deleted  The number of time series mappings that were deleted
 * @param p_dx_config         The data exchange configuration in XML format
 * @param p_store_rule        The store rule to use ('MERGE', 'INSERT', 'UPDATE', 'REPLACE').  If not specified or NULL, MERGE is used
 */
procedure store_dataexchange_conf(
   p_sets_inserted     out number,
   p_sets_updated      out number,
   p_mappings_inserted out number,
   p_mappings_updated  out number,
   p_mappings_deleted  out number,
   p_dx_config         in  clob,
   p_store_rule        in  varchar2 default 'MERGE');
/**
 * Deletes un-referenced data exchange information from the database
 */
procedure del_unused_dss_xchg_info(
   p_office_id in varchar2 default null);
/**
 * Marks the data exchange configuration as being updated. The DSSFileManager servers
 * at the specified URLs are notified.
 *
 * @param p_urls_affected A comma-separated list of all DSSFileManager URLs that are affected by the update
 */
procedure xchg_config_updated(
   p_urls_affected in varchar2);
/**
 * Updates the last-processed time of a data exchange set
 *
 * @param p_engine_url  The URL of the DSSFileManager that processed the set
 * @param p_xchg_code   The unique numeric code identifying the data exchange set
 * @param p_update_time The last-processed time in java milliseconds
 */
procedure update_last_processed_time (
   p_engine_url  in varchar2,
   p_xchg_code   in integer,
   p_update_time in integer);
/**
 * Updates the last-processed time of a data exchange set
 *
 * @param p_engine_url  The URL of the DSSFileManager that processed the set
 * @param p_xchg_set_id The data exchange set identifier
 * @param p_update_time The last-processed time in java milliseconds
 * @param p_office_id   The office that owns the data exchange set. If not specified or NULL, the session user's default office is used
 */
procedure update_last_processed_time (
   p_engine_url   in varchar2,
   p_xchg_set_id  in varchar2,
   p_update_time  in integer,
   p_office_id    in varchar2 default null);
/**
 * Requests a replay of data messages for a specified exchange set and time window
 *
 * @param p_component   The CWMS component requesting the message replay
 * @param p_host        The host address on which the requesting component is executing
 * @param p_xchg_set_id The exchange set idenifier to replay messages for
 * @param p_start_time  The start of the time window
 * @param p_end_time    The end of the time window
 * @param p_request_id  A unique identifier for the request.  If not specified or NULL, a new unique identifier will be generated
 * @param p_office_id   The office that owns the data exchange set. If not specified or NULL, the session user's default office will be used.
 *
 * @return The (specified or generated) request identifier
 */
function replay_data_messages(
   p_component   in varchar2,
   p_host        in varchar2,
   p_xchg_set_id in varchar2,
   p_start_time  in integer  default null,
   p_end_time    in integer  default null,
   p_request_id  in varchar2 default null,
   p_office_id   in varchar2 default null)
   return varchar2;
/**
 * Request that real time Oracle to DSS transfers be restarted for a specified DSSFileManager
 *
 * @param p_engine_url The URL of the requesting DSSFileManager server
 *
 * @return A comma-separated list of request identifiers. The identifiers, one per data exchange set managed
 * by the specified DSSFileManager server, are returned from <a href="#replay_data_messages>replay_data_messages</a>
 */
function restart_realtime(
   p_engine_url in varchar2)
   return varchar2;
/**
 * Requests a batch data exchange
 *
 * @param p_component        The CWMS component requesting the batch exchange
 * @param p_host             The host address on which the requsting component is executing
 * @param p_set_id           The data exchange set identifier to use
 * @param p_dst_datastore_id The destination data store for the exchange
 * @param p_start_time       The start of the time window un UTC
 * @param p_end_time         The end of the time window in UTC
 * @param p_office_id        The office that owns the data exchange set. If not specified or NULL, the session user's default office is used.
 *
 * @return A unique identifier for the batch exchange job
 */
function request_batch_exchange(
   p_component        in varchar2,
   p_host             in varchar2,
   p_set_id           in varchar2,
   p_dst_datastore_id in varchar2,
   p_start_time       in integer,
   p_end_time         in integer  default null,
   p_office_id        in varchar2 default null)
   return varchar2;
/**
 * Retrieves information about a specified datastore from the database
 *
 * @param p_datastore_code  The unique numeric code identifying the datastore
 * @param p_dss_filemgr_url The URL of the DSSFileManager server for the datastore
 * @param p_dss_file_name   The name of the DSS file for the datastore
 * @param p_description     A description of the datastore
 * @param p_datastore_id    The datastore identifier
 * @param p_office_id       The office that owns the datastore. If not specified or NULL, the session user's default office is used.
 */
procedure retrieve_dss_datastore(
   p_datastore_code  out number,                            
   p_dss_filemgr_url out nocopy varchar2,
   p_dss_file_name   out nocopy varchar2,
   p_description     out nocopy varchar2,
   p_datastore_id    in  varchar2,                                
   p_office_id       in  varchar2 default null);
/**
 * Stores a datastore to the database
 *
 * @param p_datastore_code  The unique numeric code identifying the datastore
 * @param p_datastore_id    The datastore identifier
 * @param p_dss_filemgr_url The URL of the DSSFileManager server for the datastore
 * @param p_dss_file_name   The name of the DSS file for the datastore
 * @param p_description     A description of the datastore
 * @param p_fail_if_exists  A flag ('T' or 'F') that specifies whether the routine should fail if the datastore already exists in the database
 * @param p_office_id       The office that owns the datastore. If not specified or NULL, the session user's default office is used.
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the datastore already exists in the database
 */
procedure store_dss_datastore(
   p_datastore_code  out number,                            
   p_datastore_id    in  varchar2,                                
   p_dss_filemgr_url in  varchar2,
   p_dss_file_name   in  varchar2,
   p_description     in  varchar2 default null,
   p_fail_if_exists  in  varchar2 default 'T',
   p_office_id       in  varchar2 default null);
/**
 * Retrieves a data exchange set from the database
 *
 * @param p_xchg_set_code The unique numeric code identifying the data exchange set
 * @param p_datastore_id  The datastore identifier of the data exchange set
 * @param p_description   A description of the data exchange set
 * @param p_start_time    Parameterized or explicit start of default time window for data exchange set
 * @param p_end_time      Parameterized or explicit end of default time window for data exchange set
 * @param p_interp_count  Maximum number of intervals or minutes over which to interpolate for missing data
 * @param p_interp_units  Specifies whether p_interp_count refers to intervals or minutes
 * @param p_realtime_dir  Specifies the real time data exchange direction, if any
 * @param p_last_update   Specifies thea last time the data exchange set has been updated
 * @param p_xchg_set_id   The data exchange set identifer
 * @param p_office_id     The office that owns the data exchanage set.  If not specified or NULL, the session user's default office is used
 */
procedure retrieve_xchg_set(
   p_xchg_set_code out number,
   p_datastore_id  out nocopy varchar2,
   p_description   out nocopy varchar2,
   p_start_time    out nocopy varchar2,
   p_end_time      out nocopy varchar2,
   p_interp_count  out number,
   p_interp_units  out nocopy varchar2,
   p_realtime_dir  out nocopy varchar2,
   p_last_update   out timestamp,
   p_xchg_set_id   in  varchar2,
   p_office_id     in  varchar2 default null);
/**
 * Retrieves a data exchange set from the database
 *
 * @param p_xchg_set_code  The unique numeric code identifying the data exchange set
 * @param p_xchg_set_id    The data exchange set identifer
 * @param p_datastore_id   The datastore identifier of the data exchange set
 * @param p_description    A description of the data exchange set
 * @param p_start_time     Parameterized or explicit start of default time window for data exchange set
 * @param p_end_time       Parameterized or explicit end of default time window for data exchange set
 * @param p_interp_count   Maximum number of intervals or minutes over which to interpolate for missing data
 * @param p_interp_units   Specifies what p_interp_count refers to. Valid values are <ul><li>'Intervals'</li><li>'Minutes'</li></ul>
 * @param p_realtime_dir   Specifies the real time data exchange direction, if any. Valid values are <ul><li>'DssToOracle'</li><li>'OracleToDss'</li></ul>
 * @param p_fail_if_exists A flag ('T' or 'F') that specifies whether the routine should fail if the data exchange set already exists is the database
 * @param p_office_id      The office that owns the data exchanage set.  If not specified or NULL, the session user's default office is used
 *
 * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the data exchange set already exists is the database
 */
procedure store_xchg_set(
   p_xchg_set_code  out number,
   p_xchg_set_id    in  varchar2,
   p_datastore_id   in  varchar2,
   p_description    in  varchar2 default null,
   p_start_time     in  varchar2 default null,
   p_end_time       in  varchar2 default null,
   p_interp_count   in  integer  default null,
   p_interp_units   in  varchar2 default null, -- Intervals or Minutes
   p_realtime_dir   in  varchar2 default null, -- DssToOracle or OracleToDss
   p_fail_if_exists in  varchar2 default 'T',  -- T or F
   p_office_id      in  varchar2 default null);
/**
 * Retrieves a time series mapping for a CWMS time series in a data exchange set
 *
 * @param p_mapping_code    The unique numeric code identifying the time series mapping
 * @param p_a_pathname_part The DSS A pathname part
 * @param p_b_pathname_part The DSS B pathname part
 * @param p_c_pathname_part The DSS C pathname part
 * @param p_e_pathname_part The DSS E pathname part
 * @param p_f_pathname_part The DSS F pathname part
 * @param p_parameter_type  The DSS parameter type
 * @param p_units           The DSS units
 * @param p_time_zone       The DSS time zone
 * @param p_tz_usage        The DSS time zone usage
 * @param p_xchg_set_code   The unique numeric code identifying the data exchange set
 * @param p_cwms_ts_code    The unique numeric code identifying the CWMS time series
 */
procedure retrieve_xchg_dss_ts_mapping(
   p_mapping_code    out number,
   p_a_pathname_part out nocopy varchar2,
   p_b_pathname_part out nocopy varchar2,
   p_c_pathname_part out nocopy varchar2,
   p_e_pathname_part out nocopy varchar2,
   p_f_pathname_part out nocopy varchar2,
   p_parameter_type  out nocopy varchar2,
   p_units           out nocopy varchar2,
   p_time_zone       out nocopy varchar2,
   p_tz_usage        out nocopy varchar2,
   p_xchg_set_code   in  number,
   p_cwms_ts_code    in  number);
/**
 * Retrieves a time series mapping for a CWMS time series in a data exchange set
 *
 * @param p_mapping_code    The unique numeric code identifying the time series mapping
 * @param p_xchg_set_code   The unique numeric code identifying the data exchange set
 * @param p_cwms_ts_code    The unique numeric code identifying the CWMS time series
 * @param p_a_pathname_part The DSS A pathname part
 * @param p_b_pathname_part The DSS B pathname part
 * @param p_c_pathname_part The DSS C pathname part
 * @param p_e_pathname_part The DSS E pathname part
 * @param p_f_pathname_part The DSS F pathname part
 * @param p_parameter_type  The DSS parameter type
 * @param p_units           The DSS units
 * @param p_time_zone       The DSS time zone
 * @param p_tz_usage        The DSS time zone usage
 * @param p_fail_if_exists  A flag ('T' or 'F') specifying whether the routine should fail if the time series mapping already exists
 */
procedure store_xchg_dss_ts_mapping(
   p_mapping_code    out number,
   p_xchg_set_code   in  number,
   p_cwms_ts_code    in  number,
   p_a_pathname_part in  varchar2,
   p_b_pathname_part in  varchar2,
   p_c_pathname_part in  varchar2,
   p_e_pathname_part in  varchar2,
   p_f_pathname_part in  varchar2,
   p_parameter_type  in  varchar2,
   p_units           in  varchar2,
   p_time_zone       in  varchar2 default 'UTC',
   p_tz_usage        in  varchar2 default 'Standard',
   p_fail_if_exists  in  varchar2 default 'T');

end cwms_xchg;
/
commit;
show errors;
