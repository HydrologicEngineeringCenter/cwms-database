set escape \
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
--%test(CWDB-239 Improve creation of new locations with lat/lon)
procedure test_cwdb_239_improve_creation_of_new_locations_with_lat_lon;
--%test(CWMSVUE-442 AV_LOCATION_LEVEL performance re-write)
procedure test_cwmsvue_442_location_level_performance_re_write;
--%test(CWMS_LOC.GET_LOCAL_TIMEZONE() returns NULL instead of 'UTC' when time zone is null)
procedure test_get_local_timezone_returns_null;
--%test(CWDB-246 Vertical datum info output limited size to 4000 bytes)
procedure cwdb_246_vertical_datum_info_output_limited_size_to_4000_bytes;
--%test(CWDB-288 Location Object nation usage)
procedure cwdb_288_location_object_creation;
--%test(CWDB-290 Bounding Office Overrides Lat/Lon)
procedure cwdb_290_bounding_office_overrides_lat_lon;
--%test(CWDB-305 spk location not creating)
procedure cwms_305_spk_location_not_creating;
--%test(Test storing an office location group to a CWMS category)
procedure store_loc_group_cwms_cat;
--%test(Test internataional location)
procedure test_international_location;
--%test(Test get vertical datum info series)
procedure test_vertical_datum_info_series_f;
--%test(Test issue #57 - query vertical datum offset)
procedure test_query_vertical_datum_offset;
--%test(Search location using Oracle Text via AV_LOC)
procedure test_av_loc_text_search;
--%test(Search location using Oracle Text via AV_LOC2)
procedure test_av_loc2_text_search;
--%test(CWMS-2430 [DB #54] Change lat/lon to generic geometry)
procedure test_mods_for_generic_geometry;

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
        v_msg clob := null;
    BEGIN
        commit; -- finish out any existing transactions
        FOR rec
            IN (SELECT COLUMN_VALUE     AS loc_name
                  FROM TABLE (str_tab_t ('TestLoc1', 'TestLoc2', 'TestLocObj', 'MikesHouse')))
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
        commit;
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
        ut.expect (cwms_loc.get_location_id(l_location_code)).to_equal (l_location_id2);

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
        ut.expect (l_nearest_city).to_equal ('Springfield, Oregon');
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
      x_item_does_not_exist exception;
      pragma exception_init(x_item_does_not_exist, -20034);
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
         else
            begin
               cwms_loc.delete_vertical_datum_offset(
                  p_location_id          => l_location_id,
                  p_vertical_datum_id_1  => 'Pensacola',
                  p_vertical_datum_id_2  => 'NGVD29',
                  p_match_effective_date => 'F',
                  p_office_id            => l_office_id);
            exception
               when x_item_does_not_exist then null;
            end;
         end if;
         commit;
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
      ut.expect(l_rec.nearest_city).to_equal('Sault Ste. Marie, Michigan');
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
         commit;

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
      ut.expect(l_rec.nearest_city).to_equal('Juneau, Alaska');
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
      -- Behavior changed with CWDB-290. P_BOUNDING_OFFICE_ID now overrides P_LATITUDE/P_LONGITUDE (MDP 18Jun2024)
      -- ut.expect(l_rec.bounding_office_id).to_equal('POA');
      ut.expect(l_rec.bounding_office_id).to_equal('NWS');
      ut.expect(l_rec.nearest_city).to_equal('Juneau, Alaska');
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
      l_office_id    cwms_office.office_id%TYPE;
      l_location_id  av_loc.location_id%TYPE;
      l_loc_lvl_id   av_location_level.location_level_id%TYPE;
      l_us           cwms_unit.unit_system%TYPE;
      l_code         at_location_level.location_level_code%TYPE;
      l_level        av_location_level.seasonal_level%TYPE;
      l_test_level   av_location_level.seasonal_level%TYPE;
      l_count        number;

   begin
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup;

        ----------------------------------------------------
        -- create the location and four location levels
        ----------------------------------------------------

      -- create a location

      l_office_id := '&&office_id';
      l_location_id := 'TestLoc1';
      l_loc_lvl_id       := l_location_id || '.Flow-05Percentile.Const.1Day.CENWP-10year-thru2022-STATS';
      l_us        := 'EN';

      cwms_loc.store_location ( p_location_id  => l_location_id, p_db_office_id => l_office_id);

      -- add four seasonal location_levels

     cwms_level.store_location_level4(
         p_location_level_id => l_loc_lvl_id,
         p_level_value       => null,
         p_level_units       => 'cfs',
         p_effective_date    => to_date('1900-01-01 08:00:00', 'yyyy-mm-dd hh24:mi:ss') ,
         p_timezone_id       => 'UTC',
         p_interval_origin   => to_date('2023-01-01 08:00:00', 'yyyy-mm-dd hh24:mi:ss'),
         p_interval_months   => 12,
         P_Expiration_Date   => null,
         p_interpolate       => 'F',
         p_fail_if_exists    => 'F',
         p_office_id         => l_office_id,
         p_seasonal_values   => cwms_t_seasonal_value_tab(
      cwms_t_seasonal_value( to_yminterval('00-00'), to_dsinterval('00 00:00:00'), 5360.000000000001  ),
      cwms_t_seasonal_value( to_yminterval('00-00'), to_dsinterval('01 00:00:00'), 4880.000000000001  ),
      cwms_t_seasonal_value( to_yminterval('00-00'), to_dsinterval('02 00:00:00'), 3847.7754632288793 ),
      cwms_t_seasonal_value( to_yminterval('00-00'), to_dsinterval('03 00:00:00'), 7196.964366433549  )
      ));


      select count(*)
      into   l_count
      from   av_location_level
      where  office_id=l_office_id and unit_system=l_us and location_level_id=l_loc_lvl_id;

      -- TEST FOR L_CODE=4
      ut.expect (l_count).to_equal (4);

      -- TEST A SEASIONAL LOCATION LEVEL IN EN UNITS SYSTEM

      l_us     := 'EN';
      l_test_level := 5360.000000000002d;

      select seasonal_level
      into   l_level
      from   av_location_level
      where  office_id         = l_office_id and
             unit_system       = l_us and
             location_level_id = l_loc_lvl_id and
             time_offset       = to_dsinterval('00 00:00:00');

      ut.expect (l_test_level).to_equal (l_level);

      -- TEST A SEASIONAL LOCATION LEVEL IN SI UNITS SYSTEM

      l_us         := 'SI';
      l_test_level := 151.77829773312004d;

      select seasonal_level
      into   l_level
      from   av_location_level
      where  office_id         = l_office_id and
             unit_system       = l_us and
             location_level_id = l_loc_lvl_id and
             time_offset       = to_dsinterval('00 00:00:00');

      ut.expect (l_test_level).to_equal (l_level);

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

   --------------------------------------------------------------------------------
   -- procedure cwdb_246_vertical_datum_info_output_limited_size_to_4000_bytes
   --------------------------------------------------------------------------------
   procedure cwdb_246_vertical_datum_info_output_limited_size_to_4000_bytes
   is
      l_location_ids clob;
      l_xml_str      varchar2(32767);
      l_xml_clob     clob  := '
<vertical-datum-info office="&&office_id" unit="ft">
  <location>TestLoc1</location>
  <native-datum>NGVD-29</native-datum>
  <elevation>615.25</elevation>
  <offset estimate="false">
    <to-datum>NAVD-88</to-datum>
    <value>-.3822</value>
  </offset>
</vertical-datum-info>';
   begin
      -----------------------------
      -- store the base location --
      -----------------------------
      cwms_loc.store_location(
         p_location_id  => 'TestLoc1',
         p_db_office_id => '&&office_id');
      ------------------------------------------------
      -- store the base location vertical datum xml --
      ------------------------------------------------
      cwms_loc.set_vertical_datum_info(l_xml_clob, 'F');
      dbms_lob.freetemporary(l_xml_clob);
      ----------------------------
      -- store 20 sub-locations --
      ----------------------------
      dbms_lob.createtemporary(l_location_ids, true);
      l_location_ids := l_location_ids||'TestLoc1';
      for i in 1..20 loop
         cwms_loc.store_location(
            p_location_id  => 'TestLoc1-'||trim(to_char(i, '09')),
            p_db_office_id => '&&office_id');
         l_location_ids := l_location_ids||chr(30)||'TestLoc1-'||trim(to_char(i, '09'));
      end loop;
      commit;
      -----------------------------------------------------------
      -- retrieve the for vertical datum xml for all locations --
      -----------------------------------------------------------
      cwms_loc.get_vertical_datum_info2(
         p_vert_datum_info => l_xml_clob,
         p_location_id     => l_location_ids,
         p_unit            => 'ft',
         p_office_id       => '&&office_id');
      ut.expect(length(l_xml_clob)).to_be_greater_than(4000);
      dbms_lob.freetemporary(l_xml_clob);

      execute immediate '
         create or replace function test_get_vertical_datum_info(
            p_location_id in varchar2,
            p_unit        in varchar2,
            p_office_id   in varchar2)
            return varchar2
         is
            l_xml varchar2(32767);
         begin
            cwms_loc.get_vertical_datum_info(
               p_vert_datum_info => l_xml,
               p_location_id     => p_location_id,
               p_unit            => p_unit,
               p_office_id       => p_office_id);
            return l_xml;
         end;';

   begin
      execute immediate 'select test_get_vertical_datum_info(:1, :2, :3) from dual'
         into l_xml_str
         using l_location_ids, 'ft', '&&office_id';
      cwms_err.raise('ERROR', 'Expected exception not raised');
   exception
      when others then
         ut.expect(regexp_like(dbms_utility.format_error_stack, 'character string buffer too small', 'mn')).to_be_true;
   end;

   execute immediate 'drop function test_get_vertical_datum_info';

   end cwdb_246_vertical_datum_info_output_limited_size_to_4000_bytes;

   procedure cwdb_288_location_object_creation
   is
      l_loc_code cwms_20.at_physical_location.location_code%type;
      l_loc_obj cwms_20.location_obj_t;
   begin
      cwms_loc.store_location2(
         p_location_id  => 'TestLocObj',
         p_location_type => 'Test',
         p_elevation => 41.3,
         p_elev_unit_id => 'ft',
         p_vertical_datum => 'NGVD29',
         p_latitude => 38.56,
         p_longitude => -121.73,
         p_horizontal_datum => 'NAD83',
         p_public_name => 'RMA Office',
         p_long_name => 'The RMA Office in Davis.',
         p_description => '<insert terrible, but friendly and funny, description of the group.>',
         p_time_zone_id => 'America/Los_Angeles',
         p_county_name  => 'Yolo',
         p_state_initial => 'CA',
         p_active => 'T',
         p_location_kind_id => 'SITE',
         p_map_label => 'RMA',
         p_published_latitude => 38.56,
         p_published_longitude => -121.73,
         p_bounding_office_id => 'SPD',
         p_nation_id  => 'UNITED STATES',
         p_nearest_city => 'Davis',
         p_db_office_id => '&&office_id');
      l_loc_code := cwms_loc.get_location_code('&&office_id','TestLocObj');
      l_loc_obj := location_obj_t(l_loc_code);
      ut.expect(l_loc_obj.location_ref.office_id).to_equal('&&office_id');
      ut.expect(l_loc_obj.location_ref.base_location_id).to_equal('TestLocObj');
      ut.expect(l_loc_obj.nation_id).to_equal('United States');

      l_loc_obj := cwms_loc.retrieve_location(l_loc_code);
      ut.expect(l_loc_obj.location_ref.office_id).to_equal('&&office_id');
      ut.expect(l_loc_obj.location_ref.base_location_id).to_equal('TestLocObj');
      ut.expect(l_loc_obj.nation_id).to_equal('United States');
   end;
   --------------------------------------------------------------------------------
   -- procedure cwdb_290_bounding_office_overrides_lat_lon
   --------------------------------------------------------------------------------
   procedure cwdb_290_bounding_office_overrides_lat_lon
   is
      l_bounding_office  cwms_v_office.office_id%type;
      l_expected_results cwms_t_str_tab := cwms_t_str_tab('SWT', 'SPK');
      exc_location_id_not_found   exception;
      pragma exception_init (exc_location_id_not_found, -20025);
   begin
      for i in 1..2 loop
         begin
            cwms_loc.delete_location('MikesHouse', cwms_util.delete_all, 'SPK');
         exception
            when exc_location_id_not_found then null;
         end;
         -----------------------------------------------------------------------
         -- store a location within SWT but assign SPK as the bounding office --
         -----------------------------------------------------------------------
         cwms_loc.store_location2 (
            p_location_id				=> 'MikesHouse',
            p_latitude					=> 36.147,
            p_longitude 				=> -96.089,
            p_public_name				=> 'Mike''s House',
            p_long_name 				=> 'The place where Mike lives',
            p_description				=> 'In Lakeside Park',
            p_time_zone_id 			=> 'US/Central',
            p_county_name				=> 'Tulsa',
            p_state_initial			=> 'OK',
            p_active 					=> 'T',
            p_bounding_office_id    => case when i = 1 then null else 'SPK' end,
            p_nation_id 				=> 'US',
            p_nearest_city 			=> 'Sand Springs',
            p_db_office_id 			=> 'SPK');

         select bounding_office_id
         into l_bounding_office
         from av_loc
         where location_id = 'MikesHouse'
            and db_office_id = 'SPK'
            and unit_system = 'SI';

         ut.expect(l_bounding_office).to_equal(l_expected_results(i));
      end loop;

   end cwdb_290_bounding_office_overrides_lat_lon;


   procedure cwms_305_spk_location_not_creating
   is
      l_count number;
      l_location_name varchar(32) := 'Animas R @ Durango';
   begin
      cwms_loc.store_location2(
         p_location_id => l_location_name,
         p_location_type => NULL,
         p_elevation => 5239.0,
         p_elev_unit_id => 'ft',
         p_vertical_datum => 'NGVD29',
         p_latitude => 37.2791688,
         p_longitude => -107.8803445,
         p_horizontal_datum => 'NAD83',
         p_public_name => 'Animas River at Durango, CO',
         p_long_name => NULL,
         p_description => NULL,
         p_time_zone_id => 'US/Mountain',
         p_county_name => 'La Plata',
         p_state_initial => 'CO',
         p_active => NULL,
         p_location_kind_id => 'STREAM',
         p_map_label => NULL,
         p_published_latitude => NULL,
         p_published_longitude => NULL,
         p_bounding_office_id => NULL,
         p_nation_id => NULL,
         p_nearest_city => 'Durango',
         p_ignorenulls => 'T',
         p_db_office_id => 'SPK');
      select count(*) into l_count
        from av_loc
       where db_office_id = 'SPK'
         and location_id = l_location_name
         and unit_system = 'SI';

      ut.expect(l_count).to_equal(1);

   end cwms_305_spk_location_not_creating;

   procedure store_loc_group_cwms_cat is
   begin
      cwms_loc.store_loc_group('Default', 'DistrictTestGroup', 'Unit Test Group',
      'F', 'T', null, null, '&&office_id');
      cwms_loc.delete_loc_group('Default', 'DistrictTestGroup', 'T', '&&office_id');
   end store_loc_group_cwms_cat;
   -------------------------------------------
   -- procedure test_international_location --
   -------------------------------------------
   procedure test_international_location
   is
      l_loc_rec av_loc%rowtype;
   begin
      cwms_loc.store_location2(
         p_location_id => 'International_1',
         p_state_initial => 'UC',
         p_nation_id => 'ZZ',
         p_db_office_id => 'LRE');

      select *
        into l_loc_rec
        from av_loc
       where db_office_id = 'LRE'
         and location_id = 'International_1'
         and unit_system = 'SI';

      ut.expect(l_loc_rec.nation_id).to_equal('International');
      ut.expect(l_loc_rec.state_initial).to_equal('UC');
      ut.expect(l_loc_rec.county_name).to_equal('No County - Location Shared by USA and Canada');

      cwms_loc.store_location2(
         p_location_id => 'International_2',
         p_state_initial => 'UM',
         p_nation_id => 'ZZ',
         p_db_office_id => 'SPL');

      select *
        into l_loc_rec
        from av_loc
       where db_office_id = 'SPL'
         and location_id = 'International_2'
         and unit_system = 'SI';

      ut.expect(l_loc_rec.nation_id).to_equal('International');
      ut.expect(l_loc_rec.state_initial).to_equal('UM');
      ut.expect(l_loc_rec.county_name).to_equal('No County - Location Shared by USA and Mexico');


   end test_international_location;
   -------------------------------------------------
   -- procedure test_vertical_datum_info_series_f --
   -------------------------------------------------
   procedure test_vertical_datum_info_series_f
   is
      type offset_rec_t is record(
         datum1         at_vert_datum_offset.vertical_datum_id_1%type,
         datum2         at_vert_datum_offset.vertical_datum_id_1%type,
         effective_date at_vert_datum_offset.effective_date%type,
         offset         at_vert_datum_offset.offset%type,
         description    at_vert_datum_offset.description%type);
      type offset_tab_t is table of offset_rec_t;
      l_expected_xml clob :=
'<vertical-datum-info-series office="&&office_id" unit="ft">
  <location>TestLoc1</location>
  <native-datum>TestDatum</native-datum>
  <elevation>500</elevation>
  <offset time="2000-01-01T00:00:00Z" estimate="false">
    <to-datum>NGVD-29</to-datum>
    <value>1.1</value>
    <description>1st Offset</description>
  </offset>
  <offset time="2000-01-01T00:00:00Z" estimate="true">
    <to-datum>NAVD-88</to-datum>
    <value>1.15</value>
    <description/>
  </offset>
  <offset time="2010-01-01T00:00:00Z" estimate="false">
    <to-datum>NGVD-29</to-datum>
    <value>1.3</value>
    <description>2nd Offset</description>
  </offset>
  <offset time="2010-01-01T00:00:00Z" estimate="true">
    <to-datum>NAVD-88</to-datum>
    <value>1.35</value>
    <description/>
  </offset>
  <offset time="2012-05-11T00:00:00Z" estimate="false">
    <to-datum>NAVD-88</to-datum>
    <value>1.785</value>
    <description/>
  </offset>
  <offset time="2020-01-01T00:00:00Z" estimate="false">
    <to-datum>NGVD-29</to-datum>
    <value>1.5</value>
    <description>3rd Offset</description>
  </offset>
  <offset time="2020-01-01T00:00:00Z" estimate="false">
    <to-datum>NAVD-88</to-datum>
    <value>1.985</value>
    <description/>
  </offset>
</vertical-datum-info-series>';

      l_empty_xml clob :=
'<vertical-datum-info-series office="&&office_id" unit="ft">
  <location>TestLoc1</location>
  <native-datum>OTHER</native-datum>
  <elevation>500</elevation>
</vertical-datum-info-series>';
      l_expected_offsets offset_tab_t;
      l_count binary_integer;
   begin
      teardown;
      l_expected_offsets := offset_tab_t();
      l_expected_offsets.extend(7);

      l_expected_offsets(1).datum1 := 'LOCAL';
      l_expected_offsets(1).datum2 := 'NGVD29';
      l_expected_offsets(1).effective_date := date '2000-01-01';
      l_expected_offsets(1).offset := 1.1;
      l_expected_offsets(1).description := '1st Offset';

      l_expected_offsets(2).datum1 := 'LOCAL';
      l_expected_offsets(2).datum2 := 'NAVD88';
      l_expected_offsets(2).effective_date := date '2000-01-01';
      l_expected_offsets(2).offset := 1.15;
      l_expected_offsets(2).description := 'ESTIMATE';

      l_expected_offsets(3).datum1 := 'LOCAL';
      l_expected_offsets(3).datum2 := 'NGVD29';
      l_expected_offsets(3).effective_date := date '2010-01-01';
      l_expected_offsets(3).offset := 1.3;
      l_expected_offsets(3).description := '2nd Offset';

      l_expected_offsets(4).datum1 := 'LOCAL';
      l_expected_offsets(4).datum2 := 'NAVD88';
      l_expected_offsets(4).effective_date := date '2010-01-01';
      l_expected_offsets(4).offset := 1.35;
      l_expected_offsets(4).description := 'ESTIMATE';

      l_expected_offsets(5).datum1 := 'LOCAL';
      l_expected_offsets(5).datum2 := 'NAVD88';
      l_expected_offsets(5).effective_date := date '2012-05-11';
      l_expected_offsets(5).offset := 1.785;
      l_expected_offsets(5).description := null;

      l_expected_offsets(6).datum1 := 'LOCAL';
      l_expected_offsets(6).datum2 := 'NGVD29';
      l_expected_offsets(6).effective_date := date '2020-01-01';
      l_expected_offsets(6).offset := 1.5;
      l_expected_offsets(6).description := '3rd Offset';

      l_expected_offsets(7).datum1 := 'LOCAL';
      l_expected_offsets(7).datum2 := 'NAVD88';
      l_expected_offsets(7).effective_date := date '2020-01-01';
      l_expected_offsets(7).offset := 1.985;
      l_expected_offsets(7).description := null;

      cwms_loc.store_location(
         p_location_id    => 'TestLoc1',
         p_db_office_id   => '&&office_id',
         p_elevation      => 500,
         p_elev_unit_id   => 'ft',
         p_vertical_datum => 'LOCAL');

      ut.expect(cwms_loc.get_vertical_datum_info_series_f('TestLoc1', 'ft', '&&office_id')).to_equal(l_empty_xml);

      cwms_loc.set_local_vert_datum_name(
         p_location_id     => 'TestLoc1',
         p_vert_datum_name => 'TestDatum',
         p_fail_if_exists  => 'F',
         p_office_id       => '&&office_id');

      l_empty_xml := replace(l_empty_xml, 'OTHER', 'TestDatum');
      ut.expect(cwms_loc.get_vertical_datum_info_series_f('TestLoc1', 'ft', '&&office_id')).to_equal(l_empty_xml);

      cwms_loc.store_vertical_datum_offset(
         p_location_id         => 'TestLoc1',
         p_vertical_datum_id_1 => 'NGVD29',
         p_vertical_datum_id_2 => 'NAVD88',
         p_offset              => .05,
         p_unit                => 'ft',
         p_time_zone           => 'UTC',
         p_description         => 'VERTCON ESTIMATE',
         p_office_id           => '&&office_id');

      cwms_loc.store_vertical_datum_offset(
         p_location_id         => 'TestLoc1',
         p_vertical_datum_id_1 => 'LOCAL',
         p_vertical_datum_id_2 => 'NGVD29',
         p_offset              => 1.1,
         p_unit                => 'ft',
         p_effective_date      => date '2000-01-01',
         p_time_zone           => 'UTC',
         p_description         => '1st Offset',
         p_office_id           => '&&office_id');

      cwms_loc.store_vertical_datum_offset(
         p_location_id         => 'TestLoc1',
         p_vertical_datum_id_1 => 'LOCAL',
         p_vertical_datum_id_2 => 'NGVD29',
         p_offset              => 1.3,
         p_unit                => 'ft',
         p_effective_date      => date '2010-01-01',
         p_time_zone           => 'UTC',
         p_description         => '2nd Offset',
         p_office_id           => '&&office_id');

      cwms_loc.store_vertical_datum_offset(
         p_location_id         => 'TestLoc1',
         p_vertical_datum_id_1 => 'NGVD29',
         p_vertical_datum_id_2 => 'NAVD88',
         p_offset              => .485,
         p_unit                => 'ft',
         p_effective_date      => date '2012-05-11',
         p_time_zone           => 'UTC',
         p_description         => 'Survey Value',
         p_office_id           => '&&office_id');

      cwms_loc.store_vertical_datum_offset(
         p_location_id         => 'TestLoc1',
         p_vertical_datum_id_1 => 'LOCAL',
         p_vertical_datum_id_2 => 'NGVD29',
         p_offset              => 1.5,
         p_unit                => 'ft',
         p_effective_date      => date '2020-01-01',
         p_time_zone           => 'UTC',
         p_description         => '3rd Offset',
         p_office_id           => '&&office_id');

      commit;

      ut.expect(cwms_loc.get_vertical_datum_info_series_f('TestLoc1', 'ft', '&&office_id')).to_equal(l_expected_xml);

      begin
         cwms_loc.set_vertical_datum_info_series(l_empty_xml, 'T');
         cwms_err.raise('ERROR', 'Expected exception not raised');
      exception
         when others then
            ut.expect(regexp_like(dbms_utility.format_error_stack, 'Vertical datum info would be overwritten', 'mn')).to_be_true;
      end;

      cwms_loc.set_vertical_datum_info_series(l_empty_xml, 'F');
      ut.expect(cwms_loc.get_vertical_datum_info_series_f('TestLoc1', 'ft', '&&office_id')).to_equal(l_empty_xml);

      cwms_loc.set_vertical_datum_info_series(l_expected_xml, 'T');

      select count(*)
        into l_count
        from av_vert_datum_offset
       where location_id = 'TestLoc1'
          and office_id = '&&office_id';

      ut.expect(l_count).to_equal(l_expected_offsets.count);

      l_count := 0;
      for rec in (select *
                    from av_vert_datum_offset
                   where location_id = 'TestLoc1'
                     and office_id = '&&office_id'
                   order by effective_date, vertical_datum_id_2 desc
                 )
      loop
         l_count := l_count + 1;
         ut.expect(rec.vertical_datum_id_1).to_equal(l_expected_offsets(l_count).datum1);
         ut.expect(rec.vertical_datum_id_2).to_equal(l_expected_offsets(l_count).datum2);
         ut.expect(rec.effective_date).to_equal(l_expected_offsets(l_count).effective_date);
         ut.expect(round(cwms_util.convert_units(rec.offset, 'm', 'ft'), 9)).to_equal(round(l_expected_offsets(l_count).offset, 9));
         ut.expect(rec.description).to_equal(l_expected_offsets(l_count).description, a_nulls_are_equal => true);
      end loop;

   end test_vertical_datum_info_series_f;

   --------------------------------------------------------------------------------
   -- procedure test_query_vertical_datum_offset
   --------------------------------------------------------------------------------
   procedure test_query_vertical_datum_offset
   is
      l_office_id   av_loc.db_office_id%TYPE;
      l_location_id av_loc.location_id%TYPE;
      l_offset      binary_double;
   begin
      setup;

      l_office_id := '&&office_id';
      l_location_id := 'TestLoc1';

      cwms_loc.store_location (
         p_location_id    => l_location_id,
         p_db_office_id   => l_office_id,
         p_latitude       => 34.25,
         p_longitude      => -96.5,
         p_vertical_datum => 'NGVD29');

      select cwms_loc.get_vertical_datum_offset(
            p_location_id         => l_location_id,
            p_vertical_datum_id_1 => 'NGVD29',
            p_vertical_datum_id_2 => 'NAVD88',
            p_datetime            => sysdate,
            p_time_zone           => 'UTC',
            p_unit                => 'ft',
            p_office_id           => l_office_id)
        into l_offset
        from dual;

      ut.expect(l_offset).to_be_not_null;

   end test_query_vertical_datum_offset;

    --------------------------------------------------------------------------------
    -- procedure test_av_loc_text_search
    --------------------------------------------------------------------------------
   procedure test_av_loc_text_search
       is
       l_count number;
       l_loc_id varchar2(64) := 'VANL';
    begin
       -- ensure clean state
       teardown;

       -- create test location
       cwms_loc.store_location(
          p_location_id  => l_loc_id,
          p_db_office_id => '&&office_id',
          p_county_name => 'Crawford',
          p_longitude => -94.3927778,
          p_latitude => 35.4844444,
          p_horizontal_datum => 'NAD83',
          p_time_zone_id => 'US/Central',
          p_state_initial => 'AR',
          p_public_name => 'Lee Creek at Lee Creek Reservoir',
          p_long_name => 'Lee Creek at Lee Creek Reservoir near Van Buren,AR',
          p_description => 'Lee Creek at Lee Creek Reservoir near Van Buren,AR',
          p_location_type => 'Stream Gauge'
       );

       commit;
       ctx_ddl.sync_index('AT_PHYSICAL_LOCATION_SEARCH_IDX');
       -- search using Oracle Text through the view
       select count(*)
       into l_count
       from av_loc
       where contains(search_doc, 'Van Buren') > 0
         and unit_system = 'SI'
         and location_id = l_loc_id;

       ut.expect(l_count).to_equal(1);

    end test_av_loc_text_search;

    --------------------------------------------------------------------------------
    -- procedure test_av_loc2_text_search
    --------------------------------------------------------------------------------
    procedure test_av_loc2_text_search
       is
       l_count number;
       l_loc_id varchar2(64) := 'VANB';
    begin
       teardown;

       cwms_loc.store_location(
          p_location_id  => l_loc_id,
          p_db_office_id => '&&office_id',
          p_county_name => 'Crawford',
          p_longitude => -94.3565139,
          p_latitude => 35.43085,
          p_horizontal_datum => 'NAD83',
          p_time_zone_id => 'US/Central',
          p_state_initial => 'AR',
          p_public_name => 'AR Rvr VanBuren',
          p_long_name => 'Arkansas River near Van Buren, AR',
          p_description => 'Arkansas River near Van Buren, AR'
       );

       commit;
       ctx_ddl.sync_index('AT_PHYSICAL_LOCATION_SEARCH_IDX');
       select count(*)
       into l_count
       from av_loc2
       where contains(search_doc, 'VanBuren') > 0
         and unit_system = 'SI'
         and location_id = l_loc_id;

       ut.expect(l_count).to_equal(1);

    end test_av_loc2_text_search;

   --------------------------------------------------------------------------------
   -- function equivalent_geometries
   --------------------------------------------------------------------------------
   function equivalent_geometries (
      p_geometry_1 in sdo_geometry,
      p_geometry_2 in sdo_geometry,
      p_tolerance  in number default 0.001)
      return boolean
   is
   begin
      if (p_geometry_1 is null) != (p_geometry_2 is null) then
        return false;
      else
         return sdo_geom.relate(p_geometry_1, 'EQUAL', p_geometry_2, p_tolerance) = 'EQUAL';
      end if;
   exception
      when others then return false;
   end equivalent_geometries;

   --------------------------------------------------------------------------------
   -- procedure test_mods_for_generic_geometry
   --------------------------------------------------------------------------------
   procedure test_mods_for_generic_geometry
   is
      type info_rec_t is record(
                         location_kind av_loc.location_kind_id%type,
                         elevation     av_loc.elevation%type,
                         vert_datum    av_loc.vertical_datum%type,
                         latitude      av_loc.latitude%type,
                         longitude     av_loc.longitude%type,
                         horiz_datum   av_loc.horizontal_datum%type,
                         county_name   av_loc.county_name%type,
                         state_initial av_loc.state_initial%type,
                         nation_id     av_loc.nation_id%type,
                         nearest_city  av_loc.nearest_city%type,
                         time_zone     av_loc.time_zone_name%type);
      type info_tab_t is table of info_rec_t index by varchar2(32767);
      l_info                 info_tab_t;
      l_view_rec             av_loc%rowtype;
      l_view_rec_base        av_loc%rowtype;
      l_office_id            av_loc.db_office_id%type;
      l_location_kind_id     av_loc.location_kind_id%type;
      l_elevation            av_loc.elevation%type;
      l_horizontal_datum     av_loc.horizontal_datum%type;
      l_location_id          av_loc.location_id%type;
      l_latitude             av_loc.latitude%type;
      l_vertical_datum       av_loc.vertical_datum%type;
      l_longitude            av_loc.longitude%type;
      l_time_zone_id         av_loc.time_zone_name%type;
      l_data                 clob;
      l_data_tab             str_tab_tab_t;
      l_county_state         str_tab_t;
      l_location_codes       number_tab_t;
      l_count                binary_integer;
      l_crsr                 sys_refcursor;
      l_crsr2                sys_refcursor;
      l_db_office_ids        str_tab_t;
      l_db_office_ids2       str_tab_t;
      l_location_ids         str_tab_t;
      l_base_location_ids    str_tab_t;
      l_sub_location_ids     str_tab_t;
      l_state_initials       str_tab_t;
      l_county_names         str_tab_t;
      l_time_zone_names      str_tab_t;
      l_location_types       str_tab_t;
      l_latitudes            number_tab_t;
      l_longitudes           number_tab_t;
      l_horizontal_datums    str_tab_t;
      l_elevations           number_tab_t;
      l_elev_unit_ids        str_tab_t;
      l_vertical_datums      str_tab_t;
      l_public_names         str_tab_t;
      l_long_names           str_tab_t;
      l_descriptions         str_tab_t;
      l_active_flags         str_tab_t;
      l_location_kind_ids    str_tab_t;
      l_map_labels           str_tab_t;
      l_published_latitudes  number_tab_t;
      l_published_longitudes number_tab_t;
      l_bounding_office_ids  str_tab_t;
      l_nation_ids           str_tab_t;
      l_nearest_cities       str_tab_t;
      l_geometry             sdo_geometry;
      l_vidx                 integer;
      exc_location_id_not_found EXCEPTION;
      PRAGMA EXCEPTION_INIT (exc_location_id_not_found, -20025);
   begin
      -----------------------------------------------
      -- retrieve and parse the locations to store --
      -----------------------------------------------
      l_office_id := '&&office_id';
      dbms_lob.createtemporary(l_data, true);
      select value
        into l_data
        from at_clob
       where id = '/TEST/CWMS-2430';
      l_data_tab := cwms_util.parse_delimited_text (
         p_text 	         => l_data,
         p_field_delimiter => chr(9),
         p_keep_quotes     => 'T');
      for i in 1..l_data_tab.count loop
         exit when l_data_tab(i).count < 13;
         l_location_id      := l_data_tab(i)(2);
         l_location_kind_id := l_data_tab(i)(3);
         l_elevation        := to_number(l_data_tab(i)(4));
         l_vertical_datum   := l_data_tab(i)(5);
         l_latitude         := to_number(l_data_tab(i)(6));
         l_longitude        := to_number(l_data_tab(i)(7));
         l_horizontal_datum := l_data_tab(i)(8);
         l_time_zone_id     := l_data_tab(i)(9);
         ----------------------------------------------------------
         -- compute data from lat/lon and store as expected data --
         ----------------------------------------------------------
         l_county_state := cwms_loc.get_county_id(l_latitude, l_longitude);
         l_info(l_location_id) := info_rec_t(
            l_location_kind_id,                                                             -- location kind
            l_elevation,                                                                    -- elevation
            l_vertical_datum,                                                               -- vertical datum
            l_latitude,                                                                     -- latitude
            l_longitude,                                                                    -- longitude
            l_horizontal_datum,                                                             -- horizontal datum
            l_county_state(1),                                                              -- county name
            l_county_state(2),                                                              -- state initial
            null,                                                                           -- nation id (populated below)
            cwms_util.join_text(cwms_loc.get_nearest_city(l_latitude, l_longitude), ', '),  -- nearest city
            l_time_zone_id);                                                                -- time zone
         select cntry_name
           into l_info(l_location_id).nation_id
           from cwms_nation_sp
          where fips_cntry = cwms_loc.get_nation_id(l_latitude, l_longitude);
         ---------------------------------------------------------------------------
         -- store location without data computed from lat/lon (will auto-compute) --
         ---------------------------------------------------------------------------
         cwms_loc.store_location2 (
            p_location_id      => l_location_id,
            p_elevation        => l_elevation,
            p_elev_unit_id     => 'ft',
            p_vertical_datum   => l_vertical_datum,
            p_latitude         => l_latitude,
            p_longitude        => l_longitude,
            p_horizontal_datum => l_horizontal_datum,
            p_time_zone_id     => l_time_zone_id,
            p_active           => 'T',
            p_db_office_id     => l_office_id,
            p_location_kind_id => l_location_kind_id);
      end loop;
      commit;
      ------------------------------------------------------------
      -- validate lat/lon and values auto-computed from lat/lon --
      ------------------------------------------------------------
      l_location_codes := number_tab_t();
      for i in 1..l_data_tab.count loop
         exit when l_data_tab(i).count < 13;
         l_location_codes.extend;
         l_location_id := l_data_tab(i)(2);
         l_latitude    := to_number(l_data_tab(i)(6));
         l_longitude   := to_number(l_data_tab(i)(7));
         dbms_output.put_line('--1> '||l_location_id);
         select *
           into l_view_rec
           from av_loc
          where db_office_id = l_office_id
            and location_id = l_location_id
            and unit_system = 'EN';
         l_location_codes(i) := l_view_rec.location_code;
         ut.expect(l_view_rec.latitude).to_equal(l_latitude);
         ut.expect(l_view_rec.longitude).to_equal(l_longitude);
         ut.expect(l_view_rec.county_name).to_equal(l_info(l_location_id).county_name);
         ut.expect(l_view_rec.state_initial).to_equal(l_info(l_location_id).state_initial);
         ut.expect(l_view_rec.nation_id).to_equal(l_info(l_location_id).nation_id);
         ut.expect(l_view_rec.nearest_city).to_equal(l_info(l_location_id).nearest_city);
      end loop;
      --------------------------------------
      -- clear at_location_geometry table --
      --------------------------------------
      delete
        from at_location_geometry
       where location_code in (select column_value
                                 from table(l_location_codes))
          or location_code in (select base_location_code
                                 from at_physical_location
                                where location_code in (select column_value
                                                          from table(l_location_codes)
                                                       )
                              );
      select count(*)
        into l_count
        from at_location_geometry
       where location_code in (select column_value from table(l_location_codes));
      ut.expect(l_count).to_equal(0);
      -------------------------------------------------------------------------------------------------------
      -- delete from at_location_geometry and verify lat/lons are null but computed values are not changed --
      -------------------------------------------------------------------------------------------------------
      for i in 1..l_data_tab.count loop
         exit when l_data_tab(i).count < 13;
         l_location_id      := l_data_tab(i)(2);
         dbms_output.put_line('--2> '||l_location_id);
         delete
           from at_location_geometry
          where location_code = l_location_codes(i);
         select *
           into l_view_rec
           from av_loc
          where db_office_id = l_office_id
            and location_id = l_location_id
            and unit_system = 'EN';
         ut.expect(l_view_rec.latitude).to_be_null;
         ut.expect(l_view_rec.longitude).to_be_null;
         ut.expect(l_view_rec.county_name).to_equal(l_info(l_location_id).county_name);
         ut.expect(l_view_rec.state_initial).to_equal(l_info(l_location_id).state_initial);
         ut.expect(l_view_rec.nation_id).to_equal(l_info(l_location_id).nation_id);
         ut.expect(l_view_rec.nearest_city).to_equal(l_info(l_location_id).nearest_city);
      end loop;
      ---------------------------------
      -- set computed values to null --
      ---------------------------------
      update at_physical_location
         set county_code = null,
             nation_code = null,
             nearest_city = null
       where location_code in (select column_value from table(l_location_codes));
      ----------------------------------------------------------------------------------------
      -- verify computed values are null before setting lat/lons and are correct afterwards --
      ----------------------------------------------------------------------------------------
      for i in 1..l_data_tab.count loop
         exit when l_data_tab(i).count < 13;
         l_location_id := l_data_tab(i)(2);
         dbms_output.put_line('--3> '||l_location_id);
         select *
           into l_view_rec
           from av_loc
          where db_office_id = l_office_id
            and location_id = l_location_id
            and unit_system = 'EN';
         if instr(l_location_id, '-') > 0 then
            -----------------------------------------
            -- possibly has a base location stored --
            -----------------------------------------
            begin
               select *
                 into l_view_rec_base
                 from av_loc
                where db_office_id = l_office_id
                  and location_id = cwms_util.split_text(l_location_id, 1, '-')
                  and unit_system = 'EN';
               ----------------------------------------------------------------------------
               -- has a base location stored, info is inherited (may or may not be null) --
               ----------------------------------------------------------------------------
               ut.expect(nvl(l_view_rec.county_name,   '@')).to_equal(nvl(l_view_rec_base.county_name,   '@'));
               ut.expect(nvl(l_view_rec.state_initial, '@')).to_equal(nvl(l_view_rec_base.state_initial, '@'));
               ut.expect(nvl(l_view_rec.nation_id,     '@')).to_equal(nvl(l_view_rec_base.nation_id,     '@'));
               ut.expect(nvl(l_view_rec.nearest_city,  '@')).to_equal(nvl(l_view_rec_base.nearest_city,  '@'));
            exception
               when no_data_found then
                  ------------------------------------------------
                  -- no base location stored, info must be null --
                  ------------------------------------------------
                  ut.expect(l_view_rec.county_name).to_be_null;
                  ut.expect(l_view_rec.state_initial).to_be_null;
                  ut.expect(l_view_rec.nation_id).to_be_null;
                  ut.expect(l_view_rec.nearest_city).to_be_null;
            end;
         else
            -------------------------------------------
            -- is a base location, info must be null --
            -------------------------------------------
            ut.expect(l_view_rec.county_name).to_be_null;
            ut.expect(l_view_rec.state_initial).to_be_null;
            ut.expect(l_view_rec.nation_id).to_be_null;
            ut.expect(l_view_rec.nearest_city).to_be_null;
         end if;
         ------------------------------------------
         -- set lat/lon and verify computed_info --
         ------------------------------------------
         l_location_id := l_data_tab(i)(2);
         l_latitude    := to_number(l_data_tab(i)(6));
         l_longitude   := to_number(l_data_tab(i)(7));
         cwms_loc.store_location (
            p_location_id 	=> l_location_id,
            p_latitude 	   => l_latitude,
            p_longitude 	=> l_longitude,
            p_db_office_id => l_office_id);
         select *
           into l_view_rec
           from av_loc
          where db_office_id = l_office_id
            and location_id = l_location_id
            and unit_system = 'EN';
         ut.expect(l_view_rec.latitude).to_equal(l_latitude);
         ut.expect(l_view_rec.longitude).to_equal(l_longitude);
         ut.expect(l_view_rec.county_name).to_equal(l_info(l_location_id).county_name);
         ut.expect(l_view_rec.state_initial).to_equal(l_info(l_location_id).state_initial);
         ut.expect(l_view_rec.nation_id).to_equal(l_info(l_location_id).nation_id);
         ut.expect(l_view_rec.nearest_city).to_equal(l_info(l_location_id).nearest_city);
      end loop;
      ----------------------------------------------------------
      -- test mods to cwms_cat.cat_location and cat_location2 --
      ----------------------------------------------------------
      cwms_cat.cat_location(
         p_cwms_cat       => l_crsr,
         p_elevation_unit => 'ft' ,
         p_db_office_id   => l_office_id);
      fetch l_crsr
       bulk collect
       into l_db_office_ids,
            l_location_ids,
            l_base_location_ids,
            l_sub_location_ids,
            l_state_initials,
            l_county_names,
            l_time_zone_names,
            l_location_types,
            l_latitudes,
            l_longitudes,
            l_horizontal_datums,
            l_elevations,
            l_elev_unit_ids,
            l_vertical_datums,
            l_public_names,
            l_long_names,
            l_descriptions,
            l_active_flags;
      close l_crsr;
      for i in 1..l_db_office_ids.count loop
         if l_info.exists(l_location_ids(i)) then
            dbms_output.put_line('--4> '||l_location_ids(i));
            ut.expect(l_base_location_ids(i)).to_equal(cwms_util.get_base_id(l_location_ids(i)));
            ut.expect(l_sub_location_ids(i)).to_equal(cwms_util.get_sub_id(l_location_ids(i)));
            ut.expect(l_state_initials(i)).to_equal(l_info(l_location_ids(i)).state_initial);
            ut.expect(l_county_names(i)).to_equal(l_info(l_location_ids(i)).county_name);
            ut.expect(l_time_zone_names(i)).to_equal(l_info(l_location_ids(i)).time_zone);
            ut.expect(round(l_latitudes(i), 6)).to_equal(round(l_info(l_location_ids(i)).latitude, 6));
            ut.expect(round(l_longitudes(i), 6)).to_equal(round(l_info(l_location_ids(i)).longitude, 6));
            ut.expect(l_horizontal_datums(i)).to_equal(l_info(l_location_ids(i)).horiz_datum);
            ut.expect(round(l_elevations(i), 6)).to_equal(round(l_info(l_location_ids(i)).elevation, 6));
            ut.expect(replace(l_vertical_datums(i), 'LOCAL', 'OTHER')).to_equal(l_info(l_location_ids(i)).vert_datum);
         end if;
      end loop;

      cwms_cat.cat_location2(
         p_cwms_cat       => l_crsr,
         p_elevation_unit => 'ft' ,
         p_db_office_id   => l_office_id);
      fetch l_crsr
       bulk collect
       into l_db_office_ids,
            l_location_ids,
            l_base_location_ids,
            l_sub_location_ids,
            l_state_initials,
            l_county_names,
            l_time_zone_names,
            l_location_types,
            l_latitudes,
            l_longitudes,
            l_horizontal_datums,
            l_elevations,
            l_elev_unit_ids,
            l_vertical_datums,
            l_public_names,
            l_long_names,
            l_descriptions,
            l_active_flags,
            l_location_kind_ids,
            l_map_labels,
            l_published_latitudes,
            l_published_longitudes,
            l_bounding_office_ids,
            l_nation_ids,
            l_nearest_cities;
      close l_crsr;
      for i in 1..l_db_office_ids.count loop
         if l_info.exists(l_location_ids(i)) then
            dbms_output.put_line('--5> '||l_location_ids(i));
            ut.expect(l_base_location_ids(i)).to_equal(cwms_util.get_base_id(l_location_ids(i)));
            ut.expect(l_sub_location_ids(i)).to_equal(cwms_util.get_sub_id(l_location_ids(i)));
            ut.expect(l_state_initials(i)).to_equal(l_info(l_location_ids(i)).state_initial);
            ut.expect(l_county_names(i)).to_equal(l_info(l_location_ids(i)).county_name);
            ut.expect(l_time_zone_names(i)).to_equal(l_info(l_location_ids(i)).time_zone);
            ut.expect(round(l_latitudes(i), 6)).to_equal(round(l_info(l_location_ids(i)).latitude, 6));
            ut.expect(round(l_longitudes(i), 6)).to_equal(round(l_info(l_location_ids(i)).longitude, 6));
            ut.expect(l_horizontal_datums(i)).to_equal(l_info(l_location_ids(i)).horiz_datum);
            ut.expect(round(l_elevations(i), 6)).to_equal(round(l_info(l_location_ids(i)).elevation, 6));
            ut.expect(replace(l_vertical_datums(i), 'LOCAL', 'OTHER')).to_equal(l_info(l_location_ids(i)).vert_datum);
            ut.expect(l_nation_ids(i)).to_equal(l_info(l_location_ids(i)).nation_id);
            ut.expect(l_nearest_cities(i)).to_equal(l_info(l_location_ids(i)).nearest_city);
         end if;
      end loop;
      -------------------------------------------
      -- test mods to cwms_project.cat_project --
      -------------------------------------------
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'BIGH')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'Small sediment load due to clay soil and pastureland in drainage basin. Avg sedimentation rate of 22 ac-ft/yr is expected with 80% of sediment deposited below elev 858.0; remaining 20% expected to be deposited between elev 858.0-867.5.',
         'There is no significant downstream urban development near the dam.',
         'The bankfull capacity below the dam is 1,700 cfs.',
         null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'MARI')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'Large amount of sedimentation due to large amount of agriculture in drainage basin and absence of upstream reservoirs. 1982 survey indicated sedimentation rate of 336.7ac-ft/yr. Marion reservoir has 5 degradation ranges extending to river mile 120.0.',
         'Florence, KS is downstream from the dam on the Cottonwood River.',
         'Bankfull capacity below the dam is 8700 cfs (stage 17.8 ft). Bankfull capacity at Marion Levee is 4900 cfs (stage 16.0 ft). Bankfull capacity at Florence is 7400 cfs (stage 21.0 ft). Bankfull capacity at Plymouth is 9800 cfs (stage 28.0 ft).',
         null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'PATM')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'Sedimentation information unavailable.',
         'There is no significant downstream urban development near the dam.',
         'Bankfull capacity below the dam is 800 cfs. Bankfull capacity at Chicota gage is 6800 cfs (stage 20.0 ft). Bankfull capacity at Arthur City is 85,385 cfs (stage 27.0 ft).',
         null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'HUGO')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'Kiamichi River is a light sediment-bearing system. Most of the basin is in forest or grasslands, so little sheet erosion has occurred. Banks \& beds of stream \& tributaries contribute little sediment. Total sedimentation rate is 0.20 ac-ft/sq mi/yr.',
         'Sawyer, OK (pop. 274) is immediately southeast of the dam.',
         'Bankfull capacity below the dam is 20,000 cfs. Bankfull capacity at the DeKalb gage is 46,900 cfs (stage 23.7 ft). Bankfull capacity at Index, AR is 95,000 cfs (stage 19.8 ft).',
         null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'EUFA')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'Lake inflow carries large amount of sediment from Canadian, North Canadian, and Deep Fork Rivers. During high-flow, bank caving and erosion becomes a problem. Avg annual sedimentation rate is 9,417 ac-ft/yr.',
         'Eufala, OK is located on the Eufala Reservoir. Whitefield is located downstream from the dam on the mainstem of the Canadian River.',
         'Bankfull Capacity at Whitefield, OK is 40,000 cfs (stage 13.01 ft).',
         null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'COUN')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'Relatively large amount of sedimentation at due to agriculture in drainage basin and absence of upstream reservoirs. Original design estimated sedimentation rate of 206 ac-ft/yr, but 1985 survey indicated a sedimentation rate of 212 ac-ft/yr.',
         'Council Grove, KS and Americus, KS are both on mainstem of the Neosho River.',
         'Bankfull capacity at Council Grove, KS is 3,500 cfs (stage 15.0). Bankfull capacity at Americus, KS is 16,000 cfs (stage 27.50).',
         null,
         null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'CHOU')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         null,
         null,null,null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'NEWT')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         null,
         null,null,null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'ROBE')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         null,
         null,null,null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'WDMA')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         'There are no regulation procedures for sediment, however, W.D. Mayo Reservoir does provide sediment storage for the benefit of the McClellan-Kerr Arkansas River Navigation System. See Plate 2-4 for sedimentation deposition and degradation.',
         null,null,null,null), 'F');
      cwms_project.store_project(project_obj_t(
         location_obj_t(cwms_loc.get_location_code(l_office_id, 'WEBB')),
         null,null,null,null,0,0,0,0,'$',null,null,null,
         null,
         null,null,null,null), 'F');

      cwms_project.cat_project (
         p_project_cat  => l_crsr,
         p_basin_cat    => l_crsr2, -- dummy, not used
         p_db_office_id => l_office_id);

      close l_crsr2;
      fetch l_crsr
       bulk collect
       into l_db_office_ids,
            l_base_location_ids,
            l_sub_location_ids,
            l_time_zone_names,
            l_latitudes,
            l_longitudes,
            l_horizontal_datums,
            l_elevations,
            l_elev_unit_ids,
            l_vertical_datums,
            l_public_names,
            l_long_names,
            l_descriptions,
            l_active_flags;
      close l_crsr;
      for i in 1..l_db_office_ids.count loop
         l_location_id := l_base_location_ids(i)||substr('-', 1, length(l_sub_location_ids(i)))||l_sub_location_ids(i);
         dbms_output.put_line('--6> '||l_location_id);
         ut.expect(l_time_zone_names(i)).to_equal(l_info(l_location_id).time_zone);
         ut.expect(round(l_latitudes(i), 6)).to_equal(round(l_info(l_location_id).latitude, 6));
         ut.expect(round(l_longitudes(i), 6)).to_equal(round(l_info(l_location_id).longitude, 6));
         ut.expect(l_horizontal_datums(i)).to_equal(l_info(l_location_id).horiz_datum);
         ut.expect(round(cwms_util.convert_units(l_elevations(i), 'm', 'ft'), 6)).to_equal(round(l_info(l_location_id).elevation, 6));
         ut.expect(replace(l_vertical_datums(i), 'LOCAL', 'OTHER')).to_equal(l_info(l_location_id).vert_datum);
      end loop;
      ---------------------------------------------
      -- test mods to cwms_embank.cat_embankment --
      ---------------------------------------------
      cwms_embank.store_embankment(embankment_obj_t(
         location_ref_t('BIGH', l_office_id),location_obj_t(location_ref_t('BIGH-Dam', l_office_id)),
         lookup_type_obj_t(l_office_id,'Rolled Earth-Filled','Rolled Earth-Filled','T'),
         lookup_type_obj_t(l_office_id,'Rock Riprap','Rock Riprap','T'),
         lookup_type_obj_t(l_office_id,'Grass-Covered Soil','Grass-Covered Soil','T'),
         0.3,0.3,3902,83,32,'ft'), 'F');
      cwms_embank.store_embankment(embankment_obj_t(
         location_ref_t('MARI', l_office_id),location_obj_t(location_ref_t('MARI-Dam', l_office_id)),
         lookup_type_obj_t(l_office_id,'Rolled Earth-Filled','Rolled Earth-Filled','T'),
         lookup_type_obj_t(l_office_id,'Rock Riprap','Rock Riprap','T'),
         lookup_type_obj_t(l_office_id,'Grass-Covered Soil','Grass-Covered Soil','T'),
         0.3,0.3,8375,67,32,'ft'),'F');
      cwms_embank.store_embankment(embankment_obj_t(
         location_ref_t('PATM', l_office_id),location_obj_t(location_ref_t('PATM-Dam', l_office_id)),
         lookup_type_obj_t(l_office_id,'Rolled Earth-Filled','Rolled Earth-Filled','T'),
         lookup_type_obj_t(l_office_id,'Rock Riprap','Rock Riprap','T'),
         lookup_type_obj_t(l_office_id,'Grass-Covered Soil','Grass-Covered Soil','T'),
         0.3,0.4,7080,96,32,'ft'),'F');
      cwms_embank.store_embankment(embankment_obj_t(
         location_ref_t('HUGO', l_office_id),location_obj_t(location_ref_t('HUGO-Dam', l_office_id)),
         lookup_type_obj_t(l_office_id,'Rolled Earth-Filled','Rolled Earth-Filled','T'),
         lookup_type_obj_t(l_office_id,'Rock Riprap','Rock Riprap','T'),
         lookup_type_obj_t(l_office_id,'Grass-Covered Soil','Grass-Covered Soil','T'),
         0.4,0.4,10200,101,32,'ft'),'F');
      cwms_embank.store_embankment(embankment_obj_t(
         location_ref_t('EUFA', l_office_id),location_obj_t(location_ref_t('EUFA-Dam', l_office_id)),
         lookup_type_obj_t(l_office_id,'Rolled Earth-Filled','Rolled Earth-Filled','T'),
         lookup_type_obj_t(l_office_id,'Rock Riprap','Rock Riprap','T'),
         lookup_type_obj_t(l_office_id,'Grass-Covered Soil','Grass-Covered Soil','T'),
         0.3,0.4,3200,114,32,'ft'),'F');
      cwms_embank.store_embankment(embankment_obj_t(
         location_ref_t('COUN', l_office_id),location_obj_t(location_ref_t('COUN-Dam', l_office_id)),
         lookup_type_obj_t(l_office_id,'Rolled Earth-Filled','Rolled Earth-Filled','T'),
         lookup_type_obj_t(l_office_id,'Rock Riprap','Rock Riprap','T'),
         lookup_type_obj_t(l_office_id,'Grass-Covered Soil','Grass-Covered Soil','T'),
         0.33,0.36,6500,96,32,'ft'),'F');
      commit;
      for rec in (select distinct project_id from av_embankment) loop
         cwms_embank.cat_embankment(l_crsr, rec.project_id, l_office_id);
         fetch l_crsr
          bulk collect
          into l_db_office_ids,
               l_location_ids,
               l_db_office_ids2,
               l_base_location_ids,
               l_sub_location_ids,
               l_time_zone_names,
               l_latitudes,
               l_longitudes,
               l_horizontal_datums,
               l_elevations,
               l_elev_unit_ids,
               l_vertical_datums,
               l_public_names,
               l_long_names,
               l_descriptions,
               l_active_flags;
         close l_crsr;
         ut.expect(l_db_office_ids.count).to_equal(1);
         ut.expect(l_db_office_ids(1)).to_equal(l_office_id);
         ut.expect(l_location_ids(1)).to_equal(rec.project_id);
         ut.expect(l_db_office_ids2(1)).to_equal(l_office_id);
         ut.expect(l_base_location_ids(1)).to_equal(rec.project_id);
         ut.expect(l_sub_location_ids(1)).to_equal('Dam');
         ut.expect(l_time_zone_names(1)).to_equal(l_info(rec.project_id).time_zone);
         l_location_id := rec.project_id||'-'||l_sub_location_ids(1);
         if l_info.exists(l_location_id) then
            --------------------------------------
            -- location was stored in this test --
            --------------------------------------
            ut.expect(round(l_latitudes(1), 6)).to_equal(round(l_info(l_location_id).latitude, 6));
            ut.expect(round(l_longitudes(1), 6)).to_equal(round(l_info(l_location_id).longitude, 6));
            ut.expect(l_horizontal_datums(1)).to_equal(l_info(l_location_id).horiz_datum);
            ut.expect(round(cwms_util.convert_units(l_elevations(1), l_elev_unit_ids(1), 'ft'), 6)).to_equal(round(l_info(l_location_id).elevation, 6));
            ut.expect(replace(l_vertical_datums(1), 'LOCAL', 'OTHER')).to_equal(l_info(l_location_id).vert_datum);
            ----------------------------------------
            -- test cwms_loc.get_location_lat_lon --
            ----------------------------------------
            l_location_id := rec.project_id||'-Dam';
            cwms_loc.get_location_lat_lon(
               p_lat           => l_latitude,
               p_lon           => l_longitude,
               p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id));
            ut.expect(l_latitude).to_equal(l_latitudes(1));
            ut.expect(l_longitude).to_equal(l_longitudes(1));
            -------------------------------------
            -- test cwms_loc.retrieve_geometry --
            -------------------------------------
            l_geometry := cwms_loc.retrieve_geometry(
               p_location_id  => l_location_id,
               p_db_office_id => l_office_id);
            ut.expect(l_geometry.sdo_point.x).to_equal(l_longitude);
            ut.expect(l_geometry.sdo_point.y).to_equal(l_latitude);
            ----------------------------------------------------------
            -- test cwms_loc.store_geometry with non-point geometry --
            ----------------------------------------------------------
            -- store a line geometry for the embankment --
            l_geometry := sdo_geometry(
               2002,
               4326,
               null,
               sdo_elem_info_array(1, 2, 1),
               sdo_ordinate_array(
                  l_longitude,      l_latitude,
                  l_longitude-.005, l_latitude+.005));
            cwms_loc.store_geometry(
               p_location_id    => l_location_id,
               p_geometry       => l_geometry,
               p_fail_if_exists => 'F',
               p_db_office_id   => l_office_id);
            -- verify lat/lon is null --
            declare
               l_lat at_location_geometry.latitude%type;
               l_lon at_location_geometry.longitude%type;
            begin
               cwms_loc.get_location_lat_lon(
                  p_lat           => l_lat,
                  p_lon           => l_lon,
                  p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id));
               ut.expect(l_lat).to_be_null;
               ut.expect(l_lon).to_be_null;
            end;
            -- verify points in line --
            l_geometry := cwms_loc.retrieve_geometry(
               p_location_id  => l_location_id,
               p_db_office_id => l_office_id);
            ut.expect(l_geometry.sdo_ordinates(1)).to_equal(l_longitude);
            ut.expect(l_geometry.sdo_ordinates(2)).to_equal(l_latitude);
            ut.expect(l_geometry.sdo_ordinates(3)).to_equal(l_longitude-.005);
            ut.expect(l_geometry.sdo_ordinates(4)).to_equal(l_latitude+.005);
         else
            ------------------------------------------
            -- location was stored before this test --
            ------------------------------------------
            ut.expect(l_latitudes(1)).to_be_null;
            ut.expect(l_longitudes(1)).to_be_null;
            ut.expect(l_horizontal_datums(1)).to_be_null;
            ut.expect(l_elevations(1)).to_be_null;
            ut.expect(l_vertical_datums(1)).to_be_null;
         end if;
      end loop;
      -------------------------------------
      -- test mods to cwms_lock.cat_lock --
      -------------------------------------
      cwms_lock.store_lock(lock_obj_t(
         location_ref_t(cwms_loc.get_location_code(l_office_id, 'CHOU')),
         location_obj_t(location_ref_t('CHOU-Lock', l_office_id)),
         1468800,'ft3',110,600,9,21,'ft',null,'ft',null,null,null,null,null,null,null), 'F');
      cwms_lock.store_lock(lock_obj_t(
         location_ref_t(cwms_loc.get_location_code(l_office_id, 'NEWT')),
         location_obj_t(location_ref_t('NEWT-Lock', l_office_id)),
         1468800,'ft3',110,600,9,21,'ft',null,'ft',null,null,null,null,null,null,null), 'F');
      cwms_lock.store_lock(lock_obj_t(
         location_ref_t(cwms_loc.get_location_code(l_office_id, 'ROBE')),
         location_obj_t(location_ref_t('ROBE-Lock', l_office_id)),
         3196800,'ft3',110,600,9,48,'ft',null,'ft',null,null,null,null,null,null,null), 'F');
      cwms_lock.store_lock(lock_obj_t(
         location_ref_t(cwms_loc.get_location_code(l_office_id, 'WDMA')),
         location_obj_t(location_ref_t('WDMA-Lock', l_office_id)),
         1296000,'ft3',110,600,9,20,'ft',null,'ft',null,null,null,null,null,null,null), 'F');
      cwms_lock.store_lock(lock_obj_t(
         location_ref_t(cwms_loc.get_location_code(l_office_id, 'WEBB')),
         location_obj_t(location_ref_t('WEBB-Lock', l_office_id)),
         1987200,'ft3',110,600,9,30,'ft',null,'ft',null,null,null,null,null,null,null), 'F');
      commit;
      for rec in (select distinct project_id from av_lock where unit_system = 'EN') loop
         cwms_lock.cat_lock(l_crsr, rec.project_id, l_office_id);
         fetch l_crsr
          bulk collect
          into l_db_office_ids,
               l_location_ids,
               l_base_location_ids,
               l_sub_location_ids,
               l_time_zone_names,
               l_latitudes,
               l_longitudes,
               l_horizontal_datums,
               l_elevations,
               l_elev_unit_ids,
               l_vertical_datums,
               l_public_names,
               l_long_names,
               l_descriptions,
               l_active_flags;
         close l_crsr;
         ut.expect(l_db_office_ids.count).to_equal(1);
         ut.expect(l_db_office_ids(1)).to_equal(l_office_id);
         ut.expect(l_location_ids(1)).to_equal(rec.project_id);
         ut.expect(l_db_office_ids2(1)).to_equal(l_office_id);
         ut.expect(l_base_location_ids(1)).to_equal(rec.project_id);
         ut.expect(l_sub_location_ids(1)).to_equal('Lock');
         ut.expect(l_time_zone_names(1)).to_equal(l_info(rec.project_id).time_zone);
         l_location_id := rec.project_id||'-'||l_sub_location_ids(1);
         if l_info.exists(l_location_id) then
            ut.expect(round(l_latitudes(1), 6)).to_equal(round(l_info(l_location_id).latitude, 6));
            ut.expect(round(l_longitudes(1), 6)).to_equal(round(l_info(l_location_id).longitude, 6));
            ut.expect(l_horizontal_datums(1)).to_equal(l_info(l_location_id).horiz_datum);
            ut.expect(round(cwms_util.convert_units(l_elevations(1), l_elev_unit_ids(1), 'ft'), 6)).to_equal(round(l_info(l_location_id).elevation, 6));
            ut.expect(replace(l_vertical_datums(1), 'LOCAL', 'OTHER')).to_equal(l_info(l_location_id).vert_datum);
         else
            ut.expect(l_latitudes(1)).to_be_null;
            ut.expect(l_longitudes(1)).to_be_null;
            ut.expect(l_horizontal_datums(1)).to_be_null;
            ut.expect(l_elevations(1)).to_be_null;
            ut.expect(l_vertical_datums(1)).to_be_null;
         end if;
      end loop;
      -------------------------------------------------
      -- test store_location3 and retrieve_location3 --
      -------------------------------------------------
      declare
         l_geom  sdo_geometry;
         l_geom2 sdo_geometry;
         l_loc   location_obj_t;
      begin
         l_geom := sdo_geometry(
            2002,
            4326,
            null,
            sdo_elem_info_array(1, 2, 1),
            sdo_ordinate_array(
               -95.123, 34.345,
               -95.234, 34.456));
         -- store location --
         l_location_id := 'TestLoc-Geometry';
         cwms_loc.store_location3(
            p_location_id  => l_location_id,
            p_geometry     => l_geom,
            p_db_office_id => l_office_id);
         -- verify null lat/lon --
         cwms_loc.get_location_lat_lon(
            p_lat           => l_latitude,
            p_lon           => l_longitude,
            p_location_code => cwms_loc.get_location_code(l_office_id, l_location_id));
         ut.expect(l_latitude).to_be_null;
         ut.expect(l_longitude).to_be_null;
         -- verify same geometry --
         l_loc := location_obj_t(location_ref_t(l_location_id, l_office_id));
         cwms_loc.retrieve_location3(
            p_location_id        => l_location_id,
            p_elev_unit_id       => l_loc.elev_unit_id,
            p_location_type      => l_loc.location_type,
            p_elevation          => l_loc.elevation,
            p_vertical_datum     => l_loc.vertical_datum,
            p_geometry           => l_geom2,
            p_horizontal_datum   => l_loc.horizontal_datum,
            p_public_name        => l_loc.public_name,
            p_long_name          => l_loc.long_name,
            p_description        => l_loc.description,
            p_time_zone_id       => l_loc.time_zone_name,
            p_county_name        => l_loc.county_name,
            p_state_initial      => l_loc.state_initial,
            p_active             => l_loc.active_flag,
            p_location_kind_id   => l_loc.location_kind_id,
            p_map_label          => l_loc.map_label,
            p_published_latitude => l_loc.published_latitude,
            p_published_longitude=> l_loc.published_longitude,
            p_bounding_office_id => l_loc.bounding_office_id,
            p_nation_id          => l_loc.nation_id,
            p_nearest_city       => l_loc.nearest_city,
            p_alias_cursor       => l_crsr,
            p_db_office_id       => l_office_id);

         ut.expect(equivalent_geometries(l_geom, l_geom2)).to_be_true;

         -- store location w/ null geometry and verify
         cwms_loc.store_location3(
            p_location_id  => l_location_id,
            p_geometry     => null,
            p_ignorenulls  => 'F',
            p_db_office_id => l_office_id);

         cwms_loc.retrieve_location3(
            p_location_id        => l_location_id,
            p_elev_unit_id       => l_loc.elev_unit_id,
            p_location_type      => l_loc.location_type,
            p_elevation          => l_loc.elevation,
            p_vertical_datum     => l_loc.vertical_datum,
            p_geometry           => l_geom2,
            p_horizontal_datum   => l_loc.horizontal_datum,
            p_public_name        => l_loc.public_name,
            p_long_name          => l_loc.long_name,
            p_description        => l_loc.description,
            p_time_zone_id       => l_loc.time_zone_name,
            p_county_name        => l_loc.county_name,
            p_state_initial      => l_loc.state_initial,
            p_active             => l_loc.active_flag,
            p_location_kind_id   => l_loc.location_kind_id,
            p_map_label          => l_loc.map_label,
            p_published_latitude => l_loc.published_latitude,
            p_published_longitude=> l_loc.published_longitude,
            p_bounding_office_id => l_loc.bounding_office_id,
            p_nation_id          => l_loc.nation_id,
            p_nearest_city       => l_loc.nearest_city,
            p_alias_cursor       => l_crsr,
            p_db_office_id       => l_office_id);

         ut.expect(l_geom2 is null).to_be_true;

         cwms_loc.delete_location(l_location_id, cwms_util.delete_all, l_office_id);
      end;

      ------------------------------------------
      -- delete locations stored in this test --
      ------------------------------------------
      for i in 1..l_data_tab.count loop
         exit when l_data_tab(i).count < 13;
         l_location_id := l_data_tab(i)(2);
         begin
            cwms_loc.delete_location(l_location_id, cwms_util.delete_all, l_office_id);
         exception
            when exc_location_id_not_found then null;
         end;
      end loop;
      commit;
   end test_mods_for_generic_geometry;
END test_cwms_loc;
/
show errors;
set escape off
