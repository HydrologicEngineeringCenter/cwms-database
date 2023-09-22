CREATE OR REPLACE package &&cwms_schema..test_cwms_loc as

--%suite(Test cwms_loc package code)
--%afterall(teardown)
--%beforeall (setup)
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
--%test(Test set_vertical_datum_info)
procedure test_set_vertical_datum_info;
--%test(Test set_vertical_datum_info_exp)
procedure test_set_vertical_datum_info_exp;
--%test(CWDB-222 Sublocation without VDI should inherit base location VDI)
procedure test_cwdb_222_sublocation_vdi_inheritance;
--%test(CWDB-143 Storing Elev data with unknown datum offset)
procedure test_cwdb_143_storing_elev_with_unknown_datum_offset;
--%test(CWDB-159 Store location in Ontario, CA
procedure test_cwdb_159_store_location_in_ontario_canada;
--%test(CWDB-232 Improve creation of new locations with lat/lon)
procedure test_cwdb_239_improve_creation_of_new_locations_with_lat_lon;
--%test(CWMSVUE-442 AV_LOCATION_LEVEL performance re-write)
procedure test_cwmsvue_442_location_level_performance_re_write;
--%test(CWMS_LOC.GET_LOCAL_TIMEZONE() returns NULL instead of 'UTC' when time zone is null)
procedure test_get_local_timezone_returns_null;

procedure setup;
procedure teardown;
end test_cwms_loc;
/

CREATE OR REPLACE PACKAGE BODY &&cwms_schema..test_cwms_loc
AS
    --------------------------------------------------------------------------------
    -- procedure setup
    --------------------------------------------------------------------------------
    PROCEDURE setup
    IS
        exc_location_id_not_found   EXCEPTION;
        PRAGMA EXCEPTION_INIT (exc_location_id_not_found, -20025);
    BEGIN
        FOR rec
            IN (SELECT COLUMN_VALUE     AS loc_name
                  FROM TABLE (str_tab_t ('TestLoc1', 'TestLoc2')))
        LOOP
            BEGIN
                cwms_loc.delete_location (
                    p_location_id     => rec.loc_name,
                    p_delete_action   => cwms_util.delete_all,
                    p_db_office_id    => '&&office_id');
            EXCEPTION
                WHEN exc_location_id_not_found
                THEN
                    NULL;
            END;
        END LOOP;
    END setup;


    PROCEDURE teardown
    IS
    BEGIN
        setup;
    END teardown;

    --------------------------------------------------------------------------------
    -- procedure test_rename_loc_base_to_different_base
    --------------------------------------------------------------------------------
    PROCEDURE test_rename_loc_base_to_different_base
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_id          av_loc.location_id%TYPE;
        l_location_id1         av_loc.location_id%TYPE;
        l_location_id2         av_loc.location_id%TYPE;
        l_base_location_code   av_loc.base_location_code%TYPE;
        l_location_code        av_loc.location_code%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1';
        l_location_id2 := 'TestLoc2';

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id);

        SELECT base_location_code, location_code
          INTO l_base_location_code, l_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_location_code).to_equal (l_base_location_code);
        -------------------------
        -- rename the location --
        -------------------------
        cwms_loc.rename_location (p_location_id_old   => l_location_id1,
                                  p_location_id_new   => l_location_id2,
                                  p_db_office_id      => l_office_id);

        SELECT location_id
          INTO l_location_id
          FROM av_loc
         WHERE base_location_code = l_location_code AND unit_system = 'EN';

        ut.expect (l_location_id).to_equal (l_location_id2);

        SELECT location_id
          INTO l_location_id
          FROM av_loc
         WHERE location_code = l_location_code AND unit_system = 'EN';

        ut.expect (l_location_id).to_equal (l_location_id2);
    END test_rename_loc_base_to_different_base;

    --------------------------------------------------------------------------------
    -- procedure test_rename_loc_base_to_sub
    --------------------------------------------------------------------------------
    PROCEDURE test_rename_loc_base_to_sub
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_id1         av_loc.location_id%TYPE;
        l_location_id2         av_loc.location_id%TYPE;
        l_base_location_code   av_loc.base_location_code%TYPE;
        l_location_code        av_loc.location_code%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1';
        l_location_id2 := 'TestLoc2-WithSub1';

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id);

        SELECT base_location_code, location_code
          INTO l_base_location_code, l_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_location_code).to_equal (l_base_location_code);
        -------------------------
        -- rename the location --
        -------------------------
        cwms_loc.rename_location (p_location_id_old   => l_location_id1,
                                  p_location_id_new   => l_location_id2,
                                  p_db_office_id      => l_office_id);
    END test_rename_loc_base_to_sub;

    --------------------------------------------------------------------------------
    -- procedure test_rename_loc_sub_to_base
    --------------------------------------------------------------------------------
    PROCEDURE test_rename_loc_sub_to_base
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_id1         av_loc.location_id%TYPE;
        l_location_id2         av_loc.location_id%TYPE;
        l_base_location_code   av_loc.base_location_code%TYPE;
        l_location_code        av_loc.location_code%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1-WithSub1';
        l_location_id2 := 'TestLoc2';

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id);

        SELECT base_location_code, location_code
          INTO l_base_location_code, l_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_location_code).not_to_equal (l_base_location_code);
        -------------------------
        -- rename the location --
        -------------------------
        cwms_loc.rename_location (p_location_id_old   => l_location_id1,
                                  p_location_id_new   => l_location_id2,
                                  p_db_office_id      => l_office_id);
    END test_rename_loc_sub_to_base;

    --------------------------------------------------------------------------------
    -- procedure test_rename_loc_sub_to_different_base_with_same_sub
    --------------------------------------------------------------------------------
    PROCEDURE test_rename_loc_sub_to_different_base_with_same_sub
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_ids         str_tab_t;
        l_location_id1         av_loc.location_id%TYPE;
        l_location_id2         av_loc.location_id%TYPE;
        l_base_location_code   av_loc.base_location_code%TYPE;
        l_location_code        av_loc.location_code%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1-WithSub1';
        l_location_id2 := 'TestLoc2-WithSub1';

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id);

        SELECT base_location_code, location_code
          INTO l_base_location_code, l_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_location_code).not_to_equal (l_base_location_code);
        -------------------------
        -- rename the location --
        -------------------------
        cwms_loc.rename_location (p_location_id_old   => l_location_id1,
                                  p_location_id_new   => l_location_id2,
                                  p_db_office_id      => l_office_id);

        SELECT location_id
          BULK COLLECT INTO l_location_ids
          FROM av_loc
         WHERE     base_location_code = l_base_location_code
               AND unit_system = 'EN';

        ut.expect (l_location_ids.COUNT).to_equal (1);
        ut.expect (l_location_ids (1)).to_equal (
            cwms_util.get_base_id (l_location_id1));

        SELECT location_id
          BULK COLLECT INTO l_location_ids
          FROM av_loc
         WHERE location_code = l_location_code AND unit_system = 'EN';

        ut.expect (l_location_ids.COUNT).to_equal (1);
        ut.expect (l_location_ids (1)).to_equal (l_location_id2);

        SELECT base_location_code
          INTO l_base_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id2
               AND unit_system = 'EN';

          SELECT location_id
            BULK COLLECT INTO l_location_ids
            FROM av_loc
           WHERE     base_location_code = l_base_location_code
                 AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_location_ids.COUNT).to_equal (2);
        ut.expect (l_location_ids (1)).to_equal (
            cwms_util.get_base_id (l_location_id2));
        ut.expect (l_location_ids (2)).to_equal (l_location_id2);
    END test_rename_loc_sub_to_different_base_with_same_sub;

    --------------------------------------------------------------------------------
    -- procedure test_rename_loc_sub_to_same_base_with_different_sub
    --------------------------------------------------------------------------------
    PROCEDURE test_rename_loc_sub_to_same_base_with_different_sub
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_ids         str_tab_t;
        l_location_id1         av_loc.location_id%TYPE;
        l_location_id2         av_loc.location_id%TYPE;
        l_base_location_code   av_loc.base_location_code%TYPE;
        l_location_code        av_loc.location_code%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1-WithSub1';
        l_location_id2 := 'TestLoc1-WithSub2';

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id);

        SELECT base_location_code, location_code
          INTO l_base_location_code, l_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_location_code).not_to_equal (l_base_location_code);
        -------------------------
        -- rename the location --
        -------------------------
        cwms_loc.rename_location (p_location_id_old   => l_location_id1,
                                  p_location_id_new   => l_location_id2,
                                  p_db_office_id      => l_office_id);

          SELECT location_id
            BULK COLLECT INTO l_location_ids
            FROM av_loc
           WHERE     base_location_code = l_base_location_code
                 AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_location_ids.COUNT).to_equal (2);
        ut.expect (l_location_ids (1)).to_equal (
            cwms_util.get_base_id (l_location_id2));
        ut.expect (l_location_ids (2)).to_equal (l_location_id2);

        SELECT location_id
          BULK COLLECT INTO l_location_ids
          FROM av_loc
         WHERE location_code = l_location_code AND unit_system = 'EN';

        ut.expect (l_location_ids.COUNT).to_equal (1);
        ut.expect (l_location_ids (1)).to_equal (l_location_id2);
    END test_rename_loc_sub_to_same_base_with_different_sub;

    --------------------------------------------------------------------------------
    -- procedure test_rename_loc_sub_to_different_base_with_different_sub
    --------------------------------------------------------------------------------
    PROCEDURE test_rename_loc_sub_to_different_base_with_different_sub
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_ids         str_tab_t;
        l_location_id1         av_loc.location_id%TYPE;
        l_location_id2         av_loc.location_id%TYPE;
        l_base_location_code   av_loc.base_location_code%TYPE;
        l_location_code        av_loc.location_code%TYPE;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1-WithSub1';
        l_location_id2 := 'TestLoc2-WithSub2';

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id);

        SELECT base_location_code, location_code
          INTO l_base_location_code, l_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_location_code).not_to_equal (l_base_location_code);
        -------------------------
        -- rename the location --
        -------------------------
        cwms_loc.rename_location (p_location_id_old   => l_location_id1,
                                  p_location_id_new   => l_location_id2,
                                  p_db_office_id      => l_office_id);

          SELECT location_id
            BULK COLLECT INTO l_location_ids
            FROM av_loc
           WHERE     base_location_code = l_base_location_code
                 AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_location_ids.COUNT).to_equal (1);
        ut.expect (l_location_ids (1)).to_equal (
            cwms_util.get_base_id (l_location_id1));

        SELECT location_id
          BULK COLLECT INTO l_location_ids
          FROM av_loc
         WHERE location_code = l_location_code AND unit_system = 'EN';

        ut.expect (l_location_ids.COUNT).to_equal (1);
        ut.expect (l_location_ids (1)).to_equal (l_location_id2);

        SELECT base_location_code
          INTO l_base_location_code
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id2
               AND unit_system = 'EN';

          SELECT location_id
            BULK COLLECT INTO l_location_ids
            FROM av_loc
           WHERE     base_location_code = l_base_location_code
                 AND unit_system = 'EN'
        ORDER BY 1;

        ut.expect (l_location_ids.COUNT).to_equal (2);
        ut.expect (l_location_ids (1)).to_equal (
            cwms_util.get_base_id (l_location_id2));
        ut.expect (l_location_ids (2)).to_equal (l_location_id2);
    END test_rename_loc_sub_to_different_base_with_different_sub;
    PROCEDURE test_set_vertical_datum_info
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_id1          av_loc.location_id%TYPE;
        l_vertical_datum       AV_LOC.VERTICAL_DATUM%TYPE;
        l_elevation      AV_LOC.ELEVATION%TYPE;
        l_xml            varchar2(2048);
        l_rounding_spec    varchar2(10) := '4444567894';
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1';


        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id,
                                 p_vertical_datum   => 'NGVD29');

        SELECT vertical_datum
          INTO l_vertical_datum
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (l_vertical_datum).to_equal ('NGVD29');

        l_xml := '<vertical-datum-info office="'||l_office_id||'" unit="in"><location>'||l_location_id1||'</location><native-datum>NGVD-29</native-datum><elevation>19200</elevation><offset estimate="false"><to-datum>NGVD-29</to-datum><value>0.0</value></offset><offset estimate="true"><to-datum>NAVD-88</to-datum><value>-5.846</value></offset></vertical-datum-info>';

        cwms_loc.set_vertical_datum_info (
        l_xml,
        'F');
        commit;

        SELECT elevation
          INTO l_elevation
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (abs(l_elevation-1600)).to_be_less_or_equal (0.01);
        ut.expect (abs(cwms_rounding.round_nt_f(l_elevation, l_rounding_spec)-1600)).to_be_less_or_equal (0.01);

        l_xml := '<vertical-datum-info office="'||l_office_id||'" unit="in"><location>'||l_location_id1||'</location><native-datum>NGVD-29</native-datum><elevation>19200.01</elevation><offset estimate="false"><to-datum>NGVD-29</to-datum><value>0.0</value></offset><offset estimate="true"><to-datum>NAVD-88</to-datum><value>-5.846</value></offset></vertical-datum-info>';

        cwms_loc.set_vertical_datum_info (
        l_xml,
        'F');
        commit;

        SELECT elevation
          INTO l_elevation
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (abs(l_elevation-1600)).to_be_less_or_equal (0.01);
        ut.expect (abs(cwms_rounding.round_nt_f(l_elevation, l_rounding_spec)-1600)).to_be_less_or_equal (0.01);

    END test_set_vertical_datum_info;
    PROCEDURE test_set_vertical_datum_info_exp
    IS
        l_office_id      av_loc.db_office_id%TYPE;
        l_location_id1   av_loc.location_id%TYPE;
        l_vertical_datum av_loc.vertical_datum%type;
        l_elevation      av_loc.elevation%type;
        l_xmlstr         varchar2(2048);
        l_xml1           xmltype;
        l_xml2           xmltype;
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&&office_id';
        l_location_id1 := 'TestLoc1';


        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id,
                                 p_vertical_datum => 'NGVD29');

        for i in 1..2 loop
           if i = 1 then
              l_xmlstr := '
