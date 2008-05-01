set serveroutput on;

declare
   l_tsinfo     timeseries_array := timeseries_array();
   l_tsdata     tsv_array        := tsv_array();
   
   l_tsid       varchar2(183)  := 'Test-storeTs.Flow.Inst.1Hour.0.test';
   l_units      varchar2(16)   := 'cfs';
   l_start_time date           := to_date('2006/02/01-00:15:00', 'yyyy/mm/dd-hh24:mi:ss'); 
   l_end_time   date           := to_date('2006/02/01-23:15:00', 'yyyy/mm/dd-hh24:mi:ss'); 
   l_cursor     sys_refcursor;
   l_cursor2    sys_refcursor;
   l_date_time  date;
   l_value      binary_double;
   l_quality    number;
   l_tsrequest  timeseries_req_array := timeseries_req_array();
   l_sequence   integer;
   i            pls_integer;
   l_ts_begin   timestamp;
   l_ts_end     timestamp;
   l_intvl      interval day to second;
begin
   dbms_output.put_line('==>Creating data at ' || systimestamp);
   --
   -- create the data
   --
   l_date_time := l_start_time;
   i := 1;
   loop
      exit when l_date_time > l_end_time;
      if i < 4 or (i > 10 and i < 14) or i = 24then
         null;
      else
         l_tsdata.extend;
         l_tsdata(l_tsdata.last) := tsv_type(from_tz(l_date_time, 'UTC'), i, 0);
         if i > 20 then
            l_tsdata(l_tsdata.last).quality_code := 5;
         end if; 
      end if;
      i := i + 1;
      l_date_time := l_date_time + 1 / 24;
   end loop;
   l_tsinfo.extend(4);
   l_tsinfo(1) := timeseries_type('Tester-id1.Flow.Inst.0.0.test',     'kcfs', l_tsdata);
   l_tsinfo(2) := timeseries_type('Tester-id2.Flow.Inst.1Hour.0.test', 'kcfs', l_tsdata);
   l_tsinfo(3) := timeseries_type('Tester-id3.Flow.Inst.0.0.test',     'cms',  l_tsdata);
   l_tsinfo(4) := timeseries_type('Tester-id4.Flow.Inst.1Hour.0.test', 'cms',  l_tsdata);
   --
   -- delete any existing data
   --
   l_ts_begin := systimestamp;
   dbms_output.put_line('==>Starting delete at ' || l_ts_begin);
   for i in 1..l_tsinfo.count loop
      begin
         cwms_ts.delete_ts(l_tsinfo(i).tsid, cwms_util.delete_ts_cascade, 'NAB');
      exception
         when others then
            if instr(sqlerrm, 'TS_ID_NOT_FOUND') != 0 then
               null;
            end if;
      end;
   end loop;
   l_ts_end := systimestamp;
   l_intvl  := l_ts_end - l_ts_begin; 
   dbms_output.put_line('==>Delete done at ' || l_ts_end || ' (' || l_intvl || ')');
   --
   -- store the data
   --
   l_ts_begin := systimestamp;
   dbms_output.put_line('==>Starting multi-store at ' || l_ts_begin);
   cwms_ts.store_ts_multi(l_tsinfo,cwms_util.delete_insert,'F',cwms_util.non_versioned,'NAB');
   commit;
   l_ts_end := systimestamp;
   l_intvl  := l_ts_end - l_ts_begin; 
   dbms_output.put_line('==>Multi-store done at ' || l_ts_end || ' (' || l_intvl || ')');
   --
   -- retrieve the data in a loop
   --
   dbms_output.put_line(to_char(l_start_time, 'yyyy/mm/dd-hh24:mi:ss'));
   dbms_output.put_line(to_char(l_end_time,   'yyyy/mm/dd-hh24:mi:ss'));
   l_ts_begin := systimestamp;
   dbms_output.put_line('==>Starting retrieve loop at ' || l_ts_begin);
   for i in 1..l_tsinfo.count loop
      dbms_output.put_line('-----------------------------------------');
      dbms_output.put_line(l_tsinfo(i).tsid);
      cwms_ts.retrieve_ts(
         l_cursor,
         l_tsinfo(i).tsid,
         l_units,
         l_start_time,
         l_end_time,
         'US/Central', -- time zone
         'F',          -- trim
         'T',          -- start inclusive
         'T',          -- end inclusive
         'T',          -- previous
         'T',          -- next
          null,        -- version date
         'T',          -- max version
         'NAB');       -- office id
      loop
         fetch l_cursor into l_date_time, l_value, l_quality;
         exit when l_cursor%notfound;
         if l_value is null then
            dbms_output.put_line(
               '' 
               || nvl(to_char(l_date_time, 'yyyy/mm/dd-hh24:mi:ss'), ' <null> ')
               || ' <null> ' 
               || l_quality);
         else
            dbms_output.put_line(
               '' 
               || nvl(to_char(l_date_time, 'yyyy/mm/dd-hh24:mi:ss'), ' <null> ')
               || ' ' 
               || l_value
               || ' ' 
               || l_quality);
         end if;
      end loop;
      close l_cursor;
   end loop;
   l_ts_end := systimestamp;
   l_intvl  := l_ts_end - l_ts_begin; 
   dbms_output.put_line('==>Retrieve loop done at ' || l_ts_end || ' (' || l_intvl || ')');
   --
   -- retrieve the data with retrive_ts2_multi
   --
   dbms_output.put_line('-----------------------------------------');
   l_tsrequest.extend(l_tsinfo.count);
   for i in 1..l_tsinfo.count loop
      l_tsrequest(i) := timeseries_req_type(l_tsinfo(i).tsid, l_units, l_start_time, l_end_time);
   end loop;
   l_ts_begin := systimestamp;
   dbms_output.put_line('==>Starting multi-retrieve at ' || l_ts_begin);
   cwms_ts.retrieve_ts_multi(
      l_cursor,
      l_tsrequest,
      'US/Central', -- time zone
      'F',     -- trim
      'T',     -- start inclusive
      'T',     -- end inclusive
      'T',     -- previous
      'T',     -- next
      null,    -- version date
      'T',     -- max version
      'NAB');  -- office
   l_ts_end := systimestamp;
   l_intvl  := l_ts_end - l_ts_begin; 
   dbms_output.put_line('==>Multi-retrieve done at ' || l_ts_end || ' (' || l_intvl || ')');
   loop
      fetch l_cursor into l_sequence, l_tsid, l_units, l_start_time, l_end_time, l_cursor2;
      exit when l_cursor%notfound;
      dbms_output.put_line( 
         ''  || l_sequence 
             || ' ' || l_tsid 
             || ' ' || l_units
             || ' ' || to_char(l_start_time, 'yyyy/mm/dd-hh24:mi:ss')
             || ' ' || to_char(l_end_time, 'yyyy/mm/dd-hh24:mi:ss'));
      loop
         fetch l_cursor2 into l_date_time, l_value, l_quality;
         exit when l_cursor2%notfound;
         if l_value is null then
            dbms_output.put_line(
               '----> ' 
               || to_char(l_date_time, 'yyyy/mm/dd-hh24:mi:ss') 
               || ' <null> ' 
               || l_quality);
         else
            dbms_output.put_line(
               '----> ' 
               || to_char(l_date_time, 'yyyy/mm/dd-hh24:mi:ss') 
               || ' ' 
               || l_value
               || ' ' 
               || l_quality);
         end if;
      end loop;
      close l_cursor2;
   end loop;
   close l_cursor;
end;
/


