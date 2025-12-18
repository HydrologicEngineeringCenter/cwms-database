CREATE OR REPLACE package &cwms_schema..test_cwms_text as

--%suite(Test CWMS_TEXT package code)
--%beforeall (setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test saving null text timeseries value)
procedure test_store_null_text_ts;

test_base_location_id VARCHAR2(32) := 'TestLoc1';
c_start_time    constant date         := date '2020-01-01';

procedure setup;
procedure teardown;
end test_cwms_text;
/
show errors;
/* Formatted on 4/28/2022 2:38:41 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_text
AS
   --------------------------------------------------------------------------------
    -- procedure delete_all
    --------------------------------------------------------------------------------
    PROCEDURE delete_all
    IS
        exc_location_id_not_found   EXCEPTION;
        PRAGMA EXCEPTION_INIT (exc_location_id_not_found, -20025);
    BEGIN
        FOR rec
            IN (SELECT COLUMN_VALUE     AS loc_name
                  FROM TABLE (str_tab_t (test_base_location_id)))
        LOOP
            BEGIN
                cwms_loc.delete_location (
                    p_location_id     => rec.loc_name,
                    p_delete_action   => cwms_util.delete_all,
                    p_db_office_id    => '&&office_id');
            EXCEPTION
                WHEN exc_location_id_not_found
                THEN
                    NULL;
            END;
        END LOOP;
    END delete_all;
    PROCEDURE setup
    IS
    BEGIN
        delete_all;
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'F',
                                 p_db_office_id   => '&&office_id');
        COMMIT;
    END;
    PROCEDURE teardown
    IS
    BEGIN
        delete_all;
    END teardown;
    procedure test_store_null_text_ts
    IS
        l_cwms_ts_id      VARCHAR2 (200);
        l_crsr                sys_refcursor;
        l_times            date_table_type := date_table_type();
        l_text                varchar2(32767);
        l_version_date      date;
        l_data_entry_date     date;
        l_clob                clob;
        l_number              number;
        l_count       integer;
        l_end_time      constant date := c_start_time + 1;
        l_start_time    constant date := c_start_time - 1;
        l_date_time       date;

    BEGIN
        l_cwms_ts_id := test_base_location_id || '.Text.Inst.~1Day.0.raw';
        l_times.extend;
        l_times(1) := c_start_time;
        cwms_text.store_ts_text (
            p_tsid => l_cwms_ts_id,
            p_text => null,  
            p_times => l_times,
            p_office_id => '&&office_id'
        );
        l_crsr := cwms_text.retrieve_ts_std_text_f (
            p_tsid             => l_cwms_ts_id,
            p_std_text_id_mask => '*',
            p_start_time       => l_start_time,
            p_end_time         => l_end_time,
            p_time_zone        => 'UTC',
            p_office_id        => '&&office_id');
            l_count := 0;
        loop
            fetch l_crsr
            into l_date_time,
                    l_version_date,
                    l_data_entry_date,
                    l_text,
                    l_number,
                    l_clob;
            exit when l_crsr%notfound;
            l_count := l_count + 1;
        end loop;
        close l_crsr;
        ut.expect(l_text).to_be_null();
        cwms_ts.delete_ts(l_cwms_ts_id, cwms_util.delete_all, '&&office_id');
    END test_store_null_text_ts;

END test_cwms_text;
/
show errors;
grant execute on test_cwms_text to cwms_user;
