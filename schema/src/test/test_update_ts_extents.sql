create or replace package test_update_ts_extents as
--%suite(Test time series extents functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Update Time Series Extents)
procedure update_ts_extents;
--%test(Update TS Extents can be called in a function)
procedure cwdb_119_test_for_no_error_on_update_in_select;
--%test(Update TS Extents creates record even if no TS data)
procedure cwdb_119_test_for_update_always_creates_record;

procedure setup;
procedure teardown;

c_office_id       constant varchar2(16)      := '&&office_id';
c_location_id     constant varchar2(57)      := 'TestUpdateTS';
c_ts_id           constant varchar2(183)     := c_location_id||'.Code.Inst.~1Hour.0.Test';
c_units           constant varchar2(16)      := 'n/a';
c_time_zone       constant varchar2(28)      := 'UTC';
c_store_rule      constant varchar2(11)      := cwms_util.replace_all; 
c_base_start_date constant date              := date '2021-08-01';
c_base_ts_data    constant cwms_t_ztsv_array := cwms_t_ztsv_array(
                                                   cwms_t_ztsv(c_base_start_date +  1/24, null,  5),  -- null
                                                   cwms_t_ztsv(c_base_start_date +  2/24, 1002, 17),  -- rejected
                                                   cwms_t_ztsv(c_base_start_date +  3/24, 1003,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date +  4/24, 1004,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date +  5/24, 1005,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date +  6/24, 1006,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date +  7/24, 1007,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date +  8/24, 1008,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date +  9/24, 1009,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 10/24, 1011,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 11/24, 1011,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 12/24, 1012,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 13/24, 1013,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 14/24, 1014,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 15/24, 1015,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 16/24, 1016,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 17/24, 1017,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 18/24, 1018,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 19/24, 1019,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 20/24, 1020,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 21/24, 1021,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 22/24, 1022,  3),  -- okay
                                                   cwms_t_ztsv(c_base_start_date + 23/24, 1023, 17),  -- rejected
                                                   cwms_t_ztsv(c_base_start_date + 24/24, null,  5)); -- null

end test_update_ts_extents;
/
show errors
create or replace package body test_update_ts_extents as
--------------------------------------------------------------------------------
-- procedure teaardown
--------------------------------------------------------------------------------
procedure teardown
is
   EXC_TS_ID_NOT_FOUND exception;
   pragma exception_init(EXC_TS_ID_NOT_FOUND, -20025);
begin
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id); 
exception
   when EXC_TS_ID_NOT_FOUND then null;
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
      
   cwms_ts.create_ts(
      p_cwms_ts_id        => c_ts_id,
      p_utc_offset        => null,
      p_interval_forward  => null,
      p_interval_backward => null,
      p_versioned         => 'F',
      p_active_flag       => 'T',
      p_office_id         => c_office_id);
end setup;
--------------------------------------------------------------------------------
-- function shift_ts_data
--------------------------------------------------------------------------------
function shift_ts_data(
   p_ts_data in cwms_t_ztsv_array,
   p_offset  in pls_integer)
   return cwms_t_ztsv_array
is
   l_ts_data cwms_t_ztsv_array := cwms_t_ztsv_array();
begin
   l_ts_data.extend(p_ts_data.count);
   for i in 1..p_ts_data.count loop
      l_ts_data(i) := cwms_t_ztsv(
         p_ts_data(i).date_time + p_offset * 365,
         p_ts_data(i).value + p_offset * 100,
         p_ts_data(i).quality_code);
   end loop;
   return l_ts_data;
