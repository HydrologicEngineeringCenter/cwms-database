create or replace package &&cwms_schema..test_cwms_err as

--%suite(Test cwms_err package code)

--%beforeall(setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test raise TS_ID_NOT_FOUND with p1 and p2 works )
--%test(Test raise TS_ID_NOT_FOUND with null and p2 works)
    procedure raise_ts_not_found_p1_p2;
    procedure raise_ts_not_found_null_p2;

    procedure setup;
    procedure teardown;

end test_cwms_err;
/
create or replace package body &&cwms_schema..test_cwms_err as
    --------------------------------------------------------------------------------
-- procedure setup
--------------------------------------------------------------------------------
    procedure setup
        is
    begin
        null;
    end setup;
--------------------------------------------------------------------------------
-- procedure teardown
--------------------------------------------------------------------------------
    procedure teardown
        is
    begin
        null;
    end teardown;
--------------------------------------------------------------------------------
-- procedure raise_ts_not_found_p1_p2
--------------------------------------------------------------------------------
    procedure raise_ts_not_found_p1_p2
        is
        TS_ID_NOT_FOUND       EXCEPTION;
        PRAGMA EXCEPTION_INIT (TS_ID_NOT_FOUND, -20001);

    begin
        --------------------------------------------
        -- make sure p1 thru p9 get substituted --
        --------------------------------------------
        cwms_err.raise(TS_ID_NOT_FOUND, 'thefirstarg', 'unlikelysecondparam');
    exception
        when TS_ID_NOT_FOUND then
            ut.expect(instr(cwms_err.get_error_message, 'TS_ID_NOT_FOUND') != 0).to_be_true;
            ut.expect(instr(cwms_err.get_error_message, 'thefirstarg') != 0).to_be_true;
            ut.expect(instr(cwms_err.get_error_message, '%1') != 0).to_be_false;
            ut.expect(instr(cwms_err.get_error_message, 'unlikelysecondparam') != 0).to_be_true;
            ut.expect(instr(cwms_err.get_error_message, '%2') != 0).to_be_false;
    end raise_ts_not_found_p1_p2;

--------------------------------------------------------------------------------
-- procedure raise_ts_not_found_null_p2
--------------------------------------------------------------------------------
    procedure raise_ts_not_found_null_p2
        is
        TS_ID_NOT_FOUND       EXCEPTION;
        PRAGMA EXCEPTION_INIT (TS_ID_NOT_FOUND, -20001);

    begin
        --------------------------------------------
        -- make sure p2 still gets substituted    --
        --------------------------------------------
        cwms_err.raise(TS_ID_NOT_FOUND, null, 'unlikelysecondparam');
    exception
        when TS_ID_NOT_FOUND then
            ut.expect(instr(cwms_err.get_error_message, 'TS_ID_NOT_FOUND') != 0).to_be_true;
            ut.expect(instr(cwms_err.get_error_message, '%1') != 0).to_be_true;
            ut.expect(instr(cwms_err.get_error_message, 'unlikelysecondparam') != 0).to_be_true;
            ut.expect(instr(cwms_err.get_error_message, '%2') != 0).to_be_false;

    end raise_ts_not_found_null_p2;


end test_cwms_err;
/
show errors;

grant execute on test_cwms_err to cwms_user;
