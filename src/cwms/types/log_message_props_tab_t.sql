create type log_message_props_tab_t
/**
 * Holds a collection of message properites for a database log message
 *
 * @see type log_message_properties_t
 * @see cwms_msg.parse_log_msg_prop_tab
 */
as table of log_message_properties_t;
/


create or replace public synonym cwms_t_log_message_props_tab for log_message_props_tab_t;

