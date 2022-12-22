CREATE OR REPLACE PACKAGE &cwms_schema..test_aaa_normaluserfails AUTHID CURRENT_USER 
AS
    -- %suite(Test AAA system as Normal user to make sure we aren't leaking information )
    
    -- %test(Can retrieve all users using View)    
    procedure can_retrieve_all_users_with_view; 
    
    -- %test(Normal user cannot arbitrarily set user context)
    -- %throws(-20998)
    procedure cannot_set_context_users;
END;
/

/* Formatted on 2/24/2022 3:11:58 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_aaa_normaluserfails
AS
    procedure can_retrieve_all_users_with_view is
        l_cursor sys_refcursor;
        test_row cwms_20.av_sec_users%rowtype;
    begin
      open l_cursor for select * from cwms_20.av_sec_users;
      ut.expect(l_cursor).to_be_empty();      
    end;


    procedure cannot_set_context_users is
        l_other_user varchar2(255) := '&eroc.hectest_pu';
        l_web_user varchar2(255) := '&eroc.webtest';
    begin
        ut.expect(cwms_util.get_user_id()).to_equal(upper('&EROC.hectest'));
        cwms_20.cwms_env.set_session_user_direct(l_other_user);
        ut.expect(cwms_util.get_user_id()).not_to_equal(upper(l_other_user));
        ut.fail('This should not have worked');
    end;
END;
/
