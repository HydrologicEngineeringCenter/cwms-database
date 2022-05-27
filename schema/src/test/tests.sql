set serveroutput on;
set define on;

define office_id = '&1';
define cwms_schema = '&2';
define upass_id = '&3';
-- make sure the info required for the below user is present
exec cwms_sec.add_cwms_user('OTHER_DIST', char_32_array_type('CWMS Users'),'HQ');
@test_cwms_prop.sql;
@test_cwms_msg.sql;
@test_aaa.sql;
@test_ro.sql;
@test_up.sql;
@test_dba.sql;
@test_lrts_updates.sql;
@test_update_ts_extents.sql;
@test_probability_parameter.sql;
@test_cwms_util.sql;
@test_cwms_loc.sql;
@test_cwms_ts.sql;
@test_cwms_rating.sql;
@test_cwms_pool.sql;
@test_clean_all.sql;
@test_versioned_time_series.sql;
@test_timeseries_snapping.sql;
@test_cwms_cat.sql;
@test_cwms_level.sql;
@test_cwms_display.sql;

show errors;