<vertical-datum-info office=":office_id" unit="ft">
  <location>:location_id</location>
  <native-datum>NGVD-29</native-datum>
  <elevation>1600</elevation>
  <offset estimate="true">
    <to-datum>NAVD-88</to-datum>
    <value>0.3855</value>
  </offset>
</vertical-datum-info>';
           else
              l_xmlstr := '
<vertical-datum-info office=":office_id" unit="ft">
  <location>:location_id</location>
  <native-datum>OTHER</native-datum>n
  <local-datum-name>Pensacola</local-datum-name>
  <elevation>742.34</elevation>
  <offset estimate="true">
    <to-datum>NAVD-88</to-datum>
    <value>1.457</value>
  </offset>
  <offset estimate="false">
    <to-datum>NGVD-29</to-datum>
    <value>1.07</value>
  </offset>
</vertical-datum-info>';
           end if;

           l_xmlstr := replace(replace(l_xmlstr, ':office_id', l_office_id), ':location_id', l_location_id1);
           l_xml1 := xmltype(l_xmlstr);

           cwms_loc.set_vertical_datum_info (p_vert_datum_info => l_xmlstr,
                                             p_fail_if_exists  => 'F');
           commit;

           l_xmlstr := cwms_loc.get_vertical_datum_info_f (p_location_id => l_location_id1,
                                                           p_unit        => 'ft',
                                                           p_office_id   => l_office_id);

           l_xml2 := xmltype(l_xmlstr);
           ut.expect(cwms_util.get_xml_text  (l_xml2, '//location'                            )).to_equal(cwms_util.get_xml_text  (l_xml1, '//location'                            ));
           ut.expect(cwms_util.get_xml_text  (l_xml2, '//native-datum'                        )).to_equal(cwms_util.get_xml_text  (l_xml1, '//native-datum'                        ));
           ut.expect(cwms_util.get_xml_text  (l_xml2, '//local-datum-name'                    )).to_equal(cwms_util.get_xml_text  (l_xml1, '//local-datum-name'                    ));
           ut.expect(cwms_util.get_xml_number(l_xml2, '//elevation'                           )).to_equal(cwms_util.get_xml_number(l_xml1, '//elevation'                           ));
           ut.expect(cwms_util.get_xml_text  (l_xml2, '//offset[to-datum="NGVD-29"]/@estimate')).to_equal(cwms_util.get_xml_text  (l_xml1, '//offset[to-datum="NGVD-29"]/@estimate'));
           ut.expect(cwms_util.get_xml_number(l_xml2, '//offset[to-datum="NGVD-29"]/value'    )).to_equal(cwms_util.get_xml_number(l_xml1, '//offset[to-datum="NGVD-29"]/value    '));
           ut.expect(cwms_util.get_xml_text  (l_xml2, '//offset[to-datum="NAVD-88"]/@estimate')).to_equal(cwms_util.get_xml_text  (l_xml1, '//offset[to-datum="NAVD-88"]/@estimate'));
           ut.expect(cwms_util.get_xml_number(l_xml2, '//offset[to-datum="NAVD-88"]/value'    )).to_equal(cwms_util.get_xml_number(l_xml1, '//offset[to-datum="NAVD-88"]/value'    ));
        end loop;

    END test_set_vertical_datum_info_exp;

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
        setup;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------

        l_location_id := 'TestLoc1-WithSub1';
        l_base_location_id := 'TestLoc1';


        cwms_loc.store_location (
            p_location_id        => l_location_id,
            p_db_office_id       => '&&office_id',
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
        ut.expect (l_country).to_equal ('United States');
        ut.expect (l_location_kind_id).to_equal ('SITE');

        cwms_loc.store_location (p_location_id    => l_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
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
                                 p_db_office_id   => '&&office_id');
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
                                 p_db_office_id   => '&&office_id');
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

    --------------------------------------------------------------------------------
    -- procedure test_cwdb_222_sublocation_vdi_inheritance
    --------------------------------------------------------------------------------
   procedure test_cwdb_222_sublocation_vdi_inheritance
   is
      l_office_id      av_loc.db_office_id%TYPE;
      l_location_id1   av_loc.location_id%TYPE;
      l_location_id2   av_loc.location_id%TYPE;
      l_vertical_datum av_loc.vertical_datum%type;
      l_elevation      av_loc.elevation%type;
      l_vd_offset      cwms_t_vert_datum_offset;
      l_xmlstr_out     varchar2(4000);
      l_xmlstr         cwms_t_str_tab := cwms_t_str_tab(
'<vertical-datum-info office=":office_id" unit="ft">
  <location>:location_id</location>
  <native-datum>NGVD-29</native-datum>
  <elevation>1600</elevation>
  <offset estimate="true">
    <to-datum>NAVD-88</to-datum>
    <value>0.3855</value>
  </offset>
</vertical-datum-info>',

'<vertical-datum-info office=":office_id" unit="ft">
  <location>:location_id</location>
  <native-datum>OTHER</native-datum>
  <local-datum-name>Pensacola</local-datum-name>
  <elevation>742.34</elevation>
  <offset estimate="true">
    <to-datum>NAVD-88</to-datum>
    <value>1.455</value>
  </offset>
  <offset estimate="false">
    <to-datum>NGVD-29</to-datum>
    <value>1.07</value>
  </offset>
</vertical-datum-info>');
   begin
      teardown;

      l_office_id    := '&&office_id';
      l_location_id1 := 'TestLoc1';
      l_location_id2 := 'TestLoc1-WithSub';

      for i in 1..l_xmlstr.count loop
         l_xmlstr(i) := replace(l_xmlstr(i), ':office_id',   l_office_id);
      end loop;
      ----------------------------------------------------
      -- store the base location with lat/lon/vert-daum --
      ----------------------------------------------------
      cwms_loc.store_location(
         p_location_id    => l_location_id1,
         p_elevation      => 1600,
         p_elev_unit_id   => 'ft',
         p_vertical_datum => 'NGVD-29',
         p_latitude       => 36.1406481,
         p_longitude      => -96.0063866,
         p_db_office_id   => l_office_id);
      -------------------------------------------------------
      -- store the sub-location without lat/lon/vert-datum --
      -------------------------------------------------------
      cwms_loc.store_location(
         p_location_id    => l_location_id2,
         p_db_office_id   => l_office_id);

      commit;
      -----------------------------------------------
      -- get vertical datum info for base location --
      -----------------------------------------------
      l_xmlstr_out := cwms_loc.get_vertical_datum_info_f(
         p_location_id => l_location_id1,
         p_unit        => 'ft',
         p_office_id   => l_office_id);

      ut.expect(l_xmlstr_out).to_equal(replace(l_xmlstr(1), ':location_id', l_location_id1));
      -------------------------------------------------------------------------
      -- get vertical datum info for sub-location (should inherit from base) --
      -------------------------------------------------------------------------
      l_xmlstr_out := cwms_loc.get_vertical_datum_info_f(
         p_location_id => l_location_id2,
         p_unit        => 'ft',
         p_office_id   => l_office_id);

      ut.expect(l_xmlstr_out).to_equal(replace(l_xmlstr(1), ':location_id', l_location_id2));
      -----------------------------------------------------------
      -- store sub-location with different vertical datum info --
      -----------------------------------------------------------
      cwms_loc.store_location(
         p_location_id    => l_location_id2,
         p_elevation      => 742.34,
         p_elev_unit_id   => 'ft',
         p_vertical_datum => 'Pensacola',
         p_latitude       => 36.1406481,
         p_longitude      => -96.0063866,
         p_db_office_id   => l_office_id);

      cwms_loc.store_vertical_datum_offset(
         p_location_id         => l_location_id2,
         p_vertical_datum_id_1 => 'Pensacola',
         p_vertical_datum_id_2 => 'NGVD29',
         p_offset              => 1.07,
         p_unit                => 'ft',
         p_office_id           => l_office_id);

      commit;
      -----------------------------------------------------------------------------
      -- get vertical datum info for sub-location (should NOT inherit from base) --
      -----------------------------------------------------------------------------
      l_xmlstr_out := cwms_loc.get_vertical_datum_info_f(
         p_location_id => l_location_id2,
         p_unit        => 'ft',
         p_office_id   => l_office_id);

      ut.expect(l_xmlstr_out).not_to_equal(replace(l_xmlstr(1), ':location_id', l_location_id2));
      ut.expect(l_xmlstr_out).to_equal(replace(l_xmlstr(2), ':location_id', l_location_id2));

   end test_cwdb_222_sublocation_vdi_inheritance;
   --------------------------------------------------------------------------------
   -- procedure test_cwdb_143_storing_elev_with_unknown_datum_offset
   --------------------------------------------------------------------------------
   procedure test_cwdb_143_storing_elev_with_unknown_datum_offset
   is
      type xml_tab_t is table of xmltype;
      l_location_id       cwms_v_loc.location_id%type  := 'TestLoc1';
      l_ts_id             cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev.Inst.1Hour.0.Test';
      l_office_id         cwms_v_loc.db_office_id%type := '&&office_id';
      l_value             binary_double;
      l_offset            binary_double;
      l_offset_to_ngvd29  binary_double := 1.07D; -- ft
      l_offset_to_navd88  binary_double;
      l_offset_specified  boolean;
      l_table_rating      boolean;
      l_seasonal_level    boolean;
      l_crsr              sys_refcursor;
      l_datetimes         cwms_t_date_table;
      l_values            cwms_t_double_tab;
      l_quality_codes     cwms_t_number_tab;
      l_ratings           cwms_t_rating_tab;
      l_rating_spec_ids   cwms_t_str_tab := cwms_t_str_tab();
      l_effective_dates   cwms_t_date_table := cwms_t_date_table();
      l_create_dates      cwms_t_date_table := cwms_t_date_table();
      l_expected_elevs    cwms_t_number_tab := cwms_t_number_tab();
      l_errors            clob;
      l_value_str         varchar2(16);
      l_expected_str      varchar2(16);
      l_ts_data           cwms_t_ztsv_array := cwms_t_ztsv_array(
                             cwms_t_ztsv(timestamp '2023-05-16 01:00:00', 1001, 3),
                             cwms_t_ztsv(timestamp '2023-05-16 02:00:00', 1002, 3),
                             cwms_t_ztsv(timestamp '2023-05-16 03:00:00', 1003, 3),
                             cwms_t_ztsv(timestamp '2023-05-16 04:00:00', 1004, 3),
                             cwms_t_ztsv(timestamp '2023-05-16 05:00:00', 1005, 3),
                             cwms_t_ztsv(timestamp '2023-05-16 06:00:00', 1006, 3));
      l_location_level_id cwms_v_location_level.location_level_id%type := l_location_id||'.Elev.Inst.0.Top of Normal';
      l_seasonal_values   cwms_t_seasonal_value_tab := cwms_t_seasonal_value_tab(
                             cwms_t_seasonal_value( 0, 0, 1000),
                             cwms_t_seasonal_value( 2, 0, 1002),
                             cwms_t_seasonal_value( 4, 0, 1004),
                             cwms_t_seasonal_value( 6, 0, 1006),
                             cwms_t_seasonal_value( 8, 0, 1004),
                             cwms_t_seasonal_value(10, 0, 1002));
      l_location_level       cwms_t_location_level;
      l_ratings_xml          xml_tab_t := xml_tab_t();
      l_ratings_xml_str      cwms_t_str_tab := cwms_t_str_tab(
         replace('
            <ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
              <rating-template office-id="&&office_id">
                <parameters-id>Elev;Area</parameters-id>
                <version>Standard</version>
                <ind-parameter-specs>
                  <ind-parameter-spec position="1">
                    <parameter>Elev</parameter>
                    <in-range-method>LINEAR</in-range-method>
                    <out-range-low-method>NEXT</out-range-low-method>
                    <out-range-high-method>PREVIOUS</out-range-high-method>
                  </ind-parameter-spec>
                </ind-parameter-specs>
                <dep-parameter>Area</dep-parameter>
                <description>12</description>
              </rating-template>
              <rating-spec office-id="&&office_id">
                <rating-spec-id>$location-id.Elev;Area.Standard.Production</rating-spec-id>
                <template-id>Elev;Area.Standard</template-id>
                <location-id>$location-id</location-id>
                <version>Production</version>
                <source-agency/>
                <in-range-method>PREVIOUS</in-range-method>
                <out-range-low-method>NEAREST</out-range-low-method>
                <out-range-high-method>PREVIOUS</out-range-high-method>
                <active>true</active>
                <auto-update>true</auto-update>
                <auto-activate>true</auto-activate>
                <auto-migrate-extension>true</auto-migrate-extension>
                <ind-rounding-specs>
                  <ind-rounding-spec position="1">4444444444</ind-rounding-spec>
                </ind-rounding-specs>
                <dep-rounding-spec>4444444444</dep-rounding-spec>
                <description></description>
              </rating-spec>
              <simple-rating office-id="&&office_id">
                <rating-spec-id>$location-id.Elev;Area.Standard.Production</rating-spec-id>
                <units-id>ft;acre</units-id>
                <effective-date>2017-09-26T20:06:00Z</effective-date>
                <transition-start-date>2017-09-24T20:06:00Z</transition-start-date>
                <create-date>2017-09-26T20:06:00Z</create-date>
                <active>true</active>
                <description/>
                <rating-points>
                  <point><ind>370.0</ind><dep>0.0</dep></point>
                  <point><ind>383.0</ind><dep>0.1</dep></point>
                  <point><ind>387.0</ind><dep>1.0</dep></point>
                  <point><ind>388.0</ind><dep>2.0</dep></point>
                  <point><ind>389.0</ind><dep>4.0</dep></point>
                  <point><ind>390.2</ind><dep>7.0</dep></point>
                  <point><ind>391.0</ind><dep>10.0</dep></point>
                  <point><ind>392.0</ind><dep>12.0</dep></point>
                  <point><ind>393.0</ind><dep>14.0</dep></point>
                  <point><ind>394.0</ind><dep>18.0</dep></point>
                  <point><ind>395.0</ind><dep>20.0</dep></point>
                  <point><ind>396.0</ind><dep>22.0</dep></point>
                  <point><ind>397.0</ind><dep>25.0</dep></point>
                  <point><ind>398.0</ind><dep>27.0</dep></point>
                  <point><ind>399.0</ind><dep>29.0</dep></point>
                </rating-points>
              </simple-rating>
            </ratings>','$location-id', l_location_id),
         replace('
            <ratings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.hec.usace.army.mil/xmlSchema/cwms/Ratings.xsd">
              <rating-template office-id="&&office_id">
                <parameters-id>Elev-Pool,Elev-Tailwater;Flow</parameters-id>
                <version>Standard</version>
                <ind-parameter-specs>
                  <ind-parameter-spec position="1">
                    <parameter>Elev-Pool</parameter>
                    <in-range-method>LINEAR</in-range-method>
                    <out-range-low-method>NEAREST</out-range-low-method>
                    <out-range-high-method>NEAREST</out-range-high-method>
                  </ind-parameter-spec>
                  <ind-parameter-spec position="2">
                    <parameter>Elev-Tailwater</parameter>
                    <in-range-method>LINEAR</in-range-method>
                    <out-range-low-method>NEAREST</out-range-low-method>
                    <out-range-high-method>NEAREST</out-range-high-method>
                  </ind-parameter-spec>
                </ind-parameter-specs>
                <dep-parameter>Flow</dep-parameter>
                <description/>
              </rating-template>
              <rating-spec office-id="&&office_id">
                <rating-spec-id>$location-id.Elev-Pool,Elev-Tailwater;Flow.Standard.Production</rating-spec-id>
                <template-id>Elev-Pool,Elev-Tailwater;Flow.Standard</template-id>
                <location-id>$location-id</location-id>
                <version>Production</version>
                <source-agency/>
                <in-range-method>LINEAR</in-range-method>
                <out-range-low-method>NEAREST</out-range-low-method>
                <out-range-high-method>NEAREST</out-range-high-method>
                <active>true</active>
                <auto-update>true</auto-update>
                <auto-activate>true</auto-activate>
                <auto-migrate-extension>true</auto-migrate-extension>
                <ind-rounding-specs>
                  <ind-rounding-spec position="1">4444444444</ind-rounding-spec>
                  <ind-rounding-spec position="2">4444444444</ind-rounding-spec>
                </ind-rounding-specs>
                <dep-rounding-spec>4444444444</dep-rounding-spec>
                <description>$location-id elevation-discharge rates $location-id - Gate</description>
              </rating-spec>
              <simple-rating office-id="&&office_id">
                <rating-spec-id>$location-id.Elev-Pool,Elev-Tailwater;Flow.Standard.Production</rating-spec-id>
                <units-id>ft,ft;cfs</units-id>
                <effective-date>2018-05-24T09:22:00-05:00</effective-date>
                <create-date>1969-12-31T18:00:00-06:00</create-date>
                <active>true</active>
                <description>$location-id elevation-discharge rates $location-id - Gate</description>
                <formula>0.37*60*(i1-506)*sqrt(2*32.2*(i1-i2))</formula>
              </simple-rating>
            </ratings>','$location-id', l_location_id));
   begin
      teardown;
      -------------------------------------------------------------------------
      -- store the location with lat/lon/vert-daum but no vert datum offsets --
      -------------------------------------------------------------------------
      cwms_loc.store_location(
         p_location_id    => l_location_id,
         p_elevation      => 1600,
         p_elev_unit_id   => 'ft',
         p_vertical_datum => 'Pensacola',
         p_latitude       => 36.1406481,
         p_longitude      => -96.0063866,
         p_time_zone_id   => 'UTC',
         p_db_office_id   => l_office_id);
--    #####################
--    ## LOW LEVEL TESTS ##
--    #####################
      ----------------------------------------------------------------------------------
      -- get the vertical datum offset to the native datum (no other datum indicated) --
      -- (should succeed)                                                             --
      ----------------------------------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      l_offset := cwms_loc.get_vertical_datum_offset(
                     p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
                     p_unit          => 'ft');
      ut.expect(l_offset).to_equal(0.D);
      ------------------------------------------------------
      -- get the vertical datum offset to a default datum --
      -- (should raise an exception)                      --
      ------------------------------------------------------
      cwms_loc.set_default_vertical_datum('NGVD29');
      begin
         l_offset := cwms_loc.get_vertical_datum_offset(
                        p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
                        p_unit          => 'ft');
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
      end;
      --------------------------------------------------------
      -- get the vertical datum offset to a specified datum --
      -- (should raise an exception)                        --
      --------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      begin
         l_offset := cwms_loc.get_vertical_datum_offset(
                        p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
                        p_unit          => 'U=ft|V=NAVD88');
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
      end;
--    #######################
--    ## TIME SERIES TESTS ##
--    #######################
      ------------------------------------------------------------------
      -- store the elev timeseries with no default or specified datum --
      -- (should succeed)                                             --
      ------------------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_ts_id,
         p_units           => 'ft',
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => l_office_id);

      select date_time,
             value,
             quality_code
        bulk collect
        into l_datetimes,
             l_values,
             l_quality_codes
        from cwms_v_tsv_dqu
       where cwms_ts_id = l_ts_id
         and date_time between l_ts_data(1).date_time and l_ts_data(l_ts_data.count).date_time
         and unit_id = 'ft';

      ut.expect(l_datetimes.count).to_equal(l_ts_data.count);
      for j in 1..l_datetimes.count loop
         ut.expect(l_datetimes(j)).to_equal(l_ts_data(j).date_time);
         l_value_str    := cwms_rounding.round_nt_f(l_values(j), '7777777777');
         l_expected_str := cwms_rounding.round_dt_f(l_ts_data(j).value, '7777777777');
         ut.expect(l_value_str).to_equal(l_expected_str);
         ut.expect(l_quality_codes(j)).to_equal(l_ts_data(j).quality_code);
      end loop;
      ---------------------------------------------------------------------
      -- retrieve the elev timeseries with no default or specified datum --
      -- (should succeed)                                                --
      ---------------------------------------------------------------------
      cwms_ts.retrieve_ts(
         p_at_tsv_rc  => l_crsr,
         p_cwms_ts_id => l_ts_id,
         p_units      => 'ft',
         p_start_time => l_ts_data(1).date_time,
         p_end_time   => l_ts_data(l_ts_data.count).date_time,
         p_office_id  => l_office_id);

      fetch l_crsr
       bulk collect
       into l_datetimes,
            l_values,
            l_quality_codes;
      close l_crsr;

      ut.expect(l_datetimes.count).to_equal(l_ts_data.count);
      for i in 1..l_datetimes.count loop
         ut.expect(l_datetimes(i)).to_equal(l_ts_data(i).date_time);
         l_value_str    := cwms_rounding.round_nt_f(l_values(i), '7777777777');
         l_expected_str := cwms_rounding.round_dt_f(l_ts_data(i).value, '7777777777');
         ut.expect(l_value_str).to_equal(l_expected_str);
         ut.expect(l_quality_codes(i)).to_equal(l_ts_data(i).quality_code);
      end loop;

      for i in 1..2 loop
         l_offset_specified := i = 2;
         if l_offset_specified then
            cwms_loc.store_vertical_datum_offset(
               p_location_id         => l_location_id,
               p_vertical_datum_id_1 => 'Pensacola',
               p_vertical_datum_id_2 => 'NGVD29',
               p_offset              => l_offset_to_ngvd29,
               p_unit                => 'ft',
               p_office_id           => l_office_id);
            commit;
         end if;
         ------------------------------------------------
         -- store the time series with a default datum --
         -- (should raise an exception if no offset)   --
         ------------------------------------------------
         cwms_loc.set_default_vertical_datum('NGVD29');
         begin
            cwms_ts.zstore_ts(
               p_cwms_ts_id      => l_ts_id,
               p_units           => 'ft',
               p_timeseries_data => l_ts_data,
               p_store_rule      => cwms_util.replace_all,
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => l_office_id);

            if l_offset_specified then
               select date_time,
                      value,
                      quality_code
                 bulk collect
                 into l_datetimes,
                      l_values,
                      l_quality_codes
                 from cwms_v_tsv_dqu
                where cwms_ts_id = l_ts_id
                  and date_time between l_ts_data(1).date_time and l_ts_data(l_ts_data.count).date_time
                  and unit_id = 'ft';

               ut.expect(l_datetimes.count).to_equal(l_ts_data.count);
               for j in 1..l_datetimes.count loop
                  ut.expect(l_datetimes(j)).to_equal(l_ts_data(j).date_time);
                  l_value_str    := cwms_rounding.round_nt_f(l_values(j), '7777777777');
                  l_expected_str := cwms_rounding.round_dt_f(l_ts_data(j).value-l_offset_to_ngvd29, '7777777777');
                  ut.expect(l_value_str).to_equal(l_expected_str);
                  ut.expect(l_quality_codes(j)).to_equal(l_ts_data(j).quality_code);
               end loop;
            else
               cwms_err.raise('ERROR', 'Expected exception not raised');
            end if;
         exception
            when others then
               if not l_offset_specified then
                  ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
               else
                  raise;
               end if;
         end;
         -------------------------------------------------------
         -- retrieve the elev timeseries with a default datum --
         -- (should raise an exception if no offset)          --
         -------------------------------------------------------
         begin
            cwms_ts.retrieve_ts(
               p_at_tsv_rc  => l_crsr,
               p_cwms_ts_id => l_ts_id,
               p_units      => 'ft',
               p_start_time => l_ts_data(1).date_time,
               p_end_time   => l_ts_data(l_ts_data.count).date_time,
               p_office_id  => l_office_id);

            if l_offset_specified then
               fetch l_crsr
                bulk collect
                into l_datetimes,
                     l_values,
                     l_quality_codes;
               close l_crsr;

               ut.expect(l_datetimes.count).to_equal(l_ts_data.count);
               for j in 1..l_datetimes.count loop
                  ut.expect(l_datetimes(j)).to_equal(l_ts_data(j).date_time);
                  l_value_str    := cwms_rounding.round_nt_f(l_values(j), '7777777777');
                  l_expected_str := cwms_rounding.round_dt_f(l_ts_data(j).value, '7777777777');
                  ut.expect(l_value_str).to_equal(l_expected_str);
                  ut.expect(l_quality_codes(j)).to_equal(l_ts_data(j).quality_code);
               end loop;
            else
               close l_crsr;
               cwms_err.raise('ERROR', 'Expected exception not raised');
            end if;
         exception
            when others then
               if not l_offset_specified then
                  ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
               else
                  raise;
               end if;
         end;
         --------------------------------------------------
         -- store the time series with a specified datum --
         -- (should raise an exception if no offset)     --
         --------------------------------------------------
         cwms_loc.set_default_vertical_datum(null);
         if l_offset_specified then
            l_offset_to_navd88 := cwms_loc.get_vertical_datum_offset(
               p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
               p_unit          => 'U=ft|V=NAVD88');
         end if;
         begin
            cwms_ts.zstore_ts(
               p_cwms_ts_id      => l_ts_id,
               p_units           => 'U=ft|V=NAVD88',
               p_timeseries_data => l_ts_data,
               p_store_rule      => cwms_util.replace_all,
               p_version_date    => cwms_util.non_versioned,
               p_office_id       => l_office_id);

            if l_offset_specified then
               select date_time,
                      value,
                      quality_code
                 bulk collect
                 into l_datetimes,
                      l_values,
                      l_quality_codes
                 from cwms_v_tsv_dqu
                where cwms_ts_id = l_ts_id
                  and date_time between l_ts_data(1).date_time and l_ts_data(l_ts_data.count).date_time
                  and unit_id = 'ft';

               ut.expect(l_datetimes.count).to_equal(l_ts_data.count);
               for j in 1..l_datetimes.count loop
                  ut.expect(l_datetimes(j)).to_equal(l_ts_data(j).date_time);
                  l_value_str    := cwms_rounding.round_nt_f(l_values(j), '7777777777');
                  l_expected_str := cwms_rounding.round_dt_f(l_ts_data(j).value-l_offset_to_navd88, '7777777777');
                  ut.expect(l_value_str).to_equal(l_expected_str);
                  ut.expect(l_quality_codes(j)).to_equal(l_ts_data(j).quality_code);
               end loop;
            else
               cwms_err.raise('ERROR', 'Expected exception not raised');
            end if;
         exception
            when others then
               if not l_offset_specified then
                  ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
               else
                  raise;
               end if;
         end;
         ---------------------------------------------------------
         -- retrieve the elev timeseries with a specified datum --
         -- (should raise an exception if no offset)            --
         ---------------------------------------------------------
         begin
            cwms_ts.retrieve_ts(
               p_at_tsv_rc  => l_crsr,
               p_cwms_ts_id => l_ts_id,
               p_units      => 'U=ft|V=NAVD88',
               p_start_time => l_ts_data(1).date_time,
               p_end_time   => l_ts_data(l_ts_data.count).date_time,
               p_office_id  => l_office_id);

            if l_offset_specified then
               fetch l_crsr
                bulk collect
                into l_datetimes,
                     l_values,
                     l_quality_codes;
               close l_crsr;

               ut.expect(l_datetimes.count).to_equal(l_ts_data.count);
               for j in 1..l_datetimes.count loop
                  ut.expect(l_datetimes(j)).to_equal(l_ts_data(j).date_time);
                  l_value_str    := cwms_rounding.round_nt_f(l_values(j), '7777777777');
                  l_expected_str := cwms_rounding.round_dt_f(l_ts_data(j).value, '7777777777');
                  ut.expect(l_value_str).to_equal(l_expected_str);
                  ut.expect(l_quality_codes(j)).to_equal(l_ts_data(j).quality_code);
               end loop;
            else
               close l_crsr;
               cwms_err.raise('ERROR', 'Expected exception not raised');
            end if;
         exception
            when others then
               if not l_offset_specified then
                  ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
               else
                  raise;
               end if;
         end;
         if l_offset_specified then
            cwms_loc.delete_vertical_datum_offset(
               p_location_id          => l_location_id,
               p_vertical_datum_id_1  => 'Pensacola',
               p_vertical_datum_id_2  => 'NGVD29',
               p_match_effective_date => 'F',
               p_office_id            => l_office_id);
            commit;
         end if;
      end loop;
--    ##################
--    ## RATING TESTS ##
--    ##################
      for rating_index in 1..2 loop
         --------------------------------------
         -- get the rating info from the xml --
         --------------------------------------
         l_ratings_xml.extend;
         l_ratings_xml(rating_index)     := xmltype(l_ratings_xml_str(rating_index));
         l_rating_spec_ids.extend;
         l_rating_spec_ids(rating_index) := cwms_util.get_xml_text(l_ratings_xml(rating_index), '/ratings/simple-rating/rating-spec-id');
         l_effective_dates.extend;
         l_effective_dates(rating_index) := cwms_util.to_timestamp(cwms_util.get_xml_text(l_ratings_xml(rating_index), '/ratings/simple-rating/effective-date'));
         l_create_dates.extend;
         l_create_dates(rating_index)    := cwms_util.to_timestamp(cwms_util.get_xml_text(l_ratings_xml(rating_index), '/ratings/simple-rating/create-date'));
         l_table_rating := rating_index = 1;
         if l_table_rating then
            ---------------------------------------------------------------
            -- get the elevation values from the xml of the table rating --
            ---------------------------------------------------------------
            declare
               l_elev number;
            begin
               for i in 1..999999 loop
                  l_elev := cwms_util.get_xml_number(
                               l_ratings_xml(1),
                               '/ratings/simple-rating/rating-points/point['||i||']/ind');
                  exit when l_elev is null;
                  l_expected_elevs.extend;
                  l_expected_elevs(i) := l_elev;
               end loop;
            end;
         end if;
         ---------------------------------------------------------
         -- store the rating with no default or specified datum --
         -- (should succeed)                                    --
         ---------------------------------------------------------
         cwms_loc.set_default_vertical_datum(null);
         cwms_rating.store_ratings_xml(
            p_errors         => l_errors,
            p_xml            => l_ratings_xml(rating_index),
            p_fail_if_exists => 'F');

         ut.expect(l_errors).to_be_null;
         if l_table_rating then
            select ind_value_1
              bulk collect
              into l_values
              from cwms_v_rating_values_native
             where rating_code = (select rating_code
                                    from cwms_v_rating
                                   where rating_id = l_rating_spec_ids(rating_index)
                                     and effective_date = l_effective_dates(rating_index)
                                     and create_date = l_create_dates(rating_index)
                                 )
             order by 1;

            ut.expect(l_values.count).to_equal(l_expected_elevs.count);
            for i in 1..l_values.count loop
               l_value_str    := cwms_rounding.round_dt_f(l_values(i), '7777777777');
               l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(i), '7777777777');
               ut.expect(l_value_str).to_equal(l_expected_str);
            end loop;
         end if;
         ------------------------------------------------------------
         -- retrieve the rating with no default or specified datum --
         -- (should succeed)                                       --
         ------------------------------------------------------------
         l_ratings := cwms_rating.retrieve_ratings_obj_f(
            p_spec_id_mask   => l_rating_spec_ids(rating_index),
            p_office_id_mask => l_office_id);

         ut.expect(l_ratings.count).to_equal(1);
         if l_table_rating then
            ut.expect(l_ratings(1).rating_info.rating_values.count).to_equal(l_expected_elevs.count);
            l_ratings(rating_index).convert_to_native_units;
            for i in 1..l_ratings(1).rating_info.rating_values.count loop
               l_value_str    := cwms_rounding.round_dt_f(l_values(i), '7777777777');
               l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(i), '7777777777');
               ut.expect(l_value_str).to_equal(l_expected_str);
            end loop;
         end if;
         for i in 1..2 loop
            l_offset_specified := i = 2;
            if l_offset_specified then
               cwms_loc.store_vertical_datum_offset(
                  p_location_id         => l_location_id,
                  p_vertical_datum_id_1 => 'Pensacola',
                  p_vertical_datum_id_2 => 'NGVD29',
                  p_offset              => l_offset_to_ngvd29,
                  p_unit                => 'ft',
                  p_office_id           => l_office_id);
               commit;
            end if;
            ----------------------------------------------
            -- store the rating with a default datum    --
            -- (should raise an exception) if no offset --
            ----------------------------------------------
            cwms_loc.set_default_vertical_datum('NGVD29');
            cwms_rating.store_ratings_xml(
               p_errors         => l_errors,
               p_xml            => l_ratings_xml(rating_index),
               p_fail_if_exists => 'F');

            if l_offset_specified and l_table_rating then
               ut.expect(l_errors).to_be_null;
               if l_table_rating then
                  select ind_value_1
                    bulk collect
                    into l_values
                    from cwms_v_rating_values_native
                   where rating_code = (select rating_code
                                          from cwms_v_rating
                                         where rating_id = l_rating_spec_ids(rating_index)
                                           and effective_date = l_effective_dates(rating_index)
                                           and create_date = l_create_dates(rating_index)
                                       )
                   order by 1;

                  ut.expect(l_values.count).to_equal(l_expected_elevs.count);
                  for j in 1..l_values.count loop
                     l_value_str    := cwms_rounding.round_dt_f(l_values(j), '7777777777');
                     l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j)-l_offset_to_ngvd29, '7777777777');
                     ut.expect(l_value_str).to_equal(l_expected_str);
                  end loop;
               end if;
            else
               ut.expect(l_errors).to_be_not_null;
               if l_offset_specified and not l_table_rating then
                  ut.expect(regexp_like(l_errors, 'Cannot change vertical datum on an expression rating', 'mn')).to_be_true;
               else
                  ut.expect(regexp_like(l_errors, 'Cannot convert between vertical datums', 'mn')).to_be_true;
               end if;
            end if;
            ----------------------------------------------
            -- retrieve the rating with a default datum --
            -- (should raise an exception) if no offset --
            ----------------------------------------------
            begin
               l_ratings := cwms_rating.retrieve_ratings_obj_f(
                  p_spec_id_mask   => l_rating_spec_ids(rating_index),
                  p_office_id_mask => l_office_id);

               if l_table_rating and l_offset_specified then
                  ut.expect(l_ratings.count).to_equal(1);
                  if l_table_rating then
                     ut.expect(l_ratings(1).rating_info.rating_values.count).to_equal(l_expected_elevs.count);
                     l_ratings(rating_index).convert_to_native_units;
                     for j in 1..l_ratings(1).rating_info.rating_values.count loop
                        l_value_str    := cwms_rounding.round_dt_f(l_ratings(1).rating_info.rating_values(j).ind_value, '7777777777');
                        l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j), '7777777777');
                        ut.expect(l_value_str).to_equal(l_expected_str);
                     end loop;
                  end if;
               else
                  cwms_err.raise('ERROR', 'Expected exception not raised');
               end if;
            exception
               when others then
                  if not l_offset_specified then
                     ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
                  elsif not l_table_rating then
                     ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot change vertical datum on an expression rating', 'mn')).to_be_true;
                  else
                     raise;
                  end if;
            end;
            ----------------------------------------------
            -- store the rating with a specified datum  --
            -- (should raise an exception) if no offset --
            ----------------------------------------------
            cwms_loc.set_default_vertical_datum(null);
            cwms_rating.store_ratings_xml(
               p_errors         => l_errors,
               p_xml            => replace(
                                      l_ratings_xml_str(rating_index),
                                      case when l_table_rating then '<units-id>ft;acre</units-id>' else '<units-id>ft,ft;cfs</units-id>' end,
                                      case when l_table_rating then '<units-id>U=ft|V=NAVD88;acre</units-id>' else '<units-id>U=ft|V=NAVD88,ft;cfs</units-id>' end),
               p_fail_if_exists => 'F');
            if l_offset_specified and l_table_rating then
               ut.expect(l_errors).to_be_null;
               if l_table_rating then
                  select ind_value_1
                    bulk collect
                    into l_values
                    from cwms_v_rating_values_native
                   where rating_code = (select rating_code
                                          from cwms_v_rating
                                         where rating_id = l_rating_spec_ids(rating_index)
                                           and effective_date = l_effective_dates(rating_index)
                                           and create_date = l_create_dates(rating_index)
                                       )
                   order by 1;

                  ut.expect(l_values.count).to_equal(l_expected_elevs.count);
                  for j in 1..l_values.count loop
                     l_value_str    := cwms_rounding.round_dt_f(l_values(j), '7777777777');
                     l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j)-l_offset_to_navd88, '7777777777');
                     ut.expect(l_value_str).to_equal(l_expected_str);
                  end loop;
               end if;
            else
               ut.expect(l_errors).to_be_not_null;
               if l_table_rating then
                  ut.expect(regexp_like(l_errors, 'Cannot convert between vertical datums', 'mn')).to_be_true;
               else
                  ut.expect(regexp_like(l_errors, 'Cannot have multiple effective datums in a single rating', 'mn')).to_be_true;
               end if;
            end if;
            ------------------------------------------------------------------------------
            -- cannot retrieve ratings with specified datum (no input units on retrieve --
            ------------------------------------------------------------------------------
            if l_offset_specified then
               cwms_loc.delete_vertical_datum_offset(
                  p_location_id          => l_location_id,
                  p_vertical_datum_id_1  => 'Pensacola',
                  p_vertical_datum_id_2  => 'NGVD29',
                  p_match_effective_date => 'F',
                  p_office_id            => l_office_id);
               commit;
            end if;
         end loop;
      end loop;
--    ##########################
--    ## LOCATION LEVEL TESTS ##
--    ##########################
      select value
        bulk collect
        into l_expected_elevs
        from table(l_seasonal_values);
      -----------------------------------------------------------------
      -- store the location_level with no default or specified datum --
      -- (should succeed)                                            --
      -----------------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      for i in 1..2 loop
         l_seasonal_level := i = 2;
         if l_seasonal_level then
            cwms_level.store_location_level4(
               p_location_level_id => l_location_level_id,
               p_level_value       => null,
               p_level_units       => 'ft',
               p_timezone_id       => 'US/Pacific',
               p_interval_origin   => date '2023-01-01',
               p_interval_months   => 12,
               p_seasonal_values   => l_seasonal_values,
               p_fail_if_exists    => 'F',
               p_office_id         => l_office_id);
         else
            cwms_level.store_location_level4(
               p_location_level_id => l_location_level_id,
               p_level_value       => l_seasonal_values(1).value,
               p_level_units       => 'ft',
               p_timezone_id       => 'US/Pacific',
               p_interval_origin   => null,
               p_interval_months   => null,
               p_seasonal_values   => null,
               p_fail_if_exists    => 'F',
               p_office_id         => l_office_id);
         end if;

         commit;
         if l_seasonal_level then
            select seasonal_level
              bulk collect
              into l_values
              from cwms_v_location_level
             where location_level_id = l_location_level_id
               and level_unit = 'ft'
             order by calendar_offset,
                      time_offset;

            ut.expect(l_values.count).to_equal(l_seasonal_values.count);
            for i in 1..l_values.count loop
               l_value_str    := cwms_rounding.round_dt_f(l_values(i), '7777777777');
               l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(i), '7777777777');
               ut.expect(l_value_str).to_equal(l_expected_str);
            end loop;

            select distinct
                   constant_level
              into l_value
              from cwms_v_location_level
             where location_level_id = l_location_level_id
               and level_unit = 'ft';

            ut.expect(l_value).to_be_null;
         else
            select seasonal_level
              bulk collect
              into l_values
              from cwms_v_location_level
             where location_level_id = l_location_level_id
               and level_unit = 'ft'
             order by calendar_offset,
                      time_offset;

            ut.expect(l_values.count).to_equal(1);
            ut.expect(l_values(1)).to_be_null;

            select constant_level
              into l_value
              from cwms_v_location_level
             where location_level_id = l_location_level_id
               and level_unit = 'ft';

            l_value_str    := cwms_rounding.round_dt_f(l_value, '7777777777');
            l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(1), '7777777777');
            ut.expect(l_value_str).to_equal(l_expected_str);
         end if;
         --------------------------------------------------------------------
         -- retrieve the location_level with no default or specified datum --
         -- (should succeed)                                               --
         --------------------------------------------------------------------
         l_location_level := cwms_level.retrieve_location_level(
            p_location_level_id => l_location_level_id,
            p_level_units       => 'ft',
            p_date              => sysdate,
            p_timezone_id       => 'US/Pacific',
            p_office_id         => l_office_id);

         ut.expect(l_location_level is null).to_be_false;
         if l_location_level is not null then
            if l_seasonal_level then
               ut.expect(l_location_level.seasonal_values is null).to_be_false;
               if l_location_level.seasonal_values is not null then
                  ut.expect(l_location_level.seasonal_values.count).to_equal(l_expected_elevs.count);
                  for i in 1..l_location_level.seasonal_values.count loop
                     l_value_str    := cwms_rounding.round_nt_f(l_location_level.seasonal_values(i).value, '7777777777');
                     l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(i), '7777777777');
                     ut.expect(l_value_str).to_equal(l_expected_str);
                  end loop;
               end if;
            else
               l_value_str    := cwms_rounding.round_nt_f(l_location_level.level_value, '7777777777');
               l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(1), '7777777777');
               ut.expect(l_value_str).to_equal(l_expected_str);
            end if;
         end if;
      end loop;
      for i in 1..2 loop
         l_offset_specified := i = 2;
         if l_offset_specified then
            cwms_loc.store_vertical_datum_offset(
               p_location_id         => l_location_id,
               p_vertical_datum_id_1 => 'Pensacola',
               p_vertical_datum_id_2 => 'NGVD29',
               p_offset              => l_offset_to_ngvd29,
               p_unit                => 'ft',
               p_office_id           => l_office_id);
            commit;
         end if;
         for j in 1..2 loop
            l_seasonal_level := j = 2;
            ---------------------------------------------------
            -- store the location level with a default datum --
            -- (should raise an exception) if no offset      --
            ---------------------------------------------------
            cwms_loc.set_default_vertical_datum('NGVD29');
            begin
               if l_seasonal_level then
                  cwms_level.store_location_level4(
                     p_location_level_id => l_location_level_id,
                     p_level_value       => null,
                     p_level_units       => 'ft',
                     p_timezone_id       => 'US/Pacific',
                     p_interval_origin   => date '2023-01-01',
                     p_interval_months   => 12,
                     p_seasonal_values   => l_seasonal_values,
                     p_fail_if_exists    => 'F',
                     p_office_id         => l_office_id);
               else
                  cwms_level.store_location_level4(
                     p_location_level_id => l_location_level_id,
                     p_level_value       => l_seasonal_values(1).value,
                     p_level_units       => 'ft',
                     p_timezone_id       => 'US/Pacific',
                     p_interval_origin   => null,
                     p_interval_months   => null,
                     p_seasonal_values   => null,
                     p_fail_if_exists    => 'F',
                     p_office_id         => l_office_id);
               end if;

               commit;

               if l_offset_specified then
                  if l_seasonal_level then
                     select seasonal_level
                       bulk collect
                       into l_values
                       from cwms_v_location_level
                      where location_level_id = l_location_level_id
                        and level_unit = 'ft'
                      order by calendar_offset,
                               time_offset;

                     ut.expect(l_values.count).to_equal(l_seasonal_values.count);
                     for j in 1..l_values.count loop
                        l_value_str    := cwms_rounding.round_dt_f(l_values(j), '7777777777');
                        l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j)-l_offset_to_ngvd29, '7777777777');
                        ut.expect(l_value_str).to_equal(l_expected_str);
                     end loop;
                  else
                     select constant_level
                       into l_value
                       from cwms_v_location_level
                      where location_level_id = l_location_level_id
                        and level_unit = 'ft';

                     l_value_str    := cwms_rounding.round_dt_f(l_value, '7777777777');
                     l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(1)-l_offset_to_ngvd29, '7777777777');
                     ut.expect(l_value_str).to_equal(l_expected_str);
                  end if;
               else
                  cwms_err.raise('ERROR', 'Expected exception not raised');
               end if;
            exception
               when others then
                  if not l_offset_specified then
                     ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
                  else
                     raise;
                  end if;
            end;
            ------------------------------------------------------
            -- retrieve the location_level with a default datum --
            -- (should raise an exception if no offset)         --
            ------------------------------------------------------
            begin
               l_location_level := cwms_level.retrieve_location_level(
                  p_location_level_id => l_location_level_id,
                  p_level_units       => 'ft',
                  p_date              => sysdate,
                  p_timezone_id       => 'US/Pacific',
                  p_office_id         => l_office_id);

               if l_offset_specified then
                  ut.expect(l_location_level is null).to_be_false;
                  if l_location_level is not null then
                     if l_seasonal_level then
                        ut.expect(l_location_level.seasonal_values is null).to_be_false;
                        if l_location_level.seasonal_values is not null then
                           ut.expect(l_location_level.seasonal_values.count).to_equal(l_expected_elevs.count);
                           for j in 1..l_location_level.seasonal_values.count loop
                              l_value_str    := cwms_rounding.round_nt_f(l_location_level.seasonal_values(j).value, '7777777777');
                              l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j), '7777777777');
                              ut.expect(l_value_str).to_equal(l_expected_str);
                           end loop;
                        end if;
                     else
                        l_value_str    := cwms_rounding.round_nt_f(l_location_level.level_value, '7777777777');
                        l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(1), '7777777777');
                        ut.expect(l_value_str).to_equal(l_expected_str);
                     end if;
                  end if;
               else
                  cwms_err.raise('ERROR', 'Expected exception not raised');
               end if;
            exception
               when others then
                  if not l_offset_specified then
                     ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
                  else
                     raise;
                  end if;
            end;
         end loop;
         if l_offset_specified then
            cwms_loc.delete_vertical_datum_offset(
               p_location_id          => l_location_id,
               p_vertical_datum_id_1  => 'Pensacola',
               p_vertical_datum_id_2  => 'NGVD29',
               p_match_effective_date => 'F',
               p_office_id            => l_office_id);
            commit;
         end if;
      end loop;
      cwms_loc.set_default_vertical_datum(null);
      for i in 1..2 loop
         l_offset_specified := i = 2;
         if l_offset_specified then
            cwms_loc.store_vertical_datum_offset(
               p_location_id         => l_location_id,
               p_vertical_datum_id_1 => 'Pensacola',
               p_vertical_datum_id_2 => 'NGVD29',
               p_offset              => l_offset_to_ngvd29,
               p_unit                => 'ft',
               p_office_id           => l_office_id);
            commit;
         end if;
         for j in 1..2 loop
            l_seasonal_level := j = 2;
            -----------------------------------------------------
            -- store the location level with a specified datum --
            -- (should raise an exception) if no offset        --
            -----------------------------------------------------
            begin
               if l_seasonal_level then
                  cwms_level.store_location_level4(
                     p_location_level_id => l_location_level_id,
                     p_level_value       => null,
                     p_level_units       => 'U=ft|V=NAVD88',
                     p_timezone_id       => 'US/Pacific',
                     p_interval_origin   => date '2023-01-01',
                     p_interval_months   => 12,
                     p_seasonal_values   => l_seasonal_values,
                     p_fail_if_exists    => 'F',
                     p_office_id         => l_office_id);
               else
                  cwms_level.store_location_level4(
                     p_location_level_id => l_location_level_id,
                     p_level_value       => l_seasonal_values(1).value,
                     p_level_units       => 'U=ft|V=NAVD88',
                     p_timezone_id       => 'US/Pacific',
                     p_interval_origin   => null,
                     p_interval_months   => null,
                     p_seasonal_values   => null,
                     p_fail_if_exists    => 'F',
                     p_office_id         => l_office_id);
               end if;
               commit;

               if l_offset_specified then
                  if l_seasonal_level then
                     select seasonal_level
                       bulk collect
                       into l_values
                       from cwms_v_location_level
                      where location_level_id = l_location_level_id
                        and level_unit = 'ft'
                      order by calendar_offset,
                               time_offset;

                     ut.expect(l_values.count).to_equal(l_seasonal_values.count);
                     for j in 1..l_values.count loop
                        l_value_str    := cwms_rounding.round_dt_f(l_values(j), '7777777777');
                        l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j)-l_offset_to_navd88, '7777777777');
                        ut.expect(l_value_str).to_equal(l_expected_str);
                     end loop;
                  else
                     select constant_level
                       into l_value
                       from cwms_v_location_level
                      where location_level_id = l_location_level_id
                        and level_unit = 'ft';

                     l_value_str    := cwms_rounding.round_dt_f(l_value, '7777777777');
                     l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(1)-l_offset_to_navd88, '7777777777');
                     ut.expect(l_value_str).to_equal(l_expected_str);
                  end if;
               else
                  cwms_err.raise('ERROR', 'Expected exception not raised');
               end if;
            exception
               when others then
                  if not l_offset_specified then
                     ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
                  else
                     raise;
                  end if;
            end;
            --------------------------------------------------------
            -- retrieve the location_level with a specified datum --
            -- (should raise an exception if no offset)           --
            --------------------------------------------------------
            begin
               l_location_level := cwms_level.retrieve_location_level(
                  p_location_level_id => l_location_level_id,
                  p_level_units       => 'U=ft|V=NAVD88',
                  p_date              => sysdate,
                  p_timezone_id       => 'US/Pacific',
                  p_office_id         => l_office_id);

               if l_offset_specified then
                  ut.expect(l_location_level is null).to_be_false;
                  if l_location_level is not null then
                     if l_seasonal_level then
                        ut.expect(l_location_level.seasonal_values is null).to_be_false;
                        if l_location_level.seasonal_values is not null then
                           ut.expect(l_location_level.seasonal_values.count).to_equal(l_expected_elevs.count);
                           for j in 1..l_location_level.seasonal_values.count loop
                              l_value_str    := cwms_rounding.round_nt_f(l_location_level.seasonal_values(j).value, '7777777777');
                              l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(j), '7777777777');
                              ut.expect(l_value_str).to_equal(l_expected_str);
                           end loop;
                        end if;
                     else
                        l_value_str    := cwms_rounding.round_nt_f(l_location_level.level_value, '7777777777');
                        l_expected_str := cwms_rounding.round_nt_f(l_expected_elevs(1), '7777777777');
                        ut.expect(l_value_str).to_equal(l_expected_str);
                     end if;
                  end if;
               else
                  cwms_err.raise('ERROR', 'Expected exception not raised');
               end if;
            exception
               when others then
                  if not l_offset_specified then
                     ut.expect(regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')).to_be_true;
                  else
                     raise;
                  end if;
            end;
         end loop;
         if l_offset_specified then
            cwms_loc.delete_vertical_datum_offset(
               p_location_id          => l_location_id,
               p_vertical_datum_id_1  => 'Pensacola',
               p_vertical_datum_id_2  => 'NGVD29',
               p_match_effective_date => 'F',
               p_office_id            => l_office_id);
            commit;
         end if;
      end loop;
   end test_cwdb_143_storing_elev_with_unknown_datum_offset;
   --------------------------------------------------------------------------------
   -- procedure test_cwdb_159_store_location_in_ontario_canada
   --------------------------------------------------------------------------------
   procedure test_cwdb_159_store_location_in_ontario_canada
   is
      l_rec cwms_v_loc%rowtype;
   begin
      teardown;
      cwms_loc.store_location2(
         p_location_id         => 'TestLoc1',
         p_elevation           => 216.684,
         p_elev_unit_id        => 'm',
         p_vertical_datum      => 'CGVD2013',
         p_latitude            => 46.514517,
         p_longitude           => -84.347184,
         p_horizontal_datum    => 'NAD83',
         p_public_name         => 'TestLoc1',
         p_long_name           => 'TestLoc1_CWDB_159',
         p_location_type       => null,
         p_description         => 'Location for testing CWDB-159 issue',
         p_time_zone_id        => 'US/Eastern',
         p_county_name         => null,
         p_state_initial       => 'ON',
         p_active              => 'T',
         p_location_kind_id    => 'Site',
         p_published_latitude  => null,
         p_published_longitude => null,
         p_bounding_office_id  => null,
         p_nation_id           => null,
         p_nearest_city        => null,
         p_ignorenulls         => 'T',
         p_db_office_id        => '&&office_id');
      commit;

      begin
         select *
           into l_rec
           from cwms_v_loc
          where location_id = 'TestLoc1'
            and unit_system = 'SI';
      exception
         when others then cwms_err.raise('ERROR', dbms_utility.format_error_backtrace);
      end;

      ut.expect(l_rec.state_initial).to_equal('ON');
      ut.expect(l_rec.county_name).to_equal('Unknown County or County N/A for Ontario');
      ut.expect(l_rec.nation_id).to_equal('Canada');
      ut.expect(l_rec.nearest_city).to_equal('Sault Ste. Marie');
   end test_cwdb_159_store_location_in_ontario_canada;
   --------------------------------------------------------------------------------
   -- procedure test_cwdb_239_improve_creation_of_new_locations_with_lat_lon
   --------------------------------------------------------------------------------
   procedure test_cwdb_239_improve_creation_of_new_locations_with_lat_lon
   is
      l_rec cwms_v_loc%rowtype;

      function store_location(
         p_latitude           in number,
         p_longitude          in number,
         p_county_name        in varchar2,
         p_state_initial      in varchar2,
         p_nation_id          in varchar2,
         p_bounding_office_id in varchar2,
         p_nearest_city       in varchar2,
         p_delete             in boolean default true)
      return cwms_v_loc%rowtype
      is
         ll_rec cwms_v_loc%rowtype;
      begin
         cwms_loc.store_location2(
            p_location_id         => 'HUB',
            p_location_type       => 'Climate Station',
            p_elevation           => 0.0,
            p_elev_unit_id        => 'm',
            p_vertical_datum      => 'NGVD29',
            p_latitude            => p_latitude,
            p_longitude           => p_longitude,
            p_horizontal_datum    => 'WGS84',
            p_public_name         => 'Hubbard Glacier',
            p_long_name           => 'Hubbard Glacier @ Gilbert Point',
            p_description         => 'Hubbard Glacier @ Gilbert Point',
            p_time_zone_id        => 'America/Anchorage' ,
            p_county_name         => p_county_name,
            p_state_initial       => p_state_initial,
            p_bounding_office_id  => p_bounding_office_id,
            p_nation_id           => p_nation_id,
            p_nearest_city        => p_nearest_city,
            p_db_office_id        => '&&office_id');

         select * into ll_rec from cwms_v_loc where location_id = 'HUB' and unit_system = 'SI';

         if p_delete then
            cwms_loc.delete_location('HUB', cwms_util.delete_all, '&&office_id');
         end if;

         return ll_rec;
      end;
   begin
      teardown;
      -- create with valid lat/lon with null info
      l_rec := store_location(59.994444444444, -139.486388888889, null, null, null, null, null);
      ut.expect(l_rec.county_name).to_equal('Yakutat');
      ut.expect(l_rec.state_initial).to_equal('AK');
      ut.expect(l_rec.nation_id).to_equal('United States');
      ut.expect(l_rec.bounding_office_id).to_equal('POA');
      ut.expect(l_rec.nearest_city).to_equal('Juneau');
      -- create with null lat/lon with null info
      l_rec := store_location(null, null, null, null, null, null, null);
      ut.expect(l_rec.county_name).to_equal('Unknown County or County N/A for Unknown State or State N/A');
      ut.expect(l_rec.state_initial).to_equal('00');
      ut.expect(l_rec.nation_id).to_be_null;
      ut.expect(l_rec.bounding_office_id).to_be_null;
      ut.expect(l_rec.nearest_city).to_be_null;
      -- create with bad lat/lon with null info
      l_rec := store_location(0, 0, null, null, null, null, null);
      ut.expect(l_rec.county_name).to_equal('Unknown County or County N/A for Unknown State or State N/A');
      ut.expect(l_rec.state_initial).to_equal('00');
      ut.expect(l_rec.nation_id).to_be_null;
      ut.expect(l_rec.bounding_office_id).to_equal('UNK');
      ut.expect(l_rec.nearest_city).to_be_null;
      -- create with null lat/lon with non-null info
      l_rec := store_location(null, null, 'Yakutat', 'AK', 'US', 'POA', 'Juneau');
      ut.expect(l_rec.county_name).to_equal('Yakutat');
      ut.expect(l_rec.state_initial).to_equal('AK');
      ut.expect(l_rec.nation_id).to_equal('United States');
      ut.expect(l_rec.bounding_office_id).to_equal('POA');
      ut.expect(l_rec.nearest_city).to_equal('Juneau');
      -- create with bad lat/lon with non-null info
      l_rec := store_location(0, 0, 'Yakutat', 'AK', 'US', 'POA', 'Juneau');
      ut.expect(l_rec.county_name).to_equal('Yakutat');
      ut.expect(l_rec.state_initial).to_equal('AK');
      ut.expect(l_rec.nation_id).to_equal('United States');
      ut.expect(l_rec.bounding_office_id).to_equal('POA');
      ut.expect(l_rec.nearest_city).to_equal('Juneau');
      -- create with valid lat/lon with non-null info (shoud be overriden by values retrieved by lat/lon)
      l_rec := store_location(59.994444444444, -139.486388888889, 'King', 'WA', 'US', 'NWS', 'Seattle', p_delete => false);
      ut.expect(l_rec.county_name).to_equal('Yakutat');
      ut.expect(l_rec.state_initial).to_equal('AK');
      ut.expect(l_rec.nation_id).to_equal('United States');
      ut.expect(l_rec.bounding_office_id).to_equal('POA');
      ut.expect(l_rec.nearest_city).to_equal('Juneau');
      -- update with valid lat/lon with non-null info (should overwrite existing values)
      l_rec := store_location(59.994444444444, -139.486388888889, 'King', 'WA', 'US', 'NWS', 'Seattle');
      ut.expect(l_rec.county_name).to_equal('King');
      ut.expect(l_rec.state_initial).to_equal('WA');
      ut.expect(l_rec.nation_id).to_equal('United States');
      ut.expect(l_rec.bounding_office_id).to_equal('NWS');
      ut.expect(l_rec.nearest_city).to_equal('Seattle');

   end test_cwdb_239_improve_creation_of_new_locations_with_lat_lon;

   --------------------------------------------------------------------------------
   -- test_cwmsvue_442_location_level_performance_re_write
   --------------------------------------------------------------------------------
 
   procedure test_cwmsvue_442_location_level_performance_re_write
   is
   begin
     
     ut.expect('test').to_equal('test');
   end test_cwmsvue_442_location_level_performance_re_write;

   --------------------------------------------------------------------------------
   -- procedure test_get_local_timezone_returns_null
   --------------------------------------------------------------------------------
   procedure test_get_local_timezone_returns_null
   is
   begin
      teardown;
      cwms_loc.store_location2(
         p_location_id         => 'TestLoc1',
         p_db_office_id        => '&&office_id');
      commit;
      ut.expect(cwms_loc.get_local_timezone('TestLoc1', '&&office_id')).to_be_null;
   end test_get_local_timezone_returns_null;

END test_cwms_loc;
/

show errors;

