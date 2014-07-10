set define off
create or replace package cwms_usgs
/**
 * Facilities for retrieving data from USGS 
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.2
 */
as

/**
 * URL for retrieving instantaneous value time series data from USGS NWIS for a period ending at current time
 * @see http://waterservices.usgs.gov/rest/IV-Service.html
 */
realtime_ts_url_period constant varchar2(109) := 'http://waterservices.usgs.gov/nwis/iv/?format=<format>&period=<period>&parameterCd=<parameters>&sites=<sites>';
/**
 * URL for retrieving instantaneous value time series data from USGS NWIS for specified start and end dates
 * @see http://waterservices.usgs.gov/rest/IV-Service.html
 */
realtime_ts_url_dates  constant varchar2(121) := 'http://waterservices.usgs.gov/nwis/iv/?format=<format>&startDT=<start>&endDT=<end>&parameterCd=<parameters>&sites=<sites>';
/**
 * Maximum number of sites that can be requested at once from USGS NWIS
 */
max_sites constant integer := 100;
/**
 * CWMS Properties ID for specifying run interval in minutes for automatic instantaneous value time series retrieval job. Job doesn't run if property is not set. Property category is 'USGS'. Property value is integer.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_ts_interval
 * @see get_auto_ts_interval
 */
auto_ts_interval_prop constant varchar2(28) := 'timeseries_retrieve_interval';
/**
 * CWMS Properties ID for text filter for determining locations for which to retrieve instantaneous value time series data from USGS NWIS. No time series are retrieved if property is not set. Property category is 'USGS'.
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_ts_filter_id
 * @see get_auto_ts_filter_id
 */
auto_ts_filter_prop constant varchar2(27) := 'timeseries_locations_filter';
/**
 * CWMS Properties ID for specifying lookback period when retrieving instantaneous value time series from USGS NWIS. Property value is in ISO 8601 duration format. If property is not set, default period is PT4H (4 hours).
 * May be managed using CWMS_PROPERTIES package or by routines in this package.
 *
 * @see package cwms_properties
 * @see set_auto_ts_period
 * @see get_auto_ts_period
 */
auto_ts_period_prop constant varchar2(26) := 'timeseries_retrieve_period';
/**
 * Sets the text filter used to determine locations for which to retrieve instantaneous value time series data from USGS NWIS.
 *
 * @param p_text_filter_id The text filter to use to determine location for which to retrieve time series data. 
 * @param p_office_id      The office to set the text filter for. If NULL or not specified, the session user's default office is used.
 *
 * @see constant auto_ts_filter_prop
 */
procedure set_auto_ts_filter_id(
   p_text_filter_id in varchar2,
   p_office_id      in varchar2 default null);
/**
 * Retrieves the text filter used to determine locations for which to retrieve instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id The office that owns the text filter. If NULL or not specified, the session user's default office is used.
 * @return The text filter to use to determine location for which to retrieve time series data. 
 *
 * @see constant auto_ts_filter_prop
 */
function get_auto_ts_filter_id(
   p_office_id in varchar2 default null)
   return varchar2;
/**
 * Sets the lookback period to use for retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_period     The period in minutes to use for retrieving time series data from USGS NWIS 
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *                                        
 * @see constant auto_ts_period_prop
 */
