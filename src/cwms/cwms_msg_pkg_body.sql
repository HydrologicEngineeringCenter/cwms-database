create or replace package body cwms_msg
as

-------------------------------------------------------------------------------
-- FUNCTION GET_MSG_ID(...)
--
function get_msg_id (p_millis in integer default null) return varchar2
is
   l_millis  integer := p_millis;
   seq       integer;
begin
   if l_millis is null then l_millis := cwms_util.current_millis; end if;
   select cwms_log_msg_seq.nextval into seq from dual;
   return '' || l_millis || '_' || seq;
end;

-------------------------------------------------------------------------------
-- FUNCTION GET_QUEUE_PREFIX(...)
--
function get_queue_prefix return varchar2
is
   l_db_office_id   varchar2(16);
begin
   /*
   select co2.office_id
     into l_db_office_id
     from cwms_office co1,
          cwms_office co2
    where co1.office_code = cwms_util.user_office_code
      and co2.office_code = co1.db_host_office_code;
   */
   l_db_office_id := cwms_util.user_office_id;   
   return l_db_office_id;       
end get_queue_prefix;

-------------------------------------------------------------------------------
-- FUNCTION GET_QUEUE_NAME(...)
--
function get_queue_name (p_queuename in varchar2) return varchar2
is
   l_queuename varchar2(32) := p_queuename;
   l_found     boolean      := false;
begin

   for i in 1..2 loop
      if not l_found then
         begin
            select name
              into l_queuename
              from dba_queues
             where name = upper(l_queuename)
               and owner = 'CWMS_20'
               and queue_type = 'NORMAL_QUEUE';
            l_found := true;
         exception
            when no_data_found then 
               l_queuename := get_queue_prefix || '_' || l_queuename;
         end;
      end if;
   end loop;
   
   if not l_found then
      l_queuename := null;
   else
      l_queuename := 'CWMS_20.' || l_queuename;
   end if;
   
   return l_queuename;
   
end get_queue_name;

-------------------------------------------------------------------------------
-- FUNCTION NEW_MESSAGE(...)
--
procedure new_message(
   p_msg   out sys.aq$_jms_map_message,
   p_msgid out pls_integer,
   p_type  in  varchar2)
is
begin
   p_msg   := sys.aq$_jms_map_message.construct();
   p_msgid := p_msg.prepare(null);
   p_msg.set_string(p_msgid, 'type', p_type);
end new_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in pls_integer,
   p_msg_queue in varchar2)
   return integer
is
   l_message_properties dbms_aq.message_properties_t;
   l_enqueue_options    dbms_aq.enqueue_options_t;      
   l_msgid              raw(16);
   l_queuename          varchar2(32);
   l_now                integer := cwms_util.current_millis;           
begin
   l_queuename := get_queue_name(p_msg_queue);
   if l_queuename is null then
      cwms_err.raise('INVALID_ITEM', p_msg_queue, 'message queue name');
   end if;
   -------------------------
   -- enqueue the message --
   -------------------------
   p_message.set_long(p_messageid, 'millis', l_now);
   p_message.flush(p_messageid);
   p_message.clean(p_messageid);
    
   dbms_aq.enqueue(
      l_queuename,
      l_enqueue_options,
      l_message_properties,
      p_message,
      l_msgid);

   commit;
   return l_now;

exception
   ---------------------------------------
   -- ignore the case of no subscribers --
   ---------------------------------------
   when exc_no_subscribers then return l_now;
   when others then raise;
   
end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in out nocopy xmltype,
   p_msg_queue  in varchar2)
   return integer
is
   l_msg   sys.aq$_jms_map_message;
   l_msgid pls_integer;
   l_nodes xmltype;
   l_node  xmltype;
   l_name  varchar2(128);
   l_type  varchar2(128);
   l_bool  boolean;
   i       pls_integer;
