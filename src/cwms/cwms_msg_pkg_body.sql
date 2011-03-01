SET define on
@@defines.sql
create or replace package body cwms_msg
as

-------------------------------------------------------------------------------
-- FUNCTION GET_MSG_ID(...)
--
function get_msg_id (p_millis in integer default null) return varchar2
is
   pragma autonomous_transaction;
   l_millis  integer := p_millis;
   l_seq     integer;
   l_handle  varchar2(128);
   l_result  integer;
begin
   -------------------------
   -- syncronize the code --
   -------------------------
   dbms_lock.allocate_unique('CWMS_MSG.GET_MSG_ID', l_handle);
   l_result := dbms_lock.request(
      lockhandle        => l_handle,
      lockmode          => dbms_lock.x_mode,
      timeout           => 2,
      release_on_commit => true);
   if l_result != 0 then
      cwms_err.raise(
        'ERROR',
        'Cannot get message id lock, error = '
        ||case l_result
             when 1 then 'timeout'
             when 2 then 'deadlock'
             when 3 then 'parameter error'
             when 4 then 'already owned by requestor'
             when 5 then 'illegal handle'
             else        'unknown error ('||l_result||')'
          end);
   end if;
   ------------------------
   -- perform the action --
   ------------------------      
   if l_millis is null then 
      l_millis := cwms_util.current_millis; 
   end if;
   if l_millis = last_millis then
      l_seq := last_seq + 1;
   else
      l_seq := 0;
   end if;
   last_millis := l_millis;
   last_seq    := l_seq;
   ---------------------------------
   -- release the lock and return --
   ---------------------------------
   commit;
   return to_char(l_millis)||'_'||to_char(l_seq, '000');
end;

-------------------------------------------------------------------------------
-- FUNCTION GET_QUEUE_PREFIX(...)
--
function get_queue_prefix return varchar2
is
   l_db_office_id   varchar2(16);
begin
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
               and owner = '&cwms_schema'
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
      l_queuename := '&cwms_schema'||'.'|| l_queuename;
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
   l_expiration_time    constant binary_integer := 300; -- 5 minutes
begin
   l_queuename := get_queue_name(p_msg_queue);
   if l_queuename is null then
      cwms_err.raise('INVALID_ITEM', p_msg_queue, 'message queue name');
   end if;
   -------------------------
   -- enqueue the message --
   -------------------------
   l_message_properties.expiration := l_expiration_time; 
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
   l_message_id varchar2(32);
begin
   return log_long_message(
      l_message_id,
      p_component,
      p_instance,
      p_host,
      p_port,
      p_reported,
      p_message,
      null,
      p_msg_level,
      p_publish);
end log_message;   

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
   p_publish    in  boolean default true)
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
   l_username    varchar2(30);
   l_osuser      varchar2(30);
   l_process     varchar2(24);
   l_program     varchar2(64);
   l_machine     varchar2(64);
begin
   if l_msg_level > msg_level_none then
      -----------------------------------------
      -- insert message data into the tables --
      -----------------------------------------
      l_now         := cwms_util.current_millis;
      l_now_ts      := cwms_util.to_timestamp(l_now);
      l_msg_id      := get_msg_id(l_now);
      l_office_code := cwms_util.user_office_code;
      l_document    := xmltype(p_short_msg);
      l_msgtype     := l_document.extract('/cwms_message/@type').getstringval();
      l_node        := l_document.extract('/cwms_message/text');
      if l_node is not null then
         l_message := cwms_util.strip(l_node.extract('*/node()').getstringval());
         l_message := utl_i18n.unescape_reference(l_message);
      end if;

      --------------------------------
      -- first the short message... --
      --------------------------------
      begin
         select message_type_code 
           into l_typeid 
           from cwms_log_message_types 
          where message_type_id = l_msgtype;
      exception
         when no_data_found then
            cwms_err.raise('INVALID_ITEM', l_type, 'log message type');
      end;       

      select username, 
             osuser, 
             process, 
             program, 
             machine
        into l_username,
             l_osuser,
             l_process,
             l_program,
             l_machine             
        from v$session 
       where audsid = userenv('sessionid');
       
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
                l_username,
                l_osuser,
                l_process,
                l_program,
                l_machine,
                l_typeid, 
                l_message
             );   

      -------------------------------   
      -- ... next the long message --
      -------------------------------
      if p_long_msg is not null then
         l_number := cwms_text.store_text(
            p_long_msg,
            '/message_id/'||l_msg_id,
            to_char(l_now_ts));
      end if;   
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
   p_message_id := l_msg_id;
   commit;
   
   if l_publish then
      -------------------------
      -- publish the message --
      -------------------------
      l_extra := l_extra
                 || lf
                 || '  <property name="id" type="String">'
                 || l_msg_id
                 || '</property>'
                 || lf;
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

      l_pos := instr(p_short_msg, '>');
      return publish_status_message(substr(p_short_msg, 1, l_pos) || l_extra || substr(p_short_msg, l_pos+1));
   else
      return 0;
   end if;
                                          
