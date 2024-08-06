set serveroutput on;
set define on;

define office_id = '&1';
define cwms_schema = '&2';
define upass_id = '&3';
define eroc = '&4';
define multiuser2 = '&eroc.hectest_multiuser2';
-- make sure the info required for the below users are present
begin
    cwms_sec.add_cwms_user('OTHER_DIST', char_32_array_type('CWMS Users'),'HQ');
    cwms_20.cwms_sec.add_cwms_user ('&&multiuser2',
                                        CHAR_32_ARRAY_TYPE ('CWMS Users','TS ID Creator', 'Viewer Users'),
                                        '&&office_id');
    cwms_20.cwms_sec.add_user_to_group('&&multiuser2','CWMS Users','POA');
end;
/

@test_cwms_stream;
@test_cwms_prop.sql;
@test_cwms_msg.sql;
@test_aaa.sql;
show errors;
@test_aaa_normaluserfails.sql
show errors;
@test_ro.sql;
@test_up.sql;
@test_dba.sql;
@test_lrts_updates.sql;
@test_update_ts_extents.sql;
@test_probability_parameter.sql;
@test_cwms_util.sql;
@test_cwms_err.sql;
@test_cwms_loc.sql;
@test_cwms_project.sql;
@test_cwms_ts.sql;
@test_cwms_rating.sql;
@test_cwms_pool.sql;
@test_clean_all.sql;
@test_versioned_time_series.sql;
@test_timeseries_snapping.sql;
@test_cwms_cat.sql;
@test_cwms_level.sql;
@test_cwms_display.sql;
@test_cwms_data_dissem.sql;
@test_cwms_forecast.sql;
@test_cwms_xchg.sql;
@test_cwms_cache.sql;
@test_aq_user.sql;
@test_webuser_abilities.sql;
@test_cwms_ts_profile.sql
@test_cwms_outlet.sql
show errors;
@test_multiple_office_perms.sql;
show errors;