procedure set_auto_ts_period(
   p_period    in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the lookback period in minutes to use for retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id  The office to get the period for. If NULL or not specified, the session user's default office is used.
 * @return             The period in minutes to use for retrieving time series data from USGS NWIS 
 *                                        
 * @see constant auto_ts_period_prop
 */
function get_auto_ts_period(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Sets the run interval for automatically retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_interval   The run interval in minutes for automaticcally retrieving time series data from USGS NWIS. 
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 *                                        
 * @see constant auto_ts_interval_prop
 */
procedure set_auto_ts_interval(
   p_interval  in integer,
   p_office_id in varchar2 default null);
/**
 * Retrieves the run interval for automatically retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id  The office to set the period for. If NULL or not specified, the session user's default office is used.
 * @return             The run interval in minutes for automatically retrieving time series data from USGS NWIS. 
 *                                        
 * @see constant auto_ts_interval_prop
 */
function get_auto_ts_interval(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Retrieves the list of locations that will be processed for a specified parameter. This function uses a text filter with a
 * name based on the one returned by get_auto_ts_filter_id function; it has a five-character parameter as a suffix. For example,
 * if the main text filter is named USGS_Auto_TS, the text filter for USGS parameter 65 would be USGS_Auto_TS.00065.
 *
 * @param p_parameter The USGS parameter to retrieve the locations for, specified as an integer.
 * @param p_office_id The office to retrieve locations for. If NULL or not spcecified, the session user's default office is used.
 *
 * @see get_auto_ts_filter_id
 */   
function get_auto_ts_locations(
   p_parameter in integer,
   p_office_id in varchar2 default null)
   return str_tab_t;   
/**
 * Retrieves the list of locations whose instantaneous value time series will be retrieved from the USGS NWIS.
 *
 * @param p_office_id The office to retrieve locations for. If NULL or not spcecified, the session user's default office is used.
 *
 * @see get_auto_ts_filter_id
 */   
function get_auto_ts_locations(
   p_office_id in varchar2 default null)
   return str_tab_t;   
/**
 * Retrieves the USGS parameters that will be processed when retrieving instantaneous value time series data from USGS NWIS.
 *
 * @param p_office_id The office to retrieve parameters for. If NULL or not spcecified, the session user's default office is used.
 * @return      The USGS parameters as a table of integers.
 */                        
function get_parameters(
   p_office_id in varchar2 default null)
   return number_tab_t;   
/**
 * Retrieves the USGS parameters that will be processed when retrieving instantaneous value time series data for a specified site from USGS NWIS.
 *                                
 * @param p_usgs_id   The USGS site name (station number) to retrieve the parameters for   
 * @param p_office_id The office to retrieve parameters for. If NULL or not spcecified, the session user's default office is used.
 * @return The USGS parameters as a table of integers.
 */                        
function get_parameters(
   p_usgs_id   in varchar2,
   p_office_id in varchar2)
   return number_tab_t;
/**
 * Sets the USGS-to-CWMS parameter mapping for a specified USGS parameter and office
 *
 * @param p_parameter     The USGS parameter to set the mapping for, specified as an integer
 * @param p_parameter_id  The CWMS parameter to use for the USGS parameter
 * @param p_param_type_id The CWMS parameter type to use for the USGS parameter 
 * @param p_unit          The CWMS unit  to use for the USGS parameter
 * @param p_factor        The factor in CWMS = USGS * factor + offset to get the data into the specified CWMS unit
 * @param p_offset        The offset in CWMS = USGS * factor + offset to get the data into the specified CWMS unit
 * @param p_office_id     The office to set the parameter mapping for. If NULL or not specified, the session user's default office is used
 */
procedure set_parameter_info(
   p_parameter     in integer,
   p_parameter_id  in varchar2,
   p_param_type_id in varchar2,
   p_unit          in varchar2,
   p_factor        in binary_double default 1.0, 
   p_offset        in binary_double default 0.0,
   p_office_id     in varchar2 default null);
/**
 * Retrieves the USGS-to-CWMS parameter mapping for a specified USGS parameter and office
 *
 * @param p_parameter_id  The CWMS parameter to use for the USGS parameter
 * @param p_param_type_id The CWMS parameter type to use for the USGS parameter 
 * @param p_unit          The CWMS unit  to use for the USGS parameter
 * @param p_factor        The factor in CWMS = USGS * factor + offset to get the data into the specified CWMS unit. If not specified, the factor defaults to 1.0
 * @param p_offset        The offset in CWMS = USGS * factor + offset to get the data into the specified CWMS unit  If not specified, the offset defatuls to 0.0
 * @param p_parameter     The USGS parameter to retrieve the mapping for, specified as an integer
 * @param p_office_id     The office to retrieve the parameter mapping for. If NULL or not specified, the session user's default office is used
 */
procedure get_parameter_info(
   p_parameter_id  out varchar2,
   p_param_type_id out varchar2,
   p_unit          out varchar2,
   p_factor        out binary_double, 
   p_offset        out binary_double,
   p_parameter     in integer,
   p_office_id     in varchar2 default null);      
/**
 * Deletes the USGS-to-CWMS parameter mapping for a specified USGS parameter and office
 *
 * @param p_parameter_id The CWMS parameter to use for the USGS parameter
 * @param p_office_id    The office to retrieve the parameter mapping for. If NULL or not specified, the session user's default office is used
 */
procedure delete_parameter_info(
   p_parameter in integer,
   p_office_id in varchar2 default null);      
/**
 * Retrieves the CWMS time series identifer based on specified location, version, USGS parameter, and interval 
 *
 * @param p_location_id    The location identifier for the time series
 * @param p_usgs_parameter The USGS parameter to use, specified as an integer
 * @param p_interval       The interval of the data, specified in minutes
 * @param p_version        The version portion of the time series. If not specified, the version defaults to 'USGS'
 * @param p_office_id      The office to create the time series identifier for.  If NULL or not specified, the session user's default office is used
 * @return The time series identifier constructed from the specified information and the office's USGS-to-CWMS parameter mapping information
 */
function get_ts_id(
   p_location_id    in varchar2,
   p_usgs_parameter in integer,
   p_interval       in integer,
   p_version        in varchar2 default 'USGS',
   p_office_id      in varchar2 default null)
   return varchar2; 
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on a lookback period
 *
 * @param p_format     The format for the returned data.  Currently valid values are
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">format</th>
 *     <th class="descr">description</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb,1.0</td>
 *     <td class="descr">tab-delimited USGS RDB format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb</td>
 *     <td class="descr">synonym for 'rdb,1.0'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json,1.0</td>
 *     <td class="descr">JavaScript Object Notaion format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json</td>
 *     <td class="descr">synonym for 'json,1.0'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,1.1</td>
 *     <td class="descr">the CUAHSI WaterML 1.1 format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml</td>
 *     <td class="descr">synonym for 'waterml,1.1'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,2.0</td>
 *     <td class="descr">the OGC WaterML 2.0 format</td>
 *   </tr>
 * </table>
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_ts_period for the specified or default office is used. 
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used. 
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in the requested format as a CLOB
 *
 * @see http://waterservices.usgs.gov/rest/IV-Service.html
 * @see http://en.wikipedia.org/wiki/JSON
 * @see http://river.sdsc.edu/wiki/WaterML.ashx
 * @see http://www.waterml2.org/
 */
function get_ts_data(
   p_format     in varchar2,
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2)
   return clob;   
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on start and end times
 *
 * @param p_format     The format for the returned data.  Currently valid values are
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">format</th>
 *     <th class="descr">description</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb,1.0</td>
 *     <td class="descr">tab-delimited USGS RDB format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">rdb</td>
 *     <td class="descr">synonym for 'rdb,1.0'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,1.1</td>
 *     <td class="descr">the CUAHSI WaterML 1.1 format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml</td>
 *     <td class="descr">synonym for 'waterml,1.1'</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">waterml,2.0</td>
 *     <td class="descr">the OGC WaterML 2.0 format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json,1.1</td>
 *     <td class="descr">The WaterML 1.1 data in JavaScript Object Notation format</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">json</td>
 *     <td class="descr">synonym for 'json,1.1'</td>
 *   </tr>
 * </table>
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format  
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used. 
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in the requested format as a CLOB
 *
 * @see http://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations
 * @see http://waterservices.usgs.gov/rest/IV-Service.html
 * @see http://en.wikipedia.org/wiki/JSON
 * @see http://river.sdsc.edu/wiki/WaterML.ashx
 * @see http://www.waterml2.org/
 */
function get_ts_data(
   p_format     in varchar2,
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2)
   return clob;   
/**
 * Retrieve instantaneous value time series data in RDB format from USGS NWIS based on a lookback period
 *
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_ts_period for the specified or default office is used. 
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used. 
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in RDB format format as a CLOB
 */
function get_ts_data_rdb(
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2)
   return clob;   
/**
 * Retrieve instantaneous value time series data in RDB format from USGS NWIS based on based on start and end times
 *
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format  
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used. 
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 * @return The time series data in RDB format format as a CLOB
 */
function get_ts_data_rdb(
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2)
   return clob;
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on a lookback period and store in CWMS.
 * The period used is the same as returned from get_auto_ts_period for the specified or defatul office
 * The list of sites is the same as returned from get_auto_ts_locations (without the input parameter) for the specified or default office
 * All available parameters for each site will be retrieved, but only those parameters with USGS-to-CWMS parameter mapping will be processed and stored  
 *
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_ts(      
   p_office_id in varchar2 default null);
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on a lookback period and store in CWMS
 *
 * @param p_period     The lookback period to retrieve data for. If NULL, the value returned by get_auto_ts_period for the specified or default office is used. 
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used. 
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site, but only those parameters with USGS-to-CWMS parameter mapping will be processed and stored
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_ts(      
   p_period     in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2);
/**
 * Retrieve instantaneous value time series data from USGS NWIS based on based on start and end times and store in CWMS
 *
 * @param p_start_time The beginning of the time window specified in ISO 8601 date/time format
 * @param p_end_time   The end of the time window specified in ISO 8601 date/time format  
 * @param p_sites      A comma-separated list of USGS site names (station numbers) to retrieve the data for. If NULL, the same list of sites as returned from get_auto_ts_locations (without the input parameter) for the specified or default office is used. 
 * @param p_parameters A comma-separated list of parameters to be used on the data requrest URL. If NULL, all available parameters are retrieved for each site, but only those parameters with USGS-to-CWMS parameter mapping will be processed and stored
 * @param p_office_id  The office to retrieve the data for. If NULL or not specified, the session user's default office is used
 */
procedure retrieve_and_store_ts(      
   p_start_time in varchar2,
   p_end_time   in varchar2,
   p_sites      in varchar2,
   p_parameters in varchar2,
   p_office_id  in varchar2);
/**
 * Schedules (or re-schedules) the job to automatically retrieve instaneous value time series data.
 * The scheduled job name is USGS_AUTO_TS_XXX, where XXX is the office identifier the job is running for
 *
 * @param p_office_id  The office to start the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure start_auto_ts_job(
   p_office_id in varchar2 default null);
/**
 * Unschedules the job to automatically retrieve instaneous value time series data.
 *
 * @param p_office_id  The office to stop the job for.  If NULL or not specified, the session user's default office is used.
 *
 */
procedure stop_auto_ts_job(
   p_office_id in varchar2 default null);

end cwms_usgs;
/
show errors

