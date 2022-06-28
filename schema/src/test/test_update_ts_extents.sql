create or replace package test_update_ts_extents as
--%suite(Test time series extents functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Update Time Series Extents)
procedure update_ts_extents;
--%test(Update TS Extents can be called in a function [Jira issue CWDB-119])
procedure cwdb_119_test_for_no_error_on_update_in_select;
--%test(Update TS Extents creates record even if no TS data [Jira issue CWDB-119])
procedure cwdb_119_test_for_update_always_creates_record;
--%test(TS Extents updated after DELETE_INSERT but no values deleted [Jira issue CWDB-182])
procedure cwdb_182_test_for_update_with_delete_insert_without_deletes;
--%test(Prevent NO_DATA_FOUND exception on update_ts_extents [Jira issue CWDB-170])
procedure cwdb_170_update_ts_extents_no_data_found_exception;
--%test(AT_TS_EXTENTS.LAST_UPDATE is not null when no TS data [Jira issue CWDB-212])
procedure cwdb_212_last_update_is_not_null;
--%test(UTX jobs can start before calling code commits [Jira issue CWDB-213])
procedure cwdb_213_utx_job_delays_5_seconds;
--%test(NULL in subquery can affect UPDATE_TS_EXTENTS [Jira issue CWDB-220])
procedure cwdb_220_null_in_subquery_affects_update_ts_extents;
--%test(Add HAS_NON_ZERO_QUALITY field to TS extents [Jira issue CWDB-200])
procedure cwdb_200_ts_extents_has_field_for_non_zero_quality;

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
-- function get_ts_extents
--------------------------------------------------------------------------------
function get_ts_extents return cwms_v_ts_extents_utc%rowtype
is
   l_extents cwms_v_ts_extents_utc%rowtype;
begin
   -- Add sleep here to make sure UTX job has time to update the extents
   dbms_session.sleep(10);
   select *
     into l_extents
     from cwms_v_ts_extents_utc
    where ts_code = cwms_ts.get_ts_code(c_ts_id, c_office_id)
      and version_time is null;
   return l_extents;
exception
   when no_data_found then return l_extents;
end get_ts_extents;
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

   -- Commenting this out as the test fails ocasionally as last_update field is populated by UTX job
   -- ut.expect(l_extents.last_update).to_be_between(l_ts7, l_ts8);
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

   -- Commenting this out as the test fails ocasionally as last_update field is populated by UTX job
   -- ut.expect(l_extents.last_update).to_be_between(l_ts9, l_ts10);

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
--------------------------------------------------------------------------------
-- procedure cwdb_182_test_for_update_with_delete_insert_without_deletes
--------------------------------------------------------------------------------
procedure cwdb_182_test_for_update_with_delete_insert_without_deletes
is
   l_ts_data cwms_t_ztsv_array;
   l_offset  pls_integer := 1;
   l_ts1     timestamp(3);
   l_ts2     timestamp(3);
   l_ts3     timestamp(3);
   l_ts4     timestamp(3);
   l_extents cwms_v_ts_extents_utc%rowtype;
