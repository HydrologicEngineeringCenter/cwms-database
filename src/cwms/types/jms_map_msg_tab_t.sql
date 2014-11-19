create type jms_map_msg_tab_t
-- not documented
as table of sys.aq$_jms_map_message;
/


create or replace public synonym cwms_t_jms_map_msg_tab for jms_map_msg_tab_t;

