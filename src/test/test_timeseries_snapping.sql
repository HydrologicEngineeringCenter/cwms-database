create or replace package &&cwms_schema..test_timeseries_snapping as
--%suite(Test schema for time series snapping functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Store and retrieve regular time series)
procedure store_retrieve_rts;
--%test(Store and retrieve local regular time series)
procedure store_retrieve_lrts;
--%test(Store and retrieve irrregular time series)
procedure store_retrieve_its;

procedure setup;
procedure teardown;

c_office_id            constant varchar2(16)      := '&&office_id';
c_location_id          constant varchar2(57)      := 'TestTsSnapping';
c_rts_ts_id            constant varchar2(183)     := c_location_id||'.Code.Inst.1Day.0.Test';
c_its_ts_id            constant varchar2(183)     := c_location_id||'.Code.Inst.0.0.Test';
c_lrts_ts_id           constant varchar2(183)     := c_location_id||'.Code.Inst.~1Day.0.Test';
c_time_zone            constant varchar2(28)      := 'US/Central';
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
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id);
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
   p_start_date in date)
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
               + (c_interval_offset - 10) / 1440 as timestamp),
            c_time_zone),
         1,
         0);
      for i in 2..21 loop
         l_ts_values(i) := cwms_t_tsv(
            l_ts_values(i-1).date_time  + l_increment,
            i,
            0);
      end loop;
   when p_ts_type = 'LRTS' then
      for i in 1..21 loop
         l_ts_values(i) := cwms_t_tsv(
            from_tz(
               cast(
                  p_start_date + (i-1)
                  + (c_interval_offset - 10 + i - 1)/1440 as timestamp),
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
-- procedure store_retrieve_rts
--------------------------------------------------------------------------------
procedure store_retrieve_rts
is
   l_crsr           sys_refcursor;
   l_times          cwms_t_date_table;
   l_values         cwms_t_double_tab;
   l_qualities      cwms_t_number_tab;
   l_ts_values      cwms_t_tsv_array;
   l_dst_times      cwms_t_date_table;
   l_first_time     date;
begin
   for i in 1..c_start_dates.count loop
      l_ts_values      := make_timeseries('RTS', c_start_dates(i));

      cwms_ts.create_ts(
         p_cwms_ts_id        => c_rts_ts_id,
         p_utc_offset        => c_interval_offset,
         p_interval_forward  => c_snap_forward,
         p_interval_backward => c_snap_backward,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_office_id         => c_office_id);

      cwms_ts.store_ts(
         p_cwms_ts_id      => c_rts_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_values,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);

      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => c_rts_ts_id,
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

      ut.expect(l_times.count).to_equal(c_expected_rts_values.count);
      l_first_time := c_start_dates(i) + 2 + c_interval_offset / 1440;
      if l_times.count = c_expected_rts_values.count then
         for j in 1..l_times.count loop
            ut.expect(cwms_util.change_timezone(l_times(j), c_time_zone, 'UTC')).to_equal(l_first_time + j - 1);
            l_dst_times := cwms_ts.dst_times(c_time_zone, l_times(j));
            if l_dst_times(2) is not null and l_times(j) = l_dst_times(2) - 1/24 then
               ut.expect(l_values(j)).to_be_null;
            else
               ut.expect(l_values(j)).to_equal(c_expected_rts_values(j));
            end if;
         end loop;
      end if;

      cwms_ts.delete_ts(
         p_cwms_ts_id    => c_rts_ts_id,
         p_delete_action => cwms_util.delete_all,
         p_db_office_id  => c_office_id);
   end loop;
end store_retrieve_rts;
--------------------------------------------------------------------------------
-- procedure store_retrieve_lrts
--------------------------------------------------------------------------------
procedure store_retrieve_lrts
is
   l_crsr      sys_refcursor;
   l_times     cwms_t_date_table;
   l_values    cwms_t_double_tab;
   l_qualities cwms_t_number_tab;
   l_ts_values cwms_t_tsv_array;
   l_dst_times cwms_t_date_table;
   l_first_time     date;
begin
   for i in 1..c_start_dates.count loop
      l_ts_values      := make_timeseries('LRTS', c_start_dates(i));

      cwms_ts.create_ts(
         p_cwms_ts_id        => c_lrts_ts_id,
         p_utc_offset        => c_interval_offset,
         p_interval_forward  => c_snap_forward,
         p_interval_backward => c_snap_backward,
         p_versioned         => 'F',
         p_active_flag       => 'T',
         p_office_id         => c_office_id);

      cwms_ts.store_ts(
         p_cwms_ts_id      => c_lrts_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_values,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => c_office_id);


      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => c_lrts_ts_id,
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

      ut.expect(l_times.count).to_equal(c_expected_lrts_values.count);
      l_first_time := c_start_dates(i) + 2 + c_interval_offset / 1440;
      if l_times.count = c_expected_rts_values.count then
         for j in 1..l_times.count loop
            ut.expect(l_times(j)).to_equal(l_first_time + j - 1);
            l_dst_times := cwms_ts.dst_times(c_time_zone, l_times(j));
            if l_dst_times(2) is not null and l_times(j) = l_dst_times(2) - 1/24 then
               ut.expect(l_values(j)).to_be_null;
            else
               ut.expect(l_values(j)).to_equal(c_expected_rts_values(j));
            end if;
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
      l_ts_values      := make_timeseries('ITS', c_start_dates(i));

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

end test_timeseries_snapping;
/

grant execute on test_timeseries_snapping to cwms_user;
