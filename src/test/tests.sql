

exec cwms_sec.create_user('pd_user','pd_pw', char_32_array_type('CWMS Users', 'CWMS PD Users','CWMS User Admins'), 'SPK'); 

@test_aaa.sql;

GRANT EXECUTE ON test_aaa to pd_user;

show errors;