end log_long_message;

-------------------------------------------------------------------------------
-- FUNCTION GET_MESSAGE_CLOB(...)
--
function get_message_clob(
   p_message_id in varchar2)
   return clob
is
   l_clob clob := null;
begin
   return cwms_text.retrieve_text('/message_id/'||p_message_id);
end get_message_clob;   

-------------------------------------------------------------------------------
-- PROCEDURE LOG_DB_MESSAGE(...)
--
procedure log_db_message(
   p_procedure in varchar2,
   p_msg_level in integer,
   p_message   in varchar2)
is
   l_message   varchar2(4000) := p_message;
   i           integer;
   lf constant varchar2(1) := chr(10);
   l_msg_level integer := nvl(p_msg_level, msg_level_normal);
begin
   l_message := utl_i18n.escape_reference(l_message, 'us7ascii');
   i := log_message(
      'CWMSDB',
      null,
      null,
      null,
      systimestamp at time zone 'UTC',
      '<cwms_message type="Status">' || lf
      || '  <property name="procedure" type="String">' || p_procedure || '</property>' || lf
      || '  <text>' || lf
      || '  ' || l_message || lf
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
   l_properties  str_tab_t;
   l_parts       str_tab_t;
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

-------------------------------------------------------------------------------
-- FUNCTION PARSE_LOG_MSG_PROP_TAB(...)
--
function parse_log_msg_prop_tab (
   p_tab in log_message_properties_tab_t)
   return varchar2
is
   l_text varchar2(4000);
begin
   for i in 1..p_tab.count loop
      if i > 1 then
         l_text := l_text || '; ' || chr(10);
      end if;
      if p_tab(i).prop_type = 5 then
         l_text := l_text || p_tab(i).prop_name || ' = ' || p_tab(i).prop_value || ' (' || to_char(cwms_util.to_timestamp(p_tab(i).prop_value), 'yyyy/mm/dd hh24:mi:ss') || ')';
      else
         l_text := l_text || p_tab(i).prop_name || ' = ' || p_tab(i).prop_value || p_tab(i).prop_text;
      end if;
   end loop;
   return l_text || '; ';
end parse_log_msg_prop_tab;         

-------------------------------------------------------------------------------
-- PROCEDURE TRIM_LOG
--
-- This procedure deletes log entries older than specified by the property
-- CWMSDB/logging.entry.max_age and deletes any remaining oldest entries
-- to keep the table down to the maximum number specified in CWMSDB/
-- logging.table.max_entries
--
procedure trim_log
is
   type refcur is ref cursor;
   type rec_t  is record (msg_id at_log_message.msg_id%type);
   l_cur               refcur;
   l_rec               rec_t;
   l_property_value    varchar2(256);
   l_property_comment  varchar2(256);
   l_max_age_in_days   integer := -1;
   l_max_table_entries integer := -1;
   l_entry_count       integer;
   l_oldest_timestamp  timestamp;
   l_now               timestamp := systimestamp;
   l_oldest_in_days    integer;
   l_db_office_id      varchar2(16) := cwms_util.get_db_office_id; 
   l_interval          interval day (5) to second;
   l_sql_text          varchar2(4000) := 
      'select msg_id from (
         select msg_id, num, row_number() over (order by num desc) rn from (
            select t1.msg_id, count(t2.msg_id) num 
            from at_log_message t1, at_log_message t2
            where t2.msg_id >= t1.msg_id
            group by t1.msg_id)
         where num <= :max_entries
         order by num)
      where rn = 1';
