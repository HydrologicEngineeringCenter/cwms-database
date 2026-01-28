CREATE OR REPLACE PACKAGE &cwms_schema..test_aaa_normaluserfails AUTHID CURRENT_USER 
AS
    -- %suite(Test AAA system as Normal user to make sure we aren't leaking information )
    
    -- %test(Can retrieve all users using View)    
    procedure can_retrieve_all_users_with_view; 
    
    -- %test(Normal user cannot arbitrarily set user context)
    -- %throws(-20998)
    procedure cannot_set_context_users;

    --%test(Normal user has no READ access to sensitive tables)
    procedure no_read_access;
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

    procedure no_read_access is
        c_owner constant varchar2(128) := '&&cwms_schema';
        type t_table_list is table of varchar2(128);
        c_tables constant t_table_list := t_table_list(
              'AT_API_KEYS',
              'AT_SEC_ALLOW',
              'AT_SEC_CWMS_USERS',
              'AT_SEC_LOCKED_USERS',
              'AT_SEC_SERVICE_USER',
              'AT_SEC_SESSION',
              'AT_SEC_TS_GROUPS',
              'AT_SEC_TS_GROUP_MASKS',
              'AT_SEC_USERS',
              'AT_SEC_USER_GROUPS',
              'AT_SEC_USER_OFFICE'
            );

        l_cnt number;
    begin
        for i in 1 .. c_tables.count loop
            select count(*)
            into l_cnt
            from all_tab_privs p
            where p.table_schema = c_owner
              and p.table_name   = c_tables(i)
              and p.privilege    = 'SELECT'
              and (
                p.grantee = user
                    or p.grantee = 'PUBLIC'
                    or p.grantee in (select granted_role from user_role_privs)
                );

            if l_cnt <> 0 then
                ut.fail(
                        'Expected no SELECT on ' || c_owner || '.' || c_tables(i) ||
                        ' for user=' || user || '. Found count=' || l_cnt
                );
            end if;

            begin
                execute immediate
                    'select * from ' || c_owner || '.' || c_tables(i) || ' where rownum = 1';
                ut.fail(
                        'Expected SELECT to fail on ' || c_owner || '.' || c_tables(i) ||
                        ' for user=' || user
                );
            exception
                when others then
                    if sqlcode not in (-942, -1031) then
                        ut.fail(
                                'Expected permission error on ' || c_owner || '.' || c_tables(i) ||
                                ' for user=' || user || '. Got ' || sqlcode || ' ' || sqlerrm
                        );
                    end if;
            end;
        end loop;
    end;
END;
/
