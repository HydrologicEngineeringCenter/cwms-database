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
   /**
    * Number of minutes in an interval.
    */
   min_in_hr   CONSTANT NUMBER := 60;
   min_in_dy   CONSTANT NUMBER := 1440;
   min_in_wk   CONSTANT NUMBER := 10080;
   min_in_mo   CONSTANT NUMBER := 43200;
   min_in_yr   CONSTANT NUMBER := 525600;
   min_in_dc   CONSTANT NUMBER := 5256000;


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
    * Deletes time series values for a specified time series, version date, and time window
    *
    * @see constant cwms_util.non_versioned
    *
    * @param p_ts_code          The unique numeric code identifying the time series
    * @param p_version_date_utc The UTC version date/time of the time series
    * @param p_start_time_utc   The UTC start of the time window
    * @param p_end_time_utc     The UTC end of the time window
    */
   PROCEDURE purge_ts_data (p_ts_code            IN NUMBER,
                            p_version_date_utc   IN DATE,
                            p_start_time_utc     IN DATE,
                            p_end_time_utc       IN DATE);

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
    */
   PROCEDURE change_version_date (p_ts_code                IN NUMBER,
                                  p_old_version_date_utc   IN DATE,
                                  p_new_version_date_utc   IN DATE,
                                  p_start_time_utc         IN DATE,
                                  p_end_time_utc           IN DATE);

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
    * @param p_date_cat     A cursor containing the version dates. The cursor contains a single unnamed column of type DATE, sorted in ascending order
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
    * @param p_date_cat     A cursor containing the version dates. The cursor contains a single unnamed column of type DATE, sorted in ascending order
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
    *     <td class="descr-center">3</td>
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
      p_store_rule        IN VARCHAR2 DEFAULT NULL,
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
      p_store_rule        IN VARCHAR2 DEFAULT NULL,
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
      p_store_rule      IN VARCHAR2 DEFAULT NULL,
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
      p_times           IN number_tab_t,
      p_values          IN number_tab_t,
      p_qualities       IN number_tab_t,
      p_store_rule      IN VARCHAR2 DEFAULT NULL,
      p_override_prot   IN VARCHAR2 DEFAULT 'F',
      p_version_date    IN DATE DEFAULT cwms_util.non_versioned,
      p_office_id       IN VARCHAR2 DEFAULT NULL);

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
   PROCEDURE store_ts_multi (
      p_timeseries_array   IN timeseries_array,
      p_store_rule         IN VARCHAR2 DEFAULT NULL,
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
      p_store_rule        IN VARCHAR2 DEFAULT NULL,
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
      p_store_rule         IN VARCHAR2 DEFAULT NULL,
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

END;
/

SHOW ERRORS;
COMMIT;