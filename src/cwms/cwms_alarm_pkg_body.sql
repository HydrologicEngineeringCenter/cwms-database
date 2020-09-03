create or replace package body cwms_alarm
as
procedure notify_datastream_alarm_state(
   p_data_stream_name in varchar2,
   p_host             in varchar2,
   p_alarm_state      in integer,
   p_raw_time_utc     in date,
   p_valid_time_utc   in date,
   p_raw_age          in interval day to second default null,
   p_raw_age_max      in interval day to second default null,
   p_valid_age        in interval day to second default null,
   p_valid_age_max    in interval day to second default null,
   p_office_id        in varchar2 default null)
is
   l_office_id    varchar2(16);
   l_raw_millis   integer;
   l_valid_millis integer;
   l_message      varchar2(32767);  
   l_message_id   integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_data_stream_name is null then
      cwms_err.raise('NULL_ARGUMENT', p_data_stream_name);
   end if;                                                
   if p_alarm_state is null then
      cwms_err.raise('NULL_ARGUMENT', p_alarm_state);
   end if;                                           
   if p_alarm_state not between 0 and 2 then
      cwms_err.raise('ERROR', 'P_alarm_state must be in the range 0..2');
   end if;
   ----------------------------- 
   -- create the message text --
   ----------------------------- 
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_raw_millis := cwms_util.to_millis(p_raw_time_utc);
   l_valid_millis := cwms_util.to_millis(p_valid_time_utc);
   l_message := '<cwms_message type="Alarm">';
   l_message := l_message || '<property name="office" type="String">'||l_office_id||'</property>';
   l_message := l_message || '<property name="alarm-state" type="int">'||p_alarm_state||'</property>';
   if l_raw_millis is not null then
      l_message := l_message || '<property name="raw-time" type="long">'||l_raw_millis||'</property>';
   end if; 
   if l_valid_millis is not null then
      l_message := l_message || '<property name="validated-time" type="long">'||l_valid_millis||'</property>';
   end if;
   if p_raw_age is not null then
      l_message := l_message || '<property name="raw-age" type="long">'||cwms_util.to_millis(cwms_util.epoch+p_raw_age)||'</property>';
   end if; 
   if p_valid_age is not null then
      l_message := l_message || '<property name="validated-age" type="long">'||cwms_util.to_millis(cwms_util.epoch+p_valid_age)||'</property>';
   end if; 
   if p_raw_age_max is not null then
      l_message := l_message || '<property name="raw-age-max" type="long">'||cwms_util.to_millis(cwms_util.epoch+p_raw_age_max)||'</property>';
   end if; 
   if p_valid_age_max is not null then
      l_message := l_message || '<property name="validated-age-max" type="long">'||cwms_util.to_millis(cwms_util.epoch+p_valid_age_max)||'</property>';
   end if; 
   l_message := l_message || '</cwms_message>';
   ---------------------------------
   -- log and publish the message --
   ---------------------------------
   l_message_id := cwms_msg.log_message(
      p_component => 'Data Stream', 
      p_instance  => p_data_stream_name, 
      p_host      => p_host,
      p_port      => null, 
      p_reported  => systimestamp, 
      p_message   => l_message, 
      p_msg_level => cwms_msg.msg_level_basic, 
      p_publish   => true, 
      p_immediate => true);
end notify_datastream_alarm_state;  
   
procedure notify_loc_lvl_ind_state(
   p_loc_lvl_ind_code in varchar2,
   p_state            in number,
   p_state_time       in date,
   p_duration         in integer,
   p_operation        in integer,
   p_time_zone        in varchar2 default null,
   p_ts_code_used     in number   default null)
