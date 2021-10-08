CREATE OR REPLACE package &&cwms_schema..test_cwms_ts as

--%suite(Test cwms_ts package code)
--%beforeall (setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test setting active flag)
procedure test_set_active_flag;
--%test(Test yearly tables)
procedure test_yearly_tables;
--%test(Test filter duplicates)
procedure test_filter_duplicates;


test_base_location_id VARCHAR2(32) := 'TestLoc1';
procedure setup;
procedure teardown;
end test_cwms_ts;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY &&cwms_schema..test_cwms_ts
AS


    --------------------------------------------------------------------------------
    -- procedure delete_all
    --------------------------------------------------------------------------------
    PROCEDURE  delete_all
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

    --------------------------------------------------------------------------------
    -- procedure store_location_with_multiple_attributes
    --------------------------------------------------------------------------------

    PROCEDURE test_set_active_flag
    IS
        l_base_location_id   av_loc.base_location_id%TYPE;
        l_cwms_ts_id         AV_CWMS_TS_ID.CWMS_TS_ID%TYPE;
        l_base_loc_active    AV_CWMS_TS_ID.BAS_LOC_ACTIVE_FLAG%TYPE;
        l_loc_active         AV_CWMS_TS_ID.LOC_ACTIVE_FLAG%TYPE;
        l_ts_active          AV_CWMS_TS_ID.TS_ACTIVE_FLAG%TYPE;
        l_net_ts_active      AV_CWMS_TS_ID.NET_TS_ACTIVE_FLAG%TYPE;
    BEGIN
        l_base_location_id := test_base_location_id;
        l_cwms_ts_id := l_base_location_id || '.Stage.Inst.0.0.raw';
        cwms_loc.store_location (p_location_id    => l_base_location_id,
                                 p_active         => 'F',
                                 p_db_office_id   => '&&office_id');
        COMMIT;
        cwms_ts.create_ts ('&&office_id', l_cwms_ts_id);
        COMMIT;

          SELECT bas_loc_active_flag,
                 loc_active_flag,
                 ts_active_flag,
                 net_ts_active_flag
            INTO l_base_loc_active,
                 l_loc_active,
                 l_ts_active,
                 l_net_ts_active
            FROM av_cwms_ts_id
           WHERE cwms_ts_id = l_cwms_ts_id
        ORDER BY 1;

        COMMIT;
        ut.expect (l_base_loc_active).to_equal ('F');
        ut.expect (l_loc_active).to_equal ('F');
        ut.expect (l_ts_active).to_equal ('T');
        ut.expect (l_net_ts_active).to_equal ('F');
        cwms_loc.store_location (p_location_id    => l_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        COMMIT;


          SELECT bas_loc_active_flag,
                 loc_active_flag,
                 ts_active_flag,
                 net_ts_active_flag
            INTO l_base_loc_active,
                 l_loc_active,
                 l_ts_active,
                 l_net_ts_active
            FROM av_cwms_ts_id
           WHERE cwms_ts_id = l_cwms_ts_id
        ORDER BY 1;

        COMMIT;
        ut.expect (l_base_loc_active).to_equal ('T');
        ut.expect (l_loc_active).to_equal ('T');
        ut.expect (l_ts_active).to_equal ('T');
        ut.expect (l_net_ts_active).to_equal ('T');
        CWMS_TS.UPDATE_TS_ID (p_cwms_ts_id       => l_cwms_ts_id,
                              p_ts_active_flag   => 'F',
                              p_db_office_id     => '&&office_id');
        COMMIT;

          SELECT bas_loc_active_flag,
                 loc_active_flag,
                 ts_active_flag,
                 net_ts_active_flag
            INTO l_base_loc_active,
                 l_loc_active,
                 l_ts_active,
                 l_net_ts_active
            FROM av_cwms_ts_id
           WHERE cwms_ts_id = l_cwms_ts_id
        ORDER BY 1;


        ut.expect (l_base_loc_active).to_equal ('T');
        ut.expect (l_loc_active).to_equal ('T');
        ut.expect (l_ts_active).to_equal ('F');
        ut.expect (l_net_ts_active).to_equal ('F');
    END;
    PROCEDURE test_yearly_tables
    IS
        l_cwms_ts_id   AV_CWMS_TS_ID.CWMS_TS_ID%TYPE;
        p_times        CWMS_TS.NUMBER_ARRAY;
        p_values       CWMS_TS.DOUBLE_ARRAY;
        p_qualities    CWMS_TS.NUMBER_ARRAY;
        l_cmd          VARCHAR2 (512);
        l_count        NUMBER;
    BEGIN
        l_cwms_ts_id := test_base_location_id || '.Stage.Inst.1Hour.0.';
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id.');


        FOR c
            IN (SELECT table_name, start_date, end_date
                  FROM at_ts_table_properties)
        LOOP
            p_times (1) := CWMS_UTIL.TO_MILLIS (c.start_date) + 3600 * 1000;
            p_values (1) := 10;
            p_qualities (1) := 10;
            p_times (2) := CWMS_UTIL.TO_MILLIS (c.start_date) - 3600 * 1000;
            p_values (2) := 10;
            p_qualities (2) := 10;
            p_times (3) := CWMS_UTIL.TO_MILLIS (c.end_date) - 3600 * 1000;
            p_values (3) := 10;
            p_qualities (3) := 10;
            p_times (4) := CWMS_UTIL.TO_MILLIS (c.end_date) + 3600 * 1000;
            p_values (4) := 10;
            p_qualities (4) := 10;
            CWMS_TS.STORE_TS (l_cwms_ts_id || c.table_name,
                              'FT',
                              p_times,
                              p_values,
                              p_qualities,
                              'Delete Insert');
            l_cmd :=
                   'select count(*) from '
                || c.table_name
                || ' where date_time = (select start_date+(1/24) from at_ts_table_properties where table_name = '''
                || c.table_name
                || ''') and ts_code = (select ts_code from at_cwms_ts_id where cwms_ts_id = '''
                || l_cwms_ts_id
                || c.table_name
                || ''')';
            DBMS_OUTPUT.put_line (l_cmd);

            EXECUTE IMMEDIATE l_cmd
                INTO l_count;

            ut.expect (l_count).to_equal (1);
            l_cmd :=
                   'select count(*) from '
                || c.table_name
                || ' where date_time = (select end_date-(1/24) from at_ts_table_properties where table_name = '''
                || c.table_name
                || ''') and ts_code = (select ts_code from at_cwms_ts_id where cwms_ts_id = '''
                || l_cwms_ts_id
                || c.table_name
                || ''')';

            EXECUTE IMMEDIATE l_cmd
                INTO l_count;

            DBMS_OUTPUT.put_line (l_cmd);
            ut.expect (l_count).to_equal (1);

            l_cmd :=
                   'select count(*) from av_tsv where ts_code = (select ts_code from at_cwms_ts_id where cwms_ts_id = '''
                || l_cwms_ts_id
                || c.table_name
                || ''')';

            EXECUTE IMMEDIATE l_cmd
                INTO l_count;

            DBMS_OUTPUT.put_line (l_cmd);

            IF (   c.table_name = 'AT_TSV_ARCHIVAL'
                OR c.table_name = 'AT_TSV_INF_AND_BEYOND')
            THEN
                ut.expect (l_count).to_equal (3);
            ELSE
                ut.expect (l_count).to_equal (4);
            END IF;
        END LOOP;

        FOR c IN (SELECT table_name FROM at_ts_table_properties where table_name<>'AT_TSV_INF_AND_BEYOND')
        LOOP
            EXECUTE IMMEDIATE   'insert into at_tsv_inf_and_beyond select * from '
                             || c.table_name;

            EXECUTE IMMEDIATE 'delete from ' || c.table_name;

            COMMIT;
        END LOOP;

        move_data_from_inf_to_yearly;

        FOR c IN (SELECT table_name FROM at_ts_table_properties)
        LOOP
            l_cmd :=
                   'select count(*) from '
                || c.table_name
                || ' where date_time = (select start_date+(1/24) from at_ts_table_properties where table_name = '''
                || c.table_name
                || ''') and ts_code = (select ts_code from at_cwms_ts_id where cwms_ts_id = '''
                || l_cwms_ts_id
                || c.table_name
                || ''')';
            DBMS_OUTPUT.put_line (l_cmd);

            EXECUTE IMMEDIATE l_cmd
                INTO l_count;

            ut.expect (l_count).to_equal (1);
            l_cmd :=
                   'select count(*) from '
                || c.table_name
                || ' where date_time = (select end_date-(1/24) from at_ts_table_properties where table_name = '''
                || c.table_name
                || ''') and ts_code = (select ts_code from at_cwms_ts_id where cwms_ts_id = '''
                || l_cwms_ts_id
                || c.table_name
                || ''')';

            EXECUTE IMMEDIATE l_cmd
                INTO l_count;

            DBMS_OUTPUT.put_line (l_cmd);
            ut.expect (l_count).to_equal (1);

            l_cmd :=
                   'select count(*) from av_tsv where ts_code = (select ts_code from at_cwms_ts_id where cwms_ts_id = '''
                || l_cwms_ts_id
                || c.table_name
                || ''')';

            EXECUTE IMMEDIATE l_cmd
                INTO l_count;

            DBMS_OUTPUT.put_line (l_cmd);

            IF (   c.table_name = 'AT_TSV_ARCHIVAL'
                OR c.table_name = 'AT_TSV_INF_AND_BEYOND')
            THEN
                ut.expect (l_count).to_equal (3);
            ELSE
                ut.expect (l_count).to_equal (4);
            END IF;
        END LOOP;
    END test_yearly_tables;

    --------------------------------------------------------------------------------
    -- procedure test_filter_duplicates
    --------------------------------------------------------------------------------
    procedure test_filter_duplicates
    is
        l_ts_id      varchar2(191)   := 'TestFilterDupsMsg.Code.Inst.1Hour.0.Test';
        l_loc_id     varchar2(57)    := cwms_util.split_text(l_ts_id, 1, '.');
        l_unit       varchar2(16)    := 'n/a';
        l_office_id  varchar2(16)    := '&&office_id';
        l_ts_data cwms_t_ztsv_array := cwms_t_ztsv_array(
            cwms_t_ztsv(date '2021-10-01' + 1 / 24, 1, 0),
            cwms_t_ztsv(date '2021-10-01' + 2 / 24, 2, 0),
            cwms_t_ztsv(date '2021-10-01' + 3 / 24, 3, 0),
            cwms_t_ztsv(date '2021-10-01' + 4 / 24, 4, 0),
            cwms_t_ztsv(date '2021-10-01' + 5 / 24, 5, 0),
            cwms_t_ztsv(date '2021-10-01' + 6 / 24, 6, 0));
        l_ts_data2   cwms_t_ztsv_array;
        l_ts         timestamp;
        l_msg_rec    cwms_v_ts_msg_archive%rowtype;
    begin
        -------------------------------------
        -- set up the overlapping data set --
        -------------------------------------
        l_ts_data2 := l_ts_data;
        l_ts_data2.extend;
        l_ts_data2(l_ts_data2.count) := cwms_t_ztsv(
            l_ts_data(l_ts_data.count).date_time + 1 / 24,
            l_ts_data(l_ts_data.count).value + 1,
            0);
        -----------------------------------------------------
        -- create the location and store the original data --
        -----------------------------------------------------
        cwms_loc.store_location(
            p_location_id  => l_loc_id,
            p_db_office_id => l_office_id);

        cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_timeseries_data => l_ts_data,
            p_store_rule      => cwms_util.replace_all,
            p_office_id       => l_office_id);
        ------------------------------------------------------------
        -- set filter duplicates to FALSE and store the same data --
        ------------------------------------------------------------
        cwms_ts.set_filter_duplicates_ofc('F', l_office_id);

        l_ts := systimestamp;

        cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_timeseries_data => l_ts_data,
            p_store_rule      => cwms_util.replace_all,
            p_office_id       => l_office_id);
        --------------------------------------------------------------------
        -- we should have a ts archive message for the entire time window --
        --------------------------------------------------------------------
        select *
          into l_msg_rec
          from cwms_v_ts_msg_archive
         where message_time > l_ts
           and db_office_id = l_office_id
           and cwms_ts_id = l_ts_id;

        ut.expect(l_msg_rec.first_data_time).to_equal(l_ts_data(1).date_time);
        ut.expect(l_msg_rec.last_data_time).to_equal(l_ts_data(l_ts_data.count).date_time);
        -----------------------------------------------------------
        -- set filter duplicates to TRUE and store the same data --
        -----------------------------------------------------------
        cwms_ts.set_filter_duplicates_ofc('F', l_office_id);
        cwms_ts.set_filter_duplicates_ofc('T', l_office_id);

        l_ts := systimestamp;

        cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_timeseries_data => l_ts_data,
            p_store_rule      => cwms_util.replace_all,
            p_office_id       => l_office_id);
        -----------------------------------------------
        -- we should not have ANY ts archive message --
        -----------------------------------------------
        begin
            select *
              into l_msg_rec
              from cwms_v_ts_msg_archive
             where message_time > l_ts
               and db_office_id = l_office_id
               and cwms_ts_id = l_ts_id;

            cwms_err.raise('ERROR', 'Expected exception not raised');
        exception
            when no_data_found then null;
        end;
        ----------------------------------------------------------------
        -- leave filter duplicates to TRUE and store overlapping data --
        ----------------------------------------------------------------
        l_ts := systimestamp;

        cwms_ts.zstore_ts(
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_timeseries_data => l_ts_data2,
            p_store_rule      => cwms_util.replace_all,
            p_office_id       => l_office_id);
        -------------------------------------------------------------------------------------------------
        -- we should have a ts archive message for only the non-overlapping portion of the time window --
        -------------------------------------------------------------------------------------------------
        select *
          into l_msg_rec
          from cwms_v_ts_msg_archive
         where message_time > l_ts
           and db_office_id = l_office_id
           and cwms_ts_id = l_ts_id;

        ut.expect(l_msg_rec.first_data_time).to_equal(l_ts_data2(l_ts_data2.count).date_time);
        ut.expect(l_msg_rec.last_data_time).to_equal(l_ts_data2(l_ts_data2.count).date_time);
        -----------------------------------------
        -- delete the location and time series --
        -----------------------------------------
        cwms_loc.delete_location(
            p_location_id   => l_loc_id,
            p_delete_action => cwms_util.delete_all,
            p_db_office_id  => l_office_id);
    end test_filter_duplicates;
END test_cwms_ts;
/

SHOW ERRORS;
