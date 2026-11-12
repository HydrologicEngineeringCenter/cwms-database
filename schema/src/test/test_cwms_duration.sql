set verify off;
create or replace package &&cwms_schema..test_cwms_duration as
    --%suite(Test schema for duration presence)

   --%test(Test new durations are present)
   procedure test_3_6_9_month_durations_present;
end test_cwms_duration;
/
show errors;
create or replace package body &&cwms_schema..test_cwms_duration as

   procedure test_3_6_9_month_durations_present
   is
       l_count number := 0;
   begin
       select count(*)
       into l_count
       from cwms_duration
       where duration_id = '3Month';

      ut.expect(l_count).to_equal(1);

      select count(*)
      into l_count
      from cwms_duration
      where duration_id = '6Month';

      ut.expect(l_count).to_equal(1);

      select count(*)
      into l_count
      from cwms_duration
      where duration_id = '9Month';

      ut.expect(l_count).to_equal(1);

      select count(*)
      into l_count
      from cwms_duration
      where duration_id = '3MonthBOP';

      ut.expect(l_count).to_equal(1);

      select count(*)
      into l_count
      from cwms_duration
      where duration_id = '6MonthBOP';

      ut.expect(l_count).to_equal(1);

      select count(*)
      into l_count
      from cwms_duration
      where duration_id = '9MonthBOP';

      ut.expect(l_count).to_equal(1);
   end test_3_6_9_month_durations_present;
end test_cwms_duration;
/

grant execute on test_cwms_duration to cwms_user;