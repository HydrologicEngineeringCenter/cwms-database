CREATE OR REPLACE PACKAGE cwms_data_dissem
AS
   /**
    * Routines used to manage the flow of data from Operational CWMS databases
    * to the National CWMS databases. Operational CWMS databases are used by
    * district and division offices to perform their real time reservoir operations.
    * The National CWMS databases are used primarily for data dissemination purposes.
    * There are currently two National CWMS databases, namely a CorpsNet DB and a
    * DMZ DB. The CorpsNet DB is used by internal Corps only accessible services
    * and the DMZ DB is used by public facing services.
    *
    * @author Various
    *
    * @since CWMS 2.1
    */
   do_not_stream              CONSTANT INT := 0;
   stream_to_CorpsNet         CONSTANT INT := 1;
   stream_to_dmz              CONSTANT INT := 2;

   DMZ_DB                     CONSTANT VARCHAR2 (16) := 'DMZ';
   CorpsNet_DB                CONSTANT VARCHAR2 (16) := 'CORPSNET';

   CorpsNet_include_gp_code   CONSTANT NUMBER := 100;
   CorpsNet_exclude_gp_code   CONSTANT NUMBER := 101;
   DMZ_include_gp_code        CONSTANT NUMBER := 102;
   DMZ_exclude_gp_code        CONSTANT NUMBER := 103;

   -- not documented
   TYPE cat_ts_transfer_rec_t IS RECORD
   (
      cwms_ts_id    VARCHAR2 (183),
      public_name   VARCHAR2 (57),
      office_id     VARCHAR2 (16),
      ts_code       NUMBER,
      office_code   NUMBER,
      dest_db       VARCHAR2 (16)
   );

   -- not documented
   TYPE cat_ts_transfer_tab_t IS TABLE OF cat_ts_transfer_rec_t;
   FUNCTION get_dest (p_ts_code IN NUMBER)
      RETURN INT;

   /**
  * This function is used to determine if the data for the specified time series
  * should be transferred to the CorpsNet (internal) CWMS National Database, to
  * both the CorpsNet and DMZ CWMS National Databases, not transferred at all.
  *
  * @param p_ts_code The ts_code of the time series of interest.
  *
  * @return The function returns an INT that indicates to which CWMS Databases the p_ts_code should be streamed:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Returned INT</th>
    *     <th class="descr">Indicates</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">0</td>
    *     <td class="descr">Data for this ts_code should not be streamed.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">1</td>
    *     <td class="descr">Data for this ts_code should be streamed to the CorpsNet CWMS National Database.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">2</td>
    *     <td class="descr">Data for this ts_code should be streamed to both the CorpsNet and the DMZ CWMS National Databases.</td>
    *   </tr>
    * </table>
  *
  */
   FUNCTION allowed_dest (p_ts_code IN NUMBER)
      RETURN INT;

   /**
  * Returns a Boolean indicating if data for the specified ts_code is to be streamed to the DMZ CWMS National Database.
  *
  * @param p_ts_code The ts_code of the time series of interest.
  *
  *
  * @return TRUE if data should be streamed to the DMZ CWMS National DB. FALSE if data should not be streamed to the DMZ CWMS National DB.
  *
  */
   FUNCTION allowed_to_dmz (p_ts_code IN NUMBER)
      RETURN BOOLEAN;

   /**
  * Returns a Boolean indicating if data for the specified ts_code is to be streamed to the CorpsNet CWMS National Database.
  *
  * @param p_ts_code The ts_code of the time series of interest.
  *
  *
  * @return TRUE if data should be streamed to the CorpsNet CWMS National DB. FALSE if data should not be streamed to the CorpsNet CWMS National DB.
  *
  */
   FUNCTION allowed_to_corpsnet (p_ts_code IN NUMBER)
      RETURN BOOLEAN;

   /**
  * Returns a Boolean indicating if filtering to the specified destination
  * database is enabled (i.e., TRUE) or disabled (i.e., FALSE).
  *
  * @param p_dest_db is the destination database. Valid values include
  *        <code><big>DMZ</big></code> or <code><big>CorpsNet</big></code>
  *
  * @param p_office_id the office identifier for which to find the code. If
  *        <code><big>NULL</big></code> the calling user's office is used
  *
  * @return TRUE if filtering is enabled for the specified destination
  *        database. Returns FALSE if filtering is disabled for the specified
  *        destination database.
  *
  * @throws ERROR if the specified destination database is invalid
  */
   FUNCTION is_filtering_to (p_dest_db IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN BOOLEAN;



   /**
  * Used to set (i.e., enable or disable) time series filtering to the CorpsNet
  * and/or DMZ Databases. If time series Filtering is enabled (i.e., TRUE) then
  * only data defined in the offices time series filters for the CorpsNet and
  * DMZ databases will be streamed. If time series filtering is disabled,
  * then all data is streamed to the respective databases. The default setting is:
  * <br>
  * CorpsNet DB: Filtering is disabled (FALSE) resulting in all time series data
  * being streamed to the CorpsNet DB
  * <br>
  * DMZ DB: Filtering is enabled (TRUE) resulting in only data from listed time
  * series ids getting streamed to the DMZ DB. Initially, the DMZ time series
  * include list will be empty, meaning nothing will be streamed to the DMZ DB
  * until an office populates its DMZ include/exclude lists.
  *
  * @param p_filter_to_corpsnet TRUE enables Filtering to the CorpsNet DB, FALSE disables Filtering.
  * @param p_filter_to_dmz TRUE enables Filtering to the DMZ DB, FALSE disables Filtering.
  * @param p_office_id the office identifier for which the filterig is being configured.
  *
  */
   PROCEDURE set_ts_filtering (p_filter_to_corpsnet   IN VARCHAR2,
                               p_filter_to_dmz        IN VARCHAR2,
                               p_office_id            IN VARCHAR2);

   /**
     * Retrieves a cursor of time series ids that will be streamed from the an
     * offices Operational CWMS database to the CorpsNet and possible on to the
     * DMZ CWMS databases.
     *
     * @param p_ts_transfer_cat       A cursor containing the list of time series
     * that will be streamed on to the CorpsNet and/or DMZ CWMS databases. The cursor
     * contains the following columns:
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
     *     <td class="descr">cwms_ts_id</td>
     *     <td class="descr"varchar2(183)</td>
     *     <td class="descr">The time series identifier</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">2</td>
     *     <td class="descr">public_name</td>
     *     <td class="descr">varchar2(57)</td>
     *     <td class="descr">The Public Name of the time series ids Location.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">3</td>
     *     <td class="descr">office_id</td>
     *     <td class="descr">varchar2(16)</td>
     *     <td class="descr">The office id associated with this time series id.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">4</td>
     *     <td class="descr">ts_code</td>
     *     <td class="descr">number</td>
     *     <td class="descr">The corresponding ts_code of the time series id.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">5</td>
     *     <td class="descr">office_code</td>
     *     <td class="descr">number</td>
     *     <td class="descr">The corresponding office_code of the office_id.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">6</td>
     *     <td class="descr">dest_db</td>
     *     <td class="descr">varchar2(16)</td>
     *     <td class="descr">The Destination DB for this time series. The current values are either CorpsNet which means data for this time series is only streamed to the CorpsNet DB or DMZ, which means data for this time series is streamed to both the CorpsNet and the DMZ DBs.</td>
     *   </tr>
     * </table>
     * @param p_officeid        The office that owns the time series
     */
   PROCEDURE cat_ts_transfer (
      p_ts_transfer_cat   IN OUT SYS_REFCURSOR,
      p_office_id         IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves a table of time series data for a specified time series and time window
    *
    * @param p_office_id       The office that owns the time series
    *
    * @return  A collection containing the list of time series
     * that will be streamed on to the CorpsNet and/or DMZ CWMS databases. The collection
     * contains the following columns:
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
     *     <td class="descr">cwms_ts_id</td>
     *     <td class="descr"varchar2(183)</td>
     *     <td class="descr">The time series identifier</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">2</td>
     *     <td class="descr">public_name</td>
     *     <td class="descr">varchar2(57)</td>
     *     <td class="descr">The Public Name of the time series ids Location.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">3</td>
     *     <td class="descr">office_id</td>
     *     <td class="descr">varchar2(16)</td>
     *     <td class="descr">The office id associated with this time series id.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">4</td>
     *     <td class="descr">ts_code</td>
     *     <td class="descr">number</td>
     *     <td class="descr">The corresponding ts_code of the time series id.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">5</td>
     *     <td class="descr">office_code</td>
     *     <td class="descr">number</td>
     *     <td class="descr">The corresponding office_code of the office_id.</td>
     *   </tr>
     *   <tr>
     *     <td class="descr-center">6</td>
     *     <td class="descr">dest_db</td>
     *     <td class="descr">varchar2(16)</td>
     *     <td class="descr">The Destination DB for this time series. The current values are either CorpsNet which means data for this time series is only streamed to the CorpsNet DB or DMZ, which means data for this time series is streamed to both the CorpsNet and the DMZ DBs.</td>
     *   </tr>
     * </table><p>
    * The record collection is suitable for casting to a table with the table() function.
    */
   FUNCTION cat_ts_transfer_tab (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_ts_transfer_tab_t
      PIPELINED;
END cwms_data_dissem;

/
show errors;
GRANT EXECUTE ON CWMS_DATA_DISSEM TO CWMS_USER
/

