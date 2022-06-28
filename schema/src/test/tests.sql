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
prompt CWMS MSG
@test_cwms_msg.sql;
prompt CWMS AAA
@test_aaa.sql;
show errors;
@test_aaa_normaluserfails.sql
show errors;
@test_ro.sql;
prompt Upass tests
@test_up.sql;
prompt dba tests
@test_dba.sql;
prompt lrts updates
@test_lrts_updates.sql;
prompt ts extends
@test_update_ts_extents.sql;
prompt probabilty parameter
@test_probability_parameter.sql;
prompt cwms_util
@test_cwms_util.sql;
prompt cwms loc
@test_cwms_loc.sql;
prompt cwms_ts
@test_cwms_ts.sql;
prompt cwms_rating
@test_cwms_rating.sql;
prompt cwms_pool
@test_cwms_pool.sql;
prompt versioned time series
@test_versioned_time_series.sql;
prompt timeseries snapping
@test_timeseries_snapping.sql;
prompt catalog
@test_cwms_cat.sql;
prompt levels
@test_cwms_level.sql;
prompt display
@test_cwms_display.sql;
@test_cwms_data_dissem.sql;
@test_cwms_forecast.sql;
@test_aq_user.sql;
@test_webuser_abilities.sql;
show errors;
@test_multiple_office_perms.sql;
show errors;
prompt clean_all
@test_clean_all.sql;
show errors;