is
   l_loc_lvl_ind    cwms_t_loc_lvl_indicator;  
   l_ts_id_used     varchar2(191);
   l_message        varchar2(32767);  
   l_message_id     integer;
   l_time_zone      varchar2(28);
   l_rowid          urowid;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_loc_lvl_ind_code is null then
      cwms_err.raise('NULL_ARGUMENT', p_loc_lvl_ind_code);
   end if;                                                
   if p_state is null then
      cwms_err.raise('NULL_ARGUMENT', p_state);
   end if;                                                
   if p_duration is null then
      cwms_err.raise('NULL_ARGUMENT', p_duration);
   end if;                                                
   if p_operation is null then
      cwms_err.raise('NULL_ARGUMENT', p_operation);
   end if;   
   begin
      select rowid
        into l_rowid
        from at_loc_lvl_indicator
       where level_indicator_code = p_loc_lvl_ind_code;
   exception
      when no_data_found then
         cwms_err.raise('INVALID_ITEM', p_loc_lvl_ind_code, 'location level indicator code');
   end;
   l_loc_lvl_ind := cwms_t_loc_lvl_indicator(l_rowid);
   if p_ts_code_used is not null then
      l_ts_id_used := cwms_ts.get_ts_id(p_ts_code_used);
      if l_ts_id_used is null then
         cwms_err.raise('INVALID_ITEM', p_ts_code_used, 'time series code');
      end if;
   end if;
   if p_time_zone is null then
      l_time_zone := cwms_loc.get_local_timezone(l_loc_lvl_ind.location_id, l_loc_lvl_ind.office_id);
   else
      l_time_zone := p_time_zone;
   end if;
   ----------------------------- 
   -- create the message text --
   ----------------------------- 
   l_message := '<cwms_message type="Alarm">';
   l_message := l_message || '<property name="office" type="String">'||l_loc_lvl_ind.office_id||'</property>';
   l_message := l_message || '<property name="alarm-state" type="int">'||p_state||'</property>';
   if trunc(p_state) = p_state then
      if p_state < 0 then
         l_message := l_message 
         || '<property name="alarm-state-name" type="String">Could not compute indicator conditions</property>';
      elsif p_state = 0 then
         l_message := l_message 
         || '<property name="alarm-state-name" type="String">No indicator conditions are set</property>';
      else
         l_message := l_message 
         || '<property name="alarm-state-name" type="String">'
         || l_loc_lvl_ind.conditions(p_state).description
         || '</property>';
      end if;
   else  
      if trunc(p_state) = 0 then
         l_message := l_message 
         || '<property name="alarm-state-lower-name" type="String">No indicator conditions are set</property>';
      else
         l_message := l_message 
         || '<property name="alarm-state-lower-name" type="String">'
         || l_loc_lvl_ind.conditions(trunc(p_state)).description
         || '</property>';
      end if;
      l_message := l_message 
      || '<property name="alarm-state-higher-name" type="String">'
      || l_loc_lvl_ind.conditions(trunc(p_state)+1).description
      || '</property>';
   end if;
   if p_state_time is not null then
      l_message := l_message || '<property name="alarm-state-time" type="long">'||cwms_util.to_millis(cwms_util.change_timezone(p_state_time, l_time_zone, 'UTC'))||'</property>';
   end if; 
   l_message := l_message || '<property name="duration" type="long">'||p_duration * 60000||'</property>';
   l_message := l_message || '<property name="operation" type="String">'
                          || case p_operation
                                when cwms_alarm.operation_maximum     then 'maximum'
                                when cwms_alarm.operation_mean        then 'mean'
                                when cwms_alarm.operation_median      then 'median'
                                when cwms_alarm.operation_minimum     then 'minimum'
                                when cwms_alarm.operation_mode        then 'mode'
                                when cwms_alarm.operation_most_recent then 'most recent'
                             end
                          || '</property>';
   if l_ts_id_used is not null then
      l_message := l_message || '<property name="timeseries" type="String">'||l_ts_id_used||'</property>';
   end if; 
   l_message := l_message || '</cwms_message>';
   ---------------------------------
   -- log and publish the message --
   ---------------------------------
   l_message_id := cwms_msg.log_message(
      p_component => 'Location Level Indicator', 
      p_instance  => cwms_util.join_text(cwms_t_str_tab(
                     l_loc_lvl_ind.location_id,
                     l_loc_lvl_ind.parameter_id,
                     l_loc_lvl_ind.parameter_type_id,
                     l_loc_lvl_ind.duration_id,
                     l_loc_lvl_ind.specified_level_id,
                     l_loc_lvl_ind.level_indicator_id),
                     '.'), 
      p_host      => utl_inaddr.get_host_name,
      p_port      => null, 
      p_reported  => systimestamp, 
      p_message   => l_message, 
      p_msg_level => cwms_msg.msg_level_basic, 
      p_publish   => true, 
      p_immediate => true);
end notify_loc_lvl_ind_state;

procedure notify_loc_lvl_ind_state(
   p_ts_id              in varchar2,
   p_specified_level_id in varchar2,
   p_level_indicator_id in varchar2,
   p_attribute_id       in varchar2 default null,
   p_attribute_value    in number   default null,
   p_attribute_unit     in varchar2 default null,
   p_duration           in integer  default null,
   p_operation          in integer  default operation_most_recent,
   p_min_state_notify   in integer  default 0,
   p_max_state_notify   in integer  default 5,
   p_notify_state_err   in varchar2 default 'T',
   p_office_id          in varchar2 default null)
