set verify off
create or replace package &&cwms_schema..test_cwms_level as
--%suite(Test schema for location level functionality)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

procedure teardown;
procedure setup;

--%test(Test constant location levels)
procedure test_constant_location_levels;
--%test(Test regularly varying [seasonal] location levels)
procedure test_regularly_varying_location_levels;
--%test(Test irregularly varying [time series] location levels)
procedure test_irregularly_varying_location_levels;
--%test(Test virtual location levels)
procedure test_virtual_location_levels;

c_office_id             varchar2(16)  := '&&office_id';
c_location_id           varchar2(57)  := 'LocLevelTestLoc';
c_timezone_id           varchar2(28)  := 'US/Central';
c_elev_unit             varchar2(16)  := 'ft';
c_top_of_normal_elev_id varchar2(404) := c_location_id||'.Elev.Inst.0.Top of Normal';
c_top_of_normal_stor_id varchar2(404) := c_location_id||'.Stor.Inst.0.Top of Normal';
end test_cwms_level;
/
show errors;
create or replace package body &&cwms_schema..test_cwms_level as
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
procedure teardown
is
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   cwms_loc.delete_location(
      p_location_id   => c_location_id,
      p_delete_action => cwms_util.delete_all,
      p_db_office_id  => c_office_id);
exception
   when exc_location_id_not_found then null;
end teardown;
--------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
procedure setup
is
begin
   teardown;
   cwms_loc.store_location(
      p_location_id  =>c_location_id,
      p_time_zone_id => c_timezone_id,
      p_db_office_id => c_office_id);
   commit;
end;
--------------------------------------------------------------------------------
-- procedure test_constant_location_levels
--------------------------------------------------------------------------------
procedure test_constant_location_levels
is
   l_effective_date1 date   := date '2021-01-01';
   l_effective_date2 date   := date '2022-01-01';
   l_expiration_date date   := date '2023-01-01';
   l_value1          number := 1000;
   l_value2          number := 1010;
   l_value           number;
begin
   setup;
   ----------------------------------------
   -- store the constant location levels --
   ----------------------------------------
   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => l_value1,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date1,
      p_timezone_id       => c_timezone_id,
      p_expiration_date   => null,
      p_office_id         => c_office_id);

   cwms_level.store_location_level4(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_value       => l_value2,
      p_level_units       => c_elev_unit,
      p_effective_date    => l_effective_date2,
      p_timezone_id       => c_timezone_id,
      p_expiration_date   => l_expiration_date,
      p_office_id         => c_office_id);

   commit;
   -------------------------------------------------------------
   -- retrieve the value just before the first effective date --
   -------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date1 - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(l_value).to_be_null;
   ----------------------------------------------------
   -- retrieve the value on the first effective date --
   ----------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date1,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value1, 5));
   ------------------------------------------------------------------------
   -- retrieve the value midway between first and second effective dates --
   ------------------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date1  + (l_effective_date2 - l_effective_date1) / 2,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value1, 5));
   --------------------------------------------------------------
   -- retrieve the value just before the second effective date --
   --------------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date2 - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value1, 5));
   -----------------------------------------------------
   -- retrieve the value on the second effective date --
   -----------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_effective_date2,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value2, 5));
   --------------------------------------------------------
   -- retrieve the value just before the expiration date --
   --------------------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_expiration_date - 1/86400,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(round(l_value, 5)).to_equal(round(l_value2, 5));
   -----------------------------------------------
   -- retrieve the value on the expiration date --
   -----------------------------------------------
   l_value := cwms_level.retrieve_location_level_value(
      p_location_level_id => c_top_of_normal_elev_id,
      p_level_units       => c_elev_unit,
      p_date              => l_expiration_date,
      p_timezone_id       => c_timezone_id,
      p_office_id         => c_office_id);

   ut.expect(l_value).to_be_null;

end test_constant_location_levels;
--------------------------------------------------------------------------------
-- procedure test_regularly_varying_location_levels
--------------------------------------------------------------------------------
procedure test_regularly_varying_location_levels
is
begin
   ut.expect(0).to_equal(0);
end test_regularly_varying_location_levels;
--------------------------------------------------------------------------------
--procedure test_irregularly_varying_location_levels
--------------------------------------------------------------------------------
procedure test_irregularly_varying_location_levels
is
begin
   ut.expect(0).to_equal(0);
end test_irregularly_varying_location_levels;
--------------------------------------------------------------------------------
-- procedure test_virtual_location_levels
--------------------------------------------------------------------------------
procedure test_virtual_location_levels
is
begin
   ut.expect(0).to_equal(0);
end test_virtual_location_levels;

end test_cwms_level;
/
show errors;
