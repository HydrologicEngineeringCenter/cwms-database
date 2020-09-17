create or replace package test_aaa as
    -- %suite(CWMS Authentication and Authorization functions )

    -- %test(Simple login of CAC user works)
    procedure simple_login_works;
end;
/


create or replace package body test_aaa as
    procedure simple_login_works is
    begin
        ut.expect( 0 ).to_(equal(2));
    end;
end;
/

