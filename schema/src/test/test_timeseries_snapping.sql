create or replace package &&cwms_schema..test_timeseries_snapping as
--%suite(Test schema for time series snapping functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Store and retrieve regular time series)
procedure store_retrieve_rts;
--%test(Store and retrieve regular time series with zero interval offset)
procedure store_retrieve_rts_cwdb_172;
--%test(Store and retrieve local regular time series)
procedure store_retrieve_lrts;
--%test(Store and retrieve irrregular time series)
procedure store_retrieve_its;
--%test(CWDB-217 SNAP_TO_INTERVAL_OFFSET_UTC)
procedure cwdb_217_snap_to_interval_offset_utc;

procedure setup;
procedure teardown;

c_office_id            constant varchar2(16)      := '&&office_id';
c_location_id          constant varchar2(57)      := 'TestTsSnapping';
c_rts_ts_id            constant varchar2(183)     := c_location_id||'.Code.Inst.1Day.0.Test';
c_its_ts_id            constant varchar2(183)     := c_location_id||'.Code.Inst.0.0.Test';
c_lrts_ts_id           constant varchar2(183)     := c_location_id||'.Code.Inst.~1Day.0.Test';
c_time_zone            constant varchar2(28)      := 'US/Central';
c_interval_value       constant integer           := 1440; -- 1Day
c_interval_offset      constant integer           := 7 * 60; -- 7 hours into UTC or local interval
c_snap_backward        constant integer           := 8;
c_snap_forward         constant integer           := 5;
c_units                constant varchar2(16)      := 'n/a';
c_value_count          constant pls_integer       := 21;
--                                                                     Crosses Spring DST  Normal             Crosses Autum DST
--                                                                     ------------------  -----------------  -------------------
c_start_dates          constant cwms_t_date_table := cwms_t_date_table(date '2021-03-01',  date '2021-07-01', date '2021-11-01' );

c_expected_rts_values  constant cwms_t_number_tab := cwms_t_number_tab(      3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16                    );
c_expected_lrts_values constant cwms_t_number_tab := cwms_t_number_tab(      3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16                    );
c_expected_its_values  constant cwms_t_number_tab := cwms_t_number_tab(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);

end test_timeseries_snapping;
/
create or replace package body test_timeseries_snapping as
--------------------------------------------------------------------------------
-- procedure teaardown
--------------------------------------------------------------------------------
procedure teardown
is
begin
  begin
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id);
   exception when others then null; end;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_time_zone_id => c_time_zone,
      p_db_office_id => c_office_id);
end setup;
--------------------------------------------------------------------------------
-- function make_timeseries
--------------------------------------------------------------------------------
function make_timeseries(
   p_ts_type    in varchar2,
   p_start_date in date,
   p_interval_offset INTEGER)
   return cwms_t_tsv_array
is
   l_ts_values cwms_t_tsv_array := cwms_t_tsv_array();
   l_increment interval day to second := to_dsinterval('01 00:01:00'); -- one day and one minute
begin
   l_ts_values.extend(c_value_count);
   case
   when p_ts_type in ('RTS', 'ITS') then
      l_ts_values(1) := cwms_t_tsv(
         from_tz(
            cast(
               cwms_util.change_timezone(
                  p_start_date,
                  'UTC',
                  c_time_zone)
               + (p_interval_offset - 10) / 1440 as timestamp),
            c_time_zone),
         1,
         0);
      for i in 2..c_value_count loop
         l_ts_values(i) := cwms_t_tsv(
            l_ts_values(i-1).date_time  + l_increment,
            i,
            0);
      end loop;
   when p_ts_type = 'LRTS' then
      for i in 1..c_value_count loop
         l_ts_values(i) := cwms_t_tsv(
            from_tz(
               cast(
                  p_start_date + (i-1)
                  + (p_interval_offset - 10 + i - 1)/1440 as timestamp),
               c_time_zone),
            i,
            0);
      end loop;
   else
      cwms_err.raise('ERROR', 'Invalid time series type: '||p_ts_type);
   end case;
   return l_ts_values;
end make_timeseries;
--------------------------------------------------------------------------------
-- function trim_timeseries
--------------------------------------------------------------------------------
function trim_timeseries(
   p_ts_data         in cwms_t_tsv_array,
   p_interval_offset in integer,
   p_time_zone       in varchar2)
   return cwms_t_tsv_array
is
   l_ts_data cwms_t_tsv_array := cwms_t_tsv_array();
