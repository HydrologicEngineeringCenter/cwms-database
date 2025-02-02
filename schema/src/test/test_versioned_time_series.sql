create or replace package &cwms_schema..test_versioned_time_series as
--%suite(Test schema for versioned time series functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Store and retrieve non-versioned and versioned time series)
procedure store_retrieve_time_series;
--%test(Test whether time series versioned flag is effective)
procedure cwdb_151;
--%test(Test retrieve_ts_multi with aliases)
procedure retrieve_ts_multi_test;

procedure setup;
procedure teardown;

c_office_id       constant varchar2(16)     := '&&office_id';
c_location_id     constant varchar2(57)     := 'TestVersionedTS';
c_ts_id           constant varchar2(183)    := c_location_id||'.Code.Inst.1Hour.0.Test';
c_units           constant varchar2(16)     := 'n/a';
c_start_time      constant date             := date '2021-08-01';       -- 2021-08-01 00:00
c_end_time        constant date             := c_start_time + 1;        -- 2021-08-02 00:00
c_value_count     constant pls_integer      := 21;
c_version_dates   constant date_table_type  := date_table_type(
                                                  c_start_time + 1/24,  -- 2021-08-01 01:00
                                                  c_start_time + 2/24,  -- 2021-08-01 02:00
                                                  c_start_time + 3/24,  -- 2021-08-01 03:00
                                                  c_start_time + 4/24); -- 2021-08-01 04:00
c_expected_values constant double_tab_tab_t := double_tab_tab_t(
                                                  double_tab_t(   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,null,null,null,null),  -- (1) non-versioned
                                                  double_tab_t(null,1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,null,null,null),  -- (2) c_version_dates(1)
                                                  double_tab_t(null,null,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,null,null),  -- (3) c_version_dates(1)
                                                  double_tab_t(null,null,null,3003,3004,3005,3006,3007,3008,3009,3010,3011,3012,3013,3014,3015,3016,3017,3018,3019,3020,3021,3022,3023,null),  -- (4) c_version_dates(1)
                                                  double_tab_t(null,null,null,null,4004,4005,4006,4007,4008,4009,4010,4011,4012,4013,4014,4015,4016,4017,4018,4019,4020,4021,4022,4023,4024),  -- (5) c_version_dates(1)
                                                  double_tab_t(   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,1021,2022,3023,4024),  -- (6) min version date, original data
                                                  double_tab_t(   0,1001,2002,3003,4004,4005,4006,4007,4008,4009,4010,4011,4012,4013,4014,4015,4016,4017,4018,4019,4020,4021,4022,4023,4024),  -- (7) max version date, original data
                                                  double_tab_t( 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,1021,2022,3023,4024),  -- (8) min version date, updated data
                                                  double_tab_t( 100,1001,2002,3003,4004,4005,4006,4007,4008,4009,4010,4011,4012,4013,4014,4015,4016,4017,4018,4019,4020,4021,4022,4023,4024)); -- (9) max version date, updated data
end test_versioned_time_series;
/
create or replace package body test_versioned_time_series as
--------------------------------------------------------------------------------
-- procedure teaardown
--------------------------------------------------------------------------------
procedure teardown
is
   x_location_id_not_found exception;
   pragma exception_init(x_location_id_not_found, -20025);
begin
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id);
exception
   when x_location_id_not_found then null;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  => c_location_id,
      p_db_office_id => c_office_id);
end setup;
--------------------------------------------------------------------------------
-- procedure store_retrieve_time_series
--------------------------------------------------------------------------------
procedure store_retrieve_time_series
is
   l_ts_data    ztsv_array := ztsv_array();
   l_crsr       sys_refcursor;

   procedure verify_retrieved_data(
      p_crsr            in sys_refcursor,
      p_expected_values in double_tab_t)
   is
      l_date_times date_table_type;
      l_values     number_tab_t;
      l_qualities  number_tab_t;
   begin
      fetch p_crsr
       bulk collect
       into l_date_times,
            l_values,
            l_qualities
      limit c_value_count + c_version_dates.count;
      ut.expect(p_crsr%rowcount).to_equal(p_expected_values.count);
      if l_values.count = p_expected_values.count then
         for i in 1..p_expected_values.count loop
            if p_expected_values(i) is null then
               ut.expect(l_values(i)).to_be_null;
            else
               ut.expect(l_values(i)).to_equal(p_expected_values(i));
            end if;
         end loop;
      else
         for i in 1..l_date_times.count loop
            dbms_output.put_line(chr(9)||i||chr(9)||l_date_times(i)||chr(9)||round(to_number(l_values(i)), 9)||chr(9)||l_qualities(i));
         end loop;
      end if;
   end verify_retrieved_data;
