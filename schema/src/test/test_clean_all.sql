CREATE OR REPLACE package &cwms_schema..test_clean_all as

--%suite(dummy test to clean up all data)
--%afterall(teardown_all)
--%rollback(manual)

--%test(Test Dummy)
procedure test_dummy;

procedure teardown_all;
end test_clean_all;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_clean_all
AS



    PROCEDURE test_dummy
    IS
    BEGIN
      ut.expect (0).to_equal(0);
    END;

    PROCEDURE teardown_all
    IS
    BEGIN
        test_cwms_msg.teardown; 
        test_cwms_prop.teardown; 
        test_cwms_loc.teardown;
        test_cwms_project.teardown;
        test_cwms_rating.teardown; 
        test_cwms_ts.teardown; 
        test_cwms_util.teardown;
        test_cwms_err.teardown;
        test_lrts_updates.teardown; 
        test_ro.teardown;
        test_dba.teardown;
        test_cwms_pool.teardown;
        test_update_ts_extents.teardown;
        test_timeseries_snapping.teardown;
        test_cwms_cat.teardown;
        test_cwms_stream.teardown;
        test_cwms_lock.teardown;
        test_cwms_data_dissem.teardown;
        test_cwms_fcst.teardown;
        test_cwms_forecast.teardown;
        test_cwms_xchg.teardown;
        test_cwms_cache.teardown;
    END teardown_all;

END test_clean_all;
/

SHOW ERRORS;
