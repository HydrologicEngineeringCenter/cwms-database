/* Formatted on 12/29/2011 6:47:33 AM (QP5 v5.185.11230.41888) */
SET DEFINE OFF;

CREATE OR REPLACE PACKAGE cwms_ts
/**
 * Facilities for working with time series
 *
 * @author Various
 *
 * @since CWMS 2.0
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
    * Number of minutes in an hour.
    */
   min_in_hr CONSTANT NUMBER := 60;
   /**
    * Number of minutes in a day.
    */
   min_in_dy CONSTANT NUMBER := 1440;
   /**
    * Number of minutes in a week.
    */
   min_in_wk CONSTANT NUMBER := 10080;
   /**
    * Number of minutes in a month (30 days).
    */
   min_in_mo CONSTANT NUMBER := 43200;
   /**
    * Number of minutes in a year (365 days).
    */
   min_in_yr CONSTANT NUMBER := 525600;
   /**
    * Number of minutes in a decade (10 365-day years).
    */
   min_in_dc CONSTANT NUMBER := 5256000;
                                                  
   /**
    * Behavior for STORE_TS when storing data to remove nulls from the data that don't have quality code that indicates missing.
    */
   filter_out_null_values     constant number := 1; 
   /**
    * Behavior for STORE_TS when storing data to set all quality codes to missing for null values.
    */
   set_null_values_to_missing constant number := 2;
   /**
    * Behavior for STORE_TS when storing data to reject storing any data set that contains null values and non-missing quality.
    */
   reject_ts_with_null_values constant number := 3;                                      
   
   /**
    * Type for holding a time series value.
    *
    * @see type ztsv_type
    *
    * @member date_time    Same as for type ztsv_type
    * @member value        Same as for type ztsv_type
    * @member quality_code Same as for type ztsv_type
    */
   TYPE zts_rec_t IS RECORD
   (
      date_time      DATE,
      VALUE          BINARY_DOUBLE,
      quality_code   NUMBER
   );

   /**
    * Type for holding time series values.
    *
    * @see type ztsv_array
    */
   TYPE zts_tab_t IS TABLE OF zts_rec_t;

   /**
    * Type for passing collections of values from cx_Oracle scripts and possibly others
    */
   TYPE number_array IS TABLE OF NUMBER
                           INDEX BY BINARY_INTEGER;

   /**
    * Type for passing collections of values from cx_Oracle scripts and possibly others
    */
   TYPE double_array IS TABLE OF BINARY_DOUBLE
                           INDEX BY BINARY_INTEGER;

   -- not documented
   FUNCTION get_max_open_cursors
      RETURN INTEGER;

   /**
    * Retrieves the unique numeric code value for a time series
    *
    * @see view av_cwms_ts_id
    *
    * @param p_cwms_ts_id     The time series identifier
    * @param p_db_office_code The unique numeric code identifying the office owning the time series
    *
    * @return  the unique numeric code value for the specified time series
    */
   FUNCTION get_ts_code (p_cwms_ts_id       IN VARCHAR2,
                         p_db_office_code   IN NUMBER)
      RETURN NUMBER;

   /**
    * Retrieves the unique numeric code value for a time series
    *
    * @see view av_cwms_ts_id
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_db_office_id The office owning the time series
    *
    * @return  the unique numeric code value for the specified time series
    */
   FUNCTION get_ts_code (p_cwms_ts_id     IN VARCHAR2,
                         p_db_office_id   IN VARCHAR2)
      RETURN NUMBER;

   /**
    * Retrieves the time series identifier from its unique numeric code
    *
    * @param p_ts_code The unique numeric code identifying the time series
    *
    * @return The time series identifier
    */
   FUNCTION get_ts_id (p_ts_code IN NUMBER)
      RETURN VARCHAR2;

   /**
    * Returns a case-corrected version of the specified time series identifier
    *
    * @param p_cwms_ts_id The case-insensitive version of the time series identifier
    * @param p_office_id  The office that owns the time series
    *
    * @return The case-corrected version of the time series identifier
    */
   FUNCTION get_cwms_ts_id (p_cwms_ts_id   IN VARCHAR2,
                            p_office_id    IN VARCHAR2)
      RETURN VARCHAR2;

   /**
    * Retreieves the database storage unit identifier for a time series
    *
    * @param p_cwms_ts_id The time series identifier
    *
    * @return The database storage unit for the time series
    */
   FUNCTION get_db_unit_id (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2;

   /**
    * Retrieve the beginning time of the next interval a specified time, interval, and offset
    *
    * @param p_datetime    The UTC time to retrieve the start of the next interval for
    * @param p_ts_offset   The data offset into the UTC interval, in minutes
    * @param p_ts_interval The data interval length in minutes
    *
    * @return The beginning time of the next interval
    */
   FUNCTION get_time_on_after_interval (p_datetime      IN DATE,
                                        p_ts_offset     IN NUMBER,
                                        p_ts_interval   IN NUMBER)
      RETURN DATE;

   /**
    * Retrieve the beginning time of the current interval a specified time, interval, and offset
    *
    * @param p_datetime    The UTC time to retrieve the start of the next interval for
    * @param p_ts_offset   The data offset into the UTC interval, in minutes
    * @param p_ts_interval The data interval length in minutes
    *
    * @return The beginning time of the current interval
    */
   FUNCTION get_time_on_before_interval (p_datetime      IN DATE,
                                         p_ts_offset     IN NUMBER,
                                         p_ts_interval   IN NUMBER)
      RETURN DATE;

   /**
    * Retrieves the unique numeric code identifying a specified parameter
    *
    * @param p_base_parameter_id The base parameter identifier of the parameter
    * @param p_sub_parameter_id  The sub-parameter identifier, if any, for the parameter
    * @param p_office_id         The office owning the parameter
    * @param p_create            A flag ('T' or 'F') specifying whether to create the
    *                            parameter if it doesn't already exist.
    *
    * @return The unique numeric code identifying the parameter
    */
   FUNCTION get_parameter_code (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL,
      p_create              IN VARCHAR2 DEFAULT 'T')
      RETURN NUMBER;

   -- not documented
   FUNCTION get_display_parameter_code (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   -- not documented
   FUNCTION get_display_parameter_code2 (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   /**
    * Retrieves the unique numeric code identifying a specified parameter
    *
    * @param p_base_parameter_id The base parameter identifier of the parameter
    * @param p_sub_parameter_id  The sub-parameter identifier, if any, for the parameter
    * @param p_office_id         The unique numeric code identifying the office owning the parameter
    * @param p_create            Specifies whether to create the parameter if it doesn't already exist.
    *
    * @return The unique numeric code identifying the parameter
    */
   FUNCTION get_parameter_code (
      p_base_parameter_code   IN NUMBER,
      p_sub_parameter_id      IN VARCHAR2,
      p_office_code           IN NUMBER,
      p_create                IN BOOLEAN DEFAULT TRUE)
      RETURN NUMBER;

   /**
    * Retrieve the unique numeric code specifying the parameter for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The unique numeric code specifying the parameter for the time series
    */
   FUNCTION get_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   /**
    * Retrieve the unique numeric code specifying the base parameter for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The unique numeric code specifying the base parameter for the time series
    */
   FUNCTION get_base_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   /**
    * Retrieve the unique numeric code specifying the parameter type for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The unique numeric code specifying the parameter type for the time series
    */
   FUNCTION get_parameter_type_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   /**
    * Retrieve the unique numeric code specifying the office owning a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The unique numeric code specifying the office that owns the time series
    */
   FUNCTION get_db_office_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER;

   /**
    * Retrieve the parameter for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The parameter for the time series
    */
   FUNCTION get_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   /**
    * Retrieve the base parameter for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The base parameter for the time series
    */
   FUNCTION get_base_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   /**
    * Retrieve the parameter type for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The parameter type for the time series
    */
   FUNCTION get_parameter_type_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   /**
    * Retrieve the office that owns a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The office that owns the time series
    */
   FUNCTION get_db_office_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   --   FUNCTION get_ts_ni_hash (
   --  p_parameter_code   IN NUMBER,
   --  p_parameter_type_code IN NUMBER,
   --  p_duration_code   IN NUMBER
   --   )
   --  RETURN VARCHAR2;

   --   FUNCTION create_ts_ni_hash (
   --  p_parameter_id IN  VARCHAR2,
   --  p_parameter_type_id IN  VARCHAR2,
   --  p_duration_id  IN VARCHAR2,
   --  p_db_office_id IN  VARCHAR2 DEFAULT NULL
   --   )
   --  RETURN VARCHAR2;
   /**
    * Retrieve the location for a time series
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_db_office_id The office that owns the time series
    *
    * @return The location for the time series
    */
   FUNCTION get_location_id (p_cwms_ts_id     IN VARCHAR2,
                             p_db_office_id   IN VARCHAR2)
      RETURN VARCHAR2;

   /**
    * Retrieve the location for a time series
    *
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    *
    * @return The location for the time series
    */
   FUNCTION get_location_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2;

   /**
    * Deletes a time series from the database
    *
    * @see constant cwms_util.delete_key
    * @see constant cwms_util.delete_data
    * @see constant cwms_util.delete_all
    * @see constant cwms_util.delete_ts_id
    * @see constant cwms_util.delete_ts_data
    * @see constant cwms_util.delete_ts_cascade
    *
    * @param p_cwms_ts_id     The identifier of the time series to delete
    * @param p_delete_action Specifies what to delete.  Actions are as follows:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_delete_action</th>
    *     <th class="descr">Action</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_id<br>cwms_util.delete_key</td>
    *     <td class="descr">deletes only the time series identifier, and then only if it has no time series values</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_data<br>cwms_util.delete_data</td>
    *     <td class="descr">deletes only the time series values, if any</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">delete_ts_cascade<br>cwms_util.delete_all</td>
    *     <td class="descr">deletes the time series identifier and any time series values</td>
    *   </tr>
    * </table>
    * @param p_db_office_id   The office that owns the time series.  If not specified or NULL, the session user's default office will be used.
    */
   PROCEDURE delete_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_ts_id,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   /**
    * Deletes a time series from the database
    *
    * @see constant cwms_util.delete_key
    * @see constant cwms_util.delete_data
    * @see constant cwms_util.delete_all
    * @see constant cwms_util.delete_ts_id
    * @see constant cwms_util.delete_ts_data
    * @see constant cwms_util.delete_ts_cascade
    *
    * @param p_cwms_ts_id     The identifier of the time series to delete
    * @param p_delete_action Specifies what to delete.  Actions are as follows:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">p_delete_action</th>
    *     <th class="descr">Action</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_id<br>cwms_util.delete_key</td>
    *     <td class="descr">deletes only the time series identifier, and then only if it has no time series values</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">cwms_util.delete_ts_data<br>cwms_util.delete_data</td>
    *     <td class="descr">deletes only the time series values, if any</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">delete_ts_cascade<br>cwms_util.delete_all</td>
    *     <td class="descr">deletes the time series identifier and any time series values</td>
    *   </tr>
    * </table>
    * @param p_db_office_code The unique numeric code that identifies the office that owns the time series
    */
   PROCEDURE delete_ts (p_cwms_ts_id       IN VARCHAR2,
                        p_delete_action    IN VARCHAR2,
                        p_db_office_code   IN NUMBER);

   /**
    * Deletes time series values for a specified time series, version date, and time window or specified times
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    * @see constant cwms_util.ts_values
    * @see constant cwms_util.ts_std_text
    * @see constant cwms_util.ts_text
    * @see constant cwms_util.ts_all_text
    * @see constant cwms_util.ts_binary
    * @see constant cwms_util.ts_all_non_values
    * @see constant cwms_util.ts_all
    *
    * @param p_cwms_ts_id            The identifier of the time series to delete
    * @param p_override_protection   A flag ('T'/'F') specifying whether to delete protected data, may also be set to 'E' (or 'ERROR', or anything in between) to raise an exception if protected values are encountered.
    * @param p_start_time            The start of the time window in the specified or default time zone
    * @param p_end_time              The end of the time window in the specified or default time zone
    * @param p_start_time_inclusive  A flag ('T'/'F') specifying whether any data at the start time should be deleted ('T') or only data <b><em>after</em></b> the start time ('F')
    * @param p_end_time_inclusive    A flag ('T'/'F') specifying whether any data at the end time should be deleted ('T') or only data <b><em>before</em></b> the end time ('F')
    * @param p_version_date          The version date/time of the time series in the specified or default time zone. If NULL, the earliest or latest version date will be used depending on p_max_version.
    * @param p_time_zone             The time zone of any/all specified times. If not specified or NULL, the local time zone of the time series location is used.
    * @param p_date_times            A table of specific times to use, instead of a time window, in the specified or default time zone.
    * @param p_max_version           A flag ('T'/'F') specifying whether to use the earliest ('F') or latest ('T') version date for each time if p_version_date is NULL.
    * @param p_ts_item_mask          A cookie specifying what time series items to purge.
    * @param p_db_office_id          The office that owns the time series.  If not specified or NULL, the session user's default office will be used.
    */
   PROCEDURE delete_ts (
      p_cwms_ts_id           in varchar2,
      p_override_protection  in varchar2,
      p_start_time           in date,
      p_end_time             in date,                        
      p_start_time_inclusive in varchar2,
      p_end_time_inclusive   in varchar2,
      p_version_date         in date,
      p_time_zone            in varchar2 default null,
      p_date_times           in date_table_type default null,
      p_max_version          in varchar2 default 'T',
      p_ts_item_mask         in integer default cwms_util.ts_all,
      p_db_office_id         in varchar2 default null);

   /**
    * Deletes time series values for specified time series, version date, and time windows
    *                    
    * @see type timeseries_req_array
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    * @see constant cwms_util.ts_values
    * @see constant cwms_util.ts_std_text
    * @see constant cwms_util.ts_text
    * @see constant cwms_util.ts_all_text
    * @see constant cwms_util.ts_binary
    * @see constant cwms_util.ts_all_non_values
    * @see constant cwms_util.ts_all
    *
    * @param p_timeseries_info       Identifies the combinations of time series and time windows to delete data for.  The unit member of each element is ignored.
    * @param p_override_protection   A flag ('T'/'F') specifying whether to delete protected data, may also be set to 'E' (or 'ERROR', or anything in between) to raise an exception if protected values are encountered.
    * @param p_start_time_inclusive  A flag ('T'/'F') specifying whether any data at the start time should be deleted ('T') or only data <b><em>after</em></b> the start time ('F')
    * @param p_end_time_inclusive    A flag ('T'/'F') specifying whether any data at the end time should be deleted ('T') or only data <b><em>before</em></b> the end time ('F')
    * @param p_version_date          The version date/time of the time series in the specified or default time zone. If NULL, the earliest or latest version date will be used depending on p_max_version.
    * @param p_time_zone             The time zone of any/all specified times. If not specified or NULL, the local time zone of the time series location is used.
    * @param p_max_version           A flag ('T'/'F') specifying whether to use the earliest ('F') or latest ('T') version date for each time if p_version_date is NULL.
    * @param p_ts_item_mask          A cookie specifying what time series items to purge.
    * @param p_db_office_id          The office that owns the time series.  If not specified or NULL, the session user's default office will be used.
    */
   PROCEDURE delete_ts (
      p_timeseries_info      in timeseries_req_array,
      p_override_protection  in varchar2,
      p_start_time_inclusive in varchar2,
      p_end_time_inclusive   in varchar2,
      p_version_date         in date,
      p_time_zone            in varchar2 default null,
      p_max_version          in varchar2 default 'T',
      p_ts_item_mask         in integer default cwms_util.ts_all,
      p_db_office_id         in varchar2 default null);

   /**
    * Deletes time series values for a specified time series, version date, and time window or specified times. Raises an exception if protected values are encountered.
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    * @see constant cwms_util.ts_values
    * @see constant cwms_util.ts_std_text
    * @see constant cwms_util.ts_text
    * @see constant cwms_util.ts_all_text
    * @see constant cwms_util.ts_binary
    * @see constant cwms_util.ts_all_non_values
    * @see constant cwms_util.ts_all
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The UTC version date/time of the time series. If NULL, the earliest or latest version date will be used depending on p_max_version.
    * @param p_start_time_utc   The UTC start of the time window
    * @param p_end_time_utc     The UTC end of the time window
    * @param p_date_times_utc   A table of specific times to use instead of a time window.
    * @param p_max_version      A flag ('T'/'F') specifying whether to use the earliest ('F') or latest ('T') version date for each time if p_version_date_utc is NULL.
    * @param p_ts_item_mask     A cookie specifying what time series items to purge.
    */
   PROCEDURE purge_ts_data (p_ts_code            IN NUMBER,
                            p_version_date_utc   IN DATE,
                            p_start_time_utc     IN DATE,
                            p_end_time_utc       IN DATE,
                            p_date_times_utc     IN date_table_type DEFAULT NULL,
                            p_max_version        IN VARCHAR2 DEFAULT 'T',
                            p_ts_item_mask       IN INTEGER DEFAULT cwms_util.ts_all);

   /**
    * Deletes time series values for a specified time series, version date, and time window or specified times
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    * @see constant cwms_util.ts_values
    * @see constant cwms_util.ts_std_text
    * @see constant cwms_util.ts_text
    * @see constant cwms_util.ts_all_text
    * @see constant cwms_util.ts_binary
    * @see constant cwms_util.ts_all_non_values
    * @see constant cwms_util.ts_all
    *
    * @param p_ts_code             The unique numeric code identifying the time series
    * @param p_override_protection A flag ('T'/'F') specifying whether to delete protected data, may also be set to 'E' (or 'ERROR', or anything in between) to raise an exception if protected values are encountered.
    * @param p_version_date_utc    The UTC version date/time of the time series. If NULL, the earliest or latest version date will be used depending on p_max_version.
    * @param p_start_time_utc      The UTC start of the time window
    * @param p_end_time_utc        The UTC end of the time window
    * @param p_date_times_utc      A table of specific times to use instead of a time window.
    * @param p_max_version         A flag ('T'/'F') specifying whether to use the earliest ('F') or latest ('T') version date for each time if p_version_date_utc is NULL.
    * @param p_ts_item_mask        A cookie specifying what time series items to purge.
    */
   PROCEDURE purge_ts_data (p_ts_code             IN NUMBER,
                            p_override_protection IN VARCHAR2,
                            p_version_date_utc    IN DATE,
                            p_start_time_utc      IN DATE,
                            p_end_time_utc        IN DATE,
                            p_date_times_utc      IN date_table_type DEFAULT NULL,
                            p_max_version         IN VARCHAR2 DEFAULT 'T',
                            p_ts_item_mask        IN INTEGER DEFAULT cwms_util.ts_all);

   /**
    * Changes the version date for a time series, version date, and time window
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code              The unique numeric code identifying the time series
    * @param p_old_version_date_utc The existing UTC version date/time of the time series
    * @param p_new_version_date_utc The new UTC version date/time of the time series
    * @param p_start_time_utc       The UTC start of the time window
    * @param p_end_time_utc         The UTC end of the time window
    * @param p_date_times_utc       A table of specific times to use instead of a time window.
    * @param p_ts_item_mask         A cookie specifying what time series items to purge.
    */
   PROCEDURE change_version_date (p_ts_code                IN NUMBER,
                                  p_old_version_date_utc   IN DATE,
                                  p_new_version_date_utc   IN DATE,
                                  p_start_time_utc         IN DATE,
                                  p_end_time_utc           IN DATE,
                                  p_date_times_utc         IN date_table_type DEFAULT NULL,
                                  p_ts_item_mask           IN INTEGER DEFAULT cwms_util.ts_all);

   -- not documented, for LRTS
   PROCEDURE set_ts_time_zone (p_ts_code          IN NUMBER,
                               p_time_zone_name   IN VARCHAR2);

   -- not documented, for LRTS
   PROCEDURE set_tsid_time_zone (p_ts_id            IN VARCHAR2,
                                 p_time_zone_name   IN VARCHAR2,
                                 p_office_id        IN VARCHAR2 DEFAULT NULL);

   -- not documented, for LRTS
   FUNCTION get_ts_time_zone (p_ts_code IN NUMBER)
      RETURN VARCHAR2;

   -- not documented, for LRTS
   FUNCTION get_tsid_time_zone (p_ts_id       IN VARCHAR2,
                                p_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   /**
    * Sets a time series to versioned or non-versioned.  A time series can only
    * be set to non-versioned if it contains no versioned data.
    *
    * @param p_cwms_ts_code The unique numeric code that identifies the time series
    * @param p_versioned    A flag ('T' or 'F') that specifies if the time series is to be versioned.
    */
   PROCEDURE set_ts_versioned (p_cwms_ts_code   IN NUMBER,
                               p_versioned      IN VARCHAR2 DEFAULT 'T');

   /**
    * Sets a time series to versioned or non-versioned.  A time series can only
    * be set to non-versioned if it contains no versioned data.
    *
    * @param p_cwms_ts_id The time series identifier
    * @param p_office_id  The office that owns the time series. If not specified or NULL, the session user's default office is used.
    * @param p_versioned  A flag ('T' or 'F') that specifies if the time series is to be versioned.
    */
   PROCEDURE set_tsid_versioned (p_cwms_ts_id     IN VARCHAR2,
                                 p_versioned      IN VARCHAR2 DEFAULT 'T',
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves whether a time series is currently versioned
    *
    * @param p_is_versioned A flag ('T' or 'F') that specifies if the time series is to be versioned.
    * @param p_cwms_ts_code The unique numeric code that identifies the time series
    */
   PROCEDURE is_ts_versioned (p_is_versioned      OUT VARCHAR2,
                              p_cwms_ts_code   IN     NUMBER);

   /**
    * Retrieves whether a time series is currently versioned
    *
    * @param p_is_versioned A flag ('T' or 'F') that specifies if the time series is to be versioned.
    * @param p_cwms_ts_id   The time series identifier
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE is_tsid_versioned (
      p_is_versioned      OUT VARCHAR2,
      p_cwms_ts_id     IN     VARCHAR2,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves whether a time series is currently versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return A flag ('T' or 'F') that specifies if the time series is to be versioned.
    */
   FUNCTION is_tsid_versioned_f (p_cwms_ts_id     IN VARCHAR2,
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   /**
    * Returns all version dates for a specified time series and time window
    *
    * @param p_date_cat     A cursor containing the version dates. The cursor contains a single unnamed column of type VERSION_DATE, sorted in ascending order.
    *                       VERSION_DATE will be in the specified time zone, except that non-versioned date signature is preserved regardless of time zone.
    * @param p_cwms_ts_code The unique numeric code identifying the time series
    * @param p_start_time   The start of the time window
    * @param p_end_time     The end of the time window
    * @param p_time_zone    The time zone for the time window and the retrieved version dates. If not specified or NULL, UTC will be used.
    */
   PROCEDURE get_ts_version_dates (
      p_date_cat          OUT SYS_REFCURSOR,
      p_cwms_ts_code   IN     NUMBER,
      p_start_time     IN     DATE,
      p_end_time       IN     DATE,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC');

   /**
    * Returns all version dates for a specified time series and time window
    *
    * @param p_date_cat     A cursor containing the version dates. The cursor contains a single unnamed column of type VERSION_DATE, sorted in ascending order.
    *                       VERSION_DATE will be in the specified time zone, except that non-versioned date signature is preserved regardless of time zone.
    * @param p_cwms_ts_id   The time series identifier
    * @param p_start_time   The start of the time window
    * @param p_end_time     The end of the time window
    * @param p_time_zone    The time zone for the time window and the retrieved version dates. If not specified or NULL, UTC will be used.
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE get_tsid_version_dates (
      p_date_cat          OUT SYS_REFCURSOR,
      p_cwms_ts_id     IN     VARCHAR2,
      p_start_time     IN     DATE,
      p_end_time       IN     DATE,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC',
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   /**
    * Creates a new time series
    *
    * @param p_office_id  The office that owns the time series
    * @param p_cwms_ts_id The time series identifier
    * @param p_utc_offset The UTC regular interval offset in minutes, if applicable and known
    */
   PROCEDURE create_ts (p_office_id    IN VARCHAR2,
                        p_cwms_ts_id   IN VARCHAR2,
                        p_utc_offset   IN NUMBER DEFAULT NULL);

   /**
    * Creates a new time series
    *
    * @param p_cwms_ts_id        The time series identifier
    * @param p_utc_offset        The UTC regular interval offset in minutes, if applicable and known. If not specified or NULL, the offset will be set by the first time series value stored.
    * @param p_interval_forward  The UTC regular interval forward tolerance in minutes, if applicable. If not specified or NULL, 0 minutes will be used. This specifies the number of minutes after the expected data time to treat data as being on the expected time.
    * @param p_interval_backward The UTC regular interval backward tolerance in minutes, if applicable If not specified or NULL, 0 minutes will be used. This specifies the number of minutes before the expected data time to treat data as being on the expected time.
    * @param p_versioned         A flag ('T' or 'F') specifying whether the time series is versioned
    * @param p_active_flag       A flag ('T' or 'F') specifying whether the time series is active
    * @param p_office_id         The office that owns the time series. If not specified or NULL, the session_user's default office_will be used
    */
   PROCEDURE create_ts (p_cwms_ts_id          IN VARCHAR2,
                        p_utc_offset          IN NUMBER DEFAULT NULL,
                        p_interval_forward    IN NUMBER DEFAULT NULL,
                        p_interval_backward   IN NUMBER DEFAULT NULL,
                        p_versioned           IN VARCHAR2 DEFAULT 'F',
                        p_active_flag         IN VARCHAR2 DEFAULT 'T',
                        p_office_id           IN VARCHAR2 DEFAULT NULL);

   -- not documented, for LRTS
   PROCEDURE create_ts_tz (p_cwms_ts_id          IN VARCHAR2,
                           p_utc_offset          IN NUMBER DEFAULT NULL,
                           p_interval_forward    IN NUMBER DEFAULT NULL,
                           p_interval_backward   IN NUMBER DEFAULT NULL,
                           p_versioned           IN VARCHAR2 DEFAULT 'F',
                           p_active_flag         IN VARCHAR2 DEFAULT 'T',
                           p_time_zone_name      IN VARCHAR2 DEFAULT 'UTC',
                           p_office_id           IN VARCHAR2 DEFAULT NULL);

   /**
    * Creates a new time series and returns its unique numeric code
    *
    * @param p_ts_code           The unique numeric code identifying the time series
    * @param p_cwms_ts_id        The time series identifier
    * @param p_utc_offset        The UTC regular interval offset in minutes, if applicable and known. If not specified or NULL, the offset will be set by the first time series value stored.
    * @param p_interval_forward  The UTC regular interval forward tolerance in minutes, if applicable. If not specified or NULL, 0 minutes will be used. This specifies the number of minutes after the expected data time to treat data as being on the expected time.
    * @param p_interval_backward The UTC regular interval backward tolerance in minutes, if applicable If not specified or NULL, 0 minutes will be used. This specifies the number of minutes before the expected data time to treat data as being on the expected time.
    * @param p_versioned         A flag ('T' or 'F') specifying whether the time series is versioned
    * @param p_active_flag       A flag ('T' or 'F') specifying whether the time series is active
    * @param p_fail_if_exists    A flag ('T' or 'F') specifying whether to fail if the time series already exists.  If 'F' and the time series exists, the existing numeric code is retreieved.
    * @param p_office_id         The office that owns the time series. If not specified or NULL, the session_user's default office_will be used
    */
   PROCEDURE create_ts_code (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward   IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag         IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists      IN     VARCHAR2 DEFAULT 'T',
      p_office_id           IN     VARCHAR2 DEFAULT NULL);

   -- not documented, for LRTS
   PROCEDURE create_ts_code_tz (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward   IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag         IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists      IN     VARCHAR2 DEFAULT 'T',
      p_time_zone_name      IN     VARCHAR2 DEFAULT 'UTC',
      p_office_id           IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves time series data for a specified time series and time window
    *
    * @param p_at_tsv_rc       A cursor containing the time series data.  The cursor
    * contains the following columns, sorted by date_time:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time of the value, in the specified time zone</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">value</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The data value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">quality_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The quality code for the data value</td>
    *   </tr>
    * </table>
    * @param p_cwms_ts_id_out  The case-corrected version of the time series identifier
    * @param p_units_out       The unit of the retrieved data values
    * @param p_cwms_ts_id      The time series identifier to retrieve data for
    * @param p_units           The unit to retrieve the data values in
    * @param p_start_time      The start time of the time window
    * @param p_end_time        The end time of the time window
    * @param p_time_zone       The time zone for the time window and retrieved times. Either a standard (constant offset from UTC) or local (observes Daylight Savings)
    * time zone can be specified. For local time zones there are two behaviors that can be specified for retrieving data across a (Spring or Autum)
    * Daylight Savings boundary.
    * <ul><li>The <strong>default behavior</strong> is to retrieve the data normally and label it according to the local time zone, which will result in time discontinuities
    *         at the DST boundaries. The Spring discontinuity will result in a missing 0200 hour; the Autum discontinuity will result in a repeated
    *         0100 hour (with possibly different values).</li>
    *     <li>The <strong>alternate behavior</strong> - specified by pre-pending <strong><code>!</code></strong> to the time zone (e.g. <code>!US/Pacific</code>) - is to retrieve data that can be used
    *         as a valid time series. This results in the absence of time discontinuities in the dataset, but at the expense of inserting a manufactured
    *         0200 hour in the Spring (with null values and "missing" quality codes) for regular time series and not returing earliest 0100 hour (the
    *         one corresponding to Daylight Savings) in the Autum.</li></ul>
    * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the retrieved values
    * @param p_start_inclusive A flag ('T' or 'F') that specifies whether the time window begins on ('T') or after ('F') the start time
    * @param p_end_inclusive   A flag ('T' or 'F') that specifies whether the time window ends on ('T') or before ('F') the end time
    * @param p_previous        A flag ('T' or 'F') that specifies whether to retrieve the latest value before the start of the time window
    * @param p_next            A flag ('T' or 'F') that specifies whether to retrieve the earliest value after the end of the time window
    * @param p_version_date    The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
    * @param p_max_version     A flag ('T' or 'F') that specifies whether to retrieve the maximum ('T') or minimum ('F') version date if p_version_date is NULL
    * @param p_office_id       The office that owns the time series
    */
   PROCEDURE retrieve_ts_out (
      p_at_tsv_rc            OUT SYS_REFCURSOR,
      p_cwms_ts_id_out       OUT VARCHAR2,
      p_units_out            OUT VARCHAR2,
      p_cwms_ts_id        IN     VARCHAR2,
      p_units             IN     VARCHAR2,
      p_start_time        IN     DATE,
      p_end_time          IN     DATE,
      p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
      p_trim              IN     VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_previous          IN     VARCHAR2 DEFAULT 'F',
      p_next              IN     VARCHAR2 DEFAULT 'F',
      p_version_date      IN     DATE DEFAULT NULL,
      p_max_version       IN     VARCHAR2 DEFAULT 'T',
      p_office_id         IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves a table of time series data for a specified time series and time window
    *
    * @param p_cwms_ts_id      The time series identifier to retrieve data for
    * @param p_units           The unit to retrieve the data values in
    * @param p_start_time      The start time of the time window
    * @param p_end_time        The end time of the time window
    * @param p_time_zone       The time zone for the time window and retrieved times. Either a standard (constant offset from UTC) or local (observes Daylight Savings)
    * time zone can be specified. For local time zones there are two behaviors that can be specified for retrieving data across a (Spring or Autum)
    * Daylight Savings boundary.
    * <ul><li>The <strong>default behavior</strong> is to retrieve the data normally and label it according to the local time zone, which will result in time discontinuities
    *         at the DST boundaries. The Spring discontinuity will result in a missing 0200 hour; the Autum discontinuity will result in a repeated
    *         0100 hour (with possibly different values).</li>
    *     <li>The <strong>alternate behavior</strong> - specified by pre-pending <strong><code>!</code></strong> to the time zone (e.g. <code>!US/Pacific</code>) - is to retrieve data that can be used
    *         as a valid time series. This results in the absence of time discontinuities in the dataset, but at the expense of inserting a manufactured
    *         0200 hour in the Spring (with null values and "missing" quality codes) for regular time series and not returing earliest 0100 hour (the
    *         one corresponding to Daylight Savings) in the Autum.</li></ul>
    * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the retrieved values
    * @param p_start_inclusive A flag ('T' or 'F') that specifies whether the time window begins on ('T') or after ('F') the start time
    * @param p_end_inclusive   A flag ('T' or 'F') that specifies whether the time window ends on ('T') or before ('F') the end time
    * @param p_previous        A flag ('T' or 'F') that specifies whether to retrieve the latest value before the start of the time window
    * @param p_next            A flag ('T' or 'F') that specifies whether to retrieve the earliest value after the end of the time window
    * @param p_version_date    The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
    * @param p_max_version     A flag ('T' or 'F') that specifies whether to retrieve the maximum ('T') or minimum ('F') version date if p_version_date is NULL
    * @param p_office_id       The office that owns the time series
    *
    * @return  A collection of records containing the time series data. The records contains
    * the following columns, sorted by date_time:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time of the value, in the specified time zone</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">value</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The data value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">quality_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The quality code for the data value</td>
    *   </tr>
    * </table><p>
    * The record collection is suitable for casting to a table with the table() function.
    */
   FUNCTION retrieve_ts_out_tab (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_start_time        IN DATE,
      p_end_time          IN DATE,
      p_time_zone         IN VARCHAR2 DEFAULT 'UTC',
      p_trim              IN VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN VARCHAR2 DEFAULT 'T',
      p_previous          IN VARCHAR2 DEFAULT 'F',
      p_next              IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT NULL,
      p_max_version       IN VARCHAR2 DEFAULT 'T',
      p_office_id         IN VARCHAR2 DEFAULT NULL)
      RETURN zts_tab_t
      PIPELINED;

   /**
    * Retrieves time series data for a specified time series and time window
    *
    * @param p_at_tsv_rc       A cursor containing the time series data.  The cursor
    * contains the following columns, sorted by date_time:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">timestamp with time zone</td>
    *     <td class="descr">The date/time of the value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">value</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The data value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">quality_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The quality code for the data value</td>
    *   </tr>
    * </table>
    * @param p_units           The unit to retrieve the data values in
    * @param p_officeid        The office that owns the time series
    * @param p_cwms_ts_id      The time series identifier to retrieve data for
    * @param p_start_time      The start time of the time window
    * @param p_end_time        The end time of the time window
    * @param p_timezone        The time zone for the time window. Either a standard (constant offset from UTC) or local (observes Daylight Savings)
    * time zone can be specified. For local time zones there are two behaviors that can be specified for retrieving data across a (Spring or Autum)
    * Daylight Savings boundary.
    * <ul><li>The <strong>default behavior</strong> is to retrieve the data normally and label it according to the local time zone, which will result in time discontinuities
    *         at the DST boundaries. The Spring discontinuity will result in a missing 0200 hour; the Autum discontinuity will result in a repeated
    *         0100 hour (with possibly different values).</li>
    *     <li>The <strong>alternate behavior</strong> - specified by pre-pending <strong><code>!</code></strong> to the time zone (e.g. <code>!US/Pacific</code>) - is to retrieve data that can be used
    *         as a valid time series. This results in the absence of time discontinuities in the dataset, but at the expense of inserting a manufactured
    *         0200 hour in the Spring (with null values and "missing" quality codes) for regular time series and not returing earliest 0100 hour (the
    *         one corresponding to Daylight Savings) in the Autum.</li></ul>
    * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the retrieved values
    * @param p_inclusive       A flag ('T' or 'F') that specifies whether the start and end time are included in the time window
    * @param p_versiondate     The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
    * @param p_max_version     A flag ('T' or 'F') that specifies whether to retrieve the maximum ('T') or minimum ('F') version date if p_versiondate is NULL
    */
   PROCEDURE retrieve_ts (
      p_at_tsv_rc     IN OUT SYS_REFCURSOR,
      p_units         IN     VARCHAR2,
      p_officeid      IN     VARCHAR2,
      p_cwms_ts_id    IN     VARCHAR2,
      p_start_time    IN     DATE,
      p_end_time      IN     DATE,
      p_timezone      IN     VARCHAR2 DEFAULT 'GMT',
      p_trim          IN     NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN     NUMBER DEFAULT NULL,
      p_versiondate   IN     DATE DEFAULT NULL,
      p_max_version   IN     NUMBER DEFAULT cwms_util.true_num);

   -- not documented, same as retrieve_ts
   PROCEDURE retrieve_ts_2 (
      p_at_tsv_rc        OUT SYS_REFCURSOR,
      p_units         IN     VARCHAR2,
      p_officeid      IN     VARCHAR2,
      p_cwms_ts_id    IN     VARCHAR2,
      p_start_time    IN     DATE,
      p_end_time      IN     DATE,
      p_timezone      IN     VARCHAR2 DEFAULT 'GMT',
      p_trim          IN     NUMBER DEFAULT cwms_util.false_num,
      p_inclusive     IN     NUMBER DEFAULT NULL,
      p_versiondate   IN     DATE DEFAULT NULL,
      p_max_version   IN     NUMBER DEFAULT cwms_util.true_num);

   /**
    * Retrieves time series data for a specified time series and time window
    *
    * @param p_at_tsv_rc       A cursor containing the time series data.  The cursor
    * contains the following columns, sorted by date_time:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time of the value, in the specified time zone</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">value</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The data value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">quality_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The quality code for the data value</td>
    *   </tr>
    * </table>
    * @param p_cwms_ts_id      The time series identifier to retrieve data for
    * @param p_units           The unit to retrieve the data values in
    * @param p_start_time      The start time of the time window
    * @param p_end_time        The end time of the time window. Either a standard (constant offset from UTC) or local (observes Daylight Savings)
    * time zone can be specified. For local time zones there are two behaviors that can be specified for retrieving data across a (Spring or Autum)
    * Daylight Savings boundary.
    * <ul><li>The <strong>default behavior</strong> is to retrieve the data normally and label it according to the local time zone, which will result in time discontinuities
    *         at the DST boundaries. The Spring discontinuity will result in a missing 0200 hour; the Autum discontinuity will result in a repeated
    *         0100 hour (with possibly different values).</li>
    *     <li>The <strong>alternate behavior</strong> - specified by pre-pending <strong><code>!</code></strong> to the time zone (e.g. <code>!US/Pacific</code>) - is to retrieve data that can be used
    *         as a valid time series. This results in the absence of time discontinuities in the dataset, but at the expense of inserting a manufactured
    *         0200 hour in the Spring (with null values and "missing" quality codes) for regular time series and not returing earliest 0100 hour (the
    *         one corresponding to Daylight Savings) in the Autum.</li></ul>
    * @param p_time_zone       The time zone for the time window and retrieved times
    * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the retrieved values
    * @param p_start_inclusive A flag ('T' or 'F') that specifies whether the time window begins on ('T') or after ('F') the start time
    * @param p_end_inclusive   A flag ('T' or 'F') that specifies whether the time window ends on ('T') or before ('F') the end time
    * @param p_previous        A flag ('T' or 'F') that specifies whether to retrieve the latest value before the start of the time window
    * @param p_next            A flag ('T' or 'F') that specifies whether to retrieve the earliest value after the end of the time window
    * @param p_version_date    The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
    * @param p_max_version     A flag ('T' or 'F') that specifies whether to retrieve the maximum ('T') or minimum ('F') version date if p_version_date is NULL
    * @param p_office_id       The office that owns the time series
    */
   PROCEDURE retrieve_ts (p_at_tsv_rc            OUT SYS_REFCURSOR,
                          p_cwms_ts_id        IN     VARCHAR2,
                          p_units             IN     VARCHAR2,
                          p_start_time        IN     DATE,
                          p_end_time          IN     DATE,
                          p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
                          p_trim              IN     VARCHAR2 DEFAULT 'F',
                          p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
                          p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
                          p_previous          IN     VARCHAR2 DEFAULT 'F',
                          p_next              IN     VARCHAR2 DEFAULT 'F',
                          p_version_date      IN     DATE DEFAULT NULL,
                          p_max_version       IN     VARCHAR2 DEFAULT 'T',
                          p_office_id         IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves time series data for multiple time series
    *
    * @param p_at_tsv_rc       A cursor containing the time series data.  The cursor
    * contains the following columns, sorted by date_time:
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">sequence</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The position in p_timeseries_info that this record is associated with</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">tsid</td>
    *     <td class="descr">varchar2(191)</td>
    *     <td class="descr">The time series identifier for this record</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">units</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The data unit for this record</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">start_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The start time of the time window for this record</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">end_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The end time of the time window for this record</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">time_zone</td>
    *     <td class="descr">varchar2(28)</td>
    *     <td class="descr">The time zone of the time window</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">7</td>
    *     <td class="descr">data</td>
    *     <td class="descr">cursor</td>
    *     <td class="descr">The time series data for this record
    *    <p>
    *    <table class="descr">
    *      <tr>
    *        <th class="descr">Column No.</th>
    *        <th class="descr">Column Name</th>
    *        <th class="descr">Data Type</th>
    *        <th class="descr">Contents</th>
    *      </tr>
    *      <tr>
    *        <td class="descr-center">1</td>
    *        <td class="descr">date_time</td>
    *        <td class="descr">timestamp with time zone</td>
    *        <td class="descr">The date/time of the value, in the specified time zone</td>
    *      </tr>
    *      <tr>
    *        <td class="descr-center">2</td>
    *        <td class="descr">value</td>
    *        <td class="descr">binary_double</td>
    *        <td class="descr">The data value</td>
    *      </tr>
    *      <tr>
    *        <td class="descr-center">3</td>
    *        <td class="descr">quality_code</td>
    *        <td class="descr">number</td>
    *        <td class="descr">The quality code for the data value</td>
    *      </tr>
    *    </table>
    *     </td>
    *   </tr>
    * </table>
    * @param p_timeseries_info The time series identifiers, time windows, and units to retrieve data for
    * @param p_time_zone       The time zone for the time windows and retrieved times. Either a standard (constant offset from UTC) or local (observes Daylight Savings)
    * time zone can be specified. For local time zones there are two behaviors that can be specified for retrieving data across a (Spring or Autum)
    * Daylight Savings boundary.
    * <ul><li>The <strong>default behavior</strong> is to retrieve the data normally and label it according to the local time zone, which will result in time discontinuities
    *         at the DST boundaries. The Spring discontinuity will result in a missing 0200 hour; the Autum discontinuity will result in a repeated
    *         0100 hour (with possibly different values).</li>
    *     <li>The <strong>alternate behavior</strong> - specified by pre-pending <strong><code>!</code></strong> to the time zone (e.g. <code>!US/Pacific</code>) - is to retrieve data that can be used
    *         as a valid time series. This results in the absence of time discontinuities in the dataset, but at the expense of inserting a manufactured
    *         0200 hour in the Spring (with null values and "missing" quality codes) for regular time series and not returing earliest 0100 hour (the
    *         one corresponding to Daylight Savings) in the Autum.</li></ul>
    * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the retrieved values
    * @param p_start_inclusive A flag ('T' or 'F') that specifies whether the time window begins on ('T') or after ('F') the start time
    * @param p_end_inclusive   A flag ('T' or 'F') that specifies whether the time window ends on ('T') or before ('F') the end time
    * @param p_previous        A flag ('T' or 'F') that specifies whether to retrieve the latest value before the start of the time window
    * @param p_next            A flag ('T' or 'F') that specifies whether to retrieve the earliest value after the end of the time window
    * @param p_version_date    The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
    * @param p_max_version     A flag ('T' or 'F') that specifies whether to retrieve the maximum ('T') or minimum ('F') version date if p_version_date is NULL
    * @param p_office_id       The office that owns the time series
    */
   PROCEDURE retrieve_ts_multi (
      p_at_tsv_rc            OUT SYS_REFCURSOR,
      p_timeseries_info   IN     timeseries_req_array,
      p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
      p_trim              IN     VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_previous          IN     VARCHAR2 DEFAULT 'F',
      p_next              IN     VARCHAR2 DEFAULT 'F',
      p_version_date      IN     DATE DEFAULT NULL,
      p_max_version       IN     VARCHAR2 DEFAULT 'T',
      p_office_id         IN     VARCHAR2 DEFAULT NULL);
   /*
    * Ranks a quality code on a scale of 0 - 3
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Score</th>
    *     <th class="descr">Meaning</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">0</td>
    *     <td class="descr">Quality code indicates value is missing or rejected</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">Quality code indicates value is of unscreened</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">Quality code indicates value is questionable</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">Quality code indicates value is okay</td>
    *   </tr>
    * </table>
    *
    * @param p_quality_code The quality code to score
    *
    * @return The computed score of the quality code
    */
   function quality_score(
      p_quality_code in integer)
      return integer;
      
   -- not documented, for LRTS
   FUNCTION shift_for_localtime (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN DATE;

   -- not documented
   FUNCTION clean_quality_code (p_quality_code IN NUMBER)
      RETURN NUMBER
      RESULT_CACHE;

   -- not documented
   FUNCTION use_first_table (p_timestamp IN TIMESTAMP DEFAULT NULL)
      RETURN BOOLEAN;

   -- not documented
   function same_vq(
      v1 in binary_double,
      q1 in integer,
      v2 in binary_double,
      q2 in integer)
      return varchar2;

   -- not documented
   function same_val(
      v1 in binary_double,
      v2 in binary_double)
      return varchar2;

   -- not documented
   procedure update_ts_extents(
      p_ts_code      in integer default null,
      p_version_date in date default null);

   -- not documented
   procedure start_update_ts_extents_job;

   -- not documented
   procedure start_immediate_upd_tsx_job;
   /**
    * Stores time series data to the database
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_office_id        The office owning the time series.
    * @param p_cwms_ts_id       The time series identifier
    * @param p_units            The unit of the data values
    * @param p_timeseries_data  The time series data
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_versiondate      The version date of the data
    */
   PROCEDURE store_ts (
      p_office_id         IN VARCHAR2,
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN NUMBER DEFAULT cwms_util.false_num,
      p_versiondate       IN DATE DEFAULT cwms_util.non_versioned);

   /**
    * Stores time series data to the database
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_cwms_ts_id       The time series identifier
    * @param p_units            The unit of the data values
    * @param p_timeseries_data  The time series data
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_date     The version date of the data
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE store_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores time series data to the database using parameter types compatible with cx_Oracle Pyton package
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    * @see cwms_ts.number_array
    * @see cwms_ts.double_array
    *
    * @param p_cwms_ts_id       The time series identifier
    * @param p_units            The unit of the data values
    * @param p_times            The UTC times of the data values
    * @param p_values           The data values
    * @param p_qualities        The data quality codes for the data values
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_date     The version date of the data
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units           IN VARCHAR2,
      p_times           IN number_array,
      p_values          IN double_array,
      p_qualities       IN number_array,
      p_store_rule      IN VARCHAR2,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores time series data to the database using simple parameter types
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_cwms_ts_id       The time series identifier
    * @param p_units            The unit of the data values
    * @param p_times            The UTC times of the data values in Java milliseconds
    * @param p_values           The data values
    * @param p_qualities        The data quality codes for the data values
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_date     The version date of the data
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units           IN VARCHAR2,
      p_times           IN number_tab_t,
      p_values          IN number_tab_t,
      p_qualities       IN number_tab_t,
      p_store_rule      IN VARCHAR2,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores time series data for multiple time series to the database, allowing multiple version dates
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_timeseries_array The time series data to store
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_dates    The version dateS of the data in UTC, one for each time seires. If this parameter is NULL, all time series
    *                           will be stored as non-versioned. If any element is NULL, its corresponding time series will be stored as
    *                           non-versioned.
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE store_ts_multi (
      p_timeseries_array   IN timeseries_array,
      p_store_rule         IN VARCHAR2,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_dates      IN DATE_TABLE_TYPE DEFAULT NULL,
      p_office_id          IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores time series data for multiple time series to the database
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_timeseries_array The time series data to store
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_date     The version date of the data in UTC
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE store_ts_multi (
      p_timeseries_array   IN timeseries_array,
      p_store_rule         IN VARCHAR2,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_date       IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id          IN VARCHAR2 DEFAULT NULL);

   /**
    * Changes processing information for a time series
    *
    * @param p_ts_code                 The unique numeric code identifying the time series
    * @param p_interval_utc_offset     The new interval_utc_offset in minutes. Can only be changed if the time series has no data.
    * @param p_snap_forward_minutes    The new snap forward tolerance in minutes. This specifies how many minutes before the expected data time that data will be considered to be on time.
    * @param p_snap_backward_minutes   The new snap backward tolerance in minutes. This specifies how many minutes after the expected data time that data will be considered to be on time.
    * @param p_local_reg_time_zone_id  Not used.
    * @param p_ts_active_flag          A flag ('T' or 'F') specifying whether the time series is active
    */
   PROCEDURE update_ts_id (
      p_ts_code                  IN NUMBER,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes     IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN VARCHAR2 DEFAULT NULL);

   /**
    * Changes processing information for a time series
    *
    * @see constant cwms_util.utc_offset_irregular
    * @see constant cwms_util.utc_offset_undefined
    *
    * @param p_ts_id                   The time series identifier
    * @param p_interval_utc_offset     The new offset into the utc data interval in minutes.
    * Restrictions on changing include:
    * <ul>
    *   <li>Cannot change if time series is irregular interval. Use rename_ts</li>
    *   <li>Cannot change if time series is regular interval and has time series data</li>
    *   <li>Cannot change to <a href="cwms_util.utc_offset_irregular">cwms_util.utc_offset_irregular</a>. Use rename_ts</li>
    * </ul>
    * @param p_snap_forward_minutes    The new snap forward tolerance in minutes. This specifies how many minutes before the expected data time that data will be considered to be on time.
    * @param p_snap_backward_minutes   The new snap backward tolerance in minutes. This specifies how many minutes after the expected data time that data will be considered to be on time.
    * @param p_local_reg_time_zone_id  Not used.
    * @param p_ts_active_flag          A flag ('T' or 'F') specifying whether the time series is active
    * @param p_db_office_id            The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE update_ts_id (
      p_cwms_ts_id               IN VARCHAR2,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes     IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN VARCHAR2 DEFAULT NULL,
      p_db_office_id             IN VARCHAR2 DEFAULT NULL);

   /**
    * Renames a time series in the database
    *
    * @param p_office_id           The office that owns the time series. If not specified or NULL, the session user's default office is used.
    * @param p_timeseries_desc_old The existing time series identifier
    * @param p_timeseries_desc_new The new time series identifier
    */
   PROCEDURE rename_ts (p_office_id             IN VARCHAR2,
                        p_timeseries_desc_old   IN VARCHAR2,
                        p_timeseries_desc_new   IN VARCHAR2);

   /**
    * Renames a time series in the database, optionally setting a new regular interval offset.<p>
    * Restrictions on changing include:
    * <ul>
    *   <li>New time series identifier must agree with new/existing data interval and offset (regular/irregular)</li>
    *   <li>Cannot change time utc offset if from one regular offset to another if time series data exists</li>
    * </ul>
    *
    * @see constant cwms_util.utc_offset_irregular
    * @see constant cwms_util.utc_offset_undefined
    *
    * @param p_cwms_ts_id_old The existing time series identifier
    * @param p_cwms_ts_id_new The new time series identifier
    * @param p_utc_offset_new The new offset into the utc data interval in minutes.
    * @param p_office_id      The office that owns the time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE rename_ts (p_cwms_ts_id_old   IN VARCHAR2,
                        p_cwms_ts_id_new   IN VARCHAR2,
                        p_utc_offset_new   IN NUMBER DEFAULT NULL,
                        p_office_id        IN VARCHAR2 DEFAULT NULL);

   /**
    * Parses a time series identifier into its component parts
    *
    * @param p_cwms_ts_id         The time series identifier
    * @param p_base_location_id   The base location identifier
    * @param p_sub_location_id    The sub-location identifier, if any
    * @param p_base_parameter_id  The base parameter identifier
    * @param p_sub_parameter_id   The sub-parameter identifier, if any
    * @param p_parameter_type_id  The parameter type identifier
    * @param p_interval_id        The interval identifier
    * @param p_duration_id        The duration identifier
    * @param p_version_id         The version
    */
   PROCEDURE parse_ts (p_cwms_ts_id          IN     VARCHAR2,
                       p_base_location_id       OUT VARCHAR2,
                       p_sub_location_id        OUT VARCHAR2,
                       p_base_parameter_id      OUT VARCHAR2,
                       p_sub_parameter_id       OUT VARCHAR2,
                       p_parameter_type_id      OUT VARCHAR2,
                       p_interval_id            OUT VARCHAR2,
                       p_duration_id            OUT VARCHAR2,
                       p_version_id             OUT VARCHAR2);

   -- not documented
   PROCEDURE zretrieve_ts (p_at_tsv_rc      IN OUT SYS_REFCURSOR,
                           p_units          IN     VARCHAR2,
                           p_cwms_ts_id     IN     VARCHAR2,
                           p_start_time     IN     DATE,
                           p_end_time       IN     DATE,
                           p_trim           IN     VARCHAR2 DEFAULT 'F',
                           p_inclusive      IN     NUMBER DEFAULT NULL,
                           p_version_date   IN     DATE DEFAULT NULL,
                           p_max_version    IN     VARCHAR2 DEFAULT 'T',
                           p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   /**
    * Stores time series data to the database
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_cwms_ts_id       The time series identifier
    * @param p_units            The unit of the data values
    * @param p_timeseries_data  The time series data. The date_time fields of each element must be in UTC.
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_date     The version date of the data
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE zstore_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN ztsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores time series data for multiple time series to the database
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.replace_all
    * @see constant cwms_util.do_not_replace
    * @see constant cwms_util.replace_missing_values_only
    * @see constant cwms_util.replace_with_non_missing
    * @see constant cwms_util.delete_insert
    *
    * @param p_timeseries_array The time series data to store
    * @param p_store_rule       The store rule to use
    * @param p_override_prot    A flag ('T' or 'F') specifying whether to override the protection flag on any existing data value
    * @param p_version_date     The version date of the data
    * @param p_office_id        The office owning the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE zstore_ts_multi (
      p_timeseries_array   IN ztimeseries_array,
      p_store_rule         IN VARCHAR2,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_date       IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id          IN VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves time series data for a specified time series and time window
    *
    * @param p_transaction_time The UTC timestamp of when the routine was called.
    * @param p_at_tsv_rc       A cursor containing the time series data.  The cursor
    * contains the following columns, sorted by date_time:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date/time of the value, in UTC</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">value</td>
    *     <td class="descr">binary_double</td>
    *     <td class="descr">The data value</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">quality_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The quality code for the data value</td>
    *   </tr>
    * </table>
    * @param p_units_out       The unit of the retrieved data values
    * @param p_cwms_ts_id_out  The case-corrected version of the time series identifier
    * @param p_units_in        The unit to retrieve the data values in
    * @param p_cwms_ts_id_in   The time series identifier to retrieve data for
    * @param p_start_time      The start time of the time window
    * @param p_end_time        The end time of the time window
    * @param p_trim            A flag ('T' or 'F') that specifies whether to trim missing values from the beginning and end of the retrieved values
    * @param p_inclusive       A flag ('T' or 'F') that specifies whether the time window includes the start and end times
    * @param p_version_date    The version date of the data to retrieve. If not specified or NULL, the version date is determined by p_max_version
    * @param p_max_version     A flag ('T' or 'F') that specifies whether to retrieve the maximum ('T') or minimum ('F') version date if p_version_date is NULL
    * @param p_office_id       The office that owns the time series
    */
   PROCEDURE zretrieve_ts_java (
      p_transaction_time      OUT DATE,
      p_at_tsv_rc             OUT SYS_REFCURSOR,
      p_units_out             OUT VARCHAR2,
      p_cwms_ts_id_out        OUT VARCHAR2,
      p_units_in           IN     VARCHAR2,
      p_cwms_ts_id_in      IN     VARCHAR2,
      p_start_time         IN     DATE,
      p_end_time           IN     DATE,
      p_trim               IN     VARCHAR2 DEFAULT 'F',
      p_inclusive          IN     NUMBER DEFAULT NULL,
      p_version_date       IN     DATE DEFAULT NULL,
      p_max_version        IN     VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves existing date_times and version_dates for a time series for specified time series and item types.
    *
    * @param p_cursor  A cursor containing the date_times and version_dates that match the input parameters.
    * The cursor contains the following columns and will be sorted ascending by date_time and then by version_date:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date_time of an existing value (in UTC)</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The version date (in UTC) associated with the date_time</td>
    *   </tr>
    * </table>
    * @param p_ts_code          the unique numeric code identifying the time series
    * @param p_start_time_utc   the earliest date_time to retrieve. If not specified or null no earliest bound will be applied.
    * @param p_end_time_utc     the latest date_time to retrieve.  If not specified or null no latest bound will be applied.
    * @param p_date_times_utc   a table of date_times to use instead of p_start_time_utc and p_end_time_utc. If not specified or null, p_start_time_utc and p_end_time_utc will be used.
    * @param p_version_date_utc the version_date to retrieve times for. If not specified, or null, p_max_vesion will determine whether the earliest or latest version date is retrieved.
    * @param p_max_version      flag specifying whether to retrieve the latest (true) or earliest (false) version_date if p_version_date_utc is not specified or null.
    * @param p_item_mask        value specifying which time series items to retrieve times for (values, standard/non-standard text, binary)
    *
    * @since CWMS 2.1
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    * @see constant cwms_util.ts_values
    * @see constant cwms_util.ts_std_text
    * @see constant cwms_util.ts_text
    * @see constant cwms_util.ts_all_text
    * @see constant cwms_util.ts_binary
    * @see constant cwms_util.ts_all_non_values
    * @see constant cwms_util.ts_all
    */
   PROCEDURE retrieve_existing_times(
      p_cursor           OUT sys_refcursor,
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE,
      p_item_mask        IN  BINARY_INTEGER  DEFAULT cwms_util.ts_all);

   /**
    * Retrieves existing date_times and version_dates for a time series for specified time series and item types.
    *
    * @param p_ts_code          the unique numeric code identifying the time series
    * @param p_start_time_utc   the earliest date_time to retrieve. If not specified or null no earliest bound will be applied.
    * @param p_end_time_utc     the latest date_time to retrieve.  If not specified or null no latest bound will be applied.
    * @param p_date_times_utc   a table of date_times to use instead of p_start_time_utc and p_end_time_utc. If not specified or null, p_start_time_utc and p_end_time_utc will be used.
    * @param p_version_date_utc the version_date to retrieve times for. If not specified, or null, p_max_vesion will determine whether the earliest or latest version date is retrieved.
    * @param p_max_version      flag specifying whether to retrieve the latest (true) or earliest (false) version_date if p_version_date_utc is not specified or null.
    * @param p_item_mask        value specifying which time series items to retrieve times for (values, standard/non-standard text, binary)
    *
    * @return  A cursor containing the date_times and version_dates that match the input parameters.
    * The cursor contains the following columns and will be sorted ascending by date_time and then by version_date:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date_time of an existing value (in UTC)</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The version date (in UTC) associated with the date_time</td>
    *   </tr>
    * </table>
    *
    * @since CWMS 2.1
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    * @see constant cwms_util.ts_values
    * @see constant cwms_util.ts_std_text
    * @see constant cwms_util.ts_text
    * @see constant cwms_util.ts_all_text
    * @see constant cwms_util.ts_binary
    * @see constant cwms_util.ts_all_non_values
    * @see constant cwms_util.ts_all
    */
   FUNCTION retrieve_existing_times_f(
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE,
      p_item_mask        IN  BINARY_INTEGER  DEFAULT cwms_util.ts_all)
      RETURN sys_refcursor;

   /**
    * Retrieves existing date_times, version_dates, and counts of time series item types for a specified time series.
    *
    * @param p_cursor  A cursor containing the date_times, version_datesm and item counts that match the input parameters.
    * The cursor contains the following columns and will be sorted ascending by date_time and then by version_date:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date_time of an existing value (in UTC)</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The version date (in UTC) associated with the date_time</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">value_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of values (0/1) for the date_time and vesion_date</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">std_text_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of standard text items (>=0) for the date_time and vesion_date</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">text_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of non-standard text items (>=0) for the date_time and vesion_date</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">binary_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of binary items (>=0) for the date_time and vesion_date</td>
    *   </tr>
    * </table>
   * @param p_ts_code          the unique numeric code identifying the time series
    * @param p_start_time_utc   the earliest date_time to retrieve. If not specified or null no earliest bound will be applied.
    * @param p_end_time_utc     the latest date_time to retrieve.  If not specified or null no latest bound will be applied.
    * @param p_date_times_utc   a table of date_times to use instead of p_start_time_utc and p_end_time_utc. If not specified or null, p_start_time_utc and p_end_time_utc will be used.
    * @param p_version_date_utc the version_date to retrieve times for. If not specified, or null, p_max_vesion will determine whether the earliest or latest version date is retrieved.
    * @param p_max_version      flag specifying whether to retrieve the latest (true) or earliest (false) version_date if p_version_date_utc is not specified or null.
    *
    * @since CWMS 2.1
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    */
   PROCEDURE retrieve_existing_item_counts(
      p_cursor           OUT sys_refcursor,
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE);

   /**
    * Retrieves existing date_times, version_dates, and counts of time series item types for a specified time series.
    *
    * @param p_ts_code          the unique numeric code identifying the time series
    * @param p_start_time_utc   the earliest date_time to retrieve. If not specified or null no earliest bound will be applied.
    * @param p_end_time_utc     the latest date_time to retrieve.  If not specified or null no latest bound will be applied.
    * @param p_date_times_utc   a table of date_times to use instead of p_start_time_utc and p_end_time_utc. If not specified or null, p_start_time_utc and p_end_time_utc will be used.
    * @param p_version_date_utc the version_date to retrieve times for. If not specified, or null, p_max_vesion will determine whether the earliest or latest version date is retrieved.
    * @param p_max_version      flag specifying whether to retrieve the latest (true) or earliest (false) version_date if p_version_date_utc is not specified or null.
    *
    * @return  A cursor containing the date_times, version_datesm and item counts that match the input parameters.
    * The cursor contains the following columns and will be sorted ascending by date_time and then by version_date:
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
    *     <td class="descr">date_time</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The date_time of an existing value (in UTC)</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">version_date</td>
    *     <td class="descr">date</td>
    *     <td class="descr">The version date (in UTC) associated with the date_time</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">value_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of values (0/1) for the date_time and vesion_date</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">std_text_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of standard text items (>=0) for the date_time and vesion_date</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">text_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of non-standard text items (>=0) for the date_time and vesion_date</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">binary_count</td>
    *     <td class="descr">integer</td>
    *     <td class="descr">The number of binary items (>=0) for the date_time and vesion_date</td>
    *   </tr>
    * </table>
    *
    * @since CWMS 2.1
    *
    * @see constant cwms_util.non_versioned
    * @see constant cwms_util.all_version_dates
    */
   FUNCTION retrieve_existing_item_counts(
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE)
      RETURN sys_refcursor;

   -- not documented
   PROCEDURE collect_deleted_times (p_deleted_time   IN TIMESTAMP,
                                    p_ts_code        IN NUMBER,
                                    p_version_date   IN DATE,
                                    p_start_time     IN DATE,
                                    p_end_time       IN DATE);

   -- not documented
   PROCEDURE retrieve_deleted_times (
      p_deleted_times      OUT date_table_type,
      p_deleted_time    IN     NUMBER,
      p_ts_code         IN     NUMBER,
      p_version_date    IN     NUMBER);

   -- not documented
   FUNCTION retrieve_deleted_times_f (p_deleted_time   IN NUMBER,
                                      p_ts_code        IN NUMBER,
                                      p_version_date   IN NUMBER)
      RETURN date_table_type;

   -- not documented
   PROCEDURE create_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   -- not documented
   PROCEDURE delete_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   -- not documented
   PROCEDURE rename_parameter_id (
      p_parameter_id_old   IN VARCHAR2,
      p_parameter_id_new   IN VARCHAR2,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL);

   /**
    * Registers a callback procedure to be notified of enqueued messages
    *
    * @see cwms_msg.register_msg_callback
    *
    * @param p_procedure_name   The name of the procedure to register.  This can be a free standing or package procedure and must have exactly the following signature:<p>
    * <big><pre>
    * procedure procedure_name (
    *      context  in raw,
    *      reginfo  in sys.aq$_reg_info,
    *      descr    in sys.aq$_descriptor,
    *      payload  in raw,
    *      payloadl in number);
    * </pre></big>
    * @param p_subscriber_name  The subscriber name, unique per queue. If not specified or NULL, a unique subscriber name will be generated.
    * @param p_queue_name       The queue name to subscibe to. If not specified or NULL, the TS_DATA_STORED queue for the session user's default office is used
    *
    * @return The subscriber name (specified or generated) used to register the callback procedure
    */
   FUNCTION register_ts_callback (
      p_procedure_name    IN VARCHAR2,
      p_subscriber_name   IN VARCHAR2 DEFAULT NULL,
      p_queue_name        IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   /**
    * Unregisters a callback procedure from a queue
    *
    * @see cwms_msg.unregister_msg_callback
    *
    * @param p_procedure_name   The name of the procedure to unregister
    * @param p_subscriber_name  The subscriber name. This must be the same value returned from register_ts_callback
    * @param p_queue_name       The queue name to unsubscibe from. If not specified or NULL, the TS_DATA_STORED queue for the session user's default office is used
    */
   PROCEDURE unregister_ts_callback (
      p_procedure_name    IN VARCHAR2,
      p_subscriber_name   IN VARCHAR2,
      p_queue_name        IN VARCHAR2 DEFAULT NULL);

   -- not documented
   PROCEDURE refresh_ts_catalog;

   /**
    * Stores a time series category
    *
    * @param p_ts_category_id   The time series category identifier
    * @param p_ts_category_desc A description of the time series category
    * @param p_fail_if_exists   A flag ('T' or 'F') that specifies whether the routine should fail if the time series category already exists
    * @param p_ignore_null      A flag ('T' or 'F') that specifies whether to ignore a NULL description when updating a category
    * @param p_db_office_id     The office that owns the time series category. If not specified or NULL, the session user's default office is used.
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the time series category already exists
    */
   PROCEDURE store_ts_category (
      p_ts_category_id     IN VARCHAR2,
      p_ts_category_desc   IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
      p_ignore_null        IN VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores a time series category, returning its unique numeric code
    *
    * @param p_ts_category_id   The time series category identifier
    * @param p_ts_category_desc A description of the time series category
    * @param p_fail_if_exists   A flag ('T' or 'F') that specifies whether the routine should fail if the time series category already exists
    * @param p_ignore_null      A flag ('T' or 'F') that specifies whether to ignore a NULL description when updating a category
    * @param p_db_office_id     The office that owns the time series category. If not specified or NULL, the session user's default office is used.
    *
    * @return The unique numeric code that identifies the time series category
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the time series category already exists
    */
   FUNCTION store_ts_category_f (
      p_ts_category_id     IN VARCHAR2,
      p_ts_category_desc   IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
      p_ignore_null        IN VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   /**
    * Renames a time series category in the database
    *
    * @param p_ts_category_id_old The existing identifier of the time series category
    * @param p_ts_category_id_new The new identifier of the time series category
    * @param p_db_office_id       The office that owns the time series category. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE rename_ts_category (
      p_ts_category_id_old   IN VARCHAR2,
      p_ts_category_id_new   IN VARCHAR2,
      p_db_office_id         IN VARCHAR2 DEFAULT NULL);

   /**
    * Deletes a time series category from the database
    *
    * @param p_ts_category_id The time series category identifier
    * @param p_cascade        A flag ('T' or 'F') that specifies whether to delete any time series groups in the category
    * @param p_db_office_id   The office that owns the time series category. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE delete_ts_category (p_ts_category_id   IN VARCHAR2,
                                 p_cascade          IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores a time series group
    *
    * @param p_ts_category_id   The time series category that owns the time series group
    * @param p_ts_group_id      The time series group identifier
    * @param p_ts_group_desc    A description of the time series group
    * @param p_fail_if_exists   A flag ('T' or 'F') that specifies whether the routine should fail if the time series group already exists
    * @param p_ignore_nulls     A flag ('T' or 'F') that specifies whether to ignore a NULL parameters when updating. If 'T' no data will be overwritten with NULL
    * @param p_shared_alias_id  An alias, if any, that applies to all members of the time series group
    * @param p_shared_ts_ref_id A reference to a time series, if any, that applies to all members of the time series group
    * @param p_db_office_id     The office that owns the time series group. If not specified or NULL, the session user's default office is used.
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the time series group already exists
    */
   PROCEDURE store_ts_group (p_ts_category_id     IN VARCHAR2,
                             p_ts_group_id        IN VARCHAR2,
                             p_ts_group_desc      IN VARCHAR2 DEFAULT NULL,
                             p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
                             p_ignore_nulls       IN VARCHAR2 DEFAULT 'T',
                             p_shared_alias_id    IN VARCHAR2 DEFAULT NULL,
                             p_shared_ts_ref_id   IN VARCHAR2 DEFAULT NULL,
                             p_db_office_id       IN VARCHAR2 DEFAULT NULL);

   /**
    * Stores a time series group, returning its unique numeric code
    *
    * @param p_ts_category_id   The time series category that owns the time series group
    * @param p_ts_group_id      The time series group identifier
    * @param p_ts_group_desc    A description of the time series group
    * @param p_fail_if_exists   A flag ('T' or 'F') that specifies whether the routine should fail if the time series group already exists
    * @param p_ignore_nulls     A flag ('T' or 'F') that specifies whether to ignore a NULL parameters when updating. If 'T' no data will be overwritten with NULL
    * @param p_shared_alias_id  An alias, if any, that applies to all members of the time series group
    * @param p_shared_ts_ref_id A reference to a time series, if any, that applies to all members of the time series group
    * @param p_db_office_id     The office that owns the time series group. If not specified or NULL, the session user's default office is used.
    *
    * @return The unique numeric code that identifies the time series group
    *
    * @exception ITEM_ALREADY_EXISTS if p_fail_if_exists is 'T' and the time series group already exists
    */
   FUNCTION store_ts_group_f (p_ts_category_id     IN VARCHAR2,
                              p_ts_group_id        IN VARCHAR2,
                              p_ts_group_desc      IN VARCHAR2 DEFAULT NULL,
                              p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
                              p_ignore_nulls       IN VARCHAR2 DEFAULT 'T',
                              p_shared_alias_id    IN VARCHAR2 DEFAULT NULL,
                              p_shared_ts_ref_id   IN VARCHAR2 DEFAULT NULL,
                              p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   /**
    * Renames a time series group in the database
    *
    * @param p_ts_category_id   The time series category that owns the time series group
    * @param p_ts_group_id_old  The existing identifier of the time series group
    * @param p_ts_group_id_new  The new identifier of the time series group
    * @param p_db_office_id     The office that owns the time series group. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE rename_ts_group (p_ts_category_id    IN VARCHAR2,
                              p_ts_group_id_old   IN VARCHAR2,
                              p_ts_group_id_new   IN VARCHAR2,
                              p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   /**
    * Deletes a time series group from the database
    *
    * @param p_ts_category_id The time series category that owns the time series group
    * @param p_ts_group_id    The time series group identifier
    * @param p_db_office_id   The office that owns the time series group. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE delete_ts_group (p_ts_category_id   IN VARCHAR2,
                              p_ts_group_id      IN VARCHAR2,
                              p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   /**
    * Assigns a time series to a time series group
    *
    * @param p_ts_category_id The time series category that owns the time series group
    * @param p_ts_group_id    The time series group identifier
    * @param p_ts_id          The time series identifier to assign to the group
    * @param p_ts_attribute   A numeric attribute value, if any, that is associated with the time series within the group. Can be used for sorting, etc.
    * @param p_ts_alias_id    An alias, if any, that applies to the timeseries within the group
    * @param p_ref_ts_id      A time series identifier, if any, that is referred to by the time series within the group
    * @param p_db_office_id   The office that owns the time series category, time series group and time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE assign_ts_group (p_ts_category_id   IN VARCHAR2,
                              p_ts_group_id      IN VARCHAR2,
                              p_ts_id            IN VARCHAR2,
                              p_ts_attribute     IN NUMBER DEFAULT NULL,
                              p_ts_alias_id      IN VARCHAR2 DEFAULT NULL,
                              p_ref_ts_id        IN VARCHAR2 DEFAULT NULL,
                              p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   /**
    * Unassigns a time series, or all time series from time series group
    *
    * @param p_ts_category_id The time series category that owns the time series group
    * @param p_ts_group_id    The time series group identifier
    * @param p_ts_id          The time series identifier to assign to the group. Can be NULL if p_unassign_all is 'T'
    * @param p_unassign_all   A flag ('T' or 'F') that specifies whether to un-assign all time series from the group.
    * @param p_db_office_id   The office that owns the time series category, time series group and time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE unassign_ts_group (p_ts_category_id   IN VARCHAR2,
                                p_ts_group_id      IN VARCHAR2,
                                p_ts_id            IN VARCHAR2,
                                p_unassign_all     IN VARCHAR2 DEFAULT 'F',
                                p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   /**
    * Assigns a collection of time series to a time series group
    *
    * @param p_ts_category_id The time series category that owns the time series group
    * @param p_ts_group_id    The time series group identifier
    * @param p_ts_alias_array The time series identifiers and associated information to assign to the group
    * @param p_db_office_id   The office that owns the time series category, time series group and time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE assign_ts_groups (p_ts_category_id   IN VARCHAR2,
                               p_ts_group_id      IN VARCHAR2,
                               p_ts_alias_array   IN ts_alias_tab_t,
                               p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   /**
    * Un-assigns a collection of time series from a time series group
    *
    * @param p_ts_category_id The time series category that owns the time series group
    * @param p_ts_group_id    The time series group identifier
    * @param p_ts_alias_array The time series identifiers to un-assign. Can be NULL if p_unassign_all is 'T'
    * @param p_unassign_all   A flag ('T' or 'F') that specifies whether to un-assign all time series from the group.
    * @param p_db_office_id   The office that owns the time series category, time series group and time series. If not specified or NULL, the session user's default office is used.
    */
   PROCEDURE unassign_ts_groups (p_ts_category_id   IN VARCHAR2,
                                 p_ts_group_id      IN VARCHAR2,
                                 p_ts_array         IN str_tab_t,
                                 p_unassign_all     IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   /**
    * Retrieve a time series identifier from a time series group alias
    *
    * @param p_alias_id     The time series alias within the time series group
    * @param p_group_id     The time series group identifier
    * @param p_category_id  The time series category that owns the time series group
    * @param p_db_office_id The office that owns the time series category, time series group and time series. If not specified or NULL, the session user's default office is used.
    *
    * @return The time series identifier
    */
   FUNCTION get_ts_id_from_alias (p_alias_id      IN VARCHAR2,
                                  p_group_id      IN VARCHAR2 DEFAULT NULL,
                                  p_category_id   IN VARCHAR2 DEFAULT NULL,
                                  p_office_id     IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   /**
    * Retrieve the unique numeric code identifying a time series from a time series group alias
    *
    * @param p_alias_id     The time series alias within the time series group
    * @param p_group_id     The time series group identifier
    * @param p_category_id  The time series category that owns the time series group
    * @param p_db_office_id The office that owns the time series category, time series group and time series. If not specified or NULL, the session user's default office is used.
    *
    * @return The unique numeric code that identifies the time series
    */
   FUNCTION get_ts_code_from_alias (p_alias_id      IN VARCHAR2,
                                    p_group_id      IN VARCHAR2 DEFAULT NULL,
                                    p_category_id   IN VARCHAR2 DEFAULT NULL,
                                    p_office_id     IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER;

   /**
    * Retrieves a time series identifier from an identifier that may be a time series or alias identifier
    *
    * @param p_ts_id_or_alias The identifier that may be a time series or alias identifier
    * @param p_office_id      The office that owns the time series
    *
    * @return The time series identifier
    */
   FUNCTION get_ts_id (p_ts_id_or_alias IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN VARCHAR2;

   /**
    * Retrieves the unique numeric code identifying a time series from an identifier that may be a time series or alias identifier
    *
    * @param p_ts_id_or_alias The identifier that may be a time series or alias identifier
    * @param p_office_id      The office that owns the time series
    *
    * @return The unique numeric code identifying the time series
    */
   FUNCTION get_ts_id (p_ts_id_or_alias IN VARCHAR2, p_office_code IN NUMBER)
      RETURN VARCHAR2;

   /**
    * Retrieves a text description of the validity portion of a quality code
    *
    * @param p_quality_code The quality code
    *
    * @return The text description of the validity portion of the quality code
    */
   FUNCTION get_quality_validity (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE;

   /**
    * Retrieves a text description of the validity portion of the quality code of a time series value
    *
    * @param p_value The time series value
    *
    * @return The text description of the validity portion of the quality code
    */
   FUNCTION get_quality_validity (p_value IN tsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves a text description of the validity portion of the quality code of a time series value
    *
    * @param p_value The time series value
    *
    * @return The text description of the validity portion of the quality code
    */
   FUNCTION get_quality_validity (p_value IN ztsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether a quality code is marked as okay
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as okay
    */
   FUNCTION quality_is_okay (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as okay
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as okay
    */
   FUNCTION quality_is_okay (p_value IN tsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether the quality code of a time series value is marked as okay
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as okay
    */
   FUNCTION quality_is_okay (p_value IN ztsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether a quality code is marked as okay
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as okay as text ('T'/'F')
    */
   FUNCTION quality_is_okay_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as okay
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as okay as text ('T'/'F')
    */
   FUNCTION quality_is_okay_text (p_value IN tsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether the quality code of a time series value is marked as okay
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as okay as text ('T'/'F')
    */
   FUNCTION quality_is_okay_text (p_value IN ztsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether a quality code is marked as missing
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as missing
    */
   FUNCTION quality_is_missing (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as missing
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as missing
    */
   FUNCTION quality_is_missing (p_value IN tsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether the quality code of a time series value is marked as missing
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as missing
    */
   FUNCTION quality_is_missing (p_value IN ztsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether a quality code is marked as missing
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as missing as text ('T'/'F')
    */
   FUNCTION quality_is_missing_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as missing
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as missing as text ('T'/'F')
    */
   FUNCTION quality_is_missing_text (p_value IN tsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether the quality code of a time series value is marked as missing
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as missing as text ('T'/'F')
    */
   FUNCTION quality_is_missing_text (p_value IN ztsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether a quality code is marked as questionable
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as questionable
    */
   FUNCTION quality_is_questionable (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as questionable
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as questionable
    */
   FUNCTION quality_is_questionable (p_value IN tsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether the quality code of a time series value is marked as questionable
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as questionable
    */
   FUNCTION quality_is_questionable (p_value IN ztsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether a quality code is marked as questionable
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as questionable as text ('T'/'F')
    */
   FUNCTION quality_is_questionable_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as questionable
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as questionable as text ('T'/'F')
    */
   FUNCTION quality_is_questionable_text (p_value IN tsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether the quality code of a time series value is marked as questionable
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as questionable as text ('T'/'F')
    */
   FUNCTION quality_is_questionable_text (p_value IN ztsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether a quality code is marked as rejected
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as rejected
    */
   FUNCTION quality_is_rejected (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as rejected
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as rejected
    */
   FUNCTION quality_is_rejected (p_value IN tsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether the quality code of a time series value is marked as rejected
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as rejected
    */
   FUNCTION quality_is_rejected (p_value IN ztsv_type)
      RETURN BOOLEAN;

   /**
    * Retrieves whether a quality code is marked as rejected
    *
    * @param p_quality_code The quality code
    *
    * @return Whether the quality code is marked as rejected  as text ('T'/'F')
    */
   FUNCTION quality_is_rejected_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE;

   /**
    * Retrieves whether the quality code of a time series value is marked as rejected
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as rejected as text ('T'/'F')
    */
   FUNCTION quality_is_rejected_text (p_value IN tsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves whether the quality code of a time series value is marked as rejected
    *
    * @param p_value The time series value
    *
    * @return Whether the quality code is marked as rejected  as text ('T'/'F')
    */
   FUNCTION quality_is_rejected_text (p_value IN ztsv_type)
      RETURN VARCHAR2;

   /**
    * Retrieves a text description for a quality code
    *
    * @param p_quality_code The quality code
    *
    * @return A text description for the quality code
    */
   FUNCTION get_quality_description (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE;

   /**
    * Retrieves the interval minutes of a time series
    *
    * @param p_ts_code the unique numeric value identifying the time series
    *
    * @return the interval minutes of the time series identifier
    */
   FUNCTION get_ts_interval (p_ts_code IN NUMBER)
      RETURN NUMBER RESULT_CACHE;

   /**
    * Retrieves the interval minutes of a time series identifier
    *
    * @param p_cwms_ts_id the time series identifier
    *
    * @return the interval minutes of the time series identifier
    */
   FUNCTION get_ts_interval (p_cwms_ts_id IN VARCHAR2)
      RETURN NUMBER RESULT_CACHE;

   /**
    * Retrieves the interval portion string of a time series identifier
    *
    * @param p_cwms_ts_id the time series identifier
    *
    * @return the interval portion string of the time series identifier
    */
   FUNCTION get_ts_interval_string (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2 RESULT_CACHE;

   /**
    * Retrieves the interval minutes of a specified interval string
    *
    * @param p_interval_id the time series identifier
    *
    * @return the interval minutes of the specified interval string
    */
   FUNCTION get_interval (p_interval_id IN VARCHAR2)
      RETURN NUMBER RESULT_CACHE;

   /**
    * Returns the UTC interval offset for a specified time and interval
    *
    * @param p_date_time_utc    the date/time
    * @param p_interval_minutes the interval in minutes
    *
    * @return the UTC interval offset in minuts
    */
   FUNCTION get_utc_interval_offset (
      p_date_time_utc    IN DATE,
      p_interval_minutes IN NUMBER)
      RETURN NUMBER RESULT_CACHE;
   /**
    * Returns a table of valid date/times in a specified time window for a regular time series
    *
    * @param p_start_time the start time of the time window
    * @param p_end_time   the end time of the time window
    * @param p_interval_minutes the interval for the time series, specified in minutes
    * @param p_utc_interval_offset_minutes The valid offset in minutes into the UTC interval for the time series
    * @param p_time_zone the time zone of the input and output values. If null or not specified, the time zone 'UTC' is used.
    *
    * @return the table of valid date/times for the specified parameters
    */
   FUNCTION get_times_for_time_window (
      p_start_time                  IN DATE,
      p_end_time                    IN DATE,
      p_interval_minutes            IN INTEGER,
      p_utc_interval_offset_minutes IN INTEGER,
      p_time_zone                   IN VARCHAR2 DEFAULT 'UTC')
      RETURN date_table_type;
   /**
    * Returns a table of valid date/times in a specified time window for a regular time series
    *
    * @param p_start_time the start time of the time window
    * @param p_end_time   the end time of the time window
    * @param p_ts_code    the unique numeric code identifying the time series
    * @param p_time_zone the time zone of the input and output values. If null or not specified, the time zone 'UTC' is used.
    *
    * @return the table of valid date/times for the time series
    */
   FUNCTION get_times_for_time_window (
      p_start_time IN DATE,
      p_end_time   IN DATE,
      p_ts_code    IN INTEGER,
      p_time_zone  IN VARCHAR2 DEFAULT 'UTC')
      RETURN date_table_type;
   /**
    * Returns a table of valid date/times in a specified time window for a regular time series
    *
    * @param p_start_time the start time of the time window
    * @param p_end_time   the end time of the time window
    * @param p_ts_id      the time series identifier
    * @param p_time_zone  the time zone of the input and output values. If null or not specified, the time zone 'UTC' is used.
    * @param p_office_id  the identifier of the office that owns the time series. If not specified or NULL, the session user's default office is used.
    *
    * @return the table of valid date/times for the time series
    */
   FUNCTION get_times_for_time_window (
      p_start_time IN DATE,
      p_end_time   IN DATE,
      p_ts_id      IN VARCHAR2,
      p_time_zone  IN VARCHAR2 DEFAULT 'UTC',
      p_office_id  IN VARCHAR2 DEFAULT NULL)
      RETURN date_table_type;
   /**
    * Retrieves the earliest non-null time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    *
    * @return The earliest non-null time series data date in the database for the time series, in UTC
    */
   FUNCTION get_ts_min_date_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE;

   /**
    * Retrieves the earliest non-null time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone in which to retrieve the earliest time
    * @param p_version_date The version date of the time series in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    *
    * @return The earliest non-null time series data date in the database for the time series, in the specified time zone
    */
   FUNCTION get_ts_min_date (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE;

   /**
    * Retrieves the latest non-null time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    *
    * @return The latest non-null time series data date in the database for the time series, in UTC
    */
   FUNCTION get_ts_max_date_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE;

 /**
    * Retrieves the latest time series data date in the database for a time series but returns NULL if no records exist in the at_tsv_xxxx table
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    * @param p_year             The optional year to search in; entering this year will speed the query by not searching additional tsv tables
    *
    * PL/SQL usage to obtain the max date in the current year
    * CWMS_TS.GET_TS_MAX_DATE_UTC_2(p_ts_code
    *                               , TO_DATE('1111-11-11','YYYY-MM-DD')
    *                               , TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
    *                                ) ts_max_date
    *
    * @return The latest time series data date in the database for the time series, in UTC
    */

   FUNCTION get_ts_max_date_utc_2 (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned,
      p_year               IN NUMBER DEFAULT NULL)
      RETURN DATE;      

   /**
    * Retrieves the latest non-null time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone in which to retrieve the latest time
    * @param p_version_date The version date of the time series in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    *
    * @return The latest non-null time series data date in the database for the time series, in the specified time zone
    */
   FUNCTION get_ts_max_date (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE;

   /**
    * Retrieves the earliest and latest non-null time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_min_date_utc     The earliest non-null time series data date in the database for the time series, in UTC
    * @param p_max_date_utc     The latest non-null time series data date in the database for the time series, in UTC
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    */
   PROCEDURE get_ts_extents_utc (
      p_min_date_utc          OUT DATE,
      p_max_date_utc          OUT DATE,
      p_ts_code            IN     NUMBER,
      p_version_date_utc   IN     DATE DEFAULT cwms_util.non_versioned);

   /**
    * Retrieves the earliest and latest non-null time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_min_date     The earliest non-null time series data date in the database for the time series, in the specified time zone
    * @param p_max_date     The latest non-null time series data date in the database for the time series, in the specified time zone
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone to use
    * @param p_version_date The version date of the time series, in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE get_ts_extents (
      p_min_date          OUT DATE,
      p_max_date          OUT DATE,
      p_cwms_ts_id     IN     VARCHAR2,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN     DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves the earliest time series data date (even if value is null) in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    *
    * @return The earliest time series data date (even if value is null) in the database for the time series, in UTC
    */
   FUNCTION get_ts_min_date2_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE;

   /**
    * Retrieves the earliest time series data date (even if value is null) in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone in which to retrieve the earliest time
    * @param p_version_date The version date of the time series in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    *
    * @return The earliest time series data date (even if value is null) in the database for the time series, in the specified time zone
    */
   FUNCTION get_ts_min_date2 (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE;

   /**
    * Retrieves the latest time series data date (even if value is null) in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    *
    * @return The latest time series data date (even if value is null) in the database for the time series, in UTC
    */
   FUNCTION get_ts_max_date2_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE;

   /**
    * Retrieves the latest time series data date (even if value is null) in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone in which to retrieve the latest time
    * @param p_version_date The version date of the time series in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    *
    * @return The latest time series data date (even if value is null) in the database for the time series, in the specified time zone
    */
   FUNCTION get_ts_max_date2 (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE;

   /**
    * Retrieves the earliest and latest time series data date (even if value is null) in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_min_date_utc     The earliest time series data date (even if value is null) in the database for the time series, in UTC
    * @param p_max_date_utc     The latest time series data date (even if value is null) in the database for the time series, in UTC
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    */
   PROCEDURE get_ts_extents2_utc (
      p_min_date_utc          OUT DATE,
      p_max_date_utc          OUT DATE,
      p_ts_code            IN     NUMBER,
      p_version_date_utc   IN     DATE DEFAULT cwms_util.non_versioned);

   /**
    * Retrieves the earliest and latest time series data date (even if value is null) in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_min_date     The earliest time series data date (even if value is null) in the database for the time series, in the specified time zone
    * @param p_max_date     The latest time series data date (even if value is null) in the database for the time series, in the specified time zone
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone to use
    * @param p_version_date The version date of the time series, in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    */
   PROCEDURE get_ts_extents2 (
      p_min_date          OUT DATE,
      p_max_date          OUT DATE,
      p_cwms_ts_id     IN     VARCHAR2,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN     DATE DEFAULT cwms_util.non_versioned,
      p_office_id      in     varchar2 default null);
   /**
    * Retrieves UTC time and value extents for a specified time series and version date in specified units
    *
    * @param p_ts_extents   The time series extents
    * @param p_cwms_ts_id   The time series identifier
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @see type ts_extents_t
    */
   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_cwms_ts_id   in  varchar2,
      p_version_date in  date,
      p_unit         in  varchar2 default null, 
      p_office_id    in  varchar2 default null);
   /**
    * Retrieves UTC time and value extents for a specified time series and version date in specified units
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @return The time series extents
    *
    * @see type ts_extents_t
    */
   function get_ts_extents_f(
      p_cwms_ts_id   in varchar2,
      p_version_date in date,
      p_unit         in varchar2 default null,
      p_office_id    in varchar2 default null)
      return ts_extents_t;
   /**
    * Retrieves UTC time and value extents for a specified time series and version date in specified units
    *
    * @param p_ts_extents   The time series extents
    * @param p_ts_code      The unique numeric value identifying the time series
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @see type ts_extents_t
    */
   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_ts_code      in  integer,
      p_version_date in  date,
      p_unit         in  varchar2 default null);
   /**
    * Retrieves UTC time and value extents for a specified time series and version date in specified units
    *
    * @param p_ts_code      The unique numeric value identifying the time series
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @return The time series extents
    *
    * @see type ts_extents_t
    */
   function get_ts_extents_f(
      p_ts_code      in integer,
      p_version_date in date,
      p_unit         in varchar2 default null)
      return ts_extents_t;
   /**
    * Retrieves UTC time and value extents for all version dates of a specified time series in specified units
    *
    * @param p_ts_extents   The time series extents
    * @param p_cwms_ts_id   The time series identifier
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @see type ts_extents_tab_t
    */
   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_cwms_ts_id in  varchar2,
      p_unit       in  varchar2 default null,
      p_office_id  in  varchar2 default null);
   /**
    * Retrieves UTC time and value extents for all version dates of a specified time series in specified units
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @return The time series extents
    *
    * @see type ts_extents_tab_t
    */
   function get_ts_extents_f(
      p_cwms_ts_id in varchar2,
      p_unit       in varchar2 default null,
      p_office_id  in varchar2 default null)
      return ts_extents_tab_t;
   /**
    * Retrieves UTC time and value extents for all version dates of a specified time series in specified units
    *
    * @param p_ts_extents   The time series extents
    * @param p_ts_code      The unique numeric value identifying the time series
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @see type ts_extents_tab_t
    */
   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_ts_code    in  integer,
      p_unit       in  varchar2 default null);
   /**
    * Retrieves UTC time and value extents for all version dates of a specified time series in specified units
    *
    * @param p_ts_code      The unique numeric value identifying the time series
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @return The time series extents
    *
    * @see type ts_extents_tab_t
    */
   function get_ts_extents_f(
      p_ts_code in integer,
      p_unit    in varchar2 default null)
      return ts_extents_tab_t;
   /**
    * Retrieves time and value extents for a specified time series and version date in specified time zone and units
    *
    * @param p_ts_extents   The time series extents
    * @param p_cwms_ts_id   The time series identifier
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @see type ts_extents_t
    */
   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_cwms_ts_id   in  varchar2,
      p_version_date in  date,
      p_time_zone    in  varchar2,
      p_unit         in  varchar2 default null,
      p_office_id    in  varchar2 default null);
   /**
    * Retrieves time and value extents for a specified time series and version date in specified time zone and units
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @return The time series extents
    *
    * @see type ts_extents_t
    */
   function get_ts_extents_f(
      p_cwms_ts_id   in varchar2,
      p_version_date in date,
      p_time_zone    in varchar2,
      p_unit         in varchar2 default null,
      p_office_id    in varchar2 default null)
      return ts_extents_t;
   /**
    * Retrieves time and value extents for a specified time series and version date in specified time zone and units
    *
    * @param p_ts_extents   The time series extents
    * @param p_ts_code      The unique nummeric value identifying the time series
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @see type ts_extents_t
    */
   procedure get_ts_extents(
      p_ts_extents   out ts_extents_t,
      p_ts_code      in  integer,
      p_version_date in  date,
      p_time_zone    in  varchar2,
      p_unit         in  varchar2 default null);
   /**
    * Retrieves time and value extents for a specified time series and version date in specified time zone and units
    *
    * @param p_ts_code      The unique nummeric value identifying the time series
    * @param p_version_date The version date. If null, the non-versioned date '1111-11-11 00:00:00' is used
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @return The time series extents
    *
    * @see type ts_extents_t
    */
   function get_ts_extents_f(
      p_ts_code      in integer,
      p_version_date in date,
      p_time_zone    in varchar2,
      p_unit         in varchar2 default null)
      return ts_extents_t;
   /**
    * Retrieves time and value extents for a all version dates of a specified time series in specified time zone and units
    *
    * @param p_ts_extents   The time series extents
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @see type ts_extents_tab_t
    */
   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_cwms_ts_id in  varchar2,
      p_time_zone  in  varchar2,
      p_unit       in  varchar2 default null,
      p_office_id  in  varchar2 default null);
   /**
    * Retrieves time and value extents for a all version dates of a specified time series in specified time zone and units
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    * @param p_office_id    The office that owns the time series. If unspecified or null the current session user's default office is used
    *
    * @return The time series extents
    *
    * @see type ts_extents_tab_t
    */
   function get_ts_extents_f(
      p_cwms_ts_id in varchar2,
      p_time_zone  in varchar2,
      p_unit       in varchar2 default null,
      p_office_id  in varchar2 default null)
      return ts_extents_tab_t;
   /**
    * Retrieves time and value extents for a all version dates of a specified time series in specified time zone and units
    *
    * @param p_ts_extents   The time series extents
    * @param p_ts_code      The unique nummeric value identifying the time series
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @see type ts_extents_tab_t
    */
   procedure get_ts_extents(
      p_ts_extents out ts_extents_tab_t,
      p_ts_code    in  integer,
      p_time_zone  in  varchar2,
      p_unit       in  varchar2 default null);
   /**
    * Retrieves time and value extents for a all version dates of a specified time series in specified time zone and units
    *
    * @param p_ts_code      The unique nummeric value identifying the time series
    * @param p_time_zone    The time zone for the time extents. If null, the location's local time zone is used
    * @param p_unit         The unit for the value extents. If unspecified or null, the default SI unit is used 
    *
    * @return The time series extents
    *
    * @see type ts_extents_tab_t
    */
   function get_ts_extents_f(
      p_ts_code   in integer,
      p_time_zone in varchar2,
      p_unit      in  varchar2 default null)
      return ts_extents_tab_t;
   /**
    * Retrieves the minimum and maximum values for a time series and a time window
    *
    * @param p_min_value The minium value in the time window, in the specified unit
    * @param p_max_value The maxium value in the time window, in the specified unit
    * @param p_ts_id     The time series identifier
    * @param p_unit      The unit to retrieve the min and max values is
    * @param p_min_date  The start of the time window, in the specified time zone. If not specified or NULL, the time window has no start date, and all data before the end date is considered
    * @param p_max_date  The start of the time window, in the specified time zone. If not specified or NULL, the time window has no end date, and all data after the start date is considered
    * @param p_time_zone The time zone to use. If not specified or NULL, the local time zone of the time series' location is used
    * @param p_office_id The office that owns the time series
    */
   PROCEDURE get_value_extents (p_min_value      OUT BINARY_DOUBLE,
                                p_max_value      OUT BINARY_DOUBLE,
                                p_ts_id       IN     VARCHAR2,
                                p_unit        IN     VARCHAR2,
                                p_min_date    IN     DATE DEFAULT NULL,
                                p_max_date    IN     DATE DEFAULT NULL,
                                p_time_zone   IN     VARCHAR2 DEFAULT NULL,
                                p_office_id   IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves the minimum and maximum values and the times of those values for a time series and a time window
    *
    * @param p_min_value      The minium value in the time window, in the specified unit
    * @param p_max_value      The maxium value in the time window, in the specified unit
    * @param p_min_value_date The date/time of the minimum value
    * @param p_max_value_date The date/time of the maximum value
    * @param p_ts_id          The time series identifier
    * @param p_unit           The unit to retrieve the min and max values is
    * @param p_min_date       The start of the time window, in the specified time zone. If not specified or NULL, the time window has no start date, and all data before the end date is considered
    * @param p_max_date       The start of the time window, in the specified time zone. If not specified or NULL, the time window has no end date, and all data after the start date is considered
    * @param p_time_zone      The time zone to use. If not specified or NULL, the local time zone of the time series' location is used
    * @param p_office_id      The office that owns the time series
    */
   PROCEDURE get_value_extents (
      p_min_value           OUT BINARY_DOUBLE,
      p_max_value           OUT BINARY_DOUBLE,
      p_min_value_date      OUT DATE,
      p_max_value_date      OUT DATE,
      p_ts_id            IN     VARCHAR2,
      p_unit             IN     VARCHAR2,
      p_min_date         IN     DATE DEFAULT NULL,
      p_max_date         IN     DATE DEFAULT NULL,
      p_time_zone        IN     VARCHAR2 DEFAULT NULL,
      p_office_id        IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves a time series of all values for a specified time series that are within
    * a specified value range and time window
    *
    * @param p_ts_id     The time series to retrieve values for
    * @param p_min_value The minimum value of the range. Only values greater than or equal to this value will be retrieved
    * @param p_max_value The maximum value of the range. Only values less than or equal to this value will be retrieved
    * @param p_unit      The unit for the value range and the retrieved values
    * @param p_min_date  The start of the time window. Only values with times greater than or equal to this time will be retrieved
    * @param p_max_date  The end of the time window. Only values with times less than or equal to this time will be retrieved
    * @param p_time_zone The time zone to use for the time window and retrieved value times
    * @param p_office_id The office that owns the time series
    *
    * @return A time series of values that meet the specified criteria. This time series may be irregular interval
    * even if the specified time series is regular interval do to the fact that only time series values meeting the
    * specified criteria are included. May be NULL if no values match criteria.
    */
   FUNCTION get_values_in_range (p_ts_id       IN VARCHAR2,
                                 p_min_value   IN BINARY_DOUBLE,
                                 p_max_value   IN BINARY_DOUBLE,
                                 p_unit        IN VARCHAR2,
                                 p_min_date    IN DATE DEFAULT NULL,
                                 p_max_date    IN DATE DEFAULT NULL,
                                 p_time_zone   IN VARCHAR2 DEFAULT NULL,
                                 p_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN ztsv_array;

   /**
    * Retrieves a time series of all values for a specified time series that are within
    * a specified value range and time window
    *
    * @param p_criteria The time series identifier and criteria to match
    *
    * @return A time series of values that meet the specified criteria. This time series may be irregular interval
    * even if the specified time series is regular interval do to the fact that only time series values meeting the
    * specified criteria are included. May be NULL if no values match criteria.
    */
   FUNCTION get_values_in_range (p_criteria IN time_series_range_t)
      RETURN ztsv_array;

   /**
    * Retrieves a collection of time series that match specified criteria
    *
    * @param p_criteria The time series identifiers and criteria to match
    *
    * @return A collections of time series of values that meet the specified criteria. This time series may be irregular interval
    * even if the specified time series is regular interval do to the fact that only time series values meeting the
    * specified criteria are included. Will be empty, but not NULL, if no values match criteria.
    */
   FUNCTION get_values_in_range (p_criteria IN time_series_range_tab_t)
      RETURN ztsv_array_tab;

   -- not documented
   PROCEDURE trim_ts_deleted_times;

   -- not documented
   PROCEDURE start_trim_ts_deleted_job;

   /**
    * Retrieve the time series associated with the specified parameters.
    *
    * @param p_location_id       The location for the association
    * @param p_association_type  The association type for the assocation
    * @param p_usage_category_id The usage category for the association
    * @param p_usage_id          The usage identifier for the association
    * @param p_office_id         The office owning the association. If NULL or not specified, the office identifier of the session user is used.
    *
    * @return The time series identifier matching the association parameters
    *
    * @since CWMS 2.1
    */
   function get_associated_timeseries(
      p_location_id       in varchar2,
      p_association_type  in varchar2,
      p_usage_category_id in varchar2,
      p_usage_id          in varchar2,
      p_office_id         in varchar2 default null)
      return varchar2;

   /**
    * Sets the current session to retrieve quality codes as unsigned quantities. Quality codes
    * are 32-bit masks, with specific bits representing specific portions of the overall quality.
    * As such, they are neither inherently signed nor unsigned.  They are represented in the
    * database as unsigned values. Since Java has no unsigned 32-bit data type the default
    * representation of quality codes as returned by RETRIEVE_TS is signed.
    */
   procedure set_retrieve_unsigned_quality;

   /**
    * Sets the current session to retrieve quality codes as signed quantities. Quality codes
    * are 32-bit masks, with specific bits representing specific portions of the overall quality.
    * As such, they are neither inherently signed nor unsigned.  They are represented in the
    * database as unsigned values. Since Java has no unsigned 32-bit data type the default
    * representation of quality codes as returned by RETRIEVE_TS is signed.
    */
   procedure set_retrieve_signed_quality;

   /**
    * Normalizes the specified quality code to as igned or unsigned quantity depending on
    * current session settings. Quality codes are 32-bit masks, with specific bits representing
    * specific portions of the overall quality.  As such, they are neither inherently signed nor
    * unsigned.  They are represented in the database as unsigned values. Since Java has no
    * unsigned 32-bit data type the default representation of quality codes as returned by RETRIEVE_TS
    * is signed.
    *
    * @param p_quality the quality code to normalize
    *
    * @return the normalized quality code
    *
    * @since CWMS2.1
    * @see set_retrieve_unsigned_quality
    * @see set_retrieve_signed_quality
    */
   function normalize_quality(
      p_quality in number)
      return number
      result_cache;  
      
   /**
    * Sets the default storage policy for an office for time series data that contains null values with non-missing quality codes.
    *
    * @param p_storage_policy The storage policy. Must be NULL or one of filter_out_null_values, set_null_values_to_missing, or reject_ts_with_null_values. If NULL, any office storage policy is removed and the database default is in effect.
    * @param p_office_id      The text identifier of the office to set the policy for.  If unspecified or NULL, the current session user's default office is used.
    *
    * @since CWMS 2.1
    * @see constant filter_out_null_values
    * @see constant set_null_values_to_missing
    * @see constant reject_ts_with_null_values
    */
   procedure set_nulls_storage_policy_ofc(
      p_storage_policy in integer,
      p_office_id      in varchar2 default null);
      
   /**
    * Sets the storage policy for specified time series for time series data that contains null values with non-missing quality codes.
    *
    * @param p_storage_policy The storage policy. Must be NULL or one of filter_out_null_values, set_null_values_to_missing, or reject_ts_with_null_values. If NULL, any time series policy is removed and the office default is in effect.
    * @param p_ts_id          The time series identifier to set the policy for.
    * @param p_office_id      The text identifier of the office that owns the time series.  If unspecified or NULL, the current session user's default office is used.
    *
    * @since CWMS 2.1
    * @see constant filter_out_null_values
    * @see constant set_null_values_to_missing
    * @see constant reject_ts_with_null_values
    */
   procedure set_nulls_storage_policy_ts(
      p_storage_policy in integer,
      p_ts_id          in varchar2,
      p_office_id      in varchar2 default null);
      
   /**
    * Retrieves the default storage policy for an office for time series data that contains null values with non-missing quality codes.
    *
    * @param p_office_id  The text identifier of the office to retrieve the policy for.  If unspecified or NULL, the current session user's default office is used.
    *
    * @return The default storage policy for the specified office.  If NULL, the database default is in effect.
    *
    * @since CWMS 2.1
    * @see constant filter_out_null_values
    * @see constant set_null_values_to_missing
    * @see constant reject_ts_with_null_values
    */
   function get_nulls_storage_policy_ofc(
      p_office_id in varchar2 default null)
      return integer;                  
      
   /**
    * Retrieves the storage policy for specified time series for time series data that contains null values with non-missing quality codes.
    *
    * @param p_ts_id     The time series identifier to retrieve the policy for.
    * @param p_office_id The text identifier of the office that owns the time series.  If unspecified or NULL, the current session user's default office is used.
    *
    * @return The default storage policy for the specified time series.  If NULL, the office default is in effect.
    *
    * @since CWMS 2.1
    * @see constant filter_out_null_values
    * @see constant set_null_values_to_missing
    * @see constant reject_ts_with_null_values
    */
   function get_nulls_storage_policy_ts(
      p_ts_id     in varchar2,
      p_office_id in varchar2 default null)
      return integer;
      
   /**
    * Retrieves the effective storage policy for specified time series for time series data that contains null values with non-missing quality codes.
    *
    * @param p_ts_code The numeric code identifying the time series to retrieve the effective policy for.
    *
    * @return The effective storage policy for the specified time series.  If the time series has a policy, it is returned.  If not, the office default policy is returned. If that is not set, the database defatul is returned.
    *
    * @since CWMS 2.1
    * @see constant filter_out_null_values
    * @see constant set_null_values_to_missing
    * @see constant reject_ts_with_null_values
    */
   function get_nulls_storage_policy(
      p_ts_code in integer)
      return integer;
      
   /**
    * Sets the default policy for whether to filter out duplicate value/quality combinations when storing for the specified office
    *
    * @param p_filter_duplicates The storage policy. Must be NULL, 'T', or 'F'. If NULL, the policy is reset and the database default (no filtering) will be used.
    * @param p_office_id The text identifier of the office to set the policy for.  If unspecified or NULL, the current session user's default office is used.
    *
    * @since CWMS 3.1
    */
   procedure set_filter_duplicates_ofc(
      p_filter_duplicates in varchar2,
      p_office_id         in varchar2 default null);
      
   /**
    * Sets the policy for the specified time series to filter out time/value/quality combinations that duplicate existing data before storing
    *
    * @param p_filter_duplicates The storage policy. Must be NULL, 'T', or 'F'. If NULL, the policy is reset and the office default (if any) will be used.
    * @param p_ts_id             The time series identifier to set the policy for.
    * @param p_office_id         The text identifier of the office that owns the time series.  If unspecified or NULL, the current session user's default office is used.
    *
    * @since CWMS 3.1
    */
   procedure set_filter_duplicates_ts(
      p_filter_duplicates in varchar2,
      p_ts_id             in varchar2,
      p_office_id         in varchar2 default null);
      
   /**
    * Sets whether to filter out duplicate value/quality combinations when storing the specified time series
    *
    * @param p_filter_duplicates The storage policy. Must be NULL, 'T', or 'F'. If NULL, the policy is reset and the office default (if any) will be used.
    * @param p_ts_code           The numeric code identifying the time series to set the effective policy for.
    *
    * @since CWMS 3.1
    */
   procedure set_filter_duplicates_ts(
      p_filter_duplicates in varchar2,
      p_ts_code           in integer);
      
   /**
    * Retrieves whether to filter out duplicate value/quality combinations when storing time series for the specified office
    *
    * @param p_office_id  The text identifier of the office to retrieve the policy for.  If unspecified or NULL, the current session user's default office is used.
    *
    * @return Whether to filter out duplicate value/quality combinations when storing time series for the specified office ('T'/'F'/NULL). NULL indicicates database default.
    *
    * @since CWMS 3.1
    */
   function get_filter_duplicates_ofc(
      p_office_id in varchar2 default null)
      return varchar2;                  
      
   /**
    * Retrieves whether to filter out duplicate value/quality combinations when storing the specified time series
    *
    * @param p_ts_id     The time series identifier to retrieve the policy for.
    * @param p_office_id The text identifier of the office that owns the time series.  If unspecified or NULL, the current session user's default office is used.
    *
    * @return Whether to filter out duplicate value/quality combinations when storing the specified time series ('T'/'F')
    *
    * @since CWMS 3.1
    */
   function get_filter_duplicates(
      p_ts_id     in varchar2,
      p_office_id in varchar2 default null)
      return varchar2;
      
   /**
    * Retrieves whether to filter out duplicate value/quality combinations when storing the specified time series
    *
    * @param p_ts_code The numeric code identifying the time series to retrieve the effective policy for.
    *
    * @return Whether to filter out duplicate value/quality combinations when storing the specified time series ('T'/'F')
    *
    * @since CWMS 3.1
    */
   function get_filter_duplicates(
      p_ts_code in integer)
      return varchar2;
   /**
    * Marks a time serires as part of the historic record or not
    *
    * @param p_ts_id       The time series identifier to set the historic flag for
    * @param p_is_historic A flag (T/F) specifying whether the time series is part of the hitoric record. If unspecified or NULL, the flag will be set to 'T'
    * @param p_office_id   The office that owns the time series. If unspecified or NULL, the current session user's default office is used.
    */
   procedure set_historic(
      p_ts_id       in varchar2,
      p_is_historic in varchar2 default 'T',
      p_office_id   in varchar2 default null);
   /**
    * Marks a time serires as part of the historic record or not
    *
    * @param p_ts_code     The unique numeric code of the time series to set the historic flag for
    * @param p_is_historic A flag (T/F) specifying whether the time series is part of the hitoric record. If unspecified or NULL, the flag will be set to 'T'
    */
   procedure set_historic(
      p_ts_code     in integer,
      p_is_historic in varchar2 default 'T');
   /**
    * Returns whether a time serires as part of the historic record or not
    *
    * @param p_ts_id       The time series identifier to return the historic flag for
    * @param p_office_id   The office that owns the time series. If unspecified or NULL, the current session user's default office is used.
    *
    * @return A flag (T/F) specifying whether the time series is part of the hitoric record ('T'/'F')
    */
   function is_historic(
      p_ts_id       in varchar2,
      p_office_id   in varchar2 default null)
      return varchar2;
   /**
    * Returns whether a time serires as part of the historic record or not
    *
    * @param p_ts_code The unique numeric code of the time series to return the historic flag for
    *
    * @return A flag (T/F) specifying whether the time series is part of the hitoric record ('T'/'F')
    */
   function is_historic(
      p_ts_code     in integer,
      p_office_id   in varchar2 default null)
      return varchar2;
                           
   /**
    * Retreives time series in a number of formats for a combination time window, timezone, formats, and vertical datums
    *
    * @param p_results        The time series, in the specified time zones, formats, and vertical datums
    * @param p_date_time      The time that the routine was called, in UTC
    * @param p_query_time     The time the routine took to retrieve the specified time series from the database
    * @param p_format_time    The time the routine took to format the results into the specified format, in milliseconds
    * @param p_ts_count       The number of time series retrieved by the routine
    * @param p_value_count    The number of values retrieved by the routine
    * @param p_names          The names (time series identifers) of the time series to retrieve.  Multiple time series can be specified by
    *                         <or><li>specifying multiple time series ids separated by the <b>'|'</b> character (multiple name positions)</li>
    *                         <li>specifying a time series spec id with wildcard (<b>'*'</b> and/or <b>'?'</b> characters) (single name position)</li>
    *                         <li>a combination of 1 and 2 (multiple name positions with one or more positions matching possibly more than one time series)</li></ol>
    *                         If unspecified or NULL, a listing of time series identifiers with data in the specified or default time window will be returned.
    * @param p_format         The format to retrieve the time series in. Valid formats are <ul><li>TAB</li><li>CSV</li><li>XML</li><li>JSON</li></ul>
    *                         If the format is unspecified or NULL, the TAB format will be used. 
    * @param p_units          The units to return the time series in.  Valid units are <ul><li>EN</li><li>SI</li><li>actual unit of parameter (e.g. ft, cfs)</li></ul> If the p_names variable (q.v.) has more
    *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_units variable may also have multiple positions separated by the 
    *                         <b>'|',</b> charcter. If the p_units variable has fewer positions than the p_name variable, the last unit position is used for all 
    *                         remaning names. If the units are unspecified or NULL, the NATIVE units will be used for all time series.
    * @param p_datums         The vertical datums to return the units in.  Valid datums are <ul><li>NATIVE</li><li>NGVD29</li><li>NAVD88</li></ul> If the p_names variable (q.v.) has more
    *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_datums variable may also have multiple positions separated by the 
    *                         <b>'|',</b> charcter. If the p_datums variable has fewer positions than the p_name variable, the last datum position is used for all 
    *                         remaning names. If the datums are unspecified or NULL, the NATIVE veritcal datum will be used for all time series.
    * @param p_start          The start of the time window to retrieve time series for.  No time series values earlier this time will be retrieved.
    *                         If unspecified or NULL, a value of 24 hours prior to the specified or default end of the time window will be used. for the start of the time window       
    * @param p_end            The end of the time window to retrieve time series for.  No time series values later this time will be retrieved.
    *                         If unspecified or NULL, the current time will be used for the end of the time window.
    * @param p_timezone       The time zone to retrieve the time series in. The p_start and p_end parameters - if used - are also interpreted according to this time zone.
    *                         If unspecified or NULL, the UTC time zone is used. 
    * @param p_office_id      The office to retrieve time series for.  If unspecified or NULL, time series for all offices in the database that match the other criteria will be retrieved.
    */         
   procedure retrieve_time_series(
      p_results        out clob,
      p_date_time      out date,
      p_query_time     out integer,
      p_format_time    out integer, 
      p_ts_count       out integer,
      p_value_count    out integer,
      p_names          in  varchar2 default null,            
      p_format         in  varchar2 default null,
      p_units          in  varchar2 default null,   
      p_datums         in  varchar2 default null,
      p_start          in  varchar2 default null,
      p_end            in  varchar2 default null, 
      p_timezone       in  varchar2 default null,
      p_office_id      in  varchar2 default null);
   /**
    * Retreives time series in a number of formats for a combination time window, timezone, formats, and vertical datums
    *
    * @param p_names          The names (time series identifers) of the time series to retrieve.  Multiple time series can be specified by
    *                         <or><li>specifying multiple time series ids separated by the <b>'|'</b> character (multiple name positions)</li>
    *                         <li>specifying a time series spec id with wildcard (<b>'*'</b> and/or <b>'?'</b> characters) (single name position)</li>
    *                         <li>a combination of 1 and 2 (multiple name positions with one or more positions matching possibly more than one time series)</li></ol>
    *                         If unspecified or NULL, a listing of time series identifiers with data in the specified or default time window will be returned.
    * @param p_format         The format to retrieve the time series in. Valid formats are <ul><li>TAB</li><li>CSV</li><li>XML</li><li>JSON</li></ul>
    *                         If the format is unspecified or NULL, the TAB format will be used. 
    * @param p_units          The units to return the time series in.  Valid units are <ul><li>EN</li><li>SI</li><li>actual unit of parameter (e.g. ft, cfs)</li></ul> If the p_names variable (q.v.) has more
    *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_units variable may also have multiple positions separated by the 
    *                         <b>'|',</b> charcter. If the p_units variable has fewer positions than the p_name variable, the last unit position is used for all 
    *                         remaning names. If the units are unspecified or NULL, the NATIVE units will be used for all time series.
    * @param p_datums         The vertical datums to return the units in.  Valid datums are <ul><li>NATIVE</li><li>NGVD29</li><li>NAVD88</li></ul> If the p_names variable (q.v.) has more
    *                         than one name position, (i.e., has one or more <b>'|',</b> charcters), the p_datums variable may also have multiple positions separated by the 
    *                         <b>'|',</b> charcter. If the p_datums variable has fewer positions than the p_name variable, the last datum position is used for all 
    *                         remaning names. If the datums are unspecified or NULL, the NATIVE veritcal datum will be used for all time series.
    * @param p_start          The start of the time window to retrieve time series for.  No time series values earlier this time will be retrieved.
    *                         If unspecified or NULL, a value of 24 hours prior to the specified or default end of the time window will be used. for the start of the time window       
    * @param p_end            The end of the time window to retrieve time series for.  No time series values later this time will be retrieved.
    *                         If unspecified or NULL, the current time will be used for the end of the time window.
    * @param p_timezone       The time zone to retrieve the time series in. The p_start and p_end parameters - if used - are also interpreted according to this time zone.
    *                         If unspecified or NULL, the UTC time zone is used. 
    * @param p_office_id      The office to retrieve time series for.  If unspecified or NULL, time series for all offices in the database that match the other criteria will be retrieved.
    *                         
    * @return                 The time series, in the specified time zones, formats, and vertical datums
    */         
            
   function retrieve_time_series_f(
      p_names       in  varchar2,            
      p_format      in  varchar2,
      p_units       in  varchar2 default null,   
      p_datums      in  varchar2 default null,
      p_start       in  varchar2 default null,
      p_end         in  varchar2 default null, 
      p_timezone    in  varchar2 default null,
      p_office_id   in  varchar2 default null)
      return clob;
                           
END;
/

SHOW ERRORS;
COMMIT;