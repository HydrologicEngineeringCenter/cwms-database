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
        ut.expect (l_country).to_equal ('UNITED STATES');
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
      l_location_id   cwms_v_loc.location_id%type  := 'TestLoc1';
      l_ts_id         cwms_v_ts_id.cwms_ts_id%type := l_location_id||'.Elev.Inst.1Hour.0.Test';
      l_office_id     cwms_v_loc.db_office_id%type := '&&office_id';
      l_offset        binary_double;
      l_crsr          sys_refcursor;
      l_datetimes     cwms_t_date_table;
      l_values        cwms_t_double_tab;
      l_quality_codes cwms_t_number_tab;
      l_ts_data       cwms_t_ztsv_array := cwms_t_ztsv_array(
                         cwms_t_ztsv(timestamp '2023-05-16 01:00:00', 1001, 3),
                         cwms_t_ztsv(timestamp '2023-05-16 02:00:00', 1002, 3),
                         cwms_t_ztsv(timestamp '2023-05-16 03:00:00', 1003, 3),
                         cwms_t_ztsv(timestamp '2023-05-16 04:00:00', 1004, 3),
                         cwms_t_ztsv(timestamp '2023-05-16 05:00:00', 1005, 3),
                         cwms_t_ztsv(timestamp '2023-05-16 06:00:00', 1006, 3));
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
         p_db_office_id   => l_office_id);
      ----------------------------------------------------------------------------------
      -- get the vertical datum offset to the native datum (no other datum indicated) --
      ----------------------------------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      l_offset := cwms_loc.get_vertical_datum_offset(
                     p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
                     p_unit          => 'ft');
      ut.expect(l_offset).to_equal(0.D);
      ------------------------------------------------------
      -- get the vertical datum offset to a default datum --
      ------------------------------------------------------
      cwms_loc.set_default_vertical_datum('NGVD29');
      begin
         l_offset := cwms_loc.get_vertical_datum_offset(
                        p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
                        p_unit          => 'ft');
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')
            then null;
            else raise;
            end if;
      end;
      --------------------------------------------------------
      -- get the vertical datum offset to a specified datum --
      --------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      begin
         l_offset := cwms_loc.get_vertical_datum_offset(
                        p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id),
                        p_unit          => 'U=ft|V=NAVD88');
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')
            then null;
            else raise;
            end if;
      end;
      ------------------------------------------------------------------
      -- store the elev timeseries with no default or specified datum --
      ------------------------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_ts_id,
         p_units           => 'ft',
         p_timeseries_data => l_ts_data,
         p_store_rule      => cwms_util.replace_all,
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => l_office_id);
      ---------------------------------------------------------------------
      -- retrieve the elev timeseries with no default or specified datum --
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
      ------------------------------------------------
      -- store the time series with a default datum --
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
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')
            then null;
            else raise;
            end if;
      end;
      -------------------------------------------------------
      -- retrieve the elev timeseries with a default datum --
      -------------------------------------------------------
      begin
         cwms_ts.retrieve_ts(
            p_at_tsv_rc  => l_crsr,
            p_cwms_ts_id => l_ts_id,
            p_units      => 'ft',
            p_start_time => l_ts_data(1).date_time,
            p_end_time   => l_ts_data(l_ts_data.count).date_time,
            p_office_id  => l_office_id);
         close l_crsr;
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')
            then null;
            else raise;
            end if;
      end;
      --------------------------------------------------
      -- store the time series with a specified datum --
      --------------------------------------------------
      cwms_loc.set_default_vertical_datum(null);
      begin
         cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => 'U=ft|V=NAVD88',
            p_timeseries_data => l_ts_data,
            p_store_rule      => cwms_util.replace_all,
            p_version_date    => cwms_util.non_versioned,
            p_office_id       => l_office_id);
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')
            then null;
            else raise;
            end if;
      end;
      -------------------------------------------------------
      -- retrieve the elev timeseries with a specified datum --
      -------------------------------------------------------
      begin
         cwms_ts.retrieve_ts(
            p_at_tsv_rc  => l_crsr,
            p_cwms_ts_id => l_ts_id,
            p_units      => 'U=ft|V=NAVD88',
            p_start_time => l_ts_data(1).date_time,
            p_end_time   => l_ts_data(l_ts_data.count).date_time,
            p_office_id  => l_office_id);
         close l_crsr;
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            if regexp_like(dbms_utility.format_error_stack, 'Cannot convert between vertical datums', 'mn')
            then null;
            else raise;
            end if;
      end;

   end test_cwdb_143_storing_elev_with_unknown_datum_offset;
END test_cwms_loc;
/
