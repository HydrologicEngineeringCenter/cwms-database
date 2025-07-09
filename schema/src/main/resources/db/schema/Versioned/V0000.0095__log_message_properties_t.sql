create type log_message_properties_t
/**
 * Holds a single property for a database log message
 *
 * @see type log_message_props_tab_t
 *
 * @member msg_id     the unique message identifier
 * @member prop_name  the name of the property
 * @member prop_type  the property type
 * @member prop_value the property value, if numeric
 * @member prop_text  the property value, if text
 */
as object (
   msg_id     varchar2(32),
   prop_name  varchar2(64),
   prop_type  number(1),
   prop_value number,
   prop_text  varchar2(4000)
);
/


create or replace public synonym cwms_t_log_message_properties for log_message_properties_t;