begin
   log_db_message(
      'CWMS_MSG.TRIM_LOG', 
      msg_level_basic, 
      'Beginning trimming of log entries');
   select count(*) into l_entry_count from at_log_message;
   select min(log_timestamp_utc) into l_oldest_timestamp from at_log_message;
   l_oldest_in_days := extract(day from (l_now - l_oldest_timestamp) day to second);
   log_db_message(
      'CWMS_MSG.TRIM_LOG', 
      msg_level_verbose, 
      'Log table has ' || l_entry_count || ' entries');
   log_db_message(
      'CWMS_MSG.TRIM_LOG', 
      msg_level_verbose, 
      'Oldest log entry is ' || l_oldest_timestamp || ' (' || l_oldest_in_days || ' days)');
   --------------------------------------------------------------------------------
   -- set l_max_table_entries from the CWMSDB/logging.table.max_entries property --
   --------------------------------------------------------------------------------
   cwms_properties.get_property(
      l_property_value,
      l_property_comment,
      'CWMSDB',
      'logging.table.max_entries',
      null,
      l_db_office_id);
   if l_property_value is null then
      log_db_message(
         'CWMS_MSG.TRIM_LOG', 
         msg_level_detailed, 
         'Property CWMSDB/logging.table.max_entries is not set for user ' 
         || l_db_office_id
         || ', table will not be trimmed by entry count');
   else
      begin
         l_max_table_entries := to_number(l_property_value);
         log_db_message(
            'CWMS_MSG.TRIM_LOG', 
            msg_level_verbose,
            l_db_office_id
            || '/CWMSDB/logging.table.max_entries =  ' 
            || l_max_table_entries);
      exception
         when others then
            log_db_message(
               'CWMS_MSG.TRIM_LOG', 
               msg_level_basic,
               l_db_office_id
               || '/CWMSDB/logging.table.max_entries is not an integer value: ' 
               || l_property_value
               || ', table will not be trimmed by entry count');
      end;
   end if;
   --------------------------------------------------------------------------
   -- set l_max_age_in_days from the CWMSDB/logging.entry.max_age property --
   --------------------------------------------------------------------------
   cwms_properties.get_property(
      l_property_value,
      l_property_comment,
      'CWMSDB',
      'logging.entry.max_age',
      null,
      l_db_office_id);
   if l_property_value is null then
      log_db_message(
         'CWMS_MSG.TRIM_LOG', 
         msg_level_detailed, 
         'Property CWMSDB/logging.entry.max_age is not set for user ' 
         || l_db_office_id
         || ', table will not be trimmed by entry age');
   else
      begin
         l_max_age_in_days := to_number(l_property_value);
         log_db_message(
            'CWMS_MSG.TRIM_LOG', 
            msg_level_verbose,
            l_db_office_id
            || '/CWMSDB/logging.entry.max_age =  ' 
            || l_max_age_in_days);
         l_interval := numtodsinterval(l_max_age_in_days, 'day');
      exception
         when others then
            log_db_message(
               'CWMS_MSG.TRIM_LOG', 
               msg_level_basic,
               l_db_office_id
               || '/CWMSDB/logging.entry.max_age is not an integer value: ' 
               || l_property_value
               || ', table will not be trimmed by entry age');
      end;
   end if;
   ---------------------------
   -- trim the table by age --
   ---------------------------
   if l_max_age_in_days > 0 then
      if l_oldest_in_days > l_max_age_in_days then
         log_db_message(
            'CWMS_MSG.TRIM_LOG', 
            msg_level_detailed,
            'Trimming table by entry age');
         delete from at_log_message_properties
               where msg_id in (select msg_id 
                                  from at_log_message
                                 where log_timestamp_utc < l_now - l_interval);
         delete from at_log_message
               where log_timestamp_utc < l_now - l_interval;
         select count(*) into l_entry_count from at_log_message;
         log_db_message(
            'CWMS_MSG.TRIM_LOG', 
            msg_level_verbose, 
            'Log table now has ' || l_entry_count || ' entries');
      end if;
   end if;
   -----------------------------------
   -- trim the table by entry count --
   -----------------------------------
   if l_max_table_entries > 0 then
      if l_entry_count > l_max_table_entries then
         log_db_message(
            'CWMS_MSG.TRIM_LOG', 
            msg_level_detailed,
            'Trimming table by entry count');
         open l_cur for l_sql_text using l_max_table_entries;
         fetch l_cur into l_rec;
         close l_cur;
         delete from at_log_message_properties
               where msg_id in (select msg_id from at_log_message
                                      where msg_id < l_rec.msg_id); 
         delete from at_log_message
               where msg_id < l_rec.msg_id;
         select count(*) into l_entry_count from at_log_message;
         log_db_message(
            'CWMS_MSG.TRIM_LOG', 
            msg_level_verbose, 
            'Log table now has ' || l_entry_count || ' entries');
      end if;
   end if;
   log_db_message(
      'CWMS_MSG.TRIM_LOG', 
      msg_level_basic, 
      'Ending trimming of log entries');
