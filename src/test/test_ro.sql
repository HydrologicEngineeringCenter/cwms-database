create or replace package test_ro as
    -- %suite(Test read only user functionality )
    --%afterall(teardown)
    --%rollback(manual)

    -- %test(set application login info)
    procedure test_set_application_login_info ;
    
    -- %test (store a location: throws an exception)
    --%throws(-20048)
    procedure test_store_location;

    -- %test (store a property: is allowed for read-only user) 
    procedure test_store_property;

    -- %test (store a log message: is allowed for read-only user) 
    procedure test_log_message;

    -- %test (store sec.upass.id property: throws an exception)
    --%throws(-20998)
    procedure test_store_upass_id_property;

    procedure teardown;
end;
/


CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_ro
AS
    PROCEDURE teardown
    IS
    BEGIN
      test_cwms_prop.teardown;
      test_cwms_msg.teardown;
      delete from at_application_session;
      delete from at_application_login;
      commit;
    END; 
    PROCEDURE test_set_application_login_info
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
    
    PROCEDURE test_store_location 
    IS
    BEGIN
      cwms_loc.create_location (p_location_id => 'HECTEST', p_db_office_id => '&office_id');
    END;

    PROCEDURE test_store_property 
    IS
    BEGIN
     test_cwms_prop.test_store_property;
    END;

    PROCEDURE test_log_message 
    IS
    BEGIN
     test_cwms_msg.test_log_db_message;
    END;

    PROCEDURE test_store_upass_id_property 
    IS
    BEGIN
     test_cwms_prop.test_store_upass_id_property; 
    END;
END;
/
