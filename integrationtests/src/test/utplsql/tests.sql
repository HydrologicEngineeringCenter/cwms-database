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
show errors;
@test_cwms_measurements.sql;
show errors;
@test_cwms_lock.sql;
show errors;
@test_cwms_prop.sql;
show errors;
prompt CWMS MSG
@test_cwms_msg.sql;
show errors;
prompt CWMS AAA
@test_aaa.sql;
show errors;
show errors;
@test_aaa_normaluserfails.sql
show errors;
@test_ro.sql;
show errors;
prompt Upass tests
@test_up.sql;
show errors;
prompt dba tests
@test_dba.sql;
show errors;
prompt lrts updates
@test_lrts_updates.sql;
show errors;
prompt ts extends
@test_update_ts_extents.sql;
show errors;
prompt probabilty parameter
@test_probability_parameter.sql;
show errors;
prompt cwms_util
@test_cwms_util.sql;
show errors;
prompt cwms_err
@test_cwms_err.sql;
show errors;
prompt cwms_loc
@test_cwms_loc.sql;
show errors;
@test_cwms_loc_normal_user.sql;
show errors;
prompt cwms_ts
@test_cwms_ts.sql;
show errors;
prompt cwms_rating
@test_cwms_rating.sql;
show errors;
prompt cwms_pool
@test_cwms_pool.sql;
show errors;
prompt versioned time series
@test_versioned_time_series.sql;
show errors;
prompt timeseries snapping
@test_timeseries_snapping.sql;
show errors;
prompt catalog
@test_cwms_cat.sql;
show errors;
prompt levels
@test_cwms_level.sql;
show errors;
prompt display
@test_cwms_display.sql;
show errors;
@test_cwms_data_dissem.sql;
show errors;
@test_cwms_forecast.sql;
show errors;
@test_cwms_xchg.sql;
show errors;
@test_cwms_cache.sql;
show errors;
@test_aq_user.sql;
show errors;
@test_webuser_abilities.sql;
show errors;
@test_cwms_ts_profile.sql
show errors;
@test_cwms_outlet.sql
show errors;
@../views/test_av_ts_grp_assgn.sql;
show errors;
@../views/test_av_loc_grp_assgn.sql;
show errors;
@test_cwms_project.sql
show errors;
@test_multiple_office_perms.sql;
show errors;
@test_cwms_fcst.sql;
show errors;
prompt clean_all
@test_clean_all.sql;
show errors;
