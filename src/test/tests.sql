set serveroutput on;
set define on;

define office_id = '&1';
exec cwms_sec.create_user('pd_user','pd_pw', char_32_array_type('CWMS Users', 'CWMS PD Users','CWMS User Admins'), '&office_id'); 
exec cwms_sec.create_user('ro_user','ro_pw', char_32_array_type('CWMS Users', 'Viewer Users'), '&office_id'); 
-- make sure the info required for the below user is present
exec cwms_sec.create_cwmsdbi_db_user('hqcwmsdbi','junk','HQ');
exec cwms_sec.create_user('OTHER_DIST','other', char_32_array_type('CWMS Users'),'HQ');
@test_aaa.sql;
@test_ro.sql;
@test_lrts_updates.sql;

show errors;
