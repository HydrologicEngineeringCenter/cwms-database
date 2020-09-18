create or replace package test_aaa as
    -- %suite(CWMS Authentication and Authorization functions )

    -- %test(Simple login of CAC user works)
    procedure simple_login_works;

    -- %test(Login with no EDIPI fails)
    procedure login_without_edipi_fails;

    -- %test(Duplicate EDIPI provides useful message)
    -- %throws(-20255)
    procedure duplicate_edipi_provides_useful_message;

    procedure setup_users;
end;
/


create or replace package body test_aaa as

    procedure setup_users is
    begin
        cwms_sec.create_user('basic_user','bu_pw', char_32_array_type('CWMS Users'), '&office_id');
        cwms_sec.update_edipi('basic_user',1000000000);

        cwms_sec.create_user('user_admin','us_pw', char_32_array_type('CWMS Users', 'CWMS User Admins'), '&office_id');
        cwms_sec.update_edipi('user_admin',2000000000);

        cwms_sec.create_user('No_EDIPI', 'noe_pw', char_32_array_type('CWMS Users'),'&office_id');
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

    procedure login_without_edipi_fails is
        username varchar2(400);
        session_key varchar2(400);
    begin
        setup_users;

        cwms_sec.get_user_credentials(1000000001,username,session_key);

        ut.expect( username ).to_be_null();
        ut.expect( session_key ).to_be_null();
    end;

    procedure duplicate_edipi_provides_useful_message is
        username varchar2(400);
        session_key varchar2(400);
    begin
        setup_users;
        cwms_sec.create_user('basic_user2','bu_pw', char_32_array_type('CWMS Users'), '&office_id');
        cwms_sec.update_edipi('basic_user2',1000000000);

        cwms_sec.get_user_credentials(1000000000,username,session_key);
    end;

end;
/

