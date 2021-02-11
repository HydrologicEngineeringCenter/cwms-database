create or replace package test_ro as
    -- %suite(Test read only user functionality )
    --%rollback(manual)

    -- %test(set application login info)
    procedure set_application_login_info ;
    
    -- %test (store a location: throws an exception)
    --%throws(-20048)
    procedure store_location;

end;
/


CREATE OR REPLACE PACKAGE BODY CWMS_20.test_ro
AS
    PROCEDURE set_application_login_info
    IS
        l_uuid          VARCHAR2 (64);
        l_app_name      VARCHAR2 (32);
        l_host_name     VARCHAR2 (32);
        l_diff          NUMBER;
        l_last_login    NUMBER;
        l_last_logout   NUMBER;
    BEGIN
        cwms_util.set_application_login (l_uuid,
                                         l_last_login,
                                         l_last_logout,
                                         'ro_user',
                                         'Unit Test',
                                         'Test Host',
                                         'Test Server',
                                         '&office_id');

        SELECT app_name,
               host_name,
               EXTRACT (SECOND FROM SYSTIMESTAMP - login_time)
          INTO l_app_name, l_host_name, l_diff
          FROM cwms_v_application_login
         WHERE uuid = l_uuid;

        ut.expect (UPPER (l_app_name)).to_equal ('UNIT TEST');
        ut.expect (UPPER (l_host_name)).to_equal ('TEST HOST');
        ut.expect (l_diff).to_be_less_than (1);
        DBMS_OUTPUT.put_line (
            l_app_name || ',' || l_host_name || ',' || l_diff);
        cwms_util.set_application_logout (l_last_login,
                                          l_last_logout,
                                          l_uuid);

        SELECT EXTRACT (SECOND FROM SYSTIMESTAMP - logout_time)
          INTO l_diff
          FROM cwms_v_application_login
         WHERE uuid = l_uuid;

        ut.expect (l_diff).to_be_less_than (1);
    END;
    
    PROCEDURE store_location 
    IS
    BEGIN
      cwms_loc.create_location (p_location_id => 'HECTEST', p_db_office_id => '&office_id');
    END;
END;
/
