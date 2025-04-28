create or replace package test_cwms_prop as
    -- %suite(Test cwms prop package )
    --%afterall(teardown)
    --%rollback(manual)

    -- %test (store a property) 
    procedure test_store_property;

    -- %test (store sec.upass.id property: Only admin user can set this. Otherwise throw an exception)
    --%throws(-20998)
    procedure test_store_upass_id_property;

    procedure teardown;
end;
/


CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_prop
AS
    PROCEDURE teardown
    IS
    BEGIN
      delete from at_properties;
      commit;
    END; 

    PROCEDURE test_store_property 
    IS
      l_prop_value VARCHAR2(32);
    BEGIN
      cwms_properties.set_property ('CWMSDB','TEST_PROP','TEST_VAL','NO COMMENT','&office_id');
      l_prop_value := cwms_properties.get_property('CWMSDB','TEST_PROP','DEFAULT','&office_id');
      ut.expect ('TEST_VAL').to_equal(l_prop_value);
    END;

    PROCEDURE test_store_upass_id_property 
    IS
      l_prop_value VARCHAR2(32);
    BEGIN
      cwms_properties.set_property ('CWMSDB','sec.upass.id','TEST_VAL','NO COMMENT','CWMS');
      l_prop_value := cwms_properties.get_property('CWMSDB','sec.upass.id','DEFAULT','CWMS');
      ut.expect ('TEST_VAL').to_equal(l_prop_value);
    END;
END;
/