begin
   l_type  := p_properties.extract('/cwms_message/@type').getstringval();
   l_nodes := p_properties.extract('/cwms_message/property');
   new_message(l_msg, l_msgid, l_type);
   if l_nodes is not null then
      i := 0;
      loop
         i := i + 1;
         l_node := l_nodes.extract('*['||i||']');
         exit when l_node is null;
         l_name  := l_node.extract('*/@name').getstringval();
         l_type  := l_node.extract('*/@type').getstringval();
         l_node  := l_node.extract('*/node()');
         if l_node is null then
            cwms_err.raise('INVALID_ITEM', 'NULL', 'CWMS message property value');
         end if;
         case l_type
            when 'boolean' then
               l_type := lower(cwms_util.strip(l_node.getstringval()));
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
               l_msg.set_boolean(l_msgid, l_name, l_bool);
            when 'byte'    then
               l_msg.set_byte(l_msgid, l_name, cwms_util.strip(l_node.getnumberval()));
            when 'short'   then
               l_msg.set_short(l_msgid, l_name, cwms_util.strip(l_node.getnumberval()));
            when 'int'     then
               l_msg.set_int(l_msgid, l_name, cwms_util.strip(l_node.getnumberval()));
            when 'long'    then
               l_msg.set_long(l_msgid, l_name, cwms_util.strip(l_node.getnumberval()));
            when 'float'   then
               l_msg.set_float(l_msgid, l_name, cwms_util.strip(l_node.getnumberval()));
            when 'double'  then
               l_msg.set_double(l_msgid, l_name, cwms_util.strip(l_node.getnumberval()));
            when 'String'  then
               l_msg.set_string(l_msgid, l_name, cwms_util.strip(l_node.getstringval()));
            else
               cwms_err.raise('INVALID_ITEM', l_type, 'CWMS message property type');
         end case;
      end loop;
   end if;
   l_node := p_properties.extract('/cwms_message/text');
   if l_node is not null then
      l_msg.set_string(l_msgid, 'body', cwms_util.strip(l_node.extract('*/node()').getstringval()));
   end if;

   return publish_message(l_msg, l_msgid, p_msg_queue);
   
end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in varchar2,
   p_msg_queue  in varchar2)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, p_msg_queue);
end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in out nocopy clob,
   p_msg_queue  in varchar2)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, p_msg_queue);
end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in     pls_integer) 
   return integer
is
begin
   return publish_message(p_message, p_messageid, 'STATUS');
end publish_status_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in varchar2)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, 'STATUS');
end publish_status_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in out nocopy clob)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, 'STATUS');
end publish_status_message;

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
   p_msg_level in integer,
   p_publish   in boolean)
   return integer
is
   pragma autonomous_transaction;
   
   l_now         integer;
   l_now_ts      timestamp;
   l_msg_id      varchar2(32);
   l_office_code number(10);
   l_message     varchar2(4000);
   l_document    xmltype;
   l_nodes       xmltype;
   l_node        xmltype;
   l_name        varchar2(128);
   l_msgtype     varchar2(64);
   l_type        varchar2(64);
   l_text        varchar2(4000);
   l_number      number;
   l_prop_type   integer;
   l_extra       varchar2(4000);
   l_pos         pls_integer;
   l_typeid      integer;
   i             pls_integer;
   lf            constant varchar2(1) := chr(10);
   l_msg_level   integer := nvl(p_msg_level, msg_level_normal);
   l_publish     boolean := nvl(p_publish, true);
