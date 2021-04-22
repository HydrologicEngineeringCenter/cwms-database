CREATE OR REPLACE package CWMS_20.test_cwms_ts as

--%suite(Test cwms_ts package code)
--%afterall(teardown_all)
--%rollback(manual)

--%test(Test setting active flag)
procedure test_set_active_flag;


procedure setup_rename;
procedure teardown_all;
end test_cwms_ts;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY CWMS_20.test_cwms_ts
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
                  FROM TABLE (str_tab_t ('TestLoc1')))
        LOOP
            BEGIN
                cwms_loc.delete_location (
                    p_location_id     => rec.loc_name,
                    p_delete_action   => cwms_util.delete_all,
                    p_db_office_id    => 'NAB');
            EXCEPTION
                WHEN exc_location_id_not_found
                THEN
                    NULL;
            END;
        END LOOP;
    END setup_rename;

    PROCEDURE teardown_all
    IS
    BEGIN
        setup_rename;
    END teardown_all;

    --------------------------------------------------------------------------------
    -- procedure store_location_with_multiple_attributes
    --------------------------------------------------------------------------------

    PROCEDURE test_set_active_flag
    IS
        l_base_location_id   av_loc.base_location_id%TYPE;
        l_cwms_ts_id         AV_CWMS_TS_ID.CWMS_TS_ID%TYPE;
        l_base_loc_active    AV_CWMS_TS_ID.BAS_LOC_ACTIVE_FLAG%TYPE;
        l_loc_active         AV_CWMS_TS_ID.LOC_ACTIVE_FLAG%TYPE;
        l_ts_active          AV_CWMS_TS_ID.TS_ACTIVE_FLAG%TYPE;
        l_net_ts_active      AV_CWMS_TS_ID.NET_TS_ACTIVE_FLAG%TYPE;
    BEGIN
        l_base_location_id := 'TestLoc1';
        l_cwms_ts_id := l_base_location_id || '.Stage.Inst.0.0.raw';
        cwms_loc.store_location (p_location_id    => l_base_location_id,
                                 p_active         => 'F',
                                 p_db_office_id   => 'NAB');
        COMMIT;
        cwms_ts.create_ts ('NAB', l_cwms_ts_id);
        COMMIT;

          SELECT bas_loc_active_flag,
                 loc_active_flag,
                 ts_active_flag,
                 net_ts_active_flag
            INTO l_base_loc_active,
                 l_loc_active,
                 l_ts_active,
                 l_net_ts_active
            FROM av_cwms_ts_id
           WHERE cwms_ts_id = l_cwms_ts_id
        ORDER BY 1;

        COMMIT;
        ut.expect (l_base_loc_active).to_equal ('F');
        ut.expect (l_loc_active).to_equal ('F');
        ut.expect (l_ts_active).to_equal ('T');
        ut.expect (l_net_ts_active).to_equal ('F');
        cwms_loc.store_location (p_location_id    => l_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => 'NAB');
        COMMIT;


          SELECT bas_loc_active_flag,
                 loc_active_flag,
                 ts_active_flag,
                 net_ts_active_flag
            INTO l_base_loc_active,
                 l_loc_active,
                 l_ts_active,
                 l_net_ts_active
            FROM av_cwms_ts_id
           WHERE cwms_ts_id = l_cwms_ts_id
        ORDER BY 1;

        COMMIT;
        ut.expect (l_base_loc_active).to_equal ('T');
        ut.expect (l_loc_active).to_equal ('T');
        ut.expect (l_ts_active).to_equal ('T');
        ut.expect (l_net_ts_active).to_equal ('T');
        CWMS_TS.UPDATE_TS_ID (p_cwms_ts_id       => l_cwms_ts_id,
                              p_ts_active_flag   => 'F',
                              p_db_office_id     => 'NAB');
        COMMIT;

          SELECT bas_loc_active_flag,
                 loc_active_flag,
                 ts_active_flag,
                 net_ts_active_flag
            INTO l_base_loc_active,
                 l_loc_active,
                 l_ts_active,
                 l_net_ts_active
            FROM av_cwms_ts_id
           WHERE cwms_ts_id = l_cwms_ts_id
        ORDER BY 1;


        ut.expect (l_base_loc_active).to_equal ('T');
        ut.expect (l_loc_active).to_equal ('T');
        ut.expect (l_ts_active).to_equal ('F');
        ut.expect (l_net_ts_active).to_equal ('F');
    END;
END test_cwms_ts;
/

SHOW ERRORS;
