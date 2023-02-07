CREATE OR REPLACE package &&cwms_schema..test_cwms_ts as

--%suite(Test cwms_ts package code)
--%beforeall (setup)
--%afterall(teardown)
--%rollback(manual)

--%test(Test setting active flag)
procedure test_set_active_flag;
--%test(Test filter duplicates)
procedure test_filter_duplicates;
--%test(Test delete ts data for location without timezone)
procedure delete_ts_with_location_without_timezone;
--%test(Test retrieve TS with calendar-based times [JIRA Issue CWDB-157])
procedure test_retrieve_ts_with_calendar_based_times__JIRA_CWDB_157;

--%test(Test creation various types of time series)
procedure test_create_ts_parameter_types;

--%test(Test rename time series) 
procedure test_rename_ts;

--%test(Test rename time series inst to median) 
--%throws(-20013)
procedure test_rename_ts_inst_to_median;

--%test(create depth velocity time series)
procedure test_create_depth_velocity; 

--%test(test micrograms/l)
procedure test_conc;

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
--%test(Make sure quality on generated rts/lrts values is 0 (unscreened) and not 5 (missing) [JIRA Issue CWMSVIEW-212])
procedure quality_on_generated_rts_values__JIRA_CWMSVIEW_212;
--%test(create a time series id with null timezone in location that has a  base location: CWDB-175)
procedure create_ts_with_null_timezone;
--%test(Test flags p_start_inclusive, p_end_inclusive, p_previous, p_next, and ts with aliases: CWDB-180)
procedure test_inclusion_options__JIRA_CWDB_180;
--%test(Test STORE_TS can create a versioned time series: CWDB-190)
procedure test_store_ts_can_create_versioned_time_series__JIRA_CWDB_190;

--%test(LRL 1Day at 6am EST stores correctly)
procedure test_lrl_1day_CWDB_202;

test_base_location_id VARCHAR2(32) := 'TestLoc1';
test_withsub_location_id VARCHAR2(32) := test_base_location_id||'-withsub';
test_renamed_base_location_id VARCHAR2(32) := 'RenameTestLoc1';
test_renamed_withsub_location_id VARCHAR2(32) := test_renamed_base_location_id||'-withsub';
procedure setup;
procedure teardown;
end test_cwms_ts;
/

