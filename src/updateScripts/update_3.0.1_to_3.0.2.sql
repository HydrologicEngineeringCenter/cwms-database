--------------------------------
-- RUN THIS SCRIPT AS CWMS_20 --
--------------------------------
set define off
----------------------------------------------------------
-- verify that the schema is the version that we expect --
----------------------------------------------------------
whenever sqlerror exit sql.sqlcode
begin
   for rec in 
      (select version,
              to_char(version_date, 'DDMONYYYY') as version_date
         from av_db_change_log
        where version_date = (select max(version_date) from av_db_change_log)
      )
   loop
      if rec.version != '3.0.1' or rec.version_date != '04SEP2015' then
      	cwms_err.raise('ERROR', 'Expected version 3.0.1 (04SEP2015), got version '||rec.version||' ('||rec.version_date||')');
      end if;
   end loop;
end;
/
whenever sqlerror continue
---------------------------
--Changed TABLE
--AT_STREAM_LOCATION
---------------------------
ALTER TABLE "AT_STREAM_LOCATION" DROP CONSTRAINT "AT_STREAM_LOCATION_U1";
---------------------------
--Changed PACKAGE
--CWMS_TS
---------------------------
CREATE OR REPLACE PACKAGE "CWMS_TS" 
/**
 * Facilities for working with time series
 *
 * @author Various
 *
 * @since CWMS 2.0
 */
AS
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
    *     <td class="descr">varchar2(183)</td>
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

   -- not documented, for LRTS
   FUNCTION shift_for_localtime (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN DATE;

   -- not documented
   FUNCTION clean_quality_code (p_quality_code IN NUMBER)
      RETURN NUMBER
      RESULT_CACHE;

   FUNCTION use_first_table (p_timestamp IN TIMESTAMP DEFAULT NULL)
      RETURN BOOLEAN;

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
    * Retrieves the earliest time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    *
    * @return The earliest time series data date in the database for the time series, in UTC
    */
   FUNCTION get_ts_min_date_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE;

   /**
    * Retrieves the earliest time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone in which to retrieve the earliest time
    * @param p_version_date The version date of the time series in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    *
    * @return The earliest time series data date in the database for the time series, in the specified time zone
    */
   FUNCTION get_ts_min_date (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE;

   /**
    * Retrieves the latest time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The version date of the time series in UTC
    *
    * @return The latest time series data date in the database for the time series, in UTC
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
    * @param p_year             The optional year to search in; entering this year will speed the query by searching additional tsv tables
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
    * Retrieves the latest time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_cwms_ts_id   The time series identifier
    * @param p_time_zone    The time zone in which to retrieve the latest time
    * @param p_version_date The version date of the time series in the specified time zone
    * @param p_office_id    The office that owns the time series. If not specified or NULL, the session user's default office is used
    *
    * @return The latest time series data date in the database for the time series, in the specified time zone
    */


   FUNCTION get_ts_max_date (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE;

   /**
    * Retrieves the earliest and latest time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_min_date_utc     The earliest time series data date in the database for the time series, in UTC
    * @param p_max_date_utc     The latest time series data date in the database for the time series, in UTC
    * @param p_version_date_utc The version date of the time series in UTC
    */
   PROCEDURE get_ts_extents_utc (
      p_min_date_utc          OUT DATE,
      p_max_date_utc          OUT DATE,
      p_ts_code            IN     NUMBER,
      p_version_date_utc   IN     DATE DEFAULT cwms_util.non_versioned);

   /**
    * Retrieves the earliest and latest time series data date in the database for a time series
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_min_date     The earliest time series data date in the database for the time series, in the specified time zone
    * @param p_max_date     The latest time series data date in the database for the time series, in the specified time zone
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

END;
/
---------------------------
--Changed PACKAGE BODY
--CWMS_TURBINE
---------------------------
CREATE OR REPLACE PACKAGE BODY "CWMS_TURBINE" as
--------------------------------------------------------------------------------
-- function get_turbine_code
--------------------------------------------------------------------------------
function get_turbine_code(
   p_office_id  in varchar2,
   p_turbine_id in varchar2)
   return number
is
   l_turbine_code number(10);
   l_office_id       varchar2(16);
begin
   if p_turbine_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TURBINE_ID');
   end if;
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   begin
      l_turbine_code := cwms_loc.get_location_code(l_office_id, p_turbine_id);
      select turbine_location_code
        into l_turbine_code
        from at_turbine
       where turbine_location_code = l_turbine_code;
   exception
      when others then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS turbine identifier.',
            l_office_id
            ||'/'
            ||p_turbine_id);
   end;
   return l_turbine_code;
end get_turbine_code;
--------------------------------------------------------------------------------
-- procedure check_lookup
--------------------------------------------------------------------------------
procedure check_lookup(
   p_lookup in lookup_type_obj_t)
is
begin
   if p_lookup.display_value is null then
      cwms_err.raise(
         'ERROR',
         'The display_value member of a lookup_type_obj_t object cannot be null.');
   end if;
end check_lookup;
--------------------------------------------------------------------------------
-- procedure check_location_ref
--------------------------------------------------------------------------------
procedure check_location_ref(
   p_location in location_ref_t)
is
begin
   if p_location.base_location_id is null then
      cwms_err.raise(
         'ERROR',
         'The base_location_id member of a location_ref_t object cannot be null.');
   end if;
end check_location_ref;
--------------------------------------------------------------------------------
-- procedure check_location_obj
--------------------------------------------------------------------------------
procedure check_location_obj(
   p_location in location_obj_t)
is
begin
   if p_location.location_ref is null then
      cwms_err.raise(
         'ERROR',
         'The location_ref member of a location_obj_t object cannot be null.');
   end if;
   check_location_ref(p_location.location_ref);
end check_location_obj;
--------------------------------------------------------------------------------
-- procedure check_characteristic_ref
--------------------------------------------------------------------------------
procedure check_characteristic_ref(
   p_characteristic in characteristic_ref_t)
is
begin
   if p_characteristic.office_id is null then
      cwms_err.raise(
         'ERROR',
         'The office_id member of a characteristic_ref_t object cannot be null.');
   end if;
   if p_characteristic.characteristic_id is null then
      cwms_err.raise(
         'ERROR',
         'The characteristic_id member of a characteristic_ref_t object cannot be null.');
   end if;
end check_characteristic_ref;
--------------------------------------------------------------------------------
-- procedure check_project_structure
--------------------------------------------------------------------------------
procedure check_project_structure(
   p_project_struct in project_structure_obj_t)
is
begin
   if p_project_struct.project_location_ref is null then
      cwms_err.raise(
         'ERROR',
         'The project_location_ref member of a p_project_struct object cannot be null.');
   end if;
   if p_project_struct.structure_location is null then
      cwms_err.raise(
         'ERROR',
         'The structure_location member of a p_project_struct object cannot be null.');
   end if;
   check_location_ref(p_project_struct.project_location_ref);
   check_location_obj(p_project_struct.structure_location);
   if p_project_struct.characteristic_ref is not null then
      check_characteristic_ref(p_project_struct.characteristic_ref);
   end if;
end check_project_structure;
--------------------------------------------------------------------------------
-- procedure check_turbine_setting
--------------------------------------------------------------------------------
procedure check_turbine_setting(
   p_turbine_setting in turbine_setting_obj_t)
is
begin
   check_location_ref(p_turbine_setting.turbine_location_ref);
   if p_turbine_setting.old_discharge is null then
      cwms_err.raise(
         'ERROR',
         'The old_flow member of a p_turbine_setting object cannot be null.');
   end if;
   if p_turbine_setting.new_discharge is null then
      cwms_err.raise(
         'ERROR',
         'The new_flow member of a p_turbine_setting object cannot be null.');
   end if;
end check_turbine_setting;
--------------------------------------------------------------------------------
-- procedure check_turbine_change
--------------------------------------------------------------------------------
procedure check_turbine_change(
   p_turbine_change in turbine_change_obj_t)
is
begin
   check_location_ref(p_turbine_change.project_location_ref);
   check_lookup(p_turbine_change.discharge_computation);
   check_lookup(p_turbine_change.setting_reason);
   if p_turbine_change.settings is not null and p_turbine_change.settings.count > 0 then
      for i in 1..p_turbine_change.settings.count loop
         check_turbine_setting(p_turbine_change.settings(i));
      end loop;
   end if;
end check_turbine_change;
--------------------------------------------------------------------------------
-- procedure retrieve_turbine
--------------------------------------------------------------------------------
procedure retrieve_turbine(
   p_turbine          out project_structure_obj_t,
   p_turbine_location in  location_ref_t)
is
   l_rec at_turbine%rowtype;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_location');
   end if;
   check_location_ref(p_turbine_location);
   ----------------------------
   -- get the turbine record --
   ----------------------------
   l_rec.turbine_location_code := p_turbine_location.get_location_code;
   begin
      select *
        into l_rec
        from at_turbine
       where turbine_location_code = l_rec.turbine_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS turbine',
            p_turbine_location.get_office_id
            ||'/'
            ||p_turbine_location.get_location_id);
   end;
   ----------------------------
   -- build the out variable --
   ----------------------------
   p_turbine := project_structure_obj_t(
      location_ref_t(l_rec.project_location_code),
      location_obj_t(l_rec.turbine_location_code),
      null);
end retrieve_turbine;
--------------------------------------------------------------------------------
-- function retrieve_turbine_f
--------------------------------------------------------------------------------
function retrieve_turbine_f(
   p_turbine_location in location_ref_t)
   return project_structure_obj_t
is
   l_turbine project_structure_obj_t;
begin
   retrieve_turbine(l_turbine, p_turbine_location);
   return l_turbine;
end retrieve_turbine_f;
--------------------------------------------------------------------------------
-- procedure retrieve_turbines
--------------------------------------------------------------------------------
procedure retrieve_turbines(
   p_turbines         out project_structure_tab_t,
   p_project_location in  location_ref_t)
is
   type turbine_recs_t is table of at_turbine%rowtype;
   l_recs          turbine_recs_t;
   l_project_code  number(10);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_location');
   end if;
   check_location_ref(p_project_location);
   -----------------------------
   -- get the turbine records --
   -----------------------------
   l_project_code := p_project_location.get_location_code;
   begin
      select project_location_code
        into l_project_code
        from at_project
       where project_location_code = l_project_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS project',
            p_project_location.get_office_id
            ||'/'
            ||p_project_location.get_location_id);
   end;
   begin
      select * bulk collect
        into l_recs
        from at_turbine
       where project_location_code = l_project_code;
   exception
      when no_data_found then
         null;
   end;
   ----------------------------
   -- build the out variable --
   ----------------------------
   if l_recs is not null and l_recs.count > 0 then
      p_turbines := project_structure_tab_t();
      p_turbines.extend(l_recs.count);
      for i in 1..l_recs.count loop
         p_turbines(i) := project_structure_obj_t(
            location_ref_t(l_recs(i).project_location_code),
            location_obj_t(l_recs(i).turbine_location_code),
            null);
      end loop;
   end if;
end retrieve_turbines;
--------------------------------------------------------------------------------
-- function retrieve_turbines_f
--------------------------------------------------------------------------------
function retrieve_turbines_f(
   p_project_location in location_ref_t)
   return project_structure_tab_t
is
   l_turbines project_structure_tab_t;
begin
   retrieve_turbines(l_turbines, p_project_location);
   return l_turbines;
end retrieve_turbines_f;
--------------------------------------------------------------------------------
-- procedure store_turbine
--------------------------------------------------------------------------------
procedure store_turbine(
   p_turbine        in project_structure_obj_t,
   p_fail_if_exists in varchar2 default 'T')
is
begin
   store_turbines(project_structure_tab_t(p_turbine), p_fail_if_exists);
end store_turbine;
--------------------------------------------------------------------------------
-- procedure store_turbines
--------------------------------------------------------------------------------
procedure store_turbines(
   p_turbines       in project_structure_tab_t,
   p_fail_if_exists in varchar2 default 'T')
is
   l_fail_if_exists   boolean;
   l_exists           boolean;
   l_project          project_obj_t;
   l_rec              at_turbine%rowtype;
   l_location_type    varchar2(32);
   l_code             integer;
   l_location_kind_id varchar2(32);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbines is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_TURBINES');
   end if;
   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);
   for i in 1..p_turbines.count loop
      ------------------------
      -- more sanity checks --
      ------------------------
      begin
         l_code := p_turbines(i).structure_location.location_ref.get_location_code;
      exception
         when no_data_found then null;
      end;
      if l_code is not null then
         l_location_kind_id := cwms_loc.check_location_kind(l_code);
         if l_location_kind_id not in ('TURBINE', 'SITE', 'STREAMGAGE') then
            cwms_err.raise(
               'ERROR',
               'Cannot switch location '
               ||p_turbines(i).structure_location.location_ref.office_id
               ||'/'
               ||p_turbines(i).structure_location.location_ref.get_location_id
               ||' from type '
               ||l_location_kind_id
               ||' to type TURBINE');
         end if;
      end if;
      check_project_structure(p_turbines(i));
      -- will raise an exception if project doesn't exist
      cwms_project.retrieve_project(
         l_project,
         p_turbines(i).project_location_ref.get_location_id,
         p_turbines(i).project_location_ref.get_office_id);
      ------------------------------------------------
      -- see if the turbine location already exists --
      ------------------------------------------------
      begin
      begin
         l_rec.turbine_location_code := p_turbines(i).structure_location.location_ref.get_location_code('F');
         l_exists := true;
         l_location_type := cwms_loc.get_location_type(l_rec.turbine_location_code);
         if l_location_type in ('TURBINE', 'SITE', 'STREAMGAGE') then
            if l_location_type = 'TURBINE' then
               l_exists := true; -- location has an at_turbine entry
               if l_fail_if_exists then
                  cwms_err.raise(
                     'ITEM_ALREADY_EXISTS',
                     'CWMS turbine',
                     p_turbines(i).structure_location.location_ref.get_office_id
                     ||'/'
                     ||p_turbines(i).structure_location.location_ref.get_location_id);
               end if;
            else
               l_exists := false; -- location exists, but there's no at_turbine entry
            end if;
         else
            cwms_err.raise(
               'ERROR',
               'CWMS location '
               ||p_turbines(i).structure_location.location_ref.get_office_id
               ||'/'
               ||p_turbines(i).structure_location.location_ref.get_location_id
               ||' exists but is identified as type '||l_location_type);
         end if;
      exception
         when no_data_found then
            l_exists := false; -- location does not exists
      end;
      end;
      -----------------------
      -- create the record --
      -----------------------
      cwms_loc.store_location(p_turbines(i).structure_location, 'F');
      --
      l_rec.turbine_location_code := p_turbines(i).structure_location.location_ref.get_location_code('T');
      l_rec.project_location_code := l_project.project_location.location_ref.get_location_code('F');
      --
      if  l_exists then
         update at_turbine
            set project_location_code = l_rec.project_location_code
          where turbine_location_code = l_rec.turbine_location_code;
      else
         insert into at_turbine values l_rec;
      end if;
      ---------------------------
      -- set the location kind --
      ---------------------------
      update at_physical_location
         set location_kind = (select location_kind_code
                                from cwms_location_kind
                               where location_kind_id = 'TURBINE'
                             )
       where location_code = l_rec.turbine_location_code;
   end loop;
end store_turbines;
--------------------------------------------------------------------------------
-- procedure rename_turbine
--------------------------------------------------------------------------------
procedure rename_turbine(
   p_turbine_id_old in varchar2,
   p_turbine_id_new in varchar2,
   p_office_id      in varchar2 default null)
is
   l_turbine project_structure_obj_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_id_old is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_id_old');
   end if;
   if p_turbine_id_new is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_id_new');
   end if;
   if p_office_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_office_id');
   end if;
   l_turbine := retrieve_turbine_f(location_ref_t(p_turbine_id_old, p_office_id));
   cwms_loc.rename_location(p_turbine_id_old, p_turbine_id_new, p_office_id);
end rename_turbine;
--------------------------------------------------------------------------------
-- procedure delete_turbine
--------------------------------------------------------------------------------
procedure delete_turbine(
   p_turbine_id     in varchar,
   p_delete_action in varchar2 default cwms_util.delete_key,
   p_office_id  in varchar2 default null
)
is
begin
   delete_turbine2(
      p_turbine_id    => p_turbine_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_office_id);
end delete_turbine;
--------------------------------------------------------------------------------
-- procedure delete_turbine2
--------------------------------------------------------------------------------
procedure delete_turbine2(
   p_turbine_id             in varchar2,
   p_delete_action          in varchar2 default cwms_util.delete_key,
   p_delete_location        in varchar2 default 'F',
   p_delete_location_action in varchar2 default cwms_util.delete_key,
   p_office_id              in varchar2 default null)
is
   l_turbine_code         number(10);
   l_delete_location      boolean;
   l_delete_action1       varchar2(16);
   l_delete_action2       varchar2(16);
   l_turbine_change_codes number_tab_t;
   l_count                pls_integer;
   l_location_kind_code   integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_turbine_ID');
   end if;
   l_delete_action1 := upper(substr(p_delete_action, 1, 16));
   if l_delete_action1 not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
   then
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   l_delete_location := cwms_util.return_true_or_false(p_delete_location);
   l_delete_action2 := upper(substr(p_delete_location_action, 1, 16));
   if l_delete_action2 not in (
      cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
   then
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
   end if;
   l_turbine_code := get_turbine_code(p_office_id, p_turbine_id);
   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
   if l_delete_action1 in (cwms_util.delete_data, cwms_util.delete_all) then
      select turbine_change_code bulk collect
        into l_turbine_change_codes
        from at_turbine_change
       where turbine_change_code in
             ( select turbine_change_code
                 from at_turbine_setting
                where turbine_location_code = l_turbine_code
             );
      delete
        from at_turbine_setting
       where turbine_change_code in (select * from table(l_turbine_change_codes));
      delete
        from at_turbine_change
       where turbine_change_code in (select * from table(l_turbine_change_codes));
   end if;
   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
   if l_delete_action1 in (cwms_util.delete_key, cwms_util.delete_all) then
      delete
        from at_turbine
       where turbine_location_code = l_turbine_code;
   end if;
   -------------------------------------
   -- delete the location if required --
   -------------------------------------
   if l_delete_location then
      cwms_loc.delete_location(p_turbine_id, l_delete_action2, p_office_id);
   else
      select count(*)
        into l_count
        from at_stream_location
       where location_code = l_turbine_code;
      if l_count = 0 then
         select location_kind_code
           into l_location_kind_code
           from cwms_location_kind
          where location_kind_id = 'SITE';
      else
         select location_kind_code
           into l_location_kind_code
           from cwms_location_kind
          where location_kind_id = 'STREAMGAGE';
      end if;
      update at_physical_location
         set location_kind = l_location_kind_code
       where location_code = l_turbine_code;
   end if;
end delete_turbine2;
--------------------------------------------------------------------------------
-- procedure store_turbine_changes
--------------------------------------------------------------------------------
procedure store_turbine_changes(
   p_turbine_changes      in turbine_change_tab_t,
   p_start_time           in date default null,
   p_end_time             in date default null,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F')
is
   l_proj_loc_code    number(10);
   l_office_code      number(10);
   l_office_id        varchar2(16);
   l_change_date      date;
   l_start_time       date;
   l_end_time         date;
   l_time_zone        varchar2(28);
   l_change_rec       at_turbine_change%rowtype;
   l_setting_rec      at_turbine_setting%rowtype;
   l_dates            date_table_type;
   l_existing         turbine_change_tab_t;
   l_new_change_date  date;
   l_turbine_codes    number_tab_t;
   l_count            pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_turbine_changes is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_turbine_changes');
   elsif p_turbine_changes.count = 0 then
      cwms_err.raise('ERROR', 'No turbine changes specified.');
   end if;
   for i in 1..p_turbine_changes.count loop
      check_turbine_change(p_turbine_changes(i));
   end loop;
   if p_override_protection not in ('T','F') then
      cwms_err.raise('ERROR',
      'Parameter p_override_protection must be either ''T'' or ''F''');
   end if;
   if p_start_time is null and not cwms_util.is_true(p_start_time_inclusive) then
      cwms_err.raise(
         'ERROR',
         'Cannot specify exclusive start time with implicit start time');
   end if;
   if p_end_time is null and not cwms_util.is_true(p_end_time_inclusive) then
      cwms_err.raise(
         'ERROR',
         'Cannot specify exclusive end time with implicit end time');
   end if;
   for i in 1..p_turbine_changes.count loop
      if i = 1 then
         l_proj_loc_code := p_turbine_changes(i).project_location_ref.get_location_code;
         l_office_id     := upper(trim(p_turbine_changes(i).project_location_ref.get_office_id));
         l_office_code   := p_turbine_changes(i).project_location_ref.get_office_code;
         l_change_date   := p_turbine_changes(i).change_date;
      else
         if p_turbine_changes(i).project_location_ref.get_location_code != l_proj_loc_code then
            cwms_err.raise(
               'ERROR',
               'Multiple projects found in turbine changes.');
         end if;
         if p_turbine_changes(i).change_date <= l_change_date then
            cwms_err.raise(
               'ERROR',
               'Gate changes are not in ascending time order.');
         end if;
      end if;
      if upper(trim(p_turbine_changes(i).discharge_computation.office_id)) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'Turbine change for office '
            ||l_office_id
            ||' cannot reference discharge computation for office '
            ||upper(p_turbine_changes(i).discharge_computation.office_id));
      end if;
      if upper(trim(p_turbine_changes(i).setting_reason.office_id)) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'Turbine change for office '
            ||l_office_id
            ||' cannot reference release reason for office '
            ||upper(p_turbine_changes(i).setting_reason.office_id));
      end if;
      begin
         select turbine_comp_code
           into l_change_rec.turbine_discharge_comp_code
           from at_turbine_computation_code
          where db_office_code = l_office_code
            and upper(turbine_comp_display_value) = upper(p_turbine_changes(i).discharge_computation.display_value)
            and upper(turbine_comp_tooltip) = upper(p_turbine_changes(i).discharge_computation.tooltip)
            and turbine_comp_active = upper(p_turbine_changes(i).discharge_computation.active);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS turbine change computation',
               l_office_id
               ||'/DISPLAY='
               ||p_turbine_changes(i).discharge_computation.display_value
               ||'/TOOLTIP='
               ||p_turbine_changes(i).discharge_computation.tooltip
               ||'/ACTIVE='
               ||p_turbine_changes(i).discharge_computation.active);
      end;
      begin
         select turb_set_reason_code
           into l_change_rec.turbine_setting_reason_code
           from at_turbine_setting_reason
          where db_office_code = l_office_code
            and upper(turb_set_reason_display_value) = upper(p_turbine_changes(i).setting_reason.display_value)
            and upper(turb_set_reason_tooltip) = upper(p_turbine_changes(i).setting_reason.tooltip)
            and turb_set_reason_active = upper(p_turbine_changes(i).setting_reason.active);
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS turbine release reason',
               l_office_id
               ||'/DISPLAY='
               ||p_turbine_changes(i).setting_reason.display_value
               ||'/TOOLTIP='
               ||p_turbine_changes(i).setting_reason.tooltip
               ||'/ACTIVE='
               ||p_turbine_changes(i).setting_reason.active);
      end;
   end loop;
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_start_time := nvl(p_start_time, p_turbine_changes(1).change_date);
   l_end_time   := nvl(p_end_time,   p_turbine_changes(p_turbine_changes.count).change_date);
   l_time_zone  := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   if l_time_zone is not null then
      l_start_time := cwms_util.change_timezone(l_start_time, l_time_zone, 'UTC');
      l_end_time   := cwms_util.change_timezone(l_end_time,   l_time_zone, 'UTC');
   end if;
   -------------------------------------------------------------
   -- delete any existing turbine changes in the time window  --
   -- that doesn't have a corrsponding time in the input data --
   -------------------------------------------------------------
   select cwms_util.change_timezone(change_date, nvl(l_time_zone, 'UTC'), 'UTC')
     bulk collect
     into l_dates
     from table(p_turbine_changes);

   l_existing := retrieve_turbine_changes_f(
      p_project_location => p_turbine_changes(1).project_location_ref,
      p_start_time       => l_start_time,
      p_end_time         => l_end_time);

   for rec in
      (select change_date
        from table(l_existing)
       where change_date not in (select * from table(l_dates))
      )
   loop
      delete_turbine_changes(
         p_project_location    => p_turbine_changes(1).project_location_ref,
         p_start_time          => rec.change_date,
         p_end_time            => rec.change_date,
         p_override_protection => p_override_protection);
   end loop;

   ---------------------------
   -- insert/update records --
   ---------------------------
   for i in 1..p_turbine_changes.count loop
      l_new_change_date := cwms_util.change_timezone(p_turbine_changes(i).change_date, nvl(l_time_zone, 'UTC'), 'UTC');
      -----------------------------------------
      -- retrieve any existing change record --
      -----------------------------------------
      begin
         select *
           into l_change_rec
           from at_turbine_change
          where project_location_code = l_proj_loc_code
            and turbine_change_datetime = l_new_change_date;
      exception
         when no_data_found then
            l_change_rec.turbine_change_code := null;
            l_change_rec.project_location_code := l_proj_loc_code;
            l_change_rec.turbine_change_datetime := l_new_change_date;
      end;
      --------------------------------
      -- populate the change record --
      --------------------------------
      l_change_rec.turbine_change_datetime := l_new_change_date;
      l_change_rec.elev_pool := cwms_util.convert_units(
         p_turbine_changes(i).elev_pool,
         p_turbine_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.elev_tailwater := cwms_util.convert_units(
         p_turbine_changes(i).elev_tailwater,
         p_turbine_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.old_total_discharge_override := cwms_util.convert_units(
         p_turbine_changes(i).old_total_discharge_override,
         p_turbine_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      l_change_rec.new_total_discharge_override := cwms_util.convert_units(
         p_turbine_changes(i).new_total_discharge_override,
         p_turbine_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      select turbine_comp_code
        into l_change_rec.turbine_discharge_comp_code
        from at_turbine_computation_code
       where db_office_code = l_office_code
         and upper(turbine_comp_display_value) = upper(p_turbine_changes(i).discharge_computation.display_value)
         and upper(turbine_comp_tooltip) = upper(p_turbine_changes(i).discharge_computation.tooltip)
         and turbine_comp_active = upper(p_turbine_changes(i).discharge_computation.active);
      select turb_set_reason_code
        into l_change_rec.turbine_setting_reason_code
        from at_turbine_setting_reason
       where db_office_code = l_office_code
         and upper(turb_set_reason_display_value) = upper(p_turbine_changes(i).setting_reason.display_value)
         and upper(turb_set_reason_tooltip) = upper(p_turbine_changes(i).setting_reason.tooltip)
         and turb_set_reason_active = upper(p_turbine_changes(i).setting_reason.active);
      l_change_rec.turbine_change_notes := p_turbine_changes(i).change_notes;
      l_change_rec.protected := upper(p_turbine_changes(i).protected);
      -------------------------------------
      -- insert/update the change record --
      -------------------------------------
      if l_change_rec.turbine_change_code is null then
         l_change_rec.turbine_change_code := cwms_seq.nextval;
         insert into at_turbine_change values l_change_rec;
      else
         update at_turbine_change
            set row = l_change_rec
          where turbine_change_code = l_change_rec.turbine_change_code;
      end if;
      ----------------------------------------------------------------------------
      -- collect the turbine location codes from the input data for this change --
      ----------------------------------------------------------------------------
      l_turbine_codes := number_tab_t();
      l_count := nvl(p_turbine_changes(i).settings, turbine_setting_tab_t()).count;
      l_turbine_codes.extend(l_count);
      for j in 1..l_count loop
         l_turbine_codes(j) := p_turbine_changes(i).settings(j).turbine_location_ref.get_location_code;
      end loop;
      ----------------------------------------------------------------------------------
      -- delete any existing turbine setting record not in input data for this change --
      ----------------------------------------------------------------------------------
      delete
        from at_turbine_setting
       where turbine_change_code = l_change_rec.turbine_change_code
         and turbine_location_code not in (select * from table(l_turbine_codes));
      ------------------------------------
      -- insert/update turbine settings --
      ------------------------------------
      for j in 1..l_turbine_codes.count loop
         ------------------------------------------
         -- retrieve any existing setting record --
         ------------------------------------------
         begin
            select *
              into l_setting_rec
              from at_turbine_setting
             where turbine_change_code = l_change_rec.turbine_change_code
               and turbine_location_code = l_turbine_codes(j);
         exception
            when no_data_found then
               l_setting_rec.turbine_setting_code := null;
               l_setting_rec.turbine_change_code := l_change_rec.turbine_change_code;
               l_setting_rec.turbine_location_code := l_turbine_codes(j);
         end;
         ---------------------------------
         -- populate the setting record --
         ---------------------------------
         l_setting_rec.old_discharge := cwms_util.convert_units(
            p_turbine_changes(i).settings(j).old_discharge,
            p_turbine_changes(i).settings(j).discharge_units,
            cwms_util.get_default_units('Flow'));
         l_setting_rec.new_discharge := cwms_util.convert_units(
            p_turbine_changes(i).settings(j).new_discharge,
            p_turbine_changes(i).settings(j).discharge_units,
            cwms_util.get_default_units('Flow'));
         l_setting_rec.scheduled_load := p_turbine_changes(i).settings(j).scheduled_load;
         l_setting_rec.real_power := p_turbine_changes(i).settings(j).real_power;
         --------------------------------------
         -- insert/update the setting record --
         --------------------------------------
         if l_setting_rec.turbine_setting_code is null then
            l_setting_rec.turbine_setting_code := cwms_seq.nextval;
            insert into at_turbine_setting values l_setting_rec;
         else
            update at_turbine_setting
               set row = l_setting_rec
             where turbine_setting_code = l_setting_rec.turbine_setting_code;
         end if;
      end loop;
   end loop;
end store_turbine_changes;
--------------------------------------------------------------------------------
-- procedure retrieve_turbine_changes
--------------------------------------------------------------------------------
procedure retrieve_turbine_changes(
   p_turbine_changes      out turbine_change_tab_t,
   p_project_location     in  location_ref_t,
   p_start_time           in  date,
   p_end_time             in  date,
   p_time_zone            in  varchar2 default null,
   p_unit_system          in  varchar2 default null,
   p_start_time_inclusive in  varchar2 default 'T',
   p_end_time_inclusive   in  varchar2 default 'T',
   p_max_item_count       in  integer default null)
is
   type turbine_change_db_tab_t is table of at_turbine_change%rowtype;
   type turbine_setting_db_tab_t is table of at_turbine_setting%rowtype;
   c_one_second       constant number := 1/86400;
   l_time_zone        varchar2(28);
   l_unit_system      varchar2(2);
   l_start_time       date;
   l_end_time         date;
   l_project          project_obj_t;
   l_proj_loc_code    number(10);
   l_turbine_changes  turbine_change_db_tab_t;
   l_turbine_settings turbine_setting_db_tab_t;
   l_flow_unit        varchar2(16);
   l_elev_unit        varchar2(16);
   l_db_flow_unit     varchar2(16);
   l_db_elev_unit     varchar2(16);
   l_db_power_unit    varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');
   end if;
   if p_max_item_count = 0 then
      cwms_err.raise(
         'ERROR',
         'Max item count must not be zero. Use NULL for unlimited.');
   end if;
   if p_start_time > p_end_time then
      cwms_err.raise(
         'ERROR',
         'Start time must not be later than end time.');
   end if;
   check_location_ref(p_project_location);
   -- will barf if not a valid project
   cwms_project.retrieve_project(
      l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   -------------------------
   -- get the unit system --
   -------------------------
   l_unit_system :=
      upper(
         substr(
            nvl(
               p_unit_system,
               cwms_properties.get_property(
                  'Pref_User.'||cwms_util.get_user_id,
                  'Unit_System',
                  cwms_properties.get_property(
                     'Pref_Office',
                     'Unit_System',
                     'SI',
                     p_project_location.get_office_id),
                  p_project_location.get_office_id)),
            1, 2));
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');
   if not cwms_util.is_true(p_start_time_inclusive) then
      l_start_time := l_start_time + c_one_second;
   end if;
   if not cwms_util.is_true(p_end_time_inclusive) then
      l_end_time := l_end_time - c_one_second;
   end if;
   ----------------------------------------
   -- collect the turbine change records --
   ---------------------------------------
   if p_max_item_count is null then
      select * bulk collect
        into l_turbine_changes
        from at_turbine_change
       where project_location_code = l_proj_loc_code
         and turbine_change_datetime between l_start_time and l_end_time
    order by turbine_change_datetime;

   else
      if p_max_item_count < 0 then
         select *
           bulk collect
           into l_turbine_changes
           from ( select *
                    from at_turbine_change
                   where project_location_code = l_proj_loc_code
                     and turbine_change_datetime between l_start_time and l_end_time
                order by turbine_change_datetime desc
                )
          where rownum <= -p_max_item_count
          order by turbine_change_datetime;
      else
         select *
           bulk collect
           into l_turbine_changes
           from ( select *
                    from at_turbine_change
                   where project_location_code = l_proj_loc_code
                     and turbine_change_datetime between l_start_time and l_end_time
                order by turbine_change_datetime
                )
          where rownum <= p_max_item_count
          order by turbine_change_datetime;
      end if;
   end if;
   ----------------------------
   -- build the out variable --
   ----------------------------
   if l_turbine_changes is not null and l_turbine_changes.count > 0 then
      cwms_display.retrieve_unit(l_flow_unit, 'Flow', l_unit_system, p_project_location.get_office_id);
      cwms_display.retrieve_unit(l_elev_unit, 'Elev', l_unit_system, p_project_location.get_office_id);
      l_db_elev_unit := cwms_util.get_default_units('Elev');
      l_db_flow_unit := cwms_util.get_default_units('Flow');
      l_db_power_unit := cwms_util.get_default_units('Power');
      p_turbine_changes := turbine_change_tab_t();
      p_turbine_changes.extend(l_turbine_changes.count);
      for i in 1..l_turbine_changes.count loop
         ------------------------
         -- turbine change object --
         ------------------------
         p_turbine_changes(i) := turbine_change_obj_t(
            location_ref_t(l_turbine_changes(i).project_location_code),
            cwms_util.change_timezone(l_turbine_changes(i).turbine_change_datetime, 'UTC', l_time_zone),
            null, -- discharge_computation, set below
            null, -- setting_reason, set below
            null, -- settings, set below
            cwms_util.convert_units(
               l_turbine_changes(i).elev_pool,
               l_db_elev_unit,
               l_elev_unit),
            cwms_util.convert_units(
               l_turbine_changes(i).elev_tailwater,
               l_db_elev_unit,
               l_elev_unit),
            l_elev_unit,
            cwms_util.convert_units(
               l_turbine_changes(i).old_total_discharge_override,
               l_db_flow_unit,
               l_flow_unit),
            cwms_util.convert_units(
               l_turbine_changes(i).new_total_discharge_override,
               l_db_flow_unit,
               l_flow_unit),
            l_flow_unit,
            l_turbine_changes(i).turbine_change_notes,
            l_turbine_changes(i).protected);
         ---------------------------------
         -- discharge_computation field --
         ---------------------------------
         select lookup_type_obj_t(
                   p_project_location.get_office_id,
                   turbine_comp_display_value,
                   turbine_comp_tooltip,
                   turbine_comp_active)
           into p_turbine_changes(i).discharge_computation
           from at_turbine_computation_code
          where turbine_comp_code = l_turbine_changes(i).turbine_discharge_comp_code;
         --------------------------
         -- setting_reason field --
         --------------------------
         select lookup_type_obj_t(
                   p_project_location.get_office_id,
                   turb_set_reason_display_value,
                   turb_set_reason_tooltip,
                   turb_set_reason_active)
           into p_turbine_changes(i).setting_reason
           from at_turbine_setting_reason
          where turb_set_reason_code = l_turbine_changes(i).turbine_setting_reason_code;
          --------------------
          -- settings field --
          --------------------
         select * bulk collect
           into l_turbine_settings
           from at_turbine_setting
          where turbine_change_code = l_turbine_changes(i).turbine_change_code;

         if l_turbine_settings is not null and l_turbine_settings.count > 0 then
            p_turbine_changes(i).settings := turbine_setting_tab_t();
            p_turbine_changes(i).settings.extend(l_turbine_settings.count);
            for j in 1..l_turbine_settings.count loop
               p_turbine_changes(i).settings(j) := turbine_setting_obj_t(
                  location_ref_t(l_turbine_settings(j).turbine_location_code),
                  cwms_util.convert_units(
                     l_turbine_settings(j).old_discharge,
                     l_db_flow_unit,
                     l_flow_unit),
                  cwms_util.convert_units(
                     l_turbine_settings(j).new_discharge,
                     l_db_flow_unit,
                     l_flow_unit),
                  l_flow_unit,
                  l_turbine_settings(j).real_power,
                  l_turbine_settings(j).scheduled_load,
                  l_db_power_unit);
            end loop;
         end if;

      end loop;
   end if;
end retrieve_turbine_changes;
--------------------------------------------------------------------------------
-- function retrieve_turbine_changes_f
--------------------------------------------------------------------------------
function retrieve_turbine_changes_f(
   p_project_location      in location_ref_t,
   p_start_time            in date,
   p_end_time              in date,
   p_time_zone             in varchar2 default null,
   p_unit_system           in varchar2 default null,
   p_start_time_inclusive  in varchar2 default 'T',
   p_end_time_inclusive    in varchar2 default 'T',
   p_max_item_count        in integer default null)
   return turbine_change_tab_t
is
   l_turbine_changes turbine_change_tab_t;
begin
   retrieve_turbine_changes(
      l_turbine_changes,
      p_project_location,
      p_start_time,
      p_end_time,
      p_time_zone,
      p_unit_system,
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_max_item_count);
   return l_turbine_changes;
end retrieve_turbine_changes_f;
--------------------------------------------------------------------------------
-- procedure delete_turbine_changes
--------------------------------------------------------------------------------
procedure delete_turbine_changes(
   p_project_location     in  location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F')
is
   c_one_second        constant number := 1/86400;
   l_time_zone         varchar2(28);
   l_start_time        date;
   l_end_time          date;
   l_proj_loc_code     number(10);
   l_project           project_obj_t;
   l_turbine_change_codes number_tab_t;
   l_protected_flags   str_tab_t;
   l_protected_count   pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');
   end if;
   if p_start_time > p_end_time then
      cwms_err.raise(
         'ERROR',
         'Start time must not be later than end time.');
   end if;
   check_location_ref(p_project_location);
   if p_override_protection not in ('T','F') then
      cwms_err.raise('ERROR',
      'Parameter p_override_protection must be either ''T'' or ''F''');
   end if;
   -- will barf if not a valid project
   cwms_project.retrieve_project(
      l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');
   if not cwms_util.is_true(p_start_time_inclusive) then
      l_start_time := l_start_time + c_one_second;
   end if;
   if not cwms_util.is_true(p_end_time_inclusive) then
      l_end_time := l_end_time - c_one_second;
   end if;
   -----------------------------------------------------------
   -- collect the turbine change codes  and protected flags --
   -----------------------------------------------------------
   select turbine_change_code,
          protected
     bulk collect
     into l_turbine_change_codes,
          l_protected_flags
     from at_turbine_change
    where project_location_code = l_proj_loc_code
      and turbine_change_datetime between l_start_time and l_end_time;
   -------------------------------------
   -- check for protection violations --
   -------------------------------------
   if not cwms_util.is_true(p_override_protection) then
      select count(*)
        into l_protected_count
        from table(l_protected_flags)
       where column_value = 'T';
      if l_protected_count > 0 then
         cwms_err.raise(
            'ERROR',
            'Cannot delete protected turbine change(s).');
      end if;
   end if;
   ------------------------
   -- delete the records --
   ------------------------
   delete
     from at_turbine_setting
    where turbine_change_code in (select * from table(l_turbine_change_codes));
   delete
     from at_turbine_change
    where turbine_change_code in (select * from table(l_turbine_change_codes));
end delete_turbine_changes;
--------------------------------------------------------------------------------
-- procedure set_turbine_change_protection
--------------------------------------------------------------------------------
procedure set_turbine_change_protection(
   p_project_location     in location_ref_t,
   p_start_time           in date,
   p_end_time             in date,
   p_protected            in varchar2,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T')
is
   c_one_second        constant number := 1/86400;
   l_time_zone         varchar2(28);
   l_start_time        date;
   l_end_time          date;
   l_proj_loc_code     number(10);
   l_project           project_obj_t;
   l_turbine_change_codes number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_project_location is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
   end if;
   if p_start_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
   end if;
   if p_end_time is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');
   end if;
   if p_protected is null then
      cwms_err.raise('NULL_ARGUMENT', 'p_protected');
   end if;
   if p_start_time > p_end_time then
      cwms_err.raise(
         'ERROR',
         'Start time must not be later than end time.');
   end if;
   check_location_ref(p_project_location);
   if p_protected not in ('T','F') then
      cwms_err.raise('ERROR',
      'Parameter p_protected must be either ''T'' or ''F''');
   end if;
   -- will barf if not a valid project
   cwms_project.retrieve_project(
      l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;
   l_time_zone := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   l_start_time := cwms_util.change_timezone(p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');
   if not cwms_util.is_true(p_start_time_inclusive) then
      l_start_time := l_start_time + c_one_second;
   end if;
   if not cwms_util.is_true(p_end_time_inclusive) then
      l_end_time := l_end_time - c_one_second;
   end if;
   ---------------------------
   -- update the protection --
   ---------------------------
   update at_turbine_change
      set protected = p_protected
    where project_location_code = l_proj_loc_code
      and turbine_change_datetime between l_start_time and l_end_time;
end set_turbine_change_protection;

end cwms_turbine;
/

---------------------------
--Changed PACKAGE BODY
--CWMS_TS
---------------------------
CREATE OR REPLACE PACKAGE BODY "CWMS_TS" 
AS
   FUNCTION get_max_open_cursors
      RETURN INTEGER
   IS
      l_max_open_cursors   INTEGER;
   BEGIN
      SELECT VALUE
        INTO l_max_open_cursors
        FROM v$parameter
       WHERE name = 'open_cursors';

      RETURN l_max_open_cursors;
   END get_max_open_cursors;

   --********************************************************************** -
   --
   -- get_ts_code returns ts_code...
   --
   FUNCTION get_ts_code (p_cwms_ts_id     IN VARCHAR2,
                         p_db_office_id   IN VARCHAR2)
      RETURN NUMBER
   IS
      l_ts_code   NUMBER := NULL;
   BEGIN
      RETURN get_ts_code (
                p_cwms_ts_id       => p_cwms_ts_id,
                p_db_office_code   => cwms_util.get_db_office_code (
                                        p_db_office_id));
   END get_ts_code;

   function get_ts_code (
      p_cwms_ts_id     in varchar2,
      p_db_office_code in number)
      return number
   is
      l_office_id    varchar2(16) := cwms_util.get_db_office_id_from_code(p_db_office_code);
      l_cwms_ts_code number;
   begin
      begin
         select ts_code
           into l_cwms_ts_code
           from at_cwms_ts_id
          where upper(cwms_ts_id) = upper(get_cwms_ts_id(trim(p_cwms_ts_id), l_office_id))
            and db_office_code = p_db_office_code;
      exception
         when no_data_found then
            cwms_err.raise (
               'TS_ID_NOT_FOUND',
               trim (p_cwms_ts_id),
               l_office_id);
      end;
      return l_cwms_ts_code;
   end get_ts_code;

   ---------------------------------------------------------------------------

   FUNCTION get_ts_id (p_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_cwms_ts_id   VARCHAR2 (183);
   BEGIN
      BEGIN
         SELECT cwms_ts_id
           INTO l_cwms_ts_id
           FROM at_cwms_ts_id
          WHERE ts_code = p_ts_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT cwms_ts_id
              INTO l_cwms_ts_id
              FROM at_cwms_ts_id
             WHERE ts_code = p_ts_code;
      END;

      RETURN l_cwms_ts_id;
   END;

   function clean_ts_id(
      p_ts_id in varchar2)
      return varchar2
   is
      l_parts str_tab_t;
      l_ts_id varchar2(183);
   begin
      l_parts := cwms_util.split_text(p_ts_id, '.');
      for i in 1..l_parts.count loop
         l_parts(i) := cwms_util.strip(l_parts(i));
      end loop;
      l_ts_id := cwms_util.join_text(l_parts, '.');
      if length(l_ts_id) != length(p_ts_id) then
         cwms_msg.log_db_message(
            'CWMS_TS.CLEAN_TS_ID',
            cwms_msg.msg_level_normal,
            'Cleaned invalid TSID: '||p_ts_id);
      end if;
      return l_ts_id;
   end clean_ts_id;

   --******************************************************************************/
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_CWMS_TS_ID -
   --
   function get_cwms_ts_id (
      p_cwms_ts_id   in varchar2,
      p_office_id    in varchar2)
      return varchar2
   is
      l_cwms_ts_id varchar2(183);
      l_parts      str_tab_t;
   begin
      -----------
      -- as is --
      -----------
      begin
         select cwms_ts_id
           into l_cwms_ts_id
           from at_cwms_ts_id
          where upper(cwms_ts_id) = upper(p_cwms_ts_id)
            and upper(db_office_id) = upper(p_office_id);
      exception
         when no_data_found then
            ----------------------------
            -- try time series alias  --
            -- (will try loc aliases) --
            ----------------------------
            l_cwms_ts_id := cwms_ts.get_ts_id_from_alias(p_cwms_ts_id, null, null, p_office_id);
      end;
      if l_cwms_ts_id is null then
         l_cwms_ts_id := p_cwms_ts_id;
      end if;
      return l_cwms_ts_id;
   end;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DB_UNIT_ID -
   --
   FUNCTION get_db_unit_id (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_base_location_id    at_base_location.base_location_id%TYPE;
      l_sub_location_id     at_physical_location.sub_location_id%TYPE;
      l_base_parameter_id   cwms_base_parameter.base_parameter_id%TYPE;
      l_sub_parameter_id    at_parameter.sub_parameter_id%TYPE;
      l_parameter_type_id   cwms_parameter_type.parameter_type_id%TYPE;
      l_interval_id         cwms_interval.interval_id%TYPE;
      l_duration_id         cwms_duration.duration_id%TYPE;
      l_version_id          at_cwms_ts_spec.VERSION%TYPE;
      l_db_unit_id          cwms_unit.unit_id%TYPE;
   BEGIN
      parse_ts (p_cwms_ts_id,
                l_base_location_id,
                l_sub_location_id,
                l_base_parameter_id,
                l_sub_parameter_id,
                l_parameter_type_id,
                l_interval_id,
                l_duration_id,
                l_version_id);

      --
      SELECT unit_id
        INTO l_db_unit_id
        FROM cwms_unit cu, cwms_base_parameter cbp
       WHERE     cu.unit_code = cbp.unit_code
             AND cbp.base_parameter_id = l_base_parameter_id;

      --
      RETURN l_db_unit_id;
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_TIME_ON_AFTER_INTERVAL - if p_datetime is on the interval, than
   --      p_datetime is returned, if p_datetime is off of the interval, than
   --      the first datetime after p_datetime is returned.
   --
   --      Function is usable down to 1 minute.
   --
   --      All offsets stored in the database are in minutes. --
   --      p_ts_offset and p_ts_interval are passed in as minutes --
   --      p_datetime is assumed to be in UTC --
   --
   --      Weekly intervals - the weekly interval starts with Sunday.
   --
   ----------------------------------------------------------------------------
   --

   FUNCTION get_time_on_after_interval (p_datetime      IN DATE,
                                        p_ts_offset     IN NUMBER, -- in minutes.
                                        p_ts_interval   IN NUMBER -- in minutes.
                                                                 )
      RETURN DATE
   IS
      l_datetime_tmp          DATE;
      l_normalized_datetime   DATE;
      l_tmp                   NUMBER;
      l_delta                 BINARY_INTEGER;
      l_multiplier            BINARY_INTEGER;
      l_mod                   BINARY_INTEGER;
      l_ts_interval           BINARY_INTEGER := TRUNC (p_ts_interval, 0);
   BEGIN
      DBMS_APPLICATION_INFO.set_module (
         'create_ts',
         'Function get_Time_On_After_Interval');

      -- Basic checks - interval cannot be zero - irregular...
      IF l_ts_interval <= 0
      THEN
         cwms_err.RAISE ('ERROR', 'Interval must be > zero.');
      END IF;

      -- Basic checks - offset cannot ve >= to interval...
      IF p_ts_offset >= l_ts_interval
      THEN
         cwms_err.RAISE ('ERROR', 'Offset cannot be >= to the Interval');
      END IF;

      --
      l_normalized_datetime :=
         TRUNC (p_datetime, 'MI') - (p_ts_offset / min_in_dy);

      IF p_ts_interval = 1
      THEN
         NULL;                                             -- nothing to do...
      ELSIF l_ts_interval < min_in_wk             -- intervals less than a week...
      THEN
         l_delta := (l_normalized_datetime - cwms_util.l_epoch) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod <= 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime + (l_ts_interval - l_mod) / min_in_dy;
         END IF;
      ELSIF l_ts_interval = min_in_wk                        -- weekly interval...
      THEN
         l_delta :=
            (l_normalized_datetime - cwms_util.l_epoch_wk_dy_1) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod <= 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime + (l_ts_interval - l_mod) / min_in_dy;
         END IF;
      ELSIF l_ts_interval = min_in_mo                       -- monthly interval...
      THEN
         l_datetime_tmp := TRUNC (l_normalized_datetime, 'Month');

         IF l_datetime_tmp != l_normalized_datetime
         THEN
            l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 1);
         END IF;
      ELSIF l_ts_interval = min_in_yr                       -- yearly interval...
      THEN
         l_datetime_tmp := TRUNC (l_normalized_datetime, 'YEAR');

         IF l_datetime_tmp != l_normalized_datetime
         THEN
            l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 12);
         END IF;
      ELSIF l_ts_interval = min_in_dc                     -- decadal interval...
      THEN
         l_mod :=
            MOD (TO_NUMBER (TO_CHAR (l_normalized_datetime, 'YYYY')), 10);
         l_datetime_tmp :=
            ADD_MONTHS (TRUNC (l_normalized_datetime, 'YEAR'),
                        - (l_mod * 12));

         IF l_datetime_tmp != l_normalized_datetime
         THEN
            l_normalized_datetime := ADD_MONTHS (l_datetime_tmp, 120);
         END IF;
      ELSE
         cwms_err.RAISE (
            'ERROR',
               l_ts_interval
            || ' minutes is not a valid/supported CWMS interval');
      END IF;

      RETURN l_normalized_datetime + (p_ts_offset / min_in_dy);
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END get_time_on_after_interval;

   --
   --  See get_time_on_after_interval for description/comments/etc...
   --
   FUNCTION get_time_on_before_interval (p_datetime      IN DATE,
                                         p_ts_offset     IN NUMBER,
                                         p_ts_interval   IN NUMBER)
      RETURN DATE
   IS
      l_datetime_tmp          DATE;
      l_normalized_datetime   DATE;
      l_tmp                   NUMBER;
      l_delta                 BINARY_INTEGER;
      l_multiplier            BINARY_INTEGER;
      l_mod                   BINARY_INTEGER;
      l_ts_interval           BINARY_INTEGER := TRUNC (p_ts_interval, 0);
   BEGIN
      DBMS_APPLICATION_INFO.set_module (
         'create_ts',
         'Function get_Time_On_Before_Interval');

      -- Basic checks - interval cannot be zero - irregular...
      IF l_ts_interval <= 0
      THEN
         cwms_err.RAISE ('ERROR', 'Interval must be > zero.');
      END IF;

      -- Basic checks - offset cannot ve >= to interval...
      IF p_ts_offset >= l_ts_interval
      THEN
         cwms_err.RAISE ('ERROR', 'Offset cannot be >= to the Interval');
      END IF;

      --
      l_normalized_datetime :=
         TRUNC (p_datetime, 'MI') - (p_ts_offset / min_in_dy);

      IF p_ts_interval = 1
      THEN
         NULL;                                             -- nothing to do...
      ELSIF l_ts_interval < min_in_wk             -- intervals less than a week...
      THEN
         l_delta := (l_normalized_datetime - cwms_util.l_epoch) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod < 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_ts_interval + l_mod) / min_in_dy;
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         END IF;
      ELSIF l_ts_interval = min_in_wk                        -- weekly interval...
      THEN
         l_delta :=
            (l_normalized_datetime - cwms_util.l_epoch_wk_dy_1) * min_in_dy;
         l_mod := MOD (l_delta, l_ts_interval);

         IF l_mod < 0
         THEN
            l_normalized_datetime :=
               l_normalized_datetime - (l_ts_interval + l_mod) / min_in_dy;
         ELSE
            l_normalized_datetime :=
               l_normalized_datetime - (l_mod / min_in_dy);
         END IF;
      ELSIF l_ts_interval = min_in_mo                       -- monthly interval...
      THEN
         l_normalized_datetime := TRUNC (l_normalized_datetime, 'Month');
      ELSIF l_ts_interval = min_in_yr                       -- yearly interval...
      THEN
         l_normalized_datetime := TRUNC (l_normalized_datetime, 'YEAR');
      ELSIF l_ts_interval = min_in_dc                     -- decadal interval...
      THEN
         l_mod :=
            MOD (TO_NUMBER (TO_CHAR (l_normalized_datetime, 'YYYY')), 10);
         l_normalized_datetime :=
            ADD_MONTHS (TRUNC (l_normalized_datetime, 'YEAR'),
                        - (l_mod * 12));
      ELSE
         cwms_err.RAISE (
            'ERROR',
               l_ts_interval
            || ' minutes is not a valid/supported CWMS interval');
      END IF;

      RETURN l_normalized_datetime + (p_ts_offset / min_in_dy);
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END get_time_on_before_interval;



   FUNCTION get_location_id (p_cwms_ts_id     IN VARCHAR2,
                             p_db_office_id   IN VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN get_location_id (
                p_cwms_ts_code => get_ts_code (
                                    p_cwms_ts_id       => p_cwms_ts_id,
                                    p_db_office_code   => cwms_util.get_db_office_code (
                                                            p_office_id => p_db_office_id)));
   END;


   FUNCTION get_location_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_location_id   VARCHAR2 (49);
   BEGIN
      BEGIN
         SELECT location_id
           INTO l_location_id
           FROM at_cwms_ts_id
          WHERE ts_code = p_cwms_ts_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT location_id
              INTO l_location_id
              FROM at_cwms_ts_id
             WHERE ts_code = p_cwms_ts_code;
      END;

      RETURN l_location_id;
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_CODE -
   --
   FUNCTION get_parameter_code (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL,
      p_create              IN VARCHAR2 DEFAULT 'T')
      RETURN NUMBER
   IS
      l_base_parameter_code   NUMBER;
   BEGIN
      SELECT base_parameter_code
        INTO l_base_parameter_code
        FROM cwms_base_parameter
       WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);

      --dbms_output.put_line(l_base_parameter_code);
      --
      RETURN get_parameter_code (l_base_parameter_code,
                                 p_sub_parameter_id,
                                 cwms_util.get_db_office_code (p_office_id),
                                 cwms_util.return_true_or_false (p_create));
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DISPLAY_PARAMETER_CODE -
   --
   FUNCTION get_display_parameter_code (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_display_parameter_code   NUMBER := NULL;
      l_parameter_code           NUMBER := NULL;
      l_count                    INTEGER;
   BEGIN
      l_parameter_code :=
         get_parameter_code (p_base_parameter_id,
                             p_sub_parameter_id,
                             p_office_id,
                             'F');

      SELECT COUNT (*)
        INTO l_count
        FROM at_display_units
       WHERE parameter_code = l_parameter_code;

      IF l_count = 0
      THEN
         l_parameter_code :=
            get_parameter_code (p_base_parameter_id, NULL, p_office_id);

         SELECT COUNT (*)
           INTO l_count
           FROM at_display_units
          WHERE parameter_code = l_parameter_code;

         IF l_count > 0
         THEN
            l_display_parameter_code := l_parameter_code;
         END IF;
      ELSE
         l_display_parameter_code := l_parameter_code;
      END IF;

      RETURN l_display_parameter_code;
   END;

   FUNCTION get_display_parameter_code2 (
      p_base_parameter_id   IN VARCHAR2,
      p_sub_parameter_id    IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      invalid_param_id           EXCEPTION;
      PRAGMA EXCEPTION_INIT (invalid_param_id, -20006);
      l_display_parameter_code   NUMBER;
   BEGIN
      BEGIN
         l_display_parameter_code :=
            get_display_parameter_code (p_base_parameter_id,
                                        p_sub_parameter_id,
                                        p_office_id);
      EXCEPTION
         WHEN invalid_param_id
         THEN
            NULL;
      END;

      RETURN l_display_parameter_code;
   END get_display_parameter_code2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_CODE -
   --
   FUNCTION get_parameter_code (
      p_base_parameter_code   IN NUMBER,
      p_sub_parameter_id      IN VARCHAR2,
      p_office_code           IN NUMBER,
      p_create                IN BOOLEAN DEFAULT TRUE)
      RETURN NUMBER
   IS
      l_parameter_code      NUMBER;
      l_base_parameter_id   cwms_base_parameter.base_parameter_id%TYPE;
      l_office_code         NUMBER
         := NVL (p_office_code, cwms_util.user_office_code);
      l_office_id           VARCHAR2 (16);
   BEGIN
      BEGIN
         IF p_sub_parameter_id IS NOT NULL
         THEN
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND db_office_code IN
                          (p_office_code, cwms_util.db_office_code_all)
                   AND UPPER (sub_parameter_id) = UPPER (p_sub_parameter_id);
         ELSE
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND ap.sub_parameter_id IS NULL
                   AND db_office_code IN (cwms_util.db_office_code_all);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN                                   -- Insert new sub_parameter...
            IF p_create OR p_create IS NULL
            THEN
               INSERT INTO at_parameter (parameter_code,
                                         db_office_code,
                                         base_parameter_code,
                                         sub_parameter_id)
                    VALUES (cwms_seq.NEXTVAL,
                            p_office_code,
                            p_base_parameter_code,
                            p_sub_parameter_id)
                 RETURNING parameter_code
                      INTO l_parameter_code;
            ELSE
               SELECT office_id
                 INTO l_office_id
                 FROM cwms_office
                WHERE office_code = l_office_code;

               SELECT base_parameter_id
                 INTO l_base_parameter_id
                 FROM cwms_base_parameter
                WHERE base_parameter_code = p_base_parameter_code;

               cwms_err.RAISE (
                  'INVALID_PARAM_ID',
                     l_office_id
                  || '/'
                  || cwms_util.concat_base_sub_id (l_base_parameter_id,
                                                   p_sub_parameter_id));
            END IF;
      END;

      RETURN l_parameter_code;
   END get_parameter_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_CODE -
   --
   FUNCTION get_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_parameter_code   NUMBER := NULL;
   BEGIN
      SELECT parameter_code
        INTO l_parameter_code
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      RETURN l_parameter_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         '' || NVL (p_cwms_ts_code, 'NULL'),
                         'CWMS time series code.');
   END get_parameter_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_ID -
   --
   FUNCTION get_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_parameter_row   at_parameter%ROWTYPE;
      l_parameter_id    VARCHAR2 (49) := NULL;
   BEGIN
      SELECT *
        INTO l_parameter_row
        FROM at_parameter
       WHERE parameter_code = get_parameter_code (p_cwms_ts_code);

      SELECT base_parameter_id
        INTO l_parameter_id
        FROM cwms_base_parameter
       WHERE base_parameter_code = l_parameter_row.base_parameter_code;

      IF l_parameter_row.sub_parameter_id IS NOT NULL
      THEN
         l_parameter_id :=
            l_parameter_id || '-' || l_parameter_row.sub_parameter_id;
      END IF;

      RETURN l_parameter_id;
   END get_parameter_id;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_BASE_PARAMETER_CODE -
   --
   FUNCTION get_base_parameter_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_base_parameter_code   NUMBER (10) := NULL;
   BEGIN
      SELECT base_parameter_code
        INTO l_base_parameter_code
        FROM at_parameter
       WHERE parameter_code = get_parameter_code (p_cwms_ts_code);

      RETURN l_base_parameter_code;
   END get_base_parameter_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_BASE_PARAMETER_ID -
   --
   FUNCTION get_base_parameter_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_base_parameter_id   VARCHAR2 (16) := NULL;
   BEGIN
      SELECT base_parameter_id
        INTO l_base_parameter_id
        FROM cwms_base_parameter
       WHERE base_parameter_code = get_base_parameter_code (p_cwms_ts_code);

      RETURN l_base_parameter_id;
   END get_base_parameter_id;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_TYPE_CODE -
   --
   FUNCTION get_parameter_type_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_parameter_type_code   NUMBER := NULL;
   BEGIN
      SELECT parameter_type_code
        INTO l_parameter_type_code
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      RETURN l_parameter_type_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         '' || NVL (p_cwms_ts_code, 'NULL'),
                         'CWMS time series code.');
   END get_parameter_type_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_PARAMETER_TYPE_ID -
   --
   FUNCTION get_parameter_type_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_parameter_type_id   VARCHAR2 (16) := NULL;
   BEGIN
      SELECT parameter_type_id
        INTO l_parameter_type_id
        FROM cwms_parameter_type
       WHERE parameter_type_code = get_parameter_type_code (p_cwms_ts_code);

      RETURN l_parameter_type_id;
   END get_parameter_type_id;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DB_OFFICE_CODE -
   --
   FUNCTION get_db_office_code (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
   IS
      l_db_office_code   at_base_location.db_office_code%TYPE := NULL;
   BEGIN
      SELECT db_office_code
        INTO l_db_office_code
        FROM at_base_location bl, at_physical_location pl, at_cwms_ts_spec ts
       WHERE     ts.ts_code = p_cwms_ts_code
             AND pl.location_code = ts.location_code
             AND bl.base_location_code = pl.base_location_code;

      RETURN l_db_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         '' || NVL (p_cwms_ts_code, 'NULL'),
                         'CWMS time series code.');
   END get_db_office_code;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_DB_OFFICE_ID -
   --
   FUNCTION get_db_office_id (p_cwms_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_db_office_id   cwms_office.office_id%TYPE := NULL;
   BEGIN
      SELECT office_id
        INTO l_db_office_id
        FROM cwms_office
       WHERE office_code = get_db_office_code (p_cwms_ts_code);

      RETURN l_db_office_id;
   END get_db_office_id;


   PROCEDURE update_ts_id (
      p_ts_code                  IN NUMBER,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes     IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_interval                 NUMBER;
      l_interval_utc_offset_old     NUMBER;
      l_interval_utc_offset_new     NUMBER;
      l_snap_forward_minutes_new    NUMBER;
      l_snap_forward_minutes_old    NUMBER;
      l_snap_backward_minutes_new   NUMBER;
      l_snap_backward_minutes_old   NUMBER;
      l_time_zone_code_old          NUMBER;
      l_time_zone_code_new          NUMBER;
      l_ts_active_new               VARCHAR2 (1) := UPPER (p_ts_active_flag);
      l_ts_active_old               VARCHAR2 (1);
      l_tmp                         NUMBER := NULL;
   BEGIN
      --
      --
      BEGIN
         SELECT a.interval_utc_offset,
                a.interval_backward,
                a.interval_forward,
                a.active_flag,
                a.time_zone_code,
                b.INTERVAL
           INTO l_interval_utc_offset_old,
                l_snap_backward_minutes_old,
                l_snap_forward_minutes_old,
                l_ts_active_old,
                l_time_zone_code_old,
                l_ts_interval
           FROM at_cwms_ts_spec a, cwms_interval b
          WHERE a.interval_code = b.interval_code AND a.ts_code = p_ts_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      --
      IF l_ts_active_new IS NULL
      THEN
         l_ts_active_new := l_ts_active_old;
      ELSE
         IF l_ts_active_new NOT IN ('T', 'F')
         THEN
            cwms_err.RAISE ('INVALID_T_F_FLAG', 'p_ts_active_flag');
         END IF;
      END IF;

      --
      IF p_interval_utc_offset IS NULL
      THEN
         l_interval_utc_offset_new := l_interval_utc_offset_old;
      ELSE
         --
         -- Are interval utc offset set and if so is it a valid offset?.
         --
         IF l_ts_interval = 0
         THEN
            IF    p_interval_utc_offset IS NOT NULL
               OR p_interval_utc_offset != cwms_util.utc_offset_irregular
            THEN
               cwms_err.RAISE ('INVALID_UTC_OFFSET',
                               p_interval_utc_offset,
                               'Irregular');
            ELSE
               l_interval_utc_offset_new := cwms_util.utc_offset_irregular;
            END IF;
         ELSE
            IF p_interval_utc_offset = cwms_util.utc_offset_undefined
            THEN
               l_interval_utc_offset_new := cwms_util.utc_offset_undefined;
            ELSE
               IF     p_interval_utc_offset >= 0
                  AND p_interval_utc_offset < l_ts_interval
               THEN
                  l_interval_utc_offset_new := p_interval_utc_offset;
               ELSE
                  cwms_err.RAISE ('INVALID_UTC_OFFSET',
                                  p_interval_utc_offset,
                                  l_ts_interval);
               END IF;
            END IF;

            --
            -- check if the utc offset is being changed and can it be changed.
            --
            IF     l_interval_utc_offset_old !=
                      cwms_util.utc_offset_undefined
               AND l_interval_utc_offset_old != l_interval_utc_offset_new
            THEN -- need to check if this ts_code already holds data, if it does
               -- then can't change interval_utc_offset.
               SELECT COUNT (*)
                 INTO l_tmp
                 FROM av_tsv
                WHERE ts_code = p_ts_code;

               IF l_tmp > 0
               THEN
                  cwms_err.RAISE ('CANNOT_CHANGE_OFFSET',
                                  get_ts_id (p_ts_code));
               END IF;
            END IF;
         END IF;
      END IF;

      --
      -- Set snap back/forward..
      ----
      ---- Confirm that snap back/forward times are valid....
      ----
      IF    l_interval_utc_offset_new != cwms_util.utc_offset_undefined
         OR l_interval_utc_offset_new != cwms_util.utc_offset_irregular
      THEN
         IF    p_snap_forward_minutes IS NOT NULL
            OR p_snap_backward_minutes IS NOT NULL
         THEN
            l_snap_forward_minutes_new := NVL (p_snap_forward_minutes, 0);
            l_snap_backward_minutes_new := NVL (p_snap_backward_minutes, 0);

            IF l_snap_forward_minutes_new + l_snap_backward_minutes_new >=
                  l_ts_interval
            THEN
               cwms_err.RAISE ('INVALID_SNAP_WINDOW');
            END IF;
         ELSE
            l_snap_forward_minutes_new := l_snap_forward_minutes_old;
            l_snap_backward_minutes_new := l_snap_backward_minutes_old;
         END IF;
      ELSE
         l_snap_forward_minutes_new := NULL;
         l_snap_backward_minutes_new := NULL;
      END IF;

      --
      IF p_local_reg_time_zone_id IS NULL
      THEN
         l_time_zone_code_new := l_time_zone_code_old;
      ELSE
         l_time_zone_code_new :=
            cwms_util.get_time_zone_code (p_local_reg_time_zone_id);
      END IF;

      --
      UPDATE at_cwms_ts_spec a
         SET a.interval_utc_offset = l_interval_utc_offset_new,
             a.interval_forward = l_snap_forward_minutes_new,
             a.interval_backward = l_snap_backward_minutes_new,
             a.time_zone_code = l_time_zone_code_new,
             a.active_flag = l_ts_active_new
       WHERE a.ts_code = p_ts_code;
   --
   --
   END;



   PROCEDURE update_ts_id (
      p_cwms_ts_id               IN VARCHAR2,
      p_interval_utc_offset      IN NUMBER DEFAULT NULL,        -- in minutes.
      p_snap_forward_minutes     IN NUMBER DEFAULT NULL,
      p_snap_backward_minutes    IN NUMBER DEFAULT NULL,
      p_local_reg_time_zone_id   IN VARCHAR2 DEFAULT NULL,
      p_ts_active_flag           IN VARCHAR2 DEFAULT NULL,
      p_db_office_id             IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      update_ts_id (
         p_ts_code                  => get_ts_code (
                                         p_cwms_ts_id       => p_cwms_ts_id,
                                         p_db_office_code   => cwms_util.get_db_office_code (
                                                                 p_db_office_id)),
         p_interval_utc_offset      => p_interval_utc_offset,
         -- in minutes.
         p_snap_forward_minutes     => p_snap_forward_minutes,
         p_snap_backward_minutes    => p_snap_backward_minutes,
         p_local_reg_time_zone_id   => p_local_reg_time_zone_id,
         p_ts_active_flag           => p_ts_active_flag);
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- SET_TS_TIME_ZONE -
   --
   PROCEDURE set_ts_time_zone (p_ts_code          IN NUMBER,
                               p_time_zone_name   IN VARCHAR2)
   IS
      l_time_zone_name   VARCHAR2 (28) := NVL (p_time_zone_name, 'UTC');
      l_time_zone_code   NUMBER;
      l_interval_val     NUMBER;
      l_tz_offset        NUMBER;
      l_office_id        VARCHAR2 (16);
      l_tsid             VARCHAR2 (193);
      l_query            VARCHAR2 (32767);
   BEGIN
      IF p_time_zone_name IS NULL
      THEN
         l_time_zone_code := NULL;
      ELSE
         BEGIN
            SELECT time_zone_code
              INTO l_time_zone_code
              FROM mv_time_zone
             WHERE UPPER (time_zone_name) = UPPER (p_time_zone_name);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               p_time_zone_name,
                               'time zone name');
         END;
      END IF;

      SELECT interval
        INTO l_interval_val
        FROM at_cwms_ts_spec ts, cwms_interval i
       WHERE ts.ts_code = p_ts_code AND i.interval_code = ts.interval_code;

      IF l_interval_val > 60
      THEN
         BEGIN
            l_query := REPLACE (
               'select distinct mod(round((cast((cast(date_time as timestamp) at time zone ''$tz'') as date)
                                   - trunc(cast((cast(date_time as timestamp) at time zone ''$tz'') as date)))
                                   * 1440, 0), :a)
                  from (select distinct date_time
                          from av_tsv_dqu
                         where ts_code = :b
                       )',
                       '$tz',
                       l_time_zone_name);

            cwms_util.check_dynamic_sql(l_query);

            EXECUTE IMMEDIATE l_query
               INTO l_tz_offset
               USING l_interval_val, p_ts_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN TOO_MANY_ROWS
            THEN
               SELECT cwms_ts_id, db_office_id
                 INTO l_tsid, l_office_id
                 FROM at_cwms_ts_id
                WHERE ts_code = p_ts_code;

               cwms_err.raise (
                  'ERROR',
                     'Cannot set '
                  || l_office_id
                  || '.'
                  || l_tsid
                  || ' to time zone '
                  || NVL (p_time_zone_name, 'NULL')
                  || '.  Existing data does not conform to time zone.');
         END;
      END IF;

      UPDATE at_cwms_ts_spec
         SET time_zone_code = l_time_zone_code
       WHERE ts_code = p_ts_code;
   END set_ts_time_zone;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- set_tsid_time_zone -
   --
   PROCEDURE set_tsid_time_zone (p_ts_id            IN VARCHAR2,
                                 p_time_zone_name   IN VARCHAR2,
                                 p_office_id        IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code     NUMBER;
      l_office_id   VARCHAR2 (16)
                       := NVL (p_office_id, cwms_util.user_office_id);
   BEGIN
      BEGIN
         SELECT ts_code
           INTO l_ts_code
           FROM at_cwms_ts_id
          WHERE     UPPER (cwms_ts_id) = UPPER (p_ts_id)
                AND UPPER (db_office_id) = UPPER (l_office_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('INVALID_ITEM',
                            p_ts_id,
                            'CWMS Timeseries Identifier');
      END;

      set_ts_time_zone (l_ts_code, p_time_zone_name);
   END set_tsid_time_zone;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- get_ts_time_zone -
   --
   FUNCTION get_ts_time_zone (p_ts_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_time_zone_code   NUMBER;
      l_time_zone_id     VARCHAR2 (28);
   BEGIN
      SELECT time_zone_code
        INTO l_time_zone_code
        FROM at_cwms_ts_spec
       WHERE ts_code = p_ts_code;

      IF l_time_zone_code IS NULL
      THEN
         l_time_zone_id := NULL;
      ELSE
         SELECT time_zone_name
           INTO l_time_zone_id
           FROM cwms_time_zone
          WHERE time_zone_code = l_time_zone_code;
      END IF;

      RETURN l_time_zone_id;
   END get_ts_time_zone;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_TSID_TIME_ZONE -
   --
   FUNCTION get_tsid_time_zone (p_ts_id       IN VARCHAR2,
                                p_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_ts_code     NUMBER;
      l_office_id   VARCHAR2 (16)
                       := NVL (p_office_id, cwms_util.user_office_id);
   BEGIN
      BEGIN
         SELECT ts_code
           INTO l_ts_code
           FROM at_cwms_ts_id
          WHERE     UPPER (cwms_ts_id) = UPPER (p_ts_id)
                AND UPPER (db_office_id) = UPPER (l_office_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT ts_code
                 INTO l_ts_code
                 FROM at_cwms_ts_id
                WHERE     UPPER (cwms_ts_id) = UPPER (p_ts_id)
                      AND UPPER (db_office_id) = UPPER (l_office_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  cwms_err.raise ('INVALID_ITEM',
                                  p_ts_id,
                                  'CWMS Timeseries Identifier');
            END;
      END;

      RETURN get_ts_time_zone (l_ts_code);
   END get_tsid_time_zone;


   PROCEDURE set_ts_versioned (p_cwms_ts_code   IN NUMBER,
                               p_versioned      IN VARCHAR2 DEFAULT 'T')
   IS
      l_version_flag         VARCHAR2 (1);
      l_is_versioned         BOOLEAN;
      l_version_date_count   INTEGER;
   BEGIN
      IF p_versioned NOT IN ('T', 'F', 't', 'f')
      THEN
         cwms_err.raise ('ERROR', 'Version flag must be ''T'' or ''F''');
      END IF;

      SELECT version_flag
        INTO l_version_flag
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      l_is_versioned := nvl(l_version_flag, 'F') = 'T';

      IF p_versioned IN ('T', 't') AND NOT l_is_versioned
      THEN
         ------------------------
         -- turn on versioning --
         ------------------------
         UPDATE at_cwms_ts_spec
            SET version_flag = 'T'
          WHERE ts_code = p_cwms_ts_code;
      ELSIF p_versioned IN ('F', 'f') AND l_is_versioned
      THEN
         -------------------------
         -- turn off versioning --
         -------------------------
         SELECT COUNT (version_date)
           INTO l_version_date_count
           FROM av_tsv
          WHERE     ts_code = p_cwms_ts_code
                AND version_date != DATE '1111-11-11';

         IF l_version_date_count = 0
         THEN
            UPDATE at_cwms_ts_spec
               SET version_flag = 'F'
             WHERE ts_code = p_cwms_ts_code;
         ELSE
            cwms_err.raise (
               'ERROR',
               'Cannot turn off versioning for a time series that has versioned data');
         END IF;
      END IF;
   END set_ts_versioned;

   PROCEDURE set_tsid_versioned (p_cwms_ts_id     IN VARCHAR2,
                                 p_versioned      IN VARCHAR2 DEFAULT 'T',
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      set_ts_versioned (get_ts_code (p_cwms_ts_id, p_db_office_id),
                        p_versioned);
   END set_tsid_versioned;

   PROCEDURE is_ts_versioned (p_is_versioned      OUT VARCHAR2,
                              p_cwms_ts_code   IN     NUMBER)
   IS
      l_version_flag   VARCHAR2 (1);
   BEGIN
      SELECT version_flag
        INTO l_version_flag
        FROM at_cwms_ts_spec
       WHERE ts_code = p_cwms_ts_code;

      p_is_versioned :=
         case nvl(l_version_flag , 'F')
            when 'T' then 'T'
            else 'F'
         end;
   END is_ts_versioned;

   PROCEDURE is_tsid_versioned (
      p_is_versioned      OUT VARCHAR2,
      p_cwms_ts_id     IN     VARCHAR2,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      is_ts_versioned (p_is_versioned,
                       get_ts_code (p_cwms_ts_id, p_db_office_id));
   END is_tsid_versioned;

   FUNCTION is_tsid_versioned_f (p_cwms_ts_id     IN VARCHAR2,
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_is_versioned   VARCHAR2 (1);
   BEGIN
      is_tsid_versioned (l_is_versioned, p_cwms_ts_id, p_db_office_id);

      RETURN l_is_versioned;
   END is_tsid_versioned_f;

   PROCEDURE get_ts_version_dates (
      p_date_cat       OUT SYS_REFCURSOR,
      p_cwms_ts_code   IN  NUMBER,
      p_start_time     IN  DATE,
      p_end_time       IN  DATE,
      p_time_zone      IN  VARCHAR2 DEFAULT 'UTC')
   IS
      l_start_time DATE;
      l_end_time   DATE;
   BEGIN
      l_start_time := cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC');
      l_end_time   := cwms_util.change_timezone(p_end_time,   p_time_zone, 'UTC');
      OPEN p_date_cat FOR
           SELECT DISTINCT
                  case
                     when version_date = cwms_util.non_versioned then version_date
                     else cwms_util.change_timezone(version_date, 'UTC', p_time_zone)
                  end as version_date
             FROM av_tsv
            WHERE ts_code = p_cwms_ts_code
              AND date_time BETWEEN l_start_time AND l_end_time
         ORDER BY version_date;
   END get_ts_version_dates;

   PROCEDURE get_tsid_version_dates (
      p_date_cat          OUT SYS_REFCURSOR,
      p_cwms_ts_id     IN     VARCHAR2,
      p_start_time     IN     DATE,
      p_end_time       IN     DATE,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC',
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      get_ts_version_dates (p_date_cat,
                            get_ts_code (p_cwms_ts_id, p_db_office_id),
                            p_start_time,
                            p_end_time,
                            p_time_zone);
   END get_tsid_version_dates;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (p_office_id    IN VARCHAR2,
                        p_cwms_ts_id   IN VARCHAR2,
                        p_utc_offset   IN NUMBER DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (p_ts_code      => l_ts_code,
                      p_cwms_ts_id   => p_cwms_ts_id,
                      p_utc_offset   => p_utc_offset,
                      p_office_id    => p_office_id);
   END create_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   PROCEDURE create_ts (p_cwms_ts_id          IN VARCHAR2,
                        p_utc_offset          IN NUMBER DEFAULT NULL,
                        p_interval_forward    IN NUMBER DEFAULT NULL,
                        p_interval_backward   IN NUMBER DEFAULT NULL,
                        p_versioned           IN VARCHAR2 DEFAULT 'F',
                        p_active_flag         IN VARCHAR2 DEFAULT 'T',
                        p_office_id           IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (p_ts_code             => l_ts_code,
                      p_cwms_ts_id          => p_cwms_ts_id,
                      p_utc_offset          => p_utc_offset,
                      p_interval_forward    => p_interval_forward,
                      p_interval_backward   => p_interval_backward,
                      p_versioned           => p_versioned,
                      p_active_flag         => p_active_flag,
                      p_office_id           => p_office_id);
   END create_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_TZ -
   --
   PROCEDURE create_ts_tz (p_cwms_ts_id          IN VARCHAR2,
                           p_utc_offset          IN NUMBER DEFAULT NULL,
                           p_interval_forward    IN NUMBER DEFAULT NULL,
                           p_interval_backward   IN NUMBER DEFAULT NULL,
                           p_versioned           IN VARCHAR2 DEFAULT 'F',
                           p_active_flag         IN VARCHAR2 DEFAULT 'T',
                           p_time_zone_name      IN VARCHAR2 DEFAULT 'UTC',
                           p_office_id           IN VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (l_ts_code,
                      p_cwms_ts_id,
                      p_utc_offset,
                      p_interval_forward,
                      p_interval_backward,
                      p_versioned,
                      p_active_flag,
                      'F',
                      p_office_id);

      set_ts_time_zone (l_ts_code, p_time_zone_name);
   END create_ts_tz;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_CODE - v2.0 -
   --

   PROCEDURE create_ts_code (
      p_ts_code                OUT NUMBER,
      p_cwms_ts_id          IN     VARCHAR2,
      p_utc_offset          IN     NUMBER DEFAULT NULL,
      p_interval_forward    IN     NUMBER DEFAULT NULL,
      p_interval_backward   IN     NUMBER DEFAULT NULL,
      p_versioned           IN     VARCHAR2 DEFAULT 'F',
      p_active_flag         IN     VARCHAR2 DEFAULT 'T',
      p_fail_if_exists      IN     VARCHAR2 DEFAULT 'T',
      p_office_id           IN     VARCHAR2 DEFAULT NULL)
   IS
      l_office_id             VARCHAR2 (16);
      l_base_location_id      VARCHAR2 (50);
      l_base_location_code    NUMBER;
      l_sub_location_id       VARCHAR2 (50);
      l_base_parameter_id     VARCHAR2 (50);
      l_base_parameter_code   NUMBER;
      l_sub_parameter_id      VARCHAR2 (50);
      l_parameter_code        NUMBER;
      l_parameter_type_id     VARCHAR2 (50);
      l_parameter_type_code   NUMBER;
      l_interval              NUMBER;
      l_interval_id           VARCHAR2 (50);
      l_interval_code         NUMBER;
      l_duration_id           VARCHAR2 (50);
      l_duration              NUMBER;
      l_duration_code         NUMBER;
      l_version               VARCHAR2 (50);
      l_office_code           NUMBER;
      l_location_code         NUMBER;
      l_ret                   NUMBER;
      l_hashcode              NUMBER;
      l_str_error             VARCHAR2 (256);
      l_utc_offset            NUMBER;
      l_all_office_code       NUMBER := cwms_util.db_office_code_all;
      l_ts_id_exists          BOOLEAN := FALSE;
      l_can_create            BOOLEAN := TRUE;
      l_cwms_ts_id            varchar2(183);
      l_parts                 str_tab_t;
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_office_id);
      END IF;


      DBMS_APPLICATION_INFO.set_module ('create_ts_code',
                                        'parse timeseries_desc using regexp');
      ----------------------------------------------
      -- remove any aliases from location portion --
      ----------------------------------------------
      l_parts := cwms_util.split_text(p_cwms_ts_id, '.', 1);
      l_parts(1) := cwms_loc.get_location_id(l_parts(1), p_office_id);
      if l_parts(1) is null then
         l_cwms_ts_id := p_cwms_ts_id;
      else
         l_cwms_ts_id := cwms_util.join_text(l_parts, '.');
      end if;
      --parse values from timeseries_desc using regular expressions
      parse_ts (l_cwms_ts_id,
                l_base_location_id,
                l_sub_location_id,
                l_base_parameter_id,
                l_sub_parameter_id,
                l_parameter_type_id,
                l_interval_id,
                l_duration_id,
                l_version);
      --office codes must exist, if not fail and return error  (prebuilt table, dynamic office addition not allowed)
      DBMS_APPLICATION_INFO.set_action ('check for office_code');

      BEGIN
         SELECT office_code
           INTO l_office_code
           FROM cwms_office o
          WHERE o.office_id = l_office_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_OFFICE_ID', l_office_id);
      END;

      IF l_office_code = 0
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', l_office_id);
      END IF;

      DBMS_APPLICATION_INFO.set_action (
         'check for location_code, create if necessary');
      -- check for valid base_location_code based on id passed in, if not there then create, -
      -- if create error then fail and return -

      cwms_loc.create_location_raw (l_base_location_code,
                                    l_location_code,
                                    l_base_location_id,
                                    l_sub_location_id,
                                    l_office_code);

      IF l_location_code IS NULL
      THEN
         raise_application_error (-20203,
                                  'Unable to generate location_code',
                                  TRUE);
      END IF;

      -- check for valid cwms_code based on id passed in, if not there then create, if create error then fail and return
      DBMS_APPLICATION_INFO.set_action (
         'check for cwms_code, create if necessary');

      --generate hash and lock table for that hash value to serialize ts_create as timeseries_desc is not pkeyed.
      SELECT ORA_HASH (UPPER (l_office_id) || UPPER (p_cwms_ts_id),
                       1073741823)
        INTO l_hashcode
        FROM DUAL;

      l_ret :=
         DBMS_LOCK.request (id                  => l_hashcode,
                            timeout             => 0,
                            lockmode            => DBMS_LOCK.x_mode,
                            release_on_commit   => TRUE);

      IF l_ret > 0
      THEN
         l_can_create := FALSE; -- don't create a ts_code, just retrieve the one we're blocking against.
         DBMS_LOCK.sleep (2);
      END IF;

      -- BEGIN...

      -- determine rest of lookup codes based on passed in values, use scalar subquery to minimize context switches, return error if lookups not found
      DBMS_APPLICATION_INFO.set_action (
         'check code lookups, scalar subquery');

      SELECT (SELECT base_parameter_code
                FROM cwms_base_parameter p
               WHERE UPPER (p.base_parameter_id) =
                        UPPER (l_base_parameter_id))
                p,
             (SELECT duration_code
                FROM cwms_duration d
               WHERE UPPER (d.duration_id) = UPPER (l_duration_id))
                d,
             (SELECT duration
                FROM cwms_duration d
               WHERE UPPER (d.duration_id) = UPPER (l_duration_id))
                dd,
             (SELECT parameter_type_code
                FROM cwms_parameter_type p
               WHERE UPPER (p.parameter_type_id) =
                        UPPER (l_parameter_type_id))
                pt,
             (SELECT interval_code
                FROM cwms_interval i
               WHERE UPPER (i.interval_id) = UPPER (l_interval_id))
                i,
             (SELECT INTERVAL
                FROM cwms_interval ii
               WHERE UPPER (ii.interval_id) = UPPER (l_interval_id))
                ii
        INTO l_base_parameter_code,
             l_duration_code,
	     l_duration,
             l_parameter_type_code,
             l_interval_code,
             l_interval
        FROM DUAL;

      IF    l_base_parameter_code IS NULL
         OR l_duration_code IS NULL
         OR l_parameter_type_code IS NULL
         OR l_interval_code IS NULL
         OR (UPPER (l_parameter_type_id) = 'INST' AND l_duration <> 0)
      THEN
         l_str_error :=
            'ERROR: Invalid Time Series Description: ' || p_cwms_ts_id;

         IF l_base_parameter_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_base_parameter_id
               || ' is not a valid base parameter';
         END IF;

         IF l_duration_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_duration_id
               || ' is not a valid duration';
         END IF;

         IF l_interval_code IS NULL
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || l_interval_id
               || ' is not a valid interval';
         END IF;

         IF (UPPER (l_parameter_type_id) = 'INST' AND l_duration <> 0)
         THEN
            l_str_error :=
                  l_str_error
               || CHR (10)
               || ' Inst parameter type can not have non-zero duration';
         END IF;

         IF l_can_create
         THEN
            l_ret := DBMS_LOCK.release (l_hashcode);
         END IF;

         raise_application_error (-20205, l_str_error, TRUE);
      END IF;

      BEGIN
         IF l_sub_parameter_id IS NULL
         THEN
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = l_base_parameter_code
                   AND sub_parameter_id IS NULL
                   AND db_office_code IN (l_office_code, l_all_office_code);
         ELSE
            SELECT parameter_code
              INTO l_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = l_base_parameter_code
                   AND UPPER (sub_parameter_id) = UPPER (l_sub_parameter_id)
                   AND db_office_code IN (l_office_code, l_all_office_code);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_sub_parameter_id IS NULL
            THEN
               IF l_can_create
               THEN
                  l_ret := DBMS_LOCK.release (l_hashcode);
               END IF;

               cwms_err.RAISE (
                  'GENERIC_ERROR',
                     l_base_parameter_id
                  || ' is not a valid Base Parameter. Cannot Create a new CWMS_TS_ID');
            ELSE                                -- Insert new sub_parameter...
               INSERT INTO at_parameter (parameter_code,
                                         db_office_code,
                                         base_parameter_code,
                                         sub_parameter_id)
                    VALUES (cwms_seq.NEXTVAL,
                            l_office_code,
                            l_base_parameter_code,
                            l_sub_parameter_id)
                 RETURNING parameter_code
                      INTO l_parameter_code;
            END IF;
      END;

      --after all lookups, check for existing ts_code, insert it if not found, and verify that it was inserted with the returning, error if no valid ts_code is returned
      DBMS_APPLICATION_INFO.set_action (
         'check for ts_code, create if necessary');

      BEGIN
         SELECT ts_code
           INTO p_ts_code
           FROM at_cwms_ts_spec acts
          WHERE              /*office_code = l_office_code
                         AND */
               acts .location_code = l_location_code
                AND acts.parameter_code = l_parameter_code
                AND acts.parameter_type_code = l_parameter_type_code
                AND acts.interval_code = l_interval_code
                AND acts.duration_code = l_duration_code
                AND UPPER (NVL (acts.VERSION, 1)) =
                       UPPER (NVL (l_version, 1))
                AND acts.delete_date IS NULL;

         --
         l_ts_id_exists := TRUE;

         IF l_can_create
         THEN
            l_ret := DBMS_LOCK.release (l_hashcode);
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF l_can_create
            THEN
               IF l_interval = 0
               THEN
                  l_utc_offset := cwms_util.utc_offset_irregular;
               ELSE
                  l_utc_offset := cwms_util.utc_offset_undefined;

                  IF p_utc_offset IS NOT NULL
                  THEN
                     IF p_utc_offset = cwms_util.utc_offset_undefined
                     THEN
                        NULL;
                     ELSIF p_utc_offset >= 0 AND p_utc_offset < l_interval
                     THEN
                        l_utc_offset := p_utc_offset;
                     ELSE
                        COMMIT;
                        cwms_err.RAISE ('INVALID_UTC_OFFSET',
                                        p_utc_offset,
                                        l_interval_id);
                     END IF;
                  END IF;
               END IF;

               IF p_interval_forward < 0 OR p_interval_forward >= l_interval
               THEN
                  COMMIT;
                  cwms_err.raise (
                     'ERROR',
                        'Interval forward ('
                     || p_interval_forward
                     || ') must be >= 0 and < interval ('
                     || l_interval
                     || ')');
               END IF;

               IF    p_interval_backward < 0
                  OR p_interval_backward >= l_interval
               THEN
                  COMMIT;
                  cwms_err.raise (
                     'ERROR',
                        'Interval backward ('
                     || p_interval_backward
                     || ') must be >= 0 and < interval ('
                     || l_interval
                     || ')');
               END IF;

               IF p_interval_forward + p_interval_backward >= l_interval
               THEN
                  COMMIT;
                  cwms_err.raise (
                     'ERROR',
                        'Interval backward ('
                     || p_interval_backward
                     || ') plus interval forward ('
                     || p_interval_forward
                     || ') must be < interval ('
                     || l_interval
                     || ')');
               END IF;

               IF UPPER (p_active_flag) NOT IN ('T', 'F')
               THEN
                  COMMIT;
                  cwms_err.raise ('ERROR',
                                  'Active flag must be ''T'' or ''F''');
               END IF;

               IF UPPER (p_versioned) NOT IN ('T', 'F')
               THEN
                  COMMIT;
                  cwms_err.raise ('ERROR',
                                  'Versioned flag must be ''T'' or ''F''');
               END IF;

               INSERT INTO at_cwms_ts_spec t (ts_code,
                                              location_code,
                                              parameter_code,
                                              parameter_type_code,
                                              interval_code,
                                              duration_code,
                                              VERSION,
                                              interval_utc_offset,
                                              interval_forward,
                                              interval_backward,
                                              version_flag,
                                              active_flag)
                    VALUES (
                              cwms_seq.NEXTVAL,
                              l_location_code,
                              l_parameter_code,
                              l_parameter_type_code,
                              l_interval_code,
                              l_duration_code,
                              l_version,
                              l_utc_offset,
                              p_interval_forward,
                              p_interval_backward,
                              CASE UPPER (p_versioned)
                                 WHEN 'T' THEN 'Y'
                                 WHEN 'F' THEN NULL
                              END,
                              UPPER (p_active_flag))
                 RETURNING ts_code
                      INTO p_ts_code;

               ---------------------------------
               -- Publish a TSCreated message --
               ---------------------------------
               DECLARE
                  l_msg     SYS.aq$_jms_map_message;
                  l_msgid   PLS_INTEGER;
                  i         INTEGER;
               BEGIN
                  cwms_msg.new_message (l_msg, l_msgid, 'TSCreated');
                  l_msg.set_string (l_msgid, 'ts_id', p_cwms_ts_id);
                  l_msg.set_string (l_msgid, 'office_id', l_office_id);
                  l_msg.set_long (l_msgid, 'ts_code', p_ts_code);
                  i :=
                     cwms_msg.publish_message (l_msg,
                                               l_msgid,
                                               l_office_id || '_ts_stored');
               END;

               COMMIT;
            END IF;
      END;

      IF p_ts_code IS NULL
      THEN
         raise_application_error (-20204,
                                  'Unable to generate timeseries_code',
                                  TRUE);
      ELSIF l_ts_id_exists
      THEN
         IF UPPER (p_fail_if_exists) != 'F'
         THEN
            cwms_err.RAISE ('TS_ALREADY_EXISTS', p_cwms_ts_id);
         END IF;
      END IF;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END create_ts_code;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_CODE_TZ - v2.0 -
   --
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
      p_office_id           IN     VARCHAR2 DEFAULT NULL)
   IS
      l_ts_code   NUMBER;
   BEGIN
      create_ts_code (l_ts_code,
                      p_cwms_ts_id,
                      p_utc_offset,
                      p_interval_forward,
                      p_interval_backward,
                      p_versioned,
                      p_active_flag,
                      p_fail_if_exists,
                      p_office_id);

      set_ts_time_zone (l_ts_code, p_time_zone_name);
      p_ts_code := l_ts_code;
   END create_ts_code_tz;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- tz_offset_at_gmt
   --
   FUNCTION tz_offset_at_gmt (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN INTEGER
   IS
      l_offset          INTEGER := 0;
      l_tz_offset_str   VARCHAR2 (8)
                           := RTRIM (TZ_OFFSET (p_tz_name), CHR (0));
      l_ts_utc          TIMESTAMP;
      l_ts_loc          TIMESTAMP;
      l_hours           INTEGER;
      l_minutes         INTEGER;
      l_parts           str_tab_t;
   BEGIN
      IF l_tz_offset_str != '+00:00' AND l_tz_offset_str != '-00:00'
      THEN
         l_parts := cwms_util.split_text (l_tz_offset_str, ':');
         l_hours := TO_NUMBER (l_parts (1));
         l_minutes := TO_NUMBER (l_parts (2));

         IF l_hours < 0
         THEN
            l_minutes := l_hours * 60 - l_minutes;
         ELSE
            l_minutes := l_hours * 60 + l_minutes;
         END IF;

         l_ts_utc := CAST (p_date_time AS TIMESTAMP);
         l_ts_loc := FROM_TZ (l_ts_utc, 'UTC') AT TIME ZONE p_tz_name;
         l_offset :=
              l_minutes
            - ROUND (
                   (  cwms_util.to_millis (l_ts_loc)
                    - cwms_util.to_millis (l_ts_utc))
                 / 60000);
      END IF;

      RETURN l_offset;
   END;

   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- shift_for_localtime
   --
   FUNCTION shift_for_localtime (p_date_time IN DATE, p_tz_name IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      RETURN p_date_time + tz_offset_at_gmt (p_date_time, p_tz_name) / 1440;
   END shift_for_localtime;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- setup_retrieve
   --
   PROCEDURE setup_retrieve (p_start_time        IN OUT DATE,
                             p_end_time          IN OUT DATE,
                             p_reg_start_time       OUT DATE,
                             p_reg_end_time         OUT DATE,
                             p_ts_code           IN     NUMBER,
                             p_interval          IN     NUMBER,
                             p_offset            IN     NUMBER,
                             p_start_inclusive   IN     BOOLEAN,
                             p_end_inclusive     IN     BOOLEAN,
                             p_previous          IN     BOOLEAN,
                             p_next              IN     BOOLEAN,
                             p_trim              IN     BOOLEAN)
   IS
      l_start_time   DATE := p_start_time;
      l_end_time     DATE := p_end_time;
      l_temp_time    DATE;
   BEGIN
      --
      -- handle inclusive/exclusive by adjusting start/end times inward
      --
      IF NOT p_start_inclusive
      THEN
         l_start_time := l_start_time + 1 / 86400;
      END IF;

      IF NOT p_end_inclusive
      THEN
         l_end_time := l_end_time - 1 / 86400;
      END IF;

      --
      -- handle previous/next by adjusting start/end times outward
      --
      IF p_previous
      THEN
         IF p_interval = 0
         THEN
            SELECT MAX (date_time)
              INTO l_temp_time
              FROM av_tsv
             WHERE     ts_code = p_ts_code
                   AND date_time < l_start_time
                   AND start_date <= l_end_time;

            IF l_temp_time IS NOT NULL
            THEN
               l_start_time := l_temp_time;
            END IF;
         ELSE
            l_start_time := l_start_time - p_interval / 1440;
         END IF;
      END IF;

      IF p_next
      THEN
         IF p_interval = 0
         THEN
            SELECT MIN (date_time)
              INTO l_temp_time
              FROM av_tsv
             WHERE     ts_code = p_ts_code
                   AND date_time > l_end_time
                   AND end_date > l_start_time;

            IF l_temp_time IS NOT NULL
            THEN
               l_end_time := l_temp_time;
            END IF;
         ELSE
            l_end_time := l_end_time + p_interval / 1440;
         END IF;
      END IF;

      --
      -- handle trim by adjusting start/end times inward to first/last
      -- non-missing values
      --
      IF p_trim
      THEN
         SELECT MIN (date_time), MAX (date_time)
           INTO l_start_time, l_end_time
           FROM (SELECT date_time
                   FROM av_tsv v, cwms_data_quality q
                  WHERE     v.ts_code = p_ts_code
                        AND v.date_time BETWEEN l_start_time AND l_end_time
                        AND v.start_date <= l_end_time
                        AND v.end_date > l_start_time
                        AND v.quality_code = q.quality_code
                        AND q.validity_id != 'MISSING'
                        AND v.VALUE IS NOT NULL);
      END IF;

      --
      -- set the out parameters
      --
      p_start_time := l_start_time;
      p_end_time := l_end_time;

      IF p_interval = 0
      THEN
         --
         -- These parameters are used to generate a regular time series from which
         -- to fill in the times of missing values.  In the case of irregular time
         -- series, set them so that they will not generate a time series at all.
         --
         p_reg_start_time := NULL;
         p_reg_end_time := NULL;
      ELSE
         IF p_offset = cwms_util.utc_offset_undefined
         THEN
            p_reg_start_time :=
               get_time_on_after_interval (l_start_time, NULL, p_interval);
            p_reg_end_time :=
               get_time_on_before_interval (l_end_time, NULL, p_interval);
         ELSE
            p_reg_start_time :=
               get_time_on_after_interval (l_start_time,
                                           p_offset,
                                           p_interval);
            p_reg_end_time :=
               get_time_on_before_interval (l_end_time, p_offset, p_interval);
         END IF;
      END IF;
   END setup_retrieve;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- BUILD_RETRIEVE_TS_QUERY - v2.0 -
   --
   FUNCTION build_retrieve_ts_query (
      p_cwms_ts_id_out       OUT VARCHAR2,
      p_units_out            OUT VARCHAR2,
      p_cwms_ts_id        IN     VARCHAR2,
      p_units             IN     VARCHAR2,
      p_start_time        IN     DATE,
      p_end_time          IN     DATE,
      p_date_time_type    IN     VARCHAR2,
      p_time_zone         IN     VARCHAR2 DEFAULT 'UTC',
      p_trim              IN     VARCHAR2 DEFAULT 'F',
      p_start_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_previous          IN     VARCHAR2 DEFAULT 'F',
      p_next              IN     VARCHAR2 DEFAULT 'F',
      p_version_date      IN     DATE DEFAULT NULL,
      p_max_version       IN     VARCHAR2 DEFAULT 'T',
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
      RETURN SYS_REFCURSOR
   IS
      l_ts_code           NUMBER;
      l_location_code     NUMBER;
      l_interval          NUMBER;
      l_interval2         NUMBER := 60 / 1440;
      l_utc_offset        NUMBER;
      l_office_id         VARCHAR2 (16);
      l_cwms_ts_id        VARCHAR2 (183);
      l_units             VARCHAR2 (16);
      l_time_zone         VARCHAR2 (28);
      l_base_parameter_id VARCHAR2(16);
      l_trim              BOOLEAN;
      l_start_inclusive   BOOLEAN;
      l_end_inclusive     BOOLEAN;
      l_previous          BOOLEAN;
      l_next              BOOLEAN;
      l_start_time        DATE;
      l_end_time          DATE;
      l_version_date      DATE;
      l_reg_start_time    DATE;
      l_reg_end_time      DATE;
      l_max_version       BOOLEAN;
      l_query_str         VARCHAR2 (32767);
      l_start_str         VARCHAR2 (32);
      l_end_str           VARCHAR2 (32);
      l_reg_start_str     VARCHAR2 (32);
      l_reg_end_str       VARCHAR2 (32);
      l_missing           NUMBER := 5;                 -- MISSING quality code
      l_date_format       VARCHAR2 (32) := 'yyyy/mm/dd-hh24.mi.ss';
      l_cursor            SYS_REFCURSOR;
      l_strict_times      BOOLEAN := FALSE;
      l_value_offset      binary_double := 0;

      PROCEDURE set_action (text IN VARCHAR2)
      IS
      BEGIN
         DBMS_APPLICATION_INFO.set_action (text);
         --DBMS_OUTPUT.put_line (text);
      END;

      PROCEDURE replace_strings
      IS
      BEGIN
         l_query_str := REPLACE (l_query_str, ':tz', l_time_zone);
         l_query_str :=
            REPLACE (l_query_str, ':date_time_type', p_date_time_type);

         IF l_max_version
         THEN
            l_query_str := REPLACE (l_query_str, ':first_or_last', 'last');
         ELSE
            l_query_str := REPLACE (l_query_str, ':first_or_last', 'first');
         END IF;
      END;
   BEGIN
      --------------------
      -- initialization --
      --------------------
      l_office_id := NVL (p_office_id, cwms_util.user_office_id);
      l_cwms_ts_id := get_cwms_ts_id (p_cwms_ts_id, l_office_id);
      l_units := NVL (cwms_util.get_unit_id(p_units, l_Office_id), get_db_unit_id (l_cwms_ts_id));
      l_time_zone := NVL (p_time_zone, 'UTC');

      IF SUBSTR (l_time_zone, 1, 1) = '!'
      THEN
         l_strict_times := TRUE;
         l_time_zone := SUBSTR (l_time_zone, 2);
      END IF;

      l_time_zone := cwms_util.get_time_zone_name (l_time_zone);
      l_trim := cwms_util.return_true_or_false (NVL (p_trim, 'F'));
      l_start_inclusive :=
         cwms_util.return_true_or_false (NVL (p_start_inclusive, 'T'));
      l_end_inclusive :=
         cwms_util.return_true_or_false (NVL (p_end_inclusive, 'T'));
      l_previous := cwms_util.return_true_or_false (NVL (p_previous, 'F'));
      l_next := cwms_util.return_true_or_false (NVL (p_next, 'F'));
      l_start_time :=
         cwms_util.change_timezone (p_start_time, l_time_zone, 'UTC');
      l_end_time := cwms_util.change_timezone (p_end_time, l_time_zone, 'UTC');
      l_version_date :=
         cwms_util.change_timezone (p_version_date, l_time_zone, 'UTC');
      l_max_version :=
         cwms_util.return_true_or_false (NVL (p_max_version, 'F'));
      --
      -- set the out parameters
      --
      p_cwms_ts_id_out := l_cwms_ts_id;
      p_units_out      := l_units;

      --
      -- allow cwms_util.non_versioned to be used regarless of time zone
      --
      IF p_version_date = cwms_util.non_versioned
      THEN
         l_version_date := cwms_util.non_versioned;
      END IF;

      --
      -- get ts code
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.build_retrieve_ts_query',
                                        'Get TS Code');

      BEGIN
         select ts_code,
                interval,
                interval_utc_offset,
                base_parameter_id,
                location_code
           into l_ts_code,
                l_interval,
                l_utc_offset,
                l_base_parameter_id,
                l_location_code
           from at_cwms_ts_id
          where upper(db_office_id) = upper(l_office_id)
            and upper(cwms_ts_id) = upper(p_cwms_ts_id_out);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               select ts_code,
                      interval,
                      interval_utc_offset,
                      base_parameter_id,
                      location_code
                 into l_ts_code,
                      l_interval,
                      l_utc_offset,
                      l_base_parameter_id,
                      l_location_code
                 from at_cwms_ts_id
                where upper(db_office_id) = upper(l_office_id)
                  and upper(cwms_ts_id) = upper(p_cwms_ts_id_out);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  cwms_err.raise('TS_ID_NOT_FOUND', l_cwms_ts_id, l_office_id);
            END;
      END;

      if l_base_parameter_id = 'Elev' then
         l_value_offset := cwms_loc.get_vertical_datum_offset(l_location_code, p_units);
      end if;

      set_action ('Handle start and end times');
      setup_retrieve (l_start_time,
                      l_end_time,
                      l_reg_start_time,
                      l_reg_end_time,
                      l_ts_code,
                      l_interval,
                      l_utc_offset,
                      l_start_inclusive,
                      l_end_inclusive,
                      l_previous,
                      l_next,
                      l_trim);
      --
      -- change interval from minutes to days
      --
      l_interval := l_interval / 1440;

      IF l_interval > 0
      THEN
         l_reg_start_str := TO_CHAR (l_reg_start_time, l_date_format);
         l_reg_end_str := TO_CHAR (l_reg_end_time, l_date_format);
      END IF;

      l_start_str := TO_CHAR (l_start_time, l_date_format);
      l_end_str := TO_CHAR (l_end_time, l_date_format);

      --
      -- build the query string - for some reason the time zone must be a
      -- string literal and bind variables are problematic
      --
      IF l_version_date IS NULL
      THEN
         --
         -- min or max version date
         --
         IF l_interval > 0
         THEN
            --
            -- regular time series
            --
            IF MOD (l_interval, 30) = 0 OR MOD (l_interval, 365) = 0
            THEN
               --
               -- must use calendar math
               --
               -- change interval from days to months
               --
               IF MOD (l_interval, 30) = 0
               THEN
                  l_interval := l_interval / 30;
               ELSE
                  l_interval := l_interval / 365 * 12;
               END IF;

               l_query_str :=
                  'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      case
                         when value is nan then null
                         else value + :l_value_offset
                      end "VALUE",
                      cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                 from (
                      select date_time,
                             max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                             max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                        from av_tsv_dqu
                       where ts_code    =  :ts_code
                         and date_time  >= to_date(:l_start, :l_date_fmt)
                         and date_time  <= to_date(:l_end,   :l_date_fmt)
                         and unit_id    =  :units
                         and start_date <= to_date(:l_end,   :l_date_fmt)
                         and end_date   >  to_date(:l_start, :l_date_fmt)
                    group by date_time
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(add_months(to_date(:reg_start, :l_date_fmt), (level-1) * :interval), :l_time_zone) date_time
                        from dual
                       where to_date(:reg_start, :l_date_format) is not null
                  connect by level <= months_between(to_date(:reg_end,   :l_date_format),
                                                     to_date(:reg_start, :l_date_format)) / :interval + 1
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_missing,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_reg_start_str,
                        l_date_format,
                        l_interval,
                        l_time_zone,
                        l_reg_start_str,
                        l_date_format,
                        l_reg_end_str,
                        l_date_format,
                        l_reg_start_str,
                        l_date_format,
                        l_interval;
            ELSE
               --
               -- can use date arithmetic
               --
               IF l_strict_times
               THEN
                  l_query_str :=
                     'select date_time,
                          case
                             when value is nan then null
                             else value + :l_value_offset
                          end "VALUE",
                          cwms_ts.normalize_quality(quality_code) as quality_code
                     from ((select cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                                  value,
                                  quality_code
                             from (select t.date_time as date_time,
                                          case
                                             when value is nan then null
                                             else value
                                          end as value,
                                          nvl(quality_code, :missing) as quality_code
                                     from (
                                          select date_time,
                                                 max(value) keep(dense_rank :first_or_last order by version_date) as value,
                                                 max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                                            from av_tsv_dqu
                                           where ts_code    =  :ts_code
                                             and date_time  >= to_date(:l_start, :l_date_fmt)
                                             and date_time  <= to_date(:l_end,   :l_date_fmt)
                                             and unit_id    =  :units
                                             and start_date <= to_date(:l_end,   :l_date_fmt)
                                             and end_date   >  to_date(:l_start, :l_date_fmt)
                                        group by date_time
                                          ) v
                                          right outer join
                                          (
                                          select max(date_time) date_time
                                            from (select date_time,
                                                         cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                                                    from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                                            from dual
                                                      connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                               - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                                         )
                                                 )
                                         group by local_time
                                          ) t
                                          on v.date_time = t.date_time
                                  )
                           )
                           union all
                           (select date_time,
                                   null as value,
                                   :missing as quality_code
                              from (select prev_time + (level + :interval2 / :interval - 1) * :interval as date_time,
                                           level as level_count
                                      from (select date_time,
                                                   prev_time
                                              from (select date_time,
                                                           lag(date_time, 1, null) over (order by date_time) as prev_time,
                                                           date_time - lag(date_time, 1, null) over (order by date_time) as time_diff
                                                      from (select cwms_util.change_timezone(to_date(:reg_start, :l_date_fmt) + (level-1) * :interval2, ''UTC'', :l_timezone) as date_time
                                                              from dual
                                                   connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                            - to_date(:reg_start, :l_date_fmt)) / :interval2 + 1)
                                                           )
                                                   )
                                             where time_diff > greatest(:interval, :interval2)
                                          order by date_time
                                           )
                               connect by level < (date_time - prev_time) / :interval
                                   )
                             where level_count <= round(:interval2 / :interval)
                           ))
                 order by date_time';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);

                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_missing,
                           l_interval2,
                           l_interval,
                           l_interval,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_time_zone,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval;
               ELSE
                  l_query_str :=
                     'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                             case
                                when value is nan then null
                                else value + :l_value_offset
                             end "VALUE",
                             cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                        from (
                             select date_time,
                                    max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                                    max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                               from av_tsv_dqu
                              where ts_code    =  :ts_code
                                and date_time  >= to_date(:l_start, :l_date_fmt)
                                and date_time  <= to_date(:l_end,   :l_date_fmt)
                                and unit_id    =  :units
                                and start_date <= to_date(:l_end,   :l_date_fmt)
                                and end_date   >  to_date(:l_start, :l_date_fmt)
                              group by date_time
                             ) v
                             right outer join
                            (select date_time,
                                    cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                               from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                       from dual
                                 connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                          - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                    )
                             ) t
                             on v.date_time = t.date_time
                       order by t.date_time asc';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);

                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval;
               END IF;
            END IF;
         ELSE
            --
            -- irregular time series
            --
            IF l_strict_times
            THEN
               l_query_str :=
                  'select cast(from_tz(cast(max(date_time) as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                       max(value) keep(dense_rank last order by date_time) + :l_value_offset as value,
                       cwms_ts.normalize_quality(max(quality_code) keep(dense_rank last order by date_time)) as quality_code
                  from (select date_time,
                               cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) as local_time,
                               case
                                  when max(value) keep(dense_rank :first_or_last order by version_date) is nan then null
                                  else max(value) keep(dense_rank :first_or_last order by version_date)
                               end as value,
                               max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                          from av_tsv_dqu
                         where ts_code    =  :ts_code
                           and date_time  >= to_date(:l_start, :l_date_fmt)
                           and date_time  <= to_date(:l_end,   :l_date_fmt)
                           and unit_id    =  :units
                           and start_date <= to_date(:l_end,   :l_date_fmt)
                           and end_date   >  to_date(:l_start, :l_date_fmt)
                      group by date_time
                      )
                group by local_time
                order by local_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_time_zone,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format;
            ELSE
               l_query_str :=
               'select local_time as date_time,
                       case
                         when value is nan then null
                         else value + :l_value_offset
                       end "VALUE",
                       cwms_ts.normalize_quality(quality_code) as quality_code
                  from (select date_time,
                               cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as local_time,
                               case
                                  when max(value) keep(dense_rank :first_or_last order by version_date) is nan then null
                                  else max(value) keep(dense_rank :first_or_last order by version_date)
                               end as value,
                               max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                          from av_tsv_dqu
                         where ts_code    =  :ts_code
                           and date_time  >= to_date(:l_start, :l_date_fmt)
                           and date_time  <= to_date(:l_end,   :l_date_fmt)
                           and unit_id    =  :units
                           and start_date <= to_date(:l_end,   :l_date_fmt)
                           and end_date   >  to_date(:l_start, :l_date_fmt)
                         group by date_time
                       )
                 order by date_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format;
            END IF;
         END IF;
      ELSE
         --
         -- specified version date
         --
         IF l_interval > 0
         THEN
            --
            -- regular time series
            --
            IF MOD (l_interval, 30) = 0 OR MOD (l_interval, 365) = 0
            THEN
               --
               -- must use calendar math
               --
               -- change interval from days to months
               --
               IF MOD (l_interval, 30) = 0
               THEN
                  l_interval := l_interval / 30;
               ELSE
                  l_interval := l_interval / 365 * 12;
               END IF;

               l_query_str :=
                  'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                      case
                         when value is nan then null
                         else value + :l_value_offset
                      end "VALUE",
                      cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                 from (
                      select date_time,
                             value,
                             quality_code
                        from av_tsv_dqu
                       where ts_code      =  :ts_code
                         and date_time    >= to_date(:l_start,   :l_date_fmt)
                         and date_time    <= to_date(:l_end,     :l_date_fmt)
                         and unit_id      =  :units
                         and start_date   <= to_date(:l_end,     :l_date_fmt)
                         and end_date     >  to_date(:l_start,   :l_date_fmt)
                         and version_date =  :version
                      ) v
                      right outer join
                      (
                      select cwms_ts.shift_for_localtime(add_months(to_date(:reg_start, :l_date_format), (level-1) * :interval), :tz) date_time
                        from dual
                       where to_date(:reg_start, :l_date_format) is not null
                  connect by level <= months_between(to_date(:reg_start, :l_date_format),
                                                     to_date(:reg_end,   :l_date_format)) / :interval + 1)
                      ) t
                      on v.date_time = t.date_time
                      order by t.date_time asc';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_missing,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_version_date,
                        l_reg_start_str,
                        l_date_format,
                        l_interval,
                        l_time_zone,
                        l_reg_start_str,
                        l_date_format,
                        l_reg_start_str,
                        l_date_format,
                        l_reg_end_str,
                        l_date_format,
                        l_interval;
            ELSE
               --
               -- can use date arithmetic
               --
               IF l_strict_times
               THEN
                  l_query_str :=
                  'select date_time,
                          case
                             when value is nan then null
                             else value + :l_value_offset
                          end "VALUE",
                          cwms_ts.normalize_quality(quality_code) as quality_code
                     from ((select cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                                  value,
                                  quality_code
                             from (select t.date_time as date_time,
                                          case
                                             when value is nan then null
                                             else value
                                          end as value,
                                          nvl(quality_code, :missing) as quality_code
                                     from (
                                          select date_time,
                                                 value,
                                                 quality_code
                                            from av_tsv_dqu
                                           where ts_code     =  :ts_code
                                             and date_time   >= to_date(:l_start, :l_date_fmt)
                                             and date_time   <= to_date(:l_end,   :l_date_fmt)
                                             and unit_id     =  :units
                                             and start_date  <= to_date(:l_end,   :l_date_fmt)
                                             and end_date    >  to_date(:l_start, :l_date_fmt)
                                             and version_date = :version
                                          ) v
                                          right outer join
                                          (
                                          select max(date_time) date_time
                                            from (select date_time,
                                                         cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                                                    from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                                            from dual
                                                      connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                               - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                                         )
                                                 )
                                         group by local_time
                                          ) t
                                          on v.date_time = t.date_time
                                  )
                           )
                           union all
                           (select date_time,
                                   null as value,
                                   :missing as quality_code
                              from (select prev_time + (level + :interval2 / :interval - 1) * :interval as date_time,
                                           level as level_count
                                      from (select date_time,
                                                   prev_time
                                              from (select date_time,
                                                           lag(date_time, 1, null) over (order by date_time) as prev_time,
                                                           date_time - lag(date_time, 1, null) over (order by date_time) as time_diff
                                                      from (select cwms_util.change_timezone(to_date(:reg_start, :l_date_fmt) + (level-1) * :interval2, ''UTC'', :l_timezone) as date_time
                                                              from dual
                                                   connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                                            - to_date(:reg_start, :l_date_fmt)) / :interval2 + 1)
                                                           )
                                                   )
                                             where time_diff > greatest(:interval, :interval2)
                                          order by date_time
                                           )
                               connect by level < (date_time - prev_time) / :interval
                                   )
                             where level_count <= round(:interval2 / :interval)
                           ))
                 order by date_time';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);

                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_version_date,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_missing,
                           l_interval2,
                           l_interval,
                           l_interval,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_time_zone,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval,
                           l_interval2,
                           l_interval;
               ELSE
                  l_query_str :=
                  'select cast(from_tz(cast(t.date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) "DATE_TIME",
                          case
                             when value is nan then null
                             else value + :l_value_offset
                          end "VALUE",
                          cwms_ts.normalize_quality(nvl(quality_code, :missing)) "QUALITY_CODE"
                     from (
                          select date_time,
                                 max(value) keep(dense_rank :first_or_last order by version_date) "VALUE",
                                 max(quality_code) keep(dense_rank :first_or_last order by version_date) "QUALITY_CODE"
                            from av_tsv_dqu
                           where ts_code     =  :ts_code
                             and date_time   >= to_date(:l_start, :l_date_fmt)
                             and date_time   <= to_date(:l_end,   :l_date_fmt)
                             and unit_id     =  :units
                             and start_date  <= to_date(:l_end,   :l_date_fmt)
                             and end_date    >  to_date(:l_start, :l_date_fmt)
                             and version_date = :version
                           group by date_time
                          ) v
                          right outer join
                          (select date_time,
                                  cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) local_time
                             from (select to_date(:reg_start, :l_date_fmt) + (level-1) * :interval date_time
                                     from dual
                               connect by level <= round((to_date(:reg_end,   :l_date_fmt)
                                                        - to_date(:reg_start, :l_date_fmt)) / :interval + 1)
                                  )
                          ) t
                          on v.date_time = t.date_time
                    order by t.date_time asc';
                  replace_strings;
                  cwms_util.check_dynamic_sql(l_query_str);
                  OPEN l_cursor FOR l_query_str
                     USING l_value_offset,
                           l_missing,
                           l_ts_code,
                           l_start_str,
                           l_date_format,
                           l_end_str,
                           l_date_format,
                           l_units,
                           l_end_str,
                           l_date_format,
                           l_start_str,
                           l_date_format,
                           l_version_date,
                           l_time_zone,
                           l_reg_start_str,
                           l_date_format,
                           l_interval,
                           l_reg_end_str,
                           l_date_format,
                           l_reg_start_str,
                           l_date_format,
                           l_interval;
               END IF;
            END IF;
         ELSE
            --
            -- irregular time series
            --
            IF l_strict_times
            THEN
               l_query_str :=
                  'select cast(from_tz(cast(max(date_time) as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as date_time,
                       max(value) keep(dense_rank last order by date_time) + :l_value_offset as value,
                       cwms_ts.normalize_quality(max(quality_code) keep(dense_rank last order by date_time)) as quality_code
                  from (select date_time,
                               cwms_util.change_timezone(date_time, ''UTC'', :l_time_zone) as local_time,
                               case
                                  when value is nan then null
                                  else value
                               end as value,
                               quality_code
                          from av_tsv_dqu
                         where ts_code     =  :ts_code
                           and date_time   >= to_date(:l_start, :l_date_fmt)
                           and date_time   <= to_date(:l_end,   :l_date_fmt)
                           and unit_id     =  :units
                           and start_date  <= to_date(:l_end,   :l_date_fmt)
                           and end_date    >  to_date(:l_start, :l_date_fmt)
                           and version_date = :version
                      )
             group by local_time
             order by local_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_time_zone,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_version_date;
            ELSE
               l_query_str :=
                'select local_time as date_time,
                        case
                          when value is nan then null
                          else value + :l_value_offset
                       end "VALUE",
                       cwms_ts.normalize_quality(quality_code) as quality_code
                  from (select date_time,
                               cast(from_tz(cast(date_time as timestamp), ''UTC'') at time zone '':tz'' as :date_time_type) as local_time,
                               case
                                  when max(value) keep(dense_rank :first_or_last order by version_date) is nan then null
                                  else max(value) keep(dense_rank :first_or_last order by version_date)
                               end as value,
                               max(quality_code) keep(dense_rank :first_or_last order by version_date) as quality_code
                          from av_tsv_dqu
                         where ts_code     =  :ts_code
                           and date_time   >= to_date(:l_start, :l_date_fmt)
                           and date_time   <= to_date(:l_end,   :l_date_fmt)
                           and unit_id     =  :units
                           and start_date  <= to_date(:l_end,   :l_date_fmt)
                           and end_date    >  to_date(:l_start, :l_date_fmt)
                           and version_date = :version
                         group by date_time
                       )
                 order by date_time';
               replace_strings;
               cwms_util.check_dynamic_sql(l_query_str);

               OPEN l_cursor FOR l_query_str
                  USING l_value_offset,
                        l_ts_code,
                        l_start_str,
                        l_date_format,
                        l_end_str,
                        l_date_format,
                        l_units,
                        l_end_str,
                        l_date_format,
                        l_start_str,
                        l_date_format,
                        l_version_date;
            END IF;
         END IF;
      END IF;

      RETURN l_cursor;
   END build_retrieve_ts_query;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_OUT - v2.0 -
   --
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
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      l_query_str   VARCHAR2 (4000);

      PROCEDURE set_action (text IN VARCHAR2)
      IS
      BEGIN
         DBMS_APPLICATION_INFO.set_action (text);
         DBMS_OUTPUT.put_line (text);
      END;
   BEGIN
      --
      -- Get the query string
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts',
                                        'Get query string');

      p_at_tsv_rc :=
         build_retrieve_ts_query (p_cwms_ts_id_out,
                                  p_units_out,
                                  p_cwms_ts_id,
                                  p_units,
                                  p_start_time,
                                  p_end_time,
                                  'date',
                                  p_time_zone,
                                  p_trim,
                                  p_start_inclusive,
                                  p_end_inclusive,
                                  p_previous,
                                  p_next,
                                  p_version_date,
                                  p_max_version,
                                  p_office_id);

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END retrieve_ts_out;

   --*******************************************************************   --

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
      PIPELINED
   IS
      query_cursor       SYS_REFCURSOR;
      output_row         zts_rec_t;
      l_cwms_ts_id_out   VARCHAR2 (183);
      l_units_out        VARCHAR2 (16);
   BEGIN
      retrieve_ts_out (p_at_tsv_rc         => query_cursor,
                       p_cwms_ts_id_out    => l_cwms_ts_id_out,
                       p_units_out         => l_units_out,
                       p_cwms_ts_id        => p_cwms_ts_id,
                       p_units             => p_units,
                       p_start_time        => p_start_time,
                       p_end_time          => p_end_time,
                       p_time_zone         => p_time_zone,
                       p_trim              => p_trim,
                       p_start_inclusive   => p_start_inclusive,
                       p_end_inclusive     => p_end_inclusive,
                       p_previous          => p_previous,
                       p_next              => p_next,
                       p_version_date      => p_version_date,
                       p_max_version       => p_max_version,
                       p_office_id         => p_office_id);

      LOOP
         FETCH query_cursor INTO output_row;

         EXIT WHEN query_cursor%NOTFOUND;
         PIPE ROW (output_row);
      END LOOP;

      CLOSE query_cursor;

      RETURN;
   END retrieve_ts_out_tab;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS - v1.4 -
   --
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
      p_max_version   IN     NUMBER DEFAULT cwms_util.true_num)
   IS
      l_trim          VARCHAR2 (1);
      l_max_version   VARCHAR2 (1);
      l_query_str     VARCHAR2 (4000);
      l_tsid          VARCHAR2 (183);
      l_unit          VARCHAR2 (16);

      PROCEDURE set_action (text IN VARCHAR2)
      IS
      BEGIN
         DBMS_APPLICATION_INFO.set_action (text);
         DBMS_OUTPUT.put_line (text);
      END;
   BEGIN
      --
      -- handle input parameters
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts',
                                        'Handle input parameters');

      IF p_trim IS NULL OR p_trim = cwms_util.false_num
      THEN
         l_trim := 'F';
      ELSIF p_trim = cwms_util.true_num
      THEN
         l_trim := 'T';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_trim);
      END IF;

      IF p_max_version IS NULL OR p_max_version = cwms_util.true_num
      THEN
         l_max_version := 'T';
      ELSIF p_max_version = cwms_util.false_num
      THEN
         l_max_version := 'F';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_max_version);
      END IF;

      --
      -- Get the query string
      --
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts',
                                        'Get query string');

      p_at_tsv_rc :=
         build_retrieve_ts_query (l_tsid,                  -- p_cwms_ts_id_out
                                  l_unit,                       -- p_units_out
                                  p_cwms_ts_id,                -- p_cwms_ts_id
                                  p_units,                          -- p_units
                                  p_start_time,                -- p_start_time
                                  p_end_time,                    -- p_end_time
                                  'timestamp with time zone', -- p_date_time_type
                                  p_timezone,                   -- p_time_zone
                                  l_trim,                            -- p_trim
                                  'T',                    -- p_start_inclusive
                                  'T',                      -- p_end_inclusive
                                  'F',                           -- p_previous
                                  'F',                               -- p_next
                                  p_versiondate,             -- p_version_date
                                  l_max_version,              -- p_max_version
                                  p_officeid);                  -- p_office_id

      --l_query_str := replace(l_query_str, ':date_time_type', 'timestamp with time zone');
      --
      -- open the cursor
      --
      --set_action('Open cursor');
      --open p_at_tsv_rc for l_query_str;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END retrieve_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_2 - v1.4 -
   --
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
      p_max_version   IN     NUMBER DEFAULT cwms_util.true_num)
   IS
      l_at_tsv_rc   SYS_REFCURSOR;
   BEGIN
      retrieve_ts (p_at_tsv_rc,
                   p_units,
                   p_officeid,
                   p_cwms_ts_id,
                   p_start_time,
                   p_end_time,
                   p_timezone,
                   p_trim,
                   p_inclusive,
                   p_versiondate,
                   p_max_version);
   END retrieve_ts_2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS - v2.0 -
   --
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
                          p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      l_cwms_ts_id_out   VARCHAR2 (183);
      l_units_out        VARCHAR2 (16);
      l_at_tsv_rc        SYS_REFCURSOR;
   BEGIN
      retrieve_ts_out (l_at_tsv_rc,
                       l_cwms_ts_id_out,
                       l_units_out,
                       p_cwms_ts_id,
                       p_units,
                       p_start_time,
                       p_end_time,
                       p_time_zone,
                       p_trim,
                       p_start_inclusive,
                       p_end_inclusive,
                       p_previous,
                       p_next,
                       p_version_date,
                       p_max_version,
                       p_office_id);
      p_at_tsv_rc := l_at_tsv_rc;
   END retrieve_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_MULTI - v2.0 -
   --
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
      p_office_id         IN     VARCHAR2 DEFAULT NULL)
   IS
      TYPE date_tab_t IS TABLE OF DATE;

      TYPE val_tab_t IS TABLE OF BINARY_DOUBLE;

      TYPE qual_tab_t IS TABLE OF NUMBER;

      TS_ID_NOT_FOUND   EXCEPTION;
      PRAGMA EXCEPTION_INIT (TS_ID_NOT_FOUND, -20001);
      date_tab          date_tab_t := date_tab_t ();
      val_tab           val_tab_t := val_tab_t ();
      qual_tab          qual_tab_t := qual_tab_t ();
      i                 INTEGER;
      j                 PLS_INTEGER;
      t                 nested_ts_table := nested_ts_table ();
      rec               SYS_REFCURSOR;
      l_time_zone       VARCHAR2 (28) := NVL (p_time_zone, 'UTC');
      must_exist        BOOLEAN;
      tsid              VARCHAR2 (183);
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.retrieve_ts_multi',
                                        'Preparation loop');

      --
      -- This routine actually iterates all the results in order to pack them into
      -- a collection that can be queried to generate the nested cursors.
      --
      -- I used this setup becuase I was not able to get the complex query used in
      --  retrieve_ts_out to work as a cursor expression.
      --
      -- MDP
      -- 01 May 2008
      --
      FOR i IN 1 .. p_timeseries_info.COUNT
      LOOP
         tsid := p_timeseries_info (i).tsid;

         IF SUBSTR (tsid, 1, 1) = '?'
         THEN
            tsid := SUBSTR (tsid, 2);
            must_exist := FALSE;
         ELSE
            must_exist := TRUE;
         END IF;

         t.EXTEND;
         t (i) :=
            nested_ts_type (i,
                            tsid,
                            p_timeseries_info (i).unit,
                            p_timeseries_info (i).start_time,
                            p_timeseries_info (i).end_time,
                            tsv_array ());

         BEGIN
            retrieve_ts_out (rec,
                             t (i).tsid,
                             t (i).units,
                             t (i).tsid,
                             p_timeseries_info (i).unit,
                             p_timeseries_info (i).start_time,
                             p_timeseries_info (i).end_time,
                             p_time_zone,
                             p_trim,
                             p_start_inclusive,
                             p_end_inclusive,
                             p_previous,
                             p_next,
                             p_version_date,
                             p_max_version,
                             p_office_id);

            date_tab.delete;
            val_tab.delete;
            qual_tab.delete;

            FETCH rec
            BULK COLLECT INTO date_tab, val_tab, qual_tab;

            t (i).data.EXTEND (rec%ROWCOUNT);

            FOR j IN 1 .. rec%ROWCOUNT
            LOOP
               t (i).data (j) :=
                  tsv_type (
                     FROM_TZ (CAST (date_tab (j) AS TIMESTAMP), 'UTC'),
                     val_tab (j),
                     qual_tab (j));
            END LOOP;
         EXCEPTION
            WHEN TS_ID_NOT_FOUND
            THEN
               IF NOT must_exist
               THEN
                  NULL;
               END IF;
         END;
      END LOOP;

      OPEN p_at_tsv_rc FOR
           SELECT sequence,
                  tsid,
                  units,
                  start_time,
                  end_time,
                  l_time_zone "TIME_ZONE",
                  CURSOR (  SELECT date_time, VALUE, quality_code
                              FROM TABLE (t1.data)
                          ORDER BY date_time ASC)
                     "DATA"
             FROM TABLE (t) t1
         ORDER BY sequence ASC;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END retrieve_ts_multi;

   --
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CLEAN_QUALITY_CODE -
   --
   function clean_quality_code(
      p_quality_code in number)
      return number
      result_cache
   is
      /*
      Data Quality Rules :

          1. Unless the Screened bit is set, no other bits can be set.

          2. Unused bits(22, 24, 27-31, 32+) must be reset(zero).

          3. The Okay, Missing, Questioned and Rejected bits are mutually
             exclusive.

          4. No replacement cause or replacement method bits can be set unless
             the changed(different) bit is also set, and if the changed(different)
             bit is set, one of the cause bits and one of the replacement
             method bits must be set.

          5. Replacement Cause integer is in range 0..4.

          6. Replacement Method integer is in range 0..4

          7. The Test Failed bits are not mutually exclusive(multiple tests can be
             marked as failed).

      Bit Mappings :

               3                   2                   1
           2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1

           P - - - - - T T - T - T T T T T T M M M M C C C D R R V V V V S
           |           <---------+---------> <--+--> <-+-> | <+> <--+--> |
           |                     |              |      |   |  |     |    +------Screened T/F
           |                     |              |      |   |  |     +-----------Validity Flags
           |                     |              |      |   |  +--------------Value Range Integer
           |                     |              |      |   +-------------------Different T/F
           |                     |              |      +---------------Replacement Cause Integer
           |                     |              +---------------------Replacement Method Integer
           |                     +-------------------------------------------Test Failed Flags
           +-------------------------------------------------------------------Protected T/F
      */
      c_used_bits             constant integer := 2204106751; -- 1000 0011 0101 1111 1111 1111 1111 1111
      c_screened              constant integer := 1;          -- 0000 0000 0000 0000 0000 0000 0000 0001
      c_ok                    constant integer := 2;          -- 0000 0000 0000 0000 0000 0000 0000 0010
      c_ok_mask               constant integer := 4294967267; -- 1111 1111 1111 1111 1111 1111 1110 0011
      c_missing               constant integer := 4;          -- 0000 0000 0000 0000 0000 0000 0000 0100
      c_missing_mask          constant integer := 4294967269; -- 1111 1111 1111 1111 1111 1111 1110 0101
      c_questioned            constant integer := 8;          -- 0000 0000 0000 0000 0000 0000 0000 1000
      c_questioned_mask       constant integer := 4294967273; -- 1111 1111 1111 1111 1111 1111 1110 1001
      c_rejected              constant integer := 16;         -- 0000 0000 0000 0000 0000 0000 0001 0000
      c_rejected_mask         constant integer := 4294967281; -- 1111 1111 1111 1111 1111 1111 1111 0001
      c_different_mask        constant integer := 128;        -- 0000 0000 0000 0000 0000 0000 1000 0000
      c_not_different_mask    constant integer := -129;       -- 1111 1111 1111 1111 1111 1111 0111 1111
      c_repl_cause_mask       constant integer := 1792;       -- 0000 0000 0000 0000 0000 0111 0000 0000
      c_no_repl_cause_mask    constant integer := 4294965503; -- 1111 1111 1111 1111 1111 1000 1111 1111
      c_repl_method_mask      constant integer := 30720;      -- 0000 0000 0000 0000 0111 1000 0000 0000
      c_no_repl_method_mask   constant integer := 4294936575; -- 1111 1111 1111 1111 1000 0111 1111 1111
      c_repl_cause_factor     constant integer := 256;        -- 2 ** 8 for shifting 8 bits
      c_repl_method_factor    constant integer := 2048;       -- 2 ** 11 for shifting 11 bits
      l_quality_code                   integer;
      l_repl_cause                     integer;
      l_repl_method                    integer;
      l_different                      boolean;

      function bitor(
         num1 in integer,
         num2 in integer)
         return integer
      is
      begin
         return num1 + num2 - bitand(num1, num2);
      end;
   begin
      if p_quality_code is null then
         l_quality_code := 0;
      else
         l_quality_code := p_quality_code;
         begin
            --------------------------------------------
            -- first see if the code is already clean --
            --------------------------------------------
            select quality_code
              into l_quality_code
              from cwms_data_quality
             where quality_code = l_quality_code;
         exception
            when no_data_found
            then
               -----------------------------------------------
               -- clear all bits if screened bit is not set --
               -----------------------------------------------
               if bitand(l_quality_code, c_screened) = 0 then
                  l_quality_code := 0;
               else
                  ---------------------------------------------------------------------
                  -- ensure only used bits are set(also counteracts sign-extension) --
                  ---------------------------------------------------------------------
                  l_quality_code := bitand(l_quality_code, c_used_bits);

                  -----------------------------------------
                  -- ensure only one validity bit is set --
                  -----------------------------------------
                  if bitand(l_quality_code, c_missing) != 0 then
                     l_quality_code := bitand(l_quality_code, c_missing_mask);
                  elsif bitand(l_quality_code, c_rejected) != 0 then
                     l_quality_code := bitand(l_quality_code, c_rejected_mask);
                  elsif bitand(l_quality_code, c_questioned) != 0 then
                     l_quality_code := bitand(l_quality_code, c_questioned_mask);
                  elsif bitand(l_quality_code, c_ok) != 0 then
                     l_quality_code := bitand(l_quality_code, c_ok_mask);
                  end if;

                  --------------------------------------------------------
                  -- ensure the replacement cause is not greater than 4 --
                  --------------------------------------------------------
                  l_repl_cause := trunc(bitand(l_quality_code, c_repl_cause_mask) / c_repl_cause_factor);

                  if l_repl_cause > 4 then
                     l_repl_cause := 4;
                     l_quality_code := bitor(bitand(l_quality_code, c_no_repl_cause_mask), l_repl_cause * c_repl_cause_factor);
                  end if;

                  ---------------------------------------------------------
                  -- ensure the replacement method is not greater than 4 --
                  ---------------------------------------------------------
                  l_repl_method := trunc(bitand(l_quality_code, c_repl_method_mask)/ c_repl_method_factor);

                  if l_repl_method > 4 then
                     l_repl_method := 4;
                     l_quality_code := bitor(bitand(l_quality_code, c_no_repl_method_mask), l_repl_method * c_repl_method_factor);
                  end if;

                  --------------------------------------------------------------------------------------------------------------
                  -- ensure that if 2 of replacement cause, replacement method, and different are 0, the remaining one is too --
                  --------------------------------------------------------------------------------------------------------------
                  l_different := bitand(l_quality_code, c_different_mask) != 0;

                  if l_repl_cause = 0 then
                     if l_repl_method = 0 and l_different then
                        l_quality_code := bitand(l_quality_code, c_not_different_mask);
                        l_different := false;
                     elsif(not l_different) and l_repl_method != 0 then
                        l_repl_method := 0;
                        l_quality_code := bitand(l_quality_code, c_no_repl_method_mask);
                     end if;
                  elsif l_repl_method = 0 and not l_different then
                     l_repl_cause := 0;
                     l_quality_code := bitand(l_quality_code, c_no_repl_cause_mask);
                  end if;

                  ------------------------------------------------------------------------------------------------------------------------------
                  -- ensure that if 2 of replacement cause, replacement method, and different are NOT 0, the remaining one is set accordingly --
                  ------------------------------------------------------------------------------------------------------------------------------
                  if l_repl_cause != 0 then
                     if l_repl_method != 0 and not l_different then
                        l_quality_code := bitor(l_quality_code, c_different_mask);
                        l_different := true;
                     elsif l_different and l_repl_method = 0 then
                        l_repl_method := 2;                           -- EXPLICIT
                        l_quality_code := bitor(l_quality_code, l_repl_method * c_repl_method_factor);
                     end if;
                  elsif l_repl_method != 0 and l_different then
                     l_repl_cause := 3;                                 -- MANUAL
                     l_quality_code := bitor(l_quality_code, l_repl_cause * c_repl_cause_factor);
                  end if;
               end if;
         end;
      end if;

      return l_quality_code;
   end clean_quality_code;

   -------------------------------------------------------------------------------
   -- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
   --
   FUNCTION use_first_table (p_timestamp IN TIMESTAMP DEFAULT NULL)
      RETURN BOOLEAN
   IS
      pragma autonomous_transaction;
      l_ts_month    integer;
      l_table_month integer;
      l_first_table boolean;
      l_table_ts    timestamp;
   BEGIN
      l_ts_month := to_number(to_char(nvl(p_timestamp, systimestamp), 'MM'));
      l_first_table := mod(l_ts_month, 2) = 1;
      if l_first_table then
         select min(message_time) into l_table_ts from at_ts_msg_archive_1;
      else
         select min(message_time) into l_table_ts from at_ts_msg_archive_2;
      end if;
      l_table_month := to_number(to_char(l_table_ts, 'MM'));
      if l_table_month != l_ts_month then
         execute immediate case l_first_table
                              when true  then 'truncate table at_ts_msg_archive_1'
                              when false then 'truncate table at_ts_msg_archive_2'
                           end;
         commit;
      end if;
      return l_first_table;
   END use_first_table;

   -------------------------------------------------------------------------------
   -- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
   --
   FUNCTION use_first_table (p_timestamp IN INTEGER)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN use_first_table (cwms_util.TO_TIMESTAMP (p_timestamp));
   END use_first_table;

   -------------------------------------------------------------------------------
   -- PROCEDURE TIME_SERIES_UPDATED(...)
   --
   PROCEDURE time_series_updated (p_ts_code      IN INTEGER,
                                  p_ts_id        IN VARCHAR2,
                                  p_office_id    IN VARCHAR2,
                                  p_first_time   IN TIMESTAMP WITH TIME ZONE,
                                  p_last_time    IN TIMESTAMP WITH TIME ZONE,
                                  p_version_date IN TIMESTAMP WITH TIME ZONE,
                                  p_store_time   IN TIMESTAMP WITH TIME ZONE,
                                  p_store_rule   IN VARCHAR2)
   IS
      l_msg          SYS.aq$_jms_map_message;
      l_dx_msg       SYS.aq$_jms_map_message;
      l_msgid        PLS_INTEGER;
      l_dx_msgid     PLS_INTEGER;
      l_first_time   TIMESTAMP;
      l_last_time    TIMESTAMP;
      l_version_date TIMESTAMP;
      l_store_time   TIMESTAMP;
      i              INTEGER;
   BEGIN
      -------------------------------------------------------
      -- insert the time series update info into the table --
      -------------------------------------------------------
      l_first_time   := trunc(sys_extract_utc(cwms_util.fixup_timezone(p_first_time)),   'mi');
      l_last_time    := trunc(sys_extract_utc(cwms_util.fixup_timezone(p_last_time)),    'mi');
      l_version_date := trunc(sys_extract_utc(cwms_util.fixup_timezone(p_version_date)), 'mi');
      l_store_time   := sys_extract_utc(cwms_util.fixup_timezone(p_store_time));

      for i in 1..3 loop
         -- try a few times; give up if not successful
         begin
            IF use_first_table
            THEN
               ----------------
               -- odd months --
               ----------------
               INSERT INTO at_ts_msg_archive_1
                    VALUES (cwms_msg.get_msg_id,
                            p_ts_code,
                            SYSTIMESTAMP,
                            CAST (l_first_time AS DATE),
                            CAST (l_last_time AS DATE));
            ELSE
               -----------------
               -- even months --
               -----------------
               INSERT INTO at_ts_msg_archive_2
                    VALUES (cwms_msg.get_msg_id,
                            p_ts_code,
                            SYSTIMESTAMP,
                            CAST (l_first_time AS DATE),
                            CAST (l_last_time AS DATE));
            END IF;
         exception
            when others then
               if sqlcode = -1 then
                  if i < 3 then
                     continue;
                  else
                     cwms_err.raise('ERROR', 'Could not get unique message id in 3 attempts');
                  end if;
               end if;
         end;
         exit; -- no exception
      end loop;

      -------------------------
      -- publish the message --
      -------------------------
      cwms_msg.new_message (l_msg, l_msgid, 'TSDataStored');
      l_msg.set_string (l_msgid, 'ts_id', p_ts_id);
      l_msg.set_string (l_msgid, 'office_id', p_office_id);
      l_msg.set_long (l_msgid, 'ts_code', p_ts_code);
      l_msg.set_long (l_msgid,
                      'start_time',
                      cwms_util.to_millis (l_first_time));
      l_msg.set_long (l_msgid, 'end_time', cwms_util.to_millis (l_last_time));
      l_msg.set_long (l_msgid, 'version_date', cwms_util.to_millis (l_version_date));
      l_msg.set_long (l_msgid, 'store_time', cwms_util.to_millis (l_store_time));
      l_msg.set_string (l_msgid, 'store_rule', p_store_rule);
      i :=
         cwms_msg.publish_message (l_msg,
                                   l_msgid,
                                   p_office_id || '_ts_stored');

      IF cwms_xchg.is_realtime_export (p_ts_code)
      THEN
         -----------------------------------------------
         -- notify the real-time Oracle->DSS exchange --
         -----------------------------------------------
         cwms_msg.new_message (l_dx_msg, l_dx_msgid, 'TSDataStored');
         l_dx_msg.set_string (l_dx_msgid, 'ts_id', p_ts_id);
         l_dx_msg.set_string (l_dx_msgid, 'office_id', p_office_id);
         l_dx_msg.set_long (l_dx_msgid, 'ts_code', p_ts_code);
         l_dx_msg.set_long (l_dx_msgid,
                        'start_time',
                        cwms_util.to_millis (l_first_time));
         l_dx_msg.set_long (l_dx_msgid, 'end_time', cwms_util.to_millis (l_last_time));
         i :=
            cwms_msg.publish_message (l_dx_msg,
                                      l_dx_msgid,
                                      p_office_id || '_realtime_ops');
      END IF;
   END time_series_updated;


   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE store_ts (
      p_office_id         IN VARCHAR2,
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN NUMBER DEFAULT cwms_util.false_num,
      p_versiondate       IN DATE DEFAULT cwms_util.non_versioned)
   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   IS
      l_override_prot   VARCHAR2 (1);
   BEGIN
      cwms_apex.aa1 (
            TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI')
         || 'store_ts(1.4): '
         || p_cwms_ts_id);

      IF p_override_prot IS NULL OR p_override_prot = cwms_util.false_num
      THEN
         l_override_prot := 'F';
      ELSIF p_override_prot = cwms_util.true_num
      THEN
         l_override_prot := 'T';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG_OLD', p_override_prot);
      END IF;

      DBMS_OUTPUT.put_line ('tag wie gehts2?');
      store_ts (p_cwms_ts_id,
                p_units,
                p_timeseries_data,
                p_store_rule,
                l_override_prot,
                p_versiondate,
                p_office_id);
   END store_ts;                                                    -- v1.4 --

   --
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS -
   --
   PROCEDURE store_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN tsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      TS_ID_NOT_FOUND       EXCEPTION;
      PRAGMA EXCEPTION_INIT (ts_id_not_found, -20001);
      l_timeseries_data     tsv_array;
      l_cwms_ts_id          VARCHAR2(183);
      l_office_id           VARCHAR2 (16);
      l_office_code         NUMBER;
      l_location_code       NUMBER;
      l_ucount              NUMBER;
      l_store_date          TIMESTAMP (3) DEFAULT SYSTIMESTAMP AT TIME ZONE 'UTC';
      l_ts_code             NUMBER;
      l_interval_id         cwms_interval.interval_id%TYPE;
      l_interval_value      NUMBER;
      l_utc_offset          NUMBER;
      existing_utc_offset   NUMBER;
      mindate               DATE;
      maxdate               DATE;
      l_sql_txt             VARCHAR2 (10000);
      l_override_prot       BOOLEAN;
      l_version_date        DATE;
      --
      l_units               VARCHAR2 (16);
      l_base_parameter_id   VARCHAR2 (16);
      l_base_parameter_code NUMBER(10);
      l_base_unit_id        VARCHAR2 (16);
      --
      l_first_time          DATE;
      l_last_time           DATE;
      l_msg                 SYS.aq$_jms_map_message;
      l_msgid               PLS_INTEGER;
      i                     INTEGER;
      l_millis              NUMBER (14) := cwms_util.to_millis (l_store_date);
      idx                   NUMBER := 0;
      i_max_iterations      NUMBER := 100;
      --
      l_date_times          date_table_type;
      l_min_interval        number;
      l_count               number;
      l_value_offset        binary_double := 0;
   --
      function bitor (num1 in integer, num2 in integer)
         return integer
      is
      begin
         return num1 + num2 - bitand (num1, num2);
      end;
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('cwms_ts_store.store_ts',
                                        'get tscode from ts_id');
      cwms_apex.aa1 (
            TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI')
         || 'store_ts: '
         || p_cwms_ts_id);

      -- set default values, don't be fooled by NULL as an actual argument


      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;

         --
         IF l_office_id = 'UNK'
         THEN
            cwms_err.RAISE ('INVALID_OFFICE_ID', 'Unkown');
         END IF;
      --
      ELSE
         l_office_id := cwms_util.strip(p_office_id);
      END IF;
      l_office_code := CWMS_UTIL.GET_OFFICE_CODE (l_office_id);

      begin
         l_cwms_ts_id := clean_ts_id(p_cwms_ts_id);
         l_cwms_ts_id := get_cwms_ts_id(l_cwms_ts_id, l_office_id);
      exception
         when ts_id_not_found then
            null;
      end;

      l_version_date := trunc(NVL(p_version_date, cwms_util.non_versioned), 'mi');
      if l_version_date = cwms_util.all_version_dates then
         cwms_err.raise('ERROR', 'Cannot use CWMS_UTIL.ALL_VERSION_DATES for storing data.');
      end if;

      IF NVL (p_override_prot, 'F') = 'F'
      THEN
         l_override_prot := FALSE;
      ELSE
         l_override_prot := TRUE;
      END IF;

      BEGIN
         SELECT i.interval
           INTO l_interval_value
           FROM cwms_interval i
          WHERE UPPER (i.interval_id) = UPPER (regexp_substr (l_cwms_ts_id, '[^.]+', 1, 4));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise('INVALID_INTERVAL_ID', regexp_substr (l_cwms_ts_id, '[^.]+', 1, 4));
      END;

      begin
         select base_parameter_code,
                base_parameter_id
           into l_base_parameter_code,
                l_base_parameter_id
           from cwms_base_parameter
          where upper(base_parameter_id) = upper(cwms_util.get_base_id(regexp_substr (l_cwms_ts_id, '[^.]+', 1, 2)));
      exception
         when no_data_found then
            cwms_err.raise('INVALID_PARAM_ID', regexp_substr (l_cwms_ts_id, '[^.]+', 1, 2));
      end;
      if l_base_parameter_code < 0 then
         cwms_err.raise('ERROR', 'Cannot store values to time series with parameter "'||regexp_substr (l_cwms_ts_id, '[^.]+', 1, 2)||'"');
      end if;

      DBMS_APPLICATION_INFO.set_action (
         'Find or create a TS_CODE for your TS Desc');

      BEGIN                                        -- BEGIN - Find the TS_CODE
         l_ts_code :=
            get_ts_code (p_cwms_ts_id       => l_cwms_ts_id,
                         p_db_office_code   => l_office_code);

         SELECT interval_utc_offset
           INTO existing_utc_offset
           FROM at_cwms_ts_spec
          WHERE ts_code = l_ts_code;
      EXCEPTION
         WHEN TS_ID_NOT_FOUND
         THEN
            /*
            Exception is thrown when the Time Series Description passed
            does not exist in the database for the office_id. If this is
            the case a new TS_CODE will be created for the Time Series
            Descriptor.
            */
            create_ts_code (p_ts_code      => l_ts_code,
                            p_office_id    => l_office_id,
                            p_cwms_ts_id   => l_cwms_ts_id,
                            p_utc_offset   => cwms_util.UTC_OFFSET_UNDEFINED);

            existing_utc_offset := cwms_util.UTC_OFFSET_UNDEFINED;
      END;                                               -- END - Find TS_CODE

      IF l_ts_code IS NULL
      THEN
         raise_application_error (
            -20105,
            'Unable to create or locate ts_code for ' || l_cwms_ts_id,
            TRUE);
      END IF;


      if p_timeseries_data.count = 0 then
         dbms_application_info.set_action ('Returning due to no data provided');
         return;      -- have already created ts_code if it didn't exist
      end if;

      DBMS_APPLICATION_INFO.set_action ('Check for nulls in incoming data');

      l_timeseries_data := tsv_array();
      case get_nulls_storage_policy(l_ts_code)
         when set_null_values_to_missing then
            l_timeseries_data := p_timeseries_data;
            for i in 1..l_timeseries_data.count loop
               if l_timeseries_data(i).value is null then
                  l_timeseries_data(i).quality_code := bitor(l_timeseries_data(i).quality_code, 5);
               end if;
            end loop;
         when reject_ts_with_null_values then
            for i in 1..p_timeseries_data.count loop
               if p_timeseries_data(i).value is null and not cwms_ts.quality_is_missing(p_timeseries_data(i).quality_code) then
                  cwms_err.raise('ERROR', 'Incoming data contains null values with non-missing quality.');
               end if;
            end loop;
            l_timeseries_data := p_timeseries_data;
         else -- filter_out_null_values or unset
            for i in 1..p_timeseries_data.count loop
               if p_timeseries_data(i).value is not null or cwms_ts.quality_is_missing(p_timeseries_data(i).quality_code) then
                  l_timeseries_data.extend;
                  l_timeseries_data(l_timeseries_data.count) := p_timeseries_data(i);
               end if;
            end loop;
      end case;

      if l_timeseries_data.count = 0 then
         dbms_application_info.set_action ('Returning due to no data passed null filter');
         return;      -- have already created ts_code if it didn't exist
      end if;


      DBMS_APPLICATION_INFO.set_action (
         'Truncate incoming times to minute and verify validity');
      ---------------------------------------------------------
      -- get the times as date types truncated to the minute --
      ---------------------------------------------------------
      select trunc(cast(date_time at time zone 'UTC' as date), 'mi')
        bulk collect into l_date_times
        from table(l_timeseries_data)
       order by date_time;

      select min(interval)
        into l_min_interval
        from (select column_value - lag(column_value, 1, null) over (order by column_value) as interval
                from table(l_date_times));

      if l_min_interval = 0 then
         cwms_err.raise('ERROR', 'Incoming data has multiple values for same minute.');
      end if;

      IF l_interval_value > 0
      THEN
         DBMS_APPLICATION_INFO.set_action (
            'Incoming data set has a regular interval, confirm data set matches interval_id');

         -----------------------------
         -- test for irregular data --
         -----------------------------
         begin
            select distinct get_utc_interval_offset(column_value, l_interval_value)
              into l_utc_offset
              from table(l_date_times);
         exception
            when too_many_rows then
               raise_application_error (
                  -20110,
                  'ERROR: Incoming data set appears to contain irregular data. Unable to store data for '
                  || l_cwms_ts_id,
                  TRUE);
         end;
         if existing_utc_offset = cwms_util.utc_offset_undefined then
            --------------------
            -- set the offset --
            --------------------
            update at_cwms_ts_spec
               set interval_utc_offset = l_utc_offset
             where ts_code = l_ts_code;
         else
            -----------------------------
            -- test for invalid offset --
            -----------------------------
            if get_utc_interval_offset(l_date_times(1), l_interval_value) != existing_utc_offset then
               raise_application_error (
                  -20101,
                  'Incoming Data Set''s UTC_OFFSET: '
                  || l_utc_offset
                  || ' does not match its previously stored UTC_OFFSET of: '
                  || existing_utc_offset
                  || ' - data set was NOT stored',
                  TRUE);
            end if;
         end if;


      ELSE
         DBMS_APPLICATION_INFO.set_action ('Incoming data set is irregular');

         l_utc_offset := cwms_util.UTC_OFFSET_IRREGULAR;
      END IF;


      DBMS_APPLICATION_INFO.set_action (
         'getting vertical datum offset if parameter is elevation');

      l_units := cwms_util.get_unit_id(p_units, l_office_id);
      if l_units is null then l_units := p_units; end if;
      if l_base_parameter_id = 'Elev' then
         l_location_code := cwms_loc.get_location_code(l_office_code, cwms_Util.split_text(l_cwms_ts_id, 1, '.', 1));
         l_value_offset  := cwms_loc.get_vertical_datum_offset(l_location_code, l_units);
      end if;

      DBMS_APPLICATION_INFO.set_action (
         'check p_units is a valid unit for this parameter');

      SELECT a.base_parameter_id
        INTO l_base_parameter_id
        FROM cwms_base_parameter a, at_parameter b, at_cwms_ts_spec c
       WHERE     A.BASE_PARAMETER_CODE = B.BASE_PARAMETER_CODE
             AND B.PARAMETER_CODE = C.PARAMETER_CODE
             AND c.ts_code = l_ts_code;

      l_units := cwms_util.get_valid_unit_id (l_units, l_base_parameter_id);

      DBMS_APPLICATION_INFO.set_action ('check for unit conversion factors');


      SELECT COUNT (*)
        INTO l_ucount
        FROM at_cwms_ts_spec s,
             at_parameter ap,
             cwms_unit_conversion c,
             cwms_base_parameter p,
             cwms_unit u
       WHERE     s.ts_code = l_ts_code
             AND s.parameter_code = ap.parameter_code
             AND ap.base_parameter_code = p.base_parameter_code
             AND p.unit_code = c.from_unit_code
             AND c.to_unit_code = u.unit_code
             AND u.unit_id = l_units;


      IF l_ucount <> 1
      THEN
         SELECT unit_id
           INTO l_base_unit_id
           FROM cwms_unit a, cwms_base_parameter b
          WHERE     A.UNIT_CODE = B.UNIT_CODE
                AND B.BASE_PARAMETER_ID = l_base_parameter_id;

         raise_application_error (
            -20103,
               'Unit conversion from '
            || l_units
            || ' to the CWMS Database Base Units of '
            || l_base_unit_id
            || ' is not available for the '
            || l_base_parameter_id
            || ' parameter_id.',
            TRUE);
      END IF;

      --
      -- Determine the min and max date in the dataset, convert
      -- the min and max dates to GMT dates.
      -- The min and max dates are used to determine which
      -- at_tsv tables need to be accessed during the store.
      --

      SELECT MIN (trunc(CAST ( (t.date_time AT TIME ZONE 'UTC') AS DATE), 'mi')),
             MAX (trunc(CAST ( (t.date_time AT TIME ZONE 'UTC') AS DATE), 'mi'))
        INTO mindate, maxdate
        FROM TABLE (CAST (l_timeseries_data AS tsv_array)) t;

      DBMS_OUTPUT.put_line (
            '*****************************'
         || CHR (10)
         || 'IN STORE_TS'
         || CHR (10)
         || 'TS Description: '
         || l_cwms_ts_id
         || CHR (10)
         || '       TS CODE: '
         || l_ts_code
         || CHR (10)
         || '    Store Rule: '
         || p_store_rule
         || CHR (10)
         || '      Override: '
         || p_override_prot
         || CHR (10)
         || '*****************************');

      /*
     A WHILE LOOP was added to catch primary key violations when multiple
     threads are simultaneously processing data for the same ts code and
     the data blocks have overlapping time windows. The loop allows
     repeated attempts to store the data block, with the hope that the
     initial data block that successfully stored data for the overlapping
     date/times has finally completed and COMMITed the inserts. If after
     i_max_iterations, the dup_value_on_index exception is still being
     thrown, then the loop ends and the dup_value_on_index exception is
     raised one last time.
     */
      WHILE idx < i_max_iterations
      LOOP
         BEGIN
      CASE
         WHEN     l_override_prot
              AND UPPER (p_store_rule) = cwms_util.replace_all
         THEN
            --
            --**********************************
            -- CASE 1 - Store Rule: REPLACE ALL
            --          Override:   TRUE
            --**********************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'merge into table, override, replace_all ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               l_sql_txt :=
                     'merge into ' || x.table_name || ' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                     and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)';
               cwms_util.check_dynamic_sql(l_sql_txt);

               EXECUTE IMMEDIATE l_sql_txt
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_ts_code,
                        l_store_date,
                        l_version_date;
            END LOOP;
         WHEN     NOT l_override_prot
              AND UPPER (p_store_rule) = cwms_util.replace_all
         THEN
            --
            --*************************************
            -- CASE 2 - Store Rule: REPLACE ALL -
            --         Override:   FALSE -
            --*************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'CASE 2: merge into  table, no override, replace_all ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               l_sql_txt :=
                     'merge into ' || x.table_name || ' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset)  - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                     and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                                 where (t1.quality_code in (select quality_code
                                                              from cwms_data_quality q
                                                             where q.protection_id = ''UNPROTECTED''))
                                    or (t2.quality_code in (select quality_code
                                                              from cwms_data_quality q
                                                             where q.protection_id = ''PROTECTED''))
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)';
               cwms_util.check_dynamic_sql(l_sql_txt);
               EXECUTE IMMEDIATE l_sql_txt
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_ts_code,
                        l_store_date,
                        l_version_date;
            END LOOP;
         WHEN UPPER (p_store_rule) = cwms_util.do_not_replace
         THEN
            --
            --*************************************
            -- CASE 3 - Store Rule: DO NOT REPLACE
            --*************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'merge into table, do_not_replace ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               l_sql_txt :=
                     'merge into ' || x.table_name || ' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                     and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)';
               cwms_util.check_dynamic_sql(l_sql_txt);

               EXECUTE IMMEDIATE l_sql_txt
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_ts_code,
                        l_store_date,
                        l_version_date;
            END LOOP;
               WHEN UPPER (p_store_rule) =
                       cwms_util.replace_missing_values_only
         THEN
            --
            --***************************************************
            -- CASE 4 - Store Rule: REPLACE MISSING VALUES ONLY -
            --***************************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'merge into table, replace_missing_values_only');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               if not l_override_prot then
                  --
                  --***************************************************
                  -- CASE 4a - Store Rule: REPLACE MISSING VALUES ONLY -
                  --           Override:   FALSE
                  --***************************************************
                  --
                  l_sql_txt :=
                        'merge into ' || x.table_name || ' t1
                              using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                            (t.value * c.factor + c.offset) - :l_value_offset value,
                                            cwms_ts.clean_quality_code(t.quality_code) quality_code
                                       from table(cast(:l_timeseries_data as tsv_array)) t,
                                            at_cwms_ts_spec s,
                                            at_parameter ap,
                                            cwms_unit_conversion c,
                                            cwms_base_parameter p,
                                            cwms_unit u
                                      where cwms_util.is_nan(t.value) = ''F''
                                        and s.ts_code = :l_ts_code
                                        and s.parameter_code = ap.parameter_code
                                        and ap.base_parameter_code = p.base_parameter_code
                                        and p.unit_code = c.to_unit_code
                                        and c.from_unit_code = u.unit_code
                                        and u.unit_id = :l_units
                                        and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                        and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                                 on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                         when matched then
                            update set t1.value = t2.value, t1.quality_code = t2.quality_code, t1.data_entry_date = :l_store_date
                                    where t1.quality_code in (select quality_code
                                                                from cwms_data_quality q
                                                               where q.validity_id = ''MISSING'')
                                      and ((t1.quality_code in (select quality_code
                                                                  from cwms_data_quality q
                                                                 where q.protection_id = ''UNPROTECTED''))
                                        or (t2.quality_code in (select quality_code
                                                                  from cwms_data_quality q
                                                                 where q.protection_id = ''PROTECTED'')))
                         when not matched then
                            insert     (  ts_code,
                                          date_time,
                                          data_entry_date,
                                          value,
                                          quality_code,
                                          version_date)
                                values (  :l_ts_code,
                                          t2.date_time,
                                          :l_store_date,
                                          t2.value,
                                          t2.quality_code,
                                          :l_version_date)';
               else
                  --
                  --***************************************************
                  -- CASE 4b - Store Rule: REPLACE MISSING VALUES ONLY -
                  --           Override:   TRUE
                  --***************************************************
                  --
                  l_sql_txt :=
                        'merge into ' || x.table_name || ' t1
                              using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                            (t.value * c.factor + c.offset) - :l_value_offset value,
                                            cwms_ts.clean_quality_code(t.quality_code) quality_code
                                       from table(cast(:l_timeseries_data as tsv_array)) t,
                                            at_cwms_ts_spec s,
                                            at_parameter ap,
                                            cwms_unit_conversion c,
                                            cwms_base_parameter p,
                                            cwms_unit u
                                      where cwms_util.is_nan(t.value) = ''F''
                                        and s.ts_code = :l_ts_code
                                        and s.parameter_code = ap.parameter_code
                                        and ap.base_parameter_code = p.base_parameter_code
                                        and p.unit_code = c.to_unit_code
                                        and c.from_unit_code = u.unit_code
                                        and u.unit_id = :l_units
                                        and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                        and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                                 on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                         when matched then
                            update set t1.value = t2.value, t1.quality_code = t2.quality_code, t1.data_entry_date = :l_store_date
                                    where t1.quality_code in (select quality_code
                                                                from cwms_data_quality q
                                                               where q.validity_id = ''MISSING'')
                         when not matched then
                            insert     (  ts_code,
                                          date_time,
                                          data_entry_date,
                                          value,
                                          quality_code,
                                          version_date)
                                values (  :l_ts_code,
                                          t2.date_time,
                                          :l_store_date,
                                          t2.value,
                                          t2.quality_code,
                                          :l_version_date)';
               end if;
               cwms_util.check_dynamic_sql(l_sql_txt);

               EXECUTE IMMEDIATE l_sql_txt
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_ts_code,
                        l_store_date,
                        l_version_date;
            END LOOP;
         WHEN     l_override_prot
                    AND UPPER (p_store_rule) =
                           cwms_util.replace_with_non_missing
         THEN
            --
            --*******************************************
            -- CASE 5 - Store Rule: REPLACE W/NON-MISSING -
            --         Override:   TRUE -
            --*******************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'merge into table, override, replace_with_non_missing ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               l_sql_txt :=
                     'merge into ' || x.table_name || ' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u,
                                         cwms_data_quality q
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and t.value is not null
                                     and cwms_ts.quality_is_missing_text(t.quality_code) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and q.quality_code = t.quality_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                     and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                                 where t2.quality_code not in (select quality_code
                                                                 from cwms_data_quality
                                                                where validity_id = ''MISSING'')
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)';
               cwms_util.check_dynamic_sql(l_sql_txt);

               EXECUTE IMMEDIATE l_sql_txt
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_ts_code,
                        l_store_date,
                        l_version_date;
            END LOOP;
         WHEN     NOT l_override_prot
                    AND UPPER (p_store_rule) =
                           cwms_util.replace_with_non_missing
         THEN
            --
            --*******************************************
            -- Case 6 - Store Rule: Replace w/Non-Missing -
            --         Override:   FALSE -
            --*******************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'merge into table, no override, replace_with_non_missing ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               l_sql_txt :=
                     'merge into ' || x.table_name || ' t1
                           using (select trunc(cast((cwms_util.fixup_timezone(t.date_time) at time zone ''GMT'') as date), ''mi'') date_time,
                                         (t.value * c.factor + c.offset) - :l_value_offset value,
                                         cwms_ts.clean_quality_code(t.quality_code) quality_code
                                    from table(cast(:l_timeseries_data as tsv_array)) t,
                                         at_cwms_ts_spec s,
                                         at_parameter ap,
                                         cwms_unit_conversion c,
                                         cwms_base_parameter p,
                                         cwms_unit u,
                                         cwms_data_quality q
                                   where cwms_util.is_nan(t.value) = ''F''
                                     and t.value is not null
                                     and cwms_ts.quality_is_missing_text(t.quality_code) = ''F''
                                     and s.ts_code = :l_ts_code
                                     and s.parameter_code = ap.parameter_code
                                     and ap.base_parameter_code = p.base_parameter_code
                                     and q.quality_code = t.quality_code
                                     and p.unit_code = c.to_unit_code
                                     and c.from_unit_code = u.unit_code
                                     and u.unit_id = :l_units
                                     and date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                                     and date_time < from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                              on (t1.ts_code = :l_ts_code and t1.date_time = t2.date_time and t1.version_date = :l_version_date)
                      when matched then
                         update set t1.value = t2.value, t1.data_entry_date = :l_store_date, t1.quality_code = t2.quality_code
                                 where ((t1.quality_code in (select quality_code
                                                               from cwms_data_quality q
                                                              where q.protection_id = ''UNPROTECTED''))
                                     or (t2.quality_code in (select quality_code
                                                               from cwms_data_quality q
                                                              where q.protection_id = ''PROTECTED'')))
                                   and (t2.quality_code not in (select quality_code
                                                                  from cwms_data_quality q
                                                                 where q.validity_id = ''MISSING''))
                      when not matched then
                         insert     (  ts_code,
                                       date_time,
                                       data_entry_date,
                                       value,
                                       quality_code,
                                       version_date)
                             values (  :l_ts_code,
                                       t2.date_time,
                                       :l_store_date,
                                       t2.value,
                                       t2.quality_code,
                                       :l_version_date)';
               cwms_util.check_dynamic_sql(l_sql_txt);
               EXECUTE IMMEDIATE l_sql_txt
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_ts_code,
                        l_store_date,
                        l_version_date;
            END LOOP;
         WHEN     NOT l_override_prot
              AND UPPER (p_store_rule) = cwms_util.delete_insert
         THEN
            --
            --*************************************
            -- CASE 7 - Store Rule: DELETE - INSERT -
            --         Override:   FALSE -
            --*************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'delete/merge from table, no override, delete_insert ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               EXECUTE IMMEDIATE REPLACE (
                  'insert
                     into at_ts_deleted_times
                   select :millis,
                          :ts_code,
                          :version_date,
                          t1.date_time
                     from table_name t1
                    where t1.ts_code = :ts_code
                      and t1.version_date = :version_date
                      and t1.date_time between
                          (SELECT MIN (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)
                          and
                          (SELECT MAX (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)
                      and t1.quality_code NOT IN (SELECT quality_code
                                                   FROM cwms_data_quality q
                                                  WHERE q.protection_id = ''PROTECTED'')',
                                   'table_name',
                                   x.table_name)
                  USING l_millis,
                        l_ts_code,
                        l_version_date,
                        l_ts_code,
                        l_version_date,
                        p_timeseries_data, -- get the ENTIRE time window of incoming data, even if it was trimmed by filtering NULLs
                        p_timeseries_data;

               EXECUTE IMMEDIATE REPLACE (
                  'delete
                     from table_name t1
                    where t1.ts_code = :ts_code
                      and t1.version_date = :version_date
                      and t1.date_time between
                          (SELECT MIN (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)
                          and
                          (SELECT MAX (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)
                      and t1.quality_code NOT IN (SELECT quality_code
                                                   FROM cwms_data_quality q
                                                  WHERE q.protection_id = ''PROTECTED'')',
                                   'table_name',
                                   x.table_name)
                  USING l_ts_code,
                        l_version_date,
                        p_timeseries_data, -- get the ENTIRE time window of incoming data, even if it was trimmed by filtering NULLs
                        p_timeseries_data;

               EXECUTE IMMEDIATE REPLACE (
                  'MERGE INTO table_name t1
                     USING (SELECT trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi'') as date_time,
                                   (t.value * c.factor + c.offset) - :l_value_offset as value,
                                   cwms_ts.clean_quality_code(t.quality_code) as quality_code
                              FROM TABLE (CAST (:timeseries_data AS tsv_array)) t,
                                   at_cwms_ts_spec s,
                                   at_parameter ap,
                                   cwms_unit_conversion c,
                                   cwms_base_parameter p,
                                   cwms_unit u
                             WHERE cwms_util.is_nan(t.value) = ''F''
                               AND s.ts_code = :ts_code
                               AND s.parameter_code = ap.parameter_code
                               AND ap.base_parameter_code = p.base_parameter_code
                               AND p.unit_code = c.to_unit_code
                               AND c.from_unit_code = u.unit_code
                               AND u.unit_id = :units
                               AND date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                               AND date_time <  from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                     ON (    t1.ts_code = :ts_code
                         AND t1.date_time = t2.date_time
                         AND t1.version_date = :version_date)
                     WHEN NOT MATCHED THEN
                        INSERT (ts_code, date_time, version_date, data_entry_date, value, quality_code)
                        VALUES (:ts_code, t2.date_time, :version_date, :store_date, t2.value, t2.quality_code)
                     WHEN MATCHED THEN
                        UPDATE
                           SET t1.VALUE = t2.VALUE,
                               t1.quality_code = t2.quality_code,
                               t1.data_entry_date = :store_date
                         WHERE ( (  t1.value != t2.value
                                    OR
                                    t1.quality_code != t2.quality_code
                                 )
                                 AND
                                 (  t1.quality_code NOT IN (SELECT quality_code
                                                              FROM cwms_data_quality q
                                                             WHERE q.protection_id = ''PROTECTED'')
                                    OR
                                    t2.quality_code IN (SELECT quality_code
                                                          FROM cwms_data_quality q
                                                         WHERE q.protection_id = ''PROTECTED'')
                                 )
                               )',
                                   'table_name',
                                   x.table_name)
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_store_date;
            END LOOP;
         WHEN     l_override_prot
              AND UPPER (p_store_rule) = cwms_util.delete_insert
         THEN
            --
            --*************************************
            --CASE 8 - Store Rule: DELETE - INSERT -
            --         Override:   TRUE -
            --*************************************
            --
            DBMS_APPLICATION_INFO.set_action (
               'delete/merge from  table, override, delete_insert ');

                  FOR x
                     IN (SELECT start_date, end_date, table_name
                        FROM at_ts_table_properties
                       WHERE start_date <= maxdate AND end_date > mindate)
            LOOP
               EXECUTE IMMEDIATE REPLACE (
                  'insert
                     into at_ts_deleted_times
                   select :millis,
                          :ts_code,
                          :version_date,
                          t1.date_time
                     from table_name t1
                    where t1.ts_code = :ts_code
                      and t1.version_date = :version_date
                      and t1.date_time between
                          (SELECT MIN (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)
                          and
                          (SELECT MAX (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)',
                                   'table_name',
                                   x.table_name)
                  USING l_millis,
                        l_ts_code,
                        l_version_date,
                        l_ts_code,
                        l_version_date,
                        p_timeseries_data, -- get the ENTIRE time window of incoming data, even if it was trimmed by filtering NULLs
                        p_timeseries_data;

               EXECUTE IMMEDIATE REPLACE (
                  'delete
                     from table_name t1
                    where t1.ts_code = :ts_code
                      and t1.version_date = :version_date
                      and t1.date_time between
                          (SELECT MIN (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)
                          and
                          (SELECT MAX (trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi''))
                             FROM TABLE (CAST (:timeseries_data AS tsv_array)) t)',
                                   'table_name',
                                   x.table_name)
                  USING l_ts_code,
                        l_version_date,
                        p_timeseries_data, -- get the ENTIRE time window of incoming data, even if it was trimmed by filtering NULLs
                        p_timeseries_data;

               EXECUTE IMMEDIATE REPLACE (
                  'MERGE INTO table_name t1
                     USING (SELECT trunc(CAST ((cwms_util.fixup_timezone(t.date_time) AT TIME ZONE ''GMT'') AS DATE), ''mi'') as date_time,
                                   (t.value * c.factor + c.offset) - :l_value_offset as value,
                                   cwms_ts.clean_quality_code(t.quality_code) as quality_code
                              FROM TABLE (CAST (:timeseries_data AS tsv_array)) t,
                                   at_cwms_ts_spec s,
                                   at_parameter ap,
                                   cwms_unit_conversion c,
                                   cwms_base_parameter p,
                                   cwms_unit u
                             WHERE cwms_util.is_nan(t.value) = ''F''
                               AND s.ts_code = :ts_code
                               AND s.parameter_code = ap.parameter_code
                               AND ap.base_parameter_code = p.base_parameter_code
                               AND p.unit_code = c.to_unit_code
                               AND c.from_unit_code = u.unit_code
                               AND u.unit_id = :units
                               AND date_time >= from_tz(cast(:start_date as timestamp), ''UTC'')
                               AND date_time <  from_tz(cast(:end_date as timestamp), ''UTC'')) t2
                     ON (    t1.ts_code = :ts_code
                         AND t1.date_time = t2.date_time
                         AND t1.version_date = :version_date)
                     WHEN NOT MATCHED THEN
                        INSERT (ts_code, date_time, version_date, data_entry_date, value, quality_code)
                        VALUES (:ts_code, t2.date_time, :version_date, :store_date, t2.value, t2.quality_code)
                     WHEN MATCHED THEN
                        UPDATE
                           SET t1.VALUE = t2.VALUE,
                               t1.quality_code = t2.quality_code,
                               t1.data_entry_date = :store_date
                         WHERE ( t1.value != t2.value
                                 OR
                                 t1.quality_code != t2.quality_code
                               )',
                                   'table_name',
                                   x.table_name)
                  USING l_value_offset,
                        l_timeseries_data,
                        l_ts_code,
                        l_units,
                        x.start_date,
                        x.end_date,
                        l_ts_code,
                        l_version_date,
                        l_ts_code,
                        l_version_date,
                        l_store_date,
                        l_store_date;
            END LOOP;
                  DBMS_OUTPUT.put_line (
                     'CASE 7: delete-insert FALSE Completed.');
         ELSE
            cwms_err.raise ('INVALID_STORE_RULE',
                            NVL (p_store_rule, '<NULL>'));
      END CASE;

            idx := i_max_iterations;
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               idx := idx + 1;

               IF idx >= i_max_iterations
               THEN
                  RAISE DUP_VAL_ON_INDEX;
               ELSE
                  DBMS_LOCK.sleep (0.02);
               END IF;
         END;
      END LOOP;

      ---------------------------------
      -- archive and publish message --
      ---------------------------------
      declare
         l_first_time timestamp with time zone;
         l_last_time  timestamp with time zone;
      begin
         select min(date_time)
           into l_first_time
           from table(l_timeseries_data);
         select max(date_time)
           into l_last_time
           from table(l_timeseries_data);
         time_series_updated (
            l_ts_code,
            l_cwms_ts_id,
            l_office_id,
            l_first_time,
            l_last_time,
            FROM_TZ (CAST (l_version_date AS TIMESTAMP), 'UTC'),
            l_store_date,
            upper(p_store_rule));
      end;


      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         CWMS_MSG.LOG_DB_MESSAGE (
            'store_ts',
            1,
               'STORE_TS ERROR ***'
            || l_cwms_ts_id
            || '*** '
            || SQLCODE
            || ': '
            || SQLERRM);

         cwms_err.raise ('ERROR', DBMS_UTILITY.format_error_backtrace);
   END store_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS - This version is for Python/CxOracle
   --
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units           IN VARCHAR2,
      p_times           IN number_array,
      p_values          IN double_array,
      p_qualities       IN number_array,
      p_store_rule      IN VARCHAR2,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries_data   tsv_array := tsv_array ();
      i                   BINARY_INTEGER;
   BEGIN
      IF p_values.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR', 'Inconsistent number of times and values.');
      END IF;

      IF p_qualities.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR',
                         'Inconsistent number of times and qualities.');
      END IF;

      l_timeseries_data.EXTEND (p_times.COUNT);

      FOR i IN 1 .. p_times.COUNT
      LOOP
         l_timeseries_data (i) :=
            tsv_type (FROM_TZ (cwms_util.TO_TIMESTAMP (p_times (i)), 'UTC'),
                      p_values (i),
                      p_qualities (i));
      END LOOP;

      store_ts (p_cwms_ts_id,
                p_units,
                l_timeseries_data,
                p_store_rule,
                p_override_prot,
                p_version_date,
                p_office_id);
   END store_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS - This version is for Java/Jython bypassing TIMESTAMPTZ type
   --
   PROCEDURE store_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_units           IN VARCHAR2,
      p_times           IN number_tab_t,
      p_values          IN number_tab_t,
      p_qualities       IN number_tab_t,
      p_store_rule      IN VARCHAR2,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries_data   tsv_array := tsv_array ();
      i                   BINARY_INTEGER;
   BEGIN
      IF p_values.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR', 'Inconsistent number of times and values.');
      END IF;

      IF p_qualities.COUNT != p_times.COUNT
      THEN
         cwms_err.raise ('ERROR',
                         'Inconsistent number of times and qualities.');
      END IF;

      l_timeseries_data.EXTEND (p_times.COUNT);

      FOR i IN 1 .. p_times.COUNT
      LOOP
         l_timeseries_data (i) :=
            tsv_type (FROM_TZ (cwms_util.TO_TIMESTAMP (p_times (i)), 'UTC'),
                      p_values (i),
                      p_qualities (i));
      END LOOP;

      store_ts (p_cwms_ts_id,
                p_units,
                l_timeseries_data,
                p_store_rule,
                p_override_prot,
                p_version_date,
                p_office_id);
   END store_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS_MULTI -
   --
   procedure store_ts_multi (
      p_timeseries_array   in timeseries_array,
      p_store_rule         in varchar2,
      p_override_prot      in varchar2 default 'F',
      p_version_dates      in date_table_type default null,
      p_office_id          in varchar2 default null)
   is
      l_err_msg        varchar2 (722)  := null;
      l_all_err_msgs   varchar2 (2048) := null;
      l_version_dates  date_table_type := date_table_type();
      l_len            pls_integer := 0;
      l_total_len      pls_integer := 0;
      l_num_ts_ids     pls_integer := 0;
      l_num_errors     pls_integer := 0;
      l_excep_errors   pls_integer := 0;
   begin

      if p_timeseries_array is not null then
         dbms_application_info.set_module (
            'cwms_ts_store.store_ts_multi',
            'processing parameters');
         if p_version_dates is not null and p_version_dates.count != p_timeseries_array.count then
            cwms_err.raise(
               'ERROR',
               'Counts of time series and version dates don''t match.');
         end if;
         l_version_dates.extend(p_timeseries_array.count);
         for i in 1..l_version_dates.count loop
            if p_version_dates is null or p_version_dates(i) is null then
               l_version_dates(i) := cwms_util.non_versioned;
            else
               l_version_dates(i) := p_version_dates(i);
            end if;
         end loop;
         for i in 1..p_timeseries_array.count loop
            dbms_application_info.set_module (
               'cwms_ts_store.store_ts_multi',
               'calling store_ts');

            begin
               store_ts (p_timeseries_array(i).tsid,
                         p_timeseries_array(i).unit,
                         p_timeseries_array(i).data,
                         p_store_rule,
                         p_override_prot,
                         l_version_dates(i),
                         p_office_id);
            exception
               when others then
                  l_num_errors := l_num_errors + 1;

                  l_err_msg :=
                        'STORE_ERROR ***'
                     || p_timeseries_array(i).tsid
                     || '*** '
                     || sqlcode
                     || ': '
                     || sqlerrm;

                  if   nvl (length (l_all_err_msgs), 0)
                     + nvl (length (l_err_msg),      0) <= 1930
                  then
                     l_excep_errors := l_excep_errors + 1;
                     l_all_err_msgs := l_all_err_msgs || ' ' || l_err_msg;
                  end if;
            end;
         end loop;
      end if;

      if l_all_err_msgs is not null then
         l_all_err_msgs :=
               'STORE ERRORS: store_ts_multi processed '
            || l_num_ts_ids
            || ' ts_ids of which '
            || l_num_errors
            || ' had STORE ERRORS. '
            || l_excep_errors
            || ' of those errors are: '
            || l_all_err_msgs;

         raise_application_error (-20999, l_all_err_msgs);
      end if;


      dbms_application_info.set_module (null, null);
   end store_ts_multi;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS_MULTI -
   --
   procedure store_ts_multi (
      p_timeseries_array   in timeseries_array,
      p_store_rule         in varchar2,
      p_override_prot      in varchar2 default 'F',
      p_version_date       in date default cwms_util.non_versioned,
      p_office_id          in varchar2 default null)
   is
      l_version_dates date_table_type;
   begin
      if p_timeseries_array is not null then
         l_version_dates := date_table_type();
         l_version_dates.extend(p_timeseries_array.count);
         for i in 1..p_timeseries_array.count loop
            l_version_dates(i) := p_version_date;
         end loop;
         store_ts_multi(
            p_timeseries_array,
            p_store_rule,
            p_override_prot,
            l_version_dates,
            p_office_id);
      end if;
   end store_ts_multi;

   --
   --*******************************************************************   --
   --** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE **** PRIVATE ****   --
   --
   -- DELETE_TS_CLEANUP -
   --

   PROCEDURE delete_ts_cleanup (p_ts_code_old IN NUMBER)
   IS
   BEGIN
      -- NOTE TO GERHARD Need to think about cleaning up
      -- all of the dependancies when deleting.
      DELETE FROM at_shef_decode
            WHERE ts_code = p_ts_code_old;
   END delete_ts_cleanup;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- DELETE_TS -
   --
   ---------------------------------------------------------------------   --
   -- valid p_delete_actions:                                              --
   --  delete_ts_id:      This action will delete the cwms_ts_id only if there
   --                     is no actual data associated with this cwms_ts_id.
   --                     If there is data assciated with the cwms_ts_id, then
   --                     an exception is thrown.
   --  delete_ts_data:    This action will delete all of the data associated
   --                     with the cwms_ts_id. The cwms_ts_id is not deleted.
   --  delete_ts_cascade: This action will delete both the data and the
   --                     cwms_ts_id.
   ----------------------------------------------------------------------  --


   PROCEDURE delete_ts (
      p_cwms_ts_id      IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_ts_id,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_code   NUMBER := cwms_util.GET_OFFICE_CODE (p_db_office_id);
   BEGIN
      delete_ts (p_cwms_ts_id       => p_cwms_ts_id,
                 p_delete_action    => p_delete_action,
                 p_db_office_code   => l_db_office_code);
   END;

   procedure delete_ts(
      p_cwms_ts_id     in varchar2,
      p_delete_action  in varchar2,
      p_db_office_code in number)
   is
      l_db_office_code   number := p_db_office_code;
      l_db_office_id     varchar2(16);
      l_cwms_ts_id       varchar2(183);
      l_ts_code          number;
      l_count            number;
      l_value_count      number;
      l_std_text_count   number;
      l_text_count       number;
      l_binary_count     number;
      l_delete_action    varchar2(22) := upper(nvl(p_delete_action, cwms_util.delete_ts_id));
      l_delete_date      timestamp(9) := systimestamp;
      l_msg              sys.aq$_jms_map_message;
      l_msgid            pls_integer;
      i                  integer;
   begin
      if p_db_office_code is null then
         l_db_office_code := cwms_util.get_office_code(null);
      end if;

      select office_id
        into l_db_office_id
        from cwms_office
       where office_code = l_db_office_code;

      l_cwms_ts_id := get_cwms_ts_id(p_cwms_ts_id, l_db_office_id);

      begin
         select ts_code
           into l_ts_code
           from at_cwms_ts_id mcts
          where upper(mcts.cwms_ts_id) = upper(l_cwms_ts_id) and mcts.db_office_code = l_db_office_code;
      exception
         when no_data_found then
            begin
               select ts_code
                 into l_ts_code
                 from at_cwms_ts_id mcts
                where upper(mcts.cwms_ts_id) = upper(l_cwms_ts_id) and mcts.db_office_code = l_db_office_code;
            exception
               when no_data_found then
                  cwms_err.raise('TS_ID_NOT_FOUND', l_cwms_ts_id,cwms_util.get_db_office_id_from_code(p_db_office_code));
            end;
      end;

      ----------------------------------------------
      -- translate non-ts-specific delete_actions --
      ----------------------------------------------
      if l_delete_action = cwms_util.delete_key then
         l_delete_action := cwms_util.delete_ts_id;
      end if;

      if l_delete_action = cwms_util.delete_all then
         l_delete_action := cwms_util.delete_ts_cascade;
      end if;

      if l_delete_action = cwms_util.delete_data then
         l_delete_action := cwms_util.delete_ts_data;
      end if;

      case
         when l_delete_action = cwms_util.delete_ts_id then
            select count(*)
              into l_value_count
              from av_tsv
             where ts_code = l_ts_code;

            select count(*)
              into l_std_text_count
              from at_tsv_std_text
             where ts_code = l_ts_code;

            select count(*)
              into l_text_count
              from at_tsv_text
             where ts_code = l_ts_code;

            select count(*)
              into l_binary_count
              from at_tsv_binary
             where ts_code = l_ts_code;

            l_count := l_value_count + l_std_text_count + l_text_count + l_binary_count;

            if l_count = 0 then
               loop
                  begin
                     update at_cwms_ts_spec
                        set location_code = 0, delete_date = l_delete_date
                      where ts_code = l_ts_code;

                     exit;
                  exception
                     when others then
                        if sqlcode = -1 then
                           l_delete_date := systimestamp;
                        end if;
                  end;
               end loop;
            else
               cwms_err.raise('ERROR', 'cwms_ts_id: ' || p_cwms_ts_id || ' contains data. Cannot use the DELETE TS ID action');
            end if;
         when l_delete_action in (cwms_util.delete_ts_cascade, cwms_util.delete_ts_data) then
            -------------------------------
            -- delete data from database --
            -------------------------------
            for rec in (select table_name
                          from at_ts_table_properties
                         where start_date in (select distinct start_date
                                                from av_tsv
                                               where ts_code = l_ts_code)) loop
               execute immediate replace('delete from $t where ts_code = :1', '$t', rec.table_name) using l_ts_code;
            end loop;

            delete from at_tsv_std_text
                  where ts_code = l_ts_code;

            delete from at_tsv_text
                  where ts_code = l_ts_code;

            delete from at_tsv_binary
                  where ts_code = l_ts_code;

            if l_delete_action = cwms_util.delete_ts_cascade then
               ---------------------------------------
               -- delete location group assignments --
               ---------------------------------------
               delete
                 from at_ts_group_assignment
                where ts_code = l_ts_code
                   or ts_ref_code = l_ts_code;
               ------------------------------
               -- delete the timeseries id --
               ------------------------------
               update at_cwms_ts_spec
                  set location_code = 0, delete_date = l_delete_date
                where ts_code = l_ts_code;

               delete_ts_cleanup(l_ts_code);
            end if;

            commit;
         else
            cwms_err.raise('INVALID_DELETE_ACTION', p_delete_action);
      end case;

      if l_delete_action in (cwms_util.delete_ts_id, cwms_util.delete_ts_cascade) then
         -------------------------------
         -- publish TSDeleted message --
         -------------------------------
         cwms_msg.new_message(l_msg, l_msgid, 'TSDeleted');
         l_msg.set_string(l_msgid, 'ts_id', l_cwms_ts_id);
         l_msg.set_string(l_msgid, 'office_id', l_db_office_id);
         l_msg.set_long(l_msgid, 'ts_code', l_ts_code);
         i := cwms_msg.publish_message(l_msg, l_msgid, l_db_office_id || '_ts_stored');
      end if;
   end delete_ts;

   procedure delete_ts (
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
      p_db_office_id         in varchar2 default null)
   is
      l_ts_code    integer;
      l_start_time date;
      l_end_time   date;
      l_time_zone  varchar2(28);
      l_date_times date_table_type;
   begin
      l_ts_code := get_ts_code(p_cwms_ts_id, p_db_office_id);
      l_time_zone := cwms_util.get_timezone(nvl(p_time_zone, cwms_loc.get_local_timezone(cwms_util.split_text(p_cwms_ts_id, 1, '.'), p_db_office_id)));
      if p_date_times is not null then
         select cwms_util.change_timezone(column_value, l_time_zone, 'UTC')
           bulk collect
           into l_date_times
           from table(p_date_times);
      end if;
      if p_date_times is null then
         if cwms_util.is_true(p_start_time_inclusive) then
            l_start_time := p_start_time;
         else
            l_start_time := p_start_time + 1/86400;
         end if;
         if cwms_util.is_true(p_end_time_inclusive) then
            l_end_time := p_end_time;
         else
            l_end_time := p_end_time - 1/86400;
         end if;
      end if;
      purge_ts_data(
         l_ts_code,
         p_override_protection,
         case p_version_date = cwms_util.non_versioned
            when true then p_version_date
            else cwms_util.change_timezone(p_version_date, l_time_zone, 'UTC')
         end,
         cwms_util.change_timezone(l_start_time, l_time_zone, 'UTC'),
         cwms_util.change_timezone(l_end_time, l_time_zone, 'UTC'),
         l_date_times,
         p_max_version,
         p_ts_item_mask);
   end delete_ts;

   procedure delete_ts (
      p_timeseries_info      in timeseries_req_array,
      p_override_protection  in varchar2,
      p_start_time_inclusive in varchar2,
      p_end_time_inclusive   in varchar2,
      p_version_date         in date,
      p_time_zone            in varchar2 default null,
      p_max_version          in varchar2 default 'T',
      p_ts_item_mask         in integer default cwms_util.ts_all,
      p_db_office_id         in varchar2 default null)
   is
   begin
      if p_timeseries_info is not null then
         for i in 1..p_timeseries_info.count loop
            delete_ts(
                p_cwms_ts_id           => p_timeseries_info(i).tsid,
                p_override_protection  => p_override_protection,
                p_start_time           => p_timeseries_info(i).start_time,
                p_end_time             => p_timeseries_info(i).end_time,
                p_start_time_inclusive => p_start_time_inclusive,
                p_end_time_inclusive   => p_end_time_inclusive,
                p_version_date         => p_version_date,
                p_time_zone            => p_time_zone,
                p_date_times           => null,
                p_max_version          => p_max_version,
                p_ts_item_mask         => p_ts_item_mask,
                p_db_office_id         => p_db_office_id);
         end loop;
      end if;
   end delete_ts;

   procedure purge_ts_data(
      p_ts_code          in number,
      p_version_date_utc in date,
      p_start_time_utc   in date,
      p_end_time_utc     in date,
      p_date_times_utc   in date_table_type default null,
      p_max_version      in varchar2 default 'T',
      p_ts_item_mask     in integer default cwms_util.ts_all)
   is
   begin
      purge_ts_data(
         p_ts_code,
         'ERROR',
         p_version_date_utc,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_max_version,
         p_ts_item_mask);
   end purge_ts_data;

   procedure purge_ts_data(
      p_ts_code             in number,
      p_override_protection in varchar2,
      p_version_date_utc    in date,
      p_start_time_utc      in date,
      p_end_time_utc        in date,
      p_date_times_utc      in date_table_type default null,
      p_max_version         in varchar2 default 'T',
      p_ts_item_mask        in integer default cwms_util.ts_all)
   is
      l_tsid                     varchar2(183);
      l_office_id                varchar2(16);
      l_override_protection      boolean;
      l_error_on_protection      boolean;
      l_deleted_time             timestamp := systimestamp at time zone 'UTC';
      l_msg                      sys.aq$_jms_map_message;
      l_msgid                    pls_integer;
      i                          integer;
      l_protected_count          integer;
      l_max_version              boolean;
      l_date_times_values        date_table_type := date_table_type();
      l_version_dates_values     date_table_type := date_table_type();
      l_date_times_std_text      date_table_type := date_table_type();
      l_version_dates_std_text   date_table_type := date_table_type();
      l_date_times_text          date_table_type := date_table_type();
      l_version_dates_text       date_table_type := date_table_type();
      l_date_times_binary        date_table_type := date_table_type();
      l_version_dates_binary     date_table_type := date_table_type();
      l_times_values             date2_tab_t := date2_tab_t();
      l_times_std_text           date2_tab_t := date2_tab_t();
      l_times_text               date2_tab_t := date2_tab_t();
      l_times_binary             date2_tab_t := date2_tab_t();
      l_cursor                   sys_refcursor;
   begin
      l_max_version := cwms_util.return_true_or_false(p_max_version);
      if instr('ERROR', upper(trim(p_override_protection))) = 1 then
         l_override_protection := false;
         l_error_on_protection := true;
      else
         l_override_protection := cwms_util.return_true_or_false(p_override_protection);
         l_error_on_protection := false;
      end if;

      --------------------------------------------------------------------
      -- get the date_times and version_dates of all the items to purge --
      --------------------------------------------------------------------
      if bitand(p_ts_item_mask, cwms_util.ts_values) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_values);

         fetch l_cursor
         bulk collect into l_date_times_values, l_version_dates_values;
         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_std_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_std_text);

         fetch l_cursor
         bulk collect into l_date_times_std_text, l_version_dates_std_text;
         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_text);

         fetch l_cursor
         bulk collect into l_date_times_text, l_version_dates_text;
         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_binary) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_version_date_utc,
               l_max_version,
               cwms_util.ts_binary);

         fetch l_cursor
         bulk collect into l_date_times_binary, l_version_dates_binary;
         close l_cursor;
      end if;

      -------------------------------------------------
      -- collect the times into queryable structures --
      -------------------------------------------------
      l_times_values.extend(l_date_times_values.count);

      for i in 1 .. l_date_times_values.count loop
         l_times_values(i) := date2_t(l_date_times_values(i), l_version_dates_values(i));
      end loop;

      l_times_std_text.extend(l_date_times_std_text.count);

      for i in 1 .. l_date_times_std_text.count loop
         l_times_std_text(i) := date2_t(l_date_times_std_text(i), l_version_dates_std_text(i));
      end loop;

      l_times_text.extend(l_date_times_text.count);

      for i in 1 .. l_date_times_text.count loop
         l_times_text(i) := date2_t(l_date_times_text(i), l_version_dates_text(i));
      end loop;

      l_times_binary.extend(l_date_times_binary.count);

      for i in 1 .. l_date_times_binary.count loop
         l_times_binary(i) := date2_t(l_date_times_binary(i), l_version_dates_binary(i));
      end loop;

      ----------------------------------------
      -- perform actions specific to values --
      ----------------------------------------
      if l_times_values.count > 0 then
         if l_error_on_protection then
            ------------------------------
            -- check for protected data --
            ------------------------------
            for rec
               in (select table_name
                     from at_ts_table_properties
                    where start_date in (select distinct v.start_date
                                           from cwms_v_tsv v, table(l_times_values) d
                                          where v.ts_code = p_ts_code and v.date_time = d.date_1 and v.version_date = d.date_2)) loop
               execute immediate replace(
                    'select count(*)
                       from $t
                      where rowid in (select t.rowid
                                         from $t t,
                                              table(:1) d
                                        where t.ts_code = :2
                                          and t.date_time = d.date_1
                                          and t.version_date = d.date_2
                                          and bitand(t.quality_code, 2147483648) <> 0)', '$t', rec.table_name)
                  into l_protected_count
                 using l_times_values, p_ts_code;

               if l_protected_count > 0 then
                  cwms_err.raise('ERROR', 'One or more values are protected');
               end if;
            end loop;

         end if;
         ------------------------------------------
         -- insert records into at_deleted_times --
         ------------------------------------------
         insert into at_ts_deleted_times
            select cwms_util.to_millis(l_deleted_time),
                   p_ts_code,
                   d.version_date,
                   d.date_time
              from (select date_1 as date_time, date_2 as version_date from table(l_times_values)) d;
        ------------------------------------
         -- Publish TSDataDeleted messages --
         ------------------------------------
         select cwms_ts_id, db_office_id
           into l_tsid, l_office_id
           from cwms_v_ts_id
          where ts_code = p_ts_code;

         for rec1 in (select distinct date_2 as version_date from table(l_times_values)) loop
            for rec2 in (select min(date_1) as start_time, max(date_1) as end_time
                           from table(l_times_values)
                          where date_2 = rec1.version_date) loop
               cwms_msg.new_message(l_msg, l_msgid, 'TSDataDeleted');
               l_msg.set_string(l_msgid, 'ts_id', l_tsid);
               l_msg.set_string(l_msgid, 'office_id', l_office_id);
               l_msg.set_long(l_msgid, 'ts_code', p_ts_code);
               l_msg.set_long(l_msgid, 'start_time', cwms_util.to_millis(cast(rec2.start_time as timestamp)));
               l_msg.set_long(l_msgid, 'end_time', cwms_util.to_millis(cast(rec2.end_time as timestamp)));
               l_msg.set_long(l_msgid, 'version_date', cwms_util.to_millis(cast(rec1.version_date as timestamp)));
               l_msg.set_long(l_msgid, 'deleted_time', cwms_util.to_millis(l_deleted_time));
               i := cwms_msg.publish_message(l_msg, l_msgid, l_office_id || '_ts_stored');
            end loop;
         end loop;
      end if;
      ------------------------------
      -- actually delete the data --
      ------------------------------
      for rec
         in (select table_name
               from at_ts_table_properties
              where start_date in (select distinct v.start_date
                                     from cwms_v_tsv v, table(l_times_values) d
                                    where v.ts_code = p_ts_code and v.date_time = d.date_1 and v.version_date = d.date_2)) loop
         if l_override_protection then
            execute immediate replace(
                 'delete
                    from $t
                   where rowid in (select t.rowid
                                      from $t t,
                                           table(:1) d
                                     where t.ts_code = :2
                                       and t.date_time = d.date_1
                                       and t.version_date = d.date_2)', '$t', rec.table_name)
               using l_times_values, p_ts_code;
         else
            execute immediate replace(
                 'delete
                    from $t
                   where rowid in (select t.rowid
                                      from $t t,
                                           table(:1) d
                                     where t.ts_code = :2
                                       and t.date_time = d.date_1
                                       and t.version_date = d.date_2
                                       and bitand(t.quality_code, 2147483648) = 0)', '$t', rec.table_name)
               using l_times_values, p_ts_code;
         end if;
      end loop;

      delete from at_tsv_std_text
            where rowid in (select t.rowid
                              from at_tsv_std_text t, table(l_times_std_text) d
                             where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      delete from at_tsv_text
            where rowid in (select t.rowid
                              from at_tsv_text t, table(l_times_text) d
                             where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      delete from at_tsv_binary
            where rowid in (select t.rowid
                              from at_tsv_binary t, table(l_times_binary) d
                             where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);
   end purge_ts_data;

   procedure change_version_date(
      p_ts_code              in number,
      p_old_version_date_utc in date,
      p_new_version_date_utc in date,
      p_start_time_utc       in date,
      p_end_time_utc         in date,
      p_date_times_utc       in date_table_type default null,
      p_ts_item_mask         in integer default cwms_util.ts_all)
   is
      l_is_versioned             varchar2(1);
      l_date_times_values        date_table_type := date_table_type();
      l_version_dates_values     date_table_type := date_table_type();
      l_date_times_std_text      date_table_type := date_table_type();
      l_version_dates_std_text   date_table_type := date_table_type();
      l_date_times_text          date_table_type := date_table_type();
      l_version_dates_text       date_table_type := date_table_type();
      l_date_times_binary        date_table_type := date_table_type();
      l_version_dates_binary     date_table_type := date_table_type();
      l_times_values             date2_tab_t := date2_tab_t();
      l_times_std_text           date2_tab_t := date2_tab_t();
      l_times_text               date2_tab_t := date2_tab_t();
      l_times_binary             date2_tab_t := date2_tab_t();
      l_cursor                   sys_refcursor;
   begin
      -------------------
      -- sanity checks --
      -------------------
      is_ts_versioned(l_is_versioned, p_ts_code);

      if cwms_util.is_false(l_is_versioned) then
         cwms_err.raise('ERROR', 'Cannot change version date on non-versioned data.');
      end if;

      if cwms_util.all_version_dates in (p_old_version_date_utc, p_new_version_date_utc) then
         cwms_err.raise('ERROR', 'CWMS_UTIL.ALL_VERSION_DATES cannot be used for actual version date');
      end if;

      -------------------------------------------------------------------------------
      -- NOTE: The version dates in all the following collections will be the same --
      -- as the p_old_version_date_utc parameter                                   --
      -------------------------------------------------------------------------------

      ---------------------------------------------------------------------
      -- get the date_times and version_dates of all the items to update --
      ---------------------------------------------------------------------
      if bitand(p_ts_item_mask, cwms_util.ts_values) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_values);

         fetch l_cursor
         bulk collect into l_date_times_values, l_version_dates_values;

         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_std_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_std_text);

         fetch l_cursor
         bulk collect into l_date_times_std_text, l_version_dates_std_text;

         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_text) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_text);

         fetch l_cursor
         bulk collect into l_date_times_text, l_version_dates_text;

         close l_cursor;
      end if;

      if bitand(p_ts_item_mask, cwms_util.ts_binary) > 0 then
         l_cursor      :=
            retrieve_existing_times_f(
               p_ts_code,
               p_start_time_utc,
               p_end_time_utc,
               p_date_times_utc,
               p_old_version_date_utc,
               true,
               cwms_util.ts_binary);

         fetch l_cursor
         bulk collect into l_date_times_binary, l_version_dates_binary;

         close l_cursor;
      end if;

      -------------------------------------------------
      -- collect the times into queryable structures --
      -------------------------------------------------
      l_times_values.extend(l_date_times_values.count);

      for i in 1 .. l_date_times_values.count loop
         l_times_values(i) := date2_t(l_date_times_values(i), l_version_dates_values(i));
      end loop;

      l_times_std_text.extend(l_date_times_std_text.count);

      for i in 1 .. l_date_times_std_text.count loop
         l_times_std_text(i) := date2_t(l_date_times_std_text(i), l_version_dates_std_text(i));
      end loop;

      l_times_text.extend(l_date_times_text.count);

      for i in 1 .. l_date_times_text.count loop
         l_times_text(i) := date2_t(l_date_times_text(i), l_version_dates_text(i));
      end loop;

      l_times_binary.extend(l_date_times_binary.count);

      for i in 1 .. l_date_times_binary.count loop
         l_times_binary(i) := date2_t(l_date_times_binary(i), l_version_dates_binary(i));
      end loop;

      ---------------------
      -- update the data --
      ---------------------
      for rec
         in (select table_name
               from at_ts_table_properties
              where start_date in (select distinct v.start_date
                                     from cwms_v_tsv v, table(l_times_values) d
                                    where v.ts_code = p_ts_code and v.date_time = d.date_1 and v.version_date = d.date_2)) loop
         execute immediate replace(
                 'update $t
                     set version_date = :1
                    where rowid in (select t.rowid
                                      from $t t,
                                           table(:2) d
                                     where t.ts_code = :3
                                       and t.date_time = d.date_1
                                       and t.version_date = d.date_2)', '$t', rec.table_name)
            using p_new_version_date_utc, l_times_values, p_ts_code;
      end loop;

      update at_tsv_std_text
         set version_date = p_new_version_date_utc
       where rowid in (select t.rowid
                         from at_tsv_std_text t, table(l_times_std_text) d
                        where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      update at_tsv_text
         set version_date = p_new_version_date_utc
       where rowid in (select t.rowid
                         from at_tsv_text t, table(l_times_text) d
                        where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);

      update at_tsv_binary
         set version_date = p_new_version_date_utc
       where rowid in (select t.rowid
                         from at_tsv_binary t, table(l_times_binary) d
                        where ts_code = p_ts_code and t.date_time = d.date_1 and t.version_date = d.date_2);
   end change_version_date;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RENAME...
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE rename_ts (p_office_id             IN VARCHAR2,
                        p_timeseries_desc_old   IN VARCHAR2,
                        p_timeseries_desc_new   IN VARCHAR2)
   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   IS
      l_utc_offset   NUMBER := NULL;
   BEGIN
      rename_ts (p_timeseries_desc_old,
                 p_timeseries_desc_new,
                 l_utc_offset,
                 p_office_id);
   END;

   --
   ---------------------------------------------------------------------
   --
   -- Rename a time series id.
   -- If no data exists, then you can rename every part of a cwms_ts_id.
   -- If data exists then you can rename everything except the interval.
   --
   ---------------------------------------------------------------------
   --
   PROCEDURE rename_ts (p_cwms_ts_id_old   IN VARCHAR2,
                        p_cwms_ts_id_new   IN VARCHAR2,
                        p_utc_offset_new   IN NUMBER DEFAULT NULL,
                        p_office_id        IN VARCHAR2 DEFAULT NULL)
   IS
      l_utc_offset_old            at_cwms_ts_spec.interval_utc_offset%TYPE;
      --
      l_location_code_old         at_cwms_ts_spec.location_code%TYPE;
      l_interval_code_old         cwms_interval.interval_code%TYPE;
      --
      l_base_location_id_new      at_base_location.base_location_id%TYPE;
      l_sub_location_id_new       at_physical_location.sub_location_id%TYPE;
      l_location_new              VARCHAR2 (49);
      l_base_parameter_id_new     cwms_base_parameter.base_parameter_id%TYPE;
      l_sub_parameter_id_new      at_parameter.sub_parameter_id%TYPE;
      l_parameter_type_id_new     cwms_parameter_type.parameter_type_id%TYPE;
      l_interval_id_new           cwms_interval.interval_id%TYPE;
      l_duration_id_new           cwms_duration.duration_id%TYPE;
      l_version_id_new            at_cwms_ts_spec.VERSION%TYPE;
      l_utc_offset_new            at_cwms_ts_spec.interval_utc_offset%TYPE;
      --
      l_location_code_new         at_cwms_ts_spec.location_code%TYPE;
      l_interval_dur_new          cwms_interval.INTERVAL%TYPE;
      l_interval_code_new         cwms_interval.interval_code%TYPE;
      l_base_parameter_code_new   cwms_base_parameter.base_parameter_code%TYPE;
      l_parameter_type_code_new   cwms_parameter_type.parameter_type_code%TYPE;
      l_parameter_code_new        at_parameter.parameter_code%TYPE;
      l_duration_code_new         cwms_duration.duration_code%TYPE;
      --
      l_office_code               NUMBER;
      l_ts_code_old               NUMBER;
      l_ts_code_new               NUMBER;
      l_office_id                 cwms_office.office_id%TYPE;
      l_has_data                  BOOLEAN;
      l_tmp                       NUMBER;
   --
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('rename_ts_code',
                                        'get ts_code from materialized view');

      --
      --------------------------------------------------------
      -- Set office_id...
      --------------------------------------------------------
      IF p_office_id IS NULL
      THEN
         l_office_id := cwms_util.user_office_id;
      ELSE
         l_office_id := UPPER (p_office_id);
      END IF;

      DBMS_APPLICATION_INFO.set_module ('rename_ts_code', 'get office code');
      --------------------------------------------------------
      -- Get the office_code...
      --------------------------------------------------------
      l_office_code := cwms_util.get_office_code (l_office_id);
      --------------------------------------------------------
      -- Confirm old cwms_ts_id exists...
      --------------------------------------------------------
      l_ts_code_old :=
         get_ts_code (p_cwms_ts_id     => clean_ts_id(p_cwms_ts_id_old),
                      p_db_office_id   => l_office_id);

      --
      --------------------------------------------------------
      -- Retrieve old codes for the old ts_code...
      --------------------------------------------------------
      --
      SELECT location_code, interval_code, acts.INTERVAL_UTC_OFFSET
        INTO l_location_code_old, l_interval_code_old, l_utc_offset_old
        FROM at_cwms_ts_spec acts
       WHERE ts_code = l_ts_code_old;

      DBMS_OUTPUT.put_line ('l_utc_offset_old-1: ' || l_utc_offset_old);

      --------------------------------------------------------
      -- Confirm new cwms_ts_id does not exist...
      --------------------------------------------------------
      BEGIN
         --
         l_ts_code_new :=
            get_ts_code (p_cwms_ts_id     => clean_ts_id(p_cwms_ts_id_new),
                         p_db_office_id   => l_office_id);
      --

      EXCEPTION
         -----------------------------------------------------------------
         -- Exception means cwms_ts_id_new does not exist - a good thing!.
         -----------------------------------------------------------------
         WHEN OTHERS
         THEN
            l_ts_code_new := NULL;
      END;

      IF l_ts_code_new IS NOT NULL
      THEN
         cwms_err.RAISE ('TS_ALREADY_EXISTS',
                         l_office_id || '.' || p_cwms_ts_id_new);
      END IF;

      ------------------------------------------------------------------
      -- Parse cwms_id_new --
      ------------------------------------------------------------------
      parse_ts (clean_ts_id(p_cwms_ts_id_new),
                l_base_location_id_new,
                l_sub_location_id_new,
                l_base_parameter_id_new,
                l_sub_parameter_id_new,
                l_parameter_type_id_new,
                l_interval_id_new,
                l_duration_id_new,
                l_version_id_new);
      --
      l_location_new :=
         cwms_util.concat_base_sub_id (l_base_location_id_new,
                                       l_sub_location_id_new);

      ---------------------------
      -- Validate the interval --
      ---------------------------
      BEGIN
         SELECT interval_code, INTERVAL, interval_id
           INTO l_interval_code_new, l_interval_dur_new, l_interval_id_new
           FROM cwms_interval ci
          WHERE UPPER (ci.interval_id) = UPPER (l_interval_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_INTERVAL_ID', l_interval_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      ----------------------------------
      -- Validate the base parameter --
      ----------------------------------
      BEGIN
         SELECT base_parameter_code
           INTO l_base_parameter_code_new
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (l_base_parameter_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_PARAM_ID', l_base_parameter_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      ---------------------------------
      -- Validate the parameter type --
      ---------------------------------
      BEGIN
         SELECT parameter_type_code
           INTO l_parameter_type_code_new
           FROM cwms_parameter_type
          WHERE UPPER (parameter_type_id) = UPPER (l_parameter_type_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_PARAM_TYPE', l_parameter_type_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      ---------------------------
      -- Validate the duration --
      ---------------------------
      BEGIN
         SELECT duration_code
           INTO l_duration_code_new
           FROM cwms_duration
          WHERE UPPER (duration_id) = UPPER (l_duration_id_new);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE ('INVALID_DURATION_ID', l_duration_id_new);
         WHEN OTHERS
         THEN
            RAISE;
      END;

      --------------------------------------------------------
      -- Set default utc_offset if null was passed in as new...
      --------------------------------------------------------
      IF p_utc_offset_new IS NULL
      THEN
         DBMS_OUTPUT.put_line ('l_utc_offset_old-2: ' || l_utc_offset_old);
         l_utc_offset_new := l_utc_offset_old;
      ELSE
         l_utc_offset_new := p_utc_offset_new;
      END IF;
      IF l_interval_code_new = cwms_util.irregular_interval_code
      THEN
         l_utc_offset_new := cwms_util.utc_offset_irregular;
      ELSIF l_utc_offset_new < 0 OR l_utc_offset_new >= l_interval_dur_new
      THEN
         cwms_err.RAISE ('INVALID_UTC_OFFSET',
                         l_utc_offset_new,
                         l_interval_dur_new);

      END IF;
      DBMS_OUTPUT.put_line ('l_utc_offset_new: ' || l_utc_offset_new);

      -------------------------------------------------------------
      ---- Make sure that 'Inst' Parameter type doesn't have a duration--
      --------------------------------------------------------------
      IF (UPPER (l_parameter_type_id_new) = 'INST' AND l_duration_id_new <> '0')
      THEN
        raise_application_error (-20205, 'Inst parameter type can not have non-zero duration', TRUE);
      END IF;

      ---------------------------------------------------
      -- Check whether the ts_code has associated data --
      ---------------------------------------------------
      SELECT COUNT (*)
        INTO l_tmp
        FROM at_tsv
       WHERE ts_code = l_ts_code_old;

      l_has_data := l_tmp > 0;

      ------------------------------------------------------------------
      -- Perform these checks only if the ts_code has associated data --
      ------------------------------------------------------------------
      IF l_has_data
      THEN
         --------------------------------------------------------------
         -- Do not allow the interval to change, except to irregular --
         --------------------------------------------------------------
         IF     l_interval_code_old <> cwms_util.irregular_interval_code
            AND l_interval_code_new <> l_interval_code_old
         THEN
            cwms_err.RAISE (
               'GENERIC_ERROR',
               'Cannot change to a regular interval when data is present');
         END IF;

         ----------------------------------------------------
         -- Do not allow the interval UTC offset to change --
         ----------------------------------------------------
         IF l_utc_offset_new <> l_utc_offset_old
         THEN
            cwms_err.RAISE (
               'GENERIC_ERROR',
               'Cannot change interval offsets when data is present');
         END IF;
      END IF;

      ----------------------------------------------------
      -- Determine the new location_code --
      ----------------------------------------------------
      BEGIN
         l_location_code_new :=
            cwms_loc.get_location_code (l_office_id, l_location_new);
      EXCEPTION                              -- New Location does not exist...
         WHEN OTHERS
         THEN
            cwms_loc.create_location (p_location_id    => l_location_new,
                                      p_db_office_id   => l_office_id);
            --
            l_location_code_new :=
               cwms_loc.get_location_code (l_office_id, l_location_new);
      END;

      ----------------------------------------------------
      -- Determine the new parameter_code --
      ----------------------------------------------------
      l_parameter_code_new :=
         get_parameter_code (
            p_base_parameter_code   => l_base_parameter_code_new,
            p_sub_parameter_id      => l_sub_parameter_id_new,
            p_office_code           => l_office_code,
            p_create                => TRUE);


      --
      ----------------------------------------------------
      -- Perform the Rename by updating at_cwms_ts_spec --
      ----------------------------------------------------
      --
      UPDATE at_cwms_ts_spec s
         SET s.location_code = l_location_code_new,
             s.parameter_code = l_parameter_code_new,
             s.parameter_type_code = l_parameter_type_code_new,
             s.interval_code = l_interval_code_new,
             s.duration_code = l_duration_code_new,
             s.VERSION = l_version_id_new,
             s.interval_utc_offset = l_utc_offset_new
       WHERE s.ts_code = l_ts_code_old;

      COMMIT;

      --
      ---------------------------------
      -- Publish a TSRenamed message --
      ---------------------------------
      --
      DECLARE
         l_msg     SYS.aq$_jms_map_message;
         l_msgid   PLS_INTEGER;
         i         INTEGER;
      BEGIN
         cwms_msg.new_message (l_msg, l_msgid, 'TSRenamed');
         l_msg.set_string (l_msgid, 'ts_id', p_cwms_ts_id_old);
         l_msg.set_string (l_msgid, 'new_ts_id', p_cwms_ts_id_new);
         l_msg.set_string (l_msgid, 'office_id', l_office_id);
         l_msg.set_long (l_msgid, 'ts_code', l_ts_code_old);
         i :=
            cwms_msg.publish_message (l_msg,
                                      l_msgid,
                                      l_office_id || '_ts_stored');
      END;

      --
      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   --
   END rename_ts;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- PARSE_TS -
   --
   PROCEDURE parse_ts (p_cwms_ts_id          IN     VARCHAR2,
                       p_base_location_id       OUT VARCHAR2,
                       p_sub_location_id        OUT VARCHAR2,
                       p_base_parameter_id      OUT VARCHAR2,
                       p_sub_parameter_id       OUT VARCHAR2,
                       p_parameter_type_id      OUT VARCHAR2,
                       p_interval_id            OUT VARCHAR2,
                       p_duration_id            OUT VARCHAR2,
                       p_version_id             OUT VARCHAR2)
   IS
   BEGIN
      SELECT cwms_util.get_base_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                   '[^.]+',
                                                   1,
                                                   1))
                base_location_id,
             cwms_util.get_sub_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                  '[^.]+',
                                                  1,
                                                  1))
                sub_location_id,
             cwms_util.get_base_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                   '[^.]+',
                                                   1,
                                                   2))
                base_parameter_id,
             cwms_util.get_sub_id (REGEXP_SUBSTR (p_cwms_ts_id,
                                                  '[^.]+',
                                                  1,
                                                  2))
                sub_parameter_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            3)
                parameter_type_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            4)
                interval_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            5)
                duration_id,
             REGEXP_SUBSTR (p_cwms_ts_id,
                            '[^.]+',
                            1,
                            6)
                VERSION
        INTO p_base_location_id,
             p_sub_location_id,
             p_base_parameter_id,
             p_sub_parameter_id,
             p_parameter_type_id,
             p_interval_id,
             p_duration_id,
             p_version_id
        FROM DUAL;
   END parse_ts;



   PROCEDURE zretrieve_ts (p_at_tsv_rc      IN OUT SYS_REFCURSOR,
                           p_units          IN     VARCHAR2,
                           p_cwms_ts_id     IN     VARCHAR2,
                           p_start_time     IN     DATE,
                           p_end_time       IN     DATE,
                           p_trim           IN     VARCHAR2 DEFAULT 'F',
                           p_inclusive      IN     NUMBER DEFAULT NULL,
                           p_version_date   IN     DATE DEFAULT NULL,
                           p_max_version    IN     VARCHAR2 DEFAULT 'T',
                           p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
      l_ts_interval       NUMBER;
      l_ts_offset         NUMBER;
      l_versioned         NUMBER;
      l_ts_code           NUMBER;
      l_version_date      DATE;
      l_max_version       BOOLEAN;
      l_trim              BOOLEAN;
      l_start_time        DATE := p_start_time;
      l_start_trim_time   DATE;
      l_end_time          DATE := p_end_time;
      l_end_trim_time     DATE;
      l_end_time_init     DATE := l_end_time;
      l_db_office_id      VARCHAR2 (16);
   BEGIN
      --
      DBMS_APPLICATION_INFO.set_module ('Cwms_ts_retrieve', 'Check Interval');

      --
      -- set default values, don't be fooled by NULL as an actual argument
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := cwms_util.user_office_id;
      ELSE
         l_db_office_id := p_db_office_id;
      END IF;

      IF p_trim IS NULL
      THEN
         l_trim := FALSE;
      ELSE
         l_trim := cwms_util.return_true_or_false (p_trim);
      END IF;

      IF NVL (p_max_version, 'T') = 'T'
      THEN
         l_max_version := FALSE;
      ELSE
         l_max_version := TRUE;
      END IF;

      l_version_date := NVL (p_version_date, cwms_util.non_versioned);

      -- Make initial checks on start/end dates...
      IF p_start_time IS NULL OR p_end_time IS NULL
      THEN
         cwms_err.raise ('ERROR', 'No way Jose');
      END IF;

      IF p_end_time < p_start_time
      THEN
         cwms_err.raise ('ERROR', 'No way Jose');
      END IF;


      --Get Time series parameters for retrieval load into record structure
      BEGIN
         SELECT INTERVAL,
                CASE interval_utc_offset
                   WHEN cwms_util.utc_offset_undefined THEN NULL
                   WHEN cwms_util.utc_offset_irregular THEN NULL
                   ELSE (interval_utc_offset)
                END,
                version_flag,
                ts_code
           INTO l_ts_interval,
                l_ts_offset,
                l_versioned,
                l_ts_code
           FROM at_cwms_ts_id
          WHERE     db_office_id = UPPER (l_db_office_id)
                AND UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT INTERVAL,
                   CASE interval_utc_offset
                      WHEN cwms_util.utc_offset_undefined THEN NULL
                      WHEN cwms_util.utc_offset_irregular THEN NULL
                      ELSE (interval_utc_offset)
                   END,
                   version_flag,
                   ts_code
              INTO l_ts_interval,
                   l_ts_offset,
                   l_versioned,
                   l_ts_code
              FROM at_cwms_ts_id
             WHERE     db_office_id = UPPER (l_db_office_id)
                   AND UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id);
      END;


      IF l_ts_interval = 0
      THEN
         IF p_inclusive IS NOT NULL
         THEN
            IF l_versioned IS NULL
            THEN                                      -- l_versioned IS NULL -
               --
               -- nonl_versioned, irregular, inclusive retrieval
               --
               DBMS_OUTPUT.put_line ('RETRIEVE_TS #1');

               --
               OPEN p_at_tsv_rc FOR
                    SELECT date_time, VALUE, quality_code
                      FROM (SELECT date_time,
                                   VALUE,
                                   quality_code,
                                   LAG (date_time, 1, l_start_time)
                                      OVER (ORDER BY date_time)
                                      lagdate,
                                   LEAD (date_time, 1, l_end_time)
                                      OVER (ORDER BY date_time)
                                      leaddate
                              FROM av_tsv_dqu v
                             WHERE     v.ts_code = l_ts_code
                                   AND v.unit_id = cwms_util.get_unit_id(p_units)
                                   AND v.start_date <= l_end_time
                                   AND v.end_date > l_start_time)
                     WHERE leaddate >= l_start_time AND lagdate <= l_end_time
                  ORDER BY date_time ASC;
            ELSE                                  -- l_versioned IS NOT NULL -
               --
               -- l_versioned, irregular, inclusive retrieval -
               IF p_version_date IS NULL
               THEN                                -- p_version_date IS NULL -
                  IF l_max_version
                  THEN                              -- l_max_version is TRUE -
                     --latest version_date query -
                     --
                     DBMS_OUTPUT.put_line ('RETRIEVE_TS #2');

                     --
                     OPEN p_at_tsv_rc FOR
                          SELECT date_time, VALUE, quality_code
                            FROM (SELECT date_time,
                                         MAX (
                                            VALUE)
                                         KEEP (DENSE_RANK LAST ORDER BY
                                                                  version_date)
                                            VALUE,
                                         MAX (
                                            quality_code)
                                         KEEP (DENSE_RANK LAST ORDER BY
                                                                  version_date)
                                            quality_code
                                    FROM (SELECT date_time,
                                                 VALUE,
                                                 quality_code,
                                                 version_date,
                                                 LAG (date_time,
                                                      1,
                                                      l_start_time)
                                                 OVER (ORDER BY date_time)
                                                    lagdate,
                                                 LEAD (date_time,
                                                       1,
                                                       l_end_time)
                                                 OVER (ORDER BY date_time)
                                                    leaddate
                                            FROM av_tsv_dqu v
                                           WHERE     v.ts_code = l_ts_code
                                                 AND v.unit_id = cwms_util.get_unit_id(p_units)
                                                 AND v.start_date <= l_end_time
                                                 AND v.end_date > l_start_time)
                                   WHERE     leaddate >= l_start_time
                                         AND lagdate <= l_end_time)
                        ORDER BY date_time ASC;
                  ELSE                              --l_max_version is FALSE -
                     -- first version_date query -
                     --
                     DBMS_OUTPUT.put_line ('RETRIEVE_TS #3');

                     --
                     OPEN p_at_tsv_rc FOR
                          SELECT date_time, VALUE, quality_code
                            FROM (SELECT date_time,
                                         MAX (
                                            VALUE)
                                         KEEP (DENSE_RANK FIRST ORDER BY
                                                                   version_date)
                                            VALUE,
                                         MAX (
                                            quality_code)
                                         KEEP (DENSE_RANK FIRST ORDER BY
                                                                   version_date)
                                            quality_code
                                    FROM (SELECT date_time,
                                                 VALUE,
                                                 quality_code,
                                                 version_date,
                                                 LAG (date_time,
                                                      1,
                                                      l_start_time)
                                                 OVER (ORDER BY date_time)
                                                    lagdate,
                                                 LEAD (date_time,
                                                       1,
                                                       l_end_time)
                                                 OVER (ORDER BY date_time)
                                                    leaddate
                                            FROM av_tsv_dqu v
                                           WHERE     v.ts_code = l_ts_code
                                                 AND v.unit_id = cwms_util.get_unit_id(p_units)
                                                 AND v.start_date <= l_end_time
                                                 AND v.end_date > l_start_time)
                                   WHERE     leaddate >= l_start_time
                                         AND lagdate <= l_end_time)
                        ORDER BY date_time ASC;
                  END IF;                                    --l_max_version -
               ELSE                             --p_version_date IS NOT NULL -
                  --
                  --selected version_date query -
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #4');

                  --
                  OPEN p_at_tsv_rc FOR
                       SELECT date_time, VALUE, quality_code
                         FROM (SELECT date_time,
                                      VALUE,
                                      quality_code,
                                      LAG (date_time, 1, l_start_time)
                                         OVER (ORDER BY date_time)
                                         lagdate,
                                      LEAD (date_time, 1, l_end_time)
                                         OVER (ORDER BY date_time)
                                         leaddate
                                 FROM av_tsv_dqu v
                                WHERE     v.ts_code = l_ts_code
                                      AND v.unit_id = cwms_util.get_unit_id(p_units)
                                      AND v.version_date = p_version_date
                                      AND v.start_date <= l_end_time
                                      AND v.end_date > l_start_time)
                        WHERE     leaddate >= l_start_time
                              AND lagdate <= l_end_time
                     ORDER BY date_time ASC;
               END IF;                                      --p_version_date -
            END IF;                                           -- l_versioned -
         ELSE                                         -- p_inclusive IS NULL -
            DBMS_APPLICATION_INFO.set_action (
                  'return  irregular  ts '
               || l_ts_code
               || ' from '
               || TO_CHAR (l_start_time, 'mm/dd/yyyy hh24:mi')
               || ' to '
               || TO_CHAR (l_end_time, 'mm/dd/yyyy hh24:mi')
               || ' in units '
               || p_units);

            IF l_versioned IS NULL
            THEN
               -- nonl_versioned, irregular, noninclusive retrieval -
               --
               DBMS_OUTPUT.put_line ('gk - RETRIEVE_TS #5 ');

               --
               OPEN p_at_tsv_rc FOR
                    SELECT date_time, VALUE, quality_code
                      FROM av_tsv_dqu v
                     WHERE     v.ts_code = l_ts_code
                           AND v.date_time BETWEEN l_start_time AND l_end_time
                           AND v.unit_id = cwms_util.get_unit_id(p_units)
                           AND v.start_date <= l_end_time
                           AND v.end_date > l_start_time
                  ORDER BY date_time ASC;
            ELSE                                  -- l_versioned IS NOT NULL -
               --
               -- l_versioned, irregular, noninclusive retrieval -
               --
               IF p_version_date IS NULL
               THEN
                  IF l_max_version
                  THEN
                     --latest version_date query
                     --
                     DBMS_OUTPUT.put_line ('RETRIEVE_TS #6');

                     --
                     OPEN p_at_tsv_rc FOR
                          SELECT date_time, VALUE, quality_code
                            FROM (  SELECT date_time,
                                           MAX (
                                              VALUE)
                                           KEEP (DENSE_RANK LAST ORDER BY
                                                                    version_date)
                                              VALUE,
                                           MAX (
                                              quality_code)
                                           KEEP (DENSE_RANK LAST ORDER BY
                                                                    version_date)
                                              quality_code
                                      FROM (SELECT date_time,
                                                   VALUE,
                                                   quality_code,
                                                   version_date
                                              FROM av_tsv_dqu v
                                             WHERE     v.ts_code = l_ts_code
                                                   AND v.date_time BETWEEN l_start_time
                                                                       AND l_end_time
                                                   AND v.unit_id = cwms_util.get_unit_id(p_units)
                                                   AND v.start_date <= l_end_time
                                                   AND v.end_date > l_start_time)
                                  GROUP BY date_time)
                        ORDER BY date_time ASC;
                  ELSE                         -- p_version_date IS NOT NULL -
                     --
                     DBMS_OUTPUT.put_line ('RETRIEVE_TS #7');

                     --
                     OPEN p_at_tsv_rc FOR
                          SELECT date_time, VALUE, quality_code
                            FROM (  SELECT date_time,
                                           MAX (
                                              VALUE)
                                           KEEP (DENSE_RANK FIRST ORDER BY
                                                                     version_date)
                                              VALUE,
                                           MAX (
                                              quality_code)
                                           KEEP (DENSE_RANK FIRST ORDER BY
                                                                     version_date)
                                              quality_code
                                      FROM (SELECT date_time,
                                                   VALUE,
                                                   quality_code,
                                                   version_date
                                              FROM av_tsv_dqu v
                                             WHERE     v.ts_code = l_ts_code
                                                   AND v.date_time BETWEEN l_start_time
                                                                       AND l_end_time
                                                   AND v.unit_id = cwms_util.get_unit_id(p_units)
                                                   AND v.start_date <= l_end_time
                                                   AND v.end_date > l_start_time)
                                  GROUP BY date_time)
                        ORDER BY date_time ASC;
                  END IF;                      -- p_version_date IS NOT NULL -
               ELSE                                -- l_max_version is FALSE -
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #8');

                  --
                  OPEN p_at_tsv_rc FOR
                       SELECT date_time, VALUE, quality_code
                         FROM av_tsv_dqu v
                        WHERE     v.ts_code = l_ts_code
                              AND v.date_time BETWEEN l_start_time
                                                  AND l_end_time
                              AND v.unit_id = cwms_util.get_unit_id(p_units)
                              AND v.version_date = version_date
                              AND v.start_date <= l_end_time
                              AND v.end_date > l_start_time
                     ORDER BY date_time ASC;
               END IF;                                      -- l_max_version -
            END IF;                                           -- l_versioned -
         END IF;                                              -- p_inclusive -
      ELSE                                             -- l_ts_interval <> 0 -
         DBMS_APPLICATION_INFO.set_action (
               'return  regular  ts '
            || l_ts_code
            || ' from '
            || TO_CHAR (l_start_time, 'mm/dd/yyyy hh24:mi')
            || ' to '
            || TO_CHAR (l_end_time, 'mm/dd/yyyy hh24:mi')
            || ' in units '
            || p_units);
         -- Make sure start_time and end_time fall on a valid date/time for the regular -
         --    time series given the interval and offset. -
         l_start_time :=
            get_time_on_after_interval (l_start_time,
                                        l_ts_offset,
                                        l_ts_interval);
         l_end_time :=
            get_time_on_after_interval (l_end_time,
                                        l_ts_offset,
                                        l_ts_interval);

         IF l_end_time > l_end_time_init
         THEN
            l_end_time := l_end_time - (l_ts_interval / 1440);
         END IF;

         IF l_versioned IS NULL
         THEN
            --
            -- non_versioned, regular ts query
            --
            DBMS_OUTPUT.put_line (
               'RETRIEVE_TS #9 - non versioned, regular ts query');

            --

            IF l_trim
            THEN
               SELECT MAX (date_time), MIN (date_time)
                 INTO l_end_trim_time, l_start_trim_time
                 FROM av_tsv v
                WHERE     v.ts_code = l_ts_code
                      AND v.date_time BETWEEN l_start_time AND l_end_time
                      AND v.start_date <= l_end_time
                      AND v.end_date > l_start_time;
            ELSE
               l_end_trim_time := l_end_time;
               l_start_trim_time := l_start_time;
            END IF;

            OPEN p_at_tsv_rc FOR
                 SELECT date_time "DATE_TIME",
                        VALUE,
                        NVL (quality_code, 0) quality_code
                   FROM (SELECT date_time, v.VALUE, v.quality_code
                           FROM    (SELECT date_time, v.VALUE, v.quality_code
                                      FROM av_tsv_dqu v
                                     WHERE     v.ts_code = l_ts_code
                                           AND v.date_time BETWEEN l_start_time
                                                               AND l_end_time
                                           AND v.unit_id = cwms_util.get_unit_id(p_units)
                                           AND v.start_date <= l_end_time
                                           AND v.end_date > l_start_time) v
                                RIGHT OUTER JOIN
                                   (    SELECT   l_start_trim_time
                                               + (  (LEVEL - 1)
                                                  / (1440 / (l_ts_interval)))
                                                  date_time
                                          FROM DUAL
                                    CONNECT BY     1 = 1
                                               AND LEVEL <=
                                                        (  ROUND (
                                                                (  l_end_trim_time
                                                                 - l_start_trim_time)
                                                              * 1440)
                                                         / l_ts_interval)
                                                      + 1) t
                                USING (date_time))
               ORDER BY date_time;
         ELSE                                    --  l_versioned IS NOT NULL -
            IF p_version_date IS NULL
            THEN
               IF l_max_version
               THEN
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #10');

                  --
                  OPEN p_at_tsv_rc FOR
                       SELECT date_time, VALUE, quality_code
                         FROM (  SELECT jdate_time date_time,
                                        MAX (
                                           VALUE)
                                        KEEP (DENSE_RANK LAST ORDER BY
                                                                 version_date)
                                           VALUE,
                                        MAX (
                                           quality_code)
                                        KEEP (DENSE_RANK LAST ORDER BY
                                                                 version_date)
                                           quality_code
                                   FROM (SELECT *
                                           FROM    (SELECT *
                                                      FROM av_tsv_dqu v
                                                     WHERE     v.ts_code =
                                                                  l_ts_code
                                                           AND v.date_time BETWEEN l_start_time
                                                                               AND l_end_time
                                                           AND v.unit_id =
                                                                  cwms_util.get_unit_id(p_units)
                                                           AND v.start_date <=
                                                                  l_end_time
                                                           AND v.end_date >
                                                                  l_start_time) v
                                                RIGHT OUTER JOIN
                                                   (    SELECT   l_start_time
                                                               + (  (LEVEL - 1)
                                                                  / (  1440
                                                                     / l_ts_interval))
                                                                  jdate_time
                                                          FROM DUAL
                                                    CONNECT BY     1 = 1
                                                               AND LEVEL <=
                                                                        (  ROUND (
                                                                                (  l_end_time
                                                                                 - l_start_time)
                                                                              * 1440)
                                                                         / l_ts_interval)
                                                                      + 1) t
                                                ON t.jdate_time = v.date_time)
                               ORDER BY jdate_time)
                     GROUP BY date_time;
               ELSE                                -- l_max_version is FALSE -
                  --
                  DBMS_OUTPUT.put_line ('RETRIEVE_TS #11');

                  --
                  OPEN p_at_tsv_rc FOR
                       SELECT date_time, VALUE, quality_code
                         FROM (  SELECT jdate_time date_time,
                                        MAX (
                                           VALUE)
                                        KEEP (DENSE_RANK FIRST ORDER BY
                                                                  version_date)
                                           VALUE,
                                        MAX (
                                           quality_code)
                                        KEEP (DENSE_RANK FIRST ORDER BY
                                                                  version_date)
                                           quality_code
                                   FROM (SELECT *
                                           FROM    (SELECT *
                                                      FROM av_tsv_dqu v
                                                     WHERE     v.ts_code =
                                                                  l_ts_code
                                                           AND v.date_time BETWEEN l_start_time
                                                                               AND l_end_time
                                                           AND v.unit_id =
                                                                  cwms_util.get_unit_id(p_units)
                                                           AND v.start_date <=
                                                                  l_end_time
                                                           AND v.end_date >
                                                                  l_start_time) v
                                                RIGHT OUTER JOIN
                                                   (    SELECT   l_start_time
                                                               + (  (LEVEL - 1)
                                                                  / (  1440
                                                                     / l_ts_interval))
                                                                  jdate_time
                                                          FROM DUAL
                                                    CONNECT BY     1 = 1
                                                               AND LEVEL <=
                                                                        (  ROUND (
                                                                                (  l_end_time
                                                                                 - l_start_time)
                                                                              * 1440)
                                                                         / l_ts_interval)
                                                                      + 1) t
                                                ON t.jdate_time = v.date_time)
                               ORDER BY jdate_time)
                     GROUP BY date_time;
               END IF;                                      -- l_max_version -
            ELSE                               -- p_version_date IS NOT NULL -
               --
               DBMS_OUTPUT.put_line ('RETRIEVE_TS #12');

               --
               OPEN p_at_tsv_rc FOR
                    SELECT jdate_time date_time,
                           VALUE,
                           NVL (quality_code, 0) quality_code
                      FROM (SELECT *
                              FROM    (SELECT *
                                         FROM av_tsv_dqu v
                                        WHERE     v.ts_code = l_ts_code
                                              AND v.date_time BETWEEN l_start_time
                                                                  AND l_end_time
                                              AND v.unit_id = cwms_util.get_unit_id(p_units)
                                              AND v.version_date =
                                                     p_version_date
                                              AND v.start_date <= l_end_time
                                              AND v.end_date > l_start_time) v
                                   RIGHT OUTER JOIN
                                      (    SELECT   l_start_time
                                                  + (  (LEVEL - 1)
                                                     / (1440 / l_ts_interval))
                                                     jdate_time
                                             FROM DUAL
                                       CONNECT BY     1 = 1
                                                  AND LEVEL <=
                                                           (  ROUND (
                                                                   (  l_end_time
                                                                    - l_start_time)
                                                                 * 1440)
                                                            / l_ts_interval)
                                                         + 1) t
                                   ON t.jdate_time = v.date_time)
                  ORDER BY jdate_time;
            END IF;
         END IF;
      END IF;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END zretrieve_ts;

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
      p_db_office_id       IN     VARCHAR2 DEFAULT NULL)
   IS
      /*l_at_tsv_rc   sys_refcursor;*/
      l_inclusive   VARCHAR2 (1);
   BEGIN
      p_transaction_time := CAST ( (SYSTIMESTAMP AT TIME ZONE 'GMT') AS DATE);

      IF NVL (p_inclusive, 0) = 0
      THEN
         l_inclusive := 'F';
      ELSE
         l_inclusive := 'T';
      END IF;

      retrieve_ts_out (p_at_tsv_rc,
                       p_cwms_ts_id_out,
                       p_units_out,
                       p_cwms_ts_id_in,
                       p_units_in,
                       p_start_time,
                       p_end_time,
                       'UTC',
                       p_trim,
                       l_inclusive,
                       l_inclusive,
                       'F',
                       'F',
                       p_version_date,
                       p_max_version,
                       p_db_office_id);
   END zretrieve_ts_java;

   PROCEDURE retrieve_existing_times(
      p_cursor           OUT sys_refcursor,
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE,
      p_item_mask        IN  BINARY_INTEGER  DEFAULT cwms_util.ts_all)
   IS
   BEGIN
      p_cursor := retrieve_existing_times_f(
         p_ts_code,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_version_date_utc,
         p_max_version);

   END retrieve_existing_times;

   FUNCTION retrieve_existing_times_f(
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE,
      p_item_mask        IN  BINARY_INTEGER  DEFAULT cwms_util.ts_all)
      RETURN sys_refcursor
   IS
      l_is_versioned           varchar2(1);
      l_version_date_utc       date;
      l_date_times_values      date_table_type := date_table_type();
      l_version_dates_values   date_table_type := date_table_type();
      l_date_times_std_text    date_table_type := date_table_type();
      l_version_dates_std_text date_table_type := date_table_type();
      l_date_times_text        date_table_type := date_table_type();
      l_version_dates_text     date_table_type := date_table_type();
      l_date_times_binary      date_table_type := date_table_type();
      l_version_dates_binary   date_table_type := date_table_type();
      l_value_times            date2_tab_t := date2_tab_t();
      l_std_text_times         date2_tab_t := date2_tab_t();
      l_text_times             date2_tab_t := date2_tab_t();
      l_binary_times           date2_tab_t := date2_tab_t();
      l_cursor                 sys_refcursor;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      if p_ts_code is null then
         cwms_err.raise('NULL_ARGUMENT', 'P_TS_CODE');
      end if;
      if p_date_times_utc is not null and (p_start_time_utc is not null or p_end_time_utc is not null) then
         cwms_err.raise('ERROR', 'Start and/or end times cannot be specified with specific times.');
      end if;

      -----------------------------------------------
      -- collect the times for the specified items --
      -----------------------------------------------
      cwms_ts.is_ts_versioned(l_is_versioned, p_ts_code);
      if p_version_date_utc is null then
         -------------------------------
         -- no version_date specified --
         -------------------------------
         if cwms_util.return_true_or_false(l_is_versioned) then
            ---------------------------
            -- versioned time series --
            ---------------------------
            if p_max_version then
               ---------------------------
               -- max_version specified --
               ---------------------------
               if bitand(p_item_mask, cwms_util.ts_values) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
                  if p_date_times_utc is null then
                       select date_time, max(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, max(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
            else
               ---------------------------
               -- min_version specified --
               ---------------------------
               if bitand(p_item_mask, cwms_util.ts_values) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_values, l_version_dates_values
                         from av_tsv
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_std_text, l_version_dates_std_text
                         from at_tsv_std_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_text) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_text, l_version_dates_text
                         from at_tsv_text
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
               if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
                  if p_date_times_utc is null then
                       select date_time, min(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                     group by ts_code, date_time;
                  else
                       select date_time, min(version_date)
                         bulk collect into l_date_times_binary, l_version_dates_binary
                         from at_tsv_binary
                        where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc))
                     group by ts_code, date_time;
                  end if;
               end if;
            end if;
         else
            -------------------------------
            -- non-versioned time series --
            -------------------------------
            if bitand(p_item_mask, cwms_util.ts_values) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_values, l_version_dates_values
                    from av_tsv
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_values, l_version_dates_values
                    from av_tsv
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
            if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_std_text, l_version_dates_std_text
                    from at_tsv_std_text
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_std_text, l_version_dates_std_text
                    from at_tsv_std_text
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
            if bitand(p_item_mask, cwms_util.ts_text) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_text, l_version_dates_text
                    from at_tsv_text
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_text, l_version_dates_text
                    from at_tsv_text
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
            if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
               if p_date_times_utc is null then
                  select date_time, version_date
                    bulk collect into l_date_times_binary, l_version_dates_binary
                    from at_tsv_binary
                   where ts_code = p_ts_code and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time);
               else
                  select date_time, version_date
                    bulk collect into l_date_times_binary, l_version_dates_binary
                    from at_tsv_binary
                   where ts_code = p_ts_code and date_time in (select column_value from table(p_date_times_utc));
               end if;
            end if;
         end if;
      else
         -------------------------------
         -- version_date is specified --
         -------------------------------
         if p_version_date_utc != cwms_util.all_version_dates then
            l_version_date_utc := p_version_date_utc;
         end if;
         if bitand(p_item_mask, cwms_util.ts_values) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_values, l_version_dates_values
                 from av_tsv
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_values, l_version_dates_values
                 from av_tsv
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
         if bitand(p_item_mask, cwms_util.ts_std_text) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_std_text, l_version_dates_std_text
                 from at_tsv_std_text
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_std_text, l_version_dates_std_text
                 from at_tsv_std_text
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
         if bitand(p_item_mask, cwms_util.ts_text) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_text, l_version_dates_text
                 from at_tsv_text
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_text, l_version_dates_text
                 from at_tsv_text
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
         if bitand(p_item_mask, cwms_util.ts_binary) > 0 then
            if p_date_times_utc is null then
               select date_time, version_date
                 bulk collect into l_date_times_binary, l_version_dates_binary
                 from at_tsv_binary
                where ts_code = p_ts_code
                  and date_time between nvl(p_start_time_utc, date_time) and nvl(p_end_time_utc, date_time)
                  and version_date = nvl(l_version_date_utc, version_date);
            else
               select date_time, version_date
                 bulk collect into l_date_times_binary, l_version_dates_binary
                 from at_tsv_binary
                where ts_code = p_ts_code
                  and date_time in (select column_value from table(p_date_times_utc))
                  and version_date = nvl(l_version_date_utc, version_date);
            end if;
         end if;
      end if;
      ----------------------------------------------------
      -- collect the results into queryable collections --
      ----------------------------------------------------
      l_value_times.extend(l_date_times_values.count);
      for i in 1..l_date_times_values.count loop
         l_value_times(i) := date2_t(l_date_times_values(i), l_version_dates_values(i));
      end loop;
      l_std_text_times.extend(l_date_times_std_text.count);
      for i in 1..l_date_times_std_text.count loop
         l_std_text_times(i) := date2_t(l_date_times_std_text(i), l_version_dates_std_text(i));
      end loop;
      l_text_times.extend(l_date_times_text.count);
      for i in 1..l_date_times_text.count loop
         l_text_times(i) := date2_t(l_date_times_text(i), l_version_dates_text(i));
      end loop;
      l_binary_times.extend(l_date_times_binary.count);
      for i in 1..l_date_times_binary.count loop
         l_binary_times(i) := date2_t(l_date_times_binary(i), l_version_dates_binary(i));
      end loop;
      --------------------------------------
      -- return a cursor into the results --
      --------------------------------------
      open l_cursor for
         select date_1 as date_time,
                date_2 as version_date
           from (select * from table(l_value_times)
                 union
                 select * from table(l_std_text_times)
                 union
                 select * from table(l_text_times)
                 union
                 select * from table(l_binary_times)
                )
          order by date_1, date_2;
      return l_cursor;
   END retrieve_existing_times_f;

   PROCEDURE retrieve_existing_item_counts(
      p_cursor           OUT sys_refcursor,
      p_ts_code          IN  NUMBER,
      p_start_time_utc   IN  DATE            DEFAULT NULL,
      p_end_time_utc     IN  DATE            DEFAULT NULL,
      p_date_times_utc   in  date_table_type DEFAULT NULL,
      p_version_date_utc IN  DATE            DEFAULT NULL,
      p_max_version      IN  BOOLEAN         DEFAULT TRUE)
   IS
   BEGIN
      p_cursor := retrieve_existing_item_counts(
         p_ts_code,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_version_date_utc,
         p_max_version);
   END retrieve_existing_item_counts;

function retrieve_existing_item_counts(
   p_ts_code          in number,
   p_start_time_utc   in date default null,
   p_end_time_utc     in date default null,
   p_date_times_utc   in date_table_type default null,
   p_version_date_utc in date default null,
   p_max_version      in boolean default true)
   return sys_refcursor
is
   l_cursor          sys_refcursor;
   l_date_times      date_table_type;
   l_version_dates   date_table_type;
   l_times           date2_tab_t := date2_tab_t();
begin
   l_cursor      :=
      retrieve_existing_times_f(
         p_ts_code,
         p_start_time_utc,
         p_end_time_utc,
         p_date_times_utc,
         p_version_date_utc,
         p_max_version,
         cwms_util.ts_all);

   fetch l_cursor
   bulk collect into l_date_times, l_version_dates;

   close l_cursor;

   l_times.extend(l_date_times.count);

   for i in 1 .. l_date_times.count loop
      l_times(i) := date2_t(l_date_times(i), l_version_dates(i));
   end loop;

   open l_cursor for
        select d.date_time,
               d.version_date,
               count(v.date_time) as value_count,
               count(s.date_time) as std_text_count,
               count(t.date_time) as text_count,
               count(b.date_time) as binary_count
          from (select date_1 as date_time, date_2 as version_date from table(l_times)) d
               left outer join (select date_time, version_date
                                  from av_tsv
                                 where ts_code = p_ts_code) v
                  on v.date_time = d.date_time and v.version_date = d.version_date
               left outer join (select date_time, version_date
                                  from at_tsv_std_text
                                 where ts_code = p_ts_code) s
                  on s.date_time = d.date_time and s.version_date = d.version_date
               left outer join (select date_time, version_date
                                  from at_tsv_text
                                 where ts_code = p_ts_code) t
                  on t.date_time = d.date_time and t.version_date = d.version_date
               left outer join (select date_time, version_date
                                  from at_tsv_binary
                                 where ts_code = p_ts_code) b
                  on b.date_time = d.date_time and b.version_date = d.version_date
      group by d.date_time, d.version_date
      order by d.date_time, d.version_date;

   return l_cursor;
end retrieve_existing_item_counts;

   PROCEDURE collect_deleted_times (p_deleted_time   IN TIMESTAMP,
                                    p_ts_code        IN NUMBER,
                                    p_version_date   IN DATE,
                                    p_start_time     IN DATE,
                                    p_end_time       IN DATE)
   IS
      l_table_names   str_tab_t;
      l_millis        NUMBER (14);
   BEGIN
      SELECT table_name
        BULK COLLECT INTO l_table_names
        FROM at_ts_table_properties
       WHERE start_date <= p_end_time AND end_date > p_start_time;

      l_millis := cwms_util.to_millis (p_deleted_time);

      FOR i IN 1 .. l_table_names.COUNT
      LOOP
         EXECUTE IMMEDIATE REPLACE (
            'insert
               into at_ts_deleted_times
             select :millis,
                    :ts_code,
                    :version_date,
                    date_time
               from table_name
              where ts_code = :ts_code
                and version_date = :version_date
                and date_time between :start_time and :end_time',
                             'table_name',
                             l_table_names (i))
            USING l_millis,
                  p_ts_code,
                  p_version_date,
                  p_ts_code,
                  p_version_date,
                  p_start_time,
                  p_end_time;
      END LOOP;
   END collect_deleted_times;

   PROCEDURE retrieve_deleted_times (
      p_deleted_times      OUT date_table_type,
      p_deleted_time    IN     NUMBER,
      p_ts_code         IN     NUMBER,
      p_version_date    IN     NUMBER)
   IS
   BEGIN
        SELECT date_time
          BULK COLLECT INTO p_deleted_times
          FROM at_ts_deleted_times
         WHERE     deleted_time = p_deleted_time
               AND ts_code = p_ts_code
               AND version_date =
                      CAST (cwms_util.TO_TIMESTAMP (p_version_date) AS DATE)
      ORDER BY date_time;
   END retrieve_deleted_times;

   FUNCTION retrieve_deleted_times_f (p_deleted_time   IN NUMBER,
                                      p_ts_code        IN NUMBER,
                                      p_version_date   IN NUMBER)
      RETURN date_table_type
   IS
      l_deleted_times   date_table_type;
   BEGIN
      retrieve_deleted_times (l_deleted_times,
                              p_deleted_time,
                              p_ts_code,
                              p_version_date);

      RETURN l_deleted_times;
   END retrieve_deleted_times_f;

   -- p_fail_if_exists 'T' will throw an exception if the parameter_id already    -
   --                        exists.                                              -
   --                  'F' will simply return the parameter code of the already   -
   --                        existing parameter id.                               -
   PROCEDURE create_parameter_code (
      p_base_parameter_code      OUT NUMBER,
      p_parameter_code           OUT NUMBER,
      p_base_parameter_id     IN     VARCHAR2,
      p_sub_parameter_id      IN     VARCHAR2,
      p_fail_if_exists        IN     VARCHAR2 DEFAULT 'T',
      p_db_office_code        IN     NUMBER)
   IS
      l_all_office_code       NUMBER := cwms_util.db_office_code_all;
      l_parameter_id_exists   BOOLEAN := FALSE;
   BEGIN
      IF p_db_office_code = 0
      THEN
         cwms_err.RAISE ('INVALID_OFFICE_ID', 'Unkown');
      END IF;

      BEGIN
         SELECT base_parameter_code
           INTO p_base_parameter_code
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE (
               'INVALID_PARAM_ID',
                  p_base_parameter_id
               || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
               || p_sub_parameter_id);
      END;

      BEGIN
         IF p_sub_parameter_id IS NULL
         THEN
            SELECT parameter_code
              INTO p_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND sub_parameter_id IS NULL
                   AND db_office_code IN
                          (p_db_office_code, l_all_office_code);
         ELSE
            SELECT parameter_code
              INTO p_parameter_code
              FROM at_parameter ap
             WHERE     base_parameter_code = p_base_parameter_code
                   AND UPPER (sub_parameter_id) = UPPER (p_sub_parameter_id)
                   AND db_office_code IN
                          (p_db_office_code, l_all_office_code);
         END IF;

         l_parameter_id_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF p_sub_parameter_id IS NULL
            THEN
               cwms_err.RAISE (
                  'INVALID_PARAM_ID',
                     p_base_parameter_id
                  || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
                  || p_sub_parameter_id);
            ELSE                                -- Insert new sub_parameter...
               INSERT INTO at_parameter (parameter_code,
                                         db_office_code,
                                         base_parameter_code,
                                         sub_parameter_id)
                    VALUES (cwms_seq.NEXTVAL,
                            p_db_office_code,
                            p_base_parameter_code,
                            p_sub_parameter_id)
                 RETURNING parameter_code
                      INTO p_parameter_code;
            END IF;
      END;

      IF UPPER (NVL (p_fail_if_exists, 'T')) = 'T' AND l_parameter_id_exists
      THEN
         cwms_err.RAISE (
            'ITEM_ALREADY_EXISTS',
               p_base_parameter_id
            || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
            || p_sub_parameter_id,
            'Parameter Id');
      END IF;
   END create_parameter_code;


   PROCEDURE create_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_code        NUMBER
                                 := cwms_util.get_db_office_code (p_db_office_id);
      l_base_parameter_code   NUMBER;
      l_parameter_code        NUMBER;
   BEGIN
      create_parameter_code (
         p_base_parameter_code   => l_base_parameter_code,
         p_parameter_code        => l_parameter_code,
         p_base_parameter_id     => cwms_util.get_base_id (p_parameter_id),
         p_sub_parameter_id      => cwms_util.get_sub_id (p_parameter_id),
         p_fail_if_exists        => 'F',
         p_db_office_code        => l_db_office_code);
   END;


   PROCEDURE delete_parameter_id (p_base_parameter_id   IN VARCHAR2,
                                  p_sub_parameter_id    IN VARCHAR2,
                                  p_db_office_code      IN NUMBER)
   IS
      l_base_parameter_code   NUMBER;
      l_parameter_code        NUMBER;
   BEGIN
      BEGIN
         SELECT base_parameter_code
           INTO l_base_parameter_code
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (p_base_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.RAISE (
               'INVALID_PARAM_ID',
                  p_base_parameter_id
               || SUBSTR ('-', 1, LENGTH (p_sub_parameter_id))
               || p_sub_parameter_id);
      END;

      DELETE FROM at_parameter
            WHERE     base_parameter_code = l_base_parameter_code
                  AND UPPER (sub_parameter_id) =
                         UPPER (TRIM (p_sub_parameter_id))
                  AND db_office_code = p_db_office_code;
   END;

   PROCEDURE delete_parameter_id (p_parameter_id   IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      delete_parameter_id (
         p_base_parameter_id   => cwms_util.get_base_id (p_parameter_id),
         p_sub_parameter_id    => cwms_util.get_sub_id (p_parameter_id),
         p_db_office_code      => cwms_util.get_db_office_code (
                                    p_db_office_id));
   END;


   PROCEDURE rename_parameter_id (
      p_parameter_id_old   IN VARCHAR2,
      p_parameter_id_new   IN VARCHAR2,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_code_all        NUMBER := cwms_util.db_office_code_all;
      l_db_office_code            NUMBER
         := cwms_util.get_db_office_code (p_db_office_id);
      --
      l_db_office_code_old        NUMBER;
      l_base_parameter_code_old   NUMBER;
      l_parameter_code_old        NUMBER;
      l_sub_parameter_id_old      VARCHAR2 (32);
      l_parameter_code_new        NUMBER;
      l_base_parameter_code_new   NUMBER;
      l_base_parameter_id_new     VARCHAR2 (16);
      l_sub_parameter_id_new      VARCHAR2 (32);
      --
      l_new_parameter_id_exists   BOOLEAN := FALSE;
   BEGIN
      SELECT db_office_code,
             base_parameter_code,
             parameter_code,
             sub_parameter_id
        INTO l_db_office_code_old,
             l_base_parameter_code_old,
             l_parameter_code_old,
             l_sub_parameter_id_old
        FROM av_parameter
       WHERE     UPPER (parameter_id) = UPPER (TRIM (p_parameter_id_old))
             AND db_office_code IN (l_db_office_code_all, l_db_office_code);

      IF l_db_office_code_old = l_db_office_code_all
      THEN
         cwms_err.RAISE ('ITEM_OWNED_BY_CWMS', p_parameter_id_old);
      END IF;

      BEGIN
         SELECT base_parameter_code, parameter_code, sub_parameter_id
           INTO l_base_parameter_code_new,
                l_parameter_code_new,
                l_sub_parameter_id_new
           FROM av_parameter
          WHERE     UPPER (parameter_id) = UPPER (TRIM (p_parameter_id_new))
                AND db_office_code IN
                       (l_db_office_code_all, l_db_office_code);

         l_new_parameter_id_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_base_parameter_id_new :=
               cwms_util.get_base_id (cwms_util.strip(p_parameter_id_new));
            l_sub_parameter_id_new :=
               cwms_util.get_sub_id (cwms_util.strip(p_parameter_id_new));

            SELECT base_parameter_code
              INTO l_base_parameter_code_old
              FROM cwms_base_parameter
             WHERE UPPER (base_parameter_id) =
                      UPPER (l_base_parameter_id_new);

            l_parameter_code_new := 0;
      END;


      IF l_new_parameter_id_exists
      THEN
         IF     l_parameter_code_new = l_parameter_code_old
            AND l_sub_parameter_id_old = l_sub_parameter_id_new
         THEN
            cwms_err.RAISE ('CANNOT_RENAME_3', p_parameter_id_new);
         ELSE
            cwms_err.RAISE ('CANNOT_RENAME_2', p_parameter_id_new);
         END IF;
      END IF;

      UPDATE at_parameter
         SET sub_parameter_id = l_sub_parameter_id_new
       WHERE parameter_code = l_parameter_code_old;
   END;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- ZSTORE_TS -
   --
   PROCEDURE zstore_ts (
      p_cwms_ts_id        IN VARCHAR2,
      p_units             IN VARCHAR2,
      p_timeseries_data   IN ztsv_array,
      p_store_rule        IN VARCHAR2,
      p_override_prot     IN VARCHAR2 DEFAULT 'F',
      p_version_date      IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries_data   tsv_array := tsv_array ();
   BEGIN
      l_timeseries_data.EXTEND (p_timeseries_data.COUNT);

      FOR i IN 1 .. p_timeseries_data.COUNT
      LOOP
         l_timeseries_data (i) :=
            tsv_type (
               FROM_TZ (CAST (p_timeseries_data (i).date_time AS TIMESTAMP),
                        'GMT'),
               p_timeseries_data (i).VALUE,
               p_timeseries_data (i).quality_code);
      --         DBMS_OUTPUT.put_line(   l_timeseries_data (i).date_time
      --                              || ' '
      --                              || l_timeseries_data (i).value
      --                              || ' '
      --                              || l_timeseries_data (i).quality_code);
      END LOOP;

      cwms_ts.store_ts (p_cwms_ts_id,
                        p_units,
                        l_timeseries_data,
                        p_store_rule,
                        p_override_prot,
                        p_version_date,
                        p_office_id);
   END zstore_ts;


   PROCEDURE zstore_ts_multi (
      p_timeseries_array   IN ztimeseries_array,
      p_store_rule         IN VARCHAR2,
      p_override_prot      IN VARCHAR2 DEFAULT 'F',
      p_version_date       IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id          IN VARCHAR2 DEFAULT NULL)
   IS
      l_timeseries     ztimeseries_type;
      l_err_msg        VARCHAR2 (722) := NULL;
      l_all_err_msgs   VARCHAR2 (2048) := NULL;
      l_len            NUMBER := 0;
      l_total_len      NUMBER := 0;
      l_num_ts_ids     NUMBER := 0;
      l_num_errors     NUMBER := 0;
      l_excep_errors   NUMBER := 0;
   BEGIN
      DBMS_APPLICATION_INFO.set_module ('cwms_ts.zstore_ts_multi',
                                        'selecting time series from input');

      FOR l_timeseries IN (SELECT * FROM TABLE (p_timeseries_array))
      LOOP
         DBMS_APPLICATION_INFO.set_module ('cwms_ts_store.zstore_ts_multi',
                                           'calling zstore_ts');

         BEGIN
            l_num_ts_ids := l_num_ts_ids + 1;

            cwms_ts.zstore_ts (l_timeseries.tsid,
                               l_timeseries.unit,
                               l_timeseries.data,
                               p_store_rule,
                               p_override_prot,
                               p_version_date,
                               p_office_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_num_errors := l_num_errors + 1;

               l_err_msg :=
                     'STORE_ERROR ***'
                  || l_timeseries.tsid
                  || '*** '
                  || SQLCODE
                  || ': '
                  || SQLERRM;

               IF   NVL (LENGTH (l_all_err_msgs), 0)
                  + NVL (LENGTH (l_err_msg), 0) <= 1930
               THEN
                  l_excep_errors := l_excep_errors + 1;
                  l_all_err_msgs := l_all_err_msgs || ' ' || l_err_msg;
               END IF;
         END;
      END LOOP;

      IF l_all_err_msgs IS NOT NULL
      THEN
         l_all_err_msgs :=
               'STORE ERRORS: zstore_ts_multi processed '
            || l_num_ts_ids
            || ' ts_ids of which '
            || l_num_errors
            || ' had STORE ERRORS. '
            || l_excep_errors
            || ' of those errors are: '
            || l_all_err_msgs;

         raise_application_error (-20999, l_all_err_msgs);
      END IF;

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END zstore_ts_multi;

   PROCEDURE validate_ts_queue_name (p_queue_name IN VARCHAR)
   IS
      l_pattern   CONSTANT VARCHAR2 (39)
                              := '([a-z0-9_$]+\.)?([a-z0-9$]+_)?ts_stored' ;
      l_last               INTEGER := LENGTH (p_queue_name) + 1;
   BEGIN
      IF    REGEXP_INSTR (p_queue_name,
                          l_pattern,
                          1,
                          1,
                          0,
                          'i') != 1
         OR REGEXP_INSTR (p_queue_name,
                          l_pattern,
                          1,
                          1,
                          1,
                          'i') != l_last
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_queue_name,
                         'queue name for (un)registister_ts_callback');
      END IF;
   END validate_ts_queue_name;

   FUNCTION register_ts_callback (
      p_procedure_name    IN VARCHAR2,
      p_subscriber_name   IN VARCHAR2 DEFAULT NULL,
      p_queue_name        IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_queue_name   VARCHAR2 (61) := NVL (p_queue_name, 'ts_stored');
   BEGIN
      validate_ts_queue_name (l_queue_name);
      RETURN cwms_msg.register_msg_callback (p_procedure_name,
                                             l_queue_name,
                                             p_subscriber_name);
   END register_ts_callback;

   PROCEDURE unregister_ts_callback (
      p_procedure_name    IN VARCHAR2,
      p_subscriber_name   IN VARCHAR2,
      p_queue_name        IN VARCHAR2 DEFAULT NULL)
   IS
      l_queue_name   VARCHAR2 (61) := NVL (p_queue_name, 'ts_stored');
   BEGIN
      validate_ts_queue_name (l_queue_name);
      cwms_msg.unregister_msg_callback (p_procedure_name,
                                        l_queue_name,
                                        p_subscriber_name);
   END unregister_ts_callback;

   PROCEDURE refresh_ts_catalog
   IS
   BEGIN
      -- Catalog is now refreshed during the  call to fetch the catalog
      -- cwms_util.refresh_mv_cwms_ts_id;
      NULL;
   END refresh_ts_catalog;

   -------------------------------
   -- Timeseries group routines --
   -------------------------------
   PROCEDURE store_ts_category (
      p_ts_category_id     IN VARCHAR2,
      p_ts_category_desc   IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
      p_ignore_null        IN VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_code   NUMBER (10);
   BEGIN
      l_code :=
         store_ts_category_f (p_ts_category_id,
                              p_ts_category_desc,
                              p_fail_if_exists,
                              p_ignore_null,
                              p_db_office_id);
   END store_ts_category;

   FUNCTION store_ts_category_f (
      p_ts_category_id     IN VARCHAR2,
      p_ts_category_desc   IN VARCHAR2 DEFAULT NULL,
      p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
      p_ignore_null        IN VARCHAR2 DEFAULT 'T',
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code      NUMBER;
      l_ignore_null      BOOLEAN;
      l_fail_if_exists   BOOLEAN;
      l_exists           BOOLEAN;
      l_rec              at_ts_category%ROWTYPE;
   BEGIN
      --------------------
      -- santity checks --
      --------------------
      l_fail_if_exists := cwms_util.is_true (p_fail_if_exists);
      l_ignore_null := cwms_util.is_true (p_ignore_null);
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);
      ----------------------------------
      -- determine if category exists --
      ----------------------------------
      l_rec.ts_category_id := UPPER (cwms_util.strip(p_ts_category_id));

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = l_rec.ts_category_id;

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise ('ITEM_ALREADY_EXISTS',
                            'Time series category',
                            cwms_util.strip(p_ts_category_id));
         ELSE
            IF     l_rec.db_office_code = cwms_util.db_office_code_all
               AND l_office_code != cwms_util.db_office_code_all
            THEN
               cwms_err.raise (
                  'ERROR',
                     'CWMS time series category '
                  || p_ts_category_id
                  || ' can only be updated by owner.');
            END IF;
         END IF;
      END IF;

      -----------------------------------
      -- insert or update the category --
      -----------------------------------
      l_rec.ts_category_id := cwms_util.strip(p_ts_category_id);
      IF NOT l_exists OR p_ts_category_desc IS NOT NULL OR NOT l_ignore_null
      THEN
         l_rec.ts_category_desc := cwms_util.strip(p_ts_category_desc);
      END IF;

      IF l_exists
      THEN
         UPDATE at_ts_category
            SET row = l_rec
          WHERE ts_category_code = l_rec.ts_category_code;
      ELSE
         l_rec.ts_category_code := cwms_seq.NEXTVAL;
         l_rec.db_office_code := l_office_code;

         INSERT INTO at_ts_category
              VALUES l_rec;
      END IF;

      RETURN l_rec.ts_category_code;
   END store_ts_category_f;

   PROCEDURE rename_ts_category (
      p_ts_category_id_old   IN VARCHAR2,
      p_ts_category_id_new   IN VARCHAR2,
      p_db_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code    NUMBER;
      l_category_rec   at_ts_category%ROWTYPE;
   BEGIN
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      --------------------------------------
      -- determine if old category exists --
      --------------------------------------
      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = UPPER (p_ts_category_id_old);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series location category',
                            p_ts_category_id_old);
      END;

      --------------------------------------
      -- determine if new category exists --
      --------------------------------------
      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = UPPER (cwms_util.strip(p_ts_category_id_new));

         cwms_err.raise ('ITEM_ALREADY_EXISTS',
                         'Time series location category',
                         cwms_util.strip(p_ts_category_id_new));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_category_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series category '
            || p_ts_category_id_old
            || ' can only be renamed by owner.');
      END IF;

      -------------------------
      -- rename the category --
      -------------------------
      UPDATE at_ts_category
         SET ts_category_id = cwms_util.strip(p_ts_category_id_new)
       WHERE ts_category_code = l_category_rec.ts_category_code;
   END rename_ts_category;

   PROCEDURE delete_ts_category (p_ts_category_id   IN VARCHAR2,
                                 p_cascade          IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code    NUMBER;
      l_cascade        BOOLEAN;
      l_category_rec   at_ts_category%ROWTYPE;
   BEGIN
      --------------------
      -- santity checks --
      --------------------
      l_cascade := cwms_util.is_true (p_cascade);
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      ----------------------------------
      -- determine if category exists --
      ----------------------------------
      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_ts_category
          WHERE     db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all)
                AND UPPER (ts_category_id) = UPPER (p_ts_category_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series location category',
                            p_ts_category_id);
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_category_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series category '
            || p_ts_category_id
            || ' can only be deleted by owner');
      END IF;

      -----------------
      -- do the work --
      -----------------
      IF l_cascade
      THEN
         ----------------------------------------------------------------------------
         -- delete any groups in the category (will fail if there are assignments) --
         ----------------------------------------------------------------------------
         FOR group_rec
            IN (SELECT ts_group_code
                  FROM at_ts_group
                 WHERE ts_category_code = l_category_rec.ts_category_code)
         LOOP
            FOR assign_rec
               IN (SELECT ts_code
                     FROM at_ts_group_assignment
                    WHERE ts_group_code = group_rec.ts_group_code)
            LOOP
               cwms_err.raise (
                  'ERROR',
                     'Cannot delete time series category '
                  || p_ts_category_id
                  || ' because at least one of its groups is not empty.');
            END LOOP;

            ----------------------
            -- delete the group --
            ----------------------
            DELETE FROM at_ts_group
                  WHERE ts_group_code = group_rec.ts_group_code;
         END LOOP;
      ELSE
         ------------------------------
         -- test for existing groups --
         ------------------------------
         FOR group_rec
            IN (SELECT ts_group_code
                  FROM at_ts_group
                 WHERE ts_category_code = l_category_rec.ts_category_code)
         LOOP
            cwms_err.raise (
               'ERROR',
                  'Cannot delete time series category '
               || p_ts_category_id
               || ' because it is not empty.');
         END LOOP;
      END IF;

      -------------------------
      -- delete the category --
      -------------------------
      DELETE FROM at_ts_category
            WHERE ts_category_code = l_category_rec.ts_category_code;
   END delete_ts_category;

   PROCEDURE store_ts_group (p_ts_category_id     IN VARCHAR2,
                             p_ts_group_id        IN VARCHAR2,
                             p_ts_group_desc      IN VARCHAR2 DEFAULT NULL,
                             p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
                             p_ignore_nulls       IN VARCHAR2 DEFAULT 'T',
                             p_shared_alias_id    IN VARCHAR2 DEFAULT NULL,
                             p_shared_ts_ref_id   IN VARCHAR2 DEFAULT NULL,
                             p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_code   NUMBER (10);
   BEGIN
      l_code :=
         store_ts_group_f (p_ts_category_id,
                           p_ts_group_id,
                           p_ts_group_desc,
                           p_fail_if_exists,
                           p_ignore_nulls,
                           p_shared_alias_id,
                           p_shared_ts_ref_id,
                           p_db_office_id);
   END store_ts_group;

   FUNCTION store_ts_group_f (p_ts_category_id     IN VARCHAR2,
                              p_ts_group_id        IN VARCHAR2,
                              p_ts_group_desc      IN VARCHAR2 DEFAULT NULL,
                              p_fail_if_exists     IN VARCHAR2 DEFAULT 'F',
                              p_ignore_nulls       IN VARCHAR2 DEFAULT 'T',
                              p_shared_alias_id    IN VARCHAR2 DEFAULT NULL,
                              p_shared_ts_ref_id   IN VARCHAR2 DEFAULT NULL,
                              p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code      NUMBER (10);
      l_fail_if_exists   BOOLEAN;
      l_exists           BOOLEAN;
      l_ignore_nulls     BOOLEAN;
      l_rec              at_ts_group%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_fail_if_exists := cwms_util.is_true (p_fail_if_exists);
      l_ignore_nulls := cwms_util.is_true (p_ignore_nulls);
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);
      --------------------------------------------------
      -- get the category code, creating if necessary --
      --------------------------------------------------
      l_rec.ts_category_code :=
         cwms_ts.store_ts_category_f (p_ts_category_id     => p_ts_category_id,
                                      p_ts_category_desc   => NULL,
                                      p_fail_if_exists     => 'F',
                                      p_ignore_null        => 'T',
                                      p_db_office_id       => p_db_office_id);
      -----------------------------------
      -- determine if the group exists --
      -----------------------------------
      l_rec.ts_group_id := cwms_util.strip(p_ts_group_id);

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_ts_group
          WHERE     UPPER (ts_group_id) = UPPER (l_rec.ts_group_id)
                AND ts_category_code = l_rec.ts_category_code
                AND db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF l_exists
      THEN
         IF l_fail_if_exists
         THEN
            cwms_err.raise ('ITEM_ALREADY_EXISTS',
                            'Time series group',
                            cwms_util.strip(p_ts_category_id) || '/' || cwms_util.strip(p_ts_group_id));
         ELSE
            IF     l_rec.db_office_code = cwms_util.db_office_code_all
               AND l_office_code != cwms_util.db_office_code_all
            THEN
               cwms_err.raise (
                  'ERROR',
                     'CWMS time series group '
                  || cwms_util.strip(p_ts_category_id)
                  || '/'
                  || cwms_util.strip(p_ts_group_id)
                  || ' can only be updated by owner.');
            END IF;
         END IF;
      END IF;

      ------------------------
      -- prepare the record --
      ------------------------
      l_rec.db_office_code := l_office_code;

      IF NOT l_exists OR p_ts_group_desc IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.ts_group_desc := cwms_util.strip(p_ts_group_desc);
      END IF;

      IF NOT l_exists OR p_shared_alias_id IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.shared_ts_alias_id := p_shared_alias_id;
      END IF;

      IF NOT l_exists OR p_shared_ts_ref_id IS NOT NULL OR NOT l_ignore_nulls
      THEN
         IF p_shared_ts_ref_id IS NOT NULL
         THEN
            l_rec.shared_ts_ref_code :=
               cwms_ts.get_ts_code (p_shared_ts_ref_id, l_office_code);
         END IF;
      END IF;

      ---------------------------------
      -- update or insert the record --
      ---------------------------------
      IF l_exists
      THEN
         UPDATE at_ts_group
            SET row = l_rec
          WHERE ts_group_code = l_rec.ts_group_code;
      ELSE
         l_rec.ts_group_code := cwms_seq.NEXTVAL;

         INSERT INTO at_ts_group
              VALUES l_rec;
      END IF;

      RETURN l_rec.ts_group_code;
   END store_ts_group_f;

   PROCEDURE rename_ts_group (p_ts_category_id    IN VARCHAR2,
                              p_ts_group_id_old   IN VARCHAR2,
                              p_ts_group_id_new   IN VARCHAR2,
                              p_db_office_id      IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code   NUMBER (10);
      l_rec           at_ts_group%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      -----------------------------------
      -- determine if the group exists --
      -----------------------------------
      BEGIN
         SELECT g.ts_group_code,
                g.ts_category_code,
                g.ts_group_id,
                g.ts_group_desc,
                g.db_office_code,
                g.shared_ts_alias_id,
                g.shared_ts_ref_code
           INTO l_rec
           FROM at_ts_category c, at_ts_group g
          WHERE     UPPER (c.ts_category_id) = UPPER (p_ts_category_id)
                AND UPPER (g.ts_group_id) = UPPER (p_ts_group_id_old)
                AND g.ts_category_code = c.ts_category_code
                AND g.db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series group',
                            p_ts_category_id || '/' || p_ts_group_id_old);
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series group '
            || p_ts_category_id
            || '/'
            || p_ts_group_id_old
            || ' can only be renamed by owner.');
      END IF;

      ----------------------
      -- rename the group --
      ----------------------
      UPDATE at_ts_group
         SET ts_group_id = cwms_util.strip(p_ts_group_id_new)
       WHERE ts_group_code = l_rec.ts_group_code;
   END rename_ts_group;

   PROCEDURE delete_ts_group (p_ts_category_id   IN VARCHAR2,
                              p_ts_group_id      IN VARCHAR2,
                              p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code   NUMBER (10);
      l_rec           at_ts_group%ROWTYPE;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      -----------------------------------
      -- determine if the group exists --
      -----------------------------------
      BEGIN
         SELECT g.ts_group_code,
                g.ts_category_code,
                g.ts_group_id,
                g.ts_group_desc,
                g.db_office_code,
                g.shared_ts_alias_id,
                g.shared_ts_ref_code
           INTO l_rec
           FROM at_ts_category c, at_ts_group g
          WHERE     UPPER (c.ts_category_id) = UPPER (p_ts_category_id)
                AND UPPER (g.ts_group_id) = UPPER (p_ts_group_id)
                AND g.ts_category_code = c.ts_category_code
                AND g.db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series group',
                            p_ts_category_id || '/' || p_ts_group_id);
      END;

      ----------------------------------------
      -- raise exceptions on invalid states --
      ----------------------------------------
      IF     l_rec.db_office_code = cwms_util.db_office_code_all
         AND l_office_code != cwms_util.db_office_code_all
      THEN
         cwms_err.raise (
            'ERROR',
               'CWMS time series group '
            || p_ts_category_id
            || '/'
            || p_ts_group_id
            || ' can only be deleted by owner.');
      END IF;

      FOR rec IN (SELECT ts_code
                    FROM at_ts_group_assignment
                   WHERE ts_group_code = l_rec.ts_group_code)
      LOOP
         cwms_err.raise (
            'ERROR',
               'Cannot delete time series group '
            || p_ts_category_id
            || '/'
            || p_ts_group_id
            || ' because it is not empty.');
      END LOOP;

      ----------------------
      -- delete the group --
      ----------------------
      DELETE FROM at_ts_group
            WHERE ts_group_code = l_rec.ts_group_code;
   END delete_ts_group;

   procedure assign_ts_group (
      p_ts_category_id   in varchar2,
      p_ts_group_id      in varchar2,
      p_ts_id            in varchar2,
      p_ts_attribute     in number default null,
      p_ts_alias_id      in varchar2 default null,
      p_ref_ts_id        in varchar2 default null,
      p_db_office_id     in varchar2 default null)
   is
      l_office_code     number(10);
      l_ts_group_code   number(10);
      l_ts_code         number(10);
      l_ts_ref_code     number(10);
      l_rec             at_ts_group_assignment%rowtype;
      l_exists          boolean;
   begin
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code(p_db_office_id);

      ------------------------
      -- get the group code --
      ------------------------
      begin
         select ts_group_code
           into l_ts_group_code
           from at_ts_category c, at_ts_group g
          where upper(c.ts_category_id) = upper(p_ts_category_id)
            and upper(g.ts_group_id) = upper(p_ts_group_id)
            and g.ts_category_code = c.ts_category_code
            and g.db_office_code in (l_office_code, cwms_util.db_office_code_all);
      exception
         when no_data_found
         then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'Time series group',
               p_ts_category_id || '/' || p_ts_group_id);
      end;

      -----------------------------------------------
      -- determine if an assignment already exists --
      -----------------------------------------------
      l_ts_code := get_ts_code(p_ts_id, l_office_code);

      if p_ref_ts_id is not null then
         l_ts_ref_code := get_ts_code(p_ref_ts_id, l_office_code);
      end if;

      begin
         select *
           into l_rec
           from at_ts_group_assignment
          where ts_code = l_ts_code and ts_group_code = l_ts_group_code;

         l_exists := true;
      exception
         when no_data_found then
            l_exists := false;
      end;

      ------------------------
      -- prepare the record --
      ------------------------
      l_rec.ts_attribute := nvl(p_ts_attribute, l_rec.ts_attribute);
      l_rec.ts_alias_id  := nvl(p_ts_alias_id, l_rec.ts_alias_id);
      l_rec.ts_ref_code  := nvl(l_ts_ref_code, l_rec.ts_ref_code);
      l_rec.office_code  := l_office_code;

      ---------------------------------
      -- insert or update the record --
      ---------------------------------
      if l_exists then
         update at_ts_group_assignment
            set row = l_rec
          where ts_code = l_rec.ts_code
            and ts_group_code = l_rec.ts_group_code;
      else
         l_rec.ts_code := l_ts_code;
         l_rec.ts_group_code := l_ts_group_code;

         insert into at_ts_group_assignment
              values l_rec;
      end if;
   end assign_ts_group;

   PROCEDURE unassign_ts_group (p_ts_category_id   IN VARCHAR2,
                                p_ts_group_id      IN VARCHAR2,
                                p_ts_id            IN VARCHAR2,
                                p_unassign_all     IN VARCHAR2 DEFAULT 'F',
                                p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_code     NUMBER (10);
      l_ts_group_code   NUMBER (10);
      l_ts_code         NUMBER (10);
      l_exists          BOOLEAN;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code (p_db_office_id);

      ------------------------
      -- get the group code --
      ------------------------
      BEGIN
         SELECT ts_group_code
           INTO l_ts_group_code
           FROM at_ts_category c, at_ts_group g
          WHERE     UPPER (c.ts_category_id) = UPPER (p_ts_category_id)
                AND UPPER (g.ts_group_id) = UPPER (p_ts_group_id)
                AND g.ts_category_code = c.ts_category_code
                AND g.db_office_code IN
                       (l_office_code, cwms_util.db_office_code_all);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
                            'Time series group',
                            p_ts_category_id || '/' || p_ts_group_id);
      END;

      ------------------------------
      -- delete the assignment(s) --
      ------------------------------
      IF cwms_util.is_true (p_unassign_all)
      THEN
         DELETE FROM at_ts_group_assignment
               WHERE ts_group_code = l_ts_group_code
                 AND get_db_office_code(ts_code) = l_office_code;
      ELSE
         l_ts_code := get_ts_code (p_ts_id, l_office_code);
         DELETE FROM at_ts_group_assignment
               WHERE ts_group_code = l_ts_group_code
                 AND ts_code = l_ts_code;
      END IF;
   END unassign_ts_group;

   PROCEDURE assign_ts_groups (p_ts_category_id   IN VARCHAR2,
                               p_ts_group_id      IN VARCHAR2,
                               p_ts_alias_array   IN ts_alias_tab_t,
                               p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      IF p_ts_alias_array IS NOT NULL
      THEN
         FOR i IN 1 .. p_ts_alias_array.COUNT
         LOOP
            cwms_ts.assign_ts_group (p_ts_category_id,
                                     p_ts_group_id,
                                     p_ts_alias_array (i).ts_id,
                                     p_ts_alias_array (i).ts_attribute,
                                     p_ts_alias_array (i).ts_alias_id,
                                     p_ts_alias_array (i).ts_ref_id,
                                     p_db_office_id);
         END LOOP;
      END IF;
   END assign_ts_groups;

   PROCEDURE unassign_ts_groups (p_ts_category_id   IN VARCHAR2,
                                 p_ts_group_id      IN VARCHAR2,
                                 p_ts_array         IN str_tab_t,
                                 p_unassign_all     IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      IF p_ts_array IS NULL
      THEN
         cwms_ts.unassign_ts_group (p_ts_category_id,
                                    p_ts_group_id,
                                    NULL,
                                    p_unassign_all,
                                    p_db_office_id);
      ELSE
         FOR i IN 1 .. p_ts_array.COUNT
         LOOP
            cwms_ts.unassign_ts_group (p_ts_category_id,
                                       p_ts_group_id,
                                       p_ts_array (i),
                                       p_unassign_all,
                                       p_db_office_id);
         END LOOP;
      END IF;
   END unassign_ts_groups;

   function get_ts_id_from_alias (
      p_alias_id      in varchar2,
      p_group_id      in varchar2 default null,
      p_category_id   in varchar2 default null,
      p_office_id     in varchar2 default null)
      return varchar2
   is
      l_office_code number(10);
      l_ts_code     number(10);
      l_ts_id       varchar2(183);
      l_parts       str_tab_t;
      l_location_id varchar2(49);
   begin
      -------------------
      -- sanity checks --
      -------------------
      l_office_code := cwms_util.get_db_office_code(p_office_id);

      -----------------------------------
      -- retrieve and return the ts id --
      -----------------------------------
      begin
         select distinct ts_code
           into l_ts_code
           from at_ts_group_assignment a,
                at_ts_group g,
                at_ts_category c
          where a.office_code = l_office_code
            and upper(c.ts_category_id) = upper(nvl(p_category_id, c.ts_category_id))
            and upper(g.ts_group_id) = upper(nvl(p_group_id, g.ts_group_id))
            and upper(a.ts_alias_id) = upper(p_alias_id)
            and g.ts_category_code = c.ts_category_code
            and a.ts_group_code = g.ts_group_code;
      exception
         when no_data_found then
            ------------------------------------
            -- see if the location is aliased --
            ------------------------------------
            l_parts := cwms_util.split_text(p_alias_id, '.');
            if l_parts.count = 6 then
               l_location_id := cwms_loc.get_location_id(l_parts(1), p_office_id);
               if l_location_id is not null and l_location_id != l_parts(1) then
                  l_parts(1) := l_location_id;
                  l_ts_id := cwms_util.join_text(l_parts, '.');
                  l_ts_code := cwms_ts.get_ts_code(l_ts_id, p_office_id);
                  if l_ts_code is null then
                     l_ts_id := null;
                  end if;
               end if;
            end if;
         when too_many_rows
         then
            cwms_err.raise (
               'ERROR',
               'Alias ('
               || p_alias_id
               || ') matches more than one time series.');
      end;

      if l_ts_code is not null and l_ts_id is null then
         l_ts_id := get_ts_id (l_ts_code);
      end if;

      return l_ts_id;
   END get_ts_id_from_alias;


   FUNCTION get_ts_code_from_alias (p_alias_id      IN VARCHAR2,
                                    p_group_id      IN VARCHAR2 DEFAULT NULL,
                                    p_category_id   IN VARCHAR2 DEFAULT NULL,
                                    p_office_id     IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
   BEGIN
      RETURN get_ts_code (get_ts_id_from_alias (p_alias_id,
                                                p_group_id,
                                                p_category_id,
                                                p_office_id),
                          p_office_id);
   END get_ts_code_from_alias;

   FUNCTION get_ts_id (p_ts_id_or_alias IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN VARCHAR2
   IS
      ts_id_not_found   EXCEPTION;
      PRAGMA EXCEPTION_INIT (ts_id_not_found, -20001);
      l_ts_code         NUMBER (10);
      l_ts_id           VARCHAR2 (183);
   BEGIN
      BEGIN
         l_ts_code := get_ts_code (p_ts_id_or_alias, p_office_id);
      EXCEPTION
         WHEN ts_id_not_found
         THEN
            NULL;
      END;

      IF l_ts_code IS NOT NULL
      THEN
         l_ts_id := get_ts_id (l_ts_code);
      END IF;

      RETURN l_ts_id;
   END get_ts_id;

   FUNCTION get_ts_id (p_ts_id_or_alias IN VARCHAR2, p_office_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16);
   BEGIN
      SELECT office_id
        INTO l_office_id
        FROM cwms_office
       WHERE office_code = p_office_code;

      RETURN get_ts_id (p_ts_id_or_alias, l_office_id);
   END get_ts_id;

   ---------------------------
   -- Data quality routines --
   ---------------------------
   FUNCTION get_quality_validity (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
      l_validity   VARCHAR2 (16);
   BEGIN
      SELECT validity_id
        INTO l_validity
        FROM cwms_data_quality
       WHERE quality_code = p_quality_code + case
                                                when p_quality_code < 0 then 4294967296
                                                else  0
                                             end;
      RETURN l_validity;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise('INVALID_ITEM', p_quality_code, 'CWMS quality value');
   END get_quality_validity;

   FUNCTION get_quality_validity (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN get_quality_validity (p_value.quality_code);
   END get_quality_validity;

   FUNCTION get_quality_validity (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN get_quality_validity (p_value.quality_code);
   END get_quality_validity;

   FUNCTION quality_is_okay (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'OKAY';
   END quality_is_okay;

   FUNCTION quality_is_okay (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_okay (p_value.quality_code);
   END quality_is_okay;

   FUNCTION quality_is_okay (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_okay (p_value.quality_code);
   END quality_is_okay;

   FUNCTION quality_is_okay_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'OKAY'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_okay_text;

   FUNCTION quality_is_okay_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_okay_text (p_value.quality_code);
   END quality_is_okay_text;

   FUNCTION quality_is_okay_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_okay_text (p_value.quality_code);
   END quality_is_okay_text;

   FUNCTION quality_is_missing (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'MISSING';
   END quality_is_missing;

   FUNCTION quality_is_missing (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_missing (p_value.quality_code);
   END quality_is_missing;

   FUNCTION quality_is_missing (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_missing (p_value.quality_code);
   END quality_is_missing;

   FUNCTION quality_is_missing_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'MISSING'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;

   END quality_is_missing_text;

   FUNCTION quality_is_missing_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_missing_text (p_value.quality_code);
   END quality_is_missing_text;

   FUNCTION quality_is_missing_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_missing_text (p_value.quality_code);
   END quality_is_missing_text;

   FUNCTION quality_is_questionable (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'QUESTIONABLE';
   END quality_is_questionable;

   FUNCTION quality_is_questionable (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_questionable (p_value.quality_code);
   END quality_is_questionable;

   FUNCTION quality_is_questionable (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_okay (p_value.quality_code);
   END quality_is_questionable;

   FUNCTION quality_is_questionable_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'QUESTIONABLE'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_questionable_text;

   FUNCTION quality_is_questionable_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_questionable_text (p_value.quality_code);
   END quality_is_questionable_text;

   FUNCTION quality_is_questionable_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_questionable_text (p_value.quality_code);
   END quality_is_questionable_text;

   FUNCTION quality_is_rejected (p_quality_code IN NUMBER)
      RETURN BOOLEAN
      result_cache
   IS
   BEGIN
      RETURN get_quality_validity (p_quality_code) = 'REJECTED';
   END quality_is_rejected;

   FUNCTION quality_is_rejected (p_value IN tsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_rejected (p_value.quality_code);
   END quality_is_rejected;

   FUNCTION quality_is_rejected (p_value IN ztsv_type)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN quality_is_rejected (p_value.quality_code);
   END quality_is_rejected;

   FUNCTION quality_is_rejected_text (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      RETURN CASE get_quality_validity (p_quality_code) = 'REJECTED'
                WHEN TRUE  THEN 'T'
                WHEN FALSE THEN 'F'
             END;
   END quality_is_rejected_text;

   FUNCTION quality_is_rejected_text (p_value IN tsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_rejected_text (p_value.quality_code);
   END quality_is_rejected_text;

   FUNCTION quality_is_rejected_text (p_value IN ztsv_type)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN quality_is_rejected_text (p_value.quality_code);
   END quality_is_rejected_text;

   FUNCTION get_quality_description (p_quality_code IN NUMBER)
      RETURN VARCHAR2
      result_cache
   IS
      l_description   VARCHAR2 (4000);
      l_rec           cwms_data_quality%ROWTYPE;
   BEGIN
      SELECT *
        INTO l_rec
        FROM cwms_data_quality
       WHERE quality_code = p_quality_code + case
                                                when p_quality_code < 0 then 4294967296
                                                else  0
                                             end;

      IF l_rec.screened_id = 'UNSCREENED'
      THEN
         l_description := l_rec.screened_id;
      ELSE
         l_description :=
            l_rec.screened_id || ', validity=' || l_rec.validity_id;

         IF l_rec.range_id != 'NO_RANGE'
         THEN
            l_description := l_description || ', range=' || l_rec.range_id;
         END IF;

         IF l_rec.changed_id != 'ORIGINAL'
         THEN
            l_description :=
                  l_description
               || ', '
               || l_rec.changed_id
               || ' (cause='
               || l_rec.repl_cause_id
               || ', method='
               || l_rec.repl_method_id
               || ')';
         END IF;

         IF l_rec.test_failed_id != 'NONE'
         THEN
            l_description :=
               l_description || ', failed=' || l_rec.test_failed_id;
         END IF;

         IF l_rec.protection_id != 'UNPROTECTED'
         THEN
            l_description := l_description || ', ' || l_rec.protection_id;
         END IF;
      END IF;

      l_description := INITCAP (l_description);
      RETURN l_description;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise('INVALID_ITEM', p_quality_code, 'CWMS quality value');
   END get_quality_description;

   FUNCTION get_ts_interval (p_ts_code IN NUMBER)
      RETURN NUMBER result_cache
   IS
      l_interval NUMBER;
   BEGIN
      select interval
        into l_interval
        from cwms_v_ts_id
       where ts_code = p_ts_code;

      return l_interval;
   END get_ts_interval;

   FUNCTION get_ts_interval (p_cwms_ts_id IN VARCHAR2)
      RETURN NUMBER result_cache
   IS
   BEGIN
      RETURN get_interval(get_ts_interval_string(p_cwms_ts_id));
   END get_ts_interval;

   FUNCTION get_ts_interval_string (p_cwms_ts_id IN VARCHAR2)
      RETURN VARCHAR2 result_cache
   IS
   BEGIN
      return regexp_substr (p_cwms_ts_id, '[^.]+', 1, 4);
   END get_ts_interval_string;

   FUNCTION get_interval (p_interval_id IN VARCHAR2)
      RETURN NUMBER result_cache
   IS
      l_interval NUMBER;
   BEGIN
      SELECT interval
        INTO l_interval
        FROM cwms_interval
       WHERE UPPER(interval_id) = UPPER(p_interval_id);

      RETURN l_interval;
   END get_interval;

   FUNCTION get_utc_interval_offset (
      p_date_time_utc    IN DATE,
      p_interval_minutes IN NUMBER)
      RETURN NUMBER result_cache
   IS
   BEGIN
      return round((p_date_time_utc - get_time_on_before_interval(p_date_time_utc, 0, p_interval_minutes)) * 1440);
   END get_utc_interval_offset;

   FUNCTION get_times_for_time_window (
      p_start_time                  IN DATE,
      p_end_time                    IN DATE,
      p_interval_minutes            IN INTEGER,
      p_utc_interval_offset_minutes IN INTEGER,
      p_time_zone                   IN VARCHAR2 DEFAULT 'UTC')
      RETURN date_table_type
   IS
      c_one_month_interval constant integer := 43200;
      c_one_year_interval  constant integer := 525600;
      l_start_time_utc   date;
      l_end_time_utc     date;
      l_months           integer;
      l_valid_interval   boolean := false;
      l_date_times       date_table_type;
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      if p_start_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_START_TIME'); end if;
      if p_end_time is null then cwms_err.raise('NULL_ARGUMENT', 'P_END_TIME'); end if;
      if p_interval_minutes is null then cwms_err.raise('NULL_ARGUMENT', 'P_INTERVAL_MINUTES'); end if;
      if p_utc_interval_offset_minutes is null then cwms_err.raise('NULL_ARGUMENT', 'P_UTC_INTERVAL_OFFSET_MINUTES'); end if;
      if p_start_time > p_end_time then cwms_err.raise('ERROR', 'End time is greater than start time'); end if;
      for rec in (select distinct interval from cwms_interval) loop
         if p_interval_minutes = rec.interval then
            l_valid_interval := true;
            exit;
         end if;
      end loop;
      if not l_valid_interval then
         cwms_err.raise('INVALID_ITEM', p_interval_minutes, 'CWMS interval minutes');
      end if;
      ----------------------------------------------------------------------
      -- get first and last times that are in time window and on interval --
      ----------------------------------------------------------------------
      l_start_time_utc := get_time_on_after_interval(
         cwms_util.change_timezone(p_start_time, p_time_zone, 'UTC'),
         p_utc_interval_offset_minutes,
         p_interval_minutes);
      l_end_time_utc := get_time_on_before_interval(
         cwms_util.change_timezone(p_end_time, p_time_zone, 'UTC'),
         p_utc_interval_offset_minutes,
         p_interval_minutes);
      if l_start_time_utc > l_end_time_utc then cwms_err.raise('ERROR', 'Time window contains no times on interval.'); end if;
      -------------------
      -- get the times --
      -------------------
      if p_interval_minutes >= c_one_month_interval then
         -----------------------
         -- calendar interval --
         -----------------------
         l_months := case mod(p_interval_minutes, c_one_month_interval) = 0
                        when true  then p_interval_minutes / c_one_month_interval
                        when false then p_interval_minutes / c_one_year_interval * 12
                     end;
         select add_months(l_start_time_utc, (level - 1) * l_months)
           bulk collect into l_date_times
           from dual
        connect by level <= months_between(l_end_time_utc, l_start_time_utc) / l_months + 1;
      else
         -------------------
         -- time interval --
         -------------------
         select l_start_time_utc + (level - 1) * p_interval_minutes / 1440
           bulk collect into l_date_times
           from dual
        connect by level <= round((l_end_time_utc - l_start_time_utc) * 1440 / p_interval_minutes + 1);
      end if;
      ----------------------------------------------------------------
      -- convert the times back to the input time zone if necessary --
      ----------------------------------------------------------------
      if p_time_zone != 'UTC' then
         for i in 1..l_date_times.count loop
            l_date_times(i) := cwms_util.change_timezone(l_date_times(i), 'UTC', p_time_zone);
         end loop;
      end if;
      return l_date_times;
   END get_times_for_time_window;

   FUNCTION get_times_for_time_window (
      p_start_time IN DATE,
      p_end_time   IN DATE,
      p_ts_code    IN INTEGER,
      p_time_zone  IN VARCHAR2 DEFAULT 'UTC')
      RETURN date_table_type
   IS
      l_interval INTEGER;
      l_offset   INTEGER;
   BEGIN
      select interval,
             interval_utc_offset
        into l_interval,
             l_offset
        from cwms_v_ts_id
       where ts_code = p_ts_code;

      if l_interval = 0 then
         cwms_err.raise('ERROR', 'Cannot retrieve times for irregular time series.');
      end if;
      if l_offset = cwms_util.utc_offset_undefined then
         cwms_err.raise('ERROR', 'UTC interval offset is undefined for time series');
      end if;

      return get_times_for_time_window(
         p_start_time,
         p_end_time,
         l_interval,
         l_offset,
         p_time_zone);
   END get_times_for_time_window;

   FUNCTION get_times_for_time_window (
      p_start_time IN DATE,
      p_end_time   IN DATE,
      p_ts_id      IN VARCHAR2,
      p_time_zone  IN VARCHAR2 DEFAULT 'UTC',
      p_office_id  IN VARCHAR2 DEFAULT NULL)
      RETURN date_table_type
   IS
   BEGIN
      return get_times_for_time_window(
         p_start_time,
         p_end_time,
         get_ts_code(p_ts_id, p_office_id),
         p_time_zone);
   END get_times_for_time_window;

   FUNCTION get_ts_min_date_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE
   IS
      l_min_date_utc   DATE;
   BEGIN
      FOR rec IN (  SELECT table_name
                      FROM at_ts_table_properties
                  ORDER BY start_date)
      LOOP
         EXECUTE IMMEDIATE
            'select min(date_time)
               from '|| rec.table_name||'
              where ts_code = :1
                and version_date = :2'
            INTO l_min_date_utc
            USING p_ts_code, p_version_date_utc;

         EXIT WHEN l_min_date_utc IS NOT NULL;
      END LOOP;

      RETURN l_min_date_utc;
   END get_ts_min_date_utc;

   FUNCTION get_ts_min_date (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE
   IS
      l_min_date_utc       DATE;
      l_version_date_utc   DATE;
   begin
      IF p_version_date is null or p_version_date = cwms_util.non_versioned
      THEN
         l_version_date_utc := cwms_util.non_versioned;
      ELSE
         l_version_date_utc :=
            cwms_util.change_timezone (p_version_date, p_time_zone, 'UTC');
      END IF;

      l_min_date_utc :=
         get_ts_min_date_utc (
            cwms_ts.get_ts_code (p_cwms_ts_id, p_office_id),
            l_version_date_utc);
      RETURN cwms_util.change_timezone (l_min_date_utc, 'UTC', p_time_zone);
   END get_ts_min_date;


   FUNCTION get_ts_max_date_utc (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned)
      RETURN DATE
   IS
      l_max_date_utc   DATE;
   BEGIN
      FOR rec IN (  SELECT table_name
                      FROM at_ts_table_properties
                  ORDER BY start_date DESC)
      LOOP
         EXECUTE IMMEDIATE
            'select max(date_time)
               from '||rec.table_name||'
              where ts_code = :1
                and version_date = :2'
            INTO l_max_date_utc
            USING p_ts_code, p_version_date_utc;

         EXIT WHEN l_max_date_utc IS NOT NULL;
      END LOOP;

      RETURN l_max_date_utc;
   END get_ts_max_date_utc;
      FUNCTION get_ts_max_date_utc_2 (
      p_ts_code            IN NUMBER,
      p_version_date_utc   IN DATE DEFAULT cwms_util.non_versioned,
      p_year               IN NUMBER DEFAULT NULL)
      RETURN DATE
   IS
      l_max_date_utc   DATE;
   BEGIN
      FOR rec IN (  SELECT table_name
                         , TO_NUMBER(TO_CHAR(start_date, 'YYYY')) table_year
                      FROM at_ts_table_properties
                  ORDER BY start_date DESC)
      LOOP

         CASE
          WHEN p_year IS NULL THEN
          --Process for the max date time for this at_tsv_xxxx table
             BEGIN
               EXECUTE IMMEDIATE
                  'select max(date_time)
                     from '||rec.table_name||'
                    where ts_code = :1
                      and version_date = :2'
                  INTO l_max_date_utc
                  USING p_ts_code, p_version_date_utc;

            EXCEPTION
             WHEN no_data_found THEN
              l_max_date_utc := NULL;
            END;

        WHEN p_year = rec.table_year THEN

          --Process ONLY for one year
          BEGIN
            EXECUTE IMMEDIATE
            'select max(date_time)
               from '||rec.table_name||'
              where ts_code = :1
                and version_date = :2'
            INTO l_max_date_utc
            USING p_ts_code, p_version_date_utc;

        EXCEPTION
         WHEN no_data_found THEN
          l_max_date_utc := NULL;
        END;
        ELSE
          --do nothing
          NULL;

        END CASE;

         EXIT WHEN l_max_date_utc IS NOT NULL;

      END LOOP;

      RETURN l_max_date_utc;
   END get_ts_max_date_utc_2;

   FUNCTION get_ts_max_date (
      p_cwms_ts_id     IN VARCHAR2,
      p_time_zone      IN VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN DATE
   IS
      l_max_date_utc       DATE;
      l_version_date_utc   DATE;
   BEGIN
      IF p_version_date is null or p_version_date = cwms_util.non_versioned
      THEN
         l_version_date_utc := cwms_util.non_versioned;
      ELSE
         l_version_date_utc :=
            cwms_util.change_timezone (p_version_date, p_time_zone, 'UTC');
      END IF;

      l_max_date_utc :=
         get_ts_max_date_utc (
            cwms_ts.get_ts_code (p_cwms_ts_id, p_office_id),
            l_version_date_utc);
      RETURN cwms_util.change_timezone (l_max_date_utc, 'UTC', p_time_zone);
   END get_ts_max_date;


   PROCEDURE get_ts_extents_utc (
      p_min_date_utc          OUT DATE,
      p_max_date_utc          OUT DATE,
      p_ts_code            IN     NUMBER,
      p_version_date_utc   IN     DATE DEFAULT cwms_util.non_versioned)
   IS
   BEGIN
      p_min_date_utc := get_ts_min_date_utc (p_ts_code, p_version_date_utc);
      p_max_date_utc := get_ts_max_date_utc (p_ts_code, p_version_date_utc);
   END get_ts_extents_utc;

   PROCEDURE get_ts_extents (
      p_min_date          OUT DATE,
      p_max_date          OUT DATE,
      p_cwms_ts_id     IN     VARCHAR2,
      p_time_zone      IN     VARCHAR2 DEFAULT 'UTC',
      p_version_date   IN     DATE DEFAULT cwms_util.non_versioned,
      p_office_id      IN     VARCHAR2 DEFAULT NULL)
   IS
      l_min_date_utc       DATE;
      l_max_date_utc       DATE;
      l_version_date_utc   DATE;
   BEGIN
      IF p_version_date IS NULL
      THEN
         l_version_date_utc := cwms_util.non_versioned;
      ELSIF p_version_date = cwms_util.non_versioned
      THEN
         l_version_date_utc := p_version_date;
      ELSE
         l_version_date_utc :=
            cwms_util.change_timezone (p_version_date, p_time_zone, 'UTC');
      END IF;

      get_ts_extents_utc (l_min_date_utc,
                          l_max_date_utc,
                          cwms_ts.get_ts_code (p_cwms_ts_id, p_office_id),
                          l_version_date_utc);
      p_min_date :=
         cwms_util.change_timezone (l_min_date_utc, 'UTC', p_time_zone);
      p_max_date :=
         cwms_util.change_timezone (l_max_date_utc, 'UTC', p_time_zone);
   END get_ts_extents;

   PROCEDURE get_value_extents (p_min_value      OUT BINARY_DOUBLE,
                                p_max_value      OUT BINARY_DOUBLE,
                                p_ts_id       IN     VARCHAR2,
                                p_unit        IN     VARCHAR2,
                                p_min_date    IN     DATE DEFAULT NULL,
                                p_max_date    IN     DATE DEFAULT NULL,
                                p_time_zone   IN     VARCHAR2 DEFAULT NULL,
                                p_office_id   IN     VARCHAR2 DEFAULT NULL)
   IS
      l_min_value      BINARY_DOUBLE;
      l_max_value      BINARY_DOUBLE;
      l_temp_min       BINARY_DOUBLE;
      l_temp_max       BINARY_DOUBLE;
      l_office_id      VARCHAR2 (16);
      l_unit           VARCHAR2 (16);
      l_time_zone      VARCHAR2 (28);
      l_min_date       DATE;
      l_max_date       DATE;
      l_ts_code        NUMBER (10);
      l_parts          str_tab_t;
      l_location_id    VARCHAR2 (49);
      l_parameter_id   VARCHAR2 (49);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      ----------------------------
      -- set values from inputs --
      ----------------------------
      l_office_id := cwms_util.get_db_office_id (p_office_id);
      l_ts_code := cwms_ts.get_ts_code (p_ts_id, l_office_id);
      l_parts := cwms_util.split_text (p_ts_id, '.');
      l_location_id := l_parts (1);
      l_parameter_id := l_parts (2);
      l_unit := cwms_util.get_default_units (l_parameter_id);
      l_time_zone :=
         CASE p_time_zone IS NULL
            WHEN TRUE
            THEN
               cwms_loc.get_local_timezone (l_location_id, l_office_id)
            WHEN FALSE
            THEN
               p_time_zone
         END;
      l_min_date :=
         CASE p_min_date IS NULL
            WHEN TRUE
            THEN
               DATE '1700-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_min_date, l_time_zone, 'UTC')
         END;
      l_max_date :=
         CASE p_max_date IS NULL
            WHEN TRUE
            THEN
               DATE '2100-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_max_date, l_time_zone, 'UTC')
         END;

      -----------------------
      -- perform the query --
      -----------------------
      FOR rec IN (  SELECT table_name, start_date, end_date
                      FROM at_ts_table_properties
                  ORDER BY start_date)
      LOOP
         CONTINUE WHEN    rec.start_date > l_max_date
                       OR rec.end_date < l_min_date;

         BEGIN
            EXECUTE IMMEDIATE
               'select min(value),
                       max(value)
                  from '||rec.table_name||'
                 where ts_code = :1
                   and date_time between :2 and :3'
               INTO l_temp_min, l_temp_max
               USING l_ts_code, l_min_date, l_max_date;

            IF l_min_value IS NULL OR l_temp_min < l_min_value
            THEN
               l_min_value := l_temp_min;
            END IF;

            IF l_max_value IS NULL OR l_temp_max > l_max_value
            THEN
               l_max_value := l_temp_max;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;
      END LOOP;

      IF l_min_value IS NOT NULL
      THEN
         p_min_value := cwms_util.convert_units (l_min_value, l_unit, p_unit);
      END IF;

      IF l_max_value IS NOT NULL
      THEN
         p_max_value := cwms_util.convert_units (l_max_value, l_unit, p_unit);
      END IF;
   END get_value_extents;

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
      p_office_id        IN     VARCHAR2 DEFAULT NULL)
   IS
      l_min_value        BINARY_DOUBLE;
      l_max_value        BINARY_DOUBLE;
      l_temp_min         BINARY_DOUBLE;
      l_temp_max         BINARY_DOUBLE;
      l_min_value_date   DATE;
      l_max_value_date   DATE;
      l_temp_min_date    DATE;
      l_temp_max_date    DATE;
      l_office_id        VARCHAR2 (16);
      l_unit             VARCHAR2 (16);
      l_time_zone        VARCHAR2 (28);
      l_min_date         DATE;
      l_max_date         DATE;
      l_ts_code          NUMBER (10);
      l_parts            str_tab_t;
      l_location_id      VARCHAR2 (49);
      l_parameter_id     VARCHAR2 (49);
   BEGIN
      ----------------------------
      -- set values from inputs --
      ----------------------------
      l_office_id := cwms_util.get_db_office_id (p_office_id);
      l_ts_code := cwms_ts.get_ts_code (p_ts_id, l_office_id);
      l_parts := cwms_util.split_text (p_ts_id, '.');
      l_location_id := l_parts (1);
      l_parameter_id := l_parts (2);
      l_unit := cwms_util.get_default_units (l_parameter_id);
      l_time_zone :=
         CASE p_time_zone IS NULL
            WHEN TRUE
            THEN
               cwms_loc.get_local_timezone (l_location_id, l_office_id)
            WHEN FALSE
            THEN
               p_time_zone
         END;
      l_min_date :=
         CASE p_min_date IS NULL
            WHEN TRUE
            THEN
               DATE '1700-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_min_date, l_time_zone, 'UTC')
         END;
      l_max_date :=
         CASE p_max_date IS NULL
            WHEN TRUE
            THEN
               DATE '2100-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_max_date, l_time_zone, 'UTC')
         END;

      -----------------------
      -- perform the query --
      -----------------------
      FOR rec IN (  SELECT table_name, start_date, end_date
                      FROM at_ts_table_properties
                  ORDER BY start_date)
      LOOP
         CONTINUE WHEN    rec.start_date > l_max_date
                       OR rec.end_date < l_min_date;

         BEGIN
            EXECUTE IMMEDIATE
               'select date_time,
                       value
                  from '||rec.table_name||'
                 where ts_code = :1
                   and date_time between :2 and :3
                   and value = (select min(value)
                                  from '||rec.table_name||'
                                 where ts_code = :4
                                   and date_time between :5 and :6
                               )
                   and rownum = 1'
               INTO l_temp_min_date, l_temp_min
               USING l_ts_code,
                     l_min_date,
                     l_max_date,
                     l_ts_code,
                     l_min_date,
                     l_max_date;

            IF l_min_value IS NULL OR l_temp_min < l_min_value
            THEN
               l_min_value_date := l_temp_min_date;
               l_min_value := l_temp_min;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE
               'select date_time,
                       value
                  from '||rec.table_name||'
                 where ts_code = :1
                   and date_time between :2 and :3
                   and value = (select max(value)
                                  from '||rec.table_name||'
                                 where ts_code = :4
                                   and date_time between :5 and :6
                               )
                   and rownum = 1'
               INTO l_temp_max_date, l_temp_max
               USING l_ts_code,
                     l_min_date,
                     l_max_date,
                     l_ts_code,
                     l_min_date,
                     l_max_date;

            IF l_max_value IS NULL OR l_temp_max > l_max_value
            THEN
               l_max_value_date := l_temp_max_date;
               l_max_value := l_temp_max;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;
      END LOOP;

      IF l_min_value IS NOT NULL
      THEN
         p_min_value := cwms_util.convert_units (l_min_value, l_unit, p_unit);
         p_min_value_date :=
            cwms_util.change_timezone (l_min_value_date, 'UTC', l_time_zone);
      END IF;

      IF l_max_value IS NOT NULL
      THEN
         p_max_value := cwms_util.convert_units (l_max_value, l_unit, p_unit);
         p_max_value_date :=
            cwms_util.change_timezone (l_max_value_date, 'UTC', l_time_zone);
      END IF;
   END get_value_extents;

   FUNCTION get_values_in_range (p_ts_id       IN VARCHAR2,
                                 p_min_value   IN BINARY_DOUBLE,
                                 p_max_value   IN BINARY_DOUBLE,
                                 p_unit        IN VARCHAR2,
                                 p_min_date    IN DATE DEFAULT NULL,
                                 p_max_date    IN DATE DEFAULT NULL,
                                 p_time_zone   IN VARCHAR2 DEFAULT NULL,
                                 p_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN ztsv_array
   IS
   BEGIN
      RETURN get_values_in_range (time_series_range_t (p_office_id,
                                                       p_ts_id,
                                                       p_min_date,
                                                       p_max_date,
                                                       p_time_zone,
                                                       p_min_value,
                                                       p_max_value,
                                                       p_unit));
   END;

   FUNCTION get_values_in_range (p_criteria IN time_series_range_t)
      RETURN ztsv_array
   IS
      l_results         ztsv_array;
      l_table_results   ztsv_array;
      l_office_id       VARCHAR2 (16);
      l_unit            VARCHAR2 (16);
      l_time_zone       VARCHAR2 (28);
      l_min_value       BINARY_DOUBLE;
      l_max_value       BINARY_DOUBLE;
      l_min_date        DATE;
      l_max_date        DATE;
      l_ts_code         NUMBER (10);
      l_parts           str_tab_t;
      l_location_id     VARCHAR2 (49);
      l_parameter_id    VARCHAR2 (49);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      ----------------------------
      -- set values from inputs --
      ----------------------------
      l_office_id := cwms_util.get_db_office_id (p_criteria.office_id);
      l_ts_code :=
         cwms_ts.get_ts_code (p_criteria.time_series_id, l_office_id);
      l_parts := cwms_util.split_text (p_criteria.time_series_id, '.');
      l_location_id := l_parts (1);
      l_parameter_id := l_parts (2);
      l_unit := cwms_util.get_default_units (l_parameter_id);
      l_min_value :=
         CASE p_criteria.minimum_value IS NULL
            WHEN TRUE
            THEN
               -binary_double_max_normal
            WHEN FALSE
            THEN
               cwms_util.convert_units (p_criteria.minimum_value,
                                        p_criteria.unit,
                                        l_unit)
         END;
      l_max_value :=
         CASE p_criteria.maximum_value IS NULL
            WHEN TRUE
            THEN
               binary_double_max_normal
            WHEN FALSE
            THEN
               cwms_util.convert_units (p_criteria.maximum_value,
                                        p_criteria.unit,
                                        l_unit)
         END;
      l_time_zone :=
         CASE p_criteria.time_zone IS NULL
            WHEN TRUE
            THEN
               cwms_loc.get_local_timezone (l_location_id, l_office_id)
            WHEN FALSE
            THEN
               p_criteria.time_zone
         END;
      l_min_date :=
         CASE p_criteria.start_time IS NULL
            WHEN TRUE
            THEN
               DATE '1700-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_criteria.start_time,
                                          l_time_zone,
                                          'UTC')
         END;
      l_max_date :=
         CASE p_criteria.end_time IS NULL
            WHEN TRUE
            THEN
               DATE '2100-01-01'
            WHEN FALSE
            THEN
               cwms_util.change_timezone (p_criteria.end_time,
                                          l_time_zone,
                                          'UTC')
         END;

      -----------------------
      -- perform the query --
      -----------------------
      IF     p_criteria.minimum_value IS NULL
         AND p_criteria.maximum_value IS NULL
      THEN
         -----------------------------
         -- just call retrieve_ts() --
         -----------------------------
         DECLARE
            l_cursor      SYS_REFCURSOR;
            l_dates       date_table_type;
            l_values      double_tab_t;
            l_qualities   number_tab_t;
         BEGIN
            retrieve_ts (p_at_tsv_rc         => l_cursor,
                         p_cwms_ts_id        => p_criteria.time_series_id,
                         p_units             => l_unit,
                         p_start_time        => l_min_date,
                         p_end_time          => l_max_date,
                         p_time_zone         => 'UTC',
                         p_trim              => 'T',
                         p_start_inclusive   => 'T',
                         p_end_inclusive     => 'T',
                         p_previous          => 'F',
                         p_next              => 'F',
                         p_version_date      => NULL,
                         p_max_version       => 'T',
                         p_office_id         => l_office_id);

            FETCH l_cursor
            BULK COLLECT INTO l_dates, l_values, l_qualities;

            CLOSE l_cursor;

            IF l_dates IS NOT NULL AND l_dates.COUNT > 0
            THEN
               l_results := ztsv_array ();
               l_results.EXTEND (l_dates.COUNT);

               FOR i IN 1 .. l_dates.COUNT
               LOOP
                  l_results (i) :=
                     ztsv_type (
                        cwms_util.change_timezone (l_dates (i),
                                                   'UTC',
                                                   l_time_zone),
                        l_values (i),
                        l_qualities (i));
               END LOOP;
            END IF;
         END;
      ELSE
         ---------------------------------------
         -- find the values that are in range --
         ---------------------------------------
         FOR rec IN (  SELECT table_name, start_date, end_date
                         FROM at_ts_table_properties
                     ORDER BY start_date)
         LOOP
            CONTINUE WHEN    rec.start_date > l_max_date
                          OR rec.end_date < l_min_date;

            BEGIN
               EXECUTE IMMEDIATE
                  'select ztsv_type(date_time, value, quality_code)
                    from '||rec.table_name||'
                   where ts_code = :1
                     and date_time between :1 and :2
                     and value between :3 and :4'
                  BULK COLLECT INTO l_table_results
                  USING l_ts_code,
                        l_min_date,
                        l_max_date,
                        l_min_value,
                        l_max_value;

               IF l_results IS NULL
               THEN
                  l_results := ztsv_array ();
               END IF;

               l_results.EXTEND (l_table_results.COUNT);

               FOR i IN 1 .. l_table_results.COUNT
               LOOP
                  l_table_results (i).date_time :=
                     cwms_util.change_timezone (
                        l_table_results (i).date_time,
                        'UTC',
                        l_time_zone);
                  l_table_results (i).VALUE :=
                     cwms_util.convert_units (l_table_results (i).VALUE,
                                              l_unit,
                                              p_criteria.unit);
                  l_results (l_results.COUNT - l_table_results.COUNT + i) :=
                     l_table_results (i);
               END LOOP;

               l_table_results.delete;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
         END LOOP;
      END IF;

      RETURN l_results;
   END get_values_in_range;

   FUNCTION get_values_in_range (p_criteria IN time_series_range_tab_t)
      RETURN ztsv_array_tab
   IS
      TYPE index_by_date_t IS TABLE OF INTEGER
                                 INDEX BY VARCHAR (12);

      TYPE index_by_date_tab_t IS TABLE OF index_by_date_t;

      c_date_fmt   CONSTANT VARCHAR2 (14) := 'yyyymmddhh24mi';
      l_criteria            time_series_range_tab_t := p_criteria;
      l_original_results    ztsv_array_tab := ztsv_array_tab ();
      l_results             ztsv_array_tab := ztsv_array_tab ();
      l_common_dates        index_by_date_t;
      l_individual_dates    index_by_date_tab_t := index_by_date_tab_t ();
      l_count               PLS_INTEGER;
      l_date                VARCHAR2 (12);
      l_dates               date_table_type := date_table_type ();
      l_min_date            DATE;
      l_max_date            DATE;
   BEGIN
      IF l_criteria IS NOT NULL
      THEN
         l_count := l_criteria.COUNT;
         l_individual_dates.EXTEND (l_count);
         l_original_results.EXTEND (l_count);
         l_results.EXTEND (l_count);

         ------------------------------------------------------
         -- get the data for each individual criteria object --
         ------------------------------------------------------
         FOR i IN 1 .. l_count
         LOOP
            IF l_min_date IS NOT NULL
            THEN
               l_criteria (i).start_time :=
                  GREATEST (l_criteria (i).start_time, l_min_date);
            END IF;

            IF l_max_date IS NOT NULL
            THEN
               l_criteria (i).start_time :=
                  LEAST (l_criteria (i).start_time, l_max_date);
            END IF;

            l_original_results (i) := get_values_in_range (l_criteria (i));

            IF     l_original_results (i) IS NOT NULL
               AND l_original_results (i).COUNT > 0
            THEN
               IF l_original_results (i) (1).date_time > l_min_date
               THEN
                  l_min_date := l_original_results (i) (1).date_time;
               END IF;

               IF l_original_results (i) (l_original_results (i).COUNT).date_time <
                     l_max_date
               THEN
                  l_max_date :=
                     l_original_results (i) (l_original_results (i).COUNT).date_time;
               END IF;

               FOR j IN 1 .. l_original_results (i).COUNT
               LOOP
                  l_date :=
                     TO_CHAR (l_original_results (i) (j).date_time,
                              c_date_fmt);
                  l_common_dates (l_date) := 0;
                  l_individual_dates (i) (l_date) := j;
               END LOOP;
            END IF;
         END LOOP;

         --------------------------------------------------------
         -- determine the times that are common to all results --
         --------------------------------------------------------
         FOR i IN 1 .. l_count
         LOOP
            EXIT WHEN l_common_dates.COUNT = 0;
            l_date := l_common_dates.LAST;

            LOOP
               EXIT WHEN l_date IS NULL;

               IF NOT l_individual_dates (i).EXISTS (l_date)
               THEN
                  l_common_dates.delete (l_date);
               END IF;

               l_date := l_common_dates.PRIOR (l_date);
            END LOOP;
         END LOOP;

         ------------------------------------------------
         -- build the result set from the common times --
         ------------------------------------------------
         IF l_common_dates.COUNT > 0
         THEN
            FOR i IN 1 .. l_count
            LOOP
               l_results (i) := ztsv_array ();
               l_date := l_common_dates.FIRST;

               LOOP
                  EXIT WHEN l_date IS NULL;
                  l_results (i).EXTEND;
                  l_results (i) (l_results (i).COUNT) :=
                     l_original_results (i) (l_individual_dates (i) (l_date));
                  l_date := l_common_dates.NEXT (l_date);
               END LOOP;
            END LOOP;
         END IF;
      END IF;

      RETURN l_results;
   END get_values_in_range;

   PROCEDURE trim_ts_deleted_times
   IS
      l_millis_count   NUMBER (14);
      l_millis_date    NUMBER (14);
      l_count          NUMBER;
      l_count2         NUMBER;
      l_max_count      NUMBER;
      l_max_days       NUMBER;
      l_office_id      VARCHAR2 (16) := cwms_util.user_office_id;
   BEGIN
      cwms_msg.log_db_message ('TRIM_TS_DELETED_TIMES',
                               cwms_msg.msg_level_basic,
                               'Start trimming AT_TS_DELETED_TIMES entries');
      ---------------------------------------
      -- get the count and date properties --
      ---------------------------------------
      l_max_count :=
         TO_NUMBER (cwms_properties.get_property (
                       'CWMSDB',
                       'ts_deleted.table.max_entries',
                       '1000000',
                       l_office_id));
      l_max_days :=
         TO_NUMBER (cwms_properties.get_property ('CWMSDB',
                                                  'ts_deleted.table.max_age',
                                                  '7',
                                                  l_office_id));

      -------------------------------------------
      -- determine the millis cutoff for count --
      -------------------------------------------
      SELECT COUNT (*) INTO l_count FROM at_ts_deleted_times;

      cwms_msg.log_db_message (
         'TRIM_TS_DELETED_TIMES',
         cwms_msg.msg_level_detailed,
         'AT_TS_DELETED_TIMES has ' || l_count || ' records.');

      IF l_count > l_max_count
      THEN
         SELECT deleted_time
           INTO l_millis_count
           FROM (  SELECT deleted_time, ROWNUM AS rn
                     FROM at_ts_deleted_times
                 ORDER BY deleted_time DESC)
          WHERE rn = TRUNC (l_max_count);
      END IF;

      ------------------------------------------
      -- determine the millis cutoff for date --
      ------------------------------------------
      l_millis_date :=
         cwms_util.to_millis (
              SYSTIMESTAMP AT TIME ZONE 'UTC'
            - NUMTODSINTERVAL (l_max_days, 'DAY'));

      --------------------
      -- trim the table --
      --------------------
      DELETE FROM at_ts_deleted_times
            WHERE deleted_time < GREATEST (l_millis_count, l_millis_date);

      SELECT COUNT (*) INTO l_count2 FROM at_ts_deleted_times;

      l_count := l_count - l_count2;
      cwms_msg.log_db_message (
         'TRIM_TS_DELETED_TIMES',
         cwms_msg.msg_level_detailed,
         'Deleted ' || l_count || ' records from AT_TS_DELETED_TIMES');

      cwms_msg.log_db_message ('TRIM_TS_DELETED_TIMES',
                               cwms_msg.msg_level_basic,
                               'Done trimming AT_TS_DELETED_TIMES entries');
   END trim_ts_deleted_times;

   PROCEDURE start_trim_ts_deleted_job
   IS
      l_count          BINARY_INTEGER;
      l_user_id        VARCHAR2 (30);
      l_job_id         VARCHAR2 (30) := 'TRIM_TS_DELETED_TIMES_JOB';
      l_run_interval   VARCHAR2 (8);
      l_comment        VARCHAR2 (256);

      FUNCTION job_count
         RETURN BINARY_INTEGER
      IS
      BEGIN
         SELECT COUNT (*)
           INTO l_count
           FROM sys.dba_scheduler_jobs
          WHERE job_name = l_job_id AND owner = l_user_id;

         RETURN l_count;
      END;
   BEGIN
      --------------------------------------
      -- make sure we're the correct user --
      --------------------------------------
      l_user_id := cwms_util.get_user_id;

      IF UPPER (l_user_id) != UPPER ('CWMS_20')
      THEN
         DBMS_OUTPUT.put_line ('User ID = ' || l_user_id);
         DBMS_OUTPUT.put_line ('Must be : ' || 'CWMS_20');
         raise_application_error (
            -20999,
            'Must be CWMS_20 user to start job ' || l_job_id,
            TRUE);
      END IF;

      -------------------------------------------
      -- drop the job if it is already running --
      -------------------------------------------
      IF job_count > 0
      THEN
         DBMS_OUTPUT.put ('Dropping existing job ' || l_job_id || '...');
         DBMS_SCHEDULER.drop_job (l_job_id);

         --------------------------------
         -- verify that it was dropped --
         --------------------------------
         IF job_count = 0
         THEN
            DBMS_OUTPUT.put_line ('done.');
         ELSE
            DBMS_OUTPUT.put_line ('failed.');
         END IF;
      END IF;

      IF job_count = 0
      THEN
         BEGIN
            ---------------------
            -- restart the job --
            ---------------------
            cwms_properties.get_property (l_run_interval,
                                          l_comment,
                                          'CWMSDB',
                                          'ts_deleted.auto_trim.interval',
                                          '15',
                                          'CWMS');
            DBMS_SCHEDULER.create_job (
               job_name          => l_job_id,
               job_type          => 'stored_procedure',
               job_action        => 'cwms_ts.trim_ts_deleted_times',
               start_date        => NULL,
               repeat_interval   =>    'freq=minutely; interval='
                                    || l_run_interval,
               end_date          => NULL,
               job_class         => 'default_job_class',
               enabled           => TRUE,
               auto_drop         => FALSE,
               comments          => 'Trims at_ts_deleted_times to specified max entries and max age.');

            IF job_count = 1
            THEN
               DBMS_OUTPUT.put_line (
                     'Job '
                  || l_job_id
                  || ' successfully scheduled to execute every '
                  || l_run_interval
                  || ' minutes.');
            ELSE
               cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               cwms_err.raise ('ITEM_NOT_CREATED',
                               'job',
                               l_job_id || ':' || SQLERRM);
         END;
      END IF;
   END start_trim_ts_deleted_job;

   FUNCTION get_associated_timeseries (
      p_location_id         IN VARCHAR2,
      p_association_type    IN VARCHAR2,
      p_usage_category_id   IN VARCHAR2,
      p_usage_id            IN VARCHAR2,
      p_office_id           IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   AS
      l_office_id   VARCHAR2 (16);
      l_tsid        VARCHAR2 (183);
   BEGIN
      l_office_id := cwms_util.get_db_office_id (p_office_id);

      ----------------------------------------------------------------------------
      -- retrieve the associated time series with specified or default location --
      ----------------------------------------------------------------------------
      BEGIN
         SELECT timeseries_id
           INTO l_tsid
           FROM (  SELECT timeseries_id
                     FROM cwms_v_ts_association
                    WHERE     UPPER (association_id) IN
                                 ('?GLOBAL?', UPPER (p_location_id))
                          AND association_type = UPPER (p_association_type)
                          AND UPPER (usage_category_id) =
                                 UPPER (p_usage_category_id)
                          AND UPPER (usage_id) = UPPER (p_usage_id)
                          AND office_id = l_office_id
                 ORDER BY association_id DESC -- '?GLOBAL?' sorts after actual location
                )
          WHERE ROWNUM < 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               'No such time series association: '''
               || l_office_id
               || '/'
               || '?GLOBAL?/'
               || p_association_type
               || '/'
               || p_usage_category_id
               || '/'
               || p_usage_id
               || '''');
      END get_associated_timeseries;

      ---------------------------------------
      -- return the associated time series --
      ---------------------------------------
      RETURN REPLACE (l_tsid, '?GLOBAL?', p_location_id);
   END;

   procedure set_retrieve_unsigned_quality
   is
   begin
      cwms_util.set_session_info('UNSIGNED QUALITY', 'T');
   end set_retrieve_unsigned_quality;

   procedure set_retrieve_signed_quality
   is
   begin
      cwms_util.reset_session_info('UNSIGNED QUALITY');
   end set_retrieve_signed_quality;

   function normalize_quality(
      p_quality in number)
      return number
      result_cache
   is
      l_quality number;
   begin
      case cwms_util.get_session_info_txt('UNSIGNED QUALITY')
         when 'T' then
            if p_quality < 0 then
               l_quality := 4294967296 + p_quality;
            else
               l_quality := p_quality;
            end if;
         else
            if p_quality > 2147483647 then
               l_quality := p_quality - 4294967296;
            else
               l_quality := p_quality;
            end if;
      end case;
      return l_quality;
   end normalize_quality;

   procedure set_nulls_storage_policy_ofc(
      p_storage_policy in integer,
      p_office_id      in varchar2 default null)
   as
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_storage_policy is not null and
         p_storage_policy not in (
            filter_out_null_values,
            set_null_values_to_missing,
            reject_ts_with_null_values)
      then
         cwms_err.raise(
            'ERROR',
            'P_STORAGE_POLICY must be one of FILTER_OUT_NULL_VALUES, SET_NULL_VALUES_TO_MISSING, or REJECT_TS_WITH_NULL_VALUES');
      end if;
      cwms_msg.log_db_message(
         'CWMS_TS.SET_NULLS_STORAGE_POLICY',
         cwms_msg.msg_level_normal,
         'Setting NULLs storage policy to '
         || case p_storage_policy is null
               when true then 'NULL'
               else case p_storage_policy
               	      when filter_out_null_values then
               	         'FILTER_OUT_NULL_VALUES'
               	      when set_null_values_to_missing then
               	      	 'SET_NULL_VALUES_TO_MISSING'
               	      when reject_ts_with_null_values then
               	      	 'REJECT_TS_WITH_NULL_VALUES'
                    end
            end
         ||' for office '
         ||cwms_util.get_db_office_id(p_office_id));
      if p_storage_policy is null then
         cwms_properties.delete_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.office.'||cwms_util.get_db_office_code(p_office_id),
            p_office_id => 'CWMS');
      else
         cwms_properties.set_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.office.'||cwms_util.get_db_office_code(p_office_id),
            p_value     => p_storage_policy,
            p_comment   => null,
            p_office_id => 'CWMS');
      end if;
   end set_nulls_storage_policy_ofc;

   procedure set_nulls_storage_policy_ts(
      p_storage_policy in integer,
      p_ts_id          in varchar2,
      p_office_id      in varchar2 default null)
   as
   begin
      ------------------
      -- sanity check --
      ------------------
      if p_storage_policy is not null and
         p_storage_policy not in (
            filter_out_null_values,
            set_null_values_to_missing,
            reject_ts_with_null_values)
      then
         cwms_err.raise(
            'ERROR',
            'P_STORAGE_POLICY must be one of FILTER_OUT_NULL_VALUES, SET_NULL_VALUES_TO_MISSING, or REJECT_TS_WITH_NULL_VALUES');
      end if;
      cwms_msg.log_db_message(
         'CWMS_TS.SET_NULLS_STORAGE_POLICY',
         cwms_msg.msg_level_normal,
         'Setting NULLs storage policy to '
         || case p_storage_policy is null
               when true then 'NULL'
               else case p_storage_policy
               	      when filter_out_null_values then
               	         'FILTER_OUT_NULL_VALUES'
               	      when set_null_values_to_missing then
               	      	 'SET_NULL_VALUES_TO_MISSING'
               	      when reject_ts_with_null_values then
               	      	 'REJECT_TS_WITH_NULL_VALUES'
                    end
            end
         ||' for time seires '
         ||cwms_util.get_db_office_id(p_office_id)
         ||'/'
         ||p_ts_id
         ||' ('
         ||get_ts_code(p_ts_id, p_office_id)
         ||')');
      if p_storage_policy is null then
         cwms_properties.delete_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.tscode.'||get_ts_code(p_ts_id, p_office_id),
            p_office_id => 'CWMS');
      else
         cwms_properties.set_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.tscode.'||get_ts_code(p_ts_id, p_office_id),
            p_value     => p_storage_policy,
            p_comment   => null,
            p_office_id => 'CWMS');

      end if;
   end set_nulls_storage_policy_ts;

   function get_nulls_storage_policy_ofc(
      p_office_id in varchar2 default null)
      return integer
   as
   begin
      return cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.nulls.office.'||cwms_util.get_db_office_code(p_office_id),
         p_default   => null,
         p_office_id => 'CWMS');
   end get_nulls_storage_policy_ofc;

   function get_nulls_storage_policy_ts(
      p_ts_id     in varchar2,
      p_office_id in varchar2 default null)
      return integer
   as
   begin
      return cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.nulls.tscode.'||get_ts_code(p_ts_id, p_office_id),
         p_default   => null,
         p_office_id => 'CWMS');
   end get_nulls_storage_policy_ts;

   function get_nulls_storage_policy(
      p_ts_code in integer)
      return integer
   as
      l_policy      integer;
      l_office_code integer;
   begin
      l_policy := cwms_properties.get_property(
         p_category  => 'TIMESERIES',
         p_id        => 'storage.nulls.tscode.'||p_ts_code,
         p_default   => null,
         p_office_id => 'CWMS');
      if l_policy is null then
         select bl.db_office_code
           into l_office_code
           from at_cwms_ts_spec ts,
                at_physical_location pl,
                at_base_location bl
          where ts.ts_code = p_ts_code
            and pl.location_code = ts.location_code
            and bl.base_location_code = pl.base_location_code;
         l_policy := cwms_properties.get_property(
            p_category  => 'TIMESERIES',
            p_id        => 'storage.nulls.office.'||l_office_code,
            p_default   => null,
            p_office_id => 'CWMS');
         if l_policy is null then
            l_policy := filter_out_null_values;
         end if;
      end if;
      return l_policy;
   end get_nulls_storage_policy;


END cwms_ts;
/

---------------------------
--Changed PACKAGE BODY
--CWMS_STREAM
---------------------------
CREATE OR REPLACE PACKAGE BODY "CWMS_STREAM" 
AS
--------------------------------------------------------------------------------
-- function get_stream_code
--------------------------------------------------------------------------------
   FUNCTION get_stream_code (p_office_id   IN VARCHAR2,
                             p_stream_id   IN VARCHAR2)
      RETURN NUMBER
   IS
      l_location_code   NUMBER (10);
   BEGIN
      BEGIN
         l_location_code :=
            cwms_loc.get_location_code (p_office_id, p_stream_id);

         SELECT stream_location_code
           INTO l_location_code
           FROM at_stream
          WHERE stream_location_code = l_location_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
            'CWMS stream identifier.',
                            p_office_id || '/' || p_stream_id);
      END;

      RETURN l_location_code;
   END get_stream_code;

--------------------------------------------------------------------------------
-- procedure store_stream
--------------------------------------------------------------------------------
procedure store_stream(
   p_stream_id            in varchar2,
   p_fail_if_exists       in varchar2,
   p_ignore_nulls         in varchar2,
   p_station_unit         in varchar2 default null,
   p_stationing_starts_ds in varchar2 default null,
   p_flows_into_stream    in varchar2 default null,
   p_flows_into_station   in binary_double default null,
   p_flows_into_bank      in varchar2 default null,
   p_diverts_from_stream  in varchar2 default null,
   p_diverts_from_station in binary_double default null,
   p_diverts_from_bank    in varchar2 default null,
   p_length               in binary_double default null,
   p_average_slope        in binary_double default null,
   p_comments             in varchar2 default null,
   p_office_id            in varchar2 default null)
is
   l_fail_if_exists        boolean := cwms_util.is_true(p_fail_if_exists);
   l_ignore_nulls          boolean := cwms_util.is_true(p_ignore_nulls);
   l_exists                boolean;
   l_base_location_code    number(10);
   l_location_code         number(10);
   l_diverting_stream_code number(10);
   l_receiving_stream_code number(10);
   l_office_id             varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_station_unit         varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id);
   l_rec                   at_stream%rowtype;
   l_location_kind_id      varchar2(32);
begin
   if p_stream_id is null then
      cwms_err.raise('NULL_ARGUMENT', 'P_STREAM_ID');
      END IF;

      BEGIN
         l_location_code :=
            cwms_loc.get_location_code (l_office_id, p_stream_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

   -------------------
   -- sanity checks --
   -------------------
      IF l_location_code IS NULL
      THEN
         l_exists := FALSE;
      ELSE
      l_location_kind_id := cwms_loc.check_location_kind(l_location_code);

         IF l_location_kind_id NOT IN ('STREAM', 'SITE')
         THEN
         cwms_err.raise(
            'ERROR',
            'Cannot switch location '
            ||l_office_id
            ||'/'
            ||p_stream_id
            ||' from type '
            ||l_location_kind_id
            ||' to type STREAM');
         END IF;

         BEGIN
            SELECT *
              INTO l_rec
              FROM at_stream
             WHERE stream_location_code = l_location_code;

            l_exists := TRUE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_exists := FALSE;
         END;
      END IF;

      IF l_exists AND l_fail_if_exists
      THEN
         cwms_err.raise ('ITEM_ALREADY_EXISTS',
         'CWMS stream identifier',
         l_office_id
         ||'/'
         ||p_stream_id);
   end if;
   if p_station_unit is null then
      if p_flows_into_station is not null or
         p_diverts_from_station is not null or
         p_length is not null
      then
         cwms_err.raise(
            'ERROR',
            'Station and/or length values supplied without unit.');
         END IF;
      END IF;

      IF NOT l_exists OR NOT l_ignore_nulls
      THEN
         IF p_flows_into_stream IS NULL
         THEN
            IF    p_flows_into_station IS NOT NULL
               OR p_flows_into_bank IS NOT NULL
            THEN
            cwms_err.raise(
               'ERROR',
               'Confluence station and/or bank supplied without stream name.');
            END IF;
         END IF;

         IF p_diverts_from_stream IS NULL
         THEN
            IF    p_diverts_from_station IS NOT NULL
               OR p_diverts_from_bank IS NOT NULL
            THEN
            cwms_err.raise(
               'ERROR',
               'Diversion station and/or bank supplied without stream name.');
            END IF;
         END IF;
      END IF;

      IF     p_flows_into_bank IS NOT NULL
         AND UPPER (p_flows_into_bank) NOT IN ('L', 'R')
      THEN
         cwms_err.raise ('INVALID_ITEM',
         p_flows_into_bank,
         'stream bank, must be ''L'' or ''R''');
      END IF;

      IF     p_flows_into_bank IS NOT NULL
         AND UPPER (p_flows_into_bank) NOT IN ('L', 'R')
      THEN
         cwms_err.raise ('INVALID_ITEM',
         p_flows_into_bank,
         'stream bank, must be ''L'' or ''R''');
      END IF;

   --------------------------------------
   -- create the location if necessary --
   --------------------------------------
      IF l_location_code IS NULL
      THEN
      cwms_loc.create_location_raw2(
         p_base_location_code => l_base_location_code,
         p_location_code      => l_location_code,
         p_base_location_id   => cwms_util.get_base_id(p_stream_id),
         p_sub_location_id    => cwms_util.get_sub_id(p_stream_id),
            p_db_office_code       => cwms_util.get_db_office_code (
                                        l_office_id),
         p_location_kind_id   => 'STREAM');
      END IF;

   ---------------------------------
   -- set the record to be stored --
   ---------------------------------
      IF NOT p_flows_into_stream IS NULL
      THEN
         l_receiving_stream_code :=
            get_stream_code (l_office_id, p_flows_into_stream);
      END IF;

      IF NOT p_diverts_from_stream IS NULL
      THEN
         l_diverting_stream_code :=
            get_stream_code (l_office_id, p_diverts_from_stream);
      END IF;

      IF NOT l_exists
      THEN
      l_rec.stream_location_code := l_location_code;
      END IF;

      IF p_stationing_starts_ds IS NULL
      THEN
         IF NOT l_ignore_nulls
         THEN
            l_rec.zero_station := NULL;
         END IF;
      ELSE
         l_rec.zero_station :=
            CASE cwms_util.is_true (p_stationing_starts_ds)
               WHEN TRUE THEN 'DS'
               WHEN FALSE THEN 'US'
            END;
      END IF;

      IF l_diverting_stream_code IS NOT NULL OR NOT l_ignore_nulls
      THEN
      l_rec.diverting_stream_code := l_diverting_stream_code;
   end if;
   if p_diverts_from_station is not null or not l_ignore_nulls then
      l_rec.diversion_station := cwms_util.convert_units(p_diverts_from_station, l_station_unit, 'km');
   end if;
   if p_diverts_from_bank is not null or not l_ignore_nulls then
      l_rec.diversion_bank := upper(p_diverts_from_bank);
   end if;
   if l_receiving_stream_code is not null or not l_ignore_nulls then
      l_rec.receiving_stream_code := l_receiving_stream_code;
   end if;
   if p_flows_into_station is not null or not l_ignore_nulls then
      l_rec.confluence_station := cwms_util.convert_units(p_flows_into_station, l_station_unit, 'km');
   end if;
   if p_flows_into_bank is not null or not l_ignore_nulls then
      l_rec.confluence_bank := upper(p_flows_into_bank);
   end if;
   if p_length is not null or not l_ignore_nulls then
      l_rec.stream_length := cwms_util.convert_units(p_length, l_station_unit, 'km');
   end if;
   if p_average_slope is not null or not l_ignore_nulls then
      l_rec.average_slope := p_average_slope;
      END IF;

      IF p_comments IS NOT NULL OR NOT l_ignore_nulls
      THEN
      l_rec.comments := p_comments;
      END IF;

      IF l_exists
      THEN
         UPDATE at_stream
            SET row = l_rec
          WHERE stream_location_code = l_rec.stream_location_code;
      ELSE
         INSERT INTO at_stream
              VALUES l_rec;
      END IF;

   ---------------------------
   -- set the location kind --
   ---------------------------
      UPDATE at_physical_location
         SET location_kind =
                (SELECT location_kind_code
                   FROM cwms_location_kind
                  WHERE location_kind_id = 'STREAM')
       WHERE location_code = l_location_code;
   END store_stream;
--------------------------------------------------------------------------------
-- procedure store_streams
--------------------------------------------------------------------------------
procedure store_streams(
   p_streams        in out nocopy stream_tab_t,
   p_fail_if_exists in varchar2,
   p_ignore_nulls   in varchar2)
is
begin
   if p_streams is not null then
      for i in 1..p_streams.count loop
         p_streams(i).store(p_fail_if_exists, p_ignore_nulls);
      end loop;
   end if;
end store_streams;
--------------------------------------------------------------------------------
-- procedure retrieve_stream
--------------------------------------------------------------------------------
procedure retrieve_stream(
   p_stationing_starts_ds out varchar2,
   p_flows_into_stream    out varchar2,
   p_flows_into_station   out binary_double,
   p_flows_into_bank      out varchar2,
   p_diverts_from_stream  out varchar2,
   p_diverts_from_station out binary_double,
   p_diverts_from_bank    out varchar2,
   p_length               out binary_double,
   p_average_slope        out binary_double,
   p_comments             out varchar2 ,
   p_stream_id            in  varchar2,
   p_station_unit        in  varchar2,
   p_office_id            in  varchar2 default null)
is
   l_office_id     varchar2(16) := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_rec           at_stream%rowtype;
   l_station_unit varchar2(16) := cwms_util.get_unit_id(p_station_unit, l_office_id);
begin
   ------------------
   -- sanity check --
   ------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

   ------------------------------------------
   -- get the record and return the values --
   ------------------------------------------
   l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id);

      SELECT *
        INTO l_rec
        FROM at_stream
       WHERE stream_location_code = l_rec.stream_location_code;

      IF l_rec.zero_station = 'DS'
      THEN
      p_stationing_starts_ds := 'T';
      ELSE
      p_stationing_starts_ds := 'F';
   end if;
   if l_rec.receiving_stream_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
        into p_flows_into_stream
        from at_base_location bl,
             at_physical_location pl
       where pl.location_code = l_rec.receiving_stream_code
         and bl.base_location_code = pl.base_location_code;
      p_flows_into_station := cwms_util.convert_units(l_rec.confluence_station, 'km', l_station_unit);
      p_flows_into_bank := l_rec.confluence_bank;
   end if;
   if l_rec.diverting_stream_code is not null then
      select bl.base_location_id
             ||substr('-', 1, length(pl.sub_location_id))
        into p_diverts_from_stream
        from at_base_location bl,
             at_physical_location pl
       where pl.location_code = l_rec.diverting_stream_code
         and bl.base_location_code = pl.base_location_code;
      p_diverts_from_station := cwms_util.convert_units(l_rec.diversion_station, 'km', l_station_unit);
      p_diverts_from_bank := l_rec.diversion_bank;
   end if;
   p_length := cwms_util.convert_units(l_rec.stream_length, 'km', l_station_unit);
   p_average_slope := l_rec.average_slope;
   p_comments := l_rec.comments;
   END retrieve_stream;

--------------------------------------------------------------------------------
-- function retrieve_stream_f
--------------------------------------------------------------------------------
function retrieve_stream_f(
   p_stream_id     in varchar2,
   p_station_unit in varchar2,
   p_office_id     in varchar2 default null)
   return stream_t
is
   l_stream stream_t;
begin
   l_stream := stream_t(p_stream_id, p_office_id);
   l_stream.convert_to_unit(p_station_unit);
   return l_stream;
end retrieve_stream_f;
--------------------------------------------------------------------------------
-- procedure delete_stream
--------------------------------------------------------------------------------
   PROCEDURE delete_stream (
      p_stream_id       IN VARCHAR2,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      delete_stream2 (p_stream_id       => p_stream_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_office_id);
   END delete_stream;

--------------------------------------------------------------------------------
-- procedure delete_stream2
--------------------------------------------------------------------------------
   PROCEDURE delete_stream2 (
      p_stream_id                IN VARCHAR2,
      p_delete_action            IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_delete_location          IN VARCHAR2 DEFAULT 'F',
      p_delete_location_action   IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_office_id                IN VARCHAR2 DEFAULT NULL)
   IS
      l_stream_code       NUMBER (10);
      l_delete_location   BOOLEAN;
      l_delete_action1    VARCHAR2 (16);
      l_delete_action2    VARCHAR2 (16);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'P_stream_ID');
      END IF;

      l_delete_action1 := UPPER (SUBSTR (p_delete_action, 1, 16));

      IF l_delete_action1 NOT IN
            (cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
      THEN
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
      END IF;

   l_delete_location := cwms_util.return_true_or_false(p_delete_location);
      l_delete_action2 := UPPER (SUBSTR (p_delete_location_action, 1, 16));

      IF l_delete_action2 NOT IN
            (cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
      THEN
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
      END IF;

   l_stream_code := get_stream_code(p_office_id, p_stream_id);

   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
      IF l_delete_action1 IN (cwms_util.delete_data, cwms_util.delete_all)
      THEN
         BEGIN
            DELETE FROM at_stream_location
                  WHERE stream_location_code = l_stream_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         BEGIN
            DELETE FROM at_stream_reach
                  WHERE stream_location_code = l_stream_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;
      END IF;

   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
      IF l_delete_action1 IN (cwms_util.delete_key, cwms_util.delete_all)
      THEN
         DELETE FROM at_stream
               WHERE stream_location_code = l_stream_code;
      END IF;

   -------------------------------------
   -- delete the location if required --
   -------------------------------------
      IF l_delete_location
      THEN
         cwms_loc.delete_location (p_stream_id,
                                   l_delete_action2,
                                   p_office_id);
      ELSE
         UPDATE at_physical_location
            SET location_kind = 1
          WHERE location_code = l_stream_code;
      END IF;
   END delete_stream2;

--------------------------------------------------------------------------------
-- procedure rename_stream
--------------------------------------------------------------------------------
   PROCEDURE rename_stream (p_old_stream_id   IN VARCHAR2,
                            p_new_stream_id   IN VARCHAR2,
                            p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_old_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_new_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      cwms_loc.rename_location (p_old_stream_id,
                                p_new_stream_id,
                                p_office_id);
   END rename_stream;

--------------------------------------------------------------------------------
-- procedure cat_streams
--------------------------------------------------------------------------------
procedure cat_streams(
   p_stream_catalog              out sys_refcursor,
   p_stream_id_mask              in  varchar2 default '*',
   p_station_unit               in  varchar2 default 'km',
   p_stationing_starts_ds_mask   in  varchar2 default '*',
   p_flows_into_stream_id_mask   in  varchar2 default '*',
   p_flows_into_station_min      in  binary_double default null,
   p_flows_into_station_max      in  binary_double default null,
   p_flows_into_bank_mask        in  varchar2 default '*',
   p_diverts_from_stream_id_mask in  varchar2 default '*',
   p_diverts_from_station_min    in  binary_double default null,
   p_diverts_from_station_max    in  binary_double default null,
   p_diverts_from_bank_mask      in  varchar2 default '*',
   p_length_min                  in  binary_double default null,
   p_length_max                  in  binary_double default null,
   p_average_slope_min           in  binary_double default null,
   p_average_slope_max           in  binary_double default null,
   p_comments_mask               in  varchar2 default '*',
   p_office_id_mask              in  varchar2 default null)
is
   l_stream_id_mask              varchar2(49)  := upper(cwms_util.normalize_wildcards(p_stream_id_mask));
   l_stationing_starts_ds_mask   varchar2(1)   := upper(cwms_util.normalize_wildcards(p_stationing_starts_ds_mask));
   l_flows_into_stream_id_mask   varchar2(49)  := upper(cwms_util.normalize_wildcards(p_flows_into_stream_id_mask));
   l_flows_into_bank_mask        varchar2(1)   := upper(cwms_util.normalize_wildcards(p_flows_into_bank_mask));
   l_diverts_from_stream_id_mask varchar2(49)  := upper(cwms_util.normalize_wildcards(p_diverts_from_stream_id_mask));
   l_diverts_from_bank_mask      varchar2(1)   := upper(cwms_util.normalize_wildcards(p_diverts_from_bank_mask));
   l_comments_mask               varchar2(256) := upper(cwms_util.normalize_wildcards(p_comments_mask));
   l_office_id_mask              varchar2(16)  := upper(cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id)));
   l_flows_into_station_min      binary_double := nvl(cwms_util.convert_units(p_flows_into_station_min, p_station_unit, 'km'), -binary_double_max_normal);
   l_flows_into_station_max      binary_double := nvl(cwms_util.convert_units(p_flows_into_station_max, p_station_unit, 'km'), binary_double_max_normal);
   l_diverts_from_station_min    binary_double := nvl(cwms_util.convert_units(p_diverts_from_station_min, p_station_unit, 'km'), -binary_double_max_normal);
   l_diverts_from_station_max    binary_double := nvl(cwms_util.convert_units(p_diverts_from_station_max, p_station_unit, 'km'), binary_double_max_normal);
   l_length_min                  binary_double := nvl(cwms_util.convert_units(p_length_min, p_station_unit, 'km'), -binary_double_max_normal);
   l_length_max                  binary_double := nvl(cwms_util.convert_units(p_length_max, p_station_unit, 'km'), binary_double_max_normal);
   l_average_slope_min           binary_double := nvl(p_average_slope_min, -binary_double_max_normal);
   l_average_slope_max           binary_double := nvl(p_average_slope_max, binary_double_max_normal);
begin
   open p_stream_catalog for
      select stream.office_id,
             stream.stream_id,
             stream.stationing_starts_ds,
                confluence.stream_id AS flows_into_stream,
             stream.flows_into_station,
             stream.flows_into_bank,
                diversion.stream_id AS diverts_from_stream,
             stream.diverts_from_station,
             stream.diverts_from_bank,
             stream.stream_length,
             stream.average_slope,
             stream.comments
           FROM (SELECT o.office_id,
                      bl.base_location_id
                        || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                        || pl.sub_location_id
                           AS stream_id,
                        CASE
                           WHEN zero_station = 'DS' THEN 'T'
                           WHEN zero_station = 'US' THEN 'F'
                        END
                           AS stationing_starts_ds,
                      receiving_stream_code,
                      cwms_util.convert_units(confluence_station, 'km', cwms_util.get_unit_id(p_station_unit, o.office_id)) as flows_into_station,
                      confluence_bank as flows_into_bank,
                      diverting_stream_code,
                      cwms_util.convert_units(diversion_station, 'km', cwms_util.get_unit_id(p_station_unit, o.office_id)) as diverts_from_station,
                      diversion_bank as diverts_from_bank,
                      cwms_util.convert_units(stream_length, 'km', cwms_util.get_unit_id(p_station_unit, o.office_id)) as stream_length,
                      average_slope,
                      comments
                   FROM at_physical_location pl,
                      at_base_location bl,
                      at_stream s,
                      cwms_office o
                where o.office_id like l_office_id_mask escape '\'
                  and upper(bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id) like l_stream_id_mask escape '\'
                  and bl.db_office_code = o.office_code
                  and pl.base_location_code = bl.base_location_code
                  and s.stream_location_code = pl.location_code
                  and nvl(confluence_station, l_flows_into_station_min) between l_flows_into_station_min and l_flows_into_station_max
                  and nvl(confluence_bank, '%') like l_flows_into_bank_mask
                  and nvl(diversion_station, l_diverts_from_station_min) between l_diverts_from_station_min and l_diverts_from_station_max
                  and nvl(diversion_bank, '%') like l_diverts_from_bank_mask
                  and nvl(stream_length, l_length_min) between l_length_min and l_length_max
                  and nvl(average_slope, l_average_slope_min) between l_average_slope_min and l_average_slope_max
                  and upper(nvl(comments, '%')) like l_comments_mask escape '\'
            ) stream
            left outer join
            (  select bl.base_location_id
                      ||substr('-', 1, length(pl.sub_location_id))
                      ||pl.sub_location_id as stream_id,
                      s.stream_location_code
                                   FROM at_physical_location pl,
                      at_base_location bl,
                      at_stream s
                                  WHERE     UPPER (
                                                  bl.base_location_id
                                               || SUBSTR (
                                                     '-',
                                                     1,
                                                     LENGTH (
                                                        pl.sub_location_id))
                                               || pl.sub_location_id) LIKE
                                               l_flows_into_stream_id_mask ESCAPE '\'
                                        AND pl.base_location_code =
                                               bl.base_location_code
                                        AND s.stream_location_code =
                                               pl.location_code) confluence
                   ON stream.receiving_stream_code =
                         confluence.stream_location_code
                LEFT OUTER JOIN (SELECT    bl.base_location_id
                                        || SUBSTR (
                                              '-',
                                              1,
                                              LENGTH (pl.sub_location_id))
                                        || pl.sub_location_id
                                           AS stream_id,
                      s.stream_location_code
                                   FROM at_physical_location pl,
                      at_base_location bl,
                      at_stream s
                                  WHERE     UPPER (
                                                  bl.base_location_id
                                               || SUBSTR (
                                                     '-',
                                                     1,
                                                     LENGTH (
                                                        pl.sub_location_id))
                                               || pl.sub_location_id) LIKE
                                               l_diverts_from_stream_id_mask ESCAPE '\'
                                        AND pl.base_location_code =
                                               bl.base_location_code
                                        AND s.stream_location_code =
                                               pl.location_code) diversion
                   ON stream.diverting_stream_code =
                         diversion.stream_location_code;
   END cat_streams;

--------------------------------------------------------------------------------
-- function cat_streams_f
--------------------------------------------------------------------------------
function cat_streams_f(
   p_stream_id_mask              in varchar2 default '*',
   p_station_unit               in varchar2 default 'km',
   p_stationing_starts_ds_mask   in varchar2 default '*',
   p_flows_into_stream_id_mask   in varchar2 default '*',
   p_flows_into_station_min      in binary_double default null,
   p_flows_into_station_max      in binary_double default null,
   p_flows_into_bank_mask        in varchar2 default '*',
   p_diverts_from_stream_id_mask in varchar2 default '*',
   p_diverts_from_station_min    in binary_double default null,
   p_diverts_from_station_max    in binary_double default null,
   p_diverts_from_bank_mask      in varchar2 default '*',
   p_length_min                  in binary_double default null,
   p_length_max                  in binary_double default null,
   p_average_slope_min           in binary_double default null,
   p_average_slope_max           in binary_double default null,
   p_comments_mask               in varchar2 default '*',
   p_office_id_mask              in varchar2 default null)
   return sys_refcursor
is
   l_cursor sys_refcursor;
begin
   cat_streams(
      l_cursor,
      p_stream_id_mask,
      p_station_unit,
      p_stationing_starts_ds_mask,
      p_flows_into_stream_id_mask,
      p_flows_into_station_min,
      p_flows_into_station_max,
      p_flows_into_bank_mask,
      p_diverts_from_stream_id_mask,
      p_diverts_from_station_min,
      p_diverts_from_station_max,
      p_diverts_from_bank_mask,
      p_length_min,
      p_length_max,
      p_average_slope_min,
      p_average_slope_max,
      p_comments_mask,
      p_office_id_mask);

      RETURN l_cursor;
   END cat_streams_f;

--------------------------------------------------------------------------------
-- procedure store_stream_reach
--------------------------------------------------------------------------------
   PROCEDURE store_stream_reach (
      p_stream_id            IN VARCHAR2,
      p_reach_id             IN VARCHAR2,
      p_fail_if_exists       IN VARCHAR2,
      p_ignore_nulls         IN VARCHAR2,
      p_upstream_station     IN BINARY_DOUBLE,
      p_downstream_station   IN BINARY_DOUBLE,
      p_stream_type_id       IN VARCHAR2 DEFAULT NULL,
      p_comments             IN VARCHAR2 DEFAULT NULL,
      p_office_id            IN VARCHAR2 DEFAULT NULL)
   IS
      l_fail_if_exists   BOOLEAN := cwms_util.is_true (p_fail_if_exists);
      l_ignore_nulls     BOOLEAN := cwms_util.is_true (p_ignore_nulls);
      l_exists           BOOLEAN;
      l_office_id        VARCHAR2 (16)
         := NVL (UPPER (p_office_id), cwms_util.user_office_id);
      l_stream_type_id   VARCHAR2 (4);
      l_rec              at_stream_reach%ROWTYPE;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_reach_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
      END IF;

      IF p_stream_type_id IS NOT NULL
      THEN
         BEGIN
            SELECT stream_type_id
              INTO l_stream_type_id
              FROM cwms_stream_type
             WHERE UPPER (stream_type_id) = UPPER (p_stream_type_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
               p_stream_type_id,
               'CWMS stream type identifier');
         END;
      END IF;

   l_rec.stream_location_code := get_stream_code(l_office_id, p_stream_id);

   ------------------------------------------------------------
   -- determine if the reach exists (retrieve it if it does) --
   ------------------------------------------------------------
      BEGIN
         SELECT *
           INTO l_rec
           FROM at_stream_reach
          WHERE     stream_location_code = l_rec.stream_location_code
                AND UPPER (stream_reach_id) = UPPER (p_reach_id);

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      IF l_exists AND l_fail_if_exists
      THEN
      cwms_err.raise(
         'ITEM_ALREADY_EXISTS',
         'CWMS stream reach identifier',
            l_office_id || '/' || p_stream_id || '/' || p_reach_id);
      END IF;

   --------------------------
   -- set the reach values --
   --------------------------
      IF NOT l_exists
      THEN
      l_rec.stream_reach_id := p_reach_id;
      END IF;

      IF p_upstream_station IS NOT NULL OR NOT l_ignore_nulls
      THEN
      l_rec.upstream_station := p_upstream_station;
      END IF;

      IF p_downstream_station IS NOT NULL OR NOT l_ignore_nulls
      THEN
      l_rec.downstream_station := p_downstream_station;
      END IF;

      IF l_stream_type_id IS NOT NULL OR NOT l_ignore_nulls
      THEN
      l_rec.stream_type_id := l_stream_type_id;
      END IF;

      IF p_comments IS NOT NULL OR NOT l_ignore_nulls
      THEN
      l_rec.comments := p_comments;
      END IF;

   --------------------------------
   -- insert or update the reach --
   --------------------------------
      IF l_exists
      THEN
         UPDATE at_stream_reach
            SET row = l_rec
          WHERE stream_location_code = l_rec.stream_location_code;
      ELSE
         INSERT INTO at_stream_reach
              VALUES l_rec;
      END IF;
   END store_stream_reach;

--------------------------------------------------------------------------------
-- procedure retrieve_stream_reach
--------------------------------------------------------------------------------
   PROCEDURE retrieve_stream_reach (
      p_upstream_station        OUT BINARY_DOUBLE,
      p_downstream_station      OUT BINARY_DOUBLE,
      p_stream_type_id          OUT VARCHAR2,
      p_comments                OUT VARCHAR2,
      p_stream_id            IN     VARCHAR2,
      p_reach_id             IN     VARCHAR2,
      p_office_id            IN     VARCHAR2 DEFAULT NULL)
   IS
      l_stream_location_code   NUMBER (10);
      l_office_id              VARCHAR2 (16)
         := NVL (UPPER (p_office_id), cwms_util.user_office_id);
      l_rec                    at_stream_reach%ROWTYPE;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_reach_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
      END IF;

   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_stream_reach
          WHERE     stream_location_code = l_stream_location_code
                AND UPPER (stream_reach_id) = UPPER (p_reach_id);

      p_upstream_station   := l_rec.upstream_station;
      p_downstream_station := l_rec.downstream_station;
      p_stream_type_id     := l_rec.stream_type_id;
      p_comments           := l_rec.comments;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream reach identifier',
               l_office_id || '/' || p_stream_id || '/' || p_reach_id);
      END;
   END retrieve_stream_reach;

--------------------------------------------------------------------------------
-- procedure delete_stream_reach
--------------------------------------------------------------------------------
   PROCEDURE delete_stream_reach (p_stream_id   IN VARCHAR2,
                                  p_reach_id    IN VARCHAR2,
                                  p_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
      l_stream_location_code   NUMBER (10);
      l_office_id              VARCHAR2 (16)
         := NVL (UPPER (p_office_id), cwms_util.user_office_id);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_reach_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
      END IF;

   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);

      BEGIN
         DELETE FROM at_stream_reach
               WHERE     stream_location_code = l_stream_location_code
                     AND UPPER (stream_reach_id) = UPPER (p_reach_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream reach identifier',
               l_office_id || '/' || p_stream_id || '/' || p_reach_id);
      END;
   END delete_stream_reach;

--------------------------------------------------------------------------------
-- procedure rename_stream_reach
--------------------------------------------------------------------------------
   PROCEDURE rename_stream_reach (p_stream_id      IN VARCHAR2,
                                  p_old_reach_id   IN VARCHAR2,
                                  p_new_reach_id   IN VARCHAR2,
                                  p_office_id      IN VARCHAR2 DEFAULT NULL)
   IS
      l_stream_location_code   NUMBER (10);
      l_office_id              VARCHAR2 (16)
         := NVL (UPPER (p_office_id), cwms_util.user_office_id);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_old_reach_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
      END IF;

      IF p_new_reach_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS stream reach identifier.');
      END IF;

   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);

      BEGIN
         UPDATE at_stream_reach
            SET stream_reach_id = p_new_reach_id
          WHERE     stream_location_code = l_stream_location_code
                AND UPPER (stream_reach_id) = UPPER (p_old_reach_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS stream reach identifier',
               l_office_id || '/' || p_stream_id || '/' || p_old_reach_id);
      END;
   END rename_stream_reach;

--------------------------------------------------------------------------------
-- procedure cat_stream_reaches
--------------------------------------------------------------------------------
   PROCEDURE cat_stream_reaches (
      p_reach_catalog            OUT SYS_REFCURSOR,
      p_stream_id_mask        IN     VARCHAR2 DEFAULT '*',
      p_reach_id_mask         IN     VARCHAR2 DEFAULT '*',
      p_stream_type_id_mask   IN     VARCHAR2 DEFAULT '*',
      p_comments_mask         IN     VARCHAR2 DEFAULT '*',
      p_office_id_mask        IN     VARCHAR2 DEFAULT NULL)
   IS
      l_stream_id_mask        VARCHAR2 (49)
         := cwms_util.normalize_wildcards (p_stream_id_mask);
      l_reach_id_mask         VARCHAR2 (64)
         := cwms_util.normalize_wildcards (p_reach_id_mask);
      l_stream_type_id_mask   VARCHAR2 (4)
         := cwms_util.normalize_wildcards (p_stream_type_id_mask);
      l_comments_mask         VARCHAR2 (256)
         := cwms_util.normalize_wildcards (p_comments_mask);
      l_office_id_mask        VARCHAR2 (16)
         := cwms_util.normalize_wildcards (
               NVL (UPPER (p_office_id_mask), cwms_util.user_office_id));
   BEGIN
      OPEN p_reach_catalog FOR
           SELECT o.office_id,
             bl.base_location_id
                  || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                  || pl.sub_location_id
                     AS stream_id,
             sr.stream_reach_id,
             sr.upstream_station,
             sr.downstream_station,
             sr.stream_type_id,
             sr.comments
             FROM at_physical_location pl,
             at_base_location bl,
             at_stream_reach sr,
             cwms_office o
            WHERE     o.office_id LIKE l_office_id_mask ESCAPE '\'
                  AND bl.db_office_code = o.office_code
                  AND UPPER (
                            bl.base_location_id
                         || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                         || pl.sub_location_id) LIKE
                         UPPER (l_stream_id_mask) ESCAPE '\'
                  AND sr.stream_location_code = pl.location_code
                  AND UPPER (sr.stream_reach_id) LIKE
                         UPPER (l_reach_id_mask) ESCAPE '\'
                  AND UPPER (sr.stream_type_id) LIKE
                         UPPER (l_stream_type_id_mask) ESCAPE '\'
                  AND UPPER (sr.comments) LIKE
                         UPPER (l_comments_mask) ESCAPE '\'
         ORDER BY o.office_id,
                  UPPER (bl.base_location_id),
                  UPPER (pl.sub_location_id),
                  UPPER (sr.stream_reach_id);
   END cat_stream_reaches;

--------------------------------------------------------------------------------
-- function cat_stream_reaches_f
--------------------------------------------------------------------------------
   FUNCTION cat_stream_reaches_f (
      p_stream_id_mask        IN VARCHAR2 DEFAULT '*',
      p_reach_id_mask         IN VARCHAR2 DEFAULT '*',
      p_stream_type_id_mask   IN VARCHAR2 DEFAULT '*',
      p_comments_mask         IN VARCHAR2 DEFAULT '*',
      p_office_id_mask        IN VARCHAR2 DEFAULT NULL)
      RETURN SYS_REFCURSOR
   IS
      l_cursor   SYS_REFCURSOR;
   BEGIN
      cat_stream_reaches (l_cursor,
     p_stream_id_mask,
     p_reach_id_mask,
     p_stream_type_id_mask,
     p_comments_mask,
     p_office_id_mask);

      RETURN l_cursor;
   END cat_stream_reaches_f;

--------------------------------------------------------------------------------
-- procedure store_stream_location
--------------------------------------------------------------------------------
   PROCEDURE store_stream_location (
      p_location_id               IN VARCHAR2,
      p_stream_id                 IN VARCHAR2,
      p_fail_if_exists            IN VARCHAR2,
      p_ignore_nulls              IN VARCHAR2,
      p_station                   IN BINARY_DOUBLE,
      p_station_unit              IN VARCHAR2,
      p_published_station         IN BINARY_DOUBLE DEFAULT NULL,
      p_navigation_station        IN BINARY_DOUBLE DEFAULT NULL,
      p_bank                      IN VARCHAR2 DEFAULT NULL,
      p_lowest_measurable_stage   IN BINARY_DOUBLE DEFAULT NULL,
      p_stage_unit                IN VARCHAR2 DEFAULT NULL,
      p_drainage_area             IN BINARY_DOUBLE DEFAULT NULL,
      p_ungaged_drainage_area     IN BINARY_DOUBLE DEFAULT NULL,
      p_area_unit                 IN VARCHAR2 DEFAULT NULL,
      p_office_id                 IN VARCHAR2 DEFAULT NULL)
   IS
      l_office_id        VARCHAR2 (16)
                            := NVL (UPPER (p_office_id), cwms_util.user_office_id);
      l_station_unit     VARCHAR2 (16)
         := cwms_util.get_unit_id (p_station_unit, l_office_id);
      l_stage_unit       VARCHAR2 (16)
         := cwms_util.get_unit_id (p_stage_unit, l_office_id);
      l_area_unit        VARCHAR2 (16)
                            := cwms_util.get_unit_id (p_area_unit, l_office_id);
      l_fail_if_exists   BOOLEAN := cwms_util.is_true (p_fail_if_exists);
      l_ignore_nulls     BOOLEAN := cwms_util.is_true (p_ignore_nulls);
      l_exists           BOOLEAN;
      l_rec              at_stream_location%ROWTYPE;
      l_location_kind    cwms_location_kind.location_kind_id%TYPE;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_location_id IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION_ID');
      END IF;

      IF p_station IS NOT NULL AND p_station_unit IS NULL
      THEN
         cwms_err.raise ('ERROR',
         'Station unit must be specified with station.');
      END IF;

      IF p_lowest_measurable_stage IS NOT NULL AND p_stage_unit IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'Stage unit must be specified with lowest measureable stage.');
      END IF;

      IF     (   p_drainage_area IS NOT NULL
              OR p_ungaged_drainage_area IS NOT NULL)
         AND p_area_unit IS NULL
      THEN
         cwms_err.raise ('ERROR',
         'Area unit must be specified with drainage areas.');
      END IF;

      IF p_bank IS NOT NULL AND UPPER (p_bank) NOT IN ('L', 'R')
      THEN
         cwms_err.raise ('INVALID_ITEM',
         p_bank,
         'stream bank, must be ''L'' or ''R''.');
      END IF;

      l_location_kind := cwms_loc.check_location_kind(p_location_id,
                                                      p_office_id);

      if l_location_kind not in
           ('OUTLET',
            'EMBANKMENT',
            'LOCK',
            'TURBINE',
            'PROJECT',
            'STREAMGAGE',
            'SITE')
      then
         cwms_err.raise ('ERROR',
                         'A Stream Location record can not be created for a Location of KIND: '
                         || l_location_kind);
   end if;

   ------------------------------------------
   -- get the existing record if it exists --
   ------------------------------------------
      l_rec.location_code :=
         cwms_loc.get_location_code (l_office_id, p_location_id);

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_stream_location
          WHERE location_code = l_rec.location_code;

         l_exists := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_exists := FALSE;
      END;

      IF l_exists AND l_fail_if_exists
      THEN
      cwms_err.raise(
         'ERROR',
         'Location '
         ||l_office_id
         ||'/'
         ||p_location_id
         ||' already exists as a stream location on stream '
         ||l_office_id
         ||'/'
         ||p_stream_id);
      END IF;

   ---------------------------
   -- set the record values --
   ---------------------------
      IF p_stream_id IS NOT NULL
      THEN
         l_rec.stream_location_code :=
            get_stream_code (l_office_id, p_stream_id);
      ELSIF NOT l_ignore_nulls
      THEN
         l_rec.stream_location_code := NULL;
      END IF;

      IF p_station IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.station :=
            cwms_util.convert_units (p_station, l_station_unit, 'km');
      END IF;

      IF p_published_station IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.published_station :=
            cwms_util.convert_units (p_published_station,
                                     l_station_unit,
                                     'km');
      END IF;

      IF p_navigation_station IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.navigation_station :=
            cwms_util.convert_units (p_navigation_station,
                                     l_station_unit,
                                     'km');
      END IF;

      IF p_bank IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.bank := UPPER (p_bank);
      END IF;

      IF p_lowest_measurable_stage IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.lowest_measurable_stage :=
            cwms_util.convert_units (p_lowest_measurable_stage,
                                     l_stage_unit,
                                     'm');
      END IF;

      IF p_drainage_area IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.drainage_area :=
            cwms_util.convert_units (p_drainage_area, l_area_unit, 'm2');
      END IF;

      IF p_ungaged_drainage_area IS NOT NULL OR NOT l_ignore_nulls
      THEN
         l_rec.ungaged_area :=
            cwms_util.convert_units (p_ungaged_drainage_area,
                                     l_area_unit,
                                     'm2');
      END IF;

   ---------------------------------
   -- update or insert the record --
   ---------------------------------
      IF l_exists
      THEN
         UPDATE at_stream_location
            SET row = l_rec
          WHERE     location_code = l_rec.location_code;
      ELSE
         INSERT INTO at_stream_location
              VALUES l_rec;
      END IF;
      ---------------------------
      -- set the location kind --
      ---------------------------
      if l_location_kind in ('SITE', 'STREAMGAGE') then
          update at_physical_location
             set location_kind = (select location_kind_code
                                    from cwms_location_kind
                                   where location_kind_id = 'STREAMGAGE'
                                 )
           where location_code = l_rec.location_code;
   end if;

   END store_stream_location;

--------------------------------------------------------------------------------
-- procedure retrieve_stream_location
--------------------------------------------------------------------------------
   PROCEDURE retrieve_stream_location (
      p_station                      OUT BINARY_DOUBLE,
      p_published_station            OUT BINARY_DOUBLE,
      p_navigation_station           OUT BINARY_DOUBLE,
      p_bank                         OUT VARCHAR2,
      p_lowest_measurable_stage      OUT BINARY_DOUBLE,
      p_drainage_area                OUT BINARY_DOUBLE,
      p_ungaged_drainage_area        OUT BINARY_DOUBLE,
      p_location_id               IN     VARCHAR2,
      p_stream_id                 IN     VARCHAR2,
      p_station_unit              IN     VARCHAR2,
      p_stage_unit                IN     VARCHAR2,
      p_area_unit                 IN     VARCHAR2,
      p_office_id                 IN     VARCHAR2 DEFAULT NULL)
   IS
      l_office_id              VARCHAR2 (16)
                                  := NVL (UPPER (p_office_id), cwms_util.user_office_id);
      l_station_unit           VARCHAR2 (16)
         := cwms_util.get_unit_id (p_station_unit, l_office_id);
      l_stage_unit             VARCHAR2 (16)
         := cwms_util.get_unit_id (p_stage_unit, l_office_id);
      l_area_unit              VARCHAR2 (16)
                                  := cwms_util.get_unit_id (p_area_unit, l_office_id);
      l_location_code          NUMBER (10);
      l_stream_location_code   NUMBER (10);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
      END IF;

      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_station_unit IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Station unit must be specified.');
      END IF;

      IF p_stage_unit IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Stage unit must be specified.');
      END IF;

      IF p_area_unit IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Area unit must be specified.');
      END IF;

   -----------------------
   -- retrieve the data --
   -----------------------
      l_location_code :=
         cwms_loc.get_location_code (l_office_id, p_location_id);
   l_stream_location_code := get_stream_code(l_office_id, p_stream_id);

      BEGIN
         SELECT cwms_util.convert_units (station, 'km', l_station_unit),
                cwms_util.convert_units (published_station,
                                         'km',
                                         l_station_unit),
                cwms_util.convert_units (navigation_station,
                                         'km',
                                         l_station_unit),
             bank,
                cwms_util.convert_units (lowest_measurable_stage,
                                         'm',
                                         l_stage_unit),
             cwms_util.convert_units(drainage_area, 'm2', l_area_unit),
             cwms_util.convert_units(ungaged_area, 'm2', l_area_unit)
           INTO p_station,
             p_published_station,
             p_navigation_station,
             p_bank,
             p_lowest_measurable_stage,
             p_drainage_area,
             p_ungaged_drainage_area
           FROM at_stream_location
          WHERE     location_code = l_location_code
                AND stream_location_code = l_stream_location_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' does not exist as a stream location on stream '
            ||l_office_id
            ||'/'
            ||p_stream_id);
      END;
   END retrieve_stream_location;

--------------------------------------------------------------------------------
-- procedure delete_stream_location
--------------------------------------------------------------------------------
   PROCEDURE delete_stream_location (
      p_location_id   IN VARCHAR2,
      p_stream_id     IN VARCHAR2, -- unused as stream_id, repurposed as delete action
      p_office_id     IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      delete_stream_location2 (p_location_id     => p_location_id,
      p_delete_action => p_stream_id, -- note repurposing
      p_office_id     => p_office_id);
   END delete_stream_location;

--------------------------------------------------------------------------------
-- procedure delete_stream_location2
--------------------------------------------------------------------------------
   PROCEDURE delete_stream_location2 (
      p_location_id              IN VARCHAR2,
      p_delete_action            IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_delete_location          IN VARCHAR2 DEFAULT 'F',
      p_delete_location_action   IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_office_id                IN VARCHAR2 DEFAULT NULL)
   IS
      l_location_code     NUMBER (10);
      l_delete_location   BOOLEAN;
      l_delete_action1    VARCHAR2 (16);
      l_delete_action2    VARCHAR2 (16);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_location_id IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'P_LOCATION');
      END IF;

      l_delete_action1 := UPPER (SUBSTR (p_delete_action, 1, 16));

      IF l_delete_action1 NOT IN
            (cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
      THEN
      l_delete_action1 := cwms_util.delete_key; -- delete_stream_location might pass in a stream_id
      END IF;

   l_delete_location := cwms_util.return_true_or_false(p_delete_location);
      l_delete_action2 := UPPER (SUBSTR (p_delete_location_action, 1, 16));

      IF l_delete_action2 NOT IN
            (cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
      THEN
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
      END IF;

      l_location_code :=
         cwms_loc.get_location_code (p_office_id, p_location_id);

   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
      IF l_delete_action1 IN (cwms_util.delete_data, cwms_util.delete_all)
      THEN
         NULL;                                            -- no dependent data
      END IF;

   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
      IF l_delete_action1 IN (cwms_util.delete_key, cwms_util.delete_all)
      THEN
         DELETE FROM at_stream_location
               WHERE location_code = l_location_code;
      END IF;

   -------------------------------------
   -- delete the location if required --
   -------------------------------------
      IF l_delete_location
      THEN
         cwms_loc.delete_location (p_location_id,
                                   l_delete_action2,
                                   p_office_id);
      ELSE
         UPDATE at_physical_location
            SET location_kind = 1
          WHERE location_code = l_location_code;
      END IF;
   END delete_stream_location2;

--------------------------------------------------------------------------------
-- procedure cat_stream_locations
--------------------------------------------------------------------------------
procedure cat_stream_locations(
   p_stream_location_catalog out sys_refcursor,
   p_stream_id_mask          in  varchar2 default '*',
   p_location_id_mask        in  varchar2 default '*',
   p_station_unit            in  varchar2 default null,
   p_stage_unit              in  varchar2 default null,
   p_area_unit               in  varchar2 default null,
   p_office_id_mask          in  varchar2 default null)
is
   l_stream_id_mask   varchar2(49) := cwms_util.normalize_wildcards(upper(p_stream_id_mask));
   l_location_id_mask varchar2(49) := cwms_util.normalize_wildcards(upper(p_location_id_mask));
   l_office_id_mask   varchar2(16) := cwms_util.normalize_wildcards(upper(nvl(p_office_id_mask, cwms_util.user_office_id)));
   l_station_unit     varchar2(16) := cwms_util.get_unit_id(nvl(p_station_unit, 'km'));
   l_stage_unit       varchar2(16) := cwms_util.get_unit_id(nvl(p_stage_unit, 'm'));
   l_area_unit        varchar2(16) := cwms_util.get_unit_id(nvl(p_area_unit, 'm2'));
begin
    open p_stream_location_catalog for
      select o.office_id,
             bl1.base_location_id
                  || SUBSTR ('-', 1, LENGTH (pl1.sub_location_id))
                  || pl1.sub_location_id
                     AS stream_id,
             bl2.base_location_id
             ||substr('-', 1, length(pl2.sub_location_id))
             ||pl2.sub_location_id as location_id,
             cwms_util.convert_units(station, 'km', l_station_unit) as station,
             cwms_util.convert_units(published_station, 'km', l_station_unit) as published_station,
             cwms_util.convert_units(navigation_station, 'km', l_station_unit) as navigation_station,
             bank,
             cwms_util.convert_units(lowest_measurable_stage, 'm', l_stage_unit) as lowest_measurable_stage,
             cwms_util.convert_units(drainage_area, 'm2', l_area_unit) as drainage_area,
             cwms_util.convert_units(ungaged_area, 'm2', l_area_unit) as ungaged_drainage_area,
             l_station_unit as station_unit,
             l_stage_unit as stage_unit,
             l_area_unit as area_unit
        from at_physical_location pl1,
             at_physical_location pl2,
             at_base_location bl1,
             at_base_location bl2,
             at_stream_location sl,
             cwms_office o
       where pl1.location_code = sl.stream_location_code
         and bl1.base_location_code = pl1.base_location_code
         and upper(bl1.base_location_id
             ||substr('-', 1, length(pl1.sub_location_id))
             ||pl1.sub_location_id) like l_stream_id_mask escape '\'
         and pl2.location_code = sl.location_code
         and bl2.base_location_code = pl2.base_location_code
         and upper(bl2.base_location_id
             ||substr('-', 1, length(pl2.sub_location_id))
             ||pl2.sub_location_id) like l_location_id_mask escape '\'
         and o.office_code = bl1.db_office_code
       order by 1, 2, 4, 3;
   END cat_stream_locations;

--------------------------------------------------------------------------------
-- function cat_stream_locations_f
--------------------------------------------------------------------------------
   FUNCTION cat_stream_locations_f (
      p_stream_id_mask     IN VARCHAR2 DEFAULT '*',
      p_location_id_mask   IN VARCHAR2 DEFAULT '*',
      p_station_unit       IN VARCHAR2 DEFAULT NULL,
      p_stage_unit         IN VARCHAR2 DEFAULT NULL,
      p_area_unit          IN VARCHAR2 DEFAULT NULL,
      p_office_id_mask     IN VARCHAR2 DEFAULT NULL)
      RETURN SYS_REFCURSOR
   IS
      l_cursor   SYS_REFCURSOR;
   BEGIN
      cat_stream_locations (l_cursor,
      p_location_id_mask,
      p_stream_id_mask,
      p_station_unit,
      p_stage_unit,
      p_area_unit,
      p_office_id_mask);

      RETURN l_cursor;
   END cat_stream_locations_f;

--------------------------------------------------------------------------------
-- function get_next_location_codes_f
--
-- return  the next-upstream or next-downstream stream location on this stream
--------------------------------------------------------------------------------
function get_next_location_codes_f(
   p_stream_code  in number,
   p_direction    in varchar2,
   p_station      in binary_double default null) -- in km
   return number_tab_t
is
   l_direction          varchar2(2);
   l_zero_station       varchar2(2);
   l_next_location_codes number_tab_t;
begin
   -------------------
   -- sanity checks --
   -------------------
      IF p_direction IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      l_direction := UPPER (SUBSTR (p_direction, 1, 2));

      IF p_direction NOT IN ('US', 'DS')
      THEN
         cwms_err.raise ('ERROR',
         'Direction must be specified as ''US'' or ''DS''');
      END IF;

      SELECT zero_station
        INTO l_zero_station
        FROM at_stream
       WHERE stream_location_code = p_stream_code;

   begin
      if l_zero_station = l_direction then
         ------------------------------------------
         -- get location with next lower station --
         ------------------------------------------
         select location_code
           bulk collect
           into l_next_location_codes
           from at_stream_location
          where stream_location_code = p_stream_code
            and station =
                (select max(station)
                  from at_stream_location
                  where stream_location_code = p_stream_code
                    and station < nvl(p_station, binary_double_max_normal)
                );
      else
         -------------------------------------------
         -- get location with next higher station --
         -------------------------------------------
         select location_code
           bulk collect
           into l_next_location_codes
           from at_stream_location
          where stream_location_code = p_stream_code
            and station =
                (select min(station)
                  from at_stream_location
                  where stream_location_code = p_stream_code
                    and station > nvl(p_station, -binary_double_max_normal)
                );
      end if;
   exception
      when no_data_found then null;
   end;

   return l_next_location_codes;
end get_next_location_codes_f;

--------------------------------------------------------------------------------
-- function get_us_location_codes_f
--
-- return  the next-upstream stream location on this stream
--------------------------------------------------------------------------------
function get_us_location_codes_f(
   p_stream_code  in number,
   p_station      in binary_double default null) -- in km
   return number_tab_t
is
begin
   return get_next_location_codes_f(p_stream_code, 'US', p_station);
end get_us_location_codes_f;

--------------------------------------------------------------------------------
-- function get_ds_location_codes_f
--
-- return  the next-downstream stream location on this stream
--------------------------------------------------------------------------------
function get_ds_location_codes_f(
   p_stream_code  in number,
   p_station      in binary_double default null) -- in km
   return number_tab_t
is
begin
   return get_next_location_codes_f(p_stream_code, 'DS', p_station);
end get_ds_location_codes_f;

--------------------------------------------------------------------------------
-- function get_junctions_between_f
--
-- get streams flowing into or out of this stream between 2 stations
--------------------------------------------------------------------------------
   FUNCTION get_junctions_between_f (p_stream_code     IN NUMBER,
                                     p_junction_type   IN VARCHAR2,
                                     p_station_1       IN BINARY_DOUBLE, -- in km
                                     p_station_2       IN BINARY_DOUBLE) -- in im
      RETURN number_tab_t
   IS
      l_junction_type   VARCHAR2 (1);
   l_stream_codes  number_tab_t;
      l_station_1       BINARY_DOUBLE;
      l_station_2       BINARY_DOUBLE;
      l_stream_code     NUMBER (10);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_station_1 IS NULL OR p_station_2 IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Stream stations must not be null.');
      END IF;

      IF UPPER (p_junction_type) NOT IN ('C'                     /*onfluence*/
                                            , 'B'               /*ifurcation*/
                                                 )
      THEN
      cwms_err.raise(
         'ERROR',
         'Junction type must be ''C''(confluence) or ''B''(bifurcation).');
   end if;
   l_junction_type := upper(p_junction_type);
   l_station_1  := least(p_station_1, p_station_2);
   l_station_2  := greatest(p_station_1, p_station_2);
   if l_junction_type = 'C' then
      select stream_location_code
             bulk collect into l_stream_codes
        from at_stream
       where receiving_stream_code = p_stream_code
         and confluence_station between l_station_1 and l_station_2;
   else
      select stream_location_code
             bulk collect into l_stream_codes
        from at_stream
       where diverting_stream_code = p_stream_code
         and diversion_station between l_station_1 and l_station_2;
   end if;

      RETURN l_stream_codes;
   END get_junctions_between_f;

--------------------------------------------------------------------------------
-- function get_confluences_between_f
--
-- get streams flowing into this stream between 2 stations
--------------------------------------------------------------------------------
   FUNCTION get_confluences_between_f (p_stream_code   IN NUMBER,
                                       p_station_1     IN BINARY_DOUBLE, -- in km
                                       p_station_2     IN BINARY_DOUBLE) -- in km
      RETURN number_tab_t
   IS
   BEGIN
      RETURN get_junctions_between_f (p_stream_code,
      'C', -- confluence
      p_station_1,
      p_station_2);
   END get_confluences_between_f;

--------------------------------------------------------------------------------
-- function get_bifurcations_between_f
--
-- get streams flowing into this stream between 2 stations
--------------------------------------------------------------------------------
   FUNCTION get_bifurcations_between_f (p_stream_code   IN NUMBER,
                                        p_station_1     IN BINARY_DOUBLE, -- in km
                                        p_station_2     IN BINARY_DOUBLE) -- in km
      RETURN number_tab_t
   IS
   BEGIN
      RETURN get_junctions_between_f (p_stream_code,
      'B', -- bifurcation
      p_station_1,
      p_station_2);
   END get_bifurcations_between_f;

--------------------------------------------------------------------------------
-- procedure get_us_location_codes
--
-- get location codes of upstream stations
--------------------------------------------------------------------------------
procedure get_us_location_codes(
   p_location_codes   in out nocopy number_tab_t,
   p_stream_code      in number,
   p_station          in binary_double, -- in km
   p_all_us_locations in boolean default false,
   p_same_stream_only in boolean default false)
is
   l_location_codes number_tab_t;
   l_stream_codes   number_tab_t;
      l_zero_station    VARCHAR2 (2);
      l_station         BINARY_DOUBLE;
   BEGIN
   --------------------------------------------------
   -- deterine if our stationing begins downstream --
   --------------------------------------------------
      SELECT zero_station
        INTO l_zero_station
        FROM at_stream
       WHERE stream_location_code = p_stream_code;

   ---------------------------------------------------
   -- get the next upstream location on this stream --
   ---------------------------------------------------
   l_location_codes := get_us_location_codes_f(p_stream_code, p_station);
   if l_location_codes.count > 0 then
      ----------------------------------
      -- add the location to our list --
      ----------------------------------
      for i in 1..l_location_codes.count loop
         p_location_codes.extend;
         p_location_codes(p_location_codes.count) := l_location_codes(i);
      end loop;
      -------------------------------------
      -- get the station of the location --
      -------------------------------------
      select station
        into l_station
        from at_stream_location
       where location_code = l_location_codes(1) -- all same station if more than one
        and stream_location_code = p_stream_code;
      -----------------------------------------------------
      -- get all further upstream locations if specified --
      -----------------------------------------------------
         IF p_all_us_locations
         THEN
            get_us_location_codes (p_location_codes,
            p_stream_code,
            l_station,
            true,
            p_same_stream_only);
      end if;
   else
      ---------------------------------------------------------------------------
      -- no next upstream location, set the station beyond the upstream extent --
      ---------------------------------------------------------------------------
         IF l_zero_station = 'DS'
         THEN
         l_station := binary_double_max_normal;
         ELSE
         l_station := -binary_double_max_normal;
      end if;
   end if;
   if not p_same_stream_only then
      -----------------------------------------------------------------------
      -- find all tribs that flow into this one upstream of here but below --
      -- the next upstream location (if any)                               --
      -----------------------------------------------------------------------
      l_stream_codes := get_confluences_between_f(p_stream_code, p_station, l_station);
      if l_stream_codes is not null and l_stream_codes.count > 0 then
         for i in 1..l_stream_codes.count loop
            ----------------------------------------------
            -- set the station to beyond the confluence --
            -- (taking station direction into account)  --
            ----------------------------------------------
            SELECT zero_station
              INTO l_zero_station
              FROM at_stream
             WHERE stream_location_code = l_stream_codes (i);

            IF l_zero_station = 'DS'
            THEN
               l_station := -binary_double_max_normal;
            ELSE
               l_station := binary_double_max_normal;
            END IF;

            ------------------------------------------------
            -- get all the upstream stations on the tribs --
            ------------------------------------------------
            get_us_location_codes (p_location_codes,
               l_stream_codes(i),
               l_station,
               p_all_us_locations);
         end loop;
      end if;
      ---------------------------------------------------------------
      -- at the head - continue up diverting stream if appropriate --
      ---------------------------------------------------------------
      if l_station in (binary_double_max_normal, -binary_double_max_normal) and
         (p_all_us_locations or p_location_codes.count = 0)
      then
         l_stream_codes := number_tab_t(null);
         select diverting_stream_code,
                diversion_station
           into l_stream_codes(1),
                l_station
           from at_stream
          where stream_location_code = p_stream_code;
         if l_stream_codes(1) is not null then
            get_us_location_codes(
               p_location_codes,
               l_stream_codes(1),
               l_station,
               p_all_us_locations);
         end if;
      end if;
   end if;
end get_us_location_codes;

--------------------------------------------------------------------------------
-- procedure get_ds_location_codes
--
-- get location codes of downstream stations
--------------------------------------------------------------------------------
procedure get_ds_location_codes(
   p_location_codes   in out nocopy number_tab_t,
   p_stream_code      in number,
   p_station          in binary_double, -- in km
   p_all_ds_locations in boolean default false,
   p_same_stream_only in boolean default false)
is
   l_location_codes number_tab_t;
   l_stream_codes   number_tab_t;
      l_zero_station    VARCHAR2 (2);
      l_station         BINARY_DOUBLE;
   BEGIN
   --------------------------------------------------
   -- deterine if our stationing begins downstream --
   --------------------------------------------------
      SELECT zero_station
        INTO l_zero_station
        FROM at_stream
       WHERE stream_location_code = p_stream_code;

   -----------------------------------------------------
   -- get the next downstream location on this stream --
   -----------------------------------------------------
   l_location_codes := get_ds_location_codes_f(p_stream_code, p_station);
   if l_location_codes.count > 0 then
      ----------------------------------
      -- add the location to our list --
      ----------------------------------
      for i in 1..l_location_codes.count loop
         p_location_codes.extend;
         p_location_codes(p_location_codes.count) := l_location_codes(i);
      end loop;
      -------------------------------------
      -- get the station of the location --
      -------------------------------------
      select station
        into l_station
        from at_stream_location
       where location_code = l_location_codes(1) -- all same station if more than one
        and stream_location_code = p_stream_code;
      -------------------------------------------------------
      -- get all further downstream locations if specified --
      -------------------------------------------------------
         IF p_all_ds_locations
         THEN
            get_ds_location_codes (p_location_codes,
            p_stream_code,
            l_station,
            true,
            p_same_stream_only);
      end if;
   else
      -------------------------------------------------------------------------------
      -- no next downstream location, set the station beyond the downstream extent --
      -------------------------------------------------------------------------------
         IF l_zero_station = 'DS'
         THEN
         l_station := -binary_double_max_normal;
         ELSE
         l_station := binary_double_max_normal;
         END IF;
      END IF;

   if not p_same_stream_only then
      --------------------------------------------------------------------------------
      -- find all diversions that flow out of this one downstream of here but above --
      -- the next downstream location (if any)                                      --
      --------------------------------------------------------------------------------
      l_stream_codes := get_bifurcations_between_f(p_stream_code, p_station, l_station);
      if l_stream_codes is not null and l_stream_codes.count > 0 then
         for i in 1..l_stream_codes.count loop
            ---------------------------------------------------
            -- set the station to beyond the upstream extent --
            -- (taking station direction into account)       --
            ---------------------------------------------------
            SELECT zero_station
              INTO l_zero_station
              FROM at_stream
             WHERE stream_location_code = l_stream_codes (i);

            IF l_zero_station = 'DS'
            THEN
               l_station := binary_double_max_normal;
            ELSE
               l_station := -binary_double_max_normal;
            END IF;

            -------------------------------------------------------
            -- get all the downstream stations on the diversions --
            -------------------------------------------------------
            get_ds_location_codes (p_location_codes,
               l_stream_codes(i),
               l_station,
               p_all_ds_locations);
         end loop;
      end if;
      ------------------------------------------------------------------
      -- at the mouth - continue down receiving stream if appropriate --
      ------------------------------------------------------------------
      if l_station in (binary_double_max_normal, -binary_double_max_normal) and
         (p_all_ds_locations or p_location_codes.count = 0)
      then
         l_stream_codes := number_tab_t(null);
         select receiving_stream_code,
                confluence_station
           into l_stream_codes(1),
                l_station
           from at_stream
          where stream_location_code = p_stream_code;
         if l_stream_codes(1) is not null then
            get_ds_location_codes(
               p_location_codes,
               l_stream_codes(1),
               l_station,
               p_all_ds_locations);
         end if;
      end if;
   end if;
end get_ds_location_codes;

--------------------------------------------------------------------------------
-- procedure get_us_locations
--------------------------------------------------------------------------------
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_same_stream_only in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is
   l_office_id      varchar2(16);
   l_stream_code    number(10);
   l_location_codes number_tab_t := number_tab_t();
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_station IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Station must not be null.');
      END IF;

   ----------------------------
   -- get the location codes --
   ----------------------------
      l_office_id := NVL (UPPER (p_office_id), cwms_util.user_office_id);
   l_stream_code := get_stream_code(l_office_id, p_stream_id);
   get_us_location_codes (
      l_location_codes,
      l_stream_code,
         cwms_util.convert_units (p_station,
                                  cwms_util.get_unit_id (p_station_unit),
                                  'km'),
      cwms_util.is_true(p_all_us_locations),
      cwms_util.is_true(p_same_stream_only));

      SELECT    bl.base_location_id
             || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
          ||pl.sub_location_id
          bulk collect
     into p_us_locations
     from table(l_location_codes) lc,
          at_stream_location sl,
          at_physical_location pl,
          at_base_location bl
    where sl.location_code = lc.column_value
      and pl.location_code = sl.location_code
      and bl.base_location_code = pl.base_location_code;
end get_us_locations;

--------------------------------------------------------------------------------
-- funtion get_us_locations_f
--------------------------------------------------------------------------------
function get_us_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_same_stream_only in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_locations str_tab_t := str_tab_t();
   BEGIN
      get_us_locations (l_locations,
      p_stream_id,
      p_station,
      p_station_unit,
      p_all_us_locations,
      p_same_stream_only,
      p_office_id);

   return l_locations;
end get_us_locations_f;

--------------------------------------------------------------------------------
-- procedure get_ds_locations
--------------------------------------------------------------------------------
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_stream_id        in  varchar2,
   p_station          in  binary_double,
   p_station_unit     in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_same_stream_only in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is
   l_office_id      varchar2(16);
   l_stream_code    number(10);
   l_location_codes number_tab_t := number_tab_t();
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_stream_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM', '<NULL>', 'CWMS stream identifier.');
      END IF;

      IF p_station IS NULL
      THEN
         cwms_err.raise ('ERROR', 'Station must not be null.');
      END IF;

   ----------------------------
   -- get the location codes --
   ----------------------------
      l_office_id := NVL (UPPER (p_office_id), cwms_util.user_office_id);
   l_stream_code := get_stream_code(l_office_id, p_stream_id);
   get_ds_location_codes (
      l_location_codes,
      l_stream_code,
         cwms_util.convert_units (p_station,
                                  cwms_util.get_unit_id (p_station_unit),
                                  'km'),
      cwms_util.is_true(p_all_ds_locations),
      cwms_util.is_true(p_same_stream_only));

      SELECT    bl.base_location_id
             || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
          ||pl.sub_location_id
          bulk collect
     into p_ds_locations
     from table(l_location_codes) lc,
          at_stream_location sl,
          at_physical_location pl,
          at_base_location bl
    where sl.location_code = lc.column_value
      and pl.location_code = sl.location_code
      and bl.base_location_code = pl.base_location_code;
end get_ds_locations;

--------------------------------------------------------------------------------
-- funtion get_ds_locations_f
--------------------------------------------------------------------------------
function get_ds_locations_f(
   p_stream_id        in varchar2,
   p_station          in binary_double,
   p_station_unit     in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_same_stream_only in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_locations str_tab_t := str_tab_t();
   BEGIN
      get_ds_locations (l_locations,
      p_stream_id,
      p_station,
      p_station_unit,
      p_all_ds_locations,
      p_same_stream_only,
      p_office_id);

   return l_locations;
   END get_ds_locations_f;

--------------------------------------------------------------------------------
-- procedure get_us_locations
--------------------------------------------------------------------------------
procedure get_us_locations(
   p_us_locations     out str_tab_t,
   p_location_id      in  varchar2,
   p_all_us_locations in  varchar2 default 'F',
   p_same_stream_only in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is
   l_station       binary_double;
   l_stream_code   number(10);
   l_location_code number(10);
   l_office_id     varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   -------------------------------
   -- get the codes and station --
   -------------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   begin
      select stream_location_code,
             station
        into l_stream_code,
             l_station
        from at_stream_location
       where location_code = l_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' is not a stream location');
      END;

   -----------------------------
   -- call the base procedure --
   -----------------------------
      get_us_locations (p_us_locations,
      cwms_loc.get_location_id(l_stream_code),
      l_station,
      'km',
      p_all_us_locations,
      p_same_stream_only,
      l_office_id);
   END get_us_locations;

--------------------------------------------------------------------------------
-- funtion get_us_locations_f
--------------------------------------------------------------------------------
function get_us_locations_f(
   p_location_id      in varchar2,
   p_all_us_locations in varchar2 default 'F',
   p_same_stream_only in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_us_locations str_tab_t := str_tab_t();
begin
   get_us_locations(
      l_us_locations,
      p_location_id,
      p_all_us_locations,
      p_same_stream_only,
      p_office_id);

      RETURN l_us_locations;
   END get_us_locations_f;

--------------------------------------------------------------------------------
-- procedure get_ds_locations
--------------------------------------------------------------------------------
procedure get_ds_locations(
   p_ds_locations     out str_tab_t,
   p_location_id      in  varchar2,
   p_all_ds_locations in  varchar2 default 'F',
   p_same_stream_only in  varchar2 default 'F',
   p_office_id        in  varchar2 default null)
is
   l_station       binary_double;
   l_stream_code   number(10);
   l_location_code number(10);
   l_office_id     varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
      IF p_location_id IS NULL
      THEN
         cwms_err.raise ('INVALID_ITEM',
         '<NULL>',
         'CWMS location identifier.');
   end if;
   -------------------------------
   -- get the codes and station --
   -------------------------------
   l_office_id := nvl(upper(p_office_id), cwms_util.user_office_id);
   l_location_code := cwms_loc.get_location_code(l_office_id, p_location_id);
   begin
      select stream_location_code,
             station
        into l_stream_code,
             l_station
        from at_stream_location
       where location_code = l_location_code;
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            'Location '
            ||l_office_id
            ||'/'
            ||p_location_id
            ||' is not a stream location');
      END;

   -----------------------------
   -- call the base procedure --
   -----------------------------
      get_ds_locations (p_ds_locations,
      cwms_loc.get_location_id(l_stream_code),
      l_station,
      'km',
      p_all_ds_locations,
      p_same_stream_only,
      l_office_id);
   END get_ds_locations;

--------------------------------------------------------------------------------
-- function get_ds_locations_f
--------------------------------------------------------------------------------
function get_ds_locations_f(
   p_location_id      in varchar2,
   p_all_ds_locations in varchar2 default 'F',
   p_same_stream_only in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return str_tab_t
is
   l_ds_locations str_tab_t := str_tab_t();
begin
   get_ds_locations(
      l_ds_locations,
      p_location_id,
      p_all_ds_locations,
      p_same_stream_only,
      p_office_id);

   return l_ds_locations;
end get_ds_locations_f;

--------------------------------------------------------------------------------
-- procedure get_us_locations2
--------------------------------------------------------------------------------
procedure get_us_locations2(
   p_us_locations     out sys_refcursor,
   p_stream_id        in  varchar,
   p_station          in  binary_double,
   p_station_unit     in  varchar,
   p_all_us_locations in  varchar default 'F',
   p_same_stream_only in  varchar default 'F',
   p_office_id        in  varchar default null)
is
   l_locations str_tab_t;
begin
   l_locations := get_us_locations_f(
      p_stream_id,
      p_station,
      p_station_unit,
      p_all_us_locations,
      p_same_stream_only,
      p_office_id);

   open p_us_locations for
      select loc.column_value as location_id,
             cwms_loc.get_location_id(sl.stream_location_code) as stream_id,
             cwms_util.convert_units(sl.station, 'km', p_station_unit) as station,
             sl.bank
        from table(l_locations) loc,
             at_stream_location sl
       where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value);
end get_us_locations2;

--------------------------------------------------------------------------------
-- function get_us_locations2_f
--------------------------------------------------------------------------------
function get_us_locations2_f(
   p_stream_id        in varchar,
   p_station          in binary_double,
   p_station_unit     in varchar,
   p_all_us_locations in varchar default 'F',
   p_same_stream_only in varchar default 'F',
   p_office_id        in varchar default null)
   return sys_refcursor
is
   l_us_locations sys_refcursor;
begin
   get_us_locations2(
      l_us_locations,
      p_stream_id,
      p_station,
      p_station_unit,
      p_all_us_locations,
      p_same_stream_only,
      p_office_id);

   return l_us_locations;
end get_us_locations2_f;

--------------------------------------------------------------------------------
-- procedure get_ds_locations2
--------------------------------------------------------------------------------
procedure get_ds_locations2(
   p_ds_locations     out sys_refcursor,
   p_stream_id        in  varchar,
   p_station          in  binary_double,
   p_station_unit     in  varchar,
   p_all_ds_locations in  varchar default 'F',
   p_same_stream_only in  varchar default 'F',
   p_office_id        in  varchar default null)
is
   l_locations str_tab_t;
begin
   l_locations := get_ds_locations_f(
      p_stream_id,
      p_station,
      p_station_unit,
      p_all_ds_locations,
      p_same_stream_only,
      p_office_id);

   open p_ds_locations for
      select loc.column_value as location_id,
             cwms_loc.get_location_id(sl.stream_location_code) as stream_id,
             cwms_util.convert_units(sl.station, 'km', p_station_unit) as station,
             sl.bank
        from table(l_locations) loc,
             at_stream_location sl
       where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value);
end get_ds_locations2;

--------------------------------------------------------------------------------
-- function get_ds_locations2_f
--------------------------------------------------------------------------------
function get_ds_locations2_f(
   p_stream_id        in varchar,
   p_station          in binary_double,
   p_station_unit     in varchar,
   p_all_ds_locations in varchar default 'F',
   p_same_stream_only in varchar default 'F',
   p_office_id        in varchar default null)
   return sys_refcursor
is
   l_ds_locations sys_refcursor;
begin
   get_ds_locations2(
      l_ds_locations,
      p_stream_id,
      p_station,
      p_station_unit,
      p_all_ds_locations,
      p_same_stream_only,
      p_office_id);

   return l_ds_locations;
end get_ds_locations2_f;

--------------------------------------------------------------------------------
-- procedure get_us_locations2
--------------------------------------------------------------------------------
procedure get_us_locations2(
   p_us_locations     out sys_refcursor,
   p_location_id      in  varchar,
   p_station_unit     in  varchar,
   p_all_us_locations in  varchar default 'F',
   p_same_stream_only in  varchar default 'F',
   p_office_id        in  varchar default null)
is
   l_locations str_tab_t;
begin
   l_locations := get_us_locations_f(
      p_location_id,
      p_all_us_locations,
      p_same_stream_only,
      p_office_id);

   open p_us_locations for
      select loc.column_value as location_id,
             cwms_loc.get_location_id(sl.stream_location_code) as stream_id,
             cwms_util.convert_units(sl.station, 'km', p_station_unit) as station,
             sl.bank
        from table(l_locations) loc,
             at_stream_location sl
       where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value);
end get_us_locations2;

--------------------------------------------------------------------------------
-- function get_us_locations2_f
--------------------------------------------------------------------------------
function get_us_locations2_f(
   p_location_id      in varchar,
   p_station_unit     in varchar,
   p_all_us_locations in varchar default 'F',
   p_same_stream_only in varchar default 'F',
   p_office_id        in varchar default null)
   return sys_refcursor
is
   l_us_locations sys_refcursor;
begin
   get_us_locations2(
      l_us_locations,
      p_location_id,
      p_station_unit,
      p_all_us_locations,
      p_same_stream_only,
      p_office_id);

   return l_us_locations;
end get_us_locations2_f;

--------------------------------------------------------------------------------
-- procedure get_ds_locations2
--------------------------------------------------------------------------------
procedure get_ds_locations2(
   p_ds_locations     out sys_refcursor,
   p_location_id      in  varchar,
   p_station_unit     in  varchar,
   p_all_ds_locations in  varchar default 'F',
   p_same_stream_only in  varchar default 'F',
   p_office_id        in  varchar default null)
is
   l_locations str_tab_t;
begin
   l_locations := get_ds_locations_f(
      p_location_id,
      p_all_ds_locations,
      p_same_stream_only,
      p_office_id);

   open p_ds_locations for
      select loc.column_value as location_id,
             cwms_loc.get_location_id(sl.stream_location_code) as stream_id,
             cwms_util.convert_units(sl.station, 'km', p_station_unit) as station,
             sl.bank
        from table(l_locations) loc,
             at_stream_location sl
       where sl.location_code = cwms_loc.get_location_code(p_office_id, loc.column_value);
end get_ds_locations2;

--------------------------------------------------------------------------------
-- function get_ds_locations2_f
--------------------------------------------------------------------------------
function get_ds_locations2_f(
   p_location_id      in varchar,
   p_station_unit     in varchar,
   p_all_ds_locations in varchar default 'F',
   p_same_stream_only in varchar default 'F',
   p_office_id        in varchar default null)
   return sys_refcursor
is
   l_ds_locations sys_refcursor;
begin
   get_ds_locations2(
      l_ds_locations,
      p_location_id,
      p_station_unit,
      p_all_ds_locations,
      p_same_stream_only,
      p_office_id);

   return l_ds_locations;
end get_ds_locations2_f;

--------------------------------------------------------------------------------
-- function is_upstream_of
--------------------------------------------------------------------------------
function is_upstream_of(
   p_stream_id    in varchar2,
   p_station      in binary_double,
   p_station_unit in varchar2,
   p_location_id  in varchar2,
   p_office_id    in varchar2 default null)
   return varchar2
is
   l_result       varchar2(1);
   l_location_ids str_tab_t;
   l_count        pls_integer;
begin
   l_location_ids := get_us_locations_f(
      p_stream_id        => p_stream_id,
      p_station          => p_station,
      p_station_unit     => p_station_unit,
      p_all_us_locations => 'T',
      p_same_stream_only => 'F',
      p_office_id        => p_office_id);

   select count(*)
     into l_count
     from table(l_location_ids)
    where upper(column_value) = upper(p_location_id);

   if l_count > 0 then
      l_result := 'T';
   else
      l_result := 'F';
   end if;
   return l_result;
end is_upstream_of;

--------------------------------------------------------------------------------
-- function is_upstream_of
--------------------------------------------------------------------------------
function is_upstream_of(
   p_anchor_location_id in varchar2,
   p_location_id        in varchar2,
   p_office_id          in varchar2 default null)
   return varchar2
is
   l_result       varchar2(1);
   l_location_ids str_tab_t;
   l_count        pls_integer;
begin
   l_location_ids := get_us_locations_f(
      p_location_id      => p_anchor_location_id,
      p_all_us_locations => 'T',
      p_same_stream_only => 'F',
      p_office_id        => p_office_id);

   select count(*)
     into l_count
     from table(l_location_ids)
    where upper(column_value) = upper(p_location_id);

   if l_count > 0 then
      l_result := 'T';
   else
      l_result := 'F';
   end if;
   return l_result;
end is_upstream_of;

--------------------------------------------------------------------------------
-- function is_downstream_of
--------------------------------------------------------------------------------
function is_downstream_of(
   p_stream_id    in varchar2,
   p_station      in binary_double,
   p_station_unit in varchar2,
   p_location_id  in varchar2,
   p_office_id    in varchar2 default null)
   return varchar2
is
   l_result       varchar2(1);
   l_location_ids str_tab_t;
   l_count        pls_integer;
begin
   l_location_ids := get_ds_locations_f(
      p_stream_id        => p_stream_id,
      p_station          => p_station,
      p_station_unit     => p_station_unit,
      p_all_ds_locations => 'T',
      p_same_stream_only => 'F',
      p_office_id        => p_office_id);

   select count(*)
     into l_count
     from table(l_location_ids)
    where upper(column_value) = upper(p_location_id);

   if l_count > 0 then
      l_result := 'T';
   else
      l_result := 'F';
   end if;
   return l_result;
end is_downstream_of;

--------------------------------------------------------------------------------
-- function is_downstream_of
--------------------------------------------------------------------------------
function is_downstream_of(
   p_anchor_location_id in varchar2,
   p_location_id        in varchar2,
   p_office_id          in varchar2 default null)
   return varchar2
is
   l_result       varchar2(1);
   l_location_ids str_tab_t;
   l_count        pls_integer;
begin
   l_location_ids := get_ds_locations_f(
      p_location_id      => p_anchor_location_id,
      p_all_ds_locations => 'T',
      p_same_stream_only => 'F',
      p_office_id        => p_office_id);

   select count(*)
     into l_count
     from table(l_location_ids)
    where upper(column_value) = upper(p_location_id);

   if l_count > 0 then
      l_result := 'T';
   else
      l_result := 'F';
   end if;
   return l_result;
end is_downstream_of;

--------------------------------------------------------------------------------
-- store_streamflow_meas_xml
--------------------------------------------------------------------------------
procedure store_streamflow_meas_xml(
   p_xml            in clob,
   p_fail_if_exists in varchar2)
is
   l_xml     xmltype;
   l_xml_tab xml_tab_t;
   l_meas    streamflow_meas_t;
begin
   l_xml := xmltype(p_xml);
   case l_xml.getrootelement
   when 'stream-flow-measurement' then
      ------------------------
      -- single measurement --
      ------------------------
      l_meas := streamflow_meas_t(l_xml);
      l_meas.store(p_fail_if_exists);
   when 'stream-flow-measurements' then
      --------------------------------------
      -- multiple measurements (possibly) --
      --------------------------------------
      l_xml_tab := cwms_util.get_xml_nodes(l_xml, '/*/stream-flow-measurement');
      for i in 1..l_xml_tab.count loop
         l_meas := streamflow_meas_t(l_xml_tab(i));
         l_meas.store(p_fail_if_exists);
      end loop;
   else
      cwms_err.raise(
         'ERROR',
         'Expected <stream-flow-measurement> or <stream-flow-measurements> as document root, got <'||l_xml.getrootelement||'>');
   end case;
end store_streamflow_meas_xml;

--------------------------------------------------------------------------------
-- function retrieve_streamflow_meas_objs
--------------------------------------------------------------------------------
function retrieve_streamflow_meas_objs(
   p_location_id_mask in varchar2,
   p_unit_system      in varchar2 default 'EN',
   p_min_date         in date default null,
   p_max_date         in date default null,
   p_min_height       in number default null,
   p_max_height       in number default null,
   p_min_flow         in number default null,
   p_max_flow         in number default null,
   p_min_num          in varchar2 default null,
   p_max_num          in varchar2 default null,
   p_agencies         in varchar2 default null,
   p_qualities        in varchar2 default null,
   p_time_zone        in varchar2 default null,
   p_office_id_mask   in varchar2 default null)
   return streamflow_meas_tab_t
is
   l_loc_tab          number_tab_t;
   l_meas_num_tab     str_tab_t;
   l_meas_tab         streamflow_meas_tab_t;
   l_location_id_mask varchar2(256) := cwms_util.normalize_wildcards(p_location_id_mask);
   l_office_id_mask   varchar2(64)  := cwms_util.normalize_wildcards(p_office_id_mask);
   l_height_unit      varchar2(16);
   l_flow_unit        varchar2(16);
   l_agencies         str_tab_t;
   l_qualities        str_tab_t;
begin
   l_height_unit := cwms_util.get_default_units('Stage', upper(trim(p_unit_system)));
   l_flow_unit   := cwms_util.get_default_units('Flow',  upper(trim(p_unit_system)));
   if p_agencies is not null then
      select trim(upper(column_value))
        bulk collect
        into l_agencies
        from table(cwms_util.split_text(p_agencies, ','));
      l_agencies.extend;
      l_agencies(l_agencies.count) := '@';
   end if;
   if p_qualities is not null then
      select substr(trim(upper(column_value)), 1, 1)
        bulk collect
        into l_qualities
        from table(cwms_util.split_text(p_qualities, ','));
      l_qualities.extend;
      l_qualities(l_qualities.count) := '@';
   end if;
   select distinct
          sm.location_code,
          sm.meas_number
     bulk collect
     into l_loc_tab,
          l_meas_num_tab
     from at_streamflow_meas sm,
          av_loc2 v2
    where v2.db_office_id like nvl(l_office_id_mask, cwms_util.user_office_id) escape '\'
      and v2.location_id like l_location_id_mask escape '\'
      and sm.location_code = v2.location_code
      and sm.date_time
          between
             case
             when p_min_date is null then
                date '1000-01-01'
             when p_time_zone is null then
                cwms_util.change_timezone(p_min_date, cwms_loc.get_local_timezone(sm.location_code), 'UTC')
             else
                cwms_util.change_timezone(p_min_date, p_time_zone)
             end
          and
             case
             when p_max_date is null then
                date '3000-01-01'
             when p_time_zone is null then
                cwms_util.change_timezone(p_max_date, cwms_loc.get_local_timezone(sm.location_code), 'UTC')
             else
                cwms_util.change_timezone(p_max_date, p_time_zone)
              end
      and sm.gage_height
          between
             case
             when p_min_height is null then sm.gage_height
             else cwms_util.convert_units(p_min_height, l_height_unit, 'm')
             end
          and
             case
             when p_max_height is null then sm.gage_height
             else cwms_util.convert_units(p_max_height, l_height_unit, 'm')
             end
      and sm.flow
          between
             case
             when p_min_flow is null then sm.flow
             else cwms_util.convert_units(p_min_flow, l_flow_unit, 'cms')
             end
          and
             case
             when p_max_flow is null then sm.flow
             else cwms_util.convert_units(p_max_flow, l_flow_unit, 'cms')
             end
      and sm.meas_number between nvl(p_min_num, sm.meas_number) and nvl(p_max_num, sm.meas_number)
      and nvl(sm.agency_id, '@') in (select * from table(
          case
          when l_agencies is not null then l_agencies
          else str_tab_t(nvl(sm.agency_id, '@'))
          end))
      and nvl(sm.quality, '@') in (select * from table(
          case
          when l_qualities is not null then l_qualities
          else str_tab_t(nvl(sm.quality, '@'))
          end))
    order by 1, 2;

   if l_loc_tab is not null then
      l_meas_tab := streamflow_meas_tab_t();
      l_meas_tab.extend(l_loc_tab.count);
      for i in 1..l_loc_tab.count loop
         l_meas_tab(i) := streamflow_meas_t(location_ref_t(l_loc_tab(i)), l_meas_num_tab(i));
      end loop;
   end if;
   return l_meas_tab;
end retrieve_streamflow_meas_objs;

--------------------------------------------------------------------------------
-- function retrieve_streamflow_meas_xml
--------------------------------------------------------------------------------
function retrieve_streamflow_meas_xml(
   p_location_id_mask in varchar2,
   p_unit_system      in varchar2 default 'EN',
   p_min_date         in date default null,
   p_max_date         in date default null,
   p_min_height       in number default null,
   p_max_height       in number default null,
   p_min_flow         in number default null,
   p_max_flow         in number default null,
   p_min_num          in varchar2 default null,
   p_max_num          in varchar2 default null,
   p_agencies         in varchar2 default null,
   p_qualities        in varchar2 default null,
   p_time_zone        in varchar2 default null,
   p_office_id_mask   in varchar2 default null)
   return clob
is
   l_clob     clob;
   l_meas_tab streamflow_meas_tab_t;
begin
   l_meas_tab := retrieve_streamflow_meas_objs(
      p_location_id_mask,
      p_unit_system,
      p_min_date,
      p_max_date,
      p_min_height,
      p_max_height,
      p_min_flow,
      p_max_flow,
      p_min_num,
      p_max_num,
      p_agencies,
      p_qualities,
      p_time_zone,
      p_office_id_mask);

   dbms_lob.createtemporary(l_clob, true);
   if l_meas_tab is null or l_meas_tab.count = 0 then
      cwms_util.append(l_clob, '<stream-flow-measurements/>'||chr(10));
   else
      cwms_util.append(l_clob, '<stream-flow-measurements>'||chr(10));
      For I In 1..L_Meas_Tab.Count Loop
         cwms_util.append(l_clob, l_meas_tab(i).to_string1||chr(10));
      end loop;
      cwms_util.append(l_clob, '</stream-flow-measurements>'||chr(10));
   end if;
   return l_clob;
end retrieve_streamflow_meas_xml;

--------------------------------------------------------------------------------
-- procedure delete_streamflow_meas
--------------------------------------------------------------------------------
procedure delete_streamflow_meas(
   p_location_id_mask in varchar2,
   p_unit_system      in varchar2 default 'EN',
   p_min_date         in date default null,
   p_max_date         in date default null,
   p_min_height       in number default null,
   p_max_height       in number default null,
   p_min_flow         in number default null,
   p_max_flow         in number default null,
   p_min_num          in varchar2 default null,
   p_max_num          in varchar2 default null,
   p_agencies         in varchar2 default null,
   p_qualities        in varchar2 default null,
   p_time_zone        in varchar2 default null,
   p_office_id_mask   in varchar2 default null)
is
   l_location_id_mask varchar2(256) := cwms_util.normalize_wildcards(p_location_id_mask);
   l_office_id_mask   varchar2(64)  := cwms_util.normalize_wildcards(p_office_id_mask);
   l_height_unit      varchar2(16);
   l_flow_unit        varchar2(16);
   l_agencies         str_tab_t;
   l_qualities        str_tab_t;
   l_time_zone        varchar2(28);
   l_min_date         date;
   l_max_date         date;
   l_min_height       number;
   l_max_height       number;
   l_min_flow         number;
   l_max_flow         number;
begin
   l_time_zone := nvl(p_time_zone, 'UTC');
   l_min_date    := cwms_util.change_timezone(p_min_date, l_time_zone, 'UTC');
   l_max_date    := cwms_util.change_timezone(p_max_date, l_time_zone, 'UTC');
   if coalesce(p_min_height, p_max_height, p_min_flow, p_max_flow) is not null then
      l_height_unit := cwms_util.get_default_units('Stage', upper(trim(p_unit_system)));
      l_flow_unit   := cwms_util.get_default_units('Flow',  upper(trim(p_unit_system)));
      l_min_height  := cwms_util.convert_to_db_units(p_min_height, 'Stage', l_height_unit);
      l_max_height  := cwms_util.convert_to_db_units(p_max_height, 'Stage', l_height_unit);
      l_min_flow    := cwms_util.convert_to_db_units(p_min_flow, 'Flow', l_flow_unit);
      l_max_flow    := cwms_util.convert_to_db_units(p_max_flow, 'Flow', l_flow_unit);
   end if;
   if p_agencies is null then
      select agcy_id
        bulk collect
        into l_agencies
        from cwms_usgs_agency;
      l_agencies.extend;
      l_agencies(l_agencies.count) := '@';
   else
      select trim(upper(column_value))
        bulk collect
        into l_agencies
        from table(cwms_util.split_text(p_agencies, ','));
   end if;
   if p_qualities is null then
      select qual_id
        bulk collect
        into l_qualities
        from cwms_usgs_meas_qual;
      l_qualities.extend;
      l_qualities(l_qualities.count) := '@';
   else
      select substr(trim(upper(column_value)), 1, 1)
        bulk collect
        into l_qualities
        from table(cwms_util.split_text(p_qualities, ','));
      l_qualities.extend;
   end if;
   delete
     from at_streamflow_meas
    where rowid in (select sm.rowid
                      from at_streamflow_meas sm,
                           av_loc2 v2
                     where v2.db_office_id like nvl(l_office_id_mask, cwms_util.user_office_id) escape '\'
                       and v2.location_id like l_location_id_mask escape '\'
                       and sm.location_code = v2.location_code
                       and sm.date_time between nvl(l_min_date, sm.date_time) and nvl(l_max_date, sm.date_time)
                       and sm.gage_height between nvl(l_min_height, sm.gage_height) and nvl(l_max_height, sm.gage_height)
                       and sm.flow between nvl(l_min_flow, sm.flow) and nvl(l_max_flow, sm.flow)
                       and sm.meas_number between nvl(p_min_num, sm.meas_number) and nvl(p_max_num, sm.meas_number)
                       and nvl(sm.agency_id, '@') in (select * from table(l_agencies))
                       and nvl(sm.quality, '@') in (select * from table(l_qualities))
                   );

end delete_streamflow_meas;


end cwms_stream;
/

---------------------------
--Changed PACKAGE BODY
--CWMS_OUTLET
---------------------------
CREATE OR REPLACE PACKAGE BODY "CWMS_OUTLET" 
AS
--------------------------------------------------------------------------------
-- function get_outlet_code
--------------------------------------------------------------------------------
   FUNCTION get_outlet_code (p_office_id   IN VARCHAR2,
                             p_outlet_id   IN VARCHAR2)
      RETURN NUMBER
   IS
      l_outlet_code   NUMBER (10);
      l_office_id     VARCHAR2 (16);
   BEGIN
      IF p_outlet_id IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'P_OUTLET_ID');
      END IF;

      l_office_id := NVL (UPPER (p_office_id), cwms_util.user_office_id);

      BEGIN
         l_outlet_code :=
            cwms_loc.get_location_code (l_office_id, p_outlet_id);

         SELECT outlet_location_code
           INTO l_outlet_code
           FROM at_outlet
          WHERE outlet_location_code = l_outlet_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.raise ('ITEM_DOES_NOT_EXIST',
            'CWMS outlet identifier.',
                            l_office_id || '/' || p_outlet_id);
      END;

      RETURN l_outlet_code;
   END get_outlet_code;

--------------------------------------------------------------------------------
-- procedure check_lookup
--------------------------------------------------------------------------------
   PROCEDURE check_lookup (p_lookup IN lookup_type_obj_t)
   IS
   BEGIN
      IF p_lookup.display_value IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The display_value member of a lookup_type_obj_t object cannot be null.');
      END IF;
   END check_lookup;

--------------------------------------------------------------------------------
-- procedure check_location_ref
--------------------------------------------------------------------------------
   PROCEDURE check_location_ref (p_location IN location_ref_t)
   IS
   BEGIN
      IF p_location.base_location_id IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The base_location_id member of a location_ref_t object cannot be null.');
      END IF;
   END check_location_ref;

--------------------------------------------------------------------------------
-- procedure check_location_obj
--------------------------------------------------------------------------------
   PROCEDURE check_location_obj (p_location IN location_obj_t)
   IS
   BEGIN
      IF p_location.location_ref IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The location_ref member of a location_obj_t object cannot be null.');
      END IF;

   check_location_ref(p_location.location_ref);
   END check_location_obj;

--------------------------------------------------------------------------------
-- procedure check_characteristic_ref
--------------------------------------------------------------------------------
   PROCEDURE check_characteristic_ref (
      p_characteristic IN characteristic_ref_t)
   IS
   BEGIN
      IF p_characteristic.office_id IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The office_id member of a characteristic_ref_t object cannot be null.');
      END IF;

      IF p_characteristic.characteristic_id IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The characteristic_id member of a characteristic_ref_t object cannot be null.');
      END IF;
   END check_characteristic_ref;

--------------------------------------------------------------------------------
-- procedure check_project_structure
--------------------------------------------------------------------------------
   PROCEDURE check_project_structure (
      p_project_struct IN project_structure_obj_t)
   IS
   BEGIN
      IF p_project_struct.project_location_ref IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The project_location_ref member of a p_project_struct object cannot be null.');
      END IF;

      IF p_project_struct.structure_location IS NULL
      THEN
      cwms_err.raise(
         'ERROR',
         'The structure_location member of a p_project_struct object cannot be null.');
      END IF;

   check_location_ref(p_project_struct.project_location_ref);
   check_location_obj(p_project_struct.structure_location);

      IF p_project_struct.characteristic_ref IS NOT NULL
      THEN
      check_characteristic_ref(p_project_struct.characteristic_ref);
      END IF;
   END check_project_structure;

--------------------------------------------------------------------------------
-- procedure check_gate_setting
--------------------------------------------------------------------------------
   PROCEDURE check_gate_setting (p_gate_setting IN gate_setting_obj_t)
   IS
   BEGIN
   check_location_ref(p_gate_setting.outlet_location_ref);
   END check_gate_setting;

--------------------------------------------------------------------------------
-- procedure check_gate_change
--------------------------------------------------------------------------------
   PROCEDURE check_gate_change (p_gate_change IN gate_change_obj_t)
   IS
   BEGIN
   check_location_ref(p_gate_change.project_location_ref);
   check_lookup(p_gate_change.discharge_computation);
   check_lookup(p_gate_change.release_reason);

      IF     p_gate_change.settings IS NOT NULL
         AND p_gate_change.settings.COUNT > 0
      THEN
         FOR i IN 1 .. p_gate_change.settings.COUNT
         LOOP
         check_gate_setting(p_gate_change.settings(i));
         END LOOP;
      END IF;
   END check_gate_change;

--------------------------------------------------------------------------------
-- function get_office_from_outlet
--------------------------------------------------------------------------------
   FUNCTION get_office_from_outlet (p_outlet_location_code IN NUMBER)
      RETURN NUMBER
   IS
      l_office_code   NUMBER (10);
   BEGIN
      SELECT bl.db_office_code
        INTO l_office_code
        FROM at_physical_location pl, at_base_location bl
       WHERE     pl.location_code = p_outlet_location_code
             AND bl.base_location_code = pl.base_location_code;

      RETURN l_office_code;
   END get_office_from_outlet;

--------------------------------------------------------------------------------
-- function get_outlet_opening_param
--------------------------------------------------------------------------------
   FUNCTION get_outlet_opening_param (p_outlet_location_code IN NUMBER)
      RETURN VARCHAR2
   IS
   l_ind_params str_tab_t;
      l_param         VARCHAR2 (16);
      l_alias         VARCHAR2 (256);        -- shared alias id is rating spec
      l_office_code   NUMBER (10)
                         := get_office_from_outlet (p_outlet_location_code);
   BEGIN
   ------------------------------------------
   -- get the rating spec for the location --
   ------------------------------------------
      BEGIN
         SELECT g.shared_loc_alias_id
           INTO l_alias
           FROM at_loc_category c, at_loc_group g, at_loc_group_assignment a
          WHERE     UPPER (c.loc_category_id) = 'RATING'
                AND c.db_office_code = l_office_code
                AND g.loc_category_code = c.loc_category_code
                AND g.db_office_code = c.db_office_code
                AND a.loc_group_code = g.loc_group_code
                AND a.location_code = p_outlet_location_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('ERROR',
                            'No rating is specified for outlet location');
      END;

   -------------------------------
   -- find the actual parameter --
   -------------------------------
      l_ind_params :=
      cwms_util.split_text(
         cwms_util.split_text(
               cwms_util.split_text (l_alias, 2, cwms_rating.separator1),
         1,
         cwms_rating.separator2),
      cwms_rating.separator3);

      FOR i IN 1 .. l_ind_params.COUNT
      LOOP
      l_param := cwms_util.split_text(l_ind_params(i), '-')(1);

         IF l_param NOT IN ('Count', 'Elev')
         THEN
            RETURN l_param;
         END IF;
      END LOOP;

   --------------------------------
   -- error : no parameter found --
   --------------------------------
      cwms_err.raise ('ERROR', 'No opening parameter found in ' || l_alias);
   END get_outlet_opening_param;

--------------------------------------------------------------------------------
-- function get_rating_spec
--------------------------------------------------------------------------------
   FUNCTION get_rating_spec (p_outlet_location_code    IN NUMBER,
                             p_project_location_code   IN NUMBER)
      RETURN VARCHAR2
   IS
      l_gate_type                  VARCHAR2 (32);
      l_rating_template_template   VARCHAR2 (24);
      l_rating_spec                VARCHAR2 (372);
   BEGIN
      SELECT sub_location_id
        INTO l_gate_type
        FROM at_physical_location
       WHERE location_code = p_outlet_location_code;

      l_gate_type :=
         UPPER (REGEXP_SUBSTR (l_gate_type,
                               '^(\D+).?$',
                               1,
                               1,
                               'i',
                               1));

      CASE
         WHEN l_gate_type = 'SG'
         THEN
            l_gate_type := 'Sluice';
         WHEN SUBSTR (l_gate_type, 1, 6) = 'SLUICE'
         THEN
            l_gate_type := 'Sluice';
         WHEN l_gate_type = 'CG'
         THEN
            l_gate_type := 'Conduit';
         WHEN SUBSTR (l_gate_type, 1, 7) = 'CONDUIT'
         THEN
            l_gate_type := 'Conduit';
         WHEN l_gate_type = 'TG'
         THEN
            l_gate_type := 'Spillway';
         WHEN SUBSTR (l_gate_type, 1, 7) = 'TAINTER'
         THEN
            l_gate_type := 'Spillway';
         WHEN SUBSTR (l_gate_type, 1, 8) = 'SPILLWAY'
         THEN
            l_gate_type := 'Spillway';
         WHEN l_gate_type = 'LF'
         THEN
            l_gate_type := 'Low_Flow';
         WHEN SUBSTR (l_gate_type, 1, 8) = 'LOW_FLOW'
         THEN
            l_gate_type := 'Low_Flow';
         ELSE
            NULL;
      END CASE;

      l_rating_template_template :=
         REPLACE (
      '%'
      ||cwms_rating.separator2
      ||'Flow-$_Gates'
      ||cwms_rating.separator1
      ||'%',
      '$',
      l_gate_type);

      BEGIN
         SELECT rating_id
           INTO l_rating_spec
           FROM cwms_v_rating_spec v,
             at_physical_location pl,
             at_base_location bl,
             cwms_office o
          WHERE     v.office_id = o.office_id
                AND v.location_id =
                          bl.base_location_id
                       || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
                             ||pl.sub_location_id
                AND v.template_id LIKE l_rating_template_template
                AND pl.location_code = p_project_location_code
                AND bl.base_location_code = pl.base_location_code
                AND o.office_code = bl.db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      RETURN l_rating_spec;
   END get_rating_spec;

--------------------------------------------------------------------------------
-- procedure assign_to_rating_group
--------------------------------------------------------------------------------
   PROCEDURE assign_to_rating_group (p_outlet_location_code    IN NUMBER,
                                     p_project_location_code   IN NUMBER,
                                     p_rating_group_id         IN VARCHAR2)
   IS
      l_category_rec     at_loc_category%ROWTYPE;
      l_group_rec        at_loc_group%ROWTYPE;
      l_assignment_rec   at_loc_group_assignment%ROWTYPE;
      l_office_code      NUMBER (10);
   BEGIN
   --------------------------------------------
   -- retrieve or create the rating category --
   --------------------------------------------
   l_category_rec.loc_category_id := 'Rating';
      l_category_rec.db_office_code :=
         get_office_from_outlet (p_outlet_location_code);

      BEGIN
         SELECT *
           INTO l_category_rec
           FROM at_loc_category
          WHERE     db_office_code = l_category_rec.db_office_code
                AND UPPER (loc_category_id) =
                       UPPER (l_category_rec.loc_category_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_category_rec.loc_category_code := cwms_seq.NEXTVAL;
            l_category_rec.loc_category_desc :=
               'Contains groups the relate outlets to ratings';

            INSERT INTO at_loc_category
                 VALUES l_category_rec;
      END;

   -----------------------------------------------------------
   -- verify the project and outlet are for the same office --
   -----------------------------------------------------------
      BEGIN
         SELECT bl2.db_office_code
           INTO l_office_code
           FROM at_physical_location pl1,
             at_base_location bl1,
             at_physical_location pl2,
             at_base_location bl2
          WHERE     pl1.location_code = p_outlet_location_code
                AND bl1.base_location_code = pl1.base_location_code
                AND pl2.location_code = p_project_location_code
                AND bl2.base_location_code = pl2.base_location_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
                  'Outlet ('
               || p_outlet_location_code
               || ') and Project ('
               || p_project_location_code
               || ') do not belong to the same office');
      END;

   --------------------------------------------------
   -- retrieve or create the assigned rating group --
   --------------------------------------------------
   l_group_rec.loc_category_code := l_category_rec.loc_category_code;
   l_group_rec.db_office_code    := l_category_rec.db_office_code;
   l_group_rec.loc_group_id      := p_rating_group_id;

      BEGIN
         SELECT *
           INTO l_group_rec
           FROM at_loc_group
          WHERE     loc_category_code = l_group_rec.loc_category_code
                AND db_office_code = l_group_rec.db_office_code
                AND UPPER (loc_group_id) = UPPER (l_group_rec.loc_group_id);

      ------------------------------------------------------
      -- verify we have the correct project location code --
      ------------------------------------------------------
         IF l_group_rec.shared_loc_ref_code != p_project_location_code
         THEN
         cwms_err.raise(
            'ERROR',
            'Shared location references (project locations) do not match.');
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_group_rec.loc_group_code := cwms_seq.NEXTVAL;
            l_group_rec.loc_group_desc :=
               'Shared alias contains rating spec for assigned outlets.';
            l_group_rec.shared_loc_alias_id :=
               get_rating_spec (p_outlet_location_code,
                                p_project_location_code);
         l_group_rec.shared_loc_ref_code := p_project_location_code;

            INSERT INTO at_loc_group
                 VALUES l_group_rec;
      END;

   ---------------------------------------
   -- unassign from other rating groups --
   ---------------------------------------
      DELETE FROM at_loc_group_assignment
            WHERE     location_code = p_outlet_location_code
                  AND loc_group_code IN
                         (SELECT loc_group_code
                            FROM at_loc_group
                           WHERE     loc_category_code =
                                        l_group_rec.loc_category_code
                                 AND loc_group_code !=
                                        l_group_rec.loc_group_code);

   ------------------------------------------------
   -- assign the location to the specified group --
   ------------------------------------------------
   l_assignment_rec.location_code  := p_outlet_location_code;
   l_assignment_rec.loc_group_code := l_group_rec.loc_group_code;
   l_assignment_rec.office_code    := l_office_code;

      BEGIN
         SELECT *
           INTO l_assignment_rec
           FROM at_loc_group_assignment
          WHERE     location_code = l_assignment_rec.location_code
                AND loc_group_code = l_assignment_rec.loc_group_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            INSERT INTO at_loc_group_assignment
                 VALUES l_assignment_rec;
      END;
   END assign_to_rating_group;

--------------------------------------------------------------------------------
-- procedure retrieve_outlet
--------------------------------------------------------------------------------
   PROCEDURE retrieve_outlet (p_outlet               OUT project_structure_obj_t,
                              p_outlet_location   IN     location_ref_t)
   IS
      l_rec   at_outlet%ROWTYPE;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_outlet_location IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_location');
      END IF;

   check_location_ref(p_outlet_location);
   ---------------------------
   -- get the outlet record --
   ---------------------------
   l_rec.outlet_location_code := p_outlet_location.get_location_code;

      BEGIN
         SELECT *
           INTO l_rec
           FROM at_outlet
          WHERE outlet_location_code = l_rec.outlet_location_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS outlet',
            p_outlet_location.get_office_id
            ||'/'
            ||p_outlet_location.get_location_id);
      END;

   ----------------------------
   -- build the out variable --
   ----------------------------
      p_outlet :=
         project_structure_obj_t (
      location_ref_t(l_rec.project_location_code),
      location_obj_t(l_rec.outlet_location_code),
            NULL);
   END retrieve_outlet;

--------------------------------------------------------------------------------
-- function retrieve_outlet_f
--------------------------------------------------------------------------------
   FUNCTION retrieve_outlet_f (p_outlet_location IN location_ref_t)
      RETURN project_structure_obj_t
   IS
   l_outlet project_structure_obj_t;
   BEGIN
   retrieve_outlet(l_outlet, p_outlet_location);
      RETURN l_outlet;
   END retrieve_outlet_f;

--------------------------------------------------------------------------------
-- procedure retrieve_outlets
--------------------------------------------------------------------------------
   PROCEDURE retrieve_outlets (p_outlets               OUT project_structure_tab_t,
                               p_project_location   IN     location_ref_t)
   IS
      TYPE outlet_recs_t IS TABLE OF at_outlet%ROWTYPE;

   l_recs          outlet_recs_t;
      l_project_code   NUMBER (10);
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_project_location IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_location');
      END IF;

   check_location_ref(p_project_location);
   ----------------------------
   -- get the outlet records --
   ----------------------------
   l_project_code := p_project_location.get_location_code;

      BEGIN
         SELECT project_location_code
           INTO l_project_code
           FROM at_project
          WHERE project_location_code = l_project_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         cwms_err.raise(
            'ITEM_DOES_NOT_EXIST',
            'CWMS project',
            p_project_location.get_office_id
            ||'/'
            ||p_project_location.get_location_id);
      END;

      BEGIN
         SELECT *
           BULK COLLECT INTO l_recs
           FROM at_outlet
          WHERE project_location_code = l_project_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

   ----------------------------
   -- build the out variable --
   ----------------------------
      IF l_recs IS NOT NULL AND l_recs.COUNT > 0
      THEN
      p_outlets := project_structure_tab_t();
         p_outlets.EXTEND (l_recs.COUNT);

         FOR i IN 1 .. l_recs.COUNT
         LOOP
            p_outlets (i) :=
               project_structure_obj_t (
            location_ref_t(l_recs(i).project_location_code),
            location_obj_t(l_recs(i).outlet_location_code),
                  NULL);
         END LOOP;
      END IF;
   END retrieve_outlets;

--------------------------------------------------------------------------------
-- function retrieve_outlets_f
--------------------------------------------------------------------------------
   FUNCTION retrieve_outlets_f (p_project_location IN location_ref_t)
      RETURN project_structure_tab_t
   IS
   l_outlets project_structure_tab_t;
   BEGIN
   retrieve_outlets(l_outlets, p_project_location);
      RETURN l_outlets;
   END retrieve_outlets_f;

--------------------------------------------------------------------------------
-- procedure store_outlet
--------------------------------------------------------------------------------
   PROCEDURE store_outlet (p_outlet           IN project_structure_obj_t,
                           p_rating_group     IN VARCHAR2 DEFAULT NULL,
                           p_fail_if_exists   IN VARCHAR2 DEFAULT 'T')
   IS
   BEGIN
      store_outlets (project_structure_tab_t (p_outlet),
                     p_rating_group,
                     p_fail_if_exists);
   END store_outlet;

--------------------------------------------------------------------------------
-- procedure store_outlets
--------------------------------------------------------------------------------
   PROCEDURE store_outlets (p_outlets          IN project_structure_tab_t,
                            p_rating_group     IN VARCHAR2 DEFAULT NULL,
                            p_fail_if_exists   IN VARCHAR2 DEFAULT 'T')
   IS
      l_fail_if_exists     BOOLEAN;
      l_exists             BOOLEAN;
   l_project          project_obj_t;
      l_rec                at_outlet%ROWTYPE;
      l_rating_group       VARCHAR2 (65);
      l_code               INTEGER;
      l_location_kind_id   cwms_location_kind.location_kind_id%TYPE;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_outlets IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'P_OUTLETS');
      END IF;

   l_fail_if_exists := cwms_util.is_true(p_fail_if_exists);

      FOR i IN 1 .. p_outlets.COUNT
      LOOP
      ------------------------
      -- more sanity checks --
      ------------------------
         BEGIN
            l_code :=
               p_outlets (i).structure_location.location_ref.get_location_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         IF l_code IS NOT NULL
         THEN
         l_location_kind_id := cwms_loc.check_location_kind(l_code);

            IF l_location_kind_id NOT IN ('OUTLET', 'STREAMGAGE', 'SITE')
            THEN
            cwms_err.raise(
               'ERROR',
               'Cannot switch location '
               ||p_outlets(i).structure_location.location_ref.office_id
               ||'/'
               ||p_outlets(i).structure_location.location_ref.get_location_id
               ||' from type '
               ||l_location_kind_id
               ||' to type OUTLET');
            END IF;
         END IF;

      check_project_structure(p_outlets(i));
      -- will raise an exception if project doesn't exist
      cwms_project.retrieve_project(
         l_project,
         p_outlets(i).project_location_ref.get_location_id,
         p_outlets(i).project_location_ref.get_office_id);
      -- project exists, so get its location code
         l_rec.project_location_code :=
            l_project.project_location.location_ref.get_location_code ('F');

      -----------------------------------------------
      -- create a rating group id if not specified --
      -----------------------------------------------
         IF i = 1
         THEN
            l_rating_group :=
               NVL (p_rating_group,
                    p_outlets (i).project_location_ref.get_location_id);
         END IF;

      -----------------------------------------------
      -- see if the outlet location already exists --
      -----------------------------------------------
         BEGIN
            l_rec.outlet_location_code :=
               p_outlets (i).structure_location.location_ref.get_location_code (
                  'F');
            l_exists := TRUE;                               -- Location Exists
            l_location_kind_id :=
               cwms_loc.check_location_kind (l_rec.outlet_location_code);

            IF l_location_kind_id = 'OUTLET'
            THEN
               IF l_fail_if_exists
               THEN
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'CWMS outlet',
               p_outlets(i).structure_location.location_ref.get_office_id
               ||'/'
               ||p_outlets(i).structure_location.location_ref.get_location_id);
               END IF;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_exists := FALSE;                   -- Location Does not exist
               cwms_loc.store_location (p_outlets (i).structure_location,
                                        'F');
         END;

      -----------------------
      -- create the record --
      -----------------------
         l_rec.outlet_location_code :=
            p_outlets (i).structure_location.location_ref.get_location_code (
               'T');

         IF l_location_kind_id = 'OUTLET'
         THEN
            UPDATE at_outlet
               SET project_location_code = l_rec.project_location_code
             WHERE outlet_location_code = l_rec.outlet_location_code;
         ELSE
            INSERT INTO at_outlet
                 VALUES l_rec;
         END IF;

      -----------------------------------------------------
      -- assign the record to the specified rating group --
      -----------------------------------------------------
         assign_to_rating_group (l_rec.outlet_location_code,
      l_rec.project_location_code,
      l_rating_group);

      ---------------------------
      -- set the location kind --
      ---------------------------
         UPDATE at_physical_location
            SET location_kind =
                   (SELECT location_kind_code
                      FROM cwms_location_kind
                     WHERE location_kind_id = 'OUTLET')
          WHERE location_code = l_rec.outlet_location_code;
      END LOOP;
   END store_outlets;

--------------------------------------------------------------------------------
-- procedure rename_outlet
--------------------------------------------------------------------------------
   PROCEDURE rename_outlet (p_outlet_id_old   IN VARCHAR2,
                            p_outlet_id_new   IN VARCHAR2,
                            p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
   l_outlet project_structure_obj_t;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_outlet_id_old IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_id_old');
      END IF;

      IF p_outlet_id_new IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet_id_new');
      END IF;

      IF p_office_id IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_office_id');
      END IF;

      l_outlet :=
         retrieve_outlet_f (location_ref_t (p_outlet_id_old, p_office_id));
      cwms_loc.rename_location (p_outlet_id_old,
                                p_outlet_id_new,
                                p_office_id);
   END rename_outlet;

--------------------------------------------------------------------------------
-- procedure delete_outlet
--------------------------------------------------------------------------------
   PROCEDURE delete_outlet (
      p_outlet_id       IN VARCHAR,
      p_delete_action   IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      delete_outlet2 (p_outlet_id       => p_outlet_id,
      p_delete_action => p_delete_action,
      p_office_id     => p_office_id);
   END delete_outlet;

--------------------------------------------------------------------------------
-- procedure delete_outlet2
--------------------------------------------------------------------------------
   PROCEDURE delete_outlet2 (
      p_outlet_id                IN VARCHAR2,
      p_delete_action            IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_delete_location          IN VARCHAR2 DEFAULT 'F',
      p_delete_location_action   IN VARCHAR2 DEFAULT cwms_util.delete_key,
      p_office_id                IN VARCHAR2 DEFAULT NULL)
   IS
      l_outlet_code          NUMBER (10);
      l_delete_location      BOOLEAN;
      l_delete_action1       VARCHAR2 (16);
      l_delete_action2       VARCHAR2 (16);
   l_gate_change_codes  number_tab_t;
      l_count                PLS_INTEGER;
      l_location_kind_code   INTEGER;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_outlet_id IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'P_outlet_ID');
      END IF;

      l_delete_action1 := UPPER (SUBSTR (p_delete_action, 1, 16));

      IF l_delete_action1 NOT IN
            (cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
      THEN
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
      END IF;

   l_delete_location := cwms_util.return_true_or_false(p_delete_location);
      l_delete_action2 := UPPER (SUBSTR (p_delete_location_action, 1, 16));

      IF l_delete_action2 NOT IN
            (cwms_util.delete_key,
      cwms_util.delete_data,
      cwms_util.delete_all)
      THEN
      cwms_err.raise(
         'ERROR',
         'Delete action must be one of '''
         ||cwms_util.delete_key
         ||''',  '''
         ||cwms_util.delete_data
         ||''', or '''
         ||cwms_util.delete_all
         ||'');
      END IF;

   l_outlet_code := get_outlet_code(p_office_id, p_outlet_id);

   -------------------------------------------
   -- delete the child records if specified --
   -------------------------------------------
      IF l_delete_action1 IN (cwms_util.delete_data, cwms_util.delete_all)
      THEN
         SELECT gate_change_code
           BULK COLLECT INTO l_gate_change_codes
           FROM at_gate_change
          WHERE gate_change_code IN
                   (SELECT gate_change_code
                      FROM at_gate_setting
                     WHERE outlet_location_code = l_outlet_code);

         DELETE FROM at_gate_setting
               WHERE gate_change_code IN
                        (SELECT * FROM TABLE (l_gate_change_codes));

         DELETE FROM at_gate_change
               WHERE gate_change_code IN
                        (SELECT * FROM TABLE (l_gate_change_codes));
      END IF;

   ------------------------------------
   -- delete the record if specified --
   ------------------------------------
      IF l_delete_action1 IN (cwms_util.delete_key, cwms_util.delete_all)
      THEN
         DELETE FROM at_outlet
               WHERE outlet_location_code = l_outlet_code;
      END IF;

   -------------------------------------
   -- delete the location if required --
   -------------------------------------
      IF l_delete_location
      THEN
         cwms_loc.delete_location (p_outlet_id,
                                   l_delete_action2,
                                   p_office_id);
      ELSE
         SELECT COUNT (*)
           INTO l_count
           FROM at_stream_location
          WHERE location_code = l_outlet_code;

         IF l_count = 0
         THEN
            SELECT location_kind_code
              INTO l_location_kind_code
              FROM cwms_location_kind
             WHERE location_kind_id = 'SITE';
         ELSE
            SELECT location_kind_code
              INTO l_location_kind_code
              FROM cwms_location_kind
             WHERE location_kind_id = 'STREAMGAGE';
         END IF;

         UPDATE at_physical_location
            SET location_kind = l_location_kind_code
          WHERE location_code = l_outlet_code;
      END IF;
   END delete_outlet2;

--------------------------------------------------------------------------------
-- procedure assign_to_rating_group
--------------------------------------------------------------------------------
   PROCEDURE assign_to_rating_group (
      p_outlet         IN project_structure_obj_t,
      p_rating_group   IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_outlet IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_outlet');
      END IF;

      assign_to_rating_group (project_structure_tab_t (p_outlet),
                              p_rating_group);
   END assign_to_rating_group;

--------------------------------------------------------------------------------
-- procedure assign_to_rating_group
--------------------------------------------------------------------------------
   PROCEDURE assign_to_rating_group (
      p_outlets        IN project_structure_tab_t,
      p_rating_group   IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_outlets IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_outlets');
      END IF;

      FOR i IN 1 .. p_outlets.COUNT
      LOOP
      check_project_structure(p_outlets(i));
      assign_to_rating_group(
         p_outlets(i).structure_location.location_ref.get_location_code,
         p_outlets(i).project_location_ref.get_location_code,
         p_rating_group);
      END LOOP;
   END assign_to_rating_group;

--------------------------------------------------------------------------------
-- procedure store_gate_changes
--------------------------------------------------------------------------------
procedure store_gate_changes(
   p_gate_changes         in gate_change_tab_t,
   p_start_time           in date default null,
   p_end_time             in date default null,
   p_time_zone            in varchar2 default null,
   p_start_time_inclusive in varchar2 default 'T',
   p_end_time_inclusive   in varchar2 default 'T',
   p_override_protection  in varchar2 default 'F')
is
   type db_units_by_opening_units_t is table of varchar2(16) index by varchar2(16);
   l_proj_loc_code    number(10);
   l_office_code      number(10);
   l_office_id        varchar2(16);
   l_change_date      date;
   l_start_time       date;
   l_end_time         date;
   l_time_zone        varchar2(28);
   l_change_rec       at_gate_change%rowtype;
   l_setting_rec      at_gate_setting%rowtype;
   l_dates            date_table_type;
   l_existing         gate_change_tab_t;
   l_new_change_date  date;
   l_gate_codes       number_tab_t;
   l_count            pls_integer;
   l_db_units         db_units_by_opening_units_t;
   l_units1           str_tab_t;
   l_units2           str_tab_t;
   l_db_unit          varchar2(16);
begin
   -------------------
   -- sanity checks --
   -------------------
      IF p_gate_changes IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_gate_changes');
      ELSIF p_gate_changes.COUNT = 0
      THEN
      cwms_err.raise('ERROR', 'No gate changes specified.');
      END IF;

      FOR i IN 1 .. p_gate_changes.COUNT
      LOOP
      check_gate_change(p_gate_changes(i));
      END LOOP;

      IF p_override_protection NOT IN ('T', 'F')
      THEN
         cwms_err.raise (
            'ERROR',
      'Parameter p_override_protection must be either ''T'' or ''F''');
      END IF;

      IF     p_start_time IS NULL
         AND NOT cwms_util.is_true (p_start_time_inclusive)
      THEN
      cwms_err.raise(
         'ERROR',
         'Cannot specify exclusive start time with implicit start time');
      END IF;

      IF p_end_time IS NULL AND NOT cwms_util.is_true (p_end_time_inclusive)
      THEN
      cwms_err.raise(
         'ERROR',
         'Cannot specify exclusive end time with implicit end time');
   end if;
   for i in 1..p_gate_changes.count loop
      if i = 1 then
         l_proj_loc_code := p_gate_changes(i).project_location_ref.get_location_code;
         l_office_id     := upper(trim(p_gate_changes(i).project_location_ref.get_office_id));
         l_office_code   := p_gate_changes(i).project_location_ref.get_office_code;
         l_change_date   := p_gate_changes(i).change_date;
         ELSE
            IF p_gate_changes (i).project_location_ref.get_location_code !=
                  l_proj_loc_code
            THEN
               cwms_err.raise ('ERROR',
               'Multiple projects found in gate changes.');
         end if;
         if p_gate_changes(i).change_date <= l_change_date then
            cwms_err.raise(
               'ERROR',
               'Gate changes are not in ascending time order.');
         end if;
      end if;
      if upper(trim(p_gate_changes(i).discharge_computation.office_id)) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'gate change for office '
            ||l_office_id
            ||' cannot reference discharge computation for office '
            ||upper(p_gate_changes(i).discharge_computation.office_id));
      end if;
      if upper(trim(p_gate_changes(i).release_reason.office_id)) != l_office_id then
         cwms_err.raise(
            'ERROR',
            'gate change for office '
            ||l_office_id
            ||' cannot reference release reason for office '
            ||upper(p_gate_changes(i).release_reason.office_id));
      end if;

         BEGIN
            SELECT discharge_comp_code
              INTO l_change_rec.discharge_computation_code
              FROM at_gate_ch_computation_code
             WHERE     db_office_code = l_office_code
                   AND UPPER (discharge_comp_display_value) =
                          UPPER (
                             p_gate_changes (i).discharge_computation.display_value)
                   AND UPPER (discharge_comp_tooltip) =
                          UPPER (
                             p_gate_changes (i).discharge_computation.tooltip)
                   AND discharge_comp_active =
                          UPPER (
                             p_gate_changes (i).discharge_computation.active);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS gate change computation',
               l_office_id
               ||'/DISPLAY='
               ||p_gate_changes(i).discharge_computation.display_value
               ||'/TOOLTIP='
               ||p_gate_changes(i).discharge_computation.tooltip
               ||'/ACTIVE='
               ||p_gate_changes(i).discharge_computation.active);
         END;

         BEGIN
            SELECT release_reason_code
              INTO l_change_rec.release_reason_code
              FROM at_gate_release_reason_code
             WHERE     db_office_code = l_office_code
                   AND UPPER (release_reason_display_value) =
                          UPPER (
                             p_gate_changes (i).release_reason.display_value)
                   AND UPPER (release_reason_tooltip) =
                          UPPER (p_gate_changes (i).release_reason.tooltip)
                   AND release_reason_active =
                          UPPER (p_gate_changes (i).release_reason.active);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS gate release reason',
               l_office_id
               ||'/DISPLAY='
               ||p_gate_changes(i).release_reason.display_value
               ||'/TOOLTIP='
               ||p_gate_changes(i).release_reason.tooltip
               ||'/ACTIVE='
               ||p_gate_changes(i).release_reason.active);
      end;
   end loop;
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_start_time := nvl(p_start_time, p_gate_changes(1).change_date);
   l_end_time   := nvl(p_end_time,   p_gate_changes(p_gate_changes.count).change_date);
   l_time_zone  := nvl(p_time_zone, cwms_loc.get_local_timezone(l_proj_loc_code));
   if l_time_zone is not null then
      l_start_time := cwms_util.change_timezone(l_start_time, l_time_zone, 'UTC');
      l_end_time   := cwms_util.change_timezone(l_end_time,   l_time_zone, 'UTC');
   end if;
   -------------------------------------------------------------
   -- delete any existing gate changes in the time window     --
   -- that doesn't have a corrsponding time in the input data --
   -------------------------------------------------------------
   select cwms_util.change_timezone(change_date, nvl(l_time_zone, 'UTC'), 'UTC')
     bulk collect
     into l_dates
     from table(p_gate_changes);

   l_existing := retrieve_gate_changes_f(
      p_project_location => p_gate_changes(1).project_location_ref,
      p_start_time       => l_start_time,
      p_end_time         => l_end_time);

   for rec in
      (select change_date
        from table(l_existing)
       where change_date not in (select * from table(l_dates))
      )
   loop
      delete_gate_changes(
         p_project_location    => p_gate_changes(1).project_location_ref,
         p_start_time          => rec.change_date,
         p_end_time            => rec.change_date,
         p_override_protection => p_override_protection);
   end loop;

   ---------------------------
   -- insert/update records --
   ---------------------------
   for i in 1..p_gate_changes.count loop
      l_new_change_date := cwms_util.change_timezone(p_gate_changes(i).change_date, nvl(l_time_zone, 'UTC'), 'UTC');
      -----------------------------------------
      -- retrieve any existing change record --
      -----------------------------------------
      begin
         select *
           into l_change_rec
           from at_gate_change
          where project_location_code = l_proj_loc_code
            and gate_change_date = l_new_change_date;
      exception
         when no_data_found then
            l_change_rec.gate_change_code := null;
            l_change_rec.project_location_code := l_proj_loc_code;
            l_change_rec.gate_change_date := l_new_change_date;
      end;
      --------------------------------
      -- populate the change record --
      --------------------------------
      l_change_rec.gate_change_date := l_new_change_date;
      l_change_rec.elev_pool := cwms_util.convert_units(
         p_gate_changes(i).elev_pool,
         p_gate_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.elev_tailwater := cwms_util.convert_units(
         p_gate_changes(i).elev_tailwater,
         p_gate_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      l_change_rec.old_total_discharge_override := cwms_util.convert_units(
         p_gate_changes(i).old_total_discharge_override,
         p_gate_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      l_change_rec.new_total_discharge_override := cwms_util.convert_units(
         p_gate_changes(i).new_total_discharge_override,
         p_gate_changes(i).discharge_units,
         cwms_util.get_default_units('Flow'));
      select discharge_comp_code
        into l_change_rec.discharge_computation_code
        from at_gate_ch_computation_code
       where db_office_code = l_office_code
         and upper(discharge_comp_display_value) = upper(p_gate_changes(i).discharge_computation.display_value)
         and upper(discharge_comp_tooltip) = upper(p_gate_changes(i).discharge_computation.tooltip)
         and discharge_comp_active = upper(p_gate_changes(i).discharge_computation.active);
      select release_reason_code
        into l_change_rec.release_reason_code
        from at_gate_release_reason_code
       where db_office_code = l_office_code
         and upper(release_reason_display_value) = upper(p_gate_changes(i).release_reason.display_value)
         and upper(release_reason_tooltip) = upper(p_gate_changes(i).release_reason.tooltip)
         and release_reason_active = upper(p_gate_changes(i).release_reason.active);
      l_change_rec.gate_change_notes := p_gate_changes(i).change_notes;
      l_change_rec.protected := upper(p_gate_changes(i).protected);
      l_change_rec.reference_elev := cwms_util.convert_units(
         p_gate_changes(i).reference_elev,
         p_gate_changes(i).elev_units,
         cwms_util.get_default_units('Elev'));
      -------------------------------------
      -- insert/update the change record --
      -------------------------------------
      if l_change_rec.gate_change_code is null then
         l_change_rec.gate_change_code := cwms_seq.nextval;
         insert into at_gate_change values l_change_rec;
      else
         update at_gate_change
            set row = l_change_rec
          where gate_change_code = l_change_rec.gate_change_code;
      end if;
      -------------------------------------------------------------------------
      -- collect the gate location codes from the input data for this change --
      -------------------------------------------------------------------------
      l_gate_codes := number_tab_t();
      l_count := nvl(p_gate_changes(i).settings, gate_setting_tab_t()).count;
      l_gate_codes.extend(l_count);
      for j in 1..l_count loop
         l_gate_codes(j) := p_gate_changes(i).settings(j).outlet_location_ref.get_location_code;
      end loop;
      -------------------------------------------------------------------------------
      -- delete any existing gate setting record not in input data for this change --
      -------------------------------------------------------------------------------
      delete
        from at_gate_setting
       where gate_change_code = l_change_rec.gate_change_code
         and outlet_location_code not in (select * from table(l_gate_codes));
      ---------------------------------
      -- insert/update gate settings --
      ---------------------------------
      for j in 1..l_gate_codes.count loop
         ------------------------------------------
         -- retrieve any existing setting record --
         ------------------------------------------
         begin
            select *
              into l_setting_rec
              from at_gate_setting
             where gate_change_code = l_change_rec.gate_change_code
               and outlet_location_code = l_gate_codes(j);
         exception
            when no_data_found then
               l_setting_rec.gate_setting_code := null;
            l_setting_rec.gate_change_code := l_change_rec.gate_change_code;
               l_setting_rec.outlet_location_code := l_gate_codes(j);
         end;
         ---------------------------------
         -- populate the setting record --
         ---------------------------------
         if p_gate_changes(i).settings(j).opening_parameter is null then
            if l_db_units.count = 0 then
               select cu1.unit_id,
                      cu2.unit_id
                 bulk collect
                 into l_units1,
                      l_units2
                 from cwms_unit cu1,
                      cwms_unit cu2,
                      cwms_base_parameter bp
                where bp.base_parameter_id in ('%', 'Opening', 'Rotation')
                  and bp.abstract_param_code = cu1.abstract_param_code
                  and cu2.unit_code = bp.unit_code;

               for k in 1..l_units1.count loop
                  l_db_units(l_units1(k)) := l_units2(k);
               end loop;
            end if;
            begin
               l_db_unit := l_db_units(cwms_util.get_unit_id(p_gate_changes(i).settings(j).opening_units));
            exception
               when others then
                  cwms_err.raise(
                     'ERROR',
                     'Cannot determine database storage unit for opening unit "'
                     ||p_gate_changes(i).settings(j).opening_units
                     ||'"');
            end;
         else
            begin
               l_db_unit := cwms_util.get_default_units(p_gate_changes(i).settings(j).opening_parameter);
            exception
               when others then
                  cwms_err.raise(
                     'ERROR',
                     'Cannot determine database storage unit for opening parameter "'
                     ||p_gate_changes(i).settings(j).opening_parameter
                     ||'"');
            end;
         end if;
         l_setting_rec.gate_opening := cwms_util.convert_units(
               p_gate_changes(i).settings(j).opening,
               p_gate_changes(i).settings(j).opening_units,
            l_db_unit);
            l_setting_rec.invert_elev := cwms_util.convert_units(
               p_gate_changes(i).settings(j).invert_elev,
            --p_gate_changes(i).settings(j).elev_units, !! modify object to have this !!
               p_gate_changes(i).elev_units,
               cwms_util.get_default_units('Elev'));
         --------------------------------------
         -- insert/update the setting record --
         --------------------------------------
         if l_setting_rec.gate_setting_code is null then
            l_setting_rec.gate_setting_code := cwms_seq.nextval;
            insert into at_gate_setting values l_setting_rec;
         else
            update at_gate_setting
               set row = l_setting_rec
             where gate_setting_code = l_setting_rec.gate_setting_code;
         end if;
         end loop;
   end loop;
end store_gate_changes;
--------------------------------------------------------------------------------
-- procedure retrieve_gate_changes
--------------------------------------------------------------------------------
   PROCEDURE retrieve_gate_changes (
      p_gate_changes              OUT gate_change_tab_t,
      p_project_location       IN     location_ref_t,
      p_start_time             IN     DATE,
      p_end_time               IN     DATE,
      p_time_zone              IN     VARCHAR2 DEFAULT NULL,
      p_unit_system            IN     VARCHAR2 DEFAULT NULL,
      p_start_time_inclusive   IN     VARCHAR2 DEFAULT 'T',
      p_end_time_inclusive     IN     VARCHAR2 DEFAULT 'T',
      p_max_item_count         IN     INTEGER DEFAULT NULL)
   IS
      TYPE gate_change_db_tab_t IS TABLE OF at_gate_change%ROWTYPE;

      TYPE gate_setting_db_tab_t IS TABLE OF at_gate_setting%ROWTYPE;

      c_one_second   CONSTANT NUMBER := 1 / 86400;
      l_time_zone             VARCHAR2 (28);
      l_unit_system           VARCHAR2 (2);
      l_start_time            DATE;
      l_end_time              DATE;
   l_project       project_obj_t;
      l_proj_loc_code         NUMBER (10);
   l_gate_changes  gate_change_db_tab_t;
   l_gate_settings gate_setting_db_tab_t;
      l_elev_unit             VARCHAR2 (16);
      l_flow_unit             VARCHAR2 (16);
      l_opening_param         VARCHAR2 (49);
      l_opening_unit          VARCHAR2 (16);
      l_sql                   VARCHAR2 (1024)
         := '
        select *
          from ( select *
                   from at_gate_change
                  where project_location_code = :project_location_code
                    and gate_change_date between :start_time and :end_time
               order by gate_change_date ~direction~
               )
         where rownum <= :max_items
      order by gate_change_date';
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_project_location IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
      END IF;

      IF p_start_time IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
      END IF;

      IF p_end_time IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');
      END IF;

      IF p_max_item_count = 0
      THEN
      cwms_err.raise(
         'ERROR',
         'Max item count must not be zero. Use NULL for unlimited.');
      END IF;

      IF p_start_time > p_end_time
      THEN
         cwms_err.raise ('ERROR',
         'Start time must not be later than end time.');
      END IF;

   check_location_ref(p_project_location);
   -- will barf if not a valid project
      cwms_project.retrieve_project (l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   -------------------------
   -- get the unit system --
   -------------------------
   l_unit_system :=
         UPPER (SUBSTR (NVL (p_unit_system,
               cwms_properties.get_property(
                  'Pref_User.'||cwms_util.get_user_id,
                  'Unit_System',
                  cwms_properties.get_property(
                     'Pref_Office',
                     'Unit_System',
                     'SI',
                     p_project_location.get_office_id),
                  p_project_location.get_office_id)),
                        1,
                        2));
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;
      l_time_zone :=
         NVL (p_time_zone, cwms_loc.get_local_timezone (l_proj_loc_code));
      l_start_time :=
         cwms_util.change_timezone (p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');

      IF NOT cwms_util.is_true (p_start_time_inclusive)
      THEN
      l_start_time := l_start_time + c_one_second;
      END IF;

      IF NOT cwms_util.is_true (p_end_time_inclusive)
      THEN
      l_end_time := l_end_time - c_one_second;
      END IF;

   -------------------------------------
   -- collect the gate change records --
   -------------------------------------
      IF p_max_item_count IS NULL
      THEN
           SELECT *
             BULK COLLECT INTO l_gate_changes
             FROM at_gate_change
            WHERE     project_location_code = l_proj_loc_code
                  AND gate_change_date BETWEEN l_start_time AND l_end_time
         ORDER BY gate_change_date;
      ELSE
         IF p_max_item_count < 0
         THEN
            l_sql := REPLACE (l_sql, '~direction~', 'desc');
         ELSE
            l_sql := REPLACE (l_sql, '~direction~', 'asc');
         END IF;

         EXECUTE IMMEDIATE l_sql
            BULK COLLECT INTO l_gate_changes
            USING l_proj_loc_code,
             l_start_time,
             l_end_time,
                  ABS (p_max_item_count);
      END IF;

   ----------------------------
   -- build the out variable --
   ----------------------------
      IF l_gate_changes IS NOT NULL AND l_gate_changes.COUNT > 0
      THEN
         cwms_display.retrieve_unit (l_elev_unit,
                                     'Elev',
                                     l_unit_system,
                                     p_project_location.get_office_id);
         cwms_display.retrieve_unit (l_flow_unit,
                                     'Flow',
                                     l_unit_system,
                                     p_project_location.get_office_id);
      p_gate_changes := gate_change_tab_t();
         p_gate_changes.EXTEND (l_gate_changes.COUNT);

         FOR i IN 1 .. l_gate_changes.COUNT
         LOOP
         ------------------------
         -- gate change object --
         ------------------------
            p_gate_changes (i) :=
               gate_change_obj_t (
            location_ref_t(l_gate_changes(i).project_location_code),
                  cwms_util.change_timezone (
                     l_gate_changes (i).gate_change_date,
                     'UTC',
                     l_time_zone),
                  cwms_util.convert_units (l_gate_changes (i).elev_pool,
                                           'm',
                                           l_elev_unit),
                  NULL,                    -- discharge_computation, set below
                  NULL,                           -- release_reason, set below
                  NULL,                                 -- settings, set below
                  cwms_util.convert_units (l_gate_changes (i).elev_tailwater,
                                           'm',
                                           l_elev_unit),
            l_elev_unit,
            cwms_util.convert_units(
               l_gate_changes(i).old_total_discharge_override,
               'cms',
               l_flow_unit),
            cwms_util.convert_units(
               l_gate_changes(i).new_total_discharge_override,
               'cms',
               l_flow_unit),
            l_flow_unit,
            l_gate_changes(i).gate_change_notes,
            l_gate_changes(i).protected,
            cwms_util.convert_units(
               l_gate_changes(i).reference_elev,
               'm',
               l_elev_unit));
         ---------------------------------
         -- discharge_computation field --
         ---------------------------------
            SELECT lookup_type_obj_t (p_project_location.get_office_id,
                   discharge_comp_display_value,
                   discharge_comp_tooltip,
                   discharge_comp_active)
              INTO p_gate_changes (i).discharge_computation
              FROM at_gate_ch_computation_code
             WHERE discharge_comp_code =
                      l_gate_changes (i).discharge_computation_code;

         --------------------------
         -- release_reason field --
         --------------------------
            SELECT lookup_type_obj_t (p_project_location.get_office_id,
                   release_reason_display_value,
                   release_reason_tooltip,
                   release_reason_active)
              INTO p_gate_changes (i).release_reason
              FROM at_gate_release_reason_code
             WHERE release_reason_code =
                      l_gate_changes (i).release_reason_code;

          --------------------
          -- settings field --
          --------------------
            SELECT *
              BULK COLLECT INTO l_gate_settings
              FROM at_gate_setting
             WHERE gate_change_code = l_gate_changes (i).gate_change_code;

            IF l_gate_settings IS NOT NULL AND l_gate_settings.COUNT > 0
            THEN
            p_gate_changes(i).settings := gate_setting_tab_t();
               p_gate_changes (i).settings.EXTEND (l_gate_settings.COUNT);

               FOR j IN 1 .. l_gate_settings.COUNT
               LOOP
                  l_opening_param :=
                     get_outlet_opening_param (
                        l_gate_settings (j).outlet_location_code);
               cwms_display.retrieve_unit(
                  l_opening_unit,
                  l_opening_param,
                  l_unit_system,
                  p_project_location.get_office_id);
                  p_gate_changes (i).settings (j) :=
                     gate_setting_obj_t (
                        location_ref_t (
                           l_gate_settings (j).outlet_location_code),
                  cwms_util.convert_units(
                     l_gate_settings(j).gate_opening,
                           cwms_util.get_default_units (l_opening_param,
                                                        'SI'),
                     l_opening_unit),
                  l_opening_param,
                  l_opening_unit,
                  cwms_util.convert_units(
                     l_gate_settings(j).invert_elev,
                     'm',
                     l_elev_unit));
               END LOOP;
            END IF;
         END LOOP;
      END IF;
   END retrieve_gate_changes;

--------------------------------------------------------------------------------
-- function retrieve_gate_changes_f
--------------------------------------------------------------------------------
   FUNCTION retrieve_gate_changes_f (
      p_project_location       IN location_ref_t,
      p_start_time             IN DATE,
      p_end_time               IN DATE,
      p_time_zone              IN VARCHAR2 DEFAULT NULL,
      p_unit_system            IN VARCHAR2 DEFAULT NULL,
      p_start_time_inclusive   IN VARCHAR2 DEFAULT 'T',
      p_end_time_inclusive     IN VARCHAR2 DEFAULT 'T',
      p_max_item_count         IN INTEGER DEFAULT NULL)
      RETURN gate_change_tab_t
   IS
   l_gate_changes gate_change_tab_t;
   BEGIN
      retrieve_gate_changes (l_gate_changes,
      p_project_location,
      p_start_time,
      p_end_time,
      p_time_zone,
      p_unit_system,
      p_start_time_inclusive,
      p_end_time_inclusive,
      p_max_item_count);
      RETURN l_gate_changes;
   END retrieve_gate_changes_f;

--------------------------------------------------------------------------------
-- procedure delete_gate_changes
--------------------------------------------------------------------------------
   PROCEDURE delete_gate_changes (
      p_project_location       IN location_ref_t,
      p_start_time             IN DATE,
      p_end_time               IN DATE,
      p_time_zone              IN VARCHAR2 DEFAULT NULL,
      p_start_time_inclusive   IN VARCHAR2 DEFAULT 'T',
      p_end_time_inclusive     IN VARCHAR2 DEFAULT 'T',
      p_override_protection    IN VARCHAR2 DEFAULT 'F')
   IS
      c_one_second   CONSTANT NUMBER := 1 / 86400;
      l_time_zone             VARCHAR2 (28);
      l_start_time            DATE;
      l_end_time              DATE;
      l_proj_loc_code         NUMBER (10);
   l_project           project_obj_t;
   l_gate_change_codes number_tab_t;
   l_protected_flags   str_tab_t;
      l_protected_count       PLS_INTEGER;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_project_location IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
      END IF;

      IF p_start_time IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
      END IF;

      IF p_end_time IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');
      END IF;

      IF p_start_time > p_end_time
      THEN
         cwms_err.raise ('ERROR',
                         'Start time must not be later than end time.');
      END IF;

      check_location_ref (p_project_location);

      IF p_override_protection NOT IN ('T', 'F')
      THEN
      cwms_err.raise(
         'ERROR',
      'Parameter p_override_protection must be either ''T'' or ''F''');
      END IF;

   -- will barf if not a valid project
      cwms_project.retrieve_project (l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;
      l_time_zone :=
         NVL (p_time_zone, cwms_loc.get_local_timezone (l_proj_loc_code));
      l_start_time :=
         cwms_util.change_timezone (p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');

      IF NOT cwms_util.is_true (p_start_time_inclusive)
      THEN
      l_start_time := l_start_time + c_one_second;
      END IF;

      IF NOT cwms_util.is_true (p_end_time_inclusive)
      THEN
      l_end_time := l_end_time - c_one_second;
      END IF;

   --------------------------------------------------------
   -- collect the gate change codes  and protected flags --
   --------------------------------------------------------
      SELECT gate_change_code, protected
        BULK COLLECT INTO l_gate_change_codes, l_protected_flags
        FROM at_gate_change
       WHERE     project_location_code = l_proj_loc_code
             AND gate_change_date BETWEEN l_start_time AND l_end_time;

   -------------------------------------
   -- check for protection violations --
   -------------------------------------
      IF NOT cwms_util.is_true (p_override_protection)
      THEN
         SELECT COUNT (*)
           INTO l_protected_count
           FROM TABLE (l_protected_flags)
          WHERE COLUMN_VALUE = 'T';

         IF l_protected_count > 0
         THEN
            cwms_err.raise ('ERROR',
            'Cannot delete protected gate change(s).');
         END IF;
      END IF;

   ------------------------
   -- delete the records --
   ------------------------
      DELETE FROM at_gate_setting
            WHERE gate_change_code IN
                     (SELECT * FROM TABLE (l_gate_change_codes));

      DELETE FROM at_gate_change
            WHERE gate_change_code IN
                     (SELECT * FROM TABLE (l_gate_change_codes));
   END delete_gate_changes;

--------------------------------------------------------------------------------
-- procedure set_gate_change_protection
--------------------------------------------------------------------------------
   PROCEDURE set_gate_change_protection (
      p_project_location       IN location_ref_t,
      p_start_time             IN DATE,
      p_end_time               IN DATE,
      p_protected              IN VARCHAR2,
      p_time_zone              IN VARCHAR2 DEFAULT NULL,
      p_start_time_inclusive   IN VARCHAR2 DEFAULT 'T',
      p_end_time_inclusive     IN VARCHAR2 DEFAULT 'T')
   IS
      c_one_second   CONSTANT NUMBER := 1 / 86400;
      l_time_zone             VARCHAR2 (28);
      l_start_time            DATE;
      l_end_time              DATE;
      l_proj_loc_code         NUMBER (10);
   l_project           project_obj_t;
   l_gate_change_codes number_tab_t;
   BEGIN
   -------------------
   -- sanity checks --
   -------------------
      IF p_project_location IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_project_location');
      END IF;

      IF p_start_time IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_start_time');
      END IF;

      IF p_end_time IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_end_time');
      END IF;

      IF p_protected IS NULL
      THEN
      cwms_err.raise('NULL_ARGUMENT', 'p_protected');
      END IF;

      IF p_start_time > p_end_time
      THEN
         cwms_err.raise ('ERROR',
                         'Start time must not be later than end time.');
      END IF;

      check_location_ref (p_project_location);

      IF p_protected NOT IN ('T', 'F')
      THEN
      cwms_err.raise(
         'ERROR',
      'Parameter p_protected must be either ''T'' or ''F''');
      END IF;

   -- will barf if not a valid project
      cwms_project.retrieve_project (l_project,
      p_project_location.get_location_id,
      p_project_location.get_office_id);
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   l_proj_loc_code := p_project_location.get_location_code;
      l_time_zone :=
         NVL (p_time_zone, cwms_loc.get_local_timezone (l_proj_loc_code));
      l_start_time :=
         cwms_util.change_timezone (p_start_time, l_time_zone, 'UTC');
   l_end_time   := cwms_util.change_timezone(p_end_time,   l_time_zone, 'UTC');

      IF NOT cwms_util.is_true (p_start_time_inclusive)
      THEN
      l_start_time := l_start_time + c_one_second;
      END IF;

      IF NOT cwms_util.is_true (p_end_time_inclusive)
      THEN
      l_end_time := l_end_time - c_one_second;
      END IF;

   ---------------------------
   -- update the protection --
   ---------------------------
      UPDATE at_gate_change
         SET protected = p_protected
       WHERE     project_location_code = l_proj_loc_code
             AND gate_change_date BETWEEN l_start_time AND l_end_time;
   END set_gate_change_protection;

function get_compound_outlet_code(
   p_compound_outlet_id in varchar2,
   p_project_id         in varchar2,
   p_office_id          in varchar2)
   return integer
is
   l_office_id            varchar2(16);
   l_compound_outlet_code integer;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   select compound_outlet_code
     into l_compound_outlet_code
     from at_comp_outlet
    where project_location_code = cwms_loc.get_location_code(l_office_id, p_project_id)
      and upper(compound_outlet_id) = upper(p_compound_outlet_id);

   return l_compound_outlet_code;
exception
   when no_data_found then
      cwms_err.raise(
         'ITEM_DOES_NOT_EXIST',
         'Compound outlet',
         l_office_id||'/'||p_project_id||'/'||p_compound_outlet_id);
end get_compound_outlet_code;

procedure store_compound_outlet(
   p_project_id         in varchar2,
   p_compound_outlet_id in varchar2,
   p_outlets            in str_tab_tab_t,
   p_fail_if_exists     in varchar2 default 'T',
   p_office_id          in varchar2 default null)
is
   item_does_not_exist    exception;
   pragma exception_init(item_does_not_exist, -20034);
   l_office_id            varchar2(16);
   l_compound_outlet_code integer;
   l_exists               boolean;
   l_fail_if_exists       boolean;
   l_code                 integer;
   l_count                integer;
begin
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_fail_if_exists := cwms_util.return_true_or_false(p_fail_if_exists);
   begin
      l_compound_outlet_code := get_compound_outlet_code(p_compound_outlet_id, p_project_id, l_office_id);
      l_exists := true;
   exception
      when item_does_not_exist then l_exists := false;
   end;

   if l_exists then
      if l_fail_if_exists then
         cwms_err.raise(
            'ITEM_ALREADY_EXISTS',
            'Compound outlet',
            l_office_id||'/'||p_project_id||'/'||p_compound_outlet_id);
      end if;
      delete_compound_outlet(p_project_id, p_compound_outlet_id, cwms_util.delete_data, l_office_id);
   else
      insert
        into at_comp_outlet
      values (cwms_seq.nextval,
              cwms_loc.get_location_code(l_office_id, p_project_id),
              p_compound_outlet_id
             )
      return compound_outlet_code
        into l_compound_outlet_code;
   end if;

   for i in 1..p_outlets.count loop
      l_code := cwms_loc.get_location_code(l_office_id, p_outlets(i)(1));
      select count(*)
        into l_count
        from at_comp_outlet_conn
       where outlet_location_code = l_code
         and compound_outlet_code != l_compound_outlet_code;

      if l_count > 0 then
         cwms_err.raise(
            'ERROR',
            'Oulet '
            ||l_office_id
            ||'/'
            ||p_outlets(i)(1)
            ||' is already used in another compound outlet.');
      end if;

      if p_outlets(i).count = 1 then
         insert
           into at_comp_outlet_conn
         values (cwms_seq.nextval, l_compound_outlet_code, l_code, null);
      else
         for j in 2..p_outlets(i).count loop
            if p_outlets(i)(j) is null then
               insert
                 into at_comp_outlet_conn
               values (cwms_seq.nextval, l_compound_outlet_code, l_code, null);
            else
               insert
                 into at_comp_outlet_conn
               values (cwms_seq.nextval, l_compound_outlet_code, l_code, cwms_loc.get_location_code(l_office_id, p_outlets(i)(j)));
            end if;
         end loop;
      end if;
   end loop;
end store_compound_outlet;


procedure store_compound_outlet(
   p_project_id         in varchar2,
   p_compound_outlet_id in varchar2,
   p_outlets            in varchar2,
   p_fail_if_exists     in varchar2 default 'T',
   p_office_id          in varchar2 default null)
is
begin
   store_compound_outlet(
      p_project_id,
      p_compound_outlet_id,
      cwms_util.parse_string_recordset(p_outlets),
      p_fail_if_exists,
      p_office_id);
end store_compound_outlet;

procedure rename_compound_outlet(
   p_project_id             in varchar2,
   p_old_compound_outlet_id in varchar2,
   p_new_compound_outlet_id in varchar2,
   p_office_id              in varchar2 default null)
is
   l_compound_outlet_code integer;
begin
   l_compound_outlet_code := get_compound_outlet_code(p_old_compound_outlet_id, p_project_id, p_office_id);
   update at_comp_outlet
      set compound_outlet_id = trim(p_new_compound_outlet_id)
    where compound_outlet_code = l_compound_outlet_code;
end rename_compound_outlet;

procedure delete_compound_outlet(
   p_project_id         in varchar2,
   p_compound_outlet_id in varchar2,
   p_delete_action      in varchar2 default cwms_util.delete_key,
   p_office_id          in varchar2 default null)
is
   l_delete_action        varchar2(32) := trim(upper(p_delete_action));
   l_compound_outlet_code integer;
begin
   if not l_delete_action in (cwms_util.delete_key, cwms_util.delete_data, cwms_util.delete_all) then
      cwms_err.raise(
         'ERROR',
         'Parameter P_Delete_Action must be one of '''
         ||cwms_util.delete_key||''', '
         ||cwms_util.delete_data||''', or'
         ||cwms_util.delete_key||'''');
   end if;
   l_compound_outlet_code := get_compound_outlet_code(p_compound_outlet_id, p_project_id, p_office_id);
   if l_delete_action in (cwms_util.delete_data, cwms_util.delete_all) then
      delete
        from at_comp_outlet_conn
       where compound_outlet_code = l_compound_outlet_code;
   end if;
   if l_delete_action in (cwms_util.delete_key, cwms_util.delete_all) then
      delete
        from at_comp_outlet
       where compound_outlet_code = l_compound_outlet_code;
   end if;
end delete_compound_outlet;

procedure retrieve_compound_outlets(
   p_compound_outlets out str_tab_tab_t,
   p_project_id_mask  in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
is
begin
   p_compound_outlets := retrieve_compound_outlets_f(p_project_id_mask, p_office_id_mask);
end retrieve_compound_outlets;

procedure retrieve_compound_outlets(
   p_compound_outlets out varchar2,
   p_project_id_mask  in varchar2 default '*',
   p_office_id_mask   in varchar2 default null)
is
   l_outlet_tab str_tab_tab_t;
   l_recordset  varchar2(32767);
begin
   l_outlet_tab := retrieve_compound_outlets_f(p_project_id_mask, p_office_id_mask);
   for rec in 1..l_outlet_tab.count loop
      if rec > 1 then
         l_recordset := l_recordset || cwms_util.record_separator;
      end if;
      for field in 1..l_outlet_tab(rec).count loop
         if field > 1 then
            l_recordset := l_recordset || cwms_util.field_separator;
         end if;
         l_recordset := l_recordset || l_outlet_tab(rec)(field);
      end loop;
   end loop;
   p_compound_outlets := substr(l_recordset, 1, length(l_recordset));
end retrieve_compound_outlets;

function retrieve_compound_outlets_f(
   p_project_id_mask in varchar2 default '*',
   p_office_id_mask  in varchar2 default null)
   return str_tab_tab_t
is
   l_project_id_mask  varchar2(256);
   l_office_id_mask   varchar2(16);
   l_compound_outlets str_tab_tab_t := str_tab_tab_t();
   l_tab              str_tab_t;
begin
   l_project_id_mask := cwms_util.normalize_wildcards(p_project_id_mask);
   l_office_id_mask  := cwms_util.normalize_wildcards(nvl(p_office_id_mask, cwms_util.user_office_id));
   for rec1 in (select office_id,
                       office_code
                  from cwms_office
                 where office_id like upper(l_office_id_mask) escape '\'
                 order by 1
               )
   loop
      for rec2 in (select bl.base_location_id
                          ||substr('-', length(pl.sub_location_id))
                          ||pl.sub_location_id as project_id,
                          p.project_location_code
                     from at_project p,
                          at_physical_location pl,
                          at_base_location bl
                    where pl.location_code = p.project_location_code
                      and bl.base_location_code = pl.base_location_code
                      and bl.db_office_code = rec1.office_code
                      and upper(bl.base_location_id
                          ||substr('-', length(pl.sub_location_id))
                          ||pl.sub_location_id) like upper(l_project_id_mask) escape '\'
                    order by 1
                  )
      loop
         select compound_outlet_id
           bulk collect
           into l_tab
           from at_comp_outlet
          where project_location_code = rec2.project_location_code
          order by 1;

         if l_tab.count > 0 then
            l_compound_outlets.extend;
            l_compound_outlets(l_compound_outlets.count) := str_tab_t();
            l_compound_outlets(l_compound_outlets.count).extend(l_tab.count + 2);
            l_compound_outlets(l_compound_outlets.count)(1) := rec1.office_id;
            l_compound_outlets(l_compound_outlets.count)(2) := rec2.project_id;
            for i in 1..l_tab.count loop
               l_compound_outlets(l_compound_outlets.count)(i+2) := l_tab(i);
            end loop;
         end if;
      end loop;
   end loop;
   return l_compound_outlets;
end retrieve_compound_outlets_f;

procedure retrieve_compound_outlet(
   p_outlets            out str_tab_tab_t,
   p_compound_outlet_id in  varchar2,
   p_project_id         in  varchar2,
   p_office_id          in  varchar2 default null)
is
begin
   p_outlets := retrieve_compound_outlet_f(p_compound_outlet_id, p_project_id, p_office_id);
end retrieve_compound_outlet;

procedure retrieve_compound_outlet(
   p_outlets            out varchar2,
   p_compound_outlet_id in  varchar2,
   p_project_id         in  varchar2,
   p_office_id          in  varchar2 default null)
is
   l_outlet_tab str_tab_tab_t;
   l_recordset  varchar2(32767);
begin
   l_outlet_tab := retrieve_compound_outlet_f(p_compound_outlet_id, p_project_id, p_office_id);
   for rec in 1..l_outlet_tab.count loop
      if rec > 1 then
         l_recordset := l_recordset || cwms_util.record_separator;
      end if;
      for field in 1..l_outlet_tab(rec).count loop
         if field > 1 then
            l_recordset := l_recordset || cwms_util.field_separator;
         end if;
         l_recordset := l_recordset || l_outlet_tab(rec)(field);
      end loop;
   end loop;
   p_outlets := substr(l_recordset, 1, length(l_recordset));
end retrieve_compound_outlet;

function retrieve_compound_outlet_f(
   p_compound_outlet_id in  varchar2,
   p_project_id         in  varchar2,
   p_office_id          in  varchar2 default null)
   return str_tab_tab_t
is
   l_compound_outlet_code integer;
   l_downstream           number_tab_t;
   l_outlet_tab           str_tab_tab_t := str_tab_tab_t();
begin
   l_compound_outlet_code := get_compound_outlet_code(p_compound_outlet_id, p_project_id, p_office_id);

   for rec in (select distinct
                      bl.base_location_id
                      ||substr('-', length(pl.sub_location_id))
                      ||pl.sub_location_id as outlet_id,
                      coc.outlet_location_code
                 from at_comp_outlet_conn coc,
                      at_physical_location pl,
                      at_base_location bl
                where coc.compound_outlet_code = l_compound_outlet_code
                  and pl.location_code = coc.outlet_location_code
                  and bl.base_location_code = pl.base_location_code
                order by 1
              )
   loop
      select next_outlet_code
        bulk collect
        into l_downstream
        from at_comp_outlet_conn
       where compound_outlet_code = l_compound_outlet_code
         and outlet_location_code = rec.outlet_location_code;

      if l_downstream.count = 0 then
         l_downstream := number_tab_t(null);
      end if;

      l_outlet_tab.extend;
      l_outlet_tab(l_outlet_tab.count) := str_tab_t();
      l_outlet_tab(l_outlet_tab.count).extend(l_downstream.count+1);
      l_outlet_tab(l_outlet_tab.count)(1) := rec.outlet_id;
      for i in 1..l_downstream.count loop
         if l_downstream(i) is null then
            l_outlet_tab(l_outlet_tab.count)(i+1) := null;
         else
            l_outlet_tab(l_outlet_tab.count)(i+1) := cwms_loc.get_location_id(l_downstream(i));
         end if;
      end loop;
   end loop;
   return l_outlet_tab;
end retrieve_compound_outlet_f;


end cwms_outlet;
/

--------------------
-- update version --
--------------------
insert 
  into cwms_db_change_log                                                     
       (application,
        ver_major,
        ver_minor,
        ver_build,
        ver_date,
        title,
        description
       )
values ('CWMS', 
         3,
         0,
         2,
         to_date ('21OCT2015', 'DDMONYYYY'),
        'CWMS Database 3.0.2',
        'Fixed bug where some routines consumed excessive amounts of sequence values.
Changed to allow multiple stream locations to share the same station on a stream
Various other fixes.'
       );
commit;
---------------------------------------
-- recompile schema and check erorrs --
---------------------------------------
exec sys.utl_recomp.recomp_serial('CWMS_20');
/

select substr(object_name, 1, 31) "INVALID OBJECT", object_type 
 from dba_objects 
where owner = 'CWMS_20' 
  and status = 'INVALID'
order by object_name, object_type asc;

select type,
       name, 
       line, 
       position, 
       text 
  from user_errors
 where attribute='ERROR' 
 order by 2,3,4; 

