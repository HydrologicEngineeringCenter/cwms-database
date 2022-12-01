create or replace package test_aaa AUTHID CURRENT_USER as
    -- %suite(CWMS Authentication and Authorization functions )
    --%rollback(manual)

    -- %test(Simple login of CAC user works)
    procedure simple_login_works;

    -- %test(Login with no EDIPI fails)
    procedure login_without_edipi_fails;

    -- %test(Duplicate EDIPI provides useful message)
    -- %throws(-20255)
    -- %aftertest(test_aaa.remove_duplicate_user)
    procedure duplicate_edipi_provides_useful_message;

    -- %test(Can retrieve all users)
    procedure can_retrieve_all_users;

    -- %test(Can retrieve all users using View)
    procedure can_retrieve_all_users_with_view;    

    -- %test(Get User State)
    procedure can_get_user_state;

    -- %beforeall
    procedure setup_users;

    -- %test(Can cycle from PD user to non PD user and back)
    procedure can_cycle_pd_non_pd_and_back;
    
    procedure remove_duplicate_user;
end;
/


create or replace package body test_aaa as

    procedure setup_users is
    begin
        cwms_env.set_session_office_id('&office_id');
        cwms_sec.add_cwms_user('basic_user', char_32_array_type('CWMS Users'), '&office_id');
        cwms_sec.update_edipi('basic_user',1000000000);

        cwms_sec.add_cwms_user('user_admin', char_32_array_type('CWMS Users', 'CWMS User Admins'), '&office_id');
        cwms_sec.update_edipi('user_admin',2000000000);

        cwms_sec.add_cwms_user('No_EDIPI',  char_32_array_type('CWMS Users'),'&office_id');
        
    end;

   
    procedure remove_duplicate_user is
    begin  
        -- At present only the schema user can delete user accounts, so we'll just tweek the EDIPI install
        cwms_sec.update_edipi('basic_user2',1000100001);
    end;

    procedure simple_login_works is    
        username varchar2(400);
        session_key varchar2(400);
    begin        

        cwms_sec.get_user_credentials(1000000000,username,session_key);

        ut.expect( username ).to_equal('BASIC_USER');
        ut.expect( session_key ).to_be_not_null();
    end;

    procedure login_without_edipi_fails is
        username varchar2(400);
        session_key varchar2(400);
    begin        

        cwms_sec.get_user_credentials(1000000001,username,session_key);

        ut.expect( username ).to_be_null();
        ut.expect( session_key ).to_be_null();
    end;

    procedure duplicate_edipi_provides_useful_message is
        username varchar2(400);
        session_key varchar2(400);
    begin        
        cwms_sec.add_cwms_user('basic_user2', char_32_array_type('CWMS Users'), '&office_id');
        cwms_sec.update_edipi('basic_user2',1000000000);

        cwms_sec.get_user_credentials(1000000000,username,session_key);
    end;


    procedure can_retrieve_all_users is
        l_cursor sys_refcursor;
        test_row cwms_sec.cat_user_rec_t;    
    begin
      open l_cursor for select * from table( cwms_sec.get_users_tab('&office_id') );    
      ut.expect( l_cursor ).not_to_be_empty();      

      open l_cursor for select * from table( cwms_sec.get_users_tab('&office_id') );    
      loop
        fetch l_cursor into test_row;
        exit when l_cursor%NOTFOUND;
        ut.expect( test_row.username ).not_to_equal('OTHER_DIST');
      end loop;
      close l_cursor;
    end;

    procedure can_retrieve_all_users_with_view is
        l_cursor sys_refcursor;
        test_row cwms_20.av_sec_users%rowtype;
    begin
      open l_cursor for select * from cwms_20.av_sec_users;
      ut.expect(l_cursor).not_to_be_empty();
      -- ut.expect will close the cursor
    end;

    procedure can_get_user_state is    
        l_user_state varchar2(255);
    begin
        l_user_state := cwms_sec.get_user_state('basic_user','&office_id');
        ut.expect(l_user_state).to_equal('UNLOCKED');
    end;


    procedure can_cycle_pd_non_pd_and_back is
        pd_session_key varchar2(255);
        non_pd_session_key varchar2(255);        
        non_pd_user varchar2(255);
        env_user varchar2(255);
        orig_id varchar(255);
    begin
        orig_id := cwms_util.get_user_id;
        dbms_output.put_line( orig_id );
        cwms_sec.create_session(pd_session_key);
        dbms_output.put_line(pd_session_key);
        ut.expect(pd_session_key).to_be_not_null();
        
        cwms_sec.get_user_credentials(1000000000,non_pd_user,non_pd_session_key);
        ut.expect( non_pd_session_key).to_be_not_null();

        cwms_env.set_session_user(non_pd_session_key);
        env_user := cwms_util.get_user_id;
        ut.expect(env_user).to_equal(non_pd_user);

        cwms_env.set_session_user(pd_session_key);
        env_user := cwms_util.get_user_id;
        ut.expect(env_user).to_equal(orig_id);
                                              
        cwms_sec.get_user_credentials(1000000000,non_pd_user,non_pd_session_key);
        ut.expect( non_pd_session_key).to_be_not_null();
      
    end;

end;
/
