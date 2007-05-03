create or replace package body cwms_xchg as

function is_realtime_export(
   p_ts_code in integer)
   return boolean
is
   l_count integer;
begin
   --------------------------------------------------------------------------
   -- determine if the ts_code participates in a realtime Oracle-->DSS set --
   --------------------------------------------------------------------------
   select count(*)
     into l_count
     from dual
    where exists(select null
                   from at_dss_xchg_set         xset,
                        at_dss_ts_xchg_map      xmap,
                        at_dss_ts_xchg_spec     xspec
                  where xspec.ts_code = p_ts_code
                    and xmap.dss_ts_xchg_code = xspec.dss_ts_xchg_code
                    and xset.dss_xchg_set_code = xmap.dss_xchg_set_code
                    and xset.realtime = (select dss_xchg_direction_code 
                                           from cwms_dss_xchg_direction 
                                          where dss_xchg_direction_id = 'OracleToDss'));
   return l_count = 1;
                                             
end is_realtime_export;   
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
--
function use_first_table(
   p_timestamp in timestamp default null) 
   return boolean
is
begin
   return mod(to_char(nvl(p_timestamp, systimestamp), 'MM'), 2) = 1;
end use_first_table;
                       
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
--
function use_first_table(
   p_timestamp in integer) 
   return boolean
   
is
begin
   return use_first_table(cwms_util.to_timestamp(p_timestamp));
end use_first_table;   
   
-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in timestamp default null)
   return varchar2
is
begin              
   if use_first_table(p_timestamp) then return 'AT_TS_MSG_ARCHIVE_1'; end if;
   return 'AT_TS_MSG_ARCHIVE_2';
end get_table_name;   
   
-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in integer default null)
   return varchar2
is
begin
   return get_table_name(cwms_util.to_timestamp(p_timestamp));
end get_table_name;   
   
-------------------------------------------------------------------------------
-- PROCEDURE XCHG_CONFIG_UPDATED
--
procedure xchg_config_updated
is
   l_component   varchar2(32)  := 'DataExchangeConfigurationEditor';
   l_instance    varchar2(32)  := null;
   l_host        varchar2(32)  := null;
   l_port        integer       := null;
   l_reported    timestamp     := systimestamp;
   l_log_message varchar2(4000);
   l_rt_message  varchar2(4000);
   l_parts       cwms_util.str_tab_t;
   l_ts          integer;
begin
   l_log_message := '</cwms_message type="Status">'
                    || '<property name="subtype" type="String">XchgConfigUpdated</property>'
                    || '</cwms_message>';
   
   l_parts := cwms_util.split_text(l_log_message, '>', 1);
   
   l_rt_message := l_parts(1) 
                   || '><property name="component" type="String">'
                   || l_component
                   || '</property>'
                   || '<property name="reported" type="long">'
                   || cwms_util.to_millis(l_reported)
                   || '</property>'
                   || l_parts(2);

   l_ts := cwms_msg.publish_message(l_rt_message, 'realtime_ops');
   
   l_ts := cwms_msg.log_message(l_component,l_instance,l_host,l_port,l_reported,l_log_message);                      
end xchg_config_updated;

-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED(...)
--
procedure time_series_updated(
   p_ts_code    in integer, 
   p_ts_id      in varchar2, 
   p_first_time in timestamp with time zone,
   p_last_time  in timestamp with time zone)
is
   l_msg sys.aq$_jms_text_message;
   l_first_time timestamp;
   l_last_time  timestamp;
   i     integer;
begin
   --------------------------------------------------------------------------
   -- determine if the ts_code participates in a realtime Oracle-->DSS set --
   --------------------------------------------------------------------------
   if is_realtime_export(p_ts_code) then
      -------------------------------------------------------                     
      -- insert the time series update info into the table --
      -------------------------------------------------------
      l_first_time := sys_extract_utc(p_first_time);
      l_last_time  := sys_extract_utc(p_last_time);                     
      if use_first_table then
         ----------------
         -- odd months --
         ----------------
         insert 
           into at_ts_msg_archive_1 
         values (cwms_msg.get_msg_id,
                 p_ts_code, 
                 systimestamp, 
                 cast(l_first_time as date), 
                 cast(l_last_time as date));
      else
         -----------------
         -- even months --
         -----------------
         insert 
           into at_ts_msg_archive_2
         values (cwms_msg.get_msg_id,
                 p_ts_code, 
                 systimestamp, 
                 cast(l_first_time as date), 
                 cast(l_last_time as date));
      end if;

      -------------------------
      -- publish the message --
      -------------------------
      l_msg := cwms_msg.new_message('TSDataStored');
      l_msg.set_string_property('ts_id', p_ts_id);
      l_msg.set_long_property('start_time', cwms_util.to_millis(l_first_time));
      l_msg.set_long_property('end_time', cwms_util.to_millis(l_last_time));
      i := cwms_msg.publish_message(l_msg, 'realtime_ops');
   end if;

