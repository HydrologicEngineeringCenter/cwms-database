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
   l_millis      integer := p_millis;
   l_seq         integer;
   l_last_millis integer;
   l_last_seq    integer;
   l_msg_id      varchar2(17);
begin
   --------------------------
   -- synchronize the code --
   --------------------------
   lock table cwms_msg_id in exclusive mode wait 2;
   ------------------------
   -- perform the action --
   ------------------------
   if l_millis is null then
      l_millis := cwms_util.current_millis;
   end if;
   select last_millis, last_seq into l_last_millis, l_last_seq from cwms_msg_id;
   if l_millis = l_last_millis then
      l_seq := l_last_seq + 1;
   else
      l_seq := 0;
   end if;
   update cwms_msg_id set last_millis = l_millis, last_seq = l_seq;
   l_msg_id := replace(to_char(l_millis)||'_'||to_char(l_seq, '000'), ' ', '');
   ---------------------------------
   -- release the lock and return --
   ---------------------------------
   commit;
   return l_msg_id;
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
   p_msg_queue in varchar2,
	p_immediate in boolean default false)
   return integer
is
   l_message_properties dbms_aq.message_properties_t;
   l_enqueue_options    dbms_aq.enqueue_options_t;
   l_msgid              raw(16);
   l_queuename          varchar2(64);
   l_now                integer := cwms_util.current_millis;
   l_expiration_time    constant binary_integer := 900; -- 5 minutes
   l_java_action        varchar2(4000);
   l_queueing_paused    boolean;
   l_parts              str_tab_t;
   l_office_id          varchar2(16);
begin
   ----------------------------------------------------------
   -- finish setting up the message and clean up java side --
   ----------------------------------------------------------
   if p_immediate then
      l_enqueue_options.visibility := dbms_aq.immediate;
   else
      l_enqueue_options.visibility := dbms_aq.on_commit;
   end if;
   l_message_properties.expiration := l_expiration_time;
   p_message.set_long(p_messageid, 'millis', l_now);
   p_message.flush(p_messageid);
   p_message.clean(p_messageid);
   l_java_action := dbms_java.endsession_and_related_state;
   -------------------------------
   -- get the actual queue name --
   -------------------------------
   l_queuename := get_queue_name(p_msg_queue);
   if l_queuename is null then
      cwms_err.raise('INVALID_ITEM', p_msg_queue, 'message queue name');
   end if;
   --------------------------------------
   -- determine if enqueuing is paused --
   --------------------------------------
   l_parts := cwms_util.split_text(l_queuename, '.');
   l_office_id := upper(substr(l_parts(l_parts.count), 1, instr(l_parts(l_parts.count), '_')-1));
   l_queueing_paused := is_message_queueing_paused(l_office_id);
   if not l_queueing_paused then
      -------------------------
      -- enqueue the message --
      -------------------------
      dbms_aq.enqueue(
         l_queuename,
         l_enqueue_options,
         l_message_properties,
         p_message,
         l_msgid);
   end if;
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
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
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

   return publish_message(l_msg, l_msgid, p_msg_queue, p_immediate);

end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in varchar2,
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, p_msg_queue, p_immediate);
end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_MESSAGE(...)
--
function publish_message(
   p_properties in out nocopy clob,
   p_msg_queue  in varchar2,
	p_immediate  in boolean default false)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, p_msg_queue, p_immediate);
end publish_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_message   in out nocopy sys.aq$_jms_map_message,
   p_messageid in pls_integer,
	p_immediate in boolean default false)
   return integer
is
begin
   return publish_message(p_message, p_messageid, 'STATUS', p_immediate);
end publish_status_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in varchar2,
	p_immediate  in boolean default false)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, 'STATUS', p_immediate);
end publish_status_message;

-------------------------------------------------------------------------------
-- FUNCTION PUBLISH_STATUS_MESSAGE(...)
--
function publish_status_message(
   p_properties in out nocopy clob,
	p_immediate  in boolean default false)
   return integer
is
   l_properties xmltype := xmltype(p_properties);
begin
   return publish_message(l_properties, 'STATUS', p_immediate);
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
   p_publish   in boolean,
   p_immediate in boolean default false)
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
   p_publish    in  boolean default true,
	p_immediate  in  boolean default false) -- affects publishing only
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
   l_result      integer;
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
      l_result := publish_status_message(substr(p_short_msg, 1, l_pos) || l_extra || substr(p_short_msg, l_pos+1), p_immediate);
   else
      l_result := 0;
   end if;
   commit;
   return l_result;
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
   p_tab in log_message_props_tab_t)
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
   l_msg_id_count varchar2(32) := '0';
   l_msg_id_date  varchar2(32) := '0';
   l_count        number;
   l_max_count    number;
   l_max_days     number;
   l_office_id    varchar2(16) := cwms_util.user_office_id;
