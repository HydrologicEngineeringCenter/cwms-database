set define off;
create or replace package cwms_msg
/**
 * Facilities for logging messages and publishing messages to queues.
 * The publish_message and publish_status_message functions that take a VARCHAR2
 * or CLOB parameter named p_properties expect an XML instance of the following
 * form:
 * <p>
 * <big><pre>
 * &lt;cwms_message type="message type"&gt;
 *   &lt;property name="propery name" type="property type"&gt;property value&lt;/property&gt;
 *   &lt;property name="propery name" type="property type"&gt;property value&lt;/property&gt;
 *   ...
 *   &lt;text&gt;
 *     Message Text
 *   &lt;/text&gt;
 * &lt;/cwms_message&gt;
 * </pre></big>
 * <p>
 * If a String property named "key" is specified, the message can be retrieved by retrieving its
 * ID via the get_msgids_for_key() function.
 * <p>
 * For messages to be logged, the message type property must be set to one of the following:
 * <ul>
 *   <li>AcknowledgeAlarm</li>
 *   <li>AcknowledgeRequest</li>
 *   <li>Alarm</li>
 *   <li>ControlMessage</li>
 *   <li>DeactivateAlarm</li>
 *   <li>Exception Thrown</li>
 *   <li>Fatal Error</li>
 *   <li>Initialization Error</li>
 *   <li>Initiated</li>
 *   <li>Load Library Error</li>
 *   <li>MissedHeartBeat</li>
 *   <li>PreventAlarm</li>
 *   <li>RequestAction</li>
 *   <li>ResetAlarm</li>
 *   <li>Runtime Exec Error</li>
 *   <li>Shutting Down</li>
 *   <li>State</li>
 *   <li>Status</li>
 *   <li>StatusIntervalMinutes</li>
 *   <li>Terminated</li>
 * </ul>
 * <p>
 * The <code><big>&lt;text&gt;</big></code> element is optional, and zero or more <code><big>&lt;property&gt;</big></code> elements may
 * be specified.
 * <p>
 * Valid property type attributes are the JMS valid property types, namely:
 * <ul>
 *    <li>boolean</li>
 *    <li>byte</li>
 *    <li>short</li>
 *    <li>int</li>
 *    <li>long</li>
 *    <li>float</li>
 *    <li>double</li>
 *    <li>String</li>
 * </ul>
 * Property values must be valid for the specified property type.
 * <p>
 * Do not specify a property name "type", as this property is set to the type
 * attibute of the root (&lt;cwms_message&gt;) element.
 * <p>
 * Do not specify a property name "millis", as this property is set to the
 * creation time of the message.
 * <p>
 * Message queues can be named in either of the following forms:
 * <ul>
 * <li><dl>
 *   <dt><b><em>username</em>_<em>queuename</em></b></dt><dd>specifies the <em>queuename</em> queue for the <em>username</em> user</dd>
 * <dl>
 * </dl></li>
 * <li><dl>
 *   <dt><b><em>queuename</em></b></dt><dd>specifies the <em>queuename</em> queue for the session user</td></dd>
 * </dl></li>
 * </ul>
 * <p>
 * Valid values for <em>queuename</em> are:
 * <ul>
 * <li><dl>
 *   <dt><b>STATUS</b></dt><dd>Queue for general system and application status messages</dd>
 * <dl>
 * </dl></li>
 * <li><dl>
 *   <dt><b>TS_STORED</b></dt><dd>Queue for messages about time series operations, such as data stored and deleted</dd>
 * <dl>
 * </dl></li>
 * <li><dl>
 *   <dt><b>REALTIME_OPS</b></dt><dd>Queue for application operational messages</dd>
 * <dl>
 * </dl></li>
 * </ul>
 *
 * @author Mike Perryman
 *
 * @since CWMS 2.1
 */
as

exc_no_subscribers exception; pragma exception_init(exc_no_subscribers, -24033);

/**
 * Message level specifying to NOT log a message, although it may still be published
 */
msg_level_none     constant integer :=  0;
/**
 * Message level indicating the message should be visible at all filtering levels
 */
msg_level_basic    constant integer :=  1;
/**
 * Message level indicating the message should be visible at the normal filtering level
 */
msg_level_normal   constant integer :=  3;
/**
 * Message level indicating the message should be visible only when the filtering level
 * is set to include detailed messages
 */
msg_level_detailed constant integer :=  5;
/**
 * Message level indicating the message should be visible only when the filtering
 * level is set to include all messages
 */
msg_level_verbose  constant integer :=  7;
-- not documented
function get_msg_id 
   return varchar2;
-- not documented
function get_queue_name(
   p_queuename in varchar2) 
   return varchar2;
-- not documented
procedure new_message(
   p_msg   out sys.aq$_jms_map_message,
   p_msgid out pls_integer,
   p_type  in  varchar2);
-- not documented
function publish_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in pls_integer,
   p_msg_queue in varchar2,
	p_immediate in boolean default false)
   return integer;
/**
 * Publish a message to a queue
 *
 * @param p_properties The message to publish, in the XML format shown above
 * @param p_msg_queue  The message queue name, in one of the forms shown above
 * @param p_immediate  Specifies whether to execute a database commit.  If TRUE,
 * a database commit is performed and the message is enqueued immediately. If FALSE,
 * no commit is performed and the message is not enqueued until the current transaction
 * is commited. If the current transaction is rolled back, either explicitly or due
 * to an error condition, the message is not enqueued.
 *
 * @return the message identifier of the enqueued message
 */
