CREATE OR REPLACE package &cwms_schema..test_cwms_ts as

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
--%test(Test retrieve TS with calendar-based times [JIRA Issue CWDB-157])
procedure test_retrieve_ts_with_calendar_based_times__JIRA_CWDB_157;

--%test(Test creation various types of time series)
procedure test_create_ts;

--%test(Incremental precip with non zero duration)
--%throws(-20205)
PROCEDURE inc_with_zero_duration;

--%test(Incremental cumulative precip with zero duration)
--%throws(-20205)
PROCEDURE cum_with_non_zero_duration;

--%test(regular interval with until changed duration)
--%throws(-20205)
    PROCEDURE untilchanged_with_regular;
--%test(non-const parameter type with until changed duration)
--%throws(-20205)
    PROCEDURE untilchanged_with_non_const;
--%test(Variable duration with non instantaneous)
--%throws(-20205)    
PROCEDURE variable_with_inst;
    
--%test(Variable duration with const)
--%throws(-20205)   
PROCEDURE variable_with_const;

test_base_location_id VARCHAR2(32) := 'TestLoc1';
procedure setup;
procedure teardown;
end test_cwms_ts;
/

/* Formatted on 3/18/2022 2:16:22 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY &cwms_schema..test_cwms_ts
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
                    p_db_office_id    => '&office_id');
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
                                 p_db_office_id   => '&office_id');
        COMMIT;
    END;

    PROCEDURE teardown
    IS
    BEGIN
        delete_all;
    END teardown;

    PROCEDURE store_a_value (p_cwms_ts_id VARCHAR2, p_units VARCHAR2)
    IS
        p_times       CWMS_TS.NUMBER_ARRAY;
        p_values      CWMS_TS.DOUBLE_ARRAY;
        p_qualities   CWMS_TS.NUMBER_ARRAY;
        l_ts_code     NUMBER;
        l_count INTEGER;
    BEGIN
        cwms_ts.create_ts ('&office_id', p_cwms_ts_id);
        COMMIT;

        SELECT COUNT (*)
          INTO l_count
          FROM at_cwms_ts_id
         WHERE UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id);

        ut.expect (l_count).to_equal (1);

        SELECT ts_code
          INTO l_ts_code
          FROM at_cwms_ts_id
         WHERE cwms_ts_id = p_cwms_ts_id;

        p_times (1) := CWMS_UTIL.TO_MILLIS (TIMESTAMP '2010-01-01 00:00:00');
        p_values (1) := 20.0;
        p_qualities (1) := 10;
        CWMS_TS.STORE_TS (p_cwms_ts_id,
                          p_units,
                          p_times,
                          p_values,
                          p_qualities,
                          'Delete Insert');

        SELECT COUNT (*)
          INTO l_count
          FROM at_tsv_2010
         WHERE ts_code = l_ts_code;

        ut.expect (l_count).to_equal (1);
        CWMS_TS.DELETE_TS ( p_cwms_ts_id,cwms_util.delete_all);

        SELECT COUNT (*)
          INTO l_count
          FROM at_cwms_ts_id
         WHERE UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id);

        ut.expect (l_count).to_equal (0);
    END;

    PROCEDURE throw_an_exception(p_cwms_ts_id VARCHAR2)
    IS
    BEGIN
        cwms_ts.create_ts ('&office_id', p_cwms_ts_id);
        COMMIT;
    END;

    PROCEDURE inc_with_zero_duration
    IS
    BEGIN
        throw_an_exception(test_base_location_id || '.Precip.Inc.1Hour.0.raw');
    END;

    PROCEDURE cum_with_non_zero_duration
    IS
    BEGIN
        throw_an_exception(test_base_location_id || '.Precip.Cum.1Hour.1Hour.raw');
    END;

    PROCEDURE untilchanged_with_regular
    IS
    BEGIN
        throw_an_exception(test_base_location_id || '.Precip.Const.1Hour.UntilChanged.raw');
    END;

    PROCEDURE untilchanged_with_non_const
    IS
    BEGIN
        throw_an_exception(test_base_location_id || '.Precip.Ave.0.UntilChanged.raw');
    END;

    PROCEDURE variable_with_inst
    IS
    BEGIN
        throw_an_exception(test_base_location_id || '.Precip.Inst.0.Variable.raw');
    END;

    PROCEDURE variable_with_const
    IS
    BEGIN
        throw_an_exception(test_base_location_id || '.Precip.Const.0.Variable.raw');
    END;

    PROCEDURE test_create_ts
    IS
    BEGIN
        store_a_value( test_base_location_id || '.Flow.Ave.Irr.Variable.raw','cfs');
        store_a_value( test_base_location_id || '.Flow.Ave.0.Variable.raw','cfs');
        store_a_value( test_base_location_id || '.Opening.Const.Irr.UntilChanged.raw','ft');
        store_a_value( test_base_location_id || '.Opening.Const.0.UntilChanged.raw','ft');
        store_a_value ( test_base_location_id || '.Precip.Cum.1Hour.0.raw','in');
        store_a_value (test_base_location_id || '.Precip.Inc.1Hour.1Hour.raw','in');
    END;

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
                                 p_db_office_id   => '&office_id');
        COMMIT;
        cwms_ts.create_ts ('&office_id', l_cwms_ts_id);
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
                                 p_db_office_id   => '&office_id');
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
                              p_db_office_id     => '&office_id');
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
                                 p_db_office_id   => '&office_id');


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

        FOR c IN (SELECT table_name
                    FROM at_ts_table_properties
                   WHERE table_name <> 'AT_TSV_INF_AND_BEYOND')
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
    PROCEDURE test_filter_duplicates
    IS
        l_ts_id       VARCHAR2 (191)
                          := test_base_location_id || '.Code.Inst.1Hour.0.Test';
        l_loc_id      VARCHAR2 (57) := test_base_location_id;
        l_unit        VARCHAR2 (16) := 'n/a';
        l_office_id   VARCHAR2 (16) := '&office_id';
        l_ts_data     cwms_t_ztsv_array
            := cwms_t_ztsv_array (
                   cwms_t_ztsv (DATE '2021-10-01' + 1 / 24, 1, 0),
                   cwms_t_ztsv (DATE '2021-10-01' + 2 / 24, 2, 0),
                   cwms_t_ztsv (DATE '2021-10-01' + 3 / 24, 3, 0),
                   cwms_t_ztsv (DATE '2021-10-01' + 4 / 24, 4, 0),
                   cwms_t_ztsv (DATE '2021-10-01' + 5 / 24, 5, 0),
                   cwms_t_ztsv (DATE '2021-10-01' + 6 / 24, 6, 0));
        l_ts_data2    cwms_t_ztsv_array;
        l_ts          TIMESTAMP;
        l_msg_rec     cwms_v_ts_msg_archive%ROWTYPE;
    BEGIN
        -------------------------------------
        -- set up the overlapping data set --
        -------------------------------------
        l_ts_data2 := l_ts_data;
        l_ts_data2.EXTEND;
        l_ts_data2 (l_ts_data2.COUNT) :=
            cwms_t_ztsv (l_ts_data (l_ts_data.COUNT).date_time + 1 / 24,
                         l_ts_data (l_ts_data.COUNT).VALUE + 1,
                         0);
        -----------------------------------------------------
        -- create the location and store the original data --
        -----------------------------------------------------
        cwms_loc.store_location (p_location_id    => l_loc_id,
                                 p_db_office_id   => l_office_id);

        cwms_ts.zstore_ts (p_cwms_ts_id        => l_ts_id,
                           p_units             => l_unit,
                           p_timeseries_data   => l_ts_data,
                           p_store_rule        => cwms_util.replace_all,
                           p_office_id         => l_office_id);
        ------------------------------------------------------------
        -- set filter duplicates to FALSE and store the same data --
        ------------------------------------------------------------
        cwms_ts.set_filter_duplicates_ofc ('F', l_office_id);

        l_ts := SYSTIMESTAMP;

        cwms_ts.zstore_ts (p_cwms_ts_id        => l_ts_id,
                           p_units             => l_unit,
                           p_timeseries_data   => l_ts_data,
                           p_store_rule        => cwms_util.replace_all,
                           p_office_id         => l_office_id);

        --------------------------------------------------------------------
        -- we should have a ts archive message for the entire time window --
        --------------------------------------------------------------------
        SELECT *
          INTO l_msg_rec
          FROM cwms_v_ts_msg_archive
         WHERE     message_time > l_ts
               AND db_office_id = l_office_id
               AND cwms_ts_id = l_ts_id;

        ut.expect (l_msg_rec.first_data_time).to_equal (
            l_ts_data (1).date_time);
        ut.expect (l_msg_rec.last_data_time).to_equal (
            l_ts_data (l_ts_data.COUNT).date_time);
        -----------------------------------------------------------
        -- set filter duplicates to TRUE and store the same data --
        -----------------------------------------------------------
        cwms_ts.set_filter_duplicates_ofc ('T', l_office_id);

        l_ts := SYSTIMESTAMP;

        cwms_ts.zstore_ts (p_cwms_ts_id        => l_ts_id,
                           p_units             => l_unit,
                           p_timeseries_data   => l_ts_data,
                           p_store_rule        => cwms_util.replace_all,
                           p_office_id         => l_office_id);

        -----------------------------------------------
        -- we should not have ANY ts archive message --
        -----------------------------------------------
        BEGIN
            SELECT *
              INTO l_msg_rec
              FROM cwms_v_ts_msg_archive
             WHERE     message_time > l_ts
                   AND db_office_id = l_office_id
                   AND cwms_ts_id = l_ts_id;

            cwms_err.raise ('ERROR', 'Expected exception not raised');
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                NULL;
        END;

        ----------------------------------------------------------------
        -- leave filter duplicates to TRUE and store overlapping data --
        ----------------------------------------------------------------
        l_ts := SYSTIMESTAMP;

        cwms_ts.zstore_ts (p_cwms_ts_id        => l_ts_id,
                           p_units             => l_unit,
                           p_timeseries_data   => l_ts_data2,
                           p_store_rule        => cwms_util.replace_all,
                           p_office_id         => l_office_id);

        -------------------------------------------------------------------------------------------------
        -- we should have a ts archive message for only the non-overlapping portion of the time window --
        -------------------------------------------------------------------------------------------------
        SELECT *
          INTO l_msg_rec
          FROM cwms_v_ts_msg_archive
         WHERE     message_time > l_ts
               AND db_office_id = l_office_id
               AND cwms_ts_id = l_ts_id;

        ut.expect (l_msg_rec.first_data_time).to_equal (
            l_ts_data2 (l_ts_data2.COUNT).date_time);
        ut.expect (l_msg_rec.last_data_time).to_equal (
            l_ts_data2 (l_ts_data2.COUNT).date_time);
        -----------------------------------------
        -- delete the location and time series --
        -----------------------------------------
        cwms_loc.delete_location (p_location_id     => l_loc_id,
                                  p_delete_action   => cwms_util.delete_all,
                                  p_db_office_id    => l_office_id);
    END test_filter_duplicates;

    --------------------------------------------------------------------------------
    -- procedure test_retrieve_ts_with_calendar_based_times__JIRA_CWDB_157
    --------------------------------------------------------------------------------
    PROCEDURE test_retrieve_ts_with_calendar_based_times__JIRA_CWDB_157
    IS
        l_ts_id                     VARCHAR2 (191);
        l_loc_id                    VARCHAR2 (57) := test_base_location_id;
        l_unit                      VARCHAR2 (16) := 'n/a';
        l_office_id                 VARCHAR2 (16) := '&office_id';
        l_ts_data                   cwms_t_ztsv_array;
        l_crsr                      SYS_REFCURSOR;
        l_date_times                cwms_t_date_table;
        l_values                    cwms_t_double_tab;
        l_quality_codes             cwms_t_number_tab;
        l_version_date              DATE;
        l_is_lrts                   VARCHAR2 (1);

        exc_location_id_not_found   EXCEPTION;
        PRAGMA EXCEPTION_INIT (exc_location_id_not_found, -20025);
    BEGIN
        FOR i IN 1 .. 3
        LOOP
            ------------------------------------------------------
            -- delete the location and time series if it exists --
            ------------------------------------------------------
            BEGIN
                cwms_loc.delete_location (
                    p_location_id     => l_loc_id,
                    p_delete_action   => cwms_util.delete_all,
                    p_db_office_id    => l_office_id);
            EXCEPTION
                WHEN exc_location_id_not_found
                THEN
                    NULL;
            END;

            ----------------------------------
            -- setup time series attributes --
            ----------------------------------
            CASE
                WHEN i = 1
                THEN
                    l_version_date := cwms_util.non_versioned;
                    l_is_lrts := 'F';
                WHEN i = 2
                THEN
                    l_version_date := DATE '2022-01-01';
                    l_is_lrts := 'F';
                WHEN i = 3
                THEN
                    l_version_date := DATE '2022-01-01';
                    l_ts_id := REPLACE (l_ts_id, '1Month', '~1Month');
                    l_is_lrts := 'T';
            END CASE;

            -------------------------
            -- create the location --
            -------------------------
            cwms_loc.store_location (p_location_id    => l_loc_id,
                                     p_active         => 'T',
                                     p_db_office_id   => l_office_id);
            l_ts_id := test_base_location_id || '.Code.Inst.1Month.0.Test';

            FOR j IN 1 .. 2
            LOOP
                ----------------------------
                -- create the time series --
                ----------------------------
                IF j = 1
                THEN
                    l_ts_data :=
                        cwms_t_ztsv_array (
                            cwms_t_ztsv (DATE '2022-01-01', 1, 0),
                            cwms_t_ztsv (DATE '2022-02-01', 2, 0),
                            cwms_t_ztsv (DATE '2022-03-01', 3, 0),
                            cwms_t_ztsv (DATE '2022-04-01', 4, 0));
                ELSE
                    l_ts_data :=
                        cwms_t_ztsv_array (
                            cwms_t_ztsv (DATE '2022-01-01', 1, 0),
                            cwms_t_ztsv (DATE '2023-01-01', 2, 0),
                            cwms_t_ztsv (DATE '2024-01-01', 3, 0),
                            cwms_t_ztsv (DATE '2025-01-01', 4, 0));
                    l_ts_id := REPLACE (l_ts_id, '1Month', '1Year');
                END IF;

                cwms_ts.create_ts (
                    p_cwms_ts_id   => l_ts_id,
                    p_utc_offset   => 0,
                    p_versioned    =>
                        CASE
                            WHEN l_version_date = cwms_util.non_versioned
                            THEN
                                'F'
                            ELSE
                                'T'
                        END,
                    p_office_id    => l_office_id);
                ---------------------------
                -- store the time series --
                ---------------------------
                cwms_ts.zstore_ts (
                    p_cwms_ts_id        => l_ts_id,
                    p_units             => l_unit,
                    p_timeseries_data   => l_ts_data,
                    p_store_rule        => cwms_util.replace_all,
                    p_override_prot     => 'F',
                    p_version_date      => l_version_date,
                    p_office_id         => l_office_id,
                    p_create_as_lrts    => l_is_lrts);
                -----------------------
                -- retrieve the data --
                -----------------------
                DBMS_OUTPUT.put_line (
                    CHR (10) || 'i = ' || i || ', j = ' || j);
                DBMS_OUTPUT.put_line ('Retrieving ' || l_ts_id);
                DBMS_OUTPUT.put_line ('Version date = ' || l_version_date);
                cwms_ts.retrieve_ts (
                    p_at_tsv_rc         => l_crsr,
                    p_cwms_ts_id        => l_ts_id,
                    p_units             => l_unit,
                    p_start_time        => l_ts_data (1).date_time,
                    p_end_time          => l_ts_data (l_ts_data.COUNT).date_time,
                    p_time_zone         => 'UTC',
                    p_trim              => 'F',
                    p_start_inclusive   => 'T',
                    p_end_inclusive     => 'T',
                    p_previous          => 'F',
                    p_next              => 'F',
                    p_version_date      => l_version_date,
                    p_max_version       => 'T',
                    p_office_id         => l_office_id);

                FETCH l_crsr
                    BULK COLLECT INTO l_date_times, l_values, l_quality_codes;

                CLOSE l_crsr;

                ut.expect (l_date_times.COUNT).to_equal (l_ts_data.COUNT);

                IF l_date_times.COUNT = l_ts_data.COUNT
                THEN
                    FOR k IN 1 .. l_date_times.COUNT
                    LOOP
                        ut.expect (l_date_times (k)).to_equal (
                            l_ts_data (k).date_time);
                        ut.expect (l_values (k)).to_equal (
                            l_ts_data (k).VALUE);
                        ut.expect (l_quality_codes (k)).to_equal (
                            l_ts_data (k).quality_code);
                    END LOOP;
                END IF;
            END LOOP;
        END LOOP;
    END test_retrieve_ts_with_calendar_based_times__JIRA_CWDB_157;
END test_cwms_ts;
/
SHOW ERRORS
