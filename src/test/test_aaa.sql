create or replace package test_aaa as
    -- %suite(CWMS Authentication and Authorization functions )

    -- %test(Simple login of CAC user works)
    procedure simple_login_works;


    procedure setup_users;
end;
/


create or replace package body test_aaa as

    procedure setup_users is
    begin
        cwms_sec.create_user('basic_user','bu_pw', char_32_array_type('CWMS Users'), 'SPK');
        cwms_sec.update_edipi('basic_user',1000000000);

        cwms_sec.create_user('user_admin','us_pw', char_32_array_type('CWMS Users', 'CWMS User Admins'), 'SPK');
        cwms_sec.update_edipi('user_admin',2000000000);
    end;



    procedure simple_login_works is    
        username varchar2(400);
        session_key varchar2(400);
    begin
        setup_users;

        cwms_sec.get_user_credentials(1000000000,username,session_key);

        ut.expect( username ).to_equal('BASIC_USER');
        ut.expect( session_key ).to_be_not_null();
    end;
end;
/