function publish_message(
   p_properties in varchar2,
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
   return integer;
/**
 * Publish a message to a queue
 *
 * @param p_properties The message to publish, in the XML format shown above
 * @param p_msg_queue  The message queue name, in one of the forms shown above
 * @param p_immediate  Specifies whether to execute a database commit.  If TRUE,
 * a database commit is performed and the message is enqueued immediately. If FALSE,
 * no commit is performed and the message is not enqueued until the current transaction
 * is commited. If the current transaction is rolled back, either explicitly or due
 * to an error condition, the message is not enqueued.
 *
 * @return the message identifier of the enqueued message
 */
function publish_message(
   p_properties in out nocopy clob,
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
   return integer;
-- not documented
function publish_status_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in pls_integer,
	p_immediate in boolean default false)
   return integer;
/**
 * Publish a message to the STATUS queue for the session user
 *
 * @param p_properties The message to publish, in the XML format shown above
 * @param p_immediate  Specifies whether to execute a database commit.  If TRUE,
 * a database commit is performed and the message is enqueued immediately. If FALSE,
 * no commit is performed and the message is not enqueued until the current transaction
 * is commited. If the current transaction is rolled back, either explicitly or due
 * to an error condition, the message is not enqueued.
 *
 * @return the message identifier of the enqueued message
 */
function publish_status_message(
   p_properties in varchar2,
	p_immediate  in boolean default false)
   return integer;
/**
 * Publish a message to the STATUS queue for the session user
 *
 * @param p_properties The message to publish, in the XML format shown above
 * @param p_immediate  Specifies whether to execute a database commit.  If TRUE,
 * a database commit is performed and the message is enqueued immediately. If FALSE,
 * no commit is performed and the message is not enqueued until the current transaction
 * is commited. If the current transaction is rolled back, either explicitly or due
 * to an error condition, the message is not enqueued.
 *
 * @return the message identifier of the enqueued message
 */
function publish_status_message(
   p_properties in out nocopy clob,
	p_immediate  in boolean default false)
   return integer;
/**
 * Logs a message to the datbase log table, optionally publishing the message to the
 * STATUS queue for the session user
 *
 * @see constant msg_level_basic
 * @see constant msg_level_normal
 * @see constant msg_level_detailed
 * @see constant msg_level_verbose
 *
 * @param p_component The CWMS component that is logging the messsage
 *
 * @param p_instance  The instance of the CWMS component that is logging the message
 *
 * @param p_host      The host on which the reporting component is executing
 *
 * @param p_port      The port at which the reporting component is listening, if applicable
 *
 * @param p_reported  The UTC time of the report as determined by the reporting component
 *
 * @param p_message The message to publish, in the XML format shown above
 *
 * @param p_msg_lvel The visibility level of the message
 *
 * @param p_publish specifies whether to publish the message to the STATUS queue
 *
 * @param p_immediate  Specifies whether to execute a database commit.  If TRUE,
 * a database commit is performed and the message is enqueued immediately. If FALSE,
 * no commit is performed and the message is not enqueued until the current transaction
 * is commited. If the current transaction is rolled back, either explicitly or due
 * to an error condition, the message is not enqueued.
 *
 * @return the message identifier of the enqueued message
 */
function log_message(
   p_component in varchar2,
   p_instance  in varchar2,
   p_host      in varchar2,
   p_port      in integer,
   p_reported  in timestamp,
   p_message   in varchar2,
   p_msg_level in integer default msg_level_normal,
   p_publish   in boolean default true,
	p_immediate in boolean default false)
   return integer;
/**
 * Logs a message to the datbase log table, optionally publishing the message to the
 * STATUS queue for the session user, and storing a related long message to the
 * AT_CLOB table
 *
 * @see constant msg_level_basic
 * @see constant msg_level_normal
 * @see constant msg_level_detailed
 * @see constant msg_level_verbose
 *
 * @param p_message_id the logged message identifier
 *
 * @param p_component The CWMS component that is logging the messsage
 *
 * @param p_instance  The instance of the CWMS component that is logging the message
 *
 * @param p_host      The host on which the reporting component is executing
 *
 * @param p_port      The port at which the reporting component is listening, if applicable
 *
 * @param p_reported  The UTC time of the report as determined by the reporting component
 *
 * @param p_short_msg The message to publish, in the XML format shown above
 *
 * @param p_long_msg The long message to store in the AT_CLOB table
 *
 * @param p_msg_lvel The visibility level of the message
 *
 * @param p_publish specifies whether to publish the message to the STATUS queue
 *
 * @param p_immediate  Specifies whether to execute a database commit.  If TRUE,
 * a database commit is performed and the message is enqueued immediately. If FALSE,
 * no commit is performed and the message is not enqueued until the current transaction
 * is commited. If the current transaction is rolled back, either explicitly or due
 * to an error condition, the message is not enqueued.
 *
 * @return the message identifier of the enqueued message
 */
function log_long_message(
   p_message_id out varchar2,
   p_component  in  varchar2,
   p_instance   in  varchar2,
   p_host       in  varchar2,
   p_port       in  integer,
   p_reported   in  timestamp,
   p_short_msg  in  varchar2,
   p_long_msg   in  clob,
   p_msg_level  in  integer default msg_level_normal,
   p_publish    in  boolean default true,
   p_immediate  in boolean default false)
   return integer;
/**
 * Retrieves the long message from the AT_CLOB table for a logged message
 *
 * @param p_message_id The logged message identifier
 *
 * @return the associtated long message
 */
function get_message_clob(
   p_message_id in varchar2)
   return clob;
-- not documented
function create_message_key
   return varchar2;
-- deprecated
procedure log_db_message(
   p_procedure in varchar2,
   p_msg_level in integer,
   p_message   in varchar2);
-- not documented
procedure log_db_message(
   p_msg_level in integer,
   p_message   in varchar2);
-- not documented
procedure log_db_message(
   p_key       in varchar2,
   p_message   in varchar2,
   p_msg_level in integer);
/**
 * Retrieves message IDs whose properties include the specified key, optionally within a time window.
 *
 * @param p_key        The key to retieve the message IDs for 
 * @param p_start_time The start of the time window in the specified or default time zone. If unspecified or NULL, no beginning time limit is used.
 * @param p_end_time   The end of the time window in the specified or default time zone. If unspecified or NULL, no ending time limit is used.
 * @param p_time_zone  The time zone if the time window. If unspecified or NULL, 'UTC' is used.
 *
 * @return The associated message IDs, which can be used to retrieve the messages.
 */
function get_msg_ids_for_key(
   p_key        in varchar2,
   p_start_time in date     default null,
   p_end_time   in date     default null,
   p_time_zone  in varchar2 default null)
   return str_tab_t;
/**
 * Logs a message of the CWMS Message Server message format and publishes it
 * to the STATUS queue
 *
 * @param p_message The CWMS Message Server message
 *
 * @return the message identifier of the enqueued message
 */
function log_message_server_message(
   p_message in varchar2)
   return integer;
/**
 * Logs a message of the CWMS Message Server message format and publishes it
 * to the STATUS queue
 *
 * @param p_message The CWMS Message Server message
 *
 * @return the message identifier of the enqueued message
 */
function log_message_server_message(
   p_message in out nocopy clob)
   return integer;
/**
 * Retrieves a cursor of database log messages that match the specified criteria
 *
 * @param p_log_crsr The cursor that contains the matched log messages. 
 *        <p>The following columns are returned if p_abbreviated = 'T'
 *        <p>
 *        <table class="descr">
 *          <tr>
 *            <th class="descr">Column No.</th>
 *            <th class="descr">Column Name</th>
 *            <th class="descr">Data Type</th>
 *            <th class="descr">Contents</th>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">1</td>
 *            <td class="descr">msg_id</td>
 *            <td class="descr">varchar2(32)</td>
 *            <td class="descr">The log message identifier</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">2</td>
 *            <td class="descr">log_timestamp_utc</td>
 *            <td class="descr">timestamp(6)</td>
 *            <td class="descr">Timestamp of when the message was logged</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">3</td>
 *            <td class="descr">msg_text</td>
 *            <td class="descr">varchar2(4000)</td>
 *            <td class="descr">The text of the log message</td>
 *          </tr>
 *        </table>
 *        <p>The following columns are returned if p_abbreviated = 'F'
 *        <p>
 *        <table class="descr">
 *          <tr>
 *            <th class="descr">Column No.</th>
 *            <th class="descr">Column Name</th>
 *            <th class="descr">Data Type</th>
 *            <th class="descr">Contents</th>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">1</td>
 *            <td class="descr">msg_id</td>
 *            <td class="descr">varchar2(32)</td>
 *            <td class="descr">The log message identifier</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">2</td>
 *            <td class="descr">office_code</td>
 *            <td class="descr">number(10,0)</td>
 *            <td class="descr">Office code of the logging office</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">3</td>
 *            <td class="descr">log_timestamp_utc</td>
 *            <td class="descr">timestamp(6)</td>
 *            <td class="descr">Timestamp of when the message was logged (set by database)</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">4</td>
 *            <td class="descr">msg_level</td>
 *            <td class="descr">number(2,0)</td>
 *            <td class="descr">The detail level of the service</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">5</td>
 *            <td class="descr">component</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">The reporting CWMS component</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">6</td>
 *            <td class="descr">instance</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">Instance of the reporting CWMS component, if applicable</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">7</td>
 *            <td class="descr">host</td>
 *            <td class="descr">varchar2(256)</td>
 *            <td class="descr">Host on which the reporting component is executing</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">8</td>
 *            <td class="descr">port</td>
 *            <td class="descr">number(5,0)</td>
 *            <td class="descr">Port at which the reporting component is contacted, if applicable</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">9</td>
 *            <td class="descr">report_timestamp_utc</td>
 *            <td class="descr">timestamp(6)</td>
 *            <td class="descr">Timestamp of when the message was reported (set by client)</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">10</td>
 *            <td class="descr">session_username</td>
 *            <td class="descr">varchar2(30)</td>
 *            <td class="descr">The database session usernmae</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">11</td>
 *            <td class="descr">session_osuser</td>
 *            <td class="descr">varchar2(30)</td>
 *            <td class="descr">The OS username on the client</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">12</td>
 *            <td class="descr">session_process</td>
 *            <td class="descr">varchar2(24)</td>
 *            <td class="descr">The name of the client process</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">13</td>
 *            <td class="descr">session_program</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">The name of the client program</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">14</td>
 *            <td class="descr">session_machine</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">The machine name of the connect client</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">15</td>
 *            <td class="descr">msg_type</td>
 *            <td class="descr">number(2,0)</td>
 *            <td class="descr">The message type</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">16</td>
 *            <td class="descr">mst_text</td>
 *            <td class="descr">varchar2(4000)</td>
 *            <td class="descr">The text of the log message</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">17</td>
 *            <td class="descr">properties</td>
 *            <td class="descr">cursor</td>
 *            <td class="descr">A cursor of properties for the message
 *              <table class="descr">
 *                <tr>
 *                  <th class="descr">Column No.</th>
 *                  <th class="descr">Column Name</th>
 *                  <th class="descr">Data Type</th>
 *                  <th class="descr">Contents</th>
 *                </tr>
 *                <tr>
 *                  <td class="descr-center">1</td>
 *                  <td class="descr">name</td>
 *                  <td class="descr">varchar2(64)</td>
 *                  <td class="descr">The log message identifier</td>
 *                </tr>
 *                <tr>
 *                  <td class="descr-center">2</td>
 *                  <td class="descr">type</td>
 *                  <td class="descr">number(1,0)</td>                                    
 *                  <td class="descr">The property type</td>
 *                </tr>
 *                <tr>
 *                  <td class="descr-center">3</td>
 *                  <td class="descr">value</td>
 *                  <td class="descr">varchar2(4000)</td>
 *                  <td class="descr">The value of the property</td>
 *                </tr>
 *              </table>
 *            </td>
 *          </tr>
 *        </table>
 * @param p_min_msg_id         The lowest message id to match. If unspecified or null, no lower limit will be applied. 
 * @param p_max_msg_id         The highest message id to match. If unspecified or null, no upper limit will be applied.
 * @param p_min_log_time       The lowest log timestamp to match. If unspecified or null, no lower limit will be applied. 
 * @param p_max_log_time       The highest log timestamp to match. If unspecified or null, no upper limit will be applied.
 * @param p_time_zone          The time zone of p_min/max_log_time and of the returned log times. If unspecified or null, 'UTC' will be used.
 * @param p_min_msg_level      The lowest message level to match. If unspecified or null, no lower limit will be applied.
 *                             <p>Defined levels are as follows. Levels between defined levels can be used. 
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Level</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">Basic</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">Normal</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">Detailed</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">Verbose</td>
 *                               </tr>
 *                             </table>
 * @param p_max_msg_level      The highest message level to match. If unspecified or null, no upper limit will be applied.
 *                             <p>Defined levels are as follows. Levels between defined levels can be used. 
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Level</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">Basic</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">Normal</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">Detailed</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">Verbose</td>
 *                               </tr>
 *                             </table>
 * @param p_min_inclusive      A flag (T/F) specifying whether p_min_xxx is inclusive (can be in the matched messages). If unspecified, 'T' is used.
 * @param p_max_inclusive      A flag (T/F) specifying whether p_max_xxx is inclusive (can be in the matched messages). If unspecified, 'T' is used.
 * @param p_message_types      The numeric message types to match, as a comma-separated text of integers or integer ranges (a..b).
 *                             For example, to match all alarm and error/exception message types: '1,3,5-8,10,12,14-15'.
 *                             If unspecified or null, all message types are matched.
 *                             <p>Defined types are as follows. 
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Type</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">AcknowledgeAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">2</td>
 *                                 <td class="descr">AcknowledgeRequest</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">Alarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">4</td>
 *                                 <td class="descr">ControlMessage</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">DeactivateAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">6</td>
 *                                 <td class="descr">Exception Thrown</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">Fatal Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">8</td>
 *                                 <td class="descr">Initialization Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">9</td>
 *                                 <td class="descr">Initiated</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">10</td>
 *                                 <td class="descr">Load Library Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">11</td>
 *                                 <td class="descr">MissedHeartBeat</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">12</td>
 *                                 <td class="descr">PreventAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">13</td>
 *                                 <td class="descr">RequestAction</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">14</td>
 *                                 <td class="descr">ResetAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">15</td>
 *                                 <td class="descr">Runtime Exec Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">16</td>
 *                                 <td class="descr">Shutting Down</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">17</td>
 *                                 <td class="descr">State</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">18</td>
 *                                 <td class="descr">Status</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">19</td>
 *                                 <td class="descr">StatusIntervalMinutes</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">20</td>
 *                                 <td class="descr">Terminated</td>
 *                               </tr>
 *                             </table>
 * @param p_abbreviated        A flag (T/F) specifying whether the cursror will contain abbreviated informtion. If unspecified, 'T' is used.
 * @param p_message_mask       A value to match log message text against. If unspecified or null, no message text matching is performed.
 * @param p_message_match_type Specifies the type of message text matching.
 *                             <p>Match types are as follows. For literal (non-pattern) matching, the Glob and Sql matching types are equivalent.
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Matching Type</th>
 *                                 <th class="descr">Normal Variant</th>
 *                                 <th class="descr">Negated Variant</th>
 *                                 <th class="descr">Case Insensitive Variant</th>
 *                                 <th class="descr">Negated Case Insensitive Variant</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr">Glob-style wildcards: '*' and '?'</th>
 *                                 <td class="descr">GLOB</th>
 *                                 <td class="descr">NGLOB</th>
 *                                 <td class="descr">GLOBI</th>
 *                                 <td class="descr">NGLOBI</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr">Sql-style wildcards: '%' and '_'</th>
 *                                 <td class="descr">SQL</th>
 *                                 <td class="descr">NSQL</th>
 *                                 <td class="descr">SQLI</th>
 *                                 <td class="descr">NSQLI</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr">Regular Expressions</th>
 *                                 <td class="descr">REGEX</th>
 *                                 <td class="descr">NREGEX</th>
 *                                 <td class="descr">REGEXI</th>
 *                                 <td class="descr">NREGEXI</th>
 *                               </tr>
 *                             </table>
 * @param p_ascending          A flag (T/F) specifying whether the results should be sorted ascending (T) or descending (F). If unspecified, 'T' is used.
 * @param p_session_id         Specifies the database sessions to match messages from. Must be null (current session), 'ALL' (all sessions) or a valid session id.
 * @param p_properties         The log message properties to match. If unspecified or null, no message property matching will be performed.
 * @param p_props_combination  Specifies whether to match any specified property ('ANY') or all specified properties ('ALL'). If unspecified, 'ANY' is used.
 */
procedure retrieve_log_messages(
   p_log_crsr           out sys_refcursor,
   p_min_msg_id         in  varchar2      default null,
   p_max_msg_id         in  varchar2      default null,
   p_min_log_time       in  date          default null,
   p_max_log_time       in  date          default null,
   p_time_zone          in  varchar2      default 'UTC',
   p_min_msg_level      in  integer       default null,
   p_max_msg_level      in  integer       default null,
   p_msg_types          in  varchar2      default null,      
   p_min_inclusive      in  varchar2      default 'T',
   p_max_inclusive      in  varchar2      default 'T',
   p_abbreviated        in  varchar2      default 'T',
   p_message_mask       in  varchar2      default null,
   p_message_match_type in  varchar2      default 'GLOBI',
   p_ascending          in  varchar2      default 'T',
   p_session_id         in  varchar2      default 'ALL',
   p_properties         in  str_tab_tab_t default null,
   p_props_combination  in  varchar2      default 'ANY'); 
/**
 * Retrieves a cursor of database log messages that match the specified criteria
 *
 * @param p_min_msg_id         The lowest message id to match. If unspecified or null, no lower limit will be applied. 
 * @param p_max_msg_id         The highest message id to match. If unspecified or null, no upper limit will be applied.
 * @param p_min_log_time       The lowest log timestamp to match. If unspecified or null, no lower limit will be applied. 
 * @param p_max_log_time       The highest log timestamp to match. If unspecified or null, no upper limit will be applied.
 * @param p_time_zone          The time zone of p_min/max_log_time and of the returned log times. If unspecified or null, 'UTC' will be used.
 * @param p_min_msg_level      The lowest message level to match. If unspecified or null, no lower limit will be applied.
 *                             <p>Defined levels are as follows. Levels between defined levels can be used. 
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Level</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">Basic</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">Normal</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">Detailed</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">Verbose</td>
 *                               </tr>
 *                             </table>
 * @param p_max_msg_level      The highest message level to match. If unspecified or null, no upper limit will be applied.
 *                             <p>Defined levels are as follows. Levels between defined levels can be used. 
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Level</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">Basic</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">Normal</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">Detailed</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">Verbose</td>
 *                               </tr>
 *                             </table>
 * @param p_min_inclusive      A flag (T/F) specifying whether p_min_xxx is inclusive (can be in the matched messages). If unspecified, 'T' is used.
 * @param p_max_inclusive      A flag (T/F) specifying whether p_max_xxx is inclusive (can be in the matched messages). If unspecified, 'T' is used.
 * @param p_message_types      The numeric message types to match, as a comma-separated text of integers or integer ranges (a..b).
 *                             For example, to match all alarm and error/exception message types: '1,3,5-8,10,12,14-15'.
 *                             If unspecified or null, all message types are matched.
 *                             <p>Defined types are as follows. 
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Type</th>
 *                                 <th class="descr">Meaning</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">1</td>
 *                                 <td class="descr">AcknowledgeAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">2</td>
 *                                 <td class="descr">AcknowledgeRequest</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">3</td>
 *                                 <td class="descr">Alarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">4</td>
 *                                 <td class="descr">ControlMessage</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">5</td>
 *                                 <td class="descr">DeactivateAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">6</td>
 *                                 <td class="descr">Exception Thrown</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">7</td>
 *                                 <td class="descr">Fatal Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">8</td>
 *                                 <td class="descr">Initialization Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">9</td>
 *                                 <td class="descr">Initiated</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">10</td>
 *                                 <td class="descr">Load Library Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">11</td>
 *                                 <td class="descr">MissedHeartBeat</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">12</td>
 *                                 <td class="descr">PreventAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">13</td>
 *                                 <td class="descr">RequestAction</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">14</td>
 *                                 <td class="descr">ResetAlarm</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">15</td>
 *                                 <td class="descr">Runtime Exec Error</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">16</td>
 *                                 <td class="descr">Shutting Down</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">17</td>
 *                                 <td class="descr">State</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">18</td>
 *                                 <td class="descr">Status</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">19</td>
 *                                 <td class="descr">StatusIntervalMinutes</td>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr-center">20</td>
 *                                 <td class="descr">Terminated</td>
 *                               </tr>
 *                             </table>
 * @param p_abbreviated        A flag (T/F) specifying whether the cursror will contain abbreviated informtion. If unspecified, 'T' is used.
 * @param p_message_mask       A value to match log message text against. If unspecified or null, no message text matching is performed.
 * @param p_message_match_type Specifies the type of message text matching.
 *                             <p>Match types are as follows. For literal (non-pattern) matching, the Glob and Sql matching types are equivalent.
 *                             <p>
 *                             <table class="descr">
 *                               <tr>
 *                                 <th class="descr">Matching Type</th>
 *                                 <th class="descr">Normal Variant</th>
 *                                 <th class="descr">Negated Variant</th>
 *                                 <th class="descr">Case Insensitive Variant</th>
 *                                 <th class="descr">Negated Case Insensitive Variant</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr">Glob-style wildcards: '*' and '?'</th>
 *                                 <td class="descr">GLOB</th>
 *                                 <td class="descr">NGLOB</th>
 *                                 <td class="descr">GLOBI</th>
 *                                 <td class="descr">NGLOBI</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr">Sql-style wildcards: '%' and '_'</th>
 *                                 <td class="descr">SQL</th>
 *                                 <td class="descr">NSQL</th>
 *                                 <td class="descr">SQLI</th>
 *                                 <td class="descr">NSQLI</th>
 *                               </tr>
 *                               <tr>
 *                                 <td class="descr">Regular Expressions</th>
 *                                 <td class="descr">REGEX</th>
 *                                 <td class="descr">NREGEX</th>
 *                                 <td class="descr">REGEXI</th>
 *                                 <td class="descr">NREGEXI</th>
 *                               </tr>
 *                             </table>
 * @param p_ascending          A flag (T/F) specifying whether the results should be sorted ascending (T) or descending (F). If unspecified, 'T' is used.
 * @param p_session_id         Specifies the database sessions to match messages from. Must be null (current session), 'ALL' (all sessions) or a valid session id.
 * @param p_properties         The log message properties to match. If unspecified or null, no message property matching will be performed.
 * @param p_props_combination  Specifies whether to match any specified property ('ANY') or all specified properties ('ALL'). If unspecified, 'ANY' is used.
 *
 * @return The cursor that contains the matched log messages. 
 *        <p>The following columns are returned if p_abbreviated = 'T'
 *        <p>
 *        <table class="descr">
 *          <tr>
 *            <th class="descr">Column No.</th>
 *            <th class="descr">Column Name</th>
 *            <th class="descr">Data Type</th>
 *            <th class="descr">Contents</th>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">1</td>
 *            <td class="descr">msg_id</td>
 *            <td class="descr">varchar2(32)</td>
 *            <td class="descr">The log message identifier</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">2</td>
 *            <td class="descr">log_timestamp_utc</td>
 *            <td class="descr">timestamp(6)</td>
 *            <td class="descr">Timestamp of when the message was logged</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">3</td>
 *            <td class="descr">msg_text</td>
 *            <td class="descr">varchar2(4000)</td>
 *            <td class="descr">The text of the log message</td>
 *          </tr>
 *        </table>
 *        <p>The following columns are returned if p_abbreviated = 'F'
 *        <p>
 *        <table class="descr">
 *          <tr>
 *            <th class="descr">Column No.</th>
 *            <th class="descr">Column Name</th>
 *            <th class="descr">Data Type</th>
 *            <th class="descr">Contents</th>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">1</td>
 *            <td class="descr">msg_id</td>
 *            <td class="descr">varchar2(32)</td>
 *            <td class="descr">The log message identifier</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">2</td>
 *            <td class="descr">office_code</td>
 *            <td class="descr">number(10,0)</td>
 *            <td class="descr">Office code of the logging office</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">3</td>
 *            <td class="descr">log_timestamp_utc</td>
 *            <td class="descr">timestamp(6)</td>
 *            <td class="descr">Timestamp of when the message was logged (set by database)</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">4</td>
 *            <td class="descr">msg_level</td>
 *            <td class="descr">number(2,0)</td>
 *            <td class="descr">The detail level of the service</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">5</td>
 *            <td class="descr">component</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">The reporting CWMS component</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">6</td>
 *            <td class="descr">instance</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">Instance of the reporting CWMS component, if applicable</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">7</td>
 *            <td class="descr">host</td>
 *            <td class="descr">varchar2(256)</td>
 *            <td class="descr">Host on which the reporting component is executing</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">8</td>
 *            <td class="descr">port</td>
 *            <td class="descr">number(5,0)</td>
 *            <td class="descr">Port at which the reporting component is contacted, if applicable</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">9</td>
 *            <td class="descr">report_timestamp_utc</td>
 *            <td class="descr">timestamp(6)</td>
 *            <td class="descr">Timestamp of when the message was reported (set by client)</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">10</td>
 *            <td class="descr">session_username</td>
 *            <td class="descr">varchar2(30)</td>
 *            <td class="descr">The database session usernmae</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">11</td>
 *            <td class="descr">session_osuser</td>
 *            <td class="descr">varchar2(30)</td>
 *            <td class="descr">The OS username on the client</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">12</td>
 *            <td class="descr">session_process</td>
 *            <td class="descr">varchar2(24)</td>
 *            <td class="descr">The name of the client process</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">13</td>
 *            <td class="descr">session_program</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">The name of the client program</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">14</td>
 *            <td class="descr">session_machine</td>
 *            <td class="descr">varchar2(64)</td>
 *            <td class="descr">The machine name of the connect client</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">15</td>
 *            <td class="descr">msg_type</td>
 *            <td class="descr">number(2,0)</td>
 *            <td class="descr">The message type</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">16</td>
 *            <td class="descr">mst_text</td>
 *            <td class="descr">varchar2(4000)</td>
 *            <td class="descr">The text of the log message</td>
 *          </tr>
 *          <tr>
 *            <td class="descr-center">17</td>
 *            <td class="descr">properties</td>
 *            <td class="descr">cursor</td>
 *            <td class="descr">A cursor of properties for the message
 *              <table class="descr">
 *                <tr>
 *                  <th class="descr">Column No.</th>
 *                  <th class="descr">Column Name</th>
 *                  <th class="descr">Data Type</th>
 *                  <th class="descr">Contents</th>
 *                </tr>
 *                <tr>
 *                  <td class="descr-center">1</td>
 *                  <td class="descr">name</td>
 *                  <td class="descr">varchar2(64)</td>
 *                  <td class="descr">The log message identifier</td>
 *                </tr>
 *                <tr>
 *                  <td class="descr-center">2</td>
 *                  <td class="descr">type</td>
 *                  <td class="descr">number(1,0)</td>                                    
 *                  <td class="descr">The property type</td>
 *                </tr>
 *                <tr>
 *                  <td class="descr-center">3</td>
 *                  <td class="descr">value</td>
 *                  <td class="descr">varchar2(4000)</td>
 *                  <td class="descr">The value of the property</td>
 *                </tr>
 *              </table>
 *            </td>
 *          </tr>
 *        </table>
 */
function retrieve_log_messages_f(
   p_min_msg_id         in varchar2      default null,
   p_max_msg_id         in varchar2      default null,
   p_min_log_time       in date          default null,
   p_max_log_time       in date          default null,
   p_time_zone          in varchar2      default 'UTC',
   p_min_msg_level      in integer       default null,
   p_max_msg_level      in integer       default null,
   p_msg_types          in varchar2      default null,      
   p_min_inclusive      in varchar2      default 'T',
   p_max_inclusive      in varchar2      default 'T',
   p_abbreviated        in varchar2      default 'T',
   p_message_mask       in varchar2      default null,
   p_message_match_type in varchar2      default 'GLOBI',
   p_ascending          in varchar2      default 'T',
   p_session_id         in varchar2      default 'ALL',
   p_properties         in str_tab_tab_t default null,
   p_props_combination  in varchar2      default 'ANY') 
   return sys_refcursor;
   
-- not documented
function parse_log_msg_prop_tab (
   p_tab in log_message_props_tab_t)
   return varchar2;
/**
 * Trims messages from the message log tables. This procedure uses the following
 * database property entries:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Owning Office</th>
 *     <th class="descr">Property Category Identifier</th>
 *     <th class="descr">Property Identifier</th>
 *     <th class="descr">Meaning</th>
 *     <th class="descr">Default Value if Property Not Set</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">CWMS</td>
 *     <td class="descr">CWMSDB</td>
 *     <td class="descr">logging.entry.max_age</td>
 *     <td class="descr">Max entry age in days to keep when trimming log</td>
 *     <td class="descr-center">120</td>
 *   </tr>
 *   <tr>
 *     <td class="descr">CWMS</td>
 *     <td class="descr">CWMSDB</td>
 *     <td class="descr">logging.entry.max_entries</td>
 *     <td class="descr">Max number of log message to keep when trimming log</td>
 *     <td class="descr-center">100000</td>
 *   </tr>
 * </table>
 *
 * @see cwms_properties
 */
procedure trim_log;
/**
 * Starts the background job to trim the message log tables.  If already running, the
 * existing job is stopped and restarted. This procedure uses the following
 * database property entry:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Owning Office</th>
 *     <th class="descr">Property Category Identifier</th>
 *     <th class="descr">Property Identifier</th>
 *     <th class="descr">Meaning</th>
 *     <th class="descr">Default Value if Property Not Set</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">CWMS</td>
 *     <td class="descr">CWMSDB</td>
 *     <td class="descr">logging.auto_trim.interval</td>
 *     <td class="descr">Interval in minutes for job trim_log to execute.</td>
 *     <td class="descr-center">120</td>
 *   </tr>
 * </table>
 *
 * @see cwms_properties
 */
procedure start_trim_log_job;
/**
 * Creates the CWMS queues for the specified office. If any of the queues exist, they are deleted and re-created
 */
procedure create_queues(
   p_office_id in varchar2);

/**
 * Creates the CWMS exception queue for the specified office. If any of the queues exist, they are deleted and re-created
 */
procedure create_exception_queue(
   p_office_id in varchar2);
/**
 * Purges message queues of undeliverable messages.  If a queue subscriber aborts without
 * unsubscribing, a zombie subscription is left behind and messages for that subscription accumulate in the queue.
 * This procedure kills zombie subscribers and purges queues of undeliverable messages
 */
procedure purge_queues;
/**
 * Starts the background job to purges the queues.  If already running, the
 * existing job is stopped and restarted. This procedure uses the following
 * database property entry:
 * <p>
 * <table class="descr">
 *   <tr>
 *     <th class="descr">Owning Office</th>
 *     <th class="descr">Property Category Identifier</th>
 *     <th class="descr">Property Identifier</th>
 *     <th class="descr">Meaning</th>
 *     <th class="descr">Default Value if Property Not Set</th>
 *   </tr>
 *   <tr>
 *     <td class="descr">CWMS</td>
 *     <td class="descr">CWMSDB</td>
 *     <td class="descr">queues.all.purge_interval</td>
 *     <td class="descr">Interval in minutes for purge_queues to execute.</td>
 *     <td class="descr-center">5</td>
 *   </tr>
 * </table>
 *
 * @see cwms_properties
 */
procedure start_purge_queues_job;
/**
 * Registers a callback procedure for a message queue.  A registered callback callback
 * procedures is called for every message that is enqueued into the queue, and must
 * deuque the message to keep message from accumulating.
 *
 * @param p_procedure_name  The name of the procedure to register.  This can be a free standing or package procedure and must have exactly the following signature:<p>
 * <big><pre>
 * procedure procedure_name (
 *      context  in raw,
 *      reginfo  in sys.aq$_reg_info,
 *      descr    in sys.aq$_descriptor,
 *      payload  in raw,
 *      payloadl in number);
 * </pre></big>
 *
 * @param p_queue_name      The name of the queue to register with, in one of the forms shown above
 * @param p_subscriber_name The subscriber name for the queue (unique per queue).  If not specified or null, a unique subscriber name will be generated.
 *
 * @return The (specified or generated) subscriber name.
 */
function register_msg_callback (
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2 default null)
   return varchar2;
/**
 * Unregisters a callback procedure from a message queue.
 *
 * @param p_procedure_name  The name of the procedure to register. Must be the same name used to register with
 * @param p_queue_name      The name of the queue to register with, in one of the forms shown above
 * @param p_subscriber_name The subscriber name for the queue. Must be the same as retuned from the callback registration
 *
 * @return The (specified or generated) subscriber name.
 */
procedure unregister_msg_callback (
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2); 
/**
 * Pauses the enqueueing of all messages for the specified office for a specified time period.  If this is called without
 * any parameters, message enqueueing is paused for 10 minutes from the current time for the current sessions, for all queues associated with the session user's default office.
 * The duration of the pause must be between one minute and one week.
 *
 * @param p_number       The number of units to pause enqueueing for
 * @param p_unit         The unit associated with p_number. Must be one of the following (ignoring case)
 * <ul><li>MINUTE</li><li>MINUTES</li><li>HOUR</li><li>HOURS</li><li>DAY</li><li>DAYS</li></ul>
 * @param p_all_sessions A flag ('T' or 'F') specifying whether to pause enqueueing for all database sessions for the specified office.  If not specified or 'F', only the current session is paused.
 * @param p_office_id    The office whose queues to pause message enqueueing for.  If not specified or NULL, the session user's default office is used.
 *
 * @see procedure unpause_message_queueing
 * @see function get_message_queueing_pause_min
 * @see function is_message_queueing_paused
 */   
procedure pause_message_queueing (
   p_number       in integer  default 10,
   p_unit         in varchar2 default 'MINUTES',
   p_all_sessions in varchar2 default 'F',
   p_office_id    in varchar2 default null);
/**
 * Un-pauses the enqueueing of all messages for the specified office for a specified time period.  If this is called without
 * any parameters, message queueing is un-paused for the current session for all queues associated with the sessions users' default office. Note that
 * message queueing for the current session will remain paused as long as there is a pause in effect for the current session or all sessions for the specified or default office.
 *
 * @param p_all_sessions A flag ('T' or 'F') specifying whether to un-pause enqueueing for all database sessions for the specified office.  If not specified or 'F', only the current session is un-paused.
 *                       Note that message queueing for the current session will remain paused as long as there is a pause in effect for the current session or all sessions for the specified or default office.
 * @param p_force        A flag ('T' or 'F') specifying whether to forceably un-pause each session whose enqueueing is currently paused on a session basis. This parameter is ignored unless p_all_sessions is 'T'.
 * @param p_office_id    The office whose queues to un-pause message enqueueing for.  If not specified or NULL, the session user's default office is used.
 *
 * @see procedure pause_message_queueing
 * @see function get_message_queueing_pause_min
 * @see function is_message_queueing_paused
  */
procedure unpause_message_queueing(
   p_all_sessions in varchar2 default 'F',
   p_force        in varchar2 default 'F',
   p_office_id    in varchar2 default null);
/**
 * Retrieves the number of minutes remaining until all pauses preventing the current session from enqueueing messages to queues associated with the specified or default office expire.
 * This number will be the greater of time remaining on any all-session pause and any session-specific pause.
 *
 * @param p_office_id The office whose queues to check for current enqueueing pauses.  If not specified or NULL, the session user's default office is used.
 *
 * @return The number of minutes remaining until all enqueueing pauses expire, or -1 if no pauses are currently in effect
 *
 * @see procedure pause_message_queueing
 * @see procedure unpause_message_queueing
 * @see function is_message_queueing_paused
 */
function get_message_queueing_pause_min(
   p_office_id in varchar2 default null)
   return integer;
/**
 * Retrieves whether any pauses are in effect affecting that prevent the current session from enqueueing messages to queues associated with the specified or default office.
 *
 * @param p_office_id The office whose queues to check for current enqueueing pauses.  If not specified or NULL, the session user's default office is used.
 *
 * @return True or false
 *
 * @see procedure pause_message_queueing
 * @see procedure unpause_message_queueing
 * @see function get_message_queueing_pause_min
 */
function is_message_queueing_paused(
   p_office_id in varchar2 default null)
   return boolean;      
/**
 * Retrieves information about the message client.
 *
 * @param p_db_user   The name of the database session user
 * @param p_os_user   The name of the client OS user as identified by the server
 * @param p_app_name  The name of the application as identified by the server
 * @param p_host_name The name of the client system as identified by the server
 */
procedure retrieve_client_info(
   p_db_user   out varchar2,
   p_os_user   out varchar2,
   p_app_name  out varchar2,
   p_host_name out varchar2);
/**
 * Retrieves the name of the client system as identified by the server
 */
function retrieve_host_name
   return varchar2;
/*
 * Creates and registers a queue subscriber name with a unique name based on the office, queue name, client system name and process id
 *
 * @param p_subscriber_name An output parameter for the unique subscription name
 * @param p_host_name       An output parameter for the client system name as identified by the server
 * @param p_queue_name      The name of the queue to subscribe to. Must be TS_STORED, STATUS, or REALTIME_OPS
 * @param p_process_id      The process identifier (pid) of the application requesting the subscription
 * @param p_app_name        The name of the application requesting the subscription. If not specified or NULL, the application name will be determined by the database, which works well for binary executables, but less so for Java applications connected via JDBC.
 * @param p_fail_if_exists  A flag ('T'/'F') spcecifying whether to fail if a subsciber already exists for the office/queue/pid/app 
 * @param p_office_id       The office owning the queue to subscribe to. If not specified or NULL, the session user's office is used
 */
procedure register_queue_subscriber(
   p_subscriber_name out varchar2,
   p_host_name       out varchar2,
   p_queue_name      in  varchar2,
   p_process_id      in  integer,
   p_app_name        in  varchar2 default null,
   p_fail_if_exists  in  varchar2 default 'F',
   p_office_id       in  varchar2 default null); 
/*
 * Creates and registers a queue subscriber name with a unique name based on the queue name and application instance UUID
 *
 * @param p_subscriber_name An output parameter for the unique subscription name
 * @param p_queue_name      The name of the queue to subscribe to. Must be TS_STORED, STATUS, or REALTIME_OPS
 * @param p_uuid            The application instance UUID  
 * @param p_fail_if_exists  A flag ('T'/'F') spcecifying whether to fail if a subsciber already exists for the office/queue/pid/app
 *
 * @see cwms_util.set_application_login
 *
 */
procedure register_queue_subscriber(
   p_subscriber_name out varchar2,
   p_queue_name      in  varchar2,
   p_uuid            in  varchar2,
   p_fail_if_exists  in  varchar2 default 'F'); 
/*
 * Creates and registers a queue subscriber name with a unique name based on the office, queue name, client system name and process id
 *
 * @param p_queue_name     The name of the queue to subscribe to. Must be TS_STORED, STATUS, or REALTIME_OPS
 * @param p_process_id     The process identifier (pid) of the application requesting the subscription
 * @param p_app_name       The name of the application requesting the subscription. If not specified or NULL, the application name will be determined by the database, which works well for binary executables, but less so for Java applications connected via JDBC.
 * @param p_fail_if_exists A flag ('T'/'F') spcecifying whether to fail if a subsciber already exists for the office/queue/pid/app. If not specified, '' will be used 
 * @param p_office_id      The office owning the queue to subscribe to. If not specified or NULL, the session user's office is used
 *
 * @return A string containing the client system name and unique subscriber name separated by a line feed character ('\n'; character decimal 10, hex a)
 */
function register_queue_subscriber_f(
   p_queue_name       in varchar2,
   p_process_id       in integer,
   p_app_name         in varchar2 default null,
   p_fail_if_exists   in varchar2 default 'F',
   p_office_id        in varchar2 default null)
   return varchar2;
/*
 * Creates and registers a queue subscriber name with a unique name based on the queue name and application instance UUID
 *
 * @param p_queue_name     The name of the queue to subscribe to. Must be TS_STORED, STATUS, or REALTIME_OPS
 * @param p_uuid           The the application instance UUID  
 * @param p_fail_if_exists A flag ('T'/'F') spcecifying whether to fail if a subsciber already exists for the office/queue/pid/app. If not specified, 'F' will be used 
 *
 * @return The subscriber name
 *
 * @see cwms_util.set_application_login
 */
function register_queue_subscriber_f(
   p_queue_name     in varchar2,
   p_uuid           in varchar2,
   p_fail_if_exists in varchar2 default 'F')
   return varchar2;
/*
 * Unregisters a queue subscriber name created with register_queue_subscriber or register_queue_subscriber_f
 *
 * @param p_subscriber_name       The unique name of the subscription to delete
 * @param p_process_id            The process identifier (pid) of the application requesting the subscription to be deleted
 * @param p_fail_on_wrong_host    A flag ('T'/'F') specifying whether to fail if the procedure is called from a client that is different from the one used to register the subscription. If not specified, 'T' is used
 * @param p_fail_on_wrong_process A flag ('T'/'F') specifying whether to fail if the specified pid is different from the one used to register the subscription. If not specified, 'T' is used
 * @param p_office_id             The office owning the queue to unsubscribe from. If not specified or NULL, the session user's office is used
 */
procedure unregister_queue_subscriber(
   p_subscriber_name       in varchar2,
   p_process_id            in integer,
   p_fail_on_wrong_host    in varchar2 default 'T',
   p_fail_on_wrong_process in varchar2 default 'T',
   p_office_id             in varchar2 default null);
/*
 * Unregisters a queue subscriber name created with register_queue_subscriber or register_queue_subscriber_f using an application instance UUID
 *
 * @param p_queue_name     The name of the queue to subscribe to. Must be TS_STORED, STATUS, or REALTIME_OPS
 * @param p_uuid           The the application instance UUID  
 *
 * @see cwms_util.set_application_login
 */
procedure unregister_queue_subscriber(
   p_queue_name in varchar2,
   p_uuid       in varchar2);
/*
 * Updates the process identifier for a currently registered queue subscriber name
 *
 * @param p_subscriber_name       The unique name of the subscription to update
 * @param p_process_id            The new process identifier to associate with the subscription
 * @param p_fail_on_wrong_host    A flag ('T'/'F') specifying whether to fail if the procedure is called from a client that is different from the one used to register the subscription. If not specified, 'T' is used
 * @param p_office_id             The office owning the queue to update the subscription for. If not specified or NULL, the session user's office is used
 */
procedure update_queue_subscriber(
   p_subscriber_name       in varchar2,
   p_process_id            in integer,
   p_fail_on_wrong_host    in varchar2 default 'T',
   p_office_id             in varchar2 default null);   

function get_call_stack return str_tab_tab_t;   
end cwms_msg;
/
show errors;