begin
   -----------------------------
   -- create the base ts_data --
   -----------------------------
   for i in 1..c_value_count loop
      l_ts_data.extend;
      l_ts_data(i) := ztsv_type(c_start_time + (i-1) / 24, i-1, 0);
   end loop;
   ----------------------------------------------
   -- store the time series as a non-versioned --
   ----------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id);
   ------------------------------------------------
   -- retrieve and verify the non-versioned data --
   ------------------------------------------------
   cwms_ts.zretrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_units        => c_units,
      p_cwms_ts_id   => c_ts_id,
      p_start_time   => c_start_time,
      p_end_time     => c_end_time,
      p_trim         => 'F',
      p_db_office_id => c_office_id);

   verify_retrieved_data(
      p_crsr            => l_crsr,
      p_expected_values => c_expected_values(1));
   close l_crsr;
   --------------------------------------
   -- set the time series to versioned --
   --------------------------------------
   cwms_ts.set_tsid_versioned(
      p_cwms_ts_id   => c_ts_id,
      p_versioned    => 'T',
      p_db_office_id => c_office_id);
   ------------------------------
   -- store the versioned data --
   ------------------------------
   for i in 1..c_version_dates.count loop
      for j in 1..l_ts_data.count loop
         l_ts_data(j).date_time := l_ts_data(j).date_time + 1 / 24;
         l_ts_data(j).value     := i * 1000 + i + j - 1;
      end loop;
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => c_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => c_version_dates(i),
         p_office_id       => c_office_id);
   end loop;
   ----------------------------------------------
   -- retrieve and verify the min version data --
   ----------------------------------------------
   cwms_ts.zretrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_units        => c_units,
      p_cwms_ts_id   => c_ts_id,
      p_start_time   => c_start_time,
      p_end_time     => c_end_time,
      p_trim         => 'F',
      p_version_date => null,
      p_max_version  => 'F',
      p_db_office_id => c_office_id);

   verify_retrieved_data(
      p_crsr            => l_crsr,
      p_expected_values => c_expected_values(6));
   close l_crsr;
   ----------------------------------------------------------
   -- retrieve and verify each version of the  time series --
   ----------------------------------------------------------
   cwms_ts.zretrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_units        => c_units,
      p_cwms_ts_id   => c_ts_id,
      p_start_time   => c_start_time,
      p_end_time     => c_end_time,
      p_trim         => 'F',
      p_version_date => cwms_util.non_versioned,
      p_db_office_id => c_office_id);

   verify_retrieved_data(
      p_crsr            => l_crsr,
      p_expected_values => c_expected_values(1));
   close l_crsr;

   for j in 1..c_version_dates.count loop
      cwms_ts.zretrieve_ts(
         p_at_tsv_rc    => l_crsr,
         p_units        => c_units,
         p_cwms_ts_id   => c_ts_id,
         p_start_time   => c_start_time,
         p_end_time     => c_end_time,
         p_trim         => 'F',
         p_version_date => c_version_dates(j),
         p_db_office_id => c_office_id);

      verify_retrieved_data(
         p_crsr            => l_crsr,
         p_expected_values => c_expected_values(j+1));
      close l_crsr;
   end loop;
   ----------------------------------------------
   -- retrieve and verify the max version data --
   ----------------------------------------------
   cwms_ts.zretrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_units        => c_units,
      p_cwms_ts_id   => c_ts_id,
      p_start_time   => c_start_time,
      p_end_time     => c_end_time,
      p_trim         => 'F',
      p_version_date => null,
      p_max_version  => 'T',
      p_db_office_id => c_office_id);

   verify_retrieved_data(
      p_crsr            => l_crsr,
      p_expected_values => c_expected_values(7));
   close l_crsr;
   -------------------------------------------------------------------
   -- re-store the base data as non-versioned with different values --
   -------------------------------------------------------------------
   for i in 1..c_value_count loop
      l_ts_data(i) := ztsv_type(c_start_time + (i-1) / 24, 100 + i - 1, 0);
   end loop;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id);
   -------------------------------------------------
   -- re-retrieve and verify the min version data --
   -------------------------------------------------
   cwms_ts.zretrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_units        => c_units,
      p_cwms_ts_id   => c_ts_id,
      p_start_time   => c_start_time,
      p_end_time     => c_end_time,
      p_trim         => 'F',
      p_version_date => null,
      p_max_version  => 'F',
      p_db_office_id => c_office_id);

   verify_retrieved_data(
      p_crsr            => l_crsr,
      p_expected_values => c_expected_values(8));
   close l_crsr;
   -------------------------------------------------
   -- re-retrieve and verify the max version data --
   -------------------------------------------------
   cwms_ts.zretrieve_ts(
      p_at_tsv_rc    => l_crsr,
      p_units        => c_units,
      p_cwms_ts_id   => c_ts_id,
      p_start_time   => c_start_time,
      p_end_time     => c_end_time,
      p_trim         => 'F',
      p_version_date => null,
      p_max_version  => 'T',
      p_db_office_id => c_office_id);

   verify_retrieved_data(
      p_crsr            => l_crsr,
      p_expected_values => c_expected_values(9));
   close l_crsr;
