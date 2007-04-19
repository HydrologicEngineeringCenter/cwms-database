create or replace package body cwms_msg
as
-------------------------------------------------------------------------------
-- FUNCTION NEW_MESSAGE(...)
--
function new_message(
   p_type in varchar2)
   return sys.aq$_jms_text_message
is
   msg sys.aq$_jms_text_message;
begin
   msg := sys.aq$_jms_text_message.construct();
   msg.set_string_property('type', p_type);
   msg.set_long_property('millis', cwms_util.current_millis);
   
   return msg;
end new_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_MESSAGE(...)
--
procedure publish_message(
   p_message   in sys.aq$_jms_text_message,
   p_msg_queue in varchar2)
is
   message_properties dbms_aq.message_properties_t;
   enqueue_options    dbms_aq.enqueue_options_t;      
   msgid              raw(16);
begin
   -------------------------
   -- enqueue the message --
   -------------------------
   dbms_aq.enqueue(
      'CWMS_20.' || p_msg_queue,
      enqueue_options,
      message_properties,
      p_message,
      msgid);

   commit;

exception
   ---------------------------------------
   -- ignore the case of no subscribers --
   ---------------------------------------
   when exc_no_subscribers then null;
end publish_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_MESSAGE(...)
--
procedure publish_message(
   p_properties in xmltype,
   p_msg_queue  in varchar2)
is
   l_msg   sys.aq$_jms_text_message;
   l_nodes xmltype;
   l_node  xmltype;
   l_name  varchar2(128);
   l_type  varchar2(128);
   l_bool  boolean;
   i       pls_integer;
begin
   l_type  := p_properties.extract('/cwms_message/@type').getstringval();
   l_nodes := p_properties.extract('/cwms_message/property');
   l_msg   := new_message(l_type);
   if l_nodes is not null then
      i := 0;
      loop
         i := i + 1;
         l_node := l_nodes.extract('*['||i||']');
         exit when l_node is null;
         l_name  := l_node.extract('*/@name').getstringval();
         l_type  := l_node.extract('*/@type').getstringval();
         case l_type
            when 'boolean' then
               l_type := lower(cwms_util.strip(l_node.extract('*/node()').getstringval()));
               l_bool := 
                  case l_type
                     when 't'     then true
                     when 'true'  then true
                     when 'y'     then true
                     when 'yes'   then true
                     when 'on'    then true
                     when '1'     then true
                     when 'f'     then false
                     when 'false' then false
                     when 'n'     then false
                     when 'no'    then false
                     when 'off'   then false
                     when '0'     then false
                     else              null
                  end;
               if l_bool is null then
                  cwms_err.raise('INVALID_ITEM', l_type, 'CWMS message boolean property value, use t[rue]/f[alse] y[es]/n[o] on/off 1/0');
               end if;
               l_msg.set_boolean_property(l_name, l_bool);
            when 'byte'    then
               l_msg.set_byte_property(l_name, cwms_util.strip(l_node.extract('*/node()').getnumberval()));
            when 'short'   then
               l_msg.set_short_property(l_name, cwms_util.strip(l_node.extract('*/node()').getnumberval()));
            when 'int'     then
               l_msg.set_int_property(l_name, cwms_util.strip(l_node.extract('*/node()').getnumberval()));
            when 'long'    then
               l_msg.set_long_property(l_name, cwms_util.strip(l_node.extract('*/node()').getnumberval()));
            when 'float'   then
               l_msg.set_float_property(l_name, cwms_util.strip(l_node.extract('*/node()').getnumberval()));
            when 'double'  then
               l_msg.set_double_property(l_name, cwms_util.strip(l_node.extract('*/node()').getnumberval()));
            when 'String'  then
               l_msg.set_string_property(l_name, cwms_util.strip(l_node.extract('*/node()').getstringval()));
            else
               cwms_err.raise('INVALID_ITEM', l_type, 'CWMS message property type');
         end case;
      end loop;
   end if;
   l_node := p_properties.extract('/cwms_message/text');
   if l_node is not null then
      l_msg.set_text(cwms_util.strip(l_node.extract('*/node()').getstringval()));
   end if;

   publish_message(l_msg, p_msg_queue);
   
end publish_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_MESSAGE(...)
--
procedure publish_message(
   p_properties in varchar2,
   p_msg_queue  in varchar2)
is
begin
   publish_message(xmltype(p_properties), p_msg_queue);
end publish_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_MESSAGE(...)
--
procedure publish_message(
   p_properties in clob,
   p_msg_queue  in varchar2)
is
begin
   publish_message(xmltype(p_properties), p_msg_queue);
end publish_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_STATUS_MESSAGE(...)
--
procedure publish_status_message(p_message in sys.aq$_jms_text_message)
is
begin
   publish_message(p_message, 'STATUS');
end publish_status_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_STATUS_MESSAGE(...)
--
procedure publish_status_message(
   p_properties in varchar2)
is
begin
   publish_message(xmltype(p_properties), 'STATUS');
end publish_status_message;

-------------------------------------------------------------------------------
-- PROCEDURE PUBLISH_STATUS_MESSAGE(...)
--
procedure publish_status_message(
   p_properties in clob)
is
begin
   publish_message(xmltype(p_properties), 'STATUS');
end publish_status_message;

end cwms_msg;
/
show errors;

