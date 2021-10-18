CREATE OR REPLACE package &cwms_schema..test_cwms_loc as

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
--%throws(-20998)
procedure test_set_vertical_datum_info_exp;
--%test(Test new av_loc view with old view)
procedure test_av_loc_view;

procedure setup_rename;
procedure setup;
procedure teardown;
end test_cwms_loc;
/

CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_loc
AS
    --------------------------------------------------------------------------------
    -- procedure setup_rename
    --------------------------------------------------------------------------------
    PROCEDURE setup_rename
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
                    p_db_office_id    => '&office_id');
            EXCEPTION
                WHEN exc_location_id_not_found
                THEN
                    NULL;
            END;
        END LOOP;
    END setup_rename;

    PROCEDURE cleanup_locs
    IS
    BEGIN
        EXECUTE IMMEDIATE 'alter trigger at_physical_location_t03 disable';
        COMMIT;

        EXECUTE IMMEDIATE 'delete from at_cwms_ts_spec';
        COMMIT;

        EXECUTE IMMEDIATE 'delete from at_physical_location where location_code<>0';
        COMMIT;

        EXECUTE IMMEDIATE 'delete from at_base_location where base_location_code<>0';
        COMMIT;

        EXECUTE IMMEDIATE 'delete from at_parameter where db_office_code<>53';
        COMMIT;

        BEGIN
        	EXECUTE IMMEDIATE 'drop view av_loc_old';
        
        	EXECUTE IMMEDIATE 'drop materialized view mv_loc';
        
        	EXECUTE IMMEDIATE 'drop materialized view mv_loc_old';

        EXCEPTION WHEN OTHERS
        THEN 
	   NULL;
        END;
       	EXECUTE IMMEDIATE 'alter trigger at_physical_location_t03 enable';

    END;

    PROCEDURE setup
    IS
    BEGIN
      EXECUTE IMMEDIATE 'drop view av_loc_old';
        
      EXECUTE IMMEDIATE 'drop materialized view mv_loc';
        
      EXECUTE IMMEDIATE 'drop materialized view mv_loc_old';

    EXCEPTION WHEN OTHERS
    THEN 
	   NULL;
    END setup;

    PROCEDURE teardown
    IS
    BEGIN
        setup_rename;
        cleanup_locs;
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
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&office_id';
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
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&office_id';
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
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&office_id';
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
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&office_id';
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
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&office_id';
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
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := '&office_id';
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
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := 'NAB';
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
        
        l_xml := '<vertical-datum-info office="'||l_office_id||'" unit="in"><location>'||l_location_id1||'</location><native-datum>NGVD-29</native-datum><elevation>19200</elevation><offset estimate="true"><to-datum>NAVD-88</to-datum><value>-5.846</value></offset></vertical-datum-info>';
        
        cwms_loc.set_vertical_datum_info (
        l_xml, 
        'T');
        
        SELECT elevation
          INTO l_elevation
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (abs(l_elevation-1600)).to_be_less_or_equal (0.00000001);
        
        l_xml := '<vertical-datum-info office="'||l_office_id||'" unit="in"><location>'||l_location_id1||'</location><native-datum>NGVD-29</native-datum><elevation>19200.0000000001</elevation><offset estimate="true"><to-datum>NAVD-88</to-datum><value>-5.846</value></offset></vertical-datum-info>';

        cwms_loc.set_vertical_datum_info (
        l_xml,
        'T');
        
        SELECT elevation
          INTO l_elevation
          FROM av_loc
         WHERE     db_office_id = l_office_id
               AND location_id = l_location_id1
               AND unit_system = 'EN';

        ut.expect (abs(l_elevation-1600)).to_be_less_or_equal (0.00000001);
        
    END test_set_vertical_datum_info;
    PROCEDURE test_set_vertical_datum_info_exp
    IS
        l_office_id            av_loc.db_office_id%TYPE;
        l_location_id1          av_loc.location_id%TYPE;
        l_vertical_datum       AV_LOC.VERTICAL_DATUM%TYPE;
        l_elevation      AV_LOC.ELEVATION%TYPE;
        l_xml            varchar2(2048);
    BEGIN
        --------------------------------
        -- cleanup any previous tests --
        --------------------------------
        setup_rename;
        ----------------------------------------------------
        -- create the location and get the location codes --
        ----------------------------------------------------
        l_office_id := 'NAB';
        l_location_id1 := 'TestLoc1';
        

        cwms_loc.store_location (p_location_id    => l_location_id1,
                                 p_db_office_id   => l_office_id,
                                 p_vertical_datum   => 'NGVD29');

        l_xml := '<vertical-datum-info office="'||l_office_id||'" unit="in"><location>'||l_location_id1||'</location><native-datum>NGVD-29</native-datum><elevation>19200</elevation><offset estimate="true"><to-datum>NAVD-88</to-datum><value>-5.846</value></offset></vertical-datum-info>';
        
        cwms_loc.set_vertical_datum_info (
        l_xml, 
        'T');
        
        
        l_xml := '<vertical-datum-info office="'||l_office_id||'" unit="in"><location>'||l_location_id1||'</location><native-datum>NGVD-29</native-datum><elevation>19200.0001</elevation><offset estimate="true"><to-datum>NAVD-88</to-datum><value>-5.846</value></offset></vertical-datum-info>';

        cwms_loc.set_vertical_datum_info (
        l_xml,
        'T');
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

    --%test(Test new av_loc view with old view)
    PROCEDURE test_av_loc_view
    IS
        l_count   NUMBER;
        l_cmd     VARCHAR2 (32000);
    BEGIN
      -- check for data first
        select count(*) into l_count from av_loc;

        ut.expect (l_count).to_be_greater_than(10000);
        -- Fix base location issues
        EXECUTE IMMEDIATE 'update at_physical_location set location_code=base_location_code where base_location_code<>location_code and sub_location_id is null';

        EXECUTE IMMEDIATE 'insert into at_physical_location(location_code,base_location_code,active_flag,location_kind) select base_location_code,base_location_code,''T'',1 from at_physical_location where base_location_code<>location_code and base_location_code not in (select location_code from at_physical_location)';

        COMMIT;
        l_cmd :=
            'CREATE OR REPLACE VIEW     AV_LOC_OLD (LOCATION_CODE,
                                        BASE_LOCATION_CODE,
                                        DB_OFFICE_ID,
                                        BASE_LOCATION_ID,
                                        SUB_LOCATION_ID,
                                        LOCATION_ID,
                                        LOCATION_TYPE,
                                        UNIT_SYSTEM,
                                        ELEVATION,
                                        UNIT_ID,
                                        VERTICAL_DATUM,
                                        LONGITUDE,
                                        LATITUDE,
                                        HORIZONTAL_DATUM,
                                        TIME_ZONE_NAME,
                                        COUNTY_NAME,
                                        STATE_INITIAL,
                                        PUBLIC_NAME,
                                        LONG_NAME,
                                        DESCRIPTION,
                                        BASE_LOC_ACTIVE_FLAG,
                                        LOC_ACTIVE_FLAG,
                                        LOCATION_KIND_ID,
                                        MAP_LABEL,
                                        PUBLISHED_LATITUDE,
                                        PUBLISHED_LONGITUDE,
                                        BOUNDING_OFFICE_ID,
                                        NATION_ID,
                                        NEAREST_CITY,
                                        ACTIVE_FLAG) BEQUEATH DEFINER
 AS
    SELECT       location_code             ,
           base_location_code                  ,
           db_office_id            ,
           base_location_id                ,
           sub_location_id               ,
           location_id           ,
           location_type             ,
           unit_system           ,
           cwms_util         . convert_units              ( elevation         ,
                                    cwms_util         . get_default_units                  ( ''Elev''      ) ,
                                    cwms_display            . retrieve_user_unit_f                     (
                                        ''Elev''      ,
                                        unit_system           ,
                                        NULL    ,
                                        db_office_id            ) )
               AS   elevation         ,
           cwms_display            . retrieve_user_unit_f                     ( ''Elev''      ,
                                              unit_system           ,
                                              NULL    ,
                                              db_office_id            )
               unit_id       ,
           vertical_datum              ,
           ROUND      ( longitude         ,  12  )
               AS   longitude         ,
           ROUND      ( latitude        ,  12  )
               AS   latitude        ,
           horizontal_datum                ,
           time_zone_name              ,
           county_name           ,
           state_initial             ,
           public_name           ,
           long_name         ,
           description           ,
           base_loc_active_flag                    ,
           loc_active_flag               ,
           location_kind_id                ,
           map_label         ,
           ROUND      ( published_latitude                  ,  12  )
               AS   published_latitude                  ,
           ROUND      ( published_longitude                   ,  12  )
               AS   published_longitude                   ,
           bounding_office_id                  ,
           nation_id         ,
           nearest_city            ,
           loc_active_flag
      FROM     ( SELECT       o . office_code
                       db_office_code              ,
                   p1  . location_code             ,
                   base_location_code                  ,
                   o . office_id
                       db_office_id            ,
                   base_location_id                ,
                   p1  . sub_location_id               ,
                      base_location_id
                   ||   SUBSTR       ( ''-''   ,  1 ,  LENGTH       ( p1  . sub_location_id               ) )
                   ||   p1  . sub_location_id
                       AS   location_id           ,
                   p1  . location_type             ,
                   NVL    ( p1  . elevation         ,  p2  . elevation         )
                       AS   elevation         ,
                   NVL    ( p1  . vertical_datum              ,  p2  . vertical_datum              )
                       AS   vertical_datum              ,
                   NVL    ( p1  . longitude         ,  p2  . longitude         )
                       AS   longitude         ,
                   NVL    ( p1  . latitude        ,  p2  . latitude        )
                       AS   latitude        ,
                   NVL    ( p1  . horizontal_datum                ,  p2  . horizontal_datum                )
                       AS   horizontal_datum                ,
                   time_zone_name              ,
                   county_name           ,
                   state_initial             ,
                   p1  . public_name           ,
                   p1  . long_name         ,
                   p1  . description           ,
                   b . active_flag
                       base_loc_active_flag                    ,
                   p1  . active_flag
                       loc_active_flag               ,
                   location_kind_id                ,
                   NVL    ( p1  . map_label         ,  p2  . map_label         )
                       AS   map_label         ,
                   NVL    ( p1  . published_latitude                  ,  p2  . published_latitude                  )
                       AS   published_latitude                  ,
                   NVL    ( p1  . published_longitude                   ,  p2  . published_longitude                   )
                       AS   published_longitude                   ,
                   NVL    ( o1  . office_id         ,  o2  . office_id         )
                       AS   bounding_office_id                  ,
                   nation_id         ,
                   NVL    ( p1  . nearest_city            ,  p2  . nearest_city            )
                       AS   nearest_city
              FROM     ( ( ( ( ( ( ( at_physical_location                      p1
                          LEFT     OUTER      JOIN
                          cwms_office                      o1
                          USING      ( office_code           ) )
                         JOIN
                         ( at_physical_location                      p2
                          LEFT     OUTER      JOIN
                          cwms_office                      o2
                          USING      ( office_code           ) )
                         USING      ( base_location_code                  )
                         JOIN
                         at_base_location                       b
                         USING      ( base_location_code                  ) )
                        JOIN
                        cwms_office                        o
                        ON   b . db_office_code               =  o . office_code           )
                       LEFT     OUTER      JOIN
                       cwms_location_kind
                       ON   location_kind_code                   =  p1  . location_kind             )
                      LEFT     OUTER      JOIN
                      cwms_time_zone                          t
                      ON   t . time_zone_code               =
                         COALESCE         ( p1  . time_zone_code              ,  p2  . time_zone_code              ) )
                     LEFT     OUTER      JOIN
                     cwms_county                           c
                     ON   c . county_code            =
                        COALESCE         ( p1  . county_code           ,  p2  . county_code           ) )
                    LEFT     OUTER      JOIN
                    cwms_state
                    USING      ( state_code          ) )
                   LEFT     OUTER      JOIN     cwms_nation            n
                       ON   n . nation_code            =
                          COALESCE         ( p1  . nation_code           ,  p2  . nation_code           )
             WHERE      p1  . location_code              !=   0  AND    p2  . sub_location_id                IS   NULL    )  aa
           JOIN     ( SELECT       office_id         ,  ''EN''     AS   unit_system            FROM     cwms_office
                 UNION      ALL
                 SELECT       office_id         ,  ''SI''     AS   unit_system            FROM     cwms_office           )  bb
               ON   aa  . db_office_id             =  bb  . office_id';


        EXECUTE IMMEDIATE l_cmd;

        EXECUTE IMMEDIATE 'create materialized view mv_loc refresh on demand using trusted constraints as select * from av_loc';

        EXECUTE IMMEDIATE 'create materialized view mv_loc_old refresh on demand using trusted constraints as select * from av_loc_old';

        EXECUTE IMMEDIATE 'create index mv_loc_idx on mv_loc(location_code)';

        EXECUTE IMMEDIATE 'create index mv_loc_old_idx on mv_loc_old(location_code)';

        execute immediate 'SELECT COUNT (*)
          FROM (SELECT * FROM mv_loc
                MINUS
                SELECT * FROM mv_loc_old)' into l_count;

        ut.expect (l_count).to_equal (0);

        execute immediate 'SELECT COUNT (*)
          FROM (SELECT * FROM mv_loc_old
                MINUS
                SELECT * FROM mv_loc)' into l_count;

        ut.expect (l_count).to_equal (0);
    END test_av_loc_view;
END test_cwms_loc;
/