end store_retrieve_time_series;
--------------------------------------------------------------------------------
-- procedure cwdb_151
--------------------------------------------------------------------------------
procedure cwdb_151
is
   l_ts_id         varchar2(183)     := replace(c_ts_id, '1Hour', '1Day');
   l_ts_data       cwms_t_ztsv_array := cwms_t_ztsv_array(cwms_t_ztsv(date '2022-01-01', 1, 0),cwms_t_ztsv(date '2022-01-02', 2, 0));
   l_ts_code       integer;
   l_version_dates cwms_t_date_table;
   l_date_times    cwms_t_date_table;
   l_values        cwms_t_double_tab;
   l_current_time  date;
begin
   --------------------------------
   -- create ts as non-versioned --
   --------------------------------
   cwms_ts.create_ts_code(
      p_ts_code           => l_ts_code,
      p_cwms_ts_id        => l_ts_id,
      p_utc_offset        => null,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_fail_if_exists    => 'T',
      p_office_id         => c_office_id);
   ---------------------------------------------------
   -- store non-versioned ts with null version date --
   ---------------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => null,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'F');
   ---------------------------------
   -- verify expected data stored --
   ---------------------------------
   select version_date,
          date_time,
          value
     bulk collect
     into l_version_dates,
          l_date_times,
          l_values
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_units
    order by 1, 2, 3;

   ut.expect(l_version_dates.count).to_equal(l_ts_data.count);
   if l_version_dates.count = l_ts_data.count then
      for i in 1..l_ts_data.count loop
         ut.expect(l_version_dates(i)).to_equal(cwms_util.non_versioned);
         ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
         ut.expect(l_values(i)).to_equal(l_ts_data(i).value);
      end loop;
   end if;
   -------------------------------------------------------
   -- store non-versioned ts with non-null version date --
   -------------------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => sysdate,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'F');
   ---------------------------------
   -- verify expected data stored --
   ---------------------------------
   select version_date,
          date_time,
          value
     bulk collect
     into l_version_dates,
          l_date_times,
          l_values
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_units
    order by 1, 2, 3;

   ut.expect(l_version_dates.count).to_equal(l_ts_data.count);
   if l_version_dates.count = l_ts_data.count then
      for i in 1..l_ts_data.count loop
         ut.expect(l_version_dates(i)).to_equal(cwms_util.non_versioned);
         ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
         ut.expect(l_values(i)).to_equal(l_ts_data(i).value);
      end loop;
   end if;
   -------------------------------
   -- modify ts to be versioned --
   -------------------------------
   cwms_ts.set_ts_versioned(
      p_cwms_ts_code => l_ts_code,
      p_versioned    => 'T');
   -----------------------------------------------
   -- store versioned ts with null version date --
   -----------------------------------------------
   l_current_time := sysdate;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => l_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => null,
      p_office_id       => c_office_id,
      p_create_as_lrts  => 'F');
   ---------------------------------
   -- verify expected data stored --
   ---------------------------------
   select version_date,
          date_time,
          value
     bulk collect
     into l_version_dates,
          l_date_times,
          l_values
     from cwms_v_tsv_dqu
    where ts_code = l_ts_code
      and unit_id = c_units
    order by 1, 2, 3;

   ut.expect(l_version_dates.count).to_equal(l_ts_data.count * 2);
   if l_version_dates.count = l_ts_data.count * 2 then
      for i in 1..l_ts_data.count loop
         ut.expect(l_version_dates(i)).to_equal(cwms_util.non_versioned);
         ut.expect(l_date_times(i)).to_equal(l_ts_data(i).date_time);
         ut.expect(l_values(i)).to_equal(l_ts_data(i).value);
      end loop;
      for i in 1..l_ts_data.count loop
         ut.expect(l_version_dates(l_ts_data.count+i)).to_be_greater_or_equal(l_current_time);
         ut.expect(l_date_times(l_ts_data.count+i)).to_equal(l_ts_data(i).date_time);
         ut.expect(l_values(l_ts_data.count+i)).to_equal(l_ts_data(i).value);
      end loop;
   end if;
end cwdb_151;