begin
   if l_msg_level > msg_level_none then
      -----------------------------------------
      -- insert message data into the tables --
      -----------------------------------------
      l_now         := cwms_util.current_millis;
      l_now_ts      := cwms_util.to_timestamp(l_now);
      l_msg_id      := get_msg_id(l_now);
      l_office_code := cwms_util.user_office_code;
      l_document    := xmltype(p_message);
      l_msgtype     := l_document.extract('/cwms_message/@type').getstringval();
      l_node        := l_document.extract('/cwms_message/text');
      if l_node is not null then
         l_message := cwms_util.strip(l_node.extract('*/node()').getstringval());
      end if;

      -------------------------------
      -- first the message body... --
      -------------------------------
      begin
         select message_type_code 
           into l_typeid 
           from cwms_log_message_types 
          where message_type_id = l_msgtype;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', l_type, 'log message type');
      end;       

      insert
        into at_log_message
      values (
                l_msg_id,
                l_office_code, 
                l_now_ts,
                l_msg_level, 
                p_component, 
                p_instance, 
                p_host, 
                p_port, 
                p_reported, 
                l_typeid, 
                l_message
             );   

      -------------------------------------   
      -- ... then the message properties --
      -------------------------------------   
      l_nodes := l_document.extract('/cwms_message/property');
      if l_nodes is not null then
         i := 0;
         loop
            i := i + 1;
            l_node := l_nodes.extract('*['||i||']');
            exit when l_node is null;
            l_name  := l_node.extract('*/@name').getstringval();
            l_type  := l_node.extract('*/@type').getstringval();
            if l_type = 'boolean' or l_type = 'String' then
               l_number := null;
               l_node   := l_node.extract('*/node()');
               if l_node is null then
                  cwms_err.raise(
                     'INVALID_ITEM', 
                     'NULL', 
                     'CWMS message property value (type='
                     || l_msgtype
                     || ', property='
                     || l_name
                     || ')');
               end if;
               l_text := cwms_util.strip(l_node.getstringval());
            else
               l_node := l_node.extract('*/node()');
               if l_node is null then
                  l_number := null;
               else
                  l_number := l_node.getnumberval();
               end if;
               l_text   := null;
            end if;

            begin
               select prop_type_code 
                 into l_prop_type 
                 from cwms_log_message_prop_types 
                where prop_type_id = l_type;
            exception
               when no_data_found then
                  cwms_err.raise('INVALID_ITEM', l_type, 'log message property type');
            end;
                   
            insert 
              into at_log_message_properties 
            values (
                     l_msg_id, 
                     l_name, 
                     l_prop_type, 
                     l_number, 
                     l_text
                   );
         end loop;
      end if;
   end if;
   commit;
   
   if l_publish then
      -------------------------
      -- publish the message --
      -------------------------
      l_extra := l_extra
                 || lf
                 || '  <property name="component" type="String">'
                 || p_component
                 || '</property>'
                 || lf;
      if p_instance is not null then
         l_extra := l_extra
                    || '  <property name="instance" type="String">'
                    || p_instance
                    || '</property>'
                    || lf;
      end if;
      if p_host is not null then
         l_extra := l_extra
                    || '  <property name="host" type="String">'
                    || p_host
                    || '</property>'
                    || lf;
      end if;
      if p_port is not null then
         l_extra := l_extra
                    || '  <property name="port" type="int">'
                    || p_port
                    || '</property>'
                    || lf;
      end if;
      if p_reported is not null then
         l_extra := l_extra
                    || '  <property name="reported" type="long">'
                    || cwms_util.to_millis(p_reported)
                    || '</property>'
                    || lf;
      end if;
      l_extra := l_extra
                 || '  <property name="log_timestamp" type="String">'
                 || to_char(l_now_ts)
                 || '</property>'
                 || lf;

      l_pos := instr(p_message, '>');
      return publish_status_message(substr(p_message, 1, l_pos) || l_extra || substr(p_message, l_pos+1));
   else
      return 0;
   end if;
                                          
end log_message;   

-------------------------------------------------------------------------------
-- PROCEDURE LOG_DB_MESSAGE(...)
--
procedure log_db_message(
   p_procedure in varchar2,
   p_msg_level in integer,
   p_message   in varchar2)
is
   i  integer;
   lf constant varchar2(1) := chr(10);
   l_msg_level integer := nvl(p_msg_level, msg_level_normal);
begin
   i := log_message(
      'CWMSDB',
      null,
      null,
      null,
      systimestamp,
      '<cwms_message type="Status">' || lf
      || '  <property name="procedure" type="String">' || p_procedure || '</property>' || lf
      || '  <text>' || lf
      || '  ' || p_message || lf
      || '  </text>' || lf
      || '</cwms_message>',
      l_msg_level,
      false);
      
end log_db_message;    
-------------------------------------------------------------------------------
-- FUNCTION LOG_MESSAGE_SERVER_MESSAGE(...)
--
function log_message_server_message(
   p_message in varchar2)
   return integer
is
   l_message     varchar2(4000) := p_message;
   l_component   varchar2(64);
   l_instance    varchar2(64);
   l_host        varchar2(256);
   l_port        integer;
   l_report_time timestamp;
   l_msg_type    varchar2(64);
   l_msg_text    varchar2(32767);
   l_prop_type   varchar2(8);
   l_properties  cwms_util.str_tab_t;
   l_parts       cwms_util.str_tab_t;
   i             pls_integer;
   lf            constant varchar2(1) := chr(10);
   l_msg_level   integer;