begin
   log_db_message('TRIM_LOG', msg_level_basic, 'Start trimming log entries');
   ---------------------------------------
   -- get the count and date properties --
   ---------------------------------------
   l_max_count := to_number(cwms_properties.get_property('CWMSDB','logging.table.max_entries','100000',l_office_id));
   l_max_days  := to_number(cwms_properties.get_property('CWMSDB','logging.table.max_age','120',l_office_id));
   -------------------------------------------
   -- determine the msg_id cutoff for count --
   -------------------------------------------
   select count(*)
     into l_count
     from at_log_message;
   log_db_message('TRIM_LOG', msg_level_detailed, 'AT_LOG_MESSAGE has '||l_count||' records.');
   if l_count > l_max_count then
      select msg_id
        into l_msg_id_count
        from ( select msg_id,
                      rownum as rn
                 from at_log_message
             order by msg_id desc
             )
       where rn = trunc(l_max_count);
   end if;
   ------------------------------------------
   -- determine the msg_id cutoff for date --
   ------------------------------------------
   l_msg_id_date := cwms_util.to_millis(systimestamp at time zone 'UTC' - numtodsinterval(l_max_days, 'DAY'))||'_000';
   -------------------------
   -- trim the log tables --
   -------------------------
   delete
     from at_log_message_properties
    where msg_id < greatest(l_msg_id_count, l_msg_id_date)
returning count(*)
     into l_count;
   log_db_message('TRIM_LOG', msg_level_detailed, 'Deleted '||l_count||' records from AT_LOG_MESSAGE_PROPERTIES');

   delete
     from at_log_message
    where msg_id < greatest(l_msg_id_count, l_msg_id_date)
returning count(*)
     into l_count;
     
   commit;
        
   log_db_message('TRIM_LOG', msg_level_detailed, 'Deleted '||l_count||' records from AT_LOG_MESSAGE');

   log_db_message('TRIM_LOG', msg_level_basic, 'Done trimming log entries');
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
procedure create_queues(
   p_office_id in varchar2)
is
   l_office_id   varchar2(16);
   l_queue_names str_tab_t := str_tab_t('STATUS', 'REALTIME_OPS', 'TS_STORED');
   l_queue_name  varchar2(30);
   l_table_name  varchar2(30);
begin
   -----------------------------------------
   -- make sure we have a valid office id --
   -----------------------------------------
   cwms_util.check_input(p_office_id);
   select office_id
     into l_office_id 
     from cwms_office
    where office_id = upper(p_office_id);
   ----------------------------------------    
   -- eliminate and re-create the queues --
   ----------------------------------------    
   for i in 1..l_queue_names.count loop
      l_queue_name := l_office_id || '_' || l_queue_names(i);
      l_table_name := l_queue_name || '_TABLE'; 
         begin
            sys.dbms_aqadm.stop_queue(queue_name => l_queue_name);
            dbms_output.put_line('Stopped queue '||l_queue_name);
         exception
            when others then dbms_output.put_line('Could not stop queue '||l_queue_name);   
         end;
         begin
            sys.dbms_aqadm.drop_queue(queue_name => l_queue_name);
            dbms_output.put_line('Dropped queue '||l_queue_name);
         exception
            when others then dbms_output.put_line('Could not drop queue '||l_queue_name);   
         end;
         begin
            sys.dbms_aqadm.drop_queue_table(queue_table => l_table_name);
            dbms_output.put_line('Dropped queue table '||l_table_name);
         exception
            when others then dbms_output.put_line('Could not drop queue table '||l_table_name);   
         end;
         begin
            sys.dbms_aqadm.create_queue_table(
               queue_table        => l_table_name, 
               queue_payload_type => 'SYS.AQ$_JMS_MAP_MESSAGE',
               multiple_consumers => true);
            dbms_output.put_line('Created queue table '||l_table_name);
         end;
         sys.dbms_aqadm.create_queue(
            queue_name     => l_queue_name,
            queue_table    => l_table_name,
            queue_type     => sys.dbms_aqadm.normal_queue,
            max_retries    => 5,
            retry_delay    => 0,
            retention_time => 0);
         dbms_output.put_line('Created queue '||l_queue_name);
         sys.dbms_aqadm.start_queue(
            queue_name => l_queue_name,
            enqueue    => true, 
            dequeue    => true);
         dbms_output.put_line('Started queue '||l_queue_name);
   end loop;
