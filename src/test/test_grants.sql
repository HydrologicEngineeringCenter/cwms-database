-- this runs as SYS, add any grants need for a test to run here. the EXECUTE and CREATE any are required
-- for code coverage.

GRANT EXECUTE ON cwms_20.test_aaa to pd_user;
GRANT EXECUTE any procedure to pd_user;
GRANT CREATE any procedure to pd_user;