/* Formatted on 4/28/2022 2:38:41 PM (QP5 v5.381) */
CREATE OR REPLACE PACKAGE BODY CWMS_20.test_cwms_ts
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
                  FROM TABLE (str_tab_t (test_base_location_id,test_renamed_base_location_id)))
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
        cwms_loc.store_location (p_location_id    => test_withsub_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        COMMIT;
    END;

    PROCEDURE teardown
    IS
    BEGIN
        delete_all;
    END teardown;

    PROCEDURE delete_ts_id (p_cwms_ts_id VARCHAR2)
    IS
        l_count   NUMBER;
    BEGIN
        CWMS_TS.DELETE_TS (p_cwms_ts_id, cwms_util.delete_all);

        SELECT COUNT (*)
          INTO l_count
          FROM at_cwms_ts_id
         WHERE UPPER (cwms_ts_id) = UPPER (p_cwms_ts_id);

        ut.expect (l_count).to_equal (0);

    END;

    PROCEDURE delete_ts_with_location_without_timezone
    IS
        l_times        CWMS_TS.NUMBER_ARRAY;
        l_values       CWMS_TS.DOUBLE_ARRAY;
        l_qualities    CWMS_TS.NUMBER_ARRAY;
        l_ts_code      NUMBER;
        l_count        INTEGER;
        l_cwms_ts_id   VARCHAR2 (200)
            :=    test_base_location_id
               || '.Flow-Res Out.Ave.~1Day.1Day.Raw-CDEC-web';
    BEGIN
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        cwms_ts.create_ts ('&&office_id', l_cwms_ts_id);
        COMMIT;

        SELECT COUNT (*)
          INTO l_count
          FROM at_cwms_ts_id
         WHERE UPPER (cwms_ts_id) = UPPER (l_cwms_ts_id);

        ut.expect (l_count).to_equal (1);

        SELECT ts_code
          INTO l_ts_code
          FROM at_cwms_ts_id
         WHERE cwms_ts_id = l_cwms_ts_id;

        FOR i IN 1 .. 9
        LOOP
            l_times (i) :=
                CWMS_UTIL.TO_MILLIS (
                    TO_DATE ('2022-03-0' || i || ' 07:00:00',
                             'YYYY-MM-DD HH24:MI:SS'));
            l_values (i) := i;
            l_qualities (i) := 0;
            CWMS_TS.STORE_TS (l_cwms_ts_id,
                              'cfs',
                              l_times,
                              l_values,
                              l_qualities,
                              'Delete Insert');
        END LOOP;

        SELECT COUNT (*)
          INTO l_count
          FROM at_tsv_2022
         WHERE ts_code = l_ts_code;

        ut.expect (l_count).to_equal (9);
        CWMS_TS.DELETE_TS (
            l_cwms_ts_id,
            'T',
            TO_DATE ('2022-03-01 06:00:00', 'YYYY-MM-DD HH24:MI:SS'),
            TO_DATE ('2022-03-22 07:00:00', 'YYYY-MM-DD HH24:MI:SS'),
            'T',
            'T',
            NULL,
            'UTC',
            NULL,
            'T',
            -1,
            '&&office_id');

        SELECT COUNT (*)
          INTO l_count
          FROM at_tsv_2022
         WHERE ts_code = l_ts_code;

        ut.expect (l_count).to_equal (0);
        delete_ts_id (l_cwms_ts_id);
    END;

    PROCEDURE test_unit_conversion (p_cwms_ts_id   VARCHAR2,
                                    p_start_time   TIMESTAMP,
                                    p_interval     NUMBER,
                                    p_num_values   INTEGER,
                                    p_units        VARCHAR2,
                                    p_factor       NUMBER,
                                    p_margin       NUMBER)
    IS
        l_times           CWMS_TS.NUMBER_ARRAY;
        l_values          CWMS_TS.DOUBLE_ARRAY;
        l_qualities       CWMS_TS.NUMBER_ARRAY;
        l_crsr            SYS_REFCURSOR;
        l_ret_times       cwms_t_date_table;
        l_ret_values      cwms_t_double_tab;
        l_ret_qualities   cwms_t_number_tab;
        l_ts_code         NUMBER;
        l_count           INTEGER;
    BEGIN
        cwms_ts.retrieve_ts (
            p_at_tsv_rc    => l_crsr,
            p_cwms_ts_id   => p_cwms_ts_id,
            p_units        => p_units,
            p_start_time   => p_start_time,
            p_end_time     =>
                p_start_time + ((p_interval * p_num_values) / (3600 * 24)),
            p_time_zone    => 'UTC',
            p_trim         => 'T',
            p_office_id    => '&&office_id');

        FETCH l_crsr
            BULK COLLECT INTO l_ret_times, l_ret_values, l_ret_qualities;

        ut.expect (l_ret_times.COUNT).to_equal (p_num_values);

        CLOSE l_crsr;

        FOR j IN 1 .. l_ret_times.COUNT
        LOOP
            ut.expect (CWMS_UTIL.TO_MILLIS (l_ret_times (j))).to_equal (
                CWMS_UTIL.TO_MILLIS (p_start_time) + (p_interval * 1000 * j));
            ut.expect (abs(l_ret_values (j)-(j*p_factor))).to_be_less_or_equal(p_margin);
            ut.expect (l_ret_qualities (j)).to_equal (0);
        END LOOP;
    END test_unit_conversion;

    PROCEDURE test_conc
    IS
        l_cwms_ts_id      VARCHAR2 (200);
        l_times           CWMS_TS.NUMBER_ARRAY;
        l_values          CWMS_TS.DOUBLE_ARRAY;
        l_qualities       CWMS_TS.NUMBER_ARRAY;
        l_crsr            SYS_REFCURSOR;
        l_ret_times       cwms_t_date_table;
        l_ret_values      cwms_t_double_tab;
        l_ret_qualities   cwms_t_number_tab;
        l_ts_code         NUMBER;
        l_count           INTEGER;
        l_num_values      NUMBER := 10;
        l_start_time      TIMESTAMP := TIMESTAMP '2022-03-01 00:00:00';
        l_interval        NUMBER := 3600;
    BEGIN
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        l_cwms_ts_id := test_base_location_id || '.Conc.Ave.1Hour.1Hour.raw';
        cwms_ts.create_ts ('&&office_id', l_cwms_ts_id);
        COMMIT;

        SELECT COUNT (*)
          INTO l_count
          FROM at_cwms_ts_id
         WHERE UPPER (cwms_ts_id) = UPPER (l_cwms_ts_id);

        ut.expect (l_count).to_equal (1);

        SELECT ts_code
          INTO l_ts_code
          FROM at_cwms_ts_id
         WHERE cwms_ts_id = l_cwms_ts_id;

        FOR i IN 1 .. l_num_values
        LOOP
            l_times (i) :=
                CWMS_UTIL.TO_MILLIS (l_start_time) + (l_interval * 1000 * i);
            l_values (i) := i;
            l_qualities (i) := 0;
        END LOOP;

        CWMS_TS.STORE_TS (l_cwms_ts_id,
                          'ug/l',
                          l_times,
                          l_values,
                          l_qualities,
                          'Delete Insert');

        SELECT COUNT (*)
          INTO l_count
          FROM av_tsv
         WHERE     ts_code = l_ts_code
               AND date_time >= l_start_time
               AND date_time <=
                   (  l_start_time
                    + ((l_interval * l_num_values) / (3600 * 24)));

        ut.expect (l_count).to_equal (l_num_values);
        test_unit_conversion(l_cwms_ts_id,l_start_time,l_interval,10,'ug/l',1,1.0E-09);
        test_unit_conversion(l_cwms_ts_id,l_start_time,l_interval,10,'mg/l',1.0E-03,1.0E-09);
        test_unit_conversion(l_cwms_ts_id,l_start_time,l_interval,10,'g/l',1.0E-06,1.0E-09);
        test_unit_conversion(l_cwms_ts_id,l_start_time,l_interval,10,'kg/l',1.0E-09,1.0E-02);
        test_unit_conversion(l_cwms_ts_id,l_start_time,l_interval,10,'lb/l',8.3454042651525E-9,1.0E-02);
        test_unit_conversion(l_cwms_ts_id,l_start_time,l_interval,10,'ppm',1.0E-3,1.0E-09);
	delete_ts_id(l_cwms_ts_id);
    END test_conc;

    PROCEDURE store_a_value (p_cwms_ts_id   VARCHAR2,
                             p_units        VARCHAR2,
                             p_interval     INTEGER,
                             p_num_values   INTEGER,
                             p_start_time   TIMESTAMP)
    IS
        l_times           CWMS_TS.NUMBER_ARRAY;
        l_values          CWMS_TS.DOUBLE_ARRAY;
        l_qualities       CWMS_TS.NUMBER_ARRAY;
        l_crsr            SYS_REFCURSOR;
        l_ret_times       cwms_t_date_table;
        l_ret_values      cwms_t_double_tab;
        l_ret_qualities   cwms_t_number_tab;
        l_ts_code         NUMBER;
        l_count           INTEGER;
    BEGIN
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        cwms_ts.create_ts ('&&office_id', p_cwms_ts_id);
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

        FOR i IN 1 .. p_num_values
        LOOP
            l_times (i) :=
                CWMS_UTIL.TO_MILLIS (p_start_time) + (p_interval * 1000 * i);
            l_values (i) := i;
            l_qualities (i) := 0;
        END LOOP;

        CWMS_TS.STORE_TS (p_cwms_ts_id,
                          p_units,
                          l_times,
                          l_values,
                          l_qualities,
                          'Delete Insert');

        SELECT COUNT (*)
          INTO l_count
          FROM av_tsv
         WHERE     ts_code = l_ts_code
               AND date_time >= p_start_time
               AND date_time <=
                   (  p_start_time
                    + ((p_interval * p_num_values) / (3600 * 24)));

        ut.expect (l_count).to_equal (p_num_values);

        cwms_ts.retrieve_ts (
            p_at_tsv_rc    => l_crsr,
            p_cwms_ts_id   => p_cwms_ts_id,
            p_units        => p_units,
            p_start_time   => p_start_time,
            p_end_time     =>
                  p_start_time
                + ((p_interval * p_num_values) / (3600 * 24)),
            p_time_zone    => 'UTC',
            p_trim         => 'T',
            p_office_id    => '&&office_id');

        FETCH l_crsr
            BULK COLLECT INTO l_ret_times, l_ret_values, l_ret_qualities;

        ut.expect (l_ret_times.COUNT).to_equal (p_num_values);

        CLOSE l_crsr;

        FOR j IN 1..l_ret_times.COUNT
        LOOP
            ut.expect (CWMS_UTIL.TO_MILLIS (l_ret_times (j))).to_equal (
                CWMS_UTIL.TO_MILLIS (p_start_time) + (p_interval * 1000 * j));
            ut.expect (round(l_ret_values (j))).to_equal (j);
            ut.expect (l_ret_qualities (j)).to_equal (0);
        END LOOP;
    END;

    PROCEDURE create_ts_with_null_timezone
    IS
    BEGIN
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        cwms_ts.create_ts (
            '&&office_id',
            test_base_location_id || '.Flow.Ave.Irr.Variable.raw');
        cwms_loc.rename_loc('&&office_id',
		test_base_location_id,
		test_renamed_base_location_id);
	COMMIT;
        delete_ts_id (test_renamed_base_location_id || '.Flow.Ave.Irr.Variable.raw');
        COMMIT;
        cwms_loc.store_location (p_location_id    => test_renamed_withsub_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        cwms_ts.create_ts (
            '&&office_id',
            test_renamed_withsub_location_id || '.Flow.Ave.Irr.Variable.raw');
        delete_ts_id (
            test_renamed_withsub_location_id || '.Flow.Ave.Irr.Variable.raw');
        COMMIT;
    END;

    PROCEDURE throw_an_exception (p_cwms_ts_id VARCHAR2)
    IS
    BEGIN
        cwms_ts.create_ts ('&&office_id', p_cwms_ts_id);
        COMMIT;
    END;

    PROCEDURE inc_with_zero_duration
    IS
    BEGIN
        throw_an_exception (
            test_base_location_id || '.Precip.Inc.1Hour.0.raw');
    END;

    PROCEDURE cum_with_non_zero_duration
    IS
    BEGIN
        throw_an_exception (
            test_base_location_id || '.Precip.Cum.1Hour.1Hour.raw');
    END;

    PROCEDURE untilchanged_with_regular
    IS
    BEGIN
        throw_an_exception (
            test_base_location_id || '.Precip.Const.1Hour.UntilChanged.raw');
    END;

    PROCEDURE untilchanged_with_non_const
    IS
    BEGIN
        throw_an_exception (
            test_base_location_id || '.Precip.Ave.0.UntilChanged.raw');
    END;

    PROCEDURE variable_with_inst
    IS
    BEGIN
        throw_an_exception (
            test_base_location_id || '.Precip.Inst.0.Variable.raw');
    END;

    PROCEDURE variable_with_const
    IS
    BEGIN
        throw_an_exception (
            test_base_location_id || '.Precip.Const.0.Variable.raw');
    END;

    PROCEDURE test_rename_ts
    IS
        l_time   NUMBER
                     := CWMS_UTIL.TO_MILLIS (TIMESTAMP '2010-01-01 00:00:00');
    BEGIN
        store_a_value (test_base_location_id || '.Flow.Ave.Irr.Variable.raw',
                       'cfs',
                       3600,
                       240,
                       TIMESTAMP '2022-03-01 00:00:00');
        cwms_ts.rename_ts (
            p_cwms_ts_id_old   =>
                test_base_location_id || '.Flow.Ave.Irr.Variable.raw',
            p_cwms_ts_id_new   =>
                test_base_location_id || '.Flow.Median.Irr.Variable.raw');
        delete_ts_id (
            test_base_location_id || '.Flow.Median.Irr.Variable.raw');
    END;

    PROCEDURE test_rename_ts_inst_to_median
    IS
        l_time   NUMBER
                     := CWMS_UTIL.TO_MILLIS (TIMESTAMP '2010-01-01 00:00:00');
    BEGIN
        store_a_value (test_base_location_id || '.Flow.Inst.Irr.0.raw',
                       'cfs',
                       3600,
                       240,
                       TIMESTAMP '2022-03-01 00:00:00');
        cwms_ts.rename_ts (
            p_cwms_ts_id_old   =>
                test_base_location_id || '.Flow.Inst.Irr.0.raw',
            p_cwms_ts_id_new   =>
                test_base_location_id || '.Flow.Median.1Day.1Day.raw');
    END;

    PROCEDURE test_create_ts_parameter_types
    IS
    BEGIN
        store_a_value (test_base_location_id || '.Flow.Ave.Irr.Variable.raw',
                       'cfs',
                       3600,
                       240,
                       TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Flow.Ave.Irr.Variable.raw');
        store_a_value (
            test_base_location_id || '.Flow.Median.Irr.Variable.raw',
            'cfs',
            3600,
            240,
            TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (
            test_base_location_id || '.Flow.Median.Irr.Variable.raw');
        store_a_value (test_base_location_id || '.Flow.Ave.0.Variable.raw',
                       'cfs',
                       3600,
                       240,
                       TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Flow.Ave.0.Variable.raw');
        store_a_value (
            test_base_location_id || '.Flow.Median.0.Variable.raw',
            'cfs',
            3600,
            240,
            TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Flow.Median.0.Variable.raw');
        store_a_value (
            test_base_location_id || '.Opening.Const.Irr.UntilChanged.raw',
            'ft',
            3600,
            240,
            TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (
            test_base_location_id || '.Opening.Const.Irr.UntilChanged.raw');
        store_a_value (
            test_base_location_id || '.Opening.Const.0.UntilChanged.raw',
            'ft',
            3600,
            240,
            TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (
            test_base_location_id || '.Opening.Const.0.UntilChanged.raw');
        store_a_value (test_base_location_id || '.Precip.Cum.1Hour.0.raw',
                       'in',
                       3600,
                       240,
                       TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Precip.Cum.1Hour.0.raw');
        store_a_value (
            test_base_location_id || '.Precip.Inc.1Hour.1Hour.raw',
            'in',
            3600,
            240,
            TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Precip.Inc.1Hour.1Hour.raw');
        store_a_value (test_base_location_id || '.Flow.Ave.Irr.Variable.raw',
                       'cfs',
                       3600,
                       240,
                       TIMESTAMP '2022-03-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Flow.Ave.Irr.Variable.raw');
        store_a_value (
            test_base_location_id || '.Flow.Median.Irr.Variable.raw',
            'cfs',
            3600,
            240,
            TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (
            test_base_location_id || '.Flow.Median.Irr.Variable.raw');
        store_a_value (test_base_location_id || '.Flow.Ave.0.Variable.raw',
                       'cfs',
                       3600,
                       240,
                       TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Flow.Ave.0.Variable.raw');
        store_a_value (
            test_base_location_id || '.Flow.Median.0.Variable.raw',
            'cfs',
            3600,
            240,
            TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Flow.Median.0.Variable.raw');
        store_a_value (
            test_base_location_id || '.Opening.Const.Irr.UntilChanged.raw',
            'ft',
            3600,
            240,
            TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (
            test_base_location_id || '.Opening.Const.Irr.UntilChanged.raw');
        store_a_value (
            test_base_location_id || '.Opening.Const.0.UntilChanged.raw',
            'ft',
            3600,
            240,
            TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (
            test_base_location_id || '.Opening.Const.0.UntilChanged.raw');
        store_a_value (test_base_location_id || '.Precip.Cum.1Hour.0.raw',
                       'in',
                       3600,
                       240,
                       TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Precip.Cum.1Hour.0.raw');
        store_a_value (
            test_base_location_id || '.Precip.Inc.1Hour.1Hour.raw',
            'in',
            3600,
            240,
            TIMESTAMP '2022-11-01 00:00:00');
        delete_ts_id (test_base_location_id || '.Precip.Inc.1Hour.1Hour.raw');
    END;

    PROCEDURE test_create_depth_velocity
    IS
        l_time         NUMBER
                           := CWMS_UTIL.TO_MILLIS (TIMESTAMP '2010-01-01 00:00:00');
        l_value        BINARY_DOUBLE;
        l_ts_code      NUMBER;
        l_cwms_ts_id   VARCHAR2 (200)
            := test_base_location_id || '.DepthVelocity.Ave.Irr.Variable.raw';
    BEGIN
        store_a_value (l_cwms_ts_id,
                       'ft2/s',
                       3600,
                       1,
                       TIMESTAMP '2022-03-01 00:00:00');

        SELECT ts_code
          INTO l_ts_code
          FROM at_cwms_ts_id
         WHERE cwms_ts_id = l_cwms_ts_id;

        SELECT VALUE
          INTO l_value
          FROM at_tsv_2022
         WHERE ts_code = l_ts_code;

        ut.expect (ABS (l_value - (1 * 0.092903))).to_be_less_or_equal (
            0.0001);

        SELECT VALUE
          INTO l_value
          FROM av_tsv_dqu
         WHERE ts_code = l_ts_code AND UPPER (unit_id) = 'FT2/S';

        ut.expect (ABS (l_value - 1)).to_be_less_or_equal (0.0001);
        delete_ts_id (l_cwms_ts_id);
        store_a_value (l_cwms_ts_id,
                       'm2/s',
                       3600,
                       1,
                       TIMESTAMP '2022-03-01 00:00:00');

        SELECT ts_code
          INTO l_ts_code
          FROM at_cwms_ts_id
         WHERE cwms_ts_id = l_cwms_ts_id;

        SELECT VALUE
          INTO l_value
          FROM at_tsv_2022
         WHERE ts_code = l_ts_code;

        ut.expect (l_value).to_equal (1);

        SELECT VALUE
          INTO l_value
          FROM av_tsv_dqu
         WHERE ts_code = l_ts_code AND UPPER (unit_id) = 'FT2/S';

        ut.expect (ABS (l_value - (1 / 0.092903))).to_be_less_or_equal (
            0.001);
        delete_ts_id (l_cwms_ts_id);
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

    --------------------------------------------------------------------------------
    -- procedure test_filter_duplicates
    --------------------------------------------------------------------------------
    PROCEDURE test_filter_duplicates
    IS
        l_ts_id       VARCHAR2 (191)
                          := test_base_location_id || '.Code.Inst.1Hour.0.Test';
        l_loc_id      VARCHAR2 (57) := test_base_location_id;
        l_unit        VARCHAR2 (16) := 'n/a';
        l_office_id   VARCHAR2 (16) := '&&office_id';
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
        l_office_id                 VARCHAR2 (16) := '&&office_id';
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

    --------------------------------------------------------------------------------
    -- procedure quality_on_generated_rts_values__JIRA_CWMSVIEW_212
    --------------------------------------------------------------------------------
    PROCEDURE quality_on_generated_rts_values__JIRA_CWMSVIEW_212
    IS
        l_ts_id          VARCHAR2 (191)
            := test_base_location_id || '.Code.Inst.1Day.0.QualityTest';
        l_office_id      VARCHAR2 (16) := '&&office_id';
        l_start_time     DATE := DATE '2022-03-01';
        l_value_count    PLS_INTEGER := 11;
        l_unit           VARCHAR2 (16) := 'n/a';
        l_time_zone      VARCHAR2 (28) := 'US/Central';
        l_version_date   DATE := cwms_util.non_versioned;
        l_first_date     DATE;
        l_last_date      DATE;
        l_zts_data       cwms_t_ztsv_array;
        l_ts_data        cwms_t_tsv_array;
        l_crsr           SYS_REFCURSOR;
        l_date_times     cwms_t_date_table;
        l_values         cwms_t_double_tab;
        l_qualities      cwms_t_number_tab;
    BEGIN
            ---------------------------------
            -- create the time series data --
            ---------------------------------
            SELECT cwms_t_tsv (
                       FROM_TZ (CAST (l_start_time + LEVEL - 1 AS TIMESTAMP),
                                l_time_zone),
                       LEVEL,
                       3)
              BULK COLLECT INTO l_ts_data
              FROM DUAL
        CONNECT BY LEVEL <= l_value_count;

            SELECT cwms_t_ztsv (l_start_time + LEVEL - 1, LEVEL, 3)
              BULK COLLECT INTO l_zts_data
              FROM DUAL
        CONNECT BY LEVEL <= l_value_count;

        ------------------------
        -- store the location --
        ------------------------
        cwms_loc.store_location (p_location_id    => test_base_location_id,
                                 p_active         => 'T',
                                 p_db_office_id   => '&&office_id');
        ----------------------------------
        -- store the time series as RTS --
        ----------------------------------
        cwms_ts.zstore_ts (p_cwms_ts_id        => l_ts_id,
                           p_units             => l_unit,
                           p_timeseries_data   => l_zts_data,
                           p_store_rule        => cwms_util.replace_all,
                           p_override_prot     => 'F',
                           p_version_date      => l_version_date,
                           p_office_id         => l_office_id,
                           p_create_as_lrts    => 'F');
        ------------------------------------------------------
        -- retrieve the time sereies with untrimmed padding --
        ------------------------------------------------------
        l_first_date := l_zts_data (1).date_time;
        l_last_date := l_zts_data (l_zts_data.COUNT).date_time;
        cwms_ts.retrieve_ts (p_at_tsv_rc         => l_crsr,
                             p_cwms_ts_id        => l_ts_id,
                             p_units             => l_unit,
                             p_start_time        => l_first_date - 5,
                             p_end_time          => l_last_date + 5,
                             p_time_zone         => 'UTC',
                             p_trim              => 'F',
                             p_start_inclusive   => 'T',
                             p_end_inclusive     => 'T',
                             p_previous          => 'F',
                             p_next              => 'F',
                             p_version_date      => l_version_date,
                             p_max_version       => 'T',
                             p_office_id         => l_office_id);

        FETCH l_crsr BULK COLLECT INTO l_date_times, l_values, l_qualities;

        CLOSE l_crsr;

        FOR i IN 1 .. l_date_times.COUNT
        LOOP
            IF l_date_times (i) BETWEEN l_first_date AND l_last_date
            THEN
                ut.expect (l_qualities (i)).to_equal (3);
            ELSE
                ut.expect (l_qualities (i)).to_equal (0);
            END IF;
        END LOOP;

        -----------------------------------
        -- store the time series as LRTS --
        -----------------------------------
        l_ts_id := REPLACE (l_ts_id, '1Day', '~1Day');
        cwms_ts.store_ts (p_cwms_ts_id        => l_ts_id,
                          p_units             => l_unit,
                          p_timeseries_data   => l_ts_data,
                          p_store_rule        => cwms_util.replace_all,
                          p_override_prot     => 'F',
                          p_version_date      => l_version_date,
                          p_office_id         => l_office_id,
                          p_create_as_lrts    => 'T');
        ------------------------------------------------------
        -- retrieve the time sereies with untrimmed padding --
        ------------------------------------------------------
        l_first_date := CAST (l_ts_data (1).date_time AS DATE);
        l_last_date := CAST (l_ts_data (l_zts_data.COUNT).date_time AS DATE);
        cwms_ts.retrieve_ts (p_at_tsv_rc         => l_crsr,
                             p_cwms_ts_id        => l_ts_id,
                             p_units             => l_unit,
                             p_start_time        => l_first_date - 5,
                             p_end_time          => l_last_date + 5,
                             p_time_zone         => l_time_zone,
                             p_trim              => 'F',
                             p_start_inclusive   => 'T',
                             p_end_inclusive     => 'T',
                             p_previous          => 'F',
                             p_next              => 'F',
                             p_version_date      => l_version_date,
                             p_max_version       => 'T',
                             p_office_id         => l_office_id);

        FETCH l_crsr BULK COLLECT INTO l_date_times, l_values, l_qualities;

        CLOSE l_crsr;

        FOR i IN 1 .. l_date_times.COUNT
        LOOP
            IF l_date_times (i) BETWEEN l_zts_data (1).date_time
                                    AND l_zts_data (l_value_count).date_time
            THEN
                ut.expect (l_qualities (i)).to_equal (3);
            ELSE
                ut.expect (l_qualities (i)).to_equal (0);
            END IF;
        END LOOP;
    END quality_on_generated_rts_values__JIRA_CWMSVIEW_212;
    --------------------------------------------------------------------------------
    -- procedure test_inclusion_options__JIRA_CWDB_180
    --------------------------------------------------------------------------------
    procedure test_inclusion_options__JIRA_CWDB_180
    is
      l_ts_id_cal     varchar2(191) := test_base_location_id||'.Code.Inst.1Month.0.Test';
      l_ts_id_tim     varchar2(191) := test_base_location_id||'.Code.Inst.1Day.0.Test';
      l_time_zone     varchar2(28)  := 'US/Pacific';
      l_unit          varchar2(16)  := 'n/a';
      l_crsr          sys_refcursor;
      l_values        cwms_t_double_tab;
      l_quality_codes cwms_t_number_tab;
      l_date_times    cwms_t_date_table;
      l_ts_data_cal   cwms_t_ztsv_array := cwms_t_ztsv_array(
                                            cwms_t_ztsv(timestamp '2021-01-01 08:00:00', 1, 3),
                                            cwms_t_ztsv(timestamp '2021-02-01 08:00:00', 2, 3),
                                            cwms_t_ztsv(timestamp '2021-03-01 08:00:00', 3, 3),
                                            cwms_t_ztsv(timestamp '2021-04-01 08:00:00', 4, 3),
                                            cwms_t_ztsv(timestamp '2021-05-01 08:00:00', 5, 3));
      l_ts_data_tim cwms_t_ztsv_array := cwms_t_ztsv_array(
                                            cwms_t_ztsv(timestamp '2022-01-01 08:00:00', 1, 3),
                                            cwms_t_ztsv(timestamp '2022-01-02 08:00:00', 2, 3),
                                            cwms_t_ztsv(timestamp '2022-01-03 08:00:00', 3, 3),
                                            cwms_t_ztsv(timestamp '2022-01-04 08:00:00', 4, 3),
                                            cwms_t_ztsv(timestamp '2022-01-05 08:00:00', 5, 3));
    begin
      ------------------------
      -- store the location --
      ------------------------
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_time_zone_id => l_time_zone,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      ---------------------------------
      -- store some location aliases --
      ---------------------------------
      cwms_loc.assign_loc_group(
         p_loc_category_id => 'Agency Aliases',
         p_loc_group_id    => 'USGS Station Number',
         p_location_id     => test_base_location_id,
         p_loc_alias_id    => '11111111',
         p_db_office_id    => '&&office_id');
      cwms_loc.assign_loc_group(
         p_loc_category_id => 'Agency Aliases',
         p_loc_group_id    => 'NWS Handbook 5 ID',
         p_location_id     => test_base_location_id,
         p_loc_alias_id    => '22222222',
         p_db_office_id    => '&&office_id');
      cwms_loc.assign_loc_group(
         p_loc_category_id => 'Agency Aliases',
         p_loc_group_id    => 'DCP Platform ID',
         p_location_id     => test_base_location_id,
         p_loc_alias_id    => '33333333',
         p_db_office_id    => '&&office_id');
      ----------------------------------
      -- store the time series as RTS --
      ----------------------------------
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_timeseries_data => l_ts_data_cal,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id',
         p_create_as_lrts  => 'F');

      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_timeseries_data => l_ts_data_tim,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id',
         p_create_as_lrts  => 'F');
      ---------------------------------------------------------------
      -- retrieve the data with various options and verify results --
      ---------------------------------------------------------------
      -- interval = CALENDAR, inclusive = TRUE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_cal(4).date_time);
      -- interval = CALENDAR, inclusive = FALSE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(1);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(3).date_time);
      -- interval = CALENDAR, inclusive = FALSE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_cal(4).date_time);
      -- interval = CALENDAR, inclusive = TRUE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(5);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(1).date_time);
      ut.expect(l_date_times(5)).to_equal(l_ts_data_cal(5).date_time);
      -- interval = TIME, inclusive = TRUE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_tim(4).date_time);
      -- interval = TIME, inclusive = FALSE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(1);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(3).date_time);
      -- interval = TIME, inclusive = FALSE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_tim(4).date_time);
      -- interval = TIME, inclusive = TRUE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(5);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(1).date_time);
      ut.expect(l_date_times(5)).to_equal(l_ts_data_tim(5).date_time);
      ----------------------------------
      -- store the time series as ITS --
      ----------------------------------
      l_ts_id_cal := replace(l_ts_id_cal, '1Month', '0');
      l_ts_id_tim := replace(l_ts_id_tim, '1Day', '0');
      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_timeseries_data => l_ts_data_cal,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id',
         p_create_as_lrts  => 'F');

      cwms_ts.zstore_ts(
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_timeseries_data => l_ts_data_tim,
         p_store_rule      => cwms_util.replace_all,
         p_override_prot   => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_office_id       => '&&office_id',
         p_create_as_lrts  => 'F');
      ---------------------------------------------------------------
      -- retrieve the data with various options and verify results --
      ---------------------------------------------------------------
      -- interval = NONE, inclusive = TRUE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_cal(4).date_time);
      -- interval = NONE, inclusive = FALSE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(1);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(3).date_time);
      -- interval = NONE, inclusive = FALSE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_cal(4).date_time);
      -- interval = NONE, inclusive = TRUE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_cal,
         p_units           => l_unit,
         p_start_time      => l_ts_data_cal(2).date_time,
         p_end_time        => l_ts_data_cal(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(5);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_cal(1).date_time);
      ut.expect(l_date_times(5)).to_equal(l_ts_data_cal(5).date_time);
      -- interval = NONE, inclusive = TRUE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_tim(4).date_time);
      -- interval = NONE, inclusive = FALSE, prev/next = FALSE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'F',
         p_next            => 'F',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(1);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(3).date_time);
      -- interval = NONE, inclusive = FALSE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'F',
         p_end_inclusive   => 'F',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(3);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(2).date_time);
      ut.expect(l_date_times(3)).to_equal(l_ts_data_tim(4).date_time);
      -- interval = NONE, inclusive = TRUE, prev/next = TRUE
      cwms_ts.retrieve_ts(
         p_at_tsv_rc       => l_crsr,
         p_cwms_ts_id      => l_ts_id_tim,
         p_units           => l_unit,
         p_start_time      => l_ts_data_tim(2).date_time,
         p_end_time        => l_ts_data_tim(4).date_time,
         p_time_zone       => 'UTC',
         p_trim            => 'T',
         p_start_inclusive => 'T',
         p_end_inclusive   => 'T',
         p_previous        => 'T',
         p_next            => 'T',
         p_version_date    => cwms_util.non_versioned,
         p_max_version     => 'T',
         p_office_id       => '&&office_id');

      fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
      close l_crsr;

      ut.expect(l_date_times.count).to_equal(5);
      ut.expect(l_date_times(1)).to_equal(l_ts_data_tim(1).date_time);
      ut.expect(l_date_times(5)).to_equal(l_ts_data_tim(5).date_time);

    end test_inclusion_options__JIRA_CWDB_180;
    --------------------------------------------------------------------------------
    -- procedure test_store_ts_can_create_versioned_time_series__JIRA_CWDB_190
    --------------------------------------------------------------------------------
    procedure test_store_ts_can_create_versioned_time_series__JIRA_CWDB_190
    is
      l_ts_id         varchar2(191) := test_base_location_id||'.Code.Inst.1Day.0.CWDB_190';
      l_time_zone     varchar2(28)  := 'US/Pacific';
      l_unit          varchar2(16)  := 'n/a';
      l_version_date  date          := timestamp '2021-01-01 10:00:00';
      l_crsr          sys_refcursor;
      l_values        cwms_t_double_tab;
      l_quality_codes cwms_t_number_tab;
      l_date_times    cwms_t_date_table;
      l_ts_data       cwms_t_ztsv_array := cwms_t_ztsv_array(
                                            cwms_t_ztsv(timestamp '2021-01-01 08:00:00', 1, 3),
                                            cwms_t_ztsv(timestamp '2021-01-02 08:00:00', 2, 3),
                                            cwms_t_ztsv(timestamp '2021-01-03 08:00:00', 3, 3),
                                            cwms_t_ztsv(timestamp '2021-01-04 08:00:00', 4, 3),
                                            cwms_t_ztsv(timestamp '2021-01-05 08:00:00', 5, 3));
    begin
      teardown;
      ------------------------
      -- store the location --
      ------------------------
      cwms_loc.store_location(
         p_location_id  => test_base_location_id,
         p_time_zone_id => l_time_zone,
         p_active       => 'T',
         p_db_office_id => '&&office_id');
      -------------------------------------
      -- store the versioned time series --
      -------------------------------------
      cwms_ts.zstore_ts (p_cwms_ts_id        => l_ts_id,
                         p_units             => l_unit,
                         p_timeseries_data   => l_ts_data,
                         p_store_rule        => cwms_util.replace_all,
                         p_version_date      => l_version_date,
                         p_office_id         => '&&office_id');

      ut.expect(cwms_ts.is_tsid_versioned_f(l_ts_id, '&&office_id')).to_equal('T');
      if cwms_ts.is_tsid_versioned_f(l_ts_id, '&&office_id') = 'T' then
         ------------------------------
         -- retrieve the time series --
         ------------------------------
         cwms_ts.retrieve_ts(
            p_at_tsv_rc       => l_crsr,
            p_cwms_ts_id      => l_ts_id,
            p_units           => l_unit,
            p_start_time      => l_ts_data(1).date_time,
            p_end_time        => l_ts_data(l_ts_data.count).date_time,
            p_version_date    => l_version_date,
            p_office_id       => '&&office_id');

         fetch l_crsr bulk collect into l_date_times, l_values, l_quality_codes;
         close l_crsr;

         for i in 1..l_date_times.count loop
            dbms_output.put_line(i||chr(9)||l_date_times(i)||chr(9)||l_values(i)||chr(9)||l_quality_codes(i));
         end loop;
         ut.expect(l_date_times.count).to_equal(l_ts_data.count);
         if l_date_times.count = l_ts_data.count then
            for i in 1..l_date_times.count loop
               ut.expect(l_values(i)).to_equal(l_ts_data(i).value);
            end loop;
         end if;
      end if;

    end test_store_ts_can_create_versioned_time_series__JIRA_CWDB_190;

    PROCEDURE test_lrl_1day_CWDB_202
    IS
        l_count number;
        l_tsid av_cwms_ts_id.cwms_ts_id%type := test_base_location_id || '.Temp-Water.Inst.1Day.0.lrl-at-6am';
        l_offset  av_cwms_ts_id.interval_utc_offset%type;
    BEGIN
        store_a_value (l_tsid,
                       'F',
                       3600*24,
                       1,
                       TIMESTAMP '2023-02-02 11:00:00');
        select count(*) into l_count from av_tsv where ts_code = (select ts_code from av_cwms_ts_id where cwms_ts_id = l_tsid);
        select interval_utc_offset into l_offset from av_cwms_ts_id where cwms_ts_id = l_tsid;
        dbms_output.put_line('Offset ' || l_offset);
        ut.expect(l_offset).not_to_equal(0);
        ut.expect(l_count).to_equal(1);
    END test_lrl_1day_CWDB_202;

END;
/
SHOW ERRORS
