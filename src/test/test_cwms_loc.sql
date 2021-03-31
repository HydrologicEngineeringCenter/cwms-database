create or replace package test_cwms_loc as

--%suite(Test cwms_loc package code)
--%afterall(teardown_all)
--%rollback(manual)

--%test(Test rename base location to a different base location)
procedure test_rename_loc_base_to_different_base;
--%test(Test rename base location to a sub-location: throws -20028)
--%throws(-20028)
procedure test_rename_loc_base_to_sub;
--%test(Test rename sub-location to a base location: throws -20998)
--%throws(-20998)
procedure test_rename_loc_sub_to_base;
--%test(Test rename sub-location to a different base location with the same sub-location)
procedure test_rename_loc_sub_to_different_base_with_same_sub;
--%test(Test rename sub-location to the same base location with a different sub-location)
procedure test_rename_loc_sub_to_same_base_with_different_sub;
--%test(Test rename sub-location to a different base location and a different sub-location)
procedure test_rename_loc_sub_to_different_base_with_different_sub;

procedure setup_rename;
procedure teardown_all;
end test_cwms_loc;
/
create or replace package body test_cwms_loc as
--------------------------------------------------------------------------------
-- procedure setup_rename
--------------------------------------------------------------------------------
procedure setup_rename
is
   exc_location_id_not_found exception;
   pragma exception_init(exc_location_id_not_found, -20025);
begin
   for rec in (select column_value as loc_name from table(str_tab_t('TestLoc1', 'TestLoc2'))) loop
      begin
         cwms_loc.delete_location(
            p_location_id   => rec.loc_name,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => 'SWT');
         exception
            when exc_location_id_not_found then null;
         end;
   end loop;
end setup_rename;
procedure teardown_all
is
begin
   setup_rename;
end teardown_all;
--------------------------------------------------------------------------------
-- procedure test_rename_loc_base_to_different_base
--------------------------------------------------------------------------------
procedure test_rename_loc_base_to_different_base
is
   l_office_id          av_loc.db_office_id%type;
   l_location_id        av_loc.location_id%type;
   l_location_id1       av_loc.location_id%type;
   l_location_id2       av_loc.location_id%type;
   l_base_location_code av_loc.base_location_code%type;
   l_location_code      av_loc.location_code%type;
begin
   --------------------------------
   -- cleanup any previous tests --
   --------------------------------
   setup_rename;
   ----------------------------------------------------
   -- create the location and get the location codes --
   ----------------------------------------------------
   l_office_id    := 'SWT';
   l_location_id1 := 'TestLoc1';
   l_location_id2 := 'TestLoc2';

   cwms_loc.store_location(
      p_location_id  => l_location_id1,
      p_db_office_id => l_office_id);

   select base_location_code,
          location_code
     into l_base_location_code,
          l_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id1
      and unit_system = 'EN';

   ut.expect(l_location_code).to_equal(l_base_location_code);
   -------------------------
   -- rename the location --
   -------------------------
   cwms_loc.rename_location(
      p_location_id_old => l_location_id1,
      p_location_id_new => l_location_id2,
      p_db_office_id    => l_office_id);

   select location_id
     into l_location_id
     from av_loc
    where base_location_code = l_location_code
      and unit_system = 'EN';

   ut.expect(l_location_id).to_equal(l_location_id2);

   select location_id
     into l_location_id
     from av_loc
    where location_code = l_location_code
      and unit_system = 'EN';

   ut.expect(l_location_id).to_equal(l_location_id2);

end test_rename_loc_base_to_different_base;
--------------------------------------------------------------------------------
-- procedure test_rename_loc_base_to_sub
--------------------------------------------------------------------------------
procedure test_rename_loc_base_to_sub
is
   l_office_id          av_loc.db_office_id%type;
   l_location_id1       av_loc.location_id%type;
   l_location_id2       av_loc.location_id%type;
   l_base_location_code av_loc.base_location_code%type;
   l_location_code      av_loc.location_code%type;
