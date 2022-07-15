-- this runs as SYS, add any grants need for a test to run here. the EXECUTE and CREATE any are required
-- for code coverage.
set define on
define cwms_schema = &6
GRANT EXECUTE ON &&cwms_schema..test_lrts_updates to &1;
grant execute on &&cwms_schema..test_probability_parameter to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_util to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_loc to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_ts to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_rating to &1;
GRANT EXECUTE ON &&cwms_schema..test_clean_all to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_prop to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_msg to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_pool to &1;
GRANT EXECUTE ON &&cwms_schema..test_versioned_time_series to &1;
GRANT EXECUTE ON &&cwms_schema..test_update_ts_extents to &1;
GRANT EXECUTE ON &&cwms_schema..test_timeseries_snapping to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_cat to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_level to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_display to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_stream to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_data_dissem to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_forecast to &1;
GRANT EXECUTE ON &&cwms_schema..test_update_ts_extents to &1;
GRANT EXECUTE ON &&cwms_schema..test_timeseries_snapping to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_cat to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_level to &1;
GRANT EXECUTE ON &&cwms_schema..test_cwms_display to &1;
--GRANT EXECUTE any procedure to &1;
--GRANT CREATE any procedure to &1;

GRANT EXECUTE ON &&cwms_schema..test_ro to &2;
--GRANT EXECUTE any procedure to ro_user;
--GRANT CREATE any procedure to ro_user;

GRANT EXECUTE ON &&cwms_schema..test_dba to &3;
GRANT EXECUTE ON &&cwms_schema..test_aaa to &4;
--GRANT EXECUTE any procedure to &1;
--GRANT CREATE any procedure to &1;
GRANT EXECUTE ON &&cwms_schema..test_up to &5;

exec cwms_sec.update_edipi('&7',1234567890);
GRANT EXECUTE ON &&cwms_schema..test_aq_user to &7;
GRANT EXECUTE ON &&cwms_schema..test_aaa_normaluserfails to &7;
GRANT EXECUTE ON &&cwms_schema..test_webuser_abilities to &8;
GRANT EXECUTE ON &&cwms_schema..test_multiple_office_perms to &9;
GRANT EXECUTE ON &&cwms_schema..test_multiple_office_perms to cwms_user;
GRANT EXECUTE ON &&cwms_schema..test_up to &5;