is
   type rec_t is record (
      indicator_id     varchar2(431),
      attribute_id     varchar2(83),
      attribute_value  number,
      attribute_units  varchar2(16),
      indicator_values cwms_t_ztsv_array);
   type number_counts_t is table of pls_integer index by pls_integer;
   l_cursor          sys_refcursor;
   l_rec             rec_t;  
   l_office_id       varchar2(16);  
   l_ts_id           varchar2(191);
   l_ts_code         number(14);
   l_min_duration    integer; -- minutes
   l_duration        integer; -- minutes
   l_indicator       cwms_t_loc_lvl_indicator;
   l_indicator_id    varchar2(431);
   l_indicator_code  number(14);
   l_ref_spec_lvl_id varchar2(256);      
   l_parts           cwms_t_str_tab; 
   l_unit_system     varchar2(2);
   l_state           number; 
   l_state_time      date;
   l_count           pls_integer := 0;
   l_max_count       pls_integer := 0;
   l_total           number      := 0; 
   l_values          cwms_t_number_tab;
   l_counts          number_counts_t;
   l_key             pls_integer;
begin
   -------------------
   -- sanity checks --
   -------------------
   if p_ts_id is null then
      cwms_err.raise('NULL_ARGUMENT', p_ts_id);
   end if;                                                
   if p_specified_level_id is null then
      cwms_err.raise('NULL_ARGUMENT', p_specified_level_id);
   end if;                                                
   if p_level_indicator_id is null then
      cwms_err.raise('NULL_ARGUMENT', p_level_indicator_id);
   end if;                                                
   l_office_id := cwms_util.get_db_office_id(p_office_id);
   l_ts_id := cwms_ts.get_ts_id(p_ts_id, l_office_id); -- this call handles aliases 
   if l_ts_id is null then
      cwms_err.raise('TS_ID_NOT_FOUND', p_ts_id, l_office_id);
   end if;
   l_ts_code := cwms_ts.get_ts_code(l_ts_id, l_office_id); 
   if (p_attribute_id is null) != (p_attribute_value is null) or 
      (p_attribute_id is null) != (p_attribute_unit  is null) then
      cwms_err.raise('ERROR', 'P_attribute_id, p_attribute_value, p_attribute_unit must all be specified or all be NULL.');
   end if;
   ---------------------------------------------------
   -- get the unit system if attribute is specified --
   ---------------------------------------------------
   if p_attribute_unit is not null then
      select unit_system
        into l_unit_system
        from cwms_v_unit
       where unit_id = p_attribute_unit
         and db_office_id in ('CWMS', l_office_id);
   end if;
   ---------------------------------------------------------------------------------------
   -- get the location level indicator id and code and any reference specified level id --
   ---------------------------------------------------------------------------------------
   l_parts := cwms_util.split_text(l_ts_id, '.'); -- 6 parts
   l_parts(4) := l_parts(5); -- move duration to 4th position
   l_parts(5) := p_specified_level_id;
   l_parts(6) := p_level_indicator_id;     
   l_indicator_id := cwms_util.join_text(l_parts, '.');
   begin
      select level_indicator_id,
             reference_level_id
        into l_indicator_id,
             l_ref_spec_lvl_id
        from cwms_v_loc_lvl_indicator_2
       where upper(level_indicator_id) = upper(l_indicator_id)
         and attribute_id is null;
   exception
      when no_data_found then
         cwms_err.raise(
            'ERROR',
            l_indicator_id
            || ' is not a valid no-attribute location level indicator'); 
   end;
   l_indicator_code := cwms_level.get_loc_lvl_indicator_code(
      p_loc_lvl_indicator_id   => l_indicator_id, 
      p_ref_specified_level_id => l_ref_spec_lvl_id, 
      p_office_id              => l_office_id);
   ------------------------------
   -- get the minimum duration --
   ------------------------------
   l_indicator := cwms_level.retrieve_loc_lvl_indicator(
      p_loc_lvl_indicator_id   => l_indicator_id, 
      p_ref_specified_level_id => l_ref_spec_lvl_id,
      p_office_id              => l_office_id);
   l_min_duration := trunc(
     extract(day    from l_indicator.minimum_duration) * 1440 + 
     extract(hour   from l_indicator.minimum_duration) * 60   +
     extract(minute from l_indicator.minimum_duration)        +
     extract(second from l_indicator.minimum_duration) / 60);
   l_min_duration := l_min_duration + trunc(
     extract(day    from l_indicator.maximum_age) * 1440 + 
     extract(hour   from l_indicator.maximum_age) * 60   +
     extract(minute from l_indicator.maximum_age)        +
     extract(second from l_indicator.maximum_age) / 60);
   if p_duration is null or p_duration < l_min_duration then
      l_duration := l_min_duration; 
   else                            
      l_duration := p_duration;
   end if;
   -----------------------------------------------------------   
   -- get the location level indicator max condition values --
   -----------------------------------------------------------   
   cwms_level.get_level_indicator_max_values(
      p_cursor               => l_cursor, 
      p_tsid                 => p_ts_id, 
      p_start_time           => sysdate - l_duration / 1440, 
      p_end_time             => sysdate, 
      p_time_zone            => 'UTC', 
      p_specified_level_mask => p_specified_level_id, 
      p_indicator_id_mask    => p_level_indicator_id, 
      p_unit_system          => l_unit_system, 
      p_office_id            => p_office_id);
   fetch l_cursor into l_rec;
   close l_cursor;
   -----------------------------------------------------------------------
   -- compute the value to report and the latest time that value occurs --
   -----------------------------------------------------------------------
   case p_operation
      when operation_maximum then   
         -------------------
         -- maximum value --
         -------------------
         select max(v.value) 
           into l_state 
           from table(l_rec.indicator_values) v 
          where v.value is not null;
         select max(v.date_time) 
           into l_state_time 
           from table(l_rec.indicator_values) v 
          where v.value = l_state;
      when operation_mean then
         ----------------
         -- mean value --
         ----------------  
         select sum(v.value) 
           into l_total 
           from table(l_rec.indicator_values) v 
          where v.value is not null;
         select count(*) 
           into l_count 
           from table(l_rec.indicator_values) v 
          where v.value is not null;
         l_state := l_total / l_count;
         -- no state_time for mean
      when operation_median then
         ------------------
         -- median value --
         ------------------
         select v.value
           bulk collect 
           into l_values 
           from table(l_rec.indicator_values) v 
          where v.value is not null
          order by v.value;
         if mod(l_values.count, 2) = 0 then
            l_state := (l_values(l_values.count/2) + l_values(l_values.count/2+1)) / 2;
            select max(v.date_time) 
              into l_state_time 
              from table(l_rec.indicator_values) v 
             where v.value between l_values(l_values.count/2) and l_values(l_values.count/2+1);
         else
            l_state := l_values(trunc(l_values.count / 2) + 1);
            select max(v.date_time) 
              into l_state_time 
              from table(l_rec.indicator_values) v 
             where v.value = l_state;
         end if;             
      when operation_minimum then
         -------------------
         -- minimum value --
         -------------------
         select max(v.value) 
           into l_state 
           from table(l_rec.indicator_values) v 
          where v.value is not null;
         select max(v.date_time) 
           into l_state_time 
           from table(l_rec.indicator_values) v 
          where v.value = l_state;
      when operation_mode then
         ----------------
         -- mode value --
         ----------------
         for i in 1..l_rec.indicator_values.count loop  
            if l_rec.indicator_values(i).value is not null then
               if l_counts.exists(l_rec.indicator_values(i).value) then
                  l_counts(l_rec.indicator_values(i).value) := l_counts(l_rec.indicator_values(i).value) + 1;
               else
                  l_counts(l_rec.indicator_values(i).value) := 1;
               end if;
            end if;
         end loop;
         l_key := l_counts.first;
         while not l_key is null loop
            if l_state is null or l_counts(l_key) >= l_max_count then  -- greatest value if multimodal
               l_max_count := l_counts(l_key);
               l_state     := l_key;
            end if;
            l_key := l_counts.next(l_key);
         end loop;
         select max(v.date_time) 
           into l_state_time 
           from table(l_rec.indicator_values) v 
          where v.value = l_state;
      when operation_most_recent then
         -----------------------
         -- most recent value --
         -----------------------
         select v.date_time,
                v.value
           into l_state_time,
                l_state
           from table(l_rec.indicator_values) v
          where v.date_time in (select max(v2.date_time)
                                  from table(l_rec.indicator_values) v2
                                 where v2.value is not null
                               ); 
   end case;      
   if l_state is null then
      l_state := state_condition_error;
   end if;  
   ----------------------
   -- report the value --
   ----------------------
   if ((l_state = state_condition_error) and cwms_util.return_true_or_false(p_notify_state_err)) or 
      (l_state between p_min_state_notify and p_max_state_notify) then
      notify_loc_lvl_ind_state(
         p_loc_lvl_ind_code => l_indicator_code, 
         p_state            => l_state, 
         p_state_time       => l_state_time, 
         p_duration         => l_duration, 
         p_operation        => p_operation, 
         p_time_zone        => 'UTC', 
         p_ts_code_used     => l_ts_code);   
   end if;
end notify_loc_lvl_ind_state;

end cwms_alarm;
/
show errors;
