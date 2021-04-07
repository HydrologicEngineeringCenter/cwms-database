-- this runs as SYS, add any grants need for a test to run here. the EXECUTE and CREATE any are required
-- for code coverage.

GRANT EXECUTE ON cwms_20.test_aaa to pd_user;
GRANT EXECUTE ON cwms_20.test_missing_shift_points to pd_user;
GRANT EXECUTE ON cwms_20.test_lrts_updates to pd_user;
grant execute on cwms_20.test_probability_parameter to pd_user;
GRANT EXECUTE ON cwms_20.test_cwms_util to pd_user;
GRANT EXECUTE ON cwms_20.test_cwms_loc to pd_user;
GRANT EXECUTE ON cwms_20.test_cwms_rating to pd_user;
GRANT EXECUTE any procedure to pd_user;
GRANT CREATE any procedure to pd_user;

GRANT EXECUTE ON cwms_20.test_aaa to ro_user;
GRANT EXECUTE any procedure to ro_user;
GRANT CREATE any procedure to ro_user;
