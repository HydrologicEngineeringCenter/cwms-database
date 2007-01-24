create or replace package body cwms_xchg as

-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(TIMESTAMP)
--
function use_first_table(
   p_timestamp in timestamp default null) 
   return boolean
is
   time_value timestamp;

begin
   if p_timestamp is null then
      time_value := systimestamp;
   else
      time_value := p_timestamp;
   end if;
   
   return mod(to_char(time_value, 'MM'), 2) = 1;

end use_first_table;
                       
-------------------------------------------------------------------------------
-- BOOLEAN FUNCTION USE_FIRST_TABLE(VARCHAR2)
--
function use_first_table(
   p_timestamp in varchar2) 
   return boolean
   
is
   time_value timestamp;
   
begin
   time_value := to_timestamp(p_timestamp, iso_8601_timestamp_format);
   return use_first_table(time_value);
   
exception
   when others then 
      cwms_err.raise('XCHG_TIME_VALUE', p_timestamp, 'yyyy-mm-ddThh:mi:ss.ffZ'); 

end use_first_table;   
   
-------------------------------------------------------------------------------
-- VARCHAR2 FUNCTION GET_TABLE_NAME(TIMESTAMP)
--
function get_table_name(
   p_timestamp in timestamp default null)
   return varchar2
is
   table_name varchar2(32);
   
begin              
   if use_first_table(p_timestamp) then
      table_name := 'AT_XCHG_TS_INFO_1';
   else
      table_name := 'AT_XCHG_TS_INFO_2';
   end if;
   return table_name;
   
end get_table_name;   
   
-------------------------------------------------------------------------------
-- PROCEDURE CONTROL_UPDATED()
--
procedure control_updated
is
   msg                      sys.aq$_jms_text_message;
   message_properties       dbms_aq.message_properties_t;
   enqueue_options          dbms_aq.enqueue_options_t;
   msgid                    raw(16);
   msg_handle               pls_integer;
         
begin
   ---------------------------
   -- construct the message --
   ---------------------------
   msg := sys.aq$_jms_text_message.construct();
   msg.set_boolean_property('control_info_updated', true);                  
   msg.set_string_property('update_time', to_char(systimestamp, iso_8601_timestamp_format));
   
   -------------------------
   -- enqueue the message --
   -------------------------
   dbms_aq.enqueue(
      'xchg_queue',
      enqueue_options,
      message_properties,
      msg,
      msgid);
      
   commit;

exception
   ---------------------------------------
   -- ignore the case of no subscribers --
   ---------------------------------------
   when exc_no_subscribers then null;
      
end control_updated;

-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED1(...)
--
procedure time_series_updated1(
   p_ts_code         in number, 
   p_office_id       in varchar2, 
   p_timeseries_desc in varchar2,
   p_store_rule      in varchar2, 
   p_units           in varchar2,
   p_override_prot   in boolean, 
   p_timeseries_data in tsv_array)
is                                  
   msg                  sys.aq$_jms_text_message;
   message_properties   dbms_aq.message_properties_t;
   enqueue_options      dbms_aq.enqueue_options_t;      
   msgid                raw(16);
   xchg_code            number(10);
   override_flag        char(1);
   update_time          timestamp(6);  
   
begin          
   -------------------------------------------------------                     
   -- insert the time series update info into the table --
   -------------------------------------------------------                     
   update_time := systimestamp;
   if p_override_prot then 
      override_flag := 'T'; 
   else 
      override_flag := 'F'; 
   end if;
   select seq_xchg.nextval into xchg_code from dual;
   if use_first_table(update_time) then
      ----------------
      -- odd months --
      ----------------
      insert into at_xchg_ts_info_1 values (
         xchg_code,
         p_ts_code, 
         update_time, 
         p_store_rule,
         override_flag, 
         p_units,
         p_timeseries_data);
         
   else
      -----------------
      -- even months --
      -----------------
      insert into at_xchg_ts_info_2 values (
         xchg_code,
         p_ts_code, 
         update_time, 
         p_store_rule,
         override_flag, 
         p_units,
         p_timeseries_data);
         
   end if;
      
   ---------------------------
   -- construct the message --
   ---------------------------
   msg := sys.aq$_jms_text_message.construct();
   msg.set_boolean_property('time_series_updated', true);                  
   msg.set_boolean_property('override_protection', p_override_prot);
   msg.set_int_property('value_count', p_timeseries_data.count);
   msg.set_int_property('xchg_code', xchg_code);
   msg.set_int_property('ts_code', p_ts_code);
   msg.set_string_property('update_time', to_char(update_time, iso_8601_timestamp_format));
   msg.set_string_property('office_id', p_office_id); 
   msg.set_string_property('ts_description', p_timeseries_desc);
   msg.set_string_property('store_rule', p_store_rule);
   msg.set_string_property('units', p_units);

   -------------------------
   -- enqueue the message --
   -------------------------
   dbms_aq.enqueue(
      'xchg_queue',
      enqueue_options,
      message_properties,
      msg,
      msgid);
      
   commit;
      
exception
   ---------------------------------------
   -- ignore the case of no subscribers --
   ---------------------------------------
   when exc_no_subscribers then null;

end time_series_updated1;   