procedure retrieve_ts_multi_test
is
   l_ts_data    ztsv_array := ztsv_array();
   l_crsr       sys_refcursor;
   l_sequence_out INTEGER;
   l_crsr2      sys_refcursor;
   p_location_id    varchar2(57); 
   l_date_times cwms_20.date_table_type;
   l_values cwms_20.double_tab_t;
   l_quality_codes cwms_20.number_tab_t;
   p_expected_values cwms_20.double_tab_t;
   l_timeseries_info cwms_20.timeseries_req_array := cwms_20.timeseries_req_array ();
   
   l_cwms_ts_id_out cwms_20.av_cwms_ts_id.cwms_ts_id%TYPE;
   l_unit_out cwms_20.av_cwms_ts_id.unit_id%TYPE;
   l_location_time_zone_out cwms_20.av_cwms_ts_id.time_zone_id%TYPE;
   l_start_time_out DATE;
   l_end_time_out DATE;
   l_time_zone_out cwms_20.av_cwms_ts_id.time_zone_id%TYPE;
begin
   -----------------------------
   -- create the base ts_data --
   -----------------------------
   for i in 1..c_value_count loop
      l_ts_data.extend;
      l_ts_data(i) := ztsv_type(c_start_time + (i-1) / 24, i-1, 0);
   end loop;
   ----------------------------------------------
   -- store the time series as a non-versioned --
   ----------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_office_id       => c_office_id);

  --------------------------------------
   -- set the time series to versioned --
   --------------------------------------
   cwms_ts.set_tsid_versioned(
      p_cwms_ts_id   => c_ts_id,
      p_versioned    => 'T',
      p_db_office_id => c_office_id);
   ------------------------------
   -- store the versioned data --
   ------------------------------
   for i in 1..c_version_dates.count loop
      for j in 1..l_ts_data.count loop
         l_ts_data(j).date_time := l_ts_data(j).date_time + 1 / 24;
         l_ts_data(j).value     := i * 1000 + i + j - 1;
      end loop;
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => c_ts_id,
         p_units           => c_units,
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => c_version_dates(i),
         p_office_id       => c_office_id);
   end loop;

   cwms_loc.assign_loc_group(
     p_loc_category_id => 'Agency Aliases',
     p_loc_group_id    => 'USGS Station Number',
     p_location_id     => c_location_id,
     p_loc_alias_id    => '11111111',
     p_db_office_id    => c_office_id);


   p_location_id := cwms_loc.get_location_id_from_alias(
          p_alias_id    => '11111111',
          p_group_id    => 'USGS Station Number',
          p_category_id => 'Agency Aliases' ,
          p_office_id   => c_office_id);
                            
   ut.expect(p_location_id).to_equal(c_location_id);                       
    
   -------------------------------------------------------------
   -- test retrieving versioned time series data with an alias--
   -------------------------------------------------------------
   
   l_timeseries_info.EXTEND (1);
   for j in 1..c_version_dates.count loop
    l_timeseries_info (1) := cwms_20.timeseries_req_type (c_ts_id,c_units, c_start_time,c_end_time);
    cwms_ts.retrieve_ts_multi (
         p_at_tsv_rc => l_crsr,
         p_timeseries_info => l_timeseries_info, 
         p_version_date => c_version_dates(j), 
         p_start_inclusive => 'T', 
         p_end_inclusive => 'T', 
         p_time_zone => Null, 
         p_trim => 'F', 
         p_previous => 'F', 
         p_next => 'F', 
         p_max_version => 'T');

    p_expected_values := c_expected_values(j+1);
    LOOP
        FETCH l_crsr
        INTO l_sequence_out,
            l_cwms_ts_id_out,
            l_unit_out,
            l_start_time_out,
            l_end_time_out,
            l_time_zone_out,
            l_crsr2,
            l_location_time_zone_out;
    
    EXIT WHEN l_crsr%NOTFOUND;
    
    FETCH l_crsr2
    BULK COLLECT INTO l_date_times, l_values, l_quality_codes;
    --ut.expect(l_crsr2%rowcount).to_equal(p_expected_values.count);
    CLOSE l_crsr2;
    
    
    ut.expect(l_values.count).to_equal(p_expected_values.count);
    if l_values.count = p_expected_values.count then
        for i in 1..p_expected_values.count loop
          if p_expected_values(i) is null then
              ut.expect(l_values(i)).to_be_null;
           else
              ut.expect(l_values(i)).to_equal(p_expected_values(i));
           end if;
        end loop;
     end if;
    END LOOP;
    
    CLOSE l_crsr;
   end loop;
end retrieve_ts_multi_test;

end test_versioned_time_series;
/
