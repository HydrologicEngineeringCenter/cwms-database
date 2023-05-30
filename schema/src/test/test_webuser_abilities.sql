CREATE OR REPLACE PACKAGE &cwms_schema..test_webuser_abilities AUTHID CURRENT_USER
AS
    --%suite(Test WEB USER has it's extra priveleges in CWMS_ENV )
    --%rollback(manual)
    --%beforeall(setup)
    --%afterall(teardown)
    procedure setup;
    procedure teardown;

    --%test(Can query an AT_ table directly.)
    procedure can_query_at_tables;

    --%test(Can context back and forth)
    procedure can_set_context_users;

    --%test(Can interact with the api keys table and view)
    procedure can_interact_with_api_keys_table_and_view;

    --%test(Can set USER context by API key)
    procedure can_set_context_user_by_key;

    multioffice_user varchar(255) := 'l2multof';
END;
/

/* Formatted on 2/24/2022 3:11:58 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_webuser_abilities
AS
    procedure setup is
    begin
        cwms_20.cwms_sec.add_cwms_user(multioffice_user,char_32_array_type('CWMS Users'), '&&office_id');
        cwms_20.cwms_sec.add_user_to_group(multioffice_user,'CWMS Users','&&office_id');
        cwms_20.cwms_sec.add_user_to_group(multioffice_user,'CWMS Users','PAO');
    end;

    procedure teardown is
    begin
        cwms_20.cwms_sec.delete_user(multioffice_user);
        delete from cwms_20.at_api_keys;
    end;


    procedure can_query_at_tables is
        l_count number;
    begin
      select count(*) into l_count from cwms_20.at_base_location;
      ut.expect(l_count).to_be_greater_or_equal(0);
    end;



    procedure can_set_context_users is
        l_normal_user varchar2(255) := '&&eroc.hectest';
        l_web_user varchar2(255) := '&&eroc.webtest';
        l_userid varchar2(32);
        l_session_key varchar2(128); -- used to check connection permissions

        l_users char_32_array_type := char_32_array_type(l_normal_user,multioffice_user);
        l_user varchar2(255);
    begin
        for i in l_users.first..l_users.last loop
            l_user := l_users(i);
            cwms_20.cwms_env.set_session_user_direct(l_user,'&&office_id');
            ut.expect(cwms_util.get_user_id).to_equal(upper(l_user));
            ut.expect(USER).to_equal(upper('&eroc.webtest'));
            begin
                cwms_sec.get_user_credentials(1234567890,l_userid,l_session_key);
                ut.fail('This call should not have succedded');
            exception
            when others then
                null; /** This is supposed to fail */
            end;

            cwms_20.cwms_env.set_session_user_direct(l_web_user,'&&office_id');
            ut.expect(cwms_util.get_user_id).to_equal(upper(l_web_user));
            begin
                cwms_sec.get_user_credentials(1234567890,l_userid,l_session_key);
                ut.expect(l_userid).to_equal(upper(l_user));
                ut.expect(l_session_key).to_be_not_null();
                cwms_sec.remove_session_key(l_session_key);
            exception
            when others then
                ut.fail('This call should have succedded. Environment for WEB_USER not reset correctly.');
            end;
            cwms_20.cwms_env.set_session_user_direct(l_user,'&&office_id');
            ut.expect(cwms_util.get_user_id).to_equal(upper(l_user));
            ut.expect(USER).to_equal(upper('&eroc.webtest'));
        end loop;
    end;

    procedure can_interact_with_api_keys_table_and_view is
        l_userid varchar(32) := upper('&eroc.hectest');
        l_testkey cwms_20.at_api_keys.apikey%type := 'A simple test key';
        l_testkey_name cwms_20.at_api_keys.key_name%type := 'A test key';
        l_testkey_name_out cwms_20.at_api_keys.key_name%type;
    begin
        cwms_20.cwms_env.set_session_user_direct('&&eroc.webtest','&&office_id');
        insert into cwms_20.at_api_keys(userid,key_name,apikey)
            values (l_userid,l_testkey_name,l_testkey);
        select key_name into l_testkey_name_out from cwms_20.av_active_api_keys where apikey=l_testkey;
        ut.expect(l_testkey_name_out).to_equal(l_testkey_name);
    end;


    procedure can_set_context_user_by_key is
        l_testkey1 cwms_20.at_api_keys.apikey%type := 'User 1 Test Key';
        l_testkey2 cwms_20.at_api_keys.apikey%type := 'User 2 Test Key';
        l_user1 varchar2(32) := upper('&eroc.hectest');
        l_user2 varchar2(32) := upper('&eroc.hectest_ro');
    begin
        insert into cwms_20.at_api_keys(userid,key_name,apikey)
            values (l_user1,l_testkey1,l_testkey1);
        insert into cwms_20.at_api_keys(userid,key_name,apikey)
            values (l_user2,l_testkey2,l_testkey2);

        cwms_env.set_session_user_apikey(l_testkey1,'&&office_id');
        ut.expect(cwms_util.get_user_id).to_equal(l_user1);

        cwms_env.set_session_user_apikey(l_testkey2,'&&office_id');
        ut.expect(cwms_util.get_user_id).to_equal(l_user2);

        /** I don't believe it but this actually is required, which is good. */
        cwms_env.set_session_user_direct(upper('&eroc.webtest'));



    end;

END;
/