begin
   setup();
   ------------------------------------------
   -- store the base data with REPLACE ALL --
   ------------------------------------------
   l_ts1 := systimestamp;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => c_base_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   l_ts2 := systimestamp;

   ---------------------------------------------------------------------------------------
   -- shift the base data to a non-overlapping time window and store with DELETE_INSERT --
   ---------------------------------------------------------------------------------------
   l_ts_data := shift_ts_data(c_base_ts_data, 1);
   l_ts3 := systimestamp;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.delete_insert,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   l_ts4 := systimestamp;

   ------------------------
   -- verify the extents --
   ------------------------
   select *
     into l_extents
     from cwms_v_ts_extents_utc
    where ts_code = cwms_ts.get_ts_code(c_ts_id, c_office_id)
      and version_time is null;

   ut.expect(l_extents.earliest_time).to_equal(c_base_ts_data(1).date_time);
   ut.expect(l_extents.earliest_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.earliest_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.earliest_non_null_time).to_equal(c_base_ts_data(2).date_time);
   ut.expect(l_extents.earliest_non_null_time_entry).to_be_between(l_ts1, l_ts2);
   ut.expect(l_extents.earliest_non_null_entry_time).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.latest_time).to_equal(l_ts_data(l_ts_data.count).date_time);
   ut.expect(l_extents.latest_time_entry).to_be_between(l_ts3, l_ts4);
   ut.expect(l_extents.latest_entry_time).to_be_between(l_ts3, l_ts4);

   ut.expect(l_extents.latest_non_null_time).to_equal(l_ts_data(l_ts_data.count-1).date_time);
   ut.expect(l_extents.latest_non_null_time_entry).to_be_between(l_ts3, l_ts4);
   ut.expect(l_extents.latest_non_null_entry_time).to_be_between(l_ts3, l_ts4);

   ut.expect(l_extents.si_unit).to_equal(c_units);
   ut.expect(l_extents.en_unit).to_equal(c_units);

   ut.expect(l_extents.least_value_si).to_equal(c_base_ts_data(2).value);
   ut.expect(l_extents.least_value_en).to_equal(c_base_ts_data(2).value);
   ut.expect(l_extents.least_value_time).to_equal(c_base_ts_data(2).date_time);
   ut.expect(l_extents.least_value_entry).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.least_accepted_value_si).to_equal(c_base_ts_data(3).value);
   ut.expect(l_extents.least_accepted_value_en).to_equal(c_base_ts_data(3).value);
   ut.expect(l_extents.least_accepted_value_time).to_equal(c_base_ts_data(3).date_time);
   ut.expect(l_extents.least_accepted_value_entry).to_be_between(l_ts1, l_ts2);

   ut.expect(l_extents.greatest_value_si).to_equal(l_ts_data(l_ts_data.count-1).value);
   ut.expect(l_extents.greatest_value_en).to_equal(l_ts_data(l_ts_data.count-1).value);
   ut.expect(l_extents.greatest_value_time).to_equal(l_ts_data(l_ts_data.count-1).date_time);
   ut.expect(l_extents.greatest_value_entry).to_be_between(l_ts3, l_ts4);

   ut.expect(l_extents.greatest_accepted_value_si).to_equal(l_ts_data(l_ts_data.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_en).to_equal(l_ts_data(l_ts_data.count-2).value);
   ut.expect(l_extents.greatest_accepted_value_time).to_equal(l_ts_data(l_ts_data.count-2).date_time);
   ut.expect(l_extents.greatest_accepted_value_entry).to_be_between(l_ts3, l_ts4);

   ut.expect(l_extents.last_update).to_be_between(l_ts3, l_ts4);
end cwdb_182_test_for_update_with_delete_insert_without_deletes;
--------------------------------------------------------------------------------
-- procedure cwdb_170_update_ts_extents_no_data_found_exception
--------------------------------------------------------------------------------
procedure cwdb_170_update_ts_extents_no_data_found_exception
is
   l_ts_data cwms_t_ztsv_array;
   l_msg_id  cwms_v_log_message.msg_id%type;
   l_count   pls_integer;
begin
   setup();
   l_ts_data := c_base_ts_data;
   for i in 1..l_ts_data.count loop
      l_ts_data(i).value        := null;
      l_ts_data(i).quality_code := 5;
   end loop;

   l_msg_id := cwms_msg.get_msg_id;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'T',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);

   select count(*)
     into l_count
     from cwms_v_log_message
    where msg_id > l_msg_id
      and msg_text like  'Error updating TS Extents for '||c_office_id||'/'||c_ts_id||'%';

   ut.expect(l_count).to_equal(0);
end cwdb_170_update_ts_extents_no_data_found_exception;


--------------------------------------------------------------------------------
-- procedure cwdb_212_last_update_is_not_null
--------------------------------------------------------------------------------
procedure cwdb_212_last_update_is_not_null
is
   l_ts_code integer;
   l_rec     at_ts_extents%rowtype;
   l_ts      timestamp;
begin
   setup();
   commit;
   l_ts_code := cwms_ts.get_ts_code(c_ts_id, c_office_id);

   l_ts := systimestamp;
   cwms_ts.update_ts_extents(l_ts_code, cwms_util.non_versioned);
   select *
     into l_rec
     from at_ts_extents
    where ts_code = l_ts_code
      and version_time = cwms_util.non_versioned;

   ut.expect(l_rec.last_update).to_be_not_null;
   ut.expect(cast(systimestamp as timestamp)).to_be_greater_than(l_ts);
end cwdb_212_last_update_is_not_null;
--------------------------------------------------------------------------------
-- procedure cwdb_213_utx_job_delays_5_seconds
--------------------------------------------------------------------------------
procedure cwdb_213_utx_job_delays_5_seconds
is
   l_ts_code    integer;
   l_job_name   user_scheduler_jobs.job_name%type;
   l_start_date timestamp;
   l_ts         timestamp;
