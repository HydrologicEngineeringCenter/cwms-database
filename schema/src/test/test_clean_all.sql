CREATE OR REPLACE package &cwms_schema..test_clean_all as

--%suite(dummy test to clean up all data)
--%afterall(cleanup_all)
--%rollback(manual)

--%test(Test Dummy)
procedure test_dummy;

procedure teardown_all;
procedure delete_test_clobs;
procedure cleanup_all;
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
        begin test_cwms_msg.teardown;  exception when others then null; end;
        begin test_cwms_prop.teardown;  exception when others then null; end;
        begin test_cwms_loc.teardown; exception when others then null; end;
        begin test_cwms_project.teardown; exception when others then null; end;
        begin test_cwms_rating.teardown;  exception when others then null; end;
        begin test_cwms_ts.teardown;  exception when others then null; end;
        begin test_cwms_util.teardown; exception when others then null; end;
        begin test_cwms_err.teardown; exception when others then null; end;
        begin test_lrts_updates.teardown;  exception when others then null; end;
        begin test_ro.teardown; exception when others then null; end;
        begin test_dba.teardown; exception when others then null; end;
        begin test_cwms_pool.teardown; exception when others then null; end;
        begin test_update_ts_extents.teardown; exception when others then null; end;
        begin test_timeseries_snapping.teardown; exception when others then null; end;
        begin test_cwms_cat.teardown; exception when others then null; end;
        begin test_cwms_stream.teardown; exception when others then null; end;
        begin test_cwms_lock.teardown; exception when others then null; end;
        begin test_cwms_data_dissem.teardown; exception when others then null; end;
        begin test_cwms_fcst.teardown; exception when others then null; end;
        begin test_cwms_forecast.teardown; exception when others then null; end;
        begin test_cwms_xchg.teardown; exception when others then null; end;
        begin test_cwms_cache.teardown; exception when others then null; end;      
        begin test_cwms_text.teardown; exception when others then null; end;   
    END teardown_all;

    PROCEDURE delete_test_clobs
    IS
    BEGIN
        delete from at_clob where id='/TEST_CWMS_RATING/TRANSITIONAL_RATING';
        delete from at_clob where id='/TEST/CWMS-2430';
    END delete_test_clobs;

    PROCEDURE cleanup_all
    IS
    BEGIN
        delete_test_clobs;
        teardown_all;
    END cleanup_all;

END test_clean_all;
/

SHOW ERRORS;