end trim_log;
   
--------------------------------------------------------------------------------
-- procedure start_trim_log_job
--
procedure start_trim_log_job
is
   l_count        binary_integer;
   l_user_id      varchar2(30);
   l_job_id       varchar2(30)  := 'TRIM_LOG_JOB';
   l_run_interval varchar2(8);
   l_comment      varchar2(256);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id and owner = l_user_id;

      return l_count;
   end;
begin
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   l_user_id := cwms_util.get_user_id;

   if l_user_id != '&cwms_schema'
   then
      raise_application_error (-20999,
                                  'Must be &cwms_schema user to start job '
                               || l_job_id,
                               true
                              );
   end if;

   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0
   then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0
      then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         cwms_properties.get_property(
				l_run_interval, 
				l_comment, 
				'CWMSDB', 
				'logging.auto_trim.interval', 
				'120', 
				'CWMS');
         dbms_scheduler.create_job
            (job_name             => l_job_id,
             job_type             => 'stored_procedure',
             job_action           => 'cwms_msg.trim_log',
             start_date           => null,
             repeat_interval      => 'freq=minutely; interval=' || l_run_interval,
             end_date             => null,
             job_class            => 'default_job_class',
             enabled              => true,
             auto_drop            => false,
             comments             => 'Trims at_log_message to specified max entries and max age.'
            );

         if job_count = 1
         then
            dbms_output.put_line
                           (   'Job '
                            || l_job_id
                            || ' successfully scheduled to execute every '
                            || l_run_interval
                            || ' minutes.'
                           );
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others
         then
            cwms_err.raise ('ITEM_NOT_CREATED',
                            'job',
                            l_job_id || ':' || sqlerrm
                           );
      end;
   end if;
end start_trim_log_job;

--------------------------------------------------------------------------------
-- procedure purge_queues
--
procedure purge_queues
is
   l_subscriber_name varchar2(31);
   l_last_dequeue    timestamp;
   l_subscriber      sys.aq$_agent := sys.aq$_agent(null, null, null);
   l_cursor          sys_refcursor;
   l_purge_options   dbms_aqadm.aq$_purge_options_t;
   l_expired_count   integer;
   l_max_purge_count integer := 50000;
   l_sql             varchar2(256);
   l_purged          boolean := false;
