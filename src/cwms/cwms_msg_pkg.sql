create or replace package cwms_msg
as

exc_no_subscribers exception; pragma exception_init(exc_no_subscribers, -24033);

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
   p_msg_queue in varchar2)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in varchar2,
   p_msg_queue  in varchar2)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in out nocopy clob,
   p_msg_queue  in varchar2)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in     pls_integer)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in varchar2)
   return integer;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in out nocopy clob)
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
   p_publish   in boolean default true)
   return integer;

-------------------------------------------------------------------------------
-- PROCEDURE LOG_DB_MESSAGE(...)
--
procedure log_db_message(
   p_procedure in varchar2,
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

end cwms_msg;
/
show errors;


