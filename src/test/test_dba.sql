CREATE OR REPLACE PACKAGE &cwms_schema..test_cwms_dba
AS
    -- %suite(Test cwms dba user functionality )
    --%rollback(manual)
    -- %test(create cwms user)
    PROCEDURE create_cwms_user;
    -- %test(delete cwms user)
    PROCEDURE delete_cwms_user;
    
END;
/

CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_dba
AS
    PROCEDURE create_cwms_user
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

    PROCEDURE delete_cwms_user
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
END test_cwms_dba;
/
