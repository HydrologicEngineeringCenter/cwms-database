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
--%test(Test store_location_with_multiple_attributes_and_active_flags)
procedure test_store_location_with_multiple_attributes_and_actvie_flags;

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
            p_db_office_id  => '&office_id');
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
   l_office_id    := '&office_id';
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
   l_office_id    := '&office_id';
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
   l_office_id    := '&office_id';
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
   l_office_id    := '&office_id';
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
   l_office_id    := '&office_id';
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
   l_office_id    := '&office_id';
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

    --------------------------------------------------------------------------------
    -- procedure test_store_location_with_multiple_attributes_and_actvie_flags
    --------------------------------------------------------------------------------

    PROCEDURE test_store_location_with_multiple_attributes_and_actvie_flags
    IS
        l_location_id          av_loc.location_id%TYPE;
        l_base_loc_active      AV_LOC.BASE_LOC_ACTIVE_FLAG%TYPE;
        l_loc_active           AV_LOC.LOC_ACTIVE_FLAG%TYPE;
        l_active               AV_LOC.LOC_ACTIVE_FLAG%TYPE;
        l_bounding_office_id   AV_LOC.BOUNDING_OFFICE_ID%TYPE;
        l_nearest_city         AV_LOC.NEAREST_CITY%TYPE;
        l_county               AV_LOC.COUNTY_NAME%TYPE;
        l_state_initial        AV_LOC.STATE_INITIAL%TYPE;
        l_country              AV_LOC.NATION_ID%TYPE;
        l_location_kind_id     AV_LOC.LOCATION_KIND_ID%TYPE;
        l_base_location_id     AV_LOC.BASE_LOCATION_ID%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------

        l_location_id := 'TestLoc1-WithSub1';
        l_base_location_id := 'TestLoc1';


        cwms_loc.store_location (
            p_location_id        => l_location_id,
            p_db_office_id       => '&office_id',
            p_active             => 'F',
            p_longitude          => -122.6375,
            p_latitude           => 43.9708333,
            p_horizontal_datum   => 'WGS84',
            p_vertical_datum     => 'NGVD29',
            p_public_name        => 'Fall Creek near Lowell',
            p_long_name          => 'FCLO',
            p_time_zone_id       => 'US/Pacific');
        COMMIT;



          SELECT base_loc_active_flag,
                 loc_active_flag,
                 active_flag,
                 bounding_office_id,
                 nearest_city,
                 county_name,
                 state_initial,
                 nation_id,
                 location_kind_id
            INTO l_base_loc_active,
                 l_loc_active,
                 l_active,
                 l_bounding_office_id,
                 l_nearest_city,
                 l_county,
                 l_state_initial,
                 l_country,
                 l_location_kind_id
            FROM av_loc
           WHERE location_id = l_location_id AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_base_loc_active).to_equal ('F');
        ut.expect (l_loc_active).to_equal ('F');
        ut.expect (l_active).to_equal ('F');
        ut.expect (l_bounding_office_id).to_equal ('NWP');
        ut.expect (l_nearest_city).to_equal ('Springfield');
        ut.expect (l_county).to_equal ('Lane');
        ut.expect (l_country).to_equal ('UNITED STATES');
        ut.expect (l_location_kind_id).to_equal ('SITE');

        cwms_loc.store_location (p_location_id    => l_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&office_id');
        COMMIT;

          SELECT base_loc_active_flag, loc_active_flag, active_flag
            INTO l_base_loc_active, l_loc_active, l_active
            FROM av_loc
           WHERE location_id = l_location_id AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_base_loc_active).to_equal ('F');
        ut.expect (l_loc_active).to_equal ('T');
        ut.expect (l_active).to_equal ('T');
        cwms_loc.store_location (p_location_id    => l_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&office_id');
        COMMIT;

          SELECT base_loc_active_flag, loc_active_flag, active_flag
            INTO l_base_loc_active, l_loc_active, l_active
            FROM av_loc
           WHERE location_id = l_location_id AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_base_loc_active).to_equal ('T');
        ut.expect (l_loc_active).to_equal ('T');
        ut.expect (l_active).to_equal ('T');
        cwms_loc.store_location (p_location_id   => l_location_id,
                                 p_active        => 'F');
        COMMIT;
        cwms_loc.store_location (p_location_id    => l_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&office_id');
        COMMIT;

          SELECT base_loc_active_flag, loc_active_flag, active_flag
            INTO l_base_loc_active, l_loc_active, l_active
            FROM av_loc
           WHERE location_id = l_location_id AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_base_loc_active).to_equal ('T');
        ut.expect (l_loc_active).to_equal ('F');
        ut.expect (l_active).to_equal ('F');
    END test_store_location_with_multiple_attributes_and_actvie_flags;
end test_cwms_loc;
/

