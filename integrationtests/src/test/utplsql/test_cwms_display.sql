create or replace package test_cwms_display as

--%suite(Test CWMS_DISPLAY package routines)
--%rollback(manual)
--%beforeall(setup)
--%afterall(teardown)

--%test(Correct hierarchy of user/office/default units)
procedure test_units_hierarchy;
procedure setup;
procedure teardown;


c_office_id    constant varchar2(16) := '&&office_id';
c_parameter_id constant varchar2(16) := 'Length';
c_unit_system  constant varchar2(2)  := 'EN';
c_default_unit constant varchar2(16) := 'ft';
c_office_unit  constant varchar2(16) := 'in';
c_user_unit    constant varchar2(16) := 'mi';

end test_cwms_display;
/
create or replace package body test_cwms_display as

procedure teardown
is
   l_office_code integer := cwms_util.get_db_office_code(c_office_id);
   l_user_id     varchar2(30) := cwms_util.get_user_id;
begin
   delete
     from at_properties
    where office_code = l_office_code
      and prop_category = 'CWMSDB'
      and prop_id = 'display_unit.'||l_user_id||'.'||c_unit_system||'.'||c_parameter_id;

   cwms_display.store_unit(
      p_parameter_id   =>c_parameter_id,
      p_unit_system    => c_unit_system,
      p_unit_id        => c_default_unit,
      p_fail_if_exists => 'F',
      p_office_id      => c_office_id);
end teardown;

procedure setup
is
begin
   null;
end setup;

procedure test_units_hierarchy
is
begin
   ut.expect(cwms_display.retrieve_user_unit_f(c_parameter_id, c_unit_system)).to_equal(c_default_unit);
   ---------------------
   -- set office unit --
   ---------------------
   cwms_display.store_unit(c_parameter_id, c_unit_system, c_office_unit, 'F');
   commit;
   ut.expect(cwms_display.retrieve_user_unit_f(c_parameter_id, c_unit_system)).to_equal(c_office_unit);
   -------------------
   -- set user unit --
   -------------------
   cwms_display.store_user_unit(c_parameter_id, c_unit_system, c_user_unit, 'F');
   commit;
   ut.expect(cwms_display.retrieve_user_unit_f(c_parameter_id, c_unit_system)).to_equal(c_user_unit);
   ------------------------
   -- delete office unit --
   ------------------------
   cwms_display.delete_unit(c_parameter_id, c_unit_system);
   commit;
   ut.expect(cwms_display.retrieve_user_unit_f(c_parameter_id, c_unit_system)).to_equal(c_user_unit);
   ----------------------
   -- delete user unit --
   ----------------------
   cwms_display.delete_user_unit(c_parameter_id, c_unit_system);
   commit;
   ut.expect(cwms_display.retrieve_user_unit_f(c_parameter_id, c_unit_system)).to_equal(c_default_unit);
end test_units_hierarchy;

end test_cwms_display;
/