end;   

procedure purge_queues
is
   type zombie_t is table of boolean index by varchar2(31);
   l_subscriber_name      varchar2(30);
   l_subscriber           sys.aq$_agent := sys.aq$_agent(null, null, null);
   l_msg_state            varchar2(30);
   l_queue_name           varchar2(30);
   l_table_name           varchar2(30);
   l_count                pls_integer;
   l_last_dequeue         timestamp;
   l_zombies              zombie_t;
   l_cursor               sys_refcursor;
   l_purge_options        dbms_aqadm.aq$_purge_options_t;
   l_undeliverable_count  pls_integer;
   l_expired_count        pls_integer;
   l_purge_count          pls_integer;
   l_max_purge_count      pls_integer := 50000;
   l_max_expired_count    constant pls_integer := 10;
   l_purged               boolean := false;
begin
   l_purge_options.block := false; -- don't block enqueues or dequeues when trying to purge
   for rec in (
      select name
        from user_queues
       where name not like 'AQ$%')
   loop
      l_queue_name := rec.name;
      l_table_name := l_queue_name || '_TABLE';
      --------------------------------------------------------------
      -- determine if there are any zombies and messages to purge --
      --------------------------------------------------------------
      l_zombies.delete;
      l_undeliverable_count := 0;
      l_expired_count := 0;
      open l_cursor for
         'select consumer_name,
                 msg_state,
                 count(*),
                 max(deq_timestamp)
            from AQ$'||l_table_name||'
        group by consumer_name,
                 msg_state';
      loop
         fetch l_cursor into l_subscriber_name, l_msg_state, l_count, l_last_dequeue;
         exit when l_cursor%notfound;
            case l_msg_state
               when 'UNDELIVERABLE' then
                  l_undeliverable_count := l_undeliverable_count + l_count;
               when 'EXPIRED' then
                  l_expired_count := l_expired_count + l_count;
                  cwms_msg.log_db_message(
                     'purge_queues',
                     cwms_msg.msg_level_normal,
                     'Subsciber '
                        || l_subscriber_name
                        || ' for queue '
                        || l_queue_name
                        || ' has failed to dequeue '
                        || l_count
                        || ' messages');
                  if l_count > l_max_expired_count then
                     l_zombies(l_subscriber_name) := true;
                  end if;
               else null;
            end case;
       end loop;
      close l_cursor;
      ---------------------------------
      -- kill any zombie subscribers --
      ---------------------------------
      l_subscriber_name := l_zombies.first;
      loop
         exit when l_subscriber_name is null;
         if l_zombies(l_subscriber_name) then
            cwms_msg.log_db_message(
               'purge_queues',
               cwms_msg.msg_level_normal,
               'Removing zombie subsciber '
                  || l_subscriber_name
                  || ' for queue '
                  || l_queue_name);
            l_subscriber.name := l_subscriber_name;
            begin
               execute immediate
                  'select address,
                          protocol
                     into :address,
                          :protocol
                     from AQ$'||l_queue_name||'_TABLE_S
                    where queue = :queue
                      and name = :name'
                     into l_subscriber.address,
                          l_subscriber.protocol
                    using l_queue_name,
                          l_subscriber.name;
               dbms_aqadm.remove_subscriber(l_queue_name, l_subscriber);
               commit;
            exception
               when others then
                  cwms_msg.log_db_message(
                     'purge_queues',
                     cwms_msg.msg_level_normal,
                     'Error removing zombie subsciber '
                        || l_subscriber_name
                        || ' for queue '
                        || l_queue_name
                        || ': '
                        || sqlcode
                        || ' - '
                        || sqlerrm);
            end;
         end if;
         l_subscriber_name := l_zombies.next(l_subscriber_name);
      end loop;
      -------------------------------------------------
      -- purge any expired or undeliverable messages --
      ------------------------------------------------- 
      l_purge_count := l_expired_count + l_undeliverable_count;
      if l_purge_count > 0 then
         l_purged := false;
         for i in 1..trunc((l_purge_count - 1)/l_max_purge_count) + 1 loop
            for j in 1..100 loop
               begin
                  dbms_aqadm.purge_queue_table(
                     l_table_name,
                     'MSG_STATE IN(''UNDELIVERABLE'', ''EXPIRED'') AND ROWNUM <= '|| l_max_purge_count,
                     l_purge_options);
                  commit;
                  l_purged := true;
                  exit;
               exception
                  when others then null;  -- failed because something else was enqueing or dequeuing
               end;
            end loop;
         end loop;
         if l_purged then
            cwms_msg.log_db_message(
               'purge_queues',
               cwms_msg.msg_level_normal,
               'Done purging messages from queues '||l_queue_name);
         else
            cwms_msg.log_db_message(
               'purge_queues',
               cwms_msg.msg_level_normal,
               'Failed purging messages from queue '||l_queue_name);
         end if;
      end if;
   end loop;
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
   registr_not_found exception; pragma exception_init(registr_not_found, -24950);
   not_a_subscriber  exception; pragma exception_init(not_a_subscriber,  -24035);
   l_reg_info        sys.aq$_reg_info_list;
   l_parts           str_tab_t;
   l_subscriber_name varchar2(30);
   l_queue_name      varchar2(61);
   l_procedure_name  varchar2(61);