begin
   l_purge_options.block := true;
   for rec in (
      select object_name 
        from dba_objects 
       where object_type = 'QUEUE' 
         and owner = '&cwms_schema' 
         and object_name not like 'AQ$%')
   loop
      ---------------------------------------
      -- first kill any zombie subscribers --
      ---------------------------------------
      open l_cursor for
         'select consumer_name as subscriber, 
                 max(deq_timestamp) as last_dequeue_time 
            from AQ$'||rec.object_name||'_TABLE 
           where msg_state != ''READY'' 
        group by consumer_name';
      loop
         fetch l_cursor into l_subscriber_name, l_last_dequeue;
         exit when l_cursor%notfound;
         if l_last_dequeue is null then
            ------------
            -- zombie --
            ------------
            cwms_msg.log_db_message(
               'purge_queues', 
               cwms_msg.msg_level_normal, 
               'Killing zombie subsciber '
                  || l_subscriber_name
                  || ' for queue '
                  || rec.object_name);
            l_subscriber.name := l_subscriber_name;
            begin
               execute immediate
                  'select address,
                          protocol
                     into :address,
                          :protocol
                     from AQ$'||rec.object_name||'_TABLE_S
                    where queue = :queue
                      and name = :name'
                     into l_subscriber.address,
                          l_subscriber.protocol
                    using rec.object_name,
                          l_subscriber.name;         
               dbms_aqadm.remove_subscriber(
                  rec.object_name,
                  l_subscriber);
            exception
               when others then
                  cwms_msg.log_db_message(
                     'purge_queues', 
                     cwms_msg.msg_level_normal, 
                     'Error killing zombie subsciber '
                        || l_subscriber_name
                        || ' for queue '
                        || rec.object_name
                        || ': '
                        || sqlcode
                        || ' - '
                        || sqlerrm);
            end;                                              
         end if;
      end loop;
      close l_cursor;      
      ----------------------------------------------------------------
      -- next purge queues of any expired or undeliverable messages --
      ----------------------------------------------------------------
      l_sql := 'select count(*) 
                  from AQ$'
                     || rec.object_name
                     || '_TABLE 
                 where msg_state in (''UNDELIVERABLE'',''EXPIRED'')';
      execute immediate l_sql into l_expired_count;
      if l_expired_count > l_max_purge_count then
         cwms_msg.log_db_message(
            'purge_queues', 
            cwms_msg.msg_level_normal, 
            'Purging '
               || l_max_purge_count
               || ' of '
               || l_expired_count
               || ' expired messages from queue: '
               || rec.object_name);
      elsif l_expired_count > 0 then
         cwms_msg.log_db_message(
            'purge_queues', 
            cwms_msg.msg_level_normal, 
            'Purging '
               || l_expired_count
               || ' expired messages from queue: '
               || rec.object_name);
      end if;
      if l_expired_count > 0 then
         l_purged := true;         
         dbms_aqadm.purge_queue_table(
            rec.object_name||'_TABLE',
            'MSG_STATE IN (''UNDELIVERABLE'',''EXPIRED'') AND ROWNUM <= '
               || l_max_purge_count,
            l_purge_options);
      end if;                     
   end loop;
   if l_purged then 
      cwms_msg.log_db_message(
         'purge_queues', 
         cwms_msg.msg_level_normal, 
         'Done purging expired messages from queues');
   end if;         
end purge_queues;

--------------------------------------------------------------------------------
-- procedure start_purge_queues_job
--
procedure start_purge_queues_job
is
   l_count        binary_integer;
   l_user_id      varchar2(30);
   l_job_id       varchar2(30)  := 'PURGE_QUEUES_JOB';
   l_run_interval varchar2(8);
   l_comment      varchar2(256);

   function job_count
      return binary_integer
   is
   begin
      select count (*)
        into l_count
        from sys.dba_scheduler_jobs
       where job_name = l_job_id and owner = l_user_id;

      return l_count;
   end;
begin
   --------------------------------------
   -- make sure we're the correct user --
   --------------------------------------
   l_user_id := cwms_util.get_user_id;

   if l_user_id != '&cwms_schema'
   then
      raise_application_error (-20999,
                                  'Must be &cwms_schema user to start job '
                               || l_job_id,
                               true
                              );
   end if;

   -------------------------------------------
   -- drop the job if it is already running --
   -------------------------------------------
   if job_count > 0
   then
      dbms_output.put ('Dropping existing job ' || l_job_id || '...');
      dbms_scheduler.drop_job (l_job_id);

      --------------------------------
      -- verify that it was dropped --
      --------------------------------
      if job_count = 0
      then
         dbms_output.put_line ('done.');
      else
         dbms_output.put_line ('failed.');
      end if;
   end if;

   if job_count = 0
   then
      begin
         ---------------------
         -- restart the job --
         ---------------------
         cwms_properties.get_property(
            l_run_interval,
            l_comment,
            'CWMSDB',
            'queues.all.purge_interval',
            '5',
            'CWMS');
         dbms_scheduler.create_job
            (job_name             => l_job_id,
             job_type             => 'stored_procedure',
             job_action           => 'cwms_msg.purge_queues',
             start_date           => null,
             repeat_interval      => 'freq=minutely; interval=' || l_run_interval,
             end_date             => null,
             job_class            => 'default_job_class',
             enabled              => true,
             auto_drop            => false,
             comments             => 'Purges expired and undeliverable messages from queues.'
            );

         if job_count = 1
         then
            dbms_output.put_line
                           (   'Job '
                            || l_job_id
                            || ' successfully scheduled to execute every '
                            || l_run_interval
                            || ' minutes.'
                           );
         else
            cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
         end if;
      exception
         when others
         then
            cwms_err.raise ('ITEM_NOT_CREATED',
                            'job',
                            l_job_id || ':' || sqlerrm
                           );
      end;
   end if;