begin
   --------------------------------
   -- cleanup any previous tests --
   --------------------------------
   setup_rename;
   ----------------------------------------------------
   -- create the location and get the location codes --
   ----------------------------------------------------
   l_office_id    := 'SWT';
   l_location_id1 := 'TestLoc1';
   l_location_id2 := 'TestLoc2-WithSub1';

   cwms_loc.store_location(
      p_location_id  => l_location_id1,
      p_db_office_id => l_office_id);

   select base_location_code,
          location_code
     into l_base_location_code,
          l_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id1
      and unit_system = 'EN';

   ut.expect(l_location_code).to_equal(l_base_location_code);
   -------------------------
   -- rename the location --
   -------------------------
   cwms_loc.rename_location(
      p_location_id_old => l_location_id1,
      p_location_id_new => l_location_id2,
      p_db_office_id    => l_office_id);

end test_rename_loc_base_to_sub;
--------------------------------------------------------------------------------
-- procedure test_rename_loc_sub_to_base
--------------------------------------------------------------------------------
procedure test_rename_loc_sub_to_base
is
   l_office_id          av_loc.db_office_id%type;
   l_location_id1       av_loc.location_id%type;
   l_location_id2       av_loc.location_id%type;
   l_base_location_code av_loc.base_location_code%type;
   l_location_code      av_loc.location_code%type;
begin
   --------------------------------
   -- cleanup any previous tests --
   --------------------------------
   setup_rename;
   ----------------------------------------------------
   -- create the location and get the location codes --
   ----------------------------------------------------
   l_office_id    := 'SWT';
   l_location_id1 := 'TestLoc1-WithSub1';
   l_location_id2 := 'TestLoc2';

   cwms_loc.store_location(
      p_location_id  => l_location_id1,
      p_db_office_id => l_office_id);

   select base_location_code,
          location_code
     into l_base_location_code,
          l_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id1
      and unit_system = 'EN';

   ut.expect(l_location_code).not_to_equal(l_base_location_code);
   -------------------------
   -- rename the location --
   -------------------------
   cwms_loc.rename_location(
      p_location_id_old => l_location_id1,
      p_location_id_new => l_location_id2,
      p_db_office_id    => l_office_id);

end test_rename_loc_sub_to_base;
--------------------------------------------------------------------------------
-- procedure test_rename_loc_sub_to_different_base_with_same_sub
--------------------------------------------------------------------------------
procedure test_rename_loc_sub_to_different_base_with_same_sub
is
   l_office_id          av_loc.db_office_id%type;
   l_location_ids       str_tab_t;
   l_location_id1       av_loc.location_id%type;
   l_location_id2       av_loc.location_id%type;
   l_base_location_code av_loc.base_location_code%type;
   l_location_code      av_loc.location_code%type;
begin
   --------------------------------
   -- cleanup any previous tests --
   --------------------------------
   setup_rename;
   ----------------------------------------------------
   -- create the location and get the location codes --
   ----------------------------------------------------
   l_office_id    := 'SWT';
   l_location_id1 := 'TestLoc1-WithSub1';
   l_location_id2 := 'TestLoc2-WithSub1';

   cwms_loc.store_location(
      p_location_id  => l_location_id1,
      p_db_office_id => l_office_id);

   select base_location_code,
          location_code
     into l_base_location_code,
          l_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id1
      and unit_system = 'EN';

   ut.expect(l_location_code).not_to_equal(l_base_location_code);
   -------------------------
   -- rename the location --
   -------------------------
   cwms_loc.rename_location(
      p_location_id_old => l_location_id1,
      p_location_id_new => l_location_id2,
      p_db_office_id    => l_office_id);

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where base_location_code = l_base_location_code
      and unit_system = 'EN';

   ut.expect(l_location_ids.count).to_equal(1);
   ut.expect(l_location_ids(1)).to_equal(cwms_util.get_base_id(l_location_id1));

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where location_code = l_location_code
      and unit_system = 'EN';

   ut.expect(l_location_ids.count).to_equal(1);
   ut.expect(l_location_ids(1)).to_equal(l_location_id2);

   select base_location_code
     into l_base_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id2
      and unit_system = 'EN';

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where base_location_code = l_base_location_code
      and unit_system = 'EN'
    order by 1;

   ut.expect(l_location_ids.count).to_equal(2);
   ut.expect(l_location_ids(1)).to_equal(cwms_util.get_base_id(l_location_id2));
   ut.expect(l_location_ids(2)).to_equal(l_location_id2);