end time_series_updated;   

-------------------------------------------------------------------------------
-- PROCEDURE UPDATE_LAST_PROCESSED_TIME(...)
--
procedure update_last_processed_time (
   p_component   in varchar2,
   p_host        in varchar2,
   p_port        in integer,
   p_xchg_code   in integer,
   p_update_time in integer)
is
   l_log_msg varchar2(4000);
   i         integer;
   l_set_id  at_dss_xchg_set.dss_xchg_set_id%type;
begin
   -----------------------------
   -- update the exchange set --
   -----------------------------
   cwms_dss.update_dss_xchg_set_time(p_xchg_code, cwms_util.to_timestamp(p_update_time));
   -------------------------
   -- publish the message --
   -------------------------
   select dss_xchg_set_id
     into l_set_id
     from at_dss_xchg_set
    where dss_xchg_set_code = p_xchg_code;
    
   l_log_msg := '<cwms_message type="Status">'
                || '<property type="String" name="subtype">LastProcessedTimeUpdated</property>'
                || '<property type="String" name="set_id">'
                || l_set_id
                || '</property>'
                || '<property type="long" name="last_processed">'
                || p_update_time
                || '</property>'
                || '</cwms_message>';
                
   i := cwms_msg.log_message(p_component, null, p_host, p_port, systimestamp, l_log_msg);
   
end update_last_processed_time;   
   
-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REPLAY_DATA_MESSAGES(...)
--
function replay_data_messages(
   p_xchg_code  in integer,
   p_start_time in integer  default null,
   p_end_time   in integer  default null,
   p_request_id in varchar2 default null)
   return varchar2
is
   type assoc_bool_vc183 is table of boolean index by varchar2(183);
   l_start_time    timestamp;
   l_end_time      timestamp;
   l_request_id    varchar2(32) := nvl(p_request_id, rawtohex(sys_guid()));
   l_message       sys.aq$_jms_text_message;
   l_message_count integer;
   l_tsids         assoc_bool_vc183;
   l_earliest      date;
   l_latest        date;
   l_ts            integer;
begin
   ---------------------------------
   -- get the start and end times --
   ---------------------------------
   if p_start_time is null then
      select last_update
        into l_start_time
        from at_dss_xchg_set
       where dss_xchg_set_code = p_xchg_code;
   else
      l_start_time := cwms_util.to_timestamp(p_start_time);
   end if;
   if p_end_time is null then
      l_end_time := systimestamp;
   else
      l_end_time := cwms_util.to_timestamp(p_end_time);
   end if;
   -------------------------------------
   -- loop over the archived messages --
   -------------------------------------
   for rec in (select msg.ts_code, 
                      msg.message_time,
                      msg.first_data_time,
                      msg.last_data_time,
                      tsid.cwms_ts_id 
                 from ((select * from at_ts_msg_archive_1) union (select * from at_ts_msg_archive_2)) msg,
                      mv_cwms_ts_id tsid
                where message_time between l_start_time and l_end_time
                  and msg.ts_code in (select ts_code
                                    from at_dss_ts_xchg_spec xspec,
                                         at_dss_ts_xchg_map  xmap
                                   where xmap.dss_xchg_set_code = p_xchg_code
                                     and xspec.dss_ts_xchg_code = xmap.dss_ts_xchg_code
                                 )
             order by msg.message_time asc
              ) 
   loop
      ------------------------------
      -- keep track of statistics --
      ------------------------------
      l_message_count := l_message_count + 1;
      if not l_tsids.exists(rec.cwms_ts_id) then
         l_tsids(rec.cwms_ts_id) := true;
      end if;
      if l_earliest is null or rec.first_data_time < l_earliest then
         l_earliest := rec.first_data_time;
      end if;
      if l_latest is null or rec.last_data_time < l_latest then
         l_latest := rec.last_data_time;
      end if;
      --------------------------------
      -- publish the replay message --
      --------------------------------
      l_message := cwms_msg.new_message('TSDataStored');
      l_message.set_string_property('ts_id', rec.cwms_ts_id);
      l_message.set_long_property('start_time', cwms_util.to_millis(to_timestamp(rec.first_data_time)));
      l_message.set_long_property('end_time', cwms_util.to_millis(to_timestamp(rec.last_data_time)));
      l_message.set_long_property('original_millis', cwms_util.to_millis(rec.message_time));
      l_message.set_string_property('replay_id', l_request_id);
      l_ts := cwms_msg.publish_message(l_message, 'realtime_ops');
   end loop;
   ------------------------------------------
   -- publish the replay completed message --
   ------------------------------------------
   l_message := cwms_msg.new_message('TSReplayDone');
   l_message.set_string_property('replay_id', l_request_id);
   l_message.set_int_property('message_count', l_message_count);
   l_message.set_int_property('ts_id_count', l_tsids.count);
   l_message.set_long_property('first_time', cwms_util.to_millis(to_timestamp(l_earliest)));
   l_message.set_long_property('last_time', cwms_util.to_millis(to_timestamp(l_latest)));
   l_ts := cwms_msg.publish_message(l_message, 'realtime_ops');
   return l_request_id;