begin
   setup();
   commit;
   l_ts_code  := cwms_ts.get_ts_code(c_ts_id, c_office_id);
   l_job_name := 'UTX_'||l_ts_code||'_11111111_000000';
   ------------------------------------------------------------------
   -- store some data so we have some to delete with DELETE INSERT --
   ------------------------------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => c_base_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   commit;
   -----------------------------------------------------------
   -- store some data with DELETE INSERT to trigger utx job --
   -----------------------------------------------------------
   l_ts := systimestamp;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => c_base_ts_data,
      p_store_rule      => cwms_util.delete_insert,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   commit;
   -----------------------------------------
   -- verify the utx job delays 5 seconds --
   -----------------------------------------
   select start_date
     into l_start_date
     from user_scheduler_jobs
    where job_name = l_job_name;
   ut.expect(l_start_date).to_be_greater_than(l_ts + interval '000 00:00:05' day to second);
   ------------------------------------
   -- wait for the utx job to finish --
   ------------------------------------
   l_ts := systimestamp;
   loop
      begin
         select start_date
           into l_start_date
           from user_scheduler_jobs
          where job_name = l_job_name;
      exception
         when no_data_found then exit;
      end;
      if cast(systimestamp as timestamp) > l_ts + interval '000 00:01:00' day to second then
         cwms_err.raise('ERROR', 'Timeout waiting on utx job to finish.');
      end if;
   end loop;
   -----------------------------------------------------
   -- delete some time series data to trigger utx job --
   -----------------------------------------------------
   cwms_ts.delete_ts(
      p_cwms_ts_id           => c_ts_id,
      p_override_protection  => 'T',
      p_start_time           => c_base_ts_data(1).date_time,
      p_end_time             => c_base_ts_data(1).date_time,
      p_start_time_inclusive => 'T',
      p_end_time_inclusive   => 'T',
      p_version_date         => cwms_util.non_versioned,
      p_time_zone            => 'UTC',
      p_ts_item_mask         => cwms_util.ts_all,
      p_db_office_id         => c_office_id);
   -----------------------------------------
   -- verify the utx job delays 5 seconds --
   -----------------------------------------
   select start_date
     into l_start_date
     from user_scheduler_jobs
    where job_name = l_job_name;
   ut.expect(l_start_date).to_be_greater_than(l_ts + interval '000 00:00:05' day to second);
end cwdb_213_utx_job_delays_5_seconds;
--------------------------------------------------------------------------------
-- procedure cwdb_220_null_in_subquery_affects_update_ts_extents
--------------------------------------------------------------------------------
procedure cwdb_220_null_in_subquery_affects_update_ts_extents
is
   l_ts_data  cwms_t_ztsv_array;
   l_min_date date;
   l_max_date date;
begin
   setup;
   --------------------------------------------------------
   -- create and store a data set with ALL rejected data --
   --------------------------------------------------------
   l_ts_data := c_base_ts_data;
   for i in 1..l_ts_data.count loop
      l_ts_data(i).quality_code := 17;
   end loop;
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   --------------------------------------
   -- retrieve the time series extents --
   --------------------------------------
   cwms_ts.get_ts_extents(
      p_min_date     => l_min_date,
      p_max_date     => l_max_date,
      p_cwms_ts_id   => c_ts_id,
      p_time_zone    => 'UTC',
      p_version_date => cwms_util.non_versioned,
      p_office_id    => c_office_id);
   ------------------------
   -- verify the extents --
   ------------------------
   ut.expect(l_min_date).to_be_not_null;
   ut.expect(l_max_date).to_be_not_null;
end cwdb_220_null_in_subquery_affects_update_ts_extents;
--------------------------------------------------------------------------------
-- procedure cwdb_200_ts_extents_has_field_for_non_zero_quality
--------------------------------------------------------------------------------
procedure cwdb_200_ts_extents_has_field_for_non_zero_quality
is
   l_ts_data cwms_t_ztsv_array := c_base_ts_data;
   l_extents cwms_v_ts_extents_utc%rowtype;
begin
   setup;
   for i in 1..l_ts_data.count loop
      l_ts_data(i).quality_code := 0;
   end loop;
   -----------------------------------------
   -- store data with all 0 quality codes --
   -----------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   ---------------------------------------
   -- verify has_non_zero_quality field --
   ---------------------------------------
   l_extents := get_ts_extents;
   ut.expect(l_extents.has_non_zero_quality).to_equal('F');
   -------------------------------------------------
   -- store same data with non-zero quality codes --
   -------------------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => c_base_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   ---------------------------------------
   -- verify has_non_zero_quality field --
   ---------------------------------------
   l_extents := get_ts_extents;
   ut.expect(l_extents.has_non_zero_quality).to_equal('T');
   ----------------------------------------
   -- set all quality codes back to zero --
   ----------------------------------------
   cwms_ts.zstore_ts(
      p_cwms_ts_id      => c_ts_id,
      p_units           => c_units,
      p_timeseries_data => l_ts_data,
      p_store_rule      => cwms_util.replace_all,
      p_override_prot   => 'F',
      p_version_date    => cwms_util.non_versioned,
      p_office_id       => c_office_id);
   ---------------------------------------------------------------------------------------------------
   -- verify has_non_zero_quality field (won't set back to 'F' since it *once* had non-zero quality --
   ---------------------------------------------------------------------------------------------------
   l_extents := get_ts_extents;
   ut.expect(l_extents.has_non_zero_quality).to_equal('T');
   ---------------------------------------------------
   -- verify we can pass nulls to update_ts_extents --
   ---------------------------------------------------
   cwms_ts.update_ts_extents;

end cwdb_200_ts_extents_has_field_for_non_zero_quality;

end test_update_ts_extents;
/