begin
   if instr(p_procedure_name, '.') = 0 then
      l_procedure_name := cwms_util.get_user_id||'.'||p_procedure_name;
   else
      l_procedure_name := p_procedure_name;
   end if;
   l_reg_info := get_registration_info(
      l_procedure_name,
      p_queue_name,
      p_subscriber_name);
   l_parts := cwms_util.split_text(l_reg_info(1).name ,':');
   l_queue_name := l_parts(1);
   l_subscriber_name := l_parts(2);
   begin
      dbms_aq.unregister(l_reg_info, l_reg_info.count);
   exception
      when registr_not_found then null; -- this is thrown even when it succeeds!!!
   end;
   begin
      dbms_aqadm.remove_subscriber(
         queue_name => l_queue_name,
         subscriber => sys.aq$_agent(l_subscriber_name, null, null));
   exception
      when not_a_subscriber then dbms_output.put_line(sqlerrm); -- harmless
   end;         
end unregister_msg_callback;

function get_queueing_pause_prop_key(
   p_all_sessions in boolean,
   p_get_mask     in boolean default false)
   return varchar2
is
   l_prop_id at_properties.prop_id%type := 'queues.enqueueing.paused.until';
begin
   if p_all_sessions then
      if p_get_mask then
         l_prop_id := l_prop_id||'.session=%';
      end if;
   else
      l_prop_id := l_prop_id||'.session='||sys_context('USERENV', 'SESSIONID');
   end if; 
   dbms_output.put_line(l_prop_id);
   return l_prop_id;
end get_queueing_pause_prop_key;   

procedure set_pause_until(
   p_until        date,
   p_all_sessions boolean,
   p_office_id    varchar2)
is
begin
   cwms_properties.set_property(
      'CWMSDB', 
      get_queueing_pause_prop_key(p_all_sessions), 
      to_char(p_until, 'yyyy/mm/dd hh24:mi'), 
      'set at '||to_char(sysdate, 'yyyy/mm/dd hh24:mi'), 
      p_office_id);
end set_pause_until;

function get_pause_until(   
   p_all_sessions boolean,
   p_office_id    varchar2)
   return date
is
   l_until      date;
   l_prop_value at_properties.prop_value%type;
begin
   l_prop_value := cwms_properties.get_property(
      'CWMSDB', 
      get_queueing_pause_prop_key(p_all_sessions), 
      null, 
      p_office_id);
      l_until := case l_prop_value is null
         when true  then date '1000-01-01' 
         when false then to_date(l_prop_value, 'yyyy/mm/dd hh24:mi')
      end;
   return l_until;      
end get_pause_until;      
   
procedure pause_message_queueing (
   p_number       in integer  default 10,
   p_unit         in varchar2 default 'MINUTES',
   p_all_sessions in varchar2 default 'F',
   p_office_id    in varchar2 default null)
is
   l_now          date := sysdate;
   l_office_id    varchar2(16);
   l_number       integer;
   l_unit         varchar2(8);
   l_all_sessions boolean;
   l_until        date;
