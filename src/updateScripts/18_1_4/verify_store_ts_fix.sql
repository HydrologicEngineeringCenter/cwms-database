set serveroutput on
declare
   ts_id_not_found exception;
   pragma exception_init(ts_id_not_found, -20001);
   l_office_id  varchar2(16);
   l_loc_id     varchar2(64);
   l_ts_id      varchar2(128);
   l_ts_data1   tsv_array;
   l_ts_data2   tsv_array;
   l_start_time timestamp with time zone;
   l_end_time   timestamp with time zone;
   l_cur_time   timestamp with time zone;
   l_unit       varchar2(16);
   l_count      pls_integer;
   l_date_time  date;
   l_value      binary_double;
   l_quality    integer;
   l_cursor     sys_refcursor;
   l_same_time  boolean;
   l_same_value boolean;
   l_same       boolean;
begin
   l_office_id  := 'SWT';
   l_loc_id     := 'Test-1814';
   l_ts_id      := l_loc_id||'.Code.Inst.1Hour.0.Test';
   l_unit       := 'n/a';
   ----------------------------
   -- for several time zones --
   ----------------------------
   for l_time_zone in (select column_value as value from table(str_tab_t('UTC','US/Eastern','US/Central','US/Mountain','US/Pacific'))) loop
      --------------------------
      -- for every store rule --
      --------------------------
      for l_store_rule in (select column_value as value from table(str_tab_t('DELETE INSERT', 'DO NOT REPLACE', 'REPLACE ALL', 'REPLACE MISSING VALUES ONLY', 'REPLACE WITH NON MISSING'))) loop
         ---------------------------------------------------------------------
         -- make sure the location exists and the time series doesn't exist --
         ---------------------------------------------------------------------
         cwms_loc.store_location(
            p_location_id  => l_loc_id,
            p_time_zone_id => l_time_zone.value,
            p_db_office_id => l_office_id);
         begin   
            cwms_ts.delete_ts(
               p_cwms_ts_id    => l_ts_id,
               p_delete_action => cwms_util.delete_all,
               p_db_office_id  => l_office_id);
         exception
            when ts_id_not_found then null;
         end;
         ----------------------------------------------------
         -- generate 1 year of 1Hour data in the time zone --
         ----------------------------------------------------
         l_start_time := from_tz(timestamp '2019-01-01 01:00:00', l_time_zone.value);
         l_end_time   := from_tz(timestamp '2020-01-01 00:00:00', l_time_zone.value);
         l_cur_time   := l_start_time;
         l_count      := 1;
         l_ts_data1   := tsv_array();
         while l_cur_time <= l_end_time loop
            l_ts_data1.extend;
            l_ts_data1(l_count) := tsv_type(l_cur_time, l_count, 0);
            l_count := l_count + 1;
            l_cur_time := l_cur_time + to_dsinterval('00 01:00:00');
         end loop;
         ----------------------------------------
         -- store the data with the store rule --
         ----------------------------------------
         begin      
            cwms_ts.store_ts(
               p_cwms_ts_id      => l_ts_id,
               p_units           => l_unit,
               p_timeseries_data => l_ts_data1,
               p_store_rule      => l_store_rule.value,
               p_override_prot   => 'F',
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => l_office_id);   
            commit;
         exception
            when others then
                dbms_output.put_line('Error '||sqlerrm||' Time zone = '||l_time_zone.value||', Store Rule = '||l_store_rule.value);
                continue;
         end;   
         --------------------------------------
         -- retrieve the data we just stored --
         --------------------------------------
         cwms_ts.retrieve_ts(
            p_at_tsv_rc       => l_cursor,
            p_cwms_ts_id      => l_ts_id,              
            p_units           => l_unit,              
            p_start_time      => l_start_time,                  
            p_end_time        => l_end_time,                  
            p_time_zone       => l_time_zone.value,
            p_trim            => 'F',  
            p_start_inclusive => 'T',  
            p_end_inclusive   => 'T',  
            p_previous        => 'F',  
            p_next            => 'F',  
            p_version_date    => cwms_util.non_versioned,     
            p_max_version     => 'T',  
            p_office_id       => l_office_id); 
         l_ts_data2 := tsv_array();
         loop
            fetch l_cursor into l_date_time, l_value, l_quality;
            exit when l_cursor%notfound;
            l_ts_data2.extend;
            l_ts_data2(l_ts_data2.count) := tsv_type(from_tz(cast(l_date_time as timestamp), l_time_zone.value), l_value, l_quality);
         end loop;
         close l_cursor;
         -------------------------------------------------------
         -- compare the data we retrieved with what we stored --
         -------------------------------------------------------
         l_same := true;
         if l_ts_data2.count != l_ts_data1.count then
            dbms_output.put_line('Stored '||l_ts_data1.count||' values, retrieved '||l_ts_data2.count);
            l_same := false;
         else
            for i in 1..l_ts_data1.count loop
               l_same_time  := cast(l_ts_data2(i).date_time as timestamp) = cast(l_ts_data1(i).date_time as timestamp);
               l_same_value := l_ts_data2(i).value = l_ts_data1(i).value;
               if not (l_same_time and l_same_value) then
                  l_same := false;
                  dbms_output.put_line(
                     to_char(i)
                     ||chr(9)||l_ts_data1(i).date_time
                     ||chr(9)||l_ts_data2(i).date_time
                     ||chr(9)||case when l_same_time then 'TRUE' else 'FALSE' end
                     ||chr(9)||l_ts_data1(i).value
                     ||chr(9)||l_ts_data2(i).value
                     ||chr(9)||case when l_same_value then 'TRUE' else 'FALSE' end);
               end if;
            end loop;
         end if;
         dbms_output.put_line(case when l_same then 'Data Sets Match: ' else 'Data Sets Do Not Match: ' end||'Time zone = '||l_time_zone.value||', Store Rule = '||l_store_rule.value);
      end loop;      
   end loop;
end;
/