end shift_ts_data;
--------------------------------------------------------------------------------
-- procedure update_ts_extents
--------------------------------------------------------------------------------
procedure update_ts_extents
is
   l_extents   cwms_v_ts_extents_utc%rowtype;
   l_ts_data_1 cwms_t_ztsv_array;
   l_ts_data_2 cwms_t_ztsv_array;
   l_ts_data_3 cwms_t_ztsv_array;
   l_ts1       timestamp (3);
   l_ts2       timestamp (6);
   l_ts3       timestamp (3);
   l_ts4       timestamp (6);
   l_ts5       timestamp (3);
   l_ts6       timestamp (6);
   l_ts7       timestamp (3);
   l_ts8       timestamp (6);
   l_ts9       timestamp (3);
   l_ts10      timestamp (6);
   l_ts_code   number(14);
   
   function get_ts_extents return cwms_v_ts_extents_utc%rowtype
   is
      ll_extents cwms_v_ts_extents_utc%rowtype;
   begin
      select * 
        into ll_extents 
        from cwms_v_ts_extents_utc
       where ts_code = cwms_ts.get_ts_code(c_ts_id, c_office_id)
         and version_time is null;
      return ll_extents;
   exception
      when no_data_found then return ll_extents;
   end get_ts_extents;
begin
   -----------------------
   -- test with no data --
   -----------------------
   l_extents := get_ts_extents;
   ut.expect(l_extents.ts_id).to_be_null;
   --------------------------------------
   -- test with data for the base year --
   --------------------------------------
   l_ts_data_1 := c_base_ts_data;
   
   l_ts1 := systimestamp;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units, 
      p_timeseries_data => l_ts_data_1,
      p_store_rule      => c_store_rule,
      p_office_id       => c_office_id);
   l_ts2 := systimestamp;
   
   l_extents := get_ts_extents;
   
   ut.expect(l_extents.earliest_time).to_equal(l_ts_data_1(1).date_time);
   ut.expect(l_extents.earliest_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.earliest_entry_time).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.earliest_non_null_time).to_equal(l_ts_data_1(2).date_time);
   ut.expect(l_extents.earliest_non_null_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.earliest_non_null_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.latest_time).to_equal(l_ts_data_1(l_ts_data_1.count).date_time);
   ut.expect(l_extents.latest_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.latest_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.latest_non_null_time).to_equal(l_ts_data_1(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.latest_non_null_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.latest_non_null_entry_time).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.si_unit).to_equal(c_units);
   ut.expect(l_extents.en_unit).to_equal(c_units);
   
   ut.expect(l_extents.least_value_si).to_equal(l_ts_data_1(2).value);
   ut.expect(l_extents.least_value_en).to_equal(l_ts_data_1(2).value);
   ut.expect(l_extents.least_value_time).to_equal(l_ts_data_1(2).date_time);
   ut.expect(l_extents.least_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.least_accepted_value_si).to_equal(l_ts_data_1(3).value);
   ut.expect(l_extents.least_accepted_value_en).to_equal(l_ts_data_1(3).value);
   ut.expect(l_extents.least_accepted_value_time).to_equal(l_ts_data_1(3).date_time);
   ut.expect(l_extents.least_accepted_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.greatest_value_si).to_equal(l_ts_data_1(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_en).to_equal(l_ts_data_1(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_time).to_equal(l_ts_data_1(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.greatest_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.greatest_accepted_value_si).to_equal(l_ts_data_1(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_en).to_equal(l_ts_data_1(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_time).to_equal(l_ts_data_1(l_ts_data_1.count-2).date_time);
   ut.expect(l_extents.greatest_accepted_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.last_update).to_be_between(l_ts1, l_ts2);
   ---------------------------------------------------------------------
   -- add data for the year prior to the base year (and lower values) --
   ---------------------------------------------------------------------
   l_ts_data_2 := shift_ts_data(c_base_ts_data, -1);
   
   l_ts3 := systimestamp;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units, 
      p_timeseries_data => l_ts_data_2,
      p_store_rule      => c_store_rule,
      p_office_id       => c_office_id);
   l_ts4 := systimestamp;
   
   l_extents := get_ts_extents;
   
   ut.expect(l_extents.earliest_time).to_equal(l_ts_data_2(1).date_time);
   ut.expect(l_extents.earliest_time_entry).to_be_between(l_ts3, l_ts4);
   ut.expect(l_extents.earliest_entry_time).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.earliest_non_null_time).to_equal(l_ts_data_2(2).date_time);
   ut.expect(l_extents.earliest_non_null_time_entry).to_be_between(l_ts3, l_ts4);
   ut.expect(l_extents.earliest_non_null_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.latest_time).to_equal(l_ts_data_1(l_ts_data_1.count).date_time);
   ut.expect(l_extents.latest_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.latest_entry_time).to_be_between(l_ts3, l_ts4);

   ut.expect(l_extents.latest_non_null_time).to_equal(l_ts_data_1(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.latest_non_null_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.latest_non_null_entry_time).to_be_between(l_ts3, l_ts4);
   
   ut.expect(l_extents.si_unit).to_equal(c_units);
   ut.expect(l_extents.en_unit).to_equal(c_units);
   
   ut.expect(l_extents.least_value_si).to_equal(l_ts_data_2(2).value);
   ut.expect(l_extents.least_value_en).to_equal(l_ts_data_2(2).value);
   ut.expect(l_extents.least_value_time).to_equal(l_ts_data_2(2).date_time);
   ut.expect(l_extents.least_value_entry).to_be_between(l_ts3, l_ts4);
   
   ut.expect(l_extents.least_accepted_value_si).to_equal(l_ts_data_2(3).value);
   ut.expect(l_extents.least_accepted_value_en).to_equal(l_ts_data_2(3).value);
   ut.expect(l_extents.least_accepted_value_time).to_equal(l_ts_data_2(3).date_time);
   ut.expect(l_extents.least_accepted_value_entry).to_be_between(l_ts3, l_ts4);
   
   ut.expect(l_extents.greatest_value_si).to_equal(l_ts_data_1(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_en).to_equal(l_ts_data_1(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_time).to_equal(l_ts_data_1(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.greatest_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.greatest_accepted_value_si).to_equal(l_ts_data_1(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_en).to_equal(l_ts_data_1(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_time).to_equal(l_ts_data_1(l_ts_data_1.count-2).date_time);
   ut.expect(l_extents.greatest_accepted_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.last_update).to_be_between(l_ts3, l_ts4);
   ----------------------------------------------------------------------
   -- add data for the year after to the base year (and higher values) --
   ----------------------------------------------------------------------
   l_ts_data_3 := shift_ts_data(c_base_ts_data, 1);
   
   l_ts5 := systimestamp;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units, 
      p_timeseries_data => l_ts_data_3,
      p_store_rule      => c_store_rule,
      p_office_id       => c_office_id);
   l_ts6 := systimestamp;
   
   l_extents := get_ts_extents;
   
   ut.expect(l_extents.earliest_time).to_equal(l_ts_data_2(1).date_time);
   ut.expect(l_extents.earliest_time_entry).to_be_between(l_ts3, l_ts4);
   ut.expect(l_extents.earliest_entry_time).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.earliest_non_null_time).to_equal(l_ts_data_2(2).date_time);
   ut.expect(l_extents.earliest_non_null_time_entry).to_be_between(l_ts3, l_ts4);
   ut.expect(l_extents.earliest_non_null_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.latest_time).to_equal(l_ts_data_3(l_ts_data_1.count).date_time);
   ut.expect(l_extents.latest_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.latest_entry_time).to_be_between(l_ts5, l_ts6);

   ut.expect(l_extents.latest_non_null_time).to_equal(l_ts_data_3(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.latest_non_null_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.latest_non_null_entry_time).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.si_unit).to_equal(c_units);
   ut.expect(l_extents.en_unit).to_equal(c_units);
   
   ut.expect(l_extents.least_value_si).to_equal(l_ts_data_2(2).value);
   ut.expect(l_extents.least_value_en).to_equal(l_ts_data_2(2).value);
   ut.expect(l_extents.least_value_time).to_equal(l_ts_data_2(2).date_time);
   ut.expect(l_extents.least_value_entry).to_be_between(l_ts3, l_ts4);
   
   ut.expect(l_extents.least_accepted_value_si).to_equal(l_ts_data_2(3).value);
   ut.expect(l_extents.least_accepted_value_en).to_equal(l_ts_data_2(3).value);
   ut.expect(l_extents.least_accepted_value_time).to_equal(l_ts_data_2(3).date_time);
   ut.expect(l_extents.least_accepted_value_entry).to_be_between(l_ts3, l_ts4);
   
   ut.expect(l_extents.greatest_value_si).to_equal(l_ts_data_3(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_en).to_equal(l_ts_data_3(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_time).to_equal(l_ts_data_3(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.greatest_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.greatest_accepted_value_si).to_equal(l_ts_data_3(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_en).to_equal(l_ts_data_3(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_time).to_equal(l_ts_data_3(l_ts_data_1.count-2).date_time);
   ut.expect(l_extents.greatest_accepted_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.last_update).to_be_between(l_ts5, l_ts6);
   -----------------------------------------------------
   -- delete data for the year prior to the base year --
   -----------------------------------------------------
   l_ts_code := cwms_ts.get_ts_code(c_ts_id, c_office_id);

   l_ts7 := systimestamp;   
   cwms_ts.purge_ts_data(
      p_ts_code          => l_ts_code,
      p_version_date_utc => cwms_util.non_versioned,
      p_start_time_utc   => l_ts_data_2(1).date_time,
      p_end_time_utc     => l_ts_data_2(l_ts_data_2.count).date_time);
      
   cwms_ts.update_ts_extents(
      p_ts_code      => l_ts_code,
      p_version_date => cwms_util.non_versioned);
   l_ts8 := systimestamp;
   
   l_extents := get_ts_extents;
   
   ut.expect(l_extents.earliest_time).to_equal(l_ts_data_1(1).date_time);
   ut.expect(l_extents.earliest_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.earliest_entry_time).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.earliest_non_null_time).to_equal(l_ts_data_1(2).date_time);
   ut.expect(l_extents.earliest_non_null_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.earliest_non_null_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.latest_time).to_equal(l_ts_data_3(l_ts_data_1.count).date_time);
   ut.expect(l_extents.latest_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.latest_entry_time).to_be_between(l_ts5, l_ts6);

   ut.expect(l_extents.latest_non_null_time).to_equal(l_ts_data_3(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.latest_non_null_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.latest_non_null_entry_time).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.si_unit).to_equal(c_units);
   ut.expect(l_extents.en_unit).to_equal(c_units);
   
   ut.expect(l_extents.least_value_si).to_equal(l_ts_data_1(2).value);
   ut.expect(l_extents.least_value_en).to_equal(l_ts_data_1(2).value);
   ut.expect(l_extents.least_value_time).to_equal(l_ts_data_1(2).date_time);
   ut.expect(l_extents.least_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.least_accepted_value_si).to_equal(l_ts_data_1(3).value);
   ut.expect(l_extents.least_accepted_value_en).to_equal(l_ts_data_1(3).value);
   ut.expect(l_extents.least_accepted_value_time).to_equal(l_ts_data_1(3).date_time);
   ut.expect(l_extents.least_accepted_value_entry).to_be_between(l_ts1, l_ts2);
   
   ut.expect(l_extents.greatest_value_si).to_equal(l_ts_data_3(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_en).to_equal(l_ts_data_3(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_time).to_equal(l_ts_data_3(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.greatest_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.greatest_accepted_value_si).to_equal(l_ts_data_3(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_en).to_equal(l_ts_data_3(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_time).to_equal(l_ts_data_3(l_ts_data_1.count-2).date_time);
   ut.expect(l_extents.greatest_accepted_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.last_update).to_be_between(l_ts7, l_ts8);
   -----------------------------------
   -- delete data for the base year --
   -----------------------------------
   l_ts9 := systimestamp;   
   cwms_ts.purge_ts_data(
      p_ts_code          => l_ts_code,
      p_version_date_utc => cwms_util.non_versioned,
      p_start_time_utc   => l_ts_data_1(1).date_time,
      p_end_time_utc     => l_ts_data_1(l_ts_data_2.count).date_time);
      
   cwms_ts.update_ts_extents(
      p_ts_code      => l_ts_code,
      p_version_date => cwms_util.non_versioned);
   l_ts10 := systimestamp;
   
   l_extents := get_ts_extents;
   
   ut.expect(l_extents.earliest_time).to_equal(l_ts_data_3(1).date_time);
   ut.expect(l_extents.earliest_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.earliest_entry_time).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.earliest_non_null_time).to_equal(l_ts_data_3(2).date_time);
   ut.expect(l_extents.earliest_non_null_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.earliest_non_null_entry_time).to_be_between(l_ts5, l_ts6);

   ut.expect(l_extents.latest_time).to_equal(l_ts_data_3(l_ts_data_1.count).date_time);
   ut.expect(l_extents.latest_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.latest_entry_time).to_be_between(l_ts5, l_ts6);

   ut.expect(l_extents.latest_non_null_time).to_equal(l_ts_data_3(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.latest_non_null_time_entry).to_be_between(l_ts5, l_ts6);
   ut.expect(l_extents.latest_non_null_entry_time).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.si_unit).to_equal(c_units);
   ut.expect(l_extents.en_unit).to_equal(c_units);
   
   ut.expect(l_extents.least_value_si).to_equal(l_ts_data_3(2).value);
   ut.expect(l_extents.least_value_en).to_equal(l_ts_data_3(2).value);
   ut.expect(l_extents.least_value_time).to_equal(l_ts_data_3(2).date_time);
   ut.expect(l_extents.least_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.least_accepted_value_si).to_equal(l_ts_data_3(3).value);
   ut.expect(l_extents.least_accepted_value_en).to_equal(l_ts_data_3(3).value);
   ut.expect(l_extents.least_accepted_value_time).to_equal(l_ts_data_3(3).date_time);
   ut.expect(l_extents.least_accepted_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.greatest_value_si).to_equal(l_ts_data_3(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_en).to_equal(l_ts_data_3(l_ts_data_1.count-1).value);
   ut.expect(l_extents.greatest_value_time).to_equal(l_ts_data_3(l_ts_data_1.count-1).date_time);
   ut.expect(l_extents.greatest_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.greatest_accepted_value_si).to_equal(l_ts_data_3(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_en).to_equal(l_ts_data_3(l_ts_data_1.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_time).to_equal(l_ts_data_3(l_ts_data_1.count-2).date_time);
   ut.expect(l_extents.greatest_accepted_value_entry).to_be_between(l_ts5, l_ts6);
   
   ut.expect(l_extents.last_update).to_be_between(l_ts9, l_ts10);
   
end update_ts_extents;
--------------------------------------------------------------------------------
-- procedure cwdb_119_test_for_no_error_on_update_in_select
--------------------------------------------------------------------------------
procedure cwdb_119_test_for_no_error_on_update_in_select
is
    l_ts_code   integer;
    l_date_time date;
begin
    setup();
    l_ts_code := cwms_ts.get_ts_code(c_ts_id, c_office_id);
    ----------------------------------------------------------
    -- store time series data without going through the API --
    -- (prevents update_ts_extents from being called)       --
    ----------------------------------------------------------
    insert
      into at_tsv_2021
           (ts_code,
            date_time,
            version_date,
            data_entry_date,
            value,
            quality_code,
            dest_flag
           )
    select l_ts_code,
           date_time,
           cwms_util.non_versioned,
           systimestamp,
           value,
           quality_code,
           0
      from table(c_base_ts_data);
    commit;
    ------------------------------------------------------
    -- perform a query that will call update_ts_extents --
    ------------------------------------------------------
    select cwms_ts.get_ts_min_date(
              p_cwms_ts_id   => c_ts_id,
              p_time_zone    => c_time_zone,
              p_version_date => cwms_util.non_versioned,
              p_office_id    => c_office_id)
      into l_date_time
      from dual;
    ut.expect(l_date_time).to_be_not_null();
end cwdb_119_test_for_no_error_on_update_in_select;
--------------------------------------------------------------------------------
-- procedure cwdb_119_test_for_update_always_creates_record
--------------------------------------------------------------------------------
procedure cwdb_119_test_for_update_always_creates_record
is
    l_ts_code integer;
    l_count   integer;
begin
    setup();
    l_ts_code := cwms_ts.get_ts_code(c_ts_id, c_office_id);
    commit;
    cwms_ts.update_ts_extents(l_ts_code, cwms_util.non_versioned);
    select count(*)
      into l_count
      from at_ts_extents
     where ts_code = l_ts_code
       and version_time = cwms_util.non_versioned;
    ut.expect(l_count).to_equal(1);
end cwdb_119_test_for_update_always_creates_record;

end test_update_ts_extents;
/
show errors