end replay_data_messages;   

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION RESTART_REALTIME(...)
--
function restart_realtime(
   p_xchg_code in integer)
   return varchar2
is
begin
   return replay_data_messages(p_xchg_code);
end restart_realtime;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION RESTART_REALTIME(...)
--
function restart_realtime(
   p_engine_url in varchar2)
   return varchar2
is
   l_request_ids varchar2(4000);
begin
   for rec in (select dss_xchg_set_code
                 from at_dss_xchg_set xset,
                      at_dss_file     dfile
                where dfile.dss_filemgr_url = p_engine_url
                  and xset.dss_file_code = dfile.dss_file_code
                  and xset.realtime is not null)
   loop
      l_request_ids := l_request_ids || ',' || restart_realtime(rec.dss_xchg_set_code);
   end loop;
   return substr(l_request_ids, 2);
end restart_realtime;

-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION REQUEST_BATCH_EXCHANGE(...)
--
function request_batch_exchange(
   p_component  in varchar2,
   p_host       in varchar2,
   p_set_id     in varchar2,
   p_to_dss     in varchar2,
   p_start_time in integer,
   p_end_time   in integer default null)
   return varchar2
is
   l_job_id   varchar2(32) := rawtohex(sys_guid());
   l_log_msg  varchar2(4000);
   l_rt_msg   varchar2(4000);
   l_to_dss   varchar2(8);
   l_parts    cwms_util.str_tab_t;
   l_reported timestamp := systimestamp;
   i          integer;
begin
   if cwms_util.return_true_or_false(p_to_dss) then
      l_to_dss := 'true';
   else
      l_to_dss := 'false';
   end if;
   l_log_msg := '<cwms_message type="RequestAction">'
                || '<property type="String" name="subtype">BatchExchange</property>'
                || '<property type="String" name="user">'
                || sys_context ('userenv', 'session_user')
                || '</property><property type="String" name="set_id">'
                || p_set_id
                || '</property><property type="String" name="job_id">'
                || l_job_id
                || '</property><property type="long" name="start_time">'
                || p_start_time
                || '</property><property type="long" name="end_time">'
                || nvl(p_end_time, cwms_util.current_millis)
                || '</property><property type="boolean" name="to_dss">'
                || l_to_dss
                || '</property></cwms_message>';
                
   l_parts := cwms_util.split_text(l_log_msg, '>', 1);
   
   l_rt_msg := l_parts(1)
               || '><property name="component" type="String">'
               || p_component
               || '</property><property name="host" type="String">'
               || p_host
               || '</property><property name="reported" type="long">'
               || cwms_util.to_millis(l_reported)
               || '</property>'
               || l_parts(2);                
                
   i := cwms_msg.log_message(p_component, null, p_host, null, l_reported, l_log_msg);
   
   return l_job_id;
end request_batch_exchange;
   
end cwms_xchg;
/

commit;
show errors;

