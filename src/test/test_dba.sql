create or replace package test_dba as
    -- %suite(Test dba user functionality )
    --%afterall(teardown)
    --%rollback(manual)

    -- %test(create cwms user)
    PROCEDURE test_create_cwms_user;
    -- %test(delete cwms user)
    PROCEDURE test_delete_cwms_user;

    -- %test (store a property: is allowed for read-only user) 
    procedure test_store_property;

    -- %test (store sec.upass.id property)
    procedure test_store_upass_id_property;

    procedure teardown;
end;
/


CREATE OR REPLACE PACKAGE BODY test_dba
AS
    PROCEDURE teardown
    IS
    BEGIN
     test_cwms_prop.teardown;
     test_cwms_msg.teardown;
     DELETE FROM AT_SEC_USER_OFFICE WHERE lower(USERNAME)=lower('TestUser');
     DELETE FROM AT_SEC_USERS WHERE lower(USERNAME)=lower('TestUser');
     DELETE FROM AT_SEC_CWMS_USERS WHERE lower(USERID)=lower('TestUser');
     COMMIT;
    END;
    PROCEDURE test_create_cwms_user
    IS
        l_count   NUMBER;
    BEGIN
        CWMS_SEC.CREATE_USER (
            'TestUser',
            'Test Passwd',
            cwms_20.char_32_array_type ('CWMS PD Users', 'CCP Mgr'),
            '&office_id');

        SELECT COUNT (*)
          INTO l_count
          FROM av_sec_users
         WHERE     username = UPPER ('TestUser')
               AND db_office_id = '&office_id' 
               AND is_member = 'T'
               AND is_locked = 'F'
               AND user_group_id IN ('CWMS PD Users', 'CCP Mgr', 'All Users');

        ut.expect (l_count).to_equal(3);
        SELECT COUNT (*)
          INTO l_count
          FROM av_sec_users
         WHERE     username = UPPER ('TestUser')
               AND db_office_id = '&office_id' 
               AND is_member = 'T'
               AND user_group_id NOT IN
                       ('CWMS PD Users', 'CCP Mgr', 'All Users');
        ut.expect (l_count).to_equal(0);
    END;

    PROCEDURE test_delete_cwms_user
    IS
        l_count   NUMBER;
    BEGIN
        CWMS_SEC.DELETE_USER ('TestUser');
        SELECT COUNT (*)
          INTO l_count
          FROM av_sec_users
         WHERE     username = UPPER ('TestUser')
               AND db_office_id = '&office_id' 
               AND is_member = 'T';
               
        ut.expect (l_count).to_equal(0);
    END;
    PROCEDURE test_store_property
    IS
      l_prop_value VARCHAR2(32);
    BEGIN
     test_cwms_prop.test_store_property;
    END;

    PROCEDURE test_store_upass_id_property
    IS
    BEGIN
     test_cwms_prop.test_store_upass_id_property;
    END;

END;
/
