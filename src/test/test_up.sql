create or replace package test_up as
    -- %suite(Test read only user functionality )
    --%beforeall(setup)
    --%afterall(teardown)
    --%rollback(manual)

    
    -- %test (test UPASS updates ) 
    procedure test_upass_update;

    -- %test (test UPASS delete ) 
    procedure test_upass_delete;

    procedure teardown;
    procedure setup;
end;
/


CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_up
AS
    PROCEDURE setup
    IS
    BEGIN
     execute immediate 'alter trigger &cwms_schema..ST_PROPERTIES disable';
     insert into at_properties values(53,'CWMSDB','sec.upass.id','&upass_id','UPASS USER');
     insert into at_sec_cwms_users(userid) values ('deleteme');
     commit;
     execute immediate 'alter trigger &cwms_schema..ST_PROPERTIES enable';
    END;

    PROCEDURE teardown
    IS
    BEGIN
      test_cwms_prop.teardown;
      test_cwms_msg.teardown;
      update at_sec_cwms_users set principle_name='' where lower(userid)='&upass_id';
      delete from at_sec_cwms_users where lower(userid)='deleteme';
      commit;
    END; 

    PROCEDURE test_upass_update 
    IS
     l_count NUMBER;
    BEGIN
    	&cwms_schema..cwms_upass.update_cwms_user ('&upass_id',
                                         'Last',
                                         'M',
                                         'F',
                                         'USACE',
                                         'HEC',
                                         '1234567891 1111',
                                         'x@y',
                                         'A',
                                         '1234567891@mil');
    	select count(*) into l_count from at_sec_cwms_users where lower(userid)='&upass_id' and edipi=1234567891;
    	ut.expect(1).to_equal(l_count);
    END;

    PROCEDURE test_upass_delete 
    IS
     l_count NUMBER;
    BEGIN
    	&cwms_schema..cwms_upass.update_cwms_user ('deleteme',
                                         'Last',
                                         'M',
                                         'F',
                                         'USACE',
                                         'HEC',
                                         '1234567891 1111',
                                         'x@y',
                                         'D',
                                         '1234567891@mil');
    	select count(*) into l_count from at_sec_cwms_users where lower(userid)='deleteme';
    	ut.expect(0).to_equal(l_count);
    END;

END;
/