-------------------------------------------------------------------------------
-- PROCEDURE TIME_SERIES_UPDATED1(...)
--
procedure time_series_updated(
   p_ts_code         in number, 
   p_office_id       in varchar2, 
   p_timeseries_desc in varchar2,
   p_store_rule      in varchar2, 
   p_units           in varchar2,
   p_override_prot   in boolean, 
   p_timeseries_data in tsv_array)
is                       
   last         pls_integer;
   value_count  pls_integer;
   start_time   timestamp;
   end_time     timestamp;
   elapsed_time interval day to second;
   subset       tsv_array := tsv_array();
   i            pls_integer;
   current_size pls_integer;
   first        boolean := true;
   
begin
   value_count := p_timeseries_data.count;
   last := 25;
   subset.delete;
   while last < value_count
   loop                       
      if first then 
         current_size := 0;
         first := false;
      else
         current_size := subset.count;
      end if; 
      for i in (current_size + 1) .. last
      loop 
         subset.extend;    
         subset(i) := p_timeseries_data(i);
      end loop;      
      start_time := systimestamp;
      time_series_updated1(
         p_ts_code,
         p_office_id,
         p_timeseries_desc,
         p_store_rule,
         p_units,
         p_override_prot,
         subset);
      end_time := systimestamp;
      elapsed_time := end_time - start_time;
      dbms_output.put_line('Values = ' || last || ', time = ' || elapsed_time);
      last := last * 2;
   end loop;                    
   start_time := systimestamp;
   time_series_updated1(
      p_ts_code,
      p_office_id,
      p_timeseries_desc,
      p_store_rule,
      p_units,
      p_override_prot,
      p_timeseries_data);
   end_time := systimestamp;
   elapsed_time := end_time - start_time;
   dbms_output.put_line('Values = ' || value_count || ', time = ' || elapsed_time);

end time_series_updated;

-------------------------------------------------------------------------------
-- SYS_REFCURSOR FUNCTION GET_TS(...)
--
function get_ts(
   p_xchg_code           in  number,
   p_timestamp           in  timestamp,
   p_store_rule          out varchar2,
   p_override_protection out char, 
   p_units               out varchar2)
   return                    sys_refcursor
   
is
   xchg_info_ts_row rowid;
   ts_data          sys_refcursor;
   
begin
   if use_first_table(p_timestamp) then
      ----------------
      -- odd months --
      ----------------
      select rowid, store_rule, p_override, units
         into xchg_info_ts_row, p_store_rule, p_override_protection, p_units 
         from at_xchg_ts_info_1 
         where code = p_xchg_code and store_time = p_timestamp;
      
      open ts_data for   
      select *
         from the(
            select ts_data
               from at_xchg_ts_info_1
               where rowid = xchg_info_ts_row
         )ts
         order by ts.date_time;
   else
      -----------------
      -- even months --
      -----------------
      select rowid, store_rule, p_override, units
         into xchg_info_ts_row, p_store_rule, p_override_protection, p_units 
         from at_xchg_ts_info_2 
         where code = p_xchg_code and store_time = p_timestamp;
      
      open ts_data for   
      select *
         from the(
            select ts_data
               from at_xchg_ts_info_2
               where rowid = xchg_info_ts_row
         )ts
         order by ts.date_time;
   end if;
   
   return ts_data;

exception
   when no_data_found then 
      cwms_err.raise(
         'XCHG_NO_DATA', 
         get_table_name(p_timestamp), 
         p_xchg_code, 
         to_char(p_timestamp, iso_8601_timestamp_format)); 
      
end get_ts;

-------------------------------------------------------------------------------
-- SYS_REFCURSOR FUNCTION GET_TS_RECORDS_SINCE(...)
--
function get_ts_records_since(
   p_beginning_time in  timestamp,
   p_ts_code_list   in  varchar2)
   return               sys_refcursor
is
   sql_statement  varchar2(4096);
   ts_records     sys_refcursor;
   
begin
           
  if p_ts_code_list is null or length(p_ts_code_list) = 0 then
     --------------------------------------------
     -- static sql statement (no ts_code list) --
     --------------------------------------------
     open ts_records for 
     select * from (
        select code, store_time
          from at_xchg_ts_info_1
         where store_time >= p_beginning_time
        union all
        select code, store_time
          from at_xchg_ts_info_2
         where store_time >= p_beginning_time
        )
        order by store_time;
           
  else
     ------------------------------------------------------
     -- dynamic sql statement to accomodate ts_code list --
     ------------------------------------------------------
     sql_statement := '
        select * from (
           select code, store_time
             from at_xchg_ts_info_1
            where store_time >= :p_beginning_time
              and ts_code in (:p_ts_code_list)
           union all
           select code, store_time
             from at_xchg_ts_info_2
            where store_time >= :p_beginning_time
              and ts_code in (:p_ts_code_list)
           )
           order by store_time';
                     
     open ts_records for sql_statement using p_beginning_time, p_ts_code_list, p_beginning_time, p_ts_code_list;
     
  end if;
  
  return ts_records;

exception
   when no_data_found then null;

end get_ts_records_since;   
   
end cwms_xchg;
show errors;

SPOOL OFF
SET ECHO OFF
SET TIME OFF

