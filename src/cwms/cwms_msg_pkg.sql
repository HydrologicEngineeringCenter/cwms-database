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
function get_msg_id (
   p_millis in integer default null) 
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
procedure log_db_message(
   p_procedure in varchar2,
   p_msg_level in integer default msg_level_normal,
   p_message   in varchar2);
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

end cwms_msg;
/
show errors;