begin
   cwms_util.check_inputs(str_tab_t(p_unit, p_office_id, p_all_sessions));
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_unit := upper(substr(p_unit, 1, 8));
   if l_unit not in ('MINUTE', 'MINUTES', 'HOUR', 'HOURS', 'DAY', 'DAYS') then
      cwms_err.raise('ERROR', 'P_unit must be ''MINUTE(S)'', ''HOUR(S)'', or ''DAY(S)''');
   end if;
   l_all_sessions := cwms_util.return_true_or_false(p_all_sessions);
   l_number := p_number;
   if substr(l_unit, 1, 4) = 'HOUR' then
      l_number := l_number * 60;
   elsif substr(l_unit, 1, 3) = 'DAY' then
      l_number := l_number * 1440;
   end if;
   if not l_number between 1 and 10080 then
      cwms_err.raise('ERROR', 'Pause time cannot be less than 1 minute or more than 1 week');
   end if;
   l_until := l_now + l_number / 1440;
   
   if get_pause_until(l_all_sessions, l_office_id) < l_until then
   
      set_pause_until(
         l_until, 
         l_all_sessions, 
         l_office_id);
                  
      cwms_msg.log_db_message(
         'PAUSE_MESSAGE_QUEUEING', 
         cwms_msg.msg_level_normal, 
         'Pausing message queueing until '
         ||to_char(l_until, 'yyyy/mm/dd hh24:mi')
         ||' ('
         ||l_number
         ||' minutes) for office '
         ||l_office_id
         ||case l_all_sessions
              when true  then ' session '||sys_context('USERENV', 'SESSIONID')
              when false then ' all sessions'
           end);
   else                  
      cwms_msg.log_db_message(
         'PAUSE_MESSAGE_QUEUEING', 
         cwms_msg.msg_level_normal, 
         'Message queueing already paused until '
         ||to_char(get_pause_until(l_all_sessions, l_office_id), 'yyyy/mm/dd hh24:mi')
         ||' for office '
         ||l_office_id
         ||case l_all_sessions
              when true  then ' session '||sys_context('USERENV', 'SESSIONID')
              when false then ' all sessions'
           end
         ||', request ignored.');
   end if;
end pause_message_queueing;   
   
procedure unpause_message_queueing(
   p_all_sessions in varchar2 default 'F',
   p_force        in varchar2 default 'F',
   p_office_id    in varchar2 default null)
is
   l_all_sessions boolean;
   l_force        boolean;
   l_office_id    varchar2(16);
   l_prop_id_mask at_properties.prop_id%type;
begin
   cwms_util.check_inputs(str_tab_t(p_all_sessions, p_force, p_office_id));
   l_all_sessions := cwms_util.return_true_or_false(p_all_sessions);
   l_force := cwms_util.return_true_or_false(p_force);
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   cwms_msg.log_db_message(
      'UNPAUSE_MESSAGE_QUEUEING', 
      cwms_msg.msg_level_normal, 
      'Unpausing queueing for office '
      ||l_office_id
      ||case l_all_sessions
              when false then ' session '||sys_context('USERENV', 'SESSIONID')
              when true  then ' all sessions (force='
                              ||case l_force
                                   when true  then 'T'
                                   when false then 'F'
                                end
                              ||')'
        end);
   if l_all_sessions then
      begin
         cwms_properties.delete_property(
            'CWMSDB', 
            get_queueing_pause_prop_key(true), 
            l_office_id);
      exception
         when no_data_found then null;
      end;
      if (l_force) then
         l_prop_id_mask := get_queueing_pause_prop_key(true, true);
         delete 
           from at_properties
          where office_code = cwms_util.get_db_office_code(l_office_id)
            and prop_category = 'CWMSDB'
            and prop_id like l_prop_id_mask;
      end if;
   else
      begin
         cwms_properties.delete_property(
            'CWMSDB', 
            get_queueing_pause_prop_key(false), 
            l_office_id);
      exception
         when no_data_found then null;
      end;
   end if;        
end unpause_message_queueing;   

function get_message_queueing_pause_min(
   p_office_id in varchar2 default null)
   return integer
is
   l_office_id  varchar2(16);
   l_until      date;
   l_minutes    integer;
begin
   cwms_util.check_input(p_office_id);
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_until := greatest(
      get_pause_until(true,  l_office_id),
      get_pause_until(false, l_office_id));
   l_minutes := case l_until > sysdate
                   when true  then ceil((l_until - sysdate) * 1440)
                   when false then -1
                end;      
   return l_minutes;      
end get_message_queueing_pause_min;   

function is_message_queueing_paused(
   p_office_id in varchar2 default null)
   return boolean
is
begin
   return get_message_queueing_pause_min(p_office_id) > 0;
end is_message_queueing_paused;         


end cwms_msg;
/
show errors;
