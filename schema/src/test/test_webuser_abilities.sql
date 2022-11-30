CREATE OR REPLACE PACKAGE &cwms_schema..test_webuser_abilities AUTHID CURRENT_USER 
AS
    -- %suite(Test WEB USER has it's extra priveleges in CWMS_ENV )
    --%rollback(manual)

    -- %test(Can query an AT_ table directly.)
    procedure can_query_at_tables; 
    
    -- %test(Can context back and forth)
    procedure can_set_context_users;
    
END;
/

/* Formatted on 2/24/2022 3:11:58 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_webuser_abilities
AS
    procedure can_query_at_tables is
        l_count number;
    begin
      select count(*) into l_count from cwms_20.at_base_location;
      ut.expect(l_count).to_be_greater_or_equal(0);
    end;

    procedure can_set_context_users is
        l_normal_user varchar2(255) := '&eroc.hectest';
        l_web_user varchar2(255) := '&eroc.webtest';
        l_userid varchar2(32);
        l_session_key varchar2(128);

    begin
        cwms_20.cwms_env.set_session_user_direct(l_normal_user);
        ut.expect(cwms_util.get_user_id).to_equal(upper(l_normal_user));
        ut.expect(USER).to_equal(upper('&eroc.webtest'));
        begin
            cwms_sec.get_user_credentials(1234567890,l_userid,l_session_key);
            ut.fail('This call should not have succedded');
        exception
          when others then
            null; /** This is supposed to fail */
        end;

        cwms_20.cwms_env.set_session_user_direct(l_web_user);
        ut.expect(cwms_util.get_user_id).to_equal(upper(l_web_user));
        begin
            cwms_sec.get_user_credentials(1234567890,l_userid,l_session_key);
            ut.expect(l_userid).to_equal(upper(l_normal_user));
            ut.expect(l_session_key).to_be_not_null();
            cwms_sec.remove_session_key(l_session_key);
        exception
          when others then
            ut.fail('This call should have succedded. Environment for WEB_USER not reset correctly.');
        end;
    end;
END;
/