end start_purge_queues_job;

-- function get_registration_info
--
function get_registration_info(
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2 default null)
   return sys.aq$_reg_info_list
is
   l_reg_info        sys.aq$_reg_info_list := sys.aq$_reg_info_list();
   l_queue_name      varchar2(61);
   l_subscriber_name varchar2(30) := nvl(p_subscriber_name, dbms_random.string('l', 16));
   l_schema_name     varchar2(30);
   l_office_id       varchar2(16);
   l_parts           str_tab_t;
begin
   -----------------------------------------------------------------------------
   -- get the schema and office id, either from the queue name or environment --
   -----------------------------------------------------------------------------
   l_queue_name  := p_queue_name;
   l_parts := cwms_util.split_text(p_queue_name, '.', 1);
   if l_parts.count = 1 then
      l_schema_name := sys_context('userenv', 'current_schema');
   else
      l_schema_name := l_parts(1);
      l_queue_name  := l_parts(2);
   end if;
   l_parts := cwms_util.split_text(l_queue_name, '_', 1);
   if l_parts.count = 1 then
      l_office_id := cwms_util.user_office_id;
   else
      begin
         select office_id
           into l_office_id
           from cwms_office
          where office_id = upper(l_parts(1));
         l_queue_name := l_parts(2);          
      exception
         when no_data_found then
            l_office_id := cwms_util.user_office_id;
      end;
   end if;
   ----------------------------------------------------------------------
   -- (re)construct the queue name, including the schema and office id --
   ----------------------------------------------------------------------
   l_queue_name := l_schema_name
                   ||'.'||l_office_id
                   ||'_'||l_queue_name;
   l_reg_info.extend();
   l_reg_info(1) := sys.aq$_reg_info(
      name      => upper(l_queue_name||':'||l_subscriber_name),
      namespace => dbms_aq.namespace_aq,
      callback  => 'plsql://'||upper(p_procedure_name),
      context   => hextoraw('ff'));
   return l_reg_info;
end get_registration_info;

--------------------------------------------------------------------------------
-- procedure register_msg_callback
--
function register_msg_callback (
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2 default null)
   return varchar2
is
   l_reg_info        sys.aq$_reg_info_list;
   l_parts           str_tab_t;
   l_subscriber_name varchar2(30);
   l_queue_name      varchar2(61);
begin
   l_reg_info := get_registration_info(
      p_procedure_name,
      p_queue_name,
      p_subscriber_name);
   l_parts := cwms_util.split_text(l_reg_info(1).name ,':');
   l_queue_name := l_parts(1);
   l_subscriber_name := l_parts(2);
   dbms_aqadm.add_subscriber(
      queue_name => l_queue_name,
      subscriber => sys.aq$_agent(l_subscriber_name, null, null));
   dbms_aq.register(l_reg_info, l_reg_info.count);
   return l_subscriber_name;
end register_msg_callback;

--------------------------------------------------------------------------------
-- procedure unregister_msg_callback
--
procedure unregister_msg_callback (
   p_procedure_name  in varchar2,
   p_queue_name      in varchar2,
   p_subscriber_name in varchar2)
is
   l_reg_info        sys.aq$_reg_info_list;
   l_parts           str_tab_t;
   l_subscriber_name varchar2(30);
   l_queue_name      varchar2(61);
begin
   l_reg_info := get_registration_info(
      p_procedure_name,
      p_queue_name,
      p_subscriber_name);
   l_parts := cwms_util.split_text(l_reg_info(1).name ,':');
   l_queue_name := l_parts(1);
   l_subscriber_name := l_parts(2);
   dbms_aq.unregister(l_reg_info, l_reg_info.count);
   dbms_aqadm.remove_subscriber(
      queue_name => l_queue_name,
      subscriber => sys.aq$_agent(l_subscriber_name, null, null));
end unregister_msg_callback;

end cwms_msg;
/
show errors;