end test_rename_loc_sub_to_different_base_with_same_sub;
--------------------------------------------------------------------------------
-- procedure test_rename_loc_sub_to_same_base_with_different_sub
--------------------------------------------------------------------------------
procedure test_rename_loc_sub_to_same_base_with_different_sub
is
   l_office_id          av_loc.db_office_id%type;
   l_location_ids       str_tab_t;
   l_location_id1       av_loc.location_id%type;
   l_location_id2       av_loc.location_id%type;
   l_base_location_code av_loc.base_location_code%type;
   l_location_code      av_loc.location_code%type;
begin
   --------------------------------
   -- cleanup any previous tests --
   --------------------------------
   setup_rename;
   ----------------------------------------------------
   -- create the location and get the location codes --
   ----------------------------------------------------
   l_office_id    := 'SWT';
   l_location_id1 := 'TestLoc1-WithSub1';
   l_location_id2 := 'TestLoc1-WithSub2';

   cwms_loc.store_location(
      p_location_id  => l_location_id1,
      p_db_office_id => l_office_id);

   select base_location_code,
          location_code
     into l_base_location_code,
          l_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id1
      and unit_system = 'EN';

   ut.expect(l_location_code).not_to_equal(l_base_location_code);
   -------------------------
   -- rename the location --
   -------------------------
   cwms_loc.rename_location(
      p_location_id_old => l_location_id1,
      p_location_id_new => l_location_id2,
      p_db_office_id    => l_office_id);

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where base_location_code = l_base_location_code
      and unit_system = 'EN'
    order by 1;

   ut.expect(l_location_ids.count).to_equal(2);
   ut.expect(l_location_ids(1)).to_equal(cwms_util.get_base_id(l_location_id2));
   ut.expect(l_location_ids(2)).to_equal(l_location_id2);

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where location_code = l_location_code
      and unit_system = 'EN';

   ut.expect(l_location_ids.count).to_equal(1);
   ut.expect(l_location_ids(1)).to_equal(l_location_id2);

end test_rename_loc_sub_to_same_base_with_different_sub;
--------------------------------------------------------------------------------
-- procedure test_rename_loc_sub_to_different_base_with_different_sub
--------------------------------------------------------------------------------
procedure test_rename_loc_sub_to_different_base_with_different_sub
is
   l_office_id          av_loc.db_office_id%type;
   l_location_ids       str_tab_t;
   l_location_id1       av_loc.location_id%type;
   l_location_id2       av_loc.location_id%type;
   l_base_location_code av_loc.base_location_code%type;
   l_location_code      av_loc.location_code%type;
begin
   --------------------------------
   -- cleanup any previous tests --
   --------------------------------
   setup_rename;
   ----------------------------------------------------
   -- create the location and get the location codes --
   ----------------------------------------------------
   l_office_id    := 'SWT';
   l_location_id1 := 'TestLoc1-WithSub1';
   l_location_id2 := 'TestLoc2-WithSub2';

   cwms_loc.store_location(
      p_location_id  => l_location_id1,
      p_db_office_id => l_office_id);

   select base_location_code,
          location_code
     into l_base_location_code,
          l_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id1
      and unit_system = 'EN';

   ut.expect(l_location_code).not_to_equal(l_base_location_code);
   -------------------------
   -- rename the location --
   -------------------------
   cwms_loc.rename_location(
      p_location_id_old => l_location_id1,
      p_location_id_new => l_location_id2,
      p_db_office_id    => l_office_id);

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where base_location_code = l_base_location_code
      and unit_system = 'EN'
    order by 1;

   ut.expect(l_location_ids.count).to_equal(1);
   ut.expect(l_location_ids(1)).to_equal(cwms_util.get_base_id(l_location_id1));

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where location_code = l_location_code
      and unit_system = 'EN';

   ut.expect(l_location_ids.count).to_equal(1);
   ut.expect(l_location_ids(1)).to_equal(l_location_id2);

   select base_location_code
     into l_base_location_code
     from av_loc
    where db_office_id = l_office_id
      and location_id  = l_location_id2
      and unit_system = 'EN';

   select location_id
     bulk collect
     into l_location_ids
     from av_loc
    where base_location_code = l_base_location_code
      and unit_system = 'EN'
    order by 1;

   ut.expect(l_location_ids.count).to_equal(2);
   ut.expect(l_location_ids(1)).to_equal(cwms_util.get_base_id(l_location_id2));
   ut.expect(l_location_ids(2)).to_equal(l_location_id2);

end test_rename_loc_sub_to_different_base_with_different_sub;

end test_cwms_loc;