begin
   l_msg_text := '<cwms_message type="$msgtype">' || lf;
   -----------------------------------------------------------------------
   -- reverse the character replacement used in message server messages --
   -----------------------------------------------------------------------
   l_message := replace(l_message, '^LF', lf);
   l_message := replace(l_message, '^HT', chr(9));
   l_message := replace(l_message, '^BS', chr(8));
   l_message := replace(l_message, '^CR', chr(13));
   --------------------------------------------------------------
   -- replace any illegal characters with character references --
   --------------------------------------------------------------
   l_message := utl_i18n.escape_reference(l_message, 'us7ascii');
   -------------------------------------------------
   -- split the message text into key=value pairs --
   -------------------------------------------------
   l_properties := cwms_util.split_text(cwms_util.strip(p_message), ';');
   if l_properties.count = 1 then
      ------------------------
      -- heartbeat message? --
      ------------------------
      l_message := cwms_util.strip(p_message);
      if instr(l_message, 'GMT >> Heartbeat') != 20 then
         cwms_err.raise('ERROR', 'Unrecognized message server message: ' || l_message); 
      end if;
      --------------------------
      -- set the message type --
      --------------------------
      l_msg_type  := 'MissedHeartBeat';
      l_msg_text  := replace(l_msg_text, '$msgtype', l_msg_type);
      l_msg_level := msg_level_normal;
      ---------------------------------------------
      -- get component, host and port from value --
      ---------------------------------------------
      i := instr(l_message, 'overdue for ') + 12;
      l_parts := cwms_util.split_text(cwms_util.split_text(substr(l_message, i))(1), '@', 1);
      l_component := l_parts(1);
      if l_parts.count > 1 then
         l_parts := cwms_util.split_text(cwms_util.strip(l_parts(2)), ':', 1);
         l_host := l_parts(1);
         if l_parts.count > 1 then
            begin
               l_port := cast(l_parts(2) as integer);
            exception
               when others then
                  l_host := cwms_util.join_text(l_parts, ':');
            end;
         end if;
      end if;
      ------------------------------------------------------------------
      -- crack the instance (data stream) from ProcessSHEFIT messages --
      ------------------------------------------------------------------
      if substr(l_component, 1, 13) = 'ProcessSHEFIT' then
         l_instance  := substr(l_component, 14);
         l_component := 'ProcessSHEFIT';
      end if;
      -----------------------
      -- get reported time --
      -----------------------
      l_report_time := to_timestamp(substr(l_message, 1, 18), 'ddmonyyyy hh24:mi:ss');
      --------------------------------
      -- construct the message text --
      --------------------------------
      l_msg_text := l_msg_text || '  <text>'  || lf || '    ';
      l_parts := cwms_util.split_text(substr(l_message, 27));
      l_parts.delete(6,7);
      for i in l_parts.first..l_parts.last loop
         if l_parts.exists(i) then 
            l_msg_text := l_msg_text || l_parts(i) || ' '; 
         end if;
      end loop;
      l_msg_text := l_msg_text || lf || '  </text>'  || lf;
   else
      --------------------------------------------------
      -- normal message loop over each key/value pair --
      --------------------------------------------------
      for i in 1..l_properties.count loop
         ----------------------------
         -- split pair on '=' char --
         ----------------------------
         l_parts := cwms_util.split_text(cwms_util.strip(l_properties(i)), '=', 1);
         if l_parts.count > 1 then
            l_parts(1) := cwms_util.strip(l_parts(1));
            l_parts(2) := cwms_util.strip(l_parts(2));
            case l_parts(1)
               when 'From' then
                  ---------------------------------------------
                  -- get component, host and port from value --
                  ---------------------------------------------
                  l_parts := cwms_util.split_text(l_parts(2), '@', 1);
                  l_component := cwms_util.strip(l_parts(1));
                  if l_parts.count > 1 then
                     l_parts := cwms_util.split_text(cwms_util.strip(l_parts(2)), ':', 1);
                     l_host := l_parts(1);
                     if l_parts.count > 1 then
                        begin
                           l_port := cast(l_parts(2) as integer);
                        exception
                           when others then
                              l_host := cwms_util.join_text(l_parts, ':');
                        end;
                     end if;
                  end if;
                  ------------------------------------------------------------------
                  -- crack the instance (data stream) from ProcessSHEFIT messages --
                  ------------------------------------------------------------------
                  if substr(l_component, 1, 13) = 'ProcessSHEFIT' then
                     l_instance  := substr(l_component, 14);
                     l_component := 'ProcessSHEFIT';
                  end if;
               when 'UTCTime' then
                  ----------------------------------
                  -- get reported time from value --
                  ----------------------------------
                  l_report_time := to_timestamp(replace(l_parts(2), ' GMT', ''), 'ddmonyyyy hh24:mi:ss');
               when 'MessageType' then
                  ---------------------------------
                  -- get message type from value --
                  ---------------------------------
                  l_msg_type := l_parts(2);
                  declare
                     l_typeid integer;
                  begin
                     select message_type_code 
                       into l_typeid 
                       from cwms_log_message_types 
                      where message_type_id = l_parts(2);
                     l_msg_text := replace(l_msg_text, '$msgtype', l_msg_type);
                  exception
                     when no_data_found then
                        l_msg_type := 'Status';
                        l_msg_text := replace(l_msg_text, '$msgtype', l_msg_type);
                        l_msg_text := l_msg_text 
                                   || '  <property name="subtype" type="String">'
                                   || l_parts(2)
                                   || '</property>' || lf;
                  end;
                  l_msg_level := case l_msg_type
                     when 'Exception Thrown'      then msg_level_basic
                     when 'Fatal Error'           then msg_level_basic
                     when 'Initialization Error'  then msg_level_basic
                     when 'Initiated'             then msg_level_detailed
                     when 'Load Library Error'    then msg_level_basic
                     when 'Runtime Exec Error'    then msg_level_basic
                     when 'State'                 then msg_level_detailed
                     when 'StatusIntervalMinutes' then msg_level_detailed
                     when 'Terminated'            then msg_level_basic
                     else                              msg_level_normal
                  end;       
               when 'Message' then
                  ---------------------------------
                  -- get message body from value --
                  ---------------------------------
                  if l_msg_type = 'State' and substr(l_parts(2), 1, 7) = 'Server=' then
                     l_msg_text := l_msg_text 
                                || '  <property name="state" type="String">'
                                || substr(l_parts(2), 8)
                                || '</property>' || lf;
                  else
                     l_msg_text := l_msg_text 
                                 || '  <text>'  || lf 
                                 || l_parts(2)  || lf 
                                 || '  </text>' || lf;
                  end if;
               else
                  ------------------------------------
                  -- treat pair as a named property --
                  ------------------------------------
                  declare
                     num number;
                  begin
                     num := cast(l_parts(2) as number);
                     if num = cast(l_parts(2) as integer) then
                        if num < -2147483648 or num > 2147483647 then
                           l_prop_type := 'long';
                        else
                           l_prop_type := 'int';
                        end if;
                     else
                        begin
                           if cast(l_parts(2) as binary_float) = cast(l_parts(2) as binary_double) then
                              l_prop_type := 'float';
                           else
                              l_prop_type := 'double';
                           end if;
                        exception
                           when others then
                              l_prop_type := 'double';
                        end;
                     end if;
                  exception
                     when others then 
                        case lower(l_parts(2))
                           when 'true'  then l_prop_type := 'boolean';
                           when 't'     then l_prop_type := 'boolean';
                           when 'yes'   then l_prop_type := 'boolean';
                           when 'y'     then l_prop_type := 'boolean';
                           when 'on'    then l_prop_type := 'boolean';
                           when 'false' then l_prop_type := 'boolean';
                           when 'f'     then l_prop_type := 'boolean';
                           when 'no'    then l_prop_type := 'boolean';
                           when 'n'     then l_prop_type := 'boolean';
                           when 'off'   then l_prop_type := 'boolean';
                           else              l_prop_type := 'String';
                        end case;

                  end;
                  l_msg_text := l_msg_text 
                             || '  <property name="'
                             || l_parts(1)
                             || '" type="' 
                             || l_prop_type || '">'
                             || l_parts(2)
                             || '</property>' || lf;
            end case;
         end if;
      end loop;
   end if;
   l_msg_text := l_msg_text || '</cwms_message>';
   return log_message(l_component, l_instance, l_host, l_port, l_report_time, l_msg_text, l_msg_level);
end log_message_server_message;   


-------------------------------------------------------------------------------
-- FUNCTION LOG_MESSAGE_SERVER_MESSAGE(...)
--
function log_message_server_message(
   p_message in out nocopy clob)
   return integer
is
   l_message varchar2(32767);
   l_length  integer;
begin
   l_length := dbms_lob.getlength(p_message);
   if l_length > 32767 then
      cwms_err.raise('ERROR', 'CLOB length exceeds maximum string length of 32767');
   end if;
   dbms_lob.open(p_message, dbms_lob.lob_readonly);
   dbms_lob.read(p_message, l_length, 1, l_message);
   dbms_lob.close(p_message);
   return log_message_server_message(l_message);
end log_message_server_message;

end cwms_msg;
/
show errors;
