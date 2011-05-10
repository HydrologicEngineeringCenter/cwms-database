create or replace package cwms_msg
as

exc_no_subscribers exception; pragma exception_init(exc_no_subscribers, -24033);

------------------------------
-- message level contstants --
------------------------------
msg_level_none     constant integer :=  0;
msg_level_basic    constant integer :=  1;
msg_level_normal   constant integer :=  3;
msg_level_detailed constant integer :=  5;
msg_level_verbose  constant integer :=  7;
--------------------------
-- message id variables --
--------------------------
last_millis integer := 0;
last_seq    integer := 0;

-------------------------------------------------------------------------------
--
-- The publish_message and publish_status_message functions that take a VARCHAR2
-- or CLOB parameter named p_properties expect an XML instance of the following
-- form:
-- 
-- <cwms_message type="message type">
--    <property name="propery name" type="property type">property value</property>
--    <property name="propery name" type="property type">property value</property>
--    ...
--    <text>
--       Message Text
--    </text>
-- </cwms_message>
-- 
-- The <text> element is optional, and zero or more <property> elements may
-- be specified.
-- 
-- Valid property type attributes are the JMS valid property types, namely:
-- 
--    boolean, byte, short, int, long, float, double, String
-- 
-- Property values must be valid for the specified property type.
--
-- Do not specify a property name "type", as this property is set to the type
-- attibute of the root (<cwms_message>) element.
--
-- Do not specify a property name "millis", as this property is set to the 
-- creation time of the message.
--

-------------------------------------------------------------------------------
-- FUNCTION GET_MSG_ID(...)
--
function get_msg_id (
   p_millis in integer default null) 
   return varchar2;

-------------------------------------------------------------------------------
-- FUNCTION GET_QUEUE_NAME(...)
--
function get_queue_name(
   p_queuename in varchar2) 
   return varchar2;

-------------------------------------------------------------------------------
-- PROCEDURE NEW_MESSAGE(...)
--
procedure new_message(
   p_msg   out sys.aq$_jms_map_message,
   p_msgid out pls_integer,
   p_type  in  varchar2);

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in pls_integer,
   p_msg_queue in varchar2,
	p_immediate in boolean default false)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in varchar2,
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in out nocopy clob,
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in pls_integer,
	p_immediate in boolean default false)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in varchar2,
	p_immediate  in boolean default false)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in out nocopy clob,
	p_immediate  in boolean default false)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION LOG_MESSAGE(...)
--
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

-------------------------------------------------------------------------------
-- FUNCTION LOG_LONG_MESSAGE(...)
--
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

-------------------------------------------------------------------------------
-- FUNCTION GET_MESSAGE_CLOB(...)
--
function get_message_clob(
   p_message_id in varchar2)
   return clob;

-------------------------------------------------------------------------------
-- PROCEDURE LOG_DB_MESSAGE(...)
--
procedure log_db_message(
   p_procedure in varchar2,
   p_msg_level in integer default msg_level_normal,
   p_message   in varchar2);
    
-------------------------------------------------------------------------------
-- FUNCTION LOG_MESSAGE_SERVER_MESSAGE(...)
--
function log_message_server_message(
   p_message in varchar2)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION LOG_MESSAGE_SERVER_MESSAGE(...)
--
function log_message_server_message(
   p_message in out nocopy clob)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PARSE_LOG_MSG_PROP_TAB(...)
--
function parse_log_msg_prop_tab (
   p_tab in log_message_props_tab_t)
   return varchar2;
   
-------------------------------------------------------------------------------
-- PROCEDURE TRIM_LOG
--
-- This procedure deletes log entries older than specified by the property
-- CWMSDB/logging.entry.max_age and deletes any remaining oldest entries
-- to keep the table down to the maximum number specified in CWMSDB/
-- loggin.table.max_entries
--
procedure trim_log;   

--------------------------------------------------------------------------------
-- procedure start_trim_log_job
--
procedure start_trim_log_job;

--------------------------------------------------------------------------------
-- procedure purge_queues
--
procedure purge_queues;

--------------------------------------------------------------------------------
-- procedure start_purge_queues_job
--
procedure start_purge_queues_job;
   
--------------------------------------------------------------------------------
-- procedure register_msg_callback
--
function register_msg_callback (
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2 default null)
   return varchar2;
   
--------------------------------------------------------------------------------
-- procedure unregister_msg_callback
--
procedure unregister_msg_callback (
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2);

end cwms_msg;
/
show errors;