begin
   for i in 1..p_ts_data.count loop
      if cwms_ts.snap_to_interval_offset_tz(
            p_ts_data(i).date_time,
            c_interval_value,
            p_interval_offset,
            extract(timezone_region from p_ts_data(i).date_time),
            p_time_zone,
            c_snap_forward,
            c_snap_backward) is not null
      then
         l_ts_data.extend;
         l_ts_data(l_ts_data.count) := p_ts_data(i);
      end if;
   end loop;
   return l_ts_data;
end;
--------------------------------------------------------------------------------
-- procedure store_retrieve_rts
--------------------------------------------------------------------------------
procedure store_retrieve_rts
is
   l_crsr           sys_refcursor;
   l_times          cwms_t_date_table;
   l_values         cwms_t_double_tab;
   l_qualities      cwms_t_number_tab;
   l_ts_values      cwms_t_tsv_array;
   l_ts_values_2    cwms_t_tsv_array;
   l_first_time     date;
begin
   for i in 1..c_start_dates.count loop
      l_ts_values   := make_timeseries('RTS', c_start_dates(i),c_interval_offset);
      l_ts_values_2 := trim_timeseries(l_ts_values, c_interval_offset, 'UTC');

      cwms_ts.create_ts(
         p_cwms_ts_id        => c_rts_ts_id,
         p_utc_offset        => c_interval_offset,
         p_interval_forward  => c_snap_forward,
         p_interval_backward => c_snap_backward,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_office_id         => c_office_id);

      if l_ts_values_2.count < l_ts_values.count then
         begin
            cwms_ts.store_ts(
               p_cwms_ts_id      => c_rts_ts_id,
               p_units           => c_units,
               p_timeseries_data => l_ts_values,
               p_store_rule      => cwms_util.replace_all,
               p_override_prot   => 'F',
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => c_office_id);
            cwms_err.raise('ERROR', 'Expected exception not raised.');
         exception
            when others then
               if not regexp_like(
                  dbms_utility.format_error_stack,
                  '.*Incoming data set contains multiple interval offsets.*',
                  'm')
               then
                  raise;
               end if;
         end;
      end if;

      cwms_ts.store_ts(
         p_cwms_ts_id      => c_rts_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_values_2,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);

      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => c_rts_ts_id,
         p_units           => c_units,
         p_start_time      => c_start_dates(i) - 1,
         p_end_time        => c_start_dates(i) + l_ts_values_2.count + 2,
         p_time_zone       => c_time_zone,
         p_trim            => 'T',
         p_office_id       => c_office_id);

      fetch l_crsr
       bulk collect
       into l_times,
            l_values,
            l_qualities;

      close l_crsr;

      ut.expect(l_times.count).to_equal(c_expected_rts_values.count);
      l_first_time := c_start_dates(i) + 2 + c_interval_offset / 1440;
      if l_times.count = c_expected_rts_values.count then
         for j in 1..l_times.count loop
            ut.expect(cwms_util.change_timezone(l_times(j), c_time_zone, 'UTC')).to_equal(l_first_time + j - 1);
            ut.expect(l_values(j)).to_equal(c_expected_rts_values(j));
         end loop;
      end if;

      cwms_ts.delete_ts(
         p_cwms_ts_id    => c_rts_ts_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   end loop;
end store_retrieve_rts;

procedure store_retrieve_rts_cwdb_172
is
   l_crsr           sys_refcursor;
   l_times          cwms_t_date_table;
   l_values         cwms_t_double_tab;
   l_qualities      cwms_t_number_tab;
   l_ts_values      cwms_t_tsv_array;
   l_ts_values_2    cwms_t_tsv_array;
   l_first_time     date;
   l_interval_offset INTEGER := 0;
begin
   for i in 1..c_start_dates.count loop
      l_ts_values   := make_timeseries('RTS', c_start_dates(i),l_interval_offset);
      l_ts_values_2 := trim_timeseries(l_ts_values, l_interval_offset, 'UTC');

      cwms_ts.create_ts(
         p_cwms_ts_id        => c_rts_ts_id,
         p_utc_offset        => l_interval_offset,
         p_interval_forward  => c_snap_forward,
         p_interval_backward => c_snap_backward,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_office_id         => c_office_id);

      if l_ts_values_2.count < l_ts_values.count then
         begin
            cwms_ts.store_ts(
               p_cwms_ts_id      => c_rts_ts_id,
               p_units           => c_units,
               p_timeseries_data => l_ts_values,
               p_store_rule      => cwms_util.replace_all,
               p_override_prot   => 'F',
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => c_office_id);
            cwms_err.raise('ERROR', 'Expected exception not raised.');
         exception
            when others then
               if not regexp_like(
                  dbms_utility.format_error_stack,
                  '.*Incoming data set contains multiple interval offsets.*',
                  'm')
               then
                  raise;
               end if;
         end;
      end if;

      cwms_ts.store_ts(
         p_cwms_ts_id      => c_rts_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_values_2,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);

      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => c_rts_ts_id,
         p_units           => c_units,
         p_start_time      => c_start_dates(i) - 1,
         p_end_time        => c_start_dates(i) + l_ts_values_2.count + 2,
         p_time_zone       => c_time_zone,
         p_trim            => 'T',
         p_office_id       => c_office_id);

      fetch l_crsr
       bulk collect
       into l_times,
            l_values,
            l_qualities;

      close l_crsr;

      ut.expect(l_times.count).to_equal(c_expected_rts_values.count);
      l_first_time := c_start_dates(i) + 2 + l_interval_offset / 1440;
      if l_times.count = c_expected_rts_values.count then
         for j in 1..l_times.count loop
            ut.expect(cwms_util.change_timezone(l_times(j), c_time_zone, 'UTC')).to_equal(l_first_time + j - 1);
            ut.expect(l_values(j)).to_equal(c_expected_rts_values(j));
         end loop;
      end if;

      cwms_ts.delete_ts(
         p_cwms_ts_id    => c_rts_ts_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   end loop;
end store_retrieve_rts_cwdb_172;

--------------------------------------------------------------------------------
-- procedure store_retrieve_lrts
--------------------------------------------------------------------------------
procedure store_retrieve_lrts
is
   l_crsr        sys_refcursor;
   l_times       cwms_t_date_table;
   l_values      cwms_t_double_tab;
   l_qualities   cwms_t_number_tab;
   l_ts_values   cwms_t_tsv_array;
   l_ts_values_2 cwms_t_tsv_array;
   l_first_time  date;
begin
   for i in 1..c_start_dates.count loop
      l_ts_values   := make_timeseries('LRTS', c_start_dates(i), c_interval_offset);
      l_ts_values_2 := trim_timeseries(l_ts_values, c_interval_offset, c_time_zone);

      cwms_ts.create_ts(
         p_cwms_ts_id        => c_lrts_ts_id,
         p_utc_offset        => c_interval_offset,
         p_interval_forward  => c_snap_forward,
         p_interval_backward => c_snap_backward,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_office_id         => c_office_id);

      if l_ts_values_2.count < l_ts_values.count then
         begin
            cwms_ts.store_ts(
               p_cwms_ts_id      => c_rts_ts_id,
               p_units           => c_units,
               p_timeseries_data => l_ts_values,
               p_store_rule      => cwms_util.replace_all,
               p_override_prot   => 'F',
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => c_office_id);
            cwms_err.raise('ERROR', 'Expected exception not raised.');
         exception
            when others then
               if not regexp_like(
                  dbms_utility.format_error_stack,
                  '.*Incoming data set contains multiple interval offsets.*',
                  'm')
               then
                  raise;
               end if;
         end;
      end if;

      cwms_ts.store_ts(
         p_cwms_ts_id      => c_lrts_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_values_2,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);


      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => c_lrts_ts_id,
         p_units           => c_units,
         p_start_time      => c_start_dates(i) - 1,
         p_end_time        => c_start_dates(i) + l_ts_values.count + 2,
         p_time_zone       => c_time_zone,
         p_trim            => 'T',
         p_office_id       => c_office_id);

      fetch l_crsr
       bulk collect
       into l_times,
            l_values,
            l_qualities;

      close l_crsr;

      ut.expect(l_times.count).to_equal(c_expected_lrts_values.count);
      l_first_time := c_start_dates(i) + 2 + c_interval_offset / 1440;
      if l_times.count = c_expected_rts_values.count then
         for j in 1..l_times.count loop
            ut.expect(l_times(j)).to_equal(l_first_time + j - 1);
            ut.expect(l_values(j)).to_equal(c_expected_rts_values(j));
         end loop;
      end if;

      cwms_ts.delete_ts(
         p_cwms_ts_id    => c_lrts_ts_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   end loop;
end store_retrieve_lrts;
--------------------------------------------------------------------------------
-- procedure store_retrieve_its
--------------------------------------------------------------------------------
procedure store_retrieve_its
is
   l_crsr      sys_refcursor;
   l_times     cwms_t_date_table;
   l_values    cwms_t_double_tab;
   l_qualities cwms_t_number_tab;
   l_ts_values cwms_t_tsv_array;
   l_dst_times cwms_t_date_table;
begin
   for i in 1..c_start_dates.count loop
      l_ts_values      := make_timeseries('ITS', c_start_dates(i),c_interval_offset);

      cwms_ts.create_ts(
         p_cwms_ts_id        => c_its_ts_id,
         p_utc_offset        => c_interval_offset,
         p_interval_forward  => c_snap_forward,
         p_interval_backward => c_snap_backward,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_office_id         => c_office_id);

      cwms_ts.store_ts(
         p_cwms_ts_id      => c_its_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_values,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);


      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => c_its_ts_id,
         p_units           => c_units,
         p_start_time      => c_start_dates(i) - 1,
         p_end_time        => c_start_dates(i) + l_ts_values.count + 1,
         p_time_zone       => c_time_zone,
         p_trim            => 'T',
         p_office_id       => c_office_id);

      fetch l_crsr
       bulk collect
       into l_times,
            l_values,
            l_qualities;

      close l_crsr;

      ut.expect(l_times.count).to_equal(c_expected_its_values.count);
      if l_times.count = c_expected_rts_values.count then
         for j in 1..l_times.count loop
            ut.expect(l_times(j)).to_equal(cast(l_ts_values(j).date_time as date));
            l_dst_times := cwms_ts.dst_times(c_time_zone, l_times(j));
            if l_dst_times(2) is not null and l_times(j) = l_dst_times(2) - 1/24 then
               ut.expect(l_values(j)).to_be_null;
            else
               ut.expect(l_values(j)).to_equal(c_expected_rts_values(j));
            end if;
         end loop;
      end if;

      cwms_ts.delete_ts(
         p_cwms_ts_id    => c_its_ts_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   end loop;
end store_retrieve_its;
--------------------------------------------------------------------------------
-- procedure procedure cwdb_217_snap_to_interval_offset_utc
--------------------------------------------------------------------------------
procedure cwdb_217_snap_to_interval_offset_utc
is
   type clob_tab_t is table of clob;
   l_lines             cwms_t_str_tab;
   l_parts             cwms_t_str_tab;
   l_interval          pls_integer;
   l_interval_offset   pls_integer;
   l_interval_forward  pls_integer;
   l_interval_backward pls_integer;
   l_timestamp         timestamp;
   l_snapped           timestamp;
   l_expected          timestamp;
   l_clobs clob_tab_t := clob_tab_t(
      -- Interval  1 hour
      -- Offset   15 minutes
      -- Forward  24 minutes
      -- Backward 25 minutes
      '60,15,24,25
      2023/05/01 00:00|2023/05/01 00:15
      2023/05/01 00:05|2023/05/01 00:15
      2023/05/01 00:10|2023/05/01 00:15
      2023/05/01 00:15|2023/05/01 00:15
      2023/05/01 00:20|2023/05/01 00:15
      2023/05/01 00:25|2023/05/01 00:15
      2023/05/01 00:30|2023/05/01 00:15
      2023/05/01 00:35|2023/05/01 00:15
      2023/05/01 00:40|
      2023/05/01 00:45|
      2023/05/01 00:50|2023/05/01 01:15
      2023/05/01 00:55|2023/05/01 01:15',
      -- Interval 6 hours
      -- Offset   1 hour + 15 minutes
      -- Forward  2 hours
      -- Backward 2 hours
      '360,75,120,120
      2023/05/01 00:00|2023/05/01 01:15
      2023/05/01 00:15|2023/05/01 01:15
      2023/05/01 00:30|2023/05/01 01:15
      2023/05/01 00:45|2023/05/01 01:15
      2023/05/01 01:00|2023/05/01 01:15
      2023/05/01 01:15|2023/05/01 01:15
      2023/05/01 01:30|2023/05/01 01:15
      2023/05/01 01:45|2023/05/01 01:15
      2023/05/01 02:00|2023/05/01 01:15
      2023/05/01 02:15|2023/05/01 01:15
      2023/05/01 02:30|2023/05/01 01:15
      2023/05/01 02:45|2023/05/01 01:15
      2023/05/01 03:00|2023/05/01 01:15
      2023/05/01 03:15|2023/05/01 01:15
      2023/05/01 03:30|
      2023/05/01 03:45|
      2023/05/01 04:00|
      2023/05/01 04:15|
      2023/05/01 04:30|
      2023/05/01 04:45|
      2023/05/01 05:00|
      2023/05/01 05:15|2023/05/01 07:15
      2023/05/01 05:30|2023/05/01 07:15
      2023/05/01 05:45|2023/05/01 07:15',
      -- Interval  1 day
      -- Offset    7 hours
      -- Forward   9 hours
      -- Backward 10 hours
      '1440,420,540,600
      2023/05/01 00:00|2023/05/01 07:00
      2023/05/01 01:00|2023/05/01 07:00
      2023/05/01 02:00|2023/05/01 07:00
      2023/05/01 03:00|2023/05/01 07:00
      2023/05/01 04:00|2023/05/01 07:00
      2023/05/01 05:00|2023/05/01 07:00
      2023/05/01 06:00|2023/05/01 07:00
      2023/05/01 07:00|2023/05/01 07:00
      2023/05/01 08:00|2023/05/01 07:00
      2023/05/01 09:00|2023/05/01 07:00
      2023/05/01 10:00|2023/05/01 07:00
      2023/05/01 11:00|2023/05/01 07:00
      2023/05/01 12:00|2023/05/01 07:00
      2023/05/01 13:00|2023/05/01 07:00
      2023/05/01 14:00|2023/05/01 07:00
      2023/05/01 15:00|2023/05/01 07:00
      2023/05/01 16:00|2023/05/01 07:00
      2023/05/01 17:00|
      2023/05/01 18:00|
      2023/05/01 19:00|
      2023/05/01 20:00|
      2023/05/01 21:00|2023/05/02 07:00
      2023/05/01 22:00|2023/05/02 07:00
      2023/05/01 23:00|2023/05/02 07:00',
      -- Interval 1 month
      -- Offset   2 days + 7 hours
      -- Forward  3 days
      -- Backward 4 days
      '43200,3300,4320,5760
      2023/05/01 07:00|2023/05/03 07:00
      2023/05/02 07:00|2023/05/03 07:00
      2023/05/03 07:00|2023/05/03 07:00
      2023/05/04 07:00|2023/05/03 07:00
      2023/05/05 07:00|2023/05/03 07:00
      2023/05/06 07:00|2023/05/03 07:00
      2023/05/07 07:00|
      2023/05/08 07:00|
      2023/05/28 07:00|
      2023/05/29 07:00|
      2023/05/30 07:00|2023/06/03 07:00
      2023/05/31 07:00|2023/06/03 07:00');

begin
   for i in 1..l_clobs.count loop
      l_lines := cwms_util.split_text(l_clobs(i), chr(10));
      l_parts := cwms_util.split_text(trim(l_lines(1)), ',');
      l_interval          := l_parts(1);
      l_interval_offset   := l_parts(2);
      l_interval_forward  := l_parts(3);
      l_interval_backward := l_parts(4);
      for j in 2..l_lines.count loop
         l_parts := cwms_util.split_text(l_lines(j), '|');
         l_timestamp := to_date(l_parts(1), 'yyyy/mm/dd hh24:mi');
         l_expected  := to_date(l_parts(2), 'yyyy/mm/dd hh24:mi');
         -------------------------------------------
         -- first test SNAP_TO_INTERVAL_OFFSET_TZ --
         -------------------------------------------
         l_snapped   := cwms_ts.snap_to_interval_offset_tz(
            p_date_time         => l_timestamp,
            p_interval          => l_interval,
            p_interval_offset   => l_interval_offset,
            p_time_zone         => 'US/Central',
            p_offset_time_zone  => 'US/Central',
            p_interval_forward  => l_interval_forward,
            p_interval_backward => l_interval_backward);

         if l_expected is null then
            ut.expect(l_snapped).to_be_null;
         else
            ut.expect(l_snapped).to_equal(l_expected);
         end if;
         -------------------------------------------
         -- next test SNAP_TO_INTERVAL_OFFSET_UTC --
         -------------------------------------------
         l_snapped   := cwms_ts.snap_to_interval_offset_utc(
            p_date_time         => l_timestamp,
            p_interval          => l_interval,
            p_interval_offset   => l_interval_offset,
            p_interval_forward  => l_interval_forward,
            p_interval_backward => l_interval_backward);

         if l_expected is null then
            ut.expect(l_snapped).to_be_null;
         else
            ut.expect(l_snapped).to_equal(l_expected);
         end if;
      end loop;
   end loop;
end cwdb_217_snap_to_interval_offset_utc;
end test_timeseries_snapping;
/

grant execute on test_timeseries_snapping to cwms_user